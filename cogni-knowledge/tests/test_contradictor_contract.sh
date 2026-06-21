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

# Pure-observability posture — the agent's defining contract (it scores, never resolves).
# (The distilled-page-scoring extension is asserted directly by the distilled_claims /
# four-dirs / no-excerpt_quote checks below — no need to pin an issue tag for it.)
assert_grep 'Pure observability\|pure observability' "$CTR" "wiki-contradictor: documents the pure-observability posture"

# #363: cited-page resolution must probe the four distilled dirs after
# wiki/sources/ and parse distilled_claims (no excerpt_quote) — mirrors the
# wiki-verifier #344/#362 pattern. A revert to source-only resolution is loud.
assert_grep 'distilled_claims' "$CTR" "wiki-contradictor: parses distilled_claims (#363/#344)"
assert_grep 'concepts,entities\|concepts/\|entities/' "$CTR" "wiki-contradictor: resolves the two distilled dirs"
# Distilled claims carry no excerpt_quote — the agent must say so.
assert_grep 'no `excerpt_quote`\|no excerpt_quote\|has no excerpt_quote' "$CTR" "wiki-contradictor: distilled claims have no excerpt_quote (#363)"
# #432: the 4th evidence family — a cited type:question node's answer_claims: is
# resolved (after the distilled dirs) and scored like a source.
assert_grep 'answer_claims' "$CTR" "wiki-contradictor: parses answer_claims for a question node (#432)"
assert_grep 'wiki/questions/' "$CTR" "wiki-contradictor: resolves wiki/questions/ in the probe (#432)"
assert_grep 'acl-NNN' "$CTR" "wiki-contradictor: answer findings carry an acl-NNN conflicting_claim_id (#432)"

# --- #908 recency resolution annotation (Pass A contradiction findings) ----
# The agent emits a `resolution {survivor_claim_id, strategy:"recency", rationale}`
# annotation on each Pass A contradiction finding, mirroring source-contradictor's
# shape. The finalize-time consistency-rate store reads survivor_claim_id; a revert
# to no-resolution wiki-contradictor output would silently zero the consistency rate.
assert_grep 'resolution' "$CTR" "wiki-contradictor: documents the resolution annotation (#908)"
assert_grep 'survivor_claim_id' "$CTR" "wiki-contradictor: resolution carries survivor_claim_id (#908)"
assert_grep 'strategy.*recency\|"recency"\|recency' "$CTR" "wiki-contradictor: resolution strategy is recency (#908)"
# The annotation must be scoped to Pass A contradiction findings — explicitly NOT
# on unknown findings and NOT on Pass B (prior-synthesis) findings (no claim timestamp).
assert_grep 'no `resolution` on an `unknown`\|no.*resolution.*unknown\|unknown.*no.*resolution' "$CTR" "wiki-contradictor: no resolution on unknown findings (#908)"
assert_grep 'observability-only\|annotation.*only\|never rewrites' "$CTR" "wiki-contradictor: resolution is annotation-only — never rewrites/drops (#908)"

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

# Scope discipline — the deferred kinds must be EXPLICITLY named as
# out-of-scope so a future maintainer doesn't quietly add them without
# bumping the schema or revisiting cost.
assert_grep 'type_drift' "$CTR" "wiki-contradictor: names type_drift as deferred (scope discipline)"
assert_grep 'undercited_synthesis' "$CTR" "wiki-contradictor: names undercited_synthesis as deferred (scope discipline)"

# --- #444 synthesis-vs-prior-syntheses (approach (c), Pass B) -------------
# Pass B is now IN scope: the agent scores the new synthesis's assertive
# sentences against each prior synthesis's assertive sentences. The contract:
# a new PRIOR_SYNTHESIS_SLUGS input, an additive compared_against.prior_syntheses
# / prior_synthesis_count, and prior-synthesis findings carrying a NULL
# conflicting_claim_id (syntheses have no claim block).
assert_grep 'PRIOR_SYNTHESIS_SLUGS' "$CTR" "wiki-contradictor: documents the PRIOR_SYNTHESIS_SLUGS input (#444)"
assert_grep 'prior_syntheses' "$CTR" "wiki-contradictor: compared_against carries prior_syntheses[] (#444)"
assert_grep 'prior_synthesis_count' "$CTR" "wiki-contradictor: compared_against carries prior_synthesis_count (#444)"
# A Pass B finding's conflicting_claim_id must be null. Match either the JSON
# example (conflicting_claim_id": null) or the prose ("conflicting_claim_id: null"
# / "conflicting_claim_id` is `null`").
assert_grep 'conflicting_claim_id": null\|conflicting_claim_id: null\|conflicting_claim_id` is `null`\|conflicting_claim_id.*null' "$CTR" "wiki-contradictor: prior-synthesis findings carry a null conflicting_claim_id (#444)"
# The Pass-B corpus is the prior synthesis BODY's assertive sentences (a
# sentence-vs-sentence comparison), not claim text — name the surface.
assert_grep 'assertive sentence' "$CTR" "wiki-contradictor: Pass B compares assertive sentence vs assertive sentence (#444)"
assert_grep 'wiki/syntheses/' "$CTR" "wiki-contradictor: Pass B resolves prior wiki/syntheses/ pages (#444)"
# Decision: scores ALL prior syntheses (capped), no similarity/theme pre-rank.
assert_grep 'title-similarity-rank\|theme-filter\|scores.*ALL.*prior' "$CTR" "wiki-contradictor: scores ALL prior syntheses (capped), no title-similarity/theme pre-rank (#444 decision #2)"
# The old cross-language "(c)" collision must be gone — cross-language scoring
# is relabelled as a separate/unshipped extension (since (c) now means the
# prior-synthesis surface). A revert to the "approach (c)" cross-language
# wording trips this.
assert_grep 'separate, unshipped extension\|separate.*unshipped\|unshipped extension' "$CTR" "wiki-contradictor: cross-language scoring relabelled (no longer 'approach (c)') (#444 de-collision)"
assert_not_grep 'approach (c) territory' "$CTR" "wiki-contradictor: no stale 'approach (c) territory' cross-language label remains (#444 de-collision)"

# Pillar 2 framing — the agent must be honest about partial defense.
assert_grep 'partially defend\|Partially defends\|partial.*defend' "$CTR" "wiki-contradictor: honest about partial Pillar 2 defense"

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
