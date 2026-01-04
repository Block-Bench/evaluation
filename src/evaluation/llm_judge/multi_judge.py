"""
Multi-Judge Orchestrator for running multiple LLM judges and aggregating results.

Supports:
- Running multiple judges in parallel
- Majority voting for final verdict
- Inter-judge agreement metrics
- Per-judge and aggregated results
"""

import asyncio
import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from .providers import create_judge
from .prompts import (
    get_judge_system_prompt,
    get_judge_user_prompt,
    get_traditional_tool_system_prompt,
    get_traditional_tool_user_prompt
)
from ..base import EvaluationResult


@dataclass
class MultiJudgeResult:
    """Result from multi-judge evaluation."""
    sample_id: str
    detection_source: str
    detection_model: str

    # Per-judge results
    judge_results: dict  # judge_name -> EvaluationResult

    # Aggregated results (majority vote)
    majority_target_found: bool
    majority_verdict_correct: bool
    majority_true_positives: int
    majority_false_positives: int

    # Agreement metrics
    target_found_agreement: float  # 0-1, proportion agreeing with majority
    verdict_agreement: float
    full_agreement: bool  # All judges agree on target_found

    # Metadata
    timestamp: str
    num_judges: int


class MultiJudgeOrchestrator:
    """
    Orchestrates multiple LLM judges for evaluation.

    Runs judges in parallel and aggregates results using majority voting.
    """

    def __init__(self, judge_configs: list):
        """
        Initialize with judge configurations.

        Args:
            judge_configs: List of JudgeModelConfig instances
        """
        self.judge_configs = judge_configs
        self.judges = {}

        # Initialize judges
        for config in judge_configs:
            self.judges[config.name] = create_judge(config)

    async def evaluate_sample(
        self,
        detection_output: dict,
        ground_truth: dict,
        code_snippet: str = "",
        is_traditional_tool: bool = False
    ) -> MultiJudgeResult:
        """
        Evaluate a single sample with all judges.

        Args:
            detection_output: Detection result to evaluate
            ground_truth: Ground truth information
            code_snippet: Contract source code
            is_traditional_tool: Whether detection is from traditional tool

        Returns:
            MultiJudgeResult with per-judge and aggregated results
        """
        # Run all judges in parallel
        tasks = []
        judge_names = []

        for name, judge in self.judges.items():
            judge_names.append(name)
            task = self._run_single_judge(
                judge,
                detection_output,
                ground_truth,
                code_snippet,
                is_traditional_tool
            )
            tasks.append(task)

        # Wait for all judges
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Collect successful results
        judge_results = {}
        for name, result in zip(judge_names, results):
            if isinstance(result, Exception):
                # Create error result for failed judge
                judge_results[name] = self._create_error_result(
                    detection_output, name, str(result)
                )
            else:
                judge_results[name] = result

        # Aggregate results
        return self._aggregate_results(
            detection_output,
            judge_results
        )

    async def _run_single_judge(
        self,
        judge,
        detection_output: dict,
        ground_truth: dict,
        code_snippet: str,
        is_traditional_tool: bool
    ) -> EvaluationResult:
        """Run a single judge evaluation."""
        # Build appropriate prompts
        if is_traditional_tool:
            system_prompt = get_traditional_tool_system_prompt()
            user_prompt = get_traditional_tool_user_prompt(
                detection_output, ground_truth, code_snippet
            )
        else:
            system_prompt = get_judge_system_prompt()
            user_prompt = get_judge_user_prompt(
                detection_output, ground_truth, code_snippet
            )

        # Call LLM
        response = await judge.call_llm(system_prompt, user_prompt)

        # Parse response
        result = judge.parse_evaluation_response(response, detection_output)

        return result

    def _aggregate_results(
        self,
        detection_output: dict,
        judge_results: dict
    ) -> MultiJudgeResult:
        """Aggregate results from multiple judges using majority voting."""
        sample_id = detection_output.get("sample_id", "unknown")
        detection_source = "traditional" if detection_output.get("tool") else "llm"
        detection_model = detection_output.get("model") or detection_output.get("tool", "unknown")

        # Collect votes
        target_found_votes = []
        verdict_correct_votes = []
        tp_counts = []
        fp_counts = []

        for name, result in judge_results.items():
            if result.confidence > 0:  # Only count non-error results
                target_found_votes.append(result.target_vulnerability_found)
                verdict_correct_votes.append(result.detection_verdict_correct)
                tp_counts.append(result.true_positives)
                fp_counts.append(result.false_positives)

        # Majority voting
        num_valid = len(target_found_votes)
        if num_valid == 0:
            # All judges failed
            majority_target_found = False
            majority_verdict_correct = False
            majority_tp = 0
            majority_fp = 0
            target_found_agreement = 0.0
            verdict_agreement = 0.0
            full_agreement = False
        else:
            # Calculate majorities
            majority_target_found = sum(target_found_votes) > num_valid / 2
            majority_verdict_correct = sum(verdict_correct_votes) > num_valid / 2

            # For TP/FP, use median (more robust than mean)
            tp_counts.sort()
            fp_counts.sort()
            mid = num_valid // 2
            majority_tp = tp_counts[mid] if tp_counts else 0
            majority_fp = fp_counts[mid] if fp_counts else 0

            # Calculate agreement rates
            target_found_agreement = sum(
                1 for v in target_found_votes if v == majority_target_found
            ) / num_valid
            verdict_agreement = sum(
                1 for v in verdict_correct_votes if v == majority_verdict_correct
            ) / num_valid
            full_agreement = len(set(target_found_votes)) == 1

        return MultiJudgeResult(
            sample_id=sample_id,
            detection_source=detection_source,
            detection_model=detection_model,
            judge_results=judge_results,
            majority_target_found=majority_target_found,
            majority_verdict_correct=majority_verdict_correct,
            majority_true_positives=majority_tp,
            majority_false_positives=majority_fp,
            target_found_agreement=target_found_agreement,
            verdict_agreement=verdict_agreement,
            full_agreement=full_agreement,
            timestamp=datetime.now(timezone.utc).isoformat(),
            num_judges=len(self.judges)
        )

    def _create_error_result(
        self,
        detection_output: dict,
        judge_name: str,
        error_msg: str
    ) -> EvaluationResult:
        """Create error result for a failed judge."""
        detection_source = "traditional" if detection_output.get("tool") else "llm"

        return EvaluationResult(
            sample_id=detection_output.get("sample_id", "unknown"),
            evaluator_type="llm_judge",
            detection_source=detection_source,
            detection_model=detection_output.get("model") or detection_output.get("tool", "unknown"),
            detection_verdict_correct=False,
            target_vulnerability_found=False,
            target_finding_id=None,
            target_explanation_quality=None,
            target_fix_quality=None,
            target_attack_scenario_quality=None,
            total_findings=0,
            true_positives=0,
            false_positives=0,
            hallucinations=0,
            evaluator_model=judge_name,
            confidence=0.0,
            reasoning=f"Judge error: {error_msg}",
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    async def evaluate_batch(
        self,
        detection_outputs: list[dict],
        ground_truths: list[dict],
        code_snippets: list[str] = None,
        is_traditional_tool: bool = False,
        max_concurrent: int = 5
    ) -> list[MultiJudgeResult]:
        """
        Evaluate a batch of samples with all judges.

        Args:
            detection_outputs: List of detection results
            ground_truths: List of ground truth dicts
            code_snippets: List of code snippets (optional)
            is_traditional_tool: Whether detections are from traditional tools
            max_concurrent: Maximum concurrent evaluations

        Returns:
            List of MultiJudgeResult
        """
        if code_snippets is None:
            code_snippets = [""] * len(detection_outputs)

        results = []
        semaphore = asyncio.Semaphore(max_concurrent)

        async def bounded_evaluate(detection, gt, code):
            async with semaphore:
                return await self.evaluate_sample(
                    detection, gt, code, is_traditional_tool
                )

        tasks = [
            bounded_evaluate(d, g, c)
            for d, g, c in zip(detection_outputs, ground_truths, code_snippets)
        ]

        results = await asyncio.gather(*tasks)
        return results


def save_multi_judge_result(
    result: MultiJudgeResult,
    output_dir: Path,
    prefix: str = "mj"
) -> Path:
    """
    Save multi-judge result to file.

    Args:
        result: MultiJudgeResult to save
        output_dir: Directory to save to
        prefix: Filename prefix

    Returns:
        Path to saved file
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    # Convert to dict
    output = {
        "sample_id": result.sample_id,
        "detection_source": result.detection_source,
        "detection_model": result.detection_model,
        "aggregated": {
            "majority_target_found": result.majority_target_found,
            "majority_verdict_correct": result.majority_verdict_correct,
            "majority_true_positives": result.majority_true_positives,
            "majority_false_positives": result.majority_false_positives,
        },
        "agreement": {
            "target_found_agreement": result.target_found_agreement,
            "verdict_agreement": result.verdict_agreement,
            "full_agreement": result.full_agreement,
            "num_judges": result.num_judges
        },
        "per_judge": {},
        "metadata": {
            "timestamp": result.timestamp
        }
    }

    # Add per-judge results
    for judge_name, judge_result in result.judge_results.items():
        output["per_judge"][judge_name] = {
            "target_vulnerability_found": judge_result.target_vulnerability_found,
            "detection_verdict_correct": judge_result.detection_verdict_correct,
            "true_positives": judge_result.true_positives,
            "false_positives": judge_result.false_positives,
            "hallucinations": judge_result.hallucinations,
            "confidence": judge_result.confidence,
            "reasoning": judge_result.reasoning
        }

    # Save
    filepath = output_dir / f"{prefix}_{result.sample_id}.json"
    with open(filepath, 'w') as f:
        json.dump(output, f, indent=2)

    return filepath
