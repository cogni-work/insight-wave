#!/usr/bin/env bash
# validate-taxonomy.sh — Validate the project-local taxonomy bundle created by
# portfolio-taxonomy (clone, author, or import mode).
#
# Why this exists: clone mode copies a known-good bundled template and the
# structure is guaranteed by the source. Author/import modes produce files
# from user input, which can drift from the expected shape in silent,
# scan-breaking ways — missing a required file, mismatching category ids
# between categories.json and search-patterns.md, forgetting to set
# taxonomy.source_path in portfolio.json. This script catches those before
# the next scan dispatches 150+ web searches against a broken taxonomy.
#
# Usage:
#   validate-taxonomy.sh <project_path>
#
# Output (stdout, single JSON object):
#   {"success": true,  "data": {...}}   all checks passed
#   {"success": false, "error": "...", "data": {"checks": [...]}}  some failed
#
# Exit code: 0 on full pass, 1 on any check failure (so the skill can short-circuit).

set -euo pipefail

die() {
  # Print error and exit — keep data payload if we have one
  local msg="$1"
  local data="${2:-}"
  if [ -n "$data" ]; then
    printf '{"success":false,"error":"%s","data":%s}\n' "$msg" "$data"
  else
    printf '{"success":false,"error":"%s"}\n' "$msg"
  fi
  exit 1
}

[ $# -ge 1 ] || die "usage: validate-taxonomy.sh <project_path>"

PROJECT_PATH="$1"
TAX_DIR="$PROJECT_PATH/taxonomy"
PORTFOLIO_JSON="$PROJECT_PATH/portfolio.json"

[ -d "$PROJECT_PATH" ]   || die "project_path not found: $PROJECT_PATH"
[ -f "$PORTFOLIO_JSON" ] || die "portfolio.json not found: $PORTFOLIO_JSON"
[ -d "$TAX_DIR" ]        || die "no project-local taxonomy at $TAX_DIR (run cogni-portfolio:portfolio-taxonomy first)"

# All validation logic runs in python3 — stdlib only. Collect every check's
# result into an array, decide pass/fail from the collection, emit JSON.
python3 - "$PROJECT_PATH" "$TAX_DIR" "$PORTFOLIO_JSON" <<'PY'
import json, os, re, sys

project_path, tax_dir, portfolio_json_path = sys.argv[1], sys.argv[2], sys.argv[3]
checks = []

def record(name, ok, detail=""):
    checks.append({"name": name, "ok": ok, "detail": detail})

# Check 1 — canonical file presence
canonical = [
    "template.md",
    "categories.json",
    "search-patterns.md",
    "product-template.md",
    "cross-category-rules.md",
    "provider-unit-rules.md",
    "report-template.md",
]
missing_files = [f for f in canonical if not os.path.isfile(os.path.join(tax_dir, f))]
if missing_files:
    record("canonical_files", False, f"missing: {', '.join(missing_files)}")
else:
    record("canonical_files", True, f"all {len(canonical)} canonical files present")

# Check 2 — template.md frontmatter has required fields
tpl_path = os.path.join(tax_dir, "template.md")
tpl_type = None
if os.path.isfile(tpl_path):
    with open(tpl_path) as f:
        body = f.read()
    m = re.match(r"^---\n(.*?)\n---", body, re.DOTALL)
    if not m:
        record("template_frontmatter", False, "template.md has no YAML frontmatter")
    else:
        fm = m.group(1)
        required = ["type", "version", "dimensions", "categories"]
        missing_fm = [k for k in required if not re.search(rf"^{k}\s*:", fm, re.MULTILINE)]
        if missing_fm:
            record("template_frontmatter", False, f"missing frontmatter fields: {', '.join(missing_fm)}")
        else:
            record("template_frontmatter", True, "type, version, dimensions, categories all present")
        tm = re.search(r"^type\s*:\s*(.+)$", fm, re.MULTILINE)
        if tm:
            tpl_type = tm.group(1).strip().strip('"').strip("'")
else:
    record("template_frontmatter", False, "template.md missing — cannot validate frontmatter")

# Check 3 — categories.json is valid and non-empty
cat_path = os.path.join(tax_dir, "categories.json")
categories = []
if os.path.isfile(cat_path):
    try:
        with open(cat_path) as f:
            categories = json.load(f)
        if not isinstance(categories, list):
            record("categories_json", False, "categories.json is not a JSON array")
        elif len(categories) == 0:
            record("categories_json", False, "categories.json is empty")
        else:
            required_keys = {"id", "name", "dimension"}
            bad = [c for c in categories if not isinstance(c, dict) or not required_keys.issubset(c.keys())]
            if bad:
                record("categories_json", False, f"{len(bad)} entries missing required keys (id/name/dimension)")
            else:
                record("categories_json", True, f"{len(categories)} categories, all have id/name/dimension")
    except json.JSONDecodeError as e:
        record("categories_json", False, f"invalid JSON: {e}")
else:
    record("categories_json", False, "categories.json missing")

# Check 3b — every category id matches the canonical ^\d+\.\d+$ format.
# Import mode accepts external shapes and can pass through malformed ids
# ("1a", "1-1", "cat.1.1") that satisfy presence checks but break scan Phase 3
# category matching (which pivots on the dotted-number form). Catch here.
if categories:
    id_re = re.compile(r"^[0-9]+\.[0-9]+$")
    malformed = []
    for c in categories:
        cid = str(c.get("id", "")).strip()
        if not id_re.match(cid):
            malformed.append({"id": cid, "name": c.get("name", "")})
    if malformed:
        first = malformed[0]
        more = f" (+{len(malformed)-1} more)" if len(malformed) > 1 else ""
        record("category_id_format", False,
               f"{len(malformed)} category id(s) not in ^\\d+\\.\\d+$ form — first: {first['id']!r} ({first['name']}){more}")
    else:
        record("category_id_format", True, "all category ids match ^\\d+\\.\\d+$")
else:
    record("category_id_format", False, "cannot validate — no categories loaded")

# Check 4 — every category id appears in search-patterns.md
sp_path = os.path.join(tax_dir, "search-patterns.md")
if os.path.isfile(sp_path) and categories:
    with open(sp_path) as f:
        sp_body = f.read()
    unreferenced = []
    for c in categories:
        cid = str(c.get("id", "")).strip()
        if not cid:
            continue
        # Match the id as a standalone token to avoid partial matches ("1.1" vs "1.10").
        # Look for the id followed by a non-digit/non-dot character (or EOL).
        pattern = rf"(?<![\d.]){re.escape(cid)}(?![\d.])"
        if not re.search(pattern, sp_body):
            unreferenced.append(cid)
    if unreferenced:
        sample = ", ".join(unreferenced[:5])
        more = f" (+{len(unreferenced)-5} more)" if len(unreferenced) > 5 else ""
        record("search_patterns_coverage", False,
               f"{len(unreferenced)} category ids have no search pattern: {sample}{more}")
    else:
        record("search_patterns_coverage", True, "every category id appears in search-patterns.md")
else:
    if not os.path.isfile(sp_path):
        record("search_patterns_coverage", False, "search-patterns.md missing")
    else:
        record("search_patterns_coverage", False, "cannot validate — no categories loaded")

# Check 5 — portfolio.json points at the project-local taxonomy
try:
    with open(portfolio_json_path) as f:
        pj = json.load(f)
    tax = pj.get("taxonomy") or {}
    sp = tax.get("source_path")
    if sp != "taxonomy/":
        record("portfolio_json_source_path", False,
               f"portfolio.json taxonomy.source_path is {sp!r}, expected 'taxonomy/'")
    else:
        record("portfolio_json_source_path", True, "taxonomy.source_path = 'taxonomy/'")
    # Also check that taxonomy.type roughly aligns with template.md's type (non-fatal
    # if they differ — the user may rename — but surface as a warning).
    pj_type = tax.get("type")
    if pj_type and tpl_type and pj_type != tpl_type:
        record("type_alignment", True,
               f"note: portfolio.json taxonomy.type={pj_type!r}, template.md type={tpl_type!r} — ok if intentional rename")
except json.JSONDecodeError as e:
    record("portfolio_json_source_path", False, f"portfolio.json is invalid JSON: {e}")

# Check 6 — product-template.md declares at least one product (prevents the
# scan's Phase 7.2 from silently creating nothing)
pt_path = os.path.join(tax_dir, "product-template.md")
if os.path.isfile(pt_path):
    with open(pt_path) as f:
        pt_body = f.read()
    # Heuristic: the product table looks like "| dimension | Product Slug | ..."
    # or lists slug entries as `product_slug`. Accept either a markdown table
    # with kebab-case slugs in a "| `...` |" cell or a bullet list of slugs.
    has_product = bool(re.search(r"\|\s*`[a-z0-9-]+`\s*\|", pt_body)) or \
                  bool(re.search(r"^\s*-\s+`[a-z0-9-]+`", pt_body, re.MULTILINE)) or \
                  bool(re.search(r'"slug"\s*:\s*"[a-z0-9-]+"', pt_body))
    if has_product:
        record("product_skeleton", True, "product-template.md declares at least one product")
    else:
        record("product_skeleton", False,
               "product-template.md found no product declaration (expected markdown table rows or JSON examples with slug)")
else:
    record("product_skeleton", False, "product-template.md missing — scan Phase 7.2 would have no product mapping")

# Emit result
failed = [c for c in checks if not c["ok"]]
passed = [c for c in checks if c["ok"]]
result_data = {
    "project_path": project_path,
    "taxonomy_dir": tax_dir,
    "checks": checks,
    "summary": {
        "total": len(checks),
        "passed": len(passed),
        "failed": len(failed),
    }
}

if failed:
    err_msg = f"{len(failed)} of {len(checks)} checks failed"
    print(json.dumps({"success": False, "error": err_msg, "data": result_data}))
    sys.exit(1)
else:
    print(json.dumps({"success": True, "data": result_data}))
    sys.exit(0)
PY
