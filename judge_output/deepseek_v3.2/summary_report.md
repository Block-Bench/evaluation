# Judge Evaluation Report

Generated: 2025-12-18T15:14:14.048612
Judge Model: Mistral Medium 3
Total Cost: $0.1313

## Summary

- Total Samples Evaluated: 37
- Vulnerable Samples: 37
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.973 |
| Precision | 1.000 |
| Recall | 0.973 |
| F1 Score | 0.986 |
| F2 Score | 0.978 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.027 |

Confusion Matrix: TP=36, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.459 |
| Lucky Guess Rate | 0.528 |
| Bonus Discovery Rate | 0.703 |

Target Found: 17, Lucky Guesses: 19

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.645 |
| Hallucination Rate | 0.032 |
| Over-Flagging Score | 0.89 |
| Avg Findings per Sample | 2.51 |

Total: 93, Valid: 60, Hallucinated: 3

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.912 | 0.119 |
| Attack Vector (AVA) | 0.926 | 0.143 |
| Fix Validity (FSV) | 0.868 | 0.174 |

Samples with reasoning scores: 17

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.588 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.050 |
| MCE | 0.100 |
| Overconfidence Rate | 0.027 |
| Brier Score | 0.030 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.777** |
| True Understanding Score | 0.267 |
| Lucky Guess Indicator | 0.514 |

### SUI Components

- f2: 0.978
- target_detection: 0.459
- finding_precision: 0.645
- avg_reasoning: 0.902
- calibration: 0.950

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.973
- Target Detection: 0.459
- Finding Precision: 0.645
- SUI: 0.777

