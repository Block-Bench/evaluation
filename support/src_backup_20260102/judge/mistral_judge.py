"""
Mistral Medium 3 Judge implementation via Vertex AI rawPredict endpoint.
"""

import json
import os
import time
from datetime import datetime
from typing import Optional

import aiohttp
import google.auth
import google.auth.transport.requests

from .client import BaseJudgeClient
from .config import JudgeModelConfig
from .schemas import (
    JudgeInput,
    JudgeOutput,
    FindingEvaluation,
    FindingClassification,
    TargetVulnerabilityAssessment,
    TypeMatchLevel,
    ReasoningScore,
)
from .prompts import JUDGE_SYSTEM_PROMPT, build_judge_prompt


class MistralJudgeClient(BaseJudgeClient):
    """Mistral Medium 3 judge via Vertex AI rawPredict endpoint"""

    def _setup_client(self):
        """Initialize credentials for Vertex AI"""
        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        self.project_id = (
            self.config.project_id
            or os.environ.get("GOOGLE_CLOUD_PROJECT")
            or project
        )
        self._credentials = credentials
        self.region = self.config.region or "us-central1"

        # Build the rawPredict endpoint URL
        self.endpoint_url = (
            f"https://{self.region}-aiplatform.googleapis.com/v1/"
            f"projects/{self.project_id}/locations/{self.region}/"
            f"publishers/mistralai/models/{self.config.model_id}:rawPredict"
        )

    def _refresh_token_if_needed(self):
        """Refresh Google auth token if expired"""
        if self._credentials.expired:
            self._credentials.refresh(google.auth.transport.requests.Request())

    def _get_auth_token(self) -> str:
        """Get current auth token, refreshing if needed"""
        self._refresh_token_if_needed()
        return self._credentials.token

    async def evaluate(self, input: JudgeInput) -> JudgeOutput:
        """Evaluate a single sample using Mistral judge via Vertex AI rawPredict"""
        start_time = time.perf_counter()

        # Build the prompt
        gt_dict = input.ground_truth.model_dump()
        prompt = build_judge_prompt(
            code=input.code,
            ground_truth=gt_dict,
            response_content=input.response_content,
            language=input.language
        )

        # Build request payload (Mistral chat format)
        payload = {
            "model": self.config.model_id,
            "messages": [
                {"role": "system", "content": JUDGE_SYSTEM_PROMPT},
                {"role": "user", "content": prompt + "\n\nRespond with valid JSON only."}
            ],
            "temperature": self.config.temperature,
            "max_tokens": self.config.max_tokens,
        }

        # Make async HTTP request
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self._get_auth_token()}"
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(
                self.endpoint_url,
                json=payload,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=self.config.timeout)
            ) as response:
                if response.status != 200:
                    error_text = await response.text()
                    raise Exception(f"Mistral API error {response.status}: {error_text}")

                result = await response.json()

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Extract response content
        content = result["choices"][0]["message"]["content"]

        # Parse JSON response
        judge_data = self._parse_judge_response(content)

        # Extract token usage
        usage = result.get("usage", {})
        input_tokens = usage.get("prompt_tokens", 0)
        output_tokens = usage.get("completion_tokens", 0)

        # Calculate cost
        cost = (
            input_tokens * self.config.cost_per_input_token +
            output_tokens * self.config.cost_per_output_token
        )

        # Build output
        return self._build_output(
            input=input,
            judge_data=judge_data,
            latency_ms=latency_ms,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cost=cost
        )

    def _parse_judge_response(self, content: str) -> dict:
        """Parse the judge's JSON response"""
        # Try to extract JSON from markdown code blocks if present
        if "```json" in content:
            start = content.find("```json") + 7
            end = content.find("```", start)
            content = content[start:end].strip()
        elif "```" in content:
            start = content.find("```") + 3
            end = content.find("```", start)
            content = content[start:end].strip()

        return json.loads(content)

    def _build_output(
        self,
        input: JudgeInput,
        judge_data: dict,
        latency_ms: float,
        input_tokens: int,
        output_tokens: int,
        cost: float
    ) -> JudgeOutput:
        """Build JudgeOutput from parsed judge response"""

        # Parse findings
        findings = []
        for f in judge_data.get("findings", []):
            findings.append(FindingEvaluation(
                finding_id=f["finding_id"],
                description=f["description"],
                vulnerability_type_claimed=f.get("vulnerability_type_claimed"),
                severity_claimed=f.get("severity_claimed"),
                location_claimed=f.get("location_claimed"),
                matches_target=f["matches_target"],
                is_valid_concern=f["is_valid_concern"],
                classification=FindingClassification(f["classification"]),
                reasoning=f["reasoning"]
            ))

        # Parse target assessment
        ta_data = judge_data.get("target_assessment", {})

        rcir = None
        rcir_data = ta_data.get("root_cause_identification")
        if rcir_data and rcir_data.get("score") is not None and rcir_data.get("reasoning") is not None:
            rcir = ReasoningScore(
                score=rcir_data["score"],
                reasoning=rcir_data["reasoning"]
            )

        ava = None
        ava_data = ta_data.get("attack_vector_validity")
        if ava_data and ava_data.get("score") is not None and ava_data.get("reasoning") is not None:
            ava = ReasoningScore(
                score=ava_data["score"],
                reasoning=ava_data["reasoning"]
            )

        fsv = None
        fsv_data = ta_data.get("fix_suggestion_validity")
        if fsv_data and fsv_data.get("score") is not None and fsv_data.get("reasoning") is not None:
            fsv = ReasoningScore(
                score=fsv_data["score"],
                reasoning=fsv_data["reasoning"]
            )

        target_assessment = TargetVulnerabilityAssessment(
            found=ta_data.get("found", False),
            finding_id=ta_data.get("finding_id"),
            type_match=TypeMatchLevel(ta_data.get("type_match", "not_mentioned")),
            type_match_reasoning=ta_data.get("type_match_reasoning", ""),
            root_cause_identification=rcir,
            attack_vector_validity=ava,
            fix_suggestion_validity=fsv
        )

        return JudgeOutput(
            sample_id=input.sample_id,
            transformed_id=input.transformed_id,
            prompt_type=input.prompt_type,
            judge_model=self.config.name,
            timestamp=datetime.now(),
            overall_verdict=judge_data.get("overall_verdict", {}),
            findings=findings,
            target_assessment=target_assessment,
            summary=judge_data.get("summary", {}),
            notes=judge_data.get("notes"),
            judge_latency_ms=latency_ms,
            judge_input_tokens=input_tokens,
            judge_output_tokens=output_tokens,
            judge_cost_usd=cost
        )
