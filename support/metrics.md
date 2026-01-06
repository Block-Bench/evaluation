# BlockBench Evaluation Metrics

This document provides a comprehensive overview of all evaluation metrics used in the BlockBench benchmark for assessing LLM smart contract vulnerability detection capabilities.

---

## 1. Primary Ranking Metrics

### 1.1 Target Detection Rate (TDR)

**Definition:** The proportion of samples where the specific documented vulnerability was correctly identified with both type AND location accuracy.

**Formula:**

```
TDR = |{i ∈ D | target_found_i = True}| / |D|
```

**Classification Criteria:** A finding is classified as `target_found = True` if and only if:

- Type match is at least "partial" (vulnerability type correctly identified)
- Location match is at least "partial" (vulnerable function/line correctly identified)

**Purpose:** Primary metric reflecting genuine vulnerability understanding. Unlike binary accuracy, TDR requires models to identify the _specific_ flaw, not just detect that something is wrong.

---

### 1.2 Security Understanding Index (SUI)

**Definition:** A weighted composite metric balancing detection capability, reasoning quality, and precision.

**Formula:**

```
SUI = w_TDR · TDR + w_R · R̄ + w_Prec · Finding_Precision
```

**Default Weights:**
| Component | Weight | Rationale |
|-----------|--------|-----------|
| TDR | 0.40 | Primary metric reflecting genuine vulnerability understanding |
| Reasoning Quality (R̄) | 0.30 | Measures depth of security reasoning when vulnerabilities are found |
| Finding Precision | 0.30 | Penalizes false alarms and hallucinations |

**Sensitivity Analysis:** Rankings exhibit perfect stability (Spearman's ρ = 1.000) across five weight configurations:

- Balanced (0.33/0.33/0.34)
- Detection-Default (0.40/0.30/0.30)
- Quality-First (0.30/0.40/0.30)
- Precision-First (0.30/0.30/0.40)
- Detection-Heavy (0.50/0.25/0.25)

---

## 2. Detection & Classification Metrics

### 2.1 Accuracy

**Definition:** Standard binary classification accuracy.

**Formula:**

```
Accuracy = (TP + TN) / N
```

Where:

- TP = True Positives (correctly identified as vulnerable)
- TN = True Negatives (correctly identified as safe)
- N = Total number of samples

**Limitation:** The accuracy-TDR gap exposes fundamental metric limitations. A model can achieve high accuracy (e.g., 88%) while having low TDR (e.g., 18%) by simply classifying samples as "vulnerable" without identifying specific flaws.

---

### 2.2 Lucky Guess Rate (LGR)

**Definition:** The proportion of correct verdicts where the target vulnerability was NOT actually found.

**Formula:**

```
LGR = |{i | ŷ_i = y_i ∧ target_found_i = False}| / |{i | ŷ_i = y_i}|
```

**Purpose:** Exposes pattern matching without genuine understanding. High LGR indicates the model correctly predicts vulnerable/safe status without actually identifying the specific vulnerability.

**Key Insight:** This metric directly operationalizes the "memorization vs. understanding" distinction central to BlockBench's thesis.

---

### 2.3 Finding Precision

**Definition:** The proportion of reported findings that are correct.

**Formula:**

```
Finding_Precision = Σ|F_correct_i| / Σ|F_i|
```

Where:

- F_correct_i = Subset of correct findings for sample i
- F_i = Set of all findings reported for sample i

**Purpose:** Measures the reliability of model outputs. Low precision indicates the model reports many false positives or hallucinated vulnerabilities.

---

### 2.4 Hallucination Rate

**Definition:** The proportion of fabricated findings among all reported findings.

**Formula:**

```
Hallucination_Rate = Σ|F_hallucinated_i| / Σ|F_i|
```

**Purpose:** Quantifies how often models report completely fabricated issues not present in the code.

---

## 3. Reasoning Quality Metrics

For samples where the target vulnerability was found, three reasoning dimensions are evaluated on [0, 1] scales.

### 3.1 RCIR (Root Cause Identification and Reasoning)

**Definition:** Does the explanation correctly identify _why_ the vulnerability exists?

**Scale:** 0.0 - 1.0

**Evaluation Criteria:**

- Correctly identifies the underlying code pattern causing the vulnerability
- Explains the logical flaw or missing protection
- Demonstrates understanding of the vulnerability mechanism

---

### 3.2 AVA (Attack Vector Accuracy)

**Definition:** Does the explanation correctly describe _how_ to exploit the flaw?

**Scale:** 0.0 - 1.0

**Evaluation Criteria:**

- Provides specific attack steps
- Describes the sequence of operations an attacker would use
- Demonstrates understanding of exploitation mechanics

---

### 3.3 FSV (Fix Suggestion Validity)

**Definition:** Is the proposed remediation correct and sufficient?

**Scale:** 0.0 - 1.0

**Evaluation Criteria:**

- Proposed fix addresses the root cause
- Fix is technically correct and implementable
- Fix does not introduce new vulnerabilities

---

### 3.4 Mean Reasoning Quality (R̄)

**Definition:** Average reasoning quality across the three dimensions.

**Formula:**

```
R̄ = (1 / |D_found|) × Σ[(RCIR_i + AVA_i + FSV_i) / 3]
```

Where D_found = {i ∈ D | target_found_i = True}

**Note:** Only computed for samples where the target vulnerability was successfully detected.

---

## 4. Finding Classification Categories

The LLM judge classifies each reported finding into one of five categories:

| Category             | Definition                                                                                 | Implication                  |
| -------------------- | ------------------------------------------------------------------------------------------ | ---------------------------- |
| **TARGET_MATCH**     | Finding correctly identifies the documented target vulnerability (type and location match) | Counts toward TDR            |
| **BONUS_VALID**      | Finding identifies a genuine _undocumented_ vulnerability                                  | Valid finding, not penalized |
| **MISCHARACTERIZED** | Finding identifies the correct location but wrong vulnerability type                       | Partial understanding        |
| **SECURITY_THEATER** | Finding flags non-exploitable code patterns without demonstrable impact                    | False positive               |
| **HALLUCINATED**     | Finding reports completely fabricated issues not present in the code                       | False positive               |

---

## 5. Match Assessment Criteria

### 5.1 Type Match Levels

| Level       | Definition                                         |
| ----------- | -------------------------------------------------- |
| **exact**   | Perfect match with ground truth vulnerability type |
| **partial** | Semantically related vulnerability type            |
| **wrong**   | Different/incorrect vulnerability type             |
| **none**    | No vulnerability type specified                    |

### 5.2 Location Match Levels

| Level       | Definition                   |
| ----------- | ---------------------------- |
| **exact**   | Precise lines identified     |
| **partial** | Correct function identified  |
| **wrong**   | Different location specified |
| **none**    | Location unspecified         |

**TARGET_MATCH Requirement:** Both type AND location must be at least "partial".

---

## 6. Validation Metrics

### 6.1 Inter-Rater Reliability

**Cohen's Kappa (κ):** 0.84 (almost perfect agreement)

**Formula:**

```
κ = (p_o - p_e) / (1 - p_e)
```

Where:

- p_o = observed agreement
- p_e = expected agreement by chance

**Interpretation:**

- κ > 0.80 = Almost perfect agreement
- 0.60 < κ ≤ 0.80 = Substantial agreement

---

### 6.2 Human-Judge Correlation

**Pearson's ρ:** 0.85 (p < 0.0001)

**Formula:**

```
ρ = Σ(x_i - x̄)(y_i - ȳ) / √[Σ(x_i - x̄)² × Σ(y_i - ȳ)²]
```

**Purpose:** Measures correlation between human expert scores and LLM judge scores.

---

### 6.3 Judge Performance

| Metric    | Value |
| --------- | ----- |
| Precision | 0.84  |
| Recall    | 1.00  |
| F1 Score  | 0.91  |

**Interpretation:** The judge confirmed all expert-detected vulnerabilities (perfect recall) while flagging 9 additional cases (84% precision).

---

### 6.4 Ranking Stability

**Spearman's ρ:** 1.000 (perfect correlation)

**Formula:**

```
ρ = 1 - [6 × Σd_i²] / [n(n² - 1)]
```

Where:

- d_i = difference between ranks for model i under two configurations
- n = number of models

**Purpose:** Validates that SUI rankings remain stable across different weight configurations.

---

## 7. Summary Table

| Category       | Metric                             | Type        | Range   |
| -------------- | ---------------------------------- | ----------- | ------- |
| **Primary**    | Target Detection Rate (TDR)        | Percentage  | 0-100%  |
| **Primary**    | Security Understanding Index (SUI) | Composite   | 0-1     |
| **Detection**  | Accuracy                           | Percentage  | 0-100%  |
| **Detection**  | Lucky Guess Rate (LGR)             | Percentage  | 0-100%  |
| **Detection**  | Finding Precision                  | Percentage  | 0-100%  |
| **Detection**  | Hallucination Rate                 | Percentage  | 0-100%  |
| **Reasoning**  | RCIR                               | Score       | 0-1     |
| **Reasoning**  | AVA                                | Score       | 0-1     |
| **Reasoning**  | FSV                                | Score       | 0-1     |
| **Reasoning**  | Mean Reasoning Quality (R̄)         | Score       | 0-1     |
| **Validation** | Cohen's κ                          | Coefficient | -1 to 1 |
| **Validation** | Pearson's ρ                        | Coefficient | -1 to 1 |
| **Validation** | Spearman's ρ                       | Coefficient | -1 to 1 |
| **Validation** | F1 Score                           | Score       | 0-1     |

---

## 8. Key Insights

### 8.1 Why TDR over Accuracy?

The accuracy-TDR gap reveals that binary classification inadequately measures security understanding:

- **Llama 3.1 405B:** 88% accuracy but only 18% TDR
- **Gap:** 70 percentage points

This demonstrates that models can correctly classify samples as "vulnerable" without identifying the specific flaw — providing no actionable value to security practitioners.

### 8.2 Why Lucky Guess Rate Matters

LGR directly operationalizes the distinction between:

- **Genuine understanding:** Model identifies the specific vulnerability
- **Pattern matching:** Model recognizes "vulnerable-looking" code without pinpointing the issue

### 8.3 Why Reasoning Quality Matters

High TDR with low reasoning quality would indicate superficial detection. The RCIR/AVA/FSV metrics ensure models can:

1. Explain the root cause
2. Describe the attack vector
3. Propose valid fixes

---

## 9. Potential Additions (For Future Consideration)

Metrics that could strengthen the evaluation framework:

| Metric                               | Purpose                                                                      |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| **Expected Calibration Error (ECE)** | Measure confidence calibration — are confident predictions actually correct? |
| **McNemar's Test**                   | Statistical significance testing between model pairs                         |
| **Bootstrap Confidence Intervals**   | Uncertainty quantification for TDR and SUI                                   |
| **Per-Vulnerability-Type TDR**       | Breakdown by vulnerability class (Reentrancy, Access Control, etc.)          |
| **Transformation Degradation Score** | Quantify performance drop across adversarial transformations                 |

---

_Document generated for BlockBench ACL 2026 submission preparation._
