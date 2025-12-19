#!/usr/bin/env python3
"""
Generate research paper-appropriate visualizations.
Clean, academic style - suitable for IEEE/ACM publications.
"""

import json
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from pathlib import Path

# Academic color scheme - muted, professional, grayscale-friendly
MODEL_COLORS = {
    'claude_opus_4.5': '#2E5090',      # Dark blue
    'gemini_3_pro_preview': '#2D7A3E', # Dark green
    'gpt-5.2': '#8B4513',              # Saddle brown
    'deepseek_v3.2': '#6B4C9A',        # Purple
    'llama_3.1_405b': '#C45911',       # Dark orange
    'grok_4_fast': '#4B6B8C',          # Steel blue
}

MODEL_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'deepseek_v3.2': 'DeepSeek V3.2',
    'llama_3.1_405b': 'Llama 3.1 405B',
    'grok_4_fast': 'Grok 4',
}

TRANSFORMATION_NAMES = {
    'sanitized': 'Sanitized',
    'chameleon_medical': 'Medical',
    'shapeshifter_l3_medium': 'Shapeshifter',
    'hydra_restructure': 'Hydra',
    'nocomments': 'No-Comments',
    'nocomments_original': 'Original',
}

# Academic font settings
FONT_FAMILY = 'Arial, sans-serif'
TITLE_SIZE = 14
AXIS_TITLE_SIZE = 12
TICK_SIZE = 10
LEGEND_SIZE = 10

print("="*70)
print("RESEARCH PAPER VISUALIZATION GENERATOR")
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
# FIGURE 1: Model Performance Comparison (SUI Ranking)
# =============================================================================
print("\n📊 Generating Figure 1: Model Performance Comparison...")

sui_data = []
for model in MODEL_COLORS.keys():
    if model in gs_data:
        data = gs_data[model]
        # Simple SUI calculation
        sui = (data['tdr'] * 0.4 + data['finding_precision'] * 0.4 +
               data['accuracy'] * 0.2)

        sui_data.append({
            'model': MODEL_NAMES[model],
            'model_id': model,
            'sui': sui,
            'tdr': data['tdr'],
            'precision': data['finding_precision'],
            'accuracy': data['accuracy'],
        })

sui_data.sort(key=lambda x: x['sui'], reverse=True)
df = pd.DataFrame(sui_data)

fig = go.Figure()

fig.add_trace(go.Bar(
    y=df['model'],
    x=df['sui'],
    orientation='h',
    marker=dict(
        color=[MODEL_COLORS[row['model_id']] for _, row in df.iterrows()],
        line=dict(color='black', width=0.5),
    ),
    text=[f"{val:.2f}" for val in df['sui']],
    textposition='outside',
    textfont=dict(size=TICK_SIZE, color='black'),
    hovertemplate='<b>%{y}</b><br>SUI: %{x:.3f}<extra></extra>',
))

fig.update_layout(
    title={
        'text': 'Model Performance on GPTShield Dataset',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='Security Understanding Index (SUI)', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        range=[0, max(df['sui']) * 1.1],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        showgrid=False,
        showline=True,
        linewidth=1,
        linecolor='black',
        autorange='reversed',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=700,
    height=400,
    font=dict(size=TICK_SIZE, family=FONT_FAMILY),
    margin=dict(l=120, r=80, t=60, b=60),
    showlegend=False,
)

fig.write_html('charts/paper_fig1_performance.html')
fig.write_image('charts/paper_fig1_performance.png', width=700, height=400, scale=2)
fig.write_image('charts/paper_fig1_performance.pdf', width=700, height=400)
print("✓ Saved: charts/paper_fig1_performance.{html,png,pdf}")

# =============================================================================
# FIGURE 2: Target Detection Rate Across Transformations
# =============================================================================
print("\n📊 Generating Figure 2: TDR Across Transformations...")

transformations_ordered = ['nocomments_original', 'chameleon_medical', 'shapeshifter_l3_medium',
                          'hydra_restructure', 'nocomments', 'sanitized']

fig = go.Figure()

for model in MODEL_COLORS.keys():
    if model not in transformation_data:
        continue

    tdrs = []
    for trans in transformations_ordered:
        if trans in transformation_data[model]:
            tdrs.append(transformation_data[model][trans]['tdr'])
        else:
            tdrs.append(None)

    fig.add_trace(go.Scatter(
        x=[TRANSFORMATION_NAMES[t] for t in transformations_ordered],
        y=tdrs,
        mode='lines+markers',
        name=MODEL_NAMES[model],
        line=dict(color=MODEL_COLORS[model], width=2),
        marker=dict(
            size=6,
            color=MODEL_COLORS[model],
            line=dict(width=0.5, color='black'),
        ),
        hovertemplate='<b>%{fullData.name}</b><br>%{x}<br>TDR: %{y:.1%}<extra></extra>',
    ))

fig.update_layout(
    title={
        'text': 'Target Detection Rate by Code Transformation',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='Transformation Type', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickangle=-45,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Target Detection Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, 1],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
        zeroline=True,
        zerolinecolor='lightgray',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=800,
    height=500,
    font=dict(size=LEGEND_SIZE, family=FONT_FAMILY),
    legend=dict(
        orientation='v',
        yanchor='top',
        y=0.98,
        xanchor='right',
        x=0.98,
        bgcolor='white',
        bordercolor='black',
        borderwidth=1,
    ),
    margin=dict(l=80, r=120, t=60, b=100),
)

fig.write_html('charts/paper_fig2_transformations.html')
fig.write_image('charts/paper_fig2_transformations.png', width=800, height=500, scale=2)
fig.write_image('charts/paper_fig2_transformations.pdf', width=800, height=500)
print("✓ Saved: charts/paper_fig2_transformations.{html,png,pdf}")

# =============================================================================
# FIGURE 3: Transformation Impact Heatmap
# =============================================================================
print("\n📊 Generating Figure 3: Transformation Impact Heatmap...")

transformations = ['sanitized', 'chameleon_medical', 'shapeshifter_l3_medium',
                   'hydra_restructure', 'nocomments', 'nocomments_original']
models = list(MODEL_COLORS.keys())

tdr_matrix = []
for model in models:
    tdr_row = []
    for transformation in transformations:
        if model in transformation_data and transformation in transformation_data[model]:
            tdr = transformation_data[model][transformation]['tdr']
        else:
            tdr = 0
        tdr_row.append(tdr)
    tdr_matrix.append(tdr_row)

fig = go.Figure(data=go.Heatmap(
    z=tdr_matrix,
    x=[TRANSFORMATION_NAMES[t] for t in transformations],
    y=[MODEL_NAMES[m] for m in models],
    colorscale='Greys',
    reversescale=True,
    text=[[f'{val:.0%}' for val in row] for row in tdr_matrix],
    texttemplate='%{text}',
    textfont={'size': TICK_SIZE, 'color': 'black'},
    colorbar=dict(
        title=dict(text='TDR', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
    ),
    hovertemplate='<b>%{y}</b><br>%{x}<br>TDR: %{z:.1%}<extra></extra>',
))

fig.update_layout(
    title={
        'text': 'Target Detection Rate by Model and Transformation',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickangle=-45,
        side='bottom',
    ),
    yaxis=dict(
        title=dict(text='', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=800,
    height=500,
    font=dict(size=TICK_SIZE, family=FONT_FAMILY),
    margin=dict(l=120, r=100, t=60, b=100),
)

fig.write_html('charts/paper_fig3_heatmap.html')
fig.write_image('charts/paper_fig3_heatmap.png', width=800, height=500, scale=2)
fig.write_image('charts/paper_fig3_heatmap.pdf', width=800, height=500)
print("✓ Saved: charts/paper_fig3_heatmap.{html,png,pdf}")

# =============================================================================
# FIGURE 4: TDR vs Finding Precision Scatter
# =============================================================================
print("\n📊 Generating Figure 4: TDR vs Finding Precision...")

scatter_data = []
for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue
    data = gs_data[model]
    scatter_data.append({
        'model': MODEL_NAMES[model],
        'model_id': model,
        'tdr': data['tdr'],
        'precision': data['finding_precision'],
        'accuracy': data['accuracy'],
    })

df = pd.DataFrame(scatter_data)

fig = go.Figure()

for _, row in df.iterrows():
    fig.add_trace(go.Scatter(
        x=[row['tdr']],
        y=[row['precision']],
        mode='markers+text',
        marker=dict(
            size=12,
            color=MODEL_COLORS[row['model_id']],
            line=dict(width=1, color='black'),
        ),
        text=row['model'],
        textposition='top center',
        textfont=dict(size=9, color='black'),
        name=row['model'],
        showlegend=False,
        hovertemplate=(
            '<b>%{text}</b><br>'
            'TDR: %{x:.1%}<br>'
            'Precision: %{y:.1%}'
            '<extra></extra>'
        ),
    ))

fig.update_layout(
    title={
        'text': 'Target Detection Rate vs Finding Precision',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='Target Detection Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, max(df['tdr']) * 1.2],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Finding Precision', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, max(df['precision']) * 1.2],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=600,
    height=500,
    font=dict(size=TICK_SIZE, family=FONT_FAMILY),
    margin=dict(l=80, r=40, t=60, b=60),
)

fig.write_html('charts/paper_fig4_scatter.html')
fig.write_image('charts/paper_fig4_scatter.png', width=600, height=500, scale=2)
fig.write_image('charts/paper_fig4_scatter.pdf', width=600, height=500)
print("✓ Saved: charts/paper_fig4_scatter.{html,png,pdf}")

# =============================================================================
# FIGURE 5: Prompt Type Impact
# =============================================================================
print("\n📊 Generating Figure 5: Prompt Type Impact...")

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

    if sum(1 for t in tdrs if t is not None) >= 2:
        fig.add_trace(go.Scatter(
            x=prompt_labels,
            y=tdrs,
            mode='lines+markers',
            name=MODEL_NAMES[model],
            line=dict(color=MODEL_COLORS[model], width=2),
            marker=dict(
                size=6,
                color=MODEL_COLORS[model],
                line=dict(width=0.5, color='black'),
            ),
            hovertemplate='<b>%{fullData.name}</b><br>%{x}<br>TDR: %{y:.1%}<extra></extra>',
        ))

fig.update_layout(
    title={
        'text': 'Impact of Prompt Strategy on Target Detection',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='Prompt Type', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Target Detection Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, 0.5],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=700,
    height=500,
    font=dict(size=LEGEND_SIZE, family=FONT_FAMILY),
    legend=dict(
        orientation='v',
        yanchor='top',
        y=0.98,
        xanchor='right',
        x=0.98,
        bgcolor='white',
        bordercolor='black',
        borderwidth=1,
    ),
    margin=dict(l=80, r=120, t=60, b=60),
)

fig.write_html('charts/paper_fig5_prompts.html')
fig.write_image('charts/paper_fig5_prompts.png', width=700, height=500, scale=2)
fig.write_image('charts/paper_fig5_prompts.pdf', width=700, height=500)
print("✓ Saved: charts/paper_fig5_prompts.{html,png,pdf}")

# =============================================================================
# FIGURE 6: Performance Components (Grouped Bar)
# =============================================================================
print("\n📊 Generating Figure 6: Performance Components...")

components_data = []
for model in MODEL_COLORS.keys():
    if model not in gs_data:
        continue
    data = gs_data[model]
    components_data.append({
        'model': MODEL_NAMES[model],
        'model_id': model,
        'Accuracy': data['accuracy'],
        'TDR': data['tdr'],
        'Precision': data['finding_precision'],
    })

components_data.sort(key=lambda x: x['TDR'] + x['Precision'], reverse=True)
df = pd.DataFrame(components_data)

fig = go.Figure()

bar_colors = ['#5F6368', '#3C4043', '#1A1A1A']  # Grayscale-friendly
metrics = ['Accuracy', 'TDR', 'Precision']

for i, metric in enumerate(metrics):
    fig.add_trace(go.Bar(
        x=df['model'],
        y=df[metric],
        name=metric,
        marker=dict(
            color=bar_colors[i],
            line=dict(color='black', width=0.5),
        ),
        hovertemplate='<b>%{fullData.name}</b><br>%{y:.1%}<extra></extra>',
    ))

fig.update_layout(
    title={
        'text': 'Model Performance Components',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickangle=-30,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Score', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, 1],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    barmode='group',
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=800,
    height=500,
    font=dict(size=LEGEND_SIZE, family=FONT_FAMILY),
    legend=dict(
        orientation='h',
        yanchor='bottom',
        y=1.02,
        xanchor='center',
        x=0.5,
        bgcolor='white',
        bordercolor='black',
        borderwidth=1,
    ),
    margin=dict(l=80, r=40, t=80, b=80),
)

fig.write_html('charts/paper_fig6_components.html')
fig.write_image('charts/paper_fig6_components.png', width=800, height=500, scale=2)
fig.write_image('charts/paper_fig6_components.pdf', width=800, height=500)
print("✓ Saved: charts/paper_fig6_components.{html,png,pdf}")

# =============================================================================
# FIGURE 7: TDR vs Lucky Guess Rate Scatter
# =============================================================================
print("\n📊 Generating Figure 7: TDR vs Lucky Guess Rate...")

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
            size=row['finding_precision'] * 100 + 10,  # Scale by precision
            color=MODEL_COLORS[row['model_id']],
            line=dict(width=1, color='black'),
            opacity=0.7,
        ),
        text=row['model'],
        textposition='top center',
        textfont=dict(size=9, color='black'),
        name=row['model'],
        showlegend=False,
        hovertemplate=(
            '<b>%{text}</b><br>'
            'TDR: %{x:.1%}<br>'
            'Lucky Guess Rate: %{y:.1%}<br>'
            f"Finding Precision: {row['finding_precision']:.1%}<br>"
            f"Accuracy: {row['accuracy']:.1%}"
            '<extra></extra>'
        ),
    ))

# Add reference lines
fig.add_hline(y=0.5, line_dash='dash', line_color='gray', line_width=1)
fig.add_vline(x=0.2, line_dash='dash', line_color='gray', line_width=1)

fig.update_layout(
    title={
        'text': 'Target Detection Rate vs Lucky Guess Rate',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        title=dict(text='Target Detection Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[-0.02, max(df['tdr']) * 1.3],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Lucky Guess Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[-0.05, 1.0],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=700,
    height=600,
    font=dict(size=TICK_SIZE, family=FONT_FAMILY),
    margin=dict(l=80, r=40, t=60, b=60),
)

fig.write_html('charts/paper_fig7_lucky_guess.html')
fig.write_image('charts/paper_fig7_lucky_guess.png', width=700, height=600, scale=2)
fig.write_image('charts/paper_fig7_lucky_guess.pdf', width=700, height=600)
print("✓ Saved: charts/paper_fig7_lucky_guess.{html,png,pdf}")

# =============================================================================
# FIGURE 8: Sanitization Effect Slope Chart
# =============================================================================
print("\n📊 Generating Figure 8: Sanitization Effect Slope...")

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
            width=2,
        ),
        marker=dict(
            size=8,
            color=MODEL_COLORS[item['model_id']],
            line=dict(width=1, color='black'),
        ),
        name=item['model'],
        hovertemplate=(
            '<b>%{fullData.name}</b><br>'
            '%{y:.1%}<br>'
            f"Drop: {item['drop']:.1%}"
            '<extra></extra>'
        ),
    ))

# Add labels on the right side
for i, item in enumerate(slope_data):
    fig.add_annotation(
        x=1.02,
        y=item['sanitized'],
        text=f"{item['model']} ({item['sanitized']:.0%})",
        showarrow=False,
        xanchor='left',
        font=dict(size=9, color=MODEL_COLORS[item['model_id']], family=FONT_FAMILY),
    )

# Add labels on the left side
for i, item in enumerate(slope_data):
    fig.add_annotation(
        x=-0.02,
        y=item['non_sanitized'],
        text=f"{item['non_sanitized']:.0%}",
        showarrow=False,
        xanchor='right',
        font=dict(size=9, color=MODEL_COLORS[item['model_id']], family=FONT_FAMILY),
    )

fig.update_layout(
    title={
        'text': 'Impact of Sanitization on Target Detection Rate',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': TITLE_SIZE, 'family': FONT_FAMILY, 'color': 'black'}
    },
    xaxis=dict(
        tickmode='array',
        tickvals=[0, 1],
        ticktext=['Non-Sanitized', 'Sanitized'],
        tickfont=dict(size=AXIS_TITLE_SIZE),
        range=[-0.15, 1.35],
        showgrid=False,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    yaxis=dict(
        title=dict(text='Target Detection Rate', font=dict(size=AXIS_TITLE_SIZE, family=FONT_FAMILY)),
        tickfont=dict(size=TICK_SIZE),
        tickformat='.0%',
        range=[0, 1],
        gridcolor='lightgray',
        gridwidth=0.5,
        showline=True,
        linewidth=1,
        linecolor='black',
    ),
    showlegend=False,
    plot_bgcolor='white',
    paper_bgcolor='white',
    width=800,
    height=600,
    font=dict(size=TICK_SIZE, family=FONT_FAMILY),
    margin=dict(l=80, r=150, t=60, b=60),
)

fig.write_html('charts/paper_fig8_sanitization.html')
fig.write_image('charts/paper_fig8_sanitization.png', width=800, height=600, scale=2)
fig.write_image('charts/paper_fig8_sanitization.pdf', width=800, height=600)
print("✓ Saved: charts/paper_fig8_sanitization.{html,png,pdf}")

print("\n" + "="*70)
print("✅ ALL RESEARCH PAPER FIGURES GENERATED!")
print("="*70)
print("\n📁 Output location: charts/")
print("\n📊 Generated figures (publication-ready):")
print("  Figure 1: Model Performance Comparison")
print("  Figure 2: TDR Across Transformations")
print("  Figure 3: Transformation Impact Heatmap")
print("  Figure 4: TDR vs Finding Precision")
print("  Figure 5: Prompt Type Impact")
print("  Figure 6: Performance Components")
print("  Figure 7: TDR vs Lucky Guess Rate")
print("  Figure 8: Sanitization Effect Slope")
print("\n📄 Formats:")
print("  ✓ HTML (interactive)")
print("  ✓ PNG (high-res, 2x scale)")
print("  ✓ PDF (vector, publication-quality)")
print("\n✨ Features:")
print("  ✓ Clean, minimal academic style")
print("  ✓ No emojis or decorative elements")
print("  ✓ Grayscale-friendly color schemes")
print("  ✓ Standard fonts (Arial)")
print("  ✓ Black axis lines and borders")
print("  ✓ Professional typography")
print("  ✓ IEEE/ACM publication standards")
print("="*70)
