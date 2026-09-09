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
#   - knowledge-plan: writes plan.json schema 0.1.0, carries no cogni-wiki
#     install probe, does not append binding.
#   - knowledge-curate: reads plan.json, dispatches source-curator (forwarding
#     KNOWLEDGE_ROOT/MAX_AGE_DAYS for the Phase-4 fetch, Option B #292), merges
#     through candidate-store.py append-batch, reads curator_defaults from
#     binding.
#   - knowledge-fetch: builds fetch-manifest.json from the curators' fetch
#     results, cobrowse recovery opt-in (--cobrowse + claude-in-chrome probe),
#     reads fetch_cache_max_age_days from binding, calls fetch-cache.py stat.
#   - source-curator agent: forked header, candidates.json output, drops
#     dimensions/annotation emission, WebFetch in tools: + Phase-4 fetch
#     (Option B #292), no claude-in-chrome tools.
#   - source-fetcher agent: cobrowse-only (no WebFetch/WebSearch in tools:),
#     cobrowse_interactive enum, fetch-cache.py store/fetch contract.
#   - Clean-break invariant: no `cogni-research:` or `cogni-workspace:claim*` skill
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
  red "FAIL: skill-contracts-00-knowledge-plan-skill-md knowledge-plan/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-plan' "$PLAN" "skill-contracts-01-knowledge-plan-frontmatter-name knowledge-plan: frontmatter name"
assert_grep '"schema_version": "0.1.1"' "$PLAN" "skill-contracts-02-plan-json-schema-0-1-1 knowledge-plan: plan.json schema 0.1.1 in spec (#309 P2 — writer-quality fields)"
assert_grep '3-7 sub-questions' "$PLAN" "skill-contracts-03-3-7-sub-question knowledge-plan: 3-7 sub-question contract"
# #309 P2: the four writer-quality fields are written into plan.json (schema 0.1.1),
# resolved in Step 0.5 (flag > binding > framing > default), and an optional Step 0.4
# topic-framing pass can precede resolution.
assert_grep '"prose_density"' "$PLAN" "skill-contracts-04-writes-prose-density-plan knowledge-plan: writes prose_density into plan.json (#309 P2)"
assert_grep '"tone"' "$PLAN" "skill-contracts-05-writes-tone-plan-json knowledge-plan: writes tone into plan.json (#309 P2)"
assert_grep '"citation_format"' "$PLAN" "skill-contracts-06-writes-citation-format-plan knowledge-plan: writes citation_format into plan.json (#309 P2)"
assert_grep '"target_words"' "$PLAN" "skill-contracts-07-writes-target-words-plan knowledge-plan: writes target_words into plan.json (#309 P2)"
assert_grep '0.4. Topic framing' "$PLAN" "skill-contracts-08-optional-step-0-4-topic knowledge-plan: has the optional Step 0.4 topic-framing pass (#309 P2.5)"
assert_grep 'no-framing' "$PLAN" "skill-contracts-09-documents-no-framing-skip knowledge-plan: documents --no-framing skip for Step 0.4 (#309 P2.5)"
# #382: the opt-in, fail-soft preliminary scoping scan folded into Step 0.4 framing —
# knowledge-plan gains WebSearch and a --no-prelim-search opt-out.
assert_grep 'allowed-tools:.*WebSearch' "$PLAN" "skill-contracts-10-allowed-tools-includes-websearch knowledge-plan: allowed-tools includes WebSearch for the preliminary scan (#382)"
assert_grep 'no-prelim-search' "$PLAN" "skill-contracts-11-documents-no-prelim-search knowledge-plan: documents --no-prelim-search opt-out (#382)"
assert_grep 'reliminary scoping scan' "$PLAN" "skill-contracts-12-documents-preliminary-scoping-scan knowledge-plan: documents the preliminary scoping scan inside Step 0.4 (#382)"
# Durable backstop for the no-issue-refs-in-skills convention: SKILL.md prose
# states rationale semantically, never via #NNN breadcrumbs (issue refs live in
# references/ + the PR/commit). Guards against maintenance provenance leaking
# into the executed prompt.
assert_not_grep '#[0-9]' "$PLAN" "skill-contracts-13-no-nnn-issue-ref knowledge-plan: no #NNN issue-ref breadcrumbs in the executed prompt"
assert_not_grep 'probe_plugin' "$PLAN" "skill-contracts-14-knowledge-plan-no-install-probe knowledge-plan: carries no cogni-wiki install probe (the wiki engine is vendored; this phase resolves none)"
assert_grep 'knowledge-finalize' "$PLAN" "skill-contracts-15-defers-binding-append-m9 knowledge-plan: defers binding append to M9 knowledge-finalize"
assert_not_grep 'probe_plugin cogni-research' "$PLAN" "skill-contracts-16-knowledge-plan-does-not knowledge-plan: does NOT probe cogni-research (clean break)"
# Slice 16 (#307): each sub-question carries a theme_label (the thematic index
# category Phase 4 files sources under).
assert_grep 'theme_label' "$PLAN" "skill-contracts-17-emits-theme-label-sub knowledge-plan: emits theme_label per sub-question (#307)"

# --- knowledge-curate SKILL.md -------------------------------------------
CURATE="$PLUGIN_ROOT/skills/knowledge-curate/SKILL.md"
if [ ! -f "$CURATE" ]; then
  red "FAIL: skill-contracts-18-knowledge-curate-skill-md knowledge-curate/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-curate' "$CURATE" "skill-contracts-19-knowledge-curate-frontmatter-name knowledge-curate: frontmatter name"
assert_grep 'candidate-store.py init' "$CURATE" "skill-contracts-20-knowledge-curate-calls-candidate-store-py-init knowledge-curate: calls candidate-store.py init"
assert_grep 'candidate-store.py append-batch' "$CURATE" "skill-contracts-21-knowledge-curate-calls-candidate-store-py-append-batch knowledge-curate: calls candidate-store.py append-batch"
assert_grep 'curator_defaults' "$CURATE" "skill-contracts-22-reads-curator-defaults-binding knowledge-curate: reads curator_defaults from binding"
assert_grep 'max_candidates_per_sq' "$CURATE" "skill-contracts-23-reads-max-candidates-sq knowledge-curate: reads max_candidates_per_sq"
assert_grep 'score_threshold' "$CURATE" "skill-contracts-24-reads-score-threshold knowledge-curate: reads score_threshold"
assert_grep 'Task(source-curator' "$CURATE" "skill-contracts-25-dispatches-source-curator-task knowledge-curate: dispatches source-curator via Task (matches cogni-research convention)"
# Belt-and-braces: confirm the obsolete Skill(\"cogni-knowledge:source-curator\")
# dispatch is not lingering. Agents live at agents/, not skills/.
assert_not_grep 'Skill("cogni-knowledge:source-curator' "$CURATE" "skill-contracts-26-knowledge-curate-no-skill knowledge-curate: no Skill('cogni-knowledge:source-curator) — agents go through Task"
assert_grep 'Task' "$CURATE" "skill-contracts-27-knowledge-curate-task-listed knowledge-curate: Task listed in allowed-tools"
# Option B (#292, v0.0.29): the curator fetches bodies in Phase 4, so the
# skill must forward the fetch params to each source-curator dispatch.
assert_grep 'KNOWLEDGE_ROOT=' "$CURATE" "skill-contracts-28-forwards-knowledge-root-source knowledge-curate: forwards KNOWLEDGE_ROOT to source-curator (Phase-4 fetch)"
assert_grep 'MAX_AGE_DAYS=' "$CURATE" "skill-contracts-29-forwards-max-age-days knowledge-curate: forwards MAX_AGE_DAYS to source-curator (Phase-4 fetch)"
# #304 (Slice 14): the orchestrator resolves the market config ONCE via
# get-market-config.py, validates it (aborts loudly on the _default fallback),
# writes it to .metadata/market-config.json, and threads MARKET_CONFIG_PATH to
# every curator — instead of N fragile per-agent WORKSPACE_PLUGIN_ROOT globs.
assert_grep 'get-market-config.py' "$CURATE" "skill-contracts-30-resolves-market-config-get knowledge-curate: resolves market config via get-market-config.py once (#304)"
assert_grep 'market-config.json' "$CURATE" "skill-contracts-31-writes-resolved-config-metadata knowledge-curate: writes the resolved config to .metadata/market-config.json (#304)"
assert_grep 'MARKET_CONFIG_PATH=' "$CURATE" "skill-contracts-32-forwards-market-config-path knowledge-curate: forwards MARKET_CONFIG_PATH to source-curator (#304)"
# The fail-loudly gate is the subtlest, most regression-prone line in the slice:
# get-market-config.py returns success:true with the _default config (no
# data.code) for an unknown market, so the abort MUST key on data.code, not on
# success alone. Guard both the mechanism (data.code) and the abort instruction
# ('abort unless') so a future edit can't silently drop the gate and reintroduce
# the _default degrade (#304).
assert_grep 'data.code' "$CURATE" "skill-contracts-33-gate-keys-data-code knowledge-curate: gate keys on data.code, not bare success (#304)"
assert_grep 'Abort unless' "$CURATE" "skill-contracts-34-aborts-unless-data-code knowledge-curate: aborts unless data.code == requested market — guards the _default fail-loudly gate (#304)"
# #299 (Slice 15): all N sub-questions fan out in ONE wave (one assistant message
# of N Task calls), not the old "3 or fewer per wave" cadence. The plan cap (3-7)
# bounds N, so one wave always covers the plan.
assert_grep 'one assistant message containing all N' "$CURATE" "skill-contracts-35-fans-all-n-curators knowledge-curate: fans all N curators in one assistant message (#299)"
assert_not_grep '3 or fewer' "$CURATE" "skill-contracts-36-dropped-old-3-wave knowledge-curate: dropped the old <=3-per-wave concurrency cadence (#299)"
# P1.3 (#309): read-before-web. Step 0.5 resolves wiki coverage ONCE via
# wiki-coverage.py (mirroring the #304 resolve-once posture), writes it to
# .metadata/wiki-coverage.json, and threads WIKI_ROOT + WIKI_COVERAGE_PATH to
# every curator. The pre-check is fail-soft — a scorer error degrades to an
# all-uncovered manifest and curation proceeds (the opposite of the #304
# market-config hard-abort), which is what preserves the run-1 no-regression.
assert_grep 'wiki-coverage.py' "$CURATE" "skill-contracts-37-resolves-wiki-coverage-py knowledge-curate: resolves wiki coverage via wiki-coverage.py once in Step 0.5 (#309)"
assert_grep 'wiki-coverage.json' "$CURATE" "skill-contracts-38-writes-coverage-manifest-metadata knowledge-curate: writes the coverage manifest to .metadata/wiki-coverage.json (#309)"
assert_grep 'WIKI_COVERAGE_PATH=' "$CURATE" "skill-contracts-39-forwards-wiki-coverage-path knowledge-curate: forwards WIKI_COVERAGE_PATH to source-curator (#309)"
assert_grep 'WIKI_ROOT=' "$CURATE" "skill-contracts-40-forwards-wiki-root-source knowledge-curate: forwards WIKI_ROOT to source-curator (#309)"
assert_grep 'fail-soft' "$CURATE" "skill-contracts-41-coverage-pre-check-fail knowledge-curate: coverage pre-check is fail-soft, not a hard abort (#309)"
# Sibling parity: curate threads WIKI_ROOT but did not confirm the bound wiki exists (#1707).
assert_grep_f 'Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists.' "$CURATE" "skill-contracts-113-curate-preflight-confirms-wiki-exists knowledge-curate: pre-flight confirms the bound wiki exists before Step 0.5 (#1707)"

# --- knowledge-fetch SKILL.md --------------------------------------------
FETCH="$PLUGIN_ROOT/skills/knowledge-fetch/SKILL.md"
if [ ! -f "$FETCH" ]; then
  red "FAIL: skill-contracts-42-knowledge-fetch-skill-md knowledge-fetch/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-fetch' "$FETCH" "skill-contracts-43-knowledge-fetch-frontmatter-name knowledge-fetch: frontmatter name"
assert_grep 'fetch_cache_max_age_days' "$FETCH" "skill-contracts-44-reads-fetch-cache-max knowledge-fetch: reads fetch_cache_max_age_days"
assert_grep 'fetch-cache.py stat' "$FETCH" "skill-contracts-45-knowledge-fetch-calls-cache knowledge-fetch: calls fetch-cache.py stat in summary"
assert_grep 'Task(source-fetcher' "$FETCH" "skill-contracts-46-dispatches-source-fetcher-task knowledge-fetch: dispatches source-fetcher via Task (cobrowse-only)"
assert_grep 'fetch-manifest.json' "$FETCH" "skill-contracts-47-writes-fetch-manifest-json knowledge-fetch: writes fetch-manifest.json"
assert_not_grep 'Skill("cogni-knowledge:source-fetcher' "$FETCH" "skill-contracts-48-knowledge-fetch-no-skill knowledge-fetch: no Skill('cogni-knowledge:source-fetcher) — agents go through Task"
assert_grep 'Task' "$FETCH" "skill-contracts-49-knowledge-fetch-task-listed knowledge-fetch: Task listed in allowed-tools"
# Option B (#292, v0.0.29): cobrowse recovery is opt-in, and setup mirrors
# the claims engine (probe the claude-in-chrome extension, not install-mcp).
assert_grep '--cobrowse' "$FETCH" "skill-contracts-50-cobrowse-recovery-opt knowledge-fetch: cobrowse recovery is opt-in via --cobrowse"
assert_grep 'mcp__claude-in-chrome__tabs_context_mcp' "$FETCH" "skill-contracts-51-probes-claude-chrome-extension knowledge-fetch: probes the claude-in-chrome extension before cobrowse"

# --- source-curator agent ------------------------------------------------
CURATOR="$PLUGIN_ROOT/agents/source-curator.md"
if [ ! -f "$CURATOR" ]; then
  red "FAIL: skill-contracts-52-agents-source-curator-md agents/source-curator.md not found"
  exit 1
fi
assert_grep 'name: source-curator' "$CURATOR" "skill-contracts-53-source-curator-frontmatter-name source-curator: frontmatter name"
assert_grep 'Forked from cogni-research/agents/source-curator.md at SHA' "$CURATOR" "skill-contracts-54-declares-fork-sha-header source-curator: declares fork SHA in header"
# Market config now comes from the orchestrator-resolved MARKET_CONFIG_PATH
# (#304, Slice 14). The agent must still reference get-market-config.py for
# provenance, must read MARKET_CONFIG_PATH, must treat a missing config as a
# HARD ERROR (not a silent _default drop), and must NOT re-resolve it via the
# old env-gated WORKSPACE_PLUGIN_ROOT cache glob. Still no direct read of
# cogni-research/references/market-sources.json (preserves the clean break).
assert_grep 'get-market-config.py' "$CURATOR" "skill-contracts-55-references-orchestrator-resolved-get source-curator: references the orchestrator-resolved get-market-config.py output"
assert_grep 'MARKET_CONFIG_PATH' "$CURATOR" "skill-contracts-56-reads-market-config-path source-curator: reads market config from MARKET_CONFIG_PATH (#304)"
assert_grep 'hard error' "$CURATOR" "skill-contracts-57-missing-market-config-path source-curator: missing MARKET_CONFIG_PATH is a hard error, not a silent _default (#304)"
assert_not_grep 'ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace' "$CURATOR" "skill-contracts-58-no-env-gated-cogni source-curator: no env-gated cogni-workspace glob — resolution moved to the orchestrator (#304)"
assert_not_grep 'cogni-research/references/market-sources.json' "$CURATOR" "skill-contracts-59-no-direct-read-cogni source-curator: no direct read of cogni-research/references/market-sources.json"
assert_grep 'candidates.json' "$CURATOR" "skill-contracts-60-emits-candidates-json-contract source-curator: emits to candidates.json contract"
assert_grep 'sub_question_refs' "$CURATOR" "skill-contracts-61-emits-sub-question-refs source-curator: emits sub_question_refs[]"
assert_grep 'Do not emit' "$CURATOR" "skill-contracts-62-documents-drop-emission-discipline source-curator: documents the drop-emission discipline"
assert_grep 'WebSearch' "$CURATOR" "skill-contracts-63-uses-websearch source-curator: uses WebSearch"
# Option B (#292, v0.0.29): the curator now WebFetches bodies in Phase 4, so
# WebFetch MUST be in its frontmatter tools: list. It must still NOT carry
# the claude-in-chrome cobrowse tools — cobrowse stays Phase 3 (opt-in).
CURATOR_TOOLS_LINE=$(grep '^tools:' "$CURATOR" || true)
if echo "$CURATOR_TOOLS_LINE" | grep -q WebFetch; then
  green "PASS: skill-contracts-64-frontmatter-tools-includes-webfetch source-curator: frontmatter tools: includes WebFetch (Phase-4 body fetch, Option B #292)"
else
  red "FAIL: skill-contracts-64-frontmatter-tools-includes-webfetch source-curator: frontmatter tools: must include WebFetch (Phase-4 fetch)"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
fi
if echo "$CURATOR_TOOLS_LINE" | grep -q 'mcp__claude-in-chrome__'; then
  red "FAIL: skill-contracts-65-frontmatter-tools-no-claude source-curator: frontmatter tools: must NOT include claude-in-chrome (cobrowse is Phase 3)"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: skill-contracts-65-frontmatter-tools-no-claude source-curator: frontmatter tools: no claude-in-chrome MCP tools (cobrowse stays Phase 3)"
fi
assert_grep 'KNOWLEDGE_ROOT' "$CURATOR" "skill-contracts-66-takes-knowledge-root-phase source-curator: takes KNOWLEDGE_ROOT for the Phase-4 fetch"
assert_grep 'fetch-cache.py' "$CURATOR" "skill-contracts-67-writes-bodies-through-fetch source-curator: writes bodies through fetch-cache.py (Phase 4)"
# P1.3 (#309): read-before-web narrowing. The curator reads its sub-question's
# verdict from WIKI_COVERAGE_PATH (Phase 0), branches on coverage_verdict
# (Phase 1), and reads covering pages under WIKI_ROOT before narrowing its
# query budget. Absent coverage data ⇒ full search (no regression).
assert_grep 'WIKI_COVERAGE_PATH' "$CURATOR" "skill-contracts-68-reads-wiki-coverage-path source-curator: reads wiki coverage from WIKI_COVERAGE_PATH (#309)"
assert_grep 'coverage_verdict' "$CURATOR" "skill-contracts-69-references-coverage-verdict source-curator: references coverage_verdict (#309)"
assert_grep 'WIKI_ROOT' "$CURATOR" "skill-contracts-70-takes-wiki-root-read source-curator: takes WIKI_ROOT to read covering pages (#309)"
# Guard the BEHAVIORAL change, not just the field name: `coverage_verdict` alone
# also matches the return-summary JSON EXAMPLE, so it would pass even if the
# Phase-1 branch were deleted. These two phrases live ONLY in the Phase-1
# narrowing prose, so they fail if the actual branch logic is removed (#309).
assert_grep 'Branch on the' "$CURATOR" "skill-contracts-71-phase-1-branches-verdict source-curator: Phase 1 branches on the verdict (behavioral, not just the schema example) (#309)"
assert_grep 'fewer queries' "$CURATOR" "skill-contracts-72-covered-partial-narrows-fewer source-curator: covered/partial narrows to fewer queries (#309)"

# --- source-fetcher agent ------------------------------------------------
FETCHER="$PLUGIN_ROOT/agents/source-fetcher.md"
if [ ! -f "$FETCHER" ]; then
  red "FAIL: skill-contracts-73-agents-source-fetcher-md agents/source-fetcher.md not found"
  exit 1
fi
assert_grep 'name: source-fetcher' "$FETCHER" "skill-contracts-74-source-fetcher-frontmatter-name source-fetcher: frontmatter name"
assert_grep 'fetch-cache.py store' "$FETCHER" "skill-contracts-75-source-fetcher-calls-fetch-cache-py-store source-fetcher: calls fetch-cache.py store"
assert_grep 'fetch-cache.py fetch' "$FETCHER" "skill-contracts-76-source-fetcher-calls-fetch-cache-py-positive-only source-fetcher: calls fetch-cache.py fetch (positive-only cache lookup)"
assert_grep 'cobrowse_interactive' "$FETCHER" "skill-contracts-77-uses-cobrowse-interactive-enum source-fetcher: uses cobrowse_interactive enum (matches the claims engine)"
assert_grep 'fallback_attempted' "$FETCHER" "skill-contracts-78-emits-fallback-attempted-unavailable source-fetcher: emits fallback_attempted in unavailable[]"
# Option B (#292, v0.0.29): source-fetcher shrank to cobrowse-only. WebFetch
# (and the PDF Read-loop) moved to source-curator, so the frontmatter tools:
# list must NOT include WebFetch or WebSearch (curator's job).
FETCHER_TOOLS_LINE=$(grep '^tools:' "$FETCHER" || true)
if echo "$FETCHER_TOOLS_LINE" | grep -q WebFetch; then
  red "FAIL: skill-contracts-79-source-fetcher-frontmatter-tools-does-not-include-webfetch source-fetcher: frontmatter tools: must NOT include WebFetch (moved to source-curator, Option B #292)"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: skill-contracts-79-source-fetcher-frontmatter-tools-does-not-include-webfetch source-fetcher: frontmatter tools: does NOT include WebFetch (cobrowse-only, Option B #292)"
fi
if ! echo "$FETCHER_TOOLS_LINE" | grep -q WebSearch; then
  green "PASS: skill-contracts-80-source-fetcher-frontmatter-tools-does-not-include-websearch source-fetcher: frontmatter tools: does NOT include WebSearch (curator's job)"
else
  red "FAIL: skill-contracts-80-source-fetcher-frontmatter-tools-does-not-include-websearch source-fetcher: frontmatter tools: must not include WebSearch"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
fi
# MCP cobrowse tools must be enumerated so the fallback path actually works
# (plugin agents do not auto-inherit MCP tools when a tools: array is set —
# confirmed against cogni-workspace/agents/source-inspector.md which uses the same
# mcp__claude-in-chrome__* names).
if echo "$FETCHER_TOOLS_LINE" | grep -q 'mcp__claude-in-chrome__'; then
  green "PASS: skill-contracts-81-frontmatter-tools-enumerates-claude source-fetcher: frontmatter tools: enumerates claude-in-chrome MCP tools for cobrowse fallback"
else
  red "FAIL: skill-contracts-81-frontmatter-tools-enumerates-claude source-fetcher: cobrowse fallback unreachable without MCP tools in tools: array"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- Clean-break invariant ------------------------------------------------
# v0.1.0 forbids dispatching cogni-research or cogni-workspace claim skills/agents
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
# weaker cogni-research/cogni-workspace-claims invariant for them.
INGEST="$PLUGIN_ROOT/skills/knowledge-ingest/SKILL.md"
SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
CLAIM_EXTRACTOR="$PLUGIN_ROOT/agents/claim-extractor.md"
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
VERIFY="$PLUGIN_ROOT/skills/knowledge-verify/SKILL.md"
VERIFIER="$PLUGIN_ROOT/agents/wiki-verifier.md"
REVISOR="$PLUGIN_ROOT/agents/revisor.md"
FINALIZE="$PLUGIN_ROOT/skills/knowledge-finalize/SKILL.md"
DISTILL="$PLUGIN_ROOT/skills/knowledge-distill/SKILL.md"
DISTILLER="$PLUGIN_ROOT/agents/concept-distiller.md"
REVIEWER="$PLUGIN_ROOT/agents/wiki-reviewer.md"

_cr_dispatch_hits=0
_cr_dispatch_detail=""
for _p in plan:"$PLAN" curate:"$CURATE" fetch:"$FETCH" curator:"$CURATOR" fetcher:"$FETCHER" ingest:"$INGEST" ingester:"$INGESTER" claim-extractor:"$CLAIM_EXTRACTOR" compose:"$COMPOSE" composer:"$COMPOSER" verify:"$VERIFY" verifier:"$VERIFIER" revisor:"$REVISOR" finalize:"$FINALIZE" distill:"$DISTILL" distiller:"$DISTILLER" reviewer:"$REVIEWER"; do
  _cid="${_p%%:*}"; f="${_p#*:}"
  [ -f "$f" ] || continue
  if grep -qE 'Skill\("?(cogni-research:|cogni-workspace:claim)' "$f" 2>/dev/null; then
    _cr_dispatch_detail="$_cr_dispatch_detail
${_cid} ($f):
$(grep -nE 'Skill\("?(cogni-research:|cogni-workspace:claim)' "$f")"
    errors=$((errors + 1)); _cr_dispatch_hits=$((_cr_dispatch_hits + 1))
  fi
done

if [ "$_cr_dispatch_hits" -eq 0 ]; then
  green "PASS: skill-contracts-82-dispatches-cogni-research-workspace clean-break: no scanned file dispatches a cogni-research/cogni-workspace-claims skill"
else
  red "FAIL: skill-contracts-82-dispatches-cogni-research-workspace clean-break: $_cr_dispatch_hits scanned file(s) dispatch a cogni-research/cogni-workspace-claims skill:"
  printf '%s\n' "$_cr_dispatch_detail" | sed '/^$/d' | sed 's/^/    /'
fi

# cogni-wiki extension — applies to the v0.0.20 ingest surface, the
# v0.0.22 compose surface, the v0.0.23 verify surface, and the v0.1.13
# distill surface (#336). All call cogni-wiki helpers at script level only
# (knowledge-ingest hits backlink_audit.py + wiki_index_update.py;
# knowledge-distill hits the same trio + concept-store.py which IMPORTS
# _wikilib._wiki_lock — an import, not a skill dispatch; knowledge-compose
# only reads the wiki; the composer/verifier/revisor are read-only against
# wiki/*; the concept-distiller is read+write-records only, no skill dispatch).
_wiki_dispatch_hits=0
_wiki_dispatch_detail=""
for _p in ingest:"$INGEST" ingester:"$INGESTER" claim-extractor:"$CLAIM_EXTRACTOR" compose:"$COMPOSE" composer:"$COMPOSER" verify:"$VERIFY" verifier:"$VERIFIER" revisor:"$REVISOR" finalize:"$FINALIZE" distill:"$DISTILL" distiller:"$DISTILLER" reviewer:"$REVIEWER" setup:"$SETUP"; do
  _cid="${_p%%:*}"; f="${_p#*:}"
  [ -f "$f" ] || continue
  if grep -qE 'Skill\("?cogni-wiki:' "$f" 2>/dev/null; then
    _wiki_dispatch_detail="$_wiki_dispatch_detail
${_cid} ($f):
$(grep -nE 'Skill\("?cogni-wiki:' "$f")"
    errors=$((errors + 1)); _wiki_dispatch_hits=$((_wiki_dispatch_hits + 1))
  fi
done

if [ "$_wiki_dispatch_hits" -eq 0 ]; then
  green "PASS: skill-contracts-83-dispatches-cogni-wiki-skill clean-break: no scanned file dispatches a cogni-wiki skill (M6 contract: call helper scripts directly)"
else
  red "FAIL: skill-contracts-83-dispatches-cogni-wiki-skill clean-break: $_wiki_dispatch_hits scanned file(s) dispatch a cogni-wiki skill (M6 contract: call helper scripts directly):"
  printf '%s\n' "$_wiki_dispatch_detail" | sed '/^$/d' | sed 's/^/    /'
fi

# skill-contracts-84 gates on this case's own predicate — the two dispatch
# counters above — not on the suite-wide $errors counter it used to read.
# That counter is incremented by several unrelated earlier checks, so any one of
# them silenced this case and --case skill-contracts-84-clean-break-no-cogni
# reported case_not_found instead of a verdict. The FAIL arm deliberately does
# NOT increment errors: the loops above already counted each offending file.
_clean_break_hits=$((_cr_dispatch_hits + _wiki_dispatch_hits))
if [ "$_clean_break_hits" -eq 0 ]; then
  green "PASS: skill-contracts-84-clean-break-no-cogni clean-break — no cogni-research/cogni-workspace-claims/cogni-wiki skill dispatch in new files"
else
  red "FAIL: skill-contracts-84-clean-break-no-cogni clean-break — $_clean_break_hits file(s) dispatch a cogni-research/cogni-workspace-claims/cogni-wiki skill (see the skill-contracts-82/83 lines above)"
fi

# --- wiki-verifier agent honesty bullets ---------------------------------
# Two prose bullets close the loop between the agent's internal honesty and
# the operator-facing surfaces. No behaviour-level change — the regression
# guard below proves the load-bearing zero-network invariant survived the edit.
assert_grep 'verbatim/paraphrase' "$VERIFIER" "skill-contracts-85-surfaces-verbatim-paraphrase-ratio wiki-verifier: surfaces the verbatim/paraphrase ratio as the operator confidence signal"
assert_grep 'knowledge-refresh --resweep' "$VERIFIER" "skill-contracts-86-names-knowledge-refresh-resweep wiki-verifier: names knowledge-refresh --resweep as the live-source path"
# Regression guard: the strengthened 'does NOT' bullet must NOT drop the
# original load-bearing zero-network assertion.
assert_grep 'Does NOT WebFetch or WebSearch' "$VERIFIER" "skill-contracts-87-retains-does-not-webfetch wiki-verifier: retains the 'Does NOT WebFetch or WebSearch' invariant (#337 must not erode it)"

# --- Read-side skills: engine probe posture ------------------------------
# query / dashboard / resume must probe neither cogni-research (v0.1.0 clean
# break) nor an external cogni-wiki (retired — the engine is vendored in-tree,
# and a stale external copy is never preferable to failing loudly). Each must
# gate on the VENDORED engine and wire the pipeline-summary.py reader.
QUERY="$PLUGIN_ROOT/skills/knowledge-query/SKILL.md"
DASHBOARD="$PLUGIN_ROOT/skills/knowledge-dashboard/SKILL.md"
RESUME="$PLUGIN_ROOT/skills/knowledge-resume/SKILL.md"

for f in "$QUERY" "$DASHBOARD" "$RESUME"; do
  name=$(basename "$(dirname "$f")")
  if [ ! -f "$f" ]; then
    red "FAIL: skill-contracts-88-skill-md-not-found-${name} $name/SKILL.md not found"
    errors=$((errors + 1))
    continue
  else
    green "PASS: skill-contracts-88-skill-md-not-found-${name} $name/SKILL.md present"
  fi
  assert_not_grep 'probe_plugin cogni-research' "$f" "skill-contracts-89-does-not-probe-cogni-${name} $name: does NOT probe cogni-research (clean break)"
  assert_grep 'scripts/vendor/cogni-wiki/skills' "$f" "skill-contracts-90-probes-vendored-engine-${name} $name: gates on the vendored wiki engine"
  assert_not_grep 'probe_plugin cogni-wiki' "$f" "skill-contracts-90b-no-external-cogni-wiki-probe-${name} $name: carries no external cogni-wiki fallback probe (vendored-only)"
  assert_grep 'pipeline-summary.py' "$f" "skill-contracts-91-wired-pipeline-summary-py-${name} $name: wired to pipeline-summary.py reader"
done

# knowledge-query is the shallow rung: it reads + synthesizes natively on the
# vendored wiki-grounding primitive and no longer dispatches cogni-wiki:wiki-query.
# (It keeps the vendored engine gate above and the pipeline-summary.py footer;
# there is no external cogni-wiki fallback.)
assert_not_grep 'Skill("cogni-wiki:wiki-query' "$QUERY" "skill-contracts-92-knowledge-query-no-longer knowledge-query: no longer dispatches cogni-wiki:wiki-query (native shallow rung on the vendored engine)"
assert_grep 'wiki-grounding.py' "$QUERY" "skill-contracts-93-consumes-shared-wiki-grounding knowledge-query: consumes the shared wiki-grounding primitive directly"

# knowledge-query opt-in --file-back deposit (shallow-rung synthesis parity):
# read-only is the DEFAULT (flag absent), but when the skill documents the
# --file-back deposit path it MUST reuse the vendored write lockstep
# (wiki_index_update.py + config_bump.py), label the deposit honestly as
# un-verified, and carry Write in allowed-tools. Conditional so a future
# read-only-only variant of the skill is not falsely failed.
if grep -q -- '--file-back' "$QUERY"; then
  assert_grep 'wiki_index_update.py' "$QUERY" "skill-contracts-94-knowledge-query-file-back-deposit-reuses-vendored-wiki knowledge-query: --file-back deposit reuses the vendored wiki_index_update.py (no new write path)"
  assert_grep 'config_bump.py' "$QUERY" "skill-contracts-95-knowledge-query-file-back-deposit-reuses-vendored-config knowledge-query: --file-back deposit reuses the vendored config_bump.py entries_count bump"
  assert_grep 'unverified_shallow_rung' "$QUERY" "skill-contracts-96-file-back-deposit-honestly knowledge-query: --file-back deposit honestly labels the page verification: unverified_shallow_rung"
  assert_grep 'allowed-tools:.*Write' "$QUERY" "skill-contracts-97-allowed-tools-includes-write knowledge-query: allowed-tools includes Write for the --file-back deposit path"
fi

# knowledge-dashboard renders natively on the vendored render_dashboard.py /
# build_graph.py and no longer dispatches cogni-wiki:wiki-dashboard after the
# user-facing skill re-home. It keeps the vendored engine gate above and the
# pipeline-summary.py overlay reads; there is no external cogni-wiki fallback.
assert_not_grep 'Skill("cogni-wiki:wiki-dashboard' "$DASHBOARD" "skill-contracts-98-knowledge-dashboard-no-longer knowledge-dashboard: no longer dispatches cogni-wiki:wiki-dashboard (native render on the vendored engine)"
assert_grep 'render_dashboard.py' "$DASHBOARD" "skill-contracts-99-invokes-vendored-render-dashboard knowledge-dashboard: invokes the vendored render_dashboard.py directly"

# knowledge-resume computes the wiki health verdict natively on the vendored
# health.py and no longer dispatches cogni-wiki:wiki-resume after the
# user-facing skill re-home. It keeps the vendored engine gate above and the
# pipeline-summary.py reads; there is no external cogni-wiki fallback.
assert_not_grep 'Skill("cogni-wiki:wiki-resume' "$RESUME" "skill-contracts-100-knowledge-resume-no-longer knowledge-resume: no longer dispatches cogni-wiki:wiki-resume (native health verdict on the vendored engine)"
assert_grep 'health.py' "$RESUME" "skill-contracts-101-invokes-vendored-health-py knowledge-resume: invokes the vendored health.py directly"

# knowledge-refresh shares the probe-drop invariant (M10b, v0.0.26) but does
# not read pipeline-summary.py — it dispatches the seven phase skills. Its
# phase-chain + clean-break contract lives in test_refresh_push_chain.sh; here
# we pin the read-side: push-mode no longer probes the cogni-wiki PLUGIN —
# its staleness lint was re-homed onto the vendored lint_wiki.py (resolved
# vendored-first via resolve_wiki_scripts), so a Karpathy base needs no
# cogni-wiki install for push-mode and the archival parity grep-guard greens.
REFRESH="$PLUGIN_ROOT/skills/knowledge-refresh/SKILL.md"
if [ -f "$REFRESH" ]; then
  green "PASS: skill-contracts-105-knowledge-refresh-skill-md knowledge-refresh/SKILL.md present"
  assert_not_grep 'probe_plugin cogni-research' "$REFRESH" "skill-contracts-102-knowledge-refresh-does-not knowledge-refresh: does NOT probe cogni-research (clean break)"
  assert_not_grep 'probe_plugin cogni-wiki' "$REFRESH" "skill-contracts-103-no-longer-probes-cogni knowledge-refresh: no longer probes the cogni-wiki plugin (push-mode re-homed onto the vendored lint_wiki.py)"
  assert_grep 'resolve_wiki_scripts wiki-lint lint_wiki.py' "$REFRESH" "skill-contracts-104-push-mode-resolves-vendored knowledge-refresh: push-mode resolves the vendored wiki-lint scripts"
else
  red "FAIL: skill-contracts-105-knowledge-refresh-skill-md knowledge-refresh/SKILL.md not found"
  errors=$((errors + 1))
fi

# --- M11 audit: legacy chain archived, unreachable in live code -----------
# After M11 (v0.0.27) the knowledge-research / knowledge-report skills + their
# two private helper scripts (scripts/lineage-stamp.py, scripts/read-project-
# config.py) live under _archive/. This canary fails any future PR that
# re-references the legacy chain — by skill slug OR by dead script path — from
# a live runtime surface. It scans the whole plugin EXCEPT: _archive/ (the
# retained chain), references/ (history), tests/ (this file + test_refresh_
# push_chain.sh name the slugs on purpose), and README/CLAUDE/CHANGELOG (which
# recount the history) — so hooks/, commands/, plugin.json, and any future
# runtime dir are covered automatically.
#
# Portability + precision:
#   - grep -E (ERE alternation) so the pattern works on BSD/macOS grep, not
#     only GNU (every other alternation in this file uses -E).
#   - the trailing (non-letter|EOL) guard avoids matching legitimate names
#     such as `knowledge-researcher` / `knowledge-reporting`.
#   - --include scopes to text files so a stray *.pyc under __pycache__ can't
#     produce a binary-match false positive.
AUDIT_HITS=$(grep -rnE \
  --include='*.md' --include='*.py' --include='*.sh' --include='*.json' \
  --exclude-dir=_archive --exclude-dir=references --exclude-dir=tests \
  --exclude=README.md --exclude=CLAUDE.md --exclude=CHANGELOG.md \
  'knowledge-(research|report)([^a-zA-Z]|$)|scripts/(lineage-stamp|read-project-config)\.py' \
  "$PLUGIN_ROOT" 2>/dev/null || true)
if [ -n "$AUDIT_HITS" ]; then
  red "FAIL: skill-contracts-106-m11-audit-no-legacy M11 audit — legacy knowledge-research/knowledge-report reference in live code:"
  echo "$AUDIT_HITS" | sed 's/^/    /'
  errors=$((errors + 1))
else
  green "PASS: skill-contracts-106-m11-audit-no-legacy M11 audit — no legacy chain reference in the live plugin surface"
fi

# --- cogni-wiki parity gate: ZERO cogni-wiki: skill dispatch anywhere ---------
# After knowledge-setup re-homed wiki-setup to a native scaffold, NO live skill
# or agent dispatches a cogni-wiki skill at runtime (the read/render/lint/resweep
# paths re-homed earlier). The Skill\( anchor matches only real dispatch calls,
# so prose error-hint mentions ("re-run cogni-wiki:wiki-lint manually") are ignored.
WIKI_DISPATCH_HITS=$(grep -rnE \
  --include='*.md' \
  --exclude-dir=_archive --exclude-dir=references --exclude-dir=tests \
  --exclude=README.md --exclude=CLAUDE.md --exclude=CHANGELOG.md \
  'Skill\("?cogni-wiki:' \
  "$PLUGIN_ROOT" 2>/dev/null || true)
if [ -n "$WIKI_DISPATCH_HITS" ]; then
  red "FAIL: skill-contracts-107-cogni-wiki-parity-gate cogni-wiki parity gate — a live skill/agent still dispatches a cogni-wiki skill:"
  echo "$WIKI_DISPATCH_HITS" | sed 's/^/    /'
  errors=$((errors + 1))
else
  green "PASS: skill-contracts-107-cogni-wiki-parity-gate cogni-wiki parity gate — zero cogni-wiki skill dispatch in the live plugin surface"
fi

# --- Slice 16 (#308/#307) audit: prefixed-link + audit-only can't creep back ---
# The orphan linchpin was the path-prefixed `[[sources/<slug>]]` reference
# backlink, built via a `link_dir` variable in knowledge-finalize. That variable
# is gone — bare `[[<slug>]]` is the only form. And knowledge-ingest no longer
# defers backlinks as "audit-only". These two negative greps fail any future PR
# that reintroduces either pattern. (Explanatory prose may still MENTION
# `[[sources/<slug>]]` when describing the fix, so we target the CODE construct
# `link_dir`, not the literal `[[sources/`.)
assert_not_grep 'link_dir' "$FINALIZE" "skill-contracts-108-no-link-dir-path knowledge-finalize: no link_dir path-prefix construction — reference backlinks stay bare [[<slug>]] (#308)"
assert_not_grep 'audit-only' "$INGEST" "skill-contracts-109-no-audit-only-backlink knowledge-ingest: no 'audit-only' backlink deferral — apply-plan writes backlinks (#308)"
assert_grep 'theme_label' "$INGEST" "skill-contracts-110-files-sources-sub-question knowledge-ingest: files sources under the sub-question theme_label category (#307)"

# --- Slice 17 (#350) Skill(...) dispatch convention named once + cross-referenced ---
# Convention surface — the dispatch contract lives in delegation-contract.md
# under §"How `Skill(...)` blocks are written", and every orchestrator skill
# cross-references it via that section title. Locks in #350's middle path:
# central statement + light cross-refs instead of per-site clarifiers.
DELEGATION_CONTRACT="$PLUGIN_ROOT/references/delegation-contract.md"
assert_grep 'How `Skill(...)` blocks are written' "$DELEGATION_CONTRACT" \
  "skill-contracts-111-delegation-contract-md-names delegation-contract.md names the Skill(...) dispatch convention (#350)"
# knowledge-query, knowledge-dashboard, and knowledge-resume are intentionally
# absent: they no longer dispatch a Skill() (query reads + synthesizes natively
# on the vendored wiki-grounding primitive — the shallow rung; dashboard renders
# natively on the vendored render_dashboard.py / build_graph.py; resume computes
# the health verdict natively on the vendored health.py; after the user-facing skill re-home,
# they carry no Skill(...)-convention cross-reference.
for orch in knowledge-setup knowledge-refresh; do
  ORCH_SKILL="$PLUGIN_ROOT/skills/${orch}/SKILL.md"
  assert_grep 'How `Skill(...)` blocks are written' "$ORCH_SKILL" \
    "skill-contracts-112-cross-references-skill-dispatch-${orch} ${orch}: cross-references the Skill-dispatch convention (#350)"
done

if [ $errors -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
