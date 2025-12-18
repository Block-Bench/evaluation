# Judge Evaluation Report

Generated: 2025-12-18T17:14:43.852658
Judge Model: Mistral Medium 3
Total Cost: $0.1992

## Summary

- Total Samples Evaluated: 58
- Vulnerable Samples: 58
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.828 |
| Precision | 1.000 |
| Recall | 0.828 |
| F1 Score | 0.906 |
| F2 Score | 0.857 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.172 |

Confusion Matrix: TP=48, TN=0, FP=0, FN=10

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.569 |
| Lucky Guess Rate | 0.312 |
| Bonus Discovery Rate | 0.621 |

Target Found: 33, Lucky Guesses: 15

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.863 |
| Hallucination Rate | 0.029 |
| Over-Flagging Score | 0.24 |
| Avg Findings per Sample | 1.76 |

Total: 102, Valid: 88, Hallucinated: 3

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 1.000 | 0.000 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 1.000 | 0.000 |

Samples with reasoning scores: 33

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.727 |
| Semantic Match Rate | 0.970 |
| Partial Match Rate | 0.030 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.083 |
| MCE | 0.620 |
| Overconfidence Rate | 0.068 |
| Brier Score | 0.121 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.828** |
| True Understanding Score | 0.491 |
| Lucky Guess Indicator | 0.259 |

### SUI Components

- f2: 0.857
- target_detection: 0.569
- finding_precision: 0.863
- avg_reasoning: 1.000
- calibration: 0.917

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.828
- Target Detection: 0.569
- Finding Precision: 0.863
- SUI: 0.828

