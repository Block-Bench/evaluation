# Judge Evaluation Report

Generated: 2025-12-18T17:15:15.527047
Judge Model: Mistral Medium 3
Total Cost: $0.1728

## Summary

- Total Samples Evaluated: 58
- Vulnerable Samples: 58
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.983 |
| Precision | 1.000 |
| Recall | 0.983 |
| F1 Score | 0.991 |
| F2 Score | 0.986 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.017 |

Confusion Matrix: TP=57, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.207 |
| Lucky Guess Rate | 0.789 |
| Bonus Discovery Rate | 0.138 |

Target Found: 12, Lucky Guesses: 45

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.267 |
| Hallucination Rate | 0.107 |
| Over-Flagging Score | 0.95 |
| Avg Findings per Sample | 1.29 |

Total: 75, Valid: 20, Hallucinated: 8

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.875 | 0.125 |
| Attack Vector (AVA) | 0.875 | 0.161 |
| Fix Validity (FSV) | 0.792 | 0.224 |

Samples with reasoning scores: 12

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.833 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.021 |
| MCE | 0.200 |
| Overconfidence Rate | 0.018 |
| Brier Score | 0.018 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.648** |
| True Understanding Score | 0.047 |
| Lucky Guess Indicator | 0.776 |

### SUI Components

- f2: 0.986
- target_detection: 0.207
- finding_precision: 0.267
- avg_reasoning: 0.847
- calibration: 0.979

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.983
- Target Detection: 0.207
- Finding Precision: 0.267
- SUI: 0.648

