"""HTML target adapter of design-render: one self-contained, branded HTML document from a laid-out plan.

Stdlib only. Every original string — a headline, a point, a note, a label, a unit, a source field —
reaches the page through `text()`, once, as escaped text: never as markup, never rewritten, never
trimmed, and never split except at the citation markers it already carries — or, for an entity or
chart label inside an SVG figure, into the <tspan> lines the plan counted (render_core.wrap_lines).
That split breaks at whitespace and hard-cuts only a word longer than the line; it cuts the raw
string before escaping and joins the lines with nothing between them, so the label's <text> element
still reads the string exactly. The adapter takes the split from the core and never wraps itself. Numbers keep the literal the brief
wrote. The page carries no script, loads nothing remote and references no file: its CSS is an
@font-face for the copy face when the theme ships it — the face's own bytes as a data URI, ahead of the
token block — the theme's compiled token block, and component rules that use only those tokens.

A copy-bearing element is marked `data-copy="<key>"` so its text can be checked against the frozen
brief; render_checks.py owns that check and references/design-render.md the key scheme.
"""

import base64
import re
from html import escape

import render_core as core

CITATION = re.compile(r"\[([0-9]+)\]")
COMPONENTS_MARKER = "/* design-render: components */"

# Component rules. They reference theme tokens through var() only: no color, font-family or other
# brand literal lives here, and nothing hides, clamps or clips copy. Figure label and value text sets
# no size of its own: it inherits its slot's type-<role> size, the size the plan measured it at.
COMPONENT_CSS = """
html { background: var(--colors-bg); }
body { margin: 0; font-family: var(--render-font-copy); color: var(--colors-text); background: var(--colors-bg); }
.masthead { max-width: var(--render-canvas-width); margin: 0 auto; padding: var(--spacing-6) var(--spacing-7); }
.masthead h1 { font-size: var(--typography-size-h2); line-height: var(--typography-line-height-h2); margin: 0; }
.masthead p { color: var(--colors-text-muted); margin: var(--spacing-3) 0 0; }
.deck { scroll-snap-type: y proximity; }
.unit { scroll-snap-align: start; box-sizing: border-box; width: 100%; max-width: var(--render-canvas-width); margin: 0 auto var(--spacing-6); padding: var(--spacing-7); background: var(--colors-surface); border: 1px solid var(--colors-border); }
.slot { margin: 0 0 var(--spacing-5); }
.slot > :first-child { margin-top: 0; }
[data-copy] { white-space: pre-wrap; overflow-wrap: anywhere; }
.type-display { font-size: var(--typography-size-display); line-height: var(--typography-line-height-display); }
.type-heading { font-size: var(--typography-size-h2); line-height: var(--typography-line-height-h2); }
.type-lead { font-size: var(--typography-size-h3); line-height: var(--typography-line-height-h3); }
.type-body { font-size: var(--typography-size-body); line-height: var(--typography-line-height-body); }
.type-caption { font-size: var(--typography-size-small); line-height: var(--typography-line-height-small); }
.slot h2 { font-size: inherit; line-height: inherit; margin: 0; }
.slot p { margin: 0; }
.points { margin: 0; padding-left: var(--spacing-5); }
.points li + li { margin-top: var(--spacing-3); }
.evidence { color: var(--colors-text-muted); }
.cites { color: var(--colors-text-muted); font-size: var(--typography-size-small); line-height: var(--typography-line-height-small); }
a { color: inherit; text-decoration-color: var(--colors-accent); }
.pattern-answer-emphasis .slot-answer { border-left: var(--spacing-2) solid var(--colors-accent); padding-left: var(--spacing-4); }
.pattern-comparison table { width: 100%; border-collapse: separate; border-spacing: var(--spacing-3); table-layout: fixed; }
.pattern-comparison td { vertical-align: top; padding: var(--spacing-4); background: var(--colors-bg); border-top: var(--spacing-1) solid var(--colors-accent); }
.pattern-sourced-chart svg { width: 100%; height: auto; overflow: visible; }
.pattern-sourced-chart .mark { fill: var(--colors-accent); stroke: var(--colors-text); }
.pattern-sourced-chart .baseline { stroke: var(--colors-text); }
.pattern-sourced-chart text { fill: var(--colors-text); }
.pattern-sourced-chart .data-alt { margin-top: var(--spacing-4); border-collapse: collapse; }
.pattern-sourced-chart .data-alt th, .pattern-sourced-chart .data-alt td { text-align: left; padding: var(--spacing-1) var(--spacing-4) var(--spacing-1) 0; border-bottom: 1px solid var(--colors-border); font-weight: normal; }
.pattern-conceptual-system svg { width: 100%; height: auto; overflow: visible; }
.pattern-conceptual-system .node rect { fill: var(--colors-bg); stroke: var(--colors-text); }
.pattern-conceptual-system .node text { fill: var(--colors-text); }
.pattern-conceptual-system .edge path { fill: none; stroke: var(--colors-accent); stroke-width: 2; }
.pattern-conceptual-system .edge text { fill: var(--colors-text-muted); font-size: var(--typography-size-small); }
.pattern-conceptual-system .arrowhead { fill: var(--colors-accent); }
.pattern-conceptual-system .entity-alt, .pattern-conceptual-system .relation-alt { margin: var(--spacing-4) 0 0; padding-left: var(--spacing-5); color: var(--colors-text-muted); }
.pattern-sources .register { margin: 0; padding-left: 0; list-style: none; }
.pattern-sources .register li + li { margin-top: var(--spacing-3); }
.slot-notes { margin-top: var(--spacing-5); padding-top: var(--spacing-4); border-top: 1px dashed var(--colors-border); color: var(--colors-text-muted); }
.trailer-notes { max-width: var(--render-canvas-width); margin: 0 auto var(--spacing-7); padding: 0 var(--spacing-7); color: var(--colors-text-muted); }
"""


def text(value):
    return escape(value, quote=True)


def attr(value):
    return escape(str(value), quote=True)


def dom_id(*parts):
    return "-".join(re.sub(r"[^A-Za-z0-9_-]", "-", str(part)) for part in parts)


def font_face(face):
    """One shipped face as an in-page @font-face: its file's bytes as a single data URI with the matching
    format() hint, so the browser loads nothing and consults no installed font for it."""
    payload = base64.b64encode(face["data"]).decode("ascii")
    return (f'@font-face {{ font-family: "{face["family"]}"; src: url(data:{face["mime"]};base64,{payload}) '
            f'format("{face["format"]}"); }}\n')


def tspans(lines, x, first_y, step):
    """A figure label's display lines as <tspan> children of its one copy-bearing <text>. Nothing is
    emitted between them, and no line carries a copy key, so the <text> reads the label exactly."""
    return "".join(f'<tspan x="{round(x, 2)}" y="{round(first_y + index * step, 2)}">{text(line)}</tspan>'
                   for index, line in enumerate(lines))


class Page:
    def __init__(self, brief, composition, plan, theme, font, language, faces=()):
        self.content = core.Content(brief)
        self.brief = brief
        self.composition = composition
        self.plan = plan
        self.theme = theme
        self.font = font
        self.language = language
        self.faces = list(faces)
        self.markers = {source.get("marker"): source for source in self.content.sources.values()
                        if isinstance(source.get("marker"), str)}
        self.register_numbers = {source_id: position for position, source_id in
                                 enumerate(self.content.source_order, 1)}

    # --- inline copy ------------------------------------------------------------------------------

    def copy_inline(self, value):
        """An original string as escaped text, with each `[N]` marker it carries turned into a link to
        that source's URL. The marker keeps its own characters, so the text is unchanged."""
        out, last = [], 0
        for match in CITATION.finditer(value):
            source = self.markers.get(match.group(0))
            if source is None:
                raise core.RenderError("unresolved-citation", f"the marker {match.group(0)} names no source record",
                                       "citation", match.group(0), artifact="normalized_brief")
            out.append(text(value[last:match.start()]))
            out.append(f'<a class="cite" href="{attr(self.href(source))}" data-source="{attr(source["id"])}">'
                       f'{text(match.group(0))}</a>')
            last = match.end()
        out.append(text(value[last:]))
        return "".join(out)

    def href(self, source):
        url = source.get("url")
        return url if isinstance(url, str) and url else f"#{dom_id('src', source['id'])}"

    def copy_element(self, tag, key, value, cls=None):
        klass = f' class="{cls}"' if cls else ""
        return f'<{tag}{klass} data-copy="{attr(key)}">{self.copy_inline(value)}</{tag}>'

    def cites(self, source_refs):
        """Links for sources a record names without inline markers (a direct brief's sections)."""
        links = [f'<a class="cite" href="{attr(self.href(self.content.sources[ref]))}" data-source="{attr(ref)}">'
                 f'[{self.register_numbers[ref]}]</a>' for ref in source_refs]
        return f' <span class="cites">{" ".join(links)}</span>' if links else ""

    def record_cites(self, record_ref, done):
        """Once per record, after its first rendered field, when its copy carries no marker of its own."""
        if record_ref in done:
            return ""
        done.add(record_ref)
        record = self.content.index.records[record_ref]
        fields = [value for _, _, value in validator_fields(record)]
        inline = any(CITATION.search(item) for value in fields
                     for item in (value if isinstance(value, list) else [value]) if isinstance(item, str))
        return "" if inline else self.cites(record.get("source_refs", []))

    # --- slots ------------------------------------------------------------------------------------

    def binding_blocks(self, entries, heading_tag, done):
        html = []
        for entry in entries:
            value = self.content.field(entry["record_ref"], entry["field"])
            key = f"{entry['record_ref']}#{entry['field']}"
            if isinstance(value, list):
                items = "".join(f"<li>{self.copy_element('span', f'{key}#{i}', item)}</li>"
                                for i, item in enumerate(value))
                html.append(f'<ul class="points">{items}</ul>')
            elif entry["field"] in ("headline", "title"):
                html.append(self.copy_element(heading_tag, key, value))
            elif entry["field"] == "evidence_status":
                html.append(self.copy_element("p", key, value, "evidence"))
            else:
                html.append(self.copy_element("p", key, value))
            html.append(self.record_cites(entry["record_ref"], done))
        return "".join(html)

    def comparison_items(self, unit, entries, done):
        items = []
        for entry in entries:
            value = self.content.field(entry["record_ref"], entry["field"])
            key = f"{entry['record_ref']}#{entry['field']}"
            if isinstance(value, list):
                items.extend((f"{key}#{i}", item, entry["record_ref"]) for i, item in enumerate(value))
            else:
                items.append((key, value, entry["record_ref"]))
        cells = []
        for side, (key, value, record_ref) in enumerate(items, 1):
            cell_id = dom_id("side", unit["id"], side)
            cells.append((side, f'<td id="{cell_id}" data-side="{side}">{self.copy_element("span", key, value)}'
                                f'{self.record_cites(record_ref, done)}</td>'))
        if unit["variant"] == "tabular":
            rows = "".join(f'<tr data-side="{side}">{cell}</tr>' for side, cell in cells)
        else:
            rows = f'<tr>{"".join(cell for _, cell in cells)}</tr>'
        return f'<table class="comparison variant-{attr(unit["variant"])}"><tbody>{rows}</tbody></table>'

    def layout(self):
        return core.Layout(self.theme, self.font, _library())

    def chart(self, unit, slot, entries, claim_id):
        """The one bounded SVG path for data: a mark per supplied point, labelled with the brief's own
        label, literal value and unit, and a data table as its text alternative. Marks share one zero
        baseline: a positive value extends right of it, a negative value left of it. Every point gets
        the row the plan measured for the chart, as tall as its tallest label, and its label wraps
        inside the label column; the mark and the value label keep the geometry of a one-line row at
        the top of it."""
        box = slot["box"]
        width = box["width"]
        layout = self.layout()
        role = slot["type_role"]
        size, ratio = layout.metrics(role)
        band = core.series_band(layout, role)
        label_w, bar_w = core.chart_label_column(width), width * core.CHART_BAR_SHARE
        items = [self.content.data(entry["data_ref"]) for entry in entries]
        values = [float(item["value"]) for item in items]
        high = max((v for v in values if v > 0), default=0.0)
        low = max((-v for v in values if v < 0), default=0.0)
        span = (high + low) or 1.0
        zero = label_w + bar_w * low / span
        table_id = dom_id("data", unit["id"])
        rows = core.series_rows(layout, [item["label"] for item in items], width, role)
        marks, y = [], 0.0
        for item, number, (lines, row) in zip(items, values, rows):
            length = round(abs(number) / span * bar_w, 2)
            start = zero if number >= 0 else zero - length
            value = f"{core.number_text(item['value'])} {item['unit']}"
            marks.append(
                f'<g class="point" data-ref="{attr(item["id"])}">'
                f'<text x="0" y="{round(y + band * 0.62, 2)}" data-copy="{attr("data:" + item["id"] + "#label")}">'
                f'{tspans(lines, 0, y + band * 0.62, size * ratio)}</text>'
                f'<rect class="mark" data-ref="{attr(item["id"])}" x="{round(start, 2)}" y="{round(y + band * 0.15, 2)}" '
                f'width="{length}" height="{round(band * 0.6, 2)}"></rect>'
                f'<text x="{round((zero + length if number >= 0 else zero) + 8, 2)}" y="{round(y + band * 0.62, 2)}" '
                f'data-value="{attr(item["id"])}">{text(value)}</text></g>')
            y += row
        height = y if items else box["height"]
        baseline = (f'<line class="baseline" x1="{round(zero, 2)}" y1="0" x2="{round(zero, 2)}" y2="{round(height, 2)}">'
                    f'</line>' if low else "")
        svg = (f'<svg role="img" aria-labelledby="{claim_id}" aria-describedby="{table_id}" '
               f'viewBox="0 0 {round(width, 2)} {round(height, 2)}" width="{round(width, 2)}" height="{round(height, 2)}">'
               f'{baseline}{"".join(marks)}</svg>')
        rows_html = "".join(
            f'<tr data-ref="{attr(item["id"])}"><th scope="row" data-copy="{attr("data:" + item["id"] + "#label")}">'
            f'{text(item["label"])}</th><td data-value="{attr(item["id"])}">'
            f'{text(core.number_text(item["value"]) + " " + item["unit"])}</td>'
            f'<td>{self.cites(item.get("source_refs", [])).strip()}</td></tr>' for item in items)
        return f'<figure class="chart">{svg}<table class="data-alt" id="{table_id}"><tbody>{rows_html}</tbody></table></figure>'

    def system(self, unit, slot, claim_id, done):
        """The same bounded SVG path for a conceptual system: one node per declared entity, one labelled
        connector per relationship, and an entity list as its text alternative. Each node is as tall as
        the plan measured its label, which wraps inside the node; the connector gutter stays free."""
        box = slot["box"]
        width = box["width"]
        layout = self.layout()
        role = slot["type_role"]
        size, ratio = layout.metrics(role)
        pad, gap = layout.node_pad, layout.gap
        node_w = core.node_width(width)
        entities = unit.get("entities", [])
        labels, y, nodes, records = {}, 0.0, [], {}
        for entity in entities:
            value = self.content.field(entity["record_ref"], entity["field"])
            label = value[entity["item"]] if "item" in entity else value
            key = f"{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
            lines, node_h = core.node_box(layout, label, width, role)
            labels[entity["id"]] = (key, label, y, node_h)
            records[entity["id"]] = entity["record_ref"]
            nodes.append(f'<g class="node" data-entity="{attr(entity["id"])}"><rect x="0" y="{round(y, 2)}" '
                         f'width="{round(node_w, 2)}" height="{round(node_h, 2)}" rx="4"></rect>'
                         f'<text x="{round(pad, 2)}" y="{round(y + pad + size, 2)}" data-copy="{attr(key)}">'
                         f'{tspans(lines, pad, y + pad + size, size * ratio)}</text></g>')
            y += node_h + gap
        total = max(y - gap, 1.0)
        marker_id = dom_id("arrow", unit["id"])
        edges = []
        for position, relation in enumerate(unit.get("relationships", [])):
            _, _, from_y, from_h = labels[relation["from"]]
            _, _, to_y, to_h = labels[relation["to"]]
            start, end = from_y + from_h / 2, to_y + to_h / 2
            bend = node_w + 40 + 30 * position
            edges.append(f'<g class="edge" data-kind="{attr(relation["kind"])}" data-from="{attr(relation["from"])}" '
                         f'data-to="{attr(relation["to"])}"><path d="M {round(node_w, 2)} {round(start, 2)} '
                         f'C {round(bend, 2)} {round(start, 2)} {round(bend, 2)} {round(end, 2)} {round(node_w, 2)} '
                         f'{round(end, 2)}" marker-end="url(#{marker_id})"></path><text x="{round(bend + 6, 2)}" '
                         f'y="{round((start + end) / 2, 2)}">{attr(relation["kind"])}</text></g>')
        list_id = dom_id("entities", unit["id"])
        svg = (f'<svg role="img" aria-labelledby="{claim_id}" aria-describedby="{list_id}" '
               f'viewBox="0 0 {round(width, 2)} {round(total, 2)}" width="{round(width, 2)}" height="{round(total, 2)}">'
               f'<defs><marker id="{marker_id}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" '
               f'orient="auto-start-reverse"><path class="arrowhead" d="M 0 0 L 10 5 L 0 10 z"></path></marker></defs>'
               f'{"".join(nodes)}{"".join(edges)}</svg>')
        entity_items = "".join(f'<li data-entity="{attr(entity_id)}">{self.copy_element("span", key, label)}'
                               f'{self.record_cites(records[entity_id], done)}</li>'
                               for entity_id, (key, label, _, _) in labels.items())
        relation_items = "".join(
            f'<li data-from="{attr(relation["from"])}" data-to="{attr(relation["to"])}">'
            f'{self.copy_element("span", labels[relation["from"]][0], labels[relation["from"]][1])} '
            f'<span class="kind">{attr(relation["kind"])}</span> '
            f'{self.copy_element("span", labels[relation["to"]][0], labels[relation["to"]][1])}</li>'
            for relation in unit.get("relationships", []))
        relations = f'<ul class="relation-alt">{relation_items}</ul>' if relation_items else ""
        return f'<figure class="system variant-{attr(unit["variant"])}">{svg}<ol class="entity-alt" id="{list_id}">' \
               f'{entity_items}</ol>{relations}</figure>'

    def register(self, entries):
        items = []
        for entry in entries:
            source = self.content.sources[entry["source_ref"]]
            source_id = source["id"]
            li_id = dom_id("src", source_id)
            if isinstance(source.get("raw"), str):
                raw, url = source["raw"], source.get("url")
                if isinstance(url, str) and url and url in raw:
                    at = raw.index(url)
                    body = f'{text(raw[:at])}<a href="{attr(url)}">{text(url)}</a>{text(raw[at + len(url):])}'
                else:
                    body = text(raw)
                items.append(f'<li id="{li_id}" data-source="{attr(source_id)}">'
                             f'<span data-copy="{attr("source:" + source_id + "#raw")}">{body}</span></li>')
                continue
            parts = [f'<span class="marker">[{self.register_numbers[source_id]}]</span>']
            for key in core.source_fields(source):
                copy_key = attr(f"source:{source_id}#{key}")
                if key == "url":
                    parts.append(f'<a href="{attr(source[key])}" data-copy="{copy_key}">{text(source[key])}</a>')
                else:
                    parts.append(f'<span data-copy="{copy_key}">{text(source[key])}</span>')
            items.append(f'<li id="{li_id}" data-source="{attr(source_id)}">{" ".join(parts)}</li>')
        return f'<ol class="register">{"".join(items)}</ol>'

    # --- units ------------------------------------------------------------------------------------

    def unit(self, unit, plan_unit):
        pattern = unit["pattern"]
        claim_id = dom_id("claim", unit["id"])
        done, parts = set(), []
        slots = {slot["slot"]: slot for slot in plan_unit["slots"]}
        for slot in plan_unit["slots"]:
            name = slot["slot"]
            role_class = "type-" + slot["type_role"].split(".", 1)[1]
            entries = slot["content"]
            if name in ("answer", "claim", "heading"):
                inner = self.binding_blocks(entries, "h2", done).replace("<h2 ", f'<h2 id="{claim_id}" ', 1)
            elif name == "items" and pattern == "comparison":
                inner = self.comparison_items(unit, entries, done)
            elif name == "series":
                inner = self.chart(unit, slot, entries, claim_id)
            elif name == "entities":
                inner = self.system(unit, slot, claim_id, done)
            elif name == "evidence" and pattern == "sources":
                inner = self.binding_blocks([e for e in entries if "record_ref" in e], "p", done) + \
                        self.register([e for e in entries if "source_ref" in e])
            else:
                inner = self.binding_blocks(entries, "p", done)
            tag = "aside" if slot["placement"] == "aside" else "div"
            parts.append(f'<{tag} class="slot slot-{attr(name)} {role_class}" data-slot="{attr(name)}">{inner}</{tag}>')
        label = f' aria-labelledby="{claim_id}"' if any(n in slots for n in ("answer", "claim", "heading")) else ""
        role = f' data-role="{attr(unit["role"])}"' if unit.get("role") else ""
        frame = plan_unit["frame"]
        return (f'<section class="unit pattern-{attr(pattern)} variant-{attr(unit["variant"])}" '
                f'id="{dom_id("unit", unit["id"])}" data-unit="{attr(unit["id"])}" data-pattern="{attr(pattern)}"'
                f'{role}{label} style="min-height: {frame["height"]}px">{"".join(parts)}</section>')

    def document(self):
        doc = self.brief.get("document") or {}
        title = doc.get("title") if isinstance(doc.get("title"), str) else None
        head_title = text(title) if title else attr(self.composition["artifact_id"])
        masthead = []
        for key in ("title", "subtitle"):
            value = doc.get(key)
            if isinstance(value, str) and value:
                masthead.append(self.copy_element("h1" if key == "title" else "p", f"document#{key}", value))
        units = "".join(self.unit(unit, plan_unit)
                        for unit, plan_unit in zip(self.composition["units"], self.plan["units"]))
        trailer = ""
        if self.composition["document_bindings"]:
            notes = self.content.index.trailer
            items = "".join(f"<li>{self.copy_element('span', 'trailer#' + str(b['index']), notes[b['index']])}</li>"
                            for b in self.composition["document_bindings"])
            trailer = f'<aside class="trailer-notes" data-part="trailer"><ol>{items}</ol></aside>'
        faces = "".join(font_face(face) for face in self.faces)
        style = (f"{faces}{self.theme.css}:root {{ --render-font-copy: {core.css_font_stack(self.font)}; "
                 f"--render-canvas-width: {self.plan['canvas']['width']}px; }}\n{COMPONENTS_MARKER}{COMPONENT_CSS}")
        return ("<!DOCTYPE html>\n"
                f'<html lang="{attr(self.language)}">\n<head>\n<meta charset="utf-8">\n'
                '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
                f'<meta name="generator" content="{attr(core.RENDERER_NAME)}">\n'
                f"<title>{head_title}</title>\n<style>\n{style}</style>\n</head>\n<body>\n"
                f'<header class="masthead" data-part="document">{"".join(masthead)}</header>\n'
                f'<main class="deck">{units}</main>\n{trailer}\n</body>\n</html>\n')


def validator_fields(record):
    return core.validator.content_fields(record)


_LIBRARY = {}


def _library():
    if "library" not in _LIBRARY:
        _LIBRARY["library"], _ = core.validator.load_library(core.validator.DEFAULT_LIBRARY)
    return _LIBRARY["library"]


def render(brief, composition, plan, theme, font, language, faces=()):
    """The HTML document for a validated brief, composition and plan; `faces` are the shipped faces it
    embeds (render_core.embedded_faces)."""
    return Page(brief, composition, plan, theme, font, language, faces).document()
