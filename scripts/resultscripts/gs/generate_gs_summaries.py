#!/usr/bin/env python3
"""
Generate GS (Gold Standard) summaries per judge, per prompt type.

Creates summaries in results/summaries/{judge}/gs/ with:
- {prompt_type}_summary.json
- {prompt_type}_README.md

Similar structure to TC variant summaries.
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from collections import defaultdict


# Configuration
GS_PROMPT_TYPES = [
    'direct',
    'context_protocol',
    'context_protocol_cot',
    'context_protocol_cot_adversarial',
    'context_protocol_cot_naturalistic'
]

# Default judges - flexible, can be changed
DEFAULT_JUDGES = ['codestral', 'mimo-v2-flash', 'gemini-3-flash']

# Model display names
MODEL_NAMES = {
    'claude-opus-4-5': 'Claude Opus 4.5',
    'gpt-5.2': 'GPT-5.2',
    'gemini-3-pro': 'Gemini 3 Pro',
    'gemini-3-pro-hyper-extended': 'Gemini 3 Pro HE',
    'deepseek-v3-2': 'DeepSeek V3.2',
    'llama-4-maverick': 'Llama 4 Maverick',
    'grok-4-fast': 'Grok 4 Fast',
    'qwen3-coder-plus': 'Qwen3 Coder Plus',
}

PROMPT_TYPE_NAMES = {
    'direct': 'Direct',
    'context_protocol': 'Context Protocol',
    'context_protocol_cot': 'Context + CoT',
    'context_protocol_cot_adversarial': 'Context + CoT (Adversarial)',
    'context_protocol_cot_naturalistic': 'Context + CoT (Naturalistic)',
}


def find_detectors_with_gs(eval_dir: Path, judge: str) -> list[str]:
    """Find all detectors that have GS results for a judge."""
    judge_dir = eval_dir / judge
    if not judge_dir.exists():
        return []

    detectors = []
    for p in judge_dir.iterdir():
        if p.is_dir() and not p.name.startswith('.') and p.name not in ['all', 'ds', 'slither', 'mythril']:
            gs_dir = p / 'gs'
            if gs_dir.exists():
                detectors.append(p.name)
    return sorted(detectors)


def load_judge_results(eval_dir: Path, judge: str, detector: str, prompt_type: str) -> list[dict]:
    """Load all judge result files for a detector/prompt_type combination."""
    results_dir = eval_dir / judge / detector / 'gs' / prompt_type
    if not results_dir.exists():
        return []

    results = []
    for f in sorted(results_dir.glob('j_gs_*.json')):
        try:
            with open(f) as fp:
                results.append(json.load(fp))
        except Exception as e:
            print(f"  Warning: Failed to load {f}: {e}")
    return results


def calculate_detector_metrics(results: list[dict]) -> dict:
    """Calculate metrics for a detector from judge results."""
    if not results:
        return None

    total = len(results)

    # Target detection
    target_found = 0

    # Quality scores (only for found targets)
    rcir_scores = []
    ava_scores = []
    fsv_scores = []

    # Classification counts
    classifications = defaultdict(int)
    type_matches = defaultdict(int)

    # Verdict tracking
    verdict_correct = 0

    # Findings tracking
    total_findings = 0
    true_positives = 0
    false_positives = 0
    bonus_valid = 0

    for r in results:
        ta = r.get('target_assessment', {})

        # Check if target found - GS uses 'found' or 'complete_found'/'partial_found'
        found = ta.get('found') or ta.get('complete_found') or ta.get('partial_found', False)
        if found:
            target_found += 1

            # Quality scores
            rci = ta.get('root_cause_identification', {})
            if isinstance(rci, dict) and rci.get('score') is not None:
                rcir_scores.append(rci['score'])

            ava = ta.get('attack_vector_validity', {})
            if isinstance(ava, dict) and ava.get('score') is not None:
                ava_scores.append(ava['score'])

            fsv = ta.get('fix_suggestion_validity', {})
            if isinstance(fsv, dict) and fsv.get('score') is not None:
                fsv_scores.append(fsv['score'])

            # Type match
            tm = ta.get('type_match', 'not_mentioned')
            type_matches[tm] += 1

        # Verdict accuracy
        ov = r.get('overall_verdict', {})
        said_vuln = ov.get('said_vulnerable', False)
        # For GS, all samples are vulnerable, so correct if said_vulnerable=True
        if said_vuln:
            verdict_correct += 1

        # Findings analysis
        findings = r.get('findings', [])
        total_findings += len(findings)

        for finding in findings:
            cls = finding.get('classification', '')
            classifications[cls] += 1

            if cls in ['TARGET_MATCH', 'PARTIAL_MATCH']:
                true_positives += 1
            elif cls == 'BONUS_VALID':
                true_positives += 1
                bonus_valid += 1
            elif cls in ['HALLUCINATED', 'MISCHARACTERIZED', 'INVALID']:
                false_positives += 1

    # Calculate rates
    tdr = target_found / total if total else 0
    miss_rate = 1 - tdr
    verdict_accuracy = verdict_correct / total if total else 0
    avg_findings = total_findings / total if total else 0

    # Precision and F1
    if true_positives + false_positives > 0:
        precision = true_positives / (true_positives + false_positives)
    else:
        precision = 0

    if precision + tdr > 0:
        f1_score = 2 * (precision * tdr) / (precision + tdr)
    else:
        f1_score = 0

    # Quality averages
    avg_rcir = sum(rcir_scores) / len(rcir_scores) if rcir_scores else None
    avg_ava = sum(ava_scores) / len(ava_scores) if ava_scores else None
    avg_fsv = sum(fsv_scores) / len(fsv_scores) if fsv_scores else None

    # Bonus/ancillary rate
    samples_with_bonus = sum(1 for r in results if any(
        f.get('classification') == 'BONUS_VALID' for f in r.get('findings', [])
    ))
    ancillary_rate = samples_with_bonus / total if total else 0

    # False alarm density
    false_alarm_density = false_positives / total if total else 0

    # Invalid finding rate
    invalid_rate = false_positives / total_findings if total_findings else 0

    return {
        'samples': total,
        'target_found_count': target_found,
        'target_detection_rate': tdr,
        'precision': precision,
        'f1_score': f1_score,
        'miss_rate': miss_rate,
        'samples_with_bonus': samples_with_bonus,
        'ancillary_discovery_rate': ancillary_rate,
        'verdict_correct_count': verdict_correct,
        'verdict_accuracy': verdict_accuracy,
        'total_findings': total_findings,
        'avg_findings_per_sample': avg_findings,
        'true_positives': true_positives,
        'false_positives': false_positives,
        'invalid_finding_rate': invalid_rate,
        'false_alarm_density': false_alarm_density,
        'avg_rcir': avg_rcir,
        'avg_ava': avg_ava,
        'avg_fsv': avg_fsv,
        'classification_counts': dict(classifications),
        'type_match_distribution': dict(type_matches),
    }


def generate_prompt_type_summary(eval_dir: Path, judge: str, prompt_type: str) -> dict:
    """Generate summary for a single prompt type across all detectors."""
    detectors = find_detectors_with_gs(eval_dir, judge)

    model_rankings = []

    for detector in detectors:
        results = load_judge_results(eval_dir, judge, detector, prompt_type)
        if not results:
            continue

        metrics = calculate_detector_metrics(results)
        if metrics:
            metrics['detector'] = detector
            model_rankings.append(metrics)

    # Sort by TDR descending
    model_rankings.sort(key=lambda x: x['target_detection_rate'], reverse=True)

    # Add ranks
    for i, m in enumerate(model_rankings):
        m['rank'] = i + 1

    return {
        'dataset': 'gs',
        'subset': prompt_type,
        'judge': judge,
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'total_models': len(model_rankings),
        'model_rankings': model_rankings,
    }


def generate_readme(summary: dict, prompt_type: str) -> str:
    """Generate a README markdown file for the summary."""
    lines = []
    lines.append(f"# GS {PROMPT_TYPE_NAMES.get(prompt_type, prompt_type)} Summary")
    lines.append("")
    lines.append(f"**Judge:** {summary['judge']}")
    lines.append(f"**Generated:** {summary['generated_at']}")
    lines.append(f"**Models Evaluated:** {summary['total_models']}")
    lines.append("")

    lines.append("## Model Rankings (by TDR)")
    lines.append("")
    lines.append("| Rank | Model | TDR | Precision | F1 | Verdict Acc | RCIR | AVA | FSV |")
    lines.append("|------|-------|-----|-----------|----|-----------|----|-----|-----|")

    for m in summary['model_rankings']:
        name = MODEL_NAMES.get(m['detector'], m['detector'])
        tdr = f"{m['target_detection_rate']*100:.1f}%"
        prec = f"{m['precision']*100:.1f}%"
        f1 = f"{m['f1_score']*100:.1f}%"
        va = f"{m['verdict_accuracy']*100:.1f}%"
        rcir = f"{m['avg_rcir']:.2f}" if m['avg_rcir'] is not None else "-"
        ava = f"{m['avg_ava']:.2f}" if m['avg_ava'] is not None else "-"
        fsv = f"{m['avg_fsv']:.2f}" if m['avg_fsv'] is not None else "-"

        lines.append(f"| {m['rank']} | {name} | {tdr} | {prec} | {f1} | {va} | {rcir} | {ava} | {fsv} |")

    lines.append("")
    lines.append("## Metrics Legend")
    lines.append("")
    lines.append("- **TDR**: Target Detection Rate - % of target vulnerabilities correctly identified")
    lines.append("- **Precision**: True positives / (True positives + False positives)")
    lines.append("- **F1**: Harmonic mean of Precision and TDR")
    lines.append("- **Verdict Acc**: % of correct vulnerable/safe verdicts")
    lines.append("- **RCIR**: Root Cause Identification Rating (0-1)")
    lines.append("- **AVA**: Attack Vector Accuracy (0-1)")
    lines.append("- **FSV**: Fix Suggestion Validity (0-1)")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='Generate GS summaries per judge per prompt type')
    parser.add_argument('--eval-dir', '-e', type=Path,
                        default=Path('results/detection_evaluation/llm-judge'),
                        help='Path to llm-judge evaluation directory')
    parser.add_argument('--output-dir', '-o', type=Path,
                        default=Path('results/summaries'),
                        help='Output directory for summaries')
    parser.add_argument('--judges', '-j', nargs='+',
                        default=DEFAULT_JUDGES,
                        help='Judges to process')
    parser.add_argument('--prompt-types', '-p', nargs='+',
                        default=GS_PROMPT_TYPES,
                        help='Prompt types to process')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Verbose output')

    args = parser.parse_args()

    for judge in args.judges:
        print(f"Processing judge: {judge}")

        # Create output directory
        output_dir = args.output_dir / judge / 'gs'
        output_dir.mkdir(parents=True, exist_ok=True)

        for prompt_type in args.prompt_types:
            if args.verbose:
                print(f"  Processing prompt type: {prompt_type}")

            # Generate summary
            summary = generate_prompt_type_summary(args.eval_dir, judge, prompt_type)

            if summary['total_models'] == 0:
                if args.verbose:
                    print(f"    No results found, skipping")
                continue

            # Write JSON summary
            json_path = output_dir / f"{prompt_type}_summary.json"
            with open(json_path, 'w') as f:
                json.dump(summary, f, indent=2)

            # Write README
            readme = generate_readme(summary, prompt_type)
            readme_path = output_dir / f"{prompt_type}_README.md"
            with open(readme_path, 'w') as f:
                f.write(readme)

            print(f"  {prompt_type}: {summary['total_models']} models, written to {output_dir}")

    print("Done!")


if __name__ == '__main__':
    main()
