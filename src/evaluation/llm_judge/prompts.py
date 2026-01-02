"""
Prompt templates for LLM Judge evaluation.

Design decisions (from TODO/llm_judge_prompt_design.md):
- Judge evaluates detection output against ground truth
- Scores are 1-5 scale for quality metrics
- Must identify target vulnerability match (not just type match)
- Counts true positives, false positives, and hallucinations
"""


def get_judge_system_prompt() -> str:
    """Get the system prompt for LLM judge."""
    return """You are an expert smart contract security evaluator. Your task is to evaluate the quality and accuracy of vulnerability detection outputs.

You will be given:
1. A detection output (findings from an automated tool or LLM)
2. Ground truth information about the actual vulnerability in the contract

Your job is to:
1. Determine if the detection correctly identified the target vulnerability
2. Score the quality of the detection's explanation, fix suggestion, and attack scenario
3. Classify all reported findings as true positives, false positives, or hallucinations

Definitions:
- TRUE POSITIVE: A finding that matches a real vulnerability (the target or other real issues)
- FALSE POSITIVE: A finding that describes a plausible but non-existent vulnerability
- HALLUCINATION: A finding that references code/functions that don't exist or makes factually incorrect claims

Quality Scoring (1-5 scale):
1 = Very poor / Missing / Incorrect
2 = Poor / Vague / Partially incorrect
3 = Adequate / Covers basics
4 = Good / Clear and correct
5 = Excellent / Comprehensive and insightful

Be rigorous and objective. Do not give credit for generic security advice that doesn't apply to the specific vulnerability."""


def get_judge_user_prompt(
    detection_output: dict,
    ground_truth: dict,
    code_snippet: str = ""
) -> str:
    """
    Build the user prompt for LLM judge evaluation.

    Args:
        detection_output: The detection output to evaluate
        ground_truth: Ground truth vulnerability information
        code_snippet: Optional code for context

    Returns:
        Formatted user prompt
    """
    # Extract key information
    verdict = detection_output.get("parsed_output", {}).get("verdict", "unknown")
    findings = detection_output.get("parsed_output", {}).get("vulnerabilities", [])

    # Format findings for evaluation
    findings_text = ""
    for i, finding in enumerate(findings, 1):
        findings_text += f"""
Finding {i}:
- Type: {finding.get('type', 'unspecified')}
- Severity: {finding.get('severity', 'unspecified')}
- Location: {finding.get('location', 'unspecified')}
- Explanation: {finding.get('explanation', 'none provided')}
- Attack Scenario: {finding.get('attack_scenario', 'none provided')}
- Suggested Fix: {finding.get('suggested_fix', 'none provided')}
"""

    if not findings_text:
        findings_text = "No findings reported."

    # Format ground truth
    gt_vuln_type = ground_truth.get("vulnerability_type", "unknown")
    gt_location = ground_truth.get("location", "unknown")
    gt_description = ground_truth.get("description", "No description")
    gt_severity = ground_truth.get("severity", "unknown")

    prompt = f"""## Detection Output to Evaluate

**Verdict:** {verdict}
**Number of Findings:** {len(findings)}

### Reported Findings:
{findings_text}

## Ground Truth

**Target Vulnerability:**
- Type: {gt_vuln_type}
- Location: {gt_location}
- Severity: {gt_severity}
- Description: {gt_description}

{f"## Code Context{chr(10)}{chr(10)}```solidity{chr(10)}{code_snippet}{chr(10)}```" if code_snippet else ""}

## Your Evaluation Task

Analyze the detection output and provide your evaluation in the following JSON format:

```json
{{
  "target_vulnerability_found": true | false,
  "target_finding_index": <index of finding that matches target, or null>,
  "detection_verdict_correct": true | false,
  "quality_scores": {{
    "explanation": <1-5>,
    "attack_scenario": <1-5>,
    "fix_suggestion": <1-5>
  }},
  "findings_classification": [
    {{
      "finding_index": <0-based index>,
      "classification": "true_positive" | "false_positive" | "hallucination",
      "reason": "<brief explanation>"
    }}
  ],
  "reasoning": "<your overall assessment>",
  "confidence": <0.0-1.0>
}}
```

Important:
- target_vulnerability_found should be true ONLY if a finding correctly identifies the specific target vulnerability (not just mentions the same category)
- quality_scores only apply if target_vulnerability_found is true
- Every finding must be classified
- Be strict about hallucinations - any reference to non-existent code is a hallucination"""

    return prompt


def get_quality_criteria() -> dict:
    """Return the quality scoring criteria for reference."""
    return {
        "explanation": {
            1: "Missing, incorrect, or completely generic",
            2: "Vague or partially incorrect technical details",
            3: "Correct but basic explanation of the issue",
            4: "Clear, correct, and detailed explanation",
            5: "Comprehensive with deep technical insight"
        },
        "attack_scenario": {
            1: "Missing or describes impossible attack",
            2: "Vague or impractical attack description",
            3: "Plausible but basic attack scenario",
            4: "Realistic and detailed attack steps",
            5: "Complete exploit scenario with edge cases"
        },
        "fix_suggestion": {
            1: "Missing, incorrect, or would break functionality",
            2: "Vague or incomplete fix",
            3: "Correct basic fix approach",
            4: "Complete fix with implementation details",
            5: "Optimal fix with best practices and alternatives"
        }
    }
