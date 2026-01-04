"""
Utility modules for BlockBench.
"""

from .config import (
    PathConfig,
    APIConfig,
    DetectionConfig,
    EvaluationConfig,
    BlockBenchConfig,
    get_config,
    set_config,
)
from .logging import (
    setup_logging,
    get_logger,
    ProgressLogger,
)
from .json_utils import (
    save_json,
    load_json,
    safe_load_json,
    merge_json_files,
    validate_json_schema,
    DateTimeEncoder,
)
from .solidity import (
    extract_contract_name,
    extract_all_contracts,
    extract_solidity_version,
    extract_functions,
    has_vulnerability_pattern,
    normalize_code,
    count_lines,
)


__all__ = [
    # Config
    "PathConfig",
    "APIConfig",
    "DetectionConfig",
    "EvaluationConfig",
    "BlockBenchConfig",
    "get_config",
    "set_config",
    # Logging
    "setup_logging",
    "get_logger",
    "ProgressLogger",
    # JSON
    "save_json",
    "load_json",
    "safe_load_json",
    "merge_json_files",
    "validate_json_schema",
    "DateTimeEncoder",
    # Solidity
    "extract_contract_name",
    "extract_all_contracts",
    "extract_solidity_version",
    "extract_functions",
    "has_vulnerability_pattern",
    "normalize_code",
    "count_lines",
]
