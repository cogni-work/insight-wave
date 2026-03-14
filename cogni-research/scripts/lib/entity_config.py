#!/usr/bin/env python3
"""
entity_config.py
Version: 1.0.0
Purpose: Python interface to centralized entity schema configuration

Provides functions to read entity configuration from the central
JSON config file (entity-schema.json).

Usage:
    from lib.entity_config import get_directory_by_key, get_entity_dirs

    # Get directory for a key
    findings_dir = get_directory_by_key("findings")  # Returns "04-findings"

    # Get all entity directories mapping
    dirs = get_entity_dirs()  # Returns {"findings": "04-findings", ...}

Functions:
    get_config_path()        - Get path to entity-schema.json
    get_entity_dirs()        - Get key->directory mapping
    get_directory_by_key()   - Resolve key to directory name
    get_key_by_directory()   - Resolve directory to key
    get_data_subdir()        - Get data subdirectory name (typically "data")
    get_entity_prefix()      - Get prefix for entity type
    needs_deduplication()    - Check if type needs dedup
"""

import json
from pathlib import Path
from typing import Dict, Optional

# Cache the config to avoid repeated file reads
_config_cache: Optional[dict] = None


def get_config_path() -> Path:
    """Get path to entity-schema.json."""
    # From scripts/lib/ -> scripts/ -> cogni-research/ -> config/
    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / ".." / ".." / "config" / "entity-schema.json"
    return config_path.resolve()


def _load_config() -> dict:
    """Load and cache the entity schema config."""
    global _config_cache
    if _config_cache is None:
        config_path = get_config_path()
        if not config_path.exists():
            raise FileNotFoundError(f"Entity schema config not found: {config_path}")
        with open(config_path, 'r', encoding='utf-8') as f:
            _config_cache = json.load(f)
    return _config_cache


def get_entity_dirs() -> Dict[str, str]:
    """
    Get mapping of entity key to directory name.

    Returns:
        Dict mapping keys to directories, e.g.:
        {"findings": "04-findings", "sources": "07-sources", ...}
    """
    config = _load_config()
    return {et["key"]: et["directory"] for et in config["entity_types"]}


def get_directory_by_key(key: str) -> str:
    """
    Resolve entity key to directory name.

    Args:
        key: Entity key like "findings", "sources", "research-synthesis"

    Returns:
        Directory name like "04-findings", "07-sources", "11-trends"

    Raises:
        KeyError: If key not found in config
    """
    dirs = get_entity_dirs()
    if key not in dirs:
        raise KeyError(f"Unknown entity key: {key}. Valid keys: {list(dirs.keys())}")
    return dirs[key]


def get_key_by_directory(directory: str) -> str:
    """
    Resolve directory name to entity key.

    Args:
        directory: Directory name like "04-findings"

    Returns:
        Entity key like "findings"

    Raises:
        KeyError: If directory not found in config
    """
    config = _load_config()
    for et in config["entity_types"]:
        if et["directory"] == directory:
            return et["key"]
    raise KeyError(f"Unknown directory: {directory}")


def get_data_subdir() -> str:
    """Get the data subdirectory name (typically 'data')."""
    config = _load_config()
    return config["entity_types"][0].get("data_subdir", "data")


def get_entity_prefix(directory: str) -> str:
    """
    Get the entity file prefix for a directory.

    Args:
        directory: Directory name like "04-findings"

    Returns:
        Prefix like "finding"
    """
    config = _load_config()
    for et in config["entity_types"]:
        if et["directory"] == directory:
            return et["prefix"]
    raise KeyError(f"Unknown directory: {directory}")


def needs_deduplication(directory: str) -> bool:
    """
    Check if entity type requires deduplication.

    Args:
        directory: Directory name like "07-sources"

    Returns:
        True if deduplication is enabled for this type
    """
    config = _load_config()
    for et in config["entity_types"]:
        if et["directory"] == directory:
            return et.get("dedupe", False)
    return False


def get_schema_version() -> str:
    """Get the schema version string."""
    config = _load_config()
    return config.get("version", "unknown")


def get_special_directories() -> list:
    """Get list of special (non-entity) directories."""
    config = _load_config()
    return config.get("special_directories", [])


# Convenience: pre-built mappings for common use cases
def get_type_map() -> Dict[str, tuple]:
    """
    Get mapping for citation rendering (directory -> (singular, plural)).

    Returns:
        Dict like {"04-findings": ("finding", "findings"), ...}
    """
    config = _load_config()
    return {
        et["directory"]: (et["singular"], et["plural"])
        for et in config["entity_types"]
    }


if __name__ == "__main__":
    # Test the module
    print(f"Config path: {get_config_path()}")
    print(f"Schema version: {get_schema_version()}")
    print(f"Entity dirs: {get_entity_dirs()}")
    print(f"findings -> {get_directory_by_key('findings')}")
    print(f"research-synthesis -> {get_directory_by_key('research-synthesis')}")
    print(f"Data subdir: {get_data_subdir()}")
