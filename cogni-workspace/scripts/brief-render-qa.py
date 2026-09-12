#!/usr/bin/env python3
"""brief-render-qa.py — round-trip a rendered .pptx against the presentation brief it came from.

WHY THIS EXISTS. Nothing else proves a deck still says what the brief says. A
renderer that silently dropped a slide's bullets or truncated its speaker notes
reports success, and the Rendering Contract's first two clauses — copy is
frozen, notes travel complete — are exactly the ones no file validator checks.
This script reads the deck's own XML and asks, leaf by leaf, whether the brief's
on-slide copy and notes are in it.

WHAT IT READS. `ppt/slides/slide*.xml` text runs (`a:t`), each slide's notes
part through its relationships (`ppt/slides/_rels/slide*.xml.rels`, relationship
type ending in `/notesSlide`), and hyperlink targets from the same rels. Stdlib
`zipfile` and `xml.etree` only — a .pptx is a zip of XML and needs no library.

WHAT COUNTS AS EXPECTED. Every string or numeric leaf of a slide's fields except
the ones a slide does not display: `Speaker-Notes` (checked separately),
`Source` (a footer whose URL is checked as a link), `Diagram` (rendered as
shapes), `Layout`, `Slide-Kind`, `intent`, `visual`, `cta` and `Icon`. Citation
markers are stripped before matching, whitespace is collapsed, and a leaf
matches when it appears anywhere in the deck's text — decks may reorder or
merge runs, so matching is deck-wide rather than slide-bound. Notes are matched
line by line against the union of all notes parts for the same reason.

Usage:
    brief-render-qa.py --brief <presentation-brief.md> --pptx <deck.pptx> [--skip-internal]

Exit 0 when nothing is missing, 1 when any text or notes line is missing, 2 when
the brief or deck cannot be read. Always prints one {"success", "data", "error"}
object and never a traceback. `links_missing[]` is reported but does not by
itself set the exit code — the text and notes clauses are the hard ones.
"""

import argparse
import importlib.util
import json
import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

NS_A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
NS_R = "{http://schemas.openxmlformats.org/package/2006/relationships}"
SUP_RE = re.compile(r"<sup>\[(\d+)\]\(([^)]+)\)</sup>")
URL_RE = re.compile(r"\((https?://[^)]+)\)")
SKIP_TOP = frozenset(("Speaker-Notes", "Source", "Diagram", "Layout", "Slide-Kind",
                      "intent", "visual", "cta"))
SKIP_LEAF_KEYS = frozenset(("Icon",))


class QAError(Exception):
    """The brief or the deck cannot be read — exit 2, not a finding."""


def _load_parse_brief():
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "parse-brief.py")
    if not os.path.isfile(path):
        raise QAError("cannot find parse-brief.py next to brief-render-qa.py")
    spec = importlib.util.spec_from_file_location("_parse_brief", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _norm(text):
    return re.sub(r"\s+", " ", SUP_RE.sub("", str(text))).strip()


def _leaves(value, path=()):
    if isinstance(value, dict):
        for key, sub in value.items():
            yield from _leaves(sub, path + (str(key),))
    elif isinstance(value, list):
        for index, sub in enumerate(value):
            yield from _leaves(sub, path + (str(index),))
    elif isinstance(value, (str, int, float)) and not isinstance(value, bool):
        yield path, value


def expected_from_brief(model, skip_internal):
    """Return (text_leaves, notes_lines, links) the deck must carry."""
    text_leaves, notes_lines, links = [], [], set()
    for slide in model["slides"]:
        if skip_internal and slide["slide_kind"] == "internal-prep":
            continue
        number = slide["number"]
        for path, value in _leaves(slide["fields"]):
            if path[0] in SKIP_TOP or path[-1] in SKIP_LEAF_KEYS:
                continue
            text = _norm(value)
            if text:
                text_leaves.append({"slide": number, "field": ".".join(path), "text": text})
        notes = slide["speaker_notes"]
        if isinstance(notes, str):
            for line in notes.splitlines():
                text = _norm(line)
                if text:
                    notes_lines.append({"slide": number, "line": text})
        for pair in slide["citations"]:
            links.add(pair["url"])
        source = slide["source"]
        if isinstance(source, str):
            links.update(URL_RE.findall(source))
    return text_leaves, notes_lines, sorted(links)


def _slide_parts(archive):
    names = archive.namelist()
    slides = sorted(
        (n for n in names if re.match(r"^ppt/slides/slide\d+\.xml$", n)),
        key=lambda n: int(re.search(r"(\d+)\.xml$", n).group(1)))
    return slides


def _text_of(archive, part):
    try:
        root = ET.fromstring(archive.read(part))
    except ET.ParseError as exc:
        raise QAError("cannot parse {0}: {1}".format(part, exc))
    paragraphs = []
    for para in root.iter(NS_A + "p"):
        runs = [t.text or "" for t in para.iter(NS_A + "t")]
        if runs:
            paragraphs.append("".join(runs))
    return paragraphs


def _rels_of(archive, part):
    directory, name = part.rsplit("/", 1)
    rels_part = "{0}/_rels/{1}.rels".format(directory, name)
    if rels_part not in archive.namelist():
        return []
    root = ET.fromstring(archive.read(rels_part))
    return [(rel.get("Type", ""), rel.get("Target", ""), rel.get("TargetMode", ""))
            for rel in root.iter(NS_R + "Relationship")]


def actual_from_pptx(path):
    try:
        archive = zipfile.ZipFile(path)
    except (OSError, zipfile.BadZipFile) as exc:
        raise QAError("cannot open deck: {0}".format(exc))
    with archive:
        slides = _slide_parts(archive)
        if not slides:
            raise QAError("deck carries no ppt/slides/slide*.xml part")
        texts, notes, links = [], [], set()
        for part in slides:
            texts.extend(_text_of(archive, part))
            for rel_type, target, mode in _rels_of(archive, part):
                if rel_type.endswith("/hyperlink") and mode == "External":
                    links.add(target)
                elif rel_type.endswith("/notesSlide"):
                    notes_part = os.path.normpath(os.path.join("ppt/slides", target)).replace("\\", "/")
                    if notes_part in archive.namelist():
                        notes.extend(_text_of(archive, notes_part))
        return {
            "slide_count": len(slides),
            "text": _norm("\n".join(texts)),
            "notes": _norm("\n".join(notes)),
            "links": links,
        }


def compare(expected_text, expected_notes, expected_links, actual):
    text_missing = [e for e in expected_text if e["text"] not in actual["text"]]
    notes_missing = [e for e in expected_notes if e["line"] not in actual["notes"]]
    links_missing = [u for u in expected_links if u not in actual["links"]]
    return {
        "slide_count": actual["slide_count"],
        "text_expected": len(expected_text),
        "text_missing": text_missing,
        "notes_expected": len(expected_notes),
        "notes_missing": notes_missing,
        "links_expected": len(expected_links),
        "links_found": len([u for u in expected_links if u in actual["links"]]),
        "links_missing": links_missing,
    }


def emit(success, data=None, error="", code=0):
    print(json.dumps({"success": success, "data": data or {}, "error": error}, ensure_ascii=False))
    return code


class _EnvelopeParser(argparse.ArgumentParser):
    def error(self, message):
        emit(False, None, "argument error: {0}".format(message), 2)
        raise SystemExit(2)


def main():
    parser = _EnvelopeParser(description="Round-trip a rendered .pptx against its brief.")
    parser.add_argument("--brief", required=True, help="path to presentation-brief.md")
    parser.add_argument("--pptx", required=True, help="path to the rendered deck")
    parser.add_argument("--skip-internal", action="store_true",
                        help="do not expect Slide-Kind: internal-prep slides in the deck")
    args = parser.parse_args()
    try:
        pb = _load_parse_brief()
        try:
            model = pb.parse_brief(args.brief)
        except pb.BriefError as exc:
            raise QAError("cannot parse brief: {0}".format(exc))
        except OSError as exc:
            raise QAError("cannot read brief: {0}".format(exc))
        # A brief that yields nothing to expect cannot be graded — a web or
        # infographic brief handed in by mistake, or a presentation brief whose
        # slide sections are missing, parses to zero slides without raising.
        # Passing an empty expectation against any deck would be the "gate that
        # passes when its input is absent" this script exists to close.
        expected_text, expected_notes, expected_links = expected_from_brief(model, args.skip_internal)
        if not model["slides"] or (not expected_text and not expected_notes):
            raise QAError(
                "brief yields no `## Slide N:` sections — nothing to grade the deck against"
                if not model["slides"] else
                "brief yields no on-slide text and no notes to grade the deck against")
        actual = actual_from_pptx(args.pptx)
        report = compare(expected_text, expected_notes, expected_links, actual)
    except QAError as exc:
        return emit(False, None, str(exc), 2)
    except Exception as exc:  # never surface a traceback
        return emit(False, None, "qa error: {0}".format(exc), 2)
    clean = not report["text_missing"] and not report["notes_missing"]
    return emit(clean, report, "", 0 if clean else 1)


if __name__ == "__main__":
    sys.exit(main())
