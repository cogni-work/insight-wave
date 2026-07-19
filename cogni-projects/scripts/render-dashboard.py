#!/usr/bin/env python3
"""Render a partner-meeting portfolio dashboard from a cogni-projects portfolio.

Reads projects-portfolio.json to confirm the portfolio, then opens and parses
every consultant / project / assignment entity's frontmatter to compute:
  - per-project staffing coverage (open_roles filled vs still open) + a health flag,
  - an aggregate portfolio value summary grouped by strategic_impact (1..5),
  - a simple consultant-utilization aggregate.
Writes a self-contained HTML dashboard to <portfolio-dir>/output/dashboard.html.

Read-only: never writes projects-portfolio.json (register-entity.py is its only
writer) and never appends to .metadata/. Degrades gracefully — a missing or
malformed entity field yields a partial snapshot with a surfaced warning, never
a hard failure, because a partial snapshot is more useful than no snapshot to a
partner reviewing a portfolio that is still being authored.

Stdlib-only (no PyYAML). Reuses validate-entities.py's parse_frontmatter and
_entity_files by file-path load rather than re-implementing a parser or a
directory walk — the same idiom register-entity.py uses.

Usage:
  python3 render-dashboard.py <portfolio-dir> [--design-variables <path.json>]

Output: a single JSON line following the repo contract
  {"success": bool, "data": {...}, "error": str}
Exit: 0 ok / 2 usage or environment failure.
"""

import argparse
import datetime
import html
import importlib.util
import json
import os
import sys

# validate-entities.py is not an importable module name (hyphens), so load it by
# file location and reuse its parser + entity-file discovery — the same idiom
# register-entity.py uses, so the dashboard reads exactly the shape the
# validator enforces rather than duplicating (and drifting from) those rules.
_v_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate-entities.py")
_spec = importlib.util.spec_from_file_location("validate_entities", _v_path)
if _spec is None or _spec.loader is None:
    print(json.dumps({
        "success": False, "data": {},
        "error": "cannot load validator module: %s" % _v_path,
    }))
    sys.exit(2)
_ve = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ve)


# The built-in palette. The dashboard renders with this whenever no
# --design-variables file is supplied, so the script never depends on
# cogni-workspace:pick-theme; a themed override is a purely optional flag.
DEFAULT_THEME = {
    "theme_name": "cogni-work",
    "bg": "#0f1419",
    "surface": "#1a2028",
    "text": "#e6edf3",
    "muted": "#9aa7b4",
    "accent": "#4f9cf9",
    "ok": "#3fb950",
    "warn": "#d29922",
    "risk": "#f85149",
    "border": "#2d333b",
    "font": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
}

# The status values that count an assignment as actively covering a role. A
# completed assignment no longer staffs an open role.
ACTIVE_ASSIGNMENT_STATES = ("planned", "active")

# Theme values are interpolated into the <style> block rather than into escaped
# text nodes, so a value carrying CSS-structural or markup characters could
# close the stylesheet and inject arbitrary markup into the self-contained HTML.
# Parentheses are denied for a distinct reason: a value like
# `url(https://evil.example/track.png)` is CSS-valid and would interpolate
# verbatim into `background: url(...)`, turning a self-contained partner-meeting
# artifact into one that fetches an external resource (a phone-home beacon) the
# moment it is opened. Rejecting `(` / `)` blocks the url()/@import fetch surface
# alongside the markup-injection one.
# The file is operator-supplied rather than portfolio-derived, so a conservative
# denylist of CSS-structural characters is the proportionate guard: reject and
# fall back rather than attempt to sanitize.
# Single quotes stay legal: a font stack ("'Segoe UI', Roboto") needs them and
# they cannot terminate a <style> block on their own.
_THEME_VALUE_FORBIDDEN = set("<>{}();@\\")
_THEME_VALUE_MAX_LEN = 120


def _valid_theme_value(value):
    """Return True when a theme override is safe to interpolate into <style>."""
    return (
        isinstance(value, str)
        and 0 < len(value) <= _THEME_VALUE_MAX_LEN
        and not (_THEME_VALUE_FORBIDDEN & set(value))
    )


def _load_theme(path):
    """Return the theme dict. Falls back to DEFAULT_THEME on any read problem.

    Theming is a nicety, never a hard dependency: a missing or malformed
    --design-variables file must not fail the render, only fall back.
    """
    if not path:
        return dict(DEFAULT_THEME), None
    try:
        with open(path, "r", encoding="utf-8") as f:
            overrides = json.load(f)
    except (OSError, ValueError) as exc:
        return dict(DEFAULT_THEME), "design-variables ignored (%s): %s" % (path, exc)
    theme = dict(DEFAULT_THEME)
    rejected = set()
    if isinstance(overrides, dict):
        # Accept both a flat {key: value} map and a nested {"colors": {...}} one.
        for src in (overrides, overrides.get("colors", {})):
            if isinstance(src, dict):
                for key, value in src.items():
                    if key not in theme:
                        continue
                    if _valid_theme_value(value):
                        theme[key] = value
                    else:
                        rejected.add(key)
    if rejected:
        return theme, "design-variables: ignored unsafe value(s) for %s — using the built-in palette for those keys" % ", ".join(sorted(rejected))
    return theme, None


def _read_entities(portfolio_dir):
    """Parse every entity file into type-keyed lists, collecting warnings.

    Returns (entities, warnings) where entities is
    {"consultant": [...], "project": [...], "assignment": [...]} of frontmatter
    dicts. A file that cannot be read, cannot be decoded, or has no frontmatter
    is recorded as a warning and skipped — the rest of the portfolio still
    renders, because one unreadable record must never cost the partner the whole
    snapshot.
    """
    entities = {"consultant": [], "project": [], "assignment": []}
    warnings = []
    for path in _ve._entity_files(portfolio_dir):
        rel = os.path.relpath(path, portfolio_dir)
        try:
            with open(path, "r", encoding="utf-8") as f:
                fm = _ve.parse_frontmatter(f.read())
        # UnicodeDecodeError is a ValueError, not an OSError, so it escaped the
        # original guard: one non-UTF-8 entity file must degrade to a single
        # warning, not abort the whole render. Named explicitly rather than
        # widening to ValueError, so a future parser fault still surfaces
        # instead of being silently reported as an unreadable file.
        except (OSError, UnicodeDecodeError) as exc:
            warnings.append("cannot read %s: %s" % (rel, exc))
            continue
        if not fm:
            warnings.append("no frontmatter in %s — skipped" % rel)
            continue
        etype = fm.get("type")
        if etype not in entities:
            warnings.append("unknown entity type %r in %s — skipped" % (etype, rel))
            continue
        fm["_file"] = rel
        entities[etype].append(fm)
    return entities, warnings


def _coerce_impact(value, project_label, warnings):
    """Return strategic_impact as an int 1..5, or None with a warning."""
    if value is None:
        warnings.append("%s has no strategic_impact — omitted from the value summary" % project_label)
        return None
    try:
        impact = int(str(value).strip())
    except (TypeError, ValueError):
        warnings.append("%s has a non-numeric strategic_impact %r — omitted from the value summary" % (project_label, value))
        return None
    if not 1 <= impact <= 5:
        warnings.append("%s strategic_impact %d is outside 1..5 — omitted from the value summary" % (project_label, impact))
        return None
    return impact


def _normalize_open_roles(proj):
    """Return the project's open_roles as a list, or None when undeclared.

    None is the only representation of "fill status unknown", so every way of
    failing to declare roles — key absent, `open_roles:` with no value, an
    explicit null — collapses to the same state. Declaring an empty list stays
    distinct: that is a project asserting it needs nobody, which is a real
    answer rather than a missing one.
    """
    if "open_roles" not in proj:
        return None
    raw = proj["open_roles"]
    if raw is None or (isinstance(raw, str) and not raw.strip()):
        return None
    if not isinstance(raw, list):
        return [raw]
    return raw


def _project_health(filled, open_roles, status):
    """Map (roles filled, declared open_roles, project status) to (label, severity).

    open_roles is None when the project never declared any. Rendering that with
    the same green as a fully staffed project would show an unstaffed project as
    healthy on a partner's decision surface, so it gets its own warn state.
    """
    if status == "closed":
        return ("closed", "muted")
    if open_roles is None:
        return ("staffing unknown", "warn")
    total = len(open_roles)
    if total == 0:
        return ("no open roles", "ok")
    if filled >= total:
        return ("fully staffed", "ok")
    if filled == 0 and status == "active":
        return ("unstaffed", "risk")
    return ("%d/%d roles open" % (total - filled, total), "warn")


def _compute(entities, warnings):
    """Derive per-project staffing + the portfolio value/utilization aggregates.

    Fill status is derived, not stored: for a project's open_roles list, a role
    is "filled" when some planned/active assignment for that project carries a
    matching role label. Role labels are free strings, so a label an assignment
    names that no open_roles entry matches is surfaced as a warning rather than
    silently changing the counts — a visible mismatch is safer than a confident
    wrong number.
    """
    assignments = entities["assignment"]
    projects_out = []
    value_by_impact = {i: 0 for i in range(1, 6)}

    for proj in sorted(entities["project"], key=lambda p: str(p.get("name") or p.get("slug") or "")):
        slug = proj.get("slug")
        label = "project %s" % (proj.get("name") or slug or "(unnamed)")
        # An undeclared open_roles is not an empty one — see _normalize_open_roles.
        declared_roles = _normalize_open_roles(proj)
        open_roles = declared_roles or []
        status = (proj.get("status") or "").strip()
        if declared_roles is None and status != "closed":
            warnings.append("%s has no open_roles — staffing status unknown" % label)

        covered = set()
        for a in assignments:
            if a.get("project") == slug and (a.get("status") or "").strip() in ACTIVE_ASSIGNMENT_STATES:
                role = a.get("role")
                if role:
                    covered.add(role)
        # An assignment role that matches no listed open role may be a label
        # mismatch (erp-lead vs "ERP Lead") — flag it, don't hard-fail.
        for role in sorted(covered):
            if open_roles and role not in open_roles:
                warnings.append(
                    "%s: assignment role %r matches no open_roles label — possible label mismatch" % (label, role)
                )
        filled = [r for r in open_roles if r in covered]
        health_label, health_sev = _project_health(len(filled), declared_roles, status)

        impact = _coerce_impact(proj.get("strategic_impact"), label, warnings)
        if impact is not None:
            value_by_impact[impact] += 1

        projects_out.append({
            "name": proj.get("name") or slug or "(unnamed)",
            "client": proj.get("client") or "",
            "status": status or "unknown",
            "impact": impact,
            "roles_total": len(open_roles),
            "roles_filled": len(filled),
            "open_roles": [r for r in open_roles if r not in covered],
            "health_label": health_label,
            "health_sev": health_sev,
        })

    # Utilization: a simple average of consultant allocation_pct, plus a count of
    # consultants at or above 100%. Consultants with no allocation_pct are
    # excluded from the average rather than counted as zero, so a thinly authored
    # portfolio is not made to look under-allocated. Richer heuristics are out of
    # scope.
    allocations = []
    for c in entities["consultant"]:
        raw = c.get("allocation_pct")
        if raw is None:
            continue
        try:
            allocations.append(int(str(raw).strip()))
        except (TypeError, ValueError):
            warnings.append("consultant %s has a non-numeric allocation_pct %r — omitted from utilization" % (c.get("slug") or "(unknown)", raw))
    util = {
        "consultants": len(entities["consultant"]),
        "with_allocation": len(allocations),
        "avg_allocation": round(sum(allocations) / len(allocations)) if allocations else None,
        "fully_allocated": sum(1 for a in allocations if a >= 100),
    }

    return projects_out, value_by_impact, util


def _esc(value):
    return html.escape(str(value), quote=True)


def _render_html(portfolio, projects, value_by_impact, util, warnings, theme):
    t = theme
    generated = datetime.date.today().isoformat()
    sev_color = {"ok": t["ok"], "warn": t["warn"], "risk": t["risk"], "muted": t["muted"]}

    rows = []
    for p in projects:
        impact = "—" if p["impact"] is None else ("★" * p["impact"])
        coverage = "%d/%d" % (p["roles_filled"], p["roles_total"]) if p["roles_total"] else "—"
        open_roles = ", ".join(_esc(r) for r in p["open_roles"]) if p["open_roles"] else "—"
        rows.append(
            "<tr>"
            "<td><strong>%s</strong><div class='sub'>%s</div></td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td>%s</td>"
            "<td><span class='flag' style='color:%s'>%s</span></td>"
            "</tr>" % (
                _esc(p["name"]), _esc(p["client"]),
                _esc(p["status"]), impact, coverage, open_roles,
                sev_color.get(p["health_sev"], t["text"]), _esc(p["health_label"]),
            )
        )

    value_rows = []
    for impact in range(5, 0, -1):
        count = value_by_impact.get(impact, 0)
        bar = "█" * count
        value_rows.append(
            "<tr><td>%s</td><td>%d</td><td class='bar'>%s</td></tr>"
            % ("★" * impact, count, bar)
        )

    warn_block = ""
    if warnings:
        items = "".join("<li>%s</li>" % _esc(w) for w in warnings)
        warn_block = (
            "<section class='card warnings'><h2>Warnings — partial snapshot "
            "(%d)</h2><ul>%s</ul></section>" % (len(warnings), items)
        )

    avg = "—" if util["avg_allocation"] is None else "%d%%" % util["avg_allocation"]
    total_open = sum(p["roles_total"] - p["roles_filled"] for p in projects)

    return """<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Portfolio dashboard — {name}</title>
<style>
  :root {{ color-scheme: dark; }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: {bg}; color: {text}; font-family: {font}; line-height: 1.5; }}
  .wrap {{ max-width: 1040px; margin: 0 auto; padding: 32px 20px 64px; }}
  header h1 {{ margin: 0 0 4px; font-size: 1.6rem; }}
  header .meta {{ color: {muted}; font-size: 0.9rem; }}
  .tiles {{ display: flex; flex-wrap: wrap; gap: 14px; margin: 22px 0; }}
  .tile {{ flex: 1 1 150px; background: {surface}; border: 1px solid {border};
           border-radius: 10px; padding: 16px; }}
  .tile .n {{ font-size: 1.8rem; font-weight: 700; }}
  .tile .l {{ color: {muted}; font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.04em; }}
  .card {{ background: {surface}; border: 1px solid {border}; border-radius: 10px;
           padding: 18px 20px; margin: 18px 0; overflow-x: auto; }}
  .card h2 {{ margin: 0 0 12px; font-size: 1.05rem; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 0.92rem; }}
  th, td {{ text-align: left; padding: 9px 10px; border-bottom: 1px solid {border}; vertical-align: top; }}
  th {{ color: {muted}; font-weight: 600; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em; }}
  td .sub {{ color: {muted}; font-size: 0.8rem; }}
  .flag {{ font-weight: 600; }}
  .bar {{ color: {accent}; letter-spacing: 1px; }}
  .warnings {{ border-color: {warn}; }}
  .warnings h2 {{ color: {warn}; }}
  .warnings li {{ color: {muted}; font-size: 0.88rem; }}
  footer {{ color: {muted}; font-size: 0.8rem; margin-top: 26px; }}
</style></head>
<body><div class="wrap">
<header>
  <h1>{name}</h1>
  <div class="meta">Partner-meeting portfolio dashboard · generated {generated}</div>
</header>
<div class="tiles">
  <div class="tile"><div class="n">{n_projects}</div><div class="l">Projects</div></div>
  <div class="tile"><div class="n">{n_consultants}</div><div class="l">Consultants</div></div>
  <div class="tile"><div class="n">{open_roles}</div><div class="l">Open roles</div></div>
  <div class="tile"><div class="n">{avg}</div><div class="l">Avg allocation</div></div>
</div>
<section class="card">
  <h2>Projects — staffing &amp; health</h2>
  <table>
    <thead><tr><th>Project</th><th>Status</th><th>Impact</th><th>Roles filled</th><th>Still open</th><th>Health</th></tr></thead>
    <tbody>{rows}</tbody>
  </table>
</section>
<section class="card">
  <h2>Portfolio value — projects by strategic impact</h2>
  <table>
    <thead><tr><th>Impact</th><th>Projects</th><th></th></tr></thead>
    <tbody>{value_rows}</tbody>
  </table>
</section>
{warn_block}
<footer>cogni-projects · read-only render · {generated}</footer>
</div></body></html>
""".format(
        name=_esc(portfolio.get("name") or portfolio.get("slug") or "Portfolio"),
        generated=generated,
        bg=t["bg"], surface=t["surface"], text=t["text"],
        muted=t["muted"], accent=t["accent"], border=t["border"],
        ok=t["ok"], warn=t["warn"], risk=t["risk"], font=t["font"],
        n_projects=len(projects),
        n_consultants=util["consultants"],
        open_roles=total_open,
        avg=avg,
        rows="".join(rows) or "<tr><td colspan='6'>No projects yet.</td></tr>",
        value_rows="".join(value_rows),
        warn_block=warn_block,
    )


def _fail(message, code=2):
    print(json.dumps({"success": False, "data": {}, "error": message}, ensure_ascii=False))
    return code


def main(argv):
    ap = argparse.ArgumentParser(
        description="Render a cogni-projects partner-meeting portfolio dashboard.",
    )
    ap.add_argument("portfolio_dir")
    ap.add_argument("--design-variables", dest="design_variables", default=None)
    # argparse raises SystemExit on a usage error, and SystemExit is a
    # BaseException — the top-level `except Exception` would not catch it, so a
    # caller parsing stdout would get nothing at all. Convert it to the envelope
    # every path in this repo is contracted to print.
    try:
        args = ap.parse_args(argv)
    except SystemExit as exc:
        # --help exits 0 having already printed help; that is a success path and
        # must not be dressed up as a failure envelope.
        if exc.code == 0:
            return 0
        # Derived from the parser rather than restated, so adding an argument
        # cannot leave this message describing an older signature.
        return _fail(ap.format_usage().strip())

    portfolio_dir = os.path.abspath(args.portfolio_dir)
    if not os.path.isdir(portfolio_dir):
        return _fail("portfolio directory not found: %s" % portfolio_dir)

    manifest_path = os.path.join(portfolio_dir, "projects-portfolio.json")
    if not os.path.isfile(manifest_path):
        return _fail(
            "portfolio manifest not found: %s (run /cogni-projects:projects-setup first)"
            % manifest_path
        )

    warnings = []
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            portfolio = json.load(f)
    except (OSError, ValueError) as exc:
        return _fail("cannot read portfolio manifest: %s" % exc)

    theme, theme_warning = _load_theme(args.design_variables)
    if theme_warning:
        warnings.append(theme_warning)

    entities, read_warnings = _read_entities(portfolio_dir)
    warnings.extend(read_warnings)
    projects, value_by_impact, util = _compute(entities, warnings)

    out_dir = os.path.join(portfolio_dir, "output")
    try:
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "dashboard.html")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(_render_html(portfolio, projects, value_by_impact, util, warnings, theme))
    except OSError as exc:
        return _fail("cannot write dashboard: %s" % exc)

    print(json.dumps({
        "success": True,
        "data": {
            "path": out_path,
            "portfolio": portfolio.get("slug") or "",
            "projects": len(projects),
            "consultants": util["consultants"],
            "avg_allocation": util["avg_allocation"],
            "fully_allocated": util["fully_allocated"],
            "open_roles": sum(p["roles_total"] - p["roles_filled"] for p in projects),
            "warnings": warnings,
            "partial": bool(warnings),
        },
        "error": "",
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    # Same envelope contract as the sibling scripts: a hand-edited manifest or
    # entity of the wrong shape must report as a readable failure, never a
    # traceback that breaks the {success,data,error} contract mid-render.
    try:
        _code = main(sys.argv[1:])
    except Exception as _exc:  # noqa: BLE001 — deliberate catch-all
        _code = _fail("unexpected failure: %s: %s" % (type(_exc).__name__, _exc))
    sys.exit(_code)
