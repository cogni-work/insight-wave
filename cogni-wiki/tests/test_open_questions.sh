#!/usr/bin/env bash
# test_open_questions.sh — smoke test for rebuild_open_questions.py (#220, v0.0.30).
#
# 1. Fixture prep: copy legacy-wiki, migrate to per-type layout, doctor
#    karpathy-pattern.md to drop its `sources:` block (triggers a
#    deterministic `no_sources` warning from lint_wiki.py).
# 2. First rebuild → assert the page appears under "Pages without sources"
#    with a `- [ ]` marker; data.opened == 1, data.closed == 0.
# 3. Resolve the gap: restore the sources block; append a synthetic
#    `update | karpathy-pattern` log line to wiki/log.md.
# 4. Second rebuild → assert the line flipped to `- [x]` with today's date
#    and "by update" attribution; data.opened == 0, data.closed == 1.
# 5. Third rebuild (no changes) → data.opened == 0, data.closed == 0;
#    the closed line is preserved.
# 6. Pre-migration probe → standard hard-fail message.
# 7. Trim test: hand-edit the closed line's date to >90 days old.
#    --skip-trim: retained.  Without: dropped.
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
  # $1 = JSON string, $2 = data field key
  printf '%s' "$1" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(d['data'].get('$2', ''))
"
}

# ---------- prepare a migrated fixture with one no_sources gap ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null

# Doctor karpathy-pattern.md: strip its sources: block while preserving the
# rest of the frontmatter. lint_wiki.py emits a no_sources warning when the
# `sources:` list is missing or empty.
TARGET="$WIKI/wiki/concepts/karpathy-pattern.md"
python3 - "$TARGET" <<'PY'
import sys, re
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
# Drop "sources:\n  - <line>" entries from the frontmatter block.
text = re.sub(r"^sources:\n(?:  - .*\n)+", "", text, count=1, flags=re.MULTILINE)
open(p, "w", encoding="utf-8").write(text)
PY
green "fixture prepared (karpathy-pattern.md sources removed)"

# ---------- 1) first rebuild → item opens ----------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI")
assert_success_json "first rebuild" "$OUT"

OPENED=$(json_get "$OUT" opened)
CLOSED=$(json_get "$OUT" closed)
[ "$OPENED" = "1" ] || fail "first run: expected opened=1, got $OPENED"
[ "$CLOSED" = "0" ] || fail "first run: expected closed=0, got $CLOSED"
green "first rebuild: opened=1, closed=0"

OQ="$WIKI/wiki/open_questions.md"
[ -f "$OQ" ] || fail "open_questions.md not created"
grep -q '^## Pages without sources' "$OQ" || fail "Pages without sources section missing"
grep -qE '^- \[ \] `karpathy-pattern` —' "$OQ" || fail "open item not found for karpathy-pattern"
green "open item rendered correctly"

# ---------- 2) resolve the gap ----------
# Restore karpathy-pattern.md by re-copying the original from the fixture tree.
ORIG="$FIXTURES/legacy-wiki/wiki/pages/karpathy-pattern.md"
cp "$ORIG" "$TARGET"
TODAY=$(date -u +%Y-%m-%d)
printf '\n## [%s] update | karpathy-pattern — restored sources\n' "$TODAY" >> "$WIKI/wiki/log.md"
green "gap resolved (sources restored, log line appended)"

# ---------- 3) second rebuild → item closes ----------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI")
assert_success_json "second rebuild" "$OUT"

OPENED=$(json_get "$OUT" opened)
CLOSED=$(json_get "$OUT" closed)
[ "$OPENED" = "0" ] || fail "second run: expected opened=0, got $OPENED"
[ "$CLOSED" = "1" ] || fail "second run: expected closed=1, got $CLOSED"
green "second rebuild: opened=0, closed=1"

CLOSED_RE="^- \[x\] ~~\`karpathy-pattern\` — .*~~ — closed $TODAY by update$"
if ! grep -qE "$CLOSED_RE" "$OQ"; then
  red "closed line not found or wrong shape; file content:"
  cat "$OQ"
  exit 1
fi
green "closed line rendered correctly with attribution"

# ---------- 4) third rebuild → idempotent ----------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI")
assert_success_json "third rebuild" "$OUT"
OPENED=$(json_get "$OUT" opened)
CLOSED=$(json_get "$OUT" closed)
[ "$OPENED" = "0" ] || fail "third run: expected opened=0, got $OPENED"
[ "$CLOSED" = "0" ] || fail "third run: expected closed=0, got $CLOSED"
grep -qE "$CLOSED_RE" "$OQ" || fail "closed line lost on idempotent re-run"
green "idempotent: opened=0, closed=0; closed line preserved"

# ---------- 5) pre-migration probe ----------
cp -R "$FIXTURES/legacy-wiki" "$WORKDIR/legacy-wiki"
OUT=$(python3 "$SCRIPT" --wiki-root "$WORKDIR/legacy-wiki" 2>/dev/null || true)
RESULT=$(printf '%s' "$OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
print("ok" if (not d.get("success")) and ("pre-migration" in d.get("error", "")) else "bad")
' 2>/dev/null || echo "parse-error")
[ "$RESULT" = "ok" ] || fail "pre-migration probe: expected success:false with pre-migration message; got: $OUT"
green "pre-migration probe: hard-fail with migration message"

# ---------- 6) trim test ----------
# Hand-edit the closed line's date to 100 days ago. Then:
#   - --skip-trim → still present.
#   - default     → trimmed.
OLD_DATE=$(python3 -c "
import datetime
print((datetime.date.today() - datetime.timedelta(days=100)).isoformat())
")
sed -i.bak "s/closed $TODAY by update/closed $OLD_DATE by update/" "$OQ"
rm -f "$OQ.bak"

OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --skip-trim)
assert_success_json "skip-trim run" "$OUT"
TRIMMED=$(json_get "$OUT" trimmed)
[ "$TRIMMED" = "0" ] || fail "skip-trim: expected trimmed=0, got $TRIMMED"
grep -qE "closed $OLD_DATE by update" "$OQ" || fail "skip-trim: closed line should still be present"
green "trim test: --skip-trim preserves >90d closed item"

# Now hand-edit again (the previous run rewrote the file with the same old date).
sed -i.bak "s/closed $TODAY by update/closed $OLD_DATE by update/" "$OQ" 2>/dev/null || true
rm -f "$OQ.bak"
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI")
assert_success_json "trim run" "$OUT"
TRIMMED=$(json_get "$OUT" trimmed)
[ "$TRIMMED" = "1" ] || fail "trim run: expected trimmed=1, got $TRIMMED"
grep -qE "closed $OLD_DATE" "$OQ" && fail "trim run: closed line should be gone"
green "trim test: 90d-old closed item dropped"

green "ALL TESTS PASS"
