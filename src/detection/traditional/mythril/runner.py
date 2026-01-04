"""
Mythril runner - executes Mythril on Solidity contracts.
"""

import subprocess
import json
import time
from pathlib import Path
from typing import Optional, Literal

from ..base import BaseToolRunner


# Path to Mythril binary in traditionaltools venv
MYTHRIL_VENV = Path(__file__).parents[4] / "traditionaltools" / "mythril" / "venv"
MYTHRIL_BIN = MYTHRIL_VENV / "bin" / "myth"


AnalysisMode = Literal["quick", "standard", "deep"]


class MythrilRunner(BaseToolRunner):
    """Runner for Mythril symbolic execution tool."""

    def __init__(self, tool_version: str = "0.24.8"):
        super().__init__(
            tool_name="mythril",
            tool_version=tool_version,
            bin_path=MYTHRIL_BIN
        )

    def run(
        self,
        contract_path: Path,
        sample_id: str,
        tier: int,
        solc_version: Optional[str] = None,
        analysis_mode: AnalysisMode = "standard",
        timeout: int = 300
    ) -> dict:
        """
        Run Mythril on a contract.

        Args:
            contract_path: Path to the Solidity contract
            sample_id: Sample identifier
            tier: Difficulty tier
            solc_version: Solidity version to use
            analysis_mode: Analysis depth (quick, standard, deep)
            timeout: Timeout in seconds

        Returns:
            dict conforming to mythril_output.schema.json
        """
        start_time = time.time()

        # Build command
        cmd = [
            str(self.bin_path),
            "analyze",
            str(contract_path),
            "--format", "json"
        ]

        # Add solc version if specified
        if solc_version:
            cmd.extend(["--solv", solc_version])

        # Add analysis mode flags
        if analysis_mode == "quick":
            cmd.extend(["--execution-timeout", "60", "--max-depth", "12"])
        elif analysis_mode == "deep":
            cmd.extend(["--execution-timeout", "300", "--max-depth", "50"])
        # standard uses defaults

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                timeout=timeout,
                text=True
            )

            execution_time_ms = (time.time() - start_time) * 1000

            # Parse JSON output
            raw_output = self.parse_output(result.stdout)

            output = self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=True,
                raw_output=raw_output,
                execution_time_ms=execution_time_ms,
                exit_code=result.returncode,
                solc_version=solc_version
            )
            output["timeout"] = False
            output["analysis_mode"] = analysis_mode
            return output

        except subprocess.TimeoutExpired:
            execution_time_ms = (time.time() - start_time) * 1000
            output = self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=False,
                raw_output={},
                error=f"Timeout after {timeout} seconds",
                execution_time_ms=execution_time_ms,
                solc_version=solc_version
            )
            output["timeout"] = True
            output["analysis_mode"] = analysis_mode
            return output

        except Exception as e:
            execution_time_ms = (time.time() - start_time) * 1000
            output = self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=False,
                raw_output={},
                error=str(e),
                execution_time_ms=execution_time_ms,
                solc_version=solc_version
            )
            output["timeout"] = False
            output["analysis_mode"] = analysis_mode
            return output

    def parse_output(self, raw_output: str) -> dict:
        """
        Parse Mythril JSON output.

        Args:
            raw_output: Raw JSON string from Mythril

        Returns:
            Parsed dict
        """
        try:
            return json.loads(raw_output)
        except json.JSONDecodeError:
            return {
                "success": False,
                "error": "Failed to parse JSON output",
                "issues": []
            }
