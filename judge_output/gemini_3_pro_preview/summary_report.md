# Judge Evaluation Report

Generated: 2025-12-18T19:15:45.120492
Judge Model: Mistral Medium 3
Total Cost: $0.2544

## Summary

- Total Samples Evaluated: 15
- Vulnerable Samples: 15
- Safe Samples: 0

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | 0.733 |
| Precision | 1.000 |
| Recall | 0.733 |
| F1 Score | 0.846 |
| F2 Score | 0.775 |
| False Positive Rate | 0.000 |
| False Negative Rate | 0.267 |

Confusion Matrix: TP=11, TN=0, FP=0, FN=4

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | 0.333 |
| Lucky Guess Rate | 0.545 |
| Bonus Discovery Rate | 0.333 |

Target Found: 5, Lucky Guesses: 6

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | 0.232 |
| Hallucination Rate | 0.000 |
| Over-Flagging Score | 2.87 |
| Avg Findings per Sample | 3.73 |

Total: 56, Valid: 13, Hallucinated: 0

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | 0.850 | 0.122 |
| Attack Vector (AVA) | 0.800 | 0.187 |
| Fix Validity (FSV) | 0.800 | 0.400 |

Samples with reasoning scores: 5

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | 0.400 |
| Semantic Match Rate | 1.000 |
| Partial Match Rate | 0.000 |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | 0.229 |
| MCE | 0.233 |
| Overconfidence Rate | 0.286 |
| Brier Score | 0.248 |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **0.593** |
| True Understanding Score | 0.063 |
| Lucky Guess Indicator | 0.400 |

### SUI Components

- f2: 0.775
- target_detection: 0.333
- finding_precision: 0.232
- avg_reasoning: 0.817
- calibration: 0.771

## Per-Prompt-Type Breakdown

### DIRECT

- Accuracy: 0.800
- Target Detection: 0.200
- Finding Precision: 0.286
- SUI: 0.629

### NATURALISTIC

- Accuracy: 0.600
- Target Detection: 0.400
- Finding Precision: 0.214
- SUI: 0.554

### ADVERSARIAL

- Accuracy: 0.800
- Target Detection: 0.400
- Finding Precision: 0.238
- SUI: 0.576

