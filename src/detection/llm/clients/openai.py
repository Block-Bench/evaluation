"""
OpenAI GPT API client.
"""

import os
import time
from typing import Optional

from .base import BaseLLMClient, LLMResponse

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None


# Pricing per 1M tokens (as of Jan 2026)
OPENAI_PRICING = {
    "gpt-4o": {"input": 2.50, "output": 10.0},
    "gpt-4o-mini": {"input": 0.15, "output": 0.60},
    "gpt-4-turbo": {"input": 10.0, "output": 30.0},
    "gpt-4": {"input": 30.0, "output": 60.0},
    "o1": {"input": 15.0, "output": 60.0},
    "o1-mini": {"input": 3.0, "output": 12.0},
}


class OpenAIClient(BaseLLMClient):
    """Client for OpenAI GPT API."""

    def __init__(
        self,
        model_name: str = "gpt-4o",
        api_key: Optional[str] = None
    ):
        super().__init__(model_name, api_key or os.getenv("OPENAI_API_KEY"))

        if OpenAI is None:
            raise ImportError("openai package not installed. Run: pip install openai")

        self.client = OpenAI(api_key=self.api_key)

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """Generate response using GPT."""
        start_time = time.time()

        response = self.client.chat.completions.create(
            model=self.model_name,
            temperature=temperature,
            max_tokens=max_tokens,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        )

        latency_ms = (time.time() - start_time) * 1000

        input_tokens = response.usage.prompt_tokens
        output_tokens = response.usage.completion_tokens
        cost = self.calculate_cost(input_tokens, output_tokens)

        return LLMResponse(
            content=response.choices[0].message.content,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=cost,
            model=self.model_name,
            finish_reason=response.choices[0].finish_reason
        )

    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate cost based on OpenAI pricing."""
        pricing = OPENAI_PRICING.get(
            self.model_name,
            {"input": 2.50, "output": 10.0}  # Default to gpt-4o pricing
        )
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost
