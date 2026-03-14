#!/usr/bin/env python3
"""
create-entity.py
Version: 4.0.0 (Python migration)
Purpose: Generate entity file with UUID, YAML frontmatter, deduplication, locking, atomic writes
Category: core

Usage:
    create-entity.py --project-path <path> --entity-type <type> --data <json> [options]

Required Arguments:
    --project-path <path>  Project directory path
    --entity-type <type>   Entity type (00-initial-question, ..., 06-claims)
    --data <data>          Entity data (JSON/YAML string, @file, or - for stdin)

Optional Arguments:
    --entity-id <id>       Custom entity ID (MANDATORY for 03-query-batches)
    --title <title>        Title field for YAML frontmatter
    --deterministic        Generate UUID from content hash
    --json                 Output JSON format

JSON Data Structure:
    {
        "frontmatter": {
            "name": "...",
            "url": "...",        // Required for 05-sources
            "domain": "...",     // Required for 05-sources
            "title": "...",      // Required for 05-sources
            "batch_ref": "[[03-query-batches/...]]",  // Required for 04-findings
            ...
        },
        "content": "markdown body",
        "id": "optional-custom-uuid"
    }

Exit Codes:
    0   - Success
    1   - Validation error
    2   - Usage/argument error
    122 - Batch validation failed (04-findings)
    123 - Question_ref validation failed (04-findings)

JSON Output (success):
    {
        "success": true,
        "entity_path": "/path/to/entity.md",
        "entity_id": "source-abc12345",
        "entity_type": "05-sources",
        "created_at": "2025-12-19T10:30:00Z",
        "reused": false,
        "dedupe_method": "none"
    }

JSON Output (reused via deduplication):
    {
        "success": true,
        "entity_path": "/path/to/existing.md",
        "entity_id": "source-existing",
        "entity_type": "05-sources",
        "reused": true,
        "dedupe_method": "url"
    }
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

# Add shared utils to path - prefer bundled version for plugin cache compatibility
SCRIPT_DIR = Path(__file__).resolve().parent
BUNDLED_UTILS = SCRIPT_DIR / "shared_utils"
if BUNDLED_UTILS.is_dir():
    # Use bundled shared_utils (works in plugin cache)
    sys.path.insert(0, str(BUNDLED_UTILS))
else:
    # Fall back to monorepo location (development mode)
    REPO_ROOT = SCRIPT_DIR.parent.parent
    SHARED_UTILS = REPO_ROOT / "cogni-workplace" / "python"
    sys.path.insert(0, str(SHARED_UTILS))

from script_output import parse_json_arg
from file_ops import atomic_write, file_size, ensure_dir
from cross_platform import normalize_url, now_iso, parse_data_auto
from logging_utils import log_conditional, log_phase, log_metric
from entity_lock import EntityLock, Lock
from entity_index import (
    VALID_ENTITY_TYPES,
    initialize_index,
    lookup_entity_by_url,
    lookup_entity_by_name,
    add_entity_to_index,
    verify_entity_in_index,
)
from entity_ops import (
    DEDUPE_TYPES,
    validate_entity_type,
    validate_frontmatter,
    validate_batch_ref,
    validate_question_ref,
    needs_deduplication,
    generate_entity_id,
    generate_yaml_frontmatter,
    prepare_frontmatter,
    create_entity_content,
)
from entity_config import get_entity_data_path, get_data_subdir
import hashlib
import re

__version__ = "4.2.0"


def generate_publisher_id_from_domain(domain: str) -> str:
    """Generate deterministic publisher ID from domain.

    Replicates the algorithm from generate-publisher-id.sh to ensure
    consistency between source-creator and publisher-generator.

    Algorithm:
        1. Strip www. prefix and extract org name (first component)
        2. Generate slug (lowercase, alphanumeric, hyphens)
        3. Generate 8-char MD5 hash from org name (with newline for compat)
        4. Return: publisher-{slug}-{hash}

    Args:
        domain: Domain string (e.g., "www.example.com")

    Returns:
        Publisher ID string (e.g., "publisher-example-a1b2c3d4")
    """
    # Strip protocol prefixes if present
    domain = re.sub(r'^https?://', '', domain)

    # Strip www. prefix
    if domain.startswith('www.'):
        domain = domain[4:]

    # Extract primary domain name (first component before dot)
    org_name = domain.split('.')[0]

    # Capitalize first letter
    if org_name:
        org_name = org_name[0].upper() + org_name[1:]

    # Generate slug: lowercase, hyphens, alphanumeric only
    slug = org_name.lower()
    slug = slug.replace(' ', '-')
    slug = re.sub(r'[^a-z0-9-]', '', slug)
    slug = re.sub(r'-+', '-', slug)  # Collapse multiple hyphens

    if not slug:
        slug = "unknown"

    # Generate 8-char MD5 hash (with newline for backward compatibility)
    # NOTE: Using newline to match existing publisher files
    hash_input = org_name + '\n'
    md5_hash = hashlib.md5(hash_input.encode()).hexdigest()[:8]

    return f"publisher-{slug}-{md5_hash}"


def output_json_result(data: Dict[str, Any]) -> None:
    """Output JSON result to stdout."""
    print(json.dumps(data, ensure_ascii=False))


def output_json_error(
    message: str,
    code: int = 1,
    **extra: Any
) -> None:
    """Output JSON error to stderr and exit."""
    result = {"success": False, "error": message, "error_code": code}
    result.update(extra)
    print(json.dumps(result), file=sys.stderr)
    sys.exit(code)


def output_text_error(message: str, code: int = 1) -> None:
    """Output text error to stderr and exit."""
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(code)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create entity with deduplication and atomic writes",
    )
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--entity-type", required=True, help="Entity type")
    parser.add_argument("--data", required=True, help="JSON data or @file.json")
    parser.add_argument("--entity-id", help="Custom entity ID")
    parser.add_argument("--title", help="Title for frontmatter")
    parser.add_argument("--deterministic", action="store_true", help="Hash-based UUID")
    parser.add_argument("--json", action="store_true", help="JSON output")

    args, _ = parser.parse_known_args()
    return args


def check_deduplication(
    project_path: str,
    entity_type: str,
    frontmatter: Dict[str, Any],
    json_output: bool,
) -> Optional[Dict[str, Any]]:
    """Check for existing entity via deduplication.

    Returns:
        Dict with existing entity info if found, None if not found
    """
    if entity_type not in DEDUPE_TYPES:
        return None

    # For 05-sources: try URL-based dedup first
    if entity_type == "05-sources":
        url = frontmatter.get("url", "")
        if url:
            # Normalize URL for dedup
            normalized = normalize_url(url)
            result = lookup_entity_by_url(project_path, entity_type, normalized)
            if result.get("exists"):
                return {
                    "entity_id": result.get("entity_id", ""),
                    "entity_path": f"{project_path}/{result.get('entity_path', '')}",
                    "dedupe_method": "url",
                }

    # Fallback: name-based dedup
    name = frontmatter.get("name", "")
    if name:
        result = lookup_entity_by_name(project_path, entity_type, name)
        if result.get("exists"):
            return {
                "entity_id": result.get("entity_id", ""),
                "entity_path": f"{project_path}/{result.get('entity_path', '')}",
                "dedupe_method": "name",
            }

    return None


def main() -> None:
    """Main entry point."""
    args = parse_args()
    json_output = args.json

    # Enable QUIET_MODE for JSON output
    if json_output:
        os.environ["QUIET_MODE"] = "true"

    log_phase("Phase 1: Argument Validation", "start")

    # Validate and resolve entity type (supports aliases like "finding" → "04-findings")
    valid, error_msg, resolved_type = validate_entity_type(args.entity_type)
    if not valid:
        if json_output:
            output_json_error(error_msg, 2)
        else:
            output_text_error(error_msg, 2)
    args.entity_type = resolved_type

    # Validate project path
    project_path = Path(args.project_path)
    if not project_path.is_dir():
        msg = f"Project path not found: {args.project_path}"
        if json_output:
            output_json_error(msg, 1)
        else:
            output_text_error(msg, 1)

    # Parse data (JSON or YAML)
    try:
        if args.data == "-":
            # Read from stdin
            raw_data = sys.stdin.read()
            log_conditional("DEBUG", f"Received stdin data: {len(raw_data)} bytes")
            if len(raw_data) < 50:
                log_conditional("WARN", f"Suspiciously short stdin input ({len(raw_data)} bytes): {repr(raw_data[:100])}")
        elif args.data.startswith("@"):
            # Explicit file reference with @ prefix
            data_file = Path(args.data[1:])
            if not data_file.exists():
                raise FileNotFoundError(f"Data file not found: {data_file}")
            raw_data = data_file.read_text(encoding="utf-8")
        elif args.data.startswith("/") and Path(args.data).exists():
            # Auto-detect absolute file paths
            data_file = Path(args.data)
            raw_data = data_file.read_text(encoding="utf-8")
        else:
            raw_data = args.data

        # Auto-detect format and parse (JSON first, then YAML)
        data = parse_data_auto(raw_data)
    except (ValueError, FileNotFoundError) as e:
        msg = f"Invalid data in --data argument: {e}"
        if json_output:
            output_json_error(msg, 1)
        else:
            output_text_error(msg, 1)

    # Extract components
    frontmatter = data.get("frontmatter", {})
    content = data.get("content", "")
    custom_id_from_data = data.get("id", "")

    # Auto-normalize flat JSON: if frontmatter is empty but data has known fields,
    # treat the entire data object as frontmatter
    if not frontmatter and any(key in data for key in ["dc:title", "batch_ref", "question_ref", "schema_version", "entity_type"]):
        frontmatter = {k: v for k, v in data.items() if k not in ("content", "id")}
        content = data.get("content", "")
        custom_id_from_data = data.get("id", "")

    entity_name = frontmatter.get("name", "")

    log_phase("Phase 1: Argument Validation", "complete")

    # ===== PHASE 2: INDEX INITIALIZATION =====
    log_phase("Phase 2: Index Initialization", "start")

    if not initialize_index(args.project_path):
        msg = "Failed to initialize entity index"
        if json_output:
            output_json_error(msg, 1)
        else:
            output_text_error(msg, 1)

    log_conditional("DEBUG", "Entity index initialized")
    log_phase("Phase 2: Index Initialization", "complete")

    # ===== PHASE 3: DEDUPLICATION CHECK (before lock) =====
    log_phase("Phase 3: Deduplication Check", "start")

    existing = check_deduplication(
        args.project_path,
        args.entity_type,
        frontmatter,
        json_output,
    )

    if existing:
        log_conditional("INFO", f"Entity exists via {existing['dedupe_method']} dedup")
        log_metric("dedup_match", 1, "boolean")
        log_phase("Phase 3: Deduplication Check", "complete")

        if json_output:
            output_json_result({
                "success": True,
                "entity_path": existing["entity_path"],
                "entity_id": existing["entity_id"],
                "entity_type": args.entity_type,
                "reused": True,
                "dedupe_method": existing["dedupe_method"],
            })
        else:
            print(f"Entity already exists: {existing['entity_path']}")
        return

    log_metric("dedup_match", 0, "boolean")
    log_phase("Phase 3: Deduplication Check", "complete")

    # ===== PHASE 4: ACQUIRE LOCK AND CREATE ENTITY =====
    log_phase("Phase 4: Entity Creation", "start")

    with EntityLock(args.entity_type, args.project_path, raise_on_fail=True) as lock:
        # Double-check dedup after acquiring lock (race condition prevention)
        existing = check_deduplication(
            args.project_path,
            args.entity_type,
            frontmatter,
            json_output,
        )

        if existing:
            log_conditional("INFO", "Entity created while waiting for lock")
            log_phase("Phase 4: Entity Creation", "complete")

            if json_output:
                output_json_result({
                    "success": True,
                    "entity_path": existing["entity_path"],
                    "entity_id": existing["entity_id"],
                    "entity_type": args.entity_type,
                    "reused": True,
                    "dedupe_method": existing["dedupe_method"],
                })
            else:
                print(f"Entity already exists: {existing['entity_path']}")
            return

        # Generate entity ID
        custom_id = args.entity_id or custom_id_from_data

        entity_id = generate_entity_id(
            args.entity_type,
            custom_id=custom_id,
            content=content,
            deterministic=args.deterministic,
        )

        # Determine entity directory and path (using data subdir)
        entity_dir = get_entity_data_path(args.project_path, args.entity_type)
        if not entity_dir.is_dir():
            # Auto-create data subdirectory if parent entity directory exists
            parent_dir = entity_dir.parent
            if parent_dir.is_dir():
                log_conditional("INFO", f"Creating data subdirectory: {entity_dir}")
                ensure_dir(str(entity_dir))
            else:
                msg = f"Entity directory not found: {parent_dir}"
                if json_output:
                    output_json_error(msg, 1, entity_type=args.entity_type)
                else:
                    output_text_error(msg, 1)

        filename = f"{entity_id}.md"
        entity_path = entity_dir / filename

        # Check if file already exists
        if entity_path.exists():
            msg = f"Entity already exists: {entity_path}"
            if json_output:
                output_json_error(msg, 1, entity_path=str(entity_path))
            else:
                output_text_error(msg, 1)

        # Prepare frontmatter with required fields
        timestamp = now_iso()
        prepared_frontmatter = prepare_frontmatter(
            frontmatter,
            args.entity_type,
            entity_id,
            title=args.title,
            timestamp=timestamp,
        )

        # Validate frontmatter
        valid, missing_fields = validate_frontmatter(prepared_frontmatter, args.entity_type)
        if not valid:
            msg = f"Missing required frontmatter fields: {', '.join(missing_fields)}"
            if json_output:
                output_json_error(msg, 1, entity_type=args.entity_type, missing_fields=missing_fields)
            else:
                output_text_error(msg, 1)

        # Validate batch_ref for finding entities
        if args.entity_type == "04-findings":
            valid, error_msg = validate_batch_ref(prepared_frontmatter, args.project_path)
            if not valid:
                if json_output:
                    output_json_error(error_msg, 122)
                else:
                    print(f"ERROR: {error_msg}", file=sys.stderr)
                    sys.exit(122)

            # Validate question_ref (prevents LLM hallucination of wrong directory names)
            valid, error_msg = validate_question_ref(prepared_frontmatter, args.project_path)
            if not valid:
                if json_output:
                    output_json_error(error_msg, 123)
                else:
                    print(f"ERROR: {error_msg}", file=sys.stderr)
                    sys.exit(123)

        # Create entity content
        entity_content = create_entity_content(prepared_frontmatter, content)

        # Atomic write to file
        try:
            atomic_write(str(entity_path), entity_content)
        except Exception as e:
            msg = f"Failed to write entity file: {entity_path}: {e}"
            if json_output:
                output_json_error(msg, 1)
            else:
                output_text_error(msg, 1)

        log_conditional("DEBUG", f"Entity written: {entity_path}")

        # ===== PHASE 5: INDEX UPDATE =====
        log_phase("Phase 5: Index Update", "start")

        # Acquire global index lock
        index_lock_path = f"{args.project_path}/.locks/entity-index-global"
        ensure_dir(f"{args.project_path}/.locks")

        with Lock(index_lock_path, raise_on_fail=True):
            # Get URL for source entities
            entity_url = frontmatter.get("url") if args.entity_type == "05-sources" else None

            # Build entity path including data subdir
            data_subdir = get_data_subdir()
            entity_rel_path = f"{args.entity_type}/{data_subdir}/{filename}"

            success, error_msg = add_entity_to_index(
                args.project_path,
                entity_id,
                args.entity_type,
                entity_rel_path,
                entity_name,
                entity_url=entity_url,
                timestamp=timestamp,
            )

            if not success:
                # Rollback: remove entity file
                try:
                    entity_path.unlink()
                except OSError:
                    pass

                msg = f"Failed to update entity index: {error_msg}"
                if json_output:
                    output_json_error(msg, 1, rollback=True)
                else:
                    output_text_error(msg, 1)

        log_conditional("DEBUG", "Index updated successfully")
        log_phase("Phase 5: Index Update", "complete")

        # ===== PHASE 6: VERIFICATION =====
        log_phase("Phase 6: Verification", "start")

        # Verify entity was added to index
        if args.entity_type == "05-sources" and entity_url:
            verified = verify_entity_in_index(
                args.project_path,
                entity_id,
                args.entity_type,
                entity_url=entity_url,
            )
            if verified:
                log_conditional("DEBUG", f"Index verification PASSED: {entity_id}")
            else:
                log_conditional("WARN", f"Index verification FAILED: {entity_id} not found")

        # Post-write schema validation for specific entity types
        import subprocess
        validate_script = None
        validate_args = []

        if args.entity_type == "03-query-batches":
            validate_script = SCRIPT_DIR / "validate-query-batch-schema.sh"
            validate_args = ["--file", str(entity_path), "--json"]
        elif args.entity_type == "04-findings":
            validate_script = SCRIPT_DIR / "validate-finding-template.sh"
            validate_args = ["--finding-file", str(entity_path)]

        if validate_script and validate_script.exists():
            try:
                result = subprocess.run(
                    ["bash", str(validate_script)] + validate_args,
                    capture_output=True,
                    text=True,
                    timeout=30,
                )
                if result.returncode != 0:
                    log_conditional("WARN", f"Schema validation warning for {entity_id}: {result.stdout}")
                else:
                    log_conditional("DEBUG", f"Schema validation PASSED: {entity_id}")
            except subprocess.TimeoutExpired:
                log_conditional("WARN", f"Schema validation timeout for {entity_id}")
            except Exception as e:
                log_conditional("WARN", f"Schema validation error for {entity_id}: {e}")

        log_phase("Phase 6: Verification", "complete")

    log_phase("Phase 4: Entity Creation", "complete")

    # ===== OUTPUT RESULT =====
    if json_output:
        output_json_result({
            "success": True,
            "entity_path": str(entity_path),
            "uuid": entity_id.split("-", 1)[1] if "-" in entity_id else entity_id,
            "entity_id": entity_id,
            "entity_type": args.entity_type,
            "created_at": timestamp,
            "reused": False,
            "dedupe_method": "none",
        })
    else:
        print(f"Entity created: {entity_path}")
        print(f"ID: {entity_id}")


if __name__ == "__main__":
    main()
