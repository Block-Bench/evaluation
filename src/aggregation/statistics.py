"""
Statistical analysis for BlockBench evaluation.

Provides statistical tests and confidence intervals for metrics.
"""

import math
from dataclasses import dataclass
from typing import Optional


@dataclass
class ConfidenceInterval:
    """Confidence interval for a metric."""
    metric_name: str
    point_estimate: float
    lower_bound: float
    upper_bound: float
    confidence_level: float  # e.g., 0.95
    sample_size: int


@dataclass
class StatisticalTest:
    """Result of a statistical test."""
    test_name: str
    statistic: float
    p_value: float
    significant: bool  # At alpha=0.05
    effect_size: Optional[float]
    interpretation: str


def wilson_score_interval(
    successes: int,
    total: int,
    confidence: float = 0.95
) -> tuple[float, float]:
    """
    Calculate Wilson score confidence interval for proportions.

    Better than normal approximation for small samples or extreme proportions.

    Args:
        successes: Number of successes
        total: Total trials
        confidence: Confidence level (default 0.95)

    Returns:
        Tuple of (lower_bound, upper_bound)
    """
    if total == 0:
        return (0.0, 0.0)

    # Z-score for confidence level
    z_scores = {0.90: 1.645, 0.95: 1.96, 0.99: 2.576}
    z = z_scores.get(confidence, 1.96)

    p_hat = successes / total
    n = total

    denominator = 1 + z ** 2 / n
    center = (p_hat + z ** 2 / (2 * n)) / denominator
    margin = z * math.sqrt((p_hat * (1 - p_hat) + z ** 2 / (4 * n)) / n) / denominator

    lower = max(0.0, center - margin)
    upper = min(1.0, center + margin)

    return (lower, upper)


def bootstrap_confidence_interval(
    values: list[float],
    confidence: float = 0.95,
    n_bootstrap: int = 1000,
    statistic: str = "mean"
) -> tuple[float, float]:
    """
    Calculate bootstrap confidence interval.

    Args:
        values: List of values to bootstrap
        confidence: Confidence level
        n_bootstrap: Number of bootstrap samples
        statistic: "mean" or "median"

    Returns:
        Tuple of (lower_bound, upper_bound)
    """
    import random

    if not values:
        return (0.0, 0.0)

    n = len(values)
    bootstrap_stats = []

    for _ in range(n_bootstrap):
        sample = [random.choice(values) for _ in range(n)]
        if statistic == "mean":
            stat = sum(sample) / n
        else:  # median
            sorted_sample = sorted(sample)
            mid = n // 2
            stat = sorted_sample[mid] if n % 2 else (sorted_sample[mid-1] + sorted_sample[mid]) / 2
        bootstrap_stats.append(stat)

    bootstrap_stats.sort()
    alpha = 1 - confidence
    lower_idx = int(alpha / 2 * n_bootstrap)
    upper_idx = int((1 - alpha / 2) * n_bootstrap)

    return (bootstrap_stats[lower_idx], bootstrap_stats[upper_idx])


def calculate_cohens_kappa(
    ratings_a: list,
    ratings_b: list
) -> float:
    """
    Calculate Cohen's Kappa for inter-rater agreement.

    Args:
        ratings_a: Ratings from evaluator A
        ratings_b: Ratings from evaluator B

    Returns:
        Kappa coefficient (-1 to 1)
    """
    if len(ratings_a) != len(ratings_b) or len(ratings_a) == 0:
        return 0.0

    n = len(ratings_a)

    # Get all unique categories
    categories = list(set(ratings_a) | set(ratings_b))

    # Build confusion matrix
    matrix = {}
    for cat_a in categories:
        for cat_b in categories:
            matrix[(cat_a, cat_b)] = sum(
                1 for a, b in zip(ratings_a, ratings_b)
                if a == cat_a and b == cat_b
            )

    # Calculate observed agreement
    observed = sum(matrix.get((c, c), 0) for c in categories) / n

    # Calculate expected agreement
    expected = 0.0
    for cat in categories:
        p_a = sum(1 for a in ratings_a if a == cat) / n
        p_b = sum(1 for b in ratings_b if b == cat) / n
        expected += p_a * p_b

    # Cohen's Kappa
    if expected == 1.0:
        return 1.0
    return (observed - expected) / (1 - expected)


def interpret_kappa(kappa: float) -> str:
    """Interpret Cohen's Kappa value."""
    if kappa < 0:
        return "Poor (less than chance agreement)"
    elif kappa < 0.20:
        return "Slight agreement"
    elif kappa < 0.40:
        return "Fair agreement"
    elif kappa < 0.60:
        return "Moderate agreement"
    elif kappa < 0.80:
        return "Substantial agreement"
    else:
        return "Almost perfect agreement"


def mcnemar_test(
    contingency: tuple[int, int, int, int]
) -> StatisticalTest:
    """
    McNemar's test for paired nominal data.

    Used to compare two models on the same samples.

    Args:
        contingency: (both_correct, a_only_correct, b_only_correct, neither_correct)

    Returns:
        StatisticalTest result
    """
    _, b, c, _ = contingency

    # McNemar statistic with continuity correction
    if b + c == 0:
        return StatisticalTest(
            test_name="McNemar",
            statistic=0.0,
            p_value=1.0,
            significant=False,
            effect_size=0.0,
            interpretation="No discordant pairs"
        )

    chi_squared = (abs(b - c) - 1) ** 2 / (b + c)

    # Approximate p-value (chi-squared with df=1)
    # Using simple approximation
    p_value = math.exp(-chi_squared / 2)

    return StatisticalTest(
        test_name="McNemar",
        statistic=chi_squared,
        p_value=p_value,
        significant=p_value < 0.05,
        effect_size=(b - c) / (b + c) if b + c > 0 else 0,
        interpretation=f"Chi-squared={chi_squared:.3f}, p={p_value:.4f}"
    )


def calculate_detection_metrics_with_ci(
    detections: list[bool],
    confidence: float = 0.95
) -> ConfidenceInterval:
    """
    Calculate detection rate with confidence interval.

    Args:
        detections: List of boolean detection results
        confidence: Confidence level

    Returns:
        ConfidenceInterval
    """
    successes = sum(detections)
    total = len(detections)
    point_estimate = successes / total if total > 0 else 0.0

    lower, upper = wilson_score_interval(successes, total, confidence)

    return ConfidenceInterval(
        metric_name="detection_rate",
        point_estimate=point_estimate,
        lower_bound=lower,
        upper_bound=upper,
        confidence_level=confidence,
        sample_size=total
    )
