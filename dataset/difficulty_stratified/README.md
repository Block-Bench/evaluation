# Difficulty-Stratified Smart Contract Dataset

A curated collection of 224 vulnerable smart contracts organized by detection difficulty, designed for evaluating AI-based vulnerability detection tools.

## Overview

This dataset stratifies smart contract vulnerabilities into four difficulty tiers based on detection complexity, enabling granular assessment of detection capabilities across varying challenge levels.

| Tier | Level | Contracts | Description |
|------|-------|-----------|-------------|
| 1 | Easy | 87 | Basic vulnerabilities with clear patterns |
| 2 | Medium | 87 | Moderate complexity requiring contract flow understanding |
| 3 | Hard | 36 | Complex vulnerabilities involving subtle logic or multi-contract interactions |
| 4 | Expert | 14 | Advanced vulnerabilities requiring deep protocol knowledge |

## Directory Structure

```
difficulty_stratified/
├── original/           # Contracts WITH vulnerability hints (for reference)
│   ├── tier1/
│   │   ├── contracts/  # .sol files
│   │   └── metadata/   # .json files
│   ├── tier2/
│   ├── tier3/
│   ├── tier4/
│   └── index.json
├── cleaned/            # Contracts WITHOUT vulnerability hints (for evaluation)
│   ├── tier1/
│   ├── tier2/
│   ├── tier3/
│   ├── tier4/
│   └── index.json
└── README.md
```

## Dataset Variants

### Original
Contains contracts with vulnerability-hinting identifiers, comments, and documentation intact. Use for:
- Understanding the vulnerability
- Verifying ground truth
- Training with explicit labels

### Cleaned (Sanitized)
Vulnerability hints removed while preserving the vulnerable code patterns. Use for:
- Unbiased evaluation of detection tools
- Testing semantic understanding vs. pattern matching
- Benchmarking without information leakage

**Sanitization applied:**
- Removed vulnerability-hinting identifiers (`Vulnerable*`, `Exploit*`, `Attack*`, etc.)
- Removed hint comments (`@vulnerable_at_lines`, `// <yes> <report>`, etc.)
- Removed DeFiVulnLabs documentation blocks (`Name:`, `Description:`, `Mitigation:`)
- Removed security challenge hints (`#spotthebug`, `immunefi`)

### Manual Cleanings

In addition to automated sanitization, the following contracts received **manual review and cleaning** to address issues identified during quality assurance:

| Contract | Issue | Fix Applied |
|----------|-------|-------------|
| `ds_t1_002` | Contained fixed versions and fallback hint comment | Removed fixed functions (`withdrawBalanceV2`, `withdrawBalanceV3`) and revealing comments |
| `ds_t1_004` | Contained fixed version and assert hints | Removed `safe_add` function and auditor assert comments |
| `ds_t1_005` | Contained fixed version and "should be protected" comment | Removed `changeOwnerV2` function and revealing comment |
| `ds_t1_006` | Missing interface required to demonstrate vulnerability | Added mismatched interface and caller contract |
| `ds_t1_007` | Metadata incorrectly referenced `withdraw` instead of `fallback` | Updated `vulnerable_function` to `fallback` |
| `ds_t1_039` | Contained attack contract (`executor`) demonstrating exploit | Removed attack contract |
| `ds_t1_041` | Comment explicitly explained reentrancy vulnerability | Removed revealing comment |
| `ds_t1_045` | Comment hinted at fallback-based attack vector | Removed revealing comments |
| `ds_t2_015` | Comment revealed missing access control | Removed "wrong visibility" comment |
| `ds_t2_029` | Comment revealed constructor naming vulnerability | Removed "constructor should be Missing" comment |
| `ds_t2_038` | Comment revealed constructor naming vulnerability | Removed "constructor should be Missing" comment |
| `ds_t2_043` | Comment revealed missing access control | Removed "should be protected" comment |
| `ds_t2_037` | Contained fixed version (`setV2`) showing correct interface type | Removed `setV2` from interface and caller |
| `ds_t2_045` | Contained commented-out fixed version and assert hints | Removed `safe_add` comments and auditor assert hints |
| `ds_t4_001` | Comments explained reentrancy attack mechanism | Removed bypass hint, reentrancy explanation, and "Reentered" log |

These manual interventions ensure the cleaned dataset provides a fair evaluation without information leakage while preserving all vulnerable code patterns.

## Statistics

### Source Distribution

| Source Dataset | Count | Percentage |
|----------------|-------|------------|
| SmartBugs-Curated | 143 | 63.8% |
| DeFiVulnLabs | 56 | 25.0% |
| Not-So-Smart-Contracts | 25 | 11.2% |

### Vulnerability Types

| Type | Count | Type | Count |
|------|-------|------|-------|
| unchecked_return | 53 | signature_replay | 2 |
| reentrancy | 40 | storage_collision | 2 |
| logic_error | 24 | unchecked_call | 2 |
| access_control | 23 | approval_scam | 1 |
| integer_issues | 19 | backdoor | 1 |
| weak_randomness | 10 | contract_check_bypass | 1 |
| dos | 9 | data_exposure | 1 |
| honeypot | 6 | delegatecall_injection | 1 |
| front_running | 5 | flash_loan_attack | 1 |
| oracle_manipulation | 5 | forced_ether | 1 |
| timestamp_dependency | 5 | inflation_attack | 1 |
| interface_mismatch | 2 | precision_loss | 1 |
| selfdestruct | 2 | short_address | 1 |
| | | storage_misuse | 1 |
| | | token_incompatibility | 1 |
| | | tx_origin_auth | 1 |
| | | unprotected_callback | 1 |
| | | variable_shadowing | 1 |

*31 distinct vulnerability types across 224 contracts*

### Severity Distribution

| Severity | Count |
|----------|-------|
| Medium | 112 |
| High | 83 |
| Low | 16 |
| Critical | 13 |

## Naming Convention

All contracts follow the pattern: `ds_tN_XXX`

- `ds` = difficulty-stratified
- `tN` = tier number (1-4)
- `XXX` = sequential ID within tier (001-087)

Examples:
- `ds_t1_001` - First contract in Tier 1 (Easy)
- `ds_t4_014` - Last contract in Tier 4 (Expert)

## Metadata Schema

Each contract has an accompanying JSON metadata file:

```json
{
  "id": "ds_t1_001",
  "original_id": "notso_bad_randomness_therun",
  "source_dataset": "not-so-smart-contracts",
  "vulnerability_type": "weak_randomness",
  "vulnerable_function": "theRun",
  "vulnerable_lines": [45, 48],
  "severity": "low",
  "difficulty_tier": 1,
  "description": "Vulnerability description...",
  "fix_description": "Remediation guidance...",
  "is_vulnerable": true,
  "context_level": "single_file",
  "references": ["https://..."]
}
```

### Key Fields

| Field | Description |
|-------|-------------|
| `id` | Unique identifier in this dataset |
| `original_id` | ID from source dataset |
| `source_dataset` | Origin (smartbugs-curated, DeFiVulnLabs, not-so-smart-contracts) |
| `vulnerability_type` | Standardized vulnerability classification |
| `vulnerable_function` | Function containing the vulnerability |
| `vulnerable_lines` | Line numbers of vulnerable code |
| `severity` | Impact level (low, medium, high, critical) |
| `difficulty_tier` | Detection difficulty (1-4) |
| `description` | Vulnerability explanation |
| `fix_description` | Recommended remediation |

## Difficulty Tier Assignment

Difficulty tiers were **initially assigned using heuristics** and subsequently **reviewed by human experts** to ensure accuracy.

The original source datasets (SmartBugs-Curated, DeFiVulnLabs, Not-So-Smart-Contracts) do not provide difficulty ratings. Our assignment process:

1. **Automated assignment** - Heuristic-based initial classification
2. **Human review** - Security researchers validated and adjusted tier assignments

### Assignment Criteria

| Factor | Description |
|--------|-------------|
| Vulnerability Type | Reentrancy → easier, Oracle manipulation → harder |
| Code Complexity | Lines of code, function count, modifier count |
| Pattern Clarity | Single function vs. cross-function vs. cross-contract |
| Domain Knowledge | General Solidity vs. DeFi-specific expertise required |

### Tier Guidelines

| Tier | Detection Approach |
|------|-------------------|
| 1 | Detectable by basic static analysis patterns |
| 2 | Requires understanding of contract state flow |
| 3 | Requires multi-contract or subtle logic analysis |
| 4 | Requires advanced DeFi/protocol knowledge |

**Note:** Tiers reflect detection difficulty, NOT vulnerability severity.

## Usage

### Loading the Dataset

```python
import json
from pathlib import Path

def load_tier(tier: int, variant: str = "cleaned"):
    """Load all contracts from a specific tier."""
    base = Path(f"dataset/difficulty_stratified/{variant}/tier{tier}")

    for contract_file in (base / "contracts").glob("*.sol"):
        contract_id = contract_file.stem
        metadata_file = base / "metadata" / f"{contract_id}.json"

        code = contract_file.read_text()
        metadata = json.loads(metadata_file.read_text())

        yield {
            "id": contract_id,
            "code": code,
            "metadata": metadata
        }

# Example: Load all Tier 1 cleaned contracts
for sample in load_tier(1, "cleaned"):
    print(f"{sample['id']}: {sample['metadata']['vulnerability_type']}")
```

### Evaluating a Detection Tool

```python
def evaluate_by_tier(detector, variant="cleaned"):
    """Evaluate detection accuracy per difficulty tier."""
    results = {}

    for tier in [1, 2, 3, 4]:
        correct = 0
        total = 0

        for sample in load_tier(tier, variant):
            prediction = detector.analyze(sample["code"])
            ground_truth = sample["metadata"]["vulnerability_type"]

            if prediction == ground_truth:
                correct += 1
            total += 1

        results[f"tier{tier}"] = {
            "accuracy": correct / total,
            "total": total
        }

    return results
```

## Quality Assurance

All contracts have been:

1. **Verified for vulnerability presence** - Original contracts contain documented vulnerabilities
2. **Sanitization verified** - Cleaned contracts have no information leakage
3. **Not over-sanitized** - Vulnerable code patterns preserved in cleaned versions
4. **Metadata validated** - All required fields present and accurate

### Verification Scripts

Located in `support/ds_prep/`:

| Script | Purpose |
|--------|---------|
| `verify_cleaned.py` | Automated leakage and over-sanitization check |
| `populate_cleaned.py` | Generates cleaned versions from sanitized |
| `MANUAL_REVIEW_INSTRUCTIONS.md` | Guide for human reviewers |

## Citation

If you use this dataset, please cite:

```
[Citation to be added]
```

## License

This dataset aggregates contracts from multiple sources under their respective licenses:
- SmartBugs-Curated: [MIT License](https://github.com/smartbugs/smartbugs-curated)
- DeFiVulnLabs: [MIT License](https://github.com/SunWeb3Sec/DeFiVulnLabs)
- Not-So-Smart-Contracts: [Apache 2.0](https://github.com/crytic/not-so-smart-contracts)
