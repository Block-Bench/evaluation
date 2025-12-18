# Judge Evaluation Report

Generated: 2025-12-18T19:14:14.642190
Judge Model: Mistral Medium 3
Total Cost: $0.2685

## Summary

- Total Samples Evaluated: 15
- Vulnerable Samples: 15
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.400 |
| Precision | 1.000 |
| Recall | 0.400 |
| F1 Score | 0.571 |
| F2 Score | 0.455 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.600 |

Confusion Matrix: TP=6, TN=0, FP=0, FN=9

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.200 |
| Lucky Guess Rate | 0.500 |
| Bonus Discovery Rate | 0.133 |

Target Found: 3, Lucky Guesses: 3

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.144 |
| Hallucination Rate | 0.000 |
| Over-Flagging Score | 5.13 |
| Avg Findings per Sample | 6.00 |

Total: 90, Valid: 13, Hallucinated: 0

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 1.000 | 0.000 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 1.000 | 0.000 |

Samples with reasoning scores: 3

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 1.000 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.450 |
| MCE | 0.450 |
| Overconfidence Rate | 0.600 |
| Brier Score | 0.442 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.490** |
| True Understanding Score | 0.029 |
| Lucky Guess Indicator | 0.200 |

### SUI Components

- f2: 0.455
- target_detection: 0.200
- finding_precision: 0.144
- avg_reasoning: 1.000
- calibration: 0.550

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.400
- Target Detection: 0.200
- Finding Precision: 0.059
- SUI: 0.477

### NATURALISTIC

- Accuracy: 0.400
- Target Detection: 0.200
- Finding Precision: 0.111
- SUI: 0.480

### ADVERSARIAL

- Accuracy: 0.400
- Target Detection: 0.200
- Finding Precision: 0.250
- SUI: 0.501

