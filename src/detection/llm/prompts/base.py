"""
Base class for prompt builders.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class PromptPair:
    """A system and user prompt pair."""
    system_prompt: str
    user_prompt: str
    prompt_type: str  # "direct", "naturalistic", "adversarial"
    dataset_type: str  # "ds", "tc", "gs"


class BasePromptBuilder(ABC):
    """Abstract base class for building detection prompts."""

    def __init__(self, dataset_type: str, prompt_type: str):
        self.dataset_type = dataset_type
        self.prompt_type = prompt_type

    @abstractmethod
    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity"
    ) -> PromptPair:
        """
        Build a prompt pair for vulnerability detection.

        Args:
            code: Smart contract source code
            contract_name: Name of the contract (optional)
            language: Programming language

        Returns:
            PromptPair with system and user prompts
        """
        pass

    def get_output_format_instructions(self) -> str:
        """Get the expected JSON output format instructions."""
        return '''
Respond with valid JSON only in this exact format:

```json
{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>,
  "vulnerabilities": [
    {
      "type": "<vulnerability type>",
      "severity": "critical" | "high" | "medium" | "low",
      "location": "<function name or code location>",
      "explanation": "<detailed explanation of the vulnerability>",
      "attack_scenario": "<specific steps to exploit>",
      "suggested_fix": "<recommended code changes>"
    }
  ],
  "overall_explanation": "<summary of security analysis>"
}
```

If the contract is safe, set verdict to "safe" and vulnerabilities to an empty array [].
'''
