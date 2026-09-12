#!/usr/bin/env bash
# Guard: the text-to-narrative skill's citation bridge works on both input shapes SKILL.md allows.
#
# WHAT THIS PINS
#   skills/text-to-narrative/scripts/bridge-citations.py explodes `[Source: Publisher](URL)` markers
#   into per-source files with `source_index` / `publisher` / `url` frontmatter and rewrites
#   the report with `[source-NN-slug.md]` markers. SKILL.md Phase 0.5 names those per-source
#   files as the citation target and their `url` as the preserved provenance, so this is the
#   mechanical half of the provenance chain — and it had no test. Two shapes are exercised
#   because `--source-path` may be a directory or a single `.md` file, and the single-file
#   shape used to break when SKILL.md passed an `--output-dir` nested under the file.
#
#   Assertions are BY SHAPE — exit status, file existence, frontmatter key lines, marker
#   presence — never on the wording of a message, because the script's diagnostics are its
#   own but a future localisation must not redden this suite.
#
# Every write goes under this run's own mktemp -d; the tracked fixture is copied, never used
# in place, because the script writes narrative-input/ beside its input.
#
# CASE LABEL SHAPE: `PASS: <id>` / `FAIL: <id>`, ids BC-prefixed, summary `RESULT:`.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
SCRIPT="$PLUGIN_DIR/skills/text-to-narrative/scripts/bridge-citations.py"
FIXTURE_DIR="$PLUGIN_DIR/tests/fixtures/narrative-source"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

if [ ! -f "$SCRIPT" ] || [ ! -d "$FIXTURE_DIR" ] || ! ls "$FIXTURE_DIR"/*.md >/dev/null 2>&1; then
  fail "BC0 inputs readable (script and fixture directory with .md files)"
  printf '%s\n' "RESULT: 1 bridge-citations case(s) failed."
  exit 1
fi
pass "BC0 inputs readable"

# ------------------------------------------------------------ BC1 directory source
mkdir -p "$TMPROOT/dir"
cp "$FIXTURE_DIR"/*.md "$TMPROOT/dir/"
out="$(python3 "$SCRIPT" --source-path "$TMPROOT/dir" --json 2>"$TMPROOT/dir.err")"
rc=$?
n_sources=$(ls "$TMPROOT/dir/narrative-input/sources/"source-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '"success": true' && [ "$n_sources" -ge 1 ] \
   && [ -f "$TMPROOT/dir/narrative-input/report-for-narrative.md" ]; then
  pass "BC1 directory source bridges into narrative-input/ with $n_sources per-source file(s)"
else
  printf '%s\n' "    exit=$rc sources=$n_sources"; cat "$TMPROOT/dir.err" | sed 's/^/    /'
  fail "BC1 directory source bridges into narrative-input/ with per-source files"
fi

# ------------------------------------------------------------ BC2 per-source frontmatter shape
bad=""
for f in "$TMPROOT/dir/narrative-input/sources/"source-*.md; do
  [ -f "$f" ] || continue
  for key in source_index publisher url; do
    grep -q "^$key:" "$f" || bad="$bad $(basename "$f"):$key"
  done
done
if [ "$n_sources" -ge 1 ] && [ -z "$bad" ]; then
  pass "BC2 every per-source file carries source_index, publisher and url frontmatter"
else
  fail "BC2 per-source frontmatter incomplete:$bad"
fi

# ------------------------------------------------------------ BC3 report markers replaced
report="$TMPROOT/dir/narrative-input/report-for-narrative.md"
if [ -f "$report" ] && grep -q '\[source-01-' "$report" && ! grep -q '\[Source:' "$report"; then
  pass "BC3 the bridged report carries [source-NN-slug.md] markers and no [Source:] citation"
else
  fail "BC3 the bridged report carries [source-NN-slug.md] markers and no [Source:] citation"
fi

# ------------------------------------------------------------ BC4 single-file source, default output dir
mkdir -p "$TMPROOT/single"
cp "$FIXTURE_DIR/findings.md" "$TMPROOT/single/findings.md"
out="$(python3 "$SCRIPT" --source-path "$TMPROOT/single/findings.md" --json 2>"$TMPROOT/single.err")"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '"success": true' \
   && [ -f "$TMPROOT/single/narrative-input/report-for-narrative.md" ] \
   && ls "$TMPROOT/single/narrative-input/sources/"source-*.md >/dev/null 2>&1; then
  pass "BC4 a single-file source bridges into narrative-input/ beside the file's parent"
else
  printf '%s\n' "    exit=$rc"; cat "$TMPROOT/single.err" | sed 's/^/    /'
  fail "BC4 a single-file source bridges into narrative-input/ beside the file's parent"
fi

# ------------------------------------------------------------ BC5 late citation is still detected
# Detection scans the whole text: a source whose first [Source:] appears after 500 lines of
# prose must still bridge.
mkdir -p "$TMPROOT/late"
{ for i in $(seq 1 520); do echo "Line $i of preamble with no citation."; done
  echo "A late claim [Source: Late Publisher](https://example.org/late)."; } > "$TMPROOT/late/report.md"
out="$(python3 "$SCRIPT" --source-path "$TMPROOT/late" --json 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '"sources_extracted": 1'; then
  pass "BC5 a citation after line 500 is detected and bridged"
else
  fail "BC5 a citation after line 500 is detected and bridged (exit $rc)"
fi

# ------------------------------------------------------------ BC6 negative: a missing source path is a failure
# The script must refuse rather than write an empty narrative-input/: non-zero exit, an envelope
# on stderr with success false, and no output directory created.
out="$(python3 "$SCRIPT" --source-path "$TMPROOT/does-not-exist" --json 2>"$TMPROOT/missing.err")"
rc=$?
if [ "$rc" -ne 0 ] && grep -q '"success": false' "$TMPROOT/missing.err" && grep -q '"error"' "$TMPROOT/missing.err" \
   && [ ! -d "$TMPROOT/does-not-exist" ] && [ ! -d "$TMPROOT/narrative-input" ]; then
  pass "BC6 a missing source path exits non-zero with a success-false envelope and writes nothing"
else
  printf '%s\n' "    exit=$rc"; sed 's/^/    /' "$TMPROOT/missing.err"
  fail "BC6 a missing source path exits non-zero with a success-false envelope and writes nothing"
fi

echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures bridge-citations case(s) failed."
  exit 1
fi
echo "RESULT: all bridge-citations cases passed."
exit 0
