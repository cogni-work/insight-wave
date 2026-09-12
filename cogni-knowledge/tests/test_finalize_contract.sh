#!/usr/bin/env bash
# test_finalize_contract.sh — Phase 7 (knowledge-finalize skill +
# cycle-guard.py citation-manifest fallback) contract assertions.
#
# Two surfaces in one file:
#   1. SKILL.md content-invariant grep tests (matches the M7/M8 contract-test
#      style at tests/test_compose_contract.sh + test_verify_contract.sh).
#   2. Inline cycle-guard.py fixture tests for the new manifest-shape
#      fallback added in v0.0.24 — clear + cycle_detected against synthetic
#      v0.1.0 projects (.metadata/citation-manifest.json instead of
#      02-sources/data/src-*.md). Existing test_cycle_guard_*.sh exercise
#      the legacy shape unchanged.
#
# bash 3.2 + grep only (+ python3 for the inline cycle-guard fixture).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"
. "$(dirname "$0")/fixtures/_cycle_guard_lib.sh"

errors=0

# --- knowledge-finalize SKILL.md -----------------------------------------
FIN="$PLUGIN_ROOT/skills/knowledge-finalize/SKILL.md"
if [ ! -f "$FIN" ]; then
  red "FAIL: finalize-00-skills-knowledge-finalize-skill skills/knowledge-finalize/SKILL.md not found"
  exit 1
fi

# The verbatim Step 5/6 compose+write subprocess was offloaded to a reference
# file for progressive disclosure (the SKILL.md body keeps the imperative step +
# env-input list + output contract, and points at this file for the exact code).
# Per-string contract assertions that target the subprocess code grep $FINREF;
# assertions on the imperative body still grep $FIN.
FINREF="$PLUGIN_ROOT/references/finalize-compose-subprocess.md"
if [ ! -f "$FINREF" ]; then
  red "FAIL: finalize-01-references-finalize-compose-subprocess references/finalize-compose-subprocess.md not found"
  exit 1
fi

assert_grep 'name: knowledge-finalize' "$FIN" "finalize-02-frontmatter-name knowledge-finalize: frontmatter name"
assert_grep 'citation-manifest.json' "$FIN" "finalize-03-reads-citation-manifest-json knowledge-finalize: reads citation-manifest.json"
assert_grep 'verify-v' "$FIN" "finalize-04-reads-verify-vn-json knowledge-finalize: reads verify-vN.json from M8"
assert_grep 'wiki/syntheses/' "$FIN" "finalize-05-deposits-wiki-syntheses knowledge-finalize: deposits to wiki/syntheses/"
assert_grep 'type: synthesis' "$FIN" "finalize-06-synthesis-page-type-frontmatter knowledge-finalize: synthesis page has type: synthesis frontmatter"
assert_grep 'derived_from_research:' "$FIN" "finalize-07-stamps-derived-research-inline knowledge-finalize: stamps derived_from_research inline"
assert_grep 'draft_revision_round:' "$FIN" "finalize-08-records-draft-revision-round knowledge-finalize: records draft_revision_round (informational audit)"
assert_grep 'cycle-guard.py' "$FIN" "finalize-09-dispatches-cycle-guard-py knowledge-finalize: dispatches cycle-guard.py"
assert_grep '## References' "$FIN" "finalize-10-auto-generates-references-section knowledge-finalize: auto-generates ## References section"
# cogni-wiki is retired: the pre-flight gates on the VENDORED engine only. The
# paired not-grep is the anti-regression half — an external probe must not return.
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts' "$FIN" "finalize-11-probes-vendored-engine knowledge-finalize: pre-flight gates on the vendored wiki-ingest engine"
assert_not_grep 'probe_plugin cogni-wiki' "$FIN" "finalize-11b-no-external-cogni-wiki-probe knowledge-finalize: carries no external cogni-wiki fallback probe (vendored-only)"
assert_grep 'resolve_wiki_scripts wiki-ingest' "$FIN" "finalize-12-resolves-wiki-ingest-scripts knowledge-finalize: resolves WIKI_INGEST_SCRIPTS via generalized resolver"
assert_grep 'wiki_index_update.py' "$FIN" "finalize-13-calls-cogni-wiki-index knowledge-finalize: calls cogni-wiki wiki_index_update.py at script level"
assert_grep 'config_bump.py' "$FIN" "finalize-14-calls-cogni-wiki-config knowledge-finalize: calls cogni-wiki config_bump.py at script level"
assert_grep 'rebuild_context_brief.py' "$FIN" "finalize-15-calls-cogni-wiki-rebuild knowledge-finalize: calls cogni-wiki rebuild_context_brief.py at script level"
assert_grep 'category "Syntheses"' "$FIN" "finalize-16-indexes-synthesis-syntheses-category knowledge-finalize: indexes synthesis under Syntheses category"
# #344: cited-page kind lookup resolves the distilled dirs so concept/entity
# citations get a title + bare [[<slug>]] backlink + wiki://<slug>
# source, not page_kind=None (which would drop them from the reference list / graph).
assert_grep '("concept", "concepts")' "$FINREF" "finalize-17-resolves-cited-concept-pages knowledge-finalize: resolves cited concept pages (#344)"
assert_grep '("entity", "entities")' "$FINREF" "finalize-18-resolves-cited-entity-pages knowledge-finalize: resolves cited entity pages (#344)"
# Reader-facing engine-owned type line directly under the synthesis H1.
assert_grep 'page_type_line("synthesis")' "$FINREF" "finalize-19-emits-deterministic-type-synthesis knowledge-finalize: emits the deterministic Type: Synthesis line under the H1"
assert_grep 'page_type_line' "$FINREF" "finalize-20-imports-page-type-line knowledge-finalize: imports page_type_line from _knowledge_lib"
# #324: Step 7 passes the --max-summary word-boundary clamp backstop (cogni-wiki
# v0.0.47+), and the "truncated to 180 chars" instruction that caused the mid-word
# artifact is gone (the summary is authored as one crisp, complete sentence).
assert_grep 'max-summary' "$FIN" "finalize-21-step-7-passes-max knowledge-finalize: Step 7 passes --max-summary clamp backstop (#324)"
assert_not_grep '180' "$FIN" "finalize-22-no-truncated-180-chars knowledge-finalize: no 'truncated to 180 chars' instruction remains (#324)"
# #387: Step 7 sanitizes the authored summary (stray U+2020 dagger / NBSP -> space)
# before the index update, same guard knowledge-ingest Step 4.2 applies.
assert_grep 'sanitize_summary' "$FIN" "finalize-23-step-7-sanitizes-summary knowledge-finalize: Step 7 sanitizes the summary before the index update (#387)"
assert_grep 'append-project' "$FIN" "finalize-24-appends-binding-knowledge-py knowledge-finalize: appends to binding via knowledge-binding.py append-project"
assert_grep 'report-source wiki' "$FIN" "finalize-25-hard-codes-report-source knowledge-finalize: hard-codes --report-source wiki on binding append"
# Step 9 clears any evidence-aware refresh candidate for the just-deposited
# synthesis (closes the knowledge-ingest-source → knowledge-refresh loop). Fail-soft.
assert_grep 'resolve-refresh-candidate' "$FIN" "finalize-26-step-9-clears-refresh knowledge-finalize: Step 9 clears the refresh candidate via knowledge-binding.py resolve-refresh-candidate"
# Step 9 ALSO clears by citation overlap (--cites with the full cited-source CSV
# captured after Step 5/6), so a refresh that lands under a slug diverging from
# the originally-flagged synthesis still resolves the stale candidate.
assert_grep '\-\-cites' "$FIN" "finalize-27-step-9-passes-cites knowledge-finalize: Step 9 passes --cites for the citation-overlap refresh-candidate clear"
assert_grep 'CITED_SOURCE_SLUGS_FULL_CSV' "$FIN" "finalize-28-captures-untruncated-cited-source knowledge-finalize: captures the untruncated cited-source CSV for the Step 9 --cites clear"
assert_grep 'wiki/log.md' "$FIN" "finalize-29-appends-wiki-log-md knowledge-finalize: appends to wiki/log.md"
assert_grep 'control-path.py" log' "$FIN" "finalize-30-resolves-log-path-control knowledge-finalize: resolves the log path via control-path.py (no hardcoded wiki/log.md write target)"
# #291: Step 9.5 best-effort sweeps the merged-away verify-shards/ fan-out scratch
# after deposit. Anchors the housekeeping layer like Step 2's guard is anchored.
assert_grep 'verify-shards' "$FIN" "finalize-31-step-9-5-sweeps-verify knowledge-finalize: Step 9.5 sweeps verify-shards/ after deposit (#291)"
# Match the actual log-line shape `## [DATE] finalize | project=...`.
assert_grep '\] finalize | project=' "$FIN" "finalize-32-emits-date-finalize-project knowledge-finalize: emits the '## [DATE] finalize | project=...' log-line shape"
assert_grep 'slugify' "$FIN" "finalize-33-reuses-knowledge-lib-slugify knowledge-finalize: reuses _knowledge_lib.slugify for default slug"
assert_grep 'atomic_write_text' "$FIN" "finalize-34-writes-synthesis-page-knowledge knowledge-finalize: writes synthesis page via _knowledge_lib.atomic_write_text"
# #389: the synthesis-page frontmatter title MUST be quoted via json.dumps (the same
# serializer source-ingester + concept-store use) so a colon-containing topic deposits
# valid YAML — an unquoted "title: X: Y" parses as a nested mapping and breaks
# Obsidian / yaml.safe_load / yq (masked by cogni-wiki's lenient first-colon parser).
assert_grep 'title: " + json.dumps(topic' "$FINREF" "finalize-35-synthesis-title-quoted-json knowledge-finalize: synthesis title quoted via json.dumps (#389 — valid YAML on colon-containing topics)"
# Cycle-guard adapter signal — the skill notes citation-manifest as the expected input_shape.
assert_grep 'citation-manifest' "$FIN" "finalize-36-notes-citation-manifest-cycle knowledge-finalize: notes citation-manifest as cycle-guard's input_shape"
# Defence-in-depth: no Skill() dispatches to cogni-research / cogni-workspace:claim / cogni-wiki.
assert_not_grep 'Skill("cogni-research:' "$FIN" "finalize-37-no-skill-cogni-research knowledge-finalize: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-workspace:claim' "$FIN" "finalize-38-no-skill-cogni-workspace knowledge-finalize: no Skill('cogni-workspace:claim') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$FIN" "finalize-39-no-skill-cogni-wiki knowledge-finalize: no Skill('cogni-wiki:') dispatch (M6 contract: call helpers at script level)"
# Positive control, per tests/README.md: the absence assertions above also pass on a
# gutted file, so pair them with the mechanism that replaced the dispatch.
assert_grep 'pre_extracted_claims:' "$FIN" "finalize-40-claims-engine-replacement-present knowledge-finalize: claims-engine replacement present — the contradiction pass reads on-disk pre_extracted_claims: frontmatter (zero-network)"
# Post-review hardening (v0.0.24, all 15 review findings).
# E1: wiki:// shape must be bare slug, not path-prefixed (cogni-wiki health.py:206).
assert_grep 'wiki://" + slug' "$FINREF" "finalize-41-emits-bare-wiki-slug knowledge-finalize: emits bare 'wiki://<slug>' (not 'wiki://<wiki_slug>/<slug>') per cogni-wiki contract"
assert_not_grep 'wiki://" + wiki_slug + "/"' "$FIN" "finalize-42-does-not-emit-composite knowledge-finalize: does NOT emit composite 'wiki://<wiki_slug>/<slug>' (would trip broken_wiki_source)"
# E2: synthesis-page citations must be resolved under wiki/syntheses/ as fallback.
assert_grep 'syntheses' "$FIN" "finalize-43-resolves-synthesis-page-citations knowledge-finalize: resolves synthesis-page citations under wiki/syntheses/"
assert_grep 'page_kind' "$FIN" "finalize-44-tracks-page-kind-source knowledge-finalize: tracks page kind (source vs synthesis) for wikilink emission"
# E3: must strip the composer's trailing ## References section before re-appending its own.
assert_grep 'References' "$FIN" "finalize-45-strips-composer-s-trailing knowledge-finalize: strips composer's trailing '## References' to avoid double sections"
# Slice 13 (#301/#300): the reference section is language-aware — read
# output_language, derive the heading from _knowledge_lib.ref_heading, and run
# the language-independent strip + inline renumber via the unit-tested
# _knowledge_lib helpers (the strip/renumber/URL logic was extracted out of the
# heredoc so it is executable-tested in test_knowledge_lib.sh, not just grepped).
assert_grep 'output_language' "$FIN" "finalize-46-reads-plan-json-output knowledge-finalize: reads plan.json::output_language for the reference heading (#301)"
assert_grep 'ref_heading' "$FIN" "finalize-47-derives-localized-reference-heading knowledge-finalize: derives the localized reference heading via _knowledge_lib.ref_heading (#301)"
assert_grep 'strip_reference_section' "$FINREF" "finalize-48-strips-composer-s-reference knowledge-finalize: strips the composer's reference section via _knowledge_lib.strip_reference_section (language-independent; #301)"
assert_grep 'renumber_inline_citations' "$FINREF" "finalize-49-renumbers-inline-n-markers knowledge-finalize: renumbers inline [N] markers via _knowledge_lib.renumber_inline_citations (#300)"
assert_grep 'md_link_dest' "$FINREF" "finalize-50-angle-brackets-paren-bearing knowledge-finalize: angle-brackets paren-bearing citation URLs via _knowledge_lib.md_link_dest (#300)"
# A4/D7: UTC date so frontmatter created/updated align with Step 10's `date -u`.
assert_grep 'timezone.utc' "$FINREF" "finalize-51-stamps-created-updated-utc knowledge-finalize: stamps created/updated in UTC (not local time)"
# A7 / B6: Step 8 entries_count bump is gated.
assert_grep 'INDEX_OK' "$FIN" "finalize-52-step-8-gated-7 knowledge-finalize: Step 8 gated on Step 7 success (INDEX_OK)"
assert_grep 'SYNTHESIS_EXISTED_PRE' "$FIN" "finalize-53-tracks-pre-existence-step knowledge-finalize: tracks pre-existence so Step 8 skips on --overwrite re-deposit"
# B7: --overwrite re-deposit passes --allow-update to knowledge-binding.py.
assert_grep 'allow-update' "$FIN" "finalize-54-passes-allow-update-overwrite knowledge-finalize: passes --allow-update on overwrite to refresh binding's report_path"
# A3/D8: log line uses printf, not echo, and sanitizes TOPIC newlines.
assert_grep "printf '## " "$FIN" "finalize-55-log-line-uses-printf knowledge-finalize: log line uses printf (not echo) to avoid CR/LF + escape-interp drift"
assert_grep "tr '" "$FIN" "finalize-56-sanitizes-topic-cr-lf knowledge-finalize: sanitizes TOPIC CR/LF before logging to preserve one-line-per-event invariant"
# A4 follow-on: cycle-guard's new manifest_unreadable status is documented in the SKILL.
assert_grep 'manifest_unreadable' "$FIN" "finalize-57-documents-how-handle-cycle knowledge-finalize: documents how to handle cycle-guard's new status=manifest_unreadable"
# CITATION_COUNT must actually be computed (E6 was a contract-gap finding).
assert_grep 'CITATION_COUNT=<count>' "$FIN" "finalize-58-dry-run-printout-actually knowledge-finalize: dry-run printout actually computes CITATION_COUNT"
# Task dispatch is REQUIRED as of v0.1.15 — Step 10.6 dispatches the
# wiki-contradictor agent (#335). The pre-v0.1.15 "no Task" assertion
# was tied to M9's no-agents posture, which is no longer the contract.
FIN_TOOLS_LINE=$(grep '^allowed-tools:' "$FIN" || true)
# AskUserQuestion is required since v0.1.79 (#516): the human-direct interactive
# apply-portal confirm in Step 10.5 sub-step 3.5. It is NOT a network/mutation
# tool, so it does not trip the closed-set guard below.
for _p in read:'Read' write:'Write' bash:'Bash' task:'Task' askuserquestion:'AskUserQuestion'; do
  _cid="${_p%%:*}"; required="${_p#*:}"
  if echo "$FIN_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: finalize-59-allowed-tools-includes-${_cid} knowledge-finalize: allowed-tools includes $required"
  else
    red "FAIL: finalize-59-allowed-tools-includes-${_cid} knowledge-finalize: allowed-tools missing $required"
    red "  got: $FIN_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
# Closed-set guard: the pre-v0.1.15 'no Task' block also transitively forbade
# network-shaped tools from sneaking in. Re-establish that floor explicitly so
# a future PR that adds WebFetch / WebSearch / Edit to allowed-tools fails
# loudly (Step 10.6 dispatches a zero-network agent; finalize itself must
# stay zero-network and zero-mutation-outside-the-Python-heredoc).
for _p in webfetch:'WebFetch' websearch:'WebSearch' edit:'Edit' notebookedit:'NotebookEdit'; do
  _cid="${_p%%:*}"; forbidden="${_p#*:}"
  if echo "$FIN_TOOLS_LINE" | grep -q "$forbidden"; then
    red "FAIL: finalize-60-allowed-tools-omits-zero-${_cid} knowledge-finalize: allowed-tools must NOT include $forbidden (zero-network / no-mutation contract beyond the existing Bash heredoc surface)"
    red "  got: $FIN_TOOLS_LINE"
    errors=$((errors + 1))
  else
    green "PASS: finalize-60-allowed-tools-omits-zero-${_cid} knowledge-finalize: allowed-tools omits $forbidden (zero-network contract)"
  fi
done

# --- Slice 16 (#308/#307/#306): wiki conformance -------------------------
# Reference backlinks must be BARE [[<slug>]] so the synthesis->source edge
# registers in cogni-wiki's link graph (WIKILINK_RE matches no slash). The old
# path-prefixed construction (link_dir + "/" + slug) must be gone from the code.
assert_grep 'backlink = ("\[\[" + slug + "\]\]")' "$FINREF" "finalize-61-emits-bare-slug-reference knowledge-finalize: emits a bare [[<slug>]] reference backlink (#308 orphan linchpin)"
assert_not_grep 'link_dir + "/" + slug' "$FIN" "finalize-62-no-path-prefixed-sources knowledge-finalize: no path-prefixed [[sources/<slug>]] construction remains (#308)"
assert_not_grep 'link_dir = "syntheses"' "$FIN" "finalize-63-dropped-link-dir-prefix knowledge-finalize: dropped the link_dir prefix branch (#308)"
# R1: a missing cited page (page_kind None) emits NO wikilink so it can't trip
# health.py broken_wikilink in the new gate.
assert_grep 'page_kind is not None' "$FINREF" "finalize-64-backlink-emitted-only-when knowledge-finalize: backlink emitted only when the cited page exists (#308 R1 — avoid broken_wikilink)"
# Step 10.5 conformance gate: lint --fix=all then health.py asserting 0 errors.
assert_grep 'resolve_wiki_scripts wiki-lint' "$FIN" "finalize-65-resolves-wiki-lint-scripts knowledge-finalize: resolves the wiki-lint scripts dir for the gate"
assert_grep 'resolve_wiki_scripts wiki-health' "$FIN" "finalize-66-resolves-wiki-health-scripts knowledge-finalize: resolves the wiki-health scripts dir for the gate"
assert_grep 'lint_wiki.py' "$FIN" "finalize-67-step-10-5-runs-lint knowledge-finalize: Step 10.5 runs lint_wiki.py"
assert_grep '\-\-fix=all' "$FIN" "finalize-68-step-10-5-lint-runs knowledge-finalize: Step 10.5 lint runs --fix=all (backfills reverse_link_missing)"
assert_grep 'health.py' "$FIN" "finalize-69-step-10-5-runs-health knowledge-finalize: Step 10.5 runs health.py"
assert_grep 'data.errors' "$FIN" "finalize-70-step-10-5-asserts-health knowledge-finalize: Step 10.5 asserts health data.errors == []"
# The gate must also assert 0 orphan_page (the slice's actual metric — health.py
# does NOT compute orphans), via a no-fix re-lint after --fix=all.
assert_grep 'orphan_page' "$FIN" "finalize-71-step-10-5-asserts-0 knowledge-finalize: Step 10.5 asserts 0 orphan_page (re-lint after --fix; the slice's metric)"
assert_grep 'no .*--fix' "$FIN" "finalize-72-step-10-5-re-lints knowledge-finalize: Step 10.5 re-lints with NO --fix to read post-fix orphan state"
assert_grep 'reverse_link_missing' "$FIN" "finalize-73-documents-reverse-link-missing knowledge-finalize: documents reverse_link_missing as the load-bearing de-orphaner"
# overview.md refresh (#308 stale-overview item).
assert_grep 'overview.md' "$FIN" "finalize-74-refreshes-wiki-overview-md knowledge-finalize: refreshes wiki/overview.md (#308)"
assert_grep 'Recent syntheses' "$FIN" "finalize-75-overview-md-gets-recent knowledge-finalize: overview.md gets a Recent syntheses bullet"
# Default synthesis tags (#308 empty-tags item).
assert_grep 'tags: \[synthesis\]' "$FIN" "finalize-76-synthesis-frontmatter-defaults-tags knowledge-finalize: synthesis frontmatter defaults tags: [synthesis] (#308)"
# Defence-in-depth: the synthesis index category stays Syntheses (confirmed scope).
assert_grep 'category "Syntheses"' "$FIN" "finalize-77-synthesis-filed-syntheses-category knowledge-finalize: synthesis still filed under the Syntheses category"

# --- #335 contradiction tripwire (Step 10.6, v0.1.15) --------------------
# Pure observability tripwire — fail-soft, never blocks finalize. Partially
# defends differentiation-thesis.md Pillar 2 at synthesis-write time.
# Step 10.6 lands after Step 10.5 sub-step 4 (rebuild_context_brief.py),
# before Step 11.
assert_grep '### 10.6 Contradiction tripwire' "$FIN" "finalize-78-step-10-6-heading-present knowledge-finalize: Step 10.6 heading present (#335)"
assert_grep 'wiki-contradictor' "$FIN" "finalize-79-step-10-6-dispatches-wiki knowledge-finalize: Step 10.6 dispatches wiki-contradictor agent (#335)"
# Anchor the literal dispatch syntax, not just a prose mention. The bare
# `wiki-contradictor` token also appears in the SKILL's description/Output/
# References blocks, so a maintainer could strip the actual Task(...) call
# while keeping the prose and the test would still pass without this anchor.
assert_grep 'Task(wiki-contradictor' "$FIN" "finalize-80-step-10-6-contains-literal knowledge-finalize: Step 10.6 contains the literal Task(wiki-contradictor ...) dispatch (#335)"
assert_grep 'contradictor-v' "$FIN" "finalize-81-step-10-6-writes-contradictor knowledge-finalize: Step 10.6 writes contradictor-v<N>.json output artifact (#335)"
assert_grep '\-\-no-contradictor' "$FIN" "finalize-82-no-contradictor-opt-out knowledge-finalize: --no-contradictor opt-out flag documented in Parameters table (#335, R1)"
assert_grep '### 10.6 Contradiction tripwire' "$FIN" "finalize-83-step-10-6-contradiction-tripwire knowledge-finalize: Step 10.6 contradiction tripwire heading present"
# Fail-soft framing — must be explicit so a future maintainer doesn't
# tighten Step 10.6 into a blocking gate.
assert_grep 'observability-only\|non-fatal\|never rolls back\|never blocks' "$FIN" "finalize-84-step-10-6-documented-fail knowledge-finalize: Step 10.6 documented as fail-soft / observability-only (#335)"
# Skip conditions — the --no-contradictor + both-empty skip paths must be
# documented. #444 widened skip-condition 3: the agent is now skipped only when
# BOTH the cited list AND the prior-synthesis list are empty (a 2nd+ synthesis
# with no claim-bearing cited peers still runs Pass B), so the empty-manifest
# message became the both-empty message.
assert_grep 'Contradiction tripwire skipped: --no-contradictor' "$FIN" "finalize-85-step-10-6-documents-no knowledge-finalize: Step 10.6 documents --no-contradictor skip path (#335)"
assert_grep 'Contradiction tripwire skipped: no claim-bearing cited peers and no prior syntheses' "$FIN" "finalize-86-step-10-6-documents-both knowledge-finalize: Step 10.6 documents the both-empty skip path (#444)"
# Step 11 surfaces the tripwire line — must mention the prefix so the
# operator-visible warning shape is anchored.
assert_grep 'Contradiction tripwire: ' "$FIN" "finalize-87-knowledge-finalize-step-11-final-summary-surfaces-contradiction knowledge-finalize: Step 11 final summary surfaces Contradiction tripwire line (#335)"
# Anchor the cost-line surface. It is the operator's feedback loop for the
# v0.1.16 --contradictor opt-in flip ('if sustained > $0.05/run across real
# bases...'). Losing it silently to a future SKILL edit would defeat the
# gating decision the CHANGELOG promises.
assert_grep 'Cost: \$' "$FIN" "finalize-88-step-11-surfaces-tripwire knowledge-finalize: Step 11 surfaces tripwire Cost line (#335, sustained-cost gating)"
# Step 5/6 subprocess must emit cited_source_slugs — the orchestrator
# reuses page_kind_by_slug from there rather than re-resolving pages.
assert_grep 'cited_source_slugs' "$FIN" "finalize-89-step-5-6-subprocess knowledge-finalize: Step 5/6 subprocess emits cited_source_slugs for Step 10.6 (#335)"
# #363 filter-regression guard: the Step 5/6 filter that selects which cited
# slugs flow to the contradictor MUST include the distilled kinds (concept/entity), not
# just "source" — otherwise distilled-cited slugs never reach the agent and
# the #363 extension ships a no-op (R1). Reverting the filter to source-only
# trips this assertion.
assert_grep '"concept", "entity"' "$FINREF" "finalize-90-step-5-6-filter knowledge-finalize: Step 5/6 filter includes distilled kinds for the contradictor (#363, R1 no-op guard)"
# …AND the comprehension that builds cited_source_slugs must actually apply
# that widened set (membership test, not == "source"). This catches a revert
# of ONLY the comprehension line while the set definition lingers.
assert_grep 'cited_source_slugs = \[s for s in cited_slugs if page_kind_by_slug.get(s) in _CLAIM_BEARING_KINDS\]' "$FINREF" "finalize-91-cited-source-slugs-filter knowledge-finalize: cited_source_slugs filter uses the widened claim-bearing set (#363, R1 no-op guard)"
assert_not_grep 'page_kind_by_slug.get(s) == "source"' "$FIN" "finalize-92-contradictor-filter-not-reverted knowledge-finalize: contradictor filter is NOT reverted to source-only (#363, R1 no-op guard)"
# #432: the 4th evidence family — the page-kind resolution loop must resolve
# wiki/questions/ and _CLAIM_BEARING_KINDS must include "question" so a (Slice-2)
# question-node citation gets a reference row + flows to the contradictor. Inert
# in Slice 1 (composer cites none yet) but the recognition must be wired.
assert_grep '("question", "questions")' "$FINREF" "finalize-93-knowledge-finalize-page-kind-loop-resolves-wiki-questions knowledge-finalize: page-kind loop resolves wiki/questions/ (4th evidence family, #432)"
assert_grep '"source", "interview", "concept", "entity", "question"' "$FINREF" "finalize-94-claim-bearing-kinds-includes knowledge-finalize: _CLAIM_BEARING_KINDS includes question (#432) and interview (interview read-side first-class)"
# Interview pages are source-class on the finalize read side: the page-kind loop
# resolves wiki/interviews/, _CLAIM_BEARING_KINDS includes "interview" (so a cited
# interview reaches the contradictor + gets a reference row), and the URL-reading
# branch fires for interview as well as source (interview pages carry sources:).
assert_grep '("interview", "interviews")' "$FINREF" "finalize-95-knowledge-finalize-page-kind-loop-resolves-wiki-interviews knowledge-finalize: page-kind loop resolves wiki/interviews/ (interview read-side first-class)"
assert_grep 'page_kind in ("source", "interview")' "$FINREF" "finalize-96-url-reading-branch-fires knowledge-finalize: URL-reading branch fires for interview as well as source (interview read-side first-class)"
assert_not_grep 'page_kind == "source":' "$FINREF" "finalize-97-url-reading-branch-not knowledge-finalize: URL-reading branch is NOT reverted to source-only (interview read-side first-class)"
# Pillar 2 framing — the SKILL must be honest about partial defense.
assert_grep 'Partially defends.*Pillar 2\|partially defend' "$FIN" "finalize-98-step-10-6-honest-about knowledge-finalize: Step 10.6 honest about partial Pillar 2 defense (#335)"
# References block must include the new agent.
assert_grep 'agents/wiki-contradictor.md' "$FIN" "finalize-99-knowledge-finalize-references-block-points-agents-wiki-contradictor knowledge-finalize: References block points at agents/wiki-contradictor.md (#335)"

# --- #444 synthesis-vs-prior-syntheses (approach (c)) --------------------
# Step 10.6 now runs TWO comparison passes off one dispatch: Pass A
# (synthesis-vs-cited, existing) + Pass B (synthesis-vs-prior-syntheses, new).
# The orchestrator enumerates prior synthesis slugs, threads PRIOR_SYNTHESIS_SLUGS
# into the single Task(wiki-contradictor ...) call, and splits the Step 11 line.
# New finer opt-out --no-prior-syntheses suppresses Pass B while Pass A runs.
assert_grep '\-\-no-prior-syntheses' "$FIN" "finalize-100-no-prior-syntheses-opt knowledge-finalize: --no-prior-syntheses opt-out flag documented in Parameters table (#444)"
# The single dispatch threads the new input (anchor the literal param so a
# maintainer can't drop the threading while keeping the prose).
assert_grep 'PRIOR_SYNTHESIS_SLUGS=' "$FIN" "finalize-101-step-10-6-threads-prior knowledge-finalize: Step 10.6 threads PRIOR_SYNTHESIS_SLUGS into the Task(wiki-contradictor ...) dispatch (#444)"
# Prior-synthesis enumeration: glob wiki/syntheses, exclude self, cap at 20.
assert_grep 'PRIOR_SYNTHESIS_MAX=20' "$FIN" "finalize-102-step-10-6-caps-prior knowledge-finalize: Step 10.6 caps the prior-synthesis enumeration at PRIOR_SYNTHESIS_MAX=20 (#444)"
assert_grep 'wiki.*syntheses.*glob\|syn_dir.*glob\|glob("\*.md")' "$FIN" "finalize-103-step-10-6-globs-wiki knowledge-finalize: Step 10.6 globs wiki/syntheses for prior pages (#444)"
assert_grep 'p.stem == self_slug\|exclude.*just-deposited\|excludes the just-deposited' "$FIN" "finalize-104-step-10-6-excludes-just knowledge-finalize: Step 10.6 excludes the just-deposited synthesis from the prior-synthesis enumeration (#444)"
assert_grep 'PRIOR_SYNTHESIS_SLUGS_CSV' "$FIN" "finalize-105-step-10-6-builds-prior knowledge-finalize: Step 10.6 builds PRIOR_SYNTHESIS_SLUGS_CSV (#444)"
# Widened skip-condition 3: skip only when BOTH lists are empty (the agent runs
# Pass B alone when cited is empty but prior is not).
assert_grep 'BOTH.*cited.*AND\|cited_source_slugs) == 0.*AND\|AND.*prior_synthesis_slugs' "$FIN" "finalize-106-step-10-6-skips-only knowledge-finalize: Step 10.6 skips only when BOTH cited and prior lists are empty (#444)"
# Step 11 header splits into the two families.
assert_grep 'vs prior syntheses' "$FIN" "finalize-107-step-11-contradiction-line knowledge-finalize: Step 11 contradiction line splits cited vs prior syntheses (#444)"
assert_grep 'prior-synthesis comparison truncated at 20' "$FIN" "finalize-108-step-11-surfaces-prior knowledge-finalize: Step 11 surfaces the prior-synthesis truncation line (#444)"
# The cited-vs-prior partition is read off conflicting_page membership in
# compared_against.prior_syntheses[] (the robust discriminator — a Pass A
# unknown can carry a null conflicting_claim_id, so null-ness alone would
# misroute it; the cited/prior slug sets are disjoint by page kind).
assert_grep 'conflicting_page ∈ compared_against.prior_syntheses\|conflicting_page.*membership\|in `compared_against.prior_syntheses' "$FIN" "finalize-109-step-10-6-partitions-findings knowledge-finalize: Step 10.6 partitions findings by conflicting_page membership in prior_syntheses[] for the Step 11 split (#444)"

# --- #309 P1.1 structural reviewer (Step 10.7, v0.1.28) ------------------
# Advisory structural-quality tripwire — fail-soft, never blocks finalize.
# The structural-quality half of the cogni-research feature-parity gate;
# Phase 6 owns citation-claim alignment, this owns structural quality.
# Step 10.7 lands after Step 10.6 (contradiction tripwire), before Step 11.
assert_grep '### 10.7 Structural-quality review' "$FIN" "finalize-110-step-10-7-heading-present knowledge-finalize: Step 10.7 heading present (#309 P1.1)"
assert_grep 'wiki-reviewer' "$FIN" "finalize-111-step-10-7-dispatches-wiki knowledge-finalize: Step 10.7 dispatches wiki-reviewer agent (#309 P1.1)"
# Anchor the literal dispatch, not just a prose mention (the bare token also
# appears in description/Output/References blocks).
assert_grep 'Task(wiki-reviewer' "$FIN" "finalize-112-step-10-7-contains-literal knowledge-finalize: Step 10.7 contains the literal Task(wiki-reviewer ...) dispatch (#309 P1.1)"
assert_grep 'structural-review-v' "$FIN" "finalize-113-step-10-7-writes-structural knowledge-finalize: Step 10.7 writes structural-review-v<N>.json output artifact (#309 P1.1)"
assert_grep '\-\-no-reviewer' "$FIN" "finalize-114-no-reviewer-opt-out knowledge-finalize: --no-reviewer opt-out flag documented in Parameters table (#309 P1.1)"
assert_grep 'structural-quality half of the cogni-research feature-parity' "$FIN" "finalize-115-step-10-7-framed-structural knowledge-finalize: Step 10.7 framed as the structural-quality feature-parity half"
# Fail-soft / advisory framing — must be explicit so a future maintainer
# doesn't tighten Step 10.7 into a blocking gate.
assert_grep 'advisory\|Advisory\|never rolls back\|never blocks' "$FIN" "finalize-116-step-10-7-documented-advisory knowledge-finalize: Step 10.7 documented as advisory / fail-soft (#309 P1.1)"
# Skip condition — the --no-reviewer skip path must be documented.
assert_grep 'Structural review skipped: --no-reviewer' "$FIN" "finalize-117-step-10-7-documents-no knowledge-finalize: Step 10.7 documents --no-reviewer skip path (#309 P1.1)"
# Step 11 surfaces the structural-review line (operator-visible warning shape).
assert_grep 'Structural review: score=' "$FIN" "finalize-118-knowledge-finalize-step-11-final-summary-surfaces-structural knowledge-finalize: Step 11 final summary surfaces Structural review line (#309 P1.1)"
# References block must include the new agent.
assert_grep 'agents/wiki-reviewer.md' "$FIN" "finalize-119-knowledge-finalize-references-block-points-agents-wiki-reviewer knowledge-finalize: References block points at agents/wiki-reviewer.md (#309 P1.1)"

# --- #309 P2 writer-quality knobs ----------------------------------------
# Step 10.7 threads TARGET_WORDS + PROSE_DENSITY into the wiki-reviewer dispatch
# so its advisory Word Count Gate has a floor/ceiling reference. The reviewer
# structural-review schema is now 0.1.1 (additive word_count block).
assert_grep 'TARGET_WORDS=' "$FIN" "finalize-120-step-10-7-threads-target knowledge-finalize: Step 10.7 threads TARGET_WORDS into the wiki-reviewer dispatch (#309 P2)"
assert_grep 'PROSE_DENSITY=' "$FIN" "finalize-121-step-10-7-threads-prose knowledge-finalize: Step 10.7 threads PROSE_DENSITY into the wiki-reviewer dispatch (#309 P2)"
assert_grep 'structural-review-v<N>.json` (schema `0.1.1`)\|structural-review.*schema.*0.1.1' "$FIN" "finalize-122-structural-review-schema-bumped knowledge-finalize: structural-review schema bumped to 0.1.1 (#309 P2 word_count)"
# Step 5/6 reference-row builder branches the bibliography string on
# plan.json::citation_format — chicago renders end-to-end alongside ieee.
assert_grep 'citation_format' "$FIN" "finalize-123-step-5-6-reads knowledge-finalize: Step 5/6 reads plan.json::citation_format (#309 P2.2)"
assert_grep 'citation_format == "chicago"' "$FINREF" "finalize-124-step-5-6-branches knowledge-finalize: Step 5/6 branches the reference string on chicago (#309 P2.2)"
# Author-date (apa/mla/harvard) is wired. The case id and the grep pattern are
# byte-unchanged — only this label's trailing prose moved, because its premise
# ("the named follow-up, NOT wired this round") flipped false when the family
# shipped. The pattern still asserts the same thing it always did: that the
# SKILL body documents the author-date family at all.
assert_grep 'author-date' "$FIN" "finalize-125-documents-author-date-apa knowledge-finalize: documents author-date apa/mla/harvard as a rendered citation family (#309 P2.2)"

# --- #338 open-questions refresh (Step 10.5 sub-step 5, v0.1.19) ----------
# Fail-soft refresh of the persistent data-gap backlog the inverted pipeline
# leaves stale. Same posture as cogni-wiki wiki-lint Step 8.5: never rolls
# back the synthesis; surfaces a loud failure line on error.
assert_grep '5\. \*\*Refresh `wiki/open_questions.md`' "$FIN" "finalize-126-knowledge-finalize-step-10-5-sub-5-heading-present knowledge-finalize: Step 10.5 sub-step 5 heading present"
assert_grep 'rebuild_open_questions.py' "$FIN" "finalize-127-knowledge-finalize-step-10-5-sub-5-invokes-rebuild knowledge-finalize: Step 10.5 sub-step 5 invokes rebuild_open_questions.py (#338)"
# The script dir is already resolved at Pre-flight for the Step 10.5 gate —
# anchor that sub-step 5 reuses $WIKI_LINT_SCRIPTS rather than re-resolving.
assert_grep 'WIKI_LINT_SCRIPTS/rebuild_open_questions.py' "$FIN" "finalize-128-knowledge-finalize-step-10-5-sub-5-resolves-rebuild knowledge-finalize: Step 10.5 sub-step 5 resolves rebuild_open_questions.py via \$WIKI_LINT_SCRIPTS (already wired #338)"
assert_grep '\-\-no-open-questions' "$FIN" "finalize-129-no-open-questions-opt knowledge-finalize: --no-open-questions opt-out documented in Parameters table (#338)"
assert_grep 'Open questions rebuild skipped: --no-open-questions' "$FIN" "finalize-130-knowledge-finalize-step-10-5-sub-5-documents-no knowledge-finalize: Step 10.5 sub-step 5 documents --no-open-questions skip path (#338)"
# dry-run skip must be documented on the same line as the sub-step 5 anchor
# so a future edit can't silently drop the defence-in-depth guard.
assert_grep 'dry-run.*sub-step 5\|sub-step 5.*dry-run' "$FIN" "finalize-131-knowledge-finalize-step-10-5-sub-5-skips-dry knowledge-finalize: Step 10.5 sub-step 5 skips on --dry-run (#338)"
assert_grep 'Open questions: opened=' "$FIN" "finalize-132-step-11-surfaces-opened knowledge-finalize: Step 11 surfaces opened/closed/trimmed deltas on success (#338)"
assert_grep 'open_questions rebuild FAILED' "$FIN" "finalize-133-step-11-surfaces-loud knowledge-finalize: Step 11 surfaces loud failure line on rebuild error (#338)"
# Fail-soft framing — must be explicit so a future maintainer doesn't tighten
# sub-step 5 into a blocking gate.
assert_grep 'never rolls back the synthesis' "$FIN" "finalize-134-knowledge-finalize-step-10-5-sub-5-documented-fail knowledge-finalize: Step 10.5 sub-step 5 documented as fail-soft (#338)"
# Defence-in-depth: sub-step 5 must NOT add a second wiki/log.md line — the
# existing Step 10 finalize line is the close-attribution surface; a second
# line would double-count finalize ops. Catch any shell-write idiom (printf /
# echo / cat / tee / >>) that pipes an open_questions op into log.md, in either
# token order — broader than the original printf-only pattern. ERE (the helper
# uses grep -nE). Coupling to BOTH tokens + a write verb keeps the
# close-attribution PROSE line (which legitimately names rebuild_open_questions.py
# and wiki/log.md together, but with no write verb) from false-positiving.
assert_not_grep '(printf|echo|cat|tee|>>).*open[_-]questions.*log\.md|(printf|echo|cat|tee|>>).*log\.md.*open[_-]questions' "$FIN" "finalize-135-sub-step-5-does knowledge-finalize: sub-step 5 does NOT write a second wiki/log.md line (#338)"
# Edge-case section anchor: re-finalize idempotency for the open-questions RMW.
assert_grep 'open-questions idempotency' "$FIN" "finalize-136-edge-case-section-documents knowledge-finalize: edge-case section documents re-finalize idempotency for the open-questions RMW"

# --- #354 research-time gap streaming ------------------------------------
# Step 10 finalize log line carries the conditional sqs= suffix.
assert_grep 'sqs=%s' "$FIN" "finalize-137-step-10-finalize-log knowledge-finalize: Step 10 finalize log line carries an sqs= suffix (#354)"
assert_grep 'gap_sq_ids_from_coverage' "$FIN" "finalize-138-step-10-builds-sqs knowledge-finalize: Step 10 builds sqs= from gap_sq_ids_from_coverage (#354)"
# Step 10.5 sub-step 5 pipes the merged payload via the build helper + --findings -.
assert_grep 'build_open_questions_payload.py' "$FIN" "finalize-139-knowledge-finalize-step-10-5-sub-5-invokes-build knowledge-finalize: Step 10.5 sub-step 5 invokes build_open_questions_payload.py (#354)"
assert_grep '\-\-findings  *-' "$FIN" "finalize-140-knowledge-finalize-step-10-5-sub-5-pipes-merged knowledge-finalize: Step 10.5 sub-step 5 pipes the merged payload via --findings - (#354)"
# finalize is now a CLOSING_OPS op; the close-attribution prose reflects it.
assert_grep 'closed <date> by finalize' "$FIN" "finalize-141-documents-closed-finalize-credit knowledge-finalize: documents the closed ... by finalize credit-close (#354)"
# New opt-out flag.
assert_grep '\-\-no-research-gaps' "$FIN" "finalize-142-no-research-gaps-flag knowledge-finalize: --no-research-gaps flag documented (#354)"
# Step 11 split surface.
assert_grep 'lint=<L>, research=<R>' "$FIN" "finalize-143-step-11-surfaces-lint knowledge-finalize: Step 11 surfaces the lint/research open-questions split (#354)"

# --- #337 verification-honesty surfacing (frontmatter + Step 11) ---------
# Two additive synthesis-page frontmatter keys declare WHAT "verified" means;
# Step 11 + the dashboard + verify Step 6 all carry the same qualifier so a
# reader of any surface arrives at the same understanding.
assert_grep 'verification: citation_consistent_zero_network' "$FIN" "finalize-144-knowledge-finalize-step-5-frontmatter-emits-verification-citation knowledge-finalize: Step 5 frontmatter emits verification: citation_consistent_zero_network (#337)"
assert_grep 'verification_ratio:' "$FIN" "finalize-145-knowledge-finalize-step-5-frontmatter-emits-verification-ratio knowledge-finalize: Step 5 frontmatter emits verification_ratio: (#337)"
# The four verify-vN.json counts are threaded into the Step 5 compose subprocess.
assert_grep 'VERIFY_VERBATIM' "$FIN" "finalize-146-threads-verify-verbatim-step knowledge-finalize: threads VERIFY_VERBATIM into Step 5's compose subprocess (#337)"
assert_grep 'VERIFY_UNSUPPORTED' "$FIN" "finalize-147-threads-verify-unsupported-step knowledge-finalize: threads VERIFY_UNSUPPORTED into Step 5's compose subprocess (#337)"
# Step 11 final-summary qualifier lines.
assert_grep 'Verification: citation-consistent' "$FIN" "finalize-148-step-11-prints-citation knowledge-finalize: Step 11 prints the citation-consistent Verification line (#337)"
assert_grep 'zero-network' "$FIN" "finalize-149-step-11-names-zero knowledge-finalize: Step 11 names zero-network (no live-source re-check) (#337)"
assert_grep 'Verbatim/paraphrase ratio' "$FIN" "finalize-150-step-11-prints-verbatim knowledge-finalize: Step 11 prints the verbatim/paraphrase ratio line (#337)"
# Out of scope must point live-source re-verification at the opt-in resweep.
assert_grep 'knowledge-refresh --resweep' "$FIN" "finalize-151-out-scope-names-knowledge knowledge-finalize: Out of scope names knowledge-refresh --resweep as the live-source path (#337)"
# Output block must list the two additive frontmatter keys as deliverables.
assert_grep 'verification_ratio:' "$FIN" "finalize-152-output-block-lists-additive knowledge-finalize: Output block lists the additive verification frontmatter keys (#337)"

# --- #410 synthesis->question forward links ------------------------------
# New Step 4.7 reads the ingest-time question-manifest.json handoff, builds
# QUESTION_SLUGS_CSV, and the Step 5/6 subprocess appends a `## Research
# questions` body section of bare [[slug]] forward links (existence-gated). The
# reverse link is the existing Step 10.5 reverse_link_missing backfill (no new
# code). --no-question-links opts out.
assert_grep 'question-manifest.json' "$FIN" "finalize-153-step-4-7-reads-question knowledge-finalize: Step 4.7 reads the question-manifest.json handoff (#410)"
assert_grep 'QUESTION_SLUGS_CSV' "$FIN" "finalize-154-step-4-7-builds-threads knowledge-finalize: Step 4.7 builds + threads QUESTION_SLUGS_CSV (#410)"
assert_grep '## Research questions' "$FIN" "finalize-155-step-5-6-appends knowledge-finalize: Step 5/6 appends the ## Research questions body section (#410)"
assert_grep '\-\-no-question-links' "$FIN" "finalize-156-no-question-links-opt knowledge-finalize: --no-question-links opt-out documented (#410)"
assert_grep 'n_question_links' "$FIN" "finalize-157-subprocess-emits-n-question knowledge-finalize: subprocess emits n_question_links for the Step 11 summary (#410)"

# --- #491 curated-portal auto-refresh (Step 10.5 sub-step 3.5) -----------
# Option 4b: finalize (re)authors the engine-owned per-theme lead-ins +
# overview narrative, stage-by-default, apply on --apply-portal. Pure
# observability of the SKILL surface (the apply path is exercised end-to-end
# by test_portal_store.sh against the real cogni-wiki helper).
assert_grep 'sub-step 3.5' "$FIN" "finalize-158-step-10-5-sub-3-5 knowledge-finalize: Step 10.5 sub-step 3.5 present (#491)"
assert_grep 'Task(portal-narrator' "$FIN" "finalize-159-sub-step-3-5-dispatches knowledge-finalize: sub-step 3.5 dispatches the portal-narrator agent (#491)"
assert_grep 'portal-records.txt' "$FIN" "finalize-160-sub-step-3-5-writes knowledge-finalize: sub-step 3.5 writes portal-records.txt (#491)"
assert_grep '\-\-apply-portal' "$FIN" "finalize-161-apply-portal-flag-documented knowledge-finalize: --apply-portal flag documented (#491)"
assert_grep '\-\-refresh-portal' "$FIN" "finalize-162-refresh-portal-alias-documented knowledge-finalize: --refresh-portal alias documented (#491)"
assert_grep '\-\-no-portal' "$FIN" "finalize-163-no-portal-skip-flag knowledge-finalize: --no-portal skip flag documented (#491)"
# Stage-by-default is the load-bearing safety contract — must be explicit so a
# future edit can't silently flip finalize to apply-by-default.
assert_grep 'stages' "$FIN" "finalize-164-sub-step-3-5-stages knowledge-finalize: sub-step 3.5 stages the portal diff by default (#491)"
assert_grep 'portal-proposed.md' "$FIN" "finalize-165-stage-writes-cogni-wiki knowledge-finalize: STAGE writes .cogni-wiki/portal-proposed.md (#491)"
# The apply path goes through the cogni-wiki locked helper, never a hand-edit.
assert_grep '\-\-set-leadin' "$FIN" "finalize-166-apply-calls-wiki-index knowledge-finalize: APPLY calls wiki_index_update.py --set-leadin (#491)"
assert_grep '\-\-get-leadin' "$FIN" "finalize-167-sub-step-3-5-reads knowledge-finalize: sub-step 3.5 reads the bundle via --get-leadin (#491)"
# The ownership boundary + the two sentinel names must be named.
assert_grep 'MACHINE-OWNED:PORTAL-LEADIN' "$FIN" "finalize-168-names-portal-leadin-sentinel knowledge-finalize: names the PORTAL-LEADIN sentinel (#491)"
assert_grep 'MACHINE-OWNED:OVERVIEW-NARRATIVE' "$FIN" "finalize-169-names-overview-narrative-sentinel knowledge-finalize: names the OVERVIEW-NARRATIVE sentinel (#491)"

# --- #516 interactive apply-portal confirm (Step 10.5 sub-step 3.5 (d)) ---
# Human-direct finalize asks before applying the portal diff; the autonomous
# knowledge-refresh push loop passes --no-portal-prompt so it stages silently.
assert_grep '\-\-no-portal-prompt' "$FIN" "finalize-170-no-portal-prompt-suppressor knowledge-finalize: --no-portal-prompt suppressor flag documented (#516)"
assert_grep 'AskUserQuestion' "$FIN" "finalize-171-sub-step-3-5-d knowledge-finalize: sub-step 3.5 (d) offers an interactive apply-portal confirm (#516)"
assert_grep 'upsert_machine_block' "$FIN" "finalize-172-overview-splice-knowledge-lib knowledge-finalize: overview splice via _knowledge_lib.upsert_machine_block (#491)"
# Engine never writes a human (non-sentineled) lead-in — the safety promise.
assert_grep 'human (non-sentineled) lead-in is never touched\|never touched\|never converts' "$FIN" "finalize-173-sub-step-3-5-documents knowledge-finalize: sub-step 3.5 documents the human-lead-in protection (#491)"
# Fail-soft framing — must be explicit so a future maintainer doesn't make the
# portal refresh a blocking gate.
assert_grep 'never rolls back the synthesis' "$FIN" "finalize-174-sub-step-3-5-documented knowledge-finalize: sub-step 3.5 documented as fail-soft (#491)"
# References block + agents table must point at the new agent + design note.
assert_grep 'agents/portal-narrator.md' "$FIN" "finalize-175-knowledge-finalize-references-block-points-agents-portal-narrator knowledge-finalize: References block points at agents/portal-narrator.md (#491)"
assert_grep 'portal-shape-decision.md' "$FIN" "finalize-176-references-block-points-design knowledge-finalize: References block points at the design note (#491)"
# Step 11 surfaces the portal line (operator-visible shape).
assert_grep 'Portal: ' "$FIN" "finalize-177-step-11-surfaces-portal knowledge-finalize: Step 11 surfaces the Portal line (#491)"

# --- Inverted-pipeline.md Phase 7 anchor ---------------------------------
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 7 — `knowledge-finalize`' "$PIPELINE" "finalize-178-phase-7-section-header inverted-pipeline.md: Phase 7 section header anchored"
assert_grep 'wiki_index_update' "$PIPELINE" "finalize-179-inverted-pipeline-md-phase-7-names-wiki-index inverted-pipeline.md: Phase 7 names wiki_index_update.py as a helper call"
assert_grep 'config_bump' "$PIPELINE" "finalize-180-phase-7-names-config inverted-pipeline.md: Phase 7 names config_bump.py as a helper call"
assert_grep 'rebuild_context_brief' "$PIPELINE" "finalize-181-phase-7-names-rebuild inverted-pipeline.md: Phase 7 names rebuild_context_brief.py as a helper call"
# #335 contradiction tripwire — the reference contract must name the new
# artifact + agent so the doc stays load-bearing.
assert_grep 'wiki-contradictor' "$PIPELINE" "finalize-182-inverted-pipeline-md-phase-7-names-wiki-contradictor inverted-pipeline.md: Phase 7 names wiki-contradictor agent (#335)"
assert_grep 'contradictor-v' "$PIPELINE" "finalize-183-phase-7-names-contradictor inverted-pipeline.md: Phase 7 names contradictor-v<N>.json artifact (#335)"
assert_grep '#335' "$PIPELINE" "finalize-184-phase-7-references-issue inverted-pipeline.md: Phase 7 references issue #335"

# --- cycle-guard.py docstring documents the new fallback -----------------
CG="$PLUGIN_ROOT/scripts/cycle-guard.py"
assert_grep 'citation-manifest' "$CG" "finalize-185-docstring-documents-citation-manifest cycle-guard.py: docstring documents the citation-manifest fallback"
assert_grep 'input_shape' "$CG" "finalize-186-emits-input-shape-json cycle-guard.py: emits input_shape in JSON envelope"
assert_grep 'legacy-source-entities' "$CG" "finalize-187-input-shape-vocabulary-includes cycle-guard.py: input_shape vocabulary includes legacy-source-entities"
assert_grep 'CITATION_MANIFEST_RELPATH' "$CG" "finalize-188-defines-citation-manifest-relpath cycle-guard.py: defines CITATION_MANIFEST_RELPATH constant"
assert_grep 'ManifestUnreadableError' "$CG" "finalize-189-defines-manifestunreadableerror-no-silent cycle-guard.py: defines ManifestUnreadableError (no silent green on corrupt manifest)"
assert_grep 'manifest_unreadable' "$CG" "finalize-190-emits-status-manifest-unreadable cycle-guard.py: emits status=manifest_unreadable on corrupt citation manifest"
assert_grep 'input_shapes' "$CG" "finalize-191-tracks-hop-input-shapes cycle-guard.py: tracks per-hop input_shapes (mixed-shape transitive walks observable)"

# --- Inline cycle-guard fixture: v0.1.0 clear case -----------------------
# v0.1.0 project layout: .metadata/citation-manifest.json + .metadata/project-config.json
# (no 02-sources/data/). Candidate cites a page derived from another project;
# no cycle. cycle-guard.py must:
#   - exit 0
#   - status: clear
#   - input_shape: citation-manifest
#   - cross_lineage_overlap non-empty
WORK_CLEAR=$(mktemp -d)
trap 'rm -rf "$WORK_CLEAR" "${WORK_CYCLE:-}"' EXIT

KB="$WORK_CLEAR/kb"
PROJ="$WORK_CLEAR/proj"
mk_knowledge_base "$KB" test-wiki
mk_wiki_page "$KB" sources page-from-other other-project
mk_v01_project "$PROJ" project-v01
add_manifest_citation "$PROJ" page-from-other clm-001

set +e
OUT=$(python3 "$CG" \
  --knowledge-root "$KB" \
  --research-slug project-v01 \
  --research-project-path "$PROJ" \
  --report-source wiki 2>&1)
RC=$?
set -e

if [ $RC -ne 0 ]; then
  red "FAIL: finalize-192-v0-1-0-clear-case-expected v0.1.0 clear case — expected exit 0, got $RC"
  red "  output: $OUT"
  errors=$((errors + 1))
else
  green "PASS: finalize-192-v0-1-0-clear-case-expected v0.1.0 clear case — exited 0 as expected"
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d['success'] is not True: sys.exit('expected success=true, got ' + repr(d))
data = d['data']
if data.get('status') != 'clear': sys.exit('expected status=clear, got ' + repr(data.get('status')))
if data.get('input_shape') != 'citation-manifest': sys.exit('expected input_shape=citation-manifest, got ' + repr(data.get('input_shape')))
if data.get('direct_self_cycles') != []: sys.exit('expected no direct cycles, got ' + repr(data.get('direct_self_cycles')))
if not data.get('cross_lineage_overlap'): sys.exit('cross_lineage_overlap empty')
if not isinstance(data.get('input_shapes'), list) or not data['input_shapes']: sys.exit('input_shapes missing or empty')
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: finalize-193-cycle-guard-v0-1-0-clear v0.1.0 clear case — output did not match clear contract"
  red "  got: $OUT"
  errors=$((errors + 1))
else
  green "PASS: finalize-193-cycle-guard-v0-1-0-clear cycle-guard v0.1.0 clear case — status=clear, input_shape=citation-manifest, input_shapes recorded"
fi

# --- Inline cycle-guard fixture: v0.1.0 self-cycle case ------------------
# Candidate's citation manifest points at a wiki page derived from the
# candidate itself (`derived_from_research: project-self`). cycle-guard.py must:
#   - exit 1
#   - status: cycle_detected
#   - input_shape: citation-manifest
#   - direct_self_cycles non-empty
WORK_CYCLE=$(mktemp -d)

KB2="$WORK_CYCLE/kb"
PROJ2="$WORK_CYCLE/proj"
mk_knowledge_base "$KB2" test-wiki
mk_wiki_page "$KB2" sources prior-self-deposit project-self
mk_v01_project "$PROJ2" project-self
add_manifest_citation "$PROJ2" prior-self-deposit clm-001

set +e
OUT2=$(python3 "$CG" \
  --knowledge-root "$KB2" \
  --research-slug project-self \
  --research-project-path "$PROJ2" \
  --report-source wiki 2>&1)
RC2=$?
set -e

if [ $RC2 -ne 1 ]; then
  red "FAIL: finalize-194-v0-1-0-self-cycle-case v0.1.0 self-cycle case — expected exit 1 (cycle_detected), got $RC2"
  red "  output: $OUT2"
  errors=$((errors + 1))
else
  green "PASS: finalize-194-v0-1-0-self-cycle-case v0.1.0 self-cycle case — exited 1 as expected"
fi

if ! echo "$OUT2" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d['success'] is not False: sys.exit('expected success=false on cycle')
data = d['data']
if data.get('status') != 'cycle_detected': sys.exit('expected status=cycle_detected, got ' + repr(data.get('status')))
if data.get('input_shape') != 'citation-manifest': sys.exit('expected input_shape=citation-manifest')
if not data.get('direct_self_cycles'): sys.exit('direct_self_cycles empty')
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: finalize-195-cycle-guard-v0-1-0-self v0.1.0 self-cycle case — output did not match cycle_detected contract"
  red "  got: $OUT2"
  errors=$((errors + 1))
else
  green "PASS: finalize-195-cycle-guard-v0-1-0-self cycle-guard v0.1.0 self-cycle case — exit 1 + status=cycle_detected"
fi

# --- Inline cycle-guard fixture: malformed citation-manifest case ---------
# v0.0.24 added a hard-fail on unparseable citation-manifest.json (previously
# silently returned status=clear with empty cited list — a green light for
# what cycle-guard exists to prevent). Confirm exit 1 + status=manifest_unreadable.
WORK_BAD=$(mktemp -d)
KB3="$WORK_BAD/kb"
PROJ3="$WORK_BAD/proj"
mk_knowledge_base "$KB3" test-wiki
mk_v01_project "$PROJ3" project-bad
# Replace the citation manifest with corrupt JSON.
printf '{ this is not JSON' > "$PROJ3/.metadata/citation-manifest.json"

set +e
OUT3=$(python3 "$CG" \
  --knowledge-root "$KB3" \
  --research-slug project-bad \
  --research-project-path "$PROJ3" \
  --report-source wiki 2>&1)
RC3=$?
set -e
rm -rf "$WORK_BAD"

if [ $RC3 -ne 1 ]; then
  red "FAIL: finalize-196-corrupt-manifest-case-expected corrupt-manifest case — expected exit 1, got $RC3"
  red "  output: $OUT3"
  errors=$((errors + 1))
else
  green "PASS: finalize-196-corrupt-manifest-case-expected corrupt-manifest case — exited 1 as expected"
fi

if ! echo "$OUT3" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d['success'] is not False: sys.exit('expected success=false on corrupt manifest')
data = d['data']
if data.get('status') != 'manifest_unreadable': sys.exit('expected status=manifest_unreadable, got ' + repr(data.get('status')))
if not d.get('error'): sys.exit('expected non-empty error field')
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: finalize-197-cycle-guard-corrupt-manifest corrupt-manifest case — output did not match manifest_unreadable contract"
  red "  got: $OUT3"
  errors=$((errors + 1))
else
  green "PASS: finalize-197-cycle-guard-corrupt-manifest cycle-guard corrupt-manifest case — exit 1 + status=manifest_unreadable (was silent green pre-v0.0.24)"
fi

# --- author-date reference assembly (apa/mla/harvard) ---------------------
# Code-shape assertions over $FINREF for the two structural moves, then a
# BEHAVIORAL case below that extracts and actually runs the subprocess. The
# greps alone could not tell a working branch from an unreachable one.
assert_grep 'family = citation_family(' "$FINREF" "finalize-198-family-dispatch knowledge-finalize: the citation family is resolved through _knowledge_lib.citation_family, not re-derived from the format"
assert_grep 'if family == "numbered":' "$FINREF" "finalize-199-renumber-family-guarded knowledge-finalize: the renumber pass is GUARDED by citation family (numbered runs it, author-date bypasses it) rather than removed"
assert_grep 'build_author_date_reference_list(author_date_entries)' "$FINREF" "finalize-200-author-date-list-assembly knowledge-finalize: the author-date reference list is assembled via _knowledge_lib.build_author_date_reference_list"
assert_grep 'author, year = resolve_author_year(text)' "$FINREF" "finalize-201-resolve-author-year knowledge-finalize: each entry's author/year resolve via _knowledge_lib.resolve_author_year (explicit keys, else the publisher:/fetched_at: surrogates)"
assert_grep 'author_date_reference_entry(' "$FINREF" "finalize-202-author-date-entry-builder knowledge-finalize: the per-format bibliography string comes from _knowledge_lib.author_date_reference_entry"

# Behavioral: extract the `python3 -c '...'` body out of $FINREF and RUN it over
# a three-page fixture, once per citation format. Each page carries a different
# resolution path, and all three are load-bearing:
#   zeta-page  explicit author: + published_date:
#   acme-page  NEITHER key — resolves through the publisher:/fetched_at:
#              surrogates, so the legacy no-migration path is asserted, not assumed
#   vorherige-synthese  a SYNTHESIS page: no author:, no publisher:, and neither
#              date key (finalize's own synthesis frontmatter carries only
#              created:/updated:, and concept-store/question-store write no date
#              key either) — so it renders author-less, URL-less and year-less.
#              That is the DEFAULT shape for every cited synthesis, concept,
#              entity and question node, and it is where mla's `n.d.` fallback
#              can collide with the sentence period.
# Alphabetical order (acme < Zimmermann < the author-less block) is deliberately
# unrelated to citation order, so a list that merely dropped the numbers without
# sorting still fails.
FINWORK=$(mktemp -d)
FINOUT=$(python3 - "$FINREF" "$PLUGIN_ROOT/scripts" "$FINWORK" <<'PY' 2>&1 || true
import json, os, pathlib, subprocess, sys

ref, scripts, work = pathlib.Path(sys.argv[1]), sys.argv[2], pathlib.Path(sys.argv[3])
lines = ref.read_text(encoding="utf-8").split("\n")
s = next(i for i, l in enumerate(lines) if l.strip() == "python3 -c '")
e = next(i for i, l in enumerate(lines) if i > s and l.strip() == "'")
code = "\n".join(lines[s + 1:e])

# The third citation is URL-less (a synthesis page has no external destination),
# and since #1755 its marker is PER FAMILY: the numbered families keep the plain
# <sup>[N]</sup> superscript, while author-date renders the destination-less
# ([Author, Year]) form. The AD tuple carries that form so the body assertion
# below can insist no <sup>[ survives an author-date deposit.
NUM = ("<sup>[1](https://zeta.eu/r)</sup>", "<sup>[2](https://acme.de/s)</sup>", "<sup>[3]</sup>")
AD = ("([Zimmermann, Ada, 2024](https://zeta.eu/r))", "([acme.de, 2019](https://acme.de/s))", "([Vorherige Synthese, n.d.])")
results = {}
bodies = {}
for fmt, inline in (("ieee", NUM), ("apa", AD), ("mla", AD), ("harvard", AD)):
    root = work / fmt
    w = root / "wiki"
    (w / "sources").mkdir(parents=True)
    (w / "syntheses").mkdir(parents=True)
    (w / "sources" / "zeta-page.md").write_text(
        '---\nid: zeta-page\ntitle: "Zeta Report"\ntype: source\n'
        'sources: ["https://zeta.eu/r"]\npublisher: "Zeta Institute"\n'
        'author: "Zimmermann, Ada"\npublished_date: "2024-03-02"\n---\n\nbody\n', encoding="utf-8")
    (w / "sources" / "acme-page.md").write_text(
        '---\nid: acme-page\ntitle: "Acme Studie"\ntype: source\n'
        'sources: ["https://acme.de/s"]\npublisher: "acme.de"\n'
        'fetched_at: "2019-07-01T10:00:00Z"\n---\n\nbody\n', encoding="utf-8")
    (w / "syntheses" / "vorherige-synthese.md").write_text(
        '---\nid: vorherige-synthese\ntitle: "Vorherige Synthese"\ntype: synthesis\n'
        'created: 2026-01-05\nupdated: 2026-01-05\n'
        'sources: ["wiki://zeta-page"]\n---\n\nbody\n', encoding="utf-8")
    p = root / "proj"
    (p / "output").mkdir(parents=True)
    (p / ".metadata").mkdir(parents=True)
    (p / "output" / "draft-v1.md").write_text(
        "# T\n\nAlpha" + inline[0] + ".\n\nBeta" + inline[1] + ".\n\nGamma"
        + inline[2] + ".\n", encoding="utf-8")
    (p / ".metadata" / "plan.json").write_text(json.dumps(
        {"topic": "T", "output_language": "en", "citation_format": fmt}), encoding="utf-8")
    (p / ".metadata" / "citation-manifest.json").write_text(json.dumps({
        "schema_version": "0.1.1", "draft_version": 1, "citations": [
            {"id": "c1", "wiki_slug": "zeta-page", "claim_id": "clm-001", "draft_sentence": "x"},
            {"id": "c2", "wiki_slug": "acme-page", "claim_id": "clm-001", "draft_sentence": "y"},
            {"id": "c3", "wiki_slug": "vorherige-synthese", "claim_id": None,
             "draft_sentence": "z"}]}),
        encoding="utf-8")
    env = dict(os.environ, KNOWLEDGE_SCRIPTS=scripts, WIKI_ROOT=str(root),
               PROJECT_PATH=str(p), PROJECT_SLUG="proj", SYNTHESIS_SLUG="syn",
               DRAFT_VERSION="1", REVISION_ROUND="0", VERIFY_VERBATIM="1",
               VERIFY_PARAPHRASE="1", VERIFY_SYNTHESIS="0", VERIFY_UNSUPPORTED="0",
               QUESTION_SLUGS_CSV="")
    r = subprocess.run([sys.executable, "-c", code], env=env, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("subprocess failed for " + fmt + ": " + r.stderr[-600:])
    page = (root / "wiki" / "syntheses" / "syn.md").read_text(encoding="utf-8")
    results[fmt] = page.split("## References", 1)[1].strip().split("\n") if "## References" in page else []
    bodies[fmt] = page.split("## References", 1)[0] if "## References" in page else page

problems = []
# ieee is the numbered control: numbering survives, in citation order.
if not results["ieee"] or not results["ieee"][0].startswith("**[1]** Zeta Institute"):
    problems.append("ieee-numbering:" + repr(results["ieee"][:1]))
if len([r for r in results["ieee"] if r.strip()]) != 3:
    problems.append("ieee-rowcount:" + repr(results["ieee"]))
for fmt in ("apa", "mla", "harvard"):
    rows = [r for r in results[fmt] if r.strip()]
    if len(rows) != 3:
        problems.append(fmt + "-rowcount:" + repr(rows))
        continue
    if any("**[" in r for r in rows):
        problems.append(fmt + "-numbered-prefix-survived:" + repr(rows))
    # acme.de < Zimmermann by surname; the author-less synthesis sorts LAST as a
    # block regardless of its title, via author_surname_sort_key's presence flag.
    if not rows[0].startswith("acme.de") or "Zimmermann" not in rows[1]:
        problems.append(fmt + "-not-alphabetical:" + repr(rows))
    if not rows[2].startswith('"Vorherige Synthese'):
        problems.append(fmt + "-authorless-not-title-first-or-not-last:" + repr(rows[2]))
    # legacy page (no author:/published_date:) resolved through the surrogates
    if "2019" not in rows[0]:
        problems.append(fmt + "-legacy-surrogate-year-missing:" + repr(rows[0]))
    # The year-less entry renders n.d. — and NEVER a doubled period. mla is the
    # only format whose year ends a segment, so it is the only one that can
    # collide with the sentence period; asserted for all three so a future
    # reordering of another format's segments cannot reintroduce it silently.
    if "n.d." not in rows[2]:
        problems.append(fmt + "-no-nd-on-yearless-entry:" + repr(rows[2]))
    if "n.d.." in rows[2]:
        problems.append(fmt + "-doubled-period-on-nd:" + repr(rows[2]))
    # A synthesis page has no external URL, so the entry carries no link — only
    # the bare wikilink backlink.
    if "](http" in rows[2]:
        problems.append(fmt + "-urlless-entry-got-a-link:" + repr(rows[2]))
# #1755: no numbered marker may survive in an author-date BODY — the reference
# list is un-numbered and the renumber pass is bypassed, so a [N] numeral could
# never be resolved. The ieee body is the control: it must still carry one.
if "<sup>[" not in bodies["ieee"]:
    problems.append("ieee-body-lost-its-numbered-marker:" + repr(bodies["ieee"][-200:]))
for fmt in ("apa", "mla", "harvard"):
    if "<sup>[" in bodies[fmt]:
        problems.append(fmt + "-body-kept-a-numbered-marker:" + repr(bodies[fmt][-200:]))
    if "([Vorherige Synthese, n.d.])" not in bodies[fmt]:
        problems.append(fmt + "-body-lost-the-destination-less-marker:" + repr(bodies[fmt][-200:]))
# the three formats must not collapse onto one shared bibliography string
firsts = {results[f][0] for f in ("apa", "mla", "harvard")}
if len(firsts) != 3:
    problems.append("formats-collapsed:" + repr(sorted(firsts)))
print("PROBLEMS " + "; ".join(problems) if problems else "CLEAN")
PY
)
rm -rf "$FINWORK"
if [ "$FINOUT" = "CLEAN" ]; then
  green "PASS: finalize-203-author-date-deposit-behavioral knowledge-finalize subprocess deposits apa/mla/harvard as an alphabetical, un-numbered, three-distinct-string reference list, resolves a legacy page through the publisher:/fetched_at: surrogates, renders a year-less URL-less synthesis entry title-first and last with n.d. and no doubled period, leaves the ieee numbering intact, and (#1755) keeps the destination-less author-date marker in the author-date BODY while no <sup>[N]</sup> survives there and the ieee body still carries one"
else
  red "FAIL: finalize-203-author-date-deposit-behavioral author-date deposit did not match the contract"
  red "  got: $FINOUT"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
