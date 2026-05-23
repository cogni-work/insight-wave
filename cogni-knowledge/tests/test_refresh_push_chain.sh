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
#     (Descriptive pull-mode references to a "cogni-research project" via
#     --from-research are allowed — pull-mode reads project files on disk and
#     dispatches cogni-wiki:wiki-refresh, NOT a cogni-research skill.)
#   - Pull-mode survives the rewrite (--from-research + wiki-refresh dispatch).
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

# --- 4) Pull-mode survives -------------------------------------------------
assert_grep '\-\-from-research' "$REFRESH" "pull-mode still takes --from-research"
assert_grep 'Skill("cogni-wiki:wiki-refresh"' "$REFRESH" "pull-mode still dispatches wiki-refresh"
assert_grep 'Skill("cogni-wiki:wiki-lint"' "$REFRESH" "push-mode still lints via wiki-lint"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
