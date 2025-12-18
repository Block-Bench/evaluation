# Judge Evaluation Report

Generated: 2025-12-18T15:13:56.513871
Judge Model: Mistral Medium 3
Total Cost: $0.1668

## Summary

- Total Samples Evaluated: 43
- Vulnerable Samples: 43
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.930 |
| Precision | 1.000 |
| Recall | 0.930 |
| F1 Score | 0.964 |
| F2 Score | 0.943 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.070 |

Confusion Matrix: TP=40, TN=0, FP=0, FN=3

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.581 |
| Lucky Guess Rate | 0.375 |
| Bonus Discovery Rate | 0.698 |

Target Found: 25, Lucky Guesses: 15

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.648 |
| Hallucination Rate | 0.000 |
| Over-Flagging Score | 1.00 |
| Avg Findings per Sample | 2.84 |

Total: 122, Valid: 79, Hallucinated: 0

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.970 | 0.081 |
| Attack Vector (AVA) | 0.990 | 0.049 |
| Fix Validity (FSV) | 0.950 | 0.122 |

Samples with reasoning scores: 25

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.720 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.069 |
| MCE | 0.134 |
| Overconfidence Rate | 0.070 |
| Brier Score | 0.055 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.814** |
| True Understanding Score | 0.365 |
| Lucky Guess Indicator | 0.349 |

### SUI Components

- f2: 0.943
- target_detection: 0.581
- finding_precision: 0.648
- avg_reasoning: 0.970
- calibration: 0.931

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.930
- Target Detection: 0.581
- Finding Precision: 0.648
- SUI: 0.814

