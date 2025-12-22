#!/usr/bin/env python3
"""
Calculate Security Understanding Index (SUI) for overall results table.

Computes SUI across all samples for each model using the formula:
SUI = 0.40·TDR + 0.30·Reasoning + 0.30·Precision

Output:
- Console summary with rankings
- JSON file with detailed metrics
- LaTeX table snippet for results.tex
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
import statistics

BASE_DIR = Path(__file__).parent.parent
JUDGE_OUTPUT_DIR = BASE_DIR / 'judge_output'
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'overall_sui'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Models to evaluate
MODELS = [
    'claude_opus_4.5',
    'deepseek_v3.2',
    'gemini_3_pro_preview',
    'gpt-5.2',
    'grok_4',
    'llama_3.1_405b'
]

MODEL_DISPLAY_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'deepseek_v3.2': 'DeepSeek v3.2',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'grok_4': 'Grok 4',
    'llama_3.1_405b': 'Llama 3.1 405B'
}

# SUI weights (matching paper formula)
W_TDR = 0.40
W_REASONING = 0.30
W_PRECISION = 0.30


def load_all_sample_metrics(model: str) -> List[Dict]:
    """Load all sample metrics for a model."""
    metrics_dir = JUDGE_OUTPUT_DIR / model / 'sample_metrics'

    if not metrics_dir.exists():
        print(f"  Warning: No sample_metrics directory for {model}")
        return []

    all_metrics = []
    for metrics_file in metrics_dir.glob('m_*.json'):
        try:
            with open(metrics_file, 'r') as f:
                metrics = json.load(f)
                all_metrics.append(metrics)
        except Exception as e:
            print(f"  Warning: Error loading {metrics_file}: {e}")

    return all_metrics


def calculate_model_metrics(sample_metrics: List[Dict]) -> Dict:
    """Calculate aggregate metrics for a model.

    Returns:
        Dictionary with TDR, reasoning quality, precision, and SUI
    """
    if not sample_metrics:
        return {
            'total_samples': 0,
            'vulnerable_samples': 0,
            'target_detection_rate': 0.0,
            'mean_reasoning': 0.0,
            'finding_precision': 0.0,
            'sui': 0.0,
            'accuracy': 0.0,
            'avg_findings': 0.0
        }

    total_samples = len(sample_metrics)

    # Count vulnerable samples
    vulnerable_samples = sum(1 for m in sample_metrics if m.get('ground_truth_vulnerable', False))

    # === TARGET DETECTION RATE ===
    # Only count samples where target was actually found
    targets_found = sum(1 for m in sample_metrics if m.get('target_found', False))
    tdr = targets_found / vulnerable_samples if vulnerable_samples > 0 else 0.0

    # === REASONING QUALITY ===
    # Average of RCIR, AVA, FSV scores (only for samples where target was found)
    reasoning_scores = []
    for m in sample_metrics:
        if m.get('target_found', False):
            rcir = m.get('rcir_score')
            ava = m.get('ava_score')
            fsv = m.get('fsv_score')

            if all(score is not None for score in [rcir, ava, fsv]):
                avg_reasoning = (rcir + ava + fsv) / 3.0
                reasoning_scores.append(avg_reasoning)

    mean_reasoning = statistics.mean(reasoning_scores) if reasoning_scores else 0.0

    # === FINDING PRECISION ===
    # Average finding precision across all samples
    precision_scores = [m.get('finding_precision', 0) for m in sample_metrics
                       if m.get('finding_precision') is not None]
    finding_precision = statistics.mean(precision_scores) if precision_scores else 0.0

    # === SECURITY UNDERSTANDING INDEX ===
    sui = W_TDR * tdr + W_REASONING * mean_reasoning + W_PRECISION * finding_precision

    # === OTHER METRICS FOR TABLE ===
    # Accuracy (binary classification)
    correct_detections = sum(1 for m in sample_metrics if m.get('detection_correct', False))
    accuracy = correct_detections / total_samples if total_samples > 0 else 0.0

    # Average findings per sample
    total_findings = sum(m.get('total_findings', 0) for m in sample_metrics)
    avg_findings = total_findings / total_samples if total_samples > 0 else 0.0

    return {
        'total_samples': total_samples,
        'vulnerable_samples': vulnerable_samples,
        'target_detection_rate': tdr,
        'mean_reasoning': mean_reasoning,
        'rcir_scores': [m.get('rcir_score', 0) for m in sample_metrics if m.get('target_found', False)],
        'ava_scores': [m.get('ava_score', 0) for m in sample_metrics if m.get('target_found', False)],
        'fsv_scores': [m.get('fsv_score', 0) for m in sample_metrics if m.get('target_found', False)],
        'finding_precision': finding_precision,
        'sui': sui,
        'accuracy': accuracy,
        'avg_findings': avg_findings,
        'targets_found': targets_found
    }


def generate_latex_table(results: Dict[str, Dict]) -> str:
    """Generate LaTeX table for results.tex"""

    # Sort by TDR (descending)
    sorted_models = sorted(results.items(), key=lambda x: x[1]['target_detection_rate'], reverse=True)

    latex = """\\begin{table*}[!ht]
\\centering
\\small
\\caption{Overall performance ranked by Target Detection Rate. Best values bold.}
\\label{tab:overall_results}
\\begin{tabular}{@{}lccccccc@{}}
\\toprule
\\textbf{Model} & \\textbf{TDR} & \\textbf{SUI} & \\textbf{Acc} & \\textbf{RCIR} & \\textbf{AVA} & \\textbf{FSV} & \\textbf{Findings} \\\\
\\midrule
"""

    # Find best values for bolding
    best_tdr = max(m['target_detection_rate'] for m in results.values())
    best_sui = max(m['sui'] for m in results.values())
    best_acc = max(m['accuracy'] for m in results.values())
    best_rcir = max(statistics.mean(m['rcir_scores']) if m['rcir_scores'] else 0 for m in results.values())
    best_ava = max(statistics.mean(m['ava_scores']) if m['ava_scores'] else 0 for m in results.values())
    best_fsv = max(statistics.mean(m['fsv_scores']) if m['fsv_scores'] else 0 for m in results.values())

    for model_name, metrics in sorted_models:
        display_name = MODEL_DISPLAY_NAMES[model_name]

        tdr = metrics['target_detection_rate'] * 100
        sui = metrics['sui']
        acc = metrics['accuracy'] * 100
        rcir = statistics.mean(metrics['rcir_scores']) if metrics['rcir_scores'] else 0
        ava = statistics.mean(metrics['ava_scores']) if metrics['ava_scores'] else 0
        fsv = statistics.mean(metrics['fsv_scores']) if metrics['fsv_scores'] else 0
        findings = metrics['avg_findings']

        # Bold best values
        tdr_str = f"\\textbf{{{tdr:.1f}}}" if abs(metrics['target_detection_rate'] - best_tdr) < 0.001 else f"{tdr:.1f}"
        sui_str = f"\\textbf{{{sui:.3f}}}" if abs(metrics['sui'] - best_sui) < 0.001 else f"{sui:.3f}"
        acc_str = f"\\textbf{{{acc:.1f}}}" if abs(metrics['accuracy'] - best_acc) < 0.001 else f"{acc:.1f}"
        rcir_str = f"\\textbf{{{rcir:.2f}}}" if rcir > 0 and abs(rcir - best_rcir) < 0.001 else f"{rcir:.2f}"
        ava_str = f"\\textbf{{{ava:.2f}}}" if ava > 0 and abs(ava - best_ava) < 0.001 else f"{ava:.2f}"
        fsv_str = f"\\textbf{{{fsv:.2f}}}" if fsv > 0 and abs(fsv - best_fsv) < 0.001 else f"{fsv:.2f}"

        latex += f"{display_name} & {tdr_str} & {sui_str} & {acc_str} & {rcir_str} & {ava_str} & {fsv_str} & {findings:.1f} \\\\\\\\\n"

    latex += """\\bottomrule
\\end{tabular}
\\end{table*}
"""

    return latex


def main():
    print("=" * 80)
    print("OVERALL SUI CALCULATION")
    print("=" * 80)
    print()
    print(f"Formula: SUI = {W_TDR}·TDR + {W_REASONING}·Reasoning + {W_PRECISION}·Precision")
    print()

    all_results = {}

    for model in MODELS:
        print(f"Processing {MODEL_DISPLAY_NAMES[model]}...")

        # Load all sample metrics
        sample_metrics = load_all_sample_metrics(model)

        if not sample_metrics:
            print(f"  ❌ No metrics found!")
            continue

        # Calculate aggregate metrics
        metrics = calculate_model_metrics(sample_metrics)
        all_results[model] = metrics

        print(f"  Samples: {metrics['total_samples']} (vulnerable: {metrics['vulnerable_samples']})")
        print(f"  TDR: {metrics['target_detection_rate']:.1%} ({metrics['targets_found']} targets found)")
        print(f"  Reasoning Quality: {metrics['mean_reasoning']:.3f}")
        print(f"  Finding Precision: {metrics['finding_precision']:.1%}")
        print(f"  → SUI: {metrics['sui']:.3f}")
        print()

    # Sort by SUI
    sorted_by_sui = sorted(all_results.items(), key=lambda x: x[1]['sui'], reverse=True)

    print("=" * 80)
    print("RANKINGS BY SUI")
    print("=" * 80)
    print()

    for rank, (model, metrics) in enumerate(sorted_by_sui, 1):
        print(f"{rank}. {MODEL_DISPLAY_NAMES[model]}: SUI={metrics['sui']:.3f}")

    print()

    # Save results
    output_json = OUTPUT_DIR / 'overall_sui_results.json'
    with open(output_json, 'w') as f:
        json.dump({
            'formula': f'SUI = {W_TDR}·TDR + {W_REASONING}·Reasoning + {W_PRECISION}·Precision',
            'weights': {'tdr': W_TDR, 'reasoning': W_REASONING, 'precision': W_PRECISION},
            'results': all_results,
            'rankings': [(model, metrics['sui']) for model, metrics in sorted_by_sui]
        }, f, indent=2)

    print(f"✓ Saved JSON results: {output_json}")

    # Generate LaTeX table
    latex_table = generate_latex_table(all_results)
    output_tex = OUTPUT_DIR / 'results_table.tex'
    with open(output_tex, 'w') as f:
        f.write(latex_table)

    print(f"✓ Saved LaTeX table: {output_tex}")

    # Save detailed breakdown
    output_md = OUTPUT_DIR / 'detailed_breakdown.md'
    with open(output_md, 'w') as f:
        f.write("# Overall SUI Calculation - Detailed Breakdown\n\n")
        f.write(f"**Formula:** SUI = {W_TDR}·TDR + {W_REASONING}·Reasoning + {W_PRECISION}·Precision\n\n")

        for rank, (model, metrics) in enumerate(sorted_by_sui, 1):
            f.write(f"## {rank}. {MODEL_DISPLAY_NAMES[model]}\n\n")
            f.write(f"- **Total Samples:** {metrics['total_samples']}\n")
            f.write(f"- **Vulnerable Samples:** {metrics['vulnerable_samples']}\n")
            f.write(f"- **Targets Found:** {metrics['targets_found']}\n")
            f.write(f"- **TDR:** {metrics['target_detection_rate']:.1%}\n")
            f.write(f"- **Mean Reasoning:** {metrics['mean_reasoning']:.3f}\n")
            f.write(f"  - RCIR: {statistics.mean(metrics['rcir_scores']) if metrics['rcir_scores'] else 0:.3f}\n")
            f.write(f"  - AVA: {statistics.mean(metrics['ava_scores']) if metrics['ava_scores'] else 0:.3f}\n")
            f.write(f"  - FSV: {statistics.mean(metrics['fsv_scores']) if metrics['fsv_scores'] else 0:.3f}\n")
            f.write(f"- **Finding Precision:** {metrics['finding_precision']:.1%}\n")
            f.write(f"- **Accuracy:** {metrics['accuracy']:.1%}\n")
            f.write(f"- **Avg Findings per Sample:** {metrics['avg_findings']:.1f}\n\n")

            # Show SUI calculation
            sui_calc = (W_TDR * metrics['target_detection_rate'] +
                       W_REASONING * metrics['mean_reasoning'] +
                       W_PRECISION * metrics['finding_precision'])
            f.write(f"**SUI Calculation:**\n")
            f.write(f"```\n")
            f.write(f"SUI = {W_TDR}×{metrics['target_detection_rate']:.3f} + {W_REASONING}×{metrics['mean_reasoning']:.3f} + {W_PRECISION}×{metrics['finding_precision']:.3f}\n")
            f.write(f"    = {W_TDR * metrics['target_detection_rate']:.3f} + {W_REASONING * metrics['mean_reasoning']:.3f} + {W_PRECISION * metrics['finding_precision']:.3f}\n")
            f.write(f"    = {sui_calc:.3f}\n")
            f.write(f"```\n\n")

    print(f"✓ Saved detailed breakdown: {output_md}")

    print()
    print("=" * 80)
    print("✅ CALCULATION COMPLETE")
    print("=" * 80)
    print()
    print("Next steps:")
    print("1. Review the generated LaTeX table in:")
    print(f"   {output_tex}")
    print("2. Copy the table to research/aberdeen_eval_project_ws2024/results.tex")
    print()


if __name__ == '__main__':
    main()
