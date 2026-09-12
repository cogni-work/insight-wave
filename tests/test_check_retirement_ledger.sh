#!/usr/bin/env bash
# test_check_retirement_ledger.sh — self-test for the retirement-ledger gate.
#
# The gate asserts one invariant over TWO diff shapes: when a branch DELETES a
# cogni-workspace/skills/<name>/SKILL.md, or MODIFIES a surviving one so its
# frontmatter description no longer advertises a phrase, every trigger phrase
# that file advertised at the MERGE BASE must be accounted for at HEAD —
# re-claimed by a surviving live skill, or recorded in the retirement ledger
# with a non-empty reason. One accounting rule, reached by two routes.
#
# Cases:
#   1. delete a skill, write no ledger row -> retirement-row-missing, exit 1.
#      [retirement-ledger-01-missing-row]  <- the mutation-recipe target
#   2. delete a skill, all phrases recorded retired with reasons -> clean, 0.
#      [retirement-ledger-02-recorded-retired]
#   3. delete a skill whose phrases a SURVIVING skill re-quotes -> clean, 0.
#      [retirement-ledger-03-reclaimed-by-survivor]
#   4. a branch that deletes no skill at all -> clean, 0.
#      [retirement-ledger-04-no-deletion]
#   5. no refs/remotes/origin/main -> status degraded, exit 0. A guard that
#      cannot see the baseline must not block every PR on a shallow runner.
#      [retirement-ledger-05-degraded-no-origin]
#   6. main advanced past the fork and deleted a skill of its OWN; the branch
#      deleted nothing -> clean. This is the merge-base-anchoring regression
#      test: a base-TIP anchor would read main's deletion as the branch's and
#      false-flag it. [retirement-ledger-06-merge-base-anchoring]
#   7. two phrases, one recorded and one not -> exactly ONE violation, exit 1.
#      Proves the guard reports per phrase, not per file.
#      [retirement-ledger-07-partial-accounting]
#   8. a ledger row exists but its reason is empty -> does NOT account, exit 1.
#      The documented remedy is recording the retirement WITH a justification.
#      [retirement-ledger-08-empty-reason]
#   9. the deleted skill used a `>-` block scalar -> its phrases are still
#      extracted and still demanded, proving the YAML unwrap runs before the
#      quote hunt. [retirement-ledger-09-block-scalar]
#  10. --emit-phrases spawns no git subprocess, so C11 cannot redden the shallow
#      plugin-test-suites job. [retirement-ledger-10-emit-phrases-no-git]
#  11. the deleted skill could not be PARSED at the merge base -- no frontmatter
#      block (arm a), and a block with no `description:` key (arm b). Both are
#      recorded as a base-blob-unparseable OBSERVATION and neither moves the
#      exit code: such a file was not a loadable skill, so it advertised no
#      trigger phrase and its deletion loses no claim surface. Recording it is
#      what keeps the exit-0 summary from claiming accounting it never did.
#      [retirement-ledger-11-unparseable-base-blob]
#  12. one deletion of each kind in one branch -> the observation and the
#      violation co-report, and the violation count counts only the violation.
#      [retirement-ledger-12-mixed-violation-kinds]
#  13. the skill is retired by `git mv`-ing its SKILL.md out of skills/ rather
#      than removing it -> still a deletion the ledger must account for. Without
#      --no-renames git reports R, the D filter sees nothing, and the guard exits
#      0 announcing "no skill deletion" while the phrases are gone.
#      [retirement-ledger-13-move-out-of-skills-is-a-retirement]
#  14. an unparseable SKILL.md that stays LIVE at HEAD while a DIFFERENT skill
#      is deleted -> the live file excuses nothing, so the deleted skill's
#      phrases are still demanded, and the observation channel stays empty
#      because nothing unparseable was DELETED. Cases 11 and 12 both delete the
#      unparseable file, so neither one ever reaches the live side.
#      [retirement-ledger-14-unparseable-live-at-head]
#  15. --emit-phrases over a dir mixing one parseable skill with BOTH
#      unparseable shapes -> exactly one phrase line, exit 0. Drop parity
#      mode's skip and the sentinel is iterated instead: the run dies
#      mid-stream, so the line count and the exit code both move.
#      [retirement-ledger-15-emit-phrases-skips-unparseable]
#  16. a SURVIVING skill's description drops a phrase that no sibling re-claims
#      and no ledger row records -> one violation. The modified-subject mirror
#      of case 1. [retirement-ledger-16-description-drop-unaccounted]
#  17. rewording the prose AROUND unchanged quoted phrases is not a drop, so an
#      ordinary description edit is not taxed.
#      [retirement-ledger-17-description-reword-clean]
#  18. both remedies discharge a drop — a ledger row, and a re-claim by a
#      surviving sibling. Two arms, one id.
#      [retirement-ledger-18-description-drop-accounted]
#  19. the surviving file is UNPARSEABLE AT HEAD: it contributes nothing to the
#      live set, so BOTH of its base phrases are demanded. Observations stay
#      empty — the base blob parsed, and there is no head-side observation
#      channel. [retirement-ledger-19-modified-head-unparseable]
#  20. main advanced past the fork and reworded a skill of its own; this branch
#      touched no SKILL.md. The case-6 analogue for the modified subject.
#      [retirement-ledger-20-modified-merge-base-anchoring]
#  21. both subjects in one branch -> the two checks co-report without moving
#      each other's counts. [retirement-ledger-21-mixed-subjects]
#  22. the modified file was UNPARSEABLE AT THE MERGE BASE, so it advertised
#      nothing to lose -> an observation, the mirror of case 11, and the only
#      case that observes the per-subject `checked` arithmetic.
#      [retirement-ledger-22-modified-base-unparseable]
#  23. a modification-only branch that also removes the ledger still returns a
#      determinate verdict rather than an unhandled-error exit 2.
#      [retirement-ledger-23-modified-no-ledger]
#  24. a retained phrase whose RAW TEXT changes case and internal whitespace
#      normalizes to the same key, so it was never dropped. Pins that the
#      modified arm compares normalized keys rather than raw phrase text.
#      [retirement-ledger-24-description-normalize-clean]
#
# Cases 2, 7 and 8 transitively pin the modified side's path scoping: each
# OVERWRITES the existing ledger, so the ledger TSV is a genuine M row that
# SKILL_PATH_RE must reject. (Case 4's README.md is an ADD — make_repo writes
# none — so the filter never sees it and it pins nothing here.) Case 3 rewrites
# beta's description, adding phrases rather than dropping any, so it is a live
# modified-arm case that must stay clean.
#
# bash 3.2 + stdlib python3 + git. No network.
#
# Every case builds its OWN git fixture repo — no case runs the gate against the
# real checked-out tree, so the deliberately shallow plugin-test-suites job
# (.github/workflows/lint.yml) cannot redden on a missing base ref.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id in the
# repo-root <suite-slug>-<NN>[-<discriminator>] shape documented in CLAUDE.md —
# deliberately NOT the compact cvb01 form the sibling suite happens to use, and
# not the C-prefixed convention local to
# cogni-workspace/tests/test-skill-trigger-phrases.sh. The id is followed by a
# SPACE, never a colon abutting it, so a harness matching the whole token
# resolves it. Both arms of a case receive the same id from one argument, so
# they cannot drift apart.
#
# Mutation recipe — the live-set sentinel filter:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-retirement-ledger.py \
#     --expr 's/if keys is not UNPARSEABLE //' \
#     --test 'bash tests/test_check_retirement_ledger.sh' \
#     --case retirement-ledger-14-unparseable-live-at-head
#
# The mutation drops live_phrase_keys()'s filter, so the set comprehension
# iterates the truthy UNPARSEABLE sentinel, raises TypeError, and the run
# resolves to the unhandled-error envelope at exit 2 rather than to a verdict.
# Case 14 asserts the whole tuple, so that movement reddens it. The anchor
# occurs exactly once, and removing it leaves the comprehension's bracket
# continuation valid Python rather than a SyntaxError that would red every
# case and grade nothing. No /m modifier: the expression carries no ^/$ anchor.
#
# Mutation recipe — parity mode's skip:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-retirement-ledger.py \
#     --expr 's/byte-identical to it\.\n                continue/byte-identical to it.\n                pass/' \
#     --test 'bash tests/test_check_retirement_ledger.sh' \
#     --case retirement-ledger-15-emit-phrases-skips-unparseable
#
# `if keys is UNPARSEABLE:` is spelled identically in emit_phrases() and in
# main(), so this expression anchors on the comment text unique to the parity
# arm and swaps `continue` for `pass`, leaving the block syntactically valid so
# only that one arm's behaviour moves. The 16-space indent is part of the
# anchor. --expr reaches `perl -0pi` through a quoted expansion, so the literal
# \n and \. survive; -0 slurps the file, which is what lets \n bind without /m.
#
# Mutation recipe — the modified-file half of the diff filter:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-retirement-ledger.py \
#     --expr 's/"--diff-filter=DM"/"--diff-filter=D"/' \
#     --test 'bash tests/test_check_retirement_ledger.sh' \
#     --case retirement-ledger-16-description-drop-unaccounted
#
# The mutation narrows the one diff query back to deletions, which is exactly
# the regression this suite's modified-subject cases exist to catch: the branch
# in case 16 deletes nothing, so the status split yields two empty lists, the
# both-empty early return fires, and the tuple moves from
# 1|ok|description-phrase-dropped|1|EMPTY to 0|ok|EMPTY|0|EMPTY. The anchor is
# the QUOTED argument-list form and occurs exactly once — every prose mention of
# the filter in this file and in the guard is backticked, never wrapped in ASCII
# double quotes — and the mutant is valid Python, so only the subject moves
# rather than reddening every case and grading nothing.

set -eu

# The gate reads its base ref from RETIREMENT_LEDGER_BASE_REF before falling back
# to origin/main. Under CI an ambient value would be read in place of each
# fixture's own ref, so every case would grade against the wrong baseline. Clear
# it once, here, so the fixtures exercise the default identically everywhere.
unset RETIREMENT_LEDGER_BASE_REF || true

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$REPO_ROOT/scripts/check-retirement-ledger.py"

# Plain text on purpose — result lines are machine-read; tooling anchors a
# literal PASS:/FAIL: prefix. Emit unconditionally, never probe the environment.
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=$((FAILED + 1))
  fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GIT="git -c user.email=t@test -c user.name=test -c commit.gpgsign=false"

SKILLS="cogni-workspace/skills"
LEDGER="cogni-workspace/references/retired-trigger-phrases.tsv"

# write_skill <root> <dir> <name> <phrase...> — a plain double-quoted scalar.
write_skill() {
  local root="$1" dir="$2" name="$3"; shift 3
  local body="" p
  for p in "$@"; do body="$body \\\"$p\\\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $name
description: "Use this skill when the user says$body."
---

# $name
EOF
}

# write_block_skill <root> <dir> <name> <phrase...> — a \`>-\` block scalar, so
# the unwrap-before-quote-hunt path is exercised rather than the quoted one.
write_block_skill() {
  local root="$1" dir="$2" name="$3"; shift 3
  local body="" p
  for p in "$@"; do body="$body \"$p\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $name
description: >-
  Use this skill when the user says$body.
---

# $name
EOF
}

# write_skill_prose <root> <dir> <name> <lead> <phrase...> — the same quoted
# phrases as write_skill, wrapped in a caller-supplied lead-in sentence. It
# exists so the reword case produces a GENUINE modification: writing identical
# bytes leaves the path out of the diff entirely, and the case would pass
# vacuously against an arm that never ran.
write_skill_prose() {
  local root="$1" dir="$2" name="$3" lead="$4"; shift 4
  local body="" p
  for p in "$@"; do body="$body \\\"$p\\\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $name
description: "$lead$body."
---

# $name
EOF
}

# The two helpers below write the two shapes the extractor cannot read a
# description out of. They hit SEPARATE returns in phrases_from_skill_text, so
# both are needed; one helper taking a mode flag would let a typo at a call site
# silently write the other fixture and grade one path twice.

# write_no_frontmatter_skill <root> <dir> [phrase...] — no frontmatter block at
# all. Optional trailing phrases are quoted into the PROSE BODY, never into a
# frontmatter block, so the file stays unparseable while still carrying the
# quoted spans a live-set build would have to ignore. With no phrases the bytes
# are identical to what this helper has always written, so its zero-arg callers
# are unaffected. This is one helper writing one shape, not the mode-flagged
# helper the comment above rejects: write_no_description_skill is untouched.
write_no_frontmatter_skill() {
  local root="$1" dir="$2"; shift 2
  local body="" p
  for p in "$@"; do body="$body \"$p\""; done
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
# $dir

No frontmatter block at all.
EOF
  # if/then/fi, never `[ -n ... ] && cat`: the conditional is this function's
  # last command, so under set -e the && form returns 1 on every zero-arg call
  # and aborts the whole suite at the callers that pass no phrases.
  if [ -n "$body" ]; then
    cat >> "$root/$SKILLS/$dir/SKILL.md" <<EOF

It mentions$body in prose, which no frontmatter block declares.
EOF
  fi
}

# write_no_description_skill <root> <dir> — a well-formed block, no
# \`description:\` key.
write_no_description_skill() {
  local root="$1" dir="$2"
  mkdir -p "$root/$SKILLS/$dir"
  cat > "$root/$SKILLS/$dir/SKILL.md" <<EOF
---
name: $dir
allowed-tools: [Read]
---

# $dir
EOF
}

# write_ledger <root> [row...] — each row is a literal tab-separated line.
write_ledger() {
  local root="$1"; shift
  mkdir -p "$root/cogni-workspace/references"
  {
    printf '# fixture ledger\n'
    printf '# phrase_key\tstatus\towner\treason\n'
    local r
    for r in "$@"; do printf '%s\n' "$r"; done
  } > "$root/$LEDGER"
}

# make_repo <root> — two skills plus a ledger, committed on main, with
# refs/remotes/origin/main pointing at that base commit.
make_repo() {
  local root="$1"
  mkdir -p "$root"
  write_skill "$root" alpha alpha "alpha one" "alpha two"
  write_skill "$root" beta beta "beta one"
  write_ledger "$root" "$(printf 'legacy phrase\tretired\t-\tfixture seed row')"
  (cd "$root" && $GIT init -q -b main && $GIT add -A && $GIT commit -qm base \
     && $GIT update-ref refs/remotes/origin/main HEAD)
}

# run_gate <root> [args...] ->
#   "<exit>|<status>|<violation checks>|<count>|<observation checks>"
#
# The trailing observation field is asserted by EVERY case, not just the ones
# that expect an observation, so a stray observation on a case that should carry
# none is a red rather than an unnoticed pass. `count` and the exit code are
# derived from violations alone — an observation must never move either, which
# is precisely what the clean-exit cases below pin.
run_gate() {
  local root="$1"; shift
  local out rc
  set +e
  out="$(cd "$root" && python3 "$GATE" --root "$root" "$@" 2>/dev/null)"
  rc=$?
  set -e
  printf '%s|%s' "$rc" "$(printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"] or {}
codes = ",".join(sorted({v["check"] for v in d.get("violations", [])})) or "EMPTY"
obs = ",".join(sorted({o["check"] for o in d.get("observations", [])})) or "EMPTY"
print("%s|%s|%s|%s" % (d.get("status"), codes, d.get("count"), obs))
')"
}

# ---------------------------------------------------------------------------
# 1. delete a skill, write no ledger row.
R="$WORK/c1"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha")
GOT="$(run_gate "$R")"
check "retirement-ledger-01-missing-row a deleted skill with no ledger row fails (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 2. delete a skill, record every phrase retired with a reason.
R="$WORK/c2"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\tfolded away, no successor')" \
  "$(printf 'alpha two\tretired\t-\tfolded away, no successor')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, record rows")
GOT="$(run_gate "$R")"
check "retirement-ledger-02-recorded-retired a recorded retirement passes (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 3. delete a skill whose phrases a SURVIVING skill re-quotes.
R="$WORK/c3"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_skill "$R" beta beta "beta one" "alpha one" "alpha two"
(cd "$R" && $GIT add -A && $GIT commit -qm "fold alpha into beta")
GOT="$(run_gate "$R")"
check "retirement-ledger-03-reclaimed-by-survivor a re-claimed phrase needs no row (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 4. a branch that deletes no skill at all — the overwhelmingly normal case.
R="$WORK/c4"; make_repo "$R"
(cd "$R" && printf 'docs\n' > README.md && $GIT add -A && $GIT commit -qm docs)
GOT="$(run_gate "$R")"
check "retirement-ledger-04-no-deletion a branch deleting no skill passes (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 5. no refs/remotes/origin/main -> degraded, exit 0 (never a block).
R="$WORK/c5"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha" \
   && $GIT update-ref -d refs/remotes/origin/main)
GOT="$(run_gate "$R")"
check "retirement-ledger-05-degraded-no-origin an unresolvable base ref degrades to exit 0 (got: $GOT)" \
  "$([ "$GOT" = "0|degraded|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 6. main advanced past the fork and deleted a skill of its own; this branch
#    deleted nothing. A base-TIP anchor would blame the branch for main's work.
R="$WORK/c6"; make_repo "$R"
(cd "$R" && $GIT checkout -q -b feature \
   && printf 'docs\n' > README.md && $GIT add -A && $GIT commit -qm "branch work" \
   && $GIT checkout -q main \
   && $GIT rm -rq "$SKILLS/beta" && $GIT commit -qm "main retires beta" \
   && $GIT update-ref refs/remotes/origin/main HEAD \
   && $GIT checkout -q feature)
GOT="$(run_gate "$R")"
check "retirement-ledger-06-merge-base-anchoring main's own later deletion is not the branch's (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 7. two phrases, exactly one recorded -> exactly ONE violation.
R="$WORK/c7"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\trecorded, but its sibling was forgotten')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, record one of two")
GOT="$(run_gate "$R")"
check "retirement-ledger-07-partial-accounting one unrecorded phrase of two is one violation (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|1|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 8. rows exist for both phrases but one reason is empty -> still a violation.
R="$WORK/c8"; make_repo "$R"
(cd "$R" && $GIT rm -rq "$SKILLS/alpha")
write_ledger "$R" \
  "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha one\tretired\t-\tfolded away, no successor')" \
  "$(printf 'alpha two\tretired\t-\t')"
(cd "$R" && $GIT add -A && $GIT commit -qm "retire alpha, one reason blank")
GOT="$(run_gate "$R")"
check "retirement-ledger-08-empty-reason an empty-reason row does not account for its phrase (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|1|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 9. the deleted skill used a `>-` block scalar. If the unwrap did not run
#    before the quote hunt, its phrases would be extracted differently (or not
#    at all) and this case would pass vacuously with zero violations.
R="$WORK/c9"; make_repo "$R"
write_block_skill "$R" gamma gamma "gamma one" "gamma two"
(cd "$R" && $GIT add -A && $GIT commit -qm "add gamma" \
   && $GIT update-ref refs/remotes/origin/main HEAD)
(cd "$R" && $GIT rm -rq "$SKILLS/gamma" && $GIT commit -qm "retire gamma")
GOT="$(run_gate "$R")"
check "retirement-ledger-09-block-scalar a block-scalar description still yields its phrases (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 10. --emit-phrases must spawn no git subprocess: C11 calls it from a suite
#     that runs in the shallow plugin-test-suites job. Proved by running it in a
#     directory that is not a git repository at all — a git call there would
#     fail or emit to stderr; the mode must still print phrases and exit 0.
R="$WORK/c10"
mkdir -p "$R"
write_skill "$R" delta delta "delta one" "delta two"
set +e
EP_OUT="$(cd "$R" && python3 "$GATE" --emit-phrases "$R/$SKILLS" 2>"$WORK/c10.err")"
EP_RC=$?
set -e
EP_LINES="$(printf '%s\n' "$EP_OUT" | grep -c . || true)"
EP_ERR_LINES="$(grep -c . "$WORK/c10.err" || true)"
check "retirement-ledger-10-emit-phrases-no-git parity mode runs outside a git repo, silent on stderr (rc=$EP_RC lines=$EP_LINES err=$EP_ERR_LINES)" \
  "$([ "$EP_RC" -eq 0 ] && [ "$EP_LINES" -eq 2 ] && [ "$EP_ERR_LINES" -eq 0 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 11. the deleted skill cannot be PARSED at the merge base -> an OBSERVATION
#     that does not move the exit code, never a violation. Two distinct things
#     are pinned at once and the case is worthless without both: the observation
#     IS recorded (against the pre-sentinel gate the field is empty, because the
#     silent ([], name) return left nothing to record), AND exit stays 0 with
#     count 0 (against a gate that raises a violation here, the exit is 1). So
#     the arm reddens in both directions — under-reporting and over-blocking.
#     Both fixture arms carry the SAME id from one argument, so neither can
#     report green alone.
UNPARSEABLE_RC=0
UNPARSEABLE_GOT=""
for ARM in write_no_frontmatter_skill write_no_description_skill; do
  R="$WORK/c11-$ARM"; make_repo "$R"
  "$ARM" "$R" alpha
  (cd "$R" && $GIT add -A && $GIT commit -qm "alpha becomes unparseable" \
     && $GIT update-ref refs/remotes/origin/main HEAD)
  (cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha")
  GOT="$(run_gate "$R")"
  UNPARSEABLE_GOT="$UNPARSEABLE_GOT ${ARM#write_}=$GOT"
  [ "$GOT" = "0|ok|EMPTY|0|base-blob-unparseable" ] || UNPARSEABLE_RC=1
done
check "retirement-ledger-11-unparseable-base-blob an unparseable base blob is a recorded observation that does not gate the exit (both arms:$UNPARSEABLE_GOT)" \
  "$UNPARSEABLE_RC"

# ---------------------------------------------------------------------------
# 12. one deletion of each kind in ONE branch: the two channels must co-report
#     WITHOUT contaminating each other. The unparseable gamma lands in
#     observations while alpha's two unaccounted phrases stay violations, so the
#     exit is 1 and count is 2 -- driven by alpha ALONE. That is the load-bearing
#     number: were the observation folded back into the violation list the count
#     would read 3, and were the observation channel dropped on a mixed run it
#     would read EMPTY. Cases 1-11 each exercise a single channel, so nothing
#     else pins the interaction.
R="$WORK/c12"; make_repo "$R"
write_no_frontmatter_skill "$R" gamma
(cd "$R" && $GIT add -A && $GIT commit -qm "add unparseable gamma" \
   && $GIT update-ref refs/remotes/origin/main HEAD)
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" "$SKILLS/gamma" \
   && $GIT commit -qm "retire alpha and gamma")
GOT="$(run_gate "$R")"
check "retirement-ledger-12-mixed-violation-kinds an observation and a violation co-report without either moving the other's count (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2|base-blob-unparseable" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 13. the retirement is carried out by MOVING the SKILL.md out of skills/ rather
#     than removing it -- archiving it, an ordinary workflow. Rename detection is
#     on by default since git 2.9, so without --no-renames git pairs the delete
#     with the add, reports R, and the guard's --diff-filter=D query returns
#     NOTHING: it announces "no skill deletion in this branch" and exits 0 while
#     the phrases left the live set and the record together. Case 1 cannot catch
#     this -- it deletes with `git rm`, which is reported D either way -- so this
#     is a genuine second route into the same fail-open, not a restatement.
R="$WORK/c13"; make_repo "$R"
mkdir -p "$R/cogni-workspace/references/archive"
(cd "$R" && $GIT mv "$SKILLS/alpha/SKILL.md" \
   cogni-workspace/references/archive/alpha-SKILL.md \
   && $GIT commit -qm "archive alpha instead of deleting it")
GOT="$(run_gate "$R")"
check "retirement-ledger-13-move-out-of-skills-is-a-retirement archiving a skill by git mv is still a deletion the ledger must account for (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 14. the unparseable skill stays LIVE at HEAD and a DIFFERENT skill is retired.
#     Cases 11 and 12 both DELETE the unparseable file, so both land in the
#     deleted-skill arm and neither reaches live_phrase_keys() at all. Here
#     gamma survives, so the live set is the only thing that can excuse alpha,
#     and the whole tuple is asserted: the trailing observation field is EMPTY
#     precisely because nothing unparseable was deleted, which is what separates
#     this case from 11 and 12 rather than restating them.
#
#     Two facts, deliberately not conflated. The MUTATION reddens this case
#     because dropping the filter iterates the truthy sentinel and the run dies
#     at exit 2 -- gamma's quoted phrases are not what moves it, and a control
#     fixture carrying none behaves identically under the mutation. What those
#     phrases pin is the ASSERTION: gamma quotes both of alpha's phrases and the
#     count still reads 2, so a phrase quoted only by an unparseable LIVE file
#     excuses nothing. That is the property, and it would fail at count 0 if the
#     extractor ever began reading prose quotes out of an unparseable file.
R="$WORK/c14"; make_repo "$R"
write_no_frontmatter_skill "$R" gamma "alpha one" "alpha two"
(cd "$R" && $GIT add -A && $GIT commit -qm "add unparseable gamma" \
   && $GIT update-ref refs/remotes/origin/main HEAD)
# The rm must be COMMITTED: the gate diffs base_ref...HEAD over commits, so an
# uncommitted removal would leave this passing vacuously at 0|ok|EMPTY|0|EMPTY.
(cd "$R" && $GIT rm -rq "$SKILLS/alpha" && $GIT commit -qm "retire alpha only")
GOT="$(run_gate "$R")"
check "retirement-ledger-14-unparseable-live-at-head a live unparseable skill excuses nothing, and no unparseable deletion means no observation (got: $GOT)" \
  "$([ "$GOT" = "1|ok|retirement-row-missing|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 15. parity mode over a dir holding one parseable skill and BOTH unparseable
#     shapes -> exactly one phrase line, exit 0. Both shapes are present because
#     they hit SEPARATE returns in phrases_from_skill_text; case 10 proves the
#     mode runs outside a git repo but feeds it only parseable input, so nothing
#     before this reaches emit_phrases's skip.
#
#     The dir names sort alpha < mu < nu so the parseable skill is walked FIRST.
#     That ordering is what makes both assertions move under the mutation rather
#     than just one: alpha's phrase line prints, then the sentinel is iterated
#     and the unhandled-error envelope is printed on STDOUT by render() -- not a
#     traceback on stderr -- so the count goes 1 -> 2 and rc goes 0 -> 2.
#
#     The set +e wrapper is load-bearing, not stylistic: under the mutation the
#     gate exits 2, and without it set -e would abort the suite before check
#     printed, so the recorded recipe would report the case missing rather than
#     red and would not be replayable.
R="$WORK/c15"
mkdir -p "$R"
write_skill "$R" alpha alpha "alpha one"
write_no_frontmatter_skill "$R" mu
write_no_description_skill "$R" nu
set +e
EP15_OUT="$(cd "$R" && python3 "$GATE" --emit-phrases "$R/$SKILLS" 2>"$WORK/c15.err")"
EP15_RC=$?
set -e
EP15_LINES="$(printf '%s\n' "$EP15_OUT" | grep -c . || true)"
EP15_ERR_LINES="$(grep -c . "$WORK/c15.err" || true)"
check "retirement-ledger-15-emit-phrases-skips-unparseable parity mode prints the parseable skill's one phrase and nothing for either unparseable shape (rc=$EP15_RC lines=$EP15_LINES err=$EP15_ERR_LINES)" \
  "$([ "$EP15_RC" -eq 0 ] && [ "$EP15_LINES" -eq 1 ] && [ "$EP15_ERR_LINES" -eq 0 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 16. a SURVIVING skill's description drops a phrase, unaccounted -> violation.
#     The modified-subject mirror of case 1, and the recorded mutation's target.
R="$WORK/c16"; make_repo "$R"
write_skill "$R" alpha alpha "alpha one"
(cd "$R" && $GIT commit -aqm "reword alpha")
GOT="$(run_gate "$R")"
check "retirement-ledger-16-description-drop-unaccounted a phrase dropped from a surviving description with no row and no re-claim fails (got: $GOT)" \
  "$([ "$GOT" = "1|ok|description-phrase-dropped|1|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 17. rewording the prose AROUND unchanged quoted phrases is not a drop.
#     One-directional by construction: it shares case 16's fixture shape and
#     differs in exactly one argument, so it cannot be vacuously green while
#     16 is green.
R="$WORK/c17"; make_repo "$R"
write_skill_prose "$R" alpha alpha "Reach for this skill whenever someone says" "alpha one" "alpha two"
(cd "$R" && $GIT commit -aqm "reword alpha prose only")
GOT="$(run_gate "$R")"
check "retirement-ledger-17-description-reword-clean rewording prose around unchanged phrases is not taxed (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 18. both remedies discharge a drop. TWO arms, ONE id, accumulated and emitted
#     by a single check AFTER the loop — a check inside it would print the same
#     id twice and break --case addressability for a mutation recipe.
C18_OK=0
R="$WORK/c18a"; make_repo "$R"
write_skill "$R" alpha alpha "alpha one"
write_ledger "$R" "$(printf 'legacy phrase\tretired\t-\tfixture seed row')" \
  "$(printf 'alpha two\tretired\t-\tfolded away, no successor')"
(cd "$R" && $GIT commit -aqm "reword alpha, record the phrase")
GOT_A="$(run_gate "$R")"
[ "$GOT_A" = "0|ok|EMPTY|0|EMPTY" ] || C18_OK=1
R="$WORK/c18b"; make_repo "$R"
write_skill "$R" alpha alpha "alpha one"
write_skill "$R" beta beta "beta one" "alpha two"
(cd "$R" && $GIT commit -aqm "reword alpha, re-claim in beta")
GOT_B="$(run_gate "$R")"
[ "$GOT_B" = "0|ok|EMPTY|0|EMPTY" ] || C18_OK=1
check "retirement-ledger-18-description-drop-accounted a ledger row and a sibling re-claim each discharge a dropped phrase (got: $GOT_A / $GOT_B)" \
  "$C18_OK"

# ---------------------------------------------------------------------------
# 19. the surviving file becomes UNPARSEABLE at HEAD. It contributes nothing to
#     the live set, so BOTH phrases it advertised at the merge base are demanded
#     — the safe direction. Observations stay EMPTY: the BASE blob parsed fine,
#     and there is deliberately no head-side observation channel.
R="$WORK/c19"; make_repo "$R"
write_no_frontmatter_skill "$R" alpha
(cd "$R" && $GIT commit -aqm "alpha loses its frontmatter")
GOT="$(run_gate "$R")"
check "retirement-ledger-19-modified-head-unparseable a file unparseable at HEAD excuses none of its own base phrases (got: $GOT)" \
  "$([ "$GOT" = "1|ok|description-phrase-dropped|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 20. main advanced past the fork and dropped a phrase from a skill of its own;
#     this branch touched no SKILL.md. The case-6 analogue for the modified
#     subject — a base-TIP anchor would blame the branch for main's edit.
R="$WORK/c20"; make_repo "$R"
(cd "$R" && $GIT checkout -q -b feature \
   && printf 'docs\n' > README.md && $GIT add -A && $GIT commit -qm "branch work" \
   && $GIT checkout -q main)
write_skill "$R" alpha alpha "alpha one"
(cd "$R" && $GIT commit -aqm "main rewords alpha" \
   && $GIT update-ref refs/remotes/origin/main HEAD \
   && $GIT checkout -q feature)
GOT="$(run_gate "$R")"
check "retirement-ledger-20-modified-merge-base-anchoring main's own later description edit is not the branch's (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 21. both subjects in one branch: beta is deleted AND alpha drops a phrase.
#     TWO violations, not three — beta advertises one phrase and alpha drops
#     one. run_gate sorts the check set, so the dropped-phrase code sorts first.
R="$WORK/c21"; make_repo "$R"
write_skill "$R" alpha alpha "alpha one"
(cd "$R" && $GIT rm -rq "$SKILLS/beta" && $GIT commit -aqm "retire beta, reword alpha")
GOT="$(run_gate "$R")"
check "retirement-ledger-21-mixed-subjects a deletion and a description drop co-report without contaminating each other's counts (got: $GOT)" \
  "$([ "$GOT" = "1|ok|description-phrase-dropped,retirement-row-missing|2|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 22. the modified file was UNPARSEABLE AT THE MERGE BASE: it advertised nothing
#     to lose, and no branch edit can change its own merge base. An OBSERVATION,
#     the mirror of case 11 — and the only case that observes the per-subject
#     `checked` arithmetic, which under-reported while one class existed.
R="$WORK/c22"; mkdir -p "$R"
write_no_frontmatter_skill "$R" alpha
write_skill "$R" beta beta "beta one"
write_ledger "$R" "$(printf 'legacy phrase\tretired\t-\tfixture seed row')"
(cd "$R" && $GIT init -q -b main && $GIT add -A && $GIT commit -qm base \
   && $GIT update-ref refs/remotes/origin/main HEAD)
write_skill "$R" alpha alpha "alpha one"
(cd "$R" && $GIT commit -aqm "alpha gains a frontmatter")
GOT="$(run_gate "$R")"
check "retirement-ledger-22-modified-base-unparseable a file unparseable at the merge base advertised nothing to drop (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|modified-base-unparseable" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 23. a modification-only branch that also removes the ledger. The ledger's own
#     path is a D row SKILL_PATH_RE rejects, so the deletion set stays empty and
#     the ledger-missing arm — whose detail text names a deletion — correctly
#     does not fire. Without the ledger-tolerant `accounted`, this run dies as
#     an unhandled-error exit 2 instead of returning a determinate verdict.
R="$WORK/c23"; make_repo "$R"
write_skill "$R" alpha alpha "alpha one"
(cd "$R" && $GIT rm -q "$LEDGER" && $GIT commit -aqm "reword alpha, drop the ledger")
GOT="$(run_gate "$R")"
check "retirement-ledger-23-modified-no-ledger a modification-only branch with no ledger still returns a determinate verdict (got: $GOT)" \
  "$([ "$GOT" = "1|ok|description-phrase-dropped|1|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
# 24. a retained phrase is rewritten with different case and internal spacing.
#     The extractor's normal form — trimmed, whitespace collapsed, lowercased —
#     maps it to the SAME key, so nothing left the claim surface. An arm that
#     compared raw phrase text instead of the key would report it dropped.
R="$WORK/c24"; make_repo "$R"
write_skill "$R" alpha alpha "Alpha  ONE" "alpha two"
(cd "$R" && $GIT commit -aqm "restyle a retained phrase")
GOT="$(run_gate "$R")"
check "retirement-ledger-24-description-normalize-clean a retained phrase restyled to the same normalized key is not a drop (got: $GOT)" \
  "$([ "$GOT" = "0|ok|EMPTY|0|EMPTY" ] && echo 0 || echo 1)"

# ---------------------------------------------------------------------------
if [ "$FAILED" -gt 0 ]; then
  printf '%s\n' "$FAILED failing case(s)"
  exit 1
fi
printf '%s\n' "all cases passed"
