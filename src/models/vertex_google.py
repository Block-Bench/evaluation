"""
Gemini model client via Vertex AI using google-genai SDK.
"""

import os
import time
from typing import Optional

from google import genai
from google.genai import types

from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry


@ModelRegistry.register("vertex_google")
class VertexGoogleClient(BaseModelClient):
    """Gemini models via Vertex AI using the new google-genai SDK."""

    def _setup_client(self):
        """Initialize the Google GenAI client for Vertex AI."""
        # Get project ID
        project_id = (
            self.config.project_id
            or os.environ.get("GOOGLE_CLOUD_PROJECT")
        )

        if not project_id:
            raise ValueError(
                "No project ID found. Set GOOGLE_CLOUD_PROJECT or configure project_id."
            )

        self._project_id = project_id
        self._location = self.config.region

        # Initialize the genai client for Vertex AI
        self.client = genai.Client(
            vertexai=True,
            project=project_id,
            location=self._location,
        )

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate a response from Gemini via Vertex AI.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            json_mode: Request JSON output

        Returns:
            ModelResponse with content and metadata
        """
        start_time = time.perf_counter()

        # Build the full prompt
        full_prompt = ""
        if system_prompt:
            full_prompt = f"{system_prompt}\n\n"

        full_prompt += prompt

        if json_mode:
            full_prompt += "\n\nRespond with valid JSON only, no other text."

        # Configure generation with thinking disabled (LOW level)
        config = types.GenerateContentConfig(
            max_output_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
            thinking_config=types.ThinkingConfig(
                thinking_level=types.ThinkingLevel.LOW,  # Minimize thinking tokens
            ),
        )

        if json_mode and self.config.supports_json_mode:
            config.response_mime_type = "application/json"

        # Generate response
        response = self.client.models.generate_content(
            model=self.config.model_id,
            contents=full_prompt,
            config=config,
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Extract content
        content = response.text if response.text else ""

        # Get token counts from usage metadata
        input_tokens = 0
        output_tokens = 0
        if hasattr(response, 'usage_metadata') and response.usage_metadata:
            input_tokens = getattr(response.usage_metadata, 'prompt_token_count', 0)
            output_tokens = getattr(response.usage_metadata, 'candidates_token_count', 0)

        # Determine finish reason
        finish_reason = "unknown"
        if response.candidates:
            candidate = response.candidates[0]
            if hasattr(candidate, 'finish_reason'):
                finish_reason = str(candidate.finish_reason).lower()

        return ModelResponse(
            content=content,
            model_id=self.config.model_id,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            finish_reason=finish_reason,
            raw_response={"text": content},
        )
