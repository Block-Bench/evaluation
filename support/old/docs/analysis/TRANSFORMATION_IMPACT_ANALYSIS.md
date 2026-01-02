# Transformation Impact Analysis - TC Samples

Analysis of how code transformations (sanitized, medical, shapeshifter, etc.) affected model performance on Temporal Contamination samples.

**Generated**: 2025-12-18
**Base Samples**: 5 TC samples
**Transformations**: Original, Sanitized, Medical (Chameleon), Shapeshifter, Hydra, No-Comments

---

## Executive Summary

**Key Finding**: All models show dramatic performance degradation on **sanitized** variants compared to other transformations.

### Transformation Difficulty Ranking (Across All Models)

1. **Easiest**: Original (nocomments_original) - 80-100% accuracy, 20-60% TDR
2. **Moderate**: Chameleon Medical, Hydra, Shapeshifter, No-Comments - 57-100% accuracy, 14-85% TDR
3. **Hardest**: Sanitized - 43-83% accuracy, 8-32% TDR ⚠️

**The Sanitization Effect**: Sanitized variants cause:
- **44-50%** accuracy drop (some models)
- **40-60%** TDR reduction
- **50-80%** finding precision decrease
- Increased lucky guesses (models detect vulnerability but miss target)

---

## Model-by-Model Analysis

### 1. Claude Opus 4.5

**Overall Pattern**: Strong on all transformations EXCEPT sanitized variants

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 100.0% | 60.0% | 40.0% | 92.3% | 1.00/1.00/1.00 |
| **hydra_restructure** | 7 | 100.0% | **85.7%** ⭐ | 14.3% | 68.2% | 1.00/1.00/1.00 |
| **nocomments** | 7 | 100.0% | **85.7%** ⭐ | 14.3% | 76.2% | 1.00/1.00/1.00 |
| **chameleon_medical** | 12 | 100.0% | 66.7% | 33.3% | 82.9% | 0.97/1.00/0.97 |
| **shapeshifter_l3_medium** | 12 | 100.0% | 58.3% | 41.7% | 69.7% | 1.00/1.00/1.00 |
| **sanitized** | 25 | 56.0% ⬇️ | 24.0% ⬇️ | 57.1% | 27.7% ⬇️ | 0.92/0.96/0.83 |

**What Happened**:
- ✅ **Perfect accuracy** (100%) on ALL non-sanitized transformations
- ✅ **High TDR** (60-85.7%) on original, hydra, and no-comments variants
- ✅ **Excellent finding precision** (68-92%) on complex transformations
- ⚠️ **Massive degradation** on sanitized: 56% accuracy, 24% TDR, 27.7% precision
- ⚠️ **Lucky guess rate spikes** to 57.1% on sanitized (vs 14-41% on others)

**Interpretation**: Claude Opus 4.5 excels at understanding complex transformations (medical domain, restructured code) but struggles when contextual clues are removed (sanitized). The high lucky guess rate on sanitized suggests it detects *something is wrong* but can't pinpoint the specific vulnerability.

---

### 2. DeepSeek V3.2

**Overall Pattern**: Moderate performance on complex transformations, poor on sanitized

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 100.0% | 60.0% | 40.0% | **90.0%** ⭐ | 0.92/0.92/0.83 |
| **hydra_restructure** | 7 | 100.0% | 57.1% | 42.9% | 73.7% | 0.94/1.00/0.94 |
| **nocomments** | 7 | 100.0% | 57.1% | 42.9% | 47.4% | 0.94/0.94/1.00 |
| **chameleon_medical** | 12 | 100.0% | 33.3% | 66.7% | 67.7% | 0.94/0.94/0.94 |
| **shapeshifter_l3_medium** | 12 | 100.0% | 50.0% | 50.0% | 64.5% | 0.90/0.92/0.87 |
| **sanitized** | 25 | 52.0% ⬇️ | 20.0% ⬇️ | 64.3% | 18.1% ⬇️ | 0.85/0.80/0.65 |

**What Happened**:
- ✅ **Perfect accuracy** (100%) on all non-sanitized transformations
- ⚠️ **High lucky guess rates** across the board (40-67%), even on non-sanitized
- ⚠️ **Lower TDR** (33-60%) compared to Claude, even on easy variants
- ⚠️ **Sanitized collapse**: 52% accuracy, 20% TDR, 18.1% precision
- ⚠️ **Finding precision** drops to 18.1% on sanitized (vs 47-90% elsewhere)

**Interpretation**: DeepSeek V3.2 correctly detects vulnerabilities exist (100% accuracy on complex variants) but struggles to identify the *specific* target vulnerability. This explains consistently high lucky guess rates. Sanitization exacerbates this weakness dramatically.

---

### 3. Gemini 3 Pro Preview

**Overall Pattern**: Best overall performance, resilient to most transformations

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 100.0% | 60.0% | 40.0% | **100.0%** ⭐ | 1.00/1.00/1.00 |
| **hydra_restructure** | 7 | 100.0% | **85.7%** ⭐ | 14.3% | **92.9%** | 1.00/1.00/1.00 |
| **nocomments** | 7 | 100.0% | **85.7%** ⭐ | 14.3% | 68.8% | 1.00/1.00/1.00 |
| **chameleon_medical** | 11 | 100.0% | 72.7% | 27.3% | 84.0% | 1.00/1.00/1.00 |
| **shapeshifter_l3_medium** | 12 | 100.0% | 66.7% | 33.3% | 78.6% | 0.94/1.00/0.91 |
| **sanitized** | 24 | 83.3% | 29.2% ⬇️ | 65.0% | 39.0% ⬇️ | 0.89/0.86/0.82 |

**What Happened**:
- ✅ **Perfect accuracy** (100%) on ALL non-sanitized transformations
- ✅ **Highest TDR** (85.7%) on hydra and no-comments
- ✅ **Exceptional precision** (84-100%) on complex transformations
- ✅ **Most resilient to sanitization**: 83.3% accuracy (vs 43-66% for others)
- ⚠️ **TDR still drops** to 29.2% on sanitized (vs 60-85.7% elsewhere)
- ⚠️ **Lucky guess rate spikes** to 65% on sanitized

**Interpretation**: Gemini 3 Pro shows the best overall robustness. It maintains high accuracy even on sanitized variants (83.3%), though TDR still suffers. Perfect precision on original variants demonstrates strong vulnerability understanding.

---

### 4. GPT-5.2

**Overall Pattern**: Excellent on complex transformations, moderate on sanitized

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 80.0% | 60.0% | 25.0% | 88.9% | 1.00/1.00/1.00 |
| **hydra_restructure** | 7 | 100.0% | 71.4% | 28.6% | **100.0%** ⭐ | 1.00/1.00/1.00 |
| **nocomments** | 7 | 100.0% | **85.7%** ⭐ | 14.3% | **100.0%** ⭐ | 1.00/1.00/1.00 |
| **chameleon_medical** | 12 | 91.7% | 58.3% | 36.4% | **95.0%** | 0.96/1.00/0.96 |
| **shapeshifter_l3_medium** | 12 | 91.7% | **75.0%** | 18.2% | 84.0% | 0.97/1.00/1.00 |
| **sanitized** | 25 | 44.0% ⬇️ | 32.0% | 33.3% | 31.8% ⬇️ | 0.94/0.91/0.88 |

**What Happened**:
- ✅ **Perfect finding precision** (100%) on hydra and no-comments
- ✅ **Excellent TDR** (58-85.7%) on all non-sanitized variants
- ✅ **Low lucky guess rates** (14-36%) on complex transformations
- ✅ **Best sanitized TDR** (32%) among all models
- ⚠️ **Accuracy drops** to 44% on sanitized (vs 80-100% elsewhere)
- ⚠️ **Precision drops** to 31.8% on sanitized (vs 84-100% elsewhere)

**Interpretation**: GPT-5.2 shows exceptional precision on complex transformations (100% on hydra/no-comments). While sanitization still hurts (44% accuracy), it maintains the highest TDR (32%) on sanitized variants among all models. This suggests better core vulnerability understanding that persists even without context.

---

### 5. Llama 3.1 405B

**Overall Pattern**: Consistently poor TDR across ALL transformations

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 100.0% | 20.0% | 80.0% ⚠️ | 57.1% | 0.75/0.75/0.50 |
| **hydra_restructure** | 7 | 100.0% | 28.6% | 71.4% | 22.2% | 1.00/1.00/1.00 |
| **nocomments** | 7 | 100.0% | 14.3% ⬇️ | 85.7% ⚠️ | 25.0% | 1.00/1.00/1.00 |
| **chameleon_medical** | 12 | 100.0% | 25.0% | 75.0% | 29.4% | 0.83/0.92/0.75 |
| **shapeshifter_l3_medium** | 12 | 100.0% | 25.0% | 75.0% | 22.2% | 0.83/0.83/0.92 |
| **sanitized** | 24 | 66.7% ⬇️ | **8.3%** ⬇️⬇️ | 87.5% ⚠️ | **5.3%** ⬇️⬇️ | 0.88/0.88/0.75 |

**What Happened**:
- ✅ **High accuracy** (100%) on non-sanitized transformations
- ⚠️ **Consistently low TDR** (14-28%) even on "easy" variants
- ⚠️ **Extremely high lucky guess rates** (71-87%) across ALL transformations
- ⚠️ **Catastrophic sanitized performance**: 8.3% TDR, 5.3% precision
- ⚠️ **Lucky guess rate 87.5%** on sanitized (highest of all models)

**Interpretation**: Llama 3.1 405B can detect that vulnerabilities exist (100% accuracy on complex variants) but almost never identifies the *target* vulnerability correctly. The 80-87% lucky guess rates reveal a fundamental weakness in targeted vulnerability analysis. Sanitization amplifies this to near-total failure (8.3% TDR).

---

### 6. Grok 4 Fast

**Overall Pattern**: Highly variable, struggles with most transformations

| Transformation | N | Accuracy | TDR | Lucky% | Find Prec | RCIR/AVA/FSV |
|---------------|---|----------|-----|--------|-----------|--------------|
| **nocomments_original** | 5 | 80.0% | **60.0%** ⭐ | 25.0% | 77.8% | 1.00/1.00/1.00 |
| **hydra_restructure** | 7 | 57.1% ⬇️ | 14.3% | 75.0% | 27.3% | 1.00/1.00/1.00 |
| **nocomments** | 7 | 71.4% | 14.3% | 80.0% | 45.5% | 1.00/1.00/1.00 |
| **chameleon_medical** | 12 | 66.7% | 33.3% | 50.0% | 39.4% | 1.00/1.00/0.94 |
| **shapeshifter_l3_medium** | 12 | 75.0% | 50.0% | 40.0% | 56.5% | 0.92/0.88/0.79 |
| **sanitized** | 23 | 43.5% ⬇️ | 21.7% | 54.5% | 20.3% ⬇️ | 0.90/0.85/0.80 |

**What Happened**:
- ✅ **Best performance** on original variants (60.0% TDR, 77.8% precision)
- ⚠️ **Accuracy drops** to 57-75% even on non-sanitized transformations
- ⚠️ **TDR drops** to 14-33% on complex transformations (medical, hydra)
- ⚠️ **Sanitized collapse**: 43.5% accuracy, 21.7% TDR, 20.3% precision
- ⚠️ **High variability** across transformation types

**Interpretation**: Grok 4 Fast performs reasonably on original TC samples but struggles when code is transformed in any way. Even "simple" transformations like adding medical domain context or restructuring code cause significant performance drops. This suggests shallow pattern matching rather than deep vulnerability understanding.

---

## Cross-Model Insights

### 1. The Sanitization Catastrophe

**Why Sanitized Variants Are So Hard:**

Sanitization removes contextual clues that models rely on:
- Variable/function names lose semantic meaning
- Comments and documentation removed
- Domain-specific terminology neutralized
- Code structure may be simplified

**Impact by Model:**

| Model | Accuracy Drop | TDR Drop | Precision Drop |
|-------|--------------|----------|----------------|
| **Claude Opus 4.5** | -44.0pp | -61.7pp | -64.6pp |
| **DeepSeek V3.2** | -48.0pp | -40.0pp | -71.9pp |
| **Gemini 3 Pro** | -16.7pp | -56.5pp | -61.0pp |
| **GPT-5.2** | -56.0pp | -53.7pp | -68.2pp |
| **Llama 3.1 405B** | -33.3pp | -19.7pp | -51.8pp |
| **Grok 4 Fast** | -36.5pp | -38.3pp | -57.5pp |

**Winner**: Gemini 3 Pro (smallest accuracy drop: -16.7pp)
**Biggest Struggles**: GPT-5.2 (-56pp accuracy), Claude Opus 4.5 (-61.7pp TDR)

### 2. Complex Transformation Resilience

**Models Ranked by Performance on Complex Transformations (Medical, Shapeshifter, Hydra):**

1. **Gemini 3 Pro**: 100% accuracy, 66-85.7% TDR, 69-92% precision
2. **Claude Opus 4.5**: 100% accuracy, 58-85.7% TDR, 68-83% precision
3. **GPT-5.2**: 92-100% accuracy, 58-85.7% TDR, 84-100% precision
4. **DeepSeek V3.2**: 100% accuracy, 33-60% TDR, 47-90% precision
5. **Grok 4 Fast**: 57-80% accuracy, 14-60% TDR, 27-78% precision
6. **Llama 3.1 405B**: 100% accuracy, 14-29% TDR, 22-57% precision

**Insight**: Accuracy alone is misleading. Llama maintains 100% accuracy but only 14-29% TDR, indicating it detects "something wrong" but rarely the target vulnerability.

### 3. Lucky Guess Patterns

**High Lucky Guess Rates Indicate:**
- Model detects vulnerability exists (correct verdict)
- But identifies wrong vulnerability (missed target)
- Suggests weak vulnerability localization

**Models by Lucky Guess Rate (Sanitized):**

1. Llama 3.1 405B: **87.5%** (catastrophic)
2. Gemini 3 Pro: 65.0%
3. DeepSeek V3.2: 64.3%
4. Claude Opus 4.5: 57.1%
5. Grok 4 Fast: 54.5%
6. GPT-5.2: **33.3%** (best)

**Winner**: GPT-5.2 - Even on sanitized variants, when it detects a vulnerability, it's more likely to find the actual target (66.7% success rate vs 12.5% for Llama).

---

## Recommendations

### For Original/Baseline Evaluation
**Use**: Claude Opus 4.5, Gemini 3 Pro, or GPT-5.2
- All achieve 80-100% accuracy and 60% TDR on original samples
- GPT-5.2 has lowest lucky guess rate (25%)

### For Robustness Testing (Complex Transformations)
**Use**: Gemini 3 Pro or GPT-5.2
- Gemini: 100% accuracy across all complex transformations
- GPT-5.2: 100% finding precision on hydra/no-comments variants

### For Worst-Case Evaluation (Sanitized/Minimal Context)
**Use**: Gemini 3 Pro or GPT-5.2
- Gemini: Best accuracy (83.3%) on sanitized
- GPT-5.2: Best TDR (32%) on sanitized

### Avoid
- **Llama 3.1 405B** for targeted vulnerability detection (71-87% lucky guess rates)
- **Grok 4 Fast** for complex transformations (accuracy drops to 57-75%)
- **Any model** on sanitized variants without explicit training/prompting for obfuscated code

---

## Transformation Type Definitions

| Transformation | Description | Purpose |
|---------------|-------------|---------|
| **nocomments_original** | Original TC samples with comments removed | Baseline without documentation |
| **sanitized** | Variable names neutralized, comments removed | Test reliance on semantic cues |
| **chameleon_medical** | Domain shifted to medical/healthcare context | Test domain transfer understanding |
| **shapeshifter_l3_medium** | Code structure transformed while preserving logic | Test structural robustness |
| **hydra_restructure** | Code reorganized and refactored | Test code comprehension depth |
| **nocomments** | Comments removed but semantics preserved | Test documentation dependency |

---

## Conclusion

**The Sanitization Problem** reveals that most LLMs heavily rely on contextual clues (variable names, comments, domain context) for vulnerability detection. When these cues are removed:

- **Performance collapses** across all models (8-32% TDR on sanitized)
- **Lucky guesses dominate** (models detect "something" but not the target)
- **Finding precision plummets** (5-39% vs 47-100% on complex variants)

**Only Gemini 3 Pro** shows moderate resilience to sanitization (83.3% accuracy), but even it suffers severe TDR degradation (29.2%).

This has critical implications for real-world security auditing:
- **Obfuscated/minified code** will be extremely difficult for current LLMs
- **Legacy codebases** with poor naming may see similar degradation
- **Cross-domain code** (e.g., analyzing medical contracts when trained on DeFi) shows surprising resilience for top models
