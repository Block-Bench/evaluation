#!/usr/bin/env python3
"""
Run Grok 4 evaluations on all missing samples.

This script:
1. Loads the list of missing samples
2. For each sample and prompt type:
   - Loads the contract code
   - Generates the appropriate prompt
   - Calls Grok 4
   - Saves the result in the standard output format
"""

import asyncio
import json
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict

from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.models.registry import ModelRegistry
from src.prompts.templates import PromptBuilder, PromptType

BASE_DIR = Path(__file__).parent.parent

# Prompt type mapping
PROMPT_TYPE_MAP = {
    'direct': PromptType.DIRECT,
    'adversarial': PromptType.ADVERSARIAL,
    'naturalistic': PromptType.NATURALISTIC
}

class Grok4Runner:
    """Runner for Grok 4 missing sample evaluations."""

    def __init__(self):
        print("Initializing Grok4Runner...", flush=True)
        self.base_dir = BASE_DIR
        self.samples_dir = self.base_dir / 'samples'
        self.contracts_dir = self.samples_dir / 'contracts'
        self.ground_truth_dir = self.samples_dir / 'ground_truth'
        self.output_dir = self.base_dir / 'output' / 'grok_4'
        self.missing_file = self.base_dir / 'analysis_results' / 'grok4_missing_samples.json'

        # Initialize model client
        print("Loading model configuration...", flush=True)
        model_config_path = self.base_dir / 'config' / 'models' / 'grok-4.yaml'
        self.model_client = ModelRegistry.from_yaml(model_config_path)
        print("Model client initialized successfully!", flush=True)

    def load_missing_samples(self) -> Dict[str, List[str]]:
        """Load the list of missing samples by prompt type."""
        with open(self.missing_file, 'r') as f:
            return json.load(f)

    def load_contract_code(self, sample_id: str) -> str:
        """Load contract code for a sample."""
        contract_file = self.contracts_dir / f"{sample_id}.sol"

        if not contract_file.exists():
            raise FileNotFoundError(f"Contract file not found: {contract_file}")

        with open(contract_file, 'r') as f:
            return f.read()

    async def evaluate_sample(self, sample_id: str, prompt_type: str) -> Dict:
        """Evaluate a single sample with Grok 4."""
        print(f"  Evaluating: {sample_id} ({prompt_type})")

        try:
            # Load contract code
            contract_code = self.load_contract_code(sample_id)

            # Build prompt
            prompt_type_enum = PROMPT_TYPE_MAP[prompt_type]
            prompt_builder = PromptBuilder.for_type(prompt_type_enum)
            system_prompt, user_prompt = prompt_builder.build(
                contract_code=contract_code,
                language="solidity",
                chain_of_thought=False
            )

            # Call model
            json_mode = prompt_builder.expects_json
            response = await self.model_client.generate(
                prompt=user_prompt,
                system_prompt=system_prompt,
                json_mode=json_mode
            )

            # Calculate cost
            cost_usd = self.model_client.estimate_cost(response)

            # Prepare result
            result = {
                "sample_id": sample_id,
                "prompt_type": prompt_type,
                "model": "grok_4",
                "timestamp": datetime.utcnow().isoformat(),
                "system_prompt": system_prompt,
                "user_prompt": user_prompt,
                "raw_response": response.content,
                "tokens": {
                    "input": response.input_tokens,
                    "output": response.output_tokens,
                    "total": response.input_tokens + response.output_tokens
                },
                "cost_usd": cost_usd,
                "latency_ms": response.latency_ms,
                "error": None
            }

            # For direct prompts, try to parse the JSON response
            if prompt_type == 'direct':
                try:
                    # Try to extract JSON from response
                    import re
                    json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', response.content)
                    if json_match:
                        parsed = json.loads(json_match.group(1))
                    else:
                        brace_match = re.search(r'\{[\s\S]*\}', response.content)
                        if brace_match:
                            parsed = json.loads(brace_match.group())
                        else:
                            parsed = json.loads(response.content)

                    result["prediction"] = {
                        "verdict": parsed.get("verdict", "unknown"),
                        "confidence": parsed.get("confidence"),
                        "vulnerabilities": parsed.get("vulnerabilities", []),
                        "overall_explanation": parsed.get("overall_explanation") or parsed.get("brief_explanation"),
                        "parse_success": True,
                        "parse_errors": []
                    }
                except Exception as e:
                    result["prediction"] = {
                        "verdict": "unknown",
                        "confidence": None,
                        "vulnerabilities": [],
                        "parse_success": False,
                        "parse_errors": [str(e)]
                    }

            return result

        except Exception as e:
            print(f"    ERROR: {str(e)}")
            return {
                "sample_id": sample_id,
                "prompt_type": prompt_type,
                "model": "grok_4",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
                "raw_response": None,
                "cost_usd": 0.0
            }

    def save_result(self, result: Dict, sample_id: str, prompt_type: str):
        """Save evaluation result to file."""
        # Create output directory for this prompt type
        output_prompt_dir = self.output_dir / prompt_type
        output_prompt_dir.mkdir(parents=True, exist_ok=True)

        # Save result
        output_file = output_prompt_dir / f"r_{sample_id}.json"
        with open(output_file, 'w') as f:
            json.dump(result, f, indent=2)

        print(f"    ✓ Saved to: {output_file.relative_to(self.base_dir)}")

    async def run_all(self, max_concurrent: int = 3, delay_between: float = 1.0):
        """Run evaluations for all missing samples."""
        missing = self.load_missing_samples()

        print("=" * 70)
        print("RUNNING GROK 4 ON MISSING SAMPLES")
        print("=" * 70)
        print()

        total_to_run = sum(len(samples) for samples in missing.values())
        completed = 0
        errors = 0
        total_cost = 0.0

        print(f"Total evaluations to run: {total_to_run}")
        print(f"Max concurrent requests: {max_concurrent}")
        print()

        # Process by prompt type
        for prompt_type, sample_ids in missing.items():
            if not sample_ids:
                continue

            print(f"\n{prompt_type.upper()} PROMPTS ({len(sample_ids)} samples)")
            print("-" * 70)

            # Process in batches to respect concurrency limit
            semaphore = asyncio.Semaphore(max_concurrent)

            async def evaluate_with_limit(sample_id: str):
                async with semaphore:
                    result = await self.evaluate_sample(sample_id, prompt_type)
                    self.save_result(result, sample_id, prompt_type)

                    # Small delay between requests
                    await asyncio.sleep(delay_between)

                    return result

            # Run all evaluations for this prompt type
            tasks = [evaluate_with_limit(sample_id) for sample_id in sample_ids]
            results = await asyncio.gather(*tasks, return_exceptions=True)

            # Count results
            for result in results:
                if isinstance(result, Exception):
                    errors += 1
                    print(f"  ERROR: {result}")
                elif isinstance(result, dict):
                    if result.get("error"):
                        errors += 1
                    else:
                        completed += 1
                        total_cost += result.get("cost_usd", 0.0)

            print(f"\n{prompt_type}: {len([r for r in results if not isinstance(r, Exception) and not r.get('error')])} completed")

        print("\n" + "=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"Total evaluations: {total_to_run}")
        print(f"Completed: {completed}")
        print(f"Errors: {errors}")
        print(f"Total cost: ${total_cost:.4f}")
        print("=" * 70)

async def main():
    import argparse
    parser = argparse.ArgumentParser(description='Run Grok 4 on missing samples')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be run without actually calling the API')
    parser.add_argument('--max-concurrent', type=int, default=3, help='Maximum concurrent API calls')
    parser.add_argument('--delay', type=float, default=1.0, help='Delay between requests in seconds')
    args = parser.parse_args()

    runner = Grok4Runner()

    if args.dry_run:
        # Just show what would be run
        missing = runner.load_missing_samples()
        print("=" * 70)
        print("DRY RUN - Would evaluate the following samples:")
        print("=" * 70)
        print()

        total = 0
        for prompt_type, sample_ids in missing.items():
            print(f"{prompt_type.upper()}: {len(sample_ids)} samples")
            for sample_id in sample_ids[:5]:
                print(f"  - {sample_id}")
            if len(sample_ids) > 5:
                print(f"  ... and {len(sample_ids) - 5} more")
            print()
            total += len(sample_ids)

        print(f"Total evaluations: {total}")
        print("\nRun without --dry-run to execute.")
    else:
        await runner.run_all(max_concurrent=args.max_concurrent, delay_between=args.delay)

if __name__ == '__main__':
    asyncio.run(main())
