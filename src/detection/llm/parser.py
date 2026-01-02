"""
Parser for LLM detection outputs.

Handles extraction and validation of JSON responses from various LLM formats.
"""

import json
import re
from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class ParseResult:
    """Result of parsing LLM output."""
    success: bool
    data: Optional[dict]
    raw_content: str
    error_message: Optional[str] = None
    extraction_method: Optional[str] = None  # "json_block", "raw_json", "regex"


class LLMOutputParser:
    """Parser for extracting structured data from LLM responses."""

    def parse(self, content: str) -> ParseResult:
        """
        Parse LLM output and extract JSON data.

        Tries multiple extraction strategies:
        1. JSON code block (```json ... ```)
        2. Raw JSON object
        3. Regex-based extraction

        Args:
            content: Raw LLM response text

        Returns:
            ParseResult with extracted data or error
        """
        # Strategy 1: Extract from JSON code block
        result = self._extract_json_block(content)
        if result.success:
            return result

        # Strategy 2: Try parsing as raw JSON
        result = self._extract_raw_json(content)
        if result.success:
            return result

        # Strategy 3: Regex-based extraction
        result = self._extract_via_regex(content)
        if result.success:
            return result

        return ParseResult(
            success=False,
            data=None,
            raw_content=content,
            error_message="Failed to extract valid JSON from response"
        )

    def _extract_json_block(self, content: str) -> ParseResult:
        """Extract JSON from markdown code block."""
        pattern = r'```(?:json)?\s*\n?(.*?)\n?```'
        matches = re.findall(pattern, content, re.DOTALL)

        for match in matches:
            try:
                data = json.loads(match.strip())
                return ParseResult(
                    success=True,
                    data=data,
                    raw_content=content,
                    extraction_method="json_block"
                )
            except json.JSONDecodeError:
                continue

        return ParseResult(
            success=False,
            data=None,
            raw_content=content,
            error_message="No valid JSON in code blocks"
        )

    def _extract_raw_json(self, content: str) -> ParseResult:
        """Try to parse content as raw JSON."""
        # Find JSON object boundaries
        content_stripped = content.strip()

        # Try to find JSON object
        if content_stripped.startswith('{'):
            try:
                data = json.loads(content_stripped)
                return ParseResult(
                    success=True,
                    data=data,
                    raw_content=content,
                    extraction_method="raw_json"
                )
            except json.JSONDecodeError:
                pass

        # Try to extract JSON object from content
        start_idx = content.find('{')
        if start_idx != -1:
            # Find matching closing brace
            brace_count = 0
            for i, char in enumerate(content[start_idx:], start_idx):
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        try:
                            data = json.loads(content[start_idx:i + 1])
                            return ParseResult(
                                success=True,
                                data=data,
                                raw_content=content,
                                extraction_method="raw_json"
                            )
                        except json.JSONDecodeError:
                            break

        return ParseResult(
            success=False,
            data=None,
            raw_content=content,
            error_message="Content is not valid JSON"
        )

    def _extract_via_regex(self, content: str) -> ParseResult:
        """Last resort: regex-based extraction of key fields."""
        try:
            # Extract verdict
            verdict_match = re.search(
                r'"verdict"\s*:\s*"(vulnerable|safe)"',
                content,
                re.IGNORECASE
            )
            verdict = verdict_match.group(1).lower() if verdict_match else None

            # Extract confidence
            confidence_match = re.search(
                r'"confidence"\s*:\s*([\d.]+)',
                content
            )
            confidence = float(confidence_match.group(1)) if confidence_match else None

            if verdict is not None:
                data = {
                    "verdict": verdict,
                    "confidence": confidence or 0.5,
                    "vulnerabilities": [],
                    "overall_explanation": "Extracted via regex fallback"
                }
                return ParseResult(
                    success=True,
                    data=data,
                    raw_content=content,
                    extraction_method="regex"
                )

        except Exception:
            pass

        return ParseResult(
            success=False,
            data=None,
            raw_content=content,
            error_message="Regex extraction failed"
        )

    def validate_detection_output(self, data: dict) -> tuple[bool, list[str]]:
        """
        Validate that parsed data conforms to expected detection output schema.

        Returns:
            Tuple of (is_valid, list of error messages)
        """
        errors = []

        # Required fields
        if "verdict" not in data:
            errors.append("Missing required field: verdict")
        elif data["verdict"] not in ["vulnerable", "safe"]:
            errors.append(f"Invalid verdict value: {data['verdict']}")

        if "confidence" not in data:
            errors.append("Missing required field: confidence")
        elif not isinstance(data["confidence"], (int, float)):
            errors.append("Confidence must be a number")
        elif not 0 <= data["confidence"] <= 1:
            errors.append("Confidence must be between 0 and 1")

        if "vulnerabilities" not in data:
            errors.append("Missing required field: vulnerabilities")
        elif not isinstance(data["vulnerabilities"], list):
            errors.append("Vulnerabilities must be an array")
        else:
            for i, vuln in enumerate(data["vulnerabilities"]):
                vuln_errors = self._validate_vulnerability(vuln, i)
                errors.extend(vuln_errors)

        return len(errors) == 0, errors

    def _validate_vulnerability(self, vuln: dict, index: int) -> list[str]:
        """Validate a single vulnerability entry."""
        errors = []
        prefix = f"vulnerabilities[{index}]"

        required_fields = ["type", "severity", "location", "explanation"]
        for field in required_fields:
            if field not in vuln:
                errors.append(f"{prefix}: Missing required field '{field}'")

        if "severity" in vuln:
            valid_severities = ["critical", "high", "medium", "low"]
            if vuln["severity"].lower() not in valid_severities:
                errors.append(f"{prefix}: Invalid severity '{vuln['severity']}'")

        return errors
