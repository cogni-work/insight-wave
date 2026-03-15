#!/usr/bin/env python3
"""
create-entity.py
Version: 1.0.0
Purpose: Create entity files with UUID, YAML frontmatter, URL deduplication, atomic writes.
Category: core

Usage:
    create-entity.py --project-path <path> --entity-type <type> --data <json> [--json]

Required Arguments:
    --project-path <path>  Project directory path
    --entity-type <type>   Entity type (sub-question, context, source, report-claim)
    --data <data>          Entity data (JSON string, @file, or - for stdin)

Optional Arguments:
    --entity-id <id>       Custom entity ID
    --json                 Output JSON format

Entity Types and ID Prefixes:
    sub-question   → sq-{slug}-{hash}    in 00-sub-questions/data/
    context        → ctx-{slug}-{hash}   in 01-contexts/data/
    source         → src-{slug}-{hash}   in 02-sources/data/
    report-claim   → rc-{slug}-{hash}    in 03-report-claims/data/

JSON Output (success):
    {"success": true, "entity_path": "...", "entity_id": "...", "entity_type": "...",
     "created_at": "...", "reused": false}

JSON Output (reused via URL dedup):
    {"success": true, "entity_path": "...", "entity_id": "...", "entity_type": "...",
     "reused": true, "dedupe_method": "url"}
"""

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional, Tuple


__version__ = "1.0.0"

# Entity type configuration
ENTITY_TYPES = {
    "sub-question": {"dir": "00-sub-questions", "prefix": "sq"},
    "context": {"dir": "01-contexts", "prefix": "ctx"},
    "source": {"dir": "02-sources", "prefix": "src"},
    "report-claim": {"dir": "03-report-claims", "prefix": "rc"},
}

# Aliases for convenience
ENTITY_ALIASES = {
    "00-sub-questions": "sub-question",
    "01-contexts": "context",
    "02-sources": "source",
    "03-report-claims": "report-claim",
}

# Types that support URL-based deduplication
DEDUPE_TYPES = {"source"}


def now_iso() -> str:
    """Return current UTC timestamp in ISO 8601."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slugify(text: str, max_len: int = 40) -> str:
    """Convert text to kebab-case slug."""
    slug = text.lower().strip()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s_]+', '-', slug)
    slug = re.sub(r'-+', '-', slug)
    slug = slug.strip('-')
    if len(slug) > max_len:
        slug = slug[:max_len].rstrip('-')
    return slug or "untitled"


def generate_hash(content: str, length: int = 8) -> str:
    """Generate short hash from content."""
    return hashlib.sha256(content.encode()).hexdigest()[:length]


def normalize_url(url: str) -> str:
    """Normalize URL for deduplication."""
    url = url.strip().rstrip('/')
    url = re.sub(r'^https?://(www\.)?', '', url)
    return url.lower()


def atomic_write(path: str, content: str) -> None:
    """Write file atomically via temp file + rename."""
    dir_path = os.path.dirname(path)
    fd, tmp_path = tempfile.mkstemp(dir=dir_path, suffix='.tmp')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            f.write(content)
        os.rename(tmp_path, path)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def generate_entity_id(entity_type: str, frontmatter: Dict[str, Any],
                       content: str, custom_id: str = "") -> str:
    """Generate entity ID: {prefix}-{slug}-{hash}."""
    if custom_id:
        return custom_id

    cfg = ENTITY_TYPES[entity_type]
    prefix = cfg["prefix"]

    # Derive slug from entity-specific fields
    if entity_type == "sub-question":
        slug_source = frontmatter.get("query", "")
    elif entity_type == "context":
        slug_source = frontmatter.get("sub_question_ref", "")
    elif entity_type == "source":
        slug_source = frontmatter.get("title", frontmatter.get("url", ""))
    elif entity_type == "report-claim":
        slug_source = frontmatter.get("statement", "")
    else:
        slug_source = content

    slug = slugify(slug_source, max_len=30)
    hash_input = f"{slug_source}{content}{uuid.uuid4().hex[:8]}"
    short_hash = generate_hash(hash_input)

    return f"{prefix}-{slug}-{short_hash}"


def find_existing_by_url(project_path: str, url: str) -> Optional[Dict[str, Any]]:
    """Find existing source entity by URL (deduplication)."""
    normalized = normalize_url(url)
    source_dir = Path(project_path) / "02-sources" / "data"

    if not source_dir.is_dir():
        return None

    for entity_file in source_dir.glob("src-*.md"):
        try:
            text = entity_file.read_text(encoding='utf-8')
            # Extract URL from frontmatter
            for line in text.split('\n'):
                if line.startswith('url:'):
                    existing_url = line.split(':', 1)[1].strip().strip('"').strip("'")
                    if normalize_url(existing_url) == normalized:
                        # Extract entity ID from filename
                        entity_id = entity_file.stem
                        return {
                            "entity_id": entity_id,
                            "entity_path": str(entity_file),
                        }
        except (OSError, UnicodeDecodeError):
            continue

    return None


def generate_yaml_frontmatter(frontmatter: Dict[str, Any]) -> str:
    """Generate YAML frontmatter string."""
    lines = ["---"]
    for key, value in frontmatter.items():
        if isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                if isinstance(item, dict):
                    lines.append(f"  - {json.dumps(item, ensure_ascii=False)}")
                else:
                    lines.append(f'  - "{item}"' if isinstance(item, str) else f"  - {item}")
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        elif isinstance(value, (int, float)):
            lines.append(f"{key}: {value}")
        elif isinstance(value, str):
            if '\n' in value or ':' in value or '#' in value:
                lines.append(f'{key}: "{value}"')
            else:
                lines.append(f"{key}: {value}")
        elif value is None:
            lines.append(f"{key}: null")
        else:
            lines.append(f"{key}: {json.dumps(value, ensure_ascii=False)}")
    lines.append("---")
    return '\n'.join(lines)


def parse_data(raw: str) -> Dict[str, Any]:
    """Parse JSON data string."""
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}")


def output_json(data: Dict[str, Any], file=sys.stdout) -> None:
    """Output JSON to stream."""
    print(json.dumps(data, ensure_ascii=False), file=file)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create entity with YAML frontmatter")
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--entity-type", required=True, help="Entity type")
    parser.add_argument("--data", required=True, help="JSON data or @file")
    parser.add_argument("--entity-id", help="Custom entity ID")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args, _ = parser.parse_known_args()

    json_output = args.json

    # Resolve entity type (support aliases)
    entity_type = args.entity_type
    if entity_type in ENTITY_ALIASES:
        entity_type = ENTITY_ALIASES[entity_type]
    if entity_type not in ENTITY_TYPES:
        msg = f"Unknown entity type: {entity_type}. Valid: {', '.join(ENTITY_TYPES.keys())}"
        if json_output:
            output_json({"success": False, "error": msg}, sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(2)

    # Validate project path
    project_path = Path(args.project_path)
    if not project_path.is_dir():
        msg = f"Project path not found: {args.project_path}"
        if json_output:
            output_json({"success": False, "error": msg}, sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Parse data
    try:
        if args.data == "-":
            raw_data = sys.stdin.read()
        elif args.data.startswith("@"):
            data_file = Path(args.data[1:])
            if not data_file.exists():
                raise FileNotFoundError(f"Data file not found: {data_file}")
            raw_data = data_file.read_text(encoding="utf-8")
        elif args.data.startswith("/") and Path(args.data).exists():
            raw_data = Path(args.data).read_text(encoding="utf-8")
        else:
            raw_data = args.data
        data = parse_data(raw_data)
    except (ValueError, FileNotFoundError) as e:
        msg = f"Invalid data: {e}"
        if json_output:
            output_json({"success": False, "error": msg}, sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Extract components
    frontmatter = data.get("frontmatter", {})
    content = data.get("content", "")

    # Auto-normalize flat JSON
    if not frontmatter and any(k in data for k in ["schema_version", "entity_type", "query", "statement", "url"]):
        frontmatter = {k: v for k, v in data.items() if k not in ("content", "id")}
        content = data.get("content", "")

    # URL deduplication for source entities
    if entity_type == "source":
        url = frontmatter.get("url", "")
        if url:
            existing = find_existing_by_url(str(project_path), url)
            if existing:
                if json_output:
                    output_json({
                        "success": True,
                        "entity_path": existing["entity_path"],
                        "entity_id": existing["entity_id"],
                        "entity_type": entity_type,
                        "reused": True,
                        "dedupe_method": "url",
                    })
                else:
                    print(f"Entity already exists: {existing['entity_path']}")
                return

    # Ensure required frontmatter fields
    timestamp = now_iso()
    frontmatter.setdefault("schema_version", "1.0")
    frontmatter.setdefault("entity_type", entity_type)
    frontmatter.setdefault("dc:created", timestamp)
    frontmatter.setdefault("dc:creator", "Claude (cogni-gpt-researcher)")

    # Generate entity ID
    custom_id = args.entity_id or data.get("id", "")
    entity_id = generate_entity_id(entity_type, frontmatter, content, custom_id)
    frontmatter["dc:identifier"] = entity_id

    # Determine entity directory
    cfg = ENTITY_TYPES[entity_type]
    entity_dir = project_path / cfg["dir"] / "data"
    entity_dir.mkdir(parents=True, exist_ok=True)

    # Check collision
    entity_path = entity_dir / f"{entity_id}.md"
    if entity_path.exists():
        msg = f"Entity already exists: {entity_path}"
        if json_output:
            output_json({"success": False, "error": msg}, sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Build file content
    yaml_header = generate_yaml_frontmatter(frontmatter)
    file_content = f"{yaml_header}\n\n{content}\n" if content else f"{yaml_header}\n"

    # Atomic write
    try:
        atomic_write(str(entity_path), file_content)
    except Exception as e:
        msg = f"Failed to write entity: {e}"
        if json_output:
            output_json({"success": False, "error": msg}, sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Output result
    if json_output:
        output_json({
            "success": True,
            "entity_path": str(entity_path),
            "entity_id": entity_id,
            "entity_type": entity_type,
            "created_at": timestamp,
            "reused": False,
        })
    else:
        print(f"Entity created: {entity_path}")
        print(f"ID: {entity_id}")


if __name__ == "__main__":
    main()
