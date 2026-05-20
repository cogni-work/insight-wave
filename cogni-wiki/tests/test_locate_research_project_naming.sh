#!/usr/bin/env bash
# test_locate_research_project_naming.sh - regression test for cogni-wiki F2.
#
# Asserts that _wiki_research.locate_research_project resolves both:
#   - legacy `cogni-research-<slug>/` (pre-v0.7 cogni-research naming), AND
#   - v0.7.x+ `<slug>/` (--slug-named) and `<slug>-<date>/` (derived slug)
# from both wiki_root.parent and wiki_root.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$PLUGIN_ROOT/skills/wiki-ingest/scripts"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT_DIR/_wiki_research.py" ]; then
  red "FAIL: _wiki_research.py not found at $SCRIPT_DIR"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Layout:
#   $WORK/workspace/
#       cogni-wiki/                          (the wiki root)
#       cogni-research-foo/                  (legacy naming, sibling)
#         .metadata/project-config.json
#       bar-2026-05-20/                      (v0.7.x+ derived slug, sibling)
#         .metadata/project-config.json
#       baz/                                 (v0.7.x+ --slug naming, sibling)
#         .metadata/project-config.json
#       qux-suffix-2026-05-20/               (--suffix variant)
#         .metadata/project-config.json
#       qux/                                 (collides with a wiki child below)
#   $WORK/workspace/cogni-wiki/qux/          (wrong-dir trap; same name as workspace child)
#       .metadata/project-config.json

WS="$WORK/workspace"
WIKI="$WS/cogni-wiki"
mkdir -p "$WIKI"

mk_project() {
  local dir="$1"
  mkdir -p "$dir/.metadata"
  echo '{"slug": "test"}' > "$dir/.metadata/project-config.json"
}

mk_project "$WS/cogni-research-foo"
mk_project "$WS/bar-2026-05-20"
mk_project "$WS/baz"
mk_project "$WS/qux-suffix-2026-05-20"
# A wiki-internal project at the same exact name as a workspace dir, to
# confirm workspace probes come first.
mk_project "$WIKI/inside-wiki"

errors=0
run_case() {
  local label="$1" slug="$2" expected_basename="$3"
  local actual
  actual=$(PYTHONPATH="$SCRIPT_DIR" WIKI_ROOT="$WIKI" SLUG="$slug" python3 - <<'PY'
import os, sys
from pathlib import Path
sys.path.insert(0, os.environ["PYTHONPATH"])
from _wiki_research import locate_research_project
try:
    p = locate_research_project(os.environ["SLUG"], Path(os.environ["WIKI_ROOT"]), None)
    print(p.name)
except SystemExit as e:
    # `fail()` calls sys.exit; emit a marker we can grep for in the test.
    print("__FAIL__", e, file=sys.stderr)
    sys.exit(2)
PY
  ) || true
  if [ "$actual" = "$expected_basename" ]; then
    green "PASS: $label"
  else
    red "FAIL: $label"
    red "  expected basename: $expected_basename"
    red "  got              : $actual"
    errors=$((errors + 1))
  fi
}

# 1. Legacy naming - cogni-research-<slug>/ under workspace.
run_case "legacy 'cogni-research-foo' resolves" "foo" "cogni-research-foo"

# 2. v0.7.x+ derived slug under workspace - `bar-<date>/`.
run_case "v0.7.x+ derived 'bar-2026-05-20' resolves from slug 'bar'" "bar" "bar-2026-05-20"

# 3. v0.7.x+ --slug-named under workspace - `baz/`.
run_case "v0.7.x+ exact 'baz' resolves from slug 'baz'" "baz" "baz"

# 4. v0.7.x+ --suffix variant - `qux-suffix-2026-05-20/` (prefix match).
run_case "v0.7.x+ --suffix 'qux-suffix-2026-05-20' resolves from slug 'qux'" "qux" "qux-suffix-2026-05-20"

# 5. Negative path: a non-existent slug should fail. Capture stderr.
nonexistent_out=$(PYTHONPATH="$SCRIPT_DIR" python3 - 2>&1 <<PY || true
import sys
sys.path.insert(0, "$SCRIPT_DIR")
from pathlib import Path
from _wiki_research import locate_research_project
try:
    locate_research_project("does-not-exist", Path("$WIKI"), None)
except SystemExit:
    sys.exit(2)
PY
)
if echo "$nonexistent_out" | grep -q "cogni-research project not found"; then
  green "PASS: non-existent slug yields actionable 'not found' error"
else
  red "FAIL: non-existent slug did not produce 'not found' error"
  red "  got: $nonexistent_out"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All F2 locate_research_project naming cases pass."
