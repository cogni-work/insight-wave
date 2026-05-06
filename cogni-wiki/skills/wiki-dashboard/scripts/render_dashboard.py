#!/usr/bin/env python3
"""
render_dashboard.py — generate a self-contained HTML dashboard for a cogni-wiki.

Usage:
    render_dashboard.py --wiki-root <path> [--output <path>]

Output contract:
    Writes the HTML file to --output (default: <wiki-root>/wiki-dashboard.html).
    Prints a JSON summary to stdout:
    {"success": true, "data": {"output": "<path>", "pages": N, ...}, "error": ""}

Design constraints:
    - stdlib only
    - No network calls
    - Single HTML file with inlined CSS, no JS
    - Idempotent (same bytes on repeat runs, modulo the generated-at timestamp)
    - Bash 3.2 / Python 3.8+ compatible
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"))
from _wikilib import (  # noqa: E402
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
)


FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
WIKILINK_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\]")

VALID_TYPES = ["concept", "entity", "summary", "decision", "interview", "meeting", "learning", "synthesis", "note"]
TYPE_COLORS = {
    "concept": "#2563eb",
    "entity": "#059669",
    "summary": "#d97706",
    "decision": "#dc2626",
    "interview": "#0d9488",
    "meeting": "#9333ea",
    "learning": "#7c3aed",
    "synthesis": "#0891b2",
    "note": "#64748b",
}


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def parse_frontmatter(text: str) -> dict:
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


def e(s) -> str:
    return html.escape(str(s or ""))


STYLE = """
* { box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  margin: 0;
  color: #111827;
  background: #f9fafb;
  line-height: 1.5;
}
main { max-width: 1100px; margin: 0 auto; padding: 32px 24px 64px; }
header h1 { margin: 0 0 4px; font-size: 28px; letter-spacing: -0.02em; }
header .slug { color: #6b7280; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; }
header .desc { color: #374151; margin: 8px 0 0; }
.meta { color: #6b7280; font-size: 13px; margin-top: 4px; }
section { background: #fff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 20px 22px; margin: 20px 0; }
section h2 { margin: 0 0 14px; font-size: 16px; text-transform: uppercase; letter-spacing: 0.05em; color: #374151; }
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; }
.stat { background: #f3f4f6; border-radius: 8px; padding: 14px 16px; }
.stat .num { font-size: 26px; font-weight: 600; color: #111827; }
.stat .lbl { font-size: 12px; color: #6b7280; margin-top: 2px; }
.bar-row { display: flex; align-items: center; gap: 10px; margin: 6px 0; font-size: 14px; }
.bar-row .type-lbl { width: 90px; color: #374151; }
.bar-row .bar-container { flex: 1; background: #f3f4f6; height: 18px; border-radius: 4px; overflow: hidden; }
.bar-row .bar { height: 100%; }
.bar-row .count { width: 40px; text-align: right; color: #6b7280; font-variant-numeric: tabular-nums; }
.tags { display: flex; flex-wrap: wrap; gap: 8px 10px; }
.tag { background: #eef2ff; color: #4338ca; padding: 3px 10px; border-radius: 999px; font-size: 13px; }
.activity { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; color: #374151; white-space: pre-wrap; max-height: 240px; overflow: auto; }
.pages-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 6px 16px; }
.pages-list .entry { font-size: 13px; color: #111827; }
.pages-list .entry .type-tag { font-size: 10px; text-transform: uppercase; color: #fff; padding: 1px 6px; border-radius: 3px; margin-right: 6px; vertical-align: middle; }
.pages-list .entry .links { color: #6b7280; font-variant-numeric: tabular-nums; }
.pages-list .entry.orphan { color: #b45309; }
footer { color: #9ca3af; font-size: 12px; margin-top: 24px; text-align: center; }
"""


def build_html(ctx: dict) -> str:
    pages = ctx["pages"]
    stats = ctx["stats"]
    type_counts = ctx["type_counts"]
    tag_counts = ctx["tag_counts"]
    recent_log = ctx["recent_log"]
    orphans = ctx["orphans"]
    inbound_counts = ctx["inbound_counts"]
    cfg = ctx["config"]

    # Type bars
    max_type = max(type_counts.values()) if type_counts else 1
    bars = []
    for t in VALID_TYPES:
        n = type_counts.get(t, 0)
        pct = (n / max_type * 100) if max_type else 0
        color = TYPE_COLORS.get(t, "#9ca3af")
        bars.append(
            f'<div class="bar-row"><span class="type-lbl">{e(t)}</span>'
            f'<div class="bar-container"><div class="bar" style="width:{pct:.1f}%;background:{color}"></div></div>'
            f'<span class="count">{n}</span></div>'
        )
    type_bars_html = "\n".join(bars)

    # Tag cloud
    top_tags = tag_counts.most_common(30)
    if top_tags:
        max_tag = top_tags[0][1]
        min_tag = top_tags[-1][1]
        tag_spans = []
        for tag, n in top_tags:
            if max_tag == min_tag:
                size = 14
            else:
                size = 12 + int(((n - min_tag) / (max_tag - min_tag)) * 12)
            tag_spans.append(f'<span class="tag" style="font-size:{size}px">{e(tag)} · {n}</span>')
        tags_html = '<div class="tags">' + "".join(tag_spans) + "</div>"
    else:
        tags_html = '<div class="meta">No tags yet.</div>'

    # Recent activity
    activity_html = f'<div class="activity">{e(chr(10).join(recent_log)) or "No activity yet."}</div>'

    # Most-linked pages
    most_linked = sorted(inbound_counts.items(), key=lambda kv: (-kv[1], kv[0]))[:10]
    if most_linked:
        ml_html = '<ul style="margin:0;padding-left:20px;font-size:14px">' + "".join(
            f'<li>{e(slug)} <span class="meta">— {n} inbound</span></li>' for slug, n in most_linked
        ) + "</ul>"
    else:
        ml_html = '<div class="meta">No inbound links yet.</div>'

    # Orphans
    if orphans:
        orph_html = '<ul style="margin:0;padding-left:20px;font-size:14px;color:#b45309">' + "".join(
            f"<li>{e(slug)}</li>" for slug in orphans
        ) + "</ul>"
    else:
        orph_html = '<div class="meta">No orphan pages — every page has at least one inbound link. ✓</div>'

    # Full index grouped by type
    grouped: dict = {t: [] for t in VALID_TYPES}
    grouped["_other"] = []
    for p in pages:
        t = p["type"] if p["type"] in VALID_TYPES else "_other"
        grouped[t].append(p)

    sections = []
    for t in VALID_TYPES + ["_other"]:
        items = grouped[t]
        if not items:
            continue
        entries = []
        for p in sorted(items, key=lambda x: x["title"].lower()):
            inbound = inbound_counts.get(p["slug"], 0)
            orphan_cls = " orphan" if inbound == 0 else ""
            color = TYPE_COLORS.get(p["type"], "#9ca3af")
            entries.append(
                f'<div class="entry{orphan_cls}">'
                f'<span class="type-tag" style="background:{color}">{e(p["type"] or "?")}</span>'
                f'{e(p["title"])} '
                f'<span class="links">· {inbound}↵</span>'
                f"</div>"
            )
        label = t if t != "_other" else "other"
        sections.append(
            f'<h3 style="margin:18px 0 6px;font-size:13px;text-transform:uppercase;color:#6b7280">{e(label)} ({len(items)})</h3>'
            f'<div class="pages-list">{"".join(entries)}</div>'
        )
    index_html = "".join(sections) or '<div class="meta">No pages yet.</div>'

    generated_at = dt.datetime.now().strftime("%Y-%m-%d %H:%M")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wiki Dashboard — {e(cfg.get('name', 'cogni-wiki'))}</title>
<style>{STYLE}</style>
</head>
<body>
<main>
  <header>
    <h1>{e(cfg.get("name", "cogni-wiki"))}</h1>
    <div class="slug">{e(cfg.get("slug", ""))}</div>
    <p class="desc">{e(cfg.get("description", ""))}</p>
    <div class="meta">Created {e(cfg.get("created", "?"))} · generated {e(generated_at)}</div>
  </header>

  <section>
    <h2>At a glance</h2>
    <div class="stats">
      <div class="stat"><div class="num">{stats['pages']}</div><div class="lbl">pages</div></div>
      <div class="stat"><div class="num">{stats['raw']}</div><div class="lbl">raw sources</div></div>
      <div class="stat"><div class="num">{stats['links']}</div><div class="lbl">internal links</div></div>
      <div class="stat"><div class="num">{stats['tags']}</div><div class="lbl">unique tags</div></div>
      <div class="stat"><div class="num">{stats['orphans']}</div><div class="lbl">orphans</div></div>
    </div>
  </section>

  <section>
    <h2>Pages by type</h2>
    {type_bars_html}
  </section>

  <section>
    <h2>Tag cloud</h2>
    {tags_html}
  </section>

  <section>
    <h2>Most-linked pages</h2>
    {ml_html}
  </section>

  <section>
    <h2>Orphan pages</h2>
    {orph_html}
  </section>

  <section>
    <h2>Recent activity</h2>
    {activity_html}
  </section>

  <section>
    <h2>Full index</h2>
    {index_html}
  </section>

  <footer>Generated by cogni-wiki · Karpathy-pattern compounding knowledge base</footer>
</main>
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a cogni-wiki dashboard as self-contained HTML")
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    config_path = wiki_root / ".cogni-wiki" / "config.json"
    raw_dir = wiki_root / "raw"
    log_path = wiki_root / "wiki" / "log.md"

    if not config_path.is_file():
        fail(f"not a cogni-wiki: {config_path} missing")
    fail_if_pre_migration(wiki_root)

    try:
        with config_path.open(encoding="utf-8") as f:
            config = json.load(f)
    except Exception as exc:
        fail(f"config.json unreadable: {exc}")
        return

    pages: list = []
    type_counts: Counter = Counter()
    tag_counts: Counter = Counter()
    inbound_counts: Counter = Counter()
    total_links = 0

    for slug, path, ptype_dir in iter_pages(wiki_root):
        if is_audit_slug(slug):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        title = fm.get("title", slug) or slug
        ptype = fm.get("type", "") or ptype_dir
        tags = fm.get("tags", []) if isinstance(fm.get("tags", []), list) else []
        type_counts[ptype] += 1
        for t in tags:
            if isinstance(t, str):
                tag_counts[t] += 1
        links = WIKILINK_RE.findall(text)
        total_links += len(links)
        for target in links:
            inbound_counts[target] += 1
        pages.append({"slug": slug, "title": title, "type": ptype, "tags": tags})

    existing_slugs = {p["slug"] for p in pages}
    orphans = sorted(
        slug for slug in existing_slugs if inbound_counts.get(slug, 0) == 0
    )

    raw_count = 0
    if raw_dir.is_dir():
        raw_count = sum(1 for _ in raw_dir.glob("*") if _.is_file())

    recent_log: list = []
    if log_path.is_file():
        try:
            log_lines = log_path.read_text(encoding="utf-8").splitlines()
            recent_log = [
                line for line in log_lines if line.startswith("## [")
            ][-20:]
        except OSError:
            recent_log = []

    stats = {
        "pages": len(pages),
        "raw": raw_count,
        "links": total_links,
        "tags": len(tag_counts),
        "orphans": len(orphans),
    }

    output = Path(args.output).expanduser().resolve() if args.output else wiki_root / "wiki-dashboard.html"
    html_text = build_html(
        {
            "config": config,
            "pages": pages,
            "stats": stats,
            "type_counts": type_counts,
            "tag_counts": tag_counts,
            "recent_log": recent_log,
            "orphans": orphans,
            "inbound_counts": inbound_counts,
        }
    )

    try:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(html_text, encoding="utf-8")
    except OSError as exc:
        fail(f"could not write output: {exc}")
        return

    ok(
        {
            "output": str(output),
            "pages": len(pages),
            "raw": raw_count,
            "links": total_links,
            "tags": len(tag_counts),
            "orphans": len(orphans),
        }
    )


if __name__ == "__main__":
    main()
