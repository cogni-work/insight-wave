#!/usr/bin/env bash
# test_overview_update.sh — contract + behaviour test for overview_update.py.
#
# overview_update.py routes both knowledge-finalize Step 10.5 overview.md writes
# (sub-step 3 the `## Recent syntheses` bullet, sub-step 3.5 the
# OVERVIEW-NARRATIVE splice) through one `with _wiki_lock(wiki_root):
# read → transform → atomic_write_text` body, replacing the prior unlocked /
# non-atomic inline-python writes.
#
# Asserts:
#   1. recent-bullet: refreshes the bullet, idempotent on the slug (re-run with
#      the same slug leaves exactly one bullet — dedups only the list item),
#      creates the heading when absent, preserves other content.
#   2. narrative-splice: inserts the OVERVIEW-NARRATIVE block after the H1 on the
#      first call, replaces ONLY its inner on the second, and preserves the
#      Recent-syntheses bullets + all other prose byte-for-byte.
#   3. Atomicity: a normal write leaves NO stray `.tmp` temp file (atomic
#      temp-file + os.replace).
#   4. Fail-soft: a missing --wiki-scripts-dir returns success:false and writes
#      NOTHING partial — the prior overview.md is left byte-for-byte intact.
#   5. Every run emits the {success, data, error} envelope.
#
# bash 3.2 + stdlib python3 only. POSIX only (the lock uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/overview_update.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: overview_update.py not found at $SCRIPT"; exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"; exit 1
fi

field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki" "$WIKI/.cogni-wiki"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"
OVERVIEW="$WIKI/wiki/overview.md"

# Seed an overview with an H1 and some human prose (no Recent-syntheses heading
# yet) so we can prove the heading is created and the prose is preserved.
printf -- '# Overview\n\nA human-authored intro paragraph that must survive.\n' > "$OVERVIEW"

# --- 1. recent-bullet: create heading + bullet -------------------------------
OUT=$(python3 "$SCRIPT" recent-bullet --wiki-root "$WIKI" \
  --slug eu-ai-act --topic "EU AI Act for SMEs" --date 2026-06-05 \
  --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["success"]')" = "True" ] && green "PASS: recent-bullet envelope success" || { red "FAIL: recent-bullet not success"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["changed"]')" = "True" ] && green "PASS: recent-bullet reports changed" || { red "FAIL: recent-bullet changed != True"; errors=$((errors+1)); }
grep -q '^## Recent syntheses$' "$OVERVIEW" && green "PASS: Recent syntheses heading created" || { red "FAIL: heading missing"; errors=$((errors+1)); }
grep -q -- '- \[2026-06-05\] \[\[eu-ai-act\]\] — EU AI Act for SMEs' "$OVERVIEW" && green "PASS: dated bullet written" || { red "FAIL: bullet missing"; errors=$((errors+1)); }
grep -q 'human-authored intro paragraph' "$OVERVIEW" && green "PASS: human prose preserved" || { red "FAIL: human prose lost"; errors=$((errors+1)); }

# --- 1b. recent-bullet: idempotent dedup on re-run ---------------------------
python3 "$SCRIPT" recent-bullet --wiki-root "$WIKI" \
  --slug eu-ai-act --topic "EU AI Act for SMEs" --date 2026-06-06 \
  --wiki-scripts-dir "$WSD" >/dev/null
N_BULLETS=$(grep -c '\[\[eu-ai-act\]\]' "$OVERVIEW")
[ "$N_BULLETS" = "1" ] && green "PASS: re-run dedups to exactly one slug bullet" || { red "FAIL: expected 1 bullet, got $N_BULLETS"; errors=$((errors+1)); }
N_HEAD=$(grep -c '^## Recent syntheses$' "$OVERVIEW")
[ "$N_HEAD" = "1" ] && green "PASS: heading not duplicated on re-run" || { red "FAIL: heading count $N_HEAD"; errors=$((errors+1)); }

# A second distinct slug coexists (dedup is per-slug, not global).
python3 "$SCRIPT" recent-bullet --wiki-root "$WIKI" \
  --slug data-act --topic "EU Data Act" --date 2026-06-06 \
  --wiki-scripts-dir "$WSD" >/dev/null
grep -q '\[\[data-act\]\]' "$OVERVIEW" && grep -q '\[\[eu-ai-act\]\]' "$OVERVIEW" \
  && green "PASS: a second slug bullet coexists" || { red "FAIL: second slug clobbered the first"; errors=$((errors+1)); }

# --- 2. narrative-splice: insert after H1, preserve bullets ------------------
cp "$OVERVIEW" "$WORK/before-splice.md"
printf -- '## State of the wiki\n\nThe base now spans AI-Act and Data-Act obligations.' > "$WORK/prose1.txt"
OUT=$(python3 "$SCRIPT" narrative-splice --wiki-root "$WIKI" \
  --prose-file "$WORK/prose1.txt" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["success"]')" = "True" ] && green "PASS: narrative-splice envelope success" || { red "FAIL: narrative-splice not success"; errors=$((errors+1)); }
grep -q 'MACHINE-OWNED:OVERVIEW-NARRATIVE:START' "$OVERVIEW" && green "PASS: OVERVIEW-NARRATIVE block inserted" || { red "FAIL: block missing"; errors=$((errors+1)); }
grep -q 'The base now spans AI-Act' "$OVERVIEW" && green "PASS: narrative prose spliced" || { red "FAIL: prose missing"; errors=$((errors+1)); }
grep -q '\[\[eu-ai-act\]\]' "$OVERVIEW" && grep -q '\[\[data-act\]\]' "$OVERVIEW" \
  && green "PASS: Recent-syntheses bullets preserved through splice" || { red "FAIL: bullets lost in splice"; errors=$((errors+1)); }
# Block sits after the H1.
H1_LINE=$(grep -n '^# Overview$' "$OVERVIEW" | head -1 | cut -d: -f1)
BLK_LINE=$(grep -n 'OVERVIEW-NARRATIVE:START' "$OVERVIEW" | head -1 | cut -d: -f1)
[ "$BLK_LINE" -gt "$H1_LINE" ] && green "PASS: block sits after the H1" || { red "FAIL: block not after H1"; errors=$((errors+1)); }

# --- 2b. narrative-splice: replace inner only, byte-preserve the rest --------
printf -- '## State of the wiki\n\nUpdated narrative after a third synthesis.' > "$WORK/prose2.txt"
cp "$OVERVIEW" "$WORK/before-replace.md"
python3 "$SCRIPT" narrative-splice --wiki-root "$WIKI" \
  --prose-file "$WORK/prose2.txt" --wiki-scripts-dir "$WSD" >/dev/null
grep -q 'Updated narrative after a third synthesis' "$OVERVIEW" && green "PASS: splice replaced inner" || { red "FAIL: inner not replaced"; errors=$((errors+1)); }
N_BLK=$(grep -c 'OVERVIEW-NARRATIVE:START' "$OVERVIEW")
[ "$N_BLK" = "1" ] && green "PASS: exactly one OVERVIEW-NARRATIVE block (no duplication)" || { red "FAIL: block count $N_BLK"; errors=$((errors+1)); }
# Everything outside the block inner is byte-identical between before/after.
mask() {
  python3 - "$1" <<'PY'
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
t=re.sub(r"(<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->\r?\n).*?(\r?\n?<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->)",
         r"\1<MASKED>\2",t,flags=re.DOTALL)
sys.stdout.write(t)
PY
}
if diff <(mask "$WORK/before-replace.md") <(mask "$OVERVIEW") >/dev/null; then
  green "PASS: replace-inner left all non-block bytes identical"
else
  red "FAIL: replace-inner changed bytes outside the block"; errors=$((errors+1))
  diff <(mask "$WORK/before-replace.md") <(mask "$OVERVIEW") || true
fi

# --- 3. Atomicity: no stray temp files left behind --------------------------
STRAY=$(find "$WIKI/wiki" -name '.overview.md.*.tmp' 2>/dev/null | wc -l | tr -d ' ')
[ "$STRAY" = "0" ] && green "PASS: no stray .tmp temp files after writes (atomic)" || { red "FAIL: $STRAY stray temp files"; errors=$((errors+1)); }

# --- 4. Fail-soft: missing wiki-scripts-dir → no partial write --------------
cp "$OVERVIEW" "$WORK/before-fail.md"
set +e
OUT=$(python3 "$SCRIPT" recent-bullet --wiki-root "$WIKI" \
  --slug should-not-write --topic "must not appear" --date 2026-06-07 \
  --wiki-scripts-dir "$WORK/does-not-exist")
RC=$?
set -e
[ "$RC" -ne 0 ] && green "PASS: missing wiki-scripts-dir returns non-zero exit" || { red "FAIL: expected non-zero exit"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["success"]')" = "False" ] && green "PASS: fail envelope success=false" || { red "FAIL: envelope not success=false"; errors=$((errors+1)); }
grep -q 'should-not-write' "$OVERVIEW" && { red "FAIL: a failed run wrote partial content"; errors=$((errors+1)); } || green "PASS: failed run wrote nothing"
diff "$WORK/before-fail.md" "$OVERVIEW" >/dev/null && green "PASS: overview.md byte-for-byte intact after fail" || { red "FAIL: overview.md mutated on a fail"; errors=$((errors+1)); }

# --- 5. Stdlib-only guard ----------------------------------------------------
if grep -Eq '^[[:space:]]*(import|from)[[:space:]]+(requests|yaml|bs4|lxml)\b' "$SCRIPT"; then
  red "FAIL: overview_update.py imports a non-stdlib dependency"; errors=$((errors+1))
else
  green "PASS: overview_update.py is stdlib-only"
fi

if [ "$errors" -eq 0 ]; then
  green "All overview_update.py tests passed."
  exit 0
else
  red "$errors overview_update.py test(s) failed."
  exit 1
fi
