#!/usr/bin/env python3
"""
Sensitivity Analysis for Security Understanding Index (SUI)

Tests SUI rankings under different weight configurations to assess robustness.
"""

import json
from pathlib import Path
from typing import Dict, List, Tuple
import numpy as np
from scipy.stats import spearmanr

# Weight configurations representing different deployment priorities
WEIGHT_CONFIGS = {
    "balanced": {
        "tdr": 0.33,
        "reasoning": 0.33,
        "precision": 0.34,  # 0.34 to sum to 1.0
        "rationale": "Equal importance across all dimensions"
    },
    "default": {
        "tdr": 0.40,
        "reasoning": 0.30,
        "precision": 0.30,
        "rationale": "Practitioner priority: detection first"
    },
    "quality_first": {
        "tdr": 0.30,
        "reasoning": 0.40,
        "precision": 0.30,
        "rationale": "Research focus: explanation quality"
    },
    "precision_first": {
        "tdr": 0.30,
        "reasoning": 0.30,
        "precision": 0.40,
        "rationale": "Production deployment: minimize noise"
    },
    "detection_heavy": {
        "tdr": 0.50,
        "reasoning": 0.25,
        "precision": 0.25,
        "rationale": "Critical infrastructure: detection paramount"
    }
}

# Model display names
MODEL_DISPLAY_NAMES = {
    "claude_opus_4.5": "Claude Opus 4.5",
    "gpt-5.2": "GPT-5.2",
    "gemini_3_pro_preview": "Gemini 3 Pro",
    "grok_4": "Grok 4",
    "deepseek_v3.2": "DeepSeek v3.2",
    "llama_3.1_405b": "Llama 3.1 405B"
}


def load_model_metrics(model_name: str, judge_output_dir: Path) -> Dict:
    """Load aggregated metrics for a model"""
    metrics_file = judge_output_dir / model_name / "aggregated_metrics.json"

    if not metrics_file.exists():
        raise FileNotFoundError(f"Metrics file not found: {metrics_file}")

    with open(metrics_file) as f:
        return json.load(f)


def calculate_sui(metrics: Dict, weights: Dict[str, float]) -> float:
    """
    Calculate SUI with given weights

    SUI = w_tdr * TDR + w_reasoning * Reasoning + w_precision * Finding_Precision
    """
    tdr = metrics["target_finding"]["target_detection_rate"]

    # Average reasoning quality (RCIR + AVA + FSV) / 3
    reasoning_scores = [
        metrics["reasoning_quality"].get("mean_rcir"),
        metrics["reasoning_quality"].get("mean_ava"),
        metrics["reasoning_quality"].get("mean_fsv")
    ]
    valid_reasoning = [s for s in reasoning_scores if s is not None]
    avg_reasoning = np.mean(valid_reasoning) if valid_reasoning else 0.0

    # Finding precision
    finding_precision = metrics["finding_quality"]["finding_precision"]

    # Calculate weighted sum
    sui = (
        weights["tdr"] * tdr +
        weights["reasoning"] * avg_reasoning +
        weights["precision"] * finding_precision
    )

    return sui


def run_sensitivity_analysis(judge_output_dir: Path) -> Dict:
    """Run sensitivity analysis across all models and weight configurations"""

    # Load metrics for all models
    model_metrics = {}
    for model_name in MODEL_DISPLAY_NAMES.keys():
        try:
            model_metrics[model_name] = load_model_metrics(model_name, judge_output_dir)
        except FileNotFoundError as e:
            print(f"Warning: {e}")
            continue

    if not model_metrics:
        raise ValueError("No model metrics found!")

    # Calculate SUI for each model under each configuration
    results = {}
    for config_name, config in WEIGHT_CONFIGS.items():
        results[config_name] = {}

        for model_name, metrics in model_metrics.items():
            sui = calculate_sui(metrics, config)
            results[config_name][model_name] = {
                "sui": sui,
                "tdr": metrics["target_finding"]["target_detection_rate"],
                "reasoning": np.mean([
                    s for s in [
                        metrics["reasoning_quality"].get("mean_rcir"),
                        metrics["reasoning_quality"].get("mean_ava"),
                        metrics["reasoning_quality"].get("mean_fsv")
                    ] if s is not None
                ]) if any(metrics["reasoning_quality"].get(k) for k in ["mean_rcir", "mean_ava", "mean_fsv"]) else 0.0,
                "precision": metrics["finding_quality"]["finding_precision"]
            }

    return results


def compute_rankings(results: Dict) -> Dict[str, List[Tuple[str, int]]]:
    """Compute rankings for each configuration"""
    rankings = {}

    for config_name, model_scores in results.items():
        # Sort by SUI descending
        sorted_models = sorted(
            model_scores.items(),
            key=lambda x: x[1]["sui"],
            reverse=True
        )

        # Assign ranks (1-indexed)
        rankings[config_name] = [(model, rank + 1) for rank, (model, _) in enumerate(sorted_models)]

    return rankings


def compute_ranking_correlations(rankings: Dict) -> Dict[str, float]:
    """Compute Spearman correlation between all pairs of rankings"""
    config_names = list(rankings.keys())
    correlations = {}

    for i, config1 in enumerate(config_names):
        for config2 in config_names[i+1:]:
            # Get rank vectors for common models
            models1 = {model: rank for model, rank in rankings[config1]}
            models2 = {model: rank for model, rank in rankings[config2]}

            common_models = set(models1.keys()) & set(models2.keys())

            ranks1 = [models1[m] for m in sorted(common_models)]
            ranks2 = [models2[m] for m in sorted(common_models)]

            rho, _ = spearmanr(ranks1, ranks2)
            correlations[f"{config1}_vs_{config2}"] = rho

    return correlations


def generate_latex_config_table() -> str:
    """Generate LaTeX table for weight configurations"""
    latex = r"""\begin{table}[h]
\centering
\caption{SUI weight configurations representing different deployment priorities.}
\label{tab:sui_configs}
\small
\begin{tabular}{lcccl}
\toprule
\textbf{Configuration} & \textbf{TDR} & \textbf{Reasoning} & \textbf{Precision} & \textbf{Rationale} \\
\midrule
"""

    config_order = ["balanced", "default", "quality_first", "precision_first", "detection_heavy"]
    config_labels = {
        "balanced": "Balanced",
        "default": "Detection-First (Default)",
        "quality_first": "Quality-First",
        "precision_first": "Precision-First",
        "detection_heavy": "Detection-Heavy"
    }

    for config_name in config_order:
        config = WEIGHT_CONFIGS[config_name]
        label = config_labels[config_name]
        latex += f"{label} & {config['tdr']:.2f} & {config['reasoning']:.2f} & {config['precision']:.2f} & {config['rationale']} \\\\\n"

    latex += r"""\bottomrule
\end{tabular}
\end{table}
"""
    return latex


def generate_latex_results_table(results: Dict, rankings: Dict) -> str:
    """Generate LaTeX table for SUI scores and rankings under each configuration"""
    latex = r"""\begin{table*}[t]
\centering
\caption{Model SUI scores and rankings (in parentheses) under different weight configurations.}
\label{tab:sui_sensitivity}
\small
\begin{tabular}{lccccc}
\toprule
\textbf{Model} & \textbf{Balanced} & \textbf{Default} & \textbf{Quality-First} & \textbf{Precision-First} & \textbf{Detection-Heavy} \\
\midrule
"""

    # Get all models in default ranking order
    default_ranking = sorted(
        results["default"].items(),
        key=lambda x: x[1]["sui"],
        reverse=True
    )

    config_order = ["balanced", "default", "quality_first", "precision_first", "detection_heavy"]

    for model_name, _ in default_ranking:
        display_name = MODEL_DISPLAY_NAMES[model_name]

        row = [display_name]
        for config_name in config_order:
            sui = results[config_name][model_name]["sui"]
            rank_dict = {m: r for m, r in rankings[config_name]}
            rank = rank_dict[model_name]
            row.append(f"{sui:.3f} ({rank})")

        latex += " & ".join(row) + " \\\\\n"

    latex += r"""\bottomrule
\end{tabular}
\end{table*}
"""
    return latex


def generate_summary_statistics(results: Dict, rankings: Dict, correlations: Dict) -> str:
    """Generate summary statistics text"""
    # Average correlation
    avg_correlation = np.mean(list(correlations.values()))
    std_correlation = np.std(list(correlations.values()))

    # Check top-3 stability
    top3_stability = check_top3_stability(rankings)

    summary = f"""
## Sensitivity Analysis Summary

**Ranking Stability:**
- Average Spearman correlation across configurations: ρ = {avg_correlation:.3f} ± {std_correlation:.3f}
- Range: [{min(correlations.values()):.3f}, {max(correlations.values()):.3f}]

**Top-3 Stability:**
{top3_stability}

**Interpretation:**
High correlation (ρ > 0.95) indicates rankings are robust to weight choice.
"""

    return summary


def check_top3_stability(rankings: Dict) -> str:
    """Check if top-3 models remain consistent across configurations"""
    config_names = list(rankings.keys())

    top3_sets = []
    for config_name in config_names:
        top3 = sorted(rankings[config_name], key=lambda x: x[1])[:3]
        top3_models = set(model for model, _ in top3)
        top3_sets.append((config_name, top3_models))

    # Check intersection
    all_top3 = set.intersection(*[s for _, s in top3_sets])

    if len(all_top3) == 3:
        return f"Top-3 models remain unchanged across all configurations: {', '.join([MODEL_DISPLAY_NAMES[m] for m in all_top3])}"
    else:
        return f"Top-3 models vary across configurations. Common in all: {', '.join([MODEL_DISPLAY_NAMES[m] for m in all_top3]) if all_top3 else 'None'}"


def main():
    """Main execution"""
    print("=" * 80)
    print("SUI Sensitivity Analysis")
    print("=" * 80)

    # Setup paths
    base_dir = Path(__file__).parent.parent
    judge_output_dir = base_dir / "judge_output"
    output_dir = base_dir / "analysis_results" / "sensitivity_analysis"
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\nLoading metrics from: {judge_output_dir}")

    # Run analysis
    print("\nRunning sensitivity analysis...")
    results = run_sensitivity_analysis(judge_output_dir)

    print("\nComputing rankings...")
    rankings = compute_rankings(results)

    print("\nComputing ranking correlations...")
    correlations = compute_ranking_correlations(rankings)

    # Print results to console
    print("\n" + "=" * 80)
    print("RESULTS")
    print("=" * 80)

    for config_name in ["balanced", "default", "quality_first", "precision_first", "detection_heavy"]:
        print(f"\n{config_name.upper().replace('_', ' ')}:")
        sorted_models = sorted(
            results[config_name].items(),
            key=lambda x: x[1]["sui"],
            reverse=True
        )
        for rank, (model, scores) in enumerate(sorted_models, 1):
            print(f"  {rank}. {MODEL_DISPLAY_NAMES[model]}: SUI={scores['sui']:.3f} (TDR={scores['tdr']:.3f}, R={scores['reasoning']:.3f}, P={scores['precision']:.3f})")

    print("\n" + "=" * 80)
    print("CORRELATION ANALYSIS")
    print("=" * 80)
    for pair, rho in sorted(correlations.items()):
        print(f"{pair}: ρ = {rho:.3f}")

    avg_rho = np.mean(list(correlations.values()))
    print(f"\nAverage correlation: ρ = {avg_rho:.3f} ± {np.std(list(correlations.values())):.3f}")

    # Generate LaTeX tables
    print("\n" + "=" * 80)
    print("GENERATING LATEX TABLES")
    print("=" * 80)

    config_table = generate_latex_config_table()
    results_table = generate_latex_results_table(results, rankings)
    summary = generate_summary_statistics(results, rankings, correlations)

    # Save outputs
    with open(output_dir / "config_table.tex", "w") as f:
        f.write(config_table)
    print(f"✓ Saved: {output_dir / 'config_table.tex'}")

    with open(output_dir / "results_table.tex", "w") as f:
        f.write(results_table)
    print(f"✓ Saved: {output_dir / 'results_table.tex'}")

    with open(output_dir / "summary.txt", "w") as f:
        f.write(summary)
    print(f"✓ Saved: {output_dir / 'summary.txt'}")

    # Save full results as JSON
    output_data = {
        "results": results,
        "rankings": {k: [(m, r) for m, r in v] for k, v in rankings.items()},
        "correlations": correlations,
        "summary_stats": {
            "avg_correlation": float(avg_rho),
            "std_correlation": float(np.std(list(correlations.values()))),
            "min_correlation": float(min(correlations.values())),
            "max_correlation": float(max(correlations.values()))
        }
    }

    with open(output_dir / "sensitivity_analysis.json", "w") as f:
        json.dump(output_data, f, indent=2)
    print(f"✓ Saved: {output_dir / 'sensitivity_analysis.json'}")

    print("\n" + "=" * 80)
    print("DONE!")
    print("=" * 80)


if __name__ == "__main__":
    main()
