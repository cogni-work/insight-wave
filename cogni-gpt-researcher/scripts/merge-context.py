#!/usr/bin/env python3
"""
merge-context.py
Version: 1.0.0
Purpose: Aggregate context entities, deduplicate sources, produce merged context.
Category: core

Usage:
    merge-context.py --project-path <path> [--json]

Reads all context entities from 01-contexts/data/ and source entities from 02-sources/data/.
Produces .metadata/aggregated-context.json with:
  - Merged findings from all contexts
  - Deduplicated source list
  - Per-source citation count
  - Total word count and source count

Output:
    {"success": true, "contexts": N, "sources": N, "total_words": N}
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


def parse_frontmatter(text: str) -> Tuple[Dict[str, Any], str]:
    """Parse YAML frontmatter from markdown file. Returns (frontmatter_dict, body)."""
    if not text.startswith('---'):
        return {}, text

    parts = text.split('---', 2)
    if len(parts) < 3:
        return {}, text

    fm_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parser for flat key-value + arrays
    fm = {}
    current_key = None
    current_list = None

    for line in fm_text.split('\n'):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        # Array item
        if stripped.startswith('- ') and current_key:
            if current_list is None:
                current_list = []
            item = stripped[2:].strip().strip('"').strip("'")
            # Try parsing as JSON for complex items
            try:
                item = json.loads(item)
            except (json.JSONDecodeError, TypeError):
                pass
            current_list.append(item)
            fm[current_key] = current_list
            continue

        # Key-value pair
        if ':' in stripped:
            if current_list is not None:
                current_list = None

            key, _, value = stripped.partition(':')
            key = key.strip()
            value = value.strip().strip('"').strip("'")

            # Handle empty value (start of array)
            if not value:
                current_key = key
                current_list = []
                fm[key] = current_list
                continue

            current_key = key
            current_list = None

            # Type conversion
            if value == 'null':
                fm[key] = None
            elif value == 'true':
                fm[key] = True
            elif value == 'false':
                fm[key] = False
            else:
                try:
                    fm[key] = int(value)
                except ValueError:
                    try:
                        fm[key] = float(value)
                    except ValueError:
                        fm[key] = value

    return fm, body


def load_entities(entity_dir: Path) -> List[Tuple[Dict[str, Any], str]]:
    """Load all entity files from a directory. Returns list of (frontmatter, body)."""
    entities = []
    if not entity_dir.is_dir():
        return entities

    for f in sorted(entity_dir.glob("*.md")):
        try:
            text = f.read_text(encoding='utf-8')
            fm, body = parse_frontmatter(text)
            if fm:
                entities.append((fm, body))
        except (OSError, UnicodeDecodeError):
            continue

    return entities


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge context entities")
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    project_path = Path(args.project_path)
    if not project_path.is_dir():
        msg = f"Project path not found: {args.project_path}"
        if args.json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Load contexts and sources
    contexts = load_entities(project_path / "01-contexts" / "data")
    sources = load_entities(project_path / "02-sources" / "data")

    if not contexts:
        msg = "No context entities found in 01-contexts/data/"
        if args.json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Build source lookup by ID
    source_map: Dict[str, Dict[str, Any]] = {}
    for fm, body in sources:
        sid = fm.get("dc:identifier", "")
        if sid:
            source_map[sid] = {
                "id": sid,
                "url": fm.get("url", ""),
                "title": fm.get("title", ""),
                "publisher": fm.get("publisher", ""),
                "citation_count": 0,
            }

    # Aggregate contexts
    aggregated = {
        "topic": "",
        "contexts": [],
        "sources": [],
        "total_words": 0,
        "total_contexts": len(contexts),
        "total_sources": len(source_map),
    }

    seen_source_ids: Set[str] = set()
    total_words = 0

    for fm, body in contexts:
        ctx_entry = {
            "id": fm.get("dc:identifier", ""),
            "sub_question_ref": fm.get("sub_question_ref", ""),
            "source_refs": fm.get("source_refs", []),
            "key_findings": fm.get("key_findings", []),
            "word_count": fm.get("word_count", len(body.split())),
            "body_preview": body[:500] if body else "",
        }
        aggregated["contexts"].append(ctx_entry)
        total_words += ctx_entry["word_count"]

        # Count source citations
        for ref in fm.get("source_refs", []):
            # Extract source ID from wikilink [[02-sources/data/src-xxx]]
            match = re.search(r'\[\[02-sources/data/(src-[a-z0-9-]+)\]\]', ref)
            if match:
                sid = match.group(1)
                if sid in source_map:
                    source_map[sid]["citation_count"] += 1
                    seen_source_ids.add(sid)

    aggregated["total_words"] = total_words

    # Build deduplicated source list (only cited sources)
    aggregated["sources"] = sorted(
        [s for s in source_map.values() if s["id"] in seen_source_ids],
        key=lambda s: s["citation_count"],
        reverse=True,
    )

    # Write aggregated context
    output_path = project_path / ".metadata" / "aggregated-context.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(aggregated, indent=2, ensure_ascii=False),
        encoding='utf-8',
    )

    # Output result
    result = {
        "success": True,
        "contexts": len(contexts),
        "sources": len(seen_source_ids),
        "total_words": total_words,
        "output_path": str(output_path),
    }

    if args.json:
        print(json.dumps(result))
    else:
        print(f"Aggregated {len(contexts)} contexts with {len(seen_source_ids)} unique sources ({total_words} words)")
        print(f"Output: {output_path}")


if __name__ == "__main__":
    main()
