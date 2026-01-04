#!/usr/bin/env python3
"""
Run Codestral LLM Judge on all DS tier1 Slither processed outputs.

Computes aggregated metrics including:
- Target detection rates per vulnerability type
- True positives, false positives, precision
- Finding classification breakdown
"""

import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from collections import defaultdict

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from evaluation.llm_judge.prompts import (
    get_traditional_tool_system_prompt,
    get_traditional_tool_user_prompt
)


def load_sample_data(sample_id: str, tier: str = "tier1"):
    """Load detection result, ground truth, and contract code for a sample."""
    base = PROJECT_ROOT

    # Detection result (processed)
    detection_file = base / f"results/detection/traditional/slither/ds/{tier}/processed/p_{sample_id}.json"
    with open(detection_file) as f:
        detection = json.load(f)

    # Ground truth
    gt_file = base / f"samples/ds/{tier}/ground_truth/{sample_id}.json"
    with open(gt_file) as f:
        ground_truth = json.load(f)

    # Contract code
    contract_file = base / f"samples/ds/{tier}/contracts/{sample_id}.sol"
    with open(contract_file) as f:
        code = f.read()

    return detection, ground_truth, code


def call_codestral(system_prompt: str, user_prompt: str) -> str:
    """Call Codestral via Vertex AI rawPredict endpoint."""
    from google.auth import default
    from google.auth.transport.requests import Request
    import requests

    credentials, project = default()
    credentials.refresh(Request())

    project_id = os.getenv("VERTEX_PROJECT_ID", project)
    location = "europe-west4"
    model = "codestral-2"

    endpoint = f"https://{location}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{location}/publishers/mistralai/models/{model}:rawPredict"

    headers = {
        "Authorization": f"Bearer {credentials.token}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.0,
        "max_tokens": 4096
    }

    response = requests.post(endpoint, headers=headers, json=payload, timeout=120)

    if response.status_code != 200:
        raise Exception(f"API call failed: {response.status_code} - {response.text[:200]}")

    data = response.json()
    return data["choices"][0]["message"]["content"]


def parse_response(response: str) -> dict:
    """Parse JSON from Codestral response."""
    json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
    if json_match:
        return json.loads(json_match.group(1))
    return json.loads(response)


def evaluate_sample(sample_id: str, tier: str = "tier1") -> dict:
    """Evaluate a single sample with Codestral."""
    detection, ground_truth, code = load_sample_data(sample_id, tier)

    system_prompt = get_traditional_tool_system_prompt()
    user_prompt = get_traditional_tool_user_prompt(
        detection_output=detection,
        ground_truth=ground_truth,
        code_snippet=code
    )

    start_time = time.time()
    response = call_codestral(system_prompt, user_prompt)
    latency_ms = (time.time() - start_time) * 1000

    parsed = parse_response(response)

    result = {
        "sample_id": sample_id,
        "tool": "slither",
        "judge_model": "codestral",
        "judge_family": "mistral",
        "timestamp": datetime.now().isoformat(),
        "latency_ms": latency_ms,
        "ground_truth_type": ground_truth.get("vulnerability_type"),
        **parsed
    }

    return result, response


def run_all_tier1():
    """Run Codestral on all tier1 samples."""
    tier = "tier1"
    processed_dir = PROJECT_ROOT / f"results/detection/traditional/slither/ds/{tier}/processed"
    output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/codestral/ds/{tier}"
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "raw").mkdir(exist_ok=True)

    # Get all processed samples
    samples = sorted([f.stem[2:] for f in processed_dir.glob("p_*.json")])
    print(f"Found {len(samples)} samples to evaluate")

    results = []
    for i, sample_id in enumerate(samples):
        print(f"[{i+1}/{len(samples)}] {sample_id}...", end=" ", flush=True)

        # Check if already processed
        output_file = output_dir / f"j_{sample_id}.json"
        if output_file.exists():
            print("CACHED")
            with open(output_file) as f:
                results.append(json.load(f))
            continue

        try:
            result, raw_response = evaluate_sample(sample_id, tier)
            results.append(result)

            # Save individual result
            with open(output_file, 'w') as f:
                json.dump(result, f, indent=2)

            # Save raw response
            raw_file = output_dir / "raw" / f"raw_{sample_id}.txt"
            with open(raw_file, 'w') as f:
                f.write(raw_response)

            target_found = result.get("target_assessment", {}).get("found", False)
            print(f"OK (target={'FOUND' if target_found else 'NOT FOUND'}, {result['latency_ms']:.0f}ms)")

        except Exception as e:
            print(f"ERROR: {e}")
            results.append({
                "sample_id": sample_id,
                "error": str(e),
                "ground_truth_type": None
            })

        # Small delay to avoid rate limiting
        time.sleep(0.5)

    return results


def compute_aggregated_metrics(results: list) -> dict:
    """Compute aggregated metrics from all results."""
    # Filter successful results
    successful = [r for r in results if "error" not in r]
    n = len(successful)

    if n == 0:
        return {"error": "No successful evaluations"}

    # Overall metrics
    target_found_count = sum(
        1 for r in successful
        if r.get("target_assessment", {}).get("found", False)
    )

    verdict_correct_count = sum(
        1 for r in successful
        if r.get("overall_verdict", {}).get("verdict_correct", False)
    )

    # Classification counts across all findings
    classification_totals = defaultdict(int)
    total_findings = 0
    total_true_positives = 0
    total_false_positives = 0

    for r in successful:
        summary = r.get("summary", {})
        total_findings += summary.get("total_findings", 0)

        # True positives = TARGET_MATCH + PARTIAL_MATCH + BONUS_VALID
        tp = (summary.get("target_matches", 0) +
              summary.get("partial_matches", 0) +
              summary.get("bonus_valid", 0))
        total_true_positives += tp

        # False positives = INVALID + MISCHARACTERIZED + SECURITY_THEATER
        fp = (summary.get("invalid", 0) +
              summary.get("mischaracterized", 0) +
              summary.get("security_theater", 0))
        total_false_positives += fp

        # Track all classification types
        for key in ["target_matches", "partial_matches", "bonus_valid",
                    "invalid", "mischaracterized", "design_choice",
                    "out_of_scope", "security_theater", "informational"]:
            classification_totals[key] += summary.get(key, 0)

    # Precision = TP / (TP + FP)
    precision = total_true_positives / (total_true_positives + total_false_positives) if (total_true_positives + total_false_positives) > 0 else None

    # By vulnerability type
    by_vuln_type = defaultdict(lambda: {
        "total_samples": 0,
        "target_found_count": 0,
        "verdict_correct_count": 0,
        "total_findings": 0,
        "true_positives": 0,
        "false_positives": 0,
        "classifications": defaultdict(int)
    })

    for r in successful:
        vtype = r.get("ground_truth_type", "unknown")
        by_vuln_type[vtype]["total_samples"] += 1

        if r.get("target_assessment", {}).get("found", False):
            by_vuln_type[vtype]["target_found_count"] += 1

        if r.get("overall_verdict", {}).get("verdict_correct", False):
            by_vuln_type[vtype]["verdict_correct_count"] += 1

        summary = r.get("summary", {})
        by_vuln_type[vtype]["total_findings"] += summary.get("total_findings", 0)

        tp = (summary.get("target_matches", 0) +
              summary.get("partial_matches", 0) +
              summary.get("bonus_valid", 0))
        by_vuln_type[vtype]["true_positives"] += tp

        fp = (summary.get("invalid", 0) +
              summary.get("mischaracterized", 0) +
              summary.get("security_theater", 0))
        by_vuln_type[vtype]["false_positives"] += fp

        for key in ["target_matches", "partial_matches", "bonus_valid",
                    "invalid", "mischaracterized", "design_choice",
                    "out_of_scope", "security_theater", "informational"]:
            by_vuln_type[vtype]["classifications"][key] += summary.get(key, 0)

    # Compute rates per vulnerability type
    by_vuln_type_summary = {}
    for vtype, data in by_vuln_type.items():
        n_type = data["total_samples"]
        tp = data["true_positives"]
        fp = data["false_positives"]

        by_vuln_type_summary[vtype] = {
            "total_samples": n_type,
            "target_found_count": data["target_found_count"],
            "target_found_rate": data["target_found_count"] / n_type if n_type > 0 else 0,
            "verdict_correct_count": data["verdict_correct_count"],
            "verdict_accuracy": data["verdict_correct_count"] / n_type if n_type > 0 else 0,
            "total_findings": data["total_findings"],
            "avg_findings_per_sample": data["total_findings"] / n_type if n_type > 0 else 0,
            "true_positives": tp,
            "false_positives": fp,
            "precision": tp / (tp + fp) if (tp + fp) > 0 else None,
            "classifications": dict(data["classifications"])
        }

    # Type match quality distribution
    type_match_counts = defaultdict(int)
    for r in successful:
        type_match = r.get("target_assessment", {}).get("type_match", "unknown")
        type_match_counts[type_match] += 1

    aggregated = {
        "tool": "slither",
        "tier": "tier1",
        "judge_model": "codestral",
        "timestamp": datetime.now().isoformat(),
        "sample_counts": {
            "total": len(results),
            "successful_evaluations": n,
            "failed_evaluations": len(results) - n
        },
        "detection_metrics": {
            "target_found_count": target_found_count,
            "target_found_rate": target_found_count / n if n > 0 else 0,
            "verdict_correct_count": verdict_correct_count,
            "verdict_accuracy": verdict_correct_count / n if n > 0 else 0,
            "total_findings": total_findings,
            "avg_findings_per_sample": total_findings / n if n > 0 else 0,
            "true_positives": total_true_positives,
            "false_positives": total_false_positives,
            "precision": precision
        },
        "classification_totals": dict(classification_totals),
        "type_match_distribution": dict(type_match_counts),
        "by_vulnerability_type": by_vuln_type_summary
    }

    return aggregated


def main():
    """Main entry point."""
    print("=" * 60)
    print("Running Codestral LLM Judge on DS Tier1 Slither Outputs")
    print("=" * 60)

    results = run_all_tier1()

    print("\n" + "=" * 60)
    print("Computing Aggregated Metrics")
    print("=" * 60)

    aggregated = compute_aggregated_metrics(results)

    # Save aggregated metrics
    output_dir = PROJECT_ROOT / "results/detection_evaluation/llm-judge/codestral/ds/tier1"
    summary_file = output_dir / "_tier_summary.json"
    with open(summary_file, 'w') as f:
        json.dump(aggregated, f, indent=2)
    print(f"\nSaved summary to: {summary_file}")

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    dm = aggregated["detection_metrics"]
    print(f"\nOverall Metrics:")
    print(f"  Samples evaluated: {aggregated['sample_counts']['successful_evaluations']}/{aggregated['sample_counts']['total']}")
    print(f"  Target found rate: {dm['target_found_rate']:.1%} ({dm['target_found_count']}/{aggregated['sample_counts']['successful_evaluations']})")
    print(f"  Verdict accuracy:  {dm['verdict_accuracy']:.1%}")
    print(f"  Total findings:    {dm['total_findings']}")
    print(f"  True positives:    {dm['true_positives']}")
    print(f"  False positives:   {dm['false_positives']}")
    print(f"  Precision:         {dm['precision']:.1%}" if dm['precision'] else "  Precision:         N/A")

    print(f"\nClassification Breakdown:")
    for key, count in sorted(aggregated["classification_totals"].items()):
        print(f"  {key}: {count}")

    print(f"\nType Match Distribution:")
    for key, count in sorted(aggregated["type_match_distribution"].items()):
        print(f"  {key}: {count}")

    print(f"\nBy Vulnerability Type:")
    for vtype, data in sorted(aggregated["by_vulnerability_type"].items()):
        print(f"\n  {vtype}:")
        print(f"    Samples: {data['total_samples']}")
        print(f"    Target found: {data['target_found_rate']:.1%} ({data['target_found_count']}/{data['total_samples']})")
        print(f"    Precision: {data['precision']:.1%}" if data['precision'] else "    Precision: N/A")


if __name__ == "__main__":
    main()
