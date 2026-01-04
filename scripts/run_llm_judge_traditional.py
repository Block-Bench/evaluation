#!/usr/bin/env python3
"""
Run LLM Judge evaluation on traditional tool (Slither/Mythril) outputs.

General-purpose script supporting multiple judges:
- codestral (Vertex AI / Mistral)
- haiku (Vertex AI / Anthropic)
- gpt4o-mini (OpenRouter / OpenAI)

Computes aggregated metrics including:
- Target detection rates per vulnerability type
- True positives, false positives, precision
- Finding classification breakdown
"""

import argparse
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


def load_sample_data(sample_id: str, tool: str, tier: str):
    """Load detection result, ground truth, and contract code for a sample."""
    base = PROJECT_ROOT

    # Detection result (processed)
    detection_file = base / f"results/detection/traditional/{tool}/ds/{tier}/processed/p_{sample_id}.json"
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


def call_codestral(system_prompt: str, user_prompt: str) -> tuple[str, float]:
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

    start_time = time.time()
    response = requests.post(endpoint, headers=headers, json=payload, timeout=180)
    latency_ms = (time.time() - start_time) * 1000

    if response.status_code != 200:
        raise Exception(f"API call failed: {response.status_code} - {response.text[:200]}")

    data = response.json()
    return data["choices"][0]["message"]["content"], latency_ms


def call_haiku(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Claude Haiku via Vertex AI Anthropic."""
    from anthropic import AnthropicVertex

    client = AnthropicVertex(region="global")

    start_time = time.time()
    response = client.messages.create(
        model="claude-haiku-4-5@20251001",
        max_tokens=4096,
        system=system_prompt,
        messages=[{"role": "user", "content": user_prompt}]
    )
    latency_ms = (time.time() - start_time) * 1000

    return response.content[0].text, latency_ms


def call_gpt4o_mini(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call GPT-4o-mini via OpenRouter."""
    import requests

    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise ValueError("OPENROUTER_API_KEY environment variable not set")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "openai/gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.0,
        "max_tokens": 4096
    }

    start_time = time.time()
    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=headers,
        json=payload,
        timeout=180
    )
    latency_ms = (time.time() - start_time) * 1000

    if response.status_code != 200:
        raise Exception(f"API call failed: {response.status_code} - {response.text[:200]}")

    data = response.json()
    return data["choices"][0]["message"]["content"], latency_ms


def call_gemini(system_prompt: str, user_prompt: str) -> tuple[str, float]:
    """Call Gemini 2.5 Pro via Vertex AI using google-genai SDK."""
    from google import genai
    from google.genai import types

    project_id = os.getenv("VERTEX_PROJECT_ID", os.getenv("GOOGLE_CLOUD_PROJECT"))

    client = genai.Client(
        vertexai=True,
        project=project_id,
        location="global"
    )

    start_time = time.time()
    response = client.models.generate_content(
        model="gemini-2.5-pro",
        contents=[user_prompt],
        config=types.GenerateContentConfig(
            system_instruction=system_prompt,
            temperature=0.0,
            max_output_tokens=8192
        )
    )
    latency_ms = (time.time() - start_time) * 1000

    # Check for truncation
    if response.candidates and response.candidates[0].finish_reason.name == "MAX_TOKENS":
        raise Exception("Response truncated - MAX_TOKENS reached")

    return response.text, latency_ms


JUDGE_CALLERS = {
    "codestral": ("mistral", call_codestral),
    "haiku": ("anthropic", call_haiku),
    "gpt4o-mini": ("openai", call_gpt4o_mini),
    "gemini": ("google", call_gemini),
}


def parse_response(response: str) -> dict:
    """Parse JSON from LLM response."""
    json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
    if json_match:
        return json.loads(json_match.group(1))
    return json.loads(response)


def evaluate_sample(sample_id: str, tool: str, tier: str, judge: str) -> tuple[dict, str]:
    """Evaluate a single sample with specified LLM judge."""
    detection, ground_truth, code = load_sample_data(sample_id, tool, tier)

    system_prompt = get_traditional_tool_system_prompt()
    user_prompt = get_traditional_tool_user_prompt(
        detection_output=detection,
        ground_truth=ground_truth,
        code_snippet=code
    )

    family, caller = JUDGE_CALLERS[judge]
    response, latency_ms = caller(system_prompt, user_prompt)

    parsed = parse_response(response)

    result = {
        "sample_id": sample_id,
        "tool": tool,
        "judge_model": judge,
        "judge_family": family,
        "timestamp": datetime.now().isoformat(),
        "latency_ms": latency_ms,
        "ground_truth_type": ground_truth.get("vulnerability_type"),
        **parsed
    }

    return result, response


def run_evaluation(tool: str, tier: str, judge: str, force: bool = False):
    """Run LLM judge on all samples in a tier."""
    processed_dir = PROJECT_ROOT / f"results/detection/traditional/{tool}/ds/{tier}/processed"
    output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{tool}/ds/{tier}"
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "raw").mkdir(exist_ok=True)

    # Get all processed samples
    samples = sorted([f.stem[2:] for f in processed_dir.glob("p_*.json")])
    print(f"Found {len(samples)} samples to evaluate")

    results = []
    for i, sample_id in enumerate(samples):
        print(f"[{i+1}/{len(samples)}] {sample_id}...", end=" ", flush=True)

        output_file = output_dir / f"j_{sample_id}.json"

        # Check if already processed
        if output_file.exists() and not force:
            print("CACHED")
            with open(output_file) as f:
                results.append(json.load(f))
            continue

        try:
            result, raw_response = evaluate_sample(sample_id, tool, tier, judge)
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

    return results, output_dir


def compute_aggregated_metrics(results: list, tool: str, tier: str, judge: str) -> dict:
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

    # Recall = target_found_rate (at sample level, did we find the target?)
    recall = target_found_count / n if n > 0 else 0

    # Miss Rate = 1 - Recall
    miss_rate = 1 - recall

    # F1 Score = 2 * (Precision * Recall) / (Precision + Recall)
    f1_score = (2 * precision * recall) / (precision + recall) if (precision and recall and (precision + recall) > 0) else None

    # False Positive Rate = FP / Total Findings
    fp_rate = total_false_positives / total_findings if total_findings > 0 else 0

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

        # Compute all metrics for this vulnerability type
        type_recall = data["target_found_count"] / n_type if n_type > 0 else 0
        type_miss_rate = 1 - type_recall
        type_precision = tp / (tp + fp) if (tp + fp) > 0 else None
        type_fp_rate = fp / data["total_findings"] if data["total_findings"] > 0 else 0
        type_f1 = (2 * type_precision * type_recall) / (type_precision + type_recall) if (type_precision and type_recall and (type_precision + type_recall) > 0) else None

        by_vuln_type_summary[vtype] = {
            "total_samples": n_type,
            "target_found_count": data["target_found_count"],
            "target_found_rate": type_recall,
            "recall": type_recall,
            "miss_rate": type_miss_rate,
            "verdict_correct_count": data["verdict_correct_count"],
            "verdict_accuracy": data["verdict_correct_count"] / n_type if n_type > 0 else 0,
            "total_findings": data["total_findings"],
            "avg_findings_per_sample": data["total_findings"] / n_type if n_type > 0 else 0,
            "true_positives": tp,
            "false_positives": fp,
            "precision": type_precision,
            "fp_rate": type_fp_rate,
            "f1_score": type_f1,
            "classifications": dict(data["classifications"])
        }

    # Type match quality distribution
    type_match_counts = defaultdict(int)
    for r in successful:
        type_match = r.get("target_assessment", {}).get("type_match", "unknown")
        type_match_counts[type_match] += 1

    # Average latency
    latencies = [r.get("latency_ms", 0) for r in successful if r.get("latency_ms")]
    avg_latency = sum(latencies) / len(latencies) if latencies else 0

    aggregated = {
        "tool": tool,
        "tier": tier,
        "judge_model": judge,
        "judge_family": JUDGE_CALLERS[judge][0],
        "timestamp": datetime.now().isoformat(),
        "sample_counts": {
            "total": len(results),
            "successful_evaluations": n,
            "failed_evaluations": len(results) - n
        },
        "detection_metrics": {
            "target_found_count": target_found_count,
            "target_found_rate": target_found_count / n if n > 0 else 0,
            "recall": recall,
            "miss_rate": miss_rate,
            "verdict_correct_count": verdict_correct_count,
            "verdict_accuracy": verdict_correct_count / n if n > 0 else 0,
            "total_findings": total_findings,
            "avg_findings_per_sample": total_findings / n if n > 0 else 0,
            "true_positives": total_true_positives,
            "false_positives": total_false_positives,
            "precision": precision,
            "fp_rate": fp_rate,
            "f1_score": f1_score
        },
        "classification_totals": dict(classification_totals),
        "type_match_distribution": dict(type_match_counts),
        "by_vulnerability_type": by_vuln_type_summary,
        "performance": {
            "avg_latency_ms": avg_latency
        }
    }

    return aggregated


def print_summary(aggregated: dict):
    """Print formatted summary to console."""
    print("\n" + "=" * 60)
    print(f"SUMMARY: {aggregated['tool']} / {aggregated['tier']} / {aggregated['judge_model']}")
    print("=" * 60)

    dm = aggregated["detection_metrics"]
    sc = aggregated["sample_counts"]

    print(f"\nOverall Metrics:")
    print(f"  Samples evaluated: {sc['successful_evaluations']}/{sc['total']}")
    print(f"  Recall (target found rate): {dm['recall']:.1%} ({dm['target_found_count']}/{sc['successful_evaluations']})")
    print(f"  Miss rate:         {dm['miss_rate']:.1%}")
    print(f"  Verdict accuracy:  {dm['verdict_accuracy']:.1%}")
    print(f"  Total findings:    {dm['total_findings']}")
    print(f"  True positives:    {dm['true_positives']}")
    print(f"  False positives:   {dm['false_positives']}")
    if dm['precision'] is not None:
        print(f"  Precision:         {dm['precision']:.1%}")
    print(f"  FP rate:           {dm['fp_rate']:.1%}")
    if dm['f1_score'] is not None:
        print(f"  F1 Score:          {dm['f1_score']:.3f}")
    print(f"  Avg latency:       {aggregated['performance']['avg_latency_ms']:.0f}ms")

    print(f"\nClassification Breakdown:")
    for key, count in sorted(aggregated["classification_totals"].items()):
        if count > 0:
            print(f"  {key}: {count}")

    print(f"\nType Match Distribution:")
    for key, count in sorted(aggregated["type_match_distribution"].items()):
        print(f"  {key}: {count}")

    print(f"\nBy Vulnerability Type:")
    for vtype, data in sorted(aggregated["by_vulnerability_type"].items()):
        print(f"\n  {vtype}:")
        print(f"    Samples: {data['total_samples']}")
        print(f"    Recall: {data['recall']:.1%} ({data['target_found_count']}/{data['total_samples']})")
        print(f"    Miss rate: {data['miss_rate']:.1%}")
        if data['precision'] is not None:
            print(f"    Precision: {data['precision']:.1%}")
        if data['total_findings'] > 0:
            print(f"    FP rate: {data['fp_rate']:.1%}")
        if data['f1_score'] is not None:
            print(f"    F1 Score: {data['f1_score']:.3f}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Run LLM Judge evaluation on traditional tool outputs"
    )
    parser.add_argument(
        "--tool",
        choices=["slither", "mythril"],
        default="slither",
        help="Traditional tool to evaluate (default: slither)"
    )
    parser.add_argument(
        "--tier",
        default="tier1",
        help="Tier to evaluate (default: tier1)"
    )
    parser.add_argument(
        "--judge",
        choices=["codestral", "haiku", "gpt4o-mini", "gemini"],
        default="codestral",
        help="LLM judge to use (default: codestral)"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-evaluation of all samples (ignore cache)"
    )
    parser.add_argument(
        "--metrics-only",
        action="store_true",
        help="Only compute metrics from cached results (no API calls)"
    )

    args = parser.parse_args()

    output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{args.judge}/{args.tool}/ds/{args.tier}"

    if args.metrics_only:
        # Load cached results only - no API calls
        print("=" * 60)
        print(f"Computing metrics from cached {args.judge} results for {args.tool} / {args.tier}")
        print("=" * 60)

        results = []
        cached_files = sorted(output_dir.glob("j_*.json"))
        print(f"Found {len(cached_files)} cached evaluations")

        for f in cached_files:
            with open(f) as fp:
                results.append(json.load(fp))
    else:
        print("=" * 60)
        print(f"Running {args.judge} LLM Judge on {args.tool} / {args.tier}")
        print("=" * 60)

        results, output_dir = run_evaluation(
            tool=args.tool,
            tier=args.tier,
            judge=args.judge,
            force=args.force
        )

    print("\n" + "=" * 60)
    print("Computing Aggregated Metrics")
    print("=" * 60)

    aggregated = compute_aggregated_metrics(results, args.tool, args.tier, args.judge)

    # Save aggregated metrics
    summary_file = output_dir / "_tier_summary.json"
    with open(summary_file, 'w') as f:
        json.dump(aggregated, f, indent=2)
    print(f"\nSaved summary to: {summary_file}")

    print_summary(aggregated)


if __name__ == "__main__":
    main()
