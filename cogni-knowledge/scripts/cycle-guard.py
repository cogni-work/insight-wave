#!/usr/bin/env python3
"""
cycle-guard.py — refuse a wiki-mode re-deposit that would form a self-citing
loop in the candidate cogni-research project's evidence chain.

A self-cycle exists when the candidate's source entities
(`02-sources/data/src-*.md`) cite wiki pages (`url: wiki://...`) whose own
`derived_from_research:` lineage stamps eventually point back to the candidate
slug. A **direct** cycle closes in one hop (the cited page is stamped
`derived_from_research: <candidate-slug>` itself). A **transitive** cycle
closes through one or more intermediate projects recorded in
`binding.research_projects[]` — the citation chain hops candidate → P → … →
candidate.

The walk is bounded:
- `visited` set keyed by project slug short-circuits revisits.
- `--max-depth` caps recursion (default 5; depth 0 is the candidate's own
  citation walk).
- First transitive hit short-circuits the search.

Each recursion derives the intermediate project's directory from its binding
entry's `report_path` (the file lives at `<project>/output/report.md`, so the
project root is `Path(report_path).parent.parent`). The binding schema does
not carry an explicit `project_path` field today.

Input:
  --knowledge-root         absolute path containing .cogni-knowledge/binding.json
  --research-slug          candidate research project slug
  --research-project-path  absolute path to cogni-research-<slug>/
  --report-source          optional override; defaults to reading
                           <project>/.metadata/project-config.json
  --max-depth              optional; default 5
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
DEFAULT_MAX_DEPTH = 5
# Slug character class matches the canonical contract enforced by cogni-wiki's
# `WIKILINK_RE` in skills/wiki-ingest/scripts/_wikilib.py (kebab-case: lowercase
# alphanumeric + hyphens) and the slug generator `SLUG_CLEAN_RE` in
# scripts/batch_builder.py. Verified equivalent at time of writing. If either
# upstream regex widens (e.g. uppercase, underscore, dot), widen this too —
# under-matching here returns "clear" when it shouldn't, which is a silent
# correctness bug.
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


def _build_slug_index(wiki_path: Path) -> dict[str, tuple[Path, list[str]]]:
    """One-time walk of `<wiki_path>/wiki/**/*.md` producing
    `{slug: (path, [collision_paths])}`. Slugs are globally unique by the
    cogni-wiki contract (cogni-wiki/CLAUDE.md §Bidirectional links); a
    collision list with entries is a wiki-health bug that the caller should
    surface, not silently drop.

    Replaces a per-citation `glob('**/<page-id>.md')` call. With transitive
    recursion the old shape became O(citations × pages × hops); this is O(pages)
    once + O(1) per lookup. Index lookups use the file stem (the wiki contract
    is that `<page-id>.md` filename matches the page's frontmatter `id:` slug,
    so stem-based indexing avoids parsing every page's frontmatter just to
    build the map).
    """
    index: dict[str, tuple[Path, list[str]]] = {}
    wiki_dir = wiki_path / "wiki"
    if not wiki_dir.is_dir():
        return index
    for path in sorted(wiki_dir.glob("**/*.md")):
        slug = path.stem
        rel = str(path.relative_to(wiki_path).as_posix())
        if slug in index:
            existing_path, collisions = index[slug]
            index[slug] = (existing_path, collisions + [rel])
        else:
            index[slug] = (path, [])
    return index


def _resolve_wiki_page(
    slug_index: dict[str, tuple[Path, list[str]]],
    page_id: str,
) -> tuple[Path | None, list[str]]:
    """O(1) lookup against the slug index. Same return shape as the previous
    glob-based implementation: `(path, collisions)` where collisions is
    non-empty only when slug uniqueness is violated."""
    if page_id not in slug_index:
        return None, []
    return slug_index[page_id]


def _walk_project_citations(
    project_path: Path,
    wiki_slug: str,
) -> list[str]:
    """Walk a project's `02-sources/data/src-*.md` entities and return the
    deduplicated list of `wiki://<wiki_slug>/<page-id>` page ids cited.
    Citations pointing at a different wiki are filtered out — they cannot
    participate in a self-cycle within this binding."""
    sources_dir = project_path / "02-sources" / "data"
    if not sources_dir.is_dir():
        return []
    cited: list[str] = []
    seen: set[str] = set()
    for src in sorted(sources_dir.glob("src-*.md")):
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
            continue
        if page_id in seen:
            continue
        seen.add(page_id)
        cited.append(page_id)
    return cited


def _walk_lineage(
    candidate_slug: str,
    candidate_project_path: Path,
    binding: dict,
    wiki_path: Path,
    wiki_slug: str,
    slug_index: dict[str, tuple[Path, list[str]]],
    max_depth: int,
) -> dict:
    """Bounded DFS over the candidate's wiki citations. Returns a dict with:
        cited_page_ids        list of page ids the candidate cites
        missing_pages         list of cited ids not present in the wiki
        collisions            list of {slug, additional_paths} entries
        direct_self_cycles    list of {page, derived_from_research}
        transitive_self_cycles list of {page, derived_from_research, via_chain}
        cross_lineage_overlap list of {page, derived_from_research}
        cycle_path            list[str] — first cycle chain found, [] if none

    The walk starts from the candidate (depth 0). For each cited page whose
    `derived_from_research` points at another deposited project P, recurse
    into P at depth+1, bounded by `visited` (keyed by project slug, seeded
    with candidate_slug) and `max_depth`. The first chain that closes back to
    candidate_slug populates `cycle_path` and short-circuits the search.
    """
    out: dict = {
        "cited_page_ids": [],
        "missing_pages": [],
        "collisions": [],
        "direct_self_cycles": [],
        "transitive_self_cycles": [],
        "cross_lineage_overlap": [],
        "cycle_path": [],
    }

    visited: set[str] = {candidate_slug}

    # Map slug → project_path for fast recursion lookups. Derive each path
    # directly from the binding entry's `report_path` (the binding has no
    # explicit project_path field — see knowledge-binding.py::cmd_append_project,
    # report_path = .../cogni-research-<slug>/output/report.md).
    project_paths: dict[str, Path] = {candidate_slug: candidate_project_path}
    for entry in binding.get("research_projects", []):
        slug = entry.get("slug")
        if not slug or slug in project_paths:
            continue
        rp = entry.get("report_path", "")
        if not rp:
            continue
        try:
            project_paths[slug] = Path(rp).resolve().parent.parent
        except (OSError, ValueError):
            continue

    def dfs(project_slug: str, project_path: Path, chain: list[str], depth: int) -> bool:
        """Walk `project_path`'s citations. Returns True if the candidate
        cycle has been closed (in which case `out["cycle_path"]` is set and
        the caller should stop). Recursion is depth-bounded; revisits short-
        circuit via the shared `visited` set."""
        cited = _walk_project_citations(project_path, wiki_slug)
        if depth == 0:
            out["cited_page_ids"] = cited

        for page_id in cited:
            page_file, collisions = _resolve_wiki_page(slug_index, page_id)
            if depth == 0 and collisions:
                out["collisions"].append(
                    {"slug": page_id, "additional_paths": collisions}
                )
            if page_file is None:
                if depth == 0:
                    out["missing_pages"].append(page_id)
                continue
            try:
                page_fm = _parse_frontmatter(page_file.read_text(encoding="utf-8"))
            except OSError:
                if depth == 0:
                    out["missing_pages"].append(page_id)
                continue
            derived = _strip_quotes(str(page_fm.get("derived_from_research", "")))
            if not derived:
                continue

            rel_path = page_file.relative_to(wiki_path).as_posix()

            if derived == candidate_slug:
                if depth == 0:
                    # Direct cycle — candidate cites its own past deposit.
                    out["direct_self_cycles"].append(
                        {"page": rel_path, "derived_from_research": derived}
                    )
                    if not out["cycle_path"]:
                        out["cycle_path"] = [candidate_slug, candidate_slug]
                else:
                    # Transitive cycle — the chain closes back to candidate.
                    via_chain = chain + [derived]
                    out["transitive_self_cycles"].append(
                        {
                            "page": rel_path,
                            "derived_from_research": derived,
                            "via_chain": via_chain,
                        }
                    )
                    if not out["cycle_path"]:
                        out["cycle_path"] = via_chain
                    return True  # short-circuit
                continue

            # Not a cycle into candidate; record at depth 0 and consider recursion.
            if depth == 0:
                out["cross_lineage_overlap"].append(
                    {"page": rel_path, "derived_from_research": derived}
                )

            if depth >= max_depth:
                continue
            if derived in visited:
                continue
            if derived not in project_paths:
                # Not a deposited project we can walk into; informational only.
                continue
            visited.add(derived)
            if dfs(derived, project_paths[derived], chain + [derived], depth + 1):
                return True
        return False

    dfs(candidate_slug, candidate_project_path, [candidate_slug], 0)
    return out


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Refuse a wiki-mode re-deposit that would form a self-citing loop, "
            "either directly (candidate cites a page derived from itself) or "
            "transitively (candidate → P → … → candidate) up to --max-depth."
        ),
        allow_abbrev=False,
    )
    parser.add_argument("--knowledge-root", required=True)
    parser.add_argument("--research-slug", required=True)
    parser.add_argument("--research-project-path", required=True)
    parser.add_argument("--report-source", required=False, default="")
    parser.add_argument(
        "--max-depth",
        type=int,
        default=DEFAULT_MAX_DEPTH,
        help=(
            f"Max recursion depth for transitive cycle detection "
            f"(default {DEFAULT_MAX_DEPTH}; 0 disables transitive recursion, "
            "matching the v0.0.6 behaviour)."
        ),
    )
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
    if args.max_depth < 0:
        _emit(False, error=f"--max-depth must be ≥ 0 (got {args.max_depth})")
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
        "max_depth": args.max_depth,
        "wiki_pages_cited": [],
        "wiki_pages_cited_missing": [],
        "wiki_slug_collisions": [],
        "direct_self_cycles": [],
        "transitive_self_cycles": [],
        "cross_lineage_overlap": [],
        "cycle_path": [],
    }

    if report_source in REPORT_SOURCES_TRIVIAL or report_source not in REPORT_SOURCES_NEEDS_GUARD:
        # web / local — no wiki evidence to walk
        base_data["status"] = "not_applicable"
        _emit(True, data=base_data)
        return 0

    slug_index = _build_slug_index(wiki_path)
    walk = _walk_lineage(
        candidate_slug=candidate_slug,
        candidate_project_path=project_path,
        binding=binding,
        wiki_path=wiki_path,
        wiki_slug=wiki_slug,
        slug_index=slug_index,
        max_depth=args.max_depth,
    )

    base_data["wiki_pages_cited"] = walk["cited_page_ids"]
    base_data["wiki_pages_cited_missing"] = walk["missing_pages"]
    base_data["wiki_slug_collisions"] = walk["collisions"]
    base_data["direct_self_cycles"] = walk["direct_self_cycles"]
    base_data["transitive_self_cycles"] = walk["transitive_self_cycles"]
    base_data["cross_lineage_overlap"] = walk["cross_lineage_overlap"]
    base_data["cycle_path"] = walk["cycle_path"]

    if base_data["direct_self_cycles"] or base_data["transitive_self_cycles"]:
        base_data["status"] = "cycle_detected"
        if args.dry_run:
            # Dry-run is report-don't-gate: success=true, exit 0, even on a
            # detected cycle. Wet runs gate via success=false + exit 1.
            _emit(True, data=base_data)
            return 0
        kind = "direct" if base_data["direct_self_cycles"] else "transitive"
        chain_str = " → ".join(base_data["cycle_path"]) if base_data["cycle_path"] else "(unknown)"
        _emit(
            False,
            data=base_data,
            error=(
                f"{kind} self-cycle ({chain_str}): the candidate would read its own past deposit "
                "as new evidence. Refusing to deposit. Rename the project, scope the topic "
                "narrower, or lower --max-depth (set 0 to disable transitive recursion entirely) "
                "only if you have separately confirmed the chain is safe."
            ),
        )
        return 1

    base_data["status"] = "clear"
    _emit(True, data=base_data)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
