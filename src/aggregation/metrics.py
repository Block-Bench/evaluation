"""
Core metrics calculations for BlockBench.

Implements all evaluation metrics at the sample level.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class SampleMetrics:
    """Metrics for a single sample."""
    sample_id: str
    tier: Optional[str]
    dataset_type: str
    model: str
    vulnerability_type: str        # Type of vulnerability (reentrancy, access_control, etc.)

    # Detection metrics
    true_detection: bool           # Correctly identified as vulnerable
    target_found: bool             # Found the specific target vulnerability
    verdict_correct: bool          # Correct overall verdict

    # Finding quality
    total_findings: int
    true_positives: int
    false_positives: int
    hallucinations: int

    # Quality scores (1-5, optional)
    explanation_quality: Optional[int]
    fix_quality: Optional[int]
    attack_scenario_quality: Optional[int]

    # Derived metrics
    @property
    def precision(self) -> float:
        """Precision = TP / (TP + FP)"""
        total = self.true_positives + self.false_positives
        return self.true_positives / total if total > 0 else 0.0

    @property
    def hallucination_rate(self) -> float:
        """Hallucination rate = Hallucinations / Total Findings"""
        return self.hallucinations / self.total_findings if self.total_findings > 0 else 0.0

    @property
    def average_quality(self) -> Optional[float]:
        """Average quality score across all dimensions."""
        scores = [s for s in [
            self.explanation_quality,
            self.fix_quality,
            self.attack_scenario_quality
        ] if s is not None]
        return sum(scores) / len(scores) if scores else None


def calculate_sample_metrics(
    evaluation_result: dict,
    sample_metadata: dict
) -> SampleMetrics:
    """
    Calculate metrics for a single sample from evaluation result.

    Args:
        evaluation_result: EvaluationResult as dict
        sample_metadata: Sample metadata (tier, dataset_type, etc.)

    Returns:
        SampleMetrics instance
    """
    eval_data = evaluation_result.get("evaluation", {})
    findings = evaluation_result.get("findings_analysis", {})
    quality = eval_data.get("quality_scores", {})

    return SampleMetrics(
        sample_id=evaluation_result.get("sample_id", "unknown"),
        tier=sample_metadata.get("tier"),
        dataset_type=sample_metadata.get("dataset_type", "ds"),
        model=evaluation_result.get("detection_model", "unknown"),
        vulnerability_type=sample_metadata.get("vulnerability_type", "unknown"),
        true_detection=eval_data.get("detection_verdict_correct", False),
        target_found=eval_data.get("target_vulnerability_found", False),
        verdict_correct=eval_data.get("detection_verdict_correct", False),
        total_findings=findings.get("total_findings", 0),
        true_positives=findings.get("true_positives", 0),
        false_positives=findings.get("false_positives", 0),
        hallucinations=findings.get("hallucinations", 0),
        explanation_quality=quality.get("explanation"),
        fix_quality=quality.get("fix"),
        attack_scenario_quality=quality.get("attack_scenario")
    )


@dataclass
class AggregatedMetrics:
    """Aggregated metrics for a group of samples."""
    level: str              # "sample", "tier", "dataset_type", "entire_dataset"
    identifier: str         # e.g., "tier1", "ds", "full_dataset"
    sample_count: int

    # Detection rates
    true_detection_rate: float      # % correctly identified as vulnerable
    target_found_rate: float        # % found specific target
    verdict_accuracy: float         # % correct verdicts

    # Precision and errors
    mean_precision: float
    mean_hallucination_rate: float

    # Finding counts
    total_findings: int
    total_true_positives: int
    total_false_positives: int
    total_hallucinations: int

    # Quality metrics (if available)
    mean_explanation_quality: Optional[float]
    mean_fix_quality: Optional[float]
    mean_attack_scenario_quality: Optional[float]
    mean_overall_quality: Optional[float]


def aggregate_metrics(
    sample_metrics: list[SampleMetrics],
    level: str,
    identifier: str
) -> AggregatedMetrics:
    """
    Aggregate metrics from multiple samples.

    Args:
        sample_metrics: List of SampleMetrics
        level: Aggregation level
        identifier: Identifier for this group

    Returns:
        AggregatedMetrics instance
    """
    n = len(sample_metrics)
    if n == 0:
        return AggregatedMetrics(
            level=level,
            identifier=identifier,
            sample_count=0,
            true_detection_rate=0.0,
            target_found_rate=0.0,
            verdict_accuracy=0.0,
            mean_precision=0.0,
            mean_hallucination_rate=0.0,
            total_findings=0,
            total_true_positives=0,
            total_false_positives=0,
            total_hallucinations=0,
            mean_explanation_quality=None,
            mean_fix_quality=None,
            mean_attack_scenario_quality=None,
            mean_overall_quality=None
        )

    # Detection rates
    true_detection_rate = sum(1 for m in sample_metrics if m.true_detection) / n
    target_found_rate = sum(1 for m in sample_metrics if m.target_found) / n
    verdict_accuracy = sum(1 for m in sample_metrics if m.verdict_correct) / n

    # Precision and hallucination rates
    precisions = [m.precision for m in sample_metrics]
    halluc_rates = [m.hallucination_rate for m in sample_metrics]

    mean_precision = sum(precisions) / n
    mean_halluc_rate = sum(halluc_rates) / n

    # Totals
    total_findings = sum(m.total_findings for m in sample_metrics)
    total_tp = sum(m.true_positives for m in sample_metrics)
    total_fp = sum(m.false_positives for m in sample_metrics)
    total_halluc = sum(m.hallucinations for m in sample_metrics)

    # Quality metrics
    exp_scores = [m.explanation_quality for m in sample_metrics if m.explanation_quality]
    fix_scores = [m.fix_quality for m in sample_metrics if m.fix_quality]
    attack_scores = [m.attack_scenario_quality for m in sample_metrics if m.attack_scenario_quality]
    overall_scores = [m.average_quality for m in sample_metrics if m.average_quality]

    return AggregatedMetrics(
        level=level,
        identifier=identifier,
        sample_count=n,
        true_detection_rate=true_detection_rate,
        target_found_rate=target_found_rate,
        verdict_accuracy=verdict_accuracy,
        mean_precision=mean_precision,
        mean_hallucination_rate=mean_halluc_rate,
        total_findings=total_findings,
        total_true_positives=total_tp,
        total_false_positives=total_fp,
        total_hallucinations=total_halluc,
        mean_explanation_quality=sum(exp_scores) / len(exp_scores) if exp_scores else None,
        mean_fix_quality=sum(fix_scores) / len(fix_scores) if fix_scores else None,
        mean_attack_scenario_quality=sum(attack_scores) / len(attack_scores) if attack_scores else None,
        mean_overall_quality=sum(overall_scores) / len(overall_scores) if overall_scores else None
    )
