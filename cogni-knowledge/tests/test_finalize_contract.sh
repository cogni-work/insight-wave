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
assert_grep 'resolve_wiki_ingest_scripts' "$FIN" "knowledge-finalize: resolves WIKI_INGEST_SCRIPTS"
assert_grep 'wiki_index_update.py' "$FIN" "knowledge-finalize: calls cogni-wiki wiki_index_update.py at script level"
assert_grep 'config_bump.py' "$FIN" "knowledge-finalize: calls cogni-wiki config_bump.py at script level"
assert_grep 'rebuild_context_brief.py' "$FIN" "knowledge-finalize: calls cogni-wiki rebuild_context_brief.py at script level"
assert_grep 'category "Syntheses"' "$FIN" "knowledge-finalize: indexes synthesis under Syntheses category"
assert_grep 'append-project' "$FIN" "knowledge-finalize: appends to binding via knowledge-binding.py append-project"
assert_grep 'report-source wiki' "$FIN" "knowledge-finalize: hard-codes --report-source wiki on binding append"
assert_grep 'wiki/log.md' "$FIN" "knowledge-finalize: appends to wiki/log.md"
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
assert d['success'] is True, d
data = d['data']
assert data['status'] == 'clear', 'expected status=clear, got ' + repr(data.get('status'))
assert data['input_shape'] == 'citation-manifest', 'expected input_shape=citation-manifest, got ' + repr(data.get('input_shape'))
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
assert len(data['cross_lineage_overlap']) >= 1, 'cross_lineage_overlap empty'
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: v0.1.0 clear case — output did not match clear contract"
  red "  got: $OUT"
  errors=$((errors + 1))
else
  green "PASS: cycle-guard v0.1.0 clear case — status=clear, input_shape=citation-manifest"
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
assert d['success'] is False, 'expected success=false on cycle, got success=true'
data = d['data']
assert data['status'] == 'cycle_detected', 'expected status=cycle_detected, got ' + repr(data.get('status'))
assert data['input_shape'] == 'citation-manifest', 'expected input_shape=citation-manifest, got ' + repr(data.get('input_shape'))
assert len(data['direct_self_cycles']) >= 1, 'direct_self_cycles empty'
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: v0.1.0 self-cycle case — output did not match cycle_detected contract"
  red "  got: $OUT2"
  errors=$((errors + 1))
else
  green "PASS: cycle-guard v0.1.0 self-cycle case — exit 1 + status=cycle_detected"
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
