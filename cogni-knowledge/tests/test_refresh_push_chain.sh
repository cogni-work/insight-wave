#!/usr/bin/env bash
# test_refresh_push_chain.sh — contract assertions for the v0.0.26 (M10b)
# knowledge-refresh push-mode rewrite onto the v0.1.0 inverted pipeline.
#
# Per tests/README.md §"Contract tests": knowledge-refresh is a pure LLM
# orchestrator with no script to execute, so regression coverage is SKILL.md
# content invariants. These catch the most likely failure mode — a phase
# dispatch silently dropping out of the chain, or a legacy cogni-research
# reference creeping back into the runtime path.
#
# Asserts:
#   - Push-mode §2 dispatches the seven inverted-pipeline phase skills
#     (plan → curate → fetch → ingest → compose → verify → finalize) IN ORDER.
#   - Clean break: no `knowledge-research` dispatch anywhere, no
#     `Skill("cogni-research:` dispatch, no `probe_plugin cogni-research`.
#   - Pull-mode is removed: no `--from-research` flag and no
#     `cogni-wiki:wiki-refresh` dispatch remain (pull-mode bridged from a
#     completed cogni-research project, which is being sunset).
#   - Push-mode staleness is re-homed off the `cogni-wiki:wiki-lint` SKILL
#     dispatch onto the vendored `lint_wiki.py` (run in-tree, resolved via
#     resolve_wiki_scripts) — no `Skill("cogni-wiki:wiki-lint"` dispatch
#     remains, so push-mode needs no cogni-wiki install and the archival
#     parity grep-guard greens on this skill.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

REFRESH="$PLUGIN_ROOT/skills/knowledge-refresh/SKILL.md"
if [ ! -f "$REFRESH" ]; then
  red "FAIL: knowledge-refresh/SKILL.md not found"
  exit 1
fi

# --- 1) Seven phase dispatches present ------------------------------------
for phase in plan curate fetch ingest compose verify finalize; do
  assert_grep "Skill(\"cogni-knowledge:knowledge-${phase}\"" "$REFRESH" \
    "push-mode dispatches knowledge-${phase}"
done

# --- 2) Phases appear in pipeline order ------------------------------------
# Grab the first line number of each phase dispatch and assert monotonic.
prev=0
order_ok=1
for phase in plan curate fetch ingest compose verify finalize; do
  ln=$(grep -nE "Skill\(\"cogni-knowledge:knowledge-${phase}\"" "$REFRESH" | head -1 | cut -d: -f1)
  if [ -z "$ln" ]; then
    order_ok=0
    break
  fi
  if [ "$ln" -le "$prev" ]; then
    order_ok=0
    red "FAIL: knowledge-${phase} dispatch (line $ln) is not after the previous phase (line $prev)"
    break
  fi
  prev="$ln"
done
if [ "$order_ok" -eq 1 ]; then
  green "PASS: the seven phase dispatches appear in plan→…→finalize order"
else
  red "FAIL: phase dispatches are out of order or missing"
  errors=$((errors + 1))
fi

# --- 2.5) Autonomous finalize suppresses the interactive portal confirm -----
# Push-mode is autonomous, so its knowledge-finalize dispatch must pass
# --no-portal-prompt (the --no-cobrowse parallel) — otherwise finalize would
# block on the human-direct apply-portal AskUserQuestion (#516).
FINALIZE_DISPATCH=$(grep 'Skill("cogni-knowledge:knowledge-finalize"' "$REFRESH" || true)
if echo "$FINALIZE_DISPATCH" | grep -q '\-\-no-portal-prompt'; then
  green "PASS: push-mode finalize dispatch passes --no-portal-prompt (#516)"
else
  red "FAIL: push-mode finalize dispatch must pass --no-portal-prompt (autonomous, never block on the portal confirm)"
  red "  got: $FINALIZE_DISPATCH"
  errors=$((errors + 1))
fi

# --- 3) Clean-break invariant ----------------------------------------------
# The legacy push-mode dispatched cogni-knowledge:knowledge-research (which
# transitively reached cogni-research). That dispatch — and the cogni-research
# pre-flight probe — must be fully gone.
assert_not_grep 'knowledge-research' "$REFRESH" \
  "no knowledge-research reference (legacy push dispatch removed)"
assert_not_grep 'probe_plugin cogni-research' "$REFRESH" \
  "no cogni-research pre-flight probe (clean break)"
if grep -qE 'Skill\("?cogni-research:' "$REFRESH" 2>/dev/null; then
  red "FAIL: knowledge-refresh dispatches a cogni-research skill"
  grep -nE 'Skill\("?cogni-research:' "$REFRESH"
  errors=$((errors + 1))
else
  green "PASS: no Skill(\"cogni-research:\") dispatch"
fi

# --- 4) Pull-mode is removed; push-mode survives ---------------------------
assert_not_grep '\-\-from-research' "$REFRESH" "pull-mode --from-research flag removed"
assert_not_grep 'Skill("cogni-wiki:wiki-refresh"' "$REFRESH" "pull-mode wiki-refresh dispatch removed"

# --- 5) Push-mode lint is re-homed onto the vendored lint_wiki.py -----------
# Push-mode no longer dispatches the cogni-wiki:wiki-lint SKILL; it runs the
# vendored lint_wiki.py in-tree (resolved via resolve_wiki_scripts), so a
# Karpathy base needs no cogni-wiki install for push-mode and the archival
# parity grep-guard greens on this skill.
assert_not_grep 'Skill("cogni-wiki:wiki-lint"' "$REFRESH" "push-mode no longer dispatches cogni-wiki:wiki-lint (re-homed to vendored lint_wiki.py)"
assert_grep 'lint_wiki.py' "$REFRESH" "push-mode lints via the vendored lint_wiki.py"

# --- 6) Evidence-aware refresh candidates feed the topic menu --------------
# Push-mode §1 reads binding.refresh_candidates[] (the evidence-aware signals
# flagged at knowledge-ingest-source time) and merges them into the AskUserQuestion
# topic menu alongside the time-based stale findings, labelled distinctly.
assert_grep 'refresh_candidates' "$REFRESH" "push-mode reads binding.refresh_candidates[] into the topic menu"
assert_grep 'newer evidence' "$REFRESH" "push-mode labels evidence-based candidates distinctly from time-based stale findings"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
