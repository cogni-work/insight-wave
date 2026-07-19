#!/usr/bin/env bash
# Test render-dashboard.py — the partner-meeting portfolio dashboard renderer.
#
# Covers the three acceptance criteria:
#   AC-1: every project is listed with fill status + a health flag,
#   AC-2: an aggregate portfolio value/impact summary is shown,
#   AC-3: a missing field / role-label mismatch degrades to a partial snapshot
#         (success stays true, a warning surfaces) rather than hard-failing.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
#
# Usage: bash cogni-projects/tests/test-render-dashboard.sh
# Exits non-zero on any assertion failure.

set -u  # NOT -e: a failing assertion must not abort the per-fixture counter.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/render-dashboard.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: render-dashboard.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# assert_json <label> <python-bool-expr over `d`> — pipes the last stdout line
# (the envelope) into python3 and checks the expression is truthy.
assert_json() {
  local label="$1" expr="$2"
  if printf '%s' "$LAST_JSON" | python3 -c "import json,sys
d = json.loads(sys.stdin.read())
sys.exit(0 if ($expr) else 1)" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "expr false: $expr | json=$LAST_JSON"
  fi
}

assert_html() {
  local label="$1" needle="$2" file="$3"
  if grep -qF "$needle" "$file"; then
    pass "$label"
  else
    fail "$label" "HTML missing needle: $needle ($file)"
  fi
}

# The negative counterpart — used by every "this must not have been injected"
# check, which would otherwise be hand-rolled per fixture.
assert_html_lacks() {
  local label="$1" needle="$2" file="$3"
  if grep -qF "$needle" "$file"; then
    fail "$label" "HTML unexpectedly contains: $needle ($file)"
  else
    pass "$label"
  fi
}

seed_portfolio() {
  # $1 = portfolio dir. Seeds a manifest + entity subdirs.
  local pf="$1"
  mkdir -p "$pf"/{consultants,projects,assignments,.metadata}
  cat > "$pf/projects-portfolio.json" <<'EOF'
{"slug":"test","name":"Test Portfolio","language":"en","consultants":[],"projects":[],"assignments":[],"created":"2026-01-01","updated":"2026-01-01"}
EOF
}

write_entity() { # $1 = path, $2 = frontmatter body (heredoc'd by caller)
  cat > "$1"
}

# run [args...] — invoke the renderer with any arguments (including none) and
# capture the last stdout line, which is the envelope, into LAST_JSON.
run() {
  LAST_JSON="$(python3 "$SCRIPT" "$@" 2>/dev/null | tail -n 1)"
}

# ---------------------------------------------------------------------------
# Fixture 1 — happy path: two projects, one partly staffed, one unstaffed.
# AC-1 (fill + health) and AC-2 (value aggregate).
# ---------------------------------------------------------------------------
PF1="$TMPROOT/happy"
seed_portfolio "$PF1"
write_entity "$PF1/projects/nordic-erp.md" <<'EOF'
---
type: project
slug: nordic-erp
name: Nordic Retail ERP
client: Nordic Retail
strategic_impact: 5
status: active
open_roles: [erp-lead, integration-architect, change-lead]
---
# Nordic Retail ERP
EOF
write_entity "$PF1/projects/small-audit.md" <<'EOF'
---
type: project
slug: small-audit
name: Compliance Audit
client: FinCo
strategic_impact: 2
status: active
open_roles: [auditor]
---
# Compliance Audit
EOF
write_entity "$PF1/consultants/mara.md" <<'EOF'
---
type: consultant
slug: mara
name: Mara Lindqvist
seniority: principal
skills: [erp, integration]
allocation_pct: 80
---
# Mara
EOF
write_entity "$PF1/assignments/mara--nordic-erp.md" <<'EOF'
---
type: assignment
slug: mara--nordic-erp
consultant: mara
project: nordic-erp
role: erp-lead
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment
EOF

run "$PF1"
HTML1="$PF1/output/dashboard.html"
assert_json "1a envelope success"        "d['success'] is True"
assert_json "1b two projects counted"    "d['data']['projects'] == 2"
assert_json "1c not partial (clean)"     "d['data']['partial'] is False"
assert_json "1d no warnings"             "d['data']['warnings'] == []"
assert_json "1e open roles = 3"          "d['data']['open_roles'] == 3"
assert_html "1f AC-1 lists project"      "Nordic Retail ERP" "$HTML1"
assert_html "1g AC-1 lists other project" "Compliance Audit" "$HTML1"
assert_html "1h AC-1 fill status shown"  "1/3" "$HTML1"
assert_html "1i AC-1 health flag shown"  "unstaffed" "$HTML1"
assert_html "1j AC-2 value section"      "strategic impact" "$HTML1"

# ---------------------------------------------------------------------------
# Fixture 2 — idempotent re-render: running twice rewrites the same file and
# stays successful (no accumulation, no state mutation).
# ---------------------------------------------------------------------------
run "$PF1"
assert_json "2a re-render success"       "d['success'] is True"
assert_json "2b re-render still 2 projects" "d['data']['projects'] == 2"
# The manifest must not have been touched by the read-only render.
if grep -qF '"consultants":[]' "$PF1/projects-portfolio.json"; then
  pass "2c manifest untouched (read-only)"
else
  fail "2c manifest untouched (read-only)" "manifest changed"
fi

# ---------------------------------------------------------------------------
# Fixture 3 — AC-3 graceful degradation: a project missing strategic_impact and
# an assignment whose role does not match any open_roles label. The render must
# still succeed with a partial snapshot and surfaced warnings.
# ---------------------------------------------------------------------------
PF3="$TMPROOT/partial"
seed_portfolio "$PF3"
write_entity "$PF3/projects/broken.md" <<'EOF'
---
type: project
slug: broken
name: Broken Project
client: X
status: active
open_roles: [ERP Lead]
---
# broken (no strategic_impact; open_roles label differs in case)
EOF
write_entity "$PF3/consultants/ana.md" <<'EOF'
---
type: consultant
slug: ana
name: Ana Ström
seniority: senior
skills: [erp]
---
# Ana
EOF
write_entity "$PF3/assignments/ana--broken.md" <<'EOF'
---
type: assignment
slug: ana--broken
consultant: ana
project: broken
role: erp-lead
start_date: 2026-02-01
end_date: 2026-08-01
status: active
---
# assignment (role erp-lead != open_roles "ERP Lead")
EOF

run "$PF3"
assert_json "3a AC-3 still succeeds"     "d['success'] is True"
assert_json "3b AC-3 marked partial"     "d['data']['partial'] is True"
assert_json "3c AC-3 has warnings"       "len(d['data']['warnings']) >= 2"
assert_json "3d AC-3 warns on missing impact" \
  "any('strategic_impact' in w for w in d['data']['warnings'])"
assert_json "3e AC-3 warns on label mismatch" \
  "any('label mismatch' in w for w in d['data']['warnings'])"
assert_html "3f AC-3 warnings rendered"  "partial snapshot" "$PF3/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 4 — missing manifest is a clean failure envelope, not a traceback.
# ---------------------------------------------------------------------------
PF4="$TMPROOT/no-manifest"
mkdir -p "$PF4"
run "$PF4"
assert_json "4a missing manifest fails cleanly" "d['success'] is False"
assert_json "4b failure names the manifest"     "'manifest' in d['error']"

# ---------------------------------------------------------------------------
# Fixture 5 — HTML-injection guard: an entity value with markup is escaped.
# ---------------------------------------------------------------------------
PF5="$TMPROOT/xss"
seed_portfolio "$PF5"
write_entity "$PF5/projects/evil.md" <<'EOF'
---
type: project
slug: evil
name: "<script>alert(1)</script>"
client: X
strategic_impact: 3
status: active
open_roles: [lead]
---
# evil
EOF
run "$PF5"
assert_json "5a injection render succeeds" "d['success'] is True"
assert_html_lacks "5b entity markup escaped" \
  '<script>alert(1)</script>' "$PF5/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 6 — genuinely malformed entities, not merely incomplete ones: a
# type-invalid strategic_impact, a project omitting open_roles entirely, and a
# non-UTF-8 entity file. Each must degrade to a warning while the valid project
# still renders. Fixture 3 covers only well-formed-but-incomplete data, which is
# why a decode failure could abort the whole render without tripping the suite.
# ---------------------------------------------------------------------------
PF6="$TMPROOT/malformed"
seed_portfolio "$PF6"
write_entity "$PF6/projects/good.md" <<'EOF'
---
type: project
slug: good
name: Valid Project
client: GoodCo
strategic_impact: 4
status: active
open_roles: [lead]
---
# good
EOF
write_entity "$PF6/projects/typed-wrong.md" <<'EOF'
---
type: project
slug: typed-wrong
name: Type Invalid
client: X
strategic_impact: high
status: active
open_roles: [lead]
---
# strategic_impact is a word, not 1..5
EOF
write_entity "$PF6/projects/no-roles.md" <<'EOF'
---
type: project
slug: no-roles
name: Roles Omitted
client: Y
strategic_impact: 4
status: active
---
# open_roles key absent entirely — staffing status is unknown, not zero
EOF
# The same unknown state reached by a different authoring shape: the key is
# present but carries no value. This must not read as "declares no roles".
write_entity "$PF6/projects/bare-roles.md" <<'EOF'
---
type: project
slug: bare-roles
name: Roles Blank
client: Y2
strategic_impact: 3
status: active
open_roles:
---
# open_roles present but empty — still unknown, not an assertion of zero
EOF
# A genuinely non-UTF-8 file: a latin-1 encoded byte that is invalid UTF-8.
# Written via python3 because bash printf parses a leading '---' as options.
python3 -c "
import sys
open(sys.argv[1], 'wb').write(
    '---\ntype: project\nslug: latin1\nname: Caf\xe9 Rollout\nstatus: active\n---\n'.encode('latin-1')
)" "$PF6/projects/latin1.md"

STDERR6="$TMPROOT/stderr6.txt"
LAST_JSON="$(python3 "$SCRIPT" "$PF6" 2>"$STDERR6" | tail -n 1)"

assert_json "6a malformed set still succeeds"  "d['success'] is True"
assert_json "6b marked partial"                "d['data']['partial'] is True"
# The undecodable file is skipped; the four parseable projects still render.
assert_json "6c valid projects still counted"  "d['data']['projects'] == 4"
assert_json "6d warns on non-numeric impact" \
  "any('strategic_impact' in w for w in d['data']['warnings'])"
# Both the absent key and the bare-scalar shape must reach the unknown state.
assert_json "6e warns on unknown staffing (both shapes)" \
  "sum('staffing status unknown' in w for w in d['data']['warnings']) == 2"
assert_json "6f warns on undecodable file" \
  "any('cannot read' in w and 'latin1' in w for w in d['data']['warnings'])"
if grep -qF 'Traceback' "$STDERR6"; then
  fail "6g no traceback on stderr" "traceback present: $(head -3 "$STDERR6")"
else
  pass "6g no traceback on stderr"
fi
assert_html "6h unknown staffing flagged in HTML" \
  "staffing unknown" "$PF6/output/dashboard.html"

# A project omitting open_roles must NOT render with the same ok severity as a
# project that explicitly declares none — that collapse is what made an
# unstaffed project look healthy.
assert_html_lacks "6i absent roles not shown as 'no open roles'" \
  'no open roles' "$PF6/output/dashboard.html"

# ---------------------------------------------------------------------------
# Fixture 7 — the {success,data,error} envelope is printed on every path,
# including an argparse usage error (SystemExit is a BaseException and would
# otherwise escape the top-level handler, leaving stdout empty).
# ---------------------------------------------------------------------------
run
assert_json "7a no-args still prints envelope" "d['success'] is False"
assert_json "7b no-args error names usage"     "'usage' in d['error']"
assert_json "7c usage names the real argument" "'portfolio_dir' in d['error']"

# ---------------------------------------------------------------------------
# Fixture 8 — a design-variables value that would break out of the <style>
# block is rejected in favour of the built-in palette rather than interpolated.
# ---------------------------------------------------------------------------
PF8="$TMPROOT/theme"
seed_portfolio "$PF8"
write_entity "$PF8/projects/plain.md" <<'EOF'
---
type: project
slug: plain
name: Plain Project
client: Z
strategic_impact: 3
status: active
open_roles: [lead]
---
# plain
EOF
cat > "$TMPROOT/evil-theme.json" <<'EOF'
{"bg": "#000</style><script>alert(1)</script>", "accent": "#ff0000"}
EOF
run "$PF8" --design-variables "$TMPROOT/evil-theme.json"
assert_json "8a themed render succeeds" "d['success'] is True"
assert_html_lacks "8b unsafe theme value rejected" \
  '<script>alert(1)</script>' "$PF8/output/dashboard.html"
assert_html "8c safe theme value still applied" "#ff0000" "$PF8/output/dashboard.html"

echo
if [ "$failures" -eq 0 ]; then
  echo "All render-dashboard tests passed."
  exit 0
fi
echo "$failures assertion(s) failed." >&2
exit 1
