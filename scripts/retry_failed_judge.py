#!/usr/bin/env python3
"""Retry the 2 failed judge evaluations."""

import asyncio
import json
import sys
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.judge.runner import JudgeRunner
from src.judge.config import JudgeModelConfig
from src.judge.schemas import JudgeInput, GroundTruthForJudge, PromptType
from src.data.sample_loader import SampleLoader

async def retry_failed():
    """Retry the 2 failed samples."""

    # Failed samples
    failed = [
        ("sn_gs_017", "naturalistic"),
        ("sn_gs_020", "naturalistic")
    ]

    # Load judge config
    judge_config = JudgeModelConfig.from_yaml("config/judge/mistral-medium-3.yaml")

    # Load samples
    sample_loader = SampleLoader("samples")
    samples = sample_loader.load_samples(load_code=True, load_ground_truth=True)
    samples_dict = {s.transformed_id: s for s in samples}

    # Create runner
    runner = JudgeRunner(
        judge_model_config=judge_config,
        output_dir=Path("judge_output/grok_4")
    )

    print("Retrying 2 failed judge evaluations...")
    print()

    for sample_id, prompt_type in failed:
        print(f"Evaluating {sample_id} × {prompt_type}...")

        # Get sample
        sample = samples_dict.get(sample_id)
        if not sample:
            print(f"  ERROR: Sample not found")
            continue

        # Load model response
        result_file = Path(f"output/grok_4/{prompt_type}/r_{sample_id}.json")
        with open(result_file) as f:
            result = json.load(f)

        response_content = result.get("raw_response", "")

        # Build ground truth
        gt = sample.ground_truth
        gt_for_judge = GroundTruthForJudge(
            is_vulnerable=gt.is_vulnerable if gt else False,
            vulnerability_type=gt.vulnerability_type if gt else None,
            severity=gt.severity if gt else None,
            root_cause=gt.root_cause if gt else None,
            attack_scenario=gt.attack_scenario if gt else None,
            fix_description=gt.fix_description if gt else None,
            vulnerable_function=gt.vulnerable_function if gt else None,
            vulnerable_lines=gt.vulnerable_lines if gt else None,
        )

        # Build judge input
        judge_input = JudgeInput(
            sample_id=sample.id,
            transformed_id=sample.transformed_id,
            prompt_type=PromptType(prompt_type),
            code=sample.contract_code or "",
            language="solidity",
            ground_truth=gt_for_judge,
            response_content=response_content
        )

        # Evaluate
        try:
            result = await runner.evaluate_single(judge_input)
            print(f"  ✓ Success")
        except Exception as e:
            print(f"  ✗ Error: {e}")

    print()
    print("Done!")

if __name__ == '__main__':
    asyncio.run(retry_failed())
