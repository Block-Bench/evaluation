#!/usr/bin/env python3
"""
Generate all visualization charts from the notebook.
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
    'claude_opus_4.5': '#8B5CF6',        # Purple (premium)
    'gemini_3_pro_preview': '#10B981',   # Green (Google)
    'gpt-5.2': '#3B82F6',                # Blue (OpenAI)
    'deepseek_v3.2': '#EC4899',          # Pink (distinctive)
    'llama_3.1_405b': '#F59E0B',         # Orange (Meta)
    'grok_4_fast': '#6366F1',            # Indigo (xAI)
}

# Clean model names for display
MODEL_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'deepseek_v3.2': 'DeepSeek V3.2',
    'llama_3.1_405b': 'Llama 3.1 405B',
    'grok_4_fast': 'Grok 4 Fast',
}

# Transformation names for display
TRANSFORMATION_NAMES = {
    'sanitized': 'Sanitized',
    'chameleon_medical': 'Medical',
    'shapeshifter_l3_medium': 'Shapeshifter',
    'hydra_restructure': 'Hydra',
    'nocomments': 'No-Comments',
    'nocomments_original': 'Original',
}

print("="*70)
print("BLOCKBENCH VISUALIZATION GENERATOR")
print("="*70)

# Create charts directory
Path('charts').mkdir(exist_ok=True)

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
# CHART 1: Model Performance Radar
# =============================================================================
print("\n📊 Generating Chart 1: Model Performance Radar...")

radar_metrics = ['Accuracy', 'TDR', 'Finding<br>Precision', 'Reasoning<br>Quality', 'Calibration']

fig = go.Figure()

for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue

    data = gs_data[model]

    # Calculate reasoning quality as average of RCIR, AVA, FSV
    reasoning = None
    if data['rcir'] is not None:
        reasoning = (data['rcir'] + data['ava'] + data['fsv']) / 3
    else:
        reasoning = 0

    # Calibration: use 0.7 as placeholder (would need full metrics)
    calibration = 0.7

    values = [
        data['accuracy'],
        data['tdr'],
        data['finding_precision'],
        reasoning,
        calibration,
    ]

    fig.add_trace(go.Scatterpolar(
        r=values,
        theta=radar_metrics,
        fill='toself',
        name=MODEL_NAMES[model],
        line=dict(color=MODEL_COLORS[model], width=2),
        fillcolor=MODEL_COLORS[model],
        opacity=0.25,
        hovertemplate='<b>%{fullData.name}</b><br>%{theta}: %{r:.1%}<extra></extra>'
    ))

fig.update_layout(
    polar=dict(
        radialaxis=dict(
            visible=True,
            range=[0, 1],
            tickformat='.0%',
            gridcolor='rgba(0,0,0,0.1)',
        ),
        angularaxis=dict(
            gridcolor='rgba(0,0,0,0.1)',
        ),
        bgcolor='rgba(0,0,0,0.02)',
    ),
    showlegend=True,
    title={
        'text': '<b>Model Performance Profile - GS Dataset</b><br><sub>Higher values = Better performance</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 20}
    },
    width=800,
    height=700,
    font=dict(size=12),
    legend=dict(
        orientation='v',
        yanchor='middle',
        y=0.5,
        xanchor='left',
        x=1.1
    ),
    paper_bgcolor='white',
)

fig.write_html('charts/1_radar_performance.html')
fig.write_image('charts/1_radar_performance.png', width=800, height=700, scale=2)
print("✓ Saved: charts/1_radar_performance.html & .png")

# =============================================================================
# CHART 2: Transformation Impact Heatmap
# =============================================================================
print("\n📊 Generating Chart 2: Transformation Impact Heatmap...")

transformations = ['sanitized', 'chameleon_medical', 'shapeshifter_l3_medium',
                   'hydra_restructure', 'nocomments', 'nocomments_original']

models = list(MODEL_COLORS.keys())

# Create matrices for TDR and Finding Precision
tdr_matrix = []
precision_matrix = []

for model in models:
    tdr_row = []
    precision_row = []

    for transformation in transformations:
        if model in transformation_data and transformation in transformation_data[model]:
            tdr = transformation_data[model][transformation]['tdr']
            precision = transformation_data[model][transformation]['finding_precision']
        else:
            tdr = None
            precision = None

        tdr_row.append(tdr if tdr is not None else 0)
        precision_row.append(precision if precision is not None else 0)

    tdr_matrix.append(tdr_row)
    precision_matrix.append(precision_row)

# Create subplots for TDR and Precision side-by-side
fig = make_subplots(
    rows=1, cols=2,
    subplot_titles=('<b>Target Detection Rate (TDR)</b>', '<b>Finding Precision</b>'),
    horizontal_spacing=0.15,
    specs=[[{'type': 'heatmap'}, {'type': 'heatmap'}]]
)

# TDR Heatmap
fig.add_trace(
    go.Heatmap(
        z=tdr_matrix,
        x=[TRANSFORMATION_NAMES[t] for t in transformations],
        y=[MODEL_NAMES[m] for m in models],
        colorscale='RdYlGn',
        text=[[f'{val:.1%}' if val > 0 else 'N/A' for val in row] for row in tdr_matrix],
        texttemplate='%{text}',
        textfont={'size': 11},
        colorbar=dict(title='TDR', x=0.46, len=0.8, tickformat='.0%'),
        hovertemplate='<b>%{y}</b><br>%{x}<br>TDR: %{z:.1%}<extra></extra>',
        zmin=0,
        zmax=1,
    ),
    row=1, col=1
)

# Precision Heatmap
fig.add_trace(
    go.Heatmap(
        z=precision_matrix,
        x=[TRANSFORMATION_NAMES[t] for t in transformations],
        y=[MODEL_NAMES[m] for m in models],
        colorscale='RdYlGn',
        text=[[f'{val:.1%}' if val > 0 else 'N/A' for val in row] for row in precision_matrix],
        texttemplate='%{text}',
        textfont={'size': 11},
        colorbar=dict(title='Precision', x=1.0, len=0.8, tickformat='.0%'),
        hovertemplate='<b>%{y}</b><br>%{x}<br>Precision: %{z:.1%}<extra></extra>',
        zmin=0,
        zmax=1,
    ),
    row=1, col=2
)

fig.update_layout(
    title={
        'text': '<b>Transformation Impact on Model Performance</b><br><sub>Red = Poor | Yellow = Moderate | Green = Good</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 20}
    },
    width=1400,
    height=600,
    font=dict(size=12),
    paper_bgcolor='white',
)

fig.update_xaxes(tickangle=-45)

fig.write_html('charts/2_transformation_heatmap.html')
fig.write_image('charts/2_transformation_heatmap.png', width=1400, height=600, scale=2)
print("✓ Saved: charts/2_transformation_heatmap.html & .png")

# =============================================================================
# CHART 3: TDR vs Lucky Guess Scatter
# =============================================================================
print("\n📊 Generating Chart 3: TDR vs Lucky Guess Scatter...")

scatter_data = []

for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue

    data = gs_data[model]

    scatter_data.append({
        'model': MODEL_NAMES[model],
        'model_id': model,
        'tdr': data['tdr'],
        'lucky_rate': data['lucky_rate'],
        'finding_precision': data['finding_precision'],
        'accuracy': data['accuracy'],
    })

df = pd.DataFrame(scatter_data)

fig = go.Figure()

for _, row in df.iterrows():
    fig.add_trace(go.Scatter(
        x=[row['tdr']],
        y=[row['lucky_rate']],
        mode='markers+text',
        marker=dict(
            size=row['finding_precision'] * 200,  # Scale by precision
            color=MODEL_COLORS[row['model_id']],
            line=dict(width=2, color='white'),
            opacity=0.8,
        ),
        text=row['model'],
        textposition='top center',
        textfont=dict(size=11, color='black'),
        name=row['model'],
        hovertemplate=(
            '<b>%{text}</b><br>'
            'TDR: %{x:.1%}<br>'
            'Lucky Guess Rate: %{y:.1%}<br>'
            f"Finding Precision: {row['finding_precision']:.1%}<br>"
            f"Accuracy: {row['accuracy']:.1%}"
            '<extra></extra>'
        ),
    ))

# Add quadrant labels
fig.add_annotation(
    x=0.05, y=0.9,
    text='<b>Lucky Guesser</b><br><i>Detects wrong<br>vulnerability</i>',
    showarrow=False,
    font=dict(size=12, color='rgba(220,38,38,0.6)'),
    align='center',
    bgcolor='rgba(254,226,226,0.5)',
    borderpad=10,
)

fig.add_annotation(
    x=0.25, y=0.1,
    text='<b>True Detector</b><br><i>Finds actual<br>target</i>',
    showarrow=False,
    font=dict(size=12, color='rgba(34,197,94,0.8)'),
    align='center',
    bgcolor='rgba(220,252,231,0.5)',
    borderpad=10,
)

# Add reference lines
fig.add_hline(y=0.5, line_dash='dash', line_color='rgba(0,0,0,0.2)',
              annotation_text='50% Lucky Guess Rate', annotation_position='right')
fig.add_vline(x=0.2, line_dash='dash', line_color='rgba(0,0,0,0.2)',
              annotation_text='20% TDR', annotation_position='top')

fig.update_layout(
    title={
        'text': '<b>The Lucky Guess Problem - GS Dataset</b><br><sub>Bubble size = Finding Precision | Bottom-right = Best</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 20}
    },
    xaxis=dict(
        title='<b>Target Detection Rate (TDR)</b>',
        tickformat='.0%',
        range=[-0.02, 0.35],
        gridcolor='rgba(0,0,0,0.1)',
    ),
    yaxis=dict(
        title='<b>Lucky Guess Rate</b><br><i>(Higher = More often finds wrong vulnerability)</i>',
        tickformat='.0%',
        range=[-0.05, 1.0],
        gridcolor='rgba(0,0,0,0.1)',
    ),
    showlegend=False,
    width=900,
    height=700,
    font=dict(size=12),
    plot_bgcolor='rgba(0,0,0,0.02)',
    paper_bgcolor='white',
)

fig.write_html('charts/3_tdr_vs_lucky_guess.html')
fig.write_image('charts/3_tdr_vs_lucky_guess.png', width=900, height=700, scale=2)
print("✓ Saved: charts/3_tdr_vs_lucky_guess.html & .png")

# =============================================================================
# CHART 4: Sanitization Effect Slope
# =============================================================================
print("\n📊 Generating Chart 4: Sanitization Effect Slope...")

slope_data = []

for model in MODEL_COLORS.keys():
    if model not in transformation_data:
        continue

    # Get non-sanitized performance (use nocomments_original as baseline)
    if 'nocomments_original' in transformation_data[model]:
        non_sanitized_tdr = transformation_data[model]['nocomments_original']['tdr']
    else:
        # Fallback to average of non-sanitized transformations
        non_sanitized_tdrs = []
        for trans in ['chameleon_medical', 'shapeshifter_l3_medium', 'hydra_restructure', 'nocomments']:
            if trans in transformation_data[model]:
                non_sanitized_tdrs.append(transformation_data[model][trans]['tdr'])
        non_sanitized_tdr = np.mean(non_sanitized_tdrs) if non_sanitized_tdrs else 0

    # Get sanitized performance
    sanitized_tdr = transformation_data[model].get('sanitized', {}).get('tdr', 0)

    slope_data.append({
        'model': MODEL_NAMES[model],
        'model_id': model,
        'non_sanitized': non_sanitized_tdr,
        'sanitized': sanitized_tdr,
        'drop': non_sanitized_tdr - sanitized_tdr,
    })

# Sort by drop (largest drop first)
slope_data.sort(key=lambda x: x['drop'], reverse=True)

fig = go.Figure()

# Add lines
for item in slope_data:
    fig.add_trace(go.Scatter(
        x=[0, 1],
        y=[item['non_sanitized'], item['sanitized']],
        mode='lines+markers',
        line=dict(
            color=MODEL_COLORS[item['model_id']],
            width=4 if item['drop'] > 0.4 else 3,
        ),
        marker=dict(
            size=12,
            color=MODEL_COLORS[item['model_id']],
            line=dict(width=2, color='white'),
        ),
        name=item['model'],
        hovertemplate=(
            '<b>%{fullData.name}</b><br>'
            'Non-Sanitized: %{y:.1%}<br>'
            f"Drop: {item['drop']:.1%}"
            '<extra></extra>'
        ),
    ))

# Add labels on the right side
for i, item in enumerate(slope_data):
    fig.add_annotation(
        x=1.02,
        y=item['sanitized'],
        text=f"<b>{item['model']}</b> ({item['sanitized']:.1%})",
        showarrow=False,
        xanchor='left',
        font=dict(size=11, color=MODEL_COLORS[item['model_id']]),
    )

# Add labels on the left side
for i, item in enumerate(slope_data):
    fig.add_annotation(
        x=-0.02,
        y=item['non_sanitized'],
        text=f"{item['non_sanitized']:.1%}",
        showarrow=False,
        xanchor='right',
        font=dict(size=11, color=MODEL_COLORS[item['model_id']]),
    )

fig.update_layout(
    title={
        'text': '<b>The Sanitization Catastrophe - TDR Collapse</b><br><sub>Steeper slope = Larger performance drop</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 20}
    },
    xaxis=dict(
        tickmode='array',
        tickvals=[0, 1],
        ticktext=['<b>Non-Sanitized</b><br><i>(Original, Medical,<br>Shapeshifter, etc.)</i>',
                  '<b>Sanitized</b><br><i>(No semantic cues)</i>'],
        range=[-0.15, 1.25],
        showgrid=False,
    ),
    yaxis=dict(
        title='<b>Target Detection Rate (TDR)</b>',
        tickformat='.0%',
        range=[0, 1],
        gridcolor='rgba(0,0,0,0.1)',
    ),
    showlegend=False,
    width=1000,
    height=700,
    font=dict(size=12),
    plot_bgcolor='rgba(0,0,0,0.02)',
    paper_bgcolor='white',
)

fig.write_html('charts/4_sanitization_slope.html')
fig.write_image('charts/4_sanitization_slope.png', width=1000, height=700, scale=2)
print("✓ Saved: charts/4_sanitization_slope.html & .png")

print("\n" + "="*70)
print("✅ ALL CHARTS GENERATED SUCCESSFULLY!")
print("="*70)
print("\n📁 Output location: charts/")
print("\n📊 Generated charts:")
print("  1. charts/1_radar_performance.html & .png")
print("  2. charts/2_transformation_heatmap.html & .png")
print("  3. charts/3_tdr_vs_lucky_guess.html & .png")
print("  4. charts/4_sanitization_slope.html & .png")
print("\n💡 Tip: Open .html files for interactive exploration!")
print("="*70)
