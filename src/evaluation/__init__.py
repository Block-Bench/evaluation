"""
Evaluation module for BlockBench.

Contains LLM Judge, Rule-Based, and Human evaluation systems,
plus divergence analysis between evaluators.
"""

from .base import (
    BaseEvaluator,
    EvaluatorType,
    EvaluationResult,
)
from .llm_judge import (
    BaseLLMJudge,
    ClaudeJudge,
    get_judge_system_prompt,
    get_judge_user_prompt,
    get_quality_criteria,
)
from .rule_based import (
    RuleBasedEvaluator,
    VULNERABILITY_ALIASES,
)
from .human import (
    HumanReviewInterface,
)
from .divergence import (
    Divergence,
    DivergenceReport,
    DivergenceAnalyzer,
)


__all__ = [
    # Base
    "BaseEvaluator",
    "EvaluatorType",
    "EvaluationResult",
    # LLM Judge
    "BaseLLMJudge",
    "ClaudeJudge",
    "get_judge_system_prompt",
    "get_judge_user_prompt",
    "get_quality_criteria",
    # Rule-Based
    "RuleBasedEvaluator",
    "VULNERABILITY_ALIASES",
    # Human
    "HumanReviewInterface",
    # Divergence
    "Divergence",
    "DivergenceReport",
    "DivergenceAnalyzer",
]
