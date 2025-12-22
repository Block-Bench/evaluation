# TC Sample Transformation Trajectory Analysis
**Analysis Date:** 2025-12-22 00:43:38
---
## Overview
This analysis traces how model performance changes as **TC samples** (tc_001 to tc_005) undergo progressive transformations:

1. **Baseline (nc_o)** (`nc_o_tc_00X`)
2. **Sanitized (sn)** (`sn_tc_00X`)
3. **Chameleon (ch_medical_nc)** (`ch_medical_nc_tc_00X`)
4. **Shapeshifter (ss_l3_medium_nc)** (`ss_l3_medium_nc_tc_00X`)

**Total TC Samples Tracked:** 5
---

## Key Findings

### 1. Most Robust Model (Least Performance Drop)
**Llama 3.1 405B** actually **improved** by 20.0 percentage points!

### 2. Best Baseline Performance (nc_o)
**Claude Opus 4.5** with 60.0% detection.

### 3. Best Final Stage Performance (Shapeshifter)
**Gemini 3 Pro** with 60.0% detection.

### 4. Most Affected by Transformations
**DeepSeek v3.2** dropped 40.0 percentage points from baseline to final stage.

---

## Performance by Transformation Stage

### Baseline (nc_o)

| Rank | Model | Detection Rate | Finding Precision | Quality Score | Targets Found |
|------|-------|----------------|-------------------|---------------|---------------|
| 1 | Claude Opus 4.5 | 60.0% | 93.3% | 100.0% | 3/5 |
| 2 | DeepSeek v3.2 | 60.0% | 93.3% | 91.7% | 3/5 |
| 3 | Gemini 3 Pro | 60.0% | 100.0% | 100.0% | 3/5 |
| 4 | GPT-5.2 | 60.0% | 80.0% | 100.0% | 3/5 |
| 5 | Grok 4 | 60.0% | 80.0% | 100.0% | 3/5 |
| 6 | Llama 3.1 405B | 20.0% | 60.0% | 75.0% | 1/5 |

### Sanitized (sn)

| Rank | Model | Detection Rate | Finding Precision | Quality Score | Targets Found |
|------|-------|----------------|-------------------|---------------|---------------|
| 1 | DeepSeek v3.2 | 60.0% | 80.0% | 91.7% | 3/5 |
| 2 | GPT-5.2 | 60.0% | 80.0% | 100.0% | 3/5 |
| 3 | Claude Opus 4.5 | 40.0% | 93.3% | 87.5% | 2/5 |
| 4 | Gemini 3 Pro | 40.0% | 100.0% | 100.0% | 2/5 |
| 5 | Grok 4 | 20.0% | 80.0% | 100.0% | 1/5 |
| 6 | Llama 3.1 405B | 20.0% | 40.0% | 75.0% | 1/5 |

### Chameleon (ch_medical_nc)

| Rank | Model | Detection Rate | Finding Precision | Quality Score | Targets Found |
|------|-------|----------------|-------------------|---------------|---------------|
| 1 | GPT-5.2 | 60.0% | 80.0% | 91.7% | 3/5 |
| 2 | Gemini 3 Pro | 50.0% | 91.7% | 100.0% | 2/4 |
| 3 | Claude Opus 4.5 | 40.0% | 100.0% | 87.5% | 2/5 |
| 4 | DeepSeek v3.2 | 40.0% | 86.7% | 87.5% | 2/5 |
| 5 | Grok 4 | 40.0% | 63.3% | 100.0% | 2/5 |
| 6 | Llama 3.1 405B | 20.0% | 40.0% | 75.0% | 1/5 |

### Shapeshifter (ss_l3_medium_nc)

| Rank | Model | Detection Rate | Finding Precision | Quality Score | Targets Found |
|------|-------|----------------|-------------------|---------------|---------------|
| 1 | Gemini 3 Pro | 60.0% | 80.0% | 83.3% | 3/5 |
| 2 | GPT-5.2 | 60.0% | 80.0% | 91.7% | 3/5 |
| 3 | Grok 4 | 60.0% | 73.3% | 91.7% | 3/5 |
| 4 | Claude Opus 4.5 | 40.0% | 86.7% | 100.0% | 2/5 |
| 5 | Llama 3.1 405B | 40.0% | 30.0% | 75.0% | 2/5 |
| 6 | DeepSeek v3.2 | 20.0% | 70.0% | 100.0% | 1/5 |

---

## Model-by-Model Trajectory

### Claude Opus 4.5

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 60.0% | 93.3% | 100.0% |
| Sanitized (sn) | 40.0% | 93.3% | 87.5% |
| Chameleon (ch_medical_nc) | 40.0% | 100.0% | 87.5% |
| Shapeshifter (ss_l3_medium_nc) | 40.0% | 86.7% | 100.0% |

**Performance Change:** -20.0 percentage points (degraded)

### DeepSeek v3.2

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 60.0% | 93.3% | 91.7% |
| Sanitized (sn) | 60.0% | 80.0% | 91.7% |
| Chameleon (ch_medical_nc) | 40.0% | 86.7% | 87.5% |
| Shapeshifter (ss_l3_medium_nc) | 20.0% | 70.0% | 100.0% |

**Performance Change:** -40.0 percentage points (degraded)

### GPT-5.2

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 60.0% | 80.0% | 100.0% |
| Sanitized (sn) | 60.0% | 80.0% | 100.0% |
| Chameleon (ch_medical_nc) | 60.0% | 80.0% | 91.7% |
| Shapeshifter (ss_l3_medium_nc) | 60.0% | 80.0% | 91.7% |

**Performance Change:** No change

### Gemini 3 Pro

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 60.0% | 100.0% | 100.0% |
| Sanitized (sn) | 40.0% | 100.0% | 100.0% |
| Chameleon (ch_medical_nc) | 50.0% | 91.7% | 100.0% |
| Shapeshifter (ss_l3_medium_nc) | 60.0% | 80.0% | 83.3% |

**Performance Change:** No change

### Grok 4

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 60.0% | 80.0% | 100.0% |
| Sanitized (sn) | 20.0% | 80.0% | 100.0% |
| Chameleon (ch_medical_nc) | 40.0% | 63.3% | 100.0% |
| Shapeshifter (ss_l3_medium_nc) | 60.0% | 73.3% | 91.7% |

**Performance Change:** No change

### Llama 3.1 405B

| Stage | Detection Rate | Finding Precision | Quality Score |
|-------|----------------|-------------------|---------------|
| Baseline (nc_o) | 20.0% | 60.0% | 75.0% |
| Sanitized (sn) | 20.0% | 40.0% | 75.0% |
| Chameleon (ch_medical_nc) | 20.0% | 40.0% | 75.0% |
| Shapeshifter (ss_l3_medium_nc) | 40.0% | 30.0% | 75.0% |

**Performance Change:** +20.0 percentage points (improved)

---

## Visualizations

- `01_detection_trajectory.png`: Detection rate across all stages
- `02_quality_trajectory.png`: Quality scores across stages
- `03_precision_trajectory.png`: Finding precision across stages
- `04_stage_comparison.png`: Model rankings at each stage
- `05_degradation_analysis.png`: Baseline vs final performance
- `06_multi_metric_trajectories.png`: Combined metrics per model
