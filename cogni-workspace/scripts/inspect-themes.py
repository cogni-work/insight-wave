#!/usr/bin/env python3
"""inspect-themes.py — Tier-aware introspection of user-visible themes.

For each theme that the picker would resolve (merged across
``${CLAUDE_PLUGIN_ROOT}/themes/`` and ``${COGNI_WORKSPACE_ROOT}/themes/``,
workspace shadowing standard), report:

- ``tier``: ``tier-0`` or ``tiered`` (from ``manifest.json`` presence).
- ``schema_version``: ``manifest.schema_version`` for tiered themes, else null.
- ``tiers_populated``: dotted keys of declared tiers whose path exists on disk.
- ``origin``: ``claude-design @ <imported_at> (sha256 <prefix>…)`` if the
  ``.claude-design-source`` sidecar is present, else ``local-authored``.
- ``color_palette`` / ``typography``: presence of those H2 sections in
  ``theme.md`` — the legacy Check 4 signals, preserved verbatim as the
  tier-0 floor.
- ``validator_pass`` / ``validator_first_error``: populated only when
  ``--strict`` is passed; subprocesses ``validate-theme-manifest.py``.

Read-only, stdlib only. Reuses ``signature()``, ``parse_design_source()``,
``is_stale_path()``, and ``scan_dir()`` from
``cogni-workspace/scripts/check-theme-drift.py`` via dynamic import
(the filename uses hyphens, so direct ``import`` does not work — same
pattern as ``validate-theme-manifest.py:_load_token_generator()``).

Output envelope matches the cogni-workspace convention:
    {"success": bool, "data": {...}, "error": "..."}
"""

import argparse
import importlib.util
import json
import os
import subprocess
import sys


HERE = os.path.dirname(os.path.abspath(__file__))


def _load_drift_helpers():
    """Dynamic-import check-theme-drift.py for its reusable helpers."""
    spec = importlib.util.spec_from_file_location(
        "_theme_drift", os.path.join(HERE, "check-theme-drift.py")
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot locate check-theme-drift.py next to inspect-themes.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_DRIFT = _load_drift_helpers()


def read_manifest(theme_dir):
    """Return parsed manifest.json, or None on missing/invalid."""
    path = os.path.join(theme_dir, "manifest.json")
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        return None


def tiers_populated(theme_dir, manifest):
    """Return dotted keys of declared tiers whose on-disk path exists.

    Top-level keys (``tokens``, ``assets``, ``showcase``) appear flat;
    grouped keys (``components.web``, ``templates.report``) appear dotted.
    """
    if not manifest:
        return []
    tiers = manifest.get("tiers", {}) or {}
    out = []
    for key in ("tokens", "assets"):
        sub = tiers.get(key)
        if isinstance(sub, str) and os.path.exists(os.path.join(theme_dir, sub)):
            out.append(key)
    for group in ("components", "templates"):
        node = tiers.get(group, {}) or {}
        if not isinstance(node, dict):
            continue
        for name, sub in node.items():
            if isinstance(sub, str) and os.path.exists(os.path.join(theme_dir, sub)):
                out.append("{}.{}".format(group, name))
    if "showcase" in manifest:
        showcase = manifest["showcase"]
        if isinstance(showcase, str) and os.path.exists(os.path.join(theme_dir, showcase)):
            out.append("showcase")
    return out


def origin(theme_dir):
    """Render the origin string from .claude-design-source, or 'local-authored'.

    parse_design_source() only returns {url, sha256}; we re-read the sidecar
    here for imported_at (cheap — one extra open per theme).
    """
    sidecar_path = os.path.join(theme_dir, ".claude-design-source")
    if not os.path.isfile(sidecar_path):
        return "local-authored"
    try:
        with open(sidecar_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        return "local-authored"
    sha = data.get("sha256") or ""
    sha_prefix = sha[:8] if sha else "?"
    imported_at = data.get("imported_at") or "unknown"
    return "claude-design @ {} (sha256 {}…)".format(imported_at, sha_prefix)


def section_present(theme_md_path, section_name):
    """True if theme.md contains a line matching '## <section_name>'."""
    if not os.path.isfile(theme_md_path):
        return False
    needle = "## {}".format(section_name)
    try:
        with open(theme_md_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith(needle):
                    return True
    except (OSError, UnicodeDecodeError):
        return False
    return False


def run_validator(plugin_root, theme_dir):
    """Subprocess validate-theme-manifest.py; return (pass: bool, first_error: str)."""
    script = os.path.join(plugin_root, "scripts", "validate-theme-manifest.py")
    if not os.path.isfile(script):
        return (False, "validator not found at {}".format(script))
    try:
        proc = subprocess.run(
            [sys.executable, script, theme_dir],
            capture_output=True, text=True, check=False,
        )
    except OSError as e:
        return (False, "validator subprocess failed: {}".format(e))
    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return (False, "validator returned non-JSON output")
    return (bool(envelope.get("success")), envelope.get("error") or "")


def build_row(slug, theme_dir, source, plugin_root, strict):
    sig = _DRIFT.signature(theme_dir)
    if sig is None:
        return None
    manifest = read_manifest(theme_dir) if sig["tier"] == "tiered" else None
    theme_md = os.path.join(theme_dir, "theme.md")

    row = {
        "slug": slug,
        "source": source,
        "tier": sig["tier"],
        "schema_version": manifest.get("schema_version") if manifest else None,
        "tiers_populated": tiers_populated(theme_dir, manifest),
        "origin": origin(theme_dir),
        "color_palette": section_present(theme_md, "Color Palette"),
        "typography": section_present(theme_md, "Typography"),
        "validator_pass": None,
        "validator_first_error": "",
    }

    if strict:
        if sig["tier"] == "tier-0":
            row["validator_pass"] = True
        else:
            ok, err = run_validator(plugin_root, theme_dir)
            row["validator_pass"] = ok
            row["validator_first_error"] = err if not ok else ""

    return row


def merged_themes(standard_dir, workspace_dir):
    """Return [(slug, theme_dir, source)] in sorted order, workspace shadowing standard.

    Uses check-theme-drift.scan_dir() for filter rules (skip dot/underscore
    prefixes, require theme.md). Workspace entries win on slug collision.
    """
    std = _DRIFT.scan_dir(standard_dir)
    ws = _DRIFT.scan_dir(workspace_dir)
    resolved = []
    for slug in sorted(set(std.keys()) | set(ws.keys())):
        if slug in ws:
            resolved.append((slug, os.path.join(workspace_dir, slug), "workspace"))
        else:
            resolved.append((slug, os.path.join(standard_dir, slug), "standard"))
    return resolved


def emit(data, pretty=False):
    indent = 2 if pretty else None
    print(json.dumps({"success": True, "data": data, "error": ""}, indent=indent, ensure_ascii=False))
    return 0


def main():
    parser = argparse.ArgumentParser(description="Tier-aware introspection of user-visible themes.")
    parser.add_argument("--plugin-root", default="", help="Override CLAUDE_PLUGIN_ROOT")
    parser.add_argument("--workspace-root", default="", help="Override COGNI_WORKSPACE_ROOT")
    parser.add_argument("--strict", action="store_true",
                        help="Run validate-theme-manifest.py per tiered theme")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args()

    plugin_root = args.plugin_root or os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    workspace_root = args.workspace_root or os.environ.get("COGNI_WORKSPACE_ROOT", "")

    standard_dir = os.path.join(plugin_root, "themes") if plugin_root else ""
    workspace_dir = os.path.join(workspace_root, "themes") if workspace_root else ""

    if _DRIFT.is_stale_path(workspace_root) or not workspace_dir or not os.path.isdir(workspace_dir):
        workspace_dir = ""
    if not standard_dir or not os.path.isdir(standard_dir):
        standard_dir = ""

    rows = []
    tiered_count = 0
    for slug, theme_dir, source in merged_themes(standard_dir, workspace_dir):
        row = build_row(slug, theme_dir, source, plugin_root, args.strict)
        if row is None:
            continue
        if row["tier"] == "tiered":
            tiered_count += 1
        rows.append(row)

    data = {
        "standard_dir": standard_dir,
        "workspace_dir": workspace_dir,
        "strict": args.strict,
        "themes": rows,
        "tiered_count": tiered_count,
        "total_count": len(rows),
    }
    return emit(data, args.pretty)


if __name__ == "__main__":
    sys.exit(main())
