# Judge Evaluation Report

Generated: 2025-12-18T05:03:06.254381
Judge Model: Mistral Medium 3
Total Cost: $0.0137

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
| Target Detection Rate | 0.200 |
| Lucky Guess Rate | 0.800 |
| Bonus Discovery Rate | 0.000 |

Target Found: 1, Lucky Guesses: 4

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.200 |
| Hallucination Rate | 0.200 |
| Over-Flagging Score | 0.80 |
| Avg Findings per Sample | 1.00 |

Total: 5, Valid: 1, Hallucinated: 1

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
| ECE | 0.000 |
| MCE | 0.000 |
| Overconfidence Rate | 0.000 |
| Brier Score | 0.000 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.680** |
| True Understanding Score | 0.040 |
| Lucky Guess Indicator | 0.800 |

### SUI Components

- f2: 1.000
- target_detection: 0.200
- finding_precision: 0.200
- avg_reasoning: 1.000
- calibration: 1.000

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 1.000
- Target Detection: 0.200
- Finding Precision: 0.200
- SUI: 0.680

