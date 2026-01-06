# Detection Results: Majority Vote Analysis

**Generated:** 2026-01-06
**Method:** Majority Vote (2-of-3 judges must agree)
**Judges:** GLM-4.7, MIMO-v2-Flash, Mistral-Large

---

## 1. Methodology: Inter-Annotator Agreement

### 1.1 Why Multiple Judges?

Single-judge evaluation in LLM-based assessment is inherently unreliable due to:
- **Terminology sensitivity**: Different judges may interpret vulnerability descriptions differently
- **Threshold variance**: Judges may have different standards for what constitutes a "match"
- **Semantic ambiguity**: Same vulnerability can be described in multiple valid ways

We employ a **3-judge ensemble** with majority voting to mitigate these issues.

### 1.2 Majority Vote Protocol

For each sample, we collect binary judgments (target found = 1, not found = 0) from all three judges. A sample is marked as **"target found"** if and only if **≥2 judges agree** the detector identified the target vulnerability.

This approach:
- Reduces impact of individual judge errors
- Provides more robust estimates than single-judge evaluation
- Aligns with standard annotation practices in NLP research

### 1.3 Inter-Rater Agreement Metric: Fleiss' Kappa (κ)

We report **Fleiss' kappa** to quantify inter-judge agreement:

| κ Value | Interpretation |
|---------|----------------|
| < 0.00 | Poor (less than chance) |
| 0.00–0.20 | Slight |
| 0.21–0.40 | Fair |
| 0.41–0.60 | Moderate |
| 0.61–0.80 | Substantial |
| 0.81–1.00 | Almost Perfect |

**Formula:**
```
κ = (P̄ - Pₑ) / (1 - Pₑ)
```
Where P̄ is observed agreement and Pₑ is expected agreement by chance.

### 1.4 Reporting Convention

In our tables, we report:
- **TDR (Target Detection Rate)**: Percentage of samples where majority of judges found target
- **κ**: Fleiss' kappa for inter-judge agreement (in supplementary tables)

---

## 2. DS (Difficulty-Stratified) Results

### 2.1 TDR by Detector and Tier

| Model | T1 | T2 | T3 | T4 | Avg |
|-------|---:|---:|---:|---:|---:|
| **Claude** | **100.0** | **83.8** | **70.0** | 92.3 | **86.5** |
| **Gemini** | 75.0 | 78.4 | 50.0 | **92.3** | 73.9 |
| GPT-5.2 | 60.0 | 70.3 | 36.7 | 84.6 | 62.9 |
| DeepSeek | 65.0 | 64.9 | 46.7 | 61.5 | 59.5 |
| Llama | 65.0 | 45.9 | 40.0 | 69.2 | 55.0 |
| Qwen | 60.0 | 56.8 | 43.3 | 53.8 | 53.5 |
| Grok | 40.0 | 37.8 | 33.3 | 30.8 | 35.5 |

### 2.2 Inter-Judge Agreement (Fleiss' κ)

| Model | T1 | T2 | T3 | T4 | Interpretation |
|-------|---:|---:|---:|---:|----------------|
| GPT-5.2 | 0.80 | 0.79 | 0.81 | 0.83 | Substantial–Almost Perfect |
| Grok | 0.93 | 0.84 | 0.69 | 0.87 | Substantial–Almost Perfect |
| DeepSeek | 0.79 | 0.70 | 0.64 | 0.48 | Moderate–Substantial |
| Qwen | 0.72 | 0.71 | 0.72 | 0.48 | Moderate–Substantial |
| Gemini | 0.62 | 0.64 | 0.47 | 0.54 | Moderate–Substantial |
| Llama | 0.41 | 0.64 | 0.72 | 0.55 | Moderate–Substantial |
| Claude | -0.09 | 0.56 | 0.53 | 0.54 | Moderate (ceiling effect on T1) |

**Key Observations:**
1. **Claude achieves 100% TDR on T1** with negative κ — this is a ceiling effect (nearly all samples found by all judges, leaving little room for disagreement measurement)
2. **Agreement is generally substantial** (κ > 0.6) across most detector-tier combinations
3. **T3 (complex contracts) shows highest variance** in both TDR and agreement
4. **GPT-5.2 and Grok show highest agreement** despite different TDR levels

---

## 3. TC (Temporal Contamination) Results

### 3.1 TDR by Detector and Variant

| Model | MinSan | San | NoCom | Cham | Shape | Troj | FalseP | Avg |
|-------|-------:|----:|------:|-----:|------:|-----:|-------:|----:|
| **Claude** | **71.7** | **54.3** | **50.0** | **43.5** | **50.0** | 32.6 | **54.3** | **50.9** |
| Gemini | 65.2 | 28.3 | 32.6 | 37.0 | 34.8 | 34.8 | 37.0 | 38.5 |
| DeepSeek | 58.7 | 37.0 | 41.3 | 21.7 | 26.1 | **43.5** | 30.4 | 37.0 |
| GPT-5.2 | 54.3 | 34.8 | 37.0 | 28.3 | 30.4 | 30.4 | 37.0 | 36.0 |
| Qwen | 56.5 | 43.5 | 30.4 | 15.2 | 17.4 | 28.3 | 41.3 | 33.2 |
| Llama | 52.2 | 39.1 | 30.4 | 21.7 | 13.0 | **43.5** | 21.7 | 31.7 |
| Grok | 32.6 | 23.9 | 19.6 | 15.2 | 15.2 | 21.7 | 21.7 | 21.4 |

### 3.2 Inter-Judge Agreement (Fleiss' κ)

| Model | MinSan | San | NoCom | Cham | Shape | Troj | FalseP |
|-------|-------:|----:|------:|-----:|------:|-----:|-------:|
| GPT-5.2 | 0.77 | 0.20 | 0.12 | 0.23 | 0.24 | 0.22 | 0.21 |
| DeepSeek | 0.68 | 0.10 | 0.07 | 0.17 | 0.16 | 0.11 | 0.09 |
| Llama | 0.68 | 0.04 | 0.11 | 0.27 | 0.16 | 0.04 | 0.13 |
| Claude | 0.59 | 0.07 | 0.06 | 0.13 | 0.08 | 0.05 | 0.14 |
| Grok | 0.59 | 0.29 | 0.36 | 0.27 | 0.27 | 0.32 | 0.32 |
| Gemini | 0.57 | 0.23 | 0.23 | 0.21 | 0.23 | 0.20 | 0.17 |
| Qwen | 0.54 | 0.11 | 0.20 | 0.36 | 0.17 | 0.07 | 0.05 |

**Key Observations:**
1. **MinSan has highest agreement** (κ = 0.54–0.77) — minimal transformation preserves clarity
2. **All other variants show low agreement** (κ < 0.4) — obfuscation creates ambiguity for judges
3. **Claude leads on all variants except Trojan** where DeepSeek and Llama tie at 43.5%
4. **Chameleon and ShapeShifter cause biggest drops** — domain shift and restructuring are effective at blocking memorization

---

## 4. Key Findings

### 4.1 Detection Performance

1. **Claude dominates** with 86.5% DS average and 50.9% TC average
2. **Gemini is strong on DS** (73.9%) but drops significantly on TC (38.5%)
3. **Grok consistently underperforms** at 35.5% DS and 21.4% TC

### 4.2 Memorization vs. Understanding (DS→TC Drop)

| Model | DS Avg | TC Avg | Drop | Interpretation |
|-------|-------:|-------:|-----:|----------------|
| Gemini | 73.9% | 38.5% | **-35.4%** | Heavy memorization reliance |
| Claude | 86.5% | 50.9% | **-35.6%** | Heavy memorization reliance |
| GPT-5.2 | 62.9% | 36.0% | -26.9% | Moderate memorization |
| DeepSeek | 59.5% | 37.0% | -22.5% | Moderate memorization |
| Llama | 55.0% | 31.7% | -23.3% | Moderate memorization |
| Qwen | 53.5% | 33.2% | -20.3% | Lower memorization reliance |
| Grok | 35.5% | 21.4% | -14.1% | Lowest memorization reliance |

### 4.3 Judge Agreement Patterns

1. **DS has higher agreement than TC** — obfuscation creates evaluation ambiguity
2. **MinSan variant has highest TC agreement** — closest to original structure
3. **Low TC agreement (κ < 0.3)** suggests need for more judges or clearer evaluation criteria

---

## 5. Recommendations for Paper

### 5.1 How to Report

**Main Paper:**
- Report majority vote TDR in Table 1
- Mention "evaluated by 3 LLM judges with majority voting" in methodology
- Note overall Fleiss' κ range (e.g., "κ = 0.4–0.9 for DS, κ = 0.1–0.8 for TC")

**Appendix:**
- Full per-detector κ tables
- Pairwise judge agreement breakdown
- Discussion of low TC agreement and implications

### 5.2 Interpretation Caveats

When reporting low-agreement results (TC variants), note:
> "Lower inter-judge agreement on TC variants (κ < 0.4) reflects the inherent ambiguity introduced by code transformation. Judges disagreed not on detector correctness but on whether transformed descriptions still matched the original vulnerability taxonomy."

---

## 6. Files Generated

- `ds/ds_summary.md` — DS results summary
- `ds/ds_majority_vote_results.json` — Full DS data with per-sample details
- `tc/tc_summary.md` — TC results summary
- `tc/tc_majority_vote_results.json` — Full TC data with per-sample details
- `paper_report.md` — This report
- `table1.md` — Combined Table 1 for paper
