#!/usr/bin/env python3
"""
Comprehensive Sensitivity Analysis by Dataset Subset

Runs SUI sensitivity analysis on:
1. Full evaluation set (all samples)
2. Gold Standard only (GS samples)
3. Temporal Contamination only (TC samples)
4. Difficulty Stratified only (DS samples)

Saves results to separate folders for comparison.
"""

import json
from pathlib import Path
from typing import Dict, List, Tuple, Set
import numpy as np
from scipy.stats import spearmanr

# Weight configurations
WEIGHT_CONFIGS = {
    "balanced": {"tdr": 0.33, "reasoning": 0.33, "precision": 0.34},
    "default": {"tdr": 0.40, "reasoning": 0.30, "precision": 0.30},
    "quality_first": {"tdr": 0.30, "reasoning": 0.40, "precision": 0.30},
    "precision_first": {"tdr": 0.30, "reasoning": 0.30, "precision": 0.40},
    "detection_heavy": {"tdr": 0.50, "reasoning": 0.25, "precision": 0.25}
}

MODEL_DISPLAY_NAMES = {
    "claude_opus_4.5": "Claude Opus 4.5",
    "gpt-5.2": "GPT-5.2",
    "gemini_3_pro_preview": "Gemini 3 Pro",
    "grok_4": "Grok 4",
    "deepseek_v3.2": "DeepSeek v3.2",
    "llama_3.1_405b": "Llama 3.1 405B"
}


def get_sample_subset(sample_id: str) -> str:
    """Determine which subset a sample belongs to"""
    if sample_id.startswith('gs_'):
        return 'gold_standard'
    elif sample_id.startswith('tc_') or any(x in sample_id for x in ['_tc_', 'tc00']):
        return 'temporal_contamination'
    elif sample_id.startswith('ds_'):
        return 'difficulty_stratified'
    else:
        # Check if it contains subset indicators
        if 'gold' in sample_id.lower() or 'gs' in sample_id:
            return 'gold_standard'
        elif 'temporal' in sample_id.lower() or '_tc' in sample_id:
            return 'temporal_contamination'
        else:
            return 'difficulty_stratified'


def load_sample_metrics(model_name: str, judge_output_dir: Path, subset_filter: Set[str] = None) -> Dict:
    """Load sample-level metrics for a model, optionally filtered by subset"""
    sample_metrics_dir = judge_output_dir / model_name / "sample_metrics"

    if not sample_metrics_dir.exists():
        print(f"Warning: No sample metrics found for {model_name}")
        return {}

    metrics_by_sample = {}

    for metrics_file in sample_metrics_dir.glob("m_*.json"):
        sample_id = metrics_file.stem.replace("m_", "")

        # Determine subset
        sample_subset = get_sample_subset(sample_id)

        # Filter if requested
        if subset_filter and sample_subset not in subset_filter:
            continue

        with open(metrics_file) as f:
            metrics_by_sample[sample_id] = json.load(f)

    return metrics_by_sample


def aggregate_metrics(sample_metrics: Dict) -> Dict:
    """Aggregate sample-level metrics to model-level"""
    if not sample_metrics:
        return {
            "target_detection_rate": 0.0,
            "mean_reasoning": 0.0,
            "finding_precision": 0.0,
            "num_samples": 0
        }

    total_samples = len(sample_metrics)
    targets_found = sum(1 for m in sample_metrics.values() if m.get("target_found", False))

    # TDR
    tdr = targets_found / total_samples if total_samples > 0 else 0.0

    # Reasoning quality (only for samples where target was found)
    reasoning_scores = []
    for sample_id, metrics in sample_metrics.items():
        if metrics.get("target_found", False):
            rcir = metrics.get("rcir_score")
            ava = metrics.get("ava_score")
            fsv = metrics.get("fsv_score")

            if all(score is not None for score in [rcir, ava, fsv]):
                reasoning_scores.append((rcir + ava + fsv) / 3.0)

    mean_reasoning = np.mean(reasoning_scores) if reasoning_scores else 0.0

    # Finding precision (average across all samples)
    precision_scores = [m.get("finding_precision", 0) for m in sample_metrics.values()
                       if m.get("finding_precision") is not None]
    finding_precision = np.mean(precision_scores) if precision_scores else 0.0

    return {
        "target_detection_rate": tdr,
        "mean_reasoning": mean_reasoning,
        "finding_precision": finding_precision,
        "num_samples": total_samples,
        "targets_found": targets_found
    }


def calculate_sui(metrics: Dict, weights: Dict[str, float]) -> float:
    """Calculate SUI with given weights"""
    return (
        weights["tdr"] * metrics["target_detection_rate"] +
        weights["reasoning"] * metrics["mean_reasoning"] +
        weights["precision"] * metrics["finding_precision"]
    )


def run_sensitivity_for_subset(judge_output_dir: Path, subset_name: str, subset_filter: Set[str]) -> Dict:
    """Run sensitivity analysis for a specific subset"""
    print(f"\n  Analyzing {subset_name}...")

    # Load and aggregate metrics for each model
    model_aggregated = {}
    for model_name in MODEL_DISPLAY_NAMES.keys():
        sample_metrics = load_sample_metrics(model_name, judge_output_dir, subset_filter)

        if not sample_metrics:
            print(f"    Warning: No samples found for {model_name} in {subset_name}")
            continue

        model_aggregated[model_name] = aggregate_metrics(sample_metrics)
        print(f"    {MODEL_DISPLAY_NAMES[model_name]}: {model_aggregated[model_name]['num_samples']} samples")

    if not model_aggregated:
        print(f"    ERROR: No data found for {subset_name}")
        return None

    # Calculate SUI for each configuration
    results = {}
    for config_name, weights in WEIGHT_CONFIGS.items():
        results[config_name] = {}

        for model_name, metrics in model_aggregated.items():
            sui = calculate_sui(metrics, weights)
            results[config_name][model_name] = {
                "sui": sui,
                "tdr": metrics["target_detection_rate"],
                "reasoning": metrics["mean_reasoning"],
                "precision": metrics["finding_precision"],
                "num_samples": metrics["num_samples"]
            }

    return results


def compute_rankings(results: Dict) -> Dict:
    """Compute rankings for each configuration"""
    rankings = {}

    for config_name, model_scores in results.items():
        sorted_models = sorted(
            model_scores.items(),
            key=lambda x: x[1]["sui"],
            reverse=True
        )
        rankings[config_name] = [(model, rank + 1) for rank, (model, _) in enumerate(sorted_models)]

    return rankings


def compute_correlations(rankings: Dict) -> Dict:
    """Compute Spearman correlation between all ranking pairs"""
    config_names = list(rankings.keys())
    correlations = {}

    for i, config1 in enumerate(config_names):
        for config2 in config_names[i+1:]:
            models1 = {model: rank for model, rank in rankings[config1]}
            models2 = {model: rank for model, rank in rankings[config2]}
            common_models = set(models1.keys()) & set(models2.keys())

            if len(common_models) < 2:
                continue

            ranks1 = [models1[m] for m in sorted(common_models)]
            ranks2 = [models2[m] for m in sorted(common_models)]

            rho, _ = spearmanr(ranks1, ranks2)
            correlations[f"{config1}_vs_{config2}"] = rho

    return correlations


def generate_latex_table(results: Dict, rankings: Dict, subset_name: str) -> str:
    """Generate LaTeX table for results"""
    latex = f"""\\begin{{table*}}[t]
\\centering
\\caption{{Model SUI scores and rankings for {subset_name} subset.}}
\\label{{tab:sui_sensitivity_{subset_name.lower().replace(' ', '_')}}}
\\small
\\begin{{tabular}}{{lccccc}}
\\toprule
\\textbf{{Model}} & \\textbf{{Balanced}} & \\textbf{{Default}} & \\textbf{{Quality-First}} & \\textbf{{Precision-First}} & \\textbf{{Detection-Heavy}} \\\\
\\midrule
"""

    # Get default ordering
    default_order = sorted(
        results["default"].items(),
        key=lambda x: x[1]["sui"],
        reverse=True
    )

    config_order = ["balanced", "default", "quality_first", "precision_first", "detection_heavy"]

    for model_name, _ in default_order:
        display_name = MODEL_DISPLAY_NAMES[model_name]
        row = [display_name]

        for config_name in config_order:
            sui = results[config_name][model_name]["sui"]
            rank_dict = {m: r for m, r in rankings[config_name]}
            rank = rank_dict[model_name]
            row.append(f"{sui:.3f} ({rank})")

        latex += " & ".join(row) + " \\\\\\\n"

    latex += """\\bottomrule
\\end{tabular}
\\end{table*}
"""
    return latex


def save_results(results: Dict, rankings: Dict, correlations: Dict, subset_name: str, output_dir: Path):
    """Save all results for a subset"""
    subset_dir = output_dir / subset_name.lower().replace(' ', '_')
    subset_dir.mkdir(parents=True, exist_ok=True)

    # Save JSON
    output_data = {
        "subset": subset_name,
        "results": results,
        "rankings": {k: [(m, r) for m, r in v] for k, v in rankings.items()},
        "correlations": correlations,
        "summary_stats": {
            "avg_correlation": float(np.mean(list(correlations.values()))) if correlations else 0.0,
            "std_correlation": float(np.std(list(correlations.values()))) if correlations else 0.0,
            "min_correlation": float(min(correlations.values())) if correlations else 0.0,
            "max_correlation": float(max(correlations.values())) if correlations else 0.0
        }
    }

    with open(subset_dir / "sensitivity_analysis.json", "w") as f:
        json.dump(output_data, f, indent=2)

    # Save LaTeX table
    latex_table = generate_latex_table(results, rankings, subset_name)
    with open(subset_dir / "results_table.tex", "w") as f:
        f.write(latex_table)

    # Save summary
    avg_rho = np.mean(list(correlations.values())) if correlations else 0.0
    std_rho = np.std(list(correlations.values())) if correlations else 0.0

    summary = f"""# Sensitivity Analysis: {subset_name}

## Rankings by Configuration

"""

    for config_name in ["default", "balanced", "quality_first", "precision_first", "detection_heavy"]:
        summary += f"\n### {config_name.replace('_', ' ').title()}\n\n"
        sorted_models = sorted(
            results[config_name].items(),
            key=lambda x: x[1]["sui"],
            reverse=True
        )
        for rank, (model, scores) in enumerate(sorted_models, 1):
            summary += f"{rank}. {MODEL_DISPLAY_NAMES[model]}: SUI={scores['sui']:.3f} (TDR={scores['tdr']:.1%}, R={scores['reasoning']:.3f}, P={scores['precision']:.1%})\n"

    summary += f"""
## Ranking Stability

- Average Spearman ρ: {avg_rho:.3f} ± {std_rho:.3f}
- Range: [{min(correlations.values()) if correlations else 0:.3f}, {max(correlations.values()) if correlations else 0:.3f}]

## Interpretation

{'High correlation (ρ > 0.95) indicates robust rankings.' if avg_rho > 0.95 else 'Moderate correlation indicates some ranking variation across weight choices.'}
"""

    with open(subset_dir / "summary.md", "w") as f:
        f.write(summary)

    print(f"  ✓ Saved results to: {subset_dir}")


def main():
    print("=" * 80)
    print("COMPREHENSIVE SENSITIVITY ANALYSIS BY SUBSET")
    print("=" * 80)

    base_dir = Path(__file__).parent.parent
    judge_output_dir = base_dir / "judge_output"
    output_dir = base_dir / "analysis_results" / "sensitivity_analysis_comprehensive"

    # Define subsets to analyze
    subsets = {
        "Full Evaluation": None,  # All samples
        "Gold Standard": {"gold_standard"},
        "Temporal Contamination": {"temporal_contamination"},
        "Difficulty Stratified": {"difficulty_stratified"}
    }

    for subset_name, subset_filter in subsets.items():
        print(f"\n{'='*80}")
        print(f"SUBSET: {subset_name}")
        print(f"{'='*80}")

        results = run_sensitivity_for_subset(judge_output_dir, subset_name, subset_filter)

        if results is None:
            print(f"  Skipping {subset_name} due to missing data")
            continue

        rankings = compute_rankings(results)
        correlations = compute_correlations(rankings)

        # Print console summary
        print(f"\n  Default Configuration Rankings:")
        for model, rank in sorted(rankings["default"], key=lambda x: x[1]):
            sui = results["default"][model]["sui"]
            print(f"    {rank}. {MODEL_DISPLAY_NAMES[model]}: SUI={sui:.3f}")

        if correlations:
            avg_rho = np.mean(list(correlations.values()))
            print(f"\n  Average correlation: ρ = {avg_rho:.3f}")

        save_results(results, rankings, correlations, subset_name, output_dir)

    print("\n" + "=" * 80)
    print("✅ COMPREHENSIVE ANALYSIS COMPLETE")
    print("=" * 80)
    print(f"\nResults saved to: {output_dir}")
    print("\nGenerated subdirectories:")
    for subset_name in subsets.keys():
        subdir = subset_name.lower().replace(' ', '_')
        print(f"  - {subdir}/")


if __name__ == "__main__":
    main()
