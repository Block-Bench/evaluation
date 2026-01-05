#!/usr/bin/env python3
"""
Generate ground truth files for GS (Gold Standard) dataset from metadata.
"""

import json
from pathlib import Path


def generate_ground_truth():
    """Generate ground truth JSON files from metadata."""

    base_dir = Path(__file__).parent.parent
    metadata_dir = base_dir / "samples" / "gs" / "metadata"
    ground_truth_dir = base_dir / "samples" / "gs" / "ground_truth"

    # Create ground_truth directory
    ground_truth_dir.mkdir(exist_ok=True)

    # Get all metadata files
    metadata_files = sorted(metadata_dir.glob("gs_*.json"))

    print(f"Found {len(metadata_files)} metadata files")

    for metadata_file in metadata_files:
        # Extract sample ID (gs_001, gs_002, etc.)
        sample_id = metadata_file.stem  # e.g., "gs_001"

        # Load metadata
        with open(metadata_file) as f:
            metadata = json.load(f)

        # Create ground truth structure (same fields as TC)
        ground_truth = {
            "is_vulnerable": metadata.get("is_vulnerable", True),
            "vulnerability_type": metadata.get("vulnerability_type", ""),
            "vulnerable_functions": [metadata.get("vulnerable_function", "")] if metadata.get("vulnerable_function") else [],
            "severity": metadata.get("severity", ""),
            "description": metadata.get("description", ""),
            "root_cause": metadata.get("root_cause", ""),
            "attack_scenario": metadata.get("attack_scenario", ""),
            "fix_description": metadata.get("fix_description", ""),
            "language": metadata.get("language", "solidity"),
        }

        # Write ground truth file
        output_file = ground_truth_dir / f"{sample_id}.json"
        with open(output_file, "w") as f:
            json.dump(ground_truth, f, indent=2)

        print(f"Generated: {output_file.name}")

    print(f"\nTotal: {len(metadata_files)} ground truth files generated")


if __name__ == "__main__":
    generate_ground_truth()
