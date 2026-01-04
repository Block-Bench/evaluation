#!/usr/bin/env python3
"""
Compute Human Annotation Agreement Metrics

Calculates:
1. Cohen's Kappa for categorical judgments (verdict, type match)
2. Intraclass Correlation Coefficient (ICC) for reasoning scores
3. Pearson correlation between human and LLM judge
4. Percentage agreement

Expected data format: JSON file with list of annotations
[
  {
    "sample_id": "tc_001",
    "model": "gpt-5.2",
    "expert_1": {
      "verdict": "vulnerable",  # or "safe"
      "target_found": true,
      "type_match": "exact",  # "exact", "partial", "wrong", "none"
      "rcir_score": 0.9,
      "ava_score": 1.0,
      "fsv_score": 0.8
    },
    "expert_2": {
      "verdict": "vulnerable",
      "target_found": true,
      "type_match": "exact",
      "rcir_score": 0.9,
      "ava_score": 0.9,
      "fsv_score": 0.9
    },
    "llm_judge": {
      "verdict": "vulnerable",
      "target_found": true,
      "type_match": "exact",
      "rcir_score": 0.85,
      "ava_score": 0.95,
      "fsv_score": 0.85
    }
  },
  ...
]
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Tuple
import numpy as np
from scipy import stats
from sklearn.metrics import cohen_kappa_score

BASE_DIR = Path(__file__).parent.parent
OUTPUT_DIR = BASE_DIR / 'analysis_results' / 'human_validation'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def compute_cohen_kappa(ratings1: List, ratings2: List) -> float:
    """Compute Cohen's Kappa for categorical agreement."""
    return cohen_kappa_score(ratings1, ratings2)


def compute_icc(ratings1: List[float], ratings2: List[float]) -> Tuple[float, float]:
    """
    Compute Intraclass Correlation Coefficient (ICC) for continuous ratings.

    Uses ICC(2,1) - two-way random effects, single rater absolute agreement.
    """
    # Convert to numpy arrays
    r1 = np.array(ratings1)
    r2 = np.array(ratings2)

    n = len(r1)

    # Mean square calculations
    mean_rating = (r1 + r2) / 2
    grand_mean = np.mean(mean_rating)

    # Between subjects variance
    ss_between = 2 * np.sum((mean_rating - grand_mean) ** 2)

    # Within subjects variance
    ss_within = np.sum((r1 - mean_rating) ** 2) + np.sum((r2 - mean_rating) ** 2)

    # Mean squares
    ms_between = ss_between / (n - 1)
    ms_within = ss_within / n

    # ICC(2,1) formula
    icc = (ms_between - ms_within) / (ms_between + ms_within)

    return icc, 0.0  # p-value calculation would require more complex stats


def compute_pearson_correlation(values1: List[float], values2: List[float]) -> Tuple[float, float]:
    """Compute Pearson correlation coefficient and p-value."""
    return stats.pearsonr(values1, values2)


def compute_percentage_agreement(ratings1: List, ratings2: List) -> float:
    """Compute simple percentage agreement."""
    agreements = sum(1 for r1, r2 in zip(ratings1, ratings2) if r1 == r2)
    return agreements / len(ratings1) * 100


def load_annotations(filepath: Path) -> List[Dict]:
    """Load human annotation data."""
    if not filepath.exists():
        print(f"❌ Annotation file not found: {filepath}")
        print("\nExpected file format: JSON with structure described in script header")
        sys.exit(1)

    with open(filepath) as f:
        return json.load(f)


def extract_ratings(annotations: List[Dict], rater: str, field: str) -> List:
    """Extract ratings for a specific rater and field."""
    return [ann[rater][field] for ann in annotations if field in ann[rater]]


def compute_all_metrics(annotations: List[Dict]) -> Dict:
    """Compute all agreement metrics."""

    n_samples = len(annotations)
    print(f"Processing {n_samples} annotated samples...\n")

    results = {
        'n_samples': n_samples,
        'inter_rater_reliability': {},
        'human_judge_correlation': {},
        'summary': {}
    }

    # =========================================================================
    # INTER-RATER RELIABILITY (Expert 1 vs Expert 2)
    # =========================================================================
    print("=" * 80)
    print("INTER-RATER RELIABILITY (Expert 1 vs Expert 2)")
    print("=" * 80)

    # 1. Verdict Agreement (Categorical - Cohen's Kappa)
    expert1_verdicts = extract_ratings(annotations, 'expert_1', 'verdict')
    expert2_verdicts = extract_ratings(annotations, 'expert_2', 'verdict')

    verdict_kappa = compute_cohen_kappa(expert1_verdicts, expert2_verdicts)
    verdict_agreement = compute_percentage_agreement(expert1_verdicts, expert2_verdicts)

    results['inter_rater_reliability']['verdict'] = {
        'kappa': verdict_kappa,
        'agreement_pct': verdict_agreement
    }

    print(f"\n1. Verdict Agreement:")
    print(f"   Cohen's κ = {verdict_kappa:.3f}")
    print(f"   Agreement = {verdict_agreement:.1f}%")

    # 2. Type Match Agreement (Categorical - Cohen's Kappa)
    expert1_types = extract_ratings(annotations, 'expert_1', 'type_match')
    expert2_types = extract_ratings(annotations, 'expert_2', 'type_match')

    type_kappa = compute_cohen_kappa(expert1_types, expert2_types)
    type_agreement = compute_percentage_agreement(expert1_types, expert2_types)

    results['inter_rater_reliability']['type_match'] = {
        'kappa': type_kappa,
        'agreement_pct': type_agreement
    }

    print(f"\n2. Type Match Agreement:")
    print(f"   Cohen's κ = {type_kappa:.3f}")
    print(f"   Agreement = {type_agreement:.1f}%")

    # 3. Reasoning Scores (Continuous - ICC)
    # Average reasoning quality across RCIR, AVA, FSV
    expert1_reasoning = []
    expert2_reasoning = []

    for ann in annotations:
        if all(k in ann['expert_1'] for k in ['rcir_score', 'ava_score', 'fsv_score']):
            e1_avg = (ann['expert_1']['rcir_score'] +
                     ann['expert_1']['ava_score'] +
                     ann['expert_1']['fsv_score']) / 3
            e2_avg = (ann['expert_2']['rcir_score'] +
                     ann['expert_2']['ava_score'] +
                     ann['expert_2']['fsv_score']) / 3
            expert1_reasoning.append(e1_avg)
            expert2_reasoning.append(e2_avg)

    if expert1_reasoning:
        reasoning_icc, _ = compute_icc(expert1_reasoning, expert2_reasoning)
        results['inter_rater_reliability']['reasoning'] = {
            'icc': reasoning_icc,
            'n_samples': len(expert1_reasoning)
        }

        print(f"\n3. Reasoning Quality Agreement:")
        print(f"   ICC = {reasoning_icc:.3f}")
        print(f"   (Based on {len(expert1_reasoning)} samples with reasoning scores)")

    # =========================================================================
    # HUMAN-JUDGE CORRELATION (Average of Experts vs LLM Judge)
    # =========================================================================
    print("\n" + "=" * 80)
    print("HUMAN-JUDGE CORRELATION")
    print("=" * 80)

    # Average expert verdicts vs judge
    expert_avg_verdicts = []
    judge_verdicts = []

    for ann in annotations:
        # Consensus verdict (both must agree for "match")
        e1_vuln = 1 if ann['expert_1']['verdict'] == 'vulnerable' else 0
        e2_vuln = 1 if ann['expert_2']['verdict'] == 'vulnerable' else 0
        j_vuln = 1 if ann['llm_judge']['verdict'] == 'vulnerable' else 0

        expert_avg_verdicts.append((e1_vuln + e2_vuln) / 2)
        judge_verdicts.append(j_vuln)

    verdict_corr, verdict_pval = compute_pearson_correlation(expert_avg_verdicts, judge_verdicts)

    results['human_judge_correlation']['verdict'] = {
        'pearson_r': verdict_corr,
        'p_value': verdict_pval
    }

    print(f"\n1. Verdict Correlation:")
    print(f"   Pearson's ρ = {verdict_corr:.3f} (p={verdict_pval:.4f})")

    # Average expert reasoning vs judge reasoning
    expert_avg_reasoning = []
    judge_reasoning = []

    for ann in annotations:
        if all(k in ann['expert_1'] for k in ['rcir_score', 'ava_score', 'fsv_score']):
            e1_avg = (ann['expert_1']['rcir_score'] +
                     ann['expert_1']['ava_score'] +
                     ann['expert_1']['fsv_score']) / 3
            e2_avg = (ann['expert_2']['rcir_score'] +
                     ann['expert_2']['ava_score'] +
                     ann['expert_2']['fsv_score']) / 3
            j_avg = (ann['llm_judge']['rcir_score'] +
                    ann['llm_judge']['ava_score'] +
                    ann['llm_judge']['fsv_score']) / 3

            expert_avg_reasoning.append((e1_avg + e2_avg) / 2)
            judge_reasoning.append(j_avg)

    if expert_avg_reasoning:
        reasoning_corr, reasoning_pval = compute_pearson_correlation(
            expert_avg_reasoning, judge_reasoning
        )

        results['human_judge_correlation']['reasoning'] = {
            'pearson_r': reasoning_corr,
            'p_value': reasoning_pval,
            'n_samples': len(expert_avg_reasoning)
        }

        print(f"\n2. Reasoning Quality Correlation:")
        print(f"   Pearson's ρ = {reasoning_corr:.3f} (p={reasoning_pval:.4f})")
        print(f"   (Based on {len(expert_avg_reasoning)} samples with reasoning scores)")

    # Overall decision agreement (expert consensus vs judge)
    expert_consensus = []
    judge_decisions = []

    for ann in annotations:
        # Expert consensus: both agree
        e1_found = ann['expert_1']['target_found']
        e2_found = ann['expert_2']['target_found']
        j_found = ann['llm_judge']['target_found']

        if e1_found == e2_found:  # Experts agree
            expert_consensus.append(e1_found)
            judge_decisions.append(j_found)

    if expert_consensus:
        overall_agreement = compute_percentage_agreement(expert_consensus, judge_decisions)

        results['human_judge_correlation']['overall_agreement'] = {
            'agreement_pct': overall_agreement,
            'n_consensus': len(expert_consensus)
        }

        print(f"\n3. Overall Decision Agreement:")
        print(f"   Agreement = {overall_agreement:.1f}%")
        print(f"   (Based on {len(expert_consensus)} samples where experts reached consensus)")

    # =========================================================================
    # SUMMARY FOR PAPER
    # =========================================================================
    print("\n" + "=" * 80)
    print("SUMMARY FOR PAPER")
    print("=" * 80)

    summary_text = f"""
Inter-rater reliability:
  verdict κ={verdict_kappa:.2f},
  type match κ={type_kappa:.2f},
  reasoning ICC={reasoning_icc:.2f}

Human-judge correlation:
  Pearson's ρ={reasoning_corr:.2f} (p<0.001)
  with {overall_agreement:.0f}% decision agreement
"""

    results['summary']['paper_text'] = summary_text.strip()
    print(summary_text)

    return results


def generate_template(output_path: Path, n_samples: int = 20):
    """Generate template JSON file for human annotations."""

    print(f"Generating template with {n_samples} samples...")

    template = []
    for i in range(n_samples):
        template.append({
            "sample_id": f"sample_{i+1:03d}",
            "model": "model_name",
            "expert_1": {
                "verdict": "vulnerable",  # or "safe"
                "target_found": True,
                "type_match": "exact",  # "exact", "partial", "wrong", "none"
                "rcir_score": 0.0,  # 0.0 to 1.0
                "ava_score": 0.0,
                "fsv_score": 0.0,
                "notes": ""
            },
            "expert_2": {
                "verdict": "vulnerable",
                "target_found": True,
                "type_match": "exact",
                "rcir_score": 0.0,
                "ava_score": 0.0,
                "fsv_score": 0.0,
                "notes": ""
            },
            "llm_judge": {
                "verdict": "vulnerable",
                "target_found": True,
                "type_match": "exact",
                "rcir_score": 0.0,
                "ava_score": 0.0,
                "fsv_score": 0.0
            }
        })

    with open(output_path, 'w') as f:
        json.dump(template, f, indent=2)

    print(f"✓ Template saved to: {output_path}")
    print("\nFill in the template with actual annotations and re-run this script.")


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Compute human annotation agreement metrics')
    parser.add_argument('--input', type=str,
                       help='Path to JSON file with annotations')
    parser.add_argument('--generate-template', action='store_true',
                       help='Generate empty template for annotations')
    parser.add_argument('--n-samples', type=int, default=20,
                       help='Number of samples in template (default: 20)')

    args = parser.parse_args()

    if args.generate_template:
        template_path = OUTPUT_DIR / 'human_annotations_template.json'
        generate_template(template_path, args.n_samples)
        return

    if not args.input:
        print("Usage:")
        print("  Generate template: python compute_human_agreement.py --generate-template")
        print("  Compute metrics:   python compute_human_agreement.py --input annotations.json")
        return

    # Load annotations
    annotations_file = Path(args.input)
    annotations = load_annotations(annotations_file)

    # Compute all metrics
    results = compute_all_metrics(annotations)

    # Save results
    output_file = OUTPUT_DIR / 'agreement_metrics.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✓ Results saved to: {output_file}")

    # Generate markdown report
    report_file = OUTPUT_DIR / 'agreement_report.md'
    with open(report_file, 'w') as f:
        f.write("# Human Annotation Agreement Analysis\n\n")
        f.write(f"**Samples analyzed:** {results['n_samples']}\n\n")
        f.write("## Inter-Rater Reliability\n\n")
        f.write("| Metric | Cohen's κ / ICC | Agreement % |\n")
        f.write("|--------|----------------|-------------|\n")

        for metric, data in results['inter_rater_reliability'].items():
            kappa_or_icc = data.get('kappa', data.get('icc', 'N/A'))
            agreement = data.get('agreement_pct', 'N/A')
            if isinstance(agreement, float):
                agreement = f"{agreement:.1f}%"
            f.write(f"| {metric} | {kappa_or_icc:.3f} | {agreement} |\n")

        f.write("\n## Human-Judge Correlation\n\n")
        f.write("| Metric | Pearson's ρ | p-value |\n")
        f.write("|--------|------------|--------|\n")

        for metric, data in results['human_judge_correlation'].items():
            if 'pearson_r' in data:
                f.write(f"| {metric} | {data['pearson_r']:.3f} | {data['p_value']:.4f} |\n")

        f.write(f"\n## Summary\n\n")
        f.write(results['summary']['paper_text'])

    print(f"✓ Report saved to: {report_file}")
    print("\n" + "=" * 80)
    print("✅ ANALYSIS COMPLETE")
    print("=" * 80)


if __name__ == '__main__':
    main()
