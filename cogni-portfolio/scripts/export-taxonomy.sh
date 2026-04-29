#!/usr/bin/env bash
# export-taxonomy.sh — Package a project-local taxonomy as a portable template
# folder, in the same shape as cogni-portfolio/templates/{type}/, ready to drop
# into another project's taxonomy/ directory or contribute back as a bundled
# template.
#
# Why this exists: a user who has crafted a strong taxonomy for project A
# cannot reuse it as a starting point in project B without manually copying
# files and stripping project-local provenance. This script automates the
# round-trip — the output is structurally identical to a bundled template so
# a downstream `clone-taxonomy.sh` can consume it (or it can be placed
# directly under cogni-portfolio/templates/ and committed).
#
# Usage:
#   export-taxonomy.sh <project_path> <output_dir> [--type <slug>] [--force]
#
# Arguments:
#   project_path  Absolute path to the portfolio project (dir containing portfolio.json + taxonomy/)
#   output_dir    Absolute path where the portable bundle will be written
#   --type        Override the type slug in the exported template.md frontmatter
#                 (default: keep whatever taxonomy/template.md already declares)
#   --force       Overwrite output_dir if it already exists (default: refuse)
#
# Output (stdout, single JSON object):
#   {"success": true,  "data": {...}}   on success
#   {"success": false, "error": "..."}  on any failure (exit 1)
#
# Contract:
# - Read-only on the project. Writes only into <output_dir>/.
# - Copies the 7 canonical taxonomy files; strips project-local provenance from
#   template.md frontmatter (cloned_from, cloned_at, authored_at, imported_at,
#   imported_from). The export is portable — it must not carry traces of the
#   project it came from.
# - Validates the source taxonomy via validate-taxonomy.sh before exporting; an
#   invalid taxonomy fails with the validator's findings so users can't ship
#   a broken bundle.
# - Stdlib only (bash + python3).

set -euo pipefail

die() {
  printf '{"success":false,"error":"%s"}\n' "$1"
  exit 1
}

[ $# -ge 2 ] || die "usage: export-taxonomy.sh <project_path> <output_dir> [--type <slug>] [--force]"

PROJECT_PATH="$1"
OUTPUT_DIR="$2"
shift 2

TYPE_OVERRIDE=""
FORCE="no"
while [ $# -gt 0 ]; do
  case "$1" in
    --type)
      [ $# -ge 2 ] || die "--type requires a value"
      TYPE_OVERRIDE="$2"
      shift 2
      ;;
    --force)
      FORCE="yes"
      shift
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

TAX_DIR="$PROJECT_PATH/taxonomy"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -d "$PROJECT_PATH" ] || die "project_path not found: $PROJECT_PATH"
[ -d "$TAX_DIR" ]      || die "no project-local taxonomy at $TAX_DIR (run cogni-portfolio:portfolio-taxonomy first)"

# Refuse to export a broken taxonomy — the user would publish a bundle that
# fails validation in the next consumer's project.
VALIDATE_OUT="$(bash "$SCRIPT_DIR/validate-taxonomy.sh" "$PROJECT_PATH" 2>&1 || true)"
VALIDATE_OK="$(printf '%s' "$VALIDATE_OUT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read().strip().splitlines()[-1]); print('1' if d.get('success') else '0')" 2>/dev/null || echo "0")"
if [ "$VALIDATE_OK" != "1" ]; then
  VAL_ERR="$(printf '%s' "$VALIDATE_OUT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read().strip().splitlines()[-1]); print(d.get('error','validator failed'))" 2>/dev/null || echo 'validator failed')"
  VAL_ERR="${VAL_ERR//\\/\\\\}"
  VAL_ERR="${VAL_ERR//\"/\\\"}"
  die "source taxonomy is invalid; cannot export: $VAL_ERR"
fi

if [ -e "$OUTPUT_DIR" ]; then
  if [ "$FORCE" != "yes" ]; then
    die "output_dir already exists: $OUTPUT_DIR (use --force to overwrite)"
  fi
  rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

# Copy the 7 canonical files. Anything else in taxonomy/ is project-local
# noise (e.g., .DS_Store, taxonomy.bak/, drafts) that does not belong in a
# portable bundle.
CANONICAL=(
  template.md
  categories.json
  search-patterns.md
  product-template.md
  cross-category-rules.md
  provider-unit-rules.md
  report-template.md
)

for f in "${CANONICAL[@]}"; do
  src="$TAX_DIR/$f"
  if [ ! -f "$src" ]; then
    die "expected canonical file missing: $f (validator should have caught this)"
  fi
  cp "$src" "$OUTPUT_DIR/$f"
done

# Strip project-local provenance from the exported template.md frontmatter and
# optionally rewrite the type slug. Read-only on the source — we only edit the
# copy under output_dir.
python3 - "$OUTPUT_DIR/template.md" "$TYPE_OVERRIDE" <<'PY'
import re, sys
path, type_override = sys.argv[1], sys.argv[2]
with open(path) as f:
    body = f.read()
m = re.match(r"^(---\n)(.*?)(\n---)", body, re.DOTALL)
if not m:
    sys.exit(0)
fm = m.group(2)
# Strip project-local provenance keys — they only make sense inside the project
# that produced the export, not in a portable bundle.
for key in ("cloned_from", "cloned_at", "authored_at", "imported_at", "imported_from"):
    fm = re.sub(rf"^{key}\s*:.*$\n?", "", fm, flags=re.MULTILINE)
if type_override:
    if re.search(r"^type\s*:", fm, re.MULTILINE):
        fm = re.sub(r"^type\s*:.*$", f"type: {type_override}", fm, count=1, flags=re.MULTILINE)
    else:
        fm = f"type: {type_override}\n" + fm
new_body = m.group(1) + fm + m.group(3) + body[m.end():]
with open(path, "w") as f:
    f.write(new_body)
PY

# Read the exported type back so the success payload is honest about what the
# consumer will see in template.md.
EXPORTED_TYPE="$(python3 - "$OUTPUT_DIR/template.md" <<'PY'
import re, sys
with open(sys.argv[1]) as f:
    body = f.read()
m = re.search(r"^type\s*:\s*(.+)$", body, re.MULTILINE)
print(m.group(1).strip().strip('"').strip("'") if m else "")
PY
)"

FILE_COUNT="$(find "$OUTPUT_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')"

printf '{"success":true,"data":{"output_dir":"%s","exported_type":"%s","files_written":%s,"validation":"passed","portable":true}}\n' \
  "$OUTPUT_DIR" "$EXPORTED_TYPE" "$FILE_COUNT"
