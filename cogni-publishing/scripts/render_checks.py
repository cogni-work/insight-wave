"""Independent fidelity checks for design-render output. Stdlib only.

Every expectation here is derived from the frozen inputs — the normalized brief, the composition and
the theme — never from renderer output, so a damaged renderer cannot agree with itself. The page is
read with html.parser; entity decoding is the only transformation applied to its text. Each check
returns findings `{code, check, reference, message}`; an empty list is a pass.

references/design-render.md states the rules these checks enforce: the copy-key scheme, the closed
chrome vocabulary, the citation, register, reading-order and description rules, the portability scan,
the comparator's volatile fields and tolerance, and the lock policy.
"""

import json
import re
from html.parser import HTMLParser
from pathlib import Path

import render_core as core

CITATION = re.compile(r"\[([0-9]+)\]")
EXACT_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
REGISTRY = "https://registry.npmjs.org/"
VOID = {"meta", "link", "br", "img", "input", "hr", "source", "area", "base", "col", "embed", "wbr"}
GEOMETRY_PARENTS = {"box", "frame"}
DEFAULT_TOLERANCE = 0.5
TRUNCATING_CSS = (
    (re.compile(r"text-overflow\s*:\s*ellipsis", re.I), "text-overflow: ellipsis"),
    (re.compile(r"line-clamp", re.I), "line-clamp"),
    (re.compile(r"display\s*:\s*none", re.I), "display: none"),
    (re.compile(r"visibility\s*:\s*hidden", re.I), "visibility: hidden"),
    (re.compile(r"overflow(?:-[xy])?\s*:\s*(?:hidden|clip)", re.I), "overflow: hidden"),
    (re.compile(r"max-height\s*:", re.I), "max-height"),
)
CSS_LITERAL = re.compile(r"#[0-9a-fA-F]{3,8}\b|\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch)\s*\(|font-family\s*:(?!\s*var\()",
                         re.I)
RUNTIME_GITIGNORE = ("node_modules/", "browsers/", ".provisioned.json")


def finding(code, check, reference, message):
    return {"code": code, "check": check, "reference": reference, "message": message}


# --- a small DOM over html.parser ---------------------------------------------------------------------

class Node:
    def __init__(self, tag, attrs, parent):
        self.tag = tag
        self.attrs = dict(attrs)
        self.parent = parent
        self.children = []  # Node or str

    def text(self):
        return "".join(child if isinstance(child, str) else child.text() for child in self.children)

    def iter(self):
        for child in self.children:
            if isinstance(child, Node):
                yield child
                yield from child.iter()

    def ancestors(self):
        node = self.parent
        while node is not None:
            yield node
            node = node.parent

    def inside(self, tag):
        return any(node.tag == tag for node in self.ancestors())

    def classes(self):
        return set((self.attrs.get("class") or "").split())


class TreeBuilder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("#document", [], None)
        self.current = self.root

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs, self.current)
        self.current.children.append(node)
        if tag not in VOID:
            self.current = node

    def handle_startendtag(self, tag, attrs):
        self.current.children.append(Node(tag, attrs, self.current))

    def handle_endtag(self, tag):
        node = self.current
        while node is not None and node.tag != tag:
            node = node.parent
        if node is not None and node.parent is not None:
            self.current = node.parent

    def handle_data(self, data):
        self.current.children.append(data)


def parse(html):
    builder = TreeBuilder()
    builder.feed(html)
    builder.close()
    return builder.root


def elements(root, tag=None, **attrs):
    for node in root.iter():
        if tag is not None and node.tag != tag:
            continue
        if all(node.attrs.get(key.replace("_", "-")) == value for key, value in attrs.items()):
            yield node


def by_id(root):
    return {node.attrs["id"]: node for node in root.iter() if node.attrs.get("id")}


# --- expectations from the frozen inputs ---------------------------------------------------------

def expected_copy(brief, composition):
    """copy key -> the exact string the page must show, from the brief alone."""
    content = core.Content(brief)
    expected = {}
    for unit in composition["units"]:
        for binding in unit.get("bindings", []):
            value = content.field(binding["record_ref"], binding["field"])
            key = f"{binding['record_ref']}#{binding['field']}"
            if isinstance(value, list):
                expected.update({f"{key}#{i}": item for i, item in enumerate(value)})
            else:
                expected[key] = value
        for point in unit.get("data_bindings", []):
            expected[f"data:{point['data_ref']}#label"] = content.data(point["data_ref"])["label"]
        for ref in unit.get("register_refs", []):
            source = content.sources[ref]
            if isinstance(source.get("raw"), str):
                expected[f"source:{ref}#raw"] = source["raw"]
            else:
                expected.update({f"source:{ref}#{key}": source[key] for key in core.source_fields(source)})
    for binding in composition.get("document_bindings", []):
        expected[f"trailer#{binding['index']}"] = content.index.trailer[binding["index"]]
    document = brief.get("document") or {}
    for key in ("title", "subtitle"):
        if isinstance(document.get(key), str) and document[key]:
            expected[f"document#{key}"] = document[key]
    return expected


def expected_values(brief, composition):
    """data id -> the value label: the brief's literal number, one space, its unit verbatim."""
    content = core.Content(brief)
    return {point["data_ref"]: f"{core.number_text(content.data(point['data_ref'])['value'])} "
                               f"{content.data(point['data_ref'])['unit']}"
            for unit in composition["units"] for point in unit.get("data_bindings", [])}


# --- checks ---------------------------------------------------------------------------------------

def check_frozen_copy(root, brief, composition):
    expected = expected_copy(brief, composition)
    values = expected_values(brief, composition)
    found = {}
    for node in root.iter():
        if "data-copy" in node.attrs:
            found.setdefault(node.attrs["data-copy"], []).append(node.text())
    out = []
    for key, want in expected.items():
        if key not in found:
            out.append(finding("copy-omitted", "frozen-copy", key, f"{key} is rendered nowhere"))
        for got in found.get(key, []):
            if got != want:
                out.append(finding("copy-changed", "frozen-copy", key, f"{key} renders {got!r}, not {want!r}"))
    for key in found:
        if key not in expected:
            out.append(finding("copy-invented", "frozen-copy", key, f"{key} is not content the composition binds"))
    labels = {}
    for node in root.iter():
        if "data-value" in node.attrs:
            labels.setdefault(node.attrs["data-value"], []).append(node.text())
    for ref, want in values.items():
        if ref not in labels:
            out.append(finding("copy-omitted", "frozen-copy", f"data:{ref}#value", f"the value of {ref} is not shown"))
        for got in labels.get(ref, []):
            if got != want:
                out.append(finding("copy-changed", "frozen-copy", f"data:{ref}#value",
                                   f"{ref} is labelled {got!r}, not {want!r}"))
    return out


def check_chrome_text(root, library):
    """Visible text outside copy is limited to the closed chrome vocabulary."""
    kinds = set(library["relationship_kinds"])
    out = []

    def walk(node, in_copy):
        for child in node.children:
            if isinstance(child, Node):
                if child.tag in ("head", "style", "title"):
                    continue
                walk(child, in_copy or "data-copy" in child.attrs or "data-value" in child.attrs)
            elif not in_copy and child.strip():
                token = child.strip()
                if not (re.fullmatch(r"\[[0-9]+\]", token) or token in kinds):
                    out.append(finding("invented-text", "chrome-text", token[:60],
                                       f"visible text {token[:60]!r} is neither copy nor chrome"))
    walk(root, False)
    return out


def check_scripts(root):
    out = []
    for node in root.iter():
        if node.tag == "script":
            out.append(finding("script", "script", "script", "the page carries a script element"))
        for key, value in node.attrs.items():
            if key.startswith("on"):
                out.append(finding("script", "script", key, f"{node.tag} carries an event handler {key}"))
            if isinstance(value, str) and value.strip().lower().startswith("javascript:"):
                out.append(finding("script", "script", key, f"{node.tag} {key} is a javascript: URL"))
    return out


def check_assets(root, html):
    """Nothing the page needs comes from outside it: no remote or file reference, no import, and every
    fragment reference resolves inside the page. Navigational <a href> links are exempt."""
    out = []
    ids = by_id(root)
    for node in root.iter():
        for key, value in node.attrs.items():
            if value is None:
                continue
            if node.tag == "a" and key == "href":
                if value.startswith("#") and value[1:] not in ids:
                    out.append(finding("local-reference", "assets", value, f"link {value} names no element"))
                continue
            if key in ("src", "href", "srcset", "poster", "data", "xlink:href", "action", "background"):
                out.append(finding("remote-asset" if re.match(r"(?:https?:)?//", value) else "local-reference",
                                   "assets", value, f"{node.tag} {key} loads {value!r}"))
            for ref in re.findall(r"url\(\s*['\"]?([^)'\"]*)", value):
                if not ref.startswith("#") or ref[1:] not in ids:
                    out.append(finding("remote-asset", "assets", ref, f"{node.tag} {key} references url({ref})"))
            if key in ("aria-labelledby", "aria-describedby"):
                for ref in value.split():
                    if ref not in ids:
                        out.append(finding("local-reference", "assets", ref, f"{key} names missing element {ref}"))
        if node.tag == "link":
            out.append(finding("remote-asset", "assets", node.attrs.get("href", "link"), "the page links a resource"))
    styles = "".join(node.text() for node in elements(root, "style"))
    for ref in re.findall(r"@import[^;]*|url\([^)]*\)", styles):
        out.append(finding("remote-asset", "assets", ref, f"the stylesheet references {ref}"))
    for pattern in (r"file:", r"(?<![A-Za-z0-9])/(?:Users|home|private|tmp|var|opt)/", r"[A-Za-z]:\\\\",
                    r"cogni-workspace", r"node_modules", r"ms-playwright"):
        hit = re.search(pattern, html)
        if hit:
            out.append(finding("local-reference", "assets", hit.group(0), f"the page mentions {hit.group(0)!r}"))
    return out


def check_truncation(root):
    out = []
    styles = [node.text() for node in elements(root, "style")]
    styles += [node.attrs["style"] for node in root.iter() if node.attrs.get("style")]
    for css in styles:
        for pattern, name in TRUNCATING_CSS:
            if pattern.search(css):
                out.append(finding("truncating-css", "truncation-css", name, f"the page's CSS applies {name}"))
    for node in root.iter():
        if "hidden" in node.attrs or node.attrs.get("aria-hidden") == "true":
            if "data-copy" in node.attrs or any("data-copy" in n.attrs for n in node.iter()):
                out.append(finding("hidden-copy", "truncation-css", node.tag, "copy sits inside a hidden element"))
    return out


def unit_sections(root):
    return [node for node in elements(root, "section") if "data-unit" in node.attrs]


def check_reading_order(root, composition, library):
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    out = []
    dom = [section.attrs["data-unit"] for section in unit_sections(root)]
    want = [unit["id"] for unit in composition["units"]]
    if dom != want:
        out.append(finding("reordered-unit", "reading-order", ",".join(dom), f"DOM unit order {dom} is not {want}"))
        return out
    for section, unit in zip(unit_sections(root), composition["units"]):
        reading = patterns[unit["pattern"]]["accessibility"]["reading_order"]
        slots = [node.attrs["data-slot"] for node in section.iter() if "data-slot" in node.attrs]
        positions = [reading.index(slot) if slot in reading else -1 for slot in slots]
        if -1 in positions or positions != sorted(positions) or len(set(slots)) != len(slots):
            out.append(finding("reordered-unit", "reading-order", unit["id"],
                               f"unit {unit['id']} slots {slots} leave the reading order {reading}"))
    return out


def check_descriptions(root, brief, composition):
    """Every figure is named by exactly its claim and described by its text alternative."""
    content = core.Content(brief)
    ids = by_id(root)
    out = []
    sections = {section.attrs["data-unit"]: section for section in unit_sections(root)}
    for unit in composition["units"]:
        section = sections.get(unit["id"])
        if section is None:
            continue
        claim = next((content.field(b["record_ref"], b["field"]) for b in unit.get("bindings", [])
                      if b["slot"] in ("claim", "answer", "heading")), None)
        for svg in elements(section, "svg"):
            name_ref = svg.attrs.get("aria-labelledby")
            named = ids.get(name_ref) if name_ref else None
            if svg.attrs.get("role") != "img" or named is None or named.text() != claim:
                out.append(finding("description-missing", "description", unit["id"],
                                   f"the figure in {unit['id']} is not named by its claim"))
            alt = ids.get(svg.attrs.get("aria-describedby") or "")
            if alt is None or not alt.text().strip():
                out.append(finding("description-missing", "description", unit["id"],
                                   f"the figure in {unit['id']} has no text alternative"))
    return out


def check_patterns(root, brief, composition, library):
    """One semantic assertion per proof pattern."""
    content = core.Content(brief)
    values = expected_values(brief, composition)
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    sections = {section.attrs["data-unit"]: section for section in unit_sections(root)}
    out = []
    for unit in composition["units"]:
        section = sections.get(unit["id"])
        family = patterns[unit["pattern"]]["family"]
        if section is None:
            out.append(finding("unit-omitted", "patterns", unit["id"], f"unit {unit['id']} is not rendered"))
            continue
        if unit["pattern"] == "comparison":
            want = []
            for binding in unit["bindings"]:
                if binding["slot"] != "items":
                    continue
                value = content.field(binding["record_ref"], binding["field"])
                key = f"{binding['record_ref']}#{binding['field']}"
                want += [f"{key}#{i}" for i in range(len(value))] if isinstance(value, list) else [key]
            cells = [node for node in section.iter() if node.tag == "td" and "data-side" in node.attrs]
            got = []
            for cell in cells:
                keys = [n.attrs["data-copy"] for n in cell.iter() if "data-copy" in n.attrs]
                got.append(keys[0] if len(keys) == 1 else None)
            sides = [cell.attrs["data-side"] for cell in cells]
            if len(want) < 2 or got != want or sides != [str(i) for i in range(1, len(want) + 1)]:
                out.append(finding("comparison-structure", "comparison", unit["id"],
                                   f"comparison {unit['id']} ties {got} to sides {sides}; expected {want}"))
        elif family == "chart":
            refs = [point["data_ref"] for point in unit.get("data_bindings", [])]
            svg = next(elements(section, "svg"), None)
            marks = [node for node in svg.iter() if node.tag == "rect" and "mark" in node.classes()] if svg else []
            problems = []
            if [mark.attrs.get("data-ref") for mark in marks] != refs:
                problems.append(f"marks {[m.attrs.get('data-ref') for m in marks]} are not the data {refs}")
            for point in (svg.iter() if svg else []):
                if point.tag == "g" and "point" in point.classes():
                    ref = point.attrs.get("data-ref")
                    label = [n for n in point.iter() if n.attrs.get("data-copy") == f"data:{ref}#label"]
                    value = [n for n in point.iter() if n.attrs.get("data-value") == ref]
                    if len(label) != 1 or len(value) != 1 or value[0].text() != values.get(ref):
                        problems.append(f"point {ref} lacks its own label or literal value label")
            if problems:
                out.append(finding("chart-semantics", "chart", unit["id"], "; ".join(problems)))
        elif family == "system":
            svg = next(elements(section, "svg"), None)
            problems = []
            for entity in unit.get("entities", []):
                value = content.field(entity["record_ref"], entity["field"])
                label = value[entity["item"]] if "item" in entity else value
                nodes = [n for n in (svg.iter() if svg else []) if n.tag == "g" and n.attrs.get("data-entity") == entity["id"]]
                texts = [t.text() for node in nodes for t in node.iter() if t.tag == "text"]
                if label not in texts:
                    problems.append(f"entity {entity['id']} is not labelled {label!r}")
            edges = [(n.attrs.get("data-from"), n.attrs.get("data-to"), n.attrs.get("data-kind"),
                      "".join(t.text() for t in n.iter() if t.tag == "text"))
                     for n in (svg.iter() if svg else []) if n.tag == "g" and "edge" in n.classes()]
            want = [(r["from"], r["to"], r["kind"], r["kind"]) for r in unit.get("relationships", [])]
            if edges != want:
                problems.append(f"relationships {edges} are not {want}")
            if problems:
                out.append(finding("system-semantics", "conceptual", unit["id"], "; ".join(problems)))
        elif family == "register":
            entries = [node.attrs.get("data-source") for node in section.iter()
                       if node.tag == "li" and "data-source" in node.attrs]
            if entries != unit.get("register_refs", []):
                out.append(finding("register-order", "register", unit["id"],
                                   f"the register lists {entries}, not {unit.get('register_refs')}"))
            if unit_sections(root)[-1] is not section:
                out.append(finding("register-not-last", "register", unit["id"], "the source register is not last"))
    return out


def check_citations(root, brief, composition):
    """Every [N] in copy links to source N's URL; every source a record names without a marker is
    linked from its unit; a register-number link carries that source's own URL."""
    content = core.Content(brief)
    markers = {source.get("marker"): source for source in content.sources.values() if source.get("marker")}
    out = []

    def href(source):
        url = source.get("url")
        return url if isinstance(url, str) and url else f"#src-{source['id']}"

    for node in root.iter():
        if "data-copy" not in node.attrs or node.inside("svg") or node.attrs["data-copy"].startswith("source:"):
            continue
        for child in node.children:
            if isinstance(child, str):
                for match in CITATION.finditer(child):
                    out.append(finding("citation-missing", "citation", match.group(0),
                                       f"{node.attrs['data-copy']} shows {match.group(0)} without a link"))
            elif child.tag == "a":
                marker = child.text()
                source = markers.get(marker)
                if source is None:
                    out.append(finding("citation-unresolved", "citation", marker,
                                       f"{node.attrs['data-copy']} links {marker}, which names no source"))
                elif child.attrs.get("href") != href(source) or child.attrs.get("data-source") != source["id"]:
                    out.append(finding("citation-substituted", "citation", marker,
                                       f"{marker} links {child.attrs.get('href')!r}, not {href(source)!r}"))
    numbers = {source_id: position for position, source_id in enumerate(content.source_order, 1)}
    sections = {section.attrs["data-unit"]: section for section in unit_sections(root)}
    for unit in composition["units"]:
        section = sections.get(unit["id"])
        if section is None:
            continue
        links = [(a.attrs.get("data-source"), a.attrs.get("href"), a.text()) for a in section.iter()
                 if a.tag == "a" and "cite" in a.classes()]
        needed = []
        for ref in dict.fromkeys(b["record_ref"] for b in unit.get("bindings", [])):
            record = content.index.records[ref]
            texts = [v for _, _, value in core.validator.content_fields(record)
                     for v in (value if isinstance(value, list) else [value]) if isinstance(v, str)]
            if not any(CITATION.search(t) for t in texts):
                needed += record.get("source_refs", [])
        for point in unit.get("data_bindings", []):
            needed += content.data(point["data_ref"]).get("source_refs", [])
        for ref in needed:
            source = content.sources.get(ref)
            if source is None or (ref, href(source), f"[{numbers[ref]}]") not in links:
                out.append(finding("citation-missing", "citation", ref, f"unit {unit['id']} does not link source {ref}"))
        for source_id, target, label in links:
            source = content.sources.get(source_id)
            if source is None:
                out.append(finding("citation-unresolved", "citation", label, f"link {label} names no source"))
            elif target != href(source):
                out.append(finding("citation-substituted", "citation", label,
                                   f"{label} links {target!r}, not {href(source)!r}"))
    return out


def component_css(root):
    styles = "".join(node.text() for node in elements(root, "style"))
    marker = "/* design-render: components */"
    return styles, styles.split(marker, 1)[1] if marker in styles else None


def check_tokens(root, composition, theme):
    """The theme's compiled token block is carried verbatim, component CSS uses tokens only, and every
    proof pattern on the page is styled through at least one theme token."""
    styles, components = component_css(root)
    out = []
    if theme.css not in styles:
        out.append(finding("token-block", "tokens", theme.slug, "the theme's compiled token block is not carried verbatim"))
    if components is None:
        return out + [finding("token-block", "tokens", "components", "the component rules are missing")]
    for hit in CSS_LITERAL.findall(components):
        out.append(finding("css-literal", "tokens", hit, f"component CSS carries the literal {hit!r}"))
    declared = {name for name in re.findall(r"(--[A-Za-z0-9-]+)\s*:", theme.css)}
    for pattern in dict.fromkeys(unit["pattern"] for unit in composition["units"]):
        rules = re.findall(r"([^{}]*\.pattern-" + re.escape(pattern) + r"\b[^{}]*)\{([^}]*)\}", components)
        used = {name for _, body in rules for name in re.findall(r"var\((--[A-Za-z0-9-]+)\)", body)}
        if not used & declared:
            out.append(finding("token-unused", "tokens", pattern, f"no rule styles {pattern} through a theme token"))
    return out


def check_html(html, brief, composition, theme=None):
    library, _ = core.validator.load_library(core.validator.DEFAULT_LIBRARY)
    root = parse(html)
    findings = []
    findings += check_frozen_copy(root, brief, composition)
    findings += check_chrome_text(root, library)
    findings += check_scripts(root)
    findings += check_assets(root, html)
    findings += check_truncation(root)
    findings += check_reading_order(root, composition, library)
    findings += check_descriptions(root, brief, composition)
    findings += check_patterns(root, brief, composition, library)
    findings += check_citations(root, brief, composition)
    if theme is not None:
        findings += check_tokens(root, composition, theme)
    return findings


# --- provenance -----------------------------------------------------------------------------------

def check_provenance(provenance, composition=None, plan=None, out_dir=None):
    out = []
    if not isinstance(provenance, dict) or provenance.get("artifact_type") != "render-provenance" \
            or provenance.get("artifact_version") != "1":
        return [finding("invalid-artifact", "provenance", "artifact_type", "not a render-provenance@1")]
    fonts = provenance.get("fonts")
    if not isinstance(fonts, list) or not fonts:
        out.append(finding("font-unrecorded", "fonts", "fonts", "provenance records no font resolution"))
        fonts = []
    for font in fonts:
        token = font.get("token") if isinstance(font, dict) else None
        stack = font.get("requested_stack") if isinstance(font, dict) else None
        if not isinstance(stack, list) or not stack or font.get("requested_family") != stack[0] \
                or not isinstance(font.get("resolved_face"), str) or not font["resolved_face"] \
                or not isinstance(font.get("substituted"), bool):
            out.append(finding("font-unrecorded", "fonts", str(token), f"{token} lacks a complete resolution record"))
            continue
        silent = font["resolved_face"] != stack[0] and not font["substituted"]
        unrecorded = font["substituted"] and (not isinstance(font.get("fallback_chain"), list)
                                              or not font["fallback_chain"] or not font.get("skipped"))
        if silent or unrecorded:
            out.append(finding("silent-substitution", "fonts", str(token),
                               f"{token} resolved to {font['resolved_face']!r} without a recorded fallback"))
    copy_font = next((f for f in fonts if isinstance(f, dict) and f.get("token") == core.COPY_FONT_TOKEN), None)
    if copy_font is None or provenance.get("layout_face") != copy_font.get("resolved_face"):
        out.append(finding("font-layout", "fonts", core.COPY_FONT_TOKEN,
                           "the layout face is not the resolved copy face"))
    if plan is not None and copy_font is not None:
        faces = {slot["measured_with"] for unit in plan["units"] for slot in unit["slots"]}
        if faces != {copy_font.get("resolved_face")}:
            out.append(finding("font-layout", "fonts", core.COPY_FONT_TOKEN,
                               f"the plan was measured with {sorted(faces)}, not the resolved face"))
    runtime = provenance.get("runtime") or {}
    deps = runtime.get("dependencies")
    if not isinstance(deps, dict) or not deps or not all(EXACT_VERSION.match(str(v)) for v in deps.values()) \
            or not str(runtime.get("lock_sha256", "")).startswith("sha256:"):
        out.append(finding("runtime-unpinned", "runtime", "runtime", "provenance does not record an exact runtime pin"))
    if composition is not None:
        if provenance.get("content_fingerprint") != composition["normalized_brief_ref"]["content_fingerprint"]:
            out.append(finding("fingerprint-mismatch", "fingerprint", "content_fingerprint",
                               "the recorded fingerprint is not the composition's"))
        if provenance.get("design_system") != composition["design_system"]:
            out.append(finding("design-system", "design-system", "design_system",
                               "the recorded design system is not the composition's pin"))
    if out_dir is not None:
        for name, output in (provenance.get("outputs") or {}).items():
            path = Path(out_dir) / output.get("path", "")
            if not path.is_file() or core.sha256_file(path) != output.get("sha256"):
                out.append(finding("output-digest", "outputs", name, f"{output.get('path')} does not match its digest"))
    return out


# --- comparator -----------------------------------------------------------------------------------

def compare(expected, actual, tolerance=DEFAULT_TOLERANCE, volatile=core.VOLATILE_FIELDS):
    """Differences between two plans or measurement reports. Only the declared volatile top-level
    fields are ignored; geometry under a box or frame may drift by `tolerance` px; everything else —
    every id, digest, string, count and line estimate — must be equal."""
    differences = []

    def walk(a, b, path, parent):
        if isinstance(a, dict) and isinstance(b, dict):
            for key in sorted(set(a) | set(b)):
                if not path and key in volatile:
                    continue
                if key not in a or key not in b:
                    differences.append({"path": f"{path}.{key}".lstrip("."), "expected": a.get(key), "actual": b.get(key)})
                else:
                    walk(a[key], b[key], f"{path}.{key}".lstrip("."), key)
        elif isinstance(a, list) and isinstance(b, list):
            if len(a) != len(b):
                differences.append({"path": path, "expected": len(a), "actual": len(b)})
            for i, (x, y) in enumerate(zip(a, b)):
                walk(x, y, f"{path}[{i}]", parent)
        elif path.split(".")[-2:-1] in ([key] for key in GEOMETRY_PARENTS):
            numeric = all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in (a, b))
            if not numeric or abs(a - b) > tolerance:
                differences.append({"path": path, "expected": a, "actual": b})
        elif a != b or type(a) is not type(b) and not all(isinstance(v, (int, float)) for v in (a, b)):
            differences.append({"path": path, "expected": a, "actual": b})

    walk(expected, actual, "", None)
    return differences


def copy_sequence(html):
    return [(node.attrs["data-copy"], node.text()) for node in parse(html).iter() if "data-copy" in node.attrs]


# --- runtime lock ---------------------------------------------------------------------------------

def check_runtime_lock(runtime_dir):
    """Every required package is pinned to an exact version and locked with a registry URL and a
    sha512 integrity hash; no install hook runs; the install directories stay ignored."""
    runtime_dir = Path(runtime_dir)
    out = []
    try:
        manifest = json.loads((runtime_dir / "package.json").read_text(encoding="utf-8"))
        lock = json.loads((runtime_dir / "package-lock.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [finding("lock-missing", "runtime-lock", str(runtime_dir), f"manifest or lockfile unreadable: {exc}")]
    deps = {}
    for key in ("dependencies", "optionalDependencies", "devDependencies", "peerDependencies"):
        deps.update(manifest.get(key) or {})
    if not deps:
        out.append(finding("lock-missing", "runtime-lock", "dependencies", "the manifest declares no dependency"))
    for name, version in deps.items():
        if not isinstance(version, str) or not EXACT_VERSION.match(version):
            out.append(finding("range-pin", "runtime-lock", name, f"{name} is pinned as {version!r}, not an exact x.y.z"))
    for hook in ("preinstall", "install", "postinstall", "prepare"):
        if hook in (manifest.get("scripts") or {}):
            out.append(finding("install-script", "runtime-lock", hook, f"the manifest runs a {hook} script"))
    packages = lock.get("packages")
    if not isinstance(lock.get("lockfileVersion"), int) or lock["lockfileVersion"] < 2 or not isinstance(packages, dict):
        return out + [finding("lock-missing", "runtime-lock", "package-lock.json", "the lockfile has no packages map")]
    root_deps = (packages.get("") or {}).get("dependencies") or {}
    if root_deps != (manifest.get("dependencies") or {}):
        out.append(finding("lock-mismatch", "runtime-lock", "dependencies", "the lockfile root does not mirror the manifest"))
    for name, version in deps.items():
        entry = packages.get(f"node_modules/{name}")
        if entry is None:
            out.append(finding("lock-missing", "runtime-lock", name, f"{name} is missing from the lockfile"))
        elif entry.get("version") != version:
            out.append(finding("lock-mismatch", "runtime-lock", name, f"{name} locks {entry.get('version')}, not {version}"))
    for path, entry in packages.items():
        if not path:
            continue
        if not str(entry.get("resolved", "")).startswith(REGISTRY) or not str(entry.get("integrity", "")).startswith("sha512-") \
                or not EXACT_VERSION.match(str(entry.get("version", ""))):
            out.append(finding("lock-unhashed", "runtime-lock", path,
                               f"{path} is not an exact, registry-resolved, sha512-hashed entry"))
    ignored = (runtime_dir / ".gitignore").read_text(encoding="utf-8").split() if (runtime_dir / ".gitignore").is_file() else []
    for pattern in RUNTIME_GITIGNORE:
        if pattern not in ignored:
            out.append(finding("install-tracked", "runtime-lock", pattern, f"runtime/.gitignore does not ignore {pattern}"))
    return out
