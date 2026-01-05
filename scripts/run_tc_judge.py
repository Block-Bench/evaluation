#!/usr/bin/env python3
"""
Run LLM Judge evaluation on TC (Temporal Contamination) detection outputs.
"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Import judge components from existing script
from scripts.run_llm_judge_detection import (
    JUDGE_SYSTEM_PROMPT,
    JUDGE_CALLERS,
    parse_json_response,
    get_judge_user_prompt,
)


def run_judge_on_tc_sample(
    detector_model: str,
    sample_id: str,
    variant: str,
    judge: str = "codestral",
    verbose: bool = False
) -> dict:
    """Run judge evaluation on a single TC detection output."""

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
        print(f"  Ground truth: {ground_truth['vulnerability_type']}")

    # Build prompts
    user_prompt = get_judge_user_prompt(code, ground_truth, detection)

    # Call judge
    timestamp = datetime.now(timezone.utc).isoformat()
    judge_caller = JUDGE_CALLERS.get(judge)
    if not judge_caller:
        raise ValueError(f"Unknown judge: {judge}. Available: {list(JUDGE_CALLERS.keys())}")

    try:
        raw_response, latency_ms = judge_caller(JUDGE_SYSTEM_PROMPT, user_prompt)

        if verbose:
            print(f"  Response received: {latency_ms:.0f}ms")

        parsed = parse_json_response(raw_response)

        if parsed is None:
            raise Exception(f"Failed to parse JSON response. Raw: {raw_response[:500]}...")

        result = {
            "sample_id": sample_id,
            "variant": variant,
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
            "variant": variant,
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
    parser = argparse.ArgumentParser(description="Run LLM Judge on TC detection outputs")
    parser.add_argument("--detector", "-d", required=True, action="append", help="Detector model(s)")
    parser.add_argument("--judge", "-j", default="codestral", choices=list(JUDGE_CALLERS.keys()), help="Judge model")
    parser.add_argument("--variant", "-v", default="minimalsanitized", help="TC variant")
    parser.add_argument("--sample", "-s", help="Single sample ID")
    parser.add_argument("--limit", "-l", type=int, help="Limit samples")
    parser.add_argument("--verbose", action="store_true")

    args = parser.parse_args()

    detectors = args.detector if args.detector else []

    for detector in detectors:
        # Output directory
        output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{detector}/tc/{args.variant}"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Get detection files
        detection_dir = PROJECT_ROOT / f"results/detection/llm/{detector}/tc/{args.variant}"
        if not detection_dir.exists():
            print(f"No detection results for {detector} on tc/{args.variant}")
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
            print(f"{args.judge} on {detector}: all {len(detection_files)} samples complete")
            continue

        print(f"Running {args.judge} on {detector} tc/{args.variant}: {len(pending)} pending")

        for i, (f, sample_id) in enumerate(pending, 1):
            print(f"[{i}/{len(pending)}] {sample_id}...", end=" ", flush=True)

            result = run_judge_on_tc_sample(
                detector_model=detector,
                sample_id=sample_id,
                variant=args.variant,
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

        print(f"{detector}: {found_count}/{len(all_results)} targets found ({100*found_count/len(all_results):.1f}%)")


if __name__ == "__main__":
    main()
