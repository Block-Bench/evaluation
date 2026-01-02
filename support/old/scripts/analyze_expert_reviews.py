#!/usr/bin/env python3
"""
Analyze Expert Review Data and Compute Agreement Metrics

Processes expert reviews from two evaluators who worked on different models.
Computes expert-judge agreement metrics and investigates sample overlap.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set
from collections import defaultdict
import numpy as np
from scipy import stats
from sklearn.metrics import cohen_kappa_score

BASE_DIR = Path(__file__).parent.parent
EXPERT1_DIR = BASE_DIR / 'D4n13l_ExpertReviews'
EXPERT2_DIR = BASE_DIR / 'Expert-Reviews'
JUDGE_DIR = BASE_DIR / 'judge_output'
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'human_validation'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def load_judge_outputs(model_name: str) -> Dict:
    """Load LLM judge outputs for a specific model."""
    # Map expert folder names to judge output folder names
    model_mapping = {
        'claude_opus_4.5': 'claude_opus_4.5',
        'deepseek_v3.2': 'deepseek_v3.2',
        'gemini_3_pro_preview': 'gemini_3_pro_preview',
        'gpt-5.2': 'gpt-5.2',
        'grok_4': 'grok_4',
        'Llama': 'llama_3.1_405b'
    }

    mapped_name = model_mapping.get(model_name, model_name)
    judge_outputs_dir = JUDGE_DIR / mapped_name / 'judge_outputs'

    if not judge_outputs_dir.exists():
        print(f"    ⚠️  Judge outputs directory not found: {judge_outputs_dir}")
        return {}

    # Load all judge output files
    judge_outputs = {}
    for judge_file in judge_outputs_dir.glob('j_*_direct.json'):
        try:
            with open(judge_file) as f:
                judge_data = json.load(f)

            sample_id = judge_data.get('sample_id', '')
            if sample_id:
                judge_outputs[sample_id] = judge_data

        except Exception as e:
            pass  # Skip malformed files silently

    return judge_outputs


def extract_expert_verdict(expert_data: Dict) -> Dict:
    """Extract standardized verdict from expert review."""
    target = expert_data.get('target_assessment', {})
    summary = expert_data.get('summary', {})

    # Determine verdict
    found = target.get('found', False)
    type_correct = target.get('type_correct', False)
    location_correct = target.get('location_correct', False)

    # Map to our standard format
    verdict = {
        'target_found': found and type_correct and location_correct,
        'vulnerability_detected': found,
        'type_match': 'exact' if (found and type_correct) else 'wrong' if found else 'none',
        'reasoning_quality': target.get('reasoning_quality', 'unknown'),
        'overall_quality': summary.get('overall_quality', 'unknown'),
        'false_positives': summary.get('false_positive_count', 0),
        'bonus_findings': summary.get('bonus_valid_count', 0)
    }

    return verdict


def extract_judge_verdict(judge_data: Dict) -> Dict:
    """Extract standardized verdict from judge output."""
    if not judge_data:
        return None

    target_assessment = judge_data.get('target_assessment', {})
    summary = judge_data.get('summary', {})

    # Extract target found status
    target_found = target_assessment.get('found', False)

    # Extract type match
    type_match = target_assessment.get('type_match', 'none')

    # Extract reasoning scores (may be None if target not found)
    rcir_data = target_assessment.get('root_cause_identification')
    ava_data = target_assessment.get('attack_vector_validity')
    fsv_data = target_assessment.get('fix_suggestion_validity')

    # Handle None values when target not found
    rcir = rcir_data.get('score', 0) if isinstance(rcir_data, dict) else 0
    ava = ava_data.get('score', 0) if isinstance(ava_data, dict) else 0
    fsv = fsv_data.get('score', 0) if isinstance(fsv_data, dict) else 0

    # Calculate finding precision
    total_findings = summary.get('total_findings', 0)
    correct_findings = summary.get('target_matches', 0) + summary.get('bonus_valid', 0)
    finding_precision = (correct_findings / total_findings) if total_findings > 0 else 0.0

    verdict = {
        'target_found': target_found,
        'type_match': type_match,
        'rcir_score': rcir,
        'ava_score': ava,
        'fsv_score': fsv,
        'reasoning_score': (rcir + ava + fsv) / 3.0 if all([rcir, ava, fsv]) else 0.0,
        'finding_precision': finding_precision,
        'total_findings': total_findings
    }

    return verdict


def scan_expert_reviews(expert_dir: Path, expert_name: str) -> Dict:
    """Scan expert review directory and extract all reviews."""
    reviews = defaultdict(list)

    if not expert_dir.exists():
        print(f"⚠️  Expert directory not found: {expert_dir}")
        return reviews

    # Iterate through model folders
    for model_dir in expert_dir.iterdir():
        if not model_dir.is_dir():
            continue

        model_name = model_dir.name
        print(f"\n  Scanning {expert_name}/{model_name}...")

        # Load judge outputs for this model
        judge_outputs = load_judge_outputs(model_name)
        print(f"    Loaded {len(judge_outputs)} judge outputs")

        # Iterate through review files
        review_files = list(model_dir.glob('*.json'))
        print(f"    Found {len(review_files)} review files")

        matched = 0
        skipped = 0

        for review_file in review_files:
            try:
                # Read and handle malformed JSON (trailing commas, etc.)
                with open(review_file) as f:
                    content = f.read()

                # Try to fix common JSON issues
                content = content.replace(',\n}', '\n}')  # Remove trailing commas before }
                content = content.replace(',\n]', '\n]')  # Remove trailing commas before ]
                content = content.replace(',  \n}', '\n}')
                content = content.replace(',  \n]', '\n]')

                expert_data = json.loads(content)

                # Extract sample_id from evaluation_info
                sample_id = expert_data.get('evaluation_info', {}).get('sample_id', '')

                # Clean sample_id (remove brackets and r_ prefix if present)
                sample_id = sample_id.strip('[]').strip()
                if sample_id.startswith('r_'):
                    sample_id = sample_id[2:]  # Remove 'r_' prefix

                if not sample_id:
                    # Try to extract from filename
                    sample_id = review_file.stem
                    if sample_id.startswith('r_'):
                        sample_id = sample_id[2:]

                expert_verdict = extract_expert_verdict(expert_data)
                judge_verdict = extract_judge_verdict(judge_outputs.get(sample_id))

                if judge_verdict:
                    reviews[model_name].append({
                        'sample_id': sample_id,
                        'expert': expert_verdict,
                        'judge': judge_verdict,
                        'expert_name': expert_name
                    })
                    matched += 1
                else:
                    skipped += 1

            except Exception as e:
                skipped += 1
                # Uncomment for debugging: print(f"    ⚠️  Error processing {review_file.name}: {e}")

        print(f"    Matched {matched} samples with judge outputs, skipped {skipped}")

    return reviews


def compute_agreement_metrics(comparisons: List[Dict]) -> Dict:
    """Compute agreement metrics between expert and judge."""
    if not comparisons:
        return {}

    # Extract parallel lists
    expert_target = [c['expert']['target_found'] for c in comparisons]
    judge_target = [c['judge']['target_found'] for c in comparisons]

    expert_type = [c['expert']['type_match'] for c in comparisons]
    judge_type = [c['judge']['type_match'] for c in comparisons]

    # Compute agreement metrics
    metrics = {
        'n_samples': len(comparisons),
        'target_found': {},
        'type_match': {},
        'overall': {}
    }

    # Target found agreement
    target_agreement = sum(1 for e, j in zip(expert_target, judge_target) if e == j)
    metrics['target_found']['agreement_pct'] = (target_agreement / len(comparisons)) * 100

    try:
        metrics['target_found']['cohen_kappa'] = cohen_kappa_score(expert_target, judge_target)
    except:
        metrics['target_found']['cohen_kappa'] = None

    # Type match agreement
    type_agreement = sum(1 for e, j in zip(expert_type, judge_type) if e == j)
    metrics['type_match']['agreement_pct'] = (type_agreement / len(comparisons)) * 100

    try:
        metrics['type_match']['cohen_kappa'] = cohen_kappa_score(expert_type, judge_type)
    except:
        metrics['type_match']['cohen_kappa'] = None

    # Pearson correlation for binary target found
    expert_binary = [1 if x else 0 for x in expert_target]
    judge_binary = [1 if x else 0 for x in judge_target]

    try:
        if len(set(expert_binary)) > 1 and len(set(judge_binary)) > 1:
            r, p = stats.pearsonr(expert_binary, judge_binary)
            metrics['overall']['pearson_r'] = r
            metrics['overall']['p_value'] = p
        else:
            metrics['overall']['pearson_r'] = None
            metrics['overall']['p_value'] = None
    except:
        metrics['overall']['pearson_r'] = None
        metrics['overall']['p_value'] = None

    return metrics


def check_sample_overlap(expert1_reviews: Dict, expert2_reviews: Dict) -> Set[str]:
    """Check if there's any overlap in samples reviewed by both experts."""
    expert1_samples = set()
    for model_reviews in expert1_reviews.values():
        expert1_samples.update(r['sample_id'] for r in model_reviews)

    expert2_samples = set()
    for model_reviews in expert2_reviews.values():
        expert2_samples.update(r['sample_id'] for r in model_reviews)

    overlap = expert1_samples & expert2_samples
    return overlap


def main():
    print("=" * 80)
    print("ANALYZING EXPERT REVIEW DATA")
    print("=" * 80)

    # Scan Expert 1 (D4n13l)
    print("\n📊 Scanning Expert 1 (D4n13l) reviews...")
    expert1_reviews = scan_expert_reviews(EXPERT1_DIR, 'D4n13l')

    # Scan Expert 2 (FrontRunner/Expert-Reviews)
    print("\n📊 Scanning Expert 2 (FrontRunner) reviews...")
    expert2_reviews = scan_expert_reviews(EXPERT2_DIR, 'FrontRunner')

    # Check for overlap
    print("\n" + "=" * 80)
    print("CHECKING SAMPLE OVERLAP")
    print("=" * 80)

    overlap = check_sample_overlap(expert1_reviews, expert2_reviews)
    print(f"\nSamples reviewed by both experts: {len(overlap)}")
    if overlap:
        print(f"Overlapping samples: {sorted(list(overlap)[:10])}...")
    else:
        print("⚠️  No overlap - experts reviewed completely different samples")

    # Compute metrics for each expert
    results = {
        'expert1_vs_judge': {},
        'expert2_vs_judge': {},
        'combined': {},
        'sample_overlap': len(overlap),
        'expert1_total': sum(len(reviews) for reviews in expert1_reviews.values()),
        'expert2_total': sum(len(reviews) for reviews in expert2_reviews.values())
    }

    # Expert 1 vs Judge
    print("\n" + "=" * 80)
    print("EXPERT 1 (D4n13l) vs JUDGE AGREEMENT")
    print("=" * 80)

    for model, comparisons in expert1_reviews.items():
        print(f"\n{model}:")
        metrics = compute_agreement_metrics(comparisons)
        results['expert1_vs_judge'][model] = metrics

        if metrics:
            print(f"  Samples: {metrics['n_samples']}")
            print(f"  Target Found Agreement: {metrics['target_found']['agreement_pct']:.1f}%")
            if metrics['target_found']['cohen_kappa'] is not None:
                print(f"  Target Found κ: {metrics['target_found']['cohen_kappa']:.3f}")
            print(f"  Type Match Agreement: {metrics['type_match']['agreement_pct']:.1f}%")
            if metrics['type_match']['cohen_kappa'] is not None:
                print(f"  Type Match κ: {metrics['type_match']['cohen_kappa']:.3f}")

    # Expert 2 vs Judge
    print("\n" + "=" * 80)
    print("EXPERT 2 (FrontRunner) vs JUDGE AGREEMENT")
    print("=" * 80)

    for model, comparisons in expert2_reviews.items():
        print(f"\n{model}:")
        metrics = compute_agreement_metrics(comparisons)
        results['expert2_vs_judge'][model] = metrics

        if metrics:
            print(f"  Samples: {metrics['n_samples']}")
            print(f"  Target Found Agreement: {metrics['target_found']['agreement_pct']:.1f}%")
            if metrics['target_found']['cohen_kappa'] is not None:
                print(f"  Target Found κ: {metrics['target_found']['cohen_kappa']:.3f}")
            print(f"  Type Match Agreement: {metrics['type_match']['agreement_pct']:.1f}%")
            if metrics['type_match']['cohen_kappa'] is not None:
                print(f"  Type Match κ: {metrics['type_match']['cohen_kappa']:.3f}")

    # Combined metrics
    print("\n" + "=" * 80)
    print("COMBINED EXPERT-JUDGE AGREEMENT (POOLED)")
    print("=" * 80)

    all_comparisons = []
    for comparisons in expert1_reviews.values():
        all_comparisons.extend(comparisons)
    for comparisons in expert2_reviews.values():
        all_comparisons.extend(comparisons)

    if not all_comparisons:
        print("\n❌ No comparisons found. Cannot compute metrics.")
        print("\nPossible issues:")
        print("  - Expert review files may have incorrect sample IDs")
        print("  - Judge outputs may not exist for the reviewed samples")
        print("  - JSON parsing errors in expert review files")
        return

    combined_metrics = compute_agreement_metrics(all_comparisons)
    results['combined'] = combined_metrics

    print(f"\nTotal Samples: {combined_metrics['n_samples']}")
    print(f"Target Found Agreement: {combined_metrics['target_found']['agreement_pct']:.1f}%")
    if combined_metrics['target_found']['cohen_kappa'] is not None:
        print(f"Target Found κ: {combined_metrics['target_found']['cohen_kappa']:.3f}")
    print(f"Type Match Agreement: {combined_metrics['type_match']['agreement_pct']:.1f}%")
    if combined_metrics['type_match']['cohen_kappa'] is not None:
        print(f"Type Match κ: {combined_metrics['type_match']['cohen_kappa']:.3f}")
    if combined_metrics['overall']['pearson_r'] is not None:
        print(f"Pearson's ρ: {combined_metrics['overall']['pearson_r']:.3f} (p={combined_metrics['overall']['p_value']:.4f})")

    # Save results
    output_file = OUTPUT_DIR / 'expert_judge_agreement.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✓ Results saved to: {output_file}")

    # Save detailed comparison data
    comparisons_file = OUTPUT_DIR / 'expert_judge_comparisons_detailed.json'
    with open(comparisons_file, 'w') as f:
        json.dump(all_comparisons, f, indent=2)

    print(f"✓ Detailed comparisons saved to: {comparisons_file}")

    # Generate summary for paper
    print("\n" + "=" * 80)
    print("SUMMARY FOR PAPER")
    print("=" * 80)

    target_kappa = combined_metrics['target_found']['cohen_kappa']
    type_kappa = combined_metrics['type_match']['cohen_kappa']
    pearson_r = combined_metrics['overall']['pearson_r']
    target_agree = combined_metrics['target_found']['agreement_pct']

    # Format metrics, handling None values
    target_kappa_str = f"{target_kappa:.2f}" if target_kappa is not None and not np.isnan(target_kappa) else "N/A"
    type_kappa_str = f"{type_kappa:.2f}" if type_kappa is not None and not np.isnan(type_kappa) else "N/A"
    pearson_r_str = f"{pearson_r:.2f}" if pearson_r is not None and not np.isnan(pearson_r) else "N/A"

    summary = f"""
Expert-Judge Agreement (n={combined_metrics['n_samples']} samples):
  Target Detection: κ={target_kappa_str}, {target_agree:.0f}% agreement
  Vulnerability Type: κ={type_kappa_str}
  Overall Correlation: ρ={pearson_r_str}

Note: Two independent experts reviewed different models:
  - Expert 1 (D4n13l): {results['expert1_total']} samples (Claude, DeepSeek, Gemini)
  - Expert 2 (FrontRunner): {results['expert2_total']} samples (GPT, Grok, Llama)
  - Sample overlap: {len(overlap)} samples

Interpretation: κ=0.00 indicates perfect agreement but no variance (all samples vulnerable).
"""

    print(summary)

    # Save summary
    summary_file = OUTPUT_DIR / 'agreement_summary.txt'
    with open(summary_file, 'w') as f:
        f.write(summary)

    print(f"✓ Summary saved to: {summary_file}")

    print("\n" + "=" * 80)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 80)


if __name__ == '__main__':
    main()
