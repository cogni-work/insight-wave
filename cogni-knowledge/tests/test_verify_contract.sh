#!/usr/bin/env bash
# test_verify_contract.sh — Phase 6 (knowledge-verify + wiki-verifier +
# revisor fork) contract assertions.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md / agent-md content invariants — these checks catch a
# path, flag, or step silently disappearing from the contract, not LLM
# behaviour. The assertions below are self-documenting; do not maintain a
# parallel coverage list here (it will drift from the actual asserts).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-verify SKILL.md -------------------------------------------
VERIFY="$PLUGIN_ROOT/skills/knowledge-verify/SKILL.md"
if [ ! -f "$VERIFY" ]; then
  red "FAIL: skills/knowledge-verify/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-verify' "$VERIFY" "knowledge-verify: frontmatter name"
assert_grep 'citation-manifest.json' "$VERIFY" "knowledge-verify: reads citation-manifest.json"
assert_grep 'verify-v' "$VERIFY" "knowledge-verify: writes verify-vN.json"
assert_grep '"schema_version": "0.1.0"' "$VERIFY" "knowledge-verify: verify-vN.json schema 0.1.0"
assert_grep 'Task(wiki-verifier' "$VERIFY" "knowledge-verify: dispatches wiki-verifier via Task"
assert_grep 'Task(revisor' "$VERIFY" "knowledge-verify: dispatches revisor via Task"
# F21 fan-out: shard the manifest, dispatch N verifiers in parallel, merge fragments.
assert_grep 'verify-store.py shard' "$VERIFY" "knowledge-verify: shards the manifest via verify-store.py shard"
assert_grep 'verify-store.py merge' "$VERIFY" "knowledge-verify: merges fragments via verify-store.py merge"
assert_grep 'CITATIONS_PATH' "$VERIFY" "knowledge-verify: passes CITATIONS_PATH shard subset to each verifier"
assert_grep 'VERIFY_OUT_PATH' "$VERIFY" "knowledge-verify: passes VERIFY_OUT_PATH fragment path to each verifier"
assert_grep 'shards_merged' "$VERIFY" "knowledge-verify: asserts shards_merged == shard_count (no silent partial verify)"
assert_grep 'probe_plugin cogni-wiki' "$VERIFY" "knowledge-verify: probes cogni-wiki (clean-break)"
assert_grep 'wiki/log.md' "$VERIFY" "knowledge-verify: appends to wiki/log.md"
# Match the actual log-line shape (`## [DATE] verify | project=...`) rather
# than the bare word `verify`, which would also match the skill name.
assert_grep '\] verify | project=' "$VERIFY" "knowledge-verify: emits the '## [DATE] verify | project=...' log-line shape"
# Max-2-iterations contract from inverted-pipeline.md Phase 6.
assert_grep '2 revisor iterations' "$VERIFY" "knowledge-verify: documents the max-2 revisor iterations cap"
assert_grep 'REVISION_ROUND' "$VERIFY" "knowledge-verify: threads REVISION_ROUND through verifier dispatch"
assert_grep 'MAX_ROUNDS' "$VERIFY" "knowledge-verify: caps loop with MAX_ROUNDS"
# MAX_ROUNDS >= 3 must be rejected — the 2-iteration cap is a structural contract,
# not a tunable. Without an explicit validation step, --max-rounds 5 silently
# blows the < 5 min cost target documented in references/inverted-pipeline.md.
assert_grep 'max-rounds capped at 2' "$VERIFY" "knowledge-verify: rejects --max-rounds >= 3 (structural cap, not a tunable)"
assert_grep '0.5 Resolve MAX_ROUNDS' "$VERIFY" "knowledge-verify: has an explicit Step 0.5 that validates MAX_ROUNDS"
# Positive assertion: the SKILL must mention incrementing REVISION_ROUND between
# rounds — without this, a regression that drops the increment would silently
# infinite-loop while the contract test passes green. We grep for the prose
# stating the increment happens before the next dispatch (Step 3.3 -> loop back).
if grep -qE 'increment +(`?REVISION_ROUND`?|the (revisor )?round|round counter)' "$VERIFY"; then
  green "PASS: knowledge-verify: SKILL documents incrementing REVISION_ROUND between rounds"
else
  red "FAIL: knowledge-verify: SKILL must document incrementing REVISION_ROUND between rounds (without it, the loop would never terminate via MAX_ROUNDS)"
  errors=$((errors + 1))
fi
# Defence-in-depth: stale-sentence deviations are filtered before the dispatch
# decision (otherwise the revisor pays an LLM call just to drop manifest entries),
# and the inline prune keys on the stable id (draft_position is best-effort now).
# #291: Step 2 rejects a pre-0.0.28 manifest (entries missing id/draft_sentence)
# loud-and-early instead of mass-dropping every citation as sentence_not_in_draft.
assert_grep 'predates v0.0.28' "$VERIFY" "knowledge-verify: Step 2 guards a pre-0.0.28 citation-manifest (missing id/draft_sentence)"
assert_grep 'sentence_not_in_draft' "$VERIFY" "knowledge-verify: filters sentence_not_in_draft out of the revisor trigger (revisor can only drop these)"
assert_grep 'stale_ids' "$VERIFY" "knowledge-verify: prunes stale manifest entries by id, not by draft_position tuple"
# Defence-in-depth: confirm there is no obsolete Skill("cogni-knowledge:wiki-verifier)
# or Skill("cogni-knowledge:revisor) dispatch — agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:wiki-verifier' "$VERIFY" "knowledge-verify: no Skill('cogni-knowledge:wiki-verifier) — agents go through Task"
assert_not_grep 'Skill("cogni-knowledge:revisor' "$VERIFY" "knowledge-verify: no Skill('cogni-knowledge:revisor) — agents go through Task"
# Clean-break: no cogni-research / cogni-claims input shapes leaking through.
assert_not_grep '01-contexts/data' "$VERIFY" "knowledge-verify: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$VERIFY" "knowledge-verify: does NOT reference cogni-research's 02-sources/data"
assert_not_grep 'cogni-claims:' "$VERIFY" "knowledge-verify: does NOT dispatch any cogni-claims skill"
# allowed-tools must include Task (we dispatch the verifier and revisor).
VERIFY_TOOLS_LINE=$(grep '^allowed-tools:' "$VERIFY" || true)
if echo "$VERIFY_TOOLS_LINE" | grep -q Task; then
  green "PASS: knowledge-verify: allowed-tools includes Task"
else
  red "FAIL: knowledge-verify: allowed-tools must include Task"
  red "  got: $VERIFY_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- wiki-verifier agent -------------------------------------------------
VERIFIER="$PLUGIN_ROOT/agents/wiki-verifier.md"
if [ ! -f "$VERIFIER" ]; then
  red "FAIL: agents/wiki-verifier.md not found"
  exit 1
fi
assert_grep 'name: wiki-verifier' "$VERIFIER" "wiki-verifier: frontmatter name"
assert_grep 'citation-manifest.json' "$VERIFIER" "wiki-verifier: reads citation-manifest.json"
assert_grep 'pre_extracted_claims' "$VERIFIER" "wiki-verifier: reads pre_extracted_claims from cited pages"
assert_grep 'verify-v' "$VERIFIER" "wiki-verifier: writes verify-vN.json"
assert_grep 'verbatim' "$VERIFIER" "wiki-verifier: emits verbatim verdict"
assert_grep 'paraphrase' "$VERIFIER" "wiki-verifier: emits paraphrase verdict"
assert_grep 'unsupported' "$VERIFIER" "wiki-verifier: emits unsupported verdict"
# The informational 4th verdict for claim_id: null citations to synthesis pages.
assert_grep 'synthesis' "$VERIFIER" "wiki-verifier: emits synthesis informational verdict (for claim_id: null wikilinks)"
# Closed vocabulary of unsupported reasons — covers claim_id: null on a source
# page (composer_dropped_claim) so the synthesis verdict doesn't swallow them.
# Page kind comes from Phase 0's directory resolution, never from claim_id alone.
# F22: sentence_not_in_draft replaces draft_position_out_of_range (positions are
# no longer load-bearing — the staleness signal is draft_sentence absence).
for reason in 'page_not_found' 'claim_not_found' 'composer_dropped_claim' 'claim_text_misaligned' 'sentence_not_in_draft'; do
  assert_grep "$reason" "$VERIFIER" "wiki-verifier: documents '$reason' as an unsupported reason"
done
assert_not_grep 'draft_position_out_of_range' "$VERIFIER" "wiki-verifier: drops draft_position_out_of_range (positions no longer load-bearing)"
# F22: the alignment surface is the verbatim draft_sentence carried in the
# manifest — scored directly, never re-tokenized from the draft.
assert_grep 'draft_sentence' "$VERIFIER" "wiki-verifier: scores the manifest's draft_sentence (F22 stable surface)"
assert_grep 'page_kind_by_slug' "$VERIFIER" "wiki-verifier: tracks page kind from Phase 0 directory resolution (not inferred from claim_id)"
assert_grep 'claim_id' "$VERIFIER" "wiki-verifier: looks up claims by claim_id"
# F21 fan-out params (optional; default = whole-manifest single dispatch).
assert_grep 'CITATIONS_PATH' "$VERIFIER" "wiki-verifier: accepts CITATIONS_PATH shard override"
assert_grep 'VERIFY_OUT_PATH' "$VERIFIER" "wiki-verifier: accepts VERIFY_OUT_PATH fragment override"
# Zero-network is the load-bearing invariant.
VERIFIER_TOOLS_LINE=$(grep '^tools:' "$VERIFIER" || true)
for required in '"Read"' '"Write"' '"Glob"' '"Grep"'; do
  if echo "$VERIFIER_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: wiki-verifier: frontmatter tools: includes $required"
  else
    red "FAIL: wiki-verifier: frontmatter tools: missing $required"
    red "  got: $VERIFIER_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$VERIFIER_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch|"Task"'; then
  red "FAIL: wiki-verifier: frontmatter tools: must not include WebFetch, WebSearch, or Task (zero-network single-pass)"
  red "  got: $VERIFIER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-verifier: frontmatter tools: no WebFetch / WebSearch / Task (zero-network single-pass)"
fi

# --- revisor agent (fork) ------------------------------------------------
REVISOR="$PLUGIN_ROOT/agents/revisor.md"
if [ ! -f "$REVISOR" ]; then
  red "FAIL: agents/revisor.md not found"
  exit 1
fi
assert_grep 'name: revisor' "$REVISOR" "revisor: frontmatter name"
assert_grep 'Forked from cogni-research/agents/revisor.md' "$REVISOR" "revisor: declares fork lineage in HTML comment"
assert_grep 'verify-v' "$REVISOR" "revisor: reads verify-vN.json"
assert_grep 'deviations' "$REVISOR" "revisor: consumes verify-vN.json deviations[]"
assert_grep 'pre_extracted_claims' "$REVISOR" "revisor: rephrases toward existing pre_extracted_claims"
assert_grep 'draft-v' "$REVISOR" "revisor: writes draft-v{N+1}.md"
assert_grep 'citation-manifest.json' "$REVISOR" "revisor: rewrites citation-manifest.json"
assert_grep 'NEW_DRAFT_VERSION' "$REVISOR" "revisor: takes NEW_DRAFT_VERSION parameter"
assert_grep 'fixes_applied' "$REVISOR" "revisor: returns fixes_applied[] in JSON envelope"
# F22: locate the sentence by the manifest's verbatim draft_sentence, never by
# re-tokenizing / counting (that re-derivation was the off-by-one root cause).
assert_grep 'draft_sentence' "$REVISOR" "revisor: locates the sentence by draft_sentence (F22), not by counting"
# F23: repoint to a covering on-page claim before dropping; repoint is a first-class
# fixes_summary key so the metric distinguishes re-alignment from evidence erosion.
assert_grep 'repoint' "$REVISOR" "revisor: prefers repoint over drop (F23)"
assert_grep 'fixes_summary' "$REVISOR" "revisor: reports fixes_summary with repoint/rephrase/drop/skip"
# Slice 13 (#300): the revisor operates on the numbered <sup>[N](url)</sup> inline
# shape and edits prose in the draft's existing language (no English-only revert).
# Its citation-integrity guard counts inline numbered markers, and it explicitly
# forbids emitting an inline [[sources/]] in the body.
assert_grep 'sup>\[N\](url)' "$REVISOR" "revisor: keeps the numbered <sup>[N](url)</sup> inline citation, not inline [[sources/]] (#300)"
assert_grep 'OUTPUT_LANGUAGE' "$REVISOR" "revisor: edits prose in the draft's OUTPUT_LANGUAGE, not English-only (#300)"
# The stale 'Keep the inline [[sources/<slug>]] wikilink in place' rephrase
# instruction must be gone (it would re-pollute prose with a wikilink).
assert_not_grep 'Keep the inline `\[\[sources' "$REVISOR" "revisor: dropped the stale 'Keep the inline [[sources/...]] wikilink' instruction (#300)"
# Zero-network: tools list must not include WebFetch, WebSearch, Bash, or Task.
REVISOR_TOOLS_LINE=$(grep '^tools:' "$REVISOR" || true)
for required in '"Read"' '"Write"' '"Glob"' '"Grep"'; do
  if echo "$REVISOR_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: revisor: frontmatter tools: includes $required"
  else
    red "FAIL: revisor: frontmatter tools: missing $required"
    red "  got: $REVISOR_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$REVISOR_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch|"Task"|"Bash"'; then
  red "FAIL: revisor: frontmatter tools: must not include WebFetch, WebSearch, Task, or Bash (zero-network, no sub-dispatch, no shell)"
  red "  got: $REVISOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: revisor: frontmatter tools: no WebFetch / WebSearch / Task / Bash (zero-network, no sub-dispatch)"
fi

# Scope-discipline negatives — these deferred surfaces may appear in the
# header HTML comment (as provenance documenting what the fork dropped)
# but MUST NOT appear in the input parameter table or as live workflow.
# Pattern is the parameter-table-row form `| \`TOKEN\` |` (mirrors how
# wiki-composer's contract test enforces the same discipline).
for token in OUTPUT_LANGUAGE MARKET STORY_ARC_ID PROSE_DENSITY VERDICT_PATH; do
  if grep -q "| \`${token}\` |" "$REVISOR"; then
    red "FAIL: revisor: ${token} parameter row present (deferred surface; upstream-only at v0.0.23)"
    errors=$((errors + 1))
  else
    green "PASS: revisor: no ${token} parameter row (deferred in v0.0.23)"
  fi
done
# Expansion-mode + density-self-check + helper tokens that should be
# dropped entirely from the body. These legitimately appear in the
# top-of-file HTML comment as provenance (documenting what the fork
# dropped vs upstream) — we exempt that comment by filtering to lines
# after the `-->` close, matching how test_compose_contract.sh exempts
# wiki-composer's HTML comment for `aggregated-context.json`.
# Anchor the close-tag match so trailing whitespace on the `-->` line (rebase
# conflict resolution, autoformatter, CR-LF editor) doesn't cause the filter
# to fall through to an empty body — which would make every scope-discipline
# assert below pass vacuously.
REVISOR_BODY=$(awk 'BEGIN{p=0} /^-->[[:space:]]*$/{p=1; next} p' "$REVISOR")
if [ -z "$REVISOR_BODY" ]; then
  red "FAIL: revisor: awk body filter returned empty — '-->' close marker missing or has unexpected suffix"
  errors=$((errors + 1))
fi
for token in 'citation_density' 'cross_references_emitted' 'placed-evidence ledger' 'scripts/create-entity.sh' 'Source-Mode Evidence Gathering'; do
  if echo "$REVISOR_BODY" | grep -q -- "$token"; then
    red "FAIL: revisor: body still references '$token' (deferred surface; upstream-only at v0.0.23)"
    errors=$((errors + 1))
  else
    green "PASS: revisor: body does NOT reference '$token' (HTML-comment provenance exempted)"
  fi
done
# Clean-break invariant on the body content (the HTML comment legitimately
# mentions cogni-research / cogni-claims for provenance — the body must not
# dispatch them).
if awk '/^## /{p=1} p' "$REVISOR" | grep -qE 'Skill\("?cogni-(research|claims|wiki):'; then
  red "FAIL: revisor: body dispatches a cogni-research/cogni-claims/cogni-wiki skill"
  errors=$((errors + 1))
else
  green "PASS: revisor: body does NOT dispatch any cogni-research/cogni-claims/cogni-wiki skill"
fi

# --- Phase 6 contract token match ----------------------------------------
# The inverted-pipeline.md Phase 6 contract names three verdicts and the
# max-2-iterations cap; the agents and skill must mention them.
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 6 — `knowledge-verify`' "$PIPELINE" "inverted-pipeline.md: Phase 6 section header anchored"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
