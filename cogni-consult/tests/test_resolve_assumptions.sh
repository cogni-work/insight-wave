#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/resolve-assumptions.py — the
# fail-loud {{asm:id}} render resolver.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each
# fixture builds a minimal engagement dir + target file under a temp root,
# runs the resolver, and asserts on the JSON envelope plus the on-disk state.
#
# Coverage:
#   1  resolve-in-place    two occurrences of one id both replaced (AC1)
#   2  dry-run             no --in-place -> resolved_text in envelope, file untouched
#   3  unknown-id          all missing ids listed, exit 1, file untouched (AC2)
#   4  malformed           uppercase/underscore {{asm:...}} variants fail loud
#   5  nested-value        registry value embedding a placeholder fails post-substitution
#   6  missing-value       entry without value / value null -> missing_assumption_value
#   7  bad-id              id-less or malformed-id entry -> invalid_assumption_id
#   8  duplicate-id        two entries sharing an id -> duplicate_assumption_id
#   9  registry-missing    placeholders without assumptions.json -> registry_missing
#  10  no-placeholders     placeholder-free file passes even without a registry
#  11  used-by-first       --in-place records the citer in the id's used_by[]
#  12  used-by-idempotent  re-resolving the same citer adds nothing, registry not rewritten
#  13  used-by-dry-run     dry-run leaves assumptions.json byte-identical
#  14  used-by-multi       a second citing file accumulates a second used_by[] entry
#  15  used-by-write-failed  failed edge write -> used_by_write_failed envelope, target untouched
#  16  provenance-marker   a typed entry renders value + link-safe (prov: t/s); untyped renders bare
#  17  cap-exceeded        given/reviewed exceeds the 'stated' cap -> status_cap_exceeded, target untouched
#  18  verified-reserved   hand-set 'verified' is over cap (verify-path only) -> status_cap_exceeded
#  19  incomplete-provenance  provenance_type without status -> incomplete_provenance
#  20  marker-collision-safety  re-resolving marked output does not trip the leftover checks
#  21  scoped-validation   a mis-typed UNCITED assumption does not block a brief citing a good one
#
# Usage: bash cogni-consult/tests/test_resolve_assumptions.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/resolve-assumptions.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: resolve-assumptions.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Assert the envelope's success flag and (on failure envelopes) failed_check.
# Args: <name> <expected-success> <expected-failed_check-or-empty> <envelope>
assert_envelope() {
  local name="$1" want_success="$2" want_check="$3" envelope="$4"
  echo "$envelope" | ENV_SUCCESS="$want_success" ENV_CHECK="$want_check" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
ok = str(d["success"]).lower() == os.environ["ENV_SUCCESS"]
check = os.environ["ENV_CHECK"]
if check:
    ok = ok and d["data"].get("failed_check") == check
sys.exit(0 if ok else 1)
' && pass "$name" || fail "$name" "envelope mismatch: $envelope"
}

ENG="$TMPROOT/eng"
mkdir -p "$ENG"
cat > "$ENG/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-tam-dach-2027", "name": "TAM", "value": "4.2bn EUR",
                  "created": "2026-07-08", "updated": "2026-07-08"}]}
EOF

# 1 resolve-in-place
F="$TMPROOT/brief.md"
printf 'TAM {{asm:tam-dach-2027}} again {{asm:tam-dach-2027}}.\n' > "$F"
OUT=$(python3 "$SCRIPT" "$ENG" resolve "$F" --in-place)
assert_envelope "resolve-in-place envelope" true "" "$OUT"
grep -q 'TAM 4.2bn EUR again 4.2bn EUR.' "$F" \
  && pass "resolve-in-place file" || fail "resolve-in-place file" "$(cat "$F")"

# 2 dry-run
F="$TMPROOT/dry.md"
printf 'dry {{asm:tam-dach-2027}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$ENG" resolve "$F")
echo "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if "4.2bn EUR" in d["data"]["resolved_text"] else 1)' \
  && pass "dry-run resolved_text" || fail "dry-run resolved_text" "$OUT"
grep -q '{{asm:tam-dach-2027}}' "$F" \
  && pass "dry-run file untouched" || fail "dry-run file untouched" "$(cat "$F")"

# 3 unknown-id: all listed, file untouched
F="$TMPROOT/unknown.md"
printf '{{asm:tam-dach-2027}} {{asm:nope-1}} {{asm:nope-2}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$ENG" resolve "$F" --in-place)
RC=$?
[ "$RC" -ne 0 ] && pass "unknown-id exit" || fail "unknown-id exit" "exit $RC"
assert_envelope "unknown-id envelope" false "unknown_assumption_id" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["data"]["ids"] == ["asm-nope-1","asm-nope-2"] else 1)' \
  && pass "unknown-id lists all" || fail "unknown-id lists all" "$OUT"
grep -q '{{asm:tam-dach-2027}}' "$F" \
  && pass "unknown-id file untouched" || fail "unknown-id file untouched" "$(cat "$F")"

# 4 malformed placeholders fail loud
F="$TMPROOT/malformed.md"
printf 'bad {{asm:TAM-Dach-2027}} and {{asm:tam_dach}} and {{ asm:tam }}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$ENG" resolve "$F" --in-place)
assert_envelope "malformed envelope" false "malformed_placeholder" "$OUT"

# 5 nested placeholder in a registry value
NEST="$TMPROOT/nest"; mkdir -p "$NEST"
cat > "$NEST/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-outer", "name": "n", "value": "x ({{asm:inner}})"},
                 {"id": "asm-inner", "name": "n", "value": "y"}]}
EOF
F="$TMPROOT/nested.md"
printf '{{asm:outer}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$NEST" resolve "$F" --in-place)
assert_envelope "nested-value envelope" false "unresolved_after_substitution" "$OUT"
grep -q '{{asm:outer}}' "$F" \
  && pass "nested-value file untouched" || fail "nested-value file untouched" "$(cat "$F")"

# 6 missing / null value
BADVAL="$TMPROOT/badval"; mkdir -p "$BADVAL"
cat > "$BADVAL/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-no-value", "name": "n"},
                 {"id": "asm-null-value", "name": "n", "value": null}]}
EOF
F="$TMPROOT/badval.md"
printf '{{asm:no-value}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$BADVAL" resolve "$F" --in-place)
assert_envelope "missing-value envelope" false "missing_assumption_value" "$OUT"

# 7 id-less / malformed-id entries
BADID="$TMPROOT/badid"; mkdir -p "$BADID"
cat > "$BADID/assumptions.json" <<'EOF'
{"assumptions": [{"name": "no id at all", "value": "1"},
                 {"id": "not-asm-prefixed", "value": "2"}]}
EOF
F="$TMPROOT/badid.md"
printf '{{asm:anything}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$BADID" resolve "$F" --in-place)
assert_envelope "bad-id envelope" false "invalid_assumption_id" "$OUT"

# 8 duplicate id
DUP="$TMPROOT/dup"; mkdir -p "$DUP"
cat > "$DUP/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-a", "name": "n", "value": "1"},
                 {"id": "asm-a", "name": "n", "value": "2"}]}
EOF
F="$TMPROOT/dup.md"
printf '{{asm:a}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$DUP" resolve "$F" --in-place)
assert_envelope "duplicate-id envelope" false "duplicate_assumption_id" "$OUT"

# 9 registry missing while placeholders exist
NOREG="$TMPROOT/noreg"; mkdir -p "$NOREG"
F="$TMPROOT/noreg.md"
printf '{{asm:tam-dach-2027}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$NOREG" resolve "$F" --in-place)
assert_envelope "registry-missing envelope" false "registry_missing" "$OUT"

# 10 placeholder-free file passes even without a registry
F="$TMPROOT/plain.md"
printf 'no placeholders here\n' > "$F"
OUT=$(python3 "$SCRIPT" "$NOREG" resolve "$F" --in-place)
assert_envelope "no-placeholders envelope" true "" "$OUT"

# Shared fixture for the used_by[] reference-edge cases (11-14): a fresh
# engagement dir so earlier cases' writes can't bleed in, with the citing
# file inside the engagement so the recorded path is engagement-relative.
UB="$TMPROOT/ub"; mkdir -p "$UB/action-fields/market"
cat > "$UB/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-tam", "name": "TAM", "value": "4.2bn EUR",
                  "created": "2026-07-08", "updated": "2026-07-08"}]}
EOF

# Assert used_by[] on asm-tam: entry count and each entry's file + resolved_at.
# Args: <name> <expected-count> <expected-file-csv-or-empty>
assert_used_by() {
  local name="$1" want_count="$2" want_files="$3"
  UB_COUNT="$want_count" UB_FILES="$want_files" python3 - "$UB/assumptions.json" <<'PYEOF' && pass "$name" || fail "$name" "$(cat "$UB/assumptions.json")"
import json, os, sys
entry = {e["id"]: e for e in json.load(open(sys.argv[1]))["assumptions"]}["asm-tam"]
used_by = entry.get("used_by", [])
ok = len(used_by) == int(os.environ["UB_COUNT"])
want_files = [f for f in os.environ["UB_FILES"].split(",") if f]
ok = ok and sorted(r["file"] for r in used_by) == sorted(want_files)
ok = ok and all(r.get("resolved_at") for r in used_by)
sys.exit(0 if ok else 1)
PYEOF
}

# 11 used-by-first: --in-place records the citer
F="$UB/action-fields/market/brief.md"
printf 'TAM {{asm:tam}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$UB" resolve "$F" --in-place)
assert_envelope "used-by-first envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["used_by_added"] == 1 else 1)' \
  && pass "used-by-first added=1" || fail "used-by-first added=1" "$OUT"
assert_used_by "used-by-first entry" 1 "action-fields/market/brief.md"

# 12 used-by-idempotent: same citer again -> no new edge, registry not rewritten
cp "$UB/assumptions.json" "$TMPROOT/ub-before.json"
printf 'TAM {{asm:tam}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$UB" resolve "$F" --in-place)
assert_envelope "used-by-idempotent envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["used_by_added"] == 0 else 1)' \
  && pass "used-by-idempotent added=0" || fail "used-by-idempotent added=0" "$OUT"
cmp -s "$UB/assumptions.json" "$TMPROOT/ub-before.json" \
  && pass "used-by-idempotent registry byte-identical" \
  || fail "used-by-idempotent registry byte-identical" "registry rewritten"

# 13 used-by-dry-run: no --in-place -> registry untouched
cp "$UB/assumptions.json" "$TMPROOT/ub-before.json"
F="$UB/action-fields/market/dry.md"
printf 'TAM {{asm:tam}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$UB" resolve "$F")
assert_envelope "used-by-dry-run envelope" true "" "$OUT"
cmp -s "$UB/assumptions.json" "$TMPROOT/ub-before.json" \
  && pass "used-by-dry-run registry untouched" \
  || fail "used-by-dry-run registry untouched" "registry rewritten by dry-run"

# 14 used-by-multi: a distinct citing file accumulates a second entry
F2="$UB/action-fields/market/second.md"
printf 'again {{asm:tam}}\n' > "$F2"
OUT=$(python3 "$SCRIPT" "$UB" resolve "$F2" --in-place)
assert_envelope "used-by-multi envelope" true "" "$OUT"
assert_used_by "used-by-multi entries" 2 "action-fields/market/brief.md,action-fields/market/second.md"

# 15 used-by-write-failed: edge write fails -> envelope, target file untouched
# (edge is recorded BEFORE the target rewrite, so a failed edge write must
# leave the placeholders intact and the run retryable). The engagement dir is
# made read-only so the registry's temp-file write fails; the target lives
# outside it so only the edge write can fail.
WF="$TMPROOT/wf"; mkdir -p "$WF"
cat > "$WF/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-tam", "name": "TAM", "value": "4.2bn EUR",
                  "created": "2026-07-08", "updated": "2026-07-08"}]}
EOF
F="$TMPROOT/wf-brief.md"
printf 'TAM {{asm:tam}}\n' > "$F"
chmod 555 "$WF"
OUT=$(python3 "$SCRIPT" "$WF" resolve "$F" --in-place)
RC=$?
chmod 755 "$WF"
[ "$RC" -ne 0 ] && pass "used-by-write-failed exit" || fail "used-by-write-failed exit" "exit $RC"
assert_envelope "used-by-write-failed envelope" false "used_by_write_failed" "$OUT"
grep -q '{{asm:tam}}' "$F" \
  && pass "used-by-write-failed target untouched" \
  || fail "used-by-write-failed target untouched" "$(cat "$F")"

# --- Provenance typing (16-21) ----------------------------------------------
PROV="$TMPROOT/prov"; mkdir -p "$PROV"

# 16 typed-marker: a typed entry renders value + a parenthetical (link-safe,
#    brace-free) marker; an untyped legacy entry renders bare (back-compat).
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [
  {"id": "asm-tam", "name": "TAM", "value": "4.2bn", "provenance_type": "claim", "status": "reviewed"},
  {"id": "asm-legacy", "name": "Legacy", "value": "99"}]}
EOF
F="$PROV/brief.md"
printf 'TAM {{asm:tam}}, legacy {{asm:legacy}}.\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F")
assert_envelope "provenance-marker envelope" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
# typed -> value + parenthetical marker; untyped -> bare; no [ ] link syntax,
# no braces (so a re-resolve cannot re-form a placeholder).
ok = ("4.2bn (prov: claim/reviewed)" in t and "legacy 99." in t
      and "99 (prov" not in t and "[" not in t and "{" not in t)
sys.exit(0 if ok else 1)
' && pass "provenance-marker render" || fail "provenance-marker render" "$OUT"

# 17 cap-exceeded: given caps at 'stated', so given/reviewed fails loud
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-g", "name": "G", "value": "5", "provenance_type": "given", "status": "reviewed"}]}
EOF
printf '{{asm:g}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --in-place)
assert_envelope "cap-exceeded envelope" false "status_cap_exceeded" "$OUT"
grep -q '{{asm:g}}' "$F" \
  && pass "cap-exceeded target untouched" || fail "cap-exceeded target untouched" "$(cat "$F")"

# 18 verified-not-hand-settable: 'verified' is reserved for the verify path,
#    so any hand-authored verified status is over its cap and fails loud
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-c", "name": "C", "value": "5", "provenance_type": "claim", "status": "verified"}]}
EOF
printf '{{asm:c}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F")
assert_envelope "verified-reserved envelope" false "status_cap_exceeded" "$OUT"

# 19 incomplete-provenance: provenance_type without status (or vice versa) fails
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-c", "name": "C", "value": "5", "provenance_type": "claim"}]}
EOF
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F")
assert_envelope "incomplete-provenance envelope" false "incomplete_provenance" "$OUT"

# 20 marker-collision-safety: the rendered marker must not re-trigger the
#    malformed / unresolved-after-substitution leftover checks on a re-resolve
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-c", "name": "C", "value": "5", "provenance_type": "claim", "status": "reviewed"}]}
EOF
printf '{{asm:c}}\n' > "$F"
python3 "$SCRIPT" "$PROV" resolve "$F" --in-place >/dev/null
# The written file now holds "5 (prov: claim/reviewed)" — re-resolving must
# succeed (no placeholders left, no malformed token from the marker).
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --in-place)
assert_envelope "marker-collision-safe envelope" true "" "$OUT"

# 21 scoped-validation: a mis-typed UNCITED assumption must not block a brief
#    that cites only a well-formed one (provenance caps are per-cited-value,
#    not registry-wide like the id/value/duplicate integrity checks).
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [
  {"id": "asm-ok", "name": "OK", "value": "10", "provenance_type": "given", "status": "stated"},
  {"id": "asm-bad", "name": "Bad", "value": "20", "provenance_type": "given", "status": "verified"}]}
EOF
printf 'only {{asm:ok}} here.\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F")
assert_envelope "scoped-validation envelope" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "10 (prov: given/stated)" in t else 1)
' && pass "scoped-validation renders cited" || fail "scoped-validation renders cited" "$OUT"
# And the same brief citing the mis-typed one DOES fail.
printf 'bad {{asm:bad}}.\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F")
assert_envelope "scoped-validation cited-bad fails" false "status_cap_exceeded" "$OUT"

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All resolve-assumptions assertions passed"
