"""
Entity Index Management for Claude Code Plugins
================================================

Manage entity-index.json for deduplication and lookup operations.
Provides transactional updates with backup/rollback.

Index Structure:
    {
        "version": "1.0.0",
        "created": "2025-12-19T10:30:00Z",
        "last_updated": "2025-12-19T10:35:00Z",
        "entities": {
            "00-initial-question": [],
            "05-sources": [
                {
                    "id": "source-example-abc12345",
                    "entity_type": "05-sources",
                    "entity_path": "05-sources/source-example-abc12345.md",
                    "name": "Example Source",
                    "url": "https://example.com/article",
                    "created_at": "2025-12-19T10:30:00Z"
                }
            ],
            ...
        }
    }

Functions:
    initialize_index(project_path) - Create or repair entity-index.json
    normalize_entity_name(name) - Normalize name for deduplication
    lookup_entity_by_url(project_path, entity_type, url) - URL lookup
    lookup_entity_by_name(project_path, entity_type, name) - Name lookup
    add_entity_to_index(...) - Add entity with transactional backup/rollback
    remove_entity_from_index(...) - Remove entity from index
"""

import json
import os
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

__version__ = "1.1.0"

# Import entity types from central config
try:
    from .entity_config import get_valid_entity_types
except ImportError:
    from entity_config import get_valid_entity_types

# Valid entity types in order (loaded from config)
VALID_ENTITY_TYPES = get_valid_entity_types()


def _now_iso() -> str:
    """Get current timestamp in ISO 8601 UTC format."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _read_json(path: Path) -> Optional[Dict]:
    """Read and parse JSON file, returns None on error."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def _write_json(path: Path, data: Dict) -> bool:
    """Write JSON to file atomically, returns success."""
    try:
        # Write to temp file first
        temp_path = path.with_suffix(".tmp")
        with open(temp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        # Atomic rename
        temp_path.replace(path)
        return True
    except OSError:
        # Clean up temp file if it exists
        try:
            temp_path.unlink(missing_ok=True)
        except:
            pass
        return False


def get_index_path(project_path: str) -> Path:
    """Get path to entity-index.json."""
    return Path(project_path) / ".metadata" / "entity-index.json"


def initialize_index(project_path: str) -> bool:
    """Create or repair entity-index.json with correct structure.

    Args:
        project_path: Absolute path to project root

    Returns:
        True if index exists and is valid, False on error

    Creates the index file if it doesn't exist or repairs it if the
    structure is incorrect (e.g., entities is array instead of object).
    """
    project = Path(project_path)
    if not project.is_dir():
        return False

    # Ensure metadata directory exists
    metadata_dir = project / ".metadata"
    try:
        metadata_dir.mkdir(parents=True, exist_ok=True)
    except OSError:
        return False

    index_path = metadata_dir / "entity-index.json"

    # Check if index exists and has correct structure
    if index_path.exists():
        data = _read_json(index_path)
        if data is not None:
            entities = data.get("entities")
            if isinstance(entities, dict):
                # Structure is correct
                return True

    # Initialize or repair index with correct structure
    timestamp = _now_iso()
    index_data = {
        "version": "1.0.0",
        "created": timestamp,
        "last_updated": timestamp,
        "entities": {entity_type: [] for entity_type in VALID_ENTITY_TYPES},
    }

    return _write_json(index_path, index_data)


def normalize_entity_name(name: str) -> str:
    """Normalize entity name for deduplication comparison.

    Args:
        name: Entity name to normalize

    Returns:
        Normalized name (lowercase, no punctuation, no articles)

    Normalization steps:
        1. Convert to lowercase
        2. Remove non-alphanumeric characters (keep spaces)
        3. Remove leading articles (the, a, an)
        4. Collapse multiple spaces
        5. Trim leading/trailing whitespace
    """
    if not name:
        return ""

    # Lowercase
    result = name.lower()

    # Remove non-alphanumeric (keep spaces)
    result = re.sub(r"[^a-z0-9 ]", "", result)

    # Remove leading articles
    result = re.sub(r"^the ", "", result)
    result = re.sub(r"^a ", "", result)
    result = re.sub(r"^an ", "", result)

    # Collapse multiple spaces and trim
    result = re.sub(r"  +", " ", result).strip()

    return result


def lookup_entity_by_url(
    project_path: str,
    entity_type: str,
    url: str
) -> Dict[str, Any]:
    """Look up entity by URL in entity-index.json.

    Args:
        project_path: Absolute path to project root
        entity_type: Entity type (e.g., "05-sources")
        url: URL to search for (exact match after normalization)

    Returns:
        Dict with keys:
            - exists: bool
            - entity_id: str (if exists)
            - entity_path: str (if exists)
            - url: str

    Note: URL matching is exact after both are normalized to remove
    trailing slashes and ensure consistent format.
    """
    result: Dict[str, Any] = {"exists": False, "url": url}

    index_path = get_index_path(project_path)
    if not index_path.exists():
        return result

    data = _read_json(index_path)
    if data is None:
        return result

    entities = data.get("entities", {})
    type_entities = entities.get(entity_type, [])

    # Normalize search URL for comparison
    search_url = url.rstrip("/")

    for entity in type_entities:
        entity_url = entity.get("url", "").rstrip("/")
        if entity_url == search_url:
            result["exists"] = True
            result["entity_id"] = entity.get("id", "")
            result["entity_path"] = entity.get("entity_path", "")
            result["url"] = entity.get("url", url)
            break

    return result


def lookup_entity_by_name(
    project_path: str,
    entity_type: str,
    name: str
) -> Dict[str, Any]:
    """Look up entity by normalized name in entity-index.json.

    Args:
        project_path: Absolute path to project root
        entity_type: Entity type (e.g., "05-sources")
        name: Name to search for (normalized before comparison)

    Returns:
        Dict with keys:
            - exists: bool
            - entity_id: str (if exists)
            - entity_path: str (if exists)
            - normalized_name: str
    """
    normalized_input = normalize_entity_name(name)
    result: Dict[str, Any] = {
        "exists": False,
        "normalized_name": normalized_input,
    }

    if not normalized_input:
        return result

    index_path = get_index_path(project_path)
    if not index_path.exists():
        return result

    data = _read_json(index_path)
    if data is None:
        return result

    entities = data.get("entities", {})
    type_entities = entities.get(entity_type, [])

    for entity in type_entities:
        # Get name from entity (try name, then title for sources)
        entity_name = entity.get("name")
        if not entity_name and entity_type == "05-sources":
            entity_name = entity.get("title", "")
        if not entity_name:
            # Fallback: extract from ID
            entity_id = entity.get("id", "")
            parts = entity_id.split("-")
            if len(parts) > 2:
                entity_name = " ".join(parts[1:-1])

        if normalize_entity_name(entity_name or "") == normalized_input:
            result["exists"] = True
            result["entity_id"] = entity.get("id", "")
            result["entity_path"] = entity.get("entity_path", "")
            break

    return result


def add_entity_to_index(
    project_path: str,
    entity_id: str,
    entity_type: str,
    entity_path: str,
    entity_name: str,
    entity_url: Optional[str] = None,
    timestamp: Optional[str] = None
) -> Tuple[bool, str]:
    """Add entity to index with transactional backup/rollback.

    Args:
        project_path: Absolute path to project root
        entity_id: Unique entity identifier
        entity_type: Entity type (e.g., "05-sources")
        entity_path: Relative path to entity file (e.g., "05-sources/id.md")
        entity_name: Entity name for deduplication
        entity_url: Entity URL (for 05-sources)
        timestamp: Creation timestamp (defaults to now)

    Returns:
        Tuple of (success: bool, error_message: str)

    Uses backup/rollback pattern:
        1. Backup index before update
        2. Update index
        3. If update fails: restore backup
        4. If update succeeds: remove backup
    """
    if not timestamp:
        timestamp = _now_iso()

    index_path = get_index_path(project_path)

    # Initialize index if needed
    if not initialize_index(project_path):
        return False, "Failed to initialize entity index"

    # Read current index
    data = _read_json(index_path)
    if data is None:
        return False, "Failed to read entity index"

    # Create backup
    backup_path = index_path.with_suffix(f".backup.{os.getpid()}")
    try:
        shutil.copy2(index_path, backup_path)
    except OSError as e:
        return False, f"Failed to backup index: {e}"

    try:
        # Ensure entity type key exists
        if entity_type not in data.get("entities", {}):
            data.setdefault("entities", {})[entity_type] = []

        # Build entity record
        entity_record: Dict[str, Any] = {
            "id": entity_id,
            "entity_type": entity_type,
            "entity_path": entity_path,
            "name": entity_name,
            "created_at": timestamp,
        }

        # Add URL for source entities
        if entity_type == "05-sources" and entity_url:
            entity_record["url"] = entity_url

        # Add entity to index
        data["entities"][entity_type].append(entity_record)
        data["last_updated"] = timestamp

        # Write updated index
        if not _write_json(index_path, data):
            # Restore backup
            try:
                shutil.copy2(backup_path, index_path)
            except OSError:
                pass
            return False, "Failed to write entity index"

        # Success - remove backup
        try:
            backup_path.unlink()
        except OSError:
            pass

        return True, ""

    except Exception as e:
        # Restore backup on any error
        try:
            shutil.copy2(backup_path, index_path)
        except OSError:
            pass
        return False, f"Index update error: {e}"


def remove_entity_from_index(
    project_path: str,
    entity_id: str,
    entity_type: str
) -> Tuple[bool, str]:
    """Remove entity from index.

    Args:
        project_path: Absolute path to project root
        entity_id: Entity identifier to remove
        entity_type: Entity type

    Returns:
        Tuple of (success: bool, error_message: str)
    """
    index_path = get_index_path(project_path)

    if not index_path.exists():
        return True, ""  # Nothing to remove

    data = _read_json(index_path)
    if data is None:
        return False, "Failed to read entity index"

    # Create backup
    backup_path = index_path.with_suffix(f".backup.{os.getpid()}")
    try:
        shutil.copy2(index_path, backup_path)
    except OSError as e:
        return False, f"Failed to backup index: {e}"

    try:
        entities = data.get("entities", {})
        type_entities = entities.get(entity_type, [])

        # Filter out the entity
        new_entities = [e for e in type_entities if e.get("id") != entity_id]

        if len(new_entities) == len(type_entities):
            # Entity not found, nothing to remove
            try:
                backup_path.unlink()
            except OSError:
                pass
            return True, ""

        # Update index
        data["entities"][entity_type] = new_entities
        data["last_updated"] = _now_iso()

        if not _write_json(index_path, data):
            # Restore backup
            try:
                shutil.copy2(backup_path, index_path)
            except OSError:
                pass
            return False, "Failed to write entity index"

        # Success - remove backup
        try:
            backup_path.unlink()
        except OSError:
            pass

        return True, ""

    except Exception as e:
        # Restore backup
        try:
            shutil.copy2(backup_path, index_path)
        except OSError:
            pass
        return False, f"Index update error: {e}"


def verify_entity_in_index(
    project_path: str,
    entity_id: str,
    entity_type: str,
    entity_url: Optional[str] = None
) -> bool:
    """Verify entity was added to index correctly.

    Args:
        project_path: Absolute path to project root
        entity_id: Expected entity ID
        entity_type: Entity type
        entity_url: Entity URL for URL-based verification (05-sources)

    Returns:
        True if entity found in index with correct ID
    """
    if entity_type == "05-sources" and entity_url:
        result = lookup_entity_by_url(project_path, entity_type, entity_url)
        return result.get("exists", False) and result.get("entity_id") == entity_id
    else:
        # Check by iterating through entities
        index_path = get_index_path(project_path)
        if not index_path.exists():
            return False

        data = _read_json(index_path)
        if data is None:
            return False

        entities = data.get("entities", {}).get(entity_type, [])
        return any(e.get("id") == entity_id for e in entities)


def batch_add_entities_to_index(
    project_path: str,
    entities: List[Dict[str, Any]],
    timestamp: Optional[str] = None
) -> Tuple[bool, str]:
    """Add multiple entities to index in a single atomic operation.

    This function is critical for batch operations like source-creator
    where adding entities one-by-one causes lock contention. By batching
    all additions into a single read-modify-write cycle, we eliminate
    the race conditions that caused parallel execution to fail.

    Args:
        project_path: Absolute path to project root
        entities: List of entity dicts, each containing:
            - id: Entity identifier
            - entity_type: Entity type (e.g., "05-sources")
            - entity_path: Relative path to entity file
            - name: Entity name
            - url: (optional) Entity URL for sources
        timestamp: Creation timestamp (defaults to now)

    Returns:
        Tuple of (success: bool, error_message: str)

    Example:
        entities = [
            {"id": "source-xyz", "entity_type": "05-sources",
             "entity_path": "05-sources/data/source-xyz.md", "name": "XYZ Article"},
            {"id": "source-abc", "entity_type": "05-sources",
             "entity_path": "05-sources/data/source-abc.md", "name": "ABC Report"},
        ]
        success, error = batch_add_entities_to_index(project_path, entities)
    """
    if not timestamp:
        timestamp = _now_iso()

    if not entities:
        return True, ""  # Nothing to add

    index_path = get_index_path(project_path)

    # Initialize index if needed
    if not initialize_index(project_path):
        return False, "Failed to initialize entity index"

    # Read current index (single read)
    data = _read_json(index_path)
    if data is None:
        return False, "Failed to read entity index"

    # Create backup
    backup_path = index_path.with_suffix(f".backup.{os.getpid()}")
    try:
        shutil.copy2(index_path, backup_path)
    except OSError as e:
        return False, f"Failed to backup index: {e}"

    try:
        # Add ALL entities to in-memory structure
        for entity in entities:
            entity_type = entity.get("entity_type", "")
            if not entity_type:
                continue

            # Ensure entity type key exists
            if entity_type not in data.get("entities", {}):
                data.setdefault("entities", {})[entity_type] = []

            # Build entity record
            entity_record: Dict[str, Any] = {
                "id": entity.get("id", ""),
                "entity_type": entity_type,
                "entity_path": entity.get("entity_path", ""),
                "name": entity.get("name", ""),
                "created_at": timestamp,
            }

            # Add URL for source entities
            if entity.get("url"):
                entity_record["url"] = entity["url"]

            data["entities"][entity_type].append(entity_record)

        data["last_updated"] = timestamp

        # Single atomic write for ALL entities
        if not _write_json(index_path, data):
            # Restore backup
            try:
                shutil.copy2(backup_path, index_path)
            except OSError:
                pass
            return False, "Failed to write entity index"

        # Success - remove backup
        try:
            backup_path.unlink()
        except OSError:
            pass

        return True, ""

    except Exception as e:
        # Restore backup on any error
        try:
            shutil.copy2(backup_path, index_path)
        except OSError:
            pass
        return False, f"Batch index update error: {e}"


def is_valid_entity_type(entity_type: str) -> bool:
    """Check if entity type is valid."""
    return entity_type in VALID_ENTITY_TYPES
