#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/register-generator.py — the
# browsable assumptions.md register generator.
#
# Fixtures are heredoc'd inline — no committed JSON blobs. Each fixture builds a
# minimal engagement dir under a temp root, runs the generator, and asserts on
# the JSON envelope plus the on-disk assumptions.md.
#
# Coverage:
#   1  fully-scoped   summary-table row AND anchored ## <slug> section per record,
#                     each carrying value / provenance / source-lineage quad /
#                     used_by[] backlinks (AC1)
#   2  anchor-match   the ## <slug> heading equals id-minus-asm-prefix, i.e. the
#                     exact anchor resolve-assumptions.py --mode link points at
#   3  empty          empty registry -> "No assumptions registered yet." + marker
#   4  missing        no assumptions.json -> fail-soft empty register, success
#   5  overwrite-guard hand-authored assumptions.md (no marker) -> refused
#   6  regenerate     a marker-bearing assumptions.md is overwritten in place
#
# Usage: bash cogni-consult/tests/test_register_generator.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/register-generator.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: register-generator.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Assert the envelope's success flag. Args: <name> <expected-success> <envelope>
assert_success() {
  local name="$1" want="$2" envelope="$3"
  echo "$envelope" | ENV_SUCCESS="$want" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
sys.exit(0 if str(d["success"]).lower() == os.environ["ENV_SUCCESS"] else 1)
' && pass "$name" || fail "$name" "envelope mismatch: $envelope"
}

# 1 fully-scoped
ENG="$TMPROOT/eng1"
mkdir -p "$ENG"
cat > "$ENG/assumptions.json" <<'EOF'
{"assumptions": [
  {"id": "asm-tam-dach-2027", "name": "DACH TAM 2027", "value": "4.2bn EUR",
   "rationale": "Destatis base + 11% CAGR", "provenance_type": "claim",
   "status": "reviewed",
   "citation": {"source_url": "https://www.destatis.de/x", "entity_ref": "cogni-consult/e/asm-tam-dach-2027",
                "propagated_at": "2026-07-08T09:00:00Z", "claim_id": "claim-3f2a"},
   "used_by": [{"file": "action-fields/market/brief.md", "resolved_at": "2026-07-08T10:00:00Z"}],
   "created": "2026-07-08", "updated": "2026-07-08"},
  {"id": "asm-founder-capacity", "name": "Founder capacity", "value": "2 FTE",
   "created": "2026-07-08", "updated": "2026-07-08"}
]}
EOF
OUT=$(python3 "$SCRIPT" "$ENG")
assert_success "fully-scoped envelope" true "$OUT"
REG="$ENG/assumptions.md"
python3 - "$REG" <<'PYEOF' && pass "fully-scoped register content" || fail "fully-scoped register content" "$(cat "$REG" 2>/dev/null)"
import sys
t = open(sys.argv[1], encoding="utf-8").read()
checks = [
    "| ID | Value | Type | Status | Source | Used by |",   # summary table header
    "[tam-dach-2027](#tam-dach-2027)",                     # id links to anchor
    "| 4.2bn EUR |",                                        # value in table
    "## tam-dach-2027",                                     # anchored section
    "## founder-capacity",
    "**Value:** 4.2bn EUR",
    "**Provenance:** claim / reviewed",
    "**Rationale:** Destatis base",
    "destatis.de",                                          # source host
    "entity_ref `cogni-consult/e/asm-tam-dach-2027`",       # source-lineage quad
    "propagated 2026-07-08T09:00:00Z",
    "claim `claim-3f2a`",
    "action-fields/market/brief.md",                        # used_by backlink
    "| 1 |",                                                # used_by count column
    "_(not yet cited)_",                                    # the uncited second entry
]
missing = [c for c in checks if c not in t]
sys.exit(0 if not missing else (sys.stderr.write("missing: %r\n" % missing) or 1))
PYEOF

# 2 anchor-match: the ## heading is exactly id-minus-asm-prefix (== resolver anchor)
python3 - "$REG" <<'PYEOF' && pass "anchor matches resolver link target" || fail "anchor matches resolver link target" "$(cat "$REG")"
import sys
t = open(sys.argv[1], encoding="utf-8").read()
# resolve-assumptions.py --mode link emits [[assumptions#tam-dach-2027|...]]
sys.exit(0 if "\n## tam-dach-2027\n" in t and "asm-" not in "## tam-dach-2027" else 1)
PYEOF

# 3 empty registry
ENG="$TMPROOT/eng-empty"
mkdir -p "$ENG"
printf '{"assumptions": []}\n' > "$ENG/assumptions.json"
OUT=$(python3 "$SCRIPT" "$ENG")
assert_success "empty envelope" true "$OUT"
grep -q 'No assumptions registered yet.' "$ENG/assumptions.md" \
  && pass "empty register neutral line" || fail "empty register neutral line" "$(cat "$ENG/assumptions.md")"
grep -q 'regenerated by register-generator.py' "$ENG/assumptions.md" \
  && pass "empty register marker" || fail "empty register marker" "$(cat "$ENG/assumptions.md")"

# 4 missing assumptions.json -> fail-soft, still writes an empty register
ENG="$TMPROOT/eng-missing"
mkdir -p "$ENG"
OUT=$(python3 "$SCRIPT" "$ENG")
assert_success "missing-registry fail-soft envelope" true "$OUT"
grep -q 'No assumptions registered yet.' "$ENG/assumptions.md" \
  && pass "missing-registry empty register" || fail "missing-registry empty register" "$(cat "$ENG/assumptions.md" 2>/dev/null)"

# 5 overwrite-guard: a hand-authored register (no marker) is refused
ENG="$TMPROOT/eng-hand"
mkdir -p "$ENG"
printf '{"assumptions": []}\n' > "$ENG/assumptions.json"
printf '# My hand-written assumptions\n\nDo not clobber.\n' > "$ENG/assumptions.md"
OUT=$(python3 "$SCRIPT" "$ENG")
assert_success "overwrite-guard refuses hand-authored" false "$OUT"
grep -q 'Do not clobber.' "$ENG/assumptions.md" \
  && pass "overwrite-guard leaves hand file intact" || fail "overwrite-guard leaves hand file intact" "$(cat "$ENG/assumptions.md")"

# 6 regenerate: a marker-bearing register is overwritten in place
ENG="$TMPROOT/eng-regen"
mkdir -p "$ENG"
printf '{"assumptions": [{"id": "asm-x", "name": "X", "value": "42", "created": "2026-07-08", "updated": "2026-07-08"}]}\n' > "$ENG/assumptions.json"
printf '# Assumptions\n\nStale.\n\n---\n\n_Auto-generated assumption register — regenerated by register-generator.py; edits here are overwritten._\n' > "$ENG/assumptions.md"
OUT=$(python3 "$SCRIPT" "$ENG")
assert_success "regenerate envelope" true "$OUT"
grep -q '## x' "$ENG/assumptions.md" && ! grep -q 'Stale.' "$ENG/assumptions.md" \
  && pass "regenerate overwrites marked register" || fail "regenerate overwrites marked register" "$(cat "$ENG/assumptions.md")"

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All register-generator assertions passed"
