"""
BlockBench - Smart Contract Vulnerability Detection Benchmark

A comprehensive benchmark for evaluating LLM and traditional tool performance
on smart contract vulnerability detection.

Modules:
- detection: LLM and traditional tool wrappers for detection
- evaluation: LLM Judge, Rule-Based, and Human evaluation systems
- aggregation: Metrics calculation and hierarchical aggregation
- data: Dataset and results loaders
- utils: Configuration, logging, and utility functions
"""

__version__ = "2.0.0"

from .utils import get_config, setup_logging, get_logger

# Expose key classes at package level
from .detection import (
    # LLM Detection
    LLMDetectionRunner,
    AnthropicClient,
    OpenAIClient,
    GoogleClient,
    DSDirectPromptBuilder,
    # Traditional Detection
    SlitherRunner,
    MythrilRunner,
)

from .evaluation import (
    ClaudeJudge,
    RuleBasedEvaluator,
    HumanReviewInterface,
    DivergenceAnalyzer,
)

from .aggregation import (
    HierarchicalAggregator,
    calculate_sample_metrics,
)

from .data import (
    DSLoader,
    TCLoader,
    GSLoader,
    DetectionResultsLoader,
)


__all__ = [
    # Version
    "__version__",
    # Utils
    "get_config",
    "setup_logging",
    "get_logger",
    # Detection
    "LLMDetectionRunner",
    "AnthropicClient",
    "OpenAIClient",
    "GoogleClient",
    "DSDirectPromptBuilder",
    "SlitherRunner",
    "MythrilRunner",
    # Evaluation
    "ClaudeJudge",
    "RuleBasedEvaluator",
    "HumanReviewInterface",
    "DivergenceAnalyzer",
    # Aggregation
    "HierarchicalAggregator",
    "calculate_sample_metrics",
    # Data
    "DSLoader",
    "TCLoader",
    "GSLoader",
    "DetectionResultsLoader",
]
