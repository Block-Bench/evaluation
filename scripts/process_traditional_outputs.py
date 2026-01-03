#!/usr/bin/env python3
"""
Process traditional tool (Slither, Mythril) outputs for LLM judge evaluation.

Filters findings to keep only security-relevant issues:
- Severity: High, Medium
- Confidence: High, Medium (Slither only)
- Excludes informational/optimization detectors

Creates processed outputs alongside raw outputs.
"""

import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))


# Detectors to exclude (noisy, not security-relevant)
SLITHER_EXCLUDE_DETECTORS = {
    # Naming and style
    "naming-convention",
    "similar-names",
    "too-many-digits",
    # Solidity version
    "solc-version",
    "pragma",
    # Optimization
    "external-function",
    "constable-states",
    "immutable-states",
    # Informational
    "assembly",
    "low-level-calls",
    "redundant-statements",
    "dead-code",
    "unused-state",
    "unused-return",  # Can be security but often noise
}

# Minimum severity levels to keep
SLITHER_MIN_SEVERITY = {"High", "Medium"}
SLITHER_MIN_CONFIDENCE = {"High", "Medium"}

# Mythril SWC IDs to exclude (informational)
MYTHRIL_EXCLUDE_SWC = {
    "103",  # Floating Pragma
    "108",  # State Variable Default Visibility (often intentional)
}

MYTHRIL_MIN_SEVERITY = {"High", "Medium"}


def simplify_element(element: dict) -> dict:
    """
    Simplify a Slither element to essential location info only.

    Strips verbose source_mapping with full lines arrays down to:
    - type, name, line_start, line_end, function_context
    """
    simplified = {
        "type": element.get("type", ""),
        "name": element.get("name", ""),
    }

    # Extract line range from source_mapping
    source_mapping = element.get("source_mapping", {})
    lines = source_mapping.get("lines", [])
    if lines:
        simplified["line_start"] = min(lines)
        simplified["line_end"] = max(lines)

    # Extract function context if this is a node
    type_specific = element.get("type_specific_fields", {})
    parent = type_specific.get("parent", {})
    if parent:
        parent_type = parent.get("type", "")
        if parent_type == "function":
            simplified["function"] = parent.get("type_specific_fields", {}).get("signature", "")
            # Also get contract name from function's parent
            func_parent = parent.get("type_specific_fields", {}).get("parent", {})
            if func_parent.get("type") == "contract":
                simplified["contract"] = func_parent.get("name", "")
        elif parent_type == "contract":
            simplified["contract"] = parent.get("name", "")

    return simplified


def process_slither_output(raw_data: dict) -> dict:
    """
    Process Slither output to filter security-relevant findings.

    Args:
        raw_data: Raw Slither detection output

    Returns:
        Processed output with filtered findings
    """
    raw_output = raw_data.get("raw_output", {})
    results = raw_output.get("results", {})
    detectors = results.get("detectors", [])

    original_count = len(detectors)
    filtered_findings = []

    for i, finding in enumerate(detectors):
        check = finding.get("check", "")
        impact = finding.get("impact", "")
        confidence = finding.get("confidence", "")

        # Apply filters
        if check in SLITHER_EXCLUDE_DETECTORS:
            continue
        if impact not in SLITHER_MIN_SEVERITY:
            continue
        if confidence not in SLITHER_MIN_CONFIDENCE:
            continue

        # Simplify elements to essential location info
        raw_elements = finding.get("elements", [])
        simplified_elements = [simplify_element(e) for e in raw_elements]

        # Keep this finding
        filtered_findings.append({
            "original_index": i,
            "check": check,
            "impact": impact,
            "confidence": confidence,
            "description": finding.get("description", ""),
            "elements": simplified_elements,
        })

    # Build processed output
    processed = {
        "sample_id": raw_data.get("sample_id"),
        "tier": raw_data.get("tier"),
        "tool": "slither",
        "tool_version": raw_data.get("tool_version"),
        "solc_version": raw_data.get("solc_version"),
        "timestamp": raw_data.get("timestamp"),
        "success": raw_data.get("success"),
        "error": raw_data.get("error"),
        "execution_time_ms": raw_data.get("execution_time_ms"),
        "processing": {
            "processed_at": datetime.now().isoformat(),
            "original_finding_count": original_count,
            "filtered_finding_count": len(filtered_findings),
            "filters_applied": [
                f"severity in {SLITHER_MIN_SEVERITY}",
                f"confidence in {SLITHER_MIN_CONFIDENCE}",
                f"exclude detectors: {len(SLITHER_EXCLUDE_DETECTORS)} types"
            ],
            "excluded_detectors": list(SLITHER_EXCLUDE_DETECTORS)
        },
        "findings": filtered_findings
    }

    return processed


def process_mythril_output(raw_data: dict) -> dict:
    """
    Process Mythril output to filter security-relevant findings.

    Args:
        raw_data: Raw Mythril detection output

    Returns:
        Processed output with filtered findings
    """
    raw_output = raw_data.get("raw_output", {})
    issues = raw_output.get("issues", [])

    original_count = len(issues)
    filtered_findings = []

    for i, issue in enumerate(issues):
        swc_id = issue.get("swc-id", "")
        severity = issue.get("severity", "")

        # Apply filters
        if swc_id in MYTHRIL_EXCLUDE_SWC:
            continue
        if severity not in MYTHRIL_MIN_SEVERITY:
            continue

        # Keep this finding
        filtered_findings.append({
            "original_index": i,
            "title": issue.get("title", ""),
            "swc_id": swc_id,
            "severity": severity,
            "description": issue.get("description", ""),
            "contract": issue.get("contract", ""),
            "function": issue.get("function", ""),
            "lineno": issue.get("lineno"),
            "code": issue.get("code", ""),
        })

    # Build processed output
    processed = {
        "sample_id": raw_data.get("sample_id"),
        "tier": raw_data.get("tier"),
        "tool": "mythril",
        "tool_version": raw_data.get("tool_version"),
        "solc_version": raw_data.get("solc_version"),
        "timestamp": raw_data.get("timestamp"),
        "success": raw_data.get("success"),
        "error": raw_data.get("error"),
        "execution_time_ms": raw_data.get("execution_time_ms"),
        "used_reduced_depth": raw_data.get("used_reduced_depth", False),
        "processing": {
            "processed_at": datetime.now().isoformat(),
            "original_finding_count": original_count,
            "filtered_finding_count": len(filtered_findings),
            "filters_applied": [
                f"severity in {MYTHRIL_MIN_SEVERITY}",
                f"exclude SWC IDs: {MYTHRIL_EXCLUDE_SWC}"
            ],
            "excluded_swc_ids": list(MYTHRIL_EXCLUDE_SWC)
        },
        "findings": filtered_findings
    }

    return processed


def reorganize_folder_structure(tool: str, tier: str) -> tuple[Path, Path]:
    """
    Reorganize folder structure to have raw/ and processed/ subdirectories.

    Returns:
        Tuple of (raw_dir, processed_dir)
    """
    base_dir = PROJECT_ROOT / "results" / "detection" / "traditional" / tool / "ds" / tier
    raw_dir = base_dir / "raw"
    processed_dir = base_dir / "processed"

    # Create directories
    raw_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)

    # Move existing files to raw/ if they're in the base directory
    for f in base_dir.glob("d_*.json"):
        if f.parent == base_dir:  # Only move files in base dir, not subdirs
            dest = raw_dir / f.name
            if not dest.exists():
                shutil.move(str(f), str(dest))
                print(f"  Moved {f.name} to raw/")

    return raw_dir, processed_dir


def process_tier(tool: str, tier: str) -> dict:
    """
    Process all samples in a tier.

    Returns:
        Summary statistics
    """
    print(f"\n{'='*60}")
    print(f"Processing {tool} / {tier}")
    print(f"{'='*60}")

    # Reorganize folders
    raw_dir, processed_dir = reorganize_folder_structure(tool, tier)

    # Get processor function
    if tool == "slither":
        processor = process_slither_output
    elif tool == "mythril":
        processor = process_mythril_output
    else:
        raise ValueError(f"Unknown tool: {tool}")

    # Process each raw file
    stats = {
        "total": 0,
        "successful": 0,
        "failed": 0,
        "total_original_findings": 0,
        "total_filtered_findings": 0,
    }

    for raw_file in sorted(raw_dir.glob("d_*.json")):
        sample_id = raw_file.stem.replace("d_", "")
        stats["total"] += 1

        try:
            # Load raw data
            with open(raw_file) as f:
                raw_data = json.load(f)

            # Skip failed analyses
            if not raw_data.get("success", False):
                print(f"  {sample_id}: Skipped (analysis failed)")
                stats["failed"] += 1
                continue

            # Process
            processed = processor(raw_data)

            # Save processed output
            processed_file = processed_dir / f"p_{sample_id}.json"
            with open(processed_file, 'w') as f:
                json.dump(processed, f, indent=2)

            orig = processed["processing"]["original_finding_count"]
            filt = processed["processing"]["filtered_finding_count"]
            stats["total_original_findings"] += orig
            stats["total_filtered_findings"] += filt
            stats["successful"] += 1

            print(f"  {sample_id}: {orig} -> {filt} findings")

        except Exception as e:
            print(f"  {sample_id}: Error - {e}")
            stats["failed"] += 1

    # Print summary
    print(f"\nSummary for {tool}/{tier}:")
    print(f"  Processed: {stats['successful']}/{stats['total']}")
    print(f"  Failed: {stats['failed']}")
    if stats["successful"] > 0:
        reduction = (1 - stats["total_filtered_findings"] / stats["total_original_findings"]) * 100
        print(f"  Total findings: {stats['total_original_findings']} -> {stats['total_filtered_findings']} ({reduction:.1f}% reduction)")

    return stats


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Process traditional tool outputs for LLM judge evaluation"
    )
    parser.add_argument(
        "--tool",
        choices=["slither", "mythril", "all"],
        default="all",
        help="Tool to process (default: all)"
    )
    parser.add_argument(
        "--tier",
        default="tier1",
        help="Tier to process (default: tier1)"
    )

    args = parser.parse_args()

    tools = ["slither", "mythril"] if args.tool == "all" else [args.tool]

    all_stats = {}
    for tool in tools:
        try:
            all_stats[tool] = process_tier(tool, args.tier)
        except FileNotFoundError as e:
            print(f"\nSkipping {tool}/{args.tier}: {e}")

    # Final summary
    print(f"\n{'='*60}")
    print("Processing Complete")
    print(f"{'='*60}")
    for tool, stats in all_stats.items():
        print(f"{tool}: {stats['successful']} samples processed")


if __name__ == "__main__":
    main()
