#!/usr/bin/env python3
"""
Analyze inter-annotator agreement between LLM judges.

Creates tables showing judge agreement/disagreement on target_found verdicts.
"""

import argparse
import json
import csv
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent

# Available judges (add/remove as needed)
JUDGES = ["codestral", "gemini-3-flash", "mimo-v2-flash"]
# JUDGES = ["codestral", "gemini-3-flash", "mimo-v2-flash", "glm-4.7"]  # Include GLM when ready

# Available detectors
DETECTORS = [
    "claude-opus-4-5",
    "deepseek-v3-2",
    "gemini-3-pro",
    "gpt-5.2",
    "grok-4-fast",
    "llama-4-maverick",
    "qwen3-coder-plus"
]


def load_judge_results(judge: str, detector: str, tier: int) -> dict:
    """Load all judge results for a detector/tier combination."""
    results = {}
    judge_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/ds/tier{tier}"

    if not judge_dir.exists():
        return results

    for f in judge_dir.glob("j_*.json"):
        sample_id = f.stem.replace("j_", "")
        try:
            data = json.loads(f.read_text())
            # Extract target_found from the judge result
            target_assessment = data.get("target_assessment", {})
            target_found = target_assessment.get("found", False)
            results[sample_id] = target_found
        except Exception as e:
            print(f"Warning: Could not load {f}: {e}")

    return results


def create_detector_table(detector: str, tier: int, output_dir: Path) -> dict:
    """
    Create a table comparing judge verdicts for a single detector.

    Returns dict of {sample_id: {judge: verdict, ...}} for aggregation.
    """
    # Load results from all judges for this detector
    judge_results = {}
    all_samples = set()

    for judge in JUDGES:
        results = load_judge_results(judge, detector, tier)
        judge_results[judge] = results
        all_samples.update(results.keys())

    if not all_samples:
        print(f"  No data for {detector}")
        return {}

    # Sort samples
    all_samples = sorted(all_samples)

    # Build table
    rows = []
    sample_data = {}

    for sample_id in all_samples:
        row = {"sample_id": sample_id}
        verdicts = []

        for judge in JUDGES:
            verdict = judge_results[judge].get(sample_id)
            if verdict is None:
                row[judge] = "-"
            else:
                row[judge] = "YES" if verdict else "NO"
                verdicts.append(verdict)

        # Calculate agreement
        if len(verdicts) == 0:
            row["agreement"] = "NO DATA"
            row["disagree_count"] = 0
            row["total_judges"] = 0
        else:
            yes_count = sum(verdicts)
            no_count = len(verdicts) - yes_count

            if yes_count == len(verdicts):
                row["agreement"] = f"FULL YES ({len(verdicts)}/{len(verdicts)})"
                row["disagree_count"] = 0
            elif no_count == len(verdicts):
                row["agreement"] = f"FULL NO ({len(verdicts)}/{len(verdicts)})"
                row["disagree_count"] = 0
            else:
                row["agreement"] = f"SPLIT ({yes_count}Y/{no_count}N)"
                row["disagree_count"] = min(yes_count, no_count)  # Number of dissenting votes

            row["total_judges"] = len(verdicts)

        rows.append(row)
        sample_data[sample_id] = {
            "verdicts": {j: judge_results[j].get(sample_id) for j in JUDGES},
            "disagree_count": row["disagree_count"],
            "total_judges": row["total_judges"]
        }

    # Write CSV
    output_path = output_dir / f"{detector}_judges.csv"
    with open(output_path, 'w', newline='') as f:
        fieldnames = ["sample_id"] + JUDGES + ["agreement"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row[k] for k in fieldnames})

    print(f"  Saved: {output_path.name} ({len(rows)} samples)")
    return sample_data


def create_aggregated_table(all_detector_data: dict, tier: int, output_dir: Path):
    """
    Create aggregated table showing cross-detector disagreement.

    Sorted by highest disagreement first.
    """
    # Collect all samples
    all_samples = set()
    for detector, data in all_detector_data.items():
        all_samples.update(data.keys())

    all_samples = sorted(all_samples)

    # Calculate per-sample disagreement across all detectors
    rows = []

    for sample_id in all_samples:
        total_disagree = 0
        total_comparisons = 0
        detector_details = []

        for detector in DETECTORS:
            if detector in all_detector_data and sample_id in all_detector_data[detector]:
                sample_info = all_detector_data[detector][sample_id]
                total_disagree += sample_info["disagree_count"]
                if sample_info["total_judges"] > 0:
                    total_comparisons += 1

                    # Get verdict summary for this detector
                    verdicts = sample_info["verdicts"]
                    yes_count = sum(1 for v in verdicts.values() if v is True)
                    no_count = sum(1 for v in verdicts.values() if v is False)
                    detector_details.append(f"{yes_count}Y/{no_count}N")
                else:
                    detector_details.append("-")
            else:
                detector_details.append("-")

        # Calculate disagreement score (higher = more disagreement)
        # This is the total number of dissenting votes across all detectors
        disagree_score = total_disagree

        rows.append({
            "sample_id": sample_id,
            "disagree_score": disagree_score,
            "detectors_evaluated": total_comparisons,
            **{d: detector_details[i] for i, d in enumerate(DETECTORS)}
        })

    # Sort by disagreement score (highest first)
    rows.sort(key=lambda x: (-x["disagree_score"], x["sample_id"]))

    # Write CSV
    output_path = output_dir / f"_tier{tier}_aggregated.csv"
    with open(output_path, 'w', newline='') as f:
        fieldnames = ["sample_id", "disagree_score"] + DETECTORS
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "-") for k in fieldnames})

    print(f"\nAggregated: {output_path.name}")
    print(f"  Total samples: {len(rows)}")

    # Print top disagreements
    high_disagree = [r for r in rows if r["disagree_score"] > 0]
    if high_disagree:
        print(f"  Samples with disagreement: {len(high_disagree)}")
        print(f"  Top 5 most disagreed:")
        for r in high_disagree[:5]:
            print(f"    {r['sample_id']}: score={r['disagree_score']}")


def main():
    parser = argparse.ArgumentParser(description="Analyze LLM judge disagreement")
    parser.add_argument("--tier", "-t", type=int, default=1, help="Tier to analyze (1-4)")
    args = parser.parse_args()

    tier = args.tier

    # Create output directory
    output_dir = PROJECT_ROOT / f"interannotation_analysis/ds/disagreement/llms/tier{tier}"
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Analyzing judge disagreement for DS tier{tier}")
    print(f"Output: {output_dir}")
    print(f"Judges: {', '.join(JUDGES)}")
    print(f"Detectors: {', '.join(DETECTORS)}")
    print()

    # Process each detector
    all_detector_data = {}

    for detector in DETECTORS:
        print(f"Processing {detector}...")
        data = create_detector_table(detector, tier, output_dir)
        if data:
            all_detector_data[detector] = data

    # Create aggregated table
    if all_detector_data:
        create_aggregated_table(all_detector_data, tier, output_dir)
    else:
        print("No data found for any detector!")


if __name__ == "__main__":
    main()
