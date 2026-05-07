#!/usr/bin/env python3
"""
build_graph.py — two-pass graph layer for cogni-wiki (#221).

Modes (--mode):
  build (default)        Pass 1 (deterministic [[wikilink]] edges) + read Pass-2
                         cache + Label Propagation communities + write HTML.
  enumerate-candidates   List page pairs that need LLM evaluation (shared tags
                         / type / body overlap), filtered by what's already
                         covered by Pass-1 edges and what's already cached.
                         The wiki-dashboard SKILL.md drives the LLM eval loop;
                         scripts never call an LLM directly (mirrors
                         lint_wiki.py's split with its SKILL.md Step 4).
  record-judgement       Atomically write one cache file with the LLM's verdict
                         for a single pair. Re-callable per pair so partial
                         runs persist.

Stdlib only. Self-contained HTML output (no CDN, no external resources). The
inline JS renderer is documented under
`skills/wiki-dashboard/references/graph-renderer.md`.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import html
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"))
from _wikilib import (  # noqa: E402
    atomic_write,
    build_slug_index,
    emit_json,
    fail_if_pre_migration,
    is_audit_slug,
    is_foundation_page,
    iter_pages,
)


WIKILINK_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\]")
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

EDGE_COLORS = {
    "EXTRACTED": "#555555",
    "INFERRED": "#FF5722",
    "AMBIGUOUS": "#BDBDBD",
}

STOPWORDS = frozenset("""
the a an of to and or in on at for with from by as is are was were be been being
this that these those it its their there here have has had do does did not no
but if then so than such which who whom whose what when where why how all any
each few more most other some only own same can will just should now also into
about above below over under between through during after before because while
i you we they me him her us them my your our his she he page concept entity
type tag tags title sources created updated wiki notes summary decision
interview meeting learning synthesis note
""".split())

TOKEN_RE = re.compile(r"[a-z][a-z0-9\-]+")


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


def page_body(text: str) -> str:
    m = FRONTMATTER_RE.match(text)
    return text[m.end():] if m else text


def tokenise(body: str) -> set:
    """Lowercase token bag, stop-word filtered, dedup."""
    return {t for t in TOKEN_RE.findall(body.lower()) if t not in STOPWORDS and len(t) >= 4}


def page_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def pair_id(slug_a: str, slug_b: str) -> str:
    """Deterministic pair identifier — sha256 of sorted-slug pair."""
    a, b = sorted([slug_a, slug_b])
    return hashlib.sha256(f"{a}|{b}".encode("utf-8")).hexdigest()


def jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0
    inter = len(a & b)
    union = len(a | b)
    return inter / union if union else 0.0


def collect_pages(wiki_root: Path) -> list:
    """Return [{slug, path, ptype, title, tags, body, body_tokens, fm, text, content_hash, foundation, audit}].

    Audit slugs (lint-/health-) are surfaced with audit=True so callers can
    skip them from edges and Pass-2 candidates without re-deriving the rule.
    """
    pages = []
    for slug, path, ptype in iter_pages(wiki_root):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        title = fm.get("title", slug) if isinstance(fm.get("title", slug), str) else slug
        tags_raw = fm.get("tags", [])
        tags = [t for t in tags_raw if isinstance(t, str)] if isinstance(tags_raw, list) else []
        body = page_body(text)
        pages.append({
            "slug": slug,
            "path": path,
            "ptype": fm.get("type", ptype) if isinstance(fm.get("type", ptype), str) else ptype,
            "title": title,
            "tags": set(tags),
            "tags_list": tags,
            "body": body,
            "body_tokens": tokenise(body),
            "fm": fm,
            "text": text,
            "content_hash": page_hash(text),
            "foundation": is_foundation_page(fm),
            "audit": is_audit_slug(slug),
        })
    return pages


def build_pass1_edges(pages: list) -> list:
    """Pass 1 — every [[slug]] target that resolves to an existing page becomes
    one EXTRACTED edge. Self-loops and dangling targets dropped.

    Output is deterministic (sorted by (src, tgt))."""
    slugs = {p["slug"] for p in pages if not p["audit"]}
    seen = set()
    edges = []
    for p in pages:
        if p["audit"]:
            continue
        for target in WIKILINK_RE.findall(p["text"]):
            if target == p["slug"] or target not in slugs:
                continue
            key = (p["slug"], target)
            if key in seen:
                continue
            seen.add(key)
            edges.append({
                "from": p["slug"],
                "to": target,
                "type": "EXTRACTED",
                "confidence": 1.0,
                "relationship": "",
            })
    edges.sort(key=lambda e: (e["from"], e["to"]))
    return edges


def cache_path(wiki_root: Path, slug_a: str, slug_b: str) -> Path:
    return wiki_root / ".cogni-wiki" / "graph-cache" / f"{pair_id(slug_a, slug_b)}.json"


def read_cache_entry(p: Path) -> dict:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def cache_hit(entry: dict, page_a_hash: str, page_b_hash: str, model_id: str) -> bool:
    """Hit only when both page hashes AND model_id match; otherwise the cached
    judgement is stale (page edited or model rotated)."""
    if not entry:
        return False
    a, b = sorted([page_a_hash, page_b_hash])
    cached_a, cached_b = sorted([entry.get("page_a_hash", ""), entry.get("page_b_hash", "")])
    return cached_a == a and cached_b == b and entry.get("model_id", "") == model_id


def build_pass2_edges(pages: list, wiki_root: Path, model_id: str) -> list:
    """Read every cache entry that's a fresh hit and translate to edges.

    INFERRED if confidence >= 0.7, else AMBIGUOUS. `unrelated` cache entries
    don't produce edges. Stale entries (page hash mismatch / model mismatch)
    are silently ignored — they stay on disk so re-running with the original
    model is still a no-op."""
    by_slug = {p["slug"]: p for p in pages}
    cache_dir = wiki_root / ".cogni-wiki" / "graph-cache"
    if not cache_dir.is_dir():
        return []
    edges = []
    for cache_file in sorted(cache_dir.glob("*.json")):
        entry = read_cache_entry(cache_file)
        slug_a = entry.get("slug_a")
        slug_b = entry.get("slug_b")
        if not slug_a or not slug_b:
            continue
        if slug_a not in by_slug or slug_b not in by_slug:
            continue
        if not cache_hit(entry, by_slug[slug_a]["content_hash"], by_slug[slug_b]["content_hash"], model_id):
            continue
        if entry.get("judgement") != "related":
            continue
        confidence = float(entry.get("confidence", 0.0) or 0.0)
        edge_type = "INFERRED" if confidence >= 0.7 else "AMBIGUOUS"
        edges.append({
            "from": slug_a,
            "to": slug_b,
            "type": edge_type,
            "confidence": confidence,
            "relationship": entry.get("relationship", "") or "",
        })
    edges.sort(key=lambda e: (e["from"], e["to"]))
    return edges


def label_propagation(node_ids: list, adj: dict, max_iter: int = 30) -> dict:
    """Deterministic Label Propagation Algorithm — simpler than Louvain (~60 LOC),
    seeded by sorted-slug initialisation, lower-id-wins tie-break.

    Sufficient for colour clustering on 100–1000-page wikis. Faithful Louvain
    can replace this in a follow-up PR if community-quality ever matters more
    than render speed (see references/graph-renderer.md §"Communities").
    """
    sorted_ids = sorted(node_ids)
    labels = {n: i for i, n in enumerate(sorted_ids)}
    for _ in range(max_iter):
        changed = False
        for n in sorted_ids:
            neighbour_labels = Counter(labels[m] for m in adj.get(n, ()) if m in labels)
            if not neighbour_labels:
                continue
            best = max(neighbour_labels.items(), key=lambda kv: (kv[1], -kv[0]))[0]
            if labels[n] != best:
                labels[n] = best
                changed = True
        if not changed:
            break
    # Compact community ids to 0..K-1 in deterministic order.
    remap = {}
    next_id = 0
    out = {}
    for n in sorted_ids:
        lab = labels[n]
        if lab not in remap:
            remap[lab] = next_id
            next_id += 1
        out[n] = remap[lab]
    return out


def hsl_palette(n: int) -> list:
    """Generate `n` perceptually-spaced HSL colours via golden-ratio hue stepping."""
    if n <= 0:
        return []
    golden = 0.61803398875
    out = []
    h = 0.137
    for _ in range(n):
        out.append(f"hsl({int(h * 360)}, 65%, 55%)")
        h = (h + golden) % 1.0
    return out


def preview(body: str, n: int = 220) -> str:
    s = " ".join(body.split())
    return s[:n] + ("…" if len(s) > n else "")


def build_graph_data(pages: list, edges: list) -> dict:
    """Assemble the inline graph data: per-node {id,label,type,tags,preview,
    community,degree}; per-edge {from,to,type,relationship,confidence}.

    Drops audit slugs. Foundation pages stay as nodes (they're domain knowledge),
    but Pass-2 enumeration skips foundation×foundation pairs separately.
    """
    visible = [p for p in pages if not p["audit"]]
    node_ids = [p["slug"] for p in visible]
    edges_visible = [e for e in edges if e["from"] in node_ids and e["to"] in node_ids]
    adj = defaultdict(set)
    for e in edges_visible:
        adj[e["from"]].add(e["to"])
        adj[e["to"]].add(e["from"])
    communities = label_propagation(node_ids, adj)
    palette = hsl_palette(max(1, len(set(communities.values()))))

    nodes = []
    for p in sorted(visible, key=lambda x: x["slug"]):
        comm = communities.get(p["slug"], 0)
        nodes.append({
            "id": p["slug"],
            "label": p["title"],
            "type": p["ptype"],
            "tags": sorted(p["tags_list"]),
            "preview": preview(p["body"]),
            "community": comm,
            "color": palette[comm % len(palette)],
            "foundation": p["foundation"],
            "degree": len(adj.get(p["slug"], ())),
        })

    edge_data = []
    for e in edges_visible:
        edge_data.append({
            "from": e["from"],
            "to": e["to"],
            "type": e["type"],
            "color": EDGE_COLORS.get(e["type"], "#999"),
            "confidence": round(float(e.get("confidence", 1.0)), 3),
            "relationship": e.get("relationship", ""),
        })

    return {
        "nodes": nodes,
        "edges": edge_data,
        "community_count": len(set(communities.values())),
    }


# ---------------------------------------------------------------------------
# HTML renderer — vanilla canvas, self-contained, zero external resources.
# Documented in skills/wiki-dashboard/references/graph-renderer.md.
# ---------------------------------------------------------------------------

STYLE = """
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, sans-serif;
       background: #0f1115; color: #e6e8eb; overflow: hidden; }
#header { position: fixed; top: 0; left: 0; right: 0; padding: 10px 16px;
          background: rgba(15,17,21,0.92); border-bottom: 1px solid #20242c;
          display: flex; gap: 12px; align-items: center; z-index: 10; }
#header h1 { font-size: 14px; margin: 0; font-weight: 600; letter-spacing: 0.02em; }
#header .meta { color: #8a93a3; font-size: 12px; }
#search { padding: 5px 9px; border-radius: 6px; border: 1px solid #2a2f3a;
          background: #181c25; color: #e6e8eb; font-size: 13px; width: 220px; }
#search:focus { outline: none; border-color: #4a90e2; }
#legend { display: flex; gap: 10px; font-size: 11px; color: #8a93a3; }
.legend-item { display: flex; align-items: center; gap: 4px; }
.legend-swatch { width: 14px; height: 3px; border-radius: 1px; }
#canvas { position: fixed; top: 44px; left: 0; right: 0; bottom: 0; cursor: grab; }
#canvas:active { cursor: grabbing; }
#panel { position: fixed; top: 44px; right: 0; bottom: 0; width: 340px;
         background: #181c25; border-left: 1px solid #20242c; padding: 18px;
         overflow-y: auto; transform: translateX(100%); transition: transform 0.18s ease; z-index: 9; }
#panel.open { transform: translateX(0); }
#panel h2 { margin: 0 0 4px; font-size: 16px; }
#panel .ptype { display: inline-block; font-size: 10px; text-transform: uppercase;
                background: #2a2f3a; color: #c9d1d9; padding: 2px 7px; border-radius: 3px;
                margin-bottom: 10px; }
#panel .tags { display: flex; flex-wrap: wrap; gap: 5px; margin-bottom: 12px; }
#panel .tag { font-size: 11px; background: #2a2f3a; color: #aab2bf;
              padding: 2px 7px; border-radius: 999px; }
#panel .preview { font-size: 13px; color: #c9d1d9; line-height: 1.5; margin-bottom: 14px; }
#panel h3 { font-size: 11px; text-transform: uppercase; color: #8a93a3;
            margin: 14px 0 6px; letter-spacing: 0.05em; }
#panel ul { margin: 0; padding-left: 18px; font-size: 13px; }
#panel li { margin: 3px 0; }
#panel li button { background: none; border: none; color: #79b0ff;
                   cursor: pointer; padding: 0; font: inherit; text-align: left; }
#panel li button:hover { text-decoration: underline; }
#panel .relationship { color: #8a93a3; font-size: 11px; }
#panel .close { position: absolute; top: 12px; right: 12px; background: none;
                border: none; color: #8a93a3; font-size: 20px; cursor: pointer; }
#stats { position: fixed; bottom: 10px; left: 10px; font-size: 11px;
         color: #8a93a3; background: rgba(15,17,21,0.85); padding: 5px 9px;
         border-radius: 4px; }
footer { position: fixed; bottom: 10px; right: 10px; font-size: 10px; color: #4a5160; }
"""


def render_html(graph_data: dict, config: dict, stats: dict) -> str:
    """Self-contained HTML — inline CSS + inline canvas-renderer JS + inline data.

    The data shape kept lean intentionally: full markdown is NOT inlined per
    node (would balloon a 200-page wiki to 5–10 MB). 220-char preview only;
    the user opens the source page from the dashboard if they want more.
    """
    generated_at = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    data_json = json.dumps(graph_data, ensure_ascii=False, separators=(",", ":"))
    cfg_safe = {
        "name": config.get("name", "cogni-wiki"),
        "slug": config.get("slug", ""),
    }
    edge_legend = (
        f'<span class="legend-item"><span class="legend-swatch" style="background:{EDGE_COLORS["EXTRACTED"]}"></span>extracted</span>'
        f'<span class="legend-item"><span class="legend-swatch" style="background:{EDGE_COLORS["INFERRED"]}"></span>inferred</span>'
        f'<span class="legend-item"><span class="legend-swatch" style="background:{EDGE_COLORS["AMBIGUOUS"]}"></span>ambiguous</span>'
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wiki Graph — {html.escape(cfg_safe["name"])}</title>
<style>{STYLE}</style>
</head>
<body>
<div id="header">
  <h1>{html.escape(cfg_safe["name"])} <span class="meta">/ {html.escape(cfg_safe["slug"])}</span></h1>
  <input id="search" type="text" placeholder="search nodes…" autocomplete="off">
  <div id="legend">{edge_legend}</div>
</div>
<canvas id="canvas"></canvas>
<div id="panel">
  <button class="close" type="button" onclick="closePanel()">&times;</button>
  <div id="panel-body"></div>
</div>
<div id="stats">{stats["nodes"]} nodes · {stats["edges_pass1"]} extracted · {stats["edges_pass2"]} inferred · {stats["communities"]} communities</div>
<footer>Generated by cogni-wiki v0.0.34 · {generated_at}</footer>
<script>
const GRAPH = {data_json};
{INLINE_JS}
</script>
</body>
</html>
"""


# Inline force-directed canvas renderer. Self-contained: no external libs.
# Verlet-style integration with Coulomb-like repulsion and Hooke spring on edges.
INLINE_JS = r"""
(function () {
  const canvas = document.getElementById('canvas');
  const ctx = canvas.getContext('2d');
  const search = document.getElementById('search');
  const panel = document.getElementById('panel');
  const panelBody = document.getElementById('panel-body');

  const nodes = GRAPH.nodes.map(n => ({
    ...n,
    x: 0, y: 0, vx: 0, vy: 0,
    visible: true,
  }));
  const edges = GRAPH.edges;
  const idx = new Map(nodes.map((n, i) => [n.id, i]));

  // Initial layout — concentric rings by community for cleaner cold start.
  const W = window.innerWidth;
  const H = window.innerHeight - 44;
  const byCom = new Map();
  for (const n of nodes) {
    if (!byCom.has(n.community)) byCom.set(n.community, []);
    byCom.get(n.community).push(n);
  }
  let comIdx = 0;
  const totalCom = byCom.size;
  for (const [com, group] of byCom) {
    const cx = W / 2 + Math.cos((comIdx / totalCom) * Math.PI * 2) * Math.min(W, H) * 0.25;
    const cy = H / 2 + Math.sin((comIdx / totalCom) * Math.PI * 2) * Math.min(W, H) * 0.25;
    for (let i = 0; i < group.length; i++) {
      const t = (i / Math.max(1, group.length)) * Math.PI * 2;
      const r = 30 + 8 * Math.sqrt(group.length);
      group[i].x = cx + Math.cos(t) * r + (Math.random() - 0.5) * 4;
      group[i].y = cy + Math.sin(t) * r + (Math.random() - 0.5) * 4;
    }
    comIdx++;
  }

  // Adjacency for highlight + neighbours panel.
  const neighbours = new Map(nodes.map(n => [n.id, []]));
  for (const e of edges) {
    if (neighbours.has(e.from)) neighbours.get(e.from).push({ id: e.to, type: e.type, relationship: e.relationship, dir: 'out' });
    if (neighbours.has(e.to)) neighbours.get(e.to).push({ id: e.from, type: e.type, relationship: e.relationship, dir: 'in' });
  }

  // Pan + zoom.
  let zoom = 1, panX = 0, panY = 0;
  let dragging = null, dragOffsetX = 0, dragOffsetY = 0;
  let panning = false, panStartX = 0, panStartY = 0;
  let selected = null;

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight - 44;
  }
  resize();
  window.addEventListener('resize', resize);

  function worldToScreen(x, y) { return [x * zoom + panX, y * zoom + panY]; }
  function screenToWorld(x, y) { return [(x - panX) / zoom, (y - panY) / zoom]; }

  // Force simulation step.
  function tick() {
    const REPULSE = 1800;
    const SPRING = 0.012;
    const SPRING_LEN = 90;
    const GRAVITY = 0.0008;
    const DAMP = 0.82;
    const cx = canvas.width / 2 / zoom - panX / zoom;
    const cy = canvas.height / 2 / zoom - panY / zoom;
    for (let i = 0; i < nodes.length; i++) {
      const a = nodes[i];
      if (!a.visible) continue;
      let fx = (cx - a.x) * GRAVITY;
      let fy = (cy - a.y) * GRAVITY;
      for (let j = 0; j < nodes.length; j++) {
        if (i === j) continue;
        const b = nodes[j];
        if (!b.visible) continue;
        const dx = a.x - b.x;
        const dy = a.y - b.y;
        const d2 = dx * dx + dy * dy + 1;
        const f = REPULSE / d2;
        fx += dx * f;
        fy += dy * f;
      }
      a.fx = fx; a.fy = fy;
    }
    for (const e of edges) {
      const a = nodes[idx.get(e.from)];
      const b = nodes[idx.get(e.to)];
      if (!a || !b || !a.visible || !b.visible) continue;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const d = Math.sqrt(dx * dx + dy * dy) + 0.01;
      const stretch = (d - SPRING_LEN) * SPRING;
      const fx = (dx / d) * stretch;
      const fy = (dy / d) * stretch;
      a.fx += fx; a.fy += fy;
      b.fx -= fx; b.fy -= fy;
    }
    for (const n of nodes) {
      if (!n.visible || n === dragging) continue;
      n.vx = (n.vx + n.fx) * DAMP;
      n.vy = (n.vy + n.fy) * DAMP;
      n.x += n.vx;
      n.y += n.vy;
    }
  }

  function nodeRadius(n) {
    return 5 + Math.min(14, Math.sqrt(n.degree + 1) * 2.5);
  }

  function draw() {
    ctx.fillStyle = '#0f1115';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    ctx.translate(panX, panY);
    ctx.scale(zoom, zoom);
    // Edges first.
    for (const e of edges) {
      const a = nodes[idx.get(e.from)];
      const b = nodes[idx.get(e.to)];
      if (!a || !b || !a.visible || !b.visible) continue;
      const dim = selected && selected.id !== a.id && selected.id !== b.id;
      ctx.strokeStyle = dim ? '#1f242d' : e.color;
      ctx.lineWidth = dim ? 0.5 : (e.type === 'EXTRACTED' ? 1.0 : 0.7);
      ctx.beginPath();
      ctx.moveTo(a.x, a.y);
      ctx.lineTo(b.x, b.y);
      ctx.stroke();
    }
    // Nodes on top.
    for (const n of nodes) {
      if (!n.visible) continue;
      const r = nodeRadius(n);
      const isSel = selected && selected.id === n.id;
      const dim = selected && !isSel && !(neighbours.get(selected.id) || []).some(x => x.id === n.id);
      ctx.fillStyle = dim ? '#2a2f3a' : n.color;
      ctx.strokeStyle = isSel ? '#fff' : (n.foundation ? '#ffe066' : '#0f1115');
      ctx.lineWidth = isSel ? 2.5 : (n.foundation ? 1.4 : 1);
      ctx.beginPath();
      ctx.arc(n.x, n.y, r, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      if (zoom > 0.6 && (isSel || n.degree >= 2)) {
        ctx.fillStyle = dim ? '#3a4150' : '#e6e8eb';
        ctx.font = '11px -apple-system, sans-serif';
        ctx.fillText(n.label, n.x + r + 3, n.y + 3);
      }
    }
    ctx.restore();
  }

  function loop() {
    tick();
    draw();
    requestAnimationFrame(loop);
  }

  function nodeAt(sx, sy) {
    const [wx, wy] = screenToWorld(sx, sy);
    for (let i = nodes.length - 1; i >= 0; i--) {
      const n = nodes[i];
      if (!n.visible) continue;
      const dx = n.x - wx, dy = n.y - wy;
      if (dx * dx + dy * dy <= (nodeRadius(n) + 2) ** 2) return n;
    }
    return null;
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
  }

  function renderPanel(n) {
    const tagsHtml = n.tags.map(t => `<span class="tag">${escapeHtml(t)}</span>`).join('');
    const out = (neighbours.get(n.id) || []).filter(x => x.dir === 'out');
    const inn = (neighbours.get(n.id) || []).filter(x => x.dir === 'in');
    const fmtNeighbour = x => {
      const target = nodes[idx.get(x.id)];
      const lbl = target ? target.label : x.id;
      const rel = x.relationship ? ` <span class="relationship">— ${escapeHtml(x.relationship)}</span>` : '';
      return `<li><button onclick="selectById('${escapeHtml(x.id).replace(/'/g, "&#39;")}')">${escapeHtml(lbl)}</button> <span class="relationship">[${x.type.toLowerCase()}]</span>${rel}</li>`;
    };
    panelBody.innerHTML = `
      <h2>${escapeHtml(n.label)}</h2>
      <span class="ptype">${escapeHtml(n.type || '?')}</span>
      ${tagsHtml ? `<div class="tags">${tagsHtml}</div>` : ''}
      <div class="preview">${escapeHtml(n.preview || '(no preview)')}</div>
      ${out.length ? `<h3>Outbound (${out.length})</h3><ul>${out.map(fmtNeighbour).join('')}</ul>` : ''}
      ${inn.length ? `<h3>Inbound (${inn.length})</h3><ul>${inn.map(fmtNeighbour).join('')}</ul>` : ''}
      ${!out.length && !inn.length ? `<div class="relationship">No connections.</div>` : ''}
    `;
    panel.classList.add('open');
  }

  function selectNode(n) {
    selected = n;
    if (n) renderPanel(n);
  }

  window.selectById = function (id) {
    const n = nodes[idx.get(id)];
    if (n) selectNode(n);
  };
  window.closePanel = function () {
    panel.classList.remove('open');
    selected = null;
  };

  canvas.addEventListener('mousedown', (ev) => {
    const n = nodeAt(ev.clientX, ev.clientY - 44);
    if (n) {
      dragging = n;
      const [wx, wy] = screenToWorld(ev.clientX, ev.clientY - 44);
      dragOffsetX = wx - n.x;
      dragOffsetY = wy - n.y;
    } else {
      panning = true;
      panStartX = ev.clientX - panX;
      panStartY = ev.clientY - panY;
    }
  });
  canvas.addEventListener('mousemove', (ev) => {
    if (dragging) {
      const [wx, wy] = screenToWorld(ev.clientX, ev.clientY - 44);
      dragging.x = wx - dragOffsetX;
      dragging.y = wy - dragOffsetY;
      dragging.vx = 0; dragging.vy = 0;
    } else if (panning) {
      panX = ev.clientX - panStartX;
      panY = ev.clientY - panStartY;
    }
  });
  canvas.addEventListener('mouseup', (ev) => {
    if (dragging) {
      // If barely moved → treat as click.
      if (Math.abs(dragging.vx) < 0.5 && Math.abs(dragging.vy) < 0.5) {
        selectNode(dragging);
      }
    } else if (panning) {
      const moved = Math.abs(ev.clientX - panX - panStartX) + Math.abs(ev.clientY - panY - panStartY);
      if (moved < 3) {
        // Background click.
        closePanel();
      }
    }
    dragging = null;
    panning = false;
  });
  canvas.addEventListener('wheel', (ev) => {
    ev.preventDefault();
    const factor = ev.deltaY < 0 ? 1.12 : 1 / 1.12;
    const [wx, wy] = screenToWorld(ev.clientX, ev.clientY - 44);
    zoom = Math.max(0.2, Math.min(4, zoom * factor));
    const [sx, sy] = worldToScreen(wx, wy);
    panX += ev.clientX - sx;
    panY += (ev.clientY - 44) - sy;
  }, { passive: false });

  search.addEventListener('input', () => {
    const q = search.value.trim().toLowerCase();
    if (!q) {
      for (const n of nodes) n.visible = true;
      return;
    }
    const matched = new Set();
    for (const n of nodes) {
      if (n.id.toLowerCase().includes(q) || n.label.toLowerCase().includes(q) ||
          n.tags.some(t => t.toLowerCase().includes(q))) {
        matched.add(n.id);
      }
    }
    // Include direct neighbours so the matched subgraph stays connected on screen.
    const expanded = new Set(matched);
    for (const id of matched) for (const x of (neighbours.get(id) || [])) expanded.add(x.id);
    for (const n of nodes) n.visible = expanded.has(n.id);
  });

  loop();
})();
"""


def cmd_build(args, wiki_root: Path, config: dict) -> None:
    pages = collect_pages(wiki_root)
    edges_pass1 = build_pass1_edges(pages)
    edges_pass2 = build_pass2_edges(pages, wiki_root, args.model)
    all_edges = edges_pass1 + edges_pass2
    graph_data = build_graph_data(pages, all_edges)
    stats = {
        "nodes": len(graph_data["nodes"]),
        "edges_pass1": len(edges_pass1),
        "edges_pass2": len(edges_pass2),
        "communities": graph_data["community_count"],
    }
    output = Path(args.output).expanduser().resolve() if args.output else wiki_root / "wiki-graph.html"
    html_text = render_html(graph_data, config, stats)
    try:
        atomic_write(output, html_text)
    except OSError as exc:
        emit_json(False, error=f"could not write output: {exc}")
        sys.exit(1)
    emit_json(True, data={
        "output": str(output),
        "nodes": stats["nodes"],
        "edges_pass1": stats["edges_pass1"],
        "edges_pass2": stats["edges_pass2"],
        "communities": stats["communities"],
    })


def cmd_enumerate(args, wiki_root: Path, config: dict) -> None:
    pages = collect_pages(wiki_root)
    edges_pass1 = build_pass1_edges(pages)
    pass1_pairs = {tuple(sorted([e["from"], e["to"]])) for e in edges_pass1}
    by_slug = {p["slug"]: p for p in pages if not p["audit"]}
    slugs = sorted(by_slug.keys())
    candidates = []
    for i in range(len(slugs)):
        for j in range(i + 1, len(slugs)):
            a = by_slug[slugs[i]]
            b = by_slug[slugs[j]]
            key = (slugs[i], slugs[j])
            if key in pass1_pairs:
                continue
            if a["foundation"] and b["foundation"]:
                continue
            shared = len(a["tags"] & b["tags"])
            same_type = a["ptype"] == b["ptype"]
            overlap = jaccard(a["body_tokens"], b["body_tokens"])
            include = (
                shared >= 1
                or (same_type and overlap >= 0.20)
                or overlap >= 0.35
            )
            if not include:
                continue
            cpath = cache_path(wiki_root, a["slug"], b["slug"])
            if cpath.is_file():
                entry = read_cache_entry(cpath)
                if cache_hit(entry, a["content_hash"], b["content_hash"], args.model):
                    continue
            pid = pair_id(a["slug"], b["slug"])
            candidates.append({
                "pair_id": pid,
                "slug_a": a["slug"],
                "slug_b": b["slug"],
                "shared_tags": shared,
                "same_type": same_type,
                "body_overlap": round(overlap, 3),
                "page_a_preview": preview(a["body"]),
                "page_b_preview": preview(b["body"]),
            })
    # Deterministic order: sort by pair_id (stable across runs and resumable).
    candidates.sort(key=lambda c: c["pair_id"])
    if args.limit and args.limit > 0:
        candidates = candidates[: args.limit]
    emit_json(True, data={
        "candidates": candidates,
        "count": len(candidates),
        "model_id": args.model,
    })


def cmd_record(args, wiki_root: Path, config: dict) -> None:
    if not args.pair_id or not args.slug_a or not args.slug_b:
        emit_json(False, error="record-judgement requires --pair-id, --slug-a, --slug-b")
        sys.exit(1)
    if args.judgement not in {"related", "unrelated"}:
        emit_json(False, error="--judgement must be 'related' or 'unrelated'")
        sys.exit(1)
    expected = pair_id(args.slug_a, args.slug_b)
    if expected != args.pair_id:
        emit_json(False, error=f"pair_id mismatch: expected {expected} for ({args.slug_a},{args.slug_b})")
        sys.exit(1)
    pages = collect_pages(wiki_root)
    by_slug = {p["slug"]: p for p in pages}
    if args.slug_a not in by_slug or args.slug_b not in by_slug:
        emit_json(False, error="one or both slugs do not exist in the wiki")
        sys.exit(1)
    a, b = sorted([args.slug_a, args.slug_b])
    pa_hash = by_slug[a]["content_hash"]
    pb_hash = by_slug[b]["content_hash"]
    entry = {
        "pair_id": args.pair_id,
        "slug_a": a,
        "slug_b": b,
        "page_a_hash": pa_hash,
        "page_b_hash": pb_hash,
        "model_id": args.model,
        "judgement": args.judgement,
        "confidence": float(args.confidence),
        "relationship": args.relationship or "",
        "evaluated_at": dt.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    }
    cpath = cache_path(wiki_root, args.slug_a, args.slug_b)
    try:
        atomic_write(cpath, json.dumps(entry, ensure_ascii=False, indent=2) + "\n")
    except OSError as exc:
        emit_json(False, error=f"could not write cache entry: {exc}")
        sys.exit(1)
    emit_json(True, data={"cache_path": str(cpath), "judgement": args.judgement})


def main() -> None:
    parser = argparse.ArgumentParser(description="Two-pass graph layer for cogni-wiki (#221)")
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument("--mode", choices=["build", "enumerate-candidates", "record-judgement"], default="build")
    parser.add_argument("--output", default=None, help="Override HTML output path (build mode)")
    parser.add_argument("--model", default="sonnet", help="Model id for cache key (default: sonnet)")
    parser.add_argument("--limit", type=int, default=50, help="Max candidates to emit (enumerate mode)")
    parser.add_argument("--pair-id", default=None, help="Pair sha256 identifier (record mode)")
    parser.add_argument("--slug-a", default=None)
    parser.add_argument("--slug-b", default=None)
    parser.add_argument("--judgement", default="related", choices=["related", "unrelated"])
    parser.add_argument("--confidence", type=float, default=0.0)
    parser.add_argument("--relationship", default="")
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    config_path = wiki_root / ".cogni-wiki" / "config.json"
    if not config_path.is_file():
        emit_json(False, error=f"not a cogni-wiki: {config_path} missing")
        sys.exit(1)
    fail_if_pre_migration(wiki_root)
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        emit_json(False, error=f"config.json unreadable: {exc}")
        sys.exit(1)

    if args.mode == "build":
        cmd_build(args, wiki_root, config)
    elif args.mode == "enumerate-candidates":
        cmd_enumerate(args, wiki_root, config)
    elif args.mode == "record-judgement":
        cmd_record(args, wiki_root, config)


if __name__ == "__main__":
    main()
