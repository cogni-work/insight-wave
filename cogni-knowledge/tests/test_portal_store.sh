#!/usr/bin/env bash
# test_portal_store.sh — #491 curated-portal auto-refresh (option 4b) APPLY-path
# invariants, driving the REAL cogni-wiki wiki_index_update.py --set-leadin /
# --get-leadin primitive + the _knowledge_lib overview-splice helpers exactly as
# knowledge-finalize Step 10.5 sub-step 3.5 does. The portal-narrator LLM agent
# is not run in CI — this exercises the deterministic engine beneath it.
#
# Asserts:
#   1. --set-leadin on an engine-owned (sentineled) section refreshes ONLY the
#      machine span; a human (non-sentineled) lead-in on another theme + all
#      bullets survive byte-for-byte.
#   2. --set-leadin on a section with a human lead-in is REFUSED
#      (skipped_human_leadin) — the engine never clutters human framing.
#   3. --set-leadin on a no-lead-in bullets-only section inserts a span above the
#      bullets.
#   4. The overview narrative splice (_knowledge_lib.upsert_machine_block) inserts
#      on first run, replaces on later runs, and preserves ## Recent syntheses.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KNOWLEDGE_SCRIPTS="$PLUGIN_ROOT/scripts"
UPDATE="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts/wiki_index_update.py"

WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"
INDEX="$WIKI/wiki/index.md"
OVERVIEW="$WIKI/wiki/overview.md"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; printf -- '----- index.md -----\n'; cat "$INDEX" 2>/dev/null; exit 1; }

if [ ! -f "$UPDATE" ]; then
  red "FAIL: cogni-wiki wiki_index_update.py not found at $UPDATE (sibling checkout required)"
  exit 1
fi

HUMAN_LEADIN="Human-curated framing for the questions theme — the engine must never touch this."

mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-01-01 bullets:2 -->
Old engine framing for syntheses.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

- [[alpha-synthesis]] — first
- [[omega-synthesis]] — last

## Questions

$HUMAN_LEADIN

- [[q-one]] — a human-led theme

## Sources

- [[src-a]] — a source
- [[src-b]] — another source
EOF

has_line() { grep -qF "$1" "$INDEX"; }
count_pat() { grep -cE "$1" "$INDEX" || true; }

# === 1. refresh an engine-owned span; human + bullets survive ============
printf 'New engine framing for syntheses, run N.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Syntheses" --leadin-file - \
  --refreshed-date 2026-06-05 >/dev/null

has_line "New engine framing for syntheses, run N." \
  || fail "1: refreshed engine span not present"
has_line "Old engine framing for syntheses." \
  && fail "1: old engine span lingered"
has_line "refreshed:2026-06-05 bullets:2" || fail "1: stamp not refreshed"
has_line "$HUMAN_LEADIN" || fail "1: human lead-in on ## Questions disturbed"
for b in alpha-synthesis omega-synthesis q-one src-a src-b; do
  has_line "[[$b]]" || fail "1: bullet [[$b]] lost during refresh"
done
green "1: engine span refreshed; human lead-in + all bullets preserved"

# === 2. set-leadin over a human lead-in is refused =======================
R2=$(printf 'Engine tries to clutter.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Questions" --leadin-file - 2>/dev/null)
echo "$R2" | python3 -c '
import json, sys
d = json.load(sys.stdin)
assert d["data"]["action"] == "skipped_human_leadin", d
print("OK")
' >/dev/null || fail "2: set-leadin over a human lead-in not refused"
has_line "Engine tries to clutter." && fail "2: engine prose leaked into a human section"
has_line "$HUMAN_LEADIN" || fail "2: human lead-in disturbed by a refused call"
green "2: set-leadin refuses to clutter a human-owned lead-in"

# === 3. insert on a no-lead-in bullets-only section ======================
printf 'Engine framing for sources.' | python3 "$UPDATE" \
  --wiki-root "$WIKI" --set-leadin --category "Sources" --leadin-file - \
  --refreshed-date 2026-06-05 >/dev/null
has_line "Engine framing for sources." || fail "3: span not inserted under ## Sources"
# the span must precede the first bullet under ## Sources
python3 - "$INDEX" <<'PY' || exit 1
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_sec = False; seen_span = False
for ln in lines:
    if ln.strip() == "## Sources":
        in_sec = True; continue
    if in_sec and ln.startswith("## "):
        break
    if in_sec and "PORTAL-LEADIN:START" in ln:
        seen_span = True
    if in_sec and ln.startswith("- [[") and not seen_span:
        print("FAIL: bullet precedes the inserted span under ## Sources"); sys.exit(1)
sys.exit(0 if seen_span else 1)
PY
green "3: span inserted above the bullets on a no-lead-in section"

# === 4. overview narrative splice (upsert) round-trip ====================
cat > "$OVERVIEW" <<'EOF'
# Overview

## Recent syntheses

- [2026-06-05] [[alpha-synthesis]] — first
EOF

OVERVIEW="$OVERVIEW" KNOWLEDGE_SCRIPTS="$KNOWLEDGE_SCRIPTS" python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import upsert_machine_block, extract_machine_block
p = os.environ["OVERVIEW"]
text = open(p, encoding="utf-8").read()
# first run: insert after the H1, above ## Recent syntheses
text = upsert_machine_block(text, "OVERVIEW-NARRATIVE", "State of the wiki, run 1.")
assert extract_machine_block(text, "OVERVIEW-NARRATIVE") == "State of the wiki, run 1.", text
assert text.index("OVERVIEW-NARRATIVE") < text.index("Recent syntheses"), text
assert text.startswith("# Overview"), repr(text[:40])
# later run: replace only the inner; Recent syntheses preserved
text2 = upsert_machine_block(text, "OVERVIEW-NARRATIVE", "State of the wiki, run 2.")
assert extract_machine_block(text2, "OVERVIEW-NARRATIVE") == "State of the wiki, run 2.", text2
assert "State of the wiki, run 1." not in text2
assert "## Recent syntheses" in text2 and "[[alpha-synthesis]]" in text2, text2
# idempotent: identical inner -> byte-identical text
assert upsert_machine_block(text2, "OVERVIEW-NARRATIVE", "State of the wiki, run 2.") == text2
print("OK")
' >/dev/null || fail "4: overview narrative upsert round-trip failed"
green "4: overview narrative splice inserts, replaces, preserves Recent syntheses, idempotent"

green "ALL TESTS PASS"
