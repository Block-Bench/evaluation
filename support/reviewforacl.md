# BlockBench ACL Submission: Strategic Improvement Roadmap

## Current Strengths (Preserve These)

The paper has genuine novelty that reviewers will appreciate:

- **Accuracy-TDR gap finding**: Llama's 88% accuracy / 18% TDR is a compelling insight that challenges how the field evaluates security tools
- **Transformation methodology**: Sanitization → Chameleon → Shapeshifter provides a principled way to probe memorization vs understanding
- **Temporal contamination control**: Post-cutoff Gold Standard is methodologically sound
- **Strong human validation**: κ=0.84, F1=0.91

---

## Critical Issues to Address

### 1. Statistical Power (The Elephant in the Room)

**Problem**: 58 samples with 10 Gold Standard is thin for ACL main track. When Claude gets 20% on GS (2/10) and Gemini gets 11% (≈1/10), a single sample changes conclusions dramatically. Reviewers will flag this immediately.

**Action**: Expand to 150+ samples as planned, with at least 40-50 Gold Standard. This alone transforms the paper's credibility.

---

### 2. Missing Statistical Rigor

**Problem**: No confidence intervals, no significance tests anywhere. Is GPT-5.2 (55.9%) actually better than Claude (52.9%)?

**Action**: Add throughout:

- 95% confidence intervals for all TDR/SUI values
- McNemar's test or bootstrap significance tests for pairwise comparisons
- Effect sizes where relevant

---

### 3. No Traditional Tool Baselines

**Problem**: You cite Slither/Mythril detecting 27-42% in prior work, but don't run them on your samples. Reviewers will ask: "How do LLMs compare to existing tools on _this exact benchmark_?"

**Action**: Run Slither + Mythril on BlockBench samples, report detection rates. This contextualizes LLM performance and strengthens the contribution.

---

### 4. Shallow Error Analysis

**Problem**: The paper reports _what_ happens but not deeply _why_. Which vulnerability types consistently fail? Do models fail on the same samples?

**Action**: Add:

- Per-vulnerability-type breakdown (Table showing TDR by Access Control, Reentrancy, Logic Errors, etc.)
- Cross-model agreement analysis (Venn diagram or correlation matrix of failures)
- Qualitative case studies of interesting failure modes

---

### 5. Undersold Novelty

**Problem**: The framing buries the lead. "We introduce BlockBench, a benchmark..." sounds incremental. The real contributions are the _methodology_ and the _findings_.

**Action**: Reframe contributions as:

1. A methodology for distinguishing memorization from understanding via semantic-preserving adversarial transformations
2. Empirical evidence that accuracy metrics fundamentally misrepresent security capability (the accuracy-TDR gap)
3. BlockBench as the instantiation enabling these findings

---

## Medium-Priority Improvements

### 6. Ablation Studies

**Question to answer**: Which transformations matter most? Does Sanitization alone suffice, or is Chameleon necessary?

**Action**: Add ablation table showing incremental effect of each transformation.

---

### 7. Prompt Sensitivity Analysis

**Problem**: You have three prompt types but don't deeply analyze the interaction between prompt type × transformation × model.

**Action**: Add interaction analysis—there's likely interesting signal here.

---

### 8. Chain-of-Thought / Few-Shot Experiments

**Problem**: You only evaluate zero-shot. Reviewers may ask whether CoT or few-shot prompting changes conclusions.

**Action**: Even a brief experiment (on subset) addressing this strengthens the paper and preempts the question.

---

### 9. Reproducibility

**Problem**: The promise to release code is good, but ACL increasingly values actual artifacts.

**Action**: Prepare an anonymous repository ready for review submission.

---

## Structural Suggestions

### Abstract Reframing

**Current approach**: Lead with the benchmark introduction.

**Suggested approach**: Lead with the finding. Example opening:

> "Frontier LLMs achieve 88% accuracy on smart contract vulnerability detection yet identify the actual vulnerability only 18% of the time..."

---

### Introduction Enhancement

The motivation (Figure 1, \$14B losses) is good but could connect more directly to _why memorization vs understanding matters for practitioners_.

Add a paragraph bridging: "For security practitioners, the distinction is critical: a model that correctly labels code as 'vulnerable' provides no actionable insight without identifying the specific flaw..."

---

### Results Section Reorganization

**Current organization**: By analysis type.

**Suggested organization**: Around key claims:

1. **Claim 1**: Accuracy metrics are inadequate (accuracy-TDR gap analysis)
2. **Claim 2**: Models exhibit heterogeneous robustness (transformation analysis)
3. **Claim 3**: Temporal contamination inflates performance estimates (GS vs TC comparison)

---

## Priority Roadmap

| Priority        | Task                                         | Impact                      | Effort |
| --------------- | -------------------------------------------- | --------------------------- | ------ |
| 🔴 Critical     | Expand to 150+ samples, 40+ GS               | Makes paper defensible      | High   |
| 🔴 Critical     | Add CIs + significance tests                 | Statistical rigor           | Medium |
| 🟠 High         | Traditional tool baselines (Slither/Mythril) | Contextualizes contribution | Medium |
| 🟠 High         | Per-vulnerability-type analysis              | Adds analytical depth       | Medium |
| 🟡 Medium       | Reframe contributions in abstract/intro      | Sells the novelty           | Low    |
| 🟡 Medium       | Cross-model failure analysis                 | Scientific insight          | Medium |
| 🟡 Medium       | Ablation studies on transformations          | Methodological rigor        | Medium |
| 🟢 Nice-to-have | CoT/few-shot experiment                      | Preempts reviewer question  | Medium |
| 🟢 Nice-to-have | Anonymous artifact repository                | Reproducibility signal      | Low    |

---

## Key Questions to Resolve

1. **Timeline**: What's the target deadline for ARR January cycle?
2. **Gold Standard expansion**: Are Spearbit/Code4rena audits from October-December 2025 accessible?
3. **Compute budget**: Is there capacity for additional model evaluations (CoT, few-shot)?
4. **Team capacity**: Who handles which improvements?

---

## Reviewer Anticipation

Likely reviewer questions to preempt:

1. "Why only 58 samples?" → Expand dataset
2. "Are these differences statistically significant?" → Add CIs and tests
3. "How does this compare to existing tools?" → Add Slither/Mythril baselines
4. "What about few-shot or chain-of-thought?" → Add brief experiment or explicitly scope as zero-shot evaluation with future work note
5. "Which vulnerability types are hardest?" → Add per-type breakdown
6. "Is the benchmark contaminated by using AI in creation?" → Address explicitly in limitations

---

_Document prepared for BlockBench ACL 2026 submission planning_

#If time allows to add

- synthetic context
