#!/usr/bin/env python3
"""
Run LLM Judge evaluation on LLM detection outputs.

Evaluates detection outputs from models like DeepSeek, Claude, etc.
Uses judges like Codestral, Haiku, Gemini to assess quality.
"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


# Judge system prompt - ROOT CAUSE FIRST EVALUATION
JUDGE_SYSTEM_PROMPT = """You are an expert smart contract security evaluator. Your task is to evaluate vulnerability detection outputs against ground truth.

## Your Role

You will receive:
1. The smart contract code
2. Ground truth about the TARGET vulnerability (including the SPECIFIC root cause, attack scenario, and fix)
3. An LLM's detection output with findings

## CRITICAL: Evaluation Criteria for TARGET Vulnerability

Evaluate findings against target in this order:

### 1. Root Cause Match (MOST IMPORTANT - Evaluate First)

The finding MUST identify the EXACT root cause from ground truth. This is the most important criterion.

The model's explanation must demonstrate understanding of the SPECIFIC issue described in ground truth - not just any issue in that vulnerability category or function.

**CORRECT root cause matching examples:**
- Ground truth: "acceptedRoot not initialized, defaults to zero allowing bypass"
- Model says: "acceptedRoot is uninitialized and equals bytes32(0), attackers can craft messages that pass validation" → MATCH ✓

- Ground truth: "Missing slippage protection in swap function"
- Model says: "No minimum output amount check allows sandwich attacks" → MATCH ✓

**INCORRECT root cause matching examples:**
- Ground truth: "acceptedRoot not initialized, defaults to zero"
- Model says: "Predictable initial root value allows bypass" → NO MATCH ✗
  (Different issue - predictable vs uninitialized)

- Ground truth: "Missing access control on withdraw function"
- Model says: "Reentrancy in withdraw function" → NO MATCH ✗
  (Different vulnerability entirely, even if same function)

- Ground truth: "Integer overflow in token calculation in _transfer()"
- Model says: "Unchecked arithmetic in mint() function" → NO MATCH ✗
  (Different function - not the same issue)

### 2. Location Match (Evaluate only if root cause correct)

The finding must identify the SAME vulnerable function(s) as specified in ground truth.
- If ground truth says "withdraw()" is vulnerable, finding must be about "withdraw()"
- A finding about a different function is NOT a target match, even if it's the same vulnerability type

### 3. Type Match (Semantic Match Allowed)

Compare the vulnerability TYPE NAME claimed by the model against the ground truth type.
- exact: Same terminology (e.g., "reentrancy" vs "reentrancy")
- semantic: Different terminology for SAME concept (e.g., "uninitialized variable" = "improper_initialization")
- partial: Related but imprecise
- wrong: Different vulnerability category
- not_mentioned: No type specified

Semantic match on type name is acceptable - different words can describe the same vulnerability class.

## Classification Categories

**TARGET_MATCH**: All three criteria pass:
1. Root cause: CORRECT (exact semantic match)
2. Location: CORRECT (same function)
3. Type: exact OR semantic match

**PARTIAL_MATCH**: Root cause + location correct, but type is partial/wrong:
1. Root cause: CORRECT
2. Location: CORRECT
3. Type: partial OR wrong (model understood the actual issue but mislabeled it)

**BONUS_VALID**: A DIFFERENT real vulnerability NOT in ground truth. Must meet ALL criteria:
1. The vulnerability ACTUALLY EXISTS in the provided code (not hallucinated)
2. There is a CONCRETE, SPECIFIC attack scenario with step-by-step exploit
3. The exploit does NOT require a trusted role (owner/admin) to be compromised
4. The impact is genuine: loss of funds, unauthorized access, or critical state manipulation
5. It is NOT: design choices, informational issues, security theater, out of scope, or mischaracterization

**Invalid Classifications (No Credit):**
- HALLUCINATED: Issue does not exist in the code
- MISCHARACTERIZED: Code exists but is NOT actually vulnerable
- DESIGN_CHOICE: Intentional architecture decision
- OUT_OF_SCOPE: Issue in external contracts or unseen code
- SECURITY_THEATER: Theoretical concern without concrete, profitable exploit
- INFORMATIONAL: True observation but not security-relevant

## Target Assessment Output

Set complete_found and partial_found as follows:
- complete_found = TRUE: Only for TARGET_MATCH (root_cause + location + type exact/semantic)
- partial_found = TRUE: Only for PARTIAL_MATCH (root_cause + location correct, type partial/wrong)

Note: If root_cause is wrong, neither complete_found nor partial_found can be true.

## Quality Scoring (only for TARGET_MATCH or PARTIAL_MATCH)

Score on 0.0-1.0 scale. Each metric can be satisfied by EITHER matching ground truth OR providing a genuinely valid alternative:

**RCIR (Root Cause Identification)**:
- HIGH (0.8-1.0): Semantically matches ground truth root cause, OR technically accurate alternative
- MEDIUM (0.5-0.79): Partially matches, or correct but incomplete
- LOW (0.0-0.49): Vague, generic, or incorrect

**AVA (Attack Vector Validity)**:
- HIGH (0.8-1.0): Semantically matches ground truth attack, OR concrete step-by-step alternative that works
- MEDIUM (0.5-0.79): Partially matches, or plausible but missing steps
- LOW (0.0-0.49): Vague, generic, or wouldn't work

**FSV (Fix Suggestion Validity)**:
- HIGH (0.8-1.0): Semantically matches ground truth fix, OR correct alternative that remediates the issue
- MEDIUM (0.5-0.79): Partially matches, or helpful but incomplete
- LOW (0.0-0.49): Vague, generic, or wouldn't fix the issue

IMPORTANT: "Valid alternative" means REAL, TECHNICALLY CORRECT - not just plausible-sounding. Score conservatively if unsure.

Respond with valid JSON only."""


def get_judge_user_prompt(code: str, ground_truth: dict, detection: dict) -> str:
    """Build the user prompt for judge evaluation."""

    # Format ground truth - include root_cause, attack_scenario, fix for strict matching
    gt_type = ground_truth.get("vulnerability_type", "unknown")
    gt_funcs = ground_truth.get("vulnerable_functions", [])
    gt_severity = ground_truth.get("severity", "unknown")
    gt_desc = ground_truth.get("description", "No description")
    gt_root_cause = ground_truth.get("root_cause", "Not specified")
    gt_attack = ground_truth.get("attack_scenario", "Not specified")
    gt_fix = ground_truth.get("fix_description", "Not specified")

    # Format detection findings
    prediction = detection.get("prediction", {})
    verdict = prediction.get("verdict", "unknown")
    confidence = prediction.get("confidence", "not specified")
    vulnerabilities = prediction.get("vulnerabilities", [])

    findings_text = ""
    for i, v in enumerate(vulnerabilities):
        findings_text += f"""
### Finding {i}
- **Type**: {v.get('type', 'unspecified')}
- **Severity**: {v.get('severity', 'unspecified')}
- **Location**: {v.get('location', 'unspecified')}
- **Explanation**: {v.get('explanation', 'none')}
- **Attack Scenario**: {v.get('attack_scenario', 'none')}
- **Suggested Fix**: {v.get('suggested_fix', 'none')}
"""

    if not findings_text:
        findings_text = "No findings reported."

    return f"""## Smart Contract Code

```solidity
{code}
```

## Ground Truth (TARGET Vulnerability)

- **Type**: {gt_type}
- **Vulnerable Functions**: {', '.join(gt_funcs)}
- **Severity**: {gt_severity}
- **Description**: {gt_desc}
- **Root Cause**: {gt_root_cause}
- **Attack Scenario**: {gt_attack}
- **Fix**: {gt_fix}

CRITICAL: For TARGET_MATCH, the finding must:
1. Identify the SAME root cause: {gt_root_cause}
2. Be about the SAME function(s): {', '.join(gt_funcs)}
3. Use matching vulnerability type (exact or semantic match to "{gt_type}")

## Security Audit Findings to Evaluate

- **Verdict**: {verdict}
- **Confidence**: {confidence}
- **Number of Findings**: {len(vulnerabilities)}

{findings_text}

## Your Evaluation

Respond with JSON:

```json
{{
  "overall_verdict": {{
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float or null>
  }},
  "findings": [
    {{
      "finding_id": <0-based index>,
      "vulnerability_type_claimed": "<type or null>",
      "location_claimed": "<location or null>",
      "classification": "<TARGET_MATCH | PARTIAL_MATCH | BONUS_VALID | WRONG_ROOT_CAUSE | HALLUCINATED | MISCHARACTERIZED | DESIGN_CHOICE | OUT_OF_SCOPE | SECURITY_THEATER | INFORMATIONAL>",
      "reasoning": "<your explanation>"
    }}
  ],
  "target_assessment": {{
    "complete_found": true | false,
    "partial_found": true | false,
    "finding_id": <id or null>,
    "root_cause_match": true | false,
    "location_match": true | false,
    "type_match": "exact | semantic | partial | wrong | not_mentioned",
    "root_cause_identification": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "attack_vector_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "fix_suggestion_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null
  }},
  "notes": "<optional observations>"
}}
```

EVALUATION ORDER: root_cause FIRST → location SECOND → type THIRD
- complete_found=TRUE only if TARGET_MATCH (root_cause + location + type exact/semantic)
- partial_found=TRUE only if PARTIAL_MATCH (root_cause + location correct, type partial/wrong)
- If root_cause WRONG → complete_found=FALSE, partial_found=FALSE (don't check location/type)"""


# Judge system prompt for DIFFERENTIAL (fixed/patched) code
JUDGE_SYSTEM_PROMPT_DIFFERENTIAL = """You are an expert smart contract security evaluator. Your task is to evaluate vulnerability detection outputs against ground truth for FIXED/PATCHED code.

## IMPORTANT CONTEXT: This is FIXED Code

The code you are evaluating has been PATCHED. The TARGET vulnerability described in ground truth has been FIXED and NO LONGER EXISTS in this code.

Your job is to determine:
1. Did the model incorrectly claim the target vulnerability still exists (FALSE POSITIVE)?
2. Did the model find any OTHER valid vulnerabilities (separate from the fixed target)?

## Ground Truth Context

You will receive:
1. The PATCHED smart contract code
2. Ground truth describing the ORIGINAL vulnerability that WAS present (now fixed)
3. Information about HOW it was fixed
4. An LLM's detection output with findings

## CRITICAL: Two Criteria for FALSE POSITIVE

A finding is a FALSE POSITIVE (incorrectly claims the fixed vulnerability still exists) if it meets BOTH criteria:

### 1. Location Match
The finding is about the SAME function(s) as the original vulnerability.

### 2. Root Cause Match (KEY CRITERIA)
The finding describes the SAME root cause as the ORIGINAL vulnerability.

If the model's explanation matches the original root cause, but that root cause has been FIXED, the model failed to recognize the fix. This is the KEY criterion.

**Examples of FALSE POSITIVE:**
- Original root cause: "acceptedRoot not initialized, defaults to zero"
- Model claims: "acceptedRoot is uninitialized allowing bypass" → FALSE POSITIVE ✗
  (The fix initialized acceptedRoot, but model didn't notice)

- Original root cause: "No reentrancy guard on withdraw"
- Model claims: "withdraw() is vulnerable to reentrancy" → FALSE POSITIVE ✗
  (The fix added a reentrancy guard, but model didn't notice)

**Examples of NOT a false positive (different issue):**
- Original root cause: "acceptedRoot not initialized, defaults to zero"
- Model claims: "bridgeRouter address can be changed by attacker" → NOT FALSE POSITIVE
  (This is a DIFFERENT issue - evaluate as BONUS_VALID or invalid)

- Original root cause: "No reentrancy guard on withdraw"
- Model claims: "Missing access control on setFee function" → NOT FALSE POSITIVE
  (Different function, different issue)

## Classification Categories

**TARGET_FALSE_POSITIVE**: Finding meets BOTH criteria - model incorrectly claims the FIXED vulnerability still exists at the same location with the same root cause.

**BONUS_VALID**: A DIFFERENT real vulnerability NOT related to the fixed issue. Must meet ALL criteria:
1. The vulnerability ACTUALLY EXISTS in the provided code (not hallucinated)
2. There is a CONCRETE, SPECIFIC attack scenario with step-by-step exploit
3. The exploit does NOT require a trusted role (owner/admin) to be compromised
4. The impact is genuine: loss of funds, unauthorized access, or critical state manipulation
5. It is NOT: design choices, informational issues, security theater, out of scope, or mischaracterization

**Invalid Classifications (No Credit):**
- `HALLUCINATED`: Issue does not exist in the code
- `MISCHARACTERIZED`: Code exists but is NOT actually vulnerable
- `DESIGN_CHOICE`: Intentional architecture decision
- `OUT_OF_SCOPE`: Issue in external contracts or unseen code
- `SECURITY_THEATER`: Theoretical concern without concrete, profitable exploit
- `INFORMATIONAL`: True observation but not security-relevant

Respond with valid JSON only."""


def get_judge_user_prompt_differential(code: str, ground_truth: dict, detection: dict) -> str:
    """Build the user prompt for judge evaluation of DIFFERENTIAL (fixed) code."""

    gt_type = ground_truth.get("vulnerability_type", "unknown")
    gt_funcs = ground_truth.get("vulnerable_functions", [])
    gt_severity = ground_truth.get("severity", "unknown")
    gt_desc = ground_truth.get("description", "No description")
    gt_root_cause = ground_truth.get("root_cause", "Not specified")
    gt_fix = ground_truth.get("fix_description", "Not specified")

    prediction = detection.get("prediction", {})
    verdict = prediction.get("verdict", "unknown")
    confidence = prediction.get("confidence", "not specified")
    vulnerabilities = prediction.get("vulnerabilities", [])

    findings_text = ""
    for i, v in enumerate(vulnerabilities):
        findings_text += f"""
### Finding {i}
- **Type**: {v.get('type', 'unspecified')}
- **Severity**: {v.get('severity', 'unspecified')}
- **Location**: {v.get('location', 'unspecified')}
- **Explanation**: {v.get('explanation', 'none')}
- **Attack Scenario**: {v.get('attack_scenario', 'none')}
- **Suggested Fix**: {v.get('suggested_fix', 'none')}
"""

    if not findings_text:
        findings_text = "No findings reported."

    return f"""## PATCHED Smart Contract Code

This code has been FIXED. The original vulnerability has been patched.

```solidity
{code}
```

## Original Vulnerability (NOW FIXED)

- **Type**: {gt_type}
- **Originally Vulnerable Functions**: {', '.join(gt_funcs)}
- **Severity**: {gt_severity}
- **Original Description**: {gt_desc}
- **Original Root Cause**: {gt_root_cause}
- **Fix Applied**: {gt_fix}

The fix above has been applied. The target vulnerability NO LONGER EXISTS.

CRITICAL: A finding is a FALSE POSITIVE if BOTH:
1. It is about the SAME function(s): {', '.join(gt_funcs)}
2. It describes the SAME root cause: {gt_root_cause}

If a finding matches both, the model FAILED to recognize the fix.

## Security Audit Findings to Evaluate

- **Verdict**: {verdict}
- **Confidence**: {confidence}
- **Number of Findings**: {len(vulnerabilities)}

{findings_text}

## Your Evaluation

Determine if the model incorrectly claimed the fixed vulnerability still exists (FALSE POSITIVE).

Respond with JSON:

```json
{{
  "overall_verdict": {{
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float or null>
  }},
  "findings": [
    {{
      "finding_id": <0-based index>,
      "vulnerability_type_claimed": "<type or null>",
      "location_claimed": "<location or null>",
      "classification": "<TARGET_FALSE_POSITIVE | BONUS_VALID | HALLUCINATED | MISCHARACTERIZED | DESIGN_CHOICE | OUT_OF_SCOPE | SECURITY_THEATER | INFORMATIONAL>",
      "reasoning": "<your explanation>"
    }}
  ],
  "target_assessment": {{
    "false_positive_detected": true | false,
    "false_positive_finding_id": <id or null>,
    "location_match": true | false,
    "root_cause_match": true | false,
    "false_positive_reasoning": "<explain why this is or is not a false positive>"
  }},
  "notes": "<optional observations>"
}}
```

Remember: The target vulnerability has been FIXED. If the model claims it still exists with the same root cause at the same location, that is a FALSE POSITIVE."""


def call_openrouter(system_prompt: str, user_prompt: str, model_id: str) -> tuple[str, float]:
    """Call model via OpenRouter API."""
    import requests
    from dotenv import load_dotenv

    # Load .env
    load_dotenv(PROJECT_ROOT / ".env")

    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise Exception("OPENROUTER_API_KEY not set in environment")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://blockbench.research",
        "X-Title": "BlockBench"
    }

    payload = {
        "model": model_id,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.0,
        "max_tokens": 8192
    }

    start_time = time.time()
    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=headers,
        json=payload,
        timeout=300
    )
    latency_ms = (time.time() - start_time) * 1000

    if response.status_code != 200:
        raise Exception(f"OpenRouter API failed: {response.status_code} - {response.text[:300]}")

    data = response.json()
    return data["choices"][0]["message"]["content"], latency_ms


def call_codestral(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Codestral via OpenRouter."""
    return call_openrouter(system_prompt, user_prompt, "mistralai/codestral-2508")


def call_gemini_flash(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Gemini 3 Flash via OpenRouter."""
    return call_openrouter(system_prompt, user_prompt, "google/gemini-3-flash-preview")


def call_glm_47(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call GLM-4.7 via OpenRouter with reasoning disabled."""
    import requests
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
    api_key = os.getenv("OPENROUTER_API_KEY")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://blockbench.research",
        "X-Title": "BlockBench"
    }

    payload = {
        "model": "z-ai/glm-4.7",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.0,
        "max_tokens": 8192,
        "reasoning": {"enabled": False}  # Disable reasoning to reduce cost
    }

    start_time = time.time()
    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=headers,
        json=payload,
        timeout=300
    )
    latency_ms = (time.time() - start_time) * 1000

    if response.status_code != 200:
        raise Exception(f"OpenRouter API failed: {response.status_code} - {response.text[:300]}")

    data = response.json()
    return data["choices"][0]["message"]["content"], latency_ms


def call_mimo_v2_flash(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Mimo v2 Flash via OpenRouter (free tier)."""
    return call_openrouter(system_prompt, user_prompt, "xiaomi/mimo-v2-flash:free")


def call_mistral_large(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Mistral Large 2512 via OpenRouter."""
    return call_openrouter(system_prompt, user_prompt, "mistralai/mistral-large-2512")


# Judge caller mapping - 5 judges via OpenRouter
JUDGE_CALLERS = {
    "codestral": call_codestral,
    "gemini-3-flash": call_gemini_flash,
    "glm-4.7": call_glm_47,
    "mimo-v2-flash": call_mimo_v2_flash,
    "mistral-large": call_mistral_large,
}


def parse_json_response(raw: str) -> dict | None:
    """Extract JSON from response."""
    # Try to find JSON in code block
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
    else:
        json_str = raw.strip()

    try:
        return json.loads(json_str)
    except json.JSONDecodeError:
        # Try fixing trailing commas
        fixed = re.sub(r',\s*([}\]])', r'\1', json_str)
        try:
            return json.loads(fixed)
        except:
            pass

        # Try fixing unescaped newlines in string values
        # Replace newlines inside quoted strings with escaped version
        def fix_newlines_in_strings(s):
            result = []
            in_string = False
            escape_next = False
            for i, char in enumerate(s):
                if escape_next:
                    result.append(char)
                    escape_next = False
                elif char == '\\':
                    result.append(char)
                    escape_next = True
                elif char == '"':
                    result.append(char)
                    in_string = not in_string
                elif char == '\n' and in_string:
                    result.append('\\n')
                elif char == '\r' and in_string:
                    result.append('\\r')
                elif char == '\t' and in_string:
                    result.append('\\t')
                else:
                    result.append(char)
            return ''.join(result)

        try:
            fixed_newlines = fix_newlines_in_strings(json_str)
            return json.loads(fixed_newlines)
        except:
            pass

        # Last resort: try with trailing comma fix on newline-fixed version
        try:
            fixed_both = re.sub(r',\s*([}\]])', r'\1', fixed_newlines)
            return json.loads(fixed_both)
        except:
            return None


def run_judge_on_sample(
    detector_model: str,
    sample_id: str,
    tier: int,
    judge: str = "codestral",
    verbose: bool = False
) -> dict:
    """Run judge evaluation on a single detection output."""

    # Load detection output
    detection_path = PROJECT_ROOT / f"results/detection/llm/{detector_model}/ds/tier{tier}/d_{sample_id}.json"
    with open(detection_path) as f:
        detection = json.load(f)

    # Load ground truth
    gt_path = PROJECT_ROOT / f"samples/ds/tier{tier}/ground_truth/{sample_id}.json"
    with open(gt_path) as f:
        ground_truth = json.load(f)

    # Load contract code
    code_path = PROJECT_ROOT / f"samples/ds/tier{tier}/contracts/{sample_id}.sol"
    with open(code_path) as f:
        code = f.read()

    if verbose:
        print(f"Loaded: {sample_id}")
        print(f"  Detection: {len(detection.get('prediction', {}).get('vulnerabilities', []))} findings")
        print(f"  Ground truth: {ground_truth['vulnerability_type']} in {ground_truth['vulnerable_functions']}")

    # Build prompts
    user_prompt = get_judge_user_prompt(code, ground_truth, detection)

    if verbose:
        print(f"  Prompt size: {len(JUDGE_SYSTEM_PROMPT) + len(user_prompt)} chars")

    # Call judge
    timestamp = datetime.now(timezone.utc).isoformat()
    judge_caller = JUDGE_CALLERS.get(judge)
    if not judge_caller:
        raise ValueError(f"Unknown judge: {judge}. Available: {list(JUDGE_CALLERS.keys())}")

    try:
        raw_response, latency_ms = judge_caller(JUDGE_SYSTEM_PROMPT, user_prompt)

        if verbose:
            print(f"  Response received: {latency_ms:.0f}ms")

        # Parse response
        parsed = parse_json_response(raw_response)

        if parsed is None:
            # Save raw response for debugging before raising
            raise Exception(f"Failed to parse JSON response. Raw: {raw_response[:500]}...")

        # Build output conforming to schema
        result = {
            "sample_id": sample_id,
            "detector_model": detector_model,
            "prompt_type": "direct",
            "judge_model": judge,
            "timestamp": timestamp,
            "overall_verdict": parsed.get("overall_verdict", {}),
            "findings": parsed.get("findings", []),
            "target_assessment": parsed.get("target_assessment", {}),
            "summary": parsed.get("summary", {}),
            "notes": parsed.get("notes"),
            "judge_latency_ms": latency_ms,
            "raw_response": raw_response
        }

    except Exception as e:
        result = {
            "sample_id": sample_id,
            "detector_model": detector_model,
            "prompt_type": "direct",
            "judge_model": judge,
            "timestamp": timestamp,
            "error": str(e),
            "overall_verdict": {"said_vulnerable": None, "confidence_expressed": None},
            "findings": [],
            "target_assessment": {"found": False, "type_match": "not_mentioned", "type_match_reasoning": "Error during evaluation"},
            "summary": {"total_findings": 0}
        }

        if verbose:
            print(f"  ERROR: {e}")

    return result


def main():
    parser = argparse.ArgumentParser(description="Run LLM Judge on detection outputs")
    parser.add_argument("--detector", "-d", required=True, help="Detector model (e.g., deepseek-v3-2)")
    parser.add_argument("--judge", "-j", default="codestral", choices=["codestral", "gemini-3-flash", "glm-4.7", "mimo-v2-flash"], help="Judge model")
    parser.add_argument("--tier", "-t", type=int, default=1, help="Tier (1-4)")
    parser.add_argument("--sample", "-s", help="Single sample ID")
    parser.add_argument("--limit", "-l", type=int, help="Limit samples")
    parser.add_argument("--verbose", "-v", action="store_true")

    args = parser.parse_args()

    # Output directory
    output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{args.detector}/ds/tier{args.tier}"
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.sample:
        # Single sample
        result = run_judge_on_sample(
            detector_model=args.detector,
            sample_id=args.sample,
            tier=args.tier,
            judge=args.judge,
            verbose=args.verbose
        )

        # Save
        output_path = output_dir / f"j_{args.sample}.json"
        with open(output_path, "w") as f:
            json.dump(result, f, indent=2)

        print(f"\nSaved: {output_path}")

        # Print summary
        ta = result.get("target_assessment", {})
        print(f"\n=== Judge Result ===")
        print(f"Target Found: {ta.get('found', False)}")
        print(f"Type Match: {ta.get('type_match', 'N/A')}")

        if ta.get("found"):
            rcir = ta.get("root_cause_identification", {})
            ava = ta.get("attack_vector_validity", {})
            fsv = ta.get("fix_suggestion_validity", {})
            print(f"RCIR: {rcir.get('score', 'N/A')}")
            print(f"AVA: {ava.get('score', 'N/A')}")
            print(f"FSV: {fsv.get('score', 'N/A')}")

        summary = result.get("summary", {})
        print(f"\nFindings: {summary.get('total_findings', 0)}")
        print(f"  Target matches: {summary.get('target_matches', 0)}")
        print(f"  Partial: {summary.get('partial_matches', 0)}")
        print(f"  Bonus valid: {summary.get('bonus_valid', 0)}")
        print(f"  Hallucinated: {summary.get('hallucinated', 0)}")

    else:
        # All samples in tier
        detection_dir = PROJECT_ROOT / f"results/detection/llm/{args.detector}/ds/tier{args.tier}"
        detection_files = sorted(detection_dir.glob("d_*.json"))

        if args.limit:
            detection_files = detection_files[:args.limit]

        print(f"Running {args.judge} judge on {len(detection_files)} {args.detector} outputs")

        results = []
        for i, f in enumerate(detection_files, 1):
            sample_id = f.stem.replace("d_", "")
            print(f"[{i}/{len(detection_files)}] {sample_id}...", end=" ", flush=True)

            result = run_judge_on_sample(
                detector_model=args.detector,
                sample_id=sample_id,
                tier=args.tier,
                judge=args.judge,
                verbose=False
            )

            # Save individual result
            output_path = output_dir / f"j_{sample_id}.json"
            with open(output_path, "w") as f_out:
                json.dump(result, f_out, indent=2)

            # Print quick status
            ta = result.get("target_assessment", {})
            found = "YES" if ta.get("found") else "NO"
            print(f"target={found}, type_match={ta.get('type_match', 'N/A')}")

            results.append(result)

        # Summary
        found_count = sum(1 for r in results if r.get("target_assessment", {}).get("found"))
        print(f"\n=== Summary ===")
        print(f"Target found: {found_count}/{len(results)} ({100*found_count/len(results):.1f}%)")


if __name__ == "__main__":
    main()
