#!/usr/bin/env python3
"""
script_output.py
Version: 1.0.0
Purpose: JSON output helpers matching bash script JSON contract

This module provides standardized output functions that match the existing
bash script JSON contract used throughout the Claude Code plugin framework.

JSON Contract:
    {
        "success": true|false,
        "data": {...},           # Present on success
        "error": "message",      # Present on failure
        "error_code": 123        # Optional error code
    }

Exit Codes:
    0 - Success
    1 - Validation/processing error
    2 - Invalid arguments
    3 - Path/file not found error

Usage:
    from script_output import output_success, output_error, ExitCode

    # Success with data
    output_success({"entity_path": "/path/to/entity.md", "entity_id": "abc123"})

    # Error with message
    output_error("File not found", ExitCode.PATH_ERROR)

    # Error with additional context
    output_error("Validation failed", ExitCode.VALIDATION, field="name", expected="string")
"""

import json
import sys
from enum import IntEnum
from typing import Any, Dict, NoReturn, Optional


class ExitCode(IntEnum):
    """Exit codes matching bash script conventions."""
    SUCCESS = 0
    VALIDATION = 1      # Validation or processing error
    ARGUMENTS = 2       # Invalid arguments
    PATH_ERROR = 3      # Path or file not found


def output_success(data: Optional[Dict[str, Any]] = None, **extra_fields) -> NoReturn:
    """
    Output success JSON to stdout and exit with code 0.

    Args:
        data: Optional dictionary of result data
        **extra_fields: Additional top-level fields to include

    Example:
        output_success({"entity_path": "/path", "entity_id": "123"})
        # Outputs: {"success": true, "entity_path": "/path", "entity_id": "123"}

        output_success(entity_path="/path", entity_id="123", reused=False)
        # Outputs: {"success": true, "entity_path": "/path", "entity_id": "123", "reused": false}
    """
    result: Dict[str, Any] = {"success": True}

    if data:
        result.update(data)

    if extra_fields:
        result.update(extra_fields)

    print(json.dumps(result, ensure_ascii=False))
    sys.exit(ExitCode.SUCCESS)


def output_error(
    message: str,
    code: ExitCode = ExitCode.VALIDATION,
    **extra_fields
) -> NoReturn:
    """
    Output error JSON to stdout and exit with specified code.

    Note: Outputs to stdout (not stderr) to match bash script convention
    where all JSON goes to stdout for consistent parsing by callers.

    Args:
        message: Error message
        code: Exit code (default: VALIDATION)
        **extra_fields: Additional context fields (error_code, field, expected, etc.)

    Example:
        output_error("File not found", ExitCode.PATH_ERROR, path="/missing/file")
        # Outputs: {"success": false, "error": "File not found", "path": "/missing/file"}
        # Exits with code 3
    """
    result: Dict[str, Any] = {
        "success": False,
        "error": message
    }

    if extra_fields:
        result.update(extra_fields)

    print(json.dumps(result, ensure_ascii=False))
    sys.exit(code)


def output_json(data: Dict[str, Any], indent: Optional[int] = None) -> None:
    """
    Output arbitrary JSON to stdout without exiting.

    Useful for streaming output or when you need to control exit separately.

    Args:
        data: Dictionary to output as JSON
        indent: Optional indentation for pretty-printing
    """
    print(json.dumps(data, ensure_ascii=False, indent=indent))


def parse_json_arg(value: str, arg_name: str = "data") -> Dict[str, Any]:
    """
    Parse a JSON string argument, handling both inline JSON and @file.json syntax.

    Args:
        value: JSON string or @filepath
        arg_name: Name of argument for error messages

    Returns:
        Parsed dictionary

    Raises:
        Calls output_error and exits on parse failure
    """
    try:
        # Handle @file.json syntax (load from file)
        if value.startswith("@"):
            filepath = value[1:]
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    return json.load(f)
            except FileNotFoundError:
                output_error(
                    f"JSON file not found: {filepath}",
                    ExitCode.PATH_ERROR,
                    arg=arg_name,
                    path=filepath
                )
            except PermissionError:
                output_error(
                    f"Permission denied reading: {filepath}",
                    ExitCode.PATH_ERROR,
                    arg=arg_name,
                    path=filepath
                )

        # Parse inline JSON
        return json.loads(value)

    except json.JSONDecodeError as e:
        output_error(
            f"Invalid JSON in {arg_name}: {e.msg}",
            ExitCode.ARGUMENTS,
            arg=arg_name,
            position=e.pos
        )


# For backwards compatibility and convenience
success = output_success
error = output_error
