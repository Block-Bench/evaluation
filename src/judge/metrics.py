"""
Per-sample metric computation.
"""

from .schemas import (
    JudgeOutput,
    SampleMetrics,
    GroundTruthForJudge,
    FindingClassification,
    TypeMatchLevel,
)


def compute_sample_metrics(
    judge_output: JudgeOutput,
    ground_truth: GroundTruthForJudge
) -> SampleMetrics:
    """Compute metrics for a single evaluated sample"""

    # Extract verdict
    said_vulnerable = judge_output.overall_verdict.get("said_vulnerable")

    # Detection correct?
    if said_vulnerable is None:
        detection_correct = False  # Unclear counts as wrong
    else:
        detection_correct = (said_vulnerable == ground_truth.is_vulnerable)

    # Target found?
    target_found = judge_output.target_assessment.found

    # Lucky guess? (Right verdict on vulnerable code but didn't find the target)
    lucky_guess = (
        ground_truth.is_vulnerable and
        said_vulnerable == True and
        not target_found
    )

    # Finding-level metrics
    findings = judge_output.findings
    total_findings = len(findings)

    # Valid findings: truly identified vulnerabilities
    valid_findings = sum(
        1 for f in findings
        if f.classification in [
            FindingClassification.TARGET_MATCH,
            FindingClassification.BONUS_VALID,
            FindingClassification.PARTIAL_MATCH
        ]
    )

    # Hallucinated: completely fabricated issues that don't exist in the code
    hallucinated_findings = sum(
        1 for f in findings
        if f.classification == FindingClassification.HALLUCINATED
    )

    # All invalid findings (everything that's not valid)
    # This includes: HALLUCINATED, MISCHARACTERIZED, DESIGN_CHOICE,
    # OUT_OF_SCOPE, SECURITY_THEATER, INFORMATIONAL
    invalid_findings = total_findings - valid_findings

    finding_precision = valid_findings / total_findings if total_findings > 0 else 1.0

    # Reasoning scores (only if target found)
    rcir_score = None
    ava_score = None
    fsv_score = None

    if target_found and judge_output.target_assessment.root_cause_identification:
        rcir_score = judge_output.target_assessment.root_cause_identification.score
    if target_found and judge_output.target_assessment.attack_vector_validity:
        ava_score = judge_output.target_assessment.attack_vector_validity.score
    if target_found and judge_output.target_assessment.fix_suggestion_validity:
        fsv_score = judge_output.target_assessment.fix_suggestion_validity.score

    # Type match
    type_match = judge_output.target_assessment.type_match

    # Calibration
    confidence = judge_output.overall_verdict.get("confidence_expressed")
    calibration_error = None
    if confidence is not None:
        correct_as_float = 1.0 if detection_correct else 0.0
        calibration_error = abs(confidence - correct_as_float)

    return SampleMetrics(
        sample_id=judge_output.sample_id,
        transformed_id=judge_output.transformed_id,
        prompt_type=judge_output.prompt_type,
        detection_correct=detection_correct,
        ground_truth_vulnerable=ground_truth.is_vulnerable,
        response_said_vulnerable=said_vulnerable,
        target_found=target_found,
        lucky_guess=lucky_guess,
        total_findings=total_findings,
        valid_findings=valid_findings,
        invalid_findings=invalid_findings,
        hallucinated_findings=hallucinated_findings,
        finding_precision=finding_precision,
        rcir_score=rcir_score,
        ava_score=ava_score,
        fsv_score=fsv_score,
        type_match=type_match,
        confidence=confidence,
        calibration_error=calibration_error
    )
