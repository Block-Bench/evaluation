#!/usr/bin/env python3
"""
Generate high-quality figures for BlockBench ACL paper.
Publication quality: 600 DPI, clean fonts, proper sizing.
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Set up for publication quality
plt.rcParams.update({
    'font.family': 'DejaVu Sans',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 14,
    'axes.titleweight': 'bold',
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'legend.framealpha': 0.95,
    'figure.dpi': 150,
    'savefig.dpi': 600,  # High quality for publication
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.1,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.linewidth': 1.2,
    'axes.grid': True,
    'grid.alpha': 0.3,
    'grid.linewidth': 0.8,
    'lines.linewidth': 2.5,
    'lines.markersize': 9,
})

# Color scheme - distinct, colorblind-friendly palette
MODEL_COLORS = {
    'claude-opus-4-5': '#7B2D8E',      # Deep Purple
    'gemini-3-pro': '#1976D2',         # Strong Blue
    'gpt-5.2': '#388E3C',              # Forest Green
    'deepseek-v3-2': '#D32F2F',        # Strong Red
    'llama-4-maverick': '#F57C00',     # Deep Orange
    'grok-4-fast': '#00838F',          # Teal
    'qwen3-coder-plus': '#C2185B',     # Pink
}

MODEL_DISPLAY = {
    'claude-opus-4-5': 'Claude Opus 4.5',
    'gemini-3-pro': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'deepseek-v3-2': 'DeepSeek v3.2',
    'llama-4-maverick': 'Llama 4 Maverick',
    'grok-4-fast': 'Grok 4',
    'qwen3-coder-plus': 'Qwen3 Coder+',
}

# Order by performance for legend
MODEL_ORDER = [
    'claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'deepseek-v3-2',
    'llama-4-maverick', 'qwen3-coder-plus', 'grok-4-fast'
]

PROTOCOL_COLORS = {
    'direct': '#616161',                        # Gray
    'context_protocol': '#90CAF9',              # Light blue
    'context_protocol_cot': '#1976D2',          # Blue
    'context_protocol_cot_adversarial': '#E65100',   # Deep Orange
    'context_protocol_cot_naturalistic': '#2E7D32',  # Green
}

PROTOCOL_DISPLAY = {
    'direct': 'Direct',
    'context_protocol': 'Context',
    'context_protocol_cot': 'CoT',
    'context_protocol_cot_adversarial': 'Adversarial',
    'context_protocol_cot_naturalistic': 'Naturalistic',
}


def load_results(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def figure1_tc_obfuscation(results: dict, output_dir: Path):
    """
    Figure 1: TC Obfuscation Resistance (Line Chart)
    Shows how models degrade across increasingly obfuscated code.
    """
    tc_data = results.get('tc', {})

    # TC variants in order of transformation intensity
    variants = ['minimalsanitized', 'sanitized', 'nocomments',
                'chameleon_medical', 'shapeshifter_l3', 'trojan', 'falseProphet']
    variant_labels = ['Minimal\nSanitized', 'Full\nSanitized', 'No\nComments',
                      'Chameleon\n(Domain)', 'ShapeShifter\n(Structure)',
                      'Trojan\n(Hidden)', 'False\nProphet']

    fig, ax = plt.subplots(figsize=(12, 7))

    x = np.arange(len(variants))

    # Plot in performance order for cleaner legend
    for detector in MODEL_ORDER:
        if detector not in tc_data:
            continue

        tdrs = []
        for var in variants:
            if var in tc_data[detector]:
                tdrs.append(tc_data[detector][var]['tdr'] * 100)
            else:
                tdrs.append(0)

        ax.plot(x, tdrs,
                marker='o',
                linewidth=2.5,
                markersize=9,
                color=MODEL_COLORS.get(detector, '#333333'),
                label=MODEL_DISPLAY.get(detector, detector),
                markeredgecolor='white',
                markeredgewidth=1.5)

    ax.set_xlabel('Code Transformation Type', fontweight='bold', fontsize=12)
    ax.set_ylabel('Target Detection Rate (%)', fontweight='bold', fontsize=12)
    ax.set_title('Temporal Contamination Benchmark: Detection Across Code Transformations',
                 fontsize=14, fontweight='bold', pad=15)

    ax.set_xticks(x)
    ax.set_xticklabels(variant_labels, fontsize=9)
    ax.set_ylim(0, 80)
    ax.set_xlim(-0.3, len(variants) - 0.7)

    # Add subtle background shading to show transformation intensity
    ax.axvspan(-0.5, 2.5, alpha=0.08, color='green', label='_nolegend_')
    ax.axvspan(2.5, 4.5, alpha=0.08, color='yellow', label='_nolegend_')
    ax.axvspan(4.5, 6.5, alpha=0.08, color='red', label='_nolegend_')

    # Add intensity labels at top
    ax.text(1, 77, 'Light Obfuscation', ha='center', fontsize=9, style='italic', color='#2E7D32')
    ax.text(3.5, 77, 'Medium', ha='center', fontsize=9, style='italic', color='#F57F17')
    ax.text(5.5, 77, 'Heavy', ha='center', fontsize=9, style='italic', color='#C62828')

    # Legend outside plot
    ax.legend(loc='upper right', framealpha=0.95, edgecolor='#cccccc',
              fancybox=True, shadow=False)

    ax.grid(True, alpha=0.3, linestyle='-', linewidth=0.5)
    ax.set_axisbelow(True)

    plt.tight_layout()
    plt.savefig(output_dir / 'figure1_tc_obfuscation.png', dpi=600,
                facecolor='white', edgecolor='none')
    plt.savefig(output_dir / 'figure1_tc_obfuscation.pdf')
    plt.close()
    print(f"✓ Saved Figure 1: {output_dir / 'figure1_tc_obfuscation.png'}")


def figure2_gs_protocol(results: dict, output_dir: Path):
    """
    Figure 2: GS Protocol Effect (Grouped Bar Chart)
    Shows how different prompt strategies affect detection.
    """
    gs_data = results.get('gs', {})

    protocols = ['direct', 'context_protocol', 'context_protocol_cot',
                 'context_protocol_cot_naturalistic', 'context_protocol_cot_adversarial']

    # Order detectors by average performance
    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'qwen3-coder-plus',
                 'deepseek-v3-2', 'grok-4-fast', 'llama-4-maverick']

    fig, ax = plt.subplots(figsize=(14, 7))

    x = np.arange(len(detectors))
    width = 0.16

    bars_list = []
    for i, protocol in enumerate(protocols):
        tdrs = []
        for detector in detectors:
            if detector in gs_data and protocol in gs_data[detector]:
                tdrs.append(gs_data[detector][protocol]['tdr'] * 100)
            else:
                tdrs.append(0)

        offset = (i - len(protocols)/2 + 0.5) * width
        bars = ax.bar(x + offset, tdrs, width * 0.9,
                      label=PROTOCOL_DISPLAY.get(protocol, protocol),
                      color=PROTOCOL_COLORS.get(protocol, '#333333'),
                      edgecolor='white',
                      linewidth=0.5)
        bars_list.append(bars)

        # Add value labels on top of significant bars
        for j, (bar, tdr) in enumerate(zip(bars, tdrs)):
            if tdr >= 25:  # Only label notable values
                ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                       f'{tdr:.0f}', ha='center', va='bottom', fontsize=8,
                       fontweight='bold')

    ax.set_xlabel('Model', fontweight='bold', fontsize=12)
    ax.set_ylabel('Target Detection Rate (%)', fontweight='bold', fontsize=12)
    ax.set_title('Gold Standard Benchmark: Impact of Prompt Engineering Strategies',
                 fontsize=14, fontweight='bold', pad=15)

    ax.set_xticks(x)
    ax.set_xticklabels([MODEL_DISPLAY.get(d, d).replace(' ', '\n') for d in detectors],
                       fontsize=9)
    ax.set_ylim(0, 50)

    # Legend with better positioning
    ax.legend(loc='upper right', ncol=1, framealpha=0.95,
              edgecolor='#cccccc', fancybox=True, title='Prompt Strategy',
              title_fontsize=10)

    ax.grid(True, alpha=0.3, axis='y', linestyle='-', linewidth=0.5)
    ax.set_axisbelow(True)

    # Add annotation for key insight
    ax.annotate('Adversarial framing\nboosts Claude by +29pp',
                xy=(0.15, 41), xytext=(1.5, 46),
                fontsize=9, style='italic',
                arrowprops=dict(arrowstyle='->', color='#666666', lw=1.5),
                bbox=dict(boxstyle='round,pad=0.3', facecolor='#FFF9C4',
                         edgecolor='#F57F17', alpha=0.9))

    plt.tight_layout()
    plt.savefig(output_dir / 'figure2_gs_protocol.png', dpi=600,
                facecolor='white', edgecolor='none')
    plt.savefig(output_dir / 'figure2_gs_protocol.pdf')
    plt.close()
    print(f"✓ Saved Figure 2: {output_dir / 'figure2_gs_protocol.png'}")


def main():
    results_path = Path('results/summaries/comprehensive/comprehensive_results.json')
    output_dir = Path('research/paper/figures')
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Generating High-Quality Paper Figures (600 DPI)")
    print("=" * 60)

    if results_path.exists():
        results = load_results(results_path)
    else:
        print(f"Error: Results not found at {results_path}")
        return

    figure1_tc_obfuscation(results, output_dir)
    figure2_gs_protocol(results, output_dir)

    print("=" * 60)
    print("Done! Figures ready for publication.")
    print("=" * 60)


if __name__ == '__main__':
    main()
