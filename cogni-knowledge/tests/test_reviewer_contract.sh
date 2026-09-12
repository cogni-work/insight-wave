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
  red "FAIL: reviewer-00-agents-wiki-reviewer-md agents/wiki-reviewer.md not found"
  exit 1
fi

# Frontmatter shape — name + model + tool list mirror wiki-contradictor.md.
assert_grep 'name: wiki-reviewer' "$REV" "reviewer-01-frontmatter-name wiki-reviewer: frontmatter name"
assert_grep 'model: sonnet' "$REV" "reviewer-02-frontmatter-model-sonnet wiki-reviewer: frontmatter model: sonnet"
assert_grep 'tools: \["Read", "Write", "Glob", "Grep"\]' "$REV" "reviewer-03-tools-read-write-glob wiki-reviewer: tools = Read/Write/Glob/Grep (no Task, no Bash)"

# Single-pass + no shell — guards against drift into a re-fetching or
# orchestrating shape that breaks the zero-network premise.
REV_TOOLS_LINE=$(grep '^tools:' "$REV" || true)
if echo "$REV_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: reviewer-04-tools-list-omits-task wiki-reviewer: tools list must NOT include Task (single-pass)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: reviewer-04-tools-list-omits-task wiki-reviewer: tools list omits Task (single-pass)"
fi
if echo "$REV_TOOLS_LINE" | grep -q 'Bash'; then
  red "FAIL: reviewer-05-tools-list-omits-bash wiki-reviewer: tools list must NOT include Bash (no shell)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: reviewer-05-tools-list-omits-bash wiki-reviewer: tools list omits Bash (no shell)"
fi
if echo "$REV_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch'; then
  red "FAIL: reviewer-06-tools-list-omits-webfetch wiki-reviewer: tools list must NOT include WebFetch/WebSearch (zero-network)"
  red "  got: $REV_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: reviewer-06-tools-list-omits-webfetch wiki-reviewer: tools list omits WebFetch/WebSearch (zero-network)"
fi

# The 5 weighted structural dimensions + their weights — the core ported
# scoring contract. A weight silently changing is a behavior change.
assert_grep 'Completeness' "$REV" "reviewer-07-dimension-completeness wiki-reviewer: dimension Completeness"
assert_grep 'Coherence' "$REV" "reviewer-08-dimension-coherence wiki-reviewer: dimension Coherence"
assert_grep 'Source diversity\|Source-Diversity\|source_diversity' "$REV" "reviewer-09-dimension-source-diversity wiki-reviewer: dimension Source diversity"
assert_grep 'Depth' "$REV" "reviewer-10-dimension-depth wiki-reviewer: dimension Depth"
assert_grep 'Clarity' "$REV" "reviewer-11-dimension-clarity wiki-reviewer: dimension Clarity"
assert_grep '0.25' "$REV" "reviewer-12-completeness-weight-0-25 wiki-reviewer: Completeness weight 0.25"
assert_grep '0.20' "$REV" "reviewer-13-0-20-weights-coherence-diversity wiki-reviewer: 0.20 weights (coherence/diversity/depth)"
assert_grep '0.15' "$REV" "reviewer-14-clarity-weight-0-15 wiki-reviewer: Clarity weight 0.15"

# Inline citation-density gate — keyed on the composer's <sup>[N](url)</sup>
# shape (#300). The superscript regex is the load-bearing anchor that ties
# the gate to cogni-knowledge's actual inline citation form.
assert_grep 'Citation Density Gate\|citation-density gate\|Citation density deficit' "$REV" "reviewer-15-documents-inline-citation-density wiki-reviewer: documents the inline citation density gate"
assert_grep 'sup>' "$REV" "reviewer-16-density-gate-keys-composer wiki-reviewer: density gate keys on the composer's <sup>[N](url)</sup> shape (#300)"
# Depth cap thresholds — the gate caps Depth, mirroring upstream.
assert_grep '0.70' "$REV" "reviewer-17-wiki-reviewer-density-gate-caps-depth-0-70-high wiki-reviewer: density gate caps Depth at 0.70 (high-severity)"
assert_grep '0.85' "$REV" "reviewer-18-wiki-reviewer-density-gate-caps-depth-0-85-low wiki-reviewer: density gate caps Depth at 0.85 (low-severity)"

# Language-aware clarity — must score non-English prose natively.
assert_grep 'language-aware\|OUTPUT_LANGUAGE is not English\|output language' "$REV" "reviewer-19-language-aware-clarity-scoring wiki-reviewer: language-aware Clarity scoring"

# Accept threshold — structural-only 0.82 bar (no claims multiplier).
assert_grep '0.82' "$REV" "reviewer-20-structural-only-accept-threshold wiki-reviewer: structural-only accept threshold 0.82"

# Schema literal — the contract version-pin (bumped to 0.1.1 for the additive
# word_count block, #309 P2).
assert_grep '"schema_version": "0.1.1"' "$REV" "reviewer-21-documents-schema-version-0-1-1 wiki-reviewer: documents schema_version 0.1.1 literal (#309 P2 word_count block)"

# Self-identity — the agent must name itself as the structural-quality reviewer
# (the half of the cogni-research parity gate that is NOT citation-claim alignment).
assert_grep 'structural-quality\|structural quality' "$REV" "reviewer-22-identifies-structural-quality-reviewer wiki-reviewer: identifies as the structural-quality reviewer"

# Advisory / fail-soft posture — must be explicit so a future maintainer
# doesn't turn it into a blocking gate.
assert_grep 'advisory\|Advisory' "$REV" "reviewer-23-documents-advisory-non-blocking wiki-reviewer: documents advisory / non-blocking posture"

# Zero-network invariant — verbatim, so a drift toward re-fetch is loud.
assert_grep 'never fetch' "$REV" "reviewer-24-explicitly-states-never-fetch wiki-reviewer: explicitly states 'never fetch' (zero-network invariant)"

# Three explicit DROPS vs the upstream reviewer — each must be named so a
# maintainer cannot quietly re-add one without revisiting the contract. (The
# Word-Count gate is NO LONGER dropped — see the advisory re-add block below.)
assert_grep 'claims-verification multiplier\|claims multiplier' "$REV" "reviewer-25-names-dropped-claims-verification wiki-reviewer: names the dropped claims-verification multiplier"
assert_grep 'Arc-Structural Gate\|Arc gate\|arc-agnostic\|story-arc agnostic' "$REV" "reviewer-26-names-dropped-arc-structural wiki-reviewer: names the dropped Arc-Structural Gate"
assert_grep 'Diagram Quality Gate\|no Mermaid' "$REV" "reviewer-27-names-dropped-diagram-quality wiki-reviewer: names the dropped Diagram Quality Gate"

# The Word-Count / prose-density gate is ADVISORY only and BREVITY-NEUTRAL under
# standard density: a word DEFICIT is never penalized (target is a soft upper
# budget), the only standard cap is for a likely-TRUNCATED draft (< 0.50 of budget);
# executive still caps a word EXCESS. It records a word_count envelope block but
# drives NO expansion loop (the composer is single-pass). These guard against (a)
# silent removal, (b) a re-introduced brevity penalty, (c) promotion to a blocking gate.
assert_grep 'Word Count Gate (advisory)\|advisory Word Count Gate\|Word-Count.*advisory' "$REV" "reviewer-28-word-count-gate-advisory wiki-reviewer: Word-Count gate is ADVISORY"
assert_grep 'word_count' "$REV" "reviewer-29-emits-word-count-envelope wiki-reviewer: emits a word_count envelope block"
assert_grep 'Possible truncated draft' "$REV" "reviewer-30-standard-caps-only-likely wiki-reviewer: standard caps only a likely-truncated draft (< 0.50), not brevity"
assert_not_grep 'Word deficit' "$REV" "reviewer-31-no-word-deficit-penalty wiki-reviewer: no Word deficit penalty (brevity is the intended outcome)"
assert_grep 'Word excess' "$REV" "reviewer-32-executive-density-excess-emits wiki-reviewer: executive-density excess emits a Word excess issue"
assert_grep 'TARGET_WORDS' "$REV" "reviewer-33-takes-target-words-word wiki-reviewer: takes TARGET_WORDS for the Word Count Gate"
assert_grep 'PROSE_DENSITY' "$REV" "reviewer-34-takes-prose-density-pick wiki-reviewer: takes PROSE_DENSITY to pick the gate behaviour"
# The re-add must NOT reintroduce a loop — the advisory framing has to stay explicit.
assert_grep 'no expansion loop\|never gates finalize\|advisory only\|never blocks' "$REV" "reviewer-35-word-count-gate-explicitly wiki-reviewer: Word-Count gate explicitly drives no expansion loop / never blocks (#309 P2)"

# The executive Key Takeaways Gate is ADVISORY and EXECUTIVE-ONLY: it emits a
# low-severity 'Key Takeaways block missing' issue when an executive draft lacks
# the '## Key Takeaways' opening block, caps NO dimension, and never blocks.
# These guard against (a) silent removal of the check, (b) promotion to a
# blocking/dimension-capping gate, (c) accidental firing under standard density.
assert_grep 'Key Takeaways block missing' "$REV" "reviewer-36-documents-executive-key-takeaways wiki-reviewer: documents the executive Key Takeaways advisory issue text"
assert_grep 'Key Takeaways Gate' "$REV" "reviewer-37-names-key-takeaways-gate wiki-reviewer: names the Key Takeaways Gate"

# "What this agent does NOT do" block — at least 8 NOT invariants
# (matches the wiki-contradictor template floor).
assert_grep '## What this agent does NOT do' "$REV" "reviewer-38-wiki-reviewer-what-agent-does-not-do-section wiki-reviewer: has 'What this agent does NOT do' section"
NOT_COUNT=$(awk '/^## What this agent does NOT do$/{f=1; next} /^## /{f=0} f && /^- Does NOT/' "$REV" | wc -l)
if [ "$NOT_COUNT" -ge 8 ]; then
  green "PASS: reviewer-39-wiki-reviewer-what-agent-does-not-do-section-invariants-8 wiki-reviewer: 'What this agent does NOT do' section has $NOT_COUNT invariants (≥ 8 required)"
else
  red "FAIL: reviewer-39-wiki-reviewer-what-agent-does-not-do-section-invariants-8 wiki-reviewer: 'What this agent does NOT do' section has only $NOT_COUNT invariants (≥ 8 required)"
  errors=$((errors + 1))
fi

# Failure envelopes — both must exist so the orchestrator's fail-soft path
# has something to read. synthesis_unreadable reuses the token the finalize
# orchestrator already branches on.
assert_grep 'synthesis_unreadable' "$REV" "reviewer-40-documents-synthesis-unreadable-failure wiki-reviewer: documents synthesis_unreadable failure envelope"
assert_grep 'write_failed' "$REV" "reviewer-41-documents-write-failed-failure wiki-reviewer: documents write_failed failure envelope"

# Defence-in-depth: no cogni-wiki / cogni-research / cogni-workspace claim SKILL
# dispatch (clean-break, mirrors wiki-contradictor).
assert_not_grep 'Skill("cogni-research:' "$REV" "reviewer-42-no-skill-cogni-research wiki-reviewer: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-workspace:claim' "$REV" "reviewer-43-no-skill-cogni-workspace wiki-reviewer: no Skill('cogni-workspace:claim') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$REV" "reviewer-44-no-skill-cogni-wiki wiki-reviewer: no Skill('cogni-wiki:') dispatch (clean break)"
# Positive control, per tests/README.md: an absence assertion alone also passes on a
# gutted file, so pair it with the mechanism that replaced the dispatch.
# Anchored on structural_scores, not the pre_extracted_claims: literal the four sibling
# suites use: this agent's single mention of that literal describes knowledge-verify's
# job, not its own, so it would not track this agent losing its mechanism.
assert_grep 'structural_scores' "$REV" "reviewer-45-claims-engine-replacement-present wiki-reviewer: claims-engine replacement present — emits its own structural_scores verdict instead of a claims-verification multiplier"

# --- author-date awareness in the density gate ----------------------------
# A fully-cited author-date section carries no [N] at all, so a numbered-only
# scan scores it as a citation-density deficit purely because of marker shape.
# The pattern is asserted as a fixed string: it is a regex-metacharacter thicket,
# and its two load-bearing properties live in those metacharacters — the
# scheme anchor (ordinary parenthesized prose links are not citations) and the
# label class excluding [ and ] (so [[N]] can never match as a citation).
assert_grep_f '\(\[[^\[\]]+\]\((?:<(?:https?|file)://[^>]+>|(?:https?|file)://[^)]+)\)\)' "$REV" "reviewer-46-density-gate-counts-author-date wiki-reviewer: the density gate counts the author-date marker alongside the two numbered shapes, scheme-anchored, label class excluding [ and ], and carrying the bracketed (<url>) alternative the composer emits for a paren-bearing destination"
# The bracketed arm is the half a first pass drops, and dropping it makes a
# paren-bearing citation invisible to the density count — so pin its presence
# separately from the pattern as a whole.
assert_grep_f 'The bracketed `(<url>)` alternative comes FIRST and is not optional' "$REV" "reviewer-48-density-gate-bracketed-arm-required wiki-reviewer: the density gate's bracketed (<url>) alternative is stated as required, not incidental — the composer angle-brackets a paren-bearing destination"
# A branch with no reachable source for the family is a branch that can never be
# taken: the reviewer receives no CITATION_FORMAT parameter, so its plan read is
# the only channel.
assert_grep 'Capture `citation_format`' "$REV" "reviewer-47-reads-citation-format-from-plan wiki-reviewer: resolves the citation family by reading citation_format from the PLAN_PATH it already receives — no dispatch parameter carries it"
# #1755: an author-date draft carries no <sup>[N]</sup> at all — a URL-less source
# renders the destination-less marker instead — so a gate counting only the linked
# author-date shape scores a fully-cited URL-less section as a density deficit.
assert_grep_f '\(\[[^\[\]]+\]\)' "$REV" "reviewer-49-density-gate-counts-destination-less wiki-reviewer: the density gate counts the destination-less author-date marker under apa/mla/harvard"
# The family-blind phrasing is what an additive edit leaves standing: it asserts
# the URL-less <sup>[N]</sup> count applies under author-date too, which is the
# claim this change reverses.
assert_not_grep 'stays counted in this family too' "$REV" "reviewer-50-no-family-blind-urlless-count wiki-reviewer: the URL-less <sup>[N]</sup> count is stated for the numbered family only, never reasserted family-blind"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
