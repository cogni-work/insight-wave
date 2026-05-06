#!/usr/bin/env bash
# test_lint_health_partition.sh — assert the v0.0.27 (#217) Health-vs-Lint
# boundary holds in the v0.0.31 (#223) refactored implementation.
#
# Concretely: introduce four structural defects into a migrated fixture wiki
# and confirm:
#   - lint_wiki.py emits NO error class in the "health-owned" set
#   - lint_wiki.py emits NO warning class in the "health-owned" set
#   - health.py DOES emit broken_wikilink + invalid_type for the planted defects
#
# The "lint-owned" surface (no_sources, synthesis_no_wiki_source, orphan_page,
# stale_page, stale_draft, tag_typo, reverse_link_missing, claim_drift) is
# already exercised by test_open_questions.sh and test_migrate_and_smoke.sh.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
LINT="$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py"
HEALTH="$PLUGIN_ROOT/skills/wiki-health/scripts/health.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

# Classes that MUST NOT appear in lint_wiki.py output as of v0.0.31.
# Source: skills/wiki-lint/references/severity-tiers.md (Health column).
HEALTH_OWNED="broken_wikilink missing_frontmatter id_mismatch invalid_type missing_source broken_wiki_source read_error entries_count_drift type_directory_mismatch"

# ---------- prepare a migrated fixture and plant defects ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null

# Defect 1: broken wikilink — append [[no-such-page]] to a body.
TARGET="$WIKI/wiki/concepts/karpathy-pattern.md"
printf '\nAlso see [[no-such-page]] for more.\n' >> "$TARGET"

# Defect 2: invalid type — change a frontmatter `type:` to a bogus value.
sed -i.bak 's/^type: concept$/type: bogus-type/' \
  "$WIKI/wiki/concepts/per-type-directories.md"
rm -f "$WIKI/wiki/concepts/per-type-directories.md.bak"

green "fixture prepared with planted defects (broken_wikilink + invalid_type)"

# ---------- 1) lint_wiki.py must emit no health-owned class ----------
LINT_OUT=$(python3 "$LINT" --wiki-root "$WIKI")
LINT_OK=$(printf '%s' "$LINT_OUT" | python3 -c 'import json, sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")')
[ "$LINT_OK" = "yes" ] || fail "lint_wiki.py did not return success:true"
green "lint_wiki.py: success"

# Extract every class from data.errors and data.warnings.
LINT_CLASSES=$(printf '%s' "$LINT_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        if c:
            seen.add(c)
print("\n".join(sorted(seen)))
')

# Assert empty intersection with HEALTH_OWNED.
for c in $HEALTH_OWNED; do
  if printf '%s\n' "$LINT_CLASSES" | grep -qx "$c"; then
    red "FAIL: lint_wiki.py still emits health-owned class '$c'"
    red "Full lint class set:"
    printf '%s\n' "$LINT_CLASSES"
    exit 1
  fi
done
green "lint_wiki.py emits no health-owned classes (post-#223 boundary holds)"

# Assert lint also emits zero errors entirely (the array is now always empty).
ERR_COUNT=$(printf '%s' "$LINT_OUT" | python3 -c 'import json, sys; print(len(json.loads(sys.stdin.read())["data"]["errors"]))')
[ "$ERR_COUNT" = "0" ] || fail "lint_wiki.py errors count is $ERR_COUNT (expected 0)"
green "lint_wiki.py errors[] is empty (structural errors moved to health)"

# ---------- 2) health.py must catch the planted defects ----------
HEALTH_OUT=$(python3 "$HEALTH" --wiki-root "$WIKI")
HEALTH_OK=$(printf '%s' "$HEALTH_OUT" | python3 -c 'import json, sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")')
[ "$HEALTH_OK" = "yes" ] || fail "health.py did not return success:true"

HEALTH_CLASSES=$(printf '%s' "$HEALTH_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        if c:
            seen.add(c)
print("\n".join(sorted(seen)))
')

for c in broken_wikilink invalid_type; do
  if ! printf '%s\n' "$HEALTH_CLASSES" | grep -qx "$c"; then
    red "FAIL: health.py did NOT report planted defect class '$c'"
    red "Full health class set:"
    printf '%s\n' "$HEALTH_CLASSES"
    exit 1
  fi
done
green "health.py reports both planted defects (broken_wikilink + invalid_type)"

# ---------- 3) lint preserves data.errors as a list (consumer compat) ----------
TYPE_OK=$(printf '%s' "$LINT_OUT" | python3 -c 'import json, sys; print(type(json.loads(sys.stdin.read())["data"]["errors"]).__name__)')
[ "$TYPE_OK" = "list" ] || fail "lint data.errors type is $TYPE_OK (expected list)"
green "lint data.errors stays as a list (consumer-compat preserved)"

green "ALL TESTS PASS"
