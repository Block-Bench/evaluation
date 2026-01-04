# TODO: LLM Judge Prompt Engineering

**Status:** Pending
**Priority:** High
**Related Schema:** `schemas/ds/llm_judge_output.schema.json`

---

## Overview

Engineer the LLM Judge prompt to evaluate vulnerability detection responses from models. The judge receives:
1. Original smart contract code
2. Ground truth (target vulnerability)
3. LLM's response (verdict + findings)

And produces a structured evaluation with classifications and quality scores.

---

## Design Decisions

### 1. Single Target Vulnerability Per Sample

- Each DS sample has exactly ONE documented target vulnerability
- Ground truth schema: single `vulnerability_type`, single `description`, etc.
- If future samples have multiple targets, schema supports extension to array

### 2. Quality Scores Only for Target Match

Quality scoring (RCIR, AVA, FSV) is computed **ONCE** in `target_assessment`, NOT per-finding.

**Rationale:**
- For HALLUCINATED findings: nothing real to score
- For BONUS_VALID findings: no ground truth to compare against
- For SECURITY_THEATER: theoretical concerns don't need attack/fix scoring
- Reduces judge complexity and cost

### 3. Finding ID Assignment

The judge assigns `finding_id` based on array index from LLM output:
- `vulnerabilities[0]` → `finding_id: 0`
- `vulnerabilities[1]` → `finding_id: 1`
- etc.

### 4. Field Mapping (LLM Output → Judge)

| LLM Output Field | Judge Finding Field |
|------------------|---------------------|
| *(array index)* | `finding_id` |
| `vulnerabilities[i].explanation` | `description` |
| `vulnerabilities[i].type` | `vulnerability_type_claimed` |
| `vulnerabilities[i].severity` | `severity_claimed` |
| `vulnerabilities[i].location` | `location_claimed` |
| `verdict` | `overall_verdict.said_vulnerable` |
| `confidence` | `overall_verdict.confidence_expressed` |

---

## Finding Classifications

The judge must classify each finding into one of these categories:

### Valid Classifications (Credit Given)

| Classification | Description | Criteria |
|----------------|-------------|----------|
| `TARGET_MATCH` | Found the documented vulnerability | Type matches, location matches, explanation is correct |
| `PARTIAL_MATCH` | Related to target but incomplete | Mentions the issue but wrong type/location or incomplete explanation |
| `BONUS_VALID` | Real exploitable issue not documented | Must pass ALL 6 strict criteria (see below) |

### Invalid Classifications (No Credit)

| Classification | Description | Example |
|----------------|-------------|---------|
| `HALLUCINATED` | Issue does not exist in code | Claims reentrancy when there's no external call |
| `MISCHARACTERIZED` | Code exists but isn't vulnerable | Flags safe pattern as vulnerable |
| `DESIGN_CHOICE` | Intentional architecture decision | "Owner can pause contract" |
| `OUT_OF_SCOPE` | Issue in external contract | "Called contract doesn't validate..." |
| `SECURITY_THEATER` | Theoretical concern, no exploit | "Could be front-run" without concrete attack |
| `INFORMATIONAL` | True but not security-relevant | Gas optimization, code style |

---

## BONUS_VALID Strict Criteria

A finding can ONLY be classified as BONUS_VALID if ALL of the following are TRUE:

### 1. CONCRETE EXPLOIT
- Must have specific attack steps, not just "could be risky"
- BAD: "An attacker could potentially..."
- GOOD: "An attacker can call X, then Y, causing Z loss of funds"

### 2. NO TRUSTED ROLE COMPROMISE REQUIRED
- Exploit must NOT require compromised owner/admin/manager
- BAD: "If the owner is malicious..."
- BAD: "If admin loses their keys..."
- GOOD: "Any external caller can exploit..."

### 3. NO EXISTING MITIGATION
- No workaround exists in the code
- BAD: Batch function has issues but single-item function works
- GOOD: No alternative path exists

### 4. IN SCOPE
- Vulnerability must be in THIS contract's code
- BAD: "The called contract doesn't validate..."
- BAD: Speculative issues about unseen code
- GOOD: Issue is clearly in the analyzed contract

### 5. NOT A DESIGN CHOICE
- Must be unintentional flaw, not deliberate architecture
- BAD: Same pattern used consistently (intentional)
- BAD: Common industry patterns
- GOOD: Clearly deviates from intended behavior

### 6. MATERIAL IMPACT
- Must have real security consequences
- VALID: Loss of user funds, unauthorized access, state manipulation
- INVALID: Gas inefficiency, code style, theoretical concerns

---

## Quality Scoring Rubrics

### Type Match Levels

| Level | Description | Example |
|-------|-------------|---------|
| `exact` | Same terminology | "reentrancy" when GT is "reentrancy" |
| `semantic` | Different words, same meaning | "recursive call vulnerability" for "reentrancy" |
| `partial` | Related but not precise | "external call issue" for "reentrancy" |
| `wrong` | Incorrect type | "overflow" when GT is "reentrancy" |
| `not_mentioned` | Didn't specify type | No type given |

### Root Cause Identification (RCIR) - 0.0 to 1.0

Evaluates: Does the LLM explain WHY the code is vulnerable?

| Score | Criteria |
|-------|----------|
| 1.0 | Correctly explains the core issue (the root cause) |
| 0.75 | Identifies the issue but misses some nuance |
| 0.5 | Partially correct, identifies symptoms but not root cause |
| 0.25 | Tangentially related but misses main issue |
| 0.0 | Wrong explanation or none given |

**Input from LLM:** `vulnerabilities[i].explanation`

### Attack Vector Validity (AVA) - 0.0 to 1.0

Evaluates: Does the LLM describe a valid, executable attack?

| Score | Criteria |
|-------|----------|
| 1.0 | Valid, executable attack with specific steps |
| 0.75 | Attack is valid but missing some steps |
| 0.5 | Attack concept is right but details are wrong |
| 0.25 | Vaguely related attack description |
| 0.0 | Invalid attack or none described |

**Input from LLM:** `vulnerabilities[i].attack_scenario`

### Fix Suggestion Validity (FSV) - 0.0 to 1.0

Evaluates: Would the suggested fix actually remediate the vulnerability?

| Score | Criteria |
|-------|----------|
| 1.0 | Fix would fully remediate the vulnerability |
| 0.75 | Fix addresses the issue but could be improved |
| 0.5 | Fix partially addresses the issue |
| 0.25 | Fix is related but wouldn't fully work |
| 0.0 | Fix is wrong, would introduce issues, or none suggested |

**Input from LLM:** `vulnerabilities[i].suggested_fix`

---

## Common False Positives (Never BONUS_VALID)

The judge should be trained to reject these common false positives:

- "Admin could lose their keys" → applies to all contracts
- "Unbounded loop could hit gas limit" → if single-item alternative exists
- "External call could fail" → if there's graceful fallback
- "No validation for X" → if validation happens in called contract
- "Trusted role could set malicious value" → trusted role assumption
- "Self-managed role has no recovery" → deliberate design pattern
- "Could be front-run" → without specific profitable attack
- "Reentrancy possible" → if checks-effects-interactions followed or guard exists

---

## Judge Output Structure

```json
{
  "overall_verdict": {
    "said_vulnerable": true | false | null,
    "confidence_expressed": <float 0.0-1.0 or null>
  },

  "findings": [
    {
      "finding_id": 0,
      "description": "<what was claimed>",
      "vulnerability_type_claimed": "<type or null>",
      "severity_claimed": "<severity or null>",
      "location_claimed": "<location or null>",
      "matches_target": true | false,
      "is_valid_concern": true | false,
      "classification": "TARGET_MATCH | PARTIAL_MATCH | BONUS_VALID | HALLUCINATED | ...",
      "reasoning": "<detailed explanation>"
    }
  ],

  "target_assessment": {
    "found": true | false,
    "finding_id": <id or null>,
    "type_match": "exact | semantic | partial | wrong | not_mentioned",
    "type_match_reasoning": "<explanation>",
    "root_cause_identification": {
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    },
    "attack_vector_validity": {
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    },
    "fix_suggestion_validity": {
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }
  },

  "summary": {
    "total_findings": <int>,
    "target_matches": <int>,
    "partial_matches": <int>,
    "bonus_valid": <int>,
    "hallucinated": <int>,
    "mischaracterized": <int>,
    "design_choice": <int>,
    "out_of_scope": <int>,
    "security_theater": <int>,
    "informational": <int>
  },

  "notes": "<additional observations>"
}
```

---

## Prompt Engineering Tasks

### Task 1: System Prompt
- [ ] Define judge persona (expert smart contract security evaluator)
- [ ] Emphasize STRICT evaluation standards
- [ ] Explain the classification system
- [ ] Include BONUS_VALID criteria

### Task 2: User Prompt Template
- [ ] Format for presenting code, ground truth, LLM response
- [ ] Clear section headers
- [ ] Explicit output format instructions

### Task 3: Scoring Calibration
- [ ] Test with known good/bad responses
- [ ] Ensure RCIR/AVA/FSV scores are consistent
- [ ] Validate type_match classification

### Task 4: Edge Cases
- [ ] Handle empty vulnerabilities array (verdict: safe)
- [ ] Handle missing optional fields (attack_scenario, suggested_fix)
- [ ] Handle malformed LLM responses

### Task 5: Safe Contract Handling
- [ ] Separate prompt for safe contracts (no target vulnerability)
- [ ] All findings should be HALLUCINATED, SECURITY_THEATER, etc.
- [ ] target_assessment.found should be false

---

## Implementation Notes

### Current Implementation Location
- `src/judge/prompts.py` - Current judge prompts (JUDGE_PROMPT_VULNERABLE, JUDGE_PROMPT_SAFE)
- `src/judge/schemas.py` - Pydantic schemas
- `src/judge/runner.py` - Judge orchestration

### Key Considerations
1. Judge model: Currently using Mistral Large (mistral-large-2411)
2. Cost tracking: Include token counts and cost per evaluation
3. Retry logic: Handle API failures gracefully
4. Checkpointing: Resume from partial evaluations

---

## References

- JSON Schema: `schemas/ds/llm_judge_output.schema.json`
- LLM Output Schema: `schemas/ds/llm_output.schema.json`
- Ground Truth Schema: `schemas/ds/ground_truth.schema.json`
- Current Prompts: `src/judge/prompts.py`

---

## Version History

| Date | Change |
|------|--------|
| 2026-01-02 | Initial TODO created with full design decisions |
