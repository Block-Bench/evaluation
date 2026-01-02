"""
Direct prompt strategy for DS (Difficulty-Stratified) dataset.
"""

from typing import Optional

from ..base import BasePromptBuilder, PromptPair


class DSDirectPromptBuilder(BasePromptBuilder):
    """Direct prompt builder for DS dataset."""

    def __init__(self):
        super().__init__(dataset_type="ds", prompt_type="direct")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity"
    ) -> PromptPair:
        """Build a direct detection prompt."""

        system_prompt = """You are an expert smart contract security auditor with deep knowledge of Solidity, the EVM, and common vulnerability patterns.

Your task is to analyze smart contracts for security vulnerabilities with high precision and accuracy.

You must:
1. Carefully analyze the provided code
2. Identify any security vulnerabilities present
3. Explain WHY each vulnerability is exploitable
4. Provide specific attack scenarios
5. Suggest concrete fixes

Be thorough but avoid false positives. Only report real, exploitable vulnerabilities.

Common vulnerability categories include:
- Reentrancy (cross-function, cross-contract, read-only)
- Access control issues (missing modifiers, improper role management)
- Integer overflow/underflow (in older Solidity versions)
- Weak randomness (block.timestamp, blockhash)
- Front-running vulnerabilities
- Unchecked external calls
- Logic errors

Respond with valid JSON only."""

        contract_ref = f" for contract `{contract_name}`" if contract_name else ""

        user_prompt = f"""Analyze the following {language} smart contract{contract_ref} for security vulnerabilities.

```{language}
{code}
```

{self.get_output_format_instructions()}"""

        return PromptPair(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            prompt_type=self.prompt_type,
            dataset_type=self.dataset_type
        )
