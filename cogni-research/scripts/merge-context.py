#!/usr/bin/env python3
"""
merge-context.py
Version: 1.3.0
Purpose: Aggregate context entities, deduplicate sources, produce merged context.
Category: core

Usage:
    merge-context.py --project-path <path> [--json]

Aggregation:
    Reads all context entities from 01-contexts/data/ and source entities from 02-sources/data/.
    Produces .metadata/aggregated-context.json with:
      - Merged findings from all contexts
      - Deduplicated source list
      - Per-source citation count
      - Total word count and source count

    Output: {"success": true, "contexts": N, "sources": N, "total_words": N}

Note on depth vs. length (v0.7.7, issue #35): Context aggregation caps scale by
    report_type (research depth), not target_words (writer output floor). Length
    became decoupled from depth in v0.7.7 — target_words controls the writer's
    word-count floor, depth still drives input density because the writer needs
    more raw evidence to reach a longer floor on a wider tree, not because the
    floor itself scales linearly with input. A deep project with target_words=5000
    still gets the 45K-word input cap, because evidence density is a depth property
    not a length property. Do not add a target_words branch to the cap table below.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

# Maximum words allowed in aggregated context, per report type.
# The writer's output target drives the input budget — a deep report needs to
# emit 8000+ words, so a flat 25K input cap forces ~3:1 compression which
# structurally pushes the writer toward terse synthesis. Scaling the cap by
# report type gives the writer enough raw material to retain evidence density
# at the required output length. Basic/detailed keep the legacy 25K ceiling;
# deep gets headroom; outline/resource are trimmed since their output targets
# are much smaller.
MAX_CONTEXT_WORDS_BY_TYPE: Dict[str, int] = {
    "basic": 12000,
    "detailed": 25000,
    "deep": 45000,
    "outline": 8000,
    "resource": 10000,
}
DEFAULT_MAX_CONTEXT_WORDS = 25000


def load_report_type(project_path: Path) -> str:
    """Read report_type from .metadata/project-config.json. Returns empty string on miss."""
    cfg_path = project_path / ".metadata" / "project-config.json"
    if not cfg_path.is_file():
        return ""
    try:
        cfg = json.loads(cfg_path.read_text(encoding='utf-8'))
        return str(cfg.get("report_type", "")).lower()
    except (OSError, json.JSONDecodeError):
        return ""


def get_max_context_words(report_type: str) -> int:
    """Select the context word cap for a given report type, with a safe default."""
    return MAX_CONTEXT_WORDS_BY_TYPE.get(report_type, DEFAULT_MAX_CONTEXT_WORDS)


def parse_frontmatter(text: str) -> Tuple[Dict[str, Any], str]:
    """Parse YAML frontmatter from markdown file. Returns (frontmatter_dict, body).

    Splits key/value on the first `:<whitespace>` (not the first `:`), so Dublin Core
    compound keys like `dc:identifier: <value>` parse correctly. Using `.partition(':')`
    broke these keys — the key became `dc` and `source_map` never indexed anything,
    silently emptying every aggregated source list.

    Empty-value lines (`original_url: \\n`) stay as empty strings until a `- ` item
    proves the field is actually an array. Earlier logic greedily created `[]` on
    every empty value, which meant every trailing optional scalar field — including
    the load-bearing `original_url` on wiki source entities — was coerced to `[]`
    and lost its value when the next non-array key arrived.
    """
    if not text.startswith('---'):
        return {}, text

    parts = text.split('---', 2)
    if len(parts) < 3:
        return {}, text

    fm_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parser for flat key-value + arrays
    fm: Dict[str, Any] = {}
    current_key: Optional[str] = None
    current_key_is_list: bool = False  # True only once we've seen a `- ` item under current_key

    # Match a key followed by the first ":<whitespace>" separator.
    # Key can itself contain colons (e.g. dc:identifier) as long as they are not followed
    # by whitespace. Value is everything after the first ":<whitespace>" run.
    kv_re = re.compile(r'^([^\s][^\s:]*(?::[^\s:][^\s:]*)*)\s*:\s*(.*)$')

    for line in fm_text.split('\n'):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        # Array item
        if stripped.startswith('- ') and current_key:
            item = stripped[2:].strip().strip('"').strip("'")
            # Try parsing as JSON for complex items
            try:
                item = json.loads(item)
            except (json.JSONDecodeError, TypeError):
                pass
            # Promote current_key to a list on first item, or append if already a list.
            existing = fm.get(current_key)
            if not current_key_is_list or not isinstance(existing, list):
                fm[current_key] = [item]
                current_key_is_list = True
            else:
                existing.append(item)
            continue

        # Key-value pair (supports dc:identifier-style compound keys)
        m = kv_re.match(stripped)
        if not m:
            continue

        key = m.group(1).strip()
        value = m.group(2).strip().strip('"').strip("'")

        current_key = key
        current_key_is_list = False

        # Empty value — leave as empty string; a subsequent `- ` item would promote it to a list.
        if not value:
            fm[key] = ""
            continue

        # Type conversion for simple scalars
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

    # Resolve the context word cap from the project's report type.
    report_type = load_report_type(project_path)
    max_context_words = get_max_context_words(report_type)

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

    # Build source lookup by ID. Carry publication metadata through to the writer:
    # - `original_url` holds the canonical `https://` publisher URL for wiki/file sources
    #   (see cogni-research/agents/wiki-researcher.md Phase 2). Without this field the
    #   writer cannot render clickable bibliography entries for wiki sources.
    # - `url_precision` distinguishes per-resource URLs ("exact") from publisher landing
    #   pages ("publisher") so the writer can annotate the difference honestly in the
    #   references section. Missing/unknown defaults to "exact" for https `url`,
    #   "none" for wiki/file without an original_url.
    # - `author` and `year` are needed by citation formats (apa/chicago/harvard/…)
    #   that key the surface string off author-year rather than publisher-year.
    source_map: Dict[str, Dict[str, Any]] = {}
    for fm, body in sources:
        sid = fm.get("dc:identifier", "")
        if sid:
            source_map[sid] = {
                "id": sid,
                "url": fm.get("url", ""),
                "original_url": fm.get("original_url", ""),
                "url_precision": fm.get("url_precision", ""),
                "title": fm.get("title", ""),
                "publisher": fm.get("publisher", ""),
                "author": fm.get("author", ""),
                "year": fm.get("year", ""),
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
            "sub_question_ref": (fm.get("sub_question_ref", "")
                                  or fm.get("parent_sq", "")
                                  or fm.get("sub_question", "")),
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

    # Trim contexts to stay within the report-type word limit (keep most recent, matching original's strategy)
    aggregated["report_type"] = report_type
    aggregated["max_context_words"] = max_context_words
    if total_words > max_context_words:
        trimmed_contexts = []
        running_words = 0
        # Process in reverse to keep most recent contexts (later sub-questions tend to be deeper)
        for ctx in reversed(aggregated["contexts"]):
            wc = ctx["word_count"]
            if running_words + wc <= max_context_words:
                trimmed_contexts.insert(0, ctx)
                running_words += wc
            else:
                break
        aggregated["contexts"] = trimmed_contexts
        aggregated["total_words"] = running_words
        aggregated["trimmed_from"] = total_words
        total_words = running_words

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
        "report_type": report_type,
        "max_context_words": max_context_words,
        "output_path": str(output_path),
    }
    if "trimmed_from" in aggregated:
        result["trimmed_from"] = aggregated["trimmed_from"]

    if args.json:
        print(json.dumps(result))
    else:
        print(f"Aggregated {len(contexts)} contexts with {len(seen_source_ids)} unique sources ({total_words} words)")
        print(f"Output: {output_path}")


if __name__ == "__main__":
    main()
