# BlockBench Dataset - Detailed Overview

This document provides a comprehensive overview of the BlockBench smart contract vulnerability dataset, including structure, statistics, transformation strategies, and evaluation methodologies.

---

## Table of Contents

1. [Dataset Summary](#dataset-summary)
2. [Dataset Structure](#dataset-structure)
3. [Difficulty-Stratified Dataset (DS)](#difficulty-stratified-dataset-ds)
4. [Temporal Contamination Dataset (TC)](#temporal-contamination-dataset-tc)
5. [Gold Standard Dataset (GS)](#gold-standard-dataset-gs)
6. [CodeAct Taxonomy](#codeact-taxonomy)
7. [Knowledge Assessment System](#knowledge-assessment-system)
8. [Evaluation Framework](#evaluation-framework)

---

## Dataset Summary

| Dataset                         | Samples          | Purpose                           | Sources                                                 |
| ------------------------------- | ---------------- | --------------------------------- | ------------------------------------------------------- |
| **Difficulty-Stratified (DS)**  | 210              | Tiered difficulty evaluation      | SmartBugs-Curated, DeFiVulnLabs, Not-So-Smart-Contracts |
| **Temporal Contamination (TC)** | 46 (x5 variants) | Memorization vs reasoning testing | Real-world exploits (2016-2024)                         |
| **Gold Standard (GS)**          | 34               | Post-cutoff evaluation            | Code4rena, Spearbit, MixBytes audits (2025)             |

**Total Unique Contracts**: 290
**Total with Variants**: 520+
**Total Value at Risk (TC)**: >\$1.65 billion USD

---

## Dataset Structure

Each dataset follows a consistent directory structure:

```
dataset/
├── difficulty_stratified/
│   ├── original/           # With vulnerability hints
│   │   ├── tier1/ ... tier4/
│   │   │   ├── contracts/  # .sol files
│   │   │   ├── metadata/   # .json files
│   │   │   └── index.json
│   └── cleaned/            # Hints removed (for evaluation)
│
├── temporal_contamination/
│   ├── original/           # Source of truth
│   ├── minimalsanitized/   # Expert-reviewed base
│   │   ├── contracts/
│   │   ├── metadata/
│   │   ├── knowledge_assessment/
│   │   └── code_acts_annotation/
│   ├── differential/       # Fixed versions
│   ├── trojan/             # Decoy-injected
│   ├── falseProphet/       # Misleading comments
│   └── ... (other variants)
│
└── gold_standard/
    ├── original/           # Full audit documentation
    └── cleaned/            # Sanitized for evaluation
        ├── contracts/
        ├── metadata/
        ├── knowledge_assessment/
        ├── protocol_context_doc/
        └── context/        # Multi-file dependencies
```

### Common File Types

| File Type          | Extension                | Description                                       |
| ------------------ | ------------------------ | ------------------------------------------------- |
| Contract           | `.sol`                   | Solidity smart contract code                      |
| Metadata           | `.json`                  | Vulnerability details, line numbers, descriptions |
| Knowledge Probe    | `*_knowledge_probe.json` | Pre-evaluation knowledge assessment               |
| CodeAct Annotation | `.yaml`                  | Line-level security function annotations          |
| Protocol Context   | `*_context.txt`          | High-level protocol description                   |

---

## Difficulty-Stratified Dataset (DS)

### Overview

The DS dataset stratifies 210 vulnerable smart contracts into four difficulty tiers based on detection complexity.

### Tier Distribution

| Tier       | Level  | Count | Description                                                |
| ---------- | ------ | ----- | ---------------------------------------------------------- |
| **Tier 1** | Easy   | 86    | Basic vulnerabilities with clear patterns                  |
| **Tier 2** | Medium | 81    | Moderate complexity requiring contract flow understanding  |
| **Tier 3** | Hard   | 30    | Complex vulnerabilities involving subtle logic             |
| **Tier 4** | Expert | 13    | Advanced vulnerabilities requiring deep protocol knowledge |

### Tier Assignment Criteria

Tiers were assigned using heuristics and human expert review:

| Factor               | Easier (T1-T2)                   | Harder (T3-T4)               |
| -------------------- | -------------------------------- | ---------------------------- |
| **Pattern Clarity**  | Single function, obvious pattern | Cross-function, subtle logic |
| **Domain Knowledge** | General Solidity                 | DeFi-specific expertise      |
| **Analysis Type**    | Basic static analysis            | Multi-contract reasoning     |
| **Code Complexity**  | Few functions/modifiers          | Complex interactions         |

### Source Distribution

| Source                 | Count | Percentage |
| ---------------------- | ----- | ---------- |
| SmartBugs-Curated      | 142   | 67.6%      |
| DeFiVulnLabs           | 47    | 22.4%      |
| Not-So-Smart-Contracts | 21    | 10.0%      |

### Vulnerability Types by Tier

#### Tier 1 (86 samples)

| Vulnerability Type | Count |
| ------------------ | ----- |
| unchecked_return   | 41    |
| reentrancy         | 31    |
| access_control     | 11    |
| weak_randomness    | 1     |
| integer_issues     | 1     |
| interface_mismatch | 1     |

#### Tier 2 (81 samples)

| Vulnerability Type   | Count |
| -------------------- | ----- |
| integer_issues       | 16    |
| logic_error          | 12    |
| access_control       | 9     |
| dos                  | 9     |
| unchecked_return     | 7     |
| weak_randomness      | 6     |
| timestamp_dependency | 5     |
| front_running        | 4     |
| reentrancy           | 3     |
| oracle_manipulation  | 2     |
| Other (9 types)      | 8     |

#### Tier 3 (30 samples)

| Vulnerability Type | Count |
| ------------------ | ----- |
| logic_error        | 7     |
| honeypot           | 5     |
| unchecked_return   | 5     |
| access_control     | 2     |
| reentrancy         | 2     |
| unchecked_call     | 2     |
| Other (7 types)    | 7     |

#### Tier 4 (13 samples)

| Vulnerability Type  | Count |
| ------------------- | ----- |
| weak_randomness     | 2     |
| storage_collision   | 2     |
| signature_replay    | 2     |
| reentrancy          | 2     |
| integer_issues      | 2     |
| inflation_attack    | 1     |
| oracle_manipulation | 1     |
| flash_loan_attack   | 1     |

### Variants

| Variant      | Description              | Use Case            |
| ------------ | ------------------------ | ------------------- |
| **original** | Full vulnerability hints | Reference/training  |
| **cleaned**  | Hints removed            | Unbiased evaluation |

---

## Temporal Contamination Dataset (TC)

### Overview

The TC dataset contains 46 real-world DeFi exploits designed to test whether models are memorizing known vulnerabilities or genuinely reasoning about code.

### Exploit Summary

**Date Range**: 2016 (The DAO) - 2024 (Recent exploits)
**Total Value Lost**: >\$1.65 billion USD (documented)
**Vulnerability Types**: 18 categories

### Complete Exploit List

| ID      | Exploit               | Date       | Amount Lost | Vulnerability Type        |
| ------- | --------------------- | ---------- | ----------- | ------------------------- |
| tc_001  | Nomad Bridge          | 2022-08-01 | \$190M      | improper_initialization   |
| tc_002  | Beanstalk             | 2022-04-17 | \$182M      | governance_attack         |
| tc_003  | Parity Wallet         | 2017-11-06 | \$150M      | access_control            |
| tc_004  | Harvest Finance       | 2020-10-26 | \$34M       | price_oracle_manipulation |
| tc_005  | Curve Finance (Vyper) | 2023-07-30 | \$70M       | reentrancy                |
| tc_006  | Ronin Bridge          | 2022-03-29 | \$625M      | access_control            |
| tc_007  | Poly Network          | 2021-08-10 | \$611M      | access_control            |
| tc_008  | The DAO               | 2016-06-17 | \$60M       | reentrancy                |
| tc_009  | Lendf.Me              | 2020-04-19 | \$25M       | reentrancy                |
| tc_010  | Rari Capital Fuse     | 2022-05-08 | \$80M       | reentrancy                |
| tc_011  | PancakeHunny          | 2021-05-20 | \$45M       | arithmetic_error          |
| tc_012  | Compound cTUSD        | 2022-03-15 | -           | logic_error               |
| tc_013  | bZx Protocol          | 2020-09-14 | \$8M        | reentrancy                |
| tc_014  | Pickle Finance        | 2020-11-21 | \$20M       | access_control            |
| tc_015  | Indexed Finance       | 2021-10-14 | \$16M       | pool_manipulation         |
| tc_016  | Qubit Bridge          | 2022-01-27 | \$80M       | validation_bypass         |
| tc_017  | Warp Finance          | 2020-12-17 | \$7.7M      | price_oracle_manipulation |
| tc_018  | DODO                  | 2021-03-09 | \$3.8M      | reinitialization          |
| tc_019  | Uranium Finance       | 2021-04-28 | \$50M       | arithmetic_error          |
| tc_020  | Alpha Homora          | 2021-02-13 | \$37M       | accounting_manipulation   |
| tc_021  | Inverse Finance       | 2022-04-02 | \$15.6M     | price_oracle_manipulation |
| tc_022  | Hundred Finance       | 2022-03-15 | \$6M        | reentrancy                |
| tc_023  | Anyswap               | 2022-01-18 | \$8M        | signature_verification    |
| tc_024  | BurgerSwap            | 2021-05-28 | \$7M        | input_validation          |
| tc_025  | BVaults SafeMoon      | 2021-05-30 | \$8.5M      | accounting_error          |
| tc_026  | Belt Finance          | 2021-05-30 | \$6.2M      | price_oracle_manipulation |
| tc_027  | Spartan Protocol      | 2021-05-02 | \$30M       | arithmetic_error          |
| tc_028  | Cream Finance         | 2021-10-27 | \$130M      | price_oracle_manipulation |
| tc_029  | KyberSwap Elastic     | 2023-11-22 | \$47M       | arithmetic_error          |
| tc_030+ | Various 2024 exploits | 2024       | Various     | Various                   |

### Vulnerability Type Distribution

| Vulnerability Type        | Count | Percentage |
| ------------------------- | ----- | ---------- |
| access_control            | 12    | 26.1%      |
| reentrancy                | 7     | 15.2%      |
| price_oracle_manipulation | 6     | 13.0%      |
| arithmetic_error          | 5     | 10.9%      |
| oracle_manipulation       | 2     | 4.3%       |
| logic_error               | 2     | 4.3%       |
| Other (12 types)          | 12    | 26.1%      |

### Transformation Variants

The TC dataset includes multiple transformation variants, each testing different aspects of model capability:

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
                │                                     │
                ▼                                     ▼
           nocomments                          falseProphet
                │
       ┌────────┴────────┐
       ▼                 ▼
 chameleon_medical  shapeshifter_l3
```

#### Variant Descriptions

| Variant               | Prefix   | Files | Purpose                 | What It Tests                 |
| --------------------- | -------- | ----- | ----------------------- | ----------------------------- |
| **original**          | `tc_`    | 46    | Source of truth         | Reference only                |
| **minimalsanitized**  | `ms_tc_` | 46    | Expert-reviewed base    | Baseline with protocol names  |
| **sanitized**         | `sn_tc_` | 46    | Protocol names removed  | Protocol-agnostic detection   |
| **nocomments**        | `nc_tc_` | 46    | All comments stripped   | Pure code analysis            |
| **differential**      | `df_tc_` | 46    | Fixed/patched versions  | Fix recognition ability       |
| **trojan**            | `tr_tc_` | 46    | Decoy code injected     | Pattern matching vs reasoning |
| **falseProphet**      | `fp_tc_` | 46    | Fake audit claims added | Resistance to misleading info |
| **chameleon_medical** | `cm_tc_` | 46    | Medical terminology     | Domain transfer capability    |
| **shapeshifter_l3**   | `ss_tc_` | 46    | Obfuscated identifiers  | Obfuscation resistance        |

#### Transformation Strategy Details

| Strategy                  | Description                               | Example                              |
| ------------------------- | ----------------------------------------- | ------------------------------------ |
| **Minimal Sanitization**  | Remove "Vulnerable" prefix, hint comments | `VulnerableBank` → `Bank`            |
| **Protocol Sanitization** | Replace protocol names                    | `NomadReplica` → `BridgeReplica`     |
| **Comment Stripping**     | Remove all comments                       | `// Vulnerable to X` → (removed)     |
| **Differential**          | Apply security fix                        | State update after external call     |
| **Trojan Injection**      | Add suspicious-looking but safe code      | Decoy functions, misleading names    |
| **False Prophet**         | Add fake security attestations            | `@dev Audited by Hacken - All clear` |
| **Chameleon**             | Domain terminology shift                  | `deposit()` → `admitPatient()`       |
| **Shapeshifter**          | Identifier obfuscation                    | `deposit` → `_0x1a2b3c`              |

#### What Each Variant Measures

| Variant Pair   | Comparison                     | Insight                                   |
| -------------- | ------------------------------ | ----------------------------------------- |
| ms_tc vs sn_tc | With vs without protocol names | Temporal recognition vs detection         |
| ms_tc vs nc_tc | With vs without comments       | Comment dependence                        |
| ms_tc vs df_tc | Vulnerable vs fixed            | Fix recognition                           |
| ms_tc vs tr_tc | Original vs decoy-injected     | Pattern matching vs causal understanding  |
| sn_tc vs cm_tc | DeFi vs medical domain         | Domain generalization                     |
| sn_tc vs ss_tc | Normal vs obfuscated           | Surface pattern vs semantic understanding |

---

## Gold Standard Dataset (GS)

### Overview

The GS dataset contains 34 high-quality audit findings from professional security audits conducted in **2025** (post model training cutoff). This ensures zero temporal contamination.

### Source Distribution

| Audit Firm | Count | Percentage |
| ---------- | ----- | ---------- |
| Code4rena  | 19    | 55.9%      |
| Spearbit   | 8     | 23.5%      |
| MixBytes   | 7     | 20.6%      |

### Vulnerability Type Distribution

| Vulnerability Type  | Count |
| ------------------- | ----- |
| logic_error         | 18    |
| signature_replay    | 3     |
| dos                 | 3     |
| access_control      | 3     |
| front_running       | 2     |
| flash_loan          | 2     |
| oracle_manipulation | 1     |
| unchecked_return    | 1     |
| input_validation    | 1     |

### Severity Distribution

| Severity | Count |
| -------- | ----- |
| High     | 10    |
| Medium   | 24    |

### Complete Finding List

| ID     | Finding                                    | Date       | Severity | Source                    |
| ------ | ------------------------------------------ | ---------- | -------- | ------------------------- |
| gs_001 | Assets deposited before calculating shares | 2025-10-06 | high     | Code4rena - Hybra Finance |
| gs_002 | CLFactory ignores dynamic fees above 10%   | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_003 | Emergency withdraw loses accrued rewards   | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_004 | First depositor attack                     | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_005 | Dust vote prevents poke()                  | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_006 | Rollover rewards permanently lost          | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_007 | ClaimFees steals staking rewards           | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_008 | Claiming rewards always reverts            | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_009 | Incorrect voting power calculation         | 2025-10-06 | medium   | Code4rena - Hybra Finance |
| gs_010 | MinVotingPowerCondition flashloan bypass   | 2025-09-11 | high     | Spearbit - Aragon         |
| gs_011 | EarlyExecution flashloan vulnerability     | 2025-09-11 | high     | Spearbit - Aragon         |
| gs_012 | Lack of SafeERC20 inflates balance         | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_013 | Lock fails for unlimited approvals         | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_014 | Misuse of isProposalOpen()                 | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_015 | Proposal targets voting contract           | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_016 | Idle balance gaming in isGranted           | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_017 | currentTokenSupply() manipulation          | 2025-09-11 | medium   | Spearbit - Aragon         |
| gs_018 | rejectRequest() adverse consequences       | 2025-10-23 | high     | MixBytes - Gearbox        |
| gs_019 | withdrawPhantomToken unexpected underlying | 2025-10-23 | medium   | MixBytes - Gearbox        |
| gs_020 | Missing domain separator in digest         | 2025-10-01 | medium   | Spearbit - Kyber          |
| gs_021 | Quote frontrunning via router replay       | 2025-10-01 | medium   | Spearbit - Kyber          |
| gs_022 | Manager deactivation breaks allocation     | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_023 | Inactive managers under-report funds       | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_024 | unstakeRequestWithPermit frontrunning      | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_025 | Emergency admin can transfer aWETH         | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_026 | Missing oracle freshness check             | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_027 | Fixed exchange rate fails to socialize     | 2025-10-22 | medium   | MixBytes - Mantle         |
| gs_028 | Chained signature checkpoint bypass        | 2025-10-07 | high     | Code4rena - Sequence      |
| gs_029 | Partial signature replay attack            | 2025-10-07 | high     | Code4rena - Sequence      |
| gs_030 | Session signature cross-wallet replay      | 2025-10-07 | medium   | Code4rena - Sequence      |
| gs_031 | Static signatures revert under ERC-4337    | 2025-10-07 | medium   | Code4rena - Sequence      |
| gs_032 | recoverSapientSignature returns constant   | 2025-10-07 | medium   | Code4rena - Sequence      |
| gs_033 | Factory deploy reverts on existing address | 2025-10-07 | medium   | Code4rena - Sequence      |
| gs_034 | Unclaimed fees inaccessible after unlock   | 2025-09-12 | medium   | MixBytes - Velodrome      |

### Variants

| Variant      | Description                                         |
| ------------ | --------------------------------------------------- |
| **original** | Full audit documentation with vulnerability markers |
| **cleaned**  | Sanitized for evaluation (markers removed)          |

### Additional Resources

| Resource           | Location                        | Description                              |
| ------------------ | ------------------------------- | ---------------------------------------- |
| Protocol Context   | `cleaned/protocol_context_doc/` | High-level protocol descriptions         |
| Knowledge Probes   | `cleaned/knowledge_assessment/` | Pre-evaluation knowledge tests           |
| Multi-file Context | `cleaned/context/`              | Supporting contracts for complex samples |

---

## CodeAct Taxonomy

### Overview

CodeAct (Code Act) is a taxonomy for classifying security-relevant code operations in smart contracts. It enables fine-grained evaluation of whether models understand **why** code is vulnerable, not just **that** it is vulnerable.

The term draws from Speech Act Theory in linguistics, where utterances are classified by function. Similarly, CodeActs classify code segments by their security-relevant function.

### Why CodeActs?

Standard metrics measure **what** models detect but not **why**:

```
Model A: "The external call at line 45 occurs before the state update
         at line 48, allowing recursive calls to drain funds."

Model B: "This contract has a reentrancy vulnerability because it
         uses an external call."
```

Both achieve the same accuracy. But Model A demonstrates **causal understanding** while Model B shows **pattern recognition**.

### CodeAct Types (22 Total)

#### Security-Relevant Operations (Types 1-17)

| #   | Code Act           | Abbrev                 | Description                         | Security Relevance                                   |
| --- | ------------------ | ---------------------- | ----------------------------------- | ---------------------------------------------------- |
| 1   | **EXT_CALL**       | External Call          | Call to external contract           | Reentrancy trigger, control flow to untrusted code   |
| 2   | **STATE_MOD**      | State Modification     | Write to storage variable           | Order relative to EXT_CALL determines exploitability |
| 3   | **ACCESS_CTRL**    | Access Control         | Permission/authorization check      | Missing = top vulnerability class                    |
| 4   | **ARITHMETIC**     | Arithmetic Operation   | Math that could overflow/underflow  | Overflow, precision loss, division by zero           |
| 5   | **INPUT_VAL**      | Input Validation       | Validation of input parameters      | Missing enables various attacks                      |
| 6   | **CTRL_FLOW**      | Control Flow Logic     | Conditionals and loops              | Logic errors, incorrect conditions                   |
| 7   | **FUND_XFER**      | Fund Transfer          | Movement of ETH/tokens              | Direct financial impact                              |
| 8   | **DELEGATE**       | Delegate Call          | delegatecall execution              | External code can modify all storage                 |
| 9   | **TIMESTAMP**      | Timestamp Dependency   | Use of block.timestamp              | Miner manipulation (~15s window)                     |
| 10  | **RANDOM**         | Randomness Source      | On-chain random generation          | Predictable/manipulable                              |
| 11  | **ORACLE**         | Oracle Interaction     | External price feed query           | Price manipulation, stale data                       |
| 12  | **REENTRY_GUARD**  | Reentrancy Protection  | Mutex lock pattern                  | Check if correctly implemented                       |
| 13  | **STORAGE_READ**   | Storage Read           | Reading from storage                | Order relative to STATE_MOD matters                  |
| 14  | **SIGNATURE**      | Signature Verification | Cryptographic validation            | Replay, malleability, missing validation             |
| 15  | **INITIALIZATION** | State Initialization   | Initial assignment of critical vars | Uninitialized, reinitialization attacks              |
| 16  | **COMPUTATION**    | Hash/Encode Operations | Hashing, ABI encoding               | Generally benign, data flow tracking                 |
| 17  | **EVENT_EMIT**     | Event Emission         | Emitting events                     | No direct security impact (logs only)                |

#### Structural Elements (Types 18-22)

| #   | Code Act        | Abbrev              | Description                | Security Relevance              |
| --- | --------------- | ------------------- | -------------------------- | ------------------------------- |
| 18  | **COMMENT**     | Documentation       | NatSpec, inline comments   | None (may reveal intent)        |
| 19  | **DIRECTIVE**   | Compiler Directives | Pragma, imports            | Pragma version affects behavior |
| 20  | **DECLARATION** | Type Declarations   | State vars, structs, enums | Missing initialization          |
| 21  | **EVENT_DEF**   | Event Definition    | Event declarations         | None                            |
| 22  | **SYNTAX**      | Structural Tokens   | Closing braces, etc.       | None                            |

### Security Functions

Each CodeAct plays a specific role in the context of a vulnerability:

| Security Function  | Symbol | Definition                             | Evaluation Impact                   |
| ------------------ | ------ | -------------------------------------- | ----------------------------------- |
| **ROOT_CAUSE**     | 🔴     | Directly enables exploitation          | Target found (correct)              |
| **SECONDARY_VULN** | 🟣     | Real vulnerability, not documented one | Bonus finding                       |
| **PREREQ**         | 🟡     | Necessary for exploit but not cause    | Partial credit                      |
| **INSUFF_GUARD**   | 🟠     | Failed protection attempt              | Correct if explained                |
| **DECOY**          | 🔵     | Looks suspicious but safe              | Wrong if flagged (pattern matching) |
| **BENIGN**         | 🟢     | Correctly implemented, safe            | Wrong if flagged                    |
| **UNRELATED**      | ⚪     | Not security-relevant                  | Wrong if flagged                    |

### Security Function Decision Tree

```
Is this Code Act security-relevant?
│
├── No → UNRELATED
│
└── Yes → Is it a real vulnerability?
    │
    ├── Yes → Is it the DOCUMENTED vulnerability?
    │   │
    │   ├── Yes → ROOT_CAUSE
    │   │
    │   └── No → SECONDARY_VULN
    │
    └── No → Is it necessary for the documented exploit to work?
        │
        ├── Yes → PREREQ
        │
        └── No → Was it intended as a protection?
            │
            ├── Yes (but fails) → INSUFF_GUARD
            │
            └── No → Does it LOOK vulnerable but is actually safe?
                │
                ├── Yes → DECOY
                │
                └── No → BENIGN
```

### Common Vulnerability Patterns

#### Reentrancy Pattern

```
STORAGE_READ (balance)     → PREREQ
EXT_CALL (transfer)        → ROOT_CAUSE (before state update)
STATE_MOD (balance = 0)    → ROOT_CAUSE (after external call)
```

#### Access Control Pattern

```
ACCESS_CTRL (missing)      → ROOT_CAUSE
FUND_XFER (drain)          → PREREQ
```

#### Oracle Manipulation Pattern

```
ORACLE (spot price)        → ROOT_CAUSE
ARITHMETIC (calculate)     → PREREQ
FUND_XFER (profit)         → PREREQ
```

### CodeAct Annotation File Format

```yaml
sample_id: ms_tc_001
variant: minimalsanitized
schema_version: '1.0'

vulnerable_lines: [18, 53]

code_acts:
  - line: 18
    code_act: INITIALIZATION
    security_function: ROOT_CAUSE
    observation: 'acceptedRoot initialized to bytes32(0)'

  - line: 53
    code_act: INPUT_VAL
    security_function: ROOT_CAUSE
    observation: 'messages[_messageHash] == bytes32(0) passes for any hash'
```

---

## Knowledge Assessment System

### Purpose

Knowledge assessment probes detect whether a model has prior knowledge of vulnerabilities **before** showing any code. This distinguishes:

- **Memorization**: Model recalls exploit from training data
- **Reasoning**: Model actually analyzes code to find vulnerabilities

### Probe Structure

```json
{
  "sample_id": "ms_tc_001",
  "assessment_type": "knowledge_probe",
  "prompt": "Do you have any knowledge of a DeFi exploit called 'Nomad Bridge'...",
  "expected_answers": {
    "exploit_name": "Nomad Bridge",
    "date": "2022-08-01",
    "amount_lost_usd": "190000000",
    "vulnerability_type": "improper_initialization",
    "temporal_category": "pre_cutoff"
  }
}
```

### Scoring Matrix

| Temporal Category | Model Response     | Score                   | Interpretation                        |
| ----------------- | ------------------ | ----------------------- | ------------------------------------- |
| `pre_cutoff`      | Familiar + Correct | `familiar_correct`      | Expected                              |
| `pre_cutoff`      | Unfamiliar         | `unfamiliar_surprising` | Model doesn't know well-known exploit |
| `post_cutoff`     | Unfamiliar         | `unfamiliar_honest`     | Expected                              |
| `post_cutoff`     | Familiar + Correct | `contaminated`          | **Training data contamination**       |
| Any               | Familiar + Wrong   | `hallucination`         | Model is guessing                     |

### Interpretation Matrix

```
                    │ Finds Vulnerability │ Misses Vulnerability
────────────────────┼─────────────────────┼──────────────────────
Knew the exploit    │ Possibly memorized  │ Weak despite knowledge
────────────────────┼─────────────────────┼──────────────────────
Didn't know exploit │ STRONG SIGNAL ✓     │ Expected difficulty
                    │ (actual reasoning)  │
```

### Coverage

| Dataset                | Probes | Temporal Category       |
| ---------------------- | ------ | ----------------------- |
| Temporal Contamination | 46     | Mixed (pre/post cutoff) |
| Gold Standard          | 34     | All post_cutoff (2025)  |

---

## Evaluation Framework

### Multi-Level Evaluation

```
Level 1: Binary Detection
├── Does the model detect a vulnerability? (Yes/No)
│
Level 2: Classification Accuracy
├── Does it correctly identify the vulnerability type?
│
Level 3: Localization
├── Does it identify the correct lines/functions?
│
Level 4: Causal Understanding (CodeAct)
└── Does it understand WHY the code is vulnerable?
    ├── Correct ROOT_CAUSE identification
    ├── Correct PREREQ identification
    └── No false positives on DECOY/BENIGN
```

### Cross-Variant Analysis

For Temporal Contamination, compare model performance across variants:

| Comparison     | Insight                                          |
| -------------- | ------------------------------------------------ |
| ms_tc vs df_tc | Can model recognize fixes?                       |
| ms_tc vs tr_tc | Does model detect real vs decoy vulnerabilities? |
| sn_tc vs cm_tc | Does detection generalize across domains?        |
| sn_tc vs ss_tc | Is detection robust to obfuscation?              |

### Memorization vs Understanding (TC Dataset)

Using differential and trojan variants:

| Scenario                 | Memorizing Model             | Understanding Model        |
| ------------------------ | ---------------------------- | -------------------------- |
| **Differential (fixed)** | Reports vulnerable (wrong)   | Reports safe (correct)     |
| **Trojan (new bug)**     | Reports original bug (wrong) | Finds trojan bug (correct) |

### Metrics

| Metric                   | Formula                                     | Description                         |
| ------------------------ | ------------------------------------------- | ----------------------------------- |
| **Detection Rate**       | TP / (TP + FN)                              | How often vulnerabilities are found |
| **Precision**            | TP / (TP + FP)                              | How often detections are correct    |
| **Line-Level Accuracy**  | Correct lines / Total lines flagged         | Localization precision              |
| **ROOT_CAUSE Precision** | Correct ROOT_CAUSE / All ROOT_CAUSE flagged | Causal understanding                |
| **Decoy Resistance**     | 1 - (DECOY flagged / Total DECOY)           | Pattern matching detection          |
| **Fix Recognition**      | Correct on df_tc / Total df_tc              | Understanding of fixes              |

---

## File Naming Conventions

| Dataset               | Pattern     | Example         |
| --------------------- | ----------- | --------------- |
| Difficulty-Stratified | `ds_tN_XXX` | `ds_t1_001.sol` |
| TC Original           | `tc_XXX`    | `tc_001.sol`    |
| TC MinimalSanitized   | `ms_tc_XXX` | `ms_tc_001.sol` |
| TC Sanitized          | `sn_tc_XXX` | `sn_tc_001.sol` |
| TC NoComments         | `nc_tc_XXX` | `nc_tc_001.sol` |
| TC Differential       | `df_tc_XXX` | `df_tc_001.sol` |
| TC Trojan             | `tr_tc_XXX` | `tr_tc_001.sol` |
| TC FalseProphet       | `fp_tc_XXX` | `fp_tc_001.sol` |
| TC Chameleon          | `cm_tc_XXX` | `cm_tc_001.sol` |
| TC Shapeshifter       | `ss_tc_XXX` | `ss_tc_001.sol` |
| Gold Standard         | `gs_XXX`    | `gs_001.sol`    |

---

## Quick Reference

### Total Counts

| Category                | Count |
| ----------------------- | ----- |
| DS Contracts (original) | 210   |
| DS Contracts (cleaned)  | 210   |
| TC Exploits             | 46    |
| TC Variants             | 9     |
| TC Total Files          | 414   |
| GS Findings             | 34    |
| GS Variants             | 2     |
| GS Total Files          | 68    |
| Knowledge Probes        | 80    |
| CodeAct Types           | 22    |
| Security Functions      | 7     |

### Key Directories

| Purpose             | Path                                                                    |
| ------------------- | ----------------------------------------------------------------------- |
| DS Evaluation       | `dataset/difficulty_stratified/cleaned/`                                |
| TC Baseline         | `dataset/temporal_contamination/minimalsanitized/`                      |
| TC Fixed            | `dataset/temporal_contamination/differential/`                          |
| TC Decoy            | `dataset/temporal_contamination/trojan/`                                |
| GS Evaluation       | `dataset/gold_standard/cleaned/`                                        |
| CodeAct Taxonomy    | `dataset/codeact_taxonomy.md`                                           |
| TC Knowledge Probes | `dataset/temporal_contamination/minimalsanitized/knowledge_assessment/` |
| GS Knowledge Probes | `dataset/gold_standard/cleaned/knowledge_assessment/`                   |

---

## Citation

```bibtex
@dataset{blockbench_2025,
  title={BlockBench: A Comprehensive Smart Contract Vulnerability Dataset},
  author={BlockBench Team},
  year={2025},
  version={1.0}
}
```

---

## License

This dataset aggregates contracts from multiple sources:

- SmartBugs-Curated: MIT License
- DeFiVulnLabs: MIT License
- Not-So-Smart-Contracts: Apache 2.0
- Real-world exploits: For research purposes only
- Audit findings: Publicly disclosed findings from respective audit firms
