"""Independent checks for design-render's PPTX target. Stdlib only.

Every expectation here comes from the frozen inputs — the normalized brief, the composition, the
pattern library and the theme — never from the writer: this module does not import pptx_adapter,
so a damaged writer cannot agree with itself. The package is read as Office Open XML with zipfile and
xml.etree; a paragraph's text is its runs' `a:t` text with each `a:br` read as a line feed, and nothing
else is transformed. Each check returns findings `{code, check, reference, message}`; an empty list is
a pass.

references/design-render.md states the rules these checks enforce: package integrity, the shape-name
scheme that addresses copy, frozen copy and notes, the native chart and its workbook, editable system
shapes, citations and the register, reading order, the manifest's object bijection and identities,
unreported flattening and the per-variant declared fallback, autofit, readability (per slot, with the caption size as the backstop) and slide
bounds.
"""

import io
import posixpath
import re
import zipfile
import xml.etree.ElementTree as ET

import render_core as core
from render_checks import finding

A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
P = "{http://schemas.openxmlformats.org/presentationml/2006/main}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
C = "{http://schemas.openxmlformats.org/drawingml/2006/chart}"
S = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RELS = "{http://schemas.openxmlformats.org/package/2006/relationships}"
TYPES = "{http://schemas.openxmlformats.org/package/2006/content-types}"
CHART_URI = "http://schemas.openxmlformats.org/drawingml/2006/chart"
REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
CITATION = re.compile(r"\[([0-9]+)\]")
SLIDE_JUMP = "ppaction://hlinksldjump"
SHAPE_TAGS = (P + "sp", P + "cxnSp", P + "graphicFrame", P + "pic")
EDITABLE_KINDS = {"text", "shape", "connector", "chart"}
# Children the OOXML schema makes mandatory for the elements a deck is written with. A missing one is
# the shape of defect a lenient reader opens without complaint and PowerPoint offers to repair — an
# empty p:normalViewPr was one. This is a structural subset of the schema, not a full validation.
REQUIRED_CHILDREN = {
    P + "presentation": (P + "sldMasterIdLst", P + "notesSz"),
    P + "normalViewPr": (P + "restoredLeft", P + "restoredTop"),
    P + "cSldViewPr": (P + "cViewPr",),
    P + "cViewPr": (P + "scale", P + "origin"),
    P + "sldMaster": (P + "cSld", P + "clrMap", P + "txStyles"),
    P + "notesMaster": (P + "cSld", P + "clrMap"),
    P + "sldLayout": (P + "cSld",),
    P + "sld": (P + "cSld",),
    P + "notes": (P + "cSld",),
    P + "cSld": (P + "spTree",),
    P + "spTree": (P + "nvGrpSpPr", P + "grpSpPr"),
    P + "sp": (P + "nvSpPr", P + "spPr"),
    P + "nvSpPr": (P + "cNvPr", P + "cNvSpPr", P + "nvPr"),
    P + "cxnSp": (P + "nvCxnSpPr", P + "spPr"),
    P + "graphicFrame": (P + "nvGraphicFramePr", P + "xfrm", A + "graphic"),
    P + "pic": (P + "nvPicPr", P + "blipFill", P + "spPr"),
    P + "nvPicPr": (P + "cNvPr", P + "cNvPicPr", P + "nvPr"),
    P + "bgPr": (A + "effectLst",),
    A + "theme": (A + "themeElements",),
    A + "themeElements": (A + "clrScheme", A + "fontScheme", A + "fmtScheme"),
    A + "fontScheme": (A + "majorFont", A + "minorFont"),
    A + "majorFont": (A + "latin", A + "ea", A + "cs"),
    A + "minorFont": (A + "latin", A + "ea", A + "cs"),
    A + "fmtScheme": (A + "fillStyleLst", A + "lnStyleLst", A + "effectStyleLst", A + "bgFillStyleLst"),
    A + "txBody": (A + "bodyPr",),
    P + "txBody": (A + "bodyPr",),
    A + "xfrm": (A + "off", A + "ext"),
    C + "chartSpace": (C + "chart",),
    C + "chart": (C + "plotArea",),
    C + "barChart": (C + "barDir", C + "axId"),
    C + "ser": (C + "idx", C + "order"),
    C + "catAx": (C + "axId", C + "scaling", C + "axPos", C + "crossAx"),
    C + "valAx": (C + "axId", C + "scaling", C + "axPos", C + "crossAx"),
}
MANIFEST_KEYS = ("artifact_type", "artifact_version", "artifact_id", "package", "slide_size", "writer", "runtime",
                 "design_system", "theme", "language", "fonts", "readability", "assets", "slides", "fallbacks")


class Unreadable(Exception):
    pass


# --- the package ------------------------------------------------------------------------------------

def rels_path(part):
    head, _, tail = part.rpartition("/")
    return f"{head}/_rels/{tail}.rels" if head else f"_rels/{tail}.rels"


def resolve(source, target):
    if target.startswith("/"):
        return target[1:]
    return posixpath.normpath(posixpath.join(posixpath.dirname(source), target))


class Package:
    def __init__(self, data):
        try:
            archive = zipfile.ZipFile(io.BytesIO(data))
            infos = archive.infolist()
            self.names = [info.filename for info in infos]
            self.parts = {info.filename: archive.read(info) for info in infos if not info.filename.endswith("/")}
        except (zipfile.BadZipFile, OSError, RuntimeError) as exc:
            raise Unreadable(f"the package is not a readable zip: {exc}") from exc
        self.trees = {}

    def tree(self, name):
        if name not in self.trees:
            try:
                self.trees[name] = ET.fromstring(self.parts[name])
            except ET.ParseError as exc:
                raise Unreadable(f"{name} is not well-formed XML: {exc}") from exc
        return self.trees[name]

    def rels(self, part):
        """Relationship id -> {type, target, external, resolved} for one part; {} when it has none."""
        path = rels_path(part)
        if path not in self.parts:
            return {}
        out = {}
        for rel in self.tree(path).iter(RELS + "Relationship"):
            external = rel.get("TargetMode") == "External"
            target = rel.get("Target", "")
            out[rel.get("Id")] = {"type": rel.get("Type", ""), "target": target, "external": external,
                                  "resolved": None if external else resolve(part, target)}
        return out


def check_package(pkg):
    """Content types cover every part, every relationship resolves, and every relationship id a part
    uses exists in that part's relationships — the conditions under which an application opens the
    package without offering to repair it."""
    out = []
    for name in sorted({n for n in pkg.names if pkg.names.count(n) > 1}):
        out.append(finding("package-duplicate", "package", name, f"{name} occurs twice in the zip"))
    if "[Content_Types].xml" not in pkg.parts:
        return out + [finding("package-content-type", "package", "[Content_Types].xml", "the package has no content types")]
    types = pkg.tree("[Content_Types].xml")
    defaults = {node.get("Extension", "").lower(): node.get("ContentType") for node in types.iter(TYPES + "Default")}
    overrides = {node.get("PartName", "").lstrip("/"): node.get("ContentType") for node in types.iter(TYPES + "Override")}
    for name in pkg.parts:
        if name == "[Content_Types].xml":
            continue
        extension = name.rsplit(".", 1)[-1].lower()
        # The generic xml default would type a slide as plain XML; every XML part names its own type.
        if name not in overrides and (extension == "xml" or extension not in defaults):
            out.append(finding("package-content-type", "package", name, f"{name} has no content type of its own"))
    for name in overrides:
        if name not in pkg.parts:
            out.append(finding("package-content-type", "package", name, f"a content type names the missing part {name}"))
    for path in [name for name in pkg.parts if name.endswith(".rels")]:
        head, _, tail = path.rpartition("/")
        source = posixpath.join(posixpath.dirname(head), tail[:-len(".rels")]) if head.endswith("_rels") else None
        if source is None or (source and source not in pkg.parts):
            out.append(finding("package-target", "package", path, f"{path} belongs to no part"))
            continue
        ids = []
        for rel in pkg.tree(path).iter(RELS + "Relationship"):
            ids.append(rel.get("Id"))
            target = rel.get("Target", "")
            if rel.get("TargetMode") == "External":
                if not rel.get("Type", "").endswith("/hyperlink"):
                    out.append(finding("remote-asset", "package", target, f"{path} loads the external {target}"))
                elif target.lower().startswith("file:"):
                    out.append(finding("local-reference", "package", target, f"{path} links the local file {target}"))
            elif resolve(source, target) not in pkg.parts:
                out.append(finding("package-target", "package", f"{path}:{rel.get('Id')}",
                                   f"{path} {rel.get('Id')} targets the missing part {target}"))
        for rid in sorted({rid for rid in ids if ids.count(rid) > 1}):
            out.append(finding("package-relationship", "package", f"{path}:{rid}", f"{path} declares {rid} twice"))
    for name in pkg.parts:
        if not name.endswith(".xml") or name == "[Content_Types].xml":
            continue
        known = pkg.rels(name)
        for node in pkg.tree(name).iter():
            for attr, value in node.attrib.items():
                if attr.startswith(R) and value not in known:
                    out.append(finding("package-relationship", "package", f"{name}:{value}",
                                       f"{name} uses {value}, which its relationships do not declare"))
            required = REQUIRED_CHILDREN.get(node.tag)
            # A slide's graphic frame names its chart part with an empty c:chart r:id reference; only
            # the chart part's own c:chart element carries a plot area.
            if required and not (node.tag == C + "chart" and R + "id" in node.attrib):
                present = {child.tag for child in node}
                for tag in required:
                    if tag not in present:
                        out.append(finding("package-schema", "package", f"{name}:{local(node.tag)}",
                                           f"{name} writes {local(node.tag)} without its required {local(tag)}"))
    return out


def local(tag):
    return tag.rsplit("}", 1)[-1]


def slide_parts(pkg):
    """The slide parts in presentation order, via the package relationship and the slide id list."""
    root = [rel for rel in pkg.rels("").values() if rel["type"].endswith("/officeDocument")]
    if not root or root[0]["resolved"] not in pkg.parts:
        raise Unreadable("the package names no presentation part")
    presentation = root[0]["resolved"]
    rels = pkg.rels(presentation)
    parts = []
    for node in pkg.tree(presentation).iter(P + "sldId"):
        rel = rels.get(node.get(R + "id"))
        if rel is None or not rel["type"].endswith("/slide") or rel["resolved"] not in pkg.parts:
            raise Unreadable(f"the slide list names {node.get(R + 'id')}, which resolves to no slide")
        parts.append(rel["resolved"])
    size = pkg.tree(presentation).find(P + "sldSz")
    extent = (int(size.get("cx")), int(size.get("cy"))) if size is not None else (0, 0)
    return presentation, parts, extent


def slide_count(data):
    try:
        return len(slide_parts(Package(data))[1])
    except (Unreadable, KeyError, ValueError):
        return 0


# --- shapes and text --------------------------------------------------------------------------------

def shapes_of(tree):
    tree_root = tree.find(f"{P}cSld/{P}spTree")
    found = []

    def walk(node):
        for child in node:
            if child.tag == P + "grpSp":
                walk(child)
            elif child.tag in SHAPE_TAGS:
                found.append(child)
    if tree_root is not None:
        walk(tree_root)
    return found


def props(shape):
    node = shape.find(f".//{P}cNvPr")
    return (node.get("id"), node.get("name", "")) if node is not None else (None, "")


def kind_of(shape):
    if shape.tag == P + "pic":
        return "image"
    if shape.tag == P + "cxnSp":
        return "connector"
    if shape.tag == P + "graphicFrame":
        data = shape.find(f".//{A}graphicData")
        return "chart" if data is not None and data.get("uri") == CHART_URI else "frame"
    marker = shape.find(f"{P}nvSpPr/{P}cNvSpPr")
    return "text" if marker is not None and marker.get("txBox") == "1" else "shape"


def paragraphs(shape):
    """[(text, [(run text, rPr)])] for each paragraph of a shape's text body."""
    body = shape.find(P + "txBody")
    out = []
    for para in (body.findall(A + "p") if body is not None else []):
        runs = []
        for child in para:
            if child.tag == A + "r":
                node = child.find(A + "t")
                runs.append(((node.text or "") if node is not None else "", child.find(A + "rPr")))
            elif child.tag == A + "br":
                runs.append(("\n", None))
            elif child.tag == A + "fld":
                node = child.find(A + "t")
                runs.append(((node.text or "") if node is not None else "", child.find(A + "rPr")))
        out.append(("".join(text for text, _ in runs), runs))
    return out


def texts(shape):
    return [text for text, _ in paragraphs(shape)]


class Slide:
    def __init__(self, pkg, part):
        self.part = part
        self.tree = pkg.tree(part)
        node = self.tree.find(P + "cSld")
        self.name = node.get("name", "") if node is not None else ""
        self.shapes = shapes_of(self.tree)
        self.named = {}
        for shape in self.shapes:
            self.named.setdefault(props(shape)[1], []).append(shape)
        self.rels = pkg.rels(part)
        notes = [rel["resolved"] for rel in self.rels.values() if rel["type"].endswith("/notesSlide")]
        self.notes_part = notes[0] if notes else None
        self.notes_body = None
        if self.notes_part in pkg.parts:
            for shape in shapes_of(pkg.tree(self.notes_part)):
                placeholder = shape.find(f"{P}nvSpPr/{P}nvPr/{P}ph")
                if placeholder is not None and placeholder.get("type") == "body":
                    self.notes_body = shape
        self.notes_rels = pkg.rels(self.notes_part) if self.notes_part else {}


# --- expectations from the frozen inputs ---------------------------------------------------------

def per_item(unit, slot):
    """Slots whose list items are each their own object: comparison sides and system nodes."""
    return slot == "entities" or (slot == "items" and unit["pattern"] == "comparison")


def source_entry(source, number):
    if isinstance(source.get("raw"), str):
        return source["raw"]
    return f"[{number}] " + " ".join(source[key] for key in core.source_fields(source))


def needed_cites(content, unit):
    needed = []
    for ref in dict.fromkeys(binding["record_ref"] for binding in unit.get("bindings", [])):
        record = content.index.records[ref]
        strings = [item for _, _, value in core.validator.content_fields(record)
                   for item in (value if isinstance(value, list) else [value]) if isinstance(item, str)]
        if not any(CITATION.search(text) for text in strings):
            needed += record.get("source_refs", [])
    for point in unit.get("data_bindings", []):
        needed += content.data(point["data_ref"]).get("source_refs", [])
    return list(dict.fromkeys(needed))


def expectations(brief, composition, library):
    """Slide name -> what that slide and its notes must carry, from the brief and composition alone."""
    content = core.Content(brief)
    families = {pattern["id"]: pattern["family"] for pattern in library["patterns"]}
    numbers = {source_id: position for position, source_id in enumerate(content.source_order, 1)}
    slides = []
    document = brief.get("document") or {}
    cover = {f"document#{key}": [document[key]] for key in ("title", "subtitle")
             if isinstance(document.get(key), str) and document[key]}
    if cover:
        slides.append({"name": "document", "unit": None, "family": None, "keys": cover, "notes": [], "cites": [],
                       "register": None})
    for unit in composition["units"]:
        keys, notes = {}, []
        for binding in unit.get("bindings", []):
            value = content.field(binding["record_ref"], binding["field"])
            key = f"{binding['record_ref']}#{binding['field']}"
            if binding["slot"] in core.ASIDE_SLOTS:
                notes.extend(value if isinstance(value, list) else [value])
            elif isinstance(value, list) and per_item(unit, binding["slot"]):
                keys.update({f"{key}#{i}": [item] for i, item in enumerate(value)})
            else:
                keys[key] = list(value) if isinstance(value, list) else [value]
        for point in unit.get("data_bindings", []):
            item = content.data(point["data_ref"])
            keys[f"data:{item['id']}#label"] = [item["label"]]
            keys[f"value:{item['id']}"] = [f"{core.number_text(item['value'])} {item['unit']}"]
        register = None
        if unit.get("register_refs"):
            register = {"name": f"register:{unit['id']}", "refs": list(unit["register_refs"]),
                        "lines": [source_entry(content.sources[ref], numbers[ref]) for ref in unit["register_refs"]]}
        slides.append({"name": unit["id"], "unit": unit, "family": families[unit["pattern"]], "keys": keys,
                       "notes": notes, "cites": needed_cites(content, unit), "register": register})
    if slides:
        slides[-1]["notes"] = slides[-1]["notes"] + [content.index.trailer[b["index"]]
                                                     for b in composition.get("document_bindings", [])]
    return slides, content, numbers


# --- checks -------------------------------------------------------------------------------------------

def check_order(found, expected):
    want = [slide["name"] for slide in expected]
    got = [slide.name for slide in found]
    if got == want:
        return []
    out = [finding("reordered-unit", "reading-order", ",".join(got), f"slide order {got} is not {want}")]
    if expected and expected[-1]["register"] and (not got or got[-1] != want[-1]):
        out.append(finding("register-not-last", "register", want[-1], "the source register is not the last slide"))
    return out


def text_outside_frames(slide):
    framed = set()
    for shape in slide.shapes:
        body = shape.find(P + "txBody")
        if body is not None:
            framed.update(id(node) for node in body.iter(A + "t"))
    return [node for node in slide.tree.iter(A + "t") if id(node) not in framed]


def check_copy(slide, expected, kinds):
    """Every bound string sits in the text frame its key names, exactly; nothing else carries text
    except the closed chrome vocabulary: `[n]` register numbers and relationship kinds."""
    out = []
    want = dict(expected["keys"])
    if expected["register"]:
        want[expected["register"]["name"]] = expected["register"]["lines"]
    for key, paragraphs_wanted in want.items():
        name = key if key.startswith(("value:", "register:")) else f"copy:{key}"
        shapes = slide.named.get(name, [])
        if not shapes:
            out.append(finding("copy-omitted", "frozen-copy", key, f"{key} is on no text frame of {slide.name}"))
            continue
        if len(shapes) > 1:
            out.append(finding("copy-invented", "frozen-copy", key, f"{key} is placed {len(shapes)} times"))
        got = texts(shapes[0])
        if got != paragraphs_wanted:
            out.append(finding("copy-changed", "frozen-copy", key, f"{key} reads {got!r}, not {paragraphs_wanted!r}"))
        if shapes[0].find(P + "txBody") is None or shapes[0].tag != P + "sp":
            out.append(finding("text-outside-frame", "editable-text", key, f"{key} is not native text in a shape"))
    wanted_names = {key if key.startswith(("value:", "register:")) else f"copy:{key}" for key in want}
    for name, shapes in slide.named.items():
        if name.startswith(("copy:", "value:", "register:")) and name not in wanted_names:
            out.append(finding("copy-invented", "frozen-copy", name, f"{name} is not content {slide.name} binds"))
        elif name.startswith("cites:"):
            for text in texts(shapes[0]):
                if any(not re.fullmatch(r"\[[0-9]+\]", token) for token in text.split()):
                    out.append(finding("invented-text", "chrome-text", name, f"{name} shows {text!r}"))
        elif name.startswith("kind:"):
            for text in texts(shapes[0]):
                if text not in kinds:
                    out.append(finding("invented-text", "chrome-text", name, f"{name} shows {text!r}"))
        elif not name.startswith(("copy:", "value:", "register:")):
            for shape in shapes:
                if any(text.strip() for text in texts(shape)):
                    out.append(finding("invented-text", "chrome-text", name, f"{name} carries text that is neither "
                                       "copy nor chrome"))
    if text_outside_frames(slide):
        out.append(finding("text-outside-frame", "editable-text", slide.name, "the slide carries text outside a "
                           "shape's text frame"))
    got_notes = texts(slide.notes_body) if slide.notes_body is not None else []
    if got_notes != expected["notes"]:
        code = "copy-omitted" if expected["notes"] and not got_notes else "copy-changed"
        out.append(finding(code, "notes", slide.name, f"the notes of {slide.name} read {got_notes!r}, not "
                           f"{expected['notes']!r}"))
    return out


def cell_text(cell, shared):
    if cell.get("t") == "inlineStr":
        return "".join(node.text or "" for node in cell.iter(S + "t"))
    value = cell.find(S + "v")
    text = value.text if value is not None and value.text is not None else ""
    if cell.get("t") == "s":
        return shared[int(text)] if text.isdigit() and int(text) < len(shared) else None
    return text


def workbook_cells(data):
    book = zipfile.ZipFile(io.BytesIO(data))
    names = book.namelist()
    shared = []
    if "xl/sharedStrings.xml" in names:
        shared = ["".join(node.text or "" for node in item.iter(S + "t"))
                  for item in ET.fromstring(book.read("xl/sharedStrings.xml")).iter(S + "si")]
    sheet = ET.fromstring(book.read("xl/worksheets/sheet1.xml"))
    return {cell.get("r"): cell_text(cell, shared) for cell in sheet.iter(S + "c")}


def check_chart(pkg, slide, expected, content):
    """The sourced chart is one native chart part, backed by an embedded workbook, whose categories,
    values and series name are the brief's labels, literal numbers and unit."""
    unit = expected["unit"]
    charts = [shape for shape in slide.shapes if kind_of(shape) == "chart"]
    pictures = [shape for shape in slide.shapes if shape.tag == P + "pic"]
    if expected["family"] != "chart":
        return [finding("chart-native", "chart", slide.name, f"{slide.name} carries a chart its unit does not bind")] \
            if charts else []
    items = [content.data(point["data_ref"]) for point in unit.get("data_bindings", [])]
    if len(charts) != 1 or pictures:
        return [finding("chart-native", "chart", unit["id"], f"{unit['id']} has {len(charts)} native chart(s) and "
                        f"{len(pictures)} picture(s); a sourced chart is one native chart")]
    node = charts[0].find(f".//{C}chart")
    rel = slide.rels.get(node.get(R + "id")) if node is not None else None
    if rel is None or not rel["type"].endswith("/chart") or rel["resolved"] not in pkg.parts:
        return [finding("chart-native", "chart", unit["id"], "the chart frame names no chart part")]
    chart = pkg.tree(rel["resolved"])
    series = chart.findall(f".//{C}barChart/{C}ser")
    if len(series) != 1:
        return [finding("chart-native", "chart", unit["id"], f"the chart part holds {len(series)} bar series, not one")]
    external = chart.find(f"{C}externalData")
    book_rel = pkg.rels(rel["resolved"]).get(external.get(R + "id")) if external is not None else None
    if book_rel is None or not book_rel["type"].endswith("/package") or book_rel["resolved"] not in pkg.parts \
            or not book_rel["resolved"].startswith("ppt/embeddings/"):
        return [finding("chart-native", "chart", unit["id"], "the chart has no embedded workbook")]
    ser = series[0]
    name = [node.text or "" for node in ser.findall(f"{C}tx//{C}v")]
    labels = [node.text or "" for node in ser.findall(f"{C}cat//{C}pt/{C}v")]
    values = [node.text or "" for node in ser.findall(f"{C}val//{C}numCache/{C}pt/{C}v")]
    unit_text = items[0]["unit"] if items else ""
    want_labels = [item["label"] for item in items]
    want_values = [core.number_text(item["value"]) for item in items]
    out = []
    if name != [unit_text] or labels != want_labels or values != want_values:
        out.append(finding("chart-values", "chart", unit["id"], f"the chart carries {name} / {labels} / {values}, not "
                           f"{[unit_text]} / {want_labels} / {want_values}"))
    try:
        cells = workbook_cells(pkg.parts[book_rel["resolved"]])
    except (zipfile.BadZipFile, KeyError, ET.ParseError) as exc:
        return out + [finding("chart-native", "chart", unit["id"], f"the embedded workbook is unreadable: {exc}")]
    got = ([cells.get("B1")], [cells.get(f"A{i}") for i in range(2, len(items) + 2)],
           [cells.get(f"B{i}") for i in range(2, len(items) + 2)])
    if got != ([unit_text], want_labels, want_values):
        out.append(finding("chart-values", "chart", unit["id"], f"the workbook carries {got}, not the supplied "
                           "unit, labels and values"))
    return out


def check_system(slide, expected):
    """One editable node shape per entity and one connector per relationship, glued to the nodes it
    joins, in the composition's order, each labelled with its kind."""
    unit = expected["unit"]
    if expected["family"] != "system":
        return []
    problems, ids = [], {}
    for entity in unit.get("entities", []):
        key = f"{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
        shapes = slide.named.get(f"copy:{key}", [])
        if len(shapes) != 1 or kind_of(shapes[0]) != "shape":
            problems.append(f"entity {entity['id']} is not one editable node shape")
            continue
        ids[entity["id"]] = props(shapes[0])[0]
    connectors = []
    for shape in slide.shapes:
        if shape.tag == P + "cxnSp":
            start, end = shape.find(f".//{A}stCxn"), shape.find(f".//{A}endCxn")
            connectors.append((start.get("id") if start is not None else None, end.get("id") if end is not None else None))
    want = [(ids.get(relation["from"]), ids.get(relation["to"])) for relation in unit.get("relationships", [])]
    if connectors != want or None in {part for pair in want for part in pair}:
        problems.append(f"connectors {connectors} do not join the related nodes {want}")
    for relation in unit.get("relationships", []):
        label = slide.named.get(f"kind:{relation['from']}:{relation['to']}", [])
        if len(label) != 1 or texts(label[0]) != [relation["kind"]]:
            problems.append(f"relationship {relation['from']}->{relation['to']} is not labelled {relation['kind']!r}")
    return [finding("system-semantics", "conceptual", unit["id"], "; ".join(problems))] if problems else []


def link_of(rpr, rels):
    link = rpr.find(A + "hlinkClick") if rpr is not None else None
    if link is None:
        return None
    rel = rels.get(link.get(R + "id"))
    if rel is None:
        return ("missing", link.get(R + "id"))
    if link.get("action") == SLIDE_JUMP:
        return ("slide", rel["resolved"])
    return ("url", rel["target"]) if rel["external"] else ("internal", rel["resolved"])


def check_citations(found, expected_slides, content, numbers):
    """Every `[N]` marker in copy is a hyperlink run on the marker whose relationship targets that
    source's URL byte for byte (or jumps to the register slide for a source without one); every
    source a unit names without a marker is linked from its `[n]` frame; the register links every URL."""
    out = []
    markers = {source.get("marker"): source for source in content.sources.values() if source.get("marker")}
    register_part = next((slide.part for slide, want in zip(found, expected_slides) if want["register"]), None)

    def target_of(source):
        url = source.get("url")
        return ("url", url) if isinstance(url, str) and url else ("slide", register_part)

    def marker_runs(shape, rels, owner):
        for _, runs in paragraphs(shape):
            for text, rpr in runs:
                hits = list(CITATION.finditer(text))
                if not hits:
                    continue
                if len(hits) != 1 or hits[0].group(0) != text:
                    out.append(finding("citation-missing", "citation", owner, f"{owner} shows {text!r} without a link"))
                    continue
                source = markers.get(text)
                link = link_of(rpr, rels)
                if source is None:
                    out.append(finding("citation-unresolved", "citation", text, f"{owner} links {text}, which names no "
                                       "source"))
                elif link is None:
                    out.append(finding("citation-missing", "citation", text, f"{owner} shows {text} without a link"))
                elif link != target_of(source):
                    out.append(finding("citation-substituted", "citation", text, f"{owner} links {text} to {link[1]!r}, "
                                       f"not {target_of(source)[1]!r}"))

    for slide, want in zip(found, expected_slides):
        for name, shapes in slide.named.items():
            if name.startswith("copy:"):
                for shape in shapes:
                    marker_runs(shape, slide.rels, name)
        if slide.notes_body is not None:
            marker_runs(slide.notes_body, slide.notes_rels, f"notes:{slide.name}")
        cites = slide.named.get(f"cites:{slide.name}", [])
        links = []
        for shape in cites:
            for _, runs in paragraphs(shape):
                links += [(text, link_of(rpr, slide.rels)) for text, rpr in runs if text.strip()]
        for ref in want["cites"]:
            source = content.sources.get(ref)
            label = f"[{numbers.get(ref)}]"
            if source is None or label not in [text for text, _ in links]:
                out.append(finding("citation-missing", "citation", ref, f"{slide.name} does not link source {ref}"))
            elif (label, target_of(source)) not in links:
                out.append(finding("citation-substituted", "citation", ref, f"{slide.name} links {label} elsewhere"))
        if want["register"]:
            shapes = slide.named.get(want["register"]["name"], [])
            paras = paragraphs(shapes[0]) if shapes else []
            for index, ref in enumerate(want["register"]["refs"]):
                source = content.sources[ref]
                url = source.get("url")
                if not (isinstance(url, str) and url):
                    continue
                runs = paras[index][1] if index < len(paras) else []
                linked = [link_of(rpr, slide.rels) for text, rpr in runs if text == url]
                if not linked or linked[0] is None:
                    out.append(finding("citation-missing", "register", ref, f"the register does not link {url}"))
                elif linked[0] != ("url", url):
                    out.append(finding("citation-substituted", "register", ref, f"the register links {linked[0][1]!r} "
                                       f"for {url!r}"))
    return out


def declared_fallback(name, units, library):
    """The fallback the pattern library declares for the pptx target on the variant of the unit a slide
    is named for — read from the library, never from the writer — or None."""
    unit = units.get(name)
    if unit is None:
        return None
    for pattern in library["patterns"]:
        for variant in (pattern["variants"] if pattern["id"] == unit["pattern"] else []):
            fallback = variant.get("fallback") if variant["id"] == unit["variant"] else None
            if isinstance(fallback, dict) and fallback.get("target") == "pptx":
                return fallback
    return None


def check_objects(found, manifest, library, composition):
    """Every object on every slide appears in the manifest with its true kind and editability, and a
    picture — a flattened figure — must be the fallback its unit's variant declares, listed among the
    manifest's fallbacks and carrying a text alternative."""
    out = []
    by_part = {entry.get("part"): entry for entry in (manifest or {}).get("slides", []) if isinstance(entry, dict)}
    listed_fallbacks = [item for item in (manifest or {}).get("fallbacks", []) if isinstance(item, dict)]
    vocabulary = set(library["targets"]["pptx"]["capabilities"])
    units = {unit["id"]: unit for unit in composition["units"]}
    for slide in found:
        declared = {str(item.get("shape_id")): item for item in (by_part.get(slide.part) or {}).get("objects", [])
                    if isinstance(item, dict)}
        seen = set()
        for shape in slide.shapes:
            sid, name = props(shape)
            kind = kind_of(shape)
            item = declared.get(str(sid))
            seen.add(str(sid))
            if kind == "image":
                # Three arms, one code: a picture with no entry at all; an entry that still claims
                # native editability for it; and a fallback entry missing its capability or its reason.
                fallback = (item or {}).get("fallback") or {}
                if item is None:
                    out.append(finding("unreported-flattening", "fallback", f"{slide.name}:{name}",
                                       f"{slide.name} carries picture {name!r} that no manifest fallback declares"))
                    continue
                if item.get("editable") is not False:
                    out.append(finding("unreported-flattening", "fallback", f"{slide.name}:{name}",
                                       f"{slide.name} carries picture {name!r} that the manifest records as natively "
                                       "editable"))
                    continue
                if not fallback.get("capability") or not fallback.get("reason"):
                    out.append(finding("unreported-flattening", "fallback", f"{slide.name}:{name}",
                                       f"picture {name!r} has a fallback entry that declares no capability or no reason"))
                    continue
                # The gate is per variant: the recorded fallback must be exactly the declaration of the
                # variant this slide's unit uses, so a sibling variant of the same pattern admits no picture.
                if fallback != declared_fallback(slide.name, units, library):
                    out.append(finding("undeclared-fallback", "fallback", f"{slide.name}:{name}",
                                       f"picture {name!r} claims fallback {fallback.get('capability')!r}, which the "
                                       "unit's variant does not declare for pptx"))
                    continue
                if not any(listed.get("shape_id") == item.get("shape_id") and listed.get("name") == name
                           and listed.get("fallback") == fallback for listed in listed_fallbacks):
                    out.append(finding("unreported-flattening", "fallback", f"{slide.name}:{name}",
                                       f"picture {name!r} is missing from the manifest's fallbacks"))
                    continue
                descr = shape.find(f"{P}nvPicPr/{P}cNvPr")
                if descr is None or not (descr.get("descr") or "").strip():
                    out.append(finding("description-missing", "fallback", f"{slide.name}:{name}",
                                       f"picture {name!r} carries no text alternative"))
                continue
            if manifest is None:
                continue
            if item is None:
                out.append(finding("manifest-object", "manifest", f"{slide.name}:{name}",
                                   f"{slide.name} object {name!r} is not in the manifest"))
            elif item.get("name") != name or item.get("kind") != kind:
                out.append(finding("manifest-object", "manifest", f"{slide.name}:{name}",
                                   f"the manifest records {item.get('name')!r}/{item.get('kind')!r} for {name!r}/{kind!r}"))
            elif item.get("editable") is not True or kind not in EDITABLE_KINDS:
                out.append(finding("manifest-editability", "manifest", f"{slide.name}:{name}",
                                   f"{name!r} is native but recorded as editable={item.get('editable')!r}"))
            elif item.get("capability") not in vocabulary:
                out.append(finding("manifest-editability", "manifest", f"{slide.name}:{name}",
                                   f"{name!r} records capability {item.get('capability')!r}"))
        if manifest is not None:
            for sid, item in declared.items():
                if sid not in seen:
                    out.append(finding("manifest-object", "manifest", f"{slide.name}:{item.get('name')}",
                                       f"the manifest records {item.get('name')!r}, which {slide.name} does not carry"))
    if manifest is not None:
        listed = [entry.get("part") for entry in manifest.get("slides", []) if isinstance(entry, dict)]
        if listed != [slide.part for slide in found]:
            out.append(finding("manifest-object", "manifest", "slides", f"the manifest lists {listed}"))
    return out


def check_manifest(pkg, data, manifest, composition, theme):
    """The manifest is a complete pptx-manifest@1: it names the package it describes, the fonts, the
    brand and its revision, every embedded asset by digest, the writer and the runtime."""
    out = []
    missing = [key for key in MANIFEST_KEYS if key not in manifest]
    if manifest.get("artifact_type") != "pptx-manifest" or manifest.get("artifact_version") != "1" or missing:
        return [finding("manifest-invalid", "manifest", ",".join(missing) or "artifact_type",
                        "the manifest is not a complete pptx-manifest@1")]

    def named(value, *keys):
        return isinstance(value, dict) and all(isinstance(value.get(key), str) and value[key] for key in keys)

    if not named(manifest["writer"], "name", "version") or not named(manifest["runtime"], "name", "version"):
        out.append(finding("manifest-identity", "manifest", "writer", "the manifest does not name its writer and runtime"))
    if manifest["design_system"] != composition["design_system"] or not named(manifest["design_system"], "name",
                                                                              "version"):
        out.append(finding("manifest-identity", "manifest", "design_system",
                           "the manifest does not record the composition's design system and revision"))
    if not named(manifest["theme"], "slug", "tokens_sha256") or (theme is not None and
                                                                  manifest["theme"]["tokens_sha256"] != theme.digest):
        out.append(finding("manifest-identity", "manifest", "theme", "the manifest does not record the theme tokens"))
    fonts = manifest["fonts"]
    if not isinstance(fonts, list) or not fonts or not all(
            isinstance(font, dict) and isinstance(font.get("requested_family"), str) and font.get("resolved_face")
            and font.get("typeface") and isinstance(font.get("substituted"), bool) for font in fonts):
        out.append(finding("manifest-identity", "manifest", "fonts", "the manifest does not record every font choice"))
    elif "ppt/theme/theme1.xml" in pkg.parts:
        latin = pkg.tree("ppt/theme/theme1.xml").find(f".//{A}minorFont/{A}latin")
        copy = next((font for font in fonts if font.get("token") == core.COPY_FONT_TOKEN), fonts[0])
        if latin is None or latin.get("typeface") != copy.get("typeface"):
            out.append(finding("manifest-identity", "manifest", "fonts", "the theme's typeface is not the recorded one"))
    package = manifest["package"]
    if not isinstance(package, dict) or package.get("sha256") != core.sha256_bytes(data):
        out.append(finding("manifest-identity", "manifest", "package", "the manifest describes a different package"))
    embedded = sorted(name for name in pkg.parts if name.startswith(("ppt/embeddings/", "ppt/media/")))
    assets = manifest["assets"] if isinstance(manifest["assets"], list) else []
    recorded = sorted(asset.get("part") for asset in assets if isinstance(asset, dict))
    if recorded != embedded:
        out.append(finding("manifest-identity", "manifest", "assets", f"the manifest records assets {recorded}, the "
                           f"package embeds {embedded}"))
    for asset in assets:
        if isinstance(asset, dict) and asset.get("part") in pkg.parts and \
                asset.get("sha256") != core.sha256_bytes(pkg.parts[asset["part"]]):
            out.append(finding("manifest-identity", "manifest", asset["part"], f"{asset['part']} does not match its digest"))
    readability = manifest["readability"]
    if not isinstance(readability, dict) or not isinstance(readability.get("min_sz"), int):
        out.append(finding("manifest-identity", "manifest", "readability", "the manifest records no readability minimum"))
    return out


SIZE_TAGS = (A + "rPr", A + "defRPr", A + "endParaRPr")
CHROME_PREFIXES = ("cites:", "kind:")


def slot_role(slot, unit, pattern, library):
    """The type role a slot resolves to: its default — the role the pattern declares for that slot in the
    library, else the render path's own table — raised on the canvas to the pattern's minimum role or the
    unit's type_floor, exactly as design-render.md §Type roles states it. Notes sit aside and are not
    raised."""
    role = core.slot_default_role(pattern, slot)
    if slot not in core.ASIDE_SLOTS:
        scale = library["type_scale"]
        floor = unit.get("type_floor", pattern["constraints"]["min_type_role"])
        if scale.index(role) < scale.index(floor):
            role = floor
    return role


def slot_floors(found, composition, library, theme):
    """Slide name -> shape name -> (role, minimum sz in hundredths of a point), from the composition,
    the pattern library and the theme alone. A copy shape takes its binding's slot; a data label or
    value the series slot; the register its evidence slot; the cover title display and subtitle lead;
    a unit's cites frame and a connector's kind token, chrome, caption."""
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}

    def sz(role):
        return int(round(theme.px("typography", core.TYPE_ROLE_TOKENS[role][0]) * 75))

    floors = {"document": {"copy:document#title": ("type.display", sz("type.display")),
                           "copy:document#subtitle": ("type.lead", sz("type.lead"))}}
    for unit in composition["units"]:
        pattern = patterns[unit["pattern"]]
        roles = {slot: slot_role(slot, unit, pattern, library) for slot in pattern["accessibility"]["reading_order"]}
        names = {}
        for binding in unit.get("bindings", []):
            role = roles.get(binding["slot"], slot_role(binding["slot"], unit, pattern, library))
            names[f"copy:{binding['record_ref']}#{binding['field']}"] = role
        for point in unit.get("data_bindings", []):
            role = roles.get("series", slot_role("series", unit, pattern, library))
            names[f"copy:data:{point['data_ref']}#label"] = role
            names[f"value:{point['data_ref']}"] = role
        if unit.get("register_refs"):
            names[f"register:{unit['id']}"] = roles.get("evidence", slot_role("evidence", unit, pattern, library))
        floors[unit["id"]] = {name: (role, sz(role)) for name, role in names.items()}
        floors[unit["id"]]["notes"] = ("type.body", sz("type.body"))
        floors[unit["id"]]["chrome"] = ("type.caption", sz("type.caption"))
    return floors


def shape_floor(name, floors):
    """The (role, sz) floor a shape name resolves to, or None for a shape that carries no copy."""
    if name in floors:
        return floors[name]
    stem = name.rsplit("#", 1)[0] if "#" in name and name.rsplit("#", 1)[1].isdigit() else None
    if stem in floors:
        return floors[stem]
    if name.startswith(CHROME_PREFIXES):
        return floors.get("chrome")
    return None


def check_type(pkg, min_sz, floors=None):
    """No text body hands shrinking to the opening application; no run on a slide is set below the size of
    the type role its slot resolves to; and no run anywhere is set below the readability minimum, the
    theme's caption size, which stays as the backstop."""
    out = []
    for name in sorted(pkg.parts):
        if not name.startswith("ppt/") or not name.endswith(".xml"):
            continue
        for node in pkg.tree(name).iter():
            if node.tag == A + "normAutofit" or "fontScale" in node.attrib:
                out.append(finding("autofit", "fit", name, f"{name} lets the application shrink text"))
            size = node.get("sz") if node.tag in SIZE_TAGS else None
            if size is not None and min_sz is not None and size.isdigit() and int(size) < min_sz:
                out.append(finding("readability", "fit", name, f"{name} sets text at sz {size}, below {min_sz}"))
    if not floors:
        return out
    for part in sorted(pkg.parts):
        if part.startswith("ppt/slides/") and part.endswith(".xml"):
            slide = Slide(pkg, part)
            for shape in slide.shapes:
                out += run_floor(shape, props(shape)[1], slide.name, shape_floor(props(shape)[1], floors.get(slide.name, {})))
        elif part.startswith("ppt/notesSlides/") and part.endswith(".xml"):
            for shape in shapes_of(pkg.tree(part)):
                shape_name = props(shape)[1]
                if shape_name.startswith("notes:"):
                    unit = shape_name[len("notes:"):]
                    out += run_floor(shape, shape_name, unit, floors.get(unit, {}).get("notes"))
    return out


def run_floor(shape, name, slide_name, floor):
    if floor is None:
        return []
    role, minimum = floor
    low = sorted({int(node.get("sz")) for node in shape.iter()
                  if node.tag in SIZE_TAGS and (node.get("sz") or "").isdigit() and int(node.get("sz")) < minimum})
    if not low:
        return []
    return [finding("readability", "fit", f"{slide_name}:{name}",
                    f"{name} sets text at sz {low[0]}, below its slot's {role} size {minimum}")]


def check_bounds(found, extent):
    out = []
    width, height = extent
    for slide in found:
        for shape in slide.shapes:
            node = shape.find(f"{P}spPr/{A}xfrm")
            if node is None:
                node = shape.find(P + "xfrm")
            off, ext = (node.find(A + "off"), node.find(A + "ext")) if node is not None else (None, None)
            if off is None or ext is None:
                continue
            x, y, cx, cy = (int(off.get("x")), int(off.get("y")), int(ext.get("cx")), int(ext.get("cy")))
            if x < 0 or y < 0 or x + cx > width or y + cy > height:
                out.append(finding("fit-overflow", "bounds", f"{slide.name}:{props(shape)[1]}",
                                   f"{props(shape)[1]} leaves the slide"))
    return out


def guarded(name, check, *args):
    """A malformed package answers with a finding, never a traceback."""
    try:
        return check(*args)
    except (Unreadable, KeyError, ValueError, TypeError, AttributeError, IndexError, ET.ParseError,
            zipfile.BadZipFile) as exc:
        return [finding("package-unreadable", name, name, f"{name} could not read the package: {exc}")]


def check_pptx(data, brief, composition, theme=None, manifest=None):
    library, _ = core.validator.load_library(core.validator.DEFAULT_LIBRARY)
    try:
        pkg = Package(data)
        findings = check_package(pkg)
        _, parts, extent = slide_parts(pkg)
        found = [Slide(pkg, part) for part in parts]
    except (Unreadable, KeyError, ValueError, ET.ParseError) as exc:
        return [finding("package-unreadable", "package", "package", str(exc))]
    expected, content, numbers = expectations(brief, composition, library)
    findings += check_order(found, expected)
    pairs = [(slide, want) for slide, want in zip(found, expected) if slide.name == want["name"]]
    kinds = set(library["relationship_kinds"])
    for slide, want in pairs:
        findings += guarded("frozen-copy", check_copy, slide, want, kinds)
        if want["unit"] is not None:
            findings += guarded("chart", check_chart, pkg, slide, want, content)
            findings += guarded("conceptual", check_system, slide, want)
    if len(pairs) == len(found) == len(expected):
        findings += guarded("citation", check_citations, found, expected, content, numbers)
    findings += guarded("fallback", check_objects, found, manifest, library, composition)
    if manifest is not None:
        findings += guarded("manifest", check_manifest, pkg, data, manifest, composition, theme)
    min_sz, floors = None, None
    if theme is not None:
        min_sz = int(round(theme.px("typography", "size-small") * 75))
        floors = guarded("fit", slot_floors, found, composition, library, theme)
        if isinstance(floors, list):  # the derivation itself failed: report it, keep the backstop
            findings += floors
            floors = None
    elif isinstance(manifest, dict) and isinstance((manifest.get("readability") or {}).get("min_sz"), int):
        min_sz = manifest["readability"]["min_sz"]
    findings += guarded("fit", check_type, pkg, min_sz, floors)
    findings += guarded("bounds", check_bounds, found, extent)
    return findings


def check_manifest_identity(manifest, provenance):
    """A delivered manifest names the writer the provenance names and the package it records."""
    out = []
    renderer = provenance.get("renderer") or {}
    writer = manifest.get("writer") if isinstance(manifest, dict) else None
    if not isinstance(writer, dict) or writer.get("name") != renderer.get("name") \
            or writer.get("version") != renderer.get("version"):
        out.append(finding("writer-mismatch", "manifest", "writer", "the manifest's writer is not the renderer the "
                           "provenance records"))
    artifact = (provenance.get("outputs") or {}).get("artifact") or {}
    package = manifest.get("package") if isinstance(manifest, dict) else None
    if not isinstance(package, dict) or package.get("sha256") != artifact.get("sha256"):
        out.append(finding("writer-mismatch", "manifest", "package", "the manifest describes a package the provenance "
                           "does not record"))
    return out
