#!/usr/bin/env python3
"""Generate a self-contained themed HTML infographic from parsed block data.

Usage:
    python3 generate-infographic.py \
        --infographic-data <infographic-data.json> \
        --design-variables <design-variables.json> \
        --svg-dir <svg-directory/> \
        --output <output.html> \
        --language <en|de>

Input:  infographic-data.json (parsed from infographic-brief.md by LLM)
Output: Self-contained HTML file with themed infographic.
Returns JSON: {"status": "ok", "path": "<output-path>", "blocks": N, "size_kb": N.N}
           or {"error": "..."}
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime


# ---------------------------------------------------------------------------
# Theme / Design Variables
# ---------------------------------------------------------------------------

DEFAULT_THEME = {
    "theme_name": "cogni-work",
    "colors": {
        "primary": "#111111", "secondary": "#333333",
        "accent": "#C8E62E", "accent_muted": "#A8C424", "accent_dark": "#8BA31E",
        "background": "#FAFAF8", "surface": "#F2F2EE", "surface2": "#E8E8E4",
        "surface_dark": "#111111", "border": "#E0E0DC",
        "text": "#111111", "text_light": "#FFFFFF", "text_muted": "#6B7280",
    },
    "status": {
        "success": "#2E7D32", "warning": "#E5A100",
        "danger": "#D32F2F", "info": "#1565C0",
    },
    "fonts": {
        "headers": "'Bricolage Grotesque', -apple-system, sans-serif",
        "body": "'Outfit', -apple-system, sans-serif",
        "mono": "'JetBrains Mono', monospace",
    },
    "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&family=Outfit:wght@300;400;500;600;700&display=swap');",
    "radius": "12px",
    "shadows": {
        "sm": "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)",
        "md": "0 4px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
        "lg": "0 12px 40px rgba(0,0,0,0.1), 0 4px 12px rgba(0,0,0,0.05)",
        "xl": "0 24px 64px rgba(0,0,0,0.14), 0 8px 20px rgba(0,0,0,0.06)",
    },
}


def load_design_variables(path):
    """Load design-variables.json, falling back to DEFAULT_THEME."""
    if not path or not os.path.isfile(path):
        return DEFAULT_THEME.copy()
    with open(path) as f:
        dv = json.load(f)
    result = DEFAULT_THEME.copy()
    for section in ("colors", "status", "fonts", "shadows"):
        if section in dv:
            result[section] = {**result.get(section, {}), **dv[section]}
    for key in ("theme_name", "google_fonts_import", "radius"):
        if key in dv:
            result[key] = dv[key]
    return result


# ---------------------------------------------------------------------------
# HTML Utilities
# ---------------------------------------------------------------------------

def escape_html(text):
    """Escape HTML special characters."""
    if not text:
        return ""
    return (str(text)
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;'))


def load_svg_icon(svg_dir, block_index):
    """Load an SVG icon file for a block if it exists."""
    if not svg_dir:
        return ""
    path = os.path.join(svg_dir, f"icon-{block_index}.svg")
    if os.path.isfile(path):
        with open(path) as f:
            return f.read().strip()
    return ""


# ---------------------------------------------------------------------------
# Block Renderers
# ---------------------------------------------------------------------------

def render_title(block, _dv):
    """Render the title block."""
    f = block.get("fields", {})
    headline = escape_html(f.get("Headline", ""))
    subline = escape_html(f.get("Subline", ""))
    metadata = escape_html(f.get("Metadata", ""))
    parts = [f'  <header class="ig-title">']
    parts.append(f'    <h1 class="ig-headline">{headline}</h1>')
    if subline:
        parts.append(f'    <p class="ig-subline">{subline}</p>')
    if metadata:
        parts.append(f'    <p class="ig-metadata">{metadata}</p>')
    parts.append('  </header>')
    return "\n".join(parts)


def render_kpi_card(block, _dv, svg=""):
    """Render a KPI card block."""
    f = block.get("fields", {})
    number = escape_html(f.get("Hero-Number", ""))
    label = escape_html(f.get("Hero-Label", ""))
    sublabel = escape_html(f.get("Sublabel", ""))
    source = escape_html(f.get("Source", ""))
    parts = ['    <div class="ig-block ig-kpi-card">']
    if svg:
        parts.append(f'      <div class="ig-kpi-icon">{svg}</div>')
    parts.append(f'      <div class="ig-kpi-number">{number}</div>')
    parts.append(f'      <div class="ig-kpi-label">{label}</div>')
    if sublabel:
        parts.append(f'      <div class="ig-kpi-sublabel">{sublabel}</div>')
    if source:
        parts.append(f'      <div class="ig-kpi-source">{source}</div>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_stat_row(block, _dv, svg_dir="", block_index=0):
    """Render a stat row block."""
    f = block.get("fields", {})
    stats = f.get("Stats", [])
    parts = ['    <div class="ig-block ig-stat-row">']
    for i, stat in enumerate(stats):
        svg = load_svg_icon(svg_dir, f"{block_index}-{i}") if svg_dir else ""
        number = escape_html(stat.get("number", ""))
        label = escape_html(stat.get("label", ""))
        parts.append(f'      <div class="ig-stat">')
        if svg:
            parts.append(f'        <div class="ig-stat-icon">{svg}</div>')
        parts.append(f'        <div class="ig-stat-number">{number}</div>')
        parts.append(f'        <div class="ig-stat-label">{label}</div>')
        parts.append('      </div>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_chart(block, dv, chart_index=0):
    """Render a Chart.js block. Returns (html, script)."""
    f = block.get("fields", {})
    chart_type = f.get("Chart-Type", "bar")
    chart_title = escape_html(f.get("Chart-Title", ""))
    data = f.get("Data", {})
    labels = data.get("labels", [])
    datasets = data.get("datasets", [])

    canvas_id = f"ig-chart-{chart_index}"
    colors = dv.get("colors", {})
    accent = colors.get("accent", "#C8E62E")
    accent_muted = colors.get("accent_muted", "#A8C424")
    accent_dark = colors.get("accent_dark", "#8BA31E")
    text_muted = colors.get("text_muted", "#6B7280")
    border_color = colors.get("border", "#E0E0DC")

    palette = [accent, accent_dark, accent_muted,
               colors.get("secondary", "#333"),
               colors.get("primary", "#111")]

    chart_datasets = []
    for i, ds in enumerate(datasets):
        color = palette[i % len(palette)]
        chart_datasets.append({
            "label": ds.get("label", ""),
            "data": ds.get("values", []),
            "backgroundColor": color if chart_type in ("bar", "doughnut", "stacked-bar") else "transparent",
            "borderColor": color,
            "borderWidth": 2,
        })
        if chart_type == "doughnut":
            chart_datasets[-1]["backgroundColor"] = [palette[j % len(palette)] for j in range(len(ds.get("values", [])))]

    ct = "bar" if chart_type == "stacked-bar" else chart_type
    config = {
        "type": ct,
        "data": {"labels": labels, "datasets": chart_datasets},
        "options": {
            "responsive": True,
            "maintainAspectRatio": True,
            "plugins": {
                "legend": {"display": len(datasets) > 1, "labels": {"color": text_muted}},
                "title": {"display": False},
            },
            "scales": {} if chart_type == "doughnut" else {
                "x": {"grid": {"color": border_color}, "ticks": {"color": text_muted}},
                "y": {"grid": {"color": border_color}, "ticks": {"color": text_muted}},
            },
        },
    }

    if chart_type == "stacked-bar":
        config["options"]["scales"]["x"]["stacked"] = True
        config["options"]["scales"]["y"]["stacked"] = True

    html = f"""    <div class="ig-block ig-chart">
      <h3 class="ig-chart-title">{chart_title}</h3>
      <canvas id="{canvas_id}" width="600" height="300"></canvas>
    </div>"""

    script = f"new Chart(document.getElementById('{canvas_id}'), {json.dumps(config, ensure_ascii=False)});"
    return html, script


def render_process_strip(block, _dv, svg_dir="", block_index=0):
    """Render a process strip block."""
    f = block.get("fields", {})
    steps = f.get("Steps", [])
    parts = ['    <div class="ig-block ig-process-strip">']
    for i, step in enumerate(steps):
        svg = load_svg_icon(svg_dir, f"{block_index}-{i}") if svg_dir else ""
        label = escape_html(step.get("label", ""))
        parts.append(f'      <div class="ig-step">')
        if svg:
            parts.append(f'        <div class="ig-step-icon">{svg}</div>')
        parts.append(f'        <div class="ig-step-label">{label}</div>')
        parts.append('      </div>')
        if i < len(steps) - 1:
            parts.append('      <div class="ig-step-connector">&rarr;</div>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_text_block(block, _dv, svg=""):
    """Render a text block."""
    f = block.get("fields", {})
    headline = escape_html(f.get("Headline", ""))
    body = escape_html(f.get("Body", ""))
    parts = ['    <div class="ig-block ig-text-block">']
    if svg:
        parts.append(f'      <div class="ig-text-icon">{svg}</div>')
    if headline:
        parts.append(f'      <h3 class="ig-text-headline">{headline}</h3>')
    if body:
        parts.append(f'      <p class="ig-text-body">{body}</p>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_comparison_pair(block, _dv, svg_dir="", block_index=0):
    """Render a comparison pair block."""
    f = block.get("fields", {})

    def render_side(side_data, side_class, side_idx):
        label = escape_html(side_data.get("label", ""))
        bullets = side_data.get("bullets", [])
        svg = load_svg_icon(svg_dir, f"{block_index}-{side_idx}") if svg_dir else ""
        parts = [f'      <div class="ig-comparison-side {side_class}">']
        if svg:
            parts.append(f'        <div class="ig-comparison-icon">{svg}</div>')
        parts.append(f'        <h3 class="ig-comparison-label">{label}</h3>')
        if bullets:
            items = "\n".join(f"          <li>{escape_html(b)}</li>" for b in bullets)
            parts.append(f'        <ul class="ig-comparison-bullets">\n{items}\n        </ul>')
        parts.append('      </div>')
        return "\n".join(parts)

    left = f.get("Left", {})
    right = f.get("Right", {})
    html = ['    <div class="ig-block ig-comparison">']
    html.append(render_side(left, "ig-comparison-left", "left"))
    html.append('      <div class="ig-comparison-divider"></div>')
    html.append(render_side(right, "ig-comparison-right", "right"))
    html.append('    </div>')
    return "\n".join(html)


def render_icon_grid(block, _dv, svg_dir="", block_index=0):
    """Render an icon grid block."""
    f = block.get("fields", {})
    columns = f.get("Columns", 2)
    items = f.get("Items", [])
    parts = [f'    <div class="ig-block ig-icon-grid" style="--grid-cols: {columns}">']
    for i, item in enumerate(items):
        svg = load_svg_icon(svg_dir, f"{block_index}-{i}") if svg_dir else ""
        label = escape_html(item.get("label", ""))
        sublabel = escape_html(item.get("sublabel", ""))
        parts.append('      <div class="ig-grid-item">')
        if svg:
            parts.append(f'        <div class="ig-grid-icon">{svg}</div>')
        parts.append(f'        <div class="ig-grid-label">{label}</div>')
        if sublabel:
            parts.append(f'        <div class="ig-grid-sublabel">{sublabel}</div>')
        parts.append('      </div>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_svg_diagram(block, _dv, svg=""):
    """Render an SVG diagram block (the SVG content comes from the agent)."""
    parts = ['    <div class="ig-block ig-svg-diagram">']
    if svg:
        parts.append(f'      {svg}')
    else:
        parts.append('      <p class="ig-placeholder">[SVG diagram placeholder]</p>')
    parts.append('    </div>')
    return "\n".join(parts)


def render_cta(block, _dv):
    """Render the CTA block."""
    f = block.get("fields", {})
    headline = escape_html(f.get("Headline", ""))
    cta_text = escape_html(f.get("CTA-Text", ""))
    urgency = f.get("CTA-Urgency", "medium")
    parts = [f'  <div class="ig-cta" data-urgency="{urgency}">']
    parts.append(f'    <h2 class="ig-cta-headline">{headline}</h2>')
    if cta_text:
        parts.append(f'    <span class="ig-cta-button">{cta_text}</span>')
    parts.append('  </div>')
    return "\n".join(parts)


def render_footer(block, _dv):
    """Render the footer block."""
    f = block.get("fields", {})
    left = escape_html(f.get("Left", ""))
    center = escape_html(f.get("Center", ""))
    right = escape_html(f.get("Right", ""))
    source = escape_html(f.get("Source-Line", ""))
    parts = ['  <footer class="ig-footer">']
    parts.append(f'    <div class="ig-footer-row">')
    parts.append(f'      <span class="ig-footer-left">{left}</span>')
    parts.append(f'      <span class="ig-footer-center">{center}</span>')
    parts.append(f'      <span class="ig-footer-right">{right}</span>')
    parts.append('    </div>')
    if source:
        parts.append(f'    <div class="ig-footer-source">{source}</div>')
    parts.append('  </footer>')
    return "\n".join(parts)


# ---------------------------------------------------------------------------
# CSS Generation
# ---------------------------------------------------------------------------

def generate_css(dv, style_preset, layout_type, orientation, dimensions):
    """Generate the full CSS stylesheet."""
    c = dv.get("colors", {})
    s = dv.get("status", {})
    f = dv.get("fonts", {})
    sh = dv.get("shadows", {})
    r = dv.get("radius", "12px")
    gfi = dv.get("google_fonts_import", "")

    # Parse dimensions
    w, h = dimensions.split("x") if "x" in dimensions else ("1920", "1080")

    # Spacing per preset
    spacing = {
        "editorial":  {"sm": "16px", "md": "40px", "lg": "60px", "pad": "24px"},
        "data-viz":   {"sm": "12px", "md": "24px", "lg": "32px", "pad": "16px"},
        "sketchnote": {"sm": "16px", "md": "36px", "lg": "48px", "pad": "24px"},
        "corporate":  {"sm": "12px", "md": "32px", "lg": "40px", "pad": "20px"},
        "whiteboard": {"sm": "20px", "md": "48px", "lg": "64px", "pad": "24px"},
    }.get(style_preset, {"sm": "16px", "md": "32px", "lg": "48px", "pad": "20px"})

    css = f"""{gfi}

:root {{
  --color-primary: {c.get('primary', '#111')};
  --color-secondary: {c.get('secondary', '#333')};
  --color-accent: {c.get('accent', '#C8E62E')};
  --color-accent-muted: {c.get('accent_muted', '#A8C424')};
  --color-accent-dark: {c.get('accent_dark', '#8BA31E')};
  --color-bg: {c.get('background', '#FAFAF8')};
  --color-surface: {c.get('surface', '#F2F2EE')};
  --color-surface2: {c.get('surface2', '#E8E8E4')};
  --color-surface-dark: {c.get('surface_dark', '#111')};
  --color-border: {c.get('border', '#E0E0DC')};
  --color-text: {c.get('text', '#111')};
  --color-text-light: {c.get('text_light', '#FFF')};
  --color-text-muted: {c.get('text_muted', '#6B7280')};
  --color-success: {s.get('success', '#2E7D32')};
  --color-warning: {s.get('warning', '#E5A100')};
  --color-danger: {s.get('danger', '#D32F2F')};
  --font-headers: {f.get('headers', 'sans-serif')};
  --font-body: {f.get('body', 'sans-serif')};
  --font-mono: {f.get('mono', 'monospace')};
  --radius: {r};
  --shadow-sm: {sh.get('sm', 'none')};
  --shadow-md: {sh.get('md', 'none')};
  --shadow-lg: {sh.get('lg', 'none')};
  --spacing-sm: {spacing['sm']};
  --spacing-md: {spacing['md']};
  --spacing-lg: {spacing['lg']};
  --padding: {spacing['pad']};
}}

* {{ margin: 0; padding: 0; box-sizing: border-box; }}

body {{
  background: #f0f0f0;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
  font-family: var(--font-body);
}}

.infographic {{
  width: {w}px;
  max-width: 100%;
  background: var(--color-bg);
  color: var(--color-text);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  padding: var(--spacing-lg);
  box-shadow: var(--shadow-lg);
  position: relative;
}}

/* Title */
.ig-title {{
  text-align: center;
  padding: var(--spacing-md) var(--padding);
}}
.ig-headline {{
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 2.2rem;
  line-height: 1.15;
  color: var(--color-text);
  margin-bottom: 8px;
}}
.ig-subline {{
  font-size: 1.1rem;
  color: var(--color-text-muted);
  margin-bottom: 4px;
}}
.ig-metadata {{
  font-size: 0.8rem;
  color: var(--color-text-muted);
  letter-spacing: 0.02em;
}}

/* Content area */
.ig-content {{
  display: grid;
  gap: var(--spacing-md);
  flex: 1;
}}

/* Layout-specific grids */
.ig-content[data-layout="stat-heavy"] {{
  grid-template-columns: repeat(3, 1fr);
}}
.ig-content[data-layout="stat-heavy"] .ig-chart,
.ig-content[data-layout="stat-heavy"] .ig-stat-row,
.ig-content[data-layout="stat-heavy"] .ig-process-strip,
.ig-content[data-layout="stat-heavy"] .ig-text-block {{
  grid-column: 1 / -1;
}}

.ig-content[data-layout="timeline-flow"] {{
  grid-template-columns: 1fr;
}}

.ig-content[data-layout="comparison"] {{
  grid-template-columns: 1fr;
}}

.ig-content[data-layout="hub-spoke"] {{
  grid-template-columns: 1fr;
}}

.ig-content[data-layout="funnel-pyramid"] {{
  grid-template-columns: 1fr;
}}

.ig-content[data-layout="list-grid"] {{
  grid-template-columns: 1fr;
}}

.ig-content[data-layout="flow-diagram"] {{
  grid-template-columns: 1fr;
}}

/* Blocks */
.ig-block {{
  padding: var(--padding);
  border-radius: var(--radius);
}}

/* KPI Card */
.ig-kpi-card {{
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: var(--color-surface);
}}
.ig-kpi-icon svg {{ width: 48px; height: 48px; }}
.ig-kpi-number {{
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 3rem;
  line-height: 1;
  color: var(--color-accent-dark);
}}
.ig-kpi-label {{
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--color-text);
}}
.ig-kpi-sublabel {{
  font-size: 0.8rem;
  color: var(--color-text-muted);
}}
.ig-kpi-source {{
  font-size: 0.7rem;
  color: var(--color-text-muted);
  font-style: italic;
  margin-top: 4px;
}}

/* Stat Row */
.ig-stat-row {{
  display: flex;
  justify-content: space-evenly;
  gap: var(--spacing-sm);
  background: var(--color-surface);
}}
.ig-stat {{
  text-align: center;
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}}
.ig-stat-icon svg {{ width: 32px; height: 32px; }}
.ig-stat-number {{
  font-family: var(--font-headers);
  font-weight: 600;
  font-size: 1.5rem;
  color: var(--color-accent-dark);
}}
.ig-stat-label {{
  font-size: 0.8rem;
  color: var(--color-text-muted);
}}

/* Chart */
.ig-chart {{
  background: var(--color-surface);
  padding: var(--padding);
}}
.ig-chart-title {{
  font-family: var(--font-headers);
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.03em;
  margin-bottom: 8px;
}}

/* Process Strip */
.ig-process-strip {{
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-sm);
  flex-wrap: wrap;
}}
.ig-step {{
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  flex: 1;
  min-width: 80px;
}}
.ig-step-icon svg {{ width: 40px; height: 40px; }}
.ig-step-label {{
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--color-text);
}}
.ig-step-connector {{
  font-size: 1.5rem;
  color: var(--color-accent);
  font-weight: 700;
  line-height: 1;
}}

/* Text Block */
.ig-text-block {{
  display: flex;
  gap: var(--spacing-sm);
  align-items: flex-start;
}}
.ig-text-icon svg {{ width: 40px; height: 40px; flex-shrink: 0; }}
.ig-text-headline {{
  font-family: var(--font-headers);
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 4px;
}}
.ig-text-body {{
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--color-text-muted);
}}

/* Comparison Pair */
.ig-comparison {{
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: var(--spacing-md);
}}
.ig-comparison-side {{
  padding: var(--padding);
  border-radius: var(--radius);
}}
.ig-comparison-left {{ background: var(--color-surface); }}
.ig-comparison-right {{ background: color-mix(in srgb, var(--color-accent) 10%, var(--color-bg)); }}
.ig-comparison-icon svg {{ width: 36px; height: 36px; margin-bottom: 8px; }}
.ig-comparison-label {{
  font-family: var(--font-headers);
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 8px;
}}
.ig-comparison-bullets {{
  list-style: none;
  padding: 0;
}}
.ig-comparison-bullets li {{
  padding: 4px 0;
  font-size: 0.9rem;
  position: relative;
  padding-left: 16px;
}}
.ig-comparison-left .ig-comparison-bullets li::before {{
  content: "\\2212";
  position: absolute;
  left: 0;
  color: var(--color-danger);
  font-weight: 700;
}}
.ig-comparison-right .ig-comparison-bullets li::before {{
  content: "+";
  position: absolute;
  left: 0;
  color: var(--color-success);
  font-weight: 700;
}}
.ig-comparison-divider {{
  width: 2px;
  background: var(--color-border);
  align-self: stretch;
}}

/* Icon Grid */
.ig-icon-grid {{
  display: grid;
  grid-template-columns: repeat(var(--grid-cols, 2), 1fr);
  gap: var(--spacing-md);
}}
.ig-grid-item {{
  text-align: center;
  padding: var(--padding);
  background: var(--color-surface);
  border-radius: var(--radius);
}}
.ig-grid-icon svg {{ width: 48px; height: 48px; margin-bottom: 8px; }}
.ig-grid-label {{
  font-family: var(--font-headers);
  font-weight: 600;
  font-size: 0.95rem;
  margin-bottom: 4px;
}}
.ig-grid-sublabel {{
  font-size: 0.8rem;
  color: var(--color-text-muted);
  line-height: 1.4;
}}

/* SVG Diagram */
.ig-svg-diagram {{
  display: flex;
  justify-content: center;
  align-items: center;
  padding: var(--spacing-md);
}}
.ig-svg-diagram svg {{
  max-width: 100%;
  height: auto;
}}

/* CTA */
.ig-cta {{
  text-align: center;
  padding: var(--spacing-md) var(--padding);
}}
.ig-cta-headline {{
  font-family: var(--font-headers);
  font-size: 1.3rem;
  font-weight: 600;
  margin-bottom: 12px;
}}
.ig-cta-button {{
  display: inline-block;
  background: var(--color-accent);
  color: var(--color-primary);
  padding: 12px 32px;
  border-radius: var(--radius);
  font-weight: 600;
  font-size: 1rem;
  text-decoration: none;
  cursor: pointer;
}}
.ig-cta[data-urgency="high"] .ig-cta-button {{
  box-shadow: var(--shadow-md);
  font-size: 1.1rem;
  padding: 14px 40px;
}}

/* Footer */
.ig-footer {{
  padding: var(--spacing-sm) var(--padding);
  border-top: 1px solid var(--color-border);
  font-size: 0.75rem;
  color: var(--color-text-muted);
}}
.ig-footer-row {{
  display: flex;
  justify-content: space-between;
}}
.ig-footer-source {{
  margin-top: 4px;
  font-style: italic;
  font-size: 0.7rem;
}}

/* Style preset overrides — see references/02-style-css.md */
/* editorial */
[data-style="editorial"] .ig-block {{ border: 1px solid var(--color-border); border-radius: 0; background: var(--color-bg); }}
[data-style="editorial"] .ig-kpi-card {{ background: var(--color-bg); }}
[data-style="editorial"] .ig-headline {{ font-size: 2.5rem; letter-spacing: -0.02em; }}
[data-style="editorial"] .ig-cta-button {{ border-radius: 0; background: var(--color-primary); color: var(--color-text-light); text-transform: uppercase; letter-spacing: 0.05em; }}

/* data-viz */
[data-style="data-viz"] .ig-kpi-card {{ background: color-mix(in srgb, var(--color-accent) 8%, var(--color-bg)); }}
[data-style="data-viz"] .ig-kpi-number {{ font-family: var(--font-mono); }}
[data-style="data-viz"] .ig-stat-number {{ font-family: var(--font-mono); }}
[data-style="data-viz"] .ig-kpi-label, [data-style="data-viz"] .ig-stat-label {{ text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.75rem; }}

/* sketchnote */
[data-style="sketchnote"] {{ background: var(--color-surface); }}
[data-style="sketchnote"] .ig-block {{ border: 2px dashed var(--color-primary); border-radius: 24px; background: var(--color-bg); }}
[data-style="sketchnote"] .ig-block:nth-child(odd) {{ transform: rotate(-0.5deg); }}
[data-style="sketchnote"] .ig-block:nth-child(even) {{ transform: rotate(0.5deg); }}
[data-style="sketchnote"] .ig-step-icon svg, [data-style="sketchnote"] .ig-grid-icon svg {{ width: 64px; height: 64px; }}
[data-style="sketchnote"] .ig-cta-button {{ border-radius: 24px; }}

/* corporate */
[data-style="corporate"] .ig-title {{ background: var(--color-surface-dark); color: var(--color-text-light); border-radius: 0; }}
[data-style="corporate"] .ig-headline {{ color: var(--color-text-light); }}
[data-style="corporate"] .ig-subline {{ color: var(--color-text-light); opacity: 0.8; }}
[data-style="corporate"] .ig-block {{ border: 2px solid var(--color-border); border-radius: 4px; }}
[data-style="corporate"] .ig-kpi-number {{ color: var(--color-primary); }}
[data-style="corporate"] .ig-footer {{ background: var(--color-surface); border-top: 2px solid var(--color-primary); }}
[data-style="corporate"] .ig-cta-button {{ background: var(--color-primary); color: var(--color-text-light); border-radius: 4px; }}

/* whiteboard */
[data-style="whiteboard"] {{ background: #FFFFFF; }}
[data-style="whiteboard"] .ig-block {{ border: 2px solid var(--color-primary); border-radius: 0; background: transparent; }}
[data-style="whiteboard"] .ig-kpi-card {{ background: transparent; }}
[data-style="whiteboard"] .ig-stat-row {{ background: transparent; }}
[data-style="whiteboard"] .ig-headline {{ font-weight: 800; }}
[data-style="whiteboard"] .ig-kpi-number {{ font-weight: 800; font-size: 4rem; color: var(--color-accent); }}
[data-style="whiteboard"] .ig-step-connector {{ color: var(--color-accent); }}
[data-style="whiteboard"] .ig-cta-button {{ background: var(--color-accent); border: 2px solid var(--color-primary); border-radius: 0; }}
[data-style="whiteboard"] .ig-footer {{ border-top: 2px solid var(--color-primary); }}

/* Print mode */
@media print {{
  body {{ background: white; padding: 0; }}
  .infographic {{ box-shadow: none; width: 100%; max-width: none; }}
}}
"""
    return css


# ---------------------------------------------------------------------------
# HTML Assembly
# ---------------------------------------------------------------------------

def generate_html(data, dv, svg_dir):
    """Generate the complete HTML document."""
    meta = data.get("metadata", {})
    blocks = data.get("blocks", [])
    layout_type = meta.get("layout_type", "stat-heavy")
    style_preset = meta.get("style_preset", "editorial")
    orientation = meta.get("orientation", "landscape")
    dimensions = meta.get("dimensions", "1920x1080")
    language = meta.get("language", "en")

    css = generate_css(dv, style_preset, layout_type, orientation, dimensions)

    # Separate blocks by role
    title_block = None
    content_blocks = []
    cta_block = None
    footer_block = None
    chart_scripts = []

    for i, block in enumerate(blocks):
        bt = block.get("block_type", "")
        if bt == "title":
            title_block = block
        elif bt == "cta":
            cta_block = block
        elif bt == "footer":
            footer_block = block
        else:
            content_blocks.append((i, block))

    # Render title
    title_html = render_title(title_block, dv) if title_block else ""

    # Render content blocks
    content_parts = []
    chart_idx = 0
    for i, block in content_blocks:
        bt = block.get("block_type", "")
        svg = load_svg_icon(svg_dir, i) if svg_dir else ""

        if bt == "kpi-card":
            content_parts.append(render_kpi_card(block, dv, svg))
        elif bt == "stat-row":
            content_parts.append(render_stat_row(block, dv, svg_dir, i))
        elif bt == "chart":
            html, script = render_chart(block, dv, chart_idx)
            content_parts.append(html)
            chart_scripts.append(script)
            chart_idx += 1
        elif bt == "process-strip":
            content_parts.append(render_process_strip(block, dv, svg_dir, i))
        elif bt == "text-block":
            content_parts.append(render_text_block(block, dv, svg))
        elif bt == "comparison-pair":
            content_parts.append(render_comparison_pair(block, dv, svg_dir, i))
        elif bt == "icon-grid":
            content_parts.append(render_icon_grid(block, dv, svg_dir, i))
        elif bt == "svg-diagram":
            content_parts.append(render_svg_diagram(block, dv, svg))

    content_html = "\n".join(content_parts)

    # Render CTA and footer
    cta_html = render_cta(cta_block, dv) if cta_block else ""
    footer_html = render_footer(footer_block, dv) if footer_block else ""

    # Chart.js CDN (only if charts present)
    chartjs_cdn = ""
    chartjs_init = ""
    if chart_scripts:
        chartjs_cdn = '<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>'
        chartjs_init = f"""<script>
document.addEventListener('DOMContentLoaded', function() {{
  {chr(10).join('  ' + s for s in chart_scripts)}
}});
</script>"""

    title_text = escape_html(meta.get("title", meta.get("governing_thought", "Infographic")))

    html = f"""<!DOCTYPE html>
<html lang="{language}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title_text}</title>
  <style>
{css}
  </style>
  {chartjs_cdn}
</head>
<body>
<div class="infographic" data-style="{style_preset}" data-layout="{layout_type}">
{title_html}
  <main class="ig-content" data-layout="{layout_type}">
{content_html}
  </main>
{cta_html}
{footer_html}
</div>
{chartjs_init}
</body>
</html>"""

    return html, len(blocks)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate themed HTML infographic")
    parser.add_argument("--infographic-data", required=True, help="Path to infographic-data.json")
    parser.add_argument("--design-variables", default="", help="Path to design-variables.json")
    parser.add_argument("--svg-dir", default="", help="Directory containing SVG icon files")
    parser.add_argument("--output", required=True, help="Output HTML file path")
    parser.add_argument("--language", default="en", help="Language code (en/de)")
    args = parser.parse_args()

    try:
        with open(args.infographic_data) as f:
            data = json.load(f)
    except Exception as e:
        print(json.dumps({"error": f"Failed to read infographic data: {e}"}))
        sys.exit(1)

    dv = load_design_variables(args.design_variables)
    svg_dir = args.svg_dir if args.svg_dir and os.path.isdir(args.svg_dir) else None

    try:
        html, block_count = generate_html(data, dv, svg_dir)
    except Exception as e:
        print(json.dumps({"error": f"Failed to generate HTML: {e}"}))
        sys.exit(1)

    try:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w") as f:
            f.write(html)
    except Exception as e:
        print(json.dumps({"error": f"Failed to write output: {e}"}))
        sys.exit(1)

    size_kb = os.path.getsize(args.output) / 1024
    print(json.dumps({
        "status": "ok",
        "path": os.path.abspath(args.output),
        "blocks": block_count,
        "size_kb": round(size_kb, 1),
    }))


if __name__ == "__main__":
    main()
