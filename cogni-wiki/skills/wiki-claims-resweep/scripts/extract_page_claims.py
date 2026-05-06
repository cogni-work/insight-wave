#!/usr/bin/env python3
"""
extract_page_claims.py — deterministic claim candidate extraction from wiki page prose.

Walks <wiki-root>/wiki/pages/, parses each page's frontmatter and body, and emits
claim candidates that the wiki-claims-resweep skill submits to cogni-claims for
re-verification.

Boundary: this script is **read-only** and **never** makes network calls. It reads
markdown, parses frontmatter, and prints JSON. WebFetch happens later, inside the
cogni-claims:claim-verifier agent that the SKILL dispatches.

Extraction rule (deterministic, no LLM):
    For each inline-link `[text](http(s)://...)` and each bare `http(s)://...` URL
    in the page body, take the containing sentence as the claim statement and the
    URL as the source. Sentences are split on `.`, `!`, `?` followed by whitespace
    and on blank lines. Markdown link syntax is stripped from the rendered claim.
    Sentences shorter than MIN_CLAIM_CHARS are dropped (heuristically reduces
    list-item / heading noise). Identical (statement, url) pairs dedupe.

Page selection (mode is mutually exclusive):
    --all          Every page that has a non-empty `sources:` frontmatter.
    --page <slug>  Single-page sweep.
    --stale-only   Pages whose `updated:` date is older than STALE_PAGE_DAYS
                   (mirrors wiki-lint's threshold; status=draft uses
                   STALE_DRAFT_DAYS).

Refusal: pages where any extracted claim's source URL points back into the same
wiki tree (relative wikilink or path under <wiki-root>) are dropped from that
page's claim list and counted in `circular_skipped`. Pattern from PRs #198/#199.

Output contract:
    {
      "success": true,
      "data": {
        "wiki_root": "...",
        "mode": "all|page|stale-only",
        "pages": [
          {
            "slug": "...",
            "title": "...",
            "page_path": "wiki/pages/<slug>.md",
            "updated": "YYYY-MM-DD",
            "age_days": <int|null>,
            "claims": [
              {"statement": "...", "source_url": "https://...",
               "source_title": "...", "line": <int>}
            ],
            "circular_skipped": <int>
          }
        ],
        "stats": {
          "pages_scanned": <int>,
          "pages_with_claims": <int>,
          "total_claims": <int>,
          "total_unique_sources": <int>,
          "circular_skipped": <int>,
          "pages_skipped_no_sources": <int>
        }
      },
      "error": ""
    }

stdlib-only, Python 3.8+.
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
    build_slug_index,
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
)


STALE_DRAFT_DAYS = 180
STALE_PAGE_DAYS = 365

MIN_CLAIM_CHARS = 30
MAX_CLAIMS_PER_PAGE = 50

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
INLINE_LINK_RE = re.compile(r"\[([^\]]+)\]\((https?://[^)\s]+)\)")
BARE_URL_RE = re.compile(r"(?<![\(\[\"'])\bhttps?://[^\s)\]<>\"']+")
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+(?=[A-Z\[(])|\n\s*\n")
WIKILINK_RE = re.compile(r"\[\[[^\]]+\]\]")
MD_LINK_STRIP_RE = re.compile(r"\[([^\]]+)\]\([^)]+\)")
WHITESPACE_RE = re.compile(r"\s+")


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def parse_frontmatter(text: str) -> dict:
    """Lightweight YAML subset parser, mirrors lint_wiki.py for consistency."""
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
                out[k] = [x.strip() for x in inside.split(",") if x.strip()] if inside else []
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def parse_date(s: str):
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


def split_body(text: str) -> str:
    m = FRONTMATTER_RE.match(text)
    return text[m.end():] if m else text


def strip_markdown(s: str) -> str:
    """Render claim text as plain prose: drop markdown link syntax, wikilinks,
    code-fences, and squash whitespace. Keep the link's anchor text."""
    s = MD_LINK_STRIP_RE.sub(r"\1", s)
    s = WIKILINK_RE.sub("", s)
    s = s.replace("`", "")
    s = s.lstrip("-*> \t").strip()
    s = WHITESPACE_RE.sub(" ", s)
    return s.strip()


def is_circular_source(url: str, wiki_root: Path) -> bool:
    """A URL is circular if it points back into this wiki: a relative path
    starting with `wiki/` or an absolute path under <wiki-root>. Outside
    URLs (http/https) are always non-circular."""
    if url.startswith(("http://", "https://")):
        return False
    if url.startswith("wiki/") or url.startswith("../wiki/") or url.startswith("./wiki/"):
        return True
    try:
        resolved = (wiki_root / url).resolve()
        wiki_pages = (wiki_root / "wiki").resolve()
        return str(resolved).startswith(str(wiki_pages))
    except (OSError, ValueError):
        return False


def extract_claims_from_body(body: str, wiki_root: Path) -> tuple[list[dict], int]:
    """Return (claims, circular_skipped_count)."""
    claims: list[dict] = []
    circular = 0
    seen: set = set()

    sentences = SENTENCE_SPLIT_RE.split(body)
    line_offsets: list[int] = []
    cursor = 0
    for sent in sentences:
        line_offsets.append(body[:cursor].count("\n") + 1)
        cursor += len(sent) + 1

    for idx, raw_sent in enumerate(sentences):
        sent = raw_sent.strip()
        if not sent:
            continue

        urls: list[tuple[str, str]] = []
        for m in INLINE_LINK_RE.finditer(sent):
            urls.append((m.group(2), m.group(1).strip()))
        for m in BARE_URL_RE.finditer(sent):
            url = m.group(0).rstrip(".,;:!?")
            if not any(url == u for u, _ in urls):
                urls.append((url, ""))

        if not urls:
            continue

        statement = strip_markdown(sent)
        if len(statement) < MIN_CLAIM_CHARS:
            continue

        for url, anchor_text in urls:
            if is_circular_source(url, wiki_root):
                circular += 1
                continue
            key = (statement, url)
            if key in seen:
                continue
            seen.add(key)
            claims.append({
                "statement": statement,
                "source_url": url,
                "source_title": anchor_text or url,
                "line": line_offsets[idx] if idx < len(line_offsets) else 0,
            })
            if len(claims) >= MAX_CLAIMS_PER_PAGE:
                return claims, circular
    return claims, circular


def find_wiki_root(start: Path) -> Path:
    current = start.resolve()
    while True:
        if (current / ".cogni-wiki" / "config.json").is_file():
            return current
        if current.parent == current:
            fail(f"not inside a cogni-wiki (no .cogni-wiki/config.json at or above {start})")
        current = current.parent


def select_pages(wiki_root: Path, mode: str, page_arg: str | None,
                 days_override: int | None) -> list[Path]:
    today = dt.date.today()
    all_paths = sorted(
        path for slug, path, _ptype in iter_pages(wiki_root)
        if not is_audit_slug(slug)
    )

    if mode == "page":
        slug_index = build_slug_index(wiki_root)
        entry = slug_index.get(page_arg)
        if entry is None:
            fail(f"page not found: {page_arg}")
        target = entry[0]
        return [target]

    if mode == "stale-only":
        out: list[Path] = []
        for path in all_paths:
            try:
                fm = parse_frontmatter(path.read_text(encoding="utf-8"))
            except OSError:
                continue
            updated = parse_date(_unquote(fm.get("updated", "")))
            if not updated:
                continue
            age = (today - updated).days
            status = _unquote(fm.get("status", "")).lower()
            threshold = days_override if days_override is not None else (
                STALE_DRAFT_DAYS if status == "draft" else STALE_PAGE_DAYS
            )
            if age > threshold:
                out.append(path)
        return out

    return all_paths  # mode == "all"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract claim candidates from wiki pages (deterministic, no network).")
    parser.add_argument("--wiki-root", help="Override auto-detected wiki root.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--all", action="store_true", help="Every page with non-empty sources (default).")
    group.add_argument("--page", metavar="SLUG", help="Single-page sweep.")
    group.add_argument("--stale-only", action="store_true",
                       help="Only pages older than STALE_PAGE_DAYS (or --days).")
    parser.add_argument("--days", type=int, default=None,
                        help="Override staleness threshold (used with --stale-only).")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    wiki_root = Path(args.wiki_root).resolve() if args.wiki_root else find_wiki_root(Path.cwd())
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki: {wiki_root}/.cogni-wiki/config.json not found")
    fail_if_pre_migration(wiki_root)

    if args.page:
        mode = "page"
    elif args.stale_only:
        mode = "stale-only"
    else:
        mode = "all"

    if args.days is not None and mode != "stale-only":
        fail("--days requires --stale-only")

    selected = select_pages(wiki_root, mode, args.page, args.days)

    today = dt.date.today()
    pages_out: list[dict] = []
    pages_skipped_no_sources = 0
    total_circular = 0
    unique_sources: set = set()

    for path in selected:
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        sources = fm.get("sources", [])
        if isinstance(sources, list) and not sources:
            pages_skipped_no_sources += 1
            continue
        if not isinstance(sources, list):
            pages_skipped_no_sources += 1
            continue

        body = split_body(text)
        claims, circular = extract_claims_from_body(body, wiki_root)
        total_circular += circular
        if not claims:
            continue

        updated = parse_date(_unquote(fm.get("updated", "")))
        age = (today - updated).days if updated else None

        for c in claims:
            unique_sources.add(c["source_url"])

        pages_out.append({
            "slug": path.stem,
            "title": _unquote(fm.get("title", "")) or path.stem,
            "page_path": str(path.relative_to(wiki_root)),
            "updated": _unquote(fm.get("updated", "")),
            "age_days": age,
            "claims": claims,
            "circular_skipped": circular,
        })

    ok({
        "wiki_root": str(wiki_root),
        "mode": mode,
        "pages": pages_out,
        "stats": {
            "pages_scanned": len(selected),
            "pages_with_claims": len(pages_out),
            "total_claims": sum(len(p["claims"]) for p in pages_out),
            "total_unique_sources": len(unique_sources),
            "circular_skipped": total_circular,
            "pages_skipped_no_sources": pages_skipped_no_sources,
        },
    })


if __name__ == "__main__":
    main()
