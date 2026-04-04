#!/usr/bin/env python3
"""Generate a self-contained HTML dashboard for a cogni-portfolio project.

Usage: python3 generate-dashboard.py <project-dir> [--design-variables <path.json>] [--theme <path-to-theme.md>]
Output: <project-dir>/output/dashboard.html
Returns JSON: {"status": "ok", "path": "<output-path>", "theme": "<name>", "design_variables": "<path-or-null>"} or {"error": "..."}
"""

import json
import glob
import os
import re
import sys
import subprocess
from datetime import datetime


# ---------------------------------------------------------------------------
# Theme parser — reads a cogni-workspace theme.md and extracts design tokens
# ---------------------------------------------------------------------------

DEFAULT_THEME = {
    "name": "cogni-work",
    "colors": {
        "primary": "#111111",
        "secondary": "#333333",
        "accent": "#C8E62E",
        "accent_muted": "#A8C424",
        "accent_dark": "#8BA31E",
        "background": "#FAFAF8",
        "surface": "#F2F2EE",
        "surface_dark": "#111111",
        "text": "#111111",
        "text_light": "#FFFFFF",
        "text_muted": "#6B7280",
        "border": "#E0E0DC",
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


def parse_theme(theme_path):
    """Parse a cogni-workspace theme.md file into a design tokens dict.

    Theme files use this markdown pattern:
      - **Token Name**: `#HEX` - Description
      - **Headers**: Font Name Bold / fallback: ...
    """
    if not theme_path or not os.path.isfile(theme_path):
        return DEFAULT_THEME.copy()

    with open(theme_path) as f:
        content = f.read()

    theme = {
        "name": "",
        "colors": {},
        "status": {},
        "fonts": {},
    }

    # Extract theme name from first heading
    m = re.search(r'^#\s+(.+)', content, re.MULTILINE)
    if m:
        theme["name"] = m.group(1).strip()

    # Extract color tokens: **Name**: `#HEX` - description
    # Map common token names to our CSS variable names
    color_map = {
        "primary": "primary",
        "secondary": "secondary",
        "accent": "accent",
        "accent muted": "accent_muted",
        "accent dark": "accent_dark",
        "background": "background",
        "surface": "surface",
        "surface dark": "surface_dark",
        "text": "text",
        "text light": "text_light",
        "text muted": "text_muted",
        "border": "border",
    }
    status_map = {
        "success": "success",
        "warning": "warning",
        "danger": "danger",
        "info": "info",
    }

    # Parse all color lines
    for m in re.finditer(r'-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`', content):
        name = m.group(1).strip().lower()
        hex_val = m.group(2).strip()

        # Check color palette tokens
        for key, var_name in color_map.items():
            if name == key or name.startswith(key + " "):
                # Prefer exact match; for "text" avoid matching "text light"/"text muted"
                if name == key:
                    theme["colors"][var_name] = hex_val
                    break
                # Allow prefix match only for multi-word tokens
                elif " " in key and name.startswith(key):
                    theme["colors"][var_name] = hex_val
                    break
        else:
            # Check status tokens
            for key, var_name in status_map.items():
                if name == key or name.startswith(key):
                    theme["status"][var_name] = hex_val
                    break

    # Re-parse to catch "text light" and "text muted" specifically
    for m in re.finditer(r'-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`', content):
        name = m.group(1).strip().lower()
        hex_val = m.group(2).strip()
        if name == "text light":
            theme["colors"]["text_light"] = hex_val
        elif name == "text muted":
            theme["colors"]["text_muted"] = hex_val

    # Parse font lines: **Headers**: Font Name / fallback: ...
    font_patterns = {
        "headers": r'-\s+\*\*Headers?\*\*:\s*(.+)',
        "body": r'-\s+\*\*Body\*\*:\s*(.+)',
        "mono": r'-\s+\*\*Mono\*\*:\s*(.+)',
    }
    for key, pattern in font_patterns.items():
        fm = re.search(pattern, content, re.IGNORECASE)
        if fm:
            raw = fm.group(1).strip()
            # Convert "Font Name Bold / fallback: Alt1, Alt2" to CSS font-family
            fonts = re.split(r'\s*/\s*fallback:\s*', raw, maxsplit=1)
            primary_font = fonts[0].strip().rstrip(" Bold").rstrip(" Regular")
            fallbacks = fonts[1].strip() if len(fonts) > 1 else ""
            # Build CSS value
            parts = [f"'{primary_font}'"]
            if fallbacks:
                for fb in fallbacks.split(","):
                    fb = fb.strip().rstrip(" Bold").rstrip(" Regular")
                    if fb:
                        parts.append(f"'{fb}'" if " " in fb else fb)
            if key == "mono":
                parts.append("monospace")
            else:
                parts.extend(["-apple-system", "BlinkMacSystemFont", "'Segoe UI'", "sans-serif"])
            theme["fonts"][key] = ", ".join(parts)

    # Fill missing tokens from defaults
    for section in ["colors", "status", "fonts"]:
        for k, v in DEFAULT_THEME[section].items():
            if k not in theme[section]:
                theme[section] = dict(theme[section])
                theme[section][k] = v

    if not theme["name"]:
        theme["name"] = DEFAULT_THEME["name"]

    return theme


def derive_surface2(surface_hex):
    """Derive a slightly darker surface variant from the surface color."""
    try:
        r, g, b = int(surface_hex[1:3], 16), int(surface_hex[3:5], 16), int(surface_hex[5:7], 16)
        # Darken by ~4%
        factor = 0.96
        r2, g2, b2 = int(r * factor), int(g * factor), int(b * factor)
        return f"#{r2:02x}{g2:02x}{b2:02x}"
    except Exception:
        return "#E8E8E4"


def google_fonts_url(theme):
    """Build a Google Fonts import URL from theme font names."""
    font_names = set()
    for key in ["headers", "body"]:
        val = theme["fonts"].get(key, "")
        m = re.match(r"'([^']+)'", val)
        if m:
            font_names.add(m.group(1))
    mono_val = theme["fonts"].get("mono", "")
    m = re.match(r"'([^']+)'", mono_val)
    if m:
        font_names.add(m.group(1))

    if not font_names:
        return ""

    families = []
    for name in sorted(font_names):
        encoded = name.replace(" ", "+")
        if "mono" in name.lower() or "code" in name.lower():
            families.append(f"family={encoded}:wght@400;500")
        else:
            families.append(f"family={encoded}:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,700")

    return f"https://fonts.googleapis.com/css2?{'&'.join(families)}&display=swap"


# ---------------------------------------------------------------------------
# Design variables loader — reads LLM-generated JSON contract
# ---------------------------------------------------------------------------

DESIGN_VARS_REQUIRED_COLORS = [
    "primary", "secondary", "accent", "accent_muted", "accent_dark",
    "background", "surface", "surface2", "surface_dark",
    "border", "text", "text_light", "text_muted",
]
DESIGN_VARS_REQUIRED_STATUS = ["success", "warning", "danger", "info"]
DESIGN_VARS_REQUIRED_FONTS = ["headers", "body", "mono"]

DEFAULT_SHADOWS = {
    "sm": "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)",
    "md": "0 4px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
    "lg": "0 12px 40px rgba(0,0,0,0.1), 0 4px 12px rgba(0,0,0,0.05)",
    "xl": "0 24px 64px rgba(0,0,0,0.14), 0 8px 20px rgba(0,0,0,0.06)",
}


def load_design_variables(path):
    """Load a design-variables JSON file and return a theme dict.

    Validates required keys and applies defaults for optional fields.
    Returns a dict compatible with generate_html()'s theme expectations.
    """
    with open(path) as f:
        dv = json.load(f)

    # Validate required top-level keys
    for key in ["theme_name", "colors", "status", "fonts"]:
        if key not in dv:
            raise ValueError(f"design-variables JSON missing required key: {key}")

    # Validate required color keys
    for k in DESIGN_VARS_REQUIRED_COLORS:
        if k not in dv["colors"]:
            raise ValueError(f"design-variables colors missing required key: {k}")

    # Validate required status keys
    for k in DESIGN_VARS_REQUIRED_STATUS:
        if k not in dv["status"]:
            raise ValueError(f"design-variables status missing required key: {k}")

    # Validate required font keys
    for k in DESIGN_VARS_REQUIRED_FONTS:
        if k not in dv["fonts"]:
            raise ValueError(f"design-variables fonts missing required key: {k}")

    # Build theme dict matching generate_html() expectations
    theme = {
        "name": dv["theme_name"],
        "colors": dict(dv["colors"]),
        "status": dict(dv["status"]),
        "fonts": dict(dv["fonts"]),
        "google_fonts_import": dv.get("google_fonts_import", ""),
        "radius": dv.get("radius", "12px"),
        "shadows": {**DEFAULT_SHADOWS, **dv.get("shadows", {})},
    }

    return theme


# ---------------------------------------------------------------------------
# Feature sort key — sort by sort_order (customer value top, utility bottom)
# ---------------------------------------------------------------------------

def feature_sort_key(slug, features_data):
    """Sort key: (sort_order or inf, slug) for stable ordering."""
    f = features_data.get(slug, {})
    order = f.get("sort_order")
    return (order if order is not None else float('inf'), slug)


def market_sort_key(slug, markets_data):
    """Sort key: (sort_order or inf, slug) for stable ordering."""
    m = markets_data.get(slug, {})
    order = m.get("sort_order")
    return (order if order is not None else float('inf'), slug)


# ---------------------------------------------------------------------------
# Communicate helpers — frontmatter parsing and preview extraction
# ---------------------------------------------------------------------------

# Use-case display order and human-readable labels
UC_LABELS = {
    "customer-narrative": "Customer Narratives",
    "pitch": "Pitches",
    "proposal": "Proposals",
    "market-brief": "Market Briefs",
    "repo-documentation": "Repository Documentation",
    "workbook": "Workbooks",
}
UC_ORDER = list(UC_LABELS.keys())

_FM_RE = re.compile(r'\A---\s*\n(.*?\n)---\s*\n', re.DOTALL)
_FM_LINE_RE = re.compile(r'^(\w[\w_]*):\s*(.*)')


def parse_yaml_frontmatter(text):
    """Extract YAML frontmatter from markdown text (stdlib only, no PyYAML).

    Returns (dict, body_text).  Handles flat key-value pairs and one level of
    nesting (indented children like source_entities).
    """
    m = _FM_RE.match(text)
    if not m:
        return {}, text
    block = m.group(1)
    body = text[m.end():]
    result = {}
    current_key = None
    for line in block.splitlines():
        if not line.strip():
            continue
        # Indented child line (2+ spaces)
        if line.startswith("  ") and current_key is not None:
            child_m = _FM_LINE_RE.match(line.strip())
            if child_m:
                ck, cv = child_m.group(1), child_m.group(2).strip().strip('"').strip("'")
                if not isinstance(result[current_key], dict):
                    result[current_key] = {}
                # Try to parse as int
                try:
                    cv = int(cv)
                except (ValueError, TypeError):
                    pass
                result[current_key][ck] = cv
            continue
        kv = _FM_LINE_RE.match(line)
        if kv:
            key, val = kv.group(1), kv.group(2).strip().strip('"').strip("'")
            current_key = key
            try:
                val = int(val)
            except (ValueError, TypeError):
                pass
            result[key] = val
        else:
            current_key = None
    return result, body


_MD_STRIP_RE = re.compile(r'^#{1,6}\s+.*$|<!--.*?-->|\*{1,2}|_{1,2}|`{1,3}', re.MULTILINE)


def extract_preview(body_text, max_chars=150):
    """Return the first ~max_chars of prose from markdown body text."""
    cleaned = _MD_STRIP_RE.sub('', body_text)
    lines = [l.strip() for l in cleaned.splitlines() if l.strip()]
    prose = ' '.join(lines)
    if len(prose) <= max_chars:
        return prose
    # Truncate at last word boundary before max_chars
    truncated = prose[:max_chars].rsplit(' ', 1)[0]
    return truncated + '...'


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def load_all_entities(project_dir):
    data = {
        "portfolio": load_json(os.path.join(project_dir, "portfolio.json")) or {},
        "products": {},
        "features": {},
        "markets": {},
        "propositions": {},
        "customers": {},
        "solutions": {},
        "packages": {},
        "competitors": {},
        "claims": None,
    }
    for entity_type in ["products", "features", "markets", "propositions", "customers", "solutions", "packages", "competitors"]:
        entity_dir = os.path.join(project_dir, entity_type)
        if os.path.isdir(entity_dir):
            for fp in sorted(glob.glob(os.path.join(entity_dir, "*.json"))):
                slug = os.path.basename(fp).replace(".json", "")
                obj = load_json(fp)
                if obj:
                    data[entity_type][slug] = obj
    claims_path = os.path.join(project_dir, "cogni-claims", "claims.json")
    if os.path.isfile(claims_path):
        data["claims"] = load_json(claims_path)

    # Load communicate output files with frontmatter, previews, and review verdicts
    communicate_dir = os.path.join(project_dir, "output", "communicate")
    communicate_files = []
    if os.path.isdir(communicate_dir):
        for root, _dirs, files in os.walk(communicate_dir):
            for fname in sorted(files):
                is_md = fname.endswith(".md") and not fname.endswith(".review.md")
                is_xlsx = fname.endswith(".xlsx")
                if not (is_md or is_xlsx):
                    continue
                fp = os.path.join(root, fname)
                rel = os.path.relpath(fp, project_dir)
                # Derive use case from first directory segment under communicate/
                rel_from_comm = os.path.relpath(fp, communicate_dir)
                parts = rel_from_comm.replace("\\", "/").split("/")
                use_case = parts[0] if len(parts) > 1 else "other"
                # Level from path pattern (backward compat)
                if "/customer/" in ("/" + rel):
                    level = "customer"
                elif "/market/" in ("/" + rel):
                    level = "market"
                else:
                    level = "overview"
                entry = {
                    "path": rel,
                    "name": fname.rsplit(".", 1)[0],
                    "use_case": use_case,
                    "level": level,
                    "scope": level,
                    "title": None,
                    "date_created": None,
                    "source_entities": None,
                    "arc_id": None,
                    "preview": None,
                    "review": None,
                    "is_xlsx": is_xlsx,
                    "file_size": None,
                }
                if is_xlsx:
                    try:
                        entry["file_size"] = os.path.getsize(fp)
                    except OSError:
                        pass
                if is_md:
                    try:
                        with open(fp, encoding="utf-8", errors="replace") as fh:
                            content = fh.read()
                        fm, body = parse_yaml_frontmatter(content)
                        entry["title"] = fm.get("title")
                        entry["date_created"] = fm.get("date_created", "")
                        if isinstance(entry["date_created"], str):
                            entry["date_created"] = entry["date_created"][:10]  # keep date only
                        entry["source_entities"] = fm.get("source_entities")
                        entry["arc_id"] = fm.get("arc_id")
                        if fm.get("scope"):
                            entry["scope"] = fm["scope"]
                            entry["level"] = fm["scope"]
                        entry["preview"] = extract_preview(body)
                    except Exception:
                        pass
                    review_path = fp.rsplit(".", 1)[0] + ".review.json"
                    if os.path.isfile(review_path):
                        entry["review"] = load_json(review_path)
                communicate_files.append(entry)
    data["communicate"] = communicate_files

    # Load TIPS data (portfolio-anchored STs and opportunities)
    data["tips"] = load_tips_data(project_dir, data)

    return data


def discover_tips_project(project_dir, data):
    """Find the linked TIPS project directory from portfolio data.

    Discovery chain:
    1. Scan propositions for tips_enrichment.pursuit_slug
    2. Scan workspace for cogni-trends/*/tips-project.json with matching portfolio_source
    """
    portfolio_slug = data.get("portfolio", {}).get("slug", "")

    # Primary: check propositions for tips_enrichment provenance
    for prop in data.get("propositions", {}).values():
        te = prop.get("tips_enrichment", {})
        pursuit_slug = te.get("pursuit_slug", "") if isinstance(te, dict) else ""
        if pursuit_slug:
            # Walk up from project_dir to find cogni-trends/{pursuit_slug}
            workspace = os.path.dirname(project_dir)
            tips_dir = os.path.join(workspace, "cogni-trends", pursuit_slug)
            if os.path.isdir(tips_dir):
                return tips_dir
            # Also check the portfolio's own parent (portfolio may be nested)
            for parent in [os.path.dirname(workspace), workspace]:
                tips_dir = os.path.join(parent, "cogni-trends", pursuit_slug)
                if os.path.isdir(tips_dir):
                    return tips_dir

    # Secondary: scan workspace for cogni-trends/*/tips-project.json
    workspace = os.path.dirname(project_dir)
    tips_base = os.path.join(workspace, "cogni-trends")
    if os.path.isdir(tips_base):
        for entry in os.listdir(tips_base):
            tp_path = os.path.join(tips_base, entry, "tips-project.json")
            if os.path.isfile(tp_path):
                tp = load_json(tp_path)
                if tp:
                    ps = tp.get("portfolio_source", {})
                    if ps.get("portfolio_slug") == portfolio_slug:
                        return os.path.join(tips_base, entry)

    return None


def load_tips_data(project_dir, data):
    """Load portfolio-anchored Solution Templates and opportunities from linked TIPS project."""
    tips_dir = discover_tips_project(project_dir, data)
    if not tips_dir:
        return {"anchored_sts": {}, "opportunities": None, "tips_dir": None}

    result = {"anchored_sts": {}, "opportunities": None, "tips_dir": tips_dir}

    # Load value model and extract portfolio-anchored STs
    vm_path = os.path.join(tips_dir, "tips-value-model.json")
    vm = load_json(vm_path)
    if vm:
        for st in vm.get("solution_templates", []):
            if st.get("generation_mode") == "portfolio-anchored" and st.get("portfolio_anchor"):
                anchor = st["portfolio_anchor"]
                feat_slug = anchor.get("feature_slug", "")
                if feat_slug:
                    result["anchored_sts"].setdefault(feat_slug, []).append(st)

    # Load opportunities
    opp_path = os.path.join(tips_dir, "portfolio-opportunities.json")
    opp_data = load_json(opp_path)
    if opp_data and opp_data.get("opportunities"):
        result["opportunities"] = opp_data

    return result


def get_status(project_dir):
    plugin_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    script = os.path.join(plugin_root, "scripts", "project-status.sh")
    try:
        result = subprocess.run(["bash", script, project_dir], capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception:
        pass
    return None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def escape_html(text):
    if not isinstance(text, str):
        text = str(text) if text is not None else ""
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def escape_js_string(text):
    if not isinstance(text, str):
        text = str(text) if text is not None else ""
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")


def format_currency(value, currency="EUR"):
    if value is None:
        return "N/A"
    if value >= 1_000_000_000:
        return f"{currency} {value / 1_000_000_000:.1f}B"
    if value >= 1_000_000:
        return f"{currency} {value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{currency} {value / 1_000:.0f}K"
    return f"{currency} {value:,.0f}"


# ---------------------------------------------------------------------------
# Communicate card renderer
# ---------------------------------------------------------------------------

def _render_communicate_card(cf, level_labels):
    """Render a single communicate file card as HTML."""
    name = escape_html(cf.get("title") or cf["name"])
    level = cf.get("scope", cf.get("level", "overview"))
    level_label = level_labels.get(level, level.title())
    is_xlsx = cf.get("is_xlsx", False)

    # Scope chip colors
    level_chip_bg = "rgba(46,125,50,0.1)" if level == "overview" else ("rgba(21,101,192,0.1)" if level == "market" else "rgba(156,39,176,0.1)")
    level_chip_color = "var(--green)" if level == "overview" else ("#1565C0" if level == "market" else "#9C27B0")

    card = f'    <div class="entity-card">\n'
    # Title row with scope chip
    card += f'      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">\n'
    card += f'        <div style="font-weight:600">{name}</div>\n'
    chips = f'<span style="padding:2px 8px;border-radius:6px;font-size:11px;background:{level_chip_bg};color:{level_chip_color}">{level_label}</span>'
    if cf.get("arc_id"):
        chips += f' <span class="arc-chip">{escape_html(cf["arc_id"])}</span>'
    if is_xlsx:
        size_str = ""
        if cf.get("file_size"):
            kb = cf["file_size"] / 1024
            size_str = f" ({kb:.0f} KB)" if kb < 1024 else f" ({kb/1024:.1f} MB)"
        chips += f' <span class="xlsx-badge">XLSX{size_str}</span>'
    card += f'        <div style="display:flex;gap:4px;align-items:center">{chips}</div>\n'
    card += f'      </div>\n'

    # Metadata row: date + source entities
    meta_parts = []
    if cf.get("date_created"):
        meta_parts.append(escape_html(str(cf["date_created"])))
    se = cf.get("source_entities")
    if se and isinstance(se, dict):
        entity_parts = []
        for ek in ["products", "features", "propositions", "solutions", "packages"]:
            ev = se.get(ek)
            if ev and isinstance(ev, int) and ev > 0:
                entity_parts.append(f"{ev} {ek}")
        if entity_parts:
            meta_parts.append(", ".join(entity_parts))
    if meta_parts:
        sep = ' <span class="sep">|</span> '
        card += f'      <div class="comm-meta">{sep.join(meta_parts)}</div>\n'

    # Content preview
    if cf.get("preview"):
        card += f'      <div class="comm-preview">{escape_html(cf["preview"])}</div>\n'

    # Review verdict + perspectives (same logic as before)
    review = cf.get("review")
    if review:
        verdict = review.get("final_verdict", "pending")
        score = review.get("final_score", 0)
        v_color = "var(--green)" if verdict == "accept" else ("var(--yellow)" if verdict == "revise" else "var(--red)")
        verdict_html = f'<span style="display:inline-block;padding:2px 8px;border-radius:6px;font-size:11px;font-weight:600;color:{v_color};background:rgba(0,0,0,0.05)">{verdict.title()} ({score})</span>'
        rounds = review.get("rounds", [])
        perspective_html = ""
        if rounds:
            latest = rounds[-1]
            fa = latest.get("full_assessment", {})
            perspectives = fa.get("stakeholder_reviews", [])
            if not perspectives:
                raw = fa.get("perspectives", [])
                if isinstance(raw, dict):
                    perspectives = list(raw.values())
                elif isinstance(raw, list):
                    perspectives = raw
            if not perspectives:
                for pkey in ["target_buyer", "marketing_director", "sales_director"]:
                    p = fa.get(pkey)
                    if p:
                        perspectives.append(p)
            if perspectives:
                perspective_html = '<div style="display:flex;gap:8px;margin-top:6px;flex-wrap:wrap">'
                for p in perspectives:
                    pname = escape_html(p.get("perspective", p.get("name", "?")))
                    pscore = p.get("score", 0)
                    pc = "var(--green)" if pscore >= 85 else ("var(--yellow)" if pscore >= 70 else "var(--red)")
                    perspective_html += f'<span style="font-size:11px;color:{pc}">{pname}: {pscore}</span>'
                perspective_html += '</div>'
        card += f'      <div style="margin-top:6px">{verdict_html}</div>\n'
        if perspective_html:
            card += f'      {perspective_html}\n'
    elif not is_xlsx:
        card += '      <div style="margin-top:6px"><span style="font-size:11px;color:var(--text2)">No review</span></div>\n'

    card += '    </div>\n'
    return card


# ---------------------------------------------------------------------------
# HTML generation
# ---------------------------------------------------------------------------

def generate_html(data, status, project_dir, theme):
    """Generate the full HTML dashboard string."""
    portfolio = data["portfolio"]
    company = portfolio.get("company", {})
    company_name = escape_html(company.get("name", "Unknown Company"))
    company_desc = escape_html(company.get("description", ""))
    company_industry = escape_html(company.get("industry", ""))
    project_slug = escape_html(portfolio.get("slug", ""))
    html_lang = escape_html(portfolio.get("language", "en"))

    counts = status.get("counts", {}) if status else {}
    completion = status.get("completion", {}) if status else {}
    phase = status.get("phase", "unknown") if status else "unknown"
    next_actions = status.get("next_actions", []) if status else []
    claims_status = status.get("claims", {}) if status else {}
    communicate_files = data.get("communicate", [])

    phases = ["products", "features", "markets", "customers", "propositions", "enrichment", "verification", "communicate", "complete"]
    phase_idx = phases.index(phase) if phase in phases else 0
    phase_pct = int((phase_idx / (len(phases) - 1)) * 100) if len(phases) > 1 else 0

    market_slugs = sorted(data["markets"].keys(), key=lambda s: market_sort_key(s, data["markets"]))
    feature_slugs = sorted(data["features"].keys(), key=lambda s: feature_sort_key(s, data["features"]))

    tips_data = data.get("tips", {})
    anchored_sts = tips_data.get("anchored_sts", {})
    opportunities_data = tips_data.get("opportunities")
    has_tips = bool(anchored_sts) or bool(opportunities_data)
    _tax = portfolio.get("taxonomy") or {}
    has_taxonomy = _tax.get("type") == "b2b-ict" and any(
        f.get("taxonomy_mapping", {}).get("category_id") for f in data["features"].values()
    )

    entities_json = json.dumps({
        "products": data["products"],
        "features": data["features"],
        "markets": data["markets"],
        "propositions": data["propositions"],
        "customers": data["customers"],
        "solutions": data["solutions"],
        "packages": data["packages"],
        "competitors": data["competitors"],
        "anchored_sts": anchored_sts,
    }, default=str)

    # Theme CSS variables
    c = theme["colors"]
    s = theme["status"]
    fonts = theme["fonts"]

    # Use design-variables fields when present, otherwise compute from theme
    surface2 = c.get("surface2") or derive_surface2(c["surface"])
    if "google_fonts_import" in theme and theme["google_fonts_import"]:
        fonts_import = theme["google_fonts_import"]
    else:
        fonts_url = google_fonts_url(theme)
        fonts_import = f"@import url('{fonts_url}');" if fonts_url else ""
    radius = theme.get("radius", "12px")
    shadows = theme.get("shadows", DEFAULT_SHADOWS)

    html = f"""<!DOCTYPE html>
<html lang="{html_lang}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{company_name} — Portfolio Dashboard</title>
<style>
{fonts_import}
:root {{
  --primary: {c['primary']};
  --secondary: {c['secondary']};
  --bg: {c['background']};
  --surface: {c['surface']};
  --surface2: {surface2};
  --surface-dark: {c['surface_dark']};
  --border: {c['border']};
  --text: {c['text']};
  --text2: {c['text_muted']};
  --text-light: {c['text_light']};
  --accent: {c['accent']};
  --accent-muted: {c['accent_muted']};
  --accent-dark: {c['accent_dark']};
  --green: {s['success']};
  --yellow: {s['warning']};
  --red: {s['danger']};
  --blue: {s['info']};
  --font-body: {fonts['body']};
  --font-headers: {fonts['headers']};
  --font-mono: {fonts['mono']};
  --radius: {radius};
  --shadow-sm: {shadows['sm']};
  --shadow-md: {shadows['md']};
  --shadow-lg: {shadows['lg']};
  --shadow-xl: {shadows['xl']};
}}

* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ background: var(--bg); color: var(--text); font-family: var(--font-body); line-height: 1.6; -webkit-font-smoothing: antialiased; }}
h1, h2, h3, h4, h5 {{ font-family: var(--font-headers); letter-spacing: -0.01em; }}
code, .mono {{ font-family: var(--font-mono); }}
.container {{ max-width: 1400px; margin: 0 auto; padding: 32px 24px; }}

/* Grain overlay for texture */
body::after {{
  content: "";
  position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
  pointer-events: none;
  z-index: 9999;
}}

/* Reveal animation */
.reveal {{
  opacity: 0;
  transform: translateY(18px);
  transition: opacity 0.5s cubic-bezier(0.22,1,0.36,1), transform 0.5s cubic-bezier(0.22,1,0.36,1);
}}
.reveal.visible {{
  opacity: 1;
  transform: translateY(0);
}}

/* Stagger children */
.stagger > * {{ opacity: 0; transform: translateY(14px); animation: staggerIn 0.45s cubic-bezier(0.22,1,0.36,1) forwards; }}
.stagger > *:nth-child(1) {{ animation-delay: 0.04s; }}
.stagger > *:nth-child(2) {{ animation-delay: 0.08s; }}
.stagger > *:nth-child(3) {{ animation-delay: 0.12s; }}
.stagger > *:nth-child(4) {{ animation-delay: 0.16s; }}
.stagger > *:nth-child(5) {{ animation-delay: 0.20s; }}
.stagger > *:nth-child(6) {{ animation-delay: 0.24s; }}
.stagger > *:nth-child(7) {{ animation-delay: 0.28s; }}
.stagger > *:nth-child(8) {{ animation-delay: 0.32s; }}
.stagger > *:nth-child(9) {{ animation-delay: 0.36s; }}
.stagger > *:nth-child(10) {{ animation-delay: 0.40s; }}

@keyframes staggerIn {{
  to {{ opacity: 1; transform: translateY(0); }}
}}

/* Animated bar fill */
@keyframes barFill {{
  from {{ width: 0; }}
}}

/* Header — gradient mesh anchor */
.header {{
  background: var(--surface-dark);
  color: var(--text-light);
  padding: 44px 40px 36px;
  border-radius: var(--radius);
  margin-bottom: 28px;
  position: relative;
  overflow: hidden;
  box-shadow: var(--shadow-lg);
}}
.header::before {{
  content: "";
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 60% 50% at 10% 90%, color-mix(in srgb, var(--accent) 18%, transparent) 0%, transparent 70%),
    radial-gradient(ellipse 40% 60% at 85% 20%, color-mix(in srgb, var(--accent) 10%, transparent) 0%, transparent 60%),
    radial-gradient(ellipse 50% 40% at 50% 50%, rgba(255,255,255,0.02) 0%, transparent 70%);
  pointer-events: none;
}}
.header::after {{
  content: "";
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.7' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.06'/%3E%3C/svg%3E");
  pointer-events: none;
}}
.header > * {{ position: relative; z-index: 1; }}
.header h1 {{
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 6px;
  color: var(--text-light);
  letter-spacing: -0.02em;
  line-height: 1.15;
}}
.header .meta {{
  color: rgba(255,255,255,0.55);
  font-size: 13px;
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  font-weight: 400;
}}
.header .meta span {{
  display: flex;
  align-items: center;
  gap: 6px;
  transition: color 0.2s;
}}
.header .meta span:hover {{ color: rgba(255,255,255,0.8); }}
.header .desc {{
  color: rgba(255,255,255,0.4);
  font-size: 14px;
  margin-top: 10px;
  max-width: 600px;
  line-height: 1.5;
}}

/* Phase progress */
.phase-bar {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 22px 28px;
  margin-bottom: 28px;
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.3s;
}}
.phase-bar:hover {{ box-shadow: var(--shadow-md); }}
.phase-bar h3 {{
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--text2);
  margin-bottom: 14px;
  font-weight: 600;
}}
.phase-steps {{ display: flex; gap: 4px; margin-bottom: 10px; }}
.phase-step {{
  flex: 1;
  height: 6px;
  border-radius: 3px;
  background: var(--surface2);
  transition: background 0.4s, box-shadow 0.4s;
}}
.phase-step.done {{ background: var(--accent-dark); }}
.phase-step.current {{
  background: var(--accent);
  box-shadow: 0 0 12px color-mix(in srgb, var(--accent) 40%, transparent);
  animation: pulseGlow 2.5s ease-in-out infinite;
}}
@keyframes pulseGlow {{
  0%, 100% {{ box-shadow: 0 0 8px color-mix(in srgb, var(--accent) 30%, transparent); }}
  50% {{ box-shadow: 0 0 18px color-mix(in srgb, var(--accent) 50%, transparent); }}
}}
.phase-label {{ font-size: 15px; font-weight: 600; }}
.phase-label .tag {{
  display: inline-block;
  background: var(--surface-dark);
  color: var(--accent);
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 5px;
  margin-left: 10px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-family: var(--font-mono);
  font-weight: 500;
}}

/* Cards grid */
.cards {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(175px, 1fr));
  gap: 14px;
  margin-bottom: 36px;
}}
.card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  cursor: default;
  transition: border-color 0.25s, box-shadow 0.25s, transform 0.25s;
  box-shadow: var(--shadow-sm);
  position: relative;
  overflow: hidden;
}}
.card::before {{
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--accent);
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.35s cubic-bezier(0.22,1,0.36,1);
}}
.card:hover {{
  border-color: var(--accent-muted);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}}
.card:hover::before {{ transform: scaleX(1); }}
.card .label {{
  font-size: 10px;
  color: var(--text2);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 6px;
  font-weight: 600;
}}
.card .value {{
  font-size: 30px;
  font-weight: 700;
  font-family: var(--font-mono);
  line-height: 1.1;
  letter-spacing: -0.02em;
  color: var(--secondary);
}}
.card .sub {{ font-size: 12px; color: var(--text2); margin-top: 4px; }}
.card .bar {{
  height: 4px;
  background: var(--surface2);
  border-radius: 2px;
  margin-top: 10px;
  overflow: hidden;
}}
.card .bar .fill {{
  height: 100%;
  border-radius: 2px;
  animation: barFill 0.8s cubic-bezier(0.22,1,0.36,1) forwards;
}}

/* Section */
.section {{ margin-bottom: 40px; }}
.section-title {{
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 18px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--primary);
  display: flex;
  align-items: center;
  gap: 10px;
}}
.section-title::before {{
  content: "";
  display: inline-block;
  width: 4px;
  height: 18px;
  background: var(--accent);
  border-radius: 2px;
  flex-shrink: 0;
}}

/* Matrix */
.matrix-wrap {{
  overflow-x: auto;
  margin-bottom: 32px;
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--border);
}}
.matrix {{ border-collapse: separate; border-spacing: 0; width: 100%; }}
.matrix th {{
  background: var(--surface);
  color: var(--text2);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 12px 10px;
  text-align: center;
  white-space: nowrap;
  position: sticky;
  top: 0;
  z-index: 3;
  border-bottom: 1px solid var(--border);
}}
.matrix th.corner {{ background: var(--surface); }}
.matrix td {{ padding: 3px; }}
.matrix .cell {{
  width: 100%;
  height: 44px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s cubic-bezier(0.22,1,0.36,1), box-shadow 0.2s;
  font-weight: 500;
}}
.matrix .cell:hover {{
  transform: scale(1.12);
  z-index: 2;
  position: relative;
}}
.cell.full {{
  background: var(--green);
  color: #fff;
}}
.cell.full:hover {{ box-shadow: 0 4px 20px color-mix(in srgb, var(--green) 35%, transparent); }}
.cell.partial {{
  background: var(--yellow);
  color: #fff;
}}
.cell.partial:hover {{ box-shadow: 0 4px 20px color-mix(in srgb, var(--yellow) 35%, transparent); }}
.cell.missing {{
  background: var(--red);
  color: #fff;
  opacity: 0.3;
}}
.cell.missing:hover {{ opacity: 0.6; box-shadow: 0 4px 16px color-mix(in srgb, var(--red) 25%, transparent); }}
.cell.excluded {{
  background: var(--muted);
  color: var(--text);
  opacity: 0.25;
  cursor: default;
}}
.cell.excluded:hover {{ opacity: 0.4; }}
.matrix .feature-label {{
  font-size: 13px;
  color: var(--text);
  padding: 10px 14px;
  white-space: nowrap;
  background: var(--surface);
  font-weight: 500;
  border-right: 1px solid var(--border);
}}
.matrix tbody tr {{ transition: background 0.2s; }}
.matrix tbody tr:hover .feature-label {{ color: var(--accent-dark); }}
.matrix .product-row td {{
  font-weight: 600;
  font-size: 13px;
  color: var(--text);
  background: color-mix(in srgb, var(--accent-dark) 8%, var(--surface));
  border-bottom: 2px solid var(--border);
  padding: 8px 12px;
  letter-spacing: 0.02em;
}}

/* Market cards */
.market-cards {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }}
.market-card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 22px;
  cursor: pointer;
  transition: border-color 0.25s, box-shadow 0.25s, transform 0.25s;
  box-shadow: var(--shadow-sm);
  position: relative;
  overflow: hidden;
}}
.market-card:hover {{
  border-color: var(--accent-muted);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}}
.market-card::after {{
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--blue), var(--accent-dark), var(--green));
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.4s cubic-bezier(0.22,1,0.36,1);
}}
.market-card:hover::after {{ transform: scaleX(1); }}
.market-card h4 {{ font-size: 16px; font-weight: 600; margin-bottom: 4px; letter-spacing: -0.01em; color: var(--primary); }}
.market-card .region-badge {{
  display: inline-block;
  background: var(--surface-dark);
  color: var(--accent);
  font-size: 10px;
  padding: 3px 10px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 10px;
  font-family: var(--font-mono);
  font-weight: 500;
}}
.market-card .desc {{ font-size: 13px; color: var(--text2); margin-bottom: 14px; line-height: 1.5; }}
.sizing-bars {{ display: flex; flex-direction: column; gap: 8px; }}
.sizing-row {{ display: flex; align-items: center; gap: 8px; font-size: 12px; }}
.sizing-row .sizing-label {{
  width: 36px;
  color: var(--text2);
  text-transform: uppercase;
  font-weight: 700;
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 0.04em;
}}
.sizing-row .sizing-bar {{
  flex: 1;
  height: 8px;
  background: var(--surface2);
  border-radius: 4px;
  overflow: hidden;
}}
.sizing-row .sizing-bar .fill {{
  height: 100%;
  border-radius: 4px;
  animation: barFill 1s cubic-bezier(0.22,1,0.36,1) forwards;
}}
.sizing-row .sizing-val {{
  width: 80px;
  text-align: right;
  color: var(--text);
  font-weight: 600;
  font-family: var(--font-mono);
  font-size: 11px;
}}

/* Product list */
.product-group {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  margin-bottom: 12px;
  overflow: hidden;
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.25s;
}}
.product-group:hover {{ box-shadow: var(--shadow-md); }}
.product-header {{
  padding: 18px 24px;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background 0.2s;
}}
.product-header:hover {{ background: var(--surface2); }}
.product-header h4 {{ font-size: 15px; font-weight: 600; }}
.product-header .badge {{
  font-size: 11px;
  color: var(--text2);
  background: var(--surface2);
  padding: 3px 10px;
  border-radius: 5px;
  font-weight: 500;
}}
.product-features {{ padding: 0 24px 18px; }}
.feature-item {{
  padding: 10px 0;
  border-top: 1px solid var(--border);
  font-size: 13px;
  transition: padding-left 0.2s;
}}
.feature-item:hover {{ padding-left: 6px; }}
.feature-item .fname {{ font-weight: 600; }}
.feature-item .fdesc {{ color: var(--text2); }}

/* Solutions table */
.solutions-table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
.solutions-table th {{
  text-align: left;
  padding: 12px 14px;
  background: var(--surface);
  color: var(--text2);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-weight: 700;
  border-bottom: 2px solid var(--border);
}}
.solutions-table td {{
  padding: 12px 14px;
  border-bottom: 1px solid var(--border);
  transition: background 0.15s;
}}
.solutions-table tr:hover td {{ background: var(--surface); }}
.price {{ font-weight: 600; font-family: var(--font-mono); letter-spacing: -0.01em; }}

/* Margin Health */
.margin-table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
.margin-table th {{
  text-align: left; padding: 10px 14px; background: var(--surface);
  color: var(--text2); font-size: 10px; text-transform: uppercase;
  letter-spacing: 0.06em; font-weight: 700; border-bottom: 2px solid var(--border);
}}
.margin-table td {{ padding: 10px 14px; border-bottom: 1px solid var(--border); }}
.margin-ok {{ color: var(--green); font-weight: 600; }}
.margin-warn {{ color: var(--yellow); font-weight: 600; }}
.margin-bad {{ color: var(--red); font-weight: 600; }}
.margin-badge {{
  display: inline-block; padding: 2px 8px; border-radius: 8px;
  font-size: 11px; font-weight: 600; font-family: var(--font-mono);
}}

/* Taxonomy Heatmap */
.tax-grid {{
  display: grid;
  gap: 2px;
  margin-top: 12px;
}}
.tax-dim-row {{
  display: grid;
  gap: 2px;
  align-items: stretch;
}}
.tax-dim-label {{
  background: var(--surface-dark);
  color: var(--text-light);
  padding: 8px 12px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  border-radius: 4px 0 0 4px;
  display: flex;
  align-items: center;
  white-space: nowrap;
}}
.tax-cell {{
  padding: 6px 8px;
  font-size: 11px;
  border-radius: 3px;
  text-align: center;
  font-weight: 600;
  transition: transform 0.15s;
  cursor: default;
  line-height: 1.3;
}}
.tax-cell:hover {{ transform: scale(1.05); z-index: 2; position: relative; }}
.tax-covered {{ background: rgba(46,125,50,0.15); color: var(--green); }}
.tax-empty {{ background: rgba(211,47,47,0.08); color: var(--red); }}
.tax-summary {{
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  align-items: center;
  margin-bottom: 16px;
  font-size: 13px;
}}
.tax-summary-chip {{
  padding: 6px 14px;
  border-radius: 20px;
  font-weight: 600;
  font-size: 12px;
}}
.tax-gap-item {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 12px 18px;
  margin-bottom: 6px;
}}
.tax-gap-dim {{
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--text2);
  margin-bottom: 6px;
}}
.tax-gap-cats {{
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}}
.tax-gap-cat {{
  background: rgba(211,47,47,0.08);
  color: var(--red);
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}}

/* Claims */
.claims-summary {{ display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }}
.claims-chip {{
  padding: 7px 16px;
  border-radius: 24px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.01em;
  transition: transform 0.2s;
}}
.claims-chip:hover {{ transform: scale(1.04); }}

/* Next actions */
.action-item {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px 22px;
  margin-bottom: 8px;
  display: flex;
  gap: 14px;
  align-items: center;
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.25s, transform 0.2s, border-color 0.25s;
}}
.action-item:hover {{
  box-shadow: var(--shadow-md);
  transform: translateX(4px);
  border-color: var(--accent-muted);
}}
.action-skill {{
  background: var(--surface-dark);
  color: var(--accent);
  padding: 4px 14px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
  font-family: var(--font-mono);
  letter-spacing: 0.02em;
}}
.action-reason {{ font-size: 14px; color: var(--text2); }}

/* Modal / Detail panel */
.overlay {{
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0);
  backdrop-filter: blur(0px);
  -webkit-backdrop-filter: blur(0px);
  z-index: 100;
  justify-content: center;
  align-items: flex-start;
  padding: 60px 24px;
  overflow-y: auto;
  transition: background 0.3s, backdrop-filter 0.3s, -webkit-backdrop-filter 0.3s;
}}
.overlay.open {{
  display: flex;
  background: rgba(0,0,0,0.45);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
}}
.panel {{
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 16px;
  max-width: 720px;
  width: 100%;
  padding: 32px 36px;
  position: relative;
  box-shadow: var(--shadow-xl);
  opacity: 0;
  transform: translateY(20px) scale(0.98);
  transition: opacity 0.3s cubic-bezier(0.22,1,0.36,1), transform 0.3s cubic-bezier(0.22,1,0.36,1);
}}
.overlay.open .panel {{
  opacity: 1;
  transform: translateY(0) scale(1);
}}
.panel-close {{
  position: absolute;
  top: 16px;
  right: 20px;
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text2);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  font-size: 18px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s, border-color 0.2s;
}}
.panel-close:hover {{
  background: var(--surface2);
  color: var(--text);
  border-color: var(--accent-muted);
}}
.panel h3 {{ font-size: 20px; margin-bottom: 4px; letter-spacing: -0.02em; color: var(--primary); }}
.panel .panel-sub {{ color: var(--text2); font-size: 12px; margin-bottom: 20px; font-family: var(--font-mono); letter-spacing: 0.01em; }}
.panel .section-label {{
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--accent-dark);
  font-weight: 700;
  margin-top: 20px;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 6px;
}}
.panel .section-label::after {{
  content: "";
  flex: 1;
  height: 1px;
  background: var(--border);
}}
.panel .stmt {{
  font-size: 14px;
  margin-bottom: 12px;
  line-height: 1.6;
  color: var(--text);
}}
.panel table {{ width: 100%; font-size: 13px; border-collapse: collapse; margin-top: 10px; }}
.panel table th {{
  text-align: left;
  padding: 8px 12px;
  color: var(--text2);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-weight: 700;
  border-bottom: 2px solid var(--border);
}}
.panel table td {{
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
}}
.competitor-card {{
  background: var(--surface);
  border-radius: 10px;
  padding: 14px 18px;
  margin-bottom: 10px;
  border: 1px solid var(--border);
  transition: border-color 0.2s;
}}
.competitor-card:hover {{ border-color: var(--accent-muted); }}
.competitor-card h5 {{ font-size: 14px; margin-bottom: 4px; }}
.competitor-card .comp-detail {{ font-size: 12px; color: var(--text2); margin-bottom: 2px; line-height: 1.5; }}
.comp-pills {{ display: flex; flex-wrap: wrap; gap: 5px; margin-top: 6px; }}
.comp-pill {{
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 5px;
  font-weight: 500;
}}
.comp-pill.strength {{ background: rgba(46,125,50,0.1); color: var(--green); }}
.comp-pill.weakness {{ background: rgba(211,47,47,0.1); color: var(--red); }}

/* Customer profile */
.profile-card {{
  background: var(--surface);
  border-radius: 10px;
  padding: 16px 20px;
  margin-bottom: 10px;
  border: 1px solid var(--border);
  transition: border-color 0.2s;
}}
.profile-card:hover {{ border-color: var(--accent-muted); }}
.profile-card h5 {{ font-size: 14px; margin-bottom: 2px; }}
.profile-card .profile-meta {{ font-size: 12px; color: var(--text2); margin-bottom: 10px; }}
.profile-list {{ list-style: none; padding: 0; }}
.profile-list li {{
  font-size: 12px;
  color: var(--text2);
  padding: 3px 0;
  padding-left: 16px;
  position: relative;
  line-height: 1.5;
}}
.profile-list li::before {{
  content: "";
  position: absolute;
  left: 0;
  top: 10px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent-dark);
}}

/* Named customers */
.customer-market-group {{
  margin-bottom: 20px;
}}
.customer-market-group h4 {{
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text2);
  margin-bottom: 10px;
  font-weight: 700;
}}
.customer-target-card {{
  background: var(--surface);
  border-radius: 10px;
  padding: 14px 18px;
  margin-bottom: 10px;
  border: 1px solid var(--border);
  transition: border-color 0.2s;
  cursor: pointer;
}}
.customer-target-card:hover {{ border-color: var(--accent-muted); }}
.customer-target-card h5 {{ font-size: 14px; margin-bottom: 4px; }}
.customer-target-card .ct-meta {{ font-size: 12px; color: var(--text2); margin-bottom: 6px; line-height: 1.5; }}
.fit-badge {{
  display: inline-block;
  font-size: 11px;
  padding: 2px 10px;
  border-radius: 5px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}}
.fit-badge.fit-high {{ background: rgba(46,125,50,0.12); color: var(--green); }}
.fit-badge.fit-medium {{ background: rgba(229,161,0,0.12); color: var(--yellow); }}
.fit-badge.fit-low {{ background: rgba(211,47,47,0.1); color: var(--red); }}
.stack-pill {{
  display: inline-block;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 5px;
  background: rgba(21,101,192,0.08);
  color: var(--info);
  font-weight: 500;
  margin-right: 4px;
  margin-bottom: 4px;
}}

/* Communicate section */
.comm-summary {{
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 18px;
  padding: 12px 16px;
  background: var(--surface);
  border-radius: 10px;
  border: 1px solid var(--border);
  align-items: center;
}}
.comm-summary-chip {{
  display: inline-block;
  font-size: 12px;
  padding: 3px 10px;
  border-radius: 6px;
  background: rgba(21,101,192,0.08);
  color: var(--info);
  font-weight: 500;
}}
.comm-summary-chip.coverage-full {{ background: rgba(46,125,50,0.1); color: var(--green); }}
.comm-summary-chip.coverage-partial {{ background: rgba(229,161,0,0.1); color: var(--yellow); }}
.comm-summary-chip.coverage-none {{ background: rgba(211,47,47,0.08); color: var(--red); }}
.comm-group {{
  margin-bottom: 22px;
}}
.comm-group-header {{
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text2);
  margin-bottom: 10px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 8px;
}}
.comm-group-header .count-badge {{
  font-size: 11px;
  padding: 1px 8px;
  border-radius: 5px;
  background: var(--surface);
  border: 1px solid var(--border);
  font-weight: 500;
  text-transform: none;
  letter-spacing: 0;
}}
.comm-preview {{
  font-style: italic;
  font-size: 12px;
  color: var(--text2);
  line-height: 1.4;
  margin-top: 6px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}}
.comm-meta {{
  font-size: 12px;
  color: var(--text2);
  margin-top: 4px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
}}
.comm-meta .sep {{ opacity: 0.3; }}
.arc-chip {{
  display: inline-block;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 5px;
  background: rgba(200,230,46,0.15);
  color: var(--accent-dark);
  font-weight: 600;
  letter-spacing: 0.03em;
}}
.xlsx-badge {{
  display: inline-block;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 5px;
  background: rgba(21,101,192,0.1);
  color: var(--info);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}}

/* Theme badge */
.theme-badge {{
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  color: rgba(255,255,255,0.35);
  font-family: var(--font-mono);
  margin-top: 12px;
  letter-spacing: 0.03em;
}}
.theme-badge .swatch {{
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 2px;
}}

/* Legend */
.matrix-legend {{
  font-size: 12px;
  color: var(--text2);
  display: flex;
  gap: 18px;
  margin-top: 8px;
  padding: 10px 14px;
  background: var(--surface);
  border-radius: 8px;
  border: 1px solid var(--border);
  width: fit-content;
}}
.matrix-legend span {{ display: flex; align-items: center; gap: 5px; }}
.legend-dot {{
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 3px;
}}

/* Responsive */
@media (max-width: 768px) {{
  .container {{ padding: 16px; }}
  .header {{ padding: 28px 24px 22px; }}
  .header h1 {{ font-size: 24px; }}
  .cards {{ grid-template-columns: repeat(2, 1fr); gap: 10px; }}
  .market-cards {{ grid-template-columns: 1fr; }}
  .panel {{ padding: 24px 20px; }}
  .section-title {{ font-size: 14px; }}
}}
@media (max-width: 480px) {{
  .cards {{ grid-template-columns: 1fr; }}
}}

/* Sticky navigation */
.topnav {{
  position: sticky;
  top: 0;
  z-index: 50;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border-bottom: 1px solid var(--border);
  padding: 10px 24px;
  margin: 0 -24px 24px;
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  align-items: center;
  transition: box-shadow 0.3s;
}}
.topnav.scrolled {{
  box-shadow: 0 2px 16px rgba(0,0,0,0.06);
}}
.topnav a {{
  font-size: 12px;
  font-weight: 500;
  padding: 5px 14px;
  border-radius: 20px;
  color: var(--text2);
  text-decoration: none;
  transition: background 0.2s, color 0.2s;
  white-space: nowrap;
  font-family: var(--font-body);
  letter-spacing: 0.01em;
}}
.topnav a:hover {{
  background: var(--surface2);
  color: var(--text);
}}
.topnav a.active {{
  background: var(--surface-dark);
  color: var(--accent);
  font-weight: 600;
}}
.topnav .nav-brand {{
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 14px;
  color: var(--primary);
  margin-right: 12px;
  letter-spacing: -0.02em;
}}

/* Priority badges */
.priority-badge {{
  display: inline-block;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 600;
  text-transform: lowercase;
  letter-spacing: 0.03em;
  font-family: var(--font-mono);
}}
.priority-beachhead {{ background: rgba(46,125,50,0.12); color: var(--green); }}
.priority-expansion {{ background: rgba(229,161,0,0.12); color: var(--yellow); }}
.priority-aspirational {{ background: rgba(107,114,128,0.12); color: var(--text2); }}

/* Readiness indicator */
.readiness {{
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  font-weight: 500;
  margin-left: 8px;
  font-family: var(--font-mono);
  letter-spacing: 0.02em;
}}
.readiness::before {{
  content: "";
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
}}
.readiness-ga {{ color: var(--green); }}
.readiness-ga::before {{ background: var(--green); box-shadow: 0 0 6px color-mix(in srgb, var(--green) 40%, transparent); }}
.readiness-beta {{ color: var(--yellow); }}
.readiness-beta::before {{ background: var(--yellow); }}
.readiness-planned {{ color: var(--text2); }}
.readiness-planned::before {{ background: var(--text2); opacity: 0.5; }}

/* Anchor badge on features */
.anchor-badge {{
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(21,101,192,0.1);
  color: var(--blue);
  margin-left: 8px;
  font-family: var(--font-mono);
  letter-spacing: 0.02em;
  cursor: pointer;
}}
.anchor-badge:hover {{
  background: rgba(21,101,192,0.18);
}}

/* Anchor Coverage section */
.anchor-summary {{
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
  margin-bottom: 20px;
}}
.anchor-summary-chip {{
  display: inline-block;
  font-size: 12px;
  padding: 4px 12px;
  border-radius: 6px;
  font-weight: 500;
}}
.anchor-card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px 20px;
  margin-bottom: 12px;
  transition: box-shadow 0.2s;
}}
.anchor-card:hover {{
  box-shadow: var(--shadow-sm);
}}
.anchor-card-header {{
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
}}
.anchor-card-header h4 {{
  font-size: 15px;
  font-weight: 600;
}}
.anchor-needs {{
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}}
.need-pill {{
  display: inline-block;
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 12px;
  font-weight: 500;
}}
.need-delivered {{
  background: rgba(46,125,50,0.1);
  color: var(--green);
}}
.need-undelivered {{
  background: rgba(211,47,47,0.1);
  color: var(--red);
}}
.anchor-detail {{
  display: none;
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px solid var(--border);
}}
.anchor-st-item {{
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 8px;
}}
.anchor-st-item h5 {{
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 4px;
}}
.quality-flag {{
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
  background: rgba(211,47,47,0.1);
  color: var(--red);
  font-family: var(--font-mono);
}}

/* Innovation Pipeline section */
.opp-cards {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
}}
.opp-card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  transition: box-shadow 0.2s, transform 0.15s;
}}
.opp-card:hover {{
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}}
.opp-card h4 {{
  font-size: 15px;
  font-weight: 600;
  margin-bottom: 8px;
}}
.opp-score-gauge {{
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 20px;
  font-weight: 700;
  font-family: var(--font-headers);
  letter-spacing: -0.02em;
}}
.opp-score-bar {{
  width: 60px;
  height: 6px;
  border-radius: 3px;
  background: var(--border);
  overflow: hidden;
}}
.opp-score-fill {{
  height: 100%;
  border-radius: 3px;
  transition: width 0.6s cubic-bezier(0.22,1,0.36,1);
}}
.opp-meta {{
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin: 8px 0;
}}
.opp-classify {{
  display: inline-block;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-family: var(--font-mono);
}}
.opp-classify-build {{ background: rgba(46,125,50,0.12); color: var(--green); }}
.opp-classify-buy {{ background: rgba(21,101,192,0.12); color: var(--blue); }}
.opp-classify-partner {{ background: rgba(229,161,0,0.12); color: var(--yellow); }}
.opp-priority-high {{ background: rgba(211,47,47,0.1); color: var(--red); }}
.opp-priority-medium {{ background: rgba(229,161,0,0.1); color: var(--yellow); }}
.opp-priority-low {{ background: rgba(107,114,128,0.1); color: var(--text2); }}
.pipeline-summary {{
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  align-items: center;
  margin-bottom: 20px;
}}
.pipeline-stat {{
  display: flex;
  flex-direction: column;
  align-items: center;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px 24px;
  min-width: 120px;
}}
.pipeline-stat .stat-value {{
  font-size: 28px;
  font-weight: 700;
  font-family: var(--font-headers);
  letter-spacing: -0.02em;
  color: var(--primary);
}}
.pipeline-stat .stat-label {{
  font-size: 11px;
  color: var(--text2);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 500;
}}

/* Revenue model chip */
.revenue-chip {{
  display: inline-block;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 4px;
  background: var(--surface2);
  color: var(--text2);
  font-family: var(--font-mono);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 500;
}}

/* Packages */
.package-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 16px;
}}
.package-card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 22px;
  cursor: pointer;
  transition: border-color 0.25s, box-shadow 0.25s, transform 0.25s;
  box-shadow: var(--shadow-sm);
  position: relative;
  overflow: hidden;
}}
.package-card:hover {{
  border-color: var(--accent-muted);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}}
.package-card::after {{
  content: "";
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--accent-dark), var(--accent), var(--accent-muted));
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.4s cubic-bezier(0.22,1,0.36,1);
}}
.package-card:hover::after {{ transform: scaleX(1); }}
.package-tier {{
  background: var(--bg);
  border-radius: 10px;
  padding: 14px 16px;
  margin-top: 10px;
  border: 1px solid var(--border);
  transition: border-color 0.2s;
}}
.package-tier:hover {{ border-color: var(--accent-muted); }}
.included-solution {{
  display: inline-block;
  font-size: 11px;
  padding: 2px 8px;
  background: var(--surface2);
  border-radius: 4px;
  margin: 2px;
  font-family: var(--font-mono);
  color: var(--text2);
  letter-spacing: 0.01em;
  transition: background 0.2s, color 0.2s;
}}
.included-solution:hover {{
  background: var(--accent);
  color: var(--bg);
}}
@media (max-width: 768px) {{
  .package-grid {{ grid-template-columns: 1fr; }}
  .topnav {{ padding: 8px 16px; margin: 0 -16px 16px; }}
  .topnav .nav-brand {{ display: none; }}
}}
</style>
</head>
<body>
<div class="container">

<!-- Navigation -->
<nav class="topnav" id="topnav">
  <span class="nav-brand">{company_name}</span>
  <a href="#" data-section="Entity">Overview</a>
  <a href="#" data-section="Products">Products</a>
  <a href="#" data-section="Markets">Markets</a>
  <a href="#" data-section="Matrix">Matrix</a>
  {'<a href="#" data-section="Taxonomy">Taxonomy</a>' if has_taxonomy else ''}
  {'<a href="#" data-section="Anchor">Anchors</a>' if anchored_sts else ''}
  <a href="#" data-section="Customers">Customers</a>
  <a href="#" data-section="Solutions">Solutions</a>
  <a href="#" data-section="Packages">Packages</a>
  <a href="#" data-section="Margin">Margins</a>
  {'<a href="#" data-section="Innovation">Pipeline</a>' if opportunities_data else ''}
  {'<a href="#" data-section="Communicate">Communicate</a>' if communicate_files else ''}
  <a href="#" data-section="Claims">Claims</a>
  <a href="#" data-section="Next">Actions</a>
</nav>

<!-- Header -->
<div class="header">
  <h1>{company_name}</h1>
  <div class="meta">
    <span>{company_industry}</span>
    <span>Project: {project_slug}</span>
    <span>Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}</span>
  </div>
  {f'<div class="desc">{escape_html(company_desc)}</div>' if company_desc else ''}
  <div class="theme-badge"><span class="swatch" style="background:var(--accent)"></span>Theme: {escape_html(theme["name"])}</div>
</div>

<!-- Phase Progress -->
<div class="phase-bar reveal">
  <h3>Workflow Progress</h3>
  <div class="phase-steps">
"""
    for i, p in enumerate(phases):
        cls = "done" if i < phase_idx else ("current" if i == phase_idx else "")
        html += f'    <div class="phase-step {cls}" title="{p}"></div>\n'

    html += f"""  </div>
  <div class="phase-label">
    Phase: {phase.title()} <span class="tag">{phase_pct}%</span>
  </div>
</div>

<!-- Entity Counts -->
<div class="section reveal">
  <div class="section-title">Entity Overview</div>
  <div class="cards stagger">
"""

    entity_cards = [
        ("Products", counts.get("products", 0), None, None),
        ("Features", counts.get("features", 0), None, None),
        ("Markets", counts.get("markets", 0), None, None),
        ("Propositions", counts.get("propositions", 0), counts.get("expected_propositions", 0), completion.get("propositions_pct", 0)),
        ("Customers", counts.get("customers", 0), counts.get("markets", 0), completion.get("customers_pct", 0)),
        ("Solutions", counts.get("solutions", 0), counts.get("propositions", 0), completion.get("solutions_pct", 0)),
        ("Packages", counts.get("packages", 0), len(status.get("packageable_pairs", [])) or None if status else None, completion.get("packages_pct", 0) if status and status.get("packageable_pairs") else None),
        ("Competitors", counts.get("competitors", 0), counts.get("propositions", 0), completion.get("competitors_pct", 0)),
    ]

    excluded_count = counts.get("excluded_pairs", 0)

    for label, val, expected, pct in entity_cards:
        excl_note = ""
        if label == "Propositions" and excluded_count > 0:
            excl_note = f" ({excluded_count} excluded)"
        sub = (f"of {expected}" if expected is not None else "") + excl_note
        bar_html = ""
        if pct is not None:
            color = "var(--green)" if pct >= 100 else ("var(--yellow)" if pct >= 50 else "var(--red)")
            bar_html = f'<div class="bar"><div class="fill" style="width:{min(pct,100)}%;background:{color}"></div></div>'
        html += f"""    <div class="card">
      <div class="label">{label}</div>
      <div class="value">{val}</div>
      {f'<div class="sub">{sub} ({pct}%)</div>' if pct is not None else ''}
      {bar_html}
    </div>
"""

    html += """  </div>
</div>
"""

    # --- Products & Features ---
    if data["products"]:
        html += """
<!-- Products & Features -->
<div class="section reveal">
  <div class="section-title">Products & Features</div>
"""
        for ps, p in sorted(data["products"].items()):
            pname = escape_html(p.get("name", ps))
            maturity = escape_html(p.get("maturity", ""))
            revenue_model = escape_html(p.get("revenue_model", ""))
            positioning = escape_html(p.get("positioning", ""))
            product_features = {fs: f for fs, f in data["features"].items() if f.get("product_slug") == ps}
            fcount = len(product_features)
            rev_badge = f'<span class="revenue-chip" style="margin-left:8px">{revenue_model}</span>' if revenue_model else ''

            html += f"""  <div class="product-group">
    <div class="product-header" onclick="this.nextElementSibling.style.display=this.nextElementSibling.style.display==='none'?'block':'none'">
      <h4>{pname} {f'<span style="font-size:12px;color:var(--text2);font-weight:400;margin-left:8px">{maturity}</span>' if maturity else ''}{rev_badge}</h4>
      <span class="badge">{fcount} feature{"s" if fcount != 1 else ""}</span>
    </div>
    <div class="product-features">
      {f'<div style="font-size:13px;color:var(--text2);margin-bottom:8px">{positioning}</div>' if positioning else ''}
"""
            for fs in sorted(product_features.keys(), key=lambda s: feature_sort_key(s, product_features)):
                f = product_features[fs]
                fname = escape_html(f.get("name", fs))
                fpurpose = escape_html(f.get("purpose", ""))
                fdesc = escape_html(f.get("description", ""))
                readiness = f.get("readiness", "")
                readiness_html = f'<span class="readiness readiness-{escape_html(readiness)}">{escape_html(readiness)}</span>' if readiness else ''
                # Anchor badge if this feature has portfolio-anchored STs
                feat_sts = anchored_sts.get(fs, [])
                anchor_html = f'<span class="anchor-badge" title="{len(feat_sts)} anchored Solution Template{"s" if len(feat_sts) != 1 else ""}">\u2693 {len(feat_sts)} ST{"s" if len(feat_sts) != 1 else ""}</span>' if feat_sts else ''
                purpose_html = f'<br><span class="fpurpose" style="color: var(--text2); font-style: italic; font-size: 0.85em;">{fpurpose}</span>' if fpurpose else ''
                html += f'      <div class="feature-item"><span class="fname">{fname}{readiness_html}{anchor_html}</span>{purpose_html}<br><span class="fdesc">{fdesc}</span></div>\n'
            html += "    </div>\n  </div>\n"
        html += "</div>\n"

    # --- Markets Overview ---
    if data["markets"]:
        html += """
<!-- Markets Overview -->
<div class="section reveal">
  <div class="section-title">Markets</div>
  <div class="market-cards stagger">
"""
        max_tam = max(
            (m.get("tam", {}).get("value", 0) or 0 for m in data["markets"].values()),
            default=1
        ) or 1

        for ms, m in sorted(data["markets"].items(), key=lambda item: market_sort_key(item[0], data["markets"])):
            region = escape_html(m.get("region", "?"))
            name = escape_html(m.get("name", ms))
            desc = escape_html(m.get("description", ""))
            priority = m.get("priority", "")
            priority_cls = f"priority-{priority}" if priority else ""
            tam = m.get("tam", {})
            sam = m.get("sam", {})
            som = m.get("som", {})
            tam_val = tam.get("value") or 0
            sam_val = sam.get("value") or 0
            som_val = som.get("value") or 0
            currency = tam.get("currency") or sam.get("currency") or som.get("currency") or "EUR"
            tam_pct = (tam_val / max_tam * 100) if max_tam else 0
            sam_pct = (sam_val / max_tam * 100) if max_tam else 0
            som_pct = (som_val / max_tam * 100) if max_tam else 0

            html += f"""    <div class="market-card" onclick="openMarket('{escape_js_string(ms)}')">
      <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;margin-bottom:10px"><span class="region-badge" style="margin-bottom:0">{region}</span>{f'<span class="priority-badge {priority_cls}">{escape_html(priority)}</span>' if priority else ''}</div>
      <h4>{name}</h4>
      <div class="desc">{desc}</div>
      <div class="sizing-bars">
        <div class="sizing-row"><span class="sizing-label">TAM</span><div class="sizing-bar"><div class="fill" style="width:{tam_pct:.0f}%;background:var(--blue)"></div></div><span class="sizing-val">{format_currency(tam_val, currency)}</span></div>
        <div class="sizing-row"><span class="sizing-label">SAM</span><div class="sizing-bar"><div class="fill" style="width:{sam_pct:.0f}%;background:var(--accent-dark)"></div></div><span class="sizing-val">{format_currency(sam_val, currency)}</span></div>
        <div class="sizing-row"><span class="sizing-label">SOM</span><div class="sizing-bar"><div class="fill" style="width:{som_pct:.0f}%;background:var(--green)"></div></div><span class="sizing-val">{format_currency(som_val, currency)}</span></div>
      </div>
    </div>
"""
        html += "  </div>\n</div>\n"

    # --- Feature x Market Matrix ---
    # Build excluded pairs lookup from status data
    _excluded_set = set()
    _excluded_reasons = {}
    if status:
        for ep in status.get("excluded_pairs", []):
            p = ep.get("pair", "")
            if p:
                _excluded_set.add(p)
                _excluded_reasons[p] = ep.get("reason", "Excluded")

    if feature_slugs and market_slugs:
        html += """
<!-- Feature x Market Matrix -->
<div class="section reveal">
  <div class="section-title">Feature x Market Matrix</div>
  <div class="matrix-wrap">
    <table class="matrix">
      <thead><tr><th class="corner"></th>
"""
        for ms in market_slugs:
            m = data["markets"][ms]
            html += f'        <th title="{escape_html(m.get("name", ms))}">{escape_html(ms)}</th>\n'
        html += "      </tr></thead>\n      <tbody>\n"

        # Group features by product
        num_cols = len(market_slugs) + 1
        product_groups = {}  # product_slug -> [feature_slugs]
        orphan_features = []
        for fs in feature_slugs:
            ps = data["features"][fs].get("product_slug", "")
            if ps and ps in data["products"]:
                product_groups.setdefault(ps, []).append(fs)
            else:
                orphan_features.append(fs)

        def _emit_feature_rows(feat_slugs):
            nonlocal html
            for fs in feat_slugs:
                f = data["features"][fs]
                html += f'      <tr><td class="feature-label" title="{escape_html(f.get("description", ""))}">{escape_html(f.get("name", fs))}</td>\n'
                for ms in market_slugs:
                    pair = f"{fs}--{ms}"
                    if pair in _excluded_set:
                        reason = _excluded_reasons.get(pair, "Excluded")
                        html += f'        <td><button class="cell excluded" title="{escape_html(reason)}">&#8709;</button></td>\n'
                        continue
                    has_prop = pair in data["propositions"]
                    has_sol = pair in data["solutions"]
                    if has_prop and has_sol:
                        cls = "full"
                        icon = "&#10003;"
                    elif has_prop:
                        cls = "partial"
                        icon = "&#9679;"
                    else:
                        cls = "missing"
                        icon = "&#10005;"
                    html += f'        <td><button class="cell {cls}" onclick="openProposition(\'{escape_js_string(pair)}\')" title="{escape_html(pair)}">{icon}</button></td>\n'
                html += "      </tr>\n"

        for ps in sorted(product_groups.keys()):
            pname = escape_html(data["products"][ps].get("name", ps))
            html += f'      <tr class="product-row"><td colspan="{num_cols}">{pname}</td></tr>\n'
            _emit_feature_rows(product_groups[ps])

        if orphan_features:
            if product_groups:
                html += f'      <tr class="product-row"><td colspan="{num_cols}">Other</td></tr>\n'
            _emit_feature_rows(orphan_features)
        html += "      </tbody>\n    </table>\n  </div>\n"
        html += '  <div class="matrix-legend">'
        html += '<span><span class="legend-dot" style="background:var(--green)"></span> Proposition + Solution</span>'
        html += '<span><span class="legend-dot" style="background:var(--yellow)"></span> Proposition only</span>'
        html += '<span><span class="legend-dot" style="background:var(--red);opacity:0.4"></span> Missing</span>'
        html += '<span><span class="legend-dot" style="background:var(--muted);opacity:0.3"></span> Excluded (N/A)</span>'
        html += '</div>\n</div>\n'

    # --- Taxonomy Coverage Heatmap & Gap Analysis ---
    taxonomy = portfolio.get("taxonomy")
    if has_taxonomy and taxonomy.get("type") == "b2b-ict":
        # Build the full taxonomy structure
        tax_dims = {
            0: ("Provider Profile Metrics", [
                ("0.1","Financial Scale"),("0.2","Workforce Capacity"),("0.3","Geographic Presence"),
                ("0.4","Market Position"),("0.5","Certifications & Accreditations"),("0.6","Partnership Ecosystem")]),
            1: ("Connectivity Services", [
                ("1.1","WAN Services"),("1.2","SASE"),("1.3","Internet & Cloud Connect"),
                ("1.4","5G & IoT Connectivity"),("1.5","Voice Services"),("1.6","LAN/WLAN Services"),("1.7","Network-as-a-Service")]),
            2: ("Security Services", [
                ("2.1","SOC/SIEM"),("2.2","IAM"),("2.3","Zero Trust"),("2.4","Cloud Security"),
                ("2.5","Endpoint Security"),("2.6","Network Security"),("2.7","Vulnerability Mgmt"),
                ("2.8","Security Awareness"),("2.9","Compliance & GRC"),("2.10","Data Protection")]),
            3: ("Digital Workplace", [
                ("3.1","Unified Comms"),("3.2","M365"),("3.3","Device Mgmt"),
                ("3.4","VDI & DaaS"),("3.5","IT Support"),("3.6","DEX"),("3.7","IT Asset Mgmt")]),
            4: ("Cloud Services", [
                ("4.1","Managed Hyperscaler"),("4.2","Multi-Cloud Mgmt"),("4.3","Private Cloud"),
                ("4.4","Hybrid Cloud"),("4.5","Cloud Migration"),("4.6","Cloud-Native"),("4.7","Sovereign Cloud"),("4.8","Enterprise on Cloud")]),
            5: ("Managed Infrastructure", [
                ("5.1","Data Center"),("5.2","Compute & Storage"),("5.3","Backup & DR"),
                ("5.4","Infra Monitoring"),("5.5","IT Outsourcing"),("5.6","DBA"),("5.7","Infra Automation")]),
            6: ("Application Services", [
                ("6.1","Custom Dev"),("6.2","App Modernization"),("6.3","Enterprise Platforms"),
                ("6.4","Integration & API"),("6.5","Low-Code/No-Code"),("6.6","AI, Data & Analytics"),("6.7","DevOps")]),
            7: ("Consulting Services", [
                ("7.1","IT Strategy"),("7.2","Digital Transform"),("7.3","Business Consulting"),
                ("7.4","Program Mgmt"),("7.5","Vendor Mgmt")]),
        }

        # Map features to categories
        cat_features = {}  # category_id -> list of feature slugs
        for fs, f in data["features"].items():
            tm = f.get("taxonomy_mapping")
            if tm and tm.get("category_id"):
                cid = tm["category_id"]
                cat_features.setdefault(cid, []).append(fs)

        total_cats = sum(len(cats) for _, cats in tax_dims.values())
        covered_cats = sum(1 for dim_id, (_, cats) in tax_dims.items() for cid, _ in cats if cid in cat_features)
        coverage_pct = int(covered_cats / total_cats * 100) if total_cats else 0

        # Max columns needed (Security has 10)
        max_cols = max(len(cats) for _, cats in tax_dims.values())

        html += f"""
<!-- Taxonomy Coverage -->
<div class="section reveal">
  <div class="section-title">Taxonomy Coverage</div>
  <div class="tax-summary">
    <span class="tax-summary-chip" style="background:rgba(46,125,50,0.1);color:var(--green)">{covered_cats} of {total_cats} categories covered ({coverage_pct}%)</span>
    <span class="tax-summary-chip" style="background:rgba(211,47,47,0.08);color:var(--red)">{total_cats - covered_cats} gaps</span>
    <span style="font-size:12px;color:var(--text2)">Based on {escape_html(taxonomy.get('type',''))} v{escape_html(str(taxonomy.get('version','')))}</span>
  </div>
  <div class="tax-grid">
"""
        for dim_id in range(8):
            dim_name, cats = tax_dims[dim_id]
            dim_covered = sum(1 for cid, _ in cats if cid in cat_features)
            html += f'    <div class="tax-dim-row" style="grid-template-columns: 180px repeat({len(cats)}, 1fr)">\n'
            html += f'      <div class="tax-dim-label">{dim_id}. {escape_html(dim_name)} ({dim_covered}/{len(cats)})</div>\n'
            for cid, cname in cats:
                feats = cat_features.get(cid, [])
                if feats:
                    feat_names = ", ".join(escape_html(data["features"][fs].get("name", fs)) for fs in feats[:3])
                    tooltip = f"{cid} {cname}: {feat_names}"
                    css_class = "tax-covered"
                    label = f"{cid}"
                else:
                    tooltip = f"{cid} {cname}: no features mapped"
                    css_class = "tax-empty"
                    label = f"{cid}"
                html += f'      <div class="tax-cell {css_class}" title="{escape_html(tooltip)}">{label}</div>\n'
            html += '    </div>\n'

        html += "  </div>\n"

        # Gap analysis: list uncovered categories grouped by dimension
        gaps = {}
        for dim_id in range(8):
            dim_name, cats = tax_dims[dim_id]
            uncovered = [(cid, cname) for cid, cname in cats if cid not in cat_features]
            if uncovered:
                gaps[dim_id] = (dim_name, uncovered)

        if gaps:
            html += '  <div style="margin-top:20px">\n'
            html += '    <div style="font-size:13px;font-weight:600;margin-bottom:10px;color:var(--text2)">Coverage Gaps — categories with no mapped features</div>\n'
            for dim_id, (dim_name, uncovered) in sorted(gaps.items()):
                html += f'    <div class="tax-gap-item">\n'
                html += f'      <div class="tax-gap-dim">{dim_id}. {escape_html(dim_name)} — {len(uncovered)} gap{"s" if len(uncovered) != 1 else ""}</div>\n'
                html += f'      <div class="tax-gap-cats">\n'
                for cid, cname in uncovered:
                    html += f'        <span class="tax-gap-cat">{cid} {escape_html(cname)}</span>\n'
                html += f'      </div>\n'
                html += f'    </div>\n'
            html += '  </div>\n'

        html += "</div>\n"

    # --- Portfolio Anchor Coverage ---
    if anchored_sts:
        total_features = len(data["features"])
        anchored_count = len(anchored_sts)
        total_sts = sum(len(sts) for sts in anchored_sts.values())
        all_undelivered = set()
        all_delivered = set()
        has_quality_issues = False
        for feat_slug, sts in anchored_sts.items():
            for st in sts:
                anchor = st.get("portfolio_anchor", {})
                for need in anchor.get("theme_needs_delivered", []):
                    all_delivered.add(need)
                for need in anchor.get("theme_needs_undelivered", []):
                    all_undelivered.add(need)
                if st.get("quality_flag"):
                    has_quality_issues = True

        html += f"""
<!-- Anchor Coverage -->
<div class="section reveal">
  <div class="section-title">Anchor Coverage</div>
  <div class="anchor-summary">
    <span class="anchor-summary-chip" style="background:rgba(21,101,192,0.1);color:var(--blue)">{anchored_count} of {total_features} features anchored</span>
    <span class="anchor-summary-chip" style="background:rgba(46,125,50,0.1);color:var(--green)">{total_sts} Solution Template{"s" if total_sts != 1 else ""}</span>
    <span class="anchor-summary-chip" style="background:rgba(46,125,50,0.08);color:var(--green)">{len(all_delivered)} delivered need{"s" if len(all_delivered) != 1 else ""}</span>
    <span class="anchor-summary-chip" style="background:rgba(211,47,47,0.08);color:var(--red)">{len(all_undelivered)} unmet need{"s" if len(all_undelivered) != 1 else ""}</span>
    {f'<span class="quality-flag">quality investment needed</span>' if has_quality_issues else ''}
  </div>
"""
        for feat_slug in sorted(anchored_sts.keys(), key=lambda s: feature_sort_key(s, data["features"])):
            sts = anchored_sts[feat_slug]
            feat = data["features"].get(feat_slug, {})
            feat_name = escape_html(feat.get("name", feat_slug))
            prod_slug = feat.get("product_slug", "")
            prod = data["products"].get(prod_slug, {})
            prod_name = escape_html(prod.get("name", prod_slug))

            # Aggregate needs for this feature
            feat_delivered = set()
            feat_undelivered = set()
            feat_quality = False
            for st in sts:
                anchor = st.get("portfolio_anchor", {})
                for n in anchor.get("theme_needs_delivered", []):
                    feat_delivered.add(n)
                for n in anchor.get("theme_needs_undelivered", []):
                    feat_undelivered.add(n)
                if st.get("quality_flag"):
                    feat_quality = True

            delivered_pills = "".join(f'<span class="need-pill need-delivered">{escape_html(n)}</span>' for n in sorted(feat_delivered))
            undelivered_pills = "".join(f'<span class="need-pill need-undelivered">{escape_html(n)}</span>' for n in sorted(feat_undelivered))

            card_id = f"anchor-{escape_html(feat_slug)}"
            html += f"""  <div class="anchor-card">
    <div class="anchor-card-header" onclick="var d=document.getElementById('{card_id}');d.style.display=d.style.display==='none'?'block':'none'">
      <h4>{feat_name} <span style="font-size:12px;color:var(--text2);font-weight:400;margin-left:8px">{prod_name}</span>
        {f'<span class="quality-flag" style="margin-left:8px">quality issue</span>' if feat_quality else ''}
      </h4>
      <span class="badge">{len(sts)} ST{"s" if len(sts) != 1 else ""}</span>
    </div>
    <div class="anchor-needs">
      {delivered_pills}{undelivered_pills}
    </div>
    <div class="anchor-detail" id="{card_id}">
"""
            for st in sorted(sts, key=lambda x: x.get("st_id", "")):
                st_name = escape_html(st.get("name", st.get("st_id", "Unknown")))
                st_id = escape_html(st.get("st_id", ""))
                theme_ref = escape_html(st.get("theme_ref", ""))
                qf = st.get("quality_flag", "")
                anchor = st.get("portfolio_anchor", {})
                st_delivered = "".join(f'<span class="need-pill need-delivered">{escape_html(n)}</span>' for n in anchor.get("theme_needs_delivered", []))
                st_undelivered = "".join(f'<span class="need-pill need-undelivered">{escape_html(n)}</span>' for n in anchor.get("theme_needs_undelivered", []))

                html += f"""      <div class="anchor-st-item">
        <h5>{st_name} <span style="font-size:11px;color:var(--text2);font-weight:400">{st_id}</span>
          {f'<span class="quality-flag" style="margin-left:6px">{escape_html(qf)}</span>' if qf else ''}
        </h5>
        <div style="font-size:11px;color:var(--text2);margin-bottom:6px">Theme: {theme_ref}</div>
        <div class="anchor-needs">{st_delivered}{st_undelivered}</div>
      </div>
"""
            html += "    </div>\n  </div>\n"

        # Unmet Needs Summary
        if all_undelivered:
            html += '  <div style="margin-top:16px;padding:14px 18px;background:rgba(211,47,47,0.04);border:1px solid rgba(211,47,47,0.12);border-radius:var(--radius)">\n'
            html += '    <div style="font-size:13px;font-weight:600;color:var(--red);margin-bottom:8px">Unmet Needs Feeding Opportunity Pipeline</div>\n'
            html += '    <div class="anchor-needs">\n'
            for need in sorted(all_undelivered):
                html += f'      <span class="need-pill need-undelivered">{escape_html(need)}</span>\n'
            html += '    </div>\n  </div>\n'

        html += "</div>\n"

    # --- Target Customers ---
    has_customer_data = False
    for cslug, cdata in data.get("customers", {}).items():
        if cdata.get("named_customers") or cdata.get("profiles"):
            has_customer_data = True
            break

    if has_customer_data:
        html += """
<!-- Target Customers -->
<div class="section reveal">
  <div class="section-title">Target Customers</div>
"""
        for cslug in sorted(data["customers"].keys()):
            cdata = data["customers"][cslug]
            profiles = cdata.get("profiles", [])
            nc_list = cdata.get("named_customers", [])
            if not profiles and not nc_list:
                continue
            mkt = data.get("markets", {}).get(cdata.get("market_slug", cslug), {})
            mkt_name = mkt.get("name", cslug)
            html += f'  <div class="customer-market-group">\n    <h4>{escape_html(mkt_name)}</h4>\n'

            # Buyer profiles (personas)
            if profiles:
                html += '    <div class="section-label" style="margin-top:4px">Buyer Profiles</div>\n'
                for prof in profiles:
                    role = escape_html(prof.get("role", ""))
                    seniority = escape_html(prof.get("seniority", ""))
                    decision_role = escape_html(prof.get("decision_role", ""))
                    meta_parts = [x for x in [seniority, decision_role] if x]
                    meta_str = " &bull; ".join(meta_parts)
                    html += f'    <div class="profile-card">\n'
                    html += f'      <h5>{role}</h5>\n'
                    if meta_str:
                        html += f'      <div class="profile-meta">{meta_str}</div>\n'
                    pain_pts = prof.get("pain_points", [])
                    if pain_pts:
                        html += '      <div style="font-size:12px;color:var(--text2);margin-bottom:2px">Pain Points</div>\n'
                        html += '      <ul class="profile-list">\n'
                        for pp in pain_pts:
                            html += f'        <li>{escape_html(pp)}</li>\n'
                        html += '      </ul>\n'
                    buying_criteria = prof.get("buying_criteria", [])
                    if buying_criteria:
                        html += '      <div style="font-size:12px;color:var(--text2);margin-top:6px;margin-bottom:2px">Buying Criteria</div>\n'
                        html += '      <ul class="profile-list">\n'
                        for bc in buying_criteria:
                            html += f'        <li>{escape_html(bc)}</li>\n'
                        html += '      </ul>\n'
                    html += '    </div>\n'

            # Named customers (researched companies)
            if nc_list:
                html += '    <div class="section-label" style="margin-top:12px">Target Companies</div>\n'
                for idx, nc in enumerate(nc_list):
                    name = escape_html(nc.get("name", "Unknown"))
                    industry = escape_html(nc.get("industry", ""))
                    hq = escape_html(nc.get("headquarters", ""))
                    emps = nc.get("employees")
                    emp_str = f"{emps:,}" if emps else ""
                    rev = nc.get("revenue", {})
                    rev_val = rev.get("value") if isinstance(rev, dict) else None
                    rev_cur = rev.get("currency", "EUR") if isinstance(rev, dict) else "EUR"
                    if rev_val and rev_val >= 1e9:
                        rev_str = f"{rev_cur} {rev_val/1e9:.1f}B"
                    elif rev_val and rev_val >= 1e6:
                        rev_str = f"{rev_cur} {rev_val/1e6:.0f}M"
                    elif rev_val:
                        rev_str = f"{rev_cur} {rev_val:,.0f}"
                    else:
                        rev_str = ""
                    fit = nc.get("fit_score", "")
                    fit_cls = f"fit-{fit}" if fit in ("high", "medium", "low") else ""
                    pain_pts = nc.get("pain_points", [])
                    pain_html = ", ".join(escape_html(p) for p in pain_pts[:3])

                    meta_parts = [x for x in [industry, hq, emp_str + (" employees" if emp_str else ""), rev_str] if x]
                    meta_str = " &bull; ".join(meta_parts)

                    html += f"""    <div class="customer-target-card" onclick="openNamedCustomer('{escape_html(cslug)}', {idx})">
      <div style="display:flex;justify-content:space-between;align-items:center">
        <h5>{name}</h5>
        {f'<span class="fit-badge {fit_cls}">{escape_html(fit)}</span>' if fit else ''}
      </div>
      <div class="ct-meta">{meta_str}</div>
      {f'<div style="font-size:12px;color:var(--text2)">{pain_html}</div>' if pain_html else ''}
    </div>
"""
            html += "  </div>\n"
        html += "</div>\n"

    # --- Solutions & Pricing ---
    if data["solutions"]:
        # Build blueprint version lookup from products
        product_bp_versions = {}
        for _ps, p_ent in data["products"].items():
            bp = p_ent.get("delivery_blueprint")
            if bp and "blueprint_version" in bp:
                product_bp_versions[p_ent.get("slug", _ps)] = bp["blueprint_version"]

        def blueprint_drift_badge(s_ent):
            """Return HTML badge for blueprint drift status."""
            bp_ref = s_ent.get("blueprint_ref")
            bp_ver = s_ent.get("blueprint_version")
            if not bp_ref or bp_ver is None:
                return ""
            current_ver = product_bp_versions.get(bp_ref)
            if current_ver is None:
                return ""
            if bp_ver < current_ver:
                return f' <span style="display:inline-block;padding:1px 6px;border-radius:4px;font-size:10px;font-weight:600;background:var(--status-fail);color:#fff" title="Blueprint v{bp_ver} → current v{current_ver}">drift v{bp_ver}→v{current_ver}</span>'
            return f' <span style="display:inline-block;padding:1px 6px;border-radius:4px;font-size:10px;font-weight:600;background:var(--status-pass);color:#fff" title="Blueprint v{bp_ver}">bp v{bp_ver}</span>'

        # Count drift stats for summary
        bp_drifted = sum(1 for s in data["solutions"].values() if s.get("blueprint_ref") and s.get("blueprint_version", 0) < product_bp_versions.get(s.get("blueprint_ref", ""), 0))
        bp_total = sum(1 for s in data["solutions"].values() if s.get("blueprint_ref"))

        # Separate solutions by type
        project_solutions = {}
        subscription_solutions = {}
        partnership_solutions = {}
        for ss, s_ent in sorted(data["solutions"].items()):
            sol_type = s_ent.get("solution_type", "project")
            if sol_type in ("subscription", "hybrid"):
                subscription_solutions[ss] = s_ent
            elif sol_type == "partnership":
                partnership_solutions[ss] = s_ent
            else:
                project_solutions[ss] = s_ent

        bp_summary = ""
        if bp_total > 0:
            bp_color = "var(--status-fail)" if bp_drifted > 0 else "var(--status-pass)"
            bp_summary = f'<div style="margin-bottom:12px;font-size:12px;color:var(--text2)">Blueprint coverage: {bp_total}/{len(data["solutions"])} solutions from blueprints' + (f' · <span style="color:{bp_color};font-weight:600">{bp_drifted} drifted</span>' if bp_drifted > 0 else ' · all current') + '</div>'

        html += f"""
<!-- Solutions & Pricing -->
<div class="section reveal">
  <div class="section-title">Solutions & Pricing</div>
  {bp_summary}
"""

        # Project solutions table
        if project_solutions:
            html += """  <div style="overflow-x:auto;margin-bottom:20px">
    <div style="font-size:13px;font-weight:600;margin-bottom:8px;color:var(--text2)">Project Solutions</div>
    <table class="solutions-table">
      <thead><tr><th>Proposition</th><th>Phases</th><th>Duration</th><th>PoV</th><th>Small</th><th>Medium</th><th>Large</th></tr></thead>
      <tbody>
"""
            for ss, s_ent in sorted(project_solutions.items()):
                impl = s_ent.get("implementation", [])
                pricing = s_ent.get("pricing", {})
                def safe_weeks(val):
                    try:
                        return int(val)
                    except (TypeError, ValueError):
                        return 0

                has_non_numeric = any(
                    not isinstance(ph.get("duration_weeks", 0), (int, float))
                    and not str(ph.get("duration_weeks", "0")).isdigit()
                    for ph in impl
                )
                total_weeks = sum(safe_weeks(ph.get("duration_weeks", 0)) for ph in impl)
                duration_display = f"{total_weeks}w+" if has_non_numeric else f"{total_weeks}w"
                phase_names = " → ".join(ph.get("phase", "?") for ph in impl)

                def tier_str(tier_key, pr=pricing):
                    t = pr.get(tier_key, {})
                    if not t:
                        return "—"
                    return format_currency(t.get("price"), t.get("currency", "EUR"))

                bp_badge = blueprint_drift_badge(s_ent)
                html += f"""        <tr style="cursor:pointer" onclick="openProposition('{escape_js_string(ss)}')">
          <td style="font-weight:500">{escape_html(ss)}{bp_badge}</td>
          <td style="font-size:12px;color:var(--text2)">{escape_html(phase_names)}</td>
          <td class="mono">{duration_display}</td>
          <td class="price">{tier_str("proof_of_value")}</td>
          <td class="price">{tier_str("small")}</td>
          <td class="price">{tier_str("medium")}</td>
          <td class="price">{tier_str("large")}</td>
        </tr>
"""
            html += "      </tbody>\n    </table>\n  </div>\n"

        # Subscription / hybrid solutions table
        if subscription_solutions:
            html += """  <div style="overflow-x:auto;margin-bottom:20px">
    <div style="font-size:13px;font-weight:600;margin-bottom:8px;color:var(--text2)">Subscription Solutions</div>
    <table class="solutions-table">
      <thead><tr><th>Proposition</th><th>Type</th><th>Onboarding</th><th>Free</th><th>Pro</th><th>Enterprise</th></tr></thead>
      <tbody>
"""
            for ss, s_ent in sorted(subscription_solutions.items()):
                sol_type = s_ent.get("solution_type", "subscription")
                sub = s_ent.get("subscription", {})
                tiers = sub.get("tiers", {})
                currency = sub.get("currency", "EUR")
                onb = s_ent.get("onboarding", {})
                onb_phases = onb.get("phases", [])
                onb_display = f"{len(onb_phases)} phase{'s' if len(onb_phases) != 1 else ''}" if onb_phases else "—"
                if onb.get("pricing", {}).get("included"):
                    onb_display += " (incl.)"

                def sub_tier_str(tier_key):
                    t = tiers.get(tier_key, {})
                    if not t:
                        return "—"
                    pm = t.get("price_monthly")
                    if pm is None:
                        return t.get("note", "Custom")
                    if pm == 0:
                        return "Free"
                    return format_currency(pm, currency) + "/mo"

                type_badge = f'<span style="font-size:10px;padding:2px 6px;border-radius:4px;background:var(--accent);color:var(--bg)">{escape_html(sol_type)}</span>'

                bp_badge = blueprint_drift_badge(s_ent)
                html += f"""        <tr style="cursor:pointer" onclick="openProposition('{escape_js_string(ss)}')">
          <td style="font-weight:500">{escape_html(ss)}{bp_badge}</td>
          <td>{type_badge}</td>
          <td class="mono">{onb_display}</td>
          <td class="price">{sub_tier_str("free")}</td>
          <td class="price">{sub_tier_str("pro")}</td>
          <td class="price">{sub_tier_str("enterprise")}</td>
        </tr>
"""
            html += "      </tbody>\n    </table>\n  </div>\n"

        # Partnership solutions table
        if partnership_solutions:
            html += """  <div style="overflow-x:auto;margin-bottom:20px">
    <div style="font-size:13px;font-weight:600;margin-bottom:8px;color:var(--text2)">Partnership Solutions</div>
    <table class="solutions-table">
      <thead><tr><th>Proposition</th><th>Stages</th><th>Revenue Share</th><th>Model</th></tr></thead>
      <tbody>
"""
            for ss, s_ent in sorted(partnership_solutions.items()):
                prog = s_ent.get("program", {})
                stages = prog.get("stages", [])
                stage_names = " → ".join(st.get("stage", "?") for st in stages)
                rev_share = prog.get("revenue_share", {})
                pct = rev_share.get("partner_pct", "?")
                model = rev_share.get("model", "?")

                bp_badge = blueprint_drift_badge(s_ent)
                html += f"""        <tr style="cursor:pointer" onclick="openProposition('{escape_js_string(ss)}')">
          <td style="font-weight:500">{escape_html(ss)}{bp_badge}</td>
          <td style="font-size:12px;color:var(--text2)">{escape_html(stage_names)}</td>
          <td class="price">{escape_html(str(pct))}%</td>
          <td>{escape_html(str(model))}</td>
        </tr>
"""
            html += "      </tbody>\n    </table>\n  </div>\n"

        html += "</div>\n"

    # --- Packages ---
    if data["packages"]:
        html += """
<!-- Packages -->
<div class="section reveal">
  <div class="section-title">Packages</div>
  <div class="package-grid stagger">
"""
        for pkg_slug, pkg in sorted(data["packages"].items()):
            pkg_name = escape_html(pkg.get("name", pkg_slug))
            pkg_type = escape_html(pkg.get("package_type", "project"))
            prod_slug = pkg.get("product_slug", "")
            mkt_slug = pkg.get("market_slug", "")
            prod = data["products"].get(prod_slug, {})
            mkt = data["markets"].get(mkt_slug, {})
            prod_name = escape_html(prod.get("name", prod_slug))
            mkt_name = escape_html(mkt.get("name", mkt_slug))
            positioning = escape_html(pkg.get("positioning", ""))
            savings = pkg.get("bundle_savings_pct")
            tiers = pkg.get("tiers", [])

            html += f"""    <div class="package-card" onclick="openPackage('{escape_js_string(pkg_slug)}')">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px">
        <div>
          <h4 style="font-size:16px;font-weight:600;margin-bottom:2px">{pkg_name}</h4>
          <div style="font-size:12px;color:var(--text2)">{prod_name} &rarr; {mkt_name}</div>
        </div>
        <span class="revenue-chip">{pkg_type}</span>
      </div>"""
            if positioning:
                html += f'      <div style="font-size:13px;color:var(--text2);margin-bottom:12px">{positioning}</div>\n'

            for tier in tiers:
                tier_name = escape_html(tier.get("name", tier.get("tier", "?")))
                scope = escape_html(tier.get("scope", ""))
                included = tier.get("included_solutions", [])
                if pkg.get("package_type") in ("subscription", "hybrid"):
                    pm = tier.get("price_monthly")
                    pa = tier.get("price_annual")
                    curr = tier.get("currency", "EUR")
                    if pm is not None and pm > 0:
                        price_display = format_currency(pm, curr) + "/mo"
                    elif pa is not None and pa > 0:
                        price_display = format_currency(pa, curr) + "/yr"
                    else:
                        price_display = "Free" if pm == 0 else "Custom"
                else:
                    price = tier.get("price")
                    curr = tier.get("currency", "EUR")
                    price_display = format_currency(price, curr) if price else "\u2014"

                html += f"""      <div class="package-tier">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px">
          <span style="font-weight:600;font-size:14px">{tier_name}</span>
          <span class="price" style="font-size:14px">{price_display}</span>
        </div>
        <div style="font-size:12px;color:var(--text2);margin-bottom:6px">{scope}</div>
        <div style="display:flex;flex-wrap:wrap;gap:4px">
"""
                for sol_slug in included:
                    html += f'          <span class="included-solution">{escape_html(sol_slug)}</span>\n'
                html += "        </div>\n      </div>\n"

            if savings:
                html += f'      <div style="font-size:12px;color:var(--green);margin-top:8px;font-weight:500">Bundle savings: {savings}%</div>\n'

            html += "    </div>\n"
        html += "  </div>\n</div>\n"

    # --- Margin Health ---
    # Check if any solutions have cost_model data
    solutions_with_cm = {ss: s_ent for ss, s_ent in data["solutions"].items() if s_ent.get("cost_model")}
    if solutions_with_cm:
        target_margin = 30
        try:
            pf = data.get("portfolio", {})
            target_margin = pf.get("delivery_defaults", {}).get("target_margin_pct", 30)
        except Exception:
            pass

        # Split by solution type for margin health
        project_cm = {ss: s for ss, s in solutions_with_cm.items() if s.get("solution_type", "project") in ("project", "")}
        subscription_cm = {ss: s for ss, s in solutions_with_cm.items() if s.get("solution_type") in ("subscription", "hybrid")}
        partnership_cm = {ss: s for ss, s in solutions_with_cm.items() if s.get("solution_type") == "partnership"}

        html += f"""
<!-- Margin Health (INTERNAL) -->
<div class="section reveal">
  <div class="section-title" style="display:flex;align-items:center;gap:10px">Margin Health
    <span style="font-size:10px;padding:3px 10px;border-radius:8px;background:var(--red);color:#fff;text-transform:uppercase;letter-spacing:0.06em;font-weight:700">Internal / Confidential</span>
  </div>
"""

        # Project margins (effort-based)
        if project_cm:
            html += f"""  <div style="font-size:13px;font-weight:600;margin-bottom:8px;color:var(--text2)">Project Margins (effort-based)</div>
  <div style="overflow-x:auto;margin-bottom:20px">
    <table class="margin-table">
      <thead><tr><th>Solution</th><th>PoV</th><th>Small</th><th>Medium</th><th>Large</th><th>Avg</th></tr></thead>
      <tbody>
"""
            for ss, s_ent in sorted(project_cm.items()):
                cm = s_ent["cost_model"]
                ebt = cm.get("effort_by_tier", {})
                margins = []

                def margin_cell(tier_key, is_pov=False):
                    tier = ebt.get(tier_key, {})
                    m = tier.get("margin_pct")
                    if m is None:
                        return '<td>—</td>'
                    margins.append(m)
                    threshold = 10 if is_pov else target_margin
                    if m < 0:
                        css = "margin-bad"
                    elif m < threshold:
                        css = "margin-warn"
                    else:
                        css = "margin-ok"
                    return f'<td><span class="margin-badge {css}">{m:.1f}%</span></td>'

                pov_cell = margin_cell("proof_of_value", is_pov=True)
                sm_cell = margin_cell("small")
                md_cell = margin_cell("medium")
                lg_cell = margin_cell("large")
                avg = sum(margins) / len(margins) if margins else 0
                avg_css = "margin-ok" if avg >= target_margin else ("margin-warn" if avg >= 0 else "margin-bad")

                html += f"""        <tr>
          <td style="font-weight:500">{escape_html(ss)}</td>
          {pov_cell}{sm_cell}{md_cell}{lg_cell}
          <td><span class="margin-badge {avg_css}">{avg:.1f}%</span></td>
        </tr>
"""
            html += "      </tbody>\n    </table>\n  </div>\n"

        # Subscription margins (unit economics)
        if subscription_cm:
            html += """  <div style="font-size:13px;font-weight:600;margin-bottom:8px;color:var(--text2)">Subscription Margins (unit economics)</div>
  <div style="overflow-x:auto;margin-bottom:20px">
    <table class="margin-table">
      <thead><tr><th>Solution</th><th>Gross Margin</th><th>LTV/CAC</th><th>Churn/mo</th><th>CAC</th><th>LTV</th></tr></thead>
      <tbody>
"""
            for ss, s_ent in sorted(subscription_cm.items()):
                cm = s_ent["cost_model"]
                ue = cm.get("unit_economics", {})
                gm = ue.get("gross_margin_pct")
                ltv_cac = ue.get("ltv_cac_ratio")
                churn = ue.get("churn_monthly_pct")
                cac = ue.get("cac")
                ltv = ue.get("ltv")

                def ue_cell(val, good_threshold, bad_threshold, fmt="{:.1f}%", reverse=False):
                    if val is None:
                        return '<td>—</td>'
                    if reverse:
                        css = "margin-ok" if val <= good_threshold else ("margin-warn" if val <= bad_threshold else "margin-bad")
                    else:
                        css = "margin-ok" if val >= good_threshold else ("margin-warn" if val >= bad_threshold else "margin-bad")
                    return f'<td><span class="margin-badge {css}">{fmt.format(val)}</span></td>'

                gm_cell = ue_cell(gm, 70, 50)
                ltv_cac_cell = ue_cell(ltv_cac, 3, 1, "{:.1f}x")
                churn_cell = ue_cell(churn, 3, 5, "{:.1f}%", reverse=True)
                cac_cell = f'<td class="price">{format_currency(cac, "EUR")}</td>' if cac is not None else '<td>—</td>'
                ltv_cell = f'<td class="price">{format_currency(ltv, "EUR")}</td>' if ltv is not None else '<td>—</td>'

                html += f"""        <tr>
          <td style="font-weight:500">{escape_html(ss)}</td>
          {gm_cell}{ltv_cac_cell}{churn_cell}{cac_cell}{ltv_cell}
        </tr>
"""
            html += "      </tbody>\n    </table>\n  </div>\n"

        html += f"""  <div style="font-size:12px;color:var(--text2);margin-top:10px">Project target margin: {target_margin}% (PoV: 10-20% acceptable). Subscription targets: gross margin &gt;70%, LTV/CAC &gt;3, churn &lt;5%/mo. <span class="margin-ok">Green</span> = on target, <span class="margin-warn">Yellow</span> = below target, <span class="margin-bad">Red</span> = negative/failing.</div>
</div>
"""

    # --- Innovation Pipeline ---
    if opportunities_data:
        opps = opportunities_data.get("opportunities", [])
        opp_summary = opportunities_data.get("summary", {})
        total_opps = opp_summary.get("total_opportunities", len(opps))
        total_rev = opp_summary.get("total_estimated_revenue", 0)
        opp_currency = opp_summary.get("currency", "EUR")
        by_class = opp_summary.get("by_classification", {})
        by_priority = opp_summary.get("by_priority", {})

        html += f"""
<!-- Innovation Pipeline -->
<div class="section reveal">
  <div class="section-title">Innovation Pipeline</div>
  <div class="pipeline-summary">
    <div class="pipeline-stat">
      <span class="stat-value">{total_opps}</span>
      <span class="stat-label">Opportunities</span>
    </div>
    <div class="pipeline-stat">
      <span class="stat-value">{format_currency(total_rev, opp_currency)}</span>
      <span class="stat-label">Est. Revenue</span>
    </div>
    <div class="pipeline-stat">
      <span class="stat-value" style="font-size:16px">{by_class.get('build',0)}B / {by_class.get('buy',0)}U / {by_class.get('partner',0)}P</span>
      <span class="stat-label">Build / Buy / Partner</span>
    </div>
  </div>
  <div class="opp-cards">
"""
        for opp in sorted(opps, key=lambda x: x.get("opportunity_score", 0), reverse=True):
            opp_name = escape_html(opp.get("st_name", opp.get("opportunity_id", "Unknown")))
            opp_id = escape_html(opp.get("opportunity_id", ""))
            score = opp.get("opportunity_score", 0)
            score_pct = min(score * 10, 100)
            # Color gradient: green > 7, yellow 4-7, red < 4
            if score >= 7:
                score_color = "var(--green)"
            elif score >= 4:
                score_color = "var(--yellow)"
            else:
                score_color = "var(--red)"

            classification = opp.get("classification", "")
            classify_cls = f"opp-classify-{classification}" if classification in ("build", "buy", "partner") else ""

            priority = opp.get("priority", "")
            priority_cls = f"opp-priority-{priority}" if priority in ("high", "medium", "low") else ""

            rev_est = opp.get("revenue_estimate", {})
            rev_val = rev_est.get("annual_value")
            rev_cur = rev_est.get("currency", opp_currency)
            rev_str = format_currency(rev_val, rev_cur) if rev_val else "TBD"
            rev_conf = escape_html(rev_est.get("confidence", ""))

            feat_spec = opp.get("feature_spec", {})
            feat_desc = escape_html(feat_spec.get("description", ""))
            unmet = feat_spec.get("unmet_needs", [])
            unmet_pills = "".join(f'<span class="need-pill need-undelivered">{escape_html(n)}</span>' for n in unmet)

            tips_ref = escape_html(opp.get("st_id", ""))

            html += f"""    <div class="opp-card">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px">
        <h4>{opp_name}</h4>
        <div class="opp-score-gauge">
          <div class="opp-score-bar"><div class="opp-score-fill" style="width:{score_pct}%;background:{score_color}"></div></div>
          <span style="color:{score_color}">{score:.1f}</span>
        </div>
      </div>
      <div class="opp-meta">
        {f'<span class="opp-classify {classify_cls}">{escape_html(classification)}</span>' if classification else ''}
        {f'<span class="opp-classify {priority_cls}">{escape_html(priority)}</span>' if priority else ''}
        <span style="font-size:12px;color:var(--text2)">{rev_str}{f" ({rev_conf})" if rev_conf else ""}</span>
      </div>
      {f'<div style="font-size:13px;color:var(--text2);margin-bottom:8px">{feat_desc}</div>' if feat_desc else ''}
      {f'<div class="anchor-needs">{unmet_pills}</div>' if unmet_pills else ''}
      {f'<div style="font-size:11px;color:var(--text2);margin-top:8px;font-family:var(--font-mono)">ST: {tips_ref}</div>' if tips_ref else ''}
    </div>
"""
        html += "  </div>\n</div>\n"

    # --- Customer-Facing Documentation (Communicate) ---
    if communicate_files:
        level_labels = {"overview": "Overview", "market": "Market", "customer": "Customer"}

        # Group files by use case
        uc_groups = {}
        for cf in communicate_files:
            uc = cf.get("use_case", "other")
            uc_groups.setdefault(uc, []).append(cf)

        # Build coverage stats against markets and propositions
        total_markets = len(data.get("markets", {}))
        total_propositions = len(data.get("propositions", {}))
        coverage = {}
        # Track which markets/propositions have files per use case
        for uc, files in uc_groups.items():
            market_slugs = set()
            prop_slugs = set()
            for cf in files:
                fname = cf["name"]
                if uc == "proposal":
                    # Proposals use {feature}--{market} naming
                    if "--" in fname:
                        prop_slugs.add(fname)
                elif cf.get("level") == "market" or cf.get("scope") == "market":
                    market_slugs.add(fname)
            if uc in ("customer-narrative", "pitch", "market-brief") and total_markets > 0:
                coverage[uc] = {"have": len(market_slugs), "total": total_markets, "unit": "markets"}
            elif uc == "proposal" and total_propositions > 0:
                coverage[uc] = {"have": len(prop_slugs), "total": total_propositions, "unit": "propositions"}

        html += """
<!-- Customer-Facing Documentation -->
<div class="section reveal" data-section="Communicate">
  <div class="section-title">Portfolio Communications</div>
"""
        # Coverage summary bar
        total_files = len(communicate_files)
        total_ucs = len(uc_groups)
        html += f'  <div class="comm-summary">\n'
        html += f'    <span class="comm-summary-chip">{total_ucs} use case{"s" if total_ucs != 1 else ""}</span>\n'
        html += f'    <span class="comm-summary-chip">{total_files} file{"s" if total_files != 1 else ""}</span>\n'
        for uc_id, cov in coverage.items():
            uc_label = UC_LABELS.get(uc_id, uc_id.replace("-", " ").title())
            pct = cov["have"] / cov["total"] if cov["total"] else 0
            css_cls = "coverage-full" if pct >= 1.0 else ("coverage-partial" if pct > 0 else "coverage-none")
            html += f'    <span class="comm-summary-chip {css_cls}">{uc_label}: {cov["have"]}/{cov["total"]} {cov["unit"]}</span>\n'
        html += '  </div>\n'

        # Render each use-case group in defined order, then any remaining
        rendered_ucs = set()
        for uc_id in UC_ORDER:
            if uc_id not in uc_groups:
                continue
            rendered_ucs.add(uc_id)
            uc_label = UC_LABELS.get(uc_id, uc_id.replace("-", " ").title())
            group_files = uc_groups[uc_id]
            html += f'  <div class="comm-group">\n'
            html += f'    <div class="comm-group-header">{uc_label}<span class="count-badge">{len(group_files)}</span></div>\n'
            html += '    <div class="card-grid">\n'
            for cf in group_files:
                html += _render_communicate_card(cf, level_labels)
            html += '    </div>\n  </div>\n'

        # Render any unknown use cases under "Other"
        other_ucs = [uc for uc in uc_groups if uc not in rendered_ucs]
        for uc_id in sorted(other_ucs):
            uc_label = uc_id.replace("-", " ").title()
            group_files = uc_groups[uc_id]
            html += f'  <div class="comm-group">\n'
            html += f'    <div class="comm-group-header">{escape_html(uc_label)}<span class="count-badge">{len(group_files)}</span></div>\n'
            html += '    <div class="card-grid">\n'
            for cf in group_files:
                html += _render_communicate_card(cf, level_labels)
            html += '    </div>\n  </div>\n'

        html += "</div>\n"

    # --- Claims Status ---
    claims_total = claims_status.get("total", 0)
    if claims_total > 0:
        verified = claims_status.get("verified", 0)
        resolved = claims_status.get("resolved", 0)
        unverified = claims_status.get("unverified", 0)
        deviated = claims_status.get("deviated", 0)
        unavailable = claims_status.get("source_unavailable", 0)
        clean = verified + resolved
        clean_pct = int(clean / claims_total * 100) if claims_total else 0

        html += f"""
<!-- Claims Status -->
<div class="section reveal">
  <div class="section-title">Claims Verification</div>
  <div style="margin-bottom:12px">
    <div class="bar" style="height:8px;width:100%;max-width:500px">
      <div class="fill" style="width:{clean_pct}%;background:var(--green)"></div>
    </div>
    <div style="font-size:13px;color:var(--text2);margin-top:4px">{clean} of {claims_total} claims verified ({clean_pct}%)</div>
  </div>
  <div class="claims-summary">
    <span class="claims-chip" style="background:rgba(46,125,50,0.1);color:var(--green)">Verified: {verified}</span>
    <span class="claims-chip" style="background:rgba(46,125,50,0.06);color:var(--green)">Resolved: {resolved}</span>
    <span class="claims-chip" style="background:rgba(229,161,0,0.1);color:var(--yellow)">Unverified: {unverified}</span>
    <span class="claims-chip" style="background:rgba(211,47,47,0.1);color:var(--red)">Deviated: {deviated}</span>
    <span class="claims-chip" style="background:rgba(107,114,128,0.1);color:var(--text2)">Unavailable: {unavailable}</span>
  </div>
</div>
"""

    # --- Next Actions ---
    if next_actions:
        html += """
<!-- Next Actions -->
<div class="section reveal">
  <div class="section-title">Recommended Next Actions</div>
"""
        for action in next_actions:
            skill = escape_html(action.get("skill", ""))
            reason = escape_html(action.get("reason", ""))
            html += f"""  <div class="action-item">
    <span class="action-skill">{skill}</span>
    <span class="action-reason">{reason}</span>
  </div>
"""
        html += "</div>\n"

    # --- Detail Panel (Modal) + JS ---
    html += f"""
<!-- Detail Panel -->
<div class="overlay" id="overlay" onclick="if(event.target===this)closePanel()">
  <div class="panel" id="panel"></div>
</div>

<script>
const E = {entities_json};

function closePanel() {{
  const ov = document.getElementById('overlay');
  ov.classList.remove('open');
  setTimeout(function() {{ if (!ov.classList.contains('open')) ov.style.display = 'none'; }}, 350);
}}

document.addEventListener('keydown', e => {{ if(e.key==='Escape') closePanel(); }});

function openProposition(slug) {{
  const p = E.propositions[slug];
  const s = E.solutions[slug];
  const c = E.competitors[slug];
  const parts = slug.split('--');
  const fSlug = parts[0];
  const mSlug = parts.slice(1).join('--');
  const f = E.features[fSlug] || {{}};
  const m = E.markets[mSlug] || {{}};

  let html = '<button class="panel-close" onclick="closePanel()">&times;</button>';
  html += '<h3>' + esc(f.name || fSlug) + ' &rarr; ' + esc(m.name || mSlug) + '</h3>';
  html += '<div class="panel-sub">' + esc(slug) + '</div>';

  if (p) {{
    html += '<div class="section-label">IS (What it is)</div><div class="stmt">' + esc(p.is_statement || '') + '</div>';
    html += '<div class="section-label">DOES (What it does)</div><div class="stmt">' + esc(p.does_statement || '') + '</div>';
    html += '<div class="section-label">MEANS (What it means)</div><div class="stmt">' + esc(p.means_statement || '') + '</div>';

    if (p.evidence && p.evidence.length) {{
      html += '<div class="section-label">Evidence</div>';
      p.evidence.forEach(e => {{
        html += '<div style="font-size:13px;color:var(--text2);margin-bottom:4px">&bull; ' + esc(e.statement || '');
        if (e.source_url) html += ' <a href="' + esc(e.source_url) + '" target="_blank" style="color:var(--accent-dark)">[source]</a>';
        html += '</div>';
      }});
    }}
  }} else {{
    html += '<div style="color:var(--red);margin:16px 0">No proposition created yet for this Feature x Market pair.</div>';
  }}

  if (s) {{
    var sType = s.solution_type || 'project';
    html += '<div class="section-label">Solution <span class="revenue-chip">' + esc(sType) + '</span></div>';

    // Implementation / Onboarding / Program phases
    var phases = s.implementation || (s.onboarding && s.onboarding.phases) || (s.program && s.program.stages) || [];
    if (phases.length) {{
      var phLabel = sType === 'partnership' ? 'Stage' : 'Phase';
      html += '<table><thead><tr><th>' + phLabel + '</th><th>Duration</th><th>Description</th></tr></thead><tbody>';
      phases.forEach(function(ph) {{
        var dur = ph.duration_weeks != null ? (isNaN(ph.duration_weeks) ? esc(String(ph.duration_weeks)) : ph.duration_weeks + 'w') : (ph.duration_months != null ? ph.duration_months + 'mo' : '\u2014');
        html += '<tr><td style="font-weight:500">' + esc(ph.phase || ph.stage || '') + '</td><td class="mono">' + dur + '</td><td style="color:var(--text2)">' + esc(ph.description || ph.commitment || '') + '</td></tr>';
      }});
      html += '</tbody></table>';
    }}

    // Pricing by solution type
    if (sType === 'project' || (!sType && s.pricing)) {{
      html += '<div class="section-label">Pricing Tiers</div>';
      html += '<table><thead><tr><th>Tier</th><th>Price</th><th>Scope</th></tr></thead><tbody>';
      ['proof_of_value','small','medium','large'].forEach(function(tier) {{
        var t = (s.pricing || {{}})[tier];
        if (t) {{
          var label = tier === 'proof_of_value' ? 'Proof of Value' : tier.charAt(0).toUpperCase() + tier.slice(1);
          html += '<tr><td style="font-weight:500">' + label + '</td><td class="price">' + fmtCurrency(t.price, t.currency) + '</td><td style="color:var(--text2)">' + esc(t.scope || '') + '</td></tr>';
        }}
      }});
      html += '</tbody></table>';
    }} else if (sType === 'subscription' || sType === 'hybrid') {{
      var sub = s.subscription || {{}};
      var stiers = sub.tiers || {{}};
      var cur = sub.currency || 'EUR';
      html += '<div class="section-label">Subscription Tiers</div>';
      html += '<table><thead><tr><th>Tier</th><th>Monthly</th><th>Annual</th><th>Scope</th></tr></thead><tbody>';
      ['free','starter','pro','professional','enterprise'].forEach(function(tk) {{
        var t = stiers[tk];
        if (t) {{
          var pm = t.price_monthly != null ? (t.price_monthly === 0 ? 'Free' : fmtCurrency(t.price_monthly, cur) + '/mo') : '\u2014';
          var pa = t.price_annual != null ? (t.price_annual === 0 ? 'Free' : fmtCurrency(t.price_annual, cur) + '/yr') : '\u2014';
          html += '<tr><td style="font-weight:500">' + tk.charAt(0).toUpperCase() + tk.slice(1) + '</td><td class="price">' + pm + '</td><td class="price">' + pa + '</td><td style="color:var(--text2)">' + esc(t.scope || t.note || '') + '</td></tr>';
        }}
      }});
      html += '</tbody></table>';
      var ps = s.professional_services;
      if (ps && ps.options && ps.options.length) {{
        html += '<div class="section-label">Professional Services</div>';
        ps.options.forEach(function(opt) {{
          html += '<div style="background:var(--surface);border-radius:8px;padding:10px 14px;margin-bottom:6px;border:1px solid var(--border)">';
          html += '<div style="font-weight:500;font-size:13px">' + esc(opt.name || '') + ' <span class="price">' + fmtCurrency(opt.price, opt.currency) + '</span></div>';
          html += '<div style="font-size:12px;color:var(--text2)">' + esc(opt.scope || '') + '</div></div>';
        }});
      }}
    }} else if (sType === 'partnership') {{
      var prog = s.program || {{}};
      var rev = prog.revenue_share || {{}};
      if (rev.partner_pct != null) {{
        html += '<div class="section-label">Revenue Share</div>';
        html += '<div style="background:var(--surface);border-radius:8px;padding:14px 18px;border:1px solid var(--border)">';
        html += '<div style="font-size:24px;font-weight:700;font-family:var(--font-mono);color:var(--accent-dark)">' + rev.partner_pct + '%</div>';
        html += '<div style="font-size:12px;color:var(--text2)">' + esc(rev.model || '') + ' \u2014 ' + esc(rev.description || '') + '</div>';
        html += '</div>';
      }}
    }}

    // Cost model summary (if present)
    var cm = s.cost_model;
    if (cm && cm.unit_economics) {{
      var ue = cm.unit_economics;
      html += '<div class="section-label">Unit Economics</div>';
      html += '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">';
      if (ue.gross_margin_pct != null) html += '<div style="background:var(--surface);border-radius:8px;padding:10px 14px;text-align:center;border:1px solid var(--border)"><div style="font-size:20px;font-weight:700;font-family:var(--font-mono)">' + ue.gross_margin_pct + '%</div><div style="font-size:10px;color:var(--text2);text-transform:uppercase">Gross Margin</div></div>';
      if (ue.ltv_cac_ratio != null) html += '<div style="background:var(--surface);border-radius:8px;padding:10px 14px;text-align:center;border:1px solid var(--border)"><div style="font-size:20px;font-weight:700;font-family:var(--font-mono)">' + ue.ltv_cac_ratio + 'x</div><div style="font-size:10px;color:var(--text2);text-transform:uppercase">LTV/CAC</div></div>';
      if (ue.churn_monthly_pct != null) html += '<div style="background:var(--surface);border-radius:8px;padding:10px 14px;text-align:center;border:1px solid var(--border)"><div style="font-size:20px;font-weight:700;font-family:var(--font-mono)">' + ue.churn_monthly_pct + '%</div><div style="font-size:10px;color:var(--text2);text-transform:uppercase">Churn/mo</div></div>';
      html += '</div>';
    }}
  }}

  if (c && c.competitors && c.competitors.length) {{
    html += '<div class="section-label">Competitors</div>';
    c.competitors.forEach(comp => {{
      html += '<div class="competitor-card">';
      html += '<h5>' + esc(comp.name) + '</h5>';
      if (comp.positioning) html += '<div class="comp-detail">' + esc(comp.positioning) + '</div>';
      if (comp.differentiation) html += '<div class="comp-detail" style="color:var(--accent-dark);margin-top:4px">' + esc(comp.differentiation) + '</div>';
      html += '<div class="comp-pills">';
      (comp.strengths || []).forEach(s => {{ html += '<span class="comp-pill strength">' + esc(s) + '</span>'; }});
      (comp.weaknesses || []).forEach(w => {{ html += '<span class="comp-pill weakness">' + esc(w) + '</span>'; }});
      html += '</div></div>';
    }});
  }}

  document.getElementById('panel').innerHTML = html;
  var ov = document.getElementById('overlay');
  ov.style.display = 'flex';
  requestAnimationFrame(function() {{ ov.classList.add('open'); }});
}}

function openMarket(slug) {{
  const m = E.markets[slug];
  if (!m) return;
  const cust = E.customers[slug];

  let html = '<button class="panel-close" onclick="closePanel()">&times;</button>';
  html += '<h3>' + esc(m.name || slug) + '</h3>';
  html += '<div class="panel-sub">' + esc(m.region || '') + ' &bull; ' + esc(slug) + '</div>';
  html += '<div class="stmt">' + esc(m.description || '') + '</div>';

  if (m.segmentation) {{
    html += '<div class="section-label">Segmentation</div>';
    html += '<table><tbody>';
    Object.entries(m.segmentation).forEach(([k,v]) => {{
      html += '<tr><td style="color:var(--text2)">' + esc(k) + '</td><td>' + esc(v) + '</td></tr>';
    }});
    html += '</tbody></table>';
  }}

  html += '<div class="section-label">Market Sizing</div>';
  html += '<table><thead><tr><th>Metric</th><th>Value</th><th>Source</th></tr></thead><tbody>';
  ['tam','sam','som'].forEach(key => {{
    const d = m[key];
    if (d) {{
      html += '<tr><td style="font-weight:500">' + key.toUpperCase() + '</td><td class="price">' + fmtCurrency(d.value, d.currency) + '</td><td style="color:var(--text2);font-size:12px">' + esc(d.source || d.description || '') + '</td></tr>';
    }}
  }});
  html += '</tbody></table>';

  if (cust && cust.profiles && cust.profiles.length) {{
    html += '<div class="section-label">Customer Profiles</div>';
    cust.profiles.forEach(prof => {{
      html += '<div class="profile-card">';
      html += '<h5>' + esc(prof.role || '') + '</h5>';
      html += '<div class="profile-meta">' + esc(prof.seniority || '') + (prof.decision_role ? ' &bull; ' + esc(prof.decision_role) : '') + '</div>';
      if (prof.pain_points && prof.pain_points.length) {{
        html += '<div style="font-size:12px;color:var(--text2);margin-bottom:2px">Pain Points</div><ul class="profile-list">';
        prof.pain_points.forEach(pp => {{ html += '<li>' + esc(pp) + '</li>'; }});
        html += '</ul>';
      }}
      if (prof.buying_criteria && prof.buying_criteria.length) {{
        html += '<div style="font-size:12px;color:var(--text2);margin-top:6px;margin-bottom:2px">Buying Criteria</div><ul class="profile-list">';
        prof.buying_criteria.forEach(bc => {{ html += '<li>' + esc(bc) + '</li>'; }});
        html += '</ul>';
      }}
      html += '</div>';
    }});
  }}

  if (cust && cust.named_customers && cust.named_customers.length) {{
    html += '<div class="section-label">Target Companies (' + cust.named_customers.length + ')</div>';
    cust.named_customers.forEach(function(nc, idx) {{
      var fitCls = nc.fit_score === 'high' ? 'fit-high' : (nc.fit_score === 'medium' ? 'fit-medium' : 'fit-low');
      html += '<div class="customer-target-card" onclick="event.stopPropagation();openNamedCustomer(\\''+slug+'\\', '+idx+')">';
      html += '<div style="display:flex;justify-content:space-between;align-items:center"><h5>' + esc(nc.name) + '</h5>';
      if (nc.fit_score) html += '<span class="fit-badge ' + fitCls + '">' + esc(nc.fit_score) + '</span>';
      html += '</div>';
      var meta = [nc.industry, nc.headquarters].filter(Boolean).map(esc).join(' &bull; ');
      if (meta) html += '<div class="ct-meta">' + meta + '</div>';
      html += '</div>';
    }});
  }}

  const props = Object.entries(E.propositions).filter(([k,v]) => v.market_slug === slug);
  if (props.length) {{
    html += '<div class="section-label">Propositions (' + props.length + ')</div>';
    props.forEach(([k,v]) => {{
      const feat = E.features[v.feature_slug] || {{}};
      html += '<div style="background:var(--surface);border-radius:8px;padding:12px 16px;margin-bottom:8px;cursor:pointer" onclick="openProposition(\\''+k+'\\')"><h5>' + esc(feat.name || v.feature_slug) + '</h5>';
      html += '<div style="font-size:12px;color:var(--text2)">' + esc(v.does_statement || '').substring(0,120) + '...</div></div>';
    }});
  }}

  document.getElementById('panel').innerHTML = html;
  var ov = document.getElementById('overlay');
  ov.style.display = 'flex';
  requestAnimationFrame(function() {{ ov.classList.add('open'); }});
}}

function openNamedCustomer(marketSlug, idx) {{
  var cust = E.customers[marketSlug];
  if (!cust || !cust.named_customers || !cust.named_customers[idx]) return;
  var nc = cust.named_customers[idx];
  var mkt = E.markets[marketSlug] || {{}};

  var html = '<button class="panel-close" onclick="closePanel()">&times;</button>';
  html += '<h3>' + esc(nc.name) + '</h3>';
  var fitCls = nc.fit_score === 'high' ? 'fit-high' : (nc.fit_score === 'medium' ? 'fit-medium' : 'fit-low');
  html += '<div class="panel-sub">' + esc(mkt.name || marketSlug) + (nc.fit_score ? ' &bull; <span class="fit-badge ' + fitCls + '">' + esc(nc.fit_score) + '</span>' : '') + '</div>';

  // Company details
  html += '<div class="section-label">Company Details</div>';
  html += '<table><tbody>';
  if (nc.industry) html += '<tr><td style="color:var(--text2)">Industry</td><td>' + esc(nc.industry) + '</td></tr>';
  if (nc.headquarters) html += '<tr><td style="color:var(--text2)">Headquarters</td><td>' + esc(nc.headquarters) + '</td></tr>';
  if (nc.domain) html += '<tr><td style="color:var(--text2)">Domain</td><td>' + esc(nc.domain) + '</td></tr>';
  if (nc.employees) html += '<tr><td style="color:var(--text2)">Employees</td><td>' + nc.employees.toLocaleString() + '</td></tr>';
  if (nc.revenue && nc.revenue.value) html += '<tr><td style="color:var(--text2)">Revenue</td><td class="price">' + fmtCurrency(nc.revenue.value, nc.revenue.currency) + (nc.revenue.year ? ' (' + nc.revenue.year + ')' : '') + '</td></tr>';
  html += '</tbody></table>';

  // Fit rationale
  if (nc.fit_rationale) {{
    html += '<div class="section-label">Fit Rationale</div>';
    html += '<div class="stmt">' + esc(nc.fit_rationale) + '</div>';
  }}

  // Pain points
  if (nc.pain_points && nc.pain_points.length) {{
    html += '<div class="section-label">Pain Points</div><ul class="profile-list">';
    nc.pain_points.forEach(function(pp) {{ html += '<li>' + esc(pp) + '</li>'; }});
    html += '</ul>';
  }}

  // Tech stack
  if (nc.current_stack && nc.current_stack.length) {{
    html += '<div class="section-label">Current Stack</div><div style="display:flex;flex-wrap:wrap;gap:4px">';
    nc.current_stack.forEach(function(t) {{ html += '<span class="stack-pill">' + esc(t) + '</span>'; }});
    html += '</div>';
  }}

  // Sources
  if (nc.source_urls && nc.source_urls.length) {{
    html += '<div class="section-label">Sources</div>';
    nc.source_urls.forEach(function(url) {{
      html += '<div style="font-size:12px;margin-bottom:4px"><a href="' + esc(url) + '" target="_blank" rel="noopener" style="color:var(--info);text-decoration:none">' + esc(url) + '</a></div>';
    }});
  }}

  if (nc.researched_at) {{
    html += '<div style="font-size:11px;color:var(--text2);margin-top:12px">Researched: ' + esc(nc.researched_at) + '</div>';
  }}

  // Buyer personas context
  if (cust.profiles && cust.profiles.length) {{
    html += '<div class="section-label" style="margin-top:20px">Buyer Personas (this market)</div>';
    cust.profiles.forEach(function(prof) {{
      html += '<div class="profile-card">';
      html += '<h5>' + esc(prof.role || '') + '</h5>';
      html += '<div class="profile-meta">' + esc(prof.seniority || '') + (prof.decision_role ? ' &bull; ' + esc(prof.decision_role) : '') + '</div>';
      html += '</div>';
    }});
  }}

  document.getElementById('panel').innerHTML = html;
  var ov = document.getElementById('overlay');
  ov.style.display = 'flex';
  requestAnimationFrame(function() {{ ov.classList.add('open'); }});
}}

function openPackage(slug) {{
  var pkg = E.packages[slug];
  if (!pkg) return;
  var prod = E.products[pkg.product_slug] || {{}};
  var mkt = E.markets[pkg.market_slug] || {{}};

  var html = '<button class="panel-close" onclick="closePanel()">&times;</button>';
  html += '<h3>' + esc(pkg.name || slug) + '</h3>';
  html += '<div class="panel-sub">' + esc(prod.name || pkg.product_slug) + ' &rarr; ' + esc(mkt.name || pkg.market_slug) + ' &bull; <span class="revenue-chip">' + esc(pkg.package_type || '') + '</span></div>';

  if (pkg.positioning) html += '<div class="stmt">' + esc(pkg.positioning) + '</div>';

  html += '<div class="section-label">Tiers</div>';
  (pkg.tiers || []).forEach(function(tier) {{
    html += '<div style="background:var(--surface);border-radius:10px;padding:16px 18px;margin-bottom:10px;border:1px solid var(--border)">';
    html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">';
    html += '<span style="font-weight:600;font-size:15px">' + esc(tier.name || tier.tier || '') + '</span>';
    var price;
    if (tier.price_monthly != null) {{
      price = tier.price_monthly === 0 ? 'Free' : fmtCurrency(tier.price_monthly, tier.currency) + '/mo';
    }} else if (tier.price != null) {{
      price = fmtCurrency(tier.price, tier.currency);
    }} else {{ price = 'Custom'; }}
    html += '<span class="price" style="font-size:16px">' + price + '</span>';
    html += '</div>';
    if (tier.scope) html += '<div style="font-size:13px;color:var(--text2);margin-bottom:8px">' + esc(tier.scope) + '</div>';
    if (tier.included_solutions && tier.included_solutions.length) {{
      html += '<div style="display:flex;flex-wrap:wrap;gap:4px">';
      tier.included_solutions.forEach(function(ss) {{
        var hasSol = !!E.solutions[ss];
        html += '<span class="included-solution" style="cursor:pointer' + (hasSol ? '' : ';opacity:0.5') + '" onclick="event.stopPropagation();openProposition(\\''+ss+'\\')\">' + esc(ss) + '</span>';
      }});
      html += '</div>';
    }}
    html += '</div>';
  }});

  if (pkg.bundle_savings_pct) {{
    html += '<div style="margin-top:12px;font-size:14px;color:var(--green);font-weight:600">Bundle savings: ' + pkg.bundle_savings_pct + '%</div>';
  }}

  document.getElementById('panel').innerHTML = html;
  var ov = document.getElementById('overlay');
  ov.style.display = 'flex';
  requestAnimationFrame(function() {{ ov.classList.add('open'); }});
}}

function esc(s) {{
  if (s == null) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}}

function fmtCurrency(val, cur) {{
  cur = cur || 'EUR';
  if (val == null) return 'N/A';
  if (val >= 1e9) return cur + ' ' + (val/1e9).toFixed(1) + 'B';
  if (val >= 1e6) return cur + ' ' + (val/1e6).toFixed(1) + 'M';
  if (val >= 1e3) return cur + ' ' + (val/1e3).toFixed(0) + 'K';
  return cur + ' ' + val.toLocaleString();
}}

/* Scroll-triggered reveal animations */
(function() {{
  const observer = new IntersectionObserver(function(entries) {{
    entries.forEach(function(entry) {{
      if (entry.isIntersecting) {{
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }}
    }});
  }}, {{ threshold: 0.08, rootMargin: '0px 0px -40px 0px' }});

  document.querySelectorAll('.reveal').forEach(function(el) {{
    observer.observe(el);
  }});

  /* Nav: smooth scroll to sections and active state tracking */
  var nav = document.getElementById('topnav');
  var navLinks = nav ? nav.querySelectorAll('a[data-section]') : [];
  navLinks.forEach(function(a) {{
    a.addEventListener('click', function(e) {{
      e.preventDefault();
      var title = a.dataset.section;
      var el = Array.from(document.querySelectorAll('.section-title')).find(function(t) {{ return t.textContent.indexOf(title) >= 0; }});
      if (el) {{
        var section = el.closest('.section') || el.parentElement;
        var y = section.getBoundingClientRect().top + window.pageYOffset - 60;
        window.scrollTo({{ top: y, behavior: 'smooth' }});
      }}
    }});
  }});
  if (nav) {{
    var secTitles = document.querySelectorAll('.section-title');
    var navObs = new IntersectionObserver(function(entries) {{
      entries.forEach(function(entry) {{
        if (entry.isIntersecting) {{
          var text = entry.target.textContent;
          navLinks.forEach(function(a) {{
            a.classList.toggle('active', text.indexOf(a.dataset.section) >= 0);
          }});
        }}
      }});
    }}, {{ threshold: 0.5, rootMargin: '-80px 0px -60% 0px' }});
    secTitles.forEach(function(t) {{ navObs.observe(t); }});
    window.addEventListener('scroll', function() {{
      nav.classList.toggle('scrolled', window.scrollY > 20);
    }}, {{ passive: true }});
  }}

  /* Animate overlay transitions */
  const overlay = document.getElementById('overlay');
  if (overlay) {{
    overlay.addEventListener('transitionend', function() {{
      if (!overlay.classList.contains('open')) {{
        overlay.style.display = 'none';
      }}
    }});
  }}
}})();
</script>

</div>
</body>
</html>"""
    return html


def main():
    # Parse args
    args = sys.argv[1:]
    project_dir = None
    theme_path = None
    design_variables_path = None

    i = 0
    while i < len(args):
        if args[i] == "--theme" and i + 1 < len(args):
            theme_path = args[i + 1]
            i += 2
        elif args[i] == "--design-variables" and i + 1 < len(args):
            design_variables_path = args[i + 1]
            i += 2
        elif not project_dir:
            project_dir = args[i]
            i += 1
        else:
            i += 1

    if not project_dir:
        print(json.dumps({"error": "Usage: generate-dashboard.py <project-dir> [--design-variables <path.json>] [--theme <theme.md>]"}))
        sys.exit(1)

    project_dir = os.path.abspath(project_dir)
    if not os.path.isfile(os.path.join(project_dir, "portfolio.json")):
        print(json.dumps({"error": f"Not a cogni-portfolio project (missing portfolio.json): {project_dir}"}))
        sys.exit(1)

    # Load theme — precedence: --design-variables > --theme > DEFAULT_THEME
    if design_variables_path:
        try:
            theme = load_design_variables(design_variables_path)
        except (ValueError, json.JSONDecodeError, FileNotFoundError) as e:
            print(json.dumps({"error": f"Failed to load design-variables: {e}"}))
            sys.exit(1)
    elif theme_path:
        theme = parse_theme(theme_path)
    else:
        theme = DEFAULT_THEME.copy()

    data = load_all_entities(project_dir)
    status = get_status(project_dir)
    html = generate_html(data, status, project_dir, theme)

    output_dir = os.path.join(project_dir, "output")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "dashboard.html")

    with open(output_path, "w") as f:
        f.write(html)

    result = {"status": "ok", "path": output_path, "theme": theme["name"]}
    if design_variables_path:
        result["design_variables"] = os.path.abspath(design_variables_path)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
