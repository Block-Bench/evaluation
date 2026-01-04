"""
Pydantic models for data validation and type safety.
"""

from pydantic import BaseModel, Field
from typing import Optional, Literal
from enum import Enum
from datetime import datetime


class Severity(str, Enum):
    """Vulnerability severity levels."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFORMATIONAL = "informational"


class SubsetType(str, Enum):
    """Dataset subset types."""
    DIFFICULTY_STRATIFIED = "difficulty_stratified"
    TEMPORAL_CONTAMINATION = "temporal_contamination"
    GOLD_STANDARD = "gold_standard"


class TransformationType(str, Enum):
    """Data transformation types."""
    SANITIZED = "sanitized"
    NOCOMMENTS = "nocomments"
    CHAMELEON_GAMING_SN = "chameleon/gaming_sn"
    CHAMELEON_GAMING_NC = "chameleon/gaming_nc"
    CHAMELEON_MEDICAL_SN = "chameleon/medical_sn"
    CHAMELEON_MEDICAL_NC = "chameleon/medical_nc"
    MIRROR_COMPRESSED = "mirror/compressed"
    MIRROR_EXPANDED = "mirror/expanded"
    MIRROR_MINIFIED = "mirror/minified"
    MIRROR_ALLMAN = "mirror/allman"
    MIRROR_KNR = "mirror/knr"
    CROSSDOMAIN_GAMING_NO = "crossdomain/gaming_no"
    CROSSDOMAIN_GAMING_SA = "crossdomain/gaming_sa"
    CROSSDOMAIN_HEALTHCARE_NO = "crossdomain/healthcare_no"
    CROSSDOMAIN_HEALTHCARE_SA = "crossdomain/healthcare_sa"
    HYDRA_INT_NC = "hydra/int_nc"
    HYDRA_INT_SN = "hydra/int_sn"
    GUARDIANSHIELD_ACCESS_CONTROL_NO = "guardianshield/access_control_no"
    GUARDIANSHIELD_ACCESS_CONTROL_SA = "guardianshield/access_control_sa"
    GUARDIANSHIELD_CEI_PATTERN_NO = "guardianshield/cei_pattern_no"
    GUARDIANSHIELD_CEI_PATTERN_SA = "guardianshield/cei_pattern_sa"


class SamplingStrategy(str, Enum):
    """Sampling strategies."""
    INDEPENDENT = "independent"  # Sample independently from each transformation
    ONEFORALL = "oneforall"  # Sample base IDs, then get all transformations for each


# --------------------------------------------------------------------------
# Ground Truth Schema (from annotated metadata)
# --------------------------------------------------------------------------

class GroundTruth(BaseModel):
    """Ground truth data for evaluation (from annotated metadata)."""
    id: str
    is_vulnerable: bool
    vulnerability_type: Optional[str] = None
    severity: Optional[str] = None

    # Location info
    vulnerable_contract: Optional[str] = None
    vulnerable_function: Optional[str] = None
    vulnerable_lines: Optional[list[int]] = []

    # Detailed analysis (for judge)
    description: Optional[str] = None
    root_cause: Optional[str] = None
    attack_scenario: Optional[str] = None
    fix_description: Optional[str] = None

    # Metadata
    difficulty_tier: Optional[int] = None
    original_subset: Optional[str] = None
    tags: Optional[list[str]] = []


# --------------------------------------------------------------------------
# Sample Schema (input to model)
# --------------------------------------------------------------------------

class Sample(BaseModel):
    """A single evaluation sample."""
    id: str  # Original ID (e.g., ds_001, tc_001)
    transformed_id: str  # ID with transformation prefix (e.g., sn_ds_001)
    transformation: str  # Transformation type (e.g., sanitized, nocomments)
    subset: str  # Original subset (ds, tc, gs)

    # File paths
    contract_file: str  # Path to transformed contract
    metadata_file: Optional[str] = None  # Path to metadata if exists

    # Contract content (loaded separately)
    contract_code: Optional[str] = None

    # Ground truth (loaded from annotated)
    ground_truth: Optional[GroundTruth] = None

    # Per-sample prompt types (if specified, overrides global)
    prompt_types: Optional[list[str]] = None


# --------------------------------------------------------------------------
# Model Response Schema
# --------------------------------------------------------------------------

class DetectedVulnerability(BaseModel):
    """A single vulnerability detected by the model."""
    type: str
    severity: Optional[str] = None
    location: Optional[str] = None  # Function or line description
    explanation: str
    suggested_fix: Optional[str] = None


class ModelPrediction(BaseModel):
    """Structured prediction from the model."""
    verdict: Literal["vulnerable", "safe", "unknown"]
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    vulnerabilities: list[DetectedVulnerability] = []
    overall_explanation: Optional[str] = None

    # Parsing metadata
    parse_success: bool = True
    parse_errors: list[str] = []
    raw_response: Optional[str] = None


class EvaluationResult(BaseModel):
    """Complete evaluation result for a single sample."""
    # Identifiers
    sample_id: str
    transformed_id: str
    transformation: str
    prompt_type: str  # direct, naturalistic, adversarial
    model_id: str

    # Timestamps
    timestamp: datetime = Field(default_factory=datetime.now)

    # Model output
    # For direct prompts: parsed prediction with structure
    # For naturalistic/adversarial: prediction is None, use raw_response
    prediction: Optional[ModelPrediction] = None
    raw_response: str = ""  # Always stored for all prompt types

    # API metrics
    input_tokens: Optional[int] = None
    output_tokens: Optional[int] = None
    latency_ms: Optional[float] = None
    cost_usd: Optional[float] = None

    # Error handling
    error: Optional[str] = None


# --------------------------------------------------------------------------
# Configuration Schema
# --------------------------------------------------------------------------

class SamplingConfig(BaseModel):
    """Sampling configuration."""
    ds: Optional[int] = None  # difficulty_stratified count
    tc: Optional[int] = None  # temporal_contamination count
    gs: Optional[int] = None  # gold_standard count
    strategy: str = "independent"  # "independent" or "oneforall"
    min_difficulty: Optional[int] = None  # Minimum difficulty_tier to include


class DataConfig(BaseModel):
    """Data configuration."""
    root: str
    ground_truth_path: str
    transformations: list[str]
    sampling: Optional[SamplingConfig] = None
    seed: int = 42


class ExecutionConfig(BaseModel):
    """Execution configuration."""
    max_concurrency: int = 3
    timeout_seconds: int = 180
    checkpoint_every: int = 10
    max_retries: int = 3
    retry_delay: float = 2.0


class OutputConfig(BaseModel):
    """Output configuration."""
    directory: str
    save_raw_responses: bool = True


class EvaluationConfig(BaseModel):
    """Evaluation configuration."""
    prompt_types: list[str] = ["direct", "naturalistic", "adversarial"]
    chain_of_thought: bool = False


class Config(BaseModel):
    """Complete configuration."""
    data: DataConfig
    evaluation: EvaluationConfig
    execution: ExecutionConfig
    output: OutputConfig
    default_model: str
