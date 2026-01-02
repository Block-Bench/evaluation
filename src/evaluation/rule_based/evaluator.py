"""
Rule-based evaluator using keyword matching and heuristics.
"""

import re
from datetime import datetime, timezone
from typing import Optional

from ..base import BaseEvaluator, EvaluatorType, EvaluationResult


# Vulnerability type mappings for fuzzy matching
VULNERABILITY_ALIASES = {
    "reentrancy": [
        "reentrancy", "reentrant", "re-entrancy", "re-entrant",
        "cross-function", "cross-contract", "read-only reentrancy"
    ],
    "access_control": [
        "access control", "access-control", "authorization",
        "permission", "privilege", "onlyowner", "only_owner",
        "missing modifier", "unprotected"
    ],
    "integer_overflow": [
        "overflow", "underflow", "integer overflow", "integer underflow",
        "arithmetic", "unchecked math"
    ],
    "front_running": [
        "front-running", "frontrunning", "front running",
        "mev", "sandwich", "transaction ordering"
    ],
    "weak_randomness": [
        "randomness", "random", "block.timestamp", "blockhash",
        "predictable", "entropy"
    ],
    "unchecked_call": [
        "unchecked", "return value", "low-level call",
        "external call", "call return"
    ],
    "dos": [
        "denial of service", "dos", "gas limit", "unbounded",
        "loop", "out of gas"
    ],
    "flash_loan": [
        "flash loan", "flashloan", "flash-loan",
        "price manipulation", "oracle manipulation"
    ]
}


class RuleBasedEvaluator(BaseEvaluator):
    """
    Rule-based evaluator using keyword matching.

    This provides a fast, deterministic baseline evaluation.
    """

    def __init__(self):
        super().__init__(EvaluatorType.RULE_BASED)

    def evaluate(
        self,
        detection_output: dict,
        ground_truth: dict,
        **kwargs
    ) -> EvaluationResult:
        """
        Evaluate detection output using rule-based matching.

        Args:
            detection_output: Detection result to evaluate
            ground_truth: Ground truth information

        Returns:
            EvaluationResult
        """
        parsed = detection_output.get("parsed_output", {})
        findings = parsed.get("vulnerabilities", [])
        verdict = parsed.get("verdict", "safe")

        gt_type = ground_truth.get("vulnerability_type", "").lower()
        gt_location = ground_truth.get("location", "").lower()

        # Find matching vulnerability
        target_found = False
        target_finding_idx = None

        for i, finding in enumerate(findings):
            finding_type = finding.get("type", "").lower()
            finding_location = finding.get("location", "").lower()

            if self._types_match(finding_type, gt_type):
                # Type matches, check location if available
                if gt_location and self._location_matches(finding_location, gt_location):
                    target_found = True
                    target_finding_idx = i
                    break
                elif not gt_location:
                    # No location to check, type match is enough
                    target_found = True
                    target_finding_idx = i
                    break

        # Determine verdict correctness
        # Ground truth is always vulnerable in our dataset
        verdict_correct = (verdict == "vulnerable")

        # Classify findings (simplified: can't detect hallucinations rule-based)
        true_positives = 1 if target_found else 0
        false_positives = len(findings) - true_positives

        # Rule-based can't score quality
        return EvaluationResult(
            sample_id=detection_output.get("sample_id", "unknown"),
            evaluator_type="rule_based",
            detection_source=self._get_detection_source(detection_output),
            detection_model=detection_output.get("model", "unknown"),
            detection_verdict_correct=verdict_correct,
            target_vulnerability_found=target_found,
            target_finding_id=f"finding_{target_finding_idx}" if target_found else None,
            target_explanation_quality=None,  # Rule-based can't score this
            target_fix_quality=None,
            target_attack_scenario_quality=None,
            total_findings=len(findings),
            true_positives=true_positives,
            false_positives=false_positives,
            hallucinations=0,  # Can't detect with rules alone
            evaluator_model=None,
            confidence=0.8 if target_found else 0.5,
            reasoning=self._generate_reasoning(target_found, findings, gt_type),
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    def evaluate_batch(
        self,
        detection_outputs: list[dict],
        ground_truths: list[dict],
        **kwargs
    ) -> list[EvaluationResult]:
        """Evaluate multiple detection outputs."""
        return [
            self.evaluate(d, g, **kwargs)
            for d, g in zip(detection_outputs, ground_truths)
        ]

    def _types_match(self, detected: str, ground_truth: str) -> bool:
        """Check if detected vulnerability type matches ground truth."""
        detected = detected.lower()
        ground_truth = ground_truth.lower()

        # Direct match
        if ground_truth in detected or detected in ground_truth:
            return True

        # Check aliases
        for canonical, aliases in VULNERABILITY_ALIASES.items():
            gt_matches = any(alias in ground_truth for alias in aliases)
            det_matches = any(alias in detected for alias in aliases)
            if gt_matches and det_matches:
                return True

        return False

    def _location_matches(self, detected: str, ground_truth: str) -> bool:
        """Check if detected location matches ground truth."""
        # Extract function names
        det_func = self._extract_function_name(detected)
        gt_func = self._extract_function_name(ground_truth)

        if det_func and gt_func:
            return det_func.lower() == gt_func.lower()

        # Fuzzy match on location strings
        return ground_truth in detected or detected in ground_truth

    def _extract_function_name(self, location: str) -> Optional[str]:
        """Extract function name from location string."""
        # Match patterns like "function withdraw", "withdraw()", etc.
        patterns = [
            r'function\s+(\w+)',
            r'(\w+)\s*\(',
            r'(\w+)\s+function'
        ]

        for pattern in patterns:
            match = re.search(pattern, location, re.IGNORECASE)
            if match:
                return match.group(1)

        return None

    def _get_detection_source(self, detection_output: dict) -> str:
        """Determine if detection was from LLM or traditional tool."""
        if "prompt_type" in detection_output or "api_metrics" in detection_output:
            return "llm"
        if "tool_name" in detection_output or "analysis_type" in detection_output:
            return "traditional"
        return "unknown"

    def _generate_reasoning(
        self,
        target_found: bool,
        findings: list,
        gt_type: str
    ) -> str:
        """Generate reasoning string for the evaluation."""
        if target_found:
            return f"Target vulnerability ({gt_type}) was detected via keyword matching."
        elif findings:
            types = [f.get("type", "unknown") for f in findings]
            return f"Target vulnerability ({gt_type}) not found. Detected: {', '.join(types)}"
        else:
            return f"No vulnerabilities reported. Target was: {gt_type}"
