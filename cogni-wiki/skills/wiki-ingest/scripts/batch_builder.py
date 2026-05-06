#!/usr/bin/env python3
"""
batch_builder.py — enumerate candidate sources and emit a valid wiki-ingest
batch-mode payload on stdout.

The wiki-ingest batch-mode reference doc already describes the schema
`{"sources": [{"source": "...", "title": "...", "type": "...", "tags": [...]}]}`
and the fail-fast validator in Step 0 of the skill. What did not exist before
this script: any way to *produce* that payload without the user (or
Claude-on-behalf-of-the-user) hand-typing it. For the Phase 2 pilot rebuild
(~164 skill+agent pages across a sibling monorepo), hand-typing does not
scale; the skill was effectively half-shipped.

This script is the missing half. It only enumerates — it never writes to the
wiki. That preserves the "review before ingest" discipline: a user can pipe
this to a file, eyeball it, and then pass the file to `wiki-ingest
--batch-file`, or use the skill's `--discover` flag to glue the two calls
together.

Discovery modes (exactly one required):

    --glob PATTERN      Walk the filesystem starting at --root (default: the
                        wiki root, i.e. the parent of .cogni-wiki/) and emit
                        each matching file as a sources[] entry. Supports
                        recursive glob via ** and the standard fnmatch
                        metacharacters. Patterns are resolved relative to
                        --root; absolute patterns are honoured as-is.

    --orphans           Files under <wiki-root>/raw/ that are not referenced
                        by any page's `sources:` frontmatter entry. Mirrors
                        the orphan_raw_count logic in wiki_status.sh but
                        returns the filenames themselves.

    --stubs             Pages under <wiki-root>/wiki/<type>/ whose frontmatter
                        has `status: draft`. With --older-than-days N, restrict
                        to drafts whose `updated:` date is more than N days
                        old. Stubs re-enter the wiki via the mode: re-ingest
                        branch of Step 1, which is the intended refresh path.

    --research SLUG     A cogni-research project at `cogni-research-<SLUG>/`
                        relative to the workspace root (override with
                        --research-root). One batch entry per sub-question is
                        emitted; the source field points at a synthesised
                        markdown file written to
                        `<wiki-root>/raw/research-<SLUG>/sq-NN-<short>.md`.
                        Materialisation is unavoidable here: cogni-research
                        spreads each sub-question's evidence across four
                        entity types (sub-question + contexts + sources +
                        verified report-claims) and wiki-ingest's per-source
                        worker reads exactly one file. The synthesis is
                        deterministic — re-running with the same inputs
                        overwrites byte-identically. This is the one
                        discovery mode that writes to the wiki; pair with
                        --discover-dry-run if you want to inspect the planned
                        materialisation without fan-out.

Filters (compose freely with any discovery mode):

    --exclude-ingested  Drop any source whose derived slug already exists in
                        the wiki's per-type directories (any of
                        wiki/concepts/, wiki/decisions/, …). Key dedupe for
                        the "ingest everything not yet in the wiki" use case
                        — safe to rerun after partial progress.

    --type TYPE         Apply as the per-entry `type` default (one of:
                        concept, entity, summary, decision, interview,
                        meeting, learning, note).
    --tags a,b,c        Apply as the per-entry `tags` default.
    --research-root P   Override the auto-located cogni-research project root.
                        Default lookup tries `<workspace>/cogni-research-<SLUG>/`
                        where workspace is the wiki root's parent.

    --no-materialize    Pair with --research: enumerate only, skip the
                        per-sub-question raw file writes. The emitted batch
                        still references the would-be paths; pair this with
                        --discover-dry-run when reviewing without polluting
                        raw/. A subsequent run without --no-materialize will
                        write the files deterministically.

    --title-template T  Python-style format string for the per-entry title,
                        derived from the discovered path. Placeholders:
                            {stem}      filename without extension
                            {parent}    immediate parent directory name
                            {parent2}   two directories up
                            {parent3}   three directories up
                            {parts[-N]} any negative index into Path.parts
                        Example: for paths like
                        `../cogni-claims/skills/claim-entity/SKILL.md` in a
                        wiki whose existing slug convention is
                        `skill-cogni-claims-claim-entity`, pass
                        `--title-template 'skill-{parent3}-{parent}'`.
                        When --title-template is set, the derived title is
                        also used by --exclude-ingested for slug comparison.
    --limit N           Cap the emitted sources[] at N entries.

Output contract:

    {
      "success": true,
      "data": {
        "mode": "glob" | "orphans" | "stubs" | "research",
        "count": <int>,
        "skipped_existing": <int>,
        "sources": [ { "source": "...", ... }, ... ]
      },
      "error": ""
    }

    On failure: {"success": false, "data": {}, "error": "..."} with exit 1.

Slug derivation matches the skill's rule: lowercase the filename (or the
last URL segment), strip the extension, replace any run of non-[a-z0-9]
characters with a hyphen, trim leading/trailing hyphens. This has to stay in
sync with the SKILL.md Step 1 rule or --exclude-ingested will miss dedupes.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import os
import re
import sys
from pathlib import Path
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import (  # noqa: E402
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
)


VALID_TYPES = {"concept", "entity", "summary", "decision", "interview", "meeting", "learning", "note"}
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
SLUG_CLEAN_RE = re.compile(r"[^a-z0-9]+")


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def derive_slug(source: str) -> str:
    """Mirror the skill's slug derivation rule.

    The orchestrator in SKILL.md uses the title if given, else the filename
    or URL tail. This script does not know about per-entry titles (they are
    opt-in downstream), so the discovery-time slug is always filename-based.
    That is the right default for --exclude-ingested: if the user later
    overrides the title in the batch file, the dedupe may miss — but the
    re-ingest branch of Step 1 catches it safely.
    """
    tail = source.rstrip("/").split("/")[-1]
    base = tail.rsplit(".", 1)[0] if "." in tail else tail
    slug = SLUG_CLEAN_RE.sub("-", base.lower()).strip("-")
    return slug


def parse_frontmatter(text: str) -> dict:
    """Same shape as lint_wiki.py's parser — keep them structurally aligned."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
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
    return out


def parse_date(s: str):
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


def find_wiki_root(start: Path) -> Path:
    """Walk up looking for .cogni-wiki/config.json."""
    current = start.resolve()
    while True:
        if (current / ".cogni-wiki" / "config.json").is_file():
            return current
        if current.parent == current:
            fail(f"not inside a cogni-wiki (no .cogni-wiki/config.json at or above {start})")
        current = current.parent


def existing_slugs(wiki_root: Path) -> set:
    return {slug for slug, _path, _ptype in iter_pages(wiki_root) if not is_audit_slug(slug)}


def discover_glob(pattern: str, root: Path) -> list:
    """Resolve a glob pattern against root. Supports ** recursion via pathlib."""
    if os.path.isabs(pattern):
        base = Path(pattern).anchor
        rel = pattern[len(base):]
        results = list(Path(base).glob(rel))
    else:
        results = list(root.glob(pattern))
    # Stable ordering so reruns produce identical output.
    return sorted(str(p) for p in results if p.is_file())


def discover_orphans(wiki_root: Path) -> list:
    """Files under raw/ that no page cites in its sources: frontmatter."""
    raw_dir = wiki_root / "raw"
    if not raw_dir.is_dir():
        return []
    cited: set = set()
    for _slug, page, _ptype in iter_pages(wiki_root):
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        sources = fm.get("sources", [])
        if isinstance(sources, list):
            for s in sources:
                if not isinstance(s, str):
                    continue
                # Paths in sources are typically ../raw/foo.pdf — we only
                # care about the filename tail for orphan detection.
                cited.add(s.rstrip("/").split("/")[-1])
    orphans = []
    for item in sorted(raw_dir.iterdir()):
        if not item.is_file():
            continue
        if item.name.startswith("."):
            continue
        if item.name not in cited:
            orphans.append(str(item))
    return orphans


def discover_stubs(wiki_root: Path, older_than_days: int | None) -> list:
    """Pages with status: draft (optionally filtered by age)."""
    today = dt.date.today()
    stubs = []
    for slug, page, _ptype in iter_pages(wiki_root):
        if is_audit_slug(slug):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        status = fm.get("status", "")
        if not (isinstance(status, str) and status.strip().lower() == "draft"):
            continue
        if older_than_days is not None:
            updated = parse_date(fm.get("updated", "") if isinstance(fm.get("updated"), str) else "")
            if updated is None:
                # No valid updated date — treat as eligible (conservative:
                # a stale draft without a date is exactly what needs rebuild).
                pass
            else:
                age = (today - updated).days
                if age <= older_than_days:
                    continue
        # For stubs, the source pointer is the page itself — re-ingest
        # reads the page's cited source and re-synthesises. But the batch
        # entry still needs a `source:` field. Use the first entry in the
        # page's sources: frontmatter as the ingest input; if none, point
        # at the page path itself as a fallback.
        sources = fm.get("sources", [])
        first_source = None
        if isinstance(sources, list) and sources:
            if isinstance(sources[0], str):
                first_source = sources[0]
        stubs.append({"page": str(page), "source": first_source or str(page), "slug": slug})
    return stubs


def _truncate_title(text: str, limit: int = 80) -> str:
    """Single-line, length-capped title for a sub-question batch entry.

    The downstream slug derivation (SKILL Step 1) cleans non-[a-z0-9] runs to
    hyphens, so a long title yields a long slug. Cap aggressively; the full
    query stays in the materialised page body and frontmatter.
    """
    one_line = " ".join(text.split())
    if len(one_line) <= limit:
        return one_line.rstrip(" .?!,;:")
    cut = one_line[: limit].rsplit(" ", 1)[0]
    return cut.rstrip(" .?!,;:")


def _read_research_entity(path: Path) -> tuple[dict, str]:
    """Read a cogni-research .md entity → (frontmatter dict, body text).

    Re-uses the script's own frontmatter parser; cogni-research entities use
    the same YAML-subset shape as wiki pages (top-level scalars + `- ` list
    items), so the parser already handles the shapes that matter here.
    """
    text = path.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    body = FRONTMATTER_RE.sub("", text, count=1).lstrip("\n")
    return fm, body


def _unquote(s: str) -> str:
    """Strip surrounding single or double quotes from a YAML scalar."""
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def _strip_wikilink(ref: str) -> str:
    """`[[01-contexts/data/ctx-foo-12345678]]` → `ctx-foo-12345678`.

    Tolerant of surrounding quotes — cogni-research's create-entity.py emits
    quoted wikilinks because YAML treats `[[…]]` as a flow-sequence start
    otherwise. The script's parse_frontmatter keeps the quotes verbatim.
    """
    inner = _unquote(ref)
    if inner.startswith("[[") and inner.endswith("]]"):
        inner = inner[2:-2]
    return inner.rsplit("/", 1)[-1]


def _locate_research_project(slug_or_path: str, wiki_root: Path, override: str | None) -> Path:
    """Resolve --research SLUG to a project directory.

    Lookup order:
      1. --research-root if given (must point at the project dir directly).
      2. The slug itself if it contains a path separator (relative to cwd, then absolute).
      3. `<workspace>/cogni-research-<slug>/` where workspace = wiki_root.parent.
      4. `<wiki_root>/cogni-research-<slug>/` (e.g. wiki sits at workspace root).
    Fail with the candidates checked so the user can correct the layout.
    """
    if override:
        project = Path(override).resolve()
        if not project.is_dir():
            fail(f"--research-root not a directory: {project}")
        return project

    if "/" in slug_or_path or slug_or_path.startswith("."):
        candidate = Path(slug_or_path).resolve()
        if candidate.is_dir():
            return candidate
        fail(f"--research path not found: {candidate}")

    slug = slug_or_path
    candidates = [
        wiki_root.parent / f"cogni-research-{slug}",
        wiki_root / f"cogni-research-{slug}",
    ]
    for c in candidates:
        if c.is_dir():
            return c.resolve()
    fail(
        "cogni-research project not found. Tried: "
        + ", ".join(str(c) for c in candidates)
        + ". Pass --research-root to override."
    )
    return Path()  # unreachable


def _load_sub_questions(project: Path) -> list[dict]:
    """Read all sq-*.md and return entity dicts ordered by section_index."""
    sq_dir = project / "00-sub-questions" / "data"
    if not sq_dir.is_dir():
        fail(f"sub-questions dir missing: {sq_dir}")
    items: list[dict] = []
    for path in sorted(sq_dir.glob("sq-*.md")):
        fm, _ = _read_research_entity(path)
        if not fm.get("query"):
            continue
        try:
            section_index = int(fm.get("section_index", 0))
        except (TypeError, ValueError):
            section_index = 0
        items.append({
            "id": _unquote(fm.get("dc:identifier") or path.stem),
            "query": _unquote(fm["query"]),
            "parent_topic": _unquote(fm.get("parent_topic", "")),
            "section_index": section_index,
            "status": _unquote(fm.get("status", "")),
            "path": path,
        })
    items.sort(key=lambda x: (x["section_index"], x["id"]))
    return items


def _index_research_entities(project: Path) -> tuple[dict, dict, list[dict]]:
    """Pre-load contexts (by sub_question id), sources (by id), and verified claims.

    Returns:
      contexts_by_sq: { sq_id: [context dict, ...] }
      sources_by_id:  { src_id: source dict }
      verified_claims: list of report-claim dicts with verification_status='verified'
    """
    contexts_by_sq: dict[str, list[dict]] = {}
    ctx_dir = project / "01-contexts" / "data"
    if ctx_dir.is_dir():
        for path in sorted(ctx_dir.glob("ctx-*.md")):
            fm, body = _read_research_entity(path)
            sq_ref = fm.get("sub_question_ref", "")
            sq_id = _strip_wikilink(sq_ref) if isinstance(sq_ref, str) else ""
            source_refs = fm.get("source_refs", []) or []
            if not isinstance(source_refs, list):
                source_refs = []
            contexts_by_sq.setdefault(sq_id, []).append({
                "id": fm.get("dc:identifier") or path.stem,
                "source_ids": [_strip_wikilink(r) for r in source_refs if isinstance(r, str)],
                "body": body.strip(),
            })

    sources_by_id: dict[str, dict] = {}
    src_dir = project / "02-sources" / "data"
    if src_dir.is_dir():
        for path in sorted(src_dir.glob("src-*.md")):
            fm, _ = _read_research_entity(path)
            sid = fm.get("dc:identifier") or path.stem
            sources_by_id[_unquote(sid)] = {
                "id": _unquote(sid),
                "url": _unquote(fm.get("url", "")),
                "title": _unquote(fm.get("title", "")),
                "publisher": _unquote(fm.get("publisher", "")),
            }

    verified_claims: list[dict] = []
    rc_dir = project / "03-report-claims" / "data"
    if rc_dir.is_dir():
        for path in sorted(rc_dir.glob("rc-*.md")):
            fm, _ = _read_research_entity(path)
            if fm.get("verification_status") != "verified":
                continue
            verified_claims.append({
                "id": _unquote(fm.get("dc:identifier") or path.stem),
                "statement": _unquote(fm.get("statement", "")),
                "section": _unquote(fm.get("section", "")),
                "source_id": _strip_wikilink(fm.get("source_ref", "")) if isinstance(fm.get("source_ref"), str) else "",
                "source_url": _unquote(fm.get("source_url", "")),
                "source_title": _unquote(fm.get("source_title", "")),
                "verified_at": _unquote(fm.get("verified_at", "")),
            })

    return contexts_by_sq, sources_by_id, verified_claims


def _render_synthesis(
    sq: dict,
    contexts: list[dict],
    sources_by_id: dict,
    verified_claims: list[dict],
    project_slug: str,
) -> tuple[str, list[dict]]:
    """Compose the per-sub-question markdown body and collect cited sources.

    Returns (body_text, cited_sources_list). The cited list is ordered by first
    appearance and goes into both the body's Sources section and the page's
    sources: frontmatter (set later by the wiki-ingest worker via Step 1, which
    will pick the synthesised file as a single raw/ source — the inline URL
    list inside the body lets the worker discover them on read).
    """
    # Collect source IDs in deterministic order: contexts first (in context
    # order, source order within each), then any verified-claim sources not
    # yet seen.
    cited_ids: list[str] = []
    seen: set = set()
    for ctx in contexts:
        for sid in ctx["source_ids"]:
            if sid and sid not in seen:
                seen.add(sid)
                cited_ids.append(sid)

    # Match verified claims to this sub-question by source overlap (the
    # cleanest structural join — claim.source_ref ∈ context.source_refs of
    # this sub-question's contexts). A claim with no overlap belongs to a
    # different section and is not included here.
    sq_claims = [c for c in verified_claims if c["source_id"] in seen]

    # Pull in any verified-claim sources we haven't already listed (rare —
    # claims usually cite a context source — but cover the case).
    for c in sq_claims:
        if c["source_id"] and c["source_id"] not in seen:
            seen.add(c["source_id"])
            cited_ids.append(c["source_id"])

    cited_sources = [sources_by_id[sid] for sid in cited_ids if sid in sources_by_id]

    lines: list[str] = []
    lines.append(f"# {sq['query']}")
    lines.append("")
    lines.append(
        f"*Synthesised from cogni-research project `{project_slug}` "
        f"(topic: {sq['parent_topic'] or '—'}, sub-question {sq['section_index']:02d}).*"
    )
    lines.append("")

    if contexts:
        lines.append("## Findings")
        lines.append("")
        for ctx in contexts:
            if ctx["body"]:
                lines.append(ctx["body"])
                lines.append("")

    if sq_claims:
        lines.append("## Verified claims")
        lines.append("")
        for c in sq_claims:
            url = c["source_url"] or (sources_by_id.get(c["source_id"], {}).get("url", ""))
            tail = f" ([source]({url}))" if url else ""
            verified_tag = f" — verified {c['verified_at'][:10]}" if c["verified_at"] else ""
            lines.append(f"- {c['statement']}{tail}{verified_tag}")
        lines.append("")

    if cited_sources:
        lines.append("## Sources")
        lines.append("")
        for s in cited_sources:
            label = s["title"] or s["url"] or s["id"]
            url = s["url"]
            pub = f" — {s['publisher']}" if s["publisher"] else ""
            if url:
                lines.append(f"- [{label}]({url}){pub}")
            else:
                lines.append(f"- {label}{pub}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n", cited_sources


def _short_slug(text: str, limit: int = 40) -> str:
    """Filename-safe short slug for the materialised raw file."""
    base = SLUG_CLEAN_RE.sub("-", text.lower()).strip("-")
    if len(base) <= limit:
        return base or "untitled"
    cut = base[:limit].rsplit("-", 1)[0]
    return cut.rstrip("-") or base[:limit].rstrip("-") or "untitled"


def discover_research(
    slug_or_path: str,
    wiki_root: Path,
    research_root_override: str | None,
    materialize: bool,
) -> tuple[list, dict]:
    """Enumerate one batch entry per sub-question; materialise per-sq raw files.

    Returns (entries, stats). Stats captures sub-question/context/source/claim
    counts for the Step 0 report so the user knows what they're about to ingest.
    """
    project = _locate_research_project(slug_or_path, wiki_root, research_root_override)

    project_slug = project.name
    if project_slug.startswith("cogni-research-"):
        project_slug = project_slug[len("cogni-research-"):]

    config_path = project / "project-config.json"
    if not config_path.is_file():
        fail(f"not a cogni-research project (missing project-config.json): {project}")

    sub_questions = _load_sub_questions(project)
    if not sub_questions:
        return [], {
            "project": str(project),
            "project_slug": project_slug,
            "sub_questions": 0,
            "contexts": 0,
            "sources": 0,
            "verified_claims": 0,
            "materialised": 0,
        }

    contexts_by_sq, sources_by_id, verified_claims = _index_research_entities(project)

    raw_subdir_name = f"research-{project_slug}"
    raw_subdir = wiki_root / "raw" / raw_subdir_name
    if materialize:
        raw_subdir.mkdir(parents=True, exist_ok=True)

    entries: list[dict] = []
    materialised = 0
    total_contexts = 0
    for sq in sub_questions:
        contexts = contexts_by_sq.get(sq["id"], [])
        total_contexts += len(contexts)
        body, _cited = _render_synthesis(
            sq, contexts, sources_by_id, verified_claims, project_slug
        )

        short = _short_slug(sq["query"])
        filename = f"sq-{sq['section_index']:02d}-{short}.md"
        out_path = raw_subdir / filename

        if materialize:
            tmp = out_path.with_suffix(".md.tmp")
            tmp.write_text(body, encoding="utf-8")
            os.replace(tmp, out_path)
            materialised += 1

        # Source path is wiki-root-relative so it slots into the existing
        # batch-mode "source is relative to the wiki root" rule.
        rel_source = f"raw/{raw_subdir_name}/{filename}"

        entries.append({
            "source": rel_source,
            "title": _truncate_title(sq["query"]),
            "type": "concept",
            "tags": ["research", project_slug],
        })

    stats = {
        "project": str(project),
        "project_slug": project_slug,
        "sub_questions": len(sub_questions),
        "contexts": total_contexts,
        "sources": len(sources_by_id),
        "verified_claims": len(verified_claims),
        "materialised": materialised,
    }
    return entries, stats


def render_title(template: str, path_obj: Path) -> str:
    parts = path_obj.parts
    fmt_vars = {
        "stem": path_obj.stem,
        "parent": path_obj.parent.name if len(parts) >= 2 else "",
        "parent2": path_obj.parent.parent.name if len(parts) >= 3 else "",
        "parent3": path_obj.parent.parent.parent.name if len(parts) >= 4 else "",
        "parts": list(parts),
    }
    try:
        return template.format(**fmt_vars)
    except (KeyError, IndexError) as e:
        fail(f"--title-template placeholder error for {path_obj}: {e}")
        return ""  # unreachable, fail() exits


def build_entries_from_paths(
    paths: list,
    default_type: str | None,
    default_tags: list | None,
    title_template: str | None,
    wiki_root: Path,
) -> list:
    entries = []
    for p in paths:
        # Emit paths relative to the wiki root when the file lives under it,
        # otherwise leave absolute — batch-mode.md §"Input schema" treats
        # `source` as a path relative to the wiki root or a URL, and relative
        # paths walking outside the wiki root (e.g., ../cogni-*/skills/...) are
        # explicitly the monorepo discovery case we want to support.
        path_obj = Path(p)
        try:
            rel = path_obj.resolve().relative_to(wiki_root.resolve())
            source = str(rel)
        except ValueError:
            # Outside the wiki root — emit as a relative path from wiki_root
            # so batch-mode's "relative to wiki root" rule still applies.
            try:
                rel = os.path.relpath(path_obj.resolve(), wiki_root.resolve())
                source = rel
            except ValueError:
                source = str(path_obj)
        entry: dict = {"source": source}
        if title_template:
            entry["title"] = render_title(title_template, path_obj)
        if default_type:
            entry["type"] = default_type
        if default_tags:
            entry["tags"] = list(default_tags)
        entries.append(entry)
    return entries


def build_entries_from_stubs(
    stubs: list,
    default_type: str | None,
    default_tags: list | None,
    wiki_root: Path,
) -> list:
    entries = []
    for stub in stubs:
        source = stub["source"]
        # Stub sources: if the frontmatter pointed at "../raw/foo.pdf" we keep
        # it as-is (that is already a wiki-root-relative path). If we fell
        # back to the page path itself, normalise the same way as above.
        if not (source.startswith("http://") or source.startswith("https://") or source.startswith("../") or source.startswith("./")):
            # Looks like an absolute path — make it wiki-root-relative.
            try:
                rel = os.path.relpath(Path(source).resolve(), wiki_root.resolve())
                source = rel
            except ValueError:
                pass
        entry: dict = {"source": source, "title": stub["slug"].replace("-", " ").title()}
        if default_type:
            entry["type"] = default_type
        if default_tags:
            entry["tags"] = list(default_tags)
        entries.append(entry)
    return entries


def apply_exclude_ingested(entries: list, wiki_root: Path) -> tuple:
    slugs = existing_slugs(wiki_root)
    kept = []
    skipped = 0
    for entry in entries:
        slug = derive_slug(entry.get("title") or entry["source"])
        if slug in slugs:
            skipped += 1
            continue
        kept.append(entry)
    return kept, skipped


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Enumerate wiki-ingest batch candidates and emit the sources[] payload on stdout.",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--glob", help="Filesystem glob pattern (resolved against --root).")
    mode.add_argument("--orphans", action="store_true", help="Files in raw/ not yet in any page's sources: frontmatter.")
    mode.add_argument("--stubs", action="store_true", help="Pages with status: draft.")
    mode.add_argument("--research", help="cogni-research project SLUG (auto-located at <workspace>/cogni-research-<SLUG>) or path. Emits one entry per sub-question and materialises per-sq raw files.")

    parser.add_argument("--research-root", dest="research_root", help="Override auto-located cogni-research project root (used with --research).")
    parser.add_argument("--no-materialize", dest="no_materialize", action="store_true", help="With --research: enumerate only, skip raw file writes. Use during dry-run.")
    parser.add_argument("--root", help="Walk base for --glob (default: wiki root).")
    parser.add_argument("--wiki-root", help="Override auto-detected wiki root.")
    parser.add_argument("--older-than-days", type=int, default=None, help="For --stubs: filter to drafts older than N days.")
    parser.add_argument("--exclude-ingested", action="store_true", help="Drop sources whose derived slug already has a page.")
    parser.add_argument("--type", dest="default_type", choices=sorted(VALID_TYPES), help="Default per-entry type.")
    parser.add_argument("--tags", help="Default per-entry tags (comma-separated).")
    parser.add_argument("--title-template", dest="title_template", help="Python format-string for per-entry titles. Placeholders: {stem}, {parent}, {parent2}, {parent3}, {parts[-N]}.")
    parser.add_argument("--limit", type=int, default=None, help="Cap sources[] at N entries after filtering.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.wiki_root:
        wiki_root = Path(args.wiki_root).resolve()
        if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
            fail(f"not a cogni-wiki: {wiki_root}/.cogni-wiki/config.json not found")
    else:
        wiki_root = find_wiki_root(Path.cwd())
    fail_if_pre_migration(wiki_root)

    default_tags = None
    if args.tags:
        default_tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    if args.glob:
        root = Path(args.root).resolve() if args.root else wiki_root
        if not root.is_dir():
            fail(f"--root is not a directory: {root}")
        paths = discover_glob(args.glob, root)
        entries = build_entries_from_paths(paths, args.default_type, default_tags, args.title_template, wiki_root)
        mode_name = "glob"
    elif args.orphans:
        if args.older_than_days is not None:
            fail("--older-than-days applies only to --stubs")
        paths = discover_orphans(wiki_root)
        entries = build_entries_from_paths(paths, args.default_type, default_tags, args.title_template, wiki_root)
        mode_name = "orphans"
    elif args.stubs:
        stubs = discover_stubs(wiki_root, args.older_than_days)
        entries = build_entries_from_stubs(stubs, args.default_type, default_tags, wiki_root)
        mode_name = "stubs"
    elif args.research:
        if args.older_than_days is not None:
            fail("--older-than-days applies only to --stubs")
        if args.title_template:
            fail("--title-template does not apply to --research (titles come from sub-question text)")
        entries, research_stats = discover_research(
            args.research,
            wiki_root,
            args.research_root,
            materialize=not args.no_materialize,
        )
        # Allow --type / --tags to override the per-entry defaults.
        for e in entries:
            if args.default_type:
                e["type"] = args.default_type
            if default_tags is not None:
                e["tags"] = list(default_tags)
        mode_name = "research"
    else:  # argparse enforces required mutex group, but keep the guard explicit
        fail("no discovery mode selected")
        return

    skipped_existing = 0
    if args.exclude_ingested:
        entries, skipped_existing = apply_exclude_ingested(entries, wiki_root)

    if args.limit is not None and args.limit >= 0:
        entries = entries[: args.limit]

    payload = {
        "mode": mode_name,
        "count": len(entries),
        "skipped_existing": skipped_existing,
        "sources": entries,
    }
    if args.research:
        payload["research"] = research_stats
    ok(payload)


if __name__ == "__main__":
    main()
