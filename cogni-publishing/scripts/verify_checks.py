"""Independent verification checks for design-verify. Stdlib only.

Every expectation here comes from the frozen inputs — the normalized brief, the composition, the
pattern library, the theme's tokens and the per-target capability declaration — never from the
renderer. A delivered page is read with the plugin's html.parser reader and a delivered deck with its
zipfile/ElementTree reader; this module imports no adapter, so a damaged writer cannot agree with
itself, and it takes no expectation from the render-time checkers either. Each check returns findings
`{code, check, class, unit, message}`; `class` names one of the critical classes or is null. The
report adds `target` and `brand` to every finding.

references/design-verify.md is the normative description of the families, the critical classes, the
capability declaration, the report, the review record, the specimen index and the proof manifest.
"""

import io
import json
import re
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

import pptx_checks as deck
import render_checks as page
import render_core as core

contrast = core.load_script("cogni_publishing_contrast", "check-contrast.py")

REPORT_TYPE = "verification-report"
REPORT_VERSION = "1"
# The critical classes. An open finding of any of them fails a verification outright; so does every other
# open finding. No verdict here is an average, a rate or a threshold over findings.
CRITICAL_CLASSES = ("clipping", "overlap", "missing-glyph", "unreadable-text", "misleading-encoding")
# Render-time fidelity codes that are, in substance, one of the critical classes.
FIDELITY_CLASSES = {
    "fit-overflow": "clipping", "text-outside-frame": "clipping", "truncating-css": "clipping",
    "hidden-copy": "clipping", "readability": "unreadable-text", "autofit": "unreadable-text",
    "chart-semantics": "misleading-encoding",
}
FAMILIES = ("copy", "data", "sources", "evidence", "notes", "order")
EMU_PER_PX = 9525.0
CLIP_TOLERANCE_PX = 1.0
OVERLAP_TOLERANCE_PX = 1.0
GLYPH_CATEGORIES = ("Cn", "Co", "Cs", "Cc")
ALLOWED_CONTROLS = ("\n", "\t")
UNQUALIFIED_KEYS = ("verdict", "quality", "rating", "score", "overall", "grade", "pass_rate", "average",
                    "threshold", "approved")
SEVERITIES = ("critical", "major", "minor", "note")
EXACT_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
SHA = re.compile(r"^sha256:[0-9a-f]{64}$")


def finding(code, check, unit, message, klass=None):
    return {"code": code, "check": check, "class": klass, "unit": unit, "message": message}


def sha256(data):
    return core.sha256_bytes(data)


# --- the three one-line predicates. Each is the single place its property is decided, so a recorded
# mutation of its body turns exactly its suite case red: keep each body on one line, occurring once. ---

def copy_preserved(frozen_text, found_text):
    return found_text == frozen_text


def link_preserved(source_url, target_url):
    return target_url == source_url


def clipped(needed_px, available_px):
    return needed_px > available_px + CLIP_TOLERANCE_PX


# --- expectations from the frozen inputs ---------------------------------------------------------

class Frozen:
    """What each family of the frozen input holds, keyed so a page and a deck compare against the same
    rows. Nothing here reads a rendered artifact."""

    def __init__(self, brief, composition):
        self.content = core.Content(brief)
        self.units = [unit["id"] for unit in composition["units"]]
        self.copy, self.evidence, self.data, self.links = [], [], [], []
        self.notes = {unit_id: [] for unit_id in self.units}
        document = brief.get("document") or {}
        for key in ("title", "subtitle"):
            if isinstance(document.get(key), str) and document[key]:
                self.copy.append(("document", f"document#{key}", document[key]))
        for unit in composition["units"]:
            for binding in unit.get("bindings", []):
                value = self.content.field(binding["record_ref"], binding["field"])
                key = f"{binding['record_ref']}#{binding['field']}"
                items = value if isinstance(value, list) else [value]
                if binding["slot"] in core.ASIDE_SLOTS:
                    self.notes[unit["id"]].extend(items)
                    continue
                rows = self.evidence if binding["field"] == "evidence_status" else self.copy
                if isinstance(value, list):
                    rows.extend((unit["id"], f"{key}#{i}", item) for i, item in enumerate(value))
                else:
                    rows.append((unit["id"], key, value))
            for point in unit.get("data_bindings", []):
                item = self.content.data(point["data_ref"])
                literal = core.number_text(item["value"])
                self.data.append({"unit": unit["id"], "id": item["id"], "label": item["label"], "literal": literal,
                                  "measure": item["unit"], "value_text": f"{literal} {item['unit']}",
                                  "value": float(item["value"])})
            for ref in list(unit.get("source_refs", [])) + list(unit.get("register_refs", [])):
                url = self.content.sources[ref].get("url")
                if isinstance(url, str) and url:
                    self.links.append((unit["id"], ref, url))
        if self.units:
            last = self.units[-1]
            self.notes[last] = self.notes[last] + [self.content.index.trailer[b["index"]]
                                                   for b in composition.get("document_bindings", [])]
        self.links = list(dict.fromkeys(self.links))

    def carried(self):
        return {"copy": len(self.copy), "data": len(self.data), "sources": len(self.links),
                "evidence": len(self.evidence), "notes": sum(len(v) for v in self.notes.values()),
                "order": len(self.units)}

    def strings(self):
        """Every frozen string a delivered artifact must show, for the glyph check."""
        rows = [text for _, _, text in self.copy + self.evidence]
        rows += [point["label"] for point in self.data] + [point["value_text"] for point in self.data]
        rows += [text for texts in self.notes.values() for text in texts]
        return rows


# --- what a delivered artifact shows, family by family --------------------------------------------

class PageView:
    """The families a rendered page shows, read with the plugin's html.parser reader."""

    target = "html"

    def __init__(self, data):
        self.root = page.parse(data.decode("utf-8"))
        self.sections = {node.attrs["data-unit"]: node for node in page.unit_sections(self.root)}
        self.order = [node.attrs["data-unit"] for node in page.unit_sections(self.root)]
        self.copy, self.values = {}, {}
        for node in self.root.iter():
            if "data-copy" in node.attrs:
                self.copy.setdefault(node.attrs["data-copy"], []).append(node.text())
            if "data-value" in node.attrs:
                self.values.setdefault(node.attrs["data-value"], []).append(node.text())

    def texts(self, key):
        return self.copy.get(key, [])

    def unit_notes(self, unit):
        found = []
        section = self.sections.get(unit)
        if section is not None:
            for node in section.iter():
                if node.tag == "aside" and "slot-notes" in node.classes():
                    found += [child.text() for child in node.iter() if "data-copy" in child.attrs]
        if self.order and unit == self.order[-1]:
            for node in self.root.iter():
                if "trailer-notes" in node.classes():
                    found += [child.text() for child in node.iter() if "data-copy" in child.attrs]
        return found

    def unit_links(self, unit):
        section = self.sections.get(unit)
        return [node.attrs.get("href") for node in section.iter() if node.tag == "a"] if section is not None else []

    def all_text(self):
        return [text for texts in self.copy.values() for text in texts] + \
               [text for texts in self.values.values() for text in texts]


class DeckView:
    """The families a rendered deck shows, read with the plugin's zipfile/ElementTree reader."""

    target = "pptx"

    def __init__(self, data):
        self.pkg = deck.Package(data)
        _, parts, self.extent = deck.slide_parts(self.pkg)
        self.slides = [deck.Slide(self.pkg, part) for part in parts]
        self.by_name = {slide.name: slide for slide in self.slides}
        self.order = [slide.name for slide in self.slides if slide.name != "document"]
        self.copy, self.values = {}, {}
        for slide in self.slides:
            for name, shapes in slide.named.items():
                for shape in shapes:
                    paras = deck.texts(shape)
                    if name.startswith("copy:"):
                        key = name[len("copy:"):]
                        if len(paras) == 1:
                            self.copy.setdefault(key, []).append(paras[0])
                        for i, text in enumerate(paras):
                            self.copy.setdefault(f"{key}#{i}", []).append(text)
                    elif name.startswith("value:"):
                        self.values.setdefault(name[len("value:"):], []).append("\n".join(paras))

    def texts(self, key):
        return self.copy.get(key, [])

    def unit_notes(self, unit):
        slide = self.by_name.get(unit)
        return deck.texts(slide.notes_body) if slide is not None and slide.notes_body is not None else []

    def unit_links(self, unit):
        slide = self.by_name.get(unit)
        if slide is None:
            return []
        links = []
        for rels, shapes in ((slide.rels, slide.shapes), (slide.notes_rels, [slide.notes_body])):
            for shape in shapes:
                if shape is None:
                    continue
                for _, runs in deck.paragraphs(shape):
                    for _, rpr in runs:
                        link = deck.link_of(rpr, rels)
                        if link is not None:
                            links.append(link[1])
        return links

    def chart(self, unit):
        """(frame, chart part tree, series name, categories, values, workbook cells) of a unit's native
        chart, or None when the unit's slide carries no native chart."""
        slide = self.by_name.get(unit)
        if slide is None:
            return None
        for shape in slide.shapes:
            if deck.kind_of(shape) != "chart":
                continue
            node = shape.find(f".//{deck.C}chart")
            rel = slide.rels.get(node.get(deck.R + "id")) if node is not None else None
            if rel is None or rel["resolved"] not in self.pkg.parts:
                return None
            tree = self.pkg.tree(rel["resolved"])
            ser = tree.find(f".//{deck.C}barChart/{deck.C}ser")
            if ser is None:
                return None
            name = [n.text or "" for n in ser.findall(f"{deck.C}tx//{deck.C}v")]
            cats = [n.text or "" for n in ser.findall(f"{deck.C}cat//{deck.C}pt/{deck.C}v")]
            vals = [n.text or "" for n in ser.findall(f"{deck.C}val//{deck.C}numCache/{deck.C}pt/{deck.C}v")]
            external = tree.find(f"{deck.C}externalData")
            book = self.pkg.rels(rel["resolved"]).get(external.get(deck.R + "id")) if external is not None else None
            cells = None
            if book is not None and book["resolved"] in self.pkg.parts:
                try:
                    cells = deck.workbook_cells(self.pkg.parts[book["resolved"]])
                except (zipfile.BadZipFile, KeyError, ET.ParseError):
                    cells = None
            return {"frame": shape, "part": rel["resolved"], "tree": tree, "name": name, "categories": cats,
                    "values": vals, "cells": cells, "workbook": book["resolved"] if book else None}
        return None

    def all_text(self):
        out = []
        for slide in self.slides:
            for shape in slide.shapes:
                out += deck.texts(shape)
            if slide.notes_body is not None:
                out += deck.texts(slide.notes_body)
        return out


def view_of(target, data):
    return PageView(data) if target == "html" else DeckView(data)


# --- preservation -------------------------------------------------------------------------------

def difference(family, unit, reference, expected, found):
    return {"family": family, "unit": unit, "reference": reference, "expected": expected, "found": found}


def compare_rows(view, rows, family):
    out = []
    for unit, key, want in rows:
        found = view.texts(key)
        if not found:
            out.append(difference(family, unit, key, want, None))
        for got in found:
            if not copy_preserved(want, got):
                out.append(difference(family, unit, key, want, got))
    return out


def preserve(target, data, brief, composition):
    """Extract copy, dataset values, source URLs, evidence status, notes and unit order from a rendered
    page or deck and compare each family with the frozen input. A family the input does not carry is
    `not-carried`, never passed."""
    frozen = Frozen(brief, composition)
    view = view_of(target, data)
    diffs = {family: [] for family in FAMILIES}
    diffs["copy"] = compare_rows(view, frozen.copy, "copy")
    diffs["evidence"] = compare_rows(view, frozen.evidence, "evidence")
    for point in frozen.data:
        for key, want, found in ((f"data:{point['id']}#label", point["label"], view.texts(f"data:{point['id']}#label")),
                                 (f"data:{point['id']}#value", point["value_text"], view.values.get(point["id"], []))):
            if not found:
                diffs["data"].append(difference("data", point["unit"], key, want, None))
            for got in found:
                if not copy_preserved(want, got):
                    diffs["data"].append(difference("data", point["unit"], key, want, got))
    if target == "pptx":
        for unit in dict.fromkeys(point["unit"] for point in frozen.data):
            points = [point for point in frozen.data if point["unit"] == unit]
            want = {"series": [points[0]["measure"]], "categories": [p["label"] for p in points],
                    "values": [p["literal"] for p in points]}
            chart = view.chart(unit)
            if chart is None:
                diffs["data"].append(difference("data", unit, f"chart:{unit}", want, None))
                continue
            got = {"series": chart["name"], "categories": chart["categories"], "values": chart["values"]}
            if not copy_preserved(want, got):
                diffs["data"].append(difference("data", unit, f"chart:{unit}", want, got))
            cells = chart["cells"] or {}
            book = {"series": [cells.get("B1")], "categories": [cells.get(f"A{i}") for i in range(2, len(points) + 2)],
                    "values": [cells.get(f"B{i}") for i in range(2, len(points) + 2)]}
            if not copy_preserved(want, book):
                diffs["data"].append(difference("data", unit, f"workbook:{unit}", want, book))
    for unit, ref, url in frozen.links:
        links = view.unit_links(unit)
        if not any(link_preserved(url, target_url) for target_url in links):
            diffs["sources"].append(difference("sources", unit, ref, url, links))
    for unit in frozen.units:
        got = view.unit_notes(unit)
        if not copy_preserved(frozen.notes[unit], got):
            diffs["notes"].append(difference("notes", unit, unit, frozen.notes[unit], got))
    if not copy_preserved(frozen.units, view.order):
        diffs["order"].append(difference("order", None, "units", frozen.units, view.order))
    carried = frozen.carried()
    families = {}
    for family in FAMILIES:
        status = "not-carried" if carried[family] == 0 else ("failed" if diffs[family] else "passed")
        families[family] = {"status": status, "expected": carried[family], "differences": diffs[family]}
    return families


def preservation_findings(families):
    return [finding(f"{family}-differs", "preservation", diff["unit"],
                    f"{family} {diff['reference']}: expected {diff['expected']!r}, found {diff['found']!r}")
            for family, result in families.items() for diff in result["differences"]]


# --- PPTX editability -----------------------------------------------------------------------------

def editability(data, brief, composition, library):
    """Every copy key a unit binds is native text in a p:sp text frame, every sourced chart is a native
    c:chart graphic frame backed by an embedded workbook, and a picture is only the fallback its unit's
    variant declares for pptx. A flattened substitution — copy or a chart delivered as a picture —
    fails."""
    view = DeckView(data)
    frozen = Frozen(brief, composition)
    objects, out = [], []
    units = {unit["id"]: unit for unit in composition["units"]}
    for unit, key, _ in frozen.copy + frozen.evidence:
        slide = view.by_name.get(unit)
        shapes = slide.named.get(f"copy:{key}", []) if slide is not None else []
        if not shapes and "#" in key and key.rsplit("#", 1)[1].isdigit() and slide is not None:
            shapes = slide.named.get(f"copy:{key.rsplit('#', 1)[0]}", [])
        native = len(shapes) == 1 and shapes[0].tag == deck.P + "sp" and shapes[0].find(deck.P + "txBody") is not None
        objects.append({"unit": unit, "key": key, "kind": "text", "native": native})
        if not native:
            out.append(finding("flattened-substitution", "editability", unit, f"{key} is not native text in a shape"))
    for unit in dict.fromkeys(point["unit"] for point in frozen.data):
        chart = view.chart(unit)
        native = chart is not None and chart["workbook"] is not None and chart["workbook"].startswith("ppt/embeddings/") \
            and chart["cells"] is not None
        objects.append({"unit": unit, "key": f"chart:{unit}", "kind": "chart", "native": native})
        if not native:
            out.append(finding("flattened-substitution", "editability", unit,
                               f"{unit} carries no native chart backed by an embedded workbook"))
    for slide in view.slides:
        for shape in slide.shapes:
            if shape.tag != deck.P + "pic":
                continue
            declared = deck.declared_fallback(slide.name, units, library)
            objects.append({"unit": slide.name, "key": deck.props(shape)[1], "kind": "image",
                            "native": False, "declared_fallback": declared is not None})
            if declared is None:
                out.append(finding("flattened-substitution", "editability", slide.name,
                                   f"picture {deck.props(shape)[1]!r} is not a fallback its unit's variant declares"))
    return {"objects": objects, "findings": out}


def fixed_zip(parts):
    """A package with fixed entry dates, so a witness deck is byte-reproducible."""
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, payload in parts:
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, payload)
    return buffer.getvalue()


def package_parts(data):
    archive = zipfile.ZipFile(io.BytesIO(data))
    return [(info.filename, archive.read(info)) for info in archive.infolist()]


WITNESS_TEXT = "Edited in place by the design-verify witness."
WITNESS_VALUE = "42"


def edit_witnesses(data, brief, composition):
    """Edit one copy run and one chart value of the deck the way an application's editor would reach
    them — the run's text, and the chart's numeric cache together with its embedded workbook cell — and
    read both back from the edited package. A frame or chart that is really a picture has no run or cell
    to edit, so its witness fails."""
    frozen = Frozen(brief, composition)
    view = DeckView(data)
    witnesses = []
    parts = package_parts(data)
    target_copy = next(((unit, key) for unit, key, _ in frozen.copy if unit in view.by_name
                        and view.by_name[unit].named.get(f"copy:{key}")), None)
    if target_copy is None:
        witnesses.append({"kind": "text", "object": None, "status": "failed", "message": "no native copy frame to edit"})
    else:
        unit, key = target_copy
        slide = view.by_name[unit]
        tree = ET.fromstring(dict(parts)[slide.part])
        shape = next(s for s in deck.shapes_of(tree) if deck.props(s)[1] == f"copy:{key}")
        runs = list(shape.iter(deck.A + "t"))
        if shape.tag != deck.P + "sp" or not runs:
            witnesses.append({"kind": "text", "object": f"copy:{key}", "status": "failed",
                              "message": "the frame carries no editable text run"})
        else:
            before = deck.texts(shape)
            runs[0].text = WITNESS_TEXT
            for extra in runs[1:]:
                extra.text = ""
            edited = fixed_zip([(n, ET.tostring(tree, encoding="utf-8", xml_declaration=True) if n == slide.part else p)
                                for n, p in parts])
            after = DeckView(edited).texts(key)
            witnesses.append({"kind": "text", "object": f"copy:{key}", "before": before, "after": after,
                              "edited_sha256": sha256(edited),
                              "status": "passed" if after == [WITNESS_TEXT] else "failed"})
    chart_unit = next((point["unit"] for point in frozen.data), None)
    chart = view.chart(chart_unit) if chart_unit else None
    if chart_unit is None:
        return witnesses
    if chart is None or chart["cells"] is None:
        witnesses.append({"kind": "chart", "object": f"chart:{chart_unit}", "status": "failed",
                          "message": "no native chart with an embedded workbook to edit"})
        return witnesses
    tree = ET.fromstring(dict(parts)[chart["part"]])
    first = tree.find(f".//{deck.C}barChart/{deck.C}ser/{deck.C}val//{deck.C}numCache/{deck.C}pt/{deck.C}v")
    book_parts = package_parts(dict(parts)[chart["workbook"]])
    sheet = ET.fromstring(dict(book_parts)["xl/worksheets/sheet1.xml"])
    cell = next((c for c in sheet.iter(deck.S + "c") if c.get("r") == "B2"), None)
    value = cell.find(deck.S + "v") if cell is not None else None
    if first is None or value is None:
        witnesses.append({"kind": "chart", "object": f"chart:{chart_unit}", "status": "failed",
                          "message": "the chart has no numeric cache or workbook cell to edit"})
        return witnesses
    before = {"cache": first.text, "workbook": value.text}
    first.text = WITNESS_VALUE
    value.text = WITNESS_VALUE
    book = fixed_zip([(n, ET.tostring(sheet, encoding="utf-8", xml_declaration=True) if n == "xl/worksheets/sheet1.xml"
                       else p) for n, p in book_parts])
    edited = fixed_zip([(n, ET.tostring(tree, encoding="utf-8", xml_declaration=True) if n == chart["part"]
                         else (book if n == chart["workbook"] else p)) for n, p in parts])
    read = DeckView(edited).chart(chart_unit)
    after = {"cache": read["values"][0] if read and read["values"] else None,
             "workbook": (read["cells"] or {}).get("B2") if read else None}
    witnesses.append({"kind": "chart", "object": f"chart:{chart_unit}", "before": before, "after": after,
                      "edited_sha256": sha256(edited),
                      "status": "passed" if after == {"cache": WITNESS_VALUE, "workbook": WITNESS_VALUE} else "failed"})
    return witnesses


# --- accessibility --------------------------------------------------------------------------------

def load_capabilities(path):
    declaration = json.loads(Path(path).read_text(encoding="utf-8"))
    targets = declaration.get("targets") if isinstance(declaration, dict) else None
    if not isinstance(targets, dict) or not all(isinstance(targets.get(t), dict) for t in ("html", "pptx")):
        raise ValueError("the capability declaration names no html and pptx targets")
    return declaration


def colour_of(theme, role):
    return contrast.parse_hex(theme.value("colors", role))


def check_contrast(theme, pairs, ratios):
    out, rows = [], []
    for pair in pairs:
        fg, bg = colour_of(theme, pair["foreground"]), colour_of(theme, pair["background"])
        required = ratios[pair["use"]]
        if fg is None or bg is None:
            out.append(finding("contrast-unresolved", "contrast", None,
                               f"{pair['foreground']} on {pair['background']} is not a pair of hex tokens"))
            continue
        ratio = contrast.contrast_ratio(fg, bg)
        rows.append({"foreground": pair["foreground"], "background": pair["background"], "use": pair["use"],
                     "ratio": round(ratio, 2), "required_ratio": required})
        if ratio < required:
            klass = "unreadable-text" if pair["use"] == "text" else None
            out.append(finding("contrast-low", "contrast", None, f"{pair['foreground']} on {pair['background']} is "
                               f"{ratio:.2f}:1, below {required}:1", klass))
    return rows, out


def deck_reading_order(view, composition, library):
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    out = []
    for unit in composition["units"]:
        slide = view.by_name.get(unit["id"])
        if slide is None:
            continue
        reading = patterns[unit["pattern"]]["accessibility"]["reading_order"]
        slots = {}
        for binding in unit.get("bindings", []):
            slots[f"copy:{binding['record_ref']}#{binding['field']}"] = binding["slot"]
        for point in unit.get("data_bindings", []):
            slots[f"copy:data:{point['data_ref']}#label"] = "series"
            slots[f"value:{point['data_ref']}"] = "series"
        slots[f"register:{unit['id']}"] = "evidence"
        sequence = []
        for shape in slide.shapes:
            name = deck.props(shape)[1]
            stem = name.rsplit("#", 1)[0] if name.rsplit("#", 1)[-1].isdigit() else name
            slot = slots.get(name, slots.get(stem))
            if slot is not None:
                sequence.append(reading.index(slot) if slot in reading else -1)
        if -1 in sequence or sequence != sorted(sequence):
            out.append(finding("reading-order", "reading-order", unit["id"],
                               f"{unit['id']} places its slots out of the pattern's reading order {reading}"))
    return out


def deck_descriptions(view, composition):
    out = []
    for slide in view.slides:
        for shape in slide.shapes:
            if shape.tag == deck.P + "pic" or deck.kind_of(shape) == "chart":
                node = shape.find(f".//{deck.P}cNvPr")
                if node is None or not (node.get("descr") or "").strip():
                    out.append(finding("description-missing", "alt-descriptions", slide.name,
                                       f"{deck.props(shape)[1]!r} carries no text alternative"))
    for unit in composition["units"]:
        slide = view.by_name.get(unit["id"])
        for entity in unit.get("entities", []):
            key = f"copy:{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
            shapes = slide.named.get(key, []) if slide is not None else []
            if len(shapes) != 1 or not any(t.strip() for t in deck.texts(shapes[0])):
                out.append(finding("description-missing", "alt-descriptions", unit["id"],
                                   f"entity {entity['id']} is not a native text node, so the figure has no entity-list "
                                   "alternative"))
    return out


def non_color(view, brief, composition):
    """Series, sides and relationships are told apart by text, never by colour alone."""
    frozen = Frozen(brief, composition)
    out = []
    for point in frozen.data:
        if not view.texts(f"data:{point['id']}#label") or not view.values.get(point["id"]):
            out.append(finding("colour-only", "non-color", point["unit"],
                               f"point {point['id']} is not labelled and valued in text"))
    kinds = set()
    for unit in composition["units"]:
        for relation in unit.get("relationships", []):
            kinds.add((unit["id"], relation["from"], relation["to"], relation["kind"]))
    for unit, source, target, kind in sorted(kinds):
        if view.target == "pptx":
            slide = view.by_name.get(unit)
            labels = slide.named.get(f"kind:{source}:{target}", []) if slide is not None else []
            ok = len(labels) == 1 and deck.texts(labels[0]) == [kind]
        else:
            section = view.sections.get(unit)
            ok = section is not None and any(node.attrs.get("data-from") == source and node.attrs.get("data-to") == target
                                             and kind in node.text() for node in section.iter())
        if not ok:
            out.append(finding("colour-only", "non-color", unit,
                               f"relationship {source}->{target} is not labelled {kind!r} in text"))
    return out


def accessibility(target, data, brief, composition, library, theme, declaration):
    """Grade each requirement the target's capability declaration names: `required` ones pass or fail,
    `unsupported` ones are reported as unsupported with their declared reason, never as passed."""
    spec = declaration["targets"][target]
    view = view_of(target, data)
    requirements, out = {}, []
    for name, entry in spec["requirements"].items():
        status = entry.get("status")
        if status == "unsupported":
            requirements[name] = {"status": "unsupported", "reason": entry.get("reason", "")}
            continue
        if name == "reading-order":
            found = [finding("reading-order", "reading-order", f["reference"], f["message"])
                     for f in page.check_reading_order(view.root, composition, library)] if target == "html" \
                else deck_reading_order(view, composition, library)
            rows = None
        elif name == "alt-descriptions":
            found = [finding("description-missing", "alt-descriptions", f["reference"], f["message"])
                     for f in page.check_descriptions(view.root, brief, composition)] if target == "html" \
                else deck_descriptions(view, composition)
            rows = None
        elif name == "contrast":
            rows, found = check_contrast(theme, spec["painted_pairs"], declaration["required_ratio"])
        elif name == "non-color":
            found, rows = non_color(view, brief, composition), None
        else:
            found = [finding("capability-unknown", "accessibility", None, f"no check grades the requirement {name!r}")]
            rows = None
        result = {"status": "failed" if found else "passed", "mechanism": entry.get("mechanism", "")}
        if rows is not None:
            result["pairs"] = rows
        requirements[name] = result
        out += found
    return {"requirements": requirements, "findings": out}


# --- geometry and legibility ---------------------------------------------------------------------

def box_of(shape):
    node = shape.find(f"{deck.P}spPr/{deck.A}xfrm")
    if node is None:
        node = shape.find(deck.P + "xfrm")
    off, ext = (node.find(deck.A + "off"), node.find(deck.A + "ext")) if node is not None else (None, None)
    if off is None or ext is None:
        return None
    return tuple(int(v) / EMU_PER_PX for v in (off.get("x"), off.get("y"), ext.get("cx"), ext.get("cy")))


def needed_height(shape, advance_em):
    """The height a frame's text needs, from the package alone: each paragraph's own line spacing and
    run size, the frame's insets and width, and the resolved face's documented advance."""
    body = shape.find(deck.P + "txBody")
    box = box_of(shape)
    if body is None or box is None:
        return 0.0
    props = body.find(deck.A + "bodyPr")
    inset = {k: int(props.get(k, "91440")) / EMU_PER_PX for k in ("lIns", "tIns", "rIns", "bIns")} if props is not None \
        else {k: 0.0 for k in ("lIns", "tIns", "rIns", "bIns")}
    width = box[2] - inset["lIns"] - inset["rIns"]
    wraps = props is None or props.get("wrap") != "none"
    total = inset["tIns"] + inset["bIns"]
    for para in body.findall(deck.A + "p"):
        text = "".join((node.text or "") if node.tag == deck.A + "t" else "\n" for node in para.iter()
                       if node.tag in (deck.A + "t", deck.A + "br"))
        sizes = [int(node.get("sz")) / 75.0 for node in para.iter() if node.tag in (deck.A + "rPr", deck.A + "endParaRPr")
                 and (node.get("sz") or "").isdigit()]
        size = max(sizes) if sizes else 0.0
        spacing = para.find(f"{deck.A}pPr/{deck.A}lnSpc/{deck.A}spcPts")
        line = int(spacing.get("val")) / 75.0 if spacing is not None else size * 1.2
        before = para.find(f"{deck.A}pPr/{deck.A}spcBef/{deck.A}spcPts")
        total += int(before.get("val")) / 75.0 if before is not None else 0.0
        lines = core.estimate_lines(text, width, size, advance_em) if wraps and size else max(1, text.count("\n") + 1)
        total += lines * line
    return total


def intersect(a, b):
    width = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    height = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return width > OVERLAP_TOLERANCE_PX and height > OVERLAP_TOLERANCE_PX


def glyph_problems(texts):
    bad = []
    for text in texts:
        for char in text:
            if char == "�" or (unicodedata.category(char) in GLYPH_CATEGORIES and char not in ALLOWED_CONTROLS):
                bad.append(f"U+{ord(char):04X}")
    return sorted(set(bad))


def deck_geometry(view, brief, composition, advance_em):
    out = []
    width, height = view.extent[0] / EMU_PER_PX, view.extent[1] / EMU_PER_PX
    for slide in view.slides:
        framed = []
        for shape in slide.shapes:
            name = deck.props(shape)[1]
            box = box_of(shape)
            if box is None:
                continue
            if clipped(box[0] + box[2], width) or clipped(box[1] + box[3], height) or clipped(-box[0], 0.0) \
                    or clipped(-box[1], 0.0):
                out.append(finding("off-slide", "geometry", slide.name, f"{name!r} leaves the slide", "clipping"))
            if shape.find(deck.P + "txBody") is not None and any(t.strip() for t in deck.texts(shape)):
                need = needed_height(shape, advance_em)
                if clipped(need, box[3]):
                    out.append(finding("text-clipped", "geometry", slide.name,
                                       f"{name!r} needs {need:.1f} px for its text and has {box[3]:.1f} px", "clipping"))
                framed.append((name, box))
        for i, (first, a) in enumerate(framed):
            for second, b in framed[i + 1:]:
                if intersect(a, b):
                    out.append(finding("frames-overlap", "geometry", slide.name, f"{first!r} and {second!r} overlap",
                                       "overlap"))
    frozen = Frozen(brief, composition)
    for unit in dict.fromkeys(point["unit"] for point in frozen.data):
        chart = view.chart(unit)
        if chart is None:
            continue
        values = [point["value"] for point in frozen.data if point["unit"] == unit]
        scaling = chart["tree"].find(f".//{deck.C}valAx/{deck.C}scaling")
        bound_min = scaling.find(deck.C + "min") if scaling is not None else None
        bound_max = scaling.find(deck.C + "max") if scaling is not None else None
        if min(values) >= 0 and (bound_min is None or float(bound_min.get("val")) != 0.0):
            out.append(finding("axis-not-zero", "geometry", unit, "the value axis does not start at zero, so bar lengths "
                               "need not be proportional to the values", "misleading-encoding"))
        if max(values) <= 0 and (bound_max is None or float(bound_max.get("val")) != 0.0):
            out.append(finding("axis-not-zero", "geometry", unit, "the value axis does not end at zero",
                               "misleading-encoding"))
        bar = chart["tree"].find(f".//{deck.C}barChart/{deck.C}barDir")
        if bar is None or bar.get("val") != "bar":
            out.append(finding("encoding-changed", "geometry", unit, "the chart is not a bar chart", "misleading-encoding"))
    return out


def page_geometry(view, brief, composition, report=None):
    out = []
    for item in page.check_truncation(view.root):
        out.append(finding(item["code"], "geometry", None, item["message"], "clipping"))
    frozen = Frozen(brief, composition)
    for unit in dict.fromkeys(point["unit"] for point in frozen.data):
        section = view.sections.get(unit)
        marks = [node for node in section.iter() if node.tag == "rect" and "mark" in node.classes()] \
            if section is not None else []
        problems = page.baseline_problems(marks, frozen.content)
        points = {point["id"]: point["value"] for point in frozen.data if point["unit"] == unit}
        ratios = []
        for mark in marks:
            value = points.get(mark.attrs.get("data-ref"))
            try:
                width = float(mark.attrs.get("width"))
            except (TypeError, ValueError):
                continue
            if value:
                ratios.append(width / abs(value))
        if ratios and max(ratios) - min(ratios) > 0.01 * max(ratios):
            problems.append("bar lengths are not proportional to the values")
        for problem in problems:
            out.append(finding("encoding-changed", "geometry", unit, problem, "misleading-encoding"))
    coverage = {"static": "checked", "measured": "not-supplied"}
    if report is not None:
        coverage["measured"] = "checked"
        for key in report.get("clipped", []):
            out.append(finding("text-clipped", "geometry", None, f"the browser report finds {key} clipped", "clipping"))
        for unit in report.get("units", []):
            boxes = [(slot.get("slot"), slot.get("box") or {}) for slot in unit.get("slots", [])]
            for i, (first, a) in enumerate(boxes):
                for second, b in boxes[i + 1:]:
                    try:
                        if intersect((a["x"], a["y"], a["width"], a["height"]), (b["x"], b["y"], b["width"], b["height"])):
                            out.append(finding("slots-overlap", "geometry", unit.get("unit"),
                                               f"slots {first} and {second} overlap in the measured page", "overlap"))
                    except (KeyError, TypeError):
                        out.append(finding("report-malformed", "geometry", unit.get("unit"),
                                           "the browser report carries a slot without a box"))
    return out, coverage


def geometry(target, data, brief, composition, font, report=None):
    """The critical classes a deterministic reading can decide: clipping, overlap, missing glyphs and
    misleading figure encodings. Unreadable text is graded by the fidelity readability floor and the
    contrast requirement."""
    view = view_of(target, data)
    glyphs = glyph_problems(view.all_text())
    out = [finding("missing-glyph", "geometry", None, f"the artifact carries {code}, which no face draws",
                   "missing-glyph") for code in glyphs]
    if target == "pptx":
        out += deck_geometry(view, brief, composition, font["advance_em"])
        coverage = {"static": "checked", "measured": "package"}
    else:
        found, coverage = page_geometry(view, brief, composition, report)
        out += found
    coverage["glyphs"] = "deterministic: replacement, private-use, unassigned and control characters; the platform " \
                         "face's coverage is judged by the visual review"
    return {"coverage": coverage, "findings": out}


# --- fidelity --------------------------------------------------------------------------------------

def fidelity(target, data, brief, composition, theme, manifest=None):
    """The render-time fidelity checks, re-run on the delivered artifact: a delivered file may have been
    edited after the render that produced it."""
    raw = page.check_html(data.decode("utf-8"), brief, composition, theme) if target == "html" \
        else deck.check_pptx(data, brief, composition, theme, manifest)
    return [finding(item["code"], "fidelity", item.get("reference"), item["message"], FIDELITY_CLASSES.get(item["code"]))
            for item in raw]


# --- the report --------------------------------------------------------------------------------------

def review_for(record, brand, target, artifact_sha):
    """The review record's entries for one output, and the findings they leave open."""
    entries = [e for e in record.get("entries", []) if e.get("brand") == brand and e.get("target") == target]
    overviews = [e for e in record.get("overviews", []) if e.get("brand") == brand and e.get("target") == target]
    out = []
    for entry in entries + overviews:
        if (entry.get("artifact") or {}).get("sha256") != artifact_sha:
            out.append(finding("review-stale", "review", entry.get("unit"), "the review entry names another artifact"))
        for item in entry.get("findings", []):
            if item.get("severity") in ("critical", "major"):
                klass = item.get("code") if item.get("code") in CRITICAL_CLASSES else None
                out.append(finding(f"review-{item.get('severity')}", "review", entry.get("unit"),
                                   f"{item.get('criterion')}: {item.get('description')}", klass))
    if not entries or not overviews:
        out.append(finding("review-incomplete", "review", None, f"the review record has no entries for {brand}/{target}"))
    return {"status": "failed" if out else "passed", "entries": len(entries), "overviews": len(overviews)}, out


def build_report(target, brand, artifact_name, data, brief, composition, theme, font, library, declaration,
                 manifest=None, review=None, browser_report=None):
    findings = []
    checks = {}
    fid = fidelity(target, data, brief, composition, theme, manifest)
    checks["fidelity"] = {"status": "failed" if fid else "passed", "findings": len(fid)}
    findings += fid
    families = preserve(target, data, brief, composition)
    checks["preservation"] = {"families": families}
    findings += preservation_findings(families)
    if target == "pptx":
        edit = editability(data, brief, composition, library)
        witnesses = edit_witnesses(data, brief, composition)
        edit_findings = list(edit["findings"])
        edit_findings += [finding("witness-failed", "editability", w.get("object"), f"the {w['kind']} edit witness failed")
                          for w in witnesses if w["status"] != "passed"]
        checks["editability"] = {"status": "failed" if edit_findings else "passed", "objects": edit["objects"],
                                 "witnesses": witnesses}
        findings += edit_findings
    else:
        checks["editability"] = {"status": "not-applicable", "reason": "a page has no editable-object capability"}
    access = accessibility(target, data, brief, composition, library, theme, declaration)
    checks["accessibility"] = access["requirements"]
    findings += access["findings"]
    geo = geometry(target, data, brief, composition, font, browser_report)
    checks["geometry"] = {"status": "failed" if geo["findings"] else "passed", "coverage": geo["coverage"]}
    findings += geo["findings"]
    artifact_sha = sha256(data)
    if review is not None:
        checks["review"], found = review_for(review, brand, target, artifact_sha)
        findings += found
    else:
        checks["review"] = {"status": "not-supplied"}
    for item in findings:
        item["target"], item["brand"] = target, brand
    return {
        "artifact_type": REPORT_TYPE,
        "artifact_version": REPORT_VERSION,
        "target": target,
        "brand": brand,
        "artifact": {"name": artifact_name, "sha256": artifact_sha},
        "content_fingerprint": core.validator.content_fingerprint(brief),
        "design_system": dict(composition["design_system"]),
        "theme": {"slug": theme.slug, "tokens_sha256": theme.digest},
        "checks": checks,
        "findings": findings,
        "verdict": "fail" if findings else "pass",
    }


# --- validators for the persisted records ----------------------------------------------------------

def unqualified(value, path="$"):
    """Paths of keys that state a quality verdict instead of per-artifact findings."""
    out = []
    if isinstance(value, dict):
        for key, item in value.items():
            if key in UNQUALIFIED_KEYS:
                out.append(f"{path}.{key}")
            out += unqualified(item, f"{path}.{key}")
    elif isinstance(value, list):
        for i, item in enumerate(value):
            out += unqualified(item, f"{path}[{i}]")
    return out


def check_findings_list(items, where):
    out = []
    if not isinstance(items, list):
        return [finding("review-malformed", "review", where, "findings is not a list")]
    for item in items:
        if not isinstance(item, dict) or not all(isinstance(item.get(k), str) and item[k].strip()
                                                  for k in ("criterion", "severity", "code", "description")):
            out.append(finding("review-malformed", "review", where, "a finding lacks criterion, severity, code or "
                               "description"))
        elif item["severity"] not in SEVERITIES:
            out.append(finding("review-malformed", "review", where, f"severity {item['severity']!r} is not one of "
                               f"{list(SEVERITIES)}"))
        elif item["severity"] == "critical" and item["code"] not in CRITICAL_CLASSES:
            out.append(finding("review-malformed", "review", where, f"a critical finding must name a critical class, "
                               f"not {item['code']!r}"))
    return out


def check_entry(entry, view, base):
    where = f"{entry.get('brand')}/{entry.get('target')}/{entry.get('unit', 'overview')}"
    out = []
    if entry.get("view") != view:
        out.append(finding("review-malformed", "review", where, f"the entry's view is not {view!r}"))
    capture = entry.get("capture")
    if not isinstance(capture, dict) or not all(capture.get(k) for k in ("tool", "version", "width", "height", "sha256")):
        out.append(finding("review-malformed", "review", where, "the entry does not record its capture tool, version, "
                           "resolution and image digest"))
    elif view == "full-resolution" and (int(capture["width"]) < 1280 or int(capture["height"]) < 720):
        out.append(finding("review-malformed", "review", where, "a full-resolution capture is smaller than the "
                           "1280 x 720 canvas"))
    elif view == "deck-overview":
        try:
            image = resolve_inside(base, str(capture.get("file") or "")) if capture.get("file") else None
        except ValueError:
            image = None
        if image is None or not image.is_file():
            out.append(finding("review-malformed", "review", where, "the deck overview names no committed capture "
                               "file inside the record's directory"))
        elif sha256(image.read_bytes()) != capture["sha256"]:
            out.append(finding("review-stale", "review", where, "the deck overview's capture file does not match its "
                               "recorded digest"))
    artifact = entry.get("artifact")
    if not isinstance(artifact, dict) or not artifact.get("path") or not SHA.match(str(artifact.get("sha256"))):
        out.append(finding("review-malformed", "review", where, "the entry names no artifact path and digest"))
    checked = entry.get("checked")
    if not isinstance(checked, list) or not checked or not all(isinstance(c, str) and c.strip() for c in checked):
        out.append(finding("review-malformed", "review", where, "the entry names no criterion it checked"))
    out += check_findings_list(entry.get("findings"), where)
    return out


def check_review(record, outputs, base):
    """A review record must hold one full-resolution entry per unit x target x brand and one deck overview
    per (brand, target), each naming its artifact, its capture and per-criterion findings, and must never
    carry a bare quality verdict. `outputs` is [(brand, target, artifact sha256, [unit ids])]. Each deck
    overview's capture `file` resolves against `base`, the record's own directory, and its digest is
    recomputed from that file."""
    out = [finding("unqualified-verdict", "review", path, f"{path} states a verdict instead of findings")
           for path in unqualified(record)]
    if not isinstance(record, dict) or not isinstance(record.get("entries"), list) \
            or not isinstance(record.get("overviews"), list):
        return out + [finding("review-malformed", "review", None, "the record has no entries and overviews lists")]
    reviewer = record.get("reviewer")
    if not isinstance(reviewer, dict) or not reviewer.get("kind") or not reviewer.get("name"):
        out.append(finding("review-malformed", "review", None, "the record does not name its reviewer"))
    seen, overviews = {}, {}
    for entry in record["entries"]:
        out += check_entry(entry, "full-resolution", base)
        key = (entry.get("brand"), entry.get("target"), entry.get("unit"))
        seen[key] = seen.get(key, 0) + 1
    for entry in record["overviews"]:
        out += check_entry(entry, "deck-overview", base)
        key = (entry.get("brand"), entry.get("target"))
        overviews[key] = overviews.get(key, 0) + 1
    for brand, target, artifact_sha, units in outputs:
        for unit in units:
            count = seen.get((brand, target, unit), 0)
            if count != 1:
                out.append(finding("review-incomplete" if count == 0 else "review-duplicate", "review",
                                   f"{brand}/{target}/{unit}", f"{brand}/{target}/{unit} has {count} full-resolution "
                                   "entries, not one"))
        if overviews.get((brand, target), 0) != 1:
            out.append(finding("review-incomplete", "review", f"{brand}/{target}",
                               f"{brand}/{target} has {overviews.get((brand, target), 0)} deck overviews, not one"))
        for entry in record["entries"] + record["overviews"]:
            if entry.get("brand") == brand and entry.get("target") == target \
                    and (entry.get("artifact") or {}).get("sha256") != artifact_sha:
                out.append(finding("review-stale", "review", f"{brand}/{target}/{entry.get('unit', 'overview')}",
                                   "the entry reviewed another artifact than the proof records"))
    expected = {(b, t, u) for b, t, _, units in outputs for u in units}
    for key in seen:
        if key not in expected:
            out.append(finding("review-unexpected", "review", "/".join(str(k) for k in key),
                               "the entry names a unit, target or brand the proof does not"))
    return out


def resolve_inside(root, relative):
    path = (root / relative).resolve()
    if path != root.resolve() and root.resolve() not in path.parents:
        raise ValueError(f"{relative} lies outside the proof root")
    return path


def unit_locators(target, data):
    """Every locator a rendered artifact answers, mapped to the unit it names: `#<id>` of each unit section
    of a page, and `slide <n> (<name>)` for the n-th slide of a deck in presentation order, cover included."""
    try:
        if target == "html":
            return {"#" + node.attrs["id"]: node.attrs["data-unit"]
                    for node in page.unit_sections(page.parse(data.decode("utf-8"))) if node.attrs.get("id")}
        if target == "pptx":
            return {f"slide {n} ({slide.name})": slide.name for n, slide in enumerate(DeckView(data).slides, 1)}
    except (UnicodeDecodeError, ValueError, KeyError, zipfile.BadZipFile, ET.ParseError):
        return {}
    return {}


def check_specimens(index, root, used):
    """Every (pattern, variant) the proof uses has rendered examples on both targets for every brand, each
    locator naming the entry's unit inside its own file, a good example that is one of those examples, and
    its own unsuitable uses with reasons; the index records fit failures and limitations. `used` is
    {(pattern, variant)} and `root` the directory example paths resolve against."""
    out = [finding("unqualified-verdict", "specimens", path, f"{path} states a verdict") for path in unqualified(index)]
    entries = index.get("patterns") if isinstance(index, dict) else None
    if not isinstance(entries, list):
        return out + [finding("specimen-malformed", "specimens", None, "the index has no patterns list")]
    by_key = {(e.get("pattern"), e.get("variant")): e for e in entries if isinstance(e, dict)}
    brands = set(index.get("brands") or [])
    if len(brands) < 2:
        out.append(finding("specimen-malformed", "specimens", None, "the index names fewer than two brands"))
    located = {}
    for key in sorted(used):
        entry = by_key.get(key)
        if entry is None:
            out.append(finding("specimen-unresolved", "specimens", "/".join(key), f"{'/'.join(key)} has no specimen"))
            continue
        examples = entry.get("examples") if isinstance(entry.get("examples"), list) else []
        for brand in sorted(brands):
            for target in ("html", "pptx"):
                if not any(e.get("brand") == brand and e.get("target") == target for e in examples):
                    out.append(finding("specimen-target-missing", "specimens", "/".join(key),
                                       f"{'/'.join(key)} has no {target} example for {brand}"))
        for example in examples:
            try:
                path = resolve_inside(root, example.get("artifact", ""))
            except ValueError as exc:
                out.append(finding("specimen-unresolved", "specimens", "/".join(key), str(exc)))
                continue
            if not example.get("locator") or not path.is_file():
                out.append(finding("specimen-unresolved", "specimens", "/".join(key),
                                   f"example {example.get('artifact')!r} does not resolve to a rendered file and locator"))
            elif sha256(path.read_bytes()) != example.get("sha256"):
                out.append(finding("specimen-stale", "specimens", "/".join(key),
                                   f"example {example.get('artifact')!r} does not match its digest"))
            elif located.setdefault((str(path), example.get("target")),
                                    unit_locators(example.get("target"), path.read_bytes())) \
                    .get(str(example.get("locator"))) != entry.get("unit"):
                out.append(finding("specimen-unresolved", "specimens", "/".join(key),
                                   f"example locator {example.get('locator')!r} names no {entry.get('unit')} unit "
                                   f"in {example.get('artifact')!r}"))
        if not entry.get("good"):
            out.append(finding("specimen-good-missing", "specimens", "/".join(key), f"{'/'.join(key)} names no good "
                               "example"))
        for good in entry.get("good") or []:
            if not isinstance(good, dict) or not any(
                    (e.get("brand"), e.get("target"), e.get("locator")) == (good.get("brand"), good.get("target"),
                                                                            good.get("locator"))
                    for e in examples if isinstance(e, dict)):
                out.append(finding("specimen-unresolved", "specimens", "/".join(key),
                                   "a good example names no example of this entry"))
        unsuitable = entry.get("unsuitable")
        if not isinstance(unsuitable, list) or not unsuitable:
            out.append(finding("specimen-reason-missing", "specimens", "/".join(key),
                               f"{'/'.join(key)} records no unsuitable use"))
        for item in unsuitable if isinstance(unsuitable, list) else []:
            if not isinstance(item, dict) or not str(item.get("reason", "")).strip() \
                    or not str(item.get("case", "")).strip():
                out.append(finding("specimen-reason-missing", "specimens", "/".join(key),
                                   "an unsuitable use states no case or reason"))
    if not isinstance(index.get("fit_failures"), list) or not index["fit_failures"]:
        out.append(finding("specimen-malformed", "specimens", None, "the index records no fit failure"))
    if not isinstance(index.get("limitations"), list) or not index["limitations"]:
        out.append(finding("specimen-malformed", "specimens", None, "the index records no limitation"))
    return out
