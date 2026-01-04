"""
Base class for traditional tool wrappers.
"""

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional
from datetime import datetime


class BaseToolRunner(ABC):
    """Abstract base class for traditional security analysis tools."""

    def __init__(self, tool_name: str, tool_version: str, bin_path: Path):
        self.tool_name = tool_name
        self.tool_version = tool_version
        self.bin_path = bin_path

    @abstractmethod
    def run(self, contract_path: Path, **kwargs) -> dict:
        """
        Run the tool on a contract.

        Args:
            contract_path: Path to the Solidity contract
            **kwargs: Tool-specific options

        Returns:
            dict conforming to tool output schema
        """
        pass

    @abstractmethod
    def parse_output(self, raw_output: str) -> dict:
        """
        Parse raw tool output into structured format.

        Args:
            raw_output: Raw output from the tool

        Returns:
            Parsed output dict
        """
        pass

    def create_wrapper_output(
        self,
        sample_id: str,
        tier: int,
        success: bool,
        raw_output: dict,
        error: Optional[str] = None,
        execution_time_ms: Optional[float] = None,
        exit_code: Optional[int] = None,
        solc_version: Optional[str] = None
    ) -> dict:
        """
        Create wrapper output conforming to schema.

        Returns:
            dict conforming to slither_output.schema.json or mythril_output.schema.json
        """
        return {
            "sample_id": sample_id,
            "tier": tier,
            "tool": self.tool_name,
            "tool_version": self.tool_version,
            "solc_version": solc_version,
            "timestamp": datetime.now().isoformat(),
            "success": success,
            "error": error,
            "execution_time_ms": execution_time_ms,
            "exit_code": exit_code,
            "raw_output": raw_output
        }
