#!/usr/bin/env python3
"""
Stratified Sampling Script for DS (Difficulty Stratified) Dataset

This script implements reproducible stratified sampling for the BlockBench
DS dataset, ensuring representation across difficulty tiers and vulnerability types.

Dataset Structure:
    dataset/difficulty_stratified/cleaned/
    ├── tier1/  (contracts: ds_t1_001.sol, ds_t1_002.sol, ...)
    ├── tier2/  (contracts: ds_t2_001.sol, ds_t2_002.sol, ...)
    ├── tier3/  (contracts: ds_t3_001.sol, ds_t3_002.sol, ...)
    └── tier4/  (contracts: ds_t4_001.sol, ds_t4_002.sol, ...)

Sampling Strategy:
- Tier 1 (Textbook): 20 samples - LLMs perform well, light sampling
- Tier 2 (Clear Audit): 30 samples - Moderate difficulty
- Tier 3 (Subtle Audit): 30 samples - Heavy sampling, harder cases
- Tier 4 (Multi-Contract): 14 samples - Take all available (hardest)

Within each tier, samples are selected to maximize vulnerability type coverage.

Usage:
    python sample_ds_dataset.py --data-dir /path/to/dataset --output sampled_ids.json
    python sample_ds_dataset.py --data-dir /path/to/dataset --seed 42 --target 100
"""

import argparse
import json
import random
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Any, Tuple


DEFAULT_CONFIG = {
    "target_total": 100,
    "tier_targets": {
        1: 20,   # Textbook - light sampling
        2: 30,   # Clear Audit - moderate
        3: 36,   # Subtle Audit - take all (max available: 36)
        4: 14,   # Multi-Contract - take all (max available: 14)
    },
    "random_seed": 42,
}


def load_tier_samples(tier_dir: Path, tier: int) -> List[Dict[str, Any]]:
    """Load all samples from a tier directory."""
    samples = []

    contracts_dir = tier_dir / "contracts"
    metadata_dir = tier_dir / "metadata"

    if not contracts_dir.exists():
        return samples

    for contract_file in sorted(contracts_dir.glob("ds_t*.sol")):
        sample_id = contract_file.stem  # e.g., ds_t1_001
        metadata_file = metadata_dir / f"{sample_id}.json"

        # Default values
        vtype = "unknown"
        severity = "unknown"

        # Try to load metadata
        if metadata_file.exists():
            try:
                with open(metadata_file) as f:
                    data = json.load(f)

                # Extract vulnerability type
                vtype = data.get('vulnerability_type')
                if vtype is None and 'ground_truth' in data:
                    vtype = data['ground_truth'].get('vulnerability_type')
                vtype = vtype or "unknown"

                # Extract severity
                severity = data.get('severity')
                if severity is None and 'ground_truth' in data:
                    severity = data['ground_truth'].get('severity')
                severity = severity or "unknown"
            except json.JSONDecodeError:
                pass

        samples.append({
            'id': sample_id,
            'tier': tier,
            'vtype': vtype,
            'severity': severity,
            'contract_file': str(contract_file),
            'metadata_file': str(metadata_file) if metadata_file.exists() else None,
        })

    return samples


def load_all_samples(data_dir: Path) -> Tuple[List[Dict[str, Any]], Dict[int, int]]:
    """Load all samples from the cleaned dataset."""
    all_samples = []
    tier_counts = {}

    cleaned_dir = data_dir / "difficulty_stratified" / "cleaned"

    for tier in [1, 2, 3, 4]:
        tier_dir = cleaned_dir / f"tier{tier}"
        tier_samples = load_tier_samples(tier_dir, tier)
        tier_counts[tier] = len(tier_samples)
        all_samples.extend(tier_samples)
        print(f"  Tier {tier}: {len(tier_samples)} samples")

    return all_samples, tier_counts


def stratified_sample(
    samples: List[Dict[str, Any]],
    tier_targets: Dict[int, int],
    tier_counts: Dict[int, int],
    seed: int
) -> List[Dict[str, Any]]:
    """
    Perform stratified sampling by tier and vulnerability type.

    Args:
        samples: List of sample metadata dicts
        tier_targets: Dict mapping tier -> target sample count
        tier_counts: Dict mapping tier -> total available
        seed: Random seed for reproducibility

    Returns:
        List of selected samples
    """
    random.seed(seed)
    selected = []

    # Group samples by tier and vulnerability type
    tier_vtype_samples = defaultdict(lambda: defaultdict(list))
    for s in samples:
        tier_vtype_samples[s['tier']][s['vtype']].append(s)

    for tier in sorted(tier_targets.keys()):
        target = min(tier_targets[tier], tier_counts.get(tier, 0))
        vtypes_in_tier = tier_vtype_samples[tier]

        if not vtypes_in_tier:
            print(f"Tier {tier}: No samples found")
            continue

        total_in_tier = sum(len(samples) for samples in vtypes_in_tier.values())

        # If we want all or more than available, take all
        if target >= total_in_tier:
            for tier_samples in vtypes_in_tier.values():
                selected.extend(tier_samples)
            print(f"Tier {tier}: Selected all {total_in_tier} samples")
            continue

        # Stratified sampling within tier by vulnerability type
        tier_selected = []

        # First pass: proportional allocation
        allocation = {}
        for vtype, vtype_samples in vtypes_in_tier.items():
            prop = len(vtype_samples) / total_in_tier
            alloc = max(1, round(target * prop))
            allocation[vtype] = min(alloc, len(vtype_samples))

        # Adjust to hit target
        current = sum(allocation.values())

        if current > target:
            for vtype in sorted(allocation.keys(), key=lambda x: -allocation[x]):
                if current <= target:
                    break
                reduce = min(allocation[vtype] - 1, current - target)
                if reduce > 0:
                    allocation[vtype] -= reduce
                    current -= reduce

        elif current < target:
            for vtype in sorted(allocation.keys(), key=lambda x: -len(vtypes_in_tier[x])):
                if current >= target:
                    break
                can_add = len(vtypes_in_tier[vtype]) - allocation[vtype]
                if can_add > 0:
                    add = min(can_add, target - current)
                    allocation[vtype] += add
                    current += add

        # Sample from each vulnerability type
        for vtype, n in allocation.items():
            vtype_samples = vtypes_in_tier[vtype]
            sampled = random.sample(vtype_samples, min(n, len(vtype_samples)))
            tier_selected.extend(sampled)

        selected.extend(tier_selected)
        print(f"Tier {tier}: Selected {len(tier_selected)} samples from {total_in_tier} available")

        # Print breakdown
        vtype_counts = defaultdict(int)
        for s in tier_selected:
            vtype_counts[s['vtype']] += 1

        for vtype, count in sorted(vtype_counts.items(), key=lambda x: -x[1])[:5]:
            print(f"    {vtype}: {count}")
        if len(vtype_counts) > 5:
            print(f"    ... and {len(vtype_counts) - 5} more types")

    return selected


def main():
    parser = argparse.ArgumentParser(
        description="Stratified sampling for BlockBench DS dataset",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        required=True,
        help="Path to dataset directory (containing difficulty_stratified/cleaned/)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("sampled_ds_ids.json"),
        help="Output file for sampled IDs (default: sampled_ds_ids.json)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_CONFIG["random_seed"],
        help=f"Random seed for reproducibility (default: {DEFAULT_CONFIG['random_seed']})"
    )
    parser.add_argument(
        "--target",
        type=int,
        default=DEFAULT_CONFIG["target_total"],
        help=f"Target total samples (default: {DEFAULT_CONFIG['target_total']})"
    )
    parser.add_argument(
        "--tier-weights",
        type=str,
        default=None,
        help='Custom tier targets as JSON, e.g., \'{"1": 25, "2": 25, "3": 25, "4": 14}\''
    )
    parser.add_argument(
        "--list-only",
        action="store_true",
        help="Only list sample IDs to stdout, don't write file"
    )

    args = parser.parse_args()

    # Validate data directory
    cleaned_dir = args.data_dir / "difficulty_stratified" / "cleaned"
    if not cleaned_dir.exists():
        print(f"Error: Cleaned dataset not found: {cleaned_dir}")
        return 1

    # Load samples
    print(f"Loading samples from: {cleaned_dir}\n")
    samples, tier_counts = load_all_samples(args.data_dir)
    print(f"\nTotal: {len(samples)} DS samples\n")

    # Determine tier targets
    if args.tier_weights:
        tier_targets = {int(k): v for k, v in json.loads(args.tier_weights).items()}
    else:
        # Use defaults, capped at available
        tier_targets = {}
        for tier, target in DEFAULT_CONFIG["tier_targets"].items():
            tier_targets[tier] = min(target, tier_counts.get(tier, 0))

    print(f"Sampling configuration:")
    print(f"  Random seed: {args.seed}")
    print(f"  Tier targets: {tier_targets}")
    print(f"  Target total: {sum(tier_targets.values())}\n")

    # Perform sampling
    selected = stratified_sample(samples, tier_targets, tier_counts, args.seed)

    print(f"\n{'='*60}")
    print(f"TOTAL SELECTED: {len(selected)} samples")
    print(f"{'='*60}\n")

    # Output
    if args.list_only:
        for s in sorted(selected, key=lambda x: x['id']):
            print(s['id'])
    else:
        output_data = {
            "sampling_config": {
                "seed": args.seed,
                "tier_targets": tier_targets,
                "data_dir": str(args.data_dir),
            },
            "total_selected": len(selected),
            "by_tier": {
                tier: len([s for s in selected if s['tier'] == tier])
                for tier in [1, 2, 3, 4]
            },
            "selected_samples": [
                {
                    "id": s['id'],
                    "tier": s['tier'],
                    "vtype": s['vtype'],
                }
                for s in sorted(selected, key=lambda x: x['id'])
            ],
        }

        with open(args.output, 'w') as f:
            json.dump(output_data, f, indent=2)

        print(f"Sample manifest written to: {args.output}")

    return 0


if __name__ == "__main__":
    exit(main())
