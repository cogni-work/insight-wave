#!/usr/bin/env python3
"""Generate a self-contained themed HTML file from a markdown report + enrichment plan.

Two-zone architecture:
  1. Infographic header — editorial visual executive summary (from infographic-data.json)
  2. Report body — full prose with sidebar navigation and sparse illustrations

Usage:
    python3 generate-enriched-report.py \
        --source <report.md> \
        --enrichment-plan <enrichment-plan.json> \
        --design-variables <design-variables.json> \
        --output <output.html> \
        --language <en|de> \
        [--infographic-data <infographic-data.json>] \
        [--svg-dir <path/to/svgs/>] \
        [--density <balanced>]

Chart.js configs are generated internally from enrichment data — no chart-configs.json needed.

Output: Self-contained HTML file with themed report + Chart.js visualizations + inline SVGs.
Returns JSON: {"status": "ok", "path": "<output-path>", "validation": {...}} or {"error": "..."}
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
# Chart.js config generation (from structured enrichment data)
# ---------------------------------------------------------------------------

def _color_palette(dv):
    """Return a list of themed hex colors for chart datasets."""
    c = dv["colors"]
    s = dv["status"]
    return [
        c["accent"], c["primary"], c["secondary"],
        s["info"], s["success"], s["warning"],
        c["accent_muted"], s["danger"],
    ]


def _chart_defaults(dv):
    """Base Chart.js options inherited by all charts."""
    return {
        "responsive": True,
        "maintainAspectRatio": True,
        "plugins": {
            "legend": {
                "position": "bottom",
                "labels": {
                    "font": {"family": dv["fonts"]["body"], "size": 13},
                    "color": dv["colors"]["text"],
                    "padding": 16,
                    "usePointStyle": True,
                },
            },
            "tooltip": {
                "backgroundColor": dv["colors"]["surface_dark"],
                "titleColor": dv["colors"]["text_light"],
                "bodyColor": dv["colors"]["text_light"],
                "cornerRadius": 8,
                "padding": 12,
            },
        },
    }


def generate_chart_config(enrichment, dv):
    """Generate a complete Chart.js config from an enrichment's structured data.

    The LLM extracts data (labels, values, type). This function applies the
    correct Chart.js template, resolves colors from design-variables, and
    returns a ready-to-embed config dict.
    """
    etype = enrichment.get("type", "")
    data = enrichment.get("data", {})
    eid = enrichment.get("id", "enr-000")
    palette = _color_palette(dv)
    defaults = _chart_defaults(dv)

    if etype == "kpi-dashboard":
        return None  # KPI dashboards are custom HTML, not Chart.js

    labels = data.get("labels", [])
    values = data.get("values", [])
    datasets_raw = data.get("datasets", [])
    unit = data.get("unit", "")

    # Extract from legacy data shapes (items[], claims[], stats[], segments[])
    if not labels:
        for key in ("items", "claims", "stats", "segments"):
            items = data.get(key, [])
            if items:
                labels = [it.get("label", "") for it in items]
                values = [it.get("value", 0) for it in items]
                if not unit:
                    unit = items[0].get("unit", "") if items else ""
                break

    if not labels and not datasets_raw:
        return None  # No data to chart

    config = {"chart_id": eid}

    if etype == "comparison-bar":
        config["type"] = "bar"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "label": unit or "Value",
                "data": values,
                "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
                "borderRadius": 6,
            }],
        }
        config["options"] = {
            **defaults,
            "indexAxis": "y",
            "scales": {
                "x": {
                    "beginAtZero": True,
                    "ticks": {
                        "font": {"family": dv["fonts"]["body"], "size": 12},
                        "color": dv["colors"]["text_muted"],
                        "callback_suffix": unit,
                    },
                    "grid": {"color": dv["colors"]["border"], "lineWidth": 0.5},
                },
            },
            "plugins": {**defaults["plugins"], "legend": {"display": False}},
        }

    elif etype == "stat-chart":
        config["type"] = "bar"
        if datasets_raw:
            config["data"] = {
                "labels": labels,
                "datasets": [{
                    "label": ds.get("label", ""),
                    "data": ds.get("values", []),
                    "backgroundColor": palette[i % len(palette)],
                    "borderRadius": 4,
                } for i, ds in enumerate(datasets_raw)],
            }
        else:
            config["data"] = {
                "labels": labels,
                "datasets": [{
                    "label": unit or "Value",
                    "data": values,
                    "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
                    "borderRadius": 6,
                }],
            }
        config["options"] = {
            **defaults,
            "scales": {
                "y": {
                    "beginAtZero": True,
                    "ticks": {
                        "font": {"family": dv["fonts"]["body"], "size": 12},
                        "color": dv["colors"]["text_muted"],
                    },
                    "grid": {"color": dv["colors"]["border"], "lineWidth": 0.5},
                },
            },
        }

    elif etype == "distribution-doughnut":
        config["type"] = "doughnut"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "data": values,
                "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
            }],
        }
        config["options"] = {
            **defaults,
            "plugins": {
                **defaults["plugins"],
                "legend": {**defaults["plugins"]["legend"], "position": "right"},
            },
        }

    elif etype == "timeline-chart":
        config["type"] = "line"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "label": unit or "Events",
                "data": values if values else [1] * len(labels),
                "borderColor": dv["colors"]["accent"],
                "backgroundColor": dv["colors"]["accent"] + "20",
                "pointBackgroundColor": dv["colors"]["accent"],
                "pointRadius": 6,
                "fill": False,
                "tension": 0,
            }],
        }
        config["options"] = {
            **defaults,
            "plugins": {**defaults["plugins"], "legend": {"display": False}},
        }

    elif etype == "horizon-chart":
        config["type"] = "bar"
        # Stacked horizontal
        if datasets_raw:
            config["data"] = {
                "labels": labels,
                "datasets": [{
                    "label": ds.get("label", ""),
                    "data": ds.get("values", []),
                    "backgroundColor": palette[i % len(palette)],
                } for i, ds in enumerate(datasets_raw)],
            }
        else:
            config["data"] = {
                "labels": labels,
                "datasets": [{"data": values, "backgroundColor": palette[0]}],
            }
        config["options"] = {
            **defaults,
            "indexAxis": "y",
            "scales": {
                "x": {"stacked": True, "beginAtZero": True},
                "y": {"stacked": True},
            },
        }

    elif etype in ("theme-radar", "coverage-heatmap"):
        if etype == "theme-radar":
            config["type"] = "radar"
        else:
            config["type"] = "bar"
        if datasets_raw:
            config["data"] = {
                "labels": labels,
                "datasets": [{
                    "label": ds.get("label", ""),
                    "data": ds.get("values", []),
                    "borderColor": palette[i % len(palette)],
                    "backgroundColor": palette[i % len(palette)] + "20",
                    "pointBackgroundColor": palette[i % len(palette)],
                } for i, ds in enumerate(datasets_raw)],
            }
        else:
            config["data"] = {
                "labels": labels,
                "datasets": [{
                    "data": values,
                    "borderColor": palette[0],
                    "backgroundColor": palette[0] + "20",
                    "pointBackgroundColor": palette[0],
                }],
            }
        config["options"] = defaults

    else:
        # Fallback: simple bar chart
        config["type"] = "bar"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "data": values,
                "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
                "borderRadius": 6,
            }],
        }
        config["options"] = {**defaults, "plugins": {**defaults["plugins"], "legend": {"display": False}}}

    return config


# ---------------------------------------------------------------------------
# Enrichment plan validation
# ---------------------------------------------------------------------------

DENSITY_CAPS = {"minimal": 2, "balanced": 5, "rich": 8, "none": 0}
SECTION_CAPS = {"minimal": 1, "balanced": 1, "rich": 2, "none": 0}
INFOGRAPHIC_ONLY_TYPES = {"kpi-dashboard", "stat-chart", "distribution-doughnut",
                          "theme-radar", "coverage-heatmap", "horizon-chart"}


def validate_enrichment_plan(plan, density):
    """Validate and trim enrichment plan to enforce density, type, and spacing rules.

    Returns (validated_enrichments, trimmed_log).
    """
    enrichments = plan.get("enrichments", [])
    density = density or "balanced"
    cap = DENSITY_CAPS.get(density, 5)
    sec_cap = SECTION_CAPS.get(density, 1)
    trimmed = []

    if cap == 0:
        return [], [f"density={density}: all enrichments removed"]

    # Step 1: Remove infographic-only types from report body
    filtered = []
    for enr in enrichments:
        if enr.get("type", "") in INFOGRAPHIC_ONLY_TYPES:
            trimmed.append(f"Moved to infographic: {enr.get('id', '?')} ({enr.get('type', '?')}) — dashboard type")
        else:
            filtered.append(enr)

    # Step 2: Enforce per-section caps
    section_counts = {}
    capped = []
    for enr in sorted(filtered, key=lambda e: e.get("score", 0), reverse=True):
        sec = enr.get("target_section", "")
        section_counts[sec] = section_counts.get(sec, 0) + 1
        if section_counts[sec] <= sec_cap:
            capped.append(enr)
        else:
            trimmed.append(f"Section cap: {enr.get('id', '?')} — section '{sec}' already has {sec_cap} enrichment(s)")

    # Step 3: Enforce total density cap (keep highest-scoring)
    by_score = sorted(capped, key=lambda e: e.get("score", 0), reverse=True)
    kept = by_score[:cap]
    for enr in by_score[cap:]:
        trimmed.append(f"Density cap ({cap}): {enr.get('id', '?')} (score={enr.get('score', 0)})")

    # Step 4: Sort by injection line for proper placement order
    kept.sort(key=lambda e: e.get("injection_after_line", 0))

    return kept, trimmed


# ---------------------------------------------------------------------------
# Enrichment rendering
# ---------------------------------------------------------------------------

def build_enrichment_html(enrichment, svg_dir, dv):
    """Build HTML for a single enrichment based on its type and track."""
    eid = enrichment.get("id", "enr-000")
    etype = enrichment.get("type", "")
    track = enrichment.get("track", "data")

    if track == "data":
        return _build_chart_html(eid, etype, enrichment, dv)
    elif track == "concept":
        return _build_svg_html(eid, etype, enrichment, svg_dir)
    elif track == "html":
        return _build_card_html(eid, etype, enrichment, dv)
    return ''


def _build_chart_html(eid, etype, enrichment, dv):
    """Build HTML for a Chart.js data visualization."""
    if etype == "kpi-dashboard":
        return _build_kpi_html(eid, enrichment, dv)

    # Chart config is generated by generate_chart_config — we just need the canvas
    height = _chart_height(etype, enrichment)
    desc = enrichment.get("description", "")

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
        "horizon-chart": 350,
        "theme-radar": 350,
        "coverage-heatmap": 300,
        "distribution-doughnut": 300,
        "timeline-chart": 200,
        "comparison-bar": 300,
        "stat-chart": 300,
    }
    h = heights.get(etype, 300)
    # Scale bar charts by item count
    data = enrichment.get("data", {})
    items = data.get("items", data.get("labels", []))
    if etype in ("horizon-chart", "comparison-bar") and len(items) > 5:
        h = max(h, len(items) * 50 + 80)
    return min(h, 400)  # Hard cap at 400px in report body


# ---------------------------------------------------------------------------
# Infographic header rendering
# ---------------------------------------------------------------------------

def generate_infographic_header(ig_data, dv):
    """Render an editorial infographic (Economist-style) from infographic-data.json.

    This produces an inline element meant to be inserted AFTER the executive
    summary section in the report body, not as a separate pre-report header.

    Returns (infographic_html, chart_configs_list).
    """
    if not ig_data:
        return '', []

    title = escape_html(ig_data.get("title", ""))
    subtitle = escape_html(ig_data.get("subtitle", ""))
    kpis = ig_data.get("kpis", [])
    charts = ig_data.get("charts", [])
    pullquote = ig_data.get("pullquote")
    comparison = ig_data.get("comparison")
    sources = escape_html(ig_data.get("sources", ""))

    parts = []
    parts.append('<div class="infographic-editorial">')

    # Editorial title
    parts.append(f'<div class="ig-title">{title}</div>')
    if subtitle:
        parts.append(f'<div class="ig-subtitle">{subtitle}</div>')

    # KPI strip — editorial callouts, not cards
    if kpis:
        parts.append('<div class="ig-kpi-strip">')
        for kpi in kpis[:5]:
            val = escape_html(str(kpi.get("value", "")))
            lab = escape_html(str(kpi.get("label", "")))
            src = kpi.get("source", "")
            src_url = kpi.get("source_url", "")
            src_html = ""
            if src and src_url:
                src_html = f'<div class="ig-src"><a href="{escape_html(src_url)}" target="_blank" rel="noopener">{escape_html(src)}</a></div>'
            elif src:
                src_html = f'<div class="ig-src">{escape_html(src)}</div>'
            parts.append(f'''<div class="ig-kpi-item">
  <div class="ig-num">{val}</div>
  <div class="ig-label">{lab}</div>
  {src_html}
</div>''')
        parts.append('</div>')

    # Editorial grid — chart + pullquote + comparison in 3-column layout
    has_content = charts or pullquote or comparison
    if has_content:
        parts.append('<div class="ig-editorial-grid">')

        # Charts
        chart_configs = []
        for i, chart in enumerate(charts[:2]):
            cid = f"ig-chart-{i}"
            chart_title = escape_html(chart.get("title", ""))
            parts.append(f'''<div class="ig-chart-wrap">
  <div class="ig-chart-title">{chart_title}</div>
  <canvas id="{cid}" style="max-height: 240px;"></canvas>
</div>''')
            ig_enr = {
                "id": cid,
                "type": chart.get("type", "comparison-bar"),
                "data": chart.get("data", {}),
            }
            cfg = generate_chart_config(ig_enr, dv)
            if cfg:
                chart_configs.append(cfg)

        # Pull-quote — editorial serif italic
        if pullquote and pullquote.get("text"):
            qt = escape_html(pullquote["text"])
            attr = escape_html(pullquote.get("attribution", ""))
            attr_html = f'<cite>— {attr}</cite>' if attr else ''
            parts.append(f'''<div class="ig-pullquote">
  <blockquote>&ldquo;{qt}&rdquo;</blockquote>
  {attr_html}
</div>''')

        # Comparison — editorial two-column
        if comparison:
            ll = escape_html(comparison.get("left_label", ""))
            rl = escape_html(comparison.get("right_label", ""))
            left = comparison.get("left_items", [])
            right = comparison.get("right_items", [])
            left_html = ''.join(f'<li>{escape_html(it)}</li>' for it in left)
            right_html = ''.join(f'<li>{escape_html(it)}</li>' for it in right)
            parts.append(f'''<div class="ig-comparison">
  <div class="ig-comparison-inner">
    <div>
      <div class="ig-col-label">{ll}</div>
      <ul>{left_html}</ul>
    </div>
    <div>
      <div class="ig-col-label">{rl}</div>
      <ul>{right_html}</ul>
    </div>
  </div>
</div>''')

        # Sources
        if sources:
            parts.append(f'<div class="ig-sources">{sources}</div>')

        parts.append('</div>')  # .ig-editorial-grid

    parts.append('</div>')  # .infographic-editorial

    return '\n'.join(parts), chart_configs if charts else []


# ---------------------------------------------------------------------------
# Content preservation verification
# ---------------------------------------------------------------------------

def _count_words(text):
    """Count words in a text string."""
    return len(re.findall(r'\b\w+\b', text))


def _strip_html_tags(html):
    """Strip HTML tags to get plain text."""
    return re.sub(r'<[^>]+>', ' ', html)


def verify_content_preservation(source_md, output_html):
    """Verify the output HTML preserves the source markdown content.

    Returns dict with pass/fail and diagnostics.
    """
    # Strip frontmatter from source
    lines = source_md.split('\n')
    _, start = parse_frontmatter(lines)
    source_body = '\n'.join(lines[start:])
    source_words = _count_words(source_body)
    source_h2_count = len(re.findall(r'^## ', source_md, re.MULTILINE))

    # Strip infographic header and enrichment containers from HTML
    # Remove infographic header
    html_body = re.sub(
        r'<div class="infographic-header">.*?<div class="infographic-divider"></div>',
        '', output_html, flags=re.DOTALL)
    # Remove enrichment containers
    html_body = re.sub(
        r'<div class="enrichment[^"]*"[^>]*>.*?</div>\s*(?:</div>)?',
        '', html_body, flags=re.DOTALL)
    # Strip tags to get text
    html_text = _strip_html_tags(html_body)
    html_words = _count_words(html_text)

    html_h2_count = len(re.findall(r'<h2\b', output_html))
    html_p_count = len(re.findall(r'<p\b', output_html))

    # Non-empty, non-heading source lines (rough paragraph count)
    source_content_lines = [l for l in lines[start:] if l.strip()
                           and not l.strip().startswith('#')
                           and not l.strip().startswith('---')]
    source_para_estimate = len(source_content_lines)

    word_ratio = html_words / source_words if source_words > 0 else 0
    word_pass = word_ratio >= 0.80
    h2_pass = html_h2_count >= source_h2_count
    p_pass = html_p_count >= source_para_estimate * 0.3  # 30% — paragraphs merge/split

    return {
        "pass": word_pass and h2_pass,
        "source_words": source_words,
        "html_words": html_words,
        "word_ratio": round(word_ratio, 2),
        "word_pass": word_pass,
        "source_h2": source_h2_count,
        "html_h2": html_h2_count,
        "h2_pass": h2_pass,
        "html_p": html_p_count,
        "p_pass": p_pass,
    }


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

/* ========== EDITORIAL INFOGRAPHIC (Economist-style, inline after exec summary) ========== */

.infographic-editorial {{
  max-width: 860px;
  margin: 48px auto 48px;
  padding: 40px 48px;
  background: var(--surface);
  border-top: 3px solid var(--accent);
  border-bottom: 1px solid var(--border);
  page-break-inside: avoid;
}}

/* Pencil-rendered HTML fragment (highest quality path) */
.infographic-pencil-html {{
  padding: 0;
  overflow: hidden;
}}
.infographic-pencil-html .infographic-pencil-fragment {{
  max-width: 100%;
}}

/* Pencil-rendered infographic image */
.infographic-rendered {{
  padding: 0;
  overflow: hidden;
}}
.ig-image {{
  width: 100%;
  height: auto;
  display: block;
  border-radius: var(--radius);
  cursor: zoom-in;
  transition: opacity 0.15s ease;
}}
.ig-image:hover {{
  opacity: 0.92;
}}

/* Full-screen lightbox */
.ig-lightbox {{
  display: none;
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.88);
  align-items: center;
  justify-content: center;
  cursor: zoom-out;
  flex-direction: column;
  padding: 24px;
}}
.ig-lightbox img {{
  max-width: 95vw;
  max-height: 90vh;
  object-fit: contain;
  border-radius: 8px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.4);
}}
.ig-lightbox-hint {{
  color: rgba(255,255,255,0.5);
  font-size: 0.8rem;
  margin-top: 12px;
  letter-spacing: 0.03em;
}}

/* Editorial title — large, assertive, restrained */
.infographic-editorial .ig-title {{
  font-family: var(--font-headers);
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--text);
  line-height: 1.25;
  margin: 0 0 4px;
  letter-spacing: -0.01em;
}}
.infographic-editorial .ig-subtitle {{
  font-size: 0.88rem;
  color: var(--text-muted);
  margin: 0 0 28px;
  letter-spacing: 0.02em;
}}

/* Landscape editorial grid — 3 columns for data density */
.ig-editorial-grid {{
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20px 24px;
  margin-bottom: 24px;
}}

/* KPI callouts — inline editorial style, not cards */
.ig-kpi-strip {{
  grid-column: 1 / -1;
  display: flex;
  gap: 0;
  padding-top: 16px;
  border-bottom: 1px solid var(--border);
  padding-bottom: 20px;
  margin-bottom: 4px;
}}
.ig-kpi-item {{
  flex: 1;
  text-align: left;
  padding: 0 20px;
  border-right: 1px solid var(--border);
}}
.ig-kpi-item:first-child {{ padding-left: 0; }}
.ig-kpi-item:last-child {{ border-right: none; }}
.ig-kpi-item .ig-num {{
  font-family: var(--font-headers);
  font-size: 2.4rem;
  font-weight: 700;
  color: var(--accent-dark);
  line-height: 1.1;
  letter-spacing: -0.02em;
}}
.ig-kpi-item .ig-label {{
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-top: 2px;
  line-height: 1.3;
}}
.ig-kpi-item .ig-src {{
  font-size: 0.7rem;
  color: var(--text-muted);
  margin-top: 4px;
  font-style: italic;
}}
.ig-kpi-item .ig-src a {{ color: var(--accent-dark); text-decoration: none; }}

/* Chart — editorial, no card shadow */
.ig-chart-wrap {{
  padding: 0;
}}
.ig-chart-wrap .ig-chart-title {{
  font-family: var(--font-headers);
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--text);
  margin-bottom: 10px;
}}

/* Pull-quote — editorial italic */
.ig-pullquote {{
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 8px 0;
}}
.ig-pullquote blockquote {{
  font-family: Georgia, 'Times New Roman', serif;
  font-size: 1.05rem;
  font-style: italic;
  color: var(--text);
  line-height: 1.55;
  border-left: 2px solid var(--accent);
  padding: 0 0 0 16px;
  margin: 0;
  background: none;
}}
.ig-pullquote cite {{
  display: block;
  font-size: 0.78rem;
  color: var(--text-muted);
  margin-top: 8px;
  font-style: normal;
  padding-left: 18px;
}}

/* Comparison — editorial two-column */
.ig-comparison {{
  grid-column: span 2;
}}
.ig-comparison-inner {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}}
.ig-col-label {{
  font-family: var(--font-headers);
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--text);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 8px;
  padding-bottom: 4px;
  border-bottom: 2px solid var(--accent);
}}
.ig-comparison ul {{
  list-style: none;
  padding: 0;
  margin: 0;
}}
.ig-comparison li {{
  font-size: 0.82rem;
  padding: 5px 0;
  color: var(--text);
  border-bottom: 1px solid var(--border);
  line-height: 1.4;
}}
.ig-comparison li:last-child {{ border-bottom: none; }}

/* Sources line */
.ig-sources {{
  grid-column: 1 / -1;
  font-size: 0.72rem;
  color: var(--text-muted);
  padding-top: 12px;
  border-top: 1px solid var(--border);
  letter-spacing: 0.02em;
}}

@media (max-width: 768px) {{
  .infographic-editorial {{ padding: 24px 20px; }}
  .ig-editorial-grid {{ grid-template-columns: 1fr; }}
  .ig-kpi-strip {{ flex-direction: column; gap: 16px; }}
  .ig-kpi-item {{ border-right: none; border-bottom: 1px solid var(--border); padding: 0 0 12px; }}
  .ig-kpi-item:last-child {{ border-bottom: none; }}
  .ig-comparison {{ grid-column: span 1; }}
  .ig-comparison-inner {{ grid-template-columns: 1fr; }}
}}

/* ========== REPORT BODY ZONE ========== */

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

/* Enrichments (report body — sparse, visually subordinate) */
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

/* KPI cards (report body — rare, only if density=rich) */
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
  .infographic-inner {{ padding: 0 20px; }}
}}
@media (max-width: 768px) {{
  .kpi-row {{ flex-direction: column; align-items: center; }}
  .kpi-card {{ max-width: 100%; min-width: 0; }}
  .chart-container, .concept-diagram, .summary-card {{ padding: 16px; }}
  h1 {{ font-size: 1.6rem; }}
  h2 {{ font-size: 1.3rem; }}
  .infographic-title {{ font-size: 1.5rem; }}
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


def generate_chart_scripts(chart_configs, dv):
    """Generate Chart.js initialization scripts from config dicts."""
    scripts = []
    for cfg in chart_configs:
        if not cfg:
            continue
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
                               svg_dir, dv):
    """Build content HTML with enrichments injected at specific source line positions."""
    content_parts = []
    chart_configs = []
    placed = set()  # Global across all sections to prevent duplicates

    for sec in sections:
        if sec["heading"]:
            tag = f'h{sec["level"]}'
            content_parts.append(f'<{tag} id="{sec["id"]}">{convert_inline(sec["heading"])}</{tag}>')

        # Inject summary cards BEFORE section body
        for enr in enrich_by_section.get(sec["id"], []):
            if enr.get("type") == "summary-card" and enr["id"] not in placed:
                content_parts.append(build_enrichment_html(enr, svg_dir, dv))
                placed.add(enr["id"])

        # Process section body line by line, injecting enrichments at target lines
        sec_lines = sec.get("lines", [])
        block_lines = []
        for i, line in enumerate(sec_lines):
            source_line_num = sec["line_start"] + 1 + i
            block_lines.append(line)

            if source_line_num in enrich_by_line:
                if block_lines:
                    content_parts.append(_render_block(block_lines))
                    block_lines = []
                for enr in enrich_by_line[source_line_num]:
                    if enr["id"] not in placed and enr.get("type") != "summary-card":
                        content_parts.append(build_enrichment_html(enr, svg_dir, dv))
                        cfg = generate_chart_config(enr, dv)
                        if cfg:
                            chart_configs.append(cfg)
                        placed.add(enr["id"])

        if block_lines:
            content_parts.append(_render_block(block_lines))

        # Fallback: place any unplaced enrichments at section end
        for enr in enrich_by_section.get(sec["id"], []):
            if enr["id"] not in placed:
                content_parts.append(build_enrichment_html(enr, svg_dir, dv))
                cfg = generate_chart_config(enr, dv)
                if cfg:
                    chart_configs.append(cfg)
                placed.add(enr["id"])

    return content_parts, chart_configs


def _build_content_section_based(sections, enrich_by_section, svg_dir, dv):
    """Build content HTML with enrichments at section boundaries (fallback)."""
    content_parts = []
    chart_configs = []

    for sec in sections:
        if sec["heading"]:
            tag = f'h{sec["level"]}'
            content_parts.append(f'<{tag} id="{sec["id"]}">{convert_inline(sec["heading"])}</{tag}>')

        # Summary cards BEFORE content
        for enr in enrich_by_section.get(sec["id"], []):
            if enr.get("type") == "summary-card":
                content_parts.append(build_enrichment_html(enr, svg_dir, dv))

        # Section content
        if sec.get("html"):
            content_parts.append(sec["html"])

        # Charts/diagrams AFTER content
        for enr in enrich_by_section.get(sec["id"], []):
            if enr.get("type") != "summary-card":
                content_parts.append(build_enrichment_html(enr, svg_dir, dv))
                cfg = generate_chart_config(enr, dv)
                if cfg:
                    chart_configs.append(cfg)

    return content_parts, chart_configs


def _generate_infographic_image_html(image_path, output_dir):
    """Embed a Pencil-rendered infographic PNG as base64 for a fully self-contained HTML."""
    import base64
    if not image_path or not os.path.isfile(image_path):
        return ''
    with open(image_path, 'rb') as f:
        img_bytes = f.read()
    b64 = base64.b64encode(img_bytes).decode('ascii')
    ext = os.path.splitext(image_path)[1].lstrip('.').lower()
    mime = {'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'webp': 'image/webp'}.get(ext, 'image/png')
    return f'''<div class="infographic-editorial infographic-rendered">
  <img src="data:{mime};base64,{b64}" alt="Editorial Infographic"
       class="ig-image" onclick="document.getElementById('ig-lightbox').style.display='flex'"
       title="Click for full-screen view">
</div>
<div id="ig-lightbox" class="ig-lightbox" onclick="this.style.display='none'">
  <img src="data:{mime};base64,{b64}" alt="Editorial Infographic (full screen)">
  <div class="ig-lightbox-hint">Click anywhere to close</div>
</div>'''


def _load_infographic_html_fragment(html_path, output_dir):
    """Load a Pencil-rendered HTML fragment for direct injection.

    The fragment is a self-contained <div class="infographic-pencil-fragment">
    with scoped styles — generated by render-infographic-pencil Step 5b from
    the .pen design tree. Highest-quality infographic path: native HTML with
    Pencil's editorial precision, selectable text, and responsive layout.
    """
    if not html_path or not os.path.isfile(html_path):
        return ''
    with open(html_path, encoding='utf-8') as f:
        fragment = f.read().strip()
    if not fragment or len(fragment) < 100:
        return ''
    # Wrap in the editorial container for consistent spacing with other paths
    return f'<div class="infographic-editorial infographic-pencil-html">\n{fragment}\n</div>'


def generate_html(source_path, enrichment_plan, infographic_data, svg_dir, dv,
                  output_path, language, density, infographic_image=None,
                  infographic_html=None):
    """Main HTML generation function — two-zone architecture."""
    with open(source_path, encoding='utf-8') as f:
        md_text = f.read()

    fm, sections = markdown_to_html_sections(md_text)
    title = fm.get("title", os.path.splitext(os.path.basename(source_path))[0])
    theme_name = dv.get("theme_name", "default")

    # Validate enrichment plan — enforce density, type, and spacing rules
    validated_enrichments, trim_log = validate_enrichment_plan(enrichment_plan, density)

    # Index enrichments by target_section AND by injection_after_line
    enrich_by_section = {}
    enrich_by_line = {}
    for enr in validated_enrichments:
        sec_id = enr.get("target_section", "")
        if sec_id not in enrich_by_section:
            enrich_by_section[sec_id] = []
        enrich_by_section[sec_id].append(enr)

        line = enr.get("injection_after_line")
        if line is not None:
            if line not in enrich_by_line:
                enrich_by_line[line] = []
            enrich_by_line[line].append(enr)

    # Build report body content with sparse enrichments
    if enrich_by_line:
        content_parts, report_chart_configs = _build_content_line_based(
            source_path, sections, enrich_by_line, enrich_by_section,
            svg_dir, dv
        )
    else:
        content_parts, report_chart_configs = _build_content_section_based(
            sections, enrich_by_section, svg_dir, dv
        )

    # Build infographic and inject AFTER first H2 section (executive summary)
    # Three-tier priority: Pencil HTML fragment > Pencil PNG > Python-generated HTML
    output_dir = os.path.dirname(output_path) or '.'
    ig_chart_configs = []
    ig_html = _load_infographic_html_fragment(infographic_html, output_dir)
    if not ig_html and infographic_image and os.path.isfile(infographic_image):
        ig_html = _generate_infographic_image_html(infographic_image, output_dir)
    if not ig_html:
        ig_html, ig_chart_configs = generate_infographic_header(infographic_data, dv)

    if ig_html:
        # Find the boundary between the first H2 section and the second H2 section
        # Insert infographic at that boundary so it appears after the executive summary
        first_h2_end = -1
        h2_count = 0
        for i, part in enumerate(content_parts):
            if '<h2 ' in part:
                h2_count += 1
                if h2_count == 2:
                    first_h2_end = i
                    break
        if first_h2_end > 0:
            content_parts.insert(first_h2_end, ig_html)
        else:
            # Fallback: put at the end of all content if only 1 H2
            content_parts.append(ig_html)

    # Combine all chart configs (infographic + report body)
    all_chart_configs = ig_chart_configs + report_chart_configs

    content_html = '\n'.join(content_parts)
    nav_html = generate_nav(sections)
    css = generate_css(dv)
    chart_scripts = generate_chart_scripts(all_chart_configs, dv)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    lang_code = language or fm.get("language", "en")

    # Conditionally include Mermaid CDN
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

    # Content preservation verification
    validation = verify_content_preservation(md_text, html)

    return output_path, validation, trim_log


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate enriched HTML report (two-zone architecture)")
    parser.add_argument("--source", required=True, help="Source markdown report path")
    parser.add_argument("--enrichment-plan", required=True, help="Enrichment plan JSON path")
    parser.add_argument("--infographic-data", default="", help="Infographic data JSON path (optional)")
    parser.add_argument("--svg-dir", default="", help="Directory with SVG files (enr-XXX.svg)")
    parser.add_argument("--design-variables", default="", help="Design variables JSON path")
    parser.add_argument("--output", required=True, help="Output HTML path")
    parser.add_argument("--language", default="en", help="Language code (en/de)")
    parser.add_argument("--density", default="balanced", help="Enrichment density (none/minimal/balanced/rich)")
    parser.add_argument("--infographic-image", default="", help="Pencil-rendered infographic PNG (fallback when HTML fragment unavailable)")
    parser.add_argument("--infographic-html", default="", help="Pencil-rendered HTML fragment (highest quality, preferred over PNG and JSON)")
    # Legacy support: --chart-configs is accepted but ignored (configs generated internally)
    parser.add_argument("--chart-configs", default="", help=argparse.SUPPRESS)
    args = parser.parse_args()

    try:
        dv = load_design_variables(args.design_variables)

        with open(args.enrichment_plan) as f:
            plan = json.load(f)

        ig_data = None
        if args.infographic_data and os.path.isfile(args.infographic_data):
            with open(args.infographic_data) as f:
                ig_data = json.load(f)

        out, validation, trim_log = generate_html(
            source_path=args.source,
            enrichment_plan=plan,
            infographic_data=ig_data,
            svg_dir=args.svg_dir or "",
            dv=dv,
            output_path=args.output,
            language=args.language,
            density=args.density,
            infographic_image=args.infographic_image or None,
            infographic_html=args.infographic_html or None,
        )

        result = {
            "status": "ok",
            "path": out,
            "validation": validation,
        }
        if trim_log:
            result["trimmed"] = trim_log

        print(json.dumps(result, indent=2))

        if not validation["pass"]:
            print(f"\nWARNING: Content preservation check failed!", file=sys.stderr)
            print(f"  Word ratio: {validation['word_ratio']} (need >= 0.80)", file=sys.stderr)
            print(f"  Source H2: {validation['source_h2']}, HTML H2: {validation['html_h2']}", file=sys.stderr)

    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
