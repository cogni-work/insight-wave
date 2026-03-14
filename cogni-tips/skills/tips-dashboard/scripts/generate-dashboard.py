#!/usr/bin/env python3
"""Generate a self-contained HTML dashboard for a cogni-tips TIPS project.

Usage: python3 generate-dashboard.py <project-dir> [--design-variables <path.json>] [--theme <path-to-theme.md>]
Output: <project-dir>/output/tips-dashboard.html
Returns JSON: {"status": "ok", "path": "<output-path>", "theme": "<name>"} or {"error": "..."}
"""

import json
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
        "surface2": "#E8E8E4",
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

# Dimension slugs used when candidates lack explicit dimension field
# Candidates are always produced in groups of 15 per dimension in this order.
DIMENSION_SLUGS = ["externe-effekte", "neue-horizonte", "digitale-wertetreiber", "digitales-fundament"]

# TIPS dimension colors
TIPS_COLORS = {
    "trend": "#F59E0B",      # amber
    "implication": "#06B6D4", # cyan
    "possibility": "#8B5CF6", # purple
    "solution": "#22C55E",    # green
}

# Dimension colors (Smarter Service Trendradar 4 dimensions)
DIMENSION_COLORS = [
    "#00B8D4",  # Externe Effekte / External Effects — cyan
    "#8B5CF6",  # Neue Horizonte / New Horizons — purple
    "#F59E0B",  # Digitale Wertetreiber / Digital Value Drivers — amber
    "#3B82F6",  # Digitales Fundament / Digital Foundation — blue
]

# i18n labels
UI_LABELS = {
    "en": {
        "title_suffix": "TIPS Dashboard",
        "tab_overview": "Overview",
        "tab_scout": "Trend Scout",
        "tab_model": "Value Model",
        "tab_report": "Report",
        "tab_catalog": "Catalog",
        "phase_progress": "Project Phase",
        "scoring_summary": "Scoring Summary",
        "dim_heatmap": "Dimension × Horizon",
        "source_integrity": "Source Integrity",
        "candidates": "Candidates",
        "avg_score": "Avg Score",
        "leading_pct": "Leading %",
        "confidence": "Confidence",
        "high": "High",
        "medium": "Medium",
        "low": "Low",
        "web_sourced": "Web-sourced",
        "training_based": "Training-based",
        "corroboration": "Corroboration Rate",
        "themes": "Strategic Themes",
        "value_chains": "Value Chains",
        "solution_ranking": "Solution Ranking",
        "spis_metrics": "SPIs & Metrics",
        "report_status": "Report Status",
        "claims_registry": "Claims Registry",
        "insight_summary": "Insight Summary",
        "catalog_header": "Industry Catalog",
        "taxonomy_coverage": "Taxonomy Coverage",
        "entity_counts": "Entity Counts",
        "not_available": "Not yet available",
        "run_skill": "Run",
        "to_generate": "to generate this data",
        "top_trends": "Top Trends",
        "click_node": "Click a node in the graph or an entity card to see details",
        "anchor_coverage": "Portfolio Anchor Coverage",
        "anchored_sts": "Anchored STs",
        "abstract_sts": "Abstract STs",
        "delivered_needs": "Delivered Needs",
        "unmet_needs": "Unmet Needs",
        "quality_flag": "Quality Investment Needed",
        "portfolio_anchored": "Portfolio-Anchored",
        "dimensions": ["External Effects", "New Horizons", "Digital Value Drivers", "Digital Foundation"],
        "horizons": ["ACT", "PLAN", "OBSERVE"],
        "stages": ["Web Research", "Candidate Gen", "Selection", "Report", "Claims", "Insight", "Verification", "Polish"],
    },
    "de": {
        "title_suffix": "TIPS Dashboard",
        "tab_overview": "Übersicht",
        "tab_scout": "Trend Scout",
        "tab_model": "Value Model",
        "tab_report": "Report",
        "tab_catalog": "Katalog",
        "phase_progress": "Projektphase",
        "scoring_summary": "Bewertungsübersicht",
        "dim_heatmap": "Dimension × Horizont",
        "source_integrity": "Quellenintegrität",
        "candidates": "Kandidaten",
        "avg_score": "Ø Bewertung",
        "leading_pct": "Frühindikatoren %",
        "confidence": "Konfidenz",
        "high": "Hoch",
        "medium": "Mittel",
        "low": "Niedrig",
        "web_sourced": "Web-basiert",
        "training_based": "Trainingsbasiert",
        "corroboration": "Bestätigungsrate",
        "themes": "Strategische Themen",
        "value_chains": "Wertschöpfungsketten",
        "solution_ranking": "Lösungs-Ranking",
        "spis_metrics": "SPIs & Metriken",
        "report_status": "Report-Status",
        "claims_registry": "Claims-Register",
        "insight_summary": "Insight-Zusammenfassung",
        "catalog_header": "Branchenkatalog",
        "taxonomy_coverage": "Taxonomie-Abdeckung",
        "entity_counts": "Entity-Zählung",
        "not_available": "Noch nicht verfügbar",
        "run_skill": "Führe",
        "to_generate": "aus, um diese Daten zu generieren",
        "top_trends": "Top Trends",
        "click_node": "Klicke auf einen Knoten im Graph oder eine Entity-Karte für Details",
        "anchor_coverage": "Portfolio-Anker-Abdeckung",
        "anchored_sts": "Verankerte STs",
        "abstract_sts": "Abstrakte STs",
        "delivered_needs": "Gelieferte Bedarfe",
        "unmet_needs": "Ungedeckte Bedarfe",
        "quality_flag": "Qualitätsinvestition nötig",
        "portfolio_anchored": "Portfolio-verankert",
        "dimensions": ["Externe Effekte", "Neue Horizonte", "Digitale Wertetreiber", "Digitales Fundament"],
        "horizons": ["ACT", "PLAN", "OBSERVE"],
        "stages": ["Web-Recherche", "Kandidaten-Gen.", "Selektion", "Report", "Claims", "Insight", "Verifikation", "Polish"],
    },
}


def parse_theme(theme_path):
    """Parse a cogni-workspace theme.md file into a design tokens dict."""
    if not theme_path or not os.path.isfile(theme_path):
        return DEFAULT_THEME.copy()

    with open(theme_path) as f:
        content = f.read()

    theme = {"name": "", "colors": {}, "status": {}, "fonts": {}}

    m = re.search(r'^#\s+(.+)', content, re.MULTILINE)
    if m:
        theme["name"] = m.group(1).strip()

    color_map = {
        "primary": "primary", "secondary": "secondary", "accent": "accent",
        "accent muted": "accent_muted", "accent dark": "accent_dark",
        "background": "background", "surface": "surface", "surface dark": "surface_dark",
        "text": "text", "text light": "text_light", "text muted": "text_muted", "border": "border",
    }
    status_map = {"success": "success", "warning": "warning", "danger": "danger", "info": "info"}

    for m in re.finditer(r'-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`', content):
        name = m.group(1).strip().lower()
        hex_val = m.group(2).strip()
        for key, var_name in color_map.items():
            if name == key:
                theme["colors"][var_name] = hex_val
                break
            elif " " in key and name.startswith(key):
                theme["colors"][var_name] = hex_val
                break
        else:
            for key, var_name in status_map.items():
                if name == key or name.startswith(key):
                    theme["status"][var_name] = hex_val
                    break

    for m in re.finditer(r'-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`', content):
        name = m.group(1).strip().lower()
        hex_val = m.group(2).strip()
        if name == "text light":
            theme["colors"]["text_light"] = hex_val
        elif name == "text muted":
            theme["colors"]["text_muted"] = hex_val

    font_patterns = {
        "headers": r'-\s+\*\*Headers?\*\*:\s*(.+)',
        "body": r'-\s+\*\*Body\*\*:\s*(.+)',
        "mono": r'-\s+\*\*Mono\*\*:\s*(.+)',
    }
    for key, pattern in font_patterns.items():
        fm = re.search(pattern, content, re.IGNORECASE)
        if fm:
            raw = fm.group(1).strip()
            fonts = re.split(r'\s*/\s*fallback:\s*', raw, maxsplit=1)
            primary_font = fonts[0].strip().rstrip(" Bold").rstrip(" Regular")
            fallbacks = fonts[1].strip() if len(fonts) > 1 else ""
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

    for section in ["colors", "status", "fonts"]:
        for k, v in DEFAULT_THEME[section].items():
            if k not in theme[section]:
                theme[section][k] = v

    if not theme["name"]:
        theme["name"] = DEFAULT_THEME["name"]

    return theme


def derive_surface2(surface_hex):
    """Derive a slightly darker surface variant."""
    try:
        r, g, b = int(surface_hex[1:3], 16), int(surface_hex[3:5], 16), int(surface_hex[5:7], 16)
        factor = 0.96
        return f"#{int(r*factor):02x}{int(g*factor):02x}{int(b*factor):02x}"
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
# Design variables loader
# ---------------------------------------------------------------------------

DESIGN_VARS_REQUIRED_COLORS = [
    "primary", "secondary", "accent", "accent_muted", "accent_dark",
    "background", "surface", "surface2", "surface_dark",
    "border", "text", "text_light", "text_muted",
]
DESIGN_VARS_REQUIRED_STATUS = ["success", "warning", "danger", "info"]
DESIGN_VARS_REQUIRED_FONTS = ["headers", "body", "mono"]
DEFAULT_SHADOWS = DEFAULT_THEME["shadows"]


def load_design_variables(path):
    """Load a design-variables JSON file and return a theme dict."""
    with open(path) as f:
        dv = json.load(f)

    for key in ["theme_name", "colors", "status", "fonts"]:
        if key not in dv:
            raise ValueError(f"design-variables JSON missing required key: {key}")
    for k in DESIGN_VARS_REQUIRED_COLORS:
        if k not in dv["colors"]:
            raise ValueError(f"design-variables colors missing required key: {k}")
    for k in DESIGN_VARS_REQUIRED_STATUS:
        if k not in dv["status"]:
            raise ValueError(f"design-variables status missing required key: {k}")
    for k in DESIGN_VARS_REQUIRED_FONTS:
        if k not in dv["fonts"]:
            raise ValueError(f"design-variables fonts missing required key: {k}")

    return {
        "name": dv["theme_name"],
        "colors": dict(dv["colors"]),
        "status": dict(dv["status"]),
        "fonts": dict(dv["fonts"]),
        "google_fonts_import": dv.get("google_fonts_import", ""),
        "radius": dv.get("radius", "12px"),
        "shadows": {**DEFAULT_SHADOWS, **dv.get("shadows", {})},
    }


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def load_tips_data(project_dir):
    """Load all TIPS project data files."""
    data = {
        "project": load_json(os.path.join(project_dir, "tips-project.json")) or {},
        "scout": None,
        "value_model": None,
        "claims": None,
        "modeler_state": None,
        "has_report": os.path.isfile(os.path.join(project_dir, "tips-trend-report.md")),
        "has_insight": os.path.isfile(os.path.join(project_dir, "tips-insight-summary.md")),
        "catalog": None,
    }

    # Scout output
    scout_path = os.path.join(project_dir, ".metadata", "trend-scout-output.json")
    data["scout"] = load_json(scout_path)

    # Value model
    vm_path = os.path.join(project_dir, "tips-value-model.json")
    data["value_model"] = load_json(vm_path)

    # Claims
    claims_path = os.path.join(project_dir, "tips-trend-report-claims.json")
    data["claims"] = load_json(claims_path)

    # Modeler state
    ms_path = os.path.join(project_dir, ".metadata", "value-modeler-output.json")
    data["modeler_state"] = load_json(ms_path)

    # Catalog — search up from project dir for catalogs/
    plugin_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    project_meta = data["project"]
    industry = project_meta.get("industry", {})
    ind_slug = industry.get("slug", "") if isinstance(industry, dict) else str(industry)
    sub_slug = industry.get("subsector_slug", "general") if isinstance(industry, dict) else "general"
    catalog_path = os.path.join(plugin_root, "catalogs", ind_slug, sub_slug, "catalog.json")
    if os.path.isfile(catalog_path):
        data["catalog"] = load_json(catalog_path)
        data["catalog_dir"] = os.path.dirname(catalog_path)

    return data


def get_status(project_dir):
    """Run project-status.sh and return parsed JSON."""
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

def esc(text):
    if not isinstance(text, str):
        text = str(text) if text is not None else ""
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def esc_js(text):
    if not isinstance(text, str):
        text = str(text) if text is not None else ""
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "").replace("'", "\\'")


# ---------------------------------------------------------------------------
# Graph data builder
# ---------------------------------------------------------------------------

def build_graph_data(data):
    """Build nodes and links for D3 force-directed graph from TIPS data.

    Key design: candidates and value-chain trends are MERGED when they share
    a name.  The candidate node (candidate-N) becomes the canonical trend node
    and all VC edges (T→I) point to it.  This ensures clicking a candidate in
    the Scout tab reveals its full TIPS connection chain in the graph.
    """
    nodes = []
    links = []
    node_ids = set()

    scout = data.get("scout")
    vm = data.get("value_model")

    # --- 1. Load candidates -------------------------------------------------
    candidates = []
    if scout:
        tips_cands = scout.get("tips_candidates", {})
        if isinstance(tips_cands, dict) and tips_cands.get("items"):
            candidates = tips_cands["items"]
        else:
            candidates = scout.get("candidates", [])
        if not isinstance(candidates, list):
            candidates = []

    # Build name → candidate-id mapping for merging with VC trends
    cand_name_to_id = {}  # trend_name (lower) → candidate node id
    for i, c in enumerate(candidates):
        nid = f"candidate-{i}"
        node_ids.add(nid)
        # Fix 1: derive dimension from position when missing
        dim = c.get("dimension", "")
        if not dim:
            dim = DIMENSION_SLUGS[min(i // 15, 3)]
            c["dimension"] = dim
        dim_idx = _dimension_index(dim)
        # Fix 2: extract indicator_type from nested indicator_classification
        indicator = c.get("indicator_type", "")
        if not indicator:
            ic = c.get("indicator_classification", {})
            if isinstance(ic, dict):
                indicator = ic.get("type", "")
        # Fix 3: extract diffusion_stage string from dict
        diffusion = c.get("diffusion_stage", "")
        if isinstance(diffusion, dict):
            diffusion = diffusion.get("stage", "")
        nodes.append({
            "id": nid,
            "name": c.get("trend_name", c.get("name", f"Candidate {i+1}")),
            "type": "trend",
            "dimension": dim,
            "dimension_idx": dim_idx,
            "score": c.get("score", 0),
            "horizon": c.get("horizon", ""),
            "confidence": c.get("confidence_tier", ""),
            "statement": c.get("trend_statement", c.get("statement", "")),
            "source": c.get("source", ""),
            "indicator_type": indicator,
            "diffusion_stage": diffusion,
        })
        name_key = (c.get("trend_name") or c.get("name") or "").strip().lower()
        if name_key:
            cand_name_to_id[name_key] = nid

    # --- 2. Add value model entities ----------------------------------------
    if vm:
        _st_lookup = {st.get("st_id", st.get("id", "")): st for st in vm.get("solution_templates", []) if isinstance(st, dict)}
        _vc_lookup = {vc.get("chain_id", vc.get("id", "")): vc for vc in vm.get("value_chains", []) if isinstance(vc, dict)}

        # Track which chain-t id maps to which actual node id (for merging)
        chain_trend_to_node = {}  # chain-t-{chain_id} → actual node id

        themes = vm.get("themes", vm.get("strategic_themes", []))
        if isinstance(themes, list):
            for theme in themes:
                theme_id = theme.get("theme_id", theme.get("id", ""))

                raw_chains = theme.get("value_chains", [])
                chains = []
                for vc_ref in raw_chains:
                    if isinstance(vc_ref, str):
                        vc = _vc_lookup.get(vc_ref)
                        if vc:
                            chains.append(vc)
                    elif isinstance(vc_ref, dict):
                        chains.append(vc_ref)

                for chain in chains:
                    chain_id = chain.get("chain_id", chain.get("id", ""))

                    # Trend node — merge with candidate if name matches
                    t = chain.get("trend", {})
                    if t:
                        t_name = (t.get("name") or t.get("trend_name") or "").strip()
                        t_name_key = t_name.lower()
                        canonical_t_id = f"chain-t-{chain_id}"

                        if t_name_key in cand_name_to_id:
                            # Merge: reuse the candidate node, add theme info
                            merged_id = cand_name_to_id[t_name_key]
                            chain_trend_to_node[canonical_t_id] = merged_id
                            # Enrich candidate node with theme info
                            for n in nodes:
                                if n["id"] == merged_id:
                                    n["theme"] = theme.get("name", "")
                                    n["theme_id"] = theme_id
                                    break
                        else:
                            # No matching candidate — create a new trend node
                            if canonical_t_id not in node_ids:
                                node_ids.add(canonical_t_id)
                                nodes.append({
                                    "id": canonical_t_id,
                                    "name": t_name,
                                    "type": "trend",
                                    "theme": theme.get("name", ""),
                                    "theme_id": theme_id,
                                    "statement": t.get("statement", t.get("description", "")),
                                })
                            chain_trend_to_node[canonical_t_id] = canonical_t_id

                    # Resolve the trend node id for this chain (merged or new)
                    actual_t_id = chain_trend_to_node.get(f"chain-t-{chain_id}")

                    # Implication nodes
                    for imp in chain.get("implications", []):
                        i_id = f"chain-i-{chain_id}-{imp.get('name', '')[:20]}"
                        if i_id not in node_ids:
                            node_ids.add(i_id)
                            nodes.append({
                                "id": i_id,
                                "name": imp.get("name", ""),
                                "type": "implication",
                                "theme": theme.get("name", ""),
                                "theme_id": theme_id,
                                "statement": imp.get("statement", imp.get("description", "")),
                            })
                        if actual_t_id:
                            links.append({"source": actual_t_id, "target": i_id})

                    # Possibility nodes
                    for pos in chain.get("possibilities", []):
                        p_id = f"chain-p-{chain_id}-{pos.get('name', '')[:20]}"
                        if p_id not in node_ids:
                            node_ids.add(p_id)
                            nodes.append({
                                "id": p_id,
                                "name": pos.get("name", ""),
                                "type": "possibility",
                                "theme": theme.get("name", ""),
                                "theme_id": theme_id,
                                "statement": pos.get("statement", pos.get("description", "")),
                            })
                        # Link from implications to possibilities
                        for imp in chain.get("implications", []):
                            i_id = f"chain-i-{chain_id}-{imp.get('name', '')[:20]}"
                            links.append({"source": i_id, "target": p_id})

                # Solution templates — resolve string references
                for st_ref in theme.get("solution_templates", []):
                    if isinstance(st_ref, str):
                        st = _st_lookup.get(st_ref)
                    elif isinstance(st_ref, dict):
                        st = st_ref
                    else:
                        continue
                    if not st or not isinstance(st, dict):
                        continue
                    s_id = f"st-{st.get('st_id', st.get('id', ''))}"
                    if s_id not in node_ids:
                        node_ids.add(s_id)
                        nodes.append({
                            "id": s_id,
                            "name": st.get("name", ""),
                            "type": "solution",
                            "theme": theme.get("name", ""),
                            "theme_id": theme_id,
                            "category": st.get("category", ""),
                            "enabler_type": st.get("enabler_type", ""),
                            "br_score": st.get("business_relevance", 0),
                            "ranking_value": st.get("ranking_value", 0),
                            "statement": st.get("description", ""),
                            "generation_mode": st.get("generation_mode", "abstract"),
                            "portfolio_anchor": st.get("portfolio_anchor"),
                            "quality_flag": st.get("quality_flag", ""),
                        })
                    # Link from possibilities to solution
                    for chain in chains:
                        chain_id_c = chain.get("chain_id", chain.get("id", ""))
                        for pos in chain.get("possibilities", []):
                            p_id = f"chain-p-{chain_id_c}-{pos.get('name', '')[:20]}"
                            if p_id in node_ids:
                                links.append({"source": p_id, "target": s_id})

    return {"nodes": nodes, "links": links}


def _dimension_index(dim_name):
    """Map dimension name or slug to index (0-3)."""
    dim_lower = dim_name.lower().replace("-", " ").replace("_", " ") if dim_name else ""
    mapping = {
        "externe effekte": 0, "external effects": 0, "externe": 0,
        "neue horizonte": 1, "new horizons": 1, "neue": 1,
        "digitale wertetreiber": 2, "digital value drivers": 2, "wertetreiber": 2,
        "digitales fundament": 3, "digital foundation": 3, "fundament": 3,
    }
    for key, idx in mapping.items():
        if key in dim_lower:
            return idx
    return 0


def _dimension_display_name(dim_slug, lang="de"):
    """Convert dimension slug to display name."""
    idx = _dimension_index(dim_slug)
    labels = UI_LABELS.get(lang, UI_LABELS["en"])
    return labels["dimensions"][idx]


# ---------------------------------------------------------------------------
# HTML generation
# ---------------------------------------------------------------------------

def generate_html(data, status, project_dir, theme):
    """Generate the full HTML dashboard string."""
    project = data["project"]
    scout = data["scout"]
    vm = data["value_model"]
    claims = data["claims"]

    # Project metadata — resolve display name with fallbacks
    # Priority: research_topic > scout config topic > scout project_name > project name > slug
    raw_name = project.get("research_topic", "")
    if not raw_name and scout:
        scout_config = scout.get("config", {})
        raw_name = scout_config.get("research_topic", "") or scout.get("project_name", "")
    if not raw_name:
        raw_name = project.get("name", project.get("slug", "TIPS Project"))
    project_name = esc(raw_name)

    industry_obj = project.get("industry", {})
    if isinstance(industry_obj, dict):
        industry = esc(industry_obj.get("name", industry_obj.get("slug", "")))
        subsector = esc(industry_obj.get("subsector", industry_obj.get("subsector_slug", "")))
    else:
        industry = esc(str(industry_obj))
        subsector = ""
    lang = project.get("language", scout.get("project_language", "en") if scout else "en")
    if lang not in UI_LABELS:
        lang = "en"
    L = UI_LABELS[lang]

    research_topic = esc(raw_name)
    project_slug = esc(project.get("slug", ""))
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    # Status data
    status_data = status or {}
    phase = status_data.get("phase", "unknown")
    counts = status_data.get("counts", {})
    scoring = status_data.get("scoring", {})
    next_actions = status_data.get("next_actions", [])

    # Phase progress calculation
    phase_list = ["scouting", "researching", "generating", "selecting", "reporting",
                  "verification", "modeling", "complete"]
    phase_idx = 0
    for i, p in enumerate(phase_list):
        if phase.startswith(p):
            phase_idx = i
            break

    # Scout data — handle both legacy (candidates at root) and current (tips_candidates.items)
    candidates = []
    scout_config = {}
    scout_scoring = {}
    scout_source_integrity = {}
    if scout:
        scout_config = scout.get("config", {})

        # Current format: tips_candidates.items
        tips_cands = scout.get("tips_candidates", {})
        if isinstance(tips_cands, dict) and tips_cands.get("items"):
            candidates = tips_cands["items"]
            scout_scoring = tips_cands.get("scoring_metadata", {})
            scout_source_integrity = tips_cands.get("source_distribution", {})
        else:
            # Legacy format: candidates at root
            candidates = scout.get("candidates", [])
            scout_scoring = scout.get("scoring_metadata", scout.get("scoring", {}))
            scout_source_integrity = scout.get("source_integrity", {})

        if not isinstance(candidates, list):
            candidates = []

    # Fix 1: derive dimension from position when missing
    for i, c in enumerate(candidates):
        if not c.get("dimension"):
            c["dimension"] = DIMENSION_SLUGS[min(i // 15, 3)]

    # Build dimension × horizon matrix
    dim_horizon = {}
    for c in candidates:
        dim = c.get("dimension", "Unknown")
        hor = c.get("horizon", "Unknown")
        key = (dim, hor)
        dim_horizon[key] = dim_horizon.get(key, 0) + 1

    # Value model data
    themes_list = []
    all_sts = []
    vm_st_lookup = {}  # st_id -> ST dict
    vm_vc_lookup = {}  # chain_id -> VC dict
    if vm:
        themes_list = vm.get("themes", vm.get("strategic_themes", []))
        if not isinstance(themes_list, list):
            themes_list = []

        # Build lookups from top-level arrays (STs/VCs may be referenced by ID in themes)
        for st in vm.get("solution_templates", []):
            if isinstance(st, dict):
                vm_st_lookup[st.get("st_id", st.get("id", ""))] = st
        for vc in vm.get("value_chains", []):
            if isinstance(vc, dict):
                vm_vc_lookup[vc.get("chain_id", vc.get("id", ""))] = vc

        # Resolve theme references: replace string IDs with actual objects
        for theme_obj in themes_list:
            # Resolve value_chains
            resolved_chains = []
            for vc_ref in theme_obj.get("value_chains", []):
                if isinstance(vc_ref, str):
                    vc = vm_vc_lookup.get(vc_ref)
                    if vc:
                        resolved_chains.append(vc)
                elif isinstance(vc_ref, dict):
                    resolved_chains.append(vc_ref)
            theme_obj["_resolved_chains"] = resolved_chains

            # Resolve solution_templates
            for st_ref in theme_obj.get("solution_templates", []):
                st_id = st_ref if isinstance(st_ref, str) else st_ref.get("st_id", st_ref.get("id", "")) if isinstance(st_ref, dict) else ""
                st_obj = vm_st_lookup.get(st_id) if isinstance(st_ref, str) else st_ref
                if st_obj and isinstance(st_obj, dict):
                    st_copy = dict(st_obj)
                    st_copy["_theme_name"] = theme_obj.get("name", "")
                    all_sts.append(st_copy)

        all_sts.sort(key=lambda x: x.get("ranking_value", x.get("business_relevance", 0)), reverse=True)

    # Portfolio anchor stats
    anchored_sts = [st for st in all_sts if st.get("generation_mode") in ("portfolio-anchored", "re-anchored")]
    anchored_count = len(anchored_sts)
    total_sts_count = len(all_sts)
    anchored_by_theme = {}
    all_delivered_needs = set()
    all_undelivered_needs = set()
    has_quality_issues = False
    for st in anchored_sts:
        theme_name = st.get("_theme_name", "Unknown")
        anchored_by_theme.setdefault(theme_name, []).append(st)
        anchor = st.get("portfolio_anchor", {}) or {}
        for need in anchor.get("theme_needs_delivered", []):
            all_delivered_needs.add(need)
        for need in anchor.get("theme_needs_undelivered", []):
            all_undelivered_needs.add(need)
        if st.get("quality_flag"):
            has_quality_issues = True

    # Claims data
    claims_list = []
    if claims:
        if isinstance(claims, list):
            claims_list = claims
        elif isinstance(claims, dict):
            claims_list = claims.get("claims", [])

    # Graph data
    graph = build_graph_data(data)
    graph_json = json.dumps(graph, default=str)

    # Catalog data
    catalog = data.get("catalog")
    has_catalog = catalog is not None

    # Theme CSS
    c = theme["colors"]
    s = theme["status"]
    fonts = theme["fonts"]
    surface2 = c.get("surface2") or derive_surface2(c["surface"])
    if "google_fonts_import" in theme and theme["google_fonts_import"]:
        fonts_import = theme["google_fonts_import"]
    else:
        fonts_url = google_fonts_url(theme)
        fonts_import = f"@import url('{fonts_url}');" if fonts_url else ""
    radius = theme.get("radius", "12px")
    shadows = theme.get("shadows", DEFAULT_SHADOWS)

    # Dimensions as JSON for JS
    dimensions_json = json.dumps(L["dimensions"])
    horizons_json = json.dumps(L["horizons"])

    # Build candidates JSON for JS
    candidates_json = json.dumps(candidates, default=str)
    themes_json = json.dumps(themes_list, default=str)
    all_sts_json = json.dumps(all_sts, default=str)
    claims_json = json.dumps(claims_list, default=str)

    # --- HTML output ---
    html = f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{project_name} — {L['title_suffix']}</title>
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
  --tips-trend: {TIPS_COLORS['trend']};
  --tips-implication: {TIPS_COLORS['implication']};
  --tips-possibility: {TIPS_COLORS['possibility']};
  --tips-solution: {TIPS_COLORS['solution']};
  --dim-0: {DIMENSION_COLORS[0]};
  --dim-1: {DIMENSION_COLORS[1]};
  --dim-2: {DIMENSION_COLORS[2]};
  --dim-3: {DIMENSION_COLORS[3]};
}}

* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ background: var(--bg); color: var(--text); font-family: var(--font-body); line-height: 1.6; -webkit-font-smoothing: antialiased; display: flex; flex-direction: column; height: 100vh; overflow: hidden; }}
h1, h2, h3, h4, h5 {{ font-family: var(--font-headers); letter-spacing: -0.01em; }}
code, .mono {{ font-family: var(--font-mono); }}

/* Grain overlay */
body::after {{
  content: "";
  position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
  pointer-events: none;
  z-index: 9999;
}}

/* ============ NAVBAR ============ */
.navbar {{
  position: sticky; top: 0; z-index: 200;
  display: flex; align-items: center; gap: 0;
  padding: 0 20px; height: 48px;
  background: var(--surface-dark); border-bottom: 1px solid var(--border);
}}
.navbar-brand {{
  font-size: 14px; font-weight: 700; font-family: var(--font-headers);
  color: var(--text-light); white-space: nowrap; overflow: hidden;
  text-overflow: ellipsis; max-width: 320px; flex-shrink: 0;
  margin-right: 24px;
}}
.navbar-tabs {{
  display: flex; align-items: center; gap: 0; flex: 1;
  overflow-x: auto; scrollbar-width: none;
}}
.navbar-tabs::-webkit-scrollbar {{ display: none; }}
.navbar-tab {{
  padding: 0 16px; border: none; background: transparent;
  color: rgba(255,255,255,0.5); font-family: var(--font-body);
  font-size: 12px; font-weight: 600; text-transform: uppercase;
  letter-spacing: 0.08em; cursor: pointer; white-space: nowrap;
  border-bottom: 2px solid transparent; transition: color 0.2s, border-color 0.2s;
  height: 48px; display: flex; align-items: center;
}}
.navbar-tab:hover {{ color: rgba(255,255,255,0.8); }}
.navbar-tab.active {{
  color: var(--accent); border-bottom-color: var(--accent);
}}
.navbar-tab.disabled {{
  opacity: 0.3; cursor: not-allowed;
}}

/* ============ LAYOUT: three-panel ============ */
.layout {{
  display: flex; flex: 1; overflow: hidden;
}}

/* Left panel — section index */
.left-panel {{
  width: 200px; min-width: 200px; flex-shrink: 0;
  background: var(--surface); border-right: 1px solid var(--border);
  overflow-y: auto; padding: 16px 0;
}}
.left-panel .section-group {{
  padding: 0 12px; margin-bottom: 16px;
}}
.left-panel .section-label {{
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.1em;
  color: var(--text2); font-weight: 600; padding: 4px 8px; margin-bottom: 4px;
}}
.left-panel .section-item {{
  display: block; padding: 6px 8px; border-radius: 6px;
  font-size: 13px; color: var(--text); cursor: pointer;
  transition: background 0.15s, color 0.15s;
  border: none; background: none; width: 100%; text-align: left;
  font-family: var(--font-body); line-height: 1.4;
}}
.left-panel .section-item:hover {{
  background: var(--surface2);
}}
.left-panel .section-item.active {{
  background: color-mix(in srgb, var(--accent) 15%, transparent);
  color: var(--accent-dark); font-weight: 600;
}}
.left-panel .dim-dot {{
  display: inline-block; width: 8px; height: 8px; border-radius: 50%;
  margin-right: 6px; vertical-align: middle;
}}

/* Main content area */
.main-content {{
  flex: 1; overflow-y: auto; padding: 24px 32px;
  min-width: 0;
}}

/* Right panel — graph + entity detail */
.right-panel {{
  width: 380px; min-width: 380px; flex-shrink: 0;
  background: var(--surface); border-left: 1px solid var(--border);
  display: flex; flex-direction: column; overflow: hidden;
  transition: width 0.3s, min-width 0.3s;
}}
.right-panel.collapsed {{
  width: 40px; min-width: 40px;
}}
.panel-toggle {{
  position: absolute; left: -16px; top: 50%; transform: translateY(-50%);
  width: 16px; height: 48px; background: var(--surface);
  border: 1px solid var(--border); border-right: none;
  border-radius: 6px 0 0 6px; cursor: pointer; z-index: 10;
  display: flex; align-items: center; justify-content: center;
  font-size: 10px; color: var(--text2);
}}
.panel-toggle:hover {{ background: var(--surface2); }}

/* Graph zone */
.graph-zone {{
  flex: 6; min-height: 200px; position: relative;
  border-bottom: 1px solid var(--border);
}}
.graph-header {{
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 14px; border-bottom: 1px solid var(--border);
}}
.graph-header h4 {{
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em;
  color: var(--text2); font-weight: 600;
}}
.graph-controls {{
  display: flex; gap: 4px;
}}
.graph-filter {{
  font-size: 10px; padding: 2px 8px; border-radius: 10px;
  border: 1px solid var(--border); background: var(--surface);
  cursor: pointer; font-family: var(--font-mono); font-weight: 500;
  transition: background 0.15s, border-color 0.15s;
}}
.graph-filter.active {{
  border-color: currentColor;
}}
.graph-filter[data-type="trend"] {{ color: var(--tips-trend); }}
.graph-filter[data-type="implication"] {{ color: var(--tips-implication); }}
.graph-filter[data-type="possibility"] {{ color: var(--tips-possibility); }}
.graph-filter[data-type="solution"] {{ color: var(--tips-solution); }}
#graph-container {{
  width: 100%; height: calc(100% - 42px);
}}
#graph-container svg {{
  width: 100%; height: 100%;
}}

/* Resize handle */
.resize-handle {{
  height: 6px; cursor: ns-resize; background: var(--border);
  transition: background 0.2s;
}}
.resize-handle:hover {{ background: var(--accent-muted); }}

/* Entity detail zone */
.detail-zone {{
  flex: 4; overflow-y: auto; padding: 14px;
}}
.detail-zone .empty-state {{
  color: var(--text2); font-size: 13px; text-align: center;
  padding: 40px 16px; line-height: 1.6;
}}
.detail-card {{
  background: var(--bg); border-radius: var(--radius); padding: 16px;
  border: 1px solid var(--border);
}}
.detail-card .type-badge {{
  display: inline-block; font-size: 10px; font-weight: 600;
  text-transform: uppercase; letter-spacing: 0.08em;
  padding: 2px 8px; border-radius: 4px; margin-bottom: 8px;
}}
.detail-card .type-badge.trend {{ background: color-mix(in srgb, var(--tips-trend) 15%, transparent); color: var(--tips-trend); }}
.detail-card .type-badge.implication {{ background: color-mix(in srgb, var(--tips-implication) 15%, transparent); color: var(--tips-implication); }}
.detail-card .type-badge.possibility {{ background: color-mix(in srgb, var(--tips-possibility) 15%, transparent); color: var(--tips-possibility); }}
.detail-card .type-badge.solution {{ background: color-mix(in srgb, var(--tips-solution) 15%, transparent); color: var(--tips-solution); }}
.detail-card h3 {{ font-size: 16px; margin-bottom: 8px; }}
.detail-card .statement {{ font-size: 13px; color: var(--text2); line-height: 1.6; margin-bottom: 12px; }}
.detail-card .meta-row {{
  display: flex; gap: 12px; flex-wrap: wrap; font-size: 12px; color: var(--text2);
}}
.detail-card .meta-row .meta-item {{
  display: flex; align-items: center; gap: 4px;
}}
.detail-card .meta-row .meta-label {{ font-weight: 600; }}

/* ============ TAB PANELS ============ */
.tab-panel {{ display: none; }}
.tab-panel.active {{ display: block; }}

/* Header card */
.project-header {{
  background: var(--surface-dark); color: var(--text-light);
  padding: 32px 28px 24px; border-radius: var(--radius);
  margin-bottom: 24px; position: relative; overflow: hidden;
  box-shadow: var(--shadow-lg);
}}
.project-header::before {{
  content: ""; position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 60% 50% at 10% 90%, color-mix(in srgb, var(--accent) 18%, transparent) 0%, transparent 70%),
    radial-gradient(ellipse 40% 60% at 85% 20%, color-mix(in srgb, var(--accent) 10%, transparent) 0%, transparent 60%);
  pointer-events: none;
}}
.project-header > * {{ position: relative; z-index: 1; }}
.project-header h1 {{
  font-size: 28px; font-weight: 700; margin-bottom: 4px;
  color: var(--text-light); letter-spacing: -0.02em;
}}
.project-header .meta {{
  color: rgba(255,255,255,0.55); font-size: 13px;
  display: flex; gap: 20px; flex-wrap: wrap;
}}
.project-header .meta span {{
  display: flex; align-items: center; gap: 6px;
}}

/* Phase progress bar */
.phase-bar {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 20px 24px;
  margin-bottom: 24px; box-shadow: var(--shadow-sm);
}}
.phase-bar h3 {{
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em;
  color: var(--text2); margin-bottom: 12px; font-weight: 600;
}}
.phase-steps {{ display: flex; gap: 4px; margin-bottom: 8px; }}
.phase-step {{
  flex: 1; height: 6px; border-radius: 3px;
  background: var(--surface2); transition: background 0.4s;
  position: relative;
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
.phase-labels {{
  display: flex; gap: 4px;
}}
.phase-lbl {{
  flex: 1; font-size: 9px; text-align: center;
  color: var(--text2); overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}}
.phase-lbl.done {{ color: var(--accent-dark); font-weight: 600; }}
.phase-lbl.current {{ color: var(--accent); font-weight: 700; }}

/* Cards grid */
.cards {{
  display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 14px; margin-bottom: 24px;
}}
.card {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 18px;
  transition: border-color 0.25s, box-shadow 0.25s, transform 0.25s;
  box-shadow: var(--shadow-sm); position: relative; overflow: hidden;
}}
.card::before {{
  content: ""; position: absolute; top: 0; left: 0; right: 0;
  height: 3px; background: var(--accent);
  transform: scaleX(0); transform-origin: left;
  transition: transform 0.35s cubic-bezier(0.22,1,0.36,1);
}}
.card:hover {{
  border-color: var(--accent-muted); box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}}
.card:hover::before {{ transform: scaleX(1); }}
.card .label {{
  font-size: 10px; color: var(--text2); text-transform: uppercase;
  letter-spacing: 0.08em; font-weight: 600; margin-bottom: 4px;
}}
.card .value {{
  font-size: 28px; font-weight: 700; font-family: var(--font-headers);
  line-height: 1.1;
}}
.card .sub {{ font-size: 12px; color: var(--text2); margin-top: 4px; }}

/* Heatmap grid */
.heatmap {{
  display: grid; gap: 2px; margin-bottom: 24px;
}}
.heatmap-cell {{
  padding: 12px; border-radius: 8px; text-align: center;
  cursor: pointer; transition: transform 0.15s, box-shadow 0.15s;
  border: 1px solid var(--border);
}}
.heatmap-cell:hover {{
  transform: scale(1.05); box-shadow: var(--shadow-md); z-index: 2;
}}
.heatmap-cell .cell-count {{
  font-size: 20px; font-weight: 700; font-family: var(--font-headers);
}}
.heatmap-cell .cell-label {{
  font-size: 10px; color: var(--text2); text-transform: uppercase;
  letter-spacing: 0.05em;
}}
.heatmap-header {{
  font-size: 10px; font-weight: 600; text-transform: uppercase;
  letter-spacing: 0.08em; color: var(--text2); padding: 8px;
  text-align: center;
}}

/* Section headings */
.section {{
  margin-bottom: 32px;
}}
.section-title {{
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em;
  color: var(--text2); font-weight: 600; margin-bottom: 16px;
  padding-bottom: 8px; border-bottom: 1px solid var(--border);
}}

/* Candidate cards */
.candidate-card {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 16px; margin-bottom: 10px;
  cursor: pointer; transition: border-color 0.2s, box-shadow 0.2s;
}}
.candidate-card:hover {{
  border-color: var(--accent-muted); box-shadow: var(--shadow-md);
}}
.candidate-card .c-name {{
  font-size: 15px; font-weight: 600; margin-bottom: 4px;
}}
.candidate-card .c-statement {{
  font-size: 13px; color: var(--text2); line-height: 1.5; margin-bottom: 8px;
}}
.candidate-card .c-meta {{
  display: flex; gap: 8px; flex-wrap: wrap;
}}
.badge {{
  display: inline-block; font-size: 10px; font-weight: 600;
  padding: 2px 8px; border-radius: 4px;
  text-transform: uppercase; letter-spacing: 0.05em;
}}
.badge-score {{
  background: var(--surface-dark); color: var(--accent);
  font-family: var(--font-mono);
}}
.badge-confidence-high {{ background: color-mix(in srgb, var(--green) 15%, transparent); color: var(--green); }}
.badge-confidence-medium {{ background: color-mix(in srgb, var(--yellow) 15%, transparent); color: var(--yellow); }}
.badge-confidence-low {{ background: color-mix(in srgb, var(--red) 15%, transparent); color: var(--red); }}
.badge-dim {{
  color: white; font-size: 9px;
}}

/* Theme cards */
.theme-card {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 20px; margin-bottom: 16px;
  box-shadow: var(--shadow-sm);
}}
.theme-card h3 {{
  font-size: 18px; margin-bottom: 4px;
}}
.theme-card .strategic-q {{
  font-size: 14px; color: var(--text2); font-style: italic;
  margin-bottom: 12px; line-height: 1.5;
}}
.theme-card .theme-meta {{
  display: flex; gap: 12px; flex-wrap: wrap; font-size: 12px; margin-bottom: 12px;
}}
.theme-card .theme-narrative {{
  font-size: 13px; color: var(--text2); line-height: 1.6;
}}

/* Value chain flow */
.chain-flow {{
  display: flex; align-items: center; gap: 8px; padding: 12px 0;
  overflow-x: auto; flex-wrap: nowrap;
}}
.chain-node {{
  padding: 8px 14px; border-radius: 8px; font-size: 12px;
  font-weight: 500; white-space: nowrap; cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
  border: 1px solid;
}}
.chain-node:hover {{ transform: scale(1.05); box-shadow: var(--shadow-md); }}
.chain-node.trend {{ background: color-mix(in srgb, var(--tips-trend) 12%, var(--surface)); border-color: var(--tips-trend); color: var(--tips-trend); }}
.chain-node.implication {{ background: color-mix(in srgb, var(--tips-implication) 12%, var(--surface)); border-color: var(--tips-implication); color: var(--tips-implication); }}
.chain-node.possibility {{ background: color-mix(in srgb, var(--tips-possibility) 12%, var(--surface)); border-color: var(--tips-possibility); color: var(--tips-possibility); }}
.chain-node.solution {{ background: color-mix(in srgb, var(--tips-solution) 12%, var(--surface)); border-color: var(--tips-solution); color: var(--tips-solution); }}
.chain-arrow {{
  color: var(--text2); font-size: 16px; flex-shrink: 0;
}}

/* Solution ranking table */
.ranking-table {{
  width: 100%; border-collapse: collapse; font-size: 13px;
}}
.ranking-table th {{
  text-align: left; font-size: 10px; text-transform: uppercase;
  letter-spacing: 0.08em; color: var(--text2); font-weight: 600;
  padding: 8px 12px; border-bottom: 2px solid var(--border);
}}
.ranking-table td {{
  padding: 10px 12px; border-bottom: 1px solid var(--border);
  vertical-align: top;
}}
.ranking-table tr:hover {{ background: var(--surface); }}
.ranking-table .rank-num {{
  font-family: var(--font-mono); font-weight: 700; font-size: 14px;
  color: var(--accent-dark); width: 40px;
}}
.ranking-table .st-name {{ font-weight: 600; }}
.ranking-table .br-bar {{
  display: inline-block; height: 6px; border-radius: 3px;
  background: var(--accent); vertical-align: middle;
}}

/* Anchor coverage */
.anchor-summary {{
  display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 16px;
}}
.anchor-summary-chip {{
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 12px; font-weight: 600; padding: 4px 10px;
  border-radius: 6px;
}}
.anchor-card {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 14px 16px; margin-bottom: 10px;
}}
.anchor-card-header {{
  display: flex; align-items: center; justify-content: space-between;
  cursor: pointer;
}}
.anchor-card-header h4 {{ margin: 0; font-size: 14px; }}
.anchor-needs {{
  display: flex; flex-wrap: wrap; gap: 4px; margin-top: 8px;
}}
.need-pill {{
  display: inline-block; font-size: 11px; padding: 2px 8px;
  border-radius: 4px; font-weight: 500;
}}
.need-delivered {{
  background: rgba(46,125,50,0.1); color: var(--green);
}}
.need-undelivered {{
  background: rgba(211,47,47,0.08); color: var(--red);
}}
.anchor-detail {{
  display: none; margin-top: 10px; padding-top: 10px;
  border-top: 1px solid var(--border);
}}
.anchor-st-item {{
  padding: 8px 0; border-bottom: 1px solid var(--border);
}}
.anchor-st-item:last-child {{ border-bottom: none; }}
.anchor-st-item h5 {{ margin: 0 0 4px 0; font-size: 13px; }}
.anchor-badge {{
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 10px; font-weight: 600; padding: 2px 6px;
  border-radius: 4px;
  background: rgba(34,197,94,0.15); color: var(--tips-solution);
}}
.quality-flag {{
  display: inline-block; font-size: 10px; font-weight: 600;
  padding: 2px 6px; border-radius: 4px;
  background: rgba(229,161,0,0.12); color: var(--amber);
}}

/* Claims table */
.claims-table {{
  width: 100%; border-collapse: collapse; font-size: 13px;
}}
.claims-table th {{
  text-align: left; font-size: 10px; text-transform: uppercase;
  letter-spacing: 0.08em; color: var(--text2); font-weight: 600;
  padding: 8px 12px; border-bottom: 2px solid var(--border);
}}
.claims-table td {{
  padding: 8px 12px; border-bottom: 1px solid var(--border);
}}
.claims-table tr:hover {{ background: var(--surface); }}

/* Status badges */
.status-verified {{ color: var(--green); }}
.status-unverified {{ color: var(--text2); }}
.status-deviated {{ color: var(--red); }}
.status-resolved {{ color: var(--blue); }}

/* Not-available state */
.not-available {{
  text-align: center; padding: 60px 24px; color: var(--text2);
}}
.not-available h3 {{
  font-size: 16px; color: var(--text); margin-bottom: 8px;
}}
.not-available p {{
  font-size: 14px; line-height: 1.6;
}}
.not-available code {{
  background: var(--surface2); padding: 2px 8px; border-radius: 4px;
  font-family: var(--font-mono); font-size: 13px;
}}

/* Donut chart */
.donut-container {{
  display: flex; align-items: center; gap: 16px;
}}
.donut-legend {{
  font-size: 13px;
}}
.donut-legend .legend-item {{
  display: flex; align-items: center; gap: 6px; margin-bottom: 4px;
}}
.donut-legend .legend-dot {{
  width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0;
}}

/* Distribution bars */
.dist-bar-container {{
  margin-bottom: 8px;
}}
.dist-bar-label {{
  display: flex; justify-content: space-between; font-size: 12px;
  margin-bottom: 2px;
}}
.dist-bar-track {{
  height: 8px; background: var(--surface2); border-radius: 4px; overflow: hidden;
}}
.dist-bar-fill {{
  height: 100%; border-radius: 4px; transition: width 0.6s cubic-bezier(0.22,1,0.36,1);
}}

/* Catalog heatmap */
.taxonomy-grid {{
  display: grid; gap: 3px; margin-bottom: 24px;
}}
.taxonomy-cell {{
  padding: 8px; border-radius: 6px; text-align: center;
  font-size: 11px; border: 1px solid var(--border);
  transition: transform 0.15s;
}}
.taxonomy-cell:hover {{ transform: scale(1.03); }}
.taxonomy-cell.covered {{
  background: color-mix(in srgb, var(--green) 15%, var(--surface));
  border-color: var(--green);
}}
.taxonomy-cell.gap {{
  background: color-mix(in srgb, var(--red) 8%, var(--surface));
  border-color: color-mix(in srgb, var(--red) 30%, var(--border));
}}

/* Reveal animation */
.reveal {{
  opacity: 0; transform: translateY(18px);
  transition: opacity 0.5s cubic-bezier(0.22,1,0.36,1), transform 0.5s cubic-bezier(0.22,1,0.36,1);
}}
.reveal.visible {{ opacity: 1; transform: translateY(0); }}

@media (max-width: 1200px) {{
  .right-panel {{ width: 320px; min-width: 320px; }}
}}
@media (max-width: 900px) {{
  .left-panel {{ width: 160px; min-width: 160px; }}
  .right-panel {{ display: none; }}
}}
@media (max-width: 600px) {{
  .left-panel {{ display: none; }}
}}
</style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar">
  <div class="navbar-brand">{project_name}</div>
  <div class="navbar-tabs">
    <button class="navbar-tab active" data-tab="overview">{L['tab_overview']}</button>
    <button class="navbar-tab{'' if scout else ' disabled'}" data-tab="scout">{L['tab_scout']}</button>
    <button class="navbar-tab{'' if vm else ' disabled'}" data-tab="model">{L['tab_model']}</button>
    <button class="navbar-tab{'' if data['has_report'] or claims_list else ' disabled'}" data-tab="report">{L['tab_report']}</button>
    <button class="navbar-tab{'' if has_catalog else ' disabled'}" data-tab="catalog">{L['tab_catalog']}</button>
  </div>
</nav>

<!-- LAYOUT -->
<div class="layout">

  <!-- LEFT PANEL -->
  <div class="left-panel" id="leftPanel">
    <!-- Populated by JS based on active tab -->
  </div>

  <!-- MAIN CONTENT -->
  <div class="main-content" id="mainContent">

    <!-- ==================== OVERVIEW TAB ==================== -->
    <div class="tab-panel active" id="panel-overview">

      <!-- Project header -->
      <div class="project-header reveal">
        <h1>{project_name}</h1>
        <div class="meta">
          <span>{industry}{(' / ' + subsector) if subsector else ''}</span>
          <span>{research_topic}</span>
          <span>{now}</span>
        </div>
      </div>

      <!-- Phase progress -->
      <div class="phase-bar reveal" id="sec-overview-phase">
        <h3>{L['phase_progress']}</h3>
        <div class="phase-steps">
"""

    # Phase steps
    stages = L["stages"]
    for i in range(len(stages)):
        cls = "done" if i < phase_idx else ("current" if i == phase_idx else "")
        html += f'          <div class="phase-step {cls}"></div>\n'

    html += '        </div>\n        <div class="phase-labels">\n'
    for i, stage in enumerate(stages):
        cls = "done" if i < phase_idx else ("current" if i == phase_idx else "")
        html += f'          <div class="phase-lbl {cls}">{esc(stage)}</div>\n'
    html += '        </div>\n      </div>\n\n'

    # Scoring summary cards
    avg_score = scout_scoring.get("avg_score", 0)
    leading_pct_val = 0
    confidence_dist = scout_scoring.get("confidence_distribution", {})
    indicator_dist = scout_scoring.get("indicator_distribution", scout_scoring.get("indicator_type_distribution", scout_scoring.get("intensity_distribution", {})))
    # Fix 4: compute indicator_distribution from candidates when metadata lacks it
    if not indicator_dist and candidates:
        computed = {}
        for c in candidates:
            ic = c.get("indicator_classification", {})
            itype = ic.get("type", "") if isinstance(ic, dict) else ""
            if not itype:
                itype = c.get("indicator_type", "")
            if itype:
                computed[itype] = computed.get(itype, 0) + 1
        if computed:
            indicator_dist = computed
    if indicator_dist:
        total_ind = sum(v for v in indicator_dist.values() if isinstance(v, (int, float)))
        # Handle both formats: leading/lagging/coincident or level_1..level_5
        if "leading" in indicator_dist:
            leading_pct_val = int((indicator_dist.get("leading", 0) / total_ind * 100)) if total_ind > 0 else 0
        elif "level_4" in indicator_dist or "level_5" in indicator_dist:
            # level_4 and level_5 are strong signals (similar to "leading")
            strong = indicator_dist.get("level_4", 0) + indicator_dist.get("level_5", 0)
            leading_pct_val = int((strong / total_ind * 100)) if total_ind > 0 else 0

    high_conf = confidence_dist.get("high", 0)
    med_conf = confidence_dist.get("medium", 0)
    low_conf = confidence_dist.get("low", 0)

    html += f"""      <!-- Scoring summary -->
      <div class="section reveal" id="sec-overview-scoring">
        <div class="section-title">{L['scoring_summary']}</div>
        <div class="cards">
          <div class="card">
            <div class="label">{L['candidates']}</div>
            <div class="value">{len(candidates)}</div>
            <div class="sub">/ 60 target</div>
          </div>
          <div class="card">
            <div class="label">{L['avg_score']}</div>
            <div class="value">{avg_score:.2f}</div>
            <div class="sub">out of 1.0</div>
          </div>
          <div class="card">
            <div class="label">{L['leading_pct']}</div>
            <div class="value">{leading_pct_val}%</div>
            <div class="sub">leading indicators</div>
          </div>
          <div class="card">
            <div class="label">{L['confidence']}</div>
            <div class="value" style="font-size:16px;line-height:1.8">
              <span style="color:var(--green)">{high_conf} {L['high']}</span><br>
              <span style="color:var(--yellow)">{med_conf} {L['medium']}</span><br>
              <span style="color:var(--red)">{low_conf} {L['low']}</span>
            </div>
          </div>
          <div class="card">
            <div class="label">{L['anchored_sts']}</div>
            <div class="value">{anchored_count} / {total_sts_count}</div>
            <div class="sub">{L['portfolio_anchored'].lower()}</div>
          </div>
        </div>
      </div>
"""

    # Fix 5: Top Trends section in overview
    if candidates:
        top_n = sorted(candidates, key=lambda c: c.get("score", 0), reverse=True)[:10]
        html += f'      <!-- Top trends -->\n'
        html += f'      <div class="section reveal" id="sec-overview-trends">\n'
        html += f'        <div class="section-title">{L.get("top_trends", "Top Trends")}</div>\n'
        for rank, tc in enumerate(top_n, 1):
            t_name = esc(tc.get("trend_name", tc.get("name", f"Trend {rank}")))
            t_score = tc.get("score", 0)
            t_dim = tc.get("dimension", "")
            t_dim_idx = _dimension_index(t_dim)
            t_color = DIMENSION_COLORS[t_dim_idx]
            t_dim_label = esc(_dimension_display_name(t_dim, lang))
            t_hor = esc(tc.get("horizon", ""))
            html += f'        <div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--border)">\n'
            html += f'          <span style="color:var(--text2);font-size:13px;width:20px">{rank}</span>\n'
            html += f'          <span class="dim-dot" style="background:{t_color};width:10px;height:10px;border-radius:50%;display:inline-block;flex-shrink:0"></span>\n'
            html += f'          <span style="flex:1;font-weight:500">{t_name}</span>\n'
            html += f'          <span class="badge badge-score">{t_score:.2f}</span>\n'
            if t_hor:
                html += f'          <span class="badge" style="background:var(--surface2);color:var(--text2);font-size:11px">{t_hor}</span>\n'
            html += f'          <span style="color:var(--text2);font-size:11px">{t_dim_label}</span>\n'
            html += f'        </div>\n'
        html += '      </div>\n\n'

    # Dimension × Horizon heatmap
    html += f"""
      <!-- Dimension x Horizon heatmap -->
      <div class="section reveal" id="sec-overview-heatmap">
        <div class="section-title">{L['dim_heatmap']}</div>
        <div class="heatmap" style="grid-template-columns: 160px repeat(3, 1fr)">
          <div class="heatmap-header"></div>
"""
    for h in L["horizons"]:
        html += f'          <div class="heatmap-header">{esc(h)}</div>\n'

    for di, dim in enumerate(L["dimensions"]):
        color = DIMENSION_COLORS[di]
        html += f'          <div class="heatmap-header" style="text-align:left;color:{color}">{esc(dim)}</div>\n'
        for hi, hor in enumerate(L["horizons"]):
            # Match: iterate all dim_horizon entries and match by dimension index + horizon
            count = 0
            for (d_key, h_key), val in dim_horizon.items():
                if _dimension_index(d_key) == di and h_key.upper() == hor.upper():
                    count += val
            intensity = min(count / 5.0, 1.0) if count > 0 else 0
            bg = f"color-mix(in srgb, {color} {int(intensity * 40 + 5)}%, var(--surface))" if count > 0 else "var(--surface2)"
            html += f'          <div class="heatmap-cell" style="background:{bg}" data-dim="{di}" data-hor="{hi}"><div class="cell-count">{count}</div><div class="cell-label">{esc(dim[:3])}/{esc(hor[:3])}</div></div>\n'

    html += '        </div>\n      </div>\n\n'

    # Source integrity — handle both source_distribution format and legacy format
    web_count = scout_source_integrity.get("web_signal", scout_source_integrity.get("web_signal_count", 0))
    training_count = scout_source_integrity.get("training", scout_source_integrity.get("training_count", scout_source_integrity.get("training_capped", 0)))
    user_proposed = scout_source_integrity.get("user_proposed", 0)
    corroboration = scout_source_integrity.get("corroboration_rate", 0)
    # If no explicit corroboration rate, estimate from web/training ratio
    if not corroboration and training_count > 0 and web_count > 0:
        corroboration = int(min(web_count, training_count) / max(web_count, training_count) * 100)
    total_sources = web_count + training_count + user_proposed if (web_count + training_count + user_proposed) > 0 else 1

    html += f"""      <!-- Source integrity -->
      <div class="section reveal" id="sec-overview-sources">
        <div class="section-title">{L['source_integrity']}</div>
        <div style="max-width:400px">
          <div class="dist-bar-container">
            <div class="dist-bar-label"><span>{L['web_sourced']}</span><span>{web_count}</span></div>
            <div class="dist-bar-track"><div class="dist-bar-fill" style="width:{web_count/total_sources*100:.0f}%;background:var(--blue)"></div></div>
          </div>
          <div class="dist-bar-container">
            <div class="dist-bar-label"><span>{L['training_based']}</span><span>{training_count}</span></div>
            <div class="dist-bar-track"><div class="dist-bar-fill" style="width:{training_count/total_sources*100:.0f}%;background:var(--yellow)"></div></div>
          </div>
          <div class="dist-bar-container">
            <div class="dist-bar-label"><span>{L['corroboration']}</span><span>{corroboration}%</span></div>
            <div class="dist-bar-track"><div class="dist-bar-fill" style="width:{corroboration}%;background:var(--green)"></div></div>
          </div>
        </div>
      </div>
    </div>
"""

    # ==================== SCOUT TAB ====================
    html += f"""
    <!-- SCOUT TAB -->
    <div class="tab-panel" id="panel-scout">
"""
    if not scout:
        html += f"""      <div class="not-available">
        <h3>{L['not_available']}</h3>
        <p>{L['run_skill']} <code>trend-scout</code> {L['to_generate']}</p>
      </div>
"""
    else:
        # Group candidates by dimension (resolve slugs to display names)
        dims_grouped = {}
        for cand in candidates:
            d_raw = cand.get("dimension", cand.get("dimension_de", "Unknown"))
            d_display = _dimension_display_name(d_raw, lang)
            dims_grouped.setdefault(d_display, []).append(cand)

        # Sort by dimension index
        sorted_dims = sorted(dims_grouped.keys(), key=lambda d: _dimension_index(d))
        for dim_name in sorted_dims:
            di = _dimension_index(dim_name)
            dim_cands = dims_grouped[dim_name]
            color = DIMENSION_COLORS[di]
            html += f"""      <div class="section reveal" id="sec-scout-dim-{di}">
        <div class="section-title" style="border-left:4px solid {color};padding-left:12px">{esc(dim_name)} ({len(dim_cands)})</div>
"""
            for ci, cand in enumerate(dim_cands):
                score = cand.get("score", 0)
                conf = cand.get("confidence_tier", "medium").lower()
                conf_cls = f"badge-confidence-{conf}" if conf in ("high", "medium", "low") else "badge-confidence-medium"
                # Fix 2: extract indicator_type from nested indicator_classification
                indicator = cand.get("indicator_type", "")
                if not indicator:
                    ic = cand.get("indicator_classification", {})
                    if isinstance(ic, dict):
                        indicator = ic.get("type", "")
                # Fix 3: extract diffusion_stage string from dict
                diffusion = cand.get("diffusion_stage", "")
                if isinstance(diffusion, dict):
                    diffusion = diffusion.get("stage", "")
                hor = cand.get("horizon", "")
                name = cand.get("trend_name", cand.get("name", f"Candidate {ci+1}"))
                stmt = cand.get("trend_statement", cand.get("statement", ""))
                cand_idx = candidates.index(cand) if cand in candidates else ci

                html += f"""        <div class="candidate-card" onclick="showCandidate({cand_idx})" data-candidate="{cand_idx}">
          <div class="c-name">{esc(name)}</div>
          <div class="c-statement">{esc(stmt[:200])}{'...' if len(stmt) > 200 else ''}</div>
          <div class="c-meta">
            <span class="badge badge-score">{score:.2f}</span>
            <span class="badge {conf_cls}">{esc(conf)}</span>
            <span class="badge badge-dim" style="background:{color}">{esc(hor)}</span>
"""
                if indicator:
                    html += f'            <span class="badge" style="background:var(--surface2);color:var(--text2)">{esc(indicator)}</span>\n'
                if diffusion:
                    html += f'            <span class="badge" style="background:var(--surface2);color:var(--text2)">{esc(diffusion)}</span>\n'
                html += """          </div>
        </div>
"""
            html += "      </div>\n"

    html += "    </div>\n"

    # ==================== VALUE MODEL TAB ====================
    html += f"""
    <!-- VALUE MODEL TAB -->
    <div class="tab-panel" id="panel-model">
"""
    if not vm:
        html += f"""      <div class="not-available">
        <h3>{L['not_available']}</h3>
        <p>{L['run_skill']} <code>value-modeler</code> {L['to_generate']}</p>
      </div>
"""
    else:
        # Theme cards
        html += f'      <div class="section" id="sec-model-themes">\n'
        html += f'        <div class="section-title">{L["themes"]} ({len(themes_list)})</div>\n'
        for ti, theme_obj in enumerate(themes_list):
            theme_name = theme_obj.get("name", f"Theme {ti+1}")
            strategic_q = theme_obj.get("strategic_question", "")
            narrative = theme_obj.get("narrative", "")
            br_avg = theme_obj.get("business_relevance_avg", 0)
            ranking_val = theme_obj.get("ranking_value", 0)
            # Use resolved chains (handles both inline objects and string references)
            chains = theme_obj.get("_resolved_chains", theme_obj.get("value_chains", []))
            # Filter out any remaining string references
            chains = [ch for ch in chains if isinstance(ch, dict)]

            html += f"""        <div class="theme-card reveal" id="sec-model-theme-{ti}">
          <h3>{esc(theme_name)}</h3>
          <div class="strategic-q">{esc(strategic_q)}</div>
          <div class="theme-meta">
            <span class="badge badge-score">BR {br_avg:.1f}</span>
            <span class="badge" style="background:var(--surface2);color:var(--text2)">Rank {ranking_val:.2f}</span>
            <span class="badge" style="background:var(--surface2);color:var(--text2)">{len(chains)} chains</span>
          </div>
          <div class="theme-narrative">{esc(narrative[:300])}{'...' if len(narrative) > 300 else ''}</div>
"""
            # Value chain flows — with graph focus on click
            for chain in chains:
                chain_id = chain.get("chain_id", chain.get("id", ""))
                chain_name = chain.get("name", chain_id)
                trend = chain.get("trend", {})
                imps = chain.get("implications", [])
                poss = chain.get("possibilities", [])

                html += '          <div style="margin-top:12px">\n'
                html += f'            <div style="font-size:11px;color:var(--text2);font-weight:600;margin-bottom:6px">{esc(chain_name)}</div>\n'
                html += '            <div class="chain-flow">\n'
                if trend:
                    t_name = trend.get("name", trend.get("trend_name", "T"))
                    t_graph_id = f"chain-t-{chain_id}"
                    html += f'              <div class="chain-node trend" title="{esc_js(t_name)}" onclick="focusGraphNode(\'{esc_js(t_graph_id)}\')">{esc(t_name[:25])}</div>\n'
                for imp in imps[:2]:
                    imp_name = imp.get("name", "I")
                    i_graph_id = f"chain-i-{chain_id}-{imp_name[:20]}"
                    html += '              <div class="chain-arrow">&rarr;</div>\n'
                    html += f'              <div class="chain-node implication" onclick="focusGraphNode(\'{esc_js(i_graph_id)}\')">{esc(imp_name[:25])}</div>\n'
                for pos in poss[:2]:
                    pos_name = pos.get("name", "P")
                    p_graph_id = f"chain-p-{chain_id}-{pos_name[:20]}"
                    html += '              <div class="chain-arrow">&rarr;</div>\n'
                    html += f'              <div class="chain-node possibility" onclick="focusGraphNode(\'{esc_js(p_graph_id)}\')">{esc(pos_name[:25])}</div>\n'
                # Append solution nodes from theme-level solution_templates (P→S)
                theme_sts = theme_obj.get("solution_templates", [])
                shown_solutions = 0
                for st_ref in theme_sts:
                    if shown_solutions >= 2:
                        break
                    st_obj = st_ref if isinstance(st_ref, dict) else vm_st_lookup.get(st_ref) if isinstance(st_ref, str) else None
                    if not st_obj or not isinstance(st_obj, dict):
                        continue
                    s_name = st_obj.get("name", "S")
                    s_graph_id = f"st-{st_obj.get('st_id', st_obj.get('id', ''))}"
                    anchor_mark = ' <span title="portfolio-anchored" style="font-size:10px">&#9875;</span>' if st_obj.get("generation_mode") in ("portfolio-anchored", "re-anchored") else ""
                    html += '              <div class="chain-arrow">&rarr;</div>\n'
                    html += f'              <div class="chain-node solution" onclick="focusGraphNode(\'{esc_js(s_graph_id)}\')">{esc(s_name[:25])}{anchor_mark}</div>\n'
                    shown_solutions += 1
                html += '            </div>\n'
                html += '          </div>\n'

            html += "        </div>\n"
        html += "      </div>\n"

        # Solution ranking table
        if all_sts:
            html += f"""      <div class="section reveal" id="sec-model-ranking">
        <div class="section-title">{L['solution_ranking']} ({len(all_sts)})</div>
        <table class="ranking-table">
          <thead><tr>
            <th>#</th><th>Solution Template</th><th>Theme</th><th>Category</th><th>BR</th><th>Rank</th><th>Anchor</th>
          </tr></thead>
          <tbody>
"""
            for ri, st in enumerate(all_sts):
                br = st.get("business_relevance", st.get("business_relevance_calculated", 0)) or 0
                rv = st.get("ranking_value", 0) or 0
                bar_w = int(float(br) / 5.0 * 100) if br else 0
                st_id = st.get("st_id", st.get("id", ""))
                st_graph_id = f"st-{st_id}"
                anchor_badge = ""
                if st.get("generation_mode") in ("portfolio-anchored", "re-anchored"):
                    pa = st.get("portfolio_anchor", {}) or {}
                    feat = pa.get("feature_slug", "")
                    qf_icon = ' <span class="quality-flag">!</span>' if st.get("quality_flag") else ""
                    anchor_badge = f'<span class="anchor-badge">&#9875; {esc(feat[:18])}{qf_icon}</span>'
                html += f"""            <tr style="cursor:pointer" onclick="focusGraphNode('{esc_js(st_graph_id)}')">
              <td class="rank-num">{ri+1}</td>
              <td class="st-name">{esc(st.get('name', ''))}</td>
              <td>{esc(st.get('_theme_name', ''))}</td>
              <td><span class="badge" style="background:var(--surface2);color:var(--text2)">{esc(st.get('category', ''))}</span></td>
              <td><span class="br-bar" style="width:{bar_w}px"></span> {float(br):.1f}</td>
              <td class="mono">{float(rv):.2f}</td>
              <td>{anchor_badge}</td>
            </tr>
"""
            html += "          </tbody>\n        </table>\n      </div>\n"

        # Anchor coverage section
        if anchored_sts:
            html += f"""      <div class="section reveal" id="sec-model-anchor">
        <div class="section-title">{L['anchor_coverage']}</div>
        <div class="anchor-summary">
          <span class="anchor-summary-chip" style="background:rgba(34,197,94,0.1);color:var(--tips-solution)">{anchored_count} {L['anchored_sts']}</span>
          <span class="anchor-summary-chip" style="background:var(--surface2);color:var(--text2)">{total_sts_count - anchored_count} {L['abstract_sts']}</span>
          <span class="anchor-summary-chip" style="background:rgba(46,125,50,0.08);color:var(--green)">{len(all_delivered_needs)} {L['delivered_needs']}</span>
          <span class="anchor-summary-chip" style="background:rgba(211,47,47,0.08);color:var(--red)">{len(all_undelivered_needs)} {L['unmet_needs']}</span>
          {'<span class="quality-flag">' + L['quality_flag'] + '</span>' if has_quality_issues else ''}
        </div>
"""
            for theme_name in sorted(anchored_by_theme.keys()):
                theme_sts = anchored_by_theme[theme_name]
                card_id = f"anchor-theme-{esc(theme_name[:20].replace(' ', '-').lower())}"
                # Aggregate needs for this theme
                theme_delivered = set()
                theme_undelivered = set()
                theme_quality = False
                for st in theme_sts:
                    anchor = st.get("portfolio_anchor", {}) or {}
                    for n in anchor.get("theme_needs_delivered", []):
                        theme_delivered.add(n)
                    for n in anchor.get("theme_needs_undelivered", []):
                        theme_undelivered.add(n)
                    if st.get("quality_flag"):
                        theme_quality = True

                delivered_pills = "".join(f'<span class="need-pill need-delivered">{esc(n)}</span>' for n in sorted(theme_delivered))
                undelivered_pills = "".join(f'<span class="need-pill need-undelivered">{esc(n)}</span>' for n in sorted(theme_undelivered))

                html += f"""        <div class="anchor-card">
          <div class="anchor-card-header" onclick="var d=document.getElementById('{card_id}');d.style.display=d.style.display==='none'?'block':'none'">
            <h4>{esc(theme_name)}{' <span class="quality-flag" style="margin-left:8px">!</span>' if theme_quality else ''}</h4>
            <span class="badge" style="background:var(--surface2);color:var(--text2)">{len(theme_sts)} ST{'s' if len(theme_sts) != 1 else ''}</span>
          </div>
          <div class="anchor-needs">{delivered_pills}{undelivered_pills}</div>
          <div class="anchor-detail" id="{card_id}">
"""
                for st in sorted(theme_sts, key=lambda x: x.get("st_id", "")):
                    st_name = esc(st.get("name", st.get("st_id", "Unknown")))
                    st_id_val = esc(st.get("st_id", ""))
                    pa = st.get("portfolio_anchor", {}) or {}
                    feat_slug = esc(pa.get("feature_slug", ""))
                    prod_slug = esc(pa.get("product_slug", ""))
                    qf = st.get("quality_flag", "")
                    st_del = "".join(f'<span class="need-pill need-delivered">{esc(n)}</span>' for n in pa.get("theme_needs_delivered", []))
                    st_undel = "".join(f'<span class="need-pill need-undelivered">{esc(n)}</span>' for n in pa.get("theme_needs_undelivered", []))

                    html += f"""            <div class="anchor-st-item">
              <h5>{st_name} <span style="font-size:11px;color:var(--text2);font-weight:400">{st_id_val}</span>
                {f'<span class="quality-flag" style="margin-left:6px">{esc(qf)}</span>' if qf else ''}
              </h5>
              <div style="font-size:11px;color:var(--text2);margin-bottom:6px">&#9875; {feat_slug} &middot; {prod_slug}</div>
              <div class="anchor-needs">{st_del}{st_undel}</div>
            </div>
"""
                html += "          </div>\n        </div>\n"

            # Unmet needs summary
            if all_undelivered_needs:
                html += '        <div style="margin-top:16px;padding:14px 18px;background:rgba(211,47,47,0.04);border:1px solid rgba(211,47,47,0.12);border-radius:var(--radius)">\n'
                html += f'          <div style="font-size:13px;font-weight:600;color:var(--red);margin-bottom:8px">{L["unmet_needs"]}</div>\n'
                html += '          <div class="anchor-needs">\n'
                for need in sorted(all_undelivered_needs):
                    html += f'            <span class="need-pill need-undelivered">{esc(need)}</span>\n'
                html += '          </div>\n        </div>\n'

            html += "      </div>\n"

    html += "    </div>\n"

    # ==================== REPORT TAB ====================
    html += f"""
    <!-- REPORT TAB -->
    <div class="tab-panel" id="panel-report">
"""
    if not data["has_report"] and not claims_list:
        html += f"""      <div class="not-available">
        <h3>{L['not_available']}</h3>
        <p>{L['run_skill']} <code>trend-report</code> {L['to_generate']}</p>
      </div>
"""
    else:
        # Report status
        html += f'      <div class="section reveal" id="sec-report-status">\n'
        html += f'        <div class="section-title">{L["report_status"]}</div>\n'
        html += '        <div class="cards">\n'
        html += f'          <div class="card"><div class="label">Report</div><div class="value">{"&#10003;" if data["has_report"] else "&#10007;"}</div></div>\n'
        html += f'          <div class="card"><div class="label">Claims</div><div class="value">{len(claims_list)}</div></div>\n'
        html += f'          <div class="card"><div class="label">Insight</div><div class="value">{"&#10003;" if data["has_insight"] else "&#10007;"}</div></div>\n'
        html += '        </div>\n      </div>\n'

        # Claims table
        if claims_list:
            html += f"""      <div class="section reveal" id="sec-report-claims">
        <div class="section-title">{L['claims_registry']} ({len(claims_list)})</div>
        <table class="claims-table">
          <thead><tr><th>Statement</th><th>Status</th><th>Source</th></tr></thead>
          <tbody>
"""
            for claim in claims_list[:50]:  # Cap at 50 for performance
                stmt = claim.get("statement", claim.get("claim", ""))
                status_val = claim.get("verification_status", claim.get("status", "unverified"))
                source = claim.get("source_url", claim.get("source", ""))
                status_cls = f"status-{status_val}" if status_val in ("verified", "unverified", "deviated", "resolved") else "status-unverified"
                html += f'            <tr><td>{esc(stmt[:150])}</td><td class="{status_cls}">{esc(status_val)}</td><td style="font-size:11px;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{esc(source[:60])}</td></tr>\n'
            html += "          </tbody>\n        </table>\n      </div>\n"

    html += "    </div>\n"

    # ==================== CATALOG TAB ====================
    html += f"""
    <!-- CATALOG TAB -->
    <div class="tab-panel" id="panel-catalog">
"""
    if not has_catalog:
        html += f"""      <div class="not-available">
        <h3>{L['not_available']}</h3>
        <p>{L['run_skill']} <code>catalog init</code> {L['to_generate']}</p>
      </div>
"""
    else:
        cat = catalog
        html += f'      <div class="section reveal" id="sec-catalog-header">\n'
        html += f'        <div class="section-title">{L["catalog_header"]}</div>\n'
        html += '        <div class="cards">\n'

        # Entity counts from catalog
        cat_stats = cat.get("stats", {})
        for entity_type in ["tips_entities", "solution_templates", "spis", "metrics", "collaterals"]:
            count = cat_stats.get(entity_type, 0) if cat_stats else 0
            label = entity_type.replace("_", " ").title()
            html += f'          <div class="card"><div class="label">{label}</div><div class="value">{count}</div></div>\n'
        html += '        </div>\n      </div>\n'

        # Taxonomy coverage
        taxonomy = cat.get("taxonomy_template", cat.get("taxonomy_coverage", {}))
        if taxonomy:
            html += f'      <div class="section reveal" id="sec-catalog-taxonomy">\n'
            html += f'        <div class="section-title">{L["taxonomy_coverage"]}</div>\n'
            if isinstance(taxonomy, dict):
                for dim_key in sorted(taxonomy.keys()):
                    dim_data = taxonomy[dim_key]
                    if isinstance(dim_data, dict):
                        dim_name = dim_data.get("name", dim_key)
                        categories = dim_data.get("categories", [])
                        mapped = dim_data.get("mapped_count", 0)
                        total_cat = dim_data.get("category_count", len(categories))
                        html += f'        <div style="margin-bottom:12px">\n'
                        html += f'          <div style="font-size:13px;font-weight:600;margin-bottom:4px">{esc(dim_name)} ({mapped}/{total_cat})</div>\n'
                        html += f'          <div class="dist-bar-track"><div class="dist-bar-fill" style="width:{mapped/total_cat*100 if total_cat else 0:.0f}%;background:var(--green)"></div></div>\n'
                        html += '        </div>\n'
            html += '      </div>\n'

    html += """    </div>

  </div><!-- /main-content -->

  <!-- RIGHT PANEL -->
  <div class="right-panel" id="rightPanel">
    <div class="graph-zone" id="graphZone">
      <div class="graph-header">
        <h4>TIPS Graph</h4>
        <div class="graph-controls">
          <button class="graph-filter active" data-type="trend" onclick="toggleGraphFilter('trend')">T</button>
          <button class="graph-filter active" data-type="implication" onclick="toggleGraphFilter('implication')">I</button>
          <button class="graph-filter active" data-type="possibility" onclick="toggleGraphFilter('possibility')">P</button>
          <button class="graph-filter active" data-type="solution" onclick="toggleGraphFilter('solution')">S</button>
        </div>
      </div>
      <div id="graph-container"></div>
    </div>
    <div class="resize-handle" id="resizeHandle"></div>
    <div class="detail-zone" id="detailZone">
"""
    html += f'      <div class="empty-state" id="detailEmpty">{L["click_node"]}</div>\n'
    html += """      <div id="detailContent" style="display:none"></div>
    </div>
  </div>

</div><!-- /layout -->

<script>
// ============ DATA ============
"""
    html += f"var CANDIDATES = {candidates_json};\n"
    html += f"var THEMES = {themes_json};\n"
    html += f"var ALL_STS = {all_sts_json};\n"
    html += f"var CLAIMS = {claims_json};\n"
    html += f"var GRAPH_DATA = {graph_json};\n"
    html += f"var DIMENSIONS = {dimensions_json};\n"
    html += f"var HORIZONS = {horizons_json};\n"
    html += f"var DIM_COLORS = {json.dumps(DIMENSION_COLORS)};\n"
    html += f"var TIPS_COLORS = {json.dumps(TIPS_COLORS)};\n"

    html += """
// ============ TAB ROUTING ============
var tabs = document.querySelectorAll('.navbar-tab');
var panels = document.querySelectorAll('.tab-panel');

tabs.forEach(function(tab) {
  tab.addEventListener('click', function() {
    if (tab.classList.contains('disabled')) return;
    tabs.forEach(function(t) { t.classList.remove('active'); });
    panels.forEach(function(p) { p.classList.remove('active'); });
    tab.classList.add('active');
    var target = tab.dataset.tab;
    document.getElementById('panel-' + target).classList.add('active');
    updateLeftPanel(target);
    window.location.hash = target;
  });
});

// Hash routing
function routeFromHash() {
  var hash = window.location.hash.replace('#', '');
  if (hash) {
    var tab = document.querySelector('.navbar-tab[data-tab="' + hash + '"]');
    if (tab && !tab.classList.contains('disabled')) tab.click();
  }
}
window.addEventListener('hashchange', routeFromHash);
if (window.location.hash) routeFromHash();

// ============ LEFT PANEL ============
function updateLeftPanel(tabId) {
  var lp = document.getElementById('leftPanel');
  var html = '';

  if (tabId === 'overview') {
    html += '<div class="section-group">';
    html += '<div class="section-label">Sections</div>';
    ['phase', 'scoring', 'trends', 'heatmap', 'sources'].forEach(function(s) {
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-overview-' + s + '\\')">' +
              s.charAt(0).toUpperCase() + s.slice(1) + '</button>';
    });
    html += '</div>';
  } else if (tabId === 'scout') {
    html += '<div class="section-group">';
    html += '<div class="section-label">Dimensions</div>';
    DIMENSIONS.forEach(function(d, i) {
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-scout-dim-' + i + '\\')">' +
              '<span class="dim-dot" style="background:' + DIM_COLORS[i] + '"></span>' + d + '</button>';
    });
    html += '</div>';
  } else if (tabId === 'model') {
    html += '<div class="section-group">';
    html += '<div class="section-label">Themes</div>';
    THEMES.forEach(function(t, i) {
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-model-theme-' + i + '\\')">' +
              (t.name || 'Theme ' + (i+1)) + '</button>';
    });
    if (ALL_STS.length > 0) {
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-model-ranking\\')">Ranking</button>';
    }
    if (ALL_STS.some(function(st){{ return st.generation_mode === 'portfolio-anchored' || st.generation_mode === 're-anchored'; }})) {{
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-model-anchor\\')">{L["anchor_coverage"]}</button>';
    }}
    html += '</div>';
  } else if (tabId === 'report') {
    html += '<div class="section-group">';
    html += '<div class="section-label">Sections</div>';
    html += '<button class="section-item" onclick="scrollToSection(\\'sec-report-status\\')">Status</button>';
    if (CLAIMS.length > 0) {
      html += '<button class="section-item" onclick="scrollToSection(\\'sec-report-claims\\')">Claims</button>';
    }
    html += '</div>';
  } else if (tabId === 'catalog') {
    html += '<div class="section-group">';
    html += '<div class="section-label">Sections</div>';
    html += '<button class="section-item" onclick="scrollToSection(\\'sec-catalog-header\\')">Overview</button>';
    html += '<button class="section-item" onclick="scrollToSection(\\'sec-catalog-taxonomy\\')">Taxonomy</button>';
    html += '</div>';
  }

  lp.innerHTML = html;
}

function scrollToSection(id) {
  var el = document.getElementById(id);
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    // Update active state
    document.querySelectorAll('.section-item').forEach(function(si) { si.classList.remove('active'); });
    event.target.classList.add('active');
  }
}

// Initialize left panel
updateLeftPanel('overview');

// ============ ENTITY DETAIL ============
function showEntityDetail(node) {
  var empty = document.getElementById('detailEmpty');
  var content = document.getElementById('detailContent');
  empty.style.display = 'none';
  content.style.display = 'block';

  var html = '<div class="detail-card">';
  html += '<span class="type-badge ' + (node.type || '') + '">' + esc(node.type || '') + '</span>';
  html += '<h3>' + esc(node.name || '') + '</h3>';
  if (node.statement) html += '<div class="statement">' + esc(node.statement) + '</div>';

  html += '<div class="meta-row">';
  if (node.score) html += '<div class="meta-item"><span class="meta-label">Score:</span> ' + node.score.toFixed(1) + '</div>';
  if (node.br_score) html += '<div class="meta-item"><span class="meta-label">BR:</span> ' + node.br_score.toFixed(1) + '</div>';
  if (node.ranking_value) html += '<div class="meta-item"><span class="meta-label">Rank:</span> ' + node.ranking_value.toFixed(2) + '</div>';
  if (node.confidence) html += '<div class="meta-item"><span class="meta-label">Confidence:</span> ' + node.confidence + '</div>';
  if (node.horizon) html += '<div class="meta-item"><span class="meta-label">Horizon:</span> ' + node.horizon + '</div>';
  if (node.dimension) html += '<div class="meta-item"><span class="meta-label">Dimension:</span> ' + node.dimension + '</div>';
  if (node.theme) html += '<div class="meta-item"><span class="meta-label">Theme:</span> ' + node.theme + '</div>';
  if (node.category) html += '<div class="meta-item"><span class="meta-label">Category:</span> ' + node.category + '</div>';
  if (node.enabler_type) html += '<div class="meta-item"><span class="meta-label">Type:</span> ' + node.enabler_type + '</div>';
  if (node.indicator_type) html += '<div class="meta-item"><span class="meta-label">Indicator:</span> ' + node.indicator_type + '</div>';
  if (node.diffusion_stage) html += '<div class="meta-item"><span class="meta-label">Diffusion:</span> ' + node.diffusion_stage + '</div>';
  if (node.source) html += '<div class="meta-item"><span class="meta-label">Source:</span> ' + node.source + '</div>';
  html += '</div>';

  // Portfolio anchor detail for anchored solution nodes
  if (node.type === 'solution' && (node.generation_mode === 'portfolio-anchored' || node.generation_mode === 're-anchored') && node.portfolio_anchor) {{
    var pa = node.portfolio_anchor;
    html += '<div style="margin-top:12px;padding:12px;background:rgba(34,197,94,0.06);border:1px solid rgba(34,197,94,0.15);border-radius:8px">';
    html += '<div style="font-size:11px;font-weight:600;color:var(--tips-solution);margin-bottom:8px">&#9875; {L["portfolio_anchored"]}</div>';
    if (pa.feature_slug) html += '<div class="meta-item"><span class="meta-label">Feature:</span> ' + esc(pa.feature_slug) + '</div>';
    if (pa.product_slug) html += '<div class="meta-item"><span class="meta-label">Product:</span> ' + esc(pa.product_slug) + '</div>';
    if (pa.theme_needs_delivered && pa.theme_needs_delivered.length) {{
      html += '<div style="margin-top:6px">';
      pa.theme_needs_delivered.forEach(function(n) {{ html += '<span class="need-pill need-delivered">' + esc(n) + '</span> '; }});
      html += '</div>';
    }}
    if (pa.theme_needs_undelivered && pa.theme_needs_undelivered.length) {{
      html += '<div style="margin-top:4px">';
      pa.theme_needs_undelivered.forEach(function(n) {{ html += '<span class="need-pill need-undelivered">' + esc(n) + '</span> '; }});
      html += '</div>';
    }}
    if (node.quality_flag) {{
      html += '<div class="quality-flag" style="margin-top:8px">' + esc(node.quality_flag) + '</div>';
    }}
    html += '</div>';
  }}

  html += '</div>';

  content.innerHTML = html;
}

function showCandidate(idx) {
  var c = CANDIDATES[idx];
  if (!c) return;
  // Focus the graph on this candidate (zoom + highlight neighborhood)
  focusGraphNode('candidate-' + idx);
}

function esc(s) {
  if (s == null) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ============ GRAPH ============
var graphFilters = { trend: true, implication: true, possibility: true, solution: true };
var simulation = null;
var graphSvg = null, graphG = null, graphZoom = null;
var graphNodes = [], graphLinks = [], graphNodeGroup = null, graphLinkSel = null;

function toggleGraphFilter(type) {
  graphFilters[type] = !graphFilters[type];
  var btn = document.querySelector('.graph-filter[data-type="' + type + '"]');
  btn.classList.toggle('active', graphFilters[type]);
  updateGraphVisibility();
}

function updateGraphVisibility() {
  if (!simulation) return;
  d3.selectAll('.graph-node').style('display', function(d) {
    return graphFilters[d.type] ? null : 'none';
  });
  d3.selectAll('.graph-link').style('display', function(d) {
    var s = typeof d.source === 'object' ? d.source : GRAPH_DATA.nodes.find(function(n){return n.id===d.source;});
    var t = typeof d.target === 'object' ? d.target : GRAPH_DATA.nodes.find(function(n){return n.id===d.target;});
    return (s && graphFilters[s.type] && t && graphFilters[t.type]) ? null : 'none';
  });
}

function highlightGraphNode(nodeId) {
  d3.selectAll('.graph-node').each(function(d) {
    var circle = d3.select(this).select('circle');
    if (d.id === nodeId) {
      circle.attr('stroke', '#fff').attr('stroke-width', 3);
    } else {
      circle.attr('stroke', 'var(--bg)').attr('stroke-width', 1.5);
    }
  });
}

// Focus the graph on a specific node: zoom + pan to center it,
// highlight its TIPS neighborhood (all connected nodes up to 2 hops),
// and show its detail.
function focusGraphNode(nodeId) {
  if (!graphSvg || !graphG || !graphZoom || !graphNodeGroup) return;

  // Find the node data object (with current x,y from simulation)
  var target = null;
  graphNodes.forEach(function(n) { if (n.id === nodeId) target = n; });
  if (!target) return;
  // If simulation hasn't placed the node yet, just show detail without zoom
  if (target.x == null) {
    showEntityDetail(target);
    highlightGraphNode(nodeId);
    return;
  }

  // Collect neighborhood: all nodes reachable within 2 hops
  var neighborhood = new Set();
  neighborhood.add(nodeId);
  // 2-hop BFS
  for (var hop = 0; hop < 2; hop++) {
    var frontier = new Set(neighborhood);
    graphLinks.forEach(function(l) {
      var sId = typeof l.source === 'object' ? l.source.id : l.source;
      var tId = typeof l.target === 'object' ? l.target.id : l.target;
      if (frontier.has(sId)) neighborhood.add(tId);
      if (frontier.has(tId)) neighborhood.add(sId);
    });
  }

  // Compute bounding box of the neighborhood
  var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  graphNodes.forEach(function(n) {
    if (neighborhood.has(n.id) && n.x != null) {
      minX = Math.min(minX, n.x);
      maxX = Math.max(maxX, n.x);
      minY = Math.min(minY, n.y);
      maxY = Math.max(maxY, n.y);
    }
  });

  // Add padding
  var pad = 60;
  minX -= pad; maxX += pad; minY -= pad; maxY += pad;
  var bw = maxX - minX;
  var bh = maxY - minY;

  var container = document.getElementById('graph-container');
  var cw = container.clientWidth || 360;
  var ch = container.clientHeight || 300;

  // Compute zoom scale to fit the neighborhood bbox, capped at 2.5x
  var scale = Math.min(cw / bw, ch / bh, 2.5);
  scale = Math.max(scale, 0.3);

  var cx = (minX + maxX) / 2;
  var cy = (minY + maxY) / 2;
  var tx = cw / 2 - cx * scale;
  var ty = ch / 2 - cy * scale;

  // Animate the zoom transition
  graphSvg.transition().duration(750).ease(d3.easeCubicInOut)
    .call(graphZoom.transform, d3.zoomIdentity.translate(tx, ty).scale(scale));

  // Visual: highlight neighborhood, fade the rest
  graphNodeGroup.transition().duration(400)
    .style('opacity', function(n) { return neighborhood.has(n.id) ? 1 : 0.08; });
  graphLinkSel.transition().duration(400)
    .attr('stroke-opacity', function(l) {
      var sId = typeof l.source === 'object' ? l.source.id : l.source;
      var tId = typeof l.target === 'object' ? l.target.id : l.target;
      return (neighborhood.has(sId) && neighborhood.has(tId)) ? 0.7 : 0.03;
    })
    .attr('stroke-width', function(l) {
      var sId = typeof l.source === 'object' ? l.source.id : l.source;
      var tId = typeof l.target === 'object' ? l.target.id : l.target;
      return (neighborhood.has(sId) && neighborhood.has(tId)) ? 2 : 0.5;
    });

  // Highlight the target node
  highlightGraphNode(nodeId);

  // Show detail
  showEntityDetail(target);

  // Auto-reset fade after 8 seconds if user doesn't interact
  clearTimeout(window._graphFocusTimer);
  window._graphFocusTimer = setTimeout(function() {
    graphNodeGroup.transition().duration(600).style('opacity', 1);
    graphLinkSel.transition().duration(600).attr('stroke-opacity', 0.3).attr('stroke-width', 1);
  }, 8000);
}

function initGraph() {
  var container = document.getElementById('graph-container');
  if (!container || !window.d3 || GRAPH_DATA.nodes.length === 0) return;

  var rect = container.getBoundingClientRect();
  var w = rect.width || 360;
  var h = rect.height || 300;

  var svg = d3.select('#graph-container').append('svg')
    .attr('width', w).attr('height', h);
  graphSvg = svg;

  var g = svg.append('g');
  graphG = g;

  // Zoom
  var zoom = d3.zoom().scaleExtent([0.2, 6]).on('zoom', function(event) {
    g.attr('transform', event.transform);
  });
  graphZoom = zoom;
  svg.call(zoom);

  // Build simulation
  var nodes = GRAPH_DATA.nodes.map(function(n) { return Object.assign({}, n); });
  var links = GRAPH_DATA.links.filter(function(l) {
    var sId = typeof l.source === 'object' ? l.source.id : l.source;
    var tId = typeof l.target === 'object' ? l.target.id : l.target;
    return nodes.some(function(n){return n.id===sId;}) && nodes.some(function(n){return n.id===tId;});
  }).map(function(l) { return Object.assign({}, l); });

  graphNodes = nodes;
  graphLinks = links;

  // --- Concentric TIPS layout per theme cluster ---
  // Compute theme cluster centers spread around the canvas
  var themeIds = [];
  var themeMap = {};
  nodes.forEach(function(n) {
    var tid = n.theme_id || n.theme || '__orphan__';
    if (!themeMap[tid]) { themeMap[tid] = []; themeIds.push(tid); }
    themeMap[tid].push(n);
  });

  var numThemes = themeIds.length;
  var themeCenters = {};
  // Arrange theme centers in a circle around canvas center
  var canvasCx = w / 2, canvasCy = h / 2;
  var orbitR = Math.min(w, h) * 0.3;
  if (numThemes === 1) {
    themeCenters[themeIds[0]] = { x: canvasCx, y: canvasCy };
  } else {
    themeIds.forEach(function(tid, i) {
      var angle = (2 * Math.PI * i / numThemes) - Math.PI / 2;
      themeCenters[tid] = { x: canvasCx + orbitR * Math.cos(angle), y: canvasCy + orbitR * Math.sin(angle) };
    });
  }

  // Assign each node its theme center and target radius based on TIPS type
  // T=center, I=ring1, P=ring2, S=ring3
  var tipsRadii = { trend: 0, implication: 70, possibility: 140, solution: 210 };
  nodes.forEach(function(n) {
    var tid = n.theme_id || n.theme || '__orphan__';
    n._clusterCx = themeCenters[tid].x;
    n._clusterCy = themeCenters[tid].y;
    n._targetR = tipsRadii[n.type] || 100;
  });

  // Custom force: pull nodes toward their theme center at their target radius
  function forceConcentricTIPS(alpha) {
    nodes.forEach(function(n) {
      var dx = n.x - n._clusterCx;
      var dy = n.y - n._clusterCy;
      var dist = Math.sqrt(dx * dx + dy * dy) || 1;
      var targetR = n._targetR;
      // If node is at center ring (trend), pull toward center
      // Otherwise pull to the correct radial distance
      if (targetR === 0) {
        // Pull toward cluster center
        n.vx += (n._clusterCx - n.x) * alpha * 0.15;
        n.vy += (n._clusterCy - n.y) * alpha * 0.15;
      } else {
        // Pull to target radius from cluster center
        var desiredDist = targetR;
        var ratio = (desiredDist - dist) / dist;
        n.vx += dx * ratio * alpha * 0.08;
        n.vy += dy * ratio * alpha * 0.08;
        // Also gently pull toward cluster center axis to keep clusters together
        n.vx += (n._clusterCx - n.x) * alpha * 0.02;
        n.vy += (n._clusterCy - n.y) * alpha * 0.02;
      }
    });
  }

  simulation = d3.forceSimulation(nodes)
    .force('link', d3.forceLink(links).id(function(d){return d.id;}).distance(60).strength(0.3))
    .force('charge', d3.forceManyBody().strength(-80))
    .force('collision', d3.forceCollide(30))
    .force('concentric', forceConcentricTIPS);

  // Links
  var link = g.selectAll('.graph-link')
    .data(links).enter().append('line')
    .attr('class', 'graph-link')
    .attr('stroke', 'var(--border)')
    .attr('stroke-width', 1)
    .attr('stroke-opacity', 0.4);
  graphLinkSel = link;

  // Nodes — use <g> groups so each node has a circle + text label
  var nodeSize = function(d) {
    var s = d.score || d.br_score || 0.5;
    // Scores may be 0-1 or 0-5; normalise to a reasonable radius
    if (s <= 1) s = s * 5;
    return Math.max(5, Math.min(s * 2.5, 16));
  };
  var nodeColor = function(d) { return TIPS_COLORS[d.type] || '#999'; };

  // Truncate long names for the label
  var labelText = function(d) {
    var n = d.name || '';
    return n.length > 22 ? n.substring(0, 20) + '…' : n;
  };

  var nodeGroup = g.selectAll('.graph-node')
    .data(nodes).enter().append('g')
    .attr('class', 'graph-node')
    .attr('cursor', 'pointer');
  graphNodeGroup = nodeGroup;

  nodeGroup
    .on('click', function(event, d) {
      showEntityDetail(d);
      highlightGraphNode(d.id);
    })
    .on('mouseover', function(event, d) {
      d3.select(this).select('circle').attr('r', nodeSize(d) + 3);
      d3.select(this).select('.node-label').style('opacity', 1).style('font-weight', '600');
      // Highlight connected edges
      link.attr('stroke-opacity', function(l) {
        var sId = typeof l.source === 'object' ? l.source.id : l.source;
        var tId = typeof l.target === 'object' ? l.target.id : l.target;
        return (sId === d.id || tId === d.id) ? 0.8 : 0.08;
      }).attr('stroke-width', function(l) {
        var sId = typeof l.source === 'object' ? l.source.id : l.source;
        var tId = typeof l.target === 'object' ? l.target.id : l.target;
        return (sId === d.id || tId === d.id) ? 2 : 0.5;
      });
      // Fade unconnected nodes
      var connected = new Set();
      connected.add(d.id);
      links.forEach(function(l) {
        var sId = typeof l.source === 'object' ? l.source.id : l.source;
        var tId = typeof l.target === 'object' ? l.target.id : l.target;
        if (sId === d.id) connected.add(tId);
        if (tId === d.id) connected.add(sId);
      });
      nodeGroup.style('opacity', function(n) { return connected.has(n.id) ? 1 : 0.15; });
    })
    .on('mouseout', function(event, d) {
      d3.select(this).select('circle').attr('r', nodeSize(d));
      d3.select(this).select('.node-label').style('opacity', 0.85).style('font-weight', '400');
      link.attr('stroke-opacity', 0.3).attr('stroke-width', 1);
      nodeGroup.style('opacity', 1);
    })
    .call(d3.drag()
      .on('start', function(event, d) { if (!event.active) simulation.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; })
      .on('drag', function(event, d) { d.fx = event.x; d.fy = event.y; })
      .on('end', function(event, d) { if (!event.active) simulation.alphaTarget(0); d.fx = null; d.fy = null; })
    );

  // Circle
  nodeGroup.append('circle')
    .attr('r', nodeSize)
    .attr('fill', nodeColor)
    .attr('stroke', 'var(--bg)')
    .attr('stroke-width', 1.5);

  // Anchor overlay for portfolio-anchored solution nodes
  nodeGroup.filter(function(d) {{ return d.type === 'solution' && (d.generation_mode === 'portfolio-anchored' || d.generation_mode === 're-anchored'); }})
    .append('text')
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'central')
    .attr('font-size', function(d) {{ return Math.max(8, nodeSize(d)); }})
    .text('\u2693')
    .style('pointer-events', 'none')
    .style('fill', 'white')
    .style('opacity', 0.9);

  // Text label — positioned to the right of the circle
  nodeGroup.append('text')
    .attr('class', 'node-label')
    .attr('dx', function(d) { return nodeSize(d) + 4; })
    .attr('dy', '0.35em')
    .text(labelText)
    .style('font-family', 'var(--font-body)')
    .style('font-size', '10px')
    .style('fill', 'var(--text)')
    .style('opacity', 0.85)
    .style('pointer-events', 'none')
    .style('user-select', 'none');

  simulation.on('tick', function() {
    link.attr('x1', function(d){return d.source.x;})
        .attr('y1', function(d){return d.source.y;})
        .attr('x2', function(d){return d.target.x;})
        .attr('y2', function(d){return d.target.y;});
    nodeGroup.attr('transform', function(d) { return 'translate(' + d.x + ',' + d.y + ')'; });
  });
}

// Load D3 from CDN
(function() {
  var script = document.createElement('script');
  script.src = 'https://d3js.org/d3.v7.min.js';
  script.onload = function() { initGraph(); };
  document.head.appendChild(script);
})();

// ============ RESIZE HANDLE ============
(function() {
  var handle = document.getElementById('resizeHandle');
  var graphZone = document.getElementById('graphZone');
  var detailZone = document.getElementById('detailZone');
  if (!handle || !graphZone || !detailZone) return;

  var startY, startGraphH;
  handle.addEventListener('mousedown', function(e) {
    startY = e.clientY;
    startGraphH = graphZone.offsetHeight;
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
    e.preventDefault();
  });
  function onMove(e) {
    var dy = e.clientY - startY;
    graphZone.style.flex = 'none';
    graphZone.style.height = Math.max(150, startGraphH + dy) + 'px';
  }
  function onUp() {
    document.removeEventListener('mousemove', onMove);
    document.removeEventListener('mouseup', onUp);
  }
})();

// ============ REVEAL ANIMATIONS ============
(function() {
  var observer = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
  document.querySelectorAll('.reveal').forEach(function(el) { observer.observe(el); });
})();

// ============ SCROLL SPY for left panel ============
(function() {
  var mainContent = document.getElementById('mainContent');
  if (!mainContent) return;
  mainContent.addEventListener('scroll', function() {
    var sections = mainContent.querySelectorAll('[id^="sec-"]');
    var active = null;
    sections.forEach(function(s) {
      var rect = s.getBoundingClientRect();
      var mainRect = mainContent.getBoundingClientRect();
      if (rect.top - mainRect.top < 100) active = s.id;
    });
    if (active) {
      document.querySelectorAll('.section-item').forEach(function(si) {
        si.classList.toggle('active', si.getAttribute('onclick') &&
          si.getAttribute('onclick').indexOf(active) >= 0);
      });
    }
  }, { passive: true });
})();
</script>

</body>
</html>"""
    return html


def main():
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
    if not os.path.isfile(os.path.join(project_dir, "tips-project.json")):
        print(json.dumps({"error": f"Not a cogni-tips project (missing tips-project.json): {project_dir}"}))
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

    data = load_tips_data(project_dir)
    status = get_status(project_dir)
    html = generate_html(data, status, project_dir, theme)

    output_dir = os.path.join(project_dir, "output")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "tips-dashboard.html")

    with open(output_path, "w") as f:
        f.write(html)

    result = {"status": "ok", "path": output_path, "theme": theme["name"]}
    if design_variables_path:
        result["design_variables"] = os.path.abspath(design_variables_path)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
