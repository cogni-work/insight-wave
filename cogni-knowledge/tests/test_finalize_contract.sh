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
# Defence-in-depth: no Task dispatch (M9 has no agents).
FIN_TOOLS_LINE=$(grep '^allowed-tools:' "$FIN" || true)
if echo "$FIN_TOOLS_LINE" | grep -q 'Task'; then
  red "FAIL: knowledge-finalize: allowed-tools must NOT include Task (M9 has no agents)"
  red "  got: $FIN_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: knowledge-finalize: allowed-tools omits Task (M9 has no agents)"
fi
for required in 'Read' 'Write' 'Bash'; do
  if echo "$FIN_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: knowledge-finalize: allowed-tools includes $required"
  else
    red "FAIL: knowledge-finalize: allowed-tools missing $required"
    red "  got: $FIN_TOOLS_LINE"
    errors=$((errors + 1))
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

# --- Inverted-pipeline.md Phase 7 anchor ---------------------------------
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 7 — `knowledge-finalize`' "$PIPELINE" "inverted-pipeline.md: Phase 7 section header anchored"
assert_grep 'wiki_index_update' "$PIPELINE" "inverted-pipeline.md: Phase 7 names wiki_index_update.py as a helper call"
assert_grep 'config_bump' "$PIPELINE" "inverted-pipeline.md: Phase 7 names config_bump.py as a helper call"
assert_grep 'rebuild_context_brief' "$PIPELINE" "inverted-pipeline.md: Phase 7 names rebuild_context_brief.py as a helper call"

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
