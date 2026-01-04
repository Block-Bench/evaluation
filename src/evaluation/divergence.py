"""
Divergence analysis between evaluators.

Compares evaluations from different sources (LLM Judge, Rule-Based, Human)
to identify disagreements and analyze patterns.
"""

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

from .base import EvaluationResult


@dataclass
class Divergence:
    """A divergence between two evaluations."""
    sample_id: str
    evaluator_a: str  # e.g., "llm_judge"
    evaluator_b: str  # e.g., "human"
    field: str        # Which field diverges
    value_a: any
    value_b: any
    severity: str     # "critical", "moderate", "minor"
    notes: str = ""


@dataclass
class DivergenceReport:
    """Report comparing two evaluation sources."""
    comparison_type: str  # e.g., "llm_judge_vs_human"
    evaluator_a: str
    evaluator_b: str
    total_samples: int
    agreement_rate: float
    divergences: list[Divergence]
    summary: dict
    timestamp: str


class DivergenceAnalyzer:
    """
    Analyzes divergences between different evaluator types.

    Supports three comparison types:
    - rulebased_vs_judge: Rule-based vs LLM Judge
    - rulebased_vs_human: Rule-based vs Human
    - judge_vs_human: LLM Judge vs Human
    """

    COMPARISON_TYPES = [
        "rulebased_vs_judge",
        "rulebased_vs_human",
        "judge_vs_human"
    ]

    def compare_evaluations(
        self,
        evals_a: list[EvaluationResult],
        evals_b: list[EvaluationResult],
        comparison_type: str
    ) -> DivergenceReport:
        """
        Compare two sets of evaluations.

        Args:
            evals_a: First set of evaluations
            evals_b: Second set of evaluations
            comparison_type: Type of comparison

        Returns:
            DivergenceReport with analysis
        """
        # Build lookup by sample_id
        a_by_id = {e.sample_id: e for e in evals_a}
        b_by_id = {e.sample_id: e for e in evals_b}

        # Find common samples
        common_ids = set(a_by_id.keys()) & set(b_by_id.keys())

        divergences = []
        agreements = 0

        for sample_id in common_ids:
            eval_a = a_by_id[sample_id]
            eval_b = b_by_id[sample_id]

            sample_divergences = self._compare_single(eval_a, eval_b)

            if not sample_divergences:
                agreements += 1
            else:
                divergences.extend(sample_divergences)

        total = len(common_ids)
        agreement_rate = agreements / total if total > 0 else 0.0

        # Generate summary
        summary = self._generate_summary(divergences, total)

        return DivergenceReport(
            comparison_type=comparison_type,
            evaluator_a=evals_a[0].evaluator_type if evals_a else "unknown",
            evaluator_b=evals_b[0].evaluator_type if evals_b else "unknown",
            total_samples=total,
            agreement_rate=agreement_rate,
            divergences=divergences,
            summary=summary,
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    def _compare_single(
        self,
        eval_a: EvaluationResult,
        eval_b: EvaluationResult
    ) -> list[Divergence]:
        """Compare two evaluations of the same sample."""
        divergences = []

        # Critical fields
        if eval_a.target_vulnerability_found != eval_b.target_vulnerability_found:
            divergences.append(Divergence(
                sample_id=eval_a.sample_id,
                evaluator_a=eval_a.evaluator_type,
                evaluator_b=eval_b.evaluator_type,
                field="target_vulnerability_found",
                value_a=eval_a.target_vulnerability_found,
                value_b=eval_b.target_vulnerability_found,
                severity="critical"
            ))

        if eval_a.detection_verdict_correct != eval_b.detection_verdict_correct:
            divergences.append(Divergence(
                sample_id=eval_a.sample_id,
                evaluator_a=eval_a.evaluator_type,
                evaluator_b=eval_b.evaluator_type,
                field="detection_verdict_correct",
                value_a=eval_a.detection_verdict_correct,
                value_b=eval_b.detection_verdict_correct,
                severity="critical"
            ))

        # Moderate: hallucination count difference
        if eval_a.hallucinations != eval_b.hallucinations:
            # Only flag if significant difference
            diff = abs(eval_a.hallucinations - eval_b.hallucinations)
            if diff >= 1:
                divergences.append(Divergence(
                    sample_id=eval_a.sample_id,
                    evaluator_a=eval_a.evaluator_type,
                    evaluator_b=eval_b.evaluator_type,
                    field="hallucinations",
                    value_a=eval_a.hallucinations,
                    value_b=eval_b.hallucinations,
                    severity="moderate"
                ))

        # Compare quality scores if both have them
        if (eval_a.target_explanation_quality is not None and
            eval_b.target_explanation_quality is not None):
            diff = abs(eval_a.target_explanation_quality - eval_b.target_explanation_quality)
            if diff >= 2:  # Significant quality disagreement
                divergences.append(Divergence(
                    sample_id=eval_a.sample_id,
                    evaluator_a=eval_a.evaluator_type,
                    evaluator_b=eval_b.evaluator_type,
                    field="target_explanation_quality",
                    value_a=eval_a.target_explanation_quality,
                    value_b=eval_b.target_explanation_quality,
                    severity="minor"
                ))

        return divergences

    def _generate_summary(
        self,
        divergences: list[Divergence],
        total_samples: int
    ) -> dict:
        """Generate summary statistics for divergences."""
        by_severity = {"critical": 0, "moderate": 0, "minor": 0}
        by_field = {}

        for d in divergences:
            by_severity[d.severity] = by_severity.get(d.severity, 0) + 1
            by_field[d.field] = by_field.get(d.field, 0) + 1

        samples_with_divergence = len(set(d.sample_id for d in divergences))

        return {
            "total_divergences": len(divergences),
            "samples_with_divergence": samples_with_divergence,
            "by_severity": by_severity,
            "by_field": by_field,
            "critical_divergence_rate": by_severity["critical"] / total_samples if total_samples > 0 else 0
        }

    def to_dict(self, report: DivergenceReport) -> dict:
        """Convert DivergenceReport to schema-conformant dict."""
        return {
            "comparison_type": report.comparison_type,
            "evaluator_a": report.evaluator_a,
            "evaluator_b": report.evaluator_b,
            "timestamp": report.timestamp,
            "summary": {
                "total_samples": report.total_samples,
                "agreement_rate": report.agreement_rate,
                **report.summary
            },
            "divergences": [
                {
                    "sample_id": d.sample_id,
                    "evaluator_a": d.evaluator_a,
                    "evaluator_b": d.evaluator_b,
                    "field": d.field,
                    "value_a": d.value_a,
                    "value_b": d.value_b,
                    "severity": d.severity,
                    "notes": d.notes
                }
                for d in report.divergences
            ]
        }
