# Judge Evaluation Report

Generated: 2025-12-18T19:17:42.558674
Judge Model: Mistral Medium 3
Total Cost: $0.2120

## Summary

- Total Samples Evaluated: 14
- Vulnerable Samples: 14
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.429 |
| Precision | 1.000 |
| Recall | 0.429 |
| F1 Score | 0.600 |
| F2 Score | 0.484 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.571 |

Confusion Matrix: TP=6, TN=0, FP=0, FN=8

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.071 |
| Lucky Guess Rate | 0.833 |
| Bonus Discovery Rate | 0.000 |

Target Found: 1, Lucky Guesses: 5

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.016 |
| Hallucination Rate | 0.016 |
| Over-Flagging Score | 4.43 |
| Avg Findings per Sample | 4.50 |

Total: 63, Valid: 1, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 1.000 | 0.000 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 1.000 | 0.000 |

Samples with reasoning scores: 1

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 1.000 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.200 |
| MCE | 0.200 |
| Overconfidence Rate | 0.200 |
| Brier Score | 0.200 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.471** |
| True Understanding Score | 0.001 |
| Lucky Guess Indicator | 0.357 |

### SUI Components

- f2: 0.484
- target_detection: 0.071
- finding_precision: 0.016
- avg_reasoning: 1.000
- calibration: 0.800

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.800
- Target Detection: 0.000
- Finding Precision: 0.000
- SUI: 0.288

### NATURALISTIC

- Accuracy: 0.250
- Target Detection: 0.250
- Finding Precision: 0.030
- SUI: 0.441

### ADVERSARIAL

- Accuracy: 0.200
- Target Detection: 0.000
- Finding Precision: 0.000
- SUI: 0.110

