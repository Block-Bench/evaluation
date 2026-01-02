#!/usr/bin/env python3
"""
Comprehensive comparison of Expert Reviews vs Mistral Judge Outputs

This script performs multi-dimensional analysis to assess agreement between
human expert evaluations and automated LLM judge evaluations.

Output:
- Detailed JSON comparison file
- Markdown summary report
- CSV export for further analysis
- Data quality report
"""

import json
import os
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional, Tuple
import statistics

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = Path(__file__).parent.parent
EXPERT_DIRS = [
    BASE_DIR / 'Expert-Reviews',
    BASE_DIR / 'D4n13l_ExpertReviews'
]
JUDGE_DIR = BASE_DIR / 'judge_output'
OUTPUT_DIR = BASE_DIR / 'analysis_results'
OUTPUT_DIR.mkdir(exist_ok=True)

# Model name mapping (expert folder name -> judge evaluated_model name)
MODEL_NAME_MAPPING = {
    'claude_opus_4.5': 'claude_opus_4.5',
    'deepseek_v3.2': 'deepseek_v3.2',
    'gemini_3_pro_preview': 'gemini_3_pro_preview',
    'gpt-5.2': 'gpt-5.2',
    'grok_4': 'grok_4',
    'Llama': 'llama_3.1_405b'
}


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def load_json(filepath: Path) -> Optional[Dict]:
    """Load JSON file with error handling."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"⚠️  JSON Error in {filepath.name}: {e}")
        return None
    except Exception as e:
        print(f"⚠️  Error loading {filepath.name}: {e}")
        return None


def extract_sample_id(filename: str) -> str:
    """Extract sample ID from filename."""
    # Remove prefix (r_ or j_) and suffix (.json)
    name = filename.replace('r_', '').replace('j_', '').replace('.json', '')
    # Remove _direct, _adversarial, _naturalistic if present
    for suffix in ['_direct', '__direct', '_adversarial', '_naturalistic']:
        name = name.replace(suffix, '')
    return name


# ============================================================================
# DATA EXTRACTION FUNCTIONS
# ============================================================================

def get_expert_verdict(expert_data: Dict) -> Dict:
    """Extract structured verdict from expert review."""
    if not expert_data:
        return None

    target = expert_data.get('target_assessment', {})
    summary = expert_data.get('summary', {})

    # Handle inconsistencies: prefer target_assessment over summary
    found = target.get('found')
    classification = target.get('classification', '')

    # Normalize classification
    if classification == 'FOUND' or found is True:
        verdict = 'FOUND'
    elif classification == 'PARTIAL':
        verdict = 'PARTIAL'
    elif classification == 'MISSED' or found is False:
        verdict = 'MISSED'
    else:
        verdict = 'UNKNOWN'

    # Check for internal inconsistency
    summary_found = summary.get('target_found')
    inconsistent = (found != summary_found) if (found is not None and summary_found is not None) else False

    return {
        'verdict': verdict,
        'type_correct': target.get('type_correct'),
        'location_correct': target.get('location_correct'),
        'reasoning_quality': target.get('reasoning_quality', ''),
        'bonus_valid_count': summary.get('bonus_valid_count', 0),
        'false_positive_count': summary.get('false_positive_count', 0),
        'hallucination_count': summary.get('hallucination_count', 0),
        'overall_quality': summary.get('overall_quality', ''),
        'notes': target.get('notes', ''),
        'inconsistent': inconsistent,
        'raw_found': found,
        'raw_summary_found': summary_found
    }


def get_judge_verdict(judge_data: Dict) -> Dict:
    """Extract structured verdict from Mistral judge output."""
    if not judge_data:
        return None

    target = judge_data.get('target_assessment', {})
    summary = judge_data.get('summary', {})
    overall = judge_data.get('overall_verdict', {})

    found = target.get('found')
    type_match = target.get('type_match', '')

    # Normalize verdict
    if found is True:
        if type_match in ['exact', 'semantic']:
            verdict = 'FOUND'
        elif type_match == 'partial':
            verdict = 'PARTIAL'
        else:
            verdict = 'FOUND'
    elif found is False:
        verdict = 'MISSED'
    else:
        verdict = 'UNKNOWN'

    # Extract quality scores
    rcir = target.get('root_cause_identification', {})
    ava = target.get('attack_vector_validity', {})
    fsv = target.get('fix_suggestion_validity', {})

    return {
        'verdict': verdict,
        'type_match': type_match,
        'said_vulnerable': overall.get('said_vulnerable'),
        'confidence': overall.get('confidence_expressed'),
        'root_cause_score': rcir.get('score') if isinstance(rcir, dict) else None,
        'attack_vector_score': ava.get('score') if isinstance(ava, dict) else None,
        'fix_suggestion_score': fsv.get('score') if isinstance(fsv, dict) else None,
        'bonus_valid_count': summary.get('bonus_valid', 0),
        'hallucinated_count': summary.get('hallucinated', 0),
        'total_findings': summary.get('total_findings', 0),
        'target_matches': summary.get('target_matches', 0),
        'notes': judge_data.get('notes', '')
    }


# ============================================================================
# COMPARISON FUNCTIONS
# ============================================================================

def compare_verdicts(expert: Dict, judge: Dict) -> Dict:
    """Compare primary verdict agreement."""
    if not expert or not judge:
        return {'agreement': None, 'expert': None, 'judge': None}

    expert_verdict = expert['verdict']
    judge_verdict = judge['verdict']

    # Exact match
    exact_match = expert_verdict == judge_verdict

    # Allow FOUND/PARTIAL as similar
    lenient_match = exact_match or (
        expert_verdict in ['FOUND', 'PARTIAL'] and judge_verdict in ['FOUND', 'PARTIAL']
    )

    return {
        'agreement': 'exact' if exact_match else ('lenient' if lenient_match else 'disagree'),
        'expert': expert_verdict,
        'judge': judge_verdict,
        'exact_match': exact_match,
        'lenient_match': lenient_match
    }


def compare_type_correctness(expert: Dict, judge: Dict) -> Dict:
    """Compare vulnerability type identification."""
    if not expert or not judge:
        return None

    expert_correct = expert.get('type_correct')
    judge_match = judge.get('type_match')

    # Map judge's type_match to boolean
    judge_correct = None
    if judge_match in ['exact', 'semantic']:
        judge_correct = True
    elif judge_match in ['partial']:
        judge_correct = None  # Ambiguous
    elif judge_match in ['none', 'wrong', 'not_mentioned']:
        judge_correct = False

    # Determine agreement
    if expert_correct is None or judge_correct is None:
        agreement = None
    else:
        agreement = expert_correct == judge_correct

    return {
        'agreement': agreement,
        'expert_correct': expert_correct,
        'judge_match': judge_match,
        'judge_correct_mapped': judge_correct
    }


def compare_reasoning_quality(expert: Dict, judge: Dict) -> Dict:
    """Compare reasoning quality assessments."""
    if not expert or not judge:
        return None

    expert_quality = expert.get('reasoning_quality', '')

    # Get judge's composite score (average of available scores)
    scores = []
    for key in ['root_cause_score', 'attack_vector_score', 'fix_suggestion_score']:
        score = judge.get(key)
        if score is not None:
            scores.append(score)

    judge_avg_score = statistics.mean(scores) if scores else None

    # Map expert quality to numeric
    quality_map = {
        'accurate': 1.0,
        'partial': 0.5,
        'incorrect': 0.0,
        '': None
    }
    expert_score = quality_map.get(expert_quality.lower() if expert_quality else '')

    # Calculate difference if both available
    difference = None
    if expert_score is not None and judge_avg_score is not None:
        difference = abs(expert_score - judge_avg_score)

    return {
        'expert_quality': expert_quality,
        'expert_score': expert_score,
        'judge_avg_score': judge_avg_score,
        'judge_individual_scores': {
            'root_cause': judge.get('root_cause_score'),
            'attack_vector': judge.get('attack_vector_score'),
            'fix_suggestion': judge.get('fix_suggestion_score')
        },
        'score_difference': difference,
        'agreement': 'close' if difference is not None and difference <= 0.3 else 'different' if difference is not None else None
    }


def compare_bonus_findings(expert: Dict, judge: Dict) -> Dict:
    """Compare bonus finding counts."""
    if not expert or not judge:
        return None

    expert_bonus = expert.get('bonus_valid_count', 0)
    judge_bonus = judge.get('bonus_valid_count', 0)

    difference = abs(expert_bonus - judge_bonus)

    return {
        'expert_count': expert_bonus,
        'judge_count': judge_bonus,
        'difference': difference,
        'agreement': 'exact' if difference == 0 else ('close' if difference <= 1 else 'different')
    }


def check_data_quality(expert_data: Dict, sample_id: str) -> List[str]:
    """Check for data quality issues in expert review."""
    issues = []

    if not expert_data:
        return ['missing_data']

    target = expert_data.get('target_assessment', {})
    summary = expert_data.get('summary', {})

    # Check for internal inconsistencies
    found = target.get('found')
    summary_found = summary.get('target_found')

    if found is not None and summary_found is not None and found != summary_found:
        issues.append('inconsistent_found_status')

    # Check for missing critical fields
    if 'found' not in target and 'classification' not in target:
        issues.append('missing_verdict')

    if target.get('reasoning_quality') == '':
        issues.append('empty_reasoning_quality')

    # Check for contradictions
    if target.get('found') is True and target.get('type_correct') is False:
        issues.append('found_but_type_incorrect')

    # Check summary counts consistency
    if summary.get('target_found') is False and summary.get('bonus_valid_count', 0) > 0:
        # This might be valid - model missed target but found other issues
        pass

    return issues


# ============================================================================
# MAIN ANALYSIS FUNCTION
# ============================================================================

def run_comprehensive_analysis():
    """Run full comparison analysis."""

    print("="*80)
    print("EXPERT vs MISTRAL JUDGE COMPREHENSIVE COMPARISON")
    print("="*80)
    print()

    # Collect all expert reviews from both directories
    print("📂 Loading expert reviews...")
    expert_reviews = {}  # Key: (sample_id, evaluated_model)
    for expert_dir in EXPERT_DIRS:
        if not expert_dir.exists():
            continue
        print(f"   Loading from: {expert_dir.name}")
        for model_dir in expert_dir.iterdir():
            if not model_dir.is_dir():
                continue
            expert_model = model_dir.name
            # Map expert folder name to judge model name
            judge_model_name = MODEL_NAME_MAPPING.get(expert_model, expert_model)

            for review_file in model_dir.glob('r_*.json'):
                sample_id = extract_sample_id(review_file.name)
                expert_data = load_json(review_file)
                if expert_data:
                    key = (sample_id, judge_model_name)
                    expert_reviews[key] = {
                        'path': review_file,
                        'expert_model': expert_model,
                        'evaluated_model': judge_model_name,
                        'data': expert_data
                    }

    print(f"   Found {len(expert_reviews)} expert reviews")

    # Collect all judge outputs
    print("📂 Loading Mistral judge outputs...")
    judge_outputs = defaultdict(list)
    for judge_model_dir in JUDGE_DIR.iterdir():
        if not judge_model_dir.is_dir():
            continue
        judge_output_dir = judge_model_dir / 'judge_outputs'
        if not judge_output_dir.exists():
            continue
        for judge_file in judge_output_dir.glob('j_*.json'):
            sample_id = extract_sample_id(judge_file.name)
            judge_data = load_json(judge_file)
            if judge_data:
                judge_outputs[sample_id].append({
                    'path': judge_file,
                    'evaluated_model': judge_model_dir.name,
                    'data': judge_data
                })

    print(f"   Found judge outputs for {len(judge_outputs)} samples")
    print()

    # Run comparisons
    print("🔍 Running comparisons...")
    comparisons = []
    data_quality_issues = []

    stats = {
        'total': 0,
        'verdict_exact': 0,
        'verdict_lenient': 0,
        'verdict_disagree': 0,
        'type_agree': 0,
        'type_disagree': 0,
        'reasoning_close': 0,
        'reasoning_different': 0,
        'bonus_exact': 0,
        'bonus_close': 0,
        'bonus_different': 0,
        'by_model': defaultdict(lambda: {'total': 0, 'exact': 0, 'lenient': 0, 'disagree': 0})
    }

    for (sample_id, evaluated_model), expert_info in sorted(expert_reviews.items()):
        # Check data quality
        issues = check_data_quality(expert_info['data'], sample_id)
        if issues:
            data_quality_issues.append({
                'sample_id': sample_id,
                'model': expert_info['expert_model'],
                'evaluated_model': evaluated_model,
                'issues': issues
            })

        # Find matching judge outputs for this sample and model
        if sample_id not in judge_outputs:
            continue

        for judge_info in judge_outputs[sample_id]:
            # Only compare if the judge is evaluating the same model as the expert reviewed
            if judge_info['evaluated_model'] != evaluated_model:
                continue
            # Extract verdicts
            expert = get_expert_verdict(expert_info['data'])
            judge = get_judge_verdict(judge_info['data'])

            if not expert or not judge:
                continue

            # Run comparisons
            verdict_cmp = compare_verdicts(expert, judge)
            type_cmp = compare_type_correctness(expert, judge)
            reasoning_cmp = compare_reasoning_quality(expert, judge)
            bonus_cmp = compare_bonus_findings(expert, judge)

            # Update stats
            stats['total'] += 1
            stats['by_model'][judge_info['evaluated_model']]['total'] += 1

            if verdict_cmp['exact_match']:
                stats['verdict_exact'] += 1
                stats['by_model'][judge_info['evaluated_model']]['exact'] += 1
            elif verdict_cmp['lenient_match']:
                stats['verdict_lenient'] += 1
                stats['by_model'][judge_info['evaluated_model']]['lenient'] += 1
            else:
                stats['verdict_disagree'] += 1
                stats['by_model'][judge_info['evaluated_model']]['disagree'] += 1

            if type_cmp and type_cmp['agreement'] is True:
                stats['type_agree'] += 1
            elif type_cmp and type_cmp['agreement'] is False:
                stats['type_disagree'] += 1

            if reasoning_cmp and reasoning_cmp['agreement'] == 'close':
                stats['reasoning_close'] += 1
            elif reasoning_cmp and reasoning_cmp['agreement'] == 'different':
                stats['reasoning_different'] += 1

            if bonus_cmp:
                if bonus_cmp['agreement'] == 'exact':
                    stats['bonus_exact'] += 1
                elif bonus_cmp['agreement'] == 'close':
                    stats['bonus_close'] += 1
                else:
                    stats['bonus_different'] += 1

            # Store comparison
            comparisons.append({
                'sample_id': sample_id,
                'expert_reviewer': expert_info['expert_model'],
                'evaluated_model': judge_info['evaluated_model'],
                'verdict_comparison': verdict_cmp,
                'type_comparison': type_cmp,
                'reasoning_comparison': reasoning_cmp,
                'bonus_comparison': bonus_cmp,
                'expert_raw': expert,
                'judge_raw': judge,
                'data_quality_issues': issues
            })

    print(f"   Completed {stats['total']} comparisons")
    print()

    # Generate reports
    generate_reports(comparisons, stats, data_quality_issues)

    return comparisons, stats, data_quality_issues


# ============================================================================
# REPORT GENERATION
# ============================================================================

def generate_reports(comparisons: List[Dict], stats: Dict, data_quality_issues: List[Dict]):
    """Generate all output reports."""

    # 1. JSON detailed comparison
    output_file = OUTPUT_DIR / 'expert_vs_judge_detailed.json'
    with open(output_file, 'w') as f:
        json.dump({
            'summary_statistics': dict(stats),
            'comparisons': comparisons,
            'data_quality_issues': data_quality_issues
        }, f, indent=2)
    print(f"✅ Saved detailed JSON: {output_file}")

    # 2. Markdown summary report
    generate_markdown_report(stats, comparisons, data_quality_issues)

    # 3. CSV export
    generate_csv_export(comparisons)

    # 4. Console summary
    print_console_summary(stats, data_quality_issues)


def generate_markdown_report(stats: Dict, comparisons: List[Dict], issues: List[Dict]):
    """Generate markdown summary report."""

    output_file = OUTPUT_DIR / 'expert_vs_judge_summary.md'

    total = stats['total']
    if total == 0:
        return

    with open(output_file, 'w') as f:
        f.write("# Expert vs Mistral Judge Comparison Report\n\n")
        f.write(f"**Total Comparisons:** {total}\n\n")

        # Verdict Agreement
        f.write("## 1. Primary Verdict Agreement\n\n")
        f.write(f"- **Exact Match:** {stats['verdict_exact']} ({stats['verdict_exact']/total*100:.1f}%)\n")
        f.write(f"- **Lenient Match (FOUND/PARTIAL):** {stats['verdict_lenient']} ({stats['verdict_lenient']/total*100:.1f}%)\n")
        f.write(f"- **Disagree:** {stats['verdict_disagree']} ({stats['verdict_disagree']/total*100:.1f}%)\n\n")
        f.write(f"**Combined Agreement Rate:** {(stats['verdict_exact'] + stats['verdict_lenient'])/total*100:.1f}%\n\n")

        # By Model Breakdown
        f.write("## 2. Agreement by Evaluated Model\n\n")
        f.write("| Model | Total | Exact | Lenient | Disagree | Agreement % |\n")
        f.write("|-------|-------|-------|---------|----------|-------------|\n")
        for model, model_stats in sorted(stats['by_model'].items()):
            m_total = model_stats['total']
            m_exact = model_stats['exact']
            m_lenient = model_stats['lenient']
            m_disagree = model_stats['disagree']
            agreement = (m_exact + m_lenient) / m_total * 100 if m_total > 0 else 0
            f.write(f"| {model} | {m_total} | {m_exact} | {m_lenient} | {m_disagree} | {agreement:.1f}% |\n")
        f.write("\n")

        # Type Correctness
        f.write("## 3. Vulnerability Type Correctness\n\n")
        type_total = stats['type_agree'] + stats['type_disagree']
        if type_total > 0:
            f.write(f"- **Agree:** {stats['type_agree']} ({stats['type_agree']/type_total*100:.1f}%)\n")
            f.write(f"- **Disagree:** {stats['type_disagree']} ({stats['type_disagree']/type_total*100:.1f}%)\n\n")

        # Reasoning Quality
        f.write("## 4. Reasoning Quality Agreement\n\n")
        reasoning_total = stats['reasoning_close'] + stats['reasoning_different']
        if reasoning_total > 0:
            f.write(f"- **Close (≤0.3 difference):** {stats['reasoning_close']} ({stats['reasoning_close']/reasoning_total*100:.1f}%)\n")
            f.write(f"- **Different (>0.3 difference):** {stats['reasoning_different']} ({stats['reasoning_different']/reasoning_total*100:.1f}%)\n\n")

        # Bonus Findings
        f.write("## 5. Bonus Findings Count Agreement\n\n")
        bonus_total = stats['bonus_exact'] + stats['bonus_close'] + stats['bonus_different']
        if bonus_total > 0:
            f.write(f"- **Exact Match:** {stats['bonus_exact']} ({stats['bonus_exact']/bonus_total*100:.1f}%)\n")
            f.write(f"- **Close (±1):** {stats['bonus_close']} ({stats['bonus_close']/bonus_total*100:.1f}%)\n")
            f.write(f"- **Different (>1):** {stats['bonus_different']} ({stats['bonus_different']/bonus_total*100:.1f}%)\n\n")

        # Data Quality Issues
        f.write("## 6. Data Quality Issues in Expert Reviews\n\n")
        f.write(f"**Total Reviews with Issues:** {len(issues)}\n\n")

        issue_counts = defaultdict(int)
        for item in issues:
            for issue in item['issues']:
                issue_counts[issue] += 1

        f.write("| Issue Type | Count |\n")
        f.write("|------------|-------|\n")
        for issue_type, count in sorted(issue_counts.items(), key=lambda x: -x[1]):
            f.write(f"| {issue_type} | {count} |\n")
        f.write("\n")

        # Notable Disagreements
        f.write("## 7. Notable Disagreements\n\n")
        disagreements = [c for c in comparisons if c['verdict_comparison']['agreement'] == 'disagree']
        f.write(f"Found {len(disagreements)} cases where Expert and Mistral completely disagreed.\n\n")

        # Show first 10
        for i, d in enumerate(disagreements[:10], 1):
            f.write(f"### {i}. {d['sample_id']} ({d['evaluated_model']})\n")
            f.write(f"- **Expert:** {d['verdict_comparison']['expert']}\n")
            f.write(f"- **Mistral:** {d['verdict_comparison']['judge']}\n")
            if d['data_quality_issues']:
                f.write(f"- **Data Issues:** {', '.join(d['data_quality_issues'])}\n")
            f.write("\n")

        if len(disagreements) > 10:
            f.write(f"*...and {len(disagreements) - 10} more disagreements*\n\n")

    print(f"✅ Saved markdown report: {output_file}")


def generate_csv_export(comparisons: List[Dict]):
    """Generate CSV export for spreadsheet analysis."""

    output_file = OUTPUT_DIR / 'expert_vs_judge_export.csv'

    with open(output_file, 'w') as f:
        # Header
        headers = [
            'sample_id', 'expert_reviewer', 'evaluated_model',
            'expert_verdict', 'judge_verdict', 'verdict_agreement',
            'expert_type_correct', 'judge_type_match',
            'expert_reasoning_quality', 'expert_reasoning_score', 'judge_avg_score',
            'expert_bonus_count', 'judge_bonus_count',
            'expert_overall_quality', 'data_quality_issues'
        ]
        f.write(','.join(headers) + '\n')

        # Data rows
        for c in comparisons:
            row = [
                c['sample_id'],
                c['expert_reviewer'],
                c['evaluated_model'],
                c['verdict_comparison']['expert'],
                c['verdict_comparison']['judge'],
                c['verdict_comparison']['agreement'],
                str(c['type_comparison']['expert_correct']) if c['type_comparison'] else '',
                c['type_comparison']['judge_match'] if c['type_comparison'] else '',
                c['reasoning_comparison']['expert_quality'] if c['reasoning_comparison'] else '',
                str(c['reasoning_comparison']['expert_score']) if c['reasoning_comparison'] else '',
                str(c['reasoning_comparison']['judge_avg_score']) if c['reasoning_comparison'] else '',
                str(c['bonus_comparison']['expert_count']) if c['bonus_comparison'] else '',
                str(c['bonus_comparison']['judge_count']) if c['bonus_comparison'] else '',
                c['expert_raw']['overall_quality'],
                '|'.join(c['data_quality_issues']) if c['data_quality_issues'] else ''
            ]
            f.write(','.join(row) + '\n')

    print(f"✅ Saved CSV export: {output_file}")


def print_console_summary(stats: Dict, issues: List[Dict]):
    """Print summary to console."""

    total = stats['total']
    if total == 0:
        return

    print()
    print("="*80)
    print("SUMMARY")
    print("="*80)
    print(f"Total Comparisons: {total}")
    print()
    print(f"Verdict Agreement:")
    print(f"  Exact:    {stats['verdict_exact']:3d} ({stats['verdict_exact']/total*100:5.1f}%)")
    print(f"  Lenient:  {stats['verdict_lenient']:3d} ({stats['verdict_lenient']/total*100:5.1f}%)")
    print(f"  Disagree: {stats['verdict_disagree']:3d} ({stats['verdict_disagree']/total*100:5.1f}%)")
    print(f"  Combined: {(stats['verdict_exact'] + stats['verdict_lenient'])/total*100:5.1f}%")
    print()
    print(f"Data Quality Issues: {len(issues)} expert reviews with issues")
    print()
    print("="*80)
    print()
    print(f"📊 Full reports saved to: {OUTPUT_DIR}")
    print()


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

if __name__ == '__main__':
    run_comprehensive_analysis()
