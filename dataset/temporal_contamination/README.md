# Temporal Contamination Dataset

## Overview

The Temporal Contamination (TC) dataset is a collection of **50 real-world smart contract exploits** designed to evaluate LLM vulnerability detection capabilities while controlling for temporal data leakage. These contracts represent actual DeFi hacks ranging from 2016 (The DAO) to 2024 (recent exploits), with total losses exceeding **$3 billion USD**.

## Purpose

This dataset addresses a critical evaluation challenge: **temporal contamination** in LLM training data. Models trained on data that includes post-exploit analyses, news articles, or security reports may "recognize" vulnerabilities rather than genuinely "detect" them.

The TC dataset provides:
1. **Multiple transformation variants** to test different aspects of model understanding
2. **Controlled information leakage** through progressive sanitization levels
3. **Causal understanding evaluation** through Code Act annotations
4. **Pattern matching detection** through decoy injections

## Dataset Statistics

| Metric | Value |
|--------|-------|
| Total Exploits | 50 |
| Date Range | 2016 - 2024 |
| Total Losses | >$3 billion USD |
| Vulnerability Types | 18 categories |
| Transformation Variants | 9 |
| Total Contract Files | 450 (50 x 9 variants) |

---

## Vulnerability Type Distribution

| Vulnerability Type | Count | Percentage | Examples |
|-------------------|-------|------------|----------|
| access_control | 14 | 28% | Poly Network, Ronin, Socket Gateway |
| price_oracle_manipulation | 8 | 16% | Harvest, Cream, UwU Lend |
| reentrancy | 7 | 14% | The DAO, Curve, Penpie |
| arithmetic_error | 5 | 10% | KyberSwap, Wise Lending |
| logic_error | 2 | 4% | Compound cTUSD, Bedrock |
| oracle_manipulation | 2 | 4% | Sonne, Exactly |
| governance_attack | 1 | 2% | Beanstalk |
| improper_initialization | 1 | 2% | Nomad Bridge |
| pool_manipulation | 1 | 2% | Indexed Finance |
| validation_bypass | 1 | 2% | Qubit Bridge |
| reinitialization | 1 | 2% | DODO |
| accounting_manipulation | 1 | 2% | Alpha Homora |
| signature_verification | 1 | 2% | Anyswap |
| input_validation | 1 | 2% | BurgerSwap |
| accounting_error | 1 | 2% | BVaults |
| bridge_security | 1 | 2% | Orbit Chain |
| arithmetic_manipulation | 1 | 2% | Radiant Capital |
| price_manipulation | 1 | 2% | Gamma Strategies |

---

## Complete Exploit List

| ID | Exploit Name | Vulnerability Type | Severity | Date | Loss (USD) |
|----|-------------|-------------------|----------|------|------------|
| tc_001 | Nomad Bridge | improper_initialization | critical | 2022-08 | $190M |
| tc_002 | Beanstalk | governance_attack | critical | 2022-04 | $182M |
| tc_003 | Parity Wallet | access_control | critical | 2017-11 | $280M |
| tc_004 | Harvest Finance | price_oracle_manipulation | critical | 2020-10 | $34M |
| tc_005 | Curve Finance (Vyper) | reentrancy | critical | 2023-07 | $70M |
| tc_006 | Ronin Bridge | access_control | critical | 2022-03 | $625M |
| tc_007 | Poly Network | access_control | critical | 2021-08 | $611M |
| tc_008 | Cream Finance | price_oracle_manipulation | critical | 2021-10 | $130M |
| tc_009 | KyberSwap Elastic | arithmetic_error | critical | 2023-11 | $48M |
| tc_010 | The DAO | reentrancy | critical | 2016-06 | $60M |
| tc_011 | Lendf.Me | reentrancy | high | 2020-04 | $25M |
| tc_012 | Rari Capital Fuse | reentrancy | critical | 2022-05 | $80M |
| tc_013 | PancakeHunny | arithmetic_error | critical | 2021-05 | $45M |
| tc_014 | Yearn Finance yDAI | price_oracle_manipulation | high | 2021-02 | $11M |
| tc_015 | Compound cTUSD | logic_error | medium | 2022-03 | $2M |
| tc_016 | bZx Protocol | reentrancy | high | 2020-09 | $8M |
| tc_017 | Pickle Finance | access_control | critical | 2020-11 | $20M |
| tc_018 | Indexed Finance | pool_manipulation | high | 2021-10 | $16M |
| tc_019 | Qubit Bridge | validation_bypass | critical | 2022-01 | $80M |
| tc_020 | Warp Finance | price_oracle_manipulation | high | 2020-12 | $8M |
| tc_021 | DODO | reinitialization | high | 2021-03 | $2M |
| tc_022 | Uranium Finance | arithmetic_error | critical | 2021-04 | $50M |
| tc_023 | Alpha Homora | accounting_manipulation | critical | 2021-02 | $37M |
| tc_024 | Inverse Finance | price_oracle_manipulation | critical | 2022-04 | $15M |
| tc_025 | Hundred Finance | reentrancy | critical | 2022-03 | $6M |
| tc_026 | Anyswap | signature_verification | critical | 2022-01 | $8M |
| tc_027 | BurgerSwap | input_validation | high | 2021-05 | $7M |
| tc_028 | BVaults SafeMoon | accounting_error | high | 2021-05 | $12M |
| tc_029 | Belt Finance | price_oracle_manipulation | critical | 2021-05 | $6M |
| tc_030 | Spartan Protocol | arithmetic_error | critical | 2021-05 | $30M |
| tc_031 | Orbit Chain | bridge_security | critical | 2024-01 | $82M |
| tc_032 | Radiant Capital | arithmetic_manipulation | high | 2024-01 | $4.5M |
| tc_033 | Socket Gateway | access_control | critical | 2024-01 | $3.3M |
| tc_034 | Gamma Strategies | price_manipulation | high | 2024-01 | $6M |
| tc_035 | Wise Lending | arithmetic_error | high | 2024-01 | $460K |
| tc_036 | Prisma Finance | access_control | critical | 2024-03 | $12M |
| tc_037 | UwU Lend | price_oracle_manipulation | critical | 2024-06 | $20M |
| tc_038 | Blueberry Protocol | price_oracle_manipulation | high | 2024-02 | $1.3M |
| tc_039 | CoW Protocol | access_control | high | 2024-11 | $166K |
| tc_040 | Bedrock DeFi | logic_error | critical | 2024-09 | $2M |
| tc_041 | Shezmu Protocol | access_control | critical | 2024-09 | $4.9M |
| tc_042 | Hedgey Finance | access_control | critical | 2024-04 | $44M |
| tc_043 | Seneca Protocol | access_control | critical | 2024-02 | $6M |
| tc_044 | DeltaPrime | access_control | critical | 2024-11 | $6M |
| tc_045 | Penpie | reentrancy | critical | 2024-09 | $27M |
| tc_046 | FixedFloat | access_control | critical | 2024-02 | $26M |
| tc_047 | PlayDapp | access_control | critical | 2024-02 | $290M |
| tc_048 | Sonne Finance | oracle_manipulation | critical | 2024-05 | $20M |
| tc_049 | Exactly Protocol | oracle_manipulation | critical | 2024-08 | $7M |
| tc_050 | Munchables | access_control | critical | 2024-03 | $62M |

---

## Transformation Pipeline

The dataset follows a hierarchical transformation pipeline:

```
                                    original
                                       │
                                       ▼
                              minimalsanitized
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
               sanitized          differential        trojan
                    │                  │                  │
                    ▼                  │                  │
               nocomments              │                  │
                    │                  │                  │
          ┌────────┴────────┐         │                  │
          ▼                 ▼         │                  │
    chameleon_medical  shapeshifter   │                  │
                                      │                  │
                                      ▼                  ▼
                              falseProphet        (decoy injection)
```

---

## Variant Descriptions

### Base Variants

| Variant | Directory | Purpose | Key Characteristics |
|---------|-----------|---------|---------------------|
| **original** | `original/` | Source of truth | Full vulnerability docs, protocol names, "Vulnerable" prefix |
| **minimalsanitized** | `minimalsanitized/` | Expert-reviewed base | Removed hint comments, kept code logic intact |
| **sanitized** | `sanitized/` | Protocol-agnostic | Protocol names replaced (Nomad→Bridge, Curve→Stable) |
| **nocomments** | `nocomments/` | Code-only evaluation | All comments stripped, pure code analysis |

### Transformation Variants

| Variant | Directory | Purpose | Key Characteristics |
|---------|-----------|---------|---------------------|
| **chameleon_medical** | `chameleon_medical/` | Domain shift | Medical terminology (patients, dosages, hospitals) |
| **shapeshifter_l3** | `shapeshifter_l3/` | Code obfuscation | L1 formatting + L2 hex identifiers + L3 control flow |
| **differential** | `differential/` | Fix recognition | Patched versions with `is_vulnerable: false` |
| **trojan** | `trojan/` | Decoy resistance | Distractor code (suspicious but safe elements) |
| **falseProphet** | `falseProphet/` | Misleading comments | Fake audit claims, false security attestations |

---

## Variant Details

### 1. Original (`original/`)
- **Files**: `tc_001.sol` - `tc_050.sol`
- **Use**: Source reference only (not for evaluation)
- **Contains**: Full vulnerability documentation, attack vectors, root causes

### 2. MinimalSanitized (`minimalsanitized/`)
- **Files**: `ms_tc_001.sol` - `ms_tc_050.sol`
- **Use**: Baseline evaluation (with protocol names)
- **Changes**: Removed "Vulnerable" prefix, hint comments, TODOs
- **Preserved**: Protocol names, code structure, line markers

### 3. Sanitized (`sanitized/`)
- **Files**: `sn_tc_001.sol` - `sn_tc_050.sol`
- **Use**: Protocol-agnostic evaluation
- **Changes**: Protocol names → generic names (e.g., NomadReplica → BridgeReplica)

### 4. NoComments (`nocomments/`)
- **Files**: `nc_tc_001.sol` - `nc_tc_050.sol`
- **Use**: Pure code analysis (no documentation hints)
- **Changes**: All comments stripped

### 5. Chameleon Medical (`chameleon_medical/`)
- **Files**: `cm_tc_001.sol` - `cm_tc_050.sol`
- **Use**: Domain transfer testing
- **Changes**: DeFi terminology → medical terminology
- **Example**: `deposit()` → `admitPatient()`, `withdraw()` → `dischargePatient()`

### 6. Shapeshifter L3 (`shapeshifter_l3/`)
- **Files**: `ss_tc_001.sol` - `ss_tc_050.sol`
- **Use**: Obfuscation resistance testing
- **Transformations**:
  - L1: Formatting normalization
  - L2: Identifiers → hex names (`deposit` → `_0x1a2b3c`)
  - L3: Control flow restructuring

### 7. Differential (`differential/`)
- **Files**: `df_tc_001.sol` - `df_tc_050.sol`
- **Use**: Fix recognition testing
- **Characteristic**: `is_vulnerable: false` in metadata
- **Contains**: Properly patched contracts

### 8. Trojan (`trojan/`)
- **Files**: `tr_tc_001.sol` - `tr_tc_050.sol`
- **Use**: Pattern matching vs causal understanding
- **Contains**: Distractor code that looks suspicious but is safe
- **Distractors**: Config tracking, suspicious names, fake functions

### 9. FalseProphet (`falseProphet/`)
- **Files**: `fp_tc_001.sol` - `fp_tc_050.sol`
- **Use**: Test model resistance to misleading comments
- **Contains**: Fake audit claims, false security attestations
- **Example**: `@dev Audited by Hacken (Q1 2021) - All findings resolved`

---

## Metadata Structure

Each variant includes JSON metadata with:

```json
{
  "sample_id": "xx_tc_001",
  "exploit_name": "Nomad Bridge",
  "vulnerability_type": "improper_initialization",
  "severity": "critical",
  "is_vulnerable": true,
  "vulnerable_contract": "BridgeReplica",
  "vulnerable_function": "process",
  "vulnerable_lines": [18, 53],
  "description": "...",
  "root_cause": "...",
  "attack_scenario": "...",
  "fix_description": "...",
  "variant_type": "sanitized",
  "transformation": { ... }
}
```

---

## Line Markers

All contracts use `/*LN-N*/` markers for stable line references:

```solidity
/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/
/*LN-4*/ contract BridgeReplica {
/*LN-5*/     bytes32 public acceptedRoot;
```

The `vulnerable_lines` field references these markers, not raw file line numbers.

---

## Evaluation Metrics

| Metric | Variants Used | What It Measures |
|--------|---------------|------------------|
| **Base Accuracy** | sanitized | Standard vulnerability detection |
| **Temporal Resistance** | minimalsanitized vs sanitized | Protocol recognition vs detection |
| **Domain Transfer** | chameleon_medical | Generalization across domains |
| **Obfuscation Resistance** | shapeshifter_l3 | Code understanding vs pattern matching |
| **Fix Recognition** | differential | Understanding of what makes code safe |
| **Decoy Resistance** | trojan | Distinguishing real vs fake vulnerabilities |
| **Comment Independence** | nocomments | Code analysis without documentation |
| **Misleading Resistance** | falseProphet | Resistance to false security claims |

---

## Code Act Annotations

For advanced causal understanding evaluation, the following variants support Code Act annotations:

| Variant | Annotation Type | Purpose |
|---------|-----------------|---------|
| **minimalsanitized** | Full Code Acts | Baseline ROOT_CAUSE identification |
| **differential** | Transitions | Track ROOT_CAUSE → BENIGN on fix |
| **trojan** | DECOY elements | Identify injected distractors |

See `support/codeact.md` for the complete annotation guide.

---

## Directory Structure

```
temporal_contamination/
├── README.md                    # This file
├── original/
│   ├── contracts/               # 50 original vulnerable contracts
│   ├── metadata/                # 50 JSON metadata files
│   └── README.md
├── minimalsanitized/
│   ├── contracts/               # ms_tc_001.sol - ms_tc_050.sol
│   ├── metadata/
│   └── README.md
├── sanitized/
│   ├── contracts/               # sn_tc_001.sol - sn_tc_050.sol
│   ├── metadata/
│   └── README.md
├── nocomments/
│   ├── contracts/               # nc_tc_001.sol - nc_tc_050.sol
│   ├── metadata/
│   └── README.md
├── chameleon_medical/
│   ├── contracts/               # cm_tc_001.sol - cm_tc_050.sol
│   ├── metadata/
│   └── README.md
├── shapeshifter_l3/
│   ├── contracts/               # ss_tc_001.sol - ss_tc_050.sol
│   ├── metadata/
│   └── README.md
├── differential/
│   ├── contracts/               # df_tc_001.sol - df_tc_050.sol
│   ├── metadata/
│   └── README.md
├── trojan/
│   ├── contracts/               # tr_tc_001.sol - tr_tc_050.sol
│   ├── metadata/
│   └── README.md
└── falseProphet/
    ├── contracts/               # fp_tc_001.sol - fp_tc_050.sol
    ├── metadata/
    └── README.md
```

---

## Usage

### Basic Evaluation
```bash
# Use sanitized variant for standard evaluation
python evaluate.py --dataset temporal_contamination/sanitized
```

### Comparative Analysis
```bash
# Compare model performance across variants
python compare.py \
  --baseline temporal_contamination/sanitized \
  --variants temporal_contamination/shapeshifter_l3 \
            temporal_contamination/chameleon_medical \
            temporal_contamination/trojan
```

### Differential Testing
```bash
# Test fix recognition
python differential_test.py \
  --vulnerable temporal_contamination/minimalsanitized \
  --fixed temporal_contamination/differential
```

---

## Citation

If you use this dataset, please cite:

```bibtex
@dataset{blockbench_tc_2025,
  title={BlockBench Temporal Contamination Dataset},
  author={BlockBench Team},
  year={2025},
  version={1.0}
}
```

---

## License

This dataset is provided for research purposes only. The contracts are based on real exploits and should not be deployed on any network.
