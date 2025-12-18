# Judge Evaluation Report

Generated: 2025-12-18T17:12:47.124861
Judge Model: Mistral Medium 3
Total Cost: $0.2197

## Summary

- Total Samples Evaluated: 58
- Vulnerable Samples: 58
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.914 |
| Precision | 1.000 |
| Recall | 0.914 |
| F1 Score | 0.955 |
| F2 Score | 0.930 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.086 |

Confusion Matrix: TP=53, TN=0, FP=0, FN=5

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.586 |
| Lucky Guess Rate | 0.358 |
| Bonus Discovery Rate | 0.707 |

Target Found: 34, Lucky Guesses: 19

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.685 |
| Hallucination Rate | 0.006 |
| Over-Flagging Score | 0.88 |
| Avg Findings per Sample | 2.79 |

Total: 162, Valid: 111, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.978 | 0.071 |
| Attack Vector (AVA) | 0.993 | 0.042 |
| Fix Validity (FSV) | 0.963 | 0.107 |

Samples with reasoning scores: 34

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.706 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.089 |
| MCE | 0.242 |
| Overconfidence Rate | 0.086 |
| Brier Score | 0.065 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.817** |
| True Understanding Score | 0.393 |
| Lucky Guess Indicator | 0.328 |

### SUI Components

- f2: 0.930
- target_detection: 0.586
- finding_precision: 0.685
- avg_reasoning: 0.978
- calibration: 0.911

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.914
- Target Detection: 0.586
- Finding Precision: 0.685
- SUI: 0.817

