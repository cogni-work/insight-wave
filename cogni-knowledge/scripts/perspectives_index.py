#!/usr/bin/env python3
"""perspectives_index.py — deterministic 5W1H overlay renderer for wiki/perspectives.md.

A derived OVERLAY sibling of `root_index.py`. Where `root_index.py` renders the
curated root MAP grouped by THEME, this renders a single `wiki/perspectives.md`
that re-projects the canonical type-first layout into 5W1H **perspectives**
(Who / What / When / Where / Why) WITHOUT changing the canonical layout.
Every page keeps its real home in its type directory; this page is a second,
derived way in:

  # Perspectives

  <!-- MACHINE-OWNED:PERSPECTIVES-INDEX -->

  _<intro>_

  ## Who
  <!-- MACHINE-OWNED:PERSPECTIVES-FACET:who:START --> … <!-- …:END -->
  **Explore:** [People (n)](people/index.md) · [Entities (m)](entities/index.md)

  ## What … ## Why … ## When … ## Where

**Tier 1 — the facets that re-project surviving types deterministically.** Each
facet maps to zero or more of the surviving page types and shows a single
count-link line per backing type (the cross-base TOTAL count from
`sub_index.theme_counts`, summed across themes), linking that type's sub-index.
The mapping:

  Who   → people + entities      (named subjects)
  What  → concepts + sources     (definitions + primary evidence)
  Why   → questions + syntheses  (inquiry drivers + conclusions)
  When  → wiki/log.md             log-derived timeline (v1; months link to the log)
  Where → source `market:` FM      sources grouped by market (v1; link to sources/)

The former `How` facet was dropped: its backing types (the cross-source
`summary` + run-level `learning`) were retired as dead vocabulary, leaving it
permanently empty — a dead facet rather than an honestly-forthcoming one.

`When`/`Where` are thin v1 facets (log-derived timeline / market grouping); when
a base has no activity log or no market-tagged sources they render an explicit
honest signpost about that forthcoming state rather than a bare empty line. A
type-backed facet whose types are all zero-count still renders its heading +
engine-owned lead-in + an honest `_(no pages in this facet yet)_` line, so the
overlay is complete.

**Ownership + idempotence (the same contract every renderer holds).** The page
carries a `MACHINE-OWNED:PERSPECTIVES-INDEX` marker; each facet's lead-in lives
in its own `MACHINE-OWNED:PERSPECTIVES-FACET:<slug>` span, carried forward
verbatim if a narrator has authored one (never regenerated), else seeded with a
deterministic default. Re-rendering an unchanged wiki is a byte-identical no-op
(counts are deterministic from disk; carried spans are preserved). A non-empty
`wiki/perspectives.md` that lacks the PERSPECTIVES-INDEX marker is a
hand-authored page and is skipped (`skipped_human_page`), never clobbered.

Subcommands:

  - `render` — write `wiki/perspectives.md` live, under `_wiki_lock` +
               `atomic_write_text`, only when the proposed text differs.
  - `stage`  — write the proposed page to
               `<wiki-root>/.cogni-wiki/perspectives-proposed.md` WITHOUT the
               lock and WITHOUT touching the live file.

`_emit` / `_import_wiki_lock` / `theme_counts` / `REGISTRY` are reused from
`sub_index.py`; `atomic_write_text` / `extract_machine_block` from
`_knowledge_lib`. Stdlib only, POSIX `render` (`_wiki_lock` uses `fcntl.flock`);
`stage` is lock-free. Python 3.9 floor.

Output is a `{"success": bool, "data": {...}, "error": "..."}` JSON envelope
(pretty-printed with `indent=2`), per the cross-plugin script convention.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    extract_machine_block,
    frontmatter_scalar,
    log_path,
)
from sub_index import (  # noqa: E402
    REGISTRY,
    _emit,
    _import_wiki_lock,
    theme_counts,
)

PERSPECTIVES_INDEX_MARKER = "<!-- MACHINE-OWNED:PERSPECTIVES-INDEX -->"
PERSPECTIVES_REL = ("wiki", "perspectives.md")
PAGE_H1 = "# Perspectives"
INTRO_LINE = (
    "_A 5W1H overlay: the same pages, re-projected by perspective. This view is "
    "derived — the canonical home of every page stays its type directory._"
)

# Secondary-view labels (R10/R11): the alternative projections of the same pages
# this overlay complements, so the reader knows the views available beyond the
# 5W1H spine — the curated map (by theme), the per-type sub-indexes, and a
# signpost to the Recent-syntheses overview stub so it is reachable from the
# spine rather than orphaned. A constant preamble line — deterministic and
# idempotent, like every other line the renderer assembles from constants.
SECONDARY_VIEWS_LINE = (
    "_Other views: the [curated map](index.md) (by theme) · the per-type "
    "sub-indexes (Concepts · Sources · Questions · Entities · People · "
    "Syntheses) · [Recent syntheses](overview.md)._"
)

# One entry per facet: (slug, heading, [backing type names], default lead-in).
# The backing type names index sub_index.REGISTRY. who/what/why are type-backed;
# when/where carry an empty list but render a custom builder body (timeline /
# market grouping), NOT the honest-empty count-link path. The default lead-in is
# what the engine seeds before a narrator authors the facet's PERSPECTIVES-FACET
# span. (The former `how` facet was removed — permanently dead, no backing type.)
FACET_DISPLAY = (
    ("who", "Who", ["people", "entities"],
     "_The named subjects this base tracks — the people and organizations behind "
     "the evidence._"),
    ("what", "What", ["concepts", "sources"],
     "_The substance — the concepts the base defines and the primary sources they "
     "rest on._"),
    ("why", "Why", ["questions", "syntheses"],
     "_The inquiry — the research questions driving the base and the syntheses that "
     "answer them._"),
    ("when", "When", [],
     "_The timeline — how this base grew, derived from its append-only activity "
     "log. Claim-level event dates are a future (v2) extension._"),
    ("where", "Where", [],
     "_The geography — sources grouped by the market they were researched for. "
     "Finer-grained per-source geography is a future (v2) extension._"),
)

# Per-type display labels for the count-link line (mirrors root_index TYPE_DISPLAY
# labels). Every backing type named in FACET_DISPLAY must appear here.
TYPE_LABELS = {
    "people": "People",
    "entities": "Entities",
    "concepts": "Concepts",
    "sources": "Sources",
    "questions": "Questions",
    "syntheses": "Syntheses",
}

EMPTY_FACET_LINE = "_(no pages in this facet yet)_"


def _facet_span_name(slug: str) -> str:
    return f"PERSPECTIVES-FACET:{slug}"


def _render_span(name: str, inner: str) -> str:
    """A stamp-free `MACHINE-OWNED:<name>` span (idempotent: no date)."""
    return (
        f"<!-- MACHINE-OWNED:{name}:START -->\n"
        f"{inner}\n"
        f"<!-- MACHINE-OWNED:{name}:END -->"
    )


def _type_total(tname: str, wiki_root: Path) -> int:
    """Cross-base TOTAL page count for one type — sum of its per-theme counts,
    the SAME theme assignment the type's sub-index uses, so the overlay can never
    drift from `wiki/<type>/index.md`."""
    return sum(theme_counts(REGISTRY[tname], wiki_root).values())


# A `wiki/log.md` activity heading: `## [YYYY-MM-DD] <op> | <details>`. The op
# token is the first word after the date; details (after `|`) are ignored for the
# v1 timeline. Anchored at line start so prose and the `# Log` H1 never match.
_WHEN_LOG_RE = re.compile(r"^##\s*\[(\d{4})-(\d{2})-\d{2}\]\s+(\S+)")
WHEN_INTRO = "_Activity timeline from the base's append-only log (newest month first)._"
# Honest signpost for the thin When facet (R9): names WHY it is empty and how it
# fills, instead of a bare "no pages" line — When is a forthcoming v1 facet, not
# a dead one.
WHEN_EMPTY_LINE = (
    "_(When: no activity timeline yet — it builds from the base's append-only log "
    "as research cycles run.)_"
)


def _wiki_relative_log(wiki_root: Path) -> str:
    """The activity log's path RELATIVE to the `wiki/` dir, so a link from
    `wiki/perspectives.md` resolves: `meta/log.md` on a meta-canonical base,
    legacy `log.md` on a flat base. A pure function of `_knowledge_lib.log_path`'s
    resolution — the link target never drifts from the timeline's own source."""
    return log_path(wiki_root).relative_to(Path(wiki_root) / "wiki").as_posix()


def _build_when_timeline(wiki_root: Path) -> "list[str]":
    """The When-facet body: a deterministic, byte-stable timeline grouped by
    month (`YYYY-MM`, newest first) from the append-only `wiki/log.md` operation
    headings. Resolves the log via `_knowledge_lib.log_path` (meta-first /
    legacy-flat — never hardcoded). An absent / empty / unreadable log, or a log
    with no dated operation headings, renders the honest no-timeline line — never
    a fabricated timeline.

    v1 derives only from the activity log (the purpose-built, already-existing
    signal); claim-level event-date extraction is the v2 extension."""
    try:
        text = log_path(wiki_root).read_text(encoding="utf-8")
    except OSError:
        return [WHEN_EMPTY_LINE]

    # month "YYYY-MM" -> {"total": int, "ops": set(op)}. A dict preserves nothing
    # order-wise we rely on; we sort the keys at render time for determinism.
    months: "dict[str, dict]" = {}
    for line in text.splitlines():
        m = _WHEN_LOG_RE.match(line)
        if not m:
            continue
        ym = f"{m.group(1)}-{m.group(2)}"
        op = m.group(3)
        bucket = months.setdefault(ym, {"total": 0, "ops": set()})
        bucket["total"] += 1
        bucket["ops"].add(op)

    if not months:
        return [WHEN_EMPTY_LINE]

    # The log was read above, so it exists — link each month to it (months carry
    # no per-month deep anchor in v1; that defers to the claim-level event-date
    # extension). Wiki-relative so the link from wiki/perspectives.md resolves.
    rel_log = _wiki_relative_log(wiki_root)
    out = [WHEN_INTRO, ""]
    for ym in sorted(months, reverse=True):
        bucket = months[ym]
        n = bucket["total"]
        noun = "operation" if n == 1 else "operations"
        ops = " · ".join(sorted(bucket["ops"]))
        out.append(f"- **{ym}** — [{n} {noun}]({rel_log}) ({ops})")
    return out


WHERE_INTRO = "_Sources grouped by the market they were researched for._"
# Honest signpost for the thin Where facet (R9): distinct from the type-backed
# facets' generic EMPTY_FACET_LINE — Where is a forthcoming v1 facet that fills
# once sources carry a `market:`, so it says so rather than reading "no pages".
WHERE_EMPTY_LINE = (
    "_(Where: no market-tagged sources yet — sources gain a market at ingest, and "
    "this view groups them once they do.)_"
)


def _build_where_grouping(wiki_root: Path) -> "list[str]":
    """The Where-facet body: source pages grouped by their `market:` frontmatter
    (the run-level market the curator researched against, persisted at ingest —
    the source side of the same frontmatter-resident-membership pattern
    `theme_label:` uses). Deterministic — markets sorted alphabetically. A base
    whose sources carry no `market:` (legacy / not-yet-tagged) renders the honest
    `WHERE_EMPTY_LINE` signpost (distinct from the type-backed facets' generic
    empty line — Where is a forthcoming v1 facet), never a fabricated grouping.

    v1 groups by the run-level `market:` only; finer-grained per-source `geo:`
    is the v2 extension (no per-source geo signal exists at ingest today)."""
    sources_dir = wiki_root / "wiki" / "sources"
    counts: "dict[str, int]" = {}
    for page in sorted(sources_dir.glob("*.md")):
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        market = frontmatter_scalar(text, "market").strip()
        if market:
            counts[market] = counts.get(market, 0) + 1

    if not counts:
        return [WHERE_EMPTY_LINE]

    out = [WHERE_INTRO, ""]
    for market in sorted(counts):
        n = counts[market]
        noun = "source" if n == 1 else "sources"
        # Link the count to the sources sub-index — the AC-sanctioned fallback
        # target (sources/index.md is theme-grouped, not market-scoped, so no
        # per-market anchor exists today). Relative from wiki/perspectives.md.
        out.append(f"- **{market}** — [{n} {noun}](sources/index.md)")
    return out


def _build_perspectives(wiki_root: Path, existing_text: str) -> str:
    """Assemble the full proposed `wiki/perspectives.md` overlay text."""
    parts: list = [PAGE_H1, ""]
    parts.append(PERSPECTIVES_INDEX_MARKER)
    parts.append("")
    parts.append(INTRO_LINE)
    parts.append("")
    # Secondary-view labels (R10) + the overview-stub signpost (R11). A constant
    # preamble line, so it stays a deterministic, idempotent reflow fixpoint.
    parts.append(SECONDARY_VIEWS_LINE)
    parts.append("")

    for slug, heading, type_names, default_leadin in FACET_DISPLAY:
        parts.append(f"## {heading}")
        parts.append("")
        # Carry a narrator-authored lead-in span forward verbatim; else seed the
        # deterministic default. Either way the span is engine-owned.
        carried = extract_machine_block(existing_text, _facet_span_name(slug))
        inner = carried if carried is not None else default_leadin
        parts.append(_render_span(_facet_span_name(slug), inner))
        parts.append("")

        if slug == "when":
            # The When facet has a custom, log-derived timeline body (v1) instead
            # of the count-link / honest-empty path the type-backed facets use.
            parts.extend(_build_when_timeline(wiki_root))
            parts.append("")
            continue

        if slug == "where":
            # The Where facet groups source pages by their `market:` frontmatter
            # (v1) — a custom body, like When; honest-empty until sources carry it.
            parts.extend(_build_where_grouping(wiki_root))
            parts.append("")
            continue

        links = []
        for tname in type_names:
            n = _type_total(tname, wiki_root)
            if n > 0:
                links.append(f"[{TYPE_LABELS[tname]} ({n})]({tname}/index.md)")
        if links:
            parts.append("**Explore:** " + " · ".join(links))
        else:
            parts.append(EMPTY_FACET_LINE)
        parts.append("")

    return "\n".join(parts).rstrip() + "\n"


def _is_human_page(existing_text: str) -> bool:
    """A non-empty `perspectives.md` lacking the PERSPECTIVES-INDEX marker is a
    hand-authored page the renderer must not touch."""
    if not existing_text.strip():
        return False
    return PERSPECTIVES_INDEX_MARKER not in existing_text


def _prepare(wiki_root_arg: str) -> "tuple[Optional[dict], Optional[str]]":
    wiki_root = Path(wiki_root_arg).resolve()
    if not (wiki_root / "wiki").is_dir():
        return None, f"wiki_root has no wiki/ dir: {wiki_root}"
    page_path = wiki_root.joinpath(*PERSPECTIVES_REL)
    existing = ""
    if page_path.is_file():
        try:
            existing = page_path.read_text(encoding="utf-8")
        except OSError as exc:
            return None, f"perspectives page not readable: {exc}"
    return {
        "wiki_root": wiki_root,
        "page_path": page_path,
        "existing": existing,
        "proposed": _build_perspectives(wiki_root, existing),
    }, None


def cmd_render(args) -> int:
    """`render`: write wiki/perspectives.md live (locked, atomic, idempotent, no-clobber)."""
    _wiki_lock, err = _import_wiki_lock(args.wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    payload, err = _prepare(args.wiki_root)
    if err:
        return _emit(False, error=err)
    page_path = payload["page_path"]
    wiki_root = payload["wiki_root"]

    if _is_human_page(payload["existing"]):
        return _emit(True, data={
            "path": str(page_path),
            "subcommand": "render",
            "changed": False,
            "skipped_human_page": True,
        })

    changed = False
    try:
        with _wiki_lock(wiki_root):
            current = page_path.read_text(encoding="utf-8") if page_path.is_file() else ""
            if _is_human_page(current):
                return _emit(True, data={
                    "path": str(page_path),
                    "subcommand": "render",
                    "changed": False,
                    "skipped_human_page": True,
                })
            # Rebuild against the locked-read text so a facet lead-in authored
            # between the unlocked _prepare read and now is carried, not clobbered.
            proposed = _build_perspectives(wiki_root, current)
            changed = proposed != current
            if changed:
                page_path.parent.mkdir(parents=True, exist_ok=True)
                atomic_write_text(page_path, proposed)
    except OSError as exc:
        return _emit(False, error=f"perspectives write failed: {exc}")

    return _emit(True, data={
        "path": str(page_path),
        "subcommand": "render",
        "changed": changed,
        "facet_count": len(FACET_DISPLAY),
    })


def cmd_stage(args) -> int:
    """`stage`: write the proposed overlay to .cogni-wiki/perspectives-proposed.md;
    lock-free, never touches the live page."""
    payload, err = _prepare(args.wiki_root)
    if err:
        return _emit(False, error=err)
    stage_path = payload["wiki_root"].joinpath(".cogni-wiki", "perspectives-proposed.md")
    live = payload["existing"]
    proposed = payload["proposed"]
    is_human = _is_human_page(live)
    would_change = (not is_human) and (proposed != live)
    header = (
        "<!-- staged proposal for wiki/perspectives.md — written by "
        "perspectives_index.py stage; NOT the live page -->\n"
        f"<!-- status: {'would-update' if would_change else 'no-change'}; "
        f"facets={len(FACET_DISPLAY)}; live-is-human-page={str(is_human).lower()} -->\n\n"
    )
    try:
        stage_path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_text(stage_path, header + proposed)
    except OSError as exc:
        return _emit(False, error=f"staged proposal write failed: {exc}")
    return _emit(True, data={
        "path": str(stage_path),
        "subcommand": "stage",
        "would_change": would_change,
        "facet_count": len(FACET_DISPLAY),
    })


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Deterministic 5W1H overlay renderer for wiki/perspectives.md "
                    "(re-projects the type-first layout by perspective; no canonical "
                    "layout change).",
    )
    sub = parser.add_subparsers(dest="subcommand", required=True)

    rn = sub.add_parser(
        "render",
        help="Write wiki/perspectives.md live as the 5W1H overlay (locked, atomic, "
             "idempotent, no-clobber).",
    )
    rn.add_argument("--wiki-root", required=True)
    rn.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    rn.set_defaults(func=cmd_render)

    st = sub.add_parser(
        "stage",
        help="Write the proposed overlay to "
             "<wiki-root>/.cogni-wiki/perspectives-proposed.md without the lock "
             "and without touching the live page.",
    )
    st.add_argument("--wiki-root", required=True)
    st.set_defaults(func=cmd_stage)

    return parser


def main(argv: "Optional[list[str]]" = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
