# Judge Evaluation Report

Generated: 2025-12-21T23:52:45.393752
Judge Model: Mistral Medium 3
Total Cost: $0.2200

## Summary

- Total Samples Evaluated: 67
- Vulnerable Samples: 67
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.687 |
| Precision | 1.000 |
| Recall | 0.687 |
| F1 Score | 0.814 |
| F2 Score | 0.732 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.313 |

Confusion Matrix: TP=46, TN=0, FP=0, FN=21

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.448 |
| Lucky Guess Rate | 0.413 |
| Bonus Discovery Rate | 0.478 |

Target Found: 30, Lucky Guesses: 19

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.503 |
| Hallucination Rate | 0.014 |
| Over-Flagging Score | 1.07 |
| Avg Findings per Sample | 2.16 |

Total: 145, Valid: 73, Hallucinated: 2

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.983 | 0.062 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 0.967 | 0.085 |

Samples with reasoning scores: 30

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.800 |
| Semantic Match Rate | 0.967 |
| Partial Match Rate | 0.033 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.212 |
| MCE | 0.217 |
| Overconfidence Rate | 0.214 |
| Brier Score | 0.202 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.695** |
| True Understanding Score | 0.222 |
| Lucky Guess Indicator | 0.239 |

### SUI Components

- f2: 0.732
- target_detection: 0.448
- finding_precision: 0.503
- avg_reasoning: 0.983
- calibration: 0.788

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.793
- Target Detection: 0.466
- Finding Precision: 0.683
- SUI: 0.750

### NATURALISTIC

- Accuracy: 0.000
- Target Detection: 0.500
- Finding Precision: 0.130
- SUI: 0.445

### ADVERSARIAL

- Accuracy: 0.000
- Target Detection: 0.200
- Finding Precision: 0.048
- SUI: 0.357

