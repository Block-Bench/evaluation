#!/usr/bin/env python3
"""
Generate Security Understanding Index (SUI) trajectory chart across transformations.

SUI = 0.40·TDR + 0.30·Reasoning + 0.30·Precision
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
    'llama_3.1_405b'
]

# SUI weights
W_TDR = 0.40
W_REASONING = 0.30
W_PRECISION = 0.30

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

def load_sample_metrics(model: str, sample_id: str, prompt_type: str = 'direct') -> dict:
    """Load metrics for a specific sample."""
    metrics_file = JUDGE_OUTPUT_DIR / model / 'sample_metrics' / f'm_{sample_id}_{prompt_type}.json'

    if not metrics_file.exists():
        return None

    with open(metrics_file, 'r') as f:
        return json.load(f)

def calculate_sui(tdr: float, reasoning: float, precision: float) -> float:
    """Calculate Security Understanding Index.

    Args:
        tdr: Target Detection Rate (0-100)
        reasoning: Average reasoning quality score (0-100)
        precision: Finding precision (0-100)

    Returns:
        SUI score (0-100)
    """
    # Normalize to 0-1 scale
    tdr_norm = tdr / 100.0
    reasoning_norm = reasoning / 100.0
    precision_norm = precision / 100.0

    # Calculate weighted composite
    sui = W_TDR * tdr_norm + W_REASONING * reasoning_norm + W_PRECISION * precision_norm

    # Return as percentage
    return sui * 100.0

def extract_sui_trajectory_data():
    """Extract SUI scores across transformation trajectory."""
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
                total = len(stage_metrics)

                # TDR: Target Detection Rate
                target_found = sum(1 for m in stage_metrics if m.get('target_found', False))
                tdr = (target_found / total * 100) if total > 0 else 0

                # Reasoning Quality: Average of RCIR, AVA, FSV (only when target found)
                reasoning_scores = []
                for m in stage_metrics:
                    if m.get('target_found', False):
                        rcir = m.get('rcir_score', 0)
                        ava = m.get('ava_score', 0)
                        fsv = m.get('fsv_score', 0)

                        # Average the three scores
                        if rcir is not None and ava is not None and fsv is not None:
                            avg_reasoning = (rcir + ava + fsv) / 3.0
                            reasoning_scores.append(avg_reasoning * 100)

                reasoning = np.mean(reasoning_scores) if reasoning_scores else 0

                # Finding Precision
                precisions = [m.get('finding_precision', 0) for m in stage_metrics]
                precision = np.mean(precisions) * 100 if precisions else 0

                # Calculate SUI
                sui = calculate_sui(tdr, reasoning, precision)

                data.append({
                    'Model': model_name,
                    'Stage': stage_name,
                    'Stage Order': list(TRANSFORMATION_STAGES.keys()).index(stage_name),
                    'SUI': sui,
                    'TDR': tdr,
                    'Reasoning': reasoning,
                    'Precision': precision,
                    'Samples': total
                })

    return pd.DataFrame(data)

def plot_sui_trajectory(df):
    """Plot SUI trajectory across transformations."""
    fig, ax = plt.subplots(figsize=(14, 8))

    models = sorted(df['Model'].unique())
    colors = sns.color_palette("husl", len(models))

    for idx, model in enumerate(models):
        model_data = df[df['Model'] == model].sort_values('Stage Order')
        ax.plot(model_data['Stage'], model_data['SUI'],
               marker='o', linewidth=2.5, markersize=8,
               color=colors[idx], label=model, alpha=0.85)

    ax.set_ylabel('Security Understanding Index (SUI)', fontsize=12)
    ax.set_xlabel('Transformation Stage', fontsize=12)
    ax.set_title('Security Understanding Index Across TC Sample Transformations\nSUI = 0.40·TDR + 0.30·Reasoning + 0.30·Precision',
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)

    plt.setp(ax.xaxis.get_majorticklabels(), rotation=25, ha='right')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'sui_trajectory.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Generated: sui_trajectory.png")

    return OUTPUT_DIR / 'sui_trajectory.png'

def main():
    print("=" * 70)
    print("SUI TRAJECTORY ANALYSIS")
    print("=" * 70)
    print()

    print(f"Tracking {len(TC_SAMPLES)} TC samples through {len(TRANSFORMATION_STAGES)} transformation stages")
    print(f"SUI Formula: {W_TDR}·TDR + {W_REASONING}·Reasoning + {W_PRECISION}·Precision")
    print()

    print("Extracting trajectory data...")
    df = extract_sui_trajectory_data()

    if df.empty:
        print("❌ No data found!")
        return

    print(f"Found data for {len(df['Model'].unique())} models")
    print()

    # Show summary table
    print("SUI Summary by Model and Stage:")
    print()
    pivot = df.pivot(index='Model', columns='Stage', values='SUI')
    print(pivot.round(1).to_string())
    print()

    print("Generating SUI trajectory visualization...")
    output_file = plot_sui_trajectory(df)

    print()
    print("=" * 70)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 70)
    print(f"\nOutput file: {output_file}")

if __name__ == '__main__':
    main()
