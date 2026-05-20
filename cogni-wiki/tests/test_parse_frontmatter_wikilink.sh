#!/usr/bin/env bash
# test_parse_frontmatter_wikilink.sh - regression test for cogni-wiki F4.
#
# Asserts that _wikilib.parse_frontmatter returns:
#   - field: [[slug]]        -> string "[[slug]]"
#   - field: "[[slug]]"      -> string (quoted-form, regression check)
#   - field: [a, b]          -> list ["a", "b"]   (inline-list regression)
#
# Before the F4 fix, `[[slug]]` parsed as ["[slug]"] (a one-element list whose
# only element was the literal string "[slug]") because the inline-list branch
# matched any value bracketed by [ and ]. Downstream isinstance(value, str)
# checks silently fell through.
#
# bash 3.2 + stdlib python3 only. Exit non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$PLUGIN_ROOT/skills/wiki-ingest/scripts"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT_DIR/_wikilib.py" ]; then
  red "FAIL: _wikilib.py not found at $SCRIPT_DIR"
  exit 1
fi

errors=0

# A single Python harness covers all cases. Each case is one assertion;
# Python exit code reports failures aggregated.
PYTHONPATH="$SCRIPT_DIR" python3 - <<'PY'
import sys
from _wikilib import parse_frontmatter

CASES = [
    # (label, frontmatter_body, key, expected)
    ("bare wikilink `[[slug]]` -> string",
     "field: [[slug]]",
     "field",
     "[[slug]]"),
    ('quoted wikilink `"[[slug]]"` -> string (regression)',
     'field: "[[slug]]"',
     "field",
     '"[[slug]]"'),
    ("inline list `[a, b]` -> list (regression)",
     "field: [a, b]",
     "field",
     ["a", "b"]),
    ("empty inline list `[]` -> empty list (regression)",
     "field: []",
     "field",
     []),
    ("path-prefixed wikilink `[[a/b/slug]]` -> string (F5 surface)",
     "field: [[a/b/slug]]",
     "field",
     "[[a/b/slug]]"),
]

GREEN = "\033[32m"
RED = "\033[31m"
END = "\033[0m"

failures = 0
for label, body, key, expected in CASES:
    text = "---\n" + body + "\n---\nbody\n"
    fm = parse_frontmatter(text)
    actual = fm.get(key)
    if actual == expected and type(actual) is type(expected):
        print(f"{GREEN}PASS: {label}{END}")
    else:
        print(f"{RED}FAIL: {label}{END}")
        print(f"{RED}  expected: {expected!r} ({type(expected).__name__}){END}")
        print(f"{RED}  got     : {actual!r} ({type(actual).__name__}){END}")
        failures += 1

sys.exit(0 if failures == 0 else 1)
PY

if [ $? -ne 0 ]; then
  red "F4 parse_frontmatter cases failed."
  exit 1
fi

green ""
green "All F4 parse_frontmatter cases pass."
