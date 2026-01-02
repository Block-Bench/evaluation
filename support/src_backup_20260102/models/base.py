"""
Abstract base class for model clients.

All model implementations (Vertex AI, direct API, local) inherit from this.
"""

from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Optional
import time


class VertexModelConfig(BaseModel):
    """Configuration for a Vertex AI model."""

    name: str  # Display name
    provider: str  # "anthropic", "google", "deepseek"
    model_id: str  # Vertex AI model identifier
    region: str  # GCP region

    # Optional project ID (uses default if not specified)
    project_id: Optional[str] = None

    # Generation parameters
    max_tokens: int = 4096
    temperature: float = 0.0  # Deterministic by default
    timeout: int = 180  # Seconds

    # Retry configuration
    max_retries: int = 3
    retry_delay: float = 2.0  # Base delay for exponential backoff

    # Cost tracking (per token)
    cost_per_input_token: float = 0.0
    cost_per_output_token: float = 0.0

    # Provider-specific settings
    supports_json_mode: bool = False
    extra_params: dict = {}


class ModelResponse(BaseModel):
    """Standardized response from any model."""

    content: str  # Raw response text
    model_id: str
    input_tokens: int
    output_tokens: int
    latency_ms: float
    finish_reason: str  # "stop", "length", "error"
    raw_response: Optional[dict] = None  # Full API response for debugging


class BaseModelClient(ABC):
    """Abstract base class for all model implementations."""

    def __init__(self, config: VertexModelConfig):
        """
        Initialize the model client.

        Args:
            config: Model configuration
        """
        self.config = config
        self._setup_client()

    @abstractmethod
    def _setup_client(self):
        """Initialize the provider-specific client. Called during __init__."""
        pass

    @abstractmethod
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate a response from the model.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            json_mode: Request JSON output format

        Returns:
            ModelResponse with content and metadata
        """
        pass

    def estimate_cost(self, response: ModelResponse) -> float:
        """
        Calculate cost for a response.

        Args:
            response: Model response with token counts

        Returns:
            Estimated cost in USD
        """
        return (
            response.input_tokens * self.config.cost_per_input_token
            + response.output_tokens * self.config.cost_per_output_token
        )

    async def generate_with_retry(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """
        Generate with automatic retry on transient errors.

        Uses exponential backoff for retries.
        """
        import asyncio

        last_error = None

        for attempt in range(self.config.max_retries + 1):
            try:
                return await self.generate(prompt, system_prompt, json_mode)
            except Exception as e:
                last_error = e
                error_str = str(e).lower()

                # Check if error is retryable
                retryable = any(
                    x in error_str
                    for x in ["rate limit", "timeout", "503", "502", "connection"]
                )

                if not retryable or attempt == self.config.max_retries:
                    raise

                # Exponential backoff
                delay = self.config.retry_delay * (2**attempt)
                print(
                    f"Attempt {attempt + 1} failed: {e}. Retrying in {delay:.1f}s..."
                )
                await asyncio.sleep(delay)

        raise last_error
