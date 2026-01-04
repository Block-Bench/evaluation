"""
OpenRouter unified client for multiple model providers.

Supports all models available via OpenRouter:
- GPT-5.x (OpenAI)
- o3 (OpenAI reasoning)
- Grok 4 (xAI)
- Qwen3-Coder (Alibaba)
- And many more
"""

import os
import time
import requests
from typing import Optional

from .base import BaseLLMClient, LLMResponse


# Pricing per 1M tokens (OpenRouter prices)
OPENROUTER_PRICING = {
    # OpenAI
    "openai/gpt-5.2": {"input": 1.75, "output": 14.0},
    "openai/gpt-5.1": {"input": 1.75, "output": 14.0},
    "openai/gpt-5": {"input": 1.75, "output": 14.0},
    "openai/o3": {"input": 10.0, "output": 40.0},
    "openai/o3-mini": {"input": 1.10, "output": 4.40},
    # xAI Grok
    "x-ai/grok-4": {"input": 3.0, "output": 15.0},
    "x-ai/grok-4-fast": {"input": 1.0, "output": 5.0},  # 3x cheaper, used with reasoning
    # Qwen
    "qwen/qwen3-coder-plus": {"input": 0.30, "output": 0.60},
    "qwen/qwen3-235b-a22b": {"input": 0.50, "output": 1.0},
}


class OpenRouterClient(BaseLLMClient):
    """
    Client for OpenRouter API.

    OpenRouter provides a unified API for accessing multiple LLM providers
    with OpenAI-compatible format.
    """

    def __init__(
        self,
        model_id: str,
        api_key: Optional[str] = None,
        app_name: str = "BlockBench",
        site_url: Optional[str] = None,
        reasoning: Optional[dict] = None,
    ):
        super().__init__(model_name=model_id, api_key=api_key)
        self.model_id = model_id
        self.api_key = api_key or os.getenv("OPENROUTER_API_KEY")
        self.app_name = app_name
        self.site_url = site_url
        self.reasoning = reasoning  # e.g., {"enabled": True}

        if not self.api_key:
            raise ValueError("OPENROUTER_API_KEY environment variable not set")

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """Generate response using OpenRouter API."""

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": self.site_url or "https://github.com/blockbench",
            "X-Title": self.app_name,
        }

        # Handle o3 special requirements
        actual_temp = temperature
        if "o3" in self.model_id:
            # o3 requires temperature=1 for reasoning
            actual_temp = 1.0

        payload = {
            "model": self.model_id,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": actual_temp,
            "max_tokens": max_tokens
        }

        # Add reasoning config if specified (e.g., for Grok 4 Fast)
        if self.reasoning:
            payload["reasoning"] = self.reasoning

        start_time = time.time()
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=600  # Longer timeout for reasoning models
        )
        latency_ms = (time.time() - start_time) * 1000

        if response.status_code != 200:
            raise Exception(f"API call failed: {response.status_code} - {response.text[:200]}")

        data = response.json()

        # Check for errors in response
        if "error" in data:
            raise Exception(f"OpenRouter error: {data['error']}")

        content = data["choices"][0]["message"]["content"]
        input_tokens = data.get("usage", {}).get("prompt_tokens", 0)
        output_tokens = data.get("usage", {}).get("completion_tokens", 0)
        finish_reason = data["choices"][0].get("finish_reason")

        return LLMResponse(
            content=content,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=self.calculate_cost(input_tokens, output_tokens),
            model=self.model_id,
            finish_reason=finish_reason
        )

    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate cost in USD."""
        pricing = OPENROUTER_PRICING.get(self.model_id, {"input": 1.0, "output": 2.0})
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost
