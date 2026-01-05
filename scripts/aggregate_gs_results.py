#!/usr/bin/env python3
"""Aggregate GS (Gold Standard) judge results into summary files."""

import json
import argparse
from pathlib import Path
from datetime import datetime, timezone
from collections import defaultdict
import statistics

PROJECT_ROOT = Path(__file__).parent.parent

JUDGES = ["codestral", "gemini-3-flash", "mimo-v2-flash"]
DETECTORS = [
    "claude-opus-4-5", "deepseek-v3-2", "gemini-3-pro-hyper-extended",
    "gpt-5.2", "grok-4-fast", "llama-4-maverick", "qwen3-coder-plus"
]
PROMPT_TYPES = ["direct", "context_protocol", "context_protocol_cot"]


def load_ground_truth():
    """Load all GS ground truth files."""
    gt_dir = PROJECT_ROOT / "samples/gs/ground_truth"
    ground_truth = {}
    for f in gt_dir.glob("gs_*.json"):
        sample_id = f.stem
        with open(f) as fp:
            ground_truth[sample_id] = json.load(fp)
    return ground_truth


def aggregate_prompt(judge: str, detector: str, prompt_type: str, ground_truth: dict) -> dict:
    """Aggregate results for a specific judge/detector/prompt combination."""
    judge_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/gs/{prompt_type}"

    if not judge_dir.exists():
        return None

    results = {
        "detector": detector,
        "prompt_type": prompt_type,
        "judge_model": judge,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "sample_counts": {
            "total": 0,
            "successful_evaluations": 0,
            "failed_evaluations": 0
        },
        "detection_metrics": {
            "target_found_count": 0,
            "target_detection_rate": 0.0,
            "miss_rate": 0.0,
            "verdict_correct_count": 0,
            "verdict_accuracy": 0.0,
            "total_findings": 0,
            "avg_findings_per_sample": 0.0
        },
        "quality_scores": {
            "avg_rcir": None,
            "avg_ava": None,
            "avg_fsv": None,
            "std_rcir": None,
            "std_ava": None,
            "std_fsv": None,
            "count": 0
        },
        "classification_totals": defaultdict(int),
        "type_match_distribution": defaultdict(int),
        "by_vulnerability_type": defaultdict(lambda: {
            "total_samples": 0,
            "target_found": 0,
            "detection_rate": 0.0,
            "avg_rcir": None,
            "avg_ava": None,
            "avg_fsv": None
        })
    }

    rcir_scores = []
    ava_scores = []
    fsv_scores = []

    vuln_type_scores = defaultdict(lambda: {"rcir": [], "ava": [], "fsv": [], "found": 0, "total": 0})

    for jf in judge_dir.glob("j_gs_*.json"):
        sample_id = jf.stem.replace("j_", "")

        try:
            with open(jf) as fp:
                data = json.load(fp)
        except Exception:
            results["sample_counts"]["failed_evaluations"] += 1
            continue

        if "error" in data:
            results["sample_counts"]["failed_evaluations"] += 1
            continue

        results["sample_counts"]["total"] += 1
        results["sample_counts"]["successful_evaluations"] += 1

        # Get vulnerability type from ground truth
        gt = ground_truth.get(sample_id, {})
        vuln_type = gt.get("vulnerability_type", "unknown")
        vuln_type_scores[vuln_type]["total"] += 1

        # Count findings
        findings = data.get("findings", [])
        results["detection_metrics"]["total_findings"] += len(findings)

        # Classification totals
        for finding in findings:
            classification = finding.get("classification", "UNKNOWN")
            results["classification_totals"][classification] += 1

        # Target assessment
        target = data.get("target_assessment", {})
        if target.get("found", False):
            results["detection_metrics"]["target_found_count"] += 1
            vuln_type_scores[vuln_type]["found"] += 1

            # Type match distribution
            type_match = target.get("type_match", "unknown")
            results["type_match_distribution"][type_match] += 1

            # Quality scores - extract score from nested object
            rcir_obj = target.get("root_cause_identification")
            ava_obj = target.get("attack_vector_validity")
            fsv_obj = target.get("fix_suggestion_validity")

            # Handle both formats: direct number or {"score": x, "reasoning": y}
            def extract_score(obj):
                if obj is None:
                    return None
                if isinstance(obj, dict):
                    return obj.get("score")
                return obj

            rcir = extract_score(rcir_obj)
            ava = extract_score(ava_obj)
            fsv = extract_score(fsv_obj)

            if rcir is not None:
                rcir_scores.append(rcir)
                vuln_type_scores[vuln_type]["rcir"].append(rcir)
            if ava is not None:
                ava_scores.append(ava)
                vuln_type_scores[vuln_type]["ava"].append(ava)
            if fsv is not None:
                fsv_scores.append(fsv)
                vuln_type_scores[vuln_type]["fsv"].append(fsv)
        else:
            # Track misses in type_match
            results["type_match_distribution"]["not_mentioned"] += 1

        # Verdict accuracy (all GS samples are vulnerable)
        verdict = data.get("overall_verdict", {})
        if verdict.get("said_vulnerable", False):
            results["detection_metrics"]["verdict_correct_count"] += 1

    # Calculate rates
    total = results["sample_counts"]["successful_evaluations"]
    if total > 0:
        results["detection_metrics"]["target_detection_rate"] = results["detection_metrics"]["target_found_count"] / total
        results["detection_metrics"]["miss_rate"] = 1 - results["detection_metrics"]["target_detection_rate"]
        results["detection_metrics"]["verdict_accuracy"] = results["detection_metrics"]["verdict_correct_count"] / total
        results["detection_metrics"]["avg_findings_per_sample"] = results["detection_metrics"]["total_findings"] / total

    # Calculate quality score averages
    if rcir_scores:
        results["quality_scores"]["avg_rcir"] = statistics.mean(rcir_scores)
        results["quality_scores"]["std_rcir"] = statistics.stdev(rcir_scores) if len(rcir_scores) > 1 else 0
    if ava_scores:
        results["quality_scores"]["avg_ava"] = statistics.mean(ava_scores)
        results["quality_scores"]["std_ava"] = statistics.stdev(ava_scores) if len(ava_scores) > 1 else 0
    if fsv_scores:
        results["quality_scores"]["avg_fsv"] = statistics.mean(fsv_scores)
        results["quality_scores"]["std_fsv"] = statistics.stdev(fsv_scores) if len(fsv_scores) > 1 else 0
    results["quality_scores"]["count"] = len(rcir_scores)

    # Calculate per-vulnerability-type metrics
    for vtype, scores in vuln_type_scores.items():
        vt_result = {
            "total_samples": scores["total"],
            "target_found": scores["found"],
            "detection_rate": scores["found"] / scores["total"] if scores["total"] > 0 else 0.0,
            "avg_rcir": statistics.mean(scores["rcir"]) if scores["rcir"] else None,
            "avg_ava": statistics.mean(scores["ava"]) if scores["ava"] else None,
            "avg_fsv": statistics.mean(scores["fsv"]) if scores["fsv"] else None
        }
        results["by_vulnerability_type"][vtype] = vt_result

    # Convert defaultdicts to regular dicts for JSON
    results["classification_totals"] = dict(results["classification_totals"])
    results["type_match_distribution"] = dict(results["type_match_distribution"])
    results["by_vulnerability_type"] = dict(results["by_vulnerability_type"])

    return results


def main():
    parser = argparse.ArgumentParser(description="Aggregate GS judge results")
    parser.add_argument("--judge", choices=JUDGES + ["all"], default="all")
    parser.add_argument("--detector", choices=DETECTORS + ["all"], default="all")
    parser.add_argument("--prompt", choices=PROMPT_TYPES + ["all"], default="all")
    parser.add_argument("--output-dir", type=Path, default=None, help="Custom output directory")
    args = parser.parse_args()

    judges = JUDGES if args.judge == "all" else [args.judge]
    detectors = DETECTORS if args.detector == "all" else [args.detector]
    prompts = PROMPT_TYPES if args.prompt == "all" else [args.prompt]

    ground_truth = load_ground_truth()
    print(f"Loaded {len(ground_truth)} ground truth files")

    summary_count = 0
    for judge in judges:
        for detector in detectors:
            for prompt_type in prompts:
                result = aggregate_prompt(judge, detector, prompt_type, ground_truth)
                if result is None:
                    continue

                # Determine output path
                if args.output_dir:
                    out_dir = args.output_dir / judge / detector / "gs" / prompt_type
                else:
                    out_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/gs/{prompt_type}"

                out_dir.mkdir(parents=True, exist_ok=True)
                out_file = out_dir / "_prompt_summary.json"

                with open(out_file, "w") as fp:
                    json.dump(result, fp, indent=2)

                summary_count += 1
                rate = result["detection_metrics"]["target_detection_rate"]
                print(f"{judge}/{detector}/{prompt_type}: {result['detection_metrics']['target_found_count']}/{result['sample_counts']['total']} ({rate:.1%})")

    print(f"\nGenerated {summary_count} summary files")


if __name__ == "__main__":
    main()
