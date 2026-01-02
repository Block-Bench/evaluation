"""
Base classes for data loading.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Iterator


@dataclass
class Sample:
    """A single smart contract sample."""
    sample_id: str
    code: str
    contract_name: Optional[str]
    dataset_type: str          # "ds", "tc", "gs"
    tier: Optional[str]        # "tier1", "tier2", etc. (for ds)

    # Ground truth
    vulnerability_type: str
    vulnerability_location: Optional[str]
    vulnerability_description: Optional[str]
    severity: Optional[str]

    # Metadata
    source_file: Path
    language: str = "solidity"


class BaseLoader(ABC):
    """Abstract base class for dataset loaders."""

    def __init__(self, dataset_type: str, base_path: Path):
        self.dataset_type = dataset_type
        self.base_path = Path(base_path)

    @abstractmethod
    def load_sample(self, sample_id: str) -> Sample:
        """Load a single sample by ID."""
        pass

    @abstractmethod
    def load_all(self) -> list[Sample]:
        """Load all samples from the dataset."""
        pass

    @abstractmethod
    def iter_samples(self) -> Iterator[Sample]:
        """Iterate over samples lazily."""
        pass

    def get_sample_ids(self) -> list[str]:
        """Get all sample IDs in the dataset."""
        return [s.sample_id for s in self.iter_samples()]

    def get_ground_truth(self, sample_id: str) -> dict:
        """Get ground truth for a sample."""
        sample = self.load_sample(sample_id)
        return {
            "sample_id": sample.sample_id,
            "vulnerability_type": sample.vulnerability_type,
            "location": sample.vulnerability_location,
            "description": sample.vulnerability_description,
            "severity": sample.severity
        }


@dataclass
class DatasetInfo:
    """Information about a dataset."""
    dataset_type: str
    total_samples: int
    tier_distribution: Optional[dict[str, int]]
    vulnerability_types: list[str]
    path: Path
