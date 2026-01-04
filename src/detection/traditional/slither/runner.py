"""
Slither runner - executes Slither on Solidity contracts.
"""

import subprocess
import json
import time
from pathlib import Path
from typing import Optional

from ..base import BaseToolRunner


# Path to Slither binary in traditionaltools venv
SLITHER_VENV = Path(__file__).parents[4] / "traditionaltools" / "slither" / "venv"
SLITHER_BIN = SLITHER_VENV / "bin" / "slither"
SOLC_SELECT_BIN = SLITHER_VENV / "bin" / "solc-select"


class SlitherRunner(BaseToolRunner):
    """Runner for Slither static analysis tool."""

    def __init__(self, tool_version: str = "0.11.3"):
        super().__init__(
            tool_name="slither",
            tool_version=tool_version,
            bin_path=SLITHER_BIN
        )

    def set_solc_version(self, version: str) -> bool:
        """
        Set the Solidity compiler version using solc-select.

        Args:
            version: Solidity version (e.g., "0.8.0")

        Returns:
            True if successful
        """
        try:
            # Install if not available
            subprocess.run(
                [str(SOLC_SELECT_BIN), "install", version],
                capture_output=True,
                timeout=60
            )
            # Use the version
            result = subprocess.run(
                [str(SOLC_SELECT_BIN), "use", version],
                capture_output=True,
                timeout=10
            )
            return result.returncode == 0
        except Exception:
            return False

    def run(
        self,
        contract_path: Path,
        sample_id: str,
        tier: int,
        solc_version: Optional[str] = None,
        timeout: int = 300
    ) -> dict:
        """
        Run Slither on a contract.

        Args:
            contract_path: Path to the Solidity contract
            sample_id: Sample identifier
            tier: Difficulty tier
            solc_version: Solidity version to use
            timeout: Timeout in seconds

        Returns:
            dict conforming to slither_output.schema.json
        """
        # Set solc version if specified
        if solc_version:
            self.set_solc_version(solc_version)

        start_time = time.time()

        try:
            result = subprocess.run(
                [str(self.bin_path), str(contract_path), "--json", "-"],
                capture_output=True,
                timeout=timeout,
                text=True
            )

            execution_time_ms = (time.time() - start_time) * 1000

            # Parse JSON output
            raw_output = self.parse_output(result.stdout)

            return self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=True,
                raw_output=raw_output,
                execution_time_ms=execution_time_ms,
                exit_code=result.returncode,
                solc_version=solc_version
            )

        except subprocess.TimeoutExpired:
            execution_time_ms = (time.time() - start_time) * 1000
            return self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=False,
                raw_output={},
                error=f"Timeout after {timeout} seconds",
                execution_time_ms=execution_time_ms,
                solc_version=solc_version
            )

        except Exception as e:
            execution_time_ms = (time.time() - start_time) * 1000
            return self.create_wrapper_output(
                sample_id=sample_id,
                tier=tier,
                success=False,
                raw_output={},
                error=str(e),
                execution_time_ms=execution_time_ms,
                solc_version=solc_version
            )

    def parse_output(self, raw_output: str) -> dict:
        """
        Parse Slither JSON output.

        Args:
            raw_output: Raw JSON string from Slither

        Returns:
            Parsed dict
        """
        try:
            return json.loads(raw_output)
        except json.JSONDecodeError:
            return {
                "success": False,
                "error": "Failed to parse JSON output",
                "results": {"detectors": []}
            }
