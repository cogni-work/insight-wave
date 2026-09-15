#!/usr/bin/env bash
# design-verify suite for cogni-publishing: the verification layer on top of design-render and the
# committed two-brand proof — preservation family by family, PPTX editability and edit witnesses,
# declared accessibility, the critical geometry classes, the verdict, the review record, the specimen
# index, the proof manifest, the bounded repair loop and standalone isolation.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `dver`; NN is an allocation counter,
# so never renumber an existing id — the mutation recipes below record fourteen.
#
# Every expectation comes from the frozen inputs or the committed proof records, read by this suite's
# own JSON, zipfile and ElementTree code. Every negative is a doctored copy — of a committed proof output
# or of a render made here — in a scratch directory; no tracked file is mutated. Rendering and verifying
# need no Node, browser, network or runtime, so no case here can be skipped: every line is PASS or FAIL.
# The committed proof records a renderer and brand pin of the plugin version it was rendered at; no case
# compares that with the live plugin.json, which the post-merge bump changes.
#
# Mutation recipes (run from the repository root; the harness is the installed managed-service
# cogni-service plugin, and --expr is evaluated by perl -0pi). The first three relax the executable
# checks for frozen copy, source links and clipping, and must fail dver-11, dver-12 and dver-13; the
# fourth lets the repair loop ignore its budget and must fail dver-25. The next nine delete one anchored
# prose rule each, six from the design-verify skill and three from design-render; the last deletes only
# the verdict clause from design-render's post-render line, which dver-34 must still catch. A prose rule
# can only be held by its shape, so those cases are anchored grep checks with these documented
# mutations, not behavioral tests:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return found_text == frozen_text/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-11-frozen-copy
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return target_url == source_url/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-12-source-link-loss
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return needed_px > available_px \+ CLIP_TOLERANCE_PX/return False/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-13-clipping
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/design-verify.py --expr 's/return used < budget/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-25-repair-budget-zero
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Inspect every unit at full resolution[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-29-skill-full-resolution
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Review one deck overview per brand and target[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-30-skill-deck-overview
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^An open critical finding blocks success[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-31-skill-critical-blocks
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Never record an unqualified quality verdict[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-32-skill-qualified-verdict
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^A repair never alters frozen content[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-33-skill-frozen-content
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^The repair budget defaults to 3[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-42-skill-repair-budget
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^After every render, run design-verify[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-34-render-wiring
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^When verification fails, repair within the budget[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-40-render-repair-report
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^Never rewrite, shorten, add, drop or reorder copy[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-41-render-frozen-copy
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/ and report success only when its verdict passes//' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-34-render-wiring
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$PLUGIN_ROOT/scripts"
VERIFY="$SCRIPTS/design-verify.py"
RENDER="$SCRIPTS/design-render.py"
VALIDATOR="$SCRIPTS/validate-publishing.py"
FIX="$PLUGIN_ROOT/tests/fixtures/verify"
PROOF="$PLUGIN_ROOT/docs/design-verify-proof"
BRIEF="$FIX/direct-proof-v1.normalized.json"
COMP_B="$FIX/composition-proof-boardroom-v2.json"
COMP_E="$FIX/composition-proof-editorial-v2.json"
THEME_B="$PLUGIN_ROOT/themes/boardroom"
PAGE_B="$PROOF/boardroom/html/index.html"
DECK_B="$PROOF/boardroom/pptx/deck.pptx"
NBRIEF="$PLUGIN_ROOT/tests/fixtures/narrative-slides-v1.expected.json"
NCOMP="$PLUGIN_ROOT/tests/fixtures/composition-narrative-v2.json"
NTHEME="$PLUGIN_ROOT/tests/fixtures/render/themes/cogni-work"
SKILL="$PLUGIN_ROOT/skills/design-verify/SKILL.md"
RSKILL="$PLUGIN_ROOT/skills/design-render/SKILL.md"
EVIDENCE="$PLUGIN_ROOT/docs/design-verify-proof.md"
FIXED=(--generated-at 2026-09-14T00:00:00Z --run-id design-verify-proof)
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0
failures=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

dv() {  # dv <label> <design-verify args...>: keep stdout, stderr and the exit status
  local label="$1"
  shift
  python3 "$VERIFY" "$@" > "$WORK/$label.out" 2> "$WORK/$label.err"
  printf '%s' "$?" > "$WORK/$label.rc"
}

# q <label> <python expression over e (the envelope) and d (its data)>: prints the expression's value
cat > "$WORK/q.py" <<'PY'
import json
import sys
e = json.load(open(sys.argv[1], encoding="utf-8"))
d = e.get("data") or {}
print(eval(sys.argv[2], {"e": e, "d": d, "json": json}))
PY
q() { python3 "$WORK/q.py" "$WORK/$1.out" "$2"; }
ok() {  # ok <label> <rc> [python predicate]: the exit status, one envelope, nothing on stderr, predicate
  local label="$1" want="$2" predicate="${3:-True}"
  [ "$(cat "$WORK/$label.rc")" = "$want" ] && [ ! -s "$WORK/$label.err" ] \
    && [ "$(q "$label" "$predicate")" = "True" ]
}

# One deck editor for the negatives: every edit is one small change to a copy of a green deck.
cat > "$WORK/deck.py" <<'PY'
import io
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
P = "{http://schemas.openxmlformats.org/presentationml/2006/main}"
C = "{http://schemas.openxmlformats.org/drawingml/2006/chart}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
for prefix, uri in (("a", A), ("p", P), ("c", C), ("r", R)):
    ET.register_namespace(prefix, uri[1:-1])
op, src, dst, *args = sys.argv[1:]
archive = zipfile.ZipFile(src)
parts = [(info.filename, archive.read(info)) for info in archive.infolist()]
data = dict(parts)


def slide_of(unit):
    for name, payload in parts:
        if re.fullmatch(r"ppt/slides/slide[0-9]+\.xml", name):
            tree = ET.fromstring(payload)
            if tree.find(P + "cSld").get("name") == unit:
                return name, tree
    raise SystemExit(f"no slide for {unit}")


def shape(tree, name):
    for node in tree.iter():
        if node.tag in (P + "sp", P + "graphicFrame", P + "pic", P + "cxnSp"):
            props = node.find(f".//{P}cNvPr")
            if props is not None and props.get("name") == name:
                return node
    raise SystemExit(f"no shape {name}")


def parent_of(tree, child):
    return next(node for node in tree.iter() if child in list(node))


def picture(old):
    props = old.find(f".//{P}cNvPr")
    xfrm = old.find(f"{P}spPr/{A}xfrm")
    if xfrm is None:
        frame = old.find(P + "xfrm")
        xfrm = ET.Element(A + "xfrm")
        for child in frame:
            xfrm.append(child)
    pic = ET.fromstring(f'<p:pic xmlns:p="{P[1:-1]}" xmlns:a="{A[1:-1]}"><p:nvPicPr><p:cNvPr id="{props.get("id")}" '
                       f'name="{props.get("name")}" descr="a flattened substitution"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr>'
                       f'<p:blipFill/><p:spPr/></p:pic>')
    pic.find(P + "spPr").append(xfrm)
    return pic


def emu(px):
    return str(int(round(float(px) * 9525)))


changed = {}
if op == "shrink":  # shrink <unit> <shape> <px>
    part, tree = slide_of(args[0])
    shape(tree, args[1]).find(f"{P}spPr/{A}xfrm/{A}ext").set("cy", emu(args[2]))
    changed[part] = tree
elif op == "overlap":  # overlap <unit> <moved shape> <onto shape>
    part, tree = slide_of(args[0])
    onto = shape(tree, args[2]).find(f"{P}spPr/{A}xfrm/{A}off")
    moved = shape(tree, args[1]).find(f"{P}spPr/{A}xfrm/{A}off")
    moved.set("x", onto.get("x"))
    moved.set("y", onto.get("y"))
    changed[part] = tree
elif op == "flatten":  # flatten <unit> <shape>
    part, tree = slide_of(args[0])
    old = shape(tree, args[1])
    holder = parent_of(tree, old)
    index = list(holder).index(old)
    holder.remove(old)
    holder.insert(index, picture(old))
    changed[part] = tree
elif op == "strip-descr":  # strip-descr <unit> <shape>
    part, tree = slide_of(args[0])
    shape(tree, args[1]).find(f".//{P}cNvPr").attrib.pop("descr")
    changed[part] = tree
elif op == "drop-zero":
    text = data["ppt/charts/chart1.xml"].decode("utf-8")
    assert text.count('<c:min val="0"/>') == 1
    changed["ppt/charts/chart1.xml"] = text.replace('<c:min val="0"/>', "").encode("utf-8")
elif op == "cache":  # cache <value>: the chart's first cached value only, the workbook untouched
    tree = ET.fromstring(data["ppt/charts/chart1.xml"])
    tree.find(f".//{C}val//{C}numCache/{C}pt/{C}v").text = args[0]
    changed["ppt/charts/chart1.xml"] = tree
elif op == "text":  # text <unit> <shape> <new text of its first run>
    part, tree = slide_of(args[0])
    shape(tree, args[1]).find(f".//{A}t").text = args[2]
    changed[part] = tree
else:
    raise SystemExit(f"unknown op {op}")
out = io.BytesIO()
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as target:
    for name, payload in parts:
        value = changed.get(name, payload)
        if not isinstance(value, bytes):
            value = ET.tostring(value, encoding="utf-8", xml_declaration=True)
        target.writestr(name, value)
open(dst, "wb").write(out.getvalue())
PY
deck() { python3 "$WORK/deck.py" "$@"; }

# sub <src> <dst> <old> <new> [count]: a literal replacement that must hit exactly `count` times (default 1)
cat > "$WORK/sub.py" <<'PY'
import sys
src, dst, old, new = sys.argv[1:5]
count = int(sys.argv[5]) if len(sys.argv) > 5 else 1
text = open(src, encoding="utf-8").read()
if text.count(old) < 1 or (count > 0 and text.count(old) != count):
    raise SystemExit(f"{old!r} occurs {text.count(old)} times, not {count}")
open(dst, "w", encoding="utf-8").write(text.replace(old, new))
PY
sub() { python3 "$WORK/sub.py" "$@"; }

# --- the skill and the scripts ---------------------------------------------------------------------

# dver-01: the skill's frontmatter names it after its directory and describes it within the published cap.
if python3 - "$SKILL" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
assert lines[0] == "---"
end = lines.index("---", 1)
fields = dict(line.split(": ", 1) for line in lines[1:end])
assert fields["name"] == "design-verify" == sys.argv[1].split("/")[-2]
assert 0 < len(fields["description"]) <= 1024
assert "review brief" not in fields["description"]
PY
then pass "dver-01-skill-frontmatter"; else fail "dver-01-skill-frontmatter"; fi

# dver-02: the verifier compiles on the repository's Python 3.9 floor and imports only the stdlib and the
# plugin's own sibling modules. With no 3.9 interpreter on the host, the grammar check runs as 3.9.
py39=""
for candidate in python3.9 /usr/bin/python3; do
  if command -v "$candidate" > /dev/null 2>&1 && "$candidate" -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 9) else 1)' 2> /dev/null; then
    py39="$candidate"
    break
  fi
done
if python3 - "$SCRIPTS/verify_checks.py" "$SCRIPTS/design-verify.py" "$py39" "$WORK" <<'PY'
import ast, subprocess, sys
import importlib.util, sysconfig
from pathlib import Path
files, py39, work = sys.argv[1:3], sys.argv[3], sys.argv[4]
local = {"render_core", "verify_checks"}

def stdlib_name(name):
    if name in sys.builtin_module_names:
        return True
    spec = importlib.util.find_spec(name)
    if spec is None:
        return False
    if spec.origin in ("built-in", "frozen"):
        return True
    if not spec.origin:
        return False
    origin = Path(spec.origin).resolve()
    return not {"site-packages", "dist-packages"}.intersection(origin.parts) and any(
        Path(sysconfig.get_path(key)).resolve() in origin.parents for key in ("stdlib", "platstdlib"))

for path in files:
    source = open(path, encoding="utf-8").read()
    tree = ast.parse(source, feature_version=(3, 9))
    if py39:
        code = "import py_compile, sys; py_compile.compile(sys.argv[1], cfile=sys.argv[2], doraise=True)"
        subprocess.run([py39, "-c", code, path, work + "/py39.pyc"], check=True, capture_output=True)
    for node in ast.walk(tree):
        names = [a.name for a in node.names] if isinstance(node, ast.Import) else \
            [node.module] if isinstance(node, ast.ImportFrom) and node.module else []
        for name in names:
            root = name.split(".")[0]
            assert stdlib_name(root) or root in local, (path, name)
PY
then pass "dver-02-stdlib-py39"; else fail "dver-02-stdlib-py39"; fi

# dver-03: the verifier reads only what the caller supplies: no environment, home directory, process,
# socket, URL fetch, workspace path or proprietary service anywhere in its source.
if python3 - "$SCRIPTS/verify_checks.py" "$SCRIPTS/design-verify.py" <<'PY'
import sys
for path in sys.argv[1:]:
    source = open(path, encoding="utf-8").read()
    for probe in ("os.environ", "getenv", "expanduser", "Path.home", "import subprocess", "import socket", "urllib",
                  "http.client", "cogni-workspace", "claude.ai", "COGNI_", "CLAUDE_PLUGIN_ROOT"):
        assert probe not in source, (path, probe)
PY
then pass "dver-03-no-ambient-reads"; else fail "dver-03-no-ambient-reads"; fi

# dver-04: from a scratch directory, with an empty environment, a scratch HOME and a decoy cogni-workspace
# beside the working directory, verify, check-proof and render-verified succeed while an audit hook proves
# they opened only their own plugin's files, the supplied inputs and their own output directory, listed
# nothing else, spawned no process, touched no network and loaded nothing outside the stdlib. An import
# event whose module never loaded — a stdlib module's own guarded probe, such as platform's _wmi on a
# build without it — is not a load; doctored logs prove a loaded non-stdlib module still fails.
mkdir -p "$WORK/iso/cwd" "$WORK/iso/home" "$WORK/iso/out" "$WORK/iso/cogni-workspace"
printf '%s\n' '{"target": "web"}' > "$WORK/iso/cogni-workspace/settings.json"
cat > "$WORK/audit_run.py" <<'PY'
import json, os, pathlib, runpy, sys
log_path, script, *argv = sys.argv[1:]
watched = ("os.listdir", "os.scandir", "glob.", "subprocess.", "os.system", "os.exec", "os.posix_spawn",
           "os.spawn", "os.fork", "socket.", "urllib.", "http.client.", "ctypes.")
events = []
def hook(event, args):
    if event == "open" and args and isinstance(args[0], (str, bytes)):
        events.append(["open", os.fsdecode(args[0])])
    elif event == "import":
        events.append(["import", args[0]])
    elif event in ("os.listdir", "os.scandir"):
        events.append([event, os.fsdecode(args[0]) if isinstance(args[0], (str, bytes, os.PathLike)) else repr(args[0])])
    elif event.startswith(watched):
        events.append([event, repr(args)[:160]])
def recording(real):
    def wrapper(path, *args, **kwargs):
        events.append(["stat", os.fsdecode(path) if isinstance(path, (str, bytes, os.PathLike)) else repr(path)])
        return real(path, *args, **kwargs)
    return wrapper
os.stat, os.lstat = recording(os.stat), recording(os.lstat)
# On Python 3.9 pathlib caches these builtins on an accessor. Patch that instance as well:
# loading pathlib only after wrapping os.stat would bind an unintended self argument.
if hasattr(pathlib, "_normal_accessor"):
    pathlib._normal_accessor.stat = os.stat
    pathlib._normal_accessor.lstat = os.lstat
import_path = list(sys.path)
sys.argv = [script, *argv]
sys.addaudithook(hook)
code = 0
try:
    runpy.run_path(script, run_name="__main__")
except SystemExit as exc:
    code = exc.code if isinstance(exc.code, int) else 1
snapshot = list(events)
modules = sorted(sys.modules)
with open(log_path, "w", encoding="utf-8") as fh:
    json.dump({"exit": code, "import_path": import_path, "events": snapshot, "modules": modules}, fh)
sys.exit(code)
PY
iso_rc=0
iso_run() {
  local log="$1"
  shift
  (cd "$WORK/iso/cwd" && env -i PATH="$PATH" HOME="$WORK/iso/home" \
     python3 -I -S -B "$WORK/audit_run.py" "$WORK/iso/$log" "$VERIFY" "$@" > "$WORK/iso/$log.out") || iso_rc=1
}
iso_run log-verify.json verify --target pptx --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" \
  --artifact "$DECK_B" --manifest "$PROOF/boardroom/pptx/pptx-manifest.json" --review "$PROOF/review-record.json" \
  --out "$WORK/iso/out/verification.json"
iso_run log-proof.json check-proof --manifest "$PROOF/proof-manifest.json"
iso_run log-loop.json render-verified --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" \
  --out "$WORK/iso/out/loop" "${FIXED[@]}"
cat > "$WORK/iso_check.py" <<'PY'
import json, os, sys, sysconfig
import importlib.util
from pathlib import Path

def stdlib_name(name):
    if name in sys.builtin_module_names:
        return True
    spec = importlib.util.find_spec(name)
    if spec is None:
        return False
    if spec.origin in ("built-in", "frozen"):
        return True
    if not spec.origin:
        return False
    origin = Path(spec.origin).resolve()
    return not {"site-packages", "dist-packages"}.intersection(origin.parts) and any(
        Path(sysconfig.get_path(key)).resolve() in origin.parents for key in ("stdlib", "platstdlib"))

plugin, iso = (os.path.realpath(p) for p in sys.argv[1:3])
paths = sysconfig.get_paths()
stdlib = {os.path.realpath(paths[key]) for key in ("stdlib", "platstdlib")}
inside = lambda path, root: path == root or path.startswith(root + os.sep)
allowed_roots = [plugin, os.path.join(iso, "out")]
local = {"render_core", "render_checks", "pptx_checks", "verify_checks", "html_adapter", "pptx_adapter"}
for name in sys.argv[3:]:
    log = json.load(open(os.path.join(iso, name), encoding="utf-8"))
    envelope = json.load(open(os.path.join(iso, name + ".out"), encoding="utf-8"))
    assert log["exit"] == 0 and envelope["success"] is True, name
    import_dirs = {os.path.realpath(p) for p in log["import_path"] if p}
    assert not [p for p in import_dirs if "site-packages" in p], name
    loaded = set(log["modules"])
    for kind, detail in log["events"]:
        real = os.path.realpath(detail) if kind in ("open", "stat", "os.listdir", "os.scandir") else detail
        if kind == "stat" and any(inside(root, real) for root in allowed_roots):
            continue  # resolving a path stats each ancestor directory of the allowed roots; nothing is read there
        if kind in ("open", "stat", "os.listdir", "os.scandir"):
            # Python 3.9 random initializes from the OS entropy device; this is a stdlib runtime read.
            assert real == "/dev/urandom" or any(inside(real, root) for root in allowed_roots) or real in import_dirs \
                or any(inside(real, root) for root in stdlib), (name, kind, detail)
            assert not inside(real, os.path.join(iso, "home")) and not inside(real, os.path.join(iso, "cogni-workspace"))
        elif kind == "import":
            root = detail.split(".")[0]
            if root not in loaded:
                continue  # an attempted import that never loaded, such as a stdlib module's guarded probe
            assert stdlib_name(root) or root in local or root.startswith("cogni_publishing_"), (name, detail)
        else:
            raise AssertionError((name, kind, detail))
PY
# Two doctored copies of the verify log prove the import arm still discriminates: a loaded non-stdlib
# module fails, and the same import attempted but never loaded passes.
python3 - "$WORK/iso" 2>/dev/null <<'PY'
import json, os, shutil, sys
iso = sys.argv[1]
log = json.load(open(os.path.join(iso, "log-verify.json"), encoding="utf-8"))
for name, add_module in (("log-loaded.json", True), ("log-attempted.json", False)):
    doctored = dict(log, events=log["events"] + [["import", "yaml"]])
    if add_module:
        doctored["modules"] = sorted(set(log["modules"]) | {"yaml"})
    with open(os.path.join(iso, name), "w", encoding="utf-8") as fh:
        json.dump(doctored, fh)
    shutil.copyfile(os.path.join(iso, "log-verify.json.out"), os.path.join(iso, name + ".out"))
PY
if [ "$iso_rc" -eq 0 ] \
   && python3 "$WORK/iso_check.py" "$PLUGIN_ROOT" "$WORK/iso" log-verify.json log-proof.json log-loop.json \
   && ! python3 "$WORK/iso_check.py" "$PLUGIN_ROOT" "$WORK/iso" log-loaded.json 2>/dev/null \
   && python3 "$WORK/iso_check.py" "$PLUGIN_ROOT" "$WORK/iso" log-attempted.json
then pass "dver-04-standalone-isolation"; else fail "dver-04-standalone-isolation"; fi

# --- the proof --------------------------------------------------------------------------------------

# dver-05: the proof brief is one direct-brief@1 carrying a comparison, a sourced chart whose data has a
# source with a URL, a conceptual system, notes and sources; it normalizes to the committed frozen form;
# each composition is frozen compose output of a stripped draft, differing only in its brand, and so is
# the unfit composition the repair cases use; and the normalized brief, composition and each committed
# plan validate as a chain.
python3 "$VALIDATOR" normalize --kind direct --input "$FIX/direct-unfit-v1.json" > "$WORK/unfit-norm.out" 2> /dev/null
python3 -c 'import json,sys;json.dump(json.load(open(sys.argv[1]))["data"],open(sys.argv[2],"w"),ensure_ascii=False)' \
  "$WORK/unfit-norm.out" "$WORK/unfit.json"
strip_draft() {  # strip_draft <composition> <draft>: drop every field compose fills
  python3 - "$1" "$2" <<'PY'
import json, sys
composition = json.load(open(sys.argv[1], encoding="utf-8"))
composition["normalized_brief_ref"].pop("content_fingerprint", None)
composition["document_bindings"] = []
for unit in composition["units"]:
    unit.pop("source_refs", None)
    unit.pop("register_refs", None)
    for binding in unit.get("bindings", []):
        binding.pop("digest", None)
json.dump(composition, open(sys.argv[2], "w", encoding="utf-8"))
PY
}
python3 "$VALIDATOR" normalize --kind direct --input "$FIX/direct-proof-v1.json" > "$WORK/norm.out" 2> "$WORK/norm.err"
norm_rc=$?
for brand in boardroom editorial; do
  strip_draft "$FIX/composition-proof-$brand-v2.json" "$WORK/draft-$brand.json"
  python3 "$VALIDATOR" compose --brief "$BRIEF" --composition "$WORK/draft-$brand.json" > "$WORK/compose-$brand.out" 2> /dev/null
  python3 "$VALIDATOR" check-composition --brief "$BRIEF" --composition "$FIX/composition-proof-$brand-v2.json" \
    > "$WORK/check-$brand.out" 2> /dev/null
  for target in html pptx; do
    python3 - "$BRIEF" "$FIX/composition-proof-$brand-v2.json" "$PROOF/$brand/$target/target-plan.json" \
      "$WORK/chain-$brand-$target.json" <<'PY'
import json, sys
brief, composition, plan, out = sys.argv[1:]
chain = {"normalized_brief": json.load(open(brief)), "semantic_composition": json.load(open(composition)),
         "target_resolved_plan": json.load(open(plan))}
json.dump(chain, open(out, "w", encoding="utf-8"))
PY
    python3 "$VALIDATOR" validate --input "$WORK/chain-$brand-$target.json" > "$WORK/chain-$brand-$target.out" 2> /dev/null
  done
done
strip_draft "$FIX/composition-unfit-v2.json" "$WORK/draft-unfit.json"
python3 "$VALIDATOR" compose --brief "$WORK/unfit.json" --composition "$WORK/draft-unfit.json" > "$WORK/compose-unfit.out" 2> /dev/null
if [ "$norm_rc" -eq 0 ] && [ ! -s "$WORK/norm.err" ] && python3 - "$WORK" "$FIX" "$BRIEF" <<'PY'
import json, sys
work, fix, brief_path = sys.argv[1:]
normalized = json.load(open(f"{work}/norm.out"))["data"]
brief = json.load(open(brief_path))
assert normalized == brief and brief["artifact_type"] == "normalized-brief"
assert json.load(open(f"{fix}/direct-proof-v1.json"))["artifact_type"] == "direct-brief"
compositions = {}
for brand in ("boardroom", "editorial"):
    committed = json.load(open(f"{fix}/composition-proof-{brand}-v2.json"))
    assert json.load(open(f"{work}/compose-{brand}.out"))["data"] == committed, brand
    assert json.load(open(f"{work}/check-{brand}.out"))["success"] is True, brand
    for target in ("html", "pptx"):
        assert json.load(open(f"{work}/chain-{brand}-{target}.out"))["success"] is True, (brand, target)
    assert committed["design_system"]["name"] == brand
    compositions[brand] = committed
a, b = (dict(c, design_system=None) for c in compositions.values())
assert a == b
assert json.load(open(f"{work}/compose-unfit.out"))["data"] == json.load(open(f"{fix}/composition-unfit-v2.json"))
units = compositions["boardroom"]["units"]
assert {u["pattern"] for u in units} == {"answer-emphasis", "comparison", "sourced-chart", "conceptual-system", "sources"}
assert units[-1]["pattern"] == "sources"
assert any(b["slot"] == "notes" for u in units for b in u.get("bindings", []))
sources = {s["id"]: s for s in brief["sources"]}
data = {d["id"]: d for d in brief["data"]}
chart = next(u for u in units if u["pattern"] == "sourced-chart")
points = [data[p["data_ref"]] for p in chart["data_bindings"]]
assert points and all(isinstance(p["value"], (int, float)) and p["unit"] for p in points)
assert all(sources[ref].get("url", "").startswith("https://") for p in points for ref in p["source_refs"])
PY
then pass "dver-05-proof-brief"; else fail "dver-05-proof-brief"; fi

# dver-06: the proof manifest records exactly four outputs — html and pptx for two distinct bundled
# brands — and every recorded digest recomputes, by this suite's own hashing as well as check-proof. A
# manifest with one brand token digest changed is refused.
dv proof check-proof --manifest "$PROOF/proof-manifest.json"
python3 - "$PROOF/proof-manifest.json" "$PLUGIN_ROOT" "$WORK/altered-manifest.json" <<'PY'
import json, sys
manifest = json.load(open(sys.argv[1]))
manifest["root"] = sys.argv[2]
files = manifest["outputs"][0]["theme"]["files"]
files["tokens/colors.json"] = "sha256:" + "0" * 64
json.dump(manifest, open(sys.argv[3], "w"))
PY
dv proof-altered check-proof --manifest "$WORK/altered-manifest.json"
if ok proof 0 "d['valid'] and d['outputs'] == 4" \
   && ok proof-altered 1 "d['code'] == 'proof-invalid' and any(f['code'] == 'proof-hash-mismatch' for f in d['findings'])" \
   && python3 - "$PROOF/proof-manifest.json" <<'PY'
import hashlib, json, os, re, sys
path = sys.argv[1]
manifest = json.load(open(path))
root = os.path.normpath(os.path.join(os.path.dirname(path), manifest["root"]))
def digest(rel):
    return "sha256:" + hashlib.sha256(open(os.path.join(root, rel), "rb").read()).hexdigest()
for key in ("brief", "normalized_brief", "review", "specimens", "repair", "isolated_render"):
    assert digest(manifest[key]["path"]) == manifest[key]["sha256"], key
iso = json.load(open(os.path.join(root, manifest["isolated_render"]["path"])))["inputs"]
assert iso["brief"] == manifest["brief"] and iso["normalized_brief"] == manifest["normalized_brief"]
for output in manifest["outputs"]:
    assert iso["compositions"][output["brand"]] == output["composition"], output["brand"]
    assert iso["themes"][output["brand"]] == output["theme"], output["brand"]
outputs = manifest["outputs"]
assert len(outputs) == 4
assert sorted((o["brand"], o["target"]) for o in outputs) == [(b, t) for b in sorted({o["brand"] for o in outputs})
                                                               for t in ("html", "pptx")]
assert len({o["brand"] for o in outputs}) == 2
for output in outputs:
    assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", output["renderer"]["version"])
    assert output["command"].startswith("python3 scripts/design-render.py render ")
    for key in ("composition", "plan", "artifact", "provenance", "verification") + (("manifest",) if output["target"] == "pptx" else ()):
        assert digest(output[key]["path"]) == output[key]["sha256"], (output["brand"], output["target"], key)
    theme = output["theme"]
    assert theme["path"] == "themes/" + output["brand"]
    for name, sha in theme["files"].items():
        assert digest(theme["path"] + "/" + name) == sha, name
PY
then pass "dver-06-proof-manifest"; else fail "dver-06-proof-manifest"; fi

# dver-07: re-verifying every committed output from its frozen inputs reproduces its committed report.
reverify_ok=1
for brand in boardroom editorial; do
  for target in html pptx; do
    artifact=index.html
    manifest=()
    if [ "$target" = pptx ]; then artifact=deck.pptx; manifest=(--manifest "$PROOF/$brand/pptx/pptx-manifest.json"); fi
    dv "re-$brand-$target" verify --target "$target" --brief "$BRIEF" --composition "$FIX/composition-proof-$brand-v2.json" \
      --theme "$PLUGIN_ROOT/themes/$brand" --artifact "$PROOF/$brand/$target/$artifact" ${manifest[@]+"${manifest[@]}"} \
      --review "$PROOF/review-record.json" --out "$WORK/re-$brand-$target.json"
    ok "re-$brand-$target" 0 "d['verdict'] == 'pass'" \
      && cmp -s <(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1])),sort_keys=True))' "$WORK/re-$brand-$target.json") \
                <(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1])),sort_keys=True))' "$PROOF/$brand/$target/verification.json") \
      || reverify_ok=0
  done
done
if [ "$reverify_ok" -eq 1 ]; then pass "dver-07-proof-preserved"; else fail "dver-07-proof-preserved"; fi

# dver-43: each committed proof output re-renders from its frozen inputs into a scratch directory with the
# fixed ids; the page or deck is byte-identical to the committed one, the scratch plan compares clean
# against the committed plan, and each committed bundle passes check-provenance against its composition,
# plan and output directory. A writer change that alters page or deck bytes turns this red until the proof
# is re-recorded. The deck manifest and provenance are never byte-compared: they record the interpreter.
for brand in boardroom editorial; do
  for target in html pptx; do
    artifact=index.html
    if [ "$target" = pptx ]; then artifact=deck.pptx; fi
    bundle="$PROOF/$brand/$target"
    scratch="$WORK/rerender-$brand-$target"
    composition="$FIX/composition-proof-$brand-v2.json"
    rr_ok=1
    python3 "$RENDER" render --target "$target" --brief "$BRIEF" --composition "$composition" \
      --theme "$PLUGIN_ROOT/themes/$brand" --out "$scratch" "${FIXED[@]}" \
      > "$WORK/rr-render-$brand-$target.out" 2> "$WORK/rr-render-$brand-$target.err" || rr_ok=0
    cmp -s "$scratch/$artifact" "$bundle/$artifact" || rr_ok=0
    python3 "$RENDER" compare --expected "$bundle/target-plan.json" --actual "$scratch/target-plan.json" \
      > "$WORK/rr-compare-$brand-$target.out" 2> "$WORK/rr-compare-$brand-$target.err" || rr_ok=0
    python3 "$RENDER" check-provenance --provenance "$bundle/provenance.json" --composition "$composition" \
      --plan "$bundle/target-plan.json" --out-dir "$bundle" \
      > "$WORK/rr-provenance-$brand-$target.out" 2> "$WORK/rr-provenance-$brand-$target.err" || rr_ok=0
    for step in render compare provenance; do
      [ ! -s "$WORK/rr-$step-$brand-$target.err" ] || rr_ok=0
    done
    if [ "$rr_ok" -eq 1 ]; then pass "dver-43-rerender-$brand-$target"; else fail "dver-43-rerender-$brand-$target"; fi
  done
done

# --- preservation -------------------------------------------------------------------------------------

for target in html pptx; do
  python3 "$RENDER" render --target "$target" --brief "$NBRIEF" --composition "$NCOMP" --theme "$NTHEME" \
    --out "$WORK/narr-$target" > /dev/null 2>&1
done

# dver-08: evidence status is compared where the input carries it — the narrative fixture — and a mutated
# evidence label turns the family red on both targets.
sub "$WORK/narr-html/index.html" "$WORK/narr-evidence.html" 'data-copy="slide-2#evidence_status">direct<' \
  'data-copy="slide-2#evidence_status">inferred<'
deck text "$WORK/narr-pptx/deck.pptx" "$WORK/narr-evidence.pptx" u-slide-2 "copy:slide-2#evidence_status" inferred
dv ev-html preserve --target html --brief "$NBRIEF" --composition "$NCOMP" --artifact "$WORK/narr-html/index.html"
dv ev-html-bad preserve --target html --brief "$NBRIEF" --composition "$NCOMP" --artifact "$WORK/narr-evidence.html"
dv ev-pptx preserve --target pptx --brief "$NBRIEF" --composition "$NCOMP" --artifact "$WORK/narr-pptx/deck.pptx"
dv ev-pptx-bad preserve --target pptx --brief "$NBRIEF" --composition "$NCOMP" --artifact "$WORK/narr-evidence.pptx"
if ok ev-html 0 "d['families']['evidence']['status'] == 'passed' and d['families']['evidence']['expected'] == 5" \
   && ok ev-pptx 0 "d['families']['evidence']['status'] == 'passed'" \
   && ok ev-html-bad 1 "d['families']['evidence']['status'] == 'failed' and d['families']['evidence']['differences'][0]['unit'] == 'u-slide-2'" \
   && ok ev-pptx-bad 1 "d['families']['evidence']['status'] == 'failed'"; then
  pass "dver-08-evidence-status"
else
  fail "dver-08-evidence-status"
fi

# dver-09: dataset values are compared where the input carries data — a changed value label on the page,
# and a changed chart cache in the deck with its workbook untouched, each turn the family red.
sub "$PAGE_B" "$WORK/value.html" '>13.0 million euros<' '>31.0 million euros<' 2
deck cache "$DECK_B" "$WORK/value.pptx" 31.0
dv dv-html preserve --target html --brief "$BRIEF" --composition "$COMP_B" --artifact "$PAGE_B"
dv dv-html-bad preserve --target html --brief "$BRIEF" --composition "$COMP_B" --artifact "$WORK/value.html"
dv dv-pptx preserve --target pptx --brief "$BRIEF" --composition "$COMP_B" --artifact "$DECK_B"
dv dv-pptx-bad preserve --target pptx --brief "$BRIEF" --composition "$COMP_B" --artifact "$WORK/value.pptx"
if ok dv-html 0 "d['families']['data']['status'] == 'passed' and d['families']['data']['expected'] == 4" \
   && ok dv-pptx 0 "d['families']['data']['status'] == 'passed'" \
   && ok dv-html-bad 1 "d['families']['data']['status'] == 'failed' and d['families']['copy']['status'] == 'passed'" \
   && ok dv-pptx-bad 1 "d['families']['data']['status'] == 'failed' and any(x['reference'] == 'chart:u-components' for x in d['families']['data']['differences'])"; then
  pass "dver-09-dataset-values"
else
  fail "dver-09-dataset-values"
fi

# dver-10: a family the input does not carry is reported not-carried, never passed: the direct proof
# brief carries no evidence status and the narrative brief no dataset.
if ok dv-html 0 "d['families']['evidence'] == {'status': 'not-carried', 'expected': 0, 'differences': []}" \
   && ok ev-html 0 "d['families']['data'] == {'status': 'not-carried', 'expected': 0, 'differences': []}"; then
  pass "dver-10-not-carried"
else
  fail "dver-10-not-carried"
fi

# dver-11: frozen copy changed on a delivered page is a copy difference, named by its unit and key.
sub "$PAGE_B" "$WORK/copy.html" '>Move the scheduled budget into condition-based maintenance<' \
  '>Move the scheduled budget into condition-based maintenance now<'
dv copy-bad preserve --target html --brief "$BRIEF" --composition "$COMP_B" --artifact "$WORK/copy.html"
if ok dv-html 0 "d['families']['copy']['status'] == 'passed'" \
   && ok copy-bad 1 "d['families']['copy']['status'] == 'failed' and d['families']['copy']['differences'][0]['unit'] == 'u-answer' and d['families']['copy']['differences'][0]['reference'] == 'answer#title'"; then
  pass "dver-11-frozen-copy"
else
  fail "dver-11-frozen-copy"
fi

# dver-12: a source link lost from a delivered page — its href stripped, its text left — is a sources
# difference on every unit that cites it.
sub "$PAGE_B" "$WORK/link.html" ' href="https://www.vdma.org/condition-monitoring-studie-2025"' '' 0
dv link-bad preserve --target html --brief "$BRIEF" --composition "$COMP_B" --artifact "$WORK/link.html"
if ok dv-html 0 "d['families']['sources']['status'] == 'passed'" \
   && ok link-bad 1 "d['families']['sources']['status'] == 'failed' and {x['reference'] for x in d['families']['sources']['differences']} == {'vdma-2025'} and d['families']['copy']['status'] == 'passed'"; then
  pass "dver-12-source-link-loss"
else
  fail "dver-12-source-link-loss"
fi

# --- geometry and legibility -------------------------------------------------------------------------

geo() {  # geo <label> <target> <artifact> [extra args]
  local label="$1" target="$2" artifact="$3"
  shift 3
  dv "$label" geometry --target "$target" --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$artifact" "$@"
}

# dver-13: a deck frame too short for its text is clipping, a critical finding naming its unit.
deck shrink "$DECK_B" "$WORK/clip.pptx" u-answer "copy:answer#title" 20
geo geo-deck pptx "$DECK_B"
geo clip-bad pptx "$WORK/clip.pptx"
if ok geo-deck 0 "d['coverage']['measured'] == 'package'" \
   && ok clip-bad 1 "[(f['code'], f['class'], f['unit']) for f in d['findings']] == [('text-clipped', 'clipping', 'u-answer')]"; then
  pass "dver-13-clipping"
else
  fail "dver-13-clipping"
fi

# dver-14: two text frames laid over each other are overlap.
deck overlap "$DECK_B" "$WORK/overlap.pptx" u-answer "copy:answer#body" "copy:answer#title"
geo overlap-bad pptx "$WORK/overlap.pptx"
if ok geo-deck 0 && ok overlap-bad 1 "any(f['code'] == 'frames-overlap' and f['class'] == 'overlap' and f['unit'] == 'u-answer' for f in d['findings'])"; then
  pass "dver-14-overlap"
else
  fail "dver-14-overlap"
fi

# dver-15: a replacement or private-use character in delivered text is a missing glyph, on either target.
sub "$PAGE_B" "$WORK/glyph.html" 'condition-based maintenance<' $'condition-based maintenance\xef\xbf\xbd<'
deck text "$DECK_B" "$WORK/glyph.pptx" u-answer "copy:answer#title" $'Move the scheduled budget \xee\x80\x80'
geo geo-page html "$PAGE_B"
geo glyph-page html "$WORK/glyph.html"
geo glyph-deck pptx "$WORK/glyph.pptx"
if ok geo-page 0 "d['coverage']['static'] == 'checked' and d['coverage']['measured'] == 'not-supplied'" \
   && ok glyph-page 1 "any(f['class'] == 'missing-glyph' and 'U+FFFD' in f['message'] for f in d['findings'])" \
   && ok glyph-deck 1 "any(f['class'] == 'missing-glyph' and 'U+E000' in f['message'] for f in d['findings'])"; then
  pass "dver-15-missing-glyph"
else
  fail "dver-15-missing-glyph"
fi

# dver-16: a brand whose muted text no longer clears 4.5:1 on its surfaces fails the contrast requirement,
# and the failure is the critical class unreadable-text. Contrast is computed from the supplied tokens.
mkdir -p "$WORK/pale"
cp -R "$THEME_B" "$WORK/pale/boardroom"
python3 - "$WORK/pale/boardroom/tokens/colors.json" <<'PY'
import json, sys
colors = json.load(open(sys.argv[1]))
colors["text-muted"] = "#C0C6D0"
json.dump(colors, open(sys.argv[1], "w"), indent=2)
PY
dv contrast-ok accessibility --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$PAGE_B"
dv contrast-bad accessibility --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$WORK/pale/boardroom" --artifact "$PAGE_B"
if ok contrast-ok 0 "d['requirements']['contrast']['status'] == 'passed'" \
   && ok contrast-bad 1 "d['requirements']['contrast']['status'] == 'failed' and bool(d['findings']) and all(f['class'] == 'unreadable-text' for f in d['findings'])"; then
  pass "dver-16-unreadable-text"
else
  fail "dver-16-unreadable-text"
fi

# dver-17: a value axis that no longer pins zero, and page bars no longer proportional to their values,
# are misleading encodings.
deck drop-zero "$DECK_B" "$WORK/axis.pptx"
python3 - "$PAGE_B" "$WORK/bars.html" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'(class="mark" data-ref="downtime" x="[0-9.]+" y="[0-9.]+" width=")([0-9.]+)"', text)
text = text[:match.start(2)] + str(round(float(match.group(2)) / 2, 2)) + text[match.end(2):]
open(sys.argv[2], "w", encoding="utf-8").write(text)
PY
geo axis-bad pptx "$WORK/axis.pptx"
geo bars-bad html "$WORK/bars.html"
if ok geo-deck 0 && ok geo-page 0 \
   && ok axis-bad 1 "[(f['code'], f['class']) for f in d['findings']] == [('axis-not-zero', 'misleading-encoding')]" \
   && ok bars-bad 1 "any(f['class'] == 'misleading-encoding' and f['unit'] == 'u-components' for f in d['findings'])"; then
  pass "dver-17-misleading-encoding"
else
  fail "dver-17-misleading-encoding"
fi

# dver-18: one critical finding among otherwise clean units fails the whole verification; every finding
# keeps its unit, target and brand, and no report field is a rate, average, score or threshold.
dv verdict-ok verify --target pptx --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$DECK_B" \
  --out "$WORK/verdict-ok.json"
dv verdict-bad verify --target pptx --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" \
  --artifact "$WORK/overlap.pptx" --out "$WORK/verdict-bad.json"
if ok verdict-ok 0 "d['verdict'] == 'pass' and d['findings'] == []" \
   && ok verdict-bad 1 "d['verdict'] == 'fail' and d['findings'] and all(f['class'] == 'overlap' and f['unit'] == 'u-answer' and f['target'] == 'pptx' and f['brand'] == 'boardroom' for f in d['findings'])" \
   && python3 - "$WORK/verdict-bad.json" "$WORK/verdict-ok.json" <<'PY'
import json, sys
def keys(value):
    if isinstance(value, dict):
        for key, item in value.items():
            yield key
            yield from keys(item)
    elif isinstance(value, list):
        for item in value:
            yield from keys(item)
for path in sys.argv[1:]:
    report = json.load(open(path))
    banned = {k for k in keys(report) if any(word in k for word in ("rate", "average", "score", "threshold", "percent"))}
    assert not banned, banned
    families = report["checks"]["preservation"]["families"]
    assert all(f["status"] in ("passed", "not-carried") for f in families.values())
PY
then pass "dver-18-critical-blocks"; else fail "dver-18-critical-blocks"; fi

# --- editability and accessibility -------------------------------------------------------------------

# dver-19: copy or a chart delivered as a picture is a flattened substitution; the clean deck is native.
deck flatten "$DECK_B" "$WORK/flat-copy.pptx" u-answer "copy:answer#title"
deck flatten "$DECK_B" "$WORK/flat-chart.pptx" u-components "chart:u-components"
dv edit-ok editability --brief "$BRIEF" --composition "$COMP_B" --pptx "$DECK_B"
dv edit-copy editability --brief "$BRIEF" --composition "$COMP_B" --pptx "$WORK/flat-copy.pptx"
dv edit-chart editability --brief "$BRIEF" --composition "$COMP_B" --pptx "$WORK/flat-chart.pptx"
if ok edit-ok 0 "all(o['native'] for o in d['objects']) and not any(o['kind'] == 'image' for o in d['objects'])" \
   && ok edit-copy 1 "any(f['code'] == 'flattened-substitution' and f['unit'] == 'u-answer' for f in d['findings'])" \
   && ok edit-chart 1 "any(f['code'] == 'flattened-substitution' and f['unit'] == 'u-components' for f in d['findings'])"; then
  pass "dver-19-editability"
else
  fail "dver-19-editability"
fi

# dver-20: the text and chart edit witnesses edit the deck, read both edits back, reproduce the committed
# witnesses exactly, and fail on a deck whose chart is a picture.
if ok edit-ok 0 "[w['status'] for w in d['witnesses']] == ['passed', 'passed'] and [w['kind'] for w in d['witnesses']] == ['text', 'chart']" \
   && ok edit-chart 1 "any(w['kind'] == 'chart' and w['status'] == 'failed' for w in d['witnesses'])" \
   && [ "$(q edit-ok "json.dumps(d['witnesses'], sort_keys=True)")" = \
        "$(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1]))["checks"]["editability"]["witnesses"], sort_keys=True))' "$PROOF/boardroom/pptx/verification.json")" ]; then
  pass "dver-20-edit-witness"
else
  fail "dver-20-edit-witness"
fi

# dver-21: a chart frame without its text alternative, and a page figure without its description, fail
# the required alt-descriptions capability; a capability declared unsupported is reported unsupported,
# never passed — the committed pptx slide titles, and a supplied declaration's html non-colour cue.
deck strip-descr "$DECK_B" "$WORK/nodescr.pptx" u-components "chart:u-components"
sub "$PAGE_B" "$WORK/nodescr.html" ' aria-describedby="data-u-components"' ''
python3 - "$PLUGIN_ROOT/references/verify-capabilities.json" "$WORK/declaration.json" <<'PY'
import json, sys
declaration = json.load(open(sys.argv[1]))
declaration["targets"]["html"]["requirements"]["non-color"] = {"status": "unsupported", "reason": "declared for this case"}
json.dump(declaration, open(sys.argv[2], "w"))
PY
dv a11y-deck accessibility --target pptx --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$DECK_B"
dv a11y-deck-bad accessibility --target pptx --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$WORK/nodescr.pptx"
dv a11y-page-bad accessibility --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$WORK/nodescr.html"
dv a11y-declared accessibility --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --artifact "$PAGE_B" \
  --capabilities "$WORK/declaration.json"
if ok a11y-deck 0 "d['requirements']['alt-descriptions']['status'] == 'passed' and d['requirements']['slide-titles']['status'] == 'unsupported' and bool(d['requirements']['slide-titles']['reason'])" \
   && ok a11y-deck-bad 1 "d['requirements']['alt-descriptions']['status'] == 'failed' and d['findings'][0]['code'] == 'description-missing'" \
   && ok a11y-page-bad 1 "d['requirements']['alt-descriptions']['status'] == 'failed'" \
   && ok a11y-declared 0 "d['requirements']['non-color'] == {'status': 'unsupported', 'reason': 'declared for this case'}"; then
  pass "dver-21-accessibility"
else
  fail "dver-21-accessibility"
fi

# dver-44: renderer check modules cannot contribute verification evidence. Poison their imports,
# verify a pristine artifact, then corrupt the frozen title and require an independent copy finding.
for target in html pptx; do
  if python3 - "$SCRIPTS" "$BRIEF" "$COMP_B" "$THEME_B" "$PROOF/boardroom/$target" "$target" <<'PYCASE'
import copy, importlib.abc, io, json, re, sys, zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
scripts, brief_path, comp_path, theme_path, bundle, target = sys.argv[1:]
class NoRendererChecks(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if fullname in {"render_checks", "pptx_checks", "html_adapter", "pptx_adapter", "cogni_publishing_design_render"}:
            raise AssertionError("verification attempted to load " + fullname)
sys.meta_path.insert(0, NoRendererChecks())
sys.path.insert(0, scripts)
import verify_checks as checks
import render_core as core
brief = json.loads(Path(brief_path).read_text())
composition = json.loads(Path(comp_path).read_text())
library, _ = core.validate_inputs(brief, composition)
theme = core.resolve_theme(theme_path, composition["design_system"])
_, font = core.resolve_fonts(theme, embed_faces=target == "html")
capabilities = checks.load_capabilities(Path(scripts).parent / "references/verify-capabilities.json")
name = "index.html" if target == "html" else "deck.pptx"
data = (Path(bundle) / name).read_bytes()
def report(payload):
    return checks.build_report(target, "boardroom", name, payload, brief, composition, theme, font, library, capabilities)
assert report(data)["verdict"] == "pass"
title = brief["document"]["title"].encode()
if target == "html":
    assert title in data
    damaged = data.replace(title, b"Altered frozen title")
else:
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        parts = [(n, archive.read(n)) for n in archive.namelist()]
    assert title in dict(parts)["ppt/slides/slide1.xml"]
    damaged = checks.fixed_zip([(n, p.replace(title, b"Altered frozen title") if n == "ppt/slides/slide1.xml" else p) for n, p in parts])
result = report(damaged)
assert result["verdict"] == "fail" and any(f["code"] == "copy-differs" for f in result["findings"])
def rejects(payload, code):
    result = report(payload)
    assert result["verdict"] == "fail" and any(f["code"] == code for f in result["findings"]), (code, result["findings"])
if target == "html":
    rejects(data.replace(b"</body>", b"<p>Invented</p></body>"), "invented-text")
    rejects(data.replace(b"</body>", b'<p data-copy="invented#body">Invented</p></body>'), "copy-inventory")
    rejects(data.replace(b"Fraunhofer IPA", b"Invented Publisher"), "copy-inventory")
    first, second = [core.Content(brief).sources[r]["url"].encode() for r in core.Content(brief).source_order[:2]]
    swapped = data.replace(b'href="' + first + b'"', b'href="TEMP"').replace(b'href="' + second + b'"', b'href="' + first + b'"').replace(b'href="TEMP"', b'href="' + second + b'"')
    rejects(swapped, "citation-substituted")
    rejects(data.replace(b"</style>", b"* {color:#fff!important;background:#fff!important;}</style>"), "css-literal")
else:
    rejects(checks.fixed_zip([(n, re.sub(rb'<a:stCxn[^>]*/>', b'', p)) for n, p in parts]), "system-semantics")
    rejects(checks.fixed_zip([(n, p.replace(b"Fraunhofer IPA", b"Invented Publisher")) for n, p in parts]), "source-register")
    rejects(checks.fixed_zip([(n, p) for n, p in parts if n != "[Content_Types].xml"]), "package-content-type")
    changed_cite = []
    for n, payload in parts:
        if n == "ppt/slides/slide2.xml":
            tree = ET.fromstring(payload)
            cite = next(s for s in checks.shapes_of(tree) if checks.props(s)[1].startswith("cites:"))
            next(cite.iter(checks.A + "t")).text = "Invented"
            payload = ET.tostring(tree)
        changed_cite.append((n, payload))
    rejects(checks.fixed_zip(changed_cite), "invented-text")
    extra_series = []
    changed = False
    for n, payload in parts:
        if n.startswith("ppt/charts/") and n.endswith(".xml"):
            tree = ET.fromstring(payload)
            bar = tree.find(f".//{checks.C}barChart")
            if bar is not None:
                bar.append(copy.deepcopy(bar.find(checks.C + "ser")))
                payload = ET.tostring(tree)
                changed = True
        extra_series.append((n, payload))
    assert changed
    rejects(checks.fixed_zip(extra_series), "chart-native")
PYCASE
  then pass "dver-44-independent-$target"; else fail "dver-44-independent-$target"; fi
done

# --- the persisted records -----------------------------------------------------------------------------

# dver-22: the review record holds a full-resolution entry per unit, target and brand plus one overview
# per brand and target; a record missing an entry or an overview, one with a bare verdict, one whose
# entry names nothing it checked, one whose entry records another artifact digest, one whose overview
# records another capture digest than its committed file, and one whose overview names no capture file
# are each refused. The doctored records sit beside a copy of the committed overview files.
dv review check-review --record "$PROOF/review-record.json" --proof "$PROOF/proof-manifest.json"
mkdir -p "$WORK/rev"
cp -R "$PROOF/overview" "$WORK/rev/"
python3 - "$PROOF/review-record.json" "$WORK/rev" <<'PY'
import copy, json, sys
record = json.load(open(sys.argv[1]))
def write(name, value):
    json.dump(value, open(f"{sys.argv[2]}/{name}.json", "w"))
write("review-clean", record)
a = copy.deepcopy(record); a["entries"].pop(); write("review-missing", a)
for brand in ("boardroom", "editorial"):
    missing = copy.deepcopy(record)
    missing["entries"] = [e for e in missing["entries"] if not (e["brand"] == brand and e["target"] == "pptx" and e["unit"] == "document")]
    write("review-no-cover-" + brand, missing)
b = copy.deepcopy(record); b["overviews"].pop(); write("review-no-overview", b)
c = copy.deepcopy(record); c["verdict"] = "excellent"; write("review-verdict", c)
d = copy.deepcopy(record); d["entries"][0]["checked"] = []; write("review-unchecked", d)
e = copy.deepcopy(record); e["entries"] = []; e["quality"] = "great"; write("review-bare", e)
f = copy.deepcopy(record); f["entries"][0]["artifact"]["sha256"] = "sha256:" + "0" * 64; write("review-stale-artifact", f)
g = copy.deepcopy(record); g["overviews"][0]["capture"]["sha256"] = "sha256:" + "0" * 64; write("review-stale-overview", g)
h = copy.deepcopy(record); del h["overviews"][1]["capture"]["file"]; write("review-no-overview-file", h)
PY
for variant in no-cover-boardroom no-cover-editorial clean missing no-overview verdict unchecked bare stale-artifact stale-overview no-overview-file; do
  dv "review-$variant" check-review --record "$WORK/rev/review-$variant.json" --proof "$PROOF/proof-manifest.json"
done
if ok review-no-cover-boardroom 1 "any(f['code'] == 'review-incomplete' and f['unit'] == 'boardroom/pptx/document' for f in d['findings'])" \
   && ok review-no-cover-editorial 1 "any(f['code'] == 'review-incomplete' and f['unit'] == 'editorial/pptx/document' for f in d['findings'])" \
   && ok review 0 "d['entries'] == 22 and d['overviews'] == 4" \
   && ok review-clean 0 "d['entries'] == 22 and d['overviews'] == 4" \
   && ok review-missing 1 "any(f['code'] == 'review-incomplete' for f in d['findings'])" \
   && ok review-no-overview 1 "any(f['code'] == 'review-incomplete' for f in d['findings'])" \
   && ok review-verdict 1 "any(f['code'] == 'unqualified-verdict' for f in d['findings'])" \
   && ok review-unchecked 1 "any(f['code'] == 'review-malformed' for f in d['findings'])" \
   && ok review-bare 1 "{'unqualified-verdict', 'review-incomplete'} <= {f['code'] for f in d['findings']}" \
   && ok review-stale-artifact 1 "[(x['code'], x['unit']) for x in d['findings']] == [('review-stale', 'boardroom/html/u-answer')]" \
   && ok review-stale-overview 1 "[(x['code'], x['unit']) for x in d['findings']] == [('review-stale', 'boardroom/html/overview')]" \
   && ok review-no-overview-file 1 "[(x['code'], x['unit']) for x in d['findings']] == [('review-malformed', 'boardroom/pptx/overview')]"; then
  pass "dver-22-review-record"
else
  fail "dver-22-review-record"
fi

# dver-23: the specimen index resolves every proof pattern to rendered examples on both targets for both
# brands, each locator naming its unit inside its own file, and records each pattern's unsuitable uses
# with reasons; an unresolved pattern, a missing target example, an unsuitable use without its reason, a
# page locator naming no unit section, a slide locator naming another slide's unit, an example path
# naming no file and a pattern with no unsuitable use of its own are each refused.
dv specimens check-specimens --index "$PROOF/specimens.json" --proof "$PROOF/proof-manifest.json"
mkdir -p "$WORK/spec"
cp -R "$PROOF/boardroom" "$PROOF/editorial" "$WORK/spec/"
python3 - "$PROOF/specimens.json" "$WORK/spec" <<'PY'
import copy, json, sys
index = json.load(open(sys.argv[1]))
def write(name, value):
    json.dump(value, open(f"{sys.argv[2]}/{name}.json", "w"))
write("clean", index)
a = copy.deepcopy(index); a["patterns"] = [p for p in a["patterns"] if p["pattern"] != "sourced-chart"]; write("unresolved", a)
b = copy.deepcopy(index)
for p in b["patterns"]:
    if p["pattern"] == "comparison":
        p["examples"] = [e for e in p["examples"] if e["target"] != "pptx"]
write("no-target", b)
c = copy.deepcopy(index); c["patterns"][0]["unsuitable"][0]["reason"] = ""; write("no-reason", c)
def pattern(value, name):
    return next(p for p in value["patterns"] if p["pattern"] == name)
def example(value, name, brand, target):
    return next(e for e in pattern(value, name)["examples"] if (e["brand"], e["target"]) == (brand, target))
d = copy.deepcopy(index); example(d, "answer-emphasis", "editorial", "html")["locator"] = "#unit-u-nonexistent"
write("bogus-page", d)
e = copy.deepcopy(index); example(e, "answer-emphasis", "boardroom", "pptx")["locator"] = "slide 3 (u-answer)"
write("bogus-slide", e)
f = copy.deepcopy(index); example(f, "answer-emphasis", "boardroom", "html")["artifact"] = "boardroom/html/absent.html"
write("no-artifact", f)
g = copy.deepcopy(index); pattern(g, "sources")["unsuitable"] = []; write("no-unsuitable", g)
PY
for variant in clean unresolved no-target no-reason bogus-page bogus-slide no-artifact no-unsuitable; do
  dv "spec-$variant" check-specimens --index "$WORK/spec/$variant.json" --proof "$PROOF/proof-manifest.json"
done
if ok specimens 0 "d['patterns'] == 5" && ok spec-clean 0 \
   && ok spec-unresolved 1 "any(f['code'] == 'specimen-unresolved' and f['unit'] == 'sourced-chart/bar' for f in d['findings'])" \
   && ok spec-no-target 1 "any(f['code'] == 'specimen-target-missing' for f in d['findings'])" \
   && ok spec-no-reason 1 "any(f['code'] == 'specimen-reason-missing' for f in d['findings'])" \
   && ok spec-bogus-page 1 "[(x['code'], x['unit']) for x in d['findings']] == [('specimen-unresolved', 'answer-emphasis/statement')]" \
   && ok spec-bogus-slide 1 "[(x['code'], x['unit']) for x in d['findings']] == [('specimen-unresolved', 'answer-emphasis/statement')]" \
   && ok spec-no-artifact 1 "[(x['code'], x['unit']) for x in d['findings']] == [('specimen-unresolved', 'answer-emphasis/statement')]" \
   && ok spec-no-unsuitable 1 "[(x['code'], x['unit']) for x in d['findings']] == [('specimen-reason-missing', 'sources/register')]"; then
  pass "dver-23-specimens"
else
  fail "dver-23-specimens"
fi

# --- the repair loop ------------------------------------------------------------------------------------

FINGERPRINT="$(python3 - "$SCRIPTS" "$WORK/unfit.json" <<'PY'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("validator", sys.argv[1] + "/validate-publishing.py")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)
print(validator.content_fingerprint(json.load(open(sys.argv[2]))))
PY
)"
loop() {  # loop <label> <brief> <composition> <target> [extra args]
  local label="$1" brief="$2" composition="$3" target="$4"
  shift 4
  dv "$label" render-verified --target "$target" --brief "$brief" --composition "$composition" --theme "$THEME_B" \
    --out "$WORK/$label-out" "${FIXED[@]}" "$@"
}

# dver-24: the deliberately unfit fixture returns a bounded failure: at least one repair, no more than the
# budget, each changing only the unit's variant; the fingerprint is the frozen brief's before and after,
# the unit ids never change, nothing is written, and the result equals the committed repair record.
loop unfit "$WORK/unfit.json" "$FIX/composition-unfit-v2.json" pptx
if ok unfit 1 "d['code'] == 'repair-exhausted' and 1 <= d['repairs_used'] <= d['budget'] == 3 and d['history'][0]['changes'] == [] and all(c['unit'] == 'u-options' and c['before'].split('/')[0] == c['after'].split('/')[0] == 'comparison' for h in d['history'] for c in h['changes']) and d['units']['before'] == d['units']['after'] == ['u-answer', 'u-options', 'u-sources']" \
   && [ "$(q unfit "sorted(set(d['content_fingerprint'].values()))")" = "['$FINGERPRINT']" ] \
   && [ ! -e "$WORK/unfit-out" ] \
   && [ "$(q unfit "json.dumps(e, sort_keys=True)")" = \
        "$(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1]))["envelope"], sort_keys=True))' "$PROOF/repair-unfit.json")" ]; then
  pass "dver-24-repair-unfit"
else
  fail "dver-24-repair-unfit"
fi

# dver-25: a budget of zero allows no repair: one attempt, then a bounded failure.
loop budget0 "$WORK/unfit.json" "$FIX/composition-unfit-v2.json" pptx --budget 0
if ok budget0 1 "d['stopped'] == 'budget-exhausted' and d['repairs_used'] == 0 and len(d['history']) == 1"; then
  pass "dver-25-repair-budget-zero"
else
  fail "dver-25-repair-budget-zero"
fi

# dver-26: render-verified on the proof passes with no repair and writes the committed deck byte for byte,
# with the composition it rendered and its report.
loop proofloop "$BRIEF" "$COMP_B" pptx
if ok proofloop 0 "d['verdict'] == 'pass' and d['repairs_used'] == 0 and d['changes'] == []" \
   && cmp -s "$WORK/proofloop-out/deck.pptx" "$DECK_B" \
   && python3 - "$WORK/proofloop-out" "$COMP_B" <<'PY'
import json, sys
out, composition = sys.argv[1:]
assert json.load(open(f"{out}/composition.json")) == json.load(open(composition))
assert json.load(open(f"{out}/verification.json"))["verdict"] == "pass"
history = json.load(open(f"{out}/repair-history.json"))
assert history["repairs_used"] == 0 and history["content_fingerprint"]["frozen"] == history["content_fingerprint"]["after"]
PY
then pass "dver-26-render-verified-proof"; else fail "dver-26-render-verified-proof"; fi

# dver-27: a brief whose frozen content changed after composition is refused before any render, with
# nothing written; and every candidate composition passes the one repair contract, check-repair.
python3 - "$BRIEF" "$WORK/changed.json" <<'PY'
import json, sys
brief = json.load(open(sys.argv[1]))
next(r for r in brief["records"] if r["id"] == "answer")["title"] += " now"
json.dump(brief, open(sys.argv[2], "w"))
PY
loop changed "$WORK/changed.json" "$COMP_B" html
if ok changed 1 "d['code'] == 'copy-changed' and d['reference'] == 'answer#title'" && [ ! -e "$WORK/changed-out" ] \
   && [ "$(grep -c 'core.validator.check_repair(brief, original, repaired, library)' "$VERIFY")" = "1" ]; then
  pass "dver-27-repair-content-refused"
else
  fail "dver-27-repair-content-refused"
fi

# dver-28: the budget is a whole number from 0 to 10, and every attempt needs fixed ids.
budget_ok=1
for value in -1 11 many; do
  loop "budget-$value" "$BRIEF" "$COMP_B" html --budget "$value"
  ok "budget-$value" 2 "d['code'] == 'usage-error'" || budget_ok=0
done
dv noids render-verified --target html --brief "$BRIEF" --composition "$COMP_B" --theme "$THEME_B" --out "$WORK/noids"
ok noids 2 "d['code'] == 'usage-error'" || budget_ok=0
if [ "$budget_ok" -eq 1 ] && [ "$(python3 -c 'import re,sys;print(re.search(r"^DEFAULT_REPAIR_BUDGET = ([0-9]+)$", open(sys.argv[1]).read(), re.M).group(1))' "$VERIFY")" = "3" ]; then
  pass "dver-28-budget-usage"
else
  fail "dver-28-budget-usage"
fi

# --- prose rules, held by their shape -------------------------------------------------------------------

anchored() {  # anchored <id> <file> <line start>: the rule starts a line exactly once
  if [ "$(grep -c "^$3" "$2")" = "1" ]; then pass "$1"; else fail "$1"; fi
}
anchored "dver-29-skill-full-resolution" "$SKILL" "Inspect every unit at full resolution, on every target and brand"
anchored "dver-30-skill-deck-overview" "$SKILL" "Review one deck overview per brand and target"
anchored "dver-31-skill-critical-blocks" "$SKILL" "An open critical finding blocks success"
anchored "dver-32-skill-qualified-verdict" "$SKILL" "Never record an unqualified quality verdict"
anchored "dver-33-skill-frozen-content" "$SKILL" "A repair never alters frozen content"
anchored "dver-34-render-wiring" "$RSKILL" "After every render, run design-verify on the output and report success only when its verdict passes"
anchored "dver-40-render-repair-report" "$RSKILL" "When verification fails, repair within the budget and report the findings and repair history of a bounded failure, never a success"
anchored "dver-41-render-frozen-copy" "$RSKILL" "Never rewrite, shorten, add, drop or reorder copy or units to make a unit fit, and never hand a finding to a copywriting skill"
anchored "dver-42-skill-repair-budget" "$SKILL" "The repair budget defaults to 3 and is never more than 10; a repair past the budget is never attempted"

# dver-35: the committed proof binaries stay bounded.
if python3 - "$PROOF" <<'PY'
import os, sys
sizes = [os.path.getsize(os.path.join(d, f)) for d, _, files in os.walk(sys.argv[1]) for f in files
         if f.endswith((".png", ".pdf", ".pptx"))]
assert 0 < len(sizes) <= 8 and max(sizes) <= 512000 and sum(sizes) <= 1200000, sizes
PY
then pass "dver-35-binary-budget"; else fail "dver-35-binary-budget"; fi

# dver-36: the evidence records the Claude Design handoff comparison without depending on the service.
if [ "$(grep -c '^## Claude Design handoff comparison$' "$EVIDENCE")" = "1" ] \
   && grep -q 'No actual Claude Design reference output exists for this brief' "$EVIDENCE" \
   && ! grep -q 'claude\.ai' "$SCRIPTS/verify_checks.py" "$SCRIPTS/design-verify.py" "$SKILL"; then
  pass "dver-36-claude-design-section"
else
  fail "dver-36-claude-design-section"
fi

# dver-37: every command answers a usage error with one envelope, exit 2 and nothing on stderr.
envelope_ok=1
for command in preserve editability accessibility geometry verify check-review check-specimens check-proof render-verified; do
  dv "usage-$command" "$command"
  ok "usage-$command" 2 "e['success'] is False and d['code'] == 'usage-error'" \
    && [ "$(wc -l < "$WORK/usage-$command.out" | tr -d ' ')" = "1" ] || envelope_ok=0
done
dv usage-none
ok usage-none 2 "d['code'] == 'usage-error'" || envelope_ok=0
if [ "$envelope_ok" -eq 1 ]; then pass "dver-37-envelope"; else fail "dver-37-envelope"; fi

# dver-38: a supplied measurement report is graded: its clipped copy and overlapping slot boxes are
# findings, and the coverage says the page was measured.
python3 - "$WORK" <<'PY'
import json, sys
work = sys.argv[1]
unit = {"unit": "u-answer", "slots": [{"slot": "answer", "box": {"x": 40, "y": 40, "width": 1200, "height": 120}},
                                      {"slot": "support", "box": {"x": 40, "y": 180, "width": 1200, "height": 60}}]}
json.dump({"clipped": [], "units": [unit]}, open(f"{work}/report-clean.json", "w"))
json.dump({"clipped": ["answer#title"], "units": [unit]}, open(f"{work}/report-clipped.json", "w"))
crowded = json.loads(json.dumps(unit))
crowded["slots"][1]["box"]["y"] = 100
json.dump({"clipped": [], "units": [crowded]}, open(f"{work}/report-overlap.json", "w"))
PY
geo measured-clean html "$PAGE_B" --browser-report "$WORK/report-clean.json"
geo measured-clipped html "$PAGE_B" --browser-report "$WORK/report-clipped.json"
geo measured-overlap html "$PAGE_B" --browser-report "$WORK/report-overlap.json"
if ok measured-clean 0 "d['coverage']['measured'] == 'checked'" \
   && ok measured-clipped 1 "[(f['code'], f['class']) for f in d['findings']] == [('text-clipped', 'clipping')]" \
   && ok measured-overlap 1 "[(f['code'], f['class'], f['unit']) for f in d['findings']] == [('slots-overlap', 'overlap', 'u-answer')]"; then
  pass "dver-38-measured-clipping"
else
  fail "dver-38-measured-clipping"
fi

# dver-39: a repairable unit is repaired: three options side by side at heading size overflow the slide
# as columns and fit as rows, so render-verified changes only that unit's variant and passes.
cat > "$WORK/options.json" <<'JSON'
{
  "artifact_type": "direct-brief",
  "artifact_version": "1",
  "artifact_id": "maintenance-options",
  "title": "Three maintenance options",
  "structure": {"framework": "pyramid"},
  "sections": [
    {"id": "option-1", "role": "option", "title": "Option 1",
     "body": "Scheduled intervals keep technicians busy on healthy assets while the failing ones wait for attention and the plant pays for it; scheduled intervals keep technicians busy on healthy assets while the",
     "source_refs": ["vdma-2025"]},
    {"id": "option-2", "role": "option", "title": "Option 2", "body": "Short option 2", "source_refs": ["vdma-2025"]},
    {"id": "option-3", "role": "option", "title": "Option 3", "body": "Short option 3", "source_refs": ["vdma-2025"]}
  ],
  "sources": [{"id": "vdma-2025", "publisher": "VDMA", "title": "Condition-Monitoring-Studie 2025",
               "url": "https://www.vdma.org/condition-monitoring-studie-2025"}]
}
JSON
cat > "$WORK/options-draft.json" <<'JSON'
{
  "artifact_type": "semantic-composition",
  "artifact_version": "2",
  "artifact_id": "composition:maintenance-options",
  "normalized_brief_ref": {"artifact_id": "normalized:maintenance-options", "artifact_version": "1"},
  "pattern_library_ref": {"artifact_id": "cogni-publishing/pattern-library", "artifact_version": "1"},
  "design_system": {"name": "boardroom", "version": "0.0.16"},
  "targets": ["html", "pptx"],
  "units": [
    {"id": "u-options", "role": "options", "pattern": "comparison", "variant": "parallel", "type_floor": "type.heading",
     "bindings": [{"slot": "items", "record_ref": "option-1", "field": "title"}, {"slot": "items", "record_ref": "option-1", "field": "body"},
                  {"slot": "items", "record_ref": "option-2", "field": "title"}, {"slot": "items", "record_ref": "option-2", "field": "body"},
                  {"slot": "items", "record_ref": "option-3", "field": "title"}, {"slot": "items", "record_ref": "option-3", "field": "body"}]},
    {"id": "u-sources", "role": "source-register", "pattern": "sources", "variant": "register", "bindings": []}
  ],
  "document_bindings": []
}
JSON
python3 "$VALIDATOR" normalize --kind direct --input "$WORK/options.json" > "$WORK/options-norm.out" 2> /dev/null
python3 -c 'import json,sys;json.dump(json.load(open(sys.argv[1]))["data"],open(sys.argv[2],"w"),ensure_ascii=False)' \
  "$WORK/options-norm.out" "$WORK/options-brief.json"
python3 "$VALIDATOR" compose --brief "$WORK/options-brief.json" --composition "$WORK/options-draft.json" > "$WORK/options-comp.out" 2> /dev/null
python3 -c 'import json,sys;json.dump(json.load(open(sys.argv[1]))["data"],open(sys.argv[2],"w"),ensure_ascii=False)' \
  "$WORK/options-comp.out" "$WORK/options-comp.json"
loop repair "$WORK/options-brief.json" "$WORK/options-comp.json" pptx
if ok repair 0 "d['repairs_used'] == 1 and d['changes'] == [{'unit': 'u-options', 'before': 'comparison/parallel', 'after': 'comparison/tabular'}] and d['content_fingerprint']['frozen'] == d['content_fingerprint']['after']" \
   && python3 - "$WORK/options-comp.json" "$WORK/repair-out/composition.json" <<'PY'
import json, sys
before, after = (json.load(open(p)) for p in sys.argv[1:])
assert after["units"][0]["variant"] == "tabular"
after["units"][0]["variant"] = "parallel"
assert before == after
PY
then pass "dver-39-repair-succeeds"; else fail "dver-39-repair-succeeds"; fi

printf '%s passed, %s failed\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
