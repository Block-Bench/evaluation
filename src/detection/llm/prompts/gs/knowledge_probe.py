"""
Knowledge probe prompt for GS (Gold Standard) dataset.

Used to detect if a model has prior knowledge of audit findings,
which would indicate temporal contamination.
"""

from typing import Optional
from dataclasses import dataclass

from ..base import BasePromptBuilder, PromptPair


@dataclass
class KnowledgeProbeInput:
    """Input data for knowledge probe prompt."""
    audit_firm: str
    project_name: str
    finding_id: str
    vulnerability_type: str
    severity: str
    vulnerable_contract: str
    vulnerable_function: str


class GSKnowledgeProbePromptBuilder(BasePromptBuilder):
    """Prompt builder for knowledge probe / contamination detection."""

    def __init__(self):
        super().__init__(dataset_type="gs", prompt_type="knowledge_probe")

    def build(
        self,
        code: str = "",  # Not used for knowledge probe
        contract_name: Optional[str] = None,
        language: str = "solidity",
        probe_input: Optional[KnowledgeProbeInput] = None
    ) -> PromptPair:
        """
        Build a knowledge probe prompt for contamination detection.

        Args:
            code: Not used (kept for interface compatibility)
            contract_name: Not used
            language: Not used
            probe_input: KnowledgeProbeInput with audit details
        """
        if not probe_input:
            raise ValueError("probe_input is required for knowledge probe")

        system_prompt = """You are being assessed on your knowledge of blockchain security audit findings.

Answer HONESTLY and CONCISELY.

If you are familiar with the specific audit finding described, provide the requested details.
If you are NOT familiar with this specific finding, clearly state that you don't know.

DO NOT guess or make up information. Only provide details you are confident about from your training data.

Keep your response brief and to the point."""

        user_prompt = f"""Do you have any knowledge of a security audit finding from {probe_input.audit_firm} for the "{probe_input.project_name}" project?

Specifically, we are asking about a {probe_input.severity.upper()} severity finding ({probe_input.finding_id}) related to:
- Contract: {probe_input.vulnerable_contract}
- Function: {probe_input.vulnerable_function}
- Vulnerability Type: {probe_input.vulnerability_type}

If you are familiar with this specific audit finding, please answer:

1. When was this audit published? (year and month)
2. What is the title or summary of this finding?
3. What type of vulnerability was identified?
4. Can you briefly describe the vulnerability and its impact?
5. What was the recommended fix?

If you are NOT familiar with this specific audit finding, please respond with:
"I am not familiar with this specific audit finding."

Do not guess or make up information. Only provide details you are confident about."""

        return PromptPair(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            prompt_type=self.prompt_type,
            dataset_type=self.dataset_type
        )

    def get_output_format_instructions(self) -> str:
        """Knowledge probe expects free-form text response, not JSON."""
        return ""
