#!/usr/bin/env python3
"""
Recalculate Cohen's Kappa with Binary Agreement

Treats any type detection (exact, semantic, partial) as "FOUND"
and only "none" as "NOT_FOUND"

This measures: "Do expert and judge agree on whether a vulnerability exists?"
rather than mixing detection and classification.
"""

import json
from pathlib import Path
from sklearn.metrics import cohen_kappa_score, confusion_matrix
import numpy as np

BASE_DIR = Path(__file__).parent.parent
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'human_validation'


def load_comparisons():
    """Load detailed comparison data."""
    comp_file = OUTPUT_DIR / 'expert_judge_comparisons_detailed.json'
    with open(comp_file) as f:
        return json.load(f)


def main():
    print("=" * 80)
    print("RECALCULATING KAPPA - BINARY AGREEMENT")
    print("=" * 80)

    comparisons = load_comparisons()
    print(f"\nTotal samples: {len(comparisons)}")

    # Extract type matches and convert to binary: FOUND vs NOT_FOUND
    expert_found_list = []
    judge_found_list = []

    for comp in comparisons:
        expert_type = comp['expert']['type_match']
        judge_type = comp['judge']['type_match']

        # Convert to binary: any detection (exact/semantic/partial/wrong) = FOUND
        # "none" and "not_mentioned" = NOT FOUND
        expert_found = expert_type not in ['none', 'not_mentioned']
        judge_found = judge_type not in ['none', 'not_mentioned']

        expert_found_list.append(expert_found)
        judge_found_list.append(judge_found)

    # Calculate agreement metrics
    agreements = sum(1 for e, j in zip(expert_found_list, judge_found_list) if e == j)
    agreement_pct = (agreements / len(comparisons)) * 100

    print(f"\nDirect Agreement: {agreements}/{len(comparisons)} = {agreement_pct:.1f}%")

    # Cohen's Kappa
    kappa = cohen_kappa_score(expert_found_list, judge_found_list)
    print(f"Cohen's κ: {kappa:.3f}")

    # Confusion matrix
    cm = confusion_matrix(expert_found_list, judge_found_list, labels=[False, True])

    print("\n" + "=" * 80)
    print("CONFUSION MATRIX")
    print("=" * 80)
    print("\n                    Judge: NOT FOUND  |  Judge: FOUND")
    print(f"Expert: NOT FOUND      {cm[0,0]:>8}            {cm[0,1]:>8}")
    print(f"Expert: FOUND          {cm[1,0]:>8}            {cm[1,1]:>8}")

    tn, fp, fn, tp = cm.ravel()

    # Calculate performance metrics
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

    print(f"\nJudge Performance:")
    print(f"  Precision: {precision:.3f}")
    print(f"  Recall: {recall:.3f}")
    print(f"  F1 Score: {f1:.3f}")

    # Now separately analyze type classification among cases where BOTH found it
    print("\n" + "=" * 80)
    print("TYPE CLASSIFICATION (when both found vulnerability)")
    print("=" * 80)

    both_found_cases = []
    for comp in comparisons:
        expert_type = comp['expert']['type_match']
        judge_type = comp['judge']['type_match']

        if expert_type != 'none' and judge_type != 'none':
            both_found_cases.append({
                'sample_id': comp['sample_id'],
                'expert_type': expert_type,
                'judge_type': judge_type
            })

    print(f"\nCases where both found vulnerability: {len(both_found_cases)}")

    if both_found_cases:
        # Type agreement among these cases
        type_agreements = sum(1 for case in both_found_cases
                             if case['expert_type'] == case['judge_type'])
        type_agreement_pct = (type_agreements / len(both_found_cases)) * 100

        print(f"Exact type match: {type_agreements}/{len(both_found_cases)} = {type_agreement_pct:.1f}%")

        # Show disagreements
        disagreements = [case for case in both_found_cases
                        if case['expert_type'] != case['judge_type']]

        if disagreements:
            print(f"\nType disagreements ({len(disagreements)} cases):")
            for d in disagreements[:10]:
                print(f"  {d['sample_id']}: Expert={d['expert_type']}, Judge={d['judge_type']}")

        # Calculate κ for type classification (among cases where both found it)
        expert_types = [case['expert_type'] for case in both_found_cases]
        judge_types = [case['judge_type'] for case in both_found_cases]

        if len(set(expert_types)) > 1 and len(set(judge_types)) > 1:
            type_kappa = cohen_kappa_score(expert_types, judge_types)
            print(f"\nType Classification κ (among both-found cases): {type_kappa:.3f}")
        else:
            print(f"\nType Classification κ: Cannot compute (insufficient variance)")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY FOR PAPER")
    print("=" * 80)

    summary = f"""
DETECTION AGREEMENT:
  Overall agreement: {agreement_pct:.1f}% ({agreements}/{len(comparisons)} samples)
  Cohen's κ: {kappa:.2f}
  Judge precision: {precision:.2f}, recall: {recall:.2f}, F1: {f1:.2f}

TYPE CLASSIFICATION (when both detected):
  Agreement: {type_agreement_pct:.1f}% ({type_agreements}/{len(both_found_cases)} samples)
  Disagreements: {len(disagreements)} cases (mostly exact vs. semantic)

INTERPRETATION:
  κ={kappa:.2f} indicates {'substantial' if kappa > 0.60 else 'moderate' if kappa > 0.40 else 'fair'} agreement on vulnerability detection.
  When both detect a vulnerability, they agree on classification {type_agreement_pct:.0f}% of the time.
"""

    print(summary)

    # Save results
    results = {
        'n_samples': len(comparisons),
        'detection_agreement': {
            'agreement_pct': agreement_pct,
            'cohen_kappa': kappa,
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'confusion_matrix': {
                'true_negatives': int(tn),
                'false_positives': int(fp),
                'false_negatives': int(fn),
                'true_positives': int(tp)
            }
        },
        'type_classification_when_both_found': {
            'n_cases': len(both_found_cases),
            'agreement_pct': type_agreement_pct,
            'disagreements': disagreements
        },
        'summary': summary
    }

    output_file = OUTPUT_DIR / 'binary_kappa_analysis.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✓ Results saved to: {output_file}")

    print("\n" + "=" * 80)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 80)


if __name__ == '__main__':
    main()
