#!/usr/bin/env bash
# test_misplaced_control_files_fix.sh — functional test for the opt-in
# knowledge-lint `--fix=misplaced_control_files` class and the
# migrate-layout.py relocate-only path it delegates to.
#
# Covers:
#   1. `--fix=all` does NOT trigger the relocation (opt-in only — the
#      per-deposit conformance gate must never run a layout migration).
#   2. `--fix=misplaced_control_files --dry-run` plans the move, touches
#      nothing.
#   3. migrate-layout.py on a schema-0.0.8 base WITH a misplaced flat-root
#      control file runs the relocate-only path (action=relocated, schema
#      untouched, no renders), not noop:already_migrated.
#   4. The wet `--fix=misplaced_control_files` relocates the file into
#      wiki/meta/ and is idempotent: the follow-up migrate run is a clean
#      noop and a second lint fix run reports nothing to fix.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py"
MIGRATE="$PLUGIN_ROOT/scripts/migrate-layout.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/meta" "$WIKI/.cogni-wiki"

# Already-curated base (schema 0.0.8): log + open_questions live in meta/,
# but context_brief.md has REAPPEARED at the flat wiki/ root (no meta twin) —
# the post-migration scenario health.py's curated_layout_violation flags.
cat > "$WIKI/.cogni-wiki/config.json" <<'EOF'
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 1, "schema_version": "0.0.8"}
EOF
printf '# Fixture Base\n\n## Regulierung\n\n[Sources (1)](sources/index.md)\n' > "$WIKI/wiki/index.md"
printf '# Log\n' > "$WIKI/wiki/meta/log.md"
printf '# Open questions\n' > "$WIKI/wiki/meta/open_questions.md"
printf '# Context brief (misplaced)\n' > "$WIKI/wiki/context_brief.md"
cat > "$WIKI/wiki/sources/eu-ai-act-scope.md" <<'EOF'
---
id: eu-ai-act-scope
title: "Scope of the EU AI Act"
type: source
created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/ai-act
---

# Scope of the EU AI Act

Body text long enough to clear the stub-page threshold comfortably.
EOF

# ---------------------------------------------------------------------------
# 1. --fix=all must NOT trigger the relocation (opt-in only)
# ---------------------------------------------------------------------------
ALL_OUT="$WORK/all.json"
python3 "$LINT" --wiki-root "$WIKI" --fix=all > "$ALL_OUT"
assert_grep '"success": true' "$ALL_OUT" "lint --fix=all succeeds"
if [ -f "$WIKI/wiki/context_brief.md" ]; then
  green "PASS: --fix=all left the misplaced control file untouched (opt-in respected)"
else
  red "FAIL: --fix=all relocated the control file — opt-in exclusion broken"
  errors=$((errors + 1))
fi
if grep -q 'misplaced_control_files' "$ALL_OUT"; then
  red "FAIL: --fix=all emitted misplaced_control_files entries"
  errors=$((errors + 1))
else
  green "PASS: --fix=all emitted no misplaced_control_files entries"
fi

# ---------------------------------------------------------------------------
# 2. Explicit fix class, --dry-run: plans, touches nothing
# ---------------------------------------------------------------------------
DRY_OUT="$WORK/dry.json"
python3 "$LINT" --wiki-root "$WIKI" --fix=misplaced_control_files --dry-run > "$DRY_OUT"
assert_grep '"success": true' "$DRY_OUT" "dry-run fix succeeds"
assert_grep 'misplaced_control_files' "$DRY_OUT" "dry-run reports the planned relocation"
if [ -f "$WIKI/wiki/context_brief.md" ] && [ ! -e "$WIKI/wiki/meta/context_brief.md" ]; then
  green "PASS: dry-run moved nothing"
else
  red "FAIL: dry-run moved files"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
# 3. migrate-layout.py relocate-only path on the 0.0.8 base
# ---------------------------------------------------------------------------
MIG_DRY="$WORK/mig-dry.json"
python3 "$MIGRATE" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" > "$MIG_DRY"
assert_grep '"action": "dry_run"' "$MIG_DRY" "migrate dry-run on misplaced 0.0.8 base"
assert_grep '"reason": "relocate_pending"' "$MIG_DRY" \
  "dry-run names the relocate-only path (not noop:already_migrated)"

# ---------------------------------------------------------------------------
# 4. Wet fix relocates; the whole chain is idempotent
# ---------------------------------------------------------------------------
WET_OUT="$WORK/wet.json"
python3 "$LINT" --wiki-root "$WIKI" --fix=misplaced_control_files > "$WET_OUT"
assert_grep '"success": true' "$WET_OUT" "wet fix succeeds"
assert_grep '"applied": true' "$WET_OUT" "wet fix reports an applied relocation"
if [ -f "$WIKI/wiki/meta/context_brief.md" ] && [ ! -e "$WIKI/wiki/context_brief.md" ]; then
  green "PASS: context_brief.md relocated into wiki/meta/"
else
  red "FAIL: context_brief.md not relocated"
  errors=$((errors + 1))
fi
assert_grep '"schema_version": "0.0.8"' "$WIKI/.cogni-wiki/config.json" \
  "relocate-only path leaves schema_version untouched"

NOOP_OUT="$WORK/noop.json"
python3 "$MIGRATE" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply > "$NOOP_OUT"
assert_grep '"action": "noop"' "$NOOP_OUT" "follow-up migrate run is a clean noop"
assert_grep '"reason": "already_migrated"' "$NOOP_OUT" "noop reason is already_migrated"

RERUN_OUT="$WORK/rerun.json"
python3 "$LINT" --wiki-root "$WIKI" --fix=misplaced_control_files > "$RERUN_OUT"
assert_grep '"success": true' "$RERUN_OUT" "second wet fix run succeeds"
if grep -q '"applied": true' "$RERUN_OUT"; then
  red "FAIL: second fix run re-applied a relocation (idempotency broken)"
  errors=$((errors + 1))
else
  green "PASS: second fix run finds nothing to relocate (idempotent)"
fi

# ---------------------------------------------------------------------------
# 5. --relocate-only refuses a pre-0.0.8 base (never the full migration)
# ---------------------------------------------------------------------------
LEGACY="$WORK/legacy-root"
mkdir -p "$LEGACY/wiki" "$LEGACY/.cogni-wiki"
cat > "$LEGACY/.cogni-wiki/config.json" <<'EOF'
{"wiki_slug": "legacy", "title": "Legacy Base", "entries_count": 0, "schema_version": "0.0.7"}
EOF
printf '# Log\n' > "$LEGACY/wiki/log.md"
REFUSE_OUT="$WORK/refuse.json"
python3 "$MIGRATE" --wiki-root "$LEGACY" --wiki-scripts-dir "$WSD" --relocate-only --apply > "$REFUSE_OUT" || true
assert_grep '"success": false' "$REFUSE_OUT" \
  "--relocate-only refuses a pre-0.0.8 base"
assert_grep 'knowledge-index --migrate' "$REFUSE_OUT" \
  "refusal points at the full-migration path"
if [ -f "$LEGACY/wiki/log.md" ] && [ ! -e "$LEGACY/wiki/meta" ]; then
  green "PASS: refused base left byte-identical (no partial migration)"
else
  red "FAIL: --relocate-only touched a pre-0.0.8 base"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
if [ "$errors" -gt 0 ]; then
  red "$errors assertion(s) failed"
  exit 1
fi
green "all misplaced_control_files fix assertions passed"
