#!/usr/bin/env bash
# Editorial ownership and frozen-route guard.
#
# Mutation recipes (installed cogni-service harness):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . --file cogni-publishing/skills/text-to-narrative/SKILL.md \
#     --expr 's{(### Phase 7: Design brief\n)}{$1\nDispatch copywriter after freeze.\n}' \
#     --test 'bash cogni-publishing/tests/test-editorial-transfer.sh' --case edt-01-freeze-route
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . --file cogni-publishing/skills/text-to-narrative/SKILL.md \
#     --expr 's{tests/fixtures/copywriter/readability.yml}{../cogni-workspace/tests/fixtures/copywriter/readability.yml}' \
#     --test 'bash cogni-publishing/tests/test-editorial-transfer.sh' --case edt-02-publishing-only

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$HERE/.." && pwd)"
ROOT="$(cd "$PLUGIN/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

PHASE="$TMP/phase7.md"
sed -n '/^### Phase 7: Design brief$/,/^## Error Handling$/p' "$PLUGIN/skills/text-to-narrative/SKILL.md" > "$PHASE"
phase_ok() {
  local phase=$1
  [ -s "$phase" ] &&
    grep -q 'validate-publishing.py normalize --kind narrative' "$phase" &&
    grep -q 'design-compose' "$phase" &&
    grep -q 'design-render' "$phase" &&
    grep -q 'fingerprint' "$phase" &&
    grep -q 'Claude Design as an optional' "$phase" &&
    grep -q 'never dispatch copywriter, `/copywrite`, copy-fit, rewrite, shorten, or re-narration work after the freeze' "$phase" &&
    ! grep -Eqi '^[[:space:]]*(Dispatch|Invoke|Run|Route) .*(copywriter|/copywrite|copy[- ]?fit|rewrite|shorten|re-?narrat)' "$phase"
}
if phase_ok "$PHASE"; then
  pass "edt-01-freeze-route"
else
  fail "edt-01-freeze-route" "Phase 7 must preserve the frozen-copy prohibition, normal renderer route, fingerprint and optional Claude Design route"
fi

mkdir -p "$TMP/plugin/skills/copywriter/scripts" "$TMP/plugin/skills/copywriter/references" \
  "$TMP/plugin/references" "$TMP/plugin/tests/fixtures/copywriter" "$TMP/bin" "$TMP/home"
cp "$PLUGIN/skills/copywriter/SKILL.md" "$TMP/plugin/skills/copywriter/SKILL.md"
cp "$PLUGIN/skills/copywriter/scripts/check-copywriter-output.py" "$TMP/plugin/skills/copywriter/scripts/"
cp -R "$PLUGIN/skills/copywriter/references/." "$TMP/plugin/skills/copywriter/references/"
cp "$PLUGIN"/references/arc-*.md "$PLUGIN/references/language-"*.md \
  "$PLUGIN/references/techniques-overview.md" "$TMP/plugin/references/"
cp "$PLUGIN/tests/fixtures/copywriter/editorial-regressions.json" "$TMP/plugin/tests/fixtures/copywriter/"
ln -s "$(command -v python3)" "$TMP/bin/python3"
ISO="$TMP/plugin"
POLISH_OUT="$TMP/polish.json"
python3 - "$ISO/tests/fixtures/copywriter/editorial-regressions.json" "$TMP/source.md" "$TMP/polished.md" <<'PY'
import json, pathlib, sys
d=json.load(open(sys.argv[1], encoding="utf-8"))
pathlib.Path(sys.argv[2]).write_text(d["source"], encoding="utf-8")
pathlib.Path(sys.argv[3]).write_text(d["source"].replace("will invest", "invests"), encoding="utf-8")
PY
if (cd "$TMP" && env -i HOME="$TMP/home" PATH="$TMP/bin" PYTHONDONTWRITEBYTECODE=1 \
      python3 "$ISO/skills/copywriter/scripts/check-copywriter-output.py" \
      "$TMP/source.md" "$TMP/polished.md" --mode polish --entities 'Acme GmbH' --claims 'Claim Alpha' > "$POLISH_OUT") &&
   python3 - "$POLISH_OUT" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding="utf-8"))
assert set(d) == {"success", "data", "error"} and d["success"] is True and isinstance(d["data"], dict) and d["error"] == ""
PY
   grep -q '\${CLAUDE_PLUGIN_ROOT}/references/arc-{arc_id}.md' "$ISO/skills/copywriter/SKILL.md" &&
   grep -q '\${CLAUDE_PLUGIN_ROOT}/references/language-shared.md' "$ISO/skills/copywriter/references/arc-preservation.md" &&
   [ -f "$ISO/references/arc-corporate-visions.md" ] &&
   [ -f "$ISO/references/language-shared.md" ] &&
   (cd "$TMP" && env -i HOME="$TMP/home" PATH="$TMP/bin" /bin/sh -c \
      '! command -v node && ! command -v npm && ! command -v curl && ! command -v chromium && ! command -v google-chrome') &&
   [ ! -e "$TMP/cogni-workspace" ] && [ ! -e "$ISO/runtime" ] &&
   ! rg -n 'cogni-workspace/' "$ISO/skills/copywriter" "$ISO/references" >/dev/null; then
  pass "edt-02-publishing-only"
else
  fail "edt-02-publishing-only" "captured polish validation envelope or publishing-only dependency isolation failed"
fi

shared_missing=""
for target in arc-registry.md arc-taxonomy.md language-shared.md presentation-intent.md density-ceilings.md; do
  [ -f "$PLUGIN/references/$target" ] || shared_missing="$shared_missing $target"
done
if [ -z "$shared_missing" ]; then
  pass "edt-03-shared-resources"
else
  fail "edt-03-shared-resources" "missing:$shared_missing"
fi

for term in copywriter /copywrite copy-fit rewrite shorten re-narration; do
  slug=${term#/}; slug=${slug//-/_}
  python3 - "$PLUGIN/skills/text-to-narrative/SKILL.md" "$TMP/mutant-skill.md" "$term" <<'PY'
import pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
needle="### Phase 7: Design brief\n"
pathlib.Path(sys.argv[2]).write_text(text.replace(needle, needle + f"\nDispatch {sys.argv[3]} after freeze.\n", 1), encoding="utf-8")
PY
  sed -n '/^### Phase 7: Design brief$/,/^## Error Handling$/p' "$TMP/mutant-skill.md" > "$TMP/mutant-phase.md"
  if phase_ok "$TMP/mutant-phase.md"; then
    fail "edt-04-$slug-red" "post-freeze $term dispatch was admitted"
  else
    pass "edt-04-$slug-red"
  fi
done

INVENTORY="$PLUGIN/tests/fixtures/editorial-transfer-inventory.tsv"
inventory_ok() {
  local inventory_root=$1 inventory_bad="" kind source target spec expected actual
  for spec in pointer:31 script:5 eval:2 suite:6 fixture-family:4 arc:15 fixture:31 reference:49; do
    kind=${spec%%:*}; expected=${spec#*:}
    actual=$(awk -F '\t' -v kind="$kind" '$1 == kind {n++} END {print n+0}' "$INVENTORY")
    [ "$actual" -eq "$expected" ] || inventory_bad="$inventory_bad count:$kind=$actual"
  done
  while IFS=$'\t' read -r kind source target; do
    case "$kind" in
      pointer)
        [ -f "$inventory_root/$source" ] && [ -f "$inventory_root/$target" ] || inventory_bad="$inventory_bad missing:$kind:$source:$target" ;;
      script|eval|suite|fixture|reference)
        [ ! -e "$inventory_root/$source" ] && [ -f "$inventory_root/$target" ] || inventory_bad="$inventory_bad move:$kind:$source:$target" ;;
      fixture-family)
        [ ! -e "$inventory_root/${source%/}" ] && [ -d "$inventory_root/${target%/}" ] || inventory_bad="$inventory_bad family:$source:$target" ;;
      arc)
        [ "$source" = "-" ] && [ -f "$inventory_root/$target" ] || inventory_bad="$inventory_bad arc:$target" ;;
      *) inventory_bad="$inventory_bad category:$kind" ;;
    esac
  done < "$INVENTORY"
  [ -z "$inventory_bad" ] || { printf '%s\n' "$inventory_bad"; return 1; }
}
inventory_bad="$(inventory_ok "$ROOT")"
if [ -z "$inventory_bad" ]; then
  pass "edt-05-exhaustive-inventory"
else
  fail "edt-05-exhaustive-inventory" "$inventory_bad"
fi

# Deleting a leaf while its family directory remains must fail the same inventory.
python3 - "$ROOT" "$INVENTORY" "$TMP/inventory" <<'COPY'
from pathlib import Path
import shutil, sys
root, inventory, dest=map(Path, sys.argv[1:])
for row in inventory.read_text().splitlines():
    kind, source, target=row.split('\t')
    for rel in ([source, target] if kind == 'pointer' else [target]):
        if rel.endswith('/'):
            (dest/rel).mkdir(parents=True, exist_ok=True)
        else:
            (dest/rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(root/rel, dest/rel)
COPY
for family in copywriter design-brief narrative-output narrative-source; do
  victim=$(awk -F '\t' -v prefix="cogni-publishing/tests/fixtures/$family/" '$1 == "fixture" && index($3, prefix) == 1 {print $3; exit}' "$INVENTORY")
  mv "$TMP/inventory/$victim" "$TMP/removed-leaf"
  if inventory_ok "$TMP/inventory" > /dev/null; then
    fail "edt-06-$family-leaf-red" "missing fixture was admitted"
  else
    pass "edt-06-$family-leaf-red"
  fi
  mv "$TMP/removed-leaf" "$TMP/inventory/$victim"
done
victim=$(awk -F '\t' '$1 == "reference" {print $2; exit}' "$INVENTORY")
mkdir -p "$(dirname "$TMP/inventory/$victim")"
printf 'duplicate implementation\n' > "$TMP/inventory/$victim"
if inventory_ok "$TMP/inventory" > /dev/null; then
  fail "edt-07-workspace-duplicate-red" "workspace-private reference was admitted"
else
  pass "edt-07-workspace-duplicate-red"
fi

[ "$failures" -eq 0 ] || exit 1
