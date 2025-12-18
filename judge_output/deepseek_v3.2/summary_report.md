# Judge Evaluation Report

Generated: 2025-12-18T05:00:53.876797
Judge Model: Mistral Medium 3
Total Cost: $0.0181

## Summary

- Total Samples Evaluated: 5
- Vulnerable Samples: 5
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 1.000 |
| Precision | 1.000 |
| Recall | 1.000 |
| F1 Score | 1.000 |
| F2 Score | 1.000 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.000 |

Confusion Matrix: TP=5, TN=0, FP=0, FN=0

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.800 |
| Lucky Guess Rate | 0.200 |
| Bonus Discovery Rate | 0.400 |

Target Found: 4, Lucky Guesses: 1

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.538 |
| Hallucination Rate | 0.077 |
| Over-Flagging Score | 1.20 |
| Avg Findings per Sample | 2.60 |

Total: 13, Valid: 7, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 1.000 | 0.000 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 1.000 | 0.000 |

Samples with reasoning scores: 4

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.750 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.060 |
| MCE | 0.100 |
| Overconfidence Rate | 0.000 |
| Brier Score | 0.004 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.875** |
| True Understanding Score | 0.431 |
| Lucky Guess Indicator | 0.200 |

### SUI Components

- f2: 1.000
- target_detection: 0.800
- finding_precision: 0.538
- avg_reasoning: 1.000
- calibration: 0.940

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 1.000
- Target Detection: 0.800
- Finding Precision: 0.538
- SUI: 0.875

