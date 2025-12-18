# Judge Evaluation Report

Generated: 2025-12-18T17:13:23.344049
Judge Model: Mistral Medium 3
Total Cost: $0.2062

## Summary

- Total Samples Evaluated: 58
- Vulnerable Samples: 58
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.931 |
| Precision | 1.000 |
| Recall | 0.931 |
| F1 Score | 0.964 |
| F2 Score | 0.944 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.069 |

Confusion Matrix: TP=54, TN=0, FP=0, FN=4

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.431 |
| Lucky Guess Rate | 0.537 |
| Bonus Discovery Rate | 0.690 |

Target Found: 25, Lucky Guesses: 29

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.640 |
| Hallucination Rate | 0.036 |
| Over-Flagging Score | 0.86 |
| Avg Findings per Sample | 2.40 |

Total: 139, Valid: 89, Hallucinated: 5

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.930 | 0.112 |
| Attack Vector (AVA) | 0.940 | 0.128 |
| Fix Validity (FSV) | 0.890 | 0.174 |

Samples with reasoning scores: 25

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.640 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.086 |
| MCE | 0.100 |
| Overconfidence Rate | 0.069 |
| Brier Score | 0.068 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.761** |
| True Understanding Score | 0.254 |
| Lucky Guess Indicator | 0.500 |

### SUI Components

- f2: 0.944
- target_detection: 0.431
- finding_precision: 0.640
- avg_reasoning: 0.920
- calibration: 0.914

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.931
- Target Detection: 0.431
- Finding Precision: 0.640
- SUI: 0.761

