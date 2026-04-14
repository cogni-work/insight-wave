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

    If the enrichment contains a `chart_config` field with a pre-built Chart.js
    config (type + data + options), use it directly — the LLM crafted a richer
    config than our templates can produce. Otherwise, fall back to template
    generation from the `data` field.
    """
    etype = enrichment.get("type", "")
    data = enrichment.get("data", {})
    eid = enrichment.get("id", "enr-000")

    # LLM-crafted config: use verbatim (preferred path)
    if "chart_config" in enrichment and enrichment["chart_config"]:
        cfg = enrichment["chart_config"]
        cfg["chart_id"] = eid
        return cfg

    palette = _color_palette(dv)
    defaults = _chart_defaults(dv)

    if etype == "kpi-dashboard":
        return None  # KPI dashboards are custom HTML, not Chart.js

    labels = data.get("labels", [])
    values = data.get("values", [])
    datasets_raw = data.get("datasets", [])
    unit = data.get("unit", "")

    # Timeline-chart: extract from milestones[] or events[] (date→label, constant Y)
    if etype == "timeline-chart" and not labels:
        for key in ("milestones", "events"):
            items = data.get(key, [])
            if items:
                labels = [it.get("date", it.get("label", "")) for it in items]
                values = [1] * len(items)
                data["_milestone_labels"] = [it.get("label", "") for it in items]
                data["_milestone_categories"] = [it.get("category", "") for it in items]
                break

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
        chart_title = data.get("chart_title", "")
        axis_label = data.get("axis_label", data.get("x_label", unit or ""))
        # Extract sublabels for richer tooltips
        sublabels = []
        for key in ("items", "claims", "stats", "segments"):
            for it in data.get(key, []):
                sublabels.append(it.get("sublabel", ""))
        config["type"] = "bar"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "label": axis_label or "Value",
                "data": values,
                "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
                "borderColor": [palette[i % len(palette)] for i in range(len(values))],
                "borderWidth": 1,
                "borderRadius": 6,
                "barPercentage": 0.7,
            }],
        }
        config["options"] = {
            **defaults,
            "indexAxis": "y",
            "scales": {
                "x": {
                    "beginAtZero": True,
                    "title": {"display": bool(axis_label), "text": axis_label,
                              "font": {"family": dv["fonts"]["body"], "size": 12, "weight": "bold"},
                              "color": dv["colors"]["text_muted"]},
                    "ticks": {
                        "font": {"family": dv["fonts"]["body"], "size": 12},
                        "color": dv["colors"]["text_muted"],
                    },
                    "grid": {"color": dv["colors"]["border"], "lineWidth": 0.5},
                },
                "y": {
                    "ticks": {
                        "font": {"family": dv["fonts"]["body"], "size": 13, "weight": "bold"},
                        "color": dv["colors"]["text"],
                    },
                    "grid": {"display": False},
                },
            },
            "plugins": {
                **defaults["plugins"],
                "legend": {"display": False},
                "title": {"display": bool(chart_title), "text": chart_title,
                          "font": {"family": dv["fonts"]["headers"], "size": 15, "weight": "bold"},
                          "color": dv["colors"]["text"], "padding": {"bottom": 16}},
                "tooltip": {
                    **defaults["plugins"].get("tooltip", {}),
                    "callbacks": {
                        "afterLabel": f"function(ctx) {{ var subs = {json.dumps(sublabels, ensure_ascii=False)}; return subs[ctx.dataIndex] || ''; }}"
                    } if any(sublabels) else {},
                },
            },
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
        chart_title = data.get("title", data.get("chart_title", ""))
        config["type"] = "doughnut"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "data": values,
                "backgroundColor": [palette[i % len(palette)] for i in range(len(values))],
                "borderWidth": 2,
                "borderColor": dv["colors"]["background"],
                "hoverOffset": 8,
            }],
        }
        config["options"] = {
            **defaults,
            "cutout": "55%",
            "plugins": {
                **defaults["plugins"],
                "legend": {**defaults["plugins"]["legend"], "position": "right",
                           "labels": {**defaults["plugins"]["legend"]["labels"],
                                      "usePointStyle": True, "pointStyle": "rectRounded",
                                      "padding": 14}},
                "title": {"display": bool(chart_title), "text": chart_title,
                          "font": {"family": dv["fonts"]["headers"], "size": 15, "weight": "bold"},
                          "color": dv["colors"]["text"], "padding": {"bottom": 12}},
            },
        }

    elif etype == "timeline-chart":
        # Category-based point coloring and grouping
        categories = data.get("_milestone_categories", [])
        milestone_labels = data.get("_milestone_labels", labels)
        chart_title = data.get("chart_title", "")
        category_colors = {
            "regulatory": dv["status"]["warning"],
            "strategic": dv["colors"]["accent"],
            "market": dv["status"]["info"],
            "technical": dv["status"]["success"],
            "fiscal": dv["status"]["danger"],
        }
        default_color = dv["colors"]["accent"]
        point_colors = [
            category_colors.get(cat, default_color) for cat in categories
        ] if categories else [default_color] * len(labels)

        # Stagger Y positions to avoid overlapping labels (alternate between rows)
        y_positions = [(i % 3) for i in range(len(labels))]

        config["type"] = "line"
        config["data"] = {
            "labels": labels,
            "datasets": [{
                "label": "Milestones",
                "data": y_positions if len(labels) > 3 else [1] * len(labels),
                "borderColor": dv["colors"]["accent"] + "30",
                "backgroundColor": dv["colors"]["accent"] + "10",
                "pointBackgroundColor": point_colors,
                "pointBorderColor": point_colors,
                "pointBorderWidth": 2,
                "pointRadius": 10,
                "pointHoverRadius": 13,
                "pointStyle": "circle",
                "showLine": True,
                "borderWidth": 2,
                "borderDash": [6, 4],
                "fill": False,
                "tension": 0.2,
            }],
        }
        config["options"] = {
            **defaults,
            "scales": {
                "y": {"display": False, "min": -1, "max": 4},
                "x": {
                    "title": {"display": bool(chart_title), "text": chart_title,
                              "font": {"family": dv["fonts"]["headers"], "size": 13, "weight": "bold"},
                              "color": dv["colors"]["text_muted"]},
                    "ticks": {
                        "font": {"family": dv["fonts"]["body"], "size": 11, "weight": "bold"},
                        "color": dv["colors"]["text"],
                        "maxRotation": 45,
                    },
                    "grid": {"color": dv["colors"]["border"] + "40", "lineWidth": 1,
                             "drawTicks": True, "tickLength": 8},
                },
            },
            "plugins": {
                **defaults["plugins"],
                "legend": {"display": False},
                "title": {"display": bool(chart_title), "text": chart_title,
                          "font": {"family": dv["fonts"]["headers"], "size": 15, "weight": "bold"},
                          "color": dv["colors"]["text"], "padding": {"bottom": 12}},
                "tooltip": {
                    **defaults["plugins"].get("tooltip", {}),
                    "displayColors": False,
                    "callbacks": {
                        "title": f"function(items) {{ return items[0].label; }}",
                        "label": f"function(ctx) {{ var labels = {json.dumps(milestone_labels, ensure_ascii=False)}; var cats = {json.dumps(categories, ensure_ascii=False)}; var l = labels[ctx.dataIndex] || ''; var c = cats[ctx.dataIndex] ? ' [' + cats[ctx.dataIndex] + ']' : ''; return l + c; }}"
                    },
                },
            },
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
        "horizon-chart": 380,
        "theme-radar": 380,
        "coverage-heatmap": 320,
        "distribution-doughnut": 340,
        "timeline-chart": 280,
        "comparison-bar": 320,
        "stat-chart": 320,
    }
    h = heights.get(etype, 320)
    # Scale bar charts by item count
    data = enrichment.get("data", {})
    items = data.get("items", data.get("labels", []))
    if etype in ("horizon-chart", "comparison-bar") and len(items) > 5:
        h = max(h, len(items) * 55 + 100)
    return min(h, 450)  # Hard cap at 450px in report body


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
    # Normalize: bare URL → @import so it works inside <style>
    if gf and not gf.strip().startswith("@import") and not gf.strip().startswith("<"):
        gf = f"@import url('{gf.strip()}');"

    # Derive brand-accent: use primary if it's a chromatic color, else fall back to accent
    primary_hex = c['primary']
    r, g, b = int(primary_hex[1:3], 16), int(primary_hex[3:5], 16), int(primary_hex[5:7], 16)
    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    brand_accent = primary_hex if 0.1 < lum < 0.85 else c['accent']

    return f"""{gf}

:root {{
  --primary: {c['primary']};
  --secondary: {c['secondary']};
  --accent: {c['accent']};
  --accent-muted: {c['accent_muted']};
  --accent-dark: {c['accent_dark']};
  --brand-accent: {brand_accent};
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
  border-top: 3px solid var(--brand-accent);
  border-bottom: 1px solid var(--border);
  page-break-inside: avoid;
}}

/* Pencil-rendered HTML fragment (fallback when PNG unavailable) */
.infographic-pencil-html {{
  max-width: 1080px;
  padding: 0;
  overflow: hidden;
}}
.infographic-pencil-html .infographic-pencil-fragment {{
  max-width: 100%;
}}

/* Pencil-rendered infographic image (pixel-perfect, preferred path) */
.infographic-rendered {{
  max-width: 1080px;
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
  border-left: 2px solid var(--brand-accent);
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
  border-bottom: 2px solid var(--brand-accent);
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
nav.sidebar a.active {{ background: var(--brand-accent); color: var(--surface-dark); font-weight: 500; }}
nav.sidebar a.depth-3 {{ padding-left: 28px; font-size: 0.8rem; }}
nav.sidebar a.depth-4 {{ padding-left: 44px; font-size: 0.75rem; }}

main.content {{
  flex: 1; max-width: 860px; margin: 0 auto; padding: 48px 40px;
}}

/* Typography */
h1 {{ font-family: var(--font-headers); font-size: 2.2rem; font-weight: 700; margin: 0 0 24px; line-height: 1.2; }}
h2 {{ font-family: var(--font-headers); font-size: 1.6rem; font-weight: 600; margin: 48px 0 16px; line-height: 1.3;
      padding-bottom: 8px; border-bottom: 2px solid var(--brand-accent); }}
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
blockquote {{ border-left: 4px solid var(--brand-accent); padding: 12px 20px; margin: 16px 0; background: var(--bg);
             border-radius: 0 var(--radius) var(--radius) 0; font-style: italic; color: var(--text);
             box-shadow: 0 1px 3px rgba(0,0,0,0.06); }}
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
  box-shadow: var(--shadow-sm); border-top: 3px solid var(--brand-accent);
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
  background: var(--bg); border-radius: var(--radius);
  border-left: 4px solid var(--brand-accent);
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
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
        # Unquote JavaScript function strings for Chart.js callbacks.
        # json.dumps wraps them in quotes and escapes inner quotes as \".
        # We need to: (1) remove the outer quotes, (2) unescape inner \".
        def _unquote_js_func(m):
            body = m.group(1).replace('\\"', '"')
            return body
        options = re.sub(r'"(function\(.*?\)\s*\{.*?\})"', _unquote_js_func, options)
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
    """Embed a Pencil-rendered infographic PNG as a magazine-style peek strip.

    A vertical strip on the right edge shows a sliver of the infographic —
    like a magazine page peeking out. Clicking it triggers a 3D page-turn
    unfold animation revealing the full infographic panel. Click the overlay,
    the X button, or press Escape to fold it back. Click the image for
    full-screen lightbox.
    """
    import base64
    if not image_path or not os.path.isfile(image_path):
        return ''
    with open(image_path, 'rb') as f:
        img_bytes = f.read()
    b64 = base64.b64encode(img_bytes).decode('ascii')
    ext = os.path.splitext(image_path)[1].lstrip('.').lower()
    mime = {'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'webp': 'image/webp'}.get(ext, 'image/png')
    return f'''<!-- Infographic: magazine peek strip with page-turn unfold -->
<style>
  .ig-mag-wrapper {{
    position: fixed;
    top: 0; right: 0;
    height: 100vh;
    z-index: 9998;
    pointer-events: none;
  }}
  /* Peek strip: thumbnail + label on right edge, like a magazine page tab */
  .ig-mag-peek {{
    position: absolute;
    top: 50%;
    right: 0;
    transform: translateY(-50%);
    width: 140px;
    cursor: pointer;
    pointer-events: auto;
    background: #ffffff;
    border-radius: 12px 0 0 12px;
    box-shadow: -4px 2px 20px rgba(0,0,0,0.15);
    border: 1px solid rgba(0,0,0,0.08);
    border-right: none;
    padding: 12px 10px 14px 12px;
    transition: width 0.3s ease, box-shadow 0.3s ease, transform 0.3s ease;
  }}
  .ig-mag-peek:hover {{
    width: 170px;
    box-shadow: -6px 4px 32px rgba(0,0,0,0.22);
    transform: translateY(-50%) translateX(-8px);
  }}
  .ig-mag-peek img {{
    width: 100%;
    height: auto;
    border-radius: 6px;
    pointer-events: none;
    box-shadow: 0 1px 6px rgba(0,0,0,0.1);
  }}
  .ig-mag-peek-label {{
    display: block;
    text-align: center;
    margin-top: 8px;
    font: 700 11px/1.2 system-ui, -apple-system, sans-serif;
    color: #E20074;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }}
  /* Overlay */
  .ig-mag-overlay {{
    display: none;
    position: fixed;
    inset: 0;
    z-index: 9990;
    background: rgba(0,0,0,0.25);
  }}
  .ig-mag-overlay.open {{ display: block; }}
  /* The page panel — slides in from right to fill content area beside sidebar */
  .ig-mag-page {{
    position: fixed;
    top: 0;
    right: 0;
    left: 260px;
    height: 100vh;
    z-index: 9999;
    background: #ffffff;
    box-shadow: -6px 0 40px rgba(0,0,0,0.25);
    overflow-y: auto;
    padding: 28px 40px 48px;
    transform: translateX(100%);
    transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    pointer-events: auto;
  }}
  .ig-mag-page.open {{
    transform: translateX(0);
  }}
  .ig-mag-page-close {{
    position: sticky;
    top: 0; float: right;
    background: #333; color: #fff;
    border: none; border-radius: 50%;
    width: 36px; height: 36px;
    font-size: 20px; cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    z-index: 1;
  }}
  .ig-mag-page-close:hover {{ background: #E20074; }}
  .ig-mag-page-img-wrap {{
    margin-top: 8px;
    overflow: auto;
    height: calc(100vh - 120px);
    border-radius: 6px;
    cursor: grab;
    position: relative;
    display: flex;
    align-items: flex-start;
    justify-content: center;
  }}
  .ig-mag-page-img-wrap:active {{ cursor: grabbing; }}
  .ig-mag-page-img-wrap img {{
    max-height: calc(100vh - 130px);
    width: auto;
    max-width: none;
    border-radius: 6px;
    transform-origin: top center;
    transition: transform 0.2s ease;
    display: block;
  }}
  .ig-mag-zoom-controls {{
    display: flex;
    gap: 6px;
    justify-content: flex-end;
    margin-bottom: 4px;
    z-index: 2;
  }}
  .ig-mag-zoom-btn {{
    background: #333; color: #fff;
    border: none; border-radius: 6px;
    width: 36px; height: 32px;
    font-size: 18px; cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 2px 6px rgba(0,0,0,0.15);
  }}
  .ig-mag-zoom-btn:hover {{ background: #E20074; }}
  /* Hide peek strip when page is open */
  .ig-mag-wrapper.open .ig-mag-peek {{ opacity: 0; pointer-events: none; }}
  @media (max-width: 1024px) {{
    .ig-mag-page {{ left: 0; }}
  }}
  @media (max-width: 768px) {{
    .ig-mag-peek {{ width: 48px; }}
    .ig-mag-peek:hover {{ width: 64px; }}
    .ig-mag-page {{ left: 0; padding: 20px 16px 40px; }}
  }}
</style>
<div class="ig-mag-wrapper" id="ig-mag-wrapper">
  <div class="ig-mag-peek" onclick="document.getElementById('ig-mag-wrapper').classList.add('open');document.querySelector('.ig-mag-page').classList.add('open');document.querySelector('.ig-mag-overlay').classList.add('open');" title="Click to view infographic">
    <img src="data:{mime};base64,{b64}" alt="Infographic preview">
    <span class="ig-mag-peek-label">&#9664; Infographic</span>
  </div>
  <div class="ig-mag-page">
    <button class="ig-mag-page-close" onclick="igClosePanel()" title="Close">&times;</button>
    <div class="ig-mag-zoom-controls">
      <button class="ig-mag-zoom-btn" onclick="igZoom(-1)" title="Zoom out">&minus;</button>
      <button class="ig-mag-zoom-btn" onclick="igZoom(0)" title="Fit to panel">&#8596;</button>
      <button class="ig-mag-zoom-btn" onclick="igZoom(1)" title="Zoom in">+</button>
      <button class="ig-mag-zoom-btn" onclick="document.getElementById('enrich-ig-lightbox').style.display='flex';" title="Full screen">&#x26F6;</button>
    </div>
    <div class="ig-mag-page-img-wrap" id="ig-mag-img-wrap">
      <img src="data:{mime};base64,{b64}" alt="Editorial Infographic" id="ig-mag-img">
    </div>
  </div>
</div>
<div class="ig-mag-overlay" onclick="igClosePanel()"></div>
<div id="enrich-ig-lightbox" style="display:none;position:fixed;inset:0;z-index:10001;background:rgba(0,0,0,0.95);align-items:center;justify-content:center;cursor:zoom-out;padding:24px;" onclick="this.style.display='none'">
  <img src="data:{mime};base64,{b64}" alt="Editorial Infographic (full screen)"
       style="max-height:95vh;max-width:95vw;border-radius:8px;">
  <div style="position:absolute;bottom:24px;left:50%;transform:translateX(-50%);color:#fff;font-size:13px;opacity:0.5;">Click anywhere to close</div>
</div>
<script>
(function(){{
  var scale=1, minScale=0.5, maxScale=5;
  var img=document.getElementById('ig-mag-img');
  var wrap=document.getElementById('ig-mag-img-wrap');
  function applyZoom(){{
    img.style.transform='scale('+scale+')';
    img.style.transformOrigin='top center';
    if(scale>1.05){{ wrap.style.overflow='auto'; wrap.style.cursor='grab'; }}
    else{{ wrap.style.overflow='hidden'; wrap.style.cursor='default'; }}
  }}
  window.igZoom=function(dir){{
    if(dir===0){{ scale=1; }}
    else{{ scale=Math.min(maxScale,Math.max(minScale,scale+(dir*0.4))); }}
    applyZoom();
  }};
  /* Scroll-wheel zoom */
  wrap.addEventListener('wheel',function(e){{
    if(!document.querySelector('.ig-mag-page.open')) return;
    e.preventDefault();
    igZoom(e.deltaY<0?1:-1);
  }},{{passive:false}});
  /* Escape + close reset */
  function closePanel(){{
    document.getElementById('ig-mag-wrapper').classList.remove('open');
    document.querySelector('.ig-mag-page').classList.remove('open');
    document.querySelector('.ig-mag-overlay').classList.remove('open');
    document.getElementById('enrich-ig-lightbox').style.display='none';
    scale=1; applyZoom();
  }}
  document.addEventListener('keydown',function(e){{ if(e.key==='Escape') closePanel(); }});
  /* Expose for close buttons */
  window.igClosePanel=closePanel;
}})();
</script>'''


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
    # Three-tier priority: HTML fragment (responsive, selectable) > Pencil PNG (pixel-perfect) > Python-generated HTML (legacy)
    output_dir = os.path.dirname(output_path) or '.'
    ig_chart_configs = []
    ig_html = _load_infographic_html_fragment(infographic_html, output_dir)
    if not ig_html:
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
# Flipbook Assembly (scroll HTML → flipbook HTML)
# ---------------------------------------------------------------------------

FLIPBOOK_CSS = """\
/* Flipbook-specific tokens */
:root {
  --page-width: min(48vw, 520px);
  --page-height: min(92vh, 700px);
  --page-ratio: 1 / 1.35;
  --page-padding: 48px 40px;
  --spine-width: 2px;
  --turn-duration: 0.8s;
  --turn-easing: cubic-bezier(0.645, 0.045, 0.355, 1);
}

.flipbook {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  perspective: 2000px;
  perspective-origin: center center;
  background: var(--bg);
  transition: opacity 0.3s ease;
}
.flipbook.ready { opacity: 1 !important; }

.spread {
  display: flex;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.1s ease;
  width: calc(var(--page-width) * 2 + var(--spine-width));
  height: var(--page-height);
}
.spread.active { opacity: 1; pointer-events: auto; z-index: 2; }
.spread.next { opacity: 1; z-index: 1; }

.spread .page-left,
.spread .page-right {
  width: var(--page-width);
  height: var(--page-height);
  overflow: hidden;
  background: var(--surface);
  box-shadow: var(--shadow-lg);
}
.spread .page-left {
  border-radius: var(--radius) 0 0 var(--radius);
  border-right: var(--spine-width) solid var(--border);
}
.spread .page-right { border-radius: 0 var(--radius) var(--radius) 0; }

.page-inner {
  padding: var(--page-padding);
  height: 100%;
  overflow: hidden;
  font-family: var(--font-body);
  font-size: 0.95rem;
  line-height: 1.7;
  color: var(--text);
}
.page-inner h2 {
  font-family: var(--font-headers);
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0 0 16px 0;
  padding-bottom: 8px;
  border-bottom: 2px solid var(--accent);
  color: var(--primary);
}
.page-inner h3 {
  font-family: var(--font-headers);
  font-size: 1.15rem;
  font-weight: 600;
  margin: 16px 0 8px 0;
  color: var(--primary);
}
.page-inner p { margin: 0 0 12px 0; }
.page-inner blockquote {
  margin: 12px 0;
  padding: 8px 16px;
  border-left: 3px solid var(--accent);
  background: var(--surface2);
  border-radius: 0 var(--radius) var(--radius) 0;
  font-style: italic;
}

.page-number {
  position: absolute;
  bottom: 16px;
  font-family: var(--font-body);
  font-size: 0.8rem;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
}
.page-left .page-number { left: 40px; }
.page-right .page-number { right: 40px; }

.page-cover .page-inner {
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.cover-title {
  font-family: var(--font-headers);
  font-size: 2rem;
  font-weight: 700;
  line-height: 1.2;
  margin: 0 0 24px 0;
  color: var(--primary);
  border-bottom: 3px solid var(--accent);
  padding-bottom: 16px;
}
.cover-summary { font-size: 1rem; line-height: 1.8; color: var(--text); }
.cover-meta {
  margin-top: auto;
  padding-top: 24px;
  font-size: 0.85rem;
  color: var(--text-muted);
  border-top: 1px solid var(--border);
}

.page-infographic { padding: 0; overflow: hidden; }
.page-infographic .infographic-editorial {
  width: 100%; height: 100%; object-fit: contain;
}
.page-infographic .infographic-pencil-html { transform-origin: top left; }
.page-infographic .infographic-rendered img {
  width: 100%; height: 100%; object-fit: contain;
}

.page-inner .chart-container { max-width: 100%; margin: 16px 0; }
.page-inner .chart-container canvas { max-height: 55%; }
.page-inner .concept-diagram { max-width: 100%; margin: 16px 0; }
.page-inner .concept-diagram svg { width: 100%; height: auto; max-height: 50%; }
.page-inner .summary-card {
  margin: 12px 0;
  padding: 12px 16px;
  background: var(--surface2);
  border-left: 3px solid var(--accent);
  border-radius: 0 var(--radius) var(--radius) 0;
}

/* 3D page-curl animation */
.spread.active.turning-forward .page-right {
  transform-origin: left center;
  transform: rotateY(-180deg);
  transition: transform var(--turn-duration) var(--turn-easing);
  z-index: 10;
}
.spread.active.turning-forward .page-right::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to left, rgba(0,0,0,0.15) 0%, transparent 40%);
  opacity: 1;
  transition: opacity var(--turn-duration) var(--turn-easing);
}
.spread.next.turning-backward .page-left {
  transform-origin: right center;
  transform: rotateY(180deg);
  transition: transform var(--turn-duration) var(--turn-easing);
  z-index: 10;
}
.spread.next.turning-backward .page-left::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to right, rgba(0,0,0,0.15) 0%, transparent 40%);
  opacity: 1;
  transition: opacity var(--turn-duration) var(--turn-easing);
}

/* Navigation */
.flipbook-nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: rgba(255,255,255,0.85);
  backdrop-filter: blur(12px);
  border-radius: 24px;
  box-shadow: var(--shadow-md);
  z-index: 100;
  font-family: var(--font-body);
}
.nav-btn {
  width: 36px; height: 36px;
  border: none; border-radius: 50%;
  background: var(--surface); color: var(--text);
  cursor: pointer; display: flex;
  align-items: center; justify-content: center;
  font-size: 1rem;
  transition: background 0.2s, transform 0.15s;
}
.nav-btn:hover { background: var(--accent); color: var(--primary); transform: scale(1.08); }
.nav-counter {
  font-size: 0.85rem; color: var(--text-muted);
  font-variant-numeric: tabular-nums;
  min-width: 80px; text-align: center;
}

/* Progress bar */
.flipbook-progress {
  position: fixed; top: 0; left: 0; width: 100%; height: 3px;
  background: var(--border); z-index: 100;
}
.flipbook-progress-bar {
  height: 100%; background: var(--accent);
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1); width: 0%;
}

/* ToC overlay */
.toc-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  opacity: 0; pointer-events: none;
  transition: opacity 0.3s ease; z-index: 200;
}
.toc-overlay.open { opacity: 1; pointer-events: auto; }
.toc-panel {
  position: absolute; right: 0; top: 0; bottom: 0;
  width: min(360px, 80vw);
  background: var(--surface); padding: 24px;
  overflow-y: auto;
  transform: translateX(100%); transition: transform 0.3s ease;
  box-shadow: var(--shadow-xl);
}
.toc-overlay.open .toc-panel { transform: translateX(0); }
.toc-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 16px; padding-bottom: 12px;
  border-bottom: 2px solid var(--accent);
}
.toc-title {
  font-family: var(--font-headers); font-size: 1.2rem;
  font-weight: 600; color: var(--primary);
}
.toc-close { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-muted); }
.toc-list a {
  display: flex; justify-content: space-between;
  padding: 8px 0; text-decoration: none; color: var(--text);
  border-bottom: 1px solid var(--border); font-size: 0.9rem;
  transition: color 0.15s;
}
.toc-list a:hover { color: var(--accent-dark); }
.toc-list a.toc-h3 { padding-left: 16px; font-size: 0.85rem; color: var(--text-muted); }
.toc-list a span { color: var(--text-muted); font-variant-numeric: tabular-nums; font-size: 0.8rem; }
.toc-list a.active { color: var(--accent-dark); font-weight: 500; }

/* Help overlay */
.help-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  opacity: 0; pointer-events: none;
  transition: opacity 0.3s ease; z-index: 200;
  display: flex; align-items: center; justify-content: center;
}
.help-overlay.open { opacity: 1; pointer-events: auto; }
.help-panel {
  background: var(--surface); padding: 32px;
  border-radius: var(--radius); max-width: 400px; width: 90%;
  box-shadow: var(--shadow-xl);
}
.help-panel h3 { margin: 0 0 16px 0; font-family: var(--font-headers); }
.help-panel table { width: 100%; border-collapse: collapse; }
.help-panel td { padding: 6px 8px; border-bottom: 1px solid var(--border); font-size: 0.9rem; }
.help-panel kbd {
  background: var(--surface2); padding: 2px 6px;
  border-radius: 4px; font-size: 0.85rem;
  border: 1px solid var(--border);
}
.help-close {
  margin-top: 16px; padding: 8px 24px;
  background: var(--accent); color: var(--primary);
  border: none; border-radius: 8px; cursor: pointer;
  font-weight: 500;
}

/* Loading indicator */
.flipbook-loader {
  position: fixed; inset: 0;
  display: flex; flex-direction: column;
  justify-content: center; align-items: center; gap: 16px;
  background: var(--bg); z-index: 300;
  transition: opacity 0.3s ease;
}
.flipbook-loader.hidden { opacity: 0; pointer-events: none; }
.loader-spinner {
  width: 40px; height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.loader-text { font-family: var(--font-body); font-size: 0.9rem; color: var(--text-muted); }

/* Responsive: tablet single-page */
@media (max-width: 1024px) {
  :root { --page-width: min(90vw, 520px); }
  .spread { width: var(--page-width); }
  .spread .page-left,
  .spread .page-right {
    width: 100%; border-radius: var(--radius); border-right: none;
  }
}
/* Responsive: mobile */
@media (max-width: 768px) {
  :root { --page-width: calc(100vw - 32px); --page-padding: 32px 24px; }
  .flipbook-nav { bottom: 16px; padding: 6px 12px; gap: 8px; }
  .nav-btn { width: 32px; height: 32px; }
  .page-inner h2 { font-size: 1.3rem; }
  .cover-title { font-size: 1.6rem; }
}
"""

FLIPBOOK_JS = """\
document.addEventListener('DOMContentLoaded', function() {
  var stream = document.getElementById('content-stream');
  var flipbook = document.getElementById('flipbook');
  var blocks = Array.from(stream.querySelectorAll('.block'));

  var isMobile = window.innerWidth <= 1024;
  var pageHeight = computePageHeight();
  var contentHeight = pageHeight - 96;

  var pages = [];
  var coverPage = document.querySelector('.page-cover');
  var infographicPage = document.querySelector('.page-infographic');
  pages.push(coverPage);
  pages.push(infographicPage);

  var currentPage = createPage(pages.length + 1);
  var usedHeight = 0;

  blocks.forEach(function(block) {
    var type = block.dataset.type;
    var level = block.dataset.level;

    if (type === 'heading' && level === '2' && usedHeight > 0) {
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
    }

    var blockHeight = measureBlock(block, contentHeight);

    if (blockHeight > contentHeight) {
      if (usedHeight > 0) {
        pages.push(currentPage);
        currentPage = createPage(pages.length + 1);
      }
      block.style.maxHeight = contentHeight + 'px';
      block.style.overflowY = 'auto';
      currentPage.querySelector('.page-inner').appendChild(block);
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
      return;
    }

    if (usedHeight + blockHeight > contentHeight) {
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
    }

    currentPage.querySelector('.page-inner').appendChild(block);
    usedHeight += blockHeight;
  });

  if (usedHeight > 0) {
    pages.push(currentPage);
  }

  stream.remove();

  var spreads = buildSpreads(pages, isMobile);
  spreads.forEach(function(spread) {
    flipbook.appendChild(spread);
  });

  buildToC(pages);
  initNavigation(spreads, pages.length);
  initChartsForSpread(0);

  document.getElementById('loader').classList.add('hidden');
  flipbook.classList.add('ready');
});

function computePageHeight() {
  var root = document.documentElement;
  var style = getComputedStyle(root);
  var h = style.getPropertyValue('--page-height');
  if (h && h.indexOf('px') > -1) return parseInt(h);
  return Math.min(window.innerHeight * 0.92, 700);
}

function getPageContentWidth() {
  var root = document.documentElement;
  var style = getComputedStyle(root);
  var w = style.getPropertyValue('--page-width');
  if (w && w.indexOf('px') > -1) return parseInt(w) - 80;
  return Math.min(window.innerWidth * 0.48, 520) - 80;
}

function createPage(pageNum) {
  var page = document.createElement('div');
  page.className = 'page';
  page.dataset.page = pageNum;
  var inner = document.createElement('div');
  inner.className = 'page-inner';
  page.appendChild(inner);
  var num = document.createElement('div');
  num.className = 'page-number';
  num.textContent = pageNum;
  page.appendChild(num);
  return page;
}

function measureBlock(block, maxHeight) {
  var measurer = document.getElementById('block-measurer');
  if (!measurer) {
    measurer = document.createElement('div');
    measurer.id = 'block-measurer';
    measurer.style.cssText = 'position:absolute;visibility:hidden;' +
      'width:' + getPageContentWidth() + 'px;' +
      'padding:0;font-size:0.95rem;line-height:1.7;';
    document.body.appendChild(measurer);
  }
  measurer.appendChild(block);
  var height = block.getBoundingClientRect().height;
  measurer.removeChild(block);
  return height;
}

function buildSpreads(pages, isMobile) {
  var spreads = [];
  if (isMobile) {
    pages.forEach(function(page, i) {
      var spread = document.createElement('div');
      spread.className = 'spread' + (i === 0 ? ' active' : '');
      spread.dataset.spread = i;
      page.classList.add('page-single');
      spread.appendChild(page);
      spreads.push(spread);
    });
  } else {
    for (var i = 0; i < pages.length; i += 2) {
      var spread = document.createElement('div');
      spread.className = 'spread' + (i === 0 ? ' active' : '');
      spread.dataset.spread = spreads.length;
      var left = pages[i];
      left.classList.add('page-left');
      spread.appendChild(left);
      if (i + 1 < pages.length) {
        var right = pages[i + 1];
        right.classList.add('page-right');
        spread.appendChild(right);
      }
      spreads.push(spread);
    }
  }
  return spreads;
}

function initNavigation(spreads, totalPages) {
  var current = 0;
  var total = spreads.length;
  var isAnimating = false;

  function goToSpread(index) {
    if (index < 0 || index >= total || index === current || isAnimating) return;
    isAnimating = true;
    var forward = index > current;
    var oldSpread = spreads[current];
    var newSpread = spreads[index];
    newSpread.classList.add('next');
    if (forward) {
      oldSpread.classList.add('turning-forward');
    } else {
      newSpread.classList.add('turning-backward');
    }
    setTimeout(function() {
      oldSpread.classList.remove('active', 'turning-forward');
      newSpread.classList.remove('next', 'turning-backward');
      newSpread.classList.add('active');
      current = index;
      isAnimating = false;
      updateCounter();
      updateProgress();
      initChartsForSpread(current);
      updateTocActive();
    }, 800);
  }

  function updateCounter() {
    var counter = document.getElementById('page-counter');
    var isMobile = window.innerWidth <= 1024;
    if (isMobile) {
      var pageNum = parseInt(spreads[current].querySelector('.page').dataset.page);
      counter.textContent = pageNum + ' of ' + totalPages;
    } else {
      var pages = spreads[current].querySelectorAll('.page');
      var first = pages[0].dataset.page;
      var last = pages[pages.length - 1].dataset.page;
      counter.textContent = first + '-' + last + ' of ' + totalPages;
    }
  }

  function updateProgress() {
    var bar = document.getElementById('progress-bar');
    bar.style.width = ((current + 1) / total * 100) + '%';
  }

  document.addEventListener('keydown', function(e) {
    if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'PageDown') {
      e.preventDefault(); goToSpread(current + 1);
    } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
      e.preventDefault(); goToSpread(current - 1);
    } else if (e.key === 'Home') { e.preventDefault(); goToSpread(0); }
    else if (e.key === 'End') { e.preventDefault(); goToSpread(total - 1); }
    else if (e.key === 't' || e.key === 'T') { toggleToC(); }
    else if (e.key === 'f' || e.key === 'F') { toggleFullscreen(); }
    else if (e.key === '?' || e.key === 'h' || e.key === 'H') { toggleHelp(); }
    else if (e.key === 'Escape') { closeOverlays(); }
  });

  document.getElementById('flipbook').addEventListener('click', function(e) {
    if (e.target.closest('.flipbook-nav, .toc-overlay, .help-overlay, a, button')) return;
    var rect = this.getBoundingClientRect();
    var x = e.clientX - rect.left;
    if (x > rect.width / 2) { goToSpread(current + 1); }
    else { goToSpread(current - 1); }
  });

  var touchStartX = 0;
  document.addEventListener('touchstart', function(e) {
    touchStartX = e.touches[0].clientX;
  }, { passive: true });
  document.addEventListener('touchend', function(e) {
    var dx = e.changedTouches[0].clientX - touchStartX;
    if (Math.abs(dx) > 50) {
      if (dx < 0) goToSpread(current + 1);
      else goToSpread(current - 1);
    }
  }, { passive: true });

  document.getElementById('btn-prev').addEventListener('click', function() { goToSpread(current - 1); });
  document.getElementById('btn-next').addEventListener('click', function() { goToSpread(current + 1); });
  document.getElementById('btn-toc').addEventListener('click', toggleToC);
  document.getElementById('btn-toc-close').addEventListener('click', toggleToC);

  document.getElementById('toc-list').addEventListener('click', function(e) {
    var link = e.target.closest('a');
    if (link) {
      e.preventDefault();
      var spreadIdx = parseInt(link.dataset.spread);
      goToSpread(spreadIdx);
      toggleToC();
    }
  });

  updateCounter();
  updateProgress();
  window._flipbookGoTo = goToSpread;
  window._flipbookCurrent = function() { return current; };
}

var chartInitialized = {};
function initChartsForSpread(spreadIndex) {
  var spread = document.querySelectorAll('.spread')[spreadIndex];
  if (!spread) return;
  var canvases = spread.querySelectorAll('canvas[id^="enr-"]');
  canvases.forEach(function(canvas) {
    var id = canvas.id;
    if (chartInitialized[id]) return;
    if (window._chartInits && window._chartInits[id]) {
      window._chartInits[id]();
      chartInitialized[id] = true;
    }
  });
}

function buildToC(pages) {
  var tocList = document.getElementById('toc-list');
  var isMobile = window.innerWidth <= 1024;
  pages.forEach(function(page, pageIndex) {
    var headings = page.querySelectorAll('h2, h3');
    headings.forEach(function(h) {
      var link = document.createElement('a');
      link.href = '#';
      link.className = h.tagName === 'H3' ? 'toc-h3' : 'toc-h2';
      link.dataset.spread = isMobile ? pageIndex : Math.floor(pageIndex / 2);
      link.dataset.page = pageIndex + 1;
      link.innerHTML = h.textContent + ' <span>p.' + (pageIndex + 1) + '</span>';
      tocList.appendChild(link);
    });
  });
}

function updateTocActive() {
  var current = window._flipbookCurrent();
  document.querySelectorAll('.toc-list a').forEach(function(a) {
    a.classList.toggle('active', parseInt(a.dataset.spread) === current);
  });
}

function toggleToC() { document.getElementById('toc-overlay').classList.toggle('open'); }
function toggleHelp() { document.getElementById('help-overlay').classList.toggle('open'); }
function closeOverlays() {
  document.getElementById('toc-overlay').classList.remove('open');
  document.getElementById('help-overlay').classList.remove('open');
}
function toggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(function() {});
  } else { document.exitFullscreen(); }
}
"""


def _wrap_content_blocks(main_html):
    """Wrap top-level HTML elements in .block divs with data-type attributes.

    Parses the scroll-mode <main> content and wraps each top-level element
    for the flipbook pagination engine.
    """
    # Split on top-level HTML elements while preserving them
    # We match opening tags of known block-level elements
    block_pattern = re.compile(
        r'(<(?:h[1-6]|p|blockquote|ul|ol|pre|table|div)\b[^>]*>)',
        re.IGNORECASE
    )

    # Use a simpler approach: split the HTML into top-level elements
    # by finding balanced tags at the top level
    result = []
    pos = 0
    html = main_html.strip()

    while pos < len(html):
        # Skip whitespace
        if html[pos] in ' \t\n\r':
            pos += 1
            continue

        # Must start with a tag
        if html[pos] != '<':
            # Text node — wrap as paragraph
            end = html.find('<', pos)
            if end == -1:
                end = len(html)
            text = html[pos:end].strip()
            if text:
                result.append(f'<div class="block" data-type="paragraph"><p>{text}</p></div>')
            pos = end
            continue

        # Comment — pass through
        if html[pos:pos+4] == '<!--':
            end = html.find('-->', pos)
            if end == -1:
                break
            result.append(html[pos:end+3])
            pos = end + 3
            continue

        # Parse the tag name
        tag_match = re.match(r'<(\w+)', html[pos:])
        if not tag_match:
            pos += 1
            continue

        tag_name = tag_match.group(1).lower()

        # Self-closing tags (hr, br, img)
        if tag_name in ('hr', 'br', 'img'):
            # Find end of tag
            end = html.find('>', pos)
            if end == -1:
                break
            element = html[pos:end+1]
            result.append(f'<div class="block" data-type="separator">{element}</div>')
            pos = end + 1
            continue

        # Find the matching closing tag (handle nesting)
        close_tag = f'</{tag_name}>'
        depth = 0
        search_pos = pos
        end_pos = -1

        while search_pos < len(html):
            # Find next instance of this tag (opening or closing)
            open_next = html.find(f'<{tag_name}', search_pos + 1)
            close_next = html.find(close_tag, search_pos + 1)

            if close_next == -1:
                # No closing tag found — take rest of string
                end_pos = len(html)
                break

            if open_next != -1 and open_next < close_next:
                # Nested opening tag
                depth += 1
                search_pos = open_next + len(tag_name) + 1
            else:
                if depth == 0:
                    end_pos = close_next + len(close_tag)
                    break
                depth -= 1
                search_pos = close_next + len(close_tag)

        if end_pos == -1:
            end_pos = len(html)

        element = html[pos:end_pos]

        # Determine block type and attributes
        if tag_name in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
            level = tag_name[1]
            # Extract id for section reference
            id_match = re.search(r'id="([^"]*)"', element)
            section_attr = f' data-section="{id_match.group(1)}"' if id_match else ''
            result.append(
                f'<div class="block" data-type="heading" data-level="{level}"{section_attr}>'
                f'{element}</div>'
            )
        elif tag_name == 'p':
            result.append(f'<div class="block" data-type="paragraph">{element}</div>')
        elif tag_name == 'blockquote':
            result.append(f'<div class="block" data-type="blockquote">{element}</div>')
        elif tag_name in ('ul', 'ol'):
            result.append(f'<div class="block" data-type="list">{element}</div>')
        elif tag_name == 'pre':
            result.append(f'<div class="block" data-type="code">{element}</div>')
        elif tag_name == 'table':
            result.append(
                f'<div class="block" data-type="table">'
                f'<div class="table-wrapper">{element}</div></div>'
            )
        elif tag_name == 'div':
            # Check for enrichment containers
            if 'chart-container' in element[:200]:
                # Extract canvas id for enrichment reference
                canvas_match = re.search(r'<canvas[^>]*id="(enr-[^"]*)"', element)
                eid = canvas_match.group(1) if canvas_match else ''
                result.append(
                    f'<div class="block" data-type="enrichment" '
                    f'data-enrichment-id="{eid}" data-track="data">{element}</div>'
                )
            elif 'concept-diagram' in element[:200]:
                svg_match = re.search(r'id="(enr-[^"]*)"', element)
                eid = svg_match.group(1) if svg_match else ''
                result.append(
                    f'<div class="block" data-type="enrichment" '
                    f'data-enrichment-id="{eid}" data-track="concept">{element}</div>'
                )
            elif 'summary-card' in element[:200]:
                result.append(
                    f'<div class="block" data-type="enrichment" '
                    f'data-track="html">{element}</div>'
                )
            elif 'enrichment' in element[:200]:
                result.append(
                    f'<div class="block" data-type="enrichment">{element}</div>'
                )
            elif 'table-wrapper' in element[:200]:
                result.append(f'<div class="block" data-type="table">{element}</div>')
            else:
                # Generic div — pass through as paragraph-like block
                result.append(f'<div class="block" data-type="paragraph">{element}</div>')
        else:
            # Unknown element — wrap generically
            result.append(f'<div class="block" data-type="paragraph">{element}</div>')

        pos = end_pos

    return '\n'.join(result)


def _extract_cover_content(html):
    """Extract cover content from flipbook markers or first H2 section.

    Returns (cover_html, remaining_html).
    """
    # Try marker-based extraction first
    cover_start = html.find('<!-- FLIPBOOK_COVER_CONTENT -->')
    cover_end = html.find('<!-- /FLIPBOOK_COVER_CONTENT -->')
    if cover_start != -1 and cover_end != -1:
        marker_start_len = len('<!-- FLIPBOOK_COVER_CONTENT -->')
        cover_html = html[cover_start + marker_start_len:cover_end].strip()
        remaining = html[:cover_start] + html[cover_end + len('<!-- /FLIPBOOK_COVER_CONTENT -->'):]
        return cover_html, remaining

    # Fallback: extract first H2 section (heading + content until next H2)
    h2_match = re.search(r'<h2\b[^>]*>', html)
    if not h2_match:
        return '', html

    first_h2_start = h2_match.start()
    # Find the next H2 after the first one
    next_h2 = re.search(r'<h2\b[^>]*>', html[first_h2_start + 1:])
    if next_h2:
        section_end = first_h2_start + 1 + next_h2.start()
    else:
        section_end = len(html)

    cover_html = html[first_h2_start:section_end].strip()
    remaining = html[:first_h2_start] + html[section_end:]
    return cover_html, remaining


def _convert_charts_to_lazy_init(script_block):
    """Convert immediate Chart.js execution to window._chartInits lazy registry.

    Finds patterns like:
      new Chart(document.getElementById('enr-001'), { ... });
    and wraps them in:
      window._chartInits['enr-001'] = function() { new Chart(...); };
    """
    # Check if already using lazy init
    if '_chartInits' in script_block:
        return script_block

    # Pattern: new Chart(document.getElementById('enr-XXX'), {config});
    # This is complex because configs can contain nested braces
    result = ['window._chartInits = window._chartInits || {};']

    # Find each new Chart(...) call
    pattern = re.compile(
        r"new\s+Chart\s*\(\s*document\.getElementById\s*\(\s*['\"]"
        r"(enr-[^'\"]+)['\"]"
        r"\s*\)\s*,",
    )

    pos = 0
    found_any = False
    while pos < len(script_block):
        m = pattern.search(script_block, pos)
        if not m:
            # Append remaining non-Chart code
            remaining = script_block[pos:].strip()
            if remaining:
                result.append(remaining)
            break

        # Append any code before this Chart call
        before = script_block[pos:m.start()].strip()
        if before:
            result.append(before)

        eid = m.group(1)
        # Find matching closing paren+semicolon by counting braces
        brace_start = m.end()  # Position right after the comma following getElementById
        depth = 0
        i = brace_start
        while i < len(script_block):
            c = script_block[i]
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
            elif c == ')' and depth == 0:
                # End of new Chart(...) call
                # Include any trailing semicolon
                end = i + 1
                if end < len(script_block) and script_block[end] == ';':
                    end += 1
                chart_call = script_block[m.start():end]
                result.append(
                    f"window._chartInits['{eid}'] = function() {{ {chart_call} }};"
                )
                pos = end
                found_any = True
                break
            i += 1
        else:
            # Couldn't find end — append remainder as-is
            result.append(script_block[pos:])
            break

    if not found_any:
        # No Chart calls found — return original with the registry init
        return 'window._chartInits = window._chartInits || {};\n' + script_block

    return '\n'.join(result)


def _assemble_flipbook(scroll_html, language='en'):
    """Transform scroll-mode HTML into flipbook HTML.

    Extracts the cover content, wraps body content into .block divs,
    converts Chart.js to lazy init, and assembles the complete flipbook
    with static CSS and JS.
    """
    # Extract title
    title_match = re.search(r'<title>(.*?)</title>', scroll_html, re.DOTALL)
    title = title_match.group(1) if title_match else 'Report'

    # Extract the existing <style> block (design tokens + scroll CSS)
    style_match = re.search(r'<style>(.*?)</style>', scroll_html, re.DOTALL)
    scroll_css = style_match.group(1) if style_match else ''

    # Extract only the :root {} block from scroll CSS (design tokens)
    root_match = re.search(r':root\s*\{[^}]*\}', scroll_css)
    design_tokens_css = root_match.group(0) if root_match else ''

    # Extract Google Fonts @import
    fonts_match = re.search(r"@import\s+url\([^)]+\);", scroll_css)
    fonts_import = fonts_match.group(0) if fonts_match else ''

    # Extract <main> content
    main_match = re.search(
        r'<main[^>]*>(.*?)</main>',
        scroll_html, re.DOTALL
    )
    if not main_match:
        # Fallback: try <article>
        main_match = re.search(r'<article[^>]*>(.*?)</article>', scroll_html, re.DOTALL)
    main_content = main_match.group(1) if main_match else ''

    # Extract cover content
    cover_html, remaining_content = _extract_cover_content(main_content)

    # Remove any footer and article wrapper from remaining content
    remaining_content = re.sub(
        r'<footer\b[^>]*>.*?</footer>', '', remaining_content, flags=re.DOTALL
    )
    remaining_content = re.sub(
        r'</?article[^>]*>', '', remaining_content
    ).strip()

    # Wrap remaining content into .block divs
    block_html = _wrap_content_blocks(remaining_content)

    # Extract <script> block with Chart.js configs
    # Find the script block that contains Chart.js initialization (not the CDN script tag)
    script_match = re.search(
        r'<script>\s*(.*?)\s*</script>\s*</body>',
        scroll_html, re.DOTALL
    )
    chart_script = script_match.group(1) if script_match else ''

    # Convert Chart.js to lazy init
    lazy_chart_script = _convert_charts_to_lazy_init(chart_script)

    # Extract Chart.js CDN URL
    chartjs_cdn = 'https://cdn.jsdelivr.net/npm/chart.js@4'
    cdn_match = re.search(r'src="(https://cdn\.jsdelivr\.net/npm/chart\.js[^"]*)"', scroll_html)
    if cdn_match:
        chartjs_cdn = cdn_match.group(1)

    # Extract date info from cover or meta
    date_match = re.search(r'(\d{4}-\d{2}-\d{2})', scroll_html)
    date_str = date_match.group(1) if date_match else datetime.now().strftime('%Y-%m-%d')

    toc_label = 'Inhalt' if language == 'de' else 'Contents'
    loading_text = 'Flipbook wird vorbereitet...' if language == 'de' else 'Preparing flipbook...'

    lang_code = language or 'en'

    return f"""<!DOCTYPE html>
<html lang="{lang_code}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <style>
    {fonts_import}
    {design_tokens_css}
    {FLIPBOOK_CSS}
  </style>
  <script src="{chartjs_cdn}"></script>
</head>
<body>
  <div class="flipbook-loader" id="loader">
    <div class="loader-spinner"></div>
    <div class="loader-text">{loading_text}</div>
  </div>

  <div class="flipbook" id="flipbook" style="opacity:0">
    <div class="page page-cover" data-page="1">
      <div class="page-inner">
        <h1 class="cover-title">{escape_html(title)}</h1>
        <div class="cover-summary">
          {cover_html}
        </div>
        <div class="cover-meta">{date_str}</div>
      </div>
      <div class="page-number">1</div>
    </div>

    <div class="page page-infographic" data-page="2">
      <!-- INFOGRAPHIC_INJECTION_POINT -->
      <div class="page-number">2</div>
    </div>

    <div class="content-stream" id="content-stream">
      {block_html}
    </div>
  </div>

  <div class="flipbook-nav" id="nav">
    <button class="nav-btn" id="btn-prev" aria-label="Previous page">&larr;</button>
    <span class="nav-counter" id="page-counter">1-2</span>
    <button class="nav-btn" id="btn-next" aria-label="Next page">&rarr;</button>
    <button class="nav-btn nav-toc" id="btn-toc" aria-label="{toc_label}">&#9776;</button>
  </div>

  <div class="flipbook-progress">
    <div class="flipbook-progress-bar" id="progress-bar"></div>
  </div>

  <div class="toc-overlay" id="toc-overlay">
    <div class="toc-panel">
      <div class="toc-header">
        <span class="toc-title">{toc_label}</span>
        <button class="toc-close" id="btn-toc-close">&times;</button>
      </div>
      <nav class="toc-list" id="toc-list"></nav>
    </div>
  </div>

  <div class="help-overlay" id="help-overlay">
    <div class="help-panel">
      <h3>Keyboard Shortcuts</h3>
      <table>
        <tr><td><kbd>&rarr;</kbd> <kbd>Space</kbd></td><td>Next spread</td></tr>
        <tr><td><kbd>&larr;</kbd></td><td>Previous spread</td></tr>
        <tr><td><kbd>Home</kbd></td><td>First page</td></tr>
        <tr><td><kbd>End</kbd></td><td>Last page</td></tr>
        <tr><td><kbd>T</kbd></td><td>Toggle table of contents</td></tr>
        <tr><td><kbd>F</kbd></td><td>Toggle fullscreen</td></tr>
        <tr><td><kbd>?</kbd></td><td>Toggle this help</td></tr>
        <tr><td><kbd>Esc</kbd></td><td>Close overlay</td></tr>
      </table>
      <button class="help-close" id="btn-help-close">Got it</button>
    </div>
  </div>

  <script>
    {lazy_chart_script}
  </script>
  <script>
    {FLIPBOOK_JS}
  </script>
</body>
</html>"""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def post_process_html(html_path, source_path, layout='scroll',
                      language='en', infographic_image=None,
                      infographic_html_path=None, infographic_data_path=None):
    """Post-process an LLM-written HTML file: inject infographic + validate content.

    When layout='flipbook', first transforms scroll-mode HTML into flipbook layout
    (block wrapping, pagination engine, cover extraction), then injects infographic.

    When layout='scroll', injects infographic at <!-- INFOGRAPHIC_INJECTION_POINT -->
    using the three-tier priority cascade.

    Always validates content preservation against the source markdown.
    """
    with open(html_path, encoding='utf-8') as f:
        html = f.read()

    with open(source_path, encoding='utf-8') as f:
        md_text = f.read()

    output_dir = os.path.dirname(html_path) or '.'

    # Flipbook assembly: transform scroll HTML → flipbook HTML
    if layout == 'flipbook':
        html = _assemble_flipbook(html, language=language)

    # Three-tier infographic injection: HTML fragment > PNG > JSON
    ig_html = _load_infographic_html_fragment(infographic_html_path, output_dir)
    if not ig_html:
        ig_html = _generate_infographic_image_html(infographic_image, output_dir)
    if not ig_html and infographic_data_path and os.path.isfile(infographic_data_path):
        with open(infographic_data_path) as f:
            ig_data = json.load(f)
        # Need design variables for fallback — use defaults
        ig_html, _ = generate_infographic_header(ig_data, DEFAULT_THEME)

    if ig_html:
        if '<!-- INFOGRAPHIC_INJECTION_POINT -->' in html:
            html = html.replace('<!-- INFOGRAPHIC_INJECTION_POINT -->', ig_html)
        else:
            # Fallback: inject after <main> tag or into flipbook container
            if layout == 'flipbook':
                html = html.replace(
                    '<div class="page page-infographic"',
                    f'<div class="page page-infographic">\n{ig_html}\n<div style="display:none"',
                    1
                )
            else:
                html = html.replace('<main>', '<main>\n' + ig_html, 1)

    # Write back
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)

    # Validate content preservation
    validation = verify_content_preservation(md_text, html)
    return html_path, validation


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate enriched HTML report (two-zone architecture)")
    parser.add_argument("--post-process", action="store_true",
                        help="Post-process mode: inject infographic into LLM-written HTML + validate")
    parser.add_argument("--html", default="", help="[post-process] Path to LLM-written HTML file")
    parser.add_argument("--source", required=True, help="Source markdown report path")
    parser.add_argument("--enrichment-plan", default="", help="Enrichment plan JSON path")
    parser.add_argument("--infographic-data", default="", help="Infographic data JSON path (optional)")
    parser.add_argument("--svg-dir", default="", help="Directory with SVG files (enr-XXX.svg)")
    parser.add_argument("--design-variables", default="", help="Design variables JSON path")
    parser.add_argument("--output", default="", help="Output HTML path")
    parser.add_argument("--language", default="en", help="Language code (en/de)")
    parser.add_argument("--density", default="balanced", help="Enrichment density (none/minimal/balanced/rich)")
    parser.add_argument("--infographic-image", default="", help="Pencil-rendered infographic PNG")
    parser.add_argument("--infographic-html", default="", help="Pencil-rendered HTML fragment")
    parser.add_argument("--layout", default="scroll", choices=["scroll", "flipbook"],
                        help="HTML layout mode (scroll=sidebar+scroll, flipbook=paginated book)")
    parser.add_argument("--chart-configs", default="", help=argparse.SUPPRESS)
    args = parser.parse_args()

    try:
        # ---- Post-process mode: inject infographic + validate ----
        if args.post_process:
            html_path = args.html or args.output
            if not html_path:
                print(json.dumps({"error": "--html or --output required in --post-process mode"}),
                      file=sys.stderr)
                sys.exit(1)

            out, validation = post_process_html(
                html_path=html_path,
                source_path=args.source,
                layout=args.layout,
                language=args.language,
                infographic_image=args.infographic_image or None,
                infographic_html_path=args.infographic_html or None,
                infographic_data_path=args.infographic_data or None,
            )
            result = {"status": "ok", "path": out, "validation": validation, "mode": "post-process"}
            print(json.dumps(result, indent=2))
            if not validation["pass"]:
                print(f"\nWARNING: Content preservation check failed!", file=sys.stderr)
                print(f"  Word ratio: {validation['word_ratio']} (need >= 0.80)", file=sys.stderr)
                print(f"  Source H2: {validation['source_h2']}, HTML H2: {validation['html_h2']}", file=sys.stderr)
            return

        # ---- Full generation mode (legacy) ----
        if not args.enrichment_plan:
            print(json.dumps({"error": "--enrichment-plan required in full generation mode"}),
                  file=sys.stderr)
            sys.exit(1)

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
