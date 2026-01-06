#!/usr/bin/env python3
"""
Comprehensive metrics aggregation with statistical tests for BlockBench ACL paper.

Calculates:
1. TDR with Bootstrap 95% CI
2. SUI (Security Understanding Index) with sensitivity analysis
3. Finding Precision with CI
4. RCIR, AVA, FSV (reasoning quality) with CI
5. LGR (Lucky Guess Rate)
6. Hallucination Rate
7. McNemar's Test for pairwise model significance
8. Spearman's ρ for SUI ranking stability

Outputs:
- Table 1: DS + TC with CIs
- Table 2: GS with CIs
- Table 3: Quality metrics with CIs
- Statistical significance analysis
"""

import json
import argparse
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Optional, Any
import math
import random
from dataclasses import dataclass, field
import warnings

# Set seed for reproducibility
random.seed(42)


@dataclass
class SampleMetrics:
    """Metrics for a single sample."""
    sample_id: str
    detector: str
    dataset: str
    subset: str  # tier/variant/prompt_type

    # Detection
    target_found: bool = False
    complete_found: bool = False
    partial_found: bool = False

    # Reasoning (only if target found)
    rcir: Optional[float] = None
    ava: Optional[float] = None
    fsv: Optional[float] = None

    # Findings
    total_findings: int = 0
    correct_findings: int = 0  # TARGET_MATCH + PARTIAL_MATCH + BONUS_VALID
    hallucinated_findings: int = 0
    false_alarm_findings: int = 0  # HALLUCINATED + SECURITY_THEATER + MISCHARACTERIZED

    # For LGR calculation
    overall_verdict: Optional[str] = None  # vulnerable/safe
    ground_truth_vulnerable: bool = True  # assume all samples are vulnerable


@dataclass
class AggregatedMetrics:
    """Aggregated metrics for a detector on a dataset subset."""
    detector: str
    dataset: str
    subset: str
    n_samples: int = 0

    # TDR
    tdr: float = 0.0
    tdr_ci_low: float = 0.0
    tdr_ci_high: float = 0.0

    # Reasoning quality (conditional on target found)
    rcir_mean: float = 0.0
    rcir_ci_low: float = 0.0
    rcir_ci_high: float = 0.0
    rcir_n: int = 0

    ava_mean: float = 0.0
    ava_ci_low: float = 0.0
    ava_ci_high: float = 0.0
    ava_n: int = 0

    fsv_mean: float = 0.0
    fsv_ci_low: float = 0.0
    fsv_ci_high: float = 0.0
    fsv_n: int = 0

    # R-bar (mean reasoning quality)
    r_bar: float = 0.0
    r_bar_ci_low: float = 0.0
    r_bar_ci_high: float = 0.0

    # Finding precision
    precision: float = 0.0
    precision_ci_low: float = 0.0
    precision_ci_high: float = 0.0
    total_findings: int = 0
    correct_findings: int = 0

    # Hallucination rate
    hallucination_rate: float = 0.0
    hallucinated_count: int = 0

    # Lucky Guess Rate
    lgr: float = 0.0
    lucky_guess_count: int = 0
    correct_verdict_count: int = 0

    # SUI (calculated after aggregation)
    sui: float = 0.0
    sui_ci_low: float = 0.0
    sui_ci_high: float = 0.0


def bootstrap_ci(values: List[float], n_bootstrap: int = 1000, ci: float = 0.95) -> Tuple[float, float, float]:
    """
    Calculate bootstrap confidence interval for mean.

    Returns: (mean, ci_low, ci_high)
    """
    if not values:
        return (0.0, 0.0, 0.0)

    n = len(values)
    if n == 1:
        return (values[0], values[0], values[0])

    means = []
    for _ in range(n_bootstrap):
        sample = [random.choice(values) for _ in range(n)]
        means.append(sum(sample) / n)

    means.sort()
    alpha = (1 - ci) / 2
    low_idx = int(alpha * n_bootstrap)
    high_idx = int((1 - alpha) * n_bootstrap) - 1

    return (sum(values) / n, means[low_idx], means[high_idx])


def bootstrap_proportion_ci(successes: int, total: int, n_bootstrap: int = 1000, ci: float = 0.95) -> Tuple[float, float, float]:
    """
    Calculate bootstrap confidence interval for a proportion.

    Returns: (proportion, ci_low, ci_high)
    """
    if total == 0:
        return (0.0, 0.0, 0.0)

    prop = successes / total
    if total == 1:
        return (prop, 0.0, 1.0)

    # Generate bootstrap samples
    proportions = []
    for _ in range(n_bootstrap):
        # Resample with replacement
        sample_successes = sum(1 for _ in range(total) if random.random() < prop)
        proportions.append(sample_successes / total)

    proportions.sort()
    alpha = (1 - ci) / 2
    low_idx = int(alpha * n_bootstrap)
    high_idx = int((1 - alpha) * n_bootstrap) - 1

    return (prop, proportions[low_idx], proportions[high_idx])


def mcnemar_test(contingency: Tuple[int, int, int, int]) -> Tuple[float, float]:
    """
    McNemar's test for paired nominal data.

    Args:
        contingency: (both_correct, a_only, b_only, both_wrong)

    Returns: (chi2, p_value)
    """
    both_correct, a_only, b_only, both_wrong = contingency
    b = a_only  # Model A correct, Model B wrong
    c = b_only  # Model A wrong, Model B correct

    if b + c == 0:
        return (0.0, 1.0)

    # McNemar's chi-squared (with continuity correction)
    chi2 = (abs(b - c) - 1) ** 2 / (b + c)

    # P-value from chi-squared distribution with 1 df
    # Using approximation for simplicity
    from math import exp, sqrt, pi

    def chi2_cdf(x, df=1):
        """Approximate chi-squared CDF for df=1."""
        if x <= 0:
            return 0.0
        # Using normal approximation
        z = sqrt(2 * x) - sqrt(2 * df - 1)
        return 0.5 * (1 + math.erf(z / sqrt(2)))

    p_value = 1 - chi2_cdf(chi2)
    return (chi2, p_value)


def spearman_rho(rankings1: List[int], rankings2: List[int]) -> float:
    """Calculate Spearman's rank correlation coefficient."""
    n = len(rankings1)
    if n != len(rankings2) or n == 0:
        return 0.0

    d_squared = sum((r1 - r2) ** 2 for r1, r2 in zip(rankings1, rankings2))
    rho = 1 - (6 * d_squared) / (n * (n ** 2 - 1))
    return rho


def fleiss_kappa(ratings: List[List[int]], n_categories: int = 2) -> float:
    """Calculate Fleiss' kappa for inter-rater agreement."""
    n_subjects = len(ratings)
    n_raters = len(ratings[0]) if ratings else 0

    if n_subjects == 0 or n_raters == 0:
        return 0.0

    category_counts = []
    for subject_ratings in ratings:
        counts = [0] * n_categories
        for r in subject_ratings:
            if 0 <= r < n_categories:
                counts[r] += 1
        category_counts.append(counts)

    P_i = []
    for counts in category_counts:
        sum_sq = sum(c * c for c in counts)
        p = (sum_sq - n_raters) / (n_raters * (n_raters - 1)) if n_raters > 1 else 0
        P_i.append(p)

    P_bar = sum(P_i) / n_subjects if n_subjects > 0 else 0

    total_ratings = n_subjects * n_raters
    p_j = []
    for cat in range(n_categories):
        cat_total = sum(counts[cat] for counts in category_counts)
        p_j.append(cat_total / total_ratings if total_ratings > 0 else 0)

    P_e = sum(p * p for p in p_j)

    if P_e == 1:
        return 1.0 if P_bar == 1 else 0.0

    kappa = (P_bar - P_e) / (1 - P_e)
    return kappa


def calculate_sui(tdr: float, r_bar: float, precision: float,
                  weights: Tuple[float, float, float] = (0.40, 0.30, 0.30)) -> float:
    """
    Calculate Security Understanding Index.

    Args:
        tdr: Target Detection Rate (0-1)
        r_bar: Mean reasoning quality (0-1)
        precision: Finding precision (0-1)
        weights: (w_tdr, w_reasoning, w_precision)
    """
    w_tdr, w_r, w_prec = weights
    return w_tdr * tdr + w_r * r_bar + w_prec * precision


def get_majority_vote(judge_values: List[Optional[bool]]) -> Optional[bool]:
    """Get majority vote from 3 judges (2-of-3 required)."""
    valid = [v for v in judge_values if v is not None]
    if len(valid) < 2:
        return None
    return sum(1 for v in valid if v) >= 2


def extract_sample_metrics(judge_file: Path, detector: str, dataset: str, subset: str) -> Optional[SampleMetrics]:
    """Extract metrics from a single judge output file."""
    try:
        with open(judge_file) as f:
            data = json.load(f)
    except Exception:
        return None

    sample_id = data.get('sample_id', judge_file.stem.replace('j_', ''))

    metrics = SampleMetrics(
        sample_id=sample_id,
        detector=detector,
        dataset=dataset,
        subset=subset
    )

    # Target assessment
    ta = data.get('target_assessment', {})
    metrics.complete_found = ta.get('complete_found', False)
    metrics.partial_found = ta.get('partial_found', False)
    metrics.target_found = metrics.complete_found or metrics.partial_found

    # Reasoning scores (only if target found)
    if metrics.target_found:
        rci = ta.get('root_cause_identification', {})
        if isinstance(rci, dict):
            metrics.rcir = rci.get('score')

        ava = ta.get('attack_vector_validity', {})
        if isinstance(ava, dict):
            metrics.ava = ava.get('score')

        fsv = ta.get('fix_suggestion_validity', {})
        if isinstance(fsv, dict):
            metrics.fsv = fsv.get('score')

    # Findings classification
    findings = data.get('findings', [])
    if findings:
        metrics.total_findings = len(findings)

        correct_classes = {'TARGET_MATCH', 'PARTIAL_MATCH', 'BONUS_VALID'}
        hallucinated_classes = {'HALLUCINATED'}
        false_alarm_classes = {'HALLUCINATED', 'SECURITY_THEATER', 'MISCHARACTERIZED'}

        for finding in findings:
            classification = finding.get('classification', '')
            if classification in correct_classes:
                metrics.correct_findings += 1
            if classification in hallucinated_classes:
                metrics.hallucinated_findings += 1
            if classification in false_alarm_classes:
                metrics.false_alarm_findings += 1

    # Overall verdict - it's a dict with 'said_vulnerable' boolean
    overall_verdict = data.get('overall_verdict', {})
    if isinstance(overall_verdict, dict):
        metrics.overall_verdict = 'vulnerable' if overall_verdict.get('said_vulnerable', False) else 'safe'
    else:
        metrics.overall_verdict = overall_verdict

    return metrics


def aggregate_with_majority_vote(
    base_path: Path,
    judges: List[str],
    detectors: List[str],
    dataset: str,
    subsets: List[str],
    subset_path_key: str = ''
) -> Dict[str, Dict[str, AggregatedMetrics]]:
    """
    Aggregate metrics using majority vote across judges.

    Returns: {detector: {subset: AggregatedMetrics}}
    """
    results = {}

    for detector in detectors:
        results[detector] = {}

        for subset in subsets:
            # Collect samples across all judges
            sample_ids = set()
            for judge in judges:
                if dataset == 'gs':
                    subset_path = base_path / judge / detector / 'gs' / subset
                elif dataset == 'tc':
                    subset_path = base_path / judge / detector / 'tc' / subset
                else:  # ds
                    subset_path = base_path / judge / detector / 'ds' / subset

                if subset_path.exists():
                    for f in subset_path.glob('j_*.json'):
                        sample_ids.add(f.stem.replace('j_', ''))

            sample_ids = sorted(sample_ids)

            # Aggregate metrics
            agg = AggregatedMetrics(detector=detector, dataset=dataset, subset=subset)

            target_found_list = []
            rcir_scores = []
            ava_scores = []
            fsv_scores = []
            r_bar_scores = []

            total_findings = 0
            correct_findings = 0
            hallucinated_count = 0

            lucky_guess_count = 0
            correct_verdict_count = 0

            for sample_id in sample_ids:
                # Get judge votes
                judge_target_found = []
                sample_metrics_list = []

                for judge in judges:
                    if dataset == 'gs':
                        judge_file = base_path / judge / detector / 'gs' / subset / f'j_{sample_id}.json'
                    elif dataset == 'tc':
                        judge_file = base_path / judge / detector / 'tc' / subset / f'j_{sample_id}.json'
                    else:
                        judge_file = base_path / judge / detector / 'ds' / subset / f'j_{sample_id}.json'

                    metrics = extract_sample_metrics(judge_file, detector, dataset, subset)
                    if metrics:
                        judge_target_found.append(metrics.target_found)
                        sample_metrics_list.append(metrics)

                # Skip if not all judges have data
                if len(judge_target_found) != len(judges):
                    continue

                agg.n_samples += 1

                # Majority vote for target found
                majority_found = sum(1 for v in judge_target_found if v) >= 2
                target_found_list.append(1 if majority_found else 0)

                # For reasoning scores, use first judge that found target (if majority found)
                if majority_found:
                    for m in sample_metrics_list:
                        if m.target_found:
                            if m.rcir is not None:
                                rcir_scores.append(m.rcir)
                            if m.ava is not None:
                                ava_scores.append(m.ava)
                            if m.fsv is not None:
                                fsv_scores.append(m.fsv)
                            if m.rcir is not None and m.ava is not None and m.fsv is not None:
                                r_bar_scores.append((m.rcir + m.ava + m.fsv) / 3)
                            break

                # Aggregate findings from first judge (all judges evaluate same detector output)
                if sample_metrics_list:
                    m = sample_metrics_list[0]
                    total_findings += m.total_findings
                    correct_findings += m.correct_findings
                    hallucinated_count += m.hallucinated_findings

                    # Lucky guess: correct verdict but target not found
                    # Assume all samples are vulnerable (ground_truth_vulnerable = True)
                    verdict_correct = m.overall_verdict == 'vulnerable'
                    if verdict_correct:
                        correct_verdict_count += 1
                        if not majority_found:
                            lucky_guess_count += 1

            # Calculate TDR with CI
            if agg.n_samples > 0:
                found_count = sum(target_found_list)
                tdr, tdr_low, tdr_high = bootstrap_proportion_ci(found_count, agg.n_samples)
                agg.tdr = tdr
                agg.tdr_ci_low = tdr_low
                agg.tdr_ci_high = tdr_high

            # Reasoning scores with CI
            if rcir_scores:
                agg.rcir_n = len(rcir_scores)
                agg.rcir_mean, agg.rcir_ci_low, agg.rcir_ci_high = bootstrap_ci(rcir_scores)

            if ava_scores:
                agg.ava_n = len(ava_scores)
                agg.ava_mean, agg.ava_ci_low, agg.ava_ci_high = bootstrap_ci(ava_scores)

            if fsv_scores:
                agg.fsv_n = len(fsv_scores)
                agg.fsv_mean, agg.fsv_ci_low, agg.fsv_ci_high = bootstrap_ci(fsv_scores)

            if r_bar_scores:
                agg.r_bar, agg.r_bar_ci_low, agg.r_bar_ci_high = bootstrap_ci(r_bar_scores)

            # Finding precision
            agg.total_findings = total_findings
            agg.correct_findings = correct_findings
            if total_findings > 0:
                agg.precision, agg.precision_ci_low, agg.precision_ci_high = bootstrap_proportion_ci(
                    correct_findings, total_findings)

            # Hallucination rate
            agg.hallucinated_count = hallucinated_count
            if total_findings > 0:
                agg.hallucination_rate = hallucinated_count / total_findings

            # Lucky guess rate
            agg.lucky_guess_count = lucky_guess_count
            agg.correct_verdict_count = correct_verdict_count
            if correct_verdict_count > 0:
                agg.lgr = lucky_guess_count / correct_verdict_count

            # SUI
            agg.sui = calculate_sui(agg.tdr, agg.r_bar, agg.precision)

            results[detector][subset] = agg

    return results


def run_sui_sensitivity_analysis(detector_metrics: Dict[str, Dict[str, AggregatedMetrics]],
                                   detectors: List[str]) -> Dict[str, Any]:
    """
    Run SUI sensitivity analysis with different weight configurations.

    Returns analysis results including Spearman's ρ for ranking stability.
    """
    weight_configs = {
        'balanced': (0.33, 0.33, 0.34),
        'detection_default': (0.40, 0.30, 0.30),
        'quality_first': (0.30, 0.40, 0.30),
        'precision_first': (0.30, 0.30, 0.40),
        'detection_heavy': (0.50, 0.25, 0.25)
    }

    # Calculate overall metrics per detector (average across all subsets)
    detector_overall = {}
    for detector in detectors:
        if detector in detector_metrics:
            subsets = detector_metrics[detector]
            n = len(subsets)
            if n > 0:
                tdr = sum(s.tdr for s in subsets.values()) / n
                r_bar = sum(s.r_bar for s in subsets.values()) / n
                precision = sum(s.precision for s in subsets.values()) / n
                detector_overall[detector] = {'tdr': tdr, 'r_bar': r_bar, 'precision': precision}

    # Calculate SUI for each weight config
    rankings = {}
    sui_values = {}

    for config_name, weights in weight_configs.items():
        sui_per_detector = {}
        for detector, metrics in detector_overall.items():
            sui = calculate_sui(metrics['tdr'], metrics['r_bar'], metrics['precision'], weights)
            sui_per_detector[detector] = sui

        # Sort by SUI to get ranking
        sorted_detectors = sorted(sui_per_detector.items(), key=lambda x: -x[1])
        rankings[config_name] = [d[0] for d in sorted_detectors]
        sui_values[config_name] = sui_per_detector

    # Calculate Spearman's ρ between all pairs of rankings
    config_names = list(weight_configs.keys())
    rho_matrix = {}

    for i, config1 in enumerate(config_names):
        for j, config2 in enumerate(config_names):
            if i < j:
                rank1 = [rankings[config1].index(d) + 1 for d in detectors if d in rankings[config1]]
                rank2 = [rankings[config2].index(d) + 1 for d in detectors if d in rankings[config2]]
                rho = spearman_rho(rank1, rank2)
                rho_matrix[f"{config1}_vs_{config2}"] = rho

    return {
        'weight_configs': weight_configs,
        'rankings': rankings,
        'sui_values': sui_values,
        'spearman_rho': rho_matrix,
        'detector_overall': detector_overall
    }


def run_mcnemar_tests(detector_metrics: Dict[str, Dict[str, AggregatedMetrics]],
                      base_path: Path,
                      judges: List[str],
                      detectors: List[str],
                      dataset: str,
                      subsets: List[str]) -> Dict[str, Dict[str, Tuple[float, float]]]:
    """
    Run McNemar's tests for pairwise model comparisons.

    Returns: {detector_pair: {subset: (chi2, p_value)}}
    """
    results = {}

    for i, det1 in enumerate(detectors):
        for j, det2 in enumerate(detectors):
            if i >= j:
                continue

            pair_key = f"{det1}_vs_{det2}"
            results[pair_key] = {}

            for subset in subsets:
                # Collect sample-level results for both detectors
                sample_ids = set()
                for judge in judges:
                    if dataset == 'gs':
                        for det in [det1, det2]:
                            path = base_path / judge / det / 'gs' / subset
                            if path.exists():
                                for f in path.glob('j_*.json'):
                                    sample_ids.add(f.stem.replace('j_', ''))
                    elif dataset == 'tc':
                        for det in [det1, det2]:
                            path = base_path / judge / det / 'tc' / subset
                            if path.exists():
                                for f in path.glob('j_*.json'):
                                    sample_ids.add(f.stem.replace('j_', ''))
                    else:
                        for det in [det1, det2]:
                            path = base_path / judge / det / 'ds' / subset
                            if path.exists():
                                for f in path.glob('j_*.json'):
                                    sample_ids.add(f.stem.replace('j_', ''))

                # Get majority vote for each sample
                both_correct = 0
                det1_only = 0
                det2_only = 0
                both_wrong = 0

                for sample_id in sample_ids:
                    det1_votes = []
                    det2_votes = []

                    for judge in judges:
                        if dataset == 'gs':
                            f1 = base_path / judge / det1 / 'gs' / subset / f'j_{sample_id}.json'
                            f2 = base_path / judge / det2 / 'gs' / subset / f'j_{sample_id}.json'
                        elif dataset == 'tc':
                            f1 = base_path / judge / det1 / 'tc' / subset / f'j_{sample_id}.json'
                            f2 = base_path / judge / det2 / 'tc' / subset / f'j_{sample_id}.json'
                        else:
                            f1 = base_path / judge / det1 / 'ds' / subset / f'j_{sample_id}.json'
                            f2 = base_path / judge / det2 / 'ds' / subset / f'j_{sample_id}.json'

                        m1 = extract_sample_metrics(f1, det1, dataset, subset)
                        m2 = extract_sample_metrics(f2, det2, dataset, subset)

                        if m1:
                            det1_votes.append(m1.target_found)
                        if m2:
                            det2_votes.append(m2.target_found)

                    if len(det1_votes) >= 2 and len(det2_votes) >= 2:
                        det1_found = sum(1 for v in det1_votes if v) >= 2
                        det2_found = sum(1 for v in det2_votes if v) >= 2

                        if det1_found and det2_found:
                            both_correct += 1
                        elif det1_found and not det2_found:
                            det1_only += 1
                        elif not det1_found and det2_found:
                            det2_only += 1
                        else:
                            both_wrong += 1

                chi2, p_val = mcnemar_test((both_correct, det1_only, det2_only, both_wrong))
                results[pair_key][subset] = (chi2, p_val)

    return results


def write_table1_with_ci(ds_results: Dict, tc_results: Dict, output_path: Path, detectors: List[str]):
    """Write Table 1 (DS + TC) with confidence intervals."""

    detector_display = {
        'claude-opus-4-5': 'Claude Opus 4.5',
        'gemini-3-pro': 'Gemini 3 Pro',
        'deepseek-v3-2': 'DeepSeek v3.2',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok 4',
        'llama-4-maverick': 'Llama 4 Mav',
        'qwen3-coder-plus': 'Qwen3 Coder'
    }

    tiers = ['tier1', 'tier2', 'tier3', 'tier4']
    variants = ['minimalsanitized', 'sanitized', 'nocomments', 'chameleon_medical',
                'shapeshifter_l3', 'trojan', 'falseProphet']

    lines = [
        "# Table 1: Detection Results with 95% Confidence Intervals",
        "",
        "## DS Results",
        "",
        "| Model | T1 | T2 | T3 | T4 | Avg |",
        "|-------|---:|---:|---:|---:|----:|",
    ]

    # Sort detectors by DS average
    detector_avgs = []
    for det in detectors:
        if det in ds_results:
            tdrs = [ds_results[det][t].tdr * 100 for t in tiers if t in ds_results[det]]
            avg = sum(tdrs) / len(tdrs) if tdrs else 0
            detector_avgs.append((det, avg))
    detector_avgs.sort(key=lambda x: -x[1])
    sorted_detectors = [d[0] for d in detector_avgs]

    for det in sorted_detectors:
        name = detector_display.get(det, det)
        row = f"| {name} |"

        tdrs = []
        for tier in tiers:
            if det in ds_results and tier in ds_results[det]:
                m = ds_results[det][tier]
                tdr = m.tdr * 100
                tdrs.append(tdr)
                # Format: value [low-high]
                row += f" {tdr:.1f} [{m.tdr_ci_low*100:.1f}-{m.tdr_ci_high*100:.1f}] |"
            else:
                row += " - |"

        avg = sum(tdrs) / len(tdrs) if tdrs else 0
        row += f" {avg:.1f} |"
        lines.append(row)

    lines.extend([
        "",
        "## TC Results",
        "",
        "| Model | MinS | San | NoC | Cha | Shp | Tro | FalP | Avg |",
        "|-------|-----:|----:|----:|----:|----:|----:|-----:|----:|",
    ])

    variant_short = {
        'minimalsanitized': 'MinS',
        'sanitized': 'San',
        'nocomments': 'NoC',
        'chameleon_medical': 'Cha',
        'shapeshifter_l3': 'Shp',
        'trojan': 'Tro',
        'falseProphet': 'FalP'
    }

    for det in sorted_detectors:
        name = detector_display.get(det, det)
        row = f"| {name} |"

        tdrs = []
        for var in variants:
            if det in tc_results and var in tc_results[det]:
                m = tc_results[det][var]
                tdr = m.tdr * 100
                tdrs.append(tdr)
                row += f" {tdr:.1f} |"
            else:
                row += " - |"

        avg = sum(tdrs) / len(tdrs) if tdrs else 0
        row += f" {avg:.1f} |"
        lines.append(row)

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def write_table3_quality_metrics(
    combined_metrics: Dict[str, AggregatedMetrics],
    sensitivity: Dict[str, Any],
    output_path: Path,
    detectors: List[str]
):
    """Write Table 3 (Quality Metrics) with SUI and sensitivity analysis."""

    detector_display = {
        'claude-opus-4-5': 'Claude',
        'gemini-3-pro': 'Gemini',
        'deepseek-v3-2': 'DeepSeek',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok',
        'llama-4-maverick': 'Llama',
        'qwen3-coder-plus': 'Qwen'
    }

    lines = [
        "# Table 3: Quality Metrics with 95% Confidence Intervals",
        "",
        "| Model | SUI | Precision | RCIR | AVA | FSV | LGR | Halluc. |",
        "|-------|----:|----------:|-----:|----:|----:|----:|--------:|",
    ]

    # Sort by SUI
    sorted_dets = sorted(
        [(d, combined_metrics[d].sui) for d in detectors if d in combined_metrics],
        key=lambda x: -x[1]
    )

    for det, _ in sorted_dets:
        m = combined_metrics[det]
        name = detector_display.get(det, det)

        sui_str = f"{m.sui:.3f}"
        prec_str = f"{m.precision*100:.1f}%"
        rcir_str = f"{m.rcir_mean:.2f}" if m.rcir_n > 0 else "-"
        ava_str = f"{m.ava_mean:.2f}" if m.ava_n > 0 else "-"
        fsv_str = f"{m.fsv_mean:.2f}" if m.fsv_n > 0 else "-"
        lgr_str = f"{m.lgr*100:.1f}%"
        hal_str = f"{m.hallucination_rate*100:.1f}%"

        lines.append(f"| {name} | {sui_str} | {prec_str} | {rcir_str} | {ava_str} | {fsv_str} | {lgr_str} | {hal_str} |")

    # Add sensitivity analysis section
    lines.extend([
        "",
        "## SUI Sensitivity Analysis",
        "",
        "| Config | Weights (TDR/R̄/Prec) | Ranking | Spearman's ρ vs Default |",
        "|--------|----------------------|---------|------------------------|",
    ])

    default_ranking = sensitivity['rankings'].get('detection_default', [])

    for config, weights in sensitivity['weight_configs'].items():
        ranking = sensitivity['rankings'].get(config, [])
        ranking_str = ' > '.join([detector_display.get(d, d) for d in ranking[:3]]) + ' ...'

        if config == 'detection_default':
            rho_str = "1.000 (baseline)"
        else:
            rho_key = f"detection_default_vs_{config}" if f"detection_default_vs_{config}" in sensitivity['spearman_rho'] else f"{config}_vs_detection_default"
            rho = sensitivity['spearman_rho'].get(rho_key, 1.0)
            rho_str = f"{rho:.3f}"

        weight_str = f"{weights[0]:.2f}/{weights[1]:.2f}/{weights[2]:.2f}"
        lines.append(f"| {config} | {weight_str} | {ranking_str} | {rho_str} |")

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def write_mcnemar_summary(mcnemar_results: Dict, output_path: Path, detectors: List[str]):
    """Write McNemar's test summary."""

    detector_display = {
        'claude-opus-4-5': 'Claude',
        'gemini-3-pro': 'Gemini',
        'deepseek-v3-2': 'DeepSeek',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok',
        'llama-4-maverick': 'Llama',
        'qwen3-coder-plus': 'Qwen'
    }

    lines = [
        "# McNemar's Test Results (Pairwise Model Comparison)",
        "",
        "**Interpretation:** p < 0.05 indicates statistically significant difference",
        "",
        "## Significant Differences (p < 0.05)",
        ""
    ]

    significant = []
    not_significant = []

    for pair, subsets in mcnemar_results.items():
        det1, det2 = pair.split('_vs_')
        name1 = detector_display.get(det1, det1)
        name2 = detector_display.get(det2, det2)

        # Average p-value across subsets
        p_vals = [p for chi2, p in subsets.values()]
        avg_p = sum(p_vals) / len(p_vals) if p_vals else 1.0

        if avg_p < 0.05:
            significant.append(f"- **{name1} vs {name2}**: p = {avg_p:.4f}")
        else:
            not_significant.append(f"- {name1} vs {name2}: p = {avg_p:.4f}")

    if significant:
        lines.extend(significant)
    else:
        lines.append("No significant differences found at α = 0.05")

    lines.extend([
        "",
        "## Not Significant (p ≥ 0.05)",
        ""
    ])
    lines.extend(not_significant[:10])  # Show first 10
    if len(not_significant) > 10:
        lines.append(f"... and {len(not_significant) - 10} more pairs")

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description='Comprehensive metrics aggregation with statistical tests')
    parser.add_argument('--output-dir', '-o', type=Path,
                        default=Path('results/summaries/comprehensive'),
                        help='Output directory')
    parser.add_argument('--n-bootstrap', type=int, default=1000,
                        help='Number of bootstrap samples')
    args = parser.parse_args()

    base_path = Path('results/detection_evaluation/llm-judge')

    judges = ['glm-4.7', 'mimo-v2-flash', 'mistral-large']
    detectors = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
                 'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

    tiers = ['tier1', 'tier2', 'tier3', 'tier4']
    tc_variants = ['minimalsanitized', 'sanitized', 'nocomments', 'chameleon_medical',
                   'shapeshifter_l3', 'trojan', 'falseProphet']
    gs_prompts = ['direct', 'context_protocol', 'context_protocol_cot',
                  'context_protocol_cot_naturalistic', 'context_protocol_cot_adversarial']

    args.output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("BlockBench Comprehensive Metrics Aggregation")
    print("=" * 60)

    # Aggregate DS
    print("\n[1/6] Aggregating DS results...")
    ds_results = aggregate_with_majority_vote(base_path, judges, detectors, 'ds', tiers)

    # Aggregate TC
    print("[2/6] Aggregating TC results...")
    tc_results = aggregate_with_majority_vote(base_path, judges, detectors, 'tc', tc_variants)

    # Aggregate GS
    print("[3/6] Aggregating GS results...")
    gs_results = aggregate_with_majority_vote(base_path, judges, detectors, 'gs', gs_prompts)

    # Combine all metrics per detector (for Table 3)
    print("[4/6] Computing combined quality metrics...")
    combined = {}
    for det in detectors:
        all_subsets = []

        if det in ds_results:
            all_subsets.extend(ds_results[det].values())
        if det in tc_results:
            all_subsets.extend(tc_results[det].values())

        if all_subsets:
            n = len(all_subsets)
            combined[det] = AggregatedMetrics(
                detector=det,
                dataset='combined',
                subset='all',
                n_samples=sum(s.n_samples for s in all_subsets),
                tdr=sum(s.tdr for s in all_subsets) / n,
                rcir_mean=sum(s.rcir_mean for s in all_subsets) / n,
                rcir_n=sum(s.rcir_n for s in all_subsets),
                ava_mean=sum(s.ava_mean for s in all_subsets) / n,
                ava_n=sum(s.ava_n for s in all_subsets),
                fsv_mean=sum(s.fsv_mean for s in all_subsets) / n,
                fsv_n=sum(s.fsv_n for s in all_subsets),
                r_bar=sum(s.r_bar for s in all_subsets) / n,
                precision=sum(s.precision for s in all_subsets) / n,
                total_findings=sum(s.total_findings for s in all_subsets),
                correct_findings=sum(s.correct_findings for s in all_subsets),
                hallucination_rate=sum(s.hallucination_rate for s in all_subsets) / n,
                hallucinated_count=sum(s.hallucinated_count for s in all_subsets),
                lgr=sum(s.lgr for s in all_subsets) / n,
                lucky_guess_count=sum(s.lucky_guess_count for s in all_subsets),
                correct_verdict_count=sum(s.correct_verdict_count for s in all_subsets),
            )
            combined[det].sui = calculate_sui(combined[det].tdr, combined[det].r_bar, combined[det].precision)

    # SUI Sensitivity Analysis
    print("[5/6] Running SUI sensitivity analysis...")
    sensitivity = run_sui_sensitivity_analysis(ds_results, detectors)

    # McNemar's Tests
    print("[6/6] Running McNemar's tests...")
    mcnemar_ds = run_mcnemar_tests(ds_results, base_path, judges, detectors, 'ds', tiers)

    # Write outputs
    print("\nWriting output files...")

    # Table 1
    write_table1_with_ci(ds_results, tc_results, args.output_dir / 'table1_with_ci.md', detectors)

    # Table 3
    write_table3_quality_metrics(combined, sensitivity, args.output_dir / 'table3_quality_metrics.md', detectors)

    # McNemar summary
    write_mcnemar_summary(mcnemar_ds, args.output_dir / 'mcnemar_results.md', detectors)

    # Full JSON output
    full_results = {
        'ds': {det: {k: vars(v) for k, v in subsets.items()} for det, subsets in ds_results.items()},
        'tc': {det: {k: vars(v) for k, v in subsets.items()} for det, subsets in tc_results.items()},
        'gs': {det: {k: vars(v) for k, v in subsets.items()} for det, subsets in gs_results.items()},
        'combined': {det: vars(m) for det, m in combined.items()},
        'sensitivity_analysis': sensitivity,
        'mcnemar_tests': mcnemar_ds
    }

    with open(args.output_dir / 'comprehensive_results.json', 'w') as f:
        json.dump(full_results, f, indent=2, default=str)

    print(f"\nResults written to {args.output_dir}/")

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY: Quality Metrics (Table 3)")
    print("=" * 60)
    print(f"{'Model':<15} {'SUI':>8} {'TDR':>8} {'Prec':>8} {'RCIR':>6} {'AVA':>6} {'FSV':>6} {'LGR':>8}")
    print("-" * 75)

    sorted_combined = sorted(combined.items(), key=lambda x: -x[1].sui)
    for det, m in sorted_combined:
        name = det.split('-')[0].title()[:12]
        print(f"{name:<15} {m.sui:>8.3f} {m.tdr*100:>7.1f}% {m.precision*100:>7.1f}% {m.rcir_mean:>6.2f} {m.ava_mean:>6.2f} {m.fsv_mean:>6.2f} {m.lgr*100:>7.1f}%")

    print("\n" + "=" * 60)
    print("SUI SENSITIVITY ANALYSIS")
    print("=" * 60)
    print("Spearman's ρ between weight configurations:")
    for pair, rho in sensitivity['spearman_rho'].items():
        print(f"  {pair}: ρ = {rho:.3f}")


if __name__ == '__main__':
    main()
