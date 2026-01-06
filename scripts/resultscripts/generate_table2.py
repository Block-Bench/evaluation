#!/usr/bin/env python3
"""
Generate Table 2: Prompt Protocol Results (GS Benchmark)

Reads from results/detection_evaluation/llm-judge/ folders and generates a table
showing TDR across different prompt protocols for the Gold Standard dataset.

Table 2 format:
| Model | Direct | Context | CoT | CoT-Adversarial | CoT-Naturalistic |
"""

import argparse
import json
from pathlib import Path
from typing import Optional


# Configuration
GS_PROTOCOLS = ['direct', 'context_protocol', 'context_protocol_cot',
                'context_protocol_cot_adversarial', 'context_protocol_cot_naturalistic']

PROTOCOL_DISPLAY = {
    'direct': 'Direct',
    'context_protocol': 'Context',
    'context_protocol_cot': 'CoT',
    'context_protocol_cot_adversarial': 'CoT-Adv',
    'context_protocol_cot_naturalistic': 'CoT-Nat',
}

# Model display names (short)
MODEL_NAMES = {
    'claude-opus-4-5': 'Claude',
    'gpt-5.2': 'GPT-5.2',
    'gemini-3-pro': 'Gemini',
    'gemini-3-pro-hyper-extended': 'Gemini-HE',
    'deepseek-v3-2': 'DeepSeek',
    'llama-4-maverick': 'Llama',
    'grok-4-fast': 'Grok',
    'qwen3-coder-plus': 'Qwen',
}

# Default judges to average
DEFAULT_JUDGES = ['codestral', 'gemini-3-flash', 'mimo-v2-flash']


def find_available_judges(eval_dir: Path) -> list[str]:
    """Find all judge folders in evaluation directory."""
    judges = []
    for p in eval_dir.iterdir():
        if p.is_dir() and not p.name.startswith('.'):
            judges.append(p.name)
    return sorted(judges)


def find_available_detectors(eval_dir: Path, judge: str) -> list[str]:
    """Find all detector folders for a judge."""
    judge_dir = eval_dir / judge
    if not judge_dir.exists():
        return []
    detectors = []
    for p in judge_dir.iterdir():
        if p.is_dir() and not p.name.startswith('.') and p.name != 'all':
            # Check if has GS results
            gs_dir = p / 'gs'
            if gs_dir.exists():
                detectors.append(p.name)
    return sorted(detectors)


def load_gs_protocol_summary(eval_dir: Path, judge: str, detector: str, protocol: str) -> Optional[dict]:
    """Load a GS protocol summary JSON file, or compute from individual files."""
    path = eval_dir / judge / detector / 'gs' / protocol / '_prompt_summary.json'
    if path.exists():
        with open(path) as f:
            return json.load(f)

    # Fallback: compute from individual judge files
    protocol_dir = eval_dir / judge / detector / 'gs' / protocol
    if not protocol_dir.exists():
        return None

    judge_files = list(protocol_dir.glob('j_*.json'))
    if not judge_files:
        return None

    target_found = 0
    total = len(judge_files)

    for jf in judge_files:
        try:
            with open(jf) as f:
                jdata = json.load(f)
                ta = jdata.get('target_assessment', {})
                if ta.get('complete_found') or ta.get('partial_found'):
                    target_found += 1
        except:
            continue

    if total == 0:
        return None

    return {
        'detection_metrics': {
            'target_detection_rate': target_found / total,
            'target_found_count': target_found,
        },
        'sample_counts': {
            'total': total
        }
    }


def get_all_detectors(eval_dir: Path, judges: list[str]) -> list[str]:
    """Get all unique detector names across all judges."""
    detectors = set()
    for judge in judges:
        for det in find_available_detectors(eval_dir, judge):
            detectors.add(det)
    return sorted(detectors)


def generate_table2(eval_dir: Path, judges: Optional[list[str]] = None,
                    average_judges: bool = True, output_format: str = 'markdown') -> str:
    """
    Generate Table 2 showing GS protocol detection results.

    Args:
        eval_dir: Path to results/detection_evaluation/llm-judge/
        judges: List of judges to use (None = use defaults)
        average_judges: If True, average TDR across judges; if False, use first judge
        output_format: 'markdown', 'latex', or 'csv'

    Returns:
        Formatted table string
    """
    # Find judges
    available_judges = find_available_judges(eval_dir)
    if not available_judges:
        return "Error: No judge folders found in evaluation directory"

    if judges:
        judges = [j for j in judges if j in available_judges]
    else:
        judges = [j for j in DEFAULT_JUDGES if j in available_judges]

    if not judges:
        judges = available_judges[:3]  # Use first 3 available

    print(f"Using judges: {judges}")

    # Get all detectors
    all_detectors = get_all_detectors(eval_dir, judges)
    print(f"Found detectors: {all_detectors}")

    # Collect TDR data: detector -> protocol -> value
    data = {det: {} for det in all_detectors}

    for protocol in GS_PROTOCOLS:
        col_name = PROTOCOL_DISPLAY.get(protocol, protocol)
        protocol_tdrs = {det: [] for det in all_detectors}

        for judge in judges:
            for det in all_detectors:
                summary = load_gs_protocol_summary(eval_dir, judge, det, protocol)
                if summary:
                    tdr = summary.get('detection_metrics', {}).get('target_detection_rate', 0)
                    protocol_tdrs[det].append(tdr)

        # Average or take first
        for det in all_detectors:
            if protocol_tdrs[det]:
                if average_judges:
                    data[det][col_name] = sum(protocol_tdrs[det]) / len(protocol_tdrs[det])
                else:
                    data[det][col_name] = protocol_tdrs[det][0]
            else:
                data[det][col_name] = None

    # Calculate average across protocols
    for det in all_detectors:
        protocol_vals = [data[det].get(PROTOCOL_DISPLAY[p]) for p in GS_PROTOCOLS]
        protocol_vals = [v for v in protocol_vals if v is not None]
        if protocol_vals:
            data[det]['Avg'] = sum(protocol_vals) / len(protocol_vals)
        else:
            data[det]['Avg'] = None

    # Format output
    columns = [PROTOCOL_DISPLAY[p] for p in GS_PROTOCOLS] + ['Avg']

    if output_format == 'markdown':
        return format_markdown(data, columns, all_detectors)
    elif output_format == 'latex':
        return format_latex(data, columns, all_detectors)
    elif output_format == 'csv':
        return format_csv(data, columns, all_detectors)
    else:
        return format_markdown(data, columns, all_detectors)


def format_value(val: Optional[float], as_percent: bool = True) -> str:
    """Format a TDR value for display."""
    if val is None:
        return '-'
    if as_percent:
        return f"{val*100:.1f}"
    return f"{val:.3f}"


def format_markdown(data: dict, columns: list, detectors: list) -> str:
    """Format as markdown table."""
    lines = []
    header = "| Model | " + " | ".join(columns) + " |"
    separator = "|-------|" + "|".join(["------:" for _ in columns]) + "|"
    lines.append(header)
    lines.append(separator)

    # Sort detectors by average descending
    sorted_detectors = sorted(detectors, key=lambda d: data[d].get('Avg') or 0, reverse=True)

    for det in sorted_detectors:
        display_name = MODEL_NAMES.get(det, det)
        row_vals = [format_value(data[det].get(col)) for col in columns]
        row = f"| {display_name} | " + " | ".join(row_vals) + " |"
        lines.append(row)

    return "\n".join(lines)


def format_latex(data: dict, columns: list, detectors: list) -> str:
    """Format as LaTeX table."""
    lines = []
    lines.append("\\begin{table}[h]")
    lines.append("\\centering")
    lines.append("\\caption{Prompt Protocol Results (GS Benchmark)}")
    lines.append("\\label{tab:gs_protocol_results}")

    col_spec = "l" + "r" * len(columns)
    lines.append(f"\\begin{{tabular}}{{{col_spec}}}")
    lines.append("\\toprule")

    # Header
    header = "Model & " + " & ".join(columns) + " \\\\"
    lines.append(header)
    lines.append("\\midrule")

    # Sort detectors
    sorted_detectors = sorted(detectors, key=lambda d: data[d].get('Avg') or 0, reverse=True)

    for det in sorted_detectors:
        display_name = MODEL_NAMES.get(det, det)
        row_vals = [format_value(data[det].get(col)) for col in columns]
        row = f"{display_name} & " + " & ".join(row_vals) + " \\\\"
        lines.append(row)

    lines.append("\\bottomrule")
    lines.append("\\end{tabular}")
    lines.append("\\end{table}")

    return "\n".join(lines)


def format_csv(data: dict, columns: list, detectors: list) -> str:
    """Format as CSV."""
    lines = []
    lines.append("Model," + ",".join(columns))

    sorted_detectors = sorted(detectors, key=lambda d: data[d].get('Avg') or 0, reverse=True)

    for det in sorted_detectors:
        display_name = MODEL_NAMES.get(det, det)
        row_vals = [format_value(data[det].get(col), as_percent=False) for col in columns]
        lines.append(f"{display_name}," + ",".join(row_vals))

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='Generate Table 2: GS Protocol Results')
    parser.add_argument('--eval-dir', '-d', type=Path,
                        default=Path('results/detection_evaluation/llm-judge'),
                        help='Path to llm-judge evaluation directory')
    parser.add_argument('--judges', '-j', nargs='+',
                        help='Specific judges to use (default: codestral, gemini-3-flash, mimo-v2-flash)')
    parser.add_argument('--no-average', action='store_true',
                        help='Use first judge only instead of averaging')
    parser.add_argument('--format', '-f', choices=['markdown', 'latex', 'csv'],
                        default='markdown', help='Output format')
    parser.add_argument('--output', '-o', type=Path,
                        help='Output file (default: stdout)')

    args = parser.parse_args()

    result = generate_table2(
        eval_dir=args.eval_dir,
        judges=args.judges,
        average_judges=not args.no_average,
        output_format=args.format
    )

    if args.output:
        args.output.write_text(result)
        print(f"Written to {args.output}")
    else:
        print(result)


if __name__ == '__main__':
    main()
