#!/usr/bin/env python3
"""
Analyze model performance across transformation trajectory for TC samples.

Traces how models perform as TC samples (tc_001 to tc_005) are progressively
transformed through: nc_o → sn → ch_medical_nc → ss_l3_medium_nc
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
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'transformation_analysis'

# Create output directory
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Transformation progression for TC samples
TC_SAMPLES = ['tc_001', 'tc_002', 'tc_003', 'tc_004', 'tc_005']
TRANSFORMATION_STAGES = {
    'Baseline (nc_o)': 'nc_o',
    'Sanitized (sn)': 'sn',
    'Chameleon (ch_medical_nc)': 'ch_medical_nc',
    'Shapeshifter (ss_l3_medium_nc)': 'ss_l3_medium_nc'
}

MODELS = [
    'claude_opus_4.5',
    'deepseek_v3.2',
    'gemini_3_pro_preview',
    'gpt-5.2',
    'grok_4',
    # 'grok_4_fast',  # Excluded per user request
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
        'grok_4_fast': 'Grok 4 Fast',
        'llama_3.1_405b': 'Llama 3.1 405B'
    }
    return name_map.get(model, model)

def load_sample_metrics(model: str, sample_id: str, prompt_type: str = 'direct') -> dict:
    """Load metrics for a specific sample."""
    metrics_file = JUDGE_OUTPUT_DIR / model / 'sample_metrics' / f'm_{sample_id}_{prompt_type}.json'

    if not metrics_file.exists():
        return None

    with open(metrics_file, 'r') as f:
        return json.load(f)

def extract_trajectory_data():
    """Extract performance data across transformation trajectory."""
    data = []

    for model in MODELS:
        model_name = get_model_display_name(model)

        for stage_name, stage_prefix in TRANSFORMATION_STAGES.items():
            stage_metrics = []

            # Collect metrics for all 5 TC samples at this stage
            for tc_sample in TC_SAMPLES:
                sample_id = f"{stage_prefix}_{tc_sample}"
                metrics = load_sample_metrics(model, sample_id, 'direct')

                if metrics:
                    stage_metrics.append(metrics)

            # Calculate aggregate metrics for this stage
            if stage_metrics:
                # Detection metrics
                detection_correct = sum(1 for m in stage_metrics if m.get('detection_correct', False))
                target_found = sum(1 for m in stage_metrics if m.get('target_found', False))
                total = len(stage_metrics)

                # Quality scores (only from samples where target was found)
                quality_scores = [m.get('rcir_score') for m in stage_metrics
                                if m.get('target_found') and m.get('rcir_score') is not None]
                avg_quality = np.mean(quality_scores) if quality_scores else 0

                # Finding precision
                precisions = [m.get('finding_precision', 0) for m in stage_metrics]
                avg_precision = np.mean(precisions) if precisions else 0

                data.append({
                    'Model': model_name,
                    'Stage': stage_name,
                    'Stage Order': list(TRANSFORMATION_STAGES.keys()).index(stage_name),
                    'Detection Rate': (target_found / total * 100) if total > 0 else 0,
                    'Accuracy': (detection_correct / total * 100) if total > 0 else 0,
                    'Quality Score': avg_quality * 100 if avg_quality > 0 else 0,
                    'Finding Precision': avg_precision * 100,
                    'Samples': total,
                    'Targets Found': target_found
                })

    return pd.DataFrame(data)

def plot_detection_trajectory(df):
    """Plot detection rate trajectory across transformations."""
    fig, ax = plt.subplots(figsize=(14, 8))

    models = sorted(df['Model'].unique())
    colors = sns.color_palette("husl", len(models))

    for idx, model in enumerate(models):
        model_data = df[df['Model'] == model].sort_values('Stage Order')
        ax.plot(model_data['Stage'], model_data['Detection Rate'],
               marker='o', linewidth=2.5, markersize=8,
               color=colors[idx], label=model, alpha=0.85)

    ax.set_ylabel('Detection Rate (%)', fontsize=12)
    ax.set_xlabel('Transformation Stage', fontsize=12)
    ax.set_title('Target Detection Rate Across TC Sample Transformations',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=25, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '01_detection_trajectory.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 01_detection_trajectory.png")

def plot_quality_trajectory(df):
    """Plot quality score trajectory across transformations."""
    fig, ax = plt.subplots(figsize=(14, 8))

    # Filter out zero quality scores
    df_quality = df[df['Quality Score'] > 0].copy()

    models = sorted(df_quality['Model'].unique())
    colors = sns.color_palette("coolwarm", len(models))

    for idx, model in enumerate(models):
        model_data = df_quality[df_quality['Model'] == model].sort_values('Stage Order')
        if len(model_data) > 0:
            ax.plot(model_data['Stage'], model_data['Quality Score'],
                   marker='s', linewidth=2.5, markersize=8,
                   color=colors[idx], label=model, alpha=0.85)

    ax.set_ylabel('Quality Score (RCIR) %', fontsize=12)
    ax.set_xlabel('Transformation Stage', fontsize=12)
    ax.set_title('Response Quality Across TC Sample Transformations (when target found)',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=25, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '02_quality_trajectory.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 02_quality_trajectory.png")

def plot_precision_trajectory(df):
    """Plot finding precision trajectory across transformations."""
    fig, ax = plt.subplots(figsize=(14, 8))

    models = sorted(df['Model'].unique())
    colors = sns.color_palette("viridis", len(models))

    for idx, model in enumerate(models):
        model_data = df[df['Model'] == model].sort_values('Stage Order')
        ax.plot(model_data['Stage'], model_data['Finding Precision'],
               marker='^', linewidth=2.5, markersize=8,
               color=colors[idx], label=model, alpha=0.85)

    ax.set_ylabel('Finding Precision (%)', fontsize=12)
    ax.set_xlabel('Transformation Stage', fontsize=12)
    ax.set_title('Finding Precision Across TC Sample Transformations',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=25, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '03_precision_trajectory.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 03_precision_trajectory.png")

def plot_stage_comparison(df):
    """Plot model comparison at each transformation stage."""
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    axes = axes.flatten()

    stages = sorted(df['Stage'].unique(), key=lambda x: df[df['Stage']==x]['Stage Order'].iloc[0])
    colors = sns.color_palette("Spectral", len(df['Model'].unique()))

    for idx, stage in enumerate(stages):
        ax = axes[idx]
        stage_data = df[df['Stage'] == stage].sort_values('Detection Rate', ascending=True)

        bars = ax.barh(stage_data['Model'], stage_data['Detection Rate'], color=colors)

        ax.set_xlabel('Detection Rate (%)', fontsize=11)
        ax.set_title(stage, fontsize=12, fontweight='bold')
        ax.set_xlim(0, 100)
        ax.grid(axis='x', alpha=0.3)

        # Add value labels
        for bar in bars:
            width = bar.get_width()
            if width > 0:
                ax.text(width + 2, bar.get_y() + bar.get_height()/2,
                       f'{width:.1f}%', va='center', fontsize=9)

    plt.suptitle('Model Performance at Each Transformation Stage',
                 fontsize=14, fontweight='bold', y=0.995)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '04_stage_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 04_stage_comparison.png")

def plot_degradation_analysis(df):
    """Analyze performance degradation from baseline to final stage."""
    fig, ax = plt.subplots(figsize=(12, 8))

    # Calculate degradation (baseline - final stage)
    degradation_data = []

    for model in df['Model'].unique():
        model_data = df[df['Model'] == model].sort_values('Stage Order')

        if len(model_data) >= 2:
            baseline = model_data[model_data['Stage Order'] == 0]['Detection Rate'].iloc[0]
            final = model_data[model_data['Stage Order'] == model_data['Stage Order'].max()]['Detection Rate'].iloc[0]

            degradation_data.append({
                'Model': model,
                'Baseline': baseline,
                'Final': final,
                'Degradation': baseline - final,
                'Degradation %': ((baseline - final) / baseline * 100) if baseline > 0 else 0
            })

    deg_df = pd.DataFrame(degradation_data).sort_values('Degradation', ascending=True)

    # Color: green if improved (negative degradation), red if degraded (positive)
    colors = ['#2ecc71' if x < 0 else '#e74c3c' for x in deg_df['Degradation']]

    bars = ax.barh(deg_df['Model'], deg_df['Degradation'], color=colors, alpha=0.7)

    ax.axvline(x=0, color='black', linestyle='-', linewidth=1)
    ax.set_xlabel('Detection Rate Change (Baseline - Final Stage) in percentage points',
                  fontsize=12)
    ax.set_ylabel('Model', fontsize=12)
    ax.set_title('Performance Degradation from Baseline to Final Transformation',
                 fontsize=14, fontweight='bold', pad=20)
    ax.grid(axis='x', alpha=0.3)

    # Add value labels
    for bar in bars:
        width = bar.get_width()
        label_x = width + (2 if width > 0 else -2)
        ha = 'left' if width > 0 else 'right'
        ax.text(label_x, bar.get_y() + bar.get_height()/2,
               f'{width:+.1f}pp', va='center', ha=ha, fontsize=9)

    # Add legend
    from matplotlib.patches import Patch
    legend_elements = [
        Patch(facecolor='#e74c3c', alpha=0.7, label='Performance Degraded'),
        Patch(facecolor='#2ecc71', alpha=0.7, label='Performance Improved')
    ]
    ax.legend(handles=legend_elements, loc='best')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '05_degradation_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 05_degradation_analysis.png")

def plot_multi_metric_trajectories(df):
    """Plot all metrics in one chart per model."""
    models = sorted(df['Model'].unique())

    fig, axes = plt.subplots(4, 2, figsize=(16, 16))
    axes = axes.flatten()

    for idx, model in enumerate(models):
        ax = axes[idx]
        model_data = df[df['Model'] == model].sort_values('Stage Order')

        # Plot multiple metrics
        ax.plot(model_data['Stage'], model_data['Detection Rate'],
               marker='o', linewidth=2, label='Detection Rate', color='#3498db')
        ax.plot(model_data['Stage'], model_data['Finding Precision'],
               marker='^', linewidth=2, label='Finding Precision', color='#e74c3c')

        # Only plot quality if there are non-zero values
        if model_data['Quality Score'].max() > 0:
            ax.plot(model_data['Stage'], model_data['Quality Score'],
                   marker='s', linewidth=2, label='Quality Score', color='#2ecc71')

        ax.set_ylabel('Score (%)', fontsize=10)
        ax.set_title(model, fontsize=12, fontweight='bold')
        ax.set_ylim(0, 100)
        ax.legend(loc='best', fontsize=8)
        ax.grid(axis='y', alpha=0.3)

        plt.setp(ax.xaxis.get_majorticklabels(), rotation=25, ha='right', fontsize=8)

    # Hide extra subplot if odd number of models
    if len(models) < len(axes):
        axes[-1].axis('off')

    plt.suptitle('Multi-Metric Trajectories Across TC Transformations',
                 fontsize=14, fontweight='bold', y=0.995)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '06_multi_metric_trajectories.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 06_multi_metric_trajectories.png")

def generate_summary_report(df):
    """Generate markdown summary report."""
    report = []
    report.append("# TC Sample Transformation Trajectory Analysis\n")
    report.append(f"**Analysis Date:** {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    report.append("---\n")

    report.append("## Overview\n")
    report.append("This analysis traces how model performance changes as **TC samples** ")
    report.append("(tc_001 to tc_005) undergo progressive transformations:\n\n")

    for idx, (stage_name, stage_prefix) in enumerate(TRANSFORMATION_STAGES.items(), 1):
        report.append(f"{idx}. **{stage_name}** (`{stage_prefix}_tc_00X`)\n")
    report.append("\n")
    report.append(f"**Total TC Samples Tracked:** {len(TC_SAMPLES)}\n")
    report.append("---\n\n")

    report.append("## Key Findings\n\n")

    # Finding 1: Most robust (least degradation)
    degradation_data = []
    for model in df['Model'].unique():
        model_data = df[df['Model'] == model].sort_values('Stage Order')
        if len(model_data) >= 2:
            baseline = model_data.iloc[0]['Detection Rate']
            final = model_data.iloc[-1]['Detection Rate']
            degradation_data.append({
                'Model': model,
                'Degradation': baseline - final
            })

    deg_df = pd.DataFrame(degradation_data).sort_values('Degradation')

    report.append("### 1. Most Robust Model (Least Performance Drop)\n")
    if len(deg_df) > 0:
        best_model = deg_df.iloc[0]
        if best_model['Degradation'] < 0:
            report.append(f"**{best_model['Model']}** actually **improved** by ")
            report.append(f"{abs(best_model['Degradation']):.1f} percentage points!\n\n")
        else:
            report.append(f"**{best_model['Model']}** with only ")
            report.append(f"{best_model['Degradation']:.1f} percentage point drop.\n\n")

    # Finding 2: Highest baseline performance
    baseline_data = df[df['Stage Order'] == 0].sort_values('Detection Rate', ascending=False)
    if len(baseline_data) > 0:
        report.append("### 2. Best Baseline Performance (nc_o)\n")
        top = baseline_data.iloc[0]
        report.append(f"**{top['Model']}** with {top['Detection Rate']:.1f}% detection.\n\n")

    # Finding 3: Best at final stage
    final_order = df['Stage Order'].max()
    final_data = df[df['Stage Order'] == final_order].sort_values('Detection Rate', ascending=False)
    if len(final_data) > 0:
        report.append("### 3. Best Final Stage Performance (Shapeshifter)\n")
        top = final_data.iloc[0]
        report.append(f"**{top['Model']}** with {top['Detection Rate']:.1f}% detection.\n\n")

    # Finding 4: Most degraded
    if len(deg_df) > 0:
        worst = deg_df.iloc[-1]
        report.append("### 4. Most Affected by Transformations\n")
        report.append(f"**{worst['Model']}** dropped {worst['Degradation']:.1f} percentage points ")
        report.append(f"from baseline to final stage.\n\n")

    report.append("---\n\n")

    # Detailed tables
    report.append("## Performance by Transformation Stage\n\n")

    stages = sorted(df['Stage'].unique(), key=lambda x: df[df['Stage']==x]['Stage Order'].iloc[0])

    for stage in stages:
        report.append(f"### {stage}\n\n")
        stage_data = df[df['Stage'] == stage].sort_values('Detection Rate', ascending=False)

        report.append("| Rank | Model | Detection Rate | Finding Precision | Quality Score | Targets Found |\n")
        report.append("|------|-------|----------------|-------------------|---------------|---------------|\n")

        for rank, (_, row) in enumerate(stage_data.iterrows(), 1):
            quality_str = f"{row['Quality Score']:.1f}%" if row['Quality Score'] > 0 else "N/A"
            report.append(f"| {rank} | {row['Model']} | {row['Detection Rate']:.1f}% | ")
            report.append(f"{row['Finding Precision']:.1f}% | {quality_str} | ")
            report.append(f"{int(row['Targets Found'])}/{int(row['Samples'])} |\n")

        report.append("\n")

    report.append("---\n\n")

    # Model-by-model trajectory
    report.append("## Model-by-Model Trajectory\n\n")

    for model in sorted(df['Model'].unique()):
        report.append(f"### {model}\n\n")
        model_data = df[df['Model'] == model].sort_values('Stage Order')

        report.append("| Stage | Detection Rate | Finding Precision | Quality Score |\n")
        report.append("|-------|----------------|-------------------|---------------|\n")

        for _, row in model_data.iterrows():
            quality_str = f"{row['Quality Score']:.1f}%" if row['Quality Score'] > 0 else "N/A"
            report.append(f"| {row['Stage']} | {row['Detection Rate']:.1f}% | ")
            report.append(f"{row['Finding Precision']:.1f}% | {quality_str} |\n")

        # Calculate degradation
        if len(model_data) >= 2:
            baseline = model_data.iloc[0]['Detection Rate']
            final = model_data.iloc[-1]['Detection Rate']
            change = final - baseline

            report.append(f"\n**Performance Change:** ")
            if change > 0:
                report.append(f"+{change:.1f} percentage points (improved)\n\n")
            elif change < 0:
                report.append(f"{change:.1f} percentage points (degraded)\n\n")
            else:
                report.append(f"No change\n\n")
        else:
            report.append("\n")

    report.append("---\n\n")
    report.append("## Visualizations\n\n")
    report.append("- `01_detection_trajectory.png`: Detection rate across all stages\n")
    report.append("- `02_quality_trajectory.png`: Quality scores across stages\n")
    report.append("- `03_precision_trajectory.png`: Finding precision across stages\n")
    report.append("- `04_stage_comparison.png`: Model rankings at each stage\n")
    report.append("- `05_degradation_analysis.png`: Baseline vs final performance\n")
    report.append("- `06_multi_metric_trajectories.png`: Combined metrics per model\n")

    # Save report
    with open(OUTPUT_DIR / 'TRANSFORMATION_ANALYSIS.md', 'w') as f:
        f.write(''.join(report))

    print("✓ Generated: TRANSFORMATION_ANALYSIS.md")

def main():
    print("=" * 70)
    print("TC SAMPLE TRANSFORMATION TRAJECTORY ANALYSIS")
    print("=" * 70)
    print()

    print(f"Tracking {len(TC_SAMPLES)} TC samples through {len(TRANSFORMATION_STAGES)} transformation stages:")
    for stage_name, prefix in TRANSFORMATION_STAGES.items():
        print(f"  - {stage_name}: {prefix}_tc_001 to {prefix}_tc_005")
    print()

    print("Extracting trajectory data...")
    df = extract_trajectory_data()

    if df.empty:
        print("❌ No data found!")
        return

    print(f"Found data for {len(df['Model'].unique())} models")
    print()

    print("Generating visualizations...")
    plot_detection_trajectory(df)
    plot_quality_trajectory(df)
    plot_precision_trajectory(df)
    plot_stage_comparison(df)
    plot_degradation_analysis(df)
    plot_multi_metric_trajectories(df)

    print()
    print("Generating summary report...")
    generate_summary_report(df)

    print()
    print("=" * 70)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 70)
    print(f"\nOutput directory: {OUTPUT_DIR}")
    print(f"  - 6 visualization files (.png)")
    print(f"  - 1 summary report (TRANSFORMATION_ANALYSIS.md)")

if __name__ == '__main__':
    main()
