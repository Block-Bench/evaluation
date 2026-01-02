"""
Loader for detection and evaluation results.

Loads outputs from the results/ directory structure.
"""

import json
from pathlib import Path
from typing import Iterator, Optional


class DetectionResultsLoader:
    """Loader for detection results."""

    def __init__(self, results_path: Path):
        """
        Initialize results loader.

        Args:
            results_path: Path to results/detection directory
        """
        self.base_path = Path(results_path)

    def load_llm_result(
        self,
        model: str,
        sample_id: str,
        prompt_type: str = "direct",
        dataset_type: str = "ds",
        tier: Optional[str] = None
    ) -> dict:
        """
        Load a single LLM detection result.

        Args:
            model: Model name
            sample_id: Sample ID
            prompt_type: Prompt type used
            dataset_type: Dataset type (ds, tc, gs)
            tier: Tier (for ds dataset)

        Returns:
            Detection result dictionary
        """
        if tier:
            path = self.base_path / "llm" / model / dataset_type / tier
        else:
            path = self.base_path / "llm" / model / dataset_type

        filename = f"d_{sample_id}_{prompt_type}.json"
        filepath = path / filename

        if not filepath.exists():
            raise FileNotFoundError(f"Result not found: {filepath}")

        with open(filepath) as f:
            return json.load(f)

    def load_traditional_result(
        self,
        tool: str,
        sample_id: str,
        dataset_type: str = "ds",
        tier: Optional[str] = None
    ) -> dict:
        """
        Load a single traditional tool detection result.

        Args:
            tool: Tool name (slither, mythril)
            sample_id: Sample ID
            dataset_type: Dataset type
            tier: Tier (for ds dataset)

        Returns:
            Detection result dictionary
        """
        if tier:
            path = self.base_path / "traditional" / tool / dataset_type / tier
        else:
            path = self.base_path / "traditional" / tool / dataset_type

        filename = f"d_{sample_id}.json"
        filepath = path / filename

        if not filepath.exists():
            raise FileNotFoundError(f"Result not found: {filepath}")

        with open(filepath) as f:
            return json.load(f)

    def iter_llm_results(
        self,
        model: str,
        dataset_type: str = "ds",
        prompt_type: Optional[str] = None
    ) -> Iterator[dict]:
        """
        Iterate over LLM detection results.

        Args:
            model: Model name
            dataset_type: Dataset type
            prompt_type: Optional filter by prompt type

        Yields:
            Detection result dictionaries
        """
        model_path = self.base_path / "llm" / model / dataset_type

        for json_file in model_path.rglob("*.json"):
            if prompt_type and prompt_type not in json_file.stem:
                continue

            with open(json_file) as f:
                yield json.load(f)

    def iter_traditional_results(
        self,
        tool: str,
        dataset_type: str = "ds"
    ) -> Iterator[dict]:
        """Iterate over traditional tool results."""
        tool_path = self.base_path / "traditional" / tool / dataset_type

        for json_file in tool_path.rglob("*.json"):
            with open(json_file) as f:
                yield json.load(f)


class EvaluationResultsLoader:
    """Loader for evaluation results."""

    def __init__(self, results_path: Path):
        """
        Initialize evaluation results loader.

        Args:
            results_path: Path to results/detection_evaluation directory
        """
        self.base_path = Path(results_path)

    def load_evaluation(
        self,
        evaluator_type: str,  # "llm", "human", "rule-based"
        detection_source: str,  # "llm", "traditional"
        model_or_tool: str,
        sample_id: str,
        dataset_type: str = "ds",
        tier: Optional[str] = None
    ) -> dict:
        """Load a single evaluation result."""
        if tier:
            path = self.base_path / evaluator_type / detection_source / model_or_tool / dataset_type / tier
        else:
            path = self.base_path / evaluator_type / detection_source / model_or_tool / dataset_type

        filename = f"e_{sample_id}.json"
        filepath = path / filename

        if not filepath.exists():
            raise FileNotFoundError(f"Evaluation not found: {filepath}")

        with open(filepath) as f:
            return json.load(f)

    def iter_evaluations(
        self,
        evaluator_type: str,
        detection_source: str,
        model_or_tool: str,
        dataset_type: str = "ds"
    ) -> Iterator[dict]:
        """Iterate over evaluation results."""
        path = self.base_path / evaluator_type / detection_source / model_or_tool / dataset_type

        for json_file in path.rglob("*.json"):
            with open(json_file) as f:
                yield json.load(f)


def get_available_models(results_path: Path) -> list[str]:
    """Get list of available LLM models in results."""
    llm_path = Path(results_path) / "detection" / "llm"
    if not llm_path.exists():
        return []
    return [d.name for d in llm_path.iterdir() if d.is_dir()]


def get_available_tools(results_path: Path) -> list[str]:
    """Get list of available traditional tools in results."""
    trad_path = Path(results_path) / "detection" / "traditional"
    if not trad_path.exists():
        return []
    return [d.name for d in trad_path.iterdir() if d.is_dir()]
