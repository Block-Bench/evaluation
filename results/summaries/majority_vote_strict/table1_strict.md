# Table 1 (STRICT): Detection Results with Location Validation

**Evaluation Method:** Majority vote + rule-based location validation
**Judges:** GLM-4.7, MIMO-v2-Flash, Mistral-Large
**Strict Rule:** If judge marks target_found=true but location_match=false, verify location_claimed against ground truth. Override to false if no match.

## DS Results (Strict)

| Model | DS-T1 | DS-T2 | DS-T3 | DS-T4 | DS-Avg |
|-------|------:|------:|------:|------:|-------:|
| Claude | **100.0** | **83.8** | **66.7** | 92.3 | **85.7** |
| Gemini | 75.0 | 78.4 | 50.0 | **92.3** | 73.9 |
| GPT-5.2 | 60.0 | 70.3 | 36.7 | 84.6 | 62.9 |
| DeepSeek | 60.0 | 64.9 | 43.3 | 61.5 | 57.4 |
| Llama | 65.0 | 45.9 | 40.0 | 69.2 | 55.0 |
| Qwen | 55.0 | 56.8 | 43.3 | 53.8 | 52.2 |
| Grok | 40.0 | 37.8 | 33.3 | 30.8 | 35.5 |

---

## Comparison: Original vs Strict

| Model | Original Avg | Strict Avg | Difference |
|-------|-------------:|-----------:|-----------:|
| Claude | 86.5% | 85.7% | -0.8pp |
| DeepSeek | 59.5% | 57.4% | -2.1pp |
| Qwen | 53.5% | 52.2% | -1.2pp |
| Gemini | 73.9% | 73.9% | 0.0pp |
| GPT-5.2 | 62.9% | 62.9% | 0.0pp |
| Grok | 35.5% | 35.5% | 0.0pp |
| Llama | 55.0% | 55.0% | 0.0pp |

---

## Inter-Judge Agreement Comparison

| Model | Original κ (T3) | Strict κ (T3) | Change |
|-------|----------------:|--------------:|-------:|
| Claude | 0.53 | 0.60 | +0.07 |
| DeepSeek | 0.64 | 0.69 | +0.05 |
| Gemini | 0.47 | 0.51 | +0.04 |
| Grok | 0.69 | 0.73 | +0.04 |
| Llama | 0.72 | 0.77 | +0.05 |
| GPT-5.2 | 0.81 | 0.81 | 0.00 |
| Qwen | 0.72 | 0.72 | 0.00 |

---

## Key Findings

1. **Minimal Impact Overall**: Only 9 overrides out of 700 sample-judge pairs (1.3%)
2. **Most Affected Models**: DeepSeek (-2.1pp), Qwen (-1.2pp), Claude (-0.8pp)
3. **Tier 3 Most Affected**: Complex contracts show more location mismatches
4. **Agreement Improves**: Strict validation increases κ by 0.04-0.07 on T3
5. **Some Models Unaffected**: Gemini, GPT-5.2, Grok, Llama had no overrides

## Interpretation

The low override rate (1.3%) suggests judges are generally reliable on location matching.
However, the improvement in κ indicates that the overrides target genuine disagreement cases,
making the strict method slightly more consistent.
