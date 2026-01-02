#!/usr/bin/env python3
"""
CLI for running the LLM Judge evaluation system.

Usage:
    python scripts/run_judge.py run --model deepseek_v3.2 --judge-config config/judge/mistral-medium-3.yaml
    python scripts/run_judge.py stats --model deepseek_v3.2
"""

import asyncio
import json
from pathlib import Path
from typing import Optional

import click
import yaml
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.judge.config import JudgeModelConfig
from src.judge.runner import JudgeRunner
from src.judge.schemas import JudgeInput, GroundTruthForJudge, PromptType
from src.data.sample_loader import SampleLoader


@click.group()
def cli():
    """LLM Judge Evaluation System"""
    pass


@cli.command()
@click.option('--model', '-m', required=True, help='Model name/directory (e.g., deepseek_v3.2)')
@click.option('--judge-config', '-j', default='config/judge/mistral-medium-3.yaml',
              help='Path to judge model config')
@click.option('--eval-output', '-e', default='output', help='Directory containing model eval outputs')
@click.option('--samples-dir', '-s', default='samples', help='Directory containing samples')
@click.option('--output', '-o', default='judge_output', help='Output directory for judge results')
@click.option('--max-concurrency', '-c', default=3, help='Max concurrent judge calls')
@click.option('--no-resume', is_flag=True, help='Start fresh, ignore checkpoints')
@click.option('--dry-run', is_flag=True, help='Show what would be evaluated without running')
def run(
    model: str,
    judge_config: str,
    eval_output: str,
    samples_dir: str,
    output: str,
    max_concurrency: int,
    no_resume: bool,
    dry_run: bool
):
    """Run judge evaluation on model outputs"""
    
    # Load judge model config
    judge_model_config = JudgeModelConfig.from_yaml(judge_config)
    print(f"Judge model: {judge_model_config.name}")
    
    # Load samples
    sample_loader = SampleLoader(samples_dir)
    samples = sample_loader.load_samples(load_code=True, load_ground_truth=True)
    print(f"Loaded {len(samples)} samples from {samples_dir}")
    
    # Get prompt types from manifest
    prompt_types = sample_loader.prompt_types
    print(f"Prompt types: {prompt_types}")
    
    # Load model evaluation outputs and build judge inputs
    model_output_dir = Path(eval_output) / model
    if not model_output_dir.exists():
        raise click.ClickException(f"Model output directory not found: {model_output_dir}")
    
    judge_inputs = []
    ground_truths = {}
    
    for sample in samples:
        # Use per-sample prompt types if specified, otherwise use global
        sample_prompt_types = sample.prompt_types if sample.prompt_types else prompt_types
        for prompt_type in sample_prompt_types:
            # Load the model's response for this sample+prompt
            result_file = model_output_dir / prompt_type / f"r_{sample.transformed_id}.json"
            
            if not result_file.exists():
                print(f"  Warning: Missing result {result_file}")
                continue
            
            with open(result_file) as f:
                result = json.load(f)
            
            # Extract the raw response (this is what the judge evaluates)
            response_content = result.get("raw_response", "")
            if not response_content:
                # For direct prompts, might be in prediction
                if result.get("prediction"):
                    response_content = result["prediction"].get("raw_response", "")
            
            if not response_content:
                print(f"  Warning: No response content in {result_file}")
                continue
            
            # Build ground truth for judge
            gt = sample.ground_truth
            gt_for_judge = GroundTruthForJudge(
                is_vulnerable=gt.is_vulnerable if gt else False,
                vulnerability_type=gt.vulnerability_type if gt else None,
                severity=gt.severity if gt else None,
                root_cause=gt.root_cause if gt else None,
                attack_scenario=gt.attack_scenario if gt else None,
                fix_description=gt.fix_description if gt else None,
                vulnerable_function=gt.vulnerable_function if gt else None,
                vulnerable_lines=gt.vulnerable_lines if gt else None,
            )
            
            # Build judge input
            judge_input = JudgeInput(
                sample_id=sample.id,
                transformed_id=sample.transformed_id,
                prompt_type=PromptType(prompt_type),
                code=sample.contract_code or "",
                language="solidity",
                ground_truth=gt_for_judge,
                response_content=response_content
            )
            
            judge_inputs.append(judge_input)
            ground_truths[sample.id] = gt_for_judge
    
    print(f"\nBuilt {len(judge_inputs)} judge inputs")
    
    if dry_run:
        print("\n[DRY RUN] Would evaluate:")
        for ji in judge_inputs[:10]:
            print(f"  - {ji.transformed_id} × {ji.prompt_type.value}")
        if len(judge_inputs) > 10:
            print(f"  ... and {len(judge_inputs) - 10} more")
        return
    
    # Create output directory for this model
    judge_output_dir = Path(output) / model
    
    # Initialize runner
    runner = JudgeRunner(
        judge_model_config=judge_model_config,
        output_dir=judge_output_dir,
        max_concurrency=max_concurrency
    )
    
    # Run evaluation
    asyncio.run(runner.run(
        inputs=judge_inputs,
        ground_truths=ground_truths,
        resume=not no_resume
    ))


@cli.command()
@click.option('--model', '-m', required=True, help='Model name/directory')
@click.option('--output', '-o', default='judge_output', help='Judge output directory')
def stats(model: str, output: str):
    """Show statistics for completed judge evaluation"""
    
    judge_dir = Path(output) / model
    
    if not judge_dir.exists():
        raise click.ClickException(f"Judge output directory not found: {judge_dir}")
    
    # Load aggregated metrics
    metrics_file = judge_dir / "aggregated_metrics.json"
    if not metrics_file.exists():
        raise click.ClickException(f"Aggregated metrics not found. Run evaluation first.")
    
    with open(metrics_file) as f:
        metrics = json.load(f)
    
    # Print summary
    print(f"\n{'='*60}")
    print(f"Judge Evaluation Results: {model}")
    print(f"{'='*60}")
    
    print(f"\nSamples: {metrics['total_samples']} "
          f"({metrics['vulnerable_samples']} vulnerable, {metrics['safe_samples']} safe)")
    
    d = metrics['detection']
    print(f"\n## Detection Performance")
    print(f"  Accuracy:  {d['accuracy']:.1%}")
    print(f"  Precision: {d['precision']:.1%}")
    print(f"  Recall:    {d['recall']:.1%}")
    print(f"  F1:        {d['f1']:.3f}")
    print(f"  F2:        {d['f2']:.3f}")
    
    tf = metrics['target_finding']
    print(f"\n## Target Finding")
    print(f"  Target Detection Rate: {tf['target_detection_rate']:.1%}")
    print(f"  Lucky Guess Rate:      {tf['lucky_guess_rate']:.1%}")
    print(f"  (Found: {tf['target_found_count']}, Lucky: {tf['lucky_guess_count']})")
    
    fq = metrics['finding_quality']
    print(f"\n## Finding Quality")
    print(f"  Finding Precision:   {fq['finding_precision']:.1%}")
    print(f"  Hallucination Rate:  {fq['hallucination_rate']:.1%}")
    print(f"  Avg Findings/Sample: {fq['avg_findings_per_sample']:.1f}")
    
    rq = metrics['reasoning_quality']
    if rq['n_samples_with_reasoning'] > 0:
        print(f"\n## Reasoning Quality (n={rq['n_samples_with_reasoning']})")
        print(f"  RCIR (Root Cause):   {rq['mean_rcir']:.2f}" if rq['mean_rcir'] else "  RCIR: N/A")
        print(f"  AVA (Attack Vector): {rq['mean_ava']:.2f}" if rq['mean_ava'] else "  AVA: N/A")
        print(f"  FSV (Fix Validity):  {rq['mean_fsv']:.2f}" if rq['mean_fsv'] else "  FSV: N/A")
    
    comp = metrics['composite']
    print(f"\n## Composite Scores")
    print(f"  Security Understanding Index (SUI): {comp['sui']:.3f}")
    print(f"  True Understanding Score:           {comp['true_understanding_score']:.3f}")
    print(f"  Lucky Guess Indicator:              {comp['lucky_guess_indicator']:.3f}")
    
    # Per-prompt breakdown
    if metrics.get('by_prompt_type'):
        print(f"\n## By Prompt Type")
        for pt, pt_m in metrics['by_prompt_type'].items():
            print(f"\n  {pt.upper()}:")
            print(f"    Accuracy:         {pt_m['detection']['accuracy']:.1%}")
            print(f"    Target Detection: {pt_m['target_finding']['target_detection_rate']:.1%}")
            print(f"    SUI:              {pt_m['composite']['sui']:.3f}")
    
    print(f"\n{'='*60}")


@cli.command()
@click.option('--output', '-o', default='judge_output', help='Judge output directory')
def list_models(output: str):
    """List models with judge evaluations"""
    
    output_dir = Path(output)
    if not output_dir.exists():
        print("No judge outputs found.")
        return
    
    models = [d.name for d in output_dir.iterdir() if d.is_dir()]
    
    if not models:
        print("No models evaluated yet.")
        return
    
    print("\nModels with judge evaluations:")
    for model in sorted(models):
        model_dir = output_dir / model
        metrics_file = model_dir / "aggregated_metrics.json"
        
        if metrics_file.exists():
            with open(metrics_file) as f:
                metrics = json.load(f)
            samples = metrics.get('total_samples', 0)
            sui = metrics.get('composite', {}).get('sui', 0)
            print(f"  - {model}: {samples} samples, SUI={sui:.3f}")
        else:
            n_outputs = len(list((model_dir / "judge_outputs").glob("j_*.json"))) if (model_dir / "judge_outputs").exists() else 0
            print(f"  - {model}: {n_outputs} outputs (incomplete)")


if __name__ == '__main__':
    cli()
