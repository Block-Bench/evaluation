# Stratified Sampling Methodology for Difficulty-Stratified (DS) Contracts

## Overview

We employ a **two-stage stratified sampling** procedure to select a representative subset from the DS corpus. This approach ensures balanced representation across difficulty tiers while preserving the distributional characteristics of vulnerability types within each stratum.

---

## Notation

Let $\mathcal{D} = \{d_1, d_2, \ldots, d_N\}$ denote the full DS dataset with $N = 223$ cleaned Solidity contracts.

Each sample $d_i$ is characterized by:
- **Difficulty tier** $\tau(d_i) \in \{1, 2, 3, 4\}$
- **Vulnerability type** $v(d_i) \in \mathcal{V}$, where $\mathcal{V}$ is the set of vulnerability categories
- **Sample identifier** following the convention `ds_t{τ}_{nnn}` (e.g., `ds_t1_001`)

We partition $\mathcal{D}$ into tier-specific subsets:

$$\mathcal{D}_k = \{d_i \in \mathcal{D} : \tau(d_i) = k\}, \quad k \in \{1, 2, 3, 4\}$$

---

## Stage 1: Tier-Level Allocation

We define target allocations $n_k$ for each tier $k$, guided by two principles:

1. **Inverse difficulty weighting**: Higher tiers receive proportionally more samples relative to their population, as these represent cases where model performance degrades
2. **Full coverage for scarce tiers**: Tier 4 (multi-contract) samples are taken in their entirety due to limited availability

The allocation function is:

$$n_k = \min\left(\left\lfloor n \cdot w_k \right\rceil, |\mathcal{D}_k|\right)$$

where $n$ is the target sample size and $w_k$ are tier weights.

**Population and Allocation**:

| Tier | Description | Population $|\mathcal{D}_k|$ | Allocation $n_k$ | Sampling Rate |
|:----:|-------------|:----------------------------:|:----------------:|:-------------:|
| 1 | Textbook | 86 | 20 | 23.3% |
| 2 | Clear Audit | 87 | 30 | 34.5% |
| 3 | Subtle Audit | 36 | 36 | 100% |
| 4 | Multi-Contract | 14 | 14 | 100% |
| | **Total** | **223** | **100** | **44.8%** |

**Rationale**: Tiers 3–4 constitute only 22% of the population but receive 50% of the sample allocation. This deliberate oversampling of harder cases—taking all available samples from both tiers—enables robust analysis of model performance degradation across difficulty levels.

---

## Stage 2: Vulnerability-Type Stratification

Within each tier $k$, we further stratify by vulnerability type to ensure coverage across the vulnerability taxonomy.

Let $\mathcal{D}_{k,v} = \{d_i \in \mathcal{D}_k : v(d_i) = v\}$ denote samples of type $v$ within tier $k$.

The within-tier allocation for vulnerability type $v$ is:

$$n_{k,v} = \max\left(1, \left\lfloor n_k \cdot \frac{|\mathcal{D}_{k,v}|}{|\mathcal{D}_k|} \right\rceil\right)$$

This proportional allocation ensures:
- **Minimum representation**: At least one sample per vulnerability type present in the tier
- **Proportional scaling**: Larger vulnerability categories receive proportionally more samples

**Adjustment procedure**: If $\sum_v n_{k,v} \neq n_k$, we iteratively adjust allocations starting from the largest categories until the tier constraint is satisfied.

---

## Sampling Procedure

For reproducibility, we employ deterministic pseudo-random sampling:

```
ALGORITHM: Stratified-Sample(𝒟, seed)
───────────────────────────────────────────────────────────────
Input:  𝒟 = full dataset organized by tier
        seed = random seed for reproducibility (default: 42)
Output: 𝒮 = stratified sample

1.  Initialize PRNG with seed
2.  For each tier k ∈ {1, 2, 3, 4}:
    a.  If n_k ≥ |𝒟_k|: select all samples from tier
    b.  Else:
        i.   Compute within-tier allocations {n_{k,v}} for each vuln type
        ii.  Adjust allocations to satisfy Σ_v n_{k,v} = n_k
        iii. For each vulnerability type v:
             - Draw n_{k,v} samples uniformly at random from 𝒟_{k,v}
    c.  Aggregate: 𝒮_k = ∪_v Sample(𝒟_{k,v}, n_{k,v})
3.  Return 𝒮 = ∪_k 𝒮_k
```

---

## Final Sample Composition

### By Tier

| Tier | Selected | Description |
|:----:|:--------:|-------------|
| 1 | 20 | Textbook vulnerabilities (reentrancy, unchecked returns) |
| 2 | 30 | Clear audit findings requiring code comprehension |
| 3 | 36 | Subtle vulnerabilities requiring deep semantic analysis |
| 4 | 14 | Multi-contract interactions and complex state dependencies |
| **Total** | **100** | |

### Vulnerability Type Coverage

**Tier 1**: reentrancy (7), unchecked_return (7), access_control (3), weak_randomness (1), integer_issues (1), dos (1)

**Tier 2**: logic_error (4), dos (3), access_control (3), weak_randomness (2), unchecked_return (2), +15 additional types

**Tier 3**: All 36 samples—logic_error (10), honeypot (6), unchecked_return (5), unchecked_call (2), reentrancy (2), access_control (2), front_running (1), weak_randomness (1), oracle_manipulation (1), delegatecall_injection (1), token_incompatibility (1), approval_scam (1), precision_loss (1), unprotected_callback (1)

**Tier 4**: All 14 samples (signature_replay, storage_collision, oracle_manipulation, flash_loan, cross_function_reentrancy, etc.)

---

## Statistical Properties

### Reproducibility

Given identical inputs $(\mathcal{D}, \text{seed})$, the procedure yields identical outputs. The canonical seed value is **42**.

```bash
# Reproduce the exact sample selection
python sample_ds_dataset.py --data-dir dataset --seed 42
```

### Representativeness

The sampling design ensures:

1. **Tier coverage**: All difficulty levels represented with minimum $n_k \geq 14$
2. **Type diversity**: Major vulnerability categories present in each tier
3. **Difficulty gradient**: Increasing sampling density for harder tiers

---

## Paper Citation

When referencing this sampling methodology:

> We employ two-stage stratified sampling with inverse difficulty weighting, selecting 100 contracts from a corpus of 223 difficulty-stratified samples. The procedure applies proportional allocation within tiers to preserve vulnerability-type distributions, while oversampling harder tiers (3–4) to enable robust analysis of performance degradation. All tier-3 and tier-4 samples are included in their entirety due to their scarcity and analytical importance for evaluating model performance on challenging cases. Sampling is deterministic (seed=42) for full reproducibility.

---

## Implementation

**Script**: `sample_ds_dataset.py`

**Usage**:
```bash
python sample_ds_dataset.py \
    --data-dir dataset \
    --seed 42 \
    --output sampled_ds_ids.json
```

**Output**: JSON manifest containing sample IDs, tier assignments, and vulnerability types.

---

*Document version: 2.1 | Dataset: BlockBench DS (cleaned) | Last updated: January 2026*
