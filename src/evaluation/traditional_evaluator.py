"""
Rule-based evaluator for traditional tools (Slither, Mythril).

Maps tool-specific findings to ground truth vulnerability types
and produces EvaluationResult compatible output.
"""

import json
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional

from .base import BaseEvaluator, EvaluatorType, EvaluationResult


# Mapping from Slither check names to ground truth vulnerability types
SLITHER_MAPPING = {
    # Reentrancy
    "reentrancy-eth": "reentrancy",
    "reentrancy-no-eth": "reentrancy",
    "reentrancy-unlimited-gas": "reentrancy",

    # Access Control
    "controlled-delegatecall": "access_control",
    "arbitrary-send-eth": "access_control",
    "unprotected-upgrade": "access_control",
    "suicidal": "access_control",

    # Unchecked Return
    "unchecked-send": "unchecked_return",
    "unchecked-lowlevel": "unchecked_return",
    "unchecked-transfer": "unchecked_return",

    # Integer Issues
    "divide-before-multiply": "integer_issues",
    "controlled-array-length": "integer_issues",

    # Weak Randomness
    "weak-prng": "weak_randomness",
    "timestamp": "weak_randomness",

    # Interface
    "incorrect-modifier": "interface_mismatch",
    "incorrect-equality": "interface_mismatch",
}

# Mapping from Mythril issue titles to ground truth vulnerability types
MYTHRIL_MAPPING = {
    # Reentrancy
    "State access after external call": "reentrancy",
    "State change after external call": "reentrancy",

    # Access Control
    "Delegatecall to user-supplied address": "access_control",
    "External Call To User-Supplied Address": "access_control",
    "Unprotected Ether Withdrawal": "access_control",

    # Unchecked Return
    "Unchecked return value from external call.": "unchecked_return",

    # Integer Issues
    "Integer Arithmetic Bugs": "integer_issues",
    "Integer Overflow": "integer_issues",
    "Integer Underflow": "integer_issues",

    # Weak Randomness
    "Dependence on predictable environment variable": "weak_randomness",
    "Transaction Order Dependence": "weak_randomness",
}


class TraditionalToolEvaluator(BaseEvaluator):
    """
    Evaluator for traditional security analysis tools (Slither, Mythril).

    Uses rule-based mapping to match tool findings to ground truth.
    """

    def __init__(self, tool_name: str):
        super().__init__(EvaluatorType.RULE_BASED)
        self.tool_name = tool_name
        self.mapping = SLITHER_MAPPING if tool_name == "slither" else MYTHRIL_MAPPING

    def evaluate(
        self,
        detection_output: dict,
        ground_truth: dict,
        **kwargs
    ) -> EvaluationResult:
        """
        Evaluate a traditional tool output against ground truth.

        Args:
            detection_output: Tool output (Slither or Mythril JSON)
            ground_truth: Ground truth for the sample

        Returns:
            EvaluationResult
        """
        sample_id = detection_output.get("sample_id", "unknown")
        gt_vuln_type = ground_truth.get("vulnerability_type", "unknown")
        is_vulnerable = ground_truth.get("is_vulnerable", True)

        # Check for timeout/failure
        success = detection_output.get("success", False)
        error_msg = detection_output.get("error") or ""
        timeout = "Timeout" in error_msg

        if timeout or not success:
            # Tool failed - return empty evaluation
            return EvaluationResult(
                sample_id=sample_id,
                evaluator_type="rule_based",
                detection_source="traditional",
                detection_model=self.tool_name,
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
                evaluator_model=None,
                confidence=0.0,
                reasoning=f"Tool failed: {error_msg}" if error_msg else "Tool failed",
                timestamp=datetime.now(timezone.utc).isoformat()
            )

        # Extract findings
        findings = self._extract_findings(detection_output)

        # Map findings to vulnerability types
        mapped_findings = []
        for finding in findings:
            mapped_type = self.mapping.get(finding)
            if mapped_type:
                mapped_findings.append(mapped_type)

        # Calculate metrics
        # Primary metric: did we find the target vulnerability?
        target_found = gt_vuln_type in mapped_findings

        # For rule-based evaluation, we only track target_found
        # TP/FP require LLM judge to properly verify each finding
        true_positives = 1 if target_found else 0
        false_positives = 0  # Requires LLM judge to determine

        # Verdict: detected as vulnerable if any mapped findings exist
        detected_vulnerable = len(mapped_findings) > 0
        verdict_correct = (detected_vulnerable == is_vulnerable)

        # Find the first matching finding ID
        target_finding_id = None
        if target_found:
            for i, finding in enumerate(findings):
                if self.mapping.get(finding) == gt_vuln_type:
                    target_finding_id = f"finding_{i}"
                    break

        return EvaluationResult(
            sample_id=sample_id,
            evaluator_type="rule_based",
            detection_source="traditional",
            detection_model=self.tool_name,
            detection_verdict_correct=verdict_correct,
            target_vulnerability_found=target_found,
            target_finding_id=target_finding_id,
            target_explanation_quality=None,  # Tools don't provide this
            target_fix_quality=None,
            target_attack_scenario_quality=None,
            total_findings=len(findings),
            true_positives=true_positives,
            false_positives=false_positives,
            hallucinations=0,  # Tools can't hallucinate
            evaluator_model=None,
            confidence=0.9 if target_found else 0.5,
            reasoning=self._generate_reasoning(target_found, findings, mapped_findings, gt_vuln_type),
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

    def _extract_findings(self, tool_result: dict) -> list[str]:
        """Extract finding types from tool result.

        Handles both raw format (d_*.json) and processed format (p_*.json).
        """
        if self.tool_name == "slither":
            # Check for processed format first (p_*.json)
            if "findings" in tool_result:
                return [f.get("check", "unknown") for f in tool_result["findings"]]
            # Fall back to raw format (d_*.json)
            detectors = tool_result.get("raw_output", {}).get("results", {}).get("detectors", [])
            return [d.get("check", "unknown") for d in detectors]
        elif self.tool_name == "mythril":
            # Check for processed format first
            if "findings" in tool_result:
                return [f.get("title", "unknown") for f in tool_result["findings"]]
            # Fall back to raw format
            issues = tool_result.get("raw_output", {}).get("issues", [])
            return [i.get("title", "unknown") for i in issues]
        else:
            return []

    def _generate_reasoning(
        self,
        target_found: bool,
        raw_findings: list,
        mapped_findings: list,
        gt_type: str
    ) -> str:
        """Generate reasoning string for the evaluation."""
        if target_found:
            return f"Target vulnerability ({gt_type}) detected. Mapped {len(mapped_findings)} findings to known types."
        elif mapped_findings:
            return f"Target ({gt_type}) not found. Found: {', '.join(set(mapped_findings))}"
        elif raw_findings:
            return f"Target ({gt_type}) not found. {len(raw_findings)} findings did not map to known vulnerability types."
        else:
            return f"No vulnerabilities reported. Target was: {gt_type}"


def evaluate_and_save(
    tool: str,
    tier: str,
    results_dir: Path,
    samples_dir: Path,
    output_dir: Path,
    use_processed: bool = True
) -> dict:
    """
    Evaluate a tool on all samples in a tier and save results.

    Args:
        tool: Tool name ("slither" or "mythril")
        tier: Tier name ("tier1", "tier2", etc.)
        results_dir: Path to detection results directory
        samples_dir: Path to samples directory
        output_dir: Path to save evaluation results
        use_processed: If True, read from processed/ subfolder (p_*.json),
                      else read from raw/ subfolder (d_*.json)

    Returns:
        Summary statistics dict
    """
    base_results_dir = results_dir / tool / "ds" / tier
    if use_processed:
        tool_results_dir = base_results_dir / "processed"
        file_pattern = "p_*.json"
    else:
        tool_results_dir = base_results_dir / "raw"
        file_pattern = "d_*.json"

    ground_truth_dir = samples_dir / "ds" / tier / "ground_truth"
    eval_output_dir = output_dir / tool / "ds" / tier
    eval_output_dir.mkdir(parents=True, exist_ok=True)

    evaluator = TraditionalToolEvaluator(tool)
    results = []
    timeout_count = 0

    for result_file in sorted(tool_results_dir.glob(file_pattern)):
        # Load tool result
        with open(result_file) as f:
            tool_result = json.load(f)

        sample_id = tool_result.get("sample_id", result_file.stem[2:])

        # Load ground truth
        gt_file = ground_truth_dir / f"{sample_id}.json"
        if gt_file.exists():
            with open(gt_file) as f:
                ground_truth = json.load(f)
        else:
            ground_truth = {"is_vulnerable": True, "vulnerability_type": "unknown"}

        # Evaluate
        eval_result = evaluator.evaluate(tool_result, ground_truth)
        results.append(eval_result)

        # Track timeouts
        if "Timeout" in (tool_result.get("error") or ""):
            timeout_count += 1

        # Save individual result
        output_dict = evaluator.create_output_dict(eval_result)

        # Add traditional-tool specific metadata
        output_dict["metadata"]["tool_version"] = tool_result.get("tool_version")
        output_dict["metadata"]["solc_version"] = tool_result.get("solc_version")
        output_dict["metadata"]["execution_time_ms"] = tool_result.get("execution_time_ms")
        output_dict["metadata"]["timeout"] = "Timeout" in (tool_result.get("error") or "")
        output_dict["ground_truth"] = {
            "vulnerability_type": ground_truth.get("vulnerability_type"),
            "is_vulnerable": ground_truth.get("is_vulnerable", True)
        }

        eval_file = eval_output_dir / f"e_{sample_id}.json"
        with open(eval_file, 'w') as f:
            json.dump(output_dict, f, indent=2)

    # Generate summary
    n = len(results)
    successful = [r for r in results if r.confidence > 0]
    n_success = len(successful)

    # Group by vulnerability type
    by_vuln_type = {}
    vuln_type_map = {}  # sample_id -> vuln_type for lookup

    for result_file in sorted(tool_results_dir.glob(file_pattern)):
        with open(result_file) as f:
            tool_result = json.load(f)
        sample_id = tool_result.get("sample_id", result_file.stem[2:])
        gt_file = ground_truth_dir / f"{sample_id}.json"
        if gt_file.exists():
            with open(gt_file) as f:
                gt = json.load(f)
            vuln_type_map[sample_id] = gt.get("vulnerability_type", "unknown")

    for r in results:
        vtype = vuln_type_map.get(r.sample_id, "unknown")
        if vtype not in by_vuln_type:
            by_vuln_type[vtype] = {"total": 0, "target_found": 0, "successful": 0}
        by_vuln_type[vtype]["total"] += 1
        if r.confidence > 0:  # successful analysis
            by_vuln_type[vtype]["successful"] += 1
            if r.target_vulnerability_found:
                by_vuln_type[vtype]["target_found"] += 1

    # Calculate rates per vulnerability type
    by_vuln_type_summary = {}
    for vtype, counts in by_vuln_type.items():
        by_vuln_type_summary[vtype] = {
            "total_samples": counts["total"],
            "successful_analyses": counts["successful"],
            "target_found_count": counts["target_found"],
            "target_found_rate": counts["target_found"] / counts["successful"] if counts["successful"] > 0 else 0
        }

    summary = {
        "tool": tool,
        "tier": tier,
        "total_samples": n,
        "successful_analyses": n_success,
        "timeout_count": timeout_count,
        "timeout_rate": timeout_count / n if n > 0 else 0,
        # Primary metrics (rule-based can only determine target_found)
        "target_found_count": sum(1 for r in results if r.target_vulnerability_found),
        "target_found_rate": sum(1 for r in successful if r.target_vulnerability_found) / n_success if n_success > 0 else 0,
        "verdict_accuracy": sum(1 for r in successful if r.detection_verdict_correct) / n_success if n_success > 0 else 0,
        # Output volume
        "total_findings": sum(r.total_findings for r in results),
        "avg_findings_per_sample": sum(r.total_findings for r in results) / n if n > 0 else 0,
        # Note: TP/FP require LLM judge for proper classification
        # Breakdown by vulnerability type
        "by_vulnerability_type": by_vuln_type_summary
    }

    # Save tier summary
    summary_file = eval_output_dir / "_tier_summary.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)

    return summary


if __name__ == "__main__":
    import sys

    # Default paths
    PROJECT_ROOT = Path(__file__).parent.parent.parent
    DETECTION_RESULTS_DIR = PROJECT_ROOT / "results" / "detection" / "traditional"
    SAMPLES_DIR = PROJECT_ROOT / "samples"
    EVAL_OUTPUT_DIR = PROJECT_ROOT / "results" / "detection_evaluation" / "rule-based" / "traditional"

    tool = sys.argv[1] if len(sys.argv) > 1 else "slither"
    tier = sys.argv[2] if len(sys.argv) > 2 else "tier1"

    print(f"Evaluating {tool} on {tier}...")
    print(f"Saving results to: {EVAL_OUTPUT_DIR / tool / 'ds' / tier}")

    summary = evaluate_and_save(
        tool=tool,
        tier=tier,
        results_dir=DETECTION_RESULTS_DIR,
        samples_dir=SAMPLES_DIR,
        output_dir=EVAL_OUTPUT_DIR
    )

    print(f"\n{'='*60}")
    print(f"Summary for {tool} on {tier}")
    print(f"{'='*60}")
    for k, v in summary.items():
        if isinstance(v, float):
            print(f"  {k}: {v:.2%}" if "rate" in k or "accuracy" in k else f"  {k}: {v:.2f}")
        else:
            print(f"  {k}: {v}")
