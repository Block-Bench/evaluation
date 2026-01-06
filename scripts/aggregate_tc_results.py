#!/usr/bin/env python3
"""
Aggregate TC variant results into summary files per detector/variant.
Matches the DS tier summary structure with all metrics.

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

TC_VARIANTS = ['sanitized', 'nocomments', 'chameleon_medical', 'shapeshifter_l3',
               'trojan', 'falseProphet', 'minimalsanitized', 'differential']

DETECTORS = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
             'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

JUDGES = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']

# Standard classification categories (always include all, even if 0)
CLASSIFICATION_CATEGORIES = [
    "target_matches", "partial_matches", "bonus_valid",
    "invalid", "mischaracterized", "design_choice",
    "out_of_scope", "security_theater", "informational"
]

# Standard type match categories
TYPE_MATCH_CATEGORIES = ["exact", "semantic", "partial", "wrong", "not_mentioned"]


def safe_div(a, b):
    """Safe division avoiding ZeroDivisionError."""
    return a / b if b > 0 else 0.0


def safe_avg(lst):
    """Safe average of a list."""
    return sum(lst) / len(lst) if lst else None


def safe_std(lst):
    """Safe standard deviation of a list."""
    return statistics.stdev(lst) if len(lst) > 1 else None


def aggregate_variant(judge: str, detector: str, variant: str) -> dict:
    """Aggregate results for a single detector/variant combination."""

    judge_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/tc/{variant}"

    if not judge_dir.exists():
        return None

    files = list(judge_dir.glob("j_*.json"))
    if not files:
        return None

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
            "invalid_findings": 0,
            "classifications": {cat: 0 for cat in CLASSIFICATION_CATEGORIES},
            "type_matches": {cat: 0 for cat in TYPE_MATCH_CATEGORIES},
            "quality_scores": {"rcir": [], "ava": [], "fsv": []},
            "latencies": []
        }

    by_vuln_type = defaultdict(make_vuln_type_entry)
    latencies = []

    for f in sorted(files):
        sample_id = f.stem.replace("j_", "")
        total_samples += 1

        try:
            with open(f) as fp:
                data = json.load(fp)
        except Exception:
            failed_evaluations += 1
            continue

        if data.get('error'):
            failed_evaluations += 1
            continue

        successful_evaluations += 1

        # Load ground truth for vulnerability type
        gt_path = PROJECT_ROOT / f"samples/tc/{variant}/ground_truth/{sample_id}.json"
        vuln_type = "unknown"
        is_vulnerable = True  # TC samples are all vulnerable
        if gt_path.exists():
            try:
                with open(gt_path) as gf:
                    gt = json.load(gf)
                vuln_type = gt.get('vulnerability_type', 'unknown')
                is_vulnerable = gt.get('is_vulnerable', True)
            except Exception:
                pass

        # Target assessment
        ta = data.get('target_assessment', {})
        target_found = ta.get('found', False)
        type_match = ta.get('type_match', 'not_mentioned')

        if target_found:
            target_found_count += 1
            by_vuln_type[vuln_type]["target_found_count"] += 1

            # Quality scores (only when target found)
            rcir = ta.get('root_cause_identification', {})
            ava = ta.get('attack_vector_validity', {})
            fsv = ta.get('fix_suggestion_validity', {})

            if rcir and rcir.get('score') is not None:
                quality_scores["rcir"].append(rcir["score"])
                by_vuln_type[vuln_type]["quality_scores"]["rcir"].append(rcir["score"])
            if ava and ava.get('score') is not None:
                quality_scores["ava"].append(ava["score"])
                by_vuln_type[vuln_type]["quality_scores"]["ava"].append(ava["score"])
            if fsv and fsv.get('score') is not None:
                quality_scores["fsv"].append(fsv["score"])
                by_vuln_type[vuln_type]["quality_scores"]["fsv"].append(fsv["score"])

        # Verdict assessment
        ov = data.get('overall_verdict', {})
        said_vulnerable = ov.get('said_vulnerable')
        verdict_correct = (said_vulnerable == is_vulnerable)
        if verdict_correct:
            verdict_correct_count += 1
            by_vuln_type[vuln_type]["verdict_correct_count"] += 1

        # Type match - normalize to standard categories
        type_match_normalized = type_match.lower().replace(" ", "_")
        if type_match_normalized in TYPE_MATCH_CATEGORIES:
            type_matches[type_match_normalized] += 1
            by_vuln_type[vuln_type]["type_matches"][type_match_normalized] += 1
        else:
            type_matches["not_mentioned"] += 1
            by_vuln_type[vuln_type]["type_matches"]["not_mentioned"] += 1

        # Findings classifications
        findings = data.get('findings', [])
        total_findings += len(findings)
        by_vuln_type[vuln_type]["total_findings"] += len(findings)

        # Track per-sample counts for new metrics
        sample_bonus_count = 0
        sample_invalid_count = 0

        for finding in findings:
            classification = finding.get('classification', 'unknown')
            classification_lower = classification.lower().replace(" ", "_").replace("-", "_")

            # Map to standard categories
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
                classifications["invalid"] += 1
                by_vuln_type[vuln_type]["classifications"]["invalid"] += 1
                sample_invalid_count += 1

        # Track samples with bonus findings (for ADR)
        if sample_bonus_count > 0:
            samples_with_bonus += 1
            by_vuln_type[vuln_type]["samples_with_bonus"] += 1

        # Track invalid findings per type (for FAD calculation)
        by_vuln_type[vuln_type]["invalid_findings"] += sample_invalid_count

        # Lucky Guess: correct verdict but no target and no bonus
        if verdict_correct and not target_found and sample_bonus_count == 0:
            lucky_guess_count += 1
            by_vuln_type[vuln_type]["lucky_guess_count"] += 1

        # Per vuln type sample count
        by_vuln_type[vuln_type]["total_samples"] += 1

        # Latency
        latency = data.get('judge_latency_ms')
        if latency:
            latencies.append(latency)
            by_vuln_type[vuln_type]["latencies"].append(latency)

    if total_samples == 0:
        return None

    # True positives = target_matches + partial_matches + bonus_valid
    true_positives = (classifications["target_matches"] +
                     classifications["partial_matches"] +
                     classifications["bonus_valid"])

    # False positives = invalid + mischaracterized + design_choice + out_of_scope + security_theater + informational
    false_positives = (classifications["invalid"] +
                      classifications["mischaracterized"] +
                      classifications["design_choice"] +
                      classifications["out_of_scope"] +
                      classifications["security_theater"] +
                      classifications["informational"])

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
    for vtype, vdata in by_vuln_type.items():
        vt_total = vdata["total_samples"]
        vt_found = vdata["target_found_count"]
        vt_correct = vdata["verdict_correct_count"]
        vt_findings = vdata["total_findings"]

        # True/false positives for this type
        vt_tp = (vdata["classifications"]["target_matches"] +
                vdata["classifications"]["partial_matches"] +
                vdata["classifications"]["bonus_valid"])
        vt_fp = (vdata["classifications"]["invalid"] +
                vdata["classifications"]["mischaracterized"] +
                vdata["classifications"]["design_choice"] +
                vdata["classifications"]["out_of_scope"] +
                vdata["classifications"]["security_theater"] +
                vdata["classifications"]["informational"])

        vt_precision = safe_div(vt_tp, vt_tp + vt_fp)
        vt_tdr = safe_div(vt_found, vt_total)
        vt_f1 = safe_div(2 * vt_precision * vt_tdr, vt_precision + vt_tdr) if (vt_precision + vt_tdr) > 0 else None

        # Per-type new metrics
        vt_lgr = safe_div(vdata["lucky_guess_count"], vt_total)
        vt_adr = safe_div(vdata["samples_with_bonus"], vt_total)
        vt_ifr = safe_div(vt_fp, vt_findings) if vt_findings > 0 else 0.0
        vt_fad = safe_div(vt_fp, vt_total)

        by_vuln_type_output[vtype] = {
            "total_samples": vt_total,
            "target_found_count": vt_found,
            "target_detection_rate": vt_tdr,
            "miss_rate": 1.0 - vt_tdr,
            "lucky_guess_count": vdata["lucky_guess_count"],
            "lucky_guess_rate": vt_lgr,
            "samples_with_bonus": vdata["samples_with_bonus"],
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
            "classifications": vdata["classifications"],
            "type_match_distribution": vdata["type_matches"],
            "quality_scores": {
                "avg_rcir": safe_avg(vdata["quality_scores"]["rcir"]),
                "avg_ava": safe_avg(vdata["quality_scores"]["ava"]),
                "avg_fsv": safe_avg(vdata["quality_scores"]["fsv"]),
                "std_rcir": safe_std(vdata["quality_scores"]["rcir"]),
                "std_ava": safe_std(vdata["quality_scores"]["ava"]),
                "std_fsv": safe_std(vdata["quality_scores"]["fsv"]),
                "count": len(vdata["quality_scores"]["rcir"])
            }
        }

    return {
        'detector': detector,
        'variant': variant,
        'judge_model': judge,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'sample_counts': {
            'total': total_samples,
            'successful_evaluations': successful_evaluations,
            'failed_evaluations': failed_evaluations
        },
        'detection_metrics': {
            'target_found_count': target_found_count,
            'target_detection_rate': target_detection_rate,
            'miss_rate': 1.0 - target_detection_rate,
            'lucky_guess_count': lucky_guess_count,
            'lucky_guess_rate': lucky_guess_rate,
            'samples_with_bonus': samples_with_bonus,
            'ancillary_discovery_rate': ancillary_discovery_rate,
            'verdict_correct_count': verdict_correct_count,
            'verdict_accuracy': safe_div(verdict_correct_count, successful_evaluations),
            'total_findings': total_findings,
            'avg_findings_per_sample': safe_div(total_findings, successful_evaluations),
            'true_positives': true_positives,
            'false_positives': false_positives,
            'precision': precision,
            'invalid_finding_rate': invalid_finding_rate,
            'false_alarm_density': false_alarm_density,
            'f1_score': f1_score
        },
        'quality_scores': {
            'avg_rcir': safe_avg(quality_scores["rcir"]),
            'avg_ava': safe_avg(quality_scores["ava"]),
            'avg_fsv': safe_avg(quality_scores["fsv"]),
            'std_rcir': safe_std(quality_scores["rcir"]),
            'std_ava': safe_std(quality_scores["ava"]),
            'std_fsv': safe_std(quality_scores["fsv"]),
            'count': len(quality_scores["rcir"])
        },
        'classification_totals': classifications,
        'type_match_distribution': type_matches,
        'by_vulnerability_type': by_vuln_type_output,
        'performance': {
            'avg_latency_ms': safe_avg(latencies)
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Aggregate TC variant results")
    parser.add_argument("--judge", "-j", default="codestral", choices=JUDGES)
    parser.add_argument("--detector", "-d", help="Specific detector (default: all)")
    parser.add_argument("--variant", "-v", help="Specific variant (default: all)")
    parser.add_argument("--verbose", action="store_true")

    args = parser.parse_args()

    detectors = [args.detector] if args.detector else DETECTORS
    variants = [args.variant] if args.variant else TC_VARIANTS

    for detector in detectors:
        for variant in variants:
            summary = aggregate_variant(args.judge, detector, variant)

            if summary is None:
                if args.verbose:
                    print(f"{detector}/{variant}: No data")
                continue

            # Save summary
            out_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{detector}/tc/{variant}"
            out_path = out_dir / "_variant_summary.json"

            with open(out_path, 'w') as f:
                json.dump(summary, f, indent=2)

            # Print summary
            dm = summary['detection_metrics']
            qs = summary['quality_scores']
            print(f"{detector}/{variant}: {dm['target_found_count']}/{summary['sample_counts']['successful_evaluations']} found ({dm['target_detection_rate']:.1%}), "
                  f"RCIR={qs['avg_rcir']:.2f}" if qs['avg_rcir'] else f"{detector}/{variant}: {dm['target_found_count']}/{summary['sample_counts']['successful_evaluations']} found ({dm['target_detection_rate']:.1%})")


if __name__ == "__main__":
    main()
