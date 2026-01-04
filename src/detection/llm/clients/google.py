"""
Google Gemini API client.
"""

import os
import time
from typing import Optional

from .base import BaseLLMClient, LLMResponse

try:
    import google.generativeai as genai
except ImportError:
    genai = None


# Pricing per 1M tokens (as of Jan 2026)
GEMINI_PRICING = {
    "gemini-2.0-flash": {"input": 0.075, "output": 0.30},
    "gemini-1.5-pro": {"input": 1.25, "output": 5.0},
    "gemini-1.5-flash": {"input": 0.075, "output": 0.30},
}


class GoogleClient(BaseLLMClient):
    """Client for Google Gemini API."""

    def __init__(
        self,
        model_name: str = "gemini-2.0-flash",
        api_key: Optional[str] = None
    ):
        super().__init__(model_name, api_key or os.getenv("GOOGLE_API_KEY"))

        if genai is None:
            raise ImportError(
                "google-generativeai package not installed. "
                "Run: pip install google-generativeai"
            )

        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(model_name)

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """Generate response using Gemini."""
        start_time = time.time()

        # Gemini combines system + user in a single prompt
        combined_prompt = f"{system_prompt}\n\n{user_prompt}"

        generation_config = genai.GenerationConfig(
            temperature=temperature,
            max_output_tokens=max_tokens
        )

        response = self.model.generate_content(
            combined_prompt,
            generation_config=generation_config
        )

        latency_ms = (time.time() - start_time) * 1000

        # Extract token counts
        input_tokens = response.usage_metadata.prompt_token_count
        output_tokens = response.usage_metadata.candidates_token_count
        cost = self.calculate_cost(input_tokens, output_tokens)

        return LLMResponse(
            content=response.text,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=cost,
            model=self.model_name,
            finish_reason=response.candidates[0].finish_reason.name if response.candidates else "unknown"
        )

    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate cost based on Gemini pricing."""
        pricing = GEMINI_PRICING.get(
            self.model_name,
            {"input": 0.075, "output": 0.30}  # Default to Flash pricing
        )
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost
