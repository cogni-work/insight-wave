#!/usr/bin/env bash
# inspect-taxonomy.sh — Pretty-print the resolved project-local taxonomy as a
# structured JSON snapshot: dimension tree, category counts, search-pattern
# coverage per category, product-skeleton coverage per dimension. Read-only.
#
# Why this exists: portfolio-taxonomy creates a 7-file bundle but offers no
# user-facing way to ask "what does my taxonomy look like?". Users had to read
# template.md + categories.json + search-patterns.md + product-template.md in
# their head. This script delivers the same picture in a single JSON payload
# the calling skill prints back as a readable tree, and is reused by edit/
# validate modes to print "before"/"after" snapshots without re-implementing
# the traversal.
#
# Usage:
#   inspect-taxonomy.sh <project_path>
#
# Output (stdout, single JSON object):
#   {"success": true,  "data": {...}}   on success
#   {"success": false, "error": "..."}  on any failure (exit 1)
#
# Contract:
# - Read-only. Never writes files.
# - Reads <project_path>/taxonomy/{template.md,categories.json,search-patterns.md,product-template.md}.
# - Returns: type, version (from template.md frontmatter), dimensions[] (each with
#   id, name, slug, category_count, categories[]), counts{dimensions,categories,
#   service_dimensions,service_categories}, coverage{search_patterns_per_category,
#   uncovered_category_ids,product_skeleton_per_service_dim,dimensions_without_product},
#   gaps[].
# - Stdlib only (bash + python3).

set -euo pipefail

die() {
  printf '{"success":false,"error":"%s"}\n' "$1"
  exit 1
}

[ $# -ge 1 ] || die "usage: inspect-taxonomy.sh <project_path>"

PROJECT_PATH="$1"
TAX_DIR="$PROJECT_PATH/taxonomy"

[ -d "$PROJECT_PATH" ] || die "project_path not found: $PROJECT_PATH"
[ -d "$TAX_DIR" ]      || die "no project-local taxonomy at $TAX_DIR (run cogni-portfolio:portfolio-taxonomy first)"

python3 - "$PROJECT_PATH" "$TAX_DIR" <<'PY'
import json, os, re, sys

project_path, tax_dir = sys.argv[1], sys.argv[2]

def read(name):
    p = os.path.join(tax_dir, name)
    if not os.path.isfile(p):
        return None
    with open(p) as f:
        return f.read()

def parse_frontmatter(body):
    if body is None:
        return {}
    m = re.match(r"^---\n(.*?)\n---", body, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^([a-zA-Z0-9_-]+)\s*:\s*(.*)$", line)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip().strip('"').strip("'")
    return fm

# Load source artifacts
tpl_fm = parse_frontmatter(read("template.md"))
cats_raw = read("categories.json")
sp_body  = read("search-patterns.md") or ""
pt_body  = read("product-template.md") or ""

categories = []
if cats_raw is not None:
    try:
        categories = json.loads(cats_raw)
        if not isinstance(categories, list):
            categories = []
    except json.JSONDecodeError:
        categories = []

# Group categories by dimension
by_dim = {}
for c in categories:
    if not isinstance(c, dict):
        continue
    dim = c.get("dimension")
    if dim is None:
        continue
    by_dim.setdefault(int(dim), []).append(c)

# Per-category search-pattern presence (token-bounded match, same regex shape
# the validator uses so the two stay in sync).
def has_pattern(cid):
    if not cid:
        return False
    pat = rf"(?<![\d.]){re.escape(cid)}(?![\d.])"
    return bool(re.search(pat, sp_body))

# Per-service-dimension product-skeleton presence. The product table uses
# `kebab-case-slug` cells; a dimension is considered covered if its
# dimension_slug appears as a slug in product-template.md. Heuristic only —
# product-template.md is markdown, not JSON.
def dim_has_product(dim_slug):
    if not dim_slug:
        return False
    pat = rf"`{re.escape(dim_slug)}`"
    return bool(re.search(pat, pt_body))

dimensions_out = []
for dim_num in sorted(by_dim.keys()):
    rows = by_dim[dim_num]
    # Use first row's metadata for dimension_name / dimension_slug
    first = rows[0]
    dim_name = first.get("dimension_name", f"Dimension {dim_num}")
    dim_slug = first.get("dimension_slug", "")
    cats_out = []
    for c in rows:
        cid = str(c.get("id", "")).strip()
        cats_out.append({
            "id": cid,
            "name": c.get("name", ""),
            "has_search_pattern": has_pattern(cid),
        })
    dimensions_out.append({
        "id": dim_num,
        "name": dim_name,
        "slug": dim_slug,
        "is_service_dimension": dim_num != 0,
        "category_count": len(rows),
        "has_product": dim_has_product(dim_slug) if dim_num != 0 else None,
        "categories": cats_out,
    })

# Totals + coverage summary
service_dims = [d for d in dimensions_out if d["is_service_dimension"]]
service_cats = sum(d["category_count"] for d in service_dims)
total_cats = len(categories)
covered_cats = sum(1 for d in dimensions_out for c in d["categories"] if c["has_search_pattern"])
uncovered_ids = [c["id"] for d in dimensions_out for c in d["categories"] if not c["has_search_pattern"]]
dims_without_product = [
    {"id": d["id"], "name": d["name"], "slug": d["slug"]}
    for d in service_dims if d["has_product"] is False
]

# Gap surface — high-signal flags the calling skill prints first
gaps = []
if uncovered_ids:
    sample = ", ".join(uncovered_ids[:5])
    more = f" (+{len(uncovered_ids)-5} more)" if len(uncovered_ids) > 5 else ""
    gaps.append(f"{len(uncovered_ids)} categories without a search pattern: {sample}{more}")
if dims_without_product:
    names = ", ".join(d["name"] for d in dims_without_product)
    gaps.append(f"{len(dims_without_product)} service dimension(s) without a product entry: {names}")
if not service_dims:
    gaps.append("no service dimensions found (only Dimension 0 — taxonomy has no offerings to scan)")
elif len(service_dims) < 4:
    gaps.append(f"only {len(service_dims)} service dimensions — author-mode guidance is 5–7 (4 is the floor)")
elif len(service_dims) > 8:
    gaps.append(f"{len(service_dims)} service dimensions — author-mode guidance caps at 8 (signal dilutes above)")
for d in service_dims:
    if d["category_count"] < 4:
        gaps.append(f"dimension {d['id']} ({d['name']}) has only {d['category_count']} categories — guidance is 4–10")
    elif d["category_count"] > 10:
        gaps.append(f"dimension {d['id']} ({d['name']}) has {d['category_count']} categories — guidance is 4–10 (consider splitting)")

# Frontmatter sanity — surface mismatch between declared and actual counts
fm_dims = tpl_fm.get("dimensions")
fm_cats = tpl_fm.get("categories")
counts = {
    "dimensions": len(dimensions_out),
    "categories": total_cats,
    "service_dimensions": len(service_dims),
    "service_categories": service_cats,
    "frontmatter_dimensions": fm_dims,
    "frontmatter_categories": fm_cats,
}
if fm_dims is not None and str(fm_dims) != str(len(dimensions_out)):
    gaps.append(f"template.md frontmatter says dimensions={fm_dims}, actual={len(dimensions_out)}")
if fm_cats is not None and str(fm_cats) != str(total_cats):
    gaps.append(f"template.md frontmatter says categories={fm_cats}, actual={total_cats}")

result = {
    "project_path": project_path,
    "taxonomy_dir": tax_dir,
    "type": tpl_fm.get("type"),
    "version": tpl_fm.get("version"),
    "industry_match": tpl_fm.get("industry_match"),
    "dimensions": dimensions_out,
    "counts": counts,
    "coverage": {
        "categories_with_search_pattern": covered_cats,
        "categories_without_search_pattern": len(uncovered_ids),
        "uncovered_category_ids": uncovered_ids,
        "service_dimensions_with_product": sum(1 for d in service_dims if d["has_product"]),
        "service_dimensions_without_product": dims_without_product,
    },
    "gaps": gaps,
}

print(json.dumps({"success": True, "data": result}))
PY
