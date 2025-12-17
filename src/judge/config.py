"""
Configuration for the LLM Judge system.
"""

from pydantic import BaseModel
from typing import Optional, Literal
import yaml
from pathlib import Path


class JudgeModelConfig(BaseModel):
    """Configuration for the LLM Judge model"""

    # Model identification
    name: str
    provider: Literal["mistral", "vertex_mistral", "openai", "anthropic", "google"]
    model_id: str

    # Connection settings (for Vertex AI)
    region: Optional[str] = None
    project_id: Optional[str] = None

    # Generation parameters
    max_tokens: int = 4096
    temperature: float = 0.0
    timeout: int = 120

    # Retry configuration
    max_retries: int = 3
    retry_delay: float = 2.0

    # Cost tracking
    cost_per_input_token: float
    cost_per_output_token: float

    # Capabilities
    supports_json_mode: bool = True

    @classmethod
    def from_yaml(cls, path: str | Path) -> "JudgeModelConfig":
        """Load config from YAML file"""
        with open(path) as f:
            data = yaml.safe_load(f)
        return cls(**data)


class JudgeConfig(BaseModel):
    """Main configuration for judge evaluation"""

    # Model config path
    model_config_path: str = "config/judge/mistral-medium-3.yaml"

    # Execution settings
    max_concurrency: int = 5
    checkpoint_every: int = 10
    timeout_per_sample: int = 180

    # Input/Output paths
    eval_output_dir: str = "output"  # Where model evaluation results are
    judge_output_dir: str = "judge_output"

    # Options
    save_raw_outputs: bool = True
    generate_summary_report: bool = True

    @classmethod
    def from_yaml(cls, path: str | Path) -> "JudgeConfig":
        """Load config from YAML file"""
        with open(path) as f:
            data = yaml.safe_load(f)
        return cls(**data)
