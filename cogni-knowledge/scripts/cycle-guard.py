#!/usr/bin/env python3
"""
cycle-guard.py — refuse a wiki-mode re-deposit that would form a direct
self-citing loop.

A self-cycle exists when the candidate cogni-research project's source
entities (`02-sources/data/src-*.md`) cite wiki pages (`url: wiki://...`)
that are themselves stamped `derived_from_research: <candidate-slug>` —
i.e. the project would be reading its own past deposit as new evidence.

This MVP detects **direct** self-cycles only. Transitive (multi-hop) cycles
are intentionally deferred to a v0.0.7+ patch once alpha runs surface real
shapes.

Input:
  --knowledge-root         absolute path containing .cogni-knowledge/binding.json
  --research-slug          candidate research project slug
  --research-project-path  absolute path to cogni-research-<slug>/
  --report-source          optional override; defaults to reading
                           <project>/.metadata/project-config.json
  --dry-run                report findings; exit 0 regardless

Output (insight-wave envelope):
  {"success": bool, "data": {"status": ..., ...}, "error": "..."}

Exit codes:
  0   status ∈ {clear, not_applicable}, or --dry-run regardless
  1   status == cycle_detected (and not --dry-run)

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

WIKI_DIRNAME = ".cogni-wiki"
WIKI_CONFIG_FILENAME = "config.json"
SOURCES_GLOB = "02-sources/data/src-*.md"
PROJECT_CONFIG_RELPATH = ".metadata/project-config.json"
# Slug character class follows the kebab-case contract in cogni-knowledge/CLAUDE.md
# §Conventions and cogni-wiki's slug convention. Widen if either side ever allows
# uppercase / underscore / dot — under-matching here returns "clear" when it
# shouldn't, so the failure mode is silent.
WIKI_URL_RE = re.compile(r"^wiki://([a-z0-9-]+)/([a-z0-9-]+)$")
REPORT_SOURCES_NEEDS_GUARD = {"wiki", "hybrid"}
REPORT_SOURCES_TRIVIAL = {"web", "local"}


def _emit(success: bool, data: dict | None = None, error: str = "") -> dict:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return payload


# Inlined (not imported from cogni-wiki) to keep cogni-knowledge decoupled.
# Mirrors `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py::parse_frontmatter`
# — if that upstream parser grows new edge cases (multi-line scalars, quoted
# values, nested block lists), this copy must be updated in lock-step or the
# cycle-guard silently under-detects.
_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n", re.DOTALL)


def _parse_frontmatter(text: str) -> dict:
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    current_key: str | None = None
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            out.setdefault(current_key, []).append(line[4:].strip())
            continue
        if ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            current_key = k
            if v.startswith("[") and v.endswith("]"):
                inside = v[1:-1].strip()
                out[k] = [x.strip() for x in inside.split(",") if x.strip()] if inside else []
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def _strip_quotes(v: str) -> str:
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ('"', "'"):
        return v[1:-1]
    return v


def _read_binding(knowledge_root: Path) -> tuple[dict | None, str]:
    """Shell out to knowledge-binding.py read; return (binding, diagnostic).
    `binding` is None on any failure; `diagnostic` is the underlying error
    surface (subprocess stderr, JSON decode error, or upstream envelope's
    error string) so the caller can include it in its own envelope."""
    script = Path(__file__).resolve().parent / "knowledge-binding.py"
    proc = subprocess.run(
        ["python3", str(script), "read", "--knowledge-root", str(knowledge_root)],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return None, (proc.stderr or proc.stdout).strip()
    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        return None, f"binding read returned non-JSON: {exc}"
    if not envelope.get("success"):
        return None, envelope.get("error", "binding read returned success=false")
    return envelope.get("data", {}).get("binding"), ""


def _read_wiki_slug(wiki_path: Path) -> str | None:
    cfg = wiki_path / WIKI_DIRNAME / WIKI_CONFIG_FILENAME
    if not cfg.is_file():
        return None
    try:
        return json.loads(cfg.read_text(encoding="utf-8")).get("slug")
    except json.JSONDecodeError:
        return None


def _read_report_source(project_path: Path) -> str:
    cfg = project_path / PROJECT_CONFIG_RELPATH
    if not cfg.is_file():
        return "web"
    try:
        return json.loads(cfg.read_text(encoding="utf-8")).get("report_source", "web")
    except json.JSONDecodeError:
        return "web"


def _resolve_wiki_page(wiki_path: Path, page_id: str) -> tuple[Path | None, list[str]]:
    """Resolve a wiki:// page-id to its file. Slugs are globally unique
    across per-type subdirectories (cogni-wiki/CLAUDE.md §Bidirectional links),
    so exactly one match is expected. Returns (path, collisions) where
    `collisions` is non-empty only when the slug-uniqueness invariant is
    violated (a wiki-health bug). The caller surfaces the collision list
    in the envelope so the human reviewer can repair the wiki."""
    hits = sorted((wiki_path / "wiki").glob(f"**/{page_id}.md"))
    if not hits:
        return None, []
    collisions = [str(p.relative_to(wiki_path).as_posix()) for p in hits[1:]]
    return hits[0], collisions


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Refuse a wiki-mode re-deposit that would form a direct self-citing loop.",
        allow_abbrev=False,
    )
    parser.add_argument("--knowledge-root", required=True)
    parser.add_argument("--research-slug", required=True)
    parser.add_argument("--research-project-path", required=True)
    parser.add_argument("--report-source", required=False, default="")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    knowledge_root = Path(args.knowledge_root).resolve()
    project_path = Path(args.research_project_path).resolve()
    candidate_slug = args.research_slug.strip()

    if not candidate_slug:
        _emit(False, error="--research-slug must be non-empty")
        return 1
    if not project_path.is_dir():
        _emit(False, error=f"research project path does not exist: {project_path}")
        return 1

    binding, binding_err = _read_binding(knowledge_root)
    if binding is None:
        _emit(
            False,
            error=(
                f"could not read binding at {knowledge_root}/.cogni-knowledge/binding.json"
                + (f": {binding_err}" if binding_err else "")
            ),
        )
        return 1
    wiki_path = Path(binding.get("wiki_path", "")).resolve()
    if not wiki_path.is_dir():
        _emit(False, error=f"binding wiki_path does not exist: {wiki_path}")
        return 1

    wiki_slug = _read_wiki_slug(wiki_path)
    if not wiki_slug:
        _emit(False, error=f"could not resolve wiki slug from {wiki_path}/.cogni-wiki/config.json")
        return 1

    report_source = (args.report_source or _read_report_source(project_path)).strip()

    base_data = {
        "candidate_slug": candidate_slug,
        "report_source": report_source,
        "wiki_slug": wiki_slug,
        "wiki_pages_cited": [],
        "wiki_pages_cited_missing": [],
        "wiki_slug_collisions": [],
        "direct_self_cycles": [],
        "cross_lineage_overlap": [],
    }

    if report_source in REPORT_SOURCES_TRIVIAL or report_source not in REPORT_SOURCES_NEEDS_GUARD:
        # web / local — no wiki evidence to walk
        base_data["status"] = "not_applicable"
        _emit(True, data=base_data)
        return 0

    sources_dir = project_path / "02-sources" / "data"
    src_files = sorted(sources_dir.glob("src-*.md")) if sources_dir.is_dir() else []

    cited_page_ids: list[str] = []
    for src in src_files:
        try:
            fm = _parse_frontmatter(src.read_text(encoding="utf-8"))
        except OSError:
            continue
        url = _strip_quotes(str(fm.get("url", "")))
        m = WIKI_URL_RE.match(url)
        if not m:
            continue
        cited_wiki_slug, page_id = m.group(1), m.group(2)
        if cited_wiki_slug != wiki_slug:
            # Citation points at a different wiki — not a self-cycle for this binding.
            continue
        cited_page_ids.append(page_id)

    # Deduplicate while preserving order
    seen: set[str] = set()
    cited_page_ids = [p for p in cited_page_ids if not (p in seen or seen.add(p))]
    base_data["wiki_pages_cited"] = cited_page_ids

    for page_id in cited_page_ids:
        page_file, collisions = _resolve_wiki_page(wiki_path, page_id)
        if collisions:
            base_data["wiki_slug_collisions"].append(
                {"slug": page_id, "additional_paths": collisions}
            )
        if page_file is None:
            base_data["wiki_pages_cited_missing"].append(page_id)
            continue
        try:
            page_fm = _parse_frontmatter(page_file.read_text(encoding="utf-8"))
        except OSError:
            base_data["wiki_pages_cited_missing"].append(page_id)
            continue
        derived = _strip_quotes(str(page_fm.get("derived_from_research", "")))
        if not derived:
            continue
        rel_path = page_file.relative_to(wiki_path).as_posix()
        if derived == candidate_slug:
            base_data["direct_self_cycles"].append(
                {"page": rel_path, "derived_from_research": derived}
            )
        else:
            base_data["cross_lineage_overlap"].append(
                {"page": rel_path, "derived_from_research": derived}
            )

    if base_data["direct_self_cycles"]:
        base_data["status"] = "cycle_detected"
        if args.dry_run:
            _emit(True, data=base_data)
            return 0
        _emit(
            False,
            data=base_data,
            error=(
                f"direct self-cycle: {len(base_data['direct_self_cycles'])} wiki page(s) "
                f"are stamped derived_from_research={candidate_slug} and would be cited by "
                "this same project. Refusing to deposit. Rename the project, scope the topic "
                "narrower, or wait for transitive cycle handling (v0.0.7+)."
            ),
        )
        return 1

    base_data["status"] = "clear"
    _emit(True, data=base_data)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
