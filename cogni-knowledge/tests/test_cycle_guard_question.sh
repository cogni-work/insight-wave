#!/usr/bin/env bash
# test_cycle_guard_question.sh — type:question nodes are citable (#432).
#
# Mirrors test_cycle_guard_distilled.sh for the 4th evidence family: a question
# node carries answer_claims: but NO derived_from_research:, so cycle-guard "sees
# through" it to the SOURCE pages that answer it (its EXISTING sources_answering:
# list) and runs the lineage check on each.
#
#  A. CLEAR — candidate project-a cites a question node answered (partly) by
#     project-a's own raw sources. The backing sources carry no lineage stamp, so
#     the see-through bottoms out clear. Asserts: status=clear, exit 0, the node
#     recorded in cited_question_pages[], NOT in wiki_pages_cited_missing.
#  B. SEE-THROUGH CYCLE (forward-defensive) — candidate cites a question node whose
#     sources_answering includes a page stamped derived_from_research: project-a.
#     The see-through resolves it and detects the direct self-cycle the bare
#     question citation would otherwise have hidden. Asserts: cycle_detected, exit 1.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/cycle-guard.py"

. "$TESTS_DIR/fixtures/_cycle_guard_lib.sh"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# --- Scenario A: clear ------------------------------------------------------
WORK_A=$(mktemp -d)
trap 'rm -rf "$WORK_A" "${WORK_B:-}"' EXIT

KB_A="$WORK_A/kb"
PROJ_A="$WORK_A/project-a"

mk_knowledge_base "$KB_A" test-wiki
# Two raw backing source pages that answer the question — no lineage stamp.
mk_wiki_page "$KB_A" sources src-page-x ""
mk_wiki_page "$KB_A" sources src-page-y ""
# Question node answered by project-a's own sources (its sources_answering list).
mk_question_page "$KB_A" q-high-risk src-page-x src-page-y
# Candidate cites the question node directly (with its acl-NNN claim id).
mk_v01_project "$PROJ_A" project-a
add_manifest_citation "$PROJ_A" q-high-risk acl-001

set +e
OUT_A=$(python3 "$SCRIPT" \
  --knowledge-root "$KB_A" \
  --research-slug project-a \
  --research-project-path "$PROJ_A" 2>&1)
RC_A=$?
set -e

if [ $RC_A -ne 0 ]; then
  red "FAIL[A]: expected exit 0 (clear), got $RC_A"
  red "  got: $OUT_A"
  errors=$((errors + 1))
fi
if ! echo "$OUT_A" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d['data']
assert d['success'] is True, d
assert data['status'] == 'clear', data['status']
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
assert data['transitive_self_cycles'] == [], data['transitive_self_cycles']
slugs = [p['page'] for p in data['cited_question_pages']]
assert 'wiki/questions/q-high-risk.md' in slugs, data['cited_question_pages']
assert data['cited_question_pages'][0]['type'] == 'question', data['cited_question_pages']
assert data['wiki_pages_cited_missing'] == [], data['wiki_pages_cited_missing']
print('OK')
" | grep -q OK; then
  red "FAIL[A]: clear-with-question contract not met"
  red "  got: $OUT_A"
  errors=$((errors + 1))
else
  green "PASS[A]: question citation is clear; recorded in cited_question_pages, not missing"
fi

# --- Scenario B: see-through cycle ------------------------------------------
WORK_B=$(mktemp -d)
KB_B="$WORK_B/kb"
PROJ_B="$WORK_B/project-a"

mk_knowledge_base "$KB_B" test-wiki
# A backing page stamped derived_from_research: project-a (the candidate). In real
# data a question node answers raw sources, not lineage-stamped pages — this
# synthetic backing proves the see-through is not dead code.
mk_wiki_page "$KB_B" syntheses prior-synth-of-a project-a
mk_question_page "$KB_B" q-derived prior-synth-of-a
mk_v01_project "$PROJ_B" project-a
add_manifest_citation "$PROJ_B" q-derived acl-001

set +e
OUT_B=$(python3 "$SCRIPT" \
  --knowledge-root "$KB_B" \
  --research-slug project-a \
  --research-project-path "$PROJ_B" 2>&1)
RC_B=$?
set -e

if [ $RC_B -ne 1 ]; then
  red "FAIL[B]: expected exit 1 (cycle_detected via see-through), got $RC_B"
  red "  got: $OUT_B"
  errors=$((errors + 1))
fi
if ! echo "$OUT_B" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d['data']
assert d['success'] is False, d
assert data['status'] == 'cycle_detected', data['status']
assert len(data['direct_self_cycles']) > 0, data['direct_self_cycles']
assert data['direct_self_cycles'][0]['page'] == 'wiki/syntheses/prior-synth-of-a.md', data['direct_self_cycles']
print('OK')
" | grep -q OK; then
  red "FAIL[B]: see-through cycle contract not met"
  red "  got: $OUT_B"
  errors=$((errors + 1))
else
  green "PASS[B]: see-through trace surfaces the direct cycle behind a question citation"
fi

if [ $errors -ne 0 ]; then
  red "FAIL: $errors assertion(s) failed"
  exit 1
fi
green "PASS: question-node citations handled (clear see-through + cycle detection)"
