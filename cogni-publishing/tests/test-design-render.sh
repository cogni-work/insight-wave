#!/usr/bin/env bash
# design-render suite for cogni-publishing: the HTML target over target-resolved-plan@2 — outputs,
# frozen copy, markup-as-text, pattern semantics, tokens, citations, portability, accessibility,
# font resolution, the re-render comparator, provenance, the runtime pin and the runtime boundary.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `drnd`; NN is an allocation
# counter, so never renumber an existing id — the mutation recipes below record two.
#
# Every expected string comes from the fixture inputs (the normalized brief and the composition),
# read by this suite's own html.parser extraction, never from a file the renderer produced. Every
# negative is derived in a scratch directory from a green render by one small edit; no tracked
# fixture is mutated. A case that needs an edited brief edits a copy of the direct brief and
# recomposes the composition from a stripped draft with `compose`, never by typing a digest. Two
# cases need the pinned browser runtime: without it they print a SKIP line naming the absent runtime
# and never PASS. drnd-36 compiles the render path under the oldest Python 3.9-3.11 interpreter on
# the host and prints SKIP when there is none, as on CI's 3.12+ runner.
#
# Mutation recipes (run from the repository root; the harness is the installed managed-service
# cogni-service plugin, and --expr is evaluated by perl -0pi). The first makes copy text wrong and
# must fail drnd-10; the second makes the portability scan read copy text and must fail drnd-37:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/html_adapter.py --expr 's/return escape\(value, quote=True\)/return escape(value.upper(), quote=True)/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-10-frozen-copy
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_checks.py --expr 's/if node\.tag == "style":/if True:/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-37-prose-paths-render
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
RENDER="$PLUGIN_ROOT/scripts/design-render.py"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-publishing.py"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
THEME="$FIXTURES/render/themes/cogni-work"
NBRIEF="$FIXTURES/narrative-slides-v1.expected.json"
NARR="$FIXTURES/composition-narrative-v2.json"
COSTS="$FIXTURES/composition-direct-costs-v2.json"
GERMAN="$FIXTURES/render/composition-direct-de-edge-v2.json"
CAPTURED="$FIXTURES/render/plan-narrative-captured-v2.json"
SKILL="$PLUGIN_ROOT/skills/design-render/SKILL.md"
PYTHON="$(command -v python3)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0
failures=0
skips=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
skip() { printf 'SKIP: %s\n' "$1"; skips=$((skips + 1)); }

render() {  # render <out-dir> <brief> <composition> [extra args...]
  local out="$1" brief="$2" comp="$3"
  shift 3
  python3 "$RENDER" render --target html --brief "$brief" --composition "$comp" --theme "$THEME" \
    --out "$out" "$@" > "$out.json" 2> "$out.err"
}

# One independent reader for every case below: html.parser, entity decoding only.
cat > "$WORK/extract.py" <<'PY'
import json
from html.parser import HTMLParser

VOID = {"meta", "link", "br", "img", "input", "hr"}


class Extract(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.found, self.scripts, self.tags = [], [], 0, []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.tags.append(tag)
        if tag == "script":
            self.scripts += 1
        if tag in VOID:
            return
        entry = None
        if "data-copy" in attrs:
            entry = ["copy", attrs["data-copy"], ""]
        elif "data-value" in attrs:
            entry = ["value", attrs["data-value"], ""]
        self.stack.append(entry)
        if entry:
            self.found.append(entry)

    def handle_endtag(self, tag):
        if tag not in VOID and self.stack:
            self.stack.pop()

    def handle_data(self, data):
        for entry in self.stack:
            if entry:
                entry[2] += data


def extract(path):
    parser = Extract()
    parser.feed(open(path, encoding="utf-8").read())
    parser.close()
    return parser


def load(path):
    # Numbers keep the text the brief wrote, so a value label is compared with the literal.
    return json.load(open(path, encoding="utf-8"), parse_float=str, parse_int=str)


def expected(brief, composition):
    records = {r["id"]: r for r in brief["records"]}
    data = {d["id"]: d for d in brief.get("data", [])}
    sources = {s["id"]: s for s in brief.get("sources", [])}

    def field(record_id, name):
        record = records[record_id]
        if record["kind"] == "slide" and name != "headline":
            return next(f["value"] for f in record["fields"] if f["key"] == name)
        return record[name]

    copy, values = {}, {}
    for unit in composition["units"]:
        for binding in unit["bindings"]:
            value = field(binding["record_ref"], binding["field"])
            key = binding["record_ref"] + "#" + binding["field"]
            if isinstance(value, list):
                copy.update({f"{key}#{i}": item for i, item in enumerate(value)})
            else:
                copy[key] = value
        for point in unit.get("data_bindings", []):
            item = data[point["data_ref"]]
            copy[f"data:{item['id']}#label"] = item["label"]
            values[item["id"]] = f"{item['value']} {item['unit']}"
        for ref in unit.get("register_refs", []):
            source = sources[ref]
            if "raw" in source:
                copy[f"source:{ref}#raw"] = source["raw"]
            else:
                copy.update({f"source:{ref}#{k}": v for k, v in source.items() if k != "id" and isinstance(v, str) and v})
    for binding in composition.get("document_bindings", []):
        copy[f"trailer#{binding['index']}"] = brief["freeze"]["trailer_notes"][int(binding["index"])]
    for key in ("title", "subtitle"):
        if isinstance((brief.get("document") or {}).get(key), str) and brief["document"][key]:
            copy[f"document#{key}"] = brief["document"][key]
    return copy, values


def frozen_copy_problems(html_path, brief_path, composition_path):
    """Every bound string, note, source entry and value label shown exactly; nothing invented."""
    copy, values = expected(load(brief_path), load(composition_path))
    page = extract(html_path)
    problems = []
    found = {}
    for kind, key, text in page.found:
        found.setdefault((kind, key), []).append(text)
    for key, want in copy.items():
        texts = found.get(("copy", key), [])
        if not texts:
            problems.append(("omitted", key))
        problems += [("changed", key, t) for t in texts if t != want]
    for key, want in values.items():
        texts = found.get(("value", key), [])
        if not texts:
            problems.append(("omitted", key))
        problems += [("changed", key, t) for t in texts if t != want]
    problems += [("invented", key) for kind, key in found if kind == "copy" and key not in copy]
    return problems
PY

# Fixture briefs: the direct briefs are normalized here, exactly as a caller would.
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/direct-costs-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/costs-brief.json"
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/render/direct-de-edge-v1.json" \
  | python3 -c 'import json, sys; json.dump(json.load(sys.stdin)["data"], open(sys.argv[1], "w"), ensure_ascii=False)' "$WORK/de-brief.json"
CBRIEF="$WORK/costs-brief.json"
DBRIEF="$WORK/de-brief.json"

# drnd-01: the skill is well-formed, documents the HTML branch and claims no retired render trigger.
if python3 - "$SKILL" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
front = text.split("---", 2)[1]
name = re.search(r"^name:\s*(.+)$", front, re.M).group(1).strip()
desc = re.search(r"^description:\s*(.+)$", front, re.M).group(1).strip()
assert name == "design-render", name
assert 0 < len(desc) <= 1024, len(desc)
retired = ("html slides", "html presentation", "browser presentation", "render slides as html",
           "self-contained slides", "slide deck in browser", "web slides", "present in browser",
           "open slides in browser", "export slides as html", "generating an html version",
           "adding charts or diagrams", "no powerpoint", "refine slides", "adjust slide", "fix slide")
quoted = {q.lower() for q in re.findall(r'"([^"]+)"', desc)}
assert not quoted & set(retired), quoted & set(retired)
assert "--target html" in text and "render" in text
for alias in ("story-to-", "render-html-slides", "enrich-report"):
    assert alias not in text, alias
PY
then pass "drnd-01-skill-frontmatter"; else fail "drnd-01-skill-frontmatter"; fi

# drnd-02: the wrapper and render path import only the stdlib and each other. sys.stdlib_module_names
# exists from Python 3.10; on the 3.9 floor a module counts as stdlib when it is built in or frozen, or
# resolves under the interpreter's stdlib directory and outside site-packages. Unresolvable fails closed.
if python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import ast, importlib.util, os, sys, sysconfig
root = sys.argv[1]
own = {"render_core", "html_adapter", "render_checks"}
names = getattr(sys, "stdlib_module_names", None)


def inside(path, directory):
    return path == directory or path.startswith(directory.rstrip(os.sep) + os.sep)


def stdlib(mod):
    if names is not None:
        return mod in names
    if mod in sys.builtin_module_names:
        return True
    try:
        spec = importlib.util.find_spec(mod)
    except (ImportError, ValueError):
        return False
    if spec is None or not spec.origin:
        return False
    if spec.origin in ("built-in", "frozen"):
        return True
    paths = sysconfig.get_paths()
    origin = os.path.realpath(spec.origin)
    if {"site-packages", "dist-packages"} & set(origin.split(os.sep)):
        return False
    homes = [os.path.realpath(paths[key]) for key in ("stdlib", "platstdlib")]
    sites = [os.path.realpath(paths[key]) for key in ("purelib", "platlib")]
    return any(inside(origin, home) for home in homes) and not any(inside(origin, site) for site in sites)


for name in ("design-render.py", "render_core.py", "html_adapter.py", "render_checks.py"):
    tree = ast.parse(open(f"{root}/{name}", encoding="utf-8").read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            mods = [a.name.split(".")[0] for a in node.names]
        elif isinstance(node, ast.ImportFrom):
            mods = [(node.module or "").split(".")[0]]
        else:
            continue
        for mod in mods:
            assert mod in own or stdlib(mod), (name, mod)
PY
then pass "drnd-02-stdlib-only"; else fail "drnd-02-stdlib-only"; fi

# drnd-03: nothing in the wrapper or render path installs anything or looks a binary up on PATH.
if python3 - "$PLUGIN_ROOT" <<'PY'
import re, sys
root = sys.argv[1]
forbidden = [r"pip install", r"npm install", r"\bnpm i\b", r"npm ci", r"\bnpx\b", r"pnpm dlx", r"yarn dlx",
             r"curl[^\n|]*\|\s*(?:ba)?sh", r"shutil\.which", r"os\.environ", r"getenv", r"PATH="]
for name in ("scripts/design-render.py", "scripts/render_core.py", "scripts/html_adapter.py",
             "scripts/render_checks.py", "runtime/measure.mjs"):
    source = open(f"{root}/{name}", encoding="utf-8").read()
    for pattern in forbidden:
        assert not re.search(pattern, source), (name, pattern)
PY
then pass "drnd-03-no-implicit-install"; else fail "drnd-03-no-implicit-install"; fi

# drnd-04: no model API and no workspace prerequisite anywhere in the render path.
if python3 - "$PLUGIN_ROOT" <<'PY'
import sys
root = sys.argv[1]
for name in ("scripts/design-render.py", "scripts/render_core.py", "scripts/html_adapter.py",
             "scripts/render_checks.py", "runtime/measure.mjs"):
    source = open(f"{root}/{name}", encoding="utf-8").read().lower()
    for token in ("anthropic", "openai", "claude_agent_sdk", "cogni_workspace_plugin",
                  "workspace_plugin_root", ".workspace-config.json"):
        assert token not in source, (name, token)
PY
then pass "drnd-04-no-model-api-or-workspace"; else fail "drnd-04-no-model-api-or-workspace"; fi

# drnd-05: the committed runtime pins every package exactly and keeps its install directories untracked.
if python3 "$RENDER" check-runtime-lock > "$WORK/lock.json" &&
   python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert e["success"] and e["data"]["pin"]' "$WORK/lock.json" &&
   git -C "$REPO_ROOT" check-ignore -q "cogni-publishing/runtime/node_modules/x" &&
   git -C "$REPO_ROOT" check-ignore -q "cogni-publishing/runtime/browsers/x" &&
   git -C "$REPO_ROOT" check-ignore -q "cogni-publishing/runtime/.provisioned.json" &&
   [ -z "$(git -C "$REPO_ROOT" ls-files cogni-publishing/runtime/node_modules cogni-publishing/runtime/browsers cogni-publishing/runtime/.provisioned.json)" ]
then pass "drnd-05-runtime-lock-pinned"; else fail "drnd-05-runtime-lock-pinned"; fi

# drnd-06 / drnd-07: the lock inspection goes red on a range pin and on a package missing from the lock.
lock_negative() {
  local id="$1" code="$2" edit="$3" dir="$WORK/$1"
  mkdir -p "$dir"
  cp "$PLUGIN_ROOT/runtime/package.json" "$PLUGIN_ROOT/runtime/package-lock.json" "$PLUGIN_ROOT/runtime/.gitignore" "$dir/"
  python3 - "$dir/package.json" "$edit" <<'PY'
import json, sys
path, edit = sys.argv[1:]
manifest = json.load(open(path))
if edit == "range":
    manifest["dependencies"]["playwright-core"] = "^" + manifest["dependencies"]["playwright-core"]
else:
    manifest["dependencies"]["left-pad"] = "1.3.0"
json.dump(manifest, open(path, "w"))
PY
  local rc=0
  python3 "$RENDER" check-runtime-lock --runtime-dir "$dir" > "$dir.out" || rc=$?
  if [ "$rc" -eq 1 ] && python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert not e["success"] and sys.argv[2] in {f["code"] for f in e["data"]["findings"]}' "$dir.out" "$code"
  then pass "$id"; else fail "$id"; fi
}
lock_negative "drnd-06-lock-range-pin" range-pin range
lock_negative "drnd-07-lock-missing-package" lock-missing missing

# drnd-08: with the runtime unreachable, PATH scrubbed to decoy installers and the workspace variables
# unset, a runtime-backed render answers one actionable envelope, writes nothing and installs nothing.
mkdir -p "$WORK/decoy" "$WORK/empty-runtime" "$WORK/home"
for tool in npm npx node pip pip3 curl; do
  printf '#!/bin/sh\ntouch "%s/installed-$0"\n' "$WORK" > "$WORK/decoy/$tool"
  chmod +x "$WORK/decoy/$tool"
done
rc=0
(cd "$WORK" && env -i PATH="$WORK/decoy" HOME="$WORK/home" "$PYTHON" "$RENDER" render --target html --brief "$NBRIEF" \
   --composition "$NARR" --theme "$THEME" --out "$WORK/missing-out" --measure --runtime-root "$WORK/empty-runtime" \
   > "$WORK/missing.out" 2> "$WORK/missing.err") || rc=$?
if [ "$rc" -ne 0 ] && [ ! -s "$WORK/missing.err" ] && [ ! -e "$WORK/missing-out" ] &&
   [ -z "$(ls -A "$WORK/empty-runtime")" ] && ! ls "$WORK"/installed-* >/dev/null 2>&1 &&
   python3 - "$WORK/missing.out" <<'PY'
import json, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
assert len(lines) == 1, lines
env = json.loads(lines[0])
assert env["success"] is False and env["data"]["code"] == "runtime-missing", env
assert "provision.sh" in env["error"] and "runtime" in env["error"], env["error"]
PY
then pass "drnd-08-runtime-missing-envelope"; else fail "drnd-08-runtime-missing-envelope"; fi

# drnd-09: from an empty environment, the entry point turns a validated composition and theme into a
# target plan, an HTML artifact and a provenance manifest, all named in the envelope and all on disk.
cat > "$WORK/outputs.py" <<'PY'
import json, os, sys
def outputs_complete(envelope_path):
    env = json.load(open(envelope_path, encoding="utf-8"))
    if not env.get("success"):
        return False
    data = env["data"]
    return all(isinstance(data.get(key), str) and os.path.isfile(data[key])
               for key in ("target_plan", "artifact", "provenance"))
if __name__ == "__main__":
    sys.exit(0 if outputs_complete(sys.argv[1]) else 1)
PY
(cd "$WORK" && env -i PATH="$(dirname "$PYTHON"):/usr/bin:/bin" HOME="$WORK/home" "$PYTHON" "$RENDER" render --target html \
   --brief "$CBRIEF" --composition "$COSTS" --theme "$THEME" --out "$WORK/costs" > "$WORK/costs.json" 2> "$WORK/costs.err")
if [ ! -s "$WORK/costs.err" ] && python3 "$WORK/outputs.py" "$WORK/costs.json"
then pass "drnd-09-render-outputs"; else fail "drnd-09-render-outputs"; fi

render "$WORK/narr" "$NBRIEF" "$NARR" --generated-at 2026-09-14T08:00:00Z --run-id suite
render "$WORK/de" "$DBRIEF" "$GERMAN" --language de

# drnd-10: frozen copy — every visible string, note, source entry and value label of all three
# fixtures, including the German one, equals the brief exactly; nothing is omitted or invented.
if python3 - "$WORK" "$NBRIEF" "$NARR" "$CBRIEF" "$COSTS" "$DBRIEF" "$GERMAN" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from extract import frozen_copy_problems
work = sys.argv[1]
for out, brief, comp in (("narr", sys.argv[2], sys.argv[3]), ("costs", sys.argv[4], sys.argv[5]),
                         ("de", sys.argv[6], sys.argv[7])):
    problems = frozen_copy_problems(f"{work}/{out}/index.html", brief, comp)
    assert not problems, (out, problems[:3])
PY
then pass "drnd-10-frozen-copy"; else fail "drnd-10-frozen-copy"; fi

# drnd-11: the same reader and check-html both reject an omitted and a changed string.
if python3 - "$WORK" "$NBRIEF" "$NARR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from extract import frozen_copy_problems
work, brief, comp = sys.argv[1:]
page = open(f"{work}/narr/index.html", encoding="utf-8").read()
changed = page.replace("lose 11 percent more production hours", "lose 11 percent more production  hours", 1)
omitted = page.replace('data-copy="slide-3#talk_track"', 'data-copy-dropped="slide-3#talk_track"', 1)
for name, text in (("changed", changed), ("omitted", omitted)):
    assert text != page
    open(f"{work}/copy-{name}.html", "w", encoding="utf-8").write(text)
    problems = frozen_copy_problems(f"{work}/copy-{name}.html", brief, comp)
    assert any(p[0] == name for p in problems), (name, problems)
PY
then
  ok=1
  for name in changed omitted; do
    python3 "$RENDER" check-html --brief "$NBRIEF" --composition "$NARR" --html "$WORK/copy-$name.html" > "$WORK/copy-$name.out" && ok=0
    python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert "frozen-copy" in {f["check"] for f in e["data"]["findings"]}' "$WORK/copy-$name.out" || ok=0
  done
  if [ "$ok" -eq 1 ]; then pass "drnd-11-frozen-copy-negative"; else fail "drnd-11-frozen-copy-negative"; fi
else fail "drnd-11-frozen-copy-negative"; fi

# drnd-12: markup, entities, quotes and non-breaking spaces in copy render as literal text.
if python3 - "$WORK" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from extract import extract
page = extract(f"{sys.argv[1]}/de/index.html")
found = {key: text for kind, key, text in page.found if kind == "copy"}
assert found["heute#title"] == "Heute: Wartung nach Kalender <script>alert(1)</script>"
assert found["morgen#title"] == "Morgen: Wartung nach Zustand &amp; Signal"
assert found["antwort#title"] == "Abwarten kostet 17,4 Mio. € in drei Jahren"
assert "<b>die</b>" in found["antwort#notes"] and "\n" in found["antwort#notes"]
assert found["morgen#body"].endswith("\"erst messen\", dann 'handeln'.")
assert page.scripts == 0 and "b" not in page.tags
assert "Ungeplanter Stillstand" in found.values() and found["data:versicherung#label"] == "Versicherungszuschläge"
PY
then pass "drnd-12-markup-as-text"; else fail "drnd-12-markup-as-text"; fi

# drnd-13: nothing hides, clamps or clips copy.
if python3 - "$WORK/narr/index.html" "$PLUGIN_ROOT/scripts/html_adapter.py" <<'PY'
import re, sys
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    for pattern in (r"text-overflow\s*:\s*ellipsis", r"line-clamp", r"display\s*:\s*none", r"overflow\s*:\s*(?:hidden|clip)",
                    r"visibility\s*:\s*hidden"):
        assert not re.search(pattern, text, re.I), (path, pattern)
PY
then pass "drnd-13-no-truncating-css"; else fail "drnd-13-no-truncating-css"; fi

# doctor <id> <html> <python-edit> — derive a page by one edit; check-html must fail naming <check>.
doctored() {
  local id="$1" source="$2" brief="$3" comp="$4" check="$5" edit="$6" rc=0
  python3 - "$source" "$WORK/$id.html" "$edit" <<'PY'
import re, sys
src, dst, edit = sys.argv[1:]
page = open(src, encoding="utf-8").read()
new = eval(edit, {"re": re, "page": page})
assert new != page, "the edit changed nothing"
open(dst, "w", encoding="utf-8").write(new)
PY
  [ $? -eq 0 ] || return 1
  python3 "$RENDER" check-html --brief "$brief" --composition "$comp" --html "$WORK/$id.html" --theme "$THEME" \
    > "$WORK/$id.out" || rc=$?
  [ "$rc" -eq 1 ] && python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert sys.argv[2] in {f["check"] for f in e["data"]["findings"]}, e["data"]["findings"]' "$WORK/$id.out" "$check"
}
green() {  # green <html> <brief> <composition>: check-html (with tokens) passes on a real render
  python3 "$RENDER" check-html --brief "$2" --composition "$3" --html "$1" --theme "$THEME" > /dev/null
}

# drnd-14..17: one semantic assertion per proof pattern, each paired with a negative.
if green "$WORK/narr/index.html" "$NBRIEF" "$NARR" && green "$WORK/de/index.html" "$DBRIEF" "$GERMAN" &&
   doctored drnd-14-neg "$WORK/narr/index.html" "$NBRIEF" "$NARR" comparison \
     're.sub(r"<td id=\"side-u-slide-2-2\"[^>]*>.*?</td>", "", page, count=1, flags=re.S)'
then pass "drnd-14-comparison-sides"; else fail "drnd-14-comparison-sides"; fi
if green "$WORK/costs/index.html" "$CBRIEF" "$COSTS" &&
   doctored drnd-15-neg "$WORK/costs/index.html" "$CBRIEF" "$COSTS" chart \
     'page.replace("<rect class=\"mark\" data-ref=\"wage-premium\"", "<rect class=\"bar\" data-ref=\"wage-premium\"", 1)'
then pass "drnd-15-chart-marks"; else fail "drnd-15-chart-marks"; fi
if doctored drnd-16-neg "$WORK/narr/index.html" "$NBRIEF" "$NARR" conceptual \
     're.sub(r"(<g class=\"node\" data-entity=\"e2\">.*?<text[^>]*>).*?(</text>)", r"\1\2", page, count=1, flags=re.S)'
then pass "drnd-16-conceptual-labels"; else fail "drnd-16-conceptual-labels"; fi
if doctored drnd-17-neg "$WORK/costs/index.html" "$CBRIEF" "$COSTS" register \
     're.sub(r"(<section class=\"unit pattern-sourced-chart.*?</section>)(<section class=\"unit pattern-sources.*?</section>)", r"\2\1", page, count=1, flags=re.S)'
then pass "drnd-17-register-last"; else fail "drnd-17-register-last"; fi

# drnd-18: brand values come from the theme's tokens — the custom properties equal the fixture token
# values, every proof pattern is styled through at least one of them, and component CSS has no literal.
if python3 - "$WORK/narr/index.html" "$WORK/costs/index.html" "$THEME" <<'PY'
import json, re, sys
narr, costs, theme = sys.argv[1:]
declared = {}
for stem in ("colors", "typography", "spacing"):
    for key, value in json.load(open(f"{theme}/tokens/{stem}.json")).items():
        declared[f"--{stem}-{key}"] = value
pages = [open(p, encoding="utf-8").read() for p in (narr, costs)]
for page in pages:
    root = re.search(r":root \{\n(.*?)\n\}", page, re.S).group(1)
    shown = dict(re.findall(r"(--[a-z0-9-]+): ([^;]+);", root))
    for name, value in declared.items():
        assert shown.get(name) == value, (name, shown.get(name), value)
    components = page.split("/* design-render: components */", 1)[1].split("</style>", 1)[0]
    assert not re.search(r"#[0-9a-fA-F]{3,8}\b|rgba?\(|font-family\s*:(?!\s*var\()", components)
styled = {}
for page in pages:
    components = page.split("/* design-render: components */", 1)[1]
    for pattern in ("answer-emphasis", "comparison", "sourced-chart", "conceptual-system", "sources"):
        for body in re.findall(r"\.pattern-" + pattern + r"\b[^{]*\{([^}]*)\}", components):
            styled.setdefault(pattern, set()).update(n for n in re.findall(r"var\((--[a-z0-9-]+)\)", body) if n in declared)
assert all(styled.get(p) for p in ("answer-emphasis", "comparison", "sourced-chart", "conceptual-system", "sources")), styled
PY
then
  if doctored drnd-18-neg "$WORK/narr/index.html" "$NBRIEF" "$NARR" tokens \
       'page.replace("/* design-render: components */", "/* design-render: components */\n.unit { color: #ff0000; }", 1)'
  then pass "drnd-18-brand-tokens"; else fail "drnd-18-brand-tokens"; fi
else fail "drnd-18-brand-tokens"; fi

# drnd-19: every citation marker links its source record's URL byte for byte; a missing anchor, an
# unresolved marker and a substituted URL are each rejected.
if green "$WORK/costs/index.html" "$CBRIEF" "$COSTS" &&
   python3 - "$WORK/narr/index.html" "$NBRIEF" <<'PY'
import json, re, sys
page, brief = open(sys.argv[1], encoding="utf-8").read(), json.load(open(sys.argv[2], encoding="utf-8"))
urls = {s["marker"]: s["url"] for s in brief["sources"]}
links = re.findall(r'<a class="cite" href="([^"]*)" data-source="[^"]*">(\[[0-9]+\])</a>', page)
assert links and all(urls[marker] == href for href, marker in links), links[:3]
PY
then
  ok=1
  doctored drnd-19-missing "$WORK/narr/index.html" "$NBRIEF" "$NARR" citation \
    're.sub(r"<a class=\"cite\"[^>]*>(\[1\])</a>", r"\1", page, count=1)' || ok=0
  doctored drnd-19-unresolved "$WORK/narr/index.html" "$NBRIEF" "$NARR" citation \
    're.sub(r"(<a class=\"cite\"[^>]*>)\[1\](</a>)", r"\1[9]\2", page, count=1)' || ok=0
  doctored drnd-19-substituted "$WORK/narr/index.html" "$NBRIEF" "$NARR" citation \
    'page.replace("href=\"https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html\" data-source", "href=\"https://example.com/\" data-source", 1)' || ok=0
  if [ "$ok" -eq 1 ]; then pass "drnd-19-citations"; else fail "drnd-19-citations"; fi
else fail "drnd-19-citations"; fi

# drnd-20: the page needs nothing outside itself — the static scan is clean on a copy in a fresh
# directory, and a remote font link is rejected.
mkdir -p "$WORK/portable"
cp "$WORK/de/index.html" "$WORK/portable/index.html"
if green "$WORK/portable/index.html" "$DBRIEF" "$GERMAN" &&
   ! grep -qE '(src|href)="(https?:)?//[^"]*\.(css|js|woff2?|ttf|otf|png|svg)|@import|url\((https?:)?//' "$WORK/portable/index.html" &&
   doctored drnd-20-neg "$WORK/de/index.html" "$DBRIEF" "$GERMAN" assets \
     'page.replace("<style>", "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=DM+Sans\">\n<style>", 1)'
then pass "drnd-20-portable-output"; else fail "drnd-20-portable-output"; fi

# drnd-21: reading order and accessible descriptions — DOM order equals composition order, figures are
# named by their claim and described by their alternative, and both breaches are rejected.
if python3 - "$WORK/narr/index.html" "$NARR" <<'PY'
import json, re, sys
page, comp = open(sys.argv[1], encoding="utf-8").read(), json.load(open(sys.argv[2]))
assert re.findall(r'<section [^>]*data-unit="([^"]+)"', page) == [u["id"] for u in comp["units"]]
for svg in re.findall(r"<svg [^>]*>", page):
    assert 'role="img"' in svg and "aria-labelledby=" in svg and "aria-describedby=" in svg, svg
PY
then
  ok=1
  doctored drnd-21-description "$WORK/narr/index.html" "$NBRIEF" "$NARR" description \
    're.sub(r"(<svg role=\"img\") aria-labelledby=\"[^\"]*\"", r"\1", page, count=1)' || ok=0
  doctored drnd-21-order "$WORK/narr/index.html" "$NBRIEF" "$NARR" reading-order \
    're.sub(r"(<section class=\"unit[^>]*data-unit=\"u-slide-2\".*?</section>)(<section class=\"unit[^>]*data-unit=\"u-slide-3\".*?</section>)", r"\2\1", page, count=1, flags=re.S)' || ok=0
  if [ "$ok" -eq 1 ]; then pass "drnd-21-reading-order-and-descriptions"; else fail "drnd-21-reading-order-and-descriptions"; fi
else fail "drnd-21-reading-order-and-descriptions"; fi

# theme_variant <dir> <value> [typography key]: a copy of the fixture theme with one typography token
# changed — by default the copy-font stack, font-sans.
theme_variant() {
  mkdir -p "$1"
  cp -R "$THEME" "$1/cogni-work"
  python3 - "$1/cogni-work/tokens/typography.json" "$2" "${3:-font-sans}" <<'PY'
import json, sys
path, value, key = sys.argv[1:]
tokens = json.load(open(path))
tokens[key] = value
json.dump(tokens, open(path, "w"))
PY
}

# drnd-22: an unbundled brand face falls back through the documented chain, the substitution is
# recorded, and the layout is recomputed with the fallback face — a monospace fallback moves geometry.
theme_variant "$WORK/mono" "'Brand Face', monospace"
python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$WORK/mono/cogni-work" \
  --out "$WORK/mono-out" > "$WORK/mono-out.json"
if python3 - "$WORK/narr" "$WORK/mono-out" "$PLUGIN_ROOT/references/font-fallbacks-v1.json" <<'PY'
import json, sys
sans, mono, fallbacks = sys.argv[1:]
chains = json.load(open(fallbacks))["generic_families"]
for out, face, skipped in ((sans, "system-ui", ["DM Sans", "Inter"]), (mono, "monospace", ["Brand Face"])):
    prov = json.load(open(f"{out}/provenance.json"))
    font = next(f for f in prov["fonts"] if f["token"] == "typography.font-sans")
    assert font["resolved_face"] == face and font["substituted"] is True and font["skipped"] == skipped, font
    assert font["fallback_chain"] == chains[face]["chain"], font
    assert prov["layout_face"] == face
    plan = json.load(open(f"{out}/target-plan.json"))
    assert {s["measured_with"] for u in plan["units"] for s in u["slots"]} == {face}
PY
then
  rc=0
  python3 "$RENDER" compare --expected "$WORK/narr/target-plan.json" --actual "$WORK/mono-out/target-plan.json" > "$WORK/mono-cmp.json" || rc=$?
  if [ "$rc" -eq 1 ]; then pass "drnd-22-font-fallback-recomputes-layout"; else fail "drnd-22-font-fallback-recomputes-layout"; fi
else fail "drnd-22-font-fallback-recomputes-layout"; fi

# drnd-23: a stack with no bundled or generic member fails naming the font and writes nothing.
theme_variant "$WORK/nofont" "'Brand Face', 'Other Face'"
rc=0
python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$WORK/nofont/cogni-work" \
  --out "$WORK/nofont-out" > "$WORK/nofont.json" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -e "$WORK/nofont-out" ] &&
   python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert e["data"]["code"] == "font-unresolved" and e["data"]["reference"] == "Brand Face"' "$WORK/nofont.json"
then pass "drnd-23-font-unresolved"; else fail "drnd-23-font-unresolved"; fi

# drnd-24: a provenance record showing a substitution without its record is rejected.
if python3 - "$WORK/narr/provenance.json" "$WORK" <<'PY'
import json, sys
prov = json.load(open(sys.argv[1]))
silent = json.loads(json.dumps(prov))
silent["fonts"][0]["substituted"] = False
bare = json.loads(json.dumps(prov))
bare["fonts"][0]["fallback_chain"] = []
bare["fonts"][0]["skipped"] = []
json.dump(silent, open(f"{sys.argv[2]}/prov-silent.json", "w"))
json.dump(bare, open(f"{sys.argv[2]}/prov-bare.json", "w"))
PY
then
  ok=1
  python3 "$RENDER" check-provenance --provenance "$WORK/narr/provenance.json" --composition "$NARR" \
    --plan "$WORK/narr/target-plan.json" --out-dir "$WORK/narr" > /dev/null || ok=0
  for variant in silent bare; do
    rc=0
    python3 "$RENDER" check-provenance --provenance "$WORK/prov-$variant.json" > "$WORK/prov-$variant.out" || rc=$?
    [ "$rc" -eq 1 ] && python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert "silent-substitution" in {f["code"] for f in e["data"]["findings"]}' "$WORK/prov-$variant.out" || ok=0
  done
  if [ "$ok" -eq 1 ]; then pass "drnd-24-no-silent-substitution"; else fail "drnd-24-no-silent-substitution"; fi
else fail "drnd-24-no-silent-substitution"; fi

# drnd-25: re-rendering the captured plan's inputs reproduces it; the comparator ignores only the
# declared volatile fields and fails a moved box, a resized frame and a changed string.
if python3 "$RENDER" compare --expected "$CAPTURED" --actual "$WORK/narr/target-plan.json" > /dev/null &&
   python3 - "$CAPTURED" "$WORK" <<'PY'
import json, sys
plan = json.load(open(sys.argv[1]))
work = sys.argv[2]
def variant(name, change):
    copy = json.loads(json.dumps(plan))
    change(copy)
    json.dump(copy, open(f"{work}/plan-{name}.json", "w"))
variant("timestamps", lambda p: p.update(generated_at="2030-01-01T00:00:00Z", run_id="another"))
variant("moved", lambda p: p["units"][1]["slots"][0]["box"].update(y=p["units"][1]["slots"][0]["box"]["y"] + 5))
variant("resized", lambda p: p["units"][2]["frame"].update(height=p["units"][2]["frame"]["height"] + 12))
variant("string", lambda p: p["units"][0]["slots"][0]["content"][0].update(digest="sha256:" + "0" * 64))
PY
then
  ok=1
  python3 "$RENDER" compare --expected "$CAPTURED" --actual "$WORK/plan-timestamps.json" > /dev/null || ok=0
  for variant in moved resized string; do
    rc=0
    python3 "$RENDER" compare --expected "$CAPTURED" --actual "$WORK/plan-$variant.json" > "$WORK/cmp-$variant.out" || rc=$?
    [ "$rc" -eq 1 ] && python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "plan-drift"' "$WORK/cmp-$variant.out" || ok=0
  done
  if [ "$ok" -eq 1 ]; then pass "drnd-25-rerender-comparator"; else fail "drnd-25-rerender-comparator"; fi
else fail "drnd-25-rerender-comparator"; fi

# drnd-26: provenance records the runtime pin, the design-system version and the composition's own
# content fingerprint, and its output digests match the files beside it.
if python3 - "$WORK/costs/provenance.json" "$COSTS" "$PLUGIN_ROOT/runtime/package.json" <<'PY'
import json, re, sys
prov, comp, manifest = (json.load(open(p)) for p in sys.argv[1:])
assert prov["content_fingerprint"] == comp["normalized_brief_ref"]["content_fingerprint"]
assert prov["design_system"] == comp["design_system"] and prov["design_system"]["version"]
assert prov["runtime"]["dependencies"] == manifest["dependencies"]
assert all(re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", v) for v in prov["runtime"]["dependencies"].values())
assert re.fullmatch(r"sha256:[0-9a-f]{64}", prov["runtime"]["lock_sha256"])
PY
then
  if python3 "$RENDER" check-provenance --provenance "$WORK/costs/provenance.json" --composition "$COSTS" \
       --plan "$WORK/costs/target-plan.json" --out-dir "$WORK/costs" > /dev/null
  then pass "drnd-26-provenance-pins"; else fail "drnd-26-provenance-pins"; fi
else fail "drnd-26-provenance-pins"; fi

# rejects <id> <code> <composition> [theme]: the render fails with <code> and writes no HTML.
rejects() {
  local id="$1" code="$2" comp="$3" theme="${4:-$THEME}" rc=0
  python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$comp" --theme "$theme" \
    --out "$WORK/$id-out" > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  if [ "$rc" -eq 1 ] && [ ! -s "$WORK/$id.err" ] && [ ! -e "$WORK/$id-out" ] &&
     python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert e["success"] is False and e["data"]["code"] == sys.argv[2], e' "$WORK/$id.out" "$code"
  then pass "$id"; else fail "$id"; fi
}
python3 - "$NARR" "$WORK" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1]))
dangling = json.loads(json.dumps(comp))
dangling["units"][1]["bindings"][0]["record_ref"] = "slide-99"
geometry = json.loads(json.dumps(comp))
geometry["units"][0]["width"] = 960
json.dump(dangling, open(f"{sys.argv[2]}/comp-dangling.json", "w"))
json.dump(geometry, open(f"{sys.argv[2]}/comp-geometry.json", "w"))
PY
rejects "drnd-27-invalid-composition-dangling" dangling-reference "$WORK/comp-dangling.json"
rejects "drnd-28-invalid-composition-geometry" target-geometry "$WORK/comp-geometry.json"
mkdir -p "$WORK/other-theme" "$WORK/thin"
cp -R "$THEME" "$WORK/other-theme/boardroom"
cp -R "$THEME" "$WORK/thin/cogni-work"
python3 - "$WORK/thin/cogni-work/tokens/colors.json" <<'PY'
import json, sys
tokens = json.load(open(sys.argv[1]))
del tokens["accent"]
json.dump(tokens, open(sys.argv[1], "w"))
PY
rejects "drnd-29-invalid-theme-slug" invalid-theme "$NARR" "$WORK/other-theme/boardroom"
rejects "drnd-30-invalid-theme-token" invalid-theme "$NARR" "$WORK/thin/cogni-work"

# drnd-31: the PPTX target belongs to its sibling renderer; this one refuses it.
rc=0
python3 "$RENDER" render --target pptx --brief "$NBRIEF" --composition "$NARR" --theme "$THEME" --out "$WORK/pptx-out" \
  > "$WORK/pptx.out" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -e "$WORK/pptx-out" ] &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "unsupported-target"' "$WORK/pptx.out"
then pass "drnd-31-unsupported-target"; else fail "drnd-31-unsupported-target"; fi

# drnd-32: the validator grades the captured plan@2, routes a plan@2 chain to the same check, and
# rejects a plan that carries copy or leaves the composition's order.
python3 - "$NBRIEF" "$NARR" "$CAPTURED" "$WORK" <<'PY'
import json, sys
brief, comp, plan, work = sys.argv[1:]
plan = json.load(open(plan))
json.dump({"normalized_brief": json.load(open(brief)), "semantic_composition": json.load(open(comp)),
           "target_resolved_plan": plan}, open(f"{work}/chain-v2.json", "w"))
copied = json.loads(json.dumps(plan))
copied["units"][0]["slots"][0]["text"] = "The Maintenance Budget That Buys Downtime"
swapped = json.loads(json.dumps(plan))
swapped["units"][0], swapped["units"][1] = swapped["units"][1], swapped["units"][0]
json.dump(copied, open(f"{work}/plan-copied.json", "w"))
json.dump(swapped, open(f"{work}/plan-swapped.json", "w"))
PY
ok=1
python3 "$VALIDATOR" check-plan --brief "$NBRIEF" --composition "$NARR" --plan "$CAPTURED" > /dev/null || ok=0
python3 "$VALIDATOR" validate --input "$WORK/chain-v2.json" > "$WORK/chain-v2.out" || ok=0
python3 -c 'import json, sys; d = json.load(open(sys.argv[1]))["data"]; assert d["valid"] and d["artifacts"][2]["artifact_version"] == "2"' "$WORK/chain-v2.out" || ok=0
for pair in copied:unexpected-field swapped:reordered-unit; do
  variant="${pair%%:*}" code="${pair#*:}" rc=0
  python3 "$VALIDATOR" check-plan --brief "$NBRIEF" --composition "$NARR" --plan "$WORK/plan-$variant.json" \
    > "$WORK/plan-$variant.out" || rc=$?
  [ "$rc" -eq 1 ] && python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == sys.argv[2]' "$WORK/plan-$variant.out" "$code" || ok=0
done
if [ "$ok" -eq 1 ]; then pass "drnd-32-check-plan"; else fail "drnd-32-check-plan"; fi

# drnd-33: the output check behind drnd-09 is load-bearing — suppressing any one output turns it red.
ok=1
for name in target-plan.json index.html provenance.json; do
  rm -rf "$WORK/suppressed"
  cp -R "$WORK/costs" "$WORK/suppressed"
  rm "$WORK/suppressed/$name"
  python3 - "$WORK/costs.json" "$WORK/costs" "$WORK/suppressed" "$WORK/suppressed.json" <<'PY'
import sys
src, old, new, dst = sys.argv[1:]
open(dst, "w", encoding="utf-8").write(open(src, encoding="utf-8").read().replace(old, new))
PY
  python3 "$WORK/outputs.py" "$WORK/suppressed.json" && ok=0
done
if [ "$ok" -eq 1 ]; then pass "drnd-33-missing-output-detected"; else fail "drnd-33-missing-output-detected"; fi

# drnd-34 / drnd-35 need the pinned browser runtime. Without it they say so and never pass.
runtime_case() {  # runtime_case <id> — prints SKIP and returns 1 when the runtime is not provisioned
  local id="$1" rc=0
  python3 "$RENDER" measure --html "$WORK/narr/index.html" --out "$WORK/$id-probe.json" > "$WORK/$id-probe.out" || rc=$?
  if [ "$rc" -eq 2 ] && python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "runtime-missing"' "$WORK/$id-probe.out" 2>/dev/null; then
    skip "$id pinned browser runtime not provisioned at $PLUGIN_ROOT/runtime (bash cogni-publishing/runtime/provision.sh)"
    return 1
  fi
  return 0
}

# drnd-34: an isolated, offline browser load of every fixture page requests nothing and clips no copy.
if runtime_case "drnd-34-browser-isolated-load"; then
  ok=1
  for out in narr costs de; do
    python3 "$RENDER" measure --html "$WORK/$out/index.html" --out "$WORK/$out-measure.json" > /dev/null || ok=0
    python3 -c 'import json, sys; r = json.load(open(sys.argv[1])); assert r["requests"] == {"blocked": [], "failed": []} and r["clipped"] == [] and r["platform_fonts"], r["requests"]' "$WORK/$out-measure.json" || ok=0
  done
  if [ "$ok" -eq 1 ]; then pass "drnd-34-browser-isolated-load"; else fail "drnd-34-browser-isolated-load"; fi
fi

# drnd-35: under the same pinned runtime, a re-render measures the same DOM geometry, and a measured
# render records the runtime it used.
if runtime_case "drnd-35-browser-geometry-rerender"; then
  ok=1
  render "$WORK/narr-again" "$NBRIEF" "$NARR" --measure || ok=0
  python3 "$RENDER" measure --html "$WORK/narr/index.html" --out "$WORK/narr-geometry.json" > /dev/null || ok=0
  python3 "$RENDER" compare --expected "$WORK/narr-geometry.json" --actual "$WORK/narr-again/browser-report.json" > /dev/null || ok=0
  python3 -c 'import json, sys; p = json.load(open(sys.argv[1])); assert p["runtime"]["used"] is True and p["measurement"]["requests_blocked"] == []' "$WORK/narr-again/provenance.json" || ok=0
  if [ "$ok" -eq 1 ]; then pass "drnd-35-browser-geometry-rerender"; else fail "drnd-35-browser-geometry-rerender"; fi
fi

# drnd-36: the render path compiles on the oldest Python 3.9-3.11 interpreter on this host, so newer
# syntax cannot raise the Python floor unseen. Compilation is in memory, so no __pycache__ lands in
# the tree. A host with no such interpreter — CI's runner ships only 3.12+ — prints SKIP, never PASS.
floor_py=""
floor_ver=999
for candidate in python3.9 python3.10 python3.11 /usr/bin/python3; do
  bin="$(command -v "$candidate" 2>/dev/null)" || continue
  ver="$("$bin" -c 'import sys; print("%d%02d" % sys.version_info[:2])' 2>/dev/null)" || continue
  case "$ver" in ''|*[!0-9]*) continue ;; esac
  if [ "$ver" -ge 309 ] && [ "$ver" -lt 312 ] && [ "$ver" -lt "$floor_ver" ]; then
    floor_py="$bin"
    floor_ver="$ver"
  fi
done
if [ -z "$floor_py" ]; then
  skip "drnd-36-python-floor-compiles no Python 3.9-3.11 interpreter on this host"
elif "$floor_py" - "$PLUGIN_ROOT/scripts" > /dev/null 2>&1 <<'PY'
import os
import sys

for name in ("design-render.py", "render_core.py", "html_adapter.py", "render_checks.py",
             "validate-publishing.py", "generate-tokens-css.py"):
    path = os.path.join(sys.argv[1], name)
    with open(path, encoding="utf-8") as handle:
        compile(handle.read(), path, "exec")
PY
then pass "drnd-36-python-floor-compiles"; else fail "drnd-36-python-floor-compiles"; fi

# recompose <python-edit> <prefix> [direct brief] [composition]: apply one edit to a copy of a direct
# brief (by default the costs one), normalize it, and recompose its composition from a stripped draft,
# so every digest matches the edited brief. Writes $WORK/<prefix>-brief.json and
# $WORK/<prefix>-comp.json; returns non-zero when either step fails.
recompose() {
  python3 - "${3:-$FIXTURES/direct-costs-v1.json}" "${4:-$COSTS}" "$WORK/$2" "$1" <<'PY' || return 1
import json, sys
brief_path, comp_path, prefix, edit = sys.argv[1:]
brief = json.load(open(brief_path, encoding="utf-8"))
def section(sid):
    return next(s for s in brief["sections"] if s["id"] == sid)
def item(did):
    return next(i for s in brief["sections"] for i in s.get("data", []) if i["id"] == did)
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
  python3 "$VALIDATOR" normalize --kind direct --input "$WORK/$2-direct.json" > "$WORK/$2-normalized.json" || return 1
  python3 -c 'import json, sys; json.dump(json.load(open(sys.argv[1]))["data"], open(sys.argv[2], "w"), ensure_ascii=False)' \
    "$WORK/$2-normalized.json" "$WORK/$2-brief.json" || return 1
  python3 "$VALIDATOR" compose --brief "$WORK/$2-brief.json" --composition "$WORK/$2-draft.json" > "$WORK/$2-composed.json" || return 1
  python3 -c 'import json, sys; json.dump(json.load(open(sys.argv[1]))["data"], open(sys.argv[2], "w"), ensure_ascii=False)' \
    "$WORK/$2-composed.json" "$WORK/$2-comp.json"
}

# drnd-37: prose that names a path, a tool or a scheme-like word is copy, not a reference. A brief whose
# frozen copy says "Risk profile:", "cogni-workspace", "/tmp/" and "node_modules" renders with all three
# outputs, shows that copy exactly and passes check-html; a scanned attribute saying "Risk profile:"
# passes too, so the file: scheme test is anchored rather than skipped.
PROSE='Risk profile: high. Built with cogni-workspace; logs sit under /tmp/ and node_modules stays out.'
if recompose "section(\"answer\")[\"body\"] = \"$PROSE\"" prose &&
   render "$WORK/prose" "$WORK/prose-brief.json" "$WORK/prose-comp.json" &&
   python3 "$WORK/outputs.py" "$WORK/prose.json" &&
   python3 - "$WORK" "$PROSE" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from extract import extract, frozen_copy_problems
work, prose = sys.argv[1:]
assert not frozen_copy_problems(f"{work}/prose/index.html", f"{work}/prose-brief.json", f"{work}/prose-comp.json")
assert {text for kind, key, text in extract(f"{work}/prose/index.html").found if kind == "copy"} >= {prose}
page = open(f"{work}/prose/index.html", encoding="utf-8").read()
described = page.replace("<meta charset=\"utf-8\">", "<meta charset=\"utf-8\">\n<meta name=\"description\" content=\"Risk profile: low\">", 1)
assert described != page
open(f"{work}/prose-described.html", "w", encoding="utf-8").write(described)
PY
then
  if green "$WORK/prose/index.html" "$WORK/prose-brief.json" "$WORK/prose-comp.json" &&
     green "$WORK/prose-described.html" "$WORK/prose-brief.json" "$WORK/prose-comp.json"
  then pass "drnd-37-prose-paths-render"; else fail "drnd-37-prose-paths-render"; fi
else fail "drnd-37-prose-paths-render"; fi

# drnd-38: the scoped scan still refuses a real local reference on each surface a page can load from —
# a file: URL in an attribute, an absolute path in <style> text and a node_modules/ path in a style attribute.
ok=1
doctored drnd-38-scheme "$WORK/costs/index.html" "$CBRIEF" "$COSTS" assets \
  'page.replace("<meta charset=\"utf-8\">", "<meta charset=\"utf-8\">\n<meta http-equiv=\"refresh\" content=\"0; url=file:///srv/report.html\">", 1)' || ok=0
doctored drnd-38-path "$WORK/costs/index.html" "$CBRIEF" "$COSTS" assets \
  'page.replace("<style>\n", "<style>\n@font-face { src: local(\"/Users/alice/Library/Fonts/Brand.ttf\"); }\n", 1)' || ok=0
doctored drnd-38-dir "$WORK/costs/index.html" "$CBRIEF" "$COSTS" assets \
  'page.replace("style=\"min-height: ", "style=\"behavior: node_modules/fix/fix.htc; min-height: ", 1)' || ok=0
if [ "$ok" -eq 1 ]; then pass "drnd-38-local-reference-refused"; else fail "drnd-38-local-reference-refused"; fi

# drnd-39: a negative value is drawn from the shared zero baseline in the opposite direction, keeping
# its literal label; a page that draws it rightward from the baseline is rejected naming check `chart`.
if recompose 'item("wage-premium")["value"] = -2.1' negative &&
   render "$WORK/negative" "$WORK/negative-brief.json" "$WORK/negative-comp.json" &&
   python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from extract import frozen_copy_problems
work = sys.argv[1]
assert not frozen_copy_problems(f"{work}/negative/index.html", f"{work}/negative-brief.json", f"{work}/negative-comp.json")
page = open(f"{work}/negative/index.html", encoding="utf-8").read()
marks = {ref: (float(x), float(width)) for ref, x, width in
         re.findall(r'<rect class="mark" data-ref="([^"]+)" x="([^"]+)" y="[^"]+" width="([^"]+)"', page)}
assert len(marks) == 4, marks
starts = {round(x, 2) for ref, (x, _) in marks.items() if ref != "wage-premium"}
assert len(starts) == 1, starts
baseline = starts.pop()
x, width = marks["wage-premium"]
assert x < baseline and abs(x + width - baseline) <= 0.05, (x, width, baseline)
assert ">-2.1 million euros<" in page
PY
then
  if doctored drnd-39-neg "$WORK/negative/index.html" "$WORK/negative-brief.json" "$WORK/negative-comp.json" chart \
       're.sub(r"(<rect class=\"mark\" data-ref=\"wage-premium\" x=\")[^\"]*", lambda m: m.group(1) + re.search(r"data-ref=\"downtime\" x=\"([^\"]*)\"", page).group(1), page, count=1)'
  then pass "drnd-39-chart-negative-baseline"; else fail "drnd-39-chart-negative-baseline"; fi
else fail "drnd-39-chart-negative-baseline"; fi

# drnd-40..42: SVG figure labels wrap to the plan's own line estimate. The German brief is recomposed with
# a long entity label, an entity label carrying a paragraph break and &, < and ", and a long non-ASCII
# chart label beside three short ones, then rendered with the fixture theme and with a copy whose
# size-body is 24px. At 24px an entity label of the pattern's 90-character maximum wraps at the node text
# width but would not at the full slot width, so the case also proves which width the plan measures at.
WRAP_EDIT='section("bausteine")["body"] = "Anlagenzustand, Wartungshistorie und Störungsmeldungen aller Linien in einer Sicht"
section("bausteine-2")["body"] = "Prozess nach Maß: \"erst messen\" & <dann> handeln\nCompliance by Design"
item("versicherung")["label"] = "Versicherungszuschläge für Betriebsunterbrechung und erweiterte Maschinenbruchdeckung"'
theme_variant "$WORK/big" "24px" size-body
wrap_ok=0
if recompose "$WRAP_EDIT" wrap "$FIXTURES/render/direct-de-edge-v1.json" "$GERMAN" &&
   render "$WORK/wrap" "$WORK/wrap-brief.json" "$WORK/wrap-comp.json" --language de &&
   python3 "$RENDER" render --target html --brief "$WORK/wrap-brief.json" --composition "$WORK/wrap-comp.json" \
     --theme "$WORK/big/cogni-work" --out "$WORK/wrap-big" --language de > "$WORK/wrap-big.json" 2> "$WORK/wrap-big.err"
then wrap_ok=1; fi

# drnd-40: the drawn figures have the plan's geometry, and the plan has the geometry of the widths the
# figures draw at. Every expected number is derived here from the theme tokens, the plan's type_role and
# the font-fallbacks advance, by the documented rule — never read back from the page to predict the page.
if [ "$wrap_ok" -eq 1 ] && python3 - "$WORK" "$PLUGIN_ROOT/references/font-fallbacks-v1.json" "$THEME" "$WORK/big/cogni-work" <<'PY'
import json, math, re, sys
from html.parser import HTMLParser
sys.path.insert(0, sys.argv[1])
from extract import expected, load

work, fallbacks, base_theme, big_theme = sys.argv[1:]
ROLE_TOKENS = {"type.display": ("size-display", "line-height-display"), "type.heading": ("size-h2", "line-height-h2"),
               "type.lead": ("size-h3", "line-height-h3"), "type.body": ("size-body", "line-height-body"),
               "type.caption": ("size-small", "line-height-small")}
GUTTER, LABEL_SHARE, LABEL_GAP, ROW_MIN = 260.0, 0.4, 8.0, 28.0
chains = json.load(open(fallbacks))


class Tree(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = {"tag": "#", "attrs": {}, "kids": [], "text": ""}
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = {"tag": tag, "attrs": dict(attrs), "kids": [], "text": ""}
        self.stack[-1]["kids"].append(node)
        if tag not in ("meta", "link", "br", "img", "input", "hr"):
            self.stack.append(node)

    def handle_endtag(self, tag):
        if len(self.stack) > 1 and self.stack[-1]["tag"] == tag:
            self.stack.pop()

    def handle_data(self, data):
        self.stack[-1]["text"] += data


def walk(node):
    for kid in node["kids"]:
        yield kid
        yield from walk(kid)


def px(value):
    return float(str(value).strip().replace("px", ""))


def near(a, b, tolerance=0.01):
    return abs(float(a) - float(b)) <= tolerance


def per_line(width, size, advance):
    return max(1, int(width // (size * advance)))


def estimate(text, width, size, advance):
    n = per_line(width, size, advance)
    return sum(max(1, math.ceil(len(part) / n)) for part in text.split("\n"))


def fits(line, width, size, advance):
    return len(line.rstrip("\n")) * size * advance <= width + 1e-6


brief, comp = load(f"{work}/wrap-brief.json"), load(f"{work}/wrap-comp.json")
copy, _ = expected(brief, comp)
units = {unit["id"]: unit for unit in json.load(open(f"{work}/wrap-comp.json", encoding="utf-8"))["units"]}
long_entity = copy["bausteine#body"]
for out, theme in (("wrap", base_theme), ("wrap-big", big_theme)):
    typo = json.load(open(f"{theme}/tokens/typography.json"))
    spacing = {k: px(v) for k, v in json.load(open(f"{theme}/tokens/spacing.json")).items()}
    face = json.load(open(f"{work}/{out}/provenance.json"))["layout_face"]
    advance = (chains.get("bundled_faces", {}).get(face) or chains["generic_families"][face])["advance_em"]
    plan = json.load(open(f"{work}/{out}/target-plan.json"))
    slots = {(u["composition_unit_ref"], s["slot"]): s for u in plan["units"] for s in u["slots"]}
    tree = Tree()
    tree.feed(open(f"{work}/{out}/index.html", encoding="utf-8").read())
    sections = {n["attrs"].get("data-unit"): n for n in walk(tree.root) if n["tag"] == "section"}

    # The conceptual system.
    slot = slots[("u-bausteine", "entities")]
    size, ratio = px(typo[ROLE_TOKENS[slot["type_role"]][0]]), float(typo[ROLE_TOKENS[slot["type_role"]][1]])
    line, pad, gap = size * ratio, spacing["4"], spacing["5"]
    box = slot["box"]
    node_w = box["width"] - GUTTER
    text_w = node_w - 2 * pad
    labels = [copy[f"{e['record_ref']}#{e['field']}"] for e in units["u-bausteine"]["entities"]]
    counts = [estimate(label, text_w, size, advance) for label in labels]
    heights = [n * line + 2 * pad for n in counts]
    assert slot["lines"] == sum(counts), (out, slot["lines"], counts)
    assert near(box["height"], sum(heights) + (len(heights) - 1) * gap, 0.5), (out, box, heights)
    assert max(counts) >= 2, (out, "no entity label wraps", counts)
    if out == "wrap-big":
        assert estimate(long_entity, text_w, size, advance) >= 2, "the long entity label does not wrap at 24px"
        assert estimate(long_entity, box["width"] - 2 * pad, size, advance) == 1, "the full width would wrap too"
    svg = next(n for n in walk(sections["u-bausteine"]) if n["tag"] == "svg")
    assert near(svg["attrs"]["height"], box["height"], 0.5), (out, svg["attrs"]["height"], box["height"])
    nodes = [n for n in walk(svg) if n["tag"] == "g" and "node" in n["attrs"].get("class", "").split()]
    assert len(nodes) == len(labels), (out, len(nodes))
    top, centres = 0.0, {}
    for node, entity, count, height in zip(nodes, units["u-bausteine"]["entities"], counts, heights):
        rect = next(n for n in walk(node) if n["tag"] == "rect")
        label = next(n for n in walk(node) if n["tag"] == "text")
        spans = [n for n in walk(label) if n["tag"] == "tspan"]
        y = float(rect["attrs"]["y"])
        assert near(y, top) and near(rect["attrs"]["width"], node_w) and near(rect["attrs"]["height"], height), \
            (out, entity["id"], rect["attrs"], top, node_w, height)
        assert len(spans) == count, (out, entity["id"], len(spans), count)
        for index, span in enumerate(spans):
            assert near(span["attrs"]["y"], y + pad + size + index * line), (out, entity["id"], index, span["attrs"])
            assert fits(span["text"], text_w, size, advance), (out, entity["id"], span["text"])
        assert float(spans[-1]["attrs"]["y"]) <= y + height, (out, entity["id"], "last line leaves its node")
        centres[entity["id"]] = y + height / 2
        top += height + gap
    for edge in (n for n in walk(svg) if n["tag"] == "g" and "edge" in n["attrs"].get("class", "").split()):
        path = next(n for n in walk(edge) if n["tag"] == "path")
        x0, y0, bend, _, _, y1, x1, y2 = (float(v) for v in re.findall(r"-?[0-9.]+", path["attrs"]["d"])[:8])
        assert near(x0, node_w) and near(x1, node_w) and bend > node_w, (out, path["attrs"]["d"])
        assert near(y0, centres[edge["attrs"]["data-from"]]) and near(y2, centres[edge["attrs"]["data-to"]]), \
            (out, path["attrs"]["d"], centres)

    # The chart.
    slot = slots[("u-komponenten", "series")]
    size, ratio = px(typo[ROLE_TOKENS[slot["type_role"]][0]]), float(typo[ROLE_TOKENS[slot["type_role"]][1]])
    line, item_gap = size * ratio, spacing["3"]
    box = slot["box"]
    column = box["width"] * LABEL_SHARE
    label_w = column - LABEL_GAP
    refs = [point["data_ref"] for point in units["u-komponenten"]["data_bindings"]]
    counts = [estimate(copy[f"data:{ref}#label"], label_w, size, advance) for ref in refs]
    rows = [max(n * line, ROW_MIN) + item_gap for n in counts]
    assert max(counts) >= 2 and min(counts) == 1, (out, "the chart does not mix wrapped and one-line labels", counts)
    assert slot["lines"] == sum(counts) and near(box["height"], sum(rows), 0.5), (out, slot, counts, rows)
    svg = next(n for n in walk(sections["u-komponenten"]) if n["tag"] == "svg")
    assert near(svg["attrs"]["height"], box["height"], 0.5), (out, svg["attrs"]["height"], box["height"])
    points = [n for n in walk(svg) if n["tag"] == "g" and "point" in n["attrs"].get("class", "").split()]
    assert [p["attrs"]["data-ref"] for p in points] == refs, (out, "points")
    top = 0.0
    for point, ref, count, row in zip(points, refs, counts, rows):
        label = next(n for n in walk(point) if n["attrs"].get("data-copy") == f"data:{ref}#label")
        spans = [n for n in walk(label) if n["tag"] == "tspan"]
        mark = next(n for n in walk(point) if n["tag"] == "rect")
        value = next(n for n in walk(point) if "data-value" in n["attrs"])
        assert len(spans) == count, (out, ref, len(spans), count)
        assert all(fits(span["text"], label_w, size, advance) for span in spans), (out, ref, "a line leaves the column")
        assert all(top < float(span["attrs"]["y"]) <= top + row for span in spans), (out, ref, "a line leaves its row")
        assert float(mark["attrs"]["x"]) >= column - 0.01, (out, ref, "the mark starts inside the label column")
        mark_y, mark_h = float(mark["attrs"]["y"]), float(mark["attrs"]["height"])
        assert top <= mark_y and mark_y + mark_h <= top + row + 0.01, (out, ref, "the mark leaves its row")
        assert top < float(value["attrs"]["y"]) <= top + row, (out, ref, "the value label leaves its row")
        top += row
PY
then pass "drnd-40-wrapped-figure-geometry"; else fail "drnd-40-wrapped-figure-geometry"; fi

# drnd-41: the wrapped pages stay fidelity-clean. check-html with each theme finds nothing; the frozen-copy
# reader finds nothing omitted, changed or invented; the paragraph-break, &<" and non-ASCII labels read
# back exactly from their SVG elements; no whitespace sits between two lines and no line has a copy key.
if [ "$wrap_ok" -eq 1 ] &&
   green "$WORK/wrap/index.html" "$WORK/wrap-brief.json" "$WORK/wrap-comp.json" &&
   python3 "$RENDER" check-html --brief "$WORK/wrap-brief.json" --composition "$WORK/wrap-comp.json" \
     --html "$WORK/wrap-big/index.html" --theme "$WORK/big/cogni-work" > /dev/null &&
   python3 - "$WORK" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[1])
from extract import expected, extract, frozen_copy_problems, load
work = sys.argv[1]
copy, _ = expected(load(f"{work}/wrap-brief.json"), load(f"{work}/wrap-comp.json"))
edge = {"bausteine#body": copy["bausteine#body"], "bausteine-2#body": copy["bausteine-2#body"],
        "data:versicherung#label": copy["data:versicherung#label"]}
assert "\n" in edge["bausteine-2#body"] and all(c in edge["bausteine-2#body"] for c in '&<"')
assert any(ord(c) > 127 for c in edge["data:versicherung#label"]) and any(ord(c) > 127 for c in edge["bausteine#body"])
for out in ("wrap", "wrap-big"):
    assert not frozen_copy_problems(f"{work}/{out}/index.html", f"{work}/wrap-brief.json", f"{work}/wrap-comp.json"), out
    found = {}
    for kind, key, text in extract(f"{work}/{out}/index.html").found:
        found.setdefault(key, []).append(text)
    for key, want in edge.items():
        assert found.get(key) and all(text == want for text in found[key]), (out, key, found.get(key))
    page = open(f"{work}/{out}/index.html", encoding="utf-8").read()
    assert "<tspan" in page and not re.search(r"</tspan>\s+<tspan", page), out
    assert not re.search(r"<tspan[^>]*data-copy", page), out
PY
then pass "drnd-41-wrapped-figure-fidelity"; else fail "drnd-41-wrapped-figure-fidelity"; fi

# drnd-42: the core's line split is lossless and counts exactly what the line estimate counts — empty
# strings, paragraph breaks at either end, a paragraph of exactly one line and of one character more,
# escapable characters and non-ASCII text, across widths from one character per line upward.
if python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import render_core as core
corpus = ["", "\n", "a\n", "\nb", "\n\n", "x" * 13, "x" * 14, "Versicherungszuschläge für Betriebsunterbrechung",
          'Prozess nach Maß: "erst messen" & <dann> handeln\nCompliance by Design', "a  b\n\n  c ", "ä" * 40]
for width in (1, 7.8, 101.4, 109.2, 465.6, 892):
    for text in corpus:
        lines = core.wrap_lines(text, width, 15, 0.52)
        assert "".join(lines) == text, (width, text, lines)
        assert len(lines) == core.estimate_lines(text, width, 15, 0.52), (width, text, lines)
        per_line = core.chars_per_line(width, 15, 0.52)
        assert all(len(line.rstrip("\n")) <= per_line for line in lines), (width, text, lines)
PY
then pass "drnd-42-wrap-lines-lossless"; else fail "drnd-42-wrap-lines-lossless"; fi

printf '%s\n' "Design-render tests: $passes passed, $failures failed, $skips skipped"
[ "$failures" -eq 0 ]
