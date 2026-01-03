"""
Model configuration loader.

Reads YAML config files and creates appropriate LLM clients.
"""

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict, Any

import yaml

from .clients.base import BaseLLMClient
from .clients.vertex import VertexAIClient
from .clients.openrouter import OpenRouterClient


@dataclass
class ModelConfig:
    """Configuration for a single LLM model."""
    name: str
    provider: str
    model_id: str
    region: str
    max_tokens: int = 4096
    temperature: float = 0.0
    timeout: int = 180
    max_retries: int = 3
    retry_delay: float = 2.0
    cost_per_input_token: float = 0.0
    cost_per_output_token: float = 0.0
    supports_json_mode: bool = False
    extra_params: Dict[str, Any] = None

    def __post_init__(self):
        if self.extra_params is None:
            self.extra_params = {}


def load_model_config(config_path: Path) -> ModelConfig:
    """Load a model configuration from a YAML file."""
    with open(config_path) as f:
        data = yaml.safe_load(f)

    return ModelConfig(
        name=data.get("name", config_path.stem),
        provider=data.get("provider", "unknown"),
        model_id=data.get("model_id", ""),
        region=data.get("region", "global"),
        max_tokens=data.get("max_tokens", 4096),
        temperature=data.get("temperature", 0.0),
        timeout=data.get("timeout", 180),
        max_retries=data.get("max_retries", 3),
        retry_delay=data.get("retry_delay", 2.0),
        cost_per_input_token=data.get("cost_per_input_token", 0.0),
        cost_per_output_token=data.get("cost_per_output_token", 0.0),
        supports_json_mode=data.get("supports_json_mode", False),
        extra_params=data.get("extra_params", {}),
    )


def load_all_model_configs(config_dir: Optional[Path] = None) -> Dict[str, ModelConfig]:
    """Load all model configurations from a directory."""
    if config_dir is None:
        # Default to project config/models directory
        config_dir = Path(__file__).parents[3] / "config" / "models"

    configs = {}
    for config_file in config_dir.glob("*.yaml"):
        config = load_model_config(config_file)
        # Use filename (without extension) as key
        key = config_file.stem
        configs[key] = config

    return configs


def create_client_from_config(config: ModelConfig) -> BaseLLMClient:
    """
    Create an LLM client from a model configuration.

    Routes to the appropriate client based on provider.
    """
    provider = config.provider.lower()

    if provider in ("vertex_anthropic", "vertex_google", "deepseek", "vertex_llama"):
        # Vertex AI providers
        endpoint = config.extra_params.get("endpoint")
        return VertexAIClient(
            model_id=config.model_id,
            provider=provider,
            region=config.region,
            endpoint=endpoint,
        )

    elif provider == "openrouter":
        # OpenRouter provider
        app_name = config.extra_params.get("app_name", "BlockBench")
        reasoning = config.extra_params.get("reasoning")  # e.g., {"enabled": True}
        return OpenRouterClient(
            model_id=config.model_id,
            app_name=app_name,
            reasoning=reasoning,
        )

    else:
        raise ValueError(f"Unknown provider: {provider}")


def get_client(model_name: str, config_dir: Optional[Path] = None) -> BaseLLMClient:
    """
    Get an LLM client by model name.

    Loads the config and creates the appropriate client.

    Args:
        model_name: Name of the model (matches config filename without .yaml)
        config_dir: Optional config directory path

    Returns:
        Configured LLM client
    """
    if config_dir is None:
        config_dir = Path(__file__).parents[3] / "config" / "models"

    config_path = config_dir / f"{model_name}.yaml"
    if not config_path.exists():
        raise FileNotFoundError(f"Model config not found: {config_path}")

    config = load_model_config(config_path)
    return create_client_from_config(config)


# Pre-defined model shortcuts for the 8 benchmark models
BENCHMARK_MODELS = [
    # Vertex AI
    "claude-opus-4-5",
    "gemini-3-pro",
    "deepseek-v3-2",
    "llama-4-maverick",
    # OpenRouter
    "gpt-5.2",
    "o3",
    "grok-4",
    "qwen3-coder-plus",
]


def get_benchmark_clients(config_dir: Optional[Path] = None) -> Dict[str, BaseLLMClient]:
    """
    Get all benchmark model clients.

    Returns:
        Dict mapping model name to client
    """
    clients = {}
    for model_name in BENCHMARK_MODELS:
        try:
            clients[model_name] = get_client(model_name, config_dir)
        except FileNotFoundError:
            print(f"Warning: Config not found for {model_name}")
    return clients
