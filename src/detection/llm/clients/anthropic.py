"""
Anthropic Claude API client.
"""

import os
import time
from typing import Optional

from .base import BaseLLMClient, LLMResponse

try:
    import anthropic
except ImportError:
    anthropic = None


# Pricing per 1M tokens (as of Jan 2026)
CLAUDE_PRICING = {
    "claude-opus-4-5-20251101": {"input": 15.0, "output": 75.0},
    "claude-sonnet-4-20250514": {"input": 3.0, "output": 15.0},
    "claude-3-5-sonnet-20241022": {"input": 3.0, "output": 15.0},
    "claude-3-5-haiku-20241022": {"input": 0.80, "output": 4.0},
}


class AnthropicClient(BaseLLMClient):
    """Client for Anthropic Claude API."""

    def __init__(
        self,
        model_name: str = "claude-sonnet-4-20250514",
        api_key: Optional[str] = None
    ):
        super().__init__(model_name, api_key or os.getenv("ANTHROPIC_API_KEY"))

        if anthropic is None:
            raise ImportError("anthropic package not installed. Run: pip install anthropic")

        self.client = anthropic.Anthropic(api_key=self.api_key)

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """Generate response using Claude."""
        start_time = time.time()

        response = self.client.messages.create(
            model=self.model_name,
            max_tokens=max_tokens,
            temperature=temperature,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}]
        )

        latency_ms = (time.time() - start_time) * 1000

        input_tokens = response.usage.input_tokens
        output_tokens = response.usage.output_tokens
        cost = self.calculate_cost(input_tokens, output_tokens)

        return LLMResponse(
            content=response.content[0].text,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=cost,
            model=self.model_name,
            finish_reason=response.stop_reason
        )

    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate cost based on Claude pricing."""
        pricing = CLAUDE_PRICING.get(
            self.model_name,
            {"input": 3.0, "output": 15.0}  # Default to Sonnet pricing
        )
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost
