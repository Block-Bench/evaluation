# Knowledge Assessment Probes - Temporal Contamination Dataset

This directory contains knowledge assessment prompts designed to detect whether an LLM has prior knowledge of specific blockchain security exploits **before** showing any code.

## Purpose

The temporal contamination evaluation aims to distinguish between:
- **Memorization**: Model recalls exploit from training data
- **Reasoning**: Model actually analyzes code to find vulnerabilities

By probing for prior knowledge first, we can better interpret code analysis results.

## Contents

- `ms_tc_*_knowledge_probe.json` - 46 knowledge assessment prompts (one per contract)

## Probe Structure

Each JSON file contains:

```json
{
  "sample_id": "ms_tc_001",
  "assessment_type": "knowledge_probe",
  "purpose": "Detect if model has prior knowledge of this exploit before code analysis",
  "prompt": "...",
  "expected_answers": {
    "exploit_name": "Nomad Bridge",
    "date": "2022-08-01",
    "year": "2022",
    "month": "08",
    "amount_lost_usd": "190000000",
    "amount_formatted": "$190 million",
    "vulnerability_type": "improper_initialization",
    "blockchain": "ethereum",
    "temporal_category": "pre_cutoff"
  },
  "scoring_notes": { ... }
}
```

## Evaluation Protocol

### Step 1: Knowledge Probe (No Code)
Send the `prompt` to the model. Do NOT show any code yet.

### Step 2: Analyze Response
Compare model's response against `expected_answers`.

### Step 3: Score Response

| Temporal Category | Model Response | Score | Interpretation |
|-------------------|----------------|-------|----------------|
| `pre_cutoff` | Familiar + Correct | `familiar_correct` | Expected - model knows this exploit |
| `pre_cutoff` | Familiar + Wrong | `familiar_incorrect` | Hallucination detected |
| `pre_cutoff` | Unfamiliar | `unfamiliar_but_should_know` | Surprising - well-known exploit |
| `post_cutoff` | Unfamiliar | `unfamiliar_honest` | Expected - exploit after training |
| `post_cutoff` | Familiar + Correct | `contaminated` | **Training data contamination!** |
| `post_cutoff` | Familiar + Wrong | `familiar_incorrect` | Hallucination |

### Step 4: Code Analysis
After recording the knowledge probe result, proceed with code analysis evaluation.

## Interpretation Matrix

```
                    │ Finds Vulnerability │ Misses Vulnerability
────────────────────┼─────────────────────┼──────────────────────
Knew the exploit    │ Possibly memorized  │ Weak despite knowledge
────────────────────┼─────────────────────┼──────────────────────
Didn't know exploit │ STRONG SIGNAL ✓     │ Expected difficulty
                    │ (actual reasoning)  │
```

## Key Questions Asked

1. **When** did this incident occur? (temporal knowledge)
2. **How much** was lost in USD? (headline detail)
3. **What type** of vulnerability? (technical classification)
4. **How** did the attack work? (mechanism understanding)
5. **Why** did it happen? (root cause understanding)

## Temporal Categories

- `pre_cutoff` - Exploits before model training cutoff (model may know)
- `post_cutoff` - Exploits after training cutoff (model should NOT know)
- `unknown` - Temporal category not determined

## Usage Example

```python
import json

# Load probe
with open('ms_tc_001_knowledge_probe.json') as f:
    probe = json.load(f)

# Send to model
response = model.generate(probe['prompt'])

# Compare against expected
expected = probe['expected_answers']
temporal = expected['temporal_category']

# Score based on temporal category and response accuracy
```

## Files

| File Pattern | Count | Description |
|--------------|-------|-------------|
| `ms_tc_*_knowledge_probe.json` | 46 | Individual probe files |
| `README.md` | 1 | This documentation |

## Related Directories

- `../contracts/` - Minimally sanitized Solidity contracts
- `../metadata/` - Full metadata with vulnerability details
- `../code_acts_annotation/` - CodeAct annotations for contracts

## Generation

Generated from metadata using:
```
dataset/temporal_contamination/minimalsanitized/metadata/ms_tc_*.json
```

Script extracts: exploit_name, date, amount_lost_usd, vulnerability_type, blockchain, description, root_cause, temporal_category
