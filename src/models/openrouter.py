"""
OpenRouter model client for GPT, Grok, Llama and other models.

OpenRouter provides a unified API for multiple model providers.
Uses OpenAI-compatible API format.
"""

import os
import time
from typing import Optional

from openai import OpenAI

from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry


@ModelRegistry.register("openrouter")
class OpenRouterClient(BaseModelClient):
    """Model client for OpenRouter API."""

    OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

    def _setup_client(self):
        """Initialize the OpenRouter client."""
        # Get API key from config or environment
        api_key = self.config.extra_params.get(
            "api_key"
        ) or os.environ.get("OPENROUTER_API_KEY")

        if not api_key:
            raise ValueError(
                "No OpenRouter API key found. Set OPENROUTER_API_KEY environment variable "
                "or configure api_key in extra_params."
            )

        self.client = OpenAI(
            base_url=self.OPENROUTER_BASE_URL,
            api_key=api_key,
        )

        # Optional: Set site URL and app name for OpenRouter rankings
        self._site_url = self.config.extra_params.get("site_url", "")
        self._app_name = self.config.extra_params.get("app_name", "BlockBench")

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate a response via OpenRouter.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            json_mode: Request JSON output

        Returns:
            ModelResponse with content and metadata
        """
        start_time = time.perf_counter()

        # Build messages
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        # Add JSON instruction if requested and model doesn't support native JSON mode
        user_content = prompt
        if json_mode and not self.config.supports_json_mode:
            user_content = prompt + "\n\nRespond with valid JSON only, no other text."

        messages.append({"role": "user", "content": user_content})

        # Build request kwargs
        kwargs = {
            "model": self.config.model_id,
            "messages": messages,
            "max_tokens": self.config.max_tokens,
            "temperature": self.config.temperature,
        }

        # Add JSON mode if supported
        if json_mode and self.config.supports_json_mode:
            kwargs["response_format"] = {"type": "json_object"}

        # Add OpenRouter-specific headers
        extra_headers = {}
        if self._site_url:
            extra_headers["HTTP-Referer"] = self._site_url
        if self._app_name:
            extra_headers["X-Title"] = self._app_name

        if extra_headers:
            kwargs["extra_headers"] = extra_headers

        # Make API call (synchronous - OpenAI client)
        response = self.client.chat.completions.create(**kwargs)

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Extract content from response
        content = ""
        if response.choices:
            content = response.choices[0].message.content or ""

        # Get token counts
        input_tokens = response.usage.prompt_tokens if response.usage else 0
        output_tokens = response.usage.completion_tokens if response.usage else 0

        # Get finish reason
        finish_reason = "unknown"
        if response.choices:
            finish_reason = response.choices[0].finish_reason or "unknown"

        return ModelResponse(
            content=content,
            model_id=self.config.model_id,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            finish_reason=finish_reason,
            raw_response=response.model_dump() if hasattr(response, 'model_dump') else None,
        )
