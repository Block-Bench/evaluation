"""
Vulnerability detection module.

Contains both LLM-based and traditional static analysis tool wrappers.
"""

from .llm import (
    # Clients
    BaseLLMClient,
    LLMResponse,
    AnthropicClient,
    OpenAIClient,
    GoogleClient,
    # Prompts
    BasePromptBuilder,
    PromptPair,
    DSDirectPromptBuilder,
    DSNaturalisticPromptBuilder,
    DSAdversarialPromptBuilder,
    # Parser & Runner
    LLMOutputParser,
    ParseResult,
    LLMDetectionRunner,
    DetectionPipeline,
)
from .traditional import (
    BaseToolRunner,
    SlitherRunner,
    MythrilRunner,
)


__all__ = [
    # LLM Detection
    "BaseLLMClient",
    "LLMResponse",
    "AnthropicClient",
    "OpenAIClient",
    "GoogleClient",
    "BasePromptBuilder",
    "PromptPair",
    "DSDirectPromptBuilder",
    "DSNaturalisticPromptBuilder",
    "DSAdversarialPromptBuilder",
    "LLMOutputParser",
    "ParseResult",
    "LLMDetectionRunner",
    "DetectionPipeline",
    # Traditional Detection
    "BaseToolRunner",
    "SlitherRunner",
    "MythrilRunner",
]
