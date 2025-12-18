# Judge Evaluation Report

Generated: 2025-12-18T17:14:05.355152
Judge Model: Mistral Medium 3
Total Cost: $0.2109

## Summary

- Total Samples Evaluated: 56
- Vulnerable Samples: 56
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.982 |
| Precision | 1.000 |
| Recall | 0.982 |
| F1 Score | 0.991 |
| F2 Score | 0.986 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.018 |

Confusion Matrix: TP=55, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.607 |
| Lucky Guess Rate | 0.382 |
| Bonus Discovery Rate | 0.696 |

Target Found: 34, Lucky Guesses: 21

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.777 |
| Hallucination Rate | 0.008 |
| Over-Flagging Score | 0.48 |
| Avg Findings per Sample | 2.16 |

Total: 121, Valid: 94, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.978 | 0.093 |
| Attack Vector (AVA) | 0.978 | 0.127 |
| Fix Validity (FSV) | 0.949 | 0.180 |

Samples with reasoning scores: 34

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.676 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.010 |
| MCE | 0.100 |
| Overconfidence Rate | 0.018 |
| Brier Score | 0.017 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.856** |
| True Understanding Score | 0.457 |
| Lucky Guess Indicator | 0.375 |

### SUI Components

- f2: 0.986
- target_detection: 0.607
- finding_precision: 0.777
- avg_reasoning: 0.968
- calibration: 0.990

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.982
- Target Detection: 0.607
- Finding Precision: 0.777
- SUI: 0.856

