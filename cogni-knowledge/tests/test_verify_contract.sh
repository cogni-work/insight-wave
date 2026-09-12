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
  red "FAIL: verify-contract-00-skills-knowledge-verify-skill skills/knowledge-verify/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-verify' "$VERIFY" "verify-contract-01-knowledge-verify-frontmatter-name knowledge-verify: frontmatter name"
assert_grep 'citation-manifest.json' "$VERIFY" "verify-contract-02-knowledge-verify-reads-citation knowledge-verify: reads citation-manifest.json"
assert_grep 'verify-v' "$VERIFY" "verify-contract-03-knowledge-verify-writes-vn knowledge-verify: writes verify-vN.json"
assert_grep '"schema_version": "0.1.1"' "$VERIFY" "verify-contract-04-verify-vn-json-schema knowledge-verify: verify-vN.json schema 0.1.1"
assert_grep 'Task(wiki-verifier' "$VERIFY" "verify-contract-05-dispatches-wiki-verifier-task knowledge-verify: dispatches wiki-verifier via Task"
assert_grep 'Task(revisor' "$VERIFY" "verify-contract-06-dispatches-revisor-task knowledge-verify: dispatches revisor via Task"
# F21 fan-out: shard the manifest, dispatch N verifiers in parallel, merge fragments.
assert_grep 'verify-store.py shard' "$VERIFY" "verify-contract-07-shards-manifest-verify-store knowledge-verify: shards the manifest via verify-store.py shard"
assert_grep 'verify-store.py merge' "$VERIFY" "verify-contract-08-merges-fragments-verify-store knowledge-verify: merges fragments via verify-store.py merge"
# #383: the revisor-round manifest rebuild cross-checks inline URLs against the ingest manifest.
assert_grep 'citation-store.py build' "$VERIFY" "verify-contract-09-rebuilds-manifest-citation-store knowledge-verify: rebuilds the manifest via citation-store.py build"
assert_grep 'ingest-manifest' "$VERIFY" "verify-contract-10-revisor-round-build-passes knowledge-verify: revisor-round build passes --ingest-manifest (#383 URL gate)"
# #455: the Step 3.3 post-revisor rebuild must pass the build paths as quoted
# LITERAL CLI args, never a command-prefix env-var form
# (`RECORDS_PATH=… python3 … --records "$RECORDS_PATH"`) — that form expands
# "$RECORDS_PATH" against the still-unset current environment before the prefix
# assignment takes effect, so --records receives "" and the build aborts on the cwd.
# Positive guard pins the fixed literal shape; negative guard catches the antipattern
# returning. `RECORDS_PATH="` matches only the assignment form (the corrected prose
# names `RECORDS_PATH=…` / `"$RECORDS_PATH"`, neither of which contains `="`).
assert_grep '\-\-records "<project_path>/.metadata/citation-records-v' "$VERIFY" "verify-contract-11-step-3-3-rebuild-passes knowledge-verify: Step 3.3 rebuild passes --records as a quoted literal path (#455)"
assert_not_grep 'RECORDS_PATH="' "$VERIFY" "verify-contract-12-step-3-3-rebuild-no knowledge-verify: Step 3.3 rebuild has no command-prefix RECORDS_PATH= env-var (the #455 empty-arg antipattern)"
assert_grep 'CITATIONS_PATH' "$VERIFY" "verify-contract-13-passes-citations-path-shard knowledge-verify: passes CITATIONS_PATH shard subset to each verifier"
assert_grep 'VERIFY_OUT_PATH' "$VERIFY" "verify-contract-14-passes-verify-out-path knowledge-verify: passes VERIFY_OUT_PATH fragment path to each verifier"
# Completeness guard: merge must catch a crashed/under-populated shard rather
# than proceeding on partial verification. (The pre-#305 `shards_merged ==
# shard_count` check no longer holds — the prefilter fragment is an extra
# fragment — so the guard is now merge's manifest-conservation error.)
assert_grep 'partial verification' "$VERIFY" "verify-contract-15-merge-stops-partial-verification knowledge-verify: merge stops on partial verification (completeness guard)"
# #305 incremental re-verify + prefilter + patch-in-place substrate copy.
assert_grep 'verify-store.py prefilter' "$VERIFY" "verify-contract-16-runs-deterministic-substring-prefilter knowledge-verify: runs the deterministic substring prefilter (#305)"
assert_grep '--only-ids' "$VERIFY" "verify-contract-17-shards-only-delta-ids knowledge-verify: shards only the delta via --only-ids on round >= 1 (#305)"
assert_grep '--carry-forward-from' "$VERIFY" "verify-contract-18-carries-untouched-verdicts-forward knowledge-verify: carries untouched verdicts forward via merge --carry-forward-from (#305)"
assert_grep 'DELTA_IDS' "$VERIFY" "verify-contract-19-re-verifies-only-touched knowledge-verify: re-verifies only the touched DELTA_IDS on round >= 1 (#305)"
# Review fix: DELTA_IDS comes from a DETERMINISTIC manifest diff (snapshot vs
# rewritten manifest), NOT the revisor's self-reported fixes_applied — so an LLM
# under-report cannot silently carry a stale verdict forward.
assert_grep 'deterministically from the manifest diff' "$VERIFY" "verify-contract-20-derives-delta-ids-deterministic knowledge-verify: derives DELTA_IDS from a deterministic manifest diff, not fixes_applied (review)"
assert_grep 'citation-manifest.pre-r' "$VERIFY" "verify-contract-21-snapshots-manifest-before-revisor knowledge-verify: snapshots the manifest before the revisor for the diff (review)"
assert_grep 'cp ' "$VERIFY" "verify-contract-22-pre-creates-draft-v knowledge-verify: pre-creates draft-v{N+1} via cp before the revisor (patch-in-place substrate, #305)"
# #325: the revisor writes raw-text records (no Bash, no hand-built JSON); the
# orchestrator serializes the manifest from them via citation-store.py build on
# the revise round, so a rephrased German „…" sentence can't re-break json.loads.
assert_grep 'citation-store.py' "$VERIFY" "verify-contract-23-builds-manifest-revisor-s knowledge-verify: builds the manifest from the revisor's records via citation-store.py (#325)"
# Review fix: the prefilter is handed the current draft so it can apply the
# sentence_not_in_draft staleness guard before asserting verbatim.
assert_grep '\-\-draft "' "$VERIFY" "verify-contract-24-passes-draft-prefilter-staleness knowledge-verify: passes --draft to the prefilter for the staleness guard (review)"
# Review fix: shard runs every round (even on empty remaining) so stale numbered
# fragments from an interrupted prior attempt are cleared before merge.
assert_grep 'even when .*remaining_ids.* is empty' "$VERIFY" "verify-contract-25-runs-shard-every-round knowledge-verify: runs shard every round to clear stale fragments (review)"
assert_not_grep 'probe_plugin' "$VERIFY" "verify-contract-26-no-install-only-wiki-probe knowledge-verify: no install-only cogni-wiki probe (the verifier calls no cogni-wiki skill; wiki existence is gated directly)"
assert_grep 'wiki/log.md' "$VERIFY" "verify-contract-27-appends-wiki-log-md knowledge-verify: appends to wiki/log.md"
assert_grep 'control-path.py" log' "$VERIFY" "verify-contract-28-resolves-log-path-control knowledge-verify: resolves the log path via control-path.py (no hardcoded wiki/log.md write target)"
# Match the actual log-line shape (`## [DATE] verify | project=...`) rather
# than the bare word `verify`, which would also match the skill name.
assert_grep '\] verify | project=' "$VERIFY" "verify-contract-29-emits-date-verify-project knowledge-verify: emits the '## [DATE] verify | project=...' log-line shape"
# Max-2-iterations contract from inverted-pipeline.md Phase 6.
assert_grep '2 revisor iterations' "$VERIFY" "verify-contract-30-documents-max-2-revisor knowledge-verify: documents the max-2 revisor iterations cap"
assert_grep 'REVISION_ROUND' "$VERIFY" "verify-contract-31-threads-revision-round-through knowledge-verify: threads REVISION_ROUND through verifier dispatch"
assert_grep 'MAX_ROUNDS' "$VERIFY" "verify-contract-32-caps-loop-max-rounds knowledge-verify: caps loop with MAX_ROUNDS"
# MAX_ROUNDS >= 3 must be rejected — the 2-iteration cap is a structural contract,
# not a tunable. Without an explicit validation step, --max-rounds 5 silently
# blows the < 5 min cost target documented in references/inverted-pipeline.md.
assert_grep 'max-rounds capped at 2' "$VERIFY" "verify-contract-33-rejects-max-rounds-3 knowledge-verify: rejects --max-rounds >= 3 (structural cap, not a tunable)"
assert_grep '0.5 Resolve MAX_ROUNDS' "$VERIFY" "verify-contract-34-explicit-step-0-5-validates knowledge-verify: has an explicit Step 0.5 that validates MAX_ROUNDS"
# Positive assertion: the SKILL must mention incrementing REVISION_ROUND between
# rounds — without this, a regression that drops the increment would silently
# infinite-loop while the contract test passes green. We grep for the prose
# stating the increment happens before the next dispatch (Step 3.3 -> loop back).
if grep -qE 'increment +(`?REVISION_ROUND`?|the (revisor )?round|round counter)' "$VERIFY"; then
  green "PASS: verify-contract-35-skill-documents-incrementing-revision knowledge-verify: SKILL documents incrementing REVISION_ROUND between rounds"
else
  red "FAIL: verify-contract-35-skill-documents-incrementing-revision knowledge-verify: SKILL must document incrementing REVISION_ROUND between rounds (without it, the loop would never terminate via MAX_ROUNDS)"
  errors=$((errors + 1))
fi
# Defence-in-depth: stale-sentence deviations are filtered before the dispatch
# decision (otherwise the revisor pays an LLM call just to drop manifest entries),
# and the inline prune keys on the stable id (draft_position is best-effort now).
# #291: Step 2 rejects a pre-0.0.28 manifest (entries missing id/draft_sentence)
# loud-and-early instead of mass-dropping every citation as sentence_not_in_draft.
assert_grep 'missing id/draft_sentence' "$VERIFY" "verify-contract-36-step-2-guards-stale knowledge-verify: Step 2 guards a stale citation-manifest (entries missing id/draft_sentence)"
assert_grep 'sentence_not_in_draft' "$VERIFY" "verify-contract-37-filters-sentence-not-draft knowledge-verify: filters sentence_not_in_draft out of the revisor trigger (revisor can only drop these)"
assert_grep 'stale_ids' "$VERIFY" "verify-contract-38-prunes-stale-manifest-entries knowledge-verify: prunes stale manifest entries by id, not by draft_position tuple"
# Defence-in-depth: confirm there is no obsolete Skill("cogni-knowledge:wiki-verifier)
# or Skill("cogni-knowledge:revisor) dispatch — agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:wiki-verifier' "$VERIFY" "verify-contract-39-knowledge-verify-no-skill-cogni-wiki knowledge-verify: no Skill('cogni-knowledge:wiki-verifier) — agents go through Task"
assert_not_grep 'Skill("cogni-knowledge:revisor' "$VERIFY" "verify-contract-40-knowledge-verify-no-skill-cogni-revisor knowledge-verify: no Skill('cogni-knowledge:revisor) — agents go through Task"
# Clean-break: no cogni-research / cogni-workspace:claim input shapes leaking through.
assert_not_grep '01-contexts/data' "$VERIFY" "verify-contract-41-knowledge-verify-does-not-reference-cogni-research-s-01-contexts knowledge-verify: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$VERIFY" "verify-contract-42-knowledge-verify-does-not-reference-cogni-research-s-02-sources knowledge-verify: does NOT reference cogni-research's 02-sources/data"
assert_not_grep 'Skill("cogni-workspace:claim' "$VERIFY" "verify-contract-43-no-skill-cogni-workspace knowledge-verify: no Skill('cogni-workspace:claim') dispatch (clean break)"
# Positive control, per tests/README.md: an absence assertion alone also passes on a
# gutted file, so pair it with the mechanism that replaced the dispatch.
assert_grep 'pre_extracted_claims:' "$VERIFY" "verify-contract-44-claims-engine-replacement-present knowledge-verify: claims-engine replacement present — scores citations against the cited page's on-disk pre_extracted_claims: frontmatter (zero-network)"
# allowed-tools must include Task (we dispatch the verifier and revisor).
VERIFY_TOOLS_LINE=$(grep '^allowed-tools:' "$VERIFY" || true)
if echo "$VERIFY_TOOLS_LINE" | grep -q Task; then
  green "PASS: verify-contract-45-allowed-tools-includes-task knowledge-verify: allowed-tools includes Task"
else
  red "FAIL: verify-contract-45-allowed-tools-includes-task knowledge-verify: allowed-tools must include Task"
  red "  got: $VERIFY_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- #337 verification-honesty surfacing (Step 6 summary) ----------------
# The verify step is where an operator first interprets "verified"; Step 6 must
# label the verdicts citation-consistent (zero-network) and surface the ratio,
# and Out of scope must point live-source re-verification at the opt-in resweep.
assert_grep 'Verification scope:' "$VERIFY" "verify-contract-46-step-6-prints-verification knowledge-verify: Step 6 prints the verification-scope preamble (#337)"
assert_grep 'citation-consistent' "$VERIFY" "verify-contract-47-step-6-labels-verdicts knowledge-verify: Step 6 labels verdicts citation-consistent (#337)"
assert_grep 'Verbatim/paraphrase ratio' "$VERIFY" "verify-contract-48-step-6-surfaces-verbatim knowledge-verify: Step 6 surfaces the verbatim/paraphrase ratio (#337)"
assert_grep 'knowledge-refresh --resweep' "$VERIFY" "verify-contract-49-out-scope-cross-references knowledge-verify: Out of scope cross-references knowledge-refresh --resweep (#337)"

# --- wiki-verifier agent -------------------------------------------------
VERIFIER="$PLUGIN_ROOT/agents/wiki-verifier.md"
if [ ! -f "$VERIFIER" ]; then
  red "FAIL: verify-contract-50-agents-wiki-verifier-md agents/wiki-verifier.md not found"
  exit 1
fi
assert_grep 'name: wiki-verifier' "$VERIFIER" "verify-contract-51-wiki-verifier-frontmatter-name wiki-verifier: frontmatter name"
assert_grep 'citation-manifest.json' "$VERIFIER" "verify-contract-52-wiki-verifier-reads-citation wiki-verifier: reads citation-manifest.json"
assert_grep 'pre_extracted_claims' "$VERIFIER" "verify-contract-53-reads-pre-extracted-claims wiki-verifier: reads pre_extracted_claims from cited pages"
assert_grep 'verify-v' "$VERIFIER" "verify-contract-54-wiki-verifier-writes-verify wiki-verifier: writes verify-vN.json"
assert_grep 'verbatim' "$VERIFIER" "verify-contract-55-emits-verbatim-verdict wiki-verifier: emits verbatim verdict"
assert_grep 'paraphrase' "$VERIFIER" "verify-contract-56-emits-paraphrase-verdict wiki-verifier: emits paraphrase verdict"
assert_grep 'unsupported' "$VERIFIER" "verify-contract-57-emits-unsupported-verdict wiki-verifier: emits unsupported verdict"
# The informational 4th verdict for claim_id: null citations to synthesis pages.
assert_grep 'synthesis' "$VERIFIER" "verify-contract-58-emits-synthesis-informational-verdict wiki-verifier: emits synthesis informational verdict (for claim_id: null wikilinks)"
# Closed vocabulary of unsupported reasons — covers claim_id: null on a source
# page (composer_dropped_claim) so the synthesis verdict doesn't swallow them.
# Page kind comes from Phase 0's directory resolution, never from claim_id alone.
# F22: sentence_not_in_draft replaces draft_position_out_of_range (positions are
# no longer load-bearing — the staleness signal is draft_sentence absence).
for reason in 'page_not_found' 'claim_not_found' 'composer_dropped_claim' 'claim_text_misaligned' 'sentence_not_in_draft'; do
  assert_grep "$reason" "$VERIFIER" "verify-contract-59-documents-unsupported-reason-${reason//_/-} wiki-verifier: documents '$reason' as an unsupported reason"
done
assert_not_grep 'draft_position_out_of_range' "$VERIFIER" "verify-contract-60-drops-draft-position-out wiki-verifier: drops draft_position_out_of_range (positions no longer load-bearing)"
# F22: the alignment surface is the verbatim draft_sentence carried in the
# manifest — scored directly, never re-tokenized from the draft.
assert_grep 'draft_sentence' "$VERIFIER" "verify-contract-61-scores-manifest-s-draft wiki-verifier: scores the manifest's draft_sentence (F22 stable surface)"
assert_grep 'page_kind_by_slug' "$VERIFIER" "verify-contract-62-tracks-page-kind-phase wiki-verifier: tracks page kind from Phase 0 directory resolution (not inferred from claim_id)"
assert_grep 'claim_id' "$VERIFIER" "verify-contract-63-looks-up-claims-claim wiki-verifier: looks up claims by claim_id"
# #432: the 4th evidence family — a type:question node's answer_claims: is scored
# like a source (text-only needle, no excerpt_quote). The directory resolution +
# the "source-like" verdict set must recognize it.
assert_grep 'wiki/questions/<slug>.md` → `"question"`\|questions/<slug>.md. → .question' "$VERIFIER" "verify-contract-64-phase-0-resolves-wiki wiki-verifier: Phase 0 resolves wiki/questions/ → question (#432)"
assert_grep 'answer_claims' "$VERIFIER" "verify-contract-65-parses-answer-claims-question wiki-verifier: parses answer_claims for a question node (#432)"
assert_grep 'source, concept, entity, question' "$VERIFIER" "verify-contract-66-source-like-set-includes wiki-verifier: 'source-like' set includes question (#432)"
# F21 fan-out params (optional; default = whole-manifest single dispatch).
assert_grep 'CITATIONS_PATH' "$VERIFIER" "verify-contract-67-accepts-citations-path-shard wiki-verifier: accepts CITATIONS_PATH shard override"
assert_grep 'VERIFY_OUT_PATH' "$VERIFIER" "verify-contract-68-accepts-verify-out-path wiki-verifier: accepts VERIFY_OUT_PATH fragment override"
# Zero-network is the load-bearing invariant.
VERIFIER_TOOLS_LINE=$(grep '^tools:' "$VERIFIER" || true)
for _p in read:'"Read"' write:'"Write"' glob:'"Glob"' grep:'"Grep"'; do
  _cid="${_p%%:*}"; required="${_p#*:}"
  if echo "$VERIFIER_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: verify-contract-69-wiki-verifier-frontmatter-tools-includes-${_cid} wiki-verifier: frontmatter tools: includes $required"
  else
    red "FAIL: verify-contract-69-wiki-verifier-frontmatter-tools-includes-${_cid} wiki-verifier: frontmatter tools: missing $required"
    red "  got: $VERIFIER_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$VERIFIER_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch|"Task"'; then
  red "FAIL: verify-contract-70-wiki-verifier-frontmatter-tools-no-webfetch wiki-verifier: frontmatter tools: must not include WebFetch, WebSearch, or Task (zero-network single-pass)"
  red "  got: $VERIFIER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: verify-contract-70-wiki-verifier-frontmatter-tools-no-webfetch wiki-verifier: frontmatter tools: no WebFetch / WebSearch / Task (zero-network single-pass)"
fi

# --- revisor agent (fork) ------------------------------------------------
REVISOR="$PLUGIN_ROOT/agents/revisor.md"
if [ ! -f "$REVISOR" ]; then
  red "FAIL: verify-contract-71-agents-revisor-md-not agents/revisor.md not found"
  exit 1
fi
assert_grep 'name: revisor' "$REVISOR" "verify-contract-72-revisor-frontmatter-name revisor: frontmatter name"
assert_grep 'Forked from cogni-research/agents/revisor.md' "$REVISOR" "verify-contract-73-declares-fork-lineage-html revisor: declares fork lineage in HTML comment"
assert_grep 'verify-v' "$REVISOR" "verify-contract-74-reads-verify-vn-json revisor: reads verify-vN.json"
assert_grep 'deviations' "$REVISOR" "verify-contract-75-consumes-verify-vn-json revisor: consumes verify-vN.json deviations[]"
assert_grep 'pre_extracted_claims' "$REVISOR" "verify-contract-76-rephrases-toward-existing-pre revisor: rephrases toward existing pre_extracted_claims"
assert_grep 'draft-v' "$REVISOR" "verify-contract-77-writes-draft-v-n revisor: writes draft-v{N+1}.md"
# #325: the revisor writes a raw-text citation-records file (no Bash); the
# orchestrator serializes it into citation-manifest.json via citation-store.py.
# Hand-typing the manifest here re-broke json.loads on a rephrased German „…" pair.
assert_grep 'citation-manifest.json' "$REVISOR" "verify-contract-78-references-citation-manifest-json revisor: references citation-manifest.json (built by the orchestrator)"
assert_grep 'citation-records' "$REVISOR" "verify-contract-79-writes-raw-text-citation revisor: writes a raw-text citation-records file, not hand-built JSON (#325)"
assert_not_grep 'Rewrite the citation manifest' "$REVISOR" "verify-contract-80-no-longer-hand-rewrites revisor: no longer hand-rewrites the manifest JSON (#325)"
assert_grep 'NEW_DRAFT_VERSION' "$REVISOR" "verify-contract-81-takes-new-draft-version revisor: takes NEW_DRAFT_VERSION parameter"
assert_grep 'fixes_applied' "$REVISOR" "verify-contract-82-returns-fixes-applied-json revisor: returns fixes_applied[] in JSON envelope"
# F22: locate the sentence by the manifest's verbatim draft_sentence, never by
# re-tokenizing / counting (that re-derivation was the off-by-one root cause).
assert_grep 'draft_sentence' "$REVISOR" "verify-contract-83-locates-sentence-draft-f22 revisor: locates the sentence by draft_sentence (F22), not by counting"
# F23: repoint to a covering on-page claim before dropping; repoint is a first-class
# fixes_summary key so the metric distinguishes re-alignment from evidence erosion.
assert_grep 'repoint' "$REVISOR" "verify-contract-84-prefers-repoint-drop-f23 revisor: prefers repoint over drop (F23)"
assert_grep 'fixes_summary' "$REVISOR" "verify-contract-85-reports-fixes-summary-repoint revisor: reports fixes_summary with repoint/rephrase/drop/skip"
# Slice 13 (#300): the revisor operates on the numbered <sup>[N](url)</sup> inline
# shape and edits prose in the draft's existing language (no English-only revert).
# Its citation-integrity guard counts inline numbered markers, and it explicitly
# forbids emitting an inline [[sources/]] in the body.
assert_grep 'sup>\[N\](url)' "$REVISOR" "verify-contract-86-keeps-numbered-sup-n revisor: keeps the numbered <sup>[N](url)</sup> inline citation, not inline [[sources/]] (#300)"
assert_grep 'OUTPUT_LANGUAGE' "$REVISOR" "verify-contract-87-edits-prose-draft-s revisor: edits prose in the draft's OUTPUT_LANGUAGE, not English-only (#300)"
# The stale 'Keep the inline [[sources/<slug>]] wikilink in place' rephrase
# instruction must be gone (it would re-pollute prose with a wikilink).
assert_not_grep 'Keep the inline `\[\[sources' "$REVISOR" "verify-contract-88-dropped-stale-keep-inline revisor: dropped the stale 'Keep the inline [[sources/...]] wikilink' instruction (#300)"
# #305 patch-in-place: the revisor Edits the changed sentences in a pre-created
# draft copy instead of regenerating the whole draft. Edit must be in the tools
# list, and the workflow must say it edits in place (not compose + Write whole).
assert_grep 'patch' "$REVISOR" "verify-contract-89-documents-patch-place-revision revisor: documents patch-in-place revision (#305)"
assert_grep 'Edit(draft-v' "$REVISOR" "verify-contract-90-applies-fixes-edit-against revisor: applies fixes via Edit() against the new draft (#305)"
assert_grep 'pre-created' "$REVISOR" "verify-contract-91-notes-orchestrator-pre-creates revisor: notes the orchestrator pre-creates draft-v{N+1} as a verbatim copy (#305)"
# The old whole-draft compose-and-Write instruction must be gone — a global
# rewrite would break the byte-identity incremental re-verify depends on.
assert_not_grep 'Compose the revised draft' "$REVISOR" "verify-contract-92-dropped-whole-draft-compose revisor: dropped the whole-draft compose-and-Write step (#305)"
# #386 redundant-marker drop: when a same-sentence sibling is already aligned,
# the unsupported marker is surplus -> DROP it (don't hunt for a repoint target).
# These greps catch the precondition surface silently disappearing from the
# contract; they do not run the LLM.
assert_grep 'verified\[\]' "$REVISOR" "verify-contract-93-parses-verify-vn-json revisor: parses verify-vN.json verified[] to detect aligned siblings (#386)"
assert_grep 'aligned_ids' "$REVISOR" "verify-contract-94-builds-aligned-ids-set revisor: builds the aligned_ids set from verbatim/paraphrase verdicts (#386)"
assert_grep 'redundant-marker' "$REVISOR" "verify-contract-95-documents-redundant-marker-drop revisor: documents the redundant-marker drop precondition (#386)"
assert_grep 'aligned sibling' "$REVISOR" "verify-contract-96-keys-precondition-aligned-same revisor: keys the precondition on an aligned same-sentence sibling (#386)"
# The surviving-sibling draft_sentence update is the stale-sibling regression guard:
# without it the next verify round prunes the sentence's only valid citation.
assert_grep 'Surviving-sibling bookkeeping' "$REVISOR" "verify-contract-97-updates-surviving-sibling-s revisor: updates the surviving sibling's draft_sentence after a redundant drop (#386 regression guard)"
# #404 doc-completeness: when the surplus and aligned markers point to the SAME
# source URL they render byte-identical, so a bare marker-string old_string is
# non-unique -> the drop MUST be a sentence-level Edit (whole-sentence old_string).
assert_grep 'sentence-level' "$REVISOR" "verify-contract-98-prescribes-sentence-level-edit revisor: prescribes a sentence-level Edit for the identical same-source marker (#404)"
# #412 parity: the revisor emits through the same citation-store.py build gate, so it
# self-checks every retained record is a verbatim contiguous substring of the edited
# draft before returning (defence-in-depth fail-fast, mirroring wiki-composer).
assert_grep 'contiguous substring' "$REVISOR" "verify-contract-99-agent-substring-self-check revisor: in-agent substring self-check of records vs edited draft before return (#412 parity)"
# Zero-network: tools list must not include WebFetch, WebSearch, Bash, or Task.
# Edit IS required now (patch-in-place); Write stays for the manifest rewrite.
REVISOR_TOOLS_LINE=$(grep '^tools:' "$REVISOR" || true)
for _p in read:'"Read"' write:'"Write"' edit:'"Edit"' glob:'"Glob"' grep:'"Grep"'; do
  _cid="${_p%%:*}"; required="${_p#*:}"
  if echo "$REVISOR_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: verify-contract-100-revisor-frontmatter-tools-includes-${_cid} revisor: frontmatter tools: includes $required"
  else
    red "FAIL: verify-contract-100-revisor-frontmatter-tools-includes-${_cid} revisor: frontmatter tools: missing $required"
    red "  got: $REVISOR_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$REVISOR_TOOLS_LINE" | grep -qE 'WebFetch|WebSearch|"Task"|"Bash"'; then
  red "FAIL: verify-contract-101-revisor-frontmatter-tools-no revisor: frontmatter tools: must not include WebFetch, WebSearch, Task, or Bash (zero-network, no sub-dispatch, no shell)"
  red "  got: $REVISOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: verify-contract-101-revisor-frontmatter-tools-no revisor: frontmatter tools: no WebFetch / WebSearch / Task / Bash (zero-network, no sub-dispatch)"
fi

# Scope-discipline negatives — these deferred surfaces may appear in the
# header HTML comment (as provenance documenting what the fork dropped)
# but MUST NOT appear in the input parameter table or as live workflow.
# Pattern is the parameter-table-row form `| \`TOKEN\` |` (mirrors how
# wiki-composer's contract test enforces the same discipline).
for _p in output-language:OUTPUT_LANGUAGE market:MARKET story-arc-id:STORY_ARC_ID prose-density:PROSE_DENSITY verdict-path:VERDICT_PATH; do
  _cid="${_p%%:*}"; token="${_p#*:}"
  if grep -q "| \`${token}\` |" "$REVISOR"; then
    red "FAIL: verify-contract-102-no-parameter-row-deferred-${_cid} revisor: ${token} parameter row present (deferred surface; upstream-only at v0.0.23)"
    errors=$((errors + 1))
  else
    green "PASS: verify-contract-102-no-parameter-row-deferred-${_cid} revisor: no ${token} parameter row (deferred in v0.0.23)"
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
  red "FAIL: verify-contract-103-awk-body-filter-returned revisor: awk body filter returned empty — '-->' close marker missing or has unexpected suffix"
  errors=$((errors + 1))
else
  green "PASS: verify-contract-103-awk-body-filter-returned revisor: awk body filter returned a non-empty body"
fi
for _p in citation-density:'citation_density' cross-references-emitted:'cross_references_emitted' placed-evidence-ledger:'placed-evidence ledger' create-entity-sh:'scripts/create-entity.sh' source-mode-evidence-gathering:'Source-Mode Evidence Gathering'; do
  _cid="${_p%%:*}"; token="${_p#*:}"
  if echo "$REVISOR_BODY" | grep -q -- "$token"; then
    red "FAIL: verify-contract-104-body-does-not-reference-${_cid} revisor: body still references '$token' (deferred surface; upstream-only at v0.0.23)"
    errors=$((errors + 1))
  else
    green "PASS: verify-contract-104-body-does-not-reference-${_cid} revisor: body does NOT reference '$token' (HTML-comment provenance exempted)"
  fi
done
# Clean-break invariant on the body content (the HTML comment legitimately
# mentions cogni-research / cogni-workspace:claim for provenance — the body must not
# dispatch them).
if awk '/^## /{p=1} p' "$REVISOR" | grep -qE 'Skill\("?(cogni-research:|cogni-wiki:|cogni-workspace:claim)'; then
  red "FAIL: verify-contract-105-body-does-not-dispatch revisor: body dispatches a cogni-research/cogni-workspace-claims/cogni-wiki skill"
  errors=$((errors + 1))
else
  green "PASS: verify-contract-105-body-does-not-dispatch revisor: body does NOT dispatch any cogni-research/cogni-workspace-claims/cogni-wiki skill"
fi

# --- Phase 6 contract token match ----------------------------------------
# The inverted-pipeline.md Phase 6 contract names three verdicts and the
# max-2-iterations cap; the agents and skill must mention them.
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 6 — `knowledge-verify`' "$PIPELINE" "verify-contract-106-phase-6-section-header inverted-pipeline.md: Phase 6 section header anchored"
# #337: Phase 6 must name the citation-consistent semantics + the opt-in
# wiki-claims-resweep delegation so a future PR doesn't re-litigate the scope.
assert_grep 'citation-consistent' "$PIPELINE" "verify-contract-107-phase-6-names-citation inverted-pipeline.md: Phase 6 names citation-consistent verification semantics (#337)"
assert_grep 'wiki-claims-resweep' "$PIPELINE" "verify-contract-108-names-opt-wiki-claims inverted-pipeline.md: names the opt-in wiki-claims-resweep delegation (#337)"
assert_grep '#337' "$PIPELINE" "verify-contract-109-references-337 inverted-pipeline.md: references #337"

# --- revisor: author-date awareness --------------------------------------
# The read-back citation-integrity check counts inline markers and returns
# write_failed on a mismatch. A numbered-only count over an author-date draft
# returns zero for every retained citation, so a CORRECT draft fails. Reuses the
# $REVISOR bind above rather than adding a second one.
assert_grep_f '([Author, Year](url))' "$REVISOR" "verify-contract-110-revisor-counts-author-date-markers revisor: the read-back citation-integrity check counts markers of the draft's own family, including the author-date shapes"
# That check needs a reachable source for the family. The Task(revisor, ...)
# dispatch threads no CITATION_FORMAT, so the plan read under the PROJECT_PATH
# it already receives is the only channel — without it the branch above is
# unreachable and the assertion would prove nothing.
assert_grep 'Read the citation format' "$REVISOR" "verify-contract-111-revisor-reads-citation-format revisor: resolves the citation family by reading plan.json under the PROJECT_PATH it already receives — no dispatch parameter carries it"

# --- wiki-verifier: author-date grounding normalization (#1877) -----------
# Phase 1 step 3's grounding normalization stripped `[N]`/`<sup>` only, so an
# author-date marker survived into the compared string and the
# `excerpt_quote` containment test failed on a citation that was in fact
# grounded — depressing the headline grounding rate `verify-store.py merge`
# aggregates. Reuses the $VERIFIER bind above rather than adding a second one.
assert_grep_f '([Author, Year](url))' "$VERIFIER" "verify-contract-112-verifier-strips-author-date-markers wiki-verifier: the grounding normalization strips markers of the draft's own family, including the author-date shapes"
# That strip needs a reachable source for the family. The Task(wiki-verifier, ...)
# dispatch threads no CITATION_FORMAT, so the plan read under the PROJECT_PATH
# it already receives is the only channel — without it the branch above is
# unreachable and the assertion would prove nothing.
assert_grep 'Read the citation format' "$VERIFIER" "verify-contract-113-verifier-reads-citation-format wiki-verifier: resolves the citation family by reading plan.json under the PROJECT_PATH it already receives — no dispatch parameter carries it"

# --- revisor read-back citation-integrity check (#1755) ---------------------
# The revisor counts inline markers of the draft's own family and compares that
# count against its citation records; a family whose URL-less shape it does not
# recognize returns write_failed on a CORRECT draft.
REVISOR="$PLUGIN_ROOT/agents/revisor.md"
assert_grep_f '`([Author, Year])` / `([Author])` / `([Author Year])`' "$REVISOR" "verify-contract-114-revisor-counts-destination-less revisor: the read-back citation-integrity check counts the destination-less author-date marker under apa/mla/harvard"
# The family-blind phrasing is the half an additive edit leaves behind — it says
# the plain <sup>[N]</sup> is the URL-less form in EVERY family, which is the
# claim this change reverses.
assert_not_grep 'keeps that shape in every family' "$REVISOR" "verify-contract-115-no-family-blind-urlless-shape revisor: the plain <sup>[N]</sup> is stated as the numbered family's URL-less form only, never family-blind"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
