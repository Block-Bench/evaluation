# Table 1: Detection Results (DS + TC Benchmarks)

**Evaluation Method:** Majority vote across 3 LLM judges (GLM-4.7, MIMO-v2-Flash, Mistral-Large)

| Model | DS-T1 | DS-T2 | DS-T3 | DS-T4 | DS-Avg | MinSan | San | NoCom | Cham | Shape | Troj | FalseP | TC-Avg |
|-------|------:|------:|------:|------:|-------:|-------:|----:|------:|-----:|------:|-----:|-------:|-------:|
| Claude | **100.0** | **83.8** | **70.0** | 92.3 | **86.5** | **71.7** | **54.3** | **50.0** | **43.5** | **50.0** | 32.6 | **54.3** | **50.9** |
| Gemini | 75.0 | 78.4 | 50.0 | **92.3** | 73.9 | 65.2 | 28.3 | 32.6 | 37.0 | 34.8 | 34.8 | 37.0 | 38.5 |
| DeepSeek | 65.0 | 64.9 | 46.7 | 61.5 | 59.5 | 58.7 | 37.0 | 41.3 | 21.7 | 26.1 | **43.5** | 30.4 | 37.0 |
| GPT-5.2 | 60.0 | 70.3 | 36.7 | 84.6 | 62.9 | 54.3 | 34.8 | 37.0 | 28.3 | 30.4 | 30.4 | 37.0 | 36.0 |
| Llama | 65.0 | 45.9 | 40.0 | 69.2 | 55.0 | 52.2 | 39.1 | 30.4 | 21.7 | 13.0 | **43.5** | 21.7 | 31.7 |
| Qwen | 60.0 | 56.8 | 43.3 | 53.8 | 53.5 | 56.5 | 43.5 | 30.4 | 15.2 | 17.4 | 28.3 | 41.3 | 33.2 |
| Grok | 40.0 | 37.8 | 33.3 | 30.8 | 35.5 | 32.6 | 23.9 | 19.6 | 15.2 | 15.2 | 21.7 | 21.7 | 21.4 |

---

## Inter-Annotator Agreement

Results were evaluated using a **majority vote protocol** with 3 LLM judges. Inter-judge agreement was measured using **Fleiss' kappa (κ)**.

### DS Agreement Summary

| Metric | T1 | T2 | T3 | T4 |
|--------|---:|---:|---:|---:|
| Mean κ | 0.60 | 0.68 | 0.65 | 0.60 |
| Range | -0.09–0.93 | 0.56–0.84 | 0.47–0.81 | 0.48–0.92 |

**Interpretation:** Substantial agreement (κ > 0.6) on DS dataset, indicating reliable majority vote estimates.

### TC Agreement Summary

| Metric | MinSan | San | NoCom | Cham | Shape | Troj | FalseP |
|--------|-------:|----:|------:|-----:|------:|-----:|-------:|
| Mean κ | 0.63 | 0.15 | 0.16 | 0.23 | 0.19 | 0.14 | 0.16 |
| Range | 0.54–0.77 | 0.04–0.29 | 0.06–0.36 | 0.13–0.36 | 0.08–0.27 | 0.04–0.32 | 0.05–0.32 |

**Interpretation:**
- **MinSan** shows substantial agreement (κ ≈ 0.63), similar to DS
- **Other TC variants** show slight-to-fair agreement (κ < 0.4), reflecting evaluation ambiguity introduced by code transformation
- Lower agreement on TC does not indicate unreliable results, but rather that obfuscated code creates semantic ambiguity that affects judge interpretation

---

## Column Definitions

**DS (Difficulty-Stratified):**
- **T1–T4**: Tiers 1–4 (increasing contract complexity)
- **DS-Avg**: Average across tiers

**TC (Temporal Contamination):**
- **MinSan**: Minimal sanitization (comments removed)
- **San**: Full sanitization (identifiers renamed)
- **NoCom**: Comments removed only
- **Cham**: Chameleon Medical (domain recontextualization)
- **Shape**: ShapeShifter L3 (code restructuring)
- **Troj**: Trojan (hidden vulnerability variants)
- **FalseP**: False Prophet (misleading comments)
- **TC-Avg**: Average across variants

---

## Notes

1. All values are **Target Detection Rate (TDR)** as percentages
2. TDR = samples where ≥2 of 3 judges agreed target vulnerability was found
3. **Bold** indicates best performance per column
4. DS samples are pre-2023 (before model training cutoffs)
5. TC samples use post-cutoff contracts with various obfuscation techniques to test genuine understanding vs. memorization
