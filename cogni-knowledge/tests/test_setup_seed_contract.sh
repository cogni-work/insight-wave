#!/usr/bin/env bash
# test_setup_seed_contract.sh — knowledge-setup Step 3.5 (seed the curated
# wiki-output layout for NEW wikis) contract assertions.
#
# Step 3.5 turns the schema_version 0.0.9 curated layout the SKILL's contract
# section declares into the actual seeded shape for a fresh wiki. It is an
# LLM-executed Bash recipe (the skill has no Write tool), so the only thing CI
# can guard is that the recipe's load-bearing invariants stay present in the
# SKILL prose. This file is the sibling of test_finalize_contract.sh /
# test_ingest_contract.sh — content-invariant grep tests over the SKILL.
#
# The invariants intentionally pin the points that already drifted once between
# the PR description and the merged code (overview.md kept, not removed) and the
# robustness choices in the heredoc seeds (quoted vs unquoted delimiters).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"
if [ ! -f "$SETUP" ]; then
  red "FAIL: skills/knowledge-setup/SKILL.md not found"
  exit 1
fi

# --- Step 3.5 exists + is gated to the fresh-wiki branch -----------------
assert_grep '### 3.5 Seed the curated wiki-output layout' "$SETUP" "knowledge-setup: Step 3.5 heading present"
assert_grep 'only on the fresh-wiki branch' "$SETUP" "knowledge-setup: Step 3.5 runs only on the fresh-wiki branch"
assert_grep 'Skip it' "$SETUP" "knowledge-setup: Step 3.5 documents the skip path (existing wiki / --reframe)"

# --- (a) per-type sub-index stubs via the canonical renderer -------------
# Delegated to sub_index.py — NOT hand-authored markers (no-duplicate-upstream).
assert_grep 'resolve_wiki_scripts wiki-ingest' "$SETUP" "knowledge-setup: resolves WIKI_INGEST_SCRIPTS (mirrors knowledge-finalize Step 0)"
assert_grep 'sub_index.py' "$SETUP" "knowledge-setup: (a) seeds per-type stubs via sub_index.py render"
assert_grep 'concepts entities people sources questions syntheses' "$SETUP" "knowledge-setup: (a) loops all six page types"
assert_grep 'MACHINE-OWNED:<TYPE>-INDEX' "$SETUP" "knowledge-setup: (a) documents the per-type ownership marker the renderer writes"

# --- (b) curated root files: index.md (curated MAP + narrative intro) +
#     overview.md (stub) — the curated-root layout folds the overview narrative
#     into the index.md intro and retires overview.md as the narrative home.
assert_grep 'wiki/index.md' "$SETUP" "knowledge-setup: (b) seeds wiki/index.md (curated portal front door)"
assert_grep 'wiki/overview.md' "$SETUP" "knowledge-setup: (b) seeds wiki/overview.md (stub)"
assert_grep 'MACHINE-OWNED:ROOT-INDEX' "$SETUP" "knowledge-setup: index.md carries the ROOT-INDEX ownership marker"
assert_grep 'MACHINE-OWNED:OVERVIEW-NARRATIVE' "$SETUP" "knowledge-setup: OVERVIEW-NARRATIVE block is seeded (now in the index.md intro)"
assert_grep 'narrative now lives in' "$SETUP" "knowledge-setup: overview.md is a stub pointing at the curated map (narrative moved to index.md)"
# The curated MAP carries no per-page bullet line, so the vendored
# strip_seed_placeholder has nothing to strip — assert the contract is documented.
assert_grep 'strip_seed_placeholder' "$SETUP" "knowledge-setup: documents the strip_seed_placeholder self-clean contract"
assert_grep 'narrative-splice --target-file index.md' "$SETUP" "knowledge-setup: documents the OVERVIEW-NARRATIVE redirect into the index.md intro"

# --- heredoc-delimiter hygiene -------------------------------------------
# index.md + overview.md need NO shell expansion, so they use a QUOTED
# delimiter (<<'EOF') — protects a substituted <knowledge-title> containing a
# $ or backtick. The log heredoc (c) is the ONE place that stays unquoted
# because it relies on $(date). Both must hold for the recipe to be safe.
assert_grep "wiki/index.md <<'EOF'" "$SETUP" "knowledge-setup: index.md heredoc uses a quoted delimiter (no accidental expansion of the title)"
assert_grep "wiki/overview.md <<'EOF'" "$SETUP" "knowledge-setup: overview.md heredoc uses a quoted delimiter"
assert_grep 'wiki/meta/log.md <<EOF' "$SETUP" "knowledge-setup: log.md heredoc stays unquoted (relies on \$(date))"
assert_grep 'date +%Y-%m-%d' "$SETUP" "knowledge-setup: (c) log line stamps the date via \$(date)"

# --- (c) control log under wiki/meta/, seeded directly -------------------
assert_grep 'wiki/meta/log.md' "$SETUP" "knowledge-setup: (c) seeds wiki/meta/log.md"
assert_grep 'mkdir -p <knowledge_root>/wiki/meta' "$SETUP" "knowledge-setup: (c) creates the wiki/meta dir"
# Must be seeded DIRECTLY, not via control-path.py (which resolves to the flat
# legacy path until the meta file exists — the bootstrap caveat).
assert_grep 'not via `control-path.py log`' "$SETUP" "knowledge-setup: (c) documents why log.md is seeded directly (control-path.py bootstrap caveat)"

# --- (d) drop ONLY the flat log; KEEP overview.md ------------------------
# This is the invariant that drifted between PR description (which said
# "removes overview.md") and the merged code. Lock it down: the flat log is
# removed, overview.md is explicitly KEPT.
assert_grep 'rm -f <knowledge_root>/wiki/log.md' "$SETUP" "knowledge-setup: (d) removes the flat wiki/log.md"
assert_grep 'Keep `wiki/overview.md`' "$SETUP" "knowledge-setup: (d) explicitly KEEPS wiki/overview.md (the narrative home)"
# Defence-in-depth: no instruction to delete overview.md anywhere in the step.
assert_not_grep 'rm -f <knowledge_root>/wiki/overview.md' "$SETUP" "knowledge-setup: NEVER removes wiki/overview.md"

# --- (e) advertise schema_version 0.0.9 via the locked config_bump.py ----
assert_grep 'config_bump.py' "$SETUP" "knowledge-setup: (e) bumps schema_version via the locked config_bump.py"
assert_grep 'schema_version --set-string 0.0.9' "$SETUP" "knowledge-setup: (e) sets schema_version to 0.0.9"

# --- the post-step invariant the future knowledge-health check will assert
assert_grep 'competing root file' "$SETUP" "knowledge-setup: invariant holds across the first knowledge-finalize (overview folded into index.md, root MAP re-rendered, no competing root file)"

if [ $errors -eq 0 ]; then
  green ""
  green "knowledge-setup Step 3.5 seed-layout contract: ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
