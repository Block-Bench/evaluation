#!/usr/bin/env python3
"""
Judge evaluation for ONLY naturalistic and adversarial prompts on 5 GS samples.
"""

import asyncio
import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from dotenv import load_dotenv
load_dotenv()

from src.judge.config import JudgeModelConfig
from src.judge.runner import JudgeRunner
from src.judge.schemas import JudgeInput, GroundTruthForJudge, PromptType
from src.data.sample_loader import SampleLoader

# Only these 5 GS samples with only naturalistic and adversarial prompts
TARGET_SAMPLES = ['sn_gs_002', 'sn_gs_013', 'sn_gs_017', 'sn_gs_020', 'sn_gs_026']
TARGET_PROMPTS = ['naturalistic', 'adversarial']


async def run_judge_for_model(model_name: str):
    """Run judge evaluation for a single model on only new prompts."""

    print(f"\n{'='*60}")
    print(f"Evaluating {model_name}")
    print(f"{'='*60}\n")

    # Load judge config
    judge_config = JudgeModelConfig.from_yaml('config/judge/mistral-medium-3.yaml')

    # Load samples
    sample_loader = SampleLoader('samples')
    all_samples = sample_loader.load_samples(load_code=True, load_ground_truth=True)

    # Filter to only our 5 GS samples
    samples = [s for s in all_samples if s.transformed_id in TARGET_SAMPLES]
    print(f"Loaded {len(samples)} target samples: {TARGET_SAMPLES}")

    # Build judge inputs for ONLY naturalistic and adversarial
    model_output_dir = Path('output') / model_name
    judge_inputs = []
    ground_truths = {}

    for sample in samples:
        for prompt_type in TARGET_PROMPTS:
            result_file = model_output_dir / prompt_type / f"r_{sample.transformed_id}.json"

            if not result_file.exists():
                print(f"  Warning: Missing {result_file}")
                continue

            with open(result_file) as f:
                result = json.load(f)

            response_content = result.get("raw_response", "")
            if not response_content:
                print(f"  Warning: No response in {result_file}")
                continue

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

            judge_input = JudgeInput(
                sample_id=sample.id,
                transformed_id=sample.transformed_id,
                prompt_type=PromptType(prompt_type),
                code=sample.contract_code or "",
                language="solidity",
                ground_truth=gt_for_judge,
                response_content=response_content
            )

            judge_inputs.append(judge_input)
            ground_truths[sample.id] = gt_for_judge

    print(f"Built {len(judge_inputs)} judge inputs (expecting 10)\n")

    if len(judge_inputs) == 0:
        print("No inputs to evaluate!")
        return

    # Run judge
    judge_output_dir = Path('judge_output') / model_name
    runner = JudgeRunner(
        judge_model_config=judge_config,
        output_dir=judge_output_dir,
        max_concurrency=1  # One at a time to avoid quota issues
    )

    await runner.run(
        inputs=judge_inputs,
        ground_truths=ground_truths,
        resume=True  # Skip any already completed
    )

    print(f"\n✓ Completed {model_name}\n")


async def main():
    """Run judge for all models sequentially."""
    models = [
        'claude_opus_4.5',
        'deepseek_v3.2',
        'gemini_3_pro_preview',
        'gpt-5.2',
        'llama_3.1_405b',
        'grok_4_fast'
    ]

    for model in models:
        try:
            await run_judge_for_model(model)
            print(f"\n{'='*60}\n")
        except Exception as e:
            print(f"ERROR on {model}: {e}")
            continue


if __name__ == '__main__':
    asyncio.run(main())
