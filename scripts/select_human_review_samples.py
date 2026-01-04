#!/usr/bin/env python3
"""
Select samples for human review using hybrid sampling strategy.

Strategy:
- Disagreement samples: Top N highest disagreement scores within each tier
- Agreement samples: Random sample from cases where judges fully agree (score=0)

This ensures reproducibility by using a fixed random seed.
"""
import argparse
import csv
import random
from pathlib import Path

# Fixed seed for reproducibility
RANDOM_SEED = 42

# Tier allocation based on proportional sampling (25 total from 100 samples)
TIER_ALLOCATION = {
    "tier1": {"total": 5, "disagreement": 2, "agreement": 3},
    "tier2": {"total": 9, "disagreement": 5, "agreement": 4},
    "tier3": {"total": 8, "disagreement": 4, "agreement": 4},
    "tier4": {"total": 3, "disagreement": 1, "agreement": 2},
}


def load_aggregated_csv(csv_path: Path) -> list[dict]:
    """Load aggregated disagreement CSV."""
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        return list(reader)


def select_samples_for_tier(tier: str, data: list[dict], allocation: dict) -> dict:
    """
    Select samples for a tier based on allocation.

    Returns dict with 'disagreement' and 'agreement' sample lists.
    """
    # Sort by disagree_score descending
    sorted_data = sorted(data, key=lambda x: int(x['disagree_score']), reverse=True)

    # Select top N disagreement samples
    n_disagree = allocation['disagreement']
    disagreement_samples = []
    for row in sorted_data[:n_disagree]:
        disagreement_samples.append({
            'sample_id': row['sample_id'],
            'disagree_score': int(row['disagree_score']),
            'selection_type': 'disagreement'
        })

    # Get agreement pool (score = 0)
    agreement_pool = [row for row in data if int(row['disagree_score']) == 0]

    # Random sample from agreement pool
    random.seed(RANDOM_SEED)
    n_agree = allocation['agreement']

    if len(agreement_pool) >= n_agree:
        selected_agree = random.sample(agreement_pool, n_agree)
    else:
        # If not enough agreement samples, take all and fill from low disagreement
        selected_agree = agreement_pool
        remaining = n_agree - len(selected_agree)
        # Get low disagreement samples not already selected
        low_disagree = [r for r in sorted_data if int(r['disagree_score']) > 0
                        and r['sample_id'] not in [s['sample_id'] for s in disagreement_samples]]
        low_disagree = sorted(low_disagree, key=lambda x: int(x['disagree_score']))
        selected_agree.extend(low_disagree[:remaining])

    agreement_samples = []
    for row in selected_agree:
        agreement_samples.append({
            'sample_id': row['sample_id'],
            'disagree_score': int(row['disagree_score']),
            'selection_type': 'agreement'
        })

    return {
        'disagreement': disagreement_samples,
        'agreement': agreement_samples,
        'total': disagreement_samples + agreement_samples
    }


def main():
    parser = argparse.ArgumentParser(description='Select samples for human review')
    parser.add_argument('--tier', '-t', required=True, help='Tier (tier1, tier2, tier3, tier4)')
    parser.add_argument('--input', '-i', help='Input aggregated CSV path')
    parser.add_argument('--output', '-o', help='Output directory for selection')
    args = parser.parse_args()

    tier = args.tier
    if tier not in TIER_ALLOCATION:
        print(f"Error: Invalid tier '{tier}'. Must be one of: {list(TIER_ALLOCATION.keys())}")
        return

    # Default paths
    base_dir = Path(__file__).parent.parent
    input_path = args.input or base_dir / f'interannotation_analysis/ds/disagreement/llms/{tier}/_{tier}_aggregated.csv'
    output_dir = args.output or base_dir / f'interannotation_analysis/ds/human_review/{tier}'

    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}")
        return

    # Load data
    data = load_aggregated_csv(input_path)
    print(f"Loaded {len(data)} samples from {tier}")

    # Select samples
    allocation = TIER_ALLOCATION[tier]
    selection = select_samples_for_tier(tier, data, allocation)

    # Create output directory
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write selection CSV
    output_csv = output_dir / f'{tier}_human_review_samples.csv'
    with open(output_csv, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['sample_id', 'disagree_score', 'selection_type'])
        writer.writeheader()
        writer.writerows(selection['total'])

    # Print summary
    print(f"\n=== {tier.upper()} Selection Summary ===")
    print(f"Total samples in tier: {len(data)}")
    print(f"Samples selected: {len(selection['total'])}")
    print(f"\nDisagreement samples ({len(selection['disagreement'])}):")
    for s in selection['disagreement']:
        print(f"  - {s['sample_id']} (score: {s['disagree_score']})")
    print(f"\nAgreement samples ({len(selection['agreement'])}):")
    for s in selection['agreement']:
        print(f"  - {s['sample_id']} (score: {s['disagree_score']})")
    print(f"\nOutput saved to: {output_csv}")


if __name__ == '__main__':
    main()
