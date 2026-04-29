#!/usr/bin/env bash
# edit-taxonomy.sh — Atomic structural edits to a project-local taxonomy with
# a snapshot/restore safety net.
#
# Why this exists: any change to the taxonomy structure (new category, renamed
# dimension, removed category) requires synchronized edits to categories.json
# + template.md + search-patterns.md + (sometimes) product-template.md. A
# user editing those four files by hand will eventually mismatch a category
# id, drop a search pattern, or forget to bump the frontmatter count — and
# validate-taxonomy.sh will refuse the next portfolio-scan. This script does
# the multi-file edit as one transaction: snapshot the taxonomy, apply the
# canonical JSON edit + mechanical markdown updates, run the validator, and
# restore from snapshot on any failure so the project stays scan-ready.
#
# Usage:
#   edit-taxonomy.sh <project_path> <subcommand> [args...]
#
# Subcommands:
#   add-category    <project_path> add-category    <dimension>    <name>
#   rename-category <project_path> rename-category <category_id>  <new_name>
#   split-category  <project_path> split-category  <category_id>  <new_name>
#                   (creates a sibling category in the same dimension; original kept)
#   remove-category <project_path> remove-category <category_id>
#   add-dimension   <project_path> add-dimension   <name>
#   rename-dimension <project_path> rename-dimension <dimension>  <new_name>
#
# Output (stdout, single JSON object):
#   {"success": true,  "data": {...}}   on success
#   {"success": false, "error": "..."}  on any failure (taxonomy restored from snapshot)
#
# Contract:
# - On entry: snapshots <project_path>/taxonomy/ to <project_path>/taxonomy.bak/ atomically (rsync-style replace).
# - categories.json is the source of truth for every edit. template.md frontmatter
#   counts are mechanically synced. search-patterns.md gets append-only stubs for
#   new ids and best-effort line removal for removed ids. product-template.md gets
#   an appended row for new service dimensions; renames update slug occurrences in
#   place but leave human prose untouched.
# - Refuses to edit Dimension 0 (Provider Profile Metrics is reserved by design —
#   see SKILL.md).
# - Runs validate-taxonomy.sh after the edit; on validator failure, restores from
#   the snapshot and returns the validator's findings as the error payload so the
#   user sees what would have broken.
# - Stdlib only (bash + python3).

set -euo pipefail

die() {
  printf '{"success":false,"error":"%s"}\n' "$1"
  exit 1
}

[ $# -ge 2 ] || die "usage: edit-taxonomy.sh <project_path> <subcommand> [args...]"

PROJECT_PATH="$1"
SUBCMD="$2"
shift 2

TAX_DIR="$PROJECT_PATH/taxonomy"
BAK_DIR="$PROJECT_PATH/taxonomy.bak"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -d "$PROJECT_PATH" ] || die "project_path not found: $PROJECT_PATH"
[ -d "$TAX_DIR" ]      || die "no project-local taxonomy at $TAX_DIR (run cogni-portfolio:portfolio-taxonomy first)"

# Snapshot — replace any prior backup so the contract stays one-step.
rm -rf "$BAK_DIR"
mkdir -p "$BAK_DIR"
for f in "$TAX_DIR"/* "$TAX_DIR"/.[!.]* "$TAX_DIR"/..?*; do
  [ -e "$f" ] && cp -R "$f" "$BAK_DIR/" 2>/dev/null || true
done

# Apply edit + validate in python; restore from snapshot on failure.
restore_and_die() {
  local msg="$1"
  rm -rf "$TAX_DIR"
  mkdir -p "$TAX_DIR"
  for f in "$BAK_DIR"/* "$BAK_DIR"/.[!.]* "$BAK_DIR"/..?*; do
    [ -e "$f" ] && cp -R "$f" "$TAX_DIR/" 2>/dev/null || true
  done
  printf '{"success":false,"error":"%s","data":{"restored_from":"%s"}}\n' "$msg" "$BAK_DIR"
  exit 1
}

# Run the python edit. It either prints a JSON payload to stdout (success) or
# writes an error message to a sentinel file we read after.
ERR_FILE="$(mktemp)"
trap 'rm -f "$ERR_FILE"' EXIT

set +e
PY_OUT="$(python3 - "$TAX_DIR" "$SUBCMD" "$ERR_FILE" "$@" <<'PY'
import json, os, re, sys

tax_dir, subcmd, err_file = sys.argv[1], sys.argv[2], sys.argv[3]
args = sys.argv[4:]

def fail(msg):
    with open(err_file, "w") as f:
        f.write(msg)
    sys.exit(1)

def read_text(name):
    p = os.path.join(tax_dir, name)
    if not os.path.isfile(p):
        return ""
    with open(p) as f:
        return f.read()

def write_text(name, body):
    with open(os.path.join(tax_dir, name), "w") as f:
        f.write(body)

def load_categories():
    p = os.path.join(tax_dir, "categories.json")
    try:
        with open(p) as f:
            data = json.load(f)
    except Exception as e:
        fail(f"categories.json unreadable: {e}")
    if not isinstance(data, list):
        fail("categories.json is not a JSON array")
    return data

def save_categories(data):
    p = os.path.join(tax_dir, "categories.json")
    with open(p, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

def slugify(name):
    s = name.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")

def update_frontmatter_counts(dim_count, cat_count):
    p = os.path.join(tax_dir, "template.md")
    if not os.path.isfile(p):
        return
    with open(p) as f:
        body = f.read()
    body = re.sub(r"^(dimensions\s*:\s*).*$", rf"\g<1>{dim_count}", body, count=1, flags=re.MULTILINE)
    body = re.sub(r"^(categories\s*:\s*).*$", rf"\g<1>{cat_count}", body, count=1, flags=re.MULTILINE)
    with open(p, "w") as f:
        f.write(body)

def append_search_stubs(new_ids_with_names_and_dim):
    """Append a Phase 3 stub block for newly-added category ids. Append-only."""
    if not new_ids_with_names_and_dim:
        return
    p = os.path.join(tax_dir, "search-patterns.md")
    body = read_text("search-patterns.md")
    if body and not body.endswith("\n"):
        body += "\n"
    block = "\n## Stubs added by edit-taxonomy.sh\n\n"
    block += "Tune these queries after the next scan — auto-stubs are starting points.\n\n"
    for cid, cname, dname in new_ids_with_names_and_dim:
        block += f"### {cid} {cname}\n\n"
        block += "```text\n"
        block += f'WebSearch: "{dname}" "{cname}" services\n'
        block += f'WebSearch: "{cname}" documentation OR product page\n'
        block += "```\n\n"
    write_text("search-patterns.md", body + block)

def strip_search_lines_for_id(cid):
    """Best-effort removal of search-patterns lines that reference cid as a token."""
    body = read_text("search-patterns.md")
    if not body:
        return
    pat = re.compile(rf"(?<![\d.]){re.escape(cid)}(?![\d.])")
    kept = [ln for ln in body.splitlines(keepends=True) if not pat.search(ln)]
    write_text("search-patterns.md", "".join(kept))

def append_product_row(slug, name, dim_num, dim_name):
    p = os.path.join(tax_dir, "product-template.md")
    body = read_text("product-template.md")
    if body and not body.endswith("\n"):
        body += "\n"
    block = (
        f"\n### {dim_num}. {dim_name} (added by edit-taxonomy.sh)\n\n"
        f"| Dimension | Product Slug | Product Name | Description |\n"
        f"|---|---|---|---|\n"
        f"| {dim_num}. {dim_name} | `{slug}` | {name} | (describe what this product means in your vertical) |\n"
    )
    write_text("product-template.md", body + block)

def replace_slug_occurrences(old_slug, new_slug):
    """Best-effort markdown slug rename in product-template.md."""
    p = os.path.join(tax_dir, "product-template.md")
    body = read_text("product-template.md")
    if not body:
        return
    body = re.sub(rf"`{re.escape(old_slug)}`", f"`{new_slug}`", body)
    write_text("product-template.md", body)

cats = load_categories()

def next_dim_num():
    return max((int(c.get("dimension", 0)) for c in cats), default=-1) + 1

def next_cat_id_within(dim_num):
    nums = []
    for c in cats:
        if int(c.get("dimension", -1)) != dim_num:
            continue
        cid = str(c.get("id", "")).strip()
        m = re.match(r"^(\d+)\.(\d+)$", cid)
        if m and int(m.group(1)) == dim_num:
            nums.append(int(m.group(2)))
    return f"{dim_num}.{(max(nums) + 1) if nums else 1}"

def dim_meta(dim_num):
    """Return (dim_name, dim_slug) for a dimension; falls back to slug from name."""
    for c in cats:
        if int(c.get("dimension", -1)) == dim_num:
            return c.get("dimension_name", f"Dimension {dim_num}"), c.get("dimension_slug", "")
    return None, None

def dim_count():
    return len(set(int(c.get("dimension", 0)) for c in cats))

result = {"subcommand": subcmd}

if subcmd == "add-category":
    if len(args) < 2:
        fail("add-category requires <dimension> <name>")
    try:
        dim = int(args[0])
    except ValueError:
        fail(f"dimension must be an integer, got {args[0]!r}")
    name = args[1]
    if dim == 0:
        fail("Dimension 0 is reserved (Provider Profile Metrics) — see SKILL.md")
    dname, dslug = dim_meta(dim)
    if dname is None:
        fail(f"dimension {dim} does not exist — use add-dimension first")
    new_id = next_cat_id_within(dim)
    cats.append({
        "id": new_id,
        "name": name,
        "dimension": dim,
        "dimension_name": dname,
        "dimension_slug": dslug,
    })
    save_categories(cats)
    update_frontmatter_counts(dim_count(), len(cats))
    append_search_stubs([(new_id, name, dname)])
    result.update({"new_id": new_id, "name": name, "dimension": dim})

elif subcmd == "rename-category":
    if len(args) < 2:
        fail("rename-category requires <category_id> <new_name>")
    cid, new_name = args[0], args[1]
    found = False
    for c in cats:
        if str(c.get("id")) == cid:
            c["name"] = new_name
            found = True
            break
    if not found:
        fail(f"category id not found: {cid}")
    save_categories(cats)
    result.update({"id": cid, "new_name": new_name,
                   "note": "search-patterns.md and template.md prose untouched — id is unchanged"})

elif subcmd == "split-category":
    if len(args) < 2:
        fail("split-category requires <category_id> <new_name>")
    src_id, new_name = args[0], args[1]
    src = next((c for c in cats if str(c.get("id")) == src_id), None)
    if src is None:
        fail(f"source category id not found: {src_id}")
    dim = int(src.get("dimension", 0))
    if dim == 0:
        fail("cannot split a Dimension 0 category (reserved)")
    new_id = next_cat_id_within(dim)
    cats.append({
        "id": new_id,
        "name": new_name,
        "dimension": dim,
        "dimension_name": src.get("dimension_name"),
        "dimension_slug": src.get("dimension_slug"),
    })
    save_categories(cats)
    update_frontmatter_counts(dim_count(), len(cats))
    append_search_stubs([(new_id, new_name, src.get("dimension_name", ""))])
    result.update({"split_from": src_id, "new_id": new_id, "new_name": new_name})

elif subcmd == "remove-category":
    if len(args) < 1:
        fail("remove-category requires <category_id>")
    cid = args[0]
    src = next((c for c in cats if str(c.get("id")) == cid), None)
    if src is None:
        fail(f"category id not found: {cid}")
    if int(src.get("dimension", 0)) == 0:
        fail("cannot remove a Dimension 0 category (reserved)")
    cats = [c for c in cats if str(c.get("id")) != cid]
    save_categories(cats)
    update_frontmatter_counts(dim_count(), len(cats))
    strip_search_lines_for_id(cid)
    result.update({"removed_id": cid})

elif subcmd == "add-dimension":
    if len(args) < 1:
        fail("add-dimension requires <name>")
    name = args[0]
    dim = next_dim_num()
    if dim == 0:
        fail("Dimension 0 is reserved — taxonomy must already include it (clone or import a bundled template first)")
    slug = slugify(name)
    starter_id = f"{dim}.1"
    starter_name = f"{name} (placeholder)"
    cats.append({
        "id": starter_id,
        "name": starter_name,
        "dimension": dim,
        "dimension_name": name,
        "dimension_slug": slug,
    })
    save_categories(cats)
    update_frontmatter_counts(dim_count(), len(cats))
    append_search_stubs([(starter_id, starter_name, name)])
    append_product_row(slug, name, dim, name)
    result.update({
        "new_dimension": dim,
        "name": name,
        "slug": slug,
        "starter_category_id": starter_id,
        "next_step": "use add-category to flesh out 4-10 categories under this dimension",
    })

elif subcmd == "rename-dimension":
    if len(args) < 2:
        fail("rename-dimension requires <dimension> <new_name>")
    try:
        dim = int(args[0])
    except ValueError:
        fail(f"dimension must be an integer, got {args[0]!r}")
    new_name = args[1]
    if dim == 0:
        fail("Dimension 0 is reserved (Provider Profile Metrics) — see SKILL.md")
    new_slug = slugify(new_name)
    old_dname, old_dslug = dim_meta(dim)
    if old_dname is None:
        fail(f"dimension {dim} does not exist")
    touched = 0
    for c in cats:
        if int(c.get("dimension", -1)) == dim:
            c["dimension_name"] = new_name
            c["dimension_slug"] = new_slug
            touched += 1
    save_categories(cats)
    if old_dslug and old_dslug != new_slug:
        replace_slug_occurrences(old_dslug, new_slug)
    result.update({
        "dimension": dim,
        "old_name": old_dname,
        "new_name": new_name,
        "new_slug": new_slug,
        "categories_updated": touched,
        "note": "search-patterns.md and template.md prose untouched — review manually if old name appears as label text",
    })

else:
    fail(f"unknown subcommand: {subcmd}")

print(json.dumps(result))
PY
)"
PY_RC=$?
set -e

if [ "$PY_RC" -ne 0 ]; then
  ERR_MSG="$(cat "$ERR_FILE" 2>/dev/null || echo 'edit failed')"
  ERR_MSG_ESCAPED="${ERR_MSG//\\/\\\\}"
  ERR_MSG_ESCAPED="${ERR_MSG_ESCAPED//\"/\\\"}"
  restore_and_die "$ERR_MSG_ESCAPED"
fi

# Validate the post-edit taxonomy. If it fails, restore.
VALIDATE_OUT="$(bash "$SCRIPT_DIR/validate-taxonomy.sh" "$PROJECT_PATH" 2>&1 || true)"
VALIDATE_OK="$(printf '%s' "$VALIDATE_OUT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read().strip().splitlines()[-1]); print('1' if d.get('success') else '0')" 2>/dev/null || echo "0")"

if [ "$VALIDATE_OK" != "1" ]; then
  # Extract the validator error text if we can; otherwise pass through raw output.
  VAL_ERR="$(printf '%s' "$VALIDATE_OUT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read().strip().splitlines()[-1]); print(d.get('error','validator failed'))" 2>/dev/null || echo 'validator failed')"
  VAL_ERR="${VAL_ERR//\\/\\\\}"
  VAL_ERR="${VAL_ERR//\"/\\\"}"
  restore_and_die "post-edit validation failed: $VAL_ERR"
fi

# Success — emit the python payload + a snapshot pointer
PAYLOAD_ESCAPED="${PY_OUT//\\/\\\\}"
PAYLOAD_ESCAPED="${PAYLOAD_ESCAPED//\"/\\\"}"
printf '{"success":true,"data":{"edit":%s,"snapshot":"%s","validation":"passed"}}\n' \
  "$PY_OUT" "$BAK_DIR"
