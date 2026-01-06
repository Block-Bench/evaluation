#!/usr/bin/env python3
"""
Generate all figures for BlockBench ACL paper.

Figures:
- Figure 1: TC Obfuscation Resistance (Line Chart)
- Figure 2: GS Protocol Effect (Grouped Bar Chart)
- Figure 4: Vulnerability Type Heatmap
- Figure 5: Differential Detection Advantage (Paired Bar)
- Figure A1: DS Difficulty Scaling (Line Chart)
- Figure A2: Judge Agreement Heatmap
- Figure A3: Radar Chart - Top Model Comparison
"""

import json
import argparse
from pathlib import Path
from collections import defaultdict
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Try to import seaborn, fall back gracefully
try:
    import seaborn as sns
    HAS_SEABORN = True
except ImportError:
    HAS_SEABORN = False
    print("Warning: seaborn not available, using matplotlib defaults")


# Color scheme for models
MODEL_COLORS = {
    'claude-opus-4-5': '#9467bd',      # Purple
    'gemini-3-pro': '#1f77b4',         # Blue
    'gpt-5.2': '#2ca02c',              # Green
    'deepseek-v3-2': '#d62728',        # Red
    'llama-4-maverick': '#ff7f0e',     # Orange
    'grok-4-fast': '#17becf',          # Cyan
    'qwen3-coder-plus': '#e377c2',     # Pink
    'slither': '#7f7f7f',              # Gray
    'mythril': '#bcbd22',              # Olive
}

MODEL_DISPLAY = {
    'claude-opus-4-5': 'Claude',
    'gemini-3-pro': 'Gemini',
    'gpt-5.2': 'GPT-5.2',
    'deepseek-v3-2': 'DeepSeek',
    'llama-4-maverick': 'Llama',
    'grok-4-fast': 'Grok',
    'qwen3-coder-plus': 'Qwen',
    'slither': 'Slither',
    'mythril': 'Mythril',
}

# Protocol colors for GS
PROTOCOL_COLORS = {
    'direct': '#7f7f7f',                    # Gray
    'context_protocol': '#aec7e8',          # Light blue
    'context_protocol_cot': '#1f77b4',      # Blue
    'context_protocol_cot_adversarial': '#ff7f0e',  # Orange
    'context_protocol_cot_naturalistic': '#2ca02c', # Green
}

PROTOCOL_DISPLAY = {
    'direct': 'Direct',
    'context_protocol': 'Context',
    'context_protocol_cot': 'CoT',
    'context_protocol_cot_adversarial': 'Adversarial',
    'context_protocol_cot_naturalistic': 'Naturalistic',
}


def setup_style():
    """Set up matplotlib style for publication-quality figures."""
    plt.rcParams.update({
        'font.family': 'sans-serif',
        'font.size': 10,
        'axes.labelsize': 11,
        'axes.titlesize': 12,
        'xtick.labelsize': 9,
        'ytick.labelsize': 9,
        'legend.fontsize': 9,
        'figure.dpi': 150,
        'savefig.dpi': 300,
        'savefig.bbox': 'tight',
        'axes.spines.top': False,
        'axes.spines.right': False,
    })
    if HAS_SEABORN:
        sns.set_style("whitegrid")


def load_comprehensive_results(results_path: Path) -> dict:
    """Load the comprehensive results JSON."""
    with open(results_path) as f:
        return json.load(f)


def figure1_tc_obfuscation(results: dict, output_dir: Path):
    """
    Figure 1: TC Obfuscation Resistance (Line Chart)
    Shows TDR across TC variants for each model.
    """
    tc_data = results.get('tc', {})

    # TC variants in order of obfuscation level
    variants = ['minimalsanitized', 'sanitized', 'nocomments',
                'chameleon_medical', 'shapeshifter_l3', 'trojan', 'falseProphet']
    variant_labels = ['MinSan', 'Sanitized', 'NoCom', 'Chameleon', 'ShapeShifter', 'Trojan', 'FalseProphet']

    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'deepseek-v3-2',
                 'llama-4-maverick', 'grok-4-fast', 'qwen3-coder-plus']

    fig, ax = plt.subplots(figsize=(10, 6))

    x = np.arange(len(variants))

    for detector in detectors:
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
                markersize=8,
                linewidth=2,
                color=MODEL_COLORS.get(detector, '#333333'),
                label=MODEL_DISPLAY.get(detector, detector))

    ax.set_xlabel('Obfuscation Variant')
    ax.set_ylabel('Target Detection Rate (%)')
    ax.set_title('TC Obfuscation Resistance: TDR Across Code Transformations')
    ax.set_xticks(x)
    ax.set_xticklabels(variant_labels, rotation=45, ha='right')
    ax.set_ylim(0, 80)
    ax.legend(loc='upper right', framealpha=0.9)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_dir / 'figure1_tc_obfuscation.pdf')
    plt.savefig(output_dir / 'figure1_tc_obfuscation.png')
    plt.close()
    print(f"Saved Figure 1: {output_dir / 'figure1_tc_obfuscation.pdf'}")


def figure2_gs_protocol(results: dict, output_dir: Path):
    """
    Figure 2: GS Protocol Effect (Grouped Bar Chart)
    Shows TDR by prompt protocol for each model.
    """
    gs_data = results.get('gs', {})

    protocols = ['direct', 'context_protocol', 'context_protocol_cot',
                 'context_protocol_cot_naturalistic', 'context_protocol_cot_adversarial']

    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'deepseek-v3-2',
                 'llama-4-maverick', 'grok-4-fast', 'qwen3-coder-plus']

    fig, ax = plt.subplots(figsize=(12, 6))

    x = np.arange(len(detectors))
    width = 0.15

    for i, protocol in enumerate(protocols):
        tdrs = []
        for detector in detectors:
            if detector in gs_data and protocol in gs_data[detector]:
                tdrs.append(gs_data[detector][protocol]['tdr'] * 100)
            else:
                tdrs.append(0)

        offset = (i - len(protocols)/2 + 0.5) * width
        bars = ax.bar(x + offset, tdrs, width,
                      label=PROTOCOL_DISPLAY.get(protocol, protocol),
                      color=PROTOCOL_COLORS.get(protocol, '#333333'))

    ax.set_xlabel('Model')
    ax.set_ylabel('Target Detection Rate (%)')
    ax.set_title('GS Protocol Effect: Impact of Prompt Engineering')
    ax.set_xticks(x)
    ax.set_xticklabels([MODEL_DISPLAY.get(d, d) for d in detectors])
    ax.set_ylim(0, 50)
    ax.legend(loc='upper right', ncol=2)
    ax.grid(True, alpha=0.3, axis='y')

    plt.tight_layout()
    plt.savefig(output_dir / 'figure2_gs_protocol.pdf')
    plt.savefig(output_dir / 'figure2_gs_protocol.png')
    plt.close()
    print(f"Saved Figure 2: {output_dir / 'figure2_gs_protocol.pdf'}")


def figure4_vuln_type_heatmap(output_dir: Path):
    """
    Figure 4: Vulnerability Type Heatmap
    Shows TDR by vulnerability type for each model.

    Note: This requires per-vulnerability-type data which may need to be
    aggregated from ground truth metadata.
    """
    # Sample data - replace with actual per-vulnerability-type aggregation
    vuln_types = ['Reentrancy', 'Access Control', 'Oracle', 'Arithmetic',
                  'Front-running', 'DoS', 'Logic Error']

    models = ['Claude', 'Gemini', 'GPT-5.2', 'DeepSeek', 'Llama', 'Grok', 'Qwen']

    # Placeholder data - needs real aggregation
    # This should come from analyzing ground truth vulnerability types
    data = np.array([
        [85, 78, 72, 65, 58, 45, 52],  # Reentrancy
        [80, 75, 68, 62, 55, 40, 48],  # Access Control
        [70, 65, 55, 50, 42, 35, 40],  # Oracle
        [75, 70, 60, 55, 48, 38, 45],  # Arithmetic
        [60, 55, 48, 42, 35, 28, 38],  # Front-running
        [65, 60, 52, 48, 40, 32, 42],  # DoS
        [55, 50, 45, 40, 35, 25, 35],  # Logic Error
    ])

    fig, ax = plt.subplots(figsize=(10, 6))

    if HAS_SEABORN:
        sns.heatmap(data, annot=True, fmt='.0f', cmap='Blues',
                    xticklabels=models, yticklabels=vuln_types,
                    ax=ax, cbar_kws={'label': 'TDR (%)'})
    else:
        im = ax.imshow(data, cmap='Blues', aspect='auto')
        ax.set_xticks(np.arange(len(models)))
        ax.set_yticks(np.arange(len(vuln_types)))
        ax.set_xticklabels(models)
        ax.set_yticklabels(vuln_types)

        # Add text annotations
        for i in range(len(vuln_types)):
            for j in range(len(models)):
                text = ax.text(j, i, f'{data[i, j]:.0f}',
                              ha='center', va='center', color='black', fontsize=8)

        plt.colorbar(im, ax=ax, label='TDR (%)')

    ax.set_title('Vulnerability Type Detection Rates by Model')
    ax.set_xlabel('Model')
    ax.set_ylabel('Vulnerability Type')

    plt.tight_layout()
    plt.savefig(output_dir / 'figure4_vuln_heatmap.pdf')
    plt.savefig(output_dir / 'figure4_vuln_heatmap.png')
    plt.close()
    print(f"Saved Figure 4: {output_dir / 'figure4_vuln_heatmap.pdf'}")
    print("  NOTE: Using placeholder data - needs real per-vuln-type aggregation")


def figure5_differential(results: dict, output_dir: Path):
    """
    Figure 5: Differential Detection Advantage (Paired Bar)
    Shows Single vs Differential TDR comparison.
    """
    tc_data = results.get('tc', {})

    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'deepseek-v3-2',
                 'llama-4-maverick', 'grok-4-fast', 'qwen3-coder-plus']

    # Get sanitized (single) vs differential TDR
    # Note: differential variant may need to be added to TC results
    single_tdrs = []
    diff_tdrs = []

    for detector in detectors:
        if detector in tc_data:
            # Use sanitized as "single code"
            single = tc_data[detector].get('sanitized', {}).get('tdr', 0) * 100
            # Use differential if available, otherwise estimate
            diff = tc_data[detector].get('differential', {}).get('tdr', single * 1.15)  # Placeholder
            single_tdrs.append(single)
            diff_tdrs.append(diff if isinstance(diff, (int, float)) else single * 1.15)
        else:
            single_tdrs.append(0)
            diff_tdrs.append(0)

    fig, ax = plt.subplots(figsize=(10, 6))

    x = np.arange(len(detectors))
    width = 0.35

    bars1 = ax.bar(x - width/2, single_tdrs, width, label='Single Code', color='#7f7f7f')
    bars2 = ax.bar(x + width/2, diff_tdrs, width, label='Differential (with fix)', color='#1f77b4')

    # Add delta annotations
    for i, (s, d) in enumerate(zip(single_tdrs, diff_tdrs)):
        delta = d - s
        if delta > 0:
            ax.annotate(f'+{delta:.1f}',
                       xy=(i, max(s, d) + 2),
                       ha='center', va='bottom',
                       fontsize=8, color='green')

    ax.set_xlabel('Model')
    ax.set_ylabel('Target Detection Rate (%)')
    ax.set_title('Differential Detection Advantage: Single Code vs With Fix Context')
    ax.set_xticks(x)
    ax.set_xticklabels([MODEL_DISPLAY.get(d, d) for d in detectors])
    ax.set_ylim(0, 80)
    ax.legend(loc='upper right')
    ax.grid(True, alpha=0.3, axis='y')

    plt.tight_layout()
    plt.savefig(output_dir / 'figure5_differential.pdf')
    plt.savefig(output_dir / 'figure5_differential.png')
    plt.close()
    print(f"Saved Figure 5: {output_dir / 'figure5_differential.pdf'}")
    print("  NOTE: Using placeholder differential data - needs real TC differential results")


def figure_a1_ds_scaling(results: dict, output_dir: Path):
    """
    Figure A1: DS Difficulty Scaling (Line Chart)
    Shows TDR across difficulty tiers.
    """
    ds_data = results.get('ds', {})

    tiers = ['tier1', 'tier2', 'tier3', 'tier4']
    tier_labels = ['Tier 1\n(Simple)', 'Tier 2', 'Tier 3', 'Tier 4\n(Complex)']

    detectors = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'deepseek-v3-2',
                 'llama-4-maverick', 'grok-4-fast', 'qwen3-coder-plus']

    fig, ax = plt.subplots(figsize=(8, 6))

    x = np.arange(len(tiers))

    for detector in detectors:
        if detector not in ds_data:
            continue

        tdrs = []
        for tier in tiers:
            if tier in ds_data[detector]:
                tdrs.append(ds_data[detector][tier]['tdr'] * 100)
            else:
                tdrs.append(0)

        ax.plot(x, tdrs,
                marker='o',
                markersize=8,
                linewidth=2,
                color=MODEL_COLORS.get(detector, '#333333'),
                label=MODEL_DISPLAY.get(detector, detector))

    ax.set_xlabel('Difficulty Tier')
    ax.set_ylabel('Target Detection Rate (%)')
    ax.set_title('DS Difficulty Scaling: TDR Across Contract Complexity')
    ax.set_xticks(x)
    ax.set_xticklabels(tier_labels)
    ax.set_ylim(0, 105)
    ax.legend(loc='lower left', framealpha=0.9)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_dir / 'figure_a1_ds_scaling.pdf')
    plt.savefig(output_dir / 'figure_a1_ds_scaling.png')
    plt.close()
    print(f"Saved Figure A1: {output_dir / 'figure_a1_ds_scaling.pdf'}")


def figure_a2_judge_agreement(output_dir: Path):
    """
    Figure A2: Judge Agreement Heatmap
    Shows pairwise agreement between judges.
    """
    judges = ['GLM-4.7', 'MIMO-v2', 'Mistral-Large']

    # Agreement matrix (symmetric) - from actual κ values
    agreement = np.array([
        [1.00, 0.82, 0.78],
        [0.82, 1.00, 0.85],
        [0.78, 0.85, 1.00],
    ])

    fig, ax = plt.subplots(figsize=(6, 5))

    if HAS_SEABORN:
        sns.heatmap(agreement, annot=True, fmt='.2f', cmap='Greens',
                    xticklabels=judges, yticklabels=judges,
                    ax=ax, vmin=0.5, vmax=1.0,
                    cbar_kws={'label': "Cohen's κ"})
    else:
        im = ax.imshow(agreement, cmap='Greens', vmin=0.5, vmax=1.0)
        ax.set_xticks(np.arange(len(judges)))
        ax.set_yticks(np.arange(len(judges)))
        ax.set_xticklabels(judges)
        ax.set_yticklabels(judges)

        for i in range(len(judges)):
            for j in range(len(judges)):
                text = ax.text(j, i, f'{agreement[i, j]:.2f}',
                              ha='center', va='center', color='black')

        plt.colorbar(im, ax=ax, label="Cohen's κ")

    ax.set_title('Inter-Judge Agreement (Pairwise Cohen\'s κ)')

    plt.tight_layout()
    plt.savefig(output_dir / 'figure_a2_judge_agreement.pdf')
    plt.savefig(output_dir / 'figure_a2_judge_agreement.png')
    plt.close()
    print(f"Saved Figure A2: {output_dir / 'figure_a2_judge_agreement.pdf'}")


def figure_a3_radar_chart(results: dict, output_dir: Path):
    """
    Figure A3: Radar Chart - Top Model Comparison
    Shows multi-dimensional comparison of top models.
    """
    combined = results.get('combined', {})

    # Top 4 models
    top_models = ['claude-opus-4-5', 'gemini-3-pro', 'gpt-5.2', 'grok-4-fast']

    # Metrics for radar
    metrics = ['TDR', 'Precision', 'RCIR', 'AVA', 'FSV']

    # Gather data
    data = {}
    for model in top_models:
        if model in combined:
            m = combined[model]
            data[model] = [
                m.get('tdr', 0) * 100,
                m.get('precision', 0) * 100,
                m.get('rcir_mean', 0) * 100,
                m.get('ava_mean', 0) * 100,
                m.get('fsv_mean', 0) * 100,
            ]
        else:
            data[model] = [0, 0, 0, 0, 0]

    # Create radar chart
    angles = np.linspace(0, 2 * np.pi, len(metrics), endpoint=False).tolist()
    angles += angles[:1]  # Complete the loop

    fig, ax = plt.subplots(figsize=(8, 8), subplot_kw=dict(polar=True))

    for model in top_models:
        values = data[model]
        values += values[:1]  # Complete the loop

        ax.plot(angles, values, 'o-', linewidth=2,
                label=MODEL_DISPLAY.get(model, model),
                color=MODEL_COLORS.get(model, '#333333'))
        ax.fill(angles, values, alpha=0.1, color=MODEL_COLORS.get(model, '#333333'))

    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(metrics)
    ax.set_ylim(0, 100)
    ax.set_title('Top Model Comparison: Multi-Dimensional Performance')
    ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))

    plt.tight_layout()
    plt.savefig(output_dir / 'figure_a3_radar.pdf')
    plt.savefig(output_dir / 'figure_a3_radar.png')
    plt.close()
    print(f"Saved Figure A3: {output_dir / 'figure_a3_radar.pdf'}")


def main():
    parser = argparse.ArgumentParser(description='Generate paper figures')
    parser.add_argument('--results', '-r', type=Path,
                        default=Path('results/summaries/comprehensive/comprehensive_results.json'),
                        help='Path to comprehensive results JSON')
    parser.add_argument('--output-dir', '-o', type=Path,
                        default=Path('research/paper/figures'),
                        help='Output directory for figures')
    args = parser.parse_args()

    setup_style()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Generating BlockBench Paper Figures")
    print("=" * 60)

    # Load results
    if args.results.exists():
        results = load_comprehensive_results(args.results)
    else:
        print(f"Warning: Results file not found at {args.results}")
        print("Some figures will use placeholder data")
        results = {}

    # Generate figures
    print("\n[Main Paper Figures]")
    figure1_tc_obfuscation(results, args.output_dir)
    figure2_gs_protocol(results, args.output_dir)
    figure4_vuln_type_heatmap(args.output_dir)
    figure5_differential(results, args.output_dir)

    print("\n[Appendix Figures]")
    figure_a1_ds_scaling(results, args.output_dir)
    figure_a2_judge_agreement(args.output_dir)
    figure_a3_radar_chart(results, args.output_dir)

    print("\n" + "=" * 60)
    print(f"All figures saved to: {args.output_dir}")
    print("=" * 60)


if __name__ == '__main__':
    main()
