#!/usr/bin/env python3
"""
lookup-entity.py
Version: 3.0.0 (Python migration)
Purpose: Check if entity exists by normalized name OR URL in entity-index.json
Category: utilities

Usage:
    lookup-entity.py --project-path <path> --entity-type <type> [--name <name> | --url <url>] [--json]

Arguments:
    --project-path <path>  Project directory path (required)
    --entity-type <string> Entity type directory name (required)
    --name <string>        Entity name to lookup (optional, either --name OR --url required)
    --url <string>         Entity URL to lookup (optional, either --name OR --url required)
    --json                 Output JSON format (optional flag)

Output (JSON mode):
    {
        "success": boolean,
        "data": {
            "exists": boolean,
            "entity_id": "string (if exists)",
            "entity_path": "string (if exists)",
            "normalized_name": "string (if name lookup)",
            "url": "string (if URL lookup)"
        }
    }

Exit codes:
    0 - Success
    1 - Validation error
    2 - Usage error

Example:
    # Name-based lookup
    lookup-entity.py --project-path "/path/to/project" --entity-type "07-sources" --name "World Bank" --json

    # URL-based lookup
    lookup-entity.py --project-path "/path/to/project" --entity-type "07-sources" --url "https://example.com/article" --json
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

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

from logging_utils import log_conditional, log_phase, log_metric
from entity_index import (
    lookup_entity_by_url,
    lookup_entity_by_name,
    normalize_entity_name,
    get_index_path,
)


def error_json(message: str, code: int = 1) -> None:
    """Output error in JSON format and exit."""
    log_conditional("ERROR", message)
    result = {"success": False, "error": message, "error_code": code}
    print(json.dumps(result), file=sys.stderr)
    sys.exit(code)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Check if entity exists by name or URL",
        add_help=False,
    )
    parser.add_argument("--project-path", required=True, help="Project directory path")
    parser.add_argument("--entity-type", required=True, help="Entity type directory name")
    parser.add_argument("--name", help="Entity name to lookup")
    parser.add_argument("--url", help="Entity URL to lookup")
    parser.add_argument("--json", action="store_true", help="Output JSON format")

    # Handle unknown arguments gracefully
    args, _ = parser.parse_known_args()
    return args


def main() -> None:
    """Main entry point."""
    start_time = time.time()
    args = parse_args()

    # Enable QUIET_MODE for JSON output
    if args.json:
        os.environ["QUIET_MODE"] = "true"

    log_phase("Phase 1: Input Validation", "start")

    # Determine lookup mode
    if args.url:
        lookup_mode = "url"
    elif args.name:
        lookup_mode = "name"
    else:
        lookup_mode = "name"

    log_conditional("INFO", f"Parameter: project_path = {args.project_path}")
    log_conditional("INFO", f"Parameter: entity_type = {args.entity_type}")
    log_conditional("INFO", f"Parameter: lookup_mode = {lookup_mode}")

    if lookup_mode == "url":
        log_conditional("DEBUG", f"Lookup target: {args.url}")
    else:
        log_conditional("DEBUG", f"Lookup target: {args.name}")

    # Validate required arguments
    if not args.project_path:
        error_json("Missing: --project-path", 2)

    if not args.entity_type:
        error_json("Missing: --entity-type", 2)

    project_path = Path(args.project_path)
    if not project_path.is_dir():
        error_json(f"Directory not found: {args.project_path}", 1)

    # Validate lookup criteria
    if lookup_mode == "name" and not args.name:
        error_json("Missing: --name (or use --url for URL-based lookup)", 2)

    if lookup_mode == "url" and not args.url:
        error_json("Missing: --url (or use --name for name-based lookup)", 2)

    log_phase("Phase 1: Input Validation", "complete")

    # ===== PHASE 2: INDEX LOADING =====
    log_phase("Phase 2: Index Loading", "start")

    index_path = get_index_path(args.project_path)
    log_conditional("DEBUG", f"Index path: {index_path}")

    # If index doesn't exist, return not found
    if not index_path.exists():
        log_conditional("WARN", "Index file not found, returning not found")
        log_metric("index_exists", 0, "boolean")

        if lookup_mode == "url":
            result = {
                "success": True,
                "data": {"exists": False, "url": args.url},
            }
        else:
            normalized = normalize_entity_name(args.name)
            result = {
                "success": True,
                "data": {"exists": False, "normalized_name": normalized},
            }

        print(json.dumps(result))
        return

    log_conditional("INFO", "Index loaded successfully")
    log_metric("index_exists", 1, "boolean")
    log_phase("Phase 2: Index Loading", "complete")

    # ===== PHASE 3: ENTITY SEARCH =====
    log_phase("Phase 3: Entity Search", "start")

    if lookup_mode == "url":
        log_conditional("DEBUG", "Performing URL-based lookup")
        lookup_result = lookup_entity_by_url(
            args.project_path,
            args.entity_type,
            args.url,
        )

        if lookup_result.get("exists"):
            log_conditional("INFO", f"Entity found: {lookup_result.get('entity_id')}")
            log_metric("entity_found", 1, "boolean")
            result = {
                "success": True,
                "data": {
                    "exists": True,
                    "entity_id": lookup_result.get("entity_id", ""),
                    "entity_path": lookup_result.get("entity_path", ""),
                    "url": lookup_result.get("url", args.url),
                },
            }
        else:
            log_conditional("INFO", "Entity not found by URL")
            log_metric("entity_found", 0, "boolean")
            result = {
                "success": True,
                "data": {"exists": False, "url": args.url},
            }
    else:
        log_conditional("DEBUG", "Performing name-based lookup")
        normalized_input = normalize_entity_name(args.name)

        if not normalized_input:
            error_json(f"Normalization empty for: {args.name}", 1)

        log_conditional("DEBUG", f"Normalized name: {normalized_input}")

        lookup_result = lookup_entity_by_name(
            args.project_path,
            args.entity_type,
            args.name,
        )

        if lookup_result.get("exists"):
            log_conditional("INFO", f"Entity found: {lookup_result.get('entity_id')}")
            log_metric("entity_found", 1, "boolean")
            result = {
                "success": True,
                "data": {
                    "exists": True,
                    "entity_id": lookup_result.get("entity_id", ""),
                    "entity_path": lookup_result.get("entity_path", ""),
                    "normalized_name": normalized_input,
                },
            }
        else:
            log_conditional("INFO", "Entity not found by name")
            log_metric("entity_found", 0, "boolean")
            result = {
                "success": True,
                "data": {"exists": False, "normalized_name": normalized_input},
            }

    log_phase("Phase 3: Entity Search", "complete")

    # ===== PHASE 4: RESULT GENERATION =====
    log_phase("Phase 4: Result Generation", "start")

    end_time = time.time()
    duration = int(end_time - start_time)
    log_metric("duration", duration, "seconds")

    log_phase("Phase 4: Result Generation", "complete")

    print(json.dumps(result))


if __name__ == "__main__":
    main()
