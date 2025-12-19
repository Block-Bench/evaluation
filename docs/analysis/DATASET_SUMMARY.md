# BlockBench Evaluation Dataset Summary

Comprehensive breakdown of the evaluation dataset used for vulnerability detection benchmarking.

**Generated**: 2025-12-18
**Total Samples**: 58
**Total Evaluations**: 68 (includes 5 GS samples with 3 prompt types each)

---

## Overview

| Metric | Count |
|--------|-------|
| **Total Samples** | 58 |
| **Total Evaluations** | 68 |
| **Base Vulnerabilities** | 22 unique |
| **Subsets** | 3 (TC, GS, DS) |
| **Transformation Types** | 6 |
| **Prompt Types** | 3 (direct, naturalistic, adversarial) |

---

## Dataset Composition by Subset

### 1. Temporal Contamination (TC) - 20 samples
**Purpose**: Test model robustness to code transformations
- **Base Vulnerabilities**: 5 unique
- **Samples per Base**: 4 transformations each
- **Focus**: How transformations affect detection

| Base ID | Transformation Types | Count |
|---------|---------------------|-------|
| tc_001 | sanitized, chameleon_medical, nocomments_original, shapeshifter_l3_medium | 4 |
| tc_002 | sanitized, chameleon_medical, nocomments_original, shapeshifter_l3_medium | 4 |
| tc_003 | sanitized, chameleon_medical, nocomments_original, shapeshifter_l3_medium | 4 |
| tc_004 | sanitized, chameleon_medical, nocomments_original, shapeshifter_l3_medium | 4 |
| tc_005 | sanitized, chameleon_medical, nocomments_original, shapeshifter_l3_medium | 4 |

**Transformations Used**:
- `sanitized` (5): Variable names neutralized, comments removed
- `chameleon_medical` (5): Domain shifted to medical/healthcare
- `nocomments_original` (5): Original code with comments removed
- `shapeshifter_l3_medium` (5): Code structure transformed

---

### 2. GPTShield (GS) - 10 samples
**Purpose**: Real-world audit findings from professional security audits
- **Base Vulnerabilities**: 10 unique (all different)
- **Samples per Base**: 1 sanitized variant each
- **Focus**: Professionally identified vulnerabilities

| Base ID | Prompt Types | Total Evaluations |
|---------|-------------|-------------------|
| gs_002 | direct, naturalistic, adversarial | 3 |
| gs_013 | direct, naturalistic, adversarial | 3 |
| gs_017 | direct, naturalistic, adversarial | 3 |
| gs_020 | direct, naturalistic, adversarial | 3 |
| gs_026 | direct, naturalistic, adversarial | 3 |
| gs_001 | direct | 1 |
| gs_005 | direct | 1 |
| gs_009 | direct | 1 |
| gs_025 | direct | 1 |
| gs_029 | direct | 1 |

**Note**: 5 GS samples (002, 013, 017, 020, 026) were evaluated with 3 prompt types each for prompt strategy comparison.

**Transformations Used**:
- `sanitized` (10): All GS samples use sanitized transformation

---

### 3. Difficulty Stratified (DiverseVul/DS) - 28 samples
**Purpose**: Real-world vulnerabilities from diverse sources
- **Base Vulnerabilities**: 7 unique
- **Samples per Base**: 4 transformations each
- **Focus**: Complex transformations on diverse vulnerability types

| Base ID | Transformation Types | Count |
|---------|---------------------|-------|
| ds_002 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_120 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_157 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_159 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_207 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_232 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |
| ds_234 | nocomments, chameleon_medical, hydra_restructure, shapeshifter_l3_medium | 4 |

**Transformations Used**:
- `nocomments` (7): Comments removed, semantics preserved
- `chameleon_medical` (7): Medical domain transformation
- `hydra_restructure` (7): Code reorganized and refactored
- `shapeshifter_l3_medium` (7): Structural transformation

---

## Transformation Type Distribution

| Transformation | Count | Description | Used In |
|---------------|-------|-------------|---------|
| **sanitized** | 15 | Variable names neutralized, comments removed | TC (5), GS (10) |
| **chameleon_medical** | 12 | Domain shifted to medical/healthcare context | TC (5), DS (7) |
| **shapeshifter_l3_medium** | 12 | Code structure transformed while preserving logic | TC (5), DS (7) |
| **hydra_restructure** | 7 | Code reorganized and refactored | DS (7) |
| **nocomments** | 7 | Comments removed but semantics preserved | DS (7) |
| **nocomments_original** | 5 | Original TC code with comments removed | TC (5) |

### Transformation Purpose

- **Sanitized**: Tests reliance on semantic cues (variable names, comments)
- **Chameleon Medical**: Tests cross-domain understanding (DeFi → Healthcare)
- **Shapeshifter**: Tests structural robustness (code reorganization)
- **Hydra**: Tests deep code comprehension (refactoring)
- **No-Comments**: Tests documentation dependency
- **No-Comments Original**: Baseline TC samples without comments

---

## Vulnerability Type Distribution

| Vulnerability Type | Sample Count | Percentage |
|-------------------|--------------|------------|
| **front_running** | 13 | 22.4% |
| **access_control** | 10 | 17.2% |
| **reentrancy** | 8 | 13.8% |
| **logic_error** | 8 | 13.8% |
| **oracle_manipulation** | 4 | 6.9% |
| **timestamp_dependency** | 4 | 6.9% |
| **integer_overflow** | 4 | 6.9% |
| **denial_of_service** | 4 | 6.9% |
| **input_validation** | 1 | 1.7% |
| **dos** | 1 | 1.7% |
| **unchecked_return** | 1 | 1.7% |

**Note**: "denial_of_service" and "dos" are semantically the same (5 total DoS samples).

### Vulnerability Coverage

- **Classic Vulnerabilities**: reentrancy (8), access_control (10), integer_overflow (4)
- **DeFi-Specific**: front_running (13), oracle_manipulation (4), timestamp_dependency (4)
- **Logic Issues**: logic_error (8), input_validation (1), unchecked_return (1)

---

## Prompt Type Strategy

### Standard Evaluation (53 samples)
- **Prompt Type**: Direct (structured JSON output)
- **Samples**: All TC (20) + GS (5) + DS (28)

### Prompt Comparison Study (5 samples)
- **Samples**: gs_002, gs_013, gs_017, gs_020, gs_026
- **Prompt Types**: 3 per sample
  - **Direct**: Structured JSON with explicit vulnerability analysis request
  - **Naturalistic**: Colleague-style review request (free-form)
  - **Adversarial**: "Already audited" framing (sycophancy test)
- **Total Evaluations**: 15 (5 samples × 3 prompts)

**Purpose**: Test how prompt strategy affects model performance and sycophancy resistance.

---

## Dataset Statistics Summary

### By Subset
| Subset | Base Vulns | Total Samples | Transformations per Base | Primary Purpose |
|--------|-----------|---------------|------------------------|-----------------|
| **TC** | 5 | 20 | 4 | Transformation robustness |
| **GS** | 10 | 10 | 1 | Real-world audit findings |
| **DS** | 7 | 28 | 4 | Diverse vulnerability types |

### By Transformation Complexity
| Complexity | Transformation Types | Sample Count | Models Struggle? |
|-----------|---------------------|--------------|-----------------|
| **Low** | nocomments_original, nocomments | 12 | No (80-100% accuracy) |
| **Medium** | chameleon_medical, shapeshifter, hydra | 26 | No (57-100% accuracy) |
| **High** | sanitized | 15 | **YES** (43-83% accuracy) |

---

## Evaluation Coverage

### Models Evaluated
1. Claude Opus 4.5
2. DeepSeek V3.2
3. Gemini 3 Pro Preview
4. GPT-5.2
5. Llama 3.1 405B
6. Grok 4 Fast

### Total Evaluations Performed
- **TC samples**: 20 samples × 6 models = 120 evaluations
- **GS samples**: 10 samples × 6 models = 60 evaluations (standard)
- **GS prompt comparison**: 5 samples × 3 prompts × 6 models = 90 evaluations
- **DS samples**: 28 samples × 6 models = 168 evaluations

**Grand Total**: 438 model evaluations

---

## Key Dataset Properties

### Diversity
✅ **11 vulnerability types** across 58 samples
✅ **6 transformation strategies** testing different aspects
✅ **3 data sources** (TC, GS, DS) with different origins

### Robustness Testing
✅ **Sanitized variants** (15 samples) test minimal-context performance
✅ **Domain shift variants** (12 medical) test transfer learning
✅ **Structural variants** (19 shapeshifter/hydra) test code comprehension

### Real-World Relevance
✅ **10 GPTShield samples** from professional audits
✅ **7 DiverseVul samples** from real vulnerabilities
✅ **13 front-running vulnerabilities** (DeFi-specific)

---

## Dataset Design Rationale

### Why Multiple Transformations per Base?

**Purpose**: Isolate what models rely on for detection

- **Same vulnerability** across 4 code variants
- If model detects in all variants → understands core logic
- If model fails on sanitized only → relies on semantic cues
- If model fails on medical only → domain-dependent

### Why Prompt Type Comparison?

**Purpose**: Understand prompt engineering impact

- **Direct prompts**: Structured, explicit instructions
- **Naturalistic prompts**: Mimics real-world code review
- **Adversarial prompts**: Tests sycophancy (will model disagree with user?)

### Why Temporal Contamination Samples?

**Purpose**: Avoid training data contamination

- TC samples collected **after** model training cutoffs
- Ensures models haven't "memorized" vulnerabilities
- Tests true understanding vs. pattern matching

---

## Dataset Limitations

### Sample Size
- Only **22 unique base vulnerabilities**
- **5 GS samples** for prompt comparison (small for statistical significance)
- **5 TC base samples** (limited transformation coverage)

### Transformation Coverage
- No "extreme" obfuscation (e.g., bytecode-level)
- No multi-contract interactions
- No upgradeability patterns (proxy contracts)

### Vulnerability Type Imbalance
- Front-running over-represented (13 samples, 22%)
- Some types have only 1 sample (input_validation, unchecked_return)
- No representation of: MEV, flash loan attacks, governance attacks

### Language Scope
- **Solidity only** (no Vyper, Rust, Move, etc.)
- EVM-specific vulnerabilities
- Limited to smart contract security

---

## Recommended Use Cases

### For Model Comparison
✅ Use full 58-sample set for overall ranking
✅ Use transformation breakdown to identify model weaknesses
✅ Use prompt comparison (5 GS samples) for prompt engineering insights

### For Robustness Testing
✅ Use sanitized variants (15 samples) for worst-case evaluation
✅ Use medical variants (12 samples) for cross-domain transfer
✅ Use shapeshifter/hydra (19 samples) for code comprehension depth

### For Real-World Validation
✅ Use GPTShield samples (10) for audit-quality assessment
✅ Use DiverseVul samples (28) for diverse vulnerability coverage
✅ Use TC samples (20) for temporal contamination control

---

## Citation

When using this dataset, please cite:

- **Temporal Contamination**: Samples collected post-training to avoid data leakage
- **GPTShield**: Professional audit findings from real smart contract audits
- **DiverseVul**: Diverse vulnerability samples from public sources

---

## Future Extensions

Potential dataset expansions:

1. **More base samples**: Increase from 22 to 50+ unique vulnerabilities
2. **Extreme transformations**: Bytecode obfuscation, whitespace-only variants
3. **Multi-contract samples**: Cross-contract vulnerabilities, proxy patterns
4. **Additional languages**: Vyper, Rust (Solana), Move (Aptos/Sui)
5. **Safe samples**: Add non-vulnerable contracts for false positive testing
6. **Severity stratification**: Balanced critical/high/medium/low samples
