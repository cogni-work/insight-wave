#!/usr/bin/env bash
# test_repair_mode.sh — functional test for scripts/migrate-layout.py --repair
# (the curated-layout REPAIR mode that regenerates drifted machine-owned
# regions on an already-curated base, keyed on the structural-drift class
# health.py emits — not the version floor the --migrate path uses).
#
# Executes the real code path against synthetic curated (>= 0.0.8) bases:
#   AC1.  Dry-run (default, no --apply) on a degraded base (empty ROOT-LINKS
#         span) reports action:dry_run / reason:repair_pending, names the
#         drifted ROOT-LINKS region, stages the proposed root MAP to
#         .cogni-wiki/root-index-proposed.md, and leaves the live index.md
#         byte-identical (empty sentinel untouched).
#   AC1.  --apply regenerates ROOT-LINKS via root_index.py render: the live
#         index.md ROOT-LINKS span is populated (empty sentinel gone), and a
#         repair log line lands under wiki/meta/log.md.
#   AC2.  Re-running the vendored health.py on the repaired base reports zero
#         structural_drift findings (errors stay 0).
#   AC3.  --repair on a clean curated base is action:noop / no_drift_detected,
#         and a second --apply is a clean no-op too.
#   lag.  A base recorded at 0.0.8 (behind the engine's 0.0.9) with populated
#         links repairs the schema lag only: --apply bumps schema_version to
#         0.0.9 (action:repaired, no ROOT-LINKS region in drifted_regions).
#   guard. A pre-0.0.8 base is REFUSED (success:false, pointer to --migrate)
#         rather than silently running the lossy full migration.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/migrate-layout.py"
HEALTH="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-health/scripts/health.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -d "$WSD" ]; then
  red "FAIL: vendored cogni-wiki wiki-ingest scripts not found at $WSD"
  exit 1
fi

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# The exact literals the detector strip-compares against (pinned to the live
# root_index.py empty-state sentinel).
ROOT_LINKS_EMPTY='_(no pages yet)_'
REAL_OVERVIEW='This base surveys EU AI Act scope and obligations for SMEs.'
POPULATED_LINKS='**Explore:** [Sources (1)](sources/index.md#Regulierung)'

# Build a curated-layout fixture wiki with a configurable index.md carrying the
# OVERVIEW-NARRATIVE + ROOT-LINKS machine-owned blocks. The single source page
# carries theme_label "Regulierung" so root_index.py render maps it under that
# theme and produces a populated count-link on --apply.
#   $1 = root dir, $2 = schema_version, $3 = overview inner, $4 = root-links inner
build_curated() {
  rm -rf "$1"
  mkdir -p "$1/wiki/sources" "$1/wiki/meta" "$1/.cogni-wiki"
  cat > "$1/.cogni-wiki/config.json" <<EOF
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 1, "schema_version": "$2"}
EOF
  cat > "$1/wiki/index.md" <<EOF
# Fixture Base

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
$3
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->

## Regulierung

<!-- MACHINE-OWNED:ROOT-LINKS:START -->
$4
<!-- MACHINE-OWNED:ROOT-LINKS:END -->
EOF
  printf '_The overview narrative now lives in [index.md](index.md)._\n\n## Recent syntheses\n\n- none yet\n' > "$1/wiki/overview.md"
  printf '# Log\n' > "$1/wiki/meta/log.md"
  printf '# Context brief\n' > "$1/wiki/meta/context_brief.md"
  printf '# Open questions\n' > "$1/wiki/meta/open_questions.md"
  cat > "$1/wiki/sources/eu-ai-act-scope.md" <<'EOF'
---
id: eu-ai-act-scope
title: "Scope of the EU AI Act"
type: source
theme_label: "Regulierung"
created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/ai-act
---

# Scope of the EU AI Act

Body text long enough to clear the stub-page threshold comfortably.
EOF
  printf '# Sources\n\n## Regulierung\n\n- [[eu-ai-act-scope]] — Scope of the EU AI Act.\n' > "$1/wiki/sources/index.md"
}

# ===========================================================================
# AC1. Dry-run on a degraded base (empty ROOT-LINKS span, current schema 0.0.9)
# ===========================================================================
WIKI="$WORK/degraded"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$ROOT_LINKS_EMPTY"
cp "$WIKI/wiki/index.md" "$WORK/degraded-index.before"

DRY="$WORK/dry.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --repair > "$DRY"
assert_grep '"success": true' "$DRY" "AC1 dry-run succeeds"
assert_grep '"action": "dry_run"' "$DRY" "AC1 dry-run is the default (no --apply)"
assert_grep '"reason": "repair_pending"' "$DRY" "AC1 dry-run reason is repair_pending"
assert_grep 'ROOT-LINKS' "$DRY" "AC1 dry-run names the drifted ROOT-LINKS region"
assert_grep 'root-index-proposed.md' "$DRY" "AC1 dry-run stages the proposed root MAP"
if cmp -s "$WIKI/wiki/index.md" "$WORK/degraded-index.before"; then
  green "PASS: AC1 dry-run leaves the live index.md byte-identical"
else
  red "FAIL: AC1 dry-run mutated the live index.md"
  errors=$((errors + 1))
fi

# ===========================================================================
# AC1. --apply regenerates the ROOT-LINKS region
# ===========================================================================
APPLY="$WORK/apply.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --repair --apply > "$APPLY"
assert_grep '"success": true' "$APPLY" "AC1 --apply succeeds"
assert_grep '"action": "repaired"' "$APPLY" "AC1 --apply action is repaired"
assert_not_grep "$ROOT_LINKS_EMPTY" "$WIKI/wiki/index.md" \
  "AC1 --apply replaced the empty ROOT-LINKS sentinel in the live index.md"
assert_grep 'Sources (1)' "$WIKI/wiki/index.md" \
  "AC1 --apply populated the ROOT-LINKS span with the theme-scoped count-link"
assert_grep 'curated-layout repair' "$WIKI/wiki/meta/log.md" \
  "AC1 --apply appended a repair log line"

# ===========================================================================
# AC2. Re-running health on the repaired base reports zero structural_drift
# ===========================================================================
HOUT="$WORK/health-after-repair.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$HOUT"
assert_grep '"success": true' "$HOUT" "AC2 health succeeds on the repaired base"
assert_not_grep 'structural_drift' "$HOUT" \
  "AC2 repaired base fires no structural_drift"
assert_grep '"errors": 0' "$HOUT" "AC2 repaired base has zero errors"

# ===========================================================================
# AC3. --repair on a clean curated base is a noop; a second --apply too
# ===========================================================================
CLEAN="$WORK/clean"
build_curated "$CLEAN" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
NOOP="$WORK/noop.json"
python3 "$SCRIPT" --wiki-root "$CLEAN" --wiki-scripts-dir "$WSD" --repair > "$NOOP"
assert_grep '"action": "noop"' "$NOOP" "AC3 clean base reaches action:noop"
assert_grep '"reason": "no_drift_detected"' "$NOOP" "AC3 clean base reason is no_drift_detected"

NOOP2="$WORK/noop2.json"
python3 "$SCRIPT" --wiki-root "$CLEAN" --wiki-scripts-dir "$WSD" --repair --apply > "$NOOP2"
assert_grep '"action": "noop"' "$NOOP2" "AC3 second --apply on a clean base is a clean no-op"

# ===========================================================================
# lag. Schema-lag-only repair: 0.0.8 base with populated links bumps to 0.0.9
# ===========================================================================
LAG="$WORK/lag"
build_curated "$LAG" "0.0.8" "$REAL_OVERVIEW" "$POPULATED_LINKS"
LAGOUT="$WORK/lag.json"
python3 "$SCRIPT" --wiki-root "$LAG" --wiki-scripts-dir "$WSD" --repair --apply > "$LAGOUT"
assert_grep '"action": "repaired"' "$LAGOUT" "lag --apply repairs the schema lag"
assert_grep '"schema_after": "0.0.9"' "$LAGOUT" "lag --apply reports schema_after 0.0.9"
assert_grep '"schema_version": "0.0.9"' "$LAG/.cogni-wiki/config.json" \
  "lag --apply bumped the on-disk schema_version to 0.0.9"

# ===========================================================================
# guard. A pre-0.0.8 base is refused (run --migrate first)
# ===========================================================================
OLD="$WORK/old"
build_curated "$OLD" "0.0.7" "$REAL_OVERVIEW" "$ROOT_LINKS_EMPTY"
GUARD="$WORK/guard.json"
python3 "$SCRIPT" --wiki-root "$OLD" --wiki-scripts-dir "$WSD" --repair > "$GUARD" || true
assert_grep '"success": false' "$GUARD" "guard: pre-0.0.8 base is refused"
assert_grep 'migrate' "$GUARD" "guard: refusal points at the full migration (--migrate)"

# ---------------------------------------------------------------------------
if [ "$errors" -eq 0 ]; then
  green "test_repair_mode.sh: ALL PASS"
  exit 0
else
  red "test_repair_mode.sh: $errors FAILURE(S)"
  exit 1
fi
