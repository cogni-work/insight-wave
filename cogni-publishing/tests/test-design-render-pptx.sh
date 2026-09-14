#!/usr/bin/env bash
# design-render PPTX suite for cogni-publishing: the editable deck the pptx target writes straight from
# a target-resolved-plan@2 — outputs, the no-HTML path, package integrity, frozen copy and notes, the
# native chart and its workbook, editable system shapes, citations and slide order, the manifest's
# object bijection and identities, font resolution, fit and readability, content guards, the render
# boundary, byte determinism, theme colours, the target gate and the one declared picture fallback.
#
# This suite is also the documented capability test behind the stdlib OOXML writer, which replaces the
# PptxGenJS library the target was first specified with: every run proves from the package itself each
# of the six pptx capabilities pattern-library@1 declares — text-frame (drpx-06-frozen-copy), hyperlink
# (drpx-13-citations-and-order), editable-shapes (drpx-11-editable-shapes), native-chart
# (drpx-09-native-chart), speaker-notes (drpx-12-notes-evidence) and picture-fallback
# (drpx-27-fallback-picture). references/design-render.md states the same mapping normatively.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `drpx`; NN is an allocation counter,
# so never renumber an existing id — the mutation recipes below record four.
#
# Every expected string comes from the fixture inputs (the normalized brief and the composition), read
# by this suite's own zipfile/ElementTree reader, never from a file the renderer produced and never
# through pptx_checks.py. Every negative is derived in a scratch directory from a green render by one
# small edit; no tracked fixture is mutated. A case that needs an edited brief recomposes from a
# stripped draft with `compose`, never by typing a digest. Rendering a deck needs no runtime, so no
# case here can be skipped: every line is PASS or FAIL.
#
# Mutation recipes (run from the repository root; the harness is the installed managed-service
# cogni-service plugin, and --expr is evaluated by perl -0pi). The first makes inserted text wrong and
# must fail drpx-06; the second swaps the native chart for its text alternative and must fail drpx-09;
# the third disables the per-variant fallback gate in the checker and must fail drpx-29; the fourth gives
# each chart point its own label's row again instead of the shared tallest row, so the evenly spread
# bars leave their rows, and must fail drpx-33:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/pptx_adapter.py --expr 's/return escape\(value\)/return escape(value.upper())/' --test 'bash cogni-publishing/tests/test-design-render-pptx.sh' --case drpx-06-frozen-copy
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/pptx_adapter.py --expr 's/self\.native_chart\(/self.data_table(/' --test 'bash cogni-publishing/tests/test-design-render-pptx.sh' --case drpx-09-native-chart
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/pptx_checks.py --expr 's/if fallback != declared_fallback\(slide\.name, units, library\):/if False:/' --test 'bash cogni-publishing/tests/test-design-render-pptx.sh' --case drpx-29-per-variant-gate
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_core.py --expr 's/return \[\(lines, tallest\) for lines, _ in measured\]/return measured/' --test 'bash cogni-publishing/tests/test-design-render-pptx.sh' --case drpx-33-wrapped-chart-alignment
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$PLUGIN_ROOT/scripts/design-render.py"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-publishing.py"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
THEME="$FIXTURES/render/themes/cogni-work"
NBRIEF="$FIXTURES/narrative-slides-v1.expected.json"
NARR="$FIXTURES/composition-narrative-v2.json"
COSTS="$FIXTURES/composition-direct-costs-v2.json"
GERMAN="$FIXTURES/render/composition-direct-de-edge-v2.json"
SKILL="$PLUGIN_ROOT/skills/design-render/SKILL.md"
PYTHON="$(command -v python3)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0
failures=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

render() {  # render <out-dir> <brief> <composition> [extra args...]
  local out="$1" brief="$2" comp="$3"
  shift 3
  python3 "$RENDER" render --target pptx --brief "$brief" --composition "$comp" --theme "$THEME" \
    --out "$out" "$@" > "$out.json" 2> "$out.err"
}

# One independent reader for every case below: zipfile and ElementTree, run text only.
cat > "$WORK/deckread.py" <<'PY'
import io
import json
import posixpath
import zipfile
import xml.etree.ElementTree as ET

A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
P = "{http://schemas.openxmlformats.org/presentationml/2006/main}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
C = "{http://schemas.openxmlformats.org/drawingml/2006/chart}"
S = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RELS = "{http://schemas.openxmlformats.org/package/2006/relationships}"
TYPES = "{http://schemas.openxmlformats.org/package/2006/content-types}"


def parts(path):
    with zipfile.ZipFile(path) as archive:
        return {name: archive.read(name) for name in archive.namelist() if not name.endswith("/")}


def resolve(source, target):
    return target[1:] if target.startswith("/") else posixpath.normpath(posixpath.join(posixpath.dirname(source), target))


def rels(package, part):
    head, _, tail = part.rpartition("/")
    path = f"{head}/_rels/{tail}.rels" if head else "_rels/.rels"
    if path not in package:
        return {}
    return {rel.get("Id"): (rel.get("Type"), rel.get("Target"), rel.get("TargetMode"))
            for rel in ET.fromstring(package[path]).iter(RELS + "Relationship")}


def integrity(package):
    """Problems an application would offer to repair: an uncovered part, a relationship target that is
    not in the zip, or a relationship id a part uses that its relationships do not declare."""
    problems = []
    types = ET.fromstring(package["[Content_Types].xml"])
    defaults = {n.get("Extension").lower() for n in types.iter(TYPES + "Default")}
    overrides = {n.get("PartName").lstrip("/") for n in types.iter(TYPES + "Override")}
    for name in package:
        extension = name.rsplit(".", 1)[-1].lower()
        if name != "[Content_Types].xml" and name not in overrides and (extension == "xml" or extension not in defaults):
            problems.append(("content-type", name))
    for name in package:
        if not name.endswith(".rels"):
            continue
        head, _, tail = name.rpartition("/")
        source = posixpath.join(posixpath.dirname(head), tail[:-5])
        for rel in ET.fromstring(package[name]).iter(RELS + "Relationship"):
            if rel.get("TargetMode") != "External" and resolve(source, rel.get("Target")) not in package:
                problems.append(("target", name, rel.get("Id")))
    for name in package:
        if name.endswith(".xml") and name != "[Content_Types].xml":
            declared = rels(package, name)
            for node in ET.fromstring(package[name]).iter():
                for key, value in node.attrib.items():
                    if key.startswith(R) and value not in declared:
                        problems.append(("r:id", name, value))
    return problems


def slides(package):
    presentation = "ppt/presentation.xml"
    declared = rels(package, presentation)
    out = []
    for node in ET.fromstring(package[presentation]).iter(P + "sldId"):
        part = resolve(presentation, declared[node.get(R + "id")][1])
        tree = ET.fromstring(package[part])
        out.append((part, tree.find(P + "cSld").get("name"), tree))
    return out


def shapes(tree):
    return [node for node in tree.find(f"{P}cSld/{P}spTree")
            if node.tag in (P + "sp", P + "cxnSp", P + "graphicFrame", P + "pic")]


def name_of(shape):
    return shape.find(f".//{P}cNvPr").get("name")


def paras(shape):
    body = shape.find(P + "txBody")
    out = []
    for para in (body.findall(A + "p") if body is not None else []):
        text = ""
        for child in para:
            if child.tag == A + "r":
                text += child.find(A + "t").text or ""
            elif child.tag == A + "br":
                text += "\n"
        out.append(text)
    return out


def links(shape, declared):
    """(run text, relationship type, target, mode) for each hyperlink run of a shape."""
    out = []
    body = shape.find(P + "txBody")
    for run in (body.iter(A + "r") if body is not None else []):
        link = run.find(f"{A}rPr/{A}hlinkClick")
        if link is not None:
            kind, target, mode = declared.get(link.get(R + "id"), (None, None, None))
            out.append((run.find(A + "t").text or "", kind, target, mode))
    return out


def notes(package, part):
    for kind, target, _ in rels(package, part).values():
        if kind.endswith("/notesSlide"):
            tree = ET.fromstring(package[resolve(part, target)])
            for shape in shapes(tree):
                ph = shape.find(f"{P}nvSpPr/{P}nvPr/{P}ph")
                if ph is not None and ph.get("type") == "body":
                    return paras(shape)
    return []


def load(path):
    # Numbers keep the text the brief wrote, so a value is compared with the literal.
    return json.load(open(path, encoding="utf-8"), parse_float=str, parse_int=str)


def expected(brief, composition):
    """Slide name -> {shape name: paragraphs} and notes, from the brief and composition alone."""
    records = {r["id"]: r for r in brief["records"]}
    data = {d["id"]: d for d in brief.get("data", [])}
    sources = brief.get("sources", [])
    numbers = {s["id"]: i for i, s in enumerate(sources, 1)}
    by_id = {s["id"]: s for s in sources}

    def field(record_id, name):
        record = records[record_id]
        if record["kind"] == "slide" and name != "headline":
            return next(f["value"] for f in record["fields"] if f["key"] == name)
        return record[name]

    out = []
    document = brief.get("document") or {}
    cover = {f"copy:document#{k}": [document[k]] for k in ("title", "subtitle") if isinstance(document.get(k), str) and document[k]}
    if cover:
        out.append({"name": "document", "shapes": cover, "notes": [], "unit": None})
    for unit in composition["units"]:
        shape_map, unit_notes = {}, []
        for binding in unit["bindings"]:
            value = field(binding["record_ref"], binding["field"])
            key = binding["record_ref"] + "#" + binding["field"]
            if binding["slot"] == "notes":
                unit_notes += value if isinstance(value, list) else [value]
            elif isinstance(value, list) and (binding["slot"] == "entities" or
                                              (binding["slot"] == "items" and unit["pattern"] == "comparison")):
                shape_map.update({f"copy:{key}#{i}": [item] for i, item in enumerate(value)})
            else:
                shape_map[f"copy:{key}"] = list(value) if isinstance(value, list) else [value]
        for point in unit.get("data_bindings", []):
            item = data[point["data_ref"]]
            shape_map[f"copy:data:{item['id']}#label"] = [item["label"]]
            shape_map[f"value:{item['id']}"] = [f"{item['value']} {item['unit']}"]
        if unit.get("register_refs"):
            lines = []
            for ref in unit["register_refs"]:
                source = by_id[ref]
                lines.append(source["raw"] if "raw" in source else
                             f"[{numbers[ref]}] " + " ".join(v for k, v in source.items() if k != "id" and isinstance(v, str) and v))
            shape_map[f"register:{unit['id']}"] = lines
        out.append({"name": unit["id"], "shapes": shape_map, "notes": unit_notes, "unit": unit})
    out[-1]["notes"] = out[-1]["notes"] + [brief["freeze"]["trailer_notes"][int(b["index"])]
                                           for b in composition.get("document_bindings", [])]
    return out


def copy_problems(deck, brief_path, composition_path):
    """Every bound string, note, value, source entry and register line exactly once in its text frame;
    no copy frame the composition does not bind; no text outside a shape's text frame."""
    package = parts(deck)
    want = expected(load(brief_path), load(composition_path))
    found = slides(package)
    problems = []
    if [name for _, name, _ in found] != [slide["name"] for slide in want]:
        return [("order", [name for _, name, _ in found])]
    for (part, name, tree), slide in zip(found, want):
        named = {}
        for shape in shapes(tree):
            named.setdefault(name_of(shape), []).append(shape)
        for key, texts in slide["shapes"].items():
            got = named.get(key, [])
            if len(got) != 1 or got[0].tag != P + "sp" or paras(got[0]) != texts:
                problems.append(("copy", name, key, [paras(g) for g in got]))
        for key in named:
            if key.startswith(("copy:", "value:", "register:")) and key not in slide["shapes"]:
                problems.append(("invented", name, key))
        framed = sum(1 for shape in shapes(tree) if shape.tag == P + "sp" for _ in shape.iter(A + "t"))
        if framed != sum(1 for _ in tree.iter(A + "t")):
            problems.append(("unframed", name))
        if notes(package, part) != slide["notes"]:
            problems.append(("notes", name, notes(package, part)))
    return problems


def schema_problems(value, schema, root=None, path="$"):
    """The subset of JSON Schema the manifest schema uses: $ref, type, const, enum, required,
    properties, items, minItems, minLength, minimum, pattern and oneOf."""
    import re
    root = root or schema
    if "$ref" in schema:
        schema = root["$defs"][schema["$ref"].rsplit("/", 1)[-1]]
    if "oneOf" in schema:
        matches = [s for s in schema["oneOf"] if not schema_problems(value, s, root, path)]
        return [] if len(matches) == 1 else [(path, "oneOf")]
    kinds = schema.get("type")
    names = {"object": dict, "array": list, "string": str, "integer": int, "boolean": bool, "null": type(None)}
    if kinds is not None:
        allowed = kinds if isinstance(kinds, list) else [kinds]
        if not any(isinstance(value, names[k]) and not (k == "integer" and isinstance(value, bool)) for k in allowed):
            return [(path, "type")]
    out = []
    if "const" in schema and value != schema["const"]:
        out.append((path, "const"))
    if "enum" in schema and value not in schema["enum"]:
        out.append((path, "enum"))
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0) or ("pattern" in schema and not re.search(schema["pattern"], value)):
            out.append((path, "string"))
    if isinstance(value, int) and "minimum" in schema and value < schema["minimum"]:
        out.append((path, "minimum"))
    if isinstance(value, dict):
        out += [(f"{path}.{key}", "required") for key in schema.get("required", []) if key not in value]
        for key, sub in schema.get("properties", {}).items():
            if key in value:
                out += schema_problems(value[key], sub, root, f"{path}.{key}")
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            out.append((path, "minItems"))
        for index, item in enumerate(value):
            out += schema_problems(item, schema.get("items", {}), root, f"{path}[{index}]")
    return out


def doctor(src, dst, member, edit):
    """Copy a package, rewriting one member's text with `edit(text) -> text`."""
    with zipfile.ZipFile(src) as archive:
        entries = [(info, archive.read(info)) for info in archive.infolist()]
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as archive:
        for info, data in entries:
            if info.filename == member:
                data = edit(data.decode("utf-8")).encode("utf-8")
            archive.writestr(info, data)


def rewrite_workbook(src, dst, member, edit):
    """Copy a package, rewriting the sheet of one embedded workbook."""
    with zipfile.ZipFile(src) as archive:
        book = io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(archive.read(member))) as inner, zipfile.ZipFile(book, "w") as out:
            for info in inner.infolist():
                data = inner.read(info)
                if info.filename == "xl/worksheets/sheet1.xml":
                    data = edit(data.decode("utf-8")).encode("utf-8")
                out.writestr(info, data)
    doctor_bytes(src, dst, member, book.getvalue())


def doctor_bytes(src, dst, member, payload):
    with zipfile.ZipFile(src) as archive:
        entries = [(info, archive.read(info)) for info in archive.infolist()]
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as archive:
        for info, data in entries:
            archive.writestr(info, payload if info.filename == member else data)
PY

# check_rejects <id> <deck> <brief> <composition> <code> [manifest]: check-pptx exits 1 with <code>
# among its findings, one envelope on stdout and nothing on stderr.
check_rejects() {
  local id="$1" deck="$2" brief="$3" comp="$4" code="$5" manifest="${6:-}" rc=0
  if [ -n "$manifest" ]; then
    python3 "$RENDER" check-pptx --brief "$brief" --composition "$comp" --pptx "$deck" --manifest "$manifest" \
      --theme "$THEME" > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  else
    python3 "$RENDER" check-pptx --brief "$brief" --composition "$comp" --pptx "$deck" --theme "$THEME" \
      > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  fi
  [ "$rc" -eq 1 ] && [ ! -s "$WORK/$id.err" ] &&
    python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert e["success"] is False and sys.argv[2] in {f["code"] for f in e["data"]["findings"]}, e["data"]' "$WORK/$id.out" "$code"
}

# Fixture briefs: the direct briefs are normalized here, exactly as a caller would.
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/direct-costs-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/costs-brief.json"
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/render/direct-de-edge-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/de-brief.json"
CBRIEF="$WORK/costs-brief.json"
DBRIEF="$WORK/de-brief.json"

# drpx-01: the skill documents the pptx branch and check-pptx, stays within the description cap, and
# quotes none of the presentation triggers retired with the old deck renderers.
if python3 - "$SKILL" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
front = text.split("---", 2)[1]
name = re.search(r"^name:\s*(.+)$", front, re.M).group(1).strip()
desc = re.search(r"^description:\s*(.+)$", front, re.M).group(1).strip()
assert name == "design-render", name
assert 0 < len(desc) <= 1024, len(desc)
retired = {"create slides from report", "folien aus bericht", "foliensatz", "pitch deck", "powerpoint",
           "praesentation erstellen", "presentation", "presentation outline", "slide deck", "slides",
           "html slides", "html presentation", "browser presentation", "render slides as html",
           "self-contained slides", "slide deck in browser", "web slides", "present in browser",
           "open slides in browser", "export slides as html", "refine slides", "adjust slide", "fix slide",
           "no powerpoint"}
quoted = {" ".join(q.split()).lower() for q in re.findall(r'"([^"]+)"', desc)}
assert not quoted & retired, quoted & retired
for needle in ("--target pptx", "check-pptx", "pptx-manifest-v1.schema.json", "--target html"):
    assert needle in text, needle
PY
then pass "drpx-01-skill-pptx-branch"; else fail "drpx-01-skill-pptx-branch"; fi

# drpx-02: from an empty environment the entry point writes the plan, the deck, its manifest and its
# provenance, names each in one envelope, prints nothing on stderr and writes no HTML.
mkdir -p "$WORK/home"
(cd "$WORK" && env -i PATH="$(dirname "$PYTHON"):/usr/bin:/bin" HOME="$WORK/home" "$PYTHON" "$RENDER" render --target pptx \
   --brief "$CBRIEF" --composition "$COSTS" --theme "$THEME" --out "$WORK/costs" > "$WORK/costs.json" 2> "$WORK/costs.err")
if [ ! -s "$WORK/costs.err" ] && python3 - "$WORK/costs.json" "$WORK/costs" <<'PY'
import json, os, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
assert len(lines) == 1, lines
env = json.loads(lines[0])
assert env["success"] is True and env["error"] is None, env
data = env["data"]
for key in ("target_plan", "artifact", "manifest", "provenance"):
    assert isinstance(data[key], str) and os.path.isfile(data[key]), key
assert data["target"] == "pptx" and data["artifact"].endswith("deck.pptx")
assert sorted(os.listdir(sys.argv[2])) == ["deck.pptx", "pptx-manifest.json", "provenance.json", "target-plan.json"]
PY
then pass "drpx-02-render-outputs"; else fail "drpx-02-render-outputs"; fi

render "$WORK/narr" "$NBRIEF" "$NARR" --generated-at 2026-09-14T08:00:00Z --run-id suite
render "$WORK/de" "$DBRIEF" "$GERMAN" --language de

# drpx-03: the PPTX path never goes through HTML. With the HTML adapter and its checks replaced by
# functions that raise, a pptx render still succeeds; and neither PPTX module imports the HTML adapter.
if python3 - "$PLUGIN_ROOT/scripts" "$CBRIEF" "$COSTS" "$THEME" "$WORK/nohtml" <<'PY'
import ast, importlib.util, io, os, sys, contextlib
scripts, brief, comp, theme, out = sys.argv[1:]
for name in ("pptx_adapter.py", "pptx_checks.py"):
    tree = ast.parse(open(os.path.join(scripts, name), encoding="utf-8").read())
    imported = {a.name for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
    imported |= {n.module for n in ast.walk(tree) if isinstance(n, ast.ImportFrom)}
    assert "html_adapter" not in imported, name
    assert "html_adapter" not in open(os.path.join(scripts, name), encoding="utf-8").read(), name
sys.path.insert(0, scripts)
spec = importlib.util.spec_from_file_location("design_render", os.path.join(scripts, "design-render.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
def refuse(*_args, **_kwargs):
    raise AssertionError("the HTML path was called")
module.html_adapter.render = refuse
module.render_checks.check_html = refuse
buffer = io.StringIO()
with contextlib.redirect_stdout(buffer):
    code = module.main(["render", "--target", "pptx", "--brief", brief, "--composition", comp, "--theme", theme, "--out", out])
assert code == 0, buffer.getvalue()
assert not [f for f in os.listdir(out) if f.endswith((".html", ".htm"))]
PY
then pass "drpx-03-no-html-intermediary"; else fail "drpx-03-no-html-intermediary"; fi

# drpx-04: the deck is laid out as a target-resolved-plan@2 for the pptx target, which check-plan
# grades, on a 16:9 slide of exactly the 1280 x 720 px canvas, one slide per unit plus the cover.
if python3 "$VALIDATOR" check-plan --brief "$NBRIEF" --composition "$NARR" --plan "$WORK/narr/target-plan.json" > /dev/null &&
   python3 - "$WORK" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import json
from deckread import parts, slides, P
import xml.etree.ElementTree as ET
work = sys.argv[1]
plan = json.load(open(f"{work}/narr/target-plan.json"))
assert plan["target"] == "pptx" and plan["artifact_version"] == "2" and plan["canvas"] == {"unit": "px", "width": 1280, "height": 720}
package = parts(f"{work}/narr/deck.pptx")
size = ET.fromstring(package["ppt/presentation.xml"]).find(P + "sldSz")
assert (size.get("cx"), size.get("cy")) == ("12192000", "6858000")
assert [name for _, name, _ in slides(package)] == ["document"] + [u["composition_unit_ref"] for u in plan["units"]]
PY
then pass "drpx-04-plan-pptx"; else fail "drpx-04-plan-pptx"; fi

# drpx-05: every fixture package is whole — content types cover every part, every relationship target is
# in the zip, every relationship id is declared — and a package with one of those broken is rejected by
# this suite's inspection and by check-pptx alike.
ok=1
for out in narr costs de; do
  python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from deckread import parts, integrity; p = integrity(parts(sys.argv[2])); assert not p, p' \
    "$WORK" "$WORK/$out/deck.pptx" || ok=0
done
python3 - "$WORK" <<'PY' || ok=0
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
src = f"{work}/costs/deck.pptx"
doctor(src, f"{work}/dangling.pptx", "ppt/slides/_rels/slide2.xml.rels",
       lambda t: t.replace("../slideLayouts/slideLayout1.xml", "../slideLayouts/slideLayout9.xml", 1))
doctor(src, f"{work}/untyped.pptx", "[Content_Types].xml",
       lambda t: re.sub(r'<Override PartName="/ppt/slides/slide2.xml"[^>]*/>', "", t, count=1))
doctor(src, f"{work}/undeclared.pptx", "ppt/slides/_rels/slide2.xml.rels",
       lambda t: re.sub(r'<Relationship Id="rId[0-9]+" Type="[^"]*/hyperlink"[^>]*/>', "", t, count=1))
PY
for pair in dangling:package-target untyped:package-content-type undeclared:package-relationship; do
  variant="${pair%%:*}" code="${pair#*:}"
  python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from deckread import parts, integrity; assert integrity(parts(sys.argv[2]))' \
    "$WORK" "$WORK/$variant.pptx" || ok=0
  check_rejects "drpx-05-$variant" "$WORK/$variant.pptx" "$CBRIEF" "$COSTS" "$code" || ok=0
done
if [ "$ok" -eq 1 ]; then pass "drpx-05-package-integrity"; else fail "drpx-05-package-integrity"; fi

# drpx-06: frozen copy — every headline, point, note, label, value, source entry and register line of
# all three fixtures, the German one included, is native text in the frame its key names, equal to the
# brief exactly; nothing is omitted, invented or placed outside a shape's text frame.
if python3 - "$WORK" "$NBRIEF" "$NARR" "$CBRIEF" "$COSTS" "$DBRIEF" "$GERMAN" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from deckread import copy_problems
work = sys.argv[1]
for out, brief, comp in (("narr", sys.argv[2], sys.argv[3]), ("costs", sys.argv[4], sys.argv[5]),
                         ("de", sys.argv[6], sys.argv[7])):
    problems = copy_problems(f"{work}/{out}/deck.pptx", brief, comp)
    assert not problems, (out, problems[:3])
PY
then pass "drpx-06-frozen-copy"; else fail "drpx-06-frozen-copy"; fi

# drpx-07: the same reader and check-pptx both reject a changed string, an omitted text frame, and a
# text frame replaced by a picture that keeps the frame's shape id and name.
python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
src = f"{work}/narr/deck.pptx"
frame = r'<p:sp><p:nvSpPr><p:cNvPr id="([0-9]+)" name="copy:slide-2#evidence_status"/>.*?</p:sp>'
doctor(src, f"{work}/changed.pptx", "ppt/slides/slide3.xml",
       lambda t: t.replace("Reliability is an information problem", "Reliability is an Information Problem", 1))
doctor(src, f"{work}/omitted.pptx", "ppt/slides/slide3.xml",
       lambda t: re.sub(frame, "", t, count=1, flags=re.S))
doctor(src, f"{work}/pictured-frame.pptx", "ppt/slides/slide3.xml",
       lambda t: re.sub(frame, r'<p:pic><p:nvPicPr><p:cNvPr id="\1" name="copy:slide-2#evidence_status"/><p:cNvPicPr/>'
                        r'<p:nvPr/></p:nvPicPr><p:blipFill/><p:spPr/></p:pic>', t, count=1, flags=re.S))
PY
ok=1
for pair in changed:copy-changed omitted:copy-omitted pictured-frame:unreported-flattening; do
  variant="${pair%%:*}" code="${pair#*:}"
  python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from deckread import copy_problems; assert copy_problems(sys.argv[2], sys.argv[3], sys.argv[4])' \
    "$WORK" "$WORK/$variant.pptx" "$NBRIEF" "$NARR" || ok=0
  check_rejects "drpx-07-$variant" "$WORK/$variant.pptx" "$NBRIEF" "$NARR" "$code" || ok=0
done
if [ "$ok" -eq 1 ]; then pass "drpx-07-frozen-copy-negative"; else fail "drpx-07-frozen-copy-negative"; fi

# drpx-08: markup, entities, quotes and dashes in copy are text, not markup: the German deck shows the
# brief's literal <script> tag, its literal &amp;, its quotes and its euro signs, escaped once in XML.
if python3 - "$WORK" "$DBRIEF" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, paras, name_of, load
work, brief_path = sys.argv[1:]
brief = load(brief_path)
package = parts(f"{work}/de/deck.pptx")
shown = [p for _, _, tree in slides(package) for s in shapes(tree) for p in paras(s)]
records = {r["id"]: r for r in brief["records"]}
for record_id, field in (("heute", "title"), ("morgen", "title"), ("morgen", "body"), ("antwort", "title")):
    assert records[record_id][field] in shown, (record_id, field)
assert any("<script>alert(1)</script>" in p for p in shown)
assert any("&amp;" in p for p in shown)
raw = package["ppt/slides/slide3.xml"].decode("utf-8")
assert "&lt;script&gt;" in raw and "&amp;amp;" in raw and "<script>" not in raw
PY
then pass "drpx-08-markup-as-text"; else fail "drpx-08-markup-as-text"; fi

# drpx-09: the sourced chart is a native chart — a graphic frame whose chart part is a bar chart backed
# by an embedded workbook — whose categories, numeric cache and series name are the brief's labels,
# literal numbers in order and unit, and whose workbook carries the same unit in B1 and literals in B.
# No slide carries a picture.
if python3 - "$WORK" "$CBRIEF" "$DBRIEF" <<'PY'
import io, sys, zipfile
sys.path.insert(0, sys.argv[1])
import xml.etree.ElementTree as ET
from deckread import parts, slides, shapes, rels, resolve, load, A, P, R, C, S
work = sys.argv[1]
for out, brief_path in (("costs", sys.argv[2]), ("de", sys.argv[3])):
    brief = load(brief_path)
    package = parts(f"{work}/{out}/deck.pptx")
    found = slides(package)
    assert not [s for _, _, tree in found for s in shapes(tree) if s.tag == P + "pic"], out
    frames = [(part, s) for part, _, tree in found for s in shapes(tree)
              if s.tag == P + "graphicFrame" and s.find(f".//{A}graphicData").get("uri").endswith("/chart")]
    assert len(frames) == 1, (out, len(frames))
    part, frame = frames[0]
    kind, target, _ = rels(package, part)[frame.find(f".//{C}chart").get(R + "id")]
    assert kind.endswith("/chart"), kind
    chart_part = resolve(part, target)
    assert chart_part.startswith("ppt/charts/")
    chart = ET.fromstring(package[chart_part])
    series = chart.findall(f".//{C}barChart/{C}ser")
    assert len(series) == 1
    items = brief["data"]
    assert [v.text for v in series[0].findall(f"{C}cat//{C}pt/{C}v")] == [i["label"] for i in items]
    assert [v.text for v in series[0].findall(f"{C}val//{C}numCache/{C}pt/{C}v")] == [i["value"] for i in items]
    assert [v.text for v in series[0].findall(f"{C}tx//{C}v")] == [items[0]["unit"]]
    book_kind, book_target, _ = rels(package, chart_part)[chart.find(f"{C}externalData").get(R + "id")]
    book_part = resolve(chart_part, book_target)
    assert book_kind.endswith("/package") and book_part.startswith("ppt/embeddings/") and book_part.endswith(".xlsx")
    with zipfile.ZipFile(io.BytesIO(package[book_part])) as book:
        sheet = ET.fromstring(book.read("xl/worksheets/sheet1.xml"))
    cells = {c.get("r"): ("".join(t.text or "" for t in c.iter(S + "t")) if c.get("t") == "inlineStr" else c.find(S + "v").text)
             for c in sheet.iter(S + "c")}
    assert cells["B1"] == items[0]["unit"]
    assert [cells[f"A{n}"] for n in range(2, len(items) + 2)] == [i["label"] for i in items]
    assert [cells[f"B{n}"] for n in range(2, len(items) + 2)] == [i["value"] for i in items]
PY
then pass "drpx-09-native-chart"; else fail "drpx-09-native-chart"; fi

# drpx-10: check-pptx rejects a chart flattened into a picture, a changed numeric cache and a changed
# workbook value, each naming the chart check.
python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor, rewrite_workbook
work = sys.argv[1]
src = f"{work}/costs/deck.pptx"
picture = ('<p:pic><p:nvPicPr><p:cNvPr id="{id}" name="chart:u-components"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr>'
           '<p:blipFill/><p:spPr/></p:pic>')
doctor(src, f"{work}/flattened.pptx", "ppt/slides/slide3.xml",
       lambda t: re.sub(r'<p:graphicFrame>.*?</p:graphicFrame>',
                        lambda m: picture.format(id=re.search(r'cNvPr id="([0-9]+)"', m.group(0)).group(1)), t, count=1, flags=re.S))
doctor(src, f"{work}/recached.pptx", "ppt/charts/chart1.xml", lambda t: t.replace("<c:v>13.0</c:v>", "<c:v>13</c:v>", 1))
rewrite_workbook(src, f"{work}/rebooked.pptx", "ppt/embeddings/Microsoft_Excel_Worksheet1.xlsx",
                 lambda t: t.replace("<v>2.1</v>", "<v>2.2</v>", 1))
PY
ok=1
check_rejects "drpx-10-flattened" "$WORK/flattened.pptx" "$CBRIEF" "$COSTS" chart-native || ok=0
check_rejects "drpx-10-recached" "$WORK/recached.pptx" "$CBRIEF" "$COSTS" chart-values || ok=0
check_rejects "drpx-10-rebooked" "$WORK/rebooked.pptx" "$CBRIEF" "$COSTS" chart-values || ok=0
if [ "$ok" -eq 1 ]; then pass "drpx-10-native-chart-negative"; else fail "drpx-10-native-chart-negative"; fi

# drpx-11: a conceptual system is editable shapes — one node shape per entity carrying its label, and
# one connector per relationship glued by id to exactly the two nodes it joins — and dropping a
# connector is rejected.
if python3 - "$WORK" "$NARR" "$GERMAN" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, name_of, paras, load, P, A
work = sys.argv[1]
for out, comp_path in (("narr", sys.argv[2]), ("de", sys.argv[3])):
    comp = load(comp_path)
    found = {name: tree for _, name, tree in slides(parts(f"{work}/{out}/deck.pptx"))}
    for unit in (u for u in comp["units"] if u["pattern"] == "conceptual-system"):
        tree = found[unit["id"]]
        ids = {}
        for entity in unit["entities"]:
            key = f"copy:{entity['record_ref']}#{entity['field']}" + (f"#{entity['item']}" if "item" in entity else "")
            nodes = [s for s in shapes(tree) if s.tag == P + "sp" and name_of(s) == key]
            assert len(nodes) == 1 and nodes[0].find(f"{P}nvSpPr/{P}cNvSpPr").get("txBox") != "1", key
            assert nodes[0].find(f".//{A}prstGeom") is not None
            ids[entity["id"]] = nodes[0].find(f".//{P}cNvPr").get("id")
        connectors = [(s.find(f".//{A}stCxn").get("id"), s.find(f".//{A}endCxn").get("id"))
                      for s in shapes(tree) if s.tag == P + "cxnSp"]
        assert connectors == [(ids[r["from"]], ids[r["to"]]) for r in unit["relationships"]], (unit["id"], connectors)
        labels = [paras(s) for s in shapes(tree) if name_of(s).startswith("kind:")]
        assert labels == [[r["kind"]] for r in unit["relationships"]], labels
PY
then
  python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
doctor(f"{work}/narr/deck.pptx", f"{work}/unglued.pptx", "ppt/slides/slide4.xml",
       lambda t: re.sub(r"<p:cxnSp>.*?</p:cxnSp>", "", t, count=1, flags=re.S))
PY
  if check_rejects "drpx-11-unglued" "$WORK/unglued.pptx" "$NBRIEF" "$NARR" system-semantics
  then pass "drpx-11-editable-shapes"; else fail "drpx-11-editable-shapes"; fi
else fail "drpx-11-editable-shapes"; fi

# drpx-12: speaker notes and evidence survive exactly — each narrative talk track and each direct
# note is its slide's notes-slide text, the trailer notes close the last slide's notes, and each
# evidence status is text on its slide — and a rewritten note is rejected naming the notes check.
if python3 - "$WORK" "$NBRIEF" "$NARR" "$CBRIEF" "$COSTS" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, notes, shapes, name_of, paras, load
work = sys.argv[1]
nbrief, narr, cbrief, costs = (load(p) for p in sys.argv[2:])
records = {r["id"]: r for r in nbrief["records"]}
def field(rid, key):
    return next(f["value"] for f in records[rid]["fields"] if f["key"] == key)
package = parts(f"{work}/narr/deck.pptx")
found = slides(package)
by_name = {name: (part, tree) for part, name, tree in found}
for number in range(1, 9):
    part, tree = by_name[f"u-slide-{number}"]
    want = [field(f"slide-{number}", "talk_track")]
    if number == 8:
        want += nbrief["freeze"]["trailer_notes"]
    assert notes(package, part) == want, number
    statuses = [paras(s) for s in shapes(tree) if name_of(s) == f"copy:slide-{number}#evidence_status"]
    has = any(f["key"] == "evidence_status" for f in records[f"slide-{number}"]["fields"])
    assert statuses == ([[field(f"slide-{number}", "evidence_status")]] if has else []), number
assert sum(1 for n in range(2, 7) if any(f["key"] == "evidence_status" for f in records[f"slide-{n}"]["fields"])) == 5
cpackage = parts(f"{work}/costs/deck.pptx")
answer = next(r for r in cbrief["records"] if r["id"] == "answer")
assert notes(cpackage, next(p for p, n, _ in slides(cpackage) if n == "u-answer")) == [answer["notes"]]
PY
then
  python3 - "$WORK" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
doctor(f"{work}/narr/deck.pptx", f"{work}/renoted.pptx", "ppt/notesSlides/notesSlide1.xml",
       lambda t: t.replace("<a:t>", "<a:t> ", 1))
PY
  if check_rejects "drpx-12-renoted" "$WORK/renoted.pptx" "$NBRIEF" "$NARR" copy-changed &&
     python3 -c 'import json, sys; assert "notes" in {f["check"] for f in json.load(open(sys.argv[1]))["data"]["findings"]}' "$WORK/drpx-12-renoted.out"
  then pass "drpx-12-notes-evidence"; else fail "drpx-12-notes-evidence"; fi
else fail "drpx-12-notes-evidence"; fi

# drpx-13: every [N] marker in copy and notes is a hyperlink run on the marker whose relationship is
# External with the source URL byte for byte; every source a direct unit names without a marker is
# linked from its [n] frame; the register links every URL and is the last slide. A substituted target,
# a lost link and a reordered deck are each rejected.
if python3 - "$WORK" "$NBRIEF" "$CBRIEF" "$COSTS" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, name_of, links, rels, load
work = sys.argv[1]
nbrief, cbrief, costs = (load(p) for p in sys.argv[2:])
markers = {s["marker"]: s["url"] for s in nbrief["sources"]}
package = parts(f"{work}/narr/deck.pptx")
found = slides(package)
assert found[-1][1] == "u-slide-8"
seen = 0
for part, name, tree in found:
    declared = rels(package, part)
    for shape in shapes(tree):
        for text, kind, target, mode in links(shape, declared):
            assert kind.endswith("/hyperlink") and mode == "External", (name, text)
            if re.fullmatch(r"\[[0-9]+\]", text):
                assert target == markers[text], (name, text, target)
                seen += 1
            else:
                assert name == "u-slide-8" and target in markers.values() and target == text, (name, text)
assert seen >= 10, seen
register = next(s for s in shapes(found[-1][2]) if name_of(s) == "register:u-slide-8")
assert [t for t, *_ in links(register, rels(package, found[-1][0]))] == [s["url"] for s in nbrief["sources"]]
cpackage = parts(f"{work}/costs/deck.pptx")
numbers = {s["id"]: i for i, s in enumerate(cbrief["sources"], 1)}
urls = {s["id"]: s["url"] for s in cbrief["sources"]}
cfound = {name: (part, tree) for part, name, tree in slides(cpackage)}
part, tree = cfound["u-components"]
cites = next(s for s in shapes(tree) if name_of(s) == "cites:u-components")
got = [(t, target) for t, _, target, _ in links(cites, rels(cpackage, part))]
data = {d["id"]: d for d in cbrief["data"]}
want = list(dict.fromkeys(ref for d in costs["units"][1]["data_bindings"] for ref in data[d["data_ref"]]["source_refs"]))
assert got == [(f"[{numbers[r]}]", urls[r]) for r in want], got
PY
then
  python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
src = f"{work}/narr/deck.pptx"
doctor(src, f"{work}/retargeted.pptx", "ppt/slides/_rels/slide3.xml.rels",
       lambda t: t.replace("https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html",
                           "https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html/", 1))
doctor(src, f"{work}/unlinked.pptx", "ppt/slides/slide3.xml",
       lambda t: re.sub(r'<a:hlinkClick r:id="rId[0-9]+"/>', "", t, count=1))
doctor(src, f"{work}/reordered.pptx", "ppt/presentation.xml",
       lambda t: re.sub(r'(<p:sldId id="257" r:id="rId3"/>)(<p:sldId id="258" r:id="rId4"/>)', r"\2\1", t, count=1))
PY
  ok=1
  check_rejects "drpx-13-retargeted" "$WORK/retargeted.pptx" "$NBRIEF" "$NARR" citation-substituted || ok=0
  check_rejects "drpx-13-unlinked" "$WORK/unlinked.pptx" "$NBRIEF" "$NARR" citation-missing || ok=0
  check_rejects "drpx-13-reordered" "$WORK/reordered.pptx" "$NBRIEF" "$NARR" reordered-unit || ok=0
  if [ "$ok" -eq 1 ]; then pass "drpx-13-citations-and-order"; else fail "drpx-13-citations-and-order"; fi
else fail "drpx-13-citations-and-order"; fi

# drpx-14: every emitted manifest satisfies references/pptx-manifest-v1.schema.json and records every
# object of every slide with its true kind and editable: true; no fallback exists and no slide carries a
# picture. Each of the three flattening arms is rejected on its own condition: a picture no entry
# names; an entry that lists the picture but still claims native editability; and a fallback entry
# that names its capability but no reason. An object mislabelled as a non-editable fallback is
# rejected too.
if python3 - "$WORK" "$PLUGIN_ROOT/references/pptx-manifest-v1.schema.json" <<'PY'
import json, sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, name_of, schema_problems, P
work = sys.argv[1]
schema = json.load(open(sys.argv[2]))
kinds = {P + "sp": ("text", "shape"), P + "cxnSp": ("connector",), P + "graphicFrame": ("chart",)}
for out in ("narr", "costs", "de"):
    manifest = json.load(open(f"{work}/{out}/pptx-manifest.json"))
    assert not schema_problems(manifest, schema), (out, schema_problems(manifest, schema)[:3])
    broken = json.loads(json.dumps(manifest))
    broken["slides"][0]["objects"][0]["kind"] = "picture"
    assert schema_problems(broken, schema), out
    assert manifest["fallbacks"] == []
    found = slides(parts(f"{work}/{out}/deck.pptx"))
    assert [s["part"] for s in manifest["slides"]] == [part for part, _, _ in found]
    for entry, (part, name, tree) in zip(manifest["slides"], found):
        objects = shapes(tree)
        assert not [s for s in objects if s.tag == P + "pic"], (out, name)
        assert [o["name"] for o in entry["objects"]] == [name_of(s) for s in objects], (out, name)
        for record, shape in zip(entry["objects"], objects):
            assert record["editable"] is True and record["fallback"] is None and record["kind"] in kinds[shape.tag], record
PY
then
  python3 - "$WORK" <<'PY'
import json, re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
picture = ('<p:pic><p:nvPicPr><p:cNvPr id="99" name="figure"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr><p:blipFill/>'
           '<p:spPr/></p:pic></p:spTree>')
doctor(f"{work}/costs/deck.pptx", f"{work}/pictured.pptx", "ppt/slides/slide2.xml", lambda t: t.replace("</p:spTree>", picture, 1))
manifest = json.load(open(f"{work}/costs/pptx-manifest.json"))
manifest["slides"][1]["objects"][0]["editable"] = False
json.dump(manifest, open(f"{work}/mislabelled.json", "w"))
# The injected picture listed by the manifest: once as a fallback with a capability but no reason,
# once as a natively editable object. Neither is the missing-entry arm.
figure = {"shape_id": 99, "name": "figure", "kind": "image", "capability": "native-chart", "copy_keys": []}
unreasoned = json.load(open(f"{work}/costs/pptx-manifest.json"))
unreasoned["slides"][1]["objects"].append(dict(figure, editable=False, fallback={"capability": "native-chart"}))
json.dump(unreasoned, open(f"{work}/fallback-unreasoned.json", "w"))
false_native = json.load(open(f"{work}/costs/pptx-manifest.json"))
false_native["slides"][1]["objects"].append(dict(figure, editable=True, fallback=None))
json.dump(false_native, open(f"{work}/false-native.json", "w"))
PY
  ok=1
  check_rejects "drpx-14-pictured" "$WORK/pictured.pptx" "$CBRIEF" "$COSTS" unreported-flattening "$WORK/costs/pptx-manifest.json" || ok=0
  check_rejects "drpx-14-fallback-unreasoned" "$WORK/pictured.pptx" "$CBRIEF" "$COSTS" unreported-flattening "$WORK/fallback-unreasoned.json" || ok=0
  check_rejects "drpx-14-false-native" "$WORK/pictured.pptx" "$CBRIEF" "$COSTS" unreported-flattening "$WORK/false-native.json" || ok=0
  # Each arm must be the one that fired: the finding's message names it.
  python3 -c 'import json, sys; m = {f["message"] for f in json.load(open(sys.argv[1]))["data"]["findings"] if f["code"] == "unreported-flattening"}; assert any("no capability or no reason" in x for x in m), m' "$WORK/drpx-14-fallback-unreasoned.out" || ok=0
  python3 -c 'import json, sys; m = {f["message"] for f in json.load(open(sys.argv[1]))["data"]["findings"] if f["code"] == "unreported-flattening"}; assert any("natively editable" in x for x in m), m' "$WORK/drpx-14-false-native.out" || ok=0
  check_rejects "drpx-14-mislabelled" "$WORK/costs/deck.pptx" "$CBRIEF" "$COSTS" manifest-editability "$WORK/mislabelled.json" || ok=0
  if [ "$ok" -eq 1 ]; then pass "drpx-14-manifest-editability"; else fail "drpx-14-manifest-editability"; fi
else fail "drpx-14-manifest-editability"; fi

# drpx-15: the manifest and provenance record the fonts, the design system and its revision, the theme
# tokens, every embedded asset by digest, the writer and the runtime; check-provenance accepts the
# delivered bundle; a manifest with any one of those identities removed — fonts, design_system, theme,
# assets, writer, runtime — and a manifest naming another writer are each rejected.
if python3 - "$WORK" "$COSTS" "$PLUGIN_ROOT/.claude-plugin/plugin.json" <<'PY'
import hashlib, json, platform, sys, zipfile
sys.path.insert(0, sys.argv[1])
work, comp_path, plugin = sys.argv[1:]
comp = json.load(open(comp_path))
manifest = json.load(open(f"{work}/costs/pptx-manifest.json"))
prov = json.load(open(f"{work}/costs/provenance.json"))
version = json.load(open(plugin))["version"]
assert manifest["design_system"] == comp["design_system"] and manifest["design_system"]["version"]
assert manifest["writer"]["name"] == prov["renderer"]["name"] and manifest["writer"]["version"] == version
assert manifest["runtime"]["name"] and manifest["runtime"]["version"].count(".") == 2
assert manifest["theme"]["slug"] == "cogni-work" and manifest["theme"]["tokens_sha256"] == prov["theme"]["tokens_sha256"]
assert manifest["fonts"] and all(f["typeface"] and f["resolved_face"] for f in manifest["fonts"])
with zipfile.ZipFile(f"{work}/costs/deck.pptx") as deck:
    embedded = {n: "sha256:" + hashlib.sha256(deck.read(n)).hexdigest() for n in deck.namelist() if n.startswith("ppt/embeddings/")}
assert {a["part"]: a["sha256"] for a in manifest["assets"]} == embedded and embedded
deck = open(f"{work}/costs/deck.pptx", "rb").read()
assert manifest["package"]["sha256"] == prov["outputs"]["artifact"]["sha256"] == "sha256:" + hashlib.sha256(deck).hexdigest()
assert prov["outputs"]["manifest"]["path"] == "pptx-manifest.json" and prov["renderer"]["target"] == "pptx"
for key in ("fonts", "design_system", "theme", "assets", "writer", "runtime"):
    stripped = dict(manifest)
    del stripped[key]
    json.dump(stripped, open(f"{work}/no-{key}.json", "w"))
foreign = json.loads(json.dumps(manifest))
foreign["writer"]["version"] = "9.9.9"
import os, shutil
shutil.copytree(f"{work}/costs", f"{work}/foreign")
json.dump(foreign, open(f"{work}/foreign/pptx-manifest.json", "w"))
PY
then
  ok=1
  python3 "$RENDER" check-provenance --provenance "$WORK/costs/provenance.json" --composition "$COSTS" \
    --plan "$WORK/costs/target-plan.json" --out-dir "$WORK/costs" > /dev/null || ok=0
  for key in fonts design_system theme assets writer runtime; do
    check_rejects "drpx-15-no-$key" "$WORK/costs/deck.pptx" "$CBRIEF" "$COSTS" manifest-invalid "$WORK/no-$key.json" || ok=0
  done
  rc=0
  python3 "$RENDER" check-provenance --provenance "$WORK/foreign/provenance.json" --out-dir "$WORK/foreign" > "$WORK/foreign.out" || rc=$?
  [ "$rc" -eq 1 ] && python3 -c 'import json, sys; assert "writer-mismatch" in {f["code"] for f in json.load(open(sys.argv[1]))["data"]["findings"]}' "$WORK/foreign.out" || ok=0
  if [ "$ok" -eq 1 ]; then pass "drpx-15-provenance-identities"; else fail "drpx-15-provenance-identities"; fi
else fail "drpx-15-provenance-identities"; fi

# theme_variant <dir> <font-sans stack>: a copy of the fixture theme with one font stack changed.
theme_variant() {
  mkdir -p "$1"
  cp -R "$THEME" "$1/cogni-work"
  python3 - "$1/cogni-work/tokens/typography.json" "$2" <<'PY'
import json, sys
path, stack = sys.argv[1:]
tokens = json.load(open(path))
tokens["font-sans"] = stack
json.dump(tokens, open(path, "w"))
PY
}

# drpx-16: a brand face nothing ships falls back through the documented chain and is written as that
# generic family's documented Office typeface, recorded as a substitution; a monospace fallback is
# written as its own typeface; a stack with no generic member fails naming the font and writes nothing.
theme_variant "$WORK/mono" "'Brand Face', monospace"
theme_variant "$WORK/nofont" "'Brand Face', 'Other Face'"
python3 "$RENDER" render --target pptx --brief "$CBRIEF" --composition "$COSTS" --theme "$WORK/mono/cogni-work" \
  --out "$WORK/mono-out" > "$WORK/mono-out.json"
rc=0
python3 "$RENDER" render --target pptx --brief "$CBRIEF" --composition "$COSTS" --theme "$WORK/nofont/cogni-work" \
  --out "$WORK/nofont-out" > "$WORK/nofont.json" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -e "$WORK/nofont-out" ] &&
   python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert e["data"]["code"] == "font-unresolved" and e["data"]["reference"] == "Brand Face"' "$WORK/nofont.json" &&
   python3 - "$WORK" "$PLUGIN_ROOT/references/font-fallbacks-v1.json" <<'PY'
import json, sys
sys.path.insert(0, sys.argv[1])
import xml.etree.ElementTree as ET
from deckread import parts, A
work, fallbacks = sys.argv[1:]
generic = json.load(open(fallbacks))["generic_families"]
for out, face, requested in (("costs", "system-ui", "DM Sans"), ("mono-out", "monospace", "Brand Face")):
    manifest = json.load(open(f"{work}/{out}/pptx-manifest.json"))
    font = next(f for f in manifest["fonts"] if f["token"] == "typography.font-sans")
    typeface = generic[face]["pptx_typeface"]
    assert font["requested_family"] == requested and font["resolved_face"] == face and font["substituted"] is True, font
    assert font["typeface"] == typeface, font
    package = parts(f"{work}/{out}/deck.pptx")
    assert ET.fromstring(package["ppt/theme/theme1.xml"]).find(f".//{A}minorFont/{A}latin").get("typeface") == typeface
    faces = {node.get("typeface") for name, data in package.items() if name.startswith("ppt/slides/slide")
             for node in ET.fromstring(data).iter(A + "latin")}
    assert faces == {typeface}, faces
PY
then pass "drpx-16-font-fallback"; else fail "drpx-16-font-fallback"; fi

# recompose <prefix> <python-edit> [direct-brief] [composition]: apply one edit to a copy of a direct
# brief (the costs brief unless named), normalize it and recompose its composition (the costs composition
# unless named) from a stripped draft, so every digest matches the edited brief.
recompose() {
  python3 - "${3:-$FIXTURES/direct-costs-v1.json}" "${4:-$COSTS}" "$WORK/$1" "$2" <<'PY' || return 1
import json, sys
brief_path, comp_path, prefix, edit = sys.argv[1:]
brief = json.load(open(brief_path, encoding="utf-8"))
def section(sid):
    return next(s for s in brief["sections"] if s["id"] == sid)
exec(edit)
json.dump(brief, open(prefix + "-direct.json", "w", encoding="utf-8"), ensure_ascii=False)
draft = json.load(open(comp_path, encoding="utf-8"))
draft["normalized_brief_ref"].pop("content_fingerprint", None)
draft.pop("document_bindings", None)
for unit in draft["units"]:
    unit.pop("source_refs", None)
    unit.pop("register_refs", None)
    for binding in unit.get("bindings", []):
        binding.pop("digest", None)
json.dump(draft, open(prefix + "-draft.json", "w", encoding="utf-8"), ensure_ascii=False)
PY
  python3 "$VALIDATOR" normalize --kind direct --input "$WORK/$1-direct.json" > "$WORK/$1-normalized.json" || return 1
  python3 -c 'import json, sys; json.dump(json.load(open(sys.argv[1]))["data"], open(sys.argv[2], "w"), ensure_ascii=False)' \
    "$WORK/$1-normalized.json" "$WORK/$1-brief.json" || return 1
  python3 "$VALIDATOR" compose --brief "$WORK/$1-brief.json" --composition "$WORK/$1-draft.json" > "$WORK/$1-composed.json" || return 1
  python3 -c 'import json, sys; json.dump(json.load(open(sys.argv[1]))["data"], open(sys.argv[2], "w"), ensure_ascii=False)' \
    "$WORK/$1-composed.json" "$WORK/$1-comp.json"
}

# rejects_render <id> <code> <prefix>: a pptx render of a recomposed brief exits 1 with <code>, one
# envelope on stdout, nothing on stderr and no output directory.
rejects_render() {
  local id="$1" code="$2" prefix="$3" rc=0
  python3 "$RENDER" render --target pptx --brief "$WORK/$prefix-brief.json" --composition "$WORK/$prefix-comp.json" \
    --theme "$THEME" --out "$WORK/$id-out" > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  [ "$rc" -eq 1 ] && [ ! -s "$WORK/$id.err" ] && [ ! -e "$WORK/$id-out" ] &&
    python3 -c 'import json, sys; lines = open(sys.argv[1]).read().splitlines(); assert len(lines) == 1; e = json.loads(lines[0]); assert e["success"] is False and e["data"]["code"] == sys.argv[2], e' "$WORK/$id.out" "$code"
}

# drpx-17: content that does not fit a slide fails instead of shrinking, splitting or cutting. A brief
# whose register outgrows the 720 px slide — a layout the HTML target still renders, as its frame may
# grow — fails as fit-overflow and writes nothing; every green deck sets no autofit, no font scale, no
# copy run below the size of the type role its slot resolves to (the slot default raised to the
# pattern's min_type_role, read here from the composition, the pattern library and the theme tokens)
# and no size anywhere below the theme's caption size; and a headline run shrunk to the caption size —
# above that global floor, below its slot's — is rejected as readability.
ok=1
recompose dense 'brief["sources"] += [{"id": f"extra-{i}", "publisher": f"Publisher {i}", "title": f"A long report on maintenance number {i}", "url": f"https://example.org/report-{i}"} for i in range(25)]' || ok=0
python3 "$RENDER" render --target html --brief "$WORK/dense-brief.json" --composition "$WORK/dense-comp.json" --theme "$THEME" \
  --out "$WORK/dense-html" > /dev/null || ok=0
python3 -c 'import json, sys; plan = json.load(open(sys.argv[1])); assert plan["units"][-1]["frame"]["height"] > 720' "$WORK/dense-html/target-plan.json" || ok=0
rejects_render "drpx-17-dense" fit-overflow dense || ok=0
python3 - "$WORK" "$THEME/tokens/typography.json" "$PLUGIN_ROOT/references/pattern-library-v1.json" "$NARR" "$COSTS" "$GERMAN" <<'PY' || ok=0
import json, sys
sys.path.insert(0, sys.argv[1])
import xml.etree.ElementTree as ET
from deckread import parts, slides, shapes, name_of, A
work, typography, library_path = sys.argv[1:4]
tokens = json.load(open(typography))
library = json.load(open(library_path))
scale = library["type_scale"]
patterns = {p["id"]: p for p in library["patterns"]}
role_tokens = {"type.display": "size-display", "type.heading": "size-h2", "type.lead": "size-h3",
               "type.body": "size-body", "type.caption": "size-small"}
defaults = {"answer": "type.display", "claim": "type.heading", "heading": "type.heading", "support": "type.lead",
            "evidence": "type.caption"}
minimum = round(float(tokens["size-small"].rstrip("px")) * 75)
sizes_of = lambda node: [int(n.get("sz")) for n in node.iter() if n.tag in (A + "rPr", A + "endParaRPr", A + "defRPr") and n.get("sz")]

def floor(role):
    return round(float(tokens[role_tokens[role]].rstrip("px")) * 75)

def slot_role(slot, unit):
    role = defaults.get(slot, "type.body")
    if slot == "notes":
        return role
    minimum_role = unit.get("type_floor", patterns[unit["pattern"]]["constraints"]["min_type_role"])
    return minimum_role if scale.index(role) < scale.index(minimum_role) else role

for out, comp_path in zip(("narr", "costs", "de"), sys.argv[4:7]):
    comp = json.load(open(comp_path))
    expected = {"document": {"copy:document#title": floor("type.display"), "copy:document#subtitle": floor("type.lead")}}
    for unit in comp["units"]:
        floors = {f"copy:{b['record_ref']}#{b['field']}": floor(slot_role(b["slot"], unit)) for b in unit.get("bindings", [])}
        floors[f"register:{unit['id']}"] = floor(slot_role("evidence", unit))
        expected[unit["id"]] = floors
    checked = 0
    for part, name, tree in slides(parts(f"{work}/{out}/deck.pptx")):
        for shape in shapes(tree):
            shape_name = name_of(shape)
            stem = shape_name.rsplit("#", 1)[0] if shape_name.rsplit("#", 1)[-1].isdigit() else shape_name
            wanted = expected.get(name, {}).get(shape_name, expected.get(name, {}).get(stem))
            if wanted is None:
                continue
            found = sizes_of(shape)
            assert found and min(found) >= wanted, (out, name, shape_name, found, wanted)
            checked += 1
    assert checked >= len(comp["units"]), (out, checked)
    for name, data in parts(f"{work}/{out}/deck.pptx").items():
        if not name.endswith(".xml") or not name.startswith("ppt/"):
            continue
        tree = ET.fromstring(data)
        assert not list(tree.iter(A + "normAutofit")), name
        assert not [n for n in tree.iter() if "fontScale" in n.attrib], name
        sizes = sizes_of(tree)
        assert all(size >= minimum for size in sizes), (name, min(sizes), minimum)
PY
# A headline set at the caption size clears the global floor and fails its slot's: the claim slot of
# u-slide-2 resolves to type.heading, whose size the theme sets above the caption.
python3 - "$WORK" "$THEME/tokens/typography.json" <<'PY' || ok=0
import re, sys, json
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work, typography = sys.argv[1:]
tokens = json.load(open(typography))
heading, caption = (round(float(tokens[k].rstrip("px")) * 75) for k in ("size-h2", "size-small"))
assert heading > caption
def shrink(text):
    match = re.search(r'<p:sp><p:nvSpPr><p:cNvPr id="[0-9]+" name="copy:slide-2#headline"/>.*?</p:sp>', text, flags=re.S)
    assert match and f'sz="{heading}"' in match.group(0), match
    return text[:match.start()] + match.group(0).replace(f'sz="{heading}"', f'sz="{caption}"') + text[match.end():]
doctor(f"{work}/narr/deck.pptx", f"{work}/shrunk.pptx", "ppt/slides/slide3.xml", shrink)
PY
check_rejects "drpx-17-shrunk" "$WORK/shrunk.pptx" "$NBRIEF" "$NARR" readability || ok=0
if [ "$ok" -eq 1 ]; then pass "drpx-17-fit-overflow"; else fail "drpx-17-fit-overflow"; fi

# drpx-18: copy a package cannot carry as text — a vertical tab — fails as unsupported-content naming
# its key, instead of being dropped, and writes nothing.
if recompose control 'section("answer")["body"] += "\x0b"' &&
   rejects_render "drpx-18-control" unsupported-content control &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["reference"] == "answer#body"' "$WORK/drpx-18-control.out"
then pass "drpx-18-unsupported-content"; else fail "drpx-18-unsupported-content"; fi

# drpx-19: a chain the validator rejects is rejected by the pptx render with the validator's finding:
# exit 1, one envelope, an empty stderr and no deck.
python3 - "$NARR" "$WORK/comp-dangling.json" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1]))
comp["units"][1]["bindings"][0]["record_ref"] = "slide-99"
json.dump(comp, open(sys.argv[2], "w"))
PY
rc=0
python3 "$RENDER" render --target pptx --brief "$NBRIEF" --composition "$WORK/comp-dangling.json" --theme "$THEME" \
  --out "$WORK/dangling-out" > "$WORK/dangling.out" 2> "$WORK/dangling.err" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -s "$WORK/dangling.err" ] && [ ! -e "$WORK/dangling-out" ] &&
   python3 -c 'import json, sys; lines = open(sys.argv[1]).read().splitlines(); assert len(lines) == 1 and json.loads(lines[0])["data"]["code"] == "dangling-reference"' "$WORK/dangling.out"
then pass "drpx-19-invalid-chain"; else fail "drpx-19-invalid-chain"; fi

# drpx-20: the pptx render is a closed boundary. --measure with the pptx target is a usage error that
# writes nothing; and a render run under an audit hook, with PATH scrubbed to decoy installers and HOME
# pointing at a decoy workspace, spawns no process, opens no socket and reads nothing under HOME or any
# cogni-workspace path.
mkdir -p "$WORK/decoy" "$WORK/decoy-home/cogni-workspace/themes"
for tool in npm npx node pip pip3 curl soffice; do
  printf '#!/bin/sh\ntouch "%s/installed-$0"\n' "$WORK" > "$WORK/decoy/$tool"
  chmod +x "$WORK/decoy/$tool"
done
rc=0
python3 "$RENDER" render --target pptx --measure --brief "$CBRIEF" --composition "$COSTS" --theme "$THEME" \
  --out "$WORK/measure-out" > "$WORK/measure.out" 2> "$WORK/measure.err" || rc=$?
cat > "$WORK/audited.py" <<'PY'
import os, runpy, sys
home = os.path.realpath(os.environ["HOME"])
events = []
def hook(event, args):
    if event in ("subprocess.Popen", "os.system", "os.exec", "os.posix_spawn", "socket.connect", "socket.getaddrinfo"):
        events.append((event, str(args)[:120]))
    elif event == "open" and isinstance(args[0], (str, bytes)):
        path = os.path.realpath(os.fsdecode(args[0]))
        if path.startswith(home) or "cogni-workspace" in path.split(os.sep):
            events.append((event, path))
sys.addaudithook(hook)
script = sys.argv[1]
sys.argv = sys.argv[1:]
try:
    runpy.run_path(script, run_name="__main__")
except SystemExit as exc:
    code = exc.code
else:
    code = 0
open(os.environ["AUDIT_OUT"], "w").write(repr((code, events)))
PY
(cd "$WORK" && env -i PATH="$WORK/decoy" HOME="$WORK/decoy-home" AUDIT_OUT="$WORK/audit.txt" COGNI_WORKSPACE_ROOT="$WORK/decoy-home/cogni-workspace" \
   "$PYTHON" "$WORK/audited.py" "$RENDER" render --target pptx --brief "$CBRIEF" --composition "$COSTS" --theme "$THEME" \
   --out "$WORK/audited-out" > "$WORK/audited.json" 2> "$WORK/audited.err")
if [ "$rc" -eq 2 ] && [ ! -s "$WORK/measure.err" ] && [ ! -e "$WORK/measure-out" ] &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "usage-error"' "$WORK/measure.out" &&
   [ ! -s "$WORK/audited.err" ] && ! ls "$WORK"/installed-* >/dev/null 2>&1 &&
   python3 -c 'import ast, sys; code, events = ast.literal_eval(open(sys.argv[1]).read()); assert code == 0 and events == [], events' "$WORK/audit.txt" &&
   [ -f "$WORK/audited-out/deck.pptx" ]
then pass "drpx-20-usage-and-isolation"; else fail "drpx-20-usage-and-isolation"; fi

# drpx-21: a deck is byte-deterministic — two renders of the same inputs at different times and run ids
# give the same bytes, the digest the manifest and provenance both record.
render "$WORK/narr-again" "$NBRIEF" "$NARR" --generated-at 2030-01-01T00:00:00Z --run-id another
if python3 - "$WORK" <<'PY'
import hashlib, json, sys
work = sys.argv[1]
first, second = (open(f"{work}/{d}/deck.pptx", "rb").read() for d in ("narr", "narr-again"))
assert first == second
digest = "sha256:" + hashlib.sha256(first).hexdigest()
for d in ("narr", "narr-again"):
    assert json.load(open(f"{work}/{d}/pptx-manifest.json"))["package"]["sha256"] == digest
    assert json.load(open(f"{work}/{d}/provenance.json"))["outputs"]["artifact"]["sha256"] == digest
assert json.load(open(f"{work}/narr/provenance.json"))["run_id"] != json.load(open(f"{work}/narr-again/provenance.json"))["run_id"]
PY
then pass "drpx-21-deterministic"; else fail "drpx-21-deterministic"; fi

# drpx-22: every part carries the children the OOXML schema requires of the elements it writes — the
# class a lenient reader opens and PowerPoint offers to repair. This suite's own reader checks the view
# settings, the presentation and every text body of the three fixture decks; a deck whose normal view is
# written empty, the defect PowerPoint once flagged, is rejected here and by check-pptx as package-schema.
cat > "$WORK/required.py" <<'PY'
import sys
import xml.etree.ElementTree as ET
sys.path.insert(0, sys.argv[1])
from deckread import parts, A, P

RULES = {P + "normalViewPr": {P + "restoredLeft", P + "restoredTop"}, P + "cViewPr": {P + "scale", P + "origin"},
         P + "presentation": {P + "sldMasterIdLst", P + "notesSz"}, P + "txBody": {A + "bodyPr"}}


def missing(deck):
    out = []
    for name, data in parts(deck).items():
        if name.endswith(".xml") and name.startswith("ppt/"):
            for node in ET.fromstring(data).iter():
                want = RULES.get(node.tag, set())
                out += [(name, node.tag, tag) for tag in want - {child.tag for child in node}]
    return out
PY
if python3 - "$WORK" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from required import missing
work = sys.argv[1]
for out in ("narr", "costs", "de"):
    assert not missing(f"{work}/{out}/deck.pptx"), (out, missing(f"{work}/{out}/deck.pptx")[:3])
PY
then
  python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
doctor(f"{work}/costs/deck.pptx", f"{work}/viewless.pptx", "ppt/viewProps.xml",
       lambda t: re.sub(r"<p:normalViewPr>.*?</p:normalViewPr>", "<p:normalViewPr/>", t, count=1, flags=re.S))
PY
  if python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from required import missing; assert missing(sys.argv[2])' "$WORK" "$WORK/viewless.pptx" &&
     check_rejects "drpx-22-viewless" "$WORK/viewless.pptx" "$CBRIEF" "$COSTS" package-schema
  then pass "drpx-22-required-elements"; else fail "drpx-22-required-elements"; fi
else fail "drpx-22-required-elements"; fi

# drpx-23: every colour a deck carries is a theme token. In the three fixture decks the only literal
# colours (a:srgbClr) sit in a theme part's colour scheme, each equal to one of the fixture theme's
# `colors` tokens, and each scheme carries all six required roles; every other part reaches colour only
# through a:schemeClr, and no part uses a system, preset, HSL or scRGB colour. A slide given a literal
# colour and a theme scheme given an off-token colour are each rejected by this reader. check-pptx does
# not grade colour, so this case is the guard.
cat > "$WORK/colours.py" <<'PY'
import json
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, sys.argv[1])
from deckread import parts, A

ROLES = ("text", "bg", "surface", "accent", "text-muted", "border")
OTHER = {A + "sysClr", A + "prstClr", A + "hslClr", A + "scrgbClr"}


def token_hex(value):
    text = str(value).strip().lstrip("#").upper()
    return "".join(ch * 2 for ch in text) if len(text) == 3 else text


def off_theme(deck, colors_path):
    colors = json.load(open(colors_path, encoding="utf-8"))
    tokens = {token_hex(v) for v in colors.values()}
    roles = {token_hex(colors[k]) for k in ROLES}
    problems, themes = [], 0
    for name, data in sorted(parts(deck).items()):
        if not (name.startswith("ppt/") and name.endswith(".xml")):
            continue
        tree = ET.fromstring(data)
        is_theme = name.startswith("ppt/theme/")
        scheme, seen = set(), set()
        if is_theme:
            themes += 1
            for block in tree.iter(A + "clrScheme"):
                scheme.update(id(node) for node in block.iter(A + "srgbClr"))
        for node in tree.iter():
            if node.tag == A + "srgbClr":
                value = (node.get("val") or "").upper()
                seen.add(value)
                if id(node) not in scheme or value not in tokens:
                    problems.append((name, "literal", value))
            elif node.tag in OTHER:
                problems.append((name, "colour-kind", node.tag))
        if is_theme and not roles <= seen:
            problems.append((name, "roles", sorted(roles - seen)))
    if not themes:
        problems.append(("ppt/theme/", "missing"))
    return problems
PY
if python3 - "$WORK" "$THEME/tokens/colors.json" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from colours import off_theme
work = sys.argv[1]
for out in ("narr", "costs", "de"):
    assert not off_theme(f"{work}/{out}/deck.pptx", sys.argv[2]), (out, off_theme(f"{work}/{out}/deck.pptx", sys.argv[2])[:3])
PY
then
  python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
doctor(f"{work}/costs/deck.pptx", f"{work}/literal.pptx", "ppt/slides/slide2.xml",
       lambda t: re.sub(r'<a:schemeClr val="[^"]+"/>', '<a:srgbClr val="FF0000"/>', t, count=1))
doctor(f"{work}/costs/deck.pptx", f"{work}/offbrand.pptx", "ppt/theme/theme1.xml",
       lambda t: re.sub(r'<a:srgbClr val="[0-9A-F]{6}"/>', '<a:srgbClr val="FF0000"/>', t, count=1))
PY
  if python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from colours import off_theme; assert off_theme(sys.argv[2], sys.argv[4]) and off_theme(sys.argv[3], sys.argv[4])' \
       "$WORK" "$WORK/literal.pptx" "$WORK/offbrand.pptx" "$THEME/tokens/colors.json"
  then pass "drpx-23-theme-colours"; else fail "drpx-23-theme-colours"; fi
else fail "drpx-23-theme-colours"; fi

# drpx-24: the pptx render renders only a target its composition requests. A scratch copy of the costs
# composition with pptx removed from its targets still renders as html, and a pptx render of it fails
# before layout as unsupported-capability under check `target` on the composition, naming pptx: exit 1,
# one envelope, nothing on stderr and no output directory. Asserting the check and artifact pins the
# wrapper's own gate rather than the plan validator's later refusal, whose artifact is the plan.
python3 - "$COSTS" "$WORK/html-only.json" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1], encoding="utf-8"))
comp["targets"] = [t for t in comp["targets"] if t != "pptx"]
json.dump(comp, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
rc=0
python3 "$RENDER" render --target pptx --brief "$CBRIEF" --composition "$WORK/html-only.json" --theme "$THEME" \
  --out "$WORK/html-only-out" > "$WORK/html-only.out" 2> "$WORK/html-only.err" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -s "$WORK/html-only.err" ] && [ ! -e "$WORK/html-only-out" ] &&
   python3 -c '
import json, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
assert len(lines) == 1, lines
env = json.loads(lines[0])
data = env["data"]
assert env["success"] is False, env
assert (data["code"], data["check"], data["artifact"], data["reference"]) == \
    ("unsupported-capability", "target", "semantic_composition", "pptx"), data' "$WORK/html-only.out" &&
   python3 "$RENDER" render --target html --brief "$CBRIEF" --composition "$WORK/html-only.json" --theme "$THEME" \
     --out "$WORK/html-only-page" > /dev/null 2>&1
then pass "drpx-24-target-not-requested"; else fail "drpx-24-target-not-requested"; fi

# drpx-25: a deck embeds no font, so a face a theme ships for its pages is never a face a deck is set in.
# Rendered with the font-shipping fixture theme, the deck skips the shipped family and falls through to
# its generic family: the manifest records the substitution and the Office typeface, the theme's font
# scheme names that typeface, and no part of the package is a font.
rc=0
python3 "$RENDER" render --target pptx --brief "$CBRIEF" --composition "$COSTS" \
  --theme "$FIXTURES/render/font-theme/cogni-work" --out "$WORK/shipped-deck" > "$WORK/shipped-deck.json" \
  2> "$WORK/shipped-deck.err" || rc=$?
if [ "$rc" -eq 0 ] && [ ! -s "$WORK/shipped-deck.err" ] &&
   python3 - "$WORK/shipped-deck" <<'PY'
import json, re, sys, zipfile
out = sys.argv[1]
manifest = json.load(open(f"{out}/pptx-manifest.json", encoding="utf-8"))
font = next(f for f in manifest["fonts"] if f["token"] == "typography.font-sans")
assert font["requested_family"] == "Outfit" and font["resolved_face"] == "system-ui", font
assert font["substituted"] is True and font["skipped"] == ["Outfit"] and font["typeface"] == "Arial", font
assert font["source"] == "generic" and "file_sha256" not in font, font
with zipfile.ZipFile(f"{out}/deck.pptx") as deck:
    names = deck.namelist()
    theme = deck.read("ppt/theme/theme1.xml").decode("utf-8")
fonts = [n for n in names if n.startswith("ppt/fonts/") or re.search(r"\.(ttf|otf|woff2?|fntdata|odttf)$", n, re.I)]
assert not fonts, fonts
assert '<a:minorFont><a:latin typeface="Arial"/>' in theme, theme[:400]
PY
then pass "drpx-25-shipped-face-not-embedded"; else fail "drpx-25-shipped-face-not-embedded"; fi

# drpx-26: figure labels that need more than one line are drawn on the geometry the plan measured. The
# German brief is recomposed with one long chart label and one long entity label, and with the system
# unit's type_floor raised to type.lead, since an entity label within its 90-character slot limit never
# fills a node line at body size. The deck still fits its slides, and its written target-resolved-plan@2
# counts more lines than points and entities, which is the precondition. Read from the deck with this
# suite's own reader, within 0.5 px: the chart's label and value frames sit on cumulative rows that all
# take the tallest label's max(lines x line height, 28 px) + spacing-3 and end at the series box bottom,
# so the one-line labels' rows are as tall as the long label's, each label frame at the
# box's x with a text width of the label column (40 % of the box, less 8 px) and wrapping inside it, and
# the chart frame starts at the column's right edge; the system's nodes stack from the entities box top
# to its bottom, each lines x line height + 2 x spacing-4 tall, with a text width of the box less the
# 260 px connector gutter and the padding. A long label is still one paragraph equal to the brief. A
# writer with a one-line label assumption rejected this brief as fit-overflow; one that sized a node by
# character count drew the long node, whose long word breaks it onto three lines, one line short.
python3 - "$GERMAN" "$WORK/long-src.json" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1], encoding="utf-8"))
next(unit for unit in comp["units"] if unit["id"] == "u-bausteine")["type_floor"] = "type.lead"
json.dump(comp, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
recompose long 'section("komponenten")["data"][1]["label"] = "Lohnaufschlag für Fachkräfte, die im Schichtbetrieb kurzfristig einspringen müssen"; section("bausteine")["body"] = "Ein Blick auf die Instandhaltungsplanungsdatenbankschnittstellenverwaltung Ersatzteillager"' \
  "$FIXTURES/render/direct-de-edge-v1.json" "$WORK/long-src.json" && render "$WORK/long" "$WORK/long-brief.json" "$WORK/long-comp.json" --language de
rc=$?
if [ "$rc" -eq 0 ] && [ ! -s "$WORK/long.err" ] &&
   python3 - "$WORK" "$THEME/tokens/typography.json" "$THEME/tokens/spacing.json" <<'PY'
import json, sys
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, name_of, paras, A, P
work, typography, spacing = sys.argv[1:]
tokens = json.load(open(typography))
space = {k: float(v.rstrip("px")) for k, v in json.load(open(spacing)).items()}
role_tokens = {"type.display": ("size-display", "line-height-display"), "type.heading": ("size-h2", "line-height-h2"),
               "type.lead": ("size-h3", "line-height-h3"), "type.body": ("size-body", "line-height-body"),
               "type.caption": ("size-small", "line-height-small")}
item_gap, node_pad, gap = space["3"], space["4"], space["5"]
brief = json.load(open(f"{work}/long-brief.json", encoding="utf-8"))
comp = json.load(open(f"{work}/long-comp.json", encoding="utf-8"))
plan = json.load(open(f"{work}/long/target-plan.json", encoding="utf-8"))
labels = {d["id"]: d["label"] for d in brief["data"]}
records = {r["id"]: r for r in brief["records"]}
units = {u["id"]: u for u in comp["units"]}
plan_units = {u["composition_unit_ref"]: u for u in plan["units"]}
assert all(u["frame"]["height"] <= 720.5 for u in plan["units"]), [u["frame"] for u in plan["units"]]

def metrics(role):
    size_key, ratio_key = role_tokens[role]
    return float(tokens[size_key].rstrip("px")), float(tokens[ratio_key])

def slot_of(unit_id, name):
    return next(s for s in plan_units[unit_id]["slots"] if s["slot"] == name)

def near(a, b):
    return abs(a - b) <= 0.5

def frame(shape):
    node = shape.find(f"{P}spPr/{A}xfrm")
    if node is None:
        node = shape.find(P + "xfrm")
    off, ext = node.find(A + "off"), node.find(A + "ext")
    return tuple(int(v) / 9525 for v in (off.get("x"), off.get("y"), ext.get("cx"), ext.get("cy")))

def body(shape):
    return shape.find(f"{P}txBody/{A}bodyPr")

def text_width(shape):
    pr = body(shape)
    return frame(shape)[2] - (int(pr.get("lIns")) + int(pr.get("rIns"))) / 9525

deck = {name: {name_of(s): s for s in shapes(tree)} for _, name, tree in slides(parts(f"{work}/long/deck.pptx"))}

# The chart: cumulative rows in the label column, every one as tall as the long label's, ending at the
# series box bottom.
series = slot_of("u-komponenten", "series")
box, points = series["box"], [b["data_ref"] for b in units["u-komponenten"]["data_bindings"]]
extra = series["lines"] - len(points)
assert extra >= 1, series["lines"]
long_point = "lohnaufschlag"
assert labels[long_point] == "Lohnaufschlag für Fachkräfte, die im Schichtbetrieb kurzfristig einspringen müssen"
size, ratio = metrics(series["type_role"])
column = box["width"] * 0.4
shown = deck["u-komponenten"]
y = box["y"]
tallest = 1 + extra
for point in points:
    height = max(tallest * size * ratio, 28.0) + item_gap
    label, value = shown[f"copy:data:{point}#label"], shown[f"value:{point}"]
    lx, ly, _, lh = frame(label)
    assert near(lx, box["x"]) and near(ly, y) and near(lh, height), (point, frame(label), box["x"], y, height)
    assert near(text_width(label), column - 8), (point, text_width(label), column - 8)
    assert body(label).get("wrap") == "square", (point, body(label).attrib)
    assert near(frame(value)[1], y) and near(frame(value)[3], height), (point, frame(value), y, height)
    y += height
assert near(y, box["y"] + box["height"]), (y, box)
long_label = shown[f"copy:data:{long_point}#label"]
assert paras(long_label) == [labels[long_point]] and long_label.find(f".//{A}br") is None, paras(long_label)
chart = shown["chart:u-komponenten"]
cx, cy, _, ch = frame(chart)
assert near(cx, box["x"] + column) and near(cy, box["y"]) and near(ch, box["height"]), (frame(chart), box)

# The system: nodes as tall as their planned lines, stacked from the entities box top to its bottom.
entities = slot_of("u-bausteine", "entities")
box, nodes = entities["box"], units["u-bausteine"]["entities"]
extra = entities["lines"] - len(nodes)
assert units["u-bausteine"]["type_floor"] == entities["type_role"] == "type.lead", entities["type_role"]
assert extra == 2, entities["lines"]
size, ratio = metrics(entities["type_role"])
shown = deck["u-bausteine"]
y = box["y"]
for position, entity in enumerate(nodes):
    key = f"copy:{entity['record_ref']}#{entity['field']}"
    lines = 1 + (extra if key == "copy:bausteine#body" else 0)
    height = lines * size * ratio + 2 * node_pad
    node = shown[key]
    nx, ny, _, nh = frame(node)
    assert near(nx, box["x"]) and near(ny, y) and near(nh, height), (key, frame(node), y, height)
    assert near(text_width(node), box["width"] - 260 - 2 * node_pad), (key, text_width(node))
    y += height + (gap if position < len(nodes) - 1 else 0)
assert near(y, box["y"] + box["height"]), (y, box)
long_node = shown["copy:bausteine#body"]
assert paras(long_node) == [records["bausteine"]["body"]] and long_node.find(f".//{A}br") is None, paras(long_node)
PY
then pass "drpx-26-long-labels"; else fail "drpx-26-long-labels"; fi

# --- the declared picture fallback ------------------------------------------------------------------

# The fallback fixture: a direct brief whose middle unit is a conceptual-system/feedback-loop, the one
# variant pattern-library@1 declares a pptx fallback on. Its composition is frozen compose output.
LOOP="$FIXTURES/render/composition-direct-loop-v2.json"
LIBRARY="$PLUGIN_ROOT/references/pattern-library-v1.json"
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/render/direct-loop-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/loop-brief.json"
LBRIEF="$WORK/loop-brief.json"
render "$WORK/loop" "$LBRIEF" "$LOOP" --generated-at 2026-09-14T08:00:00Z --run-id suite

# The fallback's declaration and the fixture's accent colour, read from the library and the theme.
cat > "$WORK/fallbackread.py" <<'PY'
import io, json, struct, sys, zlib
import xml.etree.ElementTree as ET
from deckread import parts, slides, shapes, name_of, rels, resolve, load, A, P, R, TYPES

ASVG = "{http://schemas.microsoft.com/office/drawing/2016/SVG/main}"
SVG = "{http://www.w3.org/2000/svg}"
SVG_EXT = "{96DAC541-7B7A-43D3-8B79-37D633B846F1}"


def declaration(library_path, pattern_id, variant_id):
    library = json.load(open(library_path, encoding="utf-8"))
    pattern = next(p for p in library["patterns"] if p["id"] == pattern_id)
    variant = next(v for v in pattern["variants"] if v["id"] == variant_id)
    return variant.get("fallback"), variant["purpose"]


def png_pixels(data):
    """(width, height, [(r, g, b, a)]) of an 8-bit RGBA PNG whose rows all use filter 0."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n", data[:8]
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    width, height, depth, colour = header[:4]
    assert (depth, colour) == (8, 6), header
    raw = zlib.decompress(idat)
    stride = width * 4 + 1
    pixels = []
    for row in range(height):
        line = raw[row * stride:(row + 1) * stride]
        assert line[0] == 0, line[0]
        pixels += [tuple(line[1 + 4 * x:5 + 4 * x]) for x in range(width)]
    return width, height, pixels


def pictures(package):
    return [(part, name, shape) for part, name, tree in slides(package) for shape in shapes(tree) if shape.tag == P + "pic"]
PY

# drpx-27: the one declared fallback is a standards-shaped OOXML SVG picture on its variant's slide only:
# a p:pic named figure:u-loop whose primary blip is a PNG part — PNG signature, opaque pixels only in the
# theme's accent colour — and whose blip extension holds an asvg:svgBlip naming an SVG part with an svg
# root drawn in that colour; both media types are declared, both relationship ids resolve, and the
# picture's descr is the variant's purpose from the library, not copy. The rest of the slide stays
# native: every copy key is its text frame, and the nodes, glued connectors and kind labels read exactly
# as drpx-11 reads them. The render succeeds under the drpx-20 audit hook, and the render path imports
# no rasteriser.
(cd "$WORK" && env -i PATH="$WORK/decoy" HOME="$WORK/decoy-home" AUDIT_OUT="$WORK/audit-loop.txt" \
   "$PYTHON" "$WORK/audited.py" "$RENDER" render --target pptx --brief "$LBRIEF" --composition "$LOOP" --theme "$THEME" \
   --out "$WORK/audited-loop" > "$WORK/audited-loop.json" 2> "$WORK/audited-loop.err")
if [ ! -s "$WORK/loop.err" ] && [ ! -s "$WORK/audited-loop.err" ] &&
   python3 -c 'import ast, sys; code, events = ast.literal_eval(open(sys.argv[1]).read()); assert code == 0 and events == [], events' "$WORK/audit-loop.txt" &&
   python3 - "$WORK" "$LBRIEF" "$LOOP" "$LIBRARY" "$THEME/tokens/colors.json" "$PLUGIN_ROOT/scripts" <<'PY'
import json, os, re, sys
sys.path.insert(0, sys.argv[1])
import xml.etree.ElementTree as ET
from deckread import parts, slides, shapes, name_of, paras, rels, resolve, load, integrity, copy_problems, A, P, R, TYPES
from fallbackread import declaration, png_pixels, pictures, ASVG, SVG, SVG_EXT
from colours import off_theme
work, brief_path, comp_path, library_path, colors_path, scripts = sys.argv[1:]
envelope = json.load(open(f"{work}/loop.json"))
assert envelope["success"] is True and envelope["data"]["fallbacks"] == 1 and envelope["data"]["fidelity"] == "passed", envelope
deck = f"{work}/loop/deck.pptx"
package = parts(deck)
assert not integrity(package), integrity(package)
assert not off_theme(deck, colors_path), off_theme(deck, colors_path)
assert not copy_problems(deck, brief_path, comp_path), copy_problems(deck, brief_path, comp_path)[:3]
found = pictures(package)
assert [(name, shape.find(f".//{P}cNvPr").get("name")) for _, name, shape in found] == [("u-loop", "figure:u-loop")], found
part, _, picture = found[0]
_, purpose = declaration(library_path, "conceptual-system", "feedback-loop")
descr = picture.find(f"{P}nvPicPr/{P}cNvPr").get("descr")
assert descr == purpose, descr
brief = load(brief_path)
copy = [s[k] for s in brief["records"] for k in ("title", "body", "notes") if isinstance(s.get(k), str)]
assert copy and not [c for c in copy if c in descr], descr
declared = rels(package, part)
blip = picture.find(f"{P}blipFill/{A}blip")
kind, target, mode = declared[blip.get(R + "embed")]
png_part = resolve(part, target)
assert kind.endswith("/image") and mode is None and png_part.startswith("ppt/media/") and png_part.endswith(".png"), target
accent = json.load(open(colors_path))["accent"].lstrip("#").upper()
ink = tuple(int(accent[i:i + 2], 16) for i in (0, 2, 4))
_, _, pixels = png_pixels(package[png_part])
opaque = [p for p in pixels if p[3] == 255]
assert opaque and all(p[:3] == ink for p in opaque) and all(p[3] in (0, 255) for p in pixels), set(pixels)
exts = [e for e in blip.findall(f"{A}extLst/{A}ext") if e.get("uri") == SVG_EXT]
assert len(exts) == 1
svg_blip = exts[0].find(ASVG + "svgBlip")
kind, target, mode = declared[svg_blip.get(R + "embed")]
svg_part = resolve(part, target)
assert kind.endswith("/image") and mode is None and svg_part.startswith("ppt/media/") and svg_part.endswith(".svg"), target
svg = ET.fromstring(package[svg_part])
assert svg.tag == SVG + "svg", svg.tag
paints = {value.upper() for node in svg.iter() for key, value in node.attrib.items() if key in ("fill", "stroke") and value != "none"}
assert paints == {"#" + accent}, paints
assert not [n for n in svg.iter() if n.tag in (SVG + "text", SVG + "tspan")]
types = ET.fromstring(package["[Content_Types].xml"])
defaults = {n.get("Extension").lower(): n.get("ContentType") for n in types.iter(TYPES + "Default")}
assert defaults.get("png") == "image/png" and defaults.get("svg") == "image/svg+xml", defaults
comp = load(comp_path)
unit = next(u for u in comp["units"] if u["id"] == "u-loop")
tree = next(t for _, name, t in slides(package) if name == "u-loop")
ids = {}
for entity in unit["entities"]:
    key = f"copy:{entity['record_ref']}#{entity['field']}"
    nodes = [s for s in shapes(tree) if s.tag == P + "sp" and name_of(s) == key]
    assert len(nodes) == 1 and nodes[0].find(f"{P}nvSpPr/{P}cNvSpPr").get("txBox") != "1", key
    ids[entity["id"]] = nodes[0].find(f".//{P}cNvPr").get("id")
connectors = [(s.find(f".//{A}stCxn").get("id"), s.find(f".//{A}endCxn").get("id")) for s in shapes(tree) if s.tag == P + "cxnSp"]
assert connectors == [(ids[r["from"]], ids[r["to"]]) for r in unit["relationships"]], connectors
assert [paras(s) for s in shapes(tree) if name_of(s).startswith("kind:")] == [[r["kind"]] for r in unit["relationships"]]
for name in os.listdir(scripts):
    if name.endswith(".py"):
        text = open(os.path.join(scripts, name), encoding="utf-8").read()
        assert not re.search(r"^\s*(import|from)\s+(PIL|cairosvg|reportlab)\b", text, re.M), name
# The wrapper spawns the html measurement runtime, never on this path (the audit hook above proves it);
# the modules that draw and check the picture name no process API at all.
for name in ("pptx_adapter.py", "pptx_checks.py", "render_core.py"):
    text = open(os.path.join(scripts, name), encoding="utf-8").read()
    assert "subprocess" not in text, name
PY
then pass "drpx-27-fallback-picture"; else fail "drpx-27-fallback-picture"; fi

# drpx-28: the manifest records the picture honestly and traceably. It satisfies the manifest schema;
# the picture's object is kind image, editable false, carries no copy and records the declared
# capability and a fallback equal to the feedback-loop variant's declaration read from the library —
# never a string this suite types; the top-level fallbacks list holds exactly that object; assets list
# both media parts by their own digests; every other object stays editable. The writer restates
# neither the capability's reason nor its declaration: the reason text occurs nowhere in pptx_adapter.py.
if python3 - "$WORK" "$LIBRARY" "$PLUGIN_ROOT/references/pptx-manifest-v1.schema.json" "$PLUGIN_ROOT/scripts/pptx_adapter.py" <<'PY'
import hashlib, json, sys, zipfile
sys.path.insert(0, sys.argv[1])
from deckread import schema_problems
from fallbackread import declaration
work, library_path, schema_path, adapter = sys.argv[1:]
fallback, _ = declaration(library_path, "conceptual-system", "feedback-loop")
manifest = json.load(open(f"{work}/loop/pptx-manifest.json"))
assert not schema_problems(manifest, json.load(open(schema_path))), schema_problems(manifest, json.load(open(schema_path)))[:3]
slide = next(s for s in manifest["slides"] if s["unit"] == "u-loop")
images = [o for s in manifest["slides"] for o in s["objects"] if o["kind"] == "image"]
assert len(images) == 1 and images[0] in slide["objects"], images
picture = images[0]
assert picture["name"] == "figure:u-loop" and picture["editable"] is False and picture["copy_keys"] == [], picture
assert picture["capability"] == fallback["capability"] and picture["fallback"] == fallback, picture
assert manifest["fallbacks"] == [picture], manifest["fallbacks"]
others = [o for s in manifest["slides"] for o in s["objects"] if o is not picture and o["kind"] != "image"]
assert others and all(o["editable"] is True and o["fallback"] is None for o in others)
with zipfile.ZipFile(f"{work}/loop/deck.pptx") as deck:
    media = {n: "sha256:" + hashlib.sha256(deck.read(n)).hexdigest() for n in deck.namelist() if n.startswith("ppt/media/")}
recorded = {a["part"]: (a["sha256"], a["kind"], a["unit"]) for a in manifest["assets"] if a["part"].startswith("ppt/media/")}
assert len(media) == 2 and {p: d for p, (d, _, _) in recorded.items()} == media, (recorded, media)
assert sorted(k for _, k, _ in recorded.values()) == ["fallback-raster", "fallback-vector"]
assert {u for _, _, u in recorded.values()} == {"u-loop"}
assert fallback["reason"] not in open(adapter, encoding="utf-8").read()
PY
then pass "drpx-28-fallback-manifest"; else fail "drpx-28-fallback-manifest"; fi

# drpx-29: the fallback gate is per variant, not per pattern. The same green deck and manifest, checked
# against a composition whose loop unit uses the sibling variant sequence of the same pattern — a valid
# composition, whose relationship kinds sequence also draws — fails as undeclared-fallback and on
# nothing else: the manifest entry is otherwise complete, so no other arm can be the one that fires.
python3 - "$LOOP" "$WORK/loop-as-sequence.json" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1], encoding="utf-8"))
next(u for u in comp["units"] if u["id"] == "u-loop")["variant"] = "sequence"
json.dump(comp, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
if python3 "$VALIDATOR" check-composition --brief "$LBRIEF" --composition "$WORK/loop-as-sequence.json" > /dev/null &&
   check_rejects "drpx-29-per-variant-gate" "$WORK/loop/deck.pptx" "$LBRIEF" "$WORK/loop-as-sequence.json" undeclared-fallback \
     "$WORK/loop/pptx-manifest.json" &&
   python3 -c 'import json, sys; codes = {f["code"] for f in json.load(open(sys.argv[1]))["data"]["findings"]}; assert codes == {"undeclared-fallback"}, codes' \
     "$WORK/drpx-29-per-variant-gate.out"
then pass "drpx-29-per-variant-gate"; else fail "drpx-29-per-variant-gate"; fi

# drpx-30: every way of misreporting the real fallback is rejected, each on its own arm: the picture's
# manifest fallback stripped (unreported-flattening), the picture left out of the top-level fallbacks
# (unreported-flattening), its text alternative emptied (description-missing), its blip fill removed
# (package-schema) and a media part dropped from the assets (manifest-identity). The green deck itself
# passes check-pptx with its manifest, so each rejection is the edit's.
python3 - "$WORK" <<'PY'
import json, re, sys
sys.path.insert(0, sys.argv[1])
from deckread import doctor
work = sys.argv[1]
src = f"{work}/loop/deck.pptx"
manifest = json.load(open(f"{work}/loop/pptx-manifest.json"))
def picture(m):
    return next(o for s in m["slides"] for o in s["objects"] if o["kind"] == "image")
unfallbacked = json.loads(json.dumps(manifest))
picture(unfallbacked)["fallback"] = None
json.dump(unfallbacked, open(f"{work}/unfallbacked.json", "w"))
unlisted = json.loads(json.dumps(manifest))
unlisted["fallbacks"] = []
json.dump(unlisted, open(f"{work}/unlisted.json", "w"))
unassetted = json.loads(json.dumps(manifest))
unassetted["assets"] = [a for a in unassetted["assets"] if not a["part"].endswith(".svg")]
json.dump(unassetted, open(f"{work}/unassetted.json", "w"))
doctor(src, f"{work}/undescribed.pptx", "ppt/slides/slide3.xml", lambda t: re.sub(r' descr="[^"]*"', ' descr=""', t, count=1))
doctor(src, f"{work}/blipless.pptx", "ppt/slides/slide3.xml", lambda t: re.sub(r"<p:blipFill>.*?</p:blipFill>", "", t, count=1, flags=re.S))
PY
ok=1
python3 "$RENDER" check-pptx --brief "$LBRIEF" --composition "$LOOP" --pptx "$WORK/loop/deck.pptx" \
  --manifest "$WORK/loop/pptx-manifest.json" --theme "$THEME" > /dev/null 2>&1 || ok=0
check_rejects "drpx-30-unfallbacked" "$WORK/loop/deck.pptx" "$LBRIEF" "$LOOP" unreported-flattening "$WORK/unfallbacked.json" || ok=0
check_rejects "drpx-30-unlisted" "$WORK/loop/deck.pptx" "$LBRIEF" "$LOOP" unreported-flattening "$WORK/unlisted.json" || ok=0
check_rejects "drpx-30-undescribed" "$WORK/undescribed.pptx" "$LBRIEF" "$LOOP" description-missing "$WORK/loop/pptx-manifest.json" || ok=0
check_rejects "drpx-30-blipless" "$WORK/blipless.pptx" "$LBRIEF" "$LOOP" package-schema "$WORK/loop/pptx-manifest.json" || ok=0
check_rejects "drpx-30-unassetted" "$WORK/loop/deck.pptx" "$LBRIEF" "$LOOP" manifest-identity "$WORK/unassetted.json" || ok=0
python3 -c 'import json, sys; m = {f["message"] for f in json.load(open(sys.argv[1]))["data"]["findings"] if f["code"] == "unreported-flattening"}; assert any("missing from the manifest" in x for x in m), m' "$WORK/drpx-30-unlisted.out" || ok=0
if [ "$ok" -eq 1 ]; then pass "drpx-30-fallback-negatives"; else fail "drpx-30-fallback-negatives"; fi

# drpx-31: a deck carrying the fallback stays byte-deterministic — two renders at different times and run
# ids give the same bytes, media parts included, and the digest both manifests record.
render "$WORK/loop-again" "$LBRIEF" "$LOOP" --generated-at 2030-01-01T00:00:00Z --run-id another
if python3 - "$WORK" <<'PY'
import hashlib, json, sys
work = sys.argv[1]
first, second = (open(f"{work}/{d}/deck.pptx", "rb").read() for d in ("loop", "loop-again"))
assert first == second
digest = "sha256:" + hashlib.sha256(first).hexdigest()
for d in ("loop", "loop-again"):
    assert json.load(open(f"{work}/{d}/pptx-manifest.json"))["package"]["sha256"] == digest
PY
then pass "drpx-31-fallback-deterministic"; else fail "drpx-31-fallback-deterministic"; fi

# drpx-32: the fallback fixture is genuine compose output. Composing its stripped draft reproduces the
# frozen file exactly, check-composition accepts it against its brief, and the html target renders it.
python3 - "$LOOP" "$WORK/loop-draft.json" <<'PY'
import json, sys
draft = json.load(open(sys.argv[1], encoding="utf-8"))
draft["normalized_brief_ref"].pop("content_fingerprint", None)
draft.pop("document_bindings", None)
for unit in draft["units"]:
    unit.pop("source_refs", None)
    unit.pop("register_refs", None)
    for binding in unit.get("bindings", []):
        binding.pop("digest", None)
json.dump(draft, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
if python3 "$VALIDATOR" compose --brief "$LBRIEF" --composition "$WORK/loop-draft.json" > "$WORK/loop-composed.json" &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"] == json.load(open(sys.argv[2]))' "$WORK/loop-composed.json" "$LOOP" &&
   python3 "$VALIDATOR" check-composition --brief "$LBRIEF" --composition "$LOOP" > /dev/null &&
   python3 "$RENDER" render --target html --brief "$LBRIEF" --composition "$LOOP" --theme "$THEME" --out "$WORK/loop-html" > /dev/null 2>&1
then pass "drpx-32-loop-fixture-frozen"; else fail "drpx-32-loop-fixture-frozen"; fi

# --- a wrapped chart label -------------------------------------------------------------------------

# The wrapped-label fixture: the costs brief with one chart label long enough to wrap in the label
# column while the other three stay on one line. Its composition is frozen compose output.
WRAPPED="$FIXTURES/render/composition-direct-wrap-v2.json"
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/render/direct-wrap-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/wrapped-brief.json"
WBRIEF="$WORK/wrapped-brief.json"

# drpx-33: a native bar chart spreads its categories evenly over its plot area, so each bar sits on its
# label's row only when every row is the same height. Precondition, from the brief, the theme tokens and
# the font-fallbacks advance alone: at least one label is longer than a line of the label column holds,
# so it wraps, and at least one fits one line. Read from the deck with this suite's own reader: the
# chart part holds one bar series whose categories are the brief's labels in order and whose values are
# its literals; each point's category band is derived from the chart frame's a:off y and a:ext cy, the
# plot area's c:manualLayout y and h, c:ptCount and c:orientation (maxMin puts the first category on
# top), and its centre lies within 0.5 px of the centre of that point's copy:data:<id>#label frame. The
# label and value frames sit on the plan's rows, stacked from the series box top to its bottom, and no
# text body in the deck shrinks. A writer that sized each row by its own label puts these bars up to
# 7.5 px off their rows.
render "$WORK/wrapped" "$WBRIEF" "$WRAPPED"
rc=$?
if [ "$rc" -eq 0 ] && [ ! -s "$WORK/wrapped.err" ] &&
   python3 - "$WORK" "$WBRIEF" "$WRAPPED" "$THEME/tokens/typography.json" "$PLUGIN_ROOT/references/font-fallbacks-v1.json" <<'PY'
import json, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, sys.argv[1])
from deckread import parts, slides, shapes, name_of, rels, resolve, A, C, P, R
work, brief_path, comp_path, typography, fallbacks = sys.argv[1:]
brief = json.load(open(brief_path, encoding="utf-8"))
comp = json.load(open(comp_path, encoding="utf-8"))
plan = json.load(open(f"{work}/wrapped/target-plan.json", encoding="utf-8"))
tokens = json.load(open(typography))
chains = json.load(open(fallbacks))
role_tokens = {"type.display": "size-display", "type.heading": "size-h2", "type.lead": "size-h3",
               "type.body": "size-body", "type.caption": "size-small"}
data = {d["id"]: d for d in brief["data"]}
unit = next(u for u in comp["units"] if u["pattern"] == "sourced-chart")
points = [b["data_ref"] for b in unit["data_bindings"]]
plan_unit = next(u for u in plan["units"] if u["composition_unit_ref"] == unit["id"])
series = next(s for s in plan_unit["slots"] if s["slot"] == "series")
box, count = series["box"], len(points)

# The witness mixes a wrapped label with one-line labels: a label longer than a line holds wraps.
face = json.load(open(f"{work}/wrapped/provenance.json"))["layout_face"]
advance = (chains.get("bundled_faces", {}).get(face) or chains["generic_families"][face])["advance_em"]
size = float(tokens[role_tokens[series["type_role"]]].rstrip("px"))
per_line = max(1, int((box["width"] * 0.4 - 8) // (size * advance)))
labels = [data[p]["label"] for p in points]
assert all("\n" not in label for label in labels), labels
wraps = [len(label) > per_line for label in labels]
assert any(wraps) and not all(wraps), (per_line, [len(label) for label in labels])

def frame(shape):
    node = shape.find(f"{P}spPr/{A}xfrm")
    if node is None:
        node = shape.find(P + "xfrm")
    off, ext = node.find(A + "off"), node.find(A + "ext")
    return tuple(int(v) / 9525 for v in (off.get("x"), off.get("y"), ext.get("cx"), ext.get("cy")))

package = parts(f"{work}/wrapped/deck.pptx")
part, _, tree = next(s for s in slides(package) if s[1] == unit["id"])
shown = {name_of(s): s for s in shapes(tree)}
chart_frame = shown[f"chart:{unit['id']}"]
rid = chart_frame.find(f".//{C}chart").get(R + "id")
chart = ET.fromstring(package[resolve(part, rels(package, part)[rid][1])])

# The chart says exactly what the brief says.
assert len(chart.findall(f".//{C}barChart")) == 1 and len(chart.findall(f".//{C}barChart/{C}ser")) == 1
ser = chart.find(f".//{C}barChart/{C}ser")
n = int(ser.find(f"{C}cat//{C}ptCount").get("val"))
assert n == count and int(ser.find(f"{C}val//{C}ptCount").get("val")) == count, n
assert [node.text for node in ser.findall(f"{C}cat//{C}pt/{C}v")] == labels
assert [float(node.text) for node in ser.findall(f"{C}val//{C}pt/{C}v")] == [float(data[p]["value"]) for p in points]

# Each category band from the package, against its label frame.
_, fy, _, fh = frame(chart_frame)
layout = chart.find(f".//{C}plotArea/{C}layout/{C}manualLayout")
assert layout is not None and layout.find(C + "yMode").get("val") == "edge", "no edge-mode manual plot layout"
my, mh = float(layout.find(C + "y").get("val")), float(layout.find(C + "h").get("val"))
top_first = chart.find(f".//{C}catAx/{C}scaling/{C}orientation").get("val") == "maxMin"
offsets = []
for i, point in enumerate(points):
    band = fy + my * fh + ((i if top_first else n - 1 - i) + 0.5) * mh * fh / n
    _, ly, _, lh = frame(shown[f"copy:data:{point}#label"])
    offsets.append(round(ly + lh / 2 - band, 3))
assert all(abs(o) <= 0.5 for o in offsets), ("bars off their label rows", offsets)

# The label and value frames are the plan's rows, and nothing in the deck shrinks.
y, row = box["y"], box["height"] / count
for point in points:
    _, ly, _, lh = frame(shown[f"copy:data:{point}#label"])
    _, vy, _, vh = frame(shown[f"value:{point}"])
    assert abs(ly - y) <= 0.5 and abs(lh - row) <= 0.5 and abs(vy - y) <= 0.5 and abs(vh - row) <= 0.5, (point, ly, lh, y, row)
    y += row
assert abs(y - (box["y"] + box["height"])) <= 0.5, (y, box)
for name, body in package.items():
    if name.endswith(".xml"):
        assert b"normAutofit" not in body and b"fontScale" not in body, name
PY
then pass "drpx-33-wrapped-chart-alignment"; else fail "drpx-33-wrapped-chart-alignment"; fi

# drpx-34: the wrapped-label fixture is genuine compose output. Composing its stripped draft reproduces
# the frozen file exactly, and check-composition accepts it against its brief.
python3 - "$WRAPPED" "$WORK/wrapped-draft.json" <<'PY'
import json, sys
draft = json.load(open(sys.argv[1], encoding="utf-8"))
draft["normalized_brief_ref"].pop("content_fingerprint", None)
draft.pop("document_bindings", None)
for unit in draft["units"]:
    unit.pop("source_refs", None)
    unit.pop("register_refs", None)
    for binding in unit.get("bindings", []):
        binding.pop("digest", None)
json.dump(draft, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
if python3 "$VALIDATOR" compose --brief "$WBRIEF" --composition "$WORK/wrapped-draft.json" > "$WORK/wrapped-composed.json" &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"] == json.load(open(sys.argv[2]))' "$WORK/wrapped-composed.json" "$WRAPPED" &&
   python3 "$VALIDATOR" check-composition --brief "$WBRIEF" --composition "$WRAPPED" > /dev/null
then pass "drpx-34-wrap-fixture-frozen"; else fail "drpx-34-wrap-fixture-frozen"; fi

printf '%s\n' "Design-render PPTX tests: $passes passed, $failures failed"
[ "$failures" -eq 0 ]
