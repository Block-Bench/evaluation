"""
Direct prompt strategy for TC (Temporal Contamination) dataset.

TC contracts have line annotations (/*LN-X*/) and require models to identify
specific vulnerable line numbers.
"""

from typing import Optional

from ..base import BasePromptBuilder, PromptPair


class TCDirectPromptBuilder(BasePromptBuilder):
    """Direct prompt builder for TC dataset with line-level detection."""

    def __init__(self):
        super().__init__(dataset_type="tc", prompt_type="direct")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity"
    ) -> PromptPair:
        """Build a direct detection prompt for TC dataset."""

        system_prompt = """You are an expert smart contract security auditor with deep knowledge of Solidity, the EVM, and common vulnerability patterns.

Your task is to analyze smart contracts for security vulnerabilities with high precision and accuracy.

## Line Annotations

The code contains line number annotations in the format /*LN-X*/ where X is the line number. Use these annotations to identify the EXACT lines where vulnerabilities exist.

For each vulnerability, you MUST specify:
- The specific line number(s) where the ROOT CAUSE of the vulnerability is located
- Not just any line that touches the vulnerable code, but the actual lines that CAUSE the security issue

## What to Report

Only report REAL, EXPLOITABLE vulnerabilities where:
1. The vulnerability EXISTS in the provided code
2. There is a CONCRETE attack scenario with specific steps
3. The exploit does NOT require a trusted role (owner/admin) to be compromised
4. The impact is a genuine security concern (loss of funds, unauthorized access, state manipulation)

For each vulnerability you find:
- Identify the SPECIFIC LINE NUMBER(S) where the vulnerability exists
- Explain WHY it is exploitable (root cause)
- Provide SPECIFIC attack steps (not vague "could be exploited")
- Suggest a concrete fix

## What NOT to Report

Do NOT report the following - they are not vulnerabilities:

- **Design Choices**: Intentional architectural decisions (e.g., "owner can pause contract", "admin controls fees")
- **Informational Issues**: Gas optimizations, code style, missing events, documentation
- **Security Theater**: Theoretical concerns without a concrete, profitable attack (e.g., vague "could be front-run" without specific exploit)
- **Trusted Role Assumptions**: Issues requiring admin/owner to be malicious (e.g., "owner could rug pull")
- **Out of Scope**: Issues in external contracts or speculative problems about code you cannot see
- **Mischaracterizations**: Code patterns that look concerning but are actually safe in context

## Confidence Calibration

Express your confidence based on certainty:
- **High (0.85-1.0)**: Clear, unambiguous vulnerability with obvious exploit path
- **Medium (0.6-0.84)**: Likely vulnerability but exploitation depends on external factors
- **Low (0.3-0.59)**: Possible issue but significant uncertainty about exploitability
- **Very Low (<0.3)**: Speculative concern, likely not exploitable

If the contract is genuinely safe, say so with high confidence. Do not invent issues.

## Response Format

Be CONCISE, precise, and direct. Maximum 250 words per field:
- **explanation**: Max 250 words. State the root cause clearly.
- **attack_scenario**: Max 250 words. List specific attack steps.
- **suggested_fix**: Max 250 words. Give actionable remediation.
- **overall_explanation**: Max 250 words. Summarize key findings.

Good quality, precise responses will be rewarded. Responses exceeding these limits will not be reviewed.

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

    def get_output_format_instructions(self) -> str:
        """Get the expected JSON output format instructions for TC."""
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
      "vulnerable_lines": [<line numbers where root cause exists>],
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
