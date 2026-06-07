#!/usr/bin/env bash
# test_refresh_resweep_contract.sh — contract assertions for the v0.1.97
# knowledge-refresh --resweep NATIVE inline re-orchestration.
#
# Per tests/README.md §"Contract tests": knowledge-refresh is a pure LLM
# orchestrator with no script to execute, so regression coverage is SKILL.md
# content invariants. These catch the most likely failure mode — the opt-in
# resweep flag, its pass-throughs, or the inline orchestration silently
# regressing back to a cogni-wiki: dispatch.
#
# The re-orchestration: --resweep no longer dispatches
# cogni-wiki:wiki-claims-resweep. It runs the vendored wiki-claims-resweep
# scripts (extract_page_claims.py + resweep_planner.py) in-tree and dispatches
# cogni-claims:claims submit/verify for the live-source re-check — dropping the
# residual cogni-wiki: dispatch (archival parity grep-guard) while keeping the
# public --resweep* flags unchanged. The vendored scripts are resolved
# vendored-first via resolve_wiki_scripts(), mirroring knowledge-dashboard.
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
# The public interface is stable across the re-home — the flags table is unchanged.
assert_grep '`--resweep`' "$REFRESH" "knowledge-refresh: --resweep documented in Parameters table"
assert_grep '`--resweep-page' "$REFRESH" "knowledge-refresh: --resweep-page pass-through documented"
assert_grep '`--resweep-stale-only`' "$REFRESH" "knowledge-refresh: --resweep-stale-only pass-through documented"
assert_grep '`--resweep-days' "$REFRESH" "knowledge-refresh: --resweep-days pass-through documented"
assert_grep '`--resweep-dry-run`' "$REFRESH" "knowledge-refresh: --resweep-dry-run pass-through documented"

# --- 2) Workflow has a dedicated resweep section ---------------------------
assert_grep '### 2. Resweep' "$REFRESH" "knowledge-refresh: Workflow has a '### 2. Resweep' section"

# --- 3) The resweep is NATIVE: vendored scripts + cogni-claims, no cogni-wiki dispatch ---
assert_not_grep 'Skill("cogni-wiki:wiki-claims-resweep"' "$REFRESH" "knowledge-refresh: --resweep no longer dispatches cogni-wiki:wiki-claims-resweep"
assert_grep 'extract_page_claims.py' "$REFRESH" "knowledge-refresh: --resweep runs vendored extract_page_claims.py"
assert_grep 'resweep_planner.py' "$REFRESH" "knowledge-refresh: --resweep runs vendored resweep_planner.py"
assert_grep 'Skill("cogni-claims:claims"' "$REFRESH" "knowledge-refresh: --resweep dispatches cogni-claims:claims for live-source re-verification"
assert_grep 'resolve_wiki_scripts wiki-claims-resweep' "$REFRESH" "knowledge-refresh: --resweep resolves vendored scripts vendored-first via resolve_wiki_scripts()"
# Against the bound wiki, never a duplicated cadence pointer.
assert_grep 'binding.wiki_path' "$REFRESH" "knowledge-refresh: resweep targets binding.wiki_path"

# --- 4) Opt-in / never-auto-run discipline ---------------------------------
assert_grep 'opt-in' "$REFRESH" "knowledge-refresh: resweep documented as opt-in"
assert_grep 'never auto-run\|Never auto-runs\|never auto-dispatch' "$REFRESH" "knowledge-refresh: resweep documented as never-auto-run"

# --- 5) Out of scope names the synthesis-extractor underyield --------------
assert_grep 'underyield' "$REFRESH" "knowledge-refresh: Out of scope documents synthesis-page underyield"

# --- 6) When/Never/References surfaces -------------------------------------
# When to run carries the opt-in resweep bullet.
if grep -qE 'live source URLs.*--resweep|--resweep.*live' "$REFRESH"; then
  green "PASS: knowledge-refresh: 'When to run' surfaces the --resweep opt-in"
else
  red "FAIL: knowledge-refresh: 'When to run' must surface the --resweep opt-in"
  errors=$((errors + 1))
fi
# Never-run-when names the missing-vendored-scripts abort (no longer a missing-plugin abort).
assert_grep 'vendored wiki-claims-resweep scripts are missing\|missing-vendored-scripts' "$REFRESH" "knowledge-refresh: Never-run-when names the missing-vendored-scripts abort"
# References block lists the vendored scripts + the cogni-claims dispatch target.
assert_grep 'wiki-claims-resweep/scripts/extract_page_claims.py' "$REFRESH" "knowledge-refresh: References lists the vendored extract_page_claims.py"
assert_grep 'wiki-claims-resweep/scripts/resweep_planner.py' "$REFRESH" "knowledge-refresh: References lists the vendored resweep_planner.py"
assert_grep 'cogni-claims:claims` SKILL.md' "$REFRESH" "knowledge-refresh: References lists cogni-claims:claims as the live-source re-verification target"

# --- 7) Pre-flight probes the vendored scripts + cogni-claims (not cogni-wiki) ---
assert_not_grep 'probe_plugin cogni-wiki wiki-claims-resweep' "$REFRESH" "knowledge-refresh: pre-flight no longer probes cogni-wiki wiki-claims-resweep"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-claims-resweep/scripts' "$REFRESH" "knowledge-refresh: pre-flight tests the vendored wiki-claims-resweep scripts dir"
assert_grep 'probe_plugin cogni-claims claims' "$REFRESH" "knowledge-refresh: pre-flight probes cogni-claims when --resweep is passed"

# --- 8) Push-mode survives; pull-mode is removed (regression guard) --------
assert_grep 'Skill("cogni-wiki:wiki-lint"' "$REFRESH" "knowledge-refresh: push-mode still lints via wiki-lint"
assert_not_grep 'Skill("cogni-wiki:wiki-refresh"' "$REFRESH" "knowledge-refresh: pull-mode wiki-refresh dispatch removed"
assert_not_grep 'from-research' "$REFRESH" "knowledge-refresh: --from-research flag removed with pull-mode"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
