#!/usr/bin/env python3
"""Generate a self-contained HTML dashboard for the cogni-workspace.

Visualizes installed plugins, themes, MCP servers, market coverage, hooks, and a
health snapshot. Complementary to `workspace-status` (text-based diagnostics) —
this is the visual configuration view.

Usage:
  python3 generate-dashboard.py <workspace-root> \\
      [--design-variables <path.json>] [--theme <path-to-theme.md>] \\
      [--output <path.html>]

Output (default): <workspace-root>/workspace-dashboard.html
Returns JSON: {"status": "ok", "path": "<output-path>", "theme": "<name>",
               "design_variables": "<path-or-null>", "mode": "workspace|monorepo-dev"}
                or {"status": "error", "error": "..."}
"""

import argparse
import glob
import html
import importlib.util
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Shared theme-value guard (cogni-workspace/scripts/sanitize-theme.py)
# ---------------------------------------------------------------------------
# Load the shared guard by path — it lives at the plugin root, a sibling of this
# skill's scripts dir. Theming is a nicety, never a hard dependency, so a load
# failure degrades to no guard (values pass through) rather than crashing the
# render; the guard's own home plugin always ships it, so this is a defensive
# floor for a corrupted install, not the expected path.
def _load_theme_guard():
    guard_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "..", "..", "scripts", "sanitize-theme.py",
    )
    try:
        spec = importlib.util.spec_from_file_location("cogni_sanitize_theme", guard_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    except (OSError, ImportError, AttributeError):
        return None


_THEME_GUARD = _load_theme_guard()


# ---------------------------------------------------------------------------
# Defaults & constants
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

MARKET_PLUGINS = [
    ("cogni-research", "cogni-research/references/market-sources.json"),
    ("cogni-trends", "cogni-trends/skills/trend-research/references/region-authority-sources.json"),
]


# ---------------------------------------------------------------------------
# Theme handling
# ---------------------------------------------------------------------------

def load_design_variables(dv_path):
    """Load a design-variables JSON file. Returns dict or None on failure."""
    if not dv_path or not os.path.isfile(dv_path):
        return None
    try:
        with open(dv_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def parse_theme_md(theme_path):
    """Parse a cogni-workspace theme.md into a design tokens dict.

    Theme files follow the pattern:
      - **Token Name**: `#HEX` - description
      - **Headers**: Font Name Bold / fallback: ...
    """
    if not theme_path or not os.path.isfile(theme_path):
        return None

    with open(theme_path) as f:
        content = f.read()

    theme = json.loads(json.dumps(DEFAULT_THEME))  # deep copy

    m = re.search(r"^#\s+(.+)", content, re.MULTILINE)
    if m:
        theme["name"] = m.group(1).strip()

    color_map = {
        "primary": "primary",
        "secondary": "secondary",
        "accent": "accent",
        "accent muted": "accent_muted",
        "accent dark": "accent_dark",
        "background": "background",
        "surface": "surface",
        "surface 2": "surface2",
        "surface dark": "surface_dark",
        "text": "text",
        "text light": "text_light",
        "text muted": "text_muted",
        "border": "border",
    }
    status_map = {"success": "success", "warning": "warning", "danger": "danger", "info": "info"}

    for m in re.finditer(r"-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`", content):
        name = m.group(1).strip().lower()
        hex_val = m.group(2).strip()
        if name in color_map:
            theme["colors"][color_map[name]] = hex_val
        elif name in status_map:
            theme["status"][status_map[name]] = hex_val
    return theme


def merge_tokens(design_variables, parsed_theme):
    """Pick the strongest available token source. Order: design-vars > theme.md > default.

    Returns ``(theme, warnings)``. When design-variables supply ``colors`` /
    ``status`` overrides, each value is vetted by the shared theme-value guard
    (``cogni-workspace/scripts/sanitize-theme.py``) before it can reach the
    ``<style>`` block: a value carrying stylesheet or markup breakout characters
    is dropped and the built-in palette value is kept for that key, with the
    rejection surfaced as a warning. Font, shadow, and ``@import`` values are
    left untouched — they legitimately carry ``rgba(...)`` / ``url(...)`` and are
    handled under a separate, deferred font-aware policy. If the guard fails to
    load, override values pass through unguarded (theming is never a hard
    dependency).
    """
    warnings = []
    if design_variables:
        if _THEME_GUARD is not None:
            colors, rejected_colors = _THEME_GUARD.sanitize_values(
                design_variables.get("colors", {}), DEFAULT_THEME["colors"])
            status, rejected_status = _THEME_GUARD.sanitize_values(
                design_variables.get("status", {}), DEFAULT_THEME["status"])
            rejected = rejected_colors + rejected_status
            if rejected:
                warnings.append(
                    "design-variables: ignored unsafe value(s) for %s — using the "
                    "built-in palette for those keys" % ", ".join(rejected))
        else:
            colors = design_variables.get("colors", DEFAULT_THEME["colors"])
            status = design_variables.get("status", DEFAULT_THEME["status"])
        return {
            "name": design_variables.get("theme_name", "custom"),
            "colors": colors,
            "status": status,
            "fonts": design_variables.get("fonts", DEFAULT_THEME["fonts"]),
            "google_fonts_import": design_variables.get("google_fonts_import", ""),
            "radius": design_variables.get("radius", DEFAULT_THEME["radius"]),
            "shadows": design_variables.get("shadows", DEFAULT_THEME["shadows"]),
        }, warnings
    if parsed_theme:
        return parsed_theme, warnings
    return json.loads(json.dumps(DEFAULT_THEME)), warnings


# ---------------------------------------------------------------------------
# Workspace mode + foundation
# ---------------------------------------------------------------------------

def detect_mode(workspace_root):
    """Return ('workspace', config_dict) or ('monorepo-dev', None) or ('unknown', None)."""
    config_path = os.path.join(workspace_root, ".workspace-config.json")
    if os.path.isfile(config_path):
        try:
            with open(config_path) as f:
                return ("workspace", json.load(f))
        except (json.JSONDecodeError, OSError):
            return ("workspace", {})
    if os.path.isfile(os.path.join(workspace_root, ".claude-plugin", "marketplace.json")):
        return ("monorepo-dev", None)
    return ("unknown", None)


def foundation_files(workspace_root):
    """Return list of (filename, exists, is_dir, required) tuples."""
    files = [
        (".workspace-config.json", False, True),
        (".claude/settings.local.json", False, True),
        (".workspace-env.sh", False, False),
        (".claude/output-styles", True, False),
    ]
    out = []
    for rel, is_dir, required in files:
        path = os.path.join(workspace_root, rel)
        exists = os.path.isdir(path) if is_dir else os.path.isfile(path)
        out.append({"file": rel, "exists": exists, "required": required})
    return out


# ---------------------------------------------------------------------------
# Plugins
# ---------------------------------------------------------------------------

def derive_maturity(version, archived):
    if archived:
        return ("Archived", "archived")
    if not version or version == "unknown":
        return ("Unknown", "unknown")
    parts = version.lstrip("v").split(".")
    try:
        major = int(parts[0])
        minor = int(parts[1]) if len(parts) > 1 else 0
    except (ValueError, IndexError):
        return ("Unknown", "unknown")
    if major == 0 and minor == 0:
        return ("Incubating", "incubating")
    if major == 0:
        return ("Preview", "preview")
    if major == 1:
        return ("Released", "released")
    return ("Established", "established")


def derive_env_vars(name):
    if not name:
        return ("", "")
    if name.startswith("cogni-"):
        suffix = name.replace("cogni-", "").upper().replace("-", "_")
        return (f"COGNI_{suffix}_ROOT", f"COGNI_{suffix}_PLUGIN")
    suffix = name.upper().replace("-", "_")
    return (f"PLUGIN_{suffix}_ROOT", f"PLUGIN_{suffix}_PLUGIN")


def discover_plugins(workspace_root, mode):
    """Return a list of plugin dicts. Tries discover-plugins.sh, falls back to glob."""
    # Try the canonical script first when available
    script_paths = [
        os.path.join(workspace_root, "cogni-workspace", "scripts", "discover-plugins.sh"),
    ]
    for sp in script_paths:
        if os.path.isfile(sp):
            try:
                env = os.environ.copy()
                # Point CLAUDE_PLUGIN_ROOT at the workspace root so the script
                # globs inside the monorepo, not the user's plugin cache
                env["CLAUDE_PLUGIN_ROOT"] = workspace_root
                proc = subprocess.run(
                    ["bash", sp], capture_output=True, text=True,
                    timeout=15, env=env,
                )
                if proc.returncode == 0 and proc.stdout.strip():
                    payload = json.loads(proc.stdout)
                    if payload.get("success") and payload.get("data", {}).get("plugins"):
                        return _enrich_plugins(payload["data"]["plugins"], workspace_root)
            except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
                pass

    # Fallback: glob plugin.json files directly
    plugins = []
    for manifest in sorted(glob.glob(os.path.join(workspace_root, "*", ".claude-plugin", "plugin.json"))):
        try:
            with open(manifest) as f:
                m = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        name = m.get("name", "")
        plugin_dir = os.path.dirname(os.path.dirname(manifest))
        root_var, plugin_var = derive_env_vars(name)
        plugins.append({
            "name": name,
            "version": m.get("version", "unknown"),
            "description": m.get("description", ""),
            "path": plugin_dir,
            "root_var": root_var,
            "plugin_var": plugin_var,
            "archived": bool(m.get("archived", False)),
            "keywords": m.get("keywords", []),
        })
    return plugins


def _enrich_plugins(plugin_list, workspace_root):
    """Add `archived` and `keywords` from each plugin's plugin.json."""
    out = []
    for p in plugin_list:
        manifest = os.path.join(p.get("path", ""), ".claude-plugin", "plugin.json")
        archived = False
        keywords = []
        if os.path.isfile(manifest):
            try:
                with open(manifest) as f:
                    m = json.load(f)
                archived = bool(m.get("archived", False))
                keywords = m.get("keywords", [])
            except (json.JSONDecodeError, OSError):
                pass
        enriched = dict(p)
        enriched["archived"] = archived
        enriched["keywords"] = keywords
        out.append(enriched)
    return out


def count_plugin_components(plugin_path):
    """Return counts of skills, agents, scripts, hooks for a plugin."""
    counts = {"skills": 0, "agents": 0, "scripts": 0, "hooks": 0}
    if not plugin_path or not os.path.isdir(plugin_path):
        return counts
    counts["skills"] = len(glob.glob(os.path.join(plugin_path, "skills", "*", "SKILL.md")))
    counts["agents"] = len(glob.glob(os.path.join(plugin_path, "agents", "*.md")))
    counts["scripts"] = sum(
        1 for p in glob.glob(os.path.join(plugin_path, "scripts", "*"))
        if os.path.isfile(p)
    )
    hooks_json = os.path.join(plugin_path, "hooks", "hooks.json")
    if os.path.isfile(hooks_json):
        try:
            with open(hooks_json) as f:
                data = json.load(f).get("hooks", {})
            counts["hooks"] = sum(
                len(matcher.get("hooks", []))
                for event_list in data.values() for matcher in event_list
            )
        except (json.JSONDecodeError, OSError):
            counts["hooks"] = 0
    return counts


# ---------------------------------------------------------------------------
# Themes gallery
# ---------------------------------------------------------------------------

def discover_themes(workspace_root):
    """Return list of theme dicts (name, slug, path, source, swatches, font, tier)."""
    themes = []
    seen_slugs = set()

    # Bundled themes (monorepo dev mode) and standard themes (workspace mode)
    bundled_dir = os.path.join(workspace_root, "cogni-workspace", "themes")
    workspace_dir = os.path.join(workspace_root, "themes")

    for source, base in [("workspace", workspace_dir), ("standard", bundled_dir)]:
        if not os.path.isdir(base):
            continue
        for entry in sorted(os.listdir(base)):
            if entry.startswith("_"):
                continue
            theme_md = os.path.join(base, entry, "theme.md")
            if not os.path.isfile(theme_md):
                continue
            if entry in seen_slugs:
                continue  # workspace wins over standard
            seen_slugs.add(entry)
            themes.append(_parse_theme_card(theme_md, entry, source))
    return themes


def _parse_theme_card(theme_md_path, slug, source):
    """Pull display-relevant tokens for a theme gallery card."""
    card = {
        "slug": slug,
        "name": slug,
        "path": theme_md_path,
        "source": source,
        "swatches": {},
        "font": "",
        "tier": "tier-0",
        "description": "",
    }
    try:
        with open(theme_md_path) as f:
            content = f.read()
    except OSError:
        return card

    m = re.search(r"^#\s+(.+)", content, re.MULTILINE)
    if m:
        card["name"] = m.group(1).strip()

    # First non-heading paragraph as description
    paragraphs = [p.strip() for p in re.split(r"\n\n+", content) if p.strip()]
    for p in paragraphs[1:]:
        if not p.startswith("#") and not p.startswith("-") and not p.startswith("|"):
            card["description"] = p[:200] + ("…" if len(p) > 200 else "")
            break

    swatch_keys = ["primary", "secondary", "accent", "background", "surface"]
    for m in re.finditer(r"-\s+\*\*([^*]+)\*\*:\s*`(#[0-9A-Fa-f]{3,8})`", content):
        name = m.group(1).strip().lower()
        if name in swatch_keys:
            card["swatches"][name] = m.group(2).strip()

    m = re.search(r"-\s+\*\*Headers\*\*:\s*([^/\n]+)", content)
    if m:
        card["font"] = m.group(1).strip()

    manifest_json = os.path.join(os.path.dirname(theme_md_path), "manifest.json")
    if os.path.isfile(manifest_json):
        card["tier"] = "tiered"
    return card


# ---------------------------------------------------------------------------
# MCP servers
# ---------------------------------------------------------------------------

def load_mcp_registry(workspace_root):
    path = os.path.join(workspace_root, "cogni-workspace", "references", "mcp-git-registry.json")
    if not os.path.isfile(path):
        return None
    try:
        with open(path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def mcp_install_status(server):
    """Heuristic: check whether the MCP appears installed locally."""
    server_type = server.get("type", "")
    desktop_key = server.get("desktop_config_key", "")
    if server_type == "git":
        candidate = os.path.expanduser(f"~/.claude/mcp-servers/{desktop_key}/start.sh")
        return ("installed" if os.path.isfile(candidate) else "missing", candidate)
    if server_type == "native":
        platforms = server.get("platforms", {})
        plat = platforms.get(sys.platform) or platforms.get("darwin") or {}
        cmd = plat.get("command", "")
        if cmd and (os.path.isfile(cmd) or _command_on_path(cmd)):
            return ("installed", cmd)
        return ("manual", cmd)
    return ("unknown", "")


def _command_on_path(cmd):
    if "/" in cmd:
        return False
    for p in os.environ.get("PATH", "").split(os.pathsep):
        if os.path.isfile(os.path.join(p, cmd)):
            return True
    return False


# ---------------------------------------------------------------------------
# Markets matrix
# ---------------------------------------------------------------------------

def load_market_matrix(workspace_root):
    """Return (markets_meta_dict, plugin_market_sets, plugin_files_found)."""
    registry_path = os.path.join(
        workspace_root, "cogni-workspace", "references", "supported-markets-registry.json")
    markets_meta = {}
    if os.path.isfile(registry_path):
        try:
            with open(registry_path) as f:
                reg = json.load(f)
            markets_meta = reg.get("markets", {})
        except (json.JSONDecodeError, OSError):
            markets_meta = {}

    plugin_sets = {}
    plugin_files = {}
    for plugin_name, rel in MARKET_PLUGINS:
        full = os.path.join(workspace_root, rel)
        plugin_files[plugin_name] = os.path.isfile(full)
        if not os.path.isfile(full):
            plugin_sets[plugin_name] = set()
            continue
        try:
            with open(full) as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            plugin_sets[plugin_name] = set()
            continue
        # The catalogs use different shapes; collect any top-level keys that look
        # like market codes (lowercase 2–6 chars), or fall back to a 'markets' / 'regions' map.
        codes = set()
        for cand_key in ("markets", "regions"):
            if isinstance(data.get(cand_key), dict):
                codes.update(data[cand_key].keys())
        if not codes:
            for k, v in data.items():
                if isinstance(v, dict) and re.match(r"^[a-z][a-z0-9_-]{1,8}$", k):
                    codes.add(k)
        plugin_sets[plugin_name] = {c.lower() for c in codes}
    return markets_meta, plugin_sets, plugin_files


# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------

def load_hooks(workspace_root):
    """Return list of {plugin, event, matcher, command, timeout} rows."""
    rows = []
    for hooks_path in sorted(glob.glob(os.path.join(workspace_root, "*", "hooks", "hooks.json"))):
        plugin = os.path.basename(os.path.dirname(os.path.dirname(hooks_path)))
        try:
            with open(hooks_path) as f:
                data = json.load(f).get("hooks", {})
        except (json.JSONDecodeError, OSError):
            continue
        for event, matchers in data.items():
            for matcher_block in matchers:
                matcher = matcher_block.get("matcher", "*")
                for hook in matcher_block.get("hooks", []):
                    rows.append({
                        "plugin": plugin,
                        "event": event,
                        "matcher": matcher,
                        "command": hook.get("command", ""),
                        "timeout": hook.get("timeout", ""),
                        "type": hook.get("type", "command"),
                    })
    return rows


# ---------------------------------------------------------------------------
# Health snapshot
# ---------------------------------------------------------------------------

def health_snapshot(workspace_root, foundation, plugins, themes, mcp_servers):
    """Build a 6-row snapshot mirroring workspace-status categories."""
    found_required_ok = all(f["exists"] for f in foundation if f["required"])
    foundation_label = (
        "ok" if found_required_ok and all(f["exists"] for f in foundation) else
        ("warning" if found_required_ok else "danger")
    )
    foundation_summary = (
        f"{sum(1 for f in foundation if f['exists'])}/{len(foundation)} files present"
    )

    settings_path = os.path.join(workspace_root, ".claude", "settings.local.json")
    env_count, env_broken = 0, 0
    if os.path.isfile(settings_path):
        try:
            with open(settings_path) as f:
                env = json.load(f).get("env", {})
            env_count = len(env)
            for v in env.values():
                if isinstance(v, str) and v.startswith("/") and not os.path.exists(v):
                    env_broken += 1
        except (json.JSONDecodeError, OSError):
            pass
    env_label = "ok" if env_broken == 0 and env_count > 0 else (
        "warning" if env_count == 0 else "danger")
    env_summary = f"{env_count} vars set, {env_broken} broken"

    plugin_label = "ok" if plugins else "warning"
    plugin_summary = f"{len(plugins)} plugins discovered"

    theme_label = "ok" if themes else "warning"
    theme_summary = f"{len(themes)} themes available"

    deps_label, deps_summary = _check_dependencies(workspace_root)

    mcp_summary = ""
    if mcp_servers is None:
        mcp_label = "warning"
        mcp_summary = "registry not found"
    else:
        installed = sum(1 for s in mcp_servers if s.get("install_status") == "installed")
        total = len(mcp_servers)
        manual = sum(1 for s in mcp_servers if s.get("install_status") == "manual")
        mcp_label = "ok" if installed + manual == total else "warning"
        mcp_summary = f"{installed}/{total} installed" + (f", {manual} manual" if manual else "")

    return [
        {"name": "Foundation", "label": foundation_label, "summary": foundation_summary},
        {"name": "Environment", "label": env_label, "summary": env_summary},
        {"name": "Plugins", "label": plugin_label, "summary": plugin_summary},
        {"name": "Themes", "label": theme_label, "summary": theme_summary},
        {"name": "Dependencies", "label": deps_label, "summary": deps_summary},
        {"name": "MCP Servers", "label": mcp_label, "summary": mcp_summary},
    ]


def _check_dependencies(workspace_root):
    script = os.path.join(workspace_root, "cogni-workspace", "scripts", "check-dependencies.sh")
    if not os.path.isfile(script):
        return ("warning", "check-dependencies.sh unavailable")
    try:
        proc = subprocess.run(["bash", script], capture_output=True, text=True, timeout=10)
        if proc.returncode != 0 or not proc.stdout.strip():
            return ("warning", "check-dependencies.sh failed")
        payload = json.loads(proc.stdout)
        data = payload.get("data", {})
        required = data.get("required", {}) or {}
        optional = data.get("optional", {}) or {}
        req_ok = sum(1 for v in required.values() if v.get("available"))
        req_total = len(required)
        opt_ok = sum(1 for v in optional.values() if v.get("available"))
        opt_total = len(optional)
        label = "ok" if req_ok == req_total else "danger"
        return (label, f"{req_ok}/{req_total} required, {opt_ok}/{opt_total} optional")
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
        return ("warning", "check-dependencies.sh errored")


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

def esc(s):
    return html.escape(str(s) if s is not None else "")


def render_css(theme):
    g = theme.get("google_fonts_import", "") or ""
    return f"""{g}
:root {{
  --primary: {theme['colors']['primary']};
  --secondary: {theme['colors']['secondary']};
  --accent: {theme['colors']['accent']};
  --accent-muted: {theme['colors']['accent_muted']};
  --accent-dark: {theme['colors']['accent_dark']};
  --background: {theme['colors']['background']};
  --surface: {theme['colors']['surface']};
  --surface2: {theme['colors']['surface2']};
  --surface-dark: {theme['colors']['surface_dark']};
  --border: {theme['colors']['border']};
  --text: {theme['colors']['text']};
  --text-light: {theme['colors']['text_light']};
  --text-muted: {theme['colors']['text_muted']};
  --success: {theme['status']['success']};
  --warning: {theme['status']['warning']};
  --danger: {theme['status']['danger']};
  --info: {theme['status']['info']};
  --font-headers: {theme['fonts']['headers']};
  --font-body: {theme['fonts']['body']};
  --font-mono: {theme['fonts']['mono']};
  --radius: {theme.get('radius', '12px')};
  --shadow-sm: {theme['shadows'].get('sm', '0 1px 3px rgba(0,0,0,0.04)')};
  --shadow-md: {theme['shadows'].get('md', '0 4px 16px rgba(0,0,0,0.06)')};
  --shadow-lg: {theme['shadows'].get('lg', '0 12px 40px rgba(0,0,0,0.1)')};
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html, body {{ background: var(--background); color: var(--text); font-family: var(--font-body); line-height: 1.55; -webkit-font-smoothing: antialiased; }}
body {{ padding-bottom: 80px; }}
h1, h2, h3, h4 {{ font-family: var(--font-headers); letter-spacing: -0.01em; }}
h1 {{ font-size: 38px; line-height: 1.1; }}
h2 {{ font-size: 24px; line-height: 1.25; margin-bottom: 18px; }}
h3 {{ font-size: 17px; line-height: 1.35; }}
code, .mono {{ font-family: var(--font-mono); font-size: 0.85em; }}
a {{ color: var(--text); }}
.shell {{ max-width: 1240px; margin: 0 auto; padding: 0 28px; }}
.hero {{ padding: 56px 28px 36px; background: linear-gradient(135deg, var(--surface), var(--background)); border-bottom: 1px solid var(--border); }}
.hero .shell {{ display: grid; grid-template-columns: 1fr auto; gap: 24px; align-items: end; }}
.hero h1 {{ margin-bottom: 6px; }}
.hero .lede {{ color: var(--text-muted); font-size: 16px; }}
.hero .meta {{ display: flex; flex-direction: column; gap: 6px; align-items: flex-end; font-size: 13px; color: var(--text-muted); }}
.hero .meta .pill {{ background: var(--accent); color: var(--primary); padding: 4px 12px; border-radius: 999px; font-weight: 600; font-size: 12px; }}
nav.sticky {{ position: sticky; top: 0; z-index: 50; background: rgba(250, 250, 248, 0.9); backdrop-filter: blur(8px); border-bottom: 1px solid var(--border); padding: 14px 0; }}
nav.sticky .shell {{ display: flex; gap: 6px; flex-wrap: wrap; }}
nav.sticky a {{ font-size: 13px; padding: 6px 14px; border-radius: 999px; text-decoration: none; color: var(--text-muted); border: 1px solid transparent; transition: all 120ms ease; }}
nav.sticky a:hover {{ background: var(--surface); color: var(--text); }}
nav.sticky a.active {{ background: var(--primary); color: var(--text-light); border-color: var(--primary); }}
section {{ padding: 56px 0 8px; }}
section + section {{ border-top: 1px solid var(--border); }}
.card {{ background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; box-shadow: var(--shadow-sm); transition: box-shadow 150ms ease, transform 150ms ease; }}
.card:hover {{ box-shadow: var(--shadow-md); }}
.grid {{ display: grid; gap: 16px; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }}
.grid-3 {{ grid-template-columns: repeat(auto-fill, minmax(360px, 1fr)); }}
.tag {{ display: inline-block; font-size: 11px; padding: 3px 10px; border-radius: 999px; background: var(--surface2); color: var(--text-muted); font-weight: 600; letter-spacing: 0.02em; text-transform: uppercase; }}
.tag.primary {{ background: var(--primary); color: var(--text-light); }}
.tag.accent {{ background: var(--accent); color: var(--primary); }}
.tag.success {{ background: var(--success); color: var(--text-light); }}
.tag.warning {{ background: var(--warning); color: var(--text-light); }}
.tag.danger {{ background: var(--danger); color: var(--text-light); }}
.tag.info {{ background: var(--info); color: var(--text-light); }}
.tag.muted {{ background: var(--surface2); color: var(--text-muted); }}
.tag.outline {{ background: transparent; color: var(--text); border: 1px solid var(--border); }}
.kv {{ display: grid; grid-template-columns: 140px 1fr; gap: 6px 16px; font-size: 14px; }}
.kv dt {{ color: var(--text-muted); }}
.kv dd {{ color: var(--text); word-break: break-all; }}
.checklist {{ display: flex; flex-wrap: wrap; gap: 8px; margin-top: 14px; }}
.checklist .item {{ font-size: 12px; padding: 6px 10px; border-radius: 8px; background: var(--surface2); color: var(--text-muted); display: inline-flex; align-items: center; gap: 8px; }}
.checklist .item .dot {{ width: 8px; height: 8px; border-radius: 999px; background: var(--text-muted); }}
.checklist .item.ok {{ color: var(--text); }}
.checklist .item.ok .dot {{ background: var(--success); }}
.checklist .item.miss {{ color: var(--danger); }}
.checklist .item.miss .dot {{ background: var(--danger); }}
table {{ width: 100%; border-collapse: collapse; font-size: 13px; background: var(--surface); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-sm); }}
th, td {{ padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--border); vertical-align: top; }}
th {{ background: var(--surface2); font-family: var(--font-headers); font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--text-muted); }}
tr:last-child td {{ border-bottom: none; }}
.maturity-incubating {{ background: #d8d8d8; color: #444; }}
.maturity-preview {{ background: var(--info); color: var(--text-light); }}
.maturity-released {{ background: var(--success); color: var(--text-light); }}
.maturity-established {{ background: var(--accent); color: var(--primary); }}
.maturity-archived {{ background: #888; color: var(--text-light); }}
.maturity-unknown {{ background: var(--surface2); color: var(--text-muted); }}
.swatch-row {{ display: flex; gap: 6px; margin: 10px 0 14px; }}
.swatch-row .sw {{ width: 36px; height: 36px; border-radius: 8px; border: 1px solid var(--border); position: relative; }}
.swatch-row .sw::after {{ content: attr(data-label); position: absolute; bottom: -16px; left: 0; right: 0; text-align: center; font-size: 9px; color: var(--text-muted); white-space: nowrap; }}
.health-row {{ display: grid; grid-template-columns: 14px 140px 1fr; gap: 12px; align-items: center; padding: 10px 0; border-bottom: 1px dashed var(--border); }}
.health-row:last-child {{ border-bottom: none; }}
.health-dot {{ width: 12px; height: 12px; border-radius: 999px; }}
.health-dot.ok {{ background: var(--success); }}
.health-dot.warning {{ background: var(--warning); }}
.health-dot.danger {{ background: var(--danger); }}
.matrix {{ width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13px; }}
.matrix th, .matrix td {{ padding: 8px 12px; border-bottom: 1px solid var(--border); }}
.matrix th {{ background: var(--surface2); }}
.matrix td.cell {{ text-align: center; font-weight: 600; }}
.matrix td.cell.on {{ background: rgba(46, 125, 50, 0.12); color: var(--success); }}
.matrix td.cell.off {{ background: var(--surface); color: var(--text-muted); }}
.matrix td.market-name {{ font-weight: 600; }}
.matrix td.tier {{ color: var(--text-muted); font-size: 11px; text-transform: uppercase; }}
.note {{ font-size: 12px; color: var(--text-muted); padding: 12px 16px; background: var(--surface); border-left: 3px solid var(--info); border-radius: 6px; margin: 12px 0; }}
.note.warning {{ border-left-color: var(--warning); }}
footer.foot {{ text-align: center; padding: 36px 28px 16px; color: var(--text-muted); font-size: 12px; border-top: 1px solid var(--border); margin-top: 48px; }}
.section-head {{ display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 18px; }}
.section-head .meta {{ font-size: 13px; color: var(--text-muted); }}
.theme-card .name-row {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }}
.theme-card .desc {{ color: var(--text-muted); font-size: 13px; min-height: 36px; }}
.theme-card .font {{ font-size: 12px; color: var(--text-muted); margin-top: 8px; padding-top: 10px; border-top: 1px solid var(--border); }}
.plugin-card h3 {{ display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 6px; }}
.plugin-card .desc {{ color: var(--text-muted); font-size: 13px; min-height: 50px; }}
.plugin-card .meta {{ font-size: 11px; color: var(--text-muted); margin-top: 12px; padding-top: 10px; border-top: 1px solid var(--border); display: flex; gap: 8px; flex-wrap: wrap; }}
.plugin-card .meta code {{ background: var(--surface2); padding: 2px 6px; border-radius: 4px; }}
.mcp-card .head {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }}
.mcp-card .req {{ display: flex; gap: 6px; flex-wrap: wrap; margin-top: 12px; }}
"""


def render_overview(workspace_root, mode, config, foundation):
    lang = (config or {}).get("language", "en")
    version = (config or {}).get("version", "—")
    created = (config or {}).get("created_at", "—")
    updated = (config or {}).get("updated_at", "—")
    installed = (config or {}).get("installed_plugins", [])
    integrations = (config or {}).get("tool_integrations", []) or []

    mode_pill = "Workspace" if mode == "workspace" else (
        "Monorepo dev" if mode == "monorepo-dev" else "Unknown")
    mode_class = "accent" if mode == "workspace" else (
        "muted" if mode == "monorepo-dev" else "warning")

    foundation_html = "".join(
        f'<span class="item {"ok" if f["exists"] else "miss"}">'
        f'<span class="dot"></span><code>{esc(f["file"])}</code>'
        f'{"" if f["exists"] else " (missing)"}'
        f'</span>'
        for f in foundation
    )

    integ_html = " ".join(
        f'<span class="tag muted">{esc(t)}</span>' for t in integrations
    ) or '<span class="tag muted">none</span>'

    return f"""
<section id="overview">
  <div class="shell">
    <div class="section-head">
      <h2>Workspace Overview</h2>
      <div class="meta"><span class="tag {mode_class}">{mode_pill}</span></div>
    </div>
    <div class="card">
      <dl class="kv">
        <dt>Path</dt><dd><code>{esc(workspace_root)}</code></dd>
        <dt>Language</dt><dd>{esc(lang).upper()}</dd>
        <dt>Workspace version</dt><dd>{esc(version)}</dd>
        <dt>Created</dt><dd>{esc(created)}</dd>
        <dt>Updated</dt><dd>{esc(updated)}</dd>
        <dt>Registered plugins</dt><dd>{len(installed)}</dd>
        <dt>Tool integrations</dt><dd>{integ_html}</dd>
      </dl>
      <div class="checklist">{foundation_html}</div>
    </div>
  </div>
</section>
"""


def render_plugins(plugins):
    if not plugins:
        return _empty_section("plugins", "Installed Plugins", "No plugins discovered.")
    cards = []
    rows = []
    for p in plugins:
        stage_label, stage_class = derive_maturity(p.get("version"), p.get("archived"))
        counts = count_plugin_components(p.get("path", ""))
        cards.append(f"""
<div class="card plugin-card">
  <h3>{esc(p['name'])}<span class="tag maturity-{stage_class}">{esc(stage_label)}</span></h3>
  <div class="desc">{esc(p.get('description', '')[:240] + ('…' if len(p.get('description', '')) > 240 else ''))}</div>
  <div class="meta">
    <span class="tag outline">v{esc(p.get('version', '—'))}</span>
    <span class="tag muted">{counts['skills']} skills</span>
    <span class="tag muted">{counts['agents']} agents</span>
    <span class="tag muted">{counts['scripts']} scripts</span>
    {('<span class="tag muted">' + str(counts['hooks']) + ' hooks</span>') if counts['hooks'] else ''}
    <code>{esc(p.get('root_var', ''))}</code>
  </div>
</div>""")
        rows.append(f"""
<tr>
  <td><strong>{esc(p['name'])}</strong></td>
  <td><code>{esc(p.get('version', '—'))}</code></td>
  <td><span class="tag maturity-{stage_class}">{esc(stage_label)}</span></td>
  <td>{counts['skills']}</td>
  <td>{counts['agents']}</td>
  <td>{counts['scripts']}</td>
  <td>{counts['hooks']}</td>
  <td><code>{esc(p.get('root_var', ''))}</code></td>
</tr>""")
    return f"""
<section id="plugins">
  <div class="shell">
    <div class="section-head">
      <h2>Installed Plugins</h2>
      <div class="meta">{len(plugins)} discovered</div>
    </div>
    <div class="grid grid-3">{"".join(cards)}</div>
    <div style="margin-top: 32px;">
      <table>
        <thead><tr>
          <th>Name</th><th>Version</th><th>Stage</th>
          <th>Skills</th><th>Agents</th><th>Scripts</th><th>Hooks</th><th>Root env var</th>
        </tr></thead>
        <tbody>{"".join(rows)}</tbody>
      </table>
    </div>
  </div>
</section>
"""


def render_themes(themes):
    if not themes:
        return _empty_section("themes", "Themes", "No themes found in this workspace.")
    cards = []
    for t in themes:
        sw = t.get("swatches", {})
        swatches_html = "".join(
            f'<div class="sw" style="background: {esc(sw.get(k, "transparent"))};" data-label="{esc(k)}" title="{esc(k)}: {esc(sw.get(k, "—"))}"></div>'
            for k in ["primary", "secondary", "accent", "surface", "background"]
        )
        cards.append(f"""
<div class="card theme-card">
  <div class="name-row">
    <h3>{esc(t['name'])}</h3>
    <span class="tag {'accent' if t['source'] == 'workspace' else 'outline'}">{esc(t['source'])}</span>
  </div>
  <div class="desc">{esc(t.get('description', ''))}</div>
  <div class="swatch-row">{swatches_html}</div>
  <div style="margin-top: 22px; display: flex; gap: 6px; flex-wrap: wrap;">
    <span class="tag muted">{esc(t.get('tier', 'tier-0'))}</span>
    <span class="tag muted">{esc(t['slug'])}</span>
  </div>
  <div class="font">{esc(t.get('font', '—'))}</div>
</div>""")
    return f"""
<section id="themes">
  <div class="shell">
    <div class="section-head">
      <h2>Themes Gallery</h2>
      <div class="meta">{len(themes)} themes</div>
    </div>
    <div class="grid">{"".join(cards)}</div>
  </div>
</section>
"""


def render_mcp(mcp_servers):
    if mcp_servers is None:
        return _empty_section("mcp", "MCP Servers", "MCP registry not found in this workspace.")
    cards = []
    for s in mcp_servers:
        status = s.get("install_status", "unknown")
        status_class = {"installed": "success", "missing": "danger", "manual": "info"}.get(status, "muted")
        type_class = "primary" if s.get("type") == "git" else "accent"
        required_html = " ".join(
            f'<span class="tag muted">{esc(p)}</span>' for p in s.get("required_by", [])
        ) or '<span class="tag muted">—</span>'
        path = s.get("install_hint", "")
        repo = s.get("repo", "")
        cards.append(f"""
<div class="card mcp-card">
  <div class="head">
    <h3>{esc(s.get('name', '—'))}</h3>
    <div style="display:flex;gap:6px;">
      <span class="tag {type_class}">{esc(s.get('type', '—'))}</span>
      <span class="tag {status_class}">{esc(status)}</span>
    </div>
  </div>
  <div class="desc">{esc(s.get('notes', '')[:160] + ('…' if len(s.get('notes', '')) > 160 else ''))}</div>
  {('<div style="margin-top: 12px;"><code>' + esc(repo) + '</code></div>') if repo else ''}
  {('<div style="margin-top: 6px; font-size: 11px; color: var(--text-muted);"><code>' + esc(path) + '</code></div>') if path else ''}
  <div class="req">{required_html}</div>
</div>""")
    return f"""
<section id="mcp">
  <div class="shell">
    <div class="section-head">
      <h2>MCP Servers</h2>
      <div class="meta">{len(mcp_servers)} servers</div>
    </div>
    <div class="grid grid-3">{"".join(cards)}</div>
  </div>
</section>
"""


def render_markets(markets_meta, plugin_sets, plugin_files):
    if not markets_meta:
        return _empty_section("markets", "Market Coverage", "No market registry found.")
    rows = []
    plugins_in_order = [name for name, _ in MARKET_PLUGINS]
    sorted_markets = sorted(
        markets_meta.items(),
        key=lambda kv: (kv[1].get("tier", "zzz"), kv[0])
    )
    for code, meta in sorted_markets:
        cells = []
        for plugin_name in plugins_in_order:
            present = code.lower() in plugin_sets.get(plugin_name, set())
            cells.append(
                f'<td class="cell {"on" if present else "off"}">{"●" if present else "○"}</td>'
            )
        primary_authorities = meta.get("authority_sources", [])[:4]
        auth_chips = " ".join(f'<span class="tag muted">{esc(a)}</span>' for a in primary_authorities)
        rows.append(f"""
<tr>
  <td class="market-name">{esc(meta.get('name', code))}</td>
  <td class="tier">{esc(meta.get('tier', '—'))}</td>
  {''.join(cells)}
  <td>{auth_chips}</td>
</tr>""")
    missing_files = [name for name in plugins_in_order if not plugin_files.get(name)]
    note = ""
    if missing_files:
        note = f'<div class="note warning">Missing plugin catalogs: {esc(", ".join(missing_files))}</div>'
    plugin_headers = "".join(f"<th>{esc(p)}</th>" for p in plugins_in_order)
    return f"""
<section id="markets">
  <div class="shell">
    <div class="section-head">
      <h2>Market Coverage Matrix</h2>
      <div class="meta">{len(markets_meta)} markets · {len(plugins_in_order)} plugins</div>
    </div>
    {note}
    <div style="overflow-x:auto;">
    <table class="matrix">
      <thead>
        <tr><th>Market</th><th>Tier</th>{plugin_headers}<th>Top authorities</th></tr>
      </thead>
      <tbody>{''.join(rows)}</tbody>
    </table>
    </div>
    <div class="note">Static view of registry vs plugin catalogs. For drift detection run <code>/cogni-workspace:audit-region-sources</code>.</div>
  </div>
</section>
"""


def render_hooks(rows):
    if not rows:
        return _empty_section("hooks", "Cross-Plugin Hooks", "No hooks found.")
    grouped = {}
    for r in rows:
        grouped.setdefault(r["event"], []).append(r)
    blocks = []
    for event in sorted(grouped.keys()):
        body = "".join(
            f"<tr><td><strong>{esc(r['plugin'])}</strong></td><td><code>{esc(r['matcher'])}</code></td>"
            f"<td><code title='{esc(r['command'])}'>{esc(_truncate_cmd(r['command']))}</code></td>"
            f"<td>{esc(r['timeout'])}s</td></tr>"
            for r in grouped[event]
        )
        blocks.append(f"""
<div style="margin-top: 24px;">
  <h3 style="margin-bottom: 12px;">{esc(event)} <span class="tag muted">{len(grouped[event])} {'hook' if len(grouped[event]) == 1 else 'hooks'}</span></h3>
  <table>
    <thead><tr><th>Plugin</th><th>Matcher</th><th>Command</th><th>Timeout</th></tr></thead>
    <tbody>{body}</tbody>
  </table>
</div>""")
    return f"""
<section id="hooks">
  <div class="shell">
    <div class="section-head">
      <h2>Cross-Plugin Hooks</h2>
      <div class="meta">{len(rows)} hooks across {len({r['plugin'] for r in rows})} plugins</div>
    </div>
    {''.join(blocks)}
  </div>
</section>
"""


def _truncate_cmd(cmd, n=72):
    if len(cmd) <= n:
        return cmd
    return "…" + cmd[-(n - 1):]


def render_health(snapshot):
    rows_html = []
    for row in snapshot:
        rows_html.append(f"""
<div class="health-row">
  <div class="health-dot {esc(row['label'])}"></div>
  <div><strong>{esc(row['name'])}</strong></div>
  <div style="color: var(--text-muted);">{esc(row['summary'])}</div>
</div>""")
    return f"""
<section id="health">
  <div class="shell">
    <div class="section-head">
      <h2>Health Snapshot</h2>
      <div class="meta">complementary to /workspace-status</div>
    </div>
    <div class="card">
      {''.join(rows_html)}
    </div>
    <div class="note">For diagnostic depth (broken paths, fix steps, version checks) run <code>/cogni-workspace:workspace-status</code>.</div>
  </div>
</section>
"""


def _empty_section(section_id, title, msg):
    return f"""
<section id="{section_id}">
  <div class="shell">
    <h2>{esc(title)}</h2>
    <div class="note warning">{esc(msg)}</div>
  </div>
</section>
"""


def render_html(workspace_root, mode, config, plugins, themes, mcp_servers,
                markets_meta, market_sets, market_files, hooks_rows, snapshot, theme):
    css = render_css(theme)
    foundation = foundation_files(workspace_root)
    overview_html = render_overview(workspace_root, mode, config or {}, foundation)
    plugins_html = render_plugins(plugins)
    themes_html = render_themes(themes)
    mcp_html = render_mcp(mcp_servers)
    markets_html = render_markets(markets_meta, market_sets, market_files)
    hooks_html = render_hooks(hooks_rows)
    health_html = render_health(snapshot)

    title = f"Workspace · {esc(theme.get('name', 'Workspace'))}"
    workspace_label = os.path.basename(workspace_root.rstrip("/")) or workspace_root
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<header class="hero">
  <div class="shell">
    <div>
      <h1>cogni-workspace</h1>
      <div class="lede">Configuration view of <code>{esc(workspace_label)}</code> — plugins, themes, MCPs, markets, hooks.</div>
    </div>
    <div class="meta">
      <span class="pill">workspace-dashboard</span>
      <div>theme: <code>{esc(theme.get('name', '—'))}</code></div>
      <div>generated: {esc(generated_at)}</div>
    </div>
  </div>
</header>
<nav class="sticky">
  <div class="shell">
    <a href="#overview">Overview</a>
    <a href="#plugins">Plugins</a>
    <a href="#themes">Themes</a>
    <a href="#mcp">MCP</a>
    <a href="#markets">Markets</a>
    <a href="#hooks">Hooks</a>
    <a href="#health">Health</a>
  </div>
</nav>
{overview_html}
{plugins_html}
{themes_html}
{mcp_html}
{markets_html}
{hooks_html}
{health_html}
<footer class="foot">
  Generated by <strong>cogni-workspace · workspace-dashboard</strong> · {esc(generated_at)}
</footer>
<script>
(function() {{
  const links = document.querySelectorAll("nav.sticky a");
  const sections = Array.from(document.querySelectorAll("section"));
  function onScroll() {{
    const y = window.scrollY + 120;
    let active = sections[0];
    for (const s of sections) {{
      if (s.offsetTop <= y) active = s;
    }}
    links.forEach(a => a.classList.toggle("active", a.getAttribute("href") === "#" + active.id));
  }}
  window.addEventListener("scroll", onScroll);
  onScroll();
}})();
</script>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("workspace_root")
    parser.add_argument("--design-variables", default=None)
    parser.add_argument("--theme", default=None, help="Path to a theme.md (legacy fallback)")
    parser.add_argument("--output", default=None,
                        help="Output HTML path (default: <workspace>/workspace-dashboard.html)")
    args = parser.parse_args()

    workspace_root = os.path.abspath(args.workspace_root)
    if not os.path.isdir(workspace_root):
        print(json.dumps({"status": "error", "error": f"Not a directory: {workspace_root}"}))
        return 2

    mode, config = detect_mode(workspace_root)
    if mode == "unknown":
        # We still produce a dashboard, but it'll mostly be empty. Caller decides.
        pass

    design_variables = load_design_variables(args.design_variables)
    parsed_theme = parse_theme_md(args.theme) if args.theme else None
    theme, theme_warnings = merge_tokens(design_variables, parsed_theme)

    plugins = discover_plugins(workspace_root, mode)
    themes = discover_themes(workspace_root)

    registry = load_mcp_registry(workspace_root)
    mcp_servers = None
    if registry:
        mcp_servers = []
        for key, server in registry.get("servers", {}).items():
            entry = dict(server)
            entry["name"] = entry.get("name", key)
            status, hint = mcp_install_status(entry)
            entry["install_status"] = status
            entry["install_hint"] = hint
            mcp_servers.append(entry)

    markets_meta, market_sets, market_files = load_market_matrix(workspace_root)
    hooks_rows = load_hooks(workspace_root)
    snapshot = health_snapshot(workspace_root, foundation_files(workspace_root),
                               plugins, themes, mcp_servers)

    html_doc = render_html(
        workspace_root=workspace_root,
        mode=mode,
        config=config,
        plugins=plugins,
        themes=themes,
        mcp_servers=mcp_servers,
        markets_meta=markets_meta,
        market_sets=market_sets,
        market_files=market_files,
        hooks_rows=hooks_rows,
        snapshot=snapshot,
        theme=theme,
    )

    output_path = args.output or os.path.join(workspace_root, "workspace-dashboard.html")
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "w") as f:
        f.write(html_doc)

    print(json.dumps({
        "status": "ok",
        "path": output_path,
        "theme": theme.get("name", "—"),
        "design_variables": args.design_variables,
        "mode": mode,
        "plugins": len(plugins),
        "themes": len(themes),
        "mcp_servers": len(mcp_servers) if mcp_servers else 0,
        "markets": len(markets_meta),
        "hooks": len(hooks_rows),
        "theme_warnings": theme_warnings,
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
