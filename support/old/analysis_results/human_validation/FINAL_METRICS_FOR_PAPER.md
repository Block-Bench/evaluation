# Human Expert Validation - Final Metrics for Paper

## Dataset

**31 unique samples** validated by two independent security experts, yielding **116 expert-judge comparisons**:
- **Expert 1 (D4n13l)**: 27 unique samples from Claude Opus 4.5, DeepSeek v3.2, Gemini 3 Pro (80 comparisons)
- **Expert 2 (FrontRunner)**: 15 unique samples from GPT-5.2, Grok 4, Llama 3.1 405B (36 comparisons)
- **Overlap**: 11 samples reviewed by both experts
- **Note**: Same sample reviewed across different models (e.g., sn_gs_002 reviewed for 8 different models)

## Key Metrics

### Target Detection Agreement

**Overall Agreement: 92.2%** (107/116 samples)

**Cohen's κ: 0.84** (almost perfect agreement)

**Judge Performance:**
- **Precision**: 0.84 (when judge says "vulnerable", expert agrees 84% of time)
- **Recall**: 1.00 (when expert says "vulnerable", judge ALWAYS agrees)
- **F1 Score**: 0.91 (excellent overall performance)

**Pearson's ρ: 0.85** (p<0.0001) - strong correlation

### Confusion Matrix

```
                    Judge: NOT FOUND  |  Judge: FOUND
Expert: NOT FOUND            61                   9
Expert: FOUND                 0                  46
```

**Interpretation:**
- 61 cases: Both agreed "NOT vulnerable" ✅
- 46 cases: Both agreed "vulnerable" ✅
- 9 cases: Judge detected, expert didn't (false positives)
- 0 cases: Expert detected, judge didn't (perfect recall!)

### Type Classification (When Both Detected Vulnerability)

Among 46 samples where both found the vulnerability:
- **Agreement: 84.8%** (39/46 samples)
- **Disagreements: 7 cases** (15.2%)
  - All involved "exact" vs "semantic" match
  - Same vulnerability, different terminology
  - No fundamental classification errors

### By-Expert Breakdown

| Expert | Samples | Agreement | Both Found | Expert Only | Judge Only | Both Not Found |
|--------|---------|-----------|------------|-------------|------------|----------------|
| D4n13l | 80 | 92.5% | 32 | 0 | 6 | 42 |
| FrontRunner | 36 | 91.7% | 11 | 0 | 3 | 22 |

Both experts showed consistent patterns with >91% agreement.

## What to Report in Paper

### Option 1: Concise (for results.tex) ✅ USED IN PAPER

```latex
Two security experts validated judge verdicts across 31 samples (116 model-sample
comparisons), achieving 92\% agreement (κ=0.84, ρ=0.85, p<0.0001). The judge
demonstrated perfect recall (100\%) with 84\% precision (F1=0.91), validating
automated evaluation.
```

### Option 2: Technical Detail (for appendix.tex) ✅ USED IN PAPER

```latex
Thirty-one unique samples across all models and transformations underwent independent
validation by two security experts, yielding 116 expert-judge comparisons (27 and 15
unique samples per expert, with 11 overlapping). Validators assessed:
- Target detection accuracy (binary)
- Vulnerability type classification
- Reasoning quality (RCIR, AVA, FSV scores)

Expert-judge agreement: 92.2\% (κ=0.84, almost perfect) with F1=0.91
(precision=0.84, recall=1.00). The judge confirmed all expert-detected
vulnerabilities while flagging 9 additional cases. Type classification showed
85\% agreement when both detected the target. Pearson correlation: ρ=0.85 (p<0.0001).
```

### Option 3: Minimal (one sentence)

```latex
Human validation (31 samples, 116 comparisons) showed 92\% agreement with
judge verdicts (κ=0.84, F1=0.91).
```

## Statistical Interpretation

### κ = 0.84 Interpretation

Cohen's Kappa guidelines (Landis & Koch, 1977):
- 0.81-1.00: **Almost perfect agreement** ✅ (we're here!)
- 0.61-0.80: Substantial agreement
- 0.41-0.60: Moderate agreement
- 0.21-0.40: Fair agreement

Our κ=0.84 indicates **almost perfect agreement**, validating the automated judge.

### Judge Validation Summary

The LLM judge demonstrates:

1. **Perfect Recall (1.00)**: Never misses vulnerabilities that experts detect
2. **High Precision (0.84)**: 84% of judge detections are validated by experts
3. **Conservative Bias**: Errs on side of caution, flagging potential issues (9 extra detections)
4. **Excellent Overall**: F1=0.91 shows strong balanced performance
5. **Type Classification**: 85% agreement on vulnerability categorization

### Comparison to Paper's Original Claims

**Original (INCORRECT placeholders):**
- "20 responses"
- "Inter-rater agreement: verdict κ=0.91, type match κ=0.84, reasoning κ=0.78"
- "Human-judge correlation: ρ=0.87 (p<0.001), 85% agreement"

**Actual (CORRECT metrics - NOW IN PAPER):**
- **31 unique samples** (116 expert-judge comparisons across multiple models)
- **Expert-judge agreement: κ=0.84** (target detection)
- **Type classification: 85% agreement** (when both found target)
- **Correlation: ρ=0.85** (p<0.0001)
- **Overall agreement: 92.2%**

## Files Generated

1. `expert_judge_agreement.json` - Full metrics by model
2. `expert_judge_comparisons_detailed.json` - All 116 sample-level comparisons
3. `comprehensive_agreement_analysis.json` - Detailed statistical breakdown
4. `binary_kappa_analysis.json` - Detection and classification metrics
5. `FINAL_METRICS_FOR_PAPER.md` - This summary

## Updates Made to Paper ✅ COMPLETE

### results.tex (line 53) - UPDATED
**Before:**
```latex
Two security experts independently reviewed 20 responses. Inter-rater agreement:
verdict κ=0.91, type match κ=0.84, reasoning κ=0.78. Human-judge correlation:
ρ=0.87 (p<0.001), 85% agreement, validating automated evaluation.
```

**After (current):**
```latex
Two security experts validated judge verdicts across 31 samples (116 model-sample
comparisons), achieving 92\% agreement (κ=0.84, ρ=0.85, p<0.0001). The judge
demonstrated perfect recall (100\%) with 84\% precision (F1=0.91), validating
automated evaluation.
```

### appendix.tex (lines 181-189) - UPDATED
**Before:**
```latex
Twenty responses spanning all transformations and difficulty levels underwent
independent review by two security experts. Validators assessed:
- Verdict correctness (binary)
- Target finding accuracy (binary)
- Reasoning quality scores (0-1 scale for RCIR, AVA, FSV)

Inter-rater reliability: verdict κ=0.91, type match κ=0.84, reasoning κ=0.78.
Human-judge correlation: Pearson's ρ=0.87 (p<0.001) with 85% decision agreement.
```

**After (current):**
```latex
Thirty-one unique samples across all models and transformations underwent
independent validation by two security experts, yielding 116 expert-judge
comparisons (27 and 15 unique samples per expert, with 11 overlapping).
Validators assessed:
- Target detection accuracy (binary)
- Vulnerability type classification
- Reasoning quality (RCIR, AVA, FSV scores)

Expert-judge agreement: 92.2\% (κ=0.84, almost perfect) with F1=0.91
(precision=0.84, recall=1.00). The judge confirmed all expert-detected
vulnerabilities while flagging 9 additional cases. Type classification showed
85\% agreement when both detected the target. Pearson correlation: ρ=0.85 (p<0.0001).
```

### Formulas (lines 364-376) - NO CHANGES NEEDED
The Cohen's Kappa and Pearson correlation formulas are correct.
