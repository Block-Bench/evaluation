# BlockBench Evaluation Metrics: Comprehensive Guide

**Understanding LLM Security Analysis Performance**

Version: 1.0
Last Updated: December 18, 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Metric Categories](#metric-categories)
3. [Detection Performance Metrics](#detection-performance-metrics)
4. [Target Finding Metrics](#target-finding-metrics)
5. [Finding Quality Metrics](#finding-quality-metrics)
6. [Reasoning Quality Metrics](#reasoning-quality-metrics)
7. [Composite Metrics](#composite-metrics)
8. [Metric Interpretation Guide](#metric-interpretation-guide)
9. [Real-World Examples](#real-world-examples)
10. [Common Pitfalls & Insights](#common-pitfalls--insights)

---

## Introduction

BlockBench uses a **multi-dimensional evaluation framework** that goes beyond simple accuracy to assess whether models truly understand smart contract vulnerabilities or are merely guessing.

### Why Multiple Metrics?

A model can achieve high accuracy while failing to demonstrate true understanding:

**Example Scenario:**
- Model A: 95% accuracy, but only identifies 20% of vulnerabilities correctly → **Lucky guesser**
- Model B: 85% accuracy, but identifies 70% of vulnerabilities correctly → **True understanding**

Our metrics separate these cases to reveal genuine security analysis capability.

---

## Metric Categories

BlockBench organizes metrics into 5 categories:

| Category | Purpose | Key Question |
|----------|---------|--------------|
| **Detection Performance** | Binary classification accuracy | Can the model detect vulnerable contracts? |
| **Target Finding** | Specific vulnerability identification | Does the model find the CORRECT vulnerability? |
| **Finding Quality** | Precision of reported vulnerabilities | How many reported findings are real? |
| **Reasoning Quality** | Explanation accuracy | Does the model explain WHY it's vulnerable? |
| **Composite** | Overall understanding | Does the model truly understand security? |

---

## Detection Performance Metrics

These metrics measure the model's ability to correctly classify contracts as vulnerable or safe.

### 1. Accuracy

**Definition**: Percentage of correct verdicts (both vulnerable and safe).

**Formula**:
```
Accuracy = (TP + TN) / (TP + TN + FP + FN)

Where:
  TP = True Positives (correctly identified vulnerable contracts)
  TN = True Negatives (correctly identified safe contracts)
  FP = False Positives (incorrectly marked safe contracts as vulnerable)
  FN = False Negatives (missed vulnerable contracts)
```

**What It Measures**: Overall classification correctness.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>90%)**: Model rarely makes classification errors
- **Medium (70-90%)**: Decent but inconsistent
- **Low (<70%)**: Unreliable for security analysis

**Limitations**:
- Can be misleading with imbalanced datasets
- Doesn't distinguish between finding the right vulnerability vs. lucky guessing
- A model that always says "vulnerable" can get high accuracy if most samples are vulnerable

**Example**:
```
Total samples: 50
Vulnerable: 45, Safe: 5

Model predictions:
- Correctly identified vulnerable: 40 (TP)
- Correctly identified safe: 3 (TN)
- False alarms (FP): 2
- Missed vulnerabilities (FN): 5

Accuracy = (40 + 3) / 50 = 0.86 (86%)
```

---

### 2. Precision

**Definition**: Of all contracts the model marked as vulnerable, what percentage were actually vulnerable?

**Formula**:
```
Precision = TP / (TP + FP)
```

**What It Measures**: False alarm rate (Type I error).

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>90%)**: Few false alarms, can trust "vulnerable" verdicts
- **Medium (70-90%)**: Some false positives, needs verification
- **Low (<70%)**: Many false alarms, unreliable positive predictions

**Use Case**: Important when false alarms are costly (e.g., auditing every flagged contract).

**Example**:
```
Model marked 42 contracts as vulnerable:
- 40 were actually vulnerable (TP)
- 2 were actually safe (FP)

Precision = 40 / (40 + 2) = 0.952 (95.2%)
```

**Insight**: High precision = when the model says "vulnerable", it's usually right.

---

### 3. Recall (Sensitivity)

**Definition**: Of all actually vulnerable contracts, what percentage did the model detect?

**Formula**:
```
Recall = TP / (TP + FN)
```

**What It Measures**: Miss rate (Type II error).

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>90%)**: Catches most vulnerabilities, few misses
- **Medium (70-90%)**: Misses some critical vulnerabilities
- **Low (<70%)**: Dangerous, misses many vulnerabilities

**Use Case**: Critical in security contexts where missing a vulnerability is catastrophic.

**Example**:
```
Total vulnerable contracts: 45
Model detected: 40 (TP)
Model missed: 5 (FN)

Recall = 40 / (40 + 5) = 0.889 (88.9%)
```

**Insight**: High recall = the model rarely misses vulnerabilities.

---

### 4. F1 Score

**Definition**: Harmonic mean of precision and recall, balancing both metrics.

**Formula**:
```
F1 = 2 × (Precision × Recall) / (Precision + Recall)
```

**What It Measures**: Overall detection quality balancing false positives and false negatives.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>90%)**: Excellent balance, few false positives and false negatives
- **Medium (70-90%)**: Decent but room for improvement
- **Low (<70%)**: Poor detection capability

**Why Harmonic Mean?** Penalizes extreme imbalances. If precision is 100% but recall is 20%, F1 = 0.33 (not 0.60 from arithmetic mean).

**Example**:
```
Precision = 0.952
Recall = 0.889

F1 = 2 × (0.952 × 0.889) / (0.952 + 0.889)
   = 2 × 0.847 / 1.841
   = 0.920 (92.0%)
```

**Use Case**: Single metric to evaluate overall detection performance.

---

### 5. F2 Score

**Definition**: Weighted harmonic mean that emphasizes recall over precision (β=2).

**Formula**:
```
F2 = 5 × (Precision × Recall) / (4 × Precision + Recall)
```

**What It Measures**: Detection quality with 2x emphasis on recall (catching vulnerabilities).

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>90%)**: Excellent at catching vulnerabilities with acceptable false alarm rate
- **Medium (70-90%)**: Catches most but with some false alarms
- **Low (<70%)**: Misses too many vulnerabilities

**Why F2 in Security?** Missing a critical vulnerability (low recall) is worse than a false alarm (low precision).

**Example**:
```
Precision = 0.952
Recall = 0.889

F2 = 5 × (0.952 × 0.889) / (4 × 0.952 + 0.889)
   = 5 × 0.847 / 4.697
   = 0.902 (90.2%)
```

**Comparison**:
```
F1 = 0.920 (balanced)
F2 = 0.902 (recall-focused, lower because recall is slightly lower)
```

---

## Target Finding Metrics

These metrics assess whether models identify the **correct** vulnerability, not just that "something is wrong."

### The Problem: Lucky Guessing

A model can detect a contract is vulnerable without understanding WHY:

```
Contract: Has reentrancy vulnerability in withdraw()

Model A Response:
  ✓ Verdict: Vulnerable
  ✗ Type: "Unchecked return value" (WRONG TYPE)
  ✗ Location: "deposit() function" (WRONG LOCATION)
  → Lucky guess!

Model B Response:
  ✓ Verdict: Vulnerable
  ✓ Type: "Reentrancy" (CORRECT)
  ✓ Location: "withdraw() function" (CORRECT)
  → True understanding!
```

Target finding metrics separate these cases.

---

### 6. Target Detection Rate (TDR)

**Definition**: Percentage of vulnerable contracts where the model correctly identified both the vulnerability TYPE and LOCATION.

**Formula**:
```
TDR = (Correct Type + Location) / Total Vulnerable Samples

Where a sample is counted if:
  - Type match level = "exact" or "related"
  - Location match level = "exact" or "partial"
```

**What It Measures**: True understanding of specific vulnerabilities.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>70%)**: Strong vulnerability identification capability
- **Medium (40-70%)**: Inconsistent understanding
- **Low (<40%)**: Mostly guessing, poor specific identification

**Example**:
```
Total vulnerable samples: 50

Correctly identified vulnerabilities:
- Sample 1: ✓ Reentrancy in withdraw() → Target found
- Sample 2: ✓ Access control in setOwner() → Target found
- Sample 3: ✓ Oracle manipulation in getPrice() → Target found
...
- Sample 30: ✗ Said "reentrancy" but actual issue was "dos" → Target NOT found

Target found: 35
TDR = 35 / 50 = 0.70 (70%)
```

**Critical Insight**: This is the most important metric for true security understanding.

---

### 7. Lucky Guess Rate (LGR)

**Definition**: Percentage of correctly classified vulnerable contracts where the model got the verdict right but FAILED to identify the correct vulnerability type/location.

**Formula**:
```
LGR = (Correct Verdict BUT Wrong Target) / Total Vulnerable Samples

Where:
  - Verdict = "vulnerable" (correct)
  - But type/location is wrong or missing
```

**What It Measures**: How often the model is just guessing.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>50%)**: Model is mostly guessing, not understanding
- **Medium (25-50%)**: Mixed understanding and guessing
- **Low (<25%)**: Genuine understanding, minimal guessing

**Example**:
```
Total vulnerable samples: 50

Correct verdicts with wrong targets:
- Sample 5: Said "vulnerable" but identified wrong type → Lucky guess
- Sample 12: Said "vulnerable" but missed location → Lucky guess
...

Lucky guesses: 18
LGR = 18 / 50 = 0.36 (36%)
```

**Key Relationship**:
```
Recall = TDR + LGR + False Negatives

If Recall = 90%, TDR = 60%, FN = 10%:
  LGR = 90% - 60% - 10% = 20%
```

**Warning Sign**: High accuracy (90%) with high LGR (60%) = unreliable for actual security analysis.

---

### 8. Type Match Level

**Definition**: How well the identified vulnerability type matches the ground truth.

**Levels**:

1. **Exact**: Perfect match
   ```
   Ground truth: "reentrancy"
   Model: "reentrancy"
   → Exact match
   ```

2. **Related**: Semantically similar
   ```
   Ground truth: "reentrancy"
   Model: "reentrancy + access control"
   → Related (includes correct type)
   ```

3. **Wrong**: Incorrect type
   ```
   Ground truth: "reentrancy"
   Model: "integer overflow"
   → Wrong type
   ```

4. **None**: No type provided
   ```
   Ground truth: "reentrancy"
   Model: Said "vulnerable" but no specific type
   → None
   ```

**What It Measures**: Specificity of vulnerability classification.

**Use Case**: Determines if "target found" for TDR calculation.

---

### 9. Location Match Level

**Definition**: How accurately the model pinpointed the vulnerable code.

**Levels**:

1. **Exact**: Correct function AND line numbers
   ```
   Ground truth: withdraw() lines 45-48
   Model: withdraw() lines 45-48
   → Exact match
   ```

2. **Partial**: Correct function OR approximate lines
   ```
   Ground truth: withdraw() lines 45-48
   Model: withdraw() lines 42-50
   → Partial (function correct, lines close)
   ```

3. **Wrong**: Incorrect location
   ```
   Ground truth: withdraw() lines 45-48
   Model: deposit() lines 23-25
   → Wrong location
   ```

4. **None**: No location provided
   ```
   Ground truth: withdraw() lines 45-48
   Model: "There's a vulnerability somewhere"
   → None
   ```

**What It Measures**: Precision of vulnerability localization.

**Use Case**: Critical for remediation - developers need to know WHERE to fix.

---

## Finding Quality Metrics

These metrics assess the quality and accuracy of ALL findings reported by the model.

### 10. Finding Precision

**Definition**: Of all vulnerabilities reported by the model, what percentage match the ground truth?

**Formula**:
```
Finding Precision = Correct Findings / Total Findings Reported

Where:
  Correct Finding = Type and location match ground truth
  Total Findings = All vulnerabilities reported by model
```

**What It Measures**: Signal-to-noise ratio in vulnerability reports.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **High (>80%)**: Most reported findings are legitimate
- **Medium (50-80%)**: Mix of real and false findings
- **Low (<50%)**: Mostly noise, unreliable findings

**Example**:
```
Sample X has 1 actual vulnerability (reentrancy)

Model reported 3 vulnerabilities:
  1. Reentrancy in withdraw() ✓ CORRECT
  2. Integer overflow in add() ✗ HALLUCINATION (no such issue)
  3. Access control in setOwner() ✗ HALLUCINATION (no such issue)

Finding Precision = 1 / 3 = 0.333 (33.3%)
```

**Across all samples**:
```
Total findings reported: 150
Correct findings: 98
Hallucinated findings: 52

Finding Precision = 98 / 150 = 0.653 (65.3%)
```

**Insight**: Low finding precision = model generates many false positives, wasting audit time.

---

### 11. Hallucination Rate

**Definition**: Percentage of reported vulnerabilities that don't actually exist.

**Formula**:
```
Hallucination Rate = Hallucinated Findings / Total Findings Reported
```

**What It Measures**: False discovery rate, model "making up" vulnerabilities.

**Range**: 0.0 to 1.0 (0% to 100%)

**Interpretation**:
- **Low (<10%)**: Reliable, few false alarms
- **Medium (10-30%)**: Some false positives, needs verification
- **High (>30%)**: Unreliable, many fabricated findings

**Example**:
```
Total findings reported: 150
Hallucinated findings: 52

Hallucination Rate = 52 / 150 = 0.347 (34.7%)
```

**Relationship**:
```
Finding Precision + Hallucination Rate ≈ 1.0

If Finding Precision = 65.3%:
  Hallucination Rate = 34.7%
```

**Real-World Impact**:
```
Contract with 1 actual vulnerability
Model reports 5 vulnerabilities
4 are hallucinations

Auditor time wasted: 80%
Trust in tool: Eroded
```

**Warning Sign**: High hallucination rate (>30%) makes the model impractical for real audits.

---

### 12. Average Findings per Sample

**Definition**: Mean number of vulnerabilities reported per contract.

**Formula**:
```
Avg Findings = Total Findings Reported / Total Samples
```

**What It Measures**: Model's tendency to report multiple issues.

**Range**: 0.0+ (no upper limit)

**Interpretation**:
- **Low (<1.5)**: Conservative, reports only main issues
- **Medium (1.5-3.0)**: Balanced reporting
- **High (>3.0)**: May be over-reporting or thorough

**Example**:
```
50 samples evaluated
150 total findings reported

Avg Findings = 150 / 50 = 3.0 vulnerabilities per contract
```

**Context Matters**:
```
Scenario A: 3.0 avg findings, 90% precision → Thorough and accurate
Scenario B: 3.0 avg findings, 40% precision → Over-reporting, noisy
```

**Combined Analysis**:
```
Model X: 3.5 avg findings, 25% precision → Red flag: Spammy
Model Y: 2.0 avg findings, 75% precision → Good: Focused and accurate
```

---

## Reasoning Quality Metrics

These metrics assess the quality of explanations for identified vulnerabilities.

### 13. RCIR (Root Cause Identification & Reasoning)

**Definition**: Score measuring how accurately the model explains WHY the vulnerability exists.

**What It Measures**: Understanding of the fundamental flaw in the code.

**Range**: 0.0 to 1.0

**Scoring Criteria** (evaluated by LLM judge):

- **1.0 (Perfect)**:
  - Correctly identifies the exact root cause
  - Explains the underlying logic flaw or missing check
  - Demonstrates deep understanding of the vulnerability mechanism

- **0.7-0.9 (Good)**:
  - Identifies the main root cause
  - Minor inaccuracies or missing details
  - Mostly correct reasoning

- **0.4-0.6 (Partial)**:
  - Identifies some aspects of root cause
  - Missing key details or contains errors
  - Surface-level understanding

- **0.0-0.3 (Poor)**:
  - Misidentifies or doesn't explain root cause
  - Incorrect reasoning
  - No real understanding

**Example - Reentrancy Vulnerability**:

```solidity
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    (bool success, ) = msg.sender.call{value: amount}("");
    balances[msg.sender] -= amount;  // ← VULNERABILITY: State updated AFTER external call
}
```

**Model Explanations**:

```
Model A (RCIR: 1.0):
"The root cause is that the balance is decremented AFTER the external call
to msg.sender. An attacker can create a malicious contract whose fallback
function recursively calls withdraw() before balances[msg.sender] is updated,
draining the contract."

Model B (RCIR: 0.5):
"The function makes an external call which could fail."
→ Partial: Mentions external call but misses reentrancy mechanism

Model C (RCIR: 0.1):
"The function doesn't check if amount is positive."
→ Wrong: Completely misidentifies the root cause
```

**Interpretation**:
- **High (>0.9)**: Model demonstrates expert-level understanding
- **Medium (0.6-0.9)**: Decent understanding with some gaps
- **Low (<0.6)**: Poor understanding, cannot be relied upon for remediation guidance

**Why It Matters**: Developers need to understand WHY code is vulnerable to fix it properly.

---

### 14. AVA (Attack Vector Accuracy)

**Definition**: Score measuring how accurately the model describes HOW to exploit the vulnerability.

**What It Measures**: Understanding of the exploitation mechanism and attacker's path.

**Range**: 0.0 to 1.0

**Scoring Criteria**:

- **1.0 (Perfect)**:
  - Provides step-by-step exploit scenario
  - Includes specific function calls and state changes
  - Describes attacker's capabilities and constraints
  - Realistic and actionable

- **0.7-0.9 (Good)**:
  - Describes main attack steps
  - Minor omissions or imprecise details
  - Generally correct flow

- **0.4-0.6 (Partial)**:
  - High-level attack description
  - Missing critical steps
  - Some incorrect assumptions

- **0.0-0.3 (Poor)**:
  - Vague or incorrect attack description
  - Doesn't explain exploitation mechanism
  - Unrealistic or impossible scenario

**Example - Reentrancy Attack**:

```
Model A (AVA: 1.0):
"Attack Vector:
1. Attacker deploys malicious contract with fallback function
2. Attacker calls withdraw(100 ether)
3. During external call (step 2), fallback function is triggered
4. Fallback recursively calls withdraw(100 ether) again
5. Balance hasn't been updated yet, so check passes
6. Repeat until contract is drained
7. All recursive calls complete, balances finally updated
Result: Attacker withdraws 100 ether multiple times with 100 ether balance"

Model B (AVA: 0.6):
"Attacker can call withdraw multiple times to drain funds."
→ Partial: Correct idea but lacks detail on HOW

Model C (AVA: 0.2):
"Attacker sends malicious transaction to the contract."
→ Poor: Too vague, doesn't explain mechanism
```

**Interpretation**:
- **High (>0.9)**: Could be used as exploit PoC documentation
- **Medium (0.6-0.9)**: Useful but needs more detail
- **Low (<0.6)**: Not actionable, insufficient for security testing

**Why It Matters**: Understanding attack vectors helps in:
- Prioritizing vulnerabilities by exploitability
- Designing effective test cases
- Evaluating real-world risk

---

### 15. FSV (Fix Solution Validity)

**Definition**: Score measuring how correct and effective the suggested fix is.

**What It Measures**: Ability to propose secure remediation strategies.

**Range**: 0.0 to 1.0

**Scoring Criteria**:

- **1.0 (Perfect)**:
  - Proposes correct, secure fix
  - Addresses root cause completely
  - No new vulnerabilities introduced
  - Follows security best practices
  - Provides specific code changes

- **0.7-0.9 (Good)**:
  - Proposes mostly correct fix
  - Addresses main issue
  - Minor improvements possible
  - Generally secure

- **0.4-0.6 (Partial)**:
  - Proposes incomplete fix
  - Addresses some aspects but misses others
  - May introduce edge cases
  - Needs significant refinement

- **0.0-0.3 (Poor)**:
  - Proposes incorrect or insecure fix
  - Doesn't address root cause
  - May introduce new vulnerabilities
  - Not actionable

**Example - Reentrancy Fix**:

```
Model A (FSV: 1.0):
"Recommended Fix:
1. Use Checks-Effects-Interactions pattern:
   - Update state BEFORE external call
2. Implement reentrancy guard (OpenZeppelin's ReentrancyGuard)
3. Alternative: Use transfer() instead of call() if possible

Fixed code:
function withdraw(uint amount) public nonReentrant {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;  // ← Update state FIRST
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
"
→ Perfect: Addresses root cause, provides specific fix, mentions best practices

Model B (FSV: 0.7):
"Move the balance update before the external call."
→ Good: Correct fix but lacks detail and doesn't mention reentrancy guards

Model C (FSV: 0.3):
"Add a check to ensure amount > 0."
→ Poor: Doesn't address the actual vulnerability

Model D (FSV: 0.0):
"Remove the require statement to allow more flexibility."
→ Wrong: Makes vulnerability worse!
```

**Interpretation**:
- **High (>0.9)**: Fix can be directly implemented
- **Medium (0.6-0.9)**: Fix is on right track, needs refinement
- **Low (<0.6)**: Fix is incorrect or incomplete, dangerous to implement

**Why It Matters**:
- Incorrect fixes can create false sense of security
- Incomplete fixes may leave attack surfaces open
- Good fixes demonstrate true security expertise

---

### Mean Reasoning Quality

**Definition**: Average of RCIR, AVA, and FSV scores across all samples where target was found.

**Formula**:
```
Mean Reasoning = (Mean RCIR + Mean AVA + Mean FSV) / 3
```

**What It Measures**: Overall explanation quality across all dimensions.

**Range**: 0.0 to 1.0

**Example**:
```
Across 30 samples with target found:
  Mean RCIR = 0.95
  Mean AVA = 0.93
  Mean FSV = 0.91

Mean Reasoning = (0.95 + 0.93 + 0.91) / 3 = 0.93
```

**Interpretation**:
- **High (>0.85)**: Expert-level reasoning and explanations
- **Medium (0.65-0.85)**: Decent but inconsistent reasoning
- **Low (<0.65)**: Poor reasoning, explanations not reliable

**Important Note**: Only computed for samples where target was found (TDR samples). If model didn't find the target, reasoning quality is meaningless.

---

## Composite Metrics

These metrics combine multiple dimensions to provide holistic assessments of security understanding.

### 16. SUI (Security Understanding Index)

**Definition**: Weighted composite score combining all key metrics to measure overall security analysis capability.

**Formula**:
```
SUI = 0.30 × Accuracy
    + 0.25 × Target Detection Rate
    + 0.15 × Finding Precision
    + 0.15 × Mean Reasoning Quality
    + 0.10 × (1 - Hallucination Rate)
    + 0.05 × (1 - Lucky Guess Rate)
```

**Weight Rationale**:
- **30% Accuracy**: Base detection capability
- **25% TDR**: Most critical - finding correct vulnerabilities
- **15% Finding Precision**: Quality of reported findings
- **15% Reasoning**: Understanding depth
- **10% Low Hallucination**: Avoiding false alarms
- **5% Low Lucky Guessing**: Genuine vs. lucky detection

**What It Measures**: Comprehensive security analysis capability.

**Range**: 0.0 to 1.0

**Interpretation**:
- **Excellent (>0.85)**: Production-ready, can assist expert auditors
- **Good (0.70-0.85)**: Useful but needs human oversight
- **Fair (0.55-0.70)**: Inconsistent, requires significant verification
- **Poor (<0.55)**: Not reliable for security analysis

**Example**:
```
Model X:
  Accuracy: 0.90
  TDR: 0.60
  Finding Precision: 0.75
  Mean Reasoning: 0.95
  Hallucination Rate: 0.05 (so 1 - 0.05 = 0.95)
  Lucky Guess Rate: 0.30 (so 1 - 0.30 = 0.70)

SUI = 0.30 × 0.90 + 0.25 × 0.60 + 0.15 × 0.75
    + 0.15 × 0.95 + 0.10 × 0.95 + 0.05 × 0.70
    = 0.270 + 0.150 + 0.113 + 0.143 + 0.095 + 0.035
    = 0.806
```

**Ranking Interpretation**:
```
Gemini 3 Pro:     SUI = 0.852  → Excellent
GPT-5.2:          SUI = 0.828  → Excellent
Claude Opus 4.5:  SUI = 0.811  → Excellent
DeepSeek V3.2:    SUI = 0.753  → Good
Llama 3.1 405B:   SUI = 0.647  → Fair
```

---

### 17. True Understanding Score

**Definition**: Product of Target Detection Rate and Mean Reasoning Quality.

**Formula**:
```
True Understanding = TDR × Mean Reasoning Quality
```

**What It Measures**: Genuine security expertise (finding + explaining).

**Range**: 0.0 to 1.0

**Interpretation**:
- **High (>0.50)**: Strong genuine understanding
- **Medium (0.30-0.50)**: Moderate understanding
- **Low (<0.30)**: Limited genuine understanding

**Example**:
```
Model A:
  TDR = 0.60
  Mean Reasoning = 0.95
  True Understanding = 0.60 × 0.95 = 0.570

Model B:
  TDR = 0.20
  Mean Reasoning = 0.85
  True Understanding = 0.20 × 0.85 = 0.170
```

**Insight**: Model B has good reasoning when it finds something, but rarely finds the right vulnerability → low true understanding.

**Why Multiplicative?**: Both dimensions must be strong. Finding without explaining OR explaining without finding = not true understanding.

---

### 18. Lucky Guess Indicator

**Definition**: Difference between detection accuracy and true understanding.

**Formula**:
```
Lucky Guess Indicator = Accuracy - True Understanding Score
```

**What It Measures**: How much of the accuracy is due to lucky guessing vs. genuine understanding.

**Range**: 0.0 to 1.0 (theoretically could be negative but rare)

**Interpretation**:
- **High (>0.40)**: Mostly lucky guessing, not true understanding
- **Medium (0.20-0.40)**: Mixed genuine + lucky
- **Low (<0.20)**: Mostly genuine understanding

**Example**:
```
Model A (Llama 3.1 405B):
  Accuracy = 0.981
  True Understanding = 0.042 (TDR: 0.208 × Reasoning: 0.867)
  Lucky Guess Indicator = 0.981 - 0.042 = 0.939

→ 93.9% of accuracy is from lucky guessing! Red flag!

Model B (GPT-5.2):
  Accuracy = 0.830
  True Understanding = 0.566
  Lucky Guess Indicator = 0.830 - 0.566 = 0.264

→ Only 26.4% from guessing, 56.6% from true understanding. Much better!
```

**Critical Insight**:
- High accuracy + high lucky guess indicator = unreliable for production
- Lower accuracy + low lucky guess indicator = more trustworthy

---

## Metric Interpretation Guide

### Understanding Trade-offs

Different metrics prioritize different aspects:

| Scenario | High Metrics | Low Metrics | Interpretation |
|----------|--------------|-------------|----------------|
| **Reliable Expert** | Accuracy, TDR, Precision, Reasoning | Hallucination, Lucky Guess | Production-ready |
| **Conservative** | Precision, Reasoning | Recall, TDR | Few false alarms but misses vulnerabilities |
| **Aggressive** | Recall | Precision, Finding Precision | Catches everything but many false positives |
| **Lucky Guesser** | Accuracy, Recall | TDR, Reasoning | Unreliable, just guessing |
| **Hallucinator** | Recall, Avg Findings | Precision, Hallucination | Over-reports, noisy |

### Metric Relationships

**Complementary Pairs**:
```
Precision ↔ Recall (classic trade-off)
TDR ↔ Lucky Guess Rate (inverse relationship)
Finding Precision ↔ Hallucination Rate (inverse)
```

**Derived Metrics**:
```
F1 = f(Precision, Recall)
SUI = f(Accuracy, TDR, Precision, Reasoning, ...)
True Understanding = f(TDR, Reasoning)
```

---

## Real-World Examples

### Case Study 1: Gemini 3 Pro Preview

```
Detection Performance:
  Accuracy: 98.0%          ⭐ Excellent
  Precision: 100.0%        ⭐ Perfect
  Recall: 98.0%            ⭐ Excellent
  F1: 0.990                ⭐ Excellent

Target Finding:
  TDR: 60.8%               ⭐ Good
  Lucky Guess Rate: 38.0%  ⚠️ Moderate

Finding Quality:
  Finding Precision: 75.7% ⭐ Good
  Hallucination Rate: 0.9% ⭐ Excellent
  Avg Findings: 2.2        ✓ Balanced

Reasoning Quality:
  RCIR: 0.98              ⭐ Excellent
  AVA: 0.98               ⭐ Excellent
  FSV: 0.94               ⭐ Excellent

Composite:
  SUI: 0.852              ⭐ Excellent
  True Understanding: 0.444 ⭐ Strong
  Lucky Guess: 0.373      ⚠️ Moderate
```

**Interpretation**:
- **Strengths**: Extremely accurate detection, rarely hallucinates, excellent reasoning
- **Weaknesses**: ~38% of correct verdicts are lucky guesses (not finding exact vulnerability)
- **Overall**: Best overall model, production-ready with human oversight
- **Use Case**: Primary security analysis tool with expert review of edge cases

---

### Case Study 2: Llama 3.1 405B

```
Detection Performance:
  Accuracy: 98.1%          ⭐ Excellent
  Precision: 100.0%        ⭐ Perfect
  Recall: 98.1%            ⭐ Excellent
  F1: 0.990                ⭐ Excellent

Target Finding:
  TDR: 20.8%               ❌ Poor
  Lucky Guess Rate: 78.8%  ❌ Very High

Finding Quality:
  Finding Precision: 23.5% ❌ Poor
  Hallucination Rate: 11.8% ⚠️ Moderate
  Avg Findings: 1.3        ✓ Conservative

Reasoning Quality:
  RCIR: 0.89              ⭐ Good
  AVA: 0.89               ⭐ Good
  FSV: 0.82               ⭐ Good

Composite:
  SUI: 0.647              ⚠️ Fair
  True Understanding: 0.042 ❌ Very Low
  Lucky Guess: 0.774      ❌ Very High
```

**Interpretation**:
- **Deceptive**: 98% accuracy looks great, but 79% is from lucky guessing!
- **Problem**: Correctly says "vulnerable" but can't identify WHICH vulnerability
- **Only 21% target detection**: Rarely finds the actual issue
- **High hallucination**: 1 in 8 findings is fabricated
- **Overall**: Unreliable for production despite high accuracy
- **Use Case**: Not recommended for security analysis

**Key Lesson**: Accuracy alone is misleading!

---

### Case Study 3: GPT-5.2

```
Detection Performance:
  Accuracy: 83.0%          ⭐ Good
  Precision: 100.0%        ⭐ Perfect
  Recall: 83.0%            ⭐ Good
  F1: 0.907                ⭐ Good

Target Finding:
  TDR: 56.6%               ⭐ Good
  Lucky Guess Rate: 31.8%  ✓ Acceptable

Finding Quality:
  Finding Precision: 86.0% ⭐ Excellent
  Hallucination Rate: 3.2% ⭐ Excellent
  Avg Findings: 1.8        ✓ Conservative

Reasoning Quality:
  RCIR: 1.00              ⭐ Perfect
  AVA: 1.00               ⭐ Perfect
  FSV: 1.00               ⭐ Perfect

Composite:
  SUI: 0.828              ⭐ Excellent
  True Understanding: 0.487 ⭐ Strong
  Lucky Guess: 0.264      ✓ Low
```

**Interpretation**:
- **Strengths**: When it finds something, explanations are PERFECT (1.0 reasoning)
- **Strengths**: Highest finding precision (86%), rarely hallucinates (3%)
- **Trade-off**: Lower recall (83%) - misses some vulnerabilities
- **Balance**: 48.7% true understanding, only 26% lucky guessing
- **Overall**: Most reliable when it reports a finding
- **Use Case**: Conservative auditing - trust what it finds, but may need supplementary tools

**Key Lesson**: Perfect reasoning with moderate coverage beats high coverage with poor reasoning.

---

## Common Pitfalls & Insights

### Pitfall 1: "High Accuracy = Good Model"

**Wrong Assumption**: 98% accuracy means the model is excellent.

**Reality Check**:
```
Model with 98% accuracy but:
- 20% TDR → Rarely finds actual vulnerabilities
- 80% Lucky Guess Rate → Mostly guessing

This is WORSE than:
Model with 85% accuracy but:
- 70% TDR → Often finds actual vulnerabilities
- 15% Lucky Guess Rate → Genuine understanding
```

**Takeaway**: Always check TDR and Lucky Guess Rate alongside accuracy.

---

### Pitfall 2: "More Findings = Better Analysis"

**Wrong Assumption**: Model reporting 5 vulnerabilities per contract is more thorough.

**Reality Check**:
```
Model A: 5 avg findings, 30% precision
  → 3.5 hallucinations per sample! Wasted audit time.

Model B: 2 avg findings, 85% precision
  → 1.7 real findings, 0.3 hallucinations. Much better!
```

**Takeaway**: Finding precision matters more than quantity.

---

### Pitfall 3: "Perfect Precision = No Problems"

**Wrong Assumption**: 100% precision means the model never makes mistakes.

**Reality Check**:
```
Model with 100% precision but 40% recall:
  → Misses 60% of vulnerabilities!
  → Perfect on what it finds, but misses critical issues
```

**Takeaway**: Balance precision with recall (use F1/F2 scores).

---

### Pitfall 4: "Reasoning Scores Don't Matter if Detection is Good"

**Wrong Assumption**: As long as the model detects vulnerabilities, explanations don't matter.

**Reality Check**:
```
Without good reasoning (RCIR/AVA/FSV):
  ✗ Developers can't fix vulnerabilities properly
  ✗ Can't prioritize by severity/exploitability
  ✗ Can't learn from the analysis
  ✗ Can't validate findings are real
```

**Takeaway**: Reasoning quality is essential for actionable security analysis.

---

### Insight 1: The "Lucky Guesser" Pattern

**Pattern**: High accuracy + Low TDR + High Lucky Guess Rate

**Example**: Llama 3.1 405B (98% accuracy, 21% TDR, 79% lucky guess)

**What's Happening**:
- Model learned that "most contracts in training are vulnerable"
- Defaults to saying "vulnerable" without deep analysis
- Gets high accuracy on vulnerable-heavy benchmarks
- But can't actually identify specific issues

**Detection Method**:
```python
if lucky_guess_rate > 0.50:
    print("Warning: Model is mostly guessing!")
```

---

### Insight 2: The "Precision-Recall Trade-off"

**Observation**: Models optimize for different points on the curve.

**Conservative Models** (High Precision, Lower Recall):
- GPT-5.2: 100% precision, 83% recall
- Strategy: Only report when confident
- Benefit: High trust in findings
- Cost: Misses some vulnerabilities

**Aggressive Models** (High Recall, Lower Precision):
- Some models report many findings to catch everything
- Benefit: Catches more issues
- Cost: More false positives to filter

**Optimal**: F2 score balances with emphasis on recall (security-critical).

---

### Insight 3: True Understanding Separates Experts from Novices

**True Understanding Score** = TDR × Reasoning Quality

**Expert Pattern** (GPT-5.2):
- TDR: 56.6% (finds correct vulnerability more than half the time)
- Reasoning: 1.00 (perfect explanations when found)
- True Understanding: 0.566 → **Strong**

**Novice Pattern** (Llama):
- TDR: 20.8% (rarely finds correct vulnerability)
- Reasoning: 0.867 (decent when it finds something)
- True Understanding: 0.042 → **Weak**

**Takeaway**: This single metric reveals genuine security expertise.

---

## Summary

### Most Critical Metrics

For evaluating LLM security analysis capability:

1. **Target Detection Rate (TDR)** - Can it find the RIGHT vulnerability?
2. **Finding Precision** - Are reported findings real?
3. **Mean Reasoning Quality** - Can it explain WHY and HOW?
4. **Lucky Guess Rate** - Is it guessing or understanding?
5. **SUI** - Overall security understanding capability

### Red Flags

Watch out for these warning signs:

- ❌ High accuracy (>90%) but low TDR (<40%) → Lucky guesser
- ❌ High hallucination rate (>30%) → Unreliable findings
- ❌ High lucky guess rate (>50%) → Not genuine understanding
- ❌ Low finding precision (<50%) → Too noisy for production
- ❌ Low reasoning quality (<0.70) → Can't explain findings

### Green Flags

Indicators of reliable models:

- ✅ High TDR (>60%) → Finds correct vulnerabilities
- ✅ Low hallucination (<10%) → Trustworthy findings
- ✅ High reasoning (>0.90) → Expert-level explanations
- ✅ Low lucky guess (<30%) → Genuine understanding
- ✅ High SUI (>0.80) → Production-ready

---

## Appendix: Metric Quick Reference

| Metric | Range | Good Threshold | Interpretation |
|--------|-------|----------------|----------------|
| **Accuracy** | 0-1 | >0.90 | Overall correctness |
| **Precision** | 0-1 | >0.90 | False alarm rate |
| **Recall** | 0-1 | >0.85 | Miss rate |
| **F1** | 0-1 | >0.88 | Balanced detection |
| **F2** | 0-1 | >0.85 | Recall-focused |
| **TDR** | 0-1 | >0.60 | Correct identification |
| **Lucky Guess Rate** | 0-1 | <0.30 | Guessing vs. understanding |
| **Finding Precision** | 0-1 | >0.75 | Quality of findings |
| **Hallucination Rate** | 0-1 | <0.10 | False discoveries |
| **RCIR** | 0-1 | >0.85 | Root cause understanding |
| **AVA** | 0-1 | >0.85 | Attack vector understanding |
| **FSV** | 0-1 | >0.85 | Fix quality |
| **SUI** | 0-1 | >0.80 | Overall capability |
| **True Understanding** | 0-1 | >0.45 | Genuine expertise |

---

**Document Version**: 1.0
**Last Updated**: December 18, 2025
**Maintained By**: BlockBench Team

For questions or feedback on metrics, please refer to the main METHODOLOGY.md document.
