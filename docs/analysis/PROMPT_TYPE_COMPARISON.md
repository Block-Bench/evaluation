# Prompt Type Comparison - GS Samples

Evaluation of 5 GPTShield samples across 3 prompt types:
- **Direct**: Structured JSON output with explicit vulnerability analysis request
- **Naturalistic**: Colleague-style review request (free-form output)
- **Adversarial**: "Already audited" framing to test sycophancy (free-form output)

Generated: 2025-12-18

---

## Performance by Prompt Type (5 GS Samples)

### Claude Opus 4.5

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | 40.0% | 20.0% | 5.9% |
| Naturalistic | 40.0% | 20.0% | 11.1% |
| Adversarial | 40.0% | 20.0% | **25.0%** ⬆️ |

**Insight**: Adversarial prompting improves finding precision despite accuracy staying constant.

---

### DeepSeek V3.2

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | **40.0%** | 0.0% | **12.5%** |
| Naturalistic | 20.0% | 20.0% | 2.3% |
| Adversarial | 20.0% | 20.0% | 4.8% |

**Insight**: Direct prompts work best for DeepSeek. Free-form prompts improve TDR but reduce precision.

---

### Gemini 3 Pro Preview

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | **80.0%** | 20.0% | **28.6%** |
| Naturalistic | 60.0% | **40.0%** | 21.4% |
| Adversarial | **80.0%** | **40.0%** | 23.8% |

**Insight**: Adversarial prompts achieve best overall performance - high accuracy AND high TDR.

---

### GPT-5.2

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | 20.0% | 0.0% | 16.7% |
| Naturalistic | **40.0%** | **40.0%** | **32.4%** |
| Adversarial | 20.0% | **40.0%** | 9.7% |

**Insight**: Naturalistic prompts dramatically improve all metrics. GPT-5.2 responds best to colleague-style requests.

---

### Llama 3.1 405B

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | **80.0%** | 0.0% | 0.0% |
| Naturalistic | **25.0%** | **25.0%** | **3.0%** |
| Adversarial | 20.0% | 0.0% | 0.0% |

**Insight**: Llama struggles with target detection across all prompt types. Naturalistic slightly improves TDR.

---

### Grok 4 Fast

| Prompt Type | Accuracy | Target Detection Rate | Finding Precision |
|-------------|----------|----------------------|-------------------|
| Direct | **40.0%** | 0.0% | **20.0%** |
| Naturalistic | 20.0% | **40.0%** | 15.6% |
| Adversarial | 20.0% | 0.0% | 6.9% |

**Insight**: Naturalistic prompts boost TDR significantly but reduce accuracy.

---

## Key Findings

### 1. Prompt Type Effectiveness by Model

**Best with Direct Prompts**:
- DeepSeek V3.2 (40% acc, 12.5% precision)
- Llama 3.1 405B (80% acc, but 0% TDR)

**Best with Naturalistic Prompts**:
- GPT-5.2 (40% acc, 40% TDR, 32.4% precision) ⭐
- Grok 4 Fast (40% TDR improvement)

**Best with Adversarial Prompts**:
- Gemini 3 Pro (80% acc, 40% TDR, 23.8% precision) ⭐
- Claude Opus 4.5 (25% precision improvement)

### 2. Sycophancy Resistance

Models that maintained or improved performance when told "already audited":
- **Gemini 3 Pro**: Maintained 80% accuracy, doubled TDR to 40%
- **Claude Opus 4.5**: Improved finding precision to 25%
- **GPT-5.2**: Maintained 40% TDR

Models showing sycophancy effects (degraded under adversarial):
- DeepSeek V3.2: Accuracy dropped from 40% → 20%
- Grok 4 Fast: TDR dropped from 40% → 0%
- Llama 3.1 405B: Minimal change (already poor TDR)

### 3. Target Detection Rate (TDR) Patterns

**Highest TDR improvements with natural/adversarial prompts**:
1. Gemini 3 Pro: 20% → 40% (2x improvement)
2. GPT-5.2: 0% → 40% (∞ improvement)
3. Grok 4 Fast: 0% → 40% (naturalistic only)

**Models with consistent low TDR**:
- Llama 3.1 405B: 0-25% across all types
- DeepSeek V3.2: 0-20% across all types

### 4. Finding Precision Patterns

**Best precision by prompt type**:
- Direct: DeepSeek V3.2 (12.5%)
- Naturalistic: GPT-5.2 (32.4%) ⭐
- Adversarial: Claude Opus 4.5 (25.0%)

---

## Recommendations

1. **For GPTShield-style samples**: Use naturalistic prompts with GPT-5.2 or adversarial prompts with Gemini 3 Pro
2. **For sycophancy-resistant evaluation**: Gemini 3 Pro and Claude Opus 4.5 show best resistance
3. **For structured outputs**: Direct prompts work best with DeepSeek V3.2
4. **Avoid**: Adversarial prompts with Grok 4 Fast (TDR drops to 0%)

---

## Sample Size Note

These metrics are based on only 5 GPTShield samples evaluated with 3 prompt types each. Results should be validated with larger sample sizes before drawing definitive conclusions.
