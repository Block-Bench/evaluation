#!/usr/bin/env python3
"""
Aggregate all detection metrics across all DS tiers, per judge and per detector.
"""
import json
from pathlib import Path
from collections import defaultdict
import argparse


def aggregate_metrics():
    base = Path('results/detection_evaluation/llm-judge')
    output_dir = Path('results/detection_evaluation/ds_aggregated')
    output_dir.mkdir(parents=True, exist_ok=True)

    judges = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']
    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'deepseek-v3-2', 'gpt-5.2',
                 'llama-4-maverick', 'qwen3-coder-plus', 'grok-4-fast']
    tiers = ['tier1', 'tier2', 'tier3', 'tier4']

    # Store results per judge
    for judge in judges:
        judge_results = {
            'judge': judge,
            'by_detector': {},
            'overall': {
                'sample_counts': {'total': 0, 'successful': 0, 'failed': 0},
                'detection_metrics': defaultdict(float),
                'quality_scores': defaultdict(list),
                'classification_totals': defaultdict(int),
                'type_match_distribution': defaultdict(int),
            }
        }

        for detector in detectors:
            det_agg = {
                'detector': detector,
                'sample_counts': {'total': 0, 'successful': 0, 'failed': 0},
                'detection_metrics': {
                    'target_found_count': 0,
                    'verdict_correct_count': 0,
                    'lucky_guess_count': 0,
                    'samples_with_bonus': 0,
                    'total_findings': 0,
                    'true_positives': 0,
                    'false_positives': 0,
                },
                'quality_scores': {
                    'rcir_values': [],
                    'ava_values': [],
                    'fsv_values': [],
                },
                'classification_totals': defaultdict(int),
                'type_match_distribution': defaultdict(int),
                'by_tier': {},
            }

            for tier in tiers:
                summary_file = base / judge / detector / 'ds' / tier / '_tier_summary.json'
                if not summary_file.exists():
                    continue

                with open(summary_file) as f:
                    data = json.load(f)

                # Store tier data
                det_agg['by_tier'][tier] = {
                    'samples': data['sample_counts']['total'],
                    'tdr': data['detection_metrics']['target_detection_rate'],
                    'precision': data['detection_metrics']['precision'],
                    'f1_score': data['detection_metrics']['f1_score'],
                    'verdict_accuracy': data['detection_metrics']['verdict_accuracy'],
                    'avg_rcir': data['quality_scores']['avg_rcir'],
                    'avg_ava': data['quality_scores']['avg_ava'],
                    'avg_fsv': data['quality_scores']['avg_fsv'],
                }

                # Aggregate sample counts
                det_agg['sample_counts']['total'] += data['sample_counts']['total']
                det_agg['sample_counts']['successful'] += data['sample_counts']['successful_evaluations']
                det_agg['sample_counts']['failed'] += data['sample_counts']['failed_evaluations']

                # Aggregate detection metrics (counts)
                dm = data['detection_metrics']
                det_agg['detection_metrics']['target_found_count'] += dm['target_found_count']
                det_agg['detection_metrics']['verdict_correct_count'] += dm['verdict_correct_count']
                det_agg['detection_metrics']['lucky_guess_count'] += dm['lucky_guess_count']
                det_agg['detection_metrics']['samples_with_bonus'] += dm['samples_with_bonus']
                det_agg['detection_metrics']['total_findings'] += dm['total_findings']
                det_agg['detection_metrics']['true_positives'] += dm['true_positives']
                det_agg['detection_metrics']['false_positives'] += dm['false_positives']

                # Aggregate quality scores (collect for averaging)
                qs = data['quality_scores']
                n = qs['count']
                det_agg['quality_scores']['rcir_values'].extend([qs['avg_rcir']] * n)
                det_agg['quality_scores']['ava_values'].extend([qs['avg_ava']] * n)
                det_agg['quality_scores']['fsv_values'].extend([qs['avg_fsv']] * n)

                # Aggregate classification totals
                for k, v in data['classification_totals'].items():
                    det_agg['classification_totals'][k] += v

                # Aggregate type match distribution
                for k, v in data['type_match_distribution'].items():
                    det_agg['type_match_distribution'][k] += v

            # Calculate derived metrics for detector
            total = det_agg['sample_counts']['total']
            if total > 0:
                dm = det_agg['detection_metrics']
                det_agg['detection_metrics']['target_detection_rate'] = dm['target_found_count'] / total
                det_agg['detection_metrics']['miss_rate'] = 1 - (dm['target_found_count'] / total)
                det_agg['detection_metrics']['verdict_accuracy'] = dm['verdict_correct_count'] / total
                det_agg['detection_metrics']['lucky_guess_rate'] = dm['lucky_guess_count'] / total
                det_agg['detection_metrics']['ancillary_discovery_rate'] = dm['samples_with_bonus'] / total
                det_agg['detection_metrics']['avg_findings_per_sample'] = dm['total_findings'] / total

                tp = dm['true_positives']
                fp = dm['false_positives']
                if tp + fp > 0:
                    det_agg['detection_metrics']['precision'] = tp / (tp + fp)
                    det_agg['detection_metrics']['invalid_finding_rate'] = fp / (tp + fp)
                else:
                    det_agg['detection_metrics']['precision'] = 0
                    det_agg['detection_metrics']['invalid_finding_rate'] = 0

                det_agg['detection_metrics']['false_alarm_density'] = fp / total

                # F1 score: 2 * (precision * recall) / (precision + recall)
                # Here recall = TDR
                prec = det_agg['detection_metrics']['precision']
                rec = det_agg['detection_metrics']['target_detection_rate']
                if prec + rec > 0:
                    det_agg['detection_metrics']['f1_score'] = 2 * prec * rec / (prec + rec)
                else:
                    det_agg['detection_metrics']['f1_score'] = 0

            # Calculate average quality scores
            qs = det_agg['quality_scores']
            if qs['rcir_values']:
                det_agg['quality_scores']['avg_rcir'] = sum(qs['rcir_values']) / len(qs['rcir_values'])
                det_agg['quality_scores']['avg_ava'] = sum(qs['ava_values']) / len(qs['ava_values'])
                det_agg['quality_scores']['avg_fsv'] = sum(qs['fsv_values']) / len(qs['fsv_values'])

            # Clean up temp lists
            del det_agg['quality_scores']['rcir_values']
            del det_agg['quality_scores']['ava_values']
            del det_agg['quality_scores']['fsv_values']

            # Convert defaultdicts to regular dicts
            det_agg['classification_totals'] = dict(det_agg['classification_totals'])
            det_agg['type_match_distribution'] = dict(det_agg['type_match_distribution'])

            judge_results['by_detector'][detector] = det_agg

            # Accumulate to overall
            judge_results['overall']['sample_counts']['total'] += det_agg['sample_counts']['total']
            judge_results['overall']['sample_counts']['successful'] += det_agg['sample_counts']['successful']
            judge_results['overall']['sample_counts']['failed'] += det_agg['sample_counts']['failed']

        # Save per-judge results
        with open(output_dir / f'all_metrics_{judge}.json', 'w') as f:
            json.dump(judge_results, f, indent=2)

        print(f"\n{'='*80}")
        print(f"AGGREGATED DS METRICS - JUDGE: {judge.upper()}")
        print(f"{'='*80}")

        # Print summary table
        print(f"\n{'Detector':<20} {'Samples':>8} {'TDR':>8} {'Prec':>8} {'F1':>8} {'VerdAcc':>8} {'RCIR':>8} {'AVA':>8} {'FSV':>8}")
        print("-" * 100)

        sorted_dets = sorted(judge_results['by_detector'].items(),
                            key=lambda x: -x[1]['detection_metrics'].get('target_detection_rate', 0))

        for det, data in sorted_dets:
            dm = data['detection_metrics']
            qs = data['quality_scores']
            print(f"{det:<20} {data['sample_counts']['total']:>8} "
                  f"{dm.get('target_detection_rate', 0)*100:>7.1f}% "
                  f"{dm.get('precision', 0)*100:>7.1f}% "
                  f"{dm.get('f1_score', 0)*100:>7.1f}% "
                  f"{dm.get('verdict_accuracy', 0)*100:>7.1f}% "
                  f"{qs.get('avg_rcir', 0):>8.3f} "
                  f"{qs.get('avg_ava', 0):>8.3f} "
                  f"{qs.get('avg_fsv', 0):>8.3f}")

        # Print classification breakdown
        print(f"\n{'Detector':<20} {'TargetMatch':>12} {'Partial':>10} {'Bonus':>10} {'Invalid':>10} {'Mischar':>10}")
        print("-" * 80)
        for det, data in sorted_dets:
            ct = data['classification_totals']
            print(f"{det:<20} {ct.get('target_matches', 0):>12} {ct.get('partial_matches', 0):>10} "
                  f"{ct.get('bonus_valid', 0):>10} {ct.get('invalid', 0):>10} {ct.get('mischaracterized', 0):>10}")

        # Print type match distribution
        print(f"\n{'Detector':<20} {'Exact':>10} {'Semantic':>10} {'Partial':>10} {'Wrong':>10} {'NotMentioned':>12}")
        print("-" * 85)
        for det, data in sorted_dets:
            tm = data['type_match_distribution']
            print(f"{det:<20} {tm.get('exact', 0):>10} {tm.get('semantic', 0):>10} "
                  f"{tm.get('partial', 0):>10} {tm.get('wrong', 0):>10} {tm.get('not_mentioned', 0):>12}")

    print(f"\n\nResults saved to: {output_dir}")


if __name__ == '__main__':
    aggregate_metrics()
