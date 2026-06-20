#!/usr/bin/env python3
"""
contradiction-frontmatter-store.py — mode-B durability for ingest-time recency-survivor
contradiction resolutions.

Channel (a) surfaces the recency-survivor annotation to the composer from the ingest-time
`.metadata/contradiction-ingest.json` artifact. This script lands channel (b): it persists
each resolved finding's `resolution {survivor_claim_id, strategy: "recency", rationale}`
DURABLY onto the participating wiki pages' frontmatter at ingest time — so the annotation
survives across runs, is visible to any reader/linter, and lets `wiki-composer` prefer the
on-page source over the central JSON (graceful fallback to (a) when the block is absent).

Called by `knowledge-ingest` Step 4.6.4, AFTER the Step 4.6.3 merge writes the canonical
`contradiction-ingest.json`. Pure persistence — never re-scores, never gates ingest, never
fetches. Additive: it splices a top-level `contradiction_resolutions:` YAML block onto each
page, preserving `pre_extracted_claims:` / `answer_claims:` and every other frontmatter key
and the whole body BYTE-FOR-BYTE (the `question-store.py answer-merge` surgery precedent).

Scope of annotated pages — the two pages a `contradiction` finding names, when each resolves
to a source (`clm-NNN` -> wiki/sources/<slug>.md) or question node (`acl-NNN` ->
wiki/questions/<slug>.md). Distilled pages (`dcl-NNN` -> concepts/entities) are out of the
named scope and are skipped; the composer's central-JSON fallback still covers them.

Replace-not-accumulate: the canonical `contradiction-ingest.json` is overwritten on every
re-ingest (it reflects the current claim set), so a page's block is REPLACED in place with
the current run's resolutions — the same posture as channel (a)'s central artifact. A page
not touched this run keeps its prior block untouched.

Shared-state read-modify-write of existing pages, so the batch runs under cogni-wiki's
`_wiki_lock` (imported from `_wikilib` via `--wiki-scripts-dir`, the answer-merge posture).

Fail-soft throughout: a missing / empty / malformed ingest JSON, or zero resolved
contradictions, is a clean no-op (byte-identical to a run without this step). A per-page
write failure is recorded and skipped — it never rolls back an already-ingested page.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    atomic_write_text,
    parse_contradiction_resolutions,
)

# Key line for the block we own, anchored at column 0 of the frontmatter inner text.
_CONTRA_RES_KEY_RE = re.compile(r"^contradiction_resolutions[ \t]*:[ \t]*$")
# Frontmatter `updated:` scalar at column 0 — never the indented per-entry lines.
_FM_UPDATED_RE = re.compile(r"(?m)^updated:[ \t]*.+$")

# claim_id prefix -> wiki page-type subdirectory. `dcl-` (distilled concept/entity) is
# intentionally absent: those pages are out of the named scope (sources + questions),
# and the composer's central-JSON fallback still covers a distilled loser.
_PREFIX_DIR = {"clm-": "sources", "acl-": "questions"}


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    print(json.dumps({"success": bool(success), "data": data or {}, "error": error or ""},
                     indent=2, ensure_ascii=False))
    return 0 if success else 1


def _page_subdir(claim_id: str | None) -> str | None:
    """Map a claim_id to its wiki page subdirectory by prefix, or None when out of scope."""
    if not claim_id:
        return None
    for prefix, subdir in _PREFIX_DIR.items():
        if claim_id.startswith(prefix):
            return subdir
    return None


def _entries_for_finding(finding: dict) -> list[tuple]:
    """Build the per-page annotation entry for one resolved contradiction finding.

    Returns a list of (subdir, slug, entry) tuples — one per participating page that is
    in scope — or [] when the finding is not a resolved, mappable contradiction. Both
    participating pages receive the SAME logical entry (a reader on either page sees the
    full survivor/loser picture); the composer keys its map by the loser side."""
    if finding.get("kind") != "contradiction":
        return []
    resolution = finding.get("resolution")
    if not isinstance(resolution, dict):
        return []
    survivor_id = resolution.get("survivor_claim_id")
    if not survivor_id:
        return []  # no recency basis (both timestamps absent/equal) — nothing durable

    new_page = finding.get("new_page")
    new_claim_id = finding.get("new_claim_id")
    conflicting_page = finding.get("conflicting_page")
    conflicting_claim_id = finding.get("conflicting_claim_id")

    # Identify survivor / loser side by which claim_id the survivor matches.
    if survivor_id == new_claim_id:
        survivor_page, survivor_claim_id = new_page, new_claim_id
        loser_page, loser_claim_id = conflicting_page, conflicting_claim_id
    elif survivor_id == conflicting_claim_id:
        survivor_page, survivor_claim_id = conflicting_page, conflicting_claim_id
        loser_page, loser_claim_id = new_page, new_claim_id
    else:
        return []  # survivor matches neither side — unmappable, skip rather than guess

    if not (loser_page and loser_claim_id and survivor_page and survivor_claim_id):
        return []

    entry = {
        "finding_id": finding.get("id") or "",
        "strategy": resolution.get("strategy") or "recency",
        "survivor_page": survivor_page,
        "survivor_claim_id": survivor_claim_id,
        "loser_page": loser_page,
        "loser_claim_id": loser_claim_id,
        "rationale": resolution.get("rationale") or "",
    }

    out = []
    for page, claim_id in ((survivor_page, survivor_claim_id), (loser_page, loser_claim_id)):
        subdir = _page_subdir(claim_id)
        if subdir:
            out.append((subdir, page, entry))
    return out


def _render_block(entries: list[dict]) -> str:
    """Render the `contradiction_resolutions:` block — a 2-space-indent list of mappings,
    entries sorted by finding_id for deterministic, idempotent output. `json.dumps` for the
    free-text / slug scalars (the YAML-valid double-quoted-scalar discipline); bare for the
    fixed-vocabulary id / strategy scalars (`ctr-NNN`, `clm-NNN`/`acl-NNN`, `recency`)."""
    lines = ["contradiction_resolutions:"]
    for e in sorted(entries, key=lambda x: x.get("finding_id", "")):
        lines.append(f"  - finding_id: {e['finding_id']}")
        lines.append(f"    strategy: {e['strategy']}")
        lines.append(f"    survivor_page: {json.dumps(e['survivor_page'], ensure_ascii=False)}")
        lines.append(f"    survivor_claim_id: {e['survivor_claim_id']}")
        lines.append(f"    loser_page: {json.dumps(e['loser_page'], ensure_ascii=False)}")
        lines.append(f"    loser_claim_id: {e['loser_claim_id']}")
        lines.append(f"    rationale: {json.dumps(e['rationale'], ensure_ascii=False)}")
    return "\n".join(lines)


def _splice_block(page_text: str, block_text: str, today: str) -> tuple:
    """Splice the rendered `contradiction_resolutions:` block into the page's frontmatter,
    replacing an existing block in place or appending it before the FM close — preserving
    the `---` markers, every OTHER frontmatter key (incl. `pre_extracted_claims:` /
    `answer_claims:`), and the entire body BYTE-FOR-BYTE. Returns (new_text, changed).

    The block-boundary rule (key line + run of blank / indented / bullet lines up to the
    next top-level key) mirrors `question-store._splice_answer_claims`, so a re-splice lands
    on exactly the span a prior run wrote. `updated:` is bumped to today only on a real
    change (rendered-first idempotency)."""
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return page_text, False  # caller guards a parseable FM
    inner_start, inner_end = m.start(1), m.end(1)
    prefix = page_text[:inner_start]
    suffix = page_text[inner_end:]  # the `\n---…` close + the whole body, byte-exact
    inner_lines = page_text[inner_start:inner_end].split("\n")
    block_lines = block_text.rstrip("\n").split("\n")

    start = None
    for i, line in enumerate(inner_lines):
        if _CONTRA_RES_KEY_RE.match(line):
            start = i
            break
    if start is not None:
        end = start + 1
        while end < len(inner_lines):
            line = inner_lines[end]
            stripped = line.strip()
            if stripped == "" or line[:1] in (" ", "\t") or stripped == "-" or stripped.startswith("- "):
                end += 1
            else:
                break
        new_inner_lines = inner_lines[:start] + block_lines + inner_lines[end:]
    else:
        new_inner_lines = inner_lines + block_lines

    candidate = prefix + "\n".join(new_inner_lines) + suffix
    if candidate == page_text:
        return page_text, False
    bumped = _FM_UPDATED_RE.sub(f"updated: {today}", "\n".join(new_inner_lines), count=1)
    return prefix + bumped + suffix, True


def _fingerprint(entries: list[dict]) -> list:
    """A tuple per entry covering every persisted field, for the pre-write round-trip
    self-check (the survivor/loser hint is unrecoverable if a write silently drops it)."""
    return sorted(
        (
            e.get("finding_id", ""), e.get("strategy", ""),
            e.get("survivor_page", ""), e.get("survivor_claim_id", ""),
            e.get("loser_page", ""), e.get("loser_claim_id", ""),
            e.get("rationale", ""),
        )
        for e in entries
    )


def cmd_splice(args: argparse.Namespace) -> int:
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock  # noqa: E402
    except ImportError as exc:
        return _emit(False, error=f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    ingest_path = Path(args.ingest).resolve()
    # Fail-soft: a missing / empty / malformed ingest file is a clean no-op — the ingested
    # pages already landed at Step 3, so a tripwire artifact hiccup must never fail the run.
    try:
        data = json.loads(ingest_path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError):
        return _emit(True, data={"pages_annotated": 0, "reason": "ingest_not_found"})
    except json.JSONDecodeError:
        return _emit(True, data={"pages_annotated": 0, "reason": "ingest_unparseable"})
    if not isinstance(data, dict):
        return _emit(True, data={"pages_annotated": 0, "reason": "ingest_not_object"})

    findings = data.get("findings") or []
    # Accumulate one entry per (target page, finding) — dedup by finding_id within a page.
    per_page: dict = {}  # (subdir, slug) -> {finding_id: entry}
    for finding in findings:
        if not isinstance(finding, dict):
            continue
        for subdir, slug, entry in _entries_for_finding(finding):
            per_page.setdefault((subdir, slug), {})[entry["finding_id"]] = entry

    if not per_page:
        return _emit(True, data={"pages_annotated": 0, "reason": "no_resolved_contradictions"})

    today = datetime.date.today().isoformat()
    annotated: list[str] = []
    skipped: list[dict] = []
    dry_run = bool(getattr(args, "dry_run", False))

    # One lock for the whole batch: each page is re-read from disk before its splice.
    with _wiki_lock(wiki_root):
        for (subdir, slug), entries_by_id in sorted(per_page.items()):
            page_label = f"{subdir}/{slug}"
            page_path = wiki_root / "wiki" / subdir / f"{slug}.md"
            if not page_path.is_file():
                skipped.append({"page": page_label, "reason": "page_not_found"})
                continue
            try:
                text = page_path.read_text(encoding="utf-8")
            except OSError as exc:
                skipped.append({"page": page_label, "reason": f"unreadable: {exc}"})
                continue
            entries = list(entries_by_id.values())
            block_text = _render_block(entries)
            new_text, changed = _splice_block(text, block_text, today)
            if not changed:
                continue  # idempotent no-op — the block is already present and identical
            # Pre-write round-trip self-check: every entry must parse back from the text.
            if _fingerprint(parse_contradiction_resolutions(new_text)) != _fingerprint(entries):
                skipped.append({"page": page_label, "reason": "round_trip_mismatch"})
                continue
            if dry_run:
                annotated.append(page_label)
                continue
            try:
                atomic_write_text(page_path, new_text)
            except OSError as exc:
                skipped.append({"page": page_label, "reason": f"write_failed: {exc}"})
                continue
            annotated.append(page_label)

    return _emit(True, data={
        "pages_annotated": len(annotated),
        "annotated_pages": sorted(annotated),
        "skipped": skipped,
        "dry_run": dry_run,
    })


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Persist recency-survivor contradiction resolutions onto wiki page "
                    "frontmatter (mode-B durability; reads the canonical contradiction-ingest.json).",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_splice = sub.add_parser(
        "splice",
        help="Splice a contradiction_resolutions: block onto each participating "
             "wiki/sources + wiki/questions page named by a resolved contradiction.",
    )
    p_splice.add_argument("--ingest", required=True,
                          help="<project>/.metadata/contradiction-ingest.json (canonical merged artifact)")
    p_splice.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_splice.add_argument("--wiki-scripts-dir", required=True,
                          help="cogni-wiki wiki-ingest/scripts/ dir (for _wiki_lock)")
    p_splice.add_argument("--dry-run", action="store_true",
                          help="Report would-be annotations without writing any page.")
    p_splice.set_defaults(func=cmd_splice)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
