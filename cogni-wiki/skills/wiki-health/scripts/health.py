#!/usr/bin/env python3
"""
health.py — zero-LLM structural integrity check for a Karpathy-style wiki.

Emits JSON on stdout with the {success, data, error} contract:
    {"success": true,
     "data": {
       "errors":   [{"class": "...", "page": "...", "message": "..."}, ...],
       "warnings": [{"class": "...", "page": "...", "message": "..."}, ...],
       "stats":    { ... }
     },
     "error": ""}

Detects:
    Errors:
        - Broken [[wikilinks]]
        - Missing required frontmatter fields
        - Filename / id mismatches
        - Invalid type values
        - Missing ../raw/ source files
        - Broken wiki:// sources (target page does not exist)
        - Read errors
    Warnings (structural debt only — semantic warnings live in wiki-lint):
        - Stub pages (body shorter than STUB_PAGE_MIN_CHARS)
        - entries_count drift between config.json and filesystem
        - index.md <-> filesystem drift (entries on one side missing on the other)
    Stats:
        - pages_audited, errors, warnings
        - entries_count_config / _actual / _drift
        - claim_drift_count + date (read from .cogni-wiki/last-resweep.json)

Non-goals:
    - Orphan pages, stale dates, tag typos, reverse-link audit — those belong
      to wiki-lint where they can be narrated alongside semantic findings.
    - Auto-fix — health reports only; fixes go through wiki-update.
    - LLM calls — health is deterministic by design.

Layout: as of v0.0.28 pages live under per-type subdirectories
(`wiki/concepts/`, `wiki/decisions/`, …) plus `wiki/audits/` for `lint-*.md`
and `health-*.md` reports. The traversal is owned by `_wikilib.iter_pages()`.

stdlib-only. Python 3.8+. Performance contract: under 1 second on a 100-page
wiki.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"))
from _wikilib import (  # noqa: E402
    AUDIT_DIR,
    VALID_TYPES,
    build_slug_index,
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
)


STUB_PAGE_MIN_CHARS = 50
REQUIRED_FRONTMATTER = {"id", "title", "type", "created", "updated"}

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
WIKILINK_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\]")


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Return (frontmatter_dict, body_text).

    body_text is the page content after the closing `---`. When no frontmatter
    is found, returns ({}, text).
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    body = text[m.end() :]
    out: dict = {}
    current_key = None
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            out.setdefault(current_key, []).append(line[4:].strip())
            continue
        if ":" in line:
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            current_key = k
            if v.startswith("[") and v.endswith("]"):
                inside = v[1:-1].strip()
                if not inside:
                    out[k] = []
                else:
                    out[k] = [x.strip() for x in inside.split(",") if x.strip()]
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out, body


def _load_last_resweep(wiki_root: Path) -> dict | None:
    p = wiki_root / ".cogni-wiki" / "last-resweep.json"
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _load_config(wiki_root: Path) -> dict:
    p = wiki_root / ".cogni-wiki" / "config.json"
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _index_slugs(wiki_root: Path) -> set[str]:
    """Return slugs referenced as [[wikilinks]] in wiki/index.md.

    Returns an empty set when index.md is missing or unreadable — the caller
    can decide whether that's worth flagging (it isn't, today; missing index
    is a wiki-setup problem caught elsewhere).
    """
    p = wiki_root / "wiki" / "index.md"
    if not p.is_file():
        return set()
    try:
        text = p.read_text(encoding="utf-8")
    except OSError:
        return set()
    return set(WIKILINK_RE.findall(text))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Zero-LLM structural integrity check for a cogni-wiki"
    )
    parser.add_argument("--wiki-root", required=True)
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    raw_dir = wiki_root / "raw"

    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki (no .cogni-wiki/config.json under {wiki_root})")
    fail_if_pre_migration(wiki_root)

    errors: list = []
    warnings: list = []

    # Build the in-memory slug index once. Includes audit reports because
    # `wiki://` and `[[wikilink]]` targets may legitimately point at lint-/
    # health-prefixed pages and must resolve.
    slug_index = build_slug_index(wiki_root, include_audit=True)
    all_pages: dict = {}
    inbound_links: dict = {}

    for slug, page_path, ptype in iter_pages(wiki_root, include_audit=True):
        try:
            text = page_path.read_text(encoding="utf-8")
        except OSError as e:
            errors.append(
                {"class": "read_error", "page": slug, "message": str(e)}
            )
            continue
        fm, body = parse_frontmatter(text)
        all_pages[slug] = {"fm": fm, "body": body, "type": ptype}

        # Audit reports (lint-*, health-*) are exempt from frontmatter and
        # source schema; they're audit artefacts, not knowledge pages. We
        # still scan them for outbound wikilinks so broken-target detection
        # picks up audit-report references.
        if ptype == "audit" or is_audit_slug(slug):
            for target in WIKILINK_RE.findall(text):
                inbound_links.setdefault(target, set()).add(slug)
            continue

        for field in REQUIRED_FRONTMATTER:
            if field not in fm or fm[field] in (None, "", []):
                errors.append(
                    {
                        "class": "missing_frontmatter",
                        "page": slug,
                        "message": f"missing required field '{field}'",
                    }
                )

        if fm.get("id") and fm["id"] != slug:
            errors.append(
                {
                    "class": "id_mismatch",
                    "page": slug,
                    "message": f"frontmatter id '{fm['id']}' != filename '{slug}'",
                }
            )

        fm_type = fm.get("type")
        if fm_type and fm_type not in VALID_TYPES:
            errors.append(
                {
                    "class": "invalid_type",
                    "page": slug,
                    "message": f"type '{fm_type}' not in {sorted(VALID_TYPES)}",
                }
            )
        # Cross-check: frontmatter type must match the directory the page
        # was found in. Catches a hand-edited frontmatter that drifts away
        # from the on-disk routing.
        if fm_type and fm_type in VALID_TYPES and fm_type != ptype:
            errors.append(
                {
                    "class": "type_directory_mismatch",
                    "page": slug,
                    "message": f"frontmatter type '{fm_type}' but page lives under wiki/{ptype}/",
                }
            )

        sources = fm.get("sources", [])
        if isinstance(sources, list):
            for src in sources:
                if isinstance(src, str) and src.startswith("../raw/"):
                    rel = src[len("../raw/") :]
                    if not (raw_dir / rel).exists():
                        errors.append(
                            {
                                "class": "missing_source",
                                "page": slug,
                                "message": f"source file not found: raw/{rel}",
                            }
                        )
                elif isinstance(src, str) and src.startswith("wiki://"):
                    target = src[len("wiki://") :].strip()
                    if not target or target not in slug_index:
                        errors.append(
                            {
                                "class": "broken_wiki_source",
                                "page": slug,
                                "message": f"wiki:// source not found: wiki://{target}",
                            }
                        )

        if len(body.strip()) < STUB_PAGE_MIN_CHARS:
            warnings.append(
                {
                    "class": "stub_page",
                    "page": slug,
                    "message": (
                        f"body is {len(body.strip())} chars (< {STUB_PAGE_MIN_CHARS}); "
                        f"expand or delete"
                    ),
                }
            )

        for target in WIKILINK_RE.findall(text):
            inbound_links.setdefault(target, set()).add(slug)

    existing_slugs = set(all_pages.keys())
    for slug, sources in sorted(inbound_links.items()):
        if slug not in existing_slugs:
            for source_slug in sorted(sources):
                errors.append(
                    {
                        "class": "broken_wikilink",
                        "page": source_slug,
                        "message": f"[[{slug}]] target does not exist",
                    }
                )

    non_audit_pages = {
        s for s, info in all_pages.items()
        if info["type"] != "audit" and not is_audit_slug(s)
    }
    cfg = _load_config(wiki_root)
    entries_count_config = (
        int(cfg["entries_count"])
        if isinstance(cfg.get("entries_count"), int)
        else 0
    )
    entries_count_actual = len(non_audit_pages)
    entries_count_drift = entries_count_actual - entries_count_config
    if entries_count_drift != 0:
        warnings.append(
            {
                "class": "entries_count_drift",
                "page": "*",
                "message": (
                    f".cogni-wiki/config.json entries_count={entries_count_config} "
                    f"but filesystem has {entries_count_actual} "
                    f"(drift={entries_count_drift:+d})"
                ),
            }
        )

    index_slugs = _index_slugs(wiki_root)
    if index_slugs:
        in_index_not_fs = sorted(index_slugs - existing_slugs)
        in_fs_not_index = sorted(non_audit_pages - index_slugs)
        for slug in in_index_not_fs:
            warnings.append(
                {
                    "class": "index_filesystem_drift",
                    "page": slug,
                    "message": f"appears in wiki/index.md but no page file exists",
                }
            )
        for slug in in_fs_not_index:
            warnings.append(
                {
                    "class": "index_filesystem_drift",
                    "page": slug,
                    "message": f"page exists but is not referenced in wiki/index.md",
                }
            )

    resweep = _load_last_resweep(wiki_root)
    claim_drift_count = 0
    claim_drift_date = None
    if resweep:
        claim_drift_date = resweep.get("sweep_date")
        deviated = resweep.get("deviated_pages") or []
        unavailable = resweep.get("unavailable_pages") or []
        flagged = {s for s in (list(deviated) + list(unavailable)) if s in existing_slugs}
        claim_drift_count = len(flagged)

    ok(
        {
            "errors": errors,
            "warnings": warnings,
            "stats": {
                "pages_audited": entries_count_actual,
                "errors": len(errors),
                "warnings": len(warnings),
                "entries_count_config": entries_count_config,
                "entries_count_actual": entries_count_actual,
                "entries_count_drift": entries_count_drift,
                "claim_drift_count": claim_drift_count,
                "claim_drift_date": claim_drift_date,
                "checked_at": dt.date.today().isoformat(),
            },
        }
    )


if __name__ == "__main__":
    main()
