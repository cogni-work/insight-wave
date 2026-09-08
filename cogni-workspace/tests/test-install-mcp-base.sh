#!/usr/bin/env bash
# Regression test for the MCP base directory that install-mcp.sh resolves
# (MCP_BASE_DIR at scripts/install-mcp.sh:13, and INSTALL_DIR derived from it at :44).
#
# Contract under test: the base override falls back to $HOME/.claude/mcp-servers when it is
# unset OR set-but-empty, and is honoured verbatim otherwise. That is the same semantics as
# patch-desktop-config.py's `or` form and the dashboard probe's. CLAUDE_MCP_DIR has three
# readers -- scripts/install-mcp.sh:13, scripts/patch-desktop-config.py:86 and
# skills/workspace-dashboard/scripts/generate-dashboard.py:544. The two Python ones are
# pinned by tests/test-patch-desktop-config-mcp-base.sh (P03) and
# tests/test-dashboard-mcp-counts.sh (M18). This bash one was the only site with no
# discriminating case, so a "consistency" edit dropping the colon -- ${CLAUDE_MCP_DIR-...},
# which fires only on UNSET -- had no red test anywhere in the tree. This suite is that test.
#
# ASSERT THE POSITIVE PATH, NEVER A NEGATIVE SHAPE. Every case below compares the resolved
# location against a controlled fixture path by EQUALITY. A case phrased as "the path is not
# empty" or "does not start with a bare slash" would be green against the colon-dropped form
# and pin nothing -- the same rule the sibling suite's header states.
#
# DRIVE THE PRODUCTION READ PATH. Each case EXECUTES install-mcp.sh as a subprocess and reads
# the install_dir the script itself prints. Re-implementing ${CLAUDE_MCP_DIR:-...} inside the
# test, or grepping the script's source for the ":-" spelling, would never execute line 13:
# the first is green against a mutated script, the second goes red on any harmless reformat.
#
# WHY THE "ALREADY INSTALLED" PATH IS THE ONLY HERMETIC SEAM. install-mcp.sh clones and
# builds, and it has no --help or dry-run flag. Its only other early exit -- the missing-args
# path at :37-41 -- prints no path at all, so it cannot pin a base. But with INSTALL_DIR/.git
# present (:56 tests `[ -d ]` only, so an empty directory suffices), --force absent, and
# INSTALL_DIR/dist present (:64 accepts dist OR build), the script prints
# {"action":"skipped","install_dir":...} at :66 and exits 0 at :68 -- before `git clone` at
# :75 and before the build at :81. $REPO is dereferenced only at :75 and :108, both past that
# exit, which is why --repo takes a placeholder that is never resolved. No network, no git
# binary, no npm, no credential.
#
# An INCIDENTAL branch is an adequate observation point here only because INSTALL_DIR is
# SINGLY DERIVED, at :44, before any branching -- the skip print at :66, the rm -rf at :74,
# the clone at :75, the cd at :80 and the metadata write at :104 all read that one
# derivation. Observing it on the skip branch therefore observes all of them. A refactor that
# computed INSTALL_DIR per branch would silently narrow this pin to the skip branch alone, so
# check that premise before trusting these cases about any other path.
#
# SHAPE ONLY, NEVER HOST AVAILABILITY -- the same discipline as the two sibling suites. HOME
# is overridden to a fixture tree for every invocation, so the default-base cases resolve
# inside $TMPROOT and determinism is STRUCTURAL rather than a naming convention. Each case
# also sets its own CLAUDE_MCP_DIR state on the line immediately before its invocation, so
# nothing leaks between cases and an exported value from the developer's shell cannot decide
# a result.
#
# ASSERT THE MUTANT'S DEATH BY SHAPE, NEVER BY ITS DIAGNOSTIC WORDING. Under the
# colon-dropped mutant the empty-override run dies at `mkdir -p ""` (:53) under
# `set -euo pipefail`, which is also what stops it reaching the `rm -rf "$INSTALL_DIR"` at
# :74 with a root-level path. The message that failure prints is foreign coreutils output and
# is locale-dependent, so no case may match its text -- a grep for the English fragment finds
# nothing on a non-English host and the case would pass against the unfixed reader everywhere
# except English-locale CI. Detection here is purely structural: empty or unparseable stdout
# (I01-I03) and a non-zero exit status (I04). install-mcp.sh's own "skipped" literal is an
# own-emitter string and is fair game.
#
# I04's ABSENCE CONJUNCT IS ORDER-DEPENDENT BY CONSTRUCTION. start.sh and .mcp-install.json
# are absent only because every earlier case also took the skip path. A case that passed
# --force (:57), or omitted the dist fixture, would fall through to the build at :81 and
# create both -- turning I04 green for the wrong reason on a later run. No case may do either.
#
# Case ids are zero-padded to a uniform width so no id is a prefix of another: the mutation
# harness matches --case as a whole token, and I1 vs I10 is that collision class.
#
# Paths are self-located from $0, never the working directory: the repo runner invokes suites
# with cwd=<repo root> and the mutation harness with cwd=$ROOT, so a cwd-relative path here
# would be a latent false result.
#
# `set -u` but deliberately NOT `set -e`: the mutant run exits non-zero by design, and the
# suite has to survive it to report the case rather than aborting.
#
# stdlib-only: bash + python3, no pip deps, per the repo-wide script convention.
#
# Mutation recipe (recorded in the PR body; verdict guard_verified):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-workspace/scripts/install-mcp.sh
#     --expr 's/CLAUDE_MCP_DIR:-/CLAUDE_MCP_DIR-/'
#     --test 'bash cogni-workspace/tests/test-install-mcp-base.sh' --case I03

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
INSTALLER="$WS_ROOT/scripts/install-mcp.sh"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# A fixture $HOME, a fixture non-default base, and an empty directory to run from. The .git
# and dist directories are what put every invocation on the pre-clone skip path; they are
# real directories because :56 and :64 test with `[ -d ]`, but they are empty -- no git
# repository is initialised and nothing in them is ever read.
FAKE_HOME="$TMPROOT/home"
DEFAULT_BASE="$FAKE_HOME/.claude/mcp-servers"
ALT_BASE="$TMPROOT/alt-base"
EMPTY_CWD="$TMPROOT/empty-cwd"
SRV="fixture-mcp-server"
mkdir -p "$DEFAULT_BASE/$SRV/.git" "$DEFAULT_BASE/$SRV/dist" \
         "$ALT_BASE/$SRV/.git" "$ALT_BASE/$SRV/dist" "$EMPTY_CWD"

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# run_installer -- one invocation of the real script on its skip path, with HOME overridden
# and CLAUDE_MCP_DIR inherited from whatever the calling case just set. stdout is returned;
# stderr is discarded because the mutant writes a locale-dependent diagnostic there that no
# case may read. The subshell propagates the script's exit status, so a caller can capture it.
run_installer() {
  ( cd "$EMPTY_CWD" && HOME="$FAKE_HOME" bash "$INSTALLER" \
      --name "$SRV" --repo unused://fixture )
}

# json_field_is "<json>" "<key>" "<expected>" -- the suite's single definition of a
# well-formed emission: the payload parses, carries a `data` object, and that object's <key>
# equals <expected>. Empty or unparseable stdout therefore fails, which is the mutant's
# signature. Both assertion sites go through this one predicate so that policy cannot drift
# between them -- I04 exists to backstop I03, so it must not grade against a laxer parse than
# the case it backstops.
json_field_is() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)["data"]
except Exception:
    sys.exit(1)
sys.exit(0 if data.get(sys.argv[1]) == sys.argv[2] else 1)
' "$2" "$3"
}

# assert_install_dir "<label>" "<expected path>" -- the script exited 0 AND the install_dir
# it printed equals the expected fixture path. The rc conjunct is in the helper rather than
# in one case, so every case carries it: without it, a change that printed the right path and
# then exited non-zero would leave I01 and I02 green. `rc` is captured on its own line
# because `local out="$(...)"` would mask the substitution's status behind local's own.
assert_install_dir() {
  local label="$1" expected="$2" out rc
  out="$(run_installer 2>/dev/null)"
  rc=$?
  if [ "$rc" -eq 0 ] && json_field_is "$out" install_dir "$expected"; then
    pass "$label"
  else
    fail "$label"
  fi
}

# --- I01: an UNSET override resolves under the default base. -----------------------------
# The unset arm is pinned separately from the empty arm so the fix for one cannot regress the
# other. The explicit unset is not redundant: anyone who has run install-mcp exports this
# variable, and without it I01 would read that live base and fail on their machine.
unset CLAUDE_MCP_DIR
assert_install_dir "I01 an unset override resolves the install dir under the default base" \
  "$DEFAULT_BASE/$SRV"

# --- I02: a NON-EMPTY override replaces the base. ----------------------------------------
export CLAUDE_MCP_DIR="$ALT_BASE"
assert_install_dir "I02 a non-empty override resolves the install dir under that base" \
  "$ALT_BASE/$SRV"

# --- I03: an EMPTY override falls back to the default base. ------------------------------
# The discriminating case, and the recorded mutation target. Against ${CLAUDE_MCP_DIR-...}
# the base stays the empty string, the script dies before printing anything, and the equality
# above cannot hold.
export CLAUDE_MCP_DIR=""
assert_install_dir "I03 an empty override falls back to the default base, not an empty one" \
  "$DEFAULT_BASE/$SRV"

# --- I04: the empty-override run took the SKIP path, and built nothing. -------------------
# The anti-vacuity conjunct. Without it, I03's equality alone does not establish that the
# observed install_dir came from the network-free seam rather than from a clone-and-build
# that happened to land in the same place. Both arms carry the same leading id token so the
# case stays addressable from the mutation harness on a green run.
export CLAUDE_MCP_DIR=""
# The label is bound once and used by both arms: the mutation harness matches --case I04 as
# a whole token against the EMITTED line, and reads both the mutated (red) and restored
# (green) runs, so an edit retitling one arm and not the other would leave the case
# addressable on only one of the two.
i04_label="I04 the empty-override run took the skip path and wrote no install artifacts"
i04_out="$(run_installer 2>/dev/null)"
i04_rc=$?
if [ "$i04_rc" -eq 0 ] \
  && json_field_is "$i04_out" action skipped \
  && [ ! -e "$DEFAULT_BASE/$SRV/start.sh" ] \
  && [ ! -e "$DEFAULT_BASE/$SRV/.mcp-install.json" ]; then
  pass "$i04_label"
else
  fail "$i04_label"
fi

unset CLAUDE_MCP_DIR

echo
if [ "$failures" -eq 0 ]; then
  echo "All install-mcp MCP-base tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
