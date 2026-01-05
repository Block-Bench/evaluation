"""
Protocol context + Chain of Thought prompt strategy for GS (Gold Standard) dataset.

Includes main contract, Solidity context files, protocol documentation,
AND structured chain-of-thought prompting for deeper analysis.
"""

from typing import Optional, List

from ..base import BasePromptBuilder, PromptPair


class GSContextProtocolCoTPromptBuilder(BasePromptBuilder):
    """Prompt builder for GS dataset with protocol context and chain-of-thought."""

    def __init__(self):
        super().__init__(dataset_type="gs", prompt_type="context_protocol_cot")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity",
        context_files: Optional[List[dict]] = None,
        protocol_doc: Optional[str] = None
    ) -> PromptPair:
        """
        Build a detection prompt with protocol context and CoT for GS dataset.

        Args:
            code: Main contract source code
            contract_name: Name of the main contract
            language: Programming language
            context_files: List of dicts with 'name' and 'code' for context files
            protocol_doc: Protocol documentation describing business logic
        """

        system_prompt = """You are an expert smart contract security auditor with deep knowledge of Solidity, the EVM, and common vulnerability patterns.

Your task is to analyze smart contracts for security vulnerabilities with high precision and accuracy.

## Analysis Approach - Think Step by Step

Follow this structured analysis process:

### Step 1: Understand the Protocol Intent
- Read the protocol documentation carefully
- Identify the core business logic and invariants
- Note what the code is SUPPOSED to accomplish

### Step 2: Map the Code Flow
- Trace key functions from entry to exit
- Identify state changes and their order
- Note external calls and their timing

### Step 3: Compare Intent vs Implementation
- For each function, verify it matches the protocol's intent
- Look for discrepancies between expected and actual behavior
- Check if invariants are maintained

### Step 4: Identify Attack Vectors
- Consider how each function could be exploited
- Think about state manipulation, reentrancy, economic attacks
- Evaluate cross-contract interactions

### Step 5: Validate Findings
- Ensure each finding has a concrete attack path
- Verify the impact is real and significant
- Confirm the fix would address the root cause

## What to Report

Only report REAL, EXPLOITABLE vulnerabilities where:
1. The vulnerability EXISTS in the provided code
2. There is a CONCRETE attack scenario with specific steps
3. The exploit does NOT require a trusted role to be compromised
4. The impact is a genuine security concern

Pay special attention to:
- Logic errors where implementation differs from intended behavior
- Order of operations issues (e.g., calculate before or after state change)
- Economic exploits (share calculation, price manipulation, sandwich attacks)
- State management and reentrancy

## What NOT to Report

- Design choices and intentional architectural decisions
- Informational issues (gas, style, events)
- Theoretical concerns without concrete exploit
- Issues requiring trusted roles to be malicious

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

## Instructions

Think through your analysis step by step:
1. First, understand what the protocol is trying to achieve
2. Trace the code flow for key functions
3. Identify any discrepancies between intent and implementation
4. For each potential issue, validate it has a real attack path

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
