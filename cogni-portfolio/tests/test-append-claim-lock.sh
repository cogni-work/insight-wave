#!/usr/bin/env bash
# Regression test for cogni-portfolio/scripts/append-claim.sh covering the
# stale-lock sweep's mtime reading — the BSD-first `stat` chain that returns a
# successful *wrong* answer on GNU coreutils — and the script's output-envelope
# contract on every emit path, success and failure alike.
#
# Fixtures are built inline under a temp root — no committed blobs to maintain.
# Most cases build a minimal claims project, pre-create the lock directory so
# the acquire loop is genuinely contended, shadow `stat` with a stub on PATH,
# run the script, and assert on the exit code plus both output streams. Cases 7
# and 8 are the exceptions and build less than that — see the note below.
#
# Coverage:
#   1  stale-lock-swept-on-non-numeric-stat   non-numeric mtime reading is floored
#                                             to 0, the ancient lock is swept, the
#                                             claim appends, and stderr stays empty
#   2  live-lock-not-swept-on-numeric-stat    negative twin — a numeric current-epoch
#                                             reading leaves a LIVE peer's lock
#                                             alone; the script times out instead
#   3  live-lock-not-swept-on-gnu-stat        the ordering pin — a FLAG-AWARE stub
#                                             simulating GNU, where `-f` means
#                                             --file-system and answers with a
#                                             non-mtime, so only a chain that tries
#                                             `-c` first reads the true mtime and
#                                             leaves a LIVE peer's lock alone
#   4  probe-resolved-once-per-acquire        the memo pin — a COUNTING stub on a
#                                             lock whose rmdir always fails records
#                                             exactly ONE GNU-form probe across the
#                                             four stale-block entries, not one per
#                                             entry
#   5  stale-sweep-bounded-when-rmdir-fails   the re-entry bound — an unremovable
#                                             lock reaches the timeout branch and
#                                             exits, instead of sweeping at 10Hz
#                                             forever with the diagnostic dead
#                                             behind an always-firing `continue`
#   6  no-working-stat-form-still-appends     neither form resolves, so the reading
#                                             floors to 0 exactly as the old
#                                             per-read `|| echo 0` tail did, and
#                                             stderr still stays empty
#   7  uncontended-acquire-spawns-no-stat     the hot-path guard — an acquire that
#                                             never contends must spawn NO stat at
#                                             all; this is what forbids resolving
#                                             the form ahead of the loop
#   8  no-arguments-emits-usage-envelope      the argument guard — the one failure
#                                             path that never reaches the acquire
#                                             loop writes a SINGLE error-envelope
#                                             object to stderr and exits 1, asserted
#                                             by shape and not by message alone
#
# Every case that CONTENDS drives the acquire loop to its ceiling on purpose, so
#   each sets APPEND_CLAIM_MAX_WAIT as a per-invocation prefix rather than paying
#   the production 3s: cases 1-3 use 3 (0.3s) and cases 4-6 use 1 (0.1s). That is
#   what keeps the whole suite near four seconds — measured, not estimated — rather
#   than the ~7.3s it cost when the ceiling was a hardcoded constant. Cases 4 and 5
#   each drive the loop through the full sweep budget, so they carry most of the
#   ~2.4s this suite grew by; folding them into one invocation that emits two result
#   lines would recover roughly half of that if the budget ever needs tightening.
#   Cases 7 and 8 are the deliberate exceptions and never contend at all. Case 7
#   exists to prove the UNcontended acquire stays fork-free, so driving the loop is
#   precisely what it must not do; case 8 returns at the argument guard before the
#   loop is reached at all, so it has no loop to drive.
#   The prefix is deliberately NOT a suite-level export: run-plugin-tests.py
#   invokes each suite as a bare `bash <path>`, so each case must carry its own
#   ceiling.
#   Cases 2, 3 and 5 assert the DERIVED form of that ceiling in their stderr
#   literal (`after 0.3s`, `after 0.1s`), not a fixed string — change a ceiling and
#   the literal moves with it. That coupling is the point: it is what stops the
#   message from drifting back into restating a number the loop no longer honours.
#
# Usage: bash cogni-portfolio/tests/test-append-claim-lock.sh
# Exits non-zero on any assertion failure.
#
# This suite has NO per-case selector — all cases are unconditional top-level
#   code, so an argument naming one is ignored. The recipe below therefore runs
#   the whole suite, and the harness classifies on the named case's output line.
#
# Mutation recipe — the SHARED cogni-service harness. Replayable as written, from the
#   repo root:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/lock_mtime=0/lock_mtime_unused=0/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case stale-lock-swept-on-non-numeric-stat
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.
#
#   The expression redirects the shape floor's assignment to a dead variable, so
#   the non-numeric reading survives into the arithmetic. `lock_mtime=0` occurs
#   exactly once in the fixed script — BOTH read paths of the memoizing probe
#   spell the assignment as a command substitution and neither contains that
#   literal — so the substitution can never be a no-op.
#
#   Second arm — the shape floor, case 2's side of it:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/\^\[0-9\]\+\$/^NOMATCH\$/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-numeric-stat
#
#   Arm one mutates the floor's ASSIGNMENT and is caught by case 1; this one
#   mutates the floor's CONDITION and is caught by case 2, which is why both are
#   recorded rather than one standing in for the other. Replacing the character
#   class with one that cannot match makes the `||` fire unconditionally, so a
#   live peer's current-epoch reading is floored to 0, reads as ancient, gets
#   swept, and the script goes on to append — case 2 sees exit 0 where it demands
#   exit 1. The pattern's `^` and `$` are ESCAPED, i.e. matched as the literal
#   characters of the regex text on the floor line, not as anchors — so the
#   expression needs no `/m` under the harness's `perl -0pi`, which slurps the
#   whole file. `^[0-9]+$` occurs exactly once (the ceiling's own floor above
#   reads `^[1-9][0-9]*$`), so the substitution can never be a no-op.
#
#   Third arm — the ceiling-to-message coupling:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/APPEND_CLAIM_MAX_WAIT:-30/APPEND_CLAIM_MAX_WAIT_UNUSED:-30/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-numeric-stat
#
#   The expression redirects the override to a dead variable, so the script
#   ignores the ceiling the cases set, waits the production 3s and announces
#   `after 3s` while case 2 asserts the derived `after 0.3s`. That is exactly the
#   decoupling this arm exists to catch: without it, a message that restates a
#   constant instead of deriving one stays green. `APPEND_CLAIM_MAX_WAIT:-30`
#   occurs exactly once (the header names the variable in prose without the
#   `:-30` default), so the substitution can never be a no-op, and the expression
#   carries no `^`/`$` anchor so it needs no `/m` under the harness's `perl -0pi`.
#
#   Fourth arm — the GNU-first ORDERING:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/stat -c %Y/stat -f %m/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-gnu-stat
#
#   The expression swaps the chain back to BSD-first while leaving the shape floor
#   intact, so this arm mutates the ORDERING rather than the floor arms one and two
#   cover. Under case 3's flag-aware stub the mutated script calls `stat -f %m`
#   first; the stub answers `%m` and exits 0, so the `||` never falls through, the
#   floor coerces that non-numeric reading to 0, a LIVE peer's lock reads as ancient
#   and is swept, and the script appends and exits 0 where case 3 demands exit 1.
#   That is the whole reason the ordering is worth pinning on its own merits: the
#   floor makes this failure silent rather than loud, it does not make it safe, and
#   the host it strikes is exactly the one — Linux — the GNU-first fix was about.
#
#   Only case 3 catches this arm. Cases 1 and 2 pass a stub that ignores its flags,
#   so they answer identically under either ordering and stay ordering-agnostic by
#   design — which is why this arm names case 3 and not one of them. `stat -c %Y`
#   occurs exactly once in the script — it is the FIRST entry of the memoizing
#   probe's candidate list, and no comment restates it — so the substitution can
#   never be a no-op, and the expression carries no `^`/`$` anchor so it needs no
#   `/m` under the harness's `perl -0pi`.
#
#   Fifth arm — the MEMO (the probe is resolved once per acquire, not per pass):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/STAT_MTIME="\$stat_form"/STAT_MTIME=""/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case probe-resolved-once-per-acquire
#
#   The expression stops the winning form from ever being recorded, so the sentinel
#   test at the top of the block stays true and EVERY stale-block entry re-probes
#   from the start of the candidate list. Case 4's counting stub then records one
#   GNU-form call per entry instead of one per acquire, and its exact-count
#   assertion goes red. `STAT_MTIME="$stat_form"` occurs exactly once (the
#   initialiser spells `STAT_MTIME=""` and the memoized read spells
#   `$STAT_MTIME`), so the substitution can never be a no-op, and the expression
#   carries no `^`/`$` anchor so it needs no `/m`.
#
#   Sixth arm — the RE-ENTRY BOUND:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/MAX_SWEEPS=3/MAX_SWEEPS=9/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case stale-sweep-bounded-when-rmdir-fails
#
#   The expression WIDENS the sweep budget rather than removing it, so the bounded
#   case sees more sweeps than it allows and goes red. `MAX_SWEEPS=3` occurs
#   exactly once, and the expression carries no `^`/`$` anchor so it needs no `/m`.
#
#   STANDING RULE for any future arm on this bound: widen it, never delete it.
#   Removing `MAX_SWEEPS` — or dropping the `SWEEPS` increment, which leaves the
#   counter at 0 forever — makes the MUTATED script non-terminating on case 5's
#   unremovable-lock fixture. The harness would then HANG rather than report red,
#   and because this suite has no per-case selector the harness runs every case, so
#   one hanging case hangs the entire replay. A widening reproduces the same defect
#   observably and terminates.
#
#   Seventh arm — the OUTPUT ENVELOPE itself:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/True/False/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case stale-lock-swept-on-non-numeric-stat
#
#   The expression flips the success envelope's own flag. `True` occurs exactly once
#   in the script — the two bash-side emits spell the key double-quoted with a
#   lowercase `false`, and the python failure branch spells it `False` — so the
#   substitution can never be a no-op, and it carries no `^`/`$` anchor so it needs
#   no `/m` under the harness's `perl -0pi`.
#
#   Three cases catch this arm — 1, 6 and 7 — because those are the three that both
#   reach the success print and assert its shape. Cases 2, 3 and 5 exit from the
#   acquire loop before the print, and case 4 discards stdout. The arm names case 1
#   only because `--case` takes one name; any of the three discriminates.
#
#   Under the mutation the script still exits 0 and still writes nothing to stderr,
#   and its stdout still parses as JSON — so the exit-code and stderr-emptiness
#   assertions stay green and only the envelope assertion discriminates. That is
#   precisely what makes asserting the whole envelope, rather than the nested status
#   alone, worth its line in all three.
#
#   Eighth arm — the TIMEOUT envelope's SHAPE, as distinct from its message:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/\\"data\\": null, //' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case live-lock-not-swept-on-numeric-stat
#
#   The expression drops the `data` key from the timeout envelope. It matches the
#   ESCAPED spelling exactly once — the bash-side emit inside the acquire loop's
#   double-quoted string; the two unescaped spellings in the SCRIPT, in its own
#   header comment documenting the envelope and in the argument guard's
#   single-quoted literal, cannot match it. It carries no `^`/`$` anchor, so it
#   needs no `/m` under the harness's `perl -0pi`.
#
#   Cases 2 and 3 both catch this arm — both reach the timeout emit and both now
#   assert its shape. Case 5 reaches the SAME envelope but asserts only the message
#   grep, so it stays green under the mutation and is deliberately not a catcher.
#   The arm names case 2 only because `--case` takes one name.
#
#   Under the mutation the script still exits 1, still writes one line to stderr,
#   and that line still carries the timeout message and still parses as JSON — so
#   the exit-code assertion and the message grep both stay green, and only the
#   structural check discriminates. That is what makes the structural check evidence
#   rather than decoration, and it is why the grep was kept alongside it rather than
#   replaced by it: the two pin different things.
#
#   Ninth arm — the USAGE envelope's shape:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/append-claim.sh \
#     --expr 's/"data": null, "error": "Usage/"error": "Usage/' \
#     --test 'bash cogni-portfolio/tests/test-append-claim-lock.sh' \
#     --case no-arguments-emits-usage-envelope
#
#   The expression drops the `data` key from the argument guard's envelope. It
#   matches exactly once — the guard's own emit; the SCRIPT's header comment spells
#   the surrounding text differently and cannot match. It carries no `^`/`$` anchor,
#   so it too needs no `/m`.
#
#   Case 8 is the only catcher, because it is the only case that runs the script
#   with no arguments. Under the mutation the guard still exits 1, still writes one
#   line to stderr, and that line still carries the `Usage:` literal — so every
#   assertion in case 8 except the structural one stays green. A case that asserted
#   the usage path by message alone would not have caught this.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-case failure counter below. All cases also run a script that is
# EXPECTED to exit non-zero in two of them.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/append-claim.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: append-claim.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one `<case>: <msg>` string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# Build a stub `stat` on its own PATH prefix. The directory holds exactly one
# file so `date` and `python3` keep resolving to the real binaries — the script
# calls all three by bare name.
#
# The helper is body-agnostic — it writes whatever `$2` holds — and the suite uses
# that in two deliberately different ways. Cases 1 and 2 pass a body that ignores
# its flags and answers unconditionally: the `||` chain short-circuits on the first
# exit-0 call, so such a body is correct under both the pre-fix BSD-first and the
# post-fix GNU-first ordering, which keeps those two cases from being coupled to
# the ordering the fix happens to land with. Case 3 passes a FLAG-AWARE body and is
# coupled to the ordering on purpose — that coupling is the thing it exists to pin.
make_stat_stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\n%s\n' "$2" > "$1/stat"
  chmod +x "$1/stat"
}

# Each case needs its OWN project directory. The swept path installs the script's
# release trap and cleans the lock up on exit; the timeout path exits from inside
# the acquire loop BEFORE that trap line is reached and deliberately leaves the
# lock behind. Reusing one directory would let case order decide the result.
seed_contended_project() {
  local pdir="$TMPROOT/$1"
  mkdir -p "$pdir/cogni-claims"
  mkdir "$pdir/cogni-claims/.claims.lock"
  printf '%s' "$pdir"
}

# Two fixtures the seeder above structurally cannot produce, each needed by a case
# below. The blocker variant puts a FILE inside the lock directory, which is what
# makes `rmdir` fail with ENOTEMPTY permanently — the script swallows that failure
# (`2>/dev/null || true`), so without a sweep budget the loop would re-enter every
# 100ms forever. The uncontended variant creates no lock at all, so the acquire
# succeeds on the loop's first condition test and the body never runs.
seed_blocked_project() {
  local pdir="$TMPROOT/$1"
  mkdir -p "$pdir/cogni-claims/.claims.lock"
  : > "$pdir/cogni-claims/.claims.lock/blocker"
  printf '%s' "$pdir"
}

seed_uncontended_project() {
  local pdir="$TMPROOT/$1"
  mkdir -p "$pdir/cogni-claims"
  printf '%s' "$pdir"
}

# A counting variant of make_stat_stub: the stub records its FIRST ARGUMENT — the
# flag it was called with — one per line, then runs the caller's behaviour. That
# is what lets a case assert a spawn count by measurement rather than by argument.
#
# The counter path is baked into the stub body at authoring time because the stub
# is a SEPARATE PROCESS: a bare `$TMPROOT` left for the stub's own shell to expand
# would resolve to nothing. `$1` is left unexpanded on purpose so it means the
# stub's argument, not this suite's.
#
# The counter must NOT live in the stub directory. That directory holds exactly one
# file so `date` and `python3` keep resolving to the real binaries (see
# make_stat_stub above); a second file there would erode the invariant the whole
# stubbing scheme rests on. Each caller also passes its OWN counter path — the stub
# appends, so a shared counter would bleed counts between cases and make both
# assertions meaningless.
make_counting_stat_stub() {
  mkdir -p "$1"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$1" >> "%s"\n' "$2"
    printf '%s\n' "$3"
  } > "$1/stat"
  chmod +x "$1/stat"
}

# --- Case 1: a non-numeric mtime reading must be floored, not fed to arithmetic.
#
# The stub prints `%m`, and the value MUST stay non-identifier-shaped. `$(( now -
# lock_mtime ))` reads a VARIABLE, and bash evaluates an identifier-shaped value
# recursively, which opens two escape hatches that would make this case vacuous:
# a bare word like `bogus` aborts only because `set -u` happens to be on, and a
# word naming a variable the script already sets (`MAX_WAIT`) resolves to a
# NUMBER and never aborts at all. `%m` is a hard operand syntax error under both.
#
# The stderr assertion is equally load-bearing. On every bash tested — 3.2.57
# through 5.3.9 alike — an arithmetic abort inside a `while` loop abandons the
# loop body AND the loop, then resumes after `done`. The UNFIXED script therefore
# still installs the trap, appends the claim and exits 0 with the success envelope
# carrying data.status=appended, never having held the lock; its EXIT trap then
# removes a live peer's lock directory it never owned. Exit code and stdout are consequently identical
# before and after the fix, so only stderr discriminates. A case asserting just
# exit-0 and stdout stays green under the mutation recipe above, i.e. it pins
# nothing.
#
# The discriminator is stderr EMPTINESS, not a text match. Bash's arithmetic-error
# message is gettext-localized, and it varies along TWO axes, not one: the host
# locale, and whether the bash build ships translations at all. Measured on a
# single host under one unchanged locale, bash 3.2.57 emits `syntax error: operand
# expected` while bash 5.3.9 emits `Arithmetischer Syntaxfehler: Operand erwartet`.
# So a grep for the English wording matches nothing, the case passes against the
# UNFIXED script, and the guard guards nothing — and pinning the locale would not
# have saved it, because the version axis remains. The fixed script writes exactly
# 0 bytes here, so emptiness is independent of both axes and catches every
# diagnostic rather than one translation of one of them.
#
# The general rule, worth keeping in view when adding a case: assert a FOREIGN
# tool's output by SHAPE (exit status, stream emptiness, numeric form), and only
# our OWN scripts' literals by text. Cases 2 and 3 below grep `Could not acquire
# lock` precisely because append-claim.sh emits that string itself.
case1_dir="$(seed_contended_project stale-non-numeric)"
case1_stub="$TMPROOT/stub-non-numeric"
make_stat_stub "$case1_stub" 'echo "%m"'
case1_out="$(PATH="$case1_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case1_dir" '{"id": "claim-1"}' 2>"$TMPROOT/case1.err")"
case1_rc=$?

if [ "$case1_rc" -ne 0 ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected exit 0, got $case1_rc (stderr: $(cat "$TMPROOT/case1.err"))"
elif [ -s "$TMPROOT/case1.err" ]; then
  fail "stale-lock-swept-on-non-numeric-stat" "expected silence on stderr, got: $(cat "$TMPROOT/case1.err")"
elif ! printf '%s' "$case1_out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is True and d["data"]["status"] == "appended" and d["error"] is None else 1)' 2>/dev/null; then
  fail "stale-lock-swept-on-non-numeric-stat" "stdout did not parse as a {success,data,error} object with data.status=appended: $case1_out"
else
  pass "stale-lock-swept-on-non-numeric-stat" "floored to 0, ancient lock swept, claim appended"
fi

# --- Case 2 (negative twin): a numeric, current mtime means the lock is LIVE.
#
# Without this case a fix that unconditionally sets lock_mtime=0 satisfies case 1
# while destroying mutual exclusion — every contended lock would read as ancient
# and get swept out from under a running peer once the acquire ceiling elapses.
case2_dir="$(seed_contended_project live-numeric)"
case2_stub="$TMPROOT/stub-numeric"
make_stat_stub "$case2_stub" 'date +%s'
PATH="$case2_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case2_dir" '{"id": "claim-2"}' >/dev/null 2>"$TMPROOT/case2.err"
case2_rc=$?

if [ "$case2_rc" -ne 1 ]; then
  fail "live-lock-not-swept-on-numeric-stat" "expected exit 1, got $case2_rc"
elif ! grep -q 'Could not acquire lock on claims.json after 0.3s' "$TMPROOT/case2.err"; then
  fail "live-lock-not-swept-on-numeric-stat" "stderr did not carry the timeout error: $(cat "$TMPROOT/case2.err")"
elif ! python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is False and d["data"] is None else 1)' < "$TMPROOT/case2.err" 2>/dev/null; then
  fail "live-lock-not-swept-on-numeric-stat" "stderr did not parse as a {success,data,error} object with success=false and data=null: $(cat "$TMPROOT/case2.err")"
elif [ ! -d "$case2_dir/cogni-claims/.claims.lock" ]; then
  fail "live-lock-not-swept-on-numeric-stat" "a live peer's lock was swept"
else
  pass "live-lock-not-swept-on-numeric-stat" "fresh lock left intact, script timed out"
fi

# --- Case 3: the ordering pin — only a chain that tries `-c` first reads an mtime.
#
# Cases 1 and 2 cannot see the ordering at all, and that is by design: their stub
# answers unconditionally, so the `||` chain's first call succeeds whichever form
# it is, and both cases stay green under either ordering. The consequence is that
# nothing above pins the GNU-first chain — reverting it to BSD-first leaves the
# suite green. This case closes that gap with a FLAG-AWARE stub, which is the
# minimum needed to tell the two calls apart.
#
# The stub simulates GNU coreutils, where `-f` means --file-system rather than a
# format string: `-c` answers with a real current epoch, `-f` answers with the
# literal `%m` and — the load-bearing part — exits 0, so a BSD-first chain never
# falls through to its second call. Against the SHIPPED script this case is
# behaviourally identical to case 2: `-c` runs first, returns a numeric current
# epoch, the lock reads as live, and the script times out leaving it intact. The
# two diverge ONLY when the ordering is swapped, which is exactly what makes this a
# distinct case rather than a duplicate of case 2 — under the swap the `%m` reading
# is floored to 0, a live peer's lock reads as ancient and is swept, and the script
# appends and exits 0.
#
# The stub body is SINGLE-quoted so `$1` reaches the written file unexpanded rather
# than being substituted with this suite's own (empty) `$1` at authoring time, and
# make_stat_stub passes it as printf's ARGUMENT, so the `%m` inside it is never
# read as a format specifier — case 1's `echo "%m"` body is the precedent.
#
# The stderr grep is of append-claim.sh's OWN literal, which is why it is a text
# match at all. Anything the shell or coreutils emits is asserted by SHAPE here
# instead — those diagnostics are gettext-localized, so a text match on one would
# pass vacuously off an English-locale host.
case3_dir="$(seed_contended_project live-gnu-ordering)"
case3_stub="$TMPROOT/stub-gnu-ordering"
make_stat_stub "$case3_stub" 'case "$1" in
  -c) date +%s ;;
  -f) echo "%m" ;;
  *) exit 1 ;;
esac'
PATH="$case3_stub:$PATH" APPEND_CLAIM_MAX_WAIT=3 bash "$SCRIPT" "$case3_dir" '{"id": "claim-3"}' >/dev/null 2>"$TMPROOT/case3.err"
case3_rc=$?

if [ "$case3_rc" -ne 1 ]; then
  fail "live-lock-not-swept-on-gnu-stat" "expected exit 1, got $case3_rc — a BSD-first chain would sweep the live lock and append"
elif ! grep -q 'Could not acquire lock on claims.json after 0.3s' "$TMPROOT/case3.err"; then
  fail "live-lock-not-swept-on-gnu-stat" "stderr did not carry the timeout error: $(cat "$TMPROOT/case3.err")"
elif ! python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is False and d["data"] is None else 1)' < "$TMPROOT/case3.err" 2>/dev/null; then
  fail "live-lock-not-swept-on-gnu-stat" "stderr did not parse as a {success,data,error} object with success=false and data=null: $(cat "$TMPROOT/case3.err")"
elif [ ! -d "$case3_dir/cogni-claims/.claims.lock" ]; then
  fail "live-lock-not-swept-on-gnu-stat" "a live peer's lock was swept"
else
  pass "live-lock-not-swept-on-gnu-stat" "GNU-first chain read the true mtime, live lock left intact"
fi

# --- Case 4: the stat form is resolved ONCE per acquire, not once per pass.
#
# This is the MEASURED criterion, and it is measured rather than argued because the
# mechanism lives in an executable script, so a count is obtainable. The stub
# simulates a BSD host — the GNU form fails, the BSD form answers a numeric epoch 0
# — and records every flag it is called with.
#
# The fixture's lock carries a blocker file, so `rmdir` can never succeed and the
# loop is driven through the full sweep budget: four stale-block entries (three
# sweeps, then one pass where the budget is spent). A memoizing probe pays the
# failing GNU form on the FIRST entry only, so the tally is exactly one `-c` and
# four `-f`. An un-memoized chain re-probes on every entry and records four of each
# — which is what the fifth mutation arm above reproduces.
#
# The counts are asserted by SHAPE (a line count over the recorded flags), never by
# reading any stat diagnostic: the stub is ours, but `rmdir`'s ENOTEMPTY is not,
# and that one is gettext-localized.
case4_dir="$(seed_blocked_project probe-memo)"
case4_stub="$TMPROOT/stub-counting-bsd"
case4_counter="$TMPROOT/case4.count"
: > "$case4_counter"
make_counting_stat_stub "$case4_stub" "$case4_counter" 'case "$1" in
  -c) exit 1 ;;
  -f) echo 0 ;;
  *) exit 1 ;;
esac'
PATH="$case4_stub:$PATH" APPEND_CLAIM_MAX_WAIT=1 bash "$SCRIPT" "$case4_dir" '{"id": "claim-4"}' >/dev/null 2>"$TMPROOT/case4.err"
case4_rc=$?
case4_c=$(grep -c '^-c$' "$case4_counter" || true)
case4_f=$(grep -c '^-f$' "$case4_counter" || true)

if [ "$case4_rc" -ne 1 ]; then
  fail "probe-resolved-once-per-acquire" "expected exit 1 once the sweep budget is spent, got $case4_rc"
elif [ "$case4_c" -ne 1 ]; then
  fail "probe-resolved-once-per-acquire" "expected exactly 1 GNU-form probe across 4 stale-block entries, got $case4_c (the form is being re-probed per pass)"
elif [ "$case4_f" -ne 4 ]; then
  fail "probe-resolved-once-per-acquire" "expected 4 memoized reads, got $case4_f"
else
  pass "probe-resolved-once-per-acquire" "1 probe + 4 memoized reads across 4 entries"
fi

# --- Case 5: stale-sweep re-entry is BOUNDED, so an unremovable lock terminates.
#
# Against the pre-fix script this fixture never returns at all. `WAITED` only ever
# climbs, so once the ceiling test is true it stays true; the sweep `continue`s
# before the timeout branch can be reached, and a lock whose `rmdir` keeps failing
# is swept at 10Hz indefinitely. That is why this case and the bound ship together:
# there is no version of it that is both deterministic and writable against the
# unbounded script.
#
# The assertion is deliberately NOT a timeout wrapper. The bound makes termination
# a property of the script, so the case asserts the real contract — the script's own
# timeout diagnostic and exit 1 — with no race, no background process and no timing
# dependence. It also asserts the lock and its blocker SURVIVE: the sweep genuinely
# could not remove them, which is what distinguishes a bounded sweep from a
# successful one.
case5_dir="$(seed_blocked_project sweep-bounded)"
case5_stub="$TMPROOT/stub-counting-bounded"
case5_counter="$TMPROOT/case5.count"
: > "$case5_counter"
make_counting_stat_stub "$case5_stub" "$case5_counter" 'case "$1" in
  -c) exit 1 ;;
  -f) echo 0 ;;
  *) exit 1 ;;
esac'
PATH="$case5_stub:$PATH" APPEND_CLAIM_MAX_WAIT=1 bash "$SCRIPT" "$case5_dir" '{"id": "claim-5"}' >/dev/null 2>"$TMPROOT/case5.err"
case5_rc=$?
case5_f=$(grep -c '^-f$' "$case5_counter" || true)

if [ "$case5_rc" -ne 1 ]; then
  fail "stale-sweep-bounded-when-rmdir-fails" "expected exit 1, got $case5_rc"
elif ! grep -q 'Could not acquire lock on claims.json after 0.1s' "$TMPROOT/case5.err"; then
  fail "stale-sweep-bounded-when-rmdir-fails" "stderr did not carry the timeout error: $(cat "$TMPROOT/case5.err")"
elif [ ! -f "$case5_dir/cogni-claims/.claims.lock/blocker" ]; then
  fail "stale-sweep-bounded-when-rmdir-fails" "the blocker vanished — the fixture no longer makes rmdir fail"
elif [ ! -d "$case5_dir/cogni-claims/.claims.lock" ]; then
  fail "stale-sweep-bounded-when-rmdir-fails" "an unremovable lock was reported swept"
elif [ "$case5_f" -gt 4 ]; then
  fail "stale-sweep-bounded-when-rmdir-fails" "sweep re-entered $case5_f times, past the budget — the bound is not holding"
else
  pass "stale-sweep-bounded-when-rmdir-fails" "unremovable lock reached the timeout branch in $case5_f reads"
fi

# --- Case 6: when NEITHER form resolves, the old per-read fallback's semantics hold.
#
# The pre-fix chain ended in `|| echo 0`, so a host where both forms fail floored the
# reading to 0 on every read. Memoizing the form has to reproduce that, and the way
# it does is the `false` builtin as the no-form sentinel — non-empty, so it memoizes,
# and fork-free, with its non-zero status absorbed by the read's tail.
#
# stderr EMPTINESS is the load-bearing assertion here, and it is what pins that BOTH
# probe calls keep their `2>/dev/null`. Drop either redirect and a real BSD host's
# `stat: illegal option -- c` reaches stderr — a diagnostic this case would catch by
# shape without ever matching its wording, which it must not do, because that
# wording is gettext-localized and would pass vacuously off an English-locale host.
case6_dir="$(seed_contended_project no-working-form)"
case6_stub="$TMPROOT/stub-no-form"
make_stat_stub "$case6_stub" 'exit 1'
case6_out="$(PATH="$case6_stub:$PATH" APPEND_CLAIM_MAX_WAIT=1 bash "$SCRIPT" "$case6_dir" '{"id": "claim-6"}' 2>"$TMPROOT/case6.err")"
case6_rc=$?

if [ "$case6_rc" -ne 0 ]; then
  fail "no-working-stat-form-still-appends" "expected exit 0, got $case6_rc (stderr: $(cat "$TMPROOT/case6.err"))"
elif [ -s "$TMPROOT/case6.err" ]; then
  fail "no-working-stat-form-still-appends" "expected silence on stderr, got: $(cat "$TMPROOT/case6.err")"
elif ! printf '%s' "$case6_out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is True and d["data"]["status"] == "appended" and d["error"] is None else 1)' 2>/dev/null; then
  fail "no-working-stat-form-still-appends" "stdout did not parse as a {success,data,error} object with data.status=appended: $case6_out"
else
  pass "no-working-stat-form-still-appends" "no form resolved, reading floored to 0, ancient lock swept"
fi

# --- Case 7: an UNCONTENDED acquire must spawn no stat at all.
#
# This is the hot-path guard, and it is the case that forbids the obvious reading of
# "resolve the form once before the loop". An uncontended acquire never enters the
# loop body — the `while` condition's own mkdir succeeds — so it costs exactly one
# fork today. Resolving the form ahead of the loop would add one or two more to
# every such call, which is the overwhelmingly common one, in order to save forks on
# the rare contended path. Lazy resolution is what keeps this counter empty.
#
# The counter is pre-created empty so the assertion distinguishes "the stub never
# ran" from "the stub was never installed" — an emptiness test on a file that does
# not exist would pass for the wrong reason.
#
# The ceiling prefix is behaviourally inert here — this case never enters the
# acquire loop, which is the whole point of it — and is carried anyway so every
# case states its own ceiling rather than inheriting the production default by
# omission. A reader should not have to know a case never contends to know what
# ceiling it would run under.
case7_dir="$(seed_uncontended_project uncontended)"
case7_stub="$TMPROOT/stub-counting-uncontended"
case7_counter="$TMPROOT/case7.count"
: > "$case7_counter"
make_counting_stat_stub "$case7_stub" "$case7_counter" 'echo 0'
case7_out="$(PATH="$case7_stub:$PATH" APPEND_CLAIM_MAX_WAIT=1 bash "$SCRIPT" "$case7_dir" '{"id": "claim-7"}' 2>"$TMPROOT/case7.err")"
case7_rc=$?

if [ "$case7_rc" -ne 0 ]; then
  fail "uncontended-acquire-spawns-no-stat" "expected exit 0, got $case7_rc (stderr: $(cat "$TMPROOT/case7.err"))"
elif ! printf '%s' "$case7_out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is True and d["data"]["status"] == "appended" and d["error"] is None else 1)' 2>/dev/null; then
  fail "uncontended-acquire-spawns-no-stat" "stdout did not parse as a {success,data,error} object with data.status=appended: $case7_out"
elif [ -s "$case7_counter" ]; then
  fail "uncontended-acquire-spawns-no-stat" "an uncontended acquire spawned stat $(wc -l < "$case7_counter" | tr -d ' ') time(s) — the probe is no longer lazy"
else
  pass "uncontended-acquire-spawns-no-stat" "no stat spawned on the uncontended path"
fi

# --- Case 8: the argument guard emits the full error envelope, not a bare message.
#
# This is the script's one failure path that never reaches the acquire loop, so no
# case above exercises it at all — it returns at the argument check before the lock
# directory is ever created, which is also why this case needs no seeder and no stub
# and leaves nothing behind to clean up.
#
# The STRUCTURAL assertion is the discriminator, not the message match. A guard that
# regressed to emitting a bare `{"error": ...}` would keep the same message text, so
# a grep alone stays green while the envelope around it rots — which is precisely
# what the ninth mutation arm in the header above demonstrates.
#
# `Usage: append-claim.sh` is append-claim.sh's OWN literal, which is what makes a
# text match legitimate here. Everything the shell or coreutils could emit is
# asserted by SHAPE instead — the exit status, stdout emptiness, and a line COUNT —
# because those diagnostics are gettext-localized and a text match on one would pass
# vacuously off an English-locale host. Case 3's comment states the same rule.
#
# The line count is a genuine assertion rather than a formality: the guard's
# `${1:-}` defaults are what keep `set -u` from adding a second line here, so a
# regression to bare `$1` would show up as a count of 2 rather than as a message
# change. `wc -l` reads from a REDIRECT, never a filename argument — the argument
# form appends the filename to wc's output, which `tr -d ' '` does not strip, and
# the numeric comparison then dies on a non-numeric operand. Case 7 above is the
# precedent.
#
# The ceiling prefix is behaviourally inert here for the same reason it is on case
# 7 — the guard returns before the ceiling is ever read — and is carried anyway so
# every case states its own ceiling rather than inheriting the production default.
case8_out="$(APPEND_CLAIM_MAX_WAIT=1 bash "$SCRIPT" 2>"$TMPROOT/case8.err")"
case8_rc=$?

if [ "$case8_rc" -ne 1 ]; then
  fail "no-arguments-emits-usage-envelope" "expected exit 1, got $case8_rc (stderr: $(cat "$TMPROOT/case8.err"))"
elif [ -n "$case8_out" ]; then
  fail "no-arguments-emits-usage-envelope" "expected nothing on stdout, got: $case8_out"
elif [ "$(wc -l < "$TMPROOT/case8.err" | tr -d ' ')" -ne 1 ]; then
  fail "no-arguments-emits-usage-envelope" "expected exactly one newline-terminated line on stderr, got $(wc -l < "$TMPROOT/case8.err" | tr -d ' '): $(cat "$TMPROOT/case8.err")"
elif ! python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] is False and d["data"] is None and isinstance(d["error"], str) and d["error"] else 1)' < "$TMPROOT/case8.err" 2>/dev/null; then
  fail "no-arguments-emits-usage-envelope" "stderr did not parse as a {success,data,error} object with success=false, data=null and a non-empty error: $(cat "$TMPROOT/case8.err")"
elif ! grep -q 'Usage: append-claim.sh' "$TMPROOT/case8.err"; then
  fail "no-arguments-emits-usage-envelope" "stderr did not carry the usage message: $(cat "$TMPROOT/case8.err")"
else
  pass "no-arguments-emits-usage-envelope" "argument guard emitted the full error envelope on stderr"
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
