"""
Protocol context prompt strategy for GS (Gold Standard) dataset.

Includes main contract, Solidity context files, AND protocol documentation
to help the model understand the business logic and intended behavior.
"""

from typing import Optional, List

from ..base import BasePromptBuilder, PromptPair


class GSContextProtocolPromptBuilder(BasePromptBuilder):
    """Prompt builder for GS dataset with protocol context documentation."""

    def __init__(self):
        super().__init__(dataset_type="gs", prompt_type="context_protocol")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity",
        context_files: Optional[List[dict]] = None,
        protocol_doc: Optional[str] = None
    ) -> PromptPair:
        """
        Build a detection prompt with protocol context for GS dataset.

        Args:
            code: Main contract source code
            contract_name: Name of the main contract
            language: Programming language
            context_files: List of dicts with 'name' and 'code' for context files
            protocol_doc: Protocol documentation describing business logic
        """

        system_prompt = """You are an expert smart contract security auditor with deep knowledge of Solidity, the EVM, and common vulnerability patterns.

Your task is to analyze smart contracts for security vulnerabilities with high precision and accuracy.

## Understanding the Protocol

You will be provided with protocol documentation that explains the intended business logic. Use this context to:
1. Understand what the code is SUPPOSED to do
2. Identify discrepancies between intended behavior and actual implementation
3. Find logic errors where the code doesn't match the protocol's design

## What to Report

Only report REAL, EXPLOITABLE vulnerabilities where:
1. The vulnerability EXISTS in the provided code
2. There is a CONCRETE attack scenario with specific steps
3. The exploit does NOT require a trusted role (owner/admin) to be compromised
4. The impact is a genuine security concern (loss of funds, unauthorized access, state manipulation)

Pay special attention to:
- Logic errors where implementation differs from intended behavior
- State management issues
- Economic exploits (e.g., share calculation errors, price manipulation)
- Cross-contract interaction vulnerabilities

For each vulnerability you find:
- Identify the function(s) where the vulnerability exists
- Explain WHY it is exploitable (root cause)
- Provide SPECIFIC attack steps (not vague "could be exploited")
- Suggest a concrete fix

## What NOT to Report

Do NOT report the following - they are not vulnerabilities:

- **Design Choices**: Intentional architectural decisions
- **Informational Issues**: Gas optimizations, code style, missing events
- **Security Theater**: Theoretical concerns without concrete attack
- **Trusted Role Assumptions**: Issues requiring admin/owner to be malicious
- **Out of Scope**: Issues in external contracts you cannot see

## Confidence Calibration

Express your confidence based on certainty:
- **High (0.85-1.0)**: Clear, unambiguous vulnerability with obvious exploit path
- **Medium (0.6-0.84)**: Likely vulnerability but exploitation depends on external factors
- **Low (0.3-0.59)**: Possible issue but significant uncertainty about exploitability

If the contract is genuinely safe, say so with high confidence. Do not invent issues.

## Response Format

Be CONCISE, precise, and direct. Maximum 250 words per field.

Respond with valid JSON only."""

        contract_ref = f" for contract `{contract_name}`" if contract_name else ""

        # Build protocol context section
        protocol_section = ""
        if protocol_doc:
            protocol_section = f"""## Protocol Documentation

{protocol_doc}

---

"""

        # Build the code section with optional context files
        code_section = f"""## Main Contract{contract_ref}

```{language}
{code}
```"""

        if context_files:
            code_section += "\n\n## Context Files (Dependencies)\n"
            code_section += "The following files provide additional context for understanding the main contract:\n\n"
            for ctx in context_files:
                code_section += f"### {ctx['name']}\n```{language}\n{ctx['code']}\n```\n\n"

        user_prompt = f"""Analyze the following {language} smart contract(s) for security vulnerabilities.

{protocol_section}{code_section}

{self.get_output_format_instructions()}"""

        return PromptPair(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            prompt_type=self.prompt_type,
            dataset_type=self.dataset_type
        )

    def get_output_format_instructions(self) -> str:
        """Get the expected JSON output format instructions for GS."""
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
      "vulnerable_function": "<function name where vulnerability exists>",
      "location": "<contract and function name>",
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
