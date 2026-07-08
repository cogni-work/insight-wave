#!/usr/bin/env python3
"""Generate an Obsidian-browsable README.md front door at a cogni-consult
engagement root.

Reads the same read model as engagement-status.sh and
skills/consult-dashboard/scripts/generate-dashboard.py — consult-project.json
plus each action-fields/<slug>/field.json, with deliverable state as the
single source of truth and field/engagement rollups derived at read time —
and writes <engagement-dir>/README.md with four sections:

  1. H1 engagement name + SMART key question
  2. Status snapshot — scope state, per-field done/total, overall completion %
  3. The single next recommended deliverable (next-action derivation with the
     personas_gate step spliced in after staleness, before in-progress work)
  4. A wayfinding link block with relative Obsidian links (only to targets
     that exist, so a scaffold-only engagement emits no broken links)

Read-only over all engagement state except the README.md it writes.

Usage: python3 generate-engagement-readme.py <engagement-dir>
Output: JSON {"success": bool, "data": {...}, "error": "string"}
"""

import argparse
import json
import os
import subprocess
import sys


# ---------------------------------------------------------------------------
# Engagement read model — mirrors engagement-status.sh and the consult-dashboard
# generator. Deliverable state lives only in field.json; rollups derive here.
# ---------------------------------------------------------------------------


def _field_rollup(states):
    if states and all(s == "complete" for s in states):
        return "complete"
    if any(s != "pending" for s in states):
        return "in-progress"
    return "pending"


def load_engagement(engagement_dir):
    """Return the engagement model, or raise ValueError with a user-facing message."""
    proj_path = os.path.join(engagement_dir, "consult-project.json")
    try:
        with open(proj_path) as f:
            project = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        raise ValueError(f"unreadable engagement file {proj_path}: {exc}")

    field_slugs = project.get("action_fields") or []
    if not isinstance(field_slugs, list) or not all(isinstance(s, str) for s in field_slugs):
        raise ValueError("malformed engagement file: action_fields must be a list of strings")

    warnings = []
    fields = []
    for slug in field_slugs:
        fpath = os.path.join(engagement_dir, "action-fields", slug, "field.json")
        title = slug
        deliverables = []
        state = "pending"
        try:
            with open(fpath) as f:
                fjson = json.load(f)
            title = fjson.get("title") or slug
            deliverables = fjson.get("deliverables") or []
            state = _field_rollup([d.get("state", "pending") for d in deliverables])
        except FileNotFoundError:
            pass
        except (json.JSONDecodeError, OSError) as exc:
            state = "unreadable"
            warnings.append(f"unreadable field file {fpath}: {exc}")
        fields.append({
            "slug": slug,
            "title": title,
            "state": state,
            "deliverables": deliverables,
        })

    return {
        "slug": project.get("slug"),
        "name": project.get("name") or project.get("slug") or "Engagement",
        "key_question": project.get("key_question") or "",
        "updated": project.get("updated") or "",
        "scope_state": (project.get("workflow_state") or {}).get("scope", "pending"),
        "action_fields": fields,
        "warnings": warnings,
    }


def compute_summary(eng):
    fields = eng["action_fields"]
    all_delivs = [d for f in fields for d in f["deliverables"]]
    total = len(all_delivs)
    complete = sum(1 for d in all_delivs if d.get("state", "pending") == "complete")
    pct = round(100 * complete / total) if total else 0
    if all(f["state"] == "complete" for f in fields) and fields:
        engagement_state = "complete"
    elif any(f["state"] != "pending" for f in fields):
        engagement_state = "in-progress"
    else:
        engagement_state = "pending"
    return {
        "deliverables_total": total,
        "deliverables_complete": complete,
        "completion_pct": pct,
        "engagement_state": engagement_state,
    }


def load_personas_gate(engagement_dir):
    """Derive the personas_gate rollup at read time, mirroring
    engagement-status.sh: satisfied when personas/.gate-waiver exists or any
    personas/*.json carries source == "scope-seeded"; else pending. Fail-soft:
    a missing or unreadable personas dir / persona file degrades to pending."""
    personas_dir = os.path.join(engagement_dir, "personas")
    if os.path.exists(os.path.join(personas_dir, ".gate-waiver")):
        return "satisfied"
    try:
        for name in os.listdir(personas_dir):
            if not name.endswith(".json"):
                continue
            try:
                with open(os.path.join(personas_dir, name)) as pf:
                    if json.load(pf).get("source") == "scope-seeded":
                        return "satisfied"
            except (json.JSONDecodeError, OSError):
                continue
    except OSError:
        pass
    return "pending"


# ---------------------------------------------------------------------------
# Staleness + refresh order — the read side of the deliverable-graph engine.
# ---------------------------------------------------------------------------


def _is_stale_deliv(d):
    ls = d.get("lineage_status")
    return isinstance(ls, dict) and ls.get("status") == "stale"


def build_deliv_index(eng):
    """Map each deliverable's WBS-coordinate key 'field_slug/deliv_slug' to its
    display title, so refresh-order layers (which speak in keys) render titles."""
    idx = {}
    for f in eng["action_fields"]:
        for d in f["deliverables"]:
            slug = d.get("slug")
            if not slug:
                continue
            idx[f"{f['slug']}/{slug}"] = d.get("title") or slug
    return idx


def load_refresh_order(engagement_dir):
    """Shell out to the sibling deliverable-graph engine for the topological
    refresh order of stale deliverables; None on any failure (graceful)."""
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "deliverable-graph.py")
    if not os.path.isfile(script):
        return None
    try:
        proc = subprocess.run(
            [sys.executable, script, engagement_dir, "refresh-order"],
            capture_output=True, text=True, timeout=30,
        )
        payload = json.loads(proc.stdout)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    if not isinstance(payload, dict) or not payload.get("success"):
        return None
    data = payload.get("data")
    return data if isinstance(data, dict) else None


def next_action(eng, summary, personas_gate, engagement_dir):
    """The single recommendation as (rung, text). Precedence: scope-incomplete,
    then the stale set upstream-first, then the personas gate, then in-progress,
    then pending — the personas gate blocks *starting* deliverable work, so it
    sits after refreshing what an upstream change invalidated and before picking
    up new or continuing work. The rung enum ("scope" / "refresh" / "personas" /
    "continue" / "start" / "plan" / "publish" / "done" / "review") is the
    machine-readable surface consumers key on; the text is display-only."""
    if eng["scope_state"] != "complete":
        return "scope", "Finish scoping the engagement (consult-scope) — define the SMART key question and action fields."
    stale = [d for f in eng["action_fields"] for d in f["deliverables"] if _is_stale_deliv(d)]
    if stale:
        refresh = load_refresh_order(engagement_dir)
        deliv_index = build_deliv_index(eng)
        first_title = None
        if refresh and refresh.get("layers"):
            for layer in refresh["layers"]:
                if layer:
                    first_title = deliv_index.get(layer[0], layer[0])
                    break
        if not first_title:
            first_title = stale[0].get("title") or stale[0].get("slug")
        n = len(stale)
        plural = "deliverable" if n == 1 else "deliverables"
        return "refresh", (
            f"{n} {plural} went stale after an upstream change — refresh "
            f"“{first_title}” first, then work down the refresh order (upstream "
            f"before dependents)."
        )
    if personas_gate != "satisfied":
        return "personas", "Seed acting stakeholder personas from scope (consult-personas) — the personas gate blocks the first design-thinking deliverable."
    for f in eng["action_fields"]:
        for d in f["deliverables"]:
            if d.get("state", "pending") == "in-progress":
                stage = d.get("dt_stage") or "empathize"
                return "continue", f"Continue “{d.get('title', d.get('slug'))}” in {f['title']} (design thinking, {stage} stage)."
    for f in eng["action_fields"]:
        for d in f["deliverables"]:
            if d.get("state", "pending") == "pending":
                return "start", f"Start “{d.get('title', d.get('slug'))}” in {f['title']} (consult-design-thinking)."
        if not f["deliverables"] and f["state"] != "unreadable":
            return "plan", f"Plan deliverables for {f['title']} (consult-action-fields)."
    if summary["engagement_state"] == "complete":
        unpublished = [
            d
            for f in eng["action_fields"]
            for d in f["deliverables"]
            if d.get("state") == "complete" and not (d.get("publish") or [])
        ]
        if unpublished:
            first = unpublished[0]
            title = first.get("title") or first.get("slug")
            return "publish", f"All deliverables complete — publish “{title}” with consult-publish."
        return "done", "All deliverables complete and published — hand the briefs to Claude Design to render."
    return "review", "Review the engagement status."


# ---------------------------------------------------------------------------
# Markdown rendering — relative Obsidian links, emitted only when the target
# exists so a scaffold-only engagement never carries a broken link.
# ---------------------------------------------------------------------------

STATE_LABEL = {"in-progress": "in progress"}


def _md_cell(s):
    """Escape a value for a markdown table cell (pipes split columns)."""
    return str(s if s is not None else "").replace("|", "\\|")


def _md_label(s):
    """Escape a value for a markdown link label (brackets break the link)."""
    return str(s if s is not None else "").replace("[", "\\[").replace("]", "\\]")


def _link_if_exists(engagement_dir, rel_path, label):
    """Markdown link when the relative target exists, else None."""
    if os.path.exists(os.path.join(engagement_dir, rel_path)):
        return f"[{_md_label(label)}]({rel_path})"
    return None


def render_readme(engagement_dir, eng, summary, action):
    lines = [f"# {eng['name']}"]
    if eng["key_question"]:
        lines += ["", f"> {eng['key_question']}"]

    # Status snapshot — "scoping" is the user-facing label until scope completes.
    lines += ["", "## Status", ""]
    scope_label = "complete" if eng["scope_state"] == "complete" else "scoping"
    lines.append(f"- **Scope:** {scope_label}")
    lines.append(f"- **Overall completion:** {summary['completion_pct']}% "
                 f"({summary['deliverables_complete']}/{summary['deliverables_total']} deliverables)")
    if eng["action_fields"]:
        lines += ["", "| Action field | Done | State |", "|---|---|---|"]
        for f in eng["action_fields"]:
            done = sum(1 for d in f["deliverables"] if d.get("state", "pending") == "complete")
            total = len(f["deliverables"])
            lines.append(f"| {_md_cell(f['title'])} | {done}/{total} | {STATE_LABEL.get(f['state'], f['state'])} |")
    if eng["warnings"]:
        lines += ["", "> ⚠ " + " · ".join(_md_cell(w) for w in eng["warnings"])]

    lines += ["", "## Next", "", action]

    # Wayfinding — every link resolves within the engagement dir by construction.
    way = []
    for f in eng["action_fields"]:
        field_rel = os.path.join("action-fields", f["slug"])
        field_link = _link_if_exists(engagement_dir, field_rel, f["title"])
        if not field_link:
            continue
        way.append(f"- {field_link}")
        for d in f["deliverables"]:
            dslug = d.get("slug")
            if not dslug:
                continue
            deliv_link = _link_if_exists(
                engagement_dir,
                os.path.join(field_rel, f"{dslug}.md"),
                d.get("title") or dslug,
            )
            if deliv_link:
                way.append(f"  - {deliv_link}")
    for rel, label in (
        ("personas", "Personas"),
        ("sources", "Sources"),
        (os.path.join(".metadata", "decision-log.json"), "Decision log"),
    ):
        link = _link_if_exists(engagement_dir, rel, label)
        if link:
            way.append(f"- {link}")
    if way:
        lines += ["", "## Wayfinding", ""] + way

    lines += ["", "---", "", "_Auto-generated front door — regenerated at engagement milestones; edits here are overwritten._", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate the engagement README.md front door")
    parser.add_argument("engagement_dir", help="Path to the engagement directory")
    args = parser.parse_args()

    try:
        eng = load_engagement(args.engagement_dir)
        summary = compute_summary(eng)
        personas_gate = load_personas_gate(args.engagement_dir)
        rung, action = next_action(eng, summary, personas_gate, args.engagement_dir)
        readme = render_readme(args.engagement_dir, eng, summary, action)
        readme_path = os.path.join(args.engagement_dir, "README.md")
        with open(readme_path, "w") as f:
            f.write(readme)
    except (ValueError, OSError, TypeError, AttributeError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": f"malformed engagement state: {exc}"}))
        return 1

    print(json.dumps({
        "success": True,
        "data": {
            "readme_path": readme_path,
            "completion_pct": summary["completion_pct"],
            "engagement_state": summary["engagement_state"],
            "personas_gate": personas_gate,
            "next_action_rung": rung,
            "next_action": action,
            "warnings": eng["warnings"],
        },
        "error": "",
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
