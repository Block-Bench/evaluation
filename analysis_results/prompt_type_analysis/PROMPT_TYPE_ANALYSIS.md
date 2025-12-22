# Performance Across Prompt Types
**Analysis Date:** 2025-12-22 00:43:45
---
## Overview
This analysis examines how models perform across three prompt types:
- **Direct**: Explicit vulnerability analysis request (structured JSON output)
- **Adversarial**: "Already audited" framing to test sycophancy resistance
- **Naturalistic**: Colleague-style code review request

---
## Key Findings

### 1. Best Average Detection Rate
**Gemini 3 Pro** with 46.9% average detection across all prompt types.

### 2. Most Robust (Consistent Across Prompts)
**GPT-5.2** with only 10.8% standard deviation.

### 3. Best Performance by Prompt Type
- **Adversarial**: Gemini 3 Pro (40.0%)
- **Direct**: Gemini 3 Pro (60.7%)
- **Naturalistic**: Gemini 3 Pro (40.0%)

### 4. Susceptibility to Adversarial Prompts
Largest drop from Direct → Adversarial:
- **Claude Opus 4.5**: -38.6% (from 58.6% to 20.0%)
- **Grok 4**: -26.6% (from 46.6% to 20.0%)
- **DeepSeek v3.2**: -21.4% (from 41.4% to 20.0%)

---

## Detailed Performance Table

### Claude Opus 4.5

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 58.6% | 20.0% | 20.0% |
| Quality Score | 97.8% | 100.0% | 100.0% |
| Finding Precision | 74.5% | 22.0% | 10.0% |
| Accuracy | 91.4% | 40.0% | 40.0% |
| Sample Count | 58 | 5 | 5 |

### DeepSeek v3.2

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 41.4% | 20.0% | 20.0% |
| Quality Score | 91.9% | 41.7% | 83.3% |
| Finding Precision | 68.1% | 6.7% | 5.0% |
| Accuracy | 93.1% | 20.0% | 20.0% |
| Sample Count | 58 | 5 | 5 |

### GPT-5.2

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 58.6% | 40.0% | 40.0% |
| Quality Score | 99.3% | 83.3% | 79.2% |
| Finding Precision | 86.2% | 10.7% | 31.5% |
| Accuracy | 82.8% | 20.0% | 40.0% |
| Sample Count | 58 | 5 | 5 |

### Gemini 3 Pro

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 60.7% | 40.0% | 40.0% |
| Quality Score | 98.5% | 70.8% | 83.3% |
| Finding Precision | 80.1% | 22.7% | 24.0% |
| Accuracy | 98.2% | 80.0% | 60.0% |
| Sample Count | 56 | 5 | 5 |

### Grok 4

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 46.6% | 20.0% | 40.0% |
| Quality Score | 98.1% | 100.0% | 100.0% |
| Finding Precision | 77.3% | 4.0% | 30.2% |
| Accuracy | 79.3% | 0.0% | 20.0% |
| Sample Count | 58 | 5 | 5 |

### Llama 3.1 405B

| Metric | Direct | Adversarial | Naturalistic |
|--------|--------|-------------|-------------|
| Detection Rate | 19.0% | 0.0% | 25.0% |
| Quality Score | 85.6% | 0.0% | 100.0% |
| Finding Precision | 23.3% | 0.0% | 3.6% |
| Accuracy | 98.3% | 20.0% | 25.0% |
| Sample Count | 58 | 5 | 4 |

---

## Visualizations

- `01_detection_by_prompt_type.png`: Detection rate comparison
- `02_quality_by_prompt_type.png`: Quality score comparison
- `03_precision_by_prompt_type.png`: Finding precision comparison
- `04_prompt_type_heatmap.png`: Multi-metric heatmaps
- `05_prompt_robustness.png`: Robustness analysis
