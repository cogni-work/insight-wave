#!/usr/bin/env python3
"""load-theme-component.py — Resolve a theme component primitive path.

Stdlib-only. Given ``(theme_slug, surface, component)``, walk the workspace
themes directory, read ``themes/<slug>/manifest.json`` (Theme System v2,
schema_version "1.0"), and return the absolute path to the requested
component file under ``tiers.components.<surface>/<component>.html``.

The caller owns reading + interpolating + emitting the component contents —
the loader returns paths, never bytes (copy-on-use semantics, RFC #124 open
question 2 resolution). This keeps the loader free of side effects and lets
the caller decide whether to inline, cache, or live-reload the primitive.

The loader is intentionally tolerant:
- Missing manifest.json → ``status: "miss"`` with reason ``"tier-0 theme"``.
- Manifest present but no ``tiers.components`` → ``status: "miss"`` with
  reason ``"theme has no components tier"``.
- Components tier present but missing the requested surface → ``status:
  "miss"`` with reason ``"surface 'X' not declared"``.
- Surface declared but the component file does not exist → ``status:
  "miss"`` with reason ``"component file not found: <path>"``.
- Hard failures (unreadable manifest, malformed JSON) → ``status: "error"``.

Every "miss" is a normal control-flow signal for the caller's fallback path.
The renderer treats miss as "use the inline template instead".

Usage (CLI):
    python3 load-theme-component.py \\
        --themes-dir <abs-path> \\
        --theme-slug <slug> \\
        --surface <surface> \\
        --component <component-name>

Output (always JSON on stdout, always exit 0 on miss, exit 1 on error):
    Hit:   {"status": "ok", "path": "...", "theme_slug": "...",
            "surface": "...", "component": "..."}
    Miss:  {"status": "miss", "reason": "...", "theme_slug": "...",
            "surface": "...", "component": "..."}
    Error: {"status": "error", "error": "...", "theme_slug": "...",
            "surface": "...", "component": "..."}

Importable: ``resolve(themes_dir, theme_slug, surface, component) -> dict``
returning the same envelope as the CLI prints.
"""

import argparse
import json
import sys
from pathlib import Path


def _envelope(status, theme_slug, surface, component, **extra):
    """Return the canonical loader response shape."""
    base = {
        "status": status,
        "theme_slug": theme_slug,
        "surface": surface,
        "component": component,
    }
    base.update(extra)
    return base


def resolve(themes_dir, theme_slug, surface, component):
    """Resolve ``themes/<slug>/components/<surface>/<component>.html``.

    ``themes_dir`` must be an absolute (or absolute-resolvable) path to the
    workspace themes directory (typically ``cogni-workspace/themes/``). The
    caller decides where that lives — usually via ``$COGNI_WORKSPACE_ROOT``
    or by walking up to the workspace root.
    """
    themes_path = Path(themes_dir).expanduser().resolve()
    theme_dir = themes_path / theme_slug

    if not theme_dir.is_dir():
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="theme directory not found: {}".format(theme_dir),
        )

    manifest_path = theme_dir / "manifest.json"
    if not manifest_path.is_file():
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="tier-0 theme (no manifest.json)",
        )

    try:
        with manifest_path.open("r", encoding="utf-8") as h:
            manifest = json.load(h)
    except (json.JSONDecodeError, OSError) as e:
        return _envelope(
            "error", theme_slug, surface, component,
            error="failed to read manifest: {}".format(e),
        )

    tiers = manifest.get("tiers")
    if not isinstance(tiers, dict):
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="manifest has no tiers map",
        )

    components = tiers.get("components")
    if not isinstance(components, dict):
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="theme has no components tier",
        )

    surface_path = components.get(surface)
    if not isinstance(surface_path, str) or not surface_path:
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="surface '{}' not declared in tiers.components".format(surface),
        )

    component_file = (theme_dir / surface_path / (component + ".html")).resolve()
    if not component_file.is_file():
        return _envelope(
            "miss", theme_slug, surface, component,
            reason="component file not found: {}".format(component_file),
        )

    return _envelope(
        "ok", theme_slug, surface, component,
        path=str(component_file),
    )


def main():
    parser = argparse.ArgumentParser(
        description="Resolve a theme component primitive path."
    )
    parser.add_argument("--themes-dir", required=True,
                        help="Absolute path to the workspace themes/ directory.")
    parser.add_argument("--theme-slug", required=True,
                        help="Theme slug (kebab-case directory name).")
    parser.add_argument("--surface", required=True,
                        help="Component surface (e.g. 'deck').")
    parser.add_argument("--component", required=True,
                        help="Component name without .html extension (e.g. 'title-slide').")
    args = parser.parse_args()

    result = resolve(args.themes_dir, args.theme_slug, args.surface, args.component)
    sys.stdout.write(json.dumps(result) + "\n")
    return 0 if result["status"] != "error" else 1


if __name__ == "__main__":
    sys.exit(main())
