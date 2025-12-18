# Judge Evaluation Report

Generated: 2025-12-18T19:15:22.436744
Judge Model: Mistral Medium 3
Total Cost: $0.2484

## Summary

- Total Samples Evaluated: 15
- Vulnerable Samples: 15
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.267 |
| Precision | 1.000 |
| Recall | 0.267 |
| F1 Score | 0.421 |
| F2 Score | 0.312 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.733 |

Confusion Matrix: TP=4, TN=0, FP=0, FN=11

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.133 |
| Lucky Guess Rate | 0.750 |
| Bonus Discovery Rate | 0.067 |

Target Found: 2, Lucky Guesses: 3

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.041 |
| Hallucination Rate | 0.041 |
| Over-Flagging Score | 4.67 |
| Avg Findings per Sample | 4.87 |

Total: 73, Valid: 3, Hallucinated: 3

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.750 | 0.000 |
| Attack Vector (AVA) | 0.625 | 0.125 |
| Fix Validity (FSV) | 0.500 | 0.500 |

Samples with reasoning scores: 2

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.000 |
| Semantic Match Rate | 0.500 |
| Partial Match Rate | 0.500 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.675 |
| MCE | 0.962 |
| Overconfidence Rate | 0.667 |
| Brier Score | 0.621 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.306** |
| True Understanding Score | 0.003 |
| Lucky Guess Indicator | 0.133 |

### SUI Components

- f2: 0.312
- target_detection: 0.133
- finding_precision: 0.041
- avg_reasoning: 0.625
- calibration: 0.325

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.400
- Target Detection: 0.000
- Finding Precision: 0.125
- SUI: 0.171

### NATURALISTIC

- Accuracy: 0.200
- Target Detection: 0.200
- Finding Precision: 0.023
- SUI: 0.371

### ADVERSARIAL

- Accuracy: 0.200
- Target Detection: 0.200
- Finding Precision: 0.048
- SUI: 0.221

