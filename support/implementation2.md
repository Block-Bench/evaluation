# Smart Contract Vulnerability Detection Benchmark

## Evaluation Pipeline Implementation Specification v2

**Version:** 2.0  
**Updated:** December 2025  
**Target Models:** Claude Opus 4.5, Gemini 3 Pro, DeepSeek V3.2  
**Platform:** Google Cloud Vertex AI (unified)

---

## 1. Overview

### 1.1 Goal

Benchmark AI models on smart contract vulnerability detection using a unified Vertex AI infrastructure. This spec focuses on three Tier 1 frontier models to establish baseline performance before expanding to additional models.

### 1.2 Target Models

| Model               | Provider            | Vertex AI Model ID               | Type               |
| ------------------- | ------------------- | -------------------------------- | ------------------ |
| **Claude Opus 4.5** | Anthropic (Partner) | `claude-opus-4-5@20251101`       | Frontier reasoning |
| **Gemini 3 Pro**    | Google (Native)     | `gemini-3-pro`                   | Google's best      |
| **DeepSeek V3.2**   | DeepSeek (MaaS)     | `deepseek-ai/deepseek-v3.2-maas` | Open model SOTA    |

### 1.3 Why These Models

- **Claude Opus 4.5**: Industry leader for coding, agents, and complex reasoning
- **Gemini 3 Pro**: #1 on LMArena (1501 Elo), state-of-the-art across benchmarks
- **DeepSeek V3.2**: Best cost-performance ratio, strong reasoning, very cheap

---

## 2. Vertex AI Setup

### 2.1 Prerequisites

```bash
# 1. Install Google Cloud CLI
# https://cloud.google.com/sdk/docs/install

# 2. Authenticate
gcloud auth application-default login

# 3. Set project
gcloud config set project YOUR_PROJECT_ID

# 4. Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com
```

### 2.2 Enable Partner Models

Each partner model must be enabled in Model Garden before use:

| Model           | Enable Link                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------- |
| Claude Opus 4.5 | https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-opus-4-5      |
| DeepSeek V3.2   | https://console.cloud.google.com/vertex-ai/publishers/deepseek-ai/model-garden/deepseek-v3.2-maas |

Gemini 3 Pro is native to Google Cloud and doesn't require separate enablement.

### 2.3 Region Availability

| Model           | Recommended Region | Alternatives                      |
| --------------- | ------------------ | --------------------------------- |
| Claude Opus 4.5 | `us-east5`         | `europe-west1`                    |
| Gemini 3 Pro    | `us-central1`      | `europe-west4`, `asia-northeast1` |
| DeepSeek V3.2   | `us-central1`      | —                                 |

### 2.4 Required Python Packages

```bash
pip install google-cloud-aiplatform anthropic[vertex] openai pydantic pyyaml aiohttp
```

---

## 3. Project Structure

```
smart-contract-eval/
├── config/
│   ├── default.yaml              # Default configuration
│   └── models/                   # Model-specific configs
│       ├── claude-opus-4-5.yaml
│       ├── gemini-3-pro.yaml
│       └── deepseek-v3-2.yaml
│
├── src/
│   ├── __init__.py
│   ├── data/
│   │   ├── loader.py             # Dataset loading
│   │   └── schema.py             # Pydantic models
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py               # Abstract base class
│   │   ├── registry.py           # Model registration
│   │   ├── vertex_claude.py      # Claude via Vertex AI
│   │   ├── vertex_gemini.py      # Gemini native
│   │   └── vertex_deepseek.py    # DeepSeek via Vertex AI
│   │
│   ├── prompts/
│   │   ├── builder.py            # Prompt construction
│   │   └── templates.py          # Task templates
│   │
│   ├── evaluation/
│   │   ├── parser.py             # Response parsing
│   │   └── judge.py              # LLM-as-judge
│   │
│   ├── metrics/
│   │   ├── detection.py          # Tier 1 metrics
│   │   ├── robustness.py         # Tier 2 metrics
│   │   ├── reasoning.py          # Tier 3 metrics
│   │   └── calibration.py        # Tier 4 metrics
│   │
│   └── pipeline/
│       ├── runner.py             # Main orchestration
│       ├── checkpoint.py         # Resume capability
│       └── cost_tracker.py       # API cost tracking
│
├── scripts/
│   └── run_eval.py               # CLI entry point
│
├── results/                      # Outputs (gitignored)
└── requirements.txt
```

---

## 4. Model Configuration

### 4.1 Configuration Schema

```python
# src/models/base.py

from pydantic import BaseModel
from typing import Optional, Literal

class VertexModelConfig(BaseModel):
    """Configuration for a Vertex AI model"""
    name: str                           # Display name
    provider: Literal["anthropic", "google", "deepseek"]
    model_id: str                       # Vertex AI model identifier
    region: str                         # GCP region
    project_id: Optional[str] = None    # Uses default if not specified

    # Generation parameters
    max_tokens: int = 4096
    temperature: float = 0.0            # Deterministic
    timeout: int = 180                  # Seconds (longer for complex analysis)

    # Retry configuration
    max_retries: int = 3
    retry_delay: float = 2.0            # Base delay for exponential backoff

    # Cost tracking (per 1M tokens)
    cost_per_input_token: float
    cost_per_output_token: float

    # Provider-specific
    supports_json_mode: bool = False
    extra_params: dict = {}
```

### 4.2 Claude Opus 4.5 Configuration

```yaml
# config/models/claude-opus-4-5.yaml
name: 'Claude Opus 4.5'
provider: 'anthropic'
model_id: 'claude-opus-4-5@20251101'
region: 'us-east5'

max_tokens: 4096
temperature: 0.0
timeout: 180

# Pricing: $15/1M input, $75/1M output
cost_per_input_token: 0.000015
cost_per_output_token: 0.000075

supports_json_mode: false
extra_params: {}
```

### 4.3 Gemini 3 Pro Configuration

```yaml
# config/models/gemini-3-pro.yaml
name: 'Gemini 3 Pro'
provider: 'google'
model_id: 'gemini-3-pro'
region: 'us-central1'

max_tokens: 4096
temperature: 0.0
timeout: 120

# Pricing: $2/1M input, $12/1M output (estimated)
cost_per_input_token: 0.000002
cost_per_output_token: 0.000012

supports_json_mode: true
extra_params:
  safety_settings: 'BLOCK_NONE' # For security research
```

### 4.4 DeepSeek V3.2 Configuration

```yaml
# config/models/deepseek-v3-2.yaml
name: 'DeepSeek V3.2'
provider: 'deepseek'
model_id: 'deepseek-ai/deepseek-v3.2-maas'
region: 'us-central1'

max_tokens: 4096
temperature: 0.0
timeout: 120

# Pricing: ~$0.14/1M input, $0.28/1M output (very cheap!)
cost_per_input_token: 0.00000014
cost_per_output_token: 0.00000028

supports_json_mode: false
extra_params: {}
```

---

## 5. Model Client Implementations

### 5.1 Base Model Interface

```python
# src/models/base.py

from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Optional
import time

class ModelResponse(BaseModel):
    """Standardized response from any model"""
    content: str
    model_id: str
    input_tokens: int
    output_tokens: int
    latency_ms: float
    finish_reason: str
    raw_response: Optional[dict] = None

class BaseModelClient(ABC):
    """Abstract base class for Vertex AI model clients"""

    def __init__(self, config: VertexModelConfig):
        self.config = config
        self._setup_client()

    @abstractmethod
    def _setup_client(self):
        """Initialize the provider-specific client"""
        pass

    @abstractmethod
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        """Generate a response"""
        pass

    def estimate_cost(self, response: ModelResponse) -> float:
        """Calculate cost for a response"""
        return (
            response.input_tokens * self.config.cost_per_input_token +
            response.output_tokens * self.config.cost_per_output_token
        )
```

### 5.2 Claude Opus 4.5 Client (Vertex AI)

```python
# src/models/vertex_claude.py

from anthropic import AnthropicVertex
from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry
import time
import os

@ModelRegistry.register("anthropic")
class VertexClaudeClient(BaseModelClient):
    """Claude models via Vertex AI"""

    def _setup_client(self):
        self.client = AnthropicVertex(
            project_id=self.config.project_id or os.environ.get("GOOGLE_CLOUD_PROJECT"),
            region=self.config.region,
        )

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        start_time = time.perf_counter()

        # Claude doesn't have native JSON mode, add instruction
        if json_mode:
            prompt = prompt + "\n\nRespond with valid JSON only, no other text."

        messages = [{"role": "user", "content": prompt}]

        response = await self.client.messages.create(
            model=self.config.model_id,
            max_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
            system=system_prompt or "",
            messages=messages,
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

### 5.3 Gemini 3 Pro Client (Native)

```python
# src/models/vertex_gemini.py

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig
from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry
import time
import os

@ModelRegistry.register("google")
class VertexGeminiClient(BaseModelClient):
    """Gemini models via Vertex AI (native)"""

    def _setup_client(self):
        vertexai.init(
            project=self.config.project_id or os.environ.get("GOOGLE_CLOUD_PROJECT"),
            location=self.config.region,
        )
        self.model = GenerativeModel(self.config.model_id)

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        start_time = time.perf_counter()

        # Build generation config
        gen_config = GenerationConfig(
            max_output_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
        )

        # Add JSON mode if supported
        if json_mode and self.config.supports_json_mode:
            gen_config.response_mime_type = "application/json"

        # Combine system prompt with user prompt
        full_prompt = prompt
        if system_prompt:
            full_prompt = f"{system_prompt}\n\n{prompt}"

        response = await self.model.generate_content_async(
            full_prompt,
            generation_config=gen_config,
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        # Extract token counts
        usage = response.usage_metadata

        return ModelResponse(
            content=response.text,
            model_id=self.config.model_id,
            input_tokens=usage.prompt_token_count,
            output_tokens=usage.candidates_token_count,
            latency_ms=latency_ms,
            finish_reason=response.candidates[0].finish_reason.name,
            raw_response={"text": response.text}
        )
```

### 5.4 DeepSeek V3.2 Client (Vertex AI MaaS)

```python
# src/models/vertex_deepseek.py

from openai import OpenAI
import google.auth
import google.auth.transport.requests
from .base import BaseModelClient, ModelResponse, VertexModelConfig
from .registry import ModelRegistry
import time
import os

@ModelRegistry.register("deepseek")
class VertexDeepSeekClient(BaseModelClient):
    """DeepSeek models via Vertex AI (OpenAI-compatible)"""

    def _setup_client(self):
        # Get access token from ADC
        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        project_id = self.config.project_id or project

        self.client = OpenAI(
            base_url=f"https://{self.config.region}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{self.config.region}/endpoints/openapi",
            api_key=credentials.token,
        )
        self._credentials = credentials

    def _refresh_token_if_needed(self):
        """Refresh access token if expired"""
        if self._credentials.expired:
            self._credentials.refresh(google.auth.transport.requests.Request())
            self.client.api_key = self._credentials.token

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
    ) -> ModelResponse:
        start_time = time.perf_counter()

        self._refresh_token_if_needed()

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        # DeepSeek doesn't have native JSON mode
        if json_mode:
            messages[-1]["content"] += "\n\nRespond with valid JSON only."

        response = self.client.chat.completions.create(
            model=self.config.model_id,
            messages=messages,
            max_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
        )

        latency_ms = (time.perf_counter() - start_time) * 1000

        return ModelResponse(
            content=response.choices[0].message.content,
            model_id=self.config.model_id,
            input_tokens=response.usage.prompt_tokens,
            output_tokens=response.usage.completion_tokens,
            latency_ms=latency_ms,
            finish_reason=response.choices[0].finish_reason,
            raw_response=response.model_dump()
        )
```

### 5.5 Model Registry

```python
# src/models/registry.py

from pathlib import Path
import yaml
from typing import Type
from .base import BaseModelClient, VertexModelConfig

class ModelRegistry:
    """Factory for creating model clients from config"""

    _providers: dict[str, Type[BaseModelClient]] = {}

    @classmethod
    def register(cls, provider: str):
        """Decorator to register a model client class"""
        def decorator(client_class: Type[BaseModelClient]):
            cls._providers[provider] = client_class
            return client_class
        return decorator

    @classmethod
    def create(cls, config: VertexModelConfig) -> BaseModelClient:
        """Create a model client from configuration"""
        if config.provider not in cls._providers:
            raise ValueError(f"Unknown provider: {config.provider}. "
                           f"Available: {list(cls._providers.keys())}")
        return cls._providers[config.provider](config)

    @classmethod
    def from_yaml(cls, config_path: Path) -> BaseModelClient:
        """Load model from YAML config file"""
        with open(config_path) as f:
            config_dict = yaml.safe_load(f)
        config = VertexModelConfig(**config_dict)
        return cls.create(config)

    @classmethod
    def load_all(cls, config_dir: Path) -> dict[str, BaseModelClient]:
        """Load all model configs from a directory"""
        models = {}
        for config_file in config_dir.glob("*.yaml"):
            client = cls.from_yaml(config_file)
            models[client.config.name] = client
        return models
```

---

## 6. Cost Estimation

### 6.1 Per-Model Costs (500 samples × ~3K tokens each)

| Model           | Input Cost | Output Cost | Total (est.) |
| --------------- | ---------- | ----------- | ------------ |
| Claude Opus 4.5 | \$22.50    | \$112.50    | **~\$135**   |
| Gemini 3 Pro    | \$3.00     | \$18.00     | **~\$21**    |
| DeepSeek V3.2   | \$0.21     | \$0.42      | **~\$0.63**  |

**Total for 3 models:** ~\$157 for full 500-sample run

### 6.2 Recommended Evaluation Strategy

**Phase 1: Pilot (50 samples)**

- Run all 3 models
- Estimated cost: ~\$16
- Validate pipeline, check response quality

**Phase 2: Full Evaluation (500 samples)**

- DeepSeek V3.2: Full run (~\$0.63) ✓
- Gemini 3 Pro: Full run (~\$21) ✓
- Claude Opus 4.5: Subset (100-200 hard samples) to manage cost

**Phase 3: Expand (if budget allows)**

- Add Claude Sonnet 4.5 (~\$12 for full run)
- Add code-specialized models (Codestral 2, Qwen3 Coder)

---

## 7. Experiment Configuration

### 7.1 Pilot Experiment

```yaml
# config/experiments/pilot-50-vertex.yaml
name: 'pilot_vertex_ai_50'
description: 'Pilot evaluation with Tier 1 models on Vertex AI'

dataset:
  root: 'benchmark/'
  subsets: ['difficulty_stratified']
  sample_size: 50
  stratify_by: ['difficulty.tier']
  seed: 42

models:
  - config/models/claude-opus-4-5.yaml
  - config/models/gemini-3-pro.yaml
  - config/models/deepseek-v3-2.yaml

evaluation:
  task_type: 'classify' # Task B: verdict + type
  few_shot: false
  chain_of_thought: false

  judge:
    enabled: true
    model: config/models/gemini-3-pro.yaml # Use Gemini as judge (cost-effective)
    metrics: ['rcir', 'ta']
    sample_rate: 1.0

execution:
  max_concurrency: 3 # Conservative for Vertex AI
  timeout_seconds: 180
  checkpoint_every: 10

output:
  directory: 'results/pilot_vertex_50'
  save_raw_responses: true
  save_parsed: true
```

### 7.2 Full Evaluation

```yaml
# config/experiments/full-eval-vertex.yaml
name: 'full_vertex_ai_eval'
description: 'Full benchmark evaluation'

dataset:
  root: 'benchmark/'
  subsets:
    [
      'difficulty_stratified',
      'temporal_contamination',
      'adversarial_contrastive',
    ]
  sample_size: null # Use all samples
  seed: 42

models:
  - config/models/gemini-3-pro.yaml # Full run
  - config/models/deepseek-v3-2.yaml # Full run
  # Claude Opus 4.5: Run separately on hard samples only

evaluation:
  task_type: 'classify'
  few_shot: false
  chain_of_thought: false

  judge:
    enabled: true
    model: config/models/gemini-3-pro.yaml
    metrics: ['rcir', 'ava', 'fsv', 'hr', 'ta']
    sample_rate: 0.2 # Judge 20% for full run

execution:
  max_concurrency: 5
  timeout_seconds: 180
  checkpoint_every: 25

output:
  directory: 'results/full_vertex_eval'
  save_raw_responses: true
  save_parsed: true
```

---

## 8. Quick Start Test Script

````python
# scripts/test_vertex_models.py
"""Quick test to verify all Vertex AI models are working"""

import asyncio
import os
from pathlib import Path

# Ensure project is set
PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT")
if not PROJECT_ID:
    raise ValueError("Set GOOGLE_CLOUD_PROJECT environment variable")

async def test_all_models():
    print(f"Testing with project: {PROJECT_ID}\n")

    test_prompt = """Analyze this Solidity function for vulnerabilities:

```solidity
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] -= amount;
}
````

Answer with JSON: {"verdict": "vulnerable" or "safe", "confidence": 0.0-1.0, "vulnerability_type": "type or null"}"""

    # Test Claude Opus 4.5
    print("=" * 50)
    print("Testing Claude Opus 4.5...")
    try:
        from anthropic import AnthropicVertex
        client = AnthropicVertex(project_id=PROJECT_ID, region="us-east5")
        response = client.messages.create(
            model="claude-opus-4-5@20251101",
            max_tokens=500,
            messages=[{"role": "user", "content": test_prompt}]
        )
        print(f"✓ Claude Opus 4.5: {response.content[0].text[:200]}...")
        print(f"  Tokens: {response.usage.input_tokens} in, {response.usage.output_tokens} out")
    except Exception as e:
        print(f"✗ Claude Opus 4.5 failed: {e}")

    # Test Gemini 3 Pro
    print("\n" + "=" * 50)
    print("Testing Gemini 3 Pro...")
    try:
        import vertexai
        from vertexai.generative_models import GenerativeModel
        vertexai.init(project=PROJECT_ID, location="us-central1")
        model = GenerativeModel("gemini-3-pro")
        response = model.generate_content(test_prompt)
        print(f"✓ Gemini 3 Pro: {response.text[:200]}...")
        print(f"  Tokens: {response.usage_metadata.prompt_token_count} in, {response.usage_metadata.candidates_token_count} out")
    except Exception as e:
        print(f"✗ Gemini 3 Pro failed: {e}")

    # Test DeepSeek V3.2
    print("\n" + "=" * 50)
    print("Testing DeepSeek V3.2...")
    try:
        from openai import OpenAI
        import google.auth
        import google.auth.transport.requests

        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        client = OpenAI(
            base_url=f"https://us-central1-aiplatform.googleapis.com/v1/projects/{PROJECT_ID}/locations/us-central1/endpoints/openapi",
            api_key=credentials.token
        )
        response = client.chat.completions.create(
            model="deepseek-ai/deepseek-v3.2-maas",
            messages=[{"role": "user", "content": test_prompt}],
            max_tokens=500
        )
        print(f"✓ DeepSeek V3.2: {response.choices[0].message.content[:200]}...")
        print(f"  Tokens: {response.usage.prompt_tokens} in, {response.usage.completion_tokens} out")
    except Exception as e:
        print(f"✗ DeepSeek V3.2 failed: {e}")

    print("\n" + "=" * 50)
    print("Testing complete!")

if **name** == "**main**":
asyncio.run(test_all_models())

````

---

## 9. Implementation Checklist

### Phase 1: Setup (Day 1)
- [ ] `gcloud auth application-default login`
- [ ] Set `GOOGLE_CLOUD_PROJECT` environment variable
- [ ] Enable Vertex AI API
- [ ] Enable Claude Opus 4.5 in Model Garden
- [ ] Enable DeepSeek V3.2 in Model Garden
- [ ] Run `test_vertex_models.py` to verify access
- [ ] Install Python dependencies

### Phase 2: Core Pipeline (Days 2-3)
- [ ] Implement data loader
- [ ] Implement model clients (all 3)
- [ ] Implement prompt builder
- [ ] Implement response parser
- [ ] Basic detection metrics

### Phase 3: Pipeline Runner (Days 4-5)
- [ ] Async runner with concurrency control
- [ ] Checkpointing for resume
- [ ] Cost tracking
- [ ] CLI interface

### Phase 4: Evaluation (Days 6-7)
- [ ] Run pilot (50 samples)
- [ ] Analyze results, fix issues
- [ ] Run full evaluation
- [ ] Generate paper tables/figures

---

## 10. Adding More Models Later

The architecture supports easy addition of new models:

**To add Claude Sonnet 4.5:**
```yaml
# config/models/claude-sonnet-4-5.yaml
name: "Claude Sonnet 4.5"
provider: "anthropic"
model_id: "claude-sonnet-4-5@20250929"
region: "us-east5"
cost_per_input_token: 0.000003   # $3/1M
cost_per_output_token: 0.000015  # $15/1M
````

**To add Codestral 2 (via OpenRouter):**
Would require a new `openrouter_client.py` implementation.

**To add local models:**
Would require `local_client.py` with Ollama/vLLM support.

---

## 11. Environment Variables Summary

```bash
# Required
export GOOGLE_CLOUD_PROJECT="your-project-id"

# Optional (if not using ADC)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

---

## 12. Troubleshooting

### Common Issues

**"Permission denied" for Claude:**

- Ensure Claude is enabled in Model Garden
- Check IAM roles: `roles/aiplatform.user` required

**"Model not found" for DeepSeek:**

- Enable DeepSeek V3.2 in Model Garden
- Verify region is `us-central1`

**Token refresh errors:**

- Run `gcloud auth application-default login` again
- Check ADC configuration

**Rate limiting:**

- Reduce `max_concurrency` in config
- Add delays between requests

---

**End of Specification v2**
