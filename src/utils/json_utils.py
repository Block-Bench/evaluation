"""
JSON utilities for BlockBench.
"""

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional


class DateTimeEncoder(json.JSONEncoder):
    """JSON encoder that handles datetime objects."""

    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, Path):
            return str(obj)
        return super().default(obj)


def save_json(
    data: Any,
    filepath: Path,
    indent: int = 2,
    ensure_ascii: bool = False
) -> None:
    """
    Save data to JSON file.

    Args:
        data: Data to save
        filepath: Output file path
        indent: JSON indentation
        ensure_ascii: Whether to escape non-ASCII characters
    """
    filepath = Path(filepath)
    filepath.parent.mkdir(parents=True, exist_ok=True)

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=indent, ensure_ascii=ensure_ascii, cls=DateTimeEncoder)


def load_json(filepath: Path) -> Any:
    """
    Load data from JSON file.

    Args:
        filepath: Input file path

    Returns:
        Loaded data
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def safe_load_json(filepath: Path, default: Any = None) -> Any:
    """
    Safely load JSON file, returning default on error.

    Args:
        filepath: Input file path
        default: Default value if file doesn't exist or is invalid

    Returns:
        Loaded data or default
    """
    try:
        return load_json(filepath)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def merge_json_files(
    filepaths: list[Path],
    output_path: Path,
    key: Optional[str] = None
) -> None:
    """
    Merge multiple JSON files into one.

    Args:
        filepaths: List of input files
        output_path: Output file path
        key: If provided, merge into dict using this key from each file
    """
    if key:
        merged = {}
        for fp in filepaths:
            data = load_json(fp)
            if isinstance(data, dict) and key in data:
                merged[data[key]] = data
    else:
        merged = []
        for fp in filepaths:
            data = load_json(fp)
            if isinstance(data, list):
                merged.extend(data)
            else:
                merged.append(data)

    save_json(merged, output_path)


def validate_json_schema(
    data: dict,
    schema_path: Path
) -> tuple[bool, list[str]]:
    """
    Validate JSON data against a schema.

    Args:
        data: Data to validate
        schema_path: Path to JSON schema file

    Returns:
        Tuple of (is_valid, list of error messages)
    """
    try:
        import jsonschema
    except ImportError:
        return True, ["jsonschema not installed, skipping validation"]

    schema = load_json(schema_path)

    try:
        jsonschema.validate(data, schema)
        return True, []
    except jsonschema.ValidationError as e:
        return False, [str(e)]
    except jsonschema.SchemaError as e:
        return False, [f"Schema error: {e}"]
