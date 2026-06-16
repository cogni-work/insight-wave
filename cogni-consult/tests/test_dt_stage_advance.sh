#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/dt-stage-advance.sh — the guarded,
# logged dt_stage stage-advance helper.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each
# fixture builds a minimal field.json under a temp engagement dir, runs the
# helper, and asserts on the resulting JSON output plus the on-disk state.
#
# Coverage:
#   1  forward-step        single-step advance empathize->define (success, logged)
#   2  invalid-stage       unknown target stage name rejected (success:false)
#   3  forward-skip        empathize->ideate skips a stage (success:false)
#   4  re-entry            test->define backward loop re-entry allowed (success)
#   5  idempotent          define->define same-stage re-set allowed (success)
#   6  legacy-no-dt-stage  entry without dt_stage -> from=null, target applied
#   7  deliverable-missing unknown deliverable slug (success:false)
#   8  field-missing       no field.json at path (success:false)
#   9  stage-log-created   stage-log.json created with the move appended
#
# Usage: bash cogni-consult/tests/test_dt_stage_advance.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/dt-stage-advance.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: dt-stage-advance.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Build a minimal engagement with one field manifest. Args: <dir> <dt_stage-json-snippet>
# The snippet is spliced as the deliverable's dt_stage line (or empty to omit it).
make_field() {
  local dir="$1" dt_line="$2"
  mkdir -p "$dir/action-fields/market-evidence"
  cat > "$dir/action-fields/market-evidence/field.json" <<EOF
{
  "slug": "market-evidence",
  "title": "Market Evidence",
  "deliverables": [
    {
      "slug": "market-sizing",
      "title": "Market sizing",
      "state": "in-progress"${dt_line}
    }
  ]
}
EOF
}

assert_json() {  # <label> <json> <python-bool-expr over `d`>
  local label="$1" json="$2" expr="$3"
  if printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if ($expr) else 1)" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "assertion failed: $expr -- got: $json"
  fi
}

# --- 1. forward-step: empathize -> define ---
D="$TMPROOT/t1"; make_field "$D" ',
      "dt_stage": "empathize"'
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing define)"
assert_json "1 forward-step result" "$OUT" "d['success'] is True and d['data']['from']=='empathize' and d['data']['to']=='define'"
STORED="$(python3 -c "import json;print(json.load(open('$D/action-fields/market-evidence/field.json'))['deliverables'][0]['dt_stage'])")"
[ "$STORED" = "define" ] && pass "1 forward-step persisted" || fail "1 forward-step persisted" "field.json dt_stage=$STORED"

# --- 2. invalid-stage ---
D="$TMPROOT/t2"; make_field "$D" ',
      "dt_stage": "empathize"'
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing prototpye)"
assert_json "2 invalid-stage rejected" "$OUT" "d['success'] is False and 'invalid target stage' in d['error']"

# --- 3. forward-skip: empathize -> ideate ---
D="$TMPROOT/t3"; make_field "$D" ',
      "dt_stage": "empathize"'
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing ideate)"
assert_json "3 forward-skip rejected" "$OUT" "d['success'] is False and 'illegal stage jump' in d['error']"

# --- 4. re-entry: test -> define ---
D="$TMPROOT/t4"; make_field "$D" ',
      "dt_stage": "test"'
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing define)"
assert_json "4 re-entry allowed" "$OUT" "d['success'] is True and d['data']['from']=='test' and d['data']['to']=='define'"

# --- 5. idempotent: define -> define ---
D="$TMPROOT/t5"; make_field "$D" ',
      "dt_stage": "define"'
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing define)"
assert_json "5 idempotent allowed" "$OUT" "d['success'] is True and d['data']['to']=='define'"

# --- 6. legacy entry without dt_stage ---
D="$TMPROOT/t6"; make_field "$D" ''
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing empathize)"
assert_json "6 legacy from=null" "$OUT" "d['success'] is True and d['data']['from'] is None and d['data']['to']=='empathize'"

# --- 7. deliverable missing ---
D="$TMPROOT/t7"; make_field "$D" ',
      "dt_stage": "empathize"'
OUT="$(bash "$SCRIPT" "$D" market-evidence nonexistent define)"
assert_json "7 deliverable-missing rejected" "$OUT" "d['success'] is False and 'not found' in d['error']"

# --- 8. field manifest missing ---
D="$TMPROOT/t8"; mkdir -p "$D"
OUT="$(bash "$SCRIPT" "$D" market-evidence market-sizing define)"
assert_json "8 field-missing rejected" "$OUT" "d['success'] is False and 'not found' in d['error']"

# --- 9. stage-log created + move appended ---
D="$TMPROOT/t9"; make_field "$D" ',
      "dt_stage": "empathize"'
bash "$SCRIPT" "$D" market-evidence market-sizing define >/dev/null
if [ -f "$D/.metadata/stage-log.json" ]; then
  LOG_OK="$(python3 -c "
import json
m=json.load(open('$D/.metadata/stage-log.json'))['moves']
e=m[-1]
print('ok' if (len(m)==1 and e['from']=='empathize' and e['to']=='define' and e['action_field']=='market-evidence' and e['deliverable']=='market-sizing' and e['triggered_by']=='consult-design-thinking' and e['timestamp'].endswith('Z')) else 'bad')
")"
  [ "$LOG_OK" = "ok" ] && pass "9 stage-log created+appended" || fail "9 stage-log created+appended" "move entry malformed"
else
  fail "9 stage-log created+appended" "stage-log.json not created"
fi

echo ""
if [ "$failures" -eq 0 ]; then
  echo "All dt-stage-advance tests passed."
  exit 0
else
  echo "$failures dt-stage-advance test(s) failed." >&2
  exit 1
fi
