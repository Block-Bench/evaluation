"""
LLM-based evaluation (judge) module.
"""

from .base import BaseLLMJudge
from .judge import ClaudeJudge
from .providers import (
    VertexAIHaikuJudge,
    VertexAICodestralJudge,
    OpenRouterJudge,
    create_judge,
)
from .multi_judge import MultiJudgeOrchestrator, MultiJudgeResult, save_multi_judge_result
from .prompts import (
    get_judge_system_prompt,
    get_judge_user_prompt,
    get_traditional_tool_system_prompt,
    get_traditional_tool_user_prompt,
    get_quality_criteria,
)


__all__ = [
    # Base classes
    "BaseLLMJudge",
    "ClaudeJudge",
    # Multi-provider judges
    "VertexAIHaikuJudge",
    "VertexAICodestralJudge",
    "OpenRouterJudge",
    "create_judge",
    # Multi-judge orchestration
    "MultiJudgeOrchestrator",
    "MultiJudgeResult",
    "save_multi_judge_result",
    # Prompts
    "get_judge_system_prompt",
    "get_judge_user_prompt",
    "get_traditional_tool_system_prompt",
    "get_traditional_tool_user_prompt",
    "get_quality_criteria",
]
