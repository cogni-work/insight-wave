"""PPTX target adapter of design-render: one editable PowerPoint package from a laid-out plan.

Stdlib only. The package is written directly as Office Open XML — no presentation library, no
HTML step and no runtime: slide text is native text in text frames, a conceptual system is native
shapes joined by connectors, the sourced chart is a native bar chart whose data lives in an embedded
workbook, speaker notes go on notes slides and every citation is a hyperlink relationship.

Every original string — a headline, a point, a note, a label, a value, a unit, a source field —
reaches the package through `xml_text()`, once, as escaped text: never rewritten, trimmed, split
across units or shrunk to fit. A frame that does not fit the fixed slide fails as `fit-overflow`
instead; copy the package cannot carry fails as `unsupported-content`. The writer records every
object it places in a pptx-manifest@1. references/design-render.md is the normative description;
pptx_checks.py grades the result independently.

The one exception to native objects is a picture its unit's variant declares as a pptx fallback in the
pattern library: an SVG drawing carried behind a stdlib-drawn PNG, recorded in the manifest as a
non-editable image with the library's declaration. It never carries copy.
"""

import io
import re
import struct
import sys
import zipfile
import zlib
from xml.sax.saxutils import escape

import render_core as core

CITATION = re.compile(r"\[([0-9]+)\]")
# XML 1.0 admits tab, line feed and these ranges; anything else cannot be written as text. A carriage
# return is legal XML but a parser folds it into a line feed, so it would not survive a round trip.
XML_ILLEGAL = re.compile("[\x00-\x08\x0b-\x1f\ud800-\udfff\ufffe\uffff]")
ATTR_ENTITIES = {'"': "&quot;"}

EMU_PER_PX = 9525
SLIDE_CX = core.CANVAS["width"] * EMU_PER_PX
SLIDE_CY = core.CANVAS["height"] * EMU_PER_PX
NOTES_CX, NOTES_CY = 6858000, 9144000
ZIP_TIME = (1980, 1, 1, 0, 0, 0)
WRITER_NAME = "cogni-publishing/design-render"
ARTIFACT = "deck.pptx"
MANIFEST = "pptx-manifest.json"
CONNECTOR_CX = 12700  # a right-side-to-right-side elbow is drawn in a sliver box, as PowerPoint does

NS = ('xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"')
NS_C = "http://schemas.openxmlformats.org/drawingml/2006/chart"
DECL = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
PKG_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
CT = "application/vnd.openxmlformats-officedocument."
LANGUAGE_REGIONS = {"en": "en-US", "de": "de-DE", "fr": "fr-FR", "it": "it-IT", "pl": "pl-PL", "nl": "nl-NL",
                    "es": "es-ES"}
# Slot colours as scheme colours, so the deck restyles with its theme: tx1 is the text token, tx2 the
# muted text token (see theme_xml for the full mapping).
MUTED_SLOTS = {"evidence"}
REQUIRED_COLOURS = ("text", "bg", "surface", "accent", "text-muted", "border")
# A declared picture fallback: the SVG rides in the blip's extension list, behind a PNG any reader shows.
SVG_BLIP_EXT = "{96DAC541-7B7A-43D3-8B79-37D633B846F1}"
NS_ASVG = "http://schemas.microsoft.com/office/drawing/2016/SVG/main"
NS_SVG = "http://www.w3.org/2000/svg"
PNG_SCALE = 2  # raster pixels per canvas px
TRACK_STROKE = 2.0
TRACK_HEAD = 8.0


def xml_text(value):
    return escape(value)


def xml_attr(value):
    return escape(str(value), ATTR_ENTITIES)


def emu(px):
    return int(round(px * EMU_PER_PX))


def size_100pt(px):
    """A px size (96 per inch on the 1280 x 720 canvas) in the hundredths of a point OOXML counts."""
    return int(round(px * 75))


def language_tag(language):
    return LANGUAGE_REGIONS.get(language, language)


# --- guards that run before anything is written -------------------------------------------------------

def hex_colour(value, token):
    text = str(value).strip()
    if re.fullmatch(r"#[0-9A-Fa-f]{6}", text):
        return text[1:].upper()
    if re.fullmatch(r"#[0-9A-Fa-f]{3}", text):
        return "".join(ch * 2 for ch in text[1:]).upper()
    raise core.RenderError("invalid-theme", f"token {token} is {text!r}; the PPTX target writes theme colours as "
                           "#RRGGBB or #RGB hex", "theme-token-unit", token, artifact="theme")


def theme_colours(theme):
    return {key: hex_colour(theme.value("colors", key), f"colors.{key}") for key in REQUIRED_COLOURS}


def office_typeface(font):
    """The Office typeface a resolved face is written as. PowerPoint names fonts, it has no generic
    families, so each generic family documents the typeface Office ships for it."""
    fallbacks = core.load_fallbacks()
    if font["source"] == "bundled":
        return font["resolved_face"]
    return fallbacks["generic_families"][font["resolved_face"]]["pptx_typeface"]


def bound_strings(brief, composition):
    """(key, string) for every original string the deck will carry."""
    content = core.Content(brief)
    for unit in composition["units"]:
        for binding in unit.get("bindings", []):
            value = content.field(binding["record_ref"], binding["field"])
            key = f"{binding['record_ref']}#{binding['field']}"
            for i, item in enumerate(value if isinstance(value, list) else [value]):
                yield (f"{key}#{i}" if isinstance(value, list) else key), item
        for point in unit.get("data_bindings", []):
            item = content.data(point["data_ref"])
            yield f"data:{item['id']}#label", item["label"]
            yield f"data:{item['id']}#value", f"{core.number_text(item['value'])} {item['unit']}"
        for ref in unit.get("register_refs", []):
            source = content.sources[ref]
            yield f"source:{ref}", core.source_line(source)
    for binding in composition.get("document_bindings", []):
        yield f"trailer#{binding['index']}", content.index.trailer[binding["index"]]
    document = brief.get("document") or {}
    for key in ("title", "subtitle"):
        if isinstance(document.get(key), str) and document[key]:
            yield f"document#{key}", document[key]


def check_content(brief, composition):
    for key, value in bound_strings(brief, composition):
        if not isinstance(value, str):
            continue
        hit = XML_ILLEGAL.search(value)
        if hit:
            raise core.RenderError("unsupported-content", f"{key} carries U+{ord(hit.group(0)):04X}, which a PPTX "
                                   "package cannot hold as text; fix the brief rather than dropping the character",
                                   "content", key, artifact="normalized_brief")


def one_line(layout, text, width, role):
    size, _ = layout.metrics(role)
    return core.estimate_lines(text, width, size, layout.font["advance_em"]) == 1


def check_fit(brief, composition, plan, theme, font, library):
    """A slide is a fixed 1280 x 720 px frame. A unit the plan had to grow past it, a series value that
    would wrap out of its row, or a chart whose rows or a system whose nodes outgrow their box fails
    here; the adapter never shrinks type, splits, merges, truncates or reorders a unit to make it fit.
    A series label may wrap: it wraps in its label column, on the taller row the plan measured for it."""
    layout = core.Layout(theme, font, library)
    content = core.Content(brief)
    height = core.CANVAS["height"]
    for unit, plan_unit in zip(composition["units"], plan["units"]):
        if plan_unit["frame"]["height"] > height + 0.5:
            raise core.RenderError("fit-overflow", f"unit {unit['id']} needs a {plan_unit['frame']['height']} px frame; "
                                   f"a slide is {height} px and the PPTX target never shrinks or splits a unit",
                                   "fit", unit["id"], artifact="target_resolved_plan")
        for slot in plan_unit["slots"]:
            if slot["slot"] == "series":
                geometry = chart_geometry(slot["box"])
                rows, bottom = chart_rows(layout, content, slot, slot["content"])
                for item, _, _ in rows:
                    value = f"{core.number_text(item['value'])} {item['unit']}"
                    if not one_line(layout, value, geometry["value_w"], slot["type_role"]):
                        raise core.RenderError("fit-overflow", f"the value of series point {item['id']} of {unit['id']} "
                                               "does not fit one line of its chart row", "fit",
                                               f"{unit['id']}/{item['id']}", artifact="target_resolved_plan")
                if bottom > slot["box"]["y"] + slot["box"]["height"] + 0.5:
                    raise core.RenderError("fit-overflow", f"the chart rows of {unit['id']} outgrow their box",
                                           "fit", unit["id"], artifact="target_resolved_plan")
            if slot["slot"] == "entities":
                nodes, bottom = system_nodes(layout, content, unit, slot)
                if bottom > slot["box"]["y"] + slot["box"]["height"] + 0.5:
                    raise core.RenderError("fit-overflow", f"the system nodes of {unit['id']} outgrow their box",
                                           "fit", unit["id"], artifact="target_resolved_plan")
    document = document_strings(brief)
    if document and cover_bottom(layout, document) > height - layout.padding + 0.5:
        raise core.RenderError("fit-overflow", "the document title and subtitle do not fit the cover slide",
                               "fit", "document", artifact="normalized_brief")


def document_strings(brief):
    document = brief.get("document") or {}
    return [(key, document[key]) for key in ("title", "subtitle")
            if isinstance(document.get(key), str) and document[key]]


def chart_geometry(box):
    """A chart's columns across its series box: render_core's label column, the band of marks right of
    it, then the value column."""
    width = box["width"]
    column, bar_w = core.chart_label_column(width), width * core.CHART_BAR_SHARE
    return {"label_w": core.chart_label_width(width), "bar_x": box["x"] + column, "bar_w": bar_w,
            "value_x": box["x"] + column + bar_w + 8, "value_w": width - column - bar_w - 8}


def chart_rows(layout, content, slot, entries):
    """(item, y, height) for each chart point, stacked from the top of the series box: every point gets
    the row the plan measured for the chart, as tall as its tallest label, which wraps in the label
    column — so each row is one of the equal category bands the native chart spreads over the box."""
    box = slot["box"]
    items = [content.data(entry["data_ref"]) for entry in entries]
    shared = core.series_rows(layout, [item["label"] for item in items], box["width"], slot["type_role"])
    rows, y = [], box["y"]
    for item, (_, height) in zip(items, shared):
        rows.append((item, y, height))
        y += height
    return rows, y


def system_nodes(layout, content, unit, slot):
    """Node boxes for a conceptual system, stacked in the entities box with a lane to their right for
    the connectors, each as tall as the plan measured its label at the node text width."""
    box = slot["box"]
    node_w = core.node_width(box["width"])
    text_w = core.node_text_width(layout, box["width"])
    nodes, y = [], box["y"]
    for entity in unit.get("entities", []):
        value = content.field(entity["record_ref"], entity["field"])
        label = value[entity["item"]] if "item" in entity else value
        key = f"{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
        lines, node_h = core.node_box(layout, label, box["width"], slot["type_role"])
        nodes.append({"entity": entity, "key": key, "label": label, "lines": lines, "x": box["x"], "y": y,
                      "w": node_w, "h": node_h, "text_w": text_w})
        y += node_h + layout.gap
    return nodes, (y - layout.gap if nodes else box["y"])


# --- a declared picture fallback ------------------------------------------------------------------

def variant_fallback(library, unit, target="pptx"):
    """The fallback the unit's variant declares for `target` in the pattern library, or None."""
    for pattern in library["patterns"]:
        if pattern["id"] == unit["pattern"]:
            for variant in pattern["variants"]:
                fallback = variant.get("fallback") if variant["id"] == unit["variant"] else None
                if isinstance(fallback, dict) and fallback.get("target") == target:
                    return fallback
    return None


def track_box(nodes):
    """The picture box of a loop's return track, in canvas px: the gutter left of the nodes, from the
    first node's middle to the last one's, with room for the arrowhead. Local coordinates put the
    track's rail on the left edge and both ends on the right edge, where the nodes begin."""
    first, last = nodes[0], nodes[-1]
    right = first["x"]
    left = right * 0.35
    top = first["y"] + first["h"] / 2 - TRACK_HEAD
    bottom = last["y"] + last["h"] / 2 + TRACK_HEAD
    return {"x": left, "y": top, "w": right - left, "h": bottom - top,
            "y_first": TRACK_HEAD, "y_last": bottom - top - TRACK_HEAD}


def track_svg(box, colour):
    """The authoritative drawing: a rail from the last node back up to the first, ending in an
    arrowhead on the first node. It carries no text."""
    w, h = round(box["w"], 2), round(box["h"], 2)
    rail = TRACK_STROKE
    yf, yl = round(box["y_first"], 2), round(box["y_last"], 2)
    tip_base = round(w - TRACK_HEAD, 2)
    half = TRACK_HEAD / 2
    return (f'{DECL}<svg xmlns="{NS_SVG}" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'<path d="M {w} {yl} H {rail} V {yf} H {tip_base}" fill="none" stroke="#{colour}" '
            f'stroke-width="{TRACK_STROKE}"/>'
            f'<path d="M {tip_base} {round(yf - half, 2)} L {w} {yf} L {tip_base} {round(yf + half, 2)} Z" '
            f'fill="#{colour}"/></svg>')


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def track_png(box, colour):
    """The raster primary: the same rail and arrowhead drawn at PNG_SCALE pixels per canvas px into an
    8-bit RGBA image, opaque in the theme colour and transparent elsewhere. It is an approximation —
    no antialiasing, pixel-snapped strokes — of the SVG, which stays the authoritative drawing."""
    scale = PNG_SCALE
    width, height = max(1, int(round(box["w"] * scale))), max(1, int(round(box["h"] * scale)))
    ink = bytes(int(colour[i:i + 2], 16) for i in (0, 2, 4)) + b"\xff"
    clear = b"\x00\x00\x00\x00"
    stroke = max(1, int(round(TRACK_STROKE * scale)))
    rail = int(round(TRACK_STROKE * scale / 2))
    yf, yl = box["y_first"] * scale, box["y_last"] * scale
    head, half = TRACK_HEAD * scale, TRACK_HEAD * scale / 2
    tip_base = width - head
    rows = []
    for py in range(height):
        cy = py + 0.5
        row = bytearray(clear * width)

        def paint(x0, x1):
            for px in range(max(0, int(x0)), min(width, int(round(x1)))):
                row[px * 4:px * 4 + 4] = ink
        if abs(cy - yl) <= stroke / 2:
            paint(rail - stroke / 2, width)
        if abs(cy - yf) <= stroke / 2:
            paint(rail - stroke / 2, tip_base)
        if yf - stroke / 2 <= cy <= yl + stroke / 2:
            paint(rail - stroke / 2, rail + stroke / 2)
        if abs(cy - yf) <= half:
            paint(tip_base, tip_base + head * (1 - abs(cy - yf) / half))
        rows.append(b"\x00" + bytes(row))
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", header)
            + png_chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + png_chunk(b"IEND", b""))


# --- relationships and parts ------------------------------------------------------------------------

class Rels:
    def __init__(self):
        self.items = []

    def add(self, kind, target, external=False):
        for rid, k, t, e in self.items:
            if (k, t, e) == (kind, target, external):
                return rid
        rid = f"rId{len(self.items) + 1}"
        self.items.append((rid, kind, target, external))
        return rid

    def xml(self):
        body = "".join(
            f'<Relationship Id="{rid}" Type="{kind}" Target="{xml_attr(target)}"'
            f'{" TargetMode=" + chr(34) + "External" + chr(34) if external else ""}/>'
            for rid, kind, target, external in self.items)
        return f'{DECL}<Relationships xmlns="{PKG_REL}">{body}</Relationships>'


def group_root():
    return ('<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm>'
            '<a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm>'
            '</p:grpSpPr>')


def xfrm(x, y, w, h, flip_v=False):
    flip = ' flipV="1"' if flip_v else ""
    return (f'<a:xfrm{flip}><a:off x="{emu(x)}" y="{emu(y)}"/><a:ext cx="{max(emu(w), 0)}" cy="{max(emu(h), 0)}"/>'
            '</a:xfrm>')


# --- the deck ---------------------------------------------------------------------------------------

class Part:
    """One slide or notes slide: its shapes, relationships and manifest objects."""

    def __init__(self, deck, kind):
        self.deck = deck
        self.kind = kind
        self.rels = Rels()
        self.shapes = []
        self.objects = []
        self.next_id = 2

    def shape_id(self):
        sid = self.next_id
        self.next_id += 1
        return sid


class Deck:
    def __init__(self, brief, composition, plan, theme, font, fonts, language, library):
        self.brief = brief
        self.composition = composition
        self.plan = plan
        self.theme = theme
        self.font = font
        self.fonts = fonts
        self.language = language_tag(language)
        self.library = library
        self.content = core.Content(brief)
        self.layout = core.Layout(theme, font, library)
        self.colours = theme_colours(theme)
        self.typeface = office_typeface(font)
        self.families = {pattern["id"]: pattern["family"] for pattern in library["patterns"]}
        self.markers = {source.get("marker"): source for source in self.content.sources.values()
                        if isinstance(source.get("marker"), str)}
        self.register_numbers = {source_id: position for position, source_id in
                                 enumerate(self.content.source_order, 1)}
        self.min_sz = size_100pt(theme.px("typography", "size-small"))
        self.charts = []  # (chart xml, workbook bytes, unit id)
        self.media = []  # (part path, bytes, asset kind, unit id)
        self.fallbacks = []  # the manifest objects of every declared fallback picture, in slide order
        self.document = document_strings(brief)
        self.slide_names = (["document"] if self.document else []) + [unit["id"] for unit in composition["units"]]
        registers = [unit["id"] for unit in composition["units"] if self.families[unit["pattern"]] == "register"]
        self.register_slide = self.slide_names.index(registers[-1]) + 1 if registers else None

    # --- text ---------------------------------------------------------------------------------------

    def rpr(self, px, colour, part=None, link=None):
        hlink = ""
        if link is not None:
            target, internal = link
            if internal:
                rid = part.rels.add(REL + "slide", target)
                hlink = f'<a:hlinkClick r:id="{rid}" action="ppaction://hlinksldjump"/>'
            else:
                rid = part.rels.add(REL + "hyperlink", target, external=True)
                hlink = f'<a:hlinkClick r:id="{rid}"/>'
        face = xml_attr(self.typeface)
        return (f'<a:rPr lang="{xml_attr(self.language)}" sz="{size_100pt(px)}" dirty="0"><a:solidFill>'
                f'<a:schemeClr val="{colour}"/></a:solidFill><a:latin typeface="{face}"/><a:ea typeface="{face}"/>'
                f'<a:cs typeface="{face}"/>{hlink}</a:rPr>')

    def source_link(self, source, part):
        url = source.get("url")
        if isinstance(url, str) and url:
            return url, False
        prefix = "" if part.kind == "slide" else "../slides/"
        return f"{prefix}slide{self.register_slide}.xml", True

    def runs(self, value, px, colour, part, citations=True):
        """The runs of one original string: `[N]` markers become hyperlink runs on the marker itself, a
        line feed becomes a line break, and nothing else changes."""
        out = []
        for index, line in enumerate(value.split("\n")):
            if index:
                out.append(f"<a:br>{self.rpr(px, colour)}</a:br>")
            last = 0
            for match in (CITATION.finditer(line) if citations else ()):
                source = self.markers.get(match.group(0))
                if source is None:
                    raise core.RenderError("unresolved-citation", f"the marker {match.group(0)} names no source record",
                                           "citation", match.group(0), artifact="normalized_brief")
                if match.start() > last:
                    out.append(f"<a:r>{self.rpr(px, colour)}<a:t>{xml_text(line[last:match.start()])}</a:t></a:r>")
                out.append(f"<a:r>{self.rpr(px, colour, part, self.source_link(source, part))}"
                           f"<a:t>{xml_text(match.group(0))}</a:t></a:r>")
                last = match.end()
            if last < len(line):
                out.append(f"<a:r>{self.rpr(px, colour)}<a:t>{xml_text(line[last:])}</a:t></a:r>")
        return "".join(out)

    def paragraph(self, runs, px, ratio, space_before=0.0, bullet=False, align=None):
        spacing = f'<a:lnSpc><a:spcPts val="{int(round(px * ratio * 75))}"/></a:lnSpc>'
        if space_before:
            spacing += f'<a:spcBef><a:spcPts val="{int(round(space_before * 75))}"/></a:spcBef>'
        if bullet:
            indent = emu(self.layout.item_gap * 1.5)
            attrs = f' marL="{indent}" indent="-{indent}"'
            marks = f'<a:buFont typeface="{xml_attr(self.typeface)}"/><a:buChar char="&#8226;"/>'
        else:
            attrs, marks = "", "<a:buNone/>"
        if align:
            attrs += f' algn="{align}"'
        end = (f'<a:endParaRPr lang="{xml_attr(self.language)}" sz="{size_100pt(px)}" dirty="0"/>')
        return f"<a:p><a:pPr{attrs}>{spacing}{marks}</a:pPr>{runs}{end}</a:p>"

    def text_body(self, paragraphs, inset=0.0, anchor="t", wrap="square"):
        pad = emu(inset)
        return (f'<p:txBody><a:bodyPr wrap="{wrap}" lIns="{pad}" tIns="{pad}" rIns="{pad}" bIns="{pad}" rtlCol="0" '
                f'anchor="{anchor}"><a:noAutofit/></a:bodyPr><a:lstStyle/>{"".join(paragraphs)}</p:txBody>')

    def shape(self, part, name, box, body="", geometry="rect", fill=None, line=None, text_box=True, kind="text",
              capability="text-frame", copy_keys=(), unit=None):
        sid = part.shape_id()
        x, y, w, h = box
        fill_xml = f'<a:solidFill><a:schemeClr val="{fill}"/></a:solidFill>' if fill else "<a:noFill/>"
        line_xml = (f'<a:ln w="9525"><a:solidFill><a:schemeClr val="{line}"/></a:solidFill></a:ln>' if line
                    else "<a:ln><a:noFill/></a:ln>")
        marker = ' txBox="1"' if text_box else ""
        part.shapes.append(
            f'<p:sp><p:nvSpPr><p:cNvPr id="{sid}" name="{xml_attr(name)}"/><p:cNvSpPr{marker}/><p:nvPr/></p:nvSpPr>'
            f'<p:spPr>{xfrm(x, y, w, h)}<a:prstGeom prst="{geometry}"><a:avLst/></a:prstGeom>{fill_xml}{line_xml}'
            f'</p:spPr>{body}</p:sp>')
        part.objects.append({"shape_id": sid, "name": name, "kind": kind, "editable": True, "capability": capability,
                             "copy_keys": list(copy_keys), "fallback": None})
        return sid

    def copy_shape(self, part, key, values, box, role, colour, bullet=False, inset=0.0, **extra):
        """One text frame per copy key; a list field keeps one paragraph per item."""
        px, ratio = self.layout.metrics(role)
        paragraphs = [self.paragraph(self.runs(value, px, colour, part), px, ratio,
                                     self.layout.item_gap if index and bullet else 0.0, bullet)
                      for index, value in enumerate(values)]
        keys = [f"{key}#{i}" for i in range(len(values))] if bullet else [key]
        return self.shape(part, f"copy:{key}", box, self.text_body(paragraphs, inset), copy_keys=keys, **extra)

    # --- slots --------------------------------------------------------------------------------------

    def blocks(self, part, entries, box, role, colour):
        y = box["y"]
        for entry in entries:
            value = self.content.field(entry["record_ref"], entry["field"])
            key = f"{entry['record_ref']}#{entry['field']}"
            values = list(value) if isinstance(value, list) else [value]
            _, height = self.layout.text_block(values, box["width"], role)
            self.copy_shape(part, key, values, (box["x"], y, box["width"], height), role, colour,
                            bullet=isinstance(value, list))
            y += height + self.layout.item_gap
        return y

    def comparison(self, part, unit, slot):
        box, role = slot["box"], slot["type_role"]
        items = []
        for entry in slot["content"]:
            value = self.content.field(entry["record_ref"], entry["field"])
            key = f"{entry['record_ref']}#{entry['field']}"
            if isinstance(value, list):
                items.extend((f"{key}#{i}", item) for i, item in enumerate(value))
            else:
                items.append((key, value))
        rule = 3.0
        if unit["variant"] == "tabular":
            y = box["y"]
            for key, value in items:
                _, height = self.layout.text_block([value], box["width"], role)
                self.shape(part, f"rule:{key}", (box["x"] - 12, y, rule, height), fill="accent1", text_box=False,
                           kind="shape", capability="editable-shapes")
                self.copy_shape(part, key, [value], (box["x"], y, box["width"], height), role, "tx1")
                y += height + self.layout.item_gap
            return
        columns = max(1, len(items))
        width = (box["width"] - (columns - 1) * self.layout.gap) / columns
        for index, (key, value) in enumerate(items):
            x = box["x"] + index * (width + self.layout.gap)
            self.shape(part, f"rule:{key}", (x, box["y"] - 8, width, rule), fill="accent1", text_box=False,
                       kind="shape", capability="editable-shapes")
            self.copy_shape(part, key, [value], (x, box["y"], width, box["height"]), role, "tx1")

    def data_table(self, unit, slot, entries):
        """The chart's text alternative: each point's own label and its literal value with its unit, on
        the row the plan measured for the chart, as native text. The label frame is exactly the chart
        label width wide with no inset, so the frame wraps the label where the plan did; the label stays
        one paragraph, never split into the planned lines, so its copy is unchanged."""
        part = self.current
        px, ratio = self.layout.metrics(slot["type_role"])
        geometry = chart_geometry(slot["box"])
        box = slot["box"]
        rows, _ = chart_rows(self.layout, self.content, slot, entries)
        for item, y, height in rows:
            label = self.paragraph(self.runs(item["label"], px, "tx1", part, citations=False), px, ratio)
            self.shape(part, f"copy:data:{item['id']}#label", (box["x"], y, geometry["label_w"], height),
                       self.text_body([label], anchor="ctr", wrap="square"), copy_keys=[f"data:{item['id']}#label"])
            value = f"{core.number_text(item['value'])} {item['unit']}"
            text = self.paragraph(self.runs(value, px, "tx1", part, citations=False), px, ratio)
            self.shape(part, f"value:{item['id']}", (geometry["value_x"], y, geometry["value_w"], height),
                       self.text_body([text], anchor="ctr", wrap="none"), copy_keys=[f"data:{item['id']}#value"])
        return ""

    def native_chart(self, unit, slot, entries):
        """The one native chart per sourced-chart unit: a bar chart whose categories are the brief's
        labels and whose values are its literal numbers, backed by an embedded workbook that carries the
        same labels, values and unit."""
        part = self.current
        items = [self.content.data(entry["data_ref"]) for entry in entries]
        geometry = chart_geometry(slot["box"])
        number = len(self.charts) + 1
        units = list(dict.fromkeys(item["unit"] for item in items))
        self.charts.append((chart_xml(items, units[0]), workbook(items, units[0]), unit["id"]))
        rid = part.rels.add(REL + "chart", f"../charts/chart{number}.xml")
        sid = part.shape_id()
        box = slot["box"]
        part.objects.append({"shape_id": sid, "name": f"chart:{unit['id']}", "kind": "chart", "editable": True,
                             "capability": "native-chart", "copy_keys": [], "data_refs": [i["id"] for i in items],
                             "fallback": None})
        return (f'<p:graphicFrame><p:nvGraphicFramePr><p:cNvPr id="{sid}" name="{xml_attr("chart:" + unit["id"])}" '
                f'descr="{xml_attr(self.variant_purpose(unit))}"/>'
                f'<p:cNvGraphicFramePr/><p:nvPr/></p:nvGraphicFramePr><p:xfrm><a:off x="{emu(geometry["bar_x"])}" '
                f'y="{emu(box["y"])}"/><a:ext cx="{emu(geometry["bar_w"])}" cy="{emu(box["height"])}"/></p:xfrm>'
                f'<a:graphic><a:graphicData uri="{NS_C}"><c:chart xmlns:c="{NS_C}" r:id="{rid}"/></a:graphicData>'
                f'</a:graphic></p:graphicFrame>')

    def variant_purpose(self, unit):
        """The text alternative of a figure object — the chart frame, a declared fallback picture: the unit's
        variant purpose from the pattern library, never copy, so no frozen string is restated in an
        attribute."""
        return next(variant["purpose"] for pattern in self.library["patterns"] if pattern["id"] == unit["pattern"]
                    for variant in pattern["variants"] if variant["id"] == unit["variant"])

    def return_track(self, part, unit, nodes, fallback):
        """The declared picture fallback of a loop: its return track as one picture in the gutter left of
        the nodes — a PNG primary blip, with the SVG drawing in the blip's extension list. Its text
        alternative is the variant's purpose from the library, never copy."""
        box = track_box(nodes)
        colour = self.colours["accent"]
        number = len(self.media) + 1
        png_path, svg_path = f"ppt/media/image{number}.png", f"ppt/media/image{number + 1}.svg"
        self.media.append((png_path, track_png(box, colour), "fallback-raster", unit["id"]))
        self.media.append((svg_path, track_svg(box, colour), "fallback-vector", unit["id"]))
        png_rid = part.rels.add(REL + "image", "../media/" + png_path.rsplit("/", 1)[1])
        svg_rid = part.rels.add(REL + "image", "../media/" + svg_path.rsplit("/", 1)[1])
        purpose = self.variant_purpose(unit)
        sid = part.shape_id()
        name = f"figure:{unit['id']}"
        part.shapes.append(
            f'<p:pic><p:nvPicPr><p:cNvPr id="{sid}" name="{xml_attr(name)}" descr="{xml_attr(purpose)}"/>'
            '<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>'
            f'<p:blipFill><a:blip r:embed="{png_rid}"><a:extLst><a:ext uri="{SVG_BLIP_EXT}">'
            f'<asvg:svgBlip xmlns:asvg="{NS_ASVG}" r:embed="{svg_rid}"/></a:ext></a:extLst></a:blip>'
            '<a:stretch><a:fillRect/></a:stretch></p:blipFill>'
            f'<p:spPr>{xfrm(box["x"], box["y"], box["w"], box["h"])}<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
            '</p:spPr></p:pic>')
        item = {"shape_id": sid, "name": name, "kind": "image", "editable": False,
                "capability": fallback["capability"], "copy_keys": [], "fallback": dict(fallback)}
        part.objects.append(item)
        self.fallbacks.append(dict(item, fallback=dict(fallback)))

    def system(self, part, unit, slot):
        content, layout = self.content, self.layout
        nodes, _ = system_nodes(layout, content, unit, slot)
        px, ratio = layout.metrics(slot["type_role"])
        fallback = variant_fallback(self.library, unit)
        if fallback is not None and len(nodes) > 1:
            self.return_track(part, unit, nodes, fallback)
        ids, positions = {}, {}
        for node in nodes:
            # The frame's side insets leave exactly the node text width the plan wrapped the label in.
            paragraph = self.paragraph(self.runs(node["label"], px, "tx1", part), px, ratio)
            ids[node["entity"]["id"]] = self.shape(
                part, f"copy:{node['key']}", (node["x"], node["y"], node["w"], node["h"]),
                self.text_body([paragraph], inset=(node["w"] - node["text_w"]) / 2, anchor="ctr"), geometry="roundRect",
                fill="bg1",
                line="tx1",
                text_box=False, kind="shape", capability="editable-shapes", copy_keys=[node["key"]])
            positions[node["entity"]["id"]] = node
        caption, caption_ratio = layout.metrics("type.caption")
        relations = unit.get("relationships", [])
        label_x = (nodes[0]["x"] + nodes[0]["w"] if nodes else 0) + 40 + 30 * max(0, len(relations) - 1) + 8
        for position, relation in enumerate(relations):
            start, end = positions[relation["from"]], positions[relation["to"]]
            x = start["x"] + start["w"]
            y1, y2 = start["y"] + start["h"] / 2, end["y"] + end["h"] / 2
            lane = 40 + 30 * position
            sid = part.shape_id()
            name = f"edge:{relation['from']}:{relation['to']}"
            adj = int(round(emu(lane) / CONNECTOR_CX * 100000))
            part.shapes.append(
                f'<p:cxnSp><p:nvCxnSpPr><p:cNvPr id="{sid}" name="{xml_attr(name)}"/><p:cNvCxnSpPr>'
                f'<a:stCxn id="{ids[relation["from"]]}" idx="3"/><a:endCxn id="{ids[relation["to"]]}" idx="3"/>'
                f'</p:cNvCxnSpPr><p:nvPr/></p:nvCxnSpPr><p:spPr><a:xfrm{" flipV=" + chr(34) + "1" + chr(34) if y2 < y1 else ""}>'
                f'<a:off x="{emu(x)}" y="{emu(min(y1, y2))}"/><a:ext cx="{CONNECTOR_CX}" cy="{emu(abs(y2 - y1))}"/>'
                f'</a:xfrm><a:prstGeom prst="bentConnector3"><a:avLst><a:gd name="adj1" fmla="val {adj}"/></a:avLst>'
                f'</a:prstGeom><a:ln w="19050"><a:solidFill><a:schemeClr val="accent1"/></a:solidFill>'
                f'<a:tailEnd type="triangle"/></a:ln></p:spPr></p:cxnSp>')
            part.objects.append({"shape_id": sid, "name": name, "kind": "connector", "editable": True,
                                 "capability": "editable-shapes", "copy_keys": [], "fallback": None})
            label = self.paragraph(self.runs(relation["kind"], caption, "tx2", part, citations=False), caption,
                                   caption_ratio)
            label_h = caption * caption_ratio
            self.shape(part, f"kind:{relation['from']}:{relation['to']}",
                       (label_x, (y1 + y2) / 2 - label_h / 2, max(1.0, core.CANVAS["width"] - label_x - 8), label_h),
                       self.text_body([label], wrap="none"))

    def register(self, part, unit, entries, box, role):
        px, ratio = self.layout.metrics(role)
        paragraphs = []
        for index, entry in enumerate(entries):
            source = self.content.sources[entry["source_ref"]]
            gap = self.layout.item_gap if index else 0.0
            if isinstance(source.get("raw"), str):
                raw, url = source["raw"], source.get("url")
                if isinstance(url, str) and url and url in raw:
                    at = raw.index(url)
                    runs = (self.runs(raw[:at], px, "tx1", part, citations=False)
                            + f"<a:r>{self.rpr(px, 'tx1', part, (url, False))}<a:t>{xml_text(url)}</a:t></a:r>"
                            + self.runs(raw[at + len(url):], px, "tx1", part, citations=False))
                else:
                    runs = self.runs(raw, px, "tx1", part, citations=False)
            else:
                pieces = [f"<a:r>{self.rpr(px, 'tx2')}<a:t>{xml_text('[' + str(self.register_numbers[source['id']]) + ']')}"
                          f"</a:t></a:r>"]
                for key in core.source_fields(source):
                    pieces.append(f"<a:r>{self.rpr(px, 'tx1')}<a:t>{xml_text(' ')}</a:t></a:r>")
                    link = (source[key], False) if key == "url" else None
                    pieces.append(f"<a:r>{self.rpr(px, 'tx1', part, link)}<a:t>{xml_text(source[key])}</a:t></a:r>")
                runs = "".join(pieces)
            paragraphs.append(self.paragraph(runs, px, ratio, gap))
        keys = [f"source:{entry['source_ref']}" for entry in entries]
        self.shape(part, f"register:{unit['id']}", (box["x"], box["y"], box["width"], box["height"]),
                   self.text_body(paragraphs), copy_keys=keys)

    def cites(self, part, unit):
        """`[n]` links for the sources a unit's records and data name without a marker of their own —
        chrome, not copy — in one caption frame in the slide's bottom margin."""
        needed = []
        for ref in dict.fromkeys(binding["record_ref"] for binding in unit.get("bindings", [])):
            record = self.content.index.records[ref]
            texts = [item for _, _, value in core.validator.content_fields(record)
                     for item in (value if isinstance(value, list) else [value]) if isinstance(item, str)]
            if not any(CITATION.search(text) for text in texts):
                needed += record.get("source_refs", [])
        for point in unit.get("data_bindings", []):
            needed += self.content.data(point["data_ref"]).get("source_refs", [])
        needed = list(dict.fromkeys(needed))
        if not needed:
            return
        px, ratio = self.layout.metrics("type.caption")
        runs = []
        for index, ref in enumerate(needed):
            if index:
                runs.append(f"<a:r>{self.rpr(px, 'tx2')}<a:t>{xml_text(' ')}</a:t></a:r>")
            label = f"[{self.register_numbers[ref]}]"
            runs.append(f"<a:r>{self.rpr(px, 'tx2', part, self.source_link(self.content.sources[ref], part))}"
                        f"<a:t>{xml_text(label)}</a:t></a:r>")
        height = px * ratio
        y = core.CANVAS["height"] - self.layout.padding / 2 - height / 2
        self.shape(part, f"cites:{unit['id']}", (self.layout.padding, y, self.layout.width, height),
                   self.text_body([self.paragraph("".join(runs), px, ratio)], wrap="none"))

    # --- slides -------------------------------------------------------------------------------------

    def cover(self):
        part = Part(self, "slide")
        self.current = part
        for key, value, role, top, height in cover_layout(self.layout, self.document):
            self.copy_shape(part, f"document#{key}", [value], (self.layout.padding, top, self.layout.width, height), role,
                            "tx1" if key == "title" else "tx2")
        return part, None

    def unit_slide(self, unit, plan_unit):
        part = Part(self, "slide")
        self.current = part
        family = self.families[unit["pattern"]]
        notes = []
        for slot in plan_unit["slots"]:
            name, entries, role = slot["slot"], slot["content"], slot["type_role"]
            if slot["placement"] == "aside":
                for entry in entries:
                    value = self.content.field(entry["record_ref"], entry["field"])
                    notes.extend(value if isinstance(value, list) else [value])
                continue
            colour = "tx2" if name in MUTED_SLOTS else "tx1"
            shapes = part.shapes
            if name == "answer":
                box = slot["box"]
                self.shape(part, f"rule:{unit['id']}", (box["x"] - 20, box["y"], 6, box["height"]), fill="accent1",
                           text_box=False, kind="shape", capability="editable-shapes")
                self.blocks(part, entries, box, role, colour)
            elif name == "items" and unit["pattern"] == "comparison":
                self.comparison(part, unit, slot)
            elif name == "series":
                shapes.append(self.native_chart(unit, slot, entries))
                self.data_table(unit, slot, entries)
            elif name == "entities":
                self.system(part, unit, slot)
            elif name == "evidence" and family == "register":
                records = [entry for entry in entries if "record_ref" in entry]
                sources = [entry for entry in entries if "source_ref" in entry]
                y = self.blocks(part, records, slot["box"], role, colour) if records else slot["box"]["y"]
                box = dict(slot["box"], y=y, height=slot["box"]["y"] + slot["box"]["height"] - y)
                self.register(part, unit, sources, box, role)
            else:
                self.blocks(part, entries, slot["box"], role, colour)
        self.cites(part, unit)
        return part, notes

    def notes_part(self, slide_number, name, values):
        part = Part(self, "notes")
        px, ratio = self.layout.metrics("type.body")
        paragraphs = [self.paragraph(self.runs(value, px, "tx1", part), px, ratio) for value in values]
        part.rels.add(REL + "notesMaster", "../notesMasters/notesMaster1.xml")
        part.rels.add(REL + "slide", f"../slides/slide{slide_number}.xml")
        body = (f'<p:sp><p:nvSpPr><p:cNvPr id="3" name="{xml_attr("notes:" + name)}"/><p:cNvSpPr><a:spLocks noGrp="1"/>'
                f'</p:cNvSpPr><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr><p:spPr/><p:txBody><a:bodyPr/>'
                f'<a:lstStyle/>{"".join(paragraphs)}</p:txBody></p:sp>')
        xml = (f'{DECL}<p:notes {NS}><p:cSld><p:spTree>{group_root()}<p:sp><p:nvSpPr><p:cNvPr id="2" '
               'name="Slide Image Placeholder 1"/><p:cNvSpPr><a:spLocks noGrp="1" noRot="1" noChangeAspect="1"/>'
               '</p:cNvSpPr><p:nvPr><p:ph type="sldImg"/></p:nvPr></p:nvSpPr><p:spPr/></p:sp>'
               f'{body}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:notes>')
        return xml, part

    def slide_xml(self, name, part):
        return (f'{DECL}<p:sld {NS}><p:cSld name="{xml_attr(name)}"><p:bg><p:bgPr><a:solidFill><a:schemeClr val="bg1"/>'
                f'</a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree>{group_root()}{"".join(part.shapes)}</p:spTree>'
                '</p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>')

    def build(self):
        slides = []
        if self.document:
            slides.append(("document", None) + self.cover())
        for unit, plan_unit in zip(self.composition["units"], self.plan["units"]):
            slides.append((unit["id"], unit) + self.unit_slide(unit, plan_unit))
        trailer = [self.content.index.trailer[b["index"]] for b in self.composition.get("document_bindings", [])]
        parts, manifest_slides, notes_count = [], [], 0
        for number, (name, unit, part, notes) in enumerate(slides, 1):
            notes = list(notes or [])
            if number == len(slides):
                notes += trailer
            part.rels.add(REL + "slideLayout", "../slideLayouts/slideLayout1.xml")
            notes_path = None
            if notes:
                notes_count += 1
                notes_xml, notes_part = self.notes_part(number, name, notes)
                part.rels.add(REL + "notesSlide", f"../notesSlides/notesSlide{notes_count}.xml")
                notes_path = f"ppt/notesSlides/notesSlide{notes_count}.xml"
                parts.append((notes_path, notes_xml, notes_part.rels))
            parts.append((f"ppt/slides/slide{number}.xml", self.slide_xml(name, part), part.rels))
            manifest_slides.append({"index": number, "part": f"ppt/slides/slide{number}.xml", "name": name,
                                    "unit": unit["id"] if unit else None,
                                    "pattern": unit["pattern"] if unit else None,
                                    "notes_part": notes_path, "notes_paragraphs": len(notes),
                                    "objects": part.objects})
        return parts, manifest_slides, len(slides), notes_count


def cover_layout(layout, document):
    blocks, y = [], layout.padding
    for key, value in document:
        role = "type.display" if key == "title" else "type.lead"
        _, height = layout.text_block([value], layout.width, role)
        blocks.append((key, value, role, y, height))
        y += height + layout.gap
    return blocks


def cover_bottom(layout, document):
    blocks = cover_layout(layout, document)
    return blocks[-1][3] + blocks[-1][4] if blocks else 0.0


# --- the chart and its workbook -------------------------------------------------------------------

def zero_bound(items):
    """The value axis's zero bound. An application left to scale the axis itself may start it above zero
    when the values cluster, so bar lengths would stop being proportional to the values; the bound pins
    the zero baseline whenever every value lies on one side of it. Values on both sides already span zero."""
    values = [float(item["value"]) for item in items]
    if values and min(values) >= 0:
        return '<c:min val="0"/>'
    if values and max(values) <= 0:
        return '<c:max val="0"/>'
    return ""


def chart_xml(items, unit):
    count = len(items)
    last = count + 1
    categories = "".join(f'<c:pt idx="{i}"><c:v>{xml_text(item["label"])}</c:v></c:pt>' for i, item in enumerate(items))
    values = "".join(f'<c:pt idx="{i}"><c:v>{xml_text(core.number_text(item["value"]))}</c:v></c:pt>'
                     for i, item in enumerate(items))
    return (f'{DECL}<c:chartSpace xmlns:c="{NS_C}" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><c:date1904 val="0"/>'
            '<c:roundedCorners val="0"/><c:chart><c:autoTitleDeleted val="1"/><c:plotArea><c:layout><c:manualLayout>'
            '<c:layoutTarget val="inner"/><c:xMode val="edge"/><c:yMode val="edge"/><c:x val="0"/><c:y val="0"/>'
            '<c:w val="1"/><c:h val="1"/></c:manualLayout></c:layout><c:barChart><c:barDir val="bar"/>'
            '<c:grouping val="clustered"/><c:varyColors val="0"/><c:ser><c:idx val="0"/><c:order val="0"/>'
            f'<c:tx><c:strRef><c:f>Sheet1!$B$1</c:f><c:strCache><c:ptCount val="1"/><c:pt idx="0"><c:v>{xml_text(unit)}'
            '</c:v></c:pt></c:strCache></c:strRef></c:tx><c:spPr><a:solidFill><a:schemeClr val="accent1"/></a:solidFill>'
            '<a:ln w="9525"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill></a:ln></c:spPr>'
            f'<c:invertIfNegative val="0"/><c:cat><c:strRef><c:f>Sheet1!$A$2:$A${last}</c:f><c:strCache>'
            f'<c:ptCount val="{count}"/>{categories}</c:strCache></c:strRef></c:cat><c:val><c:numRef>'
            f'<c:f>Sheet1!$B$2:$B${last}</c:f><c:numCache><c:formatCode>General</c:formatCode><c:ptCount val="{count}"/>'
            f'{values}</c:numCache></c:numRef></c:val></c:ser><c:gapWidth val="67"/><c:axId val="500000001"/>'
            '<c:axId val="500000002"/></c:barChart><c:catAx><c:axId val="500000001"/><c:scaling>'
            '<c:orientation val="maxMin"/></c:scaling><c:delete val="0"/><c:axPos val="l"/><c:majorTickMark val="none"/>'
            '<c:minorTickMark val="none"/><c:tickLblPos val="none"/><c:spPr><a:ln w="9525"><a:solidFill>'
            '<a:schemeClr val="tx1"/></a:solidFill></a:ln></c:spPr><c:crossAx val="500000002"/>'
            '<c:crosses val="autoZero"/><c:auto val="1"/><c:lblAlgn val="ctr"/><c:lblOffset val="100"/>'
            '<c:noMultiLvlLbl val="0"/></c:catAx><c:valAx><c:axId val="500000002"/><c:scaling>'
            f'<c:orientation val="minMax"/>{zero_bound(items)}</c:scaling><c:delete val="1"/><c:axPos val="t"/>'
            '<c:numFmt formatCode="General" sourceLinked="1"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/>'
            '<c:tickLblPos val="nextTo"/><c:crossAx val="500000001"/><c:crosses val="autoZero"/>'
            '<c:crossBetween val="between"/></c:valAx><c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr>'
            '</c:plotArea><c:plotVisOnly val="1"/><c:dispBlanksAs val="gap"/></c:chart><c:spPr><a:noFill/><a:ln>'
            '<a:noFill/></a:ln></c:spPr><c:externalData r:id="rId1"><c:autoUpdate val="0"/></c:externalData>'
            '</c:chartSpace>')


def workbook(items, unit):
    """The chart's embedded workbook: B1 names the unit, column A the labels, column B the literal
    values, one row per point in the brief's order."""
    main = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    rows = [f'<row r="1"><c r="B1" t="inlineStr"><is><t>{xml_text(unit)}</t></is></c></row>']
    for i, item in enumerate(items, 2):
        rows.append(f'<row r="{i}"><c r="A{i}" t="inlineStr"><is><t>{xml_text(item["label"])}</t></is></c>'
                    f'<c r="B{i}"><v>{xml_text(core.number_text(item["value"]))}</v></c></row>')
    sheet = (f'{DECL}<worksheet xmlns="{main}"><dimension ref="A1:B{len(items) + 1}"/><sheetData>{"".join(rows)}'
             '</sheetData></worksheet>')
    book = (f'{DECL}<workbook xmlns="{main}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/'
            'relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>')
    styles = (f'{DECL}<styleSheet xmlns="{main}"><fonts count="1"><font><sz val="11"/><name val="Calibri"/></font>'
              '</fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill>'
              '<patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/>'
              '<bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" '
              'borderId="0"/></cellStyleXfs><cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" '
              'xfId="0"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
              '</styleSheet>')
    book_rels = Rels()
    book_rels.add(REL + "worksheet", "worksheets/sheet1.xml")
    book_rels.add(REL + "styles", "styles.xml")
    root_rels = Rels()
    root_rels.add(REL + "officeDocument", "xl/workbook.xml")
    sheet_ct = "application/vnd.openxmlformats-officedocument.spreadsheetml."
    types = (f'{DECL}<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
             '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
             '<Default Extension="xml" ContentType="application/xml"/>'
             f'<Override PartName="/xl/workbook.xml" ContentType="{sheet_ct}sheet.main+xml"/>'
             f'<Override PartName="/xl/worksheets/sheet1.xml" ContentType="{sheet_ct}worksheet+xml"/>'
             f'<Override PartName="/xl/styles.xml" ContentType="{sheet_ct}styles+xml"/></Types>')
    return package([("[Content_Types].xml", types), ("_rels/.rels", root_rels.xml()), ("xl/workbook.xml", book),
                    ("xl/_rels/workbook.xml.rels", book_rels.xml()), ("xl/worksheets/sheet1.xml", sheet),
                    ("xl/styles.xml", styles)])


# --- the fixed parts --------------------------------------------------------------------------------

def theme_xml(name, colours, typeface):
    def colour(slot, key):
        return f'<a:{slot}><a:srgbClr val="{colours[key]}"/></a:{slot}>'
    scheme = "".join((colour("dk1", "text"), colour("lt1", "bg"), colour("dk2", "text-muted"), colour("lt2", "surface"),
                      colour("accent1", "accent"), colour("accent2", "border"), colour("accent3", "text-muted"),
                      colour("accent4", "text"), colour("accent5", "surface"), colour("accent6", "accent"),
                      colour("hlink", "text"), colour("folHlink", "text-muted")))
    face = xml_attr(typeface)
    font = f'<a:latin typeface="{face}"/><a:ea typeface=""/><a:cs typeface=""/>'
    fill = '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    line = '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>'
    return (f'{DECL}<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="{xml_attr(name)}">'
            f'<a:themeElements><a:clrScheme name="{xml_attr(name)}">{scheme}</a:clrScheme>'
            f'<a:fontScheme name="{xml_attr(name)}"><a:majorFont>{font}</a:majorFont><a:minorFont>{font}</a:minorFont>'
            f'</a:fontScheme><a:fmtScheme name="{xml_attr(name)}"><a:fillStyleLst>{fill * 3}</a:fillStyleLst>'
            f'<a:lnStyleLst>{line * 3}</a:lnStyleLst><a:effectStyleLst>{"<a:effectStyle><a:effectLst/></a:effectStyle>" * 3}'
            f'</a:effectStyleLst><a:bgFillStyleLst>{fill * 3}</a:bgFillStyleLst></a:fmtScheme></a:themeElements>'
            '<a:objectDefaults/><a:extraClrSchemeLst/></a:theme>')


CLR_MAP = ('bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" '
           'accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"')


def level_style(tag, size):
    return f'<{tag}><a:lvl1pPr><a:defRPr sz="{size}"/></a:lvl1pPr></{tag}>'


def master_xml():
    return (f'{DECL}<p:sldMaster {NS}><p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg>'
            f'<p:spTree>{group_root()}</p:spTree></p:cSld><p:clrMap {CLR_MAP}/><p:sldLayoutIdLst>'
            '<p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst><p:txStyles>'
            f'{level_style("p:titleStyle", 3200)}{level_style("p:bodyStyle", 1800)}{level_style("p:otherStyle", 1800)}'
            '</p:txStyles></p:sldMaster>')


def layout_xml():
    return (f'{DECL}<p:sldLayout {NS} type="blank" preserve="1"><p:cSld name="Blank"><p:spTree>{group_root()}'
            '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>')


def notes_master_xml():
    def placeholder(sid, name, kind, idx, x, y, cx, cy):
        index = f' idx="{idx}"' if idx is not None else ""
        body = '<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></p:txBody>'
        return (f'<p:sp><p:nvSpPr><p:cNvPr id="{sid}" name="{name}"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>'
                f'<p:nvPr><p:ph type="{kind}"{index}/></p:nvPr></p:nvSpPr><p:spPr><a:xfrm><a:off x="{x}" y="{y}"/>'
                f'<a:ext cx="{cx}" cy="{cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>{body}'
                '</p:sp>')
    shapes = (placeholder(2, "Slide Image Placeholder 1", "sldImg", 2, 685800, 1143000, 5486400, 3086100)
              + placeholder(3, "Notes Placeholder 2", "body", 3, 685800, 4400550, 5486400, 3600450))
    return (f'{DECL}<p:notesMaster {NS}><p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg>'
            f'<p:spTree>{group_root()}{shapes}</p:spTree></p:cSld><p:clrMap {CLR_MAP}/>'
            f'{level_style("p:notesStyle", 1200)}</p:notesMaster>')


def presentation_xml(slide_rids, notes_master_rid):
    ids = "".join(f'<p:sldId id="{256 + i}" r:id="{rid}"/>' for i, rid in enumerate(slide_rids))
    return (f'{DECL}<p:presentation {NS} saveSubsetFonts="1"><p:sldMasterIdLst><p:sldMasterId id="2147483648" '
            f'r:id="rId1"/></p:sldMasterIdLst><p:notesMasterIdLst><p:notesMasterId r:id="{notes_master_rid}"/>'
            f'</p:notesMasterIdLst><p:sldIdLst>{ids}</p:sldIdLst><p:sldSz cx="{SLIDE_CX}" cy="{SLIDE_CY}"/>'
            f'<p:notesSz cx="{NOTES_CX}" cy="{NOTES_CY}"/><p:defaultTextStyle><a:lvl1pPr><a:defRPr sz="1800"/>'
            '</a:lvl1pPr></p:defaultTextStyle></p:presentation>')


def package(parts):
    """A zip with fixed timestamps and attributes in a fixed order, so equal inputs give equal bytes."""
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in parts:
            info = zipfile.ZipInfo(name, date_time=ZIP_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0
            info.external_attr = 0o600 << 16
            archive.writestr(info, data.encode("utf-8") if isinstance(data, str) else data)
    return buffer.getvalue()


def render(brief, composition, plan, theme, font, fonts, language, library, generated_at, run_id):
    """(package bytes, pptx-manifest@1) for a validated brief, composition and plan that check_fit and
    check_content have already passed."""
    deck = Deck(brief, composition, plan, theme, font, fonts, language, library)
    slide_parts, manifest_slides, slide_count, notes_count = deck.build()
    parts, overrides = [], []
    pres_rels = Rels()
    pres_rels.add(REL + "slideMaster", "slideMasters/slideMaster1.xml")
    slide_rids = [pres_rels.add(REL + "slide", f"slides/slide{n}.xml") for n in range(1, slide_count + 1)]
    notes_master_rid = pres_rels.add(REL + "notesMaster", "notesMasters/notesMaster1.xml")
    pres_rels.add(REL + "presProps", "presProps.xml")
    pres_rels.add(REL + "viewProps", "viewProps.xml")
    pres_rels.add(REL + "theme", "theme/theme1.xml")
    pres_rels.add(REL + "tableStyles", "tableStyles.xml")

    def add(path, xml, content_type, rels=None):
        parts.append((path, xml))
        if content_type:
            overrides.append((path, content_type))
        if rels is not None:
            head, _, tail = path.rpartition("/")
            parts.append((f"{head}/_rels/{tail}.rels", rels.xml()))

    pml = CT + "presentationml."
    add("ppt/presentation.xml", presentation_xml(slide_rids, notes_master_rid), pml + "presentation.main+xml", pres_rels)
    master_rels = Rels()
    master_rels.add(REL + "slideLayout", "../slideLayouts/slideLayout1.xml")
    master_rels.add(REL + "theme", "../theme/theme1.xml")
    add("ppt/slideMasters/slideMaster1.xml", master_xml(), pml + "slideMaster+xml", master_rels)
    layout_rels = Rels()
    layout_rels.add(REL + "slideMaster", "../slideMasters/slideMaster1.xml")
    add("ppt/slideLayouts/slideLayout1.xml", layout_xml(), pml + "slideLayout+xml", layout_rels)
    notes_rels = Rels()
    notes_rels.add(REL + "theme", "../theme/theme2.xml")
    add("ppt/notesMasters/notesMaster1.xml", notes_master_xml(), pml + "notesMaster+xml", notes_rels)
    add("ppt/theme/theme1.xml", theme_xml(theme.slug, deck.colours, deck.typeface), CT + "theme+xml")
    add("ppt/theme/theme2.xml", theme_xml(theme.slug + "-notes", deck.colours, deck.typeface), CT + "theme+xml")
    for path, xml, rels in slide_parts:
        kind = "notesSlide+xml" if "/notesSlides/" in path else "slide+xml"
        add(path, xml, pml + kind, rels)
    assets = []
    for number, (xml, book, unit_id) in enumerate(deck.charts, 1):
        chart_rels = Rels()
        target = f"../embeddings/Microsoft_Excel_Worksheet{number}.xlsx"
        chart_rels.add(REL + "package", target)
        add(f"ppt/charts/chart{number}.xml", xml, CT + "drawingml.chart+xml", chart_rels)
        path = f"ppt/embeddings/Microsoft_Excel_Worksheet{number}.xlsx"
        parts.append((path, book))
        assets.append({"part": path, "sha256": core.sha256_bytes(book), "kind": "chart-workbook", "unit": unit_id})
    for path, data, kind, unit_id in deck.media:
        data = data.encode("utf-8") if isinstance(data, str) else data
        parts.append((path, data))
        assets.append({"part": path, "sha256": core.sha256_bytes(data), "kind": kind, "unit": unit_id})
    add("ppt/presProps.xml", f"{DECL}<p:presentationPr {NS}/>", pml + "presProps+xml")
    # normalViewPr must carry restoredLeft and restoredTop: PowerPoint offers to repair a deck whose
    # normal view omits them, although lenient readers open it.
    add("ppt/viewProps.xml", f'{DECL}<p:viewPr {NS}><p:normalViewPr><p:restoredLeft sz="15620"/>'
        '<p:restoredTop sz="94660"/></p:normalViewPr><p:slideViewPr><p:cSldViewPr><p:cViewPr>'
        '<p:scale><a:sx n="100" d="100"/><a:sy n="100" d="100"/></p:scale><p:origin x="0" y="0"/></p:cViewPr>'
        '<p:guideLst/></p:cSldViewPr></p:slideViewPr><p:gridSpacing cx="76200" cy="76200"/></p:viewPr>',
        pml + "viewProps+xml")
    add("ppt/tableStyles.xml", f'{DECL}<a:tblStyleLst xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'def="{5C22544A-7EE6-4342-B048-85BDC9FD1C3A}"/>', pml + "tableStyles+xml")
    document = dict(deck.document)
    title = f"<dc:title>{xml_text(document['title'])}</dc:title>" if "title" in document else ""
    add("docProps/core.xml", f'{DECL}<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/'
        'metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">'
        f'{title}<cp:revision>1</cp:revision></cp:coreProperties>',
        "application/vnd.openxmlformats-package.core-properties+xml")
    add("docProps/app.xml", f'{DECL}<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/'
        f'extended-properties"><Application>{xml_attr(WRITER_NAME)}</Application>'
        f'<PresentationFormat>Widescreen</PresentationFormat><Slides>{slide_count}</Slides><Notes>{notes_count}</Notes>'
        '</Properties>', CT + "extended-properties+xml")
    root_rels = Rels()
    root_rels.add(REL + "officeDocument", "ppt/presentation.xml")
    root_rels.add("http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties",
                  "docProps/core.xml")
    root_rels.add(REL + "extended-properties", "docProps/app.xml")
    types = (f'{DECL}<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
             '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
             '<Default Extension="xml" ContentType="application/xml"/>'
             f'<Default Extension="xlsx" ContentType="{CT}spreadsheetml.sheet"/>'
             # Picture types only when the deck carries a declared fallback, so a deck without one keeps
             # exactly the bytes it had before fallbacks existed.
             + ('<Default Extension="png" ContentType="image/png"/>'
                '<Default Extension="svg" ContentType="image/svg+xml"/>' if deck.media else "")
             + "".join(f'<Override PartName="/{path}" ContentType="{kind}"/>' for path, kind in overrides)
             + "</Types>")
    data = package([("[Content_Types].xml", types), ("_rels/.rels", root_rels.xml())] + parts)
    manifest = {
        "artifact_type": "pptx-manifest",
        "artifact_version": "1",
        "artifact_id": f"pptx-manifest:{composition['artifact_id']}",
        "composition_ref": {"artifact_id": composition["artifact_id"], "artifact_version": composition["artifact_version"]},
        "plan_ref": {"artifact_id": plan["artifact_id"], "artifact_version": plan["artifact_version"]},
        "package": {"path": ARTIFACT, "sha256": core.sha256_bytes(data)},
        "slide_size": {"unit": "emu", "cx": SLIDE_CX, "cy": SLIDE_CY},
        "writer": {"name": WRITER_NAME, "version": core.renderer_version(), "adapter": "scripts/pptx_adapter.py"},
        "runtime": {"name": sys.implementation.name,
                    "version": ".".join(str(part) for part in sys.version_info[:3])},
        "design_system": dict(composition["design_system"]),
        "theme": {"slug": theme.slug, "tokens_sha256": theme.digest},
        "language": deck.language,
        "fonts": [dict(core.font_record(entry), typeface=office_typeface(entry)) for entry in fonts],
        "readability": {"min_sz": deck.min_sz, "token": "typography.size-small", "autofit": "none"},
        "assets": assets,
        "slides": manifest_slides,
        "fallbacks": deck.fallbacks,
        "generated_at": generated_at,
        "run_id": run_id,
    }
    return data, manifest
