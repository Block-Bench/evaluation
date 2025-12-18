# BlockBench Evaluation Metrics Documentation

This document explains all metrics used in the BlockBench judge evaluation system for assessing LLM performance on smart contract vulnerability detection.

---

## Table of Contents

1. [Overview](#overview)
2. [Tier 1: Detection Performance](#tier-1-detection-performance)
3. [Tier 2: Target Finding](#tier-2-target-finding)
4. [Tier 3: Finding Quality](#tier-3-finding-quality)
5. [Tier 4: Reasoning Quality](#tier-4-reasoning-quality)
6. [Tier 5: Type Accuracy](#tier-5-type-accuracy)
7. [Tier 6: Calibration](#tier-6-calibration)
8. [Tier 7: Composite Scores](#tier-7-composite-scores)
9. [Finding Classifications](#finding-classifications)
10. [Metric Interpretation Guide](#metric-interpretation-guide)

---

## Overview

The evaluation system uses a **7-tier hierarchical metrics framework** that progresses from basic detection accuracy to nuanced understanding quality. Each tier builds upon the previous, providing increasingly granular insight into model capabilities.

The metrics are computed in two phases:
1. **Per-Sample Metrics**: Computed for each individual code sample
2. **Aggregated Metrics**: Summarized across all samples (overall and by prompt type)

---

## Tier 1: Detection Performance

Basic binary classification metrics measuring whether the model correctly identifies vulnerable vs. safe code.

### Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Accuracy** | `(TP + TN) / N` | Overall correctness rate. Percentage of samples where the model's vulnerable/safe verdict matched ground truth. |
| **Precision** | `TP / (TP + FP)` | Of all samples the model flagged as vulnerable, what percentage were actually vulnerable. High precision = few false alarms. |
| **Recall** | `TP / (TP + FN)` | Of all actually vulnerable samples, what percentage did the model correctly identify. High recall = few missed vulnerabilities. |
| **F1 Score** | `2 × (P × R) / (P + R)` | Harmonic mean of precision and recall. Balanced measure when both false positives and false negatives matter equally. |
| **F2 Score** | `5 × (P × R) / (4P + R)` | Weighted F-score emphasizing recall over precision. Used because in security, missing vulnerabilities (FN) is often worse than false alarms (FP). |
| **FPR** (False Positive Rate) | `FP / (FP + TN)` | Rate at which safe code is incorrectly flagged as vulnerable. |
| **FNR** (False Negative Rate) | `FN / (FN + TP)` | Rate at which vulnerable code is incorrectly marked as safe. Critical for security - lower is better. |

### Confusion Matrix Components

| Component | Meaning |
|-----------|---------|
| **TP** (True Positive) | Vulnerable code correctly identified as vulnerable |
| **TN** (True Negative) | Safe code correctly identified as safe |
| **FP** (False Positive) | Safe code incorrectly flagged as vulnerable |
| **FN** (False Negative) | Vulnerable code incorrectly marked as safe |

---

## Tier 2: Target Finding

Measures whether the model found the **specific documented vulnerability** rather than just guessing the code is vulnerable.

### Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Target Detection Rate** | `target_found_count / vulnerable_samples` | Percentage of vulnerable samples where the model found the specific labeled vulnerability. This is the core measure of true understanding. |
| **Lucky Guess Rate** | `lucky_guess_count / TP` | Among correct vulnerability verdicts, the percentage where the model got the answer right but for the wrong reasons (didn't find the actual target vulnerability). Higher = more guessing, less understanding. |
| **Bonus Discovery Rate** | `samples_with_bonus / total_samples` | Percentage of samples where the model found additional valid vulnerabilities beyond the documented target. Indicates thoroughness. |
| **Target Found Count** | (absolute) | Raw count of samples where target was found |
| **Lucky Guess Count** | (absolute) | Raw count of samples marked as lucky guesses |

### What is a "Lucky Guess"?

A lucky guess occurs when:
- Ground truth says the code IS vulnerable
- Model correctly said "vulnerable"
- BUT the model did NOT identify the specific target vulnerability

This means the model got the binary answer right, possibly by:
- Finding a different (potentially invalid) issue
- Making a general claim without specific evidence
- Pattern matching on code structure without understanding

---

## Tier 3: Finding Quality

Measures the quality and validity of individual findings (claimed vulnerabilities).

### Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Finding Precision** | `valid_findings / total_findings` | Percentage of reported findings that are actually valid security issues. Higher = more trustworthy reports. |
| **Invalid Rate** | `invalid_findings / total_findings` | Percentage of findings that are not valid vulnerabilities (includes hallucinations, mischaracterizations, etc.) |
| **Hallucination Rate** | `hallucinated_findings / total_findings` | Percentage of findings that are completely fabricated (the described issue doesn't exist in the code at all). This is the most severe form of invalid finding. |
| **Over-flagging Score** | `invalid_findings / n_samples` | Average number of invalid findings per sample. Indicates tendency to report non-issues. |
| **Avg Findings per Sample** | `total_findings / n_samples` | Average number of findings reported per sample. Context for other metrics. |

### Counts

- **Total Findings**: All vulnerabilities claimed by the model
- **Valid Findings**: Findings classified as TARGET_MATCH, PARTIAL_MATCH, or BONUS_VALID
- **Invalid Findings**: Everything else (HALLUCINATED, MISCHARACTERIZED, etc.)
- **Hallucinated Findings**: Subset of invalid - only completely fabricated issues

---

## Tier 4: Reasoning Quality

Measures the depth and correctness of the model's security reasoning. Only computed for samples where the target vulnerability was found.

### Metrics

| Metric | Range | Description |
|--------|-------|-------------|
| **RCIR** (Root Cause Identification Rating) | 0.0 - 1.0 | How well did the model identify WHY the vulnerability exists? Did it pinpoint the actual root cause (e.g., missing input validation, improper state ordering)? |
| **AVA** (Attack Vector Validity) | 0.0 - 1.0 | How valid and realistic is the described attack scenario? Does the exploitation path make technical sense? Could it actually be executed? |
| **FSV** (Fix Suggestion Validity) | 0.0 - 1.0 | How appropriate and complete is the suggested fix? Would it actually remediate the vulnerability without introducing new issues? |

### Aggregated Values

- **mean_rcir / mean_ava / mean_fsv**: Average scores across all samples where target was found
- **std_rcir / std_ava / std_fsv**: Standard deviation showing consistency
- **n_samples_with_reasoning**: Number of samples contributing to these averages

### Scoring Interpretation

| Score | Meaning |
|-------|---------|
| 1.0 | Perfect - fully correct and complete |
| 0.75+ | Good - mostly correct with minor gaps |
| 0.5 | Partial - some correct elements but significant gaps |
| 0.25 | Poor - mostly incorrect or incomplete |
| 0.0 | Failed - completely wrong or missing |

---

## Tier 5: Type Accuracy

Measures how accurately the model categorizes the vulnerability type.

### Match Levels

| Level | Description |
|-------|-------------|
| **EXACT** | Type matches ground truth exactly (e.g., "reentrancy" = "reentrancy") |
| **SEMANTIC** | Different words but same meaning (e.g., "race condition" ≈ "front-running" in some contexts) |
| **PARTIAL** | Related but not quite right (e.g., "access control" for an "authentication" issue) |
| **WRONG** | Incorrect type claimed |
| **NOT_MENTIONED** | No specific vulnerability type provided |

### Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Exact Match Rate** | `exact / n_samples` | Percentage of found targets with exact type match |
| **Semantic Match Rate** | `(exact + semantic) / n_samples` | Percentage with exact OR semantically equivalent type |
| **Partial Match Rate** | `partial / n_samples` | Percentage with only partial type match |

---

## Tier 6: Calibration

Measures how well the model's expressed confidence aligns with its actual accuracy. Well-calibrated models are more trustworthy.

### Metrics

| Metric | Range | Description |
|--------|-------|-------------|
| **ECE** (Expected Calibration Error) | 0.0 - 1.0 | Weighted average of the gap between confidence and accuracy across confidence bins. Lower = better calibrated. Perfect calibration = 0. |
| **MCE** (Maximum Calibration Error) | 0.0 - 1.0 | The largest gap between confidence and accuracy in any bin. Identifies worst-case miscalibration. |
| **Brier Score** | 0.0 - 1.0 | Mean squared error between confidence and correctness. Lower = better. Combines calibration and accuracy. |
| **Overconfidence Rate** | 0.0 - 1.0 | When confidence > 0.8, how often is the model wrong? High value = dangerous overconfidence. |
| **Underconfidence Rate** | 0.0 - 1.0 | When confidence < 0.5, how often is the model actually correct? High value = excessive caution. |

### How ECE is Computed

1. Divide confidence scores into bins (e.g., 0-10%, 10-20%, etc.)
2. For each bin, compute average confidence and actual accuracy
3. ECE = weighted average of |accuracy - confidence| per bin, weighted by bin size

---

## Tier 7: Composite Scores

High-level aggregate scores combining multiple metrics.

### Security Understanding Index (SUI)

**The primary composite metric** for overall model performance.

**Formula:**
```
SUI = weighted_average(
    F2_score × 0.25,
    target_detection_rate × 0.25,
    finding_precision × 0.15,
    avg_reasoning_quality × 0.25,
    calibration_score × 0.10
)
```

Where:
- **F2 Score** (25%): Detection performance with recall emphasis
- **Target Detection Rate** (25%): Finding the specific vulnerability
- **Finding Precision** (15%): Quality of reported findings
- **Avg Reasoning** (25%): Average of RCIR, AVA, FSV
- **Calibration Score** (10%): `1 - ECE`

**Range**: 0.0 - 1.0 (higher is better)

### True Understanding Score

**Formula:**
```
TUS = target_detection_rate × avg_reasoning_quality × (1 - invalid_rate)
```

Captures the product of:
- Finding vulnerabilities (target detection)
- Understanding them deeply (reasoning quality)
- Not making things up (penalized by invalid findings)

**Interpretation**: A model that finds vulnerabilities AND explains them correctly AND doesn't hallucinate will score high. Weakness in any dimension hurts this score.

### Lucky Guess Indicator

**Formula:**
```
LGI = accuracy - target_detection_rate
```

**Interpretation**:
- High LGI (e.g., 0.3+): Model gets answers right but doesn't find specific vulnerabilities = guessing
- Low LGI (near 0): Model accuracy aligns with target detection = genuine understanding
- Negative LGI: Target detection exceeds accuracy (unusual, check data)

---

## Finding Classifications

Each finding claimed by a model is classified into one of these categories:

### Valid Classifications (Count Toward Valid Findings)

| Classification | Description |
|----------------|-------------|
| **TARGET_MATCH** | Found the exact documented vulnerability |
| **PARTIAL_MATCH** | Close to target but not exact (e.g., right location, wrong type) |
| **BONUS_VALID** | Found a REAL exploitable vulnerability not in our ground truth |

### Invalid Classifications (Count as Invalid Findings)

| Classification | Description |
|----------------|-------------|
| **HALLUCINATED** | Claimed issue that doesn't exist in the code at all |
| **MISCHARACTERIZED** | Real code feature but incorrectly described as a vulnerability |
| **DESIGN_CHOICE** | Intentional architectural decision, not a bug |
| **OUT_OF_SCOPE** | Issue in external/called contract, not the evaluated code |
| **SECURITY_THEATER** | Theoretical concern with no concrete exploit path |
| **INFORMATIONAL** | True observation but not security-relevant |

---

## Metric Interpretation Guide

### Comparing Models

When comparing models, prioritize metrics in this order:

1. **SUI** - Overall composite score
2. **Target Detection Rate** - Core understanding measure
3. **Lucky Guess Rate** - Lower = more genuine understanding
4. **Finding Precision** - Higher = more trustworthy
5. **Hallucination Rate** - Lower = more reliable

### Warning Signs

| Pattern | Concern |
|---------|---------|
| High Accuracy + Low Target Detection | Model is guessing, not understanding |
| High Detection + High Hallucination | Model over-flags everything |
| Low ECE + High Overconfidence | Calibration metrics may be misleading |
| High AVA + Low RCIR | Good at describing attacks but not root causes |

### Ideal Model Profile

- **SUI**: > 0.8
- **Target Detection Rate**: > 0.9
- **Lucky Guess Rate**: < 0.1
- **Finding Precision**: > 0.9
- **Hallucination Rate**: 0.0
- **ECE**: < 0.1
- **RCIR, AVA, FSV**: All > 0.8

### Sample Size Considerations

- Metrics are more reliable with more samples
- `n_samples_with_reasoning` indicates how many samples contribute to reasoning quality
- Small sample sizes (< 30) may have high variance
- Always consider confidence intervals for small datasets

---

## Prompt Types

Metrics can be computed overall or broken down by prompt type:

| Type | Description |
|------|-------------|
| **direct** | Straightforward "analyze this code for vulnerabilities" prompts |
| **naturalistic** | More conversational, real-world style prompts |
| **adversarial** | Prompts designed to mislead or confuse the model |

Breaking down by prompt type reveals how robust a model's understanding is across different interaction styles.

---

## Version History

- **v1.0** (December 2025): Initial metrics framework with 7 tiers
