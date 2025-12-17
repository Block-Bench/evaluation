#!/usr/bin/env python3
"""
Generate a fixed sample set for evaluation.

This creates a samples/ folder with:
- samples/manifest.json - List of all selected samples with metadata
- samples/contracts/ - Copies of selected contract files
- samples/ground_truth/ - Copies of ground truth metadata

Usage:
    python scripts/generate_samples.py --config config/default.yaml
    python scripts/generate_samples.py --config config/default.yaml --output samples/
"""

import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

import click
import yaml

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.data.loader import DatasetLoader
from src.data.schema import DataConfig, SamplingConfig


def load_data_config_from_yaml(config_path: str) -> DataConfig:
    """Load data configuration from YAML file."""
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


@click.command()
@click.option(
    "--config",
    "-c",
    default="config/default.yaml",
    help="Path to configuration file",
)
@click.option(
    "--output",
    "-o",
    default="samples",
    help="Output directory for samples",
)
@click.option(
    "--copy-files/--no-copy-files",
    default=True,
    help="Copy contract and ground truth files (default: True)",
)
def generate_samples(config: str, output: str, copy_files: bool):
    """Generate a fixed sample set for evaluation."""

    click.echo(f"Loading config: {config}")

    # Load config
    with open(config) as f:
        config_dict = yaml.safe_load(f)

    data_config = load_data_config_from_yaml(config)

    # Get prompt types for reference
    eval_config = config_dict.get("evaluation", {})
    prompt_types = eval_config.get(
        "prompt_types", ["direct", "naturalistic", "adversarial"]
    )

    # Load samples
    loader = DatasetLoader(data_config)
    samples = loader.load_samples(load_code=True, load_ground_truth=True)

    click.echo(f"Selected {len(samples)} samples")

    # Create output directory
    output_dir = Path(output)
    output_dir.mkdir(parents=True, exist_ok=True)

    if copy_files:
        (output_dir / "contracts").mkdir(exist_ok=True)
        (output_dir / "ground_truth").mkdir(exist_ok=True)

    # Build manifest
    manifest = {
        "generated_at": datetime.now().isoformat(),
        "config_file": config,
        "seed": data_config.seed,
        "transformations": data_config.transformations,
        "sampling": {
            "ds": data_config.sampling.ds if data_config.sampling else None,
            "tc": data_config.sampling.tc if data_config.sampling else None,
            "gs": data_config.sampling.gs if data_config.sampling else None,
            "strategy": data_config.sampling.strategy if data_config.sampling else "independent",
            "min_difficulty": data_config.sampling.min_difficulty if data_config.sampling else None,
        },
        "prompt_types": prompt_types,
        "total_samples": len(samples),
        "total_evaluations": len(samples) * len(prompt_types),
        "samples": [],
    }

    # Process each sample
    for sample in samples:
        sample_entry = {
            "id": sample.id,
            "transformed_id": sample.transformed_id,
            "transformation": sample.transformation,
            "subset": sample.subset,
            "contract_file": f"contracts/{sample.transformed_id}.sol",
            "ground_truth_file": f"ground_truth/{sample.id}.json",
        }

        # Add ground truth summary
        if sample.ground_truth:
            sample_entry["ground_truth_summary"] = {
                "is_vulnerable": sample.ground_truth.is_vulnerable,
                "vulnerability_type": sample.ground_truth.vulnerability_type,
                "severity": sample.ground_truth.severity,
                "difficulty_tier": sample.ground_truth.difficulty_tier,
            }

        manifest["samples"].append(sample_entry)

        # Copy files if requested
        if copy_files:
            # Copy contract
            contract_dest = output_dir / "contracts" / f"{sample.transformed_id}.sol"
            contract_dest.write_text(sample.contract_code, encoding="utf-8")

            # Copy ground truth
            if sample.ground_truth:
                gt_dest = output_dir / "ground_truth" / f"{sample.id}.json"
                gt_data = sample.ground_truth.model_dump(mode="json")
                gt_dest.write_text(json.dumps(gt_data, indent=2), encoding="utf-8")

    # Save manifest
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Print summary
    click.echo(f"\nSamples generated in: {output_dir}")
    click.echo(f"  Manifest: {manifest_path}")
    if copy_files:
        click.echo(f"  Contracts: {output_dir / 'contracts'}/")
        click.echo(f"  Ground truth: {output_dir / 'ground_truth'}/")

    # Stats
    stats = loader.get_statistics(samples)
    click.echo(f"\nStatistics:")
    click.echo(f"  Total samples: {stats['total']}")
    click.echo(f"  By transformation: {stats['by_transformation']}")
    click.echo(f"  By subset: {stats['by_subset']}")
    click.echo(f"  With ground truth: {stats['with_ground_truth']}")
    click.echo(f"\n  Prompt types: {prompt_types}")
    click.echo(f"  Total evaluations: {len(samples) * len(prompt_types)}")


if __name__ == "__main__":
    generate_samples()
