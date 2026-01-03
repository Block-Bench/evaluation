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


def get_traditional_tool_system_prompt() -> str:
    """Get the system prompt for evaluating traditional tool outputs (Slither, Mythril)."""
    return """You are an expert smart contract security evaluator. Your task is to evaluate the accuracy of vulnerability detection outputs from traditional static analysis tools (Slither, Mythril).

Traditional tools output structured findings with:
- Check/detector names (e.g., "reentrancy-eth", "unchecked-send", "SWC-107")
- Severity levels
- Code locations
- Brief descriptions

Your job is to:
1. Determine if any finding detects the TARGET vulnerability pattern at the vulnerable location
2. Classify each finding using the classification scheme below
3. Assess whether the tool's overall verdict (vulnerable/not vulnerable) is correct

## IMPORTANT: Pattern Detection vs Vulnerability Naming

Traditional tools detect low-level CODE PATTERNS rather than high-level vulnerability classifications. When evaluating, focus on:
- **Location**: Did the tool flag the vulnerable function/lines?
- **Pattern**: Does the finding relate to the underlying vulnerability pattern?

Do NOT require the tool to use exact vulnerability terminology. Examples of valid detection:
- "State access after external call" in a reentrancy-vulnerable function → DETECTS reentrancy
- "Delegatecall to user-supplied address" in access-control-vulnerable code → DETECTS the issue
- "External call to user-supplied address" in withdraw() → DETECTS reentrancy risk

The question is: "Would a developer reviewing this finding investigate and discover the vulnerability?" - NOT "Did the tool use the correct vulnerability name?"

## Finding Classifications

For each finding, assign ONE of these classifications:

**True Positive Categories:**
- TARGET_MATCH: Finding flags the vulnerable location with a pattern semantically related to the target vulnerability - even if using different terminology
- PARTIAL_MATCH: Finding relates to the target but at wrong location, or only detects part of the pattern
- BONUS_VALID: Finding identifies a real vulnerability NOT in the ground truth (additional valid issue)

**False Positive Categories:**
- INVALID: Finding is technically incorrect or the issue doesn't exist in the code
- MISCHARACTERIZED: Real code pattern but wrong vulnerability type/severity assigned
- DESIGN_CHOICE: Intentional pattern flagged as an issue (e.g., intentional centralization)
- OUT_OF_SCOPE: Issue outside security scope (e.g., gas optimization, code style)
- SECURITY_THEATER: Technically true but practically unexploitable or irrelevant
- INFORMATIONAL: Informational note, not a vulnerability claim

## Type Match Assessment

Assess how well the tool's check/detector matches the ground truth vulnerability type:
- exact: Tool's check name directly matches (e.g., "reentrancy-eth" for reentrancy)
- semantic: Different name but detects the same underlying pattern (e.g., "state access after external call" for reentrancy)
- partial: Related but incomplete match (e.g., only detecting part of the issue)
- wrong: Completely different vulnerability type
- not_mentioned: Target vulnerability type not detected at all

Be rigorous but practical. The goal is to measure whether the tool effectively points developers to vulnerabilities, not whether it uses perfect classification labels."""


def get_traditional_tool_user_prompt(
    detection_output: dict,
    ground_truth: dict,
    code_snippet: str = ""
) -> str:
    """
    Build the user prompt for evaluating traditional tool output.

    Args:
        detection_output: The tool's detection output
        ground_truth: Ground truth vulnerability information
        code_snippet: The contract source code

    Returns:
        Formatted user prompt
    """
    tool_name = detection_output.get("tool", "unknown")
    sample_id = detection_output.get("sample_id", "unknown")

    # Extract findings based on tool type
    # Support both processed format (findings[]) and raw format (raw_output.results.detectors[])
    if "findings" in detection_output:
        # Processed format (p_*.json)
        findings = detection_output.get("findings", [])
        if tool_name == "slither":
            findings_text = _format_slither_findings(findings)
        elif tool_name == "mythril":
            findings_text = _format_mythril_findings(findings)
        else:
            findings_text = "Unknown tool format"
        total_findings = len(findings)
    else:
        # Raw format (d_*.json)
        raw_output = detection_output.get("raw_output", {})
        if tool_name == "slither":
            detectors = raw_output.get("results", {}).get("detectors", [])
            findings_text = _format_slither_findings(detectors)
            total_findings = len(detectors)
        elif tool_name == "mythril":
            issues = raw_output.get("issues", [])
            findings_text = _format_mythril_findings(issues)
            total_findings = len(issues)
        else:
            findings_text = "Unknown tool format"
            total_findings = 0

    # Check for tool failure
    if not detection_output.get("success", False):
        error = detection_output.get("error", "Unknown error")
        findings_text = f"TOOL FAILED: {error}"
        total_findings = 0

    # Format ground truth
    gt_vuln_type = ground_truth.get("vulnerability_type", "unknown")
    gt_description = ground_truth.get("description", "No description")
    gt_severity = ground_truth.get("severity", "unknown")
    gt_functions = ground_truth.get("vulnerable_functions", [])

    prompt = f"""## Traditional Tool Output to Evaluate

**Tool:** {tool_name}
**Sample:** {sample_id}
**Number of Findings:** {total_findings}

### Reported Findings:
{findings_text}

## Ground Truth

**Target Vulnerability:**
- Type: {gt_vuln_type}
- Severity: {gt_severity}
- Vulnerable Functions: {', '.join(gt_functions) if gt_functions else 'Not specified'}
- Description: {gt_description}

## Contract Code

```solidity
{code_snippet}
```

## Your Evaluation Task

Analyze the tool output and determine if it correctly identified the target vulnerability.

Provide your evaluation in the following JSON format:

```json
{{
  "overall_verdict": {{
    "tool_found_issues": true | false,
    "target_detected": true | false,
    "verdict_correct": true | false
  }},
  "findings": [
    {{
      "finding_id": <0-based index>,
      "tool_check": "<detector/check name from tool>",
      "tool_severity": "<severity from tool>",
      "location": "<function/line from tool>",
      "matches_target": true | false,
      "is_valid_concern": true | false,
      "classification": "TARGET_MATCH" | "PARTIAL_MATCH" | "BONUS_VALID" | "INVALID" | "MISCHARACTERIZED" | "DESIGN_CHOICE" | "OUT_OF_SCOPE" | "SECURITY_THEATER" | "INFORMATIONAL",
      "reasoning": "<brief explanation for classification>"
    }}
  ],
  "target_assessment": {{
    "found": true | false,
    "finding_id": <index of TARGET_MATCH finding, or null>,
    "type_match": "exact" | "semantic" | "partial" | "wrong" | "not_mentioned",
    "type_match_reasoning": "<explanation of type match assessment>",
    "location_accuracy": "exact" | "close" | "wrong" | null
  }},
  "summary": {{
    "total_findings": <number>,
    "target_matches": <count of TARGET_MATCH>,
    "partial_matches": <count of PARTIAL_MATCH>,
    "bonus_valid": <count of BONUS_VALID>,
    "invalid": <count of INVALID>,
    "mischaracterized": <count of MISCHARACTERIZED>,
    "design_choice": <count of DESIGN_CHOICE>,
    "out_of_scope": <count of OUT_OF_SCOPE>,
    "security_theater": <count of SECURITY_THEATER>,
    "informational": <count of INFORMATIONAL>
  }},
  "notes": "<any additional observations>",
  "confidence": <0.0-1.0>
}}
```

Important:
- target_detected should be true if ANY finding detects the vulnerability pattern at the vulnerable location (TARGET_MATCH classification)
- Remember: A finding like "state access after external call" at the vulnerable function IS detecting reentrancy - classify as TARGET_MATCH
- Every finding from the tool must be classified
- matches_target = true only for TARGET_MATCH and PARTIAL_MATCH
- is_valid_concern = true for TARGET_MATCH, PARTIAL_MATCH, and BONUS_VALID
- Focus on LOCATION + PATTERN, not on whether the tool used the exact vulnerability name
- location_accuracy: null if target not found, "exact" if same function/line, "close" if nearby, "wrong" if different location"""

    return prompt


def _format_slither_findings(detectors: list) -> str:
    """Format Slither detector findings for the prompt."""
    if not detectors:
        return "No findings reported."

    text = ""
    for i, d in enumerate(detectors):
        check = d.get("check", "unknown")
        impact = d.get("impact", "unknown")
        confidence = d.get("confidence", "unknown")
        description = d.get("description", "No description")[:300]

        # Get location from elements
        elements = d.get("elements", [])
        location_parts = []
        lines = []
        for elem in elements[:3]:  # First 3 elements
            name = elem.get("name", elem.get("type", ""))
            if name:
                location_parts.append(name)
            # Extract lines from source mapping
            src_map = elem.get("source_mapping", {})
            elem_lines = src_map.get("lines", [])
            lines.extend(elem_lines)

        location = ", ".join(location_parts) if location_parts else "unknown"
        line_info = f"lines {min(lines)}-{max(lines)}" if lines else "unknown lines"

        text += f"""
Finding {i}:
- Check: {check}
- Impact: {impact}
- Confidence: {confidence}
- Location: {location} ({line_info})
- Description: {description}
"""
    return text


def _format_mythril_findings(issues: list) -> str:
    """Format Mythril issue findings for the prompt."""
    if not issues:
        return "No findings reported."

    text = ""
    for i, issue in enumerate(issues):
        title = issue.get("title", "unknown")
        severity = issue.get("severity", "unknown")
        swc_id = issue.get("swc-id", "unknown")
        description = issue.get("description", "No description")[:300]
        function = issue.get("function", "unknown")
        lineno = issue.get("lineno", "unknown")
        contract = issue.get("contract", "unknown")
        code = issue.get("code", "")[:100]

        text += f"""
Finding {i}:
- Title: {title}
- SWC-ID: {swc_id}
- Severity: {severity}
- Contract: {contract}
- Function: {function}
- Line: {lineno}
- Code: {code}
- Description: {description}
"""
    return text
