#!/usr/bin/env python3
"""retrieval-eval.py — read-only retrieval-quality baseline harness.

Runs a labelled `question -> expected-page(s)` set through the existing
`wiki-grounding.py` `rank` primitive and computes hit@1, hit@5, and MRR
(rank-of-first-relevant as a click-depth proxy) per-query and aggregate.

WHY THIS EXISTS
    The engagement's success metric is downstream-agent retrieval hit-rate /
    click-depth, but nothing measures it. `wiki-grounding.py rank` is the live
    discovery primitive (the curate read-side and the query skill both resolve
    to it), yet it emits only `overlap_score` / a coverage verdict — there is no
    hit@k / MRR baseline anywhere. Without a baseline, the deferred
    navigation-redesign track is unfalsifiable. This harness captures that
    baseline so before/after is durable and the redesign becomes measurable.

STRICTLY READ-ONLY against the pipeline. The harness only *reads* the existing
ranking primitive (it never edits wiki pages, manifests, or any pipeline state)
and writes its own eval artifacts under `<wiki_root>/.cogni-knowledge/`:
    - the labelled set:  <wiki_root>/.cogni-knowledge/retrieval-eval-set.json
    - the run results:   <wiki_root>/.cogni-knowledge/retrieval-eval.json

The labelled set seeds from the bound base's `wiki/questions/*.md` nodes
(`sources_answering:` is the ground-truth page set; the node `title:` is the
query text, `theme_label:` the theme), so the regression floor is grounded in
real question nodes. Held-out queries can be appended to the set file by hand;
re-seeding never overwrites an existing set unless `--reseed` is passed.

stdlib + python3 only. JSON `{success, data, error}` envelope on stdout.
"""

from __future__ import annotations

import argparse
import datetime
import importlib.util
import json
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Load the shared ranking primitive and the shared lib.
#
# `wiki-grounding.py` is hyphenated, so it is NOT an importable module name —
# load it by path via importlib.util.spec_from_file_location (the same idiom the
# tests use). `_knowledge_lib` IS importable; add scripts/ to sys.path for it.
# ---------------------------------------------------------------------------
_SCRIPTS_DIR = Path(__file__).resolve().parent


def _load_by_path(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, _SCRIPTS_DIR / filename)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_wg = _load_by_path("wiki_grounding", "wiki-grounding.py")
collect_pages = _wg.collect_pages
sq_token_set = _wg.sq_token_set
rank_pages = _wg.rank_pages
DEFAULT_THRESHOLD = _wg.DEFAULT_THRESHOLD

sys.path.insert(0, str(_SCRIPTS_DIR))
from _knowledge_lib import atomic_write, frontmatter_scalar, _unquote_scalar  # noqa: E402


# ---------------------------------------------------------------------------
# Envelope
# ---------------------------------------------------------------------------
def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Question-node seeding
# ---------------------------------------------------------------------------
def _parse_inline_list(raw: str) -> list[str]:
    """Parse a YAML inline list scalar (e.g. `[slug-a, slug-b]`, as
    `frontmatter_scalar` returns it) into bare string items. Question nodes write
    `sources_answering:` with unquoted kebab slugs, so stripping the brackets and
    a comma split + unquote is sufficient and fail-soft (an empty body yields
    [])."""
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        raw = raw[1:-1]
    items = []
    for part in raw.split(","):
        v = part.strip()
        if not v:
            continue
        items.append(_unquote_scalar(v))
    return items


def seed_from_questions(wiki_root: Path) -> list[dict]:
    """Build a labelled set from `wiki/questions/*.md`. Each question node whose
    `sources_answering:` is non-empty becomes one labelled query:
        {query: <title>, theme_label: <theme_label>, expected_slugs: [...]}
    A node with no ground-truth answering set is skipped (no label to score).

    Frontmatter scalars are read via the shared `_knowledge_lib.frontmatter_scalar`
    (column-0 key, inline-comment strip, `_unquote_scalar`) so this stays in lock-
    step with how the rest of the engine parses question-node frontmatter."""
    qdir = wiki_root / "wiki" / "questions"
    queries: list[dict] = []
    if not qdir.is_dir():
        return queries
    for page in sorted(qdir.glob("*.md")):
        if page.name == "index.md":
            continue
        text = page.read_text(encoding="utf-8")
        title = frontmatter_scalar(text, "title")
        expected = _parse_inline_list(frontmatter_scalar(text, "sources_answering"))
        if not (title and expected):
            continue
        queries.append({
            "query": title,
            "theme_label": frontmatter_scalar(text, "theme_label"),
            "expected_slugs": expected,
            "source_node": page.stem,
        })
    return queries


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------
def _rank_of_first_relevant(pages: list[dict], query: dict,
                            threshold: float) -> int | None:
    """Rank (1-indexed) of the first ranked page whose slug is in the query's
    expected set, or None if no expected page is in the passing set.

    Uses a top_k large enough to return the FULL passing set, so MRR and hit@5
    are never truncated by the default rank cap (the refiner's faithful-
    measurement fix)."""
    expected = set(query.get("expected_slugs") or [])
    sq_tokens = sq_token_set({
        "query": query.get("query", ""),
        "theme_label": query.get("theme_label", ""),
    })
    full_k = max(len(pages), 5)
    ranked = rank_pages(pages, sq_tokens, threshold, full_k)
    for idx, page in enumerate(ranked["covered_pages"], start=1):
        if page["slug"] in expected:
            return idx
    return None


def run_eval(wiki_root: Path, queries: list[dict], threshold: float) -> dict:
    # include_interviews=True: interview pages are source-class evidence on the
    # read side, so a question whose ground-truth answer is an interview note
    # must not score as a false miss (the refiner's faithful-measurement fix).
    pages = collect_pages(wiki_root, include_interviews=True)
    per_query = []
    hits_at_1 = 0
    hits_at_5 = 0
    rr_sum = 0.0
    for q in queries:
        rank = _rank_of_first_relevant(pages, q, threshold)
        rr = (1.0 / rank) if rank else 0.0
        h1 = 1 if rank == 1 else 0
        h5 = 1 if (rank is not None and rank <= 5) else 0
        hits_at_1 += h1
        hits_at_5 += h5
        rr_sum += rr
        per_query.append({
            "query": q.get("query", ""),
            "theme_label": q.get("theme_label", ""),
            "expected_slugs": q.get("expected_slugs") or [],
            "source_node": q.get("source_node"),
            "rank_of_first_relevant": rank,
            "reciprocal_rank": round(rr, 4),
            "hit_at_1": h1,
            "hit_at_5": h5,
        })
    n = len(queries)
    aggregate = {
        "n_queries": n,
        "hit_at_1": round(hits_at_1 / n, 4) if n else 0.0,
        "hit_at_5": round(hits_at_5 / n, 4) if n else 0.0,
        "mrr": round(rr_sum / n, 4) if n else 0.0,
    }
    return {
        "wiki_root": str(wiki_root),
        "threshold": threshold,
        "pages_scanned": len(pages),
        "run_at": _now_iso(),
        "aggregate": aggregate,
        "per_query": per_query,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def cmd_eval(args: argparse.Namespace) -> int:
    threshold = args.threshold
    if not (0.0 < threshold <= 1.0):
        return _emit(False, error=f"--threshold must be in (0.0, 1.0], got {threshold}")

    wiki_root = Path(args.wiki_root)
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"no wiki/ dir under --wiki-root {wiki_root}")

    base_dir = wiki_root / ".cogni-knowledge"
    set_path = Path(args.eval_set) if args.eval_set else base_dir / "retrieval-eval-set.json"
    out_path = Path(args.out) if args.out else base_dir / "retrieval-eval.json"

    # Resolve the labelled set: load an existing one, or seed from question
    # nodes. --reseed forces a fresh seed even when a set file exists.
    if set_path.exists() and not args.reseed:
        try:
            stored = json.loads(set_path.read_text(encoding="utf-8"))
            queries = stored.get("queries") if isinstance(stored, dict) else stored
            if not isinstance(queries, list):
                return _emit(False, error=f"malformed eval set at {set_path}")
        except (OSError, ValueError) as exc:
            return _emit(False, error=f"cannot read eval set {set_path}: {exc}")
        seeded = False
    else:
        queries = seed_from_questions(wiki_root)
        if not queries:
            return _emit(False, error=(
                "no labelled queries: wiki/questions/*.md yielded no nodes with a "
                "non-empty sources_answering set to seed from, and no --eval-set "
                "was supplied"
            ))
        atomic_write(set_path, {"version": 1, "seeded_at": _now_iso(), "queries": queries})
        seeded = True

    result = run_eval(wiki_root, queries, threshold)
    atomic_write(out_path, {"success": True, "data": result, "error": ""})

    return _emit(True, data={
        **result,
        "eval_set_path": str(set_path),
        "eval_set_seeded_this_run": seeded,
        "out_path": str(out_path),
    })


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read-only retrieval-quality baseline harness (hit@k / MRR) "
                    "over wiki-grounding.py rank."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("eval", help="Run the labelled set through rank and emit hit@1/hit@5/MRR.")
    p.add_argument("--wiki-root", required=True,
                   help="Directory containing wiki/ (the bound base).")
    p.add_argument("--eval-set", default=None,
                   help="Path to a labelled-set JSON. Default: "
                        "<wiki_root>/.cogni-knowledge/retrieval-eval-set.json")
    p.add_argument("--reseed", action="store_true",
                   help="Re-seed the labelled set from question nodes even if a set file exists.")
    p.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                   help=f"Coverage threshold passed to rank_pages (default {DEFAULT_THRESHOLD}).")
    p.add_argument("--out", default=None,
                   help="Path to write run results. Default: "
                        "<wiki_root>/.cogni-knowledge/retrieval-eval.json")
    p.set_defaults(func=cmd_eval)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except Exception as exc:  # fail-soft: never traceback to the caller
        return _emit(False, error=f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
