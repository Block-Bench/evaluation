"""
DeepSeek model client via Vertex AI MaaS (OpenAI-compatible API).
"""

import os
import time
from typing import Optional

from openai import OpenAI
import google.auth
import google.auth.transport.requests

from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry


@ModelRegistry.register("deepseek")
class VertexDeepSeekClient(BaseModelClient):
    """DeepSeek models via Vertex AI (OpenAI-compatible endpoint)."""

    def _setup_client(self):
        """Initialize the OpenAI client with Vertex AI credentials."""
        # Get credentials from Application Default Credentials
        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        # Use configured project or fall back to ADC project
        project_id = (
            self.config.project_id
            or os.environ.get("GOOGLE_CLOUD_PROJECT")
            or project
        )

        if not project_id:
            raise ValueError(
                "No project ID found. Set GOOGLE_CLOUD_PROJECT or configure project_id."
            )

        # Construct Vertex AI endpoint URL
        # Global region uses a different base URL format
        if self.config.region == "global":
            base_url = (
                f"https://aiplatform.googleapis.com/v1/"
                f"projects/{project_id}/locations/global/endpoints/openapi"
            )
        else:
            base_url = (
                f"https://{self.config.region}-aiplatform.googleapis.com/v1/"
                f"projects/{project_id}/locations/{self.config.region}/endpoints/openapi"
            )

        self.client = OpenAI(
            base_url=base_url,
            api_key=credentials.token,
        )

        self._credentials = credentials
        self._project_id = project_id

    def _refresh_token_if_needed(self):
        """Refresh access token if expired."""
        if self._credentials.expired:
            self._credentials.refresh(google.auth.transport.requests.Request())
            self.client.api_key = self._credentials.token

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate a response from DeepSeek via Vertex AI.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            json_mode: Request JSON output (added as instruction since not natively supported)

        Returns:
            ModelResponse with content and metadata
        """
        start_time = time.perf_counter()

        # Refresh token if needed
        self._refresh_token_if_needed()

        # Build messages
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        # Add JSON instruction if requested (DeepSeek doesn't have native JSON mode)
        user_content = prompt
        if json_mode:
            user_content = prompt + "\n\nRespond with valid JSON only, no other text."

        messages.append({"role": "user", "content": user_content})

        # Make API call (synchronous - OpenAI client)
        # Note: Running sync in async context; consider using httpx for true async
        response = self.client.chat.completions.create(
            model=self.config.model_id,
            messages=messages,
            max_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        return ModelResponse(
            content=response.choices[0].message.content or "",
            model_id=self.config.model_id,
            input_tokens=response.usage.prompt_tokens,
            output_tokens=response.usage.completion_tokens,
            latency_ms=latency_ms,
            finish_reason=response.choices[0].finish_reason or "unknown",
            raw_response=response.model_dump(),
        )
