"""
Pydantic schemas for the LLM Judge system.
"""

from pydantic import BaseModel, Field
from typing import Optional, Literal
from enum import Enum
from datetime import datetime


# =============================================================================
# Enums
# =============================================================================

class PromptType(str, Enum):
    """Types of prompts used for evaluation"""
    DIRECT = "direct"
    NATURALISTIC = "naturalistic"
    ADVERSARIAL = "adversarial"


class FindingClassification(str, Enum):
    """Classification of a finding from the response"""
    # Valid findings
    TARGET_MATCH = "TARGET_MATCH"           # Found our documented vulnerability
    PARTIAL_MATCH = "PARTIAL_MATCH"         # Close but not exact match to target
    BONUS_VALID = "BONUS_VALID"             # Found a REAL exploitable issue we didn't document

    # Invalid findings (no credit)
    HALLUCINATED = "HALLUCINATED"           # Claimed issue that doesn't exist in the code
    MISCHARACTERIZED = "MISCHARACTERIZED"   # Real code feature but not a vulnerability
    DESIGN_CHOICE = "DESIGN_CHOICE"         # Intentional architectural decision, not a bug
    OUT_OF_SCOPE = "OUT_OF_SCOPE"           # Issue in external/called contract, not this one
    SECURITY_THEATER = "SECURITY_THEATER"   # Theoretical concern with no concrete exploit
    INFORMATIONAL = "INFORMATIONAL"         # True observation but not security-relevant


class TypeMatchLevel(str, Enum):
    """How well the vulnerability type matches ground truth"""
    EXACT = "exact"                         # Exact type match
    SEMANTIC = "semantic"                   # Different words, same meaning
    PARTIAL = "partial"                     # Related but not quite
    WRONG = "wrong"                         # Incorrect type
    NOT_MENTIONED = "not_mentioned"         # Didn't specify type


# =============================================================================
# Input Schemas
# =============================================================================

class GroundTruthForJudge(BaseModel):
    """Ground truth data passed to the judge"""
    is_vulnerable: bool
    vulnerability_type: Optional[str] = None
    severity: Optional[str] = None
    root_cause: Optional[str] = None
    attack_scenario: Optional[str] = None
    fix_description: Optional[str] = None
    vulnerable_function: Optional[str] = None
    vulnerable_lines: Optional[list[int]] = None


class JudgeInput(BaseModel):
    """Complete input for judge evaluation"""
    sample_id: str
    transformed_id: str
    prompt_type: PromptType
    code: str
    language: str = "solidity"
    ground_truth: GroundTruthForJudge
    response_content: str  # The analysis response to evaluate (no mention of model)


# =============================================================================
# Output Schemas - From Judge
# =============================================================================

class ReasoningScore(BaseModel):
    """Score with explanation"""
    score: float = Field(ge=0.0, le=1.0)
    reasoning: str


class FindingEvaluation(BaseModel):
    """Evaluation of a single finding from the response"""
    finding_id: int
    description: str
    vulnerability_type_claimed: Optional[str] = None
    severity_claimed: Optional[str] = None
    location_claimed: Optional[str] = None

    # Judge's evaluation
    matches_target: bool
    is_valid_concern: bool
    classification: FindingClassification
    reasoning: str


class TargetVulnerabilityAssessment(BaseModel):
    """Assessment of target vulnerability detection and reasoning"""
    found: bool
    finding_id: Optional[int] = None

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
    transformed_id: str
    prompt_type: PromptType
    judge_model: str
    timestamp: datetime = Field(default_factory=datetime.now)

    # Overall verdict extraction
    overall_verdict: dict  # {said_vulnerable, confidence_expressed}

    # All findings
    findings: list[FindingEvaluation]

    # Target vulnerability assessment
    target_assessment: TargetVulnerabilityAssessment

    # Summary counts
    summary: dict  # {total_findings, target_matches, bonus_valid, hallucinated, partial_matches}

    # Any additional notes from judge
    notes: Optional[str] = None

    # Metadata
    judge_latency_ms: float
    judge_input_tokens: int
    judge_output_tokens: int
    judge_cost_usd: float


# =============================================================================
# Computed Metrics Schemas
# =============================================================================

class SampleMetrics(BaseModel):
    """Computed metrics for a single sample"""
    sample_id: str
    transformed_id: str
    prompt_type: PromptType

    # Detection (binary)
    detection_correct: bool
    ground_truth_vulnerable: bool
    response_said_vulnerable: Optional[bool]

    # Target finding
    target_found: bool
    lucky_guess: bool  # Right verdict, wrong/no target

    # Finding-level
    total_findings: int
    valid_findings: int
    invalid_findings: int  # All non-valid findings
    hallucinated_findings: int  # Subset: completely fabricated issues only
    finding_precision: float

    # Reasoning scores (None if target not found)
    rcir_score: Optional[float] = None
    ava_score: Optional[float] = None
    fsv_score: Optional[float] = None

    # Type accuracy
    type_match: TypeMatchLevel

    # Calibration (if confidence expressed)
    confidence: Optional[float] = None
    calibration_error: Optional[float] = None


class AggregatedMetrics(BaseModel):
    """Aggregated metrics across all samples"""

    # Sample counts
    total_samples: int
    vulnerable_samples: int
    safe_samples: int

    # Tier 1: Detection Performance
    detection: dict  # accuracy, precision, recall, f1, f2, fpr, fnr, tp, tn, fp, fn

    # Tier 2: Target Finding
    target_finding: dict  # target_detection_rate, lucky_guess_rate, bonus_discovery_rate

    # Tier 3: Finding Quality
    finding_quality: dict  # finding_precision, hallucination_rate, over_flagging_score

    # Tier 4: Reasoning Quality (computed only where target found)
    reasoning_quality: dict  # mean_rcir, mean_ava, mean_fsv, std values, n_samples

    # Tier 5: Type Accuracy
    type_accuracy: dict  # exact_match_rate, semantic_match_rate, partial_match_rate

    # Tier 6: Calibration
    calibration: dict  # ece, mce, overconfidence_rate, underconfidence_rate, brier_score

    # Tier 7: Composite Scores
    composite: dict  # sui, true_understanding_score, lucky_guess_indicator

    # Per-prompt-type breakdown
    by_prompt_type: Optional[dict[str, dict]] = None


class FullEvaluationReport(BaseModel):
    """Complete evaluation report for a model"""
    
    # Metadata
    model_name: str  # The model that was evaluated
    judge_model: str
    evaluation_timestamp: str
    total_judge_cost: float
    total_samples_evaluated: int

    # Overall metrics (aggregated across all prompt types)
    overall: AggregatedMetrics

    # Per-prompt-type metrics
    by_prompt_type: dict[str, AggregatedMetrics]

    # Per-sample details path
    sample_details_path: str
