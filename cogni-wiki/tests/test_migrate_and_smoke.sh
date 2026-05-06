#!/usr/bin/env bash
# test_migrate_and_smoke.sh — end-to-end test for the per-type-directory
# migration introduced in cogni-wiki v0.0.28.
#
# 1. Copies tests/fixtures/legacy-wiki/ to a temp dir.
# 2. Asserts every consumer hard-fails on the legacy layout (pre-migration probe).
# 3. Runs migrate_layout.py --apply.
# 4. Asserts pages landed in the right per-type dirs and audit reports under wiki/audits/.
# 5. Asserts schema_version was bumped to 0.0.5.
# 6. Re-runs the migrator and asserts it's a no-op (idempotent).
# 7. Runs every consumer (health, lint, dashboard, status, backlink_audit,
#    extract_page_claims) against the migrated wiki and asserts success: true.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

# ---------- helpers ----------

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

fail() {
  red "FAIL: $1"
  exit 1
}

assert_success_json() {
  # $1 = label, $2 = JSON string
  local label="$1"
  local out="$2"
  local ok
  ok=$(printf '%s' "$out" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print("yes" if d.get("success") else "no")' 2>/dev/null || echo "parse-error")
  if [ "$ok" != "yes" ]; then
    red "FAIL ($label): expected success:true"
    printf '%s\n' "$out"
    exit 1
  fi
}

assert_failure_with_migration_msg() {
  # $1 = label, $2 = JSON string
  local label="$1"
  local out="$2"
  local result
  result=$(printf '%s' "$out" | python3 -c 'import json, sys
d = json.loads(sys.stdin.read())
print("ok" if (not d.get("success")) and ("pre-migration" in d.get("error","")) else "bad")' 2>/dev/null || echo "parse-error")
  if [ "$result" != "ok" ]; then
    red "FAIL ($label): expected success:false with pre-migration message"
    printf '%s\n' "$out"
    exit 1
  fi
}

assert_file() {
  if [ ! -f "$1" ]; then
    fail "expected file not found: $1"
  fi
}

assert_no_file() {
  if [ -e "$1" ]; then
    fail "unexpected file present: $1"
  fi
}

# ---------- copy fixture ----------

cp -R "$FIXTURES/legacy-wiki" "$WIKI"
green "fixture copied to $WIKI"

# ---------- 1) pre-migration probe ----------

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-health/scripts/health.py" --wiki-root "$WIKI" 2>/dev/null || true)
assert_failure_with_migration_msg "health.py pre-migration" "$OUT"
green "health.py hard-fails on legacy layout"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py" --wiki-root "$WIKI" 2>/dev/null || true)
assert_failure_with_migration_msg "lint_wiki.py pre-migration" "$OUT"
green "lint_wiki.py hard-fails on legacy layout"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-dashboard/scripts/render_dashboard.py" --wiki-root "$WIKI" --output "$WORKDIR/dash.html" 2>/dev/null || true)
assert_failure_with_migration_msg "render_dashboard.py pre-migration" "$OUT"
green "render_dashboard.py hard-fails on legacy layout"

# ---------- 2) wiki_status.sh surfaces migration_pending instead of hard-failing ----------

OUT=$(bash "$PLUGIN_ROOT/skills/wiki-resume/scripts/wiki_status.sh" --wiki-root "$WIKI" 2>/dev/null)
assert_success_json "wiki_status.sh pre-migration" "$OUT"
PENDING=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"].get("schema_migration_pending"))')
if [ "$PENDING" != "True" ]; then
  fail "wiki_status.sh: expected schema_migration_pending=True, got $PENDING"
fi
green "wiki_status.sh surfaces schema_migration_pending=True"

# ---------- 3) migrate_layout.py dry-run ----------

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" --wiki-root "$WIKI")
assert_success_json "migrate_layout dry-run" "$OUT"
DRY_MOVED=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"]["stats"]["moved"])')
if [ "$DRY_MOVED" != "4" ]; then
  fail "migrate_layout dry-run: expected 4 moves, got $DRY_MOVED"
fi
assert_file "$WIKI/wiki/pages/karpathy-pattern.md"
green "migrate_layout dry-run reports 4 moves and touches no files"

# ---------- 4) migrate_layout.py --apply ----------

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" --wiki-root "$WIKI" --apply)
assert_success_json "migrate_layout --apply" "$OUT"
APPLIED_AFTER=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"]["schema_version_after"])')
if [ "$APPLIED_AFTER" != "0.0.5" ]; then
  fail "migrate_layout: schema_version_after=$APPLIED_AFTER (expected 0.0.5)"
fi

assert_file "$WIKI/wiki/concepts/karpathy-pattern.md"
assert_file "$WIKI/wiki/concepts/per-type-directories.md"
assert_file "$WIKI/wiki/decisions/adopt-schema-version-0-0-5.md"
assert_file "$WIKI/wiki/audits/lint-2026-04-15.md"
assert_no_file "$WIKI/wiki/pages/karpathy-pattern.md"
green "files landed in the correct per-type dirs"

# wiki/pages/ should be removed since it's empty after the migration
if [ -d "$WIKI/wiki/pages" ]; then
  fail "wiki/pages/ should have been rmdir'd after migration"
fi
green "wiki/pages/ removed"

# Config should now show 0.0.5
CFG_VERSION=$(python3 -c 'import json; print(json.load(open("'"$WIKI"'/.cogni-wiki/config.json"))["schema_version"])')
if [ "$CFG_VERSION" != "0.0.5" ]; then
  fail "config.json schema_version=$CFG_VERSION (expected 0.0.5)"
fi
green "config.json schema_version bumped to 0.0.5"

# Log line appended
if ! grep -q '^## \[.*\] migrate | moved 4 pages to per-type dirs' "$WIKI/wiki/log.md"; then
  fail "expected migrate log line not found in wiki/log.md"
fi
green "migrate log line appended"

# ---------- 5) idempotent re-run ----------

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" --wiki-root "$WIKI" --apply)
assert_success_json "migrate_layout re-run" "$OUT"
RERUN_MOVED=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"]["stats"]["moved"])')
if [ "$RERUN_MOVED" != "0" ]; then
  fail "migrate_layout re-run: expected 0 moves, got $RERUN_MOVED"
fi
green "migrate_layout re-run is idempotent"

# ---------- 6) consumer smoke tests ----------

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-health/scripts/health.py" --wiki-root "$WIKI")
assert_success_json "health.py post-migration" "$OUT"
ERRS=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"]["stats"]["errors"])')
if [ "$ERRS" != "0" ]; then
  red "health.py reports $ERRS errors:"
  printf '%s\n' "$OUT" | python3 -m json.tool
  exit 1
fi
green "health.py: 0 errors against migrated wiki"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py" --wiki-root "$WIKI")
assert_success_json "lint_wiki.py post-migration" "$OUT"
green "lint_wiki.py: success against migrated wiki"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-dashboard/scripts/render_dashboard.py" --wiki-root "$WIKI" --output "$WORKDIR/dash.html")
assert_success_json "render_dashboard.py post-migration" "$OUT"
assert_file "$WORKDIR/dash.html"
green "render_dashboard.py: success against migrated wiki"

OUT=$(bash "$PLUGIN_ROOT/skills/wiki-resume/scripts/wiki_status.sh" --wiki-root "$WIKI")
assert_success_json "wiki_status.sh post-migration" "$OUT"
PENDING=$(printf '%s' "$OUT" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d["data"]["schema_migration_pending"])')
if [ "$PENDING" != "False" ]; then
  fail "wiki_status.sh: expected schema_migration_pending=False post-migration, got $PENDING"
fi
green "wiki_status.sh: schema_migration_pending=False post-migration"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-ingest/scripts/backlink_audit.py" --wiki-root "$WIKI" --new-page karpathy-pattern)
assert_success_json "backlink_audit.py post-migration" "$OUT"
green "backlink_audit.py: success against migrated wiki"

OUT=$(python3 "$PLUGIN_ROOT/skills/wiki-claims-resweep/scripts/extract_page_claims.py" --wiki-root "$WIKI" --all)
assert_success_json "extract_page_claims.py post-migration" "$OUT"
green "extract_page_claims.py: success against migrated wiki"

green "ALL TESTS PASS"
