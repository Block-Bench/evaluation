# ACL Paper Visualization Plan

**Working Title:** LLM-Based Smart Contract Vulnerability Detection: A Comprehensive Benchmark

**Last Updated:** 2026-01-05

---

## Tables

### Table 1: Main Detection Results (DS Benchmark)
| Model | Tier 1 | Tier 2 | Tier 3 | Tier 4 | Avg TDR | Precision | F1 |
|-------|--------|--------|--------|--------|---------|-----------|-----|

- **Rows:** 7 LLM detectors + Slither + Mythril
- **Purpose:** Shows difficulty scaling effect and LLM vs traditional tool comparison
- **Key insight:** How detection degrades with contract complexity

### Table 2: Temporal Contamination Results
| Model | Sanitized | NoComments | MinimalSan | ShapeShifter | Trojan | FalseProphet |
|-------|-----------|------------|------------|--------------|--------|--------------|

- **Purpose:** Shows how sanitization/obfuscation affects detection
- **Key insight:** Which models rely on memorization vs genuine understanding

### Table 3: Judge Agreement Analysis
| Detector | Codestral | Gemini-Flash | MIMO | GLM | Mistral-Large | Agreement % |
|----------|-----------|--------------|------|-----|---------------|-------------|

- **Purpose:** Shows inter-judge reliability
- **Key insight:** Evaluation variance and the need for multiple judges

### Table 4: Gold Standard Protocol Results
| Model | Direct | Context | CoT | CoT+Adversarial | CoT+Naturalistic |
|-------|--------|---------|-----|-----------------|------------------|

- **Purpose:** Shows prompt engineering effects on detection
- **Key insight:** CoT helps weaker models, may hurt stronger ones

### Table 5: Quality Metrics Beyond TDR
| Model | RCIR | AVA | FSV | Lucky Guess % | False Alarm Density |
|-------|------|-----|-----|---------------|---------------------|

- **Purpose:** Deeper quality analysis beyond just detection rate
- **Key insight:** High TDR doesn't always mean high quality explanations

---

## Figures

### Figure 1: Radar/Spider Chart - Model Capabilities
- **Axes:** TDR, Precision, RCIR, AVA, FSV
- **Format:** One polygon per top model (top 4-5)
- **Purpose:** Shows strengths/weaknesses at a glance
- **Tool:** matplotlib radar chart or plotly

### Figure 2: Heatmap - Detection by Vulnerability Type
- **X-axis:** Vulnerability types (reentrancy, access_control, oracle_manipulation, arithmetic_error, etc.)
- **Y-axis:** Models
- **Color:** Detection rate intensity
- **Purpose:** Reveals model specializations
- **Tool:** seaborn heatmap

### Figure 3: Bar Chart - LLMs vs Traditional Tools
- **Format:** Grouped bars comparing LLM average vs Slither vs Mythril
- **Grouping:** By tier or overall
- **Purpose:** The "headline" comparison for abstract/intro
- **Tool:** matplotlib grouped bar

### Figure 4: Line Chart - Difficulty Scaling
- **X-axis:** Tier 1 → Tier 4
- **Y-axis:** TDR
- **Format:** One line per model with markers
- **Purpose:** Shows which models degrade gracefully with complexity
- **Tool:** matplotlib line plot

### Figure 5: Heatmap - Judge Agreement Matrix
- **Format:** Confusion matrix style showing judge pair agreements
- **Purpose:** Quantifies inter-judge reliability
- **Tool:** seaborn heatmap with annotations

### Figure 6: Sankey/Flow Diagram - Detection Pipeline
- **Flow:** Ground Truth → Detector Findings → Judge Evaluation → Final Verdict
- **Purpose:** Shows information flow and loss at each stage
- **Tool:** plotly sankey

### Figure 7: Box Plot - TDR Distribution by Model Family
- **Groups:** OpenAI (GPT), Anthropic (Claude), Google (Gemini), Meta (Llama), etc.
- **Purpose:** Shows variance within model families
- **Tool:** seaborn boxplot

### Figure 8: The Paradox Plot (Novel Contribution!)
- **X-axis:** ROOT_CAUSE Line Match Rate (CodeAct-based)
- **Y-axis:** Judge TDR
- **Format:** Scatter with diagonal reference line
- **Points:** Each point = one model
- **Purpose:** Visualizes "understands but can't explain" phenomenon
- **Key insight:** Points below diagonal indicate models that find right code but explain poorly (e.g., Llama)
- **Tool:** matplotlib scatter with annotations

### Figure 9: Temporal Contamination Delta Chart
- **X-axis:** TC Variant (ordered by obfuscation level)
- **Y-axis:** TDR drop from baseline
- **Format:** Line chart showing degradation curves
- **Purpose:** Quantifies memorization reliance
- **Tool:** matplotlib line plot

---

## Case Studies (Qualitative Boxes)

### Case Study 1: The Beanstalk Paradox (ms_tc_002)
- **Content:**
  - Ground truth: governance_attack via flash loan
  - Llama's detection: "Flash Loan Attack" (correct understanding!)
  - Codestral verdict: NOT FOUND (terminology mismatch)
  - MIMO verdict: FOUND (more lenient)
- **Purpose:** Illustrates judge variance and terminology sensitivity
- **Format:** Side-by-side code + JSON snippets

### Case Study 2: True Understanding Failure
- **Sample:** Pick from "both judges rejected" list (ms_tc_011, ms_tc_015, etc.)
- **Content:** Show where model flagged right lines but completely wrong explanation
- **Purpose:** Contrast with Case Study 1 - legitimate failures exist
- **Format:** Code snippet with annotations

### Case Study 3: Traditional Tool Limitation
- **Content:** Contract that LLMs detect but Slither/Mythril miss
- **Purpose:** Motivates LLM approach
- **Format:** Code + tool outputs comparison

---

## Appendix Tables

### Table A1: Full Per-Sample Results
- Complete detection matrix for reproducibility
- Format: CSV or supplementary material

### Table A2: Prompt Templates
- System prompts for detection
- Judge evaluation prompts
- Protocol context templates

### Table A3: CodeAct Annotation Schema
- Security function definitions (ROOT_CAUSE, SECONDARY_VULN, PREREQ, BENIGN, etc.)
- Code act type taxonomy

### Table A4: Cost and Latency Comparison
| Model | Avg Latency (ms) | Cost per 1K tokens | Total Benchmark Cost |
|-------|------------------|--------------------|--------------------|

### Table A5: Dataset Statistics
- Samples per tier/variant
- Vulnerability type distribution
- Contract complexity metrics (LOC, functions, etc.)

---

## Key Narrative Points

1. **LLMs outperform traditional tools** on complex vulnerabilities but with important caveats

2. **Judge variance is significant** - single-judge evaluation is unreliable, need ensemble

3. **The Paradox Discovery:** Line-level understanding ≠ Explanation quality
   - Models can identify vulnerable code but fail to articulate the vulnerability correctly
   - This is a fundamental limitation for practical deployment

4. **Temporal contamination matters** - sanitization significantly drops performance
   - Suggests memorization plays a role in some models

5. **CoT has differential effects**
   - Helps weaker models (deepseek, llama) significantly
   - Can hurt stronger models (gemini-pro) - overthinking?

6. **Vulnerability type specialization exists**
   - Some models better at reentrancy, others at access control
   - Ensemble approaches may be beneficial

7. **Quality beyond detection**
   - RCIR/AVA/FSV metrics reveal explanation quality varies widely
   - High TDR with low quality = limited practical value

---

## TODO

- [ ] Generate actual data for all tables
- [ ] Create visualization scripts in `scripts/visualize_*.py`
- [ ] Run statistical significance tests
- [ ] Collect cost/latency data
- [ ] Write case study narratives
- [ ] Design figure color scheme (colorblind-friendly)

---

## Notes

- ACL format: 8 pages + references + appendix
- Focus on 4-5 key figures for main paper
- Move detailed tables to appendix
- Emphasize novel contributions: CodeAct paradox analysis, multi-judge evaluation
