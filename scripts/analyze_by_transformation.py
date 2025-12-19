#!/usr/bin/env python3
"""
Analyze model performance by transformation type.
"""

import json
from pathlib import Path
from collections import defaultdict
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.data.sample_loader import SampleLoader

def analyze_transformation_performance(model_name: str):
    """Analyze performance by transformation type for a model."""

    # Load samples to get transformation info
    sample_loader = SampleLoader('samples')
    samples = sample_loader.load_samples(load_code=False, load_ground_truth=True)

    # Create mapping of sample_id -> transformation
    sample_transformations = {s.id: s.transformation for s in samples}

    # Load sample metrics
    metrics_dir = Path('judge_output') / model_name / 'sample_metrics'
    if not metrics_dir.exists():
        print(f"No sample metrics for {model_name}")
        return None

    # Group by transformation
    by_transformation = defaultdict(lambda: {
        'total': 0,
        'vulnerable': 0,
        'correct_detection': 0,
        'target_found': 0,
        'lucky_guess': 0,
        'total_findings': 0,
        'valid_findings': 0,
        'reasoning_samples': 0,
        'rcir_sum': 0,
        'ava_sum': 0,
        'fsv_sum': 0,
    })

    for metrics_file in metrics_dir.glob('m_*.json'):
        with open(metrics_file) as f:
            result = json.load(f)

        sample_id = result['sample_id']
        transformation = sample_transformations.get(sample_id, 'unknown')

        stats = by_transformation[transformation]
        stats['total'] += 1

        # Detection metrics
        if result.get('ground_truth_vulnerable'):
            stats['vulnerable'] += 1

        if result.get('detection_correct'):
            stats['correct_detection'] += 1

        # Target finding
        if result.get('target_found'):
            stats['target_found'] += 1

        if result.get('lucky_guess'):
            stats['lucky_guess'] += 1

        # Finding quality
        stats['total_findings'] += result.get('total_findings', 0)
        stats['valid_findings'] += result.get('valid_findings', 0)

        # Reasoning quality
        if result.get('target_found') and result.get('rcir_score') is not None:
            stats['reasoning_samples'] += 1
            stats['rcir_sum'] += result.get('rcir_score', 0)
            stats['ava_sum'] += result.get('ava_score', 0)
            stats['fsv_sum'] += result.get('fsv_score', 0)

    # Calculate metrics
    results = {}
    for transformation, stats in by_transformation.items():
        if stats['total'] == 0:
            continue

        accuracy = stats['correct_detection'] / stats['total'] if stats['total'] > 0 else 0
        tdr = stats['target_found'] / stats['vulnerable'] if stats['vulnerable'] > 0 else 0
        lucky_rate = stats['lucky_guess'] / (stats['target_found'] + stats['lucky_guess']) if (stats['target_found'] + stats['lucky_guess']) > 0 else 0
        finding_prec = stats['valid_findings'] / stats['total_findings'] if stats['total_findings'] > 0 else 0

        results[transformation] = {
            'n': stats['total'],
            'accuracy': accuracy,
            'tdr': tdr,
            'lucky_rate': lucky_rate,
            'finding_precision': finding_prec,
            'avg_findings': stats['total_findings'] / stats['total'] if stats['total'] > 0 else 0,
            'rcir': stats['rcir_sum'] / stats['reasoning_samples'] if stats['reasoning_samples'] > 0 else None,
            'ava': stats['ava_sum'] / stats['reasoning_samples'] if stats['reasoning_samples'] > 0 else None,
            'fsv': stats['fsv_sum'] / stats['reasoning_samples'] if stats['reasoning_samples'] > 0 else None,
        }

    return results

def main():
    models = [
        'claude_opus_4.5',
        'deepseek_v3.2',
        'gemini_3_pro_preview',
        'gpt-5.2',
        'llama_3.1_405b',
        'grok_4_fast'
    ]

    all_results = {}
    for model in models:
        print(f"\n{'='*60}")
        print(f"Analyzing {model}")
        print(f"{'='*60}\n")

        results = analyze_transformation_performance(model)
        if results:
            all_results[model] = results

            for transformation in sorted(results.keys()):
                stats = results[transformation]
                print(f"\n{transformation}:")
                print(f"  N: {stats['n']}")
                print(f"  Accuracy: {stats['accuracy']:.1%}")
                print(f"  TDR: {stats['tdr']:.1%}")
                print(f"  Lucky Guess Rate: {stats['lucky_rate']:.1%}")
                print(f"  Finding Precision: {stats['finding_precision']:.1%}")
                print(f"  Avg Findings: {stats['avg_findings']:.1f}")
                if stats['rcir'] is not None:
                    print(f"  RCIR: {stats['rcir']:.2f}")
                    print(f"  AVA: {stats['ava']:.2f}")
                    print(f"  FSV: {stats['fsv']:.2f}")

    # Save results
    output_file = Path('TRANSFORMATION_ANALYSIS.json')
    with open(output_file, 'w') as f:
        json.dump(all_results, f, indent=2)

    print(f"\n\nResults saved to {output_file}")

if __name__ == '__main__':
    main()
