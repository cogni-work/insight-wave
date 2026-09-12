#!/usr/bin/env bash
#
# test-slide-grammar.sh — binds the schema-4.1 presentation-brief slide grammar
# to the three surfaces that carry live grammar samples:
#
#   cogni-workspace/libraries/EXAMPLE_BRIEF.md                          (13 slides)
#   cogni-workspace/libraries/presentation-brief-template.md  (8)
#   cogni-workspace/libraries/references-slide.md (1)
#
# Why this exists alongside test-check-brief.sh: check-brief.py already enforces
# no-color-fields and deck-references-last, and cb01 / cb04 / pb05 already run it
# against EXAMPLE_BRIEF.md. What nothing bound before this suite are the two
# TEMPLATE surfaces. Those are fragments, not briefs — no frontmatter,
# {placeholder} headlines, slide numbers written N / N+1 / N+2 — so the grammar
# they document could drift with nothing noticing. The parser rationale, the
# traps it is shaped around and the required-key table it grades live in
# fixtures/slide-grammar/slide_grammar.py; this file does not restate them.
#
# The parser sits under fixtures/ because that is where this repo parks test
# assets that are not themselves suites — tests/fixtures/ already holds brief/,
# narrative-output/ and narrative-source/. Note the runner's non-recursive
# tests/*.sh and */tests/*.sh globs are NOT the reason: a .py file matches
# neither glob at any depth, so this parser would go undiscovered sitting
# directly at tests/ too. The globs are what keep a sourced-only *bash* helper
# under fixtures/ out of the sweep — one level deeper than the globs reach —
# whereas a bash helper sitting directly at tests/ WOULD be swept in. For this
# file the convention is the whole reason.
#
# Every case id reaches both a PASS and a FAIL arm, which is what makes it
# addressable by `mutation-check.sh --case`. Most cases get that structurally:
# every expect_* wrapper delegates to expect_rc, which owns both arms, so naming
# the id once at the call site cannot leave the two out of step. sg18 is the
# exception — it grades an equality between two files, not one command's exit
# code, so it hands expect_rc no system-under-test argv: any argv would be
# scaffolding the case manufactures. Its arms are hand-rolled below, spelling
# the id twice. Both shapes keep the two arms reachable, the property
# scripts/check-case-id-pairing.py enforces repo-wide.
# The sgNN-mutant-* cases corrupt a mktemp copy and assert the matching check
# goes red. Mutants address their target through the parser's `locate` op rather
# than by absolute line number; no mutant is ever committed.
#
# What keeps a red arm honest is the parser's exit code, not the arm's
# structure: every case asserts an EXACT code, and 1 alone means "the check
# found something" (the 0/1/2 contract is stated once, in slide_grammar.py's
# module docstring). This replaces the earlier claim that "no assertion can rot
# into a tautology unnoticed", which was false when written: every red arm
# accepted any non-zero, so a crashed parser read as a caught defect. Nine cases
# were exposed — the eight expect_red sites then present (sg10-sg16, sg19)
# plus sg17's then-hand-rolled arm — and could assert nothing while reporting
# PASS.
# sg24/sg25 guard the two enumerated crash arms; sg26 guards the contract
# itself, so a crash nobody enumerated cannot quietly reclaim exit 1.
#
# ## Mutation recipe
#
# Harness: ~/GitHub/dev/managed-service/cogni-service/scripts/mutation-check.sh
# Run with:
#   --root . --file cogni-workspace/tests/fixtures/slide-grammar/slide_grammar.py
#   --test 'bash cogni-workspace/tests/test-slide-grammar.sh'
#
#   --expr 's{Slide\\s\+\(\\S\+\)}{Slide\\s+(\\d+)}'   --case sg03-heading-counts
#   --expr 's{in COLOUR_FIELDS}{in set()}'              --case sg15-mutant-bare-role-flagged
#   --expr 's{if not hits:}{if False:}'                 --case sg17-mutant-missing-role-fails-closed
#   --expr 's{if n != 1}{if False}'                     --case sg19-mutant-missing-required-subkey
#   --expr 's{"Mood"}{"Mood", "Bogus"}'                 --case sg18-colour-fields-match-check-brief
#   --expr 's{EXIT_USAGE = 2}{EXIT_USAGE = 1}'          --case sg24-unknown-check-exits-usage
#   --expr 's{compile\(r"\^\\s\*\(}{compile(r"^(}'      --case sg22-mutant-nested-colour-field
#   --expr 's{\*\)\\s\*:"\)}{*):")}'                    --case sg23-mutant-spaced-colon-colour-field
#   --expr 's{kinds != \["references"\]}{kinds != kinds}' --case sg21-mutant-refslide-kind-demoted
#   --expr 's{rc = EXIT_USAGE}{rc = 1}'                  --case sg26-unenumerated-crash-exits-usage
#
# Verdict at authoring: guard_verified for all ten — each search text occurs
# exactly once in slide_grammar.py and each named case went red under its recipe,
# replayed against the literal harness path above exactly as written. The
# heading-counts one is the load-bearing original: it reinstates the digits-only
# regex that is this suite's central failure mode. The EXIT_USAGE one collapses
# the crash code back onto the finding code and so reddens sg25 and sg26
# alongside its named sg24 — all three assert rc 2 (sg26 through the __main__
# backstop), and that is the set the collapse breaks.
#
# Those ten all mutate slide_grammar.py — the parser this suite ships with —
# so together they prove the suite reads its own machinery. They cannot show it
# grades anything else: the three bound surfaces predate the parser and none of
# the ten touches one. What follows closes that, one recipe per bound surface,
# because "a guard that passes on a broken corpus is not a guard" is checkable
# only by breaking the corpus. Treat one-entry-per-surface as the rule rather
# than the sample: a surface listed at the top of this file with no recipe here
# is a hole, not an omission.
#
# All three use the same harness and the same --test as the ten above, and each
# rewrites the FIRST occurrence of its search text — mutation-check.sh applies
# its s{}{} without /g. For the two Slide-Kind recipes that first occurrence is
# the graded key inside the slide's yaml fence; the later one is a prose mention
# of the same string, which is why /g would corrupt the wrong thing.
#
# Corpus recipe 1 of 3, for the primary brief (the discriminator is
# sg06-references-slide-last):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/libraries/EXAMPLE_BRIEF.md \
#     --expr 's{Slide-Kind: references}{Slide-Kind: content}' \
#     --test 'bash cogni-workspace/tests/test-slide-grammar.sh' \
#     --case sg06-references-slide-last
#
# Demoting the brief's own references slide leaves the deck with no slide of
# that kind, so references-slide-last has nothing to find last and sg06 — a
# clean-corpus green arm — goes RED.
#
# Corpus recipe 2 of 3, for the slide template (the discriminator is
# sg03-heading-counts):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/libraries/presentation-brief-template.md \
#     --expr 's{## Slide N\+1: }{## Slidez N+1: }' \
#     --test 'bash cogni-workspace/tests/test-slide-grammar.sh' \
#     --case sg03-heading-counts
#
# This is the load-bearing one on the corpus side, and the mirror of the
# parser-side heading-counts recipe above: misspelling one heading drops the
# template's graded count from 8 to 7, so the pinned per-surface counts stop
# matching and sg03 goes RED. Between the two, heading-counts is now bound from
# both directions — the parser cannot silently stop counting, and the corpus
# cannot silently stop being counted.
#
# Corpus recipe 3 of 3, for the references-slide template (the discriminator is
# sg20-refslide-kind-is-references):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/libraries/references-slide.md \
#     --expr 's{Slide-Kind: references}{Slide-Kind: content}' \
#     --test 'bash cogni-workspace/tests/test-slide-grammar.sh' \
#     --case sg20-refslide-kind-is-references
#
# The mirror of the parser-targeted sg21, which reddens the same check by
# breaking the comparison instead of the corpus. Neither substitutes for the
# other: sg21 stages its own copy and sets the kind line regardless of the
# file's starting value, so a corpus mutation leaves it green, and sg20 reads
# the real file, so a parser mutation leaves it green.
#
# Verdict at authoring: guard_verified for all three — each went RED under its
# recipe and green again on restore, replayed against the literal harness path
# above exactly as written.

set -u

# Keep CPython from dropping a __pycache__/ into the plugin tree — that
# directory is an interpreter artifact this repo keeps out of the tree by
# policy: it is gitignored, and scripts/check-skill-spec.py prunes it from its
# own walk.
export PYTHONDONTWRITEBYTECODE=1

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAM="$ROOT/cogni-workspace/tests/fixtures/slide-grammar/slide_grammar.py"

BRIEF="$ROOT/cogni-workspace/libraries/EXAMPLE_BRIEF.md"
TEMPLATE="$ROOT/cogni-workspace/libraries/presentation-brief-template.md"
REFSLIDE="$ROOT/cogni-workspace/libraries/references-slide.md"
CHECK_BRIEF="$ROOT/cogni-workspace/scripts/check-brief.py"

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# Run one check against the real corpus. Output is NOT suppressed here —
# expect_rc owns the suppression on its first invocation, so its failure replay
# has something to print. Baking the redirect in here silently emptied that
# replay for every wrapper-routed case, which is most of them.
clean() { python3 "$GRAM" "$1" "brief=$BRIEF" "template=$TEMPLATE" "refslide=$REFSLIDE"; }

# Run one check against a staged (mutated) copy. Roles are passed explicitly, so
# the deliberately different filenames here cannot make a check self-skip.
mutant() { python3 "$GRAM" "$2" "brief=$1/brief.md" "template=$1/template.md" "refslide=$1/refslide.md"; }

# Every arm asserts an EXACT exit code, never "zero vs non-zero" — that is the
# whole mechanism, so it lives in exactly one place here and the wrappers below
# only bind the code they want.

# expect_rc <wanted-rc> <case-id> <failure-sentence> <cmd...>
# On failure, replay without the redirect and indent the output — an rc=2 says
# only "it crashed", and the traceback is the whole diagnosis. Same shape as
# test-narrative-validate.sh's failure arm.
expect_rc() {
  local want="$1" id="$2" msg="$3"; shift 3
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq "$want" ]; then
    pass "$id"
  else
    "$@" 2>&1 | sed 's/^/    /'
    fail "$id $msg (rc=$rc)"
  fi
}

# expect_green <case-id> <check> <failure-sentence>
expect_green() { expect_rc 0 "$1" "$3" clean "$2"; }

# expect_red <case-id> <staged-dir> <check> <failure-sentence>
expect_red() { expect_rc 1 "$1" "$4" mutant "$2" "$3"; }

# expect_usage <case-id> <failure-sentence> <argv...> — the parser must exit 2.
expect_usage() { local id="$1" msg="$2"; shift 2; expect_rc 2 "$id" "$msg" python3 "$GRAM" "$@"; }

# Stage a fresh copy of all three surfaces and echo the directory. All three are
# copied even when one is mutated, so `mutant` can always pass every role.
stage() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  cp "$BRIEF" "$d/brief.md"
  cp "$TEMPLATE" "$d/template.md"
  cp "$REFSLIDE" "$d/refslide.md"
  printf '%s\n' "$d"
}

# mutate <staged-dir> <role> <selector> <del|set|ins> [text]
# The selector is resolved by the parser, so a corpus edit above the target
# cannot silently re-aim the mutation at a neighbouring line.
mutate() {
  local d="$1" role="$2" sel="$3" op="$4" txt="${5-}" doc idx
  case "$role" in
    brief) doc="brief.md" ;;
    template) doc="template.md" ;;
    refslide) doc="refslide.md" ;;
    *) printf 'unknown role %s\n' "$role" >&2; return 1 ;;
  esac
  idx="$(python3 "$GRAM" locate "$role=$d/$doc" "$sel")" || return 1
  python3 - "$d/$doc" "$idx" "$op" "$txt" <<'PY'
import sys
path, idx, op, txt = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
lines = open(path, encoding="utf-8").read().split("\n")
if op == "del":
    del lines[idx]
elif op == "set":
    lines[idx] = txt
elif op == "ins":
    lines.insert(idx, txt)
else:
    raise SystemExit("unknown op %r" % op)
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
}

# ---------------------------------------------------------------- clean corpus

expect_green sg01-fences-balanced fences-balanced \
  "a bound surface has an unbalanced fence at EOF"
expect_green sg02-one-yaml-fence-per-slide one-yaml-fence-per-slide \
  "a slide heading is not followed by exactly one yaml fence"
expect_green sg03-heading-counts heading-counts \
  "a surface graded a different number of slides than 13/8/1, or disagreed with its own loose recount"
expect_green sg04-slide-kind-single slide-kind-single \
  "a slide carries zero or multiple Slide-Kind keys"
expect_green sg05-slide-kind-enum slide-kind-enum \
  "a Slide-Kind value is outside content/internal-prep/references"
expect_green sg06-references-slide-last references-slide-last \
  "the references slide is not the last slide of EXAMPLE_BRIEF.md"
expect_green sg07-no-colour-fields no-colour-fields \
  "a colour field appears inside a slide yaml block"
expect_green sg08-required-41-subkeys required-4.1-subkeys \
  "a slide is missing its nested intent.role or visual.kind key"
expect_green sg09-non-numeric-slide-labels-graded non-numeric-slide-labels-graded \
  "the N / N+1 / N+2 headings were not graded"
expect_green sg20-refslide-kind-is-references references-slide-kind \
  "references-slide.md's slide does not carry Slide-Kind: references"

# --------------------------------------------------------------------- mutants

d="$(stage m10)"; mutate "$d" brief fence-close:1 del
expect_red sg10-mutant-unbalanced-fence "$d" fences-balanced \
  "a dropped closing fence was not reported"

d="$(stage m11)"; mutate "$d" brief fence-open:1 set '```yml'
expect_red sg11-mutant-fence-retagged "$d" one-yaml-fence-per-slide \
  "a slide fence tagged yml instead of yaml was not reported"

d="$(stage m12)"; mutate "$d" brief kind-line:1 ins 'Slide-Kind: content'
expect_red sg12-mutant-duplicate-slide-kind "$d" slide-kind-single \
  "a second Slide-Kind key was not reported"

d="$(stage m13)"; mutate "$d" brief kind-line:1 set 'Slide-Kind: bogus'
expect_red sg13-mutant-slide-kind-out-of-enum "$d" slide-kind-enum \
  "an out-of-enum Slide-Kind value was not reported"

d="$(stage m14)"; mutate "$d" brief kind-line:last set 'Slide-Kind: content'
expect_red sg14-mutant-references-not-last "$d" references-slide-last \
  "a demoted references slide was not reported"

# The prohibitive half of the intent.role carve-out. sg07 proves the scan stays
# quiet on the prose mentions; this proves it still fires on a real bare key.
d="$(stage m15)"; mutate "$d" brief body-top:1 ins 'Role: emphasis'
expect_red sg15-mutant-bare-role-flagged "$d" no-colour-fields \
  "an injected top-level Role: key was not reported"

# The central regression: if the heading matcher ever narrows to (\d+), the three
# non-numeric labels leave the parsed set.
d="$(stage m16)"
python3 - "$d/template.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = (text.replace("## Slide N: ", "## Slide 90: ")
            .replace("## Slide N+1: ", "## Slide 91: ")
            .replace("## Slide N+2: ", "## Slide 92: "))
open(path, "w", encoding="utf-8").write(text)
PY
expect_red sg16-mutant-non-numeric-labels-removed "$d" non-numeric-slide-labels-graded \
  "renumbering N/N+1/N+2 away was not reported"

# A role-scoped check handed no document for its role must go red rather than
# report green having graded nothing — the silent-skip failure this suite exists
# to prevent, applied to the suite's own plumbing.
expect_rc 1 sg17-mutant-missing-role-fails-closed \
  "a check with no document for its role did not report a finding" \
  python3 "$GRAM" references-slide-last "template=$TEMPLATE"

# The forbidden set is copied into the fixture rather than imported, to keep it
# standalone; the rationale lives at slide_grammar.py's COLOUR_FIELDS. This case
# is what makes a divergence visible — without it a stale copy would narrow sg07
# with no case going red.
if python3 - "$GRAM" "$CHECK_BRIEF" <<'PY'
import importlib.util, json, subprocess, sys
gram, check_brief = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("check_brief", check_brief)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
ours = set(json.loads(subprocess.run([sys.executable, gram, "dump-colour-fields"],
                                     capture_output=True, text=True, check=True).stdout))
sys.exit(0 if ours == set(mod.COLOR_KEYS_SLIDES) else 1)
PY
then
  pass "sg18-colour-fields-match-check-brief"
else
  fail "sg18-colour-fields-match-check-brief the forbidden colour set has diverged from check-brief.py COLOR_KEYS_SLIDES"
fi

d="$(stage m19)"; mutate "$d" brief subkey:intent/1 del
expect_red sg19-mutant-missing-required-subkey "$d" required-4.1-subkeys \
  "a slide stripped of its nested intent.role key was not reported"

# The refslide surface's defining property. references-slide-last is brief-scoped
# and never reads this file, so before sg20/sg21 the one document whose whole
# purpose is the references slide contributed only "one slide, well-formed".
d="$(stage m21)"; mutate "$d" refslide kind-line:1 set 'Slide-Kind: content'
expect_red sg21-mutant-refslide-kind-demoted "$d" references-slide-kind \
  "a demoted references-slide Slide-Kind was not reported"

# Depth. check-brief.py's check_no_color_fields walks _keys() recursively, and
# it cannot parse either template surface at all, so a nested styling key there
# is guarded by this scan alone.
d="$(stage m22)"; mutate "$d" template subkey:visual/1 ins '  Background: "#ff0000"'
expect_red sg22-mutant-nested-colour-field "$d" no-colour-fields \
  "a colour key nested under visual: was not reported"

# Spacing. `Background : x` is a real yaml key that check-brief.py flags; a
# regex requiring the colon to follow the key immediately misses it entirely.
d="$(stage m23)"; mutate "$d" template body-top:1 ins 'Background : "#ff0000"'
expect_red sg23-mutant-spaced-colon-colour-field "$d" no-colour-fields \
  "a colour key written with a space before its colon was not reported"

# The two cases below guard the crash-vs-finding split itself, replaying the two
# reproductions that falsified this suite's own header claim. Both previously
# yielded 19 PASS and exit 0, because expect_red accepted any non-zero.
expect_usage sg24-unknown-check-exits-usage \
  "an unknown check name did not exit 2, so a mis-typed check reads as a caught defect" \
  no-such-checkZZZ "brief=$BRIEF" "template=$TEMPLATE" "refslide=$REFSLIDE"

expect_usage sg25-unreadable-surface-exits-usage \
  "an unreadable surface did not exit 2, so a failed stage() reads as a caught defect" \
  fences-balanced "brief=$TMPROOT/does-not-exist.md"

# sg24 and sg25 pin the two ENUMERATED arms. This one pins the contract
# sentence: a crash nobody enumerated must still not wear the finding code.
# `locate` with no document raises IndexError on docs[0]; before the __main__
# backstop it exited 1.
expect_usage sg26-unenumerated-crash-exits-usage \
  "an unhandled parser exception did not exit 2, so an unenumerated crash still reads as a finding" \
  locate "kind-line:1"

exit "$failures"
