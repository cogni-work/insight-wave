#!/usr/bin/env python3
"""Discover all available themes across standard and workspace directories.

Scans two locations:
  1. Standard themes: $CLAUDE_PLUGIN_ROOT/themes/ (always available, ships with cogni-workspace)
  2. Workspace themes: $COGNI_WORKSPACE_ROOT/themes/ (user-created via manage-themes)

When COGNI_WORKSPACE_ROOT is empty or points to a non-existent path (e.g. stale
Cowork session), auto-discovers workspaces by searching for .workspace-config.json
in common locations under $HOME.

Outputs a JSON array of theme objects sorted by modification time (newest first).
Skips the _template directory. Deduplicates by slug (workspace overrides standard).
"""

import argparse
import glob as globmod
import importlib.util
import json
import os
import re
import sys


def parse_theme_md(path):
    """Extract name, description, primary color, and accent color from a theme.md file."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except (IOError, UnicodeDecodeError):
        return None

    # Name: first H1 line
    name_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    name = name_match.group(1).strip() if name_match else os.path.basename(os.path.dirname(path))

    # Description: first non-empty line after the H1, truncated to first sentence
    desc = ""
    if name_match:
        after_h1 = content[name_match.end():]
        for line in after_h1.split("\n"):
            line = line.strip()
            if line and not line.startswith("#"):
                # Take first sentence only for compact output
                first_sentence = re.split(r"(?<=[.!?])\s", line, maxsplit=1)
                desc = first_sentence[0]
                break

    # Extract key colors
    primary = extract_color(content, r"\*\*Primary\*\*.*?`(#[0-9A-Fa-f]{6})`")
    accent = extract_color(content, r"\*\*Accent\*\*.*?`(#[0-9A-Fa-f]{6})`")
    background = extract_color(content, r"\*\*Background\*\*.*?`(#[0-9A-Fa-f]{6})`")

    # Extract header font
    font_match = re.search(r"\*\*Headers\*\*:\s*(.+?)(?:\s*/|$)", content, re.MULTILINE)
    font = font_match.group(1).strip() if font_match else None

    return {
        "name": name,
        "description": desc,
        "primary": primary,
        "accent": accent,
        "background": background,
        "font": font,
    }


def extract_color(content, pattern):
    match = re.search(pattern, content)
    return match.group(1) if match else None


_TIER_VALIDATOR_CACHE = None


def _load_tier_validator():
    """Dynamically load cogni-workspace/scripts/validate-theme-manifest.py.

    The validator filename uses hyphens, so it can't be imported normally.
    Cached after first load. Returns None when the validator can't be located
    (callers fall back to tier-0 behaviour silently).
    """
    global _TIER_VALIDATOR_CACHE
    if _TIER_VALIDATOR_CACHE is not None:
        return _TIER_VALIDATOR_CACHE

    candidates = []
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    if plugin_root:
        candidates.append(os.path.join(plugin_root, "scripts", "validate-theme-manifest.py"))

    here = os.path.dirname(os.path.abspath(__file__))
    walk = here
    for _ in range(6):
        candidate = os.path.join(walk, "scripts", "validate-theme-manifest.py")
        if os.path.isfile(candidate):
            candidates.append(candidate)
            break
        parent = os.path.dirname(walk)
        if parent == walk:
            break
        walk = parent

    for path in candidates:
        if not os.path.isfile(path):
            continue
        try:
            spec = importlib.util.spec_from_file_location("_theme_manifest_validator", path)
            if spec is None or spec.loader is None:
                continue
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            _TIER_VALIDATOR_CACHE = module
            return module
        except Exception:
            continue

    return None


def resolve_tiers(theme_dir):
    """Read manifest.json next to theme.md and return resolved tier paths.

    Returns one of:
      - ``None`` when the theme is tier-0 (no manifest.json) — caller omits
        both ``tiers`` and ``manifest_error`` from the output dict.
      - ``("tiers", {...})`` on success — keys mirror the manifest's declared
        tiers with absolute resolved paths.
      - ``("error", "<message>")`` when manifest.json is present but invalid.
        The caller surfaces this as ``manifest_error`` and falls back to tier-0.
    """
    manifest_path = os.path.join(theme_dir, "manifest.json")
    if not os.path.isfile(manifest_path):
        return None

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        return ("error", "cannot read manifest.json: {}".format(e))

    validator = _load_tier_validator()
    if validator is None:
        return ("error", "validate-theme-manifest.py not found; cannot validate manifest")

    schema_file = validator.find_schema()
    if not os.path.isfile(str(schema_file)):
        return ("error", "schema not found at {}".format(schema_file))
    try:
        with open(schema_file, "r", encoding="utf-8") as f:
            schema = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        return ("error", "cannot read schema: {}".format(e))

    try:
        from pathlib import Path
        validator.validate(manifest, schema)
        validator.check_reserved_keys(manifest)
        validator.check_paths_exist(Path(theme_dir), manifest)
    except validator.ValidationError as e:
        return ("error", str(e))

    tiers_decl = manifest.get("tiers", {})
    resolved = {}
    for key in ("tokens", "assets"):
        if key in tiers_decl:
            resolved[key] = os.path.abspath(os.path.join(theme_dir, tiers_decl[key]))
    for group in ("components", "templates"):
        if group in tiers_decl:
            resolved[group] = {
                name: os.path.abspath(os.path.join(theme_dir, sub))
                for name, sub in tiers_decl[group].items()
            }
    if "showcase" in manifest:
        resolved["showcase"] = os.path.abspath(os.path.join(theme_dir, manifest["showcase"]))
    return ("tiers", resolved)


def scan_themes_dir(themes_dir, source_label, include_tiers=True):
    """Scan a themes directory and return a dict of slug -> theme info.

    When ``include_tiers`` is True (default) and a theme directory contains a
    valid ``manifest.json``, the per-theme dict gains a ``tiers`` field with
    resolved absolute paths. Invalid manifests fall back to tier-0 with a
    ``manifest_error`` field. Tier-0 themes (no manifest.json) emit
    byte-identical output to the legacy (pre-#126) script — no ``tiers``,
    no ``manifest_error``.
    """
    themes = {}
    if not themes_dir or not os.path.isdir(themes_dir):
        return themes

    for entry in sorted(os.listdir(themes_dir)):
        if entry.startswith("_") or entry.startswith("."):
            continue
        theme_dir = os.path.join(themes_dir, entry)
        theme_md = os.path.join(theme_dir, "theme.md")
        if not os.path.isfile(theme_md):
            continue

        info = parse_theme_md(theme_md)
        if info is None:
            continue

        info["slug"] = entry
        info["path"] = os.path.abspath(theme_md)
        info["source"] = source_label
        info["mtime"] = os.path.getmtime(theme_md)

        if include_tiers:
            tier_result = resolve_tiers(theme_dir)
            if tier_result is not None:
                kind, payload = tier_result
                if kind == "tiers":
                    info["tiers"] = payload
                else:
                    info["manifest_error"] = payload

        themes[entry] = info

    return themes


def is_stale_path(path):
    """Check if a path is a stale Cowork session path or simply doesn't exist."""
    if not path:
        return True
    if path.startswith("/sessions/"):
        return True
    return not os.path.isdir(path)


def auto_discover_workspace_root():
    """Search common locations for .workspace-config.json to find a valid workspace root.

    Returns the workspace root path (parent of .workspace-config.json) or empty string.
    Searches:
      1. $PROJECT_AGENTS_OPS_ROOT (if valid)
      2. CloudStorage directories (OneDrive, iCloud, Dropbox)
      3. Direct home subdirectories (one level deep)
    """
    home = os.path.expanduser("~")

    # Try PROJECT_AGENTS_OPS_ROOT first
    ops_root = os.environ.get("PROJECT_AGENTS_OPS_ROOT", "")
    if ops_root and os.path.isfile(os.path.join(ops_root, ".workspace-config.json")):
        return ops_root

    # Search CloudStorage (macOS OneDrive, iCloud, Dropbox, etc.)
    cloud_storage = os.path.join(home, "Library", "CloudStorage")
    if os.path.isdir(cloud_storage):
        # Search two levels deep: CloudStorage/<provider>/<folder>/.workspace-config.json
        pattern = os.path.join(cloud_storage, "*", "*", ".workspace-config.json")
        candidates = globmod.glob(pattern)
        if candidates:
            # Pick the most recently modified workspace
            candidates.sort(key=os.path.getmtime, reverse=True)
            return os.path.dirname(candidates[0])

    # Search direct home subdirectories (one level)
    pattern = os.path.join(home, "*", ".workspace-config.json")
    candidates = globmod.glob(pattern)
    if candidates:
        candidates.sort(key=os.path.getmtime, reverse=True)
        return os.path.dirname(candidates[0])

    return ""


def main():
    parser = argparse.ArgumentParser(description="Discover available themes.")
    parser.add_argument("--workspace-root", default="", help="Override COGNI_WORKSPACE_ROOT")
    parser.add_argument("--plugin-root", default="", help="Override CLAUDE_PLUGIN_ROOT")
    parser.add_argument("--no-discover", action="store_true",
                        help="Disable auto-discovery when workspace root is missing/stale")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    parser.add_argument("--no-include-tiers", action="store_true",
                        help="Suppress the optional 'tiers' and 'manifest_error' fields. "
                             "Output is byte-identical to legacy (pre-#126) tier-0 form.")
    args = parser.parse_args()
    include_tiers = not args.no_include_tiers

    plugin_root = args.plugin_root or os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    workspace_root = args.workspace_root or os.environ.get("COGNI_WORKSPACE_ROOT", "")

    # 1. Standard themes (from the plugin itself)
    standard_dir = os.path.join(plugin_root, "themes") if plugin_root else ""
    standard_themes = scan_themes_dir(standard_dir, "standard", include_tiers=include_tiers)

    # 2. Workspace themes (user-created)
    # Auto-discover workspace root when the configured path is empty or stale
    discovered = False
    if is_stale_path(workspace_root) and not args.no_discover:
        if workspace_root:
            print(f"WARNING: workspace root not found: {workspace_root}", file=sys.stderr)
            if workspace_root.startswith("/sessions/"):
                print("HINT: path looks like a stale Cowork session. Auto-discovering...", file=sys.stderr)
            else:
                print("HINT: COGNI_WORKSPACE_ROOT may be stale. Auto-discovering...", file=sys.stderr)

        discovered_root = auto_discover_workspace_root()
        if discovered_root:
            workspace_root = discovered_root
            discovered = True
            # The themes dir is at <workspace-root>/cogni-workspace/themes/
            # Check both direct themes/ and cogni-workspace/themes/
            candidate_dirs = [
                os.path.join(workspace_root, "themes"),
                os.path.join(workspace_root, "cogni-workspace", "themes"),
            ]
            workspace_dir = ""
            for d in candidate_dirs:
                if os.path.isdir(d):
                    workspace_dir = d
                    break
            if workspace_dir:
                print(f"AUTO-DISCOVERED workspace themes: {workspace_dir}", file=sys.stderr)
            else:
                print(f"AUTO-DISCOVERED workspace at {workspace_root} but no themes/ dir found", file=sys.stderr)
                workspace_dir = ""
        else:
            if not workspace_root:
                print("WARNING: COGNI_WORKSPACE_ROOT not set and auto-discovery found no workspace", file=sys.stderr)
            else:
                print("HINT: Run /manage-workspace to regenerate paths.", file=sys.stderr)
            workspace_dir = ""
    else:
        workspace_dir = os.path.join(workspace_root, "themes") if workspace_root else ""
        if workspace_root and not os.path.isdir(workspace_dir):
            print(f"WARNING: workspace themes dir not found: {workspace_dir}", file=sys.stderr)
            print(f"HINT: COGNI_WORKSPACE_ROOT may be stale. Run /manage-workspace to regenerate.", file=sys.stderr)

    workspace_themes = scan_themes_dir(workspace_dir, "workspace", include_tiers=include_tiers)

    # Merge: workspace themes override standard themes with same slug,
    # standard themes that aren't overridden are kept automatically
    merged = {**standard_themes, **workspace_themes}

    # Sort by: workspace first, then by mtime (newest first), then by name
    result = sorted(
        merged.values(),
        key=lambda t: (t["source"] != "workspace", -t.get("mtime", 0), t["name"].lower()),
    )

    if args.pretty:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
