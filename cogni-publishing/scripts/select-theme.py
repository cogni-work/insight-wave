#!/usr/bin/env python3
"""select-theme.py — Resolve one theme to the three-field selection handoff.

Every themed consumer receives the same contract from a selection:

    theme_path  absolute path to the selected theme.md
    theme_name  the theme.md H1, or the directory name when it has none
    theme_slug  the theme directory name, kebab-case

Four ways in, exactly one per call:

    --theme-path <theme.md | theme dir>   explicit path; reads that path only
    --slug <slug>                         a discovered theme by slug
    --name <name>                         a discovered theme by name (case-insensitive)
    --default                             the first theme in relevance order

The explicit mode is the one a caller uses without any workspace: it reads no
environment variable and nothing under $HOME, and it creates nothing. The three
discovery modes scan the bundled themes that ship with this plugin plus the
optional user location (``--user-themes`` > ``--workspace-root``/themes >
``$COGNI_WORKSPACE_ROOT/themes``), where a user theme shadows a bundled theme of
the same slug. Discovery here never searches $HOME for a workspace: selection
must be deterministic, so the legacy auto-discovery stays in discover-themes.py.

Output: one ``{"success": bool, "data": {...}, "error": "..."}`` envelope on
stdout. ``data`` carries ``theme_path``, ``theme_name``, ``theme_slug``,
``source`` (``explicit`` | ``standard`` | ``workspace``) and ``color_palette``
(whether theme.md has a ``## Color Palette`` section). Exit 0 selected, 1 no
such theme, 2 usage error.
"""

import argparse
import importlib.util
import json
import os
import re
import sys


HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PLUGIN_ROOT = os.path.dirname(HERE)


def emit(success, data=None, error=""):
    print(json.dumps({"success": success, "data": data or {}, "error": error}, ensure_ascii=False))
    return 0 if success else 1


def kebab(name):
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug


def read_theme(theme_md):
    """Return (name, has_color_palette) for a theme.md, or None if unreadable."""
    try:
        with open(theme_md, "r", encoding="utf-8") as f:
            content = f.read()
    except (OSError, UnicodeDecodeError):
        return None
    m = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    name = m.group(1).strip() if m else os.path.basename(os.path.dirname(theme_md))
    palette = re.search(r"^##\s+Color Palette\b", content, re.MULTILINE) is not None
    return name, palette


def handoff(theme_md, source):
    theme_md = os.path.abspath(theme_md)
    parsed = read_theme(theme_md)
    if parsed is None:
        return None
    name, palette = parsed
    return {
        "theme_path": theme_md,
        "theme_name": name,
        "theme_slug": kebab(os.path.basename(os.path.dirname(theme_md))),
        "source": source,
        "color_palette": palette,
    }


def select_explicit(path):
    """Resolve an explicit theme.md or theme directory. Touches nothing else."""
    if os.path.isdir(path):
        theme_md = os.path.join(path, "theme.md")
    else:
        theme_md = path
    if os.path.basename(theme_md) != "theme.md" or not os.path.isfile(theme_md):
        return None, "no theme.md at {}".format(path)
    result = handoff(theme_md, "explicit")
    if result is None:
        return None, "cannot read {}".format(theme_md)
    return result, ""


def _load_discovery():
    spec = importlib.util.spec_from_file_location(
        "_discover_themes", os.path.join(HERE, "discover-themes.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def discovered(plugin_root, user_themes, workspace_root):
    """Return discovery entries in relevance order, user themes shadowing bundled."""
    disc = _load_discovery()
    standard = disc.scan_themes_dir(os.path.join(plugin_root, "themes"), "standard",
                                    include_tiers=False)
    if user_themes:
        user_dir = user_themes if os.path.isdir(user_themes) else ""
    else:
        root = workspace_root or os.environ.get("COGNI_WORKSPACE_ROOT", "")
        user_dir = "" if disc.is_stale_path(root) else os.path.join(root, "themes")
    user = disc.scan_themes_dir(user_dir, "workspace", include_tiers=False)
    merged = {**standard, **user}
    return sorted(
        merged.values(),
        key=lambda t: (t["source"] != "workspace", -t.get("mtime", 0), t["name"].lower()),
    )


def main():
    parser = argparse.ArgumentParser(description="Resolve one theme to theme_path/theme_name/theme_slug.")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--theme-path", help="Explicit theme.md, or a directory holding one")
    mode.add_argument("--slug", help="Select a discovered theme by slug")
    mode.add_argument("--name", help="Select a discovered theme by name (case-insensitive)")
    mode.add_argument("--default", action="store_true", help="Select the first theme in relevance order")
    parser.add_argument("--user-themes", default="", help="User theme directory, read in place")
    parser.add_argument("--workspace-root", default="", help="Override COGNI_WORKSPACE_ROOT")
    parser.add_argument("--plugin-root", default="",
                        help="Root holding the bundled themes/ (default: this script's plugin)")
    args = parser.parse_args()

    if args.theme_path is not None:
        result, error = select_explicit(args.theme_path)
        if result is None:
            return emit(False, data={"theme_path": args.theme_path}, error=error)
        return emit(True, data=result)

    entries = discovered(args.plugin_root or DEFAULT_PLUGIN_ROOT, args.user_themes, args.workspace_root)
    if args.slug is not None:
        match = next((t for t in entries if t["slug"] == args.slug), None)
        wanted = "slug {!r}".format(args.slug)
    elif args.name is not None:
        match = next((t for t in entries if t["name"].lower() == args.name.lower()), None)
        wanted = "name {!r}".format(args.name)
    else:
        match = entries[0] if entries else None
        wanted = "any theme"
    if match is None:
        return emit(False, data={"available": [t["slug"] for t in entries]},
                    error="no discovered theme matches {}".format(wanted))
    result = handoff(match["path"], match["source"])
    if result is None:
        return emit(False, error="cannot read {}".format(match["path"]))
    return emit(True, data=result)


if __name__ == "__main__":
    sys.exit(main())
