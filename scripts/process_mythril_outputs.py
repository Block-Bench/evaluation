#!/usr/bin/env python3
"""
Process Mythril raw outputs to create simplified versions for LLM judge.

Removes verbose tx_sequence data (bytecode, transaction traces) while
keeping essential vulnerability information.
"""

import json
import argparse
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent


def simplify_issue(issue: dict) -> dict:
    """Simplify a Mythril issue to essential fields only."""
    return {
        "title": issue.get("title", ""),
        "swc_id": issue.get("swc-id", ""),
        "severity": issue.get("severity", ""),
        "contract": issue.get("contract", ""),
        "function": issue.get("function", ""),
        "lineno": issue.get("lineno"),
        "code": issue.get("code", "")[:500],  # Truncate long code snippets
        "description": issue.get("description", "")[:500],  # Truncate long descriptions
    }


def process_mythril_output(raw_result: dict) -> dict:
    """Process a single Mythril result file."""
    processed = {
        "sample_id": raw_result.get("sample_id"),
        "tier": raw_result.get("tier"),
        "tool": "mythril",
        "tool_version": raw_result.get("tool_version"),
        "solc_version": raw_result.get("solc_version"),
        "success": raw_result.get("success", False),
        "error": raw_result.get("error"),
        "execution_time_ms": raw_result.get("execution_time_ms"),
        "findings": []
    }

    # Process issues if successful
    if raw_result.get("success") and raw_result.get("raw_output"):
        issues = raw_result["raw_output"].get("issues", [])
        for issue in issues:
            simplified = simplify_issue(issue)
            processed["findings"].append(simplified)

    processed["findings_count"] = len(processed["findings"])

    return processed


def process_tier(tier: str, force: bool = False) -> dict:
    """Process all Mythril outputs for a tier."""
    raw_dir = PROJECT_ROOT / f"results/detection/traditional/mythril/ds/{tier}"
    processed_dir = raw_dir / "processed"
    processed_dir.mkdir(parents=True, exist_ok=True)

    # Also create raw subfolder and move existing files if needed
    raw_subfolder = raw_dir / "raw"
    raw_subfolder.mkdir(exist_ok=True)

    stats = {
        "total_files": 0,
        "processed": 0,
        "skipped": 0,
        "total_raw_lines": 0,
        "total_processed_lines": 0,
        "total_raw_chars": 0,
        "total_processed_chars": 0,
    }

    # Find raw files (either in base dir or raw subfolder)
    raw_files = list(raw_dir.glob("d_*.json"))
    if not raw_files:
        raw_files = list(raw_subfolder.glob("d_*.json"))

    for raw_file in sorted(raw_files):
        stats["total_files"] += 1
        sample_id = raw_file.stem[2:]  # Remove "d_" prefix

        processed_file = processed_dir / f"p_{sample_id}.json"

        if processed_file.exists() and not force:
            stats["skipped"] += 1
            continue

        # Read raw file
        with open(raw_file) as f:
            raw_content = f.read()
            raw_result = json.loads(raw_content)

        # Process
        processed_result = process_mythril_output(raw_result)

        # Write processed file
        processed_content = json.dumps(processed_result, indent=2)
        with open(processed_file, 'w') as f:
            f.write(processed_content)

        # Track stats
        stats["total_raw_lines"] += raw_content.count('\n')
        stats["total_processed_lines"] += processed_content.count('\n')
        stats["total_raw_chars"] += len(raw_content)
        stats["total_processed_chars"] += len(processed_content)
        stats["processed"] += 1

        print(f"  {sample_id}: {raw_content.count(chr(10))} -> {processed_content.count(chr(10))} lines, "
              f"{len(processed_result['findings'])} findings")

    return stats


def main():
    parser = argparse.ArgumentParser(description="Process Mythril outputs for LLM judge")
    parser.add_argument("--tier", default="tier1", help="Tier to process (default: tier1)")
    parser.add_argument("--force", action="store_true", help="Force reprocessing of all files")
    args = parser.parse_args()

    print(f"Processing Mythril outputs for {args.tier}")
    print("=" * 60)

    stats = process_tier(args.tier, args.force)

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Total files: {stats['total_files']}")
    print(f"Processed: {stats['processed']}")
    print(f"Skipped (cached): {stats['skipped']}")

    if stats['processed'] > 0:
        line_reduction = (1 - stats['total_processed_lines'] / stats['total_raw_lines']) * 100 if stats['total_raw_lines'] > 0 else 0
        char_reduction = (1 - stats['total_processed_chars'] / stats['total_raw_chars']) * 100 if stats['total_raw_chars'] > 0 else 0

        print(f"\nSize Reduction:")
        print(f"  Lines: {stats['total_raw_lines']} -> {stats['total_processed_lines']} ({line_reduction:.1f}% reduction)")
        print(f"  Chars: {stats['total_raw_chars']} -> {stats['total_processed_chars']} ({char_reduction:.1f}% reduction)")


if __name__ == "__main__":
    main()
