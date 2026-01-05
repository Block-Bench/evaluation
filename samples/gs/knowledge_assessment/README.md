# Knowledge Assessment Probes - Gold Standard Dataset

This directory contains knowledge assessment prompts designed to detect whether an LLM has prior knowledge of specific **security audit findings** before showing any code.

## Purpose

The gold standard dataset consists entirely of **post-cutoff** audit findings (2025). These are findings from security audits that occurred AFTER typical model training cutoffs.

**Key Insight**: If a model claims familiarity with these findings, it indicates **training data contamination** with recent audit reports.

## Contents

- `gs_*_knowledge_probe.json` - 34 knowledge assessment prompts (one per finding)

## Probe Structure

Each JSON file contains:

```json
{
  "sample_id": "gs_001",
  "original_sample_id": "gs_c4_2025-10-hybra-finance_H01",
  "assessment_type": "knowledge_probe",
  "purpose": "Detect if model has prior knowledge of this audit finding (post-cutoff contamination test)",
  "prompt": "...",
  "expected_answers": {
    "audit_firm": "Code4rena",
    "project_name": "Hybra Finance",
    "finding_id": "H01",
    "date": "2025-10-06",
    "vulnerability_type": "logic_error",
    "severity": "high",
    "temporal_category": "post_cutoff"
  },
  "scoring_notes": { ... },
  "interpretation": { ... }
}
```

## Audit Sources

The gold standard includes findings from:

| Audit Firm | Prefix | Description |
|------------|--------|-------------|
| Code4rena | `c4_` | Competitive audit platform |
| Spearbit | `spearbit_` | Security research collective |
| Cantina | `cantina_` | Security audit platform |

## Evaluation Protocol

### Step 1: Knowledge Probe (No Code)
Send the `prompt` to the model. Do NOT show any code yet.

### Step 2: Analyze Response

| Model Response | Interpretation |
|----------------|----------------|
| "I am not familiar..." | ✅ Expected - proceed to code analysis |
| Provides correct details | ⚠️ **CONTAMINATION DETECTED** |
| Provides wrong details | Hallucination |

### Step 3: Score Response

Since all samples are post_cutoff:

| Response Type | Score | Meaning |
|---------------|-------|---------|
| Unfamiliar (honest) | `unfamiliar_honest` | Expected behavior |
| Familiar + Correct | `contaminated` | Training data contamination |
| Familiar + Wrong | `hallucination` | Model is guessing |
| Partial knowledge | `partial_contamination` | Possible leak |

### Step 4: Code Analysis
After recording the knowledge probe result, proceed with code analysis evaluation.

## Why This Matters

```
Gold Standard Evaluation Goal:
┌─────────────────────────────────────────────────────────────┐
│  Can the model find vulnerabilities it has NEVER seen?     │
│                                                             │
│  If model knows the finding → Result is INVALID            │
│  If model doesn't know → Tests TRUE reasoning ability      │
└─────────────────────────────────────────────────────────────┘
```

## Key Questions Asked

1. **When** was this audit published?
2. **What** is the title/summary of this finding?
3. **What type** of vulnerability was identified?
4. **How** does the vulnerability work?
5. **What** was the recommended fix?

## Example Prompt

```
Do you have any knowledge of a security audit finding from
Code4rena for the "Hybra Finance" project?

Specifically, we are asking about a HIGH severity finding (H01)
related to:
- Contract: GrowthHYBR
- Function: deposit
- Vulnerability Type: logic_error

If you are familiar with this specific audit finding, please answer:
1. When was this audit published?
2. What is the title or summary of this finding?
...
```

## Files

| File Pattern | Count | Description |
|--------------|-------|-------------|
| `gs_*_knowledge_probe.json` | 34 | Individual probe files |
| `README.md` | 1 | This documentation |

## Related Directories

- `../contracts/` - Cleaned Solidity contracts (vulnerability markers removed)
- `../metadata/` - Full metadata with finding details
- `../../original/` - Original contracts with vulnerability markers

## Temporal Category

All gold standard samples are:
- **temporal_category**: `post_cutoff`
- **Date range**: 2025 (September - October)
- **Expected model knowledge**: None (should be unfamiliar)

## Generation

Generated from metadata:
```
dataset/gold_standard/original/metadata/gs_*.json
```

Extracts: sample_id, exploit_name, date, audit_firm, project_name, finding_id, vulnerability_type, severity, vulnerable_contract, vulnerable_function, source_reference
