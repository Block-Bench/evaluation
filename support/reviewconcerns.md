# BlockBench Evaluation Concerns & Potential Improvements

This document outlines critical concerns identified during metric review that should be addressed before ACL submission.

---

## Concern 1: The ρ = 1.000 Problem

### Issue

Perfect ranking stability (Spearman's ρ = 1.000) across all five SUI weight configurations sounds like a strength, but reviewers might flip this argument:

> "If rankings are identical regardless of weights, why use a composite at all? Just rank by TDR."

### Current State

| Config          | Weights (TDR/Rsn/Prec) | Ranking                                         |
| --------------- | ---------------------- | ----------------------------------------------- |
| Balanced        | 0.33/0.33/0.34         | GPT > Gemini > Claude > Grok > DeepSeek > Llama |
| Detection       | 0.40/0.30/0.30         | Same                                            |
| Quality-First   | 0.30/0.40/0.30         | Same                                            |
| Precision-First | 0.30/0.30/0.40         | Same                                            |
| Detection-Heavy | 0.50/0.25/0.25         | Same                                            |

### Risk

Reviewers may question the value proposition of SUI over raw TDR.

### Suggested Fix

Find or construct an example demonstrating where TDR alone would mislead but SUI corrects it. Possibilities:

- A model with high TDR but very low precision (spams findings, many hallucinations)
- A model with moderate TDR but excellent reasoning (demonstrates deeper understanding)
- Synthetic scenario or pull from full dataset beyond the 58-sample evaluation

### Priority: Medium

---

## Concern 2: Reasoning Scores Have Selection Bias

### Issue

Reasoning quality (RCIR/AVA/FSV) is only computed for samples where the target was found. This creates unequal sample sizes:

| Model           | TDR | Approx. Samples with Reasoning Scores |
| --------------- | --- | ------------------------------------- |
| Gemini 3 Pro    | 58% | ~34 samples                           |
| GPT-5.2         | 56% | ~32 samples                           |
| Claude Opus 4.5 | 53% | ~31 samples                           |
| Grok 4          | 44% | ~26 samples                           |
| DeepSeek v3.2   | 38% | ~22 samples                           |
| Llama 3.1 405B  | 18% | ~10 samples                           |

### Risk

- Llama's reasoning scores (0.88/0.90/0.83) are based on ~10 samples — not statistically robust
- High variance in small samples could make scores unreliable
- Reviewers may question statistical validity

### Additional Issue

MISCHARACTERIZED findings (right location, wrong type) demonstrate _partial_ understanding but receive zero reasoning credit. This misses nuance:

- Model identifies vulnerable function correctly
- Model explains the attack mechanism somewhat correctly
- Model just misclassifies the vulnerability type

This shows some understanding, but current metrics treat it as complete failure.

### Suggested Fix

**Option A:** Report confidence intervals on reasoning scores

**Option B:** Score reasoning for MISCHARACTERIZED findings with a discount factor (e.g., 0.5×)

**Option C:** Acknowledge limitation explicitly in paper

### Priority: Medium-High

---

## Concern 3: No Statistical Significance Testing

### Issue

With n = 58 samples, are model differences statistically significant?

| Model           | TDR   | Difference from Next |
| --------------- | ----- | -------------------- |
| Gemini 3 Pro    | 57.6% | +1.7pp               |
| GPT-5.2         | 55.9% | +3.0pp               |
| Claude Opus 4.5 | 52.9% | +8.8pp               |
| Grok 4          | 44.1% | +5.9pp               |
| DeepSeek v3.2   | 38.2% | +20.3pp              |
| Llama 3.1 405B  | 17.9% | —                    |

The 1.7pp difference between Gemini and GPT-5.2 is approximately 1 sample. Is this meaningful?

### Risk

ACL reviewers increasingly expect statistical rigor:

- "How do we know Gemini is actually better than GPT-5.2?"
- "Could this ranking be due to random chance?"

### Suggested Fix

Add the following statistical tests:

| Test                               | Purpose                                |
| ---------------------------------- | -------------------------------------- |
| **Bootstrap Confidence Intervals** | Show uncertainty range for TDR and SUI |
| **McNemar's Test**                 | Pairwise significance between models   |
| **Bonferroni Correction**          | Adjust for multiple comparisons        |

### Example Output (hypothetical)

```
Gemini 3 Pro TDR: 57.6% [95% CI: 44.2% - 70.1%]
GPT-5.2 TDR: 55.9% [95% CI: 42.6% - 68.4%]
McNemar's p-value: 0.72 (not significant)
```

This would honestly show that top models are not statistically distinguishable, which is a valid finding.

### Priority: High

---

## Concern 4: Gold Standard Sample Size Too Small

### Issue

Gold Standard (GS) subset has only 10 samples. Results:

| Model           | GS TDR | Approx. Targets Found |
| --------------- | ------ | --------------------- |
| Claude Opus 4.5 | 20%    | 2 samples             |
| Gemini 3 Pro    | 11%    | ~1 sample             |
| GPT-5.2         | 10%    | 1 sample              |
| Grok 4          | 10%    | 1 sample              |
| DeepSeek v3.2   | 0%     | 0 samples             |
| Llama 3.1 405B  | 0%     | 0 samples             |

### Risk

> "The difference between Claude and Gemini on Gold Standard is literally 1 contract."

Single-sample differences make results appear fragile and potentially random.

### Suggested Fix

**Short-term:** Acknowledge limitation explicitly, report confidence intervals

**Long-term (before camera-ready):** Expand GS to 30-40 samples from additional post-September 2025 audits

### Priority: High (for credibility)

---

## Concern 5: Per-Vulnerability-Type Breakdown Missing

### Issue

BlockBench has 13 vulnerability types, but only aggregate TDR is reported. The paper's central thesis is **memorization vs. understanding**, yet doesn't show:

- Which vulnerability types are "easy" (potentially memorized)?
- Which types are "hard" (require genuine reasoning)?
- Do models fail uniformly or on specific categories?

### Current Vulnerability Distribution (from paper)

| Vulnerability Type | Count |
| ------------------ | ----- |
| Access Control     | 46    |
| Reentrancy         | 43    |
| Logic Errors       | 31    |
| Others             | 143   |

### Risk

Reviewers will want to know:

- Is reentrancy detection high because the DAO hack is memorized?
- Are logic errors hard because they require genuine semantic understanding?
- Does this support or weaken the memorization thesis?

### Suggested Fix

Add a table or figure showing TDR breakdown by vulnerability type:

| Vulnerability Type  | Overall TDR | GS TDR | Interpretation         |
| ------------------- | ----------- | ------ | ---------------------- |
| Reentrancy          | 75%         | 15%    | Likely memorized       |
| Access Control      | 60%         | 20%    | Moderate               |
| Logic Errors        | 30%         | 10%    | Requires understanding |
| Oracle Manipulation | 45%         | 5%     | Moderate               |
| ...                 | ...         | ...    | ...                    |

This would significantly strengthen the paper's narrative.

### Priority: High (strengthens thesis)

---

## Concern 6: BONUS_VALID Verification

### Issue

How is BONUS_VALID (genuine undocumented vulnerability) confirmed as actually valid?

Current process:

1. Model reports finding not in ground truth
2. LLM judge (Mistral Medium 3) classifies it as BONUS_VALID

### Risk

What if the judge hallucinates that a hallucination is valid? The judge could incorrectly validate fabricated findings.

### Current Validation

Human validation covered 31 samples (116 comparisons). But did it specifically verify BONUS_VALID classifications?

### Questions to Answer

- How many BONUS_VALID findings were there total?
- How many were human-verified?
- What was the human agreement rate on BONUS_VALID specifically?

### Suggested Fix

Report BONUS_VALID statistics explicitly:

```
Total BONUS_VALID findings: X
Human-verified subset: Y
Human agreement rate: Z%
```

If human validation didn't specifically cover BONUS_VALID, acknowledge this limitation.

### Priority: Medium

---

## Concern 7: Transformation Effect Not Quantified

### Issue

Figure 4 shows SUI trajectory across transformations, but there's no single metric quantifying transformation robustness.

### Current Approach

Visual inspection of Figure 4 — readers must estimate degradation themselves.

### Suggested Fix

Add a **Transformation Degradation Score (TDS)**:

```
TDS = (SUI_baseline - SUI_shapeshifter) / SUI_baseline × 100
```

| Model         | TDS   | Interpretation            |
| ------------- | ----- | ------------------------- |
| GPT-5.2       | 1.0%  | Highly robust             |
| DeepSeek v3.2 | 25.0% | Surface pattern dependent |
| ...           | ...   | ...                       |

This gives reviewers a concrete number to compare, not just a visual.

### Priority: Low-Medium

---

## Concern 8: Prompt Type Analysis Incomplete

### Issue

Section 5.3 mentions performance varies across Direct, Adversarial, and Naturalistic prompts:

> "Gemini 3 Pro and GPT-5.2 show robustness (18-21pp drops), while Claude Opus 4.5 and DeepSeek v3.2 degrade more (21-39pp)."

But there's no table showing TDR by prompt type for each model.

### Suggested Fix

Add a breakdown table:

| Model           | Direct | Naturalistic | Adversarial | Max Drop |
| --------------- | ------ | ------------ | ----------- | -------- |
| Gemini 3 Pro    | 65%    | 55%          | 47%         | 18pp     |
| GPT-5.2         | 62%    | 52%          | 48%         | 14pp     |
| Claude Opus 4.5 | 60%    | 45%          | 39%         | 21pp     |
| ...             | ...    | ...          | ...         | ...      |

### Priority: Low

---

## Summary: Priority Matrix

| Concern                           | Impact on Acceptance | Fix Difficulty | Priority   |
| --------------------------------- | -------------------- | -------------- | ---------- |
| Statistical significance tests    | High                 | Medium         | **HIGH**   |
| Gold Standard sample size         | High                 | Hard           | **HIGH**   |
| Per-vulnerability-type breakdown  | High                 | Easy           | **HIGH**   |
| Reasoning selection bias          | Medium               | Medium         | **MEDIUM** |
| SUI justification (ρ=1.000)       | Medium               | Easy           | **MEDIUM** |
| BONUS_VALID verification          | Medium               | Easy           | **MEDIUM** |
| Transformation degradation metric | Low                  | Easy           | **LOW**    |
| Prompt type breakdown table       | Low                  | Easy           | **LOW**    |

---

## Recommended Action Plan

### Before Submission

1. **Add bootstrap confidence intervals** for TDR and SUI (addresses Concern 3)
2. **Add per-vulnerability-type table** (addresses Concern 5)
3. **Expand GS if possible** or acknowledge limitation with CIs (addresses Concern 4)
4. **Add BONUS_VALID statistics** (addresses Concern 6)

### In Discussion/Limitations Section

5. Acknowledge reasoning sample size disparity (Concern 2)
6. Justify SUI with concrete differentiating example (Concern 1)

### Nice-to-Have

7. Add Transformation Degradation Score (Concern 7)
8. Add prompt-type breakdown table (Concern 8)

---

## Questions for Team Discussion

1. Do we have access to more Gold Standard samples from recent audits?
2. Can we run bootstrap analysis with current data?
3. Do we have per-vulnerability-type results already computed?
4. How many BONUS_VALID findings were flagged, and were any human-verified?
5. Is there a case in our data where TDR and SUI rankings differ?

---

_Document prepared for BlockBench team review — ACL 2026 submission preparation._
