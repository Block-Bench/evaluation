#!/usr/bin/env python3
"""
Generate CodeAct paradox figures for BlockBench paper.
1. Main Paper: Root Cause Matching vs TDR (the understanding paradox)
2. Appendix: Contamination Index vs Root Cause Matching
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

# Publication quality settings
plt.rcParams.update({
    'font.family': 'DejaVu Sans',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 14,
    'axes.titleweight': 'bold',
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.dpi': 150,
    'savefig.dpi': 600,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.1,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.linewidth': 1.2,
    'axes.grid': True,
    'grid.alpha': 0.3,
})

# Color scheme
MODEL_COLORS = {
    'claude-opus-4-5': '#7B2D8E',
    'gemini-3-pro': '#1976D2',
    'gpt-5.2': '#388E3C',
    'deepseek-v3-2': '#D32F2F',
    'llama-4-maverick': '#F57C00',
    'grok-4-fast': '#00838F',
    'qwen3-coder-plus': '#C2185B',
}

MODEL_DISPLAY = {
    'claude-opus-4-5': 'Claude',
    'gemini-3-pro': 'Gemini',
    'gpt-5.2': 'GPT-5.2',
    'deepseek-v3-2': 'DeepSeek',
    'llama-4-maverick': 'Llama',
    'grok-4-fast': 'Grok',
    'qwen3-coder-plus': 'Qwen',
}


def load_codeact_metrics():
    """Load CodeAct metrics from JSON."""
    path = Path('code_acts/results/codeact_full_metrics.json')
    with open(path) as f:
        return json.load(f)


def load_tdr_data():
    """Load TDR from comprehensive results or compute from TC data."""
    # Use TC average TDR as the main TDR metric (post-cutoff, harder test)
    # These are from the majority vote results
    tdr_data = {
        'claude-opus-4-5': 50.9,  # TC average from results.tex
        'gemini-3-pro': 38.5,
        'gpt-5.2': 36.0,
        'deepseek-v3-2': 37.0,
        'llama-4-maverick': 31.7,
        'qwen3-coder-plus': 33.2,
        'grok-4-fast': 21.4,
    }
    return tdr_data


def figure_main_tdr_vs_rootcause(codeact_data: dict, tdr_data: dict, output_dir: Path):
    """
    Main Paper Figure: Root Cause Line Match vs TDR Paradox

    Key insight (corrected):
    - TDR = True Understanding (LLM judges evaluate reasoning quality)
    - Root Cause Line Match = Pattern Matching (just finding the right lines)

    Points where Root Cause > TDR = Pattern matching without understanding
    (Model finds right lines but can't explain why)
    """
    fig, ax = plt.subplots(figsize=(9, 7))

    # Extract data
    models = []
    tdrs = []
    root_cause_rates = []

    for item in codeact_data['summary']:
        detector = item['detector']
        if detector in tdr_data:
            models.append(detector)
            tdrs.append(tdr_data[detector])
            # Use TR root cause rate (harder test, with decoys)
            root_cause_rates.append(item['tr_root_cause_found_rate'] * 100)

    # X = Root Cause Match (pattern matching), Y = TDR (understanding)
    # Plot diagonal reference line
    ax.plot([0, 100], [0, 100], 'k--', alpha=0.3, linewidth=1.5,
            label='Line Match = Understanding')

    # Shade the "pattern matching" zone (below diagonal: high line match, low TDR)
    ax.fill_between([0, 100], [0, 0], [0, 100], alpha=0.08, color='red', label='_nolegend_')
    ax.text(55, 28, 'Pattern Matching Zone\n(finds lines, poor reasoning)',
            fontsize=9, style='italic', color='#B71C1C', alpha=0.7, ha='center')

    # Shade the "understanding" zone (above diagonal: high TDR, lower line match)
    ax.fill_between([0, 100], [0, 100], [100, 100], alpha=0.08, color='green', label='_nolegend_')
    ax.text(35, 58, 'Understanding Zone\n(good reasoning)',
            fontsize=9, style='italic', color='#2E7D32', alpha=0.7, ha='center')

    # Plot each model
    for i, model in enumerate(models):
        ax.scatter(root_cause_rates[i], tdrs[i],  # X=line match, Y=TDR
                   s=250,
                   c=MODEL_COLORS.get(model, '#333333'),
                   edgecolors='white',
                   linewidths=2,
                   zorder=5)

        # Add label with offset to avoid overlap
        offset_x = 2
        offset_y = 2
        if model == 'grok-4-fast':
            offset_x = 3
        elif model == 'deepseek-v3-2':
            offset_y = -5
        elif model == 'claude-opus-4-5':
            offset_x = -8
            offset_y = 2
        elif model == 'llama-4-maverick':
            offset_y = -5

        ax.annotate(MODEL_DISPLAY.get(model, model),
                    (root_cause_rates[i], tdrs[i]),
                    xytext=(offset_x, offset_y),
                    textcoords='offset points',
                    fontsize=10,
                    fontweight='bold',
                    color=MODEL_COLORS.get(model, '#333333'))

    ax.set_xlabel('ROOT_CAUSE Match Rate (%) - Pattern Matching', fontweight='bold', fontsize=12)
    ax.set_ylabel('Target Detection Rate (%) - Understanding', fontweight='bold', fontsize=12)
    ax.set_title('The Pattern Matching Paradox',
                 fontsize=14, fontweight='bold', pad=15)

    ax.set_xlim(25, 70)
    ax.set_ylim(15, 60)

    # Add insight annotation for Llama (high line match, low TDR = pattern matching)
    ax.annotate('Llama: Finds lines but\npoor reasoning',
                xy=(60.9, 31.7), xytext=(52, 22),
                fontsize=9, style='italic',
                arrowprops=dict(arrowstyle='->', color='#666666', lw=1.2),
                bbox=dict(boxstyle='round,pad=0.3', facecolor='#FFF3E0',
                         edgecolor='#F57C00', alpha=0.9))

    ax.grid(True, alpha=0.3, linestyle='-', linewidth=0.5)
    ax.set_axisbelow(True)

    plt.tight_layout()
    plt.savefig(output_dir / 'figure3_tdr_vs_rootcause.png', dpi=600,
                facecolor='white', edgecolor='none')
    plt.savefig(output_dir / 'figure3_tdr_vs_rootcause.pdf')
    plt.close()
    print(f"Saved: {output_dir / 'figure3_tdr_vs_rootcause.png'}")


def figure_appendix_contamination(codeact_data: dict, output_dir: Path):
    """
    Appendix Figure: Contamination Index vs Root Cause Matching
    Shows how pattern reliance affects understanding
    """
    fig, ax = plt.subplots(figsize=(9, 7))

    # Extract data
    models = []
    contamination = []
    root_cause_rates = []

    for item in codeact_data['summary']:
        detector = item['detector']
        models.append(detector)
        contamination.append(item['contamination_index'] * 100)
        root_cause_rates.append(item['tr_root_cause_found_rate'] * 100)

    # Plot each model
    for i, model in enumerate(models):
        ax.scatter(contamination[i], root_cause_rates[i],
                   s=250,
                   c=MODEL_COLORS.get(model, '#333333'),
                   edgecolors='white',
                   linewidths=2,
                   zorder=5)

        # Add label
        offset_x = 2
        offset_y = 2
        if model == 'claude-opus-4-5':
            offset_x = -10
            offset_y = 3
        elif model == 'deepseek-v3-2':
            offset_y = -5
        elif model == 'qwen3-coder-plus':
            offset_x = -8
        elif model == 'llama-4-maverick':
            offset_y = 3

        ax.annotate(MODEL_DISPLAY.get(model, model),
                    (contamination[i], root_cause_rates[i]),
                    xytext=(offset_x, offset_y),
                    textcoords='offset points',
                    fontsize=10,
                    fontweight='bold',
                    color=MODEL_COLORS.get(model, '#333333'))

    # Add trend indication
    ax.annotate('', xy=(5, 62), xytext=(38, 45),
                arrowprops=dict(arrowstyle='->', color='#666666', lw=2,
                               connectionstyle='arc3,rad=-0.2'))
    ax.text(20, 58, 'Less pattern reliance\n= More robust detection',
            fontsize=9, style='italic', color='#2E7D32', ha='center')

    ax.set_xlabel('Contamination Index (%)\n(Performance drop when DECOY segments added)',
                  fontweight='bold', fontsize=11)
    ax.set_ylabel('ROOT_CAUSE Match Rate (%)', fontweight='bold', fontsize=12)
    ax.set_title('Contamination Index vs ROOT_CAUSE Matching',
                 fontsize=14, fontweight='bold', pad=15)

    ax.set_xlim(0, 45)
    ax.set_ylim(25, 70)

    # Shade high contamination zone
    ax.axvspan(25, 45, alpha=0.08, color='red')
    ax.text(35, 30, 'High Pattern\nReliance', fontsize=9, style='italic',
            color='#B71C1C', alpha=0.7, ha='center')

    ax.grid(True, alpha=0.3, linestyle='-', linewidth=0.5)
    ax.set_axisbelow(True)

    plt.tight_layout()
    plt.savefig(output_dir / 'figure_a4_contamination.png', dpi=600,
                facecolor='white', edgecolor='none')
    plt.savefig(output_dir / 'figure_a4_contamination.pdf')
    plt.close()
    print(f"Saved: {output_dir / 'figure_a4_contamination.png'}")


def main():
    output_dir = Path('research/paper/figures')
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Generating CodeAct Paradox Figures")
    print("=" * 60)

    # Load data
    codeact_data = load_codeact_metrics()
    tdr_data = load_tdr_data()

    # Generate figures
    figure_main_tdr_vs_rootcause(codeact_data, tdr_data, output_dir)
    figure_appendix_contamination(codeact_data, output_dir)

    print("=" * 60)
    print("Done!")
    print("=" * 60)


if __name__ == '__main__':
    main()
