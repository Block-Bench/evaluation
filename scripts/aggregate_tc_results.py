#!/usr/bin/env python3
"""
Aggregate TC variant results into summary files per detector/variant.
Similar to DS tier summaries.
"""

import argparse
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean, stdev

PROJECT_ROOT = Path(__file__).parent.parent

TC_VARIANTS = ['sanitized', 'nocomments', 'chameleon_medical', 'shapeshifter_l3',
               'trojan', 'falseProphet', 'minimalsanitized']

DETECTORS = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
             'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

JUDGES = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']


def aggregate_variant(judge: str, detector: str, variant: str) -> dict:
    """Aggregate results for a single detector/variant combination."""

    judge_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/tc/{variant}"

    if not judge_dir.exists():
        return None

    files = list(judge_dir.glob("j_*.json"))
    if not files:
        return None

    # Initialize counters
    total = 0
    successful = 0
    failed = 0

    target_found = 0
    verdict_correct = 0
    total_findings = 0

    # Quality scores
    rcir_scores = []
    ava_scores = []
    fsv_scores = []

    # Type match distribution
    type_matches = defaultdict(int)

    # Classification totals
    classifications = defaultdict(int)

    # By vulnerability type
    by_vuln_type = defaultdict(lambda: {
        'total': 0, 'found': 0, 'rcir': [], 'ava': [], 'fsv': []
    })

    for f in files:
        try:
            with open(f) as fp:
                data = json.load(fp)

            total += 1

            if data.get('error'):
                failed += 1
                continue

            successful += 1

            # Target assessment
            ta = data.get('target_assessment', {})
            found = ta.get('found', False)

            if found:
                target_found += 1

                # Quality scores
                rcir = ta.get('root_cause_identification', {}).get('score')
                ava = ta.get('attack_vector_validity', {}).get('score')
                fsv = ta.get('fix_suggestion_validity', {}).get('score')

                if rcir is not None:
                    rcir_scores.append(rcir)
                if ava is not None:
                    ava_scores.append(ava)
                if fsv is not None:
                    fsv_scores.append(fsv)

            # Type match
            type_match = ta.get('type_match', 'not_mentioned')
            type_matches[type_match] += 1

            # Overall verdict
            ov = data.get('overall_verdict', {})
            said_vuln = ov.get('said_vulnerable', False)
            # For TC, all samples are vulnerable, so verdict is correct if said_vulnerable
            if said_vuln:
                verdict_correct += 1

            # Findings and classifications
            findings = data.get('findings', [])
            total_findings += len(findings)

            for finding in findings:
                cls = finding.get('classification', 'unknown')
                classifications[cls] += 1

            # Load ground truth for vulnerability type breakdown
            gt_path = PROJECT_ROOT / f"samples/tc/{variant}/ground_truth/{data['sample_id']}.json"
            if gt_path.exists():
                with open(gt_path) as gf:
                    gt = json.load(gf)
                vuln_type = gt.get('vulnerability_type', 'unknown')
                by_vuln_type[vuln_type]['total'] += 1
                if found:
                    by_vuln_type[vuln_type]['found'] += 1
                    if rcir is not None:
                        by_vuln_type[vuln_type]['rcir'].append(rcir)
                    if ava is not None:
                        by_vuln_type[vuln_type]['ava'].append(ava)
                    if fsv is not None:
                        by_vuln_type[vuln_type]['fsv'].append(fsv)

        except Exception as e:
            failed += 1
            continue

    if total == 0:
        return None

    # Calculate metrics
    detection_rate = target_found / successful if successful > 0 else 0
    verdict_accuracy = verdict_correct / successful if successful > 0 else 0
    avg_findings = total_findings / successful if successful > 0 else 0

    # Quality score stats
    def safe_stats(scores):
        if not scores:
            return {'avg': None, 'std': None, 'count': 0}
        return {
            'avg': mean(scores),
            'std': stdev(scores) if len(scores) > 1 else 0,
            'count': len(scores)
        }

    rcir_stats = safe_stats(rcir_scores)
    ava_stats = safe_stats(ava_scores)
    fsv_stats = safe_stats(fsv_scores)

    # Build vulnerability type breakdown
    vuln_breakdown = {}
    for vtype, data in by_vuln_type.items():
        vuln_breakdown[vtype] = {
            'total_samples': data['total'],
            'target_found': data['found'],
            'detection_rate': data['found'] / data['total'] if data['total'] > 0 else 0,
            'avg_rcir': mean(data['rcir']) if data['rcir'] else None,
            'avg_ava': mean(data['ava']) if data['ava'] else None,
            'avg_fsv': mean(data['fsv']) if data['fsv'] else None,
        }

    return {
        'detector': detector,
        'variant': variant,
        'judge_model': judge,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'sample_counts': {
            'total': total,
            'successful_evaluations': successful,
            'failed_evaluations': failed
        },
        'detection_metrics': {
            'target_found_count': target_found,
            'target_detection_rate': detection_rate,
            'miss_rate': 1 - detection_rate,
            'verdict_correct_count': verdict_correct,
            'verdict_accuracy': verdict_accuracy,
            'total_findings': total_findings,
            'avg_findings_per_sample': avg_findings,
        },
        'quality_scores': {
            'avg_rcir': rcir_stats['avg'],
            'avg_ava': ava_stats['avg'],
            'avg_fsv': fsv_stats['avg'],
            'std_rcir': rcir_stats['std'],
            'std_ava': ava_stats['std'],
            'std_fsv': fsv_stats['std'],
            'count': rcir_stats['count']
        },
        'classification_totals': dict(classifications),
        'type_match_distribution': dict(type_matches),
        'by_vulnerability_type': vuln_breakdown
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
