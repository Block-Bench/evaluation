#!/usr/bin/env python3
"""
Generate elegant comparison chart showing different model responses to same smart contract.
"""

import plotly.graph_objects as go
from plotly.subplots import make_subplots
import textwrap

# Academic color scheme
MODEL_COLORS = {
    'claude_opus_4.5': '#2E5090',
    'gemini_3_pro_preview': '#2D7A3E',
    'gpt-5.2': '#8B4513',
    'llama_3.1_405b': '#C45911',
}

MODEL_NAMES = {
    'claude_opus_4.5': 'Claude Opus 4.5',
    'gemini_3_pro_preview': 'Gemini 3 Pro',
    'gpt-5.2': 'GPT-5.2',
    'llama_3.1_405b': 'Llama 3.1 405B',
}

# Contract snippet
contract_code = """function setAcceptedRoot(bytes32 _newRoot) external {
    acceptedRoot = _newRoot;
}

function _messageRoot(bytes memory _message)
    internal pure returns (bytes32) {
    if (_message.length > 32 &&
        uint256(bytes32(_message)) == 0) {
        return bytes32(0);
    }
    return keccak256(_message);
}"""

# Model responses (shortened for clarity)
responses = {
    'claude_opus_4.5': {
        'verdict': 'VULNERABLE',
        'confidence': '98%',
        'vuln_count': 2,
        'vulnerabilities': [
            'Access Control: setAcceptedRoot has no access control',
            'Improper Validation: _messageRoot returns zero for messages starting with 32 zero bytes'
        ],
        'summary': 'Two critical flaws combine: unrestricted setAcceptedRoot + zero-bypass in _messageRoot'
    },
    'gemini_3_pro_preview': {
        'verdict': 'VULNERABLE',
        'confidence': '100%',
        'vuln_count': 2,
        'vulnerabilities': [
            'Access Control: setAcceptedRoot lacks access modifiers',
            'Zero Root Bypass: Returns bytes32(0) for specific message formats'
        ],
        'summary': 'Complete takeover via unprotected root setter + validation bypass mimicking Nomad hack'
    },
    'gpt-5.2': {
        'verdict': 'VULNERABLE',
        'confidence': '95%',
        'vuln_count': 2,
        'vulnerabilities': [
            'Access Control: setAcceptedRoot publicly callable with no authorization',
            'Authentication Bypass: _messageRoot returns zero when acceptedRoot defaults to 0'
        ],
        'summary': 'Root verification broken: anyone can set root + immediate bypass via zero-root attack'
    },
    'llama_3.1_405b': {
        'verdict': 'VULNERABLE',
        'confidence': '100%',
        'vuln_count': 1,
        'vulnerabilities': [
            'Access Control: setAcceptedRoot not restricted to any user or role'
        ],
        'summary': 'Critical access control vulnerability allowing unauthorized root changes'
    },
}

# Academic font settings
FONT_FAMILY = 'Arial, sans-serif'
TITLE_SIZE = 16
HEADER_SIZE = 11
TEXT_SIZE = 9

print("="*70)
print("GENERATING MODEL COMPARISON CHART")
print("="*70)

# Create figure with custom layout
fig = go.Figure()

# Add a table-like visualization using shapes and annotations
y_start = 1.0
y_spacing = 0.22
x_margin = 0.05

# Title
fig.add_annotation(
    x=0.5, y=y_start + 0.05,
    text='<b>Model Responses to Nomad Bridge Vulnerability</b>',
    showarrow=False,
    font=dict(size=TITLE_SIZE, family=FONT_FAMILY, color='black'),
    xanchor='center',
    yanchor='bottom',
)

# Contract code section
fig.add_annotation(
    x=0.5, y=y_start - 0.02,
    text='<b>Vulnerable Smart Contract (Solidity)</b>',
    showarrow=False,
    font=dict(size=HEADER_SIZE, family=FONT_FAMILY, color='black'),
    xanchor='center',
    yanchor='top',
)

fig.add_annotation(
    x=0.5, y=y_start - 0.08,
    text=f'<i>{contract_code}</i>',
    showarrow=False,
    font=dict(size=8, family='Courier New, monospace', color='#333'),
    xanchor='center',
    yanchor='top',
    bgcolor='#F5F5F5',
    bordercolor='#CCCCCC',
    borderwidth=1,
    borderpad=8,
)

# Model responses
y_current = y_start - 0.32

for i, (model_id, response) in enumerate(responses.items()):
    model_name = MODEL_NAMES[model_id]
    color = MODEL_COLORS[model_id]

    # Calculate y position for this model
    y_pos = y_current - (i * y_spacing)

    # Model name header with colored bar
    fig.add_shape(
        type="rect",
        x0=x_margin, x1=1-x_margin,
        y0=y_pos + 0.04, y1=y_pos + 0.06,
        fillcolor=color,
        line=dict(width=0),
        layer='below',
    )

    fig.add_annotation(
        x=x_margin + 0.01, y=y_pos + 0.05,
        text=f'<b>{model_name}</b>',
        showarrow=False,
        font=dict(size=HEADER_SIZE, family=FONT_FAMILY, color='white'),
        xanchor='left',
        yanchor='middle',
    )

    # Verdict and confidence
    fig.add_annotation(
        x=1-x_margin-0.01, y=y_pos + 0.05,
        text=f'{response["verdict"]} ({response["confidence"]} confidence)',
        showarrow=False,
        font=dict(size=TEXT_SIZE, family=FONT_FAMILY, color='white'),
        xanchor='right',
        yanchor='middle',
    )

    # Response box
    fig.add_shape(
        type="rect",
        x0=x_margin, x1=1-x_margin,
        y0=y_pos - 0.12, y1=y_pos + 0.04,
        fillcolor='white',
        line=dict(color='#DDDDDD', width=1),
        layer='below',
    )

    # Vulnerabilities found
    vuln_text = f'<b>Found {response["vuln_count"]} Vulnerability(ies):</b><br>'
    for vuln in response['vulnerabilities']:
        # Wrap text
        wrapped = '<br>  '.join(textwrap.wrap(vuln, width=80))
        vuln_text += f'• {wrapped}<br>'

    fig.add_annotation(
        x=x_margin + 0.02, y=y_pos + 0.01,
        text=vuln_text,
        showarrow=False,
        font=dict(size=TEXT_SIZE, family=FONT_FAMILY, color='#333'),
        xanchor='left',
        yanchor='top',
        align='left',
    )

    # Summary
    summary_wrapped = '<br>'.join(textwrap.wrap(response['summary'], width=90))
    fig.add_annotation(
        x=x_margin + 0.02, y=y_pos - 0.08,
        text=f'<i>{summary_wrapped}</i>',
        showarrow=False,
        font=dict(size=TEXT_SIZE-1, family=FONT_FAMILY, color='#666'),
        xanchor='left',
        yanchor='top',
        align='left',
    )

# Footer note
fig.add_annotation(
    x=0.5, y=-0.05,
    text='Sample: nc_o_tc_001 (VulnerableNomadReplica) | All models correctly identified the contract as vulnerable',
    showarrow=False,
    font=dict(size=8, family=FONT_FAMILY, color='#888'),
    xanchor='center',
    yanchor='top',
)

# Update layout
fig.update_layout(
    width=1000,
    height=1200,
    plot_bgcolor='white',
    paper_bgcolor='white',
    xaxis=dict(
        showgrid=False,
        showticklabels=False,
        range=[0, 1],
        zeroline=False,
    ),
    yaxis=dict(
        showgrid=False,
        showticklabels=False,
        range=[-0.1, 1.15],
        zeroline=False,
    ),
    margin=dict(l=20, r=20, t=20, b=20),
    font=dict(family=FONT_FAMILY),
)

# Save outputs
fig.write_html('charts/paper_fig9_model_comparison.html')
fig.write_image('charts/paper_fig9_model_comparison.png', width=1000, height=1200, scale=2)
fig.write_image('charts/paper_fig9_model_comparison.pdf', width=1000, height=1200)

print("✓ Saved: charts/paper_fig9_model_comparison.{html,png,pdf}")
print("\n" + "="*70)
print("✅ MODEL COMPARISON CHART GENERATED!")
print("="*70)
print("\nFigure shows how 4 different LLMs analyzed the same vulnerable contract:")
print("  • Claude Opus 4.5: Found 2 vulnerabilities with detailed analysis")
print("  • Gemini 3 Pro: Found 2 vulnerabilities, referenced Nomad hack")
print("  • GPT-5.2: Found 2 vulnerabilities with extensive DoS/bypass details")
print("  • Llama 3.1 405B: Found only 1 vulnerability (missed zero-root bypass)")
print("\nContract: VulnerableNomadReplica (Nomad Bridge exploit)")
print("Ground Truth: Access Control + Zero Root Bypass vulnerabilities")
print("="*70)
