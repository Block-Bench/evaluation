#!/usr/bin/env python3
"""
Compare expert reviews with LLM judge outputs to check agreement.
"""

import json
import os
from pathlib import Path
from collections import defaultdict

def load_json(filepath):
    """Load JSON file."""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None

def get_expert_verdict(expert_data):
    """Extract verdict from expert review."""
    if not expert_data:
        return None

    target = expert_data.get('target_assessment', {})
    classification = target.get('classification', '')
    found = target.get('found')

    # Return standardized verdict
    if classification == 'FOUND' or found is True:
        return 'FOUND'
    elif classification == 'PARTIAL':
        return 'PARTIAL'
    elif classification == 'MISSED' or found is False:
        return 'MISSED'

    return None

def get_judge_verdict(judge_data):
    """Extract verdict from LLM judge output."""
    if not judge_data:
        return None

    target = judge_data.get('target_assessment', {})
    found = target.get('found')
    type_match = target.get('type_match', '')

    # Return standardized verdict
    if found is True:
        if type_match in ['exact', 'semantic']:
            return 'FOUND'
        elif type_match == 'partial':
            return 'PARTIAL'
        else:
            return 'FOUND'  # Default to FOUND if found=true
    elif found is False:
        return 'MISSED'

    return None

def extract_sample_id(filename):
    """Extract sample ID from filename (e.g., r_sn_gs_001.json -> sn_gs_001)."""
    # Remove prefix (r_ or j_) and suffix (.json)
    name = filename.replace('r_', '').replace('j_', '').replace('.json', '')
    # Remove _direct, _adversarial, _naturalistic if present
    for suffix in ['_direct', '_adversarial', '_naturalistic']:
        name = name.replace(suffix, '')
    return name

def compare_reviews():
    """Compare expert reviews with LLM judge outputs."""
    base_dir = Path('/Users/poamen/projects/grace/blockbench/evaluation')
    expert_dir = base_dir / 'Expert-Reviews'
    judge_dir = base_dir / 'judge_output'

    results = {
        'total_comparisons': 0,
        'agreements': 0,
        'disagreements': 0,
        'expert_only': 0,
        'judge_only': 0,
        'details': []
    }

    # Collect all expert reviews
    expert_reviews = {}
    for model_dir in expert_dir.iterdir():
        if not model_dir.is_dir():
            continue
        for review_file in model_dir.glob('r_*.json'):
            sample_id = extract_sample_id(review_file.name)
            expert_reviews[sample_id] = {
                'path': review_file,
                'model': model_dir.name
            }

    # Collect all judge outputs
    judge_outputs = {}
    for judge_model_dir in judge_dir.iterdir():
        if not judge_model_dir.is_dir():
            continue
        judge_output_dir = judge_model_dir / 'judge_outputs'
        if not judge_output_dir.exists():
            continue
        for judge_file in judge_output_dir.glob('j_*.json'):
            sample_id = extract_sample_id(judge_file.name)
            if sample_id not in judge_outputs:
                judge_outputs[sample_id] = []
            judge_outputs[sample_id].append({
                'path': judge_file,
                'judge_model': judge_model_dir.name
            })

    print(f"\nFound {len(expert_reviews)} expert reviews")
    print(f"Found judge outputs for {len(judge_outputs)} samples\n")

    # Compare
    comparison_details = []

    for sample_id in sorted(expert_reviews.keys()):
        expert_info = expert_reviews[sample_id]
        expert_data = load_json(expert_info['path'])
        expert_verdict = get_expert_verdict(expert_data)

        if sample_id in judge_outputs:
            for judge_info in judge_outputs[sample_id]:
                judge_data = load_json(judge_info['path'])
                judge_verdict = get_judge_verdict(judge_data)

                if expert_verdict and judge_verdict:
                    results['total_comparisons'] += 1

                    # Check agreement
                    agree = (expert_verdict == judge_verdict) or \
                            (expert_verdict == 'FOUND' and judge_verdict == 'PARTIAL') or \
                            (expert_verdict == 'PARTIAL' and judge_verdict == 'FOUND')

                    if agree:
                        results['agreements'] += 1
                        status = 'AGREE'
                    else:
                        results['disagreements'] += 1
                        status = 'DISAGREE'

                    comparison_details.append({
                        'sample_id': sample_id,
                        'expert_model': expert_info['model'],
                        'judge_model': judge_info['judge_model'],
                        'expert_verdict': expert_verdict,
                        'judge_verdict': judge_verdict,
                        'status': status
                    })

    # Print results
    print("="*80)
    print("COMPARISON SUMMARY")
    print("="*80)
    print(f"Total Comparisons: {results['total_comparisons']}")
    print(f"Agreements: {results['agreements']} ({results['agreements']/max(results['total_comparisons'],1)*100:.1f}%)")
    print(f"Disagreements: {results['disagreements']} ({results['disagreements']/max(results['total_comparisons'],1)*100:.1f}%)")
    print("="*80)

    # Show disagreements
    if results['disagreements'] > 0:
        print("\nDISAGREEMENTS:")
        print("-"*80)
        disagreements = [d for d in comparison_details if d['status'] == 'DISAGREE']
        for detail in disagreements[:20]:  # Show first 20
            print(f"Sample: {detail['sample_id']}")
            print(f"  Expert ({detail['expert_model']}): {detail['expert_verdict']}")
            print(f"  Judge ({detail['judge_model']}): {detail['judge_verdict']}")
            print()

        if len(disagreements) > 20:
            print(f"... and {len(disagreements) - 20} more disagreements")

    # Group by agreement status
    print("\n" + "="*80)
    print("BREAKDOWN BY JUDGE MODEL:")
    print("="*80)

    by_judge = defaultdict(lambda: {'total': 0, 'agree': 0, 'disagree': 0})
    for detail in comparison_details:
        judge = detail['judge_model']
        by_judge[judge]['total'] += 1
        if detail['status'] == 'AGREE':
            by_judge[judge]['agree'] += 1
        else:
            by_judge[judge]['disagree'] += 1

    for judge, stats in sorted(by_judge.items()):
        agree_pct = stats['agree']/max(stats['total'],1)*100
        print(f"{judge}:")
        print(f"  Total: {stats['total']}, Agree: {stats['agree']} ({agree_pct:.1f}%), Disagree: {stats['disagree']}")

    # Save detailed results
    output_file = base_dir / 'expert_judge_comparison.json'
    with open(output_file, 'w') as f:
        json.dump({
            'summary': results,
            'comparisons': comparison_details
        }, f, indent=2)

    print(f"\nDetailed results saved to: {output_file}")

if __name__ == '__main__':
    compare_reviews()
