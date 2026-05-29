#!/usr/bin/env bash
# test_open_questions_research_gaps.sh — research-time gap streaming into
# wiki/open_questions.md via the --findings - contract (#354).
#
# The two new tracked classes (research_uncovered, research_partial) are
# deposit-only: lint never produces them; cogni-knowledge:knowledge-finalize
# pipes them in. This test exercises the cogni-wiki side of the contract by
# feeding synthetic --findings - payloads directly.
#
# T1 baseline regression — lint-only payload renders the existing sections;
#    no research headers appear.
# T2 gaps open — research_uncovered + research_partial render under the new
#    tail sections as `- [ ] \`sq:sq-0X\` — …`.
# T3 credit-close — a finalize log line with `sqs=sq-04` credit-closes sq-04
#    when it drops out of the findings (`closed <date> by finalize`).
# T4 reopen — sq-04 re-appearing in findings flips it back to open, no dup.
# T5 trim — a >90d closed research gap is trimmed by default, kept with
#    --skip-trim.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
SCRIPT="$PLUGIN_ROOT/skills/wiki-lint/scripts/rebuild_open_questions.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

assert_success_json() {
  local label="$1" out="$2" ok
  ok=$(printf '%s' "$out" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print("yes" if d.get("success") else "no")' 2>/dev/null || echo "parse-error")
  if [ "$ok" != "yes" ]; then
    red "FAIL ($label): expected success:true"
    printf '%s\n' "$out"
    exit 1
  fi
}

json_get() {
  # $1 = JSON string, $2 = dotted-ish data field key
  printf '%s' "$1" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(d['data'].get('$2', ''))
"
}

run_findings() {
  # $1 = findings JSON payload (stdin); rest = extra args
  local payload="$1"; shift
  printf '%s' "$payload" | python3 "$SCRIPT" --wiki-root "$WIKI" --findings - "$@"
}

# ---------- prepare a migrated (post-layout) wiki ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null
OQ="$WIKI/wiki/open_questions.md"
green "fixture prepared (migrated wiki)"

# ---------- T1: baseline regression — lint-only payload ----------
LINT_ONLY='{"errors": [], "warnings": [{"class": "no_sources", "page": "some-page", "message": "no sources cited"}], "info": []}'
OUT=$(run_findings "$LINT_ONLY")
assert_success_json "T1 lint-only" "$OUT"
[ "$(json_get "$OUT" opened)" = "1" ] || fail "T1: expected opened=1"
grep -q '^## Pages without sources' "$OQ" || fail "T1: lint section missing"
grep -qE '^- \[ \] `some-page` —' "$OQ" || fail "T1: lint item missing"
grep -q 'Research-time gaps' "$OQ" && fail "T1: research headers should be absent with zero research findings"
green "T1: lint-only payload renders existing section, no research headers"

# ---------- T2: research gaps open ----------
GAPS='{"errors": [], "warnings": [
  {"class": "research_uncovered", "id": "sq:sq-04", "message": "High-risk Classification Scope — what triggers Annex III"},
  {"class": "research_partial",   "id": "sq:sq-02", "message": "Conformity Assessment — provider obligations"}
], "info": []}'
OUT=$(run_findings "$GAPS")
assert_success_json "T2 gaps open" "$OUT"
grep -q '^## Research-time gaps — uncovered' "$OQ" || fail "T2: uncovered header missing"
grep -q '^## Research-time gaps — partial' "$OQ" || fail "T2: partial header missing"
grep -qE '^- \[ \] `sq:sq-04` — High-risk' "$OQ" || fail "T2: sq-04 open item missing"
grep -qE '^- \[ \] `sq:sq-02` — Conformity' "$OQ" || fail "T2: sq-02 open item missing"
# the T1 lint item must have closed (it dropped out of the T2 findings)
grep -qE '^- \[x\] ~~`some-page` —' "$OQ" || fail "T2: dropped lint item should be closed"
green "T2: research gaps render under the two tail sections"

# ---------- T3: credit-close via finalize log line ----------
TODAY=$(date -u +%Y-%m-%d)
printf '\n## [%s] finalize | project=EU AI Act slug=eu-ai-act draft=v1 round=0 sources=12 sqs=sq-04,sq-01\n' "$TODAY" >> "$WIKI/wiki/log.md"
# Re-dispatch WITHOUT sq-04 (keep sq-02 so the file is non-trivial).
GAPS_NO_SQ04='{"errors": [], "warnings": [
  {"class": "research_partial", "id": "sq:sq-02", "message": "Conformity Assessment — provider obligations"}
], "info": []}'
OUT=$(run_findings "$GAPS_NO_SQ04")
assert_success_json "T3 credit-close" "$OUT"
CLOSED_RE="^- \[x\] ~~\`sq:sq-04\` — .*~~ — closed $TODAY by finalize$"
if ! grep -qE "$CLOSED_RE" "$OQ"; then
  red "T3: sq-04 not closed 'by finalize'; file content:"
  cat "$OQ"
  exit 1
fi
green "T3: sq-04 credit-closed 'by finalize' via sqs= log line"

# ---------- T4: reopen on re-appearance ----------
OUT=$(run_findings "$GAPS")
assert_success_json "T4 reopen" "$OUT"
grep -qE '^- \[ \] `sq:sq-04` — High-risk' "$OQ" || fail "T4: sq-04 should be open again"
# exactly one sq-04 line total (no double-count: the closed entry was promoted)
N_SQ04=$(grep -cE '`sq:sq-04`' "$OQ" || true)
[ "$N_SQ04" = "1" ] || fail "T4: expected exactly 1 sq-04 line, got $N_SQ04"
green "T4: sq-04 reopened cleanly, no double-count"

# ---------- T5: 90-day trim ----------
# Drive sq-04 closed again, then age its closed_on date past retention.
OUT=$(run_findings "$GAPS_NO_SQ04")
assert_success_json "T5 close-for-trim" "$OUT"
OLD_DATE=$(python3 -c 'import datetime; print((datetime.date.today() - datetime.timedelta(days=100)).isoformat())')
sed -i.bak "s/closed $TODAY by finalize/closed $OLD_DATE by finalize/" "$OQ"
rm -f "$OQ.bak"
# --skip-trim keeps it
OUT=$(run_findings "$GAPS_NO_SQ04" --skip-trim)
assert_success_json "T5 skip-trim" "$OUT"
grep -qE "closed $OLD_DATE by finalize" "$OQ" || fail "T5: --skip-trim should keep the aged closed item"
# default trims it
sed -i.bak "s/closed $TODAY by finalize/closed $OLD_DATE by finalize/" "$OQ" 2>/dev/null || true
rm -f "$OQ.bak"
OUT=$(run_findings "$GAPS_NO_SQ04")
assert_success_json "T5 trim" "$OUT"
[ "$(json_get "$OUT" trimmed)" = "1" ] || fail "T5: expected trimmed=1, got $(json_get "$OUT" trimmed)"
grep -qE "closed $OLD_DATE by finalize" "$OQ" && fail "T5: aged closed item should be trimmed"
green "T5: aged research gap trimmed by default, kept with --skip-trim"

# ---------- T6: enveloped {success, data:{...}} payload is unwrapped ----------
# build_open_questions_payload.py emits the standard envelope; --findings -
# must unwrap data before flattening.
ENVELOPED='{"success": true, "data": {"errors": [], "warnings": [{"class": "research_uncovered", "id": "sq:sq-09", "message": "Enveloped payload gap"}], "info": []}, "meta": {"lint_findings": 0, "research_findings": 1}}'
OUT=$(run_findings "$ENVELOPED")
assert_success_json "T6 enveloped" "$OUT"
grep -qE '^- \[ \] `sq:sq-09` — Enveloped payload gap' "$OQ" || fail "T6: enveloped payload not unwrapped"
green "T6: enveloped {success,data} payload unwrapped via --findings -"

green "ALL TESTS PASS"
