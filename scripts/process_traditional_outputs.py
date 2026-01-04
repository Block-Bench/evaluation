#!/usr/bin/env python3
"""
Process traditional tool (Slither, Mythril) outputs for LLM judge evaluation.

Filtering strategy:
- High/Medium severity: Keep all (clearly security-relevant)
- Low severity: Keep only if finding maps to a known vulnerability type
- Informational/Optimization: Filter out

Uses comprehensive vulnerability mapping to ensure we don't miss valid findings.
"""

import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))


# =============================================================================
# COMPREHENSIVE VULNERABILITY TYPE MAPPING
# Maps ground truth vulnerability types to tool-specific finding names
# =============================================================================

# Slither check -> ground truth vulnerability type mapping
SLITHER_CHECK_TO_VULN_TYPE = {
    # Reentrancy
    "reentrancy-eth": "reentrancy",
    "reentrancy-no-eth": "reentrancy",
    "reentrancy-unlimited-gas": "reentrancy",
    "reentrancy-benign": "reentrancy",  # Low severity but still reentrancy
    "reentrancy-events": "reentrancy",  # Low severity but still reentrancy

    # Access Control
    "suicidal": "access_control",
    "arbitrary-send-eth": "access_control",
    "arbitrary-send-erc20": "access_control",
    "unprotected-upgrade": "access_control",
    "controlled-delegatecall": "access_control",

    # Unchecked Return Values
    "unchecked-send": "unchecked_return",
    "unchecked-lowlevel": "unchecked_return",
    "unchecked-transfer": "unchecked_return",
    "unused-return": "unchecked_return",

    # Integer Issues
    "divide-before-multiply": "integer_issues",
    "controlled-array-length": "integer_issues",
    "incorrect-exp": "integer_issues",
    "tautology": "integer_issues",

    # Weak Randomness / Timestamp
    "weak-prng": "weak_randomness",
    "timestamp": "timestamp_dependency",  # Also maps to weak_randomness contextually

    # Denial of Service
    "locked-ether": "dos",
    "calls-loop": "dos",
    "return-bomb": "dos",
    "mapping-deletion": "dos",

    # Interface Issues
    "erc20-interface": "interface_mismatch",
    "incorrect-modifier": "interface_mismatch",
    "incorrect-equality": "logic_error",

    # Variable Shadowing
    "shadowing-state": "variable_shadowing",
    "shadowing-local": "variable_shadowing",
    "shadowing-builtin": "variable_shadowing",

    # Initialization Issues
    "uninitialized-state": "logic_error",
    "uninitialized-storage": "storage_misuse",
    "uninitialized-local": "logic_error",

    # tx.origin
    "tx-origin": "tx_origin_auth",

    # Selfdestruct
    # (suicidal already mapped to access_control)

    # Encode collision
    "encode-packed-collision": "logic_error",

    # Constant function issues
    "constant-function-asm": "logic_error",

    # Return issues
    "incorrect-return": "logic_error",

    # Missing checks
    "missing-zero-check": "logic_error",  # Can indicate missing validation

    # Events (informational but keep for completeness in Low)
    "events-access": "logic_error",
    "events-maths": "logic_error",
}

# Mythril title -> ground truth vulnerability type mapping
MYTHRIL_TITLE_TO_VULN_TYPE = {
    # Reentrancy
    "State access after external call": "reentrancy",
    "State change after external call": "reentrancy",
    "External Call To User-Supplied Address": "reentrancy",  # Can indicate reentrancy risk

    # Access Control
    "Delegatecall to user-supplied address": "access_control",
    "Unprotected Ether Withdrawal": "access_control",
    "Unprotected Selfdestruct": "access_control",

    # Unchecked Return
    "Unchecked return value from external call.": "unchecked_return",

    # Integer Issues
    "Integer Arithmetic Bugs": "integer_issues",
    "Integer Overflow": "integer_issues",
    "Integer Underflow": "integer_issues",

    # Weak Randomness / Timestamp / Front-running
    "Dependence on predictable environment variable": "weak_randomness",
    "Transaction Order Dependence": "front_running",

    # tx.origin
    "Dependence on tx.origin": "tx_origin_auth",

    # Multiple calls (can indicate DoS or reentrancy risk)
    "Multiple Calls in a Single Transaction": "dos",

    # Exception state (assertion failures - can indicate logic errors)
    "Exception State": "logic_error",
}

# Mythril SWC IDs to exclude (truly informational)
MYTHRIL_EXCLUDE_SWC = {
    "103",  # Floating Pragma
    "108",  # State Variable Default Visibility (often intentional)
}

# Slither detectors to always exclude (noise, not security-relevant)
SLITHER_ALWAYS_EXCLUDE = {
    # Naming and style
    "naming-convention",
    "similar-names",
    "too-many-digits",
    # Solidity version
    "solc-version",
    "pragma",
    # Optimization (not security)
    "external-function",
    "constable-states",
    "immutable-states",
    "cache-array-length",
    # Pure informational
    "assembly",
    "low-level-calls",
    "redundant-statements",
    "dead-code",
    "unused-state",
    "costly-loop",
    "deprecated-standards",
    "missing-inheritance",
    "boolean-equal",
}


def simplify_element(element: dict) -> dict:
    """
    Simplify a Slither element to essential location info only.
    """
    simplified = {
        "type": element.get("type", ""),
        "name": element.get("name", ""),
    }

    source_mapping = element.get("source_mapping", {})
    lines = source_mapping.get("lines", [])
    if lines:
        simplified["line_start"] = min(lines)
        simplified["line_end"] = max(lines)

    type_specific = element.get("type_specific_fields", {})
    parent = type_specific.get("parent", {})
    if parent:
        parent_type = parent.get("type", "")
        if parent_type == "function":
            simplified["function"] = parent.get("type_specific_fields", {}).get("signature", "")
            func_parent = parent.get("type_specific_fields", {}).get("parent", {})
            if func_parent.get("type") == "contract":
                simplified["contract"] = func_parent.get("name", "")
        elif parent_type == "contract":
            simplified["contract"] = parent.get("name", "")

    return simplified


def process_slither_output(raw_data: dict) -> dict:
    """
    Process Slither output with smart filtering:
    - High/Medium: Keep all
    - Low: Keep only if check maps to known vulnerability type
    - Informational/Optimization: Filter out
    """
    raw_output = raw_data.get("raw_output", {})
    results = raw_output.get("results", {})
    detectors = results.get("detectors", [])

    original_count = len(detectors)
    filtered_findings = []
    filter_reasons = {"kept_high_medium": 0, "kept_low_mapped": 0, "filtered_excluded": 0,
                      "filtered_low_unmapped": 0, "filtered_informational": 0}

    for i, finding in enumerate(detectors):
        check = finding.get("check", "")
        impact = finding.get("impact", "")
        confidence = finding.get("confidence", "")

        # Always exclude certain detectors
        if check in SLITHER_ALWAYS_EXCLUDE:
            filter_reasons["filtered_excluded"] += 1
            continue

        # Filter by severity with smart Low handling
        if impact in {"High", "Medium"}:
            # Keep all High/Medium
            filter_reasons["kept_high_medium"] += 1
        elif impact == "Low":
            # Keep Low only if it maps to a known vulnerability type
            if check in SLITHER_CHECK_TO_VULN_TYPE:
                filter_reasons["kept_low_mapped"] += 1
            else:
                filter_reasons["filtered_low_unmapped"] += 1
                continue
        else:
            # Filter Informational/Optimization
            filter_reasons["filtered_informational"] += 1
            continue

        # Confidence filter (only for High/Medium - be lenient on mapped Low)
        if impact in {"High", "Medium"} and confidence not in {"High", "Medium"}:
            continue

        # Simplify elements
        raw_elements = finding.get("elements", [])
        simplified_elements = [simplify_element(e) for e in raw_elements]

        # Get mapped vulnerability type if available
        mapped_vuln_type = SLITHER_CHECK_TO_VULN_TYPE.get(check)

        filtered_findings.append({
            "original_index": i,
            "check": check,
            "impact": impact,
            "confidence": confidence,
            "mapped_vuln_type": mapped_vuln_type,
            "description": finding.get("description", ""),
            "elements": simplified_elements,
        })

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
            "filter_breakdown": filter_reasons,
            "filters_applied": [
                "High/Medium severity: keep all",
                "Low severity: keep only if mapped to vulnerability type",
                "Informational/Optimization: filter out",
                f"Always exclude: {len(SLITHER_ALWAYS_EXCLUDE)} detector types"
            ],
        },
        "findings": filtered_findings
    }

    return processed


def process_mythril_output(raw_data: dict) -> dict:
    """
    Process Mythril output with smart filtering:
    - High/Medium: Keep all
    - Low: Keep only if title maps to known vulnerability type
    - Excluded SWC IDs: Filter out
    """
    raw_output = raw_data.get("raw_output", {})
    issues = raw_output.get("issues", [])

    original_count = len(issues)
    filtered_findings = []
    filter_reasons = {"kept_high_medium": 0, "kept_low_mapped": 0,
                      "filtered_excluded_swc": 0, "filtered_low_unmapped": 0}

    for i, issue in enumerate(issues):
        swc_id = issue.get("swc-id", "")
        severity = issue.get("severity", "")
        title = issue.get("title", "")

        # Exclude certain SWC IDs
        if swc_id in MYTHRIL_EXCLUDE_SWC:
            filter_reasons["filtered_excluded_swc"] += 1
            continue

        # Filter by severity with smart Low handling
        if severity in {"High", "Medium"}:
            filter_reasons["kept_high_medium"] += 1
        elif severity == "Low":
            # Keep Low only if it maps to a known vulnerability type
            if title in MYTHRIL_TITLE_TO_VULN_TYPE:
                filter_reasons["kept_low_mapped"] += 1
            else:
                filter_reasons["filtered_low_unmapped"] += 1
                continue
        else:
            continue

        # Get mapped vulnerability type if available
        mapped_vuln_type = MYTHRIL_TITLE_TO_VULN_TYPE.get(title)

        filtered_findings.append({
            "original_index": i,
            "title": title,
            "swc_id": swc_id,
            "severity": severity,
            "mapped_vuln_type": mapped_vuln_type,
            "description": issue.get("description", ""),
            "contract": issue.get("contract", ""),
            "function": issue.get("function", ""),
            "lineno": issue.get("lineno"),
            "code": issue.get("code", ""),
        })

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
            "filter_breakdown": filter_reasons,
            "filters_applied": [
                "High/Medium severity: keep all",
                "Low severity: keep only if mapped to vulnerability type",
                f"Excluded SWC IDs: {MYTHRIL_EXCLUDE_SWC}"
            ],
        },
        "findings": filtered_findings
    }

    return processed


def reorganize_folder_structure(tool: str, tier: str) -> tuple[Path, Path]:
    """
    Reorganize folder structure to have raw/ and processed/ subdirectories.
    """
    base_dir = PROJECT_ROOT / "results" / "detection" / "traditional" / tool / "ds" / tier
    raw_dir = base_dir / "raw"
    processed_dir = base_dir / "processed"

    raw_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)

    for f in base_dir.glob("d_*.json"):
        if f.parent == base_dir:
            dest = raw_dir / f.name
            if not dest.exists():
                shutil.move(str(f), str(dest))
                print(f"  Moved {f.name} to raw/")

    return raw_dir, processed_dir


def process_tier(tool: str, tier: str) -> dict:
    """Process all samples in a tier."""
    print(f"\n{'='*60}")
    print(f"Processing {tool} / {tier}")
    print(f"{'='*60}")

    raw_dir, processed_dir = reorganize_folder_structure(tool, tier)

    if tool == "slither":
        processor = process_slither_output
    elif tool == "mythril":
        processor = process_mythril_output
    else:
        raise ValueError(f"Unknown tool: {tool}")

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
            with open(raw_file) as f:
                raw_data = json.load(f)

            if not raw_data.get("success", False):
                print(f"  {sample_id}: Skipped (analysis failed)")
                stats["failed"] += 1
                continue

            processed = processor(raw_data)

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

    print(f"\nSummary for {tool}/{tier}:")
    print(f"  Processed: {stats['successful']}/{stats['total']}")
    print(f"  Failed: {stats['failed']}")
    if stats["successful"] > 0 and stats["total_original_findings"] > 0:
        reduction = (1 - stats["total_filtered_findings"] / stats["total_original_findings"]) * 100
        print(f"  Total findings: {stats['total_original_findings']} -> {stats['total_filtered_findings']} ({reduction:.1f}% reduction)")

    return stats


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Process traditional tool outputs with smart vulnerability-aware filtering"
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

    print(f"\n{'='*60}")
    print("Processing Complete")
    print(f"{'='*60}")
    for tool, stats in all_stats.items():
        print(f"{tool}: {stats['successful']} samples processed")


if __name__ == "__main__":
    main()
