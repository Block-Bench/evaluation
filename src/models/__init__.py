"""
Model clients for various providers.

Import all clients here so they register with the ModelRegistry.
"""

from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry

# Import all provider clients to trigger registration
from .vertex_deepseek import VertexDeepSeekClient
from .vertex_anthropic import VertexAnthropicClient
from .vertex_google import VertexGoogleClient

__all__ = [
    "BaseModelClient",
    "ModelResponse",
    "VertexModelConfig",
    "ModelRegistry",
    "VertexDeepSeekClient",
    "VertexAnthropicClient",
    "VertexGoogleClient",
]
