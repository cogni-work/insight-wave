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
  red "FAIL: skills/knowledge-finalize/SKILL.md not found"
  exit 1
fi

assert_grep 'name: knowledge-finalize' "$FIN" "knowledge-finalize: frontmatter name"
assert_grep 'citation-manifest.json' "$FIN" "knowledge-finalize: reads citation-manifest.json"
assert_grep 'verify-v' "$FIN" "knowledge-finalize: reads verify-vN.json from M8"
assert_grep 'wiki/syntheses/' "$FIN" "knowledge-finalize: deposits to wiki/syntheses/"
assert_grep 'type: synthesis' "$FIN" "knowledge-finalize: synthesis page has type: synthesis frontmatter"
assert_grep 'derived_from_research:' "$FIN" "knowledge-finalize: stamps derived_from_research inline"
assert_grep 'draft_revision_round:' "$FIN" "knowledge-finalize: records draft_revision_round (informational audit)"
assert_grep 'cycle-guard.py' "$FIN" "knowledge-finalize: dispatches cycle-guard.py"
assert_grep '## References' "$FIN" "knowledge-finalize: auto-generates ## References section"
assert_grep 'probe_plugin cogni-wiki' "$FIN" "knowledge-finalize: probes cogni-wiki (clean-break)"
assert_grep 'resolve_wiki_scripts wiki-ingest' "$FIN" "knowledge-finalize: resolves WIKI_INGEST_SCRIPTS via generalized resolver"
assert_grep 'wiki_index_update.py' "$FIN" "knowledge-finalize: calls cogni-wiki wiki_index_update.py at script level"
assert_grep 'config_bump.py' "$FIN" "knowledge-finalize: calls cogni-wiki config_bump.py at script level"
assert_grep 'rebuild_context_brief.py' "$FIN" "knowledge-finalize: calls cogni-wiki rebuild_context_brief.py at script level"
assert_grep 'category "Syntheses"' "$FIN" "knowledge-finalize: indexes synthesis under Syntheses category"
# #324: Step 7 passes the --max-summary word-boundary clamp backstop (cogni-wiki
# v0.0.47+), and the "truncated to 180 chars" instruction that caused the mid-word
# artifact is gone (the summary is authored as one crisp, complete sentence).
assert_grep 'max-summary' "$FIN" "knowledge-finalize: Step 7 passes --max-summary clamp backstop (#324)"
assert_not_grep '180' "$FIN" "knowledge-finalize: no 'truncated to 180 chars' instruction remains (#324)"
assert_grep 'append-project' "$FIN" "knowledge-finalize: appends to binding via knowledge-binding.py append-project"
assert_grep 'report-source wiki' "$FIN" "knowledge-finalize: hard-codes --report-source wiki on binding append"
assert_grep 'wiki/log.md' "$FIN" "knowledge-finalize: appends to wiki/log.md"
# #291: Step 9.5 best-effort sweeps the merged-away verify-shards/ fan-out scratch
# after deposit. Anchors the housekeeping layer like Step 2's guard is anchored.
assert_grep 'verify-shards' "$FIN" "knowledge-finalize: Step 9.5 sweeps verify-shards/ after deposit (#291)"
# Match the actual log-line shape `## [DATE] finalize | project=...`.
assert_grep '\] finalize | project=' "$FIN" "knowledge-finalize: emits the '## [DATE] finalize | project=...' log-line shape"
assert_grep 'slugify' "$FIN" "knowledge-finalize: reuses _knowledge_lib.slugify for default slug"
assert_grep 'atomic_write_text' "$FIN" "knowledge-finalize: writes synthesis page via _knowledge_lib.atomic_write_text"
# Cycle-guard adapter signal — the skill notes citation-manifest as the expected input_shape.
assert_grep 'citation-manifest' "$FIN" "knowledge-finalize: notes citation-manifest as cycle-guard's input_shape"
# Defence-in-depth: no Skill() dispatches to cogni-research / cogni-claims / cogni-wiki.
assert_not_grep 'Skill("cogni-research:' "$FIN" "knowledge-finalize: no Skill('cogni-research:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-claims:' "$FIN" "knowledge-finalize: no Skill('cogni-claims:') dispatch (clean break)"
assert_not_grep 'Skill("cogni-wiki:' "$FIN" "knowledge-finalize: no Skill('cogni-wiki:') dispatch (M6 contract: call helpers at script level)"
# Post-review hardening (v0.0.24, all 15 review findings).
# E1: wiki:// shape must be bare slug, not path-prefixed (cogni-wiki health.py:206).
assert_grep 'wiki://" + slug' "$FIN" "knowledge-finalize: emits bare 'wiki://<slug>' (not 'wiki://<wiki_slug>/<slug>') per cogni-wiki contract"
assert_not_grep 'wiki://" + wiki_slug + "/"' "$FIN" "knowledge-finalize: does NOT emit composite 'wiki://<wiki_slug>/<slug>' (would trip broken_wiki_source)"
# E2: synthesis-page citations must be resolved under wiki/syntheses/ as fallback.
assert_grep 'syntheses' "$FIN" "knowledge-finalize: resolves synthesis-page citations under wiki/syntheses/"
assert_grep 'page_kind' "$FIN" "knowledge-finalize: tracks page kind (source vs synthesis) for wikilink emission"
# E3: must strip the composer's trailing ## References section before re-appending its own.
assert_grep 'References' "$FIN" "knowledge-finalize: strips composer's trailing '## References' to avoid double sections"
# Slice 13 (#301/#300): the reference section is language-aware — read
# output_language, derive the heading from _knowledge_lib.ref_heading, and run
# the language-independent strip + inline renumber via the unit-tested
# _knowledge_lib helpers (the strip/renumber/URL logic was extracted out of the
# heredoc so it is executable-tested in test_knowledge_lib.sh, not just grepped).
assert_grep 'output_language' "$FIN" "knowledge-finalize: reads plan.json::output_language for the reference heading (#301)"
assert_grep 'ref_heading' "$FIN" "knowledge-finalize: derives the localized reference heading via _knowledge_lib.ref_heading (#301)"
assert_grep 'strip_reference_section' "$FIN" "knowledge-finalize: strips the composer's reference section via _knowledge_lib.strip_reference_section (language-independent; #301)"
assert_grep 'renumber_inline_citations' "$FIN" "knowledge-finalize: renumbers inline [N] markers via _knowledge_lib.renumber_inline_citations (#300)"
assert_grep 'md_link_dest' "$FIN" "knowledge-finalize: angle-brackets paren-bearing citation URLs via _knowledge_lib.md_link_dest (#300)"
# A4/D7: UTC date so frontmatter created/updated align with Step 10's `date -u`.
assert_grep 'timezone.utc' "$FIN" "knowledge-finalize: stamps created/updated in UTC (not local time)"
# A7 / B6: Step 8 entries_count bump is gated.
assert_grep 'INDEX_OK' "$FIN" "knowledge-finalize: Step 8 gated on Step 7 success (INDEX_OK)"
assert_grep 'SYNTHESIS_EXISTED_PRE' "$FIN" "knowledge-finalize: tracks pre-existence so Step 8 skips on --overwrite re-deposit"
# B7: --overwrite re-deposit passes --allow-update to knowledge-binding.py.
assert_grep 'allow-update' "$FIN" "knowledge-finalize: passes --allow-update on overwrite to refresh binding's report_path"
# A3/D8: log line uses printf, not echo, and sanitizes TOPIC newlines.
assert_grep "printf '## " "$FIN" "knowledge-finalize: log line uses printf (not echo) to avoid CR/LF + escape-interp drift"
assert_grep "tr '" "$FIN" "knowledge-finalize: sanitizes TOPIC CR/LF before logging to preserve one-line-per-event invariant"
# A4 follow-on: cycle-guard's new manifest_unreadable status is documented in the SKILL.
assert_grep 'manifest_unreadable' "$FIN" "knowledge-finalize: documents how to handle cycle-guard's new status=manifest_unreadable"
# CITATION_COUNT must actually be computed (E6 was a contract-gap finding).
assert_grep 'CITATION_COUNT=<count>' "$FIN" "knowledge-finalize: dry-run printout actually computes CITATION_COUNT"
# Task dispatch is REQUIRED as of v0.1.15 — Step 10.6 dispatches the
# wiki-contradictor agent (#335). The pre-v0.1.15 "no Task" assertion
# was tied to M9's no-agents posture, which is no longer the contract.
FIN_TOOLS_LINE=$(grep '^allowed-tools:' "$FIN" || true)
for required in 'Read' 'Write' 'Bash' 'Task'; do
  if echo "$FIN_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: knowledge-finalize: allowed-tools includes $required"
  else
    red "FAIL: knowledge-finalize: allowed-tools missing $required"
    red "  got: $FIN_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
# Closed-set guard: the pre-v0.1.15 'no Task' block also transitively forbade
# network-shaped tools from sneaking in. Re-establish that floor explicitly so
# a future PR that adds WebFetch / WebSearch / Edit to allowed-tools fails
# loudly (Step 10.6 dispatches a zero-network agent; finalize itself must
# stay zero-network and zero-mutation-outside-the-Python-heredoc).
for forbidden in 'WebFetch' 'WebSearch' 'Edit' 'NotebookEdit'; do
  if echo "$FIN_TOOLS_LINE" | grep -q "$forbidden"; then
    red "FAIL: knowledge-finalize: allowed-tools must NOT include $forbidden (zero-network / no-mutation contract beyond the existing Bash heredoc surface)"
    red "  got: $FIN_TOOLS_LINE"
    errors=$((errors + 1))
  else
    green "PASS: knowledge-finalize: allowed-tools omits $forbidden (zero-network contract)"
  fi
done

# --- Slice 16 (#308/#307/#306): wiki conformance -------------------------
# Reference backlinks must be BARE [[<slug>]] so the synthesis->source edge
# registers in cogni-wiki's link graph (WIKILINK_RE matches no slash). The old
# path-prefixed construction (link_dir + "/" + slug) must be gone from the code.
assert_grep 'backlink = ("\[\[" + slug + "\]\]")' "$FIN" "knowledge-finalize: emits a bare [[<slug>]] reference backlink (#308 orphan linchpin)"
assert_not_grep 'link_dir + "/" + slug' "$FIN" "knowledge-finalize: no path-prefixed [[sources/<slug>]] construction remains (#308)"
assert_not_grep 'link_dir = "syntheses"' "$FIN" "knowledge-finalize: dropped the link_dir prefix branch (#308)"
# R1: a missing cited page (page_kind None) emits NO wikilink so it can't trip
# health.py broken_wikilink in the new gate.
assert_grep 'page_kind is not None' "$FIN" "knowledge-finalize: backlink emitted only when the cited page exists (#308 R1 — avoid broken_wikilink)"
# Step 10.5 conformance gate: lint --fix=all then health.py asserting 0 errors.
assert_grep 'resolve_wiki_scripts wiki-lint' "$FIN" "knowledge-finalize: resolves the wiki-lint scripts dir for the gate"
assert_grep 'resolve_wiki_scripts wiki-health' "$FIN" "knowledge-finalize: resolves the wiki-health scripts dir for the gate"
assert_grep 'lint_wiki.py' "$FIN" "knowledge-finalize: Step 10.5 runs lint_wiki.py"
assert_grep '\-\-fix=all' "$FIN" "knowledge-finalize: Step 10.5 lint runs --fix=all (backfills reverse_link_missing)"
assert_grep 'health.py' "$FIN" "knowledge-finalize: Step 10.5 runs health.py"
assert_grep 'data.errors' "$FIN" "knowledge-finalize: Step 10.5 asserts health data.errors == []"
# The gate must also assert 0 orphan_page (the slice's actual metric — health.py
# does NOT compute orphans), via a no-fix re-lint after --fix=all.
assert_grep 'orphan_page' "$FIN" "knowledge-finalize: Step 10.5 asserts 0 orphan_page (re-lint after --fix; the slice's metric)"
assert_grep 'no .*--fix' "$FIN" "knowledge-finalize: Step 10.5 re-lints with NO --fix to read post-fix orphan state"
assert_grep 'reverse_link_missing' "$FIN" "knowledge-finalize: documents reverse_link_missing as the load-bearing de-orphaner"
# overview.md refresh (#308 stale-overview item).
assert_grep 'overview.md' "$FIN" "knowledge-finalize: refreshes wiki/overview.md (#308)"
assert_grep 'Recent syntheses' "$FIN" "knowledge-finalize: overview.md gets a Recent syntheses bullet"
# Default synthesis tags (#308 empty-tags item).
assert_grep 'tags: \[synthesis\]' "$FIN" "knowledge-finalize: synthesis frontmatter defaults tags: [synthesis] (#308)"
# Defence-in-depth: the synthesis index category stays Syntheses (confirmed scope).
assert_grep 'category "Syntheses"' "$FIN" "knowledge-finalize: synthesis still filed under the Syntheses category"

# --- #335 contradiction tripwire (Step 10.6, v0.1.15) --------------------
# Pure observability tripwire — fail-soft, never blocks finalize. Partially
# defends differentiation-thesis.md Pillar 2 at synthesis-write time.
# Step 10.6 lands after Step 10.5 sub-step 4 (rebuild_context_brief.py),
# before Step 11.
assert_grep '### 10.6 Contradiction tripwire' "$FIN" "knowledge-finalize: Step 10.6 heading present (#335)"
assert_grep 'wiki-contradictor' "$FIN" "knowledge-finalize: Step 10.6 dispatches wiki-contradictor agent (#335)"
# Anchor the literal dispatch syntax, not just a prose mention. The bare
# `wiki-contradictor` token also appears in the SKILL's description/Output/
# References blocks, so a maintainer could strip the actual Task(...) call
# while keeping the prose and the test would still pass without this anchor.
assert_grep 'Task(wiki-contradictor' "$FIN" "knowledge-finalize: Step 10.6 contains the literal Task(wiki-contradictor ...) dispatch (#335)"
assert_grep 'contradictor-v' "$FIN" "knowledge-finalize: Step 10.6 writes contradictor-v<N>.json output artifact (#335)"
assert_grep '\-\-no-contradictor' "$FIN" "knowledge-finalize: --no-contradictor opt-out flag documented in Parameters table (#335, R1)"
assert_grep '#335' "$FIN" "knowledge-finalize: Step 10.6 references issue #335"
# Fail-soft framing — must be explicit so a future maintainer doesn't
# tighten Step 10.6 into a blocking gate.
assert_grep 'observability-only\|non-fatal\|never rolls back\|never blocks' "$FIN" "knowledge-finalize: Step 10.6 documented as fail-soft / observability-only (#335)"
# Skip conditions — all three must be documented in the SKILL.
assert_grep 'Contradiction tripwire skipped: --no-contradictor' "$FIN" "knowledge-finalize: Step 10.6 documents --no-contradictor skip path (#335)"
assert_grep 'Contradiction tripwire skipped: empty citation manifest' "$FIN" "knowledge-finalize: Step 10.6 documents empty-citation-manifest skip path (#335)"
# Step 11 surfaces the tripwire line — must mention the prefix so the
# operator-visible warning shape is anchored.
assert_grep 'Contradiction tripwire: ' "$FIN" "knowledge-finalize: Step 11 final summary surfaces Contradiction tripwire line (#335)"
# Anchor the cost-line surface. It is the operator's feedback loop for the
# v0.1.16 --contradictor opt-in flip ('if sustained > $0.05/run across real
# bases...'). Losing it silently to a future SKILL edit would defeat the
# gating decision the CHANGELOG promises.
assert_grep 'Cost: \$' "$FIN" "knowledge-finalize: Step 11 surfaces tripwire Cost line (#335, sustained-cost gating)"
# Step 5/6 subprocess must emit cited_source_slugs — the orchestrator
# reuses page_kind_by_slug from there rather than re-resolving pages.
assert_grep 'cited_source_slugs' "$FIN" "knowledge-finalize: Step 5/6 subprocess emits cited_source_slugs for Step 10.6 (#335)"
# Pillar 2 framing — the SKILL must be honest about partial defense.
assert_grep 'Partially defends.*Pillar 2\|partially defend' "$FIN" "knowledge-finalize: Step 10.6 honest about partial Pillar 2 defense (#335)"
# References block must include the new agent.
assert_grep 'agents/wiki-contradictor.md' "$FIN" "knowledge-finalize: References block points at agents/wiki-contradictor.md (#335)"

# --- #338 open-questions refresh (Step 10.5 sub-step 5, v0.1.19) ----------
# Fail-soft refresh of the persistent data-gap backlog the inverted pipeline
# leaves stale. Same posture as cogni-wiki wiki-lint Step 8.5: never rolls
# back the synthesis; surfaces a loud failure line on error.
assert_grep '5\. \*\*Refresh `wiki/open_questions.md` (#338)' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 heading present (#338)"
assert_grep 'rebuild_open_questions.py' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 invokes rebuild_open_questions.py (#338)"
# The script dir is already resolved at Pre-flight for the Step 10.5 gate —
# anchor that sub-step 5 reuses $WIKI_LINT_SCRIPTS rather than re-resolving.
assert_grep 'WIKI_LINT_SCRIPTS/rebuild_open_questions.py' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 resolves rebuild_open_questions.py via \$WIKI_LINT_SCRIPTS (already wired #338)"
assert_grep '\-\-no-open-questions' "$FIN" "knowledge-finalize: --no-open-questions opt-out documented in Parameters table (#338)"
assert_grep 'Open questions rebuild skipped: --no-open-questions' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 documents --no-open-questions skip path (#338)"
# dry-run skip must be documented on the same line as the sub-step 5 anchor
# so a future edit can't silently drop the defence-in-depth guard.
assert_grep 'dry-run.*sub-step 5\|sub-step 5.*dry-run' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 skips on --dry-run (#338)"
assert_grep 'Open questions: opened=' "$FIN" "knowledge-finalize: Step 11 surfaces opened/closed/trimmed deltas on success (#338)"
assert_grep 'open_questions rebuild FAILED' "$FIN" "knowledge-finalize: Step 11 surfaces loud failure line on rebuild error (#338)"
# Fail-soft framing — must be explicit so a future maintainer doesn't tighten
# sub-step 5 into a blocking gate.
assert_grep 'never rolls back the synthesis' "$FIN" "knowledge-finalize: Step 10.5 sub-step 5 documented as fail-soft (#338)"
# Defence-in-depth: sub-step 5 must NOT add a second wiki/log.md line — the
# existing Step 10 finalize line is the close-attribution surface; a second
# line would double-count finalize ops.
assert_not_grep "printf '## .*open[_-]questions" "$FIN" "knowledge-finalize: sub-step 5 does NOT write a second wiki/log.md line (#338)"
# Edge-case section anchor: re-finalize idempotency for the open-questions RMW.
assert_grep '#338 open-questions idempotency' "$FIN" "knowledge-finalize: edge-case section documents re-finalize idempotency for the open-questions RMW (#338)"

# --- #337 verification-honesty surfacing (frontmatter + Step 11) ---------
# Two additive synthesis-page frontmatter keys declare WHAT "verified" means;
# Step 11 + the dashboard + verify Step 6 all carry the same qualifier so a
# reader of any surface arrives at the same understanding.
assert_grep 'verification: citation_consistent_zero_network' "$FIN" "knowledge-finalize: Step 5 frontmatter emits verification: citation_consistent_zero_network (#337)"
assert_grep 'verification_ratio:' "$FIN" "knowledge-finalize: Step 5 frontmatter emits verification_ratio: (#337)"
# The four verify-vN.json counts are threaded into the Step 5 compose subprocess.
assert_grep 'VERIFY_VERBATIM' "$FIN" "knowledge-finalize: threads VERIFY_VERBATIM into Step 5's compose subprocess (#337)"
assert_grep 'VERIFY_UNSUPPORTED' "$FIN" "knowledge-finalize: threads VERIFY_UNSUPPORTED into Step 5's compose subprocess (#337)"
# Step 11 final-summary qualifier lines.
assert_grep 'Verification: citation-consistent' "$FIN" "knowledge-finalize: Step 11 prints the citation-consistent Verification line (#337)"
assert_grep 'zero-network' "$FIN" "knowledge-finalize: Step 11 names zero-network (no live-source re-check) (#337)"
assert_grep 'Verbatim/paraphrase ratio' "$FIN" "knowledge-finalize: Step 11 prints the verbatim/paraphrase ratio line (#337)"
# Out of scope must point live-source re-verification at the opt-in resweep.
assert_grep 'knowledge-refresh --resweep' "$FIN" "knowledge-finalize: Out of scope names knowledge-refresh --resweep as the live-source path (#337)"
# Output block must list the two additive frontmatter keys as deliverables.
assert_grep 'verification_ratio:' "$FIN" "knowledge-finalize: Output block lists the additive verification frontmatter keys (#337)"
assert_grep '#337' "$FIN" "knowledge-finalize: references #337"

# --- Inverted-pipeline.md Phase 7 anchor ---------------------------------
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 7 — `knowledge-finalize`' "$PIPELINE" "inverted-pipeline.md: Phase 7 section header anchored"
assert_grep 'wiki_index_update' "$PIPELINE" "inverted-pipeline.md: Phase 7 names wiki_index_update.py as a helper call"
assert_grep 'config_bump' "$PIPELINE" "inverted-pipeline.md: Phase 7 names config_bump.py as a helper call"
assert_grep 'rebuild_context_brief' "$PIPELINE" "inverted-pipeline.md: Phase 7 names rebuild_context_brief.py as a helper call"
# #335 contradiction tripwire — the reference contract must name the new
# artifact + agent so the doc stays load-bearing.
assert_grep 'wiki-contradictor' "$PIPELINE" "inverted-pipeline.md: Phase 7 names wiki-contradictor agent (#335)"
assert_grep 'contradictor-v' "$PIPELINE" "inverted-pipeline.md: Phase 7 names contradictor-v<N>.json artifact (#335)"
assert_grep '#335' "$PIPELINE" "inverted-pipeline.md: Phase 7 references issue #335"

# --- cycle-guard.py docstring documents the new fallback -----------------
CG="$PLUGIN_ROOT/scripts/cycle-guard.py"
assert_grep 'citation-manifest' "$CG" "cycle-guard.py: docstring documents the citation-manifest fallback"
assert_grep 'input_shape' "$CG" "cycle-guard.py: emits input_shape in JSON envelope"
assert_grep 'legacy-source-entities' "$CG" "cycle-guard.py: input_shape vocabulary includes legacy-source-entities"
assert_grep 'CITATION_MANIFEST_RELPATH' "$CG" "cycle-guard.py: defines CITATION_MANIFEST_RELPATH constant"
assert_grep 'ManifestUnreadableError' "$CG" "cycle-guard.py: defines ManifestUnreadableError (no silent green on corrupt manifest)"
assert_grep 'manifest_unreadable' "$CG" "cycle-guard.py: emits status=manifest_unreadable on corrupt citation manifest"
assert_grep 'input_shapes' "$CG" "cycle-guard.py: tracks per-hop input_shapes (mixed-shape transitive walks observable)"

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
  red "FAIL: v0.1.0 clear case — expected exit 0, got $RC"
  red "  output: $OUT"
  errors=$((errors + 1))
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
  red "FAIL: v0.1.0 clear case — output did not match clear contract"
  red "  got: $OUT"
  errors=$((errors + 1))
else
  green "PASS: cycle-guard v0.1.0 clear case — status=clear, input_shape=citation-manifest, input_shapes recorded"
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
  red "FAIL: v0.1.0 self-cycle case — expected exit 1 (cycle_detected), got $RC2"
  red "  output: $OUT2"
  errors=$((errors + 1))
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
  red "FAIL: v0.1.0 self-cycle case — output did not match cycle_detected contract"
  red "  got: $OUT2"
  errors=$((errors + 1))
else
  green "PASS: cycle-guard v0.1.0 self-cycle case — exit 1 + status=cycle_detected"
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
  red "FAIL: corrupt-manifest case — expected exit 1, got $RC3"
  red "  output: $OUT3"
  errors=$((errors + 1))
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
  red "FAIL: corrupt-manifest case — output did not match manifest_unreadable contract"
  red "  got: $OUT3"
  errors=$((errors + 1))
else
  green "PASS: cycle-guard corrupt-manifest case — exit 1 + status=manifest_unreadable (was silent green pre-v0.0.24)"
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
