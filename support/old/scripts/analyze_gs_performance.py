#!/usr/bin/env python3
"""
Analyze model performance specifically on GPTShield samples.
"""

import json
from pathlib import Path
from collections import defaultdict
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

def analyze_gs_performance(model_name: str):
    """Analyze performance on GS samples for a model."""

    metrics_dir = Path('judge_output') / model_name / 'sample_metrics'
    if not metrics_dir.exists():
        print(f"No sample metrics for {model_name}")
        return None

    # Collect GS sample metrics
    gs_samples = defaultdict(lambda: {
        'total': 0,
        'correct_detection': 0,
        'target_found': 0,
        'lucky_guess': 0,
        'total_findings': 0,
        'valid_findings': 0,
        'rcir_scores': [],
        'ava_scores': [],
        'fsv_scores': [],
    })

    all_gs_stats = {
        'total': 0,
        'correct_detection': 0,
        'target_found': 0,
        'lucky_guess': 0,
        'total_findings': 0,
        'valid_findings': 0,
        'rcir_scores': [],
        'ava_scores': [],
        'fsv_scores': [],
        'samples': []
    }

    for metrics_file in metrics_dir.glob('m_*_gs_*.json'):
        with open(metrics_file) as f:
            result = json.load(f)

        sample_id = result['sample_id']

        # Extract base GS ID (e.g., "sn_gs_002" -> "gs_002")
        if '_gs_' in sample_id:
            base_id = 'gs_' + sample_id.split('_gs_')[1].split('_')[0]
        else:
            continue

        stats = gs_samples[base_id]
        stats['total'] += 1
        all_gs_stats['total'] += 1
        all_gs_stats['samples'].append(sample_id)

        if result.get('detection_correct'):
            stats['correct_detection'] += 1
            all_gs_stats['correct_detection'] += 1

        if result.get('target_found'):
            stats['target_found'] += 1
            all_gs_stats['target_found'] += 1

        if result.get('lucky_guess'):
            stats['lucky_guess'] += 1
            all_gs_stats['lucky_guess'] += 1

        stats['total_findings'] += result.get('total_findings', 0)
        stats['valid_findings'] += result.get('valid_findings', 0)
        all_gs_stats['total_findings'] += result.get('total_findings', 0)
        all_gs_stats['valid_findings'] += result.get('valid_findings', 0)

        if result.get('target_found') and result.get('rcir_score') is not None:
            stats['rcir_scores'].append(result.get('rcir_score', 0))
            stats['ava_scores'].append(result.get('ava_score', 0))
            stats['fsv_scores'].append(result.get('fsv_score', 0))
            all_gs_stats['rcir_scores'].append(result.get('rcir_score', 0))
            all_gs_stats['ava_scores'].append(result.get('ava_score', 0))
            all_gs_stats['fsv_scores'].append(result.get('fsv_score', 0))

    # Calculate overall metrics
    if all_gs_stats['total'] == 0:
        return None

    total = all_gs_stats['total']
    accuracy = all_gs_stats['correct_detection'] / total if total > 0 else 0
    tdr = all_gs_stats['target_found'] / total if total > 0 else 0
    lucky_rate = all_gs_stats['lucky_guess'] / (all_gs_stats['target_found'] + all_gs_stats['lucky_guess']) if (all_gs_stats['target_found'] + all_gs_stats['lucky_guess']) > 0 else 0
    finding_prec = all_gs_stats['valid_findings'] / all_gs_stats['total_findings'] if all_gs_stats['total_findings'] > 0 else 0
    avg_findings = all_gs_stats['total_findings'] / total if total > 0 else 0

    rcir = sum(all_gs_stats['rcir_scores']) / len(all_gs_stats['rcir_scores']) if all_gs_stats['rcir_scores'] else None
    ava = sum(all_gs_stats['ava_scores']) / len(all_gs_stats['ava_scores']) if all_gs_stats['ava_scores'] else None
    fsv = sum(all_gs_stats['fsv_scores']) / len(all_gs_stats['fsv_scores']) if all_gs_stats['fsv_scores'] else None

    return {
        'total_evaluations': total,
        'unique_samples': len(gs_samples),
        'accuracy': accuracy,
        'tdr': tdr,
        'lucky_rate': lucky_rate,
        'finding_precision': finding_prec,
        'avg_findings': avg_findings,
        'rcir': rcir,
        'ava': ava,
        'fsv': fsv,
        'per_sample': gs_samples,
        'sample_list': sorted(set([s.split('_')[1] + '_' + s.split('_')[2].split('_')[0] for s in all_gs_stats['samples']]))
    }

def main():
    models = [
        'claude_opus_4.5',
        'deepseek_v3.2',
        'gemini_3_pro_preview',
        'gpt-5.2',
        'llama_3.1_405b',
        'grok_4_fast'
    ]

    print("="*70)
    print("GPTSHIELD (GS) DATASET PERFORMANCE ANALYSIS")
    print("="*70)
    print("\nGPTShield samples are professionally identified vulnerabilities")
    print("from real smart contract security audits.\n")

    all_results = {}
    for model in models:
        results = analyze_gs_performance(model)
        if results:
            all_results[model] = results

            print(f"\n{model}:")
            print(f"  Evaluations: {results['total_evaluations']} (across {results['unique_samples']} unique GS samples)")
            print(f"  Samples: {', '.join(results['sample_list'])}")
            print(f"  Accuracy: {results['accuracy']:.1%}")
            print(f"  TDR: {results['tdr']:.1%}")
            print(f"  Lucky Guess Rate: {results['lucky_rate']:.1%}")
            print(f"  Finding Precision: {results['finding_precision']:.1%}")
            print(f"  Avg Findings: {results['avg_findings']:.1f}")
            if results['rcir'] is not None:
                print(f"  RCIR: {results['rcir']:.2f}")
                print(f"  AVA: {results['ava']:.2f}")
                print(f"  FSV: {results['fsv']:.2f}")

    # Create comparison table
    print("\n\n" + "="*70)
    print("COMPARISON TABLE - GS DATASET ONLY")
    print("="*70)
    print(f"\n{'Model':<25} {'N':>4} {'Acc':>6} {'TDR':>6} {'Lucky%':>7} {'FindPr':>7} {'AvgF':>5} {'RCIR':>5} {'AVA':>5} {'FSV':>5}")
    print("-" * 90)

    # Sort by TDR
    sorted_models = sorted(all_results.items(), key=lambda x: x[1]['tdr'], reverse=True)

    for model, results in sorted_models:
        rcir_str = f"{results['rcir']:.2f}" if results['rcir'] is not None else "-"
        ava_str = f"{results['ava']:.2f}" if results['ava'] is not None else "-"
        fsv_str = f"{results['fsv']:.2f}" if results['fsv'] is not None else "-"

        print(f"{model:<25} {results['total_evaluations']:>4} {results['accuracy']:>5.1%} {results['tdr']:>5.1%} {results['lucky_rate']:>6.1%} {results['finding_precision']:>6.1%} {results['avg_findings']:>5.1f} {rcir_str:>5} {ava_str:>5} {fsv_str:>5}")

    # Save results
    output_file = Path('GS_PERFORMANCE_ANALYSIS.json')
    with open(output_file, 'w') as f:
        json.dump(all_results, f, indent=2)

    print(f"\n\nDetailed results saved to {output_file}")

if __name__ == '__main__':
    main()
