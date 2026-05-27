#!/usr/bin/env bash
# test_index_summary_clamp.sh — assert wiki_index_update.py's opt-in
# `--max-summary` word-boundary clamp (#324, v0.0.47).
#
# Background: the #311 German bake-in produced wiki/index.md one-liners cut
# MID-WORD ("…Sonderka" instead of "…Sonderkategorien von Daten"). The cut was
# LLM-side (honoring a "≤180 chars" authoring contract), and wiki_index_update.py
# stored the fragment verbatim. v0.0.47 adds a deterministic backstop:
# `_wikilib.clamp_summary` cuts on a WORD boundary + appends '…', wired through
# the opt-in `--max-summary` arg. Default (no flag) stays byte-identical verbatim,
# so every other caller is unaffected.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$PLUGIN_ROOT/skills/wiki-ingest/scripts"
UPDATE="$SCRIPTS/wiki_index_update.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

# ---------- seed a minimal wiki/index.md ----------
mkdir -p "$WIKI/wiki"
cat > "$WIKI/wiki/index.md" <<EOF
# Index

## Sources
EOF

# Extract the stored summary for <slug> from the index (text after "]] — ").
extract_summary() {
  python3 - "$WIKI/wiki/index.md" "$1" <<'PY'
import sys
idx, slug = sys.argv[1], sys.argv[2]
needle = "[[%s]] — " % slug
for line in open(idx, encoding="utf-8").read().splitlines():
    if needle in line:
        sys.stdout.write(line.split("]] — ", 1)[1])
        break
PY
}

run_insert() {  # slug summary [extra-args...]
  local slug="$1" summary="$2"; shift 2
  python3 "$UPDATE" --wiki-root "$WIKI" --slug "$slug" \
    --summary "$summary" --category "Sources" "$@"
}

# =====================================================================
# (e) + core: direct unit tests of clamp_summary (import the function).
# The killer invariant: the clamped output's words are an EXACT PREFIX of
# the input's words — proving no word is ever split. Plus the exact #324
# case ("Sonderkategorien" is never cut to "Sonderka").
# =====================================================================
python3 - "$SCRIPTS" <<'PY' || { red "FAIL: clamp_summary unit checks"; exit 1; }
import sys
sys.path.insert(0, sys.argv[1])
from _wikilib import clamp_summary

def words(s): return " ".join(s.split()).split()

# short input, flag present → verbatim, no ellipsis
s = "A crisp one-line summary."
assert clamp_summary(s, 240) == s, "short input should pass verbatim"
assert "…" not in clamp_summary(s, 240)

# exactly at the ceiling → verbatim
s_exact = "x" * 240
assert clamp_summary(s_exact, 240) == s_exact, "len == max_len passes verbatim"

# long input → clamps on a word boundary, ends with ellipsis, len <= max
s_long = ("Die Verordnung legt umfassende Pflichten zur Daten-Governance "
          "Transparenz und Aufsicht fest und beschreibt zahlreiche Ausnahmen "
          "Schwellenwerte Uebergangsfristen und Sonderregelungen die fuer "
          "Anbieter und Betreiber von Hochrisiko-Systemen im Detail gelten.")
assert len(s_long) > 240
out = clamp_summary(s_long, 240)
assert out.endswith("…"), "clamped output must end with an ellipsis"
assert len(out) <= 240, "clamped output must be within the ceiling (codepoints)"
ow = words(out[:-1])  # drop the trailing ellipsis
assert ow == words(s_long)[: len(ow)], "output words must be an exact prefix of input words (no mid-word cut)"

# German: ä/ö/ü/ß survive, count as 1 codepoint, cut stays on a word boundary
g = ("Diese Seite beschreibt die Daten-Governance-Pflichten für Anbieter und "
     "die Ausnahme für besondere Kategorien personenbezogener Daten zur "
     "Verhütung und Korrektur von Verzerrungen in Hochrisiko-Systemen gemäß "
     "der Verordnung über künstliche Intelligenz der Europäischen Union.")
assert len(g) > 240
go = clamp_summary(g, 240)
assert go.endswith("…")
assert len(go) <= 240
assert "ü" in go and "ä" in go, "umlauts must survive"
gw = words(go[:-1])
assert gw == words(g)[: len(gw)], "German output words must be an exact prefix (no mid-word, valid encoding)"

# the exact #324 case: a slice that naively lands inside "Sonderkategorien"
# must back off to the previous word boundary, never emit "Sonderka…".
base = "Art 10 regelt die Daten-Governance und eine Ausnahme fuer "
sk = base + "Sonderkategorien von Daten zur Bias-Korrektur."
# choose a ceiling whose naive [:max-1] slice lands inside "Sonderkategorien"
naive_cut = len(base) + len("Sonderka")  # mid-word position
L = naive_cut + 1                          # so head = one_line[:L-1] ends mid "Sonderka"
o = clamp_summary(sk, L)
assert o.endswith("…")
assert not o.rstrip("…").endswith("Sonderka"), "#324: must not cut Sonderkategorien mid-word"
ow2 = words(o[:-1])
assert ow2 == words(sk)[: len(ow2)], "#324: output words are an exact prefix (whole words only)"
assert ow2[-1] == "fuer", "#324: clamp backs off to the last whole word before the long token"

# empty / whitespace-only input is safe
assert clamp_summary("", 240) == ""
assert clamp_summary("   ", 240) == ""

# non-positive max_len must not negative-slice into a near-full string —
# the max(0, max_len - 1) guard bounds it to just the ellipsis.
long = "The quick brown fox jumps over the lazy dog repeatedly today"
assert clamp_summary(long, 0) == "…", clamp_summary(long, 0)
assert clamp_summary(long, -3) == "…", clamp_summary(long, -3)
assert clamp_summary(long, 1) == "…", clamp_summary(long, 1)

print("clamp_summary unit checks OK")
PY
green "(e) clamp_summary unit checks pass (word-prefix invariant + exact #324 case + German + edges)"

# =====================================================================
# (a) e2e: a >240-char summary with --max-summary 240 lands clamped.
# =====================================================================
LONG=$(python3 -c "print('Die Verordnung legt umfassende Pflichten zur Daten-Governance Transparenz und Aufsicht fest und beschreibt zahlreiche Ausnahmen Schwellenwerte Uebergangsfristen und Sonderregelungen die fuer Anbieter und Betreiber von Hochrisiko-Systemen im Detail gelten sollen.')")
run_insert long-clamped "$LONG" --max-summary 240 >/dev/null
STORED=$(extract_summary long-clamped)
python3 - "$LONG" "$STORED" <<'PY' || { red "FAIL: (a) e2e --max-summary 240 clamp"; exit 1; }
import sys
src, stored = sys.argv[1], sys.argv[2]
def words(s): return " ".join(s.split()).split()
assert len(src) > 240, "fixture must exceed the ceiling"
assert stored.endswith("…"), "stored line must be clamped with an ellipsis"
assert len(stored) <= 240, "stored summary must be within the ceiling"
ow = words(stored[:-1])
assert ow == words(src)[: len(ow)], "stored words must be an exact prefix of the source (no mid-word)"
print("ok")
PY
green "(a) >240-char summary clamped on a word boundary through the script"

# =====================================================================
# (b) e2e: a SHORT summary WITH the flag passes verbatim (no ellipsis).
# =====================================================================
SHORT="Overview of the EU AI Act data-governance duties."
run_insert short-with-flag "$SHORT" --max-summary 240 >/dev/null
STORED_B=$(extract_summary short-with-flag)
[ "$STORED_B" = "$SHORT" ] || { red "FAIL: (b) short summary with flag was altered"; printf 'got: %s\n' "$STORED_B"; exit 1; }
case "$STORED_B" in *…*) red "FAIL: (b) short summary gained an ellipsis"; exit 1;; esac
green "(b) short summary with --max-summary passes verbatim (no ellipsis)"

# =====================================================================
# (c) e2e: NO flag → verbatim passthrough even for a >240-char summary
#     (backward-compat: every other caller is byte-identical).
# =====================================================================
run_insert no-flag-verbatim "$LONG" >/dev/null
STORED_C=$(extract_summary no-flag-verbatim)
[ "$STORED_C" = "$LONG" ] || { red "FAIL: (c) no-flag insert was not stored verbatim"; printf 'got: %s\n' "$STORED_C"; exit 1; }
case "$STORED_C" in *…*) red "FAIL: (c) no-flag insert gained an ellipsis"; exit 1;; esac
green "(c) no --max-summary flag stores the summary verbatim (backward-compat)"

# =====================================================================
# (d) e2e: a German >240-char summary with ä/ö/ü clamps on a word boundary
#     with valid encoding and a complete trailing word.
# =====================================================================
GERMAN=$(python3 -c "print('Diese Seite beschreibt die Daten-Governance-Pflichten für Anbieter und die Ausnahme für besondere Kategorien personenbezogener Daten zur Verhütung und Korrektur von Verzerrungen in Hochrisiko-Systemen gemäß der Verordnung über künstliche Intelligenz der Europäischen Union.')")
run_insert german-clamped "$GERMAN" --max-summary 240 >/dev/null
STORED_D=$(extract_summary german-clamped)
python3 - "$GERMAN" "$STORED_D" <<'PY' || { red "FAIL: (d) German e2e clamp"; exit 1; }
import sys
src, stored = sys.argv[1], sys.argv[2]
def words(s): return " ".join(s.split()).split()
assert len(src) > 240
assert stored.endswith("…")
assert len(stored) <= 240
assert "ü" in stored, "umlaut must survive the round-trip through the script"
ow = words(stored[:-1])
assert ow == words(src)[: len(ow)], "German stored words must be an exact prefix (no mid-word)"
print("ok")
PY
green "(d) German >240-char summary clamps on a word boundary with valid encoding"

green "ALL TESTS PASS"
