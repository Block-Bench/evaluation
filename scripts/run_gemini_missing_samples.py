#!/usr/bin/env python3
"""
Run Gemini 3 Pro on the 2 missing samples.
"""

import asyncio
import json
import sys
from pathlib import Path
from datetime import datetime

from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.models.registry import ModelRegistry
from src.prompts.templates import PromptBuilder, PromptType

BASE_DIR = Path(__file__).parent.parent
GT_DIR = BASE_DIR / 'samples' / 'ground_truth'
OUTPUT_DIR = BASE_DIR / 'output' / 'gemini_3_pro_preview'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Missing samples
MISSING_SAMPLES = [
    'ch_medical_nc_tc_005',
    'sn_gs_005'
]

class GeminiRunner:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent

        # Load Gemini model config
        model_config_path = self.base_dir / 'config' / 'models' / 'gemini-3-pro.yaml'
        self.model_client = ModelRegistry.from_yaml(model_config_path)

        self.total_cost = 0.0
        self.success_count = 0
        self.failed_samples = []

    async def evaluate_sample(self, sample_id: str, prompt_type: str = 'direct') -> dict:
        """Evaluate a single sample with Gemini."""
        print(f"\n{'='*70}")
        print(f"Sample: {sample_id}")
        print(f"Prompt Type: {prompt_type}")
        print(f"{'='*70}")

        # Load ground truth
        gt_file = GT_DIR / f'{sample_id}.json'
        with open(gt_file, 'r') as f:
            gt_data = json.load(f)

        # Get contract code
        contract_path = gt_data['contract_file']
        # Handle both 'contracts/' and 'samples/contracts/' paths
        if contract_path.startswith('contracts/'):
            contract_file = self.base_dir / 'samples' / contract_path
        else:
            contract_file = self.base_dir / contract_path

        with open(contract_file, 'r') as f:
            contract_code = f.read()

        # Build prompt
        prompt_type_enum = PromptType.DIRECT if prompt_type == 'direct' else PromptType.ADVERSARIAL
        prompt_builder = PromptBuilder.for_type(prompt_type_enum)

        system_prompt, user_prompt = prompt_builder.build(
            contract_code=contract_code,
            language="solidity",
            chain_of_thought=False
        )

        print(f"Contract: {gt_data['contract_file']}")
        print(f"Vulnerability: {gt_data['ground_truth']['vulnerability_type']}")
        print(f"JSON mode: {prompt_builder.expects_json}")

        # Call model
        try:
            response = await self.model_client.generate(
                prompt=user_prompt,
                system_prompt=system_prompt,
                json_mode=prompt_builder.expects_json
            )

            # Calculate cost
            cost_usd = self.model_client.estimate_cost(response)
            self.total_cost += cost_usd

            print(f"\n✓ Response received")
            print(f"  Input tokens: {response.input_tokens:,}")
            print(f"  Output tokens: {response.output_tokens:,}")
            print(f"  Cost: ${cost_usd:.4f}")

            # Save output
            output_data = {
                'sample_id': sample_id,
                'prompt_type': prompt_type,
                'model': 'gemini_3_pro_preview',
                'timestamp': datetime.now().isoformat(),
                'response': response.text,
                'usage': {
                    'input_tokens': response.input_tokens,
                    'output_tokens': response.output_tokens,
                    'total_tokens': response.input_tokens + response.output_tokens
                },
                'cost_usd': cost_usd,
                'ground_truth': gt_data['ground_truth']
            }

            output_file = OUTPUT_DIR / f'{sample_id}_{prompt_type}.json'
            with open(output_file, 'w') as f:
                json.dump(output_data, f, indent=2)

            print(f"  Saved: {output_file}")

            self.success_count += 1
            return output_data

        except Exception as e:
            print(f"\n✗ Error: {e}")
            self.failed_samples.append(sample_id)
            return None

    async def run_all(self):
        """Run all missing samples."""
        print("="*70)
        print("GEMINI 3 PRO - MISSING SAMPLES EVALUATION")
        print("="*70)
        print(f"\nTotal samples to evaluate: {len(MISSING_SAMPLES)}")
        print(f"Samples: {', '.join(MISSING_SAMPLES)}")
        print()

        for sample_id in MISSING_SAMPLES:
            await self.evaluate_sample(sample_id, 'direct')

        # Summary
        print("\n" + "="*70)
        print("EVALUATION COMPLETE")
        print("="*70)
        print(f"\nSuccess: {self.success_count}/{len(MISSING_SAMPLES)}")
        print(f"Total cost: ${self.total_cost:.2f}")

        if self.failed_samples:
            print(f"\nFailed samples ({len(self.failed_samples)}):")
            for sample in self.failed_samples:
                print(f"  - {sample}")

        print(f"\nOutputs saved to: {OUTPUT_DIR}")

async def main():
    runner = GeminiRunner()
    await runner.run_all()

if __name__ == '__main__':
    asyncio.run(main())
