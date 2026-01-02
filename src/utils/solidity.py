"""
Solidity-specific utilities.
"""

import re
from typing import Optional


def extract_contract_name(code: str) -> Optional[str]:
    """
    Extract the main contract name from Solidity code.

    Args:
        code: Solidity source code

    Returns:
        Contract name or None if not found
    """
    # Match 'contract ContractName' but not 'abstract contract' or 'interface'
    pattern = r'(?<!abstract\s)contract\s+(\w+)'
    matches = re.findall(pattern, code, re.IGNORECASE)

    # Return first concrete contract found
    return matches[0] if matches else None


def extract_all_contracts(code: str) -> list[str]:
    """
    Extract all contract names from Solidity code.

    Args:
        code: Solidity source code

    Returns:
        List of contract names
    """
    pattern = r'contract\s+(\w+)'
    return re.findall(pattern, code, re.IGNORECASE)


def extract_solidity_version(code: str) -> Optional[str]:
    """
    Extract Solidity version from pragma statement.

    Args:
        code: Solidity source code

    Returns:
        Version string or None
    """
    pattern = r'pragma\s+solidity\s+([^;]+);'
    match = re.search(pattern, code, re.IGNORECASE)

    if match:
        version_str = match.group(1).strip()
        # Extract actual version number
        version_match = re.search(r'(\d+\.\d+\.\d+|\d+\.\d+)', version_str)
        return version_match.group(1) if version_match else version_str

    return None


def extract_functions(code: str) -> list[dict]:
    """
    Extract function signatures from Solidity code.

    Args:
        code: Solidity source code

    Returns:
        List of function info dicts
    """
    pattern = r'function\s+(\w+)\s*\(([^)]*)\)\s*(public|external|internal|private)?'
    matches = re.findall(pattern, code, re.IGNORECASE)

    functions = []
    for name, params, visibility in matches:
        functions.append({
            "name": name,
            "parameters": params.strip() if params.strip() else None,
            "visibility": visibility.lower() if visibility else "internal"
        })

    return functions


def has_vulnerability_pattern(code: str, pattern_type: str) -> bool:
    """
    Check if code contains a known vulnerability pattern.

    Args:
        code: Solidity source code
        pattern_type: Type of vulnerability to check

    Returns:
        True if pattern found
    """
    patterns = {
        "reentrancy": [
            r'\.call\s*\{',
            r'\.call\.value\(',
            r'\.send\(',
            r'\.transfer\('
        ],
        "weak_randomness": [
            r'block\.timestamp',
            r'block\.difficulty',
            r'blockhash\s*\('
        ],
        "unchecked_call": [
            r'\.call\s*\([^)]*\)\s*;',  # call without checking return
        ],
        "selfdestruct": [
            r'selfdestruct\s*\(',
            r'suicide\s*\('
        ],
        "tx_origin": [
            r'tx\.origin'
        ]
    }

    if pattern_type not in patterns:
        return False

    for pattern in patterns[pattern_type]:
        if re.search(pattern, code, re.IGNORECASE):
            return True

    return False


def normalize_code(code: str) -> str:
    """
    Normalize Solidity code for comparison.

    Removes comments and extra whitespace.

    Args:
        code: Solidity source code

    Returns:
        Normalized code
    """
    # Remove single-line comments
    code = re.sub(r'//.*$', '', code, flags=re.MULTILINE)

    # Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    # Normalize whitespace
    code = re.sub(r'\s+', ' ', code)

    return code.strip()


def count_lines(code: str, exclude_comments: bool = True) -> int:
    """
    Count lines of code.

    Args:
        code: Solidity source code
        exclude_comments: Whether to exclude comment lines

    Returns:
        Line count
    """
    if exclude_comments:
        code = normalize_code(code)

    lines = [line for line in code.split('\n') if line.strip()]
    return len(lines)
