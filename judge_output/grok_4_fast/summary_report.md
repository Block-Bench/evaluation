# Judge Evaluation Report

Generated: 2025-12-18T18:28:06.726445
Judge Model: Mistral Medium 3
Total Cost: $0.1661

## Summary

- Total Samples Evaluated: 56
- Vulnerable Samples: 56
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.679 |
| Precision | 1.000 |
| Recall | 0.679 |
| F1 Score | 0.809 |
| F2 Score | 0.725 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.321 |

Confusion Matrix: TP=38, TN=0, FP=0, FN=18

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.339 |
| Lucky Guess Rate | 0.579 |
| Bonus Discovery Rate | 0.518 |

Target Found: 19, Lucky Guesses: 22

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.439 |
| Hallucination Rate | 0.008 |
| Over-Flagging Score | 1.23 |
| Avg Findings per Sample | 2.20 |

Total: 123, Valid: 54, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.921 | 0.163 |
| Attack Vector (AVA) | 0.855 | 0.296 |
| Fix Validity (FSV) | 0.803 | 0.368 |

Samples with reasoning scores: 19

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.684 |
| Semantic Match Rate | 0.895 |
| Partial Match Rate | 0.105 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.312 |
| MCE | 0.324 |
| Overconfidence Rate | 0.321 |
| Brier Score | 0.315 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.616** |
| True Understanding Score | 0.128 |
| Lucky Guess Indicator | 0.339 |

### SUI Components

- f2: 0.725
- target_detection: 0.339
- finding_precision: 0.439
- avg_reasoning: 0.860
- calibration: 0.688

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.679
- Target Detection: 0.339
- Finding Precision: 0.439
- SUI: 0.616

