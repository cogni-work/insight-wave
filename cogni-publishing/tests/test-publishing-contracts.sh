#!/usr/bin/env bash
# Contract suite for cogni-publishing: brief normalization, artifact-chain validation,
# configuration precedence, and the standalone/minimal-runtime boundary.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `pubc`; NN is an
# allocation counter, so never renumber an existing id — the mutation recipes below
# record them.
#
# The narrative fixture is cogni-workspace/tests/fixtures/design-brief/slides-en.md,
# byte-for-byte, plus one `evidence_status:` line on slides 2-6 (one per label) so the
# evidence metadata is exercised; it still passes check-design-brief.py. The expected
# file is that fixture's normalized output, cross-checked by pubc-02's independent
# slicing before it was frozen.
#
# Mutation recipes (run from the repository root; the harness is the installed
# managed-service cogni-service plugin, and --expr is evaluated by perl -0pi):
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return artifact_version in supported_versions/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-04-invalid-version
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return reference_id in available_ids/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-05-dangling-reference
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return subtitle\[1:-1\]/return subtitle/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-24-subtitle-emphasis-strip
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/frontmatter\[key\] = items if saw_item else \(mapping if saw_pair else None\)/frontmatter[key] = items if items else mapping/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-31-key-figures-empty-block
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if field in declared and declared\[field\] is None:/if False:/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-32-design-field-declared-empty
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if subtitle\[0\] in subtitle\[1:-1\]:/if False:/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-33-subtitle-two-spans-unchanged
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-publishing.py"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
passes=0
failures=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# check_rejection <case-id> <exit> <code> <check|-> <reference|-> <validator args...>
# A rejection must exit with the stated status, write nothing to stderr, answer with one
# envelope naming the failed check and offending reference, and carry no artifact.
check_rejection() {
  local id="$1" want="$2" code="$3" check="$4" ref="$5" rc=0
  shift 5
  python3 "$VALIDATOR" "$@" > "$WORK/$id.out" 2> "$WORK/$id.err" || rc=$?
  if [ "$rc" -eq "$want" ] && [ ! -s "$WORK/$id.err" ] &&
     python3 - "$WORK/$id.out" "$code" "$check" "$ref" <<'PY'
import json, sys
path, code, check, ref = sys.argv[1:]
with open(path, encoding="utf-8") as fh:
    lines = fh.read().splitlines()
assert len(lines) == 1, "exactly one envelope"
env = json.loads(lines[0])
assert set(env) == {"success", "data", "error"} and env["success"] is False and env["error"]
data = env["data"]
assert data["code"] == code, data
assert check == "-" or data.get("check") == check, data
assert ref == "-" or str(data.get("reference")) == ref, data
assert set(data) <= {"code", "check", "artifact", "reference"}, data
PY
  then pass "$id"; else fail "$id"; fi
}

python3 "$VALIDATOR" normalize --kind narrative --input "$FIXTURES/narrative-slides-v1.md" > "$WORK/narrative.json"
python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/direct-consult-v1.json" > "$WORK/direct.json"

# pubc-01: every headline, field (in order), slide point, talk track, evidence label,
# citation, source record, contract clause, trailer note and unit position is unchanged.
if python3 - "$WORK/narrative.json" "$FIXTURES/narrative-slides-v1.expected.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
expected = json.load(open(sys.argv[2], encoding="utf-8"))
assert env["success"] is True and env["error"] is None
actual = env["data"]
families = {
    "unit order": lambda d: [(r["id"], r["order"]) for r in d["records"]],
    "headlines": lambda d: [r["headline"] for r in d["records"]],
    "field order": lambda d: [[f["key"] for f in r["fields"]] for r in d["records"]],
    "field values": lambda d: [[f["value"] for f in r["fields"]] for r in d["records"]],
    "slide points": lambda d: [[f["value"] for f in r["fields"] if f["key"] == "slide_points"] for r in d["records"]],
    "talk tracks": lambda d: [[f["value"] for f in r["fields"] if f["key"] == "talk_track"] for r in d["records"]],
    "evidence status": lambda d: [[f["value"] for f in r["fields"] if f["key"] == "evidence_status"] for r in d["records"]],
    "citations": lambda d: [r["source_refs"] for r in d["records"]],
    "source records": lambda d: d["sources"],
    "freeze": lambda d: d["freeze"],
    "provenance": lambda d: d["provenance"],
}
for name, pick in families.items():
    assert pick(actual) == pick(expected), f"{name} changed"
assert actual == expected, "normalized artifact differs from the frozen expectation"
PY
then pass "pubc-01-narrative-fidelity"; else fail "pubc-01-narrative-fidelity"; fi

# pubc-02: an oracle independent of the expected file — each record's raw text is the exact
# slice of the source brief, and every value sits inside that slice in the order read.
if python3 - "$WORK/narrative.json" "$FIXTURES/narrative-slides-v1.md" <<'PY'
import json, re, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))["data"]
source = open(sys.argv[2], encoding="utf-8").read()
slices = source.split("\n## Slide ")[1:]
slices[-1] = slices[-1].split("\nnote: ")[0]
assert len(slices) == len(data["records"])
for record, piece in zip(data["records"], slices):
    block = ("## Slide " + piece).rstrip("\n")
    assert record["raw"] == block, record["id"]
    assert [f["key"] for f in record["fields"]] == re.findall(r"^([a-z_]+):", block, re.M), record["id"]
    cursor = 0
    for field in record["fields"]:
        values = field["value"] if field["kind"] == "list" else [field["value"]]
        if field["kind"] == "mapping":
            values = [item["value"] for item in field["value"]]
        for value in values:
            found = block.find(value, cursor)
            assert found >= cursor, (record["id"], field["key"], value[:40])
            cursor = found + len(value)
body = [line for line in source.split("**Sources**\n", 1)[1].split("\n") if line.strip()]
assert [s["raw"] for s in data["sources"]] == body
assert data["freeze"]["trailer_notes"] == re.findall(r"^note: (.*)$", source, re.M)
PY
then pass "pubc-02-narrative-raw-slices"; else fail "pubc-02-narrative-raw-slices"; fi

sed 's/^target: slides$/target: document/' "$FIXTURES/narrative-slides-v1.md" > "$WORK/narrative-document.md"
check_rejection "pubc-03-narrative-unsupported-target" 1 unsupported-target narrative-target document \
  normalize --kind narrative --input "$WORK/narrative-document.md"

check_rejection "pubc-04-invalid-version" 1 invalid-version artifact-version normalized-brief@2 \
  validate --input "$FIXTURES/invalid-version.json"

check_rejection "pubc-05-dangling-reference" 1 dangling-reference copy_refs procurement \
  validate --input "$FIXTURES/dangling-reference.json"

sed 's/^version: "1.1"$/version: "1.0"/' "$FIXTURES/narrative-slides-v1.md" > "$WORK/narrative-v10.md"
check_rejection "pubc-06-narrative-unsupported-version" 1 invalid-version artifact-version design-brief@1.0 \
  normalize --kind narrative --input "$WORK/narrative-v10.md"

# pubc-07: a consult-shaped brief keeps its own structure — order, identities, copy, notes,
# data and sources survive, and no arc, BLUF, slide or element obligation appears.
if python3 - "$WORK/direct.json" "$FIXTURES/direct-consult-v1.json" "$PLUGIN_ROOT/references/direct-brief-v1.schema.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
brief = json.load(open(sys.argv[2], encoding="utf-8"))
schema = json.load(open(sys.argv[3], encoding="utf-8"))
assert env["success"] is True
data = env["data"]
sections = brief["sections"]
assert [r["id"] for r in data["records"]] == [s["id"] for s in sections]
assert [r["order"] for r in data["records"]] == list(range(1, len(sections) + 1))
for record, section in zip(data["records"], sections):
    for key in ("title", "body", "notes", "role"):
        assert record.get(key) == section.get(key), (record["id"], key)
    assert record["source_refs"] == section.get("source_refs", [])
    assert record["data_refs"] == [item["id"] for item in section.get("data", [])]
assert data["data"] == [{**item, "record_ref": s["id"]} for s in sections for item in s.get("data", [])]
assert data["sources"] == brief["sources"] and data["structure"] == brief["structure"]
narrative_only = {"arc_id", "arc_display_name", "element", "slide_points", "talk_track", "bluf",
                  "slide_number", "governing_thought", "rendering_contract", "evidence_status"}
def keys(node):
    if isinstance(node, dict):
        for key, value in node.items():
            yield key
            yield from keys(value)
    elif isinstance(node, list):
        for value in node:
            yield from keys(value)
assert not narrative_only & set(keys(data)), narrative_only & set(keys(data))
assert not narrative_only & set(schema["required"])
assert schema["properties"]["sections"]["items"]["required"] == ["id", "title", "body"]
PY
then pass "pubc-07-direct-brief-no-arc-rewrite"; else fail "pubc-07-direct-brief-no-arc-rewrite"; fi

check_rejection "pubc-08-direct-dangling-reference" 1 dangling-reference source_refs destatis-2031 \
  normalize --kind direct --input "$FIXTURES/direct-dangling-reference.json"

check_rejection "pubc-09-direct-malformed-reference" 1 malformed-reference source_refs 42 \
  normalize --kind direct --input "$FIXTURES/direct-malformed-reference.json"

check_rejection "pubc-10-direct-dangling-data-reference" 1 dangling-reference source_refs vdma-2026 \
  normalize --kind direct --input "$FIXTURES/direct-dangling-data-reference.json"

# pubc-11: three separately versioned artifacts; the chain's normalized brief is the real
# normalizer output, composition and plan reference copy by id and never repeat it, and
# only the plan carries target and design-system decisions.
if python3 "$VALIDATOR" validate --input "$FIXTURES/contract-chain-v1.json" > "$WORK/chain.json" &&
   python3 - "$WORK/chain.json" "$FIXTURES/contract-chain-v1.json" "$WORK/direct.json" <<'PY'
import json, sys
result = json.load(open(sys.argv[1], encoding="utf-8"))
chain = json.load(open(sys.argv[2], encoding="utf-8"))
direct = json.load(open(sys.argv[3], encoding="utf-8"))["data"]
assert result["success"] is True
assert [(a["artifact_type"], a["artifact_version"]) for a in result["data"]["artifacts"]] == [
    ("normalized-brief", "1"), ("semantic-composition", "1"), ("target-resolved-plan", "1")]
normalized, composition, plan = (chain[k] for k in ("normalized_brief", "semantic_composition", "target_resolved_plan"))
assert normalized == direct, "the chain must start from real normalized output"
copy = [r[k] for r in normalized["records"] for k in ("title", "body", "notes") if k in r]
copy += [item["label"] for item in normalized["data"]]
for artifact in (composition, plan):
    text = json.dumps(artifact, ensure_ascii=False)
    assert not [c for c in copy if c in text], "downstream artifacts reference copy, never repeat it"
record_ids = {r["id"] for r in normalized["records"]}
assert all(set(u["copy_refs"]) <= record_ids for u in composition["units"])
assert "target" not in composition and "design_system" not in composition
assert plan["composition_ref"]["artifact_id"] == composition["artifact_id"]
assert plan["normalized_brief_ref"]["artifact_id"] == normalized["artifact_id"]
assert plan["target"] and plan["design_system"]["name"] and plan["design_system"]["version"]
PY
then pass "pubc-11-separate-versioned-artifacts"; else fail "pubc-11-separate-versioned-artifacts"; fi

check_rejection "pubc-12-incompatible-combination" 1 invalid-version version-compatibility normalized-brief@2 \
  validate --input "$FIXTURES/incompatible-combination.json"

python3 - "$FIXTURES/contract-chain-v1.json" "$WORK/copy-in-unit.json" <<'PY'
import json, sys
chain = json.load(open(sys.argv[1], encoding="utf-8"))
chain["semantic_composition"]["units"][0]["body"] = chain["normalized_brief"]["records"][0]["body"]
json.dump(chain, open(sys.argv[2], "w", encoding="utf-8"))
PY
check_rejection "pubc-13-unit-carries-copy" 1 unexpected-field unit-fields "unit opening" \
  validate --input "$WORK/copy-in-unit.json"

# pubc-22: a @1 unit role names what the unit does, never what it says — a record's title
# copied into it is rejected like any other copy in a unit.
python3 - "$FIXTURES/contract-chain-v1.json" "$WORK/role-carries-copy.json" <<'PY'
import json, sys
chain = json.load(open(sys.argv[1], encoding="utf-8"))
chain["semantic_composition"]["units"][0]["role"] = chain["normalized_brief"]["records"][0]["title"]
json.dump(chain, open(sys.argv[2], "w", encoding="utf-8"))
PY
check_rejection "pubc-22-unit-role-carries-copy" 1 unexpected-field role "unit opening" \
  validate --input "$WORK/role-carries-copy.json"

# pubc-23: the @1 role check is ROLE_TOKEN.fullmatch behind a presence guard — a prefix, case,
# length or non-string slip is a contract rejection, never a traceback, and an absent role is valid.
if python3 - "$VALIDATOR" "$FIXTURES/contract-chain-v1.json" "$WORK" <<'PY'
import json, subprocess, sys
validator, fixture, work = sys.argv[1:]
MISSING = object()
def run(role):
    chain = json.load(open(fixture, encoding="utf-8"))
    unit = chain["semantic_composition"]["units"][0]
    if role is MISSING:
        unit.pop("role", None)
    else:
        unit["role"] = role
    path = f"{work}/role-edge.json"
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(chain, fh)
    return subprocess.run([sys.executable, validator, "validate", "--input", path], capture_output=True, text=True)
rejected = ["Governing-Thought", "", "a" + "-b" * 32, "governing-thought\n",
            "governing-thought: Reliability is an information problem", 42, None, ["governing-thought"]]
for role in rejected:
    result = run(role)
    assert result.returncode == 1 and not result.stderr, (role, result.returncode, result.stderr)
    lines = result.stdout.splitlines()
    assert len(lines) == 1, role
    data = json.loads(lines[0])["data"]
    assert (data["code"], data.get("check"), data.get("reference")) == ("unexpected-field", "role", "unit opening"), \
        (role, data)
for role in ("governing-thought", "supporting-group", "a", "a" + "b" * 63, MISSING):
    result = run(role)
    assert result.returncode == 0 and not result.stderr, (role, result.returncode, result.stdout)
    assert json.loads(result.stdout)["success"] is True, role
PY
then pass "pubc-23-role-token-edges"; else fail "pubc-23-role-token-edges"; fi

# pubc-14-<scenario>: supplied > project > workspace preferences > bundled defaults, per key.
python3 - "$FIXTURES/config-precedence.json" "$WORK" <<'PY'
import json, pathlib, sys
fixture = json.load(open(sys.argv[1], encoding="utf-8"))
root = pathlib.Path(sys.argv[2])
(root / "project.json").write_text(json.dumps(fixture["project"]), encoding="utf-8")
(root / "workspace.json").write_text(json.dumps(fixture["workspace"]), encoding="utf-8")
PY
for scenario in supplied-beats-all supplied-beats-workspace project-beats-workspace absent-preferences-use-defaults project-over-defaults; do
  if python3 - "$VALIDATOR" "$FIXTURES/config-precedence.json" "$WORK" "$scenario" <<'PY'
import json, subprocess, sys
validator, fixture_path, work, name = sys.argv[1:]
scenario = next(s for s in json.load(open(fixture_path, encoding="utf-8"))["scenarios"] if s["name"] == name)
argv = [sys.executable, validator, "resolve-config"]
if scenario["project"] == "present":
    argv += ["--project-config", f"{work}/project.json"]
if scenario["workspace"] == "present":
    argv += ["--workspace-preferences", f"{work}/workspace.json"]
elif scenario["workspace"] == "absent":
    argv += ["--workspace-preferences", f"{work}/no-such-preferences.json"]
for item in scenario["set"]:
    argv += ["--set", item]
run = subprocess.run(argv, capture_output=True, text=True)
assert run.returncode == 0 and not run.stderr, run
env = json.loads(run.stdout)
assert env["success"] is True
assert env["data"]["configuration"] == scenario["expected"], env["data"]
assert env["data"]["origin"] == scenario["origin"], env["data"]
PY
  then pass "pubc-14-$scenario"; else fail "pubc-14-$scenario"; fi
done

printf '%s\n' '{"renderer": {"name": "pptx-runtime", "version": "^2.4"}}' > "$WORK/unpinned.json"
check_rejection "pubc-15-unpinned-renderer" 1 unpinned-renderer renderer-pin project \
  resolve-config --project-config "$WORK/unpinned.json"

# pubc-16: from a scratch directory, with an empty environment and HOME and a decoy
# cogni-workspace beside the working directory, every command succeeds while an audit
# hook proves it opened or stat'ed only its own code, the named inputs and — for the
# composition commands — the bundled pattern library beside it, listed no directory
# outside the import system, spawned no process, touched no network, and imported
# nothing outside the stdlib — site-packages is not even on the path.
mkdir -p "$WORK/iso/cwd" "$WORK/iso/home" "$WORK/iso/inputs" "$WORK/iso/cogni-workspace"
printf '%s\n' '{"target": "web"}' > "$WORK/iso/cogni-workspace/settings.json"
cp "$FIXTURES/narrative-slides-v1.md" "$FIXTURES/direct-consult-v1.json" "$FIXTURES/contract-chain-v1.json" \
   "$FIXTURES/narrative-slides-v1.expected.json" "$FIXTURES/composition-narrative-v2.json" \
   "$WORK/iso/inputs/"
cat > "$WORK/audit_run.py" <<'PY'
import json, runpy, sys
log_path, validator, *argv = sys.argv[1:]
watched = ("os.listdir", "os.scandir", "glob.", "subprocess.", "os.system", "os.exec", "os.posix_spawn",
           "os.spawn", "os.fork", "socket.", "urllib.", "http.client.", "ctypes.")
events = []
def hook(event, args):
    if event == "open" and args and isinstance(args[0], (str, bytes)):
        events.append(["open", args[0] if isinstance(args[0], str) else args[0].decode()])
    elif event == "import":
        events.append(["import", args[0]])
    elif event in ("os.listdir", "os.scandir"):
        events.append([event, args[0] if isinstance(args[0], str) else repr(args[0])])
    elif event.startswith(watched):
        events.append([event, repr(args)[:160]])
import os
def recording(real):
    # stat raises no audit event, so an existence probe would otherwise go unseen
    def wrapper(path, *args, **kwargs):
        name = os.fsdecode(path) if isinstance(path, (str, bytes, os.PathLike)) else repr(path)
        events.append(["stat", name])
        return real(path, *args, **kwargs)
    return wrapper
os.stat, os.lstat = recording(os.stat), recording(os.lstat)
import_path = list(sys.path)
sys.argv = [validator, *argv]
sys.addaudithook(hook)
code = 0
try:
    runpy.run_path(validator, run_name="__main__")
except SystemExit as exc:
    code = exc.code if isinstance(exc.code, int) else 1
snapshot = list(events)
with open(log_path, "w", encoding="utf-8") as fh:
    json.dump({"exit": code, "argv": argv, "import_path": import_path, "events": snapshot}, fh)
sys.exit(code)
PY
iso_rc=0
iso_run() {
  local log="$1"; shift
  (cd "$WORK/iso/cwd" && env -i PATH="$PATH" HOME="$WORK/iso/home" \
     python3 -I -S "$WORK/audit_run.py" "$WORK/iso/$log" "$VALIDATOR" "$@" > "$WORK/iso/$log.out") || iso_rc=1
}
iso_run log-narrative.json normalize --kind narrative --input "$WORK/iso/inputs/narrative-slides-v1.md"
iso_run log-direct.json normalize --kind direct --input "$WORK/iso/inputs/direct-consult-v1.json"
iso_run log-chain.json validate --input "$WORK/iso/inputs/contract-chain-v1.json"
iso_run log-config.json resolve-config --set target=slides
iso_run log-patterns.json check-patterns
iso_run log-compose.json compose --brief "$WORK/iso/inputs/narrative-slides-v1.expected.json" \
  --composition "$WORK/iso/inputs/composition-narrative-v2.json"
iso_run log-check-composition.json check-composition --brief "$WORK/iso/inputs/narrative-slides-v1.expected.json" \
  --composition "$WORK/iso/inputs/composition-narrative-v2.json"
iso_run log-repair.json check-repair --brief "$WORK/iso/inputs/narrative-slides-v1.expected.json" \
  --before "$WORK/iso/inputs/composition-narrative-v2.json" --after "$WORK/iso/inputs/composition-narrative-v2.json"
if [ "$iso_rc" -eq 0 ] && python3 - "$VALIDATOR" "$WORK/iso" <<'PY'
import json, os, sys, sysconfig
validator, iso = sys.argv[1:]
paths = sysconfig.get_paths()
stdlib = {os.path.realpath(paths[key]) for key in ("stdlib", "platstdlib")}
allowed = {os.path.realpath(validator)} | {os.path.realpath(os.path.join(iso, "inputs", n)) for n in os.listdir(os.path.join(iso, "inputs"))}
allowed.add(os.path.realpath(os.path.join(os.path.dirname(os.path.dirname(validator)), "references", "pattern-library-v1.json")))
for name in ("log-narrative.json", "log-direct.json", "log-chain.json", "log-config.json", "log-patterns.json",
             "log-compose.json", "log-check-composition.json", "log-repair.json"):
    log = json.load(open(os.path.join(iso, name), encoding="utf-8"))
    envelope = json.load(open(os.path.join(iso, name + ".out"), encoding="utf-8"))
    assert log["exit"] == 0 and envelope["success"] is True, name
    import_dirs = {os.path.realpath(p) for p in log["import_path"] if p}
    assert not [p for p in import_dirs if "site-packages" in p], "run with site-packages unreachable"
    for kind, detail in log["events"]:
        if kind in ("os.listdir", "os.scandir"):
            # the import system caches its own sys.path and stdlib package directories;
            # a listing anywhere else (cwd, HOME, a sibling plugin) is a probe
            real = os.path.realpath(detail)
            assert real in import_dirs or any(real == root or real.startswith(root + os.sep) for root in stdlib), \
                (name, kind, detail)
        elif kind in ("open", "stat"):
            real = os.path.realpath(detail)
            assert real in allowed or any(real.startswith(root + os.sep) for root in stdlib), (name, detail)
        elif kind == "import":
            assert detail.split(".")[0] in sys.stdlib_module_names, (name, detail)
        else:
            raise AssertionError((name, kind, detail))
config = json.load(open(os.path.join(iso, "log-config.json.out"), encoding="utf-8"))["data"]
assert config["configuration"] == {"target": "slides", "language": "en", "renderer": None}, config
source = open(validator, encoding="utf-8").read()
for probe in ("os.environ", "getenv", "expanduser", "Path.home", "import subprocess", "import socket", "urllib"):
    assert probe not in source, probe
PY
then pass "pubc-16-standalone-isolation"; else fail "pubc-16-standalone-isolation"; fi

check_rejection "pubc-17-usage-error-envelope" 2 usage-error - - validate
check_rejection "pubc-18-runtime-error-envelope" 2 runtime-error - - validate --input "$WORK/no-such-chain.json"
check_rejection "pubc-19-unsettable-key" 2 usage-error - - resolve-config --set renderer=pptx-runtime

# pubc-20: each contract schema carries its own identity, exact version and the
# cross-artifact reference fields the validator enforces.
if python3 - "$PLUGIN_ROOT/references" <<'PY'
import json, sys
refs = sys.argv[1]
schemas = {kind: json.load(open(f"{refs}/{kind}-v1.schema.json", encoding="utf-8"))
           for kind in ("direct-brief", "normalized-brief", "semantic-composition", "target-resolved-plan")}
for kind, schema in schemas.items():
    assert schema["$id"] == f"cogni-publishing/{kind}-v1"
    assert schema["properties"]["artifact_type"]["const"] == kind
    assert schema["properties"]["artifact_version"]["const"] == "1"
    assert {"artifact_type", "artifact_version", "artifact_id"} <= set(schema["required"])
assert len({s["$id"] for s in schemas.values()}) == 4
assert "normalized_brief_ref" in schemas["semantic-composition"]["required"]
assert {"composition_ref", "normalized_brief_ref", "design_system"} <= set(schemas["target-resolved-plan"]["required"])
assert {"provenance", "freeze"} <= set(schemas["normalized-brief"]["required"])
# Both composition versions declare one role token rule, and @1 keeps role optional.
v1_unit = schemas["semantic-composition"]["properties"]["units"]["items"]
v2_unit = json.load(open(f"{refs}/semantic-composition-v2.schema.json", encoding="utf-8"))["properties"]["units"]["items"]
assert v1_unit["properties"]["role"]["pattern"] == v2_unit["properties"]["role"]["pattern"] == "^[a-z][a-z0-9-]{0,63}$"
assert v1_unit["required"] == ["id"]
PY
then pass "pubc-20-schema-identities"; else fail "pubc-20-schema-identities"; fi

# pubc-21: the marketplace registers the plugin exactly once, mirroring its own manifest.
if python3 - "$REPO_ROOT/.claude-plugin/marketplace.json" "$PLUGIN_ROOT/.claude-plugin/plugin.json" <<'PY'
import json, sys
market = json.load(open(sys.argv[1], encoding="utf-8"))
manifest = json.load(open(sys.argv[2], encoding="utf-8"))
entries = [p for p in market["plugins"] if p["name"] == "cogni-publishing"]
assert len(entries) == 1
entry = entries[0]
assert entry["source"] == "./cogni-publishing" and manifest["name"] == "cogni-publishing"
assert entry["version"] == manifest["version"]
assert entry["description"] == manifest["description"]
assert set(entry["keywords"]) <= set(manifest["keywords"])
PY
then pass "pubc-21-marketplace-registration"; else fail "pubc-21-marketplace-registration"; fi

# pubc-24: document.subtitle sheds exactly one enclosing emphasis pair. The authored line is read
# out of the brief itself, so the case stands independently of the frozen expectation.
if python3 - "$WORK/narrative.json" "$FIXTURES/narrative-slides-v1.md" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))["data"]
lines = open(sys.argv[2], encoding="utf-8").read().split("\n")
end = lines.index("---", 1)
contract = next(i for i in range(end + 1, len(lines)) if lines[i].startswith("# Rendering"))
authored = next(lines[i] for i in range(end + 1, contract)
                if lines[i].strip() and not lines[i].startswith("# ") and not lines[i].startswith("**"))
assert authored.startswith("*") and authored.endswith("*"), authored
assert data["document"]["subtitle"] == authored[1:-1], data["document"]["subtitle"]
PY
then pass "pubc-24-subtitle-emphasis-strip"; else fail "pubc-24-subtitle-emphasis-strip"; fi

# pubc-25: the strip removes one pair and only one. An unmarked subtitle is carried verbatim, and
# an underscore pair is shed like an asterisk pair.
python3 - "$FIXTURES/narrative-slides-v1.md" "$WORK/subtitle-bare.md" "$WORK/subtitle-underscore.md" <<'PY'
import sys
src, bare_out, under_out = sys.argv[1:]
lines = open(src, encoding="utf-8").read().split("\n")
end = lines.index("---", 1)
contract = next(i for i in range(end + 1, len(lines)) if lines[i].startswith("# Rendering"))
index = next(i for i in range(end + 1, contract)
             if lines[i].strip() and not lines[i].startswith("# ") and not lines[i].startswith("**"))
bare = lines[index][1:-1]
for out, replacement in ((bare_out, bare), (under_out, "_" + bare + "_")):
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines[:index] + [replacement] + lines[index + 1:]))
with open(bare_out + ".expected", "w", encoding="utf-8") as fh:
    fh.write(bare)
PY
python3 "$VALIDATOR" normalize --kind narrative --input "$WORK/subtitle-bare.md" > "$WORK/subtitle-bare.json"
python3 "$VALIDATOR" normalize --kind narrative --input "$WORK/subtitle-underscore.md" > "$WORK/subtitle-underscore.json"
if python3 - "$WORK/subtitle-bare.json" "$WORK/subtitle-underscore.json" "$WORK/subtitle-bare.md.expected" <<'PY'
import json, sys
bare, under, expected_path = sys.argv[1:]
expected = open(expected_path, encoding="utf-8").read()
for path in (bare, under):
    env = json.load(open(path, encoding="utf-8"))
    assert env["success"] is True, path
    assert env["data"]["document"]["subtitle"] == expected, (path, env["data"]["document"]["subtitle"])
PY
then pass "pubc-25-subtitle-unmarked-verbatim"; else fail "pubc-25-subtitle-unmarked-verbatim"; fi

# pubc-26: the five additive metadata keys carry the author's design intent — design complete with
# its five fields, climax as an integer, the two optional asks explicit even when unauthored — while
# the six pre-existing keys keep the values the suite re-reads from the brief and density stays out.
if python3 - "$WORK/narrative.json" "$FIXTURES/narrative-slides-v1.md" <<'PY'
import json, re, sys
metadata = json.load(open(sys.argv[1], encoding="utf-8"))["data"]["metadata"]
lines = open(sys.argv[2], encoding="utf-8").read().split("\n")
end = lines.index("---", 1)
scalars = {}
for line in lines[1:end]:
    match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*): (.*)$", line)
    if match:
        value = match.group(2)
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        scalars[match.group(1)] = value
for key in ("title", "language", "arc_id", "arc_display_name", "governing_thought", "source_narrative"):
    assert metadata[key] == scalars[key], key
assert set(metadata["design"]) == {"register", "dark_slides", "speaker_notes", "imagery", "variations"}
assert metadata["design"] == {"register": "quiet-executive", "dark_slides": [1, 7],
                              "speaker_notes": "full-script", "imagery": "none", "variations": 1}
assert metadata["climax"] == 7
assert isinstance(metadata["climax"], int) and not isinstance(metadata["climax"], bool)
for key in ("decision_required", "management_ask"):
    assert key in metadata and metadata[key] is None, key
assert "density" not in metadata
assert "key_figures" in metadata
PY
then pass "pubc-26-design-intent-metadata"; else fail "pubc-26-design-intent-metadata"; fi

# pubc-27: each key figure is the authored figure with its citation suffix resolved into a source id,
# and nothing else about the line is rewritten — the expectation is derived from the brief.
if python3 - "$WORK/narrative.json" "$FIXTURES/narrative-slides-v1.md" <<'PY'
import json, re, sys
figures = json.load(open(sys.argv[1], encoding="utf-8"))["data"]["metadata"]["key_figures"]
lines = open(sys.argv[2], encoding="utf-8").read().split("\n")
end = lines.index("---", 1)
authored, collecting = [], False
for line in lines[1:end]:
    if line == "key_figures:":
        collecting = True
        continue
    if collecting:
        item = re.match(r'^  - "(.*)"$', line)
        if not item:
            break
        authored.append(item.group(1))
assert len(authored) == 5 and len(figures) == len(authored)
for figure, line in zip(figures, authored):
    match = re.search(r"\s*\(src: \[([0-9]+)\]\)$", line)
    assert match, line
    assert set(figure) == {"text", "source_ref"}, figure
    assert figure["text"] == line[:match.start()], (figure["text"], line)
    assert figure["source_ref"] == "source-%d" % int(match.group(1)), figure
PY
then pass "pubc-27-key-figures-verbatim"; else fail "pubc-27-key-figures-verbatim"; fi

# pubc-28/29: a key figure citing a source the Sources block does not carry, and a climax that is not
# a bare integer, are refused in the chain's own rejection vocabulary.
python3 - "$FIXTURES/narrative-slides-v1.md" "$WORK/key-figure-dangling.md" "$WORK/climax-non-integer.md" <<'PY'
import re, sys
src, dangling_out, climax_out = sys.argv[1:]
text = open(src, encoding="utf-8").read()
with open(dangling_out, "w", encoding="utf-8") as fh:
    fh.write(re.sub(r"\(src: \[1\]\)\"$", '(src: [9])"', text, count=1, flags=re.M))
with open(climax_out, "w", encoding="utf-8") as fh:
    fh.write(re.sub(r"^climax: 7$", "climax: seven", text, count=1, flags=re.M))
PY
check_rejection "pubc-28-key-figure-dangling-reference" 1 dangling-reference key-figure-citation source-9 \
  normalize --kind narrative --input "$WORK/key-figure-dangling.md"

check_rejection "pubc-29-climax-non-integer" 1 invalid-brief climax seven \
  normalize --kind narrative --input "$WORK/climax-non-integer.md"

# pubc-30: the direct adapter is untouched by a narrative-only widening — its normalize output still
# matches the committed oracle byte for byte and still carries no metadata surface at all.
if python3 - "$VALIDATOR" "$FIXTURES" <<'PY'
import json, subprocess, sys
validator, fixtures = sys.argv[1:]
def normalize(path):
    out = subprocess.run([sys.executable, validator, "normalize", "--kind", "direct", "--input", path],
                         capture_output=True, text=True)
    assert out.returncode == 0 and not out.stderr, path
    env = json.loads(out.stdout)
    assert env["success"] is True, path
    return env["data"]
proof = normalize(f"{fixtures}/verify/direct-proof-v1.json")
committed = json.load(open(f"{fixtures}/verify/direct-proof-v1.normalized.json", encoding="utf-8"))
assert proof == committed, "direct normalize drifted from its committed oracle"
for name in ("direct-costs-v1.json", "direct-consult-v1.json"):
    data = normalize(f"{fixtures}/{name}")
    assert "metadata" not in data, name
PY
then pass "pubc-30-direct-normalize-unchanged"; else fail "pubc-30-direct-normalize-unchanged"; fi

# pubc-31: a block key whose items are all removed is declared-empty, not the wrong container.
# key_figures: with nothing under it normalizes to an empty sequence rather than being refused as a
# mapping, and the design block beside it is untouched by the shape decision.
python3 - "$FIXTURES/narrative-slides-v1.md" "$WORK/key-figures-empty.md" <<'PY'
import sys
src, out = sys.argv[1:]
lines = open(src, encoding="utf-8").read().split("\n")
start = lines.index("key_figures:")
end = start + 1
while end < len(lines) and lines[end].startswith("  - "):
    end += 1
assert end > start + 1, "fixture carries no key_figures items to remove"
with open(out, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines[:start + 1] + lines[end:]))
PY
python3 "$VALIDATOR" normalize --kind narrative --input "$WORK/key-figures-empty.md" > "$WORK/key-figures-empty.json" 2> "$WORK/key-figures-empty.err" || true
if [ ! -s "$WORK/key-figures-empty.err" ] && python3 - "$WORK/key-figures-empty.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
assert env["success"] is True and env["error"] is None, env
metadata = env["data"]["metadata"]
assert metadata["key_figures"] == [], metadata["key_figures"]
assert set(metadata["design"]) == {"register", "dark_slides", "speaker_notes", "imagery", "variations"}
assert metadata["design"]["imagery"] == "none", metadata["design"]
PY
then pass "pubc-31-key-figures-empty-block"; else fail "pubc-31-key-figures-empty-block"; fi

# pubc-32: a design field authored with no value is refused, never silently defaulted. Declaring
# emptiness and omitting the key are different statements, and only the second takes a default.
python3 - "$FIXTURES/narrative-slides-v1.md" "$WORK/design-empty-field.md" <<'PY'
import re, sys
src, out = sys.argv[1:]
text = open(src, encoding="utf-8").read()
patched, count = re.subn(r"^  imagery: .*$", "  imagery:", text, count=1, flags=re.M)
assert count == 1, "fixture carries no authored design.imagery line"
with open(out, "w", encoding="utf-8") as fh:
    fh.write(patched)
PY
check_rejection "pubc-32-design-field-declared-empty" 1 invalid-brief design-intent imagery \
  normalize --kind narrative --input "$WORK/design-empty-field.md"

# pubc-33: the strip sheds one ENCLOSING pair, never a pair that merely starts and ends the line.
# A subtitle carrying two separate emphasis spans is copy and is carried verbatim; the single-span
# control beside it still sheds its pair, so the case distinguishes the guard from disabling the strip.
python3 - "$FIXTURES/narrative-slides-v1.md" "$WORK/subtitle-two-spans.md" "$WORK/subtitle-one-span.md" <<'PY'
import sys
src, two_out, one_out = sys.argv[1:]
lines = open(src, encoding="utf-8").read().split("\n")
end = lines.index("---", 1)
contract = next(i for i in range(end + 1, len(lines)) if lines[i].startswith("# Rendering"))
index = next(i for i in range(end + 1, contract)
             if lines[i].strip() and not lines[i].startswith("# ") and not lines[i].startswith("**"))
for out, replacement in ((two_out, "*a* and *b*"), (one_out, "*a and b*")):
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines[:index] + [replacement] + lines[index + 1:]))
PY
python3 "$VALIDATOR" normalize --kind narrative --input "$WORK/subtitle-two-spans.md" > "$WORK/subtitle-two-spans.json"
python3 "$VALIDATOR" normalize --kind narrative --input "$WORK/subtitle-one-span.md" > "$WORK/subtitle-one-span.json"
if python3 - "$WORK/subtitle-two-spans.json" "$WORK/subtitle-one-span.json" <<'PY'
import json, sys
two, one = sys.argv[1:]
two_env = json.load(open(two, encoding="utf-8"))
one_env = json.load(open(one, encoding="utf-8"))
assert two_env["success"] is True and one_env["success"] is True
assert two_env["data"]["document"]["subtitle"] == "*a* and *b*", two_env["data"]["document"]["subtitle"]
assert one_env["data"]["document"]["subtitle"] == "a and b", one_env["data"]["document"]["subtitle"]
PY
then pass "pubc-33-subtitle-two-spans-unchanged"; else fail "pubc-33-subtitle-two-spans-unchanged"; fi

printf '%s\n' "Publishing contract tests: $passes passed, $failures failed"
[ "$failures" -eq 0 ]
