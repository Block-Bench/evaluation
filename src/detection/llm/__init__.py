"""
LLM-based vulnerability detection.
"""

from .clients import (
    BaseLLMClient,
    LLMResponse,
    AnthropicClient,
    OpenAIClient,
    GoogleClient,
    VertexAIClient,
    OpenRouterClient,
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
from .model_config import (
    ModelConfig,
    load_model_config,
    load_all_model_configs,
    create_client_from_config,
    get_client,
    get_benchmark_clients,
    BENCHMARK_MODELS,
)


__all__ = [
    # Clients
    "BaseLLMClient",
    "LLMResponse",
    "AnthropicClient",
    "OpenAIClient",
    "GoogleClient",
    "VertexAIClient",
    "OpenRouterClient",
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
    # Model Config
    "ModelConfig",
    "load_model_config",
    "load_all_model_configs",
    "create_client_from_config",
    "get_client",
    "get_benchmark_clients",
    "BENCHMARK_MODELS",
]
