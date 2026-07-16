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
#  18  verified-evidence-gate  claim/verified needs a citation.claim_id resolving to a
#      verified ClaimRecord: absent -> verified_claim_id_missing, dangling ->
#      claim_id_dangling, unverified record -> claim_not_verified, missing
#      registry -> claims_registry_unreadable, genuine evidence -> renders
#  19  incomplete-provenance  provenance_type without status -> incomplete_provenance
#  20  marker-collision-safety  re-resolving marked output does not trip the leftover checks
#  21  scoped-validation   a mis-typed UNCITED assumption does not block a brief citing a good one
#  22  submit-propagate-roundtrip  submit-assumption-claim.py end-to-end: submit is
#      idempotent, propagate refuses an unverified record, then flips the
#      assumption to verified once the ClaimRecord verifies (default layout)
#  23  link-render-mode  --mode link substitutes {{asm:slug}} ->
#      [[assumptions#<slug>|<value>]] with the (prov: type/status) marker intact,
#      the leftover check stays clean (brackets can't trip the brace-only regex),
#      and the default (value) mode is byte-for-byte unchanged
#  24  resolve-propagate  submit-assumption-claim.py resolve-propagate: refuses a
#      still-verified (not resolved) or non-'corrected' ClaimRecord, then on a
#      resolved+corrected record overwrites the assumption value, demotes status
#      verified->reviewed, stamps citation.propagated_at, and re-runs as a no-op
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

# 18 verified-evidence-gate: claim/verified is structurally within the cap but
#    must be backed by a citation.claim_id resolving to a ClaimRecord that is
#    itself verified — every unbacked shape fails loud with its own check.
CLAIMS="$TMPROOT/claims-fixture.json"

# 18a no citation.claim_id at all -> verified_claim_id_missing
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-c", "name": "C", "value": "5", "provenance_type": "claim", "status": "verified"}]}
EOF
printf '{{asm:c}}\n' > "$F"
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --claims-file "$CLAIMS")
assert_envelope "verified-no-claim-id envelope" false "verified_claim_id_missing" "$OUT"

# 18b claim_id present but the claims registry is missing -> claims_registry_unreadable
cat > "$PROV/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-c", "name": "C", "value": "5", "provenance_type": "claim",
                  "status": "verified", "citation": {"claim_id": "claim-1111"}}]}
EOF
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --claims-file "$TMPROOT/no-such-claims.json")
assert_envelope "verified-registry-missing envelope" false "claims_registry_unreadable" "$OUT"

# 18c dangling claim_id -> claim_id_dangling
cat > "$CLAIMS" <<'EOF'
{"claims": [{"id": "claim-2222", "status": "verified"}]}
EOF
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --claims-file "$CLAIMS")
assert_envelope "verified-dangling envelope" false "claim_id_dangling" "$OUT"

# 18d referenced ClaimRecord not itself verified -> claim_not_verified
cat > "$CLAIMS" <<'EOF'
{"claims": [{"id": "claim-1111", "status": "deviated"}]}
EOF
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --claims-file "$CLAIMS")
assert_envelope "verified-unverified-record envelope" false "claim_not_verified" "$OUT"

# 18e genuine evidence: claim_id resolves to a verified ClaimRecord -> renders
cat > "$CLAIMS" <<'EOF'
{"claims": [{"id": "claim-1111", "status": "verified"}]}
EOF
OUT=$(python3 "$SCRIPT" "$PROV" resolve "$F" --claims-file "$CLAIMS")
assert_envelope "verified-evidence-present envelope" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "5 (prov: claim/verified)" in t else 1)
' && pass "verified-evidence-present render" || fail "verified-evidence-present render" "$OUT"

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

# --- Submit/propagate round-trip (22) ----------------------------------------
# End-to-end over the DEFAULT layout (<project>/cogni-consult/<eng> beside
# <project>/cogni-claims/), exercising the adapter script plus the resolver's
# default engagement-relative claims lookup — no --claims-file override.
SUBMIT="$PLUGIN_DIR/scripts/submit-assumption-claim.py"
PROJ="$TMPROOT/proj"; ENG2="$PROJ/cogni-consult/rt"; mkdir -p "$ENG2"
cat > "$ENG2/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-rt", "name": "RT", "value": "7",
                  "provenance_type": "claim", "status": "reviewed",
                  "citation": {"source_url": "https://example.org/report"},
                  "created": "2026-07-11", "updated": "2026-07-11"}]}
EOF

# 22a submit appends an unverified ClaimRecord with the adapted entity_ref
OUT=$(python3 "$SUBMIT" "$ENG2" submit asm-rt)
assert_envelope "submit envelope" true "" "$OUT"
CLAIM_ID=$(echo "$OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["claim_id"])')
python3 - "$PROJ/cogni-claims/claims.json" "$CLAIM_ID" <<'PYEOF' && pass "submit record shape" || fail "submit record shape" "$(cat "$PROJ/cogni-claims/claims.json")"
import json, sys
claims = {c["id"]: c for c in json.load(open(sys.argv[1]))["claims"]}
c = claims[sys.argv[2]]
ref = c["entity_ref"]
ok = (c["status"] == "unverified" and c["submitted_by"] == "cogni-consult"
      and ref["type"] == "assumption"
      and ref["file"] == "cogni-consult/rt/assumptions.json"
      and ref["field_path"] == 'assumptions[?id=="asm-rt"].value')
sys.exit(0 if ok else 1)
PYEOF

# 22b re-submit reuses the existing record (idempotent, no duplicate)
OUT=$(python3 "$SUBMIT" "$ENG2" submit asm-rt)
assert_envelope "re-submit envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["reused"] else 1)' \
  && pass "re-submit reused" || fail "re-submit reused" "$OUT"
python3 -c 'import json,sys; sys.exit(0 if len(json.load(open(sys.argv[1]))["claims"]) == 1 else 1)' "$PROJ/cogni-claims/claims.json" \
  && pass "re-submit no duplicate" || fail "re-submit no duplicate" "$(cat "$PROJ/cogni-claims/claims.json")"

# 22c propagate refuses while the ClaimRecord is still unverified
OUT=$(python3 "$SUBMIT" "$ENG2" propagate asm-rt --claim-id "$CLAIM_ID")
assert_envelope "propagate-unverified envelope" false "claim_not_verified" "$OUT"

# 22d verify the record (simulating the cogni-claims verify pass), propagate,
#     and confirm the resolver's default claims lookup now renders verified
python3 - "$PROJ/cogni-claims/claims.json" "$CLAIM_ID" <<'PYEOF'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
for c in data["claims"]:
    if c["id"] == sys.argv[2]:
        c["status"] = "verified"
json.dump(data, open(path, "w"), indent=2)
PYEOF
OUT=$(python3 "$SUBMIT" "$ENG2" propagate asm-rt --claim-id "$CLAIM_ID")
assert_envelope "propagate-verified envelope" true "" "$OUT"
python3 - "$ENG2/assumptions.json" "$CLAIM_ID" <<'PYEOF' && pass "propagate wrote back-reference" || fail "propagate wrote back-reference" "$(cat "$ENG2/assumptions.json")"
import json, sys
e = json.load(open(sys.argv[1]))["assumptions"][0]
sys.exit(0 if e["status"] == "verified" and e["citation"]["claim_id"] == sys.argv[2] else 1)
PYEOF
F2="$ENG2/brief.md"
printf 'RT {{asm:rt}}\n' > "$F2"
OUT=$(python3 "$SCRIPT" "$ENG2" resolve "$F2")
assert_envelope "roundtrip resolve envelope" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "7 (prov: claim/verified)" in t else 1)
' && pass "roundtrip resolve renders verified" || fail "roundtrip resolve renders verified" "$OUT"

# 22e propagate is idempotent (verified is a fixed point)
OUT=$(python3 "$SUBMIT" "$ENG2" propagate asm-rt --claim-id "$CLAIM_ID")
assert_envelope "propagate-idempotent envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["changed"] is False else 1)' \
  && pass "propagate-idempotent changed=false" || fail "propagate-idempotent changed=false" "$OUT"

# 22f propagate survives an explicit null citation (envelope, not a traceback):
#     the write side must normalize a null/non-dict citation to {} before
#     assigning claim_id, mirroring the read side's `or {}` guard
python3 - "$ENG2/assumptions.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
e = data["assumptions"][0]
e["citation"] = None
e["status"] = "reviewed"
json.dump(data, open(path, "w"), indent=2)
PYEOF
OUT=$(python3 "$SUBMIT" "$ENG2" propagate asm-rt --claim-id "$CLAIM_ID" 2>/dev/null)
assert_envelope "propagate-null-citation envelope" true "" "$OUT"
python3 - "$ENG2/assumptions.json" "$CLAIM_ID" <<'PYEOF' && pass "propagate-null-citation rebuilt citation" || fail "propagate-null-citation rebuilt citation" "$(cat "$ENG2/assumptions.json")"
import json, sys
e = json.load(open(sys.argv[1]))["assumptions"][0]
sys.exit(0 if e["status"] == "verified" and e["citation"]["claim_id"] == sys.argv[2] else 1)
PYEOF

# 23 link-render mode (--mode link): {{asm:slug}} -> [[assumptions#<slug>|<value>]]
#    with the (prov: type/status) parenthetical intact, the leftover check still
#    clean (brackets can never trip the brace-only LOOSE_ASM_RE), and the default
#    (value) mode byte-for-byte unchanged.
ENGL="$TMPROOT/eng-link"
mkdir -p "$ENGL"
cat > "$ENGL/assumptions.json" <<'EOF'
{"assumptions": [
  {"id": "asm-tam-dach-2027", "name": "TAM", "value": "4.2bn EUR",
   "created": "2026-07-08", "updated": "2026-07-08"},
  {"id": "asm-conv-rate", "name": "Conversion", "value": "12%",
   "provenance_type": "estimate", "status": "reviewed",
   "created": "2026-07-08", "updated": "2026-07-08"}
]}
EOF

# 23a link-mode untyped entry -> bare wikilink, no (prov:) marker, envelope clean
FL="$TMPROOT/link-untyped.md"
printf 'TAM {{asm:tam-dach-2027}}.\n' > "$FL"
OUT=$(python3 "$SCRIPT" "$ENGL" resolve "$FL" --mode link)
assert_envelope "link-mode untyped envelope clean" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "[[assumptions#tam-dach-2027|4.2bn EUR]]" in t and "(prov:" not in t else 1)
' && pass "link-mode untyped wikilink" || fail "link-mode untyped wikilink" "$OUT"

# 23b link-mode typed entry -> wikilink + (prov: type/status) trailing the link
FL="$TMPROOT/link-typed.md"
printf 'Conv {{asm:conv-rate}}.\n' > "$FL"
OUT=$(python3 "$SCRIPT" "$ENGL" resolve "$FL" --mode link)
assert_envelope "link-mode typed envelope clean" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "[[assumptions#conv-rate|12%]] (prov: estimate/reviewed)" in t else 1)
' && pass "link-mode typed wikilink + marker" || fail "link-mode typed wikilink + marker" "$OUT"

# 23c link-mode --in-place: file rewritten with the wikilink, leftover check clean
FL="$TMPROOT/link-inplace.md"
printf '{{asm:tam-dach-2027}} and {{asm:conv-rate}}\n' > "$FL"
OUT=$(python3 "$SCRIPT" "$ENGL" resolve "$FL" --mode link --in-place)
assert_envelope "link-mode in-place envelope clean" true "" "$OUT"
grep -q '\[\[assumptions#tam-dach-2027|4.2bn EUR\]\]' "$FL" \
  && ! grep -q '{{asm:' "$FL" \
  && pass "link-mode in-place file rewritten, no leftover" || fail "link-mode in-place file rewritten" "$(cat "$FL")"

# 23e link-mode escapes a pipe in the value so the wikilink alias is not split
python3 - "$ENGL/assumptions.json" <<'PYEOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["assumptions"].append({"id": "asm-range", "name": "Range", "value": "3 | 4",
                         "created": "2026-07-08", "updated": "2026-07-08"})
json.dump(d, open(p, "w"), indent=2)
PYEOF
FL="$TMPROOT/link-pipe.md"
printf 'R {{asm:range}}\n' > "$FL"
OUT=$(python3 "$SCRIPT" "$ENGL" resolve "$FL" --mode link)
assert_envelope "link-mode pipe envelope clean" true "" "$OUT"
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if "[[assumptions#range|3 \\| 4]]" in t else 1)
' && pass "link-mode escapes pipe in alias" || fail "link-mode escapes pipe in alias" "$OUT"

# 23d default (value) mode is byte-for-byte unchanged (no brackets, literal value)
FL="$TMPROOT/link-default.md"
printf 'TAM {{asm:tam-dach-2027}}.\n' > "$FL"
OUT=$(python3 "$SCRIPT" "$ENGL" resolve "$FL")
echo "$OUT" | python3 -c '
import json, sys
t = json.load(sys.stdin)["data"]["resolved_text"]
sys.exit(0 if t == "TAM 4.2bn EUR.\n" and "[[" not in t else 1)
' && pass "default mode literal value unchanged" || fail "default mode literal value unchanged" "$OUT"

# --- Resolve/correction propagation (24) -------------------------------------
# resolve-propagate writes a resolved+corrected claim's value onto the
# assumption and demotes verified->reviewed; DEFAULT layout, adapter script.
PROJ3="$TMPROOT/proj-rc"; ENG3="$PROJ3/cogni-consult/rc"; mkdir -p "$ENG3"
cat > "$ENG3/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-rc", "name": "RC", "value": "7",
                  "provenance_type": "claim", "status": "verified",
                  "citation": {"source_url": "https://example.org/report",
                               "claim_id": "claim-rc"},
                  "created": "2026-07-11", "updated": "2026-07-11"}]}
EOF
mkdir -p "$PROJ3/cogni-claims"
cat > "$PROJ3/cogni-claims/claims.json" <<'EOF'
{"claims": [{"id": "claim-rc", "status": "verified", "resolution": null,
             "entity_ref": {"type": "assumption",
                            "file": "cogni-consult/rc/assumptions.json",
                            "field_path": "assumptions[?id==\"asm-rc\"].value"}}]}
EOF

# 24a refuses while the ClaimRecord is still 'verified' (not resolved)
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --corrected-value "9" --claim-id claim-rc)
assert_envelope "resolve-propagate-not-resolved envelope" false "claim_not_resolved" "$OUT"

# 24b resolved but a non-propagable action ('disputed' keeps the original
#     value) is refused
python3 - "$PROJ3/cogni-claims/claims.json" <<'PYEOF'
import json, sys
p = sys.argv[1]; d = json.load(open(p))
for c in d["claims"]:
    if c["id"] == "claim-rc":
        c["status"] = "resolved"; c["resolution"] = {"action": "disputed"}
json.dump(d, open(p, "w"), indent=2)
PYEOF
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --corrected-value "9" --claim-id claim-rc)
assert_envelope "resolve-propagate-non-propagable envelope" false "resolution_action_not_propagable" "$OUT"

# 24c resolved + corrected: value overwritten, status demoted verified->reviewed,
#     citation.propagated_at stamped, changed=true
python3 - "$PROJ3/cogni-claims/claims.json" <<'PYEOF'
import json, sys
p = sys.argv[1]; d = json.load(open(p))
for c in d["claims"]:
    if c["id"] == "claim-rc":
        c["resolution"] = {"action": "corrected",
                           "corrected_statement": "The value is 9."}
json.dump(d, open(p, "w"), indent=2)
PYEOF
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --corrected-value "9" --claim-id claim-rc)
assert_envelope "resolve-propagate envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json, sys
d = json.load(sys.stdin)["data"]
sys.exit(0 if d["changed"] and d["value_changed"] and d["new_value"] == "9"
         and d["old_value"] == "7" and d["status"] == "reviewed" else 1)' \
  && pass "resolve-propagate envelope shape" || fail "resolve-propagate envelope shape" "$OUT"
python3 - "$ENG3/assumptions.json" <<'PYEOF' && pass "resolve-propagate wrote value + demoted + stamped" || fail "resolve-propagate wrote value + demoted + stamped" "$(cat "$ENG3/assumptions.json")"
import json, sys
e = json.load(open(sys.argv[1]))["assumptions"][0]
sys.exit(0 if e["value"] == "9" and e["status"] == "reviewed"
         and e["citation"]["claim_id"] == "claim-rc"
         and e["citation"].get("propagated_at") else 1)
PYEOF

# 24d idempotent re-run: changed=false, assumptions.json byte-identical (no re-stamp)
BEFORE=$(cat "$ENG3/assumptions.json")
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --corrected-value "9" --claim-id claim-rc)
assert_envelope "resolve-propagate-idempotent envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["changed"] is False else 1)' \
  && pass "resolve-propagate-idempotent changed=false" || fail "resolve-propagate-idempotent changed=false" "$OUT"
[ "$BEFORE" = "$(cat "$ENG3/assumptions.json")" ] \
  && pass "resolve-propagate-idempotent file byte-identical" || fail "resolve-propagate-idempotent file byte-identical" "$(cat "$ENG3/assumptions.json")"

# 24e a corrected value on a still-'verified' assumption is refused a dangling claim
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --corrected-value "9" --claim-id claim-nope)
assert_envelope "resolve-propagate-dangling envelope" false "claim_id_dangling" "$OUT"

# 24f a 'corrected' action with no --corrected-value is refused (ENG3's claim is
#     action=corrected from 24c)
OUT=$(python3 "$SUBMIT" "$ENG3" resolve-propagate asm-rc --claim-id claim-rc)
assert_envelope "resolve-propagate-corrected-no-value envelope" false "corrected_value_required" "$OUT"

# --- Resolve/alternative_source propagation (25) -----------------------------
# alternative_source writes resolution.alternative_source_url/title onto the
# citation, leaves the value unchanged, and demotes verified->reviewed.
PROJ4="$TMPROOT/proj-as"; ENG4="$PROJ4/cogni-consult/as"; mkdir -p "$ENG4"
cat > "$ENG4/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-as", "name": "AS", "value": "7",
                  "provenance_type": "claim", "status": "verified",
                  "citation": {"source_url": "https://old.example/report",
                               "claim_id": "claim-as"},
                  "created": "2026-07-11", "updated": "2026-07-11"}]}
EOF
mkdir -p "$PROJ4/cogni-claims"
cat > "$PROJ4/cogni-claims/claims.json" <<'EOF'
{"claims": [{"id": "claim-as", "status": "resolved",
             "resolution": {"action": "alternative_source"},
             "entity_ref": {"type": "assumption",
                            "file": "cogni-consult/as/assumptions.json",
                            "field_path": "assumptions[?id==\"asm-as\"].value"}}]}
EOF

# 25a alternative_source with no alternative_source_url on the resolution is refused
OUT=$(python3 "$SUBMIT" "$ENG4" resolve-propagate asm-as --claim-id claim-as)
assert_envelope "alt-source-missing-url envelope" false "alternative_source_url_missing" "$OUT"

# 25b add the url + title: value unchanged, source updated, demoted, no --corrected-value
python3 - "$PROJ4/cogni-claims/claims.json" <<'PYEOF'
import json, sys
p = sys.argv[1]; d = json.load(open(p))
for c in d["claims"]:
    if c["id"] == "claim-as":
        c["resolution"] = {"action": "alternative_source",
                           "alternative_source_url": "https://new.example/doc",
                           "alternative_source_title": "New Source"}
json.dump(d, open(p, "w"), indent=2)
PYEOF
OUT=$(python3 "$SUBMIT" "$ENG4" resolve-propagate asm-as --claim-id claim-as)
assert_envelope "alt-source envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json, sys
d = json.load(sys.stdin)["data"]
sys.exit(0 if d["changed"] and d["value_changed"] is False
         and d["old_value"] == "7" and d["new_value"] == "7"
         and d["status"] == "reviewed" and d["action"] == "alternative_source" else 1)' \
  && pass "alt-source envelope shape" || fail "alt-source envelope shape" "$OUT"
python3 - "$ENG4/assumptions.json" <<'PYEOF' && pass "alt-source updated citation, kept value, demoted" || fail "alt-source updated citation, kept value, demoted" "$(cat "$ENG4/assumptions.json")"
import json, sys
e = json.load(open(sys.argv[1]))["assumptions"][0]
c = e["citation"]
sys.exit(0 if e["value"] == "7" and e["status"] == "reviewed"
         and c["source_url"] == "https://new.example/doc"
         and c["source_title"] == "New Source"
         and c["claim_id"] == "claim-as" and c.get("propagated_at") else 1)
PYEOF

# 25c idempotent re-run: changed=false, byte-identical
BEFORE=$(cat "$ENG4/assumptions.json")
OUT=$(python3 "$SUBMIT" "$ENG4" resolve-propagate asm-as --claim-id claim-as)
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["changed"] is False else 1)' \
  && pass "alt-source-idempotent changed=false" || fail "alt-source-idempotent changed=false" "$OUT"
[ "$BEFORE" = "$(cat "$ENG4/assumptions.json")" ] \
  && pass "alt-source-idempotent file byte-identical" || fail "alt-source-idempotent file byte-identical" "$(cat "$ENG4/assumptions.json")"

# --- Resolve/discarded propagation (26) --------------------------------------
# discarded unbinds citation.claim_id, retains the value (the {{asm:}} placeholder
# still needs one), and demotes verified->reviewed.
PROJ5="$TMPROOT/proj-di"; ENG5="$PROJ5/cogni-consult/di"; mkdir -p "$ENG5"
cat > "$ENG5/assumptions.json" <<'EOF'
{"assumptions": [{"id": "asm-di", "name": "DI", "value": "7",
                  "provenance_type": "claim", "status": "verified",
                  "citation": {"source_url": "https://example.org/report",
                               "claim_id": "claim-di"},
                  "created": "2026-07-11", "updated": "2026-07-11"}]}
EOF
mkdir -p "$PROJ5/cogni-claims"
cat > "$PROJ5/cogni-claims/claims.json" <<'EOF'
{"claims": [{"id": "claim-di", "status": "resolved",
             "resolution": {"action": "discarded", "rationale": "unsupported"},
             "entity_ref": {"type": "assumption",
                            "file": "cogni-consult/di/assumptions.json",
                            "field_path": "assumptions[?id==\"asm-di\"].value"}}]}
EOF

# 26a discarded: value retained, claim_id cleared, demoted, no --corrected-value
OUT=$(python3 "$SUBMIT" "$ENG5" resolve-propagate asm-di --claim-id claim-di)
assert_envelope "discarded envelope" true "" "$OUT"
echo "$OUT" | python3 -c 'import json, sys
d = json.load(sys.stdin)["data"]
sys.exit(0 if d["changed"] and d["value_changed"] is False
         and d["old_value"] == "7" and d["new_value"] == "7"
         and d["status"] == "reviewed" and d["action"] == "discarded" else 1)' \
  && pass "discarded envelope shape" || fail "discarded envelope shape" "$OUT"
python3 - "$ENG5/assumptions.json" <<'PYEOF' && pass "discarded cleared claim_id, kept value, demoted, stamped" || fail "discarded cleared claim_id, kept value, demoted, stamped" "$(cat "$ENG5/assumptions.json")"
import json, sys
e = json.load(open(sys.argv[1]))["assumptions"][0]
c = e["citation"]
sys.exit(0 if e["value"] == "7" and e["status"] == "reviewed"
         and "claim_id" not in c and c.get("propagated_at") else 1)
PYEOF

# 26b idempotent re-run: changed=false, byte-identical
BEFORE=$(cat "$ENG5/assumptions.json")
OUT=$(python3 "$SUBMIT" "$ENG5" resolve-propagate asm-di --claim-id claim-di)
echo "$OUT" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["changed"] is False else 1)' \
  && pass "discarded-idempotent changed=false" || fail "discarded-idempotent changed=false" "$OUT"
[ "$BEFORE" = "$(cat "$ENG5/assumptions.json")" ] \
  && pass "discarded-idempotent file byte-identical" || fail "discarded-idempotent file byte-identical" "$(cat "$ENG5/assumptions.json")"

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All resolve-assumptions assertions passed"
