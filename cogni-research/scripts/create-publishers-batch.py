#!/usr/bin/env python3
"""
create-publishers-batch.py
Version: 1.0.0
Purpose: Batch create publisher skeleton entities from source files
Category: deeper-research Phase 6

This script is Phase A of the publisher-generator rearchitecture.
It creates all publisher skeleton entities atomically in a single process,
eliminating the entity-index.json race conditions that caused parallel
execution to fail.

Usage:
    create-publishers-batch.py --project-path <path> [--json]

Required Arguments:
    --project-path <path>  Project directory path

Optional Arguments:
    --json                 Output JSON format (default: text)

Algorithm:
    1. Glob all source files from 07-sources/data/
    2. Extract unique domains from YAML frontmatter
    3. Generate deterministic publisher IDs (same as generate-publisher-id.sh)
    4. Create skeleton publisher entities (enriched: false)
    5. Batch-write entity-index.json ONCE
    6. Return list of publishers needing enrichment

Exit Codes:
    0 - Success
    1 - Validation error
    2 - Usage/argument error

JSON Output (success):
    {
        "success": true,
        "created": 185,
        "reused": 26,
        "total_unique_domains": 211,
        "sources_processed": 474,
        "sources_without_domain": 3,
        "publishers_to_enrich": [
            "08-publishers/data/publisher-xyz.md",
            ...
        ],
        "execution_time_seconds": 12.5
    }
"""

import argparse
import glob
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Add shared utils to path
SCRIPT_DIR = Path(__file__).resolve().parent
BUNDLED_UTILS = SCRIPT_DIR / "shared_utils"
if BUNDLED_UTILS.is_dir():
    sys.path.insert(0, str(BUNDLED_UTILS))
else:
    REPO_ROOT = SCRIPT_DIR.parent.parent
    SHARED_UTILS = REPO_ROOT / "cogni-workplace" / "python"
    sys.path.insert(0, str(SHARED_UTILS))

from file_ops import atomic_write, ensure_dir
from entity_index import batch_add_entities_to_index, get_index_path, _read_json
from entity_lock import Lock

__version__ = "1.0.0"


def _now_iso() -> str:
    """Get current timestamp in ISO 8601 UTC format."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def generate_publisher_id_from_domain(domain: str) -> Tuple[str, str]:
    """Generate deterministic publisher ID from domain.

    Replicates the algorithm from generate-publisher-id.sh exactly.

    Args:
        domain: Domain string (e.g., "www.example.com")

    Returns:
        Tuple of (publisher_id, org_name)
        e.g., ("publisher-example-a1b2c3d4", "Example")
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
    hash_input = org_name + '\n'
    md5_hash = hashlib.md5(hash_input.encode()).hexdigest()[:8]

    return f"publisher-{slug}-{md5_hash}", org_name


def extract_yaml_frontmatter(content: str) -> Dict[str, Any]:
    """Extract YAML frontmatter from markdown content.

    Args:
        content: Full file content

    Returns:
        Dict of frontmatter fields
    """
    if not content.startswith('---'):
        return {}

    # Find closing ---
    end_idx = content.find('---', 3)
    if end_idx == -1:
        return {}

    yaml_content = content[3:end_idx].strip()
    result = {}

    for line in yaml_content.split('\n'):
        if ':' in line:
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            result[key] = value

    return result


def read_source_file(source_path: Path) -> Optional[Dict[str, Any]]:
    """Read source file and extract relevant metadata.

    Args:
        source_path: Path to source file

    Returns:
        Dict with id, domain, or None if invalid
    """
    try:
        content = source_path.read_text(encoding='utf-8')
        frontmatter = extract_yaml_frontmatter(content)

        source_id = frontmatter.get('id', '')
        domain = frontmatter.get('domain', '')

        if not source_id or not domain:
            return None

        return {
            'id': source_id,
            'domain': domain,
            'path': str(source_path),
        }
    except (OSError, UnicodeDecodeError):
        return None


def create_skeleton_publisher(
    publisher_id: str,
    org_name: str,
    domain: str,
    source_ids: List[str],
    timestamp: str
) -> str:
    """Create skeleton publisher markdown content.

    Args:
        publisher_id: Publisher entity ID
        org_name: Organization name
        domain: Domain string
        source_ids: List of source IDs referencing this publisher
        timestamp: Creation timestamp

    Returns:
        Markdown content string
    """
    # Build source_references array
    source_refs_str = json.dumps(source_ids)

    # Build wikilinks for Related Sources section
    wikilinks = '\n'.join([f'- [[07-sources/data/{sid}]]' for sid in source_ids])

    content = f'''---
id: "{publisher_id}"
entity_type: "publisher"
publisher_type: "organization"
name: "{org_name}"
domain: "{domain}"
enriched: false
enrichment_status: "pending"
source_references: {source_refs_str}
tags: ["publisher", "publisher-type/organization"]
created_at: "{timestamp}"
---

## Publisher: {org_name}

**Domain**: {domain}

### Related Sources
{wikilinks}
'''
    return content


def update_existing_publisher(
    publisher_path: Path,
    new_source_ids: List[str]
) -> bool:
    """Update existing publisher with additional source references.

    Args:
        publisher_path: Path to existing publisher file
        new_source_ids: Source IDs to add

    Returns:
        True if updated, False if no changes needed
    """
    try:
        content = publisher_path.read_text(encoding='utf-8')
        frontmatter = extract_yaml_frontmatter(content)

        # Get existing source_references
        existing_refs_str = frontmatter.get('source_references', '[]')
        try:
            # Handle both JSON array and YAML array formats
            if existing_refs_str.startswith('['):
                existing_refs = json.loads(existing_refs_str)
            else:
                existing_refs = []
        except json.JSONDecodeError:
            existing_refs = []

        # Find new sources to add
        sources_to_add = [sid for sid in new_source_ids if sid not in existing_refs]
        if not sources_to_add:
            return False

        # Update source_references in frontmatter
        all_refs = existing_refs + sources_to_add
        new_refs_str = json.dumps(all_refs)

        # Replace source_references line
        content = re.sub(
            r'source_references:.*',
            f'source_references: {new_refs_str}',
            content
        )

        # Add wikilinks to Related Sources section
        for sid in sources_to_add:
            wikilink = f'- [[07-sources/data/{sid}]]'
            # Insert before the last line of Related Sources (or at end if not found)
            if '### Related Sources' in content:
                # Find position after ### Related Sources
                pos = content.find('### Related Sources')
                end_pos = content.find('\n\n', pos)
                if end_pos == -1:
                    end_pos = len(content)
                content = content[:end_pos] + f'\n{wikilink}' + content[end_pos:]

        atomic_write(str(publisher_path), content)
        return True

    except (OSError, UnicodeDecodeError):
        return False


def output_json(data: Dict[str, Any]) -> None:
    """Output JSON to stdout."""
    print(json.dumps(data, ensure_ascii=False, indent=2))


def output_error(message: str, code: int = 1, json_output: bool = False) -> None:
    """Output error and exit."""
    if json_output:
        print(json.dumps({"success": False, "error": message}), file=sys.stderr)
    else:
        print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(code)


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Batch create publisher skeleton entities"
    )
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    json_output = args.json
    start_time = time.time()

    # Validate project path
    project_path = Path(args.project_path)
    if not project_path.is_dir():
        output_error(f"Project path not found: {args.project_path}", 1, json_output)

    sources_dir = project_path / "07-sources" / "data"
    if not sources_dir.is_dir():
        output_error(f"Sources directory not found: {sources_dir}", 1, json_output)

    # Ensure publishers directory exists
    publishers_dir = project_path / "08-publishers" / "data"
    try:
        ensure_dir(str(publishers_dir))
    except OSError as e:
        output_error(f"Cannot create publishers directory: {e}", 1, json_output)

    # Phase 1: Enumerate source files
    source_files = list(sources_dir.glob("source-*.md"))
    if not source_files:
        output_json({
            "success": True,
            "created": 0,
            "reused": 0,
            "total_unique_domains": 0,
            "sources_processed": 0,
            "sources_without_domain": 0,
            "publishers_to_enrich": [],
            "execution_time_seconds": round(time.time() - start_time, 2)
        }) if json_output else print("No source files found")
        return

    # Phase 2: Extract unique domains and map to sources
    domain_to_sources: Dict[str, List[str]] = {}  # domain -> [source_ids]
    sources_without_domain = 0

    for source_file in source_files:
        source_data = read_source_file(source_file)
        if source_data is None:
            sources_without_domain += 1
            continue

        domain = source_data['domain']
        source_id = source_data['id']
        domain_to_sources.setdefault(domain, []).append(source_id)

    # Phase 3: Generate publisher entities
    timestamp = _now_iso()
    publishers_to_create: List[Dict[str, Any]] = []
    publishers_existing: List[str] = []
    publishers_to_enrich: List[str] = []

    for domain, source_ids in domain_to_sources.items():
        publisher_id, org_name = generate_publisher_id_from_domain(domain)
        publisher_path = publishers_dir / f"{publisher_id}.md"
        publisher_rel_path = f"08-publishers/data/{publisher_id}.md"

        if publisher_path.exists():
            # Update existing publisher with additional source references
            update_existing_publisher(publisher_path, source_ids)
            publishers_existing.append(publisher_id)

            # Check if needs enrichment
            try:
                content = publisher_path.read_text(encoding='utf-8')
                if 'enriched: false' in content or 'enrichment_status: "pending"' in content:
                    publishers_to_enrich.append(publisher_rel_path)
            except OSError:
                pass
        else:
            # Queue for batch creation
            publishers_to_create.append({
                'id': publisher_id,
                'org_name': org_name,
                'domain': domain,
                'source_ids': source_ids,
                'entity_type': '08-publishers',
                'entity_path': publisher_rel_path,
                'name': org_name,
            })
            publishers_to_enrich.append(publisher_rel_path)

    # Phase 4: Atomic batch write (single global lock)
    if publishers_to_create:
        # Acquire global index lock
        lock_dir = project_path / ".locks"
        ensure_dir(str(lock_dir))
        lock_path = str(lock_dir / "entity-index-global")

        with Lock(lock_path, raise_on_fail=True):
            # Create all publisher files
            for pub in publishers_to_create:
                publisher_path = publishers_dir / f"{pub['id']}.md"
                content = create_skeleton_publisher(
                    pub['id'],
                    pub['org_name'],
                    pub['domain'],
                    pub['source_ids'],
                    timestamp
                )
                atomic_write(str(publisher_path), content)

            # Batch update entity-index.json
            index_entities = [
                {
                    'id': pub['id'],
                    'entity_type': pub['entity_type'],
                    'entity_path': pub['entity_path'],
                    'name': pub['name'],
                }
                for pub in publishers_to_create
            ]

            success, error_msg = batch_add_entities_to_index(
                str(project_path),
                index_entities,
                timestamp
            )

            if not success:
                # Rollback: remove created files
                for pub in publishers_to_create:
                    try:
                        (publishers_dir / f"{pub['id']}.md").unlink()
                    except OSError:
                        pass
                output_error(f"Failed to update entity index: {error_msg}", 1, json_output)

    # Phase 5: Return results
    execution_time = round(time.time() - start_time, 2)

    result = {
        "success": True,
        "created": len(publishers_to_create),
        "reused": len(publishers_existing),
        "total_unique_domains": len(domain_to_sources),
        "sources_processed": len(source_files),
        "sources_without_domain": sources_without_domain,
        "publishers_to_enrich": publishers_to_enrich,
        "execution_time_seconds": execution_time
    }

    if json_output:
        output_json(result)
    else:
        print(f"Created: {result['created']} publishers")
        print(f"Reused: {result['reused']} existing publishers")
        print(f"Total unique domains: {result['total_unique_domains']}")
        print(f"Sources processed: {result['sources_processed']}")
        print(f"Publishers needing enrichment: {len(result['publishers_to_enrich'])}")
        print(f"Execution time: {result['execution_time_seconds']}s")


if __name__ == "__main__":
    main()
