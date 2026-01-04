"""
Hierarchical metrics aggregation.

Aggregates metrics at multiple levels:
- Sample level (per individual contract)
- Tier level (per difficulty tier, e.g., tier1, tier2, tier3, tier4)
- Dataset type level (per dataset: ds, tc, gs)
- Entire dataset level (across all samples)
"""

from collections import defaultdict
from dataclasses import asdict
from datetime import datetime, timezone
from typing import Optional

from .metrics import SampleMetrics, AggregatedMetrics, aggregate_metrics


class HierarchicalAggregator:
    """
    Performs hierarchical aggregation of metrics.

    Supports 4 levels:
    1. Sample - Individual contract metrics
    2. Tier - Grouped by difficulty tier (tier1-4 for DS dataset)
    3. Dataset Type - Grouped by dataset (ds, tc, gs)
    4. Entire Dataset - All samples combined
    """

    def __init__(self, model_name: str):
        self.model_name = model_name
        self.sample_metrics: list[SampleMetrics] = []

    def add_sample(self, metrics: SampleMetrics) -> None:
        """Add a sample's metrics to the aggregator."""
        self.sample_metrics.append(metrics)

    def add_samples(self, metrics_list: list[SampleMetrics]) -> None:
        """Add multiple samples' metrics."""
        self.sample_metrics.extend(metrics_list)

    def aggregate_all(self) -> dict:
        """
        Perform full hierarchical aggregation.

        Returns:
            Dict with metrics at all levels
        """
        result = {
            "model": self.model_name,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "levels": {}
        }

        # Level 1: Sample-level (individual metrics)
        result["levels"]["sample"] = {
            m.sample_id: self._metrics_to_dict(m)
            for m in self.sample_metrics
        }

        # Level 2: Tier-level aggregation
        result["levels"]["tier"] = self._aggregate_by_tier()

        # Level 3: Dataset-type aggregation
        result["levels"]["dataset_type"] = self._aggregate_by_dataset_type()

        # Level 4: Entire dataset
        result["levels"]["entire_dataset"] = self._aggregate_entire_dataset()

        # Summary statistics
        result["summary"] = self._generate_summary()

        return result

    def _aggregate_by_tier(self) -> dict:
        """Aggregate metrics by difficulty tier, with vulnerability type breakdown."""
        by_tier = defaultdict(list)

        for m in self.sample_metrics:
            if m.tier:
                by_tier[m.tier].append(m)

        result = {}
        for tier, samples in by_tier.items():
            result[tier] = {
                "overall": asdict(aggregate_metrics(samples, "tier", tier)),
                "by_vulnerability_type": self._group_by_vuln_type(samples, "tier")
            }

        return result

    def _aggregate_by_dataset_type(self) -> dict:
        """Aggregate metrics by dataset type (ds, tc, gs), with vulnerability type breakdown."""
        by_type = defaultdict(list)

        for m in self.sample_metrics:
            by_type[m.dataset_type].append(m)

        result = {}
        for dtype, samples in by_type.items():
            result[dtype] = {
                "overall": asdict(aggregate_metrics(samples, "dataset_type", dtype)),
                "by_vulnerability_type": self._group_by_vuln_type(samples, "dataset_type")
            }

        return result

    def _aggregate_entire_dataset(self) -> dict:
        """Aggregate all metrics into single summary, with vulnerability type breakdown."""
        agg = aggregate_metrics(
            self.sample_metrics,
            "entire_dataset",
            "full"
        )
        return {
            "overall": asdict(agg),
            "by_vulnerability_type": self._group_by_vuln_type(self.sample_metrics, "entire_dataset")
        }

    def _group_by_vuln_type(self, samples: list, level: str) -> dict:
        """Group samples by vulnerability type and aggregate each group."""
        by_vuln = defaultdict(list)

        for m in samples:
            by_vuln[m.vulnerability_type].append(m)

        return {
            vuln_type: asdict(aggregate_metrics(vuln_samples, level, vuln_type))
            for vuln_type, vuln_samples in by_vuln.items()
        }

    def _metrics_to_dict(self, m: SampleMetrics) -> dict:
        """Convert SampleMetrics to dict with computed properties."""
        return {
            "sample_id": m.sample_id,
            "tier": m.tier,
            "dataset_type": m.dataset_type,
            "model": m.model,
            "vulnerability_type": m.vulnerability_type,
            "detection": {
                "true_detection": m.true_detection,
                "target_found": m.target_found,
                "verdict_correct": m.verdict_correct
            },
            "findings": {
                "total": m.total_findings,
                "true_positives": m.true_positives,
                "false_positives": m.false_positives,
                "hallucinations": m.hallucinations,
                "precision": m.precision,
                "hallucination_rate": m.hallucination_rate
            },
            "quality": {
                "explanation": m.explanation_quality,
                "fix": m.fix_quality,
                "attack_scenario": m.attack_scenario_quality,
                "average": m.average_quality
            }
        }

    def _generate_summary(self) -> dict:
        """Generate high-level summary statistics."""
        n = len(self.sample_metrics)
        if n == 0:
            return {"sample_count": 0}

        # Get tier breakdown
        tier_counts = defaultdict(int)
        for m in self.sample_metrics:
            if m.tier:
                tier_counts[m.tier] += 1

        # Get dataset type breakdown
        dtype_counts = defaultdict(int)
        for m in self.sample_metrics:
            dtype_counts[m.dataset_type] += 1

        # Get vulnerability type breakdown
        vuln_type_counts = defaultdict(int)
        for m in self.sample_metrics:
            vuln_type_counts[m.vulnerability_type] += 1

        return {
            "sample_count": n,
            "tier_distribution": dict(tier_counts),
            "dataset_type_distribution": dict(dtype_counts),
            "vulnerability_type_distribution": dict(vuln_type_counts),
            "model": self.model_name,
            "overall_target_found_rate": sum(
                1 for m in self.sample_metrics if m.target_found
            ) / n,
            "overall_precision": sum(
                m.precision for m in self.sample_metrics
            ) / n
        }


def create_aggregation_output(
    aggregator: HierarchicalAggregator,
    evaluator_type: str = "llm_judge"
) -> dict:
    """
    Create schema-conformant aggregation output.

    Args:
        aggregator: HierarchicalAggregator with data
        evaluator_type: Type of evaluator used

    Returns:
        Dict conforming to aggregated_metrics.schema.json
    """
    raw = aggregator.aggregate_all()

    return {
        "$schema": "../schemas/ds/aggregated_metrics.schema.json",
        "model": raw["model"],
        "evaluator_type": evaluator_type,
        "timestamp": raw["timestamp"],
        "aggregation_levels": raw["levels"],
        "summary": raw["summary"]
    }
