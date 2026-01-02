#!/usr/bin/env python3
"""
Analyze and visualize model performance across different prompt types.

This script examines how models perform on:
- Direct prompts (explicit vulnerability analysis)
- Adversarial prompts ("already audited" framing)
- Naturalistic prompts (colleague-style review)
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
METRICS_FILE = BASE_DIR / 'analysis_results' / 'aggregated_metrics.json'
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'prompt_type_analysis'

# Create output directory
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def load_metrics():
    """Load aggregated metrics."""
    with open(METRICS_FILE, 'r') as f:
        return json.load(f)

def get_model_display_name(model: str) -> str:
    """Convert model name to display-friendly format."""
    name_map = {
        'claude_opus_4.5': 'Claude Opus 4.5',
        'deepseek_v3.2': 'DeepSeek v3.2',
        'gemini_3_pro_preview': 'Gemini 3 Pro',
        'gpt-5.2': 'GPT-5.2',
        'grok_4': 'Grok 4',
        'grok_4_fast': 'Grok 4 Fast',
        'llama_3.1_405b': 'Llama 3.1 405B'
    }
    return name_map.get(model, model)

def extract_prompt_type_data(metrics):
    """Extract prompt type performance data for all models."""
    data = []

    for model, model_data in metrics['by_model'].items():
        # Exclude Grok 4 Fast per user request
        if model == 'grok_4_fast':
            continue

        by_prompt = model_data.get('by_prompt_type', {})
        model_name = get_model_display_name(model)

        for prompt_type, prompt_data in by_prompt.items():
            detection = prompt_data.get('detection', {})
            target = prompt_data.get('target', {})
            quality = prompt_data.get('quality', {})
            findings = prompt_data.get('findings', {})

            data.append({
                'Model': model_name,
                'Prompt Type': prompt_type.capitalize(),
                'Sample Count': detection.get('total_samples', 0),
                'Detection Rate': (target.get('target_detection_rate') or 0) * 100,
                'Quality Score': (quality.get('avg_overall_quality_score') or 0) * 100,
                'Finding Precision': (findings.get('avg_finding_precision') or 0) * 100,
                'Hallucination Rate': (findings.get('hallucination_rate') or 0) * 100,
                'Accuracy': (detection.get('accuracy') or 0) * 100,
                'F1 Score': (detection.get('f1_score') or 0) * 100,
                'Avg Findings': findings.get('avg_findings_per_sample', 0)
            })

    return pd.DataFrame(data)

def plot_detection_by_prompt_type(df):
    """Plot detection rate by prompt type for each model."""
    fig, ax = plt.subplots(figsize=(14, 8))

    # Pivot for grouped bar chart
    pivot = df.pivot(index='Model', columns='Prompt Type', values='Detection Rate')

    # Plot grouped bars
    pivot.plot(kind='bar', ax=ax, width=0.8,
               color=['#2ecc71', '#e74c3c', '#3498db'])

    ax.set_ylabel('Detection Rate (%)', fontsize=12)
    ax.set_xlabel('Model', fontsize=12)
    ax.set_title('Target Detection Rate by Prompt Type', fontsize=14, fontweight='bold', pad=20)
    ax.legend(title='Prompt Type', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '01_detection_by_prompt_type.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 01_detection_by_prompt_type.png")

def plot_quality_by_prompt_type(df):
    """Plot quality score by prompt type for each model."""
    fig, ax = plt.subplots(figsize=(14, 8))

    # Filter out zero quality scores (no targets found)
    df_quality = df[df['Quality Score'] > 0].copy()

    # Pivot for grouped bar chart
    pivot = df_quality.pivot(index='Model', columns='Prompt Type', values='Quality Score')

    # Plot grouped bars
    pivot.plot(kind='bar', ax=ax, width=0.8,
               color=['#2ecc71', '#e74c3c', '#3498db'])

    ax.set_ylabel('Quality Score (%)', fontsize=12)
    ax.set_xlabel('Model', fontsize=12)
    ax.set_title('Response Quality Score by Prompt Type (when target found)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(title='Prompt Type', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '02_quality_by_prompt_type.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 02_quality_by_prompt_type.png")

def plot_precision_by_prompt_type(df):
    """Plot finding precision by prompt type for each model."""
    fig, ax = plt.subplots(figsize=(14, 8))

    # Pivot for grouped bar chart
    pivot = df.pivot(index='Model', columns='Prompt Type', values='Finding Precision')

    # Plot grouped bars
    pivot.plot(kind='bar', ax=ax, width=0.8,
               color=['#2ecc71', '#e74c3c', '#3498db'])

    ax.set_ylabel('Finding Precision (%)', fontsize=12)
    ax.set_xlabel('Model', fontsize=12)
    ax.set_title('Finding Precision by Prompt Type (avoiding false positives)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(title='Prompt Type', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '03_precision_by_prompt_type.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 03_precision_by_prompt_type.png")

def plot_prompt_type_heatmap(df):
    """Create heatmap showing all metrics across prompt types."""
    # Create separate heatmaps for each prompt type
    prompt_types = df['Prompt Type'].unique()

    fig, axes = plt.subplots(1, 3, figsize=(18, 8))

    for idx, prompt_type in enumerate(sorted(prompt_types)):
        df_prompt = df[df['Prompt Type'] == prompt_type].copy()

        # Create matrix
        metrics_to_show = ['Detection Rate', 'Quality Score', 'Finding Precision', 'Accuracy']
        matrix = df_prompt[['Model'] + metrics_to_show].set_index('Model')[metrics_to_show]

        # Plot heatmap
        sns.heatmap(matrix, annot=True, fmt='.1f', cmap='RdYlGn',
                   center=50, vmin=0, vmax=100, ax=axes[idx],
                   cbar_kws={'label': 'Score (%)'})

        axes[idx].set_title(f'{prompt_type} Prompts', fontsize=12, fontweight='bold')
        axes[idx].set_xlabel('')
        axes[idx].set_ylabel('')

    plt.suptitle('Performance Heatmap by Prompt Type', fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '04_prompt_type_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 04_prompt_type_heatmap.png")

def plot_prompt_robustness(df):
    """Plot how robust each model is across different prompt types."""
    fig, ax = plt.subplots(figsize=(12, 8))

    # Calculate variance/std for each model across prompt types
    robustness_data = []

    for model in df['Model'].unique():
        model_data = df[df['Model'] == model]

        # Calculate coefficient of variation (lower = more robust)
        detection_rates = model_data['Detection Rate'].values
        mean_detection = detection_rates.mean()
        std_detection = detection_rates.std()
        cv = (std_detection / mean_detection * 100) if mean_detection > 0 else 0

        robustness_data.append({
            'Model': model,
            'Mean Detection': mean_detection,
            'Std Detection': std_detection,
            'Coefficient of Variation': cv,
            'Min Detection': detection_rates.min(),
            'Max Detection': detection_rates.max()
        })

    rob_df = pd.DataFrame(robustness_data).sort_values('Coefficient of Variation')

    # Plot
    colors = sns.color_palette("RdYlGn_r", len(rob_df))
    bars = ax.barh(rob_df['Model'], rob_df['Coefficient of Variation'], color=colors)

    ax.set_xlabel('Coefficient of Variation (%)\n(Lower = More Robust Across Prompt Types)', fontsize=12)
    ax.set_ylabel('Model', fontsize=12)
    ax.set_title('Prompt Type Robustness (Detection Rate Stability)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.grid(axis='x', alpha=0.3)

    # Add mean detection rate as text
    for i, (idx, row) in enumerate(rob_df.iterrows()):
        ax.text(row['Coefficient of Variation'] + 2, i,
               f"μ={row['Mean Detection']:.1f}%",
               va='center', fontsize=9)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '05_prompt_robustness.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 05_prompt_robustness.png")

def generate_summary_report(df, metrics):
    """Generate markdown summary report."""
    report = []
    report.append("# Performance Across Prompt Types\n")
    report.append(f"**Analysis Date:** {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    report.append("---\n")

    report.append("## Overview\n")
    report.append("This analysis examines how models perform across three prompt types:\n")
    report.append("- **Direct**: Explicit vulnerability analysis request (structured JSON output)\n")
    report.append("- **Adversarial**: \"Already audited\" framing to test sycophancy resistance\n")
    report.append("- **Naturalistic**: Colleague-style code review request\n")
    report.append("\n---\n")

    report.append("## Key Findings\n\n")

    # Finding 1: Best overall across prompt types
    avg_by_model = df.groupby('Model')['Detection Rate'].mean().sort_values(ascending=False)
    report.append(f"### 1. Best Average Detection Rate\n")
    report.append(f"**{avg_by_model.index[0]}** with {avg_by_model.iloc[0]:.1f}% average detection across all prompt types.\n\n")

    # Finding 2: Most robust (lowest variance)
    variance_by_model = df.groupby('Model')['Detection Rate'].std().sort_values()
    report.append(f"### 2. Most Robust (Consistent Across Prompts)\n")
    report.append(f"**{variance_by_model.index[0]}** with only {variance_by_model.iloc[0]:.1f}% standard deviation.\n\n")

    # Finding 3: Best on each prompt type
    report.append(f"### 3. Best Performance by Prompt Type\n")
    for prompt_type in sorted(df['Prompt Type'].unique()):
        best = df[df['Prompt Type'] == prompt_type].nlargest(1, 'Detection Rate').iloc[0]
        report.append(f"- **{prompt_type}**: {best['Model']} ({best['Detection Rate']:.1f}%)\n")
    report.append("\n")

    # Finding 4: Biggest drop from direct to adversarial
    direct_data = df[df['Prompt Type'] == 'Direct'].set_index('Model')['Detection Rate']
    adv_data = df[df['Prompt Type'] == 'Adversarial'].set_index('Model')['Detection Rate']
    drops = (direct_data - adv_data).sort_values(ascending=False)

    report.append(f"### 4. Susceptibility to Adversarial Prompts\n")
    report.append(f"Largest drop from Direct → Adversarial:\n")
    for model, drop in drops.head(3).items():
        report.append(f"- **{model}**: -{drop:.1f}% (from {direct_data[model]:.1f}% to {adv_data[model]:.1f}%)\n")
    report.append("\n")

    report.append("---\n\n")

    # Detailed table
    report.append("## Detailed Performance Table\n\n")

    for model in sorted(df['Model'].unique()):
        report.append(f"### {model}\n\n")
        model_data = df[df['Model'] == model].sort_values('Prompt Type')

        report.append("| Metric | Direct | Adversarial | Naturalistic |\n")
        report.append("|--------|--------|-------------|-------------|\n")

        metrics_map = {
            'Detection Rate': 'Detection Rate',
            'Quality Score': 'Quality Score',
            'Finding Precision': 'Finding Precision',
            'Accuracy': 'Accuracy',
            'Sample Count': 'Sample Count'
        }

        for metric_name, metric_col in metrics_map.items():
            row = [metric_name]
            for prompt in ['Direct', 'Adversarial', 'Naturalistic']:
                val = model_data[model_data['Prompt Type'] == prompt][metric_col]
                if len(val) > 0:
                    val = val.iloc[0]
                    if metric_name == 'Sample Count':
                        row.append(f"{int(val)}")
                    else:
                        row.append(f"{val:.1f}%")
                else:
                    row.append("N/A")
            report.append("| " + " | ".join(row) + " |\n")

        report.append("\n")

    report.append("---\n\n")
    report.append("## Visualizations\n\n")
    report.append("- `01_detection_by_prompt_type.png`: Detection rate comparison\n")
    report.append("- `02_quality_by_prompt_type.png`: Quality score comparison\n")
    report.append("- `03_precision_by_prompt_type.png`: Finding precision comparison\n")
    report.append("- `04_prompt_type_heatmap.png`: Multi-metric heatmaps\n")
    report.append("- `05_prompt_robustness.png`: Robustness analysis\n")

    # Save report
    with open(OUTPUT_DIR / 'PROMPT_TYPE_ANALYSIS.md', 'w') as f:
        f.write(''.join(report))

    print("✓ Generated: PROMPT_TYPE_ANALYSIS.md")

def main():
    print("=" * 70)
    print("PROMPT TYPE PERFORMANCE ANALYSIS")
    print("=" * 70)
    print()

    print(f"Loading metrics from: {METRICS_FILE}")
    metrics = load_metrics()

    print(f"Extracting prompt type data...")
    df = extract_prompt_type_data(metrics)

    print(f"Found data for {len(df['Model'].unique())} models across {len(df['Prompt Type'].unique())} prompt types")
    print()

    print("Generating visualizations...")
    plot_detection_by_prompt_type(df)
    plot_quality_by_prompt_type(df)
    plot_precision_by_prompt_type(df)
    plot_prompt_type_heatmap(df)
    plot_prompt_robustness(df)

    print()
    print("Generating summary report...")
    generate_summary_report(df, metrics)

    print()
    print("=" * 70)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 70)
    print(f"\nOutput directory: {OUTPUT_DIR}")
    print(f"  - 5 visualization files (.png)")
    print(f"  - 1 summary report (PROMPT_TYPE_ANALYSIS.md)")

if __name__ == '__main__':
    main()
