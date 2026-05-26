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
# Slice 16 (#307): each sub-question carries a theme_label (the thematic index
# category Phase 4 files sources under).
assert_grep 'theme_label' "$PLAN" "knowledge-plan: emits theme_label per sub-question (#307)"

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
# Option B (#292, v0.0.29): the curator fetches bodies in Phase 4, so the
# skill must forward the fetch params to each source-curator dispatch.
assert_grep 'KNOWLEDGE_ROOT=' "$CURATE" "knowledge-curate: forwards KNOWLEDGE_ROOT to source-curator (Phase-4 fetch)"
assert_grep 'MAX_AGE_DAYS=' "$CURATE" "knowledge-curate: forwards MAX_AGE_DAYS to source-curator (Phase-4 fetch)"
# #304 (Slice 14): the orchestrator resolves the market config ONCE via
# get-market-config.py, validates it (aborts loudly on the _default fallback),
# writes it to .metadata/market-config.json, and threads MARKET_CONFIG_PATH to
# every curator — instead of N fragile per-agent WORKSPACE_PLUGIN_ROOT globs.
assert_grep 'get-market-config.py' "$CURATE" "knowledge-curate: resolves market config via get-market-config.py once (#304)"
assert_grep 'market-config.json' "$CURATE" "knowledge-curate: writes the resolved config to .metadata/market-config.json (#304)"
assert_grep 'MARKET_CONFIG_PATH=' "$CURATE" "knowledge-curate: forwards MARKET_CONFIG_PATH to source-curator (#304)"
# The fail-loudly gate is the subtlest, most regression-prone line in the slice:
# get-market-config.py returns success:true with the _default config (no
# data.code) for an unknown market, so the abort MUST key on data.code, not on
# success alone. Guard both the mechanism (data.code) and the abort instruction
# ('abort unless') so a future edit can't silently drop the gate and reintroduce
# the _default degrade (#304).
assert_grep 'data.code' "$CURATE" "knowledge-curate: gate keys on data.code, not bare success (#304)"
assert_grep 'Abort unless' "$CURATE" "knowledge-curate: aborts unless data.code == requested market — guards the _default fail-loudly gate (#304)"
# #299 (Slice 15): all N sub-questions fan out in ONE wave (one assistant message
# of N Task calls), not the old "3 or fewer per wave" cadence. The plan cap (3-7)
# bounds N, so one wave always covers the plan.
assert_grep 'one assistant message containing all N' "$CURATE" "knowledge-curate: fans all N curators in one assistant message (#299)"
assert_not_grep '3 or fewer' "$CURATE" "knowledge-curate: dropped the old <=3-per-wave concurrency cadence (#299)"

# --- knowledge-fetch SKILL.md --------------------------------------------
FETCH="$PLUGIN_ROOT/skills/knowledge-fetch/SKILL.md"
if [ ! -f "$FETCH" ]; then
  red "FAIL: knowledge-fetch/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-fetch' "$FETCH" "knowledge-fetch: frontmatter name"
assert_grep 'fetch_cache_max_age_days' "$FETCH" "knowledge-fetch: reads fetch_cache_max_age_days"
assert_grep 'fetch-cache.py stat' "$FETCH" "knowledge-fetch: calls fetch-cache.py stat in summary"
assert_grep 'Task(source-fetcher' "$FETCH" "knowledge-fetch: dispatches source-fetcher via Task (cobrowse-only)"
assert_grep 'fetch-manifest.json' "$FETCH" "knowledge-fetch: writes fetch-manifest.json"
assert_not_grep 'Skill("cogni-knowledge:source-fetcher' "$FETCH" "knowledge-fetch: no Skill('cogni-knowledge:source-fetcher) — agents go through Task"
assert_grep 'Task' "$FETCH" "knowledge-fetch: Task listed in allowed-tools"
# Option B (#292, v0.0.29): cobrowse recovery is opt-in, and setup mirrors
# cogni-claims (probe the claude-in-chrome extension, not install-mcp).
assert_grep '--cobrowse' "$FETCH" "knowledge-fetch: cobrowse recovery is opt-in via --cobrowse"
assert_grep 'mcp__claude-in-chrome__tabs_context_mcp' "$FETCH" "knowledge-fetch: probes the claude-in-chrome extension before cobrowse"

# --- source-curator agent ------------------------------------------------
CURATOR="$PLUGIN_ROOT/agents/source-curator.md"
if [ ! -f "$CURATOR" ]; then
  red "FAIL: agents/source-curator.md not found"
  exit 1
fi
assert_grep 'name: source-curator' "$CURATOR" "source-curator: frontmatter name"
assert_grep 'Forked from cogni-research/agents/source-curator.md at SHA' "$CURATOR" "source-curator: declares fork SHA in header"
# Market config now comes from the orchestrator-resolved MARKET_CONFIG_PATH
# (#304, Slice 14). The agent must still reference get-market-config.py for
# provenance, must read MARKET_CONFIG_PATH, must treat a missing config as a
# HARD ERROR (not a silent _default drop), and must NOT re-resolve it via the
# old env-gated WORKSPACE_PLUGIN_ROOT cache glob. Still no direct read of
# cogni-research/references/market-sources.json (preserves the clean break).
assert_grep 'get-market-config.py' "$CURATOR" "source-curator: references the orchestrator-resolved get-market-config.py output"
assert_grep 'MARKET_CONFIG_PATH' "$CURATOR" "source-curator: reads market config from MARKET_CONFIG_PATH (#304)"
assert_grep 'hard error' "$CURATOR" "source-curator: missing MARKET_CONFIG_PATH is a hard error, not a silent _default (#304)"
assert_not_grep 'ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace' "$CURATOR" "source-curator: no env-gated cogni-workspace glob — resolution moved to the orchestrator (#304)"
assert_not_grep 'cogni-research/references/market-sources.json' "$CURATOR" "source-curator: no direct read of cogni-research/references/market-sources.json"
assert_grep 'candidates.json' "$CURATOR" "source-curator: emits to candidates.json contract"
assert_grep 'sub_question_refs' "$CURATOR" "source-curator: emits sub_question_refs[]"
assert_grep 'Do not emit' "$CURATOR" "source-curator: documents the drop-emission discipline"
assert_grep 'WebSearch' "$CURATOR" "source-curator: uses WebSearch"
# Option B (#292, v0.0.29): the curator now WebFetches bodies in Phase 4, so
# WebFetch MUST be in its frontmatter tools: list. It must still NOT carry
# the claude-in-chrome cobrowse tools — cobrowse stays Phase 3 (opt-in).
CURATOR_TOOLS_LINE=$(grep '^tools:' "$CURATOR" || true)
if echo "$CURATOR_TOOLS_LINE" | grep -q WebFetch; then
  green "PASS: source-curator: frontmatter tools: includes WebFetch (Phase-4 body fetch, Option B #292)"
else
  red "FAIL: source-curator: frontmatter tools: must include WebFetch (Phase-4 fetch)"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
fi
if echo "$CURATOR_TOOLS_LINE" | grep -q 'mcp__claude-in-chrome__'; then
  red "FAIL: source-curator: frontmatter tools: must NOT include claude-in-chrome (cobrowse is Phase 3)"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: source-curator: frontmatter tools: no claude-in-chrome MCP tools (cobrowse stays Phase 3)"
fi
assert_grep 'KNOWLEDGE_ROOT' "$CURATOR" "source-curator: takes KNOWLEDGE_ROOT for the Phase-4 fetch"
assert_grep 'fetch-cache.py' "$CURATOR" "source-curator: writes bodies through fetch-cache.py (Phase 4)"

# --- source-fetcher agent ------------------------------------------------
FETCHER="$PLUGIN_ROOT/agents/source-fetcher.md"
if [ ! -f "$FETCHER" ]; then
  red "FAIL: agents/source-fetcher.md not found"
  exit 1
fi
assert_grep 'name: source-fetcher' "$FETCHER" "source-fetcher: frontmatter name"
assert_grep 'fetch-cache.py store' "$FETCHER" "source-fetcher: calls fetch-cache.py store"
assert_grep 'fetch-cache.py fetch' "$FETCHER" "source-fetcher: calls fetch-cache.py fetch (positive-only cache lookup)"
assert_grep 'cobrowse_interactive' "$FETCHER" "source-fetcher: uses cobrowse_interactive enum (matches cogni-claims)"
assert_grep 'fallback_attempted' "$FETCHER" "source-fetcher: emits fallback_attempted in unavailable[]"
# Option B (#292, v0.0.29): source-fetcher shrank to cobrowse-only. WebFetch
# (and the PDF Read-loop) moved to source-curator, so the frontmatter tools:
# list must NOT include WebFetch or WebSearch (curator's job).
FETCHER_TOOLS_LINE=$(grep '^tools:' "$FETCHER" || true)
if echo "$FETCHER_TOOLS_LINE" | grep -q WebFetch; then
  red "FAIL: source-fetcher: frontmatter tools: must NOT include WebFetch (moved to source-curator, Option B #292)"
  red "  got: $FETCHER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: source-fetcher: frontmatter tools: does NOT include WebFetch (cobrowse-only, Option B #292)"
fi
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
FINALIZE="$PLUGIN_ROOT/skills/knowledge-finalize/SKILL.md"

for f in "$PLAN" "$CURATE" "$FETCH" "$CURATOR" "$FETCHER" "$INGEST" "$INGESTER" "$CLAIM_EXTRACTOR" "$COMPOSE" "$COMPOSER" "$VERIFY" "$VERIFIER" "$REVISOR" "$FINALIZE"; do
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
for f in "$INGEST" "$INGESTER" "$CLAIM_EXTRACTOR" "$COMPOSE" "$COMPOSER" "$VERIFY" "$VERIFIER" "$REVISOR" "$FINALIZE"; do
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

# --- Read-side skills: cogni-research probe drop (M10a, v0.0.25) ----------
# query / dashboard / resume dispatch ONLY cogni-wiki. The v0.1.0 clean break
# (decision-1) makes cogni-research 0% of the runtime path, so these skills
# must probe cogni-wiki only — otherwise an uninstalled cogni-research (after
# M11 archives the legacy skills) would brick read-only status surfaces. Each
# must also wire the new pipeline-summary.py reader.
QUERY="$PLUGIN_ROOT/skills/knowledge-query/SKILL.md"
DASHBOARD="$PLUGIN_ROOT/skills/knowledge-dashboard/SKILL.md"
RESUME="$PLUGIN_ROOT/skills/knowledge-resume/SKILL.md"

for f in "$QUERY" "$DASHBOARD" "$RESUME"; do
  name=$(basename "$(dirname "$f")")
  if [ ! -f "$f" ]; then
    red "FAIL: $name/SKILL.md not found"
    errors=$((errors + 1))
    continue
  fi
  assert_not_grep 'probe_plugin cogni-research' "$f" "$name: does NOT probe cogni-research (clean break)"
  assert_grep 'probe_plugin cogni-wiki' "$f" "$name: still probes cogni-wiki"
  assert_grep 'pipeline-summary.py' "$f" "$name: wired to pipeline-summary.py reader"
done

# knowledge-refresh shares the probe-drop invariant (M10b, v0.0.26) but does
# not read pipeline-summary.py — it dispatches the seven phase skills. Its
# phase-chain + clean-break contract lives in test_refresh_push_chain.sh; here
# we just pin the probe split alongside the read-side trio.
REFRESH="$PLUGIN_ROOT/skills/knowledge-refresh/SKILL.md"
if [ -f "$REFRESH" ]; then
  assert_not_grep 'probe_plugin cogni-research' "$REFRESH" "knowledge-refresh: does NOT probe cogni-research (clean break)"
  assert_grep 'probe_plugin cogni-wiki' "$REFRESH" "knowledge-refresh: still probes cogni-wiki"
else
  red "FAIL: knowledge-refresh/SKILL.md not found"
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
  red "FAIL: M11 audit — legacy knowledge-research/knowledge-report reference in live code:"
  echo "$AUDIT_HITS" | sed 's/^/    /'
  errors=$((errors + 1))
else
  green "PASS: M11 audit — no legacy chain reference in the live plugin surface"
fi

# --- Slice 16 (#308/#307) audit: prefixed-link + audit-only can't creep back ---
# The orphan linchpin was the path-prefixed `[[sources/<slug>]]` reference
# backlink, built via a `link_dir` variable in knowledge-finalize. That variable
# is gone — bare `[[<slug>]]` is the only form. And knowledge-ingest no longer
# defers backlinks as "audit-only". These two negative greps fail any future PR
# that reintroduces either pattern. (Explanatory prose may still MENTION
# `[[sources/<slug>]]` when describing the fix, so we target the CODE construct
# `link_dir`, not the literal `[[sources/`.)
assert_not_grep 'link_dir' "$FINALIZE" "knowledge-finalize: no link_dir path-prefix construction — reference backlinks stay bare [[<slug>]] (#308)"
assert_not_grep 'audit-only' "$INGEST" "knowledge-ingest: no 'audit-only' backlink deferral — apply-plan writes backlinks (#308)"
assert_grep 'theme_label' "$INGEST" "knowledge-ingest: files sources under the sub-question theme_label category (#307)"

if [ $errors -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
