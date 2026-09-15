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
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

PHASE="$TMP/phase7.md"
sed -n '/^### Phase 7: Design brief$/,/^## Error Handling$/p' "$PLUGIN/skills/text-to-narrative/SKILL.md" > "$PHASE"
if [ -s "$PHASE" ] &&
   grep -q 'validate-publishing.py normalize --kind narrative' "$PHASE" &&
   grep -q 'design-compose' "$PHASE" &&
   grep -q 'design-render' "$PHASE" &&
   grep -q 'fingerprint' "$PHASE" &&
   grep -q 'Claude Design as an optional' "$PHASE" &&
   ! grep -Eqi 'copywriter|/copywrite|readability\.sh' "$PHASE"; then
  pass "edt-01-freeze-route"
else
  fail "edt-01-freeze-route" "Phase 7 must preserve the freeze, normal renderer route, fingerprint and optional Claude Design route"
fi

cp -R "$PLUGIN" "$TMP/plugin"
ISO="$TMP/plugin"
READ_OUT="$TMP/readability.json"
NORM_OUT="$TMP/normalized.json"
if (cd "$TMP" && env -i HOME="$TMP/home" PATH="$PATH" PYTHONDONTWRITEBYTECODE=1 \
      bash "$ISO/skills/copywriter/scripts/readability.sh" \
      --file "$ISO/tests/fixtures/copywriter/test-docs/english-memo.md" --lang en --json > "$READ_OUT") &&
   (cd "$TMP" && env -i HOME="$TMP/home" PATH="$PATH" PYTHONDONTWRITEBYTECODE=1 \
      python3 "$ISO/scripts/validate-publishing.py" normalize --kind narrative \
      --input "$ISO/tests/fixtures/design-brief/slides-en.md" > "$NORM_OUT") &&
   grep -q '"success": true' "$READ_OUT" &&
   grep -q '"success": true' "$NORM_OUT" &&
   ! rg -n 'cogni-workspace/(skills/(copywriter|text-to-narrative)|libraries|tests/fixtures/(copywriter|design-brief|narrative))' \
      "$ISO/skills/copywriter" "$ISO/skills/text-to-narrative" "$ISO/references" "$ISO/tests/fixtures" >/dev/null; then
  pass "edt-02-publishing-only"
else
  fail "edt-02-publishing-only" "canonical editorial execution or private-path isolation failed without workspace"
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

[ "$failures" -eq 0 ] || exit 1
