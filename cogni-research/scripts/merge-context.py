#!/usr/bin/env python3
"""
merge-context.py
Version: 1.1.0
Purpose: Aggregate context entities, deduplicate sources, produce merged context.
         Also produce per-section context slices for deep-mode section-dispatch writing.
Category: core

Usage:
    merge-context.py --project-path <path> [--json]
    merge-context.py --project-path <path> --slice-sections --draft-version N [--json]

Aggregation mode (default):
    Reads all context entities from 01-contexts/data/ and source entities from 02-sources/data/.
    Produces .metadata/aggregated-context.json with:
      - Merged findings from all contexts
      - Deduplicated source list
      - Per-source citation count
      - Total word count and source count

    Output: {"success": true, "contexts": N, "sources": N, "total_words": N}

Slice mode (--slice-sections):
    Reads .metadata/writer-outline-v{DRAFT_VERSION}.json and .metadata/aggregated-context.json.
    For each outline section, produces .metadata/section-contexts/section-{index}.json
    containing only the context entries whose sub_question_ref is in covers_sub_questions,
    plus the sources those contexts cite. Used by deep-mode Phase 4b section dispatch so each
    section-writer call gets a small, focused context slice instead of the full aggregated set.

    Output: {"success": true, "sections": N, "slices": [{"index": "00", "contexts": N, "sources": N}, ...]}
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


def slice_sections(project_path: Path, draft_version: int, as_json: bool) -> None:
    """
    Slice aggregated-context.json per writer-outline section.

    For each section in writer-outline-v{draft_version}.json, write
    .metadata/section-contexts/section-{index}.json containing only the
    context entries whose sub_question_ref is listed in covers_sub_questions,
    plus the deduplicated sources those contexts cite.
    """
    metadata_dir = project_path / ".metadata"
    outline_path = metadata_dir / f"writer-outline-v{draft_version}.json"
    aggregated_path = metadata_dir / "aggregated-context.json"

    if not outline_path.is_file():
        msg = f"Writer outline not found: {outline_path}"
        if as_json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    if not aggregated_path.is_file():
        msg = f"Aggregated context not found: {aggregated_path}"
        if as_json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    try:
        outline = json.loads(outline_path.read_text(encoding='utf-8'))
        aggregated = json.loads(aggregated_path.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as e:
        msg = f"Failed to load outline or aggregated context: {e}"
        if as_json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Build lookup: sub_question_ref -> list of context entries
    all_contexts = aggregated.get("contexts", [])
    all_sources = {s["id"]: s for s in aggregated.get("sources", []) if s.get("id")}

    # Context entities store sub_question_ref as a wikilink, e.g.
    #   [[00-sub-questions/data/sq-welche-ki-trends-edge-ai-indus-cc8782fa]]
    # but the writer outline's covers_sub_questions lists bare slug *prefixes*,
    # e.g. "sq-welche-ki-trends-edge-ai-indus" (no 8-char hash suffix). Both
    # shapes represent the same sub-question, so we normalize context refs to
    # their bare slug and match a covers_sub_questions entry against any ref
    # that starts with the entry. This tolerates both historical and current
    # outline formats without forcing a migration.
    # Entity slugs follow the shape `<slug>[-]<8-hex-hash>`. The hash is
    # always 8 lowercase hex chars, sometimes dash-separated from the slug
    # and sometimes appended directly when the slug truncation happens to
    # collide with the hash boundary. Stripping the hash on both sides
    # reduces the outline-vs-context comparison to a stable slug-prefix
    # match regardless of which format the source file uses.
    _HASH_TAIL_RE = re.compile(r'-?[0-9a-f]{8}$')

    def normalize_sq_ref(raw: str) -> str:
        """Strip wikilink wrapper, path prefix, and trailing 8-hex hash."""
        if not raw:
            return ""
        stripped = raw.strip()
        # Strip [[...]] wrapper
        if stripped.startswith("[[") and stripped.endswith("]]"):
            stripped = stripped[2:-2]
        # Strip leading path component (00-sub-questions/data/)
        slash = stripped.rfind("/")
        if slash >= 0:
            stripped = stripped[slash + 1:]
        # Strip the trailing entity hash (with or without its leading dash).
        # Outline entries written by the LLM sometimes carry a truncated
        # partial of the hash; the regex only matches a full 8-char hex run,
        # so partial-hash outline entries are left alone and the symmetric
        # prefix match below still works.
        stripped = _HASH_TAIL_RE.sub("", stripped)
        return stripped

    # Index contexts by normalized sub_question_ref for slice matching.
    # A single normalized slug may carry the 8-char content hash (e.g.
    # "sq-welche-...-cc8782fa"), so we also index by every prefix truncation
    # to the first `-` before the final 8 hex chars. Prefix matching keeps
    # slicing O(N * S) where N is outline section count and S is context
    # count — fine for typical reports (~10 × ~20).
    sq_to_contexts: Dict[str, List[Dict[str, Any]]] = {}
    normalized_refs: List[Tuple[str, Dict[str, Any]]] = []
    for ctx in all_contexts:
        sq_ref = normalize_sq_ref(ctx.get("sub_question_ref", "") or "")
        sq_to_contexts.setdefault(sq_ref, []).append(ctx)
        normalized_refs.append((sq_ref, ctx))

    # Prepare output directory
    slice_dir = metadata_dir / "section-contexts"
    slice_dir.mkdir(parents=True, exist_ok=True)

    # Clear any stale slices from prior runs (section count may differ across versions)
    for stale in slice_dir.glob("section-*.json"):
        try:
            stale.unlink()
        except OSError:
            pass

    sections = outline.get("sections", [])
    slice_report: List[Dict[str, Any]] = []

    for section in sections:
        index = section.get("index")
        if not index:
            # Outline predates the index field; derive from position
            index = f"{sections.index(section):02d}"
        heading = section.get("heading", "")
        covers_sqs = section.get("covers_sub_questions", []) or []

        # Collect contexts matching any of this section's sub-questions.
        # We tolerate three shapes for covers_sub_questions entries:
        #   (a) full normalized slug with hash: "sq-foo-bar-cc8782fa"
        #   (b) bare slug prefix: "sq-foo-bar"
        #   (c) full wikilink: "[[00-sub-questions/data/sq-foo-bar-cc8782fa]]"
        # Match is symmetric prefix: a context matches if its normalized ref
        # startswith the normalized covers entry, OR the normalized covers
        # entry startswith the ref. Deduplicate by context id, falling back
        # to Python object identity when the stored id is empty (older
        # aggregated-context.json files leave ctx["id"] blank).
        sliced_contexts: List[Dict[str, Any]] = []
        seen_ctx_keys: Set[Any] = set()

        def _ctx_key(ctx: Dict[str, Any]) -> Any:
            cid = ctx.get("id") or ""
            return cid if cid else id(ctx)

        for sq in covers_sqs:
            normalized_sq = normalize_sq_ref(sq)
            if not normalized_sq:
                continue
            # Fast path: exact match (post-normalization)
            for ctx in sq_to_contexts.get(normalized_sq, []):
                key = _ctx_key(ctx)
                if key not in seen_ctx_keys:
                    sliced_contexts.append(ctx)
                    seen_ctx_keys.add(key)
            # Slow path: prefix match. An outline entry "sq-foo-bar" matches
            # a context ref "sq-foo-bar-cc8782fa". Length check avoids matching
            # unrelated slugs that share a short prefix.
            if len(normalized_sq) >= 8:
                for ref, ctx in normalized_refs:
                    if not ref or ref == normalized_sq:
                        continue
                    if ref.startswith(normalized_sq + "-") or normalized_sq.startswith(ref + "-"):
                        key = _ctx_key(ctx)
                        if key not in seen_ctx_keys:
                            sliced_contexts.append(ctx)
                            seen_ctx_keys.add(key)

        # Collect sources cited by the sliced contexts
        sliced_source_ids: Set[str] = set()
        for ctx in sliced_contexts:
            for ref in ctx.get("source_refs", []) or []:
                match = re.search(r'\[\[02-sources/data/(src-[a-z0-9-]+)\]\]', ref)
                if match:
                    sid = match.group(1)
                    if sid in all_sources:
                        sliced_source_ids.add(sid)

        sliced_sources = [all_sources[sid] for sid in sliced_source_ids]

        slice_payload = {
            "section_index": index,
            "section_heading": heading,
            "section_budget": section.get("budget", 0),
            "covers_sub_questions": covers_sqs,
            "contexts": sliced_contexts,
            "sources": sliced_sources,
        }

        out_file = slice_dir / f"section-{index}.json"
        out_file.write_text(
            json.dumps(slice_payload, indent=2, ensure_ascii=False),
            encoding='utf-8',
        )

        slice_report.append({
            "index": index,
            "heading": heading,
            "contexts": len(sliced_contexts),
            "sources": len(sliced_sources),
            "path": str(out_file),
        })

    result = {
        "success": True,
        "mode": "slice",
        "draft_version": draft_version,
        "sections": len(sections),
        "slices": slice_report,
        "output_dir": str(slice_dir),
    }

    if as_json:
        print(json.dumps(result))
    else:
        print(f"Sliced {len(sections)} sections into {slice_dir}")
        for s in slice_report:
            print(f"  section-{s['index']}: {s['contexts']} contexts, {s['sources']} sources — {s['heading']}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge or slice context entities")
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--slice-sections", action="store_true",
                        help="Slice mode: emit per-section context slices from writer outline")
    parser.add_argument("--draft-version", type=int, default=1,
                        help="Draft version for slice mode (default: 1)")
    args = parser.parse_args()

    project_path = Path(args.project_path)
    if not project_path.is_dir():
        msg = f"Project path not found: {args.project_path}"
        if args.json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    # Slice mode: emit per-section slices and exit
    if args.slice_sections:
        slice_sections(project_path, args.draft_version, args.json)
        return

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
