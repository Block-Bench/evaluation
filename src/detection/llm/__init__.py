"""
LLM-based vulnerability detection.
"""

from .clients import (
    BaseLLMClient,
    LLMResponse,
    AnthropicClient,
    OpenAIClient,
    GoogleClient,
)
from .prompts import (
    BasePromptBuilder,
    PromptPair,
    DSDirectPromptBuilder,
    DSNaturalisticPromptBuilder,
    DSAdversarialPromptBuilder,
)
from .parser import LLMOutputParser, ParseResult
from .runner import LLMDetectionRunner, DetectionPipeline


__all__ = [
    # Clients
    "BaseLLMClient",
    "LLMResponse",
    "AnthropicClient",
    "OpenAIClient",
    "GoogleClient",
    # Prompts
    "BasePromptBuilder",
    "PromptPair",
    "DSDirectPromptBuilder",
    "DSNaturalisticPromptBuilder",
    "DSAdversarialPromptBuilder",
    # Parser
    "LLMOutputParser",
    "ParseResult",
    # Runner
    "LLMDetectionRunner",
    "DetectionPipeline",
]
