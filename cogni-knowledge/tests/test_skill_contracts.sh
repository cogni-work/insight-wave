#!/usr/bin/env bash
# test_skill_contracts.sh - grep-based contract assertions for the v0.0.17
# Phase 1/2/3 skills + agents.
#
# Per the convention at tests/README.md §"Contract tests": for pure LLM
# skills, regression coverage is SKILL.md content invariants. These checks
# catch the most likely failure mode — a path, flag, or step silently
# disappearing from the contract. They do NOT assert LLM behaviour.
#
# Covers:
#   - knowledge-plan: writes plan.json schema 0.1.0, probes only cogni-wiki,
#     does not append binding.
#   - knowledge-curate: reads plan.json, dispatches source-curator, merges
#     through candidate-store.py append-batch, reads curator_defaults from
#     binding.
#   - knowledge-fetch: reads candidates.json, dispatches source-fetcher,
#     reads fetch_cache_max_age_days from binding, calls fetch-cache.py stat.
#   - source-curator agent: forked header, candidates.json output, drops
#     dimensions/annotation emission.
#   - source-fetcher agent: webfetch + cobrowse_interactive enum,
#     fetch-cache.py store/fetch contract.
#   - Clean-break invariant: no `cogni-research:` or `cogni-claims:` skill
#     dispatch references in any of the new files.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-plan SKILL.md ---------------------------------------------
PLAN="$PLUGIN_ROOT/skills/knowledge-plan/SKILL.md"
if [ ! -f "$PLAN" ]; then
  red "FAIL: knowledge-plan/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-plan' "$PLAN" "knowledge-plan: frontmatter name"
assert_grep '"schema_version": "0.1.0"' "$PLAN" "knowledge-plan: plan.json schema 0.1.0 in spec"
assert_grep '3-7 sub-questions' "$PLAN" "knowledge-plan: 3-7 sub-question contract"
assert_grep 'probe_plugin cogni-wiki wiki-setup' "$PLAN" "knowledge-plan: probes cogni-wiki"
assert_grep 'knowledge-finalize' "$PLAN" "knowledge-plan: defers binding append to M9 knowledge-finalize"
assert_not_grep 'probe_plugin cogni-research' "$PLAN" "knowledge-plan: does NOT probe cogni-research (clean break)"

# --- knowledge-curate SKILL.md -------------------------------------------
CURATE="$PLUGIN_ROOT/skills/knowledge-curate/SKILL.md"
if [ ! -f "$CURATE" ]; then
  red "FAIL: knowledge-curate/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-curate' "$CURATE" "knowledge-curate: frontmatter name"
assert_grep 'candidate-store.py init' "$CURATE" "knowledge-curate: calls candidate-store.py init"
assert_grep 'candidate-store.py append-batch' "$CURATE" "knowledge-curate: calls candidate-store.py append-batch"
assert_grep 'curator_defaults' "$CURATE" "knowledge-curate: reads curator_defaults from binding"
assert_grep 'max_candidates_per_sq' "$CURATE" "knowledge-curate: reads max_candidates_per_sq"
assert_grep 'score_threshold' "$CURATE" "knowledge-curate: reads score_threshold"
assert_grep 'Task(source-curator' "$CURATE" "knowledge-curate: dispatches source-curator via Task (matches cogni-research convention)"
# Belt-and-braces: confirm the obsolete Skill(\"cogni-knowledge:source-curator\")
# dispatch is not lingering. Agents live at agents/, not skills/.
assert_not_grep 'Skill("cogni-knowledge:source-curator' "$CURATE" "knowledge-curate: no Skill('cogni-knowledge:source-curator) — agents go through Task"
assert_grep 'Task' "$CURATE" "knowledge-curate: Task listed in allowed-tools"

# --- knowledge-fetch SKILL.md --------------------------------------------
FETCH="$PLUGIN_ROOT/skills/knowledge-fetch/SKILL.md"
if [ ! -f "$FETCH" ]; then
  red "FAIL: knowledge-fetch/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-fetch' "$FETCH" "knowledge-fetch: frontmatter name"
assert_grep 'fetch_cache_max_age_days' "$FETCH" "knowledge-fetch: reads fetch_cache_max_age_days"
assert_grep 'fetch-cache.py stat' "$FETCH" "knowledge-fetch: calls fetch-cache.py stat in summary"
assert_grep 'Task(source-fetcher' "$FETCH" "knowledge-fetch: dispatches source-fetcher via Task"
assert_grep 'fetch-manifest.json' "$FETCH" "knowledge-fetch: writes fetch-manifest.json"
assert_not_grep 'Skill("cogni-knowledge:source-fetcher' "$FETCH" "knowledge-fetch: no Skill('cogni-knowledge:source-fetcher) — agents go through Task"
assert_grep 'Task' "$FETCH" "knowledge-fetch: Task listed in allowed-tools"

# --- source-curator agent ------------------------------------------------
CURATOR="$PLUGIN_ROOT/agents/source-curator.md"
if [ ! -f "$CURATOR" ]; then
  red "FAIL: agents/source-curator.md not found"
  exit 1
fi
assert_grep 'name: source-curator' "$CURATOR" "source-curator: frontmatter name"
assert_grep 'Forked from cogni-research/agents/source-curator.md at SHA' "$CURATOR" "source-curator: declares fork SHA in header"
# Market config must route through the canonical workspace helper, NOT a
# direct read of cogni-research/references/market-sources.json (preserves
# the clean-break commitment past M11+ when cogni-research is archived).
assert_grep 'get-market-config.py' "$CURATOR" "source-curator: routes market config through cogni-workspace helper"
assert_not_grep 'cogni-research/references/market-sources.json' "$CURATOR" "source-curator: no direct read of cogni-research/references/market-sources.json"
assert_grep 'candidates.json' "$CURATOR" "source-curator: emits to candidates.json contract"
assert_grep 'sub_question_refs' "$CURATOR" "source-curator: emits sub_question_refs[]"
assert_grep 'Do not emit' "$CURATOR" "source-curator: documents the drop-emission discipline"
assert_grep 'WebSearch' "$CURATOR" "source-curator: uses WebSearch"
# Negative assertion targets the frontmatter tools: line only — the body
# legitimately mentions WebFetch to document the boundary.
CURATOR_TOOLS_LINE=$(grep '^tools:' "$CURATOR" || true)
if ! echo "$CURATOR_TOOLS_LINE" | grep -q WebFetch; then
  green "PASS: source-curator: frontmatter tools: does NOT include WebFetch (Phase 3's job)"
else
  red "FAIL: source-curator: frontmatter tools: must not include WebFetch"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- source-fetcher agent ------------------------------------------------
FETCHER="$PLUGIN_ROOT/agents/source-fetcher.md"
if [ ! -f "$FETCHER" ]; then
  red "FAIL: agents/source-fetcher.md not found"
  exit 1
fi
assert_grep 'name: source-fetcher' "$FETCHER" "source-fetcher: frontmatter name"
assert_grep 'fetch-cache.py store' "$FETCHER" "source-fetcher: calls fetch-cache.py store"
assert_grep 'fetch-cache.py fetch' "$FETCHER" "source-fetcher: calls fetch-cache.py fetch (cache lookup)"
assert_grep 'webfetch' "$FETCHER" "source-fetcher: uses webfetch enum (matches cogni-claims)"
assert_grep 'cobrowse_interactive' "$FETCHER" "source-fetcher: uses cobrowse_interactive enum (matches cogni-claims)"
assert_grep 'fallback_attempted' "$FETCHER" "source-fetcher: emits fallback_attempted in unavailable[]"
assert_grep 'WebFetch' "$FETCHER" "source-fetcher: uses WebFetch tool"
# Frontmatter-tools-only check (body mentions WebSearch to document the boundary).
FETCHER_TOOLS_LINE=$(grep '^tools:' "$FETCHER" || true)
if ! echo "$FETCHER_TOOLS_LINE" | grep -q WebSearch; then
  green "PASS: source-fetcher: frontmatter tools: does NOT include WebSearch (curator's job)"
else
  red "FAIL: source-fetcher: frontmatter tools: must not include WebSearch"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
fi
# MCP cobrowse tools must be enumerated so the fallback path actually works
# (plugin agents do not auto-inherit MCP tools when a tools: array is set —
# confirmed against cogni-claims/agents/source-inspector which uses the same
# mcp__claude-in-chrome__* names).
if echo "$FETCHER_TOOLS_LINE" | grep -q 'mcp__claude-in-chrome__'; then
  green "PASS: source-fetcher: frontmatter tools: enumerates claude-in-chrome MCP tools for cobrowse fallback"
else
  red "FAIL: source-fetcher: cobrowse fallback unreachable without MCP tools in tools: array"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- Clean-break invariant ------------------------------------------------
# v0.1.0 forbids dispatching cogni-research or cogni-claims skills/agents
# from the new runtime path. v0.0.20 (M6 knowledge-ingest) extends the rule
# to cogni-wiki: the ingest skill calls wiki-ingest's helper scripts
# directly at script level (backlink_audit.py, wiki_index_update.py) rather
# than dispatching the upstream skill. Static references to documentation
# files (e.g., cogni-research/references/market-sources.json) are permitted;
# skill DISPATCH is not.
#
# The cogni-wiki check is scoped to the v0.0.20 ingest surface only (the
# three new files plus the orchestrator skill). knowledge-plan / knowledge-
# curate / knowledge-fetch legitimately do not dispatch cogni-wiki either,
# but they predate the explicit rule; the original loop already proves the
# weaker cogni-research/cogni-claims invariant for them.
INGEST="$PLUGIN_ROOT/skills/knowledge-ingest/SKILL.md"
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
CLAIM_EXTRACTOR="$PLUGIN_ROOT/agents/claim-extractor.md"
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
VERIFY="$PLUGIN_ROOT/skills/knowledge-verify/SKILL.md"
VERIFIER="$PLUGIN_ROOT/agents/wiki-verifier.md"
REVISOR="$PLUGIN_ROOT/agents/revisor.md"

for f in "$PLAN" "$CURATE" "$FETCH" "$CURATOR" "$FETCHER" "$INGEST" "$INGESTER" "$CLAIM_EXTRACTOR" "$COMPOSE" "$COMPOSER" "$VERIFY" "$VERIFIER" "$REVISOR"; do
  [ -f "$f" ] || continue
  if grep -qE 'Skill\("?cogni-(research|claims):' "$f" 2>/dev/null; then
    red "FAIL: clean-break: $f dispatches a cogni-research/cogni-claims skill"
    grep -nE 'Skill\("?cogni-(research|claims):' "$f"
    errors=$((errors + 1))
  fi
done

# cogni-wiki extension — applies to the v0.0.20 ingest surface, the
# v0.0.22 compose surface, and the v0.0.23 verify surface. All call
# cogni-wiki helpers at script level only (knowledge-ingest hits
# backlink_audit.py + wiki_index_update.py; knowledge-compose only reads
# the wiki — no script calls — and the composer is fully read-only
# against wiki/*; knowledge-verify only reads the wiki — no script calls
# — and the verifier + revisor are read-only against wiki/* too).
for f in "$INGEST" "$INGESTER" "$CLAIM_EXTRACTOR" "$COMPOSE" "$COMPOSER" "$VERIFY" "$VERIFIER" "$REVISOR"; do
  [ -f "$f" ] || continue
  if grep -qE 'Skill\("?cogni-wiki:' "$f" 2>/dev/null; then
    red "FAIL: clean-break: $f dispatches a cogni-wiki skill (M6 contract: call helper scripts directly)"
    grep -nE 'Skill\("?cogni-wiki:' "$f"
    errors=$((errors + 1))
  fi
done

if [ $errors -eq 0 ]; then
  green "PASS: clean-break — no cogni-research/cogni-claims/cogni-wiki skill dispatch in new files"
fi

if [ $errors -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
