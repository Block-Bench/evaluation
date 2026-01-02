#!/usr/bin/env python3
"""
Generate comprehensive visualizations of model evaluation metrics.
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from typing import Dict, List

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 10

BASE_DIR = Path(__file__).parent.parent
METRICS_FILE = BASE_DIR / 'analysis_results' / 'aggregated_metrics.json'
OUTPUT_DIR = BASE_DIR / 'charts' / 'newmetricschart'

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

def plot_model_rankings(metrics: Dict):
    """Plot model rankings by different metrics."""
    models = []
    detection_rates = []
    quality_scores = []
    precision_scores = []
    sample_counts = []

    for model, data in metrics['by_model'].items():
        overall = data['overall']['all_prompts_aggregated']
        models.append(get_model_display_name(model))
        detection_rates.append(overall['target']['target_detection_rate'] * 100)
        quality_scores.append(overall['quality']['avg_overall_quality_score'] * 100 if overall['quality']['avg_overall_quality_score'] else 0)
        precision_scores.append(overall['findings']['avg_finding_precision'] * 100 if overall['findings']['avg_finding_precision'] else 0)
        sample_counts.append(overall['detection']['total_samples'])

    # Create figure with 3 subplots
    fig, axes = plt.subplots(1, 3, figsize=(18, 6))

    # Detection Rate
    colors_detect = sns.color_palette("RdYlGn", len(models))
    sorted_indices = sorted(range(len(detection_rates)), key=lambda i: detection_rates[i], reverse=True)
    axes[0].barh([models[i] for i in sorted_indices],
                 [detection_rates[i] for i in sorted_indices],
                 color=[colors_detect[i] for i in sorted_indices])
    axes[0].set_xlabel('Detection Rate (%)')
    axes[0].set_title('Target Vulnerability Detection Rate')
    axes[0].set_xlim(0, 100)

    # Add sample counts as text
    for i, idx in enumerate(sorted_indices):
        axes[0].text(detection_rates[idx] + 2, i, f'n={sample_counts[idx]}',
                    va='center', fontsize=8)

    # Quality Score
    sorted_indices = sorted(range(len(quality_scores)), key=lambda i: quality_scores[i], reverse=True)
    axes[1].barh([models[i] for i in sorted_indices],
                 [quality_scores[i] for i in sorted_indices],
                 color=sns.color_palette("Blues_r", len(models)))
    axes[1].set_xlabel('Quality Score (%)')
    axes[1].set_title('Average Quality Score (RCIR/AVA/FSV)')
    axes[1].set_xlim(0, 100)

    # Finding Precision
    sorted_indices = sorted(range(len(precision_scores)), key=lambda i: precision_scores[i], reverse=True)
    axes[2].barh([models[i] for i in sorted_indices],
                 [precision_scores[i] for i in sorted_indices],
                 color=sns.color_palette("Purples_r", len(models)))
    axes[2].set_xlabel('Precision (%)')
    axes[2].set_title('Finding Precision (Avoiding False Positives)')
    axes[2].set_xlim(0, 100)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '01_model_rankings.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 01_model_rankings.png")

def plot_prompt_type_performance(metrics: Dict):
    """Plot performance by prompt type for each model."""
    prompt_types = ['direct', 'adversarial', 'naturalistic']
    models_data = []

    for model, data in metrics['by_model'].items():
        by_prompt = data.get('by_prompt_type', {})
        model_name = get_model_display_name(model)

        for prompt in prompt_types:
            if prompt in by_prompt:
                prompt_data = by_prompt[prompt]
                models_data.append({
                    'Model': model_name,
                    'Prompt Type': prompt.capitalize(),
                    'Detection Rate': prompt_data['target']['target_detection_rate'] * 100,
                    'Quality Score': (prompt_data['quality']['avg_overall_quality_score'] or 0) * 100,
                    'Sample Count': prompt_data['detection']['total_samples']
                })

    df = pd.DataFrame(models_data)

    # Create figure with 2 subplots
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))

    # Detection Rate by Prompt Type
    pivot_detect = df.pivot(index='Model', columns='Prompt Type', values='Detection Rate')
    pivot_detect.plot(kind='bar', ax=axes[0], color=['#2ecc71', '#e74c3c', '#3498db'])
    axes[0].set_ylabel('Detection Rate (%)')
    axes[0].set_title('Detection Rate by Prompt Type')
    axes[0].set_xlabel('')
    axes[0].legend(title='Prompt Type')
    axes[0].set_ylim(0, 100)
    plt.setp(axes[0].xaxis.get_majorticklabels(), rotation=45, ha='right')

    # Quality Score by Prompt Type
    pivot_quality = df.pivot(index='Model', columns='Prompt Type', values='Quality Score')
    pivot_quality.plot(kind='bar', ax=axes[1], color=['#2ecc71', '#e74c3c', '#3498db'])
    axes[1].set_ylabel('Quality Score (%)')
    axes[1].set_title('Quality Score by Prompt Type')
    axes[1].set_xlabel('')
    axes[1].legend(title='Prompt Type')
    axes[1].set_ylim(0, 100)
    plt.setp(axes[1].xaxis.get_majorticklabels(), rotation=45, ha='right')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '02_prompt_type_performance.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 02_prompt_type_performance.png")

def plot_quality_breakdown(metrics: Dict):
    """Plot breakdown of quality metrics (RCIR, AVA, FSV)."""
    models = []
    rcir_scores = []
    ava_scores = []
    fsv_scores = []

    for model, data in metrics['by_model'].items():
        overall = data['overall']['all_prompts_aggregated']
        quality = overall['quality']

        if quality['avg_rcir_score'] is not None:
            models.append(get_model_display_name(model))
            rcir_scores.append(quality['avg_rcir_score'] * 100)
            ava_scores.append(quality['avg_ava_score'] * 100)
            fsv_scores.append(quality['avg_fsv_score'] * 100)

    x = np.arange(len(models))
    width = 0.25

    fig, ax = plt.subplots(figsize=(14, 6))

    ax.bar(x - width, rcir_scores, width, label='RCIR (Root Cause)', color='#e74c3c')
    ax.bar(x, ava_scores, width, label='AVA (Attack Vector)', color='#3498db')
    ax.bar(x + width, fsv_scores, width, label='FSV (Fix Suggestion)', color='#2ecc71')

    ax.set_ylabel('Score (%)')
    ax.set_title('Quality Metrics Breakdown: RCIR vs AVA vs FSV')
    ax.set_xticks(x)
    ax.set_xticklabels(models, rotation=45, ha='right')
    ax.legend()
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '03_quality_breakdown.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 03_quality_breakdown.png")

def plot_detection_vs_quality(metrics: Dict):
    """Scatter plot: Detection Rate vs Quality Score."""
    models = []
    detection_rates = []
    quality_scores = []
    sample_counts = []

    for model, data in metrics['by_model'].items():
        overall = data['overall']['all_prompts_aggregated']
        models.append(get_model_display_name(model))
        detection_rates.append(overall['target']['target_detection_rate'] * 100)
        quality_scores.append((overall['quality']['avg_overall_quality_score'] or 0) * 100)
        sample_counts.append(overall['detection']['total_samples'])

    fig, ax = plt.subplots(figsize=(10, 8))

    # Create scatter plot with size based on sample count
    sizes = [count * 5 for count in sample_counts]
    scatter = ax.scatter(detection_rates, quality_scores, s=sizes, alpha=0.6,
                        c=range(len(models)), cmap='tab10')

    # Add model labels
    for i, model in enumerate(models):
        ax.annotate(model, (detection_rates[i], quality_scores[i]),
                   xytext=(5, 5), textcoords='offset points', fontsize=9)

    ax.set_xlabel('Detection Rate (%)')
    ax.set_ylabel('Quality Score (%)')
    ax.set_title('Detection Rate vs Quality Score\n(Bubble size = sample count)')
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)

    # Add diagonal reference line
    ax.plot([0, 100], [0, 100], 'k--', alpha=0.3, linewidth=1)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '04_detection_vs_quality.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 04_detection_vs_quality.png")

def plot_hallucination_rates(metrics: Dict):
    """Plot hallucination rates and finding quality."""
    models = []
    hallucination_rates = []
    avg_findings = []
    precision = []

    for model, data in metrics['by_model'].items():
        overall = data['overall']['all_prompts_aggregated']
        findings = overall['findings']

        models.append(get_model_display_name(model))
        hallucination_rates.append(findings['hallucination_rate'] * 100)
        avg_findings.append(findings['avg_findings_per_sample'])
        precision.append((findings['avg_finding_precision'] or 0) * 100)

    fig, axes = plt.subplots(1, 2, figsize=(16, 6))

    # Hallucination Rate
    sorted_indices = sorted(range(len(hallucination_rates)), key=lambda i: hallucination_rates[i])
    colors = sns.color_palette("RdYlGn_r", len(models))
    axes[0].barh([models[i] for i in sorted_indices],
                 [hallucination_rates[i] for i in sorted_indices],
                 color=[colors[i] for i in sorted_indices])
    axes[0].set_xlabel('Hallucination Rate (%)')
    axes[0].set_title('Hallucination Rate (Lower is Better)')
    axes[0].set_xlim(0, max(hallucination_rates) * 1.2)

    # Average Findings per Sample
    sorted_indices = sorted(range(len(avg_findings)), key=lambda i: avg_findings[i], reverse=True)
    axes[1].barh([models[i] for i in sorted_indices],
                 [avg_findings[i] for i in sorted_indices],
                 color=sns.color_palette("viridis", len(models)))
    axes[1].set_xlabel('Average Findings per Sample')
    axes[1].set_title('Average Number of Findings Reported')

    # Add precision as text
    for i, idx in enumerate(sorted_indices):
        axes[1].text(avg_findings[idx] + 0.1, i, f'{precision[idx]:.0f}% precise',
                    va='center', fontsize=8)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '05_hallucination_and_findings.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 05_hallucination_and_findings.png")

def plot_vulnerability_type_performance(metrics: Dict):
    """Plot performance by vulnerability type."""
    # Collect data
    vuln_data = []

    for model, data in metrics['by_model'].items():
        by_vuln = data.get('by_vulnerability_type', {})
        model_name = get_model_display_name(model)

        for vuln_type, vuln_metrics in by_vuln.items():
            vuln_data.append({
                'Model': model_name,
                'Vulnerability Type': vuln_type.replace('_', ' ').title(),
                'Detection Rate': vuln_metrics['target']['target_detection_rate'] * 100,
                'Sample Count': vuln_metrics['detection']['total_samples']
            })

    if not vuln_data:
        print("⚠ No vulnerability type data available")
        return

    df = pd.DataFrame(vuln_data)

    # Get top vulnerability types by sample count
    vuln_counts = df.groupby('Vulnerability Type')['Sample Count'].sum().sort_values(ascending=False)
    top_vulns = vuln_counts.head(8).index.tolist()

    df_filtered = df[df['Vulnerability Type'].isin(top_vulns)]

    fig, ax = plt.subplots(figsize=(14, 8))

    pivot = df_filtered.pivot(index='Vulnerability Type', columns='Model', values='Detection Rate')
    pivot.plot(kind='barh', ax=ax, width=0.8)

    ax.set_xlabel('Detection Rate (%)')
    ax.set_title('Detection Rate by Vulnerability Type (Top 8)')
    ax.legend(title='Model', bbox_to_anchor=(1.05, 1), loc='upper left')
    ax.set_xlim(0, 100)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '06_vulnerability_type_performance.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 06_vulnerability_type_performance.png")

def plot_difficulty_tier_performance(metrics: Dict):
    """Plot performance by difficulty tier."""
    tier_data = []

    for model, data in metrics['by_model'].items():
        by_tier = data.get('by_difficulty_tier', {})
        model_name = get_model_display_name(model)

        for tier, tier_metrics in by_tier.items():
            tier_data.append({
                'Model': model_name,
                'Difficulty Tier': str(tier),
                'Detection Rate': tier_metrics['target']['target_detection_rate'] * 100,
                'Quality Score': (tier_metrics['quality']['avg_overall_quality_score'] or 0) * 100,
                'Sample Count': tier_metrics['detection']['total_samples']
            })

    if not tier_data:
        print("⚠ No difficulty tier data available")
        return

    df = pd.DataFrame(tier_data)

    fig, axes = plt.subplots(1, 2, figsize=(16, 6))

    # Detection Rate by Tier
    pivot_detect = df.pivot(index='Model', columns='Difficulty Tier', values='Detection Rate')
    pivot_detect.plot(kind='bar', ax=axes[0], color=sns.color_palette("YlOrRd", len(pivot_detect.columns)))
    axes[0].set_ylabel('Detection Rate (%)')
    axes[0].set_title('Detection Rate by Difficulty Tier')
    axes[0].set_xlabel('')
    axes[0].legend(title='Difficulty Tier')
    axes[0].set_ylim(0, 100)
    plt.setp(axes[0].xaxis.get_majorticklabels(), rotation=45, ha='right')

    # Quality Score by Tier
    pivot_quality = df.pivot(index='Model', columns='Difficulty Tier', values='Quality Score')
    pivot_quality.plot(kind='bar', ax=axes[1], color=sns.color_palette("YlGnBu", len(pivot_quality.columns)))
    axes[1].set_ylabel('Quality Score (%)')
    axes[1].set_title('Quality Score by Difficulty Tier')
    axes[1].set_xlabel('')
    axes[1].legend(title='Difficulty Tier')
    axes[1].set_ylim(0, 100)
    plt.setp(axes[1].xaxis.get_majorticklabels(), rotation=45, ha='right')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '07_difficulty_tier_performance.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 07_difficulty_tier_performance.png")

def plot_comprehensive_comparison(metrics: Dict):
    """Create comprehensive heatmap comparison."""
    models = []
    data_dict = {
        'Detection Rate': [],
        'Quality Score': [],
        'Finding Precision': [],
        'RCIR': [],
        'AVA': [],
        'FSV': [],
        'Accuracy': [],
        'Recall': []
    }

    for model, data in metrics['by_model'].items():
        overall = data['overall']['all_prompts_aggregated']
        models.append(get_model_display_name(model))

        data_dict['Detection Rate'].append(overall['target']['target_detection_rate'] * 100)
        data_dict['Quality Score'].append((overall['quality']['avg_overall_quality_score'] or 0) * 100)
        data_dict['Finding Precision'].append((overall['findings']['avg_finding_precision'] or 0) * 100)
        data_dict['RCIR'].append((overall['quality']['avg_rcir_score'] or 0) * 100)
        data_dict['AVA'].append((overall['quality']['avg_ava_score'] or 0) * 100)
        data_dict['FSV'].append((overall['quality']['avg_fsv_score'] or 0) * 100)
        data_dict['Accuracy'].append(overall['detection']['accuracy'] * 100)
        data_dict['Recall'].append(overall['detection']['recall'] * 100)

    df = pd.DataFrame(data_dict, index=models)

    fig, ax = plt.subplots(figsize=(12, 8))

    sns.heatmap(df, annot=True, fmt='.1f', cmap='RdYlGn', center=50,
                vmin=0, vmax=100, ax=ax, cbar_kws={'label': 'Score (%)'})

    ax.set_title('Comprehensive Model Performance Heatmap', fontsize=14, pad=20)
    ax.set_xlabel('')
    ax.set_ylabel('')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / '08_comprehensive_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: 08_comprehensive_heatmap.png")

def create_summary_report():
    """Create a text summary of what charts were generated."""
    summary = """# Metrics Visualization Summary

## Generated Charts

1. **01_model_rankings.png**
   - Three horizontal bar charts showing model rankings
   - Detection Rate, Quality Score, and Finding Precision
   - Sorted by performance with sample counts

2. **02_prompt_type_performance.png**
   - Detection rate and quality by prompt type (Direct, Adversarial, Naturalistic)
   - Grouped bar charts for easy comparison

3. **03_quality_breakdown.png**
   - Breakdown of quality metrics: RCIR, AVA, FSV
   - Shows which models excel at different aspects of vulnerability analysis

4. **04_detection_vs_quality.png**
   - Scatter plot showing trade-off between detection rate and quality
   - Bubble size represents sample count
   - Helps identify balanced vs specialized models

5. **05_hallucination_and_findings.png**
   - Hallucination rates (false findings)
   - Average findings per sample with precision annotations

6. **06_vulnerability_type_performance.png**
   - Detection rates for top 8 vulnerability types
   - Shows which models excel at which vulnerability categories

7. **07_difficulty_tier_performance.png**
   - Performance across different difficulty tiers
   - Shows model degradation on harder samples

8. **08_comprehensive_heatmap.png**
   - Complete performance heatmap across all key metrics
   - Easy to spot strengths and weaknesses at a glance

## How to Use These Charts

- Use charts 1, 4, and 8 for overview presentations
- Use charts 2 and 7 to show robustness across conditions
- Use charts 3 and 5 for detailed capability analysis
- Use chart 6 for domain-specific insights

All charts are saved at 300 DPI for publication quality.
"""

    with open(OUTPUT_DIR / 'README.md', 'w') as f:
        f.write(summary)

    print("✓ Generated: README.md")

def main():
    print(f"\n{'='*60}")
    print("GENERATING METRICS VISUALIZATIONS")
    print(f"{'='*60}\n")

    print(f"Loading metrics from: {METRICS_FILE}")
    metrics = load_metrics()

    print(f"Output directory: {OUTPUT_DIR}\n")

    print("Generating charts...\n")

    plot_model_rankings(metrics)
    plot_prompt_type_performance(metrics)
    plot_quality_breakdown(metrics)
    plot_detection_vs_quality(metrics)
    plot_hallucination_rates(metrics)
    plot_vulnerability_type_performance(metrics)
    plot_difficulty_tier_performance(metrics)
    plot_comprehensive_comparison(metrics)

    create_summary_report()

    print(f"\n{'='*60}")
    print(f"✓ Successfully generated 8 charts + README")
    print(f"{'='*60}\n")
    print(f"View charts in: {OUTPUT_DIR}")

if __name__ == '__main__':
    main()
