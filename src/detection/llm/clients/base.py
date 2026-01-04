"""
Base class for LLM API clients.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class LLMResponse:
    """Response from an LLM API call."""
    content: str
    input_tokens: int
    output_tokens: int
    latency_ms: float
    cost_usd: float
    model: str
    finish_reason: Optional[str] = None


class BaseLLMClient(ABC):
    """Abstract base class for LLM API clients."""

    def __init__(self, model_name: str, api_key: Optional[str] = None):
        self.model_name = model_name
        self.api_key = api_key

    @abstractmethod
    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """
        Generate a response from the LLM.

        Args:
            system_prompt: System message
            user_prompt: User message
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate

        Returns:
            LLMResponse with content and metadata
        """
        pass

    @abstractmethod
    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """
        Calculate cost in USD for the API call.

        Args:
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens

        Returns:
            Cost in USD
        """
        pass
