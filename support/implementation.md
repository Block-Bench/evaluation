# Smart Contract Vulnerability Detection Benchmark

## Evaluation Pipeline Implementation Specification

**Version:** 1.0  
**Purpose:** Complete technical specification for implementing the evaluation pipeline  
**Target:** Coding agent / developer implementation

---

## 1. Project Overview

### 1.1 Goal

Build a modular, extensible evaluation pipeline to benchmark AI models on smart contract vulnerability detection. The pipeline must:

- Evaluate multiple models against a standardized dataset
- Calculate 32+ metrics across detection accuracy, robustness, reasoning quality, and calibration
- Support multiple evaluation task types (binary classification → full analysis)
- Generate publication-ready results for NeurIPS submission

### 1.2 Core Requirements

- **Model-agnostic**: Any LLM can be plugged in via configuration
- **Reproducible**: Deterministic where possible, seeded randomness where not
- **Cost-aware**: Track API costs, support sampling strategies
- **Fault-tolerant**: Resume from failures, retry logic, graceful degradation
- **Extensible**: Easy to add new metrics, models, or task types

---

## 2. Project Structure

```
smart-contract-eval/
├── config/
│   ├── default.yaml              # Default configuration
│   ├── models/                   # Model-specific configs
│   │   ├── claude-sonnet.yaml
│   │   ├── gpt-4o.yaml
│   │   └── deepseek-coder.yaml
│   └── experiments/              # Experiment presets
│       ├── pilot-50.yaml
│       └── full-eval.yaml
│
├── src/
│   ├── __init__.py
│   ├── data/
│   │   ├── __init__.py
│   │   ├── loader.py             # Dataset loading and filtering
│   │   ├── schema.py             # Pydantic models for data validation
│   │   └── sampler.py            # Stratified sampling utilities
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py               # Abstract base class for models
│   │   ├── registry.py           # Model registration and factory
│   │   ├── anthropic_client.py   # Claude implementation
│   │   ├── openai_client.py      # GPT implementation
│   │   ├── together_client.py    # Open source models via Together
│   │   ├── local_client.py       # Local models (ollama, vLLM)
│   │   └── mock_client.py        # Mock for testing
│   │
│   ├── prompts/
│   │   ├── __init__.py
│   │   ├── builder.py            # Prompt construction logic
│   │   ├── templates.py          # Prompt templates per task type
│   │   └── formats.py            # Output format specifications
│   │
│   ├── evaluation/
│   │   ├── __init__.py
│   │   ├── parser.py             # Response parsing and extraction
│   │   ├── comparator.py         # Ground truth comparison
│   │   ├── judge.py              # LLM-as-judge implementation
│   │   └── validator.py          # Response validation
│   │
│   ├── metrics/
│   │   ├── __init__.py
│   │   ├── detection.py          # Tier 1: Detection metrics
│   │   ├── robustness.py         # Tier 2: Robustness metrics
│   │   ├── reasoning.py          # Tier 3: Reasoning quality metrics
│   │   ├── calibration.py        # Tier 4: Calibration metrics
│   │   ├── composite.py          # Composite scores (SUI)
│   │   └── aggregator.py         # Slice-based aggregation
│   │
│   ├── pipeline/
│   │   ├── __init__.py
│   │   ├── runner.py             # Main evaluation orchestration
│   │   ├── batch.py              # Batch processing with concurrency
│   │   ├── checkpoint.py         # Checkpointing and resume
│   │   └── cost_tracker.py       # API cost tracking
│   │
│   └── reporting/
│       ├── __init__.py
│       ├── results_schema.py     # Results data structures
│       ├── exporter.py           # Export to JSON/CSV/LaTeX
│       └── visualizer.py         # Chart generation
│
├── scripts/
│   ├── run_eval.py               # Main CLI entry point
│   ├── analyze_results.py        # Post-hoc analysis
│   └── generate_report.py        # Generate paper tables/figures
│
├── tests/
│   ├── test_data_loader.py
│   ├── test_models.py
│   ├── test_metrics.py
│   └── fixtures/                 # Test data
│
├── results/                      # Evaluation outputs (gitignored)
│   └── {experiment_id}/
│       ├── config.yaml           # Frozen config for reproducibility
│       ├── raw_responses.jsonl   # All model responses
│       ├── evaluations.jsonl     # Parsed + scored responses
│       ├── metrics.json          # Aggregated metrics
│       └── checkpoints/          # Resume checkpoints
│
├── requirements.txt
├── pyproject.toml
└── README.md
```

---

## 3. Data Schema

### 3.1 Input Data Schema (Pydantic Models)

```python
# src/data/schema.py

from pydantic import BaseModel, Field
from typing import Optional, Literal
from enum import Enum

class Severity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFORMATIONAL = "informational"

class DifficultyTier(int, Enum):
    TIER_1_OBVIOUS = 1      # obvious_vulnerable
    TIER_2_CLEAR = 2        # clear_audit
    TIER_3_SUBTLE = 3       # subtle_expert
    TIER_4_ADVERSARIAL = 4  # adversarial_edge

class VulnerableLocation(BaseModel):
    contract_name: str
    function_name: Optional[str] = None
    line_numbers: Optional[list[int]] = None

class GroundTruth(BaseModel):
    is_vulnerable: bool
    vulnerability_type: Optional[str] = None  # e.g., "reentrancy", "overflow"
    severity: Optional[Severity] = None
    vulnerable_location: Optional[VulnerableLocation] = None
    root_cause: Optional[str] = None          # Why it's vulnerable
    attack_vector: Optional[str] = None       # How to exploit
    correct_fix: Optional[str] = None         # How to fix

class Difficulty(BaseModel):
    tier: DifficultyTier
    tier_name: str

class TemporalInfo(BaseModel):
    exploit_date: Optional[str] = None        # ISO date
    cutoff_status: Literal["pre_cutoff", "post_cutoff", "unknown"]
    known_exploit_name: Optional[str] = None  # e.g., "Euler Finance Hack"

class AdversarialInfo(BaseModel):
    group_id: str                             # Links related samples
    transformation_type: str                  # e.g., "chameleon_rename"
    is_original: bool
    original_id: Optional[str] = None         # Reference to original

class Sample(BaseModel):
    """Single evaluation sample"""
    id: str
    contract_file: str                        # Relative path to .sol file
    subset: Literal["gold_standard", "difficulty_stratified",
                    "temporal_contamination", "adversarial_contrastive"]
    ground_truth: GroundTruth
    difficulty: Optional[Difficulty] = None
    temporal: Optional[TemporalInfo] = None
    adversarial: Optional[AdversarialInfo] = None
    language: Literal["solidity", "rust", "move", "cairo"] = "solidity"

class Dataset(BaseModel):
    """Full dataset with index"""
    samples: list[Sample]
    metadata: dict  # Version, creation date, etc.
```

### 3.2 Contract Code Loading

```python
# src/data/loader.py

class DatasetLoader:
    def __init__(self, benchmark_root: Path):
        """
        benchmark_root: Path to benchmark/ directory containing:
          - gold_standard/
          - difficulty_stratified/
          - temporal_contamination/
          - adversarial_contrastive/
        """

    def load_subset(self, subset: str) -> list[Sample]:
        """Load all samples from a specific subset"""

    def load_all(self) -> Dataset:
        """Load entire benchmark dataset"""

    def load_contract_code(self, sample: Sample) -> str:
        """Read the actual contract source code for a sample"""

    def filter(
        self,
        samples: list[Sample],
        subset: Optional[str] = None,
        difficulty_tiers: Optional[list[int]] = None,
        vulnerability_types: Optional[list[str]] = None,
        languages: Optional[list[str]] = None,
        temporal_status: Optional[str] = None,
        is_vulnerable: Optional[bool] = None,
    ) -> list[Sample]:
        """Filter samples by various criteria"""

    def get_adversarial_groups(self, samples: list[Sample]) -> dict[str, list[Sample]]:
        """Group adversarial samples by group_id for paired analysis"""
```

---

## 4. Model Abstraction Layer

### 4.1 Base Model Interface

```python
# src/models/base.py

from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Optional

class ModelConfig(BaseModel):
    """Configuration for a model"""
    name: str                           # Display name
    provider: str                       # "anthropic", "openai", "together", "local"
    model_id: str                       # API model identifier
    api_key_env: Optional[str] = None   # Environment variable for API key
    base_url: Optional[str] = None      # Custom endpoint URL
    max_tokens: int = 4096
    temperature: float = 0.0            # Deterministic by default
    timeout: int = 120                  # Seconds
    max_retries: int = 3
    retry_delay: float = 1.0            # Seconds, exponential backoff
    cost_per_input_token: float = 0.0   # For cost tracking
    cost_per_output_token: float = 0.0
    supports_json_mode: bool = False    # Native JSON output
    supports_system_prompt: bool = True
    extra_params: dict = {}             # Provider-specific params

class ModelResponse(BaseModel):
    """Standardized response from any model"""
    content: str                        # Raw response text
    model_id: str
    input_tokens: int
    output_tokens: int
    latency_ms: float
    finish_reason: str                  # "stop", "length", "error"
    raw_response: Optional[dict] = None # Full API response for debugging

class BaseModelClient(ABC):
    """Abstract base class for all model implementations"""

    def __init__(self, config: ModelConfig):
        self.config = config

    @abstractmethod
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """Generate a response from the model"""
        pass

    @abstractmethod
    async def generate_batch(
        self,
        prompts: list[str],
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
        max_concurrency: int = 5,
    ) -> list[ModelResponse]:
        """Generate responses for multiple prompts with concurrency control"""
        pass

    def estimate_cost(self, response: ModelResponse) -> float:
        """Calculate cost for a response"""
        return (
            response.input_tokens * self.config.cost_per_input_token +
            response.output_tokens * self.config.cost_per_output_token
        )
```

### 4.2 Model Registry

```python
# src/models/registry.py

class ModelRegistry:
    """Factory for creating model clients from config"""

    _providers: dict[str, type[BaseModelClient]] = {}

    @classmethod
    def register(cls, provider: str):
        """Decorator to register a model client class"""
        def decorator(client_class: type[BaseModelClient]):
            cls._providers[provider] = client_class
            return client_class
        return decorator

    @classmethod
    def create(cls, config: ModelConfig) -> BaseModelClient:
        """Create a model client from configuration"""
        if config.provider not in cls._providers:
            raise ValueError(f"Unknown provider: {config.provider}")
        return cls._providers[config.provider](config)

    @classmethod
    def from_yaml(cls, config_path: Path) -> BaseModelClient:
        """Load model from YAML config file"""
        # Load YAML, create ModelConfig, return client
```

### 4.3 Example Model Implementation

```python
# src/models/anthropic_client.py

import anthropic
from .base import BaseModelClient, ModelConfig, ModelResponse
from .registry import ModelRegistry

@ModelRegistry.register("anthropic")
class AnthropicClient(BaseModelClient):

    def __init__(self, config: ModelConfig):
        super().__init__(config)
        api_key = os.environ.get(config.api_key_env or "ANTHROPIC_API_KEY")
        self.client = anthropic.AsyncAnthropic(api_key=api_key)

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        start_time = time.perf_counter()

        messages = [{"role": "user", "content": prompt}]

        # Add JSON instruction if needed (Anthropic doesn't have native JSON mode)
        if json_mode:
            prompt = prompt + "\n\nRespond with valid JSON only, no other text."

        response = await self.client.messages.create(
            model=self.config.model_id,
            max_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
            system=system_prompt or "",
            messages=messages,
            **self.config.extra_params
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        return ModelResponse(
            content=response.content[0].text,
            model_id=self.config.model_id,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            latency_ms=latency_ms,
            finish_reason=response.stop_reason,
            raw_response=response.model_dump()
        )
```

### 4.4 Model Configuration Files

```yaml
# config/models/claude-sonnet.yaml
name: 'Claude Sonnet 4'
provider: 'anthropic'
model_id: 'claude-sonnet-4-20250514'
api_key_env: 'ANTHROPIC_API_KEY'
max_tokens: 4096
temperature: 0.0
cost_per_input_token: 0.000003 # $3 per 1M input
cost_per_output_token: 0.000015 # $15 per 1M output
supports_json_mode: false
supports_system_prompt: true
```

```yaml
# config/models/gpt-4o.yaml
name: 'GPT-4o'
provider: 'openai'
model_id: 'gpt-4o'
api_key_env: 'OPENAI_API_KEY'
max_tokens: 4096
temperature: 0.0
cost_per_input_token: 0.0000025 # $2.50 per 1M input
cost_per_output_token: 0.00001 # $10 per 1M output
supports_json_mode: true
supports_system_prompt: true
```

```yaml
# config/models/deepseek-coder.yaml
name: 'DeepSeek Coder V2'
provider: 'together'
model_id: 'deepseek-ai/deepseek-coder-33b-instruct'
api_key_env: 'TOGETHER_API_KEY'
base_url: 'https://api.together.xyz/v1'
max_tokens: 4096
temperature: 0.0
cost_per_input_token: 0.0000008
cost_per_output_token: 0.0000008
supports_json_mode: false
supports_system_prompt: true
```

```yaml
# config/models/local-llama.yaml
name: 'Llama 3 70B (Local)'
provider: 'local'
model_id: 'llama3:70b'
base_url: 'http://localhost:11434' # Ollama endpoint
max_tokens: 4096
temperature: 0.0
cost_per_input_token: 0.0 # Free (local)
cost_per_output_token: 0.0
supports_json_mode: false
supports_system_prompt: true
```

---

## 5. Prompt System

### 5.1 Task Types

```python
# src/prompts/templates.py

from enum import Enum

class TaskType(str, Enum):
    BINARY = "binary"           # Task A: Yes/No vulnerable
    CLASSIFY = "classify"       # Task B: Vulnerable + type
    FULL_ANALYSIS = "analysis"  # Task C: Complete analysis
    VERIFICATION = "verify"     # Task D: Verify a claim
```

### 5.2 Prompt Templates

````python
# src/prompts/templates.py

SYSTEM_PROMPT = """You are an expert smart contract security auditor with deep knowledge of:
- Common vulnerability patterns (reentrancy, overflow, access control, etc.)
- Blockchain-specific attack vectors
- Secure coding practices for Solidity, Rust/Solana, Move, and Cairo

Your task is to analyze smart contracts for security vulnerabilities.
Be thorough but precise. Only report vulnerabilities you are confident exist.
{format_instruction}"""

TASK_TEMPLATES = {
    TaskType.BINARY: """Analyze the following smart contract and determine if it contains any security vulnerabilities.

```{language}
{contract_code}
````

Answer with a JSON object:
{{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>
}}""",

    TaskType.CLASSIFY: """Analyze the following smart contract for security vulnerabilities.

```{language}
{contract_code}
```

Answer with a JSON object:
{{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>,
  "vulnerability_type": "<type if vulnerable, else null>",
  "brief_explanation": "<1-2 sentence explanation>"
}}""",

    TaskType.FULL_ANALYSIS: """Perform a comprehensive security audit of the following smart contract.

```{language}
{contract_code}
```

Answer with a JSON object:
{{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>,
  "vulnerabilities": [
    {{
      "type": "<vulnerability type>",
      "severity": "critical" | "high" | "medium" | "low",
      "location": {{
        "contract_name": "<name>",
        "function_name": "<name or null>",
        "line_numbers": [<line numbers if identifiable>]
      }},
"root_cause": "<explanation of why this is vulnerable>",
"attack_vector": "<how an attacker could exploit this>",
"suggested_fix": "<how to remediate>"
}}
]
}}

If the contract is safe, return an empty vulnerabilities array.""",

    TaskType.VERIFICATION: """A security researcher has made the following claim about this smart contract:

CLAIM: "{claim}"

```{language}
{contract_code}
```

Evaluate this claim. Answer with a JSON object:
{{
  "agree": true | false,
  "confidence": <float 0.0-1.0>,
  "reasoning": "<detailed explanation of why you agree or disagree>"
}}"""
}

````

### 5.3 Prompt Builder

```python
# src/prompts/builder.py

class PromptBuilder:
    def __init__(self, task_type: TaskType):
        self.task_type = task_type

    def build(
        self,
        contract_code: str,
        language: str = "solidity",
        claim: Optional[str] = None,  # For verification task
        few_shot_examples: Optional[list[dict]] = None,
        chain_of_thought: bool = False,
    ) -> tuple[str, str]:
        """
        Returns (system_prompt, user_prompt)
        """
        # Get base template
        template = TASK_TEMPLATES[self.task_type]

        # Build format instruction
        format_instruction = "Respond with valid JSON only."
        if chain_of_thought:
            format_instruction = (
                "Think step by step, then provide your final answer as JSON. "
                "Wrap your reasoning in <thinking></thinking> tags, "
                "then provide the JSON response."
            )

        system = SYSTEM_PROMPT.format(format_instruction=format_instruction)

        # Build user prompt
        user = template.format(
            language=language,
            contract_code=contract_code,
            claim=claim or "",
        )

        # Add few-shot examples if provided
        if few_shot_examples:
            examples_text = self._format_examples(few_shot_examples)
            user = f"Here are some examples:\n\n{examples_text}\n\nNow analyze this contract:\n\n{user}"

        return system, user

    def _format_examples(self, examples: list[dict]) -> str:
        """Format few-shot examples"""
        formatted = []
        for i, ex in enumerate(examples, 1):
            formatted.append(f"Example {i}:\n```\n{ex['code']}\n```\nAnswer: {ex['answer']}")
        return "\n\n".join(formatted)
````

---

## 6. Response Parsing

### 6.1 Parsed Response Schema

```python
# src/evaluation/parser.py

from pydantic import BaseModel
from typing import Optional

class ParsedVulnerability(BaseModel):
    type: str
    severity: Optional[str] = None
    location: Optional[dict] = None
    root_cause: Optional[str] = None
    attack_vector: Optional[str] = None
    suggested_fix: Optional[str] = None

class ParsedResponse(BaseModel):
    """Standardized parsed response from any model"""
    verdict: Literal["vulnerable", "safe", "unknown"]
    confidence: float  # 0.0 to 1.0
    vulnerability_type: Optional[str] = None
    vulnerabilities: list[ParsedVulnerability] = []
    explanation: Optional[str] = None
    reasoning: Optional[str] = None  # Chain-of-thought if present

    # Parsing metadata
    parse_success: bool
    parse_errors: list[str] = []
    raw_content: str  # Original response for debugging
```

### 6.2 Response Parser

````python
# src/evaluation/parser.py

import json
import re

class ResponseParser:
    """Parse model responses into structured format"""

    def parse(self, response: ModelResponse, task_type: TaskType) -> ParsedResponse:
        """Parse a model response based on task type"""
        content = response.content
        errors = []

        # Extract JSON from response
        json_data, json_errors = self._extract_json(content)
        errors.extend(json_errors)

        if json_data is None:
            return ParsedResponse(
                verdict="unknown",
                confidence=0.0,
                parse_success=False,
                parse_errors=errors,
                raw_content=content
            )

        # Extract chain-of-thought reasoning if present
        reasoning = self._extract_reasoning(content)

        # Parse based on task type
        try:
            return self._parse_json_response(json_data, task_type, reasoning, content)
        except Exception as e:
            errors.append(f"Parse error: {str(e)}")
            return ParsedResponse(
                verdict="unknown",
                confidence=0.0,
                parse_success=False,
                parse_errors=errors,
                raw_content=content
            )

    def _extract_json(self, content: str) -> tuple[Optional[dict], list[str]]:
        """Extract JSON from response, handling various formats"""
        errors = []

        # Try direct parse
        try:
            return json.loads(content), []
        except json.JSONDecodeError:
            pass

        # Try extracting from markdown code block
        json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
        if json_match:
            try:
                return json.loads(json_match.group(1)), []
            except json.JSONDecodeError as e:
                errors.append(f"JSON in code block invalid: {e}")

        # Try finding JSON object in text
        brace_match = re.search(r'\{[\s\S]*\}', content)
        if brace_match:
            try:
                return json.loads(brace_match.group()), []
            except json.JSONDecodeError as e:
                errors.append(f"Extracted JSON invalid: {e}")

        errors.append("No valid JSON found in response")
        return None, errors

    def _extract_reasoning(self, content: str) -> Optional[str]:
        """Extract chain-of-thought reasoning from <thinking> tags"""
        match = re.search(r'<thinking>([\s\S]*?)</thinking>', content)
        return match.group(1).strip() if match else None

    def _parse_json_response(
        self,
        data: dict,
        task_type: TaskType,
        reasoning: Optional[str],
        raw_content: str
    ) -> ParsedResponse:
        """Parse validated JSON into ParsedResponse"""
        # Normalize verdict
        verdict = data.get("verdict", "unknown").lower()
        if verdict not in ["vulnerable", "safe"]:
            verdict = "unknown"

        # Extract confidence
        confidence = float(data.get("confidence", 0.5))
        confidence = max(0.0, min(1.0, confidence))  # Clamp to [0, 1]

        # Extract vulnerabilities for full analysis
        vulnerabilities = []
        if "vulnerabilities" in data:
            for v in data["vulnerabilities"]:
                vulnerabilities.append(ParsedVulnerability(
                    type=v.get("type", "unknown"),
                    severity=v.get("severity"),
                    location=v.get("location"),
                    root_cause=v.get("root_cause"),
                    attack_vector=v.get("attack_vector"),
                    suggested_fix=v.get("suggested_fix")
                ))

        return ParsedResponse(
            verdict=verdict,
            confidence=confidence,
            vulnerability_type=data.get("vulnerability_type"),
            vulnerabilities=vulnerabilities,
            explanation=data.get("brief_explanation") or data.get("reasoning"),
            reasoning=reasoning,
            parse_success=True,
            parse_errors=[],
            raw_content=raw_content
        )
````

---

## 7. Metrics Implementation

### 7.1 Tier 1: Detection Metrics

```python
# src/metrics/detection.py

from dataclasses import dataclass
import numpy as np
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    f1_score, fbeta_score, confusion_matrix
)

@dataclass
class DetectionMetrics:
    accuracy: float
    precision: float
    recall: float
    f1: float
    f2: float  # Security-weighted (favors recall)
    true_positives: int
    true_negatives: int
    false_positives: int
    false_negatives: int

def calculate_detection_metrics(
    y_true: list[bool],  # Ground truth: is_vulnerable
    y_pred: list[bool],  # Predictions: verdict == "vulnerable"
) -> DetectionMetrics:
    """Calculate Tier 1 detection metrics"""

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)

    cm = confusion_matrix(y_true, y_pred, labels=[False, True])
    tn, fp, fn, tp = cm.ravel()

    return DetectionMetrics(
        accuracy=accuracy_score(y_true, y_pred),
        precision=precision_score(y_true, y_pred, zero_division=0),
        recall=recall_score(y_true, y_pred, zero_division=0),
        f1=f1_score(y_true, y_pred, zero_division=0),
        f2=fbeta_score(y_true, y_pred, beta=2, zero_division=0),
        true_positives=int(tp),
        true_negatives=int(tn),
        false_positives=int(fp),
        false_negatives=int(fn),
    )
```

### 7.2 Tier 2: Robustness Metrics

```python
# src/metrics/robustness.py

@dataclass
class RobustnessMetrics:
    # Pattern Independence Score (PIS)
    pis: float  # 1 - (accuracy_drop after renaming)
    pis_details: dict  # Per-transformation breakdown

    # Temporal Generalization Gap (TGG)
    tgg: float  # pre_cutoff_accuracy - post_cutoff_accuracy
    pre_cutoff_accuracy: float
    post_cutoff_accuracy: float

    # Decoy Discrimination Rate (DDR)
    ddr: float  # Accuracy on samples with protection patterns

    # Adversarial Consistency Score (ACS)
    acs: float  # Agreement rate across adversarial variants

def calculate_pis(
    original_results: list[EvaluationResult],
    transformed_results: dict[str, list[EvaluationResult]],  # transform_type -> results
) -> tuple[float, dict]:
    """
    Pattern Independence Score:
    Measures how much accuracy drops when surface patterns change.
    PIS = 1 means fully robust, PIS = 0 means completely pattern-dependent.
    """
    original_acc = calculate_accuracy(original_results)

    pis_details = {}
    drops = []

    for transform_type, results in transformed_results.items():
        transformed_acc = calculate_accuracy(results)
        drop = original_acc - transformed_acc
        drops.append(drop)
        pis_details[transform_type] = {
            "original_accuracy": original_acc,
            "transformed_accuracy": transformed_acc,
            "drop": drop
        }

    # PIS = 1 - average drop (clamped to [0, 1])
    avg_drop = np.mean(drops) if drops else 0
    pis = max(0.0, min(1.0, 1.0 - avg_drop))

    return pis, pis_details

def calculate_tgg(
    pre_cutoff_results: list[EvaluationResult],
    post_cutoff_results: list[EvaluationResult],
) -> tuple[float, float, float]:
    """
    Temporal Generalization Gap:
    Measures memorization by comparing pre vs post cutoff performance.
    Large positive gap suggests memorization.
    """
    pre_acc = calculate_accuracy(pre_cutoff_results)
    post_acc = calculate_accuracy(post_cutoff_results)
    tgg = pre_acc - post_acc
    return tgg, pre_acc, post_acc

def calculate_acs(
    adversarial_groups: dict[str, list[EvaluationResult]],  # group_id -> results
) -> float:
    """
    Adversarial Consistency Score:
    Measures if model gives consistent verdicts across variants of same vulnerability.
    """
    consistencies = []

    for group_id, results in adversarial_groups.items():
        verdicts = [r.parsed.verdict for r in results]
        # Check if all verdicts agree
        if len(set(verdicts)) == 1:
            consistencies.append(1.0)
        else:
            # Partial credit: majority agreement
            majority = max(set(verdicts), key=verdicts.count)
            consistencies.append(verdicts.count(majority) / len(verdicts))

    return np.mean(consistencies) if consistencies else 0.0
```

### 7.3 Tier 3: Reasoning Quality Metrics

```python
# src/metrics/reasoning.py

@dataclass
class ReasoningMetrics:
    # Root Cause Identification Rate (RCIR)
    rcir: float  # Did explanation identify actual root cause?

    # Attack Vector Accuracy (AVA)
    ava: float  # Is described attack vector valid?

    # Fix Suggestion Validity (FSV)
    fsv: float  # Would suggested fix actually work?

    # Hallucination Rate (HR)
    hr: float  # Mentions non-existent code features?

    # Location Accuracy (LA)
    la: float  # Correct function/line identification

    # Type Accuracy (TA)
    ta: float  # Correct vulnerability type

def calculate_type_accuracy(
    results: list[EvaluationResult],
) -> float:
    """
    Type Accuracy:
    Among true positives, how often is vulnerability type correct?
    """
    correct = 0
    total = 0

    for r in results:
        # Only evaluate on true positives
        if r.ground_truth.is_vulnerable and r.parsed.verdict == "vulnerable":
            total += 1
            # Check if predicted type matches ground truth
            gt_type = r.ground_truth.vulnerability_type.lower() if r.ground_truth.vulnerability_type else None
            pred_type = r.parsed.vulnerability_type.lower() if r.parsed.vulnerability_type else None

            if gt_type and pred_type:
                # Allow partial matches (e.g., "reentrancy" matches "cross-function reentrancy")
                if gt_type in pred_type or pred_type in gt_type:
                    correct += 1

    return correct / total if total > 0 else 0.0

# Note: RCIR, AVA, FSV, HR require LLM-as-judge (see Section 8)
```

### 7.4 Tier 4: Calibration Metrics

```python
# src/metrics/calibration.py

import numpy as np

@dataclass
class CalibrationMetrics:
    ece: float  # Expected Calibration Error
    mce: float  # Maximum Calibration Error
    overconfidence_rate: float  # P(wrong | confidence > 0.8)
    underconfidence_rate: float  # P(correct | confidence < 0.5)
    brier_score: float

def calculate_ece(
    confidences: list[float],
    correctness: list[bool],
    n_bins: int = 10
) -> float:
    """
    Expected Calibration Error:
    Weighted average of |accuracy - confidence| per bin.
    Lower is better (0 = perfectly calibrated).
    """
    confidences = np.array(confidences)
    correctness = np.array(correctness).astype(float)

    bin_boundaries = np.linspace(0, 1, n_bins + 1)
    ece = 0.0

    for i in range(n_bins):
        in_bin = (confidences > bin_boundaries[i]) & (confidences <= bin_boundaries[i + 1])
        prop_in_bin = in_bin.mean()

        if prop_in_bin > 0:
            avg_confidence = confidences[in_bin].mean()
            avg_accuracy = correctness[in_bin].mean()
            ece += prop_in_bin * abs(avg_accuracy - avg_confidence)

    return ece

def calculate_overconfidence_rate(
    confidences: list[float],
    correctness: list[bool],
    threshold: float = 0.8
) -> float:
    """
    Overconfidence Rate:
    P(incorrect | confidence > threshold)
    """
    high_conf_mask = np.array(confidences) > threshold
    if not high_conf_mask.any():
        return 0.0

    high_conf_correct = np.array(correctness)[high_conf_mask]
    return 1.0 - high_conf_correct.mean()
```

### 7.5 Composite Score

```python
# src/metrics/composite.py

@dataclass
class CompositeMetrics:
    sui: float  # Security Understanding Index
    component_weights: dict[str, float]
    component_scores: dict[str, float]

def calculate_sui(
    detection: DetectionMetrics,
    robustness: RobustnessMetrics,
    reasoning: ReasoningMetrics,
    calibration: CalibrationMetrics,
    weights: Optional[dict] = None
) -> CompositeMetrics:
    """
    Security Understanding Index (SUI):
    Weighted composite of all metric tiers.
    """
    default_weights = {
        "f2": 0.25,           # Detection (security-weighted)
        "pis": 0.15,          # Pattern independence
        "tgg_inv": 0.10,      # Temporal generalization (inverted: lower gap = better)
        "rcir": 0.15,         # Root cause identification
        "ta": 0.10,           # Type accuracy
        "ece_inv": 0.10,      # Calibration (inverted: lower ECE = better)
        "acs": 0.15,          # Adversarial consistency
    }
    weights = weights or default_weights

    # Normalize TGG and ECE (invert so higher = better)
    tgg_inv = max(0, 1 - abs(robustness.tgg))  # Penalize gap in either direction
    ece_inv = 1 - calibration.ece

    component_scores = {
        "f2": detection.f2,
        "pis": robustness.pis,
        "tgg_inv": tgg_inv,
        "rcir": reasoning.rcir,
        "ta": reasoning.ta,
        "ece_inv": ece_inv,
        "acs": robustness.acs,
    }

    sui = sum(weights[k] * component_scores[k] for k in weights)

    return CompositeMetrics(
        sui=sui,
        component_weights=weights,
        component_scores=component_scores
    )
```

### 7.6 Metrics Aggregator

```python
# src/metrics/aggregator.py

class MetricsAggregator:
    """Aggregate metrics across different slices"""

    def aggregate(
        self,
        results: list[EvaluationResult],
        slices: dict[str, Callable[[EvaluationResult], bool]]
    ) -> dict[str, dict]:
        """
        Calculate metrics for different data slices.

        Example slices:
        {
            "overall": lambda r: True,
            "tier_1": lambda r: r.sample.difficulty.tier == 1,
            "tier_2": lambda r: r.sample.difficulty.tier == 2,
            "reentrancy": lambda r: r.ground_truth.vulnerability_type == "reentrancy",
            "pre_cutoff": lambda r: r.sample.temporal.cutoff_status == "pre_cutoff",
            "solidity": lambda r: r.sample.language == "solidity",
        }
        """
        aggregated = {}

        for slice_name, filter_fn in slices.items():
            slice_results = [r for r in results if filter_fn(r)]
            if slice_results:
                aggregated[slice_name] = {
                    "n": len(slice_results),
                    "detection": calculate_detection_metrics(...),
                    # Add other metrics as appropriate
                }

        return aggregated
```

---

## 8. LLM-as-Judge

### 8.1 Judge Configuration

```python
# src/evaluation/judge.py

class JudgeConfig(BaseModel):
    model_config: ModelConfig  # Which model to use as judge
    metrics_to_judge: list[str]  # ["rcir", "ava", "fsv", "hr"]
    samples_per_evaluation: int = 1  # For consistency checking
    require_explanation: bool = True

JUDGE_PROMPTS = {
    "rcir": """You are evaluating an AI model's explanation of a smart contract vulnerability.

Ground Truth Root Cause: {ground_truth_root_cause}

Model's Explanation: {model_explanation}

Did the model correctly identify the root cause of the vulnerability?
Consider:
- Did it identify the core issue (not just symptoms)?
- Is the explanation technically accurate?
- Would a developer understand WHY the code is vulnerable?

Answer with JSON:
{{
  "score": <0.0-1.0>,
  "correct": <true/false>,
  "reasoning": "<explanation>"
}}""",

    "ava": """You are evaluating whether an AI model described a valid attack vector.

Contract Code:
```

{contract_code}

```

Ground Truth Attack Vector: {ground_truth_attack}

Model's Attack Vector: {model_attack}

Is the model's attack vector valid and exploitable?
Consider:
- Is the attack technically feasible?
- Would it actually exploit the vulnerability?
- Are the steps accurate?

Answer with JSON:
{{
  "score": <0.0-1.0>,
  "valid": <true/false>,
  "reasoning": "<explanation>"
}}""",

    "fsv": """You are evaluating whether an AI model's suggested fix would remediate a vulnerability.

Contract Code:
```

{contract_code}

```

Vulnerability Type: {vulnerability_type}
Ground Truth Fix: {ground_truth_fix}

Model's Suggested Fix: {model_fix}

Would the model's fix actually remediate the vulnerability?
Consider:
- Does it address the root cause?
- Does it introduce new vulnerabilities?
- Is it a reasonable/practical fix?

Answer with JSON:
{{
  "score": <0.0-1.0>,
  "effective": <true/false>,
  "reasoning": "<explanation>"
}}""",

    "hr": """You are checking if an AI model hallucinated code features in its analysis.

Contract Code:
```

{contract_code}

```

Model's Analysis: {model_analysis}

Did the model mention any functions, variables, or features that don't exist in the code?

Answer with JSON:
{{
  "hallucination_detected": <true/false>,
  "hallucinated_elements": ["<list of hallucinated items>"],
  "reasoning": "<explanation>"
}}"""
}
```

### 8.2 Judge Implementation

```python
# src/evaluation/judge.py

class LLMJudge:
    def __init__(self, config: JudgeConfig):
        self.config = config
        self.model = ModelRegistry.create(config.model_config)

    async def evaluate_reasoning(
        self,
        result: EvaluationResult,
        metric: str
    ) -> JudgeResult:
        """Evaluate a single reasoning metric using LLM judge"""

        if metric not in JUDGE_PROMPTS:
            raise ValueError(f"Unknown metric for judge: {metric}")

        # Build judge prompt
        prompt = JUDGE_PROMPTS[metric].format(
            ground_truth_root_cause=result.ground_truth.root_cause,
            ground_truth_attack=result.ground_truth.attack_vector,
            ground_truth_fix=result.ground_truth.correct_fix,
            model_explanation=result.parsed.explanation,
            model_attack=self._extract_attack_vector(result.parsed),
            model_fix=self._extract_fix(result.parsed),
            model_analysis=result.parsed.raw_content,
            contract_code=result.contract_code,
            vulnerability_type=result.ground_truth.vulnerability_type,
        )

        # Get judge response
        response = await self.model.generate(prompt, json_mode=True)

        # Parse judge response
        return self._parse_judge_response(response, metric)

    async def evaluate_batch(
        self,
        results: list[EvaluationResult],
        metrics: list[str]
    ) -> dict[str, list[JudgeResult]]:
        """Evaluate multiple results across multiple metrics"""
        # Implementation with concurrency control
```

---

## 9. Pipeline Orchestration

### 9.1 Experiment Configuration

```yaml
# config/experiments/pilot-50.yaml
name: 'pilot_50_samples'
description: 'Initial pilot evaluation with 50 samples'

dataset:
  subsets: ['difficulty_stratified']
  sample_size: 50
  stratify_by: ['difficulty.tier'] # Ensure representation across tiers
  seed: 42

models:
  - config/models/claude-sonnet.yaml
  - config/models/gpt-4o.yaml
  - config/models/deepseek-coder.yaml

evaluation:
  task_type: 'classify' # Task B
  few_shot: false
  chain_of_thought: false

  judge:
    enabled: true
    model: config/models/claude-sonnet.yaml
    metrics: ['rcir', 'ta'] # Subset for pilot
    sample_rate: 1.0 # Judge all samples

execution:
  max_concurrency: 5
  timeout_seconds: 120
  checkpoint_every: 10

output:
  directory: 'results/pilot_50'
  save_raw_responses: true
  save_parsed: true
```

### 9.2 Pipeline Runner

```python
# src/pipeline/runner.py

class EvaluationPipeline:
    def __init__(self, config_path: Path):
        self.config = self._load_config(config_path)
        self.data_loader = DatasetLoader(self.config.dataset.root)
        self.models = self._load_models()
        self.prompt_builder = PromptBuilder(self.config.evaluation.task_type)
        self.parser = ResponseParser()
        self.judge = LLMJudge(self.config.judge) if self.config.judge.enabled else None
        self.checkpoint_manager = CheckpointManager(self.config.output.directory)
        self.cost_tracker = CostTracker()

    async def run(self) -> EvaluationReport:
        """Run full evaluation pipeline"""

        # 1. Load and sample data
        samples = self._load_samples()
        logger.info(f"Loaded {len(samples)} samples")

        # 2. Check for existing checkpoint
        completed = self.checkpoint_manager.load()
        samples = [s for s in samples if s.id not in completed]
        logger.info(f"Resuming with {len(samples)} remaining samples")

        # 3. Run evaluation for each model
        all_results = {}
        for model_name, model in self.models.items():
            logger.info(f"Evaluating {model_name}")
            results = await self._evaluate_model(model, samples)
            all_results[model_name] = results

        # 4. Run LLM-as-judge if enabled
        if self.judge:
            logger.info("Running LLM-as-judge evaluation")
            for model_name, results in all_results.items():
                await self._run_judge(results)

        # 5. Calculate metrics
        metrics = self._calculate_all_metrics(all_results)

        # 6. Generate report
        report = self._generate_report(all_results, metrics)

        # 7. Save outputs
        self._save_results(all_results, metrics, report)

        return report

    async def _evaluate_model(
        self,
        model: BaseModelClient,
        samples: list[Sample]
    ) -> list[EvaluationResult]:
        """Evaluate a single model on all samples"""

        results = []

        # Process in batches with concurrency
        for batch in self._batch(samples, self.config.execution.batch_size):
            batch_results = await self._evaluate_batch(model, batch)
            results.extend(batch_results)

            # Checkpoint
            self.checkpoint_manager.save([r.sample.id for r in batch_results])

            # Log progress
            self.cost_tracker.log_batch(batch_results)
            logger.info(
                f"Progress: {len(results)}/{len(samples)} | "
                f"Cost: ${self.cost_tracker.total_cost:.2f}"
            )

        return results

    async def _evaluate_batch(
        self,
        model: BaseModelClient,
        samples: list[Sample]
    ) -> list[EvaluationResult]:
        """Evaluate a batch of samples with concurrency"""

        async def evaluate_single(sample: Sample) -> EvaluationResult:
            # Load contract code
            code = self.data_loader.load_contract_code(sample)

            # Build prompt
            system, user = self.prompt_builder.build(
                contract_code=code,
                language=sample.language,
                few_shot_examples=self.config.evaluation.few_shot_examples,
                chain_of_thought=self.config.evaluation.chain_of_thought,
            )

            # Get model response
            response = await model.generate(user, system_prompt=system, json_mode=True)

            # Parse response
            parsed = self.parser.parse(response, self.config.evaluation.task_type)

            return EvaluationResult(
                sample=sample,
                ground_truth=sample.ground_truth,
                contract_code=code,
                response=response,
                parsed=parsed,
                correct=self._check_correct(parsed, sample.ground_truth),
                cost=model.estimate_cost(response),
            )

        # Run with concurrency limit
        semaphore = asyncio.Semaphore(self.config.execution.max_concurrency)

        async def bounded_evaluate(sample):
            async with semaphore:
                return await evaluate_single(sample)

        return await asyncio.gather(*[bounded_evaluate(s) for s in samples])
```

### 9.3 Checkpoint Manager

```python
# src/pipeline/checkpoint.py

class CheckpointManager:
    """Manage evaluation checkpoints for resume capability"""

    def __init__(self, output_dir: Path):
        self.checkpoint_file = output_dir / "checkpoints" / "progress.json"
        self.checkpoint_file.parent.mkdir(parents=True, exist_ok=True)

    def save(self, completed_ids: list[str]):
        """Save completed sample IDs"""
        existing = self.load()
        existing.update(completed_ids)
        with open(self.checkpoint_file, 'w') as f:
            json.dump({"completed": list(existing), "timestamp": datetime.now().isoformat()}, f)

    def load(self) -> set[str]:
        """Load completed sample IDs"""
        if self.checkpoint_file.exists():
            with open(self.checkpoint_file) as f:
                data = json.load(f)
                return set(data.get("completed", []))
        return set()

    def clear(self):
        """Clear checkpoints for fresh run"""
        if self.checkpoint_file.exists():
            self.checkpoint_file.unlink()
```

---

## 10. Results Schema

### 10.1 Evaluation Result

```python
# src/reporting/results_schema.py

class EvaluationResult(BaseModel):
    """Single evaluation result"""
    sample_id: str
    model_id: str
    timestamp: datetime

    # Input
    sample: Sample
    contract_code: str
    prompt_used: str

    # Output
    response: ModelResponse
    parsed: ParsedResponse

    # Evaluation
    correct: bool  # Binary: did verdict match ground truth?
    type_correct: Optional[bool]  # Did vulnerability type match?

    # Judge scores (if applicable)
    judge_scores: Optional[dict[str, float]] = None  # metric -> score

    # Cost
    cost_usd: float
    latency_ms: float

class ModelResults(BaseModel):
    """All results for a single model"""
    model_id: str
    model_name: str
    results: list[EvaluationResult]
    metrics: dict  # Calculated metrics
    total_cost: float
    total_time_seconds: float

class ExperimentResults(BaseModel):
    """Complete experiment results"""
    experiment_id: str
    experiment_name: str
    config: dict  # Frozen config
    timestamp: datetime

    models: dict[str, ModelResults]

    # Cross-model comparisons
    comparison_metrics: dict
```

### 10.2 Output Files

```
results/{experiment_id}/
├── config.yaml                    # Frozen experiment config
├── raw_responses/
│   ├── claude-sonnet.jsonl        # Raw API responses
│   ├── gpt-4o.jsonl
│   └── deepseek-coder.jsonl
├── evaluations/
│   ├── claude-sonnet.jsonl        # Parsed + scored results
│   ├── gpt-4o.jsonl
│   └── deepseek-coder.jsonl
├── metrics/
│   ├── claude-sonnet.json         # Per-model metrics
│   ├── gpt-4o.json
│   ├── deepseek-coder.json
│   └── comparison.json            # Cross-model comparison
├── judge/
│   ├── rcir_scores.jsonl          # Judge evaluations
│   └── ava_scores.jsonl
├── report.md                      # Human-readable summary
└── tables/
    ├── main_results.csv           # For paper
    ├── per_tier.csv
    └── per_vuln_type.csv
```

---

## 11. CLI Interface

### 11.1 Main Entry Point

```python
# scripts/run_eval.py

import click
import asyncio

@click.group()
def cli():
    """Smart Contract Vulnerability Detection Benchmark"""
    pass

@cli.command()
@click.option('--config', '-c', required=True, help='Path to experiment config')
@click.option('--resume/--no-resume', default=True, help='Resume from checkpoint')
@click.option('--dry-run', is_flag=True, help='Show what would be evaluated')
def run(config: str, resume: bool, dry_run: bool):
    """Run an evaluation experiment"""
    pipeline = EvaluationPipeline(Path(config))

    if dry_run:
        pipeline.dry_run()
        return

    if not resume:
        pipeline.checkpoint_manager.clear()

    report = asyncio.run(pipeline.run())
    click.echo(f"Evaluation complete. Results saved to {pipeline.config.output.directory}")
    click.echo(f"Total cost: ${report.total_cost:.2f}")

@cli.command()
@click.option('--results', '-r', required=True, help='Path to results directory')
@click.option('--output', '-o', default='report.md', help='Output report path')
def report(results: str, output: str):
    """Generate report from results"""
    # Implementation

@cli.command()
@click.option('--results', '-r', required=True, help='Path to results directory')
@click.option('--format', '-f', type=click.Choice(['latex', 'csv', 'json']), default='latex')
def export(results: str, format: str):
    """Export results for paper"""
    # Implementation

@cli.command()
@click.option('--config', '-c', required=True, help='Path to experiment config')
def estimate_cost(config: str):
    """Estimate API costs before running"""
    pipeline = EvaluationPipeline(Path(config))
    estimate = pipeline.estimate_cost()
    click.echo(f"Estimated cost: ${estimate['total']:.2f}")
    for model, cost in estimate['per_model'].items():
        click.echo(f"  {model}: ${cost:.2f}")

if __name__ == '__main__':
    cli()
```

### 11.2 Usage Examples

```bash
# Run pilot evaluation
python scripts/run_eval.py run --config config/experiments/pilot-50.yaml

# Resume interrupted run
python scripts/run_eval.py run --config config/experiments/pilot-50.yaml --resume

# Estimate costs before running
python scripts/run_eval.py estimate-cost --config config/experiments/full-eval.yaml

# Generate report
python scripts/run_eval.py report --results results/pilot_50/ --output report.md

# Export for paper
python scripts/run_eval.py export --results results/pilot_50/ --format latex
```

---

## 12. Error Handling

### 12.1 Retry Logic

```python
# src/models/base.py

async def with_retry(
    func: Callable,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    retryable_exceptions: tuple = (RateLimitError, TimeoutError, APIConnectionError)
):
    """Exponential backoff retry wrapper"""
    last_exception = None

    for attempt in range(max_retries + 1):
        try:
            return await func()
        except retryable_exceptions as e:
            last_exception = e
            if attempt < max_retries:
                delay = min(base_delay * (2 ** attempt), max_delay)
                logger.warning(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay}s")
                await asyncio.sleep(delay)
            else:
                logger.error(f"All {max_retries + 1} attempts failed")
                raise

    raise last_exception
```

### 12.2 Graceful Degradation

```python
# src/pipeline/runner.py

async def _evaluate_single_safe(self, sample: Sample) -> EvaluationResult:
    """Evaluate with graceful error handling"""
    try:
        return await self._evaluate_single(sample)
    except Exception as e:
        logger.error(f"Failed to evaluate {sample.id}: {e}")
        return EvaluationResult(
            sample=sample,
            error=str(e),
            parsed=ParsedResponse(
                verdict="unknown",
                confidence=0.0,
                parse_success=False,
                parse_errors=[f"Evaluation failed: {e}"],
                raw_content=""
            )
        )
```

---

## 13. Testing Requirements

### 13.1 Unit Tests

````python
# tests/test_metrics.py

def test_detection_metrics_perfect():
    """Test detection metrics with perfect predictions"""
    y_true = [True, True, False, False]
    y_pred = [True, True, False, False]
    metrics = calculate_detection_metrics(y_true, y_pred)
    assert metrics.accuracy == 1.0
    assert metrics.f1 == 1.0

def test_ece_calibration():
    """Test ECE calculation"""
    # Perfectly calibrated
    confidences = [0.9, 0.9, 0.1, 0.1]
    correctness = [True, True, False, False]
    ece = calculate_ece(confidences, correctness)
    assert ece < 0.1  # Should be near 0

def test_parser_extracts_json():
    """Test JSON extraction from various formats"""
    parser = ResponseParser()

    # Direct JSON
    content = '{"verdict": "vulnerable", "confidence": 0.85}'
    result = parser._extract_json(content)
    assert result[0]["verdict"] == "vulnerable"

    # JSON in code block
    content = '```json\n{"verdict": "safe"}\n```'
    result = parser._extract_json(content)
    assert result[0]["verdict"] == "safe"
````

### 13.2 Integration Tests

```python
# tests/test_integration.py

@pytest.mark.integration
async def test_full_pipeline_mock():
    """Test full pipeline with mock model"""
    config = load_config("config/experiments/test.yaml")
    config.models = ["config/models/mock.yaml"]

    pipeline = EvaluationPipeline(config)
    report = await pipeline.run()

    assert len(report.models) == 1
    assert "mock" in report.models
    assert report.models["mock"].metrics["detection"]["accuracy"] > 0
```

---

## 14. Dependencies

```
# requirements.txt

# Core
python>=3.11
pydantic>=2.0
pyyaml>=6.0
click>=8.0

# Async
asyncio
aiohttp>=3.8
aiofiles>=23.0

# ML/Stats
numpy>=1.24
scikit-learn>=1.3
scipy>=1.11

# API Clients
anthropic>=0.25
openai>=1.0
together>=1.0
httpx>=0.25

# Data
pandas>=2.0
jsonlines>=4.0

# Visualization
matplotlib>=3.7
seaborn>=0.13

# Testing
pytest>=7.0
pytest-asyncio>=0.21

# Dev
black
ruff
mypy
```

---

## 15. Implementation Priorities

### Phase 1: Core Infrastructure (Days 1-2)

1. Data schema and loader
2. Model abstraction layer (Anthropic + OpenAI clients)
3. Prompt builder (Task B only)
4. Response parser
5. Basic detection metrics

### Phase 2: Pipeline (Days 3-4)

1. Pipeline runner with checkpointing
2. Cost tracking
3. CLI interface
4. Results export (JSON/CSV)

### Phase 3: Advanced Metrics (Days 5-6)

1. Robustness metrics (PIS, TGG, ACS)
2. LLM-as-judge implementation
3. Reasoning metrics
4. Calibration metrics
5. Composite SUI score

### Phase 4: Polish (Day 7)

1. Visualization/charts
2. LaTeX export for paper
3. Documentation
4. Test coverage

---

## 16. Open Questions for Implementer

1. **Concurrency limits**: What's the rate limit for each API? Adjust `max_concurrency` accordingly.

2. **Judge model**: Should the judge be a different model than those being evaluated? (Recommended: yes, to avoid self-evaluation bias)

3. **Sampling strategy**: For pilot, stratified by tier. For full eval, include all samples or cap per category?

4. **Reproducibility**: Store random seeds, model versions, exact prompts used?

5. **Human validation**: Plan for human review of judge scores? How many samples?

---

**End of Specification**
