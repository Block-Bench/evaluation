"""
Loader for DS (Difficulty-Stratified) dataset.

The DS dataset is organized by difficulty tiers (tier1-4), with each
sample containing a vulnerable smart contract and ground truth metadata.
"""

import json
from pathlib import Path
from typing import Iterator, Optional

from ..base import BaseLoader, Sample, DatasetInfo


class DSLoader(BaseLoader):
    """Loader for the Difficulty-Stratified dataset."""

    TIERS = ["tier1", "tier2", "tier3", "tier4"]

    def __init__(self, base_path: Path):
        """
        Initialize DS loader.

        Args:
            base_path: Path to the samples/ds directory
        """
        super().__init__("ds", base_path)

    def load_sample(self, sample_id: str) -> Sample:
        """
        Load a single sample by ID.

        Expected sample_id format: "ds_t1_001" or similar
        """
        # Search in all tiers for the sample
        for tier in self.TIERS:
            tier_path = self.base_path / tier
            contracts_path = tier_path / "contracts"

            if not contracts_path.exists():
                continue

            # Try to find the sample file
            for sol_file in contracts_path.glob("*.sol"):
                if sample_id in sol_file.stem or sol_file.stem == sample_id:
                    return self._load_from_file(sol_file, tier)

        raise FileNotFoundError(f"Sample not found: {sample_id}")

    def load_all(self) -> list[Sample]:
        """Load all samples from all tiers."""
        return list(self.iter_samples())

    def iter_samples(self) -> Iterator[Sample]:
        """Iterate over all samples across tiers."""
        for tier in self.TIERS:
            tier_path = self.base_path / tier
            contracts_path = tier_path / "contracts"

            if not contracts_path.exists():
                continue

            for sol_file in sorted(contracts_path.glob("*.sol")):
                yield self._load_from_file(sol_file, tier)

    def load_tier(self, tier: str) -> list[Sample]:
        """Load all samples from a specific tier."""
        tier_path = self.base_path / tier
        contracts_path = tier_path / "contracts"

        if not contracts_path.exists():
            raise FileNotFoundError(f"Tier not found: {tier}")

        samples = []
        for sol_file in sorted(contracts_path.glob("*.sol")):
            samples.append(self._load_from_file(sol_file, tier))

        return samples

    def _load_from_file(self, sol_file: Path, tier: str) -> Sample:
        """Load a sample from a Solidity file."""
        # Read the code
        code = sol_file.read_text()

        # Ground truth is in sibling ground_truth/ directory
        tier_path = sol_file.parent.parent
        ground_truth_file = tier_path / "ground_truth" / f"{sol_file.stem}.json"
        ground_truth = {}

        if ground_truth_file.exists():
            with open(ground_truth_file) as f:
                ground_truth = json.load(f)

        # Extract sample ID
        sample_id = sol_file.stem

        # Extract contract name from code or metadata
        contract_name = self._extract_contract_name(code)

        # Handle both flat and nested ground truth formats
        vuln_type = ground_truth.get("vulnerability_type", "unknown")
        if "ground_truth" in ground_truth:
            # Nested format (GS style)
            gt_data = ground_truth["ground_truth"]
            vuln_type = gt_data.get("vulnerability_type", vuln_type)
            severity = gt_data.get("severity")
            description = gt_data.get("root_cause") or gt_data.get("description")
            location = gt_data.get("vulnerable_location", {})
            vuln_location = location.get("function_name") if isinstance(location, dict) else None
        else:
            # Flat format (DS style)
            severity = ground_truth.get("severity")
            description = ground_truth.get("description")
            vuln_functions = ground_truth.get("vulnerable_functions", [])
            vuln_location = vuln_functions[0] if vuln_functions else None

        return Sample(
            sample_id=sample_id,
            code=code,
            contract_name=contract_name,
            dataset_type="ds",
            tier=tier,
            vulnerability_type=vuln_type,
            vulnerability_location=vuln_location,
            vulnerability_description=description,
            severity=severity,
            source_file=sol_file,
            language="solidity"
        )

    def _extract_contract_name(self, code: str) -> Optional[str]:
        """Extract contract name from Solidity code."""
        import re
        match = re.search(r'contract\s+(\w+)', code)
        return match.group(1) if match else None

    def get_dataset_info(self) -> DatasetInfo:
        """Get information about the DS dataset."""
        tier_dist = {}
        vuln_types = set()

        for tier in self.TIERS:
            tier_path = self.base_path / tier
            contracts_path = tier_path / "contracts"
            if contracts_path.exists():
                count = len(list(contracts_path.glob("*.sol")))
                tier_dist[tier] = count

                for sample in self.load_tier(tier):
                    vuln_types.add(sample.vulnerability_type)

        return DatasetInfo(
            dataset_type="ds",
            total_samples=sum(tier_dist.values()),
            tier_distribution=tier_dist,
            vulnerability_types=sorted(vuln_types),
            path=self.base_path
        )
