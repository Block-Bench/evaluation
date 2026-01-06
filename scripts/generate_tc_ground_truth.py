#!/usr/bin/env python3
"""
Generate ground truth files for TC variants in DS format.
Converts TC metadata to ground_truth format used by the judge.
"""

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent


def convert_metadata_to_ground_truth(metadata: dict) -> dict:
    """Convert TC metadata to DS ground_truth format.

    Handles varying metadata schemas:
    - root_cause: top-level OR vulnerability_details.root_cause
    - attack: attack_scenario (top) OR attack_vector (vd) OR attack_flow (top, array)
    - fix: fix_description (top) OR fix (top) OR mitigation (top, array)
    - functions: vulnerable_function (top, string) + vulnerable_functions (vd, array)
    """

    # Get vulnerability details (nested in metadata)
    vuln_details = metadata.get("vulnerability_details", {})
    if not isinstance(vuln_details, dict):
        vuln_details = {}

    # ============================================================
    # VULNERABLE FUNCTIONS - collect from all sources
    # ============================================================
    vulnerable_functions = []

    # 1. From vulnerability_details.vulnerable_functions (array)
    vd_funcs = vuln_details.get("vulnerable_functions", [])
    if isinstance(vd_funcs, list):
        vulnerable_functions.extend(vd_funcs)
    elif isinstance(vd_funcs, str) and vd_funcs:
        vulnerable_functions.append(vd_funcs)

    # 2. From top-level vulnerable_function (string) - always present
    top_func = metadata.get("vulnerable_function", "")
    if top_func and top_func not in vulnerable_functions:
        vulnerable_functions.append(top_func)

    # 3. From top-level vulnerable_functions (array) - rare but check
    top_funcs = metadata.get("vulnerable_functions", [])
    if isinstance(top_funcs, list):
        for f in top_funcs:
            if f and f not in vulnerable_functions:
                vulnerable_functions.append(f)

    # Clean up function names (remove parentheses inconsistency)
    vulnerable_functions = [f.rstrip("()") for f in vulnerable_functions if f]
    vulnerable_functions = list(dict.fromkeys(vulnerable_functions))  # dedupe preserving order

    # ============================================================
    # ROOT CAUSE - check multiple locations
    # ============================================================
    # Priority: top-level root_cause > vulnerability_details.root_cause
    root_cause = metadata.get("root_cause", "") or vuln_details.get("root_cause", "")

    # Add key weaknesses for additional context if available
    key_weakness = vuln_details.get("key_weakness", [])
    if key_weakness and isinstance(key_weakness, list) and root_cause:
        root_cause += f"\n\nKey Weaknesses: {'; '.join(key_weakness[:3])}"

    # ============================================================
    # ATTACK SCENARIO - check multiple field names
    # ============================================================
    # Priority: attack_scenario (top) > attack_vector (vd) > attack_flow (top, array)
    attack_scenario = metadata.get("attack_scenario", "")

    if not attack_scenario:
        attack_scenario = vuln_details.get("attack_vector", "")

    # Add attack_flow if available (detailed step-by-step)
    attack_flow = metadata.get("attack_flow", [])
    if attack_flow and isinstance(attack_flow, list):
        attack_flow_text = " → ".join(attack_flow)
        if attack_scenario:
            attack_scenario = f"{attack_scenario}\n\nAttack Flow: {attack_flow_text}"
        else:
            attack_scenario = attack_flow_text

    # ============================================================
    # FIX DESCRIPTION - check multiple field names
    # ============================================================
    # Priority: fix_description > fix > mitigation (array)
    fix_description = metadata.get("fix_description", "")

    if not fix_description:
        fix_description = metadata.get("fix", "")

    if not fix_description:
        mitigation = metadata.get("mitigation", [])
        if isinstance(mitigation, list) and mitigation:
            fix_description = "; ".join(mitigation[:3])  # Top 3 mitigations
        elif isinstance(mitigation, str) and mitigation:
            fix_description = mitigation

    # ============================================================
    # BUILD GROUND TRUTH
    # ============================================================
    return {
        "is_vulnerable": metadata.get("is_vulnerable", True),
        "vulnerability_type": metadata.get("vulnerability_type", "unknown"),
        "vulnerable_functions": vulnerable_functions,
        "severity": metadata.get("severity", "unknown"),
        "description": metadata.get("description", ""),
        "root_cause": root_cause,
        "attack_scenario": attack_scenario,
        "fix_description": fix_description,
        "language": metadata.get("language", "solidity"),
        # Additional fields for richer evaluation
        "vulnerable_lines": metadata.get("vulnerable_lines", []),
        "sub_category": metadata.get("sub_category", ""),
    }


def get_reference_metadata(sample_id: str, samples_dir: Path) -> dict | None:
    """Get metadata from minimalsanitized as reference for missing fields.

    All TC variants share the same parent (tc_XXX), so minimalsanitized
    metadata can fill in missing fields for other variants.
    """
    import re

    # Extract the numeric part: df_tc_029 -> 029, tr_tc_001 -> 001
    match = re.search(r'(\d+)$', sample_id)
    if not match:
        return None

    num = match.group(1)
    ref_sample_id = f"ms_tc_{num}"
    ref_path = samples_dir / "minimalsanitized" / "metadata" / f"{ref_sample_id}.json"

    if ref_path.exists():
        with open(ref_path) as f:
            return json.load(f)
    return None


def merge_metadata_with_reference(metadata: dict, reference: dict | None) -> dict:
    """Merge metadata with reference, using reference for missing fields."""
    if not reference:
        return metadata

    merged = metadata.copy()
    ref_vd = reference.get("vulnerability_details", {}) or {}

    # Fill in missing top-level fields from reference
    if not merged.get("root_cause"):
        merged["root_cause"] = reference.get("root_cause") or ref_vd.get("root_cause", "")

    if not merged.get("attack_scenario"):
        merged["attack_scenario"] = reference.get("attack_scenario") or ref_vd.get("attack_vector", "")

    if not merged.get("attack_flow") and reference.get("attack_flow"):
        merged["attack_flow"] = reference.get("attack_flow")

    if not merged.get("fix_description") and not merged.get("fix") and not merged.get("mitigation"):
        merged["fix_description"] = reference.get("fix_description") or reference.get("fix", "")
        if not merged["fix_description"]:
            merged["mitigation"] = reference.get("mitigation", [])

    # Fill in vulnerability_details if missing
    if not merged.get("vulnerability_details") and ref_vd:
        merged["vulnerability_details"] = ref_vd

    return merged


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
        filled_from_ref = 0

        for meta_file in metadata_files:
            sample_id = meta_file.stem

            with open(meta_file) as f:
                metadata = json.load(f)

            # For variants other than minimalsanitized, try to fill missing data from reference
            if variant != "minimalsanitized":
                reference = get_reference_metadata(sample_id, samples_dir)
                original_rc = metadata.get("root_cause") or (metadata.get("vulnerability_details", {}) or {}).get("root_cause")
                metadata = merge_metadata_with_reference(metadata, reference)
                new_rc = metadata.get("root_cause") or (metadata.get("vulnerability_details", {}) or {}).get("root_cause")
                if not original_rc and new_rc:
                    filled_from_ref += 1

            ground_truth = convert_metadata_to_ground_truth(metadata)

            gt_file = ground_truth_dir / f"{sample_id}.json"
            with open(gt_file, "w") as f:
                json.dump(ground_truth, f, indent=2)

            count += 1

        if filled_from_ref > 0:
            print(f"{variant}: Generated {count} ground truth files ({filled_from_ref} filled from reference)")
        else:
            print(f"{variant}: Generated {count} ground truth files")

    print("\nDone!")


if __name__ == "__main__":
    main()
