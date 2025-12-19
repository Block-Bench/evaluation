#!/usr/bin/env python3
"""Find a sample where models had different responses."""

import json
from pathlib import Path
from collections import defaultdict

models = ['claude_opus_4.5', 'gemini_3_pro_preview', 'gpt-5.2', 'deepseek_v3.2', 'llama_3.1_405b', 'grok_4_fast']

# Find all sample IDs
sample_ids = set()
for model in models:
    metrics_dir = Path('judge_output') / model / 'sample_metrics'
    if metrics_dir.exists():
        for f in metrics_dir.glob('m_*_direct.json'):
            sample_id = f.stem.replace('m_', '').replace('_direct', '')
            sample_ids.add(sample_id)

print(f"Found {len(sample_ids)} samples")

# Analyze each sample for disagreement
disagreements = []

for sample_id in sorted(sample_ids):
    verdicts = {}
    vuln_types = {}

    for model in models:
        metric_file = Path('judge_output') / model / 'sample_metrics' / f'm_{sample_id}_direct.json'
        if metric_file.exists():
            with open(metric_file) as f:
                data = json.load(f)
                verdicts[model] = data.get('predicted_vulnerable', 'unknown')
                vuln_types[model] = data.get('predicted_vuln_type', 'unknown')

    if len(verdicts) >= 5:  # At least 5 models responded
        # Check if there's disagreement
        verdict_values = list(verdicts.values())
        vuln_values = list(vuln_types.values())

        # Count unique verdicts and vuln types
        unique_verdicts = len(set(verdict_values))
        unique_vulns = len(set(vuln_values))

        if unique_verdicts >= 1:  # Show all samples
            disagreements.append({
                'sample_id': sample_id,
                'unique_verdicts': unique_verdicts,
                'unique_vulns': unique_vulns,
                'verdicts': verdicts,
                'vuln_types': vuln_types,
            })

# Sort by most disagreement
disagreements.sort(key=lambda x: (x['unique_vulns'], x['unique_verdicts']), reverse=True)

print(f"\nFound {len(disagreements)} samples with disagreement\n")

# Show top 10
for i, item in enumerate(disagreements[:10]):
    print(f"{i+1}. Sample: {item['sample_id']}")
    print(f"   Unique verdicts: {item['unique_verdicts']}, Unique vuln types: {item['unique_vulns']}")
    print(f"   Verdicts: {item['verdicts']}")
    print(f"   Vuln types: {item['vuln_types']}")
    print()
