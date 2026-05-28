#!/usr/bin/env bash
# test_distill_contract.sh — grep-based contract assertions for the Phase 4.5
# distillation surface (#336): the knowledge-distill skill + the concept-distiller
# agent. Script behaviour (concept-store.py) is covered by test_concept_store.sh;
# the lifted primitives + claim-dedup by test_knowledge_lib.sh.
#
# Per tests/README.md §"Contract tests": for pure-LLM skills/agents, regression
# coverage is SKILL.md / agent-md content invariants — catches a path/flag/step
# silently disappearing. Does NOT assert LLM behaviour.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0

# --- knowledge-distill SKILL.md ----------------------------------------------
SKILL="$PLUGIN_ROOT/skills/knowledge-distill/SKILL.md"
if [ ! -f "$SKILL" ]; then
  red "FAIL: skills/knowledge-distill/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-distill' "$SKILL" "knowledge-distill: frontmatter name"
assert_grep 'Phase 4.5' "$SKILL" "knowledge-distill: announces Phase 4.5"
assert_grep 'ingest .* distill .* compose' "$SKILL" "knowledge-distill: placed between ingest and compose"
assert_grep 'fail-soft' "$SKILL" "knowledge-distill: fail-soft posture (optional, never blocks compose)"
assert_grep 'ingest-manifest.json' "$SKILL" "knowledge-distill: reads ingest-manifest.json"
assert_grep 'parse_pre_extracted_claims' "$SKILL" "knowledge-distill: builds claim bundle from source pages"
assert_grep 'Task(concept-distiller' "$SKILL" "knowledge-distill: dispatches concept-distiller via Task"
assert_grep 'concept-store.py merge' "$SKILL" "knowledge-distill: calls concept-store.py merge"
assert_grep 'wiki-scripts-dir' "$SKILL" "knowledge-distill: threads --wiki-scripts-dir (for _wiki_lock import)"
assert_grep 'resolve_wiki_scripts' "$SKILL" "knowledge-distill: resolves cogni-wiki scripts (shared helper)"
assert_grep 'backlink_audit.py' "$SKILL" "knowledge-distill: forms edges via backlink_audit.py --apply-plan"
assert_grep 'apply-plan' "$SKILL" "knowledge-distill: curated backlink apply-plan (LLM-curated targets)"
assert_grep 'wiki_index_update.py' "$SKILL" "knowledge-distill: files pages under Concepts/Entities"
assert_grep 'max-summary 240' "$SKILL" "knowledge-distill: --max-summary 240 backstop (#324 posture)"
assert_grep 'config_bump.py' "$SKILL" "knowledge-distill: entries_count lockstep bump"
assert_grep 'action == "inserted"' "$SKILL" "knowledge-distill: counts only inserted rows (n_new lockstep, #302 posture)"
assert_grep 'distill | project=' "$SKILL" "knowledge-distill: appends a distill log line"
assert_grep 'claims_deduped_total' "$SKILL" "knowledge-distill: surfaces the claim-dedup ratio"
assert_grep 'bundle_hash' "$SKILL" "knowledge-distill: resume no-op via bundle hash"
assert_grep 'Concepts' "$SKILL" "knowledge-distill: Concepts index category"
assert_grep 'Entities' "$SKILL" "knowledge-distill: Entities index category"
# Must NOT run the conformance gate (finalize Step 10.5 owns it once).
assert_not_grep 'health.py asserts' "$SKILL" "knowledge-distill: does NOT run the conformance gate itself"
assert_grep 'Task' "$SKILL" "knowledge-distill: Task in allowed-tools"

# --- concept-distiller agent -------------------------------------------------
AGENT="$PLUGIN_ROOT/agents/concept-distiller.md"
if [ ! -f "$AGENT" ]; then
  red "FAIL: agents/concept-distiller.md not found"
  exit 1
fi
assert_grep 'name: concept-distiller' "$AGENT" "concept-distiller: frontmatter name"
assert_grep 'model: sonnet' "$AGENT" "concept-distiller: model sonnet"
assert_grep 'CLAIM_BUNDLE_PATH' "$AGENT" "concept-distiller: reads the claim bundle"
assert_grep 'SLUG_INDEX_PATH' "$AGENT" "concept-distiller: reads the existing-slug index"
assert_grep 'RECORDS_OUTPUT_PATH' "$AGENT" "concept-distiller: writes raw-text records"
assert_grep 'concept' "$AGENT" "concept-distiller: proposes concept pages"
assert_grep 'entity' "$AGENT" "concept-distiller: proposes entity pages"
# Pure-proposal invariants — the #325 + claim-dedup discipline.
assert_grep 'never compute slugs\|never computes slugs\|do not compute slugs\|does NOT compute slugs\|never compute' "$AGENT" "concept-distiller: never computes slugs"
assert_grep 'raw text' "$AGENT" "concept-distiller: writes raw text, never JSON/YAML (#325)"
assert_grep 'concept-store.py' "$AGENT" "concept-distiller: defers dedup/serialization to concept-store.py"
# Tools: Read + Write only (no Bash, no Task, no WebFetch/WebSearch) — the exact
# tools-list line is the guard (the prose legitimately says "does NOT WebSearch").
assert_grep 'tools: \["Read", "Write"\]' "$AGENT" "concept-distiller: tools Read + Write only"

if [ "$errors" -eq 0 ]; then
  green ""
  green "knowledge-distill + concept-distiller contract: all pass."
  exit 0
else
  red "knowledge-distill + concept-distiller contract: $errors failure(s)."
  exit 1
fi
