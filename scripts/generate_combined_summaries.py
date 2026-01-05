#!/usr/bin/env python3
"""
Generate combined summary files across all models for each variant/tier.

Creates:
- JSON summary files with model rankings and vulnerability breakdown
- Visual README markdown files for easy visualization

Output structure:
  results/summaries/
  ├── tc/
  │   ├── minimalsanitized_summary.json
  │   ├── minimalsanitized_README.md
  │   └── ...
  ├── ds/
  │   ├── tier1_summary.json
  │   ├── tier1_README.md
  │   └── ...
  └── gs/
      └── ...
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent

TC_VARIANTS = ['sanitized', 'nocomments', 'chameleon_medical', 'shapeshifter_l3',
               'trojan', 'falseProphet', 'minimalsanitized', 'differential']

DS_TIERS = ['tier1', 'tier2', 'tier3', 'tier4']

DETECTORS = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
             'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

JUDGES = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']


def load_variant_summary(judge: str, detector: str, dataset: str, subset: str) -> dict:
    """Load a variant/tier summary file."""
    if dataset == 'tc':
        path = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/tc/{subset}/_variant_summary.json"
    elif dataset == 'ds':
        path = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/ds/{subset}/_tier_summary.json"
    elif dataset == 'gs':
        path = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/{judge}/{detector}/gs/{subset}/_summary.json"
    else:
        return None

    if not path.exists():
        return None

    with open(path) as f:
        return json.load(f)


def generate_combined_summary(judge: str, dataset: str, subset: str) -> dict:
    """Generate combined summary across all models for a variant/tier."""

    model_data = []
    all_vuln_types = {}

    for detector in DETECTORS:
        summary = load_variant_summary(judge, detector, dataset, subset)
        if not summary:
            continue

        dm = summary.get('detection_metrics', {})
        qs = summary.get('quality_scores', {})
        sc = summary.get('sample_counts', {})

        model_entry = {
            'detector': detector,
            'samples': sc.get('successful_evaluations', 0),
            'target_found_count': dm.get('target_found_count', 0),
            'target_detection_rate': dm.get('target_detection_rate', 0),
            'precision': dm.get('precision', 0),
            'f1_score': dm.get('f1_score'),
            'miss_rate': dm.get('miss_rate', 0),
            'lucky_guess_count': dm.get('lucky_guess_count', 0),
            'lucky_guess_rate': dm.get('lucky_guess_rate', 0),
            'samples_with_bonus': dm.get('samples_with_bonus', 0),
            'ancillary_discovery_rate': dm.get('ancillary_discovery_rate', 0),
            'verdict_correct_count': dm.get('verdict_correct_count', 0),
            'verdict_accuracy': dm.get('verdict_accuracy', 0),
            'total_findings': dm.get('total_findings', 0),
            'avg_findings_per_sample': dm.get('avg_findings_per_sample', 0),
            'true_positives': dm.get('true_positives', 0),
            'false_positives': dm.get('false_positives', 0),
            'invalid_finding_rate': dm.get('invalid_finding_rate', 0),
            'false_alarm_density': dm.get('false_alarm_density', 0),
            'avg_rcir': qs.get('avg_rcir'),
            'avg_ava': qs.get('avg_ava'),
            'avg_fsv': qs.get('avg_fsv'),
        }
        model_data.append(model_entry)

        # Collect vulnerability type data
        by_vuln = summary.get('by_vulnerability_type', {})
        for vtype, vdata in by_vuln.items():
            if vtype not in all_vuln_types:
                all_vuln_types[vtype] = {
                    'total_samples': vdata.get('total_samples', 0),
                    'models': []
                }

            all_vuln_types[vtype]['models'].append({
                'detector': detector,
                'target_found': vdata.get('target_found_count', 0),
                'detection_rate': vdata.get('target_detection_rate', 0),
                'precision': vdata.get('precision', 0),
                'f1_score': vdata.get('f1_score'),
                'avg_rcir': vdata.get('quality_scores', {}).get('avg_rcir'),
                'avg_ava': vdata.get('quality_scores', {}).get('avg_ava'),
                'avg_fsv': vdata.get('quality_scores', {}).get('avg_fsv'),
            })

    # Sort models by TDR (highest first)
    model_data.sort(key=lambda x: x['target_detection_rate'], reverse=True)

    # Add ranks
    for i, m in enumerate(model_data):
        m['rank'] = i + 1

    # Sort models within each vuln type by detection rate
    for vtype in all_vuln_types:
        all_vuln_types[vtype]['models'].sort(
            key=lambda x: x['detection_rate'], reverse=True
        )

    return {
        'dataset': dataset,
        'subset': subset,
        'judge': judge,
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'total_models': len(model_data),
        'model_rankings': model_data,
        'by_vulnerability_type': all_vuln_types
    }


def generate_readme(summary: dict) -> str:
    """Generate a visual README markdown file from summary data."""

    dataset = summary['dataset'].upper()
    subset = summary['subset']
    judge = summary['judge']
    generated_at = summary['generated_at'][:19].replace('T', ' ')

    lines = [
        f"# {dataset} {subset.replace('_', ' ').title()} - Combined Summary",
        "",
        f"**Judge Model:** {judge}  ",
        f"**Generated:** {generated_at} UTC  ",
        f"**Total Models:** {summary['total_models']}",
        "",
        "---",
        "",
        "## Model Rankings (by Target Detection Rate)",
        "",
    ]

    # Model rankings table
    lines.append("| Rank | Detector | TDR | Precision | F1 | Verdict Acc | RCIR | AVA | FSV | Findings | FP Rate |")
    lines.append("|:----:|:---------|----:|----------:|---:|------------:|-----:|----:|----:|---------:|--------:|")

    for m in summary['model_rankings']:
        tdr = f"{m['target_detection_rate']*100:.1f}%" if m['target_detection_rate'] else "N/A"
        prec = f"{m['precision']*100:.1f}%" if m['precision'] else "N/A"
        f1 = f"{m['f1_score']*100:.1f}%" if m['f1_score'] else "N/A"
        vacc = f"{m['verdict_accuracy']*100:.1f}%" if m['verdict_accuracy'] else "N/A"
        rcir = f"{m['avg_rcir']:.2f}" if m['avg_rcir'] else "N/A"
        ava = f"{m['avg_ava']:.2f}" if m['avg_ava'] else "N/A"
        fsv = f"{m['avg_fsv']:.2f}" if m['avg_fsv'] else "N/A"
        findings = f"{m['avg_findings_per_sample']:.1f}"
        fpr = f"{m['invalid_finding_rate']*100:.1f}%" if m['invalid_finding_rate'] else "0.0%"

        lines.append(f"| {m['rank']} | {m['detector']} | {tdr} | {prec} | {f1} | {vacc} | {rcir} | {ava} | {fsv} | {findings} | {fpr} |")

    # Detailed metrics table
    lines.extend([
        "",
        "### Detailed Metrics",
        "",
        "| Detector | Found | Miss Rate | Lucky Guess | Bonus Disc | TP | FP | FAD |",
        "|:---------|------:|----------:|------------:|-----------:|---:|---:|----:|"
    ])

    for m in summary['model_rankings']:
        found = f"{m['target_found_count']}/{m['samples']}"
        miss = f"{m['miss_rate']*100:.1f}%"
        lg = f"{m['lucky_guess_rate']*100:.1f}%"
        adr = f"{m['ancillary_discovery_rate']*100:.1f}%"
        tp = m['true_positives']
        fp = m['false_positives']
        fad = f"{m['false_alarm_density']:.2f}"

        lines.append(f"| {m['detector']} | {found} | {miss} | {lg} | {adr} | {tp} | {fp} | {fad} |")

    # Vulnerability type breakdown
    lines.extend([
        "",
        "---",
        "",
        "## Performance by Vulnerability Type",
        "",
    ])

    vuln_types = summary.get('by_vulnerability_type', {})

    # Sort vuln types by total samples (descending)
    sorted_vtypes = sorted(vuln_types.items(), key=lambda x: x[1]['total_samples'], reverse=True)

    for vtype, vdata in sorted_vtypes:
        total = vdata['total_samples']
        lines.extend([
            f"### {vtype.replace('_', ' ').title()} ({total} samples)",
            "",
            "| Detector | Found | Rate | Precision | F1 | RCIR |",
            "|:---------|------:|-----:|----------:|---:|-----:|"
        ])

        for m in vdata['models']:
            found = m['target_found']
            rate = f"{m['detection_rate']*100:.1f}%" if m['detection_rate'] else "0.0%"
            prec = f"{m['precision']*100:.1f}%" if m['precision'] else "N/A"
            f1 = f"{m['f1_score']*100:.1f}%" if m['f1_score'] else "N/A"
            rcir = f"{m['avg_rcir']:.2f}" if m['avg_rcir'] else "N/A"

            lines.append(f"| {m['detector']} | {found}/{total} | {rate} | {prec} | {f1} | {rcir} |")

        lines.append("")

    # Legend
    lines.extend([
        "---",
        "",
        "## Metric Definitions",
        "",
        "| Metric | Description |",
        "|:-------|:------------|",
        "| **TDR** | Target Detection Rate - % of samples where target vulnerability was found |",
        "| **Precision** | True Positives / (True Positives + False Positives) |",
        "| **F1** | Harmonic mean of Precision and TDR |",
        "| **Verdict Acc** | % of samples with correct vulnerable/safe verdict |",
        "| **RCIR** | Root Cause Identification Rating (0-1) |",
        "| **AVA** | Attack Vector Accuracy (0-1) |",
        "| **FSV** | Fix Suggestion Validity (0-1) |",
        "| **Lucky Guess** | Correct verdict but no target found and no bonus findings |",
        "| **Bonus Disc** | Ancillary Discovery Rate - found additional valid vulnerabilities |",
        "| **TP/FP** | True Positives / False Positives |",
        "| **FAD** | False Alarm Density - avg false positives per sample |",
        ""
    ])

    return "\n".join(lines)


def generate_all_summaries(judge: str, dataset: str, subsets: list, output_dir: Path):
    """Generate summaries for all subsets of a dataset."""

    output_dir.mkdir(parents=True, exist_ok=True)

    for subset in subsets:
        print(f"Generating {dataset}/{subset}...")

        summary = generate_combined_summary(judge, dataset, subset)

        if not summary['model_rankings']:
            print(f"  No data for {subset}, skipping")
            continue

        # Save JSON
        json_path = output_dir / f"{subset}_summary.json"
        with open(json_path, 'w') as f:
            json.dump(summary, f, indent=2)
        print(f"  Saved: {json_path}")

        # Save README
        readme = generate_readme(summary)
        readme_path = output_dir / f"{subset}_README.md"
        with open(readme_path, 'w') as f:
            f.write(readme)
        print(f"  Saved: {readme_path}")


def main():
    parser = argparse.ArgumentParser(description="Generate combined summary files")
    parser.add_argument("--judge", "-j", default="codestral", choices=JUDGES + ['all'])
    parser.add_argument("--dataset", "-d", choices=['tc', 'ds', 'gs', 'all'], default='all')
    parser.add_argument("--subset", "-s", help="Specific subset/variant/tier")

    args = parser.parse_args()

    base_output = PROJECT_ROOT / "results/summaries"

    # Determine which judges to process
    judges_to_process = JUDGES if args.judge == 'all' else [args.judge]

    for judge in judges_to_process:
        judge_output = base_output / judge

        datasets_to_process = []

        if args.dataset == 'all' or args.dataset == 'tc':
            subsets = [args.subset] if args.subset else TC_VARIANTS
            datasets_to_process.append(('tc', subsets, judge_output / 'tc'))

        if args.dataset == 'all' or args.dataset == 'ds':
            subsets = [args.subset] if args.subset else DS_TIERS
            datasets_to_process.append(('ds', subsets, judge_output / 'ds'))

        if args.dataset == 'all' or args.dataset == 'gs':
            # GS has different structure - handle separately if needed
            subsets = [args.subset] if args.subset else ['direct']
            datasets_to_process.append(('gs', subsets, judge_output / 'gs'))

        for dataset, subsets, output_dir in datasets_to_process:
            print(f"\n{'='*60}")
            print(f"Processing {dataset.upper()} with judge {judge}")
            print(f"{'='*60}")
            generate_all_summaries(judge, dataset, subsets, output_dir)

    print(f"\n\nAll summaries saved to: {base_output}")


if __name__ == "__main__":
    main()
