#!/usr/bin/env python3
"""
Strict majority vote aggregation with rule-based location validation.

Difference from regular majority vote:
- If a judge marks target_found=true but location_match=false,
  we verify if location_claimed actually matches ground truth vulnerable_functions.
- If location_claimed doesn't match ANY ground truth function, we override to target_found=false.

This catches cases where judges were too lenient based on root cause similarity
but the model actually pointed to the wrong function.
"""

import json
import argparse
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Optional
import re


def fleiss_kappa(ratings: List[List[int]], n_categories: int = 2) -> float:
    """Calculate Fleiss' kappa for inter-rater agreement."""
    n_subjects = len(ratings)
    n_raters = len(ratings[0]) if ratings else 0

    if n_subjects == 0 or n_raters == 0:
        return 0.0

    category_counts = []
    for subject_ratings in ratings:
        counts = [0] * n_categories
        for r in subject_ratings:
            if 0 <= r < n_categories:
                counts[r] += 1
        category_counts.append(counts)

    P_i = []
    for counts in category_counts:
        sum_sq = sum(c * c for c in counts)
        p = (sum_sq - n_raters) / (n_raters * (n_raters - 1)) if n_raters > 1 else 0
        P_i.append(p)

    P_bar = sum(P_i) / n_subjects if n_subjects > 0 else 0

    total_ratings = n_subjects * n_raters
    p_j = []
    for cat in range(n_categories):
        cat_total = sum(counts[cat] for counts in category_counts)
        p_j.append(cat_total / total_ratings if total_ratings > 0 else 0)

    P_e = sum(p * p for p in p_j)

    if P_e == 1:
        return 1.0 if P_bar == 1 else 0.0

    kappa = (P_bar - P_e) / (1 - P_e)
    return kappa


def extract_function_name(location_claimed: str) -> str:
    """
    Extract function name from location_claimed.

    Examples:
    - "GrowthHYBR.deposit" -> "deposit"
    - "Contract.functionName" -> "functionName"
    - "deposit" -> "deposit"
    - "deposit()" -> "deposit"
    """
    if not location_claimed:
        return ""

    # Remove parentheses and parameters
    location = re.sub(r'\(.*\)', '', location_claimed)

    # Split by dot and take last part
    parts = location.split('.')
    func_name = parts[-1].strip()

    return func_name.lower()


def normalize_function_name(name: str) -> str:
    """Normalize function name for comparison."""
    # Remove common prefixes/suffixes, lowercase
    name = name.lower().strip()
    name = re.sub(r'\(.*\)', '', name)  # Remove params
    return name


def location_matches_ground_truth(location_claimed: str, vulnerable_functions: List[str]) -> bool:
    """
    Check if location_claimed matches at least one ground truth function.
    """
    if not location_claimed or not vulnerable_functions:
        return False

    claimed_func = extract_function_name(location_claimed)

    for gt_func in vulnerable_functions:
        gt_normalized = normalize_function_name(gt_func)
        if claimed_func == gt_normalized:
            return True
        # Also check if claimed contains gt or vice versa (partial match)
        if claimed_func in gt_normalized or gt_normalized in claimed_func:
            return True

    return False


def load_ground_truth(dataset: str, sample_id: str) -> Optional[Dict]:
    """Load ground truth for a sample."""
    # Handle different dataset paths
    if dataset == 'gs':
        gt_path = Path(f'samples/gs/ground_truth/{sample_id}.json')
    elif dataset == 'ds':
        # DS samples have tier info in the ID: ds_t1_001
        parts = sample_id.split('_')
        if len(parts) >= 3:
            tier = f"tier{parts[1][1]}"  # t1 -> tier1
            gt_path = Path(f'samples/ds/{tier}/ground_truth/{sample_id}.json')
        else:
            return None
    elif dataset == 'tc':
        # TC samples need variant info - we'll need to check metadata
        # For now, skip TC location validation (complex structure)
        return None
    else:
        return None

    if gt_path.exists():
        with open(gt_path) as f:
            return json.load(f)
    return None


def get_target_found_strict(judge_file: Path, ground_truth: Optional[Dict] = None) -> Tuple[Optional[bool], bool, Dict]:
    """
    Extract target found status with strict location validation.

    Returns:
        - target_found: bool or None if error
        - was_overridden: bool indicating if we overrode a lenient judge
        - details: dict with validation details
    """
    try:
        with open(judge_file) as f:
            data = json.load(f)

        ta = data.get('target_assessment', {})
        complete_found = ta.get('complete_found', False)
        partial_found = ta.get('partial_found', False)
        location_match = ta.get('location_match', False)
        finding_id = ta.get('finding_id')

        original_found = complete_found or partial_found

        details = {
            'original_complete': complete_found,
            'original_partial': partial_found,
            'location_match': location_match,
            'finding_id': finding_id,
            'was_overridden': False,
            'override_reason': None
        }

        # If not found, nothing to validate
        if not original_found:
            return False, False, details

        # If location already matches, trust the judge
        if location_match:
            return True, False, details

        # STRICT VALIDATION: target_found=true but location_match=false
        # Check if location_claimed actually matches ground truth

        if ground_truth is None:
            # No ground truth available, trust the judge
            return original_found, False, details

        vulnerable_functions = ground_truth.get('vulnerable_functions', [])

        if not vulnerable_functions:
            # No functions specified in ground truth, trust the judge
            return original_found, False, details

        # Get the finding that was marked as target
        findings = data.get('findings', [])
        location_claimed = None

        if finding_id is not None:
            for f in findings:
                if f.get('finding_id') == finding_id:
                    location_claimed = f.get('location_claimed', '')
                    break

        if not location_claimed:
            # No location claimed, can't validate - be conservative
            details['was_overridden'] = True
            details['override_reason'] = 'no_location_claimed'
            return False, True, details

        details['location_claimed'] = location_claimed
        details['ground_truth_functions'] = vulnerable_functions

        # Check if location matches any ground truth function
        if location_matches_ground_truth(location_claimed, vulnerable_functions):
            # Location actually matches - this is a false negative on location_match
            # Trust the judge's target_found
            details['location_validated'] = True
            return True, False, details
        else:
            # Location doesn't match ground truth - override to false
            details['was_overridden'] = True
            details['override_reason'] = 'location_mismatch'
            details['location_validated'] = False
            return False, True, details

    except Exception as e:
        return None, False, {'error': str(e)}


def aggregate_ds_strict(output_dir: Path, judges: List[str], detectors: List[str], tiers: List[str]):
    """Aggregate DS results using strict majority vote with location validation."""

    base_path = Path('results/detection_evaluation/llm-judge')

    results = {
        'summary': {},
        'per_detector': {},
        'overrides': {},
        'comparison': {}
    }

    total_overrides = 0
    total_samples_checked = 0

    for detector in detectors:
        results['per_detector'][detector] = {}
        results['overrides'][detector] = {}

        for tier in tiers:
            sample_ids = set()
            for judge in judges:
                tier_path = base_path / judge / detector / 'ds' / tier
                if tier_path.exists():
                    for f in tier_path.glob('j_ds_*.json'):
                        sample_id = f.stem.replace('j_', '')
                        sample_ids.add(sample_id)

            sample_ids = sorted(sample_ids)

            ratings_original = []
            ratings_strict = []
            override_details = []

            for sample_id in sample_ids:
                # Load ground truth
                ground_truth = load_ground_truth('ds', sample_id)

                sample_ratings_original = []
                sample_ratings_strict = []
                sample_overrides = []

                for judge in judges:
                    judge_file = base_path / judge / detector / 'ds' / tier / f'j_{sample_id}.json'

                    # Get strict result
                    found_strict, was_overridden, details = get_target_found_strict(judge_file, ground_truth)

                    if found_strict is not None:
                        sample_ratings_strict.append(1 if found_strict else 0)
                        # Also get original for comparison
                        sample_ratings_original.append(1 if (details.get('original_complete') or details.get('original_partial')) else 0)

                        if was_overridden:
                            sample_overrides.append({
                                'judge': judge,
                                'sample_id': sample_id,
                                **details
                            })

                if len(sample_ratings_strict) == len(judges):
                    ratings_strict.append(sample_ratings_strict)
                    ratings_original.append(sample_ratings_original)
                    total_samples_checked += 1

                    if sample_overrides:
                        override_details.extend(sample_overrides)
                        total_overrides += len(sample_overrides)

            # Calculate metrics for strict
            n_samples = len(ratings_strict)
            majority_found_strict = sum(1 for r in ratings_strict if sum(r) >= 2)
            majority_found_original = sum(1 for r in ratings_original if sum(r) >= 2)
            tdr_strict = majority_found_strict / n_samples * 100 if n_samples > 0 else 0
            tdr_original = majority_found_original / n_samples * 100 if n_samples > 0 else 0

            kappa_strict = fleiss_kappa(ratings_strict) if ratings_strict else 0
            kappa_original = fleiss_kappa(ratings_original) if ratings_original else 0

            unanimous_strict = sum(1 for r in ratings_strict if len(set(r)) == 1)
            unanimous_pct_strict = unanimous_strict / n_samples * 100 if n_samples > 0 else 0

            results['per_detector'][detector][tier] = {
                'n_samples': n_samples,
                'majority_found_strict': majority_found_strict,
                'majority_found_original': majority_found_original,
                'tdr_strict_pct': round(tdr_strict, 1),
                'tdr_original_pct': round(tdr_original, 1),
                'tdr_diff': round(tdr_original - tdr_strict, 1),
                'fleiss_kappa_strict': round(kappa_strict, 3),
                'fleiss_kappa_original': round(kappa_original, 3),
                'unanimous_pct_strict': round(unanimous_pct_strict, 1),
                'n_overrides': len(override_details)
            }

            results['overrides'][detector][tier] = override_details

    results['summary'] = {
        'total_overrides': total_overrides,
        'total_samples_checked': total_samples_checked
    }

    # Write outputs
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(output_dir / 'ds_strict_results.json', 'w') as f:
        json.dump(results, f, indent=2)

    write_ds_strict_summary_md(results, output_dir / 'ds_strict_summary.md', judges, detectors, tiers)
    write_comparison_table(results, output_dir / 'ds_comparison.md', detectors, tiers)

    return results


def write_ds_strict_summary_md(results: dict, output_path: Path, judges: List[str], detectors: List[str], tiers: List[str]):
    """Write a markdown summary of strict DS results."""

    detector_display = {
        'claude-opus-4-5': 'Claude',
        'gemini-3-pro': 'Gemini',
        'deepseek-v3-2': 'DeepSeek',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok',
        'llama-4-maverick': 'Llama',
        'qwen3-coder-plus': 'Qwen'
    }

    lines = [
        "# DS Strict Majority Vote Results",
        "",
        f"**Judges:** {', '.join(judges)}",
        "**Method:** Majority vote with strict location validation",
        "",
        "## Strict Rule",
        "If a judge marks `target_found=true` but `location_match=false`, we verify if",
        "`location_claimed` actually matches any function in ground truth's `vulnerable_functions`.",
        "If not, we override to `target_found=false`.",
        "",
        "## TDR by Detector and Tier (STRICT)",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " | Avg |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|------:|",
    ]

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        tdrs = []
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                tdr = results['per_detector'][detector][tier]['tdr_strict_pct']
                tdrs.append(tdr)
                row += f" {tdr:.1f} |"
            else:
                row += " - |"

        avg = sum(tdrs) / len(tdrs) if tdrs else 0
        row += f" {avg:.1f} |"
        lines.append(row)

    lines.extend([
        "",
        "## Inter-Judge Agreement (STRICT)",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|",
    ])

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                kappa = results['per_detector'][detector][tier]['fleiss_kappa_strict']
                unan = results['per_detector'][detector][tier]['unanimous_pct_strict']
                row += f" κ={kappa:.2f} ({unan:.0f}%) |"
            else:
                row += " - |"
        lines.append(row)

    lines.extend([
        "",
        f"## Override Statistics",
        f"",
        f"Total overrides: {results['summary']['total_overrides']}",
        f"Total samples checked: {results['summary']['total_samples_checked']}",
    ])

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def write_comparison_table(results: dict, output_path: Path, detectors: List[str], tiers: List[str]):
    """Write comparison between original and strict results."""

    detector_display = {
        'claude-opus-4-5': 'Claude',
        'gemini-3-pro': 'Gemini',
        'deepseek-v3-2': 'DeepSeek',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok',
        'llama-4-maverick': 'Llama',
        'qwen3-coder-plus': 'Qwen'
    }

    lines = [
        "# DS: Original vs Strict Comparison",
        "",
        "## TDR Comparison (Original → Strict)",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " | Avg Diff |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|------:|",
    ]

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        diffs = []
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                orig = results['per_detector'][detector][tier]['tdr_original_pct']
                strict = results['per_detector'][detector][tier]['tdr_strict_pct']
                diff = orig - strict
                diffs.append(diff)
                row += f" {orig:.1f}→{strict:.1f} |"
            else:
                row += " - |"

        avg_diff = sum(diffs) / len(diffs) if diffs else 0
        row += f" -{avg_diff:.1f}pp |"
        lines.append(row)

    lines.extend([
        "",
        "## Fleiss' κ Comparison (Original → Strict)",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|",
    ])

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                orig = results['per_detector'][detector][tier]['fleiss_kappa_original']
                strict = results['per_detector'][detector][tier]['fleiss_kappa_strict']
                row += f" {orig:.2f}→{strict:.2f} |"
            else:
                row += " - |"
        lines.append(row)

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description='Strict majority vote with location validation')
    parser.add_argument('--dataset', '-d', choices=['ds', 'tc', 'gs', 'all'], default='ds',
                        help='Dataset to aggregate')
    parser.add_argument('--output-dir', '-o', type=Path,
                        default=Path('results/summaries/majority_vote_strict'),
                        help='Output directory')
    args = parser.parse_args()

    judges = ['glm-4.7', 'mimo-v2-flash', 'mistral-large']
    detectors = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
                 'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

    if args.dataset in ['ds', 'all']:
        tiers = ['tier1', 'tier2', 'tier3', 'tier4']
        print("Aggregating DS results with strict location validation...")
        results = aggregate_ds_strict(args.output_dir / 'ds', judges, detectors, tiers)
        print(f"DS strict results written to {args.output_dir / 'ds'}")

        print(f"\nTotal overrides: {results['summary']['total_overrides']}")
        print(f"Total samples checked: {results['summary']['total_samples_checked']}")

        print("\n=== DS TDR Comparison (Original → Strict) ===")
        for detector in detectors:
            print(f"{detector}:", end=" ")
            for tier in tiers:
                if tier in results['per_detector'][detector]:
                    orig = results['per_detector'][detector][tier]['tdr_original_pct']
                    strict = results['per_detector'][detector][tier]['tdr_strict_pct']
                    print(f"{tier}={orig:.1f}→{strict:.1f}", end=" ")
            print()


if __name__ == '__main__':
    main()
