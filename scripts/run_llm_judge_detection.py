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


# Judge system prompt aligned with schema
JUDGE_SYSTEM_PROMPT = """You are an expert smart contract security evaluator. Your task is to evaluate vulnerability detection outputs against ground truth.

## Your Role

You will receive:
1. The smart contract code
2. Ground truth about the TARGET vulnerability
3. An LLM's detection output with findings

## Classification Categories

Classify EACH finding into exactly ONE category:

**Valid Classifications (Credit Given):**
- `TARGET_MATCH`: Finding correctly identifies the documented target vulnerability (right type + right location + correct explanation)
- `PARTIAL_MATCH`: Finding is related to target but incomplete (e.g., wrong type name but describes the issue, or right type but wrong location)
- `BONUS_VALID`: Real exploitable vulnerability NOT in ground truth. Must have: concrete exploit steps, no trusted role compromise required, material impact

**Invalid Classifications (No Credit):**
- `HALLUCINATED`: Issue does not exist in the code (references non-existent functions, wrong logic)
- `MISCHARACTERIZED`: Code exists but is NOT actually vulnerable (safe pattern flagged as vulnerable)
- `DESIGN_CHOICE`: Intentional architecture decision (admin controls, pausability)
- `OUT_OF_SCOPE`: Issue in external contracts or unseen code
- `SECURITY_THEATER`: Theoretical concern without concrete profitable exploit
- `INFORMATIONAL`: True observation but not security-relevant (gas, style)

## Quality Scoring (only for TARGET_MATCH)

Score these on 0.0-1.0 scale:
- **RCIR (Root Cause Identification)**: Does explanation correctly identify WHY it's vulnerable?
- **AVA (Attack Vector Validity)**: Is the attack scenario realistic and executable?
- **FSV (Fix Suggestion Validity)**: Would the suggested fix actually remediate the issue?

## Type Match Levels

- `exact`: Same terminology as ground truth
- `semantic`: Different words, same meaning (e.g., "predictable randomness" = "weak_randomness")
- `partial`: Related but imprecise (e.g., "external call issue" for "reentrancy")
- `wrong`: Incorrect type
- `not_mentioned`: No type specified

Respond with valid JSON only."""


def get_judge_user_prompt(code: str, ground_truth: dict, detection: dict) -> str:
    """Build the user prompt for judge evaluation."""

    # Format ground truth
    gt_type = ground_truth.get("vulnerability_type", "unknown")
    gt_funcs = ground_truth.get("vulnerable_functions", [])
    gt_severity = ground_truth.get("severity", "unknown")
    gt_desc = ground_truth.get("description", "No description")

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

## Security Audit Findings to Evaluate

- **Verdict**: {verdict}
- **Confidence**: {confidence}
- **Number of Findings**: {len(vulnerabilities)}

{findings_text}

## Your Evaluation

Evaluate the audit findings and respond with JSON matching this structure:

```json
{{
  "overall_verdict": {{
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float or null>
  }},
  "findings": [
    {{
      "finding_id": <0-based index>,
      "description": "<what was claimed>",
      "vulnerability_type_claimed": "<type or null>",
      "severity_claimed": "<severity or null>",
      "location_claimed": "<location or null>",
      "matches_target": true | false,
      "is_valid_concern": true | false,
      "classification": "<one of the categories>",
      "reasoning": "<your explanation>"
    }}
  ],
  "target_assessment": {{
    "found": true | false,
    "finding_id": <id or null>,
    "type_match": "exact | semantic | partial | wrong | not_mentioned",
    "type_match_reasoning": "<explanation>",
    "root_cause_identification": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "attack_vector_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "fix_suggestion_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null
  }},
  "summary": {{
    "total_findings": <int>,
    "target_matches": <int>,
    "partial_matches": <int>,
    "bonus_valid": <int>,
    "hallucinated": <int>,
    "mischaracterized": <int>,
    "design_choice": <int>,
    "out_of_scope": <int>,
    "security_theater": <int>,
    "informational": <int>
  }},
  "notes": "<any additional observations>"
}}
```

Be rigorous. Only TARGET_MATCH if it truly identifies the ground truth vulnerability."""


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


# Judge caller mapping - only 2 judges for cost reasons
JUDGE_CALLERS = {
    "codestral": call_codestral,
    "gemini-3-flash": call_gemini_flash,
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
    parser.add_argument("--judge", "-j", default="codestral", choices=["codestral", "gemini-3-flash"], help="Judge model")
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
