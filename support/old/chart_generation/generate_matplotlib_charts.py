#!/usr/bin/env python3
"""
Generate publication-ready charts using matplotlib with proper font sizes.
"""

import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path

# Set publication-quality defaults
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['Arial', 'DejaVu Sans']
plt.rcParams['font.size'] = 12
plt.rcParams['axes.linewidth'] = 1.5
plt.rcParams['xtick.major.width'] = 1.5
plt.rcParams['ytick.major.width'] = 1.5

# Model colors (muted, professional)
MODEL_COLORS = {
    'claude_opus_4.5': '#2E5090',
    'gemini_3_pro_preview': '#2D7A3E',
    'gpt-5.2': '#8B4513',
    'deepseek_v3.2': '#6B4C9A',
    'llama_3.1_405b': '#C45911',
    'grok_4_fast': '#4B6B8C',
}

MODEL_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'deepseek_v3.2': 'DeepSeek V3.2',
    'llama_3.1_405b': 'Llama 3.1 405B',
    'grok_4_fast': 'Grok 4',
}

print("="*70)
print("MATPLOTLIB CHART GENERATOR")
print("="*70)

# Load data
print("\n📊 Loading data...")
with open('GS_PERFORMANCE_ANALYSIS.json') as f:
    gs_data = json.load(f)

print(f"✓ Loaded data for {len(gs_data)} models")

# =============================================================================
# FIGURE 1: Model Performance on Gold Standard Dataset
# =============================================================================
print("\n📊 Generating Figure 1: Model Performance (Gold Standard)...")

# Calculate SUI for each model
sui_data = []
for model_id in MODEL_COLORS.keys():
    if model_id in gs_data:
        data = gs_data[model_id]
        # SUI = weighted average of TDR (40%), Finding Precision (40%), Accuracy (20%)
        sui = (data['tdr'] * 0.4 + data['finding_precision'] * 0.4 + data['accuracy'] * 0.2)
        sui_data.append({
            'model': MODEL_NAMES[model_id],
            'model_id': model_id,
            'sui': sui,
            'tdr': data['tdr'],
            'precision': data['finding_precision'],
            'accuracy': data['accuracy'],
        })

# Sort by SUI
sui_data.sort(key=lambda x: x['sui'], reverse=True)

# Create figure
fig, ax = plt.subplots(figsize=(10, 6))

models = [d['model'] for d in sui_data]
sui_scores = [d['sui'] * 100 for d in sui_data]  # Convert to percentage
colors = [MODEL_COLORS[d['model_id']] for d in sui_data]

# Horizontal bar chart
bars = ax.barh(models, sui_scores, color=colors, edgecolor='black', linewidth=1.5)

# Add value labels
for i, (bar, score) in enumerate(zip(bars, sui_scores)):
    ax.text(score + 1, i, f'{score:.1f}%', va='center', fontsize=12, fontweight='bold')

ax.set_xlabel('Security Understanding Index (SUI)', fontsize=14, fontweight='bold')
ax.set_title('Model Performance on Gold Standard Dataset', fontsize=16, fontweight='bold', pad=20)
ax.set_xlim(0, max(sui_scores) * 1.15)
ax.grid(axis='x', alpha=0.3, linestyle='--', linewidth=1)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('charts/matplotlib_fig1_performance.png', dpi=300, bbox_inches='tight')
plt.savefig('charts/matplotlib_fig1_performance.pdf', bbox_inches='tight')
plt.close()

print("✓ Saved: charts/matplotlib_fig1_performance.{png,pdf}")

# =============================================================================
# FIGURE 2: TDR vs Lucky Guess Rate
# =============================================================================
print("\n📊 Generating Figure 2: TDR vs Lucky Guess Rate...")

fig, ax = plt.subplots(figsize=(10, 8))

for model_id in MODEL_COLORS.keys():
    if model_id not in gs_data:
        continue

    data = gs_data[model_id]
    tdr = data['tdr'] * 100
    lucky_rate = data['lucky_rate'] * 100
    precision = data['finding_precision']

    # Scatter point with size based on precision
    size = precision * 500 + 100
    ax.scatter(tdr, lucky_rate, s=size, c=MODEL_COLORS[model_id],
               alpha=0.7, edgecolors='black', linewidth=2, zorder=3)

    # Label
    ax.annotate(MODEL_NAMES[model_id],
                xy=(tdr, lucky_rate),
                xytext=(0, 15),
                textcoords='offset points',
                ha='center',
                fontsize=11,
                fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='white',
                         edgecolor='gray', alpha=0.8))

# Reference lines
ax.axhline(y=50, color='gray', linestyle='--', linewidth=1.5, alpha=0.5, zorder=1)
ax.axvline(x=20, color='gray', linestyle='--', linewidth=1.5, alpha=0.5, zorder=1)

# Add quadrant labels
ax.text(5, 85, 'Lucky Guesser\n(High false positives)',
        fontsize=11, color='#8B0000', alpha=0.6, ha='center',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='#FFE4E4', alpha=0.5))

ax.text(25, 15, 'True Detector\n(Correct findings)',
        fontsize=11, color='#006400', alpha=0.6, ha='center',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='#E4FFE4', alpha=0.5))

ax.set_xlabel('Target Detection Rate (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Lucky Guess Rate (%)', fontsize=14, fontweight='bold')
ax.set_title('Target Detection Rate vs Lucky Guess Rate\n(Bubble size = Finding Precision)',
             fontsize=16, fontweight='bold', pad=20)

ax.set_xlim(-2, max([gs_data[m]['tdr']*100 for m in gs_data]) * 1.2)
ax.set_ylim(-5, 105)

ax.grid(True, alpha=0.3, linestyle='--', linewidth=1)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('charts/matplotlib_fig2_lucky_guess.png', dpi=300, bbox_inches='tight')
plt.savefig('charts/matplotlib_fig2_lucky_guess.pdf', bbox_inches='tight')
plt.close()

print("✓ Saved: charts/matplotlib_fig2_lucky_guess.{png,pdf}")

print("\n" + "="*70)
print("✅ MATPLOTLIB CHARTS GENERATED!")
print("="*70)
print("\n📁 Output location: charts/")
print("\n📊 Generated figures:")
print("  Figure 1: Model Performance on Gold Standard Dataset (SUI)")
print("  Figure 2: TDR vs Lucky Guess Rate")
print("\n📄 Formats:")
print("  ✓ PNG (300 DPI, publication quality)")
print("  ✓ PDF (vector graphics)")
print("\n✨ Features:")
print("  ✓ Large, readable fonts (12-16pt)")
print("  ✓ Professional matplotlib styling")
print("  ✓ Thick axis lines and borders")
print("  ✓ Proper sizing for research papers")
print("="*70)
