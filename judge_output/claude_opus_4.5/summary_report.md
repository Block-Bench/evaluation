# Judge Evaluation Report

Generated: 2025-12-18T15:53:56.810970
Judge Model: Mistral Medium 3
Total Cost: $0.2033

## Summary

- Total Samples Evaluated: 53
- Vulnerable Samples: 53
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.906 |
| Precision | 1.000 |
| Recall | 0.906 |
| F1 Score | 0.950 |
| F2 Score | 0.923 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.094 |

Confusion Matrix: TP=48, TN=0, FP=0, FN=5

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.585 |
| Lucky Guess Rate | 0.354 |
| Bonus Discovery Rate | 0.679 |

Target Found: 31, Lucky Guesses: 17

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.664 |
| Hallucination Rate | 0.007 |
| Over-Flagging Score | 0.94 |
| Avg Findings per Sample | 2.81 |

Total: 149, Valid: 99, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.976 | 0.074 |
| Attack Vector (AVA) | 0.992 | 0.044 |
| Fix Validity (FSV) | 0.960 | 0.112 |

Samples with reasoning scores: 31

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.774 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.094 |
| MCE | 0.242 |
| Overconfidence Rate | 0.094 |
| Brier Score | 0.071 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.811** |
| True Understanding Score | 0.379 |
| Lucky Guess Indicator | 0.321 |

### SUI Components

- f2: 0.923
- target_detection: 0.585
- finding_precision: 0.664
- avg_reasoning: 0.976
- calibration: 0.906

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.906
- Target Detection: 0.585
- Finding Precision: 0.664
- SUI: 0.811

