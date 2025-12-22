#!/usr/bin/env python3
"""
Analyze model performance on Gold Standard (gs) samples.

Gold standard samples are manually curated, high-quality benchmark samples
that represent real-world vulnerabilities with expert-validated ground truth.
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 8)
plt.rcParams['font.size'] = 10

BASE_DIR = Path(__file__).parent.parent
JUDGE_OUTPUT_DIR = BASE_DIR / 'judge_output'
GT_DIR = BASE_DIR / 'samples' / 'ground_truth'
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'gold_standard_analysis'

# Create output directory
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MODELS = [
    'claude_opus_4.5',
    'deepseek_v3.2',
    'gemini_3_pro_preview',
    'gpt-5.2',
    'grok_4',
    'llama_3.1_405b'
]

def get_model_display_name(model: str) -> str:
    """Convert model name to display-friendly format."""
    name_map = {
        'claude_opus_4.5': 'Claude Opus 4.5',
        'deepseek_v3.2': 'DeepSeek v3.2',
        'gemini_3_pro_preview': 'Gemini 3 Pro',
        'gpt-5.2': 'GPT-5.2',
        'grok_4': 'Grok 4',
        'llama_3.1_405b': 'Llama 3.1 405B'
    }
    return name_map.get(model, model)

def get_gold_standard_samples() -> list:
    """Get list of all gold standard sample IDs."""
    gs_samples = []
    for file in GT_DIR.glob('*_gs_*.json'):
        sample_id = file.stem
        gs_samples.append(sample_id)
    return sorted(gs_samples)

def load_sample_metrics(model: str, sample_id: str, prompt_type: str = 'direct') -> dict:
    """Load metrics for a specific sample."""
    metrics_file = JUDGE_OUTPUT_DIR / model / 'sample_metrics' / f'm_{sample_id}_{prompt_type}.json'

    if not metrics_file.exists():
        return None

    with open(metrics_file, 'r') as f:
        return json.load(f)

def load_ground_truth(sample_id: str) -> dict:
    """Load ground truth for a sample."""
    gt_file = GT_DIR / f'{sample_id}.json'

    if not gt_file.exists():
        return None

    with open(gt_file, 'r') as f:
        return json.load(f)

def extract_gold_standard_data():
    """Extract performance data on gold standard samples."""
    gs_samples = get_gold_standard_samples()
    data = []

    print(f"Found {len(gs_samples)} gold standard samples:")
    for sample in gs_samples:
        print(f"  - {sample}")
    print()

    for model in MODELS:
        model_name = get_model_display_name(model)

        # Overall metrics for this model on GS samples
        gs_metrics = []

        for sample_id in gs_samples:
            metrics = load_sample_metrics(model, sample_id, 'direct')
            gt = load_ground_truth(sample_id)

            if metrics and gt:
                gs_metrics.append({
                    'sample_id': sample_id,
                    'metrics': metrics,
                    'ground_truth': gt
                })

        if gs_metrics:
            # Calculate aggregates
            total = len(gs_metrics)
            targets_found = sum(1 for m in gs_metrics if m['metrics'].get('target_found', False))
            detection_correct = sum(1 for m in gs_metrics if m['metrics'].get('detection_correct', False))

            # Quality scores (only from samples where target was found)
            quality_scores = [m['metrics'].get('rcir_score') for m in gs_metrics
                            if m['metrics'].get('target_found') and m['metrics'].get('rcir_score') is not None]
            avg_quality = np.mean(quality_scores) if quality_scores else 0

            # Finding precision
            precisions = [m['metrics'].get('finding_precision', 0) for m in gs_metrics]
            avg_precision = np.mean(precisions) if precisions else 0

            data.append({
                'Model': model_name,
                'Detection Rate': (targets_found / total * 100) if total > 0 else 0,
                'Accuracy': (detection_correct / total * 100) if total > 0 else 0,
                'Quality Score': avg_quality * 100 if avg_quality > 0 else 0,
                'Finding Precision': avg_precision * 100,
                'Total Samples': total,
                'Targets Found': targets_found
            })

    return pd.DataFrame(data), gs_samples

def load_overall_metrics():
    """Load overall metrics for comparison."""
    metrics_file = BASE_DIR / 'analysis_results' / 'aggregated_metrics.json'
    with open(metrics_file, 'r') as f:
        return json.load(f)

def plot_gs_vs_overall_detection(gs_df, overall_metrics):
    """Compare GS detection rate vs overall."""
    fig, ax = plt.subplots(figsize=(14, 8))

    # Prepare data
    models = []
    gs_rates = []
    overall_rates = []

    for _, row in gs_df.iterrows():
        model = row['Model']
        models.append(model)
        gs_rates.append(row['Detection Rate'])

        # Get overall rate (direct prompts only for fair comparison)
        model_key = [k for k, v in {
            'claude_opus_4.5': 'Claude Opus 4.5',
            'deepseek_v3.2': 'DeepSeek v3.2',
            'gemini_3_pro_preview': 'Gemini 3 Pro',
            'gpt-5.2': 'GPT-5.2',
            'grok_4': 'Grok 4',
            'llama_3.1_405b': 'Llama 3.1 405B'
        }.items() if v == model][0]

        # Use direct prompts only for fair comparison
        overall_direct = overall_metrics['by_model'][model_key]['by_prompt_type']['direct']
        overall_rates.append(overall_direct['target']['target_detection_rate'] * 100)

    x = np.arange(len(models))
    width = 0.35

    bars1 = ax.bar(x - width/2, gs_rates, width, label='Gold Standard (Direct Prompts)',
                   color='#e74c3c', alpha=0.8)
    bars2 = ax.bar(x + width/2, overall_rates, width, label='Overall (Direct Prompts)',
                   color='#3498db', alpha=0.8)

    ax.set_ylabel('Detection Rate (%)', fontsize=12)
    ax.set_xlabel('Model', fontsize=12)
    ax.set_title('Detection Rate: Gold Standard vs Overall (Direct Prompts Only)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xticks(x)
    ax.set_xticklabels(models, rotation=45, ha='right')
    ax.legend(fontsize=11)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    # Add value labels
    for bars in [bars1, bars2]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 1,
                   f'{height:.1f}%', ha='center', va='bottom', fontsize=9)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '01_gs_vs_overall_detection.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 01_gs_vs_overall_detection.png")

def plot_gs_performance_breakdown(gs_df):
    """Plot detailed breakdown of GS performance."""
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))

    # 1. Detection Rate
    ax = axes[0, 0]
    sorted_df = gs_df.sort_values('Detection Rate', ascending=True)
    colors = sns.color_palette("RdYlGn", len(sorted_df))
    bars = ax.barh(sorted_df['Model'], sorted_df['Detection Rate'], color=colors)
    ax.set_xlabel('Detection Rate (%)', fontsize=11)
    ax.set_title('Target Detection Rate on Gold Standard', fontsize=12, fontweight='bold')
    ax.set_xlim(0, 100)
    ax.grid(axis='x', alpha=0.3)
    for i, bar in enumerate(bars):
        width = bar.get_width()
        targets = sorted_df.iloc[i]['Targets Found']
        total = sorted_df.iloc[i]['Total Samples']
        ax.text(width + 2, bar.get_y() + bar.get_height()/2,
               f'{width:.1f}% ({int(targets)}/{int(total)})',
               va='center', fontsize=9)

    # 2. Quality Score
    ax = axes[0, 1]
    quality_df = gs_df[gs_df['Quality Score'] > 0].sort_values('Quality Score', ascending=True)
    if len(quality_df) > 0:
        colors = sns.color_palette("Blues", len(quality_df))
        bars = ax.barh(quality_df['Model'], quality_df['Quality Score'], color=colors)
        ax.set_xlabel('Quality Score (%)', fontsize=11)
        ax.set_title('Response Quality (when target found)', fontsize=12, fontweight='bold')
        ax.set_xlim(0, 100)
        ax.grid(axis='x', alpha=0.3)
        for bar in bars:
            width = bar.get_width()
            if width > 0:
                ax.text(width + 2, bar.get_y() + bar.get_height()/2,
                       f'{width:.1f}%', va='center', fontsize=9)

    # 3. Finding Precision
    ax = axes[1, 0]
    sorted_df = gs_df.sort_values('Finding Precision', ascending=True)
    colors = sns.color_palette("Purples", len(sorted_df))
    bars = ax.barh(sorted_df['Model'], sorted_df['Finding Precision'], color=colors)
    ax.set_xlabel('Finding Precision (%)', fontsize=11)
    ax.set_title('Finding Precision (avoiding false positives)', fontsize=12, fontweight='bold')
    ax.set_xlim(0, 100)
    ax.grid(axis='x', alpha=0.3)
    for bar in bars:
        width = bar.get_width()
        ax.text(width + 2, bar.get_y() + bar.get_height()/2,
               f'{width:.1f}%', va='center', fontsize=9)

    # 4. Accuracy
    ax = axes[1, 1]
    sorted_df = gs_df.sort_values('Accuracy', ascending=True)
    colors = sns.color_palette("Greens", len(sorted_df))
    bars = ax.barh(sorted_df['Model'], sorted_df['Accuracy'], color=colors)
    ax.set_xlabel('Accuracy (%)', fontsize=11)
    ax.set_title('Overall Accuracy', fontsize=12, fontweight='bold')
    ax.set_xlim(0, 100)
    ax.grid(axis='x', alpha=0.3)
    for bar in bars:
        width = bar.get_width()
        ax.text(width + 2, bar.get_y() + bar.get_height()/2,
               f'{width:.1f}%', va='center', fontsize=9)

    plt.suptitle('Gold Standard Performance Breakdown', fontsize=14, fontweight='bold', y=0.995)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '02_gs_performance_breakdown.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 02_gs_performance_breakdown.png")

def plot_per_sample_heatmap(gs_samples):
    """Create heatmap showing which models found each GS sample."""
    fig, ax = plt.subplots(figsize=(14, 10))

    # Build matrix: rows=models, cols=samples
    matrix = []
    model_names = []

    for model in MODELS:
        model_name = get_model_display_name(model)
        model_names.append(model_name)
        row = []

        for sample_id in gs_samples:
            metrics = load_sample_metrics(model, sample_id, 'direct')
            if metrics:
                target_found = metrics.get('target_found', False)
                row.append(1 if target_found else 0)
            else:
                row.append(-1)  # Missing data

        matrix.append(row)

    # Create DataFrame
    df = pd.DataFrame(matrix, index=model_names, columns=[s.replace('sn_gs_', 'GS-') for s in gs_samples])

    # Plot heatmap
    cmap = sns.color_palette(["#e74c3c", "#95a5a6", "#2ecc71"], as_cmap=True)
    sns.heatmap(df, annot=True, fmt='d', cmap=cmap, center=0,
               cbar_kws={'label': 'Target Found', 'ticks': [-1, 0, 1]},
               linewidths=0.5, linecolor='white', ax=ax,
               vmin=-1, vmax=1)

    ax.set_title('Per-Sample Detection on Gold Standard Samples\n(1=Found, 0=Missed, -1=No Data)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Gold Standard Sample', fontsize=12)
    ax.set_ylabel('Model', fontsize=12)

    # Customize colorbar
    cbar = ax.collections[0].colorbar
    cbar.set_ticks([-1, 0, 1])
    cbar.set_ticklabels(['No Data', 'Missed', 'Found'])

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '03_per_sample_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 03_per_sample_heatmap.png")

def plot_gs_difficulty_analysis(gs_samples):
    """Analyze performance by vulnerability type on GS samples."""
    # Collect vulnerability types
    vuln_data = {}

    for sample_id in gs_samples:
        gt = load_ground_truth(sample_id)
        if gt:
            vuln_type = gt['ground_truth'].get('vulnerability_type', 'unknown')

            if vuln_type not in vuln_data:
                vuln_data[vuln_type] = {model: {'found': 0, 'total': 0} for model in MODELS}

            for model in MODELS:
                metrics = load_sample_metrics(model, sample_id, 'direct')
                if metrics:
                    vuln_data[vuln_type][model]['total'] += 1
                    if metrics.get('target_found', False):
                        vuln_data[vuln_type][model]['found'] += 1

    # Create plot
    fig, ax = plt.subplots(figsize=(14, 8))

    vuln_types = sorted(vuln_data.keys())
    x = np.arange(len(vuln_types))
    width = 0.12

    colors = sns.color_palette("husl", len(MODELS))

    for i, model in enumerate(MODELS):
        model_name = get_model_display_name(model)
        rates = []

        for vuln_type in vuln_types:
            stats = vuln_data[vuln_type][model]
            rate = (stats['found'] / stats['total'] * 100) if stats['total'] > 0 else 0
            rates.append(rate)

        ax.bar(x + i * width - (len(MODELS) * width / 2) + width/2,
               rates, width, label=model_name, color=colors[i], alpha=0.85)

    ax.set_ylabel('Detection Rate (%)', fontsize=12)
    ax.set_xlabel('Vulnerability Type', fontsize=12)
    ax.set_title('Gold Standard Performance by Vulnerability Type',
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xticks(x)
    ax.set_xticklabels(vuln_types, rotation=45, ha='right')
    ax.legend(fontsize=9, ncol=2)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '04_gs_by_vulnerability_type.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 04_gs_by_vulnerability_type.png")

def generate_summary_report(gs_df, gs_samples, overall_metrics):
    """Generate markdown summary report."""
    report = []
    report.append("# Gold Standard Performance Analysis\n")
    report.append(f"**Analysis Date:** {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    report.append("---\n")

    report.append("## Overview\n")
    report.append("Gold Standard (gs) samples are manually curated, high-quality benchmark samples ")
    report.append("representing real-world vulnerabilities with expert-validated ground truth.\n\n")
    report.append(f"**Total Gold Standard Samples:** {len(gs_samples)}\n\n")

    # List samples
    report.append("**Samples:**\n")
    for sample in gs_samples:
        gt = load_ground_truth(sample)
        if gt:
            vuln_type = gt['ground_truth'].get('vulnerability_type', 'unknown')
            severity = gt['ground_truth'].get('severity', 'unknown')
            report.append(f"- `{sample}`: {vuln_type} ({severity})\n")
    report.append("\n---\n\n")

    report.append("## Key Findings\n\n")

    # Best detection on GS
    best = gs_df.nlargest(1, 'Detection Rate').iloc[0]
    report.append(f"### 1. Best Detection Rate on Gold Standard\n")
    report.append(f"**{best['Model']}** with {best['Detection Rate']:.1f}% ")
    report.append(f"({int(best['Targets Found'])}/{int(best['Total Samples'])} samples).\n\n")

    # Best quality on GS
    quality_df = gs_df[gs_df['Quality Score'] > 0].nlargest(1, 'Quality Score')
    if len(quality_df) > 0:
        best_quality = quality_df.iloc[0]
        report.append(f"### 2. Best Quality on Gold Standard\n")
        report.append(f"**{best_quality['Model']}** with {best_quality['Quality Score']:.1f}% ")
        report.append(f"average quality score.\n\n")

    # Compare GS vs overall
    report.append(f"### 3. Performance Comparison: GS vs Overall (Direct Prompts Only)\n\n")
    report.append("**Note:** Both comparisons use direct prompts only for fair evaluation.\n\n")
    report.append("| Model | GS Detection | Overall Detection (Direct) | Difference |\n")
    report.append("|-------|--------------|----------------------------|------------|\n")

    for _, row in gs_df.iterrows():
        model = row['Model']
        gs_rate = row['Detection Rate']

        # Get overall rate (direct prompts only for fair comparison)
        model_key = [k for k, v in {
            'claude_opus_4.5': 'Claude Opus 4.5',
            'deepseek_v3.2': 'DeepSeek v3.2',
            'gemini_3_pro_preview': 'Gemini 3 Pro',
            'gpt-5.2': 'GPT-5.2',
            'grok_4': 'Grok 4',
            'llama_3.1_405b': 'Llama 3.1 405B'
        }.items() if v == model][0]

        # Use direct prompts only for fair comparison
        overall_direct = overall_metrics['by_model'][model_key]['by_prompt_type']['direct']
        overall_rate = overall_direct['target']['target_detection_rate'] * 100
        diff = gs_rate - overall_rate

        report.append(f"| {model} | {gs_rate:.1f}% | {overall_rate:.1f}% | ")
        report.append(f"{diff:+.1f}pp |\n")

    report.append("\n---\n\n")

    # Detailed table
    report.append("## Detailed Gold Standard Performance\n\n")
    report.append("| Rank | Model | Detection Rate | Quality Score | Finding Precision | Targets Found |\n")
    report.append("|------|-------|----------------|---------------|-------------------|---------------|\n")

    sorted_df = gs_df.sort_values('Detection Rate', ascending=False)
    for rank, (_, row) in enumerate(sorted_df.iterrows(), 1):
        quality_str = f"{row['Quality Score']:.1f}%" if row['Quality Score'] > 0 else "N/A"
        report.append(f"| {rank} | {row['Model']} | {row['Detection Rate']:.1f}% | ")
        report.append(f"{quality_str} | {row['Finding Precision']:.1f}% | ")
        report.append(f"{int(row['Targets Found'])}/{int(row['Total Samples'])} |\n")

    report.append("\n---\n\n")
    report.append("## Visualizations\n\n")
    report.append("- `01_gs_vs_overall_detection.png`: Gold Standard vs Overall comparison\n")
    report.append("- `02_gs_performance_breakdown.png`: Detailed metrics breakdown\n")
    report.append("- `03_per_sample_heatmap.png`: Per-sample detection matrix\n")
    report.append("- `04_gs_by_vulnerability_type.png`: Performance by vulnerability type\n")

    # Save report
    with open(OUTPUT_DIR / 'GOLD_STANDARD_ANALYSIS.md', 'w') as f:
        f.write(''.join(report))

    print("✓ Generated: GOLD_STANDARD_ANALYSIS.md")

def main():
    print("=" * 70)
    print("GOLD STANDARD PERFORMANCE ANALYSIS")
    print("=" * 70)
    print()

    print("Extracting gold standard data...")
    gs_df, gs_samples = extract_gold_standard_data()

    if gs_df.empty:
        print("❌ No gold standard data found!")
        return

    print(f"Found data for {len(gs_df)} models on {len(gs_samples)} gold standard samples")
    print()

    print("Loading overall metrics for comparison...")
    overall_metrics = load_overall_metrics()

    print()
    print("Generating visualizations...")
    plot_gs_vs_overall_detection(gs_df, overall_metrics)
    plot_gs_performance_breakdown(gs_df)
    plot_per_sample_heatmap(gs_samples)
    plot_gs_difficulty_analysis(gs_samples)

    print()
    print("Generating summary report...")
    generate_summary_report(gs_df, gs_samples, overall_metrics)

    print()
    print("=" * 70)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 70)
    print(f"\nOutput directory: {OUTPUT_DIR}")
    print(f"  - 4 visualization files (.png)")
    print(f"  - 1 summary report (GOLD_STANDARD_ANALYSIS.md)")

if __name__ == '__main__':
    main()
