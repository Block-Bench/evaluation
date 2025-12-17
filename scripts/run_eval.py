#!/usr/bin/env python3
"""
CLI entry point for the smart contract vulnerability detection benchmark.

Usage:
    # Step 1: Generate fixed sample set
    python scripts/generate_samples.py --config config/default.yaml

    # Step 2: Run evaluation (loads from samples/ folder)
    python scripts/run_eval.py run --config config/default.yaml
    python scripts/run_eval.py run --config config/default.yaml --dry-run
    python scripts/run_eval.py run --config config/default.yaml --no-resume

    # Step 3: Check results
    python scripts/run_eval.py stats --results output/deepseek_v3.2/

    # Utilities
    python scripts/run_eval.py list-samples --config config/default.yaml
    python scripts/run_eval.py estimate-cost --config config/default.yaml
"""

import asyncio
import json
import sys
from pathlib import Path

import click

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.pipeline.runner import run_pipeline, EvaluationPipeline
from src.data.loader import DatasetLoader
from src.data.schema import DataConfig, SamplingConfig


def load_data_config_from_yaml(config_path: str) -> DataConfig:
    """Load data configuration from YAML file."""
    import yaml

    with open(config_path) as f:
        config_dict = yaml.safe_load(f)

    data_dict = config_dict.get("data", {})
    sampling = None
    if "sampling" in data_dict:
        sampling_dict = data_dict["sampling"]
        sampling = SamplingConfig(
            ds=sampling_dict.get("ds"),
            tc=sampling_dict.get("tc"),
            gs=sampling_dict.get("gs"),
            strategy=sampling_dict.get("strategy", "independent"),
            min_difficulty=sampling_dict.get("min_difficulty"),
        )

    return DataConfig(
        root=data_dict.get("root", "./raw/data"),
        ground_truth_path=data_dict.get(
            "ground_truth_path", "./raw/data/annotated/metadata"
        ),
        transformations=data_dict.get("transformations", ["sanitized"]),
        sampling=sampling,
        seed=data_dict.get("seed", 42),
    )


@click.group()
def cli():
    """Smart Contract Vulnerability Detection Benchmark"""
    pass


@cli.command()
@click.option(
    "--config",
    "-c",
    default="config/default.yaml",
    help="Path to configuration file",
)
@click.option(
    "--model",
    "-m",
    default=None,
    help="Path to model config (overrides default_model in config)",
)
@click.option(
    "--resume/--no-resume",
    default=True,
    help="Resume from checkpoint (skip completed samples)",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be evaluated without running",
)
def run(config: str, model: str, resume: bool, dry_run: bool):
    """Run the evaluation pipeline."""
    click.echo(f"Loading config: {config}")

    try:
        summary = asyncio.run(
            run_pipeline(
                config_path=config,
                model_config_path=model,
                resume=resume,
                dry_run=dry_run,
            )
        )

        if not dry_run:
            click.echo("\n" + "=" * 50)
            click.echo("Evaluation Summary:")
            click.echo(f"  Model: {summary.get('model', 'unknown')}")
            click.echo(f"  Samples: {summary.get('samples', 0)}")
            click.echo(f"  Prompt types: {summary.get('prompt_types', [])}")
            click.echo(f"  Total evaluations: {summary.get('eval_pairs', 0)}")
            click.echo(f"  Completed: {summary.get('completed', 0)}")
            click.echo(f"  Errors: {summary.get('errors', 0)}")
            click.echo(f"  Total Cost: ${summary.get('total_cost_usd', 0):.4f}")

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        raise click.Abort()


@cli.command()
@click.option(
    "--config",
    "-c",
    default="config/default.yaml",
    help="Path to configuration file",
)
def list_samples(config: str):
    """List all samples that would be loaded with current config."""
    import yaml

    with open(config) as f:
        config_dict = yaml.safe_load(f)

    data_config = load_data_config_from_yaml(config)
    loader = DatasetLoader(data_config)

    samples = loader.load_samples(load_code=False, load_ground_truth=False)
    stats = loader.get_statistics(samples)

    # Get prompt types
    eval_config = config_dict.get("evaluation", {})
    prompt_types = eval_config.get(
        "prompt_types", ["direct", "naturalistic", "adversarial"]
    )

    click.echo(f"Total samples: {stats['total']}")
    click.echo(f"Prompt types: {prompt_types}")
    click.echo(f"Total evaluations: {stats['total'] * len(prompt_types)}")

    click.echo(f"\nBy transformation:")
    for t, count in stats["by_transformation"].items():
        click.echo(f"  {t}: {count}")

    click.echo(f"\nBy subset:")
    for s, count in stats["by_subset"].items():
        click.echo(f"  {s}: {count}")

    click.echo(f"\nSample IDs (first 20):")
    for sample in samples[:20]:
        click.echo(f"  {sample.transformed_id} ({sample.transformation})")
    if len(samples) > 20:
        click.echo(f"  ... and {len(samples) - 20} more")


@cli.command()
@click.option(
    "--results",
    "-r",
    required=True,
    help="Path to results directory (model folder)",
)
def stats(results: str):
    """Show statistics for completed evaluations."""
    results_dir = Path(results)

    if not results_dir.exists():
        click.echo(f"Results directory not found: {results_dir}", err=True)
        raise click.Abort()

    # Find prompt type subdirectories
    prompt_dirs = [d for d in results_dir.iterdir() if d.is_dir()]

    if not prompt_dirs:
        click.echo("No prompt type directories found")
        return

    click.echo(f"Results from: {results_dir}")
    click.echo(f"Prompt types found: {[d.name for d in prompt_dirs]}")

    total_files = 0
    total_cost = 0.0

    for prompt_dir in sorted(prompt_dirs):
        result_files = list(prompt_dir.glob("r_*.json"))
        total_files += len(result_files)

        # Analyze results for this prompt type
        verdicts = {"vulnerable": 0, "safe": 0, "unknown": 0}
        parse_success = 0
        parse_fail = 0
        prompt_cost = 0.0
        errors = 0

        for result_file in result_files:
            try:
                with open(result_file) as f:
                    result = json.load(f)

                if result.get("error"):
                    errors += 1
                    continue

                prompt_cost += result.get("cost_usd", 0) or 0

                # For direct prompts, check prediction
                prediction = result.get("prediction")
                if prediction:
                    verdict = prediction.get("verdict", "unknown")
                    verdicts[verdict] = verdicts.get(verdict, 0) + 1
                    if prediction.get("parse_success"):
                        parse_success += 1
                    else:
                        parse_fail += 1
                else:
                    # Free-form response (naturalistic/adversarial)
                    raw_response = result.get("raw_response", "")
                    verdicts["unknown"] += 1  # Not parsed

            except Exception as e:
                click.echo(f"Warning: Failed to load {result_file}: {e}")

        total_cost += prompt_cost

        click.echo(f"\n--- {prompt_dir.name} ---")
        click.echo(f"  Files: {len(result_files)}")
        click.echo(f"  Errors: {errors}")
        if prompt_dir.name == "direct":
            click.echo(f"  Verdicts: {dict(verdicts)}")
            click.echo(f"  Parse success: {parse_success}, fail: {parse_fail}")
        else:
            click.echo(f"  (Free-form responses, not parsed)")
        click.echo(f"  Cost: ${prompt_cost:.4f}")

    click.echo(f"\n{'='*50}")
    click.echo(f"Total files: {total_files}")
    click.echo(f"Total cost: ${total_cost:.4f}")


@cli.command()
@click.option(
    "--config",
    "-c",
    default="config/default.yaml",
    help="Path to configuration file",
)
@click.option(
    "--model",
    "-m",
    default=None,
    help="Path to model config",
)
def estimate_cost(config: str, model: str):
    """Estimate API costs before running."""
    import yaml

    with open(config) as f:
        config_dict = yaml.safe_load(f)

    # Load data config to count samples
    data_config = load_data_config_from_yaml(config)
    loader = DatasetLoader(data_config)
    samples = loader.load_samples(load_code=True, load_ground_truth=False)

    # Get prompt types
    eval_config = config_dict.get("evaluation", {})
    prompt_types = eval_config.get(
        "prompt_types", ["direct", "naturalistic", "adversarial"]
    )
    num_prompts = len(prompt_types)

    # Estimate tokens per sample (rough estimate)
    avg_code_tokens = sum(
        len(s.contract_code.split()) * 1.3 for s in samples
    ) / len(samples)
    prompt_overhead = 500  # System prompt + template
    output_estimate = 800  # Estimated output tokens

    # Total evaluations = samples × prompt types
    total_evals = len(samples) * num_prompts

    total_input_tokens = total_evals * (avg_code_tokens + prompt_overhead)
    total_output_tokens = total_evals * output_estimate

    # Load model config for pricing
    model_config_path = model or f"config/models/{config_dict.get('default_model', 'deepseek-v3-2')}.yaml"

    with open(model_config_path) as f:
        model_config = yaml.safe_load(f)

    input_cost = total_input_tokens * model_config.get("cost_per_input_token", 0)
    output_cost = total_output_tokens * model_config.get("cost_per_output_token", 0)

    click.echo(f"Cost Estimate for {model_config.get('name', 'unknown')}")
    click.echo(f"\nSamples: {len(samples)}")
    click.echo(f"Prompt types: {prompt_types}")
    click.echo(f"Total evaluations: {total_evals}")
    click.echo(f"Avg code tokens: {avg_code_tokens:.0f}")
    click.echo(f"\nEstimated tokens:")
    click.echo(f"  Input: {total_input_tokens:,.0f}")
    click.echo(f"  Output: {total_output_tokens:,.0f}")
    click.echo(f"\nEstimated cost:")
    click.echo(f"  Input: ${input_cost:.4f}")
    click.echo(f"  Output: ${output_cost:.4f}")
    click.echo(f"  Total: ${input_cost + output_cost:.4f}")


if __name__ == "__main__":
    cli()
