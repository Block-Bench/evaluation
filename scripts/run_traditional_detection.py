#!/usr/bin/env python3
"""
Run traditional tools (Slither, Mythril) on DS tier1 samples.
"""

import json
import subprocess
import time
import re
from pathlib import Path
from datetime import datetime


# Paths
PROJECT_ROOT = Path(__file__).parent.parent
SAMPLES_DIR = PROJECT_ROOT / "samples" / "ds"
RESULTS_DIR = PROJECT_ROOT / "results" / "detection" / "traditional"
SLITHER_BIN = PROJECT_ROOT / "traditionaltools" / "slither" / "venv" / "bin" / "slither"
SOLC_SELECT_BIN = PROJECT_ROOT / "traditionaltools" / "slither" / "venv" / "bin" / "solc-select"
MYTHRIL_BIN = PROJECT_ROOT / "traditionaltools" / "mythril" / "venv" / "bin" / "myth"


def extract_solidity_version(code: str) -> str:
    """Extract Solidity version from pragma or guess based on syntax."""
    # Look for pragma
    match = re.search(r'pragma\s+solidity\s+[\^~>=<]*\s*(\d+\.\d+\.\d+)', code)
    if match:
        return match.group(1)

    # Check for old syntax indicators
    if 'function()' in code and 'fallback' not in code.lower():
        return "0.4.26"  # Old fallback syntax
    if 'constructor' not in code and re.search(r'function\s+\w+\s*\(\s*\)\s*{', code):
        return "0.4.26"  # Might be old constructor

    # Default to 0.8.0 for modern contracts
    return "0.8.0"


def set_solc_version(version: str) -> bool:
    """Set solc version using solc-select."""
    try:
        # Install if needed
        subprocess.run(
            [str(SOLC_SELECT_BIN), "install", version],
            capture_output=True,
            timeout=120
        )
        # Use the version
        result = subprocess.run(
            [str(SOLC_SELECT_BIN), "use", version],
            capture_output=True,
            timeout=10
        )
        return result.returncode == 0
    except Exception as e:
        print(f"  Warning: Failed to set solc version {version}: {e}")
        return False


def run_slither(contract_path: Path, sample_id: str, tier: str, solc_version: str) -> dict:
    """Run Slither on a contract."""
    start_time = time.time()

    try:
        result = subprocess.run(
            [str(SLITHER_BIN), str(contract_path), "--json", "-"],
            capture_output=True,
            timeout=300,
            text=True
        )

        execution_time_ms = (time.time() - start_time) * 1000

        # Parse JSON output
        try:
            raw_output = json.loads(result.stdout) if result.stdout else {}
        except json.JSONDecodeError:
            raw_output = {"error": "Failed to parse JSON", "raw": result.stdout[:1000]}

        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "slither",
            "tool_version": "0.11.3",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": result.returncode == 0 or "detectors" in raw_output.get("results", {}),
            "error": result.stderr[:500] if result.returncode != 0 and not raw_output.get("success") else None,
            "execution_time_ms": execution_time_ms,
            "exit_code": result.returncode,
            "raw_output": raw_output
        }

    except subprocess.TimeoutExpired:
        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "slither",
            "tool_version": "0.11.3",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": "Timeout after 300 seconds",
            "execution_time_ms": (time.time() - start_time) * 1000,
            "exit_code": -1,
            "raw_output": {}
        }
    except Exception as e:
        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "slither",
            "tool_version": "0.11.3",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": str(e),
            "execution_time_ms": (time.time() - start_time) * 1000,
            "exit_code": -1,
            "raw_output": {}
        }


def run_mythril(contract_path: Path, sample_id: str, tier: str, solc_version: str, retry_with_t1: bool = True) -> dict:
    """Run Mythril on a contract.

    If retry_with_t1 is True and the first attempt times out,
    retry with -t 1 (single transaction depth) to avoid path explosion.
    """
    start_time = time.time()

    # First attempt: default transaction depth (usually 2)
    cmd = [str(MYTHRIL_BIN), "analyze", str(contract_path), "-o", "json", "--solv", solc_version]
    timeout_sec = 120
    used_t1 = False

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            timeout=timeout_sec,
            text=True
        )

        execution_time_ms = (time.time() - start_time) * 1000

        # Parse JSON output
        try:
            raw_output = json.loads(result.stdout) if result.stdout else {}
        except json.JSONDecodeError:
            raw_output = {"error": "Failed to parse JSON", "raw": result.stdout[:1000] if result.stdout else ""}

        # Mythril returns exit code 1 when it finds issues, 0 when no issues
        # So we check if we got valid JSON output to determine success
        has_valid_output = "issues" in raw_output or "error" in raw_output

        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "mythril",
            "tool_version": "0.24.8",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": has_valid_output,
            "error": result.stderr[:500] if not has_valid_output else None,
            "execution_time_ms": execution_time_ms,
            "exit_code": result.returncode,
            "raw_output": raw_output,
            "used_reduced_depth": used_t1
        }

    except subprocess.TimeoutExpired:
        # First attempt timed out - retry with reduced transaction depth
        if retry_with_t1:
            print("TIMEOUT, retrying with -t 1...", end=" ", flush=True)
            retry_start = time.time()
            try:
                # Retry with single transaction depth to avoid path explosion
                cmd_t1 = [str(MYTHRIL_BIN), "analyze", str(contract_path),
                          "-o", "json", "--solv", solc_version,
                          "-t", "1", "--execution-timeout", "60"]
                result = subprocess.run(
                    cmd_t1,
                    capture_output=True,
                    timeout=120,
                    text=True
                )

                total_time_ms = (time.time() - start_time) * 1000

                try:
                    raw_output = json.loads(result.stdout) if result.stdout else {}
                except json.JSONDecodeError:
                    raw_output = {"error": "Failed to parse JSON", "raw": result.stdout[:1000] if result.stdout else ""}

                has_valid_output = "issues" in raw_output or "error" in raw_output

                return {
                    "sample_id": sample_id,
                    "tier": tier,
                    "tool": "mythril",
                    "tool_version": "0.24.8",
                    "solc_version": solc_version,
                    "timestamp": datetime.now().isoformat(),
                    "success": has_valid_output,
                    "error": result.stderr[:500] if not has_valid_output else None,
                    "execution_time_ms": total_time_ms,
                    "exit_code": result.returncode,
                    "raw_output": raw_output,
                    "used_reduced_depth": True
                }
            except subprocess.TimeoutExpired:
                # Even with -t 1, still timed out
                return {
                    "sample_id": sample_id,
                    "tier": tier,
                    "tool": "mythril",
                    "tool_version": "0.24.8",
                    "solc_version": solc_version,
                    "timestamp": datetime.now().isoformat(),
                    "success": False,
                    "error": "Timeout after retry with -t 1",
                    "execution_time_ms": (time.time() - start_time) * 1000,
                    "exit_code": -1,
                    "raw_output": {},
                    "used_reduced_depth": True
                }

        # No retry or retry also failed
        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "mythril",
            "tool_version": "0.24.8",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": f"Timeout after {timeout_sec} seconds",
            "execution_time_ms": (time.time() - start_time) * 1000,
            "exit_code": -1,
            "raw_output": {},
            "used_reduced_depth": used_t1
        }
    except Exception as e:
        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": "mythril",
            "tool_version": "0.24.8",
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": str(e),
            "execution_time_ms": (time.time() - start_time) * 1000,
            "exit_code": -1,
            "raw_output": {},
            "used_reduced_depth": False
        }


def save_result(result: dict, tool: str, tier: str):
    """Save detection result to file."""
    output_dir = RESULTS_DIR / tool / "ds" / tier
    output_dir.mkdir(parents=True, exist_ok=True)

    filename = f"d_{result['sample_id']}.json"
    filepath = output_dir / filename

    with open(filepath, 'w') as f:
        json.dump(result, f, indent=2)

    return filepath


def run_tier(tier: str, tools: list[str] = ["slither", "mythril"]):
    """Run detection on all samples in a tier."""
    tier_dir = SAMPLES_DIR / tier / "contracts"

    if not tier_dir.exists():
        print(f"Tier directory not found: {tier_dir}")
        return

    contracts = sorted(tier_dir.glob("*.sol"))
    print(f"\n{'='*60}")
    print(f"Processing {tier}: {len(contracts)} contracts")
    print(f"{'='*60}")

    for i, contract_path in enumerate(contracts):
        sample_id = contract_path.stem
        print(f"\n[{i+1}/{len(contracts)}] {sample_id}")

        # Check which tools need to run (skip if result already exists)
        tools_to_run = []
        for tool in tools:
            result_path = RESULTS_DIR / tool / "ds" / tier / f"d_{sample_id}.json"
            if result_path.exists():
                print(f"  Skipping {tool} (result exists)")
            else:
                tools_to_run.append(tool)

        if not tools_to_run:
            continue

        # Read contract to detect version
        code = contract_path.read_text()
        solc_version = extract_solidity_version(code)
        print(f"  Detected Solidity version: {solc_version}")

        # Set solc version
        set_solc_version(solc_version)

        # Run Slither
        if "slither" in tools_to_run:
            print(f"  Running Slither...", end=" ", flush=True)
            result = run_slither(contract_path, sample_id, tier, solc_version)
            filepath = save_result(result, "slither", tier)

            if result["success"]:
                detectors = result.get("raw_output", {}).get("results", {}).get("detectors", [])
                print(f"OK ({len(detectors)} findings, {result['execution_time_ms']:.0f}ms)")
            else:
                print(f"FAILED: {result.get('error', 'Unknown error')[:50]}")

        # Run Mythril
        if "mythril" in tools_to_run:
            print(f"  Running Mythril...", end=" ", flush=True)
            result = run_mythril(contract_path, sample_id, tier, solc_version)
            filepath = save_result(result, "mythril", tier)

            if result["success"]:
                issues = result.get("raw_output", {}).get("issues", [])
                print(f"OK ({len(issues)} findings, {result['execution_time_ms']:.0f}ms)")
            else:
                print(f"FAILED: {result.get('error', 'Unknown error')[:50]}")


if __name__ == "__main__":
    import sys

    # Default to tier1, but allow specifying tier
    tier = sys.argv[1] if len(sys.argv) > 1 else "tier1"

    # Allow specifying tools
    tools = sys.argv[2:] if len(sys.argv) > 2 else ["slither", "mythril"]

    print(f"Running traditional detection on DS {tier}")
    print(f"Tools: {', '.join(tools)}")

    run_tier(tier, tools)

    print("\n" + "="*60)
    print("Detection complete!")
    print(f"Results saved to: {RESULTS_DIR}")
