#!/usr/bin/env python3
"""
Generate Target Detection Rate chart for paper.
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

# Set style
sns.set_style("whitegrid")
plt.rcParams['font.size'] = 11

BASE_DIR = Path(__file__).parent.parent
METRICS_FILE = BASE_DIR / 'analysis_results' / 'aggregated_metrics.json'
OUTPUT_FILE = BASE_DIR / 'research' / 'aberdeen_eval_project_ws2024' / 'figures' / 'tdr_comparison.png'

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

def main():
    # Load metrics
    with open(METRICS_FILE, 'r') as f:
        data = json.load(f)

    # Extract TDR for each model
    model_tdrs = []
    if 'by_model' in data:
        for model, model_data in data['by_model'].items():
            if 'overall' in model_data:
                overall = model_data['overall']
                if 'all_prompts_aggregated' in overall:
                    agg = overall['all_prompts_aggregated']
                    if 'target' in agg and 'target_detection_rate' in agg['target']:
                        tdr = agg['target']['target_detection_rate'] * 100  # Convert to percentage
                        model_tdrs.append({
                            'model': get_model_display_name(model),
                            'tdr': tdr
                        })

    # Sort by TDR descending
    model_tdrs.sort(key=lambda x: x['tdr'], reverse=True)

    # Create figure
    fig, ax = plt.subplots(figsize=(8, 5))

    models = [x['model'] for x in model_tdrs]
    tdrs = [x['tdr'] for x in model_tdrs]

    # Use RdYlGn colormap like the original model rankings chart
    colors = sns.color_palette("RdYlGn", len(models))
    bars = ax.barh(models, tdrs, color=colors)

    # Add value labels on bars
    for i, (bar, tdr) in enumerate(zip(bars, tdrs)):
        width = bar.get_width()
        ax.text(width + 1, bar.get_y() + bar.get_height()/2,
                f'{tdr:.1f}%',
                ha='left', va='center', fontsize=10, fontweight='bold')

    # Formatting
    ax.set_xlabel('Target Detection Rate (%)', fontsize=12, fontweight='bold')
    ax.set_xlim(0, max(tdrs) + 10)
    ax.grid(axis='x', alpha=0.3)
    ax.set_axisbelow(True)

    # Invert y-axis so highest is at top
    ax.invert_yaxis()

    plt.tight_layout()

    # Save
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(OUTPUT_FILE, dpi=300, bbox_inches='tight')
    print(f"Chart saved to: {OUTPUT_FILE}")

    plt.close()

if __name__ == "__main__":
    main()
