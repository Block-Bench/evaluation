# Evaluation Metrics

## Core Detection Metrics

### Sample-Level Metrics
| Metric | Formula | Description |
|--------|---------|-------------|
| **Target Found Rate (Recall)** | targets_found / total_samples | Did the tool find the ground truth vulnerability? |
| **Verdict Accuracy** | correct_verdicts / total_samples | Did tool correctly say "vulnerable" or "not vulnerable"? |
| **Miss Rate** | 1 - target_found_rate | Rate of missed target vulnerabilities |

### Finding-Level Metrics
| Metric | Formula | Description |
|--------|---------|-------------|
| **Precision** | TP / (TP + FP) | What fraction of reported findings are valid? |
| **False Positive Rate** | FP / total_findings | What fraction of findings are false positives? |
| **True Positive Count** | TARGET_MATCH + PARTIAL_MATCH + BONUS_VALID | Count of valid findings |
| **False Positive Count** | INVALID + MISCHARACTERIZED + SECURITY_THEATER | Count of invalid findings |

### Combined Metrics
| Metric | Formula | Description |
|--------|---------|-------------|
| **F1 Score** | 2 * (Precision * Recall) / (Precision + Recall) | Harmonic mean of precision and recall |

## Volume Metrics
| Metric | Description |
|--------|-------------|
| **Total Findings** | Total number of findings reported |
| **Avg Findings per Sample** | Average number of findings per contract |

## Classification Breakdown (LLM Judge)

### True Positive Categories
- **TARGET_MATCH**: Finding correctly identifies the ground truth vulnerability
- **PARTIAL_MATCH**: Finding relates to target but misses key aspects
- **BONUS_VALID**: Finding identifies a real vulnerability NOT in ground truth

### False Positive Categories
- **INVALID**: Finding is technically incorrect
- **MISCHARACTERIZED**: Real pattern but wrong vulnerability type assigned
- **DESIGN_CHOICE**: Intentional pattern flagged as issue
- **OUT_OF_SCOPE**: Non-security issue (gas, style)
- **SECURITY_THEATER**: Technically true but unexploitable
- **INFORMATIONAL**: Not a vulnerability claim

## Type Match Quality (LLM Judge)
- **exact**: Tool's detector name directly matches vulnerability type
- **semantic**: Different name but same vulnerability class
- **partial**: Related but incomplete match
- **wrong**: Completely different vulnerability type
- **not_mentioned**: Target type not detected at all

## What Rule-Based vs LLM Judge Can Compute

| Metric | Rule-Based | LLM Judge |
|--------|------------|-----------|
| Target Found Rate | Yes | Yes |
| Verdict Accuracy | Yes | Yes |
| Total Findings | Yes | Yes |
| Precision | No | Yes |
| F1 Score | No | Yes |
| TP/FP Counts | No | Yes |
| Classification Breakdown | No | Yes |
| Type Match Quality | No | Yes |
