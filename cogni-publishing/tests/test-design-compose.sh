#!/usr/bin/env bash
# Composition suite for cogni-publishing: the pattern library, pattern-bound
# semantic-composition@2, binding fidelity, coverage, quantitative provenance, fit,
# bounded repair and the proposed/accepted routing gate.
#
# Case ids follow <suite-slug>-<NN>[-<discriminator>] with the slug `dcmp`; NN is an
# allocation counter, so never renumber an existing id — the mutation recipes below
# record them.
#
# Every negative is derived in a scratch directory from a green fixture by one small
# edit; no tracked fixture is ever mutated. Where the brief changes, the draft is
# stripped of its mechanical fields and recomposed, so digests match the edited brief
# and only the edit under test can fail.
#
# Mutation recipes (run from the repository root; the harness is the installed
# managed-service cogni-service plugin, and --expr is evaluated by perl -0pi):
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return positions == sorted\(positions\)/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-10-reordered-unit
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return len\(source_refs\) > 0/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-25-unsourced-chart-data
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return pattern\.get\("status"\) == "accepted"/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-45-unaccepted-pattern
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-compose/SKILL.md --expr 's/Never route a proposed pattern into a production composition/Route any pattern into a composition/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-49-skill-proposed-routing
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if require_register and index\.source_ids and not state\.register_units:/if False:/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-57-register-omitted
set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-publishing.py"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
LIBRARY="$PLUGIN_ROOT/references/pattern-library-v1.json"
SKILL="$PLUGIN_ROOT/skills/design-compose/SKILL.md"
REFERENCE="$PLUGIN_ROOT/references/design-composition.md"
NBRIEF="$FIXTURES/narrative-slides-v1.expected.json"
NARR="$FIXTURES/composition-narrative-v2.json"
COSTS="$FIXTURES/composition-direct-costs-v2.json"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CBRIEF="$WORK/costs-brief.json"
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

# derive <source.json> <out.json> — apply the Python edit read from stdin to `d`.
cat > "$WORK/derive.py" <<'PY'
import json, sys
source, out = sys.argv[1:]
with open(source, encoding="utf-8") as fh:
    d = json.load(fh)
def unit(uid):
    return next(u for u in d["units"] if u["id"] == uid)
def record(rid):
    return next(r for r in d["records"] if r["id"] == rid)
def item(did):
    return next(i for i in d["data"] if i["id"] == did)
def pattern(pid):
    return next(p for p in d["patterns"] if p["id"] == pid)
def strip():
    """Remove every field compose fills, so an edited brief is re-bound mechanically."""
    d["normalized_brief_ref"].pop("content_fingerprint", None)
    d.pop("document_bindings", None)
    for u in d["units"]:
        u.pop("source_refs", None)
        u.pop("register_refs", None)
        for binding in u.get("bindings", []):
            binding.pop("digest", None)
exec(sys.stdin.read())
with open(out, "w", encoding="utf-8") as fh:
    json.dump(d, fh, ensure_ascii=False)
PY
derive() { python3 "$WORK/derive.py" "$1" "$2"; }

python3 "$VALIDATOR" normalize --kind direct --input "$FIXTURES/direct-costs-v1.json" > "$WORK/costs-env.json"
python3 - "$WORK/costs-env.json" "$CBRIEF" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
json.dump(env["data"], open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY

# --- the library ----------------------------------------------------------------------------

# dcmp-01: the bundled library carries exactly the five proof patterns, all accepted, each
# with every contract field non-empty.
if python3 "$VALIDATOR" check-patterns > "$WORK/patterns.json" &&
   python3 - "$WORK/patterns.json" "$LIBRARY" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
library = json.load(open(sys.argv[2], encoding="utf-8"))
five = ["answer-emphasis", "comparison", "sourced-chart", "conceptual-system", "sources"]
assert env["success"] is True and env["data"]["accepted"] == five and env["data"]["proposed"] == []
fields = ("status", "family", "purpose", "eligibility", "slots", "constraints", "evidence_needs",
          "accessibility", "target_capabilities", "variants", "examples")
for pattern in library["patterns"]:
    for field in fields:
        assert pattern.get(field) not in (None, "", [], {}), (pattern["id"], field)
PY
then pass "dcmp-01-library-accepted-five"; else fail "dcmp-01-library-accepted-five"; fi

# dcmp-02-<field>: a pattern missing any required contract-field class is rejected by name.
for field in status family purpose eligibility slots constraints evidence_needs accessibility target_capabilities variants examples; do
  slug="$(printf '%s' "$field" | tr '_' '-')"
  FIELD="$field" derive "$LIBRARY" "$WORK/library-no-$slug.json" <<'PY'
import os
del pattern("comparison")[os.environ["FIELD"]]
PY
  check_rejection "dcmp-02-missing-$slug" 1 invalid-pattern "$field" comparison \
    check-patterns --patterns "$WORK/library-no-$slug.json"
done

# dcmp-03: the schemas document the same contract the validator enforces.
if python3 - "$PLUGIN_ROOT/references" <<'PY'
import json, sys
refs = sys.argv[1]
composition = json.load(open(f"{refs}/semantic-composition-v2.schema.json", encoding="utf-8"))
contract = json.load(open(f"{refs}/pattern-contract-v1.schema.json", encoding="utf-8"))
assert composition["$id"] == "cogni-publishing/semantic-composition-v2"
assert composition["properties"]["artifact_version"]["const"] == "2"
assert set(composition["required"]) == {"artifact_type", "artifact_version", "artifact_id", "normalized_brief_ref",
                                        "pattern_library_ref", "design_system", "targets", "document_bindings", "units"}
unit = composition["properties"]["units"]["items"]
assert unit["additionalProperties"] is False
assert set(unit["properties"]) == {"id", "role", "pattern", "variant", "bindings", "data_bindings", "source_refs",
                                   "register_refs", "entities", "relationships", "type_floor"}
assert unit["properties"]["role"]["pattern"] == "^[a-z][a-z0-9-]{0,63}$"
design = composition["properties"]["design_system"]
assert design["additionalProperties"] is False and set(design["properties"]) == {"name", "version"}
assert contract["$id"] == "cogni-publishing/pattern-contract-v1"
assert contract["properties"]["artifact_type"]["const"] == "pattern-library"
assert contract["$defs"]["pattern"]["required"] == ["id", "status", "family", "purpose", "eligibility", "slots",
    "constraints", "evidence_needs", "accessibility", "target_capabilities", "variants", "examples"]
PY
then pass "dcmp-03-schema-field-parity"; else fail "dcmp-03-schema-field-parity"; fi

# dcmp-04: a specimen is validated exactly like production; an accepted pattern whose own
# specimen fails is rejected.
derive "$LIBRARY" "$WORK/library-bad-specimen.json" <<'PY'
pattern("answer-emphasis")["examples"][0]["unit"]["bindings"][0]["slot"] = "no-such-slot"
PY
check_rejection "dcmp-04-specimen-must-validate" 1 invalid-pattern examples answer-emphasis/answer-emphasis-direct \
  check-patterns --patterns "$WORK/library-bad-specimen.json"

# dcmp-05: the prose catalogue documents every pattern, variant and slot the library defines.
if python3 - "$LIBRARY" "$REFERENCE" <<'PY'
import json, re, sys
library = json.load(open(sys.argv[1], encoding="utf-8"))
text = open(sys.argv[2], encoding="utf-8").read()
for pattern in library["patterns"]:
    heading = f"### `{pattern['id']}`"
    assert heading in text, heading
    section = re.split(r"\n#{2,3} ", text.split(heading, 1)[1], maxsplit=1)[0]
    for name in [v["id"] for v in pattern["variants"]] + [s["id"] for s in pattern["slots"]]:
        assert f"`{name}`" in section, (pattern["id"], name)
PY
then pass "dcmp-05-catalogue-sync"; else fail "dcmp-05-catalogue-sync"; fi

# --- binding fidelity and coverage ----------------------------------------------------------

# dcmp-06: the narrative brief composes green with complete coverage computed independently
# from the brief, carries no copy and no target decision, and treats visual intent as a hint.
if python3 "$VALIDATOR" check-composition --brief "$NBRIEF" --composition "$NARR" > "$WORK/narr-check.json" &&
   python3 - "$WORK/narr-check.json" "$NBRIEF" "$NARR" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
brief = json.load(open(sys.argv[2], encoding="utf-8"))
composition = json.load(open(sys.argv[3], encoding="utf-8"))
assert env["success"] is True and env["data"]["omissions"] == []
coverage = env["data"]["coverage"]
records = brief["records"]
def values(record, key):
    return [f["value"] for f in record["fields"] if f["key"] == key]
talks = sum(len(values(r, "talk_track")) for r in records)
trailer = brief["freeze"]["trailer_notes"]
evidence = sum(len(values(r, "evidence_status")) for r in records)
pairs = sum(len(r["source_refs"]) for r in records)
assert coverage["records"] == {"expected": 8, "bound": 8}
assert coverage["notes"] == {"expected": talks + len(trailer), "bound": talks + len(trailer)} and talks + len(trailer) == 12
assert coverage["evidence_status"] == {"expected": evidence, "bound": evidence} and evidence == 5
assert coverage["citations"] == {"expected": pairs, "bound": pairs} and pairs == 14
assert coverage["data"] == {"expected": 0, "bound": 0}
sources = len(brief["sources"])
assert coverage["sources"] == {"expected": sources, "bound": sources} and sources > 0
copy = [r["headline"] for r in records] + trailer
copy += [text for r in records for field in ("slide_points", "talk_track") for value in values(r, field)
         for text in (value if isinstance(value, list) else [value])]
rendered = json.dumps(composition, ensure_ascii=False)
leaked = [text for text in copy if len(text) >= 12 and text in rendered]
assert not leaked, leaked
def keys(node):
    if isinstance(node, dict):
        for key, value in node.items():
            yield key
            yield from keys(value)
    elif isinstance(node, list):
        for value in node:
            yield from keys(value)
assert not {"target", "layout", "emphasis"} & set(keys(composition))
intent = {entry["key"]: entry["value"] for entry in values(records[4], "visual_intent")[0]}
slide5 = next(u for u in composition["units"] if u["id"] == "u-slide-5")
assert intent["asset_signal"] == "data-chart" and slide5["pattern"] == "comparison"
PY
then pass "dcmp-06-narrative-composition-green"; else fail "dcmp-06-narrative-composition-green"; fi

# dcmp-07: compose is deterministic and mechanical — a stripped draft recomposes to the frozen
# fixture, and every digest and the fingerprint follow the documented algorithm.
derive "$NARR" "$WORK/narr-draft.json" <<'PY'
strip()
PY
if python3 "$VALIDATOR" compose --brief "$NBRIEF" --composition "$WORK/narr-draft.json" > "$WORK/compose-a.json" &&
   python3 "$VALIDATOR" compose --brief "$NBRIEF" --composition "$WORK/narr-draft.json" > "$WORK/compose-b.json" &&
   python3 - "$WORK/compose-a.json" "$WORK/compose-b.json" "$NARR" "$NBRIEF" <<'PY'
import hashlib, json, sys
first, second, frozen, brief = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:])
assert first["success"] and second["success"] and first["data"] == second["data"] == frozen
def digest(value):
    text = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()
keys = ("document", "structure", "records", "data", "sources", "freeze")
assert frozen["normalized_brief_ref"]["content_fingerprint"] == digest({k: brief.get(k) for k in keys})
records = {r["id"]: r for r in brief["records"]}
def value(record, field):
    if field == "headline":
        return record["headline"]
    return next(f["value"] for f in record["fields"] if f["key"] == field)
bound = 0
for unit in frozen["units"]:
    for binding in unit["bindings"]:
        assert binding["digest"] == digest(value(records[binding["record_ref"]], binding["field"])), binding
        bound += 1
assert bound == 28
for entry in frozen["document_bindings"]:
    assert entry["digest"] == digest(brief["freeze"]["trailer_notes"][entry["index"]])
PY
then pass "dcmp-07-compose-deterministic"; else fail "dcmp-07-compose-deterministic"; fi

derive "$NARR" "$WORK/geometry-key.json" <<'PY'
d["units"][1]["position"] = {"x": 40, "y": 80}
PY
check_rejection "dcmp-08-geometry-key" 1 target-geometry geometry-key "units[1].position" \
  check-composition --brief "$NBRIEF" --composition "$WORK/geometry-key.json"

derive "$NARR" "$WORK/geometry-value.json" <<'PY'
d["units"][0]["role"] = "960px"
PY
check_rejection "dcmp-09-geometry-value" 1 target-geometry geometry-value "units[0].role" \
  check-composition --brief "$NBRIEF" --composition "$WORK/geometry-value.json"

derive "$NARR" "$WORK/reordered.json" <<'PY'
d["units"][1], d["units"][2] = d["units"][2], d["units"][1]
PY
check_rejection "dcmp-10-reordered-unit" 1 reordered-unit record-order slide-2 \
  check-composition --brief "$NBRIEF" --composition "$WORK/reordered.json"

derive "$NARR" "$WORK/missing-unit.json" <<'PY'
d["units"] = [u for u in d["units"] if u["id"] != "u-slide-7"]
PY
check_rejection "dcmp-11-missing-unit" 1 unbound-content records slide-7 \
  check-composition --brief "$NBRIEF" --composition "$WORK/missing-unit.json"

derive "$NARR" "$WORK/missing-field.json" <<'PY'
u = unit("u-slide-6")
u["bindings"] = [b for b in u["bindings"] if b["field"] != "slide_points"]
PY
check_rejection "dcmp-12-missing-field" 1 unbound-content fields "slide-6#slide_points" \
  check-composition --brief "$NBRIEF" --composition "$WORK/missing-field.json"

derive "$NARR" "$WORK/duplicate-field.json" <<'PY'
u = unit("u-slide-2")
u["bindings"].append(dict(u["bindings"][0]))
PY
check_rejection "dcmp-13-duplicate-field-binding" 1 duplicate-binding field "slide-2#headline" \
  check-composition --brief "$NBRIEF" --composition "$WORK/duplicate-field.json"

derive "$NARR" "$WORK/record-in-two-units.json" <<'PY'
unit("u-slide-3")["bindings"].append(dict(unit("u-slide-2")["bindings"][0]))
PY
check_rejection "dcmp-14-record-in-two-units" 1 duplicate-binding record-units slide-2 \
  check-composition --brief "$NBRIEF" --composition "$WORK/record-in-two-units.json"

derive "$NBRIEF" "$WORK/brief-headline-edited.json" <<'PY'
record("slide-4")["headline"] += "!"
PY
check_rejection "dcmp-15-copy-changed" 1 copy-changed digest "slide-4#headline" \
  check-composition --brief "$WORK/brief-headline-edited.json" --composition "$NARR"

derive "$NARR" "$WORK/source-identity.json" <<'PY'
u = unit("u-slide-2")
u["source_refs"] = ["source-9" if ref == "source-2" else ref for ref in u["source_refs"]]
PY
check_rejection "dcmp-16-source-identity-changed" 1 source-identity-changed citations source-9 \
  check-composition --brief "$NBRIEF" --composition "$WORK/source-identity.json"

derive "$NARR" "$WORK/register-reordered.json" <<'PY'
unit("u-slide-8")["register_refs"].reverse()
PY
check_rejection "dcmp-17-register-reordered" 1 source-identity-changed register u-slide-8 \
  check-composition --brief "$NBRIEF" --composition "$WORK/register-reordered.json"

derive "$NARR" "$WORK/note-omitted.json" <<'PY'
u = unit("u-slide-5")
u["bindings"] = [b for b in u["bindings"] if b["field"] != "talk_track"]
PY
check_rejection "dcmp-18-note-omitted" 1 reference-omitted notes "slide-5#talk_track" \
  check-composition --brief "$NBRIEF" --composition "$WORK/note-omitted.json"

derive "$NARR" "$WORK/note-reassigned.json" <<'PY'
next(b for b in unit("u-slide-1")["bindings"] if b["field"] == "talk_track")["slot"] = "support"
PY
check_rejection "dcmp-19-note-reassigned" 1 reference-reassigned notes "slide-1#talk_track" \
  check-composition --brief "$NBRIEF" --composition "$WORK/note-reassigned.json"

derive "$NARR" "$WORK/citation-reassigned.json" <<'PY'
unit("u-slide-6")["source_refs"].append("source-1")
PY
check_rejection "dcmp-20-citation-reassigned" 1 reference-reassigned citations "u-slide-6:source-1" \
  check-composition --brief "$NBRIEF" --composition "$WORK/citation-reassigned.json"

derive "$NARR" "$WORK/citation-omitted.json" <<'PY'
unit("u-slide-3")["source_refs"].remove("source-4")
PY
check_rejection "dcmp-21-citation-omitted" 1 reference-omitted citations "u-slide-3:source-4" \
  check-composition --brief "$NBRIEF" --composition "$WORK/citation-omitted.json"

derive "$NARR" "$WORK/evidence-omitted.json" <<'PY'
u = unit("u-slide-3")
u["bindings"] = [b for b in u["bindings"] if b["field"] != "evidence_status"]
PY
check_rejection "dcmp-22-evidence-omitted" 1 reference-omitted evidence_status "slide-3#evidence_status" \
  check-composition --brief "$NBRIEF" --composition "$WORK/evidence-omitted.json"

derive "$NARR" "$WORK/trailer-omitted.json" <<'PY'
del d["document_bindings"][3]
PY
check_rejection "dcmp-23-trailer-note-omitted" 1 reference-omitted trailer_notes "trailer_notes[3]" \
  check-composition --brief "$NBRIEF" --composition "$WORK/trailer-omitted.json"

# --- quantitative provenance ----------------------------------------------------------------

# dcmp-24: every plotted point resolves to a supplied data item with a numeric value, one unit
# of measure, and sources that resolve and travel in the unit's citations.
if python3 "$VALIDATOR" check-composition --brief "$CBRIEF" --composition "$COSTS" > "$WORK/costs-check.json" &&
   python3 - "$WORK/costs-check.json" "$CBRIEF" "$COSTS" <<'PY'
import json, sys
env, brief, composition = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:])
assert env["success"] is True and env["data"]["coverage"]["data"] == {"expected": 4, "bound": 4}
chart = next(u for u in composition["units"] if u["id"] == "u-components")
data = {item["id"]: item for item in brief["data"]}
sources = {source["id"] for source in brief["sources"]}
assert [point["data_ref"] for point in chart["data_bindings"]] == [item["id"] for item in brief["data"]]
for point in chart["data_bindings"]:
    assert set(point) == {"slot", "data_ref"}, point
    item = data[point["data_ref"]]
    assert isinstance(item["value"], (int, float)) and item["unit"] == "million euros"
    assert item["source_refs"] and set(item["source_refs"]) <= sources & set(chart["source_refs"])
PY
then pass "dcmp-24-sourced-chart-green"; else fail "dcmp-24-sourced-chart-green"; fi

derive "$CBRIEF" "$WORK/brief-unsourced.json" <<'PY'
item("downtime")["source_refs"] = []
PY
derive "$COSTS" "$WORK/costs-draft.json" <<'PY'
strip()
PY
check_rejection "dcmp-25-unsourced-chart-data" 1 unsourced-chart-data chart-provenance downtime \
  compose --brief "$WORK/brief-unsourced.json" --composition "$WORK/costs-draft.json"

derive "$COSTS" "$WORK/invented-value.json" <<'PY'
unit("u-components")["data_bindings"][1]["value"] = 18.0
PY
check_rejection "dcmp-26-invented-value" 1 invented-value chart-provenance wage-premium \
  check-composition --brief "$CBRIEF" --composition "$WORK/invented-value.json"

derive "$CBRIEF" "$WORK/brief-mixed-units.json" <<'PY'
item("insurance-surcharge")["unit"] = "percent"
PY
check_rejection "dcmp-27-mismatched-unit" 1 mismatched-unit chart-units insurance-surcharge \
  compose --brief "$WORK/brief-mixed-units.json" --composition "$WORK/costs-draft.json"

derive "$COSTS" "$WORK/absent-dataset.json" <<'PY'
unit("u-components")["data_bindings"][0]["data_ref"] = "no-such-series"
PY
check_rejection "dcmp-28-absent-dataset" 1 absent-dataset chart-provenance no-such-series \
  check-composition --brief "$CBRIEF" --composition "$WORK/absent-dataset.json"

derive "$NARR" "$WORK/chart-without-data.json" <<'PY'
u = unit("u-slide-6")
u["pattern"], u["variant"] = "sourced-chart", "bar"
for binding in u["bindings"]:
    binding["slot"] = {"answer": "claim", "support": "context"}.get(binding["slot"], binding["slot"])
PY
check_rejection "dcmp-29-chart-without-dataset" 1 absent-dataset chart-series u-slide-6 \
  check-composition --brief "$NBRIEF" --composition "$WORK/chart-without-data.json"

# dcmp-30: the conceptual diagrams relate named entities and carry no number but the index of
# the list item each entity names — and they validate without any dataset.
if python3 "$VALIDATOR" check-composition --brief "$NBRIEF" --composition "$NARR" > /dev/null &&
   python3 - "$NARR" "$LIBRARY" <<'PY'
import json, sys
composition, library = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:])
patterns = {p["id"]: p for p in library["patterns"]}
systems = [u for u in composition["units"] if patterns[u["pattern"]]["family"] == "system"]
assert len(systems) == 2
def numbers(node, key=None):
    if isinstance(node, dict):
        for k, v in node.items():
            yield from numbers(v, k)
    elif isinstance(node, list):
        for v in node:
            yield from numbers(v, key)
    elif isinstance(node, (int, float)) and not isinstance(node, bool):
        yield key
for unit in systems:
    variant = next(v for v in patterns[unit["pattern"]]["variants"] if v["id"] == unit["variant"])
    assert len(unit["entities"]) >= 2 and "data_bindings" not in unit
    assert unit["relationships"] and all(r["kind"] in variant["relationships"] for r in unit["relationships"])
    assert set(numbers(unit)) == {"item"}, set(numbers(unit))
PY
then pass "dcmp-30-system-without-measurement"; else fail "dcmp-30-system-without-measurement"; fi

derive "$NARR" "$WORK/system-measurement.json" <<'PY'
unit("u-slide-4")["relationships"][0]["weight"] = 3
PY
check_rejection "dcmp-31-system-measurement" 1 invented-value system-measurement u-slide-4 \
  check-composition --brief "$NBRIEF" --composition "$WORK/system-measurement.json"

derive "$NARR" "$WORK/entity-dropped.json" <<'PY'
u = unit("u-slide-4")
u["entities"] = [e for e in u["entities"] if e["id"] != "e3"]
u["relationships"] = [r for r in u["relationships"] if "e3" not in (r["from"], r["to"])]
PY
check_rejection "dcmp-32-entity-dropped" 1 unbound-content entities "slide-4#slide_points[2]" \
  check-composition --brief "$NBRIEF" --composition "$WORK/entity-dropped.json"

# --- fit, eligibility and targets -----------------------------------------------------------

# dcmp-33: content that does not fit fails with an actionable finding naming the unit, the
# pattern and the limit — and nothing is truncated, added or rewritten to make it fit.
derive "$NARR" "$WORK/oversized.json" <<'PY'
unit("u-slide-1")["variant"] = "statement"
PY
before_hash="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$WORK/oversized.json")"
rc=0
python3 "$VALIDATOR" check-composition --brief "$NBRIEF" --composition "$WORK/oversized.json" \
  > "$WORK/oversized.out" 2> "$WORK/oversized.err" || rc=$?
if [ "$rc" -eq 1 ] && [ ! -s "$WORK/oversized.err" ] &&
   python3 - "$WORK/oversized.out" "$WORK/oversized.json" "$before_hash" <<'PY'
import hashlib, json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
assert hashlib.sha256(open(sys.argv[2], "rb").read()).hexdigest() == sys.argv[3], "the input was rewritten"
assert env["success"] is False and set(env["data"]) == {"code", "check", "artifact", "reference"}, env
assert env["data"]["code"] == "impossible-fit" and env["data"]["check"] == "support.max_items"
assert env["data"]["reference"] == "u-slide-1:answer-emphasis/statement"
assert "4 items" in env["error"] and "maximum of 3" in env["error"] and "never truncated" in env["error"]
PY
then pass "dcmp-33-oversized"; else fail "dcmp-33-oversized"; fi

derive "$NARR" "$WORK/unsupported-shape.json" <<'PY'
u = unit("u-slide-3")
u["pattern"], u["variant"] = "comparison", "parallel"
for binding in u["bindings"]:
    binding["slot"] = {"entities": "items"}.get(binding["slot"], binding["slot"])
del u["entities"], u["relationships"]
PY
check_rejection "dcmp-34-unsupported-shape" 1 ineligible-pattern eligibility.slide_types "u-slide-3:comparison/parallel" \
  check-composition --brief "$NBRIEF" --composition "$WORK/unsupported-shape.json"

derive "$NARR" "$WORK/typography.json" <<'PY'
unit("u-slide-7")["type_floor"] = "type.caption"
PY
check_rejection "dcmp-35-typography-relaxed" 1 typography-relaxed min_type_role "u-slide-7:answer-emphasis/statement" \
  check-composition --brief "$NBRIEF" --composition "$WORK/typography.json"

derive "$NARR" "$WORK/target-document.json" <<'PY'
d["targets"].append("document")
PY
check_rejection "dcmp-36-unsupported-target" 1 unsupported-capability target document \
  check-composition --brief "$NBRIEF" --composition "$WORK/target-document.json"

derive "$LIBRARY" "$WORK/library-no-pptx-chart.json" <<'PY'
del pattern("sourced-chart")["target_capabilities"]["pptx"]
PY
check_rejection "dcmp-37-capability-gap" 1 unsupported-capability target-capabilities "u-components:sourced-chart@pptx" \
  check-composition --brief "$CBRIEF" --composition "$COSTS" --patterns "$WORK/library-no-pptx-chart.json"

derive "$NARR" "$WORK/unknown-pattern.json" <<'PY'
unit("u-slide-2")["pattern"] = "hero-banner"
PY
check_rejection "dcmp-38-unknown-pattern" 1 unknown-pattern pattern hero-banner \
  check-composition --brief "$NBRIEF" --composition "$WORK/unknown-pattern.json"

# --- bounded repair -------------------------------------------------------------------------

digest_py='import hashlib, json
def digest(value):
    text = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()'

# dcmp-39: switching to an eligible declared variant is a valid repair, and the content
# fingerprint survives it byte for byte.
if python3 "$VALIDATOR" check-repair --brief "$NBRIEF" --before "$WORK/oversized.json" --after "$NARR" > "$WORK/repair.json" &&
   DIGEST_PY="$digest_py" python3 - "$WORK/repair.json" "$WORK/oversized.json" "$NARR" "$NBRIEF" <<'PY'
import json, os, sys
exec(os.environ["DIGEST_PY"])
env, before, after, brief = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:])
assert env["success"] is True
assert env["data"]["repaired_units"] == [{"unit": "u-slide-1", "before": "answer-emphasis/statement",
                                          "after": "answer-emphasis/statement-with-support"}]
fingerprint = digest({k: brief.get(k) for k in ("document", "structure", "records", "data", "sources", "freeze")})
assert env["data"]["content_fingerprint"] == fingerprint
assert before["normalized_brief_ref"]["content_fingerprint"] == after["normalized_brief_ref"]["content_fingerprint"] == fingerprint
PY
then pass "dcmp-39-repair-eligible-variant"; else fail "dcmp-39-repair-eligible-variant"; fi

check_rejection "dcmp-40-repair-changed-content" 1 fingerprint-mismatch content-fingerprint - \
  check-repair --brief "$WORK/brief-headline-edited.json" --before "$NARR" --after "$NARR"

check_rejection "dcmp-41-repair-reordered" 1 invalid-repair units u-slide-2 \
  check-repair --brief "$NBRIEF" --before "$NARR" --after "$WORK/reordered.json"

derive "$NARR" "$WORK/repair-sources.json" <<'PY'
unit("u-slide-2")["source_refs"].reverse()
PY
check_rejection "dcmp-42-repair-source-identity" 1 invalid-repair source_refs u-slide-2 \
  check-repair --brief "$NBRIEF" --before "$NARR" --after "$WORK/repair-sources.json"

derive "$NARR" "$WORK/repair-fingerprint.json" <<'PY'
d["normalized_brief_ref"]["content_fingerprint"] = "sha256:" + "0" * 64
PY
check_rejection "dcmp-43-repair-fingerprint-declared" 1 fingerprint-mismatch content-fingerprint - \
  check-repair --brief "$NBRIEF" --before "$NARR" --after "$WORK/repair-fingerprint.json"

# --- proposed versus accepted patterns ------------------------------------------------------

PROPOSED="$FIXTURES/pattern-proposed-timeline.json"
PROPOSED="$PROPOSED" derive "$LIBRARY" "$WORK/library-proposed.json" <<'PY'
import os
d["patterns"].append(json.load(open(os.environ["PROPOSED"], encoding="utf-8")))
PY

# dcmp-44: a proposed pattern with a passing specimen is listed as ready for acceptance and
# never joins the accepted set on its own.
if python3 "$VALIDATOR" check-patterns --patterns "$WORK/library-proposed.json" > "$WORK/proposed.json" &&
   python3 - "$WORK/proposed.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
assert env["success"] is True
assert env["data"]["accepted"] == ["answer-emphasis", "comparison", "sourced-chart", "conceptual-system", "sources"]
assert env["data"]["proposed"] == [{"id": "timeline-sequence", "ready_for_acceptance": True, "blocked_by": None}]
PY
then pass "dcmp-44-proposed-pattern-listed"; else fail "dcmp-44-proposed-pattern-listed"; fi

derive "$NARR" "$WORK/uses-proposed.json" <<'PY'
unit("u-slide-3")["pattern"] = "timeline-sequence"
PY
check_rejection "dcmp-45-unaccepted-pattern" 1 unaccepted-pattern pattern-status timeline-sequence \
  check-composition --brief "$NBRIEF" --composition "$WORK/uses-proposed.json" --patterns "$WORK/library-proposed.json"

derive "$WORK/library-proposed.json" "$WORK/library-promoted.json" <<'PY'
pattern("timeline-sequence")["status"] = "accepted"
PY
if python3 "$VALIDATOR" check-composition --brief "$NBRIEF" --composition "$WORK/uses-proposed.json" \
     --patterns "$WORK/library-promoted.json" > "$WORK/promoted.json" &&
   python3 -c 'import json,sys; env=json.load(open(sys.argv[1])); assert env["success"] and env["data"]["patterns"]["timeline-sequence"] == 1' "$WORK/promoted.json"
then pass "dcmp-46-promoted-pattern-usable"; else fail "dcmp-46-promoted-pattern-usable"; fi

derive "$WORK/library-proposed.json" "$WORK/library-unready.json" <<'PY'
pattern("timeline-sequence")["examples"] = []
PY
if python3 "$VALIDATOR" check-patterns --patterns "$WORK/library-unready.json" > "$WORK/unready.json" &&
   python3 -c 'import json,sys; env=json.load(open(sys.argv[1])); assert env["success"] and env["data"]["proposed"][0]["ready_for_acceptance"] is False' "$WORK/unready.json"
then pass "dcmp-47-proposed-not-ready"; else fail "dcmp-47-proposed-not-ready"; fi

derive "$WORK/library-unready.json" "$WORK/library-unproven.json" <<'PY'
pattern("timeline-sequence")["status"] = "accepted"
PY
check_rejection "dcmp-48-accepted-needs-specimen" 1 invalid-pattern examples timeline-sequence \
  check-patterns --patterns "$WORK/library-unproven.json"

# dcmp-49: the skill's routing rule — the prose half of the proposed/accepted gate — is stated
# once and names the command and finding that enforce it.
if python3 - "$SKILL" "$REFERENCE" <<'PY'
import re, sys
skill = open(sys.argv[1], encoding="utf-8").read()
reference = open(sys.argv[2], encoding="utf-8").read()
assert skill.count("Never route a proposed pattern into a production composition") == 1
assert "check-patterns" in skill and "unaccepted-pattern" in skill
assert "\n## Extension workflow\n" in reference
section = re.split(r"\n## ", reference.split("\n## Extension workflow\n", 1)[1], maxsplit=1)[0]
assert "`proposed`" in section and "`accepted`" in section and "unaccepted-pattern" in section
PY
then pass "dcmp-49-skill-proposed-routing"; else fail "dcmp-49-skill-proposed-routing"; fi

# --- chain boundary and envelopes -----------------------------------------------------------

python3 - "$CBRIEF" "$COSTS" "$WORK/chain-v2.json" <<'PY'
import json, sys
brief = json.load(open(sys.argv[1], encoding="utf-8"))
composition = json.load(open(sys.argv[2], encoding="utf-8"))
plan = {
    "artifact_type": "target-resolved-plan", "artifact_version": "1", "artifact_id": "plan:cost-of-inaction",
    "composition_ref": {"artifact_id": composition["artifact_id"], "artifact_version": "2"},
    "normalized_brief_ref": {"artifact_id": brief["artifact_id"], "artifact_version": "1"},
    "target": "slides", "design_system": {"name": "cogni-work", "version": "1.0.0"}, "units": [],
}
chain = {"normalized_brief": brief, "semantic_composition": composition, "target_resolved_plan": plan}
json.dump(chain, open(sys.argv[3], "w", encoding="utf-8"), ensure_ascii=False)
PY
check_rejection "dcmp-50-chain-rejects-composition-v2" 1 invalid-version version-compatibility semantic-composition@2 \
  validate --input "$WORK/chain-v2.json"

check_rejection "dcmp-51-usage-error" 2 usage-error - - check-composition --brief "$NBRIEF"

printf '%s\n' '{not json' > "$WORK/malformed.json"
check_rejection "dcmp-52-malformed-composition" 2 runtime-error - - \
  check-composition --brief "$NBRIEF" --composition "$WORK/malformed.json"

check_rejection "dcmp-53-missing-library" 2 runtime-error - - check-patterns --patterns "$WORK/no-such-library.json"

printf '%s\n' '[]' > "$WORK/not-object.json"
check_rejection "dcmp-54-composition-not-object" 1 invalid-artifact composition - \
  check-composition --brief "$NBRIEF" --composition "$WORK/not-object.json"

# dcmp-55: a repair may also swap to another eligible pattern whose slots take the same
# content, renaming slots only — every record, field, digest and citation stays put.
derive "$NARR" "$WORK/pattern-swap.json" <<'PY'
u = unit("u-slide-6")
u["pattern"], u["variant"] = "comparison", "parallel"
for binding in u["bindings"]:
    binding["slot"] = {"answer": "claim", "support": "items"}.get(binding["slot"], binding["slot"])
PY
if python3 "$VALIDATOR" check-repair --brief "$NBRIEF" --before "$NARR" --after "$WORK/pattern-swap.json" > "$WORK/swap.json" &&
   python3 - "$WORK/swap.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
assert env["success"] is True
assert env["data"]["repaired_units"] == [{"unit": "u-slide-6", "before": "answer-emphasis/statement",
                                          "after": "comparison/parallel"}]
assert len(env["data"]["unchanged_units"]) == 7
PY
then pass "dcmp-55-repair-pattern-swap"; else fail "dcmp-55-repair-pattern-swap"; fi

check_rejection "dcmp-56-envelope-as-brief" 1 invalid-artifact brief - \
  check-composition --brief "$WORK/costs-env.json" --composition "$COSTS"

# dcmp-57: a brief that carries sources needs a register; a direct composition that leaves
# the sources unit out is rejected, not passed with unregistered sources.
derive "$COSTS" "$WORK/register-omitted.json" <<'PY'
d["units"] = [u for u in d["units"] if u["id"] != "u-sources"]
PY
check_rejection "dcmp-57-register-omitted" 1 reference-omitted register fraunhofer-2025 \
  check-composition --brief "$CBRIEF" --composition "$WORK/register-omitted.json"

# dcmp-58: a unit role is a short kebab-case token; frozen copy smuggled into it is rejected.
derive "$NARR" "$WORK/role-headline.json" <<'PY'
unit("u-slide-2")["role"] = "Reliability is an information problem, not a spending problem"
PY
check_rejection "dcmp-58-role-copied-headline" 1 unexpected-field role u-slide-2 \
  check-composition --brief "$NBRIEF" --composition "$WORK/role-headline.json"

# dcmp-59: a malformed brief record is a named finding, never a runtime error.
derive "$CBRIEF" "$WORK/brief-bad-source-refs.json" <<'PY'
record("answer")["source_refs"] = None
PY
check_rejection "dcmp-59-brief-malformed-source-refs" 1 invalid-artifact records answer \
  check-composition --brief "$WORK/brief-bad-source-refs.json" --composition "$COSTS"

# dcmp-60: design_system pins a name and a version and nothing else.
derive "$COSTS" "$WORK/design-system-extra.json" <<'PY'
d["design_system"]["canvas"] = "16:9 widescreen"
PY
check_rejection "dcmp-60-design-system-extra-key" 1 unexpected-field design-system canvas \
  check-composition --brief "$CBRIEF" --composition "$WORK/design-system-extra.json"

# --- declared picture fallbacks ------------------------------------------------------------------

# dcmp-61: the bundled library declares exactly one variant-level fallback — on
# conceptual-system/feedback-loop, a figure pattern — for the pptx target, naming a capability
# that target offers and no pattern lists in its own target_capabilities, with a non-empty reason;
# check-patterns accepts the library with that pattern accepted; the variant schema requires target,
# capability and reason; and the prose catalogue names the capability.
if python3 "$VALIDATOR" check-patterns > "$WORK/fallback-patterns.json" &&
   python3 - "$WORK/fallback-patterns.json" "$LIBRARY" "$PLUGIN_ROOT/references" "$REFERENCE" <<'PY'
import json, sys
env = json.load(open(sys.argv[1], encoding="utf-8"))
library = json.load(open(sys.argv[2], encoding="utf-8"))
schema = json.load(open(f"{sys.argv[3]}/pattern-contract-v1.schema.json", encoding="utf-8"))
prose = open(sys.argv[4], encoding="utf-8").read()
assert env["success"] is True and "conceptual-system" in env["data"]["accepted"], env
declared = [(p, v) for p in library["patterns"] for v in p["variants"] if "fallback" in v]
assert len(declared) == 1, [(p["id"], v["id"]) for p, v in declared]
pattern, variant = declared[0]
fallback = variant["fallback"]
assert (pattern["id"], variant["id"]) == ("conceptual-system", "feedback-loop"), (pattern["id"], variant["id"])
assert pattern["accessibility"]["role"] == "figure"
assert set(fallback) == {"target", "capability", "reason"} and fallback["target"] == "pptx", fallback
assert fallback["capability"] in library["targets"]["pptx"]["capabilities"], fallback
assert all(fallback["capability"] not in p["target_capabilities"].get("pptx", []) for p in library["patterns"])
assert fallback["reason"].strip()
defn = schema["$defs"]["variant"]["properties"]["fallback"]
assert defn["required"] == ["target", "capability", "reason"] and defn["additionalProperties"] is False, defn
assert f"`{fallback['capability']}`" in prose and "`fallback`" in prose
PY
then pass "dcmp-61-fallback-declared"; else fail "dcmp-61-fallback-declared"; fi

# dcmp-62..67: a malformed variant fallback is rejected as invalid-pattern under check variants, naming
# the variant — a capability its target does not offer, an empty and a missing reason, a declaration
# on a pattern that is not a figure, a target the library does not define, and an extra key.
derive "$LIBRARY" "$WORK/fallback-unknown-capability.json" <<'PY'
next(v for v in pattern("conceptual-system")["variants"] if v["id"] == "feedback-loop")["fallback"]["capability"] = "svg-figure"
PY
check_rejection "dcmp-62-fallback-unknown-capability" 1 invalid-pattern variants conceptual-system/feedback-loop \
  check-patterns --patterns "$WORK/fallback-unknown-capability.json"
derive "$LIBRARY" "$WORK/fallback-empty-reason.json" <<'PY'
next(v for v in pattern("conceptual-system")["variants"] if v["id"] == "feedback-loop")["fallback"]["reason"] = "  "
PY
check_rejection "dcmp-63-fallback-empty-reason" 1 invalid-pattern variants conceptual-system/feedback-loop \
  check-patterns --patterns "$WORK/fallback-empty-reason.json"
derive "$LIBRARY" "$WORK/fallback-missing-reason.json" <<'PY'
del next(v for v in pattern("conceptual-system")["variants"] if v["id"] == "feedback-loop")["fallback"]["reason"]
PY
check_rejection "dcmp-64-fallback-missing-reason" 1 invalid-pattern variants conceptual-system/feedback-loop \
  check-patterns --patterns "$WORK/fallback-missing-reason.json"
derive "$LIBRARY" "$WORK/fallback-non-figure.json" <<'PY'
pattern("answer-emphasis")["variants"][0]["fallback"] = {"target": "pptx", "capability": "picture-fallback", "reason": "A statement drawn as a picture."}
PY
check_rejection "dcmp-65-fallback-non-figure" 1 invalid-pattern variants answer-emphasis/statement \
  check-patterns --patterns "$WORK/fallback-non-figure.json"
derive "$LIBRARY" "$WORK/fallback-unknown-target.json" <<'PY'
next(v for v in pattern("conceptual-system")["variants"] if v["id"] == "feedback-loop")["fallback"]["target"] = "docx"
PY
check_rejection "dcmp-66-fallback-unknown-target" 1 invalid-pattern variants conceptual-system/feedback-loop \
  check-patterns --patterns "$WORK/fallback-unknown-target.json"
derive "$LIBRARY" "$WORK/fallback-extra-key.json" <<'PY'
next(v for v in pattern("conceptual-system")["variants"] if v["id"] == "feedback-loop")["fallback"]["alt"] = "a picture"
PY
check_rejection "dcmp-67-fallback-extra-key" 1 invalid-pattern variants conceptual-system/feedback-loop \
  check-patterns --patterns "$WORK/fallback-extra-key.json"

printf '%s\n' "Design-compose tests: $passes passed, $failures failed"
[ "$failures" -eq 0 ]
