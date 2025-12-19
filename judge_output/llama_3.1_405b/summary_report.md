# Judge Evaluation Report

Generated: 2025-12-18T15:14:10.319849
Judge Model: Mistral Medium 3
Total Cost: $0.1229

## Summary

- Total Samples Evaluated: 40
- Vulnerable Samples: 40
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.975 |
| Precision | 1.000 |
| Recall | 0.975 |
| F1 Score | 0.987 |
| F2 Score | 0.980 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.025 |

Confusion Matrix: TP=39, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.225 |
| Lucky Guess Rate | 0.769 |
| Bonus Discovery Rate | 0.050 |

Target Found: 9, Lucky Guesses: 30

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.212 |
| Hallucination Rate | 0.115 |
| Over-Flagging Score | 1.02 |
| Avg Findings per Sample | 1.30 |

Total: 52, Valid: 11, Hallucinated: 6

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.861 | 0.124 |
| Attack Vector (AVA) | 0.861 | 0.171 |
| Fix Validity (FSV) | 0.778 | 0.219 |

Samples with reasoning scores: 9

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.778 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.030 |
| MCE | 0.200 |
| Overconfidence Rate | 0.026 |
| Brier Score | 0.026 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.638** |
| True Understanding Score | 0.040 |
| Lucky Guess Indicator | 0.750 |

### SUI Components

- f2: 0.980
- target_detection: 0.225
- finding_precision: 0.212
- avg_reasoning: 0.833
- calibration: 0.970

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.975
- Target Detection: 0.225
- Finding Precision: 0.212
- SUI: 0.638

