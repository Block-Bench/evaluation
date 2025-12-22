#!/usr/bin/env python3
"""
Comprehensive metrics aggregation across all models, prompt types, and dimensions.

This script:
1. Loads all sample_metrics from Mistral judge outputs
2. Enriches with ground truth metadata
3. Aggregates across multiple dimensions
4. Computes comprehensive evaluation metrics
5. Outputs JSON, Markdown, and CSV reports
"""

import json
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional
import statistics
from datetime import datetime

BASE_DIR = Path(__file__).parent.parent
JUDGE_DIR = BASE_DIR / 'judge_output'
GT_DIR = BASE_DIR / 'samples' / 'ground_truth'
OUTPUT_DIR = BASE_DIR / 'analysis_results'
OUTPUT_DIR.mkdir(exist_ok=True)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def load_json(filepath: Path) -> Optional[Dict]:
    """Load JSON file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        # print(f"⚠️  Error loading {filepath}: {e}")
        return None


def safe_mean(values: List[float]) -> Optional[float]:
    """Compute mean, handling empty lists."""
    if not values:
        return None
    return statistics.mean(values)


def safe_ratio(numerator: int, denominator: int) -> Optional[float]:
    """Compute ratio, handling division by zero."""
    if denominator == 0:
        return None
    return numerator / denominator


# ============================================================================
# DATA LOADING
# ============================================================================

def load_all_sample_metrics() -> List[Dict]:
    """Load all sample_metrics files from all models."""
    all_metrics = []

    for model_dir in JUDGE_DIR.iterdir():
        if not model_dir.is_dir():
            continue

        model_name = model_dir.name

        # Exclude Grok 4 Fast per user request
        if model_name == 'grok_4_fast':
            continue

        metrics_dir = model_dir / 'sample_metrics'

        if not metrics_dir.exists():
            continue

        for metrics_file in metrics_dir.glob('m_*.json'):
            data = load_json(metrics_file)
            if data:
                # Add model name to the data
                data['model_name'] = model_name
                all_metrics.append(data)

    return all_metrics


def enrich_with_ground_truth(metrics: List[Dict]) -> List[Dict]:
    """Enrich metrics with ground truth metadata."""
    enriched = []

    for m in metrics:
        sample_id = m.get('sample_id') or m.get('transformed_id')

        # Load ground truth
        gt_file = GT_DIR / f'{sample_id}.json'
        gt_data = load_json(gt_file)

        if gt_data:
            gt = gt_data.get('ground_truth', {})

            # Add ground truth fields
            m['vulnerability_type'] = gt.get('vulnerability_type', 'unknown')
            m['severity'] = gt.get('severity', 'unknown')

            # Difficulty tier
            diff_fields = gt_data.get('difficulty_fields', {})
            m['difficulty_tier'] = diff_fields.get('difficulty_tier', 0)
            m['difficulty_tier_name'] = diff_fields.get('difficulty_tier_name', 'unknown')

            # Subset
            m['subset'] = gt_data.get('subset', 'unknown')
            m['original_subset'] = gt_data.get('original_subset', 'unknown')

            # Provenance
            prov = gt_data.get('provenance', {})
            m['source'] = prov.get('source', 'unknown')

        enriched.append(m)

    return enriched


# ============================================================================
# METRICS COMPUTATION
# ============================================================================

def compute_detection_metrics(samples: List[Dict]) -> Dict:
    """Compute binary detection metrics (TP, FP, TN, FN, Precision, Recall, etc.)."""
    if not samples:
        return {}

    # Binary classification metrics
    tp = sum(1 for s in samples if s.get('ground_truth_vulnerable') and s.get('response_said_vulnerable'))
    fp = sum(1 for s in samples if not s.get('ground_truth_vulnerable') and s.get('response_said_vulnerable'))
    tn = sum(1 for s in samples if not s.get('ground_truth_vulnerable') and not s.get('response_said_vulnerable'))
    fn = sum(1 for s in samples if s.get('ground_truth_vulnerable') and not s.get('response_said_vulnerable'))

    total = len(samples)

    accuracy = safe_ratio(tp + tn, total)
    precision = safe_ratio(tp, tp + fp)
    recall = safe_ratio(tp, tp + fn)
    specificity = safe_ratio(tn, tn + fp)

    f1 = None
    if precision and recall and (precision + recall) > 0:
        f1 = 2 * (precision * recall) / (precision + recall)

    return {
        'total_samples': total,
        'true_positives': tp,
        'false_positives': fp,
        'true_negatives': tn,
        'false_negatives': fn,
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'specificity': specificity,
        'f1_score': f1
    }


def compute_target_metrics(samples: List[Dict]) -> Dict:
    """Compute target vulnerability detection metrics."""
    if not samples:
        return {}

    total = len(samples)
    vulnerable_samples = [s for s in samples if s.get('ground_truth_vulnerable')]

    target_found_count = sum(1 for s in samples if s.get('target_found'))
    target_detection_rate = safe_ratio(target_found_count, len(vulnerable_samples))

    # Type match distribution
    type_matches = [s.get('type_match', 'unknown') for s in samples if s.get('target_found')]
    type_match_dist = {
        'exact': sum(1 for tm in type_matches if tm == 'exact'),
        'semantic': sum(1 for tm in type_matches if tm == 'semantic'),
        'partial': sum(1 for tm in type_matches if tm == 'partial'),
        'none': sum(1 for tm in type_matches if tm == 'none'),
        'unknown': sum(1 for tm in type_matches if tm not in ['exact', 'semantic', 'partial', 'none'])
    }

    return {
        'total_vulnerable_samples': len(vulnerable_samples),
        'target_found_count': target_found_count,
        'target_detection_rate': target_detection_rate,
        'type_match_distribution': type_match_dist
    }


def compute_quality_metrics(samples: List[Dict]) -> Dict:
    """Compute quality scores (RCIR, AVA, FSV)."""
    if not samples:
        return {}

    # Only compute for samples where target was found
    found_samples = [s for s in samples if s.get('target_found')]

    rcir_scores = [s.get('rcir_score') for s in found_samples if s.get('rcir_score') is not None]
    ava_scores = [s.get('ava_score') for s in found_samples if s.get('ava_score') is not None]
    fsv_scores = [s.get('fsv_score') for s in found_samples if s.get('fsv_score') is not None]

    # Overall quality score (average of the three)
    overall_scores = []
    for s in found_samples:
        scores = []
        if s.get('rcir_score') is not None:
            scores.append(s['rcir_score'])
        if s.get('ava_score') is not None:
            scores.append(s['ava_score'])
        if s.get('fsv_score') is not None:
            scores.append(s['fsv_score'])
        if scores:
            overall_scores.append(statistics.mean(scores))

    return {
        'samples_with_target_found': len(found_samples),
        'avg_rcir_score': safe_mean(rcir_scores),
        'avg_ava_score': safe_mean(ava_scores),
        'avg_fsv_score': safe_mean(fsv_scores),
        'avg_overall_quality_score': safe_mean(overall_scores),
        'rcir_distribution': {
            'high (>0.8)': sum(1 for s in rcir_scores if s > 0.8),
            'medium (0.5-0.8)': sum(1 for s in rcir_scores if 0.5 <= s <= 0.8),
            'low (<0.5)': sum(1 for s in rcir_scores if s < 0.5)
        } if rcir_scores else {}
    }


def compute_finding_metrics(samples: List[Dict]) -> Dict:
    """Compute finding quality metrics."""
    if not samples:
        return {}

    total_findings = sum(s.get('total_findings', 0) for s in samples)
    valid_findings = sum(s.get('valid_findings', 0) for s in samples)
    hallucinated = sum(s.get('hallucinated_findings', 0) for s in samples)

    precision_scores = [s.get('finding_precision') for s in samples if s.get('finding_precision') is not None]

    return {
        'total_findings': total_findings,
        'valid_findings': valid_findings,
        'invalid_findings': total_findings - valid_findings,
        'hallucinated_findings': hallucinated,
        'avg_findings_per_sample': safe_ratio(total_findings, len(samples)),
        'avg_finding_precision': safe_mean(precision_scores),
        'hallucination_rate': safe_ratio(hallucinated, total_findings)
    }


def compute_confidence_metrics(samples: List[Dict]) -> Dict:
    """Compute confidence calibration metrics."""
    if not samples:
        return {}

    confidences = [s.get('confidence') for s in samples if s.get('confidence') is not None]
    calibration_errors = [s.get('calibration_error') for s in samples if s.get('calibration_error') is not None]

    # Overconfidence and underconfidence
    overconfident = sum(1 for s in samples
                       if s.get('confidence') is not None and s.get('confidence') > 0.8 and not s.get('detection_correct'))
    underconfident = sum(1 for s in samples
                        if s.get('confidence') is not None and s.get('confidence') < 0.5 and s.get('detection_correct'))

    return {
        'avg_confidence': safe_mean(confidences),
        'avg_calibration_error': safe_mean(calibration_errors),
        'overconfident_count': overconfident,
        'underconfident_count': underconfident,
        'confidence_distribution': {
            'high (>0.8)': sum(1 for c in confidences if c > 0.8),
            'medium (0.5-0.8)': sum(1 for c in confidences if 0.5 <= c <= 0.8),
            'low (<0.5)': sum(1 for c in confidences if c < 0.5)
        } if confidences else {}
    }


def compute_all_metrics(samples: List[Dict]) -> Dict:
    """Compute all metrics for a group of samples."""
    return {
        'detection': compute_detection_metrics(samples),
        'target': compute_target_metrics(samples),
        'quality': compute_quality_metrics(samples),
        'findings': compute_finding_metrics(samples),
        'confidence': compute_confidence_metrics(samples)
    }


# ============================================================================
# AGGREGATION
# ============================================================================

def aggregate_by_dimensions(metrics: List[Dict]) -> Dict:
    """Aggregate metrics across all dimensions."""

    # Get unique values for each dimension
    models = sorted(set(m['model_name'] for m in metrics))
    prompt_types = sorted(set(m.get('prompt_type', 'unknown') for m in metrics))
    vuln_types = sorted(set(m.get('vulnerability_type', 'unknown') for m in metrics))
    difficulty_tiers = sorted(set(m.get('difficulty_tier', 0) for m in metrics))
    subsets = sorted(set(m.get('subset', 'unknown') for m in metrics))

    result = {
        'metadata': {
            'generated_at': datetime.now().isoformat(),
            'total_samples': len(metrics),
            'unique_samples': len(set(m.get('sample_id') or m.get('transformed_id') for m in metrics)),
            'models_evaluated': models,
            'prompt_types': prompt_types,
            'vulnerability_types': vuln_types,
            'difficulty_tiers': difficulty_tiers,
            'subsets': subsets
        },
        'by_model': {}
    }

    # Aggregate by model
    for model in models:
        model_samples = [m for m in metrics if m['model_name'] == model]

        result['by_model'][model] = {
            'overall': {
                'all_prompts_aggregated': compute_all_metrics(model_samples)
            },
            'by_prompt_type': {},
            'by_vulnerability_type': {},
            'by_difficulty_tier': {},
            'by_subset': {},
            'cross_tabulations': {}
        }

        # By prompt type
        for prompt in prompt_types:
            prompt_samples = [m for m in model_samples if m.get('prompt_type') == prompt]
            if prompt_samples:
                result['by_model'][model]['by_prompt_type'][prompt] = compute_all_metrics(prompt_samples)

        # By vulnerability type
        for vtype in vuln_types:
            vtype_samples = [m for m in model_samples if m.get('vulnerability_type') == vtype]
            if vtype_samples:
                result['by_model'][model]['by_vulnerability_type'][vtype] = compute_all_metrics(vtype_samples)

        # By difficulty tier
        for tier in difficulty_tiers:
            tier_samples = [m for m in model_samples if m.get('difficulty_tier') == tier]
            if tier_samples:
                result['by_model'][model]['by_difficulty_tier'][f'tier_{tier}'] = compute_all_metrics(tier_samples)

        # By subset
        for subset in subsets:
            subset_samples = [m for m in model_samples if m.get('subset') == subset]
            if subset_samples:
                result['by_model'][model]['by_subset'][subset] = compute_all_metrics(subset_samples)

        # Cross-tabulations: prompt × difficulty
        result['by_model'][model]['cross_tabulations']['prompt_x_difficulty'] = {}
        for prompt in prompt_types:
            for tier in difficulty_tiers:
                samples = [m for m in model_samples
                          if m.get('prompt_type') == prompt and m.get('difficulty_tier') == tier]
                if samples:
                    key = f'{prompt}_tier_{tier}'
                    result['by_model'][model]['cross_tabulations']['prompt_x_difficulty'][key] = compute_all_metrics(samples)

        # Cross-tabulations: prompt × vulnerability type
        result['by_model'][model]['cross_tabulations']['prompt_x_vuln_type'] = {}
        for prompt in prompt_types:
            for vtype in vuln_types:
                samples = [m for m in model_samples
                          if m.get('prompt_type') == prompt and m.get('vulnerability_type') == vtype]
                if samples:
                    key = f'{prompt}_{vtype}'
                    result['by_model'][model]['cross_tabulations']['prompt_x_vuln_type'][key] = compute_all_metrics(samples)

    # Add comparative metrics
    result['comparative'] = compute_comparative_metrics(metrics, models)

    return result


def compute_comparative_metrics(metrics: List[Dict], models: List[str]) -> Dict:
    """Compute comparative metrics across models."""

    # Ranking by target detection rate
    rankings = []
    for model in models:
        model_samples = [m for m in metrics if m['model_name'] == model]
        vulnerable = [m for m in model_samples if m.get('ground_truth_vulnerable')]
        if vulnerable:
            detection_rate = safe_ratio(
                sum(1 for m in model_samples if m.get('target_found')),
                len(vulnerable)
            )
            rankings.append({
                'model': model,
                'target_detection_rate': detection_rate,
                'samples_evaluated': len(model_samples)
            })

    rankings.sort(key=lambda x: x.get('target_detection_rate') or 0, reverse=True)

    # Ranking by quality score
    quality_rankings = []
    for model in models:
        model_samples = [m for m in metrics if m['model_name'] == model and m.get('target_found')]
        if model_samples:
            quality_scores = []
            for s in model_samples:
                scores = []
                if s.get('rcir_score') is not None:
                    scores.append(s['rcir_score'])
                if s.get('ava_score') is not None:
                    scores.append(s['ava_score'])
                if s.get('fsv_score') is not None:
                    scores.append(s['fsv_score'])
                if scores:
                    quality_scores.append(statistics.mean(scores))

            if quality_scores:
                quality_rankings.append({
                    'model': model,
                    'avg_quality_score': statistics.mean(quality_scores),
                    'samples_with_target': len(model_samples)
                })

    quality_rankings.sort(key=lambda x: x.get('avg_quality_score') or 0, reverse=True)

    # Ranking by finding precision
    precision_rankings = []
    for model in models:
        model_samples = [m for m in metrics if m['model_name'] == model]
        precisions = [s.get('finding_precision') for s in model_samples if s.get('finding_precision') is not None]
        if precisions:
            precision_rankings.append({
                'model': model,
                'avg_finding_precision': statistics.mean(precisions)
            })

    precision_rankings.sort(key=lambda x: x.get('avg_finding_precision') or 0, reverse=True)

    return {
        'ranking_by_target_detection': rankings,
        'ranking_by_quality_score': quality_rankings,
        'ranking_by_finding_precision': precision_rankings
    }


# ============================================================================
# OUTPUT GENERATION
# ============================================================================

def generate_markdown_summary(aggregated: Dict) -> str:
    """Generate markdown summary report."""
    lines = []

    lines.append("# Comprehensive Model Evaluation Metrics\n")
    lines.append(f"**Generated:** {aggregated['metadata']['generated_at']}\n")
    lines.append(f"**Total Samples:** {aggregated['metadata']['total_samples']}")
    lines.append(f"**Unique Samples:** {aggregated['metadata']['unique_samples']}")
    lines.append(f"**Models Evaluated:** {', '.join(aggregated['metadata']['models_evaluated'])}\n")

    lines.append("---\n")

    # Overall Rankings
    lines.append("## 🏆 Model Rankings\n")

    lines.append("### By Target Detection Rate\n")
    lines.append("| Rank | Model | Detection Rate | Samples |")
    lines.append("|------|-------|----------------|---------|")
    for i, r in enumerate(aggregated['comparative']['ranking_by_target_detection'], 1):
        rate = r.get('target_detection_rate')
        rate_str = f"{rate:.1%}" if rate is not None else "N/A"
        lines.append(f"| {i} | {r['model']} | {rate_str} | {r['samples_evaluated']} |")
    lines.append("")

    lines.append("### By Quality Score (RCIR/AVA/FSV)\n")
    lines.append("| Rank | Model | Avg Quality | Samples with Target |")
    lines.append("|------|-------|-------------|---------------------|")
    for i, r in enumerate(aggregated['comparative']['ranking_by_quality_score'], 1):
        score = r.get('avg_quality_score')
        score_str = f"{score:.3f}" if score is not None else "N/A"
        lines.append(f"| {i} | {r['model']} | {score_str} | {r['samples_with_target']} |")
    lines.append("")

    lines.append("### By Finding Precision\n")
    lines.append("| Rank | Model | Avg Precision |")
    lines.append("|------|-------|---------------|")
    for i, r in enumerate(aggregated['comparative']['ranking_by_finding_precision'], 1):
        prec = r.get('avg_finding_precision')
        prec_str = f"{prec:.1%}" if prec is not None else "N/A"
        lines.append(f"| {i} | {r['model']} | {prec_str} |")
    lines.append("")

    lines.append("---\n")

    # Detailed metrics per model
    lines.append("## 📊 Detailed Metrics by Model\n")

    for model, model_data in aggregated['by_model'].items():
        lines.append(f"### {model}\n")

        overall = model_data['overall']['all_prompts_aggregated']

        # Detection metrics
        det = overall.get('detection', {})
        lines.append("**Detection Metrics:**")
        lines.append(f"- Accuracy: {det.get('accuracy', 0):.1%}")
        lines.append(f"- Precision: {det.get('precision', 0):.1%}")
        lines.append(f"- Recall: {det.get('recall', 0):.1%}")
        lines.append(f"- F1 Score: {det.get('f1_score', 0):.3f}")
        lines.append("")

        # Target metrics
        tgt = overall.get('target', {})
        lines.append("**Target Detection:**")
        lines.append(f"- Detection Rate: {tgt.get('target_detection_rate', 0):.1%}")
        lines.append(f"- Targets Found: {tgt.get('target_found_count', 0)} / {tgt.get('total_vulnerable_samples', 0)}")
        lines.append("")

        # Quality metrics
        qual = overall.get('quality', {})
        lines.append("**Quality Scores (when target found):**")
        rcir = qual.get('avg_rcir_score')
        ava = qual.get('avg_ava_score')
        fsv = qual.get('avg_fsv_score')
        overall_q = qual.get('avg_overall_quality_score')
        lines.append(f"- RCIR (Root Cause): {rcir:.3f}" if rcir else "- RCIR: N/A")
        lines.append(f"- AVA (Attack Vector): {ava:.3f}" if ava else "- AVA: N/A")
        lines.append(f"- FSV (Fix Suggestion): {fsv:.3f}" if fsv else "- FSV: N/A")
        lines.append(f"- Overall Quality: {overall_q:.3f}" if overall_q else "- Overall Quality: N/A")
        lines.append("")

        # Finding metrics
        find = overall.get('findings', {})
        lines.append("**Finding Quality:**")
        lines.append(f"- Avg Finding Precision: {find.get('avg_finding_precision', 0):.1%}")
        lines.append(f"- Hallucination Rate: {find.get('hallucination_rate', 0):.1%}")
        lines.append(f"- Avg Findings/Sample: {find.get('avg_findings_per_sample', 0):.1f}")
        lines.append("")

        # Performance by prompt type
        lines.append("**By Prompt Type:**")
        lines.append("| Prompt | Detection Rate | Quality Score | Finding Precision |")
        lines.append("|--------|----------------|---------------|-------------------|")
        for prompt, pdata in model_data.get('by_prompt_type', {}).items():
            tgt_p = pdata.get('target', {})
            qual_p = pdata.get('quality', {})
            find_p = pdata.get('findings', {})

            det_rate = tgt_p.get('target_detection_rate')
            qual_score = qual_p.get('avg_overall_quality_score')
            find_prec = find_p.get('avg_finding_precision')

            det_rate_str = f"{det_rate:.1%}" if det_rate is not None else "N/A"
            qual_str = f"{qual_score:.3f}" if qual_score is not None else "N/A"
            prec_str = f"{find_prec:.1%}" if find_prec is not None else "N/A"

            lines.append(f"| {prompt} | {det_rate_str} | {qual_str} | {prec_str} |")
        lines.append("")

        lines.append("---\n")

    return '\n'.join(lines)


def generate_csv_export(aggregated: Dict) -> str:
    """Generate CSV for spreadsheet analysis."""
    lines = []

    # Header
    lines.append("model,prompt_type,total_samples,accuracy,precision,recall,f1_score,target_detection_rate,avg_quality_score,avg_finding_precision,hallucination_rate")

    # Data rows
    for model, model_data in aggregated['by_model'].items():
        # Overall (all prompts)
        overall = model_data['overall']['all_prompts_aggregated']
        det = overall.get('detection', {})
        tgt = overall.get('target', {})
        qual = overall.get('quality', {})
        find = overall.get('findings', {})

        row = [
            model,
            'all',
            str(det.get('total_samples', 0)),
            f"{det.get('accuracy', 0):.4f}",
            f"{det.get('precision', 0):.4f}",
            f"{det.get('recall', 0):.4f}",
            f"{det.get('f1_score', 0):.4f}",
            f"{tgt.get('target_detection_rate', 0):.4f}",
            f"{qual.get('avg_overall_quality_score', 0):.4f}" if qual.get('avg_overall_quality_score') else "",
            f"{find.get('avg_finding_precision', 0):.4f}",
            f"{find.get('hallucination_rate', 0):.4f}"
        ]
        lines.append(','.join(row))

        # By prompt type
        for prompt, pdata in model_data.get('by_prompt_type', {}).items():
            det_p = pdata.get('detection', {})
            tgt_p = pdata.get('target', {})
            qual_p = pdata.get('quality', {})
            find_p = pdata.get('findings', {})

            row = [
                model,
                prompt,
                str(det_p.get('total_samples', 0)),
                f"{det_p.get('accuracy') or 0:.4f}",
                f"{det_p.get('precision') or 0:.4f}",
                f"{det_p.get('recall') or 0:.4f}",
                f"{det_p.get('f1_score') or 0:.4f}",
                f"{tgt_p.get('target_detection_rate') or 0:.4f}",
                f"{qual_p.get('avg_overall_quality_score') or 0:.4f}",
                f"{find_p.get('avg_finding_precision') or 0:.4f}",
                f"{find_p.get('hallucination_rate') or 0:.4f}"
            ]
            lines.append(','.join(row))

    return '\n'.join(lines)


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Main execution function."""
    print("="*80)
    print("COMPREHENSIVE METRICS AGGREGATION")
    print("="*80)
    print()

    # Step 1: Load all sample metrics
    print("📂 Loading all sample_metrics files...")
    all_metrics = load_all_sample_metrics()
    print(f"   Loaded {len(all_metrics)} sample metric records")
    print()

    # Step 2: Enrich with ground truth
    print("🔗 Enriching with ground truth metadata...")
    enriched_metrics = enrich_with_ground_truth(all_metrics)
    print(f"   Enriched {len(enriched_metrics)} records")
    print()

    # Step 3: Aggregate across all dimensions
    print("📊 Aggregating across all dimensions...")
    aggregated = aggregate_by_dimensions(enriched_metrics)
    print(f"   Aggregated data for {len(aggregated['by_model'])} models")
    print()

    # Step 4: Generate outputs
    print("💾 Generating output files...")

    # JSON output
    json_file = OUTPUT_DIR / 'aggregated_metrics.json'
    with open(json_file, 'w') as f:
        json.dump(aggregated, f, indent=2)
    print(f"   ✅ {json_file}")

    # Markdown summary
    md_file = OUTPUT_DIR / 'metrics_summary.md'
    md_content = generate_markdown_summary(aggregated)
    with open(md_file, 'w') as f:
        f.write(md_content)
    print(f"   ✅ {md_file}")

    # CSV export
    csv_file = OUTPUT_DIR / 'model_comparison.csv'
    csv_content = generate_csv_export(aggregated)
    with open(csv_file, 'w') as f:
        f.write(csv_content)
    print(f"   ✅ {csv_file}")

    print()
    print("="*80)
    print("✅ AGGREGATION COMPLETE")
    print("="*80)
    print()
    print("Summary:")
    print(f"  Total samples processed: {aggregated['metadata']['total_samples']}")
    print(f"  Unique samples: {aggregated['metadata']['unique_samples']}")
    print(f"  Models evaluated: {len(aggregated['metadata']['models_evaluated'])}")
    print()
    print("Output files:")
    print(f"  📊 Full data: {json_file}")
    print(f"  📝 Summary: {md_file}")
    print(f"  📈 CSV: {csv_file}")
    print()


if __name__ == '__main__':
    main()
