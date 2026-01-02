"""
Configuration management for BlockBench.
"""

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class PathConfig:
    """Path configuration for the project."""
    project_root: Path = field(default_factory=lambda: Path(__file__).parents[2])

    @property
    def samples_dir(self) -> Path:
        return self.project_root / "samples"

    @property
    def ds_samples(self) -> Path:
        return self.samples_dir / "ds"

    @property
    def tc_samples(self) -> Path:
        return self.samples_dir / "tc"

    @property
    def gs_samples(self) -> Path:
        return self.samples_dir / "gs"

    @property
    def results_dir(self) -> Path:
        return self.project_root / "results"

    @property
    def detection_results(self) -> Path:
        return self.results_dir / "detection"

    @property
    def evaluation_results(self) -> Path:
        return self.results_dir / "detection_evaluation"

    @property
    def schemas_dir(self) -> Path:
        return self.project_root / "schemas"

    @property
    def traditional_tools_dir(self) -> Path:
        return self.project_root / "traditionaltools"


@dataclass
class APIConfig:
    """API configuration for LLM providers."""
    anthropic_api_key: Optional[str] = field(
        default_factory=lambda: os.getenv("ANTHROPIC_API_KEY")
    )
    openai_api_key: Optional[str] = field(
        default_factory=lambda: os.getenv("OPENAI_API_KEY")
    )
    google_api_key: Optional[str] = field(
        default_factory=lambda: os.getenv("GOOGLE_API_KEY")
    )


@dataclass
class DetectionConfig:
    """Configuration for detection runs."""
    temperature: float = 0.0
    max_tokens: int = 4096
    concurrency: int = 5
    timeout_seconds: int = 300
    retry_attempts: int = 3


@dataclass
class EvaluationConfig:
    """Configuration for evaluation runs."""
    judge_model: str = "claude-sonnet-4-20250514"
    judge_temperature: float = 0.0


@dataclass
class BlockBenchConfig:
    """Main configuration class."""
    paths: PathConfig = field(default_factory=PathConfig)
    api: APIConfig = field(default_factory=APIConfig)
    detection: DetectionConfig = field(default_factory=DetectionConfig)
    evaluation: EvaluationConfig = field(default_factory=EvaluationConfig)

    @classmethod
    def from_env(cls) -> "BlockBenchConfig":
        """Create configuration from environment variables."""
        return cls()


# Global config instance
_config: Optional[BlockBenchConfig] = None


def get_config() -> BlockBenchConfig:
    """Get the global configuration instance."""
    global _config
    if _config is None:
        _config = BlockBenchConfig.from_env()
    return _config


def set_config(config: BlockBenchConfig) -> None:
    """Set the global configuration instance."""
    global _config
    _config = config
