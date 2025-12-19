#!/usr/bin/env python3
"""
Generate elegant, publication-quality visualizations.
Focus: Clean bar charts, line graphs, and SUI comparisons with model branding.
"""

import json
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from pathlib import Path

# Model color scheme - vibrant and distinctive
MODEL_COLORS = {
    'claude_opus_4.5': '#8B5CF6',        # Purple
    'gemini_3_pro_preview': '#10B981',   # Green
    'gpt-5.2': '#3B82F6',                # Blue
    'deepseek_v3.2': '#EC4899',          # Pink
    'llama_3.1_405b': '#F59E0B',         # Orange
    'grok_4_fast': '#6366F1',            # Indigo
}

MODEL_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'deepseek_v3.2': 'DeepSeek V3.2',
    'llama_3.1_405b': 'Llama 3.1 405B',
    'grok_4_fast': 'Grok 4 Fast',
}

# Model short names for compact display
MODEL_SHORT = {
    'claude_opus_4.5': 'Claude',
    'gemini_3_pro_preview': 'Gemini',
    'gpt-5.2': 'GPT-5.2',
    'deepseek_v3.2': 'DeepSeek',
    'llama_3.1_405b': 'Llama',
    'grok_4_fast': 'Grok',
}

# Model logos/icons (using emoji-style representations)
MODEL_ICONS = {
    'claude_opus_4.5': '◆',      # Diamond for Claude
    'gemini_3_pro_preview': '★', # Star for Gemini
    'gpt-5.2': '●',              # Circle for GPT
    'deepseek_v3.2': '▲',        # Triangle for DeepSeek
    'llama_3.1_405b': '■',       # Square for Llama
    'grok_4_fast': '✦',          # Sparkle for Grok
}

TRANSFORMATION_NAMES = {
    'sanitized': 'Sanitized',
    'chameleon_medical': 'Medical',
    'shapeshifter_l3_medium': 'Shapeshifter',
    'hydra_restructure': 'Hydra',
    'nocomments': 'No-Comments',
    'nocomments_original': 'Original',
}

print("="*70)
print("ELEGANT VISUALIZATION GENERATOR")
print("="*70)

# Load data
print("\n📊 Loading data...")
with open('TRANSFORMATION_ANALYSIS.json') as f:
    transformation_data = json.load(f)

with open('GS_PERFORMANCE_ANALYSIS.json') as f:
    gs_data = json.load(f)

prompt_type_data = {}
for model in MODEL_COLORS.keys():
    metrics_file = Path('judge_output') / model / 'aggregated_metrics.json'
    if metrics_file.exists():
        with open(metrics_file) as f:
            prompt_type_data[model] = json.load(f)

print(f"✓ Loaded data for {len(transformation_data)} models")

# =============================================================================
# CHART 5: SUI Index Ranking - Elegant Horizontal Bar Chart
# =============================================================================
print("\n📊 Generating Chart 5: SUI Index Ranking...")

# Collect SUI scores from GS data
sui_data = []
for model in MODEL_COLORS.keys():
    if model in gs_data:
        # Calculate SUI if not directly available
        # For now, use a composite score
        data = gs_data[model]
        # Simple SUI calculation: weighted average
        sui = (data['tdr'] * 0.4 + data['finding_precision'] * 0.4 +
               data['accuracy'] * 0.2)

        sui_data.append({
            'model': MODEL_NAMES[model],
            'model_id': model,
            'short_name': MODEL_SHORT[model],
            'icon': MODEL_ICONS[model],
            'sui': sui,
            'tdr': data['tdr'],
            'precision': data['finding_precision'],
            'accuracy': data['accuracy'],
        })

# Sort by SUI score (descending)
sui_data.sort(key=lambda x: x['sui'], reverse=True)
df = pd.DataFrame(sui_data)

# Create horizontal bar chart
fig = go.Figure()

fig.add_trace(go.Bar(
    y=[f"{row['icon']} {row['model']}" for _, row in df.iterrows()],
    x=df['sui'],
    orientation='h',
    marker=dict(
        color=[MODEL_COLORS[row['model_id']] for _, row in df.iterrows()],
        line=dict(color='white', width=2),
    ),
    text=[f"{val:.1%}" for val in df['sui']],
    textposition='outside',
    textfont=dict(size=14, color='black', family='Arial Black'),
    hovertemplate=(
        '<b>%{y}</b><br>'
        'SUI Score: %{x:.1%}<br>'
        '<extra></extra>'
    ),
))

# Add rank medals/badges
for i, (_, row) in enumerate(df.iterrows()):
    rank = i + 1
    if rank == 1:
        medal = '🥇'
    elif rank == 2:
        medal = '🥈'
    elif rank == 3:
        medal = '🥉'
    else:
        medal = f'{rank}.'

    fig.add_annotation(
        x=-0.01,
        y=i,
        text=medal,
        showarrow=False,
        xanchor='right',
        font=dict(size=16),
    )

fig.update_layout(
    title={
        'text': '<b>Security Understanding Index (SUI) Rankings</b><br><sub>GS Dataset Performance</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>SUI Score</b>',
        tickformat='.0%',
        range=[0, max(df['sui']) * 1.15],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    yaxis=dict(
        showgrid=False,
        autorange='reversed',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=900,
    height=500,
    font=dict(size=13, family='Arial'),
    margin=dict(l=200, r=100, t=100, b=80),
    showlegend=False,
)

fig.write_html('charts/5_sui_ranking.html')
fig.write_image('charts/5_sui_ranking.png', width=900, height=500, scale=2)
print("✓ Saved: charts/5_sui_ranking.html & .png")

# =============================================================================
# CHART 6: Performance Across Transformations - Line Graph
# =============================================================================
print("\n📊 Generating Chart 6: Performance Across Transformations...")

# Prepare data for line graph
transformations_ordered = ['nocomments_original', 'chameleon_medical', 'shapeshifter_l3_medium',
                          'hydra_restructure', 'nocomments', 'sanitized']

fig = go.Figure()

for model in MODEL_COLORS.keys():
    if model not in transformation_data:
        continue

    tdrs = []
    precisions = []

    for trans in transformations_ordered:
        if trans in transformation_data[model]:
            tdrs.append(transformation_data[model][trans]['tdr'])
            precisions.append(transformation_data[model][trans]['finding_precision'])
        else:
            tdrs.append(None)
            precisions.append(None)

    # TDR line
    fig.add_trace(go.Scatter(
        x=[TRANSFORMATION_NAMES[t] for t in transformations_ordered],
        y=tdrs,
        mode='lines+markers',
        name=f"{MODEL_ICONS[model]} {MODEL_SHORT[model]}",
        line=dict(color=MODEL_COLORS[model], width=3),
        marker=dict(
            size=10,
            color=MODEL_COLORS[model],
            line=dict(width=2, color='white'),
        ),
        hovertemplate=(
            f'<b>{MODEL_ICONS[model]} {MODEL_NAMES[model]}</b><br>'
            '%{x}<br>'
            'TDR: %{y:.1%}'
            '<extra></extra>'
        ),
    ))

fig.update_layout(
    title={
        'text': '<b>Target Detection Rate Across Transformations</b><br><sub>Easiest → Hardest (Left to Right)</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>Code Transformation</b>',
        tickangle=-30,
        showgrid=False,
    ),
    yaxis=dict(
        title='<b>Target Detection Rate (TDR)</b>',
        tickformat='.0%',
        range=[0, 1],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
        zeroline=True,
        zerolinecolor='rgba(0,0,0,0.2)',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=1100,
    height=600,
    font=dict(size=13, family='Arial'),
    legend=dict(
        title='<b>Models</b>',
        orientation='v',
        yanchor='top',
        y=0.98,
        xanchor='right',
        x=0.98,
        bgcolor='rgba(255,255,255,0.9)',
        bordercolor='rgba(0,0,0,0.1)',
        borderwidth=1,
    ),
    hovermode='x unified',
)

# Add annotation for sanitized drop
fig.add_annotation(
    x='Sanitized',
    y=0.05,
    text='<b>⚠️ Sanitization Collapse</b><br>All models drop significantly',
    showarrow=True,
    arrowhead=2,
    arrowcolor='rgba(220,38,38,0.6)',
    font=dict(size=11, color='rgba(220,38,38,0.8)'),
    bgcolor='rgba(254,226,226,0.8)',
    borderpad=8,
    ax=-80,
    ay=-80,
)

fig.write_html('charts/6_transformation_lines.html')
fig.write_image('charts/6_transformation_lines.png', width=1100, height=600, scale=2)
print("✓ Saved: charts/6_transformation_lines.html & .png")

# =============================================================================
# CHART 7: Prompt Type Impact - Line Graph
# =============================================================================
print("\n📊 Generating Chart 7: Prompt Type Impact...")

prompt_types = ['direct', 'naturalistic', 'adversarial']
prompt_labels = ['Direct', 'Naturalistic', 'Adversarial']

fig = go.Figure()

for model in MODEL_COLORS.keys():
    if model not in prompt_type_data:
        continue

    if 'by_prompt_type' not in prompt_type_data[model]:
        continue

    tdrs = []
    for ptype in prompt_types:
        if ptype in prompt_type_data[model]['by_prompt_type']:
            tdr = prompt_type_data[model]['by_prompt_type'][ptype]['target_finding']['target_detection_rate']
            tdrs.append(tdr)
        else:
            tdrs.append(None)

    # Only plot if we have data for at least 2 prompt types
    if sum(1 for t in tdrs if t is not None) >= 2:
        fig.add_trace(go.Scatter(
            x=prompt_labels,
            y=tdrs,
            mode='lines+markers',
            name=f"{MODEL_ICONS[model]} {MODEL_SHORT[model]}",
            line=dict(color=MODEL_COLORS[model], width=3),
            marker=dict(
                size=12,
                color=MODEL_COLORS[model],
                line=dict(width=2, color='white'),
            ),
            hovertemplate=(
                f'<b>{MODEL_ICONS[model]} {MODEL_NAMES[model]}</b><br>'
                '%{x} Prompt<br>'
                'TDR: %{y:.1%}'
                '<extra></extra>'
            ),
        ))

fig.update_layout(
    title={
        'text': '<b>Prompt Strategy Impact on Target Detection</b><br><sub>5 GS Samples Evaluated with 3 Prompt Types</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>Prompt Type</b>',
        showgrid=False,
    ),
    yaxis=dict(
        title='<b>Target Detection Rate (TDR)</b>',
        tickformat='.0%',
        range=[0, 0.5],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=900,
    height=600,
    font=dict(size=13, family='Arial'),
    legend=dict(
        title='<b>Models</b>',
        orientation='v',
        yanchor='top',
        y=0.98,
        xanchor='right',
        x=0.98,
        bgcolor='rgba(255,255,255,0.9)',
        bordercolor='rgba(0,0,0,0.1)',
        borderwidth=1,
    ),
    hovermode='x unified',
)

# Add annotations for insights
fig.add_annotation(
    x='Adversarial',
    y=0.42,
    text='<b>Gemini & GPT-5.2:</b><br>Sycophancy resistant',
    showarrow=True,
    arrowhead=2,
    font=dict(size=10, color='rgba(34,197,94,0.8)'),
    bgcolor='rgba(220,252,231,0.8)',
    borderpad=6,
    ax=60,
    ay=-40,
)

fig.write_html('charts/7_prompt_type_lines.html')
fig.write_image('charts/7_prompt_type_lines.png', width=900, height=600, scale=2)
print("✓ Saved: charts/7_prompt_type_lines.html & .png")

# =============================================================================
# CHART 8: SUI Components Breakdown - Stacked Horizontal Bar
# =============================================================================
print("\n📊 Generating Chart 8: SUI Components Breakdown...")

# Prepare data for stacked bar
components_data = []

for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue

    data = gs_data[model]

    # Calculate component contributions (normalized)
    components_data.append({
        'model': MODEL_NAMES[model],
        'model_id': model,
        'icon': MODEL_ICONS[model],
        'TDR': data['tdr'],
        'Precision': data['finding_precision'],
        'Accuracy': data['accuracy'],
    })

# Sort by total score
components_data.sort(key=lambda x: x['TDR'] + x['Precision'] + x['Accuracy'], reverse=True)

df = pd.DataFrame(components_data)

fig = go.Figure()

# Add each component as a stacked bar
component_colors = {
    'TDR': '#3B82F6',
    'Precision': '#10B981',
    'Accuracy': '#F59E0B',
}

for component in ['Accuracy', 'TDR', 'Precision']:
    fig.add_trace(go.Bar(
        y=[f"{row['icon']} {row['model']}" for _, row in df.iterrows()],
        x=df[component],
        name=component,
        orientation='h',
        marker=dict(
            color=component_colors[component],
            line=dict(color='white', width=1),
        ),
        text=[f"{val:.0%}" if val > 0.05 else "" for val in df[component]],
        textposition='inside',
        textfont=dict(color='white', size=11),
        hovertemplate=(
            '<b>%{fullData.name}</b><br>'
            '%{x:.1%}'
            '<extra></extra>'
        ),
    ))

fig.update_layout(
    title={
        'text': '<b>Model Performance Components</b><br><sub>GS Dataset - Breakdown by Metric</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>Component Scores (Higher = Better)</b>',
        tickformat='.0%',
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    yaxis=dict(
        showgrid=False,
        autorange='reversed',
    ),
    barmode='stack',
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=1000,
    height=500,
    font=dict(size=13, family='Arial'),
    legend=dict(
        title='<b>Metrics</b>',
        orientation='h',
        yanchor='bottom',
        y=1.02,
        xanchor='center',
        x=0.5,
    ),
    margin=dict(l=200, r=50, t=120, b=80),
)

fig.write_html('charts/8_sui_components.html')
fig.write_image('charts/8_sui_components.png', width=1000, height=500, scale=2)
print("✓ Saved: charts/8_sui_components.html & .png")

# =============================================================================
# CHART 9: Finding Quality Matrix - Grouped Bar Chart
# =============================================================================
print("\n📊 Generating Chart 9: Finding Quality Matrix...")

# Prepare data
quality_data = []

for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue

    data = gs_data[model]

    quality_data.append({
        'model': MODEL_SHORT[model],
        'model_full': MODEL_NAMES[model],
        'model_id': model,
        'icon': MODEL_ICONS[model],
        'Finding Precision': data['finding_precision'],
        'Lucky Guess Rate': data['lucky_rate'],
        'Avg Findings': data['avg_findings'] / 10,  # Normalize to 0-1 scale
    })

# Sort by precision
quality_data.sort(key=lambda x: x['Finding Precision'], reverse=True)
df = pd.DataFrame(quality_data)

fig = go.Figure()

metrics = ['Finding Precision', 'Avg Findings']
colors_qual = ['#10B981', '#3B82F6']

for i, metric in enumerate(metrics):
    fig.add_trace(go.Bar(
        x=[f"{row['icon']} {row['model']}" for _, row in df.iterrows()],
        y=df[metric],
        name=metric,
        marker=dict(
            color=colors_qual[i],
            line=dict(color='white', width=2),
        ),
        text=[f"{val:.1%}" if metric == 'Finding Precision' else f"{val*10:.1f}" for val in df[metric]],
        textposition='outside',
        textfont=dict(size=11, color='black'),
        hovertemplate=(
            '<b>%{fullData.name}</b><br>'
            '%{y:.1%}' if metric != 'Avg Findings' else 'Avg: %{y:.1f}'
            '<extra></extra>'
        ),
    ))

# Add lucky guess rate as markers
fig.add_trace(go.Scatter(
    x=[f"{row['icon']} {row['model']}" for _, row in df.iterrows()],
    y=df['Lucky Guess Rate'],
    mode='markers+text',
    name='Lucky Guess Rate',
    marker=dict(
        size=15,
        color='#EF4444',
        symbol='x',
        line=dict(width=2, color='white'),
    ),
    text=[f"{val:.0%}" for val in df['Lucky Guess Rate']],
    textposition='top center',
    textfont=dict(size=10, color='#DC2626'),
    hovertemplate=(
        '<b>Lucky Guess Rate</b><br>'
        '%{y:.1%}'
        '<extra></extra>'
    ),
))

fig.update_layout(
    title={
        'text': '<b>Finding Quality Metrics Comparison</b><br><sub>Precision, Volume, and Lucky Guesses</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>Model</b>',
        showgrid=False,
    ),
    yaxis=dict(
        title='<b>Score</b>',
        tickformat='.0%',
        range=[0, 1.1],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    barmode='group',
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=1000,
    height=600,
    font=dict(size=13, family='Arial'),
    legend=dict(
        title='<b>Metrics</b>',
        orientation='h',
        yanchor='bottom',
        y=1.02,
        xanchor='center',
        x=0.5,
    ),
    margin=dict(t=120),
)

fig.write_html('charts/9_finding_quality.html')
fig.write_image('charts/9_finding_quality.png', width=1000, height=600, scale=2)
print("✓ Saved: charts/9_finding_quality.html & .png")

# =============================================================================
# CHART 10: Model Efficiency - Scatter with Trendline
# =============================================================================
print("\n📊 Generating Chart 10: Model Efficiency...")

# Prepare data
efficiency_data = []

for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue

    data = gs_data[model]

    # Calculate efficiency: valid findings per total findings
    efficiency = data['finding_precision']
    volume = data['avg_findings']
    value = data['tdr']  # True value delivered

    efficiency_data.append({
        'model': MODEL_SHORT[model],
        'model_full': MODEL_NAMES[model],
        'model_id': model,
        'icon': MODEL_ICONS[model],
        'efficiency': efficiency,
        'volume': volume,
        'value': value,
    })

df = pd.DataFrame(efficiency_data)

fig = go.Figure()

# Add scatter points
for _, row in df.iterrows():
    fig.add_trace(go.Scatter(
        x=[row['volume']],
        y=[row['efficiency']],
        mode='markers+text',
        marker=dict(
            size=row['value'] * 400,  # Size by TDR
            color=MODEL_COLORS[row['model_id']],
            line=dict(width=2, color='white'),
            opacity=0.8,
        ),
        text=f"{row['icon']}<br>{row['model']}",
        textposition='top center',
        textfont=dict(size=11, color='black'),
        name=row['model_full'],
        hovertemplate=(
            f"<b>{row['icon']} {row['model_full']}</b><br>"
            f"Avg Findings: {row['volume']:.1f}<br>"
            f"Precision: {row['efficiency']:.1%}<br>"
            f"TDR: {row['value']:.1%}"
            '<extra></extra>'
        ),
    ))

# Add quadrant lines
avg_volume = df['volume'].mean()
avg_efficiency = df['efficiency'].mean()

fig.add_hline(y=avg_efficiency, line_dash='dash', line_color='rgba(0,0,0,0.2)',
              annotation_text=f'Avg Precision ({avg_efficiency:.1%})', annotation_position='left')
fig.add_vline(x=avg_volume, line_dash='dash', line_color='rgba(0,0,0,0.2)',
              annotation_text=f'Avg Volume ({avg_volume:.1f})', annotation_position='top')

# Add quadrant labels
fig.add_annotation(x=2, y=0.28, text='<b>Efficient & Precise</b><br><i>Low volume, high quality</i>',
                   showarrow=False, font=dict(size=10, color='rgba(34,197,94,0.6)'),
                   bgcolor='rgba(220,252,231,0.5)', borderpad=8)

fig.add_annotation(x=5, y=0.05, text='<b>High Volume, Low Quality</b><br><i>Many invalid findings</i>',
                   showarrow=False, font=dict(size=10, color='rgba(220,38,38,0.6)'),
                   bgcolor='rgba(254,226,226,0.5)', borderpad=8)

fig.update_layout(
    title={
        'text': '<b>Model Efficiency: Quality vs Quantity</b><br><sub>Bubble size = TDR (Target Detection Rate)</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 22, 'family': 'Arial'}
    },
    xaxis=dict(
        title='<b>Average Findings per Sample</b>',
        range=[0, max(df['volume']) * 1.2],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    yaxis=dict(
        title='<b>Finding Precision</b>',
        tickformat='.0%',
        range=[0, max(df['efficiency']) * 1.2],
        gridcolor='rgba(0,0,0,0.08)',
        showgrid=True,
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=900,
    height=700,
    font=dict(size=13, family='Arial'),
    showlegend=False,
)

fig.write_html('charts/10_model_efficiency.html')
fig.write_image('charts/10_model_efficiency.png', width=900, height=700, scale=2)
print("✓ Saved: charts/10_model_efficiency.html & .png")

print("\n" + "="*70)
print("✅ ALL ELEGANT CHARTS GENERATED SUCCESSFULLY!")
print("="*70)
print("\n📁 Output location: charts/")
print("\n📊 Generated elegant charts:")
print("  5. SUI Index Ranking (horizontal bar with medals)")
print("  6. Performance Across Transformations (line graph)")
print("  7. Prompt Type Impact (line graph)")
print("  8. SUI Components Breakdown (stacked bar)")
print("  9. Finding Quality Matrix (grouped bar)")
print(" 10. Model Efficiency (scatter with bubbles)")
print("\n💡 Features:")
print("  ✓ Model icons/logos on all charts")
print("  ✓ Clean, minimal design")
print("  ✓ Publication-quality typography")
print("  ✓ Colorblind-friendly palettes")
print("  ✓ Interactive tooltips")
print("="*70)
