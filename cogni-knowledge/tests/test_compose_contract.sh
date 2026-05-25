#!/usr/bin/env bash
# test_compose_contract.sh — Phase 5 (knowledge-compose + wiki-composer)
# contract assertions.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md / agent-md content invariants — these checks catch a
# path, flag, or step silently disappearing from the contract, not LLM
# behaviour. The assertions below are self-documenting; do not maintain a
# parallel coverage list here (it will drift from the actual asserts).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-compose SKILL.md ------------------------------------------
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
if [ ! -f "$COMPOSE" ]; then
  red "FAIL: skills/knowledge-compose/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-compose' "$COMPOSE" "knowledge-compose: frontmatter name"
assert_grep 'plan.json' "$COMPOSE" "knowledge-compose: reads plan.json"
assert_grep 'ingest-manifest.json' "$COMPOSE" "knowledge-compose: reads ingest-manifest.json"
assert_grep 'draft-v' "$COMPOSE" "knowledge-compose: writes draft-vN.md"
assert_grep 'citation-manifest.json' "$COMPOSE" "knowledge-compose: writes citation-manifest.json"
assert_grep '"schema_version": "0.1.0"' "$COMPOSE" "knowledge-compose: citation-manifest schema 0.1.0"
assert_grep 'Task(wiki-composer' "$COMPOSE" "knowledge-compose: dispatches wiki-composer via Task"
# Slice 13 (#300): threads the project's output_language into the composer dispatch.
assert_grep 'OUTPUT_LANGUAGE=' "$COMPOSE" "knowledge-compose: threads OUTPUT_LANGUAGE into the wiki-composer dispatch (#300)"
assert_grep 'output_language' "$COMPOSE" "knowledge-compose: reads plan.json::output_language (#300)"
assert_grep 'probe_plugin cogni-wiki' "$COMPOSE" "knowledge-compose: probes cogni-wiki (clean-break)"
assert_grep 'RESUME_FROM_OUTLINE' "$COMPOSE" "knowledge-compose: F11 — passes RESUME_FROM_OUTLINE to composer"
assert_grep 'writer-outline-v' "$COMPOSE" "knowledge-compose: F11 — detects writer-outline-vN.json for recovery"
assert_grep 'wiki/log.md' "$COMPOSE" "knowledge-compose: appends to wiki/log.md"
# Match the actual log-line shape Step 6 emits (`## [DATE] compose | project=...`)
# rather than the bare word `compose`, which would also match the filename,
# skill name, and every doc paragraph.
assert_grep '\] compose | project=' "$COMPOSE" "knowledge-compose: emits the '## [DATE] compose | project=...' log-line shape"
# Defence-in-depth: confirm there is no obsolete Skill("cogni-knowledge:wiki-composer)
# dispatch. Agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:wiki-composer' "$COMPOSE" "knowledge-compose: no Skill('cogni-knowledge:wiki-composer) — agents go through Task"
# Clean-break: no cogni-research input shapes leaking through.
assert_not_grep 'aggregated-context.json' "$COMPOSE" "knowledge-compose: does NOT reference aggregated-context.json (clean-break — that's cogni-research's input shape)"
assert_not_grep '01-contexts/data' "$COMPOSE" "knowledge-compose: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$COMPOSE" "knowledge-compose: does NOT reference cogni-research's 02-sources/data"
# allowed-tools must include Task (we dispatch wiki-composer).
COMPOSE_TOOLS_LINE=$(grep '^allowed-tools:' "$COMPOSE" || true)
if echo "$COMPOSE_TOOLS_LINE" | grep -q Task; then
  green "PASS: knowledge-compose: allowed-tools includes Task"
else
  red "FAIL: knowledge-compose: allowed-tools must include Task"
  red "  got: $COMPOSE_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- wiki-composer agent -------------------------------------------------
COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
if [ ! -f "$COMPOSER" ]; then
  red "FAIL: agents/wiki-composer.md not found"
  exit 1
fi
assert_grep 'name: wiki-composer' "$COMPOSER" "wiki-composer: frontmatter name"
assert_grep 'Forked from cogni-research/agents/writer.md' "$COMPOSER" "wiki-composer: declares fork lineage"
assert_grep 'wiki/index.md' "$COMPOSER" "wiki-composer: reads wiki/index.md"
assert_grep 'wiki/sources/' "$COMPOSER" "wiki-composer: reads wiki/sources/<slug>.md pages"
assert_grep 'wiki/syntheses/' "$COMPOSER" "wiki-composer: reads prior wiki/syntheses/*.md"
assert_grep '\[\[sources/' "$COMPOSER" "wiki-composer: emits [[sources/<slug>]] wikilink citations"
assert_grep 'writer-outline-v' "$COMPOSER" "wiki-composer: F11 — persists writer-outline-vN.json"
assert_grep 'RESUME_FROM_OUTLINE' "$COMPOSER" "wiki-composer: F11 — honours RESUME_FROM_OUTLINE input"
assert_grep 'citation-manifest.json' "$COMPOSER" "wiki-composer: writes citation-manifest.json"
assert_grep 'draft_position' "$COMPOSER" "wiki-composer: citation-manifest entry has draft_position (best-effort locator)"
assert_grep 'wiki_slug' "$COMPOSER" "wiki-composer: citation-manifest entry has wiki_slug"
assert_grep 'claim_id' "$COMPOSER" "wiki-composer: citation-manifest entry has claim_id"
# F22: each citation carries a stable id and the verbatim cited sentence.
assert_grep 'draft_sentence' "$COMPOSER" "wiki-composer: citation-manifest entry has draft_sentence (F22 stable alignment surface)"
assert_grep 'cit-001' "$COMPOSER" "wiki-composer: citation ids are the cit-NNN stable join key"
assert_grep 'pre_extracted_claims' "$COMPOSER" "wiki-composer: looks up claim_id in pre_extracted_claims (zero-network alignment surface)"
assert_grep 'draft-v' "$COMPOSER" "wiki-composer: writes output/draft-vN.md"

# Scope-discipline negatives — these deferred surfaces may appear in the
# header HTML comment (as provenance documenting what the fork dropped)
# but MUST NOT appear in the input parameter table or as live workflow.
# Pattern is the parameter-table-row form `| \`TOKEN\` |`.
assert_not_grep '01-contexts/data' "$COMPOSER" "wiki-composer: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$COMPOSER" "wiki-composer: does NOT reference cogni-research's 02-sources/data"
# Slice 13 (#300): OUTPUT_LANGUAGE + CITATION_FORMAT are now LIVE parameter rows
# (the composer honours the project's output_language and a numbered citation
# format). The remaining three stay deferred.
for token in OUTPUT_LANGUAGE CITATION_FORMAT; do
  if grep -q "| \`${token}\` |" "$COMPOSER"; then
    green "PASS: wiki-composer: ${token} parameter row present (#300 — language/citation-format aware)"
  else
    red "FAIL: wiki-composer: ${token} parameter row missing (#300 expects it as a live input)"
    errors=$((errors + 1))
  fi
done
for token in PROSE_DENSITY EXPANSION_NOTES STORY_ARC_ID; do
  if grep -q "| \`${token}\` |" "$COMPOSER"; then
    red "FAIL: wiki-composer: ${token} parameter row present (deferred surface)"
    errors=$((errors + 1))
  else
    green "PASS: wiki-composer: no ${token} parameter row (deferred)"
  fi
done
# #300 inline-citation convention: numbered [N] inline, wikilinks confined to
# the reference list (never in prose), numbered in first-appearance order.
assert_grep 'first-appearance order' "$COMPOSER" "wiki-composer: numbers [N] in first-appearance order (#300)"
assert_grep '\[\[N\]\]' "$COMPOSER" "wiki-composer: forbids the Obsidian-colliding [[N]] form (#300)"
assert_grep 'reference list, never in prose' "$COMPOSER" "wiki-composer: wikilinks confined to the reference list, not prose (#300)"
assert_grep 'OUTPUT_LANGUAGE' "$COMPOSER" "wiki-composer: honours OUTPUT_LANGUAGE for output + headings (#300)"
# `aggregated-context.json` is cogni-research's input shape. The fork
# header explains it was dropped; the composer must not READ it. The
# read-input contract lives in Phase 0 — assert the workflow phase
# doesn't mention it (the header HTML comment is exempt).
if awk '/^### Phase 0/{p=1; next} /^### Phase/{p=0} p' "$COMPOSER" | grep -q 'aggregated-context.json'; then
  red "FAIL: wiki-composer: Phase 0 reads aggregated-context.json (clean-break broken)"
  errors=$((errors + 1))
else
  green "PASS: wiki-composer: Phase 0 does NOT read aggregated-context.json (clean-break)"
fi

# Frontmatter tools: single-pass agent — must include Read/Write/Glob/Grep,
# must NOT include Task (no sub-dispatch) or WebFetch (no re-fetch).
COMPOSER_TOOLS_LINE=$(grep '^tools:' "$COMPOSER" || true)
for required in '"Read"' '"Write"' '"Glob"' '"Grep"'; do
  if echo "$COMPOSER_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: wiki-composer: frontmatter tools: includes $required"
  else
    red "FAIL: wiki-composer: frontmatter tools: missing $required"
    red "  got: $COMPOSER_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$COMPOSER_TOOLS_LINE" | grep -qE 'WebFetch|"Task"'; then
  red "FAIL: wiki-composer: frontmatter tools: must not include WebFetch or Task (single-pass, no sub-dispatch)"
  red "  got: $COMPOSER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-composer: frontmatter tools: no WebFetch, no Task (single-pass, read-the-wiki only)"
fi

# --- Phase 5 contract token match ----------------------------------------
# The inverted-pipeline.md Phase 5 contract names three reads and two
# writes; the composer must mention all of them at least once.
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 5 — `knowledge-compose`' "$PIPELINE" "inverted-pipeline.md: Phase 5 section header anchored"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
