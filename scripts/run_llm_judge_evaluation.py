#!/usr/bin/env python3
"""
Run LLM Judge evaluation on traditional tool detection results.

Uses 3 judges (Haiku, GPT-4o-mini, Codestral) with majority voting.
"""

import asyncio
import json
import sys
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from evaluation.llm_judge import MultiJudgeOrchestrator, save_multi_judge_result
from utils.config import get_config, JudgeModelConfig


def load_detection_results(tool: str, tier: str) -> list[dict]:
    """Load detection results for a tool and tier."""
    config = get_config()
    results_dir = config.paths.detection_results / "traditional" / tool / "ds" / tier

    results = []
    for f in sorted(results_dir.glob("d_*.json")):
        with open(f) as fp:
            results.append(json.load(fp))

    return results


def load_ground_truths(tier: str) -> dict:
    """Load ground truth files for a tier, indexed by sample_id."""
    config = get_config()
    gt_dir = config.paths.ds_samples / tier / "ground_truth"

    ground_truths = {}
    for f in gt_dir.glob("*.json"):
        sample_id = f.stem
        with open(f) as fp:
            ground_truths[sample_id] = json.load(fp)

    return ground_truths


def load_contract_code(sample_id: str, tier: str) -> str:
    """Load contract source code."""
    config = get_config()
    contract_file = config.paths.ds_samples / tier / "contracts" / f"{sample_id}.sol"

    if contract_file.exists():
        return contract_file.read_text()
    return ""


async def run_evaluation(
    tool: str,
    tier: str,
    output_dir: Path,
    max_samples: int = None
):
    """
    Run multi-judge evaluation on a tool's detection results.

    Args:
        tool: Tool name (slither, mythril)
        tier: Tier name (tier1, tier2, etc.)
        output_dir: Directory to save results
        max_samples: Maximum samples to process (for testing)
    """
    print(f"\n{'='*60}")
    print(f"Running LLM Judge Evaluation")
    print(f"Tool: {tool}, Tier: {tier}")
    print(f"{'='*60}\n")

    # Load data
    print("Loading detection results...")
    detection_results = load_detection_results(tool, tier)
    print(f"  Found {len(detection_results)} detection results")

    print("Loading ground truths...")
    ground_truths = load_ground_truths(tier)
    print(f"  Found {len(ground_truths)} ground truth files")

    # Limit samples if specified
    if max_samples:
        detection_results = detection_results[:max_samples]
        print(f"  Limited to {max_samples} samples for testing")

    # Initialize orchestrator with judge configs
    config = get_config()
    print("\nInitializing judges:")
    for jc in config.evaluation.judge_models:
        print(f"  - {jc.name} ({jc.provider}/{jc.model_id})")

    orchestrator = MultiJudgeOrchestrator(config.evaluation.judge_models)

    # Process each sample
    output_dir = output_dir / tool / "ds" / tier
    output_dir.mkdir(parents=True, exist_ok=True)

    results = []
    success_count = 0
    error_count = 0

    for i, detection in enumerate(detection_results):
        sample_id = detection.get("sample_id", f"unknown_{i}")
        print(f"\n[{i+1}/{len(detection_results)}] {sample_id}")

        # Skip if already processed
        output_file = output_dir / f"mj_{sample_id}.json"
        if output_file.exists():
            print("  Skipping (already processed)")
            continue

        # Get ground truth
        gt = ground_truths.get(sample_id)
        if not gt:
            print(f"  WARNING: No ground truth found, skipping")
            error_count += 1
            continue

        # Load contract code
        code = load_contract_code(sample_id, tier)

        # Run evaluation
        try:
            result = await orchestrator.evaluate_sample(
                detection_output=detection,
                ground_truth=gt,
                code_snippet=code,
                is_traditional_tool=True
            )

            # Save result
            save_multi_judge_result(result, output_dir)
            results.append(result)
            success_count += 1

            # Print summary
            print(f"  Target found: {result.majority_target_found} "
                  f"(agreement: {result.target_found_agreement:.0%})")
            print(f"  Verdict correct: {result.majority_verdict_correct}")

        except Exception as e:
            print(f"  ERROR: {e}")
            error_count += 1

    # Generate summary
    print(f"\n{'='*60}")
    print("Evaluation Complete")
    print(f"{'='*60}")
    print(f"Processed: {success_count}")
    print(f"Errors: {error_count}")

    if results:
        # Calculate aggregate metrics
        target_found_rate = sum(1 for r in results if r.majority_target_found) / len(results)
        verdict_accuracy = sum(1 for r in results if r.majority_verdict_correct) / len(results)
        avg_agreement = sum(r.target_found_agreement for r in results) / len(results)
        full_agreement_rate = sum(1 for r in results if r.full_agreement) / len(results)

        print(f"\nAggregate Metrics (Majority Vote):")
        print(f"  Target Found Rate: {target_found_rate:.1%}")
        print(f"  Verdict Accuracy: {verdict_accuracy:.1%}")
        print(f"  Avg Agreement: {avg_agreement:.1%}")
        print(f"  Full Agreement Rate: {full_agreement_rate:.1%}")

        # Save summary
        summary = {
            "tool": tool,
            "tier": tier,
            "total_samples": len(results),
            "target_found_rate": target_found_rate,
            "verdict_accuracy": verdict_accuracy,
            "avg_agreement": avg_agreement,
            "full_agreement_rate": full_agreement_rate,
            "judges": [jc.name for jc in config.evaluation.judge_models]
        }

        summary_file = output_dir / "_tier_summary.json"
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        print(f"\nSummary saved to: {summary_file}")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Run LLM Judge evaluation on traditional tool results"
    )
    parser.add_argument(
        "--tool",
        choices=["slither", "mythril"],
        required=True,
        help="Tool to evaluate"
    )
    parser.add_argument(
        "--tier",
        default="tier1",
        help="Tier to evaluate (default: tier1)"
    )
    parser.add_argument(
        "--max-samples",
        type=int,
        default=None,
        help="Maximum samples to process (for testing)"
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Output directory (default: results/detection_evaluation/llm-judge/traditional)"
    )

    args = parser.parse_args()

    # Default output directory
    if args.output_dir is None:
        config = get_config()
        args.output_dir = config.paths.evaluation_results / "llm-judge" / "traditional"

    # Run evaluation
    asyncio.run(run_evaluation(
        tool=args.tool,
        tier=args.tier,
        output_dir=args.output_dir,
        max_samples=args.max_samples
    ))


if __name__ == "__main__":
    main()
