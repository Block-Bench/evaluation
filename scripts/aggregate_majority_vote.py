#!/usr/bin/env python3
"""
Aggregate judge results using majority vote (2-of-3) and compute inter-judge agreement.

Outputs:
- Per-tier TDR using majority vote
- Inter-judge agreement metrics (Fleiss' kappa, pairwise agreement)
- Results written to results/summaries/majority_vote/
"""

import json
import argparse
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Optional
import math


def fleiss_kappa(ratings: List[List[int]], n_categories: int = 2) -> float:
    """
    Calculate Fleiss' kappa for inter-rater agreement.

    Args:
        ratings: List of [n_raters] ratings per subject. Each rating is 0 or 1.
        n_categories: Number of categories (default 2 for binary)

    Returns:
        Fleiss' kappa value (-1 to 1)
    """
    n_subjects = len(ratings)
    n_raters = len(ratings[0]) if ratings else 0

    if n_subjects == 0 or n_raters == 0:
        return 0.0

    # Count category assignments per subject
    # For binary: count how many raters said "found" (1) vs "not found" (0)
    category_counts = []
    for subject_ratings in ratings:
        counts = [0] * n_categories
        for r in subject_ratings:
            if 0 <= r < n_categories:
                counts[r] += 1
        category_counts.append(counts)

    # Calculate P_i (agreement for each subject)
    P_i = []
    for counts in category_counts:
        sum_sq = sum(c * c for c in counts)
        p = (sum_sq - n_raters) / (n_raters * (n_raters - 1)) if n_raters > 1 else 0
        P_i.append(p)

    # Calculate P_bar (mean agreement)
    P_bar = sum(P_i) / n_subjects if n_subjects > 0 else 0

    # Calculate P_e (expected agreement by chance)
    # p_j = proportion of all ratings in category j
    total_ratings = n_subjects * n_raters
    p_j = []
    for cat in range(n_categories):
        cat_total = sum(counts[cat] for counts in category_counts)
        p_j.append(cat_total / total_ratings if total_ratings > 0 else 0)

    P_e = sum(p * p for p in p_j)

    # Fleiss' kappa
    if P_e == 1:
        return 1.0 if P_bar == 1 else 0.0

    kappa = (P_bar - P_e) / (1 - P_e)
    return kappa


def pairwise_agreement(ratings: List[List[int]]) -> Dict[str, float]:
    """Calculate pairwise agreement between judges."""
    if not ratings or len(ratings[0]) < 2:
        return {}

    n_judges = len(ratings[0])
    agreements = {}

    for i in range(n_judges):
        for j in range(i + 1, n_judges):
            agree = sum(1 for r in ratings if r[i] == r[j])
            total = len(ratings)
            agreements[f"judge_{i+1}_vs_{j+1}"] = agree / total if total > 0 else 0

    return agreements


def get_target_found(judge_file: Path) -> Optional[bool]:
    """Extract target found status from judge output file."""
    try:
        with open(judge_file) as f:
            data = json.load(f)
        ta = data.get('target_assessment', {})
        # Target is found if complete_found OR partial_found
        return ta.get('complete_found', False) or ta.get('partial_found', False)
    except Exception as e:
        return None


def aggregate_ds(output_dir: Path, judges: List[str], detectors: List[str], tiers: List[str]):
    """Aggregate DS results using majority vote."""

    base_path = Path('results/detection_evaluation/llm-judge')

    results = {
        'summary': {},
        'per_detector': {},
        'agreement': {},
        'per_sample': {}
    }

    for detector in detectors:
        results['per_detector'][detector] = {}
        results['per_sample'][detector] = {}

        for tier in tiers:
            # Collect all sample IDs that exist across all judges
            sample_ids = set()
            for judge in judges:
                tier_path = base_path / judge / detector / 'ds' / tier
                if tier_path.exists():
                    for f in tier_path.glob('j_ds_*.json'):
                        sample_id = f.stem.replace('j_', '')
                        sample_ids.add(sample_id)

            sample_ids = sorted(sample_ids)

            # Collect ratings for each sample
            ratings = []  # List of [judge1, judge2, judge3] ratings (0 or 1)
            sample_details = {}

            for sample_id in sample_ids:
                sample_ratings = []
                judge_results = {}

                for judge in judges:
                    judge_file = base_path / judge / detector / 'ds' / tier / f'j_{sample_id}.json'
                    found = get_target_found(judge_file)

                    if found is not None:
                        sample_ratings.append(1 if found else 0)
                        judge_results[judge] = found
                    else:
                        judge_results[judge] = None

                # Only include if we have ratings from all 3 judges
                if len(sample_ratings) == len(judges):
                    ratings.append(sample_ratings)

                    # Majority vote: 2+ out of 3
                    majority_found = sum(sample_ratings) >= 2
                    sample_details[sample_id] = {
                        'judge_ratings': judge_results,
                        'majority_found': majority_found,
                        'agreement': len(set(sample_ratings)) == 1  # All agree
                    }

            # Calculate metrics
            n_samples = len(ratings)
            majority_found_count = sum(1 for r in ratings if sum(r) >= 2)
            tdr = majority_found_count / n_samples * 100 if n_samples > 0 else 0

            # Calculate agreement
            kappa = fleiss_kappa(ratings) if ratings else 0
            pairwise = pairwise_agreement(ratings) if ratings else {}
            unanimous = sum(1 for r in ratings if len(set(r)) == 1)
            unanimous_pct = unanimous / n_samples * 100 if n_samples > 0 else 0

            results['per_detector'][detector][tier] = {
                'n_samples': n_samples,
                'majority_found': majority_found_count,
                'tdr_pct': round(tdr, 1),
                'fleiss_kappa': round(kappa, 3),
                'unanimous_pct': round(unanimous_pct, 1),
                'pairwise_agreement': {k: round(v, 3) for k, v in pairwise.items()}
            }

            results['per_sample'][detector][tier] = sample_details

    # Calculate overall summary per tier
    for tier in tiers:
        tier_total_samples = 0
        tier_total_found = 0
        all_ratings = []

        for detector in detectors:
            if tier in results['per_detector'][detector]:
                tier_data = results['per_detector'][detector][tier]
                tier_total_samples += tier_data['n_samples']
                tier_total_found += tier_data['majority_found']

        results['summary'][tier] = {
            'total_samples_evaluated': tier_total_samples,
            'total_majority_found': tier_total_found
        }

    # Write outputs
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write detailed JSON
    with open(output_dir / 'ds_majority_vote_results.json', 'w') as f:
        json.dump(results, f, indent=2)

    # Write summary markdown
    write_ds_summary_md(results, output_dir / 'ds_summary.md', judges, detectors, tiers)

    return results


def write_ds_summary_md(results: dict, output_path: Path, judges: List[str], detectors: List[str], tiers: List[str]):
    """Write a markdown summary of DS results."""

    lines = [
        "# DS Majority Vote Results",
        "",
        f"**Judges:** {', '.join(judges)}",
        f"**Method:** Majority vote (2-of-3 judges must agree target was found)",
        "",
        "## TDR by Detector and Tier",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " | Avg |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|------:|",
    ]

    detector_display = {
        'claude-opus-4-5': 'Claude',
        'gemini-3-pro': 'Gemini',
        'deepseek-v3-2': 'DeepSeek',
        'gpt-5.2': 'GPT-5.2',
        'grok-4-fast': 'Grok',
        'llama-4-maverick': 'Llama',
        'qwen3-coder-plus': 'Qwen'
    }

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        tdrs = []
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                tdr = results['per_detector'][detector][tier]['tdr_pct']
                tdrs.append(tdr)
                row += f" {tdr:.1f} |"
            else:
                row += " - |"

        avg = sum(tdrs) / len(tdrs) if tdrs else 0
        row += f" {avg:.1f} |"
        lines.append(row)

    lines.extend([
        "",
        "## Inter-Judge Agreement",
        "",
        "| Detector | " + " | ".join([t.replace('tier', 'T') for t in tiers]) + " |",
        "|----------|" + "|".join(["------:" for _ in tiers]) + "|",
    ])

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        for tier in tiers:
            if tier in results['per_detector'][detector]:
                kappa = results['per_detector'][detector][tier]['fleiss_kappa']
                unan = results['per_detector'][detector][tier]['unanimous_pct']
                row += f" κ={kappa:.2f} ({unan:.0f}% unan) |"
            else:
                row += " - |"
        lines.append(row)

    lines.extend([
        "",
        "## Legend",
        "- **TDR**: Target Detection Rate (% of samples where majority of judges found target)",
        "- **κ**: Fleiss' kappa (inter-rater agreement, -1 to 1, >0.6 is substantial)",
        "- **unan**: Percentage of samples where all 3 judges agreed",
    ])

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def aggregate_tc(output_dir: Path, judges: List[str], detectors: List[str], variants: List[str]):
    """Aggregate TC results using majority vote."""

    base_path = Path('results/detection_evaluation/llm-judge')

    results = {
        'summary': {},
        'per_detector': {},
        'agreement': {},
        'per_sample': {}
    }

    for detector in detectors:
        results['per_detector'][detector] = {}
        results['per_sample'][detector] = {}

        for variant in variants:
            # Collect all sample IDs that exist across all judges
            sample_ids = set()
            for judge in judges:
                variant_path = base_path / judge / detector / 'tc' / variant
                if variant_path.exists():
                    for f in variant_path.glob('j_*.json'):
                        sample_id = f.stem.replace('j_', '')
                        sample_ids.add(sample_id)

            sample_ids = sorted(sample_ids)

            # Collect ratings for each sample
            ratings = []
            sample_details = {}

            for sample_id in sample_ids:
                sample_ratings = []
                judge_results = {}

                for judge in judges:
                    judge_file = base_path / judge / detector / 'tc' / variant / f'j_{sample_id}.json'
                    found = get_target_found(judge_file)

                    if found is not None:
                        sample_ratings.append(1 if found else 0)
                        judge_results[judge] = found
                    else:
                        judge_results[judge] = None

                # Only include if we have ratings from all 3 judges
                if len(sample_ratings) == len(judges):
                    ratings.append(sample_ratings)

                    majority_found = sum(sample_ratings) >= 2
                    sample_details[sample_id] = {
                        'judge_ratings': judge_results,
                        'majority_found': majority_found,
                        'agreement': len(set(sample_ratings)) == 1
                    }

            # Calculate metrics
            n_samples = len(ratings)
            majority_found_count = sum(1 for r in ratings if sum(r) >= 2)
            tdr = majority_found_count / n_samples * 100 if n_samples > 0 else 0

            kappa = fleiss_kappa(ratings) if ratings else 0
            pairwise = pairwise_agreement(ratings) if ratings else {}
            unanimous = sum(1 for r in ratings if len(set(r)) == 1)
            unanimous_pct = unanimous / n_samples * 100 if n_samples > 0 else 0

            results['per_detector'][detector][variant] = {
                'n_samples': n_samples,
                'majority_found': majority_found_count,
                'tdr_pct': round(tdr, 1),
                'fleiss_kappa': round(kappa, 3),
                'unanimous_pct': round(unanimous_pct, 1),
                'pairwise_agreement': {k: round(v, 3) for k, v in pairwise.items()}
            }

            results['per_sample'][detector][variant] = sample_details

    # Write outputs
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(output_dir / 'tc_majority_vote_results.json', 'w') as f:
        json.dump(results, f, indent=2)

    write_tc_summary_md(results, output_dir / 'tc_summary.md', judges, detectors, variants)

    return results


def write_tc_summary_md(results: dict, output_path: Path, judges: List[str], detectors: List[str], variants: List[str]):
    """Write a markdown summary of TC results."""

    variant_display = {
        'minimalsanitized': 'MinSan',
        'sanitized': 'San',
        'nocomments': 'NoCom',
        'chameleon_medical': 'Cham',
        'shapeshifter_l3': 'Shape',
        'trojan': 'Troj',
        'falseProphet': 'FalseP'
    }

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
        "# TC Majority Vote Results",
        "",
        f"**Judges:** {', '.join(judges)}",
        f"**Method:** Majority vote (2-of-3 judges must agree target was found)",
        "",
        "## TDR by Detector and Variant",
        "",
        "| Detector | " + " | ".join([variant_display.get(v, v) for v in variants]) + " | Avg |",
        "|----------|" + "|".join(["------:" for _ in variants]) + "|------:|",
    ]

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        tdrs = []
        for variant in variants:
            if variant in results['per_detector'][detector]:
                tdr = results['per_detector'][detector][variant]['tdr_pct']
                tdrs.append(tdr)
                row += f" {tdr:.1f} |"
            else:
                row += " - |"

        avg = sum(tdrs) / len(tdrs) if tdrs else 0
        row += f" {avg:.1f} |"
        lines.append(row)

    lines.extend([
        "",
        "## Inter-Judge Agreement (Fleiss' κ)",
        "",
        "| Detector | " + " | ".join([variant_display.get(v, v) for v in variants]) + " |",
        "|----------|" + "|".join(["------:" for _ in variants]) + "|",
    ])

    for detector in detectors:
        display_name = detector_display.get(detector, detector)
        row = f"| {display_name} |"
        for variant in variants:
            if variant in results['per_detector'][detector]:
                kappa = results['per_detector'][detector][variant]['fleiss_kappa']
                row += f" {kappa:.2f} |"
            else:
                row += " - |"
        lines.append(row)

    lines.extend([
        "",
        "## Legend",
        "- **TDR**: Target Detection Rate (% of samples where majority of judges found target)",
        "- **κ**: Fleiss' kappa (inter-rater agreement, -1 to 1, >0.6 is substantial)",
        "",
        "## Variant Descriptions",
        "- **MinSan**: Minimal sanitization (comments removed, formatting standardized)",
        "- **San**: Full sanitization (identifiers renamed, structure preserved)",
        "- **NoCom**: Comments removed only",
        "- **Cham**: Chameleon Medical (domain recontextualization to medical)",
        "- **Shape**: ShapeShifter L3 (code restructuring/obfuscation)",
        "- **Troj**: Trojan (hidden vulnerability variants)",
        "- **FalseP**: False Prophet (misleading comments added)",
    ])

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description='Aggregate judge results using majority vote')
    parser.add_argument('--dataset', '-d', choices=['ds', 'tc', 'gs', 'all'], default='ds',
                        help='Dataset to aggregate')
    parser.add_argument('--output-dir', '-o', type=Path,
                        default=Path('results/summaries/majority_vote'),
                        help='Output directory')
    args = parser.parse_args()

    judges = ['glm-4.7', 'mimo-v2-flash', 'mistral-large']
    detectors = ['claude-opus-4-5', 'deepseek-v3-2', 'gemini-3-pro', 'gpt-5.2',
                 'grok-4-fast', 'llama-4-maverick', 'qwen3-coder-plus']

    if args.dataset in ['ds', 'all']:
        tiers = ['tier1', 'tier2', 'tier3', 'tier4']
        print("Aggregating DS results...")
        results = aggregate_ds(args.output_dir / 'ds', judges, detectors, tiers)
        print(f"DS results written to {args.output_dir / 'ds'}")

        print("\n=== DS TDR (Majority Vote) ===")
        for detector in detectors:
            print(f"{detector}:", end=" ")
            for tier in tiers:
                if tier in results['per_detector'][detector]:
                    tdr = results['per_detector'][detector][tier]['tdr_pct']
                    print(f"{tier}={tdr:.1f}%", end=" ")
            print()

    if args.dataset in ['tc', 'all']:
        # Order as per plan.md: MinSan, San, NoCom, Cham, Shape, Troj, FalseP
        variants = ['minimalsanitized', 'sanitized', 'nocomments', 'chameleon_medical',
                    'shapeshifter_l3', 'trojan', 'falseProphet']
        print("\nAggregating TC results...")
        results = aggregate_tc(args.output_dir / 'tc', judges, detectors, variants)
        print(f"TC results written to {args.output_dir / 'tc'}")

        print("\n=== TC TDR (Majority Vote) ===")
        for detector in detectors:
            print(f"{detector}:", end=" ")
            for variant in variants:
                if variant in results['per_detector'][detector]:
                    tdr = results['per_detector'][detector][variant]['tdr_pct']
                    short = {'minimalsanitized': 'MS', 'sanitized': 'S', 'nocomments': 'NC',
                             'chameleon_medical': 'CM', 'shapeshifter_l3': 'SH',
                             'trojan': 'TR', 'falseProphet': 'FP'}.get(variant, variant[:2])
                    print(f"{short}={tdr:.1f}%", end=" ")
            print()


if __name__ == '__main__':
    main()
