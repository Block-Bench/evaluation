# GPTShield (GS) Dataset Performance Summary

Analysis of model performance on professionally identified vulnerabilities from real smart contract security audits.

**Generated**: 2025-12-18
**Dataset**: 10 unique GPTShield samples (professional audit findings)
**Total Evaluations**: 18-20 per model (some samples evaluated with multiple prompt types)

---

## Executive Summary

**GPTShield samples proved significantly harder than other datasets.**

### Key Findings

🔴 **Low Target Detection Rates**: Best model (Gemini 3 Pro) only achieved **26.3% TDR**
- Compare to TC dataset: 60-85.7% TDR on non-sanitized variants
- Compare to DS dataset: 57-85.7% TDR on complex transformations

🔴 **High Lucky Guess Rates**: Models detect "something wrong" but miss the target
- Llama 3.1 405B: **90.9%** lucky guess rate (worst)
- GPT-5.2: **37.5%** lucky guess rate (best)

🔴 **Poor Finding Precision**: Even top performers struggle
- Best: Gemini 3 Pro with **29.9%** precision
- Worst: Llama 3.1 405B with **1.5%** precision

⚠️ **Accuracy Misleading**: High accuracy doesn't mean good vulnerability detection
- Llama: 57.9% accuracy but only 5.3% TDR (mostly lucky guesses)

---

## Performance Rankings

### By Target Detection Rate (Primary Metric)

| Rank | Model | TDR | Accuracy | Lucky% | Finding Precision | Evaluations |
|------|-------|-----|----------|--------|-------------------|-------------|
| 1 | **Gemini 3 Pro Preview** | **26.3%** | 78.9% | 66.7% | **29.9%** | 19 |
| 2 | **GPT-5.2** | **25.0%** | 35.0% | **37.5%** ✅ | 24.0% | 20 |
| 3 | **Claude Opus 4.5** | 20.0% | 45.0% | 55.6% | 18.4% | 20 |
| 4 | **Grok 4 Fast** | 11.1% | 27.8% | 66.7% | 12.5% | 18 |
| 5 | **DeepSeek V3.2** | 10.0% | 40.0% | 77.8% | 11.9% | 20 |
| 6 | **Llama 3.1 405B** | **5.3%** ⚠️ | 57.9% | **90.9%** ⚠️ | **1.5%** ⚠️ | 19 |

### By Finding Precision (Quality Metric)

| Rank | Model | Finding Precision | Valid Findings | Total Findings | Avg per Sample |
|------|-------|-------------------|----------------|----------------|----------------|
| 1 | **Gemini 3 Pro Preview** | **29.9%** | 20 | 67 | 3.5 |
| 2 | **GPT-5.2** | 24.0% | 18 | 75 | 3.8 |
| 3 | **Claude Opus 4.5** | 18.4% | 18 | 98 | 4.9 |
| 4 | **Grok 4 Fast** | 12.5% | 9 | 72 | 4.0 |
| 5 | **DeepSeek V3.2** | 11.9% | 10 | 84 | 4.2 |
| 6 | **Llama 3.1 405B** | **1.5%** ⚠️ | 1 | 68 | 3.6 |

### By Reasoning Quality (For Found Targets)

| Rank | Model | RCIR | AVA | FSV | Average | Targets Found |
|------|-------|------|-----|-----|---------|---------------|
| 1 | **Llama 3.1 405B** | **1.00** | **1.00** | **1.00** | **1.00** | 1 (only!) |
| 2 | **Claude Opus 4.5** | 0.94 | 0.94 | 0.88 | 0.92 | 4 |
| 3 | **GPT-5.2** | 0.90 | 0.85 | 0.80 | 0.85 | 5 |
| 4 | **Grok 4 Fast** | 0.88 | 0.88 | 0.75 | 0.84 | 2 |
| 5 | **Gemini 3 Pro Preview** | 0.85 | 0.80 | 0.80 | 0.82 | 5 |
| 6 | **DeepSeek V3.2** | 0.75 | 0.62 | 0.50 | 0.62 | 2 |

**Note**: Llama's perfect reasoning scores are based on only 1 successful target finding, making them statistically unreliable.

---

## What Happened? Deep Dive by Model

### 1. Gemini 3 Pro Preview - The Winner 🥇

**Performance**: 78.9% accuracy, 26.3% TDR, 29.9% precision

**What Happened**:
- ✅ **Highest accuracy** (78.9%) - correctly identifies when vulnerabilities exist
- ✅ **Highest TDR** (26.3%) - finds target vulnerabilities most often
- ✅ **Best precision** (29.9%) - 30% of findings are valid
- ⚠️ **High lucky guess rate** (66.7%) - still misses many targets
- ✅ **Most efficient** - fewest findings per sample (3.5 avg)

**Interpretation**: Gemini 3 Pro is the most reliable model for GS samples. It detects vulnerabilities exist (78.9% accuracy) and has the best chance of finding the actual target (26.3%). However, even Gemini struggles - 2/3 of the time it detects a vulnerability, it identifies the wrong one.

**Best For**: Production auditing where you need the highest likelihood of finding the real vulnerability.

---

### 2. GPT-5.2 - The Precise Detector 🎯

**Performance**: 35.0% accuracy, 25.0% TDR, 24.0% precision

**What Happened**:
- ⚠️ **Low accuracy** (35.0%) - frequently misses that vulnerabilities exist
- ✅ **High TDR** (25.0%) - when it looks, it finds targets well
- ✅ **Best lucky guess rate** (37.5%) - when it detects, it's usually the right target
- ✅ **Good precision** (24.0%) - 1/4 of findings are valid
- ✅ **Excellent reasoning** (0.90/0.85/0.80) when target found

**Interpretation**: GPT-5.2 has a conservative approach - it often doesn't flag vulnerabilities (65% miss rate), but when it does flag one, it has the best chance of identifying the actual target (62.5% success rate vs 33.3% for Gemini). This makes it prone to false negatives but good at reducing false positives.

**Best For**: Second-pass verification when you want high confidence in flagged issues.

---

### 3. Claude Opus 4.5 - The Verbose Scanner 📊

**Performance**: 45.0% accuracy, 20.0% TDR, 18.4% precision

**What Happened**:
- ⚠️ **Moderate accuracy** (45.0%) - misses many vulnerabilities
- ⚠️ **Moderate TDR** (20.0%) - finds targets 1 in 5 times
- ⚠️ **High lucky guess rate** (55.6%) - often finds wrong vulnerability
- ⚠️ **Low precision** (18.4%) - only 18% of findings are valid
- ⚠️ **Over-flagging** - 4.9 findings per sample (highest)
- ✅ **Excellent reasoning** (0.94/0.94/0.88) when target found

**Interpretation**: Claude Opus 4.5 generates many findings (4.9 avg) but most are invalid (81.6%). It correctly detects vulnerabilities exist (45% accuracy) but struggles to identify the specific target. The high finding count suggests it's thorough but lacks precision on GS samples.

**Best For**: Initial broad scanning where you want comprehensive coverage and will manually review findings.

---

### 4. Grok 4 Fast - The Struggling Scanner ⚠️

**Performance**: 27.8% accuracy, 11.1% TDR, 12.5% precision

**What Happened**:
- 🔴 **Very low accuracy** (27.8%) - misses 72% of vulnerabilities
- 🔴 **Low TDR** (11.1%) - rarely finds targets
- ⚠️ **High lucky guess rate** (66.7%) - usually finds wrong vulnerability
- 🔴 **Poor precision** (12.5%) - 87.5% of findings are invalid
- ⚠️ **Moderate reasoning** (0.88/0.88/0.75) when target found

**Interpretation**: Grok 4 Fast performs poorly on GS samples. It misses most vulnerabilities entirely (72.2%) and when it does detect something, it's usually the wrong issue (66.7% lucky guesses). Only evaluates 18 samples (missing gs_001 and gs_009), suggesting some samples may have failed evaluation.

**Best For**: Not recommended for GS-style professional audit findings.

---

### 5. DeepSeek V3.2 - The Inaccurate Detector 📉

**Performance**: 40.0% accuracy, 10.0% TDR, 11.9% precision

**What Happened**:
- ⚠️ **Low accuracy** (40.0%) - misses 60% of vulnerabilities
- 🔴 **Very low TDR** (10.0%) - finds targets only 1 in 10 times
- 🔴 **High lucky guess rate** (77.8%) - almost always finds wrong vulnerability
- 🔴 **Poor precision** (11.9%) - 88% of findings are invalid
- 🔴 **Worst reasoning quality** (0.75/0.62/0.50) when target found

**Interpretation**: DeepSeek V3.2 struggles significantly with GS samples. While it detects that vulnerabilities exist (40% accuracy), it almost never identifies the correct target (10% TDR). The 77.8% lucky guess rate reveals it's essentially guessing - it knows something is wrong but can't pinpoint what.

**Best For**: Not recommended for GS-style samples. Consider for simpler, non-sanitized code.

---

### 6. Llama 3.1 405B - The Lucky Guesser 🎲

**Performance**: 57.9% accuracy, 5.3% TDR, 1.5% precision

**What Happened**:
- ⚠️ **Moderate accuracy** (57.9%) - detects vulnerabilities exist
- 🔴 **Catastrophic TDR** (5.3%) - finds target in only 1/19 evaluations
- 🔴 **Worst lucky guess rate** (90.9%) - almost NEVER finds the right vulnerability
- 🔴 **Catastrophic precision** (1.5%) - 98.5% of findings are invalid
- ✅ **Perfect reasoning** (1.00/1.00/1.00) - but only for 1 sample!

**Interpretation**: Llama 3.1 405B shows a fundamental flaw in targeted vulnerability analysis on GS samples. It correctly detects that vulnerabilities exist (57.9% accuracy - higher than Claude and GPT-5.2!) but almost never identifies the actual target. Out of 11 correct vulnerability detections, only 1 was the target vulnerability (9.1% success rate).

The perfect reasoning scores (1.00) are misleading - they're based on a single successful detection out of 19 evaluations.

**Best For**: Not recommended. Accuracy metric is highly misleading for this model.

---

## Cross-Cutting Insights

### 1. Why GS Samples Are So Hard

**Professional audit findings vs synthetic samples:**

| Factor | GS Samples | TC/DS Samples |
|--------|-----------|---------------|
| **Sanitization** | All sanitized (no semantic cues) | Mixed (some with context) |
| **Complexity** | Real-world edge cases | Clearer vulnerability patterns |
| **Ambiguity** | Subtle logic errors | More obvious flaws |
| **Documentation** | Minimal (sanitized) | Varies by transformation |

**Result**: GS samples test true vulnerability understanding without relying on variable names, comments, or domain context.

### 2. The Lucky Guess Problem

**What it means**: Model correctly detects "vulnerable" but identifies wrong vulnerability

**Why it happens on GS samples**:
1. **Multiple potential issues** - Real code often has several security concerns
2. **Sanitization removes hints** - Can't use variable names to guide analysis
3. **Shallow pattern matching** - Models recognize vulnerability patterns but can't pinpoint root cause

**Models ranked by lucky guess resistance**:
1. **GPT-5.2**: 37.5% (best - when it flags, usually correct)
2. **Claude Opus 4.5**: 55.6%
3. **Gemini 3 Pro**: 66.7%
4. **Grok 4 Fast**: 66.7%
5. **DeepSeek V3.2**: 77.8%
6. **Llama 3.1 405B**: 90.9% (worst - almost always wrong target)

### 3. Accuracy vs TDR Discrepancy

**Case Study: Llama 3.1 405B**
- Accuracy: 57.9% (higher than GPT-5.2's 35%!)
- TDR: 5.3% (lowest of all models)
- **Interpretation**: Llama detects "something wrong" but rarely the target

**Case Study: GPT-5.2**
- Accuracy: 35.0% (lowest among top models)
- TDR: 25.0% (second highest!)
- **Interpretation**: GPT-5.2 is conservative but precise

**Lesson**: For vulnerability detection, **TDR and precision matter more than accuracy**.

### 4. Finding Volume vs Quality

| Model | Avg Findings | Precision | Valid Findings |
|-------|-------------|-----------|----------------|
| **Gemini 3 Pro** | 3.5 | 29.9% | 20 ✅ |
| **GPT-5.2** | 3.8 | 24.0% | 18 ✅ |
| **Llama 3.1 405B** | 3.6 | **1.5%** | 1 🔴 |
| **DeepSeek V3.2** | 4.2 | 11.9% | 10 |
| **Grok 4 Fast** | 4.0 | 12.5% | 9 |
| **Claude Opus 4.5** | 4.9 | 18.4% | 18 |

**Insight**: More findings ≠ better detection. Claude generates 4.9 findings/sample but only 18.4% are valid. Gemini generates 3.5 findings/sample but 29.9% are valid.

---

## Comparison: GS vs Other Datasets

### TDR Comparison

| Model | GS (Sanitized) | TC (Non-Sanitized) | TC (Sanitized) | DS (Complex) |
|-------|---------------|-------------------|---------------|--------------|
| **Claude Opus 4.5** | 20.0% | 60-85.7% | 24.0% | 58-85.7% |
| **Gemini 3 Pro** | 26.3% | 60-85.7% | 29.2% | 66-85.7% |
| **GPT-5.2** | 25.0% | 60-85.7% | 32.0% | 58-85.7% |
| **Llama 3.1 405B** | 5.3% | 14-28% | 8.3% | 14-28% |
| **DeepSeek V3.2** | 10.0% | 33-60% | 20.0% | 33-60% |
| **Grok 4 Fast** | 11.1% | 14-60% | 21.7% | 14-60% |

**Key Observations**:
1. GS TDR ≈ TC Sanitized TDR (both around 5-32%)
2. TC Non-Sanitized TDR much higher (60-85.7%)
3. **Sanitization is the primary difficulty factor**

### Finding Precision Comparison

| Model | GS | TC (Sanitized) | TC (Non-Sanitized) | DS (Complex) |
|-------|------|---------------|-------------------|--------------|
| **Gemini 3 Pro** | 29.9% | 39.0% | 68-100% | 68-93% |
| **GPT-5.2** | 24.0% | 31.8% | 89-100% | 84-100% |
| **Claude Opus 4.5** | 18.4% | 27.7% | 68-92% | 68-83% |
| **DeepSeek V3.2** | 11.9% | 18.1% | 47-90% | 47-74% |
| **Grok 4 Fast** | 12.5% | 20.3% | 45-78% | 27-56% |
| **Llama 3.1 405B** | 1.5% | 5.3% | 22-57% | 22-29% |

**Insight**: Precision drops 50-80% on GS/sanitized vs non-sanitized samples.

---

## Sample Coverage

| Model | Samples Evaluated | Missing Samples | Coverage |
|-------|------------------|-----------------|----------|
| **Claude Opus 4.5** | 10 | None | 100% |
| **DeepSeek V3.2** | 10 | None | 100% |
| **GPT-5.2** | 10 | None | 100% |
| **Llama 3.1 405B** | 10 | None (1 eval error) | 100%* |
| **Gemini 3 Pro** | 9 | gs_005 | 90% |
| **Grok 4 Fast** | 8 | gs_001, gs_009 | 80% |

*Llama has 100% sample coverage but 1 evaluation failed (gs_017 naturalistic), resulting in 19 total evaluations instead of 20.

---

## Recommendations

### For Production Auditing (Real-World Use)

**1st Choice: Gemini 3 Pro Preview**
- Highest TDR (26.3%)
- Best precision (29.9%)
- Most efficient (3.5 findings/sample)
- Highest accuracy (78.9%)

**2nd Choice: GPT-5.2**
- Similar TDR (25.0%)
- Best lucky guess resistance (37.5%)
- Good precision (24.0%)
- More conservative (lower false positives)

**Ensemble Approach**: Use both Gemini + GPT-5.2
- Gemini for comprehensive scanning
- GPT-5.2 for high-confidence findings
- Combined: catch ~40-50% of targets

### For Research/Analysis

**Use: Claude Opus 4.5**
- Generates most findings (4.9 avg)
- Excellent reasoning quality (0.94/0.94/0.88)
- Good for understanding model behavior
- Requires manual filtering

### What to Avoid

❌ **Llama 3.1 405B** - 90.9% lucky guess rate, 1.5% precision
❌ **DeepSeek V3.2** - 77.8% lucky guess rate, poor reasoning quality
❌ **Grok 4 Fast** - 27.8% accuracy, 11.1% TDR

---

## Conclusions

### The GS Challenge

GPTShield samples represent **real-world audit difficulty**:
- All samples are sanitized (no semantic hints)
- Professional findings (not synthetic patterns)
- Subtle, complex vulnerabilities
- Realistic code complexity

### Model Performance Summary

**Only 2 models are viable for GS-style samples**:
1. **Gemini 3 Pro**: Best overall (26.3% TDR, 29.9% precision)
2. **GPT-5.2**: Best precision when it flags (62.5% success rate)

**4 models struggle significantly**:
- Claude Opus 4.5: Too many invalid findings
- Grok 4 Fast: Poor accuracy and TDR
- DeepSeek V3.2: High lucky guess rate
- Llama 3.1 405B: Catastrophic target detection failure

### The Sanitization Effect

**GS performance ≈ TC Sanitized performance** for all models, confirming:
- Sanitization (removing semantic cues) is the primary difficulty
- Models heavily rely on variable names, comments, domain context
- Without these cues, even top models achieve only 26-32% TDR

### Implications for Real-World Auditing

🔴 **Current LLMs are NOT ready for autonomous auditing** on sanitized/obfuscated code
- Best model: 26.3% TDR (misses 73.7% of targets)
- High lucky guess rates (37-91%)
- Low precision (1.5-30%)

✅ **LLMs can assist human auditors** as:
- Broad scanners (Gemini generates candidates)
- Second-opinion tools (GPT-5.2 validates concerns)
- Educational aids (Claude provides detailed reasoning)

⚠️ **Accuracy is a misleading metric**
- Llama: 57.9% accuracy but 5.3% TDR
- GPT-5.2: 35.0% accuracy but 25.0% TDR
- **Use TDR + precision for evaluation**
