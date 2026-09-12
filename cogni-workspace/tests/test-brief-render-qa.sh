#!/usr/bin/env bash
#
# test-brief-render-qa.sh — suite for cogni-workspace/scripts/brief-render-qa.py.
#
# Builds, in a mktemp -d, a two-slide 4.1 brief and a matching minimal .pptx —
# content types, package rels, presentation part, two slide parts, two notes
# parts wired through slide rels, and one external hyperlink rel — with the
# standard library's zipfile, so no renderer and no LibreOffice is needed. The
# clean deck must report nothing missing; a mutant deck with one text run removed
# must list that run in text_missing[]; a mutant with a notes paragraph removed
# must list it in notes_missing[]. Foreign tools are never invoked here, so no
# assertion depends on a localized message.
#
# Mutation recipes (harness: ~/GitHub/dev/managed-service/cogni-service/scripts/
# mutation-check.sh, run with --root . --file cogni-workspace/scripts/brief-render-qa.py
# --test 'bash cogni-workspace/tests/test-brief-render-qa.sh'):
#
#   --expr 's{text_missing = \[e for e in expected_text if e\["text"\] not in actual\["text"\]\]}{text_missing = []}'
#       --case rq03-mutant-text-run-removed
#   --expr 's{if not model\["slides"\] or \(not expected_text and not expected_notes\):}{if False:}'
#       --case rq08-mutant-empty-brief-not-refused
#
# Verdict at authoring: guard_verified for both — each search text occurs exactly
# once. The first makes the QA blind to dropped text, so rq03 goes red; the
# second removes the empty-expectation refusal in one line (both arms sit on it
# on purpose, so no second guard can keep the case green), and rq08, rq09 and
# rq10 all go red.

set -u
export PYTHONDONTWRITEBYTECODE=1

failures=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
QA="$ROOT/cogni-workspace/scripts/brief-render-qa.py"

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# --- the brief ----------------------------------------------------------------
cat > "$TMPROOT/brief.md" <<'MD'
---
type: presentation-brief
version: "4.1"
customer: "Fixture GmbH"
provider: "Test AG"
language: de
generated: "2026-09-05"
arc_type: problem-solution
governing_thought: "Die Zustandsüberwachung muss messbar größer werden."
confidence_score: 0.9
max_slides: 12
slides: 2
design:
  register: sachlich
  speaker_notes: full-script
  imagery: none
key_figures:
  - "688 Vorfälle"
---

# Rendering-Vertrag

- Texte sind eingefroren.
- Notizen vollständig.
- Zitate als Hyperlinks.
- Gestaltung nur aus dem Theme.
- Layout ist eine Inhaltsform.

## Slide 1: Der Pilotbetrieb ist abgeschlossen

```yaml
Layout: title-slide
Slide-Kind: content
intent:
  role: hook
  emphasis: none
visual:
  kind: none
Title: Zustandsüberwachung im Pilotbetrieb
Subtitle: Ergebnisse aus drei Standorten
Metadata: Fixture GmbH | Test AG | September 2026
```

## Slide 2: 688 Vorfälle pro Jahr sind vermeidbar

```yaml
Layout: stat-card-with-context
Slide-Kind: content
intent:
  role: problem
  emphasis: none
visual:
  kind: stat
Slide-Title: 688 Vorfälle pro Jahr sind vermeidbar
Hero-Stat-Box:
  Number: 688
  Label: Vorfälle pro Jahr
  Icon: shield
Context-Box:
  Headline: Warum manuelle Kontrolle versagt
  Bullets:
    - Personal deckt nicht alle Bereiche ab <sup>[1](https://example.invalid/bericht)</sup>
    - Ereignisse werden zu spät erkannt
Bottom-Banner:
  Text: Deutschland führt die Statistik an
Speaker-Notes: |
  >> WAS SIE SAGEN
  [Einstieg]: "Fragen Sie nach der Zahl."
  >> WAS SIE WISSEN MÜSSEN
  - Quelle: [Bericht](https://example.invalid/bericht)
Source: "[Bericht 2026](https://example.invalid/bericht)"
```
MD

# --- the deck builder ----------------------------------------------------------
cat > "$TMPROOT/build_deck.py" <<'PY'
"""Build a minimal .pptx with zipfile. argv: out.pptx [drop-text] [drop-notes]"""
import sys, zipfile

out = sys.argv[1]
drop_text = "drop-text" in sys.argv
drop_notes = "drop-notes" in sys.argv

A = 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
P = 'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"'
R = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'

def run(text, link=None):
    hl = '<a:rPr><a:hlinkClick r:id="{0}"/></a:rPr>'.format(link) if link else ""
    return "<a:r>{0}<a:t>{1}</a:t></a:r>".format(hl, text)

def para(*runs):
    return "<a:p>" + "".join(runs) + "</a:p>"

def slide(paras):
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<p:sld {P} {A} {R}><p:cSld><p:spTree><p:sp><p:txBody>{body}</p:txBody></p:sp>'
            '</p:spTree></p:cSld></p:sld>').format(P=P, A=A, R=R, body="".join(paras))

def notes(paras):
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<p:notes {P} {A} {R}><p:cSld><p:spTree><p:sp><p:txBody>{body}</p:txBody></p:sp>'
            '</p:spTree></p:cSld></p:notes>').format(P=P, A=A, R=R, body="".join(paras))

REL = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/'
PKG = 'http://schemas.openxmlformats.org/package/2006/relationships'

def rels(entries):
    body = "".join('<Relationship Id="{0}" Type="{1}" Target="{2}"{3}/>'.format(
        i, t, g, ' TargetMode="External"' if ext else "") for i, t, g, ext in entries)
    return '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="{0}">{1}</Relationships>'.format(PKG, body)

slide1 = slide([para(run("Zustandsüberwachung im Pilotbetrieb")),
                para(run("Ergebnisse aus drei Standorten")),
                para(run("Fixture GmbH | Test AG | September 2026"))])
s2 = [para(run("688 Vorfälle pro Jahr sind vermeidbar")),
      para(run("688")), para(run("Vorfälle pro Jahr")),
      para(run("Warum manuelle Kontrolle versagt")),
      para(run("Personal deckt nicht alle Bereiche ab "), run("1", link="rId2")),
      para(run("Deutschland führt die Statistik an"))]
if not drop_text:
    s2.insert(5, para(run("Ereignisse werden zu spät erkannt")))
slide2 = slide(s2)

n1 = notes([para(run("1"))])
n2_paras = [para(run(">> WAS SIE SAGEN")),
            para(run('[Einstieg]: "Fragen Sie nach der Zahl."')),
            para(run(">> WAS SIE WISSEN MÜSSEN"))]
if not drop_notes:
    n2_paras.append(para(run("- Quelle: [Bericht](https://example.invalid/bericht)")))
n2 = notes(n2_paras)

ct = ('<?xml version="1.0" encoding="UTF-8"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>'
      '<Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
      '<Override PartName="/ppt/slides/slide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
      '<Override PartName="/ppt/notesSlides/notesSlide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"/>'
      '<Override PartName="/ppt/notesSlides/notesSlide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"/>'
      '</Types>')
pres = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:presentation {P} {R}><p:sldIdLst><p:sldId id="256" r:id="rId1"/><p:sldId id="257" r:id="rId2"/></p:sldIdLst>'
        '</p:presentation>').format(P=P, R=R)

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", ct)
    z.writestr("_rels/.rels", rels([("rId1", REL + "officeDocument", "ppt/presentation.xml", False)]))
    z.writestr("ppt/presentation.xml", pres)
    z.writestr("ppt/_rels/presentation.xml.rels", rels([
        ("rId1", REL + "slide", "slides/slide1.xml", False),
        ("rId2", REL + "slide", "slides/slide2.xml", False)]))
    z.writestr("ppt/slides/slide1.xml", slide1)
    z.writestr("ppt/slides/slide2.xml", slide2)
    z.writestr("ppt/slides/_rels/slide1.xml.rels", rels([
        ("rId1", REL + "notesSlide", "../notesSlides/notesSlide1.xml", False)]))
    z.writestr("ppt/slides/_rels/slide2.xml.rels", rels([
        ("rId1", REL + "notesSlide", "../notesSlides/notesSlide2.xml", False),
        ("rId2", REL + "hyperlink", "https://example.invalid/bericht", True)]))
    z.writestr("ppt/notesSlides/notesSlide1.xml", n1)
    z.writestr("ppt/notesSlides/notesSlide2.xml", n2)
PY

python3 "$TMPROOT/build_deck.py" "$TMPROOT/clean.pptx"
python3 "$TMPROOT/build_deck.py" "$TMPROOT/no-text.pptx" drop-text
python3 "$TMPROOT/build_deck.py" "$TMPROOT/no-notes.pptx" drop-notes

# run <pptx> <out> -> RC
run() { python3 "$QA" --brief "$TMPROOT/brief.md" --pptx "$1" > "$2" 2>/dev/null; RC=$?; }

# --- rq01: the clean deck round-trips with nothing missing -------------------
run "$TMPROOT/clean.pptx" "$TMPROOT/clean.json"
if [ "$RC" -eq 0 ] && python3 - "$TMPROOT/clean.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["data"]
ok = (d["slide_count"] == 2 and not d["text_missing"] and not d["notes_missing"]
      and d["text_expected"] >= 8 and d["notes_expected"] == 4)
sys.exit(0 if ok else 1)
PY
then
  pass "rq01-clean-deck-nothing-missing"
else
  fail "rq01-clean-deck-nothing-missing the clean fixture deck reported missing text or notes"
fi

# --- rq02: links are counted from the slide rels ----------------------------
if python3 - "$TMPROOT/clean.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["data"]
sys.exit(0 if d["links_expected"] == 1 and d["links_found"] == 1 and not d["links_missing"] else 1)
PY
then
  pass "rq02-hyperlink-rel-counted"
else
  fail "rq02-hyperlink-rel-counted the external hyperlink rel was not counted as a found link"
fi

# --- rq03: a removed text run is reported in text_missing[] ------------------
run "$TMPROOT/no-text.pptx" "$TMPROOT/no-text.json"
if [ "$RC" -eq 1 ] && python3 - "$TMPROOT/no-text.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["data"]
missing = [m["text"] for m in d["text_missing"]]
sys.exit(0 if missing == ["Ereignisse werden zu spät erkannt"] and not d["notes_missing"] else 1)
PY
then
  pass "rq03-mutant-text-run-removed"
else
  fail "rq03-mutant-text-run-removed a dropped text run was not the one and only text_missing entry"
fi

# --- rq04: a removed notes paragraph is reported in notes_missing[] ----------
run "$TMPROOT/no-notes.pptx" "$TMPROOT/no-notes.json"
if [ "$RC" -eq 1 ] && python3 - "$TMPROOT/no-notes.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["data"]
missing = [m["line"] for m in d["notes_missing"]]
sys.exit(0 if len(missing) == 1 and missing[0].startswith("- Quelle:") and not d["text_missing"] else 1)
PY
then
  pass "rq04-mutant-notes-line-removed"
else
  fail "rq04-mutant-notes-line-removed a dropped notes paragraph was not the one and only notes_missing entry"
fi

# --- rq05: a missing deck exits 2 with an envelope ---------------------------
run "$TMPROOT/absent.pptx" "$TMPROOT/absent.json"
if [ "$RC" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/absent.json')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
  pass "rq05-missing-deck-exits-2"
else
  fail "rq05-missing-deck-exits-2 a missing deck did not exit 2 with an error envelope"
fi

# --- rq06: a file that is not a zip exits 2 ----------------------------------
printf 'not a deck\n' > "$TMPROOT/garbage.pptx"
run "$TMPROOT/garbage.pptx" "$TMPROOT/garbage.json"
if [ "$RC" -eq 2 ]; then
  pass "rq06-non-zip-exits-2"
else
  fail "rq06-non-zip-exits-2 a non-zip file did not exit 2"
fi

# --- rq08: a brief that yields no slides is refused, not passed ----------------
# A web brief handed in as --brief parses to zero slides without raising; the QA
# must refuse to grade rather than compare an empty expectation and report clean.
python3 "$QA" --brief "$ROOT/cogni-workspace/libraries/EXAMPLE_WEB_BRIEF.md" --pptx "$TMPROOT/clean.pptx" > "$TMPROOT/web.json" 2>/dev/null
rc=$?
if [ "$rc" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/web.json')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
  pass "rq08-mutant-empty-brief-not-refused"
else
  fail "rq08-mutant-empty-brief-not-refused a web brief as --brief was graded instead of refused (rc=$rc)"
fi

# --- rq09: a presentation brief with its slide sections deleted is refused too --
python3 - "$TMPROOT/brief.md" "$TMPROOT/no-slides.md" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
head = text.split("\n## Slide 1: ", 1)[0]
assert "## Slide" not in head
open(sys.argv[2], "w", encoding="utf-8").write(head + "\n")
PY
python3 "$QA" --brief "$TMPROOT/no-slides.md" --pptx "$TMPROOT/clean.pptx" > "$TMPROOT/noslides.json" 2>/dev/null
rc=$?
if [ "$rc" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/noslides.json')); sys.exit(0 if d['success'] is False and d['error'] else 1)"; then
  pass "rq09-slideless-brief-refused"
else
  fail "rq09-slideless-brief-refused a presentation brief with no slide sections was graded instead of refused (rc=$rc)"
fi

# --- rq10: slides present but nothing gradeable (all internal-prep, skipped) ---
# Exercises the second arm of the refusal on its own: the brief parses to one
# slide, but --skip-internal leaves no text and no notes to expect.
python3 - "$TMPROOT/brief.md" "$TMPROOT/all-internal.md" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
head, rest = text.split("\n## Slide 1: ", 1)
slide1 = "\n## Slide 1: " + rest.split("\n## Slide 2: ", 1)[0]
slide1 = slide1.replace("Slide-Kind: content", "Slide-Kind: internal-prep", 1)
assert "internal-prep" in slide1
open(sys.argv[2], "w", encoding="utf-8").write(head + slide1)
PY
python3 "$QA" --brief "$TMPROOT/all-internal.md" --pptx "$TMPROOT/clean.pptx" --skip-internal > "$TMPROOT/allint.json" 2>/dev/null
rc=$?
if [ "$rc" -eq 2 ] && python3 -c "
import json,sys; d=json.load(open('$TMPROOT/allint.json')); sys.exit(0 if d['success'] is False and 'no on-slide text' in d['error'] else 1)"; then
  pass "rq10-nothing-gradeable-refused"
else
  fail "rq10-nothing-gradeable-refused a brief whose every slide was skipped was graded instead of refused (rc=$rc)"
fi

# --- rq07: stdlib only ---------------------------------------------------------
if python3 - "$QA" <<'PY'
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
  pass "rq07-stdlib-only-imports"
else
  fail "rq07-stdlib-only-imports brief-render-qa.py imports something outside the standard library"
fi

exit "$failures"
