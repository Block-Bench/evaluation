#!/usr/bin/env python3
"""
Aggregate LLM judge results into tier summaries.

Generates _tier_summary.json for each detector model with:
- Overall detection metrics
- Classification totals
- Type match distribution
- Per-vulnerability-type breakdown

Metrics:
- Target Detection Rate (TDR): Rate of finding the target vulnerability
- Lucky Guess Rate (LGR): Correct verdict but no target and no bonus findings
- Ancillary Discovery Rate (ADR): Rate of finding bonus valid vulnerabilities
- Invalid Finding Rate (IFR): Invalid findings / total findings
- False Alarm Density (FAD): Avg invalid findings per sample
"""

import argparse
import json
import statistics
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent


def load_ground_truths(tier: int) -> dict:
    """Load ground truth files indexed by sample_id."""
    gt_dir = PROJECT_ROOT / f"samples/ds/tier{tier}/ground_truth"
    ground_truths = {}
    for f in gt_dir.glob("*.json"):
        sample_id = f.stem
        with open(f) as fp:
            ground_truths[sample_id] = json.load(fp)
    return ground_truths


def aggregate_results(judge_dir: Path, ground_truths: dict) -> dict:
    """Aggregate all judge results in a directory."""

    # Standard classification categories (always include all, even if 0)
    CLASSIFICATION_CATEGORIES = [
        "target_matches", "partial_matches", "bonus_valid",
        "invalid", "mischaracterized", "design_choice",
        "out_of_scope", "security_theater", "informational"
    ]

    # Standard type match categories
    TYPE_MATCH_CATEGORIES = ["exact", "semantic", "partial", "wrong", "not_mentioned"]

    # Initialize counters
    total_samples = 0
    successful_evaluations = 0
    failed_evaluations = 0

    target_found_count = 0
    verdict_correct_count = 0
    total_findings = 0

    # New metric counters
    lucky_guess_count = 0  # Correct verdict but no target and no bonus
    samples_with_bonus = 0  # Samples that have at least one bonus_valid finding

    # Classification counters - initialize all to 0
    classifications = {cat: 0 for cat in CLASSIFICATION_CATEGORIES}
    type_matches = {cat: 0 for cat in TYPE_MATCH_CATEGORIES}

    # Quality score accumulators
    quality_scores = {
        "rcir": [],  # Root Cause Identification
        "ava": [],   # Attack Vector Validity
        "fsv": []    # Fix Suggestion Validity
    }

    # Per vulnerability type
    def make_vuln_type_entry():
        return {
            "total_samples": 0,
            "target_found_count": 0,
            "verdict_correct_count": 0,
            "total_findings": 0,
            "lucky_guess_count": 0,
            "samples_with_bonus": 0,
            "invalid_findings": 0,  # Track per-type for FAD
            "classifications": {cat: 0 for cat in CLASSIFICATION_CATEGORIES},
            "type_matches": {cat: 0 for cat in TYPE_MATCH_CATEGORIES},
            "quality_scores": {"rcir": [], "ava": [], "fsv": []},
            "latencies": []
        }

    by_vuln_type = defaultdict(make_vuln_type_entry)

    latencies = []

    # Process each judge result
    for f in sorted(judge_dir.glob("j_*.json")):
        sample_id = f.stem.replace("j_", "")
        total_samples += 1

        try:
            with open(f) as fp:
                result = json.load(fp)
        except Exception as e:
            failed_evaluations += 1
            continue

        # Check for errors
        if result.get("error"):
            failed_evaluations += 1
            continue

        successful_evaluations += 1

        # Get ground truth info
        gt = ground_truths.get(sample_id, {})
        vuln_type = gt.get("vulnerability_type", "unknown")
        is_vulnerable = gt.get("is_vulnerable", True)

        # Target assessment
        target_assessment = result.get("target_assessment", {})
        # Support both old "found" key and new "complete_found"/"partial_found" keys
        target_found = target_assessment.get("found", False) or \
                       target_assessment.get("complete_found", False) or \
                       target_assessment.get("partial_found", False)
        type_match = target_assessment.get("type_match", "not_mentioned")

        if target_found:
            target_found_count += 1
            by_vuln_type[vuln_type]["target_found_count"] += 1

        # Extract quality scores if target was found
        if target_found:
            rcir = target_assessment.get("root_cause_identification", {})
            ava = target_assessment.get("attack_vector_validity", {})
            fsv = target_assessment.get("fix_suggestion_validity", {})

            if rcir and rcir.get("score") is not None:
                quality_scores["rcir"].append(rcir["score"])
                by_vuln_type[vuln_type]["quality_scores"]["rcir"].append(rcir["score"])
            if ava and ava.get("score") is not None:
                quality_scores["ava"].append(ava["score"])
                by_vuln_type[vuln_type]["quality_scores"]["ava"].append(ava["score"])
            if fsv and fsv.get("score") is not None:
                quality_scores["fsv"].append(fsv["score"])
                by_vuln_type[vuln_type]["quality_scores"]["fsv"].append(fsv["score"])

        # Verdict assessment
        overall_verdict = result.get("overall_verdict", {})
        said_vulnerable = overall_verdict.get("said_vulnerable")
        verdict_correct = (said_vulnerable == is_vulnerable)
        if verdict_correct:
            verdict_correct_count += 1
            by_vuln_type[vuln_type]["verdict_correct_count"] += 1

        # Type match - normalize to standard categories
        type_match_normalized = (type_match or "not_mentioned").lower().replace(" ", "_")
        if type_match_normalized in TYPE_MATCH_CATEGORIES:
            type_matches[type_match_normalized] += 1
            by_vuln_type[vuln_type]["type_matches"][type_match_normalized] += 1
        else:
            type_matches["not_mentioned"] += 1
            by_vuln_type[vuln_type]["type_matches"]["not_mentioned"] += 1

        # Findings classifications
        findings = result.get("findings", [])
        total_findings += len(findings)
        by_vuln_type[vuln_type]["total_findings"] += len(findings)

        # Track per-sample counts for new metrics
        sample_bonus_count = 0
        sample_invalid_count = 0

        for finding in findings:
            classification = finding.get("classification", "unknown")
            # Normalize classification names
            classification_lower = classification.lower().replace(" ", "_").replace("-", "_")

            # Map to standard categories (HALLUCINATED -> INVALID for consistency)
            if classification_lower in ["target_match", "target_matches"]:
                classifications["target_matches"] += 1
                by_vuln_type[vuln_type]["classifications"]["target_matches"] += 1
            elif classification_lower in ["partial_match", "partial_matches"]:
                classifications["partial_matches"] += 1
                by_vuln_type[vuln_type]["classifications"]["partial_matches"] += 1
            elif classification_lower in ["bonus_valid"]:
                classifications["bonus_valid"] += 1
                by_vuln_type[vuln_type]["classifications"]["bonus_valid"] += 1
                sample_bonus_count += 1
            elif classification_lower in ["hallucinated", "invalid"]:
                # Map HALLUCINATED -> INVALID for consistency with traditional tools
                classifications["invalid"] += 1
                by_vuln_type[vuln_type]["classifications"]["invalid"] += 1
                sample_invalid_count += 1
            elif classification_lower in ["mischaracterized"]:
                classifications["mischaracterized"] += 1
                by_vuln_type[vuln_type]["classifications"]["mischaracterized"] += 1
                sample_invalid_count += 1
            elif classification_lower in ["design_choice"]:
                classifications["design_choice"] += 1
                by_vuln_type[vuln_type]["classifications"]["design_choice"] += 1
                sample_invalid_count += 1
            elif classification_lower in ["out_of_scope"]:
                classifications["out_of_scope"] += 1
                by_vuln_type[vuln_type]["classifications"]["out_of_scope"] += 1
                sample_invalid_count += 1
            elif classification_lower in ["security_theater"]:
                classifications["security_theater"] += 1
                by_vuln_type[vuln_type]["classifications"]["security_theater"] += 1
                sample_invalid_count += 1
            elif classification_lower in ["informational"]:
                classifications["informational"] += 1
                by_vuln_type[vuln_type]["classifications"]["informational"] += 1
                sample_invalid_count += 1
            else:
                # Unknown classifications go to invalid
                classifications["invalid"] += 1
                by_vuln_type[vuln_type]["classifications"]["invalid"] += 1
                sample_invalid_count += 1

        # Track samples with bonus findings (for ADR)
        if sample_bonus_count > 0:
            samples_with_bonus += 1
            by_vuln_type[vuln_type]["samples_with_bonus"] += 1

        # Track invalid findings per type (for FAD calculation)
        by_vuln_type[vuln_type]["invalid_findings"] += sample_invalid_count

        # Lucky Guess: correct verdict (vulnerable) but no target and no bonus
        # Note: All tier1 samples are vulnerable, so verdict_correct means said_vulnerable=True
        if verdict_correct and not target_found and sample_bonus_count == 0:
            lucky_guess_count += 1
            by_vuln_type[vuln_type]["lucky_guess_count"] += 1

        # Per vuln type sample count
        by_vuln_type[vuln_type]["total_samples"] += 1

        # Latency
        latency = result.get("judge_latency_ms")
        if latency:
            latencies.append(latency)
            by_vuln_type[vuln_type]["latencies"].append(latency)

    # Compute metrics
    def safe_div(a, b):
        return a / b if b > 0 else 0.0

    def safe_avg(lst):
        return sum(lst) / len(lst) if lst else None

    def safe_std(lst):
        return statistics.stdev(lst) if len(lst) > 1 else None

    # True positives = target_matches + partial_matches + bonus_valid
    true_positives = classifications["target_matches"] + \
                     classifications["partial_matches"] + \
                     classifications["bonus_valid"]

    # False positives = invalid + mischaracterized + design_choice + out_of_scope + security_theater + informational
    false_positives = classifications["invalid"] + \
                      classifications["mischaracterized"] + \
                      classifications["design_choice"] + \
                      classifications["out_of_scope"] + \
                      classifications["security_theater"] + \
                      classifications["informational"]

    precision = safe_div(true_positives, true_positives + false_positives)
    target_detection_rate = safe_div(target_found_count, successful_evaluations)
    f1_score = safe_div(2 * precision * target_detection_rate, precision + target_detection_rate) if (precision + target_detection_rate) > 0 else None

    # New metrics
    lucky_guess_rate = safe_div(lucky_guess_count, successful_evaluations)
    ancillary_discovery_rate = safe_div(samples_with_bonus, successful_evaluations)
    invalid_finding_rate = safe_div(false_positives, total_findings)
    false_alarm_density = safe_div(false_positives, successful_evaluations)

    # Build by_vulnerability_type with computed metrics
    by_vuln_type_output = {}
    for vtype, data in by_vuln_type.items():
        vt_total = data["total_samples"]
        vt_found = data["target_found_count"]
        vt_correct = data["verdict_correct_count"]
        vt_findings = data["total_findings"]

        # True/false positives for this type
        vt_tp = data["classifications"]["target_matches"] + \
                data["classifications"]["partial_matches"] + \
                data["classifications"]["bonus_valid"]
        vt_fp = data["classifications"]["invalid"] + \
                data["classifications"]["mischaracterized"] + \
                data["classifications"]["design_choice"] + \
                data["classifications"]["out_of_scope"] + \
                data["classifications"]["security_theater"] + \
                data["classifications"]["informational"]

        vt_precision = safe_div(vt_tp, vt_tp + vt_fp)
        vt_tdr = safe_div(vt_found, vt_total)
        vt_f1 = safe_div(2 * vt_precision * vt_tdr, vt_precision + vt_tdr) if (vt_precision + vt_tdr) > 0 else None

        # Per-type new metrics
        vt_lgr = safe_div(data["lucky_guess_count"], vt_total)
        vt_adr = safe_div(data["samples_with_bonus"], vt_total)
        vt_ifr = safe_div(vt_fp, vt_findings) if vt_findings > 0 else 0.0
        vt_fad = safe_div(vt_fp, vt_total)

        by_vuln_type_output[vtype] = {
            "total_samples": vt_total,
            "target_found_count": vt_found,
            "target_detection_rate": vt_tdr,
            "miss_rate": 1.0 - vt_tdr,
            "lucky_guess_count": data["lucky_guess_count"],
            "lucky_guess_rate": vt_lgr,
            "samples_with_bonus": data["samples_with_bonus"],
            "ancillary_discovery_rate": vt_adr,
            "verdict_correct_count": vt_correct,
            "verdict_accuracy": safe_div(vt_correct, vt_total),
            "total_findings": vt_findings,
            "avg_findings_per_sample": safe_div(vt_findings, vt_total),
            "true_positives": vt_tp,
            "false_positives": vt_fp,
            "precision": vt_precision,
            "invalid_finding_rate": vt_ifr,
            "false_alarm_density": vt_fad,
            "f1_score": vt_f1,
            "classifications": data["classifications"],
            "type_match_distribution": data["type_matches"],
            "quality_scores": {
                "avg_rcir": safe_avg(data["quality_scores"]["rcir"]),
                "avg_ava": safe_avg(data["quality_scores"]["ava"]),
                "avg_fsv": safe_avg(data["quality_scores"]["fsv"]),
                "std_rcir": safe_std(data["quality_scores"]["rcir"]),
                "std_ava": safe_std(data["quality_scores"]["ava"]),
                "std_fsv": safe_std(data["quality_scores"]["fsv"]),
                "count": len(data["quality_scores"]["rcir"])
            }
        }

    return {
        "sample_counts": {
            "total": total_samples,
            "successful_evaluations": successful_evaluations,
            "failed_evaluations": failed_evaluations
        },
        "detection_metrics": {
            "target_found_count": target_found_count,
            "target_detection_rate": target_detection_rate,
            "miss_rate": 1.0 - target_detection_rate,
            "lucky_guess_count": lucky_guess_count,
            "lucky_guess_rate": lucky_guess_rate,
            "samples_with_bonus": samples_with_bonus,
            "ancillary_discovery_rate": ancillary_discovery_rate,
            "verdict_correct_count": verdict_correct_count,
            "verdict_accuracy": safe_div(verdict_correct_count, successful_evaluations),
            "total_findings": total_findings,
            "avg_findings_per_sample": safe_div(total_findings, successful_evaluations),
            "true_positives": true_positives,
            "false_positives": false_positives,
            "precision": precision,
            "invalid_finding_rate": invalid_finding_rate,
            "false_alarm_density": false_alarm_density,
            "f1_score": f1_score
        },
        "quality_scores": {
            "avg_rcir": safe_avg(quality_scores["rcir"]),
            "avg_ava": safe_avg(quality_scores["ava"]),
            "avg_fsv": safe_avg(quality_scores["fsv"]),
            "std_rcir": safe_std(quality_scores["rcir"]),
            "std_ava": safe_std(quality_scores["ava"]),
            "std_fsv": safe_std(quality_scores["fsv"]),
            "count": len(quality_scores["rcir"])
        },
        "classification_totals": classifications,
        "type_match_distribution": type_matches,
        "by_vulnerability_type": by_vuln_type_output,
        "performance": {
            "avg_latency_ms": sum(latencies) / len(latencies) if latencies else None
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Aggregate LLM judge results")
    parser.add_argument("--judge", "-j", required=True, help="Judge model (codestral, gemini-3-flash)")
    parser.add_argument("--detector", "-d", help="Specific detector model (default: all)")
    parser.add_argument("--tier", "-t", type=int, default=1, help="Tier (default: 1)")
    parser.add_argument("--force", "-f", action="store_true", help="Overwrite existing summaries")

    args = parser.parse_args()

    # Load ground truths
    ground_truths = load_ground_truths(args.tier)
    print(f"Loaded {len(ground_truths)} ground truths for tier{args.tier}")

    # Find detector directories
    judge_base = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}"

    if args.detector:
        detectors = [args.detector]
    else:
        # Find all detector directories (exclude traditional tools)
        traditional = {"slither", "mythril"}
        detectors = [d.name for d in judge_base.iterdir()
                    if d.is_dir() and d.name not in traditional and d.name != "ds"]

    print(f"Processing {len(detectors)} detectors: {detectors}")

    for detector in detectors:
        judge_dir = judge_base / detector / "ds" / f"tier{args.tier}"

        if not judge_dir.exists():
            print(f"\n{detector}: No results directory found, skipping")
            continue

        output_file = judge_dir / "_tier_summary.json"

        if output_file.exists() and not args.force:
            print(f"\n{detector}: Summary exists, skipping (use --force to overwrite)")
            continue

        print(f"\n{detector}: Aggregating results...")

        # Aggregate
        results = aggregate_results(judge_dir, ground_truths)

        # Add metadata
        summary = {
            "detector": detector,
            "tier": f"tier{args.tier}",
            "judge_model": args.judge,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **results
        }

        # Save
        with open(output_file, "w") as f:
            json.dump(summary, f, indent=2)

        print(f"  Saved: {output_file}")
        dm = results['detection_metrics']
        print(f"  TDR: {dm['target_found_count']}/{results['sample_counts']['successful_evaluations']} ({dm['target_detection_rate']:.1%})")
        print(f"  LGR: {dm['lucky_guess_rate']:.1%} | ADR: {dm['ancillary_discovery_rate']:.1%} | IFR: {dm['invalid_finding_rate']:.1%} | FAD: {dm['false_alarm_density']:.2f}")

        # Print per-type summary
        print(f"  By vulnerability type:")
        for vtype, metrics in sorted(results["by_vulnerability_type"].items()):
            tdr = metrics["target_detection_rate"]
            total = metrics["total_samples"]
            found = metrics["target_found_count"]
            print(f"    {vtype}: {found}/{total} ({tdr:.0%})")


if __name__ == "__main__":
    main()
