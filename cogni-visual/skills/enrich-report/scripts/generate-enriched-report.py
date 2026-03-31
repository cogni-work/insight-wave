#!/usr/bin/env python3
"""Generate a self-contained themed HTML file from a markdown report + enrichment plan.

Usage:
    python3 generate-enriched-report.py \
        --source <report.md> \
        --enrichment-plan <enrichment-plan.json> \
        --chart-configs <chart-configs.json> \
        --design-variables <design-variables.json> \
        --output <output.html> \
        --language <en|de> \
        [--svg-dir <path/to/svgs/>]

Output: Self-contained HTML file with themed report + Chart.js visualizations + inline SVGs.
Returns JSON: {"status": "ok", "path": "<output-path>"} or {"error": "..."}
"""

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
        "headers": "'Bricolage Grotesque', 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "body": "'Outfit', 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "mono": "'JetBrains Mono', 'Fira Code', Consolas, monospace",
    },
    "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Outfit:wght@300;400;500;600;700&display=swap');",
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
    # Merge with defaults for any missing keys
    result = DEFAULT_THEME.copy()
    for section in ("colors", "status", "fonts", "shadows"):
        if section in dv:
            result[section] = {**result.get(section, {}), **dv[section]}
    for key in ("theme_name", "google_fonts_import", "radius"):
        if key in dv:
            result[key] = dv[key]
    return result


# ---------------------------------------------------------------------------
# Markdown → HTML conversion (stdlib only, no pip deps)
# ---------------------------------------------------------------------------

def slugify(text):
    """Convert heading text to URL-safe slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-')


def escape_html(text):
    """Escape HTML special characters."""
    return (text
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;'))


def convert_inline(text):
    """Convert inline markdown (bold, italic, links, code) to HTML."""
    # Links: [text](url)
    text = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        r'<a href="\2" target="_blank" rel="noopener">\1</a>',
        text
    )
    # Bold: **text**
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    # Italic: *text*
    text = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', text)
    # Inline code: `text`
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text


def parse_frontmatter(lines):
    """Extract YAML frontmatter if present. Returns (frontmatter_dict, content_start_line)."""
    if not lines or lines[0].strip() != '---':
        return {}, 0
    end = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            end = i
            break
    if end == -1:
        return {}, 0
    fm = {}
    for line in lines[1:end]:
        m = re.match(r'^(\w[\w_-]*):\s*(.+)', line)
        if m:
            fm[m.group(1).strip()] = m.group(2).strip().strip('"').strip("'")
    return fm, end + 1


def markdown_to_html_sections(md_text):
    """Convert markdown text to a list of HTML sections with heading hierarchy.

    Returns: list of dicts {id, level, heading, html, line_start}
    """
    lines = md_text.split('\n')
    fm, content_start = parse_frontmatter(lines)

    sections = []
    current = {"id": "preamble", "level": 0, "heading": "", "lines": [], "line_start": content_start}

    for i, line in enumerate(lines[content_start:], start=content_start):
        heading_match = re.match(r'^(#{1,4})\s+(.+)', line)
        if heading_match:
            # Close previous section
            if current["lines"] or current["heading"]:
                current["html"] = _render_block(current["lines"])
                sections.append(current)
            level = len(heading_match.group(1))
            heading = heading_match.group(2).strip()
            current = {
                "id": slugify(heading),
                "level": level,
                "heading": heading,
                "lines": [],
                "line_start": i,
            }
        else:
            current["lines"].append(line)

    # Close last section
    if current["lines"] or current["heading"]:
        current["html"] = _render_block(current["lines"])
        sections.append(current)

    return fm, sections


def _render_block(lines):
    """Render a block of markdown lines to HTML."""
    html_parts = []
    i = 0
    in_table = False
    in_list = False
    in_blockquote = False
    in_code = False
    code_lines = []
    code_lang = ''
    table_rows = []
    list_items = []
    bq_lines = []

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Fenced code blocks
        if stripped.startswith('```'):
            if in_code:
                if code_lang == 'mermaid':
                    html_parts.append('<pre class="mermaid">' + escape_html('\n'.join(code_lines)) + '</pre>')
                else:
                    html_parts.append('<pre><code>' + escape_html('\n'.join(code_lines)) + '</code></pre>')
                code_lines = []
                code_lang = ''
                in_code = False
            else:
                _flush_state(html_parts, in_table, table_rows, in_list, list_items, in_blockquote, bq_lines)
                in_table = in_list = in_blockquote = False
                table_rows = []; list_items = []; bq_lines = []
                code_lang = stripped[3:].strip().lower()
                in_code = True
            i += 1
            continue
        if in_code:
            code_lines.append(line)
            i += 1
            continue

        # Table rows
        if '|' in stripped and not stripped.startswith('>'):
            if re.match(r'^\|?\s*[-:]+[-| :]*$', stripped):
                # Separator row — skip
                i += 1
                continue
            cells = [c.strip() for c in stripped.strip('|').split('|')]
            if not in_table:
                _flush_state(html_parts, False, [], in_list, list_items, in_blockquote, bq_lines)
                in_list = in_blockquote = False
                list_items = []; bq_lines = []
                in_table = True
                table_rows = []
            table_rows.append(cells)
            i += 1
            continue
        elif in_table:
            html_parts.append(_render_table(table_rows))
            table_rows = []
            in_table = False

        # Blockquotes
        if stripped.startswith('>'):
            if not in_blockquote:
                _flush_state(html_parts, in_table, table_rows, in_list, list_items, False, [])
                in_table = in_list = False
                table_rows = []; list_items = []
                in_blockquote = True
                bq_lines = []
            bq_lines.append(re.sub(r'^>\s?', '', stripped))
            i += 1
            continue
        elif in_blockquote:
            html_parts.append('<blockquote>' + convert_inline(' '.join(bq_lines)) + '</blockquote>')
            bq_lines = []
            in_blockquote = False

        # Unordered lists
        if re.match(r'^[-*+]\s', stripped):
            if not in_list:
                _flush_state(html_parts, in_table, table_rows, False, [], in_blockquote, bq_lines)
                in_table = in_blockquote = False
                table_rows = []; bq_lines = []
                in_list = True
                list_items = []
            list_items.append(re.sub(r'^[-*+]\s', '', stripped))
            i += 1
            continue
        # Ordered lists
        elif re.match(r'^\d+\.\s', stripped):
            if not in_list:
                _flush_state(html_parts, in_table, table_rows, False, [], in_blockquote, bq_lines)
                in_table = in_blockquote = False
                table_rows = []; bq_lines = []
                in_list = True
                list_items = []
            list_items.append(re.sub(r'^\d+\.\s', '', stripped))
            i += 1
            continue
        elif in_list:
            html_parts.append(_render_list(list_items))
            list_items = []
            in_list = False

        # Horizontal rule
        if re.match(r'^[-*_]{3,}\s*$', stripped):
            html_parts.append('<hr>')
            i += 1
            continue

        # Empty line
        if not stripped:
            i += 1
            continue

        # Regular paragraph
        html_parts.append('<p>' + convert_inline(stripped) + '</p>')
        i += 1

    # Flush remaining state
    _flush_state(html_parts, in_table, table_rows, in_list, list_items, in_blockquote, bq_lines)
    if in_code:
        html_parts.append('<pre><code>' + escape_html('\n'.join(code_lines)) + '</code></pre>')

    return '\n'.join(html_parts)


def _flush_state(html_parts, in_table, table_rows, in_list, list_items, in_bq, bq_lines):
    if in_table and table_rows:
        html_parts.append(_render_table(table_rows))
    if in_list and list_items:
        html_parts.append(_render_list(list_items))
    if in_bq and bq_lines:
        html_parts.append('<blockquote>' + convert_inline(' '.join(bq_lines)) + '</blockquote>')


def _render_table(rows):
    if not rows:
        return ''
    html = '<div class="table-wrapper"><table>'
    # First row as header
    html += '<thead><tr>'
    for cell in rows[0]:
        html += '<th>' + convert_inline(cell) + '</th>'
    html += '</tr></thead>'
    # Remaining rows
    if len(rows) > 1:
        html += '<tbody>'
        for row in rows[1:]:
            html += '<tr>'
            for cell in row:
                html += '<td>' + convert_inline(cell) + '</td>'
            html += '</tr>'
        html += '</tbody>'
    html += '</table></div>'
    return html


def _render_list(items):
    html = '<ul>'
    for item in items:
        html += '<li>' + convert_inline(item) + '</li>'
    html += '</ul>'
    return html


# ---------------------------------------------------------------------------
# Enrichment injection
# ---------------------------------------------------------------------------

def build_enrichment_html(enrichment, chart_configs, svg_dir, dv):
    """Build HTML for a single enrichment based on its type and track."""
    eid = enrichment.get("id", "enr-000")
    etype = enrichment.get("type", "")
    track = enrichment.get("track", "data")

    if track == "data":
        return _build_chart_html(eid, etype, enrichment, chart_configs, dv)
    elif track == "concept":
        return _build_svg_html(eid, etype, enrichment, svg_dir)
    elif track == "html":
        return _build_card_html(eid, etype, enrichment, dv)
    return ''


def _build_chart_html(eid, etype, enrichment, chart_configs, dv):
    """Build HTML for a Chart.js data visualization."""
    if etype == "kpi-dashboard":
        return _build_kpi_html(eid, enrichment, dv)

    # Canvas-based chart
    config = None
    for cfg in chart_configs:
        if cfg.get("chart_id") == eid:
            config = cfg
            break
    if not config:
        return f'<!-- enrichment {eid}: no chart config found -->'

    desc = enrichment.get("description", "")
    height = _chart_height(etype, enrichment)

    html = f'''<div class="enrichment chart-container" data-type="{etype}" data-id="{eid}">
  <canvas id="{eid}" style="max-height: {height}px;"></canvas>
  <p class="enrichment-caption">{escape_html(desc)}</p>
</div>'''
    return html


def _build_kpi_html(eid, enrichment, dv):
    """Build KPI card row from enrichment data."""
    stats = enrichment.get("data", {}).get("stats", [])
    if not stats:
        return f'<!-- enrichment {eid}: no KPI stats -->'

    cards = []
    for stat in stats[:6]:
        value = escape_html(str(stat.get("value", "")))
        label = escape_html(str(stat.get("label", "")))
        source = stat.get("source", "")
        source_url = stat.get("source_url", "")
        source_html = ""
        if source and source_url:
            source_html = f'<div class="kpi-source"><a href="{escape_html(source_url)}" target="_blank" rel="noopener">{escape_html(source)}</a></div>'
        elif source:
            source_html = f'<div class="kpi-source">{escape_html(source)}</div>'

        cards.append(f'''<div class="kpi-card">
  <div class="kpi-value">{value}</div>
  <div class="kpi-label">{label}</div>
  {source_html}
</div>''')

    return f'''<div class="enrichment kpi-row" data-type="kpi-dashboard" data-id="{eid}">
  {''.join(cards)}
</div>'''


def _build_svg_html(eid, etype, enrichment, svg_dir):
    """Build HTML for an inline SVG concept diagram."""
    svg_path = os.path.join(svg_dir, f"{eid}.svg") if svg_dir else ""
    svg_content = ""
    if svg_path and os.path.isfile(svg_path):
        with open(svg_path) as f:
            svg_content = f.read()
    else:
        svg_content = f'<!-- SVG not found: {eid}.svg -->'

    desc = enrichment.get("description", "")
    return f'''<div class="enrichment concept-diagram" data-type="{etype}" data-id="{eid}">
  {svg_content}
  <p class="enrichment-caption">{escape_html(desc)}</p>
</div>'''


def _build_card_html(eid, etype, enrichment, dv):
    """Build HTML for a summary card."""
    data = enrichment.get("data", {})
    summary = data.get("summary", "")
    word_count = data.get("word_count", 0)

    wc_badge = f'<span class="summary-badge">{word_count} words</span>' if word_count else ''

    return f'''<div class="enrichment summary-card" data-type="{etype}" data-id="{eid}">
  <div class="summary-card-content">
    <p>{convert_inline(summary)}</p>
  </div>
  {wc_badge}
</div>'''


def _chart_height(etype, enrichment):
    """Determine chart height based on type and data size."""
    heights = {
        "horizon-chart": 400,
        "theme-radar": 400,
        "coverage-heatmap": 350,
        "distribution-doughnut": 350,
        "timeline-chart": 200,
        "comparison-bar": 350,
        "stat-chart": 350,
    }
    h = heights.get(etype, 350)
    # Scale bar charts by item count
    if etype in ("horizon-chart", "comparison-bar"):
        items = len(enrichment.get("data", {}).get("stats", []))
        if items > 5:
            h = max(h, items * 60 + 80)
    return h


# ---------------------------------------------------------------------------
# HTML assembly
# ---------------------------------------------------------------------------

def generate_css(dv):
    """Generate the full CSS block with design variables."""
    c = dv["colors"]
    s = dv["status"]
    f = dv["fonts"]
    sh = dv.get("shadows", DEFAULT_THEME["shadows"])
    radius = dv.get("radius", "12px")
    gf = dv.get("google_fonts_import", "")

    return f"""{gf}

:root {{
  --primary: {c['primary']};
  --secondary: {c['secondary']};
  --accent: {c['accent']};
  --accent-muted: {c['accent_muted']};
  --accent-dark: {c['accent_dark']};
  --bg: {c['background']};
  --surface: {c['surface']};
  --surface2: {c['surface2']};
  --surface-dark: {c['surface_dark']};
  --border: {c['border']};
  --text: {c['text']};
  --text-light: {c['text_light']};
  --text-muted: {c['text_muted']};
  --status-success: {s['success']};
  --status-warning: {s['warning']};
  --status-danger: {s['danger']};
  --status-info: {s['info']};
  --font-headers: {f['headers']};
  --font-body: {f['body']};
  --font-mono: {f['mono']};
  --radius: {radius};
  --shadow-sm: {sh['sm']};
  --shadow-md: {sh['md']};
  --shadow-lg: {sh['lg']};
  --shadow-xl: {sh['xl']};
}}

*, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}

body {{
  font-family: var(--font-body);
  background: var(--bg);
  color: var(--text);
  line-height: 1.7;
  -webkit-font-smoothing: antialiased;
}}

/* Layout */
.layout {{ display: flex; min-height: 100vh; }}
nav.sidebar {{
  position: sticky; top: 0; height: 100vh; width: 260px; min-width: 260px;
  background: var(--surface); border-right: 1px solid var(--border);
  overflow-y: auto; padding: 24px 16px;
  scrollbar-width: thin;
}}
nav.sidebar .nav-title {{
  font-family: var(--font-headers); font-size: 0.85rem; font-weight: 600;
  color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em;
  margin-bottom: 16px; padding: 0 8px;
}}
nav.sidebar a {{
  display: block; padding: 6px 12px; border-radius: 6px;
  font-size: 0.85rem; color: var(--text-muted); text-decoration: none;
  transition: all 0.15s ease;
}}
nav.sidebar a:hover {{ background: var(--surface2); color: var(--text); }}
nav.sidebar a.active {{ background: var(--accent); color: var(--surface-dark); font-weight: 500; }}
nav.sidebar a.depth-3 {{ padding-left: 28px; font-size: 0.8rem; }}
nav.sidebar a.depth-4 {{ padding-left: 44px; font-size: 0.75rem; }}

main.content {{
  flex: 1; max-width: 860px; margin: 0 auto; padding: 48px 40px;
}}

/* Typography */
h1 {{ font-family: var(--font-headers); font-size: 2.2rem; font-weight: 700; margin: 0 0 24px; line-height: 1.2; }}
h2 {{ font-family: var(--font-headers); font-size: 1.6rem; font-weight: 600; margin: 48px 0 16px; line-height: 1.3;
      padding-bottom: 8px; border-bottom: 2px solid var(--accent); }}
h3 {{ font-family: var(--font-headers); font-size: 1.2rem; font-weight: 600; margin: 32px 0 12px; }}
h4 {{ font-family: var(--font-headers); font-size: 1.05rem; font-weight: 600; margin: 24px 0 8px; }}
p {{ margin: 0 0 16px; }}
a {{ color: var(--accent-dark); text-decoration: underline; text-underline-offset: 2px; }}
a:hover {{ color: var(--accent); }}
strong {{ font-weight: 600; }}
code {{ font-family: var(--font-mono); font-size: 0.88em; background: var(--surface); padding: 2px 6px; border-radius: 4px; }}
pre {{ background: var(--surface-dark); color: var(--text-light); padding: 16px 20px; border-radius: var(--radius);
       overflow-x: auto; margin: 16px 0; }}
pre code {{ background: none; padding: 0; color: inherit; }}
blockquote {{ border-left: 3px solid var(--accent); padding: 12px 20px; margin: 16px 0; background: var(--surface);
             border-radius: 0 var(--radius) var(--radius) 0; font-style: italic; color: var(--text-muted); }}
hr {{ border: none; border-top: 1px solid var(--border); margin: 32px 0; }}
ul, ol {{ margin: 0 0 16px; padding-left: 24px; }}
li {{ margin: 4px 0; }}

/* Tables */
.table-wrapper {{ overflow-x: auto; margin: 16px 0; }}
table {{ width: 100%; border-collapse: collapse; font-size: 0.9rem; }}
th {{ background: var(--surface); font-weight: 600; text-align: left; padding: 10px 12px; border-bottom: 2px solid var(--border); }}
td {{ padding: 8px 12px; border-bottom: 1px solid var(--border); }}
tr:hover td {{ background: var(--surface); }}

/* Enrichments */
.enrichment {{ margin: 32px 0; }}
.chart-container {{
  max-width: 720px; margin: 32px auto; padding: 24px;
  background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow-sm);
}}
.chart-container canvas {{ max-width: 100%; }}
.enrichment-caption {{
  font-size: 0.85rem; color: var(--text-muted); margin-top: 12px;
  font-style: italic; text-align: center;
}}

/* KPI cards */
.kpi-row {{ display: flex; gap: 16px; flex-wrap: wrap; justify-content: center; }}
.kpi-card {{
  flex: 1; min-width: 140px; max-width: 220px;
  background: var(--surface); border-radius: var(--radius); padding: 20px; text-align: center;
  box-shadow: var(--shadow-sm); border-top: 3px solid var(--accent);
}}
.kpi-value {{ font-family: var(--font-headers); font-size: 2rem; font-weight: 700; color: var(--accent-dark); line-height: 1.2; }}
.kpi-label {{ font-size: 0.85rem; color: var(--text-muted); margin-top: 6px; }}
.kpi-source {{ font-size: 0.75rem; color: var(--text-muted); margin-top: 8px; }}
.kpi-source a {{ color: var(--accent); text-decoration: none; }}

/* Concept diagrams */
.concept-diagram {{
  max-width: 720px; margin: 32px auto; padding: 24px;
  background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow-sm); text-align: center;
}}
.concept-diagram svg {{ max-width: 100%; height: auto; }}

/* Summary cards */
.summary-card {{
  max-width: 720px; margin: 24px auto; padding: 20px 24px;
  background: var(--surface); border-radius: var(--radius);
  border-left: 4px solid var(--accent); box-shadow: var(--shadow-sm);
}}
.summary-card-content p {{ margin: 0; font-size: 0.95rem; }}
.summary-badge {{
  display: inline-block; margin-top: 8px; font-size: 0.75rem;
  color: var(--text-muted); background: var(--surface2); padding: 2px 8px; border-radius: 4px;
}}

/* Responsive */
@media (max-width: 1024px) {{
  nav.sidebar {{ display: none; }}
  main.content {{ padding: 24px 20px; max-width: 100%; }}
}}
@media (max-width: 768px) {{
  .kpi-row {{ flex-direction: column; align-items: center; }}
  .kpi-card {{ max-width: 100%; min-width: 0; }}
  .chart-container, .concept-diagram, .summary-card {{ padding: 16px; }}
  h1 {{ font-size: 1.6rem; }}
  h2 {{ font-size: 1.3rem; }}
}}
"""


def generate_nav(sections):
    """Generate sidebar navigation HTML from sections."""
    nav_items = []
    for sec in sections:
        if sec["level"] < 1 or sec["level"] > 3:
            continue
        if not sec["heading"]:
            continue
        depth_class = f' depth-{sec["level"]}' if sec["level"] > 2 else ''
        nav_items.append(
            f'<a href="#{sec["id"]}" class="nav-link{depth_class}">{escape_html(sec["heading"])}</a>'
        )
    return '\n    '.join(nav_items)


def resolve_chart_colors(chart_configs, dv):
    """Replace var(--name) tokens in chart configs with actual hex values."""
    var_map = {
        "var(--accent)": dv["colors"]["accent"],
        "var(--accent-muted)": dv["colors"]["accent_muted"],
        "var(--accent-dark)": dv["colors"]["accent_dark"],
        "var(--primary)": dv["colors"]["primary"],
        "var(--secondary)": dv["colors"]["secondary"],
        "var(--surface)": dv["colors"]["surface"],
        "var(--surface-dark)": dv["colors"]["surface_dark"],
        "var(--border)": dv["colors"]["border"],
        "var(--text)": dv["colors"]["text"],
        "var(--text-light)": dv["colors"]["text_light"],
        "var(--text-muted)": dv["colors"]["text_muted"],
        "var(--status-success)": dv["status"]["success"],
        "var(--status-warning)": dv["status"]["warning"],
        "var(--status-danger)": dv["status"]["danger"],
        "var(--status-info)": dv["status"]["info"],
        "var(--font-headers)": dv["fonts"]["headers"],
        "var(--font-body)": dv["fonts"]["body"],
        "var(--font-mono)": dv["fonts"]["mono"],
    }
    config_str = json.dumps(chart_configs)
    for token, value in var_map.items():
        config_str = config_str.replace(token, value)
    # Handle alpha variants like "var(--accent)20"
    config_str = re.sub(r'(#[0-9A-Fa-f]{6})(\d{2})"', r'\g<1>\g<2>"', config_str)
    return json.loads(config_str)


def generate_chart_scripts(chart_configs, dv):
    """Generate Chart.js initialization scripts."""
    resolved = resolve_chart_colors(chart_configs, dv)
    scripts = []
    for cfg in resolved:
        cid = cfg.get("chart_id", "")
        ctype = cfg.get("type", "bar")
        data = json.dumps(cfg.get("data", {}))
        options = json.dumps(cfg.get("options", {}))
        scripts.append(f"""
  (function() {{
    var ctx = document.getElementById('{cid}');
    if (ctx) {{
      new Chart(ctx, {{
        type: '{ctype}',
        data: {data},
        options: {options}
      }});
    }}
  }})();""")
    return '\n'.join(scripts)


def _build_content_line_based(source_path, sections, enrich_by_line, enrich_by_section,
                               chart_configs, svg_dir, dv):
    """Build content HTML with enrichments injected at specific source line positions.

    This approach reads the original markdown line-by-line and injects enrichments
    after their target lines, producing interleaved content rather than stacking
    all enrichments at section boundaries.
    """
    with open(source_path, encoding='utf-8') as f:
        source_lines = f.read().split('\n')

    _, content_start = parse_frontmatter(source_lines)

    # Track which enrichments have been placed (by id)
    placed = set()
    content_parts = []

    # Sort injection lines descending so we process from bottom to top
    # Actually, we process top to bottom and inject after each target line
    for sec in sections:
        if sec["heading"]:
            tag = f'h{sec["level"]}'
            content_parts.append(f'<{tag} id="{sec["id"]}">{convert_inline(sec["heading"])}</{tag}>')

        # Inject summary cards BEFORE section body
        for enr in enrich_by_section.get(sec["id"], []):
            if enr.get("type") == "summary-card" and enr["id"] not in placed:
                content_parts.append(build_enrichment_html(enr, chart_configs, svg_dir, dv))
                placed.add(enr["id"])

        # Process section body line by line, injecting enrichments at target lines
        sec_lines = sec.get("lines", [])
        # Render the section content in blocks, checking for injection points
        # We need to map source line numbers to positions within rendered content
        block_lines = []
        for i, line in enumerate(sec_lines):
            source_line_num = sec["line_start"] + 1 + i  # +1 for heading line
            block_lines.append(line)

            # Check if any enrichment should inject after this source line
            if source_line_num in enrich_by_line:
                # Flush accumulated block lines as rendered HTML
                if block_lines:
                    content_parts.append(_render_block(block_lines))
                    block_lines = []
                # Inject enrichments at this line (skip summary-cards, already placed)
                for enr in enrich_by_line[source_line_num]:
                    if enr["id"] not in placed and enr.get("type") != "summary-card":
                        content_parts.append(
                            build_enrichment_html(enr, chart_configs, svg_dir, dv))
                        placed.add(enr["id"])

        # Flush remaining block lines
        if block_lines:
            content_parts.append(_render_block(block_lines))

        # Fallback: place any unplaced enrichments for this section at the end
        for enr in enrich_by_section.get(sec["id"], []):
            if enr["id"] not in placed:
                content_parts.append(build_enrichment_html(enr, chart_configs, svg_dir, dv))
                placed.add(enr["id"])

    return content_parts


def _build_content_section_based(sections, enrich_by_section, chart_configs, svg_dir, dv):
    """Build content HTML with enrichments at section boundaries (fallback)."""
    content_parts = []
    for sec in sections:
        if sec["heading"]:
            tag = f'h{sec["level"]}'
            content_parts.append(f'<{tag} id="{sec["id"]}">{convert_inline(sec["heading"])}</{tag}>')

        # Summary cards BEFORE content
        pre_enrichments = [e for e in enrich_by_section.get(sec["id"], [])
                          if e.get("type") == "summary-card"]
        for enr in pre_enrichments:
            content_parts.append(build_enrichment_html(enr, chart_configs, svg_dir, dv))

        # Section content
        if sec.get("html"):
            content_parts.append(sec["html"])

        # Charts/diagrams AFTER content
        post_enrichments = [e for e in enrich_by_section.get(sec["id"], [])
                           if e.get("type") != "summary-card"]
        for enr in post_enrichments:
            content_parts.append(build_enrichment_html(enr, chart_configs, svg_dir, dv))

    return content_parts


def generate_html(source_path, enrichment_plan, chart_configs, svg_dir, dv, output_path, language):
    """Main HTML generation function."""
    with open(source_path, encoding='utf-8') as f:
        md_text = f.read()

    fm, sections = markdown_to_html_sections(md_text)
    title = fm.get("title", os.path.splitext(os.path.basename(source_path))[0])
    theme_name = dv.get("theme_name", "default")

    # Build enrichment lookup by source line number for precise placement
    enrichments = enrichment_plan.get("enrichments", [])

    # Index enrichments by target_section AND by injection_after_line
    enrich_by_section = {}  # fallback: section-level placement
    enrich_by_line = {}     # preferred: line-level placement
    for enr in enrichments:
        sec_id = enr.get("target_section", "")
        if sec_id not in enrich_by_section:
            enrich_by_section[sec_id] = []
        enrich_by_section[sec_id].append(enr)

        line = enr.get("injection_after_line")
        if line is not None:
            if line not in enrich_by_line:
                enrich_by_line[line] = []
            enrich_by_line[line].append(enr)

    # If we have line-level injection data, use line-based approach
    if enrich_by_line:
        content_parts = _build_content_line_based(
            source_path, sections, enrich_by_line, enrich_by_section,
            chart_configs, svg_dir, dv
        )
    else:
        # Fallback: section-level injection (original approach)
        content_parts = _build_content_section_based(
            sections, enrich_by_section, chart_configs, svg_dir, dv
        )

    # Remove duplicates — line-based injection may have already placed some enrichments
    content_html = '\n'.join(content_parts)
    nav_html = generate_nav(sections)
    css = generate_css(dv)
    chart_scripts = generate_chart_scripts(chart_configs, dv)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    lang_code = language or fm.get("language", "en")

    # Conditionally include Mermaid CDN when mermaid blocks are present
    has_mermaid = '<pre class="mermaid">' in content_html
    mermaid_script = (
        '\n  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>'
        '\n  <script>mermaid.initialize({startOnLoad: true, theme: "neutral"});</script>'
        if has_mermaid else ''
    )

    html = f"""<!DOCTYPE html>
<html lang="{lang_code}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escape_html(title)}</title>
  <style>{css}</style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>{mermaid_script}
</head>
<body>
<div class="layout">
  <nav class="sidebar">
    <div class="nav-title">Contents</div>
    {nav_html}
  </nav>
  <main class="content">
    <article>
      {content_html}
    </article>
    <footer style="margin-top:64px; padding-top:24px; border-top:1px solid var(--border); font-size:0.8rem; color:var(--text-muted);">
      Enriched by cogni-visual:enrich-report &middot; Theme: {escape_html(theme_name)} &middot; {timestamp}
    </footer>
  </main>
</div>
<script>
  // Chart.js initialization
  document.addEventListener('DOMContentLoaded', function() {{
    {chart_scripts}

    // Scroll spy for navigation
    var navLinks = document.querySelectorAll('.nav-link');
    var sections = [];
    navLinks.forEach(function(link) {{
      var id = link.getAttribute('href').slice(1);
      var el = document.getElementById(id);
      if (el) sections.push({{ id: id, el: el, link: link }});
    }});

    function updateActiveNav() {{
      var scrollY = window.scrollY + 100;
      var active = sections[0];
      for (var i = 0; i < sections.length; i++) {{
        if (sections[i].el.offsetTop <= scrollY) active = sections[i];
      }}
      navLinks.forEach(function(l) {{ l.classList.remove('active'); }});
      if (active) active.link.classList.add('active');
    }}

    window.addEventListener('scroll', updateActiveNav);
    updateActiveNav();
  }});
</script>
</body>
</html>"""

    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

    return output_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate enriched HTML report")
    parser.add_argument("--source", required=True, help="Source markdown report path")
    parser.add_argument("--enrichment-plan", required=True, help="Enrichment plan JSON path")
    parser.add_argument("--chart-configs", default="", help="Chart configs JSON path")
    parser.add_argument("--svg-dir", default="", help="Directory with SVG files (enr-XXX.svg)")
    parser.add_argument("--design-variables", default="", help="Design variables JSON path")
    parser.add_argument("--output", required=True, help="Output HTML path")
    parser.add_argument("--language", default="en", help="Language code (en/de)")
    args = parser.parse_args()

    try:
        dv = load_design_variables(args.design_variables)

        with open(args.enrichment_plan) as f:
            plan = json.load(f)

        chart_configs = []
        if args.chart_configs and os.path.isfile(args.chart_configs):
            with open(args.chart_configs) as f:
                chart_configs = json.load(f)

        out = generate_html(
            source_path=args.source,
            enrichment_plan=plan,
            chart_configs=chart_configs,
            svg_dir=args.svg_dir or "",
            dv=dv,
            output_path=args.output,
            language=args.language,
        )
        print(json.dumps({"status": "ok", "path": out}))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
