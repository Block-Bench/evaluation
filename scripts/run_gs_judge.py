#!/usr/bin/env python3
"""
Run LLM Judge evaluation on GS (Gold Standard) detection outputs.
Enhanced with protocol context, extra contract files, and chain-of-thought reasoning.
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Import judge components from existing script - use the ORIGINAL prompt
from scripts.run_llm_judge_detection import (
    JUDGE_SYSTEM_PROMPT,
    JUDGE_CALLERS,
    parse_json_response,
)


# ============================================================================
# USE ORIGINAL PROMPT - No modifications to system prompt
# Protocol context and extra files are added to USER prompt only
# ============================================================================
GS_JUDGE_SYSTEM_PROMPT = JUDGE_SYSTEM_PROMPT


def load_context_files(sample_id: str) -> list[dict]:
    """Load extra contract files for a sample if they exist."""
    context_dir = PROJECT_ROOT / f"samples/gs/contracts/context/{sample_id}"
    if not context_dir.exists():
        return []

    context_files = []
    for ctx_file in sorted(context_dir.glob('*.sol')):
        context_files.append({
            'name': ctx_file.name,
            'code': ctx_file.read_text()
        })
    return context_files


def get_gs_judge_user_prompt(code: str, ground_truth: dict, detection: dict,
                              protocol_context: str, context_files: list[dict]) -> str:
    """Build the user prompt for GS judge evaluation with protocol context and extra files."""

    # Format ground truth
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

    # === NEW: Format extra context files ===
    context_files_text = ""
    if context_files:
        context_files_text = "\n\n## Additional Contract Files (for context)\n"
        for cf in context_files:
            context_files_text += f"""
### {cf['name']}
```solidity
{cf['code']}
```
"""

    # === NEW: Protocol context section ===
    protocol_section = ""
    if protocol_context and protocol_context != "No protocol context available.":
        protocol_section = f"""## Protocol Context

{protocol_context}

---

"""

    return f"""{protocol_section}## Smart Contract Code

```solidity
{code}
```
{context_files_text}
---

## Ground Truth (TARGET Vulnerability)

- **Type**: {gt_type}
- **Vulnerable Function(s)**: {', '.join(gt_funcs) if gt_funcs else 'Not specified'}
- **Severity**: {gt_severity}
- **Description**: {gt_desc}
- **Root Cause**: {gt_root_cause}
- **Attack Scenario**: {gt_attack}
- **Recommended Fix**: {gt_fix}

CRITICAL: For TARGET_MATCH, the finding must:
1. Be about the SAME function(s): {', '.join(gt_funcs) if gt_funcs else 'Not specified'}
2. Identify the SAME root cause: {gt_root_cause}
3. Use matching vulnerability type (exact or semantic match to "{gt_type}")

---

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
      "classification": "<TARGET_MATCH | PARTIAL_MATCH | BONUS_VALID | HALLUCINATED | MISCHARACTERIZED | DESIGN_CHOICE | OUT_OF_SCOPE | SECURITY_THEATER | INFORMATIONAL>",
      "reasoning": "<your explanation>"
    }}
  ],
  "target_assessment": {{
    "found": true | false,
    "finding_id": <id or null>,
    "location_match": true | false,
    "root_cause_match": true | false,
    "type_match": "exact | semantic | partial | wrong | not_mentioned",
    "root_cause_identification": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "attack_vector_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null,
    "fix_suggestion_validity": {{"score": <0.0-1.0>, "reasoning": "<why>"}} | null
  }},
  "notes": "<optional observations>"
}}
```

Only TARGET_MATCH if ALL THREE: location match + root cause match + type match (exact/semantic)."""


def run_judge_on_gs_sample(
    detector_model: str,
    sample_id: str,
    prompt_type: str,
    judge: str = "codestral",
    verbose: bool = False
) -> dict:
    """Run judge evaluation on a single GS detection output with protocol context and extra files."""

    # Load detection output
    detection_path = PROJECT_ROOT / f"results/detection/llm/{detector_model}/gs/{prompt_type}/d_{sample_id}.json"
    with open(detection_path) as f:
        detection = json.load(f)

    # Load ground truth
    gt_path = PROJECT_ROOT / f"samples/gs/ground_truth/{sample_id}.json"
    with open(gt_path) as f:
        ground_truth = json.load(f)

    # Load contract code
    code_path = PROJECT_ROOT / f"samples/gs/contracts/{sample_id}.sol"
    with open(code_path) as f:
        code = f.read()

    # NEW: Load protocol context
    context_path = PROJECT_ROOT / f"samples/gs/protocol_context_doc/{sample_id}_context.txt"
    if context_path.exists():
        with open(context_path) as f:
            protocol_context = f.read()
    else:
        protocol_context = ""

    # NEW: Load extra contract files
    context_files = load_context_files(sample_id)

    if verbose:
        print(f"Loaded: {sample_id}")
        print(f"  Detection: {len(detection.get('prediction', {}).get('vulnerabilities', []))} findings")
        print(f"  Ground truth: {ground_truth.get('vulnerability_type', 'unknown')}")
        print(f"  Protocol context: {'Yes' if protocol_context else 'No'}")
        print(f"  Extra contract files: {len(context_files)}")

    # Build prompts with protocol context and extra files
    user_prompt = get_gs_judge_user_prompt(code, ground_truth, detection, protocol_context, context_files)

    # Call judge
    timestamp = datetime.now(timezone.utc).isoformat()
    judge_caller = JUDGE_CALLERS.get(judge)
    if not judge_caller:
        raise ValueError(f"Unknown judge: {judge}. Available: {list(JUDGE_CALLERS.keys())}")

    try:
        raw_response, latency_ms = judge_caller(GS_JUDGE_SYSTEM_PROMPT, user_prompt)

        if verbose:
            print(f"  Response received: {latency_ms:.0f}ms")

        parsed = parse_json_response(raw_response)

        if parsed is None:
            raise Exception(f"Failed to parse JSON response. Raw: {raw_response[:500]}...")

        result = {
            "sample_id": sample_id,
            "dataset": "gs",
            "prompt_type": prompt_type,
            "detector_model": detector_model,
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
            "dataset": "gs",
            "prompt_type": prompt_type,
            "detector_model": detector_model,
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
    parser = argparse.ArgumentParser(description="Run LLM Judge on GS detection outputs")
    parser.add_argument("--detector", "-d", required=True, action="append", help="Detector model(s)")
    parser.add_argument("--judge", "-j", default="codestral", choices=list(JUDGE_CALLERS.keys()), help="Judge model")
    parser.add_argument("--prompt-type", "-p", default="direct", help="Prompt type (direct, context_protocol, etc.)")
    parser.add_argument("--sample", "-s", help="Single sample ID")
    parser.add_argument("--limit", "-l", type=int, help="Limit samples")
    parser.add_argument("--verbose", action="store_true")

    args = parser.parse_args()

    detectors = args.detector if args.detector else []

    for detector in detectors:
        # Output directory - organized by judge/detector/gs/prompt_type
        output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{detector}/gs/{args.prompt_type}"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Get detection files
        detection_dir = PROJECT_ROOT / f"results/detection/llm/{detector}/gs/{args.prompt_type}"
        if not detection_dir.exists():
            print(f"No detection results for {detector} on gs/{args.prompt_type}")
            continue

        detection_files = sorted(detection_dir.glob("d_*.json"))

        # Filter already completed
        pending = []
        for f in detection_files:
            sample_id = f.stem.replace("d_", "")
            out_file = output_dir / f"j_{sample_id}.json"
            if not out_file.exists():
                pending.append((f, sample_id))

        if args.sample:
            pending = [(f, sid) for f, sid in pending if sid == args.sample]

        if args.limit:
            pending = pending[:args.limit]

        if not pending:
            print(f"{args.judge} on {detector} gs/{args.prompt_type}: all {len(detection_files)} samples complete")
            continue

        print(f"Running {args.judge} on {detector} gs/{args.prompt_type}: {len(pending)} pending")

        for i, (f, sample_id) in enumerate(pending, 1):
            print(f"[{i}/{len(pending)}] {sample_id}...", end=" ", flush=True)

            result = run_judge_on_gs_sample(
                detector_model=detector,
                sample_id=sample_id,
                prompt_type=args.prompt_type,
                judge=args.judge,
                verbose=args.verbose
            )

            # Save
            output_path = output_dir / f"j_{sample_id}.json"
            with open(output_path, "w") as f_out:
                json.dump(result, f_out, indent=2)

            # Status
            ta = result.get("target_assessment", {})
            found = "YES" if ta.get("found") else "NO"
            err = " [ERR]" if result.get("error") else ""
            print(f"target={found}{err}")

        # Summary
        all_results = list(output_dir.glob("j_*.json"))
        found_count = 0
        for rf in all_results:
            with open(rf) as f:
                r = json.load(f)
                if r.get("target_assessment", {}).get("found"):
                    found_count += 1

        print(f"{detector} gs/{args.prompt_type}: {found_count}/{len(all_results)} targets found ({100*found_count/len(all_results):.1f}%)")


if __name__ == "__main__":
    main()
