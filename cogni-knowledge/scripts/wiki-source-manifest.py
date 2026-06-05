#!/usr/bin/env python3
"""Synthesize an ingest-manifest.json from a populated wiki's source pages — the
evidence base for `knowledge-compose --source wiki` (the wiki-only report rung).

The inverted pipeline's `wiki-composer` discovers which `wiki/sources/<slug>.md`
pages to draw on, and which sub-question each covers, from
`<project>/.metadata/ingest-manifest.json::ingested[].sub_question_refs[]`. In the
default `web` mode that manifest is produced by `knowledge-ingest` from a fresh
web crawl. Under `--source wiki` there is no crawl — so this script builds the
SAME manifest shape from the already-populated wiki instead, mapping each
`type: source` page to the CURRENT plan's sub-questions via the shared
`wiki-grounding` discovery primitive (the one `wiki-coverage.py` also resolves
to). The composer then runs byte-for-byte unchanged: it reads a manifest, it
does not care whether the manifest came from the web or from the wiki.

A source page that covers none of the plan's sub-questions is excluded (it would
map to no section). An empty result means the wiki holds no source pages relevant
to this plan — the caller surfaces that as "narrow the plan or ingest more".

Stdlib only; JSON envelope output per the insight-wave convention.
"""

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

# wiki-grounding.py is hyphenated (not an importable module name), so load it by
# path — the same pattern wiki-coverage.py uses to resolve the shared primitive.
_GROUNDING_PATH = HERE / "wiki-grounding.py"
_spec = importlib.util.spec_from_file_location("wiki_grounding", _GROUNDING_PATH)
wg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wg)  # type: ignore[union-attr]

from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    _unquote_scalar,
    atomic_write,
    extract_page_id_and_url,
    parse_pre_extracted_claims,
)

SCHEMA_VERSION = "0.1.0"  # matches knowledge-ingest's ingest-manifest schema


def _scalar(frontmatter: str, key: str) -> str:
    """First top-level `key: <scalar>` value in a frontmatter block, unquoted."""
    m = re.search(rf"^{re.escape(key)}:[ \t]*(.+?)[ \t]*$", frontmatter, re.MULTILINE)
    return _unquote_scalar(m.group(1).strip()) if m else ""


def _publisher_fallback(url: str) -> str:
    """Domain (sans leading www.) as a best-effort publisher when the page has none."""
    try:
        host = urlparse(url).netloc
        return host[4:] if host.startswith("www.") else host
    except ValueError:
        return ""


def build(wiki_root: Path, plan_path: Path, out_path: Path,
          threshold: float, top_k: int) -> dict:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    sub_questions = plan.get("sub_questions", []) or []

    pages = wg.collect_pages(wiki_root)
    source_pages = [p for p in pages if p.get("type") == "source"]
    slug_to_page = {p["slug"]: p for p in source_pages}

    # Map each source slug -> the set of current-plan sub-question ids it covers,
    # using the same per-sub-question token set + discovery primitive that
    # wiki-coverage.py uses for the read-before-web step.
    slug_to_sqs: dict[str, set] = {}
    for sq in sub_questions:
        sqid = sq.get("id") or sq.get("sub_question_id") or ""
        if not sqid:
            continue
        tokens = wg.sq_token_set({
            "query": sq.get("query") or sq.get("question") or "",
            "theme_label": sq.get("theme_label", "") or "",
        })
        ranked = wg.rank_pages(source_pages, tokens, threshold, top_k)
        for pg in ranked["covered_pages"]:
            slug_to_sqs.setdefault(pg["slug"], set()).add(sqid)

    ingested = []
    for slug in sorted(slug_to_sqs):
        page = slug_to_page.get(slug)
        if not page:
            continue
        page_text = (wiki_root / page["page_path"]).read_text(encoding="utf-8")
        _, url = extract_page_id_and_url(page_text)
        m = _FRONTMATTER_RE.match(page_text)
        fm = m.group(1) if m else ""
        title = _scalar(fm, "title") or page.get("title", "") or slug
        publisher = _scalar(fm, "publisher") or _publisher_fallback(url)
        claims = parse_pre_extracted_claims(page_text)
        ingested.append({
            "url": url,
            "slug": slug,
            "title": title,
            "publisher": publisher,
            "summary": title,
            "claims_extracted": len(claims),
            "sub_question_refs": sorted(slug_to_sqs[slug]),
        })

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "source_mode": "wiki",  # marks this as a synthesized (no-crawl) manifest
        "ingested": ingested,
        "skipped": [],
    }
    atomic_write(out_path, manifest)

    return {
        "out": str(out_path),
        "source_pages_scanned": len(source_pages),
        "ingested_count": len(ingested),
        "sub_questions": len([sq for sq in sub_questions
                              if (sq.get("id") or sq.get("sub_question_id"))]),
    }


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error},
                     indent=2, ensure_ascii=False))
    return 0 if success else 1


def cmd_build(args: argparse.Namespace) -> int:
    if not (0.0 < args.threshold <= 1.0):
        return _emit(False, error=f"--threshold must be in (0.0, 1.0], got {args.threshold}")
    if args.top_k < 1:
        return _emit(False, error=f"--top-k must be >= 1, got {args.top_k}")
    wiki_root = Path(args.wiki_root)
    plan_path = Path(args.plan)
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"no wiki/ under wiki-root: {wiki_root}")
    if not plan_path.is_file():
        return _emit(False, error=f"plan.json not found: {plan_path}")
    try:
        data = build(wiki_root, plan_path, Path(args.out), args.threshold, args.top_k)
    except (OSError, ValueError, KeyError) as exc:
        return _emit(False, error=f"build failed: {exc}")
    return _emit(True, data=data)


def main(argv: list | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Synthesize an ingest-manifest.json from a wiki's source pages "
                    "for knowledge-compose --source wiki.")
    sub = parser.add_subparsers(dest="command", required=True)
    p_build = sub.add_parser("build", help="build the synthetic ingest-manifest")
    p_build.add_argument("--wiki-root", required=True, help="absolute path to the wiki root")
    p_build.add_argument("--plan", required=True, help="path to <project>/.metadata/plan.json")
    p_build.add_argument("--out", required=True, help="path to write the synthetic ingest-manifest.json")
    p_build.add_argument("--threshold", type=float, default=wg.DEFAULT_THRESHOLD,
                         help="coverage threshold (0.0, 1.0]")
    p_build.add_argument("--top-k", type=int, default=wg.TOP_K,
                         help="max covering source pages emitted per sub-question")
    p_build.set_defaults(func=cmd_build)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
