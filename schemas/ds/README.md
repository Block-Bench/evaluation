# DS Schema Documentation

This document describes all schemas used in the Difficulty-Stratified (DS) evaluation pipeline.

---

## Overview

| Schema | File | Purpose |
|--------|------|---------|
| [Ground Truth](#1-ground-truth) | `ground_truth.schema.json` | Minimal ground truth for evaluation |
| [LLM Output](#2-llm-output) | `llm_output.schema.json` | Raw LLM response format |
| [LLM Detection Output](#3-llm-detection-output) | `llm_detection_output.schema.json` | Wrapper with pipeline metadata |
| [LLM Judge Output](#4-llm-judge-output) | `llm_judge_output.schema.json` | Judge evaluation of LLM response |
| [Slither Output](#5-slither-output) | `slither_output.schema.json` | Slither static analysis wrapper |
| [Mythril Output](#6-mythril-output) | `mythril_output.schema.json` | Mythril symbolic execution wrapper |
| [Rule-Based Evaluator](#7-rule-based-evaluator) | `rulebased_evaluator_output.schema.json` | Automated keyword-based evaluation |
| [Human Review](#8-human-review) | `human_review_output.schema.json` | Expert human evaluation |
| [Divergence Report](#9-divergence-report) | `divergence_report.schema.json` | Comparison between evaluators |
| [Aggregated Metrics](#10-aggregated-metrics) | `aggregated_metrics.schema.json` | Hierarchical aggregated metrics |

---

## 1. Ground Truth

**File:** `ground_truth.schema.json`
**Location:** `samples/ds/tier{N}/ground_truth/{sample_id}.json`

Minimal schema containing only fields needed for judge evaluation.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `is_vulnerable` | boolean | Yes | Always `true` for DS (all samples are vulnerable) |
| `vulnerability_type` | string | Yes | Vulnerability category (e.g., "reentrancy", "access_control") |
| `vulnerable_functions` | array[string] | Yes | Function names where vulnerability exists |
| `severity` | string | Yes | Severity: "low", "medium", "high", "critical" |
| `description` | string | Yes | Explanation of vulnerability and impact |
| `fix_description` | string | Yes | Recommended remediation |
| `language` | string | Yes | Always "solidity" for DS |

### Example

```json
{
  "is_vulnerable": true,
  "vulnerability_type": "weak_randomness",
  "vulnerable_functions": ["random"],
  "severity": "low",
  "description": "The contract uses block.timestamp and block.blockhash as randomness sources. These are predictable by miners.",
  "fix_description": "Use Chainlink VRF or commit-reveal scheme instead of block variables.",
  "language": "solidity"
}
```

### Notes

- Full metadata available at `samples/ds/tier{N}/metadata/{sample_id}.json` if needed
- Fields like `source_dataset`, `difficulty_tier`, `references` excluded (not needed for judging)

---

## 2. LLM Output

**File:** `llm_output.schema.json`
**Location:** `results/detections/ds/{model}/tier{N}/{sample_id}.json` (within `prediction` field)

Raw JSON response from LLM when analyzing a contract.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `verdict` | string | Yes | "vulnerable" or "safe" |
| `confidence` | number | No | Model confidence 0.0-1.0 |
| `vulnerabilities` | array | Yes | List of detected vulnerabilities (empty if safe) |
| `overall_explanation` | string | No | Summary of security analysis |

### Vulnerability Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Vulnerability category |
| `severity` | string | No | "critical", "high", "medium", "low" |
| `location` | string | No | Function name or code location |
| `explanation` | string | Yes | Why it's vulnerable and exploitable |
| `attack_scenario` | string | No | Steps to exploit the vulnerability |
| `suggested_fix` | string | No | Recommended code changes |

### Example

```json
{
  "verdict": "vulnerable",
  "confidence": 0.92,
  "vulnerabilities": [
    {
      "type": "weak_randomness",
      "severity": "medium",
      "location": "random() function",
      "explanation": "The random() function uses block.timestamp and block.blockhash which are predictable by miners.",
      "attack_scenario": "1. Attacker monitors mempool. 2. Mines block with favorable timestamp. 3. Predicts random outcome.",
      "suggested_fix": "Replace block variables with Chainlink VRF or commit-reveal scheme."
    }
  ],
  "overall_explanation": "This contract has a critical flaw in its randomness generation."
}
```

### Mapping to Ground Truth

| LLM Output | Ground Truth | Evaluation Type |
|------------|--------------|-----------------|
| `verdict` | `is_vulnerable` | Exact match |
| `type` | `vulnerability_type` | Type accuracy |
| `location` | `vulnerable_functions` | Location match |
| `severity` | `severity` | Severity accuracy |
| `explanation` | `description` | Semantic comparison |
| `suggested_fix` | `fix_description` | Fix quality |
| `attack_scenario` | *(none)* | Plausibility check |
| `confidence` | *(none)* | Calibration metrics |

---

## 3. LLM Detection Output

**File:** `llm_detection_output.schema.json`
**Location:** `results/detections/ds/{model}/tier{N}/{sample_id}_{prompt_type}.json`

Wrapper schema that adds pipeline metadata around the raw LLM response. Used for storing detection results with full context.

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sample_id` | string | Yes | Sample identifier |
| `tier` | integer | No | Difficulty tier (1-4) |
| `model` | string | Yes | Model that produced this detection |
| `prompt_type` | string | Yes | "direct", "naturalistic", or "adversarial" |
| `timestamp` | string | Yes | ISO 8601 timestamp |
| `ground_truth` | object | No | Copy of ground truth for convenience |
| `prediction` | object | Yes | The raw LLM output (conforms to llm_output.schema) |
| `parsing` | object | Yes | Parsing status and raw response |
| `api_metrics` | object | No | API usage metrics |
| `error` | string | No | Pipeline error message if failed |

### Parsing Object

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Whether LLM response was successfully parsed |
| `errors` | array | List of parsing errors if any |
| `raw_response` | string | Raw text response before parsing |

### API Metrics Object

| Field | Type | Description |
|-------|------|-------------|
| `input_tokens` | integer | Number of input tokens |
| `output_tokens` | integer | Number of output tokens |
| `latency_ms` | number | API call latency in milliseconds |
| `cost_usd` | number | Estimated cost in USD |

### Example

```json
{
  "sample_id": "ds_t1_001",
  "tier": 1,
  "model": "claude_opus_4.5",
  "prompt_type": "direct",
  "timestamp": "2026-01-02T12:00:00Z",

  "ground_truth": {
    "is_vulnerable": true,
    "vulnerability_type": "weak_randomness",
    "vulnerable_functions": ["random"],
    "severity": "low"
  },

  "prediction": {
    "verdict": "vulnerable",
    "confidence": 0.92,
    "vulnerabilities": [
      {
        "type": "weak_randomness",
        "severity": "medium",
        "location": "random() function",
        "explanation": "Uses block.timestamp which is predictable...",
        "attack_scenario": "Attacker mines block with favorable timestamp...",
        "suggested_fix": "Use Chainlink VRF..."
      }
    ],
    "overall_explanation": "Contract has weak randomness vulnerability."
  },

  "parsing": {
    "success": true,
    "errors": [],
    "raw_response": "```json\n{...}\n```"
  },

  "api_metrics": {
    "input_tokens": 850,
    "output_tokens": 420,
    "latency_ms": 3200,
    "cost_usd": 0.025
  },

  "error": null
}
```

### Notes

- `prediction` contains the raw LLM output conforming to `llm_output.schema.json`
- `ground_truth` is optional - can be looked up separately by sample_id
- `parsing.raw_response` preserved for debugging parse failures
- Same wrapper pattern used for judge and human review outputs

---

## 4. LLM Judge Output

**File:** `llm_judge_output.schema.json`
**Location:** `results/judge/ds/{judge_model}/{evaluated_model}/tier{N}/{sample_id}_{prompt_type}.json`

Evaluation output from the LLM Judge when assessing an LLM's vulnerability detection response.

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sample_id` | string | Yes | Sample identifier |
| `transformed_id` | string | No | Transformed sample ID if applicable |
| `prompt_type` | string | Yes | "direct", "naturalistic", or "adversarial" |
| `judge_model` | string | Yes | Model used as judge |
| `timestamp` | string | Yes | ISO 8601 evaluation timestamp |
| `overall_verdict` | object | Yes | Extraction of LLM's verdict |
| `findings` | array | Yes | Evaluation of each LLM finding |
| `target_assessment` | object | Yes | Assessment of target vulnerability detection |
| `summary` | object | Yes | Summary counts |
| `notes` | string | No | Additional observations |
| `judge_latency_ms` | number | No | Judge latency in ms |
| `judge_input_tokens` | integer | No | Input tokens used |
| `judge_output_tokens` | integer | No | Output tokens generated |
| `judge_cost_usd` | number | No | Cost in USD |

### Overall Verdict Object

| Field | Type | Description |
|-------|------|-------------|
| `said_vulnerable` | boolean/null | Whether LLM said contract is vulnerable |
| `confidence_expressed` | number/null | Confidence level (0.0-1.0) if expressed |

### Finding Object Fields

Each finding from the LLM response is evaluated:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `finding_id` | integer | Yes | Index from LLM vulnerabilities array |
| `description` | string | Yes | What the LLM claimed |
| `vulnerability_type_claimed` | string | No | Type claimed by LLM |
| `severity_claimed` | string | No | Severity claimed by LLM |
| `location_claimed` | string | No | Code location claimed |
| `matches_target` | boolean | Yes | Whether finding matches target vulnerability |
| `is_valid_concern` | boolean | Yes | Whether finding is valid (target or bonus) |
| `classification` | string | Yes | Finding classification (see below) |
| `reasoning` | string | Yes | Judge's explanation for classification |

### Finding Classifications

| Classification | Valid? | Description |
|----------------|--------|-------------|
| `TARGET_MATCH` | Yes | Correctly identifies the documented vulnerability |
| `PARTIAL_MATCH` | Yes | Related to target but doesn't fully capture it |
| `BONUS_VALID` | Yes | Real exploitable issue not in ground truth |
| `HALLUCINATED` | No | Issue does not exist in the code |
| `MISCHARACTERIZED` | No | Code exists but isn't a vulnerability |
| `DESIGN_CHOICE` | No | Intentional architectural decision |
| `OUT_OF_SCOPE` | No | Issue in external/called contract |
| `SECURITY_THEATER` | No | Theoretical concern, no concrete exploit |
| `INFORMATIONAL` | No | True observation but not security-relevant |

### Target Assessment Object

Quality scoring for the target vulnerability (only populated if found):

| Field | Type | Description |
|-------|------|-------------|
| `found` | boolean | Whether target vulnerability was found |
| `finding_id` | integer/null | Which finding matched target |
| `type_match` | string | "exact", "semantic", "partial", "wrong", "not_mentioned" |
| `type_match_reasoning` | string | Explanation of type match |
| `root_cause_identification` | object/null | RCIR score (0.0-1.0) + reasoning |
| `attack_vector_validity` | object/null | AVA score (0.0-1.0) + reasoning |
| `fix_suggestion_validity` | object/null | FSV score (0.0-1.0) + reasoning |

### Example

```json
{
  "sample_id": "ds_t1_001",
  "transformed_id": "ds_t1_001",
  "prompt_type": "direct",
  "judge_model": "mistral-large-2411",
  "timestamp": "2026-01-02T12:00:00Z",

  "overall_verdict": {
    "said_vulnerable": true,
    "confidence_expressed": 0.92
  },

  "findings": [
    {
      "finding_id": 0,
      "description": "Uses block.timestamp for randomness which is predictable by miners",
      "vulnerability_type_claimed": "weak_randomness",
      "severity_claimed": "medium",
      "location_claimed": "random() function",
      "matches_target": true,
      "is_valid_concern": true,
      "classification": "TARGET_MATCH",
      "reasoning": "Correctly identifies the documented weak randomness vulnerability in the random() function."
    },
    {
      "finding_id": 1,
      "description": "Owner can change fee percentage",
      "vulnerability_type_claimed": "centralization",
      "severity_claimed": "low",
      "location_claimed": "setFee()",
      "matches_target": false,
      "is_valid_concern": false,
      "classification": "DESIGN_CHOICE",
      "reasoning": "Admin fee control is an intentional design pattern, not a vulnerability."
    }
  ],

  "target_assessment": {
    "found": true,
    "finding_id": 0,
    "type_match": "exact",
    "type_match_reasoning": "Used 'weak_randomness' which matches ground truth exactly.",
    "root_cause_identification": {
      "score": 0.9,
      "reasoning": "Correctly explains that block.timestamp is predictable by miners."
    },
    "attack_vector_validity": {
      "score": 0.85,
      "reasoning": "Valid attack steps but missing mempool monitoring detail."
    },
    "fix_suggestion_validity": {
      "score": 0.9,
      "reasoning": "Correctly suggests Chainlink VRF as solution."
    }
  },

  "summary": {
    "total_findings": 2,
    "target_matches": 1,
    "partial_matches": 0,
    "bonus_valid": 0,
    "hallucinated": 0,
    "mischaracterized": 0,
    "design_choice": 1,
    "out_of_scope": 0,
    "security_theater": 0,
    "informational": 0
  },

  "notes": "Good target detection but over-flagged admin functionality.",
  "judge_latency_ms": 2500,
  "judge_input_tokens": 3200,
  "judge_output_tokens": 850,
  "judge_cost_usd": 0.012
}
```

### LLM Output → Judge Output Mapping

| LLM Output Field | Judge Finding Field |
|------------------|---------------------|
| *(array index)* | `finding_id` |
| `vulnerabilities[i].explanation` | `description` |
| `vulnerabilities[i].type` | `vulnerability_type_claimed` |
| `vulnerabilities[i].severity` | `severity_claimed` |
| `vulnerabilities[i].location` | `location_claimed` |
| `verdict` | `overall_verdict.said_vulnerable` |
| `confidence` | `overall_verdict.confidence_expressed` |

For quality scoring in `target_assessment`:

| LLM Field | Used For |
|-----------|----------|
| `explanation` | `root_cause_identification` score |
| `attack_scenario` | `attack_vector_validity` score |
| `suggested_fix` | `fix_suggestion_validity` score |

---

## 5. Slither Output

**File:** `slither_output.schema.json`
**Location:** `results/detections/ds/slither/tier{N}/{sample_id}.json`

Wrapper schema for Slither static analysis. Raw tool output preserved in `raw_output` field.

### Wrapper Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sample_id` | string | Yes | Sample identifier (e.g., "ds_t1_001") |
| `tier` | integer | Yes | Difficulty tier (1-4) |
| `tool` | string | Yes | Always "slither" |
| `tool_version` | string | Yes | Slither version (e.g., "0.11.3") |
| `solc_version` | string | No | Solidity compiler version used |
| `timestamp` | string | Yes | ISO 8601 execution timestamp |
| `success` | boolean | Yes | Whether execution succeeded |
| `error` | string/null | No | Error message if failed |
| `execution_time_ms` | number | No | Execution duration |
| `exit_code` | integer | No | Process exit code |
| `raw_output` | object | Yes | Raw Slither JSON output |

### Example

```json
{
  "sample_id": "ds_t1_001",
  "tier": 1,
  "tool": "slither",
  "tool_version": "0.11.3",
  "solc_version": "0.8.0",
  "timestamp": "2026-01-01T12:00:00Z",
  "success": true,
  "error": null,
  "execution_time_ms": 1250,
  "exit_code": 0,
  "raw_output": {
    "success": true,
    "error": null,
    "results": {
      "detectors": [
        {
          "check": "weak-prng",
          "impact": "High",
          "confidence": "Medium",
          "description": "TheRun.random() uses weak PRNG...",
          "elements": [...]
        }
      ]
    }
  }
}
```

### Notes

- `raw_output` structure defined by Slither, not validated beyond being an object
- Run with `slither contract.sol --json -` to get JSON output
- Detectors list: https://github.com/crytic/slither/wiki/Detector-Documentation

---

## 6. Mythril Output

**File:** `mythril_output.schema.json`
**Location:** `results/detections/ds/mythril/tier{N}/{sample_id}.json`

Wrapper schema for Mythril symbolic execution. Raw tool output preserved in `raw_output` field.

### Wrapper Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sample_id` | string | Yes | Sample identifier (e.g., "ds_t1_001") |
| `tier` | integer | Yes | Difficulty tier (1-4) |
| `tool` | string | Yes | Always "mythril" |
| `tool_version` | string | Yes | Mythril version (e.g., "0.24.8") |
| `solc_version` | string | No | Solidity compiler version used |
| `timestamp` | string | Yes | ISO 8601 execution timestamp |
| `success` | boolean | Yes | Whether execution succeeded |
| `error` | string/null | No | Error message if failed |
| `timeout` | boolean | No | Whether execution timed out |
| `execution_time_ms` | number | No | Execution duration |
| `exit_code` | integer | No | Process exit code |
| `analysis_mode` | string | No | Analysis depth: "quick", "standard", "deep" |
| `raw_output` | object | Yes | Raw Mythril JSON output |

### Example

```json
{
  "sample_id": "ds_t1_001",
  "tier": 1,
  "tool": "mythril",
  "tool_version": "0.24.8",
  "solc_version": "0.8.0",
  "timestamp": "2026-01-01T12:00:00Z",
  "success": true,
  "error": null,
  "timeout": false,
  "execution_time_ms": 45000,
  "exit_code": 0,
  "analysis_mode": "standard",
  "raw_output": {
    "success": true,
    "error": null,
    "issues": [
      {
        "swc-id": "SWC-120",
        "title": "Weak Sources of Randomness from Chain Attributes",
        "severity": "Medium",
        "description": "The block.timestamp is used...",
        "contract": "TheRun",
        "function": "random()"
      }
    ]
  }
}
```

### Notes

- `raw_output` structure defined by Mythril, not validated beyond being an object
- Run with `myth analyze contract.sol --format json` to get JSON output
- Mythril can be slow; `timeout` field tracks if analysis was cut short
- SWC Registry: https://swcregistry.io/

---

## 7. Rule-Based Evaluator

**File:** `rulebased_evaluator_output.schema.json`
**Location:** `results/evaluations/rulebased/ds/{model}/tier{N}/{sample_id}.json`

Automated evaluation using keyword/string matching (no LLM). Faster and cheaper than judge, useful for catching obvious issues.

### Key Fields

| Field | Type | Description |
|-------|------|-------------|
| `verdict_check` | object | Compares model verdict to ground truth |
| `type_check` | object | Keyword-based vulnerability type matching |
| `location_check` | object | Function name matching |
| `severity_check` | object | Severity level comparison |
| `finding_counts` | object | Counts of findings |
| `keyword_analysis` | object | Keyword coverage in explanation |
| `computed_scores` | object | Automated scores (0.0-1.0) |
| `flags` | object | Boolean flags for common issues |

### Computed Scores

| Score | Description |
|-------|-------------|
| `detection_score` | 1.0 if verdict correct, 0.0 otherwise |
| `type_accuracy` | 1.0 exact match, 0.5 semantic, 0.0 otherwise |
| `location_accuracy` | Fraction of ground truth functions mentioned |
| `severity_accuracy` | 1.0 exact, 0.75 within one level, 0.0 otherwise |
| `keyword_coverage` | Fraction of ground truth keywords found |

### Flags

| Flag | Description |
|------|-------------|
| `likely_target_found` | Type and location both match |
| `potential_hallucination` | Has findings with no type/location match |
| `severity_mismatch` | Severity differs from ground truth |
| `over_reporting` | More than 3 findings reported |

---

## 8. Human Review

**File:** `human_review_output.schema.json`
**Location:** `results/evaluations/human/ds/{model}/tier{N}/{sample_id}.json`

Expert human evaluation of model predictions. Uses 1-5 scale for quality scores (more intuitive for humans).

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sample_id` | string | Yes | Sample identifier |
| `model_evaluated` | string | Yes | Model being reviewed |
| `reviewer_id` | string | Yes | Human reviewer identifier |
| `review_timestamp` | string | Yes | ISO 8601 timestamp |
| `verdict_assessment` | object | Yes | Assessment of verdict |
| `findings_assessment` | array | Yes | Per-finding evaluations |
| `additional_findings_missed` | array | No | Vulnerabilities model missed |
| `overall_quality` | object | Yes | Overall assessment |
| `review_metadata` | object | No | Review process metadata |

### Finding Assessment Fields

Human reviewers evaluate **each finding** (not just target):

| Field | Type | Description |
|-------|------|-------------|
| `finding_id` | integer | Index from model output |
| `classification` | string | Same enum as judge (TARGET_MATCH, HALLUCINATED, etc.) |
| `type_correct` | boolean | Whether type is correct |
| `location_correct` | boolean | Whether location is correct |
| `explanation_quality` | integer | 1-5 scale (1=wrong, 3=adequate, 5=excellent) |
| `attack_scenario_quality` | integer | 1-5 scale |
| `fix_quality` | integer | 1-5 scale |
| `notes` | string | Reviewer notes |

### Overall Quality

| Field | Type | Description |
|-------|------|-------------|
| `score` | number | 1.0-5.0 overall quality |
| `strengths` | array | What model did well |
| `weaknesses` | array | Where model fell short |
| `recommendation` | string | "pass", "marginal", or "fail" |

---

## 9. Divergence Report

**File:** `divergence_report.schema.json`
**Location:** `results/divergence/{comparison_type}/ds/{model}/tier{N}/{sample_id}.json`

Comparison between different evaluators to catch disagreements.

### Comparison Types

| Type | Description |
|------|-------------|
| `rulebased_vs_judge` | Rule-based evaluator vs LLM Judge |
| `rulebased_vs_human` | Rule-based evaluator vs Human Review |
| `judge_vs_human` | LLM Judge vs Human Review |

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `comparison_type` | string | Which evaluators are being compared |
| `has_divergence` | boolean | Whether any divergence was found |
| `divergence_severity` | string | "critical", "high", "medium", "low" |
| `divergences` | array | List of specific divergences |
| `agreement_summary` | object | What agrees and disagrees |
| `requires_human_review` | boolean | Whether human arbitration needed |
| `review_priority` | string | Priority for review |
| `resolution` | object | Resolution if reviewed |

### Divergence Types

| Type | Severity | Description |
|------|----------|-------------|
| `verdict_mismatch` | Critical | Disagree on detection correctness |
| `target_found_mismatch` | High | Disagree on target vulnerability detection |
| `classification_mismatch` | Medium | Disagree on finding classification |
| `quality_score_mismatch` | Low | Significant difference in quality scores |
| `type_match_mismatch` | Medium | Disagree on type match level |

---

## 10. Aggregated Metrics

**File:** `aggregated_metrics.schema.json`
**Location:** Varies by aggregation level (see below)

Hierarchical aggregated metrics at multiple levels.

### Aggregation Levels

| Level | Location | Description |
|-------|----------|-------------|
| `sample` | `results/metrics/ds/{model}/samples/{sample_id}.json` | Per-sample metrics |
| `tier` | `results/metrics/ds/{model}/tier{N}_metrics.json` | Per-tier aggregation |
| `dataset_type` | `results/metrics/ds/{model}/ds_summary.json` | Entire DS dataset |
| `entire_dataset` | `results/metrics/{model}/overall_summary.json` | DS + TC + GS combined |

### Metric Tiers

Metrics are organized into 7 tiers:

| Tier | Name | Key Metrics |
|------|------|-------------|
| 1 | Detection | accuracy, precision, recall, f1, f2, fpr, fnr |
| 2 | Target Finding | target_detection_rate, lucky_guess_rate, bonus_discovery_rate |
| 3 | Finding Quality | finding_precision, hallucination_rate, over_flagging_score |
| 4 | Reasoning Quality | mean_rcir, mean_ava, mean_fsv (only where target found) |
| 5 | Type Accuracy | exact_match_rate, semantic_match_rate, partial_match_rate |
| 6 | Calibration | ece, mce, overconfidence_rate, brier_score |
| 7 | Composite | sui, true_understanding_score, lucky_guess_indicator |

### Breakdowns

Metrics can include optional breakdowns:

| Breakdown | Description |
|-----------|-------------|
| `by_vulnerability_type` | Performance per vulnerability type |
| `by_tier` | Performance per difficulty tier |
| `by_prompt_type` | Performance per prompt type (direct, naturalistic, adversarial) |
| `divergence_summary` | Count of divergences by severity |

### Example (Tier-Level)

```json
{
  "aggregation_level": "tier",
  "scope": {
    "dataset_type": "ds",
    "tier": 1,
    "model": "claude_opus_4.5"
  },
  "timestamp": "2026-01-02T12:00:00Z",
  "sample_counts": {
    "total_samples": 20,
    "vulnerable_samples": 20,
    "safe_samples": 0
  },
  "detection": {
    "accuracy": 0.85,
    "precision": 1.0,
    "recall": 0.85,
    "f1": 0.92,
    "tp": 17,
    "fn": 3
  },
  "target_finding": {
    "target_detection_rate": 0.75,
    "lucky_guess_rate": 0.10,
    "target_found_count": 15
  },
  "finding_quality": {
    "finding_precision": 0.82,
    "hallucination_rate": 0.10,
    "avg_findings_per_sample": 1.5
  },
  "reasoning_quality": {
    "mean_rcir": 0.85,
    "mean_ava": 0.78,
    "mean_fsv": 0.82,
    "n_samples_with_reasoning": 15
  },
  "type_accuracy": {
    "exact_match_rate": 0.70,
    "semantic_match_rate": 0.85
  },
  "composite": {
    "sui": 0.72,
    "true_understanding_score": 0.68
  }
}
```

---

## Validation

Validate files against schemas using `ajv-cli`:

```bash
# Install ajv-cli
npm install -g ajv-cli

# Validate ground truth
ajv validate -s schemas/ds/ground_truth.schema.json -d samples/ds/tier1/ground_truth/ds_t1_001.json

# Validate LLM output (extract prediction field first)
ajv validate -s schemas/ds/llm_output.schema.json -d prediction.json
```

---

## Version

- Schema version: 1.0
- Last updated: January 2026
