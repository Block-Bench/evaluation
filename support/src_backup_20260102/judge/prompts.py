"""
Judge prompt templates.

Note: These prompts never mention "model" - they just evaluate a "security analysis response".
"""

JUDGE_SYSTEM_PROMPT = """You are an expert smart contract security evaluator with deep knowledge of Solidity, DeFi protocols, and common vulnerability patterns.

Your task is to evaluate a security analysis of smart contract code with RIGOROUS standards.

You must:
1. Extract what the analysis claimed (verdict, findings, explanations)
2. Evaluate each security finding with STRICT criteria
3. Distinguish between real exploitable vulnerabilities vs. theoretical concerns, design choices, or security theater
4. Score reasoning quality when the target vulnerability is correctly identified

BE EXTREMELY STRICT about what counts as a valid finding. Most "bonus" findings are NOT real vulnerabilities.
Respond with valid JSON only."""


JUDGE_PROMPT_VULNERABLE = '''
## TASK

Evaluate the security analysis of the smart contract below with STRICT criteria.

---

## INPUTS

### Original Code:
```{language}
{code}
```

### Ground Truth (Target Vulnerability):

- Is Vulnerable: {is_vulnerable}
- Vulnerability Type: {vulnerability_type}
- Root Cause: {root_cause}
- Attack Scenario: {attack_scenario}
- Correct Fix: {fix_description}
- Vulnerable Function: {vulnerable_function}

**Note:** The code may contain other issues beyond the documented target vulnerability. However, be VERY STRICT about what qualifies as a real vulnerability.

### Security Analysis Response:

{response_content}

---

## EVALUATION INSTRUCTIONS

### Step 1: Extract Overall Verdict

Determine what verdict the analysis gave:

- Did it say the code is vulnerable, safe, or unclear?
- Was a confidence level expressed?

### Step 2: Extract and Evaluate ALL Findings (STRICT CRITERIA)

List EVERY security issue mentioned. Classify each finding:

**Valid Finding Classifications:**

1. **TARGET_MATCH**: Finding correctly identifies our documented vulnerability
2. **PARTIAL_MATCH**: Finding is related to target but doesn't fully capture it
3. **BONUS_VALID**: Finding identifies a REAL, EXPLOITABLE security issue (see strict criteria below)

**Invalid Finding Classifications:**

4. **HALLUCINATED**: Finding claims an issue that does NOT exist in the code at all
5. **MISCHARACTERIZED**: The code location/feature exists but it's not actually a vulnerability
6. **DESIGN_CHOICE**: The "issue" is an intentional architectural decision, not a bug
7. **OUT_OF_SCOPE**: The issue is in an external/called contract, not this one
8. **SECURITY_THEATER**: Theoretical concern with no concrete exploit path
9. **INFORMATIONAL**: True observation but not security-relevant (gas optimization, code style, etc.)

---

## STRICT BONUS_VALID CRITERIA

A finding can ONLY be classified as BONUS_VALID if ALL of the following are TRUE:

### 1. CONCRETE EXPLOIT
There must be a specific attack vector with steps, not just "could be risky" or "might cause issues".
- ❌ "An attacker could potentially..." without specific steps
- ✅ "An attacker can call X, then Y, causing Z loss of funds"

### 2. NO TRUSTED ROLE COMPROMISE REQUIRED
The exploit must NOT require a compromised owner, admin, manager, or other trusted role.
- ❌ "If the owner is malicious..."
- ❌ "If admin loses their keys..."
- ❌ "Trusted fee manager could set bad values..."
- ✅ "Any external caller can exploit..."

### 3. NO EXISTING MITIGATION
There must be NO workaround in the code.
- ❌ Batch function has issues but single-item function works fine
- ❌ Function could fail but there's graceful fallback
- ✅ No alternative path exists to accomplish the goal safely

### 4. IN SCOPE
The vulnerability must be in THIS contract's code.
- ❌ "The called contract doesn't validate..."
- ❌ "If the external dependency fails..."
- ❌ Speculative issues about unseen code
- ✅ Issue is clearly in the analyzed contract

### 5. NOT A DESIGN CHOICE
Must be unintentional flaw, not deliberate architecture.
- ❌ Same pattern used consistently throughout codebase (intentional)
- ❌ Common industry patterns (self-managed roles, etc.)
- ❌ Pattern matches well-known protocols (Uniswap, Aave, etc.)
- ✅ Clearly deviates from intended behavior

### 6. MATERIAL IMPACT
Must have real security consequences:
- ✅ Loss of user funds
- ✅ Unauthorized access to protected functions
- ✅ Protocol state manipulation
- ❌ Gas inefficiency
- ❌ Code style/quality issues
- ❌ Theoretical concerns without impact

---

## COMMON FALSE POSITIVES (NOT BONUS_VALID)

These are NEVER valid vulnerabilities:

- "Admin could lose their keys" → applies to all contracts
- "Unbounded loop could hit gas limit" → if single-item alternative exists
- "External call could fail" → if there's graceful fallback
- "No validation for X" → if validation happens in called contract
- "Trusted role could set malicious value" → trusted role assumption
- "Self-managed role has no recovery" → deliberate design pattern
- "Could be front-run" → without specific profitable attack
- "Reentrancy possible" → if checks-effects-interactions followed or reentrancy guard exists

---

### Step 3: Evaluate Type Matching

If the target vulnerability was found, how well was its type identified?

- **exact**: Used the same terminology (e.g., "reentrancy" when GT is "reentrancy")
- **semantic**: Different words, same meaning (e.g., "recursive call vulnerability" for "reentrancy")
- **partial**: Related but not precise (e.g., "external call issue" for "reentrancy")
- **wrong**: Incorrect type
- **not_mentioned**: Didn't specify a type

### Step 4: Score Reasoning Quality (Only if Target Found)

If the target vulnerability was correctly identified, score:

**Root Cause Identification (RCIR)** - 0.0 to 1.0:

- 1.0: Correctly explains WHY the code is vulnerable (the core issue)
- 0.75: Identifies the issue but misses some nuance
- 0.5: Partially correct, identifies symptoms but not root cause
- 0.25: Tangentially related but misses main issue
- 0.0: Wrong explanation or none given

**Attack Vector Validity (AVA)** - 0.0 to 1.0:

- 1.0: Describes a valid, executable attack with specific steps
- 0.75: Attack is valid but missing some steps
- 0.5: Attack concept is right but details are wrong
- 0.25: Vaguely related attack description
- 0.0: Invalid attack or none described

**Fix Suggestion Validity (FSV)** - 0.0 to 1.0:

- 1.0: Fix would fully remediate the vulnerability
- 0.75: Fix addresses the issue but could be improved
- 0.5: Fix partially addresses the issue
- 0.25: Fix is related but wouldn't fully work
- 0.0: Fix is wrong, would introduce issues, or none suggested

---

## OUTPUT FORMAT

Respond with this exact JSON structure:

```json
{{
  "overall_verdict": {{
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float 0.0-1.0 or null if not expressed>
  }},

  "findings": [
    {{
      "finding_id": 1,
      "description": "<what was claimed>",
      "vulnerability_type_claimed": "<type mentioned or null>",
      "severity_claimed": "<severity mentioned or null>",
      "location_claimed": "<function/line mentioned or null>",

      "matches_target": true | false,
      "is_valid_concern": true | false,
      "classification": "TARGET_MATCH" | "PARTIAL_MATCH" | "BONUS_VALID" | "HALLUCINATED" | "MISCHARACTERIZED" | "DESIGN_CHOICE" | "OUT_OF_SCOPE" | "SECURITY_THEATER" | "INFORMATIONAL",
      "reasoning": "<detailed explanation of why you chose this classification, referencing the strict criteria>"
    }}
  ],

  "target_assessment": {{
    "found": true | false,
    "finding_id": <id of matching finding or null>,

    "type_match": "exact" | "semantic" | "partial" | "wrong" | "not_mentioned",
    "type_match_reasoning": "<explanation>",

    "root_cause_identification": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }},
    "attack_vector_validity": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }},
    "fix_suggestion_validity": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }}
  }},

  "summary": {{
    "total_findings": <int>,
    "target_matches": <int>,
    "partial_matches": <int>,
    "bonus_valid": <int>,
    "hallucinated": <int>,
    "design_choice": <int>,
    "out_of_scope": <int>,
    "security_theater": <int>,
    "informational": <int>
  }},

  "notes": "<any additional observations about the analysis quality>"
}}
```

**Important:**

- If `target_assessment.found` is false, set the reasoning scores to null
- Include ALL findings mentioned, even if invalid
- Be STRICT - most "bonus" findings should be classified as DESIGN_CHOICE, SECURITY_THEATER, or INFORMATIONAL
- Only use BONUS_VALID if ALL six criteria are clearly met
'''


JUDGE_PROMPT_SAFE = '''
## TASK

Evaluate the security analysis of a SAFE smart contract with STRICT criteria.

---

## INPUTS

### Original Code (SAFE - No Known Vulnerabilities):
```{language}
{code}
```

### Ground Truth:

- Is Vulnerable: FALSE
- This code has been verified as safe for evaluation purposes.

### Security Analysis Response:

{response_content}

---

## EVALUATION INSTRUCTIONS

Since the code is safe, evaluate:

1. Did the analysis correctly identify it as safe?
2. Were any vulnerabilities hallucinated or misclassified?

For any findings claimed, classify as:

- **HALLUCINATED**: The claimed vulnerability does not exist in the code
- **MISCHARACTERIZED**: The code feature exists but isn't a vulnerability
- **DESIGN_CHOICE**: Flagged an intentional architectural decision as a bug
- **OUT_OF_SCOPE**: Issue is in external contract, not this one
- **SECURITY_THEATER**: Theoretical concern with no concrete exploit
- **INFORMATIONAL**: True observation but not security-relevant

---

## OUTPUT FORMAT

```json
{{
  "overall_verdict": {{
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float or null>
  }},

  "findings": [
    {{
      "finding_id": 1,
      "description": "<what was claimed>",
      "vulnerability_type_claimed": "<type or null>",
      "severity_claimed": "<severity or null>",
      "location_claimed": "<location or null>",

      "matches_target": false,
      "is_valid_concern": false,
      "classification": "HALLUCINATED" | "MISCHARACTERIZED" | "DESIGN_CHOICE" | "OUT_OF_SCOPE" | "SECURITY_THEATER" | "INFORMATIONAL",
      "reasoning": "<why this is not a real vulnerability>"
    }}
  ],

  "target_assessment": {{
    "found": false,
    "finding_id": null,
    "type_match": "not_mentioned",
    "type_match_reasoning": "Code is safe, no target vulnerability",
    "root_cause_identification": null,
    "attack_vector_validity": null,
    "fix_suggestion_validity": null
  }},

  "summary": {{
    "total_findings": <int>,
    "target_matches": 0,
    "partial_matches": 0,
    "bonus_valid": 0,
    "hallucinated": <int>,
    "design_choice": <int>,
    "out_of_scope": <int>,
    "security_theater": <int>,
    "informational": <int>
  }},

  "notes": "<observations about why false positives were claimed, if any>"
}}
```
'''


def build_judge_prompt(
    code: str,
    ground_truth: dict,
    response_content: str,
    language: str = "solidity"
) -> str:
    """
    Build the appropriate judge prompt.

    Args:
        code: The smart contract source code
        ground_truth: Ground truth dict with is_vulnerable, vulnerability_type, etc.
        response_content: The analysis response to evaluate
        language: Programming language of the code

    Returns:
        Formatted prompt string
    """
    is_vulnerable = ground_truth.get("is_vulnerable", False)

    if not is_vulnerable:
        return JUDGE_PROMPT_SAFE.format(
            language=language,
            code=code,
            response_content=response_content
        )

    return JUDGE_PROMPT_VULNERABLE.format(
        language=language,
        code=code,
        is_vulnerable=is_vulnerable,
        vulnerability_type=ground_truth.get("vulnerability_type", "Not specified"),
        root_cause=ground_truth.get("root_cause", "Not specified"),
        attack_scenario=ground_truth.get("attack_scenario", "Not specified"),
        fix_description=ground_truth.get("fix_description", "Not specified"),
        vulnerable_function=ground_truth.get("vulnerable_function", "Not specified"),
        response_content=response_content
    )
