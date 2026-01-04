"""
LLM Judge implementation.
"""

import json
import re
import os
from typing import Optional
from datetime import datetime, timezone

from .base import BaseLLMJudge
from .prompts import get_judge_system_prompt, get_judge_user_prompt
from ..base import EvaluationResult

try:
    import anthropic
except ImportError:
    anthropic = None


class ClaudeJudge(BaseLLMJudge):
    """LLM Judge using Claude for evaluation."""

    def __init__(
        self,
        model_name: str = "claude-sonnet-4-20250514",
        api_key: Optional[str] = None
    ):
        super().__init__(model_name, api_key or os.getenv("ANTHROPIC_API_KEY"))

        if anthropic is None:
            raise ImportError("anthropic package required for ClaudeJudge")

        self.client = anthropic.Anthropic(api_key=self.api_key)

    async def call_llm(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0
    ) -> str:
        """Make Claude API call."""
        response = self.client.messages.create(
            model=self.model_name,
            max_tokens=4096,
            temperature=temperature,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}]
        )
        return response.content[0].text

    def build_evaluation_prompt(
        self,
        detection_output: dict,
        ground_truth: dict
    ) -> tuple[str, str]:
        """Build prompts for evaluation."""
        system_prompt = get_judge_system_prompt()
        user_prompt = get_judge_user_prompt(
            detection_output=detection_output,
            ground_truth=ground_truth,
            code_snippet=ground_truth.get("code_snippet", "")
        )
        return system_prompt, user_prompt

    def parse_evaluation_response(
        self,
        response: str,
        detection_output: dict
    ) -> EvaluationResult:
        """Parse Claude's evaluation response."""
        # Extract JSON from response
        json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            # Try parsing raw JSON
            json_str = response

        try:
            data = json.loads(json_str)
        except json.JSONDecodeError:
            # Fallback for parsing errors
            return self._create_error_result(detection_output, "Failed to parse judge response")

        # Extract findings classification counts
        findings_class = data.get("findings_classification", [])
        tp = sum(1 for f in findings_class if f.get("classification") == "true_positive")
        fp = sum(1 for f in findings_class if f.get("classification") == "false_positive")
        hallucinations = sum(1 for f in findings_class if f.get("classification") == "hallucination")

        # Get quality scores (only if target found)
        quality = data.get("quality_scores", {})
        target_found = data.get("target_vulnerability_found", False)

        parsed = detection_output.get("parsed_output", {})
        findings = parsed.get("vulnerabilities", [])

        # Determine target finding ID
        target_idx = data.get("target_finding_index")
        target_finding_id = None
        if target_found and target_idx is not None and target_idx < len(findings):
            target_finding_id = f"finding_{target_idx}"

        return EvaluationResult(
            sample_id=detection_output.get("sample_id", "unknown"),
            evaluator_type="llm_judge",
            detection_source=self._get_detection_source(detection_output),
            detection_model=detection_output.get("model", "unknown"),
            detection_verdict_correct=data.get("detection_verdict_correct", False),
            target_vulnerability_found=target_found,
            target_finding_id=target_finding_id,
            target_explanation_quality=quality.get("explanation") if target_found else None,
            target_fix_quality=quality.get("fix_suggestion") if target_found else None,
            target_attack_scenario_quality=quality.get("attack_scenario") if target_found else None,
            total_findings=len(findings),
            true_positives=tp,
            false_positives=fp,
            hallucinations=hallucinations,
            evaluator_model=self.model_name,
            confidence=data.get("confidence", 0.5),
            reasoning=data.get("reasoning", ""),
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    def _get_detection_source(self, detection_output: dict) -> str:
        """Determine if detection was from LLM or traditional tool."""
        # Check for LLM-specific fields
        if "prompt_type" in detection_output or "api_metrics" in detection_output:
            return "llm"
        # Check for traditional tool fields
        if "tool_name" in detection_output or "analysis_type" in detection_output:
            return "traditional"
        return "unknown"

    def _create_error_result(
        self,
        detection_output: dict,
        error_msg: str
    ) -> EvaluationResult:
        """Create an error result when parsing fails."""
        parsed = detection_output.get("parsed_output", {})
        findings = parsed.get("vulnerabilities", [])

        return EvaluationResult(
            sample_id=detection_output.get("sample_id", "unknown"),
            evaluator_type="llm_judge",
            detection_source=self._get_detection_source(detection_output),
            detection_model=detection_output.get("model", "unknown"),
            detection_verdict_correct=False,
            target_vulnerability_found=False,
            target_finding_id=None,
            target_explanation_quality=None,
            target_fix_quality=None,
            target_attack_scenario_quality=None,
            total_findings=len(findings),
            true_positives=0,
            false_positives=0,
            hallucinations=0,
            evaluator_model=self.model_name,
            confidence=0.0,
            reasoning=f"Evaluation error: {error_msg}",
            timestamp=datetime.now(timezone.utc).isoformat()
        )
