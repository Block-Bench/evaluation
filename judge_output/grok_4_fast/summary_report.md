# Judge Evaluation Report

Generated: 2025-12-18T19:19:21.122041
Judge Model: Mistral Medium 3
Total Cost: $0.2121

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
| Bonus Discovery Rate | 0.400 |

Target Found: 2, Lucky Guesses: 3

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.127 |
| Hallucination Rate | 0.000 |
| Over-Flagging Score | 4.13 |
| Avg Findings per Sample | 4.73 |

Total: 71, Valid: 9, Hallucinated: 0

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.875 | 0.125 |
| Attack Vector (AVA) | 0.875 | 0.125 |
| Fix Validity (FSV) | 0.750 | 0.250 |

Samples with reasoning scores: 2

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.500 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.743 |
| MCE | 1.000 |
| Overconfidence Rate | 0.714 |
| Brier Score | 0.717 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.365** |
| True Understanding Score | 0.014 |
| Lucky Guess Indicator | 0.133 |

### SUI Components

- f2: 0.312
- target_detection: 0.133
- finding_precision: 0.127
- avg_reasoning: 0.833
- calibration: 0.257

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.400
- Target Detection: 0.000
- Finding Precision: 0.200
- SUI: 0.180

### NATURALISTIC

- Accuracy: 0.200
- Target Detection: 0.400
- Finding Precision: 0.156
- SUI: 0.441

### ADVERSARIAL

- Accuracy: 0.200
- Target Detection: 0.000
- Finding Precision: 0.069
- SUI: 0.070

