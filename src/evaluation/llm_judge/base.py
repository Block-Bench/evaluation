"""
LLM Judge base class and utilities.
"""

from abc import abstractmethod
from datetime import datetime, timezone
from typing import Optional

from ..base import BaseEvaluator, EvaluatorType, EvaluationResult


class BaseLLMJudge(BaseEvaluator):
    """Base class for LLM-based judges."""

    def __init__(
        self,
        model_name: str,
        api_key: Optional[str] = None
    ):
        super().__init__(EvaluatorType.LLM_JUDGE)
        self.model_name = model_name
        self.api_key = api_key

    @abstractmethod
    async def call_llm(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0
    ) -> str:
        """Make an LLM API call."""
        pass

    @abstractmethod
    def build_evaluation_prompt(
        self,
        detection_output: dict,
        ground_truth: dict
    ) -> tuple[str, str]:
        """
        Build the system and user prompts for evaluation.

        Returns:
            Tuple of (system_prompt, user_prompt)
        """
        pass

    @abstractmethod
    def parse_evaluation_response(
        self,
        response: str,
        detection_output: dict
    ) -> EvaluationResult:
        """Parse the LLM response into an EvaluationResult."""
        pass

    async def evaluate(
        self,
        detection_output: dict,
        ground_truth: dict,
        **kwargs
    ) -> EvaluationResult:
        """
        Evaluate detection output using LLM judge.

        Args:
            detection_output: Detection result to evaluate
            ground_truth: Ground truth information
            **kwargs: Additional parameters (temperature, etc.)

        Returns:
            EvaluationResult
        """
        temperature = kwargs.get("temperature", 0.0)

        # Build prompts
        system_prompt, user_prompt = self.build_evaluation_prompt(
            detection_output, ground_truth
        )

        # Call LLM
        response = await self.call_llm(
            system_prompt, user_prompt, temperature
        )

        # Parse response
        result = self.parse_evaluation_response(response, detection_output)
        result.timestamp = datetime.now(timezone.utc).isoformat()
        result.evaluator_model = self.model_name

        return result

    async def evaluate_batch(
        self,
        detection_outputs: list[dict],
        ground_truths: list[dict],
        **kwargs
    ) -> list[EvaluationResult]:
        """Evaluate multiple detection outputs."""
        results = []
        for detection, ground_truth in zip(detection_outputs, ground_truths):
            result = await self.evaluate(detection, ground_truth, **kwargs)
            results.append(result)
        return results
