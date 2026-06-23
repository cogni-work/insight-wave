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
        - Missing ../../raw/ source files
        - Broken wiki:// sources (target page does not exist)
        - Read errors
    Warnings (structural debt only — semantic warnings live in wiki-lint):
        - Stub pages (body shorter than STUB_PAGE_MIN_CHARS)
        - entries_count drift between config.json and filesystem
        - index.md <-> filesystem drift (entries on one side missing on the other)
        - schema_version_lag: config schema_version trails the engine's current
          expected structure (ENGINE_SCHEMA)
        - structural_drift: a machine-owned curated front-door region a completed
          phase should have populated is still on its bootstrap placeholder
          (OVERVIEW-NARRATIVE) or empty-state sentinel (ROOT-LINKS)
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
    CONTROL_FILES,
    SUBINDEXED_TYPE_DIRS,
    VALID_TYPES,
    WIKILINK_RE,
    build_slug_index,
    fail,
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
    ok,
    split_frontmatter,
    version_at_least,
)


STUB_PAGE_MIN_CHARS = 50
REQUIRED_FRONTMATTER = {"id", "title", "type", "created", "updated"}

# The curated layout (schema_version >= 0.0.8) moves the visible control
# files off the flat wiki/ root into wiki/meta/.
CURATED_LAYOUT_SCHEMA = "0.0.8"

# The engine's current expected wiki schema. A curated base recorded behind
# this lags the structure the engine now produces — a read-forward, additive
# gap surfaced as a warning, not a hard fail (0.0.5 stays the hard-fail
# boundary, owned by fail_if_pre_migration).
ENGINE_SCHEMA = "0.0.9"

# The cogni-knowledge plugin version whose index renderers produced the
# *current* curated machine-owned indexes. Tracks plugin.json::version and MUST
# be bumped in lockstep with it whenever an index renderer (root_index.py /
# sub_index.py / perspectives_index.py) ships a change — the same manual-sync
# discipline ENGINE_SCHEMA already carries for the wiki schema. A base whose
# stamped `last_rendered_engine_version` trails this lags a shipped renderer
# upgrade (render_engine_lag); the renderers stamp the field on every live
# render via _knowledge_lib.stamp_render_engine_version.
ENGINE_RENDER_VERSION = "1.0.53"

# Bootstrap state a completed phase should have replaced. `knowledge-setup`
# seeds the OVERVIEW-NARRATIVE block with this placeholder and `root_index.py`
# renders an empty ROOT-LINKS span with the sentinel; a finalized base that
# still carries either has a degraded curated front door.
OVERVIEW_BOOTSTRAP_PLACEHOLDER = (
    "_Overview pending — authored on the first knowledge-finalize run._"
)
ROOT_LINKS_EMPTY_SENTINEL = "_(no pages yet)_"


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


def _check_curated_layout(
    wiki_root: Path, cfg: dict, errors: list, warnings: list
) -> None:
    """Assert the curated layout on a schema >= 0.0.8 base.

    Errors (repair via `knowledge-lint --fix=misplaced_control_files`):
        - a control file (log.md / context_brief.md / open_questions.md) at
          the flat wiki/ root instead of wiki/meta/
        - wiki/meta/ missing entirely
        - overview.md still carrying the OVERVIEW-NARRATIVE machine block
          (the narrative folds into the index.md intro; only the pointer
          stub + `## Recent syntheses` list stay)
    Warnings:
        - a sub-indexed type dir with pages but no machine-owned index.md

    A pre-0.0.8 base predates the curated layout, so nothing fires — the
    0.0.5 hard-fail boundary stays owned by fail_if_pre_migration.
    """
    schema = str(cfg.get("schema_version", ""))
    if not schema or not version_at_least(schema, CURATED_LAYOUT_SCHEMA):
        return
    wiki_dir = wiki_root / "wiki"

    if not (wiki_dir / "meta").is_dir():
        errors.append(
            {
                "class": "curated_layout_violation",
                "page": "(wiki/meta/)",
                "message": (
                    f"wiki/meta/ missing — control files live under "
                    f"wiki/meta/ since schema {CURATED_LAYOUT_SCHEMA}; "
                    f"run knowledge-lint --fix=misplaced_control_files"
                ),
            }
        )
    for name in CONTROL_FILES:
        if (wiki_dir / name).is_file():
            errors.append(
                {
                    "class": "curated_layout_violation",
                    "page": f"(wiki/{name})",
                    "message": (
                        f"control file at the flat wiki/ root; belongs in "
                        f"wiki/meta/{name} since schema "
                        f"{CURATED_LAYOUT_SCHEMA}; run knowledge-lint "
                        f"--fix=misplaced_control_files"
                    ),
                }
            )
    overview = wiki_dir / "overview.md"
    if overview.is_file():
        try:
            text = overview.read_text(encoding="utf-8")
        except OSError as exc:
            # Unreadable means the narrative fold CANNOT be verified —
            # surface that rather than silently passing the layout check.
            errors.append(
                {
                    "class": "curated_layout_violation",
                    "page": "(wiki/overview.md)",
                    "message": (
                        f"overview.md unreadable ({exc}) — cannot verify "
                        f"the narrative fold; fix permissions/encoding"
                    ),
                }
            )
            text = ""
        if "MACHINE-OWNED:OVERVIEW-NARRATIVE" in text:
            errors.append(
                {
                    "class": "curated_layout_violation",
                    "page": "(wiki/overview.md)",
                    "message": (
                        "overview.md still carries the OVERVIEW-NARRATIVE "
                        "machine block; the curated layout folds it into "
                        "the index.md intro (overview.md stays as a stub) — "
                        "run knowledge-lint --fix=misplaced_control_files"
                    ),
                }
            )
    for dirname in sorted(SUBINDEXED_TYPE_DIRS):
        d = wiki_dir / dirname
        if not d.is_dir():
            continue
        has_pages = any(
            p.name != "index.md" for p in d.glob("*.md")
        )
        if has_pages and not (d / "index.md").is_file():
            warnings.append(
                {
                    "class": "missing_subindex",
                    "page": f"(wiki/{dirname}/)",
                    "message": (
                        f"wiki/{dirname}/ has pages but no machine-owned "
                        f"index.md sub-index; re-render via "
                        f"knowledge-index"
                    ),
                }
            )


def _machine_block_pattern(name: str) -> str:
    """Regex source for a MACHINE-OWNED:<name>:START..:END span (group 1 = inner).

    The single source of truth for the comment-delimiter shape, shared by the
    first-span helper below and the all-spans ROOT-LINKS scan.
    """
    esc = re.escape(name)
    return (
        r"<!--\s*MACHINE-OWNED:" + esc + r":START\s*-->"
        r"(.*?)<!--\s*MACHINE-OWNED:" + esc + r":END\s*-->"
    )


def _extract_machine_block(text: str, name: str) -> str | None:
    """Inner text of the first MACHINE-OWNED:<name>:START..:END span, or None.

    Self-contained port of _knowledge_lib.extract_machine_block — the vendored
    engine imports only from _wikilib, so health.py must not reach into
    cogni-knowledge's _knowledge_lib.
    """
    m = re.search(_machine_block_pattern(name), text, re.DOTALL)
    return m.group(1) if m else None


def _check_structural_drift(
    wiki_root: Path, cfg: dict, errors: list, warnings: list
) -> None:
    """Flag structural / schema drift on a curated (schema >= 0.0.8) base.

    Read-only and fail-soft, distinct from the numeric count-drift checks:
        - schema_version_lag: config schema_version trails the engine's current
          ENGINE_SCHEMA (a read-forward gap; repair via knowledge-index --migrate)
        - render_engine_lag: the stamped last_rendered_engine_version trails the
          installed ENGINE_RENDER_VERSION (or is absent) — the curated indexes
          were rendered by an older engine and may lag a shipped renderer
          upgrade (repair via a knowledge-index rebuild)
        - structural_drift: a machine-owned curated front-door region a completed
          phase should have populated is still on its bootstrap placeholder
          (OVERVIEW-NARRATIVE) or empty-state sentinel (ROOT-LINKS)

    Never fires on a pre-0.0.8 base (same guard as _check_curated_layout). All
    findings are warnings — a degraded front door moves the verdict OK -> WARN,
    never to a hard error.
    """
    schema = str(cfg.get("schema_version", ""))
    if not schema or not version_at_least(schema, CURATED_LAYOUT_SCHEMA):
        return

    # (a) schema_version lag behind the engine's current expected structure.
    if not version_at_least(schema, ENGINE_SCHEMA):
        warnings.append(
            {
                "class": "schema_version_lag",
                "page": "(.cogni-wiki/config.json)",
                "message": (
                    f"schema_version={schema} trails the engine's expected "
                    f"{ENGINE_SCHEMA}; run knowledge-index --migrate to "
                    f"converge the curated layout"
                ),
            }
        )

    # (a.2) render-engine lag: the curated indexes were produced by a plugin
    # version behind the installed one (a shipped renderer upgrade not yet
    # re-rendered), or carry no engine stamp at all (rendered before the stamp
    # landed). Read-forward + fail-soft; repaired by a knowledge-index rebuild,
    # which re-renders and re-stamps last_rendered_engine_version.
    rendered = str(cfg.get("last_rendered_engine_version", "")).strip()
    if not rendered:
        warnings.append(
            {
                "class": "render_engine_lag",
                "page": "(.cogni-wiki/config.json)",
                "message": (
                    "no last_rendered_engine_version recorded — the curated "
                    f"indexes may predate the installed engine {ENGINE_RENDER_VERSION}; "
                    "run knowledge-index to rebuild and record the engine version"
                ),
            }
        )
    elif not version_at_least(rendered, ENGINE_RENDER_VERSION):
        warnings.append(
            {
                "class": "render_engine_lag",
                "page": "(.cogni-wiki/config.json)",
                "message": (
                    f"last_rendered_engine_version={rendered} trails the installed "
                    f"engine {ENGINE_RENDER_VERSION}; run knowledge-index to "
                    "re-render with the upgraded index renderers"
                ),
            }
        )

    # (b) + (c) curated front-door regions left on their bootstrap state. Fires
    # only when the machine-owned region is PRESENT and unpopulated, so a base
    # whose index.md carries no such region (e.g. a minimal fixture) is silent.
    index_path = wiki_root / "wiki" / "index.md"
    if not index_path.is_file():
        return
    try:
        index_text = index_path.read_text(encoding="utf-8")
    except OSError:
        # Unreadable index.md — stay fail-soft (the curated-layout check owns
        # hard structural errors; this read-only drift pass never aborts).
        return

    overview = _extract_machine_block(index_text, "OVERVIEW-NARRATIVE")
    if overview is not None and overview.strip() == OVERVIEW_BOOTSTRAP_PLACEHOLDER:
        warnings.append(
            {
                "class": "structural_drift",
                "page": "(wiki/index.md)",
                "message": (
                    "OVERVIEW-NARRATIVE is still the bootstrap placeholder "
                    "though a finalize should have authored it; re-run "
                    "knowledge-finalize (or knowledge-index --repair) to "
                    "regenerate the curated front door"
                ),
            }
        )

    root_links_re = re.compile(_machine_block_pattern("ROOT-LINKS"), re.DOTALL)
    for m in root_links_re.finditer(index_text):
        if m.group(1).strip() == ROOT_LINKS_EMPTY_SENTINEL:
            warnings.append(
                {
                    "class": "structural_drift",
                    "page": "(wiki/index.md)",
                    "message": (
                        "a ROOT-LINKS span carries no theme-scoped deep links "
                        "(still the empty-state sentinel); re-run "
                        "knowledge-index to populate the curated root map"
                    ),
                }
            )
            break


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
        fm, body = split_frontmatter(text)
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
                if isinstance(src, str) and (
                    src.startswith("../") or src.startswith("./")
                ):
                    # Relative-path raw-source citation. Resolve from the page's
                    # ACTUAL on-disk location rather than decoding the literal
                    # `../raw/` prefix by convention — pages live two levels deep
                    # (wiki/<type>/<slug>.md) since schema 0.0.5, so a `../raw/`
                    # citation resolves to the non-existent wiki/raw/ instead of
                    # <wiki-root>/raw/. The correct form is `../../raw/`. The old
                    # string-strip check passed regardless of depth as long as
                    # raw/<tail> existed, so a depth-wrong (unreachable) citation
                    # shipped "health clean". Resolving from page_path.parent
                    # catches the depth bug regardless of the literal string.
                    resolved = (page_path.parent / src).resolve()
                    in_raw = resolved == raw_dir or raw_dir in resolved.parents
                    if not in_raw:
                        errors.append(
                            {
                                "class": "missing_source",
                                "page": slug,
                                "message": (
                                    f"raw source citation does not resolve under "
                                    f"raw/: '{src}' from wiki/{ptype}/ points at "
                                    f"{resolved} (use ../../raw/<file>)"
                                ),
                            }
                        )
                    elif not resolved.exists():
                        errors.append(
                            {
                                "class": "missing_source",
                                "page": slug,
                                "message": (
                                    f"source file not found: "
                                    f"raw/{resolved.name} (cited as '{src}')"
                                ),
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

    _check_curated_layout(wiki_root, cfg, errors, warnings)
    _check_structural_drift(wiki_root, cfg, errors, warnings)

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
