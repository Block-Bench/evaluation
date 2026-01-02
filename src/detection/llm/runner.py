"""
LLM Detection Runner.

Orchestrates the detection pipeline: prompt building -> LLM call -> parsing -> output.
"""

import json
import asyncio
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Any

from .clients.base import BaseLLMClient, LLMResponse
from .prompts.base import BasePromptBuilder, PromptPair
from .parser import LLMOutputParser, ParseResult


class LLMDetectionRunner:
    """
    Runs LLM-based vulnerability detection on smart contracts.

    Handles the full pipeline from loading code to producing schema-conformant output.
    """

    def __init__(
        self,
        client: BaseLLMClient,
        prompt_builder: BasePromptBuilder,
        parser: Optional[LLMOutputParser] = None
    ):
        """
        Initialize the detection runner.

        Args:
            client: LLM API client
            prompt_builder: Prompt builder for the target dataset/prompt type
            parser: Output parser (uses default if not provided)
        """
        self.client = client
        self.prompt_builder = prompt_builder
        self.parser = parser or LLMOutputParser()

    async def detect(
        self,
        code: str,
        sample_id: str,
        tier: Optional[str] = None,
        contract_name: Optional[str] = None,
        language: str = "solidity",
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> dict:
        """
        Run vulnerability detection on a smart contract.

        Args:
            code: Smart contract source code
            sample_id: Unique identifier for this sample
            tier: Difficulty tier (for DS dataset)
            contract_name: Name of the contract
            language: Programming language
            temperature: LLM temperature
            max_tokens: Max tokens for response

        Returns:
            Dict conforming to llm_detection_output.schema.json
        """
        # Build prompts
        prompt_pair = self.prompt_builder.build(
            code=code,
            contract_name=contract_name,
            language=language
        )

        # Call LLM
        try:
            response = await self.client.generate(
                system_prompt=prompt_pair.system_prompt,
                user_prompt=prompt_pair.user_prompt,
                temperature=temperature,
                max_tokens=max_tokens
            )
            llm_error = None
        except Exception as e:
            response = None
            llm_error = str(e)

        # Parse response
        if response:
            parse_result = self.parser.parse(response.content)
            if parse_result.success:
                is_valid, validation_errors = self.parser.validate_detection_output(
                    parse_result.data
                )
            else:
                is_valid = False
                validation_errors = [parse_result.error_message]
        else:
            parse_result = ParseResult(
                success=False,
                data=None,
                raw_content="",
                error_message=llm_error
            )
            is_valid = False
            validation_errors = [llm_error]

        # Build output
        return self._build_output(
            sample_id=sample_id,
            tier=tier,
            prompt_pair=prompt_pair,
            response=response,
            parse_result=parse_result,
            is_valid=is_valid,
            validation_errors=validation_errors
        )

    def _build_output(
        self,
        sample_id: str,
        tier: Optional[str],
        prompt_pair: PromptPair,
        response: Optional[LLMResponse],
        parse_result: ParseResult,
        is_valid: bool,
        validation_errors: list[str]
    ) -> dict:
        """Build schema-conformant output dictionary."""
        timestamp = datetime.now(timezone.utc).isoformat()

        output = {
            "sample_id": sample_id,
            "model": self.client.model_name,
            "prompt_type": prompt_pair.prompt_type,
            "dataset_type": prompt_pair.dataset_type,
            "timestamp": timestamp,
            "raw_llm_output": {
                "content": response.content if response else None,
                "finish_reason": response.finish_reason if response else None
            },
            "parsed_output": parse_result.data,
            "parsing_info": {
                "success": parse_result.success,
                "extraction_method": parse_result.extraction_method,
                "validation_passed": is_valid,
                "validation_errors": validation_errors if not is_valid else []
            },
            "api_metrics": {
                "input_tokens": response.input_tokens if response else 0,
                "output_tokens": response.output_tokens if response else 0,
                "latency_ms": response.latency_ms if response else 0,
                "cost_usd": response.cost_usd if response else 0
            }
        }

        if tier:
            output["tier"] = tier

        return output

    async def detect_batch(
        self,
        samples: list[dict],
        concurrency: int = 5
    ) -> list[dict]:
        """
        Run detection on multiple samples with concurrency control.

        Args:
            samples: List of dicts with 'code', 'sample_id', and optional 'tier', 'contract_name'
            concurrency: Max concurrent requests

        Returns:
            List of detection outputs
        """
        semaphore = asyncio.Semaphore(concurrency)

        async def detect_with_limit(sample: dict) -> dict:
            async with semaphore:
                return await self.detect(
                    code=sample["code"],
                    sample_id=sample["sample_id"],
                    tier=sample.get("tier"),
                    contract_name=sample.get("contract_name")
                )

        tasks = [detect_with_limit(sample) for sample in samples]
        return await asyncio.gather(*tasks)


class DetectionPipeline:
    """
    High-level pipeline for running detection across datasets.

    Handles loading samples, running detection, and saving results.
    """

    def __init__(
        self,
        runner: LLMDetectionRunner,
        output_dir: Path
    ):
        """
        Initialize the pipeline.

        Args:
            runner: Detection runner instance
            output_dir: Directory for output files
        """
        self.runner = runner
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    async def run_on_samples(
        self,
        samples: list[dict],
        save_individual: bool = True
    ) -> list[dict]:
        """
        Run detection on samples and save results.

        Args:
            samples: List of sample dictionaries
            save_individual: Whether to save individual result files

        Returns:
            List of all detection results
        """
        results = []

        for sample in samples:
            result = await self.runner.detect(
                code=sample["code"],
                sample_id=sample["sample_id"],
                tier=sample.get("tier"),
                contract_name=sample.get("contract_name")
            )
            results.append(result)

            if save_individual:
                self._save_result(result)

        return results

    def _save_result(self, result: dict) -> Path:
        """Save individual result to file."""
        sample_id = result["sample_id"]
        prompt_type = result["prompt_type"]

        # Build filename: d_{sample_id}_{prompt_type}.json
        filename = f"d_{sample_id}_{prompt_type}.json"

        # Determine subdirectory based on tier if present
        if "tier" in result:
            subdir = self.output_dir / result["tier"]
        else:
            subdir = self.output_dir

        subdir.mkdir(parents=True, exist_ok=True)
        filepath = subdir / filename

        with open(filepath, 'w') as f:
            json.dump(result, f, indent=2)

        return filepath
