"""
Load samples from the pre-generated samples folder.

This loader reads from:
- samples/manifest.json - Sample list and metadata
- samples/contracts/ - Contract source files
- samples/ground_truth/ - Ground truth metadata
"""

import json
from pathlib import Path
from typing import Optional

from .schema import Sample, GroundTruth


class SampleLoader:
    """Load samples from pre-generated samples folder."""

    def __init__(self, samples_dir: str = "samples"):
        """
        Initialize the sample loader.

        Args:
            samples_dir: Path to samples directory
        """
        self.samples_dir = Path(samples_dir)
        self.manifest_path = self.samples_dir / "manifest.json"
        self.contracts_dir = self.samples_dir / "contracts"
        self.ground_truth_dir = self.samples_dir / "ground_truth"

        # Load manifest
        if not self.manifest_path.exists():
            raise FileNotFoundError(
                f"Samples manifest not found: {self.manifest_path}\n"
                "Run 'python scripts/generate_samples.py' first."
            )

        with open(self.manifest_path) as f:
            self.manifest = json.load(f)

    @property
    def prompt_types(self) -> list[str]:
        """Get prompt types from manifest."""
        return self.manifest.get("prompt_types", ["direct", "naturalistic", "adversarial"])

    @property
    def total_samples(self) -> int:
        """Get total number of samples."""
        return self.manifest.get("total_samples", 0)

    @property
    def total_evaluations(self) -> int:
        """Get total number of evaluations (samples × prompt types)."""
        return self.manifest.get("total_evaluations", 0)

    def load_contract(self, transformed_id: str) -> str:
        """Load contract source code."""
        contract_path = self.contracts_dir / f"{transformed_id}.sol"
        if not contract_path.exists():
            raise FileNotFoundError(f"Contract not found: {contract_path}")
        return contract_path.read_text(encoding="utf-8")

    def load_ground_truth(self, sample_id: str) -> Optional[GroundTruth]:
        """Load ground truth metadata."""
        gt_path = self.ground_truth_dir / f"{sample_id}.json"
        if not gt_path.exists():
            return None

        with open(gt_path) as f:
            data = json.load(f)

        return GroundTruth(**data)

    def load_samples(
        self,
        load_code: bool = True,
        load_ground_truth: bool = True,
    ) -> list[Sample]:
        """
        Load all samples from the manifest.

        Args:
            load_code: Whether to load contract code
            load_ground_truth: Whether to load ground truth

        Returns:
            List of Sample objects
        """
        samples = []

        for entry in self.manifest.get("samples", []):
            sample = Sample(
                id=entry["id"],
                transformed_id=entry["transformed_id"],
                transformation=entry["transformation"],
                subset=entry["subset"],
                contract_file=str(self.contracts_dir / f"{entry['transformed_id']}.sol"),
            )

            if load_code:
                sample.contract_code = self.load_contract(entry["transformed_id"])

            if load_ground_truth:
                sample.ground_truth = self.load_ground_truth(entry["id"])

            samples.append(sample)

        return samples

    def get_statistics(self) -> dict:
        """Get statistics from manifest."""
        samples = self.manifest.get("samples", [])

        stats = {
            "total": len(samples),
            "by_transformation": {},
            "by_subset": {},
            "prompt_types": self.prompt_types,
            "total_evaluations": self.total_evaluations,
        }

        for s in samples:
            t = s.get("transformation", "unknown")
            stats["by_transformation"][t] = stats["by_transformation"].get(t, 0) + 1

            subset = s.get("subset", "unknown")
            stats["by_subset"][subset] = stats["by_subset"].get(subset, 0) + 1

        return stats


def samples_exist(samples_dir: str = "samples") -> bool:
    """Check if samples folder exists with manifest."""
    manifest_path = Path(samples_dir) / "manifest.json"
    return manifest_path.exists()
