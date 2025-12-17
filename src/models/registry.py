"""
Model registry for creating model clients from configuration.
"""

from pathlib import Path
from typing import Type, Optional
import yaml

from .base import BaseModelClient, VertexModelConfig


class ModelRegistry:
    """Factory for creating model clients from configuration."""

    _providers: dict[str, Type[BaseModelClient]] = {}

    @classmethod
    def register(cls, provider: str):
        """
        Decorator to register a model client class.

        Usage:
            @ModelRegistry.register("deepseek")
            class DeepSeekClient(BaseModelClient):
                ...
        """

        def decorator(client_class: Type[BaseModelClient]):
            cls._providers[provider] = client_class
            return client_class

        return decorator

    @classmethod
    def create(cls, config: VertexModelConfig) -> BaseModelClient:
        """
        Create a model client from configuration.

        Args:
            config: Model configuration

        Returns:
            Initialized model client

        Raises:
            ValueError: If provider is not registered
        """
        if config.provider not in cls._providers:
            available = list(cls._providers.keys())
            raise ValueError(
                f"Unknown provider: {config.provider}. Available: {available}"
            )
        return cls._providers[config.provider](config)

    @classmethod
    def from_yaml(cls, config_path: Path | str) -> BaseModelClient:
        """
        Load model from YAML config file.

        Args:
            config_path: Path to YAML config file

        Returns:
            Initialized model client
        """
        config_path = Path(config_path)
        with open(config_path) as f:
            config_dict = yaml.safe_load(f)

        config = VertexModelConfig(**config_dict)
        return cls.create(config)

    @classmethod
    def load_config(cls, config_path: Path | str) -> VertexModelConfig:
        """
        Load model configuration without creating client.

        Args:
            config_path: Path to YAML config file

        Returns:
            Model configuration
        """
        config_path = Path(config_path)
        with open(config_path) as f:
            config_dict = yaml.safe_load(f)

        return VertexModelConfig(**config_dict)

    @classmethod
    def list_providers(cls) -> list[str]:
        """List all registered providers."""
        return list(cls._providers.keys())

    @classmethod
    def load_all(
        cls, config_dir: Path | str
    ) -> dict[str, BaseModelClient]:
        """
        Load all model configs from a directory.

        Args:
            config_dir: Directory containing YAML config files

        Returns:
            Dict mapping model name to client
        """
        config_dir = Path(config_dir)
        models = {}

        for config_file in config_dir.glob("*.yaml"):
            try:
                client = cls.from_yaml(config_file)
                models[client.config.name] = client
            except Exception as e:
                print(f"Warning: Failed to load {config_file}: {e}")

        return models
