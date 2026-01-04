"""
Loader for GS (Gold Standard) dataset.

The GS dataset contains expert-validated samples with high-confidence
ground truth, used as the benchmark for evaluating other components.
"""

import json
from pathlib import Path
from typing import Iterator, Optional

from ..base import BaseLoader, Sample, DatasetInfo


class GSLoader(BaseLoader):
    """Loader for the Gold Standard dataset."""

    def __init__(self, base_path: Path):
        """
        Initialize GS loader.

        Args:
            base_path: Path to the samples/gs directory
        """
        super().__init__("gs", base_path)

    def load_sample(self, sample_id: str) -> Sample:
        """Load a single sample by ID."""
        for sol_file in self.base_path.glob("*.sol"):
            if sample_id in sol_file.stem or sol_file.stem == sample_id:
                return self._load_from_file(sol_file)

        for sol_file in self.base_path.rglob("*.sol"):
            if sample_id in sol_file.stem or sol_file.stem == sample_id:
                return self._load_from_file(sol_file)

        raise FileNotFoundError(f"Sample not found: {sample_id}")

    def load_all(self) -> list[Sample]:
        """Load all samples from the GS dataset."""
        return list(self.iter_samples())

    def iter_samples(self) -> Iterator[Sample]:
        """Iterate over all GS samples."""
        for sol_file in sorted(self.base_path.rglob("*.sol")):
            yield self._load_from_file(sol_file)

    def _load_from_file(self, sol_file: Path) -> Sample:
        """Load a sample from a Solidity file."""
        code = sol_file.read_text()

        meta_file = sol_file.with_suffix(".json")
        metadata = {}

        if meta_file.exists():
            with open(meta_file) as f:
                metadata = json.load(f)

        sample_id = sol_file.stem

        contract_name = metadata.get("contract_name")
        if not contract_name:
            contract_name = self._extract_contract_name(code)

        return Sample(
            sample_id=sample_id,
            code=code,
            contract_name=contract_name,
            dataset_type="gs",
            tier=None,  # GS doesn't have tiers
            vulnerability_type=metadata.get("vulnerability_type", "unknown"),
            vulnerability_location=metadata.get("location"),
            vulnerability_description=metadata.get("description"),
            severity=metadata.get("severity"),
            source_file=sol_file,
            language="solidity"
        )

    def _extract_contract_name(self, code: str) -> Optional[str]:
        """Extract contract name from Solidity code."""
        import re
        match = re.search(r'contract\s+(\w+)', code)
        return match.group(1) if match else None

    def get_dataset_info(self) -> DatasetInfo:
        """Get information about the GS dataset."""
        vuln_types = set()
        samples = list(self.iter_samples())

        for sample in samples:
            vuln_types.add(sample.vulnerability_type)

        return DatasetInfo(
            dataset_type="gs",
            total_samples=len(samples),
            tier_distribution=None,
            vulnerability_types=sorted(vuln_types),
            path=self.base_path
        )
