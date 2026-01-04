"""
Aggregation module for BlockBench.

Provides metrics calculation, hierarchical aggregation, and statistical analysis.
"""

from .metrics import (
    SampleMetrics,
    AggregatedMetrics,
    calculate_sample_metrics,
    aggregate_metrics,
)
from .hierarchical import (
    HierarchicalAggregator,
    create_aggregation_output,
)
from .statistics import (
    ConfidenceInterval,
    StatisticalTest,
    wilson_score_interval,
    bootstrap_confidence_interval,
    calculate_cohens_kappa,
    interpret_kappa,
    mcnemar_test,
    calculate_detection_metrics_with_ci,
)


__all__ = [
    # Metrics
    "SampleMetrics",
    "AggregatedMetrics",
    "calculate_sample_metrics",
    "aggregate_metrics",
    # Hierarchical
    "HierarchicalAggregator",
    "create_aggregation_output",
    # Statistics
    "ConfidenceInterval",
    "StatisticalTest",
    "wilson_score_interval",
    "bootstrap_confidence_interval",
    "calculate_cohens_kappa",
    "interpret_kappa",
    "mcnemar_test",
    "calculate_detection_metrics_with_ci",
]
