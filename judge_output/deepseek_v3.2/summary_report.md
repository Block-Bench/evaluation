# Judge Evaluation Report

Generated: 2025-12-18T15:37:34.120199
Judge Model: Mistral Medium 3
Total Cost: $0.1920

## Summary

- Total Samples Evaluated: 53
- Vulnerable Samples: 53
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.925 |
| Precision | 1.000 |
| Recall | 0.925 |
| F1 Score | 0.961 |
| F2 Score | 0.939 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.075 |

Confusion Matrix: TP=49, TN=0, FP=0, FN=4

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.415 |
| Lucky Guess Rate | 0.551 |
| Bonus Discovery Rate | 0.660 |

Target Found: 22, Lucky Guesses: 27

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.620 |
| Hallucination Rate | 0.039 |
| Over-Flagging Score | 0.92 |
| Avg Findings per Sample | 2.43 |

Total: 129, Valid: 80, Hallucinated: 5

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.932 | 0.111 |
| Attack Vector (AVA) | 0.943 | 0.129 |
| Fix Validity (FSV) | 0.898 | 0.163 |

Samples with reasoning scores: 22

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.636 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.093 |
| MCE | 0.100 |
| Overconfidence Rate | 0.075 |
| Brier Score | 0.074 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.753** |
| True Understanding Score | 0.238 |
| Lucky Guess Indicator | 0.509 |

### SUI Components

- f2: 0.939
- target_detection: 0.415
- finding_precision: 0.620
- avg_reasoning: 0.924
- calibration: 0.907

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.925
- Target Detection: 0.415
- Finding Precision: 0.620
- SUI: 0.753

