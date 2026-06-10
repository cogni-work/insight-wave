#!/usr/bin/env bash
# test_migrate_layout.sh — functional test for scripts/migrate-layout.py (the
# curated-layout migrator that converges an EXISTING pre-0.0.8 wiki onto the
# layout knowledge-setup seeds for new ones).
#
# Executes the real code path against a synthetic old-structure wiki: flat
# control files at wiki/ root, a flat-bullet root index.md carrying a HUMAN
# (non-sentineled) theme lead-in, an overview.md holding the
# MACHINE-OWNED:OVERVIEW-NARRATIVE block, schema_version 0.0.7.
#
# Covers:
#   1. Dry-run (default, no --apply) reports the planned control-file moves +
#      the would-fold overview verdict, stages the proposed indexes to
#      .cogni-wiki/*-proposed.md (the content-diff surface), and leaves every
#      live file byte-identical — no move, no fold, no schema bump.
#   2. --apply migrates: control files land under wiki/meta/, the overview
#      narrative folds into the index.md intro (and the overview keeps its
#      ## Recent syntheses list), the root becomes the curated MAP (per-page
#      bullets dropped, count-links present), the per-type sub-indexes render,
#      and schema_version reads 0.0.8.
#   3. The HUMAN lead-in on the theme section survives the lossy root split
#      verbatim (addendum-B4 guarantee, inherited from root_index.py).
#   4. Second --apply run is a clean no-op (action=noop, already_migrated).
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/migrate-layout.py"
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

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/sources" "$WIKI/.cogni-wiki"

# -- old-structure config: schema_version 0.0.7 ------------------------------
cat > "$WIKI/.cogni-wiki/config.json" <<'EOF'
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 1, "schema_version": "0.0.7"}
EOF

# -- flat control files at the wiki/ root ------------------------------------
printf '# Log\n\n## [2026-01-01] setup | wiki initialized\n' > "$WIKI/wiki/log.md"
printf '# Context brief\n\nA brief.\n' > "$WIKI/wiki/context_brief.md"
printf '# Open questions\n\n- none\n' > "$WIKI/wiki/open_questions.md"

# -- old-style flat root index: per-page bullets + a HUMAN theme lead-in -----
cat > "$WIKI/wiki/index.md" <<'EOF'
# Fixture Base

## Regulierung

Hand-written human lead-in that must survive the split verbatim.

- [[eu-ai-act-scope]] — Scope of the EU AI Act.
EOF

# -- overview.md still carrying the narrative block --------------------------
cat > "$WIKI/wiki/overview.md" <<'EOF'
# Overview

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
The base covers EU AI regulation fundamentals.
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->

## Recent syntheses

- [[some-synthesis]] — A prior synthesis bullet that must be preserved.
EOF

# -- one source page with frontmatter-resident theme membership --------------
cat > "$WIKI/wiki/sources/eu-ai-act-scope.md" <<'EOF'
---
id: eu-ai-act-scope
type: source
title: "Scope of the EU AI Act"
theme_label: "Regulierung"
sources:
  - https://example.org/ai-act
---

# Scope of the EU AI Act

Body text.
EOF

# ---------------------------------------------------------------------------
# 1. Dry-run: reports + stages, touches nothing live
# ---------------------------------------------------------------------------
cp "$WIKI/wiki/index.md" "$WORK/index.before"
cp "$WIKI/wiki/overview.md" "$WORK/overview.before"

DRY_OUT="$WORK/dry.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" > "$DRY_OUT"

assert_grep '"success": true' "$DRY_OUT" "dry-run succeeds"
assert_grep '"action": "dry_run"' "$DRY_OUT" "dry-run is the default (no --apply)"
assert_grep '"action": "would_fold"' "$DRY_OUT" "dry-run reports the overview fold"
assert_grep 'root-index-proposed.md' "$DRY_OUT" "dry-run stages the proposed root MAP (content-diff surface)"

if cmp -s "$WIKI/wiki/index.md" "$WORK/index.before" \
   && cmp -s "$WIKI/wiki/overview.md" "$WORK/overview.before" \
   && [ -f "$WIKI/wiki/log.md" ] && [ ! -e "$WIKI/wiki/meta/log.md" ]; then
  green "PASS: dry-run leaves live files byte-identical and moves nothing"
else
  red "FAIL: dry-run touched live files"
  errors=$((errors + 1))
fi

assert_grep '"schema_version": "0.0.7"' "$WIKI/.cogni-wiki/config.json" \
  "dry-run does not bump schema_version"

# ---------------------------------------------------------------------------
# 2. --apply migrates the base
# ---------------------------------------------------------------------------
APPLY_OUT="$WORK/apply.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply > "$APPLY_OUT"

assert_grep '"success": true' "$APPLY_OUT" "apply succeeds"
assert_grep '"action": "migrated"' "$APPLY_OUT" "apply reports action=migrated"

for f in log.md context_brief.md open_questions.md; do
  if [ -f "$WIKI/wiki/meta/$f" ] && [ ! -e "$WIKI/wiki/$f" ]; then
    green "PASS: $f relocated to wiki/meta/"
  else
    red "FAIL: $f not relocated to wiki/meta/"
    errors=$((errors + 1))
  fi
done

assert_grep 'MACHINE-OWNED:OVERVIEW-NARRATIVE:START' "$WIKI/wiki/index.md" \
  "overview narrative folded into index.md intro"
assert_grep 'EU AI regulation fundamentals' "$WIKI/wiki/index.md" \
  "narrative inner text relocated verbatim"

if grep -q 'MACHINE-OWNED:OVERVIEW-NARRATIVE' "$WIKI/wiki/overview.md"; then
  red "FAIL: overview.md still carries the narrative block after the fold"
  errors=$((errors + 1))
else
  green "PASS: overview.md narrative block retired"
fi
assert_grep 'Recent syntheses' "$WIKI/wiki/overview.md" \
  "overview.md keeps the ## Recent syntheses list (non-destructive)"
assert_grep 'some-synthesis' "$WIKI/wiki/overview.md" \
  "overview.md keeps its synthesis bullet byte-for-byte"

# Curated MAP shape: bullets dropped, count-link span present
if grep -q -- '- \[\[eu-ai-act-scope\]\]' "$WIKI/wiki/index.md"; then
  red "FAIL: per-page bullet survived on the curated root (should live in sub-index)"
  errors=$((errors + 1))
else
  green "PASS: per-page bullets dropped from the curated root"
fi
assert_grep 'MACHINE-OWNED:ROOT-LINKS:START' "$WIKI/wiki/index.md" \
  "curated root carries the ROOT-LINKS count span"

# 3. Addendum-B4: the human lead-in survives the split verbatim
assert_grep 'Hand-written human lead-in that must survive the split verbatim.' \
  "$WIKI/wiki/index.md" "human (non-sentineled) theme lead-in preserved verbatim"

# Sub-index rendered with the page bullet relocated there
assert_grep 'eu-ai-act-scope' "$WIKI/wiki/sources/index.md" \
  "sources sub-index carries the relocated page bullet"

assert_grep '"schema_version": "0.0.8"' "$WIKI/.cogni-wiki/config.json" \
  "schema_version bumped to 0.0.8"

assert_grep 'migrate | curated layout' "$WIKI/wiki/meta/log.md" \
  "migration logged to wiki/meta/log.md"

# ---------------------------------------------------------------------------
# 4. Second --apply run is a clean no-op
# ---------------------------------------------------------------------------
cp "$WIKI/wiki/index.md" "$WORK/index.after"
NOOP_OUT="$WORK/noop.json"
python3 "$SCRIPT" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" --apply > "$NOOP_OUT"

assert_grep '"success": true' "$NOOP_OUT" "second apply succeeds"
assert_grep '"action": "noop"' "$NOOP_OUT" "second apply is a no-op"
assert_grep '"reason": "already_migrated"' "$NOOP_OUT" "no-op reason is already_migrated"

if cmp -s "$WIKI/wiki/index.md" "$WORK/index.after"; then
  green "PASS: second apply leaves the curated root byte-identical"
else
  red "FAIL: second apply changed the curated root"
  errors=$((errors + 1))
fi

# ---------------------------------------------------------------------------
if [ "$errors" -gt 0 ]; then
  red "$errors assertion(s) failed"
  exit 1
fi
green "all migrate-layout assertions passed"
