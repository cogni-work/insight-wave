"""
Entity Configuration Loader
============================

Single source of truth for entity directory structure.
Loads from cogni-research/config/entity-schema.json

This module provides centralized access to entity type definitions,
eliminating hardcoded lists scattered across multiple files.

Functions:
    load_entity_config() - Load and cache configuration
    get_valid_entity_types() - Return ordered list of entity directories
    get_type_prefixes() - Return {directory: prefix} mapping
    get_dedupe_types() - Return set of types requiring deduplication
    get_required_fields() - Return {directory: [fields]} for dedupe types
    get_entity_data_path(project_path, entity_type) - Get data subdir path
    get_wikilink_pattern(entity_type) - Generate wikilink regex pattern
    get_directory_by_key(key) - Resolve key to directory name
    get_key_by_directory(directory) - Resolve directory to key
    get_all_keys() - Return all key→directory mappings
    resolve_entity_variables(template) - Resolve {{key}} placeholders
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Set

__version__ = "1.1.0"

# Cache for loaded config
_config_cache: Optional[Dict] = None


def _find_config_path() -> Path:
    """Locate entity-schema.json relative to this module or via env var.

    Search order:
    1. CLAUDE_PLUGIN_ROOT/config/entity-schema.json (plugin root)
    2. COGNI_RESEARCH_ROOT/config/entity-schema.json
    3. Bundled location: scripts/shared_utils -> scripts -> plugin root -> config

    Returns:
        Path to entity-schema.json

    Raises:
        FileNotFoundError: If config file cannot be located
    """
    # Try CLAUDE_PLUGIN_ROOT first (points directly to plugin directory)
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if plugin_root:
        config_path = Path(plugin_root) / "config" / "entity-schema.json"
        if config_path.exists():
            return config_path

    # Try COGNI_RESEARCH_ROOT
    agents_root = os.environ.get("COGNI_RESEARCH_ROOT")
    if agents_root:
        config_path = Path(agents_root) / "config" / "entity-schema.json"
        if config_path.exists():
            return config_path

    # Bundled mode: scripts/shared_utils/entity_config.py -> scripts/shared_utils -> scripts -> plugin -> config
    utils_dir = Path(__file__).resolve().parent
    bundled_config = utils_dir.parent.parent / "config" / "entity-schema.json"
    if bundled_config.exists():
        return bundled_config

    raise FileNotFoundError(
        f"Entity schema config not found. Searched:\n"
        f"  CLAUDE_PLUGIN_ROOT: {plugin_root}\n"
        f"  COGNI_RESEARCH_ROOT: {agents_root}\n"
        f"  Bundled: {bundled_config}"
    )


def load_entity_config(force_reload: bool = False) -> Dict:
    """Load entity schema configuration with caching.

    Args:
        force_reload: If True, bypass cache and reload from disk

    Returns:
        Dictionary containing full entity schema configuration
    """
    global _config_cache
    if _config_cache is None or force_reload:
        config_path = _find_config_path()
        with open(config_path, 'r', encoding='utf-8') as f:
            _config_cache = json.load(f)
    return _config_cache


def get_valid_entity_types() -> List[str]:
    """Return ordered list of entity type directory names.

    Returns:
        List like ["00-initial-question", "01-research-dimensions", ...]
    """
    config = load_entity_config()
    return [et["directory"] for et in config["entity_types"]]


def get_type_prefixes() -> Dict[str, str]:
    """Return mapping of directory name to ID prefix.

    Returns:
        Dict like {"04-findings": "finding", "07-sources": "source", ...}
    """
    config = load_entity_config()
    return {et["directory"]: et["prefix"] for et in config["entity_types"]}


def get_dedupe_types() -> Set[str]:
    """Return set of entity types requiring deduplication.

    Returns:
        Set like {"07-sources", "08-publishers"}
    """
    config = load_entity_config()
    return {et["directory"] for et in config["entity_types"] if et.get("dedupe", False)}


def get_required_fields() -> Dict[str, List[str]]:
    """Return mapping of directory to required frontmatter fields.

    Only includes types that have required fields defined.

    Returns:
        Dict like {"07-sources": ["name", "url", "domain", "title"], ...}
    """
    config = load_entity_config()
    return {
        et["directory"]: et["required_fields"]
        for et in config["entity_types"]
        if et.get("required_fields")
    }


def get_data_subdir() -> str:
    """Return the data subdirectory name from config.

    Returns:
        Subdirectory name (typically "data")
    """
    config = load_entity_config()
    # All entity types use the same data_subdir, get from first entity
    if config["entity_types"]:
        return config["entity_types"][0].get("data_subdir", "data")
    return "data"


def get_entity_data_path(project_path: str, entity_type: str) -> Path:
    """Get the full path to an entity type's data subdirectory.

    Args:
        project_path: Root path of the research project
        entity_type: Entity type directory name (e.g., "04-findings")

    Returns:
        Path like /project/04-findings/data/
    """
    data_subdir = get_data_subdir()
    return Path(project_path) / entity_type / data_subdir


def get_special_directories() -> List[str]:
    """Return list of special (non-entity) directories.

    Returns:
        List like [".metadata", ".logs", ".locks"]
    """
    config = load_entity_config()
    return config.get("special_directories", [".metadata", ".logs", ".locks"])


def get_entity_config_by_directory(directory: str) -> Optional[Dict]:
    """Get full configuration for a specific entity type.

    Args:
        directory: Entity type directory name (e.g., "04-findings")

    Returns:
        Full entity config dict or None if not found
    """
    config = load_entity_config()
    for et in config["entity_types"]:
        if et["directory"] == directory:
            return et
    return None


def get_wikilink_pattern(entity_type: str) -> Optional[str]:
    """Generate wikilink regex pattern for an entity type.

    Args:
        entity_type: Entity type directory name (e.g., "04-findings")

    Returns:
        Regex pattern string or None if entity type not found
    """
    config = load_entity_config()
    template = config.get("wikilink_pattern_template")
    if not template:
        return None

    et_config = get_entity_config_by_directory(entity_type)
    if not et_config:
        return None

    return template.format(
        directory=et_config["directory"],
        prefix=et_config["prefix"]
    )


def get_schema_version() -> str:
    """Return the schema version string.

    Returns:
        Version string like "2.0.0"
    """
    config = load_entity_config()
    return config.get("version", "1.0.0")


def get_directory_by_key(key: str) -> Optional[str]:
    """Resolve entity key to directory name.

    Args:
        key: Logical alias (e.g., "findings", "sources")

    Returns:
        Directory name (e.g., "04-findings") or None if not found

    Example:
        >>> get_directory_by_key("findings")
        "04-findings"
    """
    config = load_entity_config()
    for et in config["entity_types"]:
        if et.get("key") == key:
            return et["directory"]
    return None


def get_key_by_directory(directory: str) -> Optional[str]:
    """Resolve directory name to entity key.

    Args:
        directory: Directory name (e.g., "04-findings")

    Returns:
        Logical key (e.g., "findings") or None if not found

    Example:
        >>> get_key_by_directory("04-findings")
        "findings"
    """
    config = load_entity_config()
    for et in config["entity_types"]:
        if et["directory"] == directory:
            return et.get("key")
    return None


def get_all_keys() -> Dict[str, str]:
    """Return mapping of all keys to directories.

    Returns:
        Dict like {"findings": "04-findings", "sources": "07-sources", ...}
    """
    config = load_entity_config()
    return {et["key"]: et["directory"] for et in config["entity_types"] if "key" in et}


def resolve_entity_variables(template: str, project_path: str = "") -> str:
    """Resolve entity directory placeholders in template strings.

    Supports two syntaxes:
    - {{key}}: Resolves to directory name (e.g., "04-findings")
    - {{key_path}}: Resolves to full path (requires project_path)

    Args:
        template: String containing {{key}} placeholders
        project_path: Optional project path for {{key_path}} resolution

    Returns:
        Template with placeholders resolved

    Example:
        >>> resolve_entity_variables("Read from {{findings}}/data/")
        "Read from 04-findings/data/"

        >>> resolve_entity_variables("{{findings_path}}", "/home/project")
        "/home/project/04-findings"
    """
    key_map = get_all_keys()

    def replace_match(match):
        placeholder = match.group(1)

        # Handle _path suffix
        if placeholder.endswith("_path"):
            key = placeholder[:-5]  # Remove "_path"
            directory = key_map.get(key)
            if directory and project_path:
                return str(Path(project_path) / directory)
            return match.group(0)  # Keep original if no project_path

        # Direct key resolution
        return key_map.get(placeholder, match.group(0))

    return re.sub(r'\{\{([a-z_-]+)\}\}', replace_match, template)


# Convenience constants for backward compatibility
# These are evaluated at import time, so config must be loadable
def _init_compat_constants():
    """Initialize backward-compatible constants."""
    try:
        return {
            "VALID_ENTITY_TYPES": get_valid_entity_types(),
            "TYPE_PREFIXES": get_type_prefixes(),
            "DEDUPE_TYPES": get_dedupe_types(),
            "REQUIRED_FIELDS": get_required_fields(),
        }
    except FileNotFoundError:
        # Return empty defaults if config not found (allows import without config)
        return {
            "VALID_ENTITY_TYPES": [],
            "TYPE_PREFIXES": {},
            "DEDUPE_TYPES": set(),
            "REQUIRED_FIELDS": {},
        }
