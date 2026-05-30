#!/usr/bin/env python3
"""
cycle-guard.py — refuse a wiki-mode re-deposit that would form a self-citing
loop in the candidate cogni-research project's evidence chain.

A self-cycle exists when the candidate's citations resolve to wiki pages whose
own `derived_from_research:` lineage stamps eventually point back to the
candidate slug. A **direct** cycle closes in one hop (the cited page is stamped
`derived_from_research: <candidate-slug>` itself). A **transitive** cycle
closes through one or more intermediate projects recorded in
`binding.research_projects[]` — the citation chain hops candidate → P → … →
candidate.

Distilled pages (concept/entity/summary/learning) are citable since #344 but
carry no `derived_from_research` stamp of their own. When a citation resolves to
one, the walk "sees through" it to the SOURCE pages its `distilled_claims:` were
distilled from (page-level `sources:`) and runs the lineage check on each. Cited
distilled pages are surfaced in `data.cited_distilled_pages[]`.

Two citation input shapes are supported:

  legacy-source-entities  — the cogni-research v0.0.x layout. Walks
                            `<project>/02-sources/data/src-*.md` for
                            `url: wiki://<wiki_slug>/<page-id>` lines.
  citation-manifest        — the v0.1.0 inverted-pipeline layout. Reads
                            `<project>/.metadata/citation-manifest.json` and
                            treats each `citations[].wiki_slug` as a cited
                            page id.

The fallback is additive: the legacy glob wins when it returns ≥ 1 source
entity (preserves existing semantics on mixed-shape projects); otherwise the
manifest fallback fires. The resulting `input_shape` is surfaced in the
JSON envelope's `data.input_shape` field so observers can tell which path
ran. Direct-cycle detection works identically for both shapes (page resolution
+ frontmatter `derived_from_research` lookup is shape-agnostic). Transitive
recursion walks each hop's local shape independently, so mixed-shape bindings
(some v0.0.x projects, some v0.1.0 projects) coexist cleanly.

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
CITATION_MANIFEST_RELPATH = ".metadata/citation-manifest.json"
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
# The four distilled page kinds (Phase 4.5, #336/#342). Citable since #344, so
# cycle-guard must "see through" a cited distilled page to the SOURCE pages its
# `distilled_claims:` were distilled from and run the lineage check on those.
_DISTILLED_PAGE_TYPES = {"concept", "entity", "summary", "learning"}


def _emit(success: bool, data: dict | None = None, error: str = "") -> dict:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return payload


# Inlined (not imported from cogni-wiki) to keep cogni-knowledge decoupled.
# Mirrors `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py::parse_frontmatter`
# — if that upstream parser grows new edge cases (multi-line scalars, quoted
# values, nested block lists), this copy must be updated in lock-step or the
# cycle-guard silently under-detects.
_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.DOTALL)


class ManifestUnreadableError(Exception):
    """Raised when `<project>/.metadata/citation-manifest.json` exists but
    cannot be read or parsed. Surfaced loudly by main() rather than swallowed
    — the manifest is the only evidence input for v0.1.0 projects, so a
    silent "no citations → status=clear" path would defeat the guard."""


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


def _distilled_backing_slugs(page_fm: dict) -> list[str]:
    """Backing SOURCE slugs of a distilled (concept/entity/summary/learning)
    page, read from its page-level `sources:` block. concept-store.py's
    `_render_page` writes that block as `  - wiki://<source-slug>` lines (the
    union of every distilled claim's backlinks), which `_parse_frontmatter`
    already captures as a list. These are the source pages the distilled claims
    were distilled from; cycle-guard traces through them so a synthesis citing a
    distilled page is checked against the lineage of that page's underlying
    sources (#344). Deduplicated, order-preserving."""
    out: list[str] = []
    seen: set[str] = set()
    for raw in page_fm.get("sources", []) or []:
        s = _strip_quotes(str(raw)).strip()
        if s.startswith("wiki://"):
            s = s[len("wiki://"):]
        # A bare `wiki://<slug>` has no slash; a `wiki://<wiki>/<page>` composite
        # collapses to its trailing page slug. Either way take the last segment.
        s = s.split("/")[-1].strip()
        if s and s not in seen:
            seen.add(s)
            out.append(s)
    return out


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
) -> tuple[list[str], str]:
    """Walk a project's citation set and return the deduplicated list of page
    ids cited, plus an `input_shape` label identifying which layout produced
    the list:

      "legacy-source-entities"  — at least one `02-sources/data/src-*.md`
                                  found; manifest fallback was NOT consulted.
      "citation-manifest"        — legacy dir absent or empty; fell back to
                                  `.metadata/citation-manifest.json`.
      "none"                     — neither input present (project has no
                                  citations to walk).

    Legacy-shape filtering: citations pointing at a different wiki are dropped
    (they cannot participate in a self-cycle within this binding). The
    manifest shape carries bare page slugs, not `wiki://<wiki>/<page>` URLs,
    so unknown-slug filtering happens downstream in `_resolve_wiki_page`.
    """
    sources_dir = project_path / "02-sources" / "data"
    legacy_files = (
        sorted(sources_dir.glob("src-*.md")) if sources_dir.is_dir() else []
    )

    if legacy_files:
        cited: list[str] = []
        seen: set[str] = set()
        for src in legacy_files:
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
        return cited, "legacy-source-entities"

    manifest_path = project_path / CITATION_MANIFEST_RELPATH
    if manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ManifestUnreadableError(
                f"citation-manifest at {manifest_path} is unreadable: {exc}"
            ) from exc
        cited_m: list[str] = []
        seen_m: set[str] = set()
        for entry in manifest.get("citations", []) or []:
            slug = (entry or {}).get("wiki_slug")
            if not isinstance(slug, str) or not slug or slug in seen_m:
                continue
            seen_m.add(slug)
            cited_m.append(slug)
        return cited_m, "citation-manifest"

    return [], "none"


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
        cited_distilled_pages list of {page, type} — citable concept/entity/
                              summary/learning pages the candidate cites (#344)
        direct_self_cycles    list of {page, derived_from_research}
        transitive_self_cycles list of {page, derived_from_research, via_chain}
        cross_lineage_overlap list of {page, derived_from_research}
        cycle_path            list[str] — first cycle chain found, [] if none

    The walk starts from the candidate (depth 0). For each cited page whose
    `derived_from_research` points at another deposited project P, recurse
    into P at depth+1, bounded by `visited` (keyed by project slug, seeded
    with candidate_slug) and `max_depth`. The first chain that closes back to
    candidate_slug populates `cycle_path` and short-circuits the search.

    A cited **distilled** page (concept/entity/summary/learning, citable since
    #344) carries no `derived_from_research` of its own — it stamps
    `distilled_from_research:` instead. The walk "sees through" it to the SOURCE
    pages its `distilled_claims:` were distilled from (page-level `sources:`,
    via `_distilled_backing_slugs`) and runs the same lineage check on each. In
    today's data those sources carry no lineage stamp, so a distilled citation
    bottoms out `clear`; the explicit trace is forward-defensive (a future
    lineage-bearing backing page would be caught, not silently skipped).
    """
    out: dict = {
        "cited_page_ids": [],
        "missing_pages": [],
        "collisions": [],
        "cited_distilled_pages": [],
        "direct_self_cycles": [],
        "transitive_self_cycles": [],
        "cross_lineage_overlap": [],
        "cycle_path": [],
        # `input_shape` is the depth-0 (candidate project's own) shape; kept
        # for back-compat. `input_shapes` is the ordered per-hop list, so
        # mixed-shape transitive walks are observable. Both are populated by
        # the inner `dfs()`.
        "input_shape": "none",
        "input_shapes": [],
    }

    visited: set[str] = {candidate_slug}

    # Prefer entry["project_path"]; fall back to report_path.parent.parent for
    # legacy bindings (schema 0.0.1 or entries written without --project-path).
    project_paths: dict[str, Path] = {candidate_slug: candidate_project_path}
    for entry in binding.get("research_projects", []):
        slug = entry.get("slug")
        if not slug or slug in project_paths:
            continue
        explicit = entry.get("project_path", "") or ""
        if explicit:
            try:
                project_paths[slug] = Path(explicit).resolve()
                continue
            except (OSError, ValueError):
                pass  # fall through to legacy derivation
        rp = entry.get("report_path", "")
        if not rp:
            continue
        try:
            project_paths[slug] = Path(rp).resolve().parent.parent
        except (OSError, ValueError):
            continue

    def check_hop(
        page_file: Path, page_fm: dict, chain: list[str], depth: int
    ) -> bool:
        """Run the `derived_from_research` lineage check on one resolved page
        (a directly-cited page, or a distilled page's backing source). Records
        direct / transitive cycles and cross-lineage overlap, and recurses into
        the deriving project when applicable. Returns True iff the candidate
        cycle has closed (caller short-circuits)."""
        derived = _strip_quotes(str(page_fm.get("derived_from_research", "")))
        if not derived:
            return False

        rel_path = page_file.relative_to(wiki_path).as_posix()

        if derived == candidate_slug:
            if depth == 0:
                # Direct cycle — candidate cites its own past deposit.
                out["direct_self_cycles"].append(
                    {"page": rel_path, "derived_from_research": derived}
                )
                if not out["cycle_path"]:
                    out["cycle_path"] = [candidate_slug, candidate_slug]
                return False
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

        # Not a cycle into candidate; record at depth 0 and consider recursion.
        if depth == 0:
            out["cross_lineage_overlap"].append(
                {"page": rel_path, "derived_from_research": derived}
            )

        if depth >= max_depth:
            return False
        if derived in visited:
            return False
        if derived not in project_paths:
            # Not a deposited project we can walk into; informational only.
            return False
        visited.add(derived)
        return dfs(derived, project_paths[derived], chain + [derived], depth + 1)

    def dfs(project_slug: str, project_path: Path, chain: list[str], depth: int) -> bool:
        """Walk `project_path`'s citations. Returns True if the candidate
        cycle has been closed (in which case `out["cycle_path"]` is set and
        the caller should stop). Recursion is depth-bounded; revisits short-
        circuit via the shared `visited` set."""
        cited, shape = _walk_project_citations(project_path, wiki_slug)
        out["input_shapes"].append({"slug": project_slug, "shape": shape})
        if depth == 0:
            out["cited_page_ids"] = cited
            out["input_shape"] = shape

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

            # A page carrying its own `derived_from_research` is a deposited
            # synthesis-like page — run the normal lineage check regardless of
            # which directory it lives in (check_hop, below). The distilled
            # see-through applies ONLY to a page with NO `derived_from_research`
            # that is identifiably distilled (real concept/entity/summary/
            # learning pages stamp `distilled_from_research:`, never
            # `derived_from_research:`).
            has_derived = bool(
                _strip_quotes(str(page_fm.get("derived_from_research", "")))
            )
            page_type = _strip_quotes(str(page_fm.get("type", "")))
            is_distilled = (not has_derived) and (
                page_type in _DISTILLED_PAGE_TYPES or "distilled_claims" in page_fm
            )
            if is_distilled:
                # Citable distilled page (#344). See through it to the SOURCE
                # pages its claims were distilled from and run the same lineage
                # check on each.
                if depth == 0:
                    out["cited_distilled_pages"].append(
                        {
                            "page": page_file.relative_to(wiki_path).as_posix(),
                            "type": page_type,
                        }
                    )
                for src_slug in _distilled_backing_slugs(page_fm):
                    src_file, _src_collisions = _resolve_wiki_page(slug_index, src_slug)
                    if src_file is None:
                        continue
                    try:
                        src_fm = _parse_frontmatter(src_file.read_text(encoding="utf-8"))
                    except OSError:
                        continue
                    if check_hop(src_file, src_fm, chain, depth):
                        return True
                continue

            if check_hop(page_file, page_fm, chain, depth):
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
            f"(default {DEFAULT_MAX_DEPTH}; 0 disables transitive recursion)."
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
        "input_shape": "none",
        "input_shapes": [],
        "wiki_pages_cited": [],
        "wiki_pages_cited_missing": [],
        "wiki_slug_collisions": [],
        "cited_distilled_pages": [],
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
    try:
        walk = _walk_lineage(
            candidate_slug=candidate_slug,
            candidate_project_path=project_path,
            binding=binding,
            wiki_path=wiki_path,
            wiki_slug=wiki_slug,
            slug_index=slug_index,
            max_depth=args.max_depth,
        )
    except ManifestUnreadableError as exc:
        base_data["status"] = "manifest_unreadable"
        _emit(False, data=base_data, error=str(exc))
        return 1

    base_data["wiki_pages_cited"] = walk["cited_page_ids"]
    base_data["wiki_pages_cited_missing"] = walk["missing_pages"]
    base_data["wiki_slug_collisions"] = walk["collisions"]
    base_data["cited_distilled_pages"] = walk["cited_distilled_pages"]
    base_data["direct_self_cycles"] = walk["direct_self_cycles"]
    base_data["transitive_self_cycles"] = walk["transitive_self_cycles"]
    base_data["cross_lineage_overlap"] = walk["cross_lineage_overlap"]
    base_data["cycle_path"] = walk["cycle_path"]
    base_data["input_shape"] = walk["input_shape"]
    base_data["input_shapes"] = walk["input_shapes"]

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
