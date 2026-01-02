"""
Base class for evaluation systems.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional, Any
from enum import Enum


class EvaluatorType(Enum):
    """Types of evaluators."""
    LLM_JUDGE = "llm_judge"
    RULE_BASED = "rule_based"
    HUMAN = "human"


@dataclass
class EvaluationResult:
    """Result from an evaluation."""
    sample_id: str
    evaluator_type: str
    detection_source: str  # "llm" or "traditional"
    detection_model: str   # Model name or tool name

    # Core evaluation
    detection_verdict_correct: bool
    target_vulnerability_found: bool
    target_finding_id: Optional[str]

    # Quality scores (1-5 scale, where applicable)
    target_explanation_quality: Optional[int]
    target_fix_quality: Optional[int]
    target_attack_scenario_quality: Optional[int]

    # Findings analysis
    total_findings: int
    true_positives: int
    false_positives: int
    hallucinations: int

    # Metadata
    evaluator_model: Optional[str] = None  # For LLM judge
    confidence: Optional[float] = None
    reasoning: Optional[str] = None
    timestamp: Optional[str] = None


class BaseEvaluator(ABC):
    """Abstract base class for evaluation systems."""

    def __init__(self, evaluator_type: EvaluatorType):
        self.evaluator_type = evaluator_type

    @abstractmethod
    def evaluate(
        self,
        detection_output: dict,
        ground_truth: dict,
        **kwargs
    ) -> EvaluationResult:
        """
        Evaluate a detection output against ground truth.

        Args:
            detection_output: The detection result to evaluate
            ground_truth: Ground truth vulnerability information
            **kwargs: Additional evaluation parameters

        Returns:
            EvaluationResult with evaluation details
        """
        pass

    @abstractmethod
    def evaluate_batch(
        self,
        detection_outputs: list[dict],
        ground_truths: list[dict],
        **kwargs
    ) -> list[EvaluationResult]:
        """Evaluate multiple detection outputs."""
        pass

    def create_output_dict(self, result: EvaluationResult) -> dict:
        """Convert EvaluationResult to schema-conformant dictionary."""
        output = {
            "sample_id": result.sample_id,
            "evaluator_type": result.evaluator_type,
            "detection_source": result.detection_source,
            "detection_model": result.detection_model,
            "evaluation": {
                "detection_verdict_correct": result.detection_verdict_correct,
                "target_vulnerability_found": result.target_vulnerability_found,
                "target_finding_id": result.target_finding_id,
                "quality_scores": {
                    "explanation": result.target_explanation_quality,
                    "fix": result.target_fix_quality,
                    "attack_scenario": result.target_attack_scenario_quality
                }
            },
            "findings_analysis": {
                "total_findings": result.total_findings,
                "true_positives": result.true_positives,
                "false_positives": result.false_positives,
                "hallucinations": result.hallucinations
            },
            "metadata": {
                "evaluator_model": result.evaluator_model,
                "confidence": result.confidence,
                "reasoning": result.reasoning,
                "timestamp": result.timestamp
            }
        }
        return output
