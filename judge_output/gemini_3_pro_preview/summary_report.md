# Judge Evaluation Report

Generated: 2025-12-18T15:14:01.815240
Judge Model: Mistral Medium 3
Total Cost: $0.1250

## Summary

- Total Samples Evaluated: 32
- Vulnerable Samples: 32
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.969 |
| Precision | 1.000 |
| Recall | 0.969 |
| F1 Score | 0.984 |
| F2 Score | 0.975 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.031 |

Confusion Matrix: TP=31, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.531 |
| Lucky Guess Rate | 0.452 |
| Bonus Discovery Rate | 0.656 |

Target Found: 17, Lucky Guesses: 14

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.765 |
| Hallucination Rate | 0.000 |
| Over-Flagging Score | 0.50 |
| Avg Findings per Sample | 2.12 |

Total: 68, Valid: 52, Hallucinated: 0

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.985 | 0.059 |
| Attack Vector (AVA) | 1.000 | 0.000 |
| Fix Validity (FSV) | 0.956 | 0.095 |

Samples with reasoning scores: 17

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.588 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.016 |
| MCE | 0.016 |
| Overconfidence Rate | 0.031 |
| Brier Score | 0.029 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.835** |
| True Understanding Score | 0.398 |
| Lucky Guess Indicator | 0.438 |

### SUI Components

- f2: 0.975
- target_detection: 0.531
- finding_precision: 0.765
- avg_reasoning: 0.980
- calibration: 0.984

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.969
- Target Detection: 0.531
- Finding Precision: 0.765
- SUI: 0.835

