# Judge Evaluation Report

Generated: 2025-12-18T15:49:36.704985
Judge Model: Mistral Medium 3
Total Cost: $0.1598

## Summary

- Total Samples Evaluated: 53
- Vulnerable Samples: 53
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.981 |
| Precision | 1.000 |
| Recall | 0.981 |
| F1 Score | 0.990 |
| F2 Score | 0.985 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.019 |

Confusion Matrix: TP=52, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.208 |
| Lucky Guess Rate | 0.788 |
| Bonus Discovery Rate | 0.094 |

Target Found: 11, Lucky Guesses: 41

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.235 |
| Hallucination Rate | 0.118 |
| Over-Flagging Score | 0.98 |
| Avg Findings per Sample | 1.28 |

Total: 68, Valid: 16, Hallucinated: 8

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.886 | 0.124 |
| Attack Vector (AVA) | 0.886 | 0.164 |
| Fix Validity (FSV) | 0.818 | 0.216 |

Samples with reasoning scores: 11

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.818 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.023 |
| MCE | 0.200 |
| Overconfidence Rate | 0.019 |
| Brier Score | 0.020 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.647** |
| True Understanding Score | 0.042 |
| Lucky Guess Indicator | 0.774 |

### SUI Components

- f2: 0.985
- target_detection: 0.208
- finding_precision: 0.235
- avg_reasoning: 0.864
- calibration: 0.977

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.981
- Target Detection: 0.208
- Finding Precision: 0.235
- SUI: 0.647

