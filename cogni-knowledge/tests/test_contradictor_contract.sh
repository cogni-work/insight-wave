#!/usr/bin/env bash
# test_contradictor_contract.sh — Phase 7 (wiki-contradictor agent, #335)
# content-invariant contract assertions.
#
# Mirrors tests/test_verify_contract.sh's shape: a single SKILL.md /
# agent.md grep block that catches a Phase 1 step or invariant silently
# disappearing. Never asserts LLM scoring behavior — that is the live-
# verification surface (§ "How to verify" in the PR body).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- wiki-contradictor agent file ----------------------------------------
CTR="$PLUGIN_ROOT/agents/wiki-contradictor.md"
if [ ! -f "$CTR" ]; then
  red "FAIL: agents/wiki-contradictor.md not found"
  exit 1
fi

# Frontmatter shape — name + model + tool list mirror wiki-verifier.md exactly.
assert_grep 'name: wiki-contradictor' "$CTR" "wiki-contradictor: frontmatter name"
assert_grep 'model: sonnet' "$CTR" "wiki-contradictor: frontmatter model: sonnet"
assert_grep 'tools: \["Read", "Write", "Glob", "Grep"\]' "$CTR" "wiki-contradictor: tools = Read/Write/Glob/Grep (no Task, no Bash)"

# Single-pass + no shell — guards against drift into a re-fetching or
# orchestrating shape that breaks the zero-network premise.
CTR_TOOLS_LINE=$(grep '^tools:' "$CTR" || true)
if echo "$CTR_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: wiki-contradictor: tools list must NOT include Task (single-pass)"
  red "  got: $CTR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-contradictor: tools list omits Task (single-pass)"
fi
if echo "$CTR_TOOLS_LINE" | grep -q 'Bash'; then
  red "FAIL: wiki-contradictor: tools list must NOT include Bash (no shell)"
  red "  got: $CTR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-contradictor: tools list omits Bash (no shell)"
fi

# Phase 1 kind vocabulary — only contradiction + unknown ship in v0.1.15.
assert_grep '`contradiction`' "$CTR" "wiki-contradictor: documents kind=contradiction"
assert_grep '`unknown`' "$CTR" "wiki-contradictor: documents kind=unknown"
# Severity vocabulary — three levels, all referenced.
assert_grep '`high`' "$CTR" "wiki-contradictor: documents severity=high"
assert_grep '`medium`' "$CTR" "wiki-contradictor: documents severity=medium"
assert_grep '`low`' "$CTR" "wiki-contradictor: documents severity=low"

# Schema literal — the contract version-pin.
assert_grep '"schema_version": "0.1.0"' "$CTR" "wiki-contradictor: documents schema_version 0.1.0 literal"

# Issue reference — the agent must say WHICH issue it implements.
assert_grep '#335' "$CTR" "wiki-contradictor: references issue #335"

# Zero-network invariant — verbatim, so a drift toward re-fetch is loud.
assert_grep 'never fetch' "$CTR" "wiki-contradictor: explicitly states 'never fetch' (zero-network invariant)"

# "What this agent does NOT do" block — at least 8 NOT invariants
# (matches §3.1 of the plan and the wiki-verifier.md template).
assert_grep '## What this agent does NOT do' "$CTR" "wiki-contradictor: has 'What this agent does NOT do' section"
NOT_COUNT=$(awk '/^## What this agent does NOT do$/{f=1; next} /^## /{f=0} f && /^- Does NOT/' "$CTR" | wc -l)
if [ "$NOT_COUNT" -ge 8 ]; then
  green "PASS: wiki-contradictor: 'What this agent does NOT do' section has $NOT_COUNT invariants (≥ 8 required)"
else
  red "FAIL: wiki-contradictor: 'What this agent does NOT do' section has only $NOT_COUNT invariants (≥ 8 required)"
  errors=$((errors + 1))
fi

# Phase 1 scope discipline — the deferred kinds must be EXPLICITLY named
# as out-of-scope so a future maintainer doesn't quietly add them without
# bumping the schema or revisiting cost.
assert_grep 'type_drift' "$CTR" "wiki-contradictor: names type_drift as deferred (Phase 1 scope discipline)"
assert_grep 'undercited_synthesis' "$CTR" "wiki-contradictor: names undercited_synthesis as deferred (Phase 1 scope discipline)"
# Source-only comparison — synthesis-vs-synthesis is out of scope.
assert_grep 'synthesis-vs-prior-syntheses\|synthesis-vs-synthesis\|prior `wiki/syntheses/' "$CTR" "wiki-contradictor: names synthesis-vs-synthesis as out of scope (Phase 1)"

# Pillar 2 framing — the agent must be honest about partial defense.
assert_grep 'partially defend\|Partially defends\|partial.*defend\|Phase 1' "$CTR" "wiki-contradictor: honest about partial Pillar 2 defense"

# Conservative-bias discipline — the agent prompt MUST steer toward 'low'
# on doubt. This is R1's only structural mitigation.
assert_grep 'conservative\|Conservative' "$CTR" "wiki-contradictor: documents conservative scoring bias (R1)"

# Cap on unknown (R1 mitigation) — without the cap, low-confidence
# findings flood the summary.
assert_grep 'Cap.*unknown\|cap.*unknown' "$CTR" "wiki-contradictor: caps unknown at 3 per run (R1 mitigation)"

# Severity-gated summary surface contract — the orchestrator filters
# medium/low to counts-only, so the agent must produce those counts.
assert_grep '"high"' "$CTR" "wiki-contradictor: documents high in counts payload"
assert_grep '"medium"' "$CTR" "wiki-contradictor: documents medium in counts payload"

# Failure envelopes — both must exist so the orchestrator's fail-soft
# path has something to read.
assert_grep 'synthesis_unreadable' "$CTR" "wiki-contradictor: documents synthesis_unreadable failure envelope"
assert_grep 'write_failed' "$CTR" "wiki-contradictor: documents write_failed failure envelope"

# Defence-in-depth: no cogni-wiki / cogni-research / cogni-claims SKILL
# dispatch (clean-break, mirrors wiki-verifier).
assert_not_grep 'Skill("cogni-research:' "$CTR" "wiki-contradictor: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-claims:' "$CTR" "wiki-contradictor: no Skill('cogni-claims:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$CTR" "wiki-contradictor: no Skill('cogni-wiki:') dispatch (clean break)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
