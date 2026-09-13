#!/usr/bin/env bash
# test_check_code_span_nesting.sh — suite for the code-span nesting guard.
#
# Case labels are `<id> <description>` — an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so
# `--case code-span-nesting-01-red-planted` matches both the red and the green
# line, while a trailing colon would match neither and report case_not_found.
#
# SELF-SCAN: this file sits inside the repository the guard scans. It is not a
# *.md file, so the guard's own pathspec excludes it — but the defect literal is
# still never spelled contiguously here, because the shape belongs in a fixture,
# not in source anyone might copy. Every backtick is assembled at run time from
# BT, and every dirty fixture is written through an UNQUOTED heredoc so the
# expansion lands in the fixture rather than in this file.
#
# DISCOVERY IS THE GIT INDEX: the guard enumerates tracked *.md via
# `git ls-files`, so every fixture tree is a throwaway git repo — `git init -q`
# then `git add -A -f`. The -f defeats any inherited global ignore file. No
# commit and no identity config are needed; ls-files reads the index.
#
# ZERO DISCOVERY IS RED: the guard treats an empty sweep as a failure, so every
# fixture tree whose case asserts exit 0 or 1 must contain at least one tracked
# markdown file. Without that, a tree meant to prove an exclusion would exit 2
# and the case would silently be grading the empty-sweep path instead.
#
# bash 3.2 + python3 stdlib only.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-code-span-nesting.py"

red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0

check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

check_eq() {  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    check "$1" 0
  else
    check "$1 (expected $2, got $3)" 1
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

OUT="$WORK/out.json"
CODE=0

run_guard() {  # run_guard <root>
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

py_assert() {  # py_assert <label> <python-body, single-quoted strings only>
  set +e
  OUT_PATH="$OUT" python3 -c "
import json, os, sys
d = json.load(open(os.environ['OUT_PATH']))
s = d['data']['summary'] if d.get('data') else {}
v = d['data']['violations'] if d.get('data') else []
$2
"
  rc=$?
  set -e
  check "$1" "$rc"
}

# The backtick, assembled so this file never spells a nested span contiguously.
BT='`'

# mktree <name> — a throwaway git repo the guard's git ls-files discovery can see.
mktree() {
  tree="$WORK/$1"
  mkdir -p "$tree"
  git -C "$tree" init -q
  printf '%s\n' "$tree"
}

seal() {  # seal <tree> — stage everything so ls-files enumerates it
  git -C "$1" add -A -f >/dev/null 2>&1
}

# --- 01/02: a FRESHLY planted occurrence goes red, and the finding is usable ---
# Deliberately NOT a copy of a previously-retired instance: a fresh bare token,
# a fresh surrounding phrase.
T=$(mktree t01)
cat > "$T/clean.md" <<'EOF'
A well-formed paragraph with one span for `--verbose` and nothing else.
EOF
cat > "$T/planted.md" <<EOF
Some ordinary prose above the planted line.

Pass ${BT}run the ${BT}--verbose${BT} flag first${BT} when reproducing.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-01-red-planted a freshly planted nested span exits 1" "1" "$CODE"
py_assert "code-span-nesting-02-red-finding-fields the finding names the fixture file, its 1-based line and the bare token" "
assert s['total'] == 1, s
hit = v[0]
assert hit['file'] == 'planted.md', hit
assert hit['line'] == 3, hit
assert hit['between'] == '--verbose', hit
assert hit['context'], hit
"

# --- 03: the paired green control — same tree, occurrence removed ---
T=$(mktree t03)
cat > "$T/clean.md" <<'EOF'
A well-formed paragraph with one span for `--verbose` and nothing else.
EOF
cat > "$T/planted.md" <<EOF
Some ordinary prose above the line that no longer carries the defect.

Pass the ${BT}--verbose${BT} flag first when reproducing.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-03-green-clean-tree the same tree with the occurrence removed exits 0" "0" "$CODE"
py_assert "code-span-nesting-03b-green-nonvacuous the clean tree reports zero violations over a non-zero scanned population" "
assert s['total'] == 0, s
assert s['files_scanned'] >= 2, s
"

# --- 04-07: the well-formed shapes a naive scan flags ---
T=$(mktree t04)
cat > "$T/adjacent.md" <<'EOF'
Several spans separated by punctuation: `alpha`, `beta` and `gamma` all render.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-04-clean-adjacent-punctuation adjacent spans separated by punctuation stay clean" "0" "$CODE"

T=$(mktree t05)
cat > "$T/spaces.md" <<'EOF'
The heading prefix `# ` and the sentence delimiter `. ` are deliberate house style.

A span may also carry parentheses, as in `tr (translate)` mid-sentence.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-05-clean-span-with-spaces-and-parens spans whose content carries spaces or parentheses stay clean" "0" "$CODE"

T=$(mktree t06)
cat > "$T/double.md" <<EOF
The documented escape is a double delimiter, as in ${BT}${BT}tr '\\r\\n${BT}|' '  '${BT}${BT} here.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-06-clean-multi-backtick-containing-backtick a double-backtick span containing a literal backtick stays clean" "0" "$CODE"

T=$(mktree t07)
cat > "$T/escaped.md" <<EOF
A backslash-escaped backtick \\${BT} in prose, with a real span for ${BT}--verbose${BT} after it.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-07-clean-escaped-backtick an escaped backtick is clean under the guard's escape-blind pairing" "0" "$CODE"

# --- 08/09/10: fenced blocks ---
T=$(mktree t08)
cat > "$T/fence.md" <<EOF
Prose before the fence.

\`\`\`
Pass ${BT}run the ${BT}--verbose${BT} flag first${BT} when reproducing.
\`\`\`

Prose after the fence.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-08-fence-backtick-skipped an occurrence inside a backtick fence is not flagged" "0" "$CODE"

T=$(mktree t09)
cat > "$T/tilde.md" <<EOF
Prose before the fence.

~~~
Pass ${BT}run the ${BT}--verbose${BT} flag first${BT} when reproducing.
~~~

Prose after the fence.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-09-fence-tilde-skipped an occurrence inside a tilde fence is not flagged" "0" "$CODE"

T=$(mktree t10)
cat > "$T/after.md" <<EOF
\`\`\`
Pass ${BT}run the ${BT}--verbose${BT} flag first${BT} when reproducing.
\`\`\`

Pass ${BT}run the ${BT}--quiet${BT} flag next${BT} when reproducing.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-10-after-fence-still-flagged a real occurrence after a closed fence is still flagged" "1" "$CODE"
py_assert "code-span-nesting-10b-after-fence-names-the-live-one the flagged occurrence is the one outside the fence" "
assert s['total'] == 1, s
assert v[0]['between'] == '--quiet', v[0]
"

# --- 11: paragraph scoping — the line-scoped rule's false positive ---
T=$(mktree t11)
cat > "$T/multiline.md" <<EOF
A span may cross a newline inside a paragraph, as in ${BT}one
continued span${BT}, and the continuation line's first backtick is a CLOSER.
A line-scoped scan misreads it as an opener; a paragraph-scoped one does not.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-11-multiline-span-not-flagged a span crossing a newline inside a paragraph is not flagged" "0" "$CODE"

# --- 12: zero discovery is red, not a clean sweep ---
T=$(mktree t12)
cat > "$T/notes.txt" <<'EOF'
No markdown in this tree at all.
EOF
seal "$T"
run_guard "$T"
check_eq "code-span-nesting-12-zero-discovery-is-red a tree with no tracked markdown exits 2" "2" "$CODE"
py_assert "code-span-nesting-12b-zero-discovery-envelope the empty sweep reports success false with a non-empty error" "
assert d['success'] is False, d
assert d['error'], d
"

# --- 13/14: the real tree, and the liveness floor ---
# The floors are liveness checks, not shrink guards: they exist so a glob that
# stops matching, or a pairing pass that silently resolves nothing, cannot
# report a clean sweep. They are sized well under the live population so an
# ordinary deletion does not trip them, and recalibrated with a measurement
# when a deletion is large enough to. Measured 2026-09-13, after the doku wiki
# (two trees, ~260 pages) retired: 664 tracked markdown files, 45609 spans
# paired. The file floor had been 900, calibrated while those pages existed.
run_guard "$REPO_ROOT"
check_eq "code-span-nesting-13-real-tree-clean the repository as it stands is clean" "0" "$CODE"
py_assert "code-span-nesting-14-liveness-floor discovery still reaches markdown and pairing still resolves spans" "
assert s['files_scanned'] >= 550, s['files_scanned']
assert s['code_spans_paired'] >= 40000, s['code_spans_paired']
"

if [ "$FAILED" -eq 0 ]; then
  printf '%s\n' "All code-span nesting guard tests passed."
  exit 0
fi
printf '%s\n' "Some code-span nesting guard tests failed."
exit 1
