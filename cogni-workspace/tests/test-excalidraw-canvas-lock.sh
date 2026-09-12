#!/usr/bin/env bash
# test-excalidraw-canvas-lock.sh — pins the atomic start claim in
# hooks/ensure-excalidraw-canvas.sh.
#
# What it guards: cogni-workspace and cogni-portfolio ship byte-identical copies of
# that hook and register the same unqualified mcp__excalidraw__* PreToolUse
# matcher, so a machine with both plugins installed dispatches two of them in
# parallel on every tool call. The hook's port probe is a check, not a
# mutual-exclusion primitive — without the claim both invocations spawn a
# server, the loser dies on EADDRINUSE, and canvas.pid is left naming a dead
# process. Every exit status stays 0 throughout, so the failure is silent: only
# a behavioural test catches it.
#
# Hermetic by construction: each case builds its own sandbox under `mktemp -d`
# and prepends a stub bin/ to PATH shadowing every external the hook touches
# (nc, node, curl, open, xdg-open). No socket is bound, no network is used, and
# nothing is written outside the sandbox.
#
# `set -u` only, never `set -e`: one run reports every offender rather than
# stopping at the first.
#
# Mutation recipes — the SHARED cogni-service harness, which classifies on the
#   output labels below (a FAIL: line naming the case is RED). Replayable as
#   written, from the repo root. If that version directory is gone, use the
#   newest under the same parent; everything after the path is version-independent.
#
#   The case id names the ASSERTION, not the case function, and every id inside
#   a loop over EXCALIDRAW_HOOKS also carries the owning plugin directory. That
#   is why each --case below is spelled out rather than being the same string as
#   the --test selector: one function emits several result lines, and before the
#   ids were split a mutation of one line could be credited by a sibling line
#   going red. --test still names the bare shell function, because ALL_TESTS and
#   run_one dispatch on the function name — those are unchanged.
#
#   The harness matches a case whole-token, so a stale --case does not go red:
#   it returns case_not_found, which reads as a missing case rather than a
#   surviving mutant. Re-key every recipe here in the same change that re-ids a
#   line, and replay it.
#
#   M1 -> test_cold_start_spawns_exactly_one_server
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/hooks/ensure-excalidraw-canvas.sh \
#     --expr 's#mkdir "\$LOCK_DIR" 2>/dev/null#mkdir -p "\$LOCK_DIR" 2>/dev/null#' \
#     --test 'bash cogni-workspace/tests/test-excalidraw-canvas-lock.sh test_cold_start_spawns_exactly_one_server' \
#     --case test_cold_start_spawns_exactly_one_server-spawn-count
#   `mkdir -p` succeeds against an existing directory, so both racers believe
#   they won and both spawn — exactly the pre-fix behaviour. The searched
#   literal occurs once (the two other `mkdir` mentions are prose), the
#   replacement is disjoint from it, `#` is safe as a delimiter because neither
#   side contains one, and `\$` reaches perl as a literal dollar rather than an
#   interpolated variable.
#
#   M2 -> test_stale_lock_does_not_deadlock
#     --expr 's#LOCK_STALE_SECS=60#LOCK_STALE_SECS=999999999#'
#     --case test_stale_lock_does_not_deadlock-swept
#   The aged claim is never swept, so no spawn happens. Occurs once as the
#   declaration; every use is "$LOCK_STALE_SECS".
#
#   M3 -> test_release_is_trapped_for_signals
#     --expr 's#trap release_start_claim EXIT INT TERM#trap release_start_claim EXIT#'
#     --case test_release_is_trapped_for_signals-trap-signals-cogni-workspace
#   Still valid bash, so nothing aborts — only the signal-coverage case reddens.
#
#   M4 -> test_hook_copies_are_identical
#     --file cogni-portfolio/hooks/ensure-excalidraw-canvas.sh
#     --expr 's#LOCK_STALE_SECS=60#LOCK_STALE_SECS=61#'
#     --case test_hook_copies_are_identical-hooks-identical
#   Mutates the other copy so the pair diverges. Run against the cogni-workspace
#   suite, which reads both copies, so a drift introduced on either side reddens.
#
#   M5 -> test_stale_lock_survives_divergent_stat
#     --expr 's#\[\[ "\$lock_mtime" =~ \^\[0-9\]\+\$ \]\]#[[ -n "\$lock_mtime" ]]#'
#     --case test_stale_lock_survives_divergent_stat-swept
#   Reverts the mtime floor to the emptiness test, which structurally cannot see
#   a successful wrong answer: the stub's non-numeric reading survives it,
#   reaches the arithmetic, and aborts the hook. Occurs once.
#
#   M6 -> test_stale_lock_survives_divergent_stat
#     --expr 's#stat -c %Y "\$LOCK_DIR"#stat -f %m "\$LOCK_DIR"#'
#     --case test_stale_lock_survives_divergent_stat-gnu-first-cogni-workspace
#   Puts the BSD form first, leaving the GNU arm unreachable on the platform
#   that needs it. Reddens the ordering arm, which reads the chain out of the
#   hook's source. M8 replays this same substitution against the behavioural
#   case, so the one defect is caught by source shape and by consequence
#   independently — that is the defence-in-depth split. Occurs once; the quoted
#   form is deliberately absent from every comment.
#
#   M7 -> test_concurrent_stale_claim_spawns_exactly_one_server
#     --expr 's#\$swept_mtime" -eq "\$lock_mtime#\$swept_mtime" -ne "\$lock_mtime#'
#     --case test_concurrent_stale_claim_spawns_exactly_one_server-spawn-count
#   Inverts the identity test the sweep turns on, so the invocation that really
#   did carry the aged claim aside declines to claim and the one that did not
#   finds nothing left to carry: no spawn at all. Chosen over reverting the
#   sweep to a plain rmdir because it reddens deterministically rather than at
#   the rate the underlying race happens to hit. Occurs once; the comparison is
#   never written out in prose.
#
#   M8 -> test_live_claim_survives_flag_aware_stat
#     --expr 's#stat -c %Y "\$LOCK_DIR"#stat -f %m "\$LOCK_DIR"#'
#     --case test_live_claim_survives_flag_aware_stat-claim-survived
#   The same substitution M6 makes, replayed against the behavioural case — the
#   duplication is the point, not a copy error, so do not fold the two arms
#   together. Under the flag-aware stub a BSD-first chain answers first for a
#   LIVE claim, succeeds with a non-mtime, floors it to 0, judges the claim
#   ancient and carries it aside; the case demands it survive. Nothing in that
#   case reads the hook's source, so it stays red even if the chain is renamed
#   or moved into a helper.
#
#   M9 -> test_stale_lock_survives_divergent_stat
#     --expr 's#stat -c %Y "\$swept"#stat -f %m "\$swept"#'
#     --case test_stale_lock_survives_divergent_stat-gnu-first-cogni-workspace
#   The sweep's own chain, which no arm reached before. It reddens through the
#   ordering arm only: under the flag-agnostic stub both forms answer the same
#   non-numeric value, so reverting this chain leaves every behavioural case
#   green — which is why the ordering arm now holds over every chain the hook
#   contains rather than the first one it finds. Occurs once.
#
#   Neither M8 nor M9 carries a ^/$ anchor, so neither needs /m under the
#   harness's perl -0pi, and neither searched literal appears in any comment —
#   so neither substitution can be a silent no-op.
#
#   Mutating a hook copy is required: these cases assert hook behaviour, so
#   mutating this suite or a docs file would prove nothing. All nine recipes
#   were replayed against the shared harness and each returned guard_verified.
#
#   M3, M6 and M9 mutate the cogni-workspace copy only, so their --case carries
#   the cogni-workspace slug and the cogni-portfolio sibling id stays GREEN in
#   the same run. That asymmetry is the point of the per-hook discriminator:
#   before it existed both iterations shared one token, so a defect introduced
#   in one copy could be credited by the other copy's line going red.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"
WORKSPACE_HOOK="$REPO_ROOT/cogni-workspace/hooks/ensure-excalidraw-canvas.sh"
PORTFOLIO_HOOK="$REPO_ROOT/cogni-portfolio/hooks/ensure-excalidraw-canvas.sh"
WORKSPACE_HOOKS_JSON="$REPO_ROOT/cogni-workspace/hooks/hooks.json"
PORTFOLIO_HOOKS_JSON="$REPO_ROOT/cogni-portfolio/hooks/hooks.json"

MATCHER='mcp__excalidraw__.*'

# The surviving pair that ships this hook. Stated once: the next change to this
# population edits one line, so it cannot half-land across the sites below.
EXCALIDRAW_HOOKS=("$PORTFOLIO_HOOK" "$WORKSPACE_HOOK")

# Slug a hook path down to its owning plugin directory: .../cogni-portfolio/hooks/
# ensure-excalidraw-canvas.sh -> cogni-portfolio. The discriminator has to come
# from the DIRECTORY, never `basename` — both copies are named
# ensure-excalidraw-canvas.sh, so a basename-derived slug is constant and the
# per-iteration ids would still collide. Parameter expansion, no fork.
hook_slug() { local _d="${1%/hooks/*}"; printf '%s' "${_d##*/}"; }
# Same idea for the four-path existence loop, which also covers the hooks.json
# pair — there the file name does vary, so both parts are kept.
path_slug() { local _r="${1#"$REPO_ROOT/"}"; printf '%s' "${_r//\//-}"; }

# One reader of the PreToolUse surface, used by both arms below. Both modes are
# scoped to hooks.PreToolUse, never to the file as a whole: cogni-workspace's
# hooks.json declares SessionStart first, so a flat scan of the file reads the
# wrong hook and agrees with the right answer only by coincidence.
#
#   block   — the whole key-sorted PreToolUse array. Deliberately NOT filtered by
#             matcher: the matcher is one of the things that must not drift, so
#             filtering on it would make a matcher divergence unreadable rather
#             than reporting it as the divergence it is. Comparing the array
#             whole also covers a field that becomes dispatch-relevant later
#             without editing this accessor.
#   <field> — a field of the excalidraw entry's own hook, selected BY MATCHER so
#             a second PreToolUse entry could never silently shift which hook is
#             read. Absent matcher yields empty, and the call site's own floor
#             turns that into a failure.
pretooluse_field() {
  python3 -c 'import json,sys
blocks = json.load(open(sys.argv[1]))["hooks"]["PreToolUse"]
if sys.argv[3] == "block":
    print(json.dumps(blocks, sort_keys=True))
else:
    b = next(x for x in blocks if x.get("matcher") == sys.argv[2])
    print(b["hooks"][0][sys.argv[3]])' \
    "$1" "$MATCHER" "$2" 2>/dev/null
}

failures=0

# Emitters stay plain: no escape sequence may precede a result label, or a
# genuinely red case reports as case_not_found to the mutation harness. The
# case id is always a separate argument, so the harness's whole-token match
# against the label holds.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

TMPROOT="$(mktemp -d)"
STARTED_PIDS=""

cleanup() {
  for p in $STARTED_PIDS; do
    kill "$p" 2>/dev/null || true
  done
  rm -rf "$TMPROOT"
}
trap cleanup EXIT

# Build a sandbox: an EXCALIDRAW_MCP_DIR with a dist/server.js fixture, plus a
# stub bin/ shadowing every external the hook shells out to.
#
#   node  records one line per spawn, waits, then signals "port up" by creating
#         the marker, and finally execs sleep so the recorded pid stays live
#         (canvas.pid must name a live process). The wait is what forces real
#         contention: without it the second invocation would take the fast path
#         and the case would pass vacuously.
#   nc    reports the port up only once the marker exists — the cold canvas.
#   curl  reports a connected websocket client once the port is up, so the
#         browser branch is never reached.
make_fixture() {
  fx="$TMPROOT/$1"
  mkdir -p "$fx/mcp/dist" "$fx/bin"
  : > "$fx/mcp/dist/server.js"
  : > "$fx/spawns.log"

  cat > "$fx/bin/node" <<EOF
#!/usr/bin/env bash
echo spawn >> "$fx/spawns.log"
sleep 0.7
: > "$fx/port.up"
exec sleep 30
EOF

  cat > "$fx/bin/nc" <<EOF
#!/usr/bin/env bash
[ -f "$fx/port.up" ]
EOF

  cat > "$fx/bin/curl" <<EOF
#!/usr/bin/env bash
[ -f "$fx/port.up" ] || exit 1
printf '%s\n' '{"websocket_clients":1}'
EOF

  printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/bin/open"
  cp "$fx/bin/open" "$fx/bin/xdg-open"
  chmod +x "$fx/bin/node" "$fx/bin/nc" "$fx/bin/curl" "$fx/bin/open" "$fx/bin/xdg-open"
}

# Shadow `stat` with one whose flag semantics diverge from the BSD shape this
# hook was first written against. make_fixture deliberately does not stub it:
# stat is the one external here whose flags mean different things on different
# platforms, so leaving it real is what let a Linux-only defect pass a macOS
# run. The hook carries the full rationale for the chain order.
#
# Non-numeric for BOTH forms on purpose: what is pinned is the numeric floor
# itself — that no unusable reading can reach the arithmetic — not which arm of
# the chain happened to answer.
add_divergent_stat_stub() {
  fx="$TMPROOT/$1"
  cat > "$fx/bin/stat" <<'STATSTUB'
#!/usr/bin/env bash
echo /
exit 0
STATSTUB
  chmod +x "$fx/bin/stat"
}

# The sibling of the stub above, and the opposite choice on the one axis that
# matters: this one ANSWERS THE FLAGS. `-c` returns a real epoch, `-f` returns
# a string that is not an mtime and still exits 0 — GNU's actual shape, where
# `-f` means --file-system and so succeeds without reporting a modification
# time. That exit 0 is the load-bearing half: a failing `-f` would let the `||`
# fall through to the GNU form and both orders would agree again, which is
# exactly what makes the flag-agnostic stub above unable to see the ordering.
#
# The heredoc is unquoted so $fx interpolates at write time, while \$1 is
# escaped through to the stub's own runtime — the technique add_staggered_date_stub
# below uses for \$@. `date` is deliberately NOT stubbed alongside this: the -c
# arm shells out to the real one, and a staggering date stub would corrupt the
# reading this case turns on.
#
# Two markers, written on every call, deliberately kept separate. port.up is
# what keeps the case cheap: a live claim sends the hook into its port-wait
# loop — twenty half-second probes — and the nc stub reports the port up as
# soon as that file exists, so the loop breaks on its first probe. Removing
# just that one write costs the suite about ten seconds.
#
# stat.called is the witness the case asserts on, and it is separate precisely
# because port.up is not exclusively ours: the node stub writes it too, on any
# run that reaches a spawn. This case spawns nothing today, so the two would
# agree — but a witness that silently depends on that is the kind of guard this
# suite exists to not ship. Only the stub writes stat.called.
add_flag_aware_stat_stub() {
  fx="$TMPROOT/$1"
  cat > "$fx/bin/stat" <<EOF
#!/usr/bin/env bash
: > "$fx/port.up"
: > "$fx/stat.called"
case "\$1" in
  -c) date +%s ;;
  -f) echo "%m" ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$fx/bin/stat"
}

# Stagger two racers at the one point where the sweep is decided. The hook
# calls `date` exactly once, between reading the aged claim's mtime and acting
# on it, so a stub that holds the SECOND caller there puts the two racers into
# the specific interleaving that breaks a non-atomic sweep: the first retires
# the stale claim and takes a fresh one, and the second — still holding the
# staleness verdict it formed about the OLD claim — arrives afterwards and
# retires the fresh one.
#
# Deliberately deterministic rather than left to timing. That interleaving is a
# few syscalls wide, so racing two unstaggered invocations reproduces it only
# occasionally: a case that catches the defect at some rate below 1 is not a
# guard, it is a coin flip that reports green most of the time.
#
# `mkdir` is the stagger's own claim primitive for the same reason the hook
# uses it — it is atomic, so exactly one caller can be first.
add_staggered_date_stub() {
  fx="$TMPROOT/$1"
  cat > "$fx/bin/date" <<EOF
#!/usr/bin/env bash
mkdir "$fx/date.first" 2>/dev/null || sleep 0.4
exec /bin/date "\$@"
EOF
  chmod +x "$fx/bin/date"
}

# Run the hook against a sandbox. stdin must be /dev/null: the hook consumes
# stdin to avoid a broken pipe and would otherwise block on an inherited
# terminal.
#
# An optional third argument names a gate file to spin on first, which is how
# the barriered case below releases two racers together. A builtin-only spin,
# so it forks nothing and both racers resume inside the same millisecond. A
# FIFO on stdin looks like the tidier barrier and is not one: the writer's
# open unblocks whichever reader arrived first and its close then sends EOF,
# so a reader that opens after that close waits for a writer that will never
# return, and the case hangs instead of racing.
run_hook() {
  fx="$TMPROOT/$1"
  if [ -n "${3:-}" ]; then
    while [ ! -e "$3" ]; do :; done
  fi
  PATH="$fx/bin:$PATH" \
  EXCALIDRAW_MCP_DIR="$fx/mcp" \
  EXCALIDRAW_CANVAS_PORT=39117 \
    bash "$WORKSPACE_HOOK" < /dev/null > "$fx/out.$2" 2>&1
}

spawn_count() { wc -l < "$TMPROOT/$1/spawns.log" | tr -d ' '; }

# Strip comments before asserting on code: the hook's prose deliberately names
# the primitives it forbids ("never mkdir -p", "flock is not stock on macOS"),
# so an unstripped grep would match the explanation rather than the code.
hook_code() { sed 's/#.*//' "$1"; }

# AC 1 + AC 2 + AC 3: two concurrent invocations against a cold canvas spawn
# exactly one server, canvas.pid names a live process, and both exit 0.
test_cold_start_spawns_exactly_one_server() {
  c=cold; make_fixture "$c"
  run_hook "$c" a & pa=$!
  run_hook "$c" b & pb=$!
  wait "$pa"; rca=$?
  wait "$pb"; rcb=$?

  n="$(spawn_count "$c")"
  if [ "$n" = "1" ]; then
    pass test_cold_start_spawns_exactly_one_server-spawn-count "exactly one spawn"
  else
    fail test_cold_start_spawns_exactly_one_server-spawn-count "expected 1 spawn, got $n"
  fi

  if [ "$rca" = "0" ] && [ "$rcb" = "0" ]; then
    pass test_cold_start_spawns_exactly_one_server-exit-codes "both invocations exited 0"
  else
    fail test_cold_start_spawns_exactly_one_server-exit-codes "exit codes were $rca and $rcb"
  fi

  pidfile="$TMPROOT/$c/mcp/canvas.pid"
  if [ -f "$pidfile" ]; then
    livepid="$(cat "$pidfile")"
    STARTED_PIDS="$STARTED_PIDS $livepid"
    if kill -0 "$livepid" 2>/dev/null; then
      pass test_cold_start_spawns_exactly_one_server-canvas-pid "canvas.pid names a live process"
    else
      fail test_cold_start_spawns_exactly_one_server-canvas-pid "canvas.pid $livepid is not live"
    fi
  else
    fail test_cold_start_spawns_exactly_one_server-canvas-pid "canvas.pid was never written"
  fi

  if [ -d "$TMPROOT/$c/mcp/canvas-start.lock" ]; then
    fail test_cold_start_spawns_exactly_one_server-claim-released "claim was not released"
  else
    pass test_cold_start_spawns_exactly_one_server-claim-released "claim released"
  fi
}

# Plant an aged claim: the state both stale-sweep cases start from.
plant_stale_claim() {
  mkdir -p "$TMPROOT/$1/mcp/canvas-start.lock"
  touch -t 202001010000 "$TMPROOT/$1/mcp/canvas-start.lock"
}

# Shared post-conditions for both stale-sweep cases: exactly one server
# started, the hook exited 0, and the claim was released again. Kept in one
# place so a change to what "swept successfully" means cannot land on one case
# and silently leave the other asserting the old contract — that failure mode
# is a GREEN suite, since each case stays self-consistent.
#
# The case name travels as a separate argument all the way to pass/fail, so
# the mutation harness's whole-token match on the result label still holds.
assert_stale_claim_swept() {
  _case="$1"; _c="$2"; _rc="$3"; _label="$4"

  _n="$(spawn_count "$_c")"
  if [ "$_n" = "1" ] && [ "$_rc" = "0" ]; then
    pass "$_case-swept" "$_label"
  else
    fail "$_case-swept" "expected 1 spawn and rc 0, got $_n and $_rc"
  fi

  _pidfile="$TMPROOT/$_c/mcp/canvas.pid"
  if [ -f "$_pidfile" ]; then
    STARTED_PIDS="$STARTED_PIDS $(cat "$_pidfile")"
  fi

  if [ -d "$TMPROOT/$_c/mcp/canvas-start.lock" ]; then
    fail "$_case-claim-released" "claim was not released"
  else
    pass "$_case-claim-released" "claim released"
  fi
}

# AC 5: a claim left behind by a killed spawn is swept, not waited on forever.
test_stale_lock_does_not_deadlock() {
  c=stale; make_fixture "$c"; plant_stale_claim "$c"

  run_hook "$c" a; rc=$?

  assert_stale_claim_swept test_stale_lock_does_not_deadlock "$c" "$rc" \
    "stale claim swept and server started"
}

# The intersection neither case above reaches: concurrency AGAINST a stale
# claim. test_cold_start races two invocations but only from a virgin sandbox,
# and test_stale_lock exercises the aged claim with a single invocation. The
# guarantee breaks exactly where they cross — two racers that both judge the
# same aged claim stale — so a sweep that retires it non-atomically passes
# every other case in this file. That is how such a sweep reached review.
#
# Barriered rather than started bare: each racer spins on a gate file until it
# appears, so both resume inside the same millisecond. A bare background start
# (what the cold-start case uses) routinely lets the first finish before the
# second is scheduled, which is why that case cannot see this.
#
test_concurrent_stale_claim_spawns_exactly_one_server() {
  c=staleconcurrent
  make_fixture "$c"
  add_staggered_date_stub "$c"
  plant_stale_claim "$c"

  gate="$TMPROOT/$c/gate"
  run_hook "$c" a "$gate" & pa=$!
  run_hook "$c" b "$gate" & pb=$!
  # Let both racers reach the spin before releasing them, so neither is still
  # being scheduled when the other starts claiming.
  sleep 0.2
  : > "$gate"

  wait "$pa"; rca=$?
  wait "$pb"; rcb=$?

  pidfile="$TMPROOT/$c/mcp/canvas.pid"
  if [ -f "$pidfile" ]; then
    STARTED_PIDS="$STARTED_PIDS $(cat "$pidfile")"
  fi

  n="$(spawn_count "$c")"
  if [ "$n" = "1" ]; then
    pass test_concurrent_stale_claim_spawns_exactly_one_server-spawn-count "exactly one spawn against a contested stale claim"
  else
    fail test_concurrent_stale_claim_spawns_exactly_one_server-spawn-count "expected 1 spawn, got $n"
  fi

  if [ "$rca" = "0" ] && [ "$rcb" = "0" ]; then
    pass test_concurrent_stale_claim_spawns_exactly_one_server-exit-codes "both invocations exited 0"
  else
    fail test_concurrent_stale_claim_spawns_exactly_one_server-exit-codes "exit codes were $rca and $rcb"
  fi

  if [ -d "$TMPROOT/$c/mcp/canvas-start.lock" ]; then
    fail test_concurrent_stale_claim_spawns_exactly_one_server-claim-released "claim was not released"
  else
    pass test_concurrent_stale_claim_spawns_exactly_one_server-claim-released "claim released"
  fi
}

# The sweep must survive a stat whose flags mean something else. This is the
# cross-platform contract: the suite runs on macOS but CI (and most users) run
# Linux, so a chain that only works under BSD semantics passes locally and dies
# there. Two arms, because the fix has two independent halves and neither one
# alone is observable through the other.
test_stale_lock_survives_divergent_stat() {
  # Ordering arm first, and deliberately so: it is a static read of two files
  # (sub-second) while the behavioural arm below costs a real hook run against
  # a stubbed canvas (seconds), so running it first is where a failing path
  # gets its feedback soonest.
  #
  # This arm is defence in depth, not the primary pin. The ordering IS reachable
  # behaviourally — test_live_claim_survives_flag_aware_stat asserts it by
  # consequence — and what this arm adds is the two things that case cannot
  # give. It holds over EVERY stat chain the hook contains, including the
  # sweep's own second chain, whose revert leaves every behavioural case in this
  # file green; and it holds over the portfolio copy, which no case here can
  # run. The count floor is what keeps both of those honest: fold the chains
  # into a helper, or drop one, and this arm reddens rather than passing over a
  # smaller set than it thinks it has.
  #
  # Why the ordering is worth pinning at all: a BSD-first chain leaves the GNU
  # arm dead on the platform that needs it, and the numeric floor then silently
  # degrades every sweep to "ancient" instead of reading the real age. The floor
  # makes that failure quiet, not safe.
  #
  # The selection keys on the call itself, not on the variable it is assigned to
  # and not on the assignment shape — so neither renaming lock_mtime or
  # swept_mtime, nor moving a chain out of an assignment and into a condition,
  # can drop it out of the set. Counting the captured lines rather than running
  # a second grep keeps one selector: two would have to be kept in step by hand,
  # and the arm would pass over a different population than the floor counts.
  for h in "${EXCALIDRAW_HOOKS[@]}"; do
    hslug="$(hook_slug "$h")"
    chains="$(hook_code "$h" | grep -E 'stat ')"
    n_chains="$(printf '%s\n' "$chains" | grep -c .)"
    if [ "$n_chains" != "2" ]; then
      fail test_stale_lock_survives_divergent_stat-chain-count-$hslug "expected 2 stat chains in $h, found $n_chains"
      continue
    else
      pass test_stale_lock_survives_divergent_stat-chain-count-$hslug "2 stat chains in $h"
    fi
    bad=0
    # Fed by a heredoc, never a pipe: a pipeline runs the loop in a subshell
    # under bash 3.2 and the counter would not survive it.
    while IFS= read -r chain; do
      case "$chain" in
        *"stat -c "*"stat -f "*) ;;
        *)
          bad=1
          fail test_stale_lock_survives_divergent_stat-gnu-first-$hslug "chain is not GNU-first in $h: $chain" ;;
      esac
    done <<EOF
$chains
EOF
    if [ "$bad" = "0" ]; then
      pass test_stale_lock_survives_divergent_stat-gnu-first-$hslug "both stat chains are GNU-first in $h"
    fi
  done

  # Behavioural arm. Pre-fix this is rc 1 with 0 spawns: the mtime read
  # succeeds with a non-numeric value, which reaches the arithmetic and aborts
  # the hook under set -e before it can ever spawn.
  c=divergentstat; make_fixture "$c"; add_divergent_stat_stub "$c"
  plant_stale_claim "$c"

  run_hook "$c" a; rc=$?

  assert_stale_claim_swept test_stale_lock_survives_divergent_stat "$c" "$rc" \
    "swept and started despite a divergent stat"
}

# The ordering of the chain, pinned by consequence rather than by source text.
# The stub's mechanics live with the stub; what matters here is what they buy:
#
# Against a GNU-first chain a live peer's claim reads its true, recent mtime and
# is left alone. Reverse the chain and `-f` answers first, succeeds, and the
# `||` never falls through; the numeric floor coerces that unusable reading to
# 0, the claim reads as ancient, and it is carried aside — a live peer's claim
# swept, and the double spawn back.
#
# That survival is the discriminator. The rc check below is a floor, not the
# pin: a reverted chain still exits 0 (the hook has no failing branch), so rc
# never moves under the mutation this case grades. What it catches is a hook
# that aborts mid-run, which would leave both other assertions passing over a
# run that decided nothing. A spawn count would grade nothing at all here — it
# is 0 under either ordering.
#
# Nothing in this case reads the hook's source, so renaming the variable the
# chain assigns to cannot quietly make it green again.
test_live_claim_survives_flag_aware_stat() {
  c=liveclaim; make_fixture "$c"; add_flag_aware_stat_stub "$c"

  # A LIVE claim — a bare mkdir, deliberately not plant_stale_claim, whose
  # backdated timestamp is the opposite of the state this case needs.
  mkdir -p "$TMPROOT/$c/mcp/canvas-start.lock"

  run_hook "$c" a; rc=$?

  if [ -d "$TMPROOT/$c/mcp/canvas-start.lock" ]; then
    pass test_live_claim_survives_flag_aware_stat-claim-survived "a live peer's claim survived the sweep decision"
  else
    fail test_live_claim_survives_flag_aware_stat-claim-survived "a live peer's claim was swept"
  fi

  if [ "$rc" = "0" ]; then
    pass test_live_claim_survives_flag_aware_stat-exit-code "hook exited 0"
  else
    fail test_live_claim_survives_flag_aware_stat-exit-code "expected rc 0, got $rc"
  fi

  # Non-vacuity floor: only the stub writes this marker, so its absence means
  # the run never reached a stat chain and the assertions above passed without
  # exercising anything.
  if [ -f "$TMPROOT/$c/stat.called" ]; then
    pass test_live_claim_survives_flag_aware_stat-stat-called "the sweep decision read the stubbed stat"
  else
    fail test_live_claim_survives_flag_aware_stat-stat-called "the stubbed stat was never called — the case never reached the chain"
  fi
}

# AC 4: the two plugin-private copies must not drift apart. Their hooks.json
# pair is checked too — the shared matcher is what makes the double dispatch
# happen at all. Each path is floored on existence so a deleted file cannot
# read as identical.
test_hook_copies_are_identical() {
  for f in "$PORTFOLIO_HOOK" "$WORKSPACE_HOOK" "$PORTFOLIO_HOOKS_JSON" "$WORKSPACE_HOOKS_JSON"; do
    if [ ! -s "$f" ]; then
      fail test_hook_copies_are_identical-surface-$(path_slug "$f") "missing or empty: $f"
      return
    else
      pass test_hook_copies_are_identical-surface-$(path_slug "$f") "present and non-empty: $f"
    fi
  done

  if cmp -s "$PORTFOLIO_HOOK" "$WORKSPACE_HOOK"; then
    pass test_hook_copies_are_identical-hooks-identical "hook copies are byte-identical"
  else
    fail test_hook_copies_are_identical-hooks-identical "hook copies have diverged"
  fi

  # The two survivors' hooks.json can no longer be compared byte-for-byte:
  # cogni-workspace's is a merge that also declares SessionStart and carries no
  # top-level description, so `cmp` would report a divergence that is by design.
  # What must not drift is the dispatch itself, so assert that the two plugins'
  # excalidraw PreToolUse blocks are equivalent entry-for-entry.
  portfolio_pre="$(pretooluse_field "$PORTFOLIO_HOOKS_JSON" block)"
  workspace_pre="$(pretooluse_field "$WORKSPACE_HOOKS_JSON" block)"
  # The emptiness guard is load-bearing: without it two unreadable files would
  # both yield "", compare equal, and green the arm without reading a matcher.
  if [ -z "$portfolio_pre" ] || [ -z "$workspace_pre" ]; then
    fail test_hook_copies_are_identical-pretooluse-block "a PreToolUse block could not be read"
  elif [ "$portfolio_pre" = "$workspace_pre" ]; then
    pass test_hook_copies_are_identical-pretooluse-block "PreToolUse blocks are equivalent"
  else
    fail test_hook_copies_are_identical-pretooluse-block "PreToolUse blocks have diverged"
  fi
}

# Per-arm liveness floor the behavioural cases cannot reach: a release armed
# for EXIT alone would pass every case above and still strand the claim when
# the harness kills the hook at its declared timeout.
test_release_is_trapped_for_signals() {
  for h in "${EXCALIDRAW_HOOKS[@]}"; do
    hslug="$(hook_slug "$h")"
    code="$(hook_code "$h")"

    traps="$(printf '%s\n' "$code" | grep -cE '^[[:space:]]*trap ')"
    if [ "$traps" != "1" ]; then
      fail test_release_is_trapped_for_signals-trap-count-$hslug "expected exactly 1 trap line in $h, got $traps"
      continue
    else
      pass test_release_is_trapped_for_signals-trap-count-$hslug "exactly 1 trap line in $h"
    fi

    trapline="$(printf '%s\n' "$code" | grep -E '^[[:space:]]*trap ')"
    case "$trapline" in
      *EXIT*INT*TERM*) pass test_release_is_trapped_for_signals-trap-signals-$hslug "release trapped for EXIT INT TERM" ;;
      *) fail test_release_is_trapped_for_signals-trap-signals-$hslug "trap does not cover INT/TERM: $trapline" ;;
    esac

    if printf '%s\n' "$code" | grep -q 'mkdir -p'; then
      fail test_release_is_trapped_for_signals-bare-mkdir-$hslug "claim uses mkdir -p, which cannot tell winner from loser"
    else
      pass test_release_is_trapped_for_signals-bare-mkdir-$hslug "claim is a bare mkdir"
    fi

    # The release must be guarded by the claim flag, or a loser deletes the
    # winner's claim on its way out through the shared wait-loop exits.
    if printf '%s\n' "$code" | grep -A 3 'release_start_claim()' | grep -q 'SPAWN_CLAIMED'; then
      pass test_release_is_trapped_for_signals-release-guarded-$hslug "release is guarded by the claim flag"
    else
      fail test_release_is_trapped_for_signals-release-guarded-$hslug "release is not guarded by the claim flag in $h"
    fi

    # No claim machinery may sit above the fast path: an already-warm canvas
    # must stay a bare probe plus a /health call, and the acceptance contract
    # pins this textually, not just by runtime cost.
    fastline="$(printf '%s\n' "$code" | grep -n 'has_ws_client; then' | head -1 | cut -d: -f1)"
    if [ -n "$fastline" ]; then
      above="$(printf '%s\n' "$code" | sed -n "1,${fastline}p" | grep -cE 'LOCK_DIR|LOCK_STALE_SECS|SPAWN_CLAIMED|canvas-start.lock|_claim')"
      if [ "$above" = "0" ]; then
        pass test_release_is_trapped_for_signals-fast-path-$hslug "fast path carries no claim machinery"
      else
        fail test_release_is_trapped_for_signals-fast-path-$hslug "$above claim token(s) above the fast path in $h"
      fi
    else
      fail test_release_is_trapped_for_signals-fast-path-$hslug "could not locate the fast path in $h"
    fi

    # The staleness sweep must outlast the hook's own declared timeout, or a
    # healthy in-flight winner gets robbed and the double spawn comes back.
    secs="$(printf '%s\n' "$code" | sed -n 's/^[[:space:]]*LOCK_STALE_SECS=\([0-9][0-9]*\)[[:space:]]*$/\1/p')"
    hooks_json="$(dirname "$h")/hooks.json"
    timeout="$(pretooluse_field "$hooks_json" timeout)"
    if [ -n "$secs" ] && [ -n "$timeout" ] && [ "$secs" -gt "$timeout" ]; then
      pass test_release_is_trapped_for_signals-staleness-outlasts-timeout-$hslug "staleness $secs s outlasts the $timeout s hook timeout"
    else
      fail test_release_is_trapped_for_signals-staleness-outlasts-timeout-$hslug "staleness ($secs) does not outlast the hook timeout ($timeout)"
    fi
  done
}

ALL_TESTS="test_cold_start_spawns_exactly_one_server test_stale_lock_does_not_deadlock test_concurrent_stale_claim_spawns_exactly_one_server test_stale_lock_survives_divergent_stat test_live_claim_survives_flag_aware_stat test_hook_copies_are_identical test_release_is_trapped_for_signals"

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
  printf '\nRESULT: %d check(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nRESULT: all checks passed\n'
