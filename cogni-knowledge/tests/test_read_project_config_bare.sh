#!/usr/bin/env bash
# test_read_project_config_bare.sh - regression test for A1.
#
# Asserts that read-project-config.py --bare prints the resolved value
# directly to stdout (no JSON envelope), errors go to stderr with exit 1,
# and the default envelope mode is unchanged.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/read-project-config.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: read-project-config.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

PROJ="$WORK/proj"
mkdir -p "$PROJ/.metadata"
cat > "$PROJ/.metadata/project-config.json" <<'JSON'
{
  "slug": "test",
  "report_source": "hybrid",
  "topic": "test topic"
}
JSON

# Case 1: --bare on a present field prints exactly the value + newline.
OUT=$(python3 "$SCRIPT" --project-path "$PROJ" --field report_source --default web --bare)
if [ "$OUT" = "hybrid" ]; then
  green "PASS: --bare prints field value to stdout"
else
  red "FAIL: --bare expected 'hybrid', got '$OUT'"
  errors=$((errors + 1))
fi

# Case 2: --bare on a missing field falls back to --default.
OUT=$(python3 "$SCRIPT" --project-path "$PROJ" --field nonexistent --default fallback-default --bare)
if [ "$OUT" = "fallback-default" ]; then
  green "PASS: --bare missing field falls back to --default"
else
  red "FAIL: --bare missing field expected 'fallback-default', got '$OUT'"
  errors=$((errors + 1))
fi

# Case 3: --bare on a missing config file falls back to --default.
EMPTY_PROJ="$WORK/empty-proj"
mkdir -p "$EMPTY_PROJ"
OUT=$(python3 "$SCRIPT" --project-path "$EMPTY_PROJ" --field report_source --default web --bare)
if [ "$OUT" = "web" ]; then
  green "PASS: --bare missing file falls back to --default"
else
  red "FAIL: --bare missing file expected 'web', got '$OUT'"
  errors=$((errors + 1))
fi

# Case 4: malformed JSON - --bare exits 1, stderr non-empty, stdout empty.
BAD_PROJ="$WORK/bad-proj"
mkdir -p "$BAD_PROJ/.metadata"
echo 'not valid json' > "$BAD_PROJ/.metadata/project-config.json"
set +e
OUT_STDOUT=$(python3 "$SCRIPT" --project-path "$BAD_PROJ" --field report_source --default web --bare 2>"$WORK/stderr.log")
RC=$?
set -e
STDERR_CONTENT=$(cat "$WORK/stderr.log")
if [ "$RC" -eq 1 ] && [ -z "$OUT_STDOUT" ] && [ -n "$STDERR_CONTENT" ]; then
  green "PASS: --bare malformed JSON yields empty stdout + non-empty stderr + exit 1"
else
  red "FAIL: --bare malformed JSON: rc=$RC, stdout='$OUT_STDOUT', stderr='$STDERR_CONTENT'"
  errors=$((errors + 1))
fi

# Case 5: default envelope mode (no --bare) - the JSON envelope is intact.
OUT=$(python3 "$SCRIPT" --project-path "$PROJ" --field report_source --default web)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['value']=='hybrid'; print('OK')" | grep -q OK; then
  green "PASS: default envelope mode unchanged (regression check)"
else
  red "FAIL: default envelope mode broken"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# Case 6: --raw alias works the same.
OUT=$(python3 "$SCRIPT" --project-path "$PROJ" --field report_source --default web --raw)
if [ "$OUT" = "hybrid" ]; then
  green "PASS: --raw alias matches --bare"
else
  red "FAIL: --raw alias expected 'hybrid', got '$OUT'"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All A1 --bare cases pass."
