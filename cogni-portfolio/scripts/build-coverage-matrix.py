#!/usr/bin/env python3
"""Build a cross-scan taxonomy coverage matrix from N research-only scan outputs.

Reads one or more `research/.metadata/scan-output.json` files (typically produced
by `portfolio-scan --mode=research-only`), parses the associated markdown reports
for per-category `[Status: X]` tags, and emits:

- `research/consolidated-{scope-slug}-portfolio.md` — markdown pivot table
  {company × category_id} with cells ✓ (Confirmed = any non-"Not Offered" status)
  or — (Not Offered / not reported), grouped by taxonomy dimension, plus a
  per-category coverage-rate column.
- `research/.metadata/consolidated-{scope-slug}.json` — machine-readable matrix
  + per-category counts for downstream consumers (portfolio-dashboard in Phase 2+).

Phase 1 scope: two cell states (Confirmed / Not Offered); Emerging and Extended
roll into Confirmed in the display. Refuses on mismatched `template_type` across
inputs. Stdlib only.

Example:
    python3 build-coverage-matrix.py \\
        --inputs "project/research/.metadata/scan-output.json" \\
                 "peer-a/research/.metadata/scan-output.json" \\
        --scope-slug "ict-peer-set" \\
        --output-dir "project/research" \\
        --taxonomy-dir "cogni-portfolio/templates/b2b-ict"
"""

import argparse
import datetime as _dt
import json
import os
import re
import sys


STATUS_RE = re.compile(r"^###\s+(\d+\.\d+)\s+.*\[Status:\s*([^\]]+)\]", re.MULTILINE)
NOT_OFFERED = "Not Offered"


def _respond(success, data=None, error=None, exit_code=None):
    payload = {"success": bool(success)}
    if data is not None:
        payload["data"] = data
    if error is not None:
        payload["error"] = error
    sys.stdout.write(json.dumps(payload))
    sys.stdout.write("\n")
    sys.exit(0 if exit_code is None and success else (1 if exit_code is None else exit_code))


def _load_json(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh), None
    except FileNotFoundError:
        return None, "file not found"
    except json.JSONDecodeError as exc:
        return None, f"malformed JSON: {exc}"
    except OSError as exc:
        return None, f"read error: {exc}"


def _parse_report(report_path):
    """Return a dict {category_id: status} parsed from a scan report markdown."""
    try:
        with open(report_path, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        return {}
    statuses = {}
    for match in STATUS_RE.finditer(text):
        cat_id, status = match.group(1), match.group(2).strip()
        statuses[cat_id] = status
    return statuses


def _load_scan(scan_output_path):
    """Load one scan-output.json + its report; return (dict, error)."""
    raw, err = _load_json(scan_output_path)
    if err:
        return None, f"{scan_output_path}: {err}"
    if not isinstance(raw, dict):
        return None, f"{scan_output_path}: top-level is not an object"

    template_type = raw.get("template_type")
    if not template_type:
        return None, f"{scan_output_path}: missing `template_type`"

    # The report lives relative to the scan's project root (two dirs up from
    # research/.metadata/scan-output.json).
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(scan_output_path))))
    output_file = raw.get("output_file", "")
    report_path = os.path.join(project_root, output_file) if output_file else None
    statuses = _parse_report(report_path) if report_path and os.path.isfile(report_path) else {}

    return {
        "scan_output_path": scan_output_path,
        "company_name": raw.get("company_name") or raw.get("company_slug") or "",
        "company_slug": raw.get("company_slug", ""),
        "template_type": template_type,
        "consolidation_mode": raw.get("consolidation_mode", "consolidate"),
        "created": raw.get("created", ""),
        "report_path": report_path,
        "statuses": statuses,
    }, None


def _load_taxonomy(taxonomy_dir):
    """Return (categories_list, error). Each item: {id, name, dimension, dimension_name, dimension_slug}."""
    path = os.path.join(taxonomy_dir, "categories.json")
    raw, err = _load_json(path)
    if err:
        return None, f"{path}: {err}"
    if not isinstance(raw, list):
        return None, f"{path}: expected a JSON array"
    return raw, None


def _render_markdown(scans, categories, template_type, scope_slug):
    """Build the consolidated markdown report."""
    now = _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    providers = [s["company_name"] for s in scans]

    lines = []
    lines.append(f"# Consolidated coverage matrix — {scope_slug}")
    lines.append("")
    lines.append(f"- **Generated:** {now}")
    lines.append(f"- **Template:** `{template_type}`")
    lines.append(f"- **Providers ({len(providers)}):** {', '.join(providers)}")
    lines.append(f"- **Categories:** {len(categories)}")
    lines.append("")
    lines.append("Each cell marks whether the provider's scan report declared a non-`Not Offered` status for that category. `✓` = Confirmed (includes Emerging / Extended per Phase 1 collapse); `—` = Not Offered or not reported. Coverage rate counts `✓` cells over the provider set.")
    lines.append("")

    # Group categories by dimension for readable section breaks.
    by_dimension = {}
    dim_order = []
    for cat in categories:
        dim_key = (cat.get("dimension"), cat.get("dimension_name", ""))
        if dim_key not in by_dimension:
            by_dimension[dim_key] = []
            dim_order.append(dim_key)
        by_dimension[dim_key].append(cat)

    confirmed_cells = 0
    per_category_counts = {}

    for dim_key in dim_order:
        dim_num, dim_name = dim_key
        lines.append(f"## Dimension {dim_num} — {dim_name}")
        lines.append("")
        header = ["Category"] + providers + ["Coverage"]
        lines.append("| " + " | ".join(header) + " |")
        lines.append("| " + " | ".join(["---"] * len(header)) + " |")
        for cat in by_dimension[dim_key]:
            cat_id = cat.get("id", "")
            cat_name = cat.get("name", "")
            row = [f"`{cat_id}` {cat_name}"]
            covered = 0
            for s in scans:
                status = s["statuses"].get(cat_id, NOT_OFFERED)
                is_covered = status.strip().lower() != NOT_OFFERED.strip().lower()
                row.append("✓" if is_covered else "—")
                if is_covered:
                    covered += 1
                    confirmed_cells += 1
            rate = f"{covered}/{len(scans)}"
            row.append(rate)
            per_category_counts[cat_id] = {
                "name": cat_name,
                "dimension": dim_num,
                "covered": covered,
                "total": len(scans),
            }
            lines.append("| " + " | ".join(row) + " |")
        lines.append("")

    return "\n".join(lines), confirmed_cells, per_category_counts


def cmd_build(args):
    input_paths = [p for p in args.inputs if p]
    if len(input_paths) < 1:
        _respond(False, error="no inputs provided")

    scans = []
    mismatches = []
    template_type = None
    for path in input_paths:
        scan, err = _load_scan(path)
        if err:
            _respond(False, error=err)
        if template_type is None:
            template_type = scan["template_type"]
        elif scan["template_type"] != template_type:
            mismatches.append({
                "file": scan["scan_output_path"],
                "template_type": scan["template_type"],
            })
        scans.append(scan)

    if mismatches:
        _respond(
            False,
            error=(
                "template_type mismatch — cannot consolidate across different taxonomies. "
                f"Expected `{template_type}`; offenders: "
                + "; ".join(f"{m['file']}=`{m['template_type']}`" for m in mismatches)
            ),
        )

    categories, err = _load_taxonomy(args.taxonomy_dir)
    if err:
        _respond(False, error=err)

    markdown, confirmed_cells, per_category = _render_markdown(
        scans, categories, template_type, args.scope_slug
    )

    md_path = os.path.join(args.output_dir, f"consolidated-{args.scope_slug}-portfolio.md")
    meta_path = os.path.join(args.output_dir, ".metadata", f"consolidated-{args.scope_slug}.json")
    try:
        os.makedirs(os.path.dirname(md_path), exist_ok=True)
        os.makedirs(os.path.dirname(meta_path), exist_ok=True)
        with open(md_path, "w", encoding="utf-8") as fh:
            fh.write(markdown)
            if not markdown.endswith("\n"):
                fh.write("\n")
        meta = {
            "version": "1.0.0",
            "scope_slug": args.scope_slug,
            "template_type": template_type,
            "generated": _dt.datetime.now(_dt.timezone.utc).isoformat(
                timespec="seconds"
            ).replace("+00:00", "Z"),
            "providers": [
                {
                    "company_name": s["company_name"],
                    "company_slug": s["company_slug"],
                    "scan_output": s["scan_output_path"],
                    "consolidation_mode": s["consolidation_mode"],
                    "created": s["created"],
                }
                for s in scans
            ],
            "providers_count": len(scans),
            "categories_count": len(categories),
            "confirmed_cells": confirmed_cells,
            "per_category": per_category,
        }
        with open(meta_path, "w", encoding="utf-8") as fh:
            json.dump(meta, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
    except OSError as exc:
        _respond(False, error=f"write failed: {exc}")

    _respond(True, {
        "markdown_path": md_path,
        "metadata_path": meta_path,
        "providers_count": len(scans),
        "categories_count": len(categories),
        "confirmed_cells": confirmed_cells,
        "template_type": template_type,
    })


def build_parser():
    p = argparse.ArgumentParser(
        description="Build a cross-scan taxonomy coverage matrix from research-only scan outputs.",
    )
    p.add_argument(
        "--inputs",
        nargs="+",
        required=True,
        metavar="SCAN_OUTPUT_JSON",
        help="One or more paths to research/.metadata/scan-output.json files.",
    )
    p.add_argument("--scope-slug", required=True, help="Slug used in output filenames (e.g. 'ict-peer-set').")
    p.add_argument("--output-dir", required=True, help="Directory where consolidated-*.md is written (usually research/).")
    p.add_argument("--taxonomy-dir", required=True, help="Taxonomy template dir containing categories.json (e.g. cogni-portfolio/templates/b2b-ict).")
    p.set_defaults(func=cmd_build)
    return p


def main():
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
