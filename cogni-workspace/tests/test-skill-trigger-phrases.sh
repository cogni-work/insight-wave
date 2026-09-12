#!/usr/bin/env bash
# Skill trigger-phrase collision guard: no two cogni-workspace skills may
# advertise the same verbatim trigger phrase.
#
# Why this exists. A skill's frontmatter `description:` is the router's only
# input — the host picks a skill by matching the user's words against those
# descriptions. When two skills quote the same phrase, the router has no
# tiebreaker, and which one fires is not a property of the repo at all. Nothing
# else in CI looks at description *content*: check-skill-names.sh checks the
# `name:` field, scripts/check-skill-spec.py checks that the required keys exist
# and stay within the published limits, and plugin-validator checks structure.
# A duplicated phrase is well-formed by every one of those and still broken.
#
# The failure is silent in the worst way. Both skills load, both look correct in
# isolation, and the only symptom is that a user asking the shared phrase
# sometimes lands in the wrong skill. There is no error, no log line, and no
# reproduction that holds still. That is precisely the class of defect a
# deterministic guard is for.
#
# This matters most while capability is being consolidated. Folding a retiring
# skill's material into a surviving one means moving its advertised phrases too,
# and the natural mistake is to add them to the absorbing skill while the
# original still claims them. Within one plugin this guard catches it. Across
# plugins it deliberately does not — see the scope note below.
#
# Contract under test:
#   - phrases are the double-quoted strings inside the frontmatter
#     `description:` block, and nowhere else in the file
#   - a phrase claimed by two different skills fails, and the phrase plus both
#     skill names are printed
#   - a phrase repeated inside ONE description is not a collision
#   - matching is case-insensitive and whitespace-trimmed, so "What Does X Do"
#     and "what does x do" collide
#   - quoted strings in the skill BODY are ignored — bodies are full of quoted
#     examples and would produce constant false positives
#   - every YAML scalar style in the tree (>-, |, "...", '...') yields the same
#     phrases, with the scalar's own delimiters unwrapped first
#   - the real cogni-workspace tree is clean
#   - every skill in the real tree contributes at least one phrase to the
#     extractor, so a description that advertises its triggers as unquoted
#     prose, or in single quotes inside a double-quoted scalar, is invisible
#     to this guard and fails the coverage floor
#   - an empty or missing skills directory fails rather than reporting clean
#   - a phrase the retirement record marks as claimed, that no live skill
#     yields, fails as an orphan; and a phrase it marks as retired, that a live
#     skill DOES yield, fails as a stale record
#
# Scoped to one plugin on purpose. The obvious generalization — scan every
# plugin at once — is wrong here: `cogni-portfolio:markets` and
# `cogni-trends:trends-catalog` may both legitimately quote "show the catalog",
# because the user reaches them through different projects and the host
# disambiguates by plugin. Only phrases competing INSIDE one plugin's skill set
# are unambiguously a defect. A cross-plugin version of this check would need a
# hand-maintained exemption list, which is the thing this design rejects.
#
# That rejection stands, and C10's retirement record is not an instance of it.
# The discriminator is the direction of effect, not the fact of being a file.
# An exemption list makes the guard QUIETER: every row removes a finding, and a
# guard that is quiet because it stopped looking is worse than no guard. C10's
# record makes it LOUDER: every row adds a way to go red, and the record itself
# is checked in both directions against the live extractor, so a row that stops
# being true reddens rather than silently persisting. It is also scoped to
# retirement EVENTS rather than to skills — its population is closed by history
# and it enumerates no live skill except as an owner attribution C10 verifies —
# so it needs no syncing with the extractor's name key as skills come and go.
# The in-repo precedent is references/wiki-tree-reconciliation.md and its
# enforcement arm tests/test-wiki-tree-parity.sh: a one-sided page with no
# recorded decision turns that suite red, and the documented fix is to record
# the decision rather than route around the guard.
#
# The record is needed at all because absence is not derivable from this tree.
# Collision detection folds the live surface with `sort | uniq -d`, which can
# only see a phrase claimed by two skills; a phrase claimed by NONE leaves no
# trace here to fold. When a skill is deleted its phrases vanish from the tree
# entirely, so nothing the extractor can read remembers that they were ever
# routed. Only an enumerated record can carry that.
#
# The extractor takes the description block as everything from `description:` up
# to the next top-level frontmatter key. Both YAML block styles in the tree
# (`>-` and `|`) fold into that same shape, so neither needs special handling —
# but a phrase must not be quoted in a *disclaimer* either ("read-only requests
# such as \"show X\" route elsewhere" still reads as a claim to this guard, and
# to the router). Say it without the quotes.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A / typeset -A,
# no mapfile / readarray, no ${var^^} / ${var,,}. Phrase-to-skill accumulation
# runs through a temp file and `sort`/`uniq`, which is the house alternative to
# an associative array.
#
# Case labels are "PASS: <case>" / "FAIL: <case>" to match the sibling suite
# test-wiki-namespace-sync.sh — the cogni-service mutation harness classifies a
# case GREEN only on that vocabulary. Case ids are C-prefixed and never bare
# numerals, so the final summary line is not read as a case result.
#
# stdlib-only: bash + coreutils + python3 (frontmatter parsing), no pip deps,
# no network.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# The checker. Fixture cases and the real-tree case drive this same function —
# the extractor is never reimplemented in a case body, so pointing a case at a
# broken extractor turns that case red.
# ---------------------------------------------------------------------------

# emit_phrases <skills_dir> -> "<phrase>\t<skill-name>" per line, deduped within
# a skill. Reads ONLY the frontmatter description block.
emit_phrases() {
  python3 -c '
import os, re, sys

skills_dir = sys.argv[1]
try:
    entries = sorted(os.listdir(skills_dir))
except OSError:
    sys.exit(3)

found_any = False
for entry in entries:
    path = os.path.join(skills_dir, entry, "SKILL.md")
    if not os.path.isfile(path):
        continue
    found_any = True
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        continue
    fm = m.group(1)
    nm = re.search(r"^name:[ \t]*(\S+)", fm, re.M)
    name = nm.group(1) if nm else entry
    # description: through the next TOP-LEVEL key (column 0), or end of block.
    dm = re.search(r"^description:.*?(?=^[A-Za-z_][A-Za-z0-9_-]*:|\Z)", fm, re.M | re.S)
    if not dm:
        continue
    body = re.sub(r"^description:[ \t]*", "", dm.group(0), count=1)
    # Unwrap the YAML scalar BEFORE hunting for quoted phrases. On a
    # double-quoted scalar the outer quotes are syntax, not a trigger phrase —
    # leaving them in makes the whole description read as one giant phrase, so
    # that skill contributes nothing usable and its real phrases go unguarded.
    stripped = body.strip()
    if stripped[:1] in (">", "|"):
        stripped = stripped.split("\n", 1)[1] if "\n" in stripped else ""
    elif stripped[:1] == "\"" and stripped[-1:] == "\"":
        stripped = stripped[1:-1].replace("\\\"", "\"")
    elif stripped[:1] == chr(39) and stripped[-1:] == chr(39):
        stripped = stripped[1:-1].replace(chr(39) * 2, chr(39))
    seen = set()
    for phrase in re.findall(r"\"([^\"]+)\"", stripped):
        key = " ".join(phrase.split()).lower()
        if not key or key in seen:
            continue
        seen.add(key)
        print("%s\t%s" % (key, name))

if not found_any:
    sys.exit(4)
' "$1"
}

# scan_skills <skills_dir> -> 0 clean, 1 collision/unusable tree.
scan_skills() {
  local dir="$1"
  local raw="$TMPROOT/raw.$$" rc

  if [ ! -d "$dir" ]; then
    echo "ERROR skills directory not found: $dir"
    return 1
  fi

  emit_phrases "$dir" > "$raw" 2>/dev/null
  rc=$?
  if [ "$rc" -eq 4 ]; then
    # Liveness floor. Without it, a scan pointed at a directory holding no
    # SKILL.md reports clean, and a half-dead guard is indistinguishable from a
    # working one — the real tree is already clean, so nothing else would notice.
    echo "ERROR no SKILL.md files found under $dir"
    return 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR could not read skills under $dir"
    return 1
  fi

  # A phrase collides when its distinct skill count exceeds 1. Sorting on the
  # phrase field and folding is the bash-3.2 stand-in for a dict of sets.
  local collisions=0 phrase owners
  while IFS= read -r phrase; do
    [ -n "$phrase" ] || continue
    owners="$(awk -F'\t' -v p="$phrase" '$1 == p { print $2 }' "$raw" | sort -u | tr '\n' ' ')"
    echo "COLLISION \"$phrase\" claimed by: $owners"
    collisions=$((collisions + 1))
  done <<EOF
$(cut -f1 "$raw" | sort | uniq -d)
EOF

  [ "$collisions" -eq 0 ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

RC=0
OUT=""
run_scan() { OUT="$(scan_skills "$1" 2>&1)"; RC=$?; }

assert_rc() {
  [ "$RC" -eq "$1" ] && return 0
  echo "     expected rc=$1, got rc=$RC; output:"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_has() {
  case "$OUT" in *"$1"*) return 0 ;; esac
  echo "     expected output to contain: $1"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_lacks() {
  case "$OUT" in *"$1"*) echo "     expected output NOT to contain: $1"; return 1 ;; esac
  return 0
}

# mk_skill <skills_dir> <name> <description-body> [body-text]
mk_skill() {
  local dir="$1/$2"
  mkdir -p "$dir"
  {
    printf -- '---\n'
    printf -- 'name: %s\n' "$2"
    printf -- 'description: >-\n'
    printf -- '  %s\n' "$3"
    printf -- 'allowed-tools: Read\n'
    printf -- '---\n\n'
    printf -- '# %s\n\n%s\n' "$2" "${4:-fixture body.}"
  } > "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# C1 — the real cogni-workspace tree is clean (asserted here, not only in
# fixtures).
# ---------------------------------------------------------------------------
run_scan "$WS_ROOT/skills"
if assert_rc 0; then
  pass "C1 real cogni-workspace skills claim no duplicate trigger phrase"
else
  fail "C1 real cogni-workspace skills claim no duplicate trigger phrase"
fi

# ---------------------------------------------------------------------------
# C2 — the core case: one phrase, two skills. This is the mutation the issue
# names ("what does cogni-X do" added to a second skill).
# ---------------------------------------------------------------------------
F2="$TMPROOT/c2/skills"
mk_skill "$F2" ask 'Answer questions. Trigger on "what does cogni-X do" or "ask the wiki".'
mk_skill "$F2" cheatsheet 'Quick cards. Trigger on "what does cogni-X do" or "tldr cogni-X".'
run_scan "$F2"
if assert_rc 1 \
  && assert_out_has 'what does cogni-x do' \
  && assert_out_has 'ask' \
  && assert_out_has 'cheatsheet'; then
  pass "C2 one phrase claimed by two skills fails and names both"
else
  fail "C2 one phrase claimed by two skills fails and names both"
fi

# ---------------------------------------------------------------------------
# C3 — a phrase repeated INSIDE one description is not a collision. Without the
# per-skill dedupe this would false-fail, and every rewritten description that
# restates its own trigger would turn the guard red.
# ---------------------------------------------------------------------------
F3="$TMPROOT/c3/skills"
mk_skill "$F3" ask 'Trigger on "ask the wiki". Say "ask the wiki" to start. Also "ask insight-wave".'
mk_skill "$F3" other 'Unrelated. Trigger on "something else".'
run_scan "$F3"
if assert_rc 0; then
  pass "C3 a phrase repeated within one description is not a collision"
else
  fail "C3 a phrase repeated within one description is not a collision"
fi

# ---------------------------------------------------------------------------
# C4 — case and whitespace normalization. Two skills quoting the same phrase in
# different casing compete for the same invocation just as surely.
# ---------------------------------------------------------------------------
F4="$TMPROOT/c4/skills"
mk_skill "$F4" alpha 'Trigger on "Show Market Coverage".'
mk_skill "$F4" beta  'Trigger on "show market   coverage".'
run_scan "$F4"
if assert_rc 1 && assert_out_has 'show market coverage'; then
  pass "C4 collisions are detected across casing and internal whitespace"
else
  fail "C4 collisions are detected across casing and internal whitespace"
fi

# ---------------------------------------------------------------------------
# C5 — quoted strings in the BODY are ignored. Skill bodies quote examples
# constantly; counting them would make the guard unusable.
# ---------------------------------------------------------------------------
F5="$TMPROOT/c5/skills"
mk_skill "$F5" alpha 'Trigger on "alpha phrase".' 'Example: the user says "shared body quote" here.'
mk_skill "$F5" beta  'Trigger on "beta phrase".'  'Also documents "shared body quote" as an example.'
run_scan "$F5"
if assert_rc 0 && assert_out_lacks 'shared body quote'; then
  pass "C5 quoted strings in the skill body are not treated as trigger phrases"
else
  fail "C5 quoted strings in the skill body are not treated as trigger phrases"
fi

# ---------------------------------------------------------------------------
# C6 — the extractor stops at the next top-level frontmatter key. A phrase
# quoted in a later key must not be attributed to the description.
# ---------------------------------------------------------------------------
F6="$TMPROOT/c6/skills"
mkdir -p "$F6/alpha" "$F6/beta"
printf -- '---\nname: alpha\ndescription: >-\n  Trigger on "alpha only".\nargument-hint: pass "shared later key" here\n---\n\n# alpha\n' > "$F6/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: >-\n  Trigger on "beta only".\nargument-hint: pass "shared later key" here\n---\n\n# beta\n' > "$F6/beta/SKILL.md"
run_scan "$F6"
if assert_rc 0 && assert_out_lacks 'shared later key'; then
  pass "C6 the description block ends at the next top-level frontmatter key"
else
  fail "C6 the description block ends at the next top-level frontmatter key"
fi

# ---------------------------------------------------------------------------
# C7 — YAML scalar styles. All four in-tree styles must yield the same phrases.
# The double-quoted case is the trap: leave the outer quotes on and the entire
# description reads as one phrase, so that skill contributes nothing and its
# real triggers go unguarded — silently, because one giant unique string never
# collides with anything.
# ---------------------------------------------------------------------------
F7="$TMPROOT/c7-styles/skills"
mkdir -p "$F7/blockfold" "$F7/blockliteral" "$F7/dquoted" "$F7/squoted"
printf -- '---\nname: blockfold\ndescription: >-\n  Trigger on \"shared style phrase\".\n---\n\n# blockfold\n' > "$F7/blockfold/SKILL.md"
printf -- '---\nname: blockliteral\ndescription: |\n  Unrelated trigger \"literal only\".\n---\n\n# blockliteral\n' > "$F7/blockliteral/SKILL.md"
printf -- '---\nname: dquoted\ndescription: "Trigger on \\"shared style phrase\\" here."\n---\n\n# dquoted\n' > "$F7/dquoted/SKILL.md"
printf -- "---\nname: squoted\ndescription: 'Unrelated trigger \"squoted only\".'\n---\n\n# squoted\n" > "$F7/squoted/SKILL.md"
run_scan "$F7"
if assert_rc 1 \
  && assert_out_has 'shared style phrase' \
  && assert_out_has 'blockfold' \
  && assert_out_has 'dquoted' \
  && assert_out_lacks 'trigger on' \
  && assert_out_lacks 'unrelated trigger'; then
  pass "C7 phrases are found under every YAML scalar style, quotes unwrapped"
else
  fail "C7 phrases are found under every YAML scalar style, quotes unwrapped"
fi

# ---------------------------------------------------------------------------
# C8 — the liveness floor itself. Without this the floor is an unfalsifiable
# branch, and a scan silently pointed at nothing would report clean.
# ---------------------------------------------------------------------------
c8_ok=1
mkdir -p "$TMPROOT/c8/empty"
run_scan "$TMPROOT/c8/empty"
assert_rc 1 && assert_out_has "no SKILL.md files found" || c8_ok=0
run_scan "$TMPROOT/c8/does-not-exist"
assert_rc 1 && assert_out_has "skills directory not found" || c8_ok=0
if [ "$c8_ok" -eq 1 ]; then
  pass "C8 an empty or missing skills tree fails rather than reporting clean"
else
  fail "C8 an empty or missing skills tree fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
# C9 — the coverage floor. A description that advertises its triggers as
# unquoted prose, or as single-quoted spans inside a double-quoted scalar,
# contributes ZERO phrases: it cannot collide with anything, so C1 stays green
# no matter what it claims. That is not hypothetical — it is how a real
# collision once sat in this tree behind a green suite.
#
# This case asserts CONTRIBUTION to the real extractor, never the presence of
# quote characters. A shape test looking for a quote would pass a skill whose
# only double quotes are the scalar's own delimiters, and would pass one whose
# triggers are single-quoted — both of which contribute nothing. That test
# would be green on precisely the defect it exists to catch.
#
# Each skill is probed through emit_phrases itself, one at a time, so there is
# no roster to keep in sync with the extractor's own name key, and no
# per-skill exemption list — the thing this suite's design rejects. Pointing
# this case at a broken extractor turns it red, exactly as C1-C8 do.
#
# That claim is about C9 specifically, and stays true of it: C9 enumerates
# nothing, because it derives its population from the live tree on every run.
# C10 below deliberately does carry a record; the header states why, and why it
# is not the roster this design rejects.
#
# Single-quoted spans are deliberately NOT harvested, and the fix for a
# single-quoted description is to migrate it rather than to widen the regex.
# A boundary-aware widening is possible and mints no garbage, so that is not
# the objection: the objection is that it only reaches descriptions that quote
# SOMETHING. Measured over the six skills this floor first caught, widening
# rescued three; the other three advertised their triggers as unquoted prose,
# so no pattern over any quote character reaches them. Widening therefore buys
# a second quoting convention and still leaves half the work undone. It also
# harvests what an author would not: a word-mention ("the word 'adapt'") and a
# span whose trailing comma sits inside the quotes. Punctuation and mentions
# are for an author to adjudicate, not a regex.
# ---------------------------------------------------------------------------
c9_scanned=0
c9_missing=""
for c9_dir in "$WS_ROOT"/skills/*/; do
  [ -f "$c9_dir/SKILL.md" ] || continue
  c9_trimmed="${c9_dir%/}"
  c9_name="${c9_trimmed##*/}"
  c9_scanned=$((c9_scanned + 1))
  c9_probe="$TMPROOT/c9/$c9_name/skills"
  mkdir -p "$c9_probe/$c9_name"
  cp "$c9_dir/SKILL.md" "$c9_probe/$c9_name/SKILL.md"
  if [ -z "$(emit_phrases "$c9_probe" 2>/dev/null)" ]; then
    c9_missing="$c9_missing $c9_name"
  fi
done
# c9_scanned > 0 is the anti-vacuity clause, mirroring C8: a glob that matched
# nothing must fail this case, not pass it on an empty loop.
if [ "$c9_scanned" -gt 0 ] && [ -z "$c9_missing" ]; then
  pass "C9 every real cogni-workspace skill contributes at least one trigger phrase"
else
  echo "     skills contributing zero phrases:$c9_missing (scanned $c9_scanned)"
  fail "C9 every real cogni-workspace skill contributes at least one trigger phrase"
fi

# ---------------------------------------------------------------------------
# C10 — the orphan direction. C1/C2 detect a phrase claimed by TWO skills;
# nothing detected one claimed by NONE, because `sort | uniq -d` over the live
# surface cannot see what is not there. A retirement can therefore delete
# routing coverage with every case green — which is what happened to six
# phrases of the folded story-to-storyboard skill, caught only by a human
# reviewer.
#
# The record at references/retired-trigger-phrases.tsv supplies the population
# the tree cannot. This case cross-checks it against the live extractor in both
# directions, so the record cannot quietly go stale in either:
#
#   claimed, not yielded  -> ORPHAN        (the routing loss this case exists for)
#   claimed, wrong owner  -> MISATTRIBUTED (the record names a skill that does not claim it)
#   retired, yielded      -> STALE RECORD  (a retired phrase came back)
#
# The live side comes from emit_phrases itself — never a second parser — so
# pointing this case at a broken extractor turns it red exactly as C1-C9 do.
# Row hygiene is enforced here too: four fields, a known status, a NON-EMPTY
# reason, and a key already in the extractor's normal form. The reason check is
# what stops the record degrading into a bare list nobody has to justify.
#
# bash-3.2 portable: flat temp files plus sort/comm/awk, no associative arrays.
# ---------------------------------------------------------------------------
c10_ok=1
C10_LEDGER="$WS_ROOT/references/retired-trigger-phrases.tsv"
mkdir -p "$TMPROOT/c10"

if [ ! -f "$C10_LEDGER" ] || [ ! -r "$C10_LEDGER" ]; then
  echo "     retirement record missing or unreadable: $C10_LEDGER"
  c10_ok=0
else
  # Strip comments and blank lines. Everything below reads this.
  grep -v '^[[:space:]]*#' "$C10_LEDGER" | grep -v '^[[:space:]]*$' > "$TMPROOT/c10/rows" || true

  # One pass for all three counts. `rows` is carried for the diagnostic only —
  # rows == 0 implies both status counts are 0, so it is never the deciding arm.
  read -r c10_rows c10_claimed_n c10_retired_n <<EOF
$(awk -F'\t' '{n++} $2 == "claimed" {c++} $2 == "retired" {r++} END {print n+0, c+0, r+0}' "$TMPROOT/c10/rows")
EOF

  # Anti-vacuity floor, mirroring C8/C9: an empty or single-status record must
  # fail rather than pass on an empty loop. Without this, truncating the file
  # would make every direction below iterate over nothing and report clean.
  if [ "$c10_claimed_n" -eq 0 ] || [ "$c10_retired_n" -eq 0 ]; then
    echo "     record is vacuous: rows=$c10_rows claimed=$c10_claimed_n retired=$c10_retired_n (each must be > 0)"
    c10_ok=0
  fi

  # Row hygiene. A malformed row is reported, never skipped — skipping one
  # would let a typo silently drop a phrase out of both directions.
  # The shape checks are awk; the key check is python, and deliberately so.
  # awk's tolower is byte-wise, while the extractor normalizes in python, whose
  # lower() folds non-ASCII too — so an awk normal-form check would call an
  # uppercase umlaut key already-normal, and the row would then never join the
  # live set. That loses a direction SILENTLY, which is the failure class C10
  # exists to close. An earlier form rejected any non-ASCII key outright to
  # avoid a second normal form; a retired German phrase with an umlaut is a
  # real row this file has to carry, so the key check now applies the
  # extractor's own normal form (whitespace-collapsed, python lower()) — the
  # same parser, not a second one.
  #
  # The python step must never fail OPEN. It runs inside the same $(...) as the
  # awk arm, so a traceback would go to stderr, leave c10_bad empty and let the
  # case print PASS on a row it never graded. Two things close that: the file
  # is read as bytes and each line decoded strictly, so a byte that is not
  # valid UTF-8 — the class the old ASCII-only arm rejected — is reported as a
  # malformed key and the step exits non-zero; and the shell appends its own
  # crash line whenever the step exits non-zero for any other reason, so a
  # crashed check is red by construction rather than silently green.
  c10_bad=$(awk -F'\t' '
    NF != 4                                  { print "  field-count " NF " (want 4): " $0; next }
    $2 != "claimed" && $2 != "retired"        { print "  unknown status \"" $2 "\": " $0; next }
    $2 == "retired" && $3 != "-"              { print "  retired row must have owner \"-\", got \"" $3 "\": " $0; next }
    { r = $4; gsub(/^[ \t]+|[ \t]+$/, "", r) }
    r == ""                                   { print "  empty reason: " $0 }
  ' "$TMPROOT/c10/rows"
  python3 - "$TMPROOT/c10/rows" <<'PY' 2>/dev/null || echo "  key check crashed (python exit $?) — the row set was not graded"
import sys
rc = 0
try:
    with open(sys.argv[1], "rb") as fh:
        raw_lines = fh.read().split(b"\n")
except OSError as exc:
    print("  key check could not read the record: %s" % exc)
    sys.exit(1)
for raw in raw_lines:
    if not raw:
        continue
    raw_key = raw.split(b"\t", 1)[0]
    try:
        key = raw_key.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        print("  key is not valid UTF-8 (%s): %s" % (exc, raw.decode("utf-8", errors="replace")))
        rc = 1
        continue
    normal = " ".join(key.split()).lower()
    if key != normal:
        print('  key not in normal form (want "%s"): %s' % (normal, raw.decode("utf-8", errors="replace")))
sys.exit(rc)
PY
  )
  if [ -n "$c10_bad" ]; then
    echo "     malformed record rows:"
    echo "$c10_bad"
    c10_ok=0
  fi

  # The live side, from the suite's own extractor. A non-zero rc is red: an
  # extractor that could not read the tree is not evidence the tree agrees.
  if emit_phrases "$WS_ROOT/skills" > "$TMPROOT/c10/raw" 2>"$TMPROOT/c10/raw.err"; then
    cut -f1 "$TMPROOT/c10/raw" | sort -u > "$TMPROOT/c10/live"

    awk -F'\t' '$2 == "claimed" { print $1 }' "$TMPROOT/c10/rows" | sort -u > "$TMPROOT/c10/claimed"
    awk -F'\t' '$2 == "retired" { print $1 }' "$TMPROOT/c10/rows" | sort -u > "$TMPROOT/c10/retired"

    # Direction A — recorded claimed, yielded by nobody. The orphan.
    c10_orphans=$(comm -23 "$TMPROOT/c10/claimed" "$TMPROOT/c10/live")
    if [ -n "$c10_orphans" ]; then
      echo "$c10_orphans" | while IFS= read -r phrase; do
        [ -z "$phrase" ] && continue
        owner=$(awk -F'\t' -v p="$phrase" '$1 == p { print $3 }' "$TMPROOT/c10/rows")
        echo "     ORPHAN \"$phrase\" recorded as claimed by $owner but yielded by no live skill"
      done
      c10_ok=0
    fi

    # Direction B — recorded retired, yielded after all. A stale record.
    c10_stale=$(comm -12 "$TMPROOT/c10/retired" "$TMPROOT/c10/live")
    if [ -n "$c10_stale" ]; then
      echo "$c10_stale" | while IFS= read -r phrase; do
        [ -z "$phrase" ] && continue
        owners=$(awk -F'\t' -v p="$phrase" '$1 == p { print $2 }' "$TMPROOT/c10/raw" | sort -u | tr '\n' ' ')
        echo "     STALE RECORD \"$phrase\" recorded retired but claimed by: $owners"
      done
      c10_ok=0
    fi

    # Direction C — owner attribution. A claimed row must name the skill the
    # extractor actually attributes the phrase to. Gated on the phrase being
    # live at all: without that guard an orphan satisfies this condition too and
    # reports twice, the second time with a message that is false about the
    # state ("not yielded under that name" implies it is yielded under another).
    c10_mis=$(awk -F'\t' '
      NR == FNR             { live[$1 "\t" $2] = 1; phrase[$1] = 1; next }
      $2 == "claimed" && ($1 in phrase) {
        if (!(($1 "\t" $3) in live)) print "     MISATTRIBUTED \"" $1 "\" recorded as claimed by " $3 " but not yielded under that name"
      }
    ' "$TMPROOT/c10/raw" "$TMPROOT/c10/rows")
    if [ -n "$c10_mis" ]; then
      echo "$c10_mis"
      c10_ok=0
    fi
  else
    echo "     emit_phrases failed over $WS_ROOT/skills: $(cat "$TMPROOT/c10/raw.err")"
    c10_ok=0
  fi
fi

if [ "$c10_ok" -eq 1 ]; then
  pass "C10 the retirement record and the live tree agree in both directions"
else
  fail "C10 the retirement record and the live tree agree in both directions"
fi

# ---------------------------------------------------------------------------
# C11 — extractor parity with the merge-base guard.
#
# scripts/check-retirement-ledger.py closes the direction C10 cannot see: a
# retirement that deletes a skill and writes no ledger row, where the phrases
# leave the live set and the record at once so both sides still agree. That
# guard has to read a SKILL.md recovered from the merge base, which this suite
# has no git ref to reach, so it carries its own copy of emit_phrases' normal
# form. Two copies of a normalization drift, and a drifted copy fails OPEN — it
# would extract fewer phrases from the deleted file and demand fewer rows, going
# green for the same reason the bug it guards goes green.
#
# This case pins them together over the real tree. It needs no git ref: the
# guard's --emit-phrases mode reads the directory and returns before any git
# call, so this case is safe inside the shallow plugin-test-suites job.
c11_ok=1
C11_GUARD="$REPO_ROOT/scripts/check-retirement-ledger.py"

if [ ! -f "$C11_GUARD" ]; then
  echo "     guard missing or unreadable: $C11_GUARD"
  c11_ok=0
else
  mkdir -p "$TMPROOT/c11"
  if ! emit_phrases "$WS_ROOT/skills" > "$TMPROOT/c11/suite" 2>/dev/null; then
    echo "     emit_phrases failed over $WS_ROOT/skills"
    c11_ok=0
  elif ! python3 "$C11_GUARD" --emit-phrases "$WS_ROOT/skills" \
         > "$TMPROOT/c11/guard" 2>/dev/null; then
    echo "     guard --emit-phrases failed over $WS_ROOT/skills"
    c11_ok=0
  else
    sort "$TMPROOT/c11/suite" > "$TMPROOT/c11/suite.s"
    sort "$TMPROOT/c11/guard" > "$TMPROOT/c11/guard.s"
    # Anti-vacuity floor, mirroring C9's and C10's: two empty outputs match
    # trivially, so an extractor that stopped finding anything would report
    # perfect parity. The real tree yields a non-empty set.
    c11_n=$(grep -c . "$TMPROOT/c11/suite.s" || true)
    if [ "$c11_n" -eq 0 ]; then
      echo "     parity is vacuous: emit_phrases yielded 0 phrases"
      c11_ok=0
    elif ! diff -u "$TMPROOT/c11/suite.s" "$TMPROOT/c11/guard.s" > "$TMPROOT/c11/diff"; then
      echo "     extractors disagree (suite yielded $c11_n phrase line(s)):"
      sed -n '1,20p' "$TMPROOT/c11/diff" | sed 's/^/       /'
      c11_ok=0
    fi
  fi
fi

if [ "$c11_ok" -eq 1 ]; then
  pass "C11 the retirement-ledger guard's extractor matches emit_phrases exactly"
else
  fail "C11 the retirement-ledger guard's extractor matches emit_phrases exactly"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures skill-trigger-phrase test(s) failed."
  exit 1
fi
echo ""
echo "All skill-trigger-phrase tests passed."
