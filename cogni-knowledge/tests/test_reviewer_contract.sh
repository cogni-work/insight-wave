#!/usr/bin/env bash
# test_reviewer_contract.sh — Phase 7 (wiki-reviewer agent, #309 P1.1)
# content-invariant contract assertions.
#
# Mirrors tests/test_contradictor_contract.sh's shape: a single agent.md
# grep block that catches a Phase-1 dimension, a dropped gate, or an
# invariant silently disappearing. Never asserts LLM scoring behavior —
# that is the live-verification surface (§ "How to verify" in the PR body).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- wiki-reviewer agent file --------------------------------------------
REV="$PLUGIN_ROOT/agents/wiki-reviewer.md"
if [ ! -f "$REV" ]; then
  red "FAIL: agents/wiki-reviewer.md not found"
  exit 1
fi

# Frontmatter shape — name + model + tool list mirror wiki-contradictor.md.
assert_grep 'name: wiki-reviewer' "$REV" "wiki-reviewer: frontmatter name"
assert_grep 'model: sonnet' "$REV" "wiki-reviewer: frontmatter model: sonnet"
assert_grep 'tools: \["Read", "Write", "Glob", "Grep"\]' "$REV" "wiki-reviewer: tools = Read/Write/Glob/Grep (no Task, no Bash)"

# Single-pass + no shell — guards against drift into a re-fetching or
# orchestrating shape that breaks the zero-network premise.
REV_TOOLS_LINE=$(grep '^tools:' "$REV" || true)
if echo "$REV_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: wiki-reviewer: tools list must NOT include Task (single-pass)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-reviewer: tools list omits Task (single-pass)"
fi
if echo "$REV_TOOLS_LINE" | grep -q 'Bash'; then
  red "FAIL: wiki-reviewer: tools list must NOT include Bash (no shell)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-reviewer: tools list omits Bash (no shell)"
fi
if echo "$REV_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch'; then
  red "FAIL: wiki-reviewer: tools list must NOT include WebFetch/WebSearch (zero-network)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-reviewer: tools list omits WebFetch/WebSearch (zero-network)"
fi

# The 5 weighted structural dimensions + their weights — the core ported
# scoring contract. A weight silently changing is a behavior change.
assert_grep 'Completeness' "$REV" "wiki-reviewer: dimension Completeness"
assert_grep 'Coherence' "$REV" "wiki-reviewer: dimension Coherence"
assert_grep 'Source diversity\|Source-Diversity\|source_diversity' "$REV" "wiki-reviewer: dimension Source diversity"
assert_grep 'Depth' "$REV" "wiki-reviewer: dimension Depth"
assert_grep 'Clarity' "$REV" "wiki-reviewer: dimension Clarity"
assert_grep '0.25' "$REV" "wiki-reviewer: Completeness weight 0.25"
assert_grep '0.20' "$REV" "wiki-reviewer: 0.20 weights (coherence/diversity/depth)"
assert_grep '0.15' "$REV" "wiki-reviewer: Clarity weight 0.15"

# Inline citation-density gate — keyed on the composer's <sup>[N](url)</sup>
# shape (#300). The superscript regex is the load-bearing anchor that ties
# the gate to cogni-knowledge's actual inline citation form.
assert_grep 'Citation Density Gate\|citation-density gate\|Citation density deficit' "$REV" "wiki-reviewer: documents the inline citation density gate"
assert_grep 'sup>' "$REV" "wiki-reviewer: density gate keys on the composer's <sup>[N](url)</sup> shape (#300)"
# Depth cap thresholds — the gate caps Depth, mirroring upstream.
assert_grep '0.70' "$REV" "wiki-reviewer: density gate caps Depth at 0.70 (high-severity)"
assert_grep '0.85' "$REV" "wiki-reviewer: density gate caps Depth at 0.85 (low-severity)"

# Language-aware clarity — must score non-English prose natively.
assert_grep 'language-aware\|OUTPUT_LANGUAGE is not English\|output language' "$REV" "wiki-reviewer: language-aware Clarity scoring"

# Accept threshold — structural-only 0.82 bar (no claims multiplier).
assert_grep '0.82' "$REV" "wiki-reviewer: structural-only accept threshold 0.82"

# Schema literal — the contract version-pin (bumped to 0.1.1 for the additive
# word_count block, #309 P2).
assert_grep '"schema_version": "0.1.1"' "$REV" "wiki-reviewer: documents schema_version 0.1.1 literal (#309 P2 word_count block)"

# Self-identity — the agent must name itself as the structural-quality reviewer
# (the half of the cogni-research parity gate that is NOT citation-claim alignment).
assert_grep 'structural-quality\|structural quality' "$REV" "wiki-reviewer: identifies as the structural-quality reviewer"

# Advisory / fail-soft posture — must be explicit so a future maintainer
# doesn't turn it into a blocking gate.
assert_grep 'advisory\|Advisory' "$REV" "wiki-reviewer: documents advisory / non-blocking posture"

# Zero-network invariant — verbatim, so a drift toward re-fetch is loud.
assert_grep 'never fetch' "$REV" "wiki-reviewer: explicitly states 'never fetch' (zero-network invariant)"

# Three explicit DROPS vs the upstream reviewer — each must be named so a
# maintainer cannot quietly re-add one without revisiting the contract. (The
# Word-Count gate is NO LONGER dropped — see the advisory re-add block below.)
assert_grep 'claims-verification multiplier\|claims multiplier' "$REV" "wiki-reviewer: names the dropped claims-verification multiplier"
assert_grep 'Arc-Structural Gate\|Arc gate\|arc-agnostic\|story-arc agnostic' "$REV" "wiki-reviewer: names the dropped Arc-Structural Gate"
assert_grep 'Diagram Quality Gate\|no Mermaid' "$REV" "wiki-reviewer: names the dropped Diagram Quality Gate"

# The Word-Count / prose-density gate is ADVISORY only and BREVITY-NEUTRAL under
# standard density: a word DEFICIT is never penalized (target is a soft upper
# budget), the only standard cap is for a likely-TRUNCATED draft (< 0.50 of budget);
# executive still caps a word EXCESS. It records a word_count envelope block but
# drives NO expansion loop (the composer is single-pass). These guard against (a)
# silent removal, (b) a re-introduced brevity penalty, (c) promotion to a blocking gate.
assert_grep 'Word Count Gate (advisory)\|advisory Word Count Gate\|Word-Count.*advisory' "$REV" "wiki-reviewer: Word-Count gate is ADVISORY"
assert_grep 'word_count' "$REV" "wiki-reviewer: emits a word_count envelope block"
assert_grep 'Possible truncated draft' "$REV" "wiki-reviewer: standard caps only a likely-truncated draft (< 0.50), not brevity"
assert_not_grep 'Word deficit' "$REV" "wiki-reviewer: no Word deficit penalty (brevity is the intended outcome)"
assert_grep 'Word excess' "$REV" "wiki-reviewer: executive-density excess emits a Word excess issue"
assert_grep 'TARGET_WORDS' "$REV" "wiki-reviewer: takes TARGET_WORDS for the Word Count Gate"
assert_grep 'PROSE_DENSITY' "$REV" "wiki-reviewer: takes PROSE_DENSITY to pick the gate behaviour"
# The re-add must NOT reintroduce a loop — the advisory framing has to stay explicit.
assert_grep 'no expansion loop\|never gates finalize\|advisory only\|never blocks' "$REV" "wiki-reviewer: Word-Count gate explicitly drives no expansion loop / never blocks (#309 P2)"

# The executive Key Takeaways Gate is ADVISORY and EXECUTIVE-ONLY: it emits a
# low-severity 'Key Takeaways block missing' issue when an executive draft lacks
# the '## Key Takeaways' opening block, caps NO dimension, and never blocks.
# These guard against (a) silent removal of the check, (b) promotion to a
# blocking/dimension-capping gate, (c) accidental firing under standard density.
assert_grep 'Key Takeaways block missing' "$REV" "wiki-reviewer: documents the executive Key Takeaways advisory issue text"
assert_grep 'Key Takeaways Gate' "$REV" "wiki-reviewer: names the Key Takeaways Gate"

# "What this agent does NOT do" block — at least 8 NOT invariants
# (matches the wiki-contradictor template floor).
assert_grep '## What this agent does NOT do' "$REV" "wiki-reviewer: has 'What this agent does NOT do' section"
NOT_COUNT=$(awk '/^## What this agent does NOT do$/{f=1; next} /^## /{f=0} f && /^- Does NOT/' "$REV" | wc -l)
if [ "$NOT_COUNT" -ge 8 ]; then
  green "PASS: wiki-reviewer: 'What this agent does NOT do' section has $NOT_COUNT invariants (≥ 8 required)"
else
  red "FAIL: wiki-reviewer: 'What this agent does NOT do' section has only $NOT_COUNT invariants (≥ 8 required)"
  errors=$((errors + 1))
fi

# Failure envelopes — both must exist so the orchestrator's fail-soft path
# has something to read. synthesis_unreadable reuses the token the finalize
# orchestrator already branches on.
assert_grep 'synthesis_unreadable' "$REV" "wiki-reviewer: documents synthesis_unreadable failure envelope"
assert_grep 'write_failed' "$REV" "wiki-reviewer: documents write_failed failure envelope"

# Defence-in-depth: no cogni-wiki / cogni-research / cogni-claims SKILL
# dispatch (clean-break, mirrors wiki-contradictor).
assert_not_grep 'Skill("cogni-research:' "$REV" "wiki-reviewer: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-claims:' "$REV" "wiki-reviewer: no Skill('cogni-claims:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$REV" "wiki-reviewer: no Skill('cogni-wiki:') dispatch (clean break)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
