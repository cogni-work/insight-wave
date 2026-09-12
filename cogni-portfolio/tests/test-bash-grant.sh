#!/usr/bin/env bash
# Acceptance suite for the script-invocation Bash grant.
#
# A skill that documents `bash .../scripts/x.sh` or `python3 .../scripts/x.py`
# can only run that step if its own frontmatter grants `Bash` — there is no
# separate Python tool, so the `python3` form needs the same grant. Nothing
# fails when the grant is missing: the documented step is simply unreachable,
# silently. This suite is what fails.
#
# Both halves are derived, never enumerated: the surface is the same three-glob
# scan the dashboard-handoff suite uses, and the governing file comes from the
# path — an invocation in skills/<x>/references/*.md is governed by
# skills/<x>/SKILL.md, the only file in that skill carrying frontmatter. A skill
# that starts invoking a script tomorrow is covered with no edit here.
# agents/*.md declare their tools under a JSON-array `tools:` key, so they stay
# in the scan surface but outside this rule.
#
# The grant is read from the `^allowed-tools:` LINE only, as a comma-delimited
# whole token. Both halves of that are load-bearing. A body-wide grep would be
# vacuously green on the very file this suite exists for — portfolio-verify's
# own prose says "Bash invocations below resolve the plugin root inline" — and a
# substring match would let a hypothetical `BashOutput` or an `mcp__*` token pass
# as the grant.
#
# The rule is one-way: an invocation implies the grant, never the converse. A
# skill that grants Bash without documenting an invocation is not an offender,
# so `compete` and `trends-bridge` (no invocation, no grant) are correctly
# silent here rather than flagged.
#
# Detector boundary: any line naming a `.../scripts/<name>.(sh|py)` path counts
# as a documented invocation. Keying on an interpreter token (`bash …`,
# `python3 …`) instead was tried and is wrong here — the plugin's dominant idiom
# is bare, `Run `$CLAUDE_PLUGIN_ROOT/scripts/project-status.sh <project-dir>``,
# and portfolio-architecture uses ONLY that form. An interpreter-keyed detector
# leaves it ungoverned, so stripping its grant would keep this suite green while
# the class-bug recurs — the one outcome this suite exists to prevent. Measured
# on the tree at the time of writing, the path-keyed rule governs 19 of 19
# skills and reports zero offenders once the two real ones are fixed, so the
# breadth costs no precision: whether a step names its interpreter is an
# authoring accident, not what decides that running it needs `Bash`.
#
# Named acceptance tests:
#   test_invocation_sites_grant_bash  every skill documenting a script invocation grants Bash
#   test_invocation_surface_intact    the derived surface and both detector arms are still live
#
# Usage: bash cogni-portfolio/tests/test-bash-grant.sh [test_name ...]
#   No args -> run every test (the CI path). One or more names -> run only those
#   (used by the mutation harness to run a single assertion against a mutant).
#   An unknown name exits 2 rather than reporting green, so a stale mutation
#   recipe cannot pass while running zero assertions.
# Exits non-zero on any assertion failure.
#
# Mutation recipe — the SHARED cogni-service harness, which classifies on the
#   output labels below. Replayable as written, from the repo root.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/portfolio-canvas/SKILL.md \
#     --expr 's#Grep, Bash#Grep#' \
#     --test 'bash cogni-portfolio/tests/test-bash-grant.sh test_invocation_sites_grant_bash' \
#     --case test_invocation_sites_grant_bash
#   The expr strips the Bash token from a skill that carries three real script
#   invocations, so the case goes red on the mutant and green on HEAD. The harness
#   feeds the expr to `perl -0pi` — never sed, never ERE — so it is single-quoted
#   at the call site, a `#` delimiter is used because neither string contains one,
#   and the anchor is metacharacter-free: a sed-style `/.../d` delete form would
#   match nothing and hard-error as expr_no_op. `Grep, Bash` occurs exactly once
#   in that file. The replacement is deliberately DISJOINT from the searched
#   string — one that still contained `Bash` would leave the grant intact, the
#   case green, and the mutation would survive unnoticed. The mutant must be a
#   documentation file: this suite asserts on frontmatter content, so mutating a
#   scripts/ file would leave every case green and prove nothing. There is no
#   in-repo copy of the SHARED harness; if that version directory is gone, use the
#   newest under the same parent — everything after the path is version-independent.
#   The in-repo equivalent is registered as mutation_invocation_bash_grant in
#   cogni-portfolio/scripts/mutation-check.sh.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the failure counter below, which exists so one run reports every offender.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"

# The one place the script-path shape is spelled. Everything below derives from
# it, so widening the filename class cannot leave the arm-liveness counters in
# test_invocation_surface_intact matching something narrower than the detector.
# Deliberately unanchored on the left: customers invokes a cogni-workspace script
# through ${WORKSPACE_PLUGIN_ROOT}, and the grant it needs is still the local one.
SCRIPT_PATH_RE='scripts/[A-Za-z0-9_.-]+\.'
INVOCATION_RE="${SCRIPT_PATH_RE}(sh|py)"
# The floor is a health check on the scan, not a census — it only has to be low
# enough never to trip on honest churn and high enough to catch a collapse.
MIN_GOVERNED=10

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one "<case>: <msg>" string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# The three-glob scan surface. agents/*.md are included on purpose: they are part
# of the documented surface, and test_invocation_surface_intact asserts they stay
# ungoverned rather than silently becoming offenders.
invocation_surface() {
  find "$PLUGIN_DIR/agents" -name '*.md' -type f 2>/dev/null
  find "$PLUGIN_DIR/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null
  find "$PLUGIN_DIR/skills" -mindepth 3 -maxdepth 3 -path '*/references/*.md' -type f 2>/dev/null
}

# file:line:text entries for every documented invocation across the surface,
# which the caller passes in so a single case never walks the tree twice.
# `-H` is what supplies the file: prefix; plain `grep -n` drops it for a single
# file argument, and the entry shape is what ${entry%%:*} below depends on.
invocation_lines() {
  printf '%s\n' "$1" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -nHE "$INVOCATION_RE" "$f" 2>/dev/null
  done
}

# skills/<x>/references/*.md -> skills/<x>/SKILL.md; skills/<x>/SKILL.md -> itself;
# anything else (agents/*.md) is ungoverned and prints nothing.
governing_file() {
  case "$1" in
    "$PLUGIN_DIR"/skills/*/references/*) printf '%s\n' "${1%/references/*}/SKILL.md" ;;
    "$PLUGIN_DIR"/skills/*/SKILL.md)     printf '%s\n' "$1" ;;
  esac
}

# --- test_invocation_sites_grant_bash --------------------------------------
# The offender case. Both broken-surface guards stay INLINE rather than living in
# the sibling case below, because the mutation harness runs this case by name and
# alone: a guard that only ran as part of a full sweep would let a mutant that
# breaks the scan report a vacuous green here.
test_invocation_sites_grant_bash() {
  local surface scanned
  surface="$(invocation_surface)"
  scanned="$(printf '%s\n' "$surface" | grep -c . )"
  if [ "$scanned" -eq 0 ]; then
    fail test_invocation_sites_grant_bash "scanned no files; scan surface is broken"
    return
  fi

  local lines line_count
  lines="$(invocation_lines "$surface")"
  line_count="$(printf '%s\n' "$lines" | grep -c . )"
  if [ "$line_count" -eq 0 ]; then
    fail test_invocation_sites_grant_bash "found no script-invocation lines; scan surface is broken"
    return
  fi

  # One pass, no early exit: every offender lands in $offenders and the single
  # fail() below names them all. $seen collapses a skill that invokes from more
  # than one file so it is reported once. The heredoc — not a pipe — is what keeps
  # both accumulators in this shell.
  local offenders="" seen="" governed=0
  while IFS= read -r entry; do
    local file governing rel grant
    file="${entry%%:*}"
    governing="$(governing_file "$file")"
    [ -n "$governing" ] || continue
    rel="${governing#"$PLUGIN_DIR/"}"
    case " $seen " in
      *" $rel "*) continue ;;
    esac
    seen="$seen $rel"
    governed=$((governed + 1))
    if [ ! -s "$governing" ]; then
      # Distinct from a missing grant on purpose: a broken surface must never
      # read as a skill that simply forgot the token.
      offenders="$offenders $rel:governing-SKILL.md-missing"
      continue
    fi
    grant="$(grep -m1 '^allowed-tools:' "$governing")"
    if [ -z "$grant" ]; then
      offenders="$offenders $rel:no-allowed-tools-line"
      continue
    fi
    grant="${grant#allowed-tools:}"
    case ",${grant//[[:space:]]/}," in
      *,Bash,*) : ;;
      *) offenders="$offenders $rel:missing-Bash" ;;
    esac
  done <<EOF
$lines
EOF

  if [ -n "$offenders" ]; then
    fail test_invocation_sites_grant_bash "skills documenting a script invocation whose allowed-tools omits Bash:$offenders"
  else
    pass test_invocation_sites_grant_bash "all $governed invoking skills grant Bash ($line_count invocation lines scanned)"
  fi
}

# --- test_invocation_surface_intact ----------------------------------------
# What a zero-guard structurally cannot catch: PARTIAL decay. If the detector
# silently loses its python3 arm, or the references find loses its -mindepth, the
# offender case still scans a non-empty surface and still passes — while the only
# .py invocation site becomes invisible. Each assertion here is a floor or a
# non-empty check, never an exact count, so honest churn does not trip it.
test_invocation_surface_intact() {
  local lines
  lines="$(invocation_lines "$(invocation_surface)")"

  # Built from SCRIPT_PATH_RE so these can never drift narrower than the detector
  # and report a dead arm that is merely spelled differently.
  local sh_hits py_hits
  sh_hits="$(printf '%s\n' "$lines" | grep -cE "${SCRIPT_PATH_RE}sh")"
  py_hits="$(printf '%s\n' "$lines" | grep -cE "${SCRIPT_PATH_RE}py")"
  if [ "$sh_hits" -eq 0 ] || [ "$py_hits" -eq 0 ]; then
    fail test_invocation_surface_intact "a detector arm went dead: .sh hits=$sh_hits .py hits=$py_hits (both must be non-zero)"
    return
  fi

  local seen="" governed=0 agent_hits=0 governed_agents=0
  while IFS= read -r entry; do
    local file governing rel
    file="${entry%%:*}"
    case "$file" in "$PLUGIN_DIR"/agents/*) agent_hits=$((agent_hits + 1)) ;; esac
    governing="$(governing_file "$file")"
    if [ -z "$governing" ]; then
      continue
    fi
    case "$file" in "$PLUGIN_DIR"/agents/*) governed_agents=$((governed_agents + 1)) ;; esac
    rel="${governing#"$PLUGIN_DIR/"}"
    case " $seen " in
      *" $rel "*) continue ;;
    esac
    seen="$seen $rel"
    governed=$((governed + 1))
  done <<EOF
$lines
EOF

  if [ "$governed" -lt "$MIN_GOVERNED" ]; then
    fail test_invocation_surface_intact "only $governed governed skills carry an invocation, floor is $MIN_GOVERNED; the derived surface has collapsed"
    return
  fi

  # agents/*.md declare tools under a JSON-array `tools:` key, so the
  # allowed-tools rule must never reach them. Asserted positively: a future change
  # that made governing_file fall through to a default would turn every agent file
  # into an offender, and this is what catches it.
  if [ "$governed_agents" -ne 0 ]; then
    fail test_invocation_surface_intact "$governed_agents agent file(s) resolved to a governing SKILL.md; agents declare tools under a different key and must stay ungoverned"
    return
  fi

  pass test_invocation_surface_intact "surface live: $governed governed skills, .sh=$sh_hits .py=$py_hits, $agent_hits agent invocation line(s) all ungoverned"
}

# Every case registered together. A name dropped here still resolves as a shell
# function, so run_one() would happily execute it while a no-arg CI run silently
# skips it — the registration list is the only thing that makes the suite complete.
ALL_TESTS="test_invocation_sites_grant_bash test_invocation_surface_intact"

# Reject an unknown case name instead of letting bash's "command not found" pass
# through: with no `set -e` and no failures increment, an unrecognised name would
# otherwise print "All tests passed." having run nothing at all.
run_one() {
  case " $ALL_TESTS " in
    *" $1 "*) "$1" ;;
    *) printf 'unknown test %s\n' "$1" >&2; exit 2 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for t in "$@"; do run_one "$t"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
