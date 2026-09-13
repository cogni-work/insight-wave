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
   "$FIXTURES/render/plan-narrative-captured-v2.json" "$WORK/iso/inputs/"
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
iso_run log-check-plan.json check-plan --brief "$WORK/iso/inputs/narrative-slides-v1.expected.json" \
  --composition "$WORK/iso/inputs/composition-narrative-v2.json" --plan "$WORK/iso/inputs/plan-narrative-captured-v2.json"
if [ "$iso_rc" -eq 0 ] && python3 - "$VALIDATOR" "$WORK/iso" <<'PY'
import json, os, sys, sysconfig
validator, iso = sys.argv[1:]
paths = sysconfig.get_paths()
stdlib = {os.path.realpath(paths[key]) for key in ("stdlib", "platstdlib")}
allowed = {os.path.realpath(validator)} | {os.path.realpath(os.path.join(iso, "inputs", n)) for n in os.listdir(os.path.join(iso, "inputs"))}
allowed.add(os.path.realpath(os.path.join(os.path.dirname(os.path.dirname(validator)), "references", "pattern-library-v1.json")))
for name in ("log-narrative.json", "log-direct.json", "log-chain.json", "log-config.json", "log-patterns.json",
             "log-compose.json", "log-check-composition.json", "log-repair.json", "log-check-plan.json"):
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

printf '%s\n' "Publishing contract tests: $passes passed, $failures failed"
[ "$failures" -eq 0 ]
