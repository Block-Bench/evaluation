#!/usr/bin/env python3
"""
LLM Detection Runner for DS (Difficulty-Stratified) dataset.

Runs vulnerability detection on smart contract samples using LLM models
and saves results in the expected schema format.
"""

import argparse
import asyncio
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from src.detection.llm.model_config import get_client, load_model_config
from src.detection.llm.prompts.ds.direct import DSDirectPromptBuilder


def parse_json_response(raw_response: str) -> tuple[dict | None, list[str]]:
    """
    Parse JSON from LLM response.

    Returns:
        (parsed_dict, errors) - parsed dict or None, list of parsing errors
    """
    errors = []

    # Try to find JSON in code block
    json_match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw_response, re.DOTALL)
    if json_match:
        json_str = json_match.group(1).strip()
    else:
        # Try the whole response as JSON
        json_str = raw_response.strip()

    try:
        parsed = json.loads(json_str)
        return parsed, errors
    except json.JSONDecodeError as e:
        errors.append(f"JSON parse error: {e}")

        # Try to fix common issues
        # Remove trailing commas
        fixed = re.sub(r',\s*([}\]])', r'\1', json_str)
        try:
            parsed = json.loads(fixed)
            errors.append("Fixed trailing comma")
            return parsed, errors
        except json.JSONDecodeError:
            pass

    return None, errors


def load_sample(sample_id: str, tier: int) -> tuple[str, dict]:
    """Load contract code and ground truth for a sample."""
    samples_dir = PROJECT_ROOT / "samples" / "ds" / f"tier{tier}"

    contract_path = samples_dir / "contracts" / f"{sample_id}.sol"
    gt_path = samples_dir / "ground_truth" / f"{sample_id}.json"

    if not contract_path.exists():
        raise FileNotFoundError(f"Contract not found: {contract_path}")
    if not gt_path.exists():
        raise FileNotFoundError(f"Ground truth not found: {gt_path}")

    code = contract_path.read_text()
    ground_truth = json.loads(gt_path.read_text())

    return code, ground_truth


async def run_detection(
    model_name: str,
    sample_id: str,
    tier: int,
    output_dir: Path,
    verbose: bool = False
) -> dict:
    """
    Run detection on a single sample.

    Returns:
        Detection output conforming to llm_detection_output.schema.json
    """
    # Load sample
    code, ground_truth = load_sample(sample_id, tier)

    if verbose:
        print(f"Loaded sample: {sample_id} ({len(code)} chars)")
        print(f"Ground truth: {ground_truth['vulnerability_type']} in {ground_truth['vulnerable_functions']}")

    # Load model config and create client
    config_dir = PROJECT_ROOT / "config" / "models"
    config = load_model_config(config_dir / f"{model_name}.yaml")
    client = get_client(model_name, config_dir)

    if verbose:
        print(f"Using model: {config.name} ({config.model_id})")

    # Build prompt
    prompt_builder = DSDirectPromptBuilder()
    prompt_pair = prompt_builder.build(code=code, language="solidity")

    if verbose:
        print(f"System prompt: {len(prompt_pair.system_prompt)} chars")
        print(f"User prompt: {len(prompt_pair.user_prompt)} chars")

    # Call the model
    timestamp = datetime.now(timezone.utc).isoformat()

    try:
        response = await client.generate(
            system_prompt=prompt_pair.system_prompt,
            user_prompt=prompt_pair.user_prompt,
            temperature=config.temperature,
            max_tokens=config.max_tokens
        )

        if verbose:
            print(f"Response received: {response.input_tokens} in, {response.output_tokens} out, {response.latency_ms:.0f}ms")

        # Parse the response
        prediction, parse_errors = parse_json_response(response.content)

        result = {
            "sample_id": sample_id,
            "tier": tier,
            "model": model_name,
            "prompt_type": "direct",
            "timestamp": timestamp,
            "ground_truth": {
                "is_vulnerable": ground_truth["is_vulnerable"],
                "vulnerability_type": ground_truth["vulnerability_type"],
                "vulnerable_functions": ground_truth["vulnerable_functions"],
                "severity": ground_truth["severity"]
            },
            "prediction": prediction,
            "parsing": {
                "success": prediction is not None,
                "errors": parse_errors,
                "raw_response": response.content
            },
            "api_metrics": {
                "input_tokens": response.input_tokens,
                "output_tokens": response.output_tokens,
                "latency_ms": response.latency_ms,
                "cost_usd": response.cost_usd
            },
            "error": None
        }

    except Exception as e:
        result = {
            "sample_id": sample_id,
            "tier": tier,
            "model": model_name,
            "prompt_type": "direct",
            "timestamp": timestamp,
            "ground_truth": {
                "is_vulnerable": ground_truth["is_vulnerable"],
                "vulnerability_type": ground_truth["vulnerability_type"],
                "vulnerable_functions": ground_truth["vulnerable_functions"],
                "severity": ground_truth["severity"]
            },
            "prediction": None,
            "parsing": {
                "success": False,
                "errors": [str(e)],
                "raw_response": ""
            },
            "api_metrics": None,
            "error": str(e)
        }

        if verbose:
            print(f"Error: {e}")

    # Save result
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"d_{sample_id}.json"

    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    if verbose:
        print(f"Saved: {output_path}")

    return result


async def run_tier(
    model_name: str,
    tier: int,
    output_dir: Path,
    limit: int | None = None,
    verbose: bool = False
) -> list[dict]:
    """Run detection on all samples in a tier."""
    samples_dir = PROJECT_ROOT / "samples" / "ds" / f"tier{tier}" / "contracts"

    sample_files = sorted(samples_dir.glob("*.sol"))
    if limit:
        sample_files = sample_files[:limit]

    print(f"Running {model_name} on {len(sample_files)} samples from tier {tier}")

    results = []
    for i, sample_file in enumerate(sample_files, 1):
        sample_id = sample_file.stem
        print(f"[{i}/{len(sample_files)}] {sample_id}...", end=" ", flush=True)

        result = await run_detection(
            model_name=model_name,
            sample_id=sample_id,
            tier=tier,
            output_dir=output_dir,
            verbose=False
        )

        # Print quick summary
        if result["prediction"]:
            verdict = result["prediction"].get("verdict", "?")
            vulns = len(result["prediction"].get("vulnerabilities", []))
            print(f"verdict={verdict}, findings={vulns}")
        else:
            print(f"ERROR: {result.get('error', 'parse failed')[:50]}")

        results.append(result)

    return results


def main():
    parser = argparse.ArgumentParser(description="Run LLM vulnerability detection on DS samples")
    parser.add_argument("--model", "-m", required=True, help="Model name (e.g., deepseek-v3-2)")
    parser.add_argument("--tier", "-t", type=int, default=1, help="Difficulty tier (1-4)")
    parser.add_argument("--sample", "-s", help="Specific sample ID (e.g., ds_t1_001)")
    parser.add_argument("--limit", "-l", type=int, help="Limit number of samples")
    parser.add_argument("--output", "-o", help="Output directory (default: results/detection/llm/<model>/ds/tier<N>)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # Set output directory
    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = PROJECT_ROOT / "results" / "detection" / "llm" / args.model / "ds" / f"tier{args.tier}"

    if args.sample:
        # Run single sample
        result = asyncio.run(run_detection(
            model_name=args.model,
            sample_id=args.sample,
            tier=args.tier,
            output_dir=output_dir,
            verbose=args.verbose
        ))

        print("\n=== Result ===")
        if result["prediction"]:
            print(f"Verdict: {result['prediction'].get('verdict')}")
            print(f"Confidence: {result['prediction'].get('confidence')}")
            print(f"Vulnerabilities: {len(result['prediction'].get('vulnerabilities', []))}")
            for v in result['prediction'].get('vulnerabilities', []):
                print(f"  - {v.get('type')}: {v.get('location')} ({v.get('severity')})")
        else:
            print(f"Error: {result.get('error')}")

        print(f"\nGround Truth: {result['ground_truth']['vulnerability_type']} in {result['ground_truth']['vulnerable_functions']}")

        if result["api_metrics"]:
            print(f"\nAPI Metrics: {result['api_metrics']['input_tokens']} in, {result['api_metrics']['output_tokens']} out")
            print(f"Latency: {result['api_metrics']['latency_ms']:.0f}ms, Cost: ${result['api_metrics']['cost_usd']:.4f}")
    else:
        # Run entire tier
        results = asyncio.run(run_tier(
            model_name=args.model,
            tier=args.tier,
            output_dir=output_dir,
            limit=args.limit,
            verbose=args.verbose
        ))

        # Print summary
        successful = [r for r in results if r["prediction"]]
        correct_verdict = [r for r in successful if r["prediction"].get("verdict") == "vulnerable"]

        print(f"\n=== Summary ===")
        print(f"Total samples: {len(results)}")
        print(f"Successful parses: {len(successful)}")
        print(f"Correct verdict (vulnerable): {len(correct_verdict)}/{len(successful)}")

        if successful:
            total_cost = sum(r["api_metrics"]["cost_usd"] for r in successful if r["api_metrics"])
            avg_latency = sum(r["api_metrics"]["latency_ms"] for r in successful if r["api_metrics"]) / len(successful)
            print(f"Total cost: ${total_cost:.4f}")
            print(f"Avg latency: {avg_latency:.0f}ms")


if __name__ == "__main__":
    main()
