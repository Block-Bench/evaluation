#!/usr/bin/env python3
"""Fix Gemini TC detection results that have valid responses but failed JSON parsing."""

import json
import re
from pathlib import Path

BASE_DIR = Path("/Users/poamen/projects/grace/blockbench/evaluation")

# Files to fix
FILES_TO_FIX = [
    "results/detection/llm/gemini-3-pro/tc/sanitized/d_sn_tc_017.json",
    "results/detection/llm/gemini-3-pro/tc/sanitized/d_sn_tc_031.json",
    "results/detection/llm/gemini-3-pro/tc/sanitized/d_sn_tc_032.json",
    "results/detection/llm/gemini-3-pro/tc/sanitized/d_sn_tc_040.json",
    "results/detection/llm/gemini-3-pro/tc/nocomments/d_nc_tc_005.json",
    "results/detection/llm/gemini-3-pro/tc/nocomments/d_nc_tc_007.json",
]


def extract_json_from_response(raw_response: str) -> dict:
    """Extract JSON from raw response, handling truncation and code blocks."""

    # Remove markdown code block markers
    text = raw_response

    # Remove leading text before JSON
    if "```json" in text:
        text = text.split("```json", 1)[1]
    elif "```" in text:
        text = text.split("```", 1)[1]

    # Remove trailing code block marker
    if "```" in text:
        text = text.split("```")[0]

    # Try to parse as-is first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Handle nested code blocks in suggested_fix (escape them)
    # Replace ```solidity with escaped version
    text = re.sub(r'```(\w+)\n', r'\\n```\1\\n', text)
    text = text.replace('```"', '\\n```"')

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try to extract partial JSON - find verdict and vulnerabilities
    result = {"verdict": None, "confidence": None, "vulnerabilities": [], "overall_explanation": ""}

    # Extract verdict
    verdict_match = re.search(r'"verdict"\s*:\s*"(\w+)"', text)
    if verdict_match:
        result["verdict"] = verdict_match.group(1)

    # Extract confidence
    conf_match = re.search(r'"confidence"\s*:\s*([\d.]+)', text)
    if conf_match:
        result["confidence"] = float(conf_match.group(1))

    # Try to extract individual vulnerabilities
    vuln_pattern = r'\{\s*"type"\s*:\s*"([^"]+)"[^}]*?"severity"\s*:\s*"(\w+)"[^}]*?"vulnerable_lines"\s*:\s*\[([^\]]*)\][^}]*?"location"\s*:\s*"([^"]+)"'
    for match in re.finditer(vuln_pattern, text, re.DOTALL):
        vuln_type, severity, lines_str, location = match.groups()

        # Parse lines
        lines = []
        for num in re.findall(r'\d+', lines_str):
            lines.append(int(num))

        # Extract explanation if present
        explanation = ""
        exp_match = re.search(rf'"location"\s*:\s*"{re.escape(location)}"[^}}]*?"explanation"\s*:\s*"([^"]+)"', text, re.DOTALL)
        if exp_match:
            explanation = exp_match.group(1)

        result["vulnerabilities"].append({
            "type": vuln_type,
            "severity": severity,
            "vulnerable_lines": lines,
            "location": location,
            "explanation": explanation
        })

    # Extract overall explanation
    overall_match = re.search(r'"overall_explanation"\s*:\s*"([^"]+)"', text)
    if overall_match:
        result["overall_explanation"] = overall_match.group(1)

    return result


def fix_file(filepath: Path) -> bool:
    """Fix a single file."""
    print(f"\n=== Processing {filepath.name} ===")

    with open(filepath) as f:
        data = json.load(f)

    raw_response = data.get("parsing", {}).get("raw_response", "")
    if not raw_response:
        print(f"  No raw response to parse")
        return False

    print(f"  Raw response length: {len(raw_response)}")

    # Try to extract JSON
    extracted = extract_json_from_response(raw_response)

    if not extracted.get("verdict"):
        print(f"  Could not extract verdict")
        return False

    print(f"  Extracted verdict: {extracted.get('verdict')}")
    print(f"  Extracted confidence: {extracted.get('confidence')}")
    print(f"  Extracted {len(extracted.get('vulnerabilities', []))} vulnerabilities")

    # Update the prediction field
    data["prediction"] = extracted
    data["parsing"]["success"] = True
    data["parsing"]["errors"] = ["Manually fixed truncated JSON response"]

    # Write back
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)

    print(f"  Fixed and saved!")
    return True


def main():
    fixed = 0
    failed = 0

    for filepath_str in FILES_TO_FIX:
        filepath = BASE_DIR / filepath_str
        if not filepath.exists():
            print(f"File not found: {filepath}")
            failed += 1
            continue

        if fix_file(filepath):
            fixed += 1
        else:
            failed += 1

    print(f"\n=== Summary ===")
    print(f"Fixed: {fixed}")
    print(f"Failed: {failed}")


if __name__ == "__main__":
    main()
