#!/usr/bin/env bash
#
# test-check-brief.sh — suite for cogni-workspace/scripts/check-brief.py.
#
# The real example briefs under libraries/ are the corpus: the slides example
# must come out clean, every sibling example must pass its core profile, and
# seven red mutants — each built in a mktemp -d by editing a copy of the slides
# example — must each trip exactly the check written to catch it. No mutant is
# committed: a deliberate corruption is not a corpus artifact.
#
# Mutation recipes (harness: ~/GitHub/dev/managed-service/cogni-service/scripts/
# mutation-check.sh, run with --root . --file cogni-workspace/scripts/check-brief.py
# --test 'bash cogni-workspace/tests/test-check-brief.sh'). Each expression
# disables one check; the case named must then print FAIL:
#
#   --expr 's{"Background", "Text-Color"}{"Text-Color"}'                  --case cb04-mutant-no-color-fields
#   --expr 's{if layout not in LAYOUT_ENUM:}{if False:}'                 --case cb05-mutant-layout-enum
#   --expr 's{CONSECUTIVE_RUN = 3}{CONSECUTIVE_RUN = 4}'                 --case cb06-mutant-deck-consecutive
#   --expr 's{"IS-Box": 15,}{"IS-Box": 150,}'                            --case cb07-mutant-density-idm
#   --expr 's{\("<sup>" in text or BARE_CITE_RE.search\(text\)\)}{False}' --case cb08-mutant-cite-zones
#   --expr 's{if headers < 2:}{if headers < 1:}'                         --case cb09-mutant-notes-sections
#   --expr 's{if refs_idx != len\(ctx.slides\) - 1:}{if False:}'         --case cb10-mutant-deck-references-last
#   --expr 's{ or BARE_CITE_RE.search\(text\)\)}{)}'                     --case cb23-mutant-bare-cite-in-heading
#
# Verdict at authoring: guard_verified for all eight — each search text occurs
# exactly once in check-brief.py and each mutant case went red under its recipe.
# cb23 is the bare-marker arm of cite-zones: removing only that arm keeps cb08
# green (the <sup> form is still caught) and turns cb23 red.

set -u

# The checker imports parse-brief.py via importlib; without this CPython writes
# a __pycache__/ into the plugin tree. That directory is an interpreter artifact
# this repo keeps out of the tree by policy — it is gitignored, and
# scripts/check-skill-spec.py prunes it from its own walk.
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CB="$ROOT/cogni-workspace/scripts/check-brief.py"
LIB="$ROOT/cogni-workspace/libraries"
EXB="$LIB/EXAMPLE_BRIEF.md"
F40="$ROOT/cogni-workspace/tests/fixtures/brief/unfenced-slides-4.0.md"
CHECKLISTS=(
  "$ROOT/cogni-workspace/libraries/presentation-brief-validation.md"
  "$ROOT/cogni-workspace/libraries/web-brief-validation.md"
  "$ROOT/cogni-workspace/libraries/storyboard-brief-validation.md"
  "$ROOT/cogni-workspace/libraries/infographic-brief-validation.md"
)

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# run <type> <brief> <outfile> -> sets RC
run() {
  python3 "$CB" --type "$1" "$2" > "$3" 2>/dev/null
  RC=$?
}

# has_fail <outfile> <check>  — exit 0 when the check appears with severity fail
has_fail() {
  python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
hits = [f for f in d["data"].get("findings", []) if f["check"] == sys.argv[2] and f["severity"] == "fail"]
sys.exit(0 if hits else 1)
PY
}

# mutate <python-expr-file> — copies EXB to $TMPROOT/mutant.md then applies the
# python transform read from stdin (a function body operating on `text`).
mutate() {
  python3 - "$EXB" "$TMPROOT/mutant.md" "$1" <<'PY'
import sys
src, dst, transform = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src, encoding="utf-8").read()
namespace = {"text": text}
exec(open(transform, encoding="utf-8").read(), namespace)
out = namespace["text"]
assert out != text, "transform did not change the brief"
open(dst, "w", encoding="utf-8").write(out)
PY
}

# --- cb01: the example brief is clean --------------------------------------
run slides "$EXB" "$TMPROOT/ex.json"
if [ "$RC" -eq 0 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/ex.json')); sys.exit(0 if d['success'] and d['data']['fails']==0 else 1)"; then
  pass "cb01-example-brief-clean"
else
  fail "cb01-example-brief-clean the v4.1 example brief has fails or a non-zero exit"
fi

# --- cb02: --list-checks names every check the issue enumerates, and each ---
# listed name is one the checker actually ran on the example.
python3 "$CB" --list-checks > "$TMPROOT/list.json" 2>/dev/null
if python3 - "$TMPROOT/list.json" "$TMPROOT/ex.json" <<'PY'
import json, sys
expected = """fm-core-keys fm-type-version fm-theme-path fm-confidence unit-fenced unit-numbering
layout-enum layout-required-fields layout-unknown-fields no-color-fields diagram-constraints
render-contract-section idm-labels-localized headline-length jargon-client-facing density-idm
density-bullets density-banner notes-sections notes-words notes-no-sup cite-format cite-sequence
cite-zones cite-references-complete deck-bookends deck-count deck-variety deck-consecutive
deck-prep-slides deck-references-last cta-summary-consistent metadata-block""".split()
listed = [c["name"] for c in json.load(open(sys.argv[1]))["data"]["checks"]]
ran = json.load(open(sys.argv[2]))["data"]["checks_run"]
missing = [n for n in expected if n not in listed]
not_run = [n for n in listed if n not in ran]
sys.exit(0 if len(expected) == 33 and not missing and not not_run else 1)
PY
then
  pass "cb02-list-checks-complete-and-run"
else
  fail "cb02-list-checks-complete-and-run a check name is missing from --list-checks or listed but never run"
fi

# --- cb03: the example only warns on the three advisory checks --------------
if python3 - "$TMPROOT/ex.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
checks = {f["check"] for f in d["data"]["findings"]}
sys.exit(0 if checks <= {"notes-words", "metadata-block", "deck-references-last"} else 1)
PY
then
  pass "cb03-example-warnings-are-advisory-only"
else
  fail "cb03-example-warnings-are-advisory-only a non-advisory check fired on the example"
fi

# --- cb04: Background: "#fff" injected -> no-color-fields --------------------
cat > "$TMPROOT/t04.py" <<'PY'
text = text.replace('Slide-Title: 42% der Überwachungssysteme sind veraltet\n',
                    'Slide-Title: 42% der Überwachungssysteme sind veraltet\nBackground: "#fff"\n', 1)
PY
mutate "$TMPROOT/t04.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m04.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m04.json" no-color-fields; then
  pass "cb04-mutant-no-color-fields"
else
  fail "cb04-mutant-no-color-fields an injected Background key was not reported"
fi

# --- cb05: misspelled layout -> layout-enum ---------------------------------
cat > "$TMPROOT/t05.py" <<'PY'
text = text.replace('Layout: stat-card-with-context\n', 'Layout: stat-card-with-contxt\n', 1)
PY
mutate "$TMPROOT/t05.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m05.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m05.json" layout-enum; then
  pass "cb05-mutant-layout-enum"
else
  fail "cb05-mutant-layout-enum a misspelled layout name was not reported"
fi

# --- cb06: three consecutive stat-card slides -> deck-consecutive -----------
cat > "$TMPROOT/t06.py" <<'PY'
text = text.replace('Layout: four-quadrants\nSlide-Kind: content\n',
                    'Layout: stat-card-with-context\nSlide-Kind: content\n', 1)
PY
mutate "$TMPROOT/t06.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m06.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m06.json" deck-consecutive; then
  pass "cb06-mutant-deck-consecutive"
else
  fail "cb06-mutant-deck-consecutive three consecutive slides on one layout were not reported"
fi

# --- cb07: 40-word IS box -> density-idm -------------------------------------
cat > "$TMPROOT/t07.py" <<'PY'
long = " ".join(["Wort{0}".format(i) for i in range(40)])
text = text.replace('  Text: Eine KI-gestützte Plattform für automatisierte Echtzeit-Überwachung von Bahninfrastruktur\n',
                    '  Text: ' + long + '\n', 1)
PY
mutate "$TMPROOT/t07.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m07.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m07.json" density-idm; then
  pass "cb07-mutant-density-idm"
else
  fail "cb07-mutant-density-idm a 40-word IS box was not reported"
fi

# --- cb08: <sup> marker in a headline -> cite-zones --------------------------
cat > "$TMPROOT/t08.py" <<'PY'
text = text.replace('## Slide 5: 42% der Überwachungssysteme sind veraltet\n',
                    '## Slide 5: 42% der Überwachungssysteme sind veraltet <sup>[2](https://www.bka.de/kriminalstatistik)</sup>\n', 1)
PY
mutate "$TMPROOT/t08.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m08.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m08.json" cite-zones; then
  pass "cb08-mutant-cite-zones"
else
  fail "cb08-mutant-cite-zones a citation marker in a headline was not reported"
fi

# --- cb23: bare [N](url) in a headline -> cite-zones ----------------------------
# The heading is the most important exclusion zone and cite-format skips it on
# purpose, so the bare spelling must be caught by cite-zones itself.
cat > "$TMPROOT/t23.py" <<'PY'
text = text.replace('## Slide 5: 42% der Überwachungssysteme sind veraltet\n',
                    '## Slide 5: 42% der Überwachungssysteme sind veraltet [2](https://www.bka.de/kriminalstatistik)\n', 1)
PY
mutate "$TMPROOT/t23.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m23.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m23.json" cite-zones; then
  pass "cb23-mutant-bare-cite-in-heading"
else
  fail "cb23-mutant-bare-cite-in-heading a bare [N](url) marker in a headline was not reported"
fi

# --- cb09: a >> notes header dropped -> notes-sections -----------------------
cat > "$TMPROOT/t09.py" <<'PY'
needle = '  >> WAS SIE WISSEN MÜSSEN\n\n  - Quelle: 688'
assert needle in text
text = text.replace(needle, '  WAS SIE WISSEN MÜSSEN\n\n  - Quelle: 688', 1)
PY
mutate "$TMPROOT/t09.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m09.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m09.json" notes-sections; then
  pass "cb09-mutant-notes-sections"
else
  fail "cb09-mutant-notes-sections a notes block missing its second section was not reported"
fi

# --- cb10: references slide moved before the closing slide ------------------
cat > "$TMPROOT/t10.py" <<'PY'
import re
head, rest = text.split('\n## Slide 12: ', 1)
closing, rest2 = rest.split('\n## Slide 13: ', 1)
refs, tail = rest2.split('\n## CTA Summary', 1)
# refs ends with the "**Notes**: The references slide..." paragraph and a ---; keep both blocks whole.
text = head + '\n## Slide 12: ' + refs + '\n## Slide 13: ' + closing + '\n## CTA Summary' + tail
PY
mutate "$TMPROOT/t10.py"; run slides "$TMPROOT/mutant.md" "$TMPROOT/m10.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/m10.json" deck-references-last; then
  pass "cb10-mutant-deck-references-last"
else
  fail "cb10-mutant-deck-references-last a references slide before the closing slide was not reported"
fi

# --- cb11..cb15: sibling profiles pass on their example briefs ---------------
sibling() {
  run "$1" "$LIB/$2" "$TMPROOT/sib.json"
  if [ "$RC" -eq 0 ]; then
    pass "$3"
  else
    fail "$3 $2 did not pass the $1 core profile"
  fi
}
sibling web EXAMPLE_WEB_BRIEF.md cb11-web-example-passes
sibling storyboard EXAMPLE_STORYBOARD_BRIEF.md cb12-storyboard-example-passes
sibling infographic EXAMPLE_INFOGRAPHIC_BRIEF.md cb13-infographic-example-passes
sibling infographic EXAMPLE_SKETCHNOTE_BRIEF.md cb14-sketchnote-example-passes
sibling infographic EXAMPLE_ECONOMIST_BRIEF.md cb15-economist-example-passes

# --- cb16: legacy 4.0 version accepted by the version pin -------------------
run slides "$F40" "$TMPROOT/f40.json"
if ! has_fail "$TMPROOT/f40.json" fm-type-version && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/f40.json')); sys.exit(0 if d['data']['version']=='4.0' else 1)"; then
  pass "cb16-legacy-40-version-accepted"
else
  fail "cb16-legacy-40-version-accepted the 4.0 fixture tripped fm-type-version"
fi

# --- cb17: a hand-drawn preset declaring 1.2 is a pairing the dispatcher refuses
cat > "$TMPROOT/t17.py" <<'PY'
text = text.replace('version: "1.1"\n', 'version: "1.2"\n', 1)
PY
python3 - "$LIB/EXAMPLE_SKETCHNOTE_BRIEF.md" "$TMPROOT/sk12.md" "$TMPROOT/t17.py" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
ns = {"text": text}; exec(open(sys.argv[3]).read(), ns)
assert ns["text"] != text
open(sys.argv[2], "w", encoding="utf-8").write(ns["text"])
PY
run infographic "$TMPROOT/sk12.md" "$TMPROOT/sk12.json"
if [ "$RC" -eq 1 ] && has_fail "$TMPROOT/sk12.json" fm-type-version; then
  pass "cb17-hand-drawn-preset-rejects-12"
else
  fail "cb17-hand-drawn-preset-rejects-12 a sketchnote brief declaring 1.2 was not reported"
fi

# --- cb18: missing file -> exit 2 with an envelope ---------------------------
run slides "$TMPROOT/does-not-exist.md" "$TMPROOT/nf.json"
if [ "$RC" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/nf.json')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
  pass "cb18-missing-brief-exits-2"
else
  fail "cb18-missing-brief-exits-2 a missing brief did not exit 2 with an error envelope"
fi

# --- cb19: unknown --type -> exit 2 -------------------------------------------
python3 "$CB" --type deck "$EXB" > "$TMPROOT/ut.json" 2>/dev/null
if [ $? -eq 2 ]; then
  pass "cb19-unknown-type-exits-2"
else
  fail "cb19-unknown-type-exits-2 an unknown --type did not exit 2"
fi

# --- cb20: --strict promotes the example's metadata warning to a failure -----
python3 "$CB" --type slides --strict "$EXB" > "$TMPROOT/strict.json" 2>/dev/null
if [ $? -eq 1 ] && has_fail "$TMPROOT/strict.json" metadata-block; then
  pass "cb20-strict-promotes-warnings"
else
  fail "cb20-strict-promotes-warnings --strict did not turn metadata-block into a failure"
fi

# --- cb21: stdlib only ---------------------------------------------------------
if python3 - "$CB" <<'PY'
import ast, sys
stdlib = set(sys.stdlib_module_names) if hasattr(sys, "stdlib_module_names") else set()
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
names = set()
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        names.update(a.name.split(".")[0] for a in node.names)
    elif isinstance(node, ast.ImportFrom) and node.module:
        names.add(node.module.split(".")[0])
bad = [n for n in names if stdlib and n not in stdlib]
sys.exit(0 if names and not bad else 1)
PY
then
  pass "cb21-stdlib-only-imports"
else
  fail "cb21-stdlib-only-imports check-brief.py imports something outside the standard library"
fi

# --- cb22: every check name a checklist references is one the checker lists --
if python3 - "$TMPROOT/list.json" "${CHECKLISTS[@]}" <<'PY'
import json, re, sys
listed = {c["name"] for c in json.load(open(sys.argv[1]))["data"]["checks"]}
pattern = re.compile(r"`((?:fm|unit|layout|no|diagram|render|idm|headline|jargon|density|notes|cite|deck|cta|metadata)-[a-z-]+)`")
unknown = []
for path in sys.argv[2:]:
    for name in pattern.findall(open(path, encoding="utf-8").read()):
        if name not in listed:
            unknown.append((path, name))
for path, name in unknown:
    print("unknown check", name, "in", path)
sys.exit(0 if not unknown else 1)
PY
then
  pass "cb22-checklists-name-only-known-checks"
else
  fail "cb22-checklists-name-only-known-checks a checklist names a check the script does not run"
fi

exit "$failures"
