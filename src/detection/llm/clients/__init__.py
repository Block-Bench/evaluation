"""
LLM API clients for vulnerability detection.
"""

from .base import BaseLLMClient, LLMResponse
from .anthropic import AnthropicClient
from .openai import OpenAIClient
from .google import GoogleClient
from .vertex import VertexAIClient
from .openrouter import OpenRouterClient


__all__ = [
    "BaseLLMClient",
    "LLMResponse",
    # Direct API clients
    "AnthropicClient",
    "OpenAIClient",
    "GoogleClient",
    # Unified clients (recommended for benchmark)
    "VertexAIClient",
    "OpenRouterClient",
]
