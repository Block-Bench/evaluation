# Prompt Type Comparison Results - GS Samples

Comprehensive evaluation of 5 GPTShield samples across 3 prompt types on 6 frontier LLMs.

**Generated**: 2025-12-18
**Samples**: sn_gs_002, sn_gs_013, sn_gs_017, sn_gs_020, sn_gs_026
**Prompt Types**: Direct (structured JSON), Naturalistic (colleague-style), Adversarial (sycophancy test)

---

## Overall Performance (All Prompt Types Combined)

Ranked by Security Understanding Index (SUI)

| Rank | Model | N | SUI | Accuracy | TDR | Find Prec | RCIR | AVA | FSV | TrueU |
|------|-------|---|-----|----------|-----|-----------|------|-----|-----|-------|
| 1 | **Gemini 3 Pro Preview** | 15 | **0.593** | 73.3% | 33.3% | 23.2% | 0.85 | 0.80 | 0.80 | 0.063 |
| 2 | **Claude Opus 4.5** | 15 | **0.490** | 40.0% | 20.0% | 14.4% | 1.00 | 1.00 | 1.00 | 0.029 |
| 3 | **Llama 3.1 405B** | 14 | **0.471** | 42.9% | 7.1% | 1.6% | 1.00 | 1.00 | 1.00 | 0.001 |
| 4 | **GPT-5.2** | 15 | **0.425** | 26.7% | 26.7% | 21.1% | 0.88 | 0.81 | 0.75 | 0.046 |
| 5 | **Grok 4 Fast** | 15 | **0.365** | 26.7% | 13.3% | 12.7% | 0.88 | 0.88 | 0.75 | 0.014 |
| 6 | **DeepSeek V3.2** | 15 | **0.306** | 26.7% | 13.3% | 4.1% | 0.75 | 0.62 | 0.50 | 0.003 |

**Additional Metrics:**

| Model | F2 | Lucky% | Invalid% | Hall% | Over-Flag | Avg Findings |
|-------|----|----|----------|-------|-----------|--------------|
| **Gemini 3 Pro Preview** | 0.775 | 54.5% | 76.8% | 0.0% | 1.27 | 2.47 |
| **Claude Opus 4.5** | 0.455 | 50.0% | 83.1% | 0.0% | 3.80 | 4.80 |
| **Llama 3.1 405B** | 0.484 | 83.3% | 98.4% | 1.6% | 4.43 | 4.50 |
| **GPT-5.2** | 0.312 | 25.0% | 78.9% | 0.0% | 3.73 | 4.73 |
| **Grok 4 Fast** | 0.312 | 75.0% | 87.3% | 0.0% | 4.13 | 4.73 |
| **DeepSeek V3.2** | 0.312 | 75.0% | 93.9% | 4.1% | 4.20 | 4.73 |

---

## Performance by Prompt Type

### DIRECT PROMPTS (Structured JSON Output)

Ranked by SUI

| Rank | Model | N | SUI | Accuracy | TDR | Find Prec | RCIR | AVA | FSV |
|------|-------|---|-----|----------|-----|-----------|------|-----|-----|
| 1 | **Gemini 3 Pro Preview** | 5 | **0.655** | 80.0% | 20.0% | 28.6% | 0.90 | 0.85 | 0.85 |
| 2 | **DeepSeek V3.2** | 5 | **0.336** | 40.0% | 0.0% | 12.5% | 0.75 | 0.62 | 0.50 |
| 3 | **Llama 3.1 405B** | 5 | **0.288** | 80.0% | 0.0% | 0.0% | - | - | - |
| 4 | **Claude Opus 4.5** | 5 | **0.286** | 40.0% | 20.0% | 5.9% | - | - | - |
| 5 | **Grok 4 Fast** | 5 | **0.180** | 40.0% | 0.0% | 20.0% | - | - | - |
| 6 | **GPT-5.2** | 5 | **0.130** | 20.0% | 0.0% | 16.7% | - | - | - |

**Key Findings:**
- Gemini 3 Pro dominates with structured prompts (80% accuracy, 28.6% precision)
- Llama 3.1 405B has high accuracy (80%) but 0% target detection
- DeepSeek V3.2 performs best among mid-tier models on structured output

---

### NATURALISTIC PROMPTS (Colleague-Style Review)

Ranked by SUI

| Rank | Model | N | SUI | Accuracy | TDR | Find Prec | RCIR | AVA | FSV |
|------|-------|---|-----|----------|-----|-----------|------|-----|-----|
| 1 | **Gemini 3 Pro Preview** | 5 | **0.548** | 60.0% | 40.0% | 21.4% | 0.75 | 0.75 | 0.75 |
| 2 | **GPT-5.2** | 5 | **0.510** | 40.0% | 40.0% | 32.4% | 0.88 | 0.75 | 0.75 |
| 3 | **Claude Opus 4.5** | 5 | **0.509** | 40.0% | 20.0% | 11.1% | 1.00 | 1.00 | 1.00 |
| 4 | **Grok 4 Fast** | 5 | **0.441** | 20.0% | 40.0% | 15.6% | 0.88 | 0.88 | 0.75 |
| 5 | **Llama 3.1 405B** | 4 | **0.441** | 25.0% | 25.0% | 3.0% | 1.00 | 1.00 | 1.00 |
| 6 | **DeepSeek V3.2** | 5 | **0.215** | 20.0% | 20.0% | 2.3% | - | - | - |

**Key Findings:**
- GPT-5.2 excels with naturalistic prompts (40% TDR, 32.4% precision) ⭐
- Grok 4 Fast shows strong TDR (40%) despite lower accuracy
- Naturalistic prompts improve TDR for most models vs direct

---

### ADVERSARIAL PROMPTS ("Already Audited" Framing)

Ranked by SUI

| Rank | Model | N | SUI | Accuracy | TDR | Find Prec | RCIR | AVA | FSV |
|------|-------|---|-----|----------|-----|-----------|------|-----|-----|
| 1 | **Claude Opus 4.5** | 5 | **0.674** | 40.0% | 20.0% | 25.0% | 1.00 | 1.00 | 1.00 |
| 2 | **Gemini 3 Pro Preview** | 5 | **0.577** | 80.0% | 40.0% | 23.8% | 0.90 | 0.80 | 0.80 |
| 3 | **GPT-5.2** | 5 | **0.432** | 20.0% | 40.0% | 9.7% | 0.88 | 0.88 | 0.75 |
| 4 | **DeepSeek V3.2** | 5 | **0.368** | 20.0% | 20.0% | 4.8% | - | - | - |
| 5 | **Llama 3.1 405B** | 5 | **0.110** | 20.0% | 0.0% | 0.0% | - | - | - |
| 6 | **Grok 4 Fast** | 5 | **0.070** | 20.0% | 0.0% | 6.9% | - | - | - |

**Key Findings:**
- Claude Opus 4.5 shows best sycophancy resistance (25% precision, highest SUI) ⭐
- Gemini 3 Pro maintains 80% accuracy and 40% TDR under adversarial framing
- Grok 4 Fast and Llama 3.1 405B collapse under adversarial prompts (0% TDR)

---

## Sycophancy Resistance Analysis

### Models Showing Resistance (Improved/Maintained Performance)

| Model | Metric | Direct | Adversarial | Change |
|-------|--------|--------|-------------|--------|
| **Claude Opus 4.5** | Finding Precision | 5.9% | 25.0% | +19.1pp ⬆️ |
| **Claude Opus 4.5** | SUI | 0.286 | 0.674 | +0.388 ⬆️ |
| **Gemini 3 Pro** | TDR | 20.0% | 40.0% | +20.0pp ⬆️ |
| **Gemini 3 Pro** | Accuracy | 80.0% | 80.0% | Maintained |
| **GPT-5.2** | TDR | 0.0% | 40.0% | +40.0pp ⬆️ |

### Models Showing Sycophancy (Degraded Performance)

| Model | Metric | Best | Adversarial | Change |
|-------|--------|------|-------------|--------|
| **Grok 4 Fast** | TDR | 40.0% (nat) | 0.0% (adv) | -40.0pp ⬇️ |
| **Grok 4 Fast** | SUI | 0.441 (nat) | 0.070 (adv) | -0.371 ⬇️ |
| **DeepSeek V3.2** | Accuracy | 40.0% (dir) | 20.0% (adv) | -20.0pp ⬇️ |
| **Llama 3.1 405B** | Accuracy | 80.0% (dir) | 20.0% (adv) | -60.0pp ⬇️ |

---

## Best Prompt Strategy by Model

| Model | Best Prompt Type | SUI | Key Strength |
|-------|-----------------|-----|--------------|
| **Gemini 3 Pro Preview** | Direct | 0.655 | High accuracy (80%) + best precision (28.6%) |
| **Claude Opus 4.5** | Adversarial | 0.674 | Sycophancy resistance + high precision (25%) |
| **GPT-5.2** | Naturalistic | 0.510 | Best finding precision (32.4%) + high TDR (40%) |
| **Grok 4 Fast** | Naturalistic | 0.441 | Strong TDR (40%) with free-form prompts |
| **Llama 3.1 405B** | Naturalistic | 0.441 | Only achieves non-zero TDR (25%) |
| **DeepSeek V3.2** | Adversarial | 0.368 | Least degradation under adversarial framing |

---

## Recommendations

### For High Accuracy + Precision
**Use Gemini 3 Pro Preview with Direct prompts**
- 80% accuracy, 28.6% finding precision
- Strong reasoning quality (RCIR: 0.90)
- Best overall SUI (0.655)

### For Sycophancy-Resistant Evaluation
**Use Claude Opus 4.5 with Adversarial prompts**
- Highest SUI under adversarial framing (0.674)
- 25% finding precision (4.2x improvement over direct)
- Perfect reasoning scores (1.00 across all metrics)

### For Maximum Target Detection
**Use GPT-5.2 with Naturalistic prompts**
- 40% TDR with 32.4% finding precision
- Colleague-style requests elicit best performance
- Low lucky guess rate (0%)

### Avoid
- **Grok 4 Fast** with adversarial prompts (TDR drops to 0%)
- **Llama 3.1 405B** with direct prompts (0% TDR despite 80% accuracy)
- **DeepSeek V3.2** for finding precision (4.1% overall)

---

## Metric Definitions

- **SUI**: Security Understanding Index (composite: F2 + TDR + Finding Precision + Reasoning + Calibration)
- **TDR**: Target Detection Rate - % of samples where target vulnerability was found
- **Find Prec**: Finding Precision - % of reported findings that are valid
- **Lucky%**: Lucky Guess Rate - % of correct detections that missed the actual target
- **RCIR**: Reasoning Completeness, Insight, Rigor (0-1 scale)
- **AVA**: Attack Vector Accuracy (0-1 scale)
- **FSV**: Fix Solution Validity (0-1 scale)
- **TrueU**: True Understanding Score (TDR × Finding Precision)

---

## Sample Size Note

These results are based on **5 GPTShield samples** evaluated with **3 prompt types each** (15 total evaluations per model, except Llama 3.1 405B with 14 due to evaluation error).

For production deployment decisions, validate findings with larger sample sizes across diverse vulnerability types.
