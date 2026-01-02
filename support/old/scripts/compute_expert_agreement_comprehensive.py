#!/usr/bin/env python3
"""
Comprehensive Expert-Judge Agreement Analysis

Loads the detailed comparison data and computes:
1. Agreement metrics for target detection and type match
2. Disagreement analysis
3. Reasoning quality comparison (where available)
4. Per-model breakdown
"""

import json
from pathlib import Path
from typing import Dict, List
import numpy as np
from scipy import stats
from sklearn.metrics import cohen_kappa_score, confusion_matrix

BASE_DIR = Path(__file__).parent.parent
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'human_validation'


def load_comparisons() -> List[Dict]:
    """Load detailed comparison data."""
    comp_file = OUTPUT_DIR / 'expert_judge_comparisons_detailed.json'
    with open(comp_file) as f:
        return json.load(f)


def compute_confusion_matrix_metrics(expert_vals: List, judge_vals: List, labels=None) -> Dict:
    """Compute precision, recall, F1 from confusion matrix."""
    if labels is None:
        labels = sorted(list(set(expert_vals + judge_vals)))

    # Compute confusion matrix
    cm = confusion_matrix(expert_vals, judge_vals, labels=labels)

    # For binary classification
    if len(labels) == 2:
        tn, fp, fn, tp = cm.ravel()

        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

        return {
            'confusion_matrix': cm.tolist(),
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'true_positives': int(tp),
            'true_negatives': int(tn),
            'false_positives': int(fp),
            'false_negatives': int(fn)
        }

    return {
        'confusion_matrix': cm.tolist(),
        'labels': labels
    }


def analyze_disagreements(comparisons: List[Dict]) -> Dict:
    """Analyze cases where expert and judge disagree."""
    target_disagreements = []
    type_disagreements = []

    for comp in comparisons:
        expert = comp['expert']
        judge = comp['judge']

        # Target found disagreements
        if expert['target_found'] != judge['target_found']:
            target_disagreements.append({
                'sample_id': comp['sample_id'],
                'expert_found': expert['target_found'],
                'judge_found': judge['target_found'],
                'expert_name': comp['expert_name']
            })

        # Type match disagreements (only if both found target)
        if expert['target_found'] and judge['target_found']:
            if expert['type_match'] != judge['type_match']:
                type_disagreements.append({
                    'sample_id': comp['sample_id'],
                    'expert_type': expert['type_match'],
                    'judge_type': judge['type_match'],
                    'expert_name': comp['expert_name']
                })

    return {
        'target_disagreements': target_disagreements,
        'type_disagreements': type_disagreements,
        'n_target_disagreements': len(target_disagreements),
        'n_type_disagreements': len(type_disagreements)
    }


def analyze_by_model(comparisons: List[Dict]) -> Dict:
    """Break down agreement by expert."""
    expert1_comps = [c for c in comparisons if c['expert_name'] == 'D4n13l']
    expert2_comps = [c for c in comparisons if c['expert_name'] == 'FrontRunner']

    results = {}

    for expert_name, comps in [('D4n13l', expert1_comps), ('FrontRunner', expert2_comps)]:
        if not comps:
            continue

        expert_target = [c['expert']['target_found'] for c in comps]
        judge_target = [c['judge']['target_found'] for c in comps]

        target_agreement = sum(1 for e, j in zip(expert_target, judge_target) if e == j)
        target_agreement_pct = (target_agreement / len(comps)) * 100

        # Count cases
        both_found = sum(1 for e, j in zip(expert_target, judge_target) if e and j)
        expert_only = sum(1 for e, j in zip(expert_target, judge_target) if e and not j)
        judge_only = sum(1 for e, j in zip(expert_target, judge_target) if j and not e)
        neither = sum(1 for e, j in zip(expert_target, judge_target) if not e and not j)

        results[expert_name] = {
            'n_samples': len(comps),
            'target_agreement_pct': target_agreement_pct,
            'both_found': both_found,
            'expert_only_found': expert_only,
            'judge_only_found': judge_only,
            'neither_found': neither
        }

    return results


def main():
    print("=" * 80)
    print("COMPREHENSIVE EXPERT-JUDGE AGREEMENT ANALYSIS")
    print("=" * 80)

    # Load comparisons
    comparisons = load_comparisons()
    print(f"\nTotal samples: {len(comparisons)}")

    # Extract parallel lists
    expert_target = [c['expert']['target_found'] for c in comparisons]
    judge_target = [c['judge']['target_found'] for c in comparisons]

    expert_type = [c['expert']['type_match'] for c in comparisons]
    judge_type = [c['judge']['type_match'] for c in comparisons]

    # Basic agreement
    target_agreement = sum(1 for e, j in zip(expert_target, judge_target) if e == j)
    type_agreement = sum(1 for e, j in zip(expert_type, judge_type) if e == j)

    print(f"\nTarget Detection Agreement: {target_agreement}/{len(comparisons)} ({target_agreement/len(comparisons)*100:.1f}%)")
    print(f"Type Match Agreement: {type_agreement}/{len(comparisons)} ({type_agreement/len(comparisons)*100:.1f}%)")

    # Confusion matrix for target detection
    print("\n" + "=" * 80)
    print("TARGET DETECTION CONFUSION MATRIX")
    print("=" * 80)

    cm_metrics = compute_confusion_matrix_metrics(expert_target, judge_target, labels=[False, True])

    print("\nConfusion Matrix (Expert=rows, Judge=columns):")
    print("                Judge: Not Found  |  Judge: Found")
    print(f"Expert: Not Found  {cm_metrics['true_negatives']:>8}      {cm_metrics['false_positives']:>8}")
    print(f"Expert: Found      {cm_metrics['false_negatives']:>8}      {cm_metrics['true_positives']:>8}")

    print(f"\nJudge Precision (when judge says 'found', how often is expert correct?): {cm_metrics['precision']:.3f}")
    print(f"Judge Recall (when expert says 'found', how often does judge agree?): {cm_metrics['recall']:.3f}")
    print(f"F1 Score: {cm_metrics['f1_score']:.3f}")

    # Cohen's Kappa
    try:
        kappa = cohen_kappa_score(expert_target, judge_target)
        print(f"\nCohen's κ: {kappa:.3f}")
    except Exception as e:
        print(f"\nCohen's κ: Could not compute ({e})")

    # Type match analysis
    print("\n" + "=" * 80)
    print("TYPE MATCH ANALYSIS")
    print("=" * 80)

    # Get unique type values
    all_types = sorted(list(set(expert_type + judge_type)))
    print(f"\nType match categories: {all_types}")

    # Type confusion matrix
    type_cm = confusion_matrix(expert_type, judge_type, labels=all_types)
    print("\nType Match Confusion Matrix:")
    print(f"{'':>12} | " + " | ".join(f"{t:>10}" for t in all_types))
    print("-" * (15 + len(all_types) * 14))
    for i, expert_type_label in enumerate(all_types):
        row_str = f"{expert_type_label:>12} | " + " | ".join(f"{type_cm[i, j]:>10}" for j in range(len(all_types)))
        print(row_str)

    try:
        type_kappa = cohen_kappa_score(expert_type, judge_type)
        print(f"\nType Match κ: {type_kappa:.3f}")
    except Exception as e:
        print(f"\nType Match κ: Could not compute ({e})")

    # Disagreement analysis
    print("\n" + "=" * 80)
    print("DISAGREEMENT ANALYSIS")
    print("=" * 80)

    disagreements = analyze_disagreements(comparisons)

    print(f"\nTarget Detection Disagreements: {disagreements['n_target_disagreements']}")
    if disagreements['target_disagreements']:
        print("\nSamples where expert and judge disagree on target detection:")
        for d in disagreements['target_disagreements'][:10]:
            print(f"  {d['sample_id']}: Expert={d['expert_found']}, Judge={d['judge_found']} ({d['expert_name']})")

    print(f"\nType Match Disagreements: {disagreements['n_type_disagreements']}")
    if disagreements['type_disagreements']:
        print("\nSamples where expert and judge disagree on type (when both found target):")
        for d in disagreements['type_disagreements'][:10]:
            print(f"  {d['sample_id']}: Expert={d['expert_type']}, Judge={d['judge_type']} ({d['expert_name']})")

    # By-expert analysis
    print("\n" + "=" * 80)
    print("BY-EXPERT BREAKDOWN")
    print("=" * 80)

    by_expert = analyze_by_model(comparisons)

    for expert_name, metrics in by_expert.items():
        print(f"\n{expert_name}:")
        print(f"  Samples: {metrics['n_samples']}")
        print(f"  Agreement: {metrics['target_agreement_pct']:.1f}%")
        print(f"  Both found: {metrics['both_found']}")
        print(f"  Expert only: {metrics['expert_only_found']}")
        print(f"  Judge only: {metrics['judge_only_found']}")
        print(f"  Neither found: {metrics['neither_found']}")

    # Summary for paper
    print("\n" + "=" * 80)
    print("SUMMARY FOR PAPER")
    print("=" * 80)

    summary = f"""
Expert-Judge Agreement on Target Detection (n={len(comparisons)}):
  Agreement: {target_agreement/len(comparisons)*100:.1f}%
  Cohen's κ: {kappa:.2f}
  Judge Precision: {cm_metrics['precision']:.2f}
  Judge Recall: {cm_metrics['recall']:.2f}

Type Match Agreement (when both found target):
  Cohen's κ: {type_kappa:.2f}

Disagreements:
  Target detection: {disagreements['n_target_disagreements']} samples
  Type classification: {disagreements['n_type_disagreements']} samples

Experts:
  D4n13l: {by_expert['D4n13l']['n_samples']} samples, {by_expert['D4n13l']['target_agreement_pct']:.1f}% agreement
  FrontRunner: {by_expert['FrontRunner']['n_samples']} samples, {by_expert['FrontRunner']['target_agreement_pct']:.1f}% agreement
"""

    print(summary)

    # Save detailed results
    results = {
        'n_samples': len(comparisons),
        'target_detection': {
            'agreement_pct': target_agreement / len(comparisons) * 100,
            'cohen_kappa': kappa,
            'confusion_matrix': cm_metrics,
        },
        'type_match': {
            'agreement_pct': type_agreement / len(comparisons) * 100,
            'cohen_kappa': type_kappa,
        },
        'disagreements': disagreements,
        'by_expert': by_expert,
        'summary': summary
    }

    output_file = OUTPUT_DIR / 'comprehensive_agreement_analysis.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✓ Results saved to: {output_file}")

    # Save summary
    summary_file = OUTPUT_DIR / 'comprehensive_agreement_summary.txt'
    with open(summary_file, 'w') as f:
        f.write(summary)

    print(f"✓ Summary saved to: {summary_file}")

    print("\n" + "=" * 80)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 80)


if __name__ == '__main__':
    main()
