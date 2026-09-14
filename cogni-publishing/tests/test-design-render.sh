#!/usr/bin/env bash
# design-render suite for cogni-publishing: the HTML target over target-resolved-plan@2 — outputs,
# frozen copy, markup-as-text, pattern semantics, tokens, citations, portability, accessibility,
# font resolution, the re-render comparator, provenance, the runtime pin and the runtime boundary.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `drnd`; NN is an allocation
# counter, so never renumber an existing id — the mutation recipes below record four.
#
# Every expected string comes from the fixture inputs (the normalized brief and the composition),
# read by this suite's own html.parser extraction, never from a file the renderer produced. Every
# negative is derived in a scratch directory from a green render by one small edit; no tracked
# fixture is mutated. A case that needs an edited brief edits a copy of the direct brief and
# recomposes the composition from a stripped draft with `compose`, never by typing a digest. Three
# cases need the pinned browser runtime: without it they print a SKIP line naming the absent runtime
# and never PASS. drnd-36 compiles the render path under the oldest Python 3.9-3.11 interpreter on
# the host and prints SKIP when there is none. With COGNI_PUBLISHING_REQUIRE_PROVISIONED=1 in the
# environment each of those SKIP lines is a FAIL under the same id instead; the Plugin test suites CI
# job sets it after provisioning the runtime and a Python 3.9, so CI never passes with them skipped.
#
# Mutation recipes (run from the repository root; the harness is the installed managed-service
# cogni-service plugin, and --expr is evaluated by perl -0pi). The first makes copy text wrong and
# must fail drnd-10; the second makes the portability scan read copy text and must fail drnd-37; the
# third admits an @font-face whose bytes are not the face the theme ships and must fail drnd-50; the
# fourth admits the shipped bytes under a format label the theme does not ship them with and must also
# fail drnd-50:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/html_adapter.py --expr 's/return escape\(value, quote=True\)/return escape(value.upper(), quote=True)/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-10-frozen-copy
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_checks.py --expr 's/if node\.tag == "style":/if True:/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-37-prose-paths-render
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_checks.py --expr 's/if shipped_family != family:/if False:/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-50-embedded-face-negatives
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_checks.py --expr 's/if face is None or face\["format"\] != form or face\["mime"\] != mime:/if False:/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-50-embedded-face-negatives
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
RENDER="$PLUGIN_ROOT/scripts/design-render.py"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-publishing.py"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
THEME="$FIXTURES/render/themes/cogni-work"
FONT_THEME="$FIXTURES/render/font-theme/cogni-work"
FONT_FILE="$FONT_THEME/assets/fonts/Outfit-Regular.ttf"
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
own = {"render_core", "html_adapter", "render_checks", "pptx_adapter", "pptx_checks"}
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


for name in ("design-render.py", "render_core.py", "html_adapter.py", "render_checks.py", "pptx_adapter.py",
             "pptx_checks.py"):
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
             "scripts/render_checks.py", "scripts/pptx_adapter.py", "scripts/pptx_checks.py", "runtime/measure.mjs"):
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
             "scripts/render_checks.py", "scripts/pptx_adapter.py", "scripts/pptx_checks.py", "runtime/measure.mjs"):
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

# doctor <id> <html> <python-edit> [theme] — derive a page by one edit; check-html must fail naming <check>.
doctored() {
  local id="$1" source="$2" brief="$3" comp="$4" check="$5" edit="$6" theme="${7:-$THEME}" rc=0
  python3 - "$source" "$WORK/$id.html" "$edit" <<'PY'
import re, sys
src, dst, edit = sys.argv[1:]
page = open(src, encoding="utf-8").read()
new = eval(edit, {"re": re, "page": page})
assert new != page, "the edit changed nothing"
open(dst, "w", encoding="utf-8").write(new)
PY
  [ $? -eq 0 ] || return 1
  python3 "$RENDER" check-html --brief "$brief" --composition "$comp" --html "$WORK/$id.html" --theme "$theme" \
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

# drnd-31: a target no adapter here owns is refused before anything is read or written. The html and
# pptx targets are siblings behind this wrapper (test-design-render-pptx.sh grades the pptx one).
rc=0
python3 "$RENDER" render --target docx --brief "$NBRIEF" --composition "$NARR" --theme "$THEME" --out "$WORK/docx-out" \
  > "$WORK/docx.out" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -e "$WORK/docx-out" ] &&
   python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "unsupported-target"' "$WORK/docx.out"
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

# drnd-34 / drnd-35 need the pinned browser runtime and drnd-36 a Python 3.9-3.11 interpreter. Without
# them they say so and never pass; where COGNI_PUBLISHING_REQUIRE_PROVISIONED=1 declares them
# provisioned, as the Plugin test suites CI job does, the same line is a FAIL under the same id.
unprovisioned() {  # unprovisioned <id> <what is missing> — SKIP, or FAIL when provisioning is required
  if [ "${COGNI_PUBLISHING_REQUIRE_PROVISIONED:-}" = "1" ]; then
    fail "$1 $2 (required by COGNI_PUBLISHING_REQUIRE_PROVISIONED=1)"
  else
    skip "$1 $2"
  fi
}

runtime_case() {  # runtime_case <id> — reports the absent runtime and returns 1 when it is not provisioned
  local id="$1" rc=0
  python3 "$RENDER" measure --html "$WORK/narr/index.html" --out "$WORK/$id-probe.json" > "$WORK/$id-probe.out" || rc=$?
  if [ "$rc" -eq 2 ] && python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "runtime-missing"' "$WORK/$id-probe.out" 2>/dev/null; then
    unprovisioned "$id" "pinned browser runtime not provisioned at $PLUGIN_ROOT/runtime (bash cogni-publishing/runtime/provision.sh)"
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
# the tree. A host with no such interpreter prints SKIP, never PASS, or FAIL when provisioning is
# required; CI provisions a Python 3.9 as python3.9 beside its newer python3.
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
  unprovisioned "drnd-36-python-floor-compiles" "no Python 3.9-3.11 interpreter on this host"
elif "$floor_py" - "$PLUGIN_ROOT/scripts" > /dev/null 2>&1 <<'PY'
import os
import sys

for name in ("design-render.py", "render_core.py", "html_adapter.py", "render_checks.py", "pptx_adapter.py",
             "pptx_checks.py", "validate-publishing.py", "generate-tokens-css.py"):
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

# drnd-40..43: SVG figure labels wrap by the word-aware rule to the plan's own line estimate. The German
# brief is recomposed with a long entity label, an entity label carrying a paragraph break and &, < and ",
# and two long non-ASCII chart labels beside two short ones, then rendered with the fixture theme and with
# a copy whose size-body is 24px. At 24px an entity label of the pattern's 90-character maximum wraps at the
# node text width but would not at the full slot width, so the case also proves which width the plan
# measures at; and the second long chart label takes more lines by words than by characters, so the
# geometry case tells the word-aware rule from a character cut.
WRAP_EDIT='section("bausteine")["body"] = "Anlagenzustand, Wartungshistorie und Störungsmeldungen aller Linien in einer Sicht"
section("bausteine-2")["body"] = "Prozess nach Maß: \"erst messen\" & <dann> handeln\nCompliance by Design"
item("versicherung")["label"] = "Versicherungszuschläge für Betriebsunterbrechung und erweiterte Maschinenbruchdeckung"
item("nachruestung")["label"] = "Nachrüstung für Compliance und Arbeitssicherheit an allen Fertigungslinien"'
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
import itertools, json, math, re, sys
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


# The documented rule, restated here: a break space is any whitespace but a no-break space; a paragraph is
# filled word by word and breaks before the first word that would not fit; the break spaces a line ends with
# do not count toward its fit; only a word longer than a line is cut, starting a fresh line.
NO_BREAK = "\u00a0\u2007\u202f"


def breaks(char):
    return char.isspace() and char not in NO_BREAK


def words(part):
    runs = []
    for is_space, group in itertools.groupby(part, breaks):
        run = "".join(group)
        if is_space and runs:
            runs[-1][1] += run
        else:
            runs.append(["", run] if is_space else [run, ""])
    return runs


def estimate(text, width, size, advance):
    n = per_line(width, size, advance)
    total = 0
    for part in text.split("\n"):
        count, line = 1, ""
        for word, space in words(part):
            if line and len(line + word) > n:
                count, line = count + 1, ""
            if len(word) > n:
                pieces = math.ceil(len(word) / n)
                count, word = count + pieces - 1, word[(pieces - 1) * n:]
            line += word + space
        total += count
    return total


def char_estimate(text, width, size, advance):
    n = per_line(width, size, advance)
    return sum(max(1, math.ceil(len(part) / n)) for part in text.split("\n"))


def fits(line, width, size, advance):
    body = line.rstrip("\n")
    while body and breaks(body[-1]):
        body = body[:-1]
    return len(body) * size * advance <= width + 1e-6


brief, comp = load(f"{work}/wrap-brief.json"), load(f"{work}/wrap-comp.json")
copy, _ = expected(brief, comp)
units = {unit["id"]: unit for unit in json.load(open(f"{work}/wrap-comp.json", encoding="utf-8"))["units"]}
long_entity = copy["bausteine#body"]
wider = []  # figure labels that take more lines by words than by characters
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
    wider += [(out, label) for label, n in zip(labels, counts) if n > char_estimate(label, text_w, size, advance)]
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
    wider += [(out, ref) for ref, n in zip(refs, counts)
              if n > char_estimate(copy[f"data:{ref}#label"], label_w, size, advance)]
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
# A plan that still cut figure labels by characters would draw fewer lines for these labels than counted here.
assert wider, "no figure label takes more lines by words than by characters, so the case cannot tell the rules apart"
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

# drnd-42: the core's line split is lossless and counts exactly what the figure-label estimate counts —
# empty strings, paragraph breaks at either end, a paragraph of exactly one line and of one character more,
# escapable characters, non-ASCII text, whitespace runs at either end, tabs, no-break spaces and an overlong
# word between words, across widths from one character per line upward. Every line fits its width once the
# break spaces it ends with are set aside, every paragraph takes at least one line, and a paragraph break
# ends exactly the last line of its paragraph.
if python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import render_core as core
NO_BREAK = "\u00a0\u2007\u202f"


def fit(line):
    body = line.rstrip("\n")
    while body and body[-1].isspace() and body[-1] not in NO_BREAK:
        body = body[:-1]
    return len(body)


corpus = ["", "\n", "a\n", "\nb", "\n\n", "x" * 13, "x" * 14, "Versicherungszuschläge für Betriebsunterbrechung",
          'Prozess nach Maß: "erst messen" & <dann> handeln\nCompliance by Design', "a  b\n\n  c ", "ä" * 40,
          "10\u00a0% mehr Umsatz", "ab 10\u00a0%", "a \u202f b", "   führend und nachlaufend   ",
          "Tab\t\tgetrennt\tund  Leerzeichen", "Nachrüstung für Compliance und Arbeitssicherheit an allen Fertigungslinien",
          "kurz Donaudampfschifffahrtsgesellschaft lang\n  eingerückt"]
extra = {n: n * 15 * 0.52 + 1 for n in (3, 5, 6)}
assert all(core.chars_per_line(width, 15, 0.52) == n for n, width in extra.items()), extra
for width in (1, 7.8, 101.4, 109.2, 465.6, 892) + tuple(extra.values()):
    per_line = core.chars_per_line(width, 15, 0.52)
    for text in corpus:
        lines = core.wrap_lines(text, width, 15, 0.52)
        assert "".join(lines) == text, (width, text, lines)
        assert len(lines) == core.estimate_label_lines(text, width, 15, 0.52), (width, text, lines)
        assert all(fit(line) <= per_line for line in lines), (width, text, lines)
        assert len(lines) >= text.count("\n") + 1, (width, text, lines)
        assert all("\n" not in line[:-1] for line in lines), (width, text, lines)
        assert sum(line.endswith("\n") for line in lines) == text.count("\n"), (width, text, lines)
PY
then pass "drnd-42-wrap-lines-lossless"; else fail "drnd-42-wrap-lines-lossless"; fi

# drnd-43: the split breaks at whitespace. Within a paragraph, a line either ends in break spaces and the
# next word would not have fit after them, or it ends inside a word longer than a line, which is cut after
# every n characters from its start; no continuation line starts with a break space, and a no-break space
# never ends a line. Pinned splits include the German label a character cut breaks mid-word.
if python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import render_core as core
NO_BREAK = "\u00a0\u2007\u202f"


def breaks(char):
    return char.isspace() and char not in NO_BREAK


def width_for(n):
    width = n * 15 * 0.52 + 1
    assert core.chars_per_line(width, 15, 0.52) == n, (n, width)
    return width


german = 'Prozess nach Maß: "erst messen" & <dann> handeln\nCompliance by Design'
pinned = [
    (german, 13, ["Prozess nach ", 'Maß: "erst ', 'messen" & ', "<dann> ", "handeln\n", "Compliance by ", "Design"]),
    ("a  b\n\n  c ", 1, ["a  ", "b\n", "\n", "  ", "c "]),
    ("x" * 14, 13, ["x" * 13, "x"]),
    ("10 % mehr", 3, ["10 ", "% ", "meh", "r"]),
    ("ab 10\u00a0%", 5, ["ab ", "10\u00a0%"]),
    ("kurz Donaudampfschifffahrt lang", 6, ["kurz ", "Donaud", "ampfsc", "hifffa", "hrt ", "lang"]),
]
for text, n, want in pinned:
    got = core.wrap_lines(text, width_for(n), 15, 0.52)
    assert got == want, (text, n, got)

corpus = [text for text, _, _ in pinned] + [
    "Versicherungszuschläge für Betriebsunterbrechung und erweiterte Maschinenbruchdeckung",
    "Nachrüstung für Compliance und Arbeitssicherheit an allen Fertigungslinien",
    "Anlagenzustand, Wartungshistorie und Störungsmeldungen aller Linien in einer Sicht",
    "10\u00a0% mehr Umsatz, « texte\u202fcité » und  zwei  Leerzeichen", "   führend\tund nachlaufend   "]
for n in (1, 3, 5, 6, 13, 20, 37, 59):
    width = width_for(n)
    for text in corpus:
        lines = core.wrap_lines(text, width, 15, 0.52)
        assert "".join(lines) == text, (n, text, lines)
        paragraphs, current = [], []
        for line in lines:
            current.append(line)
            if line.endswith("\n"):
                paragraphs.append(current)
                current = []
        paragraphs.append(current)
        for paragraph in paragraphs:
            whole = "".join(paragraph).rstrip("\n")
            at = 0
            for line, following in zip(paragraph, paragraph[1:]):
                at += len(line)
                assert not breaks(following[0]), (n, text, lines, "a continuation line starts with a break space")
                start, end = at, at
                while start > 0 and not breaks(whole[start - 1]):
                    start -= 1
                while end < len(whole) and not breaks(whole[end]):
                    end += 1
                if breaks(line[-1]):
                    assert len(line) + (end - at) > n, (n, text, lines, "the next word would have fit")
                else:
                    assert end - start > n and (at - start) % n == 0, (n, text, lines, "a break inside a word")
PY
then pass "drnd-43-wrap-lines-word-boundary"; else fail "drnd-43-wrap-lines-word-boundary"; fi

# drnd-44..45: SVG figure text is drawn at the size of its slot's own type_role, the size the plan measured
# it at. A small cascade reader works out the size a browser draws each figure label at from the page alone:
# an inline style over the page's stylesheet rules (specificity, then source order) over an SVG presentation
# attribute, and the parent's size otherwise, with var() resolved against the page's :root. It models type,
# class, attribute-presence, :first-child and :root selectors joined by descendant, child and adjacent-sibling
# combinators, and raises on any other selector or value, so it cannot skip a rule that might match. The size each label must
# be drawn at comes from the theme tokens and the plan slot's type_role, never from what the page declares.
cat > "$WORK/cascade.py" <<'PY'
import re
from html.parser import HTMLParser

VOID = {"meta", "link", "br", "img", "input", "hr"}
COMPOUND = re.compile(r"(\*|[a-z][a-z0-9-]*)?((?:\.[A-Za-z0-9_-]+|\[[a-z-]+\]|:first-child|:root)*)")
PART = re.compile(r"\.[A-Za-z0-9_-]+|\[[a-z-]+\]|:first-child|:root")
RULE = re.compile(r"([^{}]+)\{([^{}]*)\}")
VAR = re.compile(r"var\(\s*(--[A-Za-z0-9_-]+)\s*\)")


class Node:
    def __init__(self, tag, attrs, parent):
        self.tag, self.attrs, self.parent, self.kids = tag, dict(attrs), parent, []

    def classes(self):
        return (self.attrs.get("class") or "").split()

    def walk(self):
        for kid in self.kids:
            yield kid
            yield from kid.walk()


def declarations(body):
    out = {}
    for decl in body.split(";"):
        if decl.strip():
            name, sep, value = decl.partition(":")
            assert sep and "!important" not in value, ("unmodelled declaration", decl)
            out[name.strip().lower()] = value.strip()
    return out


def selector(text):
    """A complex selector as steps of (combinator to the left, tag, simple parts), and its specificity."""
    steps, combinator = [], None
    for token in text.replace(">", " > ").replace("+", " + ").split():
        if token in (">", "+"):
            assert steps and combinator is None, ("unmodelled selector", text)
            combinator = token
            continue
        match = COMPOUND.fullmatch(token)
        if match is None:
            raise ValueError("unmodelled selector: " + text)
        steps.append((combinator or (" " if steps else None), match.group(1), PART.findall(match.group(2))))
        combinator = None
    assert steps and combinator is None, ("unmodelled selector", text)
    return steps, (0, sum(len(parts) for _, _, parts in steps), sum(1 for _, tag, _ in steps if tag not in (None, "*")))


def compound_matches(node, tag, parts):
    if node.parent is None or (tag not in (None, "*") and node.tag != tag):
        return False
    for part in parts:
        if part.startswith("."):
            ok = part[1:] in node.classes()
        elif part.startswith("["):
            ok = part[1:-1] in node.attrs
        elif part == ":first-child":
            ok = node.parent.kids[0] is node
        else:
            ok = node.tag == "html" and node.parent.parent is None
        if not ok:
            return False
    return True


def matches(node, steps):
    combinator, tag, parts = steps[-1]
    if not compound_matches(node, tag, parts):
        return False
    if len(steps) == 1:
        return True
    if combinator == "+":
        at = next(index for index, kid in enumerate(node.parent.kids) if kid is node)
        return at > 0 and matches(node.parent.kids[at - 1], steps[:-1])
    ancestor = node.parent
    while ancestor is not None:
        if matches(ancestor, steps[:-1]):
            return True
        if combinator == ">":
            return False
        ancestor = ancestor.parent
    return False


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.root = Node("#document", {}, None)
        self.stack, self.css, self.in_style = [self.root], [], False
        self.feed(open(path, encoding="utf-8").read())
        css = re.sub(r"/\*.*?\*/", "", "".join(self.css), flags=re.S)
        assert "@" not in css, "an at-rule the reader does not model"
        assert not RULE.sub("", css).strip(), "stylesheet text outside a rule"
        self.rules, self.custom = [], {}
        for order, (head, body) in enumerate(RULE.findall(css)):
            decls = declarations(body)
            for text in head.split(","):
                steps, specificity = selector(text)
                self.rules.append((steps, specificity, order, decls))
                custom = {name: value for name, value in decls.items() if name.startswith("--")}
                assert not custom or steps == [(None, None, [":root"])], ("a custom property outside :root", text)
                self.custom.update(custom)

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs, self.stack[-1])
        self.stack[-1].kids.append(node)
        if tag not in VOID:
            self.stack.append(node)
        self.in_style = tag == "style"

    def handle_endtag(self, tag):
        if len(self.stack) > 1 and self.stack[-1].tag == tag:
            self.stack.pop()
        self.in_style = False

    def handle_data(self, data):
        if self.in_style:
            self.css.append(data)

    def resolve(self, value):
        for _ in range(10):
            if not VAR.search(value):
                break
            value = VAR.sub(lambda match: self.custom[match.group(1)], value)
        match = re.fullmatch(r"([0-9]+(?:\.[0-9]+)?)px", value.strip())
        if match is None:
            raise ValueError("not a px length: " + value)
        return float(match.group(1))

    def font_size(self, node):
        """The px size `node` is drawn at, or None when nothing between it and the root sets one."""
        if node.parent is None:
            return None
        declared = declarations(node.attrs["style"]).get("font-size") if node.attrs.get("style") else None
        if declared is None:
            winners = [(specificity, order, decls["font-size"]) for steps, specificity, order, decls in self.rules
                       if "font-size" in decls and matches(node, steps)]
            declared = max(winners)[2] if winners else node.attrs.get("font-size")
        if declared is None or declared == "inherit":
            return self.font_size(node.parent)
        return self.resolve(declared)
PY

# figure_sizes <out-dir> <composition> <role>: every figure slot of the render records <role>, and every
# entity, chart and value label — and each of its lines — is drawn at that role's size token in the theme,
# while connector kind labels stay at size-small. With a raised role the three sizes must all differ, so the
# check cannot pass on a page that draws every figure at size-body.
figure_sizes() {
  python3 - "$WORK" "$1" "$2" "$3" "$THEME" <<'PY'
import json, re, sys
sys.path.insert(0, sys.argv[1])
from cascade import Page

work, out, comp_path, role, theme = sys.argv[1:]
ROLE_SIZE = {"type.display": "size-display", "type.heading": "size-h2", "type.lead": "size-h3",
             "type.body": "size-body", "type.caption": "size-small"}
FIGURE_SLOT = {"sourced-chart": "series", "conceptual-system": "entities"}
typography = json.load(open(f"{theme}/tokens/typography.json", encoding="utf-8"))


def token(key):
    return float(re.fullmatch(r"([0-9.]+)px", typography[key].strip()).group(1))


want, body, small = token(ROLE_SIZE[role]), token("size-body"), token("size-small")
assert want != small, (role, want, small)
if role != "type.body":
    assert want != body, (role, "the raised role draws at size-body in this theme, so the case proves nothing")
units = {unit["id"]: unit for unit in json.load(open(comp_path, encoding="utf-8"))["units"]}
plan = json.load(open(f"{work}/{out}/target-plan.json", encoding="utf-8"))
page = Page(f"{work}/{out}/index.html")
sections = {node.attrs.get("data-unit"): node for node in page.root.walk() if node.tag == "section"}
seen = set()
for plan_unit in plan["units"]:
    unit = units[plan_unit["composition_unit_ref"]]
    if unit["pattern"] not in FIGURE_SLOT:
        continue
    slot = next(s for s in plan_unit["slots"] if s["slot"] == FIGURE_SLOT[unit["pattern"]])
    assert slot["type_role"] == role, (unit["id"], slot["type_role"], role)
    svg = next(node for node in sections[unit["id"]].walk() if node.tag == "svg")
    texts = [node for node in svg.walk() if node.tag == "text"]
    if unit["pattern"] == "sourced-chart":
        labels = [t for t in texts if (t.attrs.get("data-copy") or "").startswith("data:")]
        values = [t for t in texts if "data-value" in t.attrs]
        assert len(labels) == len(values) == len(unit["data_bindings"]), (unit["id"], len(labels), len(values))
        drawn, chrome = labels + values, []
    else:
        drawn = [t for t in texts if "node" in t.parent.classes()]
        chrome = [t for t in texts if "edge" in t.parent.classes()]
        assert len(drawn) == len(unit["entities"]) and len(chrome) == len(unit.get("relationships", [])), unit["id"]
    assert len(drawn) + len(chrome) == len(texts), (unit["id"], "a figure text this case does not classify")
    for label in drawn:
        lines = [node for node in label.walk() if node.tag == "tspan"]
        for element in [label] + lines:
            assert page.font_size(element) == want, (unit["id"], label.attrs, page.font_size(element), want)
    for label in chrome:
        assert page.font_size(label) == small, (unit["id"], label.attrs, page.font_size(label), small)
    seen.add(unit["pattern"])
assert seen == set(FIGURE_SLOT), ("both figure kinds must be checked", seen)
PY
}

# drnd-44: a unit type_floor of type.lead on the German chart unit and system unit raises both figure slots,
# and every entity, chart and value label is drawn at size-h3, the size the plan measured; the page stays
# fidelity-clean. The composition is recomposed from a stripped draft, never typed.
floor_ok=0
if python3 - "$GERMAN" "$WORK/floor-src.json" <<'PY'
import json, sys
comp = json.load(open(sys.argv[1], encoding="utf-8"))
raised = [unit for unit in comp["units"] if unit["pattern"] in ("sourced-chart", "conceptual-system")]
assert sorted(unit["pattern"] for unit in raised) == ["conceptual-system", "sourced-chart"], raised
for unit in raised:
    unit["type_floor"] = "type.lead"
json.dump(comp, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
then
  if recompose 'pass' floor "$FIXTURES/render/direct-de-edge-v1.json" "$WORK/floor-src.json" &&
     render "$WORK/floor" "$WORK/floor-brief.json" "$WORK/floor-comp.json" --language de
  then floor_ok=1; fi
fi
if [ "$floor_ok" -eq 1 ] &&
   python3 -c 'import json, sys; units = json.load(open(sys.argv[1]))["units"]; assert sorted(u["id"] for u in units if u.get("type_floor") == "type.lead") == ["u-bausteine", "u-komponenten"]' "$WORK/floor-comp.json" &&
   green "$WORK/floor/index.html" "$WORK/floor-brief.json" "$WORK/floor-comp.json" &&
   figure_sizes floor "$WORK/floor-comp.json" type.lead
then pass "drnd-44-figure-text-role-size"; else fail "drnd-44-figure-text-role-size"; fi

# drnd-45: the control. With no type_floor the German figure slots stay at type.body and every figure label
# is drawn at size-body, so a fix that drew every figure at one raised size would fail here.
if green "$WORK/de/index.html" "$DBRIEF" "$GERMAN" && figure_sizes de "$GERMAN" type.body
then pass "drnd-45-figure-text-body-role"; else fail "drnd-45-figure-text-body-role"; fi

# --- faces a theme ships -------------------------------------------------------------------------------
# The font-shipping fixture theme is the render fixture theme with one change: its copy font leads with
# Outfit, which it ships under assets/fonts/ and declares in faces.json. Every expectation below comes
# from that theme's own files — the declaration and the font's bytes — never from the render.
python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$FONT_THEME" \
  --out "$WORK/shipped" --generated-at 2026-09-14T08:00:00Z --run-id suite > "$WORK/shipped.json" 2> "$WORK/shipped.err"
# font_theme_copy <dir> <python-edit>: a scratch copy of the font-shipping theme at <dir>/cogni-work whose
# faces.json (as `faces`) and typography tokens (as `typography`) the edit may change.
font_theme_copy() {
  mkdir -p "$1"
  cp -R "$FONT_THEME" "$1/cogni-work"
  python3 - "$1/cogni-work" "$2" <<'PY'
import json, sys
theme, edit = sys.argv[1:]
faces = json.load(open(f"{theme}/assets/fonts/faces.json"))
typography = json.load(open(f"{theme}/tokens/typography.json"))
exec(edit)
json.dump(faces, open(f"{theme}/assets/fonts/faces.json", "w"))
json.dump(typography, open(f"{theme}/tokens/typography.json", "w"))
PY
}

# drnd-46: a face the theme ships is the face the copy is set in, not a substitution. Provenance records
# it as requested and resolved, unsubstituted, with the digest of the shipped file; every plan slot is
# measured with it; the plugin-wide bundled registry gains nothing; the record passes check-provenance,
# and the same record without its file digest fails it.
if [ -s "$WORK/shipped/provenance.json" ] && [ ! -s "$WORK/shipped.err" ] &&
   python3 - "$WORK/shipped" "$FONT_FILE" "$PLUGIN_ROOT/references/font-fallbacks-v1.json" "$WORK" <<'PY'
import hashlib, json, sys
out, font_file, fallbacks, work = sys.argv[1:]
prov = json.load(open(f"{out}/provenance.json"))
font = next(f for f in prov["fonts"] if f["token"] == "typography.font-sans")
assert font["requested_family"] == font["resolved_face"] == "Outfit", font
assert font["substituted"] is False and font["skipped"] == [] and font["fallback_chain"][0] == "Outfit", font
assert font["source"] == "theme", font
assert font["file_sha256"] == "sha256:" + hashlib.sha256(open(font_file, "rb").read()).hexdigest(), font
assert prov["layout_face"] == "Outfit", prov["layout_face"]
plan = json.load(open(f"{out}/target-plan.json"))
assert {s["measured_with"] for u in plan["units"] for s in u["slots"]} == {"Outfit"}
assert json.load(open(fallbacks))["bundled_faces"] == {}
bare = json.loads(json.dumps(prov))
next(f for f in bare["fonts"] if f["token"] == "typography.font-sans").pop("file_sha256")
json.dump(bare, open(f"{work}/prov-shipped-bare.json", "w"))
PY
then
  ok=1
  python3 "$RENDER" check-provenance --provenance "$WORK/shipped/provenance.json" --composition "$NARR" \
    --plan "$WORK/shipped/target-plan.json" --out-dir "$WORK/shipped" > /dev/null || ok=0
  rc=0
  python3 "$RENDER" check-provenance --provenance "$WORK/prov-shipped-bare.json" > "$WORK/prov-shipped-bare.out" || rc=$?
  [ "$rc" -eq 1 ] && python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert "font-unrecorded" in {f["code"] for f in e["data"]["findings"]}' "$WORK/prov-shipped-bare.out" || ok=0
  if [ "$ok" -eq 1 ]; then pass "drnd-46-shipped-face-resolved"; else fail "drnd-46-shipped-face-resolved"; fi
else fail "drnd-46-shipped-face-resolved"; fi

# drnd-47: the face arrives inside the page. Read by the suite's own parser, the stylesheet carries exactly
# one @font-face, whose src is one data URI of type font/ttf with a truetype format() hint and nothing
# else — no local(), no remote, protocol-relative or file source — and whose payload decodes to the
# shipped file's bytes. The copy stack names the shipped family first, the rule sits before the component
# section, the component CSS stays free of literals, and check-html with the theme passes the page.
if [ -s "$WORK/shipped/index.html" ] && python3 - "$WORK/shipped/index.html" "$FONT_FILE" <<'PY'
import base64, re, sys
from html.parser import HTMLParser


class Styles(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.inside, self.text = False, []

    def handle_starttag(self, tag, attrs):
        self.inside = self.inside or tag == "style"

    def handle_endtag(self, tag):
        if tag == "style":
            self.inside = False

    def handle_data(self, data):
        if self.inside:
            self.text.append(data)


page, font_file = sys.argv[1:]
reader = Styles()
reader.feed(open(page, encoding="utf-8").read())
reader.close()
css = "".join(reader.text)
rules = re.findall(r"@font-face\s*\{([^{}]*)\}", css)
assert len(rules) == 1, len(rules)
body = rules[0]
urls = re.findall(r"url\(([^)]*)\)", body)
assert len(urls) == 1, urls
data = re.fullmatch(r"data:font/ttf;base64,([A-Za-z0-9+/]+=*)", urls[0])
assert data, urls[0][:40]
rest = body.replace(urls[0], "")
assert 'format("truetype")' in rest and re.search(r'font-family:\s*"Outfit"', rest), rest
for forbidden in ("local(", "http:", "https:", "//", "file:"):
    assert forbidden not in rest, forbidden
assert base64.b64decode(data.group(1), validate=True) == open(font_file, "rb").read()
stack = re.search(r"--render-font-copy:\s*([^;]+);", css).group(1)
assert stack.split(",")[0].strip().strip('"') == "Outfit", stack
marker = css.index("/* design-render: components */")
assert css.index("@font-face") < marker, "the @font-face is inside the component section"
assert not re.search(r"#[0-9a-fA-F]{3,8}\b|rgba?\(|font-family\s*:(?!\s*var\()|url\(", css[marker:])
PY
then
  if python3 "$RENDER" check-html --brief "$NBRIEF" --composition "$NARR" --html "$WORK/shipped/index.html" \
       --theme "$FONT_THEME" > /dev/null
  then pass "drnd-47-shipped-face-embedded"; else fail "drnd-47-shipped-face-embedded"; fi
else fail "drnd-47-shipped-face-embedded"; fi

# drnd-48: layout is computed with the shipped face's declared metric. A re-render compares equal, and a
# scratch copy of the theme whose declaration states another advance_em moves the plan: compare exits 1
# with plan-drift.
font_theme_copy "$WORK/wide" 'faces["faces"][0]["advance_em"] = 0.9'
ok=1
python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$FONT_THEME" \
  --out "$WORK/shipped-again" > /dev/null 2>&1 || ok=0
python3 "$RENDER" compare --expected "$WORK/shipped/target-plan.json" --actual "$WORK/shipped-again/target-plan.json" \
  > /dev/null || ok=0
python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$WORK/wide/cogni-work" \
  --out "$WORK/wide-out" > /dev/null 2>&1 || ok=0
rc=0
python3 "$RENDER" compare --expected "$WORK/shipped/target-plan.json" --actual "$WORK/wide-out/target-plan.json" \
  > "$WORK/wide-cmp.json" || rc=$?
[ "$rc" -eq 1 ] && python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["data"]["code"] == "plan-drift"' "$WORK/wide-cmp.json" || ok=0
if [ "$ok" -eq 1 ]; then pass "drnd-48-shipped-face-metrics"; else fail "drnd-48-shipped-face-metrics"; fi

# drnd-49: the declared advance_em is derived from the shipped file, not chosen. Read with struct from
# the TrueType tables themselves — the cmap's format 4 subtable, hmtx, hhea and head — the mean advance of
# the glyphs U+0020 to U+007E map to, over unitsPerEm and rounded to three decimals, equals the declaration.
if python3 - "$FONT_FILE" "$FONT_THEME/assets/fonts/faces.json" <<'PY'
import json, struct, sys
font_file, faces = sys.argv[1:]
data = open(font_file, "rb").read()
tables = {}
for i in range(struct.unpack(">H", data[4:6])[0]):
    tag, _, offset, _ = struct.unpack(">4sIII", data[12 + 16 * i:28 + 16 * i])
    tables[tag] = offset
units = struct.unpack(">H", data[tables[b"head"] + 18:tables[b"head"] + 20])[0]
metrics = struct.unpack(">H", data[tables[b"hhea"] + 34:tables[b"hhea"] + 36])[0]
cmap = tables[b"cmap"]
glyph = None
for i in range(struct.unpack(">H", data[cmap + 2:cmap + 4])[0]):
    platform, encoding, sub = struct.unpack(">HHI", data[cmap + 4 + 8 * i:cmap + 12 + 8 * i])
    at = cmap + sub
    if platform == 3 and encoding in (1, 10) and struct.unpack(">H", data[at:at + 2])[0] == 4:
        size = struct.unpack(">H", data[at + 6:at + 8])[0]
        count = size // 2
        ends = struct.unpack(">%dH" % count, data[at + 14:at + 14 + size])
        starts = struct.unpack(">%dH" % count, data[at + 16 + size:at + 16 + 2 * size])
        deltas = struct.unpack(">%dh" % count, data[at + 16 + 2 * size:at + 16 + 3 * size])
        ranges_at = at + 16 + 3 * size
        ranges = struct.unpack(">%dH" % count, data[ranges_at:ranges_at + size])

        def glyph(code):
            for k in range(count):
                if starts[k] <= code <= ends[k]:
                    if ranges[k] == 0:
                        return (code + deltas[k]) & 0xFFFF
                    spot = ranges_at + 2 * k + ranges[k] + 2 * (code - starts[k])
                    found = struct.unpack(">H", data[spot:spot + 2])[0]
                    return (found + deltas[k]) & 0xFFFF if found else 0
            return 0
        break
assert glyph is not None, "no format 4 Windows cmap"
codes = range(0x20, 0x7F)
assert all(glyph(code) for code in codes), "a printable ASCII character has no glyph"
hmtx = tables[b"hmtx"]
advances = [struct.unpack(">H", data[hmtx + 4 * min(glyph(c), metrics - 1):hmtx + 4 * min(glyph(c), metrics - 1) + 2])[0]
            for c in codes]
declared = json.load(open(faces))["faces"][0]["advance_em"]
assert round(sum(advances) / len(advances) / units, 3) == declared, (sum(advances) / len(advances) / units, declared)
PY
then pass "drnd-49-advance-em-derived"; else fail "drnd-49-advance-em-derived"; fi

# drnd-50: the fidelity gate admits exactly the embedded face and nothing else. Each doctored copy of the
# embedded page fails check-html with the theme under check `assets`, with the finding code it names: an
# @font-face src on a remote URL, a data URI outside any @font-face, the page's own embedded token reused
# outside its @font-face, a local() source, a payload whose bytes are not the shipped file, the shipped
# bytes under another format label (font/otf, opentype), an @import, and a page that drops the
# @font-face the theme's copy face needs. Without --theme no face is known, so the embedded page itself
# fails closed.
font_negative() {  # font_negative <id> <code> <python-edit>
  doctored "$1" "$WORK/shipped/index.html" "$NBRIEF" "$NARR" assets "$3" "$FONT_THEME" &&
    python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert sys.argv[2] in {f["code"] for f in e["data"]["findings"] if f["check"] == "assets"}, e["data"]["findings"]' "$WORK/$1.out" "$2"
}
ok=1
EMBED='re.search(r"url\(data:font/ttf;base64,[^)]*\) format\(\"truetype\"\)", page).group(0)'
font_negative drnd-50-https remote-asset \
  "page.replace($EMBED, 'url(https://fonts.example.com/outfit.ttf) format(\"truetype\")', 1)" || ok=0
font_negative drnd-50-outside remote-asset \
  'page.replace("<style>\n", "<style>\nbody { background: url(data:image/png;base64,iVBORw0KGgo=); }\n", 1)' || ok=0
font_negative drnd-50-reuse remote-asset \
  'page.replace("<style>\n", "<style>\nbody { background: " + re.search(r"url\(data:font/ttf;base64,[^)]*\)", page).group(0) + "; }\n", 1)' || ok=0
font_negative drnd-50-local local-reference \
  "page.replace($EMBED, 'local(\"Outfit\")', 1)" || ok=0
font_negative drnd-50-payload unshipped-font \
  're.sub(r"(url\(data:font/ttf;base64,)[^)]*(\))", r"\1AAEAAAAQAQAABAAAR0RFRg==\2", page, count=1)' || ok=0
font_negative drnd-50-relabel unshipped-font \
  'page.replace("url(data:font/ttf;", "url(data:font/otf;", 1).replace("format(\"truetype\")", "format(\"opentype\")", 1)' || ok=0
font_negative drnd-50-import remote-asset \
  'page.replace("<style>\n", "<style>\n@import url(fonts.css);\n", 1)' || ok=0
font_negative drnd-50-removed font-not-embedded \
  're.sub(r"@font-face \{[^{}]*\}\n", "", page, count=1)' || ok=0
rc=0
python3 "$RENDER" check-html --brief "$NBRIEF" --composition "$NARR" --html "$WORK/shipped/index.html" \
  > "$WORK/shipped-nothemed.out" || rc=$?
[ "$rc" -eq 1 ] && python3 -c 'import json, sys; e = json.load(open(sys.argv[1])); assert "remote-asset" in {f["code"] for f in e["data"]["findings"]}' "$WORK/shipped-nothemed.out" || ok=0
if [ "$ok" -eq 1 ]; then pass "drnd-50-embedded-face-negatives"; else fail "drnd-50-embedded-face-negatives"; fi

# drnd-51: a theme is untrusted input, so a face declaration cannot reach outside it, name a file that is
# not there or not a font, or leave the metric the layout needs undeclared. Each scratch declaration makes
# render exit 1 as invalid-theme under check `theme-font`, print nothing on stderr and create no output.
rejects_face() {  # rejects_face <id> <theme-dir>
  local id="$1" rc=0
  python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$2" \
    --out "$WORK/$id-out" > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  if [ "$rc" -eq 1 ] && [ ! -s "$WORK/$id.err" ] && [ ! -e "$WORK/$id-out" ] &&
     python3 -c 'import json, sys; d = json.load(open(sys.argv[1]))["data"]; assert (d["code"], d["check"]) == ("invalid-theme", "theme-font"), d' "$WORK/$id.out"
  then pass "$id"; else fail "$id"; fi
}
cp "$FONT_FILE" "$WORK/outside.ttf"
font_theme_copy "$WORK/face-absolute" "faces['faces'][0]['file'] = '$WORK/outside.ttf'"
font_theme_copy "$WORK/face-dotdot" 'faces["faces"][0]["file"] = "../outside.ttf"'
cp "$FONT_FILE" "$WORK/face-dotdot/outside.ttf"
font_theme_copy "$WORK/face-symlink" 'faces["faces"][0]["file"] = "assets/fonts/linked.ttf"'
ln -s "$WORK/outside.ttf" "$WORK/face-symlink/cogni-work/assets/fonts/linked.ttf"
font_theme_copy "$WORK/face-missing" 'faces["faces"][0]["file"] = "assets/fonts/Missing.ttf"'
font_theme_copy "$WORK/face-signature" 'faces["faces"][0]["file"] = "assets/fonts/fake.ttf"'
printf '%s\n' 'not a font' > "$WORK/face-signature/cogni-work/assets/fonts/fake.ttf"
font_theme_copy "$WORK/face-advance-missing" 'del faces["faces"][0]["advance_em"]'
font_theme_copy "$WORK/face-advance-zero" 'faces["faces"][0]["advance_em"] = 0'
for variant in absolute dotdot symlink missing signature advance-missing advance-zero; do
  rejects_face "drnd-51-theme-font-$variant" "$WORK/face-$variant/cogni-work"
done

# drnd-52: substitution bookkeeping stays honest when the shipped face is not the first choice. With
# 'Brand Face' ahead of it, the copy font resolves to the shipped face as a recorded substitution — skipped
# names the earlier family — the page still embeds that face, and check-html and check-provenance pass.
font_theme_copy "$WORK/second" 'typography["font-sans"] = "'"'"'Brand Face'"'"', '"'"'Outfit'"'"', system-ui, sans-serif"'
if python3 "$RENDER" render --target html --brief "$NBRIEF" --composition "$NARR" --theme "$WORK/second/cogni-work" \
     --out "$WORK/second-out" > /dev/null 2>&1 &&
   python3 -c '
import json, sys
font = next(f for f in json.load(open(sys.argv[1]))["fonts"] if f["token"] == "typography.font-sans")
assert (font["resolved_face"], font["substituted"], font["skipped"], font["source"]) == ("Outfit", True, ["Brand Face"], "theme"), font
assert font["fallback_chain"] == ["Outfit", "system-ui", "sans-serif"], font' "$WORK/second-out/provenance.json" &&
   python3 "$RENDER" check-html --brief "$NBRIEF" --composition "$NARR" --html "$WORK/second-out/index.html" \
     --theme "$WORK/second/cogni-work" > /dev/null &&
   python3 "$RENDER" check-provenance --provenance "$WORK/second-out/provenance.json" --composition "$NARR" \
     --plan "$WORK/second-out/target-plan.json" --out-dir "$WORK/second-out" > /dev/null
then pass "drnd-52-shipped-face-not-first"; else fail "drnd-52-shipped-face-not-first"; fi

# drnd-53: browser evidence that the embedded face is the face the page renders in, with no request. Under
# the pinned runtime the embedded page requests nothing, clips no copy, and the platform fonts the browser
# reports for copy include the shipped family. Without the runtime it prints SKIP, never PASS.
if runtime_case "drnd-53-shipped-face-browser"; then
  ok=1
  python3 "$RENDER" measure --html "$WORK/shipped/index.html" --out "$WORK/shipped-measure.json" > /dev/null || ok=0
  python3 -c 'import json, sys; r = json.load(open(sys.argv[1])); assert r["requests"] == {"blocked": [], "failed": []} and r["clipped"] == [] and "Outfit" in r["platform_fonts"], (r["requests"], r["platform_fonts"])' "$WORK/shipped-measure.json" || ok=0
  if [ "$ok" -eq 1 ]; then pass "drnd-53-shipped-face-browser"; else fail "drnd-53-shipped-face-browser"; fi
fi

printf '%s\n' "Design-render tests: $passes passed, $failures failed, $skips skipped"
[ "$failures" -eq 0 ]
