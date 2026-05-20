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
#       qux-suffix-2026-05-20/               (--suffix variant, sibling)
#         .metadata/project-config.json
#   $WORK/workspace/cogni-wiki/inside-wiki/  (wiki-internal probe target)
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
mk_project "$WIKI/inside-wiki"

# One python3 startup runs all cases. Each case prints PASS/FAIL with diagnostics.
# Exit status reports aggregate failures.
PYTHONPATH="$SCRIPT_DIR" WIKI_ROOT="$WIKI" python3 - <<'PY' || exit 1
import os
import sys
from pathlib import Path

sys.path.insert(0, os.environ["PYTHONPATH"])
from _wiki_research import locate_research_project

WIKI = Path(os.environ["WIKI_ROOT"])
GREEN = "\033[32m"
RED = "\033[31m"
END = "\033[0m"

CASES = [
    # (label, slug, expected_basename)
    ("legacy 'cogni-research-foo' resolves", "foo", "cogni-research-foo"),
    ("v0.7.x+ derived 'bar-2026-05-20' resolves from slug 'bar'", "bar", "bar-2026-05-20"),
    ("v0.7.x+ exact 'baz' resolves from slug 'baz'", "baz", "baz"),
    ("v0.7.x+ --suffix 'qux-suffix-2026-05-20' resolves from slug 'qux'", "qux", "qux-suffix-2026-05-20"),
]

failures = 0
for label, slug, expected in CASES:
    try:
        resolved = locate_research_project(slug, WIKI, None)
        actual = resolved.name
    except SystemExit as exc:
        actual = f"__FAIL__:{exc}"
    if actual == expected:
        print(f"{GREEN}PASS: {label}{END}")
    else:
        print(f"{RED}FAIL: {label}{END}")
        print(f"{RED}  expected basename: {expected}{END}")
        print(f"{RED}  got              : {actual}{END}")
        failures += 1

# Negative case: non-existent slug must abort with the actionable error.
# _wikilib.fail() writes the envelope to stdout, so capture stdout.
import io, contextlib
out_buf = io.StringIO()
try:
    with contextlib.redirect_stdout(out_buf):
        locate_research_project("does-not-exist", WIKI, None)
    print(f"{RED}FAIL: non-existent slug should have aborted{END}")
    failures += 1
except SystemExit:
    out = out_buf.getvalue()
    if "cogni-research project not found" in out:
        print(f"{GREEN}PASS: non-existent slug yields actionable 'not found' error{END}")
    else:
        print(f"{RED}FAIL: non-existent slug aborted but error text unexpected{END}")
        print(f"{RED}  got: {out}{END}")
        failures += 1

sys.exit(0 if failures == 0 else 1)
PY

green ""
green "All F2 locate_research_project naming cases pass."
