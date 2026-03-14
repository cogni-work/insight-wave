"""
Entity Operations for Claude Code Plugins
==========================================

Entity creation, validation, and ID generation operations.
Core logic for create-entity.py.

Constants:
    DEDUPE_TYPES - Entity types requiring deduplication
    REQUIRED_FIELDS - Required frontmatter fields by entity type
    TYPE_PREFIXES - Entity ID prefixes by entity type

Functions:
    validate_entity_type(entity_type) - Check if entity type is valid
    validate_frontmatter(frontmatter, entity_type) - Validate required fields
    validate_batch_ref(frontmatter, project_path) - Validate batch reference
    validate_question_ref(frontmatter, project_path) - Validate question reference
    needs_deduplication(entity_type) - Check if type needs dedup
    generate_entity_id(entity_type, custom_id, content, deterministic) - Generate ID
    get_type_prefix(entity_type) - Get singular prefix for entity type
    generate_yaml_frontmatter(data) - Convert dict to YAML frontmatter
"""

import hashlib
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

__version__ = "1.1.0"

# Import from central config (try relative import first for package usage)
try:
    from .entity_config import (
        get_valid_entity_types,
        get_type_prefixes,
        get_dedupe_types,
        get_required_fields,
        get_directory_by_key,
        load_entity_config,
    )
    from .entity_index import VALID_ENTITY_TYPES
except ImportError:
    from entity_config import (
        get_valid_entity_types,
        get_type_prefixes,
        get_dedupe_types,
        get_required_fields,
        get_directory_by_key,
        load_entity_config,
    )
    from entity_index import VALID_ENTITY_TYPES

# Entity types requiring deduplication (loaded from config)
DEDUPE_TYPES = get_dedupe_types()

# Required frontmatter fields by entity type (loaded from config)
REQUIRED_FIELDS: Dict[str, List[str]] = get_required_fields()

# Entity ID prefixes (singular form) (loaded from config)
TYPE_PREFIXES: Dict[str, str] = get_type_prefixes()


def _now_iso() -> str:
    """Get current timestamp in ISO 8601 UTC format."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def validate_entity_type(entity_type: str) -> Tuple[bool, str, str]:
    """Validate and resolve entity type.

    Supports aliases like "finding" or "findings" in addition to full
    directory names like "04-findings".

    Args:
        entity_type: Entity type string (e.g., "07-sources", "sources", "source")

    Returns:
        Tuple of (valid: bool, error_message: str, resolved_type: str)
    """
    if not entity_type:
        return False, "Entity type is required", ""

    # Direct match - already a valid directory name
    if entity_type in VALID_ENTITY_TYPES:
        return True, "", entity_type

    # Try key alias (e.g., "findings" → "04-findings")
    resolved = get_directory_by_key(entity_type)
    if resolved:
        return True, "", resolved

    # Try singular form (e.g., "finding" → "findings" → "04-findings")
    resolved = get_directory_by_key(entity_type + "s")
    if resolved:
        return True, "", resolved

    # Try matching by singular or prefix field (e.g., "dimension" → "01-research-dimensions")
    config = load_entity_config()
    for et in config["entity_types"]:
        if et.get("singular") == entity_type or et.get("prefix") == entity_type:
            return True, "", et["directory"]

    valid_types = ", ".join(VALID_ENTITY_TYPES)
    return False, f"Invalid entity type: {entity_type}. Valid: {valid_types}", ""


def validate_frontmatter(
    frontmatter: Dict[str, Any],
    entity_type: str
) -> Tuple[bool, List[str]]:
    """Validate frontmatter has required fields for entity type.

    Args:
        frontmatter: Frontmatter dictionary
        entity_type: Entity type string

    Returns:
        Tuple of (valid: bool, missing_fields: List[str])
    """
    required = REQUIRED_FIELDS.get(entity_type, [])
    if not required:
        return True, []

    missing = []
    for field in required:
        value = frontmatter.get(field)
        if value is None or value == "" or value == "null":
            missing.append(field)

    return len(missing) == 0, missing


def validate_batch_ref(
    frontmatter: Dict[str, Any],
    project_path: str
) -> Tuple[bool, str]:
    """Validate batch_ref for finding entities (04-findings).

    Args:
        frontmatter: Frontmatter dictionary
        project_path: Absolute path to project root

    Returns:
        Tuple of (valid: bool, error_message: str)

    Checks:
        1. batch_ref field exists
        2. Referenced batch file exists
        3. Batch file has content (>500 bytes)
        4. Batch file has question_ref wikilink
        5. Batch is indexed in entity-index.json (not orphaned)
    """
    batch_ref = frontmatter.get("batch_ref", "")

    # Check 1a: Type check (catches malformed JSON input)
    if batch_ref is not None and not isinstance(batch_ref, str):
        return False, f"batch_ref has wrong type: expected string wikilink, got {type(batch_ref).__name__}"

    # Check 1b: batch_ref exists and is not empty
    if not batch_ref or batch_ref == "null":
        return False, "batch_ref is empty or missing - verify JSON input was not corrupted"

    # Extract batch path from wikilink: [[03-query-batches/data/batch-id]] -> 03-query-batches/data/batch-id
    batch_path = batch_ref.replace("[[", "").replace("]]", "").strip()
    batch_file = Path(project_path) / f"{batch_path}.md"

    # Check 2: Batch file exists
    if not batch_file.exists():
        return False, f"Cannot create finding: batch entity not found at {batch_file}"

    # Check 3: Batch file has content (>500 bytes)
    try:
        file_size = batch_file.stat().st_size
        if file_size < 500:
            return False, f"Cannot create finding: batch entity is empty or incomplete ({file_size} bytes)"
    except OSError as e:
        return False, f"Cannot check batch file size: {e}"

    # Check 4: Batch has question_ref wikilink
    try:
        content = batch_file.read_text(encoding="utf-8")
        if not re.search(r"question_ref:.*\[\[02-refined-questions/data/", content):
            return False, "Cannot create finding: batch entity missing question_ref wikilink"
    except OSError as e:
        return False, f"Cannot read batch file: {e}"

    # Check 5: Batch is indexed (not orphaned)
    # Extract batch ID from path: 03-query-batches/data/batch-uuid -> batch-uuid
    batch_id = batch_path.split("/")[-1]
    index_path = Path(project_path) / "entity-index.json"
    if index_path.exists():
        try:
            import json
            index_data = json.loads(index_path.read_text(encoding="utf-8"))
            batch_entries = index_data.get("03-query-batches", [])
            batch_ids_in_index = [entry.get("id", "") for entry in batch_entries]
            if batch_id not in batch_ids_in_index:
                return False, f"Cannot create finding: batch '{batch_id}' exists on disk but not in entity-index.json (orphaned)"
        except (json.JSONDecodeError, OSError) as e:
            # Log warning but don't fail - index check is advisory
            pass

    return True, ""


def validate_question_ref(
    frontmatter: Dict[str, Any],
    project_path: str
) -> Tuple[bool, str]:
    """Validate question_ref for finding entities (04-findings).

    Prevents LLM hallucination errors where incorrect directory names
    (e.g., '02-query-batches') are used instead of '02-refined-questions'.

    Args:
        frontmatter: Frontmatter dictionary
        project_path: Absolute path to project root

    Returns:
        Tuple of (valid: bool, error_message: str)

    Checks:
        1. question_ref field exists and is a string
        2. Format matches [[02-refined-questions/data/...]]
        3. Referenced question file exists (advisory, non-blocking)
    """
    question_ref = frontmatter.get("question_ref", "")

    # Check 1a: Type check (catches malformed JSON input)
    if question_ref is not None and not isinstance(question_ref, str):
        return False, f"question_ref has wrong type: expected string wikilink, got {type(question_ref).__name__}"

    # Check 1b: question_ref exists and is not empty
    if not question_ref or question_ref == "null":
        return False, "question_ref is empty or missing"

    # Check 2: Format validation - must point to 02-refined-questions
    if not re.search(r"^\[\[02-refined-questions/data/", question_ref):
        return False, f"question_ref has invalid directory: expected [[02-refined-questions/data/...]], got {question_ref}"

    # Check 3: Question file exists (advisory - warn but don't fail)
    question_path = question_ref.replace("[[", "").replace("]]", "").strip()
    question_file = Path(project_path) / f"{question_path}.md"
    if not question_file.exists():
        # Advisory warning - don't fail, but log if not in quiet mode
        import os
        if not os.environ.get("QUIET_MODE"):
            import sys
            print(f"WARN: question_ref points to non-existent file: {question_file}", file=sys.stderr)

    return True, ""


def needs_deduplication(entity_type: str) -> bool:
    """Check if entity type requires deduplication.

    Args:
        entity_type: Entity type string

    Returns:
        True if entity type needs deduplication
    """
    return entity_type in DEDUPE_TYPES


def get_type_prefix(entity_type: str) -> str:
    """Get singular prefix for entity type.

    Args:
        entity_type: Entity type string (e.g., "07-sources")

    Returns:
        Singular prefix (e.g., "source")
    """
    if entity_type in TYPE_PREFIXES:
        return TYPE_PREFIXES[entity_type]

    # Fallback: extract after first dash and remove trailing 's'
    parts = entity_type.split("-", 1)
    if len(parts) > 1:
        prefix = parts[1].rstrip("s")
        return prefix

    return entity_type


def generate_entity_id(
    entity_type: str,
    custom_id: Optional[str] = None,
    content: Optional[str] = None,
    deterministic: bool = False
) -> str:
    """Generate entity ID.

    Priority:
        1. custom_id - Use as-is (caller controls full name)
        2. deterministic - Generate from content hash
        3. random - Generate random UUID v4

    Args:
        entity_type: Entity type for prefix
        custom_id: Custom entity ID (used as-is)
        content: Content for deterministic hash
        deterministic: Use content-based hash instead of random

    Returns:
        Entity ID string
    """
    if custom_id:
        return custom_id

    if deterministic and content:
        # Deterministic UUID from content hash
        content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
        id_uuid = f"{content_hash[:8]}-{content_hash[8:12]}-{content_hash[12:16]}-{content_hash[16:20]}-{content_hash[20:32]}"
    else:
        # Random UUID v4
        id_uuid = str(uuid.uuid4())

    # Add type prefix
    prefix = get_type_prefix(entity_type)
    return f"{prefix}-{id_uuid}"


def _needs_yaml_quoting(value: str) -> bool:
    """Check if string value needs YAML quoting.

    Args:
        value: String to check

    Returns:
        True if value needs quotes
    """
    if not value:
        return True

    # Check patterns that need quoting
    patterns = [
        r"^[0-9]",                          # Starts with digit
        r"^(true|false|null|yes|no|on|off)$",  # YAML keywords (case insensitive)
        r"[:#{}[\],&*?|<>=!%@`']",          # Special YAML chars
        r"^\s",                              # Leading whitespace
        r"\s$",                              # Trailing whitespace
        r"\[\[.*\]\]",                       # Wikilinks
        r"://",                              # URLs
    ]

    for pattern in patterns:
        if re.search(pattern, value, re.IGNORECASE):
            return True

    return False


def _to_yaml_value(value: Any, indent: int = 0) -> str:
    """Convert Python value to YAML string representation.

    Args:
        value: Value to convert
        indent: Current indentation level

    Returns:
        YAML string representation
    """
    if value is None:
        return "null"

    if isinstance(value, bool):
        return "true" if value else "false"

    if isinstance(value, (int, float)):
        return str(value)

    if isinstance(value, str):
        if _needs_yaml_quoting(value):
            # Escape backslashes and quotes
            escaped = value.replace("\\", "\\\\").replace('"', '\\"')
            return f'"{escaped}"'
        return value

    if isinstance(value, list):
        if not value:
            return "[]"
        # Inline format for short arrays
        if all(isinstance(v, (str, int, float, bool)) or v is None for v in value):
            items = [_to_yaml_value(v) for v in value]
            inline = f"[{', '.join(items)}]"
            if len(inline) < 80:
                return inline
        # Multi-line format
        lines = []
        for item in value:
            item_yaml = _to_yaml_value(item, indent + 2)
            lines.append(f"\n{'  ' * (indent // 2 + 1)}- {item_yaml}")
        return "".join(lines)

    if isinstance(value, dict):
        if not value:
            return "{}"
        # Inline format for simple dicts
        if all(isinstance(v, (str, int, float, bool)) or v is None for v in value.values()):
            items = [f"{k}: {_to_yaml_value(v)}" for k, v in value.items()]
            inline = f"{{{', '.join(items)}}}"
            if len(inline) < 80:
                return inline
        # Multi-line format
        lines = []
        for k, v in value.items():
            v_yaml = _to_yaml_value(v, indent + 2)
            lines.append(f"\n{'  ' * (indent // 2 + 1)}{k}: {v_yaml}")
        return "".join(lines)

    return str(value)


def generate_yaml_frontmatter(data: Dict[str, Any]) -> str:
    """Convert dictionary to YAML frontmatter string.

    Args:
        data: Dictionary to convert

    Returns:
        YAML frontmatter string with --- delimiters

    Handles:
        - Proper quoting for wikilinks [[...]]
        - Proper quoting for URLs (containing :)
        - Proper quoting for ISO timestamps
        - Arrays and nested objects
    """
    lines = ["---"]

    for key, value in data.items():
        yaml_value = _to_yaml_value(value)
        lines.append(f"{key}: {yaml_value}")

    lines.append("---")
    return "\n".join(lines)


def prepare_frontmatter(
    frontmatter: Dict[str, Any],
    entity_type: str,
    entity_id: str,
    title: Optional[str] = None,
    timestamp: Optional[str] = None
) -> Dict[str, Any]:
    """Prepare frontmatter with required fields added.

    Args:
        frontmatter: Base frontmatter dictionary
        entity_type: Entity type
        entity_id: Generated entity ID
        title: Optional title to add
        timestamp: Optional timestamp (defaults to now)

    Returns:
        Updated frontmatter dictionary
    """
    result = dict(frontmatter)

    # Add title if provided
    if title:
        result["title"] = title

    # Add id field
    result["id"] = entity_id

    # Add created_at for non-source entities
    if entity_type != "07-sources":
        result["created_at"] = timestamp or _now_iso()

    return result


def create_entity_content(
    frontmatter: Dict[str, Any],
    body: str = ""
) -> str:
    """Create complete entity file content.

    Args:
        frontmatter: Frontmatter dictionary
        body: Markdown body content

    Returns:
        Complete entity file content
    """
    yaml = generate_yaml_frontmatter(frontmatter)

    if body:
        return f"{yaml}\n\n{body}"
    else:
        return yaml
