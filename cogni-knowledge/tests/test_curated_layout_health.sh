#!/usr/bin/env bash
# test_curated_layout_health.sh — functional test for the vendored health.py
# curated-layout assertions (schema_version >= 0.0.8) and the per-type
# sub-index exemption (_wikilib.iter_pages skips wiki/<type>/index.md).
#
# Covers:
#   1. A clean curated-layout wiki (control files under wiki/meta/, sub-index
#      present, overview.md stub) passes with zero errors, and the sub-index
#      neither inflates entries_count_actual nor registers anywhere.
#   2. A flat-root control file at schema >= 0.0.8 fires
#      curated_layout_violation; a missing wiki/meta/ fires too.
#   3. An overview.md still carrying the OVERVIEW-NARRATIVE machine block
#      fires curated_layout_violation.
#   4. A sub-indexed type dir with pages but no index.md warns
#      missing_subindex.
#   5. A pre-0.0.8 base (schema 0.0.7) with flat-root control files fires
#      NOTHING — the curated assertions are schema-gated.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HEALTH="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-health/scripts/health.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# Build one curated-layout fixture wiki at schema 0.0.8.
build_wiki() {
  # $1 = root dir, $2 = schema_version
  rm -rf "$1"
  mkdir -p "$1/wiki/sources" "$1/wiki/meta" "$1/.cogni-wiki"
  cat > "$1/.cogni-wiki/config.json" <<EOF
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 1, "schema_version": "$2"}
EOF
  printf '# Fixture Base\n\n## Regulierung\n\n[Sources (1)](sources/index.md)\n' > "$1/wiki/index.md"
  printf '_The overview narrative now lives in [index.md](index.md)._\n\n## Recent syntheses\n\n- none yet\n' > "$1/wiki/overview.md"
  printf '# Log\n' > "$1/wiki/meta/log.md"
  printf '# Context brief\n' > "$1/wiki/meta/context_brief.md"
  printf '# Open questions\n' > "$1/wiki/meta/open_questions.md"
  cat > "$1/wiki/sources/eu-ai-act-scope.md" <<'EOF'
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
  # machine-owned per-type sub-index — must be invisible to the page walk
  printf '# Sources\n\n- [[eu-ai-act-scope]] — Scope of the EU AI Act.\n' > "$1/wiki/sources/index.md"
}

# ---------------------------------------------------------------------------
# 1. Clean curated wiki: zero errors, sub-index exempt from entries_count
# ---------------------------------------------------------------------------
WIKI="$WORK/clean"
build_wiki "$WIKI" "0.0.8"
CLEAN_OUT="$WORK/clean.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$CLEAN_OUT"

assert_grep '"success": true' "$CLEAN_OUT" "clean curated wiki: health succeeds"
if grep -q 'curated_layout_violation' "$CLEAN_OUT"; then
  red "FAIL: clean curated wiki raised curated_layout_violation"
  errors=$((errors + 1))
else
  green "PASS: clean curated wiki has no curated_layout_violation"
fi
assert_grep '"entries_count_actual": 1' "$CLEAN_OUT" \
  "sub-index excluded: entries_count_actual is 1 (the source page only)"
if grep -q 'missing_subindex' "$CLEAN_OUT"; then
  red "FAIL: clean wiki warned missing_subindex despite sources/index.md"
  errors=$((errors + 1))
else
  green "PASS: present sub-index raises no missing_subindex warning"
fi
assert_grep '"errors": 0' "$CLEAN_OUT" "clean curated wiki: zero errors"

# ---------------------------------------------------------------------------
# 2. Flat-root control file + missing meta/ at schema >= 0.0.8
# ---------------------------------------------------------------------------
WIKI="$WORK/flatroot"
build_wiki "$WIKI" "0.0.8"
printf '# Context brief\n' > "$WIKI/wiki/context_brief.md"
FLAT_OUT="$WORK/flatroot.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$FLAT_OUT"
assert_grep 'curated_layout_violation' "$FLAT_OUT" \
  "flat-root context_brief.md fires curated_layout_violation"
assert_grep 'misplaced_control_files' "$FLAT_OUT" \
  "violation message points at the lint fix class"

rm -rf "$WIKI/wiki/meta"
NOMETA_OUT="$WORK/nometa.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$NOMETA_OUT"
assert_grep 'wiki/meta/ missing' "$NOMETA_OUT" \
  "missing wiki/meta/ fires curated_layout_violation"

# ---------------------------------------------------------------------------
# 3. overview.md still carrying the narrative machine block
# ---------------------------------------------------------------------------
WIKI="$WORK/narrative"
build_wiki "$WIKI" "0.0.8"
cat > "$WIKI/wiki/overview.md" <<'EOF'
# Overview

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
Unfolded narrative.
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->
EOF
NARR_OUT="$WORK/narrative.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$NARR_OUT"
assert_grep 'OVERVIEW-NARRATIVE' "$NARR_OUT" \
  "unfolded overview narrative fires curated_layout_violation"

# ---------------------------------------------------------------------------
# 4. Sub-indexed type dir with pages but no index.md warns
# ---------------------------------------------------------------------------
WIKI="$WORK/nosubindex"
build_wiki "$WIKI" "0.0.8"
rm "$WIKI/wiki/sources/index.md"
NOSUB_OUT="$WORK/nosubindex.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$NOSUB_OUT"
assert_grep 'missing_subindex' "$NOSUB_OUT" \
  "pages without a sub-index warn missing_subindex"

# ---------------------------------------------------------------------------
# 5. Pre-0.0.8 base: curated assertions stay silent
# ---------------------------------------------------------------------------
WIKI="$WORK/legacy"
build_wiki "$WIKI" "0.0.7"
rm -rf "$WIKI/wiki/meta"
printf '# Log\n' > "$WIKI/wiki/log.md"
LEGACY_OUT="$WORK/legacy.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$LEGACY_OUT"
if grep -q 'curated_layout_violation\|missing_subindex' "$LEGACY_OUT"; then
  red "FAIL: pre-0.0.8 base fired curated-layout findings (schema gate broken)"
  errors=$((errors + 1))
else
  green "PASS: pre-0.0.8 base fires no curated-layout findings"
fi

# ---------------------------------------------------------------------------
if [ "$errors" -gt 0 ]; then
  red "$errors assertion(s) failed"
  exit 1
fi
green "all curated-layout health assertions passed"
