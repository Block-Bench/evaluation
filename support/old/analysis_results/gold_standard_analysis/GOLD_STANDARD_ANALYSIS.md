# Gold Standard Performance Analysis
**Analysis Date:** 2025-12-22 01:50:40
---
## Overview
Gold Standard (gs) samples are manually curated, high-quality benchmark samples representing real-world vulnerabilities with expert-validated ground truth.

**Total Gold Standard Samples:** 10

**Samples:**
- `sn_gs_001`: logic_error (high)
- `sn_gs_002`: logic_error (medium)
- `sn_gs_005`: dos (medium)
- `sn_gs_009`: logic_error (medium)
- `sn_gs_013`: unchecked_return (medium)
- `sn_gs_017`: logic_error (medium)
- `sn_gs_020`: input_validation (medium)
- `sn_gs_025`: front_running (medium)
- `sn_gs_026`: access_control (medium)
- `sn_gs_029`: access_control (high)

---

## Key Findings

### 1. Best Detection Rate on Gold Standard
**Claude Opus 4.5** with 20.0% (2/10 samples).

### 2. Best Quality on Gold Standard
**Gemini 3 Pro** with 100.0% average quality score.

### 3. Performance Comparison: GS vs Overall (Direct Prompts Only)

**Note:** Both comparisons use direct prompts only for fair evaluation.

| Model | GS Detection | Overall Detection (Direct) | Difference |
|-------|--------------|----------------------------|------------|
| Claude Opus 4.5 | 20.0% | 58.6% | -38.6pp |
| DeepSeek v3.2 | 0.0% | 41.4% | -41.4pp |
| Gemini 3 Pro | 11.1% | 60.7% | -49.6pp |
| GPT-5.2 | 10.0% | 58.6% | -48.6pp |
| Grok 4 | 10.0% | 46.6% | -36.6pp |
| Llama 3.1 405B | 0.0% | 19.0% | -19.0pp |

---

## Detailed Gold Standard Performance

| Rank | Model | Detection Rate | Quality Score | Finding Precision | Targets Found |
|------|-------|----------------|---------------|-------------------|---------------|
| 1 | Claude Opus 4.5 | 20.0% | 87.5% | 40.0% | 2/10 |
| 2 | Gemini 3 Pro | 11.1% | 100.0% | 38.9% | 1/9 |
| 3 | GPT-5.2 | 10.0% | 100.0% | 60.0% | 1/10 |
| 4 | Grok 4 | 10.0% | 100.0% | 50.0% | 1/10 |
| 5 | DeepSeek v3.2 | 0.0% | N/A | 48.3% | 0/10 |
| 6 | Llama 3.1 405B | 0.0% | N/A | 0.0% | 0/10 |

---

## Visualizations

- `01_gs_vs_overall_detection.png`: Gold Standard vs Overall comparison
- `02_gs_performance_breakdown.png`: Detailed metrics breakdown
- `03_per_sample_heatmap.png`: Per-sample detection matrix
- `04_gs_by_vulnerability_type.png`: Performance by vulnerability type
