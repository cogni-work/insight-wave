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


def scan_themes_dir(themes_dir, source_label):
    """Scan a themes directory and return a dict of slug -> theme info."""
    themes = {}
    if not themes_dir or not os.path.isdir(themes_dir):
        return themes

    for entry in sorted(os.listdir(themes_dir)):
        if entry.startswith("_") or entry.startswith("."):
            continue
        theme_md = os.path.join(themes_dir, entry, "theme.md")
        if not os.path.isfile(theme_md):
            continue

        info = parse_theme_md(theme_md)
        if info is None:
            continue

        info["slug"] = entry
        info["path"] = os.path.abspath(theme_md)
        info["source"] = source_label
        info["mtime"] = os.path.getmtime(theme_md)
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
    args = parser.parse_args()

    plugin_root = args.plugin_root or os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    workspace_root = args.workspace_root or os.environ.get("COGNI_WORKSPACE_ROOT", "")

    # 1. Standard themes (from the plugin itself)
    standard_dir = os.path.join(plugin_root, "themes") if plugin_root else ""
    standard_themes = scan_themes_dir(standard_dir, "standard")

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

    workspace_themes = scan_themes_dir(workspace_dir, "workspace")

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
