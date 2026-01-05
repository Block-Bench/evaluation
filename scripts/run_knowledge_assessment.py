#!/usr/bin/env python3
"""Run knowledge assessment probes on all detectors for TC and GS datasets."""

import json
import argparse
import asyncio
import time
from pathlib import Path
from datetime import datetime, timezone
import sys

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from dotenv import load_dotenv
load_dotenv(PROJECT_ROOT / '.env')

from src.detection.llm.model_config import get_client, load_model_config

DETECTORS = [
    "claude-opus-4-5",
    "deepseek-v3-2",
    "gemini-3-pro",
    "gpt-5.2",
    "grok-4-fast",
    "llama-4-maverick",
    "qwen3-coder-plus"
]

# Knowledge assessment paths (input)
TC_KNOWLEDGE_DIR = PROJECT_ROOT / "samples/tc/minimalsanitized/knowledge_assessment"
GS_KNOWLEDGE_DIR = PROJECT_ROOT / "samples/gs/knowledge_assessment"

# Output paths - same structure as detection: results/detection/llm/{model}/{dataset}/knowledge_assessment/
OUTPUT_BASE = PROJECT_ROOT / "results/detection/llm"


def load_knowledge_probes(dataset: str) -> list[dict]:
    """Load all knowledge probe files for a dataset."""
    if dataset == "tc":
        probe_dir = TC_KNOWLEDGE_DIR
        pattern = "ms_tc_*_knowledge_probe.json"
    else:  # gs
        probe_dir = GS_KNOWLEDGE_DIR
        pattern = "gs_*_knowledge_probe.json"

    probes = []
    for f in sorted(probe_dir.glob(pattern)):
        with open(f) as fp:
            probes.append(json.load(fp))
    return probes


async def run_assessment(model: str, prompt: str) -> tuple[str, float]:
    """Send prompt to model and get response."""
    config = load_model_config(PROJECT_ROOT / f'config/models/{model}.yaml')
    client = get_client(model)

    system_prompt = "You are a knowledgeable assistant being assessed on your knowledge of blockchain security. Answer honestly - if you don't know something, say so."

    start = time.time()
    response = await client.generate(
        system_prompt=system_prompt,
        user_prompt=prompt,
        max_tokens=config.max_tokens,
        temperature=0.0
    )
    latency = (time.time() - start) * 1000

    return response.content, latency


async def assess_sample(model: str, probe: dict, dataset: str, verbose: bool = False) -> dict:
    """Run knowledge assessment for a single sample."""
    sample_id = probe["sample_id"]
    prompt = probe["prompt"]

    if verbose:
        print(f"  Assessing {sample_id}...", end=" ", flush=True)

    try:
        response, latency = await run_assessment(model, prompt)

        # Simple heuristic to classify response
        response_lower = response.lower()
        if "not familiar" in response_lower or "don't have" in response_lower or "no knowledge" in response_lower:
            knowledge_status = "unfamiliar"
        elif any(word in response_lower for word in ["yes", "i am familiar", "i know", "this incident", "this vulnerability"]):
            knowledge_status = "familiar"
        else:
            knowledge_status = "unclear"

        result = {
            "sample_id": sample_id,
            "model": model,
            "dataset": dataset,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "prompt": prompt,
            "response": response,
            "knowledge_status": knowledge_status,
            "latency_ms": latency,
            "expected_answers": probe.get("expected_answers", {}),
            "error": None
        }

        if verbose:
            print(f"{knowledge_status}")

    except Exception as e:
        result = {
            "sample_id": sample_id,
            "model": model,
            "dataset": dataset,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "prompt": prompt,
            "response": None,
            "knowledge_status": "error",
            "latency_ms": None,
            "error": str(e)
        }
        if verbose:
            print(f"ERROR: {e}")

    return result


async def main():
    parser = argparse.ArgumentParser(description="Run knowledge assessment probes")
    parser.add_argument("--model", choices=DETECTORS + ["all"], default="all",
                       help="Model to assess")
    parser.add_argument("--dataset", choices=["tc", "gs", "all"], default="all",
                       help="Dataset to use")
    parser.add_argument("--sample", type=str, default=None,
                       help="Specific sample ID to assess")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--force", action="store_true",
                       help="Overwrite existing results")
    args = parser.parse_args()

    models = DETECTORS if args.model == "all" else [args.model]
    datasets = ["tc", "gs"] if args.dataset == "all" else [args.dataset]

    for dataset in datasets:
        probes = load_knowledge_probes(dataset)
        print(f"Loaded {len(probes)} {dataset.upper()} knowledge probes")

        if args.sample:
            probes = [p for p in probes if p["sample_id"] == args.sample]
            if not probes:
                print(f"Sample {args.sample} not found in {dataset}")
                continue

        for model in models:
            # Output structure: results/detection/llm/{model}/{dataset}/knowledge_assessment/
            model_dir = OUTPUT_BASE / model / dataset / "knowledge_assessment"
            model_dir.mkdir(parents=True, exist_ok=True)

            # Check existing
            existing = set(f.stem.replace("ka_", "") for f in model_dir.glob("ka_*.json"))
            pending = [p for p in probes if p["sample_id"] not in existing or args.force]

            if not pending:
                print(f"{model}/{dataset}/knowledge_assessment: All {len(probes)} complete")
                continue

            print(f"Running {model} on {dataset}/knowledge_assessment: {len(pending)} pending of {len(probes)}")

            for i, probe in enumerate(pending, 1):
                print(f"[{i}/{len(pending)}]", end=" ")
                result = await assess_sample(model, probe, dataset, verbose=True)

                out_file = model_dir / f"ka_{result['sample_id']}.json"
                with open(out_file, "w") as fp:
                    json.dump(result, fp, indent=2)

            print(f"{model}/{dataset}/knowledge_assessment: COMPLETE")


if __name__ == "__main__":
    asyncio.run(main())
