#!/usr/bin/env python3
"""
Aggregate TC judge metrics per variant for each detector and judge.
Reports counts and metrics to verify data completeness.

IMPORTANT: Differential variant contains FIXED/SAFE code (is_vulnerable: false).
For differential:
  - target_found: true = FALSE POSITIVE (model incorrectly found vuln in safe code)
  - verdict_safe = CORRECT (model correctly identified code as safe)
For all other variants (is_vulnerable: true):
  - target_found: true = TRUE POSITIVE (model correctly found the vulnerability)
  - verdict_vulnerable = CORRECT
"""

import json
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent

# All variants, detectors, and judges
# Note: differential is SAFE code (is_vulnerable: false), all others are VULNERABLE
VARIANTS = ['minimalsanitized', 'sanitized', 'nocomments', 'shapeshifter_l3', 'differential', 'falseProphet', 'trojan']
SAFE_VARIANTS = ['differential']  # Variants where is_vulnerable: false
DETECTORS = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2', 'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']
JUDGES = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']


def aggregate_variant(judge: str, detector: str, variant: str) -> dict:
    """Aggregate metrics for a single variant."""
    judge_dir = PROJECT_ROOT / f'results/detection_evaluation/llm-judge/{judge}/{detector}/tc/{variant}'

    if not judge_dir.exists():
        return None

    judge_files = list(judge_dir.glob('j_*.json'))

    metrics = {
        'total_samples': len(judge_files),
        'target_found': 0,
        'target_not_found': 0,
        'verdict_vulnerable': 0,
        'verdict_safe': 0,
        'parse_errors': 0,
        'avg_findings': 0,
        'total_findings': 0,
    }

    for jf in judge_files:
        try:
            data = json.loads(jf.read_text())

            # Target found
            target_found = data.get('target_assessment', {}).get('found', False)
            if target_found:
                metrics['target_found'] += 1
            else:
                metrics['target_not_found'] += 1

            # Verdict
            said_vulnerable = data.get('overall_verdict', {}).get('said_vulnerable', False)
            if said_vulnerable:
                metrics['verdict_vulnerable'] += 1
            else:
                metrics['verdict_safe'] += 1

            # Findings count
            findings = data.get('findings', [])
            metrics['total_findings'] += len(findings)

        except Exception as e:
            metrics['parse_errors'] += 1

    if metrics['total_samples'] > 0:
        metrics['avg_findings'] = round(metrics['total_findings'] / metrics['total_samples'], 2)
        metrics['target_found_rate'] = round(metrics['target_found'] / metrics['total_samples'] * 100, 1)
    else:
        metrics['target_found_rate'] = 0

    return metrics


def main():
    print("=" * 120)
    print("TC JUDGE AGGREGATED METRICS BY VARIANT")
    print("=" * 120)

    for judge in JUDGES:
        print(f"\n{'=' * 120}")
        print(f"JUDGE: {judge}")
        print("=" * 120)

        # Header
        print(f"\n{'Detector':<20} {'Variant':<18} {'Samples':>8} {'Target+':>8} {'Target-':>8} {'Rate':>7} {'Vuln':>6} {'Safe':>6} {'Findings':>8} {'Errors':>7}")
        print("-" * 120)

        for detector in DETECTORS:
            for variant in VARIANTS:
                metrics = aggregate_variant(judge, detector, variant)

                if metrics is None:
                    print(f"{detector:<20} {variant:<18} {'--':>8} {'--':>8} {'--':>8} {'--':>7} {'--':>6} {'--':>6} {'--':>8} {'--':>7}")
                else:
                    print(f"{detector:<20} {variant:<18} {metrics['total_samples']:>8} {metrics['target_found']:>8} {metrics['target_not_found']:>8} {metrics['target_found_rate']:>6.1f}% {metrics['verdict_vulnerable']:>6} {metrics['verdict_safe']:>6} {metrics['total_findings']:>8} {metrics['parse_errors']:>7}")

            print()  # Empty line between detectors

    # Summary by judge
    print("\n" + "=" * 120)
    print("SUMMARY BY JUDGE (all detectors, all variants)")
    print("=" * 120)
    print(f"\n{'Judge':<20} {'Total Samples':>15} {'Target Found':>15} {'Target Rate':>12} {'Parse Errors':>15}")
    print("-" * 80)

    for judge in JUDGES:
        total_samples = 0
        total_target_found = 0
        total_errors = 0

        for detector in DETECTORS:
            for variant in VARIANTS:
                metrics = aggregate_variant(judge, detector, variant)
                if metrics:
                    total_samples += metrics['total_samples']
                    total_target_found += metrics['target_found']
                    total_errors += metrics['parse_errors']

        rate = round(total_target_found / total_samples * 100, 1) if total_samples > 0 else 0
        print(f"{judge:<20} {total_samples:>15} {total_target_found:>15} {rate:>11.1f}% {total_errors:>15}")


if __name__ == '__main__':
    main()
