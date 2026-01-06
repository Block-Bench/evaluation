#!/usr/bin/env python3
"""
Generate Table 1: Detection Results (DS + TC Benchmarks)

Reads from results/summaries/{judge}/ folders and generates a table
showing TDR across DS tiers and TC variants.

Table 1 format:
| Model | DS-T1 | DS-T2 | DS-T3 | DS-T4 | DS-Avg | TC-San | TC-MinSan | TC-Shape | TC-Avg |
"""

import argparse
import json
from pathlib import Path
from typing import Optional


# Configuration
DS_TIERS = ['tier1', 'tier2', 'tier3', 'tier4']
# TC variants in order of obfuscation level
TC_VARIANTS = ['minimalsanitized', 'sanitized', 'nocomments', 'chameleon_medical',
               'shapeshifter_l3', 'trojan', 'falseProphet']

# Traditional tools (baselines) - only have DS tier1 results
TRADITIONAL_TOOLS = ['slither', 'mythril']

# Model display names (short)
MODEL_NAMES = {
    'claude-opus-4-5': 'Claude',
    'gpt-5.2': 'GPT-5.2',
    'gemini-3-pro': 'Gemini',
    'deepseek-v3-2': 'DeepSeek',
    'llama-4-maverick': 'Llama',
    'grok-4-fast': 'Grok',
    'qwen3-coder-plus': 'Qwen',
    'slither': 'Slither',
    'mythril': 'Mythril',
}


EXCLUDED_FOLDERS = {'tables', 'figures', 'plan.md'}

def find_available_judges(summaries_dir: Path) -> list[str]:
    """Find all judge folders in summaries directory."""
    judges = []
    for p in summaries_dir.iterdir():
        if p.is_dir() and not p.name.startswith('.') and p.name not in EXCLUDED_FOLDERS:
            judges.append(p.name)
    return sorted(judges)


def load_summary(summaries_dir: Path, judge: str, dataset: str, subset: str) -> Optional[dict]:
    """Load a summary JSON file."""
    if dataset == 'ds':
        path = summaries_dir / judge / 'ds' / f'{subset}_summary.json'
    else:  # tc
        path = summaries_dir / judge / 'tc' / f'{subset}_summary.json'

    if path.exists():
        with open(path) as f:
            return json.load(f)
    return None


def extract_model_tdr(summary: dict) -> dict[str, float]:
    """Extract TDR for each model from a summary."""
    result = {}
    for model_data in summary.get('model_rankings', []):
        detector = model_data.get('detector')
        tdr = model_data.get('target_detection_rate', 0)
        if detector:
            result[detector] = tdr
    return result


def get_all_models(summaries_dir: Path, judges: list[str]) -> list[str]:
    """Get all unique model names across all summaries."""
    models = set()
    for judge in judges:
        for tier in DS_TIERS:
            summary = load_summary(summaries_dir, judge, 'ds', tier)
            if summary:
                for m in summary.get('model_rankings', []):
                    models.add(m.get('detector'))
    return sorted(models)


def generate_table1(summaries_dir: Path, judges: Optional[list[str]] = None,
                    average_judges: bool = True, output_format: str = 'markdown') -> str:
    """
    Generate Table 1 showing DS + TC detection results.

    Args:
        summaries_dir: Path to results/summaries/
        judges: List of judges to use (None = auto-detect all)
        average_judges: If True, average TDR across judges; if False, use first judge
        output_format: 'markdown', 'latex', or 'csv'

    Returns:
        Formatted table string
    """
    # Find judges
    available_judges = find_available_judges(summaries_dir)
    if not available_judges:
        return "Error: No judge folders found in summaries directory"

    if judges:
        judges = [j for j in judges if j in available_judges]
    else:
        judges = available_judges

    print(f"Using judges: {judges}")

    # Get all models
    all_models = get_all_models(summaries_dir, judges)
    print(f"Found models: {all_models}")

    # Collect TDR data: model -> column -> value
    data = {model: {} for model in all_models}

    # DS Tiers
    for tier in DS_TIERS:
        col_name = f"DS-T{tier[-1]}"  # tier1 -> DS-T1
        tier_tdrs = {model: [] for model in all_models}

        for judge in judges:
            summary = load_summary(summaries_dir, judge, 'ds', tier)
            if summary:
                model_tdrs = extract_model_tdr(summary)
                for model, tdr in model_tdrs.items():
                    if model in tier_tdrs:
                        tier_tdrs[model].append(tdr)

        # Average or take first
        for model in all_models:
            if tier_tdrs[model]:
                if average_judges:
                    data[model][col_name] = sum(tier_tdrs[model]) / len(tier_tdrs[model])
                else:
                    data[model][col_name] = tier_tdrs[model][0]
            else:
                data[model][col_name] = None

    # DS Average
    for model in all_models:
        ds_vals = [data[model].get(f"DS-T{i}") for i in range(1, 5)]
        ds_vals = [v for v in ds_vals if v is not None]
        if ds_vals:
            data[model]['DS-Avg'] = sum(ds_vals) / len(ds_vals)
        else:
            data[model]['DS-Avg'] = None

    # TC Variants
    tc_col_map = {
        'minimalsanitized': 'MinSan',
        'sanitized': 'San',
        'nocomments': 'NoCom',
        'chameleon_medical': 'Cham',
        'shapeshifter_l3': 'Shape',
        'trojan': 'Troj',
        'falseProphet': 'FalseP',
    }

    for variant in TC_VARIANTS:
        col_name = tc_col_map.get(variant, variant)
        variant_tdrs = {model: [] for model in all_models}

        for judge in judges:
            summary = load_summary(summaries_dir, judge, 'tc', variant)
            if summary:
                model_tdrs = extract_model_tdr(summary)
                for model, tdr in model_tdrs.items():
                    if model in variant_tdrs:
                        variant_tdrs[model].append(tdr)

        for model in all_models:
            if variant_tdrs[model]:
                if average_judges:
                    data[model][col_name] = sum(variant_tdrs[model]) / len(variant_tdrs[model])
                else:
                    data[model][col_name] = variant_tdrs[model][0]
            else:
                data[model][col_name] = None

    # TC Average
    for model in all_models:
        tc_vals = [data[model].get(tc_col_map[v]) for v in TC_VARIANTS]
        tc_vals = [v for v in tc_vals if v is not None]
        if tc_vals:
            data[model]['TC-Avg'] = sum(tc_vals) / len(tc_vals)
        else:
            data[model]['TC-Avg'] = None

    # Load traditional tools (baselines) - only from codestral, only DS tier1
    traditional_data = {}
    for tool in TRADITIONAL_TOOLS:
        traditional_data[tool] = {}
        # Load from llm-judge evaluation results
        eval_dir = summaries_dir.parent / 'detection_evaluation' / 'llm-judge' / 'codestral' / tool / 'ds' / 'tier1' / '_tier_summary.json'
        if eval_dir.exists():
            with open(eval_dir) as f:
                summary = json.load(f)
                tdr = summary.get('detection_metrics', {}).get('target_found_rate', 0)
                traditional_data[tool]['DS-T1'] = tdr
        # Set other columns to None
        for col in ['DS-T2', 'DS-T3', 'DS-T4', 'DS-Avg'] + [tc_col_map[v] for v in TC_VARIANTS] + ['TC-Avg']:
            if col not in traditional_data[tool]:
                traditional_data[tool][col] = None

    # Format output
    tc_columns = [tc_col_map[v] for v in TC_VARIANTS]
    columns = ['DS-T1', 'DS-T2', 'DS-T3', 'DS-T4', 'DS-Avg'] + tc_columns + ['TC-Avg']

    if output_format == 'markdown':
        return format_markdown(data, columns, all_models, traditional_data)
    elif output_format == 'latex':
        return format_latex(data, columns, all_models, traditional_data)
    elif output_format == 'csv':
        return format_csv(data, columns, all_models, traditional_data)
    else:
        return format_markdown(data, columns, all_models, traditional_data)


def format_value(val: Optional[float], as_percent: bool = True) -> str:
    """Format a TDR value for display."""
    if val is None:
        return '-'
    if as_percent:
        return f"{val*100:.1f}"
    return f"{val:.3f}"


def format_markdown(data: dict, columns: list, models: list, traditional_data: dict = None) -> str:
    """Format as markdown table."""
    # Header
    lines = []
    header = "| Model | " + " | ".join(columns) + " |"
    separator = "|-------|" + "|".join(["------:" for _ in columns]) + "|"
    lines.append(header)
    lines.append(separator)

    # Sort models by DS-Avg descending
    sorted_models = sorted(models, key=lambda m: data[m].get('DS-Avg') or 0, reverse=True)

    for model in sorted_models:
        display_name = MODEL_NAMES.get(model, model)
        row_vals = [format_value(data[model].get(col)) for col in columns]
        row = f"| {display_name} | " + " | ".join(row_vals) + " |"
        lines.append(row)

    # Add traditional tools as baselines
    if traditional_data:
        lines.append("|-------|" + "|".join(["------:" for _ in columns]) + "|")
        for tool in TRADITIONAL_TOOLS:
            if tool in traditional_data:
                display_name = MODEL_NAMES.get(tool, tool.capitalize())
                row_vals = [format_value(traditional_data[tool].get(col)) for col in columns]
                row = f"| {display_name} | " + " | ".join(row_vals) + " |"
                lines.append(row)

    return "\n".join(lines)


def format_latex(data: dict, columns: list, models: list, traditional_data: dict = None) -> str:
    """Format as LaTeX table."""
    lines = []
    lines.append("\\begin{table}[h]")
    lines.append("\\centering")
    lines.append("\\caption{Detection Results (DS + TC Benchmarks)}")
    lines.append("\\label{tab:detection_results}")

    col_spec = "l" + "r" * len(columns)
    lines.append(f"\\begin{{tabular}}{{{col_spec}}}")
    lines.append("\\toprule")

    # Header
    header = "Model & " + " & ".join(columns) + " \\\\"
    lines.append(header)
    lines.append("\\midrule")

    # Sort models
    sorted_models = sorted(models, key=lambda m: data[m].get('DS-Avg') or 0, reverse=True)

    for model in sorted_models:
        display_name = MODEL_NAMES.get(model, model)
        row_vals = [format_value(data[model].get(col)) for col in columns]
        row = f"{display_name} & " + " & ".join(row_vals) + " \\\\"
        lines.append(row)

    # Add traditional tools as baselines
    if traditional_data:
        lines.append("\\midrule")
        for tool in TRADITIONAL_TOOLS:
            if tool in traditional_data:
                display_name = MODEL_NAMES.get(tool, tool.capitalize())
                row_vals = [format_value(traditional_data[tool].get(col)) for col in columns]
                row = f"{display_name} & " + " & ".join(row_vals) + " \\\\"
                lines.append(row)

    lines.append("\\bottomrule")
    lines.append("\\end{tabular}")
    lines.append("\\end{table}")

    return "\n".join(lines)


def format_csv(data: dict, columns: list, models: list, traditional_data: dict = None) -> str:
    """Format as CSV."""
    lines = []
    lines.append("Model," + ",".join(columns))

    sorted_models = sorted(models, key=lambda m: data[m].get('DS-Avg') or 0, reverse=True)

    for model in sorted_models:
        display_name = MODEL_NAMES.get(model, model)
        row_vals = [format_value(data[model].get(col), as_percent=False) for col in columns]
        lines.append(f"{display_name}," + ",".join(row_vals))

    # Add traditional tools as baselines
    if traditional_data:
        for tool in TRADITIONAL_TOOLS:
            if tool in traditional_data:
                display_name = MODEL_NAMES.get(tool, tool.capitalize())
                row_vals = [format_value(traditional_data[tool].get(col), as_percent=False) for col in columns]
                lines.append(f"{display_name}," + ",".join(row_vals))

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='Generate Table 1: Detection Results')
    parser.add_argument('--summaries-dir', '-d', type=Path,
                        default=Path('results/summaries'),
                        help='Path to summaries directory')
    parser.add_argument('--judges', '-j', nargs='+',
                        help='Specific judges to use (default: all)')
    parser.add_argument('--no-average', action='store_true',
                        help='Use first judge only instead of averaging')
    parser.add_argument('--format', '-f', choices=['markdown', 'latex', 'csv'],
                        default='markdown', help='Output format')
    parser.add_argument('--output', '-o', type=Path,
                        help='Output file (default: stdout)')

    args = parser.parse_args()

    result = generate_table1(
        summaries_dir=args.summaries_dir,
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
