#!/usr/bin/env bash
# test_refresh_resweep_contract.sh — contract assertions for the v0.1.16 (#337)
# knowledge-refresh --resweep opt-in skeleton.
#
# Per tests/README.md §"Contract tests": knowledge-refresh is a pure LLM
# orchestrator with no script to execute, so regression coverage is SKILL.md
# content invariants. These catch the most likely failure mode — the opt-in
# resweep flag, its pass-throughs, or the upstream dispatch silently dropping
# out of the contract.
#
# The minimal (a)-skeleton from #337: --resweep delegates to the existing
# cogni-wiki:wiki-claims-resweep primitive against the bound wiki. It is opt-in
# only (never auto-dispatched), and the synthesis-page extractor adapter is
# explicitly deferred to v0.1.17+.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

REFRESH="$PLUGIN_ROOT/skills/knowledge-refresh/SKILL.md"
if [ ! -f "$REFRESH" ]; then
  red "FAIL: skills/knowledge-refresh/SKILL.md not found"
  exit 1
fi

# --- 1) Parameters table documents --resweep + the four pass-throughs ------
assert_grep '`--resweep`' "$REFRESH" "knowledge-refresh: --resweep documented in Parameters table (#337)"
assert_grep '`--resweep-page' "$REFRESH" "knowledge-refresh: --resweep-page pass-through documented (#337)"
assert_grep '`--resweep-stale-only`' "$REFRESH" "knowledge-refresh: --resweep-stale-only pass-through documented (#337)"
assert_grep '`--resweep-days' "$REFRESH" "knowledge-refresh: --resweep-days pass-through documented (#337)"
assert_grep '`--resweep-dry-run`' "$REFRESH" "knowledge-refresh: --resweep-dry-run pass-through documented (#337)"

# --- 2) Workflow has a dedicated resweep-dispatch section ------------------
assert_grep '### 3. Resweep dispatch' "$REFRESH" "knowledge-refresh: Workflow has a '### 3. Resweep dispatch' section (#337)"

# --- 3) The dispatch goes through the upstream primitive -------------------
assert_grep 'Skill("cogni-wiki:wiki-claims-resweep"' "$REFRESH" "knowledge-refresh: --resweep dispatches cogni-wiki:wiki-claims-resweep (#337)"
# Against the bound wiki, never a duplicated cadence pointer.
assert_grep 'binding.wiki_path' "$REFRESH" "knowledge-refresh: resweep targets binding.wiki_path (#337)"

# --- 4) Opt-in / never-auto-run discipline ---------------------------------
assert_grep 'opt-in' "$REFRESH" "knowledge-refresh: resweep documented as opt-in (#337)"
assert_grep 'never auto-run\|Never auto-runs\|never auto-dispatch' "$REFRESH" "knowledge-refresh: resweep documented as never-auto-run (#337)"

# --- 5) Out of scope names the synthesis-extractor underyield -----
assert_grep 'extract_page_claims.py' "$REFRESH" "knowledge-refresh: Out of scope names the upstream inline-URL extractor (#337)"
assert_grep 'underyield' "$REFRESH" "knowledge-refresh: Out of scope documents synthesis-page underyield (#337)"

# --- 6) When/Never/References surfaces -------------------------------------
assert_grep 'wiki-claims-resweep' "$REFRESH" "knowledge-refresh: delegates the resweep to cogni-wiki:wiki-claims-resweep"
# When to run gains the opt-in resweep bullet.
if grep -qE 'live source URLs.*--resweep|--resweep.*live' "$REFRESH"; then
  green "PASS: knowledge-refresh: 'When to run' surfaces the --resweep opt-in"
else
  red "FAIL: knowledge-refresh: 'When to run' must surface the --resweep opt-in (#337)"
  errors=$((errors + 1))
fi
# Never run when gains the missing-plugin abort.
assert_grep 'wiki-claims-resweep` is not installed\|wiki-claims-resweep is not installed' "$REFRESH" "knowledge-refresh: Never-run-when names the missing wiki-claims-resweep abort (#337)"
# References block lists the dispatch target.
assert_grep 'cogni-wiki:wiki-claims-resweep` SKILL.md' "$REFRESH" "knowledge-refresh: References lists cogni-wiki:wiki-claims-resweep (#337)"

# --- 7) Pre-flight probes the resweep target -------------------------------
assert_grep 'probe_plugin cogni-wiki wiki-claims-resweep' "$REFRESH" "knowledge-refresh: pre-flight probes wiki-claims-resweep when --resweep is passed (#337)"

# --- 8) Push/pull modes survive (regression guard) -------------------------
assert_grep 'Skill("cogni-wiki:wiki-refresh"' "$REFRESH" "knowledge-refresh: pull-mode still dispatches wiki-refresh"
assert_grep 'Skill("cogni-wiki:wiki-lint"' "$REFRESH" "knowledge-refresh: push-mode still lints via wiki-lint"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
