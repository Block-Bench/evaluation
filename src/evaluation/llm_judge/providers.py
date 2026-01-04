"""
Multi-provider LLM Judge implementations.

Supports:
- Vertex AI Anthropic (Haiku via AnthropicVertex)
- Vertex AI Mistral (Codestral via rawPredict)
- OpenRouter (GPT-4o-mini)
"""

import json
import os
import re
import httpx
import requests
from abc import ABC
from datetime import datetime, timezone
from typing import Optional

from .base import BaseLLMJudge
from .prompts import (
    get_judge_system_prompt,
    get_judge_user_prompt,
    get_traditional_tool_system_prompt,
    get_traditional_tool_user_prompt
)
from ..base import EvaluationResult


class VertexAIHaikuJudge(BaseLLMJudge):
    """LLM Judge using Claude Haiku via AnthropicVertex."""

    def __init__(
        self,
        model_id: str = "claude-haiku-4-5@20251001",
        project_id: Optional[str] = None,
        region: str = "global",
        model_name: Optional[str] = None
    ):
        super().__init__(model_name or "haiku", api_key=None)
        self.model_id = model_id
        self.project_id = project_id or os.getenv("VERTEX_PROJECT_ID")
        self.region = region
        self._client = None

        if not self.project_id:
            raise ValueError("VERTEX_PROJECT_ID must be set")

    def _get_client(self):
        """Get or create AnthropicVertex client."""
        if self._client is None:
            try:
                from anthropic import AnthropicVertex
                self._client = AnthropicVertex(
                    region=self.region,
                    project_id=self.project_id
                )
            except ImportError:
                raise ImportError("anthropic package required for VertexAIHaikuJudge")
        return self._client

    async def call_llm(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0
    ) -> str:
        """Make AnthropicVertex API call."""
        client = self._get_client()

        message = client.messages.create(
            model=self.model_id,
            max_tokens=4096,
            messages=[{"role": "user", "content": user_prompt}],
            system=system_prompt,
            temperature=temperature
        )

        return message.content[0].text

    def build_evaluation_prompt(
        self,
        detection_output: dict,
        ground_truth: dict,
        code_snippet: str = "",
        is_traditional: bool = False
    ) -> tuple[str, str]:
        """Build prompts for evaluation."""
        if is_traditional:
            system_prompt = get_traditional_tool_system_prompt()
            user_prompt = get_traditional_tool_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        else:
            system_prompt = get_judge_system_prompt()
            user_prompt = get_judge_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        return system_prompt, user_prompt

    def parse_evaluation_response(
        self,
        response: str,
        detection_output: dict
    ) -> EvaluationResult:
        """Parse evaluation response."""
        return _parse_judge_response(response, detection_output, self.model_name)


class VertexAICodestralJudge(BaseLLMJudge):
    """LLM Judge using Codestral via Vertex AI rawPredict."""

    def __init__(
        self,
        model_id: str = "codestral-2",
        project_id: Optional[str] = None,
        location: str = "europe-west4",
        model_name: Optional[str] = None
    ):
        super().__init__(model_name or "codestral", api_key=None)
        self.model_id = model_id
        self.project_id = project_id or os.getenv("VERTEX_PROJECT_ID")
        self.location = location
        self._credentials = None

        if not self.project_id:
            raise ValueError("VERTEX_PROJECT_ID must be set")

    def _get_credentials(self):
        """Get Google Cloud credentials."""
        if self._credentials is None:
            from google.auth import default
            from google.auth.transport.requests import Request
            self._credentials, _ = default()
            self._credentials.refresh(Request())
        return self._credentials

    async def call_llm(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0
    ) -> str:
        """Make Vertex AI rawPredict call for Codestral."""
        credentials = self._get_credentials()

        # Refresh token if needed
        from google.auth.transport.requests import Request
        if not credentials.valid:
            credentials.refresh(Request())

        endpoint = (
            f"https://{self.location}-aiplatform.googleapis.com/v1/"
            f"projects/{self.project_id}/locations/{self.location}/"
            f"publishers/mistralai/models/{self.model_id}:rawPredict"
        )

        headers = {
            "Authorization": f"Bearer {credentials.token}",
            "Content-Type": "application/json"
        }

        # Mistral message format
        payload = {
            "model": self.model_id,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": temperature,
            "max_tokens": 4096
        }

        response = requests.post(
            endpoint,
            headers=headers,
            json=payload,
            timeout=120
        )

        if response.status_code != 200:
            raise Exception(f"Codestral API error {response.status_code}: {response.text}")

        data = response.json()
        return data["choices"][0]["message"]["content"]

    def build_evaluation_prompt(
        self,
        detection_output: dict,
        ground_truth: dict,
        code_snippet: str = "",
        is_traditional: bool = False
    ) -> tuple[str, str]:
        """Build prompts for evaluation."""
        if is_traditional:
            system_prompt = get_traditional_tool_system_prompt()
            user_prompt = get_traditional_tool_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        else:
            system_prompt = get_judge_system_prompt()
            user_prompt = get_judge_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        return system_prompt, user_prompt

    def parse_evaluation_response(
        self,
        response: str,
        detection_output: dict
    ) -> EvaluationResult:
        """Parse evaluation response."""
        return _parse_judge_response(response, detection_output, self.model_name)


class OpenRouterJudge(BaseLLMJudge):
    """LLM Judge using OpenRouter API."""

    def __init__(
        self,
        model_id: str,
        api_key: Optional[str] = None,
        model_name: Optional[str] = None
    ):
        super().__init__(model_name or model_id, api_key or os.getenv("OPENROUTER_API_KEY"))
        self.model_id = model_id
        self.base_url = "https://openrouter.ai/api/v1/chat/completions"

        if not self.api_key:
            raise ValueError("OPENROUTER_API_KEY must be set")

    async def call_llm(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0
    ) -> str:
        """Make OpenRouter API call."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/blockbench",
            "X-Title": "BlockBench Evaluation"
        }

        payload = {
            "model": self.model_id,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": temperature,
            "max_tokens": 4096
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                self.base_url,
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            data = response.json()

        return data["choices"][0]["message"]["content"]

    def build_evaluation_prompt(
        self,
        detection_output: dict,
        ground_truth: dict,
        code_snippet: str = "",
        is_traditional: bool = False
    ) -> tuple[str, str]:
        """Build prompts for evaluation."""
        if is_traditional:
            system_prompt = get_traditional_tool_system_prompt()
            user_prompt = get_traditional_tool_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        else:
            system_prompt = get_judge_system_prompt()
            user_prompt = get_judge_user_prompt(
                detection_output=detection_output,
                ground_truth=ground_truth,
                code_snippet=code_snippet
            )
        return system_prompt, user_prompt

    def parse_evaluation_response(
        self,
        response: str,
        detection_output: dict
    ) -> EvaluationResult:
        """Parse evaluation response."""
        return _parse_judge_response(response, detection_output, self.model_name)


def _parse_judge_response(
    response: str,
    detection_output: dict,
    model_name: str
) -> EvaluationResult:
    """
    Common response parsing logic for all judge providers.

    Extracts JSON from response and creates EvaluationResult.
    """
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
        return _create_error_result(detection_output, model_name, "Failed to parse judge response")

    # Extract findings classification counts
    findings_class = data.get("findings_classification", [])
    tp = sum(1 for f in findings_class if f.get("classification") == "true_positive")
    fp = sum(1 for f in findings_class if f.get("classification") == "false_positive")
    hallucinations = sum(1 for f in findings_class if f.get("classification") == "hallucination")

    # Get quality scores (only if target found)
    quality = data.get("quality_scores", {})
    target_found = data.get("target_vulnerability_found", False)

    # Get findings from detection output
    parsed = detection_output.get("parsed_output", {})
    findings = parsed.get("vulnerabilities", [])

    # For traditional tools, findings might be in raw_output
    if not findings and "raw_output" in detection_output:
        raw = detection_output.get("raw_output", {})
        if "results" in raw:  # Slither format
            findings = raw.get("results", {}).get("detectors", [])
        elif "issues" in raw:  # Mythril format
            findings = raw.get("issues", [])

    # Determine target finding ID
    target_idx = data.get("target_finding_index")
    target_finding_id = None
    if target_found and target_idx is not None and target_idx < len(findings):
        target_finding_id = f"finding_{target_idx}"

    # Determine detection source
    detection_source = "traditional" if detection_output.get("tool") else "llm"

    return EvaluationResult(
        sample_id=detection_output.get("sample_id", "unknown"),
        evaluator_type="llm_judge",
        detection_source=detection_source,
        detection_model=detection_output.get("model") or detection_output.get("tool", "unknown"),
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
        evaluator_model=model_name,
        confidence=data.get("confidence", 0.5),
        reasoning=data.get("reasoning", ""),
        timestamp=datetime.now(timezone.utc).isoformat()
    )


def _create_error_result(
    detection_output: dict,
    model_name: str,
    error_msg: str
) -> EvaluationResult:
    """Create an error result when parsing fails."""
    parsed = detection_output.get("parsed_output", {})
    findings = parsed.get("vulnerabilities", [])

    detection_source = "traditional" if detection_output.get("tool") else "llm"

    return EvaluationResult(
        sample_id=detection_output.get("sample_id", "unknown"),
        evaluator_type="llm_judge",
        detection_source=detection_source,
        detection_model=detection_output.get("model") or detection_output.get("tool", "unknown"),
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
        evaluator_model=model_name,
        confidence=0.0,
        reasoning=f"Evaluation error: {error_msg}",
        timestamp=datetime.now(timezone.utc).isoformat()
    )


def create_judge(config) -> BaseLLMJudge:
    """
    Factory function to create a judge from JudgeModelConfig.

    Args:
        config: JudgeModelConfig instance with fields:
            - name: Judge name (e.g., "haiku", "codestral", "gpt4o-mini")
            - provider: Provider type ("vertex-anthropic", "vertex-mistral", "openrouter")
            - model_id: Model identifier
            - family: Model family ("anthropic", "openai", "mistral")

    Returns:
        BaseLLMJudge instance
    """
    if config.provider == "vertex-anthropic":
        return VertexAIHaikuJudge(
            model_id=config.model_id,
            model_name=config.name
        )
    elif config.provider == "vertex-mistral":
        return VertexAICodestralJudge(
            model_id=config.model_id,
            model_name=config.name
        )
    elif config.provider == "openrouter":
        return OpenRouterJudge(
            model_id=config.model_id,
            model_name=config.name
        )
    else:
        raise ValueError(f"Unknown provider: {config.provider}")
