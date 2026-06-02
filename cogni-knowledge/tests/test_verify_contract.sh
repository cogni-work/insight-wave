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
# #383: the revisor-round manifest rebuild cross-checks inline URLs against the ingest manifest.
assert_grep 'citation-store.py build' "$VERIFY" "knowledge-verify: rebuilds the manifest via citation-store.py build"
assert_grep 'ingest-manifest' "$VERIFY" "knowledge-verify: revisor-round build passes --ingest-manifest (#383 URL gate)"
assert_grep 'CITATIONS_PATH' "$VERIFY" "knowledge-verify: passes CITATIONS_PATH shard subset to each verifier"
assert_grep 'VERIFY_OUT_PATH' "$VERIFY" "knowledge-verify: passes VERIFY_OUT_PATH fragment path to each verifier"
# Completeness guard: merge must catch a crashed/under-populated shard rather
# than proceeding on partial verification. (The pre-#305 `shards_merged ==
# shard_count` check no longer holds — the prefilter fragment is an extra
# fragment — so the guard is now merge's manifest-conservation error.)
assert_grep 'partial verification' "$VERIFY" "knowledge-verify: merge stops on partial verification (completeness guard)"
# #305 incremental re-verify + prefilter + patch-in-place substrate copy.
assert_grep 'verify-store.py prefilter' "$VERIFY" "knowledge-verify: runs the deterministic substring prefilter (#305)"
assert_grep '--only-ids' "$VERIFY" "knowledge-verify: shards only the delta via --only-ids on round >= 1 (#305)"
assert_grep '--carry-forward-from' "$VERIFY" "knowledge-verify: carries untouched verdicts forward via merge --carry-forward-from (#305)"
assert_grep 'DELTA_IDS' "$VERIFY" "knowledge-verify: re-verifies only the touched DELTA_IDS on round >= 1 (#305)"
# Review fix: DELTA_IDS comes from a DETERMINISTIC manifest diff (snapshot vs
# rewritten manifest), NOT the revisor's self-reported fixes_applied — so an LLM
# under-report cannot silently carry a stale verdict forward.
assert_grep 'deterministically from the manifest diff' "$VERIFY" "knowledge-verify: derives DELTA_IDS from a deterministic manifest diff, not fixes_applied (review)"
assert_grep 'citation-manifest.pre-r' "$VERIFY" "knowledge-verify: snapshots the manifest before the revisor for the diff (review)"
assert_grep 'cp ' "$VERIFY" "knowledge-verify: pre-creates draft-v{N+1} via cp before the revisor (patch-in-place substrate, #305)"
# #325: the revisor writes raw-text records (no Bash, no hand-built JSON); the
# orchestrator serializes the manifest from them via citation-store.py build on
# the revise round, so a rephrased German „…" sentence can't re-break json.loads.
assert_grep 'citation-store.py' "$VERIFY" "knowledge-verify: builds the manifest from the revisor's records via citation-store.py (#325)"
# Review fix: the prefilter is handed the current draft so it can apply the
# sentence_not_in_draft staleness guard before asserting verbatim.
assert_grep '\-\-draft "' "$VERIFY" "knowledge-verify: passes --draft to the prefilter for the staleness guard (review)"
# Review fix: shard runs every round (even on empty remaining) so stale numbered
# fragments from an interrupted prior attempt are cleared before merge.
assert_grep 'even when .*remaining_ids.* is empty' "$VERIFY" "knowledge-verify: runs shard every round to clear stale fragments (review)"
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
assert_grep 'missing id/draft_sentence' "$VERIFY" "knowledge-verify: Step 2 guards a stale citation-manifest (entries missing id/draft_sentence)"
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

# --- #337 verification-honesty surfacing (Step 6 summary) ----------------
# The verify step is where an operator first interprets "verified"; Step 6 must
# label the verdicts citation-consistent (zero-network) and surface the ratio,
# and Out of scope must point live-source re-verification at the opt-in resweep.
assert_grep 'Verification scope:' "$VERIFY" "knowledge-verify: Step 6 prints the verification-scope preamble (#337)"
assert_grep 'citation-consistent' "$VERIFY" "knowledge-verify: Step 6 labels verdicts citation-consistent (#337)"
assert_grep 'Verbatim/paraphrase ratio' "$VERIFY" "knowledge-verify: Step 6 surfaces the verbatim/paraphrase ratio (#337)"
assert_grep 'knowledge-refresh --resweep' "$VERIFY" "knowledge-verify: Out of scope cross-references knowledge-refresh --resweep (#337)"

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
# #325: the revisor writes a raw-text citation-records file (no Bash); the
# orchestrator serializes it into citation-manifest.json via citation-store.py.
# Hand-typing the manifest here re-broke json.loads on a rephrased German „…" pair.
assert_grep 'citation-manifest.json' "$REVISOR" "revisor: references citation-manifest.json (built by the orchestrator)"
assert_grep 'citation-records' "$REVISOR" "revisor: writes a raw-text citation-records file, not hand-built JSON (#325)"
assert_not_grep 'Rewrite the citation manifest' "$REVISOR" "revisor: no longer hand-rewrites the manifest JSON (#325)"
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
# #305 patch-in-place: the revisor Edits the changed sentences in a pre-created
# draft copy instead of regenerating the whole draft. Edit must be in the tools
# list, and the workflow must say it edits in place (not compose + Write whole).
assert_grep 'patch' "$REVISOR" "revisor: documents patch-in-place revision (#305)"
assert_grep 'Edit(draft-v' "$REVISOR" "revisor: applies fixes via Edit() against the new draft (#305)"
assert_grep 'pre-created' "$REVISOR" "revisor: notes the orchestrator pre-creates draft-v{N+1} as a verbatim copy (#305)"
# The old whole-draft compose-and-Write instruction must be gone — a global
# rewrite would break the byte-identity incremental re-verify depends on.
assert_not_grep 'Compose the revised draft' "$REVISOR" "revisor: dropped the whole-draft compose-and-Write step (#305)"
# #386 redundant-marker drop: when a same-sentence sibling is already aligned,
# the unsupported marker is surplus -> DROP it (don't hunt for a repoint target).
# These greps catch the precondition surface silently disappearing from the
# contract; they do not run the LLM.
assert_grep 'verified\[\]' "$REVISOR" "revisor: parses verify-vN.json verified[] to detect aligned siblings (#386)"
assert_grep 'aligned_ids' "$REVISOR" "revisor: builds the aligned_ids set from verbatim/paraphrase verdicts (#386)"
assert_grep 'redundant-marker' "$REVISOR" "revisor: documents the redundant-marker drop precondition (#386)"
assert_grep 'aligned sibling' "$REVISOR" "revisor: keys the precondition on an aligned same-sentence sibling (#386)"
# The surviving-sibling draft_sentence update is the stale-sibling regression guard:
# without it the next verify round prunes the sentence's only valid citation.
assert_grep 'Surviving-sibling bookkeeping' "$REVISOR" "revisor: updates the surviving sibling's draft_sentence after a redundant drop (#386 regression guard)"
# #404 doc-completeness: when the surplus and aligned markers point to the SAME
# source URL they render byte-identical, so a bare marker-string old_string is
# non-unique -> the drop MUST be a sentence-level Edit (whole-sentence old_string).
assert_grep 'sentence-level' "$REVISOR" "revisor: prescribes a sentence-level Edit for the identical same-source marker (#404)"
# #412 parity: the revisor emits through the same citation-store.py build gate, so it
# self-checks every retained record is a verbatim contiguous substring of the edited
# draft before returning (defence-in-depth fail-fast, mirroring wiki-composer).
assert_grep 'contiguous substring' "$REVISOR" "revisor: in-agent substring self-check of records vs edited draft before return (#412 parity)"
# Zero-network: tools list must not include WebFetch, WebSearch, Bash, or Task.
# Edit IS required now (patch-in-place); Write stays for the manifest rewrite.
REVISOR_TOOLS_LINE=$(grep '^tools:' "$REVISOR" || true)
for required in '"Read"' '"Write"' '"Edit"' '"Glob"' '"Grep"'; do
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
# #337: Phase 6 must name the citation-consistent semantics + the opt-in
# wiki-claims-resweep delegation so a future PR doesn't re-litigate the scope.
assert_grep 'citation-consistent' "$PIPELINE" "inverted-pipeline.md: Phase 6 names citation-consistent verification semantics (#337)"
assert_grep 'wiki-claims-resweep' "$PIPELINE" "inverted-pipeline.md: names the opt-in wiki-claims-resweep delegation (#337)"
assert_grep '#337' "$PIPELINE" "inverted-pipeline.md: references #337"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
