# Comprehensive Model Evaluation Metrics

**Generated:** 2025-12-22T00:58:44.963785

**Total Samples:** 405
**Unique Samples:** 58
**Models Evaluated:** claude_opus_4.5, deepseek_v3.2, gemini_3_pro_preview, gpt-5.2, grok_4, llama_3.1_405b

---

## 🏆 Model Rankings

### By Target Detection Rate

| Rank | Model | Detection Rate | Samples |
|------|-------|----------------|---------|
| 1 | gemini_3_pro_preview | 57.6% | 66 |
| 2 | gpt-5.2 | 55.9% | 68 |
| 3 | claude_opus_4.5 | 52.9% | 68 |
| 4 | grok_4 | 44.1% | 68 |
| 5 | deepseek_v3.2 | 38.2% | 68 |
| 6 | llama_3.1_405b | 17.9% | 67 |

### By Quality Score (RCIR/AVA/FSV)

| Rank | Model | Avg Quality | Samples with Target |
|------|-------|-------------|---------------------|
| 1 | grok_4 | 0.983 | 30 |
| 2 | claude_opus_4.5 | 0.979 | 36 |
| 3 | gpt-5.2 | 0.974 | 38 |
| 4 | gemini_3_pro_preview | 0.963 | 38 |
| 5 | deepseek_v3.2 | 0.896 | 26 |
| 6 | llama_3.1_405b | 0.868 | 12 |

### By Finding Precision

| Rank | Model | Avg Precision |
|------|-------|---------------|
| 1 | gpt-5.2 | 76.6% |
| 2 | gemini_3_pro_preview | 71.5% |
| 3 | grok_4 | 68.4% |
| 4 | claude_opus_4.5 | 65.9% |
| 5 | deepseek_v3.2 | 58.9% |
| 6 | llama_3.1_405b | 20.4% |

---

## 📊 Detailed Metrics by Model

### claude_opus_4.5

**Detection Metrics:**
- Accuracy: 83.8%
- Precision: 100.0%
- Recall: 83.8%
- F1 Score: 0.912

**Target Detection:**
- Detection Rate: 52.9%
- Targets Found: 36 / 68

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.979
- AVA (Attack Vector): 0.993
- FSV (Fix Suggestion): 0.965
- Overall Quality: 0.979

**Finding Quality:**
- Avg Finding Precision: 65.9%
- Hallucination Rate: 0.0%
- Avg Findings/Sample: 3.5

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 20.0% | 1.000 | 22.0% |
| direct | 58.6% | 0.978 | 74.5% |
| naturalistic | 20.0% | 1.000 | 10.0% |

---

### deepseek_v3.2

**Detection Metrics:**
- Accuracy: 82.4%
- Precision: 100.0%
- Recall: 82.4%
- F1 Score: 0.903

**Target Detection:**
- Detection Rate: 38.2%
- Targets Found: 26 / 68

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.910
- AVA (Attack Vector): 0.915
- FSV (Fix Suggestion): 0.863
- Overall Quality: 0.896

**Finding Quality:**
- Avg Finding Precision: 58.9%
- Hallucination Rate: 2.5%
- Avg Findings/Sample: 3.0

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 20.0% | 0.417 | 6.7% |
| direct | 41.4% | 0.919 | 68.1% |
| naturalistic | 20.0% | 0.833 | 5.0% |

---

### gemini_3_pro_preview

**Detection Metrics:**
- Accuracy: 93.9%
- Precision: 100.0%
- Recall: 93.9%
- F1 Score: 0.969

**Target Detection:**
- Detection Rate: 57.6%
- Targets Found: 38 / 66

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.967
- AVA (Attack Vector): 0.974
- FSV (Fix Suggestion): 0.947
- Overall Quality: 0.963

**Finding Quality:**
- Avg Finding Precision: 71.5%
- Hallucination Rate: 0.6%
- Avg Findings/Sample: 2.6

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 40.0% | 0.708 | 22.7% |
| direct | 60.7% | 0.985 | 80.1% |
| naturalistic | 40.0% | 0.833 | 24.0% |

---

### gpt-5.2

**Detection Metrics:**
- Accuracy: 75.0%
- Precision: 100.0%
- Recall: 75.0%
- F1 Score: 0.857

**Target Detection:**
- Detection Rate: 55.9%
- Targets Found: 38 / 68

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.974
- AVA (Attack Vector): 0.980
- FSV (Fix Suggestion): 0.967
- Overall Quality: 0.974

**Finding Quality:**
- Avg Finding Precision: 76.6%
- Hallucination Rate: 1.2%
- Avg Findings/Sample: 2.4

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 40.0% | 0.833 | 10.7% |
| direct | 58.6% | 0.993 | 86.2% |
| naturalistic | 40.0% | 0.792 | 31.5% |

---

### grok_4

**Detection Metrics:**
- Accuracy: 69.1%
- Precision: 100.0%
- Recall: 69.1%
- F1 Score: 0.817

**Target Detection:**
- Detection Rate: 44.1%
- Targets Found: 30 / 68

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.983
- AVA (Attack Vector): 1.000
- FSV (Fix Suggestion): 0.967
- Overall Quality: 0.983

**Finding Quality:**
- Avg Finding Precision: 68.4%
- Hallucination Rate: 1.4%
- Avg Findings/Sample: 2.1

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 20.0% | 1.000 | 4.0% |
| direct | 46.6% | 0.981 | 77.3% |
| naturalistic | 40.0% | 1.000 | 30.2% |

---

### llama_3.1_405b

**Detection Metrics:**
- Accuracy: 88.1%
- Precision: 100.0%
- Recall: 88.1%
- F1 Score: 0.937

**Target Detection:**
- Detection Rate: 17.9%
- Targets Found: 12 / 67

**Quality Scores (when target found):**
- RCIR (Root Cause): 0.875
- AVA (Attack Vector): 0.896
- FSV (Fix Suggestion): 0.833
- Overall Quality: 0.868

**Finding Quality:**
- Avg Finding Precision: 20.4%
- Hallucination Rate: 5.2%
- Avg Findings/Sample: 2.0

**By Prompt Type:**
| Prompt | Detection Rate | Quality Score | Finding Precision |
|--------|----------------|---------------|-------------------|
| adversarial | 0.0% | N/A | 0.0% |
| direct | 19.0% | 0.856 | 23.3% |
| naturalistic | 25.0% | 1.000 | 3.6% |

---
