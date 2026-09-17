"""Independent verification checks for design-verify. Stdlib only.

Every expectation here comes from the frozen inputs — the normalized brief, the composition, the
pattern library, the theme's tokens and the per-target capability declaration — never from the
renderer. A delivered page is read with the verification layer's html.parser reader and a delivered deck with its
zipfile/ElementTree reader; this module imports no adapter, so a damaged writer cannot agree with
itself, and it takes no expectation from the render-time checkers either. Each check returns findings
`{code, check, class, unit, message}`; `class` names one of the critical classes or is null. The
report adds `target` and `brand` to every finding.

references/design-verify.md is the normative description of the families, the critical classes, the
capability declaration, the report, the review record, the specimen index and the proof manifest.
"""

import io
import math
import posixpath
from html.parser import HTMLParser
import json
import re
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

import render_core as core



REPORT_TYPE = "verification-report"
REPORT_VERSION = "1"
# The critical classes. An open finding of any of them fails a verification outright; so does every other
# open finding. No verdict here is an average, a rate or a threshold over findings.
CRITICAL_CLASSES = ("clipping", "overlap", "missing-glyph", "unreadable-text", "misleading-encoding",
                    "generation-residue")
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
# The page's own style block is read far enough to say which colours it paints over which: the
# properties a copy element's foreground and its background can come from, and the selector grammar
# the adapter writes. Anything outside this grammar that carries a colour becomes a finding.
CSS_COLOUR_PROPERTIES = ("color", "fill", "background-color", "background")
CSS_RULE = re.compile(r"([^{}]+)\{([^{}]*)\}")
CSS_VAR = re.compile(r"var\(\s*(--[A-Za-z0-9_-]+)")
CSS_HEX = re.compile(r"#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\b")
CSS_COMPOUND = re.compile(r"([A-Za-z][\w-]*)?((?:\.[\w-]+|\[[\w-]+(?:=[\"']?[^\]\"']*[\"']?)?\])*)")
CSS_KEY = re.compile(r"\.([\w-]+)|\[([\w-]+)")


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


# Artifact readers belong to verification. They extract facts without importing the renderer's
# adapters or check layer; shared core access is limited to frozen inputs and theme resolution.
A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
P = "{http://schemas.openxmlformats.org/presentationml/2006/main}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
C = "{http://schemas.openxmlformats.org/drawingml/2006/chart}"
S = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RELS = "{http://schemas.openxmlformats.org/package/2006/relationships}"


class HtmlNode:
    def __init__(self, tag, attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def iter(self):
        for child in self.children:
            if isinstance(child, HtmlNode):
                yield child
                yield from child.iter()

    def text(self):
        return ''.join(child.text() if isinstance(child, HtmlNode) else child for child in self.children)

    def classes(self):
        return set((self.attrs.get('class') or '').split())


class ArtifactHTML(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = HtmlNode('#document')
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = HtmlNode(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta',
                       'param', 'source', 'track', 'wbr'}:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.stack[-1].children.append(HtmlNode(tag, attrs))

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                break

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def parse_html(text):
    reader = ArtifactHTML()
    reader.feed(text)
    reader.close()
    return reader.root


def unit_sections(root):
    return [node for node in root.iter() if node.tag == 'section' and 'data-unit' in node.attrs]


class Package:
    def __init__(self, data):
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            self.names = archive.namelist()
            self.parts = {name: archive.read(name) for name in self.names if not name.endswith('/')}

    def tree(self, name):
        return ET.fromstring(self.parts[name])

    def rels(self, part):
        folder, name = posixpath.split(part)
        path = posixpath.join(folder, '_rels', name + '.rels')
        if path not in self.parts:
            return {}
        relationships = {}
        for node in self.tree(path):
            if node.tag != RELS + 'Relationship':
                continue
            target = node.get('Target', '')
            external = node.get('TargetMode') == 'External'
            resolved = posixpath.normpath(posixpath.join(folder, target)).lstrip('/')
            relationships[node.get('Id')] = {'type': node.get('Type', ''), 'target': target,
                                             'external': external, 'resolved': None if external else resolved}
        return relationships


def slide_parts(pkg):
    presentations = [rel['resolved'] for rel in pkg.rels('').values()
                     if rel['type'].endswith('/officeDocument') and not rel['external']]
    if len(presentations) != 1:
        raise ValueError('the package must name exactly one presentation')
    part = presentations[0]
    tree, rels = pkg.tree(part), pkg.rels(part)
    parts = []
    for node in tree.findall(f'{P}sldIdLst/{P}sldId'):
        rel = rels.get(node.get(R + 'id'))
        if not rel or not rel['type'].endswith('/slide') or rel['resolved'] not in pkg.parts:
            raise ValueError('a presentation slide relationship does not resolve')
        parts.append(rel['resolved'])
    size = tree.find(P + 'sldSz')
    return part, parts, (int(size.get('cx')), int(size.get('cy')))


def shapes_of(tree):
    container = tree.find(f'{P}cSld/{P}spTree')
    if container is None:
        return []
    return [node for node in container.iter() if node.tag in {P + k for k in ('sp', 'pic', 'cxnSp', 'graphicFrame')}]


def props(shape):
    node = shape.find(f'.//{P}cNvPr')
    return (node.get('id'), node.get('name', '')) if node is not None else (None, '')


def kind_of(shape):
    if shape.tag == P + 'pic':
        return 'image'
    if shape.tag == P + 'cxnSp':
        return 'connector'
    if shape.tag == P + 'graphicFrame':
        return 'chart' if shape.find(f'.//{C}chart') is not None else 'frame'
    return 'text' if shape.find(P + 'txBody') is not None else 'shape'


def paragraphs(shape):
    result = []
    for paragraph in shape.findall(f'{P}txBody/{A}p'):
        runs = []
        for node in paragraph:
            if node.tag == A + 'br':
                runs.append(('\n', None))
            elif node.tag in (A + 'r', A + 'fld'):
                runs.append((''.join(t.text or '' for t in node.iter(A + 't')), node.find(A + 'rPr')))
        result.append((''.join(text for text, _ in runs), runs))
    return result


def texts(shape):
    return [text for text, _ in paragraphs(shape)]


def link_of(properties, rels):
    link = properties.find(A + 'hlinkClick') if properties is not None else None
    rel = rels.get(link.get(R + 'id')) if link is not None else None
    return (link.get(R + 'id'), rel['target']) if rel is not None else None


class Slide:
    def __init__(self, pkg, part):
        self.part, self.tree = part, pkg.tree(part)
        self.name = self.tree.find(P + 'cSld').get('name', '')
        self.shapes, self.rels = shapes_of(self.tree), pkg.rels(part)
        self.named = {}
        for shape in self.shapes:
            self.named.setdefault(props(shape)[1], []).append(shape)
        notes = [rel['resolved'] for rel in self.rels.values() if rel['type'].endswith('/notesSlide')]
        self.notes_part = notes[0] if notes else None
        self.notes_rels = pkg.rels(self.notes_part) if self.notes_part else {}
        self.notes_body = None
        if self.notes_part in pkg.parts:
            for shape in shapes_of(pkg.tree(self.notes_part)):
                placeholder = shape.find(f'.//{P}ph')
                if placeholder is not None and placeholder.get('type') == 'body':
                    self.notes_body = shape


def workbook_cells(data):
    with zipfile.ZipFile(io.BytesIO(data)) as book:
        shared = []
        if 'xl/sharedStrings.xml' in book.namelist():
            shared = [''.join(t.text or '' for t in item.iter(S + 't'))
                      for item in ET.fromstring(book.read('xl/sharedStrings.xml')).iter(S + 'si')]
        sheet = ET.fromstring(book.read('xl/worksheets/sheet1.xml'))
    cells = {}
    for cell in sheet.iter(S + 'c'):
        value = cell.findtext(S + 'v', '')
        if cell.get('t') == 'inlineStr':
            value = ''.join(t.text or '' for t in cell.iter(S + 't'))
        elif cell.get('t') == 's':
            value = shared[int(value)]
        cells[cell.get('r')] = value
    return cells


def declared_fallback(name, units, library):
    unit = units.get(name)
    if unit:
        pattern = next(p for p in library['patterns'] if p['id'] == unit['pattern'])
        variant = next(v for v in pattern['variants'] if v['id'] == unit['variant'])
        fallback = variant.get('fallback')
        if isinstance(fallback, dict) and fallback.get('target') == 'pptx':
            return fallback
    return None


def parse_hex(value):
    value = value.lstrip('#') if isinstance(value, str) else ''
    if not re.fullmatch(r'[0-9a-fA-F]{3}|[0-9a-fA-F]{6}', value):
        return None
    if len(value) == 3:
        value = ''.join(c * 2 for c in value)
    return tuple(int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def contrast_ratio(first, second):
    def luminance(rgb):
        linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
        return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))
    light, dark = sorted((luminance(first), luminance(second)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


def page_reading_order(view, composition, library):
    patterns = {p['id']: p for p in library['patterns']}
    out = []
    if view.order != [u['id'] for u in composition['units']]:
        out.append(finding('reading-order', 'reading-order', None, 'page units differ from the composition order'))
    for unit in composition['units']:
        section = view.sections.get(unit['id'])
        if section is None:
            continue
        order = patterns[unit['pattern']]['accessibility']['reading_order']
        slots = [n.attrs['data-slot'] for n in section.iter() if 'data-slot' in n.attrs]
        ranks = [order.index(slot) if slot in order else -1 for slot in slots]
        if -1 in ranks or ranks != sorted(ranks) or len(slots) != len(set(slots)):
            out.append(finding('reading-order', 'reading-order', unit['id'], 'page slots differ from pattern reading order'))
    return out


def page_descriptions(view, brief, composition):
    content = core.Content(brief)
    ids = {n.attrs['id']: n for n in view.root.iter() if 'id' in n.attrs}
    out = []
    for unit in composition['units']:
        section = view.sections.get(unit['id'])
        if section is None:
            continue
        claim = next((content.field(b['record_ref'], b['field']) for b in unit.get('bindings', [])
                      if b['slot'] in ('claim', 'answer', 'heading')), None)
        for node in section.iter():
            if node.tag != 'svg':
                continue
            label = ids.get(node.attrs.get('aria-labelledby'))
            alt = ids.get(node.attrs.get('aria-describedby'))
            if node.attrs.get('role') != 'img' or label is None or label.text() != claim or alt is None or not alt.text().strip():
                out.append(finding('description-missing', 'alt-descriptions', unit['id'],
                                   'figure needs its frozen claim and a resolvable text alternative'))
    return out


def page_truncation(root):
    out = []
    for node in root.iter():
        css = node.text() if node.tag == 'style' else node.attrs.get('style', '')
        if re.search(r'text-overflow\s*:\s*ellipsis|line-clamp|display\s*:\s*none|visibility\s*:\s*hidden|'
                     r'overflow(?:-[xy])?\s*:\s*(?:hidden|clip)|max-height\s*:', css, re.I):
            out.append(finding('truncating-css', 'geometry', None, 'CSS hides or clips content', 'clipping'))
        if 'hidden' in node.attrs or node.attrs.get('aria-hidden') == 'true':
            if 'data-copy' in node.attrs or any('data-copy' in n.attrs for n in node.iter()):
                out.append(finding('hidden-copy', 'geometry', None, 'frozen copy is hidden', 'clipping'))
    return out


def baseline_problems(marks, content):
    baselines, problems = [], []
    for mark in marks:
        try:
            value = float(content.data(mark.attrs['data-ref'])['value'])
            x, width = float(mark.attrs['x']), float(mark.attrs['width'])
            if width < 0 or (value == 0 and width != 0):
                problems.append('bar width contradicts its frozen value')
            baselines.append(x + width if value < 0 else x)
        except (KeyError, TypeError, ValueError):
            problems.append('bar has no frozen value or numeric geometry')
    if baselines and max(baselines) - min(baselines) > 0.05:
        problems.append('bars do not share the frozen values\' zero baseline')
    return problems


# --- what a delivered artifact shows, family by family --------------------------------------------

class PageView:
    """The families a rendered page shows, read with the verification layer's html.parser reader."""

    target = "html"

    def __init__(self, data):
        self.root = parse_html(data.decode("utf-8"))
        self.sections = {node.attrs["data-unit"]: node for node in unit_sections(self.root)}
        self.order = [node.attrs["data-unit"] for node in unit_sections(self.root)]
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
    """The families a rendered deck shows, read with the verification layer's zipfile/ElementTree reader."""

    target = "pptx"

    def __init__(self, data):
        self.pkg = Package(data)
        _, parts, self.extent = slide_parts(self.pkg)
        self.slides = [Slide(self.pkg, part) for part in parts]
        self.by_name = {slide.name: slide for slide in self.slides}
        self.order = [slide.name for slide in self.slides if slide.name != "document"]
        self.copy, self.values = {}, {}
        for slide in self.slides:
            for name, shapes in slide.named.items():
                for shape in shapes:
                    paras = texts(shape)
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
        return texts(slide.notes_body) if slide is not None and slide.notes_body is not None else []

    def unit_links(self, unit):
        slide = self.by_name.get(unit)
        if slide is None:
            return []
        links = []
        for rels, shapes in ((slide.rels, slide.shapes), (slide.notes_rels, [slide.notes_body])):
            for shape in shapes:
                if shape is None:
                    continue
                for _, runs in paragraphs(shape):
                    for _, rpr in runs:
                        link = link_of(rpr, rels)
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
            if kind_of(shape) != "chart":
                continue
            node = shape.find(f".//{C}chart")
            rel = slide.rels.get(node.get(R + "id")) if node is not None else None
            if rel is None or rel["resolved"] not in self.pkg.parts:
                return None
            tree = self.pkg.tree(rel["resolved"])
            ser = tree.find(f".//{C}barChart/{C}ser")
            if ser is None:
                return None
            name = [n.text or "" for n in ser.findall(f"{C}tx//{C}v")]
            cats = [n.text or "" for n in ser.findall(f"{C}cat//{C}pt/{C}v")]
            vals = [n.text or "" for n in ser.findall(f"{C}val//{C}numCache/{C}pt/{C}v")]
            external = tree.find(f"{C}externalData")
            book = self.pkg.rels(rel["resolved"]).get(external.get(R + "id")) if external is not None else None
            cells = None
            if book is not None and book["resolved"] in self.pkg.parts:
                try:
                    cells = workbook_cells(self.pkg.parts[book["resolved"]])
                except (zipfile.BadZipFile, KeyError, ET.ParseError):
                    cells = None
            return {"frame": shape, "part": rel["resolved"], "tree": tree, "name": name, "categories": cats,
                    "values": vals, "cells": cells, "workbook": book["resolved"] if book else None}
        return None

    def all_text(self):
        out = []
        for slide in self.slides:
            for shape in slide.shapes:
                out += texts(shape)
            if slide.notes_body is not None:
                out += texts(slide.notes_body)
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

def text_shapes(slide):
    return [shape for shape in slide.shapes if shape.find(P + "txBody") is not None]


def split_across_shapes(slide, value):
    """The shapes a frozen string is only whole across, when no single shape carries it — an emphasis
    run moved into a second p:sp keeps the copy byte-identical while destroying editability, so the
    join is the only place that move is visible."""
    shapes = text_shapes(slide)
    joined = ["".join(texts(shape)) for shape in shapes]
    if any(found == value for found in joined):
        return None
    for start in range(len(shapes)):
        for end in range(start + 2, len(shapes) + 1):
            if "".join(joined[start:end]) == value:
                return [props(shape)[1] for shape in shapes[start:end]]
    return None


def editability(data, brief, composition, library):
    """Every copy key a unit binds is native text in one p:sp text frame, every sourced chart is a native
    c:chart graphic frame backed by an embedded workbook, and a picture is only the fallback its unit's
    variant declares for pptx. A flattened substitution — copy or a chart delivered as a picture, or a
    copy key whole only across two shapes — fails. The frozen walk grades what the brief binds; the
    package walk after it grades the objects a foreign writer named differently, so a deck this plugin
    did not write is still graded."""
    view = DeckView(data)
    frozen = Frozen(brief, composition)
    objects, out, graded = [], [], set()
    units = {unit["id"]: unit for unit in composition["units"]}
    for unit, key, value in frozen.copy + frozen.evidence:
        slide = view.by_name.get(unit)
        shapes = slide.named.get(f"copy:{key}", []) if slide is not None else []
        if not shapes and "#" in key and key.rsplit("#", 1)[1].isdigit() and slide is not None:
            shapes = slide.named.get(f"copy:{key.rsplit('#', 1)[0]}", [])
        native = len(shapes) == 1 and shapes[0].tag == P + "sp" and shapes[0].find(P + "txBody") is not None
        graded.update(id(shape) for shape in shapes)
        objects.append({"unit": unit, "key": key, "kind": "text", "native": native})
        if not native:
            pictures = [props(shape)[1] for shape in slide.shapes if shape.tag == P + "pic"] if slide is not None else []
            instead = f", and the slide carries the picture {pictures[0]!r}" if pictures and not shapes else ""
            out.append(finding("flattened-substitution", "editability", unit,
                               f"{key} is not native text in a shape{instead}"))
            continue
        spread = split_across_shapes(slide, value) if isinstance(value, str) else None
        if spread:
            out.append(finding("flattened-substitution", "editability", unit,
                               f"{key} is whole only across {len(spread)} shapes, so a run left its own shape"))
    for unit in dict.fromkeys(point["unit"] for point in frozen.data):
        chart = view.chart(unit)
        native = chart is not None and chart["workbook"] is not None and chart["workbook"].startswith("ppt/embeddings/") \
            and chart["cells"] is not None
        if chart is not None:
            graded.add(id(chart["frame"]))
        objects.append({"unit": unit, "key": f"chart:{unit}", "kind": "chart", "native": native})
        if not native:
            out.append(finding("flattened-substitution", "editability", unit,
                               f"{unit} carries no native chart backed by an embedded workbook"))
    for slide in view.slides:
        for shape in slide.shapes:
            name = props(shape)[1]
            if shape.tag == P + "pic":
                declared = declared_fallback(slide.name, units, library)
                objects.append({"unit": slide.name, "key": name, "kind": "image",
                                "native": False, "declared_fallback": declared is not None})
                if declared is None:
                    out.append(finding("flattened-substitution", "editability", slide.name,
                                       f"picture {name!r} is not a fallback its unit's variant declares"))
                node = shape.find(f".//{P}cNvPr")
                if node is None or not (node.get("descr") or "").strip():
                    out.append(finding("description-missing", "editability", slide.name,
                                       f"picture {name!r} carries no text alternative"))
                continue
            if id(shape) in graded or not name.startswith("copy:"):
                continue
            if shape.tag == P + "sp" and shape.find(P + "txBody") is not None:
                continue  # a native object the frozen walk did not name is editable; only flattening is a finding
            objects.append({"unit": slide.name, "key": name[len("copy:"):], "kind": "text", "native": False,
                            "from": "package"})
            out.append(finding("flattened-substitution", "editability", slide.name,
                               f"{name} is not native text in a shape"))
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
        shape = next(s for s in shapes_of(tree) if props(s)[1] == f"copy:{key}")
        runs = list(shape.iter(A + "t"))
        if shape.tag != P + "sp" or not runs:
            witnesses.append({"kind": "text", "object": f"copy:{key}", "status": "failed",
                              "message": "the frame carries no editable text run"})
        else:
            before = texts(shape)
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
    first = tree.find(f".//{C}barChart/{C}ser/{C}val//{C}numCache/{C}pt/{C}v")
    book_parts = package_parts(dict(parts)[chart["workbook"]])
    sheet = ET.fromstring(dict(book_parts)["xl/worksheets/sheet1.xml"])
    cell = next((c for c in sheet.iter(S + "c") if c.get("r") == "B2"), None)
    value = cell.find(S + "v") if cell is not None else None
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
    return parse_hex(theme.value("colors", role))


class Colours:
    """The one place a colour is resolved to a literal, for both targets and for both the declared
    roles and the painted values. The theme's tokens are already alias-resolved — `render_core`'s
    `resolve_theme` builds the theme from `render_resolved(...)["tokens"]` — so nothing here reads a
    `tokens.resolved.json`, which a theme holding no alias never writes."""

    def __init__(self, theme):
        self.roles, self.properties = {}, {}
        for role, value in (theme.tokens.get("colors") or {}).items():
            literal = self.literal(value)
            if literal is None:
                continue
            self.roles[role] = literal
            self.properties["--colors-" + str(role).replace("_", "-").lstrip("-")] = literal

    @staticmethod
    def literal(value):
        """A colour as a lowercase `#rrggbb` literal, or None when it is not one."""
        if parse_hex(value) is None:
            return None
        text = str(value).lstrip("#")
        return "#" + ("".join(c * 2 for c in text) if len(text) == 3 else text).lower()

    def css(self, value):
        """A CSS colour declaration as a literal: a `var()` resolved through the theme's tokens, or a
        hex literal the artifact paints outside them. None when it names no colour this reader
        resolves, and `inherit` when the declaration defers to the ancestor."""
        if not isinstance(value, str):
            return None
        text = value.strip()
        if text in ("inherit", "currentColor", "currentcolor"):
            return "inherit"
        match = CSS_VAR.search(text)
        if match:
            return self.properties.get(match.group(1))
        match = CSS_HEX.search(text)
        return self.literal(match.group()) if match else None

    def drawingml(self, node, palette):
        """The literal a DrawingML fill paints — an `srgbClr`, or a `schemeClr` through the slide
        master's `clrMap` into the theme's `clrScheme`. None when the fill paints no solid colour."""
        if node is None:
            return None
        mapping, scheme = palette
        for child in node:
            if child.tag == A + "srgbClr":
                return self.literal("#" + (child.get("val") or ""))
            if child.tag == A + "schemeClr":
                return scheme.get(mapping.get(child.get("val"), child.get("val")))
        return None


def painted_graded(pair, declared):
    return pair not in declared


def css_declarations(body, colours):
    """The colour-bearing declarations of one CSS rule body, keyed by property."""
    found = {}
    for piece in body.split(";"):
        name, _, value = piece.partition(":")
        name = name.strip().lower()
        if name in CSS_COLOUR_PROPERTIES:
            found[name] = colours.css(value)
    return found


def css_compound(text):
    """One compound selector as (tag, keys, specificity), or None when it is outside the supported
    grammar — a tag optionally followed by any number of `.class` and `[attr]` or `[attr=value]`."""
    match = CSS_COMPOUND.fullmatch(text)
    if match is None:
        return None
    tag = (match.group(1) or "").lower()
    keys = tuple(sorted(name or attribute for name, attribute in CSS_KEY.findall(match.group(2) or "")))
    return tag, keys, (len(keys), 1 if tag else 0)


def css_selector(text):
    """One selector as a list of compounds, outermost first, or None when it is unsupported. A `>`
    child combinator is read as a descendant one: it only ever narrows what a rule matches, so
    reading it loosely can add a painted pair but never drop one."""
    compounds, specificity = [], (0, 0)
    for piece in text.replace(">", " ").split():
        compound = css_compound(piece)
        if compound is None:
            return None
        compounds.append(compound[:2])
        specificity = (specificity[0] + compound[2][0], specificity[1] + compound[2][1])
    return (compounds, specificity) if compounds else None


def css_rules(style, colours):
    """The page's own colour-bearing rules as (compounds, specificity, order, declarations), and the
    selectors that carry a colour this reader cannot match, which become findings rather than a
    silent pass."""
    rules, unsupported = [], []
    for match in CSS_RULE.finditer(re.sub(r"/\*.*?\*/", " ", style, flags=re.S)):
        head, body = match.group(1).strip(), match.group(2)
        if head.startswith("@"):
            continue
        declarations = css_declarations(body, colours)
        if not declarations:
            continue
        for piece in head.split(","):
            selector = css_selector(piece.strip())
            if selector is None:
                unsupported.append(piece.strip())
                continue
            rules.append((selector[0], selector[1], len(rules), declarations))
    return rules, unsupported


def css_matches(compounds, chain):
    """Whether a selector's compounds match an element's ancestor chain, innermost compound on the
    element itself and the rest as ancestors in order."""
    index = len(chain) - 1
    for tag, keys in reversed(compounds):
        while index >= 0:
            node = chain[index]
            index -= 1
            if (not tag or node.tag == tag) and all(key in node.attrs or key in node.classes() for key in keys):
                break
        else:
            return False
    return True


def page_painting(view, colours):
    """Each `data-copy` element's painted foreground and the nearest painted ancestor background,
    read from the page's own style rules and inline declarations."""
    style = "\n".join(node.text() for node in view.root.iter() if node.tag == "style")
    rules, unsupported = css_rules(style, colours)
    out = [{"unit": None, "unresolved": True, "message": f"the selector {name!r} paints a colour this "
            "reader does not resolve"} for name in sorted(set(unsupported))]
    seen = set()
    def walk(node, chain, unit, foreground, background):
        chain = chain + [node]
        unit = node.attrs.get("data-unit", unit)
        painted = {}
        for compounds, specificity, order, declarations in sorted(rules, key=lambda rule: (rule[1], rule[2])):
            if css_matches(compounds, chain):
                painted.update(declarations)
        painted.update(css_declarations(node.attrs.get("style", ""), colours))
        for name in ("color", "fill"):
            if painted.get(name) and painted[name] != "inherit":
                foreground = painted[name]
        for name in ("background-color", "background"):
            if painted.get(name) and painted[name] != "inherit":
                background = painted[name]
        if "data-copy" in node.attrs:
            # Page chrome carries a `data-copy` key outside every `[data-unit]` ancestor, so the walk
            # has no unit to hand it; the copy key's own prefix names it instead, and no painted pair
            # ever reaches a report with a null unit.
            name = unit or node.attrs["data-copy"].split("#", 1)[0]
            if foreground is None or background is None:
                key = (name, "unresolved")
                if key not in seen:
                    seen.add(key)
                    out.append({"unit": name, "unresolved": True,
                                "message": f"{node.attrs['data-copy']} paints no resolvable foreground and background"})
            else:
                key = (name, foreground, background)
                if key not in seen:
                    seen.add(key)
                    out.append({"unit": name, "foreground": foreground, "background": background, "use": "text"})
        for child in node.children:
            if isinstance(child, HtmlNode):
                walk(child, chain, unit, foreground, background)
    walk(view.root, [], None, None, None)
    return out


def deck_palette(pkg, slide):
    """The slide's colour vocabulary — its master's `clrMap` and its theme's `clrScheme` — and the
    layout and master parts, read through the package's own relationships."""
    layout = next((rel["resolved"] for rel in slide.rels.values() if rel["type"].endswith("/slideLayout")), None)
    master = next((rel["resolved"] for rel in pkg.rels(layout).values()
                   if rel["type"].endswith("/slideMaster")), None) if layout in pkg.parts else None
    part = next((rel["resolved"] for rel in pkg.rels(master).values()
                 if rel["type"].endswith("/theme")), None) if master in pkg.parts else None
    mapping, scheme = {}, {}
    if master in pkg.parts:
        node = pkg.tree(master).find(P + "clrMap")
        mapping = dict(node.attrib) if node is not None else {}
    if part in pkg.parts:
        node = pkg.tree(part).find(f"{A}themeElements/{A}clrScheme")
        for child in node if node is not None else []:
            srgb = child.find(A + "srgbClr")
            if srgb is not None:
                scheme[child.tag[len(A):]] = Colours.literal("#" + (srgb.get("val") or ""))
    return (mapping, scheme), layout, master


def deck_background(pkg, node, palette, colours):
    """The literal a `p:bg` paints — a `bgPr` solid fill, or a `bgRef`'s scheme colour."""
    if node is None:
        return None
    fill = node.find(f"{P}bgPr/{A}solidFill")
    return colours.drawingml(fill if fill is not None else node.find(P + "bgRef"), palette)


def deck_painting(view, colours):
    """Each text-bearing shape run's painted colour against the colour behind it — the shape's own
    solid fill when it has one, else the slide's background. OOXML background inheritance is
    slide -> layout -> master, so a layout-declared `p:bg` is read before the master's."""
    out, seen = [], set()
    for slide in view.slides:
        palette, layout, master = deck_palette(view.pkg, slide)
        background = deck_background(view.pkg, slide.tree.find(f"{P}cSld/{P}bg"), palette, colours)
        if background is None and layout in view.pkg.parts:
            background = deck_background(view.pkg, view.pkg.tree(layout).find(f"{P}cSld/{P}bg"), palette, colours)
        if background is None and master in view.pkg.parts:
            background = deck_background(view.pkg, view.pkg.tree(master).find(f"{P}cSld/{P}bg"), palette, colours)
        for shape in slide.shapes:
            if shape.find(P + "txBody") is None:
                continue
            fill = colours.drawingml(shape.find(f"{P}spPr/{A}solidFill"), palette) or background
            for _, runs in paragraphs(shape):
                for text, properties in runs:
                    if not text.strip():
                        continue
                    colour = colours.drawingml(properties.find(A + "solidFill") if properties is not None else None,
                                               palette)
                    if colour is None or fill is None:
                        key = (slide.name, "unresolved")
                        if key not in seen:
                            seen.add(key)
                            out.append({"unit": slide.name, "unresolved": True,
                                        "message": f"{props(shape)[1]!r} paints a run this reader does not resolve"})
                        continue
                    key = (slide.name, colour, fill)
                    if key not in seen:
                        seen.add(key)
                        out.append({"unit": slide.name, "foreground": colour, "background": fill, "use": "text"})
    return out


def check_contrast(theme, pairs, ratios, painted=()):
    colours = Colours(theme)
    out, rows = [], []
    for pair in pairs:
        fg, bg = colour_of(theme, pair["foreground"]), colour_of(theme, pair["background"])
        required = ratios[pair["use"]]
        if fg is None or bg is None:
            out.append(finding("contrast-unresolved", "contrast", None,
                               f"{pair['foreground']} on {pair['background']} is not a pair of hex tokens"))
            continue
        ratio = contrast_ratio(fg, bg)
        rows.append({"foreground": pair["foreground"], "background": pair["background"], "use": pair["use"],
                     "ratio": round(ratio, 2), "required_ratio": required})
        if ratio < required:
            klass = "unreadable-text" if pair["use"] == "text" else None
            out.append(finding("contrast-low", "contrast", None, f"{pair['foreground']} on {pair['background']} is "
                               f"{ratio:.2f}:1, below {required}:1", klass))
    declared = {(colours.roles.get(pair["foreground"]), colours.roles.get(pair["background"]), pair["use"])
                for pair in pairs}
    for item in painted:
        if item.get("unresolved"):
            out.append(finding("contrast-unresolved", "contrast", item["unit"], item["message"]))
            continue
        key = (item["foreground"], item["background"], item["use"])
        if not painted_graded(key, declared):
            continue
        required = ratios[item["use"]]
        ratio = contrast_ratio(parse_hex(item["foreground"]), parse_hex(item["background"]))
        rows.append({"foreground": item["foreground"], "background": item["background"], "use": item["use"],
                     "unit": item["unit"], "painted": True, "ratio": round(ratio, 2), "required_ratio": required})
        if ratio < required:
            klass = "unreadable-text" if item["use"] == "text" else None
            out.append(finding("contrast-low", "contrast", item["unit"],
                               f"the artifact paints {item['foreground']} on {item['background']}, "
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
            name = props(shape)[1]
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
            if shape.tag == P + "pic" or kind_of(shape) == "chart":
                node = shape.find(f".//{P}cNvPr")
                if node is None or not (node.get("descr") or "").strip():
                    out.append(finding("description-missing", "alt-descriptions", slide.name,
                                       f"{props(shape)[1]!r} carries no text alternative"))
    for unit in composition["units"]:
        slide = view.by_name.get(unit["id"])
        for entity in unit.get("entities", []):
            key = f"copy:{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
            shapes = slide.named.get(key, []) if slide is not None else []
            if len(shapes) != 1 or not any(t.strip() for t in texts(shapes[0])):
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
            ok = len(labels) == 1 and texts(labels[0]) == [kind]
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
            found = page_reading_order(view, composition, library) if target == "html" \
                else deck_reading_order(view, composition, library)
            rows = None
        elif name == "alt-descriptions":
            found = page_descriptions(view, brief, composition) if target == "html" \
                else deck_descriptions(view, composition)
            rows = None
        elif name == "contrast":
            colours = Colours(theme)
            painted = page_painting(view, colours) if target == "html" else deck_painting(view, colours)
            rows, found = check_contrast(theme, spec["painted_pairs"], declaration["required_ratio"], painted)
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
    node = shape.find(f"{P}spPr/{A}xfrm")
    if node is None:
        node = shape.find(P + "xfrm")
    off, ext = (node.find(A + "off"), node.find(A + "ext")) if node is not None else (None, None)
    if off is None or ext is None:
        return None
    return tuple(int(v) / EMU_PER_PX for v in (off.get("x"), off.get("y"), ext.get("cx"), ext.get("cy")))


def sized_runs(para, default):
    """Each run of one paragraph as (text, size px), a hard break as its own newline run. A paragraph
    whose runs share one size is left to `estimate_lines` unchanged; only a paragraph carrying a second
    run at another size — an emphasis run inside its own shape — needs the per-run measurement."""
    out = []
    for node in para:
        if node.tag == A + "br":
            out.append(("\n", default))
        elif node.tag in (A + "r", A + "fld"):
            properties = node.find(A + "rPr")
            size = int(properties.get("sz")) / 75.0 if properties is not None and (properties.get("sz") or "").isdigit() \
                else default
            out.append(("".join(t.text or "" for t in node.iter(A + "t")), size))
    return out


def run_lines(runs, width, advance_em):
    """The lines a paragraph of differently sized runs needs: each character consumes its own run's
    share of a line, and a hard break closes the line it is on."""
    lines, consumed = 0, 0.0
    for text, size in runs:
        for index, segment in enumerate(str(text).split("\n")):
            if index:
                lines += max(1, math.ceil(consumed))
                consumed = 0.0
            consumed += len(segment) / core.chars_per_line(width, size, advance_em)
    return lines + max(1, math.ceil(consumed))


def needed_height(shape, advance_em):
    """The height a frame's text needs, from the package alone: each paragraph's own line spacing and
    run size, the frame's insets and width, and the resolved face's documented advance."""
    body = shape.find(P + "txBody")
    box = box_of(shape)
    if body is None or box is None:
        return 0.0
    props = body.find(A + "bodyPr")
    inset = {k: int(props.get(k, "91440")) / EMU_PER_PX for k in ("lIns", "tIns", "rIns", "bIns")} if props is not None \
        else {k: 0.0 for k in ("lIns", "tIns", "rIns", "bIns")}
    width = box[2] - inset["lIns"] - inset["rIns"]
    wraps = props is None or props.get("wrap") != "none"
    total = inset["tIns"] + inset["bIns"]
    for para in body.findall(A + "p"):
        text = "".join((node.text or "") if node.tag == A + "t" else "\n" for node in para.iter()
                       if node.tag in (A + "t", A + "br"))
        sizes = [int(node.get("sz")) / 75.0 for node in para.iter() if node.tag in (A + "rPr", A + "endParaRPr")
                 and (node.get("sz") or "").isdigit()]
        size = max(sizes) if sizes else 0.0
        spacing = para.find(f"{A}pPr/{A}lnSpc/{A}spcPts")
        line = int(spacing.get("val")) / 75.0 if spacing is not None else size * 1.2
        before = para.find(f"{A}pPr/{A}spcBef/{A}spcPts")
        total += int(before.get("val")) / 75.0 if before is not None else 0.0
        runs = sized_runs(para, size)
        mixed = len({run_size for run_text, run_size in runs if run_text != "\n"}) > 1
        if not (wraps and size):
            lines = max(1, text.count("\n") + 1)
        elif mixed:
            lines = run_lines(runs, width, advance_em)
        else:
            lines = core.estimate_lines(text, width, size, advance_em)
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
            name = props(shape)[1]
            box = box_of(shape)
            if box is None:
                continue
            if clipped(box[0] + box[2], width) or clipped(box[1] + box[3], height) or clipped(-box[0], 0.0) \
                    or clipped(-box[1], 0.0):
                out.append(finding("off-slide", "geometry", slide.name, f"{name!r} leaves the slide", "clipping"))
            if shape.find(P + "txBody") is not None and any(t.strip() for t in texts(shape)):
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
        scaling = chart["tree"].find(f".//{C}valAx/{C}scaling")
        bound_min = scaling.find(C + "min") if scaling is not None else None
        bound_max = scaling.find(C + "max") if scaling is not None else None
        if min(values) >= 0 and (bound_min is None or float(bound_min.get("val")) != 0.0):
            out.append(finding("axis-not-zero", "geometry", unit, "the value axis does not start at zero, so bar lengths "
                               "need not be proportional to the values", "misleading-encoding"))
        if max(values) <= 0 and (bound_max is None or float(bound_max.get("val")) != 0.0):
            out.append(finding("axis-not-zero", "geometry", unit, "the value axis does not end at zero",
                               "misleading-encoding"))
        bar = chart["tree"].find(f".//{C}barChart/{C}barDir")
        if bar is None or bar.get("val") != "bar":
            out.append(finding("encoding-changed", "geometry", unit, "the chart is not a bar chart", "misleading-encoding"))
    return out


def page_geometry(view, brief, composition, report=None):
    out = page_truncation(view.root)
    frozen = Frozen(brief, composition)
    for unit in dict.fromkeys(point["unit"] for point in frozen.data):
        section = view.sections.get(unit)
        marks = [node for node in section.iter() if node.tag == "rect" and "mark" in node.classes()] \
            if section is not None else []
        problems = baseline_problems(marks, frozen.content)
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

def chrome_and_citations(view, brief, composition, library):
    """Visible chrome is closed; each citation marker identifies its own frozen source URL."""
    content = core.Content(brief)
    sources = [content.sources[ref] for ref in content.source_order]
    out = []
    def marker(text, url):
        for match in re.finditer(r'\[([0-9]+)\]', text):
            index = int(match.group(1)) - 1
            if index < 0 or index >= len(sources) or (sources[index].get('url') and url != sources[index]['url']):
                out.append(finding('citation-substituted', 'fidelity', match.group(), 'citation does not link its frozen source'))
    if view.target == 'html':
        def walk(node, bound=False, url=None, register=False):
            if node.tag in ('head', 'style', 'title'):
                return
            register = register or (node.tag == 'li' and 'data-source' in node.attrs)
            bound = bound or 'data-copy' in node.attrs or 'data-value' in node.attrs
            url = node.attrs.get('href') if node.tag == 'a' else url
            for child in node.children:
                if isinstance(child, HtmlNode):
                    walk(child, bound, url, register)
                elif child.strip():
                    text = child.strip()
                    if not register:
                        marker(text, url)
                    if not bound and not re.fullmatch(r'\[[0-9]+\]', text) and text not in library['relationship_kinds']:
                        out.append(finding('invented-text', 'fidelity', None, 'page carries text outside frozen copy and chrome',
                                           'generation-residue'))
        walk(view.root)
        for node in view.root.iter():
            if node.tag == 'a' and node.attrs.get('data-source'):
                ref = node.attrs['data-source']
                source = content.sources.get(ref)
                if source is None or (source.get('url') and node.attrs.get('href') != source['url']):
                    out.append(finding('citation-substituted', 'fidelity', ref, 'source link targets another source'))
    else:
        for slide in view.slides:
            for shape, rels in [(s, slide.rels) for s in slide.shapes] + ([(slide.notes_body, slide.notes_rels)] if slide.notes_body is not None else []):
                name = props(shape)[1]
                for text, runs in paragraphs(shape):
                    for run, properties in runs:
                        link = link_of(properties, rels)
                        if not name.startswith("register:"):
                            marker(run, link[1] if link else None)
                    if shape is slide.notes_body or name.startswith(('copy:', 'value:', 'register:')):
                        continue
                    if name.startswith('cites:'):
                        allowed = all(re.fullmatch(r'\[[0-9]+\]', token) for token in text.split())
                    elif name.startswith('kind:'):
                        allowed = text in library['relationship_kinds']
                    else:
                        allowed = not text.strip()
                    if not allowed:
                        out.append(finding('invented-text', 'fidelity', slide.name,
                                           'shape carries text outside frozen copy and chrome',
                                           'generation-residue'))
        frozen = set(Frozen(brief, composition).strings())
        for slide in view.slides:
            for shape in slide.shapes:
                if shape.tag != P + 'pic':
                    continue
                node = shape.find(f'.//{P}cNvPr')
                description = (node.get('descr') or '').strip() if node is not None else ''
                if description in frozen and description:
                    out.append(finding('rasterised-copy', 'fidelity', slide.name,
                                       f'picture {props(shape)[1]!r} describes itself with frozen copy, so that copy '
                                       'is painted into an image rather than set as text', 'generation-residue'))
    return out


def copy_inventory(view, brief, composition):
    """Close the artifact's copy inventory over frozen bindings and source-register fields."""
    content = core.Content(brief)
    expected = {}
    for key, value in (brief.get('document') or {}).items():
        if key in ('title', 'subtitle') and isinstance(value, str) and value:
            expected[f'document#{key}'] = value
    for unit in composition['units']:
        for binding in unit.get('bindings', []):
            key = f"{binding['record_ref']}#{binding['field']}"
            value = content.field(binding['record_ref'], binding['field'])
            expected[key] = value
        for point in unit.get('data_bindings', []):
            expected[f"data:{point['data_ref']}#label"] = content.data(point['data_ref'])['label']
    if view.target == 'html':
        for binding in composition.get('document_bindings', []):
            expected[f"trailer#{binding['index']}"] = content.index.trailer[binding['index']]
        for unit in composition['units']:
            for ref in unit.get('register_refs', []):
                source = content.sources[ref]
                fields = ['raw'] if isinstance(source.get('raw'), str) else core.source_fields(source)
                for key in fields:
                    expected[f'source:{ref}#{key}'] = source[key]
    expanded = {}
    for key, value in expected.items():
        if isinstance(value, list):
            expanded.update({f'{key}#{i}': v for i, v in enumerate(value)})
        else:
            expanded[key] = value
    out = []
    if view.target == 'html':
        for key in sorted(set(expanded) | set(view.copy)):
            actual = view.copy.get(key, [])
            if key not in expanded or not actual or any(v != expanded[key] for v in actual):
                out.append(finding('copy-inventory', 'fidelity', key, 'copy differs from frozen bindings or source fields'))
    else:
        for slide in view.slides:
            for name, shapes in slide.named.items():
                if not name.startswith('copy:'):
                    continue
                key = name[len('copy:'):]
                value = expected.get(key, expanded.get(key))
                wanted = value if isinstance(value, list) else [value]
                if value is None or any(texts(shape) != wanted for shape in shapes):
                    out.append(finding('copy-inventory', 'fidelity', slide.name, 'copy object is unbound or altered'))
        numbers = {ref: i for i, ref in enumerate(content.source_order, 1)}
        for unit in composition['units']:
            if not unit.get('register_refs'):
                continue
            want = []
            for ref in unit['register_refs']:
                source = content.sources[ref]
                want.append(source['raw'] if isinstance(source.get('raw'), str) else
                            f'[{numbers[ref]}] ' + ' '.join(source[key] for key in core.source_fields(source)))
            slide = view.by_name.get(unit['id'])
            shapes = slide.named.get(f"register:{unit['id']}", []) if slide else []
            if len(shapes) != 1 or texts(shapes[0]) != want:
                out.append(finding('source-register', 'fidelity', unit['id'], 'source register prose differs from frozen sources'))
    return out


def package_integrity(pkg):
    """Validate content-type coverage and relationship references directly from OPC XML."""
    out = []
    types_ns = '{http://schemas.openxmlformats.org/package/2006/content-types}'
    if '[Content_Types].xml' not in pkg.parts:
        return [finding('package-content-type', 'fidelity', None, 'package has no content-type declarations')]
    types = pkg.tree('[Content_Types].xml')
    defaults = {n.get('Extension') for n in types if n.tag == types_ns + 'Default'}
    overrides = {n.get('PartName', '').lstrip('/') for n in types if n.tag == types_ns + 'Override'}
    if len(pkg.names) != len(set(pkg.names)):
        out.append(finding('package-duplicate', 'fidelity', None, 'package repeats a part'))
    for part in pkg.parts:
        if part == '[Content_Types].xml':
            continue
        if part not in overrides and (part.endswith('.xml') or part.rsplit('.', 1)[-1] not in defaults):
            out.append(finding('package-content-type', 'fidelity', part, 'part lacks its required content type'))
        if part.endswith('.xml'):
            rels = pkg.rels(part)
            for node in pkg.tree(part).iter():
                for key, value in node.attrib.items():
                    if key.startswith(R) and value not in rels:
                        out.append(finding('package-relationship', 'fidelity', part, f'XML references undeclared {value}'))
    for part in overrides - set(pkg.parts):
        out.append(finding('package-content-type', 'fidelity', part, 'content type names a missing part'))
    return out


def deck_semantics(view, composition, library):
    """Check semantic structure, not merely text that happens to survive beside a damaged figure."""
    out = []
    patterns = {p['id']: p for p in library['patterns']}
    for unit in composition['units']:
        slide = view.by_name.get(unit['id'])
        if slide is None:
            continue
        charts = [s for s in slide.shapes if kind_of(s) == 'chart']
        family = patterns[unit['pattern']]['family']
        if family == 'chart':
            chart = view.chart(unit['id'])
            if len(charts) != 1 or chart is None or len(chart['tree'].findall(f'.//{C}ser')) != 1:
                out.append(finding('chart-native', 'fidelity', unit['id'], 'a sourced chart needs exactly one native series'))
        elif charts:
            out.append(finding('chart-native', 'fidelity', unit['id'], 'unit carries an unbound chart'))
        if family != 'system':
            continue
        entity_ids = {}
        for entity in unit.get('entities', []):
            name = f"copy:{entity['record_ref']}#{entity['field']}"
            if 'item' in entity:
                name += f"#{entity['item']}"
            nodes = slide.named.get(name, [])
            if len(nodes) == 1 and nodes[0].tag == P + 'sp':
                entity_ids[entity['id']] = props(nodes[0])[0]
        expected = [(entity_ids.get(r['from']), entity_ids.get(r['to'])) for r in unit.get('relationships', [])]
        actual = []
        for connector in (s for s in slide.shapes if s.tag == P + 'cxnSp'):
            start, end = connector.find(f'.//{A}stCxn'), connector.find(f'.//{A}endCxn')
            actual.append((start.get('id') if start is not None else None, end.get('id') if end is not None else None))
        if len(entity_ids) != len(unit.get('entities', [])) or actual != expected:
            out.append(finding('system-semantics', 'fidelity', unit['id'], 'connectors do not join the frozen entities in order'))
    return out


def fidelity(target, data, brief, composition, theme, manifest=None):
    """Structural fidelity from delivered facts and frozen inputs. Preservation, accessibility and
    geometry are graded separately; none of these results comes from the renderer's check layer."""
    view = view_of(target, data)
    library, _ = core.validator.load_library(core.validator.DEFAULT_LIBRARY)
    patterns = {p['id']: p for p in library['patterns']}
    out = copy_inventory(view, brief, composition) + chrome_and_citations(view, brief, composition, library)
    if target == 'html':
        ids = {node.attrs['id'] for node in view.root.iter() if node.attrs.get('id')}
        for node in view.root.iter():
            if node.tag == 'script' or any(key.startswith('on') for key in node.attrs):
                out.append(finding('active-content', 'fidelity', None, 'page carries executable content'))
            for key, value in node.attrs.items():
                if not isinstance(value, str):
                    continue
                if key == 'href' and node.tag == 'a':
                    if value.startswith('#') and value[1:] not in ids:
                        out.append(finding('local-reference', 'fidelity', value, 'anchor target is absent'))
                elif key in ('src', 'href', 'srcset', 'poster', 'xlink:href') and not value.startswith('data:'):
                    out.append(finding('remote-asset', 'fidelity', value, 'page loads an external resource'))
        styles = '\n'.join(n.text() for n in view.root.iter() if n.tag == 'style')
        components = styles.split('/* design-render: components */', 1)
        if len(components) != 2:
            out.append(finding('token-block', 'fidelity', None, 'page omits component style declarations'))
        elif re.search(r'#[0-9a-fA-F]{3,8}\b|\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch)\s*\(|font-family\s*:(?!\s*var\()', components[1], re.I):
            out.append(finding('css-literal', 'fidelity', None, 'component CSS overrides the declared theme tokens'))
        if theme.css not in styles:
            out.append(finding('token-block', 'fidelity', None, 'page omits the frozen theme token block'))
        for unit in composition['units']:
            section = view.sections.get(unit['id'])
            if section is None:
                continue  # preservation already identifies missing units
            if section.attrs.get('data-pattern') != unit['pattern']:
                out.append(finding('pattern-changed', 'fidelity', unit['id'], 'page pattern differs from composition'))
            if patterns[unit['pattern']]['family'] == 'register':
                refs = [n.attrs['data-source'] for n in section.iter() if n.tag == 'li' and 'data-source' in n.attrs]
                if refs != unit.get('register_refs', []):
                    out.append(finding('register-order', 'fidelity', unit['id'], 'source register differs from composition'))
        return out

    out += package_integrity(view.pkg)
    out += deck_semantics(view, composition, library)
    expected_order = [u['id'] for u in composition['units']]
    document = brief.get('document') or {}
    if any(document.get(k) for k in ('title', 'subtitle')):
        expected_order.insert(0, 'document')
    if [s.name for s in view.slides] != expected_order:
        out.append(finding('slide-order', 'fidelity', None, 'slide list differs from the frozen document and units'))
    for part in view.pkg.parts:
        if not part.endswith('.xml'):
            continue
        for rid, rel in view.pkg.rels(part).items():
            if not rel['external'] and rel['resolved'] not in view.pkg.parts:
                out.append(finding('package-relationship', 'fidelity', part, f'{rid} targets a missing part'))
        for node in view.pkg.tree(part).iter():
            if node.tag == A + 'normAutofit' or 'fontScale' in node.attrib:
                out.append(finding('autofit', 'fidelity', part, 'package shrinks text', 'unreadable-text'))

    # Derive each copy object's size floor from the binding slot and the pattern minimum. Never
    # accept the manifest's claimed floor as the expected value.
    def size(role):
        return round(theme.px('typography', core.TYPE_ROLE_TOKENS[role][0]) * 75)
    floors = {'document': {'copy:document#title': size('type.display'),
                           'copy:document#subtitle': size('type.lead')}}
    for unit in composition['units']:
        pattern = patterns[unit['pattern']]
        def floor(slot):
            role = core.SLOT_ROLES.get(slot, 'type.body')
            minimum = unit.get('type_floor', pattern['constraints']['min_type_role'])
            if slot not in core.ASIDE_SLOTS:
                role = max((role, minimum), key=library['type_scale'].index)
            return size(role)
        names = {f"copy:{b['record_ref']}#{b['field']}": floor(b['slot']) for b in unit.get('bindings', [])}
        for point in unit.get('data_bindings', []):
            names[f"copy:data:{point['data_ref']}#label"] = floor('series')
            names[f"value:{point['data_ref']}"] = floor('series')
        names[f"register:{unit['id']}"] = floor('evidence')
        floors[unit['id']] = names
    manifest_slides = manifest.get('slides', []) if isinstance(manifest, dict) else []
    if manifest is not None and len(manifest_slides) != len(view.slides):
        out.append(finding('manifest-object', 'fidelity', None, 'manifest slide count differs from package'))
    for index, slide in enumerate(view.slides):
        sizes = floors.get(slide.name, {})
        for shape in slide.shapes + ([slide.notes_body] if slide.notes_body is not None else []):
            name = props(shape)[1]
            stem = re.sub(r'#[0-9]+$', '', name)
            minimum = size('type.body') if shape is slide.notes_body else sizes.get(name, sizes.get(stem, size('type.caption')))
            for node in shape.iter():
                if node.tag in (A + 'rPr', A + 'defRPr', A + 'endParaRPr') and node.get('sz'):
                    if int(node.get('sz')) < minimum:
                        out.append(finding('readability', 'fidelity', slide.name,
                                           f'{name} has a run below its frozen type-role floor', 'unreadable-text'))
        if manifest is not None and index < len(manifest_slides):
            entry = manifest_slides[index]
            observed = {(props(s)[0], props(s)[1]) for s in slide.shapes}
            recorded = {(str(o.get('shape_id')), o.get('name')) for o in entry.get('objects', [])}
            if entry.get('part') != slide.part or entry.get('name') != slide.name or observed != recorded:
                out.append(finding('manifest-object', 'fidelity', slide.name, 'manifest objects differ from package'))
            for shape in slide.shapes:
                item = next((o for o in entry.get('objects', []) if str(o.get('shape_id')) == props(shape)[0]), {})
                native = shape.tag != P + 'pic'
                if item.get('editable') is not native:
                    out.append(finding('manifest-object', 'fidelity', slide.name, 'manifest editability differs from object'))
    return out


# --- the report --------------------------------------------------------------------------------------

def review_units(target, data):
    """Every delivered slide, including generated covers; HTML has one entry per unit section."""
    view = view_of(target, data)
    return [slide.name for slide in view.slides] if target == "pptx" else view.order


def review_for(record, brand, target, artifact_sha, units):
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
    if sorted(e.get("unit", "") for e in entries) != sorted(units) or len(overviews) != 1:
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
        checks["review"], found = review_for(review, brand, target, artifact_sha, review_units(target, data))
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
                    for node in unit_sections(parse_html(data.decode("utf-8"))) if node.attrs.get("id")}
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
