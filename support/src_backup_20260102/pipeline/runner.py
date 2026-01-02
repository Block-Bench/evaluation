"""
Main evaluation pipeline runner.

Orchestrates:
- Loading samples from transformed datasets
- Running each sample through multiple prompt types (direct, naturalistic, adversarial)
- Parsing responses (JSON for direct, raw for others)
- Saving results grouped by prompt type
"""

import asyncio
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Optional

import yaml

from ..data.loader import DatasetLoader
from ..data.sample_loader import SampleLoader, samples_exist
from ..data.schema import (
    Sample,
    ModelPrediction,
    DetectedVulnerability,
    EvaluationResult,
    Config,
    DataConfig,
    EvaluationConfig,
    ExecutionConfig,
    OutputConfig,
    SamplingConfig,
)
from ..models.base import BaseModelClient, ModelResponse
from ..models.registry import ModelRegistry
from ..prompts.templates import PromptBuilder, PromptType


class ResponseParser:
    """Parse model responses into structured predictions."""

    def parse(self, response: ModelResponse) -> ModelPrediction:
        """
        Parse a model response into a structured prediction.

        Args:
            response: Raw model response

        Returns:
            ModelPrediction with parsed data or error info
        """
        content = response.content
        errors = []

        # Try to extract JSON from response
        json_data, json_errors = self._extract_json(content)
        errors.extend(json_errors)

        if json_data is None:
            return ModelPrediction(
                verdict="unknown",
                confidence=0.0,
                parse_success=False,
                parse_errors=errors,
                raw_response=content,
            )

        try:
            return self._parse_json(json_data, content)
        except Exception as e:
            errors.append(f"Parse error: {str(e)}")
            return ModelPrediction(
                verdict="unknown",
                confidence=0.0,
                parse_success=False,
                parse_errors=errors,
                raw_response=content,
            )

    def _extract_json(self, content: str) -> tuple[Optional[dict], list[str]]:
        """Extract JSON from response, handling various formats."""
        errors = []

        # Try direct parse
        try:
            return json.loads(content), []
        except json.JSONDecodeError:
            pass

        # Try extracting from markdown code block
        json_match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", content)
        if json_match:
            try:
                return json.loads(json_match.group(1)), []
            except json.JSONDecodeError as e:
                errors.append(f"JSON in code block invalid: {e}")

        # Try finding JSON object in text
        brace_match = re.search(r"\{[\s\S]*\}", content)
        if brace_match:
            try:
                return json.loads(brace_match.group()), []
            except json.JSONDecodeError as e:
                errors.append(f"Extracted JSON invalid: {e}")

        errors.append("No valid JSON found in response")
        return None, errors

    def _parse_json(self, data: dict, raw_content: str) -> ModelPrediction:
        """Parse validated JSON into ModelPrediction."""
        # Normalize verdict
        verdict = data.get("verdict", "unknown")
        if isinstance(verdict, str):
            verdict = verdict.lower()
        if verdict not in ["vulnerable", "safe"]:
            verdict = "unknown"

        # Extract confidence
        confidence = data.get("confidence")
        if confidence is not None:
            confidence = max(0.0, min(1.0, float(confidence)))

        # Extract vulnerabilities
        vulnerabilities = []
        raw_vulns = data.get("vulnerabilities", [])
        if isinstance(raw_vulns, list):
            for v in raw_vulns:
                if isinstance(v, dict):
                    vulnerabilities.append(
                        DetectedVulnerability(
                            type=v.get("type", "unknown"),
                            severity=v.get("severity"),
                            location=v.get("location"),
                            explanation=v.get("explanation", ""),
                            suggested_fix=v.get("suggested_fix"),
                        )
                    )

        return ModelPrediction(
            verdict=verdict,
            confidence=confidence,
            vulnerabilities=vulnerabilities,
            overall_explanation=data.get("overall_explanation")
            or data.get("brief_explanation"),
            parse_success=True,
            parse_errors=[],
            raw_response=raw_content,
        )


class EvaluationPipeline:
    """Main evaluation pipeline."""

    def __init__(self, config_path: str):
        """
        Initialize the pipeline.

        Args:
            config_path: Path to configuration YAML file
        """
        self.config = self._load_config(config_path)
        self.config_path = config_path

        # Initialize components
        self.data_loader = DatasetLoader(self.config.data)
        self.parser = ResponseParser()

        # Will be set when running
        self.model: Optional[BaseModelClient] = None

    def _load_config(self, config_path: str) -> Config:
        """Load configuration from YAML file."""
        with open(config_path) as f:
            config_dict = yaml.safe_load(f)

        # Parse data config
        data_dict = config_dict.get("data", {})
        sampling = None
        if "sampling" in data_dict:
            sampling_dict = data_dict["sampling"]
            sampling = SamplingConfig(
                ds=sampling_dict.get("ds"),
                tc=sampling_dict.get("tc"),
                gs=sampling_dict.get("gs"),
                strategy=sampling_dict.get("strategy", "independent"),
                min_difficulty=sampling_dict.get("min_difficulty"),
            )

        data_config = DataConfig(
            root=data_dict.get("root", "./raw/data"),
            ground_truth_path=data_dict.get(
                "ground_truth_path", "./raw/data/annotated/metadata"
            ),
            transformations=data_dict.get("transformations", ["sanitized"]),
            sampling=sampling,
            seed=data_dict.get("seed", 42),
        )

        # Parse evaluation config
        eval_dict = config_dict.get("evaluation", {})
        eval_config = EvaluationConfig(
            prompt_types=eval_dict.get(
                "prompt_types", ["direct", "naturalistic", "adversarial"]
            ),
            chain_of_thought=eval_dict.get("chain_of_thought", False),
        )

        # Parse execution config
        exec_dict = config_dict.get("execution", {})
        exec_config = ExecutionConfig(
            max_concurrency=exec_dict.get("max_concurrency", 3),
            timeout_seconds=exec_dict.get("timeout_seconds", 180),
            checkpoint_every=exec_dict.get("checkpoint_every", 10),
            max_retries=exec_dict.get("max_retries", 3),
            retry_delay=exec_dict.get("retry_delay", 2.0),
        )

        # Parse output config
        output_dict = config_dict.get("output", {})
        output_config = OutputConfig(
            directory=output_dict.get("directory", "./output"),
            save_raw_responses=output_dict.get("save_raw_responses", True),
        )

        return Config(
            data=data_config,
            evaluation=eval_config,
            execution=exec_config,
            output=output_config,
            default_model=config_dict.get("default_model", "deepseek-v3-2"),
        )

    def _get_output_path(
        self, model_name: str, prompt_type: str, transformed_id: str
    ) -> Path:
        """
        Get output file path for a result.

        Structure: output/{model_name}/{prompt_type}/r_{transformed_id}.json
        """
        # Sanitize model name for filesystem
        safe_model_name = model_name.replace(" ", "_").replace("/", "_").lower()

        output_dir = Path(self.config.output.directory) / safe_model_name / prompt_type
        output_dir.mkdir(parents=True, exist_ok=True)

        return output_dir / f"r_{transformed_id}.json"

    def _result_exists(
        self, model_name: str, prompt_type: str, transformed_id: str
    ) -> bool:
        """Check if a result already exists (for resume)."""
        output_path = self._get_output_path(model_name, prompt_type, transformed_id)
        return output_path.exists()

    def _save_result(self, result: EvaluationResult):
        """Save an evaluation result to disk."""
        output_path = self._get_output_path(
            result.model_id, result.prompt_type, result.transformed_id
        )

        # Convert to dict for JSON serialization
        result_dict = result.model_dump(mode="json")

        with open(output_path, "w") as f:
            json.dump(result_dict, f, indent=2, default=str)

    async def evaluate_sample(
        self,
        sample: Sample,
        model: BaseModelClient,
        prompt_type: str,
    ) -> EvaluationResult:
        """
        Evaluate a single sample with a specific prompt type.

        Args:
            sample: Sample to evaluate
            model: Model client to use
            prompt_type: Type of prompt (direct, naturalistic, adversarial)

        Returns:
            EvaluationResult with prediction/raw_response and metadata
        """
        # Build prompt for this type
        prompt_builder = PromptBuilder.for_type(prompt_type)
        system_prompt, user_prompt = prompt_builder.build(
            contract_code=sample.contract_code,
            language="solidity",  # TODO: detect from file
            chain_of_thought=self.config.evaluation.chain_of_thought,
        )

        try:
            # Call model - only request JSON mode for direct prompts
            response = await model.generate_with_retry(
                prompt=user_prompt,
                system_prompt=system_prompt,
                json_mode=prompt_builder.expects_json,
            )

            # Calculate cost
            cost = model.estimate_cost(response)

            # Parse response only for direct prompts
            prediction = None
            if prompt_builder.expects_json:
                prediction = self.parser.parse(response)

            return EvaluationResult(
                sample_id=sample.id,
                transformed_id=sample.transformed_id,
                transformation=sample.transformation,
                prompt_type=prompt_type,
                model_id=model.config.name,
                prediction=prediction,
                raw_response=response.content,
                input_tokens=response.input_tokens,
                output_tokens=response.output_tokens,
                latency_ms=response.latency_ms,
                cost_usd=cost,
            )

        except Exception as e:
            # Return error result
            return EvaluationResult(
                sample_id=sample.id,
                transformed_id=sample.transformed_id,
                transformation=sample.transformation,
                prompt_type=prompt_type,
                model_id=model.config.name,
                prediction=None,
                raw_response="",
                error=str(e),
            )

    async def run(
        self,
        model_config_path: Optional[str] = None,
        resume: bool = True,
        dry_run: bool = False,
    ) -> dict:
        """
        Run the evaluation pipeline.

        Args:
            model_config_path: Path to model config (uses default if None)
            resume: Skip samples that already have results
            dry_run: Just show what would be evaluated

        Returns:
            Summary statistics
        """
        # Load samples - prefer samples/ folder if it exists
        if samples_exist("samples"):
            print("Loading samples from: samples/ (pre-generated)")
            sample_loader = SampleLoader("samples")
            samples = sample_loader.load_samples()
            stats = sample_loader.get_statistics()
            prompt_types = sample_loader.prompt_types
        else:
            print(f"Loading samples from: {self.config.data.root} (on-the-fly)")
            samples = self.data_loader.load_samples()
            stats = self.data_loader.get_statistics(samples)
            prompt_types = self.config.evaluation.prompt_types

        print(f"Loaded {stats['total']} samples")
        print(f"  By transformation: {stats['by_transformation']}")
        print(f"  By subset: {stats['by_subset']}")
        print(f"Prompt types: {prompt_types}")

        # Get model name from config (without loading full client)
        if model_config_path is None:
            model_config_path = f"config/models/{self.config.default_model}.yaml"
        model_config = ModelRegistry.load_config(model_config_path)
        model_name = model_config.name

        # Build list of (sample, prompt_type) pairs to evaluate
        eval_pairs = []
        for sample in samples:
            # Use per-sample prompt types if specified, otherwise use global
            sample_prompt_types = sample.prompt_types if sample.prompt_types else prompt_types
            for prompt_type in sample_prompt_types:
                if resume and self._result_exists(
                    model_name, prompt_type, sample.transformed_id
                ):
                    continue  # Skip already completed
                eval_pairs.append((sample, prompt_type))

        skipped = (len(samples) * len(prompt_types)) - len(eval_pairs)
        if skipped > 0:
            print(f"Resuming: skipping {skipped} already completed evaluations")

        if dry_run:
            print(f"\nDry run - would evaluate {len(eval_pairs)} sample×prompt pairs:")
            for sample, prompt_type in eval_pairs[:10]:
                print(f"  {sample.transformed_id} × {prompt_type}")
            if len(eval_pairs) > 10:
                print(f"  ... and {len(eval_pairs) - 10} more")
            return {"dry_run": True, "eval_pairs": len(eval_pairs), "samples": len(samples)}

        if not eval_pairs:
            print("No samples to evaluate")
            return {"samples": 0, "completed": 0}

        # Load model client (only after dry_run check to avoid auth errors)
        # Import here to trigger registration of all model providers
        from ..models import (  # noqa: F401
            vertex_deepseek,
            vertex_anthropic,
            vertex_google,
            openrouter,
        )

        model = ModelRegistry.create(model_config)
        self.model = model

        # Run evaluation
        print(
            f"\nEvaluating {len(eval_pairs)} sample×prompt pairs with {model.config.name}"
        )

        results = []
        total_cost = 0.0
        errors = 0

        for i, (sample, prompt_type) in enumerate(eval_pairs):
            print(
                f"[{i+1}/{len(eval_pairs)}] {sample.transformed_id} × {prompt_type}...",
                end=" ",
                flush=True,
            )

            result = await self.evaluate_sample(sample, model, prompt_type)
            results.append(result)

            # Save immediately
            self._save_result(result)

            if result.error:
                errors += 1
                print(f"ERROR: {result.error}")
            else:
                total_cost += result.cost_usd or 0
                # Show verdict for direct, response length for others
                if result.prediction:
                    print(
                        f"OK ({result.prediction.verdict}, ${result.cost_usd:.4f})"
                    )
                else:
                    print(
                        f"OK ({len(result.raw_response)} chars, ${result.cost_usd:.4f})"
                    )

        # Summary
        summary = {
            "samples": len(samples),
            "prompt_types": prompt_types,
            "eval_pairs": len(eval_pairs),
            "completed": len([r for r in results if not r.error]),
            "errors": errors,
            "total_cost_usd": total_cost,
            "model": model.config.name,
        }

        print(f"\n{'='*50}")
        print(f"Completed: {summary['completed']}/{summary['eval_pairs']}")
        print(f"Errors: {summary['errors']}")
        print(f"Total cost: ${summary['total_cost_usd']:.4f}")

        return summary


async def run_pipeline(
    config_path: str = "config/default.yaml",
    model_config_path: Optional[str] = None,
    resume: bool = True,
    dry_run: bool = False,
) -> dict:
    """
    Convenience function to run the pipeline.

    Args:
        config_path: Path to main config file
        model_config_path: Path to model config (uses default if None)
        resume: Skip already completed samples
        dry_run: Just show what would be evaluated

    Returns:
        Summary statistics
    """
    pipeline = EvaluationPipeline(config_path)
    return await pipeline.run(
        model_config_path=model_config_path,
        resume=resume,
        dry_run=dry_run,
    )
