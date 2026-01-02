"""
Human review interface for manual evaluation.

This module provides utilities for creating review templates
and collecting human expert evaluations.
"""

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from ..base import BaseEvaluator, EvaluatorType, EvaluationResult


class HumanReviewInterface(BaseEvaluator):
    """
    Interface for human review evaluations.

    Generates review templates and processes completed reviews.
    """

    def __init__(self, reviewer_id: str):
        super().__init__(EvaluatorType.HUMAN)
        self.reviewer_id = reviewer_id

    def create_review_template(
        self,
        detection_output: dict,
        ground_truth: dict,
        code: str = ""
    ) -> dict:
        """
        Create a template for human review.

        Args:
            detection_output: Detection result to review
            ground_truth: Ground truth information
            code: Smart contract code

        Returns:
            Review template dictionary
        """
        parsed = detection_output.get("parsed_output", {})
        findings = parsed.get("vulnerabilities", [])

        # Create findings for review
        findings_for_review = []
        for i, finding in enumerate(findings):
            findings_for_review.append({
                "finding_id": f"finding_{i}",
                "type": finding.get("type", ""),
                "severity": finding.get("severity", ""),
                "location": finding.get("location", ""),
                "explanation": finding.get("explanation", ""),
                "attack_scenario": finding.get("attack_scenario", ""),
                "suggested_fix": finding.get("suggested_fix", ""),
                # Fields for human to fill
                "review": {
                    "classification": None,  # "true_positive" | "false_positive" | "hallucination"
                    "is_target_vulnerability": None,  # true/false
                    "quality_scores": {
                        "explanation": None,  # 1-5
                        "attack_scenario": None,  # 1-5
                        "fix_suggestion": None  # 1-5
                    },
                    "notes": ""
                }
            })

        return {
            "review_id": f"hr_{detection_output.get('sample_id', 'unknown')}_{self.reviewer_id}",
            "sample_id": detection_output.get("sample_id"),
            "reviewer_id": self.reviewer_id,
            "detection_model": detection_output.get("model", "unknown"),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "status": "pending",

            "ground_truth": {
                "vulnerability_type": ground_truth.get("vulnerability_type"),
                "location": ground_truth.get("location"),
                "description": ground_truth.get("description"),
                "severity": ground_truth.get("severity")
            },

            "detection_verdict": parsed.get("verdict"),
            "findings": findings_for_review,

            "code_context": code[:5000] if code else None,  # Truncate long code

            # Overall review fields
            "overall_review": {
                "detection_verdict_correct": None,  # true/false
                "target_vulnerability_found": None,  # true/false
                "overall_quality": None,  # 1-5
                "reviewer_notes": "",
                "time_spent_minutes": None
            }
        }

    def process_completed_review(self, review_data: dict) -> EvaluationResult:
        """
        Process a completed human review into an EvaluationResult.

        Args:
            review_data: Completed review dictionary

        Returns:
            EvaluationResult
        """
        findings = review_data.get("findings", [])
        overall = review_data.get("overall_review", {})

        # Count classifications
        tp = 0
        fp = 0
        hallucinations = 0
        target_finding_id = None
        target_scores = {"explanation": None, "attack_scenario": None, "fix": None}

        for finding in findings:
            review = finding.get("review", {})
            classification = review.get("classification", "")

            if classification == "true_positive":
                tp += 1
            elif classification == "false_positive":
                fp += 1
            elif classification == "hallucination":
                hallucinations += 1

            # Check if this is the target vulnerability
            if review.get("is_target_vulnerability"):
                target_finding_id = finding.get("finding_id")
                quality = review.get("quality_scores", {})
                target_scores = {
                    "explanation": quality.get("explanation"),
                    "attack_scenario": quality.get("attack_scenario"),
                    "fix": quality.get("fix_suggestion")
                }

        return EvaluationResult(
            sample_id=review_data.get("sample_id", "unknown"),
            evaluator_type="human",
            detection_source="llm",  # Assuming LLM for now
            detection_model=review_data.get("detection_model", "unknown"),
            detection_verdict_correct=overall.get("detection_verdict_correct", False),
            target_vulnerability_found=overall.get("target_vulnerability_found", False),
            target_finding_id=target_finding_id,
            target_explanation_quality=target_scores["explanation"],
            target_fix_quality=target_scores["fix"],
            target_attack_scenario_quality=target_scores["attack_scenario"],
            total_findings=len(findings),
            true_positives=tp,
            false_positives=fp,
            hallucinations=hallucinations,
            evaluator_model=None,
            confidence=1.0,  # Human reviews are high confidence
            reasoning=overall.get("reviewer_notes", ""),
            timestamp=review_data.get("completed_at", datetime.now(timezone.utc).isoformat())
        )

    def evaluate(
        self,
        detection_output: dict,
        ground_truth: dict,
        **kwargs
    ) -> EvaluationResult:
        """
        This method creates a template - actual evaluation is asynchronous.

        For synchronous evaluation, use process_completed_review with
        a filled-out review template.
        """
        raise NotImplementedError(
            "Human review is asynchronous. Use create_review_template() to "
            "generate a review form, then process_completed_review() after "
            "human completes the review."
        )

    def evaluate_batch(
        self,
        detection_outputs: list[dict],
        ground_truths: list[dict],
        **kwargs
    ) -> list[EvaluationResult]:
        """Generate review templates for batch processing."""
        raise NotImplementedError(
            "Use create_review_template() for each sample, then "
            "process_completed_review() after human review."
        )

    def save_template(self, template: dict, output_path: Path) -> None:
        """Save review template to file."""
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(template, f, indent=2)

    def load_completed_review(self, review_path: Path) -> dict:
        """Load a completed review from file."""
        with open(review_path, 'r') as f:
            return json.load(f)
