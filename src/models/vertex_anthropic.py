"""
Claude model client via Vertex AI.
"""

import os
import time
from typing import Optional

from anthropic import AnthropicVertex

from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry


@ModelRegistry.register("vertex_anthropic")
class VertexAnthropicClient(BaseModelClient):
    """Claude models via Vertex AI."""

    def _setup_client(self):
        """Initialize the Anthropic Vertex client."""
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

        # Initialize Anthropic Vertex client
        self.client = AnthropicVertex(
            project_id=project_id,
            region=self.config.region,
        )

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate a response from Claude via Vertex AI.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            json_mode: Request JSON output (added as instruction)

        Returns:
            ModelResponse with content and metadata
        """
        start_time = time.perf_counter()

        # Build messages
        messages = []

        # Add JSON instruction if requested
        user_content = prompt
        if json_mode:
            user_content = prompt + "\n\nRespond with valid JSON only, no other text."

        messages.append({"role": "user", "content": user_content})

        # Build request kwargs
        kwargs = {
            "model": self.config.model_id,
            "max_tokens": self.config.max_tokens,
            "messages": messages,
        }

        if system_prompt:
            kwargs["system"] = system_prompt

        # Make API call (synchronous - Anthropic client)
        response = self.client.messages.create(**kwargs)

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Extract content from response
        content = ""
        if response.content:
            content = response.content[0].text

        return ModelResponse(
            content=content,
            model_id=self.config.model_id,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            latency_ms=latency_ms,
            finish_reason=response.stop_reason or "unknown",
            raw_response=response.model_dump(),
        )
