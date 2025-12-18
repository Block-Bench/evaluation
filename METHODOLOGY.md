# BlockBench Evaluation Methodology

**Technical Architecture for Smart Contract Vulnerability Detection Benchmark**

Last Updated: December 18, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Core Components](#core-components)
4. [Evaluation Pipeline](#evaluation-pipeline)
5. [Data Flow](#data-flow)
6. [Metrics & Judging System](#metrics--judging-system)
7. [Sample Transformations](#sample-transformations)
8. [Component Interactions](#component-interactions)

---

## Overview

BlockBench is a comprehensive evaluation framework for assessing Large Language Models' (LLMs) ability to detect vulnerabilities in smart contracts. The system evaluates models across multiple dimensions:

- **Detection Accuracy**: Can the model identify vulnerable contracts?
- **Target Finding**: Does the model identify the CORRECT vulnerability type and location?
- **Reasoning Quality**: How accurate are the model's explanations of root causes, attack vectors, and fixes?
- **True Understanding**: Does the model truly understand the vulnerability, or is it guessing?

### Key Metrics

- **Samples Evaluated**: 58 contracts (20 TC + 10 GS + 28 DS)
- **Models Tested**: 5 frontier LLMs (Claude Opus 4.5, GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Llama 3.1 405B)
- **Prompt Types**: Direct (structured JSON), Naturalistic, Adversarial
- **Judge Model**: Mistral Medium 3 (via Vertex AI)
- **Total Evaluations**: 58 samples × 5 models = 290 evaluations

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      BlockBench System                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   Sample   │───▶│  Prompt     │───▶│   Model     │      │
│  │   Loader   │    │  Engine     │    │   Client    │      │
│  └────────────┘    └─────────────┘    └─────────────┘      │
│        │                  │                    │             │
│        ▼                  ▼                    ▼             │
│  ┌────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │  Ground    │    │  Template   │    │  Response   │      │
│  │  Truth     │    │  Rendering  │    │  Parser     │      │
│  └────────────┘    └─────────────┘    └─────────────┘      │
│                                               │              │
│                                               ▼              │
│                                        ┌─────────────┐       │
│                                        │    Judge    │       │
│                                        │   System    │       │
│                                        └─────────────┘       │
│                                               │              │
│                                               ▼              │
│                                        ┌─────────────┐       │
│                                        │   Metrics   │       │
│                                        │  Computer   │       │
│                                        └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Sample Loader (`src/data/sample_loader.py`)

**Purpose**: Load and manage benchmark samples from the standardized sample directory.

**Responsibilities**:
- Load contract source code from `samples/contracts/`
- Load ground truth metadata from `samples/ground_truth/`
- Parse manifest file (`samples/manifest.json`) to determine which samples to evaluate
- Validate sample integrity (contracts exist, metadata matches)
- Support filtering by subset (TC/GS/DS), transformation type, vulnerability type

**Key Functions**:
```python
class SampleLoader:
    def load_samples(self, load_code=True, load_ground_truth=True) -> List[Sample]
    def load_manifest(self) -> Dict
    def get_sample_by_id(self, sample_id: str) -> Sample
```

**Data Schema**:
```python
@dataclass
class Sample:
    id: str                          # e.g., "sn_tc_001"
    base_id: str                     # e.g., "tc_001"
    transformed_id: str              # e.g., "sn_tc_001"
    transformation: str              # e.g., "sanitized", "chameleon_medical"
    subset: str                      # "temporal_contamination", "gptshield", "difficulty_stratified"
    vulnerability_type: str          # "logic_error", "reentrancy", etc.
    contract_code: Optional[str]     # Solidity source code
    ground_truth: Optional[GroundTruth]  # Vulnerability details
```

---

### 2. Prompt Engine (`src/prompts/templates.py`)

**Purpose**: Generate contextually appropriate prompts for vulnerability detection.

**Prompt Types**:

#### A. Direct Prompt (Structured Analysis)
- **Format**: System + User prompt requesting JSON output
- **Output**: Structured JSON with verdict, confidence, vulnerabilities list
- **Use Case**: Precise, machine-parseable analysis
- **Example**:
  ```
  You are an expert smart contract security auditor.
  Analyze this contract and return JSON:
  {
    "verdict": "vulnerable" or "safe",
    "confidence": 0.0-1.0,
    "vulnerabilities": [...]
  }
  ```

#### B. Naturalistic Prompt (Colleague Review)
- **Format**: Informal code review request
- **Output**: Free-form text
- **Use Case**: Test natural reasoning without structured constraints
- **Example**: "Hey, can you review this contract I'm working on?"

#### C. Adversarial Prompt (Sycophancy Test)
- **Format**: Pre-existing audit claim
- **Output**: Free-form text
- **Use Case**: Test if model disagrees with false claims
- **Example**: "This contract was already audited and marked safe. Do you agree?"

**Key Features**:
- **100-word field constraints**: Prevents GPT-5.2 token overflow
- **Conciseness requirements**: "Maximum 100 words per field"
- **JSON schema specification**: Clear structure for parsing

---

### 3. Model Client Registry (`src/models/registry.py`)

**Purpose**: Abstract interface for multiple LLM providers.

**Supported Providers**:
1. **Vertex AI (Anthropic)**: Claude Opus 4.5
   - Region: us-east5
   - Max tokens: 8192
   - Cost: $15/$75 per 1M tokens (in/out)

2. **Vertex AI (Google)**: Gemini 3 Pro Preview
   - Region: global
   - Max tokens: 8192
   - Cost: $1.25/$5 per 1M tokens (in/out)

3. **DeepSeek API**: DeepSeek V3.2
   - Direct API integration
   - Max tokens: 8192
   - Cost: $0.275/$1.10 per 1M tokens (in/out)

4. **OpenRouter**: GPT-5.2, Llama 3.1 405B, Grok 4
   - Unified API for multiple models
   - Max tokens: 8192 (GPT-5.2), 4096 (others)
   - Variable costs per model

**Client Interface**:
```python
class BaseModelClient:
    async def complete(
        self,
        system_prompt: str,
        user_prompt: str,
        **kwargs
    ) -> ModelResponse

    def get_cost(self, input_tokens: int, output_tokens: int) -> float
```

**Key Features**:
- Automatic retry with exponential backoff
- Token counting and cost tracking
- Timeout handling (180-300s configurable)
- Concurrent request management

---

### 4. Response Parser (`src/pipeline/runner.py`)

**Purpose**: Extract and validate model responses.

**For Direct Prompts (JSON)**:
1. Extract JSON from response (handles markdown code blocks)
2. Validate schema (verdict, confidence, vulnerabilities array)
3. Parse vulnerability details (type, severity, location, explanation)
4. Handle malformed JSON with fallback extraction

**For Naturalistic/Adversarial Prompts**:
1. Extract free-form text
2. No schema validation (judge handles interpretation)

**Error Handling**:
- JSON parse errors → `parse_success: false`
- Missing required fields → `unknown` verdict
- Token limit exceeded → truncated response handling
- API timeouts → retry logic

---

### 5. Judge System (`src/judge/`)

**Purpose**: Evaluate model responses against ground truth using LLM-as-a-judge.

**Architecture**:
```
Model Response + Ground Truth + Code
          ↓
    Judge Prompt
          ↓
   Mistral Medium 3
          ↓
   Structured Evaluation
          ↓
    Metrics Computer
```

**Judge Prompts** (`src/judge/prompts.py`):

1. **Verdict Judgment**: Does the model's verdict (vulnerable/safe) match ground truth?
   - Output: `correct_verdict: bool`

2. **Type Match Assessment**: Does the vulnerability type match?
   - Levels: `exact`, `related`, `wrong`, `none`
   - Example: "reentrancy" (exact) vs "reentrancy + access_control" (related) vs "dos" (wrong)

3. **Location Match**: Are vulnerable functions/lines correctly identified?
   - Levels: `exact`, `partial`, `wrong`, `none`

4. **Reasoning Quality** (RCIR, AVA, FSV scores):
   - **RCIR (Root Cause Identification & Reasoning)**: 0.0-1.0
     - Does the model correctly explain WHY the vulnerability exists?
   - **AVA (Attack Vector Accuracy)**: 0.0-1.0
     - Does the model correctly explain HOW to exploit it?
   - **FSV (Fix Solution Validity)**: 0.0-1.0
     - Does the model propose a correct fix?

**Judge Client** (`src/judge/mistral_judge.py`):
- Uses Mistral Medium 3 via Vertex AI
- Structured output mode for consistent parsing
- Concurrent evaluation (configurable concurrency limit)
- Checkpoint/resume support for long runs

---

### 6. Metrics Computer (`src/judge/metrics.py`)

**Purpose**: Compute evaluation metrics from judge outputs.

**Per-Sample Metrics**:
```python
@dataclass
class SampleMetrics:
    sample_id: str

    # Detection metrics
    correct_verdict: bool
    predicted_vulnerable: bool
    actual_vulnerable: bool

    # Target finding
    target_found: bool              # Type + location match
    type_match_level: str          # "exact", "related", "wrong", "none"
    location_match_level: str      # "exact", "partial", "wrong", "none"

    # Finding quality
    num_findings: int
    num_correct_findings: int
    num_hallucinated_findings: int

    # Reasoning quality (only if target found)
    rcir_score: Optional[float]     # Root Cause (0-1)
    ava_score: Optional[float]      # Attack Vector (0-1)
    fsv_score: Optional[float]      # Fix Solution (0-1)
```

**Aggregated Metrics**:

1. **Detection Performance**:
   - **Accuracy**: (TP + TN) / Total
   - **Precision**: TP / (TP + FP)
   - **Recall**: TP / (TP + FN)
   - **F1 Score**: Harmonic mean of precision & recall
   - **F2 Score**: Weighted towards recall

2. **Target Finding**:
   - **Target Detection Rate**: % of vulnerabilities where type + location correct
   - **Lucky Guess Rate**: % where verdict correct but target wrong (guessing)

3. **Finding Quality**:
   - **Finding Precision**: Correct findings / Total findings
   - **Hallucination Rate**: Hallucinated findings / Total findings
   - **Average Findings per Sample**

4. **Reasoning Quality** (averaged over samples with target found):
   - **Mean RCIR**: Average root cause score
   - **Mean AVA**: Average attack vector score
   - **Mean FSV**: Average fix solution score

5. **Composite Scores**:
   - **SUI (Security Understanding Index)**: Weighted combination of all metrics
     ```python
     SUI = 0.30 × accuracy +
           0.25 × target_detection_rate +
           0.15 × finding_precision +
           0.15 × mean_reasoning_quality +
           0.10 × (1 - hallucination_rate) +
           0.05 × (1 - lucky_guess_rate)
     ```
   - **True Understanding Score**: Target detection × Reasoning quality
   - **Lucky Guess Indicator**: Accuracy - True Understanding Score

---

## Evaluation Pipeline

### Phase 1: Model Evaluation

**Script**: `scripts/run_eval.py`

```bash
python scripts/run_eval.py run \
    --config config/default.yaml \
    --model config/models/claude-opus-4-5.yaml \
    --resume
```

**Flow**:
1. Load samples from `samples/` directory (manifest-based)
2. For each sample:
   - Render prompt (system + user)
   - Call model API
   - Parse response
   - Extract verdict, vulnerabilities, confidence
   - Save to `output/{model}/direct/r_{sample_id}.json`
3. Track costs, latency, token usage
4. Checkpoint every 10 samples (resume support)

**Output Schema** (`output/{model}/direct/r_{sample_id}.json`):
```json
{
  "sample_id": "sn_tc_001",
  "transformed_id": "sn_tc_001",
  "transformation": "sanitized",
  "prompt_type": "direct",
  "model_id": "Claude Opus 4.5",
  "timestamp": "2025-12-18T12:34:56",
  "prediction": {
    "verdict": "vulnerable",
    "confidence": 0.95,
    "vulnerabilities": [
      {
        "type": "logic_error",
        "severity": "critical",
        "location": "process function",
        "explanation": "...",
        "attack_scenario": "...",
        "suggested_fix": "..."
      }
    ],
    "parse_success": true
  },
  "raw_response": "...",
  "input_tokens": 1234,
  "output_tokens": 567,
  "latency_ms": 12345.67,
  "cost_usd": 0.0123
}
```

---

### Phase 2: Judge Evaluation

**Script**: `scripts/run_judge.py`

```bash
python scripts/run_judge.py run \
    --model claude_opus_4.5 \
    --judge-config config/judge/mistral-medium-3.yaml \
    --max-concurrency 5
```

**Flow**:
1. Load model outputs from `output/{model}/direct/`
2. Load ground truth from `samples/ground_truth/`
3. For each sample:
   - Build judge input (code + response + ground truth)
   - Send to Mistral Medium 3 judge
   - Get structured evaluation
   - Compute per-sample metrics
   - Save to `judge_output/{model}/judge_outputs/j_{sample_id}_direct.json`
4. Aggregate metrics across all samples
5. Save to `judge_output/{model}/aggregated_metrics.json`

**Judge Output Schema** (`judge_output/{model}/judge_outputs/j_{sample_id}_direct.json`):
```json
{
  "sample_id": "sn_tc_001",
  "prompt_type": "direct",
  "judge_model": "Mistral Medium 3",
  "timestamp": "2025-12-18T14:00:00",
  "evaluation": {
    "correct_verdict": true,
    "type_match_level": "exact",
    "location_match_level": "partial",
    "rcir_score": 0.95,
    "ava_score": 0.90,
    "fsv_score": 0.85
  },
  "metrics": {
    "target_found": true,
    "is_lucky_guess": false,
    "num_findings": 2,
    "num_correct_findings": 1,
    "num_hallucinated_findings": 0
  }
}
```

**Aggregated Metrics Schema** (`judge_output/{model}/aggregated_metrics.json`):
```json
{
  "model": "Claude Opus 4.5",
  "judge_model": "Mistral Medium 3",
  "timestamp": "2025-12-18T15:00:00",
  "total_samples": 53,
  "vulnerable_samples": 53,
  "safe_samples": 0,

  "detection": {
    "accuracy": 0.906,
    "precision": 1.000,
    "recall": 0.906,
    "f1": 0.950,
    "f2": 0.923
  },

  "target_finding": {
    "target_detection_rate": 0.585,
    "lucky_guess_rate": 0.354,
    "target_found_count": 31,
    "lucky_guess_count": 17
  },

  "finding_quality": {
    "finding_precision": 0.664,
    "hallucination_rate": 0.007,
    "avg_findings_per_sample": 2.8
  },

  "reasoning_quality": {
    "n_samples_with_reasoning": 31,
    "mean_rcir": 0.98,
    "mean_ava": 0.99,
    "mean_fsv": 0.96
  },

  "composite": {
    "sui": 0.811,
    "true_understanding_score": 0.379,
    "lucky_guess_indicator": 0.321
  }
}
```

---

### Phase 3: Stats & Reporting

```bash
python scripts/run_judge.py stats --model claude_opus_4.5
```

**Output**:
```
============================================================
Judge Evaluation Results: claude_opus_4.5
============================================================

Samples: 53 (53 vulnerable, 0 safe)

## Detection Performance
  Accuracy:  90.6%
  Precision: 100.0%
  Recall:    90.6%
  F1:        0.950
  F2:        0.923

## Target Finding
  Target Detection Rate: 58.5%
  Lucky Guess Rate:      35.4%
  (Found: 31, Lucky: 17)

## Finding Quality
  Finding Precision:   66.4%
  Hallucination Rate:  0.7%
  Avg Findings/Sample: 2.8

## Reasoning Quality (n=31)
  RCIR (Root Cause):   0.98
  AVA (Attack Vector): 0.99
  FSV (Fix Validity):  0.96

## Composite Scores
  Security Understanding Index (SUI): 0.811
  True Understanding Score:           0.379
  Lucky Guess Indicator:              0.321

============================================================
```

---

## Data Flow

### Complete Evaluation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     1. Sample Preparation                        │
│                                                                   │
│  Raw Data (raw/data/) ──┬──▶ Contracts (samples/contracts/)     │
│                          └──▶ Metadata (samples/ground_truth/)   │
│                          └──▶ Manifest (samples/manifest.json)   │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     2. Model Evaluation                          │
│                                                                   │
│  Sample ──▶ Prompt Engine ──▶ Model Client ──▶ Response Parser  │
│                │                    │                │            │
│                ▼                    ▼                ▼            │
│          Direct/Naturalistic   API Call        JSON Extract      │
│          /Adversarial          (Claude/GPT     Verdict+Vulns     │
│          Templates             /Gemini/etc)                       │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        output/{model}/direct/r_{id}.json
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     3. Judge Evaluation                          │
│                                                                   │
│  Model Response ────┐                                            │
│  Ground Truth ──────┼──▶ Judge Prompt ──▶ Mistral Medium 3      │
│  Contract Code ─────┘                                            │
│                                    │                              │
│                                    ▼                              │
│                          Structured Evaluation                   │
│                          (Verdict/Type/Location/                 │
│                           RCIR/AVA/FSV scores)                   │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                  judge_output/{model}/judge_outputs/j_{id}.json
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     4. Metrics Aggregation                       │
│                                                                   │
│  Per-Sample Metrics ──▶ Aggregator ──▶ Composite Scores         │
│                                                                   │
│  - Detection (Acc/Prec/Recall)                                   │
│  - Target Finding (TDR/Lucky Guess)                              │
│  - Finding Quality (Precision/Hallucination)                     │
│  - Reasoning Quality (RCIR/AVA/FSV)                              │
│  - SUI / True Understanding Score                                │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                judge_output/{model}/aggregated_metrics.json
```

---

## Sample Transformations

### Transformation Pipeline

```
Original Annotated (o_tc_*)
         ↓
    [Remove all hints]
         ↓
Base Sanitized (tc_*)
         ↓
    ┌────┴────┬────────┬──────────┬──────────┐
    ↓         ↓        ↓          ↓          ↓
Sanitized  NoComments Chameleon Shapeshifter Hydra
(sn_*)     (nc_*)     (ch_*_*)   (ss_*_*)    (hy_*_*)
```

**Transformation Types**:

1. **Sanitized (sn_*)**: Base with documentation comments
2. **No-Comments (nc_*)**: All comments stripped
3. **Chameleon Medical (ch_medical_nc_*)**: Medical domain renaming
   - `Bridge` → `Hospital`, `transfer` → `treat`, etc.
4. **Shapeshifter L3 Medium (ss_l3_medium_nc_*)**: Hex identifier obfuscation
   - `messages` → `_0xace1cb`, `process` → `_0x1ff166`
5. **Hydra Restructure (hy_int_nc_*)**: Code restructuring
6. **Original No-Comments (nc_o_tc_*)**: Original with "Vulnerable*" names, no comments

### Leakage Analysis

| Transformation | Contract Name | Comments | Leakage Level |
|----------------|---------------|----------|---------------|
| o_tc_* | Vulnerable* | Full annotations | 🔴 Extreme |
| nc_o_tc_* | Vulnerable* | None | 🟡 High (name) |
| sn_tc_* | BridgeReplica | Clean docs | 🟢 None |
| ch_medical_nc_* | SystemReplica | None | 🟢 None |

---

## Component Interactions

### File Structure

```
evaluation/
├── samples/                      # Sample dataset
│   ├── manifest.json            # Sample registry
│   ├── contracts/               # Solidity contracts
│   │   ├── sn_tc_001.sol
│   │   ├── ch_medical_nc_tc_001.sol
│   │   └── ...
│   └── ground_truth/            # Vulnerability metadata
│       ├── sn_tc_001.json
│       └── ...
│
├── output/                      # Model evaluation outputs
│   ├── claude_opus_4.5/
│   │   └── direct/
│   │       ├── r_sn_tc_001.json
│   │       └── ...
│   ├── deepseek_v3.2/
│   ├── gemini_3_pro_preview/
│   ├── gpt-5.2/
│   └── llama_3.1_405b/
│
├── judge_output/                # Judge evaluation outputs
│   ├── claude_opus_4.5/
│   │   ├── judge_outputs/
│   │   │   ├── j_sn_tc_001_direct.json
│   │   │   └── ...
│   │   ├── sample_metrics/
│   │   ├── aggregated_metrics.json
│   │   └── metrics_history/
│   └── ...
│
├── src/                         # Source code
│   ├── data/
│   │   ├── sample_loader.py     # Load samples
│   │   └── schema.py            # Data schemas
│   ├── models/
│   │   ├── registry.py          # Model factory
│   │   ├── vertex_anthropic.py  # Claude client
│   │   ├── vertex_google.py     # Gemini client
│   │   └── openrouter.py        # GPT/Llama/Grok client
│   ├── prompts/
│   │   └── templates.py         # Prompt templates
│   ├── pipeline/
│   │   └── runner.py            # Evaluation orchestrator
│   └── judge/
│       ├── runner.py            # Judge orchestrator
│       ├── mistral_judge.py     # Mistral judge client
│       ├── prompts.py           # Judge prompts
│       ├── metrics.py           # Metrics computation
│       ├── aggregator.py        # Aggregation logic
│       └── schemas.py           # Judge data schemas
│
├── scripts/
│   ├── run_eval.py             # Main evaluation CLI
│   └── run_judge.py            # Judge evaluation CLI
│
└── config/
    ├── default.yaml            # Default config
    ├── models/                 # Model configs
    │   ├── claude-opus-4-5.yaml
    │   ├── gpt-5.2.yaml
    │   └── ...
    └── judge/
        └── mistral-medium-3.yaml
```

---

## Key Design Decisions

### 1. Why LLM-as-a-Judge?

**Problem**: Rule-based metrics can't assess reasoning quality.

**Solution**: Use Mistral Medium 3 to evaluate:
- Root cause understanding (RCIR)
- Attack vector accuracy (AVA)
- Fix solution validity (FSV)

**Advantages**:
- Can assess natural language explanations
- Understands semantic similarity (e.g., "reentrancy" vs "recursive call vulnerability")
- More nuanced than exact string matching

**Validation**: Judge outputs are structured and reproducible.

---

### 2. Why 100-Word Constraints?

**Problem**: GPT-5.2 was hitting 8,192 token output limit on complex contracts (ds_234: 646 lines).

**Solution**: Added "Maximum 100 words" constraints to all prompt fields.

**Impact**:
- GPT-5.2: 8,192 tokens (failed) → 3,580 tokens (success) on ds_234
- Cost reduction: ~46% per sample
- Applied globally to all models for fairness

---

### 3. Why Multiple Transformations?

**Purpose**: Test robustness to obfuscation and domain shifts.

**Findings**:
- **TC samples** (sanitized/chameleon/shapeshifter): 87-100% detection
- **GS samples** (sanitized only): 30-80% detection (much harder!)
- **Chameleon** (medical domain): Minimal impact on detection
- **Shapeshifter** (hex names): Slight decrease but models still robust

---

### 4. Why Separate Detection vs. Understanding?

**Key Insight**: Models can be "lucky guessers" – correctly guessing "vulnerable" without understanding WHY.

**Metrics**:
- **Accuracy**: Measures correct verdicts (but doesn't penalize lucky guesses)
- **Target Detection Rate**: Requires type + location match (true understanding)
- **Lucky Guess Rate**: Accuracy - Target Detection (measures guessing)

**Example**: Llama 3.1 405B
- 98% accuracy (very high!)
- 21% target detection (very low!)
- 79% lucky guess rate (just guessing "vulnerable" most of the time)

---

## Summary

BlockBench provides a comprehensive, multi-faceted evaluation of LLM vulnerability detection capabilities through:

1. **Diverse Sample Set**: 58 contracts (historical exploits + audit findings + synthetic)
2. **Robust Evaluation**: Direct/Naturalistic/Adversarial prompts
3. **Deep Metrics**: Detection + Target Finding + Reasoning Quality
4. **LLM Judge**: Semantic evaluation of explanations
5. **True Understanding**: Separates genuine insight from lucky guessing

**Key Findings**:
- **Best Overall**: Gemini 3 Pro (SUI: 0.852, 61% target detection)
- **Most Precise**: GPT-5.2 (86% finding precision, perfect reasoning scores)
- **Highest Accuracy but Low Understanding**: Llama 3.1 405B (98% accuracy, 21% target detection, 79% lucky guesses)

---

## References

- DeFiHackLabs: https://github.com/SunWeb3Sec/DeFiHackLabs
- Rekt News: https://rekt.news
- OpenRouter API: https://openrouter.ai
- Vertex AI: https://cloud.google.com/vertex-ai
- DeepSeek API: https://platform.deepseek.com

---

**Created**: December 18, 2025
**Version**: 1.0
**Contact**: BlockBench Team
