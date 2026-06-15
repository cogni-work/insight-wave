#!/usr/bin/env python3
"""Generate a self-contained HTML status dashboard for a cogni-consult engagement.

Usage:
  python3 generate-dashboard.py <engagement-dir> [--design-variables <path.json>] [--theme <theme.md>]
Output: <engagement-dir>/output/dashboard.html
Returns JSON on stdout: {"success": bool, "data": {...}, "error": "string"}

The dashboard is the visual sibling of the text WBS table that consult-resume and
consult-action-fields render. Data source: consult-project.json + each
action-fields/<slug>/field.json (the same read model as engagement-status.sh, where
deliverable state is the single source of truth and field/engagement rollups are
DERIVED at read time, never stored). Read-only: never modifies any engagement file.
"""

import argparse
import glob
import html
import json
import os
import re
import sys
from datetime import datetime, timezone

DT_STAGES = ["empathize", "define", "ideate", "prototype", "test"]

# ---------------------------------------------------------------------------
# Theme — design-variables JSON is the contract; --theme parses a theme.md as a
# legacy/CI fallback; DEFAULT_THEME is the last resort. Precedence:
# --design-variables > --theme > DEFAULT_THEME.
# ---------------------------------------------------------------------------

DEFAULT_THEME = {
    "theme_name": "cogni-work",
    "colors": {
        "primary": "#111111",
        "secondary": "#333333",
        "accent": "#C8E62E",
        "accent_muted": "#A8C424",
        "accent_dark": "#8BA31E",
        "background": "#FAFAF8",
        "surface": "#F2F2EE",
        "surface2": "#E8E8E4",
        "surface_dark": "#111111",
        "border": "#E0E0DC",
        "text": "#111111",
        "text_light": "#FFFFFF",
        "text_muted": "#6B7280",
    },
    "status": {
        "success": "#2E7D32",
        "warning": "#E5A100",
        "danger": "#D32F2F",
        "info": "#1565C0",
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


def _deep_merge(base, over):
    """Overlay `over` onto a copy of `base`, recursing into nested dicts."""
    out = dict(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _deep_merge(out[k], v)
        elif v is not None:
            out[k] = v
    return out


def load_design_variables(path):
    """Read a design-variables.json file and overlay it on DEFAULT_THEME so a
    partial file still yields a complete theme."""
    with open(path) as f:
        dv = json.load(f)
    if not isinstance(dv, dict):
        raise ValueError("design-variables must be a JSON object")
    return _deep_merge(DEFAULT_THEME, dv)


def parse_theme_md(path):
    """Minimal theme.md fallback: pull the first few hex colors into accent/
    primary/surface roles. Best-effort only — design-variables.json is the
    real contract."""
    with open(path) as f:
        text = f.read()
    hexes = re.findall(r"#[0-9A-Fa-f]{6}", text)
    over = {"colors": {}}
    roles = ["primary", "accent", "surface", "border", "secondary"]
    for role, hexval in zip(roles, hexes):
        over["colors"][role] = hexval
    name = os.path.splitext(os.path.basename(path))[0]
    over["theme_name"] = name
    return _deep_merge(DEFAULT_THEME, over)


def resolve_theme(design_variables, theme):
    if design_variables:
        return load_design_variables(design_variables), design_variables
    if theme:
        return parse_theme_md(theme), None
    return dict(DEFAULT_THEME), None


# ---------------------------------------------------------------------------
# Engagement read model — mirrors engagement-status.sh, plus field title/framing
# and research-synthesis counts the rollup script does not surface.
# ---------------------------------------------------------------------------


def _field_rollup(states):
    if states and all(s == "complete" for s in states):
        return "complete"
    if any(s != "pending" for s in states):
        return "in-progress"
    return "pending"


def load_engagement(engagement_dir):
    """Return the engagement model, or raise ValueError with a user-facing message."""
    proj_path = os.path.join(engagement_dir, "consult-project.json")
    try:
        with open(proj_path) as f:
            project = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        raise ValueError(f"unreadable engagement file {proj_path}: {exc}")

    field_slugs = project.get("action_fields") or []
    if not isinstance(field_slugs, list) or not all(isinstance(s, str) for s in field_slugs):
        raise ValueError("malformed engagement file: action_fields must be a list of strings")

    warnings = []
    fields = []
    for slug in field_slugs:
        fdir = os.path.join(engagement_dir, "action-fields", slug)
        fpath = os.path.join(fdir, "field.json")
        title, framing = slug, ""
        deliverables = []
        state = "pending"
        try:
            with open(fpath) as f:
                fjson = json.load(f)
            title = fjson.get("title") or slug
            framing = fjson.get("framing") or ""
            deliverables = fjson.get("deliverables") or []
            state = _field_rollup([d.get("state", "pending") for d in deliverables])
        except FileNotFoundError:
            pass
        except (json.JSONDecodeError, OSError) as exc:
            state = "unreadable"
            warnings.append(f"unreadable field file {fpath}: {exc}")
        research_count = len(glob.glob(os.path.join(fdir, "research", "*.md")))
        fields.append({
            "slug": slug,
            "title": title,
            "framing": framing,
            "state": state,
            "deliverables": deliverables,
            "research_count": research_count,
        })

    scope_research = len(glob.glob(os.path.join(engagement_dir, "scope", "research", "*.md")))
    return {
        "slug": project.get("slug"),
        "name": project.get("name") or project.get("slug") or "Engagement",
        "language": project.get("language") or "en",
        "key_question": project.get("key_question") or "",
        "updated": project.get("updated") or "",
        "scope_state": (project.get("workflow_state") or {}).get("scope", "pending"),
        "knowledge_base": (project.get("plugin_refs") or {}).get("knowledge_base"),
        "action_fields": fields,
        "scope_research_count": scope_research,
        "warnings": warnings,
    }


def compute_summary(eng):
    fields = eng["action_fields"]
    all_delivs = [d for f in fields for d in f["deliverables"]]
    total = len(all_delivs)
    by_state = {"complete": 0, "in-progress": 0, "pending": 0}
    persona_complete = 0
    for d in all_delivs:
        st = d.get("state", "pending")
        by_state[st] = by_state.get(st, 0) + 1
        if d.get("persona_review") == "complete":
            persona_complete += 1
    field_states = {"complete": 0, "in-progress": 0, "pending": 0, "unreadable": 0}
    for f in fields:
        field_states[f["state"]] = field_states.get(f["state"], 0) + 1
    pct = round(100 * by_state["complete"] / total) if total else 0
    research_total = eng["scope_research_count"] + sum(f["research_count"] for f in fields)
    if all(f["state"] == "complete" for f in fields) and fields:
        engagement_state = "complete"
    elif any(f["state"] != "pending" for f in fields):
        engagement_state = "in-progress"
    else:
        engagement_state = "pending"
    return {
        "deliverables_total": total,
        "deliverables_by_state": by_state,
        "fields_total": len(fields),
        "fields_by_state": field_states,
        "persona_reviews_complete": persona_complete,
        "research_total": research_total,
        "completion_pct": pct,
        "engagement_state": engagement_state,
    }


def next_action(eng, summary):
    """A single recommendation line, mirroring engagement-status signals."""
    if eng["scope_state"] != "complete":
        return "Finish scoping the engagement (consult-scope) — define the SMART key question and action fields."
    for f in eng["action_fields"]:
        for d in f["deliverables"]:
            if d.get("state") == "in-progress":
                stage = d.get("dt_stage") or "empathize"
                return f"Continue “{d.get('title', d.get('slug'))}” in {f['title']} (design thinking, {stage} stage)."
    for f in eng["action_fields"]:
        for d in f["deliverables"]:
            if d.get("state") == "pending":
                return f"Start “{d.get('title', d.get('slug'))}” in {f['title']} (consult-design-thinking)."
        if not f["deliverables"]:
            return f"Plan deliverables for {f['title']} (consult-action-fields)."
    if summary["engagement_state"] == "complete":
        return "All deliverables complete — review with acting personas and assemble the engagement output."
    return "Review the engagement status."


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

STATE_ROLE = {"complete": "success", "in-progress": "warning", "pending": "muted", "unreadable": "danger"}
REVIEW_ROLE = {"complete": "success", "in-progress": "warning", "pending": "muted"}


def esc(s):
    return html.escape(str(s if s is not None else ""))


def badge(text, role):
    return f'<span class="badge badge-{role}">{esc(text)}</span>'


def dt_indicator(stage):
    """Five-step empathize→test indicator; prior + current stages are filled."""
    try:
        idx = DT_STAGES.index(stage) if stage in DT_STAGES else -1
    except ValueError:
        idx = -1
    dots = []
    for i, name in enumerate(DT_STAGES):
        cls = "dt-dot"
        if idx >= 0 and i < idx:
            cls += " dt-done"
        elif idx >= 0 and i == idx:
            cls += " dt-current"
        dots.append(f'<span class="{cls}" title="{esc(name)}"></span>')
    label = esc(stage) if stage else "—"
    return f'<span class="dt-track">{"".join(dots)}</span><span class="dt-label">{label}</span>'


def render_field_card(field):
    delivs = field["deliverables"]
    rows = []
    if not delivs:
        rows.append('<div class="deliv-empty">No deliverables planned yet</div>')
    for d in delivs:
        st = d.get("state", "pending")
        review = d.get("persona_review", "pending")
        rows.append(
            '<div class="deliv-row">'
            f'<div class="deliv-title">{esc(d.get("title") or d.get("slug"))}</div>'
            f'<div class="deliv-state">{badge(st, STATE_ROLE.get(st, "muted"))}</div>'
            f'<div class="deliv-dt">{dt_indicator(d.get("dt_stage"))}</div>'
            f'<div class="deliv-review">persona {badge(review, REVIEW_ROLE.get(review, "muted"))}</div>'
            '</div>'
        )
    done = sum(1 for d in delivs if d.get("state") == "complete")
    framing = f'<p class="field-framing">{esc(field["framing"])}</p>' if field["framing"] else ""
    research = (
        f'<span class="field-research">\U0001f4da {field["research_count"]} research</span>'
        if field["research_count"] else ""
    )
    return (
        '<div class="field-card">'
        '<div class="field-head">'
        f'<h3>{esc(field["title"])}</h3>'
        f'<div class="field-meta">{badge(field["state"], STATE_ROLE.get(field["state"], "muted"))}'
        f'<span class="field-count">{done}/{len(delivs)} done</span>{research}</div>'
        '</div>'
        f'{framing}'
        f'<div class="deliv-list">{"".join(rows)}</div>'
        '</div>'
    )


def render_html(eng, summary, theme):
    colors = theme["colors"]
    status = theme["status"]
    fonts = theme["fonts"]
    shadows = theme.get("shadows", DEFAULT_THEME["shadows"])
    radius = theme.get("radius", "12px")
    gfi = theme.get("google_fonts_import", "")

    bystate = summary["deliverables_by_state"]
    stat_cards = "".join([
        f'<div class="stat"><div class="stat-num">{summary["completion_pct"]}%</div><div class="stat-lbl">deliverables complete</div></div>',
        f'<div class="stat"><div class="stat-num">{summary["fields_total"]}</div><div class="stat-lbl">action fields</div></div>',
        f'<div class="stat"><div class="stat-num">{summary["deliverables_total"]}</div><div class="stat-lbl">deliverables</div></div>',
        f'<div class="stat"><div class="stat-num">{summary["persona_reviews_complete"]}</div><div class="stat-lbl">persona reviews done</div></div>',
        f'<div class="stat"><div class="stat-num">{summary["research_total"]}</div><div class="stat-lbl">research syntheses</div></div>',
    ])

    field_cards = "".join(render_field_card(f) for f in eng["action_fields"])
    if not eng["action_fields"]:
        field_cards = '<div class="deliv-empty">No action fields defined yet — run consult-scope.</div>'

    kb = eng["knowledge_base"]
    kb_line = (
        f'Bound knowledge base: <code>{esc(kb)}</code> · {summary["research_total"]} synthesis file(s) across scope + action fields'
        if kb else "No knowledge base bound yet."
    )

    warn_block = ""
    if eng["warnings"]:
        items = "".join(f"<li>{esc(w)}</li>" for w in eng["warnings"])
        warn_block = f'<section class="card warn"><h2>⚠ Warnings</h2><ul>{items}</ul></section>'

    generated = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    return f"""<!DOCTYPE html>
<html lang="{esc(eng['language'])}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(eng['name'])} — Engagement Dashboard</title>
<style>
{gfi}
:root {{
  --primary: {colors['primary']}; --secondary: {colors['secondary']};
  --accent: {colors['accent']}; --accent-muted: {colors['accent_muted']}; --accent-dark: {colors['accent_dark']};
  --bg: {colors['background']}; --surface: {colors['surface']}; --surface2: {colors['surface2']};
  --surface-dark: {colors['surface_dark']}; --border: {colors['border']};
  --text: {colors['text']}; --text-light: {colors['text_light']}; --text-muted: {colors['text_muted']};
  --green: {status['success']}; --yellow: {status['warning']}; --red: {status['danger']}; --blue: {status['info']};
  --font-headers: {fonts['headers']}; --font-body: {fonts['body']}; --font-mono: {fonts['mono']};
  --radius: {radius};
  --shadow-sm: {shadows['sm']}; --shadow-md: {shadows['md']}; --shadow-lg: {shadows['lg']};
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: var(--font-body); background: var(--bg); color: var(--text); line-height: 1.5; padding: 2rem 1.5rem 4rem; }}
.wrap {{ max-width: 1100px; margin: 0 auto; }}
h1, h2, h3 {{ font-family: var(--font-headers); font-weight: 600; }}
header.hero {{ background: var(--surface-dark); color: var(--text-light); border-radius: var(--radius); padding: 2rem; box-shadow: var(--shadow-lg); margin-bottom: 1.5rem; }}
header.hero h1 {{ font-size: 1.9rem; margin-bottom: .5rem; }}
header.hero .kq {{ font-size: 1.05rem; opacity: .9; max-width: 70ch; }}
header.hero .hero-meta {{ margin-top: 1rem; display: flex; flex-wrap: wrap; gap: .5rem; align-items: center; }}
.card {{ background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 1.5rem; box-shadow: var(--shadow-sm); margin-bottom: 1.5rem; }}
.card > h2 {{ font-size: 1.2rem; margin-bottom: 1rem; }}
.card.warn {{ border-color: var(--red); }}
.stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; }}
.stat {{ background: var(--surface2); border-radius: var(--radius); padding: 1.1rem; text-align: center; }}
.stat-num {{ font-family: var(--font-headers); font-size: 1.8rem; font-weight: 700; color: var(--accent-dark); }}
.stat-lbl {{ font-size: .8rem; color: var(--text-muted); margin-top: .25rem; }}
.progress {{ height: 10px; background: var(--surface2); border-radius: 999px; overflow: hidden; margin: 1rem 0 .25rem; }}
.progress > span {{ display: block; height: 100%; background: var(--accent); border-radius: 999px; }}
.progress-lbl {{ font-size: .8rem; color: var(--text-muted); }}
.fields {{ display: grid; grid-template-columns: 1fr; gap: 1rem; }}
.field-card {{ background: var(--surface2); border: 1px solid var(--border); border-radius: var(--radius); padding: 1.25rem; }}
.field-head {{ display: flex; justify-content: space-between; align-items: baseline; flex-wrap: wrap; gap: .5rem; }}
.field-head h3 {{ font-size: 1.05rem; }}
.field-meta {{ display: flex; align-items: center; gap: .6rem; }}
.field-count {{ font-size: .8rem; color: var(--text-muted); }}
.field-research {{ font-size: .78rem; color: var(--text-muted); }}
.field-framing {{ font-size: .88rem; color: var(--text-muted); margin: .5rem 0 .75rem; }}
.deliv-list {{ display: flex; flex-direction: column; gap: .4rem; margin-top: .5rem; }}
.deliv-row {{ display: grid; grid-template-columns: minmax(0,2.2fr) auto minmax(0,1.6fr) auto; gap: .75rem; align-items: center; background: var(--surface); border-radius: 8px; padding: .55rem .75rem; }}
.deliv-title {{ font-size: .92rem; font-weight: 500; }}
.deliv-review {{ font-size: .76rem; color: var(--text-muted); text-align: right; }}
.deliv-empty {{ font-size: .85rem; color: var(--text-muted); font-style: italic; padding: .5rem 0; }}
.dt-track {{ display: inline-flex; gap: 3px; vertical-align: middle; }}
.dt-dot {{ width: 9px; height: 9px; border-radius: 50%; background: var(--border); display: inline-block; }}
.dt-dot.dt-done {{ background: var(--accent-muted); }}
.dt-dot.dt-current {{ background: var(--accent-dark); box-shadow: 0 0 0 2px var(--surface2); }}
.dt-label {{ font-size: .72rem; color: var(--text-muted); margin-left: .4rem; text-transform: capitalize; }}
.badge {{ display: inline-block; font-size: .72rem; font-weight: 600; padding: .12rem .5rem; border-radius: 999px; text-transform: capitalize; }}
.badge-success {{ background: color-mix(in srgb, var(--green) 16%, transparent); color: var(--green); }}
.badge-warning {{ background: color-mix(in srgb, var(--yellow) 18%, transparent); color: var(--yellow); }}
.badge-danger {{ background: color-mix(in srgb, var(--red) 16%, transparent); color: var(--red); }}
.badge-muted {{ background: var(--surface2); color: var(--text-muted); }}
.badge-info {{ background: color-mix(in srgb, var(--blue) 16%, transparent); color: var(--blue); }}
.next {{ font-size: 1rem; }}
.next strong {{ color: var(--accent-dark); }}
code {{ font-family: var(--font-mono); font-size: .85em; background: var(--surface2); padding: .1rem .35rem; border-radius: 5px; }}
footer {{ text-align: center; color: var(--text-muted); font-size: .78rem; margin-top: 2rem; }}
@media (max-width: 640px) {{ .deliv-row {{ grid-template-columns: 1fr; gap: .35rem; }} .deliv-review {{ text-align: left; }} }}
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <h1>{esc(eng['name'])}</h1>
    {f'<p class="kq">{esc(eng["key_question"])}</p>' if eng['key_question'] else ''}
    <div class="hero-meta">
      {badge('engagement ' + summary['engagement_state'], STATE_ROLE.get(summary['engagement_state'], 'muted'))}
      {badge('scope ' + eng['scope_state'], STATE_ROLE.get(eng['scope_state'], 'muted'))}
      {badge('lang ' + eng['language'], 'info')}
      {f"<span style='opacity:.7;font-size:.8rem'>updated {esc(eng['updated'])}</span>" if eng['updated'] else ''}
    </div>
  </header>

  <section class="card">
    <h2>Progress</h2>
    <div class="stats">{stat_cards}</div>
    <div class="progress"><span style="width: {summary['completion_pct']}%"></span></div>
    <div class="progress-lbl">{bystate['complete']} complete · {bystate['in-progress']} in progress · {bystate['pending']} pending</div>
  </section>

  <section class="card">
    <h2>Action fields — work breakdown</h2>
    <div class="fields">{field_cards}</div>
  </section>

  <section class="card">
    <h2>Knowledge base</h2>
    <p>{kb_line}</p>
  </section>

  <section class="card">
    <h2>Next action</h2>
    <p class="next">{esc(next_action(eng, summary))}</p>
  </section>

  {warn_block}

  <footer>Generated {generated} · cogni-consult engagement dashboard · theme: {esc(theme.get('theme_name', 'default'))}</footer>
</div>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser(description="Generate a cogni-consult engagement HTML dashboard.")
    ap.add_argument("engagement_dir")
    ap.add_argument("--design-variables", dest="design_variables", default=None)
    ap.add_argument("--theme", dest="theme", default=None)
    args = ap.parse_args()

    engagement_dir = os.path.abspath(args.engagement_dir)
    try:
        if not os.path.isdir(engagement_dir):
            raise ValueError(f"engagement directory not found: {engagement_dir}")
        eng = load_engagement(engagement_dir)
        summary = compute_summary(eng)
        theme, dv_path = resolve_theme(args.design_variables, args.theme)
        out_dir = os.path.join(engagement_dir, "output")
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "dashboard.html")
        with open(out_path, "w") as f:
            f.write(render_html(eng, summary, theme))
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 1

    print(json.dumps({
        "success": True,
        "data": {
            "path": out_path,
            "theme": theme.get("theme_name", "default"),
            "design_variables": dv_path,
            "engagement_state": summary["engagement_state"],
            "completion_pct": summary["completion_pct"],
        },
        "error": "",
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
