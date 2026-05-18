#!/usr/bin/env python3
"""check-theme-drift.py — Detect drift between standard and workspace theme copies.

Compares ``${CLAUDE_PLUGIN_ROOT}/themes/`` (standard, ships with the plugin) and
``${COGNI_WORKSPACE_ROOT}/themes/`` (user-owned). For each slug that exists on
both sides, computes a shallow signature and classifies the drift. Slugs that
exist on only one side are not reported — that is the normal case, not drift.

Read-only. stdlib only (``hashlib``, ``json``, ``os``, ``argparse``). At most
four file opens per theme directory: ``theme.md``, ``manifest.json``,
``tokens/tokens.css``, and ``.claude-design-source``.

Output envelope matches the cogni-workspace convention:
    {"success": bool, "data": {...}, "error": "..."}

When the workspace dir is missing or stale (no ``COGNI_WORKSPACE_ROOT``, stale
Cowork session, etc.), returns ``success: true`` with ``shadowed_slugs: []``
and a ``note`` — workspace-status treats this as "no drift to report".
"""

import argparse
import hashlib
import json
import os
import sys


def sha256_file(path):
    """Return the hex sha256 of a file, or None on any error."""
    try:
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except (OSError, IOError):
        return None


def parse_design_source(path):
    """Parse a .claude-design-source sidecar. Returns {url, sha256} or None."""
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        return None
    url = data.get("url")
    sha = data.get("sha256")
    if not url and not sha:
        return None
    return {"url": url, "sha256": sha}


def signature(theme_dir):
    """Compute a shallow drift signature for one theme directory.

    Returns ``None`` if ``theme.md`` is missing (the theme is ineligible).
    """
    theme_md = os.path.join(theme_dir, "theme.md")
    if not os.path.isfile(theme_md):
        return None
    manifest_path = os.path.join(theme_dir, "manifest.json")
    tokens_css_path = os.path.join(theme_dir, "tokens", "tokens.css")
    sidecar_path = os.path.join(theme_dir, ".claude-design-source")

    manifest_sha = sha256_file(manifest_path) if os.path.isfile(manifest_path) else None
    tokens_css_sha = sha256_file(tokens_css_path) if os.path.isfile(tokens_css_path) else None

    return {
        "tier": "tiered" if manifest_sha else "tier-0",
        "theme_md_sha256": sha256_file(theme_md),
        "manifest_sha256": manifest_sha,
        "tokens_css_sha256": tokens_css_sha,
        "design_source": parse_design_source(sidecar_path),
    }


def scan_dir(themes_dir):
    """Return {slug: signature} for eligible immediate subdirs.

    Skips entries starting with ``_`` or ``.`` and any dir without ``theme.md``
    (mirrors the filter in pick-theme/scripts/discover-themes.py).
    """
    result = {}
    if not themes_dir or not os.path.isdir(themes_dir):
        return result
    for entry in sorted(os.listdir(themes_dir)):
        if entry.startswith("_") or entry.startswith("."):
            continue
        theme_dir = os.path.join(themes_dir, entry)
        if not os.path.isdir(theme_dir):
            continue
        sig = signature(theme_dir)
        if sig is None:
            continue
        result[entry] = sig
    return result


def is_stale_path(path):
    """Mirror of discover-themes.py:is_stale_path — never crash on missing dirs."""
    if not path:
        return True
    if path.startswith("/sessions/"):
        return True
    return not os.path.isdir(path)


def sidecar_diff(std_src, ws_src):
    """Return advisory suffix describing sidecar mismatch, or empty string.

    Three cases:
      - both present, url or sha256 differs → ``standard imported from bundle X;
        workspace imported from bundle Y``
      - exactly one present → ``(one side imported from a Claude Design bundle,
        the other did not)``
      - both absent, or both present and equal → empty string
    """
    if std_src is None and ws_src is None:
        return ""
    if std_src is None or ws_src is None:
        return "; (one side imported from a Claude Design bundle, the other did not)"
    if std_src.get("url") != ws_src.get("url") or std_src.get("sha256") != ws_src.get("sha256"):
        std_id = std_src.get("url") or std_src.get("sha256") or "?"
        ws_id = ws_src.get("url") or ws_src.get("sha256") or "?"
        return "; standard imported from bundle {}; workspace imported from bundle {}".format(
            std_id, ws_id
        )
    return ""


def classify(std, ws):
    """Compare two signatures and return (status, advisory).

    Sidecar mismatch promotes an otherwise ``identical`` row to
    ``workspace_customised`` so it surfaces; on already-drifting rows the
    sidecar text is appended to the advisory.
    """
    sidecar_suffix = sidecar_diff(std["design_source"], ws["design_source"])

    std_tier = std["tier"]
    ws_tier = ws["tier"]

    if std_tier == "tier-0" and ws_tier == "tier-0":
        if std["theme_md_sha256"] == ws["theme_md_sha256"] and not sidecar_suffix:
            return ("identical", "identical")
        return ("workspace_customised", "workspace customised" + sidecar_suffix)

    if std_tier == "tiered" and ws_tier == "tier-0":
        return (
            "upgrade_available",
            "upgrade available — workspace copy is tier-0, standard is tiered" + sidecar_suffix,
        )

    if std_tier == "tier-0" and ws_tier == "tiered":
        return ("workspace_ahead", "workspace ahead" + sidecar_suffix)

    # both tiered
    manifest_differs = std["manifest_sha256"] != ws["manifest_sha256"]
    tokens_differs = std["tokens_css_sha256"] != ws["tokens_css_sha256"]
    if manifest_differs or tokens_differs:
        parts = []
        if manifest_differs:
            parts.append(
                "standard manifest sha {}, workspace sha {}".format(
                    (std["manifest_sha256"] or "none")[:8],
                    (ws["manifest_sha256"] or "none")[:8],
                )
            )
        if tokens_differs:
            parts.append(
                "tokens.css differs (standard {} vs workspace {})".format(
                    (std["tokens_css_sha256"] or "none")[:8],
                    (ws["tokens_css_sha256"] or "none")[:8],
                )
            )
        return ("tier_drift", "tier drift — " + "; ".join(parts) + sidecar_suffix)

    if std["theme_md_sha256"] != ws["theme_md_sha256"] or sidecar_suffix:
        return ("workspace_customised", "workspace customised" + sidecar_suffix)

    return ("identical", "identical")


def emit(success, data=None, error=""):
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(description="Detect drift between standard and workspace theme copies.")
    parser.add_argument("--plugin-root", default="", help="Override CLAUDE_PLUGIN_ROOT")
    parser.add_argument("--workspace-root", default="", help="Override COGNI_WORKSPACE_ROOT")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args()

    plugin_root = args.plugin_root or os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    workspace_root = args.workspace_root or os.environ.get("COGNI_WORKSPACE_ROOT", "")

    standard_dir = os.path.join(plugin_root, "themes") if plugin_root else ""
    workspace_dir = os.path.join(workspace_root, "themes") if workspace_root else ""

    data = {
        "standard_dir": standard_dir,
        "workspace_dir": workspace_dir,
        "shadowed_slugs": [],
        "drift_count": 0,
        "identical_count": 0,
    }

    if not standard_dir or not os.path.isdir(standard_dir):
        data["note"] = "standard themes dir not found; no drift to report"
        output = json.dumps({"success": True, "data": data, "error": ""}, indent=2 if args.pretty else None, ensure_ascii=False)
        print(output)
        return 0

    if is_stale_path(workspace_root) or not workspace_dir or not os.path.isdir(workspace_dir):
        data["note"] = "workspace themes dir not found; no drift to report"
        output = json.dumps({"success": True, "data": data, "error": ""}, indent=2 if args.pretty else None, ensure_ascii=False)
        print(output)
        return 0

    standard = scan_dir(standard_dir)
    workspace = scan_dir(workspace_dir)

    shadowed = sorted(set(standard.keys()) & set(workspace.keys()))
    rows = []
    drift_count = 0
    identical_count = 0
    for slug in shadowed:
        std = standard[slug]
        ws = workspace[slug]
        status, advisory = classify(std, ws)
        rows.append({
            "slug": slug,
            "status": status,
            "advisory": advisory,
            "standard": std,
            "workspace": ws,
        })
        if status == "identical":
            identical_count += 1
        else:
            drift_count += 1

    data["shadowed_slugs"] = rows
    data["drift_count"] = drift_count
    data["identical_count"] = identical_count

    output = json.dumps({"success": True, "data": data, "error": ""}, indent=2 if args.pretty else None, ensure_ascii=False)
    print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
