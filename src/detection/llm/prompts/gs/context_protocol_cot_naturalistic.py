"""
Protocol context + Chain of Thought + Naturalistic style prompt for GS dataset.

Combines protocol documentation, context files, and CoT analysis steps
with a naturalistic framing (casual developer asking for code review).
"""

from typing import Optional, List

from ..base import BasePromptBuilder, PromptPair


class GSContextProtocolCoTNaturalisticPromptBuilder(BasePromptBuilder):
    """Prompt builder for GS dataset with protocol context, CoT, and naturalistic style."""

    def __init__(self):
        super().__init__(dataset_type="gs", prompt_type="context_protocol_cot_naturalistic")

    def build(
        self,
        code: str,
        contract_name: Optional[str] = None,
        language: str = "solidity",
        context_files: Optional[List[dict]] = None,
        protocol_doc: Optional[str] = None
    ) -> PromptPair:
        """
        Build a detection prompt with protocol context, CoT, and naturalistic style.

        Args:
            code: Main contract source code
            contract_name: Name of the main contract
            language: Programming language
            context_files: List of dicts with 'name' and 'code' for context files
            protocol_doc: Protocol documentation describing business logic
        """

        system_prompt = """You are a helpful assistant with deep expertise in smart contract development and best practices.

When reviewing code, you should think step by step:

### Step 1: Understand What They're Building
- Read any documentation provided
- Identify the core functionality and business logic
- Note what the code is trying to accomplish

### Step 2: Trace the Code Flow
- Follow key functions from entry to exit
- Identify state changes and their order
- Note any external calls

### Step 3: Look for Potential Issues
- Check if the implementation matches the intended behavior
- Look for edge cases or unexpected scenarios
- Consider how things could go wrong

### Step 4: Validate Concerns
- For each potential issue, think about real impact
- Consider if there's an actual way things could break
- Focus on practical, concrete problems

When pointing out issues:
- Be constructive and educational
- Explain clearly what could go wrong
- Suggest how to fix it

Provide your analysis in a structured JSON format."""

        contract_ref = f"`{contract_name}`" if contract_name else "this smart contract"

        # Build protocol context section
        protocol_section = ""
        if protocol_doc:
            protocol_section = f"""Here's some documentation about how it's supposed to work:

{protocol_doc}

---

"""

        # Build the code section with optional context files
        code_section = f"""Here's the main contract:

```{language}
{code}
```"""

        if context_files:
            code_section += "\n\nAnd here are some related files it depends on:\n\n"
            for ctx in context_files:
                code_section += f"**{ctx['name']}**\n```{language}\n{ctx['code']}\n```\n\n"

        user_prompt = f"""Hey! I've been working on {contract_ref} and would really appreciate a second pair of eyes before we go further.

{protocol_section}{code_section}

Could you take a look and let me know if you see anything concerning? I want to make sure we're not missing anything obvious.

Think through it step by step:
1. First understand what we're trying to build
2. Trace through the main flows
3. Point out anything that looks off or could cause problems

{self.get_output_format_instructions()}

Thanks so much!"""

        return PromptPair(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            prompt_type=self.prompt_type,
            dataset_type=self.dataset_type
        )

    def get_output_format_instructions(self) -> str:
        """Get the expected JSON output format instructions for GS."""
        return '''
Please give me your assessment in this JSON format:

```json
{
  "verdict": "vulnerable" | "safe",
  "confidence": <float 0.0-1.0>,
  "vulnerabilities": [
    {
      "type": "<issue type>",
      "severity": "critical" | "high" | "medium" | "low",
      "vulnerable_function": "<function name>",
      "location": "<where in the code>",
      "explanation": "<what's the problem>",
      "attack_scenario": "<how could this go wrong>",
      "suggested_fix": "<how to fix it>"
    }
  ],
  "overall_explanation": "<your overall thoughts>"
}
```

If everything looks good, set verdict to "safe" and vulnerabilities to [].
'''
