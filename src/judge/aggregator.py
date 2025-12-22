"""
Aggregated metrics computation across all samples.
"""

import numpy as np
from typing import Optional

from .schemas import (
    SampleMetrics,
    AggregatedMetrics,
    GroundTruthForJudge,
    TypeMatchLevel,
    PromptType,
)


def compute_aggregated_metrics(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruthForJudge],
) -> AggregatedMetrics:
    """Aggregate metrics across all samples"""

    n_samples = len(sample_metrics)
    if n_samples == 0:
        return _empty_metrics()

    # Count vulnerable vs safe
    vulnerable_samples = sum(1 for gt in ground_truths if gt.is_vulnerable)
    safe_samples = n_samples - vulnerable_samples

    # =========================================================================
    # TIER 1: DETECTION PERFORMANCE
    # =========================================================================
    detection = _compute_detection_metrics(sample_metrics, ground_truths)

    # =========================================================================
    # TIER 2: TARGET FINDING
    # =========================================================================
    target_finding = _compute_target_finding_metrics(sample_metrics, ground_truths, detection)

    # =========================================================================
    # TIER 3: FINDING QUALITY
    # =========================================================================
    finding_quality = _compute_finding_quality_metrics(sample_metrics)

    # =========================================================================
    # TIER 4: REASONING QUALITY
    # =========================================================================
    reasoning_quality = _compute_reasoning_quality_metrics(sample_metrics)

    # =========================================================================
    # TIER 5: TYPE ACCURACY
    # =========================================================================
    type_accuracy = _compute_type_accuracy_metrics(sample_metrics, ground_truths)

    # =========================================================================
    # TIER 6: CALIBRATION
    # =========================================================================
    calibration = _compute_calibration_metrics(sample_metrics)

    # =========================================================================
    # TIER 7: COMPOSITE SCORES
    # =========================================================================
    composite = _compute_composite_scores(
        detection, target_finding, finding_quality,
        reasoning_quality, calibration
    )

    # =========================================================================
    # PER-PROMPT-TYPE BREAKDOWN
    # =========================================================================
    by_prompt_type = _compute_by_prompt_type(sample_metrics, ground_truths)

    return AggregatedMetrics(
        total_samples=n_samples,
        vulnerable_samples=vulnerable_samples,
        safe_samples=safe_samples,
        detection=detection,
        target_finding=target_finding,
        finding_quality=finding_quality,
        reasoning_quality=reasoning_quality,
        type_accuracy=type_accuracy,
        calibration=calibration,
        composite=composite,
        by_prompt_type=by_prompt_type
    )


def _compute_detection_metrics(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruthForJudge]
) -> dict:
    """Compute detection performance metrics"""
    n_samples = len(sample_metrics)

    # Build confusion matrix
    tp = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if gt.is_vulnerable and sm.detection_correct)
    tn = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if not gt.is_vulnerable and sm.detection_correct)
    fp = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if not gt.is_vulnerable and not sm.detection_correct)
    fn = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if gt.is_vulnerable and not sm.detection_correct)

    accuracy = (tp + tn) / n_samples if n_samples > 0 else 0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    f2 = 5 * (precision * recall) / (4 * precision + recall) if (4 * precision + recall) > 0 else 0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0
    fnr = fn / (fn + tp) if (fn + tp) > 0 else 0

    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "f2": f2,
        "fpr": fpr,
        "fnr": fnr,
        "tp": tp, "tn": tn, "fp": fp, "fn": fn
    }


def _compute_target_finding_metrics(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruthForJudge],
    detection: dict
) -> dict:
    """Compute target finding metrics"""
    vulnerable_metrics = [
        sm for sm, gt in zip(sample_metrics, ground_truths) if gt.is_vulnerable
    ]
    vulnerable_count = len(vulnerable_metrics)

    target_found_count = sum(1 for sm in vulnerable_metrics if sm.target_found)
    lucky_guess_count = sum(1 for sm in vulnerable_metrics if sm.lucky_guess)

    # Samples with bonus findings
    bonus_count = sum(
        1 for sm in sample_metrics
        if sm.valid_findings > (1 if sm.target_found else 0)
    )

    tp = detection["tp"]

    return {
        "target_detection_rate": target_found_count / vulnerable_count if vulnerable_count > 0 else 0,
        "lucky_guess_rate": lucky_guess_count / tp if tp > 0 else 0,
        "bonus_discovery_rate": bonus_count / len(sample_metrics) if sample_metrics else 0,
        "target_found_count": target_found_count,
        "lucky_guess_count": lucky_guess_count
    }


def _compute_finding_quality_metrics(sample_metrics: list[SampleMetrics]) -> dict:
    """Compute finding quality metrics"""
    n_samples = len(sample_metrics)

    total_all_findings = sum(sm.total_findings for sm in sample_metrics)
    valid_all_findings = sum(sm.valid_findings for sm in sample_metrics)
    invalid_all_findings = sum(sm.invalid_findings for sm in sample_metrics)
    hallucinated_all_findings = sum(sm.hallucinated_findings for sm in sample_metrics)

    return {
        "finding_precision": valid_all_findings / total_all_findings if total_all_findings > 0 else 1.0,
        "invalid_rate": invalid_all_findings / total_all_findings if total_all_findings > 0 else 0,
        "hallucination_rate": hallucinated_all_findings / total_all_findings if total_all_findings > 0 else 0,
        "over_flagging_score": invalid_all_findings / n_samples if n_samples > 0 else 0,
        "avg_findings_per_sample": total_all_findings / n_samples if n_samples > 0 else 0,
        "total_findings": total_all_findings,
        "valid_findings": valid_all_findings,
        "invalid_findings": invalid_all_findings,
        "hallucinated_findings": hallucinated_all_findings
    }


def _compute_reasoning_quality_metrics(sample_metrics: list[SampleMetrics]) -> dict:
    """Compute reasoning quality metrics"""
    rcir_scores = [sm.rcir_score for sm in sample_metrics if sm.rcir_score is not None]
    ava_scores = [sm.ava_score for sm in sample_metrics if sm.ava_score is not None]
    fsv_scores = [sm.fsv_score for sm in sample_metrics if sm.fsv_score is not None]

    return {
        "mean_rcir": float(np.mean(rcir_scores)) if rcir_scores else None,
        "mean_ava": float(np.mean(ava_scores)) if ava_scores else None,
        "mean_fsv": float(np.mean(fsv_scores)) if fsv_scores else None,
        "std_rcir": float(np.std(rcir_scores)) if rcir_scores else None,
        "std_ava": float(np.std(ava_scores)) if ava_scores else None,
        "std_fsv": float(np.std(fsv_scores)) if fsv_scores else None,
        "n_samples_with_reasoning": len(rcir_scores)
    }


def _compute_type_accuracy_metrics(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruthForJudge]
) -> dict:
    """Compute type accuracy metrics"""
    vulnerable_metrics = [
        sm for sm, gt in zip(sample_metrics, ground_truths)
        if gt.is_vulnerable and sm.target_found
    ]

    type_matches = [sm.type_match for sm in vulnerable_metrics]
    n_type_samples = len(type_matches)

    exact_matches = sum(1 for t in type_matches if t == TypeMatchLevel.EXACT)
    semantic_matches = sum(1 for t in type_matches if t in [TypeMatchLevel.EXACT, TypeMatchLevel.SEMANTIC])
    partial_matches = sum(1 for t in type_matches if t == TypeMatchLevel.PARTIAL)

    return {
        "exact_match_rate": exact_matches / n_type_samples if n_type_samples > 0 else 0,
        "semantic_match_rate": semantic_matches / n_type_samples if n_type_samples > 0 else 0,
        "partial_match_rate": partial_matches / n_type_samples if n_type_samples > 0 else 0,
        "n_samples": n_type_samples
    }


def _compute_calibration_metrics(sample_metrics: list[SampleMetrics], n_bins: int = 10) -> dict:
    """Compute calibration metrics"""
    confidences = [sm.confidence for sm in sample_metrics if sm.confidence is not None]
    correct = [sm.detection_correct for sm in sample_metrics if sm.confidence is not None]

    if not confidences:
        return {
            "ece": None, "mce": None,
            "overconfidence_rate": None, "underconfidence_rate": None,
            "brier_score": None, "n_samples": 0
        }

    confidences = np.array(confidences)
    correct = np.array(correct).astype(float)

    # ECE (Expected Calibration Error)
    bin_boundaries = np.linspace(0, 1, n_bins + 1)
    ece = 0.0
    mce = 0.0

    for i in range(n_bins):
        in_bin = (confidences > bin_boundaries[i]) & (confidences <= bin_boundaries[i + 1])
        prop_in_bin = in_bin.mean()

        if prop_in_bin > 0:
            avg_confidence = confidences[in_bin].mean()
            avg_accuracy = correct[in_bin].mean()
            gap = abs(avg_accuracy - avg_confidence)
            ece += prop_in_bin * gap
            mce = max(mce, gap)

    # Overconfidence rate: P(wrong | confidence > 0.8)
    high_conf_mask = confidences > 0.8
    if high_conf_mask.any():
        overconfidence_rate = 1.0 - correct[high_conf_mask].mean()
    else:
        overconfidence_rate = 0.0

    # Underconfidence rate: P(correct | confidence < 0.5)
    low_conf_mask = confidences < 0.5
    if low_conf_mask.any():
        underconfidence_rate = correct[low_conf_mask].mean()
    else:
        underconfidence_rate = 0.0

    # Brier score
    brier_score = float(np.mean((confidences - correct) ** 2))

    return {
        "ece": float(ece),
        "mce": float(mce),
        "overconfidence_rate": float(overconfidence_rate),
        "underconfidence_rate": float(underconfidence_rate),
        "brier_score": brier_score,
        "n_samples": len(confidences)
    }


def _compute_composite_scores(
    detection: dict,
    target_finding: dict,
    finding_quality: dict,
    reasoning_quality: dict,
    calibration: dict
) -> dict:
    """Compute composite scores"""

    # True Understanding Score
    target_rate = target_finding["target_detection_rate"]

    reasoning_scores = [
        reasoning_quality.get("mean_rcir"),
        reasoning_quality.get("mean_ava"),
        reasoning_quality.get("mean_fsv")
    ]
    valid_reasoning = [s for s in reasoning_scores if s is not None]
    avg_reasoning = float(np.mean(valid_reasoning)) if valid_reasoning else 0

    invalid_rate = finding_quality["invalid_rate"]

    true_understanding = target_rate * avg_reasoning * (1 - invalid_rate)

    # Security Understanding Index (SUI)
    # Updated formula: SUI = 0.40·TDR + 0.30·Reasoning + 0.30·Finding_Precision
    components = {
        "target_detection": target_rate,
        "avg_reasoning": avg_reasoning,
        "finding_precision": finding_quality["finding_precision"],
    }

    # Weights (updated to match paper)
    weights = {
        "target_detection": 0.40,
        "avg_reasoning": 0.30,
        "finding_precision": 0.30,
    }

    sui = sum(
        weights.get(k, 0) * v
        for k, v in components.items()
        if v is not None
    )

    # Normalize by actual weight sum
    actual_weight_sum = sum(
        weights.get(k, 0)
        for k, v in components.items()
        if v is not None
    )
    if actual_weight_sum > 0:
        sui = sui / actual_weight_sum

    return {
        "true_understanding_score": true_understanding,
        "sui": sui,
        "sui_components": components,
        "lucky_guess_indicator": detection["accuracy"] - target_rate
    }


def _compute_by_prompt_type(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruthForJudge]
) -> dict[str, dict]:
    """Compute metrics breakdown by prompt type"""
    result = {}

    # Group by prompt type
    by_type: dict[str, tuple[list, list]] = {}
    for sm, gt in zip(sample_metrics, ground_truths):
        pt = sm.prompt_type.value
        if pt not in by_type:
            by_type[pt] = ([], [])
        by_type[pt][0].append(sm)
        by_type[pt][1].append(gt)

    for prompt_type, (metrics, gts) in by_type.items():
        if metrics:
            # Compute metrics without recursive by_prompt_type call
            n_samples = len(metrics)
            vulnerable_samples = sum(1 for gt in gts if gt.is_vulnerable)
            safe_samples = n_samples - vulnerable_samples

            detection = _compute_detection_metrics(metrics, gts)
            target_finding = _compute_target_finding_metrics(metrics, gts, detection)
            finding_quality = _compute_finding_quality_metrics(metrics)
            reasoning_quality = _compute_reasoning_quality_metrics(metrics)
            type_accuracy = _compute_type_accuracy_metrics(metrics, gts)
            calibration = _compute_calibration_metrics(metrics)
            composite = _compute_composite_scores(
                detection, target_finding, finding_quality,
                reasoning_quality, calibration
            )

            result[prompt_type] = {
                "total_samples": n_samples,
                "vulnerable_samples": vulnerable_samples,
                "safe_samples": safe_samples,
                "detection": detection,
                "target_finding": target_finding,
                "finding_quality": finding_quality,
                "reasoning_quality": reasoning_quality,
                "type_accuracy": type_accuracy,
                "calibration": calibration,
                "composite": composite,
            }

    return result


def _empty_metrics() -> AggregatedMetrics:
    """Return empty metrics structure"""
    return AggregatedMetrics(
        total_samples=0,
        vulnerable_samples=0,
        safe_samples=0,
        detection={"accuracy": 0, "precision": 0, "recall": 0, "f1": 0, "f2": 0,
                   "fpr": 0, "fnr": 0, "tp": 0, "tn": 0, "fp": 0, "fn": 0},
        target_finding={"target_detection_rate": 0, "lucky_guess_rate": 0,
                        "bonus_discovery_rate": 0, "target_found_count": 0, "lucky_guess_count": 0},
        finding_quality={"finding_precision": 0, "invalid_rate": 0, "hallucination_rate": 0,
                         "over_flagging_score": 0, "avg_findings_per_sample": 0,
                         "total_findings": 0, "valid_findings": 0, "invalid_findings": 0,
                         "hallucinated_findings": 0},
        reasoning_quality={"mean_rcir": None, "mean_ava": None, "mean_fsv": None,
                           "std_rcir": None, "std_ava": None, "std_fsv": None,
                           "n_samples_with_reasoning": 0},
        type_accuracy={"exact_match_rate": 0, "semantic_match_rate": 0,
                       "partial_match_rate": 0, "n_samples": 0},
        calibration={"ece": None, "mce": None, "overconfidence_rate": None,
                     "underconfidence_rate": None, "brier_score": None, "n_samples": 0},
        composite={"true_understanding_score": 0, "sui": 0, "sui_components": {},
                   "lucky_guess_indicator": 0},
        by_prompt_type=None
    )
