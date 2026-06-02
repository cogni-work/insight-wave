#!/usr/bin/env bash
# test_source_contradictor_contract.sh — Phase 4 (source-contradictor agent)
# content-invariant contract assertions.
#
# Mirrors tests/test_contradictor_contract.sh's shape: a single agent.md grep
# block that catches a Phase 1 step or invariant silently disappearing. Never
# asserts LLM scoring behavior — that is the live-verification surface.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- source-contradictor agent file --------------------------------------
SC="$PLUGIN_ROOT/agents/source-contradictor.md"
if [ ! -f "$SC" ]; then
  red "FAIL: agents/source-contradictor.md not found"
  exit 1
fi

# Frontmatter shape — name + model + tool list mirror wiki-contradictor.md exactly.
assert_grep 'name: source-contradictor' "$SC" "source-contradictor: frontmatter name"
assert_grep 'model: sonnet' "$SC" "source-contradictor: frontmatter model: sonnet"
assert_grep 'tools: \["Read", "Write", "Glob", "Grep"\]' "$SC" "source-contradictor: tools = Read/Write/Glob/Grep (no Task, no Bash)"

# Single-pass + no shell — guards against drift into a re-fetching or
# orchestrating shape that breaks the zero-network premise.
SC_TOOLS_LINE=$(grep '^tools:' "$SC" || true)
if echo "$SC_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: source-contradictor: tools list must NOT include Task (single-pass)"
  errors=$((errors + 1))
else
  green "PASS: source-contradictor: tools list omits Task (single-pass)"
fi
if echo "$SC_TOOLS_LINE" | grep -q 'Bash'; then
  red "FAIL: source-contradictor: tools list must NOT include Bash (no shell)"
  errors=$((errors + 1))
else
  green "PASS: source-contradictor: tools list omits Bash (no shell)"
fi

# kind vocabulary — only contradiction + unknown.
assert_grep '`contradiction`' "$SC" "source-contradictor: documents kind=contradiction"
assert_grep '`unknown`' "$SC" "source-contradictor: documents kind=unknown"
# Severity vocabulary — three levels, all referenced.
assert_grep '`high`' "$SC" "source-contradictor: documents severity=high"
assert_grep '`medium`' "$SC" "source-contradictor: documents severity=medium"
assert_grep '`low`' "$SC" "source-contradictor: documents severity=low"

# Schema literal — the contract version-pin.
assert_grep '"schema_version": "0.1.0"' "$SC" "source-contradictor: documents schema_version 0.1.0 literal"

# Pure-observability posture — the agent's defining contract.
assert_grep 'Pure observability\|pure observability' "$SC" "source-contradictor: documents the pure-observability posture"

# Claim-vs-claim surface: resolves all three claim families across the six dirs.
assert_grep 'pre_extracted_claims' "$SC" "source-contradictor: parses pre_extracted_claims (NEW source claims)"
assert_grep 'distilled_claims' "$SC" "source-contradictor: parses distilled_claims (distilled peer)"
assert_grep 'answer_claims' "$SC" "source-contradictor: parses answer_claims (question-node peer)"
assert_grep 'concepts,entities,summaries,learnings\|concepts/\|entities/\|summaries/\|learnings/' "$SC" "source-contradictor: resolves the four distilled dirs"
assert_grep 'wiki/questions/' "$SC" "source-contradictor: resolves wiki/questions/ in the probe"
assert_grep 'wiki/sources/' "$SC" "source-contradictor: resolves wiki/sources/ in the probe"

# New-vs-new AND new-vs-peer comparison must both be documented.
assert_grep 'NEW-vs-NEW\|new-vs-new\|other NEW' "$SC" "source-contradictor: documents new-vs-new comparison"
assert_grep 'PEER\|peer' "$SC" "source-contradictor: documents peer comparison"

# No sentence-splitting (the structural difference from wiki-contradictor).
assert_grep 'No sentence-splitting\|no sentence-splitting\|not split claims into sentences\|split claims into sentences' "$SC" "source-contradictor: states no sentence-splitting (claim-vs-claim)"

# Zero-network invariant — verbatim, so a drift toward re-fetch is loud.
assert_grep 'never fetch\|It never fetches' "$SC" "source-contradictor: explicitly states it never fetches (zero-network invariant)"

# "What this agent does NOT do" block — at least 8 NOT invariants.
assert_grep '## What this agent does NOT do' "$SC" "source-contradictor: has 'What this agent does NOT do' section"
NOT_COUNT=$(awk '/^## What this agent does NOT do$/{f=1; next} /^## /{f=0} f && /^- Does NOT/' "$SC" | wc -l)
if [ "$NOT_COUNT" -ge 8 ]; then
  green "PASS: source-contradictor: 'What this agent does NOT do' section has $NOT_COUNT invariants (≥ 8 required)"
else
  red "FAIL: source-contradictor: 'What this agent does NOT do' section has only $NOT_COUNT invariants (≥ 8 required)"
  errors=$((errors + 1))
fi

# Conservative-bias discipline — steer toward 'low' on doubt.
assert_grep 'conservative\|Conservative' "$SC" "source-contradictor: documents conservative scoring bias"
# Cap on unknown.
assert_grep 'Cap.*unknown\|cap.*unknown' "$SC" "source-contradictor: caps unknown at 3 per group"

# Severity-gated counts payload.
assert_grep '"high"' "$SC" "source-contradictor: documents high in counts payload"
assert_grep '"medium"' "$SC" "source-contradictor: documents medium in counts payload"

# Failure envelopes — both must exist so the orchestrator's fail-soft path
# has something to read.
assert_grep 'group_unreadable' "$SC" "source-contradictor: documents group_unreadable failure envelope"
assert_grep 'write_failed' "$SC" "source-contradictor: documents write_failed failure envelope"

# Pure-observability: never gates ingest / never rolls back.
assert_grep 'never gates ingest\|never gate ingest\|gate ingest\|roll back\|rolls back\|rolling back' "$SC" "source-contradictor: documents it never gates ingest / never rolls back"

# Defence-in-depth: no cogni-wiki / cogni-research / cogni-claims SKILL dispatch.
assert_not_grep 'Skill("cogni-research:' "$SC" "source-contradictor: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-claims:' "$SC" "source-contradictor: no Skill('cogni-claims:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$SC" "source-contradictor: no Skill('cogni-wiki:') dispatch (clean break)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
