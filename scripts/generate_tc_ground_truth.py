#!/usr/bin/env python3
"""
Generate ground truth files for TC variants in DS format.
Converts TC metadata to ground_truth format used by the judge.
"""

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent


def convert_metadata_to_ground_truth(metadata: dict) -> dict:
    """Convert TC metadata to DS ground_truth format."""

    # Get vulnerable function as array
    vuln_func = metadata.get("vulnerable_function", "")
    vulnerable_functions = [vuln_func] if vuln_func else []

    return {
        "is_vulnerable": metadata.get("is_vulnerable", True),
        "vulnerability_type": metadata.get("vulnerability_type", "unknown"),
        "vulnerable_functions": vulnerable_functions,
        "severity": metadata.get("severity", "unknown"),
        "description": metadata.get("description", ""),
        "root_cause": metadata.get("root_cause", ""),
        "attack_scenario": metadata.get("attack_scenario", ""),
        "fix_description": metadata.get("fix_description", ""),
        "language": metadata.get("language", "solidity")
    }


def main():
    samples_dir = PROJECT_ROOT / "samples/tc"

    # Get all TC variants
    variants = [d.name for d in samples_dir.iterdir() if d.is_dir()]

    print(f"Found {len(variants)} TC variants: {', '.join(sorted(variants))}")

    for variant in sorted(variants):
        variant_dir = samples_dir / variant
        metadata_dir = variant_dir / "metadata"
        ground_truth_dir = variant_dir / "ground_truth"

        if not metadata_dir.exists():
            print(f"\n{variant}: No metadata folder, skipping")
            continue

        # Create ground_truth directory
        ground_truth_dir.mkdir(exist_ok=True)

        # Process each metadata file
        metadata_files = sorted(metadata_dir.glob("*.json"))
        count = 0

        for meta_file in metadata_files:
            sample_id = meta_file.stem

            with open(meta_file) as f:
                metadata = json.load(f)

            ground_truth = convert_metadata_to_ground_truth(metadata)

            gt_file = ground_truth_dir / f"{sample_id}.json"
            with open(gt_file, "w") as f:
                json.dump(ground_truth, f, indent=2)

            count += 1

        print(f"{variant}: Generated {count} ground truth files")

    print("\nDone!")


if __name__ == "__main__":
    main()
