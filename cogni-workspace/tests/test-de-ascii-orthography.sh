#!/usr/bin/env bash
# Guard: German-language copy under cogni-visual/ must keep its Unicode umlauts.
#
# WHAT THIS PINS
#   No enumerated ASCII-ified German token may appear in the plugin's markdown. Two
#   corruption styles are covered, because both were observed on origin/main:
#     dropped-vowel  the diacritic is simply dropped   (Stillstaende -> the a-form)
#     digraph        the umlaut is expanded to ae/oe/ue (Qualitaet-style spellings)
#   The vocabulary lives in the VOCABULARY table below, one row per token.
#
# WHY A TEST AND NOT MORE PROSE
#   This corruption degrades SILENTLY. Nothing errors, nothing warns; the copy simply
#   reads as machine-generated to a German speaker and as correct to everyone else. It
#   took two separate content PRs to clear the last outbreak, and the rule that was
#   supposed to prevent it was itself prose. Prose did not hold. A suite does.
#
# WHAT A GREEN RUN DOES AND DOES NOT MEAN
#   Green means NO ENUMERATED TOKEN APPEARED. It does NOT mean the corpus is
#   orthographically correct. This distinction is not hedging — the vocabulary is a
#   curated list, so a corruption whose token is not on it passes unseen, and has done.
#   Read a green run as "no enumerated token regressed", never as proof the German in
#   the corpus is clean.
#
# WHY A CURATED VOCABULARY RATHER THAN A GENERAL ORTHOGRAPHY PATTERN
#   Forced, not stylistic. A general pattern that infers "this looks like a de-umlauted
#   German word" is red on the base tree: the scanned corpus deliberately documents the
#   umlaut-to-ASCII transliteration used for slugs and filenames, and carries English
#   prose and brand words, none of which such an inference separates from real
#   corruption — which is why the EXEMPT table and the de-context guard column exist.
#   So the suite has to do two things at once: flag genuine ASCII-ified German, and exit
#   0 on a clean base. Only an enumerated vocabulary can satisfy both at once. The cost
#   is that the guard catches exactly what it lists, which is why extending it is a
#   first-class, test-enforced operation (see below) rather than an afterthought.
#   This is a settled decision, not an open question deferred to a later rewrite, and
#   reversing it has a known consequence: a matcher that infers the shape instead of
#   listing the vocabulary is red on the base tree, for the reasons just given.
#   Coverage grows by adding rows.
#
# HOW TO EXTEND THE VOCABULARY
#   Add one row to VOCABULARY: ascii_token|correct_form|style|guard. That is the whole
#   manual step. The P1 and P2 positive fixtures are GENERATED at run time by an awk pass
#   directly over this same table, so a new row is planted in the matching fixture without
#   anyone editing one — an earlier revision of this comment asked for that edit by hand,
#   which was already untrue and sent contributors looking for a file that does not exist.
#   The proof still grows with the vocabulary, it just grows automatically: W1 rejects a
#   row whose ascii_token is not what correct_form actually folds to under the declared
#   style, so an unmatchable typo cannot be committed, and W2 set-differences the
#   vocabulary against the tokens the generated fixtures actually cause the scanner to
#   report, in BOTH directions — so a row the scanner cannot detect fails just as loudly
#   as a token with no row.
#
# WHY EXEMPTIONS ARE CONTENT-ANCHORED, NEVER LINE-ANCHORED
#   Two files legitimately contain ASCII forms: one states the umlaut rule by naming the
#   ASCII spellings it forbids, the other defines a deliberate umlaut-to-ASCII mapping for
#   filename slugs. Pinning those by line number would rot on the next edit above them,
#   and the failure mode would be a FALSE POSITIVE on correct content — the "a naive guard
#   is worse than none" outcome. Each exemption therefore keys on a substring of the line
#   itself, and C2 asserts every anchor still resolves, so a reword forces a human to
#   re-confirm the carve-out instead of letting it silently become dead weight.
#
# CASE LABEL SHAPE: `ok: <id>` / `FAIL: <id>` — colon form, matching the sibling suite
#   tests/test-arc-taxonomy-sync.sh. The shared mutation harness and the handoff preflight
#   classify a case by reading OUTPUT LINES, not the exit code: red is
#   `^[ \t]*FAIL:[ \t]+<case>`, green is `^[ \t]*(?:ok|PASS):[ \t]+<case>`. The older
#   no-colon `OK   ` / `FAIL ` shape matches neither and returns case_not_found, which
#   silently disarms the mutation recipe while the suite still looks green. Case ids are
#   bare single tokens (`C1`, never `C1:`) for the same reason. The summary is prefixed
#   `RESULT:` so it is never itself parsed as a case verdict, and advisory lines are
#   prefixed `NOTE:` for the same reason.
#
# EXECUTED NEGATIVE CASE
#   M1 copies the plugin's markdown into this run's own mktemp -d, injects one corrupted
#   line into the COPY, re-invokes this same file against the mutant, and requires the
#   child to exit non-zero AND report C1 red by name. Asserting the exit code alone would
#   be too weak — a non-zero exit cannot distinguish C1 going red from any other case
#   going red. The tracked tree is never written to.
#
# SELF-CONTAINMENT
#   One file, bash + python3 + coreutils, no network, no arguments, cwd-independent,
#   writes only under its own mktemp -d. It deliberately does NOT call or vendor the
#   sibling ss/ligature scanner in another plugin: that scanner covers a different defect
#   class, and the cross-plugin guard-sharing mechanism is an undecided open question. A
#   self-contained suite does not pre-empt that decision.
#
# AUTHOR CONSTRAINT
#   No vocabulary token may appear in any .md file this plugin ships, including the
#   registration entry in CLAUDE.md — that file is inside the scanned tree, so naming a
#   token there turns C1 red.
#
# Usage: bash cogni-workspace/tests/test-de-ascii-orthography.sh   (no args, no network)

set -u
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"

# Scan root is overridable ONLY so the M1 negative case can aim this same file at a
# mutant copy. Production runs never set it.
SCAN_ROOT="${VISUAL_DE_ASCII_ROOT:-$PLUGIN_DIR}"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
note() { echo "NOTE: $1"; }

ALL_CASES="V1 V2 V3 V4 W1 W2 P1 P2 X1 X2 X3 X4 X5 G1 C1 C2 M1"

DOWNSTREAM_CASES=""
for case_id in $ALL_CASES; do
  case "$case_id" in
    V*) ;;
    *) DOWNSTREAM_CASES="$DOWNSTREAM_CASES $case_id" ;;
  esac
done
DOWNSTREAM_CASES="${DOWNSTREAM_CASES# }"

# Deliberately not prefixed `FAIL:` — that shape is reserved for per-case verdicts, and a
# summary wearing it would be misread as a case named by its first token.
finish() {
  echo ""
  if [ "$failures" -gt 0 ]; then
    echo "RESULT: $failures de-ascii-orthography case(s) failed."
    exit 1
  fi
  echo "RESULT: all de-ascii-orthography cases passed."
  exit 0
}

# Abandon the run when an input is missing or unusable, reporting every downstream case
# under its own id first so a bail is never mistaken for coverage.
bail_out() {
  for case_id in $DOWNSTREAM_CASES; do
    fail "$case_id not evaluated — non-vacuity guard failed"
  done
  finish
}

# ---------------------------------------------------------------------- vocabulary
# ascii_token|correct_form|style|guard
#   style ∈ {dropped-vowel, digraph} — selects the fold W1 verifies the row against.
#   guard ∈ {plain, de-context} — `de-context` tokens are also ordinary English or brand
#   words, so they count only on a line carrying an independent German signal. Without
#   that guard the two of them would be the first tokens to false-positive the moment any
#   English prose is added to the scanned tree.
cat > "$TMPROOT/vocabulary.txt" <<'VOCAB'
Stillstande|Stillstände|dropped-vowel|plain
fur|für|dropped-vowel|de-context
uber|über|dropped-vowel|de-context
nachste|nächste|dropped-vowel|plain
Verschleiss|Verschleiß|dropped-vowel|plain
Wettbewerbsfahigkeit|Wettbewerbsfähigkeit|dropped-vowel|plain
Krafte|Kräfte|dropped-vowel|plain
Fuhrung|Führung|dropped-vowel|plain
Erstgesprach|Erstgespräch|dropped-vowel|plain
jahrlich|jährlich|dropped-vowel|plain
ausrusten|ausrüsten|dropped-vowel|plain
Uberblick|Überblick|dropped-vowel|plain
Qualitaetsdrift|Qualitätsdrift|digraph|plain
hoehere|höhere|digraph|plain
LOESUNG|LÖSUNG|digraph|plain
FAEHIGKEITEN|FÄHIGKEITEN|digraph|plain
Anlagenverfuegbarkeit|Anlagenverfügbarkeit|digraph|plain
Qualitaet|Qualität|digraph|plain
Woerter|Wörter|digraph|plain
Pruefung|Prüfung|digraph|plain
Naehe|Nähe|digraph|plain
Hauptsaetze|Hauptsätze|digraph|plain
Massnahmen|Maßnahmen|digraph|plain
Beruecksichtigung|Berücksichtigung|digraph|plain
verkuerzen|verkürzen|digraph|plain
VOCAB

# ---------------------------------------------------------------------- exemptions
# relative_path|anchor_substring
# A line in the named file containing the anchor is exempt. Content-anchored on purpose;
# C2 asserts each anchor still resolves so a reword cannot silently void the carve-out.
cat > "$TMPROOT/exemptions.txt" <<'EXEMPT'
libraries/web-brief-validation.md|ae/oe/ue
agents/web.md|Replace German umlauts
EXEMPT

# ---------------------------------------------------------------------- the scanner
cat > "$TMPROOT/scan.py" <<'SCANNER'
"""Report enumerated ASCII-ified German tokens in markdown under a scan root.

Emits one `path:line:token` per finding on stdout. Structural exemptions (frontmatter
description blocks, English image-prompt scalars, inline code, URLs, slug/path shapes)
and the declared content-anchored exemptions are applied before a match counts.
"""
import os
import re
import sys

scan_root, vocab_path, exempt_path = sys.argv[1], sys.argv[2], sys.argv[3]

vocab = []
with open(vocab_path, encoding="utf-8") as handle:
    for raw in handle:
        raw = raw.strip()
        if not raw or raw.startswith("#"):
            continue
        token, correct, style, guard = raw.split("|")
        vocab.append({"token": token, "correct": correct, "style": style, "guard": guard})

exemptions = {}
with open(exempt_path, encoding="utf-8") as handle:
    for raw in handle:
        raw = raw.strip()
        if not raw or raw.startswith("#"):
            continue
        rel, anchor = raw.split("|", 1)
        exemptions.setdefault(rel, []).append(anchor)

WORD = "A-Za-z0-9_ÄÖÜäöüß"
PATTERNS = [
    (entry, re.compile(r"(?<![" + WORD + r"])" + re.escape(entry["token"]) + r"(?![" + WORD + r"])",
                       re.IGNORECASE))
    for entry in vocab
]

# A German signal on the same line: a real umlaut/eszett, or a common function word that
# does not exist in English. Used only to qualify `de-context` tokens.
UMLAUT = re.compile(r"[ÄÖÜäöüß]")
DE_STOPWORDS = re.compile(
    r"(?<![" + WORD + r"])(?:und|oder|nicht|eine|einen|einem|einer|der|die|das|den|dem|des"
    r"|mit|von|auf|aus|im|ins|zum|zur|bei|durch|nach|wird|werden|sind|ist|sich|Sie|Ihre"
    r"|Ihren|kein|keine|mehr|schon|noch|beim|dass)(?![" + WORD + r"])"
)

INLINE_CODE = re.compile(r"`[^`]*`")
URL = re.compile(r"(?:https?://|www\.)\S+")


def strip_uncheckable(line):
    """Blank out spans that are never prose: inline code and URLs."""
    line = INLINE_CODE.sub(lambda m: " " * len(m.group(0)), line)
    line = URL.sub(lambda m: " " * len(m.group(0)), line)
    return line


def is_slug_context(line, start, end):
    """True when the match sits inside a larger path/slug/identifier token.

    Expands over characters that glue identifiers together. A trailing dot only counts
    as glue when another word character follows it, so ordinary sentence punctuation
    does not disguise a real finding as a filename.
    """
    left = start
    while left > 0 and (line[left - 1] in "-_/" or line[left - 1] in "." and left - 1 > 0):
        if line[left - 1] == "." and not (left < len(line)):
            break
        left -= 1
        while left > 0 and re.match(r"[" + WORD + r"]", line[left - 1]):
            left -= 1
    right = end
    while right < len(line):
        ch = line[right]
        if ch in "-_/":
            right += 1
        elif ch == "." and right + 1 < len(line) and re.match(r"[" + WORD + r"]", line[right + 1]):
            right += 1
        else:
            break
        while right < len(line) and re.match(r"[" + WORD + r"]", line[right]):
            right += 1
    return (left, right) != (start, end)


def frontmatter_description_lines(lines):
    """Line indices belonging to a YAML frontmatter `description:` value.

    Trigger phrases in a description are matching keys, not prose: they are spelled in
    ASCII on purpose so a user without a German keyboard still triggers the skill.
    """
    if not lines or lines[0].rstrip("\n") != "---":
        return set()
    end = None
    for idx in range(1, len(lines)):
        if lines[idx].rstrip("\n") == "---":
            end = idx
            break
    if end is None:
        return set()
    marked, active = set(), False
    for idx in range(1, end):
        line = lines[idx]
        if re.match(r"^description\s*:", line):
            active = True
            marked.add(idx)
            continue
        if active:
            # A continuation line is indented; a new top-level key ends the value.
            if line.strip() == "" or line[:1] in (" ", "\t"):
                marked.add(idx)
                continue
            active = False
    return marked


def image_prompt_lines(lines):
    """Line indices belonging to an `image_prompt:` key or its block scalar body.

    Image prompts are always written in English regardless of the brief's language, so
    they are never German copy and must never be scanned as such.
    """
    marked = set()
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        match = re.match(r"^(\s*)image_prompt\s*:(.*)$", line)
        if not match:
            idx += 1
            continue
        indent = len(match.group(1))
        marked.add(idx)
        idx += 1
        while idx < len(lines):
            nxt = lines[idx]
            if nxt.strip() == "":
                marked.add(idx)
                idx += 1
                continue
            nxt_indent = len(nxt) - len(nxt.lstrip())
            if nxt_indent > indent:
                marked.add(idx)
                idx += 1
                continue
            break
    return marked


findings = []
scanned = 0
german_bearing = 0

for dirpath, dirnames, filenames in os.walk(scan_root):
    dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
    for name in sorted(filenames):
        if not name.endswith(".md"):
            continue
        abs_path = os.path.join(dirpath, name)
        rel_path = os.path.relpath(abs_path, scan_root)
        try:
            with open(abs_path, encoding="utf-8") as handle:
                lines = handle.read().splitlines(keepends=False)
        except (OSError, UnicodeDecodeError):
            print("UNREADABLE:%s" % rel_path, file=sys.stderr)
            sys.exit(3)
        scanned += 1
        if any(UMLAUT.search(line) for line in lines):
            german_bearing += 1

        skip = frontmatter_description_lines(lines) | image_prompt_lines(lines)
        anchors = exemptions.get(rel_path.replace(os.sep, "/"), [])

        for lineno, line in enumerate(lines):
            if lineno in skip:
                continue
            if any(anchor in line for anchor in anchors):
                continue
            probe = strip_uncheckable(line)
            hits = []
            for entry, pattern in PATTERNS:
                for match in pattern.finditer(probe):
                    if is_slug_context(probe, match.start(), match.end()):
                        continue
                    hits.append((entry, match))
            if not hits:
                continue
            plain_hit = any(entry["guard"] == "plain" for entry, _ in hits)
            has_umlaut = bool(UMLAUT.search(line))
            has_stopword = bool(DE_STOPWORDS.search(probe))
            for entry, match in hits:
                if entry["guard"] == "de-context" and not (plain_hit or has_umlaut or has_stopword):
                    continue
                findings.append("%s:%d:%s" % (rel_path, lineno + 1, entry["token"]))

print("SCANNED:%d" % scanned, file=sys.stderr)
print("GERMAN:%d" % german_bearing, file=sys.stderr)
for finding in findings:
    print(finding)
SCANNER

scan() {
  python3 "$TMPROOT/scan.py" "$1" "$TMPROOT/vocabulary.txt" "$TMPROOT/exemptions.txt" \
    2> "$TMPROOT/scan.err"
}

# ---------------------------------------------------------------- non-vacuity guards
# Without these, a moved corpus or an empty vocabulary yields zero findings, which is
# indistinguishable from a clean tree — the suite would report green forever. That is the
# same silent degradation this guard exists to catch, one level up.
vacuous=0

if [ -d "$SCAN_ROOT" ]; then
  pass "V1 scan root is present at $SCAN_ROOT"
else
  fail "V1 scan root not found at $SCAN_ROOT"
  vacuous=1
fi

vocab_total=$(grep -c '|' "$TMPROOT/vocabulary.txt" | tr -d ' ')
vocab_dropped=$(awk -F'|' '$3 == "dropped-vowel"' "$TMPROOT/vocabulary.txt" | wc -l | tr -d ' ')
vocab_digraph=$(awk -F'|' '$3 == "digraph"' "$TMPROOT/vocabulary.txt" | wc -l | tr -d ' ')

if [ "$vocab_total" -gt 0 ] && [ "$vocab_dropped" -gt 0 ] && [ "$vocab_digraph" -gt 0 ]; then
  pass "V2 vocabulary parsed: $vocab_total token(s), $vocab_dropped dropped-vowel, $vocab_digraph digraph"
else
  fail "V2 vocabulary empty or missing a style (total=$vocab_total dropped=$vocab_dropped digraph=$vocab_digraph)"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

scan "$SCAN_ROOT" > "$TMPROOT/tracked_findings.txt"
scan_rc=$?
scanned_count=$(sed -n 's/^SCANNED://p' "$TMPROOT/scan.err")
german_count=$(sed -n 's/^GERMAN://p' "$TMPROOT/scan.err")
: "${scanned_count:=0}"
: "${german_count:=0}"

if [ "$scan_rc" -ne 0 ]; then
  fail "V3 scanner exited $scan_rc — $(head -n 1 "$TMPROOT/scan.err")"
  vacuous=1
elif [ "$scanned_count" -gt 0 ]; then
  pass "V3 scanned $scanned_count markdown file(s) under the scan root"
else
  fail "V3 scanned no markdown files — the corpus moved or the walk is broken"
  vacuous=1
fi

if [ "$german_count" -gt 0 ]; then
  pass "V4 $german_count scanned file(s) carry real German characters"
else
  fail "V4 no scanned file carries a German character — a green run would be meaningless"
  vacuous=1
fi

if [ "$vacuous" -ne 0 ]; then
  bail_out
fi

note "corpus: $scanned_count markdown file(s), $german_count German-bearing"
note "vocabulary: $vocab_dropped dropped-vowel + $vocab_digraph digraph = $vocab_total token(s)"
note "exemption anchors declared: $(grep -c '|' "$TMPROOT/exemptions.txt" | tr -d ' ')"

# ------------------------------------------------------------------ W1 fold-verified
# A row whose ascii_token is not what correct_form folds to under its declared style can
# never match anything. Committing one would silently shrink the guard.
if python3 - "$TMPROOT/vocabulary.txt" > "$TMPROOT/w1.txt" <<'PY'
import sys

DROPPED = {"ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O",
           "Ü": "U", "ß": "ss"}


def fold(word, style):
    out = []
    for idx, ch in enumerate(word):
        if style == "dropped-vowel":
            out.append(DROPPED.get(ch, ch))
            continue
        if ch == "ß":
            out.append("ss")
        elif ch in "äöü":
            out.append({"ä": "ae", "ö": "oe", "ü": "ue"}[ch])
        elif ch in "ÄÖÜ":
            base = {"Ä": "A", "Ö": "O", "Ü": "U"}[ch]
            rest = word[idx + 1:]
            upper = bool(rest) and rest[0].isupper()
            out.append(base + ("E" if upper else "e"))
        else:
            out.append(ch)
    return "".join(out)


problems, seen = [], set()
with open(sys.argv[1], encoding="utf-8") as handle:
    for lineno, raw in enumerate(handle, 1):
        raw = raw.strip()
        if not raw or raw.startswith("#"):
            continue
        parts = raw.split("|")
        if len(parts) != 4:
            problems.append("row %d: expected 4 fields, got %d" % (lineno, len(parts)))
            continue
        token, correct, style, guard = parts
        if style not in ("dropped-vowel", "digraph"):
            problems.append("row %d: undeclared style %r" % (lineno, style))
            continue
        if guard not in ("plain", "de-context"):
            problems.append("row %d: undeclared guard %r" % (lineno, guard))
        if not token.isascii():
            problems.append("row %d: ascii_token %r is not ASCII" % (lineno, token))
        if token in seen:
            problems.append("row %d: duplicate token %r" % (lineno, token))
        seen.add(token)
        folded = fold(correct, style)
        if folded != token:
            problems.append("row %d: %r folds to %r under %s, not %r"
                            % (lineno, correct, folded, style, token))

for problem in problems:
    print(problem)
sys.exit(1 if problems else 0)
PY
then
  pass "W1 every vocabulary row is well-formed and fold-verified against its correct form"
else
  fail "W1 vocabulary row(s) rejected: $(tr '\n' ';' < "$TMPROOT/w1.txt")"
fi

# ------------------------------------------------------------------- positive fixtures
# Each fixture plants every token of one style into plain German content, so a token that
# the matcher cannot see is named individually rather than hiding behind an aggregate.
mkdir -p "$TMPROOT/pos/skills/demo/references"
{
  echo "# Beispielinhalt"
  echo ""
  awk -F'|' '$3 == "dropped-vowel" { print "- Die Anlage und der Betrieb: " $1 " ist hier nicht korrekt." }' \
    "$TMPROOT/vocabulary.txt"
} > "$TMPROOT/pos/skills/demo/references/dropped.md"
{
  echo "# Beispielinhalt"
  echo ""
  awk -F'|' '$3 == "digraph" { print "- Die Anlage und der Betrieb: " $1 " ist hier nicht korrekt." }' \
    "$TMPROOT/vocabulary.txt"
} > "$TMPROOT/pos/skills/demo/references/digraph.md"

scan "$TMPROOT/pos" > "$TMPROOT/pos_findings.txt"
cut -d: -f3 "$TMPROOT/pos_findings.txt" | sort -u > "$TMPROOT/pos_tokens.txt"

awk -F'|' '$3 == "dropped-vowel" { print $1 }' "$TMPROOT/vocabulary.txt" | sort -u > "$TMPROOT/want_dropped.txt"
awk -F'|' '$3 == "digraph" { print $1 }' "$TMPROOT/vocabulary.txt" | sort -u > "$TMPROOT/want_digraph.txt"
grep -F 'dropped.md' "$TMPROOT/pos_findings.txt" | cut -d: -f3 | sort -u > "$TMPROOT/got_dropped.txt"
grep -F 'digraph.md' "$TMPROOT/pos_findings.txt" | cut -d: -f3 | sort -u > "$TMPROOT/got_digraph.txt"

missing_dropped=$(comm -23 "$TMPROOT/want_dropped.txt" "$TMPROOT/got_dropped.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$missing_dropped" ]; then
  pass "P1 every dropped-vowel token is detected in German content ($vocab_dropped token(s))"
else
  fail "P1 dropped-vowel token(s) not detected: $missing_dropped"
fi

missing_digraph=$(comm -23 "$TMPROOT/want_digraph.txt" "$TMPROOT/got_digraph.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$missing_digraph" ]; then
  pass "P2 every digraph token is detected in German content ($vocab_digraph token(s))"
else
  fail "P2 digraph token(s) not detected: $missing_digraph"
fi

# --------------------------------------------------------- W2 vocabulary <-> fixtures
awk -F'|' '{ print $1 }' "$TMPROOT/vocabulary.txt" | sort -u > "$TMPROOT/want_all.txt"
undetected=$(comm -23 "$TMPROOT/want_all.txt" "$TMPROOT/pos_tokens.txt" | tr '\n' ' ' | sed 's/ *$//')
unexpected=$(comm -13 "$TMPROOT/want_all.txt" "$TMPROOT/pos_tokens.txt" | tr '\n' ' ' | sed 's/ *$//')
if [ -z "$undetected" ] && [ -z "$unexpected" ]; then
  pass "W2 the fixture-exercised token set equals the vocabulary in both directions"
elif [ -n "$undetected" ]; then
  fail "W2 vocabulary token(s) no fixture exercises: $undetected — add fixture coverage with the row"
else
  fail "W2 fixture reported token(s) absent from the vocabulary: $unexpected"
fi

# ------------------------------------------------------------------ exemption fixtures
# Each plants a REAL vocabulary token inside an exempt context and requires zero findings.
# P1/P2 above are the paired controls: they plant the same tokens in plain German content
# and require detection, so an exemption case cannot pass merely by the matcher being dead.
mkdir -p "$TMPROOT/exempt/libraries" "$TMPROOT/exempt/agents" \
         "$TMPROOT/exempt/skills/demo"

cat > "$TMPROOT/exempt/libraries/web-brief-validation.md" <<'FIXTURE'
# Validation

- `[W]` German umlauts preserved where possible (a/o/u not ae/oe/ue)
  - If this fails, replace ae/oe/ue with proper umlauts. Qualitaet and hoehere are the shapes to avoid.
FIXTURE

cat > "$TMPROOT/exempt/agents/web.md" <<'FIXTURE'
# Web agent

4. Slugify the title:
   - Replace German umlauts: a->ae, o->oe, u->ue. Uberblick and Krafte are produced this way.
FIXTURE

cat > "$TMPROOT/exempt/skills/demo/SKILL.md" <<'FIXTURE'
---
name: demo
description: >
  Use for German requests such as Qualitaet pruefen, hoehere Reichweite,
  Uberblick erstellen. Trigger phrases are ASCII on purpose.
---

# Demo

Regular English body text.
FIXTURE

cat > "$TMPROOT/exempt/skills/demo/structural.md" <<'FIXTURE'
# Structural exemptions

Slug: predictive-maintenance-fur-alle
File: report-Qualitaet-2024.md
Enum: `LOESUNG`
URL: https://example.com/de/uber/uns
Path: skills/demo/uber/index.md
FIXTURE

cat > "$TMPROOT/exempt/skills/demo/english.md" <<'FIXTURE'
# English prose and image prompts

The coat has thick fur and the ride was booked with uber convenience.

```yaml
headline: "Ein Beispiel"
image_prompt: |
  A photograph of a factory floor, fur textures visible, shot from uber close range,
  with Qualitaet written nowhere in German prose.
```
FIXTURE

scan "$TMPROOT/exempt" > "$TMPROOT/exempt_findings.txt"

exempt_case() {
  case_id="$1"; needle="$2"; label="$3"
  hits=$(grep -F "$needle" "$TMPROOT/exempt_findings.txt" | tr '\n' ';' | sed 's/;*$//')
  if [ -z "$hits" ]; then
    pass "$case_id $label"
  else
    fail "$case_id $label — flagged: $hits"
  fi
}

exempt_case "X1" "web-brief-validation.md" "the rule statement naming the ASCII spellings is exempt"
exempt_case "X2" "agents/web.md" "the deliberate slug mapping is exempt"
exempt_case "X3" "SKILL.md" "frontmatter description trigger phrases are exempt"
exempt_case "X4" "structural.md" "slugs, filenames, ids, enum values and URLs are exempt"
exempt_case "X5" "english.md" "English prose and image-prompt scalars are exempt"

# -------------------------------------------------- G1 correct German that looks wrong
# Fixture-only on purpose: asserting real-corpus occurrence counts would stale the case
# out the moment someone legitimately edits the copy.
mkdir -p "$TMPROOT/lookalike"
cat > "$TMPROOT/lookalike/copy.md" <<'FIXTURE'
# Korrekte deutsche Begriffe

- Der Stillstand der Anlage wird gemeldet.
- Stillstandstag und Stillstandskosten werden erfasst.
- Eine Vorwarnung geht an den Betrieb.
- Die Prozesse und die Ersatzteil-Lieferzeit sind dokumentiert.
- Wettbewerbsfähigkeit und Führung bleiben korrekt geschrieben.
FIXTURE

lookalike_hits=$(scan "$TMPROOT/lookalike" | tr '\n' ';' | sed 's/;*$//')
if [ -z "$lookalike_hits" ]; then
  pass "G1 already-correct German that resembles a corrupted form is not flagged"
else
  fail "G1 correct German was flagged: $lookalike_hits"
fi

# -------------------------------------------------------------- C1 the tracked corpus
tracked_hits=$(wc -l < "$TMPROOT/tracked_findings.txt" | tr -d ' ')
if [ "$tracked_hits" -eq 0 ]; then
  pass "C1 the tracked corpus carries no enumerated ASCII-ified German token"
else
  fail "C1 $tracked_hits finding(s) in the tracked corpus: $(tr '\n' ';' < "$TMPROOT/tracked_findings.txt")"
fi

# ------------------------------------------------------- C2 exemption anchors resolve
anchor_problems=""
while IFS='|' read -r rel anchor; do
  [ -z "${rel:-}" ] && continue
  case "$rel" in \#*) continue ;; esac
  target="$SCAN_ROOT/$rel"
  if [ ! -f "$target" ]; then
    anchor_problems="$anchor_problems [$rel missing]"
  elif ! grep -qF "$anchor" "$target"; then
    anchor_problems="$anchor_problems [$rel no longer contains its anchor]"
  fi
done < "$TMPROOT/exemptions.txt"

if [ -z "$anchor_problems" ]; then
  pass "C2 every declared exemption anchor still resolves in the tracked corpus"
else
  fail "C2 stale exemption(s):$anchor_problems — update or remove the row, do not leave it dangling"
fi

# ------------------------------------------------------------ M1 executed negative case
if [ "${VISUAL_DE_ASCII_MUTANT:-0}" = "1" ]; then
  # This run IS the mutant child. Recursing here would not terminate.
  finish
fi

mkdir -p "$TMPROOT/mutant"
if (cd "$SCAN_ROOT" && find . -name '*.md' -print0 | while IFS= read -r -d '' rel; do
      mkdir -p "$TMPROOT/mutant/$(dirname "$rel")"
      cp "$rel" "$TMPROOT/mutant/$rel"
    done); then
  victim_rel="libraries/web-section-copywriting.md"
  if [ ! -f "$TMPROOT/mutant/$victim_rel" ]; then
    victim_rel=$(cd "$TMPROOT/mutant" && find . -name '*.md' | head -n 1 | sed 's|^\./||')
  fi
  victim_dropped=$(awk -F'|' '$3 == "dropped-vowel" && $4 == "plain" { print $1; exit }' "$TMPROOT/vocabulary.txt")
  victim_digraph=$(awk -F'|' '$3 == "digraph" { print $1; exit }' "$TMPROOT/vocabulary.txt")

  if [ -n "$victim_rel" ] && [ -n "$victim_dropped" ] && [ -n "$victim_digraph" ]; then
    printf '\n- Der Betrieb und die Anlage: %s und %s sind hier falsch geschrieben.\n' \
      "$victim_dropped" "$victim_digraph" >> "$TMPROOT/mutant/$victim_rel"

    mutant_out=$(VISUAL_DE_ASCII_MUTANT=1 VISUAL_DE_ASCII_ROOT="$TMPROOT/mutant" \
      bash "$HERE/$(basename "$0")" 2>&1)
    mutant_rc=$?

    mutant_c1=$(printf '%s\n' "$mutant_out" | grep '^FAIL: C1 ' || true)

    printf '%s\n' "$mutant_out" \
      | grep -E '^(ok|FAIL): ' \
      | awk '{print $2}' \
      | sort -u > "$TMPROOT/emitted_cases.txt"
    for case_id in $ALL_CASES; do
      [ "$case_id" = "M1" ] || echo "$case_id"
    done | sort -u > "$TMPROOT/expected_cases.txt"

    unregistered=$(comm -13 "$TMPROOT/expected_cases.txt" "$TMPROOT/emitted_cases.txt" | tr '\n' ' ' | sed 's/ *$//')
    unemitted=$(comm -23 "$TMPROOT/expected_cases.txt" "$TMPROOT/emitted_cases.txt" | tr '\n' ' ' | sed 's/ *$//')

    if [ "$mutant_rc" -eq 0 ]; then
      fail "M1 injecting corrupted German left the suite GREEN — the guard is vacuous"
    elif [ -n "$unregistered" ]; then
      fail "M1 case(s) emitted by a full run but missing from ALL_CASES: $unregistered — register them or bail_out will never report them"
    elif [ -n "$unemitted" ]; then
      fail "M1 case id(s) in ALL_CASES that a full run never emitted: $unemitted — the case was removed or renamed"
    elif [ -n "$mutant_c1" ] && printf '%s\n' "$mutant_c1" | grep -qF "$victim_dropped" \
         && printf '%s\n' "$mutant_c1" | grep -qF "$victim_digraph"; then
      pass "M1 injecting both corruption styles turns C1 red naming each token (child exit $mutant_rc); case registry matches the full run"
    else
      fail "M1 mutant run exited $mutant_rc, but not via C1 naming both injected tokens — got: $(printf '%s' "$mutant_out" | grep '^FAIL:' | tr '\n' ';')"
    fi
  else
    fail "M1 could not select a victim file or tokens to inject"
  fi
else
  fail "M1 could not copy the corpus into the sandbox"
fi

finish
