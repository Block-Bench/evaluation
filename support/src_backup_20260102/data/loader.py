"""
Data loader for transformed smart contract datasets.

Handles:
- Loading samples from transformation directories (sanitized, nocomments, chameleon)
- Mapping transformed IDs back to original IDs for ground truth lookup
- Stratified sampling from subsets (ds, tc, gs)
- Loading contract code and ground truth metadata
- "oneforall" sampling: sample base IDs, get all transformations for each
"""

import json
import random
import re
from pathlib import Path
from typing import Optional

from .schema import (
    Sample,
    GroundTruth,
    DataConfig,
    SamplingConfig,
    SamplingStrategy,
)


class DatasetLoader:
    """Load and sample from transformed smart contract datasets."""

    # Transformation prefixes - maps transformation path to filename prefix
    TRANSFORM_PREFIXES = {
        "sanitized": "sn_",
        "nocomments": "nc_",
        "chameleon/gaming_sn": "ch_gaming_sn_",
        "chameleon/gaming_nc": "ch_gaming_nc_",
        "chameleon/medical_sn": "ch_medical_sn_",
        "chameleon/medical_nc": "ch_medical_nc_",
        "mirror/compressed": "mr_compressed_nc_",
        "mirror/expanded": "mr_expanded_nc_",
        "mirror/minified": "mr_minified_nc_",
        "mirror/allman": "mr_allman_nc_",
        "mirror/knr": "mr_knr_nc_",
        "crossdomain/gaming_no": "cd_gaming_nc_",
        "crossdomain/gaming_sa": "cd_gaming_sa_",
        "crossdomain/healthcare_no": "cd_healthcare_nc_",
        "crossdomain/healthcare_sa": "cd_healthcare_sa_",
        "crossdomain/logistics_no": "cd_logistics_nc_",
        "crossdomain/logistics_sa": "cd_logistics_sa_",
        "crossdomain/social_no": "cd_social_nc_",
        "crossdomain/social_sa": "cd_social_sa_",
        "hydra/int_nc": "hy_int_nc_",
        "hydra/int_sn": "hy_int_sn_",
        "guardianshield/access_control_no": "gs_access_control_nc_",
        "guardianshield/access_control_sa": "gs_access_control_sa_",
        "guardianshield/cei_pattern_no": "gs_cei_pattern_nc_",
        "guardianshield/cei_pattern_sa": "gs_cei_pattern_sa_",
        "guardianshield/reentrancy_guard_no": "gs_reentrancy_guard_nc_",
        "guardianshield/reentrancy_guard_sa": "gs_reentrancy_guard_sa_",
        "guardianshield/solidity_0_8_no": "gs_solidity_0_8_nc_",
        "guardianshield/solidity_0_8_sa": "gs_solidity_0_8_sa_",
    }

    # Subset prefixes (original IDs)
    SUBSET_PREFIXES = {
        "ds": "ds_",  # difficulty_stratified
        "tc": "tc_",  # temporal_contamination
        "gs": "gs_",  # gold_standard
    }

    def __init__(self, config: DataConfig):
        """
        Initialize the data loader.

        Args:
            config: Data configuration with paths and sampling settings
        """
        self.config = config
        self.data_root = Path(config.root)
        self.ground_truth_path = Path(config.ground_truth_path)

        # Validate paths exist
        if not self.data_root.exists():
            raise ValueError(f"Data root not found: {self.data_root}")
        if not self.ground_truth_path.exists():
            raise ValueError(f"Ground truth path not found: {self.ground_truth_path}")

        # Set random seed for reproducibility
        random.seed(config.seed)

    def extract_original_id(self, transformed_id: str, transformation: str) -> str:
        """
        Extract the original ID from a transformed ID.

        Examples:
            sn_ds_001 -> ds_001
            nc_tc_005 -> tc_005
            ch_gaming_sn_gs_010 -> gs_010
        """
        prefix = self.TRANSFORM_PREFIXES.get(transformation, "")
        if prefix and transformed_id.startswith(prefix):
            return transformed_id[len(prefix):]

        # Fallback: try to extract using regex for chameleon variants
        # Pattern: ch_{theme}_{source}_{original_id}
        match = re.match(r"ch_\w+_(?:sn|nc)_(.+)", transformed_id)
        if match:
            return match.group(1)

        # If no prefix matches, return as-is (shouldn't happen normally)
        return transformed_id

    def get_subset_from_id(self, original_id: str) -> str:
        """
        Determine the subset (ds, tc, gs) from an original ID.

        Examples:
            ds_001 -> ds
            tc_005 -> tc
            gs_010 -> gs
        """
        for subset, prefix in self.SUBSET_PREFIXES.items():
            if original_id.startswith(prefix):
                return subset
        return "unknown"

    def discover_samples(self, transformation: str) -> list[Sample]:
        """
        Discover all samples for a given transformation.

        Args:
            transformation: Transformation type (e.g., "sanitized", "nocomments", "chameleon/gaming_sn")

        Returns:
            List of Sample objects (without contract code loaded)
        """
        transform_dir = self.data_root / transformation

        # Handle both flat (nocomments/contracts/) and nested (chameleon/gaming_sn/contracts/) structures
        contracts_dir = transform_dir / "contracts"
        if not contracts_dir.exists():
            # Try flat structure where .sol files are directly in the transformation folder
            contracts_dir = transform_dir

        if not contracts_dir.exists():
            raise ValueError(f"Transformation directory not found: {transform_dir}")

        samples = []
        sol_files = list(contracts_dir.glob("*.sol"))

        if not sol_files:
            raise ValueError(f"No .sol files found in: {contracts_dir}")

        for contract_file in sorted(sol_files):
            # Extract IDs
            transformed_id = contract_file.stem  # e.g., sn_ds_001
            original_id = self.extract_original_id(transformed_id, transformation)
            subset = self.get_subset_from_id(original_id)

            # Check for metadata file
            metadata_file = transform_dir / "metadata" / f"{transformed_id}.json"

            sample = Sample(
                id=original_id,
                transformed_id=transformed_id,
                transformation=transformation,
                subset=subset,
                contract_file=str(contract_file),
                metadata_file=str(metadata_file) if metadata_file.exists() else None,
            )
            samples.append(sample)

        return samples

    def discover_base_ids(self) -> list[str]:
        """
        Discover all base IDs from the base directory.

        Returns:
            List of original IDs (e.g., ["ds_001", "ds_002", "tc_001", ...])
        """
        base_dir = self.data_root / "base" / "contracts"
        if not base_dir.exists():
            raise ValueError(f"Base contracts directory not found: {base_dir}")

        base_ids = []
        for contract_file in sorted(base_dir.glob("*.sol")):
            base_ids.append(contract_file.stem)
        return base_ids

    def find_transformed_file(self, base_id: str, transformation: str) -> Optional[Path]:
        """
        Find the transformed file for a given base ID and transformation.

        Args:
            base_id: Original ID (e.g., "ds_001")
            transformation: Transformation type (e.g., "nocomments", "chameleon/gaming_sn")

        Returns:
            Path to the transformed file if it exists, None otherwise
        """
        prefix = self.TRANSFORM_PREFIXES.get(transformation, "")
        transformed_id = f"{prefix}{base_id}"

        transform_dir = self.data_root / transformation

        # Try contracts subdirectory first
        contract_path = transform_dir / "contracts" / f"{transformed_id}.sol"
        if contract_path.exists():
            return contract_path

        # Try flat structure
        contract_path = transform_dir / f"{transformed_id}.sol"
        if contract_path.exists():
            return contract_path

        return None

    def load_samples_oneforall(
        self,
        transformations: list[str],
        sampling: SamplingConfig,
        load_code: bool = True,
        load_ground_truth: bool = True,
    ) -> list[Sample]:
        """
        Load samples using oneforall strategy: sample base IDs, then get all transformations.

        Args:
            transformations: List of transformations to include
            sampling: Sampling configuration with counts per subset
            load_code: Whether to load contract code
            load_ground_truth: Whether to load ground truth

        Returns:
            List of Sample objects
        """
        # Discover all base IDs
        all_base_ids = self.discover_base_ids()

        # Filter by difficulty tier if specified
        if sampling.min_difficulty is not None:
            filtered_base_ids = []
            for base_id in all_base_ids:
                gt = self.load_ground_truth(base_id)
                if gt and gt.difficulty_tier is not None and gt.difficulty_tier >= sampling.min_difficulty:
                    filtered_base_ids.append(base_id)
            all_base_ids = filtered_base_ids

        # Group by subset
        base_ids_by_subset = {"ds": [], "tc": [], "gs": []}
        for base_id in all_base_ids:
            subset = self.get_subset_from_id(base_id)
            if subset in base_ids_by_subset:
                base_ids_by_subset[subset].append(base_id)

        # Sample from each subset
        sampled_base_ids = []
        for subset, count in [("ds", sampling.ds), ("tc", sampling.tc), ("gs", sampling.gs)]:
            available = base_ids_by_subset.get(subset, [])
            if count is None or count >= len(available):
                sampled_base_ids.extend(available)
            else:
                sampled_base_ids.extend(random.sample(available, count))

        # For each sampled base ID, get all configured transformations
        all_samples = []
        for base_id in sampled_base_ids:
            for transformation in transformations:
                contract_path = self.find_transformed_file(base_id, transformation)
                if contract_path is None:
                    # Transformation doesn't have this file, skip
                    continue

                prefix = self.TRANSFORM_PREFIXES.get(transformation, "")
                transformed_id = f"{prefix}{base_id}"
                subset = self.get_subset_from_id(base_id)

                # Check for metadata file
                transform_dir = self.data_root / transformation
                metadata_file = transform_dir / "metadata" / f"{transformed_id}.json"

                sample = Sample(
                    id=base_id,
                    transformed_id=transformed_id,
                    transformation=transformation,
                    subset=subset,
                    contract_file=str(contract_path),
                    metadata_file=str(metadata_file) if metadata_file.exists() else None,
                )

                if load_code:
                    sample.contract_code = self.load_contract_code(sample)
                if load_ground_truth:
                    sample.ground_truth = self.load_ground_truth(base_id)

                all_samples.append(sample)

        return all_samples

    def load_contract_code(self, sample: Sample) -> str:
        """Load the contract source code for a sample."""
        contract_path = Path(sample.contract_file)
        if not contract_path.exists():
            raise FileNotFoundError(f"Contract file not found: {contract_path}")
        return contract_path.read_text(encoding="utf-8")

    def load_ground_truth(self, original_id: str) -> Optional[GroundTruth]:
        """
        Load ground truth from annotated metadata.

        Args:
            original_id: Original sample ID (e.g., ds_001, tc_001)

        Returns:
            GroundTruth object or None if not found
        """
        gt_file = self.ground_truth_path / f"{original_id}.json"

        if not gt_file.exists():
            return None

        try:
            data = json.loads(gt_file.read_text(encoding="utf-8"))

            # Handle different metadata formats (ds vs tc have different schemas)
            return GroundTruth(
                id=original_id,
                is_vulnerable=data.get("is_vulnerable", True),
                vulnerability_type=data.get("vulnerability_type"),
                severity=data.get("severity"),
                vulnerable_contract=data.get("vulnerable_contract"),
                vulnerable_function=data.get("vulnerable_function"),
                vulnerable_lines=data.get("vulnerable_lines", []),
                description=data.get("description"),
                root_cause=data.get("root_cause"),
                attack_scenario=data.get("attack_scenario"),
                fix_description=data.get("fix_description"),
                difficulty_tier=data.get("difficulty_tier"),
                original_subset=data.get("original_subset"),
                tags=data.get("tags", []),
            )
        except Exception as e:
            print(f"Warning: Failed to load ground truth for {original_id}: {e}")
            return None

    def sample_from_subset(
        self,
        samples: list[Sample],
        subset: str,
        count: Optional[int]
    ) -> list[Sample]:
        """
        Sample n items from a specific subset.

        Args:
            samples: List of all samples
            subset: Subset to filter by (ds, tc, gs)
            count: Number of samples to take (None = all)

        Returns:
            Sampled list of samples
        """
        subset_samples = [s for s in samples if s.subset == subset]

        if count is None or count >= len(subset_samples):
            return subset_samples

        return random.sample(subset_samples, count)

    def load_samples(
        self,
        transformations: Optional[list[str]] = None,
        sampling: Optional[SamplingConfig] = None,
        load_code: bool = True,
        load_ground_truth: bool = True,
    ) -> list[Sample]:
        """
        Load samples from specified transformations with optional sampling.

        Args:
            transformations: List of transformations to load (default: from config)
            sampling: Sampling configuration (default: from config)
            load_code: Whether to load contract code
            load_ground_truth: Whether to load ground truth

        Returns:
            List of Sample objects
        """
        transformations = transformations or self.config.transformations
        sampling = sampling or self.config.sampling

        # Check if using oneforall strategy
        if sampling and sampling.strategy == "oneforall":
            return self.load_samples_oneforall(
                transformations=transformations,
                sampling=sampling,
                load_code=load_code,
                load_ground_truth=load_ground_truth,
            )

        # Default: independent sampling per transformation
        all_samples = []

        for transformation in transformations:
            # Discover all samples for this transformation
            transform_samples = self.discover_samples(transformation)

            # Apply sampling per subset
            sampled = []
            if sampling:
                for subset, count in [
                    ("ds", sampling.ds),
                    ("tc", sampling.tc),
                    ("gs", sampling.gs),
                ]:
                    subset_sampled = self.sample_from_subset(
                        transform_samples, subset, count
                    )
                    sampled.extend(subset_sampled)
            else:
                sampled = transform_samples

            # Load code and ground truth
            for sample in sampled:
                if load_code:
                    sample.contract_code = self.load_contract_code(sample)
                if load_ground_truth:
                    sample.ground_truth = self.load_ground_truth(sample.id)

            all_samples.extend(sampled)

        return all_samples

    def get_statistics(self, samples: list[Sample]) -> dict:
        """Get statistics about loaded samples."""
        stats = {
            "total": len(samples),
            "by_transformation": {},
            "by_subset": {},
            "by_vulnerability_type": {},
            "with_ground_truth": 0,
        }

        for sample in samples:
            # By transformation
            t = sample.transformation
            stats["by_transformation"][t] = stats["by_transformation"].get(t, 0) + 1

            # By subset
            s = sample.subset
            stats["by_subset"][s] = stats["by_subset"].get(s, 0) + 1

            # By vulnerability type
            if sample.ground_truth:
                stats["with_ground_truth"] += 1
                vt = sample.ground_truth.vulnerability_type or "unknown"
                stats["by_vulnerability_type"][vt] = (
                    stats["by_vulnerability_type"].get(vt, 0) + 1
                )

        return stats


def load_config(config_path: str) -> DataConfig:
    """Load data configuration from YAML file."""
    import yaml

    with open(config_path) as f:
        config_dict = yaml.safe_load(f)

    data_config = config_dict.get("data", {})

    sampling = None
    if "sampling" in data_config:
        sampling = SamplingConfig(**data_config["sampling"])

    return DataConfig(
        root=data_config.get("root", "./raw/data"),
        ground_truth_path=data_config.get(
            "ground_truth_path", "./raw/data/annotated/metadata"
        ),
        transformations=data_config.get("transformations", ["sanitized"]),
        sampling=sampling,
        seed=data_config.get("seed", 42),
    )
