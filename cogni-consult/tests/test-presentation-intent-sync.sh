#!/usr/bin/env bash
# Parity guard for the presentation-intent vocabulary.
#
# The vocabulary is defined once, in cogni-publishing/references/presentation-intent.md,
# and mirrored into cogni-consult/references/publish-routing.md so consult-publish
# still has a complete schema when cogni-consult is installed without a
# cogni-workspace tree beside it. Both copies delimit the shared text with:
#
#     <!-- PRESENTATION-INTENT:SHARED:START -->
#     <!-- PRESENTATION-INTENT:SHARED:END -->
#
# The extraction includes the marker lines and the blank-line padding, so the two
# copies must match byte for byte including that padding.
#
# Emitters are plain on purpose: scripts/check-result-line-plainness.py forbids an
# escape literal anywhere in a discovered suite, and this file is discovered by
# scripts/run-plugin-tests.py via the */tests/*.sh glob. Do not import the coloured
# c_skip/c_info helpers from cogni-workspace/scripts/verify-theme-backcompat.sh —
# those survive only because that path matches neither discovery glob.
#
# SKIP vs FAIL: a MISSING cogni-workspace TREE is the installed-plugin layout and
# skips cleanly. A tree that is present but has lost its library file, or a file
# whose block is empty or malformed, FAILS — a vacuous scan must never read as
# success, and in a monorepo checkout the tree is always present.
#
# Mutation recipe (verified — mutated red, restored green):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-publishing/references/presentation-intent.md \
#     --expr 's/speaker_notes/speaker_note/' \
#     --test 'bash cogni-consult/tests/test-presentation-intent-sync.sh' \
#     --case pi-sync-03
#
# Use the cogni-service harness, NOT the different scripts/mutation-check.sh that
# cogni-consult and cogni-portfolio each ship — from here the plugin-root variable
# resolves to the consult copy, which takes no arguments and exits 0, so the
# replay grades nothing and reads green. See cogni-knowledge/tests/README.md.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"
NESTED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) REPO_ROOT="$2"; NESTED=1; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

LIB_FILE="$REPO_ROOT/cogni-publishing/references/presentation-intent.md"
CONSULT_FILE="$REPO_ROOT/cogni-consult/references/publish-routing.md"

START_MARK='<!-- PRESENTATION-INTENT:SHARED:START -->'
END_MARK='<!-- PRESENTATION-INTENT:SHARED:END -->'

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

extract_block() {
  sed -n "/^$START_MARK\$/,/^$END_MARK\$/p" "$1"
}

# The installed-plugin layout may carry no cogni-publishing TREE at all. That is the
# only clean skip. A tree that IS present but has lost the library file is a real
# failure -- skipping there would let an accidental deletion read as success.
if [ ! -d "$REPO_ROOT/cogni-publishing" ]; then
  printf 'SKIP: pi-sync-00 (no cogni-publishing tree at %s)\n' "$REPO_ROOT/cogni-publishing"
  exit 0
fi

if [ -f "$LIB_FILE" ]; then
  pass "pi-sync-00-library"
else
  fail "pi-sync-00-library" "the cogni-publishing tree is present but $LIB_FILE is missing"
  exit 1
fi

if [ ! -f "$CONSULT_FILE" ]; then
  fail "pi-sync-00-consult" "publish-routing.md not found at $CONSULT_FILE"
  exit 1
fi
pass "pi-sync-00-consult"

extract_block "$LIB_FILE" > "$WORK_DIR/lib.block"
extract_block "$CONSULT_FILE" > "$WORK_DIR/consult.block"

# pi-sync-01 / pi-sync-02 -- vacuity guards. An empty extraction would make the
# byte-compare below trivially pass over two broken files.
if [ -s "$WORK_DIR/lib.block" ]; then
  pass "pi-sync-01"
else
  fail "pi-sync-01" "the shared block in $LIB_FILE is empty or its markers are missing"
fi

if [ -s "$WORK_DIR/consult.block" ]; then
  pass "pi-sync-02"
else
  fail "pi-sync-02" "the shared block in $CONSULT_FILE is empty or its markers are missing"
fi

# pi-sync-03 -- the parity assertion itself.
if cmp -s "$WORK_DIR/lib.block" "$WORK_DIR/consult.block"; then
  pass "pi-sync-03"
else
  fail "pi-sync-03" "the shared blocks differ; run: diff <(sed -n '/START/,/END/p' $LIB_FILE) <(sed -n '/START/,/END/p' $CONSULT_FILE)"
fi

# pi-sync-04-* -- exactly one marker of each kind per file. Two of either makes
# the sed range ambiguous.
check_marker_count() {
  case_id="$1"; target="$2"
  starts=$(grep -c "^$START_MARK\$" "$target")
  ends=$(grep -c "^$END_MARK\$" "$target")
  if [ "$starts" -eq 1 ] && [ "$ends" -eq 1 ]; then
    pass "$case_id"
  else
    fail "$case_id" "expected exactly one START and one END in $target, found start=$starts end=$ends"
  fi
}
check_marker_count "pi-sync-04-library" "$LIB_FILE"
check_marker_count "pi-sync-04-consult" "$CONSULT_FILE"

# pi-sync-05-* -- marker ORDER. With END before START the sed range runs from
# START to end of file, and two identically-inverted files still compare equal,
# so the count check and the byte-compare together still read green.
check_marker_order() {
  case_id="$1"; target="$2"
  start_line=$(grep -n "^$START_MARK\$" "$target" | head -1 | cut -d: -f1)
  end_line=$(grep -n "^$END_MARK\$" "$target" | head -1 | cut -d: -f1)
  if [ -n "$start_line" ] && [ -n "$end_line" ] && [ "$start_line" -lt "$end_line" ]; then
    pass "$case_id"
  else
    fail "$case_id" "START must precede END in $target (start=${start_line:-none} end=${end_line:-none})"
  fi
}
check_marker_order "pi-sync-05-library" "$LIB_FILE"
check_marker_order "pi-sync-05-consult" "$CONSULT_FILE"

# pi-sync-06 -- self-sufficiency. consult-publish defers to this subsection as the
# canonical schema and is forbidden from restating the field shape, so a reduction
# to a pointer-plus-blurb would silently remove the schema it builds from.
missing=""
for token in 'register' 'dark_slides' 'speaker_notes' 'imagery' 'variations' \
             'slide_points' 'talk_track' 'key_figures' 'climax:' 'tbd:' 'note:' \
             'cover' 'bluf' 'two-column' 'table' 'timeline' 'quote' 'metric' 'roles' \
             'design is frozen'; do
  if ! grep -q -- "$token" "$WORK_DIR/consult.block"; then
    missing="$missing $token"
  fi
done
if [ -z "$missing" ]; then
  pass "pi-sync-06"
else
  fail "pi-sync-06" "the consult block is no longer self-sufficient; missing:$missing"
fi

# pi-sync-07 -- goes-red proof. Build a fixture tree whose library block is
# mutated and assert this suite fails against it. Skipped when already nested so
# the fixture run cannot recurse.
if [ "$NESTED" -eq 1 ]; then
  printf 'SKIP: pi-sync-07 (nested fixture run)\n'
else
  FIX="$WORK_DIR/fixture"
  mkdir -p "$FIX/cogni-publishing/references" "$FIX/cogni-consult/references" "$FIX/cogni-consult/tests"
  cp "$CONSULT_FILE" "$FIX/cogni-consult/references/publish-routing.md"
  sed 's/speaker_notes/speaker_note/' "$LIB_FILE" > "$FIX/cogni-publishing/references/presentation-intent.md"
  SELF="$FIX/cogni-consult/tests/$(basename "$0")"
  cp "$0" "$SELF"
  # Classify the nested run by its output line, never by exit status alone: any
  # non-zero exit -- a rejected flag, an unbound variable -- would otherwise read
  # as "the parity assertion fired" and leave this proof vacuous.
  NESTED_OUT="$WORK_DIR/nested.out"
  if bash "$SELF" --root "$FIX" >"$NESTED_OUT" 2>&1; then
    fail "pi-sync-07" "a mutated library block did not make this suite fail"
  elif ! grep -q "^FAIL: pi-sync-03" "$NESTED_OUT"; then
    fail "pi-sync-07" "the nested run failed, but not through pi-sync-03's parity assertion"
  else
    pass "pi-sync-07"
  fi
fi

if [ "$failures" -gt 0 ]; then
  printf '%s\n' "$failures failure(s)" >&2
  exit 1
fi
exit 0
