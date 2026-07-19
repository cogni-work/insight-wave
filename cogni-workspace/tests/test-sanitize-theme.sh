#!/usr/bin/env bash
# Regression test for the shared theme-value guard (scripts/sanitize-theme.py)
# and its wiring into the workspace-dashboard renderer.
#
# Contract under test (issue #1129): an operator-supplied --design-variables
# value carrying a stylesheet/markup breakout (e.g. "#000</style><script>...")
# must be rejected before it reaches the generated <style> block, with the
# renderer falling back to its built-in palette for that key.
#
# stdlib-only: bash + python3, no pip deps. Mirrors the cogni conventions in
# cogni-projects/tests/test-render-dashboard.sh.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
GUARD="$WS_ROOT/scripts/sanitize-theme.py"
RENDERER="$WS_ROOT/skills/workspace-dashboard/scripts/generate-dashboard.py"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "OK   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# assert_py "<label>" "<python expr, True to pass>" — GUARD path is on sys.path.
assert_py() {
  local label="$1" expr="$2"
  if python3 - "$GUARD" <<PY
import importlib.util, sys
spec = importlib.util.spec_from_file_location("g", sys.argv[1])
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
sys.exit(0 if ($expr) else 1)
PY
  then pass "$label"; else fail "$label"; fi
}

# assert_lacks "<label>" "<needle>" "<file>"
assert_lacks() {
  if [ -f "$3" ] && ! grep -qF "$2" "$3"; then pass "$1"; else fail "$1 (found '$2' or missing file)"; fi
}
# assert_has "<label>" "<needle>" "<file>"
assert_has() {
  if [ -f "$3" ] && grep -qF "$2" "$3"; then pass "$1"; else fail "$1 (missing '$2')"; fi
}

echo "=== guard unit behavior ==="
assert_py "1a hex color is safe"        'g.is_safe_value("#000000") is True'
assert_py "1b style breakout rejected"  'g.is_safe_value("#000</style><script>alert(1)</script>") is False'
assert_py "1c url() beacon rejected"    'g.is_safe_value("url(https://evil.example/track.png)") is False'
assert_py "1d empty rejected"           'g.is_safe_value("") is False'
assert_py "1e non-string rejected"      'g.is_safe_value(123) is False'
assert_py "1f overlong rejected"        'g.is_safe_value("#" + "a"*200) is False'
assert_py "1g font stack single-quotes ok" "g.is_safe_value(\"'Segoe UI', Roboto\") is True"
assert_py "1h unknown profile falls back to strict" 'g.is_safe_value("#000</style>", "nope") is False'

echo "=== sanitize_values fallback ==="
assert_py "2a rejected key keeps default" \
  'g.sanitize_values({"background":"#000</style>"}, {"background":"#FAFAF8"})[0]["background"] == "#FAFAF8"'
assert_py "2b safe key applied" \
  'g.sanitize_values({"background":"#123456"}, {"background":"#FAFAF8"})[0]["background"] == "#123456"'
assert_py "2c rejected key reported" \
  'g.sanitize_values({"background":"#000</style>"}, {"background":"#FAFAF8"})[1] == ["background"]'
assert_py "2d absent-in-defaults key ignored" \
  'g.sanitize_values({"rogue":"x"}, {"background":"#FAFAF8"})[0] == {"background":"#FAFAF8"}'

echo "=== CLI envelope ==="
cat > "$TMPROOT/dv-evil.json" <<'EOF'
{"colors": {"background": "#000</style><script>alert(1)</script>", "primary": "#111111"}, "status": {"danger": "#f00"}}
EOF
CLI_OUT="$(python3 "$GUARD" "$TMPROOT/dv-evil.json")"
echo "$CLI_OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and d["data"]["rejected"].get("colors")==["background"] else 1)' \
  && pass "3a CLI reports rejected color key" || fail "3a CLI reports rejected color key"
python3 "$GUARD" >/dev/null 2>&1 && fail "3b CLI no-arg errors" || pass "3b CLI no-arg errors"

echo "=== wired renderer end-to-end ==="
WS="$TMPROOT/ws"; mkdir -p "$WS"
run_render() { python3 "$RENDERER" "$WS" --design-variables "$1" --output "$WS/out.html" >/tmp/render-out.json 2>/tmp/render-err.txt; }

# Malicious color value must not reach the output; renderer must still succeed.
run_render "$TMPROOT/dv-evil.json"
if python3 -c 'import json,sys; d=json.load(open("/tmp/render-out.json")); sys.exit(0 if d.get("status")=="ok" else 1)'; then pass "4a malicious render succeeds"; else fail "4a malicious render succeeds"; fi
assert_lacks "4b </style><script> not in output" '</style><script>' "$WS/out.html"
assert_has   "4c built-in background applied instead" '#FAFAF8' "$WS/out.html"
python3 -c 'import json,sys; d=json.load(open("/tmp/render-out.json")); sys.exit(0 if d.get("theme_warnings") else 1)' \
  && pass "4d rejection surfaced as warning" || fail "4d rejection surfaced as warning"

# Safe theme still applies, and the legitimate @import url(...) font path is untouched.
cat > "$TMPROOT/dv-safe.json" <<'EOF'
{"colors": {"background": "#123456"}, "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=Outfit&display=swap');"}
EOF
run_render "$TMPROOT/dv-safe.json"
assert_has "4e safe color applied" '#123456' "$WS/out.html"
assert_has "4f legitimate @import url() font preserved" "@import url('https://fonts.googleapis.com" "$WS/out.html"

echo
if [ "$failures" -eq 0 ]; then
  echo "All sanitize-theme tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
