# Judge Evaluation Report

Generated: 2025-12-18T15:34:56.610354
Judge Model: Mistral Medium 3
Total Cost: $0.1860

## Summary

- Total Samples Evaluated: 49
- Vulnerable Samples: 49
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.980 |
| Precision | 1.000 |
| Recall | 0.980 |
| F1 Score | 0.990 |
| F2 Score | 0.984 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.020 |

Confusion Matrix: TP=48, TN=0, FP=0, FN=1

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.612 |
| Lucky Guess Rate | 0.375 |
| Bonus Discovery Rate | 0.653 |

Target Found: 30, Lucky Guesses: 18

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.750 |
| Hallucination Rate | 0.009 |
| Over-Flagging Score | 0.55 |
| Avg Findings per Sample | 2.20 |

Total: 108, Valid: 81, Hallucinated: 1

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.975 | 0.099 |
| Attack Vector (AVA) | 0.975 | 0.135 |
| Fix Validity (FSV) | 0.942 | 0.190 |

Samples with reasoning scores: 30

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.733 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.011 |
| MCE | 0.100 |
| Overconfidence Rate | 0.020 |
| Brier Score | 0.019 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.851** |
| True Understanding Score | 0.443 |
| Lucky Guess Indicator | 0.367 |

### SUI Components

- f2: 0.984
- target_detection: 0.612
- finding_precision: 0.750
- avg_reasoning: 0.964
- calibration: 0.989

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.980
- Target Detection: 0.612
- Finding Precision: 0.750
- SUI: 0.851

