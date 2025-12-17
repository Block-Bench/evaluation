# LLM Judge System Specification

## Smart Contract Vulnerability Detection Benchmark

**Version:** 1.1  
**Purpose:** Complete specification for building the LLM-as-Judge evaluation system  
**Default Judge Model:** Mistral Medium 3 (configurable)

---

## 1. Overview

### 1.1 Purpose

The LLM Judge system evaluates AI model responses to smart contract security analysis tasks. It handles both structured JSON responses (from direct prompts) and free-form responses (from naturalistic/adversarial prompts), producing metrics that distinguish genuine understanding from pattern matching.

### 1.2 Key Capabilities

- **Dual-path evaluation**: Parse JSON directly for structured responses, extract from prose for free-form
- **Multi-prompt support**: Evaluate 3 prompt types independently (direct, naturalistic, adversarial)
- Extract structured data from free-form model responses
- Evaluate multiple findings per response (not just one)
- Classify findings as: target match, bonus valid, hallucinated, mischaracterized
- Score reasoning quality (RCIR, AVA, FSV) when target vulnerability is found
- Detect "lucky guesses" (right verdict, wrong reasoning)
- Produce per-sample reports with full reasoning trails
- **Cross-prompt metrics**: Verdict consistency, reasoning consistency, priming effect

### 1.3 Design Principles

1. **Configurable**: Judge model can be swapped without code changes
2. **Deterministic where possible**: Rule-based computation for aggregations
3. **Transparent**: Every score includes reasoning explanation
4. **Efficient**: Minimal judge calls (skip extraction for structured JSON responses)
5. **Prompt-type aware**: Independent evaluation per prompt type, then cross-prompt analysis

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           LLM JUDGE SYSTEM                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  INPUTS (per sample, per prompt type)                                            │
│  ├── Original Code                                                               │
│  ├── Ground Truth (target vulnerability)                                         │
│  ├── Model Response (JSON or free-form)                                          │
│  └── Prompt Type (direct | naturalistic | adversarial)                           │
│              │                                                                   │
│              ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                      PROMPT TYPE ROUTER                                  │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│              │                                                                   │
│      ┌───────┴───────┐                                                          │
│      ▼               ▼                                                          │
│  ┌─────────┐    ┌──────────────────────────────────────────────────────────┐   │
│  │ DIRECT  │    │            NATURALISTIC / ADVERSARIAL                     │   │
│  │ (JSON)  │    │                  (Free-form)                              │   │
│  ├─────────┤    ├──────────────────────────────────────────────────────────┤   │
│  │         │    │                                                           │   │
│  │ 1. Parse│    │  1. LLM Judge extracts verdict, findings, reasoning      │   │
│  │    JSON │    │  2. LLM Judge classifies each finding                     │   │
│  │         │    │  3. LLM Judge scores reasoning quality                    │   │
│  │ 2. LLM  │    │                                                           │   │
│  │  Judge: │    │                                                           │   │
│  │  reason-│    │                                                           │   │
│  │  ing    │    │                                                           │   │
│  │  only   │    │                                                           │   │
│  └────┬────┘    └──────────────────────────────┬────────────────────────────┘   │
│       │                                         │                                │
│       └─────────────────┬───────────────────────┘                                │
│                         ▼                                                        │
│  ┌───────────────────────────────────────────────────────────────┐              │
│  │           RULE-BASED METRIC COMPUTATION                        │              │
│  │                                                                │              │
│  │  Per-Sample Metrics:                                           │              │
│  │  - detection_correct, target_found, lucky_guess                │              │
│  │  - finding_precision, hallucination_count                      │              │
│  │  - rcir_score, ava_score, fsv_score (if applicable)            │              │
│  │  - calibration_error                                           │              │
│  └───────────────────────────────────────────────────────────────┘              │
│                         │                                                        │
│                         ▼                                                        │
│  ┌───────────────────────────────────────────────────────────────┐              │
│  │           AGGREGATION (Per Prompt Type + Cross-Prompt)         │              │
│  │                                                                │              │
│  │  Per-Prompt-Type Metrics:                                      │              │
│  │  - Detection, Target Finding, Reasoning for each prompt type   │              │
│  │                                                                │              │
│  │  Cross-Prompt Metrics:                                         │              │
│  │  - Verdict Consistency, Reasoning Consistency, Priming Effect  │              │
│  └───────────────────────────────────────────────────────────────┘              │
│                         │                                                        │
│                         ▼                                                        │
│  OUTPUT: MetricsReport (per-prompt + cross-prompt) + Per-Sample Details          │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Judge Model Configuration

### 3.1 Configuration Schema

```python
# src/judge/config.py

from pydantic import BaseModel
from typing import Optional, Literal

class JudgeModelConfig(BaseModel):
    """Configuration for the LLM Judge model"""

    # Model identification
    name: str                                    # Display name
    provider: Literal["mistral", "qwen", "openai", "anthropic", "google"]
    model_id: str                                # API model identifier

    # Connection settings
    region: Optional[str] = None                 # For Vertex AI models
    project_id: Optional[str] = None             # For Vertex AI models
    api_key_env: Optional[str] = None            # Env var for API key
    base_url: Optional[str] = None               # Custom endpoint

    # Generation parameters
    max_tokens: int = 4096                       # Judge needs room for detailed output
    temperature: float = 0.0                     # Deterministic judgments
    timeout: int = 120                           # Seconds

    # Retry configuration
    max_retries: int = 3
    retry_delay: float = 2.0                     # Exponential backoff base

    # Cost tracking
    cost_per_input_token: float
    cost_per_output_token: float

    # Capabilities
    supports_json_mode: bool = True              # Most judges should
```

### 3.2 Default Configuration (Mistral Medium 3)

```yaml
# config/judge/mistral-medium-3.yaml

name: 'Mistral Medium 3'
provider: 'mistral'
model_id: 'mistral-medium-3'
region: 'us-central1'

max_tokens: 4096
temperature: 0.0
timeout: 120

max_retries: 3
retry_delay: 2.0

# Pricing: $0.40/1M input, $2.00/1M output
cost_per_input_token: 0.0000004
cost_per_output_token: 0.000002

supports_json_mode: true
```

### 3.3 Alternative Configurations

```yaml
# config/judge/qwen3-80b.yaml

name: 'Qwen3 Next 80B Instruct'
provider: 'qwen'
model_id: 'qwen3-next-80b-instruct'
region: 'us-central1'

max_tokens: 4096
temperature: 0.0
timeout: 120

# Pricing: $0.15/1M input, $1.20/1M output
cost_per_input_token: 0.00000015
cost_per_output_token: 0.0000012

supports_json_mode: true
```

---

## 4. Data Schemas

### 4.1 Input Schemas

```python
# src/judge/schemas.py

from pydantic import BaseModel
from typing import Optional, Literal, Union
from enum import Enum

class PromptType(str, Enum):
    """Types of prompts used for evaluation"""
    DIRECT = "direct"               # Structured JSON output expected
    NATURALISTIC = "naturalistic"   # Free-form, no vulnerability hint
    ADVERSARIAL = "adversarial"     # Free-form, misleading context

class GroundTruth(BaseModel):
    """Ground truth for a sample"""
    is_vulnerable: bool
    vulnerability_type: Optional[str] = None
    severity: Optional[Literal["critical", "high", "medium", "low", "informational"]] = None
    root_cause: Optional[str] = None              # Description of why it's vulnerable
    attack_vector: Optional[str] = None           # Description of how to exploit
    correct_fix: Optional[str] = None             # Description of how to fix
    vulnerable_location: Optional[dict] = None    # {contract, function, lines}

class DirectModelResponse(BaseModel):
    """Structured JSON response from direct prompt"""
    verdict: Literal["vulnerable", "safe", "unknown"]
    confidence: float                             # 0.0 to 1.0
    vulnerability_type: Optional[str] = None
    severity: Optional[str] = None
    root_cause_explanation: Optional[str] = None
    attack_vector_description: Optional[str] = None
    suggested_fix: Optional[str] = None
    affected_location: Optional[str] = None       # Function/line
    additional_findings: Optional[list[dict]] = None  # Other issues found

class FreeFormModelResponse(BaseModel):
    """Free-form text response from naturalistic/adversarial prompts"""
    content: str                                  # Raw response text

class ModelResponse(BaseModel):
    """Raw response from evaluated model"""
    content: str                                  # Raw response (JSON string or free-form)
    model_id: str
    prompt_type: PromptType
    parsed_direct: Optional[DirectModelResponse] = None  # Pre-parsed if direct prompt

class JudgeInput(BaseModel):
    """Complete input for judge evaluation"""
    sample_id: str
    code: str
    language: Literal["solidity", "rust", "move", "cairo"]
    ground_truth: GroundTruth
    model_response: ModelResponse
    prompt_type: PromptType
```

### 4.2 Output Schemas

```python
# src/judge/schemas.py

class FindingClassification(str, Enum):
    TARGET_MATCH = "TARGET_MATCH"           # Found our documented vulnerability
    BONUS_VALID = "BONUS_VALID"             # Found a real issue we didn't document
    HALLUCINATED = "HALLUCINATED"           # Claimed issue that doesn't exist
    MISCHARACTERIZED = "MISCHARACTERIZED"   # Real issue but wrong characterization
    PARTIAL_MATCH = "PARTIAL_MATCH"         # Close but not exact match to target

class TypeMatchLevel(str, Enum):
    EXACT = "exact"                         # Exact type match
    SEMANTIC = "semantic"                   # Different words, same meaning
    PARTIAL = "partial"                     # Related but not quite
    WRONG = "wrong"                         # Incorrect type
    NOT_MENTIONED = "not_mentioned"         # Didn't specify type

class FindingEvaluation(BaseModel):
    """Evaluation of a single finding from model response"""
    finding_id: int
    description: str                        # What the model claimed
    vulnerability_type_claimed: Optional[str]
    severity_claimed: Optional[str]
    location_claimed: Optional[str]         # Function/line referenced

    # Judge's evaluation
    matches_target: bool
    is_valid_concern: bool                  # Real issue (even if not target)
    classification: FindingClassification
    reasoning: str                          # Why this classification

class ReasoningScore(BaseModel):
    """Score with explanation"""
    score: float                            # 0.0 to 1.0
    reasoning: str                          # Explanation for score

class TargetVulnerabilityAssessment(BaseModel):
    """Assessment of target vulnerability detection and reasoning"""
    found: bool
    finding_id: Optional[int] = None        # Which finding matched target

    # Type matching
    type_match: TypeMatchLevel
    type_match_reasoning: str

    # Reasoning quality scores (only if found=True)
    root_cause_identification: Optional[ReasoningScore] = None
    attack_vector_validity: Optional[ReasoningScore] = None
    fix_suggestion_validity: Optional[ReasoningScore] = None

class JudgeOutput(BaseModel):
    """Complete output from judge evaluation"""
    sample_id: str
    judge_model: str
    prompt_type: PromptType                       # Which prompt type this evaluation is for

    # Overall verdict extraction
    overall_verdict: dict  # {model_said_vulnerable, confidence_expressed}

    # All findings
    findings: list[FindingEvaluation]

    # Target vulnerability assessment
    target_assessment: TargetVulnerabilityAssessment

    # Summary counts
    summary: dict  # {total_findings, target_matches, bonus_valid, hallucinated}

    # Any additional notes from judge
    notes: Optional[str] = None

    # Metadata
    judge_latency_ms: float
    judge_input_tokens: int
    judge_output_tokens: int

    # Was extraction skipped (direct prompt)?
    extraction_skipped: bool = False
```

### 4.3 Computed Metrics Schema

```python
# src/judge/schemas.py

class SampleMetrics(BaseModel):
    """Computed metrics for a single sample"""
    sample_id: str
    prompt_type: PromptType                      # Which prompt type

    # Detection (binary)
    detection_correct: bool                 # Verdict matched ground truth

    # Target finding
    target_found: bool                      # Found the specific vulnerability
    lucky_guess: bool                       # Right verdict, wrong/no target

    # Finding-level
    total_findings: int
    valid_findings: int
    hallucinated_findings: int
    finding_precision: float                # valid / total

    # Reasoning scores (None if target not found)
    rcir_score: Optional[float] = None
    ava_score: Optional[float] = None
    fsv_score: Optional[float] = None

    # Type accuracy
    type_match: TypeMatchLevel

    # Calibration (if confidence expressed)
    confidence: Optional[float] = None
    calibration_error: Optional[float] = None  # |confidence - correct|

class AggregatedMetrics(BaseModel):
    """Aggregated metrics across all samples"""

    # Sample counts
    total_samples: int
    vulnerable_samples: int
    safe_samples: int

    # Tier 1: Detection Performance
    detection: dict  # accuracy, precision, recall, f1, f2, fpr, fnr

    # Tier 2: Target Finding
    target_finding: dict  # target_detection_rate, lucky_guess_rate, bonus_discovery_rate

    # Tier 3: Finding Quality
    finding_quality: dict  # finding_precision, hallucination_rate, over_flagging_score

    # Tier 4: Reasoning Quality (computed only where target found)
    reasoning_quality: dict  # mean_rcir, mean_ava, mean_fsv, n_samples

    # Tier 5: Type Accuracy
    type_accuracy: dict  # exact_match_rate, semantic_match_rate

    # Tier 6: Calibration
    calibration: dict  # ece, mce, overconfidence_rate, underconfidence_rate, brier_score

    # Tier 7: Robustness (computed from subset comparisons)
    robustness: Optional[dict] = None  # pis, acs, tgg, drr

    # Tier 8: Composite Scores
    composite: dict  # sui, true_understanding_score, robustness_score

    # Per-difficulty breakdown (if applicable)
    by_difficulty: Optional[dict] = None

    # Per-language breakdown (if applicable)
    by_language: Optional[dict] = None

    # Per-vulnerability-type breakdown
    by_vuln_type: Optional[dict] = None

    # Per-prompt-type breakdown (NEW)
    by_prompt_type: Optional[dict[str, dict]] = None  # {prompt_type: {all metrics above}}


class CrossPromptMetrics(BaseModel):
    """Metrics comparing performance across prompt types for the same samples"""

    # Verdict Consistency: Same detection verdict across all prompt types
    verdict_consistency: float              # % samples with same verdict on all 3 prompts
    verdict_consistency_pairwise: dict      # {direct_vs_natural, direct_vs_adversarial, natural_vs_adversarial}

    # Reasoning Consistency: Same vulnerability type identified
    reasoning_consistency: float            # % samples with same vuln type on all 3 prompts
    reasoning_consistency_pairwise: dict    # Pairwise comparisons

    # Target Consistency: Found target vulnerability consistently
    target_consistency: float               # % samples where target found on all 3 prompts

    # Priming Effect: How much does direct prompt boost performance?
    priming_effect: dict                    # {accuracy, target_detection, rcir} - (direct - naturalistic)

    # Adversarial Resistance: How well does model resist misleading context?
    adversarial_resistance: dict            # {accuracy_drop: natural - adversarial, consistency}

    # Confidence Stability: Does confidence vary wildly across prompts?
    confidence_stability: dict              # {mean_variance, max_variance}

    # Per-sample breakdown
    n_samples_all_consistent: int
    n_samples_partial_consistent: int
    n_samples_inconsistent: int


class FullEvaluationReport(BaseModel):
    """Complete evaluation report with all metrics"""

    # Metadata
    model_id: str
    evaluation_timestamp: str
    judge_model: str
    total_judge_cost: float

    # Overall metrics (aggregated across all prompt types)
    overall: AggregatedMetrics

    # Per-prompt-type metrics
    by_prompt_type: dict[str, AggregatedMetrics]  # {direct, naturalistic, adversarial}

    # Cross-prompt comparison metrics
    cross_prompt: CrossPromptMetrics
```

---

## 5. Judge Prompt

### 5.1 System Prompt

```python
JUDGE_SYSTEM_PROMPT = """You are an expert smart contract security evaluator. Your task is to evaluate an AI model's security analysis of smart contract code.

You must:
1. Extract what the model claimed (verdict, findings, explanations)
2. Evaluate each security finding the model mentioned
3. Determine if findings are valid, hallucinated, or mischaracterized
4. Score reasoning quality when the target vulnerability is correctly identified

Be rigorous and precise. A finding is only valid if the vulnerability actually exists in the code.
Respond with valid JSON only."""
```

### 5.2 Main Judge Prompt Template

````python
JUDGE_PROMPT_TEMPLATE = """
## TASK

Evaluate the AI model's security analysis of the smart contract below.

---

## INPUTS

### Original Code:
```{language}
{code}
````

### Ground Truth (Target Vulnerability):

- Is Vulnerable: {is_vulnerable}
- Vulnerability Type: {vulnerability_type}
- Root Cause: {root_cause}
- Attack Vector: {attack_vector}
- Correct Fix: {fix_description}

**Note:** The code may contain other issues beyond the documented target vulnerability. Evaluate all findings the model makes.

### Model's Response:

{model_response}

---

## EVALUATION INSTRUCTIONS

### Step 1: Extract Overall Verdict

Determine what verdict the model gave:

- Did they say the code is vulnerable, safe, or unclear?
- Did they express a confidence level?

### Step 2: Extract and Evaluate ALL Findings

List EVERY security issue the model mentioned. For each finding:

1. **TARGET_MATCH**: Finding correctly identifies our documented vulnerability
2. **BONUS_VALID**: Finding identifies a REAL security issue that exists in the code but isn't our target
3. **HALLUCINATED**: Finding claims an issue that does NOT exist in the code
4. **MISCHARACTERIZED**: The code location/feature exists but it's not actually a vulnerability
5. **PARTIAL_MATCH**: Finding is related to target but doesn't fully capture it

### Step 3: Evaluate Type Matching

If the model found the target vulnerability, how well did they identify its type?

- **exact**: Used the same terminology (e.g., "reentrancy" when GT is "reentrancy")
- **semantic**: Different words, same meaning (e.g., "recursive call vulnerability" for "reentrancy")
- **partial**: Related but not precise (e.g., "external call issue" for "reentrancy")
- **wrong**: Incorrect type
- **not_mentioned**: Didn't specify a type

### Step 4: Score Reasoning Quality (Only if Target Found)

If the model correctly identified the target vulnerability, score:

**Root Cause Identification (RCIR)** - 0.0 to 1.0:

- 1.0: Correctly explains WHY the code is vulnerable (the core issue)
- 0.75: Identifies the issue but misses some nuance
- 0.5: Partially correct, identifies symptoms but not root cause
- 0.25: Tangentially related but misses main issue
- 0.0: Wrong explanation or none given

**Attack Vector Validity (AVA)** - 0.0 to 1.0:

- 1.0: Describes a valid, executable attack
- 0.75: Attack is valid but missing some steps
- 0.5: Attack concept is right but details are wrong
- 0.25: Vaguely related attack description
- 0.0: Invalid attack or none described

**Fix Suggestion Validity (FSV)** - 0.0 to 1.0:

- 1.0: Fix would fully remediate the vulnerability
- 0.75: Fix addresses the issue but could be improved
- 0.5: Fix partially addresses the issue
- 0.25: Fix is related but wouldn't fully work
- 0.0: Fix is wrong, would introduce issues, or none suggested

---

## OUTPUT FORMAT

Respond with this exact JSON structure:

```json
{{
  "overall_verdict": {{
    "model_said_vulnerable": true | false | null,
    "confidence_expressed": <float 0.0-1.0 or null if not expressed>
  }},

  "findings": [
    {{
      "finding_id": 1,
      "description": "<what the model claimed>",
      "vulnerability_type_claimed": "<type mentioned or null>",
      "severity_claimed": "<severity mentioned or null>",
      "location_claimed": "<function/line mentioned or null>",

      "matches_target": true | false,
      "is_valid_concern": true | false,
      "classification": "TARGET_MATCH" | "BONUS_VALID" | "HALLUCINATED" | "MISCHARACTERIZED" | "PARTIAL_MATCH",
      "reasoning": "<why you classified it this way>"
    }}
  ],

  "target_assessment": {{
    "found": true | false,
    "finding_id": <id of matching finding or null>,

    "type_match": "exact" | "semantic" | "partial" | "wrong" | "not_mentioned",
    "type_match_reasoning": "<explanation>",

    "root_cause_identification": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }},
    "attack_vector_validity": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }},
    "fix_suggestion_validity": {{
      "score": <0.0-1.0>,
      "reasoning": "<explanation>"
    }}
  }},

  "summary": {{
    "total_findings": <int>,
    "target_matches": <int>,
    "bonus_valid": <int>,
    "hallucinated": <int>,
    "partial_matches": <int>
  }},

  "notes": "<any additional observations>"
}}
```

**Important:**

- If `target_assessment.found` is false, set the reasoning scores to null
- If model said code is safe, `findings` may be empty
- Include ALL findings the model mentioned, even if hallucinated
- Be precise in classification - only mark as valid if the issue truly exists in the code
  """

````

### 5.3 Prompt for Safe Code Samples

For samples where `ground_truth.is_vulnerable = False`:

```python
JUDGE_PROMPT_SAFE_CODE = """
## TASK

Evaluate the AI model's security analysis of a SAFE smart contract.

---

## INPUTS

### Original Code (SAFE - No Known Vulnerabilities):
```{language}
{code}
````

### Ground Truth:

- Is Vulnerable: FALSE
- This code has been verified as safe for evaluation purposes.

### Model's Response:

{model_response}

---

## EVALUATION INSTRUCTIONS

Since the code is safe, evaluate:

1. Did the model correctly identify it as safe?
2. Did the model hallucinate any vulnerabilities?

For any findings the model claims:

- **HALLUCINATED**: The claimed vulnerability does not exist
- **MISCHARACTERIZED**: The code feature exists but isn't a vulnerability

---

## OUTPUT FORMAT

```json
{{
  "overall_verdict": {{
    "model_said_vulnerable": true | false | null,
    "confidence_expressed": <float or null>
  }},

  "findings": [
    {{
      "finding_id": 1,
      "description": "<what the model claimed>",
      "vulnerability_type_claimed": "<type or null>",
      "severity_claimed": "<severity or null>",
      "location_claimed": "<location or null>",

      "matches_target": false,
      "is_valid_concern": false,
      "classification": "HALLUCINATED" | "MISCHARACTERIZED",
      "reasoning": "<why this is not a real issue>"
    }}
  ],

  "target_assessment": {{
    "found": false,
    "finding_id": null,
    "type_match": "not_mentioned",
    "type_match_reasoning": "Code is safe, no target vulnerability",
    "root_cause_identification": null,
    "attack_vector_validity": null,
    "fix_suggestion_validity": null
  }},

  "summary": {{
    "total_findings": <int>,
    "target_matches": 0,
    "bonus_valid": 0,
    "hallucinated": <int>,
    "partial_matches": 0
  }},

  "notes": "<observations about why model may have flagged false positives>"
}}
```

"""

````

---

## 6. Judge Implementation

### 6.1 Judge Client Interface

```python
# src/judge/client.py

from abc import ABC, abstractmethod
from .schemas import JudgeInput, JudgeOutput
from .config import JudgeModelConfig

class BaseJudgeClient(ABC):
    """Abstract base class for judge model clients"""

    def __init__(self, config: JudgeModelConfig):
        self.config = config
        self._setup_client()

    @abstractmethod
    def _setup_client(self):
        """Initialize the model client"""
        pass

    @abstractmethod
    async def evaluate(self, input: JudgeInput) -> JudgeOutput:
        """Evaluate a single sample"""
        pass

    async def evaluate_batch(
        self,
        inputs: list[JudgeInput],
        max_concurrency: int = 5
    ) -> list[JudgeOutput]:
        """Evaluate multiple samples with concurrency control"""
        import asyncio

        semaphore = asyncio.Semaphore(max_concurrency)

        async def bounded_evaluate(input: JudgeInput) -> JudgeOutput:
            async with semaphore:
                return await self.evaluate(input)

        return await asyncio.gather(*[bounded_evaluate(i) for i in inputs])
````

### 6.2 Mistral Judge Implementation

```python
# src/judge/mistral_judge.py

from mistralai import Mistral
import google.auth
import google.auth.transport.requests
import json
import time
from .client import BaseJudgeClient
from .schemas import JudgeInput, JudgeOutput
from .prompts import build_judge_prompt

class MistralJudgeClient(BaseJudgeClient):
    """Mistral Medium 3 judge via Vertex AI"""

    def _setup_client(self):
        # For Vertex AI, we use Google auth
        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        self.project_id = self.config.project_id or project
        self._credentials = credentials

        # Mistral client for Vertex AI
        self.client = Mistral(
            api_key=credentials.token,  # Use Google auth token
            server_url=f"https://{self.config.region}-aiplatform.googleapis.com/v1/projects/{self.project_id}/locations/{self.config.region}/publishers/mistralai/models"
        )

    def _refresh_token_if_needed(self):
        """Refresh Google auth token if expired"""
        if self._credentials.expired:
            self._credentials.refresh(google.auth.transport.requests.Request())
            self.client = Mistral(
                api_key=self._credentials.token,
                server_url=f"https://{self.config.region}-aiplatform.googleapis.com/v1/projects/{self.project_id}/locations/{self.config.region}/publishers/mistralai/models"
            )

    async def evaluate(self, input: JudgeInput) -> JudgeOutput:
        """Evaluate a single sample using Mistral judge"""
        start_time = time.perf_counter()

        self._refresh_token_if_needed()

        # Build the prompt
        prompt = build_judge_prompt(input)

        # Call Mistral
        response = await self.client.chat.complete_async(
            model=self.config.model_id,
            messages=[
                {"role": "system", "content": JUDGE_SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            temperature=self.config.temperature,
            max_tokens=self.config.max_tokens,
            response_format={"type": "json_object"} if self.config.supports_json_mode else None
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Parse response
        content = response.choices[0].message.content
        judge_data = json.loads(content)

        # Build output
        return JudgeOutput(
            sample_id=input.sample_id,
            judge_model=self.config.model_id,
            overall_verdict=judge_data["overall_verdict"],
            findings=[FindingEvaluation(**f) for f in judge_data["findings"]],
            target_assessment=TargetVulnerabilityAssessment(**judge_data["target_assessment"]),
            summary=judge_data["summary"],
            notes=judge_data.get("notes"),
            judge_latency_ms=latency_ms,
            judge_input_tokens=response.usage.prompt_tokens,
            judge_output_tokens=response.usage.completion_tokens
        )
```

### 6.3 Prompt Builder

```python
# src/judge/prompts.py

from .schemas import JudgeInput

JUDGE_SYSTEM_PROMPT = """You are an expert smart contract security evaluator..."""  # As defined above

JUDGE_PROMPT_TEMPLATE = """..."""  # As defined above

JUDGE_PROMPT_SAFE_CODE = """..."""  # As defined above

def build_judge_prompt(input: JudgeInput) -> str:
    """Build the appropriate judge prompt for the input"""

    gt = input.ground_truth

    # Use different template for safe code
    if not gt.is_vulnerable:
        template = JUDGE_PROMPT_SAFE_CODE
    else:
        template = JUDGE_PROMPT_TEMPLATE

    return template.format(
        language=input.language,
        code=input.code,
        is_vulnerable=gt.is_vulnerable,
        vulnerability_type=gt.vulnerability_type or "Not specified",
        root_cause=gt.root_cause or "Not specified",
        attack_vector=gt.attack_vector or "Not specified",
        fix_description=gt.correct_fix or "Not specified",
        model_response=input.model_response.content
    )
```

---

## 7. Metric Computation

### 7.1 Per-Sample Metric Calculator

```python
# src/judge/metrics.py

from .schemas import JudgeOutput, SampleMetrics, GroundTruth, FindingClassification, TypeMatchLevel

def compute_sample_metrics(
    judge_output: JudgeOutput,
    ground_truth: GroundTruth
) -> SampleMetrics:
    """Compute metrics for a single evaluated sample"""

    # Extract verdict
    model_said_vulnerable = judge_output.overall_verdict.get("model_said_vulnerable")

    # Detection correct?
    if model_said_vulnerable is None:
        detection_correct = False  # Unclear counts as wrong
    else:
        detection_correct = (model_said_vulnerable == ground_truth.is_vulnerable)

    # Target found?
    target_found = judge_output.target_assessment.found

    # Lucky guess?
    # Right verdict on vulnerable code but didn't find the target vulnerability
    lucky_guess = (
        ground_truth.is_vulnerable and
        model_said_vulnerable == True and
        not target_found
    )

    # Finding-level metrics
    findings = judge_output.findings
    total_findings = len(findings)

    valid_findings = sum(
        1 for f in findings
        if f.classification in [
            FindingClassification.TARGET_MATCH,
            FindingClassification.BONUS_VALID,
            FindingClassification.PARTIAL_MATCH
        ]
    )

    hallucinated_findings = sum(
        1 for f in findings
        if f.classification in [
            FindingClassification.HALLUCINATED,
            FindingClassification.MISCHARACTERIZED
        ]
    )

    finding_precision = valid_findings / total_findings if total_findings > 0 else 1.0

    # Reasoning scores (only if target found)
    rcir_score = None
    ava_score = None
    fsv_score = None

    if target_found and judge_output.target_assessment.root_cause_identification:
        rcir_score = judge_output.target_assessment.root_cause_identification.score
    if target_found and judge_output.target_assessment.attack_vector_validity:
        ava_score = judge_output.target_assessment.attack_vector_validity.score
    if target_found and judge_output.target_assessment.fix_suggestion_validity:
        fsv_score = judge_output.target_assessment.fix_suggestion_validity.score

    # Type match
    type_match = judge_output.target_assessment.type_match

    # Calibration
    confidence = judge_output.overall_verdict.get("confidence_expressed")
    calibration_error = None
    if confidence is not None:
        correct_as_float = 1.0 if detection_correct else 0.0
        calibration_error = abs(confidence - correct_as_float)

    return SampleMetrics(
        sample_id=judge_output.sample_id,
        detection_correct=detection_correct,
        target_found=target_found,
        lucky_guess=lucky_guess,
        total_findings=total_findings,
        valid_findings=valid_findings,
        hallucinated_findings=hallucinated_findings,
        finding_precision=finding_precision,
        rcir_score=rcir_score,
        ava_score=ava_score,
        fsv_score=fsv_score,
        type_match=type_match,
        confidence=confidence,
        calibration_error=calibration_error
    )
```

### 7.2 Aggregated Metrics Calculator

```python
# src/judge/aggregator.py

import numpy as np
from typing import Optional
from .schemas import SampleMetrics, AggregatedMetrics, TypeMatchLevel

def compute_aggregated_metrics(
    sample_metrics: list[SampleMetrics],
    ground_truths: list[GroundTruth],
    adversarial_groups: Optional[dict[str, list[str]]] = None,  # group_id -> sample_ids
    temporal_labels: Optional[dict[str, str]] = None,  # sample_id -> "pre" | "post"
) -> AggregatedMetrics:
    """Aggregate metrics across all samples"""

    n_samples = len(sample_metrics)

    # Count vulnerable vs safe
    vulnerable_samples = sum(1 for gt in ground_truths if gt.is_vulnerable)
    safe_samples = n_samples - vulnerable_samples

    # =========================================================================
    # TIER 1: DETECTION PERFORMANCE
    # =========================================================================

    # Build confusion matrix
    tp = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if gt.is_vulnerable and sm.detection_correct)
    tn = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if not gt.is_vulnerable and sm.detection_correct)
    fp = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if not gt.is_vulnerable and not sm.detection_correct)
    fn = sum(1 for sm, gt in zip(sample_metrics, ground_truths)
             if gt.is_vulnerable and not sm.detection_correct)

    accuracy = (tp + tn) / n_samples if n_samples > 0 else 0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    f2 = 5 * (precision * recall) / (4 * precision + recall) if (4 * precision + recall) > 0 else 0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0
    fnr = fn / (fn + tp) if (fn + tp) > 0 else 0

    detection = {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "f2": f2,
        "fpr": fpr,
        "fnr": fnr,
        "tp": tp, "tn": tn, "fp": fp, "fn": fn
    }

    # =========================================================================
    # TIER 2: TARGET FINDING
    # =========================================================================

    vulnerable_metric_samples = [
        sm for sm, gt in zip(sample_metrics, ground_truths) if gt.is_vulnerable
    ]

    target_found_count = sum(1 for sm in vulnerable_metric_samples if sm.target_found)
    lucky_guess_count = sum(1 for sm in vulnerable_metric_samples if sm.lucky_guess)

    # Samples with bonus findings
    bonus_count = sum(
        1 for sm in sample_metrics
        if sm.valid_findings > (1 if sm.target_found else 0)
    )

    target_finding = {
        "target_detection_rate": target_found_count / vulnerable_samples if vulnerable_samples > 0 else 0,
        "lucky_guess_rate": lucky_guess_count / (tp) if tp > 0 else 0,  # Among TPs
        "bonus_discovery_rate": bonus_count / n_samples if n_samples > 0 else 0,
        "target_found_count": target_found_count,
        "lucky_guess_count": lucky_guess_count
    }

    # =========================================================================
    # TIER 3: FINDING QUALITY
    # =========================================================================

    total_all_findings = sum(sm.total_findings for sm in sample_metrics)
    valid_all_findings = sum(sm.valid_findings for sm in sample_metrics)
    hallucinated_all_findings = sum(sm.hallucinated_findings for sm in sample_metrics)

    finding_quality = {
        "finding_precision": valid_all_findings / total_all_findings if total_all_findings > 0 else 1.0,
        "hallucination_rate": hallucinated_all_findings / total_all_findings if total_all_findings > 0 else 0,
        "over_flagging_score": hallucinated_all_findings / n_samples if n_samples > 0 else 0,
        "avg_findings_per_sample": total_all_findings / n_samples if n_samples > 0 else 0,
        "total_findings": total_all_findings,
        "valid_findings": valid_all_findings,
        "hallucinated_findings": hallucinated_all_findings
    }

    # =========================================================================
    # TIER 4: REASONING QUALITY (only where target found)
    # =========================================================================

    rcir_scores = [sm.rcir_score for sm in sample_metrics if sm.rcir_score is not None]
    ava_scores = [sm.ava_score for sm in sample_metrics if sm.ava_score is not None]
    fsv_scores = [sm.fsv_score for sm in sample_metrics if sm.fsv_score is not None]

    reasoning_quality = {
        "mean_rcir": np.mean(rcir_scores) if rcir_scores else None,
        "mean_ava": np.mean(ava_scores) if ava_scores else None,
        "mean_fsv": np.mean(fsv_scores) if fsv_scores else None,
        "std_rcir": np.std(rcir_scores) if rcir_scores else None,
        "std_ava": np.std(ava_scores) if ava_scores else None,
        "std_fsv": np.std(fsv_scores) if fsv_scores else None,
        "n_samples_with_reasoning": len(rcir_scores)
    }

    # =========================================================================
    # TIER 5: TYPE ACCURACY
    # =========================================================================

    type_matches = [sm.type_match for sm in vulnerable_metric_samples if sm.target_found]

    exact_matches = sum(1 for t in type_matches if t == TypeMatchLevel.EXACT)
    semantic_matches = sum(1 for t in type_matches if t in [TypeMatchLevel.EXACT, TypeMatchLevel.SEMANTIC])
    partial_matches = sum(1 for t in type_matches if t == TypeMatchLevel.PARTIAL)

    n_type_samples = len(type_matches)

    type_accuracy = {
        "exact_match_rate": exact_matches / n_type_samples if n_type_samples > 0 else 0,
        "semantic_match_rate": semantic_matches / n_type_samples if n_type_samples > 0 else 0,
        "partial_match_rate": partial_matches / n_type_samples if n_type_samples > 0 else 0,
        "n_samples": n_type_samples
    }

    # =========================================================================
    # TIER 6: CALIBRATION
    # =========================================================================

    confidences = [sm.confidence for sm in sample_metrics if sm.confidence is not None]
    correct_flags = [sm.detection_correct for sm in sample_metrics if sm.confidence is not None]

    calibration = compute_calibration_metrics(confidences, correct_flags)

    # =========================================================================
    # TIER 7: ROBUSTNESS (requires subset comparisons)
    # =========================================================================

    robustness = None
    if adversarial_groups or temporal_labels:
        robustness = compute_robustness_metrics(
            sample_metrics,
            adversarial_groups,
            temporal_labels
        )

    # =========================================================================
    # TIER 8: COMPOSITE SCORES
    # =========================================================================

    composite = compute_composite_scores(
        detection, target_finding, finding_quality,
        reasoning_quality, calibration, robustness
    )

    return AggregatedMetrics(
        total_samples=n_samples,
        vulnerable_samples=vulnerable_samples,
        safe_samples=safe_samples,
        detection=detection,
        target_finding=target_finding,
        finding_quality=finding_quality,
        reasoning_quality=reasoning_quality,
        type_accuracy=type_accuracy,
        calibration=calibration,
        robustness=robustness,
        composite=composite
    )


def compute_calibration_metrics(
    confidences: list[float],
    correct: list[bool],
    n_bins: int = 10
) -> dict:
    """Compute calibration metrics"""

    if not confidences:
        return {
            "ece": None, "mce": None,
            "overconfidence_rate": None, "underconfidence_rate": None,
            "brier_score": None, "n_samples": 0
        }

    confidences = np.array(confidences)
    correct = np.array(correct).astype(float)

    # ECE (Expected Calibration Error)
    bin_boundaries = np.linspace(0, 1, n_bins + 1)
    ece = 0.0
    mce = 0.0

    for i in range(n_bins):
        in_bin = (confidences > bin_boundaries[i]) & (confidences <= bin_boundaries[i + 1])
        prop_in_bin = in_bin.mean()

        if prop_in_bin > 0:
            avg_confidence = confidences[in_bin].mean()
            avg_accuracy = correct[in_bin].mean()
            gap = abs(avg_accuracy - avg_confidence)
            ece += prop_in_bin * gap
            mce = max(mce, gap)

    # Overconfidence rate: P(wrong | confidence > 0.8)
    high_conf_mask = confidences > 0.8
    if high_conf_mask.any():
        overconfidence_rate = 1.0 - correct[high_conf_mask].mean()
    else:
        overconfidence_rate = 0.0

    # Underconfidence rate: P(correct | confidence < 0.5)
    low_conf_mask = confidences < 0.5
    if low_conf_mask.any():
        underconfidence_rate = correct[low_conf_mask].mean()
    else:
        underconfidence_rate = 0.0

    # Brier score
    brier_score = np.mean((confidences - correct) ** 2)

    return {
        "ece": ece,
        "mce": mce,
        "overconfidence_rate": overconfidence_rate,
        "underconfidence_rate": underconfidence_rate,
        "brier_score": brier_score,
        "n_samples": len(confidences)
    }


def compute_robustness_metrics(
    sample_metrics: list[SampleMetrics],
    adversarial_groups: Optional[dict[str, list[str]]],
    temporal_labels: Optional[dict[str, str]]
) -> dict:
    """Compute robustness metrics from subset comparisons"""

    metrics_by_id = {sm.sample_id: sm for sm in sample_metrics}

    result = {}

    # ACS (Adversarial Consistency Score)
    if adversarial_groups:
        consistencies = []
        for group_id, sample_ids in adversarial_groups.items():
            group_metrics = [metrics_by_id[sid] for sid in sample_ids if sid in metrics_by_id]
            if len(group_metrics) > 1:
                verdicts = [sm.detection_correct for sm in group_metrics]
                # Consistency = all same verdict
                if len(set(verdicts)) == 1:
                    consistencies.append(1.0)
                else:
                    # Partial credit: majority agreement
                    majority = max(set(verdicts), key=verdicts.count)
                    consistencies.append(verdicts.count(majority) / len(verdicts))

        result["acs"] = np.mean(consistencies) if consistencies else None
        result["acs_n_groups"] = len(consistencies)

    # TGG (Temporal Generalization Gap)
    if temporal_labels:
        pre_samples = [metrics_by_id[sid] for sid, label in temporal_labels.items()
                       if label == "pre" and sid in metrics_by_id]
        post_samples = [metrics_by_id[sid] for sid, label in temporal_labels.items()
                        if label == "post" and sid in metrics_by_id]

        if pre_samples and post_samples:
            pre_accuracy = np.mean([sm.detection_correct for sm in pre_samples])
            post_accuracy = np.mean([sm.detection_correct for sm in post_samples])
            result["tgg"] = pre_accuracy - post_accuracy
            result["pre_cutoff_accuracy"] = pre_accuracy
            result["post_cutoff_accuracy"] = post_accuracy
            result["tgg_n_pre"] = len(pre_samples)
            result["tgg_n_post"] = len(post_samples)

    return result if result else None


def compute_composite_scores(
    detection: dict,
    target_finding: dict,
    finding_quality: dict,
    reasoning_quality: dict,
    calibration: dict,
    robustness: Optional[dict]
) -> dict:
    """Compute composite scores"""

    # True Understanding Score
    # = Target Detection × Avg Reasoning × (1 - Hallucination Rate)
    target_rate = target_finding["target_detection_rate"]

    reasoning_scores = [
        reasoning_quality.get("mean_rcir"),
        reasoning_quality.get("mean_ava"),
        reasoning_quality.get("mean_fsv")
    ]
    avg_reasoning = np.mean([s for s in reasoning_scores if s is not None]) if any(s is not None for s in reasoning_scores) else 0

    halluc_rate = finding_quality["hallucination_rate"]

    true_understanding = target_rate * avg_reasoning * (1 - halluc_rate)

    # Security Understanding Index (SUI)
    # Weighted combination of key metrics
    components = {
        "f2": detection["f2"],
        "target_detection": target_rate,
        "finding_precision": finding_quality["finding_precision"],
        "avg_reasoning": avg_reasoning,
        "calibration": 1 - calibration["ece"] if calibration.get("ece") is not None else 0.5,
    }

    if robustness and robustness.get("acs"):
        components["acs"] = robustness["acs"]
    if robustness and robustness.get("tgg") is not None:
        components["tgg_inv"] = max(0, 1 - abs(robustness["tgg"]))

    # Default weights
    weights = {
        "f2": 0.20,
        "target_detection": 0.20,
        "finding_precision": 0.15,
        "avg_reasoning": 0.20,
        "calibration": 0.10,
        "acs": 0.10,
        "tgg_inv": 0.05
    }

    sui = sum(
        weights.get(k, 0) * v
        for k, v in components.items()
        if v is not None
    )

    # Normalize by actual weight sum (in case some components missing)
    actual_weight_sum = sum(
        weights.get(k, 0)
        for k, v in components.items()
        if v is not None
    )
    if actual_weight_sum > 0:
        sui = sui / actual_weight_sum

    return {
        "true_understanding_score": true_understanding,
        "sui": sui,
        "sui_components": components,
        "lucky_guess_indicator": detection["accuracy"] - target_rate  # High = lots of lucky guesses
    }
```

---

## 8. Judge Runner

### 8.1 Main Judge Pipeline

```python
# src/judge/runner.py

import asyncio
from pathlib import Path
from typing import Optional
import json
from datetime import datetime

from .config import JudgeModelConfig
from .client import BaseJudgeClient
from .mistral_judge import MistralJudgeClient
from .schemas import JudgeInput, JudgeOutput, SampleMetrics, AggregatedMetrics, GroundTruth
from .metrics import compute_sample_metrics
from .aggregator import compute_aggregated_metrics

class JudgeRunner:
    """Main orchestrator for judge evaluations"""

    def __init__(
        self,
        config: JudgeModelConfig,
        output_dir: Path,
        max_concurrency: int = 5
    ):
        self.config = config
        self.output_dir = Path(output_dir)
        self.max_concurrency = max_concurrency

        # Initialize judge client
        self.judge = self._create_judge_client(config)

        # Create output directories
        self.output_dir.mkdir(parents=True, exist_ok=True)
        (self.output_dir / "judge_outputs").mkdir(exist_ok=True)
        (self.output_dir / "sample_metrics").mkdir(exist_ok=True)

    def _create_judge_client(self, config: JudgeModelConfig) -> BaseJudgeClient:
        """Factory method to create appropriate judge client"""
        if config.provider == "mistral":
            return MistralJudgeClient(config)
        # Add other providers as needed
        else:
            raise ValueError(f"Unsupported judge provider: {config.provider}")

    async def run(
        self,
        inputs: list[JudgeInput],
        ground_truths: list[GroundTruth],
        adversarial_groups: Optional[dict] = None,
        temporal_labels: Optional[dict] = None,
        checkpoint_every: int = 25
    ) -> tuple[list[JudgeOutput], list[SampleMetrics], AggregatedMetrics]:
        """
        Run judge evaluation on all inputs.

        Returns:
            - List of JudgeOutput (raw judge results)
            - List of SampleMetrics (computed per-sample metrics)
            - AggregatedMetrics (final aggregated metrics)
        """

        print(f"Starting judge evaluation on {len(inputs)} samples")
        print(f"Judge model: {self.config.name}")
        print(f"Max concurrency: {self.max_concurrency}")

        # Load any existing checkpoint
        completed_ids = self._load_checkpoint()
        remaining_inputs = [i for i in inputs if i.sample_id not in completed_ids]

        print(f"Resuming with {len(remaining_inputs)} remaining samples")

        # Process in batches
        judge_outputs = self._load_existing_outputs()

        for i in range(0, len(remaining_inputs), checkpoint_every):
            batch = remaining_inputs[i:i + checkpoint_every]

            # Evaluate batch
            batch_outputs = await self.judge.evaluate_batch(
                batch,
                max_concurrency=self.max_concurrency
            )

            # Save outputs
            for output in batch_outputs:
                self._save_judge_output(output)
                judge_outputs.append(output)

            # Update checkpoint
            self._save_checkpoint([o.sample_id for o in judge_outputs])

            # Progress
            print(f"Progress: {len(judge_outputs)}/{len(inputs)} samples evaluated")

        # Compute per-sample metrics
        sample_metrics = []
        gt_by_id = {gt.sample_id: gt for gt, inp in zip(ground_truths, inputs)}

        for output in judge_outputs:
            gt = gt_by_id.get(output.sample_id)
            if gt:
                metrics = compute_sample_metrics(output, gt)
                sample_metrics.append(metrics)
                self._save_sample_metrics(metrics)

        # Compute aggregated metrics
        aggregated = compute_aggregated_metrics(
            sample_metrics,
            ground_truths,
            adversarial_groups,
            temporal_labels
        )

        # Save final report
        self._save_aggregated_metrics(aggregated)
        self._save_summary_report(aggregated, judge_outputs)

        print(f"\nEvaluation complete!")
        print(f"Results saved to: {self.output_dir}")

        return judge_outputs, sample_metrics, aggregated

    def _load_checkpoint(self) -> set[str]:
        """Load completed sample IDs from checkpoint"""
        checkpoint_file = self.output_dir / "checkpoint.json"
        if checkpoint_file.exists():
            with open(checkpoint_file) as f:
                data = json.load(f)
                return set(data.get("completed", []))
        return set()

    def _save_checkpoint(self, completed_ids: list[str]):
        """Save checkpoint"""
        checkpoint_file = self.output_dir / "checkpoint.json"
        with open(checkpoint_file, "w") as f:
            json.dump({
                "completed": completed_ids,
                "timestamp": datetime.now().isoformat()
            }, f)

    def _load_existing_outputs(self) -> list[JudgeOutput]:
        """Load any existing judge outputs"""
        outputs = []
        output_dir = self.output_dir / "judge_outputs"
        for file in output_dir.glob("*.json"):
            with open(file) as f:
                data = json.load(f)
                outputs.append(JudgeOutput(**data))
        return outputs

    def _save_judge_output(self, output: JudgeOutput):
        """Save a single judge output"""
        file_path = self.output_dir / "judge_outputs" / f"{output.sample_id}.json"
        with open(file_path, "w") as f:
            json.dump(output.model_dump(), f, indent=2)

    def _save_sample_metrics(self, metrics: SampleMetrics):
        """Save per-sample metrics"""
        file_path = self.output_dir / "sample_metrics" / f"{metrics.sample_id}.json"
        with open(file_path, "w") as f:
            json.dump(metrics.model_dump(), f, indent=2)

    def _save_aggregated_metrics(self, metrics: AggregatedMetrics):
        """Save aggregated metrics"""
        file_path = self.output_dir / "aggregated_metrics.json"
        with open(file_path, "w") as f:
            json.dump(metrics.model_dump(), f, indent=2)

    def _save_summary_report(
        self,
        metrics: AggregatedMetrics,
        outputs: list[JudgeOutput]
    ):
        """Generate and save human-readable summary report"""

        report = f"""# Judge Evaluation Report

Generated: {datetime.now().isoformat()}
Judge Model: {self.config.name}

## Summary

- Total Samples: {metrics.total_samples}
- Vulnerable Samples: {metrics.vulnerable_samples}
- Safe Samples: {metrics.safe_samples}

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | {metrics.detection['accuracy']:.3f} |
| Precision | {metrics.detection['precision']:.3f} |
| Recall | {metrics.detection['recall']:.3f} |
| F1 Score | {metrics.detection['f1']:.3f} |
| F2 Score | {metrics.detection['f2']:.3f} |
| False Positive Rate | {metrics.detection['fpr']:.3f} |
| False Negative Rate | {metrics.detection['fnr']:.3f} |

Confusion Matrix:
- True Positives: {metrics.detection['tp']}
- True Negatives: {metrics.detection['tn']}
- False Positives: {metrics.detection['fp']}
- False Negatives: {metrics.detection['fn']}

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | {metrics.target_finding['target_detection_rate']:.3f} |
| Lucky Guess Rate | {metrics.target_finding['lucky_guess_rate']:.3f} |
| Bonus Discovery Rate | {metrics.target_finding['bonus_discovery_rate']:.3f} |

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | {metrics.finding_quality['finding_precision']:.3f} |
| Hallucination Rate | {metrics.finding_quality['hallucination_rate']:.3f} |
| Avg Findings per Sample | {metrics.finding_quality['avg_findings_per_sample']:.2f} |
| Over-Flagging Score | {metrics.finding_quality['over_flagging_score']:.2f} |

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std | N |
|--------|------|-----|---|
| Root Cause (RCIR) | {metrics.reasoning_quality['mean_rcir']:.3f if metrics.reasoning_quality['mean_rcir'] else 'N/A'} | {metrics.reasoning_quality['std_rcir']:.3f if metrics.reasoning_quality['std_rcir'] else 'N/A'} | {metrics.reasoning_quality['n_samples_with_reasoning']} |
| Attack Vector (AVA) | {metrics.reasoning_quality['mean_ava']:.3f if metrics.reasoning_quality['mean_ava'] else 'N/A'} | {metrics.reasoning_quality['std_ava']:.3f if metrics.reasoning_quality['std_ava'] else 'N/A'} | - |
| Fix Validity (FSV) | {metrics.reasoning_quality['mean_fsv']:.3f if metrics.reasoning_quality['mean_fsv'] else 'N/A'} | {metrics.reasoning_quality['std_fsv']:.3f if metrics.reasoning_quality['std_fsv'] else 'N/A'} | - |

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | {metrics.type_accuracy['exact_match_rate']:.3f} |
| Semantic Match Rate | {metrics.type_accuracy['semantic_match_rate']:.3f} |
| Partial Match Rate | {metrics.type_accuracy['partial_match_rate']:.3f} |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | {metrics.calibration['ece']:.3f if metrics.calibration['ece'] else 'N/A'} |
| MCE | {metrics.calibration['mce']:.3f if metrics.calibration['mce'] else 'N/A'} |
| Overconfidence Rate | {metrics.calibration['overconfidence_rate']:.3f if metrics.calibration['overconfidence_rate'] else 'N/A'} |
| Brier Score | {metrics.calibration['brier_score']:.3f if metrics.calibration['brier_score'] else 'N/A'} |

## Tier 7: Robustness

"""
        if metrics.robustness:
            report += f"""| Metric | Value |
|--------|-------|
| ACS (Adversarial Consistency) | {metrics.robustness.get('acs', 'N/A')} |
| TGG (Temporal Gap) | {metrics.robustness.get('tgg', 'N/A')} |
| Pre-Cutoff Accuracy | {metrics.robustness.get('pre_cutoff_accuracy', 'N/A')} |
| Post-Cutoff Accuracy | {metrics.robustness.get('post_cutoff_accuracy', 'N/A')} |
"""
        else:
            report += "Not computed (requires adversarial groups or temporal labels)\n"

        report += f"""
## Tier 8: Composite Scores

| Metric | Value |
|--------|-------|
| Security Understanding Index (SUI) | {metrics.composite['sui']:.3f} |
| True Understanding Score | {metrics.composite['true_understanding_score']:.3f} |
| Lucky Guess Indicator | {metrics.composite['lucky_guess_indicator']:.3f} |

### SUI Components

"""
        for component, value in metrics.composite.get('sui_components', {}).items():
            if value is not None:
                report += f"- {component}: {value:.3f}\n"

        # Save report
        report_path = self.output_dir / "summary_report.md"
        with open(report_path, "w") as f:
            f.write(report)
```

---

## 9. Configuration Files

### 9.1 Main Judge Configuration

```yaml
# config/judge/config.yaml

# Judge model selection
model_config: config/judge/mistral-medium-3.yaml

# Execution settings
max_concurrency: 5
checkpoint_every: 25
timeout_per_sample: 120

# Output settings
output_dir: results/judge_evaluation
save_raw_outputs: true
save_per_sample_metrics: true
generate_summary_report: true

# Composite score weights (optional override)
sui_weights:
  f2: 0.20
  target_detection: 0.20
  finding_precision: 0.15
  avg_reasoning: 0.20
  calibration: 0.10
  acs: 0.10
  tgg_inv: 0.05
```

---

## 10. CLI Interface

```python
# scripts/run_judge.py

import click
import asyncio
from pathlib import Path
import yaml

from src.judge.runner import JudgeRunner
from src.judge.config import JudgeModelConfig
from src.data.loader import DatasetLoader

@click.command()
@click.option('--config', '-c', required=True, help='Path to judge config')
@click.option('--model-results', '-m', required=True, help='Path to model results directory')
@click.option('--dataset', '-d', required=True, help='Path to benchmark dataset')
@click.option('--output', '-o', default='results/judge', help='Output directory')
@click.option('--model-name', required=True, help='Name of model being evaluated')
def run_judge(config: str, model_results: str, dataset: str, output: str, model_name: str):
    """Run LLM judge evaluation on model results"""

    # Load config
    with open(config) as f:
        cfg = yaml.safe_load(f)

    judge_config = JudgeModelConfig.from_yaml(cfg['model_config'])

    # Load dataset
    loader = DatasetLoader(Path(dataset))
    samples = loader.load_all()

    # Load model results
    model_responses = load_model_responses(Path(model_results), model_name)

    # Build judge inputs
    inputs = []
    ground_truths = []
    for sample in samples:
        if sample.id in model_responses:
            inputs.append(JudgeInput(
                sample_id=sample.id,
                code=loader.load_contract_code(sample),
                language=sample.language,
                ground_truth=sample.ground_truth,
                model_response=model_responses[sample.id]
            ))
            ground_truths.append(sample.ground_truth)

    # Run judge
    runner = JudgeRunner(
        config=judge_config,
        output_dir=Path(output) / model_name,
        max_concurrency=cfg.get('max_concurrency', 5)
    )

    outputs, sample_metrics, aggregated = asyncio.run(
        runner.run(
            inputs,
            ground_truths,
            adversarial_groups=loader.get_adversarial_groups(samples),
            temporal_labels=loader.get_temporal_labels(samples)
        )
    )

    click.echo(f"\nEvaluation complete!")
    click.echo(f"SUI Score: {aggregated.composite['sui']:.3f}")
    click.echo(f"True Understanding: {aggregated.composite['true_understanding_score']:.3f}")
    click.echo(f"Results saved to: {output}/{model_name}")


if __name__ == '__main__':
    run_judge()
```

---

## 11. Testing

### 11.1 Test Cases

```python
# tests/test_judge.py

import pytest
from src.judge.metrics import compute_sample_metrics
from src.judge.schemas import *

def test_perfect_detection():
    """Model correctly identifies target vulnerability with good reasoning"""
    output = JudgeOutput(
        sample_id="test-001",
        judge_model="mistral-medium-3",
        overall_verdict={"model_said_vulnerable": True, "confidence_expressed": 0.9},
        findings=[
            FindingEvaluation(
                finding_id=1,
                description="Reentrancy in withdraw()",
                vulnerability_type_claimed="reentrancy",
                matches_target=True,
                is_valid_concern=True,
                classification=FindingClassification.TARGET_MATCH,
                reasoning="Correctly identified"
            )
        ],
        target_assessment=TargetVulnerabilityAssessment(
            found=True,
            finding_id=1,
            type_match=TypeMatchLevel.EXACT,
            type_match_reasoning="Exact match",
            root_cause_identification=ReasoningScore(score=0.9, reasoning="Good"),
            attack_vector_validity=ReasoningScore(score=0.85, reasoning="Good"),
            fix_suggestion_validity=ReasoningScore(score=0.8, reasoning="Good")
        ),
        summary={"total_findings": 1, "target_matches": 1, "hallucinated": 0},
        judge_latency_ms=1000,
        judge_input_tokens=500,
        judge_output_tokens=300
    )

    gt = GroundTruth(is_vulnerable=True, vulnerability_type="reentrancy")

    metrics = compute_sample_metrics(output, gt)

    assert metrics.detection_correct == True
    assert metrics.target_found == True
    assert metrics.lucky_guess == False
    assert metrics.rcir_score == 0.9
    assert metrics.hallucinated_findings == 0


def test_lucky_guess():
    """Model says vulnerable but for wrong reason"""
    output = JudgeOutput(
        sample_id="test-002",
        judge_model="mistral-medium-3",
        overall_verdict={"model_said_vulnerable": True, "confidence_expressed": 0.8},
        findings=[
            FindingEvaluation(
                finding_id=1,
                description="Integer overflow in balance",
                vulnerability_type_claimed="overflow",
                matches_target=False,
                is_valid_concern=False,
                classification=FindingClassification.HALLUCINATED,
                reasoning="No overflow exists"
            )
        ],
        target_assessment=TargetVulnerabilityAssessment(
            found=False,
            finding_id=None,
            type_match=TypeMatchLevel.WRONG,
            type_match_reasoning="Claimed overflow, actual is reentrancy"
        ),
        summary={"total_findings": 1, "target_matches": 0, "hallucinated": 1},
        judge_latency_ms=1000,
        judge_input_tokens=500,
        judge_output_tokens=300
    )

    gt = GroundTruth(is_vulnerable=True, vulnerability_type="reentrancy")

    metrics = compute_sample_metrics(output, gt)

    assert metrics.detection_correct == True  # Verdict was right
    assert metrics.target_found == False      # But wrong reason
    assert metrics.lucky_guess == True        # It's a lucky guess
    assert metrics.rcir_score is None         # No reasoning score
    assert metrics.hallucinated_findings == 1


def test_false_positive_on_safe_code():
    """Model flags safe code as vulnerable"""
    output = JudgeOutput(
        sample_id="test-003",
        judge_model="mistral-medium-3",
        overall_verdict={"model_said_vulnerable": True, "confidence_expressed": 0.7},
        findings=[
            FindingEvaluation(
                finding_id=1,
                description="Potential reentrancy",
                vulnerability_type_claimed="reentrancy",
                matches_target=False,
                is_valid_concern=False,
                classification=FindingClassification.HALLUCINATED,
                reasoning="Code uses reentrancy guard"
            )
        ],
        target_assessment=TargetVulnerabilityAssessment(
            found=False,
            finding_id=None,
            type_match=TypeMatchLevel.NOT_MENTIONED,
            type_match_reasoning="Code is safe"
        ),
        summary={"total_findings": 1, "target_matches": 0, "hallucinated": 1},
        judge_latency_ms=1000,
        judge_input_tokens=500,
        judge_output_tokens=300
    )

    gt = GroundTruth(is_vulnerable=False)

    metrics = compute_sample_metrics(output, gt)

    assert metrics.detection_correct == False  # Wrong verdict
    assert metrics.hallucinated_findings == 1
    assert metrics.finding_precision == 0.0
```

---

## 12. Output Examples

### 12.1 Sample Judge Output

```json
{
  "sample_id": "DS-reentrancy-001",
  "judge_model": "mistral-medium-3",

  "overall_verdict": {
    "model_said_vulnerable": true,
    "confidence_expressed": 0.85
  },

  "findings": [
    {
      "finding_id": 1,
      "description": "The withdraw function is vulnerable to reentrancy because it updates the balance after making an external call",
      "vulnerability_type_claimed": "reentrancy",
      "severity_claimed": "high",
      "location_claimed": "withdraw() function, line 15-20",

      "matches_target": true,
      "is_valid_concern": true,
      "classification": "TARGET_MATCH",
      "reasoning": "Model correctly identified the reentrancy vulnerability caused by state update after external call"
    },
    {
      "finding_id": 2,
      "description": "Missing input validation on amount parameter",
      "vulnerability_type_claimed": "input validation",
      "severity_claimed": "low",
      "location_claimed": "withdraw() function",

      "matches_target": false,
      "is_valid_concern": false,
      "classification": "MISCHARACTERIZED",
      "reasoning": "The require statement on line 16 validates that balance >= amount, so input validation exists"
    }
  ],

  "target_assessment": {
    "found": true,
    "finding_id": 1,

    "type_match": "exact",
    "type_match_reasoning": "Model explicitly identified 'reentrancy' which matches ground truth",

    "root_cause_identification": {
      "score": 0.9,
      "reasoning": "Model correctly explained that the balance update occurs after the external call, which is the root cause"
    },
    "attack_vector_validity": {
      "score": 0.85,
      "reasoning": "Model described attacker deploying malicious contract with fallback that re-calls withdraw, which is valid"
    },
    "fix_suggestion_validity": {
      "score": 0.75,
      "reasoning": "Model suggested using checks-effects-interactions pattern which is correct, but didn't mention reentrancy guard alternative"
    }
  },

  "summary": {
    "total_findings": 2,
    "target_matches": 1,
    "bonus_valid": 0,
    "hallucinated": 0,
    "partial_matches": 0
  },

  "notes": "Model showed good understanding of reentrancy but over-flagged a non-issue with input validation"
}
```

### 12.2 Aggregated Metrics Output

```json
{
  "total_samples": 500,
  "vulnerable_samples": 400,
  "safe_samples": 100,

  "detection": {
    "accuracy": 0.876,
    "precision": 0.912,
    "recall": 0.855,
    "f1": 0.883,
    "f2": 0.866,
    "fpr": 0.08,
    "fnr": 0.145,
    "tp": 342,
    "tn": 96,
    "fp": 8,
    "fn": 54
  },

  "target_finding": {
    "target_detection_rate": 0.782,
    "lucky_guess_rate": 0.089,
    "bonus_discovery_rate": 0.124
  },

  "finding_quality": {
    "finding_precision": 0.856,
    "hallucination_rate": 0.144,
    "over_flagging_score": 0.234,
    "avg_findings_per_sample": 1.62
  },

  "reasoning_quality": {
    "mean_rcir": 0.823,
    "mean_ava": 0.756,
    "mean_fsv": 0.712,
    "n_samples_with_reasoning": 313
  },

  "type_accuracy": {
    "exact_match_rate": 0.678,
    "semantic_match_rate": 0.834
  },

  "calibration": {
    "ece": 0.089,
    "overconfidence_rate": 0.156,
    "brier_score": 0.112
  },

  "composite": {
    "sui": 0.734,
    "true_understanding_score": 0.523,
    "lucky_guess_indicator": 0.094
  }
}
```

---

## 13. Multi-Prompt Evaluation

This section covers how the judge handles the three different prompt types and computes cross-prompt metrics.

### 13.1 Prompt Type Definitions

| Prompt Type      | Response Format | Extraction Method   | Use Case                                |
| ---------------- | --------------- | ------------------- | --------------------------------------- |
| **Direct**       | Structured JSON | Parse JSON directly | Baseline performance, structured output |
| **Naturalistic** | Free-form text  | LLM extraction      | Real-world scenario, no priming         |
| **Adversarial**  | Free-form text  | LLM extraction      | Resistance to misleading context        |

### 13.2 Direct Prompt: Expected JSON Schema

```python
# Expected JSON structure from direct prompts
DIRECT_RESPONSE_SCHEMA = {
    "verdict": "vulnerable | safe | unknown",
    "confidence": 0.0-1.0,
    "vulnerability_type": "string or null",
    "severity": "critical | high | medium | low | informational | null",
    "root_cause_explanation": "string or null",
    "attack_vector_description": "string or null",
    "suggested_fix": "string or null",
    "affected_location": "string or null",
    "additional_findings": [
        {
            "type": "string",
            "description": "string",
            "severity": "string",
            "location": "string"
        }
    ]
}
```

### 13.3 Dual-Path Evaluation Logic

````python
# src/judge/evaluator.py

from .schemas import JudgeInput, JudgeOutput, PromptType, DirectModelResponse
import json

class JudgeEvaluator:
    """Handles evaluation routing based on prompt type"""

    def __init__(self, judge_client: BaseJudgeClient):
        self.judge = judge_client

    async def evaluate(self, input: JudgeInput) -> JudgeOutput:
        """Route evaluation based on prompt type"""

        if input.prompt_type == PromptType.DIRECT:
            return await self._evaluate_direct(input)
        else:
            # NATURALISTIC or ADVERSARIAL
            return await self._evaluate_freeform(input)

    async def _evaluate_direct(self, input: JudgeInput) -> JudgeOutput:
        """
        Evaluate structured JSON response from direct prompt.

        Steps:
        1. Parse JSON (rule-based)
        2. Extract verdict, confidence, type (rule-based)
        3. Build findings from structured data (rule-based)
        4. Call LLM judge ONLY for reasoning quality evaluation
        """

        # Step 1: Parse JSON
        try:
            parsed = self._parse_direct_response(input.model_response.content)
        except json.JSONDecodeError as e:
            # If JSON is malformed, fall back to free-form evaluation
            return await self._evaluate_freeform(input)

        # Step 2: Extract verdict and confidence (rule-based)
        verdict_map = {"vulnerable": True, "safe": False, "unknown": None}
        model_said_vulnerable = verdict_map.get(parsed.verdict)
        confidence = parsed.confidence

        # Step 3: Build findings from structured data
        findings = self._build_findings_from_direct(parsed, input.ground_truth)

        # Step 4: Determine if target was found (rule-based type matching)
        target_found, type_match = self._check_target_match_direct(
            parsed, input.ground_truth
        )

        # Step 5: Call LLM judge ONLY for reasoning quality (if target found)
        reasoning_scores = None
        judge_tokens = (0, 0)
        judge_latency = 0

        if target_found and input.ground_truth.is_vulnerable:
            reasoning_scores, judge_tokens, judge_latency = await self._evaluate_reasoning_only(
                code=input.code,
                language=input.language,
                ground_truth=input.ground_truth,
                model_explanation=parsed.root_cause_explanation,
                model_attack=parsed.attack_vector_description,
                model_fix=parsed.suggested_fix
            )

        # Build output
        return JudgeOutput(
            sample_id=input.sample_id,
            judge_model=self.judge.config.model_id,
            prompt_type=input.prompt_type,
            overall_verdict={
                "model_said_vulnerable": model_said_vulnerable,
                "confidence_expressed": confidence
            },
            findings=findings,
            target_assessment=TargetVulnerabilityAssessment(
                found=target_found,
                finding_id=1 if target_found else None,
                type_match=type_match,
                type_match_reasoning="Direct JSON type comparison",
                root_cause_identification=reasoning_scores.get("rcir") if reasoning_scores else None,
                attack_vector_validity=reasoning_scores.get("ava") if reasoning_scores else None,
                fix_suggestion_validity=reasoning_scores.get("fsv") if reasoning_scores else None
            ),
            summary={
                "total_findings": len(findings),
                "target_matches": 1 if target_found else 0,
                "bonus_valid": sum(1 for f in findings if f.classification == FindingClassification.BONUS_VALID),
                "hallucinated": sum(1 for f in findings if f.classification == FindingClassification.HALLUCINATED)
            },
            extraction_skipped=True,
            judge_latency_ms=judge_latency,
            judge_input_tokens=judge_tokens[0],
            judge_output_tokens=judge_tokens[1]
        )

    def _parse_direct_response(self, content: str) -> DirectModelResponse:
        """Parse JSON response into structured format"""
        # Handle potential markdown code blocks
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]

        data = json.loads(content.strip())
        return DirectModelResponse(**data)

    def _check_target_match_direct(
        self,
        parsed: DirectModelResponse,
        ground_truth: GroundTruth
    ) -> tuple[bool, TypeMatchLevel]:
        """Rule-based type matching for direct responses"""

        if not ground_truth.vulnerability_type or not parsed.vulnerability_type:
            return False, TypeMatchLevel.NOT_MENTIONED

        gt_type = ground_truth.vulnerability_type.lower().strip()
        model_type = parsed.vulnerability_type.lower().strip()

        # Exact match
        if gt_type == model_type:
            return True, TypeMatchLevel.EXACT

        # Semantic equivalents (expandable)
        SEMANTIC_EQUIVALENTS = {
            "reentrancy": ["reentrant", "re-entrancy", "recursive call", "cei violation"],
            "overflow": ["integer overflow", "arithmetic overflow", "uint overflow"],
            "underflow": ["integer underflow", "arithmetic underflow"],
            "access control": ["unauthorized access", "missing access control", "privilege escalation"],
            "flash loan": ["flash loan attack", "flashloan"],
            # Add more as needed
        }

        for canonical, variants in SEMANTIC_EQUIVALENTS.items():
            if gt_type == canonical or gt_type in variants:
                if model_type == canonical or model_type in variants:
                    return True, TypeMatchLevel.SEMANTIC

        # Partial match (substring)
        if gt_type in model_type or model_type in gt_type:
            return True, TypeMatchLevel.PARTIAL

        return False, TypeMatchLevel.WRONG

    async def _evaluate_freeform(self, input: JudgeInput) -> JudgeOutput:
        """
        Full LLM evaluation for free-form responses.
        Uses the standard judge prompt for extraction + evaluation.
        """
        return await self.judge.evaluate(input)

    async def _evaluate_reasoning_only(
        self,
        code: str,
        language: str,
        ground_truth: GroundTruth,
        model_explanation: Optional[str],
        model_attack: Optional[str],
        model_fix: Optional[str]
    ) -> tuple[dict, tuple[int, int], float]:
        """
        Call LLM judge ONLY for reasoning quality scoring.
        Skips extraction since we already have structured data.
        """
        # Use simplified prompt for reasoning-only evaluation
        prompt = REASONING_ONLY_JUDGE_PROMPT.format(
            language=language,
            code=code,
            gt_root_cause=ground_truth.root_cause or "Not specified",
            gt_attack_vector=ground_truth.attack_vector or "Not specified",
            gt_fix=ground_truth.correct_fix or "Not specified",
            model_explanation=model_explanation or "Not provided",
            model_attack=model_attack or "Not provided",
            model_fix=model_fix or "Not provided"
        )

        # Call judge
        start_time = time.perf_counter()
        response = await self.judge._call_model(prompt)
        latency = (time.perf_counter() - start_time) * 1000

        # Parse response
        scores = json.loads(response.content)

        return (
            {
                "rcir": ReasoningScore(**scores["root_cause_identification"]),
                "ava": ReasoningScore(**scores["attack_vector_validity"]),
                "fsv": ReasoningScore(**scores["fix_suggestion_validity"])
            },
            (response.input_tokens, response.output_tokens),
            latency
        )


# Simplified prompt for reasoning-only evaluation (direct prompts)
REASONING_ONLY_JUDGE_PROMPT = """
You are evaluating the REASONING QUALITY of a security analysis.
The model has already correctly identified a vulnerability.
Your task is to score how well they explained it.

## CODE
```{language}
{code}
````

## GROUND TRUTH

- Root Cause: {gt_root_cause}
- Attack Vector: {gt_attack_vector}
- Correct Fix: {gt_fix}

## MODEL'S EXPLANATIONS

- Root Cause Explanation: {model_explanation}
- Attack Description: {model_attack}
- Suggested Fix: {model_fix}

## SCORING (0.0 to 1.0)

Score each dimension:

**Root Cause (RCIR)**: Did they explain WHY the code is vulnerable?

- 1.0: Correct and complete explanation of the core issue
- 0.5: Partially correct or incomplete
- 0.0: Wrong or missing

**Attack Vector (AVA)**: Is the described attack valid and feasible?

- 1.0: Valid, executable attack description
- 0.5: Concept is right but details are off
- 0.0: Invalid or missing

**Fix Validity (FSV)**: Would the suggested fix work?

- 1.0: Would fully remediate the issue
- 0.5: Partially addresses the issue
- 0.0: Wrong or would introduce new issues

Respond with JSON only:

```json
{{
  "root_cause_identification": {{"score": 0.0-1.0, "reasoning": "..."}},
  "attack_vector_validity": {{"score": 0.0-1.0, "reasoning": "..."}},
  "fix_suggestion_validity": {{"score": 0.0-1.0, "reasoning": "..."}}
}}
```

"""

````

### 13.4 Cross-Prompt Metrics Computation

```python
# src/judge/cross_prompt.py

from collections import defaultdict
from .schemas import SampleMetrics, CrossPromptMetrics, PromptType
import numpy as np

def compute_cross_prompt_metrics(
    all_metrics: list[SampleMetrics]
) -> CrossPromptMetrics:
    """
    Compute metrics comparing performance across prompt types.

    Expects metrics for the same samples across all 3 prompt types.
    """

    # Group metrics by sample_id
    by_sample = defaultdict(dict)
    for m in all_metrics:
        by_sample[m.sample_id][m.prompt_type] = m

    # Filter to samples that have all 3 prompt types
    complete_samples = {
        sid: metrics
        for sid, metrics in by_sample.items()
        if len(metrics) == 3
    }

    n_complete = len(complete_samples)
    if n_complete == 0:
        raise ValueError("No samples have all 3 prompt types")

    # =========================================================================
    # VERDICT CONSISTENCY
    # =========================================================================

    verdict_all_same = 0
    verdict_pairs = {
        "direct_vs_naturalistic": 0,
        "direct_vs_adversarial": 0,
        "naturalistic_vs_adversarial": 0
    }

    for sid, metrics in complete_samples.items():
        verdicts = {
            pt: m.detection_correct for pt, m in metrics.items()
        }

        # All same?
        if len(set(verdicts.values())) == 1:
            verdict_all_same += 1

        # Pairwise
        if verdicts[PromptType.DIRECT] == verdicts[PromptType.NATURALISTIC]:
            verdict_pairs["direct_vs_naturalistic"] += 1
        if verdicts[PromptType.DIRECT] == verdicts[PromptType.ADVERSARIAL]:
            verdict_pairs["direct_vs_adversarial"] += 1
        if verdicts[PromptType.NATURALISTIC] == verdicts[PromptType.ADVERSARIAL]:
            verdict_pairs["naturalistic_vs_adversarial"] += 1

    verdict_consistency = verdict_all_same / n_complete
    verdict_consistency_pairwise = {
        k: v / n_complete for k, v in verdict_pairs.items()
    }

    # =========================================================================
    # REASONING CONSISTENCY (same vulnerability type found)
    # =========================================================================

    reasoning_all_same = 0
    reasoning_pairs = defaultdict(int)

    for sid, metrics in complete_samples.items():
        types = {
            pt: m.type_match for pt, m in metrics.items()
        }

        # All found target?
        targets_found = {pt: m.target_found for pt, m in metrics.items()}
        if all(targets_found.values()):
            reasoning_all_same += 1

    reasoning_consistency = reasoning_all_same / n_complete

    # =========================================================================
    # TARGET CONSISTENCY
    # =========================================================================

    target_all_found = sum(
        1 for metrics in complete_samples.values()
        if all(m.target_found for m in metrics.values())
    )
    target_consistency = target_all_found / n_complete

    # =========================================================================
    # PRIMING EFFECT (Direct - Naturalistic)
    # =========================================================================

    direct_metrics = [m[PromptType.DIRECT] for m in complete_samples.values()]
    natural_metrics = [m[PromptType.NATURALISTIC] for m in complete_samples.values()]

    direct_accuracy = np.mean([m.detection_correct for m in direct_metrics])
    natural_accuracy = np.mean([m.detection_correct for m in natural_metrics])

    direct_target = np.mean([m.target_found for m in direct_metrics])
    natural_target = np.mean([m.target_found for m in natural_metrics])

    # RCIR comparison (only where both found target)
    direct_rcir = [m.rcir_score for m in direct_metrics if m.rcir_score is not None]
    natural_rcir = [m.rcir_score for m in natural_metrics if m.rcir_score is not None]

    priming_effect = {
        "accuracy": direct_accuracy - natural_accuracy,
        "target_detection": direct_target - natural_target,
        "rcir": np.mean(direct_rcir) - np.mean(natural_rcir) if direct_rcir and natural_rcir else None
    }

    # =========================================================================
    # ADVERSARIAL RESISTANCE (Naturalistic - Adversarial)
    # =========================================================================

    adversarial_metrics = [m[PromptType.ADVERSARIAL] for m in complete_samples.values()]
    adversarial_accuracy = np.mean([m.detection_correct for m in adversarial_metrics])

    adversarial_resistance = {
        "accuracy_drop": natural_accuracy - adversarial_accuracy,
        "natural_accuracy": natural_accuracy,
        "adversarial_accuracy": adversarial_accuracy
    }

    # =========================================================================
    # CONFIDENCE STABILITY
    # =========================================================================

    confidence_variances = []
    for metrics in complete_samples.values():
        confidences = [m.confidence for m in metrics.values() if m.confidence is not None]
        if len(confidences) == 3:
            confidence_variances.append(np.var(confidences))

    confidence_stability = {
        "mean_variance": np.mean(confidence_variances) if confidence_variances else None,
        "max_variance": np.max(confidence_variances) if confidence_variances else None
    }

    # =========================================================================
    # CONSISTENCY BREAKDOWN
    # =========================================================================

    n_all_consistent = sum(
        1 for metrics in complete_samples.values()
        if len(set(m.detection_correct for m in metrics.values())) == 1
        and len(set(m.target_found for m in metrics.values())) == 1
    )

    n_partial = sum(
        1 for metrics in complete_samples.values()
        if len(set(m.detection_correct for m in metrics.values())) == 1
        and len(set(m.target_found for m in metrics.values())) > 1
    )

    n_inconsistent = n_complete - n_all_consistent - n_partial

    return CrossPromptMetrics(
        verdict_consistency=verdict_consistency,
        verdict_consistency_pairwise=verdict_consistency_pairwise,
        reasoning_consistency=reasoning_consistency,
        reasoning_consistency_pairwise={},  # TODO: implement if needed
        target_consistency=target_consistency,
        priming_effect=priming_effect,
        adversarial_resistance=adversarial_resistance,
        confidence_stability=confidence_stability,
        n_samples_all_consistent=n_all_consistent,
        n_samples_partial_consistent=n_partial,
        n_samples_inconsistent=n_inconsistent
    )
````

### 13.5 Full Evaluation Pipeline

```python
# src/judge/full_pipeline.py

from .evaluator import JudgeEvaluator
from .metrics import compute_sample_metrics
from .aggregator import compute_aggregated_metrics
from .cross_prompt import compute_cross_prompt_metrics
from .schemas import FullEvaluationReport, PromptType

class FullEvaluationPipeline:
    """
    Complete evaluation pipeline handling all 3 prompt types.
    """

    def __init__(self, judge_config: JudgeModelConfig):
        self.judge = MistralJudgeClient(judge_config)
        self.evaluator = JudgeEvaluator(self.judge)

    async def evaluate_model(
        self,
        model_id: str,
        samples: list[Sample],
        responses: dict[str, dict[PromptType, ModelResponse]]  # sample_id -> prompt_type -> response
    ) -> FullEvaluationReport:
        """
        Evaluate a model across all prompt types.

        Args:
            model_id: ID of model being evaluated
            samples: List of benchmark samples
            responses: Dict mapping sample_id -> {prompt_type: response}

        Returns:
            Complete evaluation report
        """

        all_judge_outputs = []
        all_sample_metrics = []
        total_cost = 0.0

        # Evaluate each sample for each prompt type
        for sample in samples:
            sample_responses = responses.get(sample.id, {})

            for prompt_type in PromptType:
                if prompt_type not in sample_responses:
                    continue

                response = sample_responses[prompt_type]

                # Build judge input
                judge_input = JudgeInput(
                    sample_id=sample.id,
                    code=sample.code,
                    language=sample.language,
                    ground_truth=sample.ground_truth,
                    model_response=response,
                    prompt_type=prompt_type
                )

                # Evaluate
                judge_output = await self.evaluator.evaluate(judge_input)
                all_judge_outputs.append(judge_output)

                # Compute sample metrics
                sample_metric = compute_sample_metrics(judge_output, sample.ground_truth)
                sample_metric.prompt_type = prompt_type
                all_sample_metrics.append(sample_metric)

                # Track cost
                total_cost += self._compute_judge_cost(judge_output)

        # Aggregate by prompt type
        by_prompt_type = {}
        for prompt_type in PromptType:
            pt_metrics = [m for m in all_sample_metrics if m.prompt_type == prompt_type]
            if pt_metrics:
                pt_gts = [s.ground_truth for s in samples]  # Simplified
                by_prompt_type[prompt_type.value] = compute_aggregated_metrics(pt_metrics, pt_gts)

        # Compute overall (all prompt types combined)
        overall = compute_aggregated_metrics(
            all_sample_metrics,
            [s.ground_truth for s in samples] * 3  # Each sample appears 3 times
        )

        # Compute cross-prompt metrics
        cross_prompt = compute_cross_prompt_metrics(all_sample_metrics)

        return FullEvaluationReport(
            model_id=model_id,
            evaluation_timestamp=datetime.now().isoformat(),
            judge_model=self.judge.config.model_id,
            total_judge_cost=total_cost,
            overall=overall,
            by_prompt_type=by_prompt_type,
            cross_prompt=cross_prompt
        )
```

### 13.6 Example Cross-Prompt Output

```json
{
  "cross_prompt": {
    "verdict_consistency": 0.72,
    "verdict_consistency_pairwise": {
      "direct_vs_naturalistic": 0.81,
      "direct_vs_adversarial": 0.76,
      "naturalistic_vs_adversarial": 0.84
    },

    "reasoning_consistency": 0.58,
    "target_consistency": 0.54,

    "priming_effect": {
      "accuracy": 0.17,
      "target_detection": 0.12,
      "rcir": 0.05
    },

    "adversarial_resistance": {
      "accuracy_drop": 0.08,
      "natural_accuracy": 0.72,
      "adversarial_accuracy": 0.64
    },

    "confidence_stability": {
      "mean_variance": 0.023,
      "max_variance": 0.15
    },

    "n_samples_all_consistent": 180,
    "n_samples_partial_consistent": 95,
    "n_samples_inconsistent": 225
  }
}
```

### 13.7 Research Insights from Cross-Prompt Metrics

| Metric                         | What It Reveals                                                          |
| ------------------------------ | ------------------------------------------------------------------------ |
| **Priming Effect > 0.15**      | Model relies heavily on prompt hints; may not understand vulnerabilities |
| **Verdict Consistency < 0.7**  | Inconsistent detection; surface-level pattern matching                   |
| **Target Consistency < 0.5**   | Even when verdict is right, reasoning varies wildly                      |
| **Adversarial Resistance < 0** | Model fooled by misleading context; poor robustness                      |
| **Confidence Variance > 0.1**  | Confidence is arbitrary, not calibrated to actual understanding          |

---

## 14. Implementation Checklist

### Phase 1: Core Judge (Days 1-2)

- [ ] Implement `JudgeModelConfig` schema
- [ ] Implement `BaseJudgeClient` interface
- [ ] Implement `MistralJudgeClient` for Vertex AI
- [ ] Test judge with single sample

### Phase 2: Schemas & Prompts (Day 3)

- [ ] Implement all input/output schemas (including `PromptType`, `DirectModelResponse`)
- [ ] Implement judge prompt templates (full + reasoning-only)
- [ ] Test prompt generation for both paths

### Phase 3: Dual-Path Evaluation (Day 4)

- [ ] Implement `JudgeEvaluator` with prompt type routing
- [ ] Implement JSON parsing for direct responses
- [ ] Implement rule-based type matching for direct responses
- [ ] Implement reasoning-only judge prompt
- [ ] Test dual-path evaluation

### Phase 4: Metrics (Days 5-6)

- [ ] Implement `compute_sample_metrics()`
- [ ] Implement `compute_aggregated_metrics()`
- [ ] Implement calibration metrics
- [ ] Implement robustness metrics
- [ ] Implement `compute_cross_prompt_metrics()`
- [ ] Unit tests for all metric functions

### Phase 5: Pipeline (Day 7)

- [ ] Implement `JudgeRunner` with checkpoint support
- [ ] Implement `FullEvaluationPipeline`
- [ ] Implement report generation (per-prompt + cross-prompt)
- [ ] CLI interface

### Phase 6: Testing & Validation (Day 8)

- [ ] Create gold-standard test cases (all 3 prompt types)
- [ ] Validate judge accuracy on each prompt type
- [ ] Validate cross-prompt metrics computation
- [ ] End-to-end integration test
- [ ] Documentation

---

**End of Specification v1.1**

### Changelog

**v1.1** (Current)

- Added multi-prompt evaluation support (direct, naturalistic, adversarial)
- Added dual-path evaluation: JSON parsing for direct, LLM extraction for free-form
- Added `CrossPromptMetrics` schema
- Added `FullEvaluationReport` schema
- Added reasoning-only judge prompt for direct responses
- Updated architecture diagram
- Added Section 13: Multi-Prompt Evaluation
- Updated implementation checklist

**v1.0** (Initial)

- Core judge system specification
- Single-path evaluation (free-form only)
- Basic metrics and aggregation
