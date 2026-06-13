#!/usr/bin/env bash
# test_check_external_dispatch.sh — self-test for the external-dispatch guard.
#
# The guard asserts a HARD clean-zero: no live-dispatch surface
# (*/skills/*/SKILL.md, */agents/*.md, */commands/*.md, */hooks/**) may carry a
# `cogni-wiki:` / `cogni-research:` dispatch token. Cases:
#   1. Negative controls (bare noun "cogni-research" with no colon) -> exit 0.
#   2. Dispatch-laden fixture (cogni-wiki: + cogni-research:) -> exit 1, naming
#      the file + line + match.
#   3. Inline-allow escape hatch -> the flagged line is skipped.
#   4. Path exclusions (cogni-knowledge/ history, */wiki/ mirror) skipped in
#      discover mode -> exit 0 even though the token is present.
#   5. Real tree -> exit 0 (clean-zero today).
#
# bash 3.2 + stdlib python3 only (+ git for the discover-mode exclusion case).

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-external-dispatch.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Case 1 — negative control: a bare "cogni-research" noun (no colon) is fine.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/clean/cogni-demo/skills/demo"
cat > "$WORK/clean/cogni-demo/skills/demo/SKILL.md" <<'EOF'
---
name: demo
---
Modeled on the cogni-research verify-report skill, scoped to demo data.
This plugin dispatches cogni-knowledge:knowledge-query, not the retired engines.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/clean" "cogni-demo/skills/demo/SKILL.md" 2>/dev/null)
CODE=$?
set -e
check "bare-noun negative control exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "negative control reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 2 — dispatch-laden fixture: must fail, naming file + line + match.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/dirty/cogni-bad/agents"
cat > "$WORK/dirty/cogni-bad/agents/bad.md" <<'EOF'
First the agent dispatches Skill("cogni-wiki:wiki-query") to read the base.
Then it falls back to cogni-research:section-researcher for fresh web work.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/dirty" "cogni-bad/agents/bad.md" 2>/dev/null)
CODE=$?
set -e
check "dispatch fixture exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "dispatch fixture names both tokens with correct file+line" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
got={(x['match'],x['line']) for x in v}
want={('cogni-wiki:',1),('cogni-research:',2)}
missing=want-got
assert not missing, 'missing: %r (got %r)' % (missing, got)
assert all(x['file']=='cogni-bad/agents/bad.md' for x in v), v
assert d['success'] is False, d
"

# ---------------------------------------------------------------------------
# Case 3 — inline-allow escape hatch skips an otherwise-flagged line.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/allow/cogni-x/commands"
cat > "$WORK/allow/cogni-x/commands/c.md" <<'EOF'
Historical note: this menu mirrors cogni-research:verify-report's Next steps.  # external-dispatch-guard:allow
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/allow" "cogni-x/commands/c.md" 2>/dev/null)
CODE=$?
set -e
check "inline-allow line exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "inline-allow suppresses the dispatch token" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 4 — discover-mode path exclusions: a token under cogni-knowledge/ (FMO
# history) or */wiki/ (generated mirror) must NOT trip the guard.
# ---------------------------------------------------------------------------
EXC="$WORK/exclude"
mkdir -p "$EXC"
git -C "$EXC" init -q
git -C "$EXC" config user.email t@t.test
git -C "$EXC" config user.name test
mkdir -p "$EXC/cogni-knowledge/skills/k" "$EXC/cogni-foo/wiki/concepts" "$EXC/cogni-foo/skills/s"
# cogni-knowledge legitimately NAMES the retired engines as history:
printf -- '---\nname: k\n---\nDelegation history: this once dispatched cogni-wiki:wiki-ingest.\n' \
  > "$EXC/cogni-knowledge/skills/k/SKILL.md"
# a generated wiki mirror page may quote a retired dispatch as page content:
printf -- '---\nname: x\n---\nThe source quoted cogni-research:section-researcher.\n' \
  > "$EXC/cogni-foo/wiki/concepts/SKILL.md"
# a genuinely-clean live surface in the same repo:
printf -- '---\nname: s\n---\nDispatches cogni-knowledge:knowledge-compose only.\n' \
  > "$EXC/cogni-foo/skills/s/SKILL.md"
git -C "$EXC" add -A >/dev/null 2>&1
git -C "$EXC" commit -qm init >/dev/null 2>&1

set +e
OUT=$(python3 "$GUARD" --root "$EXC" 2>/dev/null)
CODE=$?
set -e
check "discover-mode exclusions pass (cogni-knowledge/ + */wiki/ skipped)" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "exclusions report zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 5 — real tree: the guard passes clean-zero today.
# ---------------------------------------------------------------------------
set +e
python3 "$GUARD" >/dev/null 2>&1
CODE=$?
set -e
check "real tree passes clean-zero" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All external-dispatch-guard tests passed."
  exit 0
else
  red "Some external-dispatch-guard tests failed."
  exit 1
fi
