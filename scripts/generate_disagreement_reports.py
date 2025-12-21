#!/usr/bin/env python3
"""
Generate detailed disagreement analysis reports for all cases where
Expert and Mistral Judge disagreed.
"""

import json
from pathlib import Path
from typing import Dict, Optional

BASE_DIR = Path(__file__).parent.parent
DISAGREEMENTS_DIR = BASE_DIR / 'analysis_results' / 'disagreements'
DISAGREEMENTS_DIR.mkdir(exist_ok=True)


def load_json(filepath: Path) -> Optional[Dict]:
    """Load JSON file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"⚠️  Error loading {filepath}: {e}")
        return None


def find_prompt_type(sample_id: str, model: str) -> str:
    """Find which prompt type this disagreement relates to."""
    judge_dir = BASE_DIR / 'judge_output' / model / 'judge_outputs'
    if not judge_dir.exists():
        return 'unknown'

    # Check for different prompt types
    for prompt_type in ['direct', 'adversarial', 'naturalistic']:
        judge_file = judge_dir / f'j_{sample_id}_{prompt_type}.json'
        if judge_file.exists():
            return prompt_type

    return 'unknown'


def generate_disagreement_report(case_num: int, disagreement: Dict) -> str:
    """Generate a detailed markdown report for a single disagreement."""

    sample_id = disagreement['sample_id']
    evaluated_model = disagreement['evaluated_model']
    expert_reviewer = disagreement['expert_reviewer']

    # Load all relevant files
    ground_truth_file = BASE_DIR / 'samples' / 'ground_truth' / f'{sample_id}.json'
    contract_file = BASE_DIR / 'samples' / 'contracts' / f'{sample_id}.sol'

    # Find the prompt type for this specific disagreement
    # We need to check which judge file this came from
    judge_dir = BASE_DIR / 'judge_output' / evaluated_model / 'judge_outputs'
    prompt_type = 'unknown'
    judge_file_path = None

    for pt in ['direct', 'adversarial', 'naturalistic']:
        potential_judge_file = judge_dir / f'j_{sample_id}_{pt}.json'
        if potential_judge_file.exists():
            judge_data = load_json(potential_judge_file)
            if judge_data and judge_data.get('target_assessment', {}).get('found') == disagreement['verdict_comparison']['judge'] == 'FOUND':
                prompt_type = pt
                judge_file_path = potential_judge_file
                break
            elif judge_data and not judge_data.get('target_assessment', {}).get('found') and disagreement['verdict_comparison']['judge'] == 'MISSED':
                prompt_type = pt
                judge_file_path = potential_judge_file
                break

    # Default to direct if we can't determine
    if prompt_type == 'unknown':
        prompt_type = 'direct'
        judge_file_path = judge_dir / f'j_{sample_id}_direct.json'

    # Determine model output path based on prompt type
    model_output_file = BASE_DIR / 'output' / evaluated_model / prompt_type / f'r_{sample_id}.json'

    # Determine expert review file path
    # Check both Expert-Reviews and D4n13l_ExpertReviews
    expert_file = None
    for expert_dir in [BASE_DIR / 'Expert-Reviews', BASE_DIR / 'D4n13l_ExpertReviews']:
        potential_expert_file = expert_dir / expert_reviewer / f'r_{sample_id}.json'
        if potential_expert_file.exists():
            expert_file = potential_expert_file
            break

    # Load all data
    ground_truth = load_json(ground_truth_file)
    model_output = load_json(model_output_file)
    expert_review = load_json(expert_file) if expert_file else None
    judge_output = load_json(judge_file_path)

    # Read contract code
    contract_code = ""
    if contract_file.exists():
        with open(contract_file, 'r') as f:
            contract_code = f.read()

    # Generate the markdown report
    report = []

    # Header
    report.append(f"# Disagreement Case #{case_num}: {sample_id} - {evaluated_model}\n")
    report.append(f"**Expert Verdict:** {disagreement['verdict_comparison']['expert']}")
    report.append(f"**Mistral Verdict:** {disagreement['verdict_comparison']['judge']}")
    report.append(f"**Expert Reviewer:** {expert_reviewer}")
    report.append(f"**Evaluated Model:** {evaluated_model}")
    report.append(f"**Prompt Type:** {prompt_type}\n")

    # File Links Section
    report.append("---\n")
    report.append("## 📁 Source Files\n")
    report.append("**Ground Truth:**")
    report.append(f"- File: `{ground_truth_file.relative_to(BASE_DIR)}`")
    report.append(f"- [View Ground Truth JSON]({ground_truth_file.relative_to(BASE_DIR)})\n")

    report.append("**Contract Code:**")
    report.append(f"- File: `{contract_file.relative_to(BASE_DIR)}`")
    report.append(f"- [View Contract]({contract_file.relative_to(BASE_DIR)})\n")

    report.append("**Model Response:**")
    report.append(f"- File: `{model_output_file.relative_to(BASE_DIR)}`")
    report.append(f"- [View Model Output]({model_output_file.relative_to(BASE_DIR)})\n")

    if expert_file:
        report.append("**Expert Review:**")
        report.append(f"- File: `{expert_file.relative_to(BASE_DIR)}`")
        report.append(f"- [View Expert Review]({expert_file.relative_to(BASE_DIR)})\n")

    report.append("**Mistral Judge Output:**")
    report.append(f"- File: `{judge_file_path.relative_to(BASE_DIR)}`")
    report.append(f"- [View Judge Output]({judge_file_path.relative_to(BASE_DIR)})\n")

    report.append("---\n")

    # Ground Truth Section
    report.append("## 1. GROUND TRUTH\n")
    if ground_truth:
        gt = ground_truth.get('ground_truth', {})
        report.append(f"**Sample ID:** {sample_id}")
        report.append(f"**Source:** {ground_truth.get('provenance', {}).get('source', 'N/A')}")
        report.append(f"**Subset:** {ground_truth.get('subset', 'N/A')}")

        if 'difficulty_fields' in ground_truth:
            diff = ground_truth['difficulty_fields']
            report.append(f"**Difficulty:** Tier {diff.get('difficulty_tier', 'N/A')} ({diff.get('difficulty_tier_name', 'N/A')})")

        if 'transformation' in ground_truth:
            trans = ground_truth['transformation']
            coverage = trans.get('coverage', {}).get('coverage_percent', 0)
            report.append(f"**Transformation:** {trans.get('strategy', 'N/A')} {trans.get('theme', '')} ({coverage:.1f}% coverage)")

        report.append("\n### Vulnerability Details:")
        report.append(f"- **Type:** `{gt.get('vulnerability_type', 'N/A')}`")
        report.append(f"- **Severity:** {gt.get('severity', 'N/A')}")

        vuln_loc = gt.get('vulnerable_location', {})
        report.append(f"- **Vulnerable Function:** `{vuln_loc.get('function_name', 'N/A')}`")
        report.append(f"- **Contract:** `{vuln_loc.get('contract_name', 'N/A')}`")

        if gt.get('root_cause'):
            report.append(f"\n### Root Cause:")
            report.append(f"```\n{gt['root_cause']}\n```")

        if gt.get('attack_vector'):
            report.append(f"\n### Attack Vector:")
            report.append(f"```\n{gt['attack_vector']}\n```")

        if contract_code:
            report.append(f"\n### Contract Code:")
            report.append(f"```solidity\n{contract_code}\n```")

    report.append("\n---\n")

    # Model Response Section
    report.append(f"## 2. MODEL RESPONSE ({evaluated_model})\n")
    if model_output and model_output.get('prediction'):
        pred = model_output['prediction']
        report.append(f"**Verdict:** {pred.get('verdict', 'N/A').capitalize()}")
        report.append(f"**Confidence:** {pred.get('confidence', 'N/A')}\n")

        if 'vulnerabilities' in pred and pred['vulnerabilities']:
            report.append("### Vulnerabilities Identified:\n")
            for i, vuln in enumerate(pred['vulnerabilities'], 1):
                report.append(f"#### Finding {i}: {vuln.get('type', 'Unknown').replace('_', ' ').title()}")
                report.append(f"- **Type:** `{vuln.get('type', 'N/A')}`")
                report.append(f"- **Severity:** {vuln.get('severity', 'N/A')}")
                report.append(f"- **Location:** `{vuln.get('location', 'N/A')}`")

                if vuln.get('explanation'):
                    report.append(f"- **Explanation:**")
                    report.append(f'  > "{vuln["explanation"]}"')

                if vuln.get('attack_scenario'):
                    report.append(f"- **Attack Scenario:**")
                    report.append(f'  > "{vuln["attack_scenario"]}"')

                if vuln.get('suggested_fix'):
                    report.append(f"- **Suggested Fix:**")
                    report.append(f'  > "{vuln["suggested_fix"]}"')
                report.append("")

        if pred.get('overall_explanation'):
            report.append("### Overall Explanation:")
            report.append(f'> "{pred["overall_explanation"]}"')

    report.append("\n---\n")

    # Expert Review Section
    report.append(f"## 3. EXPERT REVIEW ({expert_reviewer})\n")
    if expert_review:
        eval_info = expert_review.get('evaluation_info', {})
        report.append(f"**Evaluator:** {eval_info.get('evaluator', 'N/A')}")
        report.append(f"**Date:** {eval_info.get('date', 'N/A')}")
        report.append(f"**Time Spent:** {eval_info.get('time_spent_minutes', 'N/A')} minutes\n")

        target = expert_review.get('target_assessment', {})
        report.append("### Target Assessment:")
        report.append(f"- **Found:** {target.get('found', 'N/A')}")
        report.append(f"- **Classification:** {target.get('classification', 'N/A')}")
        report.append(f"- **Type Correct:** {target.get('type_correct', 'N/A')}")
        report.append(f"- **Location Correct:** {target.get('location_correct', 'N/A')}")
        report.append(f"- **Reasoning Quality:** {target.get('reasoning_quality', 'N/A')}")

        if target.get('notes'):
            report.append(f"\n**Notes:**")
            report.append(f'> "{target["notes"]}"')

        other = expert_review.get('other_findings', [])
        if other and any(f.get('model_claim') for f in other):
            report.append("\n### Other Findings Analysis:\n")
            for i, finding in enumerate(other, 1):
                if finding.get('model_claim'):
                    report.append(f"**Finding #{i}:**")
                    report.append(f"- **Model Claim:** \"{finding['model_claim']}\"")
                    report.append(f"- **Expert Classification:** {finding.get('classification', 'N/A')}")
                    if finding.get('reasoning'):
                        report.append(f"- **Expert Reasoning:** \"{finding['reasoning']}\"")
                    report.append("")

        summary = expert_review.get('summary', {})
        report.append("### Summary:")
        report.append(f"- **Target Found:** {summary.get('target_found', 'N/A')}")
        report.append(f"- **Bonus Valid Count:** {summary.get('bonus_valid_count', 0)}")
        report.append(f"- **False Positive Count:** {summary.get('false_positive_count', 0)}")
        report.append(f"- **Hallucination Count:** {summary.get('hallucination_count', 0)}")
        report.append(f"- **Overall Quality:** {summary.get('overall_quality', 'N/A')}")

    report.append("\n---\n")

    # Mistral Judge Section
    report.append("## 4. MISTRAL JUDGE RESPONSE\n")
    if judge_output:
        report.append(f"**Judge Model:** {judge_output.get('judge_model', 'N/A')}")
        report.append(f"**Timestamp:** {judge_output.get('timestamp', 'N/A')}\n")

        overall = judge_output.get('overall_verdict', {})
        report.append(f"**Overall Verdict:** {'Vulnerable' if overall.get('said_vulnerable') else 'Not Vulnerable'}")
        report.append(f"**Confidence:** {overall.get('confidence_expressed', 'N/A')}\n")

        findings = judge_output.get('findings', [])
        if findings:
            report.append("### Findings Analysis:\n")
            for finding in findings:
                report.append(f"#### Finding {finding.get('finding_id', '?')}: {finding.get('vulnerability_type_claimed', 'Unknown')}")
                report.append(f"- **Description:** \"{finding.get('description', 'N/A')}\"")
                report.append(f"- **Matches Target:** {finding.get('matches_target', 'N/A')}")
                report.append(f"- **Is Valid Concern:** {finding.get('is_valid_concern', 'N/A')}")
                report.append(f"- **Classification:** {finding.get('classification', 'N/A')}")
                report.append(f"- **Reasoning:** \"{finding.get('reasoning', 'N/A')}\"")
                report.append("")

        target_assess = judge_output.get('target_assessment', {})
        report.append("### Target Assessment:")
        report.append(f"- **Found:** {target_assess.get('found', 'N/A')}")
        report.append(f"- **Type Match:** {target_assess.get('type_match', 'N/A')}")

        if target_assess.get('type_match_reasoning'):
            report.append(f"- **Type Match Reasoning:** \"{target_assess['type_match_reasoning']}\"")

        if target_assess.get('root_cause_identification'):
            rcir = target_assess['root_cause_identification']
            report.append(f"\n**Root Cause Identification Score:** {rcir.get('score', 'N/A')}")
            if rcir.get('reasoning'):
                report.append(f"- Reasoning: \"{rcir['reasoning']}\"")

        if target_assess.get('attack_vector_validity'):
            ava = target_assess['attack_vector_validity']
            report.append(f"\n**Attack Vector Validity Score:** {ava.get('score', 'N/A')}")
            if ava.get('reasoning'):
                report.append(f"- Reasoning: \"{ava['reasoning']}\"")

        if target_assess.get('fix_suggestion_validity'):
            fsv = target_assess['fix_suggestion_validity']
            report.append(f"\n**Fix Suggestion Validity Score:** {fsv.get('score', 'N/A')}")
            if fsv.get('reasoning'):
                report.append(f"- Reasoning: \"{fsv['reasoning']}\"")

        summary = judge_output.get('summary', {})
        report.append("\n### Summary:")
        report.append(f"- **Total Findings:** {summary.get('total_findings', 0)}")
        report.append(f"- **Target Matches:** {summary.get('target_matches', 0)}")
        report.append(f"- **Bonus Valid:** {summary.get('bonus_valid', 0)}")
        report.append(f"- **Hallucinated:** {summary.get('hallucinated', 0)}")
        report.append(f"- **Security Theater:** {summary.get('security_theater', 0)}")

        if judge_output.get('notes'):
            report.append(f"\n**Judge Notes:**")
            report.append(f'> "{judge_output["notes"]}"')

    report.append("\n---\n")

    # Analysis Section
    report.append("## 5. ANALYSIS OF DISAGREEMENT\n")

    expert_verdict = disagreement['verdict_comparison']['expert']
    judge_verdict = disagreement['verdict_comparison']['judge']

    report.append(f"### Why Expert Said {expert_verdict}:")
    if expert_review and expert_review.get('target_assessment', {}).get('notes'):
        report.append(f"- {expert_review['target_assessment']['notes']}")

    report.append(f"\n### Why Mistral Said {judge_verdict}:")
    if judge_output and judge_output.get('notes'):
        report.append(f"- {judge_output['notes']}")

    # Add data quality issues if any
    if disagreement.get('data_quality_issues'):
        report.append(f"\n### Data Quality Issues:")
        for issue in disagreement['data_quality_issues']:
            report.append(f"- {issue}")

    report.append("\n### Comparison:")

    # Type comparison
    type_cmp = disagreement.get('type_comparison', {})
    if type_cmp:
        report.append(f"- **Type Correctness:**")
        report.append(f"  - Expert: {type_cmp.get('expert_correct', 'N/A')}")
        report.append(f"  - Judge: {type_cmp.get('judge_match', 'N/A')}")

    # Reasoning comparison
    reasoning_cmp = disagreement.get('reasoning_comparison', {})
    if reasoning_cmp and reasoning_cmp.get('score_difference') is not None:
        report.append(f"- **Reasoning Quality Score Difference:** {reasoning_cmp['score_difference']:.2f}")
        report.append(f"  - Expert: {reasoning_cmp.get('expert_quality', 'N/A')} ({reasoning_cmp.get('expert_score', 'N/A')})")
        report.append(f"  - Judge Avg: {reasoning_cmp.get('judge_avg_score', 'N/A')}")

    # Bonus findings comparison
    bonus_cmp = disagreement.get('bonus_comparison', {})
    if bonus_cmp:
        report.append(f"- **Bonus Findings:**")
        report.append(f"  - Expert: {bonus_cmp.get('expert_count', 0)}")
        report.append(f"  - Judge: {bonus_cmp.get('judge_count', 0)}")

    report.append("\n### Potential Explanation:")
    report.append("*[To be analyzed case by case]*")

    return '\n'.join(report)


def generate_readme(disagreements: list) -> str:
    """Generate the main README for the disagreements folder."""

    readme = []
    readme.append("# Expert vs Mistral Judge Disagreements Analysis\n")
    readme.append("This folder contains detailed analysis of all cases where the Expert reviewer and Mistral judge disagreed on whether a model correctly identified a vulnerability.\n")
    readme.append(f"**Total Disagreements:** {len(disagreements)}\n")

    readme.append("---\n")
    readme.append("## Quick Stats\n")

    # Count patterns
    expert_missed_judge_found = sum(1 for d in disagreements if d['verdict_comparison']['expert'] == 'MISSED' and d['verdict_comparison']['judge'] == 'FOUND')
    expert_found_judge_missed = sum(1 for d in disagreements if d['verdict_comparison']['expert'] == 'FOUND' and d['verdict_comparison']['judge'] == 'MISSED')
    other_patterns = len(disagreements) - expert_missed_judge_found - expert_found_judge_missed

    readme.append(f"- **Expert MISSED, Judge FOUND:** {expert_missed_judge_found} cases")
    readme.append(f"- **Expert FOUND, Judge MISSED:** {expert_found_judge_missed} cases")
    readme.append(f"- **Other patterns:** {other_patterns} cases\n")

    # By model
    from collections import Counter
    model_counts = Counter(d['evaluated_model'] for d in disagreements)
    readme.append("### Disagreements by Model:\n")
    for model, count in sorted(model_counts.items(), key=lambda x: -x[1]):
        readme.append(f"- **{model}:** {count}")

    readme.append("\n---\n")
    readme.append("## All Disagreement Cases\n")

    for i, d in enumerate(disagreements, 1):
        sample_id = d['sample_id']
        model = d['evaluated_model']
        expert_verdict = d['verdict_comparison']['expert']
        judge_verdict = d['verdict_comparison']['judge']

        filename = f"disagreement_{i:02d}_{sample_id}_{model}.md"

        readme.append(f"### Case #{i}: {sample_id} - {model}\n")
        readme.append(f"**Expert:** {expert_verdict} | **Mistral:** {judge_verdict}")
        readme.append(f"**Reviewer:** {d['expert_reviewer']}\n")

        readme.append("**Quick Links:**")
        readme.append(f"- [📄 Detailed Analysis]({filename})")

        # Add source file links
        ground_truth = BASE_DIR / 'samples' / 'ground_truth' / f'{sample_id}.json'
        contract = BASE_DIR / 'samples' / 'contracts' / f'{sample_id}.sol'

        readme.append(f"- [🎯 Ground Truth](../../{ground_truth.relative_to(BASE_DIR)})")
        readme.append(f"- [📜 Contract Code](../../{contract.relative_to(BASE_DIR)})")

        # Try to find the model output and judge output
        for prompt_type in ['direct', 'adversarial', 'naturalistic']:
            model_output = BASE_DIR / 'output' / model / prompt_type / f'r_{sample_id}.json'
            judge_output = BASE_DIR / 'judge_output' / model / 'judge_outputs' / f'j_{sample_id}_{prompt_type}.json'

            if model_output.exists():
                readme.append(f"- [🤖 Model Response ({prompt_type})](../../{model_output.relative_to(BASE_DIR)})")
            if judge_output.exists():
                readme.append(f"- [⚖️ Judge Output ({prompt_type})](../../{judge_output.relative_to(BASE_DIR)})")

        # Expert review
        for expert_dir_name in ['Expert-Reviews', 'D4n13l_ExpertReviews']:
            expert_dir = BASE_DIR / expert_dir_name
            expert_file = expert_dir / d['expert_reviewer'] / f'r_{sample_id}.json'
            if expert_file.exists():
                readme.append(f"- [👤 Expert Review](../../{expert_file.relative_to(BASE_DIR)})")
                break

        readme.append("")

    readme.append("\n---\n")
    readme.append("## How to Use This Folder\n")
    readme.append("1. Browse the list above to find disagreement cases of interest")
    readme.append("2. Click on the detailed analysis to see the full comparison")
    readme.append("3. Use the quick links to jump directly to source files")
    readme.append("4. Each detailed analysis includes:")
    readme.append("   - Ground truth vulnerability details")
    readme.append("   - Complete model response")
    readme.append("   - Expert reviewer's assessment")
    readme.append("   - Mistral judge's assessment")
    readme.append("   - Analysis of why they disagreed\n")

    readme.append("---\n")
    readme.append("*Generated automatically by `generate_disagreement_reports.py`*")

    return '\n'.join(readme)


def main():
    """Main function to generate all disagreement reports."""
    print("="*80)
    print("GENERATING DISAGREEMENT ANALYSIS REPORTS")
    print("="*80)
    print()

    # Load the disagreements
    detailed_file = BASE_DIR / 'analysis_results' / 'expert_vs_judge_detailed.json'
    with open(detailed_file, 'r') as f:
        data = json.load(f)

    disagreements = [c for c in data['comparisons'] if c['verdict_comparison']['agreement'] == 'disagree']

    print(f"Found {len(disagreements)} disagreement cases")
    print()

    # Generate individual reports
    print("Generating individual case reports...")
    for i, disagreement in enumerate(disagreements, 1):
        sample_id = disagreement['sample_id']
        model = disagreement['evaluated_model']

        filename = f"disagreement_{i:02d}_{sample_id}_{model}.md"
        filepath = DISAGREEMENTS_DIR / filename

        print(f"  {i:2d}. {sample_id} - {model}")

        report_content = generate_disagreement_report(i, disagreement)

        with open(filepath, 'w') as f:
            f.write(report_content)

    print()
    print("Generating README...")
    readme_content = generate_readme(disagreements)
    readme_path = DISAGREEMENTS_DIR / 'README.md'

    with open(readme_path, 'w') as f:
        f.write(readme_content)

    print()
    print("="*80)
    print("✅ COMPLETE")
    print("="*80)
    print(f"Generated {len(disagreements)} detailed case reports")
    print(f"Output directory: {DISAGREEMENTS_DIR}")
    print(f"Main index: {readme_path}")
    print()


if __name__ == '__main__':
    main()
