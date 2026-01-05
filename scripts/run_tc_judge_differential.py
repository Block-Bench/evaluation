#!/usr/bin/env python3
"""
Run LLM Judge evaluation on TC differential (FIXED/PATCHED) detection outputs.

The differential variant contains PATCHED code where the target vulnerability
has been FIXED. We evaluate whether the detector:
1. Correctly recognized the fix (no false positive)
2. Incorrectly claimed the vulnerability still exists (false positive)
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Import judge components from existing script
from scripts.run_llm_judge_detection import (
    JUDGE_SYSTEM_PROMPT_DIFFERENTIAL,
    JUDGE_CALLERS,
    parse_json_response,
    get_judge_user_prompt_differential,
)


def run_judge_on_differential_sample(
    detector_model: str,
    sample_id: str,
    judge: str = "codestral",
    verbose: bool = False
) -> dict:
    """Run judge evaluation on a single differential (fixed code) detection output."""

    variant = "differential"

    # Load detection output
    detection_path = PROJECT_ROOT / f"results/detection/llm/{detector_model}/tc/{variant}/d_{sample_id}.json"
    with open(detection_path) as f:
        detection = json.load(f)

    # Load ground truth
    gt_path = PROJECT_ROOT / f"samples/tc/{variant}/ground_truth/{sample_id}.json"
    with open(gt_path) as f:
        ground_truth = json.load(f)

    # Load contract code
    code_path = PROJECT_ROOT / f"samples/tc/{variant}/contracts/{sample_id}.sol"
    with open(code_path) as f:
        code = f.read()

    if verbose:
        print(f"Loaded: {sample_id}")
        print(f"  Detection: {len(detection.get('prediction', {}).get('vulnerabilities', []))} findings")
        print(f"  Ground truth: {ground_truth['vulnerability_type']} (FIXED)")
        print(f"  is_vulnerable: {ground_truth.get('is_vulnerable', 'not specified')}")

    # Build prompts using DIFFERENTIAL prompt builder
    user_prompt = get_judge_user_prompt_differential(code, ground_truth, detection)

    # Call judge
    timestamp = datetime.now(timezone.utc).isoformat()
    judge_caller = JUDGE_CALLERS.get(judge)
    if not judge_caller:
        raise ValueError(f"Unknown judge: {judge}. Available: {list(JUDGE_CALLERS.keys())}")

    try:
        raw_response, latency_ms = judge_caller(JUDGE_SYSTEM_PROMPT_DIFFERENTIAL, user_prompt)

        if verbose:
            print(f"  Response received: {latency_ms:.0f}ms")

        parsed = parse_json_response(raw_response)

        if parsed is None:
            raise Exception(f"Failed to parse JSON response. Raw: {raw_response[:500]}...")

        # Extract target_assessment (differential format)
        target_assessment = parsed.get("target_assessment", {})

        result = {
            "sample_id": sample_id,
            "variant": variant,
            "detector_model": detector_model,
            "prompt_type": "direct",
            "judge_model": judge,
            "timestamp": timestamp,
            "overall_verdict": parsed.get("overall_verdict", {}),
            "findings": parsed.get("findings", []),
            "target_assessment": target_assessment,
            "notes": parsed.get("notes"),
            "judge_latency_ms": latency_ms,
            "raw_response": raw_response
        }

    except Exception as e:
        result = {
            "sample_id": sample_id,
            "variant": variant,
            "detector_model": detector_model,
            "prompt_type": "direct",
            "judge_model": judge,
            "timestamp": timestamp,
            "error": str(e),
            "overall_verdict": {"said_vulnerable": None, "confidence_expressed": None},
            "findings": [],
            "target_assessment": {
                "false_positive_detected": None,
                "false_positive_finding_id": None,
                "location_match": None,
                "root_cause_match": None,
                "false_positive_reasoning": f"Error during evaluation: {str(e)}"
            }
        }

        if verbose:
            print(f"  ERROR: {e}")

    return result


def main():
    parser = argparse.ArgumentParser(description="Run LLM Judge on TC differential (fixed code) detection outputs")
    parser.add_argument("--detector", "-d", required=True, action="append", help="Detector model(s)")
    parser.add_argument("--judge", "-j", default="codestral", choices=list(JUDGE_CALLERS.keys()), help="Judge model")
    parser.add_argument("--sample", "-s", help="Single sample ID")
    parser.add_argument("--limit", "-l", type=int, help="Limit samples")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--force", "-f", action="store_true", help="Force re-run even if output exists")

    args = parser.parse_args()

    variant = "differential"
    detectors = args.detector if args.detector else []

    for detector in detectors:
        # Output directory
        output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{detector}/tc/{variant}"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Get detection files
        detection_dir = PROJECT_ROOT / f"results/detection/llm/{detector}/tc/{variant}"
        if not detection_dir.exists():
            print(f"No detection results for {detector} on tc/{variant}")
            continue

        detection_files = sorted(detection_dir.glob("d_*.json"))

        # Filter already completed (unless --force)
        pending = []
        for f in detection_files:
            sample_id = f.stem.replace("d_", "")
            out_file = output_dir / f"j_{sample_id}.json"
            if args.force or not out_file.exists():
                pending.append((f, sample_id))

        if args.sample:
            pending = [(f, sid) for f, sid in pending if sid == args.sample]

        if args.limit:
            pending = pending[:args.limit]

        if not pending:
            print(f"{args.judge} on {detector}: all {len(detection_files)} samples complete")
            continue

        print(f"Running {args.judge} on {detector} tc/{variant}: {len(pending)} pending")

        for i, (f, sample_id) in enumerate(pending, 1):
            print(f"[{i}/{len(pending)}] {sample_id}...", end=" ", flush=True)

            result = run_judge_on_differential_sample(
                detector_model=detector,
                sample_id=sample_id,
                judge=args.judge,
                verbose=args.verbose
            )

            # Save
            output_path = output_dir / f"j_{sample_id}.json"
            with open(output_path, "w") as f_out:
                json.dump(result, f_out, indent=2)

            # Status - for differential, we track false positives
            ta = result.get("target_assessment", {})
            fp = ta.get("false_positive_detected", None)

            if result.get("error"):
                status = "ERR"
            elif fp is True:
                status = "FP"  # False Positive - model failed
            elif fp is False:
                status = "OK"  # No false positive - passed
            else:
                status = "?"

            print(f"status={status}")

        # Summary
        all_results = list(output_dir.glob("j_*.json"))
        fp_count = 0
        ok_count = 0
        for rf in all_results:
            with open(rf) as f:
                r = json.load(f)
                ta = r.get("target_assessment", {})
                if ta.get("false_positive_detected") is True:
                    fp_count += 1
                elif ta.get("false_positive_detected") is False:
                    ok_count += 1

        total = len(all_results)
        print(f"{detector}: {ok_count}/{total} passed (no FP), {fp_count}/{total} false positives")


if __name__ == "__main__":
    main()
