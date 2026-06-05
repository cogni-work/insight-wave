#!/usr/bin/env bash
# test_index_machine_leadin.sh — lock the machine-managed portal lead-in
# contract (#491): wiki_index_update.py --set-leadin / --get-leadin author and
# refresh a MACHINE-OWNED:PORTAL-LEADIN span the engine owns, while NEVER
# touching a non-sentineled human lead-in (the existing "Protected lead-in
# guarantee" still holds) and ALWAYS preserving the bullet block.
#
# Cases:
#   1. --set-leadin on a bullets-only section: span inserted ABOVE the bullets;
#      bullets preserved + still alphabetised.
#   2. --set-leadin refresh of an existing machine span: only the span changes;
#      a preceding HUMAN lead-in and the bullets survive byte-for-byte; stamp
#      reflects the new bullet count.
#   3. --set-leadin on theme X never touches a non-sentineled human lead-in on
#      theme Y.
#   4. --get-leadin round-trips a set span and returns "" for a human-only /
#      bullets-only section.
#   5. empty --leadin-file removes the machine span, leaving human prose +
#      bullets intact.
#
# Mirrors tests/test_index_leadin_preserve.sh. bash 3.2 + python3 stdlib only.
# Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPDATE="$PLUGIN_ROOT/skills/wiki-ingest/scripts/wiki_index_update.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"
INDEX="$WIKI/wiki/index.md"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; printf -- '----- index.md -----\n'; cat "$INDEX" 2>/dev/null; exit 1; }

HUMAN_LEADIN="Human-curated framing for this theme — never touched by the engine."
MACHINE_A="Engine framing v1. Start with the registration duties."
MACHINE_B="Engine framing v2. Now also covers the conformity-assessment path."

# ---------- seed a curated portal-shaped index ----------
mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

- [[alpha-synthesis]] — first synthesis
- [[omega-synthesis]] — last synthesis

## Questions

$HUMAN_LEADIN

- [[first-question]] — a human-led theme
EOF

green "seeded portal index (## Syntheses bullets-only; ## Questions human lead-in + 1 bullet)"

has_line() { grep -qF "$1" "$INDEX"; }
count_pat() { grep -cE "$1" "$INDEX" || true; }

# =====================================================================
# CASE 1 — set machine lead-in on a bullets-only section.
# =====================================================================
printf '%s' "$MACHINE_A" | python3 "$UPDATE" --wiki-root "$WIKI" \
  --set-leadin --category "Syntheses" --leadin-file - --refreshed-date 2026-06-05 >/dev/null

has_line "$MACHINE_A" || fail "Case 1: machine lead-in not inserted under ## Syntheses"
has_line "MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-06-05 bullets:2" \
  || fail "Case 1: START sentinel/stamp (bullets:2) missing"
has_line "MACHINE-OWNED:PORTAL-LEADIN:END" || fail "Case 1: END sentinel missing"
has_line "[[alpha-synthesis]]" && has_line "[[omega-synthesis]]" \
  || fail "Case 1: bullets lost after inserting machine lead-in"
green "Case 1: machine span inserted, stamp bullets:2, bullets preserved"

# the span must sit ABOVE the first bullet under ## Syntheses
python3 - "$INDEX" <<'PY' || exit 1
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_sec = False; seen_span = False
for ln in lines:
    if ln.strip() == "## Syntheses":
        in_sec = True; continue
    if in_sec and ln.startswith("## "):
        break
    if in_sec and "PORTAL-LEADIN:START" in ln:
        seen_span = True
    if in_sec and ln.startswith("- [[") and not seen_span:
        print("FAIL: a bullet precedes the machine lead-in span under ## Syntheses")
        sys.exit(1)
sys.exit(0 if seen_span else 1)
PY
green "Case 1: span precedes the bullet block"

# =====================================================================
# CASE 2 — refresh the existing machine span (## Syntheses).
# Bullets unchanged (still 2) so the stamp stays bullets:2; only inner changes.
# =====================================================================
printf '%s' "$MACHINE_B" | python3 "$UPDATE" --wiki-root "$WIKI" \
  --set-leadin --category "Syntheses" --leadin-file - --refreshed-date 2026-07-01 >/dev/null

has_line "$MACHINE_B" || fail "Case 2: refreshed machine lead-in not present"
has_line "$MACHINE_A" && fail "Case 2: old machine lead-in prose lingered after refresh"
has_line "MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-07-01 bullets:2" \
  || fail "Case 2: stamp not refreshed to 2026-07-01 bullets:2"
[ "$(count_pat '^- \[\[(alpha|omega)-synthesis\]\]')" = "2" ] \
  || fail "Case 2: bullet set changed during refresh"
[ "$(count_pat 'PORTAL-LEADIN:START')" = "1" ] \
  || fail "Case 2: more than one machine span exists after refresh"
green "Case 2: only the span changed; bullets + single-span invariant hold"

# =====================================================================
# CASE 3 — set machine lead-in on ## Syntheses must NOT touch the human
# lead-in on ## Questions (already true from Cases 1-2, assert explicitly).
# =====================================================================
has_line "$HUMAN_LEADIN" || fail "Case 3: human lead-in on ## Questions was lost"
# the human lead-in must remain NON-sentineled (no machine span under ## Questions)
python3 - "$INDEX" <<'PY' || exit 1
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_sec = False
for ln in lines:
    if ln.strip() == "## Questions":
        in_sec = True; continue
    if in_sec and ln.startswith("## "):
        break
    if in_sec and "PORTAL-LEADIN" in ln:
        print("FAIL: ## Questions human lead-in was converted to a machine span")
        sys.exit(1)
sys.exit(0)
PY
green "Case 3: human lead-in on the untouched theme stays human (no sentinel)"

# =====================================================================
# CASE 4 — --get-leadin round-trips the machine span and returns "" for a
# human-only section.
# =====================================================================
GOT=$(python3 "$UPDATE" --wiki-root "$WIKI" --get-leadin --category "Syntheses")
echo "$GOT" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["success"] is True, d
data = d["data"]
assert data["has_machine_leadin"] is True, data
assert data["leadin"].strip().startswith("Engine framing v2"), repr(data["leadin"])
print("OK")
' >/dev/null || fail "Case 4: --get-leadin did not round-trip the machine span"

GOTQ=$(python3 "$UPDATE" --wiki-root "$WIKI" --get-leadin --category "Questions")
echo "$GOTQ" | python3 -c '
import json, sys
d = json.load(sys.stdin)
data = d["data"]
assert data["has_machine_leadin"] is False, data
assert data["leadin"] == "", repr(data["leadin"])
print("OK")
' >/dev/null || fail "Case 4: --get-leadin reported a machine lead-in on a human-only section"
green "Case 4: --get-leadin round-trips machine span, '' for human-only section"

# =====================================================================
# CASE 5 — empty --leadin-file removes the machine span; human prose +
# bullets survive. Remove on ## Syntheses (machine span present).
# =====================================================================
RESULT=$(printf '' | python3 "$UPDATE" --wiki-root "$WIKI" \
  --set-leadin --category "Syntheses" --leadin-file - 2>/dev/null)
echo "$RESULT" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["data"]["action"] == "removed", d
print("OK")
' >/dev/null || fail "Case 5: empty --leadin-file did not report action=removed"
[ "$(count_pat 'PORTAL-LEADIN')" = "0" ] || fail "Case 5: machine span not removed"
has_line "[[alpha-synthesis]]" && has_line "[[omega-synthesis]]" \
  || fail "Case 5: bullets lost when removing the span"
has_line "$HUMAN_LEADIN" || fail "Case 5: human lead-in on the other theme disturbed"
green "Case 5: empty --leadin-file removes the span; bullets + human prose intact"

# =====================================================================
# CASE 6 — --set-leadin on a section that already has a HUMAN (non-sentineled)
# lead-in is refused: no machine span is inserted, human prose intact.
# =====================================================================
RESULT6=$(printf 'Engine wants in.' | python3 "$UPDATE" --wiki-root "$WIKI" \
  --set-leadin --category "Questions" --leadin-file - 2>/dev/null)
echo "$RESULT6" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["data"]["action"] == "skipped_human_leadin", d
print("OK")
' >/dev/null || fail "Case 6: set-leadin over a human lead-in did not report skipped_human_leadin"
has_line "$HUMAN_LEADIN" || fail "Case 6: human lead-in disturbed by a refused set-leadin"
[ "$(count_pat 'PORTAL-LEADIN')" = "0" ] \
  || fail "Case 6: a machine span was inserted over a human lead-in (contract violation)"
has_line "Engine wants in." && fail "Case 6: engine prose leaked into a human-owned section"
green "Case 6: set-leadin refuses to clutter a human-owned lead-in (skipped_human_leadin)"

green "ALL TESTS PASS"
