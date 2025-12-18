# Judge Evaluation Report

Generated: 2025-12-18T15:14:00.417004
Judge Model: Mistral Medium 3
Total Cost: $0.1266

## Summary

- Total Samples Evaluated: 36
- Vulnerable Samples: 36
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.806 |
| Precision | 1.000 |
| Recall | 0.806 |
| F1 Score | 0.892 |
| F2 Score | 0.838 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.194 |

Confusion Matrix: TP=29, TN=0, FP=0, FN=7

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.500 |
| Lucky Guess Rate | 0.379 |
| Bonus Discovery Rate | 0.556 |

Target Found: 18, Lucky Guesses: 11

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.860 |
| Hallucination Rate | 0.035 |
| Over-Flagging Score | 0.22 |
| Avg Findings per Sample | 1.58 |

Total: 57, Valid: 49, Hallucinated: 2

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 1.000 | 0.000 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 1.000 | 0.000 |

Samples with reasoning scores: 18

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.833 |
| Semantic Match Rate | 0.944 |
| Partial Match Rate | 0.056 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.096 |
| MCE | 0.620 |
| Overconfidence Rate | 0.074 |
| Brier Score | 0.131 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.804** |
| True Understanding Score | 0.430 |
| Lucky Guess Indicator | 0.306 |

### SUI Components

- f2: 0.838
- target_detection: 0.500
- finding_precision: 0.860
- avg_reasoning: 1.000
- calibration: 0.904

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.806
- Target Detection: 0.500
- Finding Precision: 0.860
- SUI: 0.804

