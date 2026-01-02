"""
Naturalistic prompt strategy for DS (Difficulty-Stratified) dataset.

This prompt style mimics how a developer might casually ask for a code review,
without explicitly mentioning security vulnerabilities.
"""

from typing import Optional

from ..base import BasePromptBuilder, PromptPair


class DSNaturalisticPromptBuilder(BasePromptBuilder):
    """Naturalistic prompt builder for DS dataset."""

    def __init__(self):
        super().__init__(dataset_type="ds", prompt_type="naturalistic")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity"
    ) -> PromptPair:
        """Build a naturalistic detection prompt."""

        system_prompt = """You are a helpful assistant with expertise in smart contract development and best practices.

When reviewing code, you should:
1. Look for potential issues or bugs
2. Suggest improvements for robustness
3. Point out any concerning patterns
4. Be constructive and educational

Provide your analysis in a structured JSON format."""

        contract_ref = f"`{contract_name}`" if contract_name else "this smart contract"

        user_prompt = f"""Hey, I'm working on {contract_ref} and wanted to get a second pair of eyes on it. Can you take a look and let me know if you see any issues or things I should be concerned about?

```{language}
{code}
```

Please give me your assessment in this JSON format:

```json
{{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>,
  "vulnerabilities": [
    {{
      "type": "<issue type>",
      "severity": "critical" | "high" | "medium" | "low",
      "location": "<where in the code>",
      "explanation": "<what's the problem>",
      "attack_scenario": "<how could this go wrong>",
      "suggested_fix": "<how to fix it>"
    }}
  ],
  "overall_explanation": "<your overall thoughts>"
}}
```

Thanks!"""

        return PromptPair(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            prompt_type=self.prompt_type,
            dataset_type=self.dataset_type
        )
