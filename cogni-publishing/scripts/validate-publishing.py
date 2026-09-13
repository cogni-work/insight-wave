#!/usr/bin/env python3
"""Normalize publishing briefs and validate cogni-publishing v1 artifact chains.

Stdlib only. Every invocation prints exactly one JSON envelope,
{"success": bool, "data": {...}, "error": str|null}, and exits 0 when the input
is valid, 1 when it violates a publishing contract, and 2 on a usage or runtime
error. A rejected input never emits a downstream artifact: the failure `data`
carries the finding (code, check, artifact, reference) and nothing else.

The validator reads only the files it is handed. It never consults the
environment, the home directory, or any sibling plugin, so it behaves the same
with or without cogni-workspace installed.
"""

import argparse
import json
import re
import sys
from pathlib import Path

SUPPORTED = {
    "direct-brief": {"1"},
    "design-brief": {"1.1"},
    "normalized-brief": {"1"},
    "semantic-composition": {"1"},
    "target-resolved-plan": {"1"},
}
# The upstream artifact versions each downstream artifact version accepts.
# A new contract version lands here and in references/artifact-contracts.md together.
COMPATIBLE = {
    ("semantic-composition", "1"): {"normalized-brief": {"1"}},
    ("target-resolved-plan", "1"): {"semantic-composition": {"1"}, "normalized-brief": {"1"}},
}
CHAIN_SLOTS = (
    ("normalized_brief", "normalized-brief"),
    ("semantic_composition", "semantic-composition"),
    ("target_resolved_plan", "target-resolved-plan"),
)

# The narrative adapter is bounded to the slides target of design-brief@1.1.
NARRATIVE_TARGETS = {"slides"}
SLIDE_FIELDS = ("type", "evidence_status", "element", "visual_intent", "slide_points", "talk_track")
SLIDE_TYPES = {"cover", "bluf", "two-column", "table", "timeline", "quote", "metric", "roles", "sources"}
EVIDENCE_STATUSES = {"direct", "triangulated", "proxy", "interpretation", "mixed"}
CONTRACT_HEADINGS = {"# Rendering Contract", "# Rendering-Vertrag"}
METADATA_KEYS = ("title", "language", "arc_id", "arc_display_name", "governing_thought", "source_narrative")

# Downstream units reference copy; they never carry it.
COMPOSITION_UNIT_KEYS = {"id", "role", "copy_refs", "data_refs"}
TARGET_UNIT_KEYS = {"composition_unit_ref", "copy_refs", "data_refs", "layout", "emphasis"}

DEFAULTS = {"target": "slides", "language": "en", "renderer": None}
SETTABLE_KEYS = ("target", "language")
EXACT_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
RENDERER_CONSUMES = "target-resolved-plan@1"

UNIT_HEADING = re.compile(r"^## Slide ([0-9]+): (.+)$")
FIELD_LINE = re.compile(r"^([a-z_]+):(?: (.*))?$")
MAPPING_LINE = re.compile(r"^  ([a-z_]+): (.+)$")
SOURCE_LINE = re.compile(r"^\[([0-9]+)\] (.+)$")
CITATION = re.compile(r"\[([0-9]+)\]")
URL = re.compile(r"https?://\S+")


class ContractError(Exception):
    def __init__(self, code, message, check, artifact=None, reference=None):
        super().__init__(message)
        self.finding = {"code": code, "check": check}
        if artifact is not None:
            self.finding["artifact"] = artifact
        if reference is not None:
            self.finding["reference"] = reference


class UsageError(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise UsageError(message)


def envelope(success, data, error):
    return {"success": success, "data": data, "error": error}


def version_supported(artifact_version, supported_versions):
    return artifact_version in supported_versions


def reference_resolves(reference_id, available_ids):
    return reference_id in available_ids


def require_version(artifact, slot):
    kind = artifact.get("artifact_type")
    version = artifact.get("artifact_version")
    if kind not in SUPPORTED:
        raise ContractError("invalid-artifact", f"{slot} has unknown artifact_type {kind!r}",
                            check="artifact-type", artifact=slot)
    if not isinstance(version, str) or not version_supported(version, SUPPORTED[kind]):
        raise ContractError("invalid-version", f"{slot} is {kind}@{version}, which this validator does not support",
                            check="artifact-version", artifact=slot, reference=f"{kind}@{version}")


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError(f"cannot read input {path}: {exc}") from exc


def read_json(path):
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"input {path} is not JSON: {exc}") from exc


def collect_ids(items, slot, field, code="invalid-artifact"):
    if not isinstance(items, list):
        raise ContractError(code, f"{slot}.{field} must be a list", check=field, artifact=slot)
    seen = set()
    for item in items:
        item_id = item.get("id") if isinstance(item, dict) else None
        if not isinstance(item_id, str) or not item_id:
            raise ContractError(code, f"every {slot}.{field} entry needs a non-empty string id",
                                check=field, artifact=slot)
        if item_id in seen:
            raise ContractError(code, f"{slot}.{field} repeats id {item_id}", check=field,
                                artifact=slot, reference=item_id)
        seen.add(item_id)
    return seen


def check_refs(refs, available_ids, slot, owner, field):
    if not isinstance(refs, list):
        raise ContractError("malformed-reference", f"{owner}.{field} must be a list of ids",
                            check=field, artifact=slot, reference=owner)
    for reference_id in refs:
        if not isinstance(reference_id, str) or not reference_id:
            raise ContractError("malformed-reference", f"{owner}.{field} holds a non-id value {reference_id!r}",
                                check=field, artifact=slot, reference=reference_id)
        if not reference_resolves(reference_id, available_ids):
            raise ContractError("dangling-reference", f"{owner}.{field} names {reference_id}, which nothing declares",
                                check=field, artifact=slot, reference=reference_id)


def check_artifact_ref(artifact, field, upstream, slot):
    ref = artifact.get(field)
    if not isinstance(ref, dict) or not isinstance(ref.get("artifact_id"), str) \
            or not isinstance(ref.get("artifact_version"), str):
        raise ContractError("malformed-reference", f"{slot}.{field} must be {{artifact_id, artifact_version}}",
                            check=field, artifact=slot)
    if not reference_resolves(ref["artifact_id"], {upstream["artifact_id"]}):
        raise ContractError("dangling-reference", f"{slot}.{field} names {ref['artifact_id']}, not the supplied "
                            f"{upstream['artifact_type']}", check=field, artifact=slot, reference=ref["artifact_id"])
    accepted = COMPATIBLE[(artifact["artifact_type"], artifact["artifact_version"])][upstream["artifact_type"]]
    declared = ref["artifact_version"]
    if declared != upstream["artifact_version"] or not version_supported(declared, accepted):
        raise ContractError("invalid-version", f"{slot} pins {upstream['artifact_type']}@{declared} but the chain "
                            f"supplies @{upstream['artifact_version']}", check="version-compatibility",
                            artifact=slot, reference=f"{upstream['artifact_type']}@{declared}")


# --- narrative adapter: design-brief@1.1, slides target -----------------------------------------

def parse_scalar(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_frontmatter(lines):
    if not lines or lines[0] != "---":
        raise ContractError("invalid-brief", "narrative brief requires YAML frontmatter", check="frontmatter")
    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise ContractError("invalid-brief", "narrative brief frontmatter is unterminated",
                            check="frontmatter") from exc
    frontmatter = {}
    for line in lines[1:end]:
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):(.*)$", line)
        if match:
            frontmatter[match.group(1)] = parse_scalar(match.group(2))
    return frontmatter, end


def close_field(field):
    if field is None:
        return
    if field["kind"] == "prose":
        lines = field["value"]
        while lines and not lines[-1].strip():
            lines.pop()
        field["value"] = "\n".join(lines)


def parse_slide_fields(body, unit_id):
    """Split a slide unit into ordered fields without rewriting a single value."""
    fields, current = [], None
    for line in body:
        match = FIELD_LINE.match(line)
        if match and match.group(1) in SLIDE_FIELDS:
            close_field(current)
            key, inline = match.group(1), match.group(2)
            if any(field["key"] == key for field in fields):
                raise ContractError("invalid-brief", f"{unit_id} repeats field {key}", check="slide-fields",
                                    reference=unit_id)
            current = {"key": key, "kind": "scalar", "value": inline} if inline else {"key": key, "kind": None}
            fields.append(current)
            if inline:
                current = None
            continue
        if current is None:
            if line.strip():
                raise ContractError("invalid-brief", f"{unit_id} carries content outside a supported slide field: "
                                    f"{line[:60]!r}", check="slide-fields", reference=unit_id)
            continue
        if current["kind"] is None:
            if not line.strip():
                continue
            if MAPPING_LINE.match(line):
                current["kind"], current["value"] = "mapping", []
            elif line.startswith("- "):
                current["kind"], current["value"] = "list", []
            else:
                current["kind"], current["value"] = "prose", []
        if current["kind"] == "prose":
            current["value"].append(line)
        elif not line.strip():
            continue
        elif current["kind"] == "mapping" and MAPPING_LINE.match(line):
            key, value = MAPPING_LINE.match(line).groups()
            current["value"].append({"key": key, "value": value})
        elif current["kind"] == "list" and line.startswith("- "):
            current["value"].append(line[2:])
        else:
            raise ContractError("invalid-brief", f"{unit_id}.{current['key']} mixes {current['kind']} with "
                                f"{line[:60]!r}", check="slide-fields", reference=unit_id)
    close_field(current)
    for field in fields:
        if field["kind"] is None:
            raise ContractError("invalid-brief", f"{unit_id}.{field['key']} is empty", check="slide-fields",
                                reference=unit_id)
    return fields


def field_value(fields, key):
    return next((field["value"] for field in fields if field["key"] == key), None)


def field_text(fields):
    for field in fields:
        if field["kind"] in ("scalar", "prose"):
            yield field["value"]
        elif field["kind"] == "list":
            yield from field["value"]
        else:
            yield from (item["value"] for item in field["value"])


def normalize_narrative(path):
    text = read_text(path)
    lines = text.splitlines()
    frontmatter, end = parse_frontmatter(lines)
    if frontmatter.get("type") != "design-brief":
        raise ContractError("invalid-brief", "the narrative adapter reads type: design-brief only",
                            check="frontmatter-type", reference=frontmatter.get("type"))
    require_version({"artifact_type": "design-brief", "artifact_version": frontmatter.get("version")},
                    "design_brief")
    target = frontmatter.get("target")
    if target not in NARRATIVE_TARGETS:
        raise ContractError("unsupported-target", f"the narrative adapter supports the slides target, not {target!r}",
                            check="narrative-target", artifact="design_brief", reference=target)

    body = lines[end + 1:]
    headings = [index for index, line in enumerate(body) if UNIT_HEADING.match(line)]
    if not headings:
        raise ContractError("invalid-brief", "narrative slides brief has no `## Slide N:` units", check="units")
    numbers = [int(UNIT_HEADING.match(body[index]).group(1)) for index in headings]
    if numbers != list(range(1, len(numbers) + 1)):
        raise ContractError("invalid-brief", f"slide units must be numbered 1..n without gaps, got {numbers}",
                            check="unit-numbering")

    preamble = body[:headings[0]]
    title = next((line[2:] for line in preamble if line.startswith("# ") and line not in CONTRACT_HEADINGS), None)
    subtitle = next((line for line in preamble if line.startswith("*") and line.endswith("*")
                     and not line.startswith("**")), None)
    contract_at = next((i for i, line in enumerate(preamble) if line in CONTRACT_HEADINGS), None)
    if contract_at is None:
        raise ContractError("invalid-brief", "narrative brief has no Rendering Contract heading",
                            check="rendering-contract")
    clauses = []
    for line in preamble[contract_at + 1:]:
        if line.startswith("- "):
            clauses.append(line[2:])
        elif line.strip() and clauses:
            break
    if not clauses:
        raise ContractError("invalid-brief", "the Rendering Contract carries no clauses", check="rendering-contract")

    trailer_at = next((i for i in range(headings[-1] + 1, len(body))
                       if body[i].startswith("note: ") or body[i] == "**Sources**"), len(body))
    sources_at = next((i for i in range(trailer_at, len(body)) if body[i] == "**Sources**"), None)
    if sources_at is None:
        raise ContractError("invalid-brief", "narrative brief has no **Sources** block", check="sources-block")
    trailer_notes = []
    for line in body[trailer_at:sources_at]:
        if line.startswith("note: "):
            trailer_notes.append(line[len("note: "):])
        elif line.strip():
            raise ContractError("invalid-brief", f"unexpected trailer line {line[:60]!r}", check="trailer")

    sources = []
    for line in body[sources_at + 1:]:
        if not line.strip():
            continue
        match = SOURCE_LINE.match(line)
        if not match:
            raise ContractError("invalid-brief", f"unexpected Sources line {line[:60]!r}", check="sources-block")
        number, rest = int(match.group(1)), match.group(2)
        urls = URL.findall(rest)
        head = rest.split(" — ", 1)[0]
        sources.append({
            "id": f"source-{number}",
            "marker": f"[{number}]",
            "file": head if head.endswith(".md") else None,
            "url": urls[-1] if urls else None,
            "raw": line,
        })
    source_ids = collect_ids(sources, "design_brief", "sources", code="invalid-brief")

    records = []
    stops = headings[1:] + [trailer_at]
    for number, (start, stop) in enumerate(zip(headings, stops), 1):
        unit_id = f"slide-{number}"
        heading = body[start]
        fields = parse_slide_fields(body[start + 1:stop], unit_id)
        slide_type = field_value(fields, "type")
        if slide_type not in SLIDE_TYPES:
            raise ContractError("invalid-brief", f"{unit_id} type {slide_type!r} is not a slides content shape",
                                check="slide-type", reference=unit_id)
        status = field_value(fields, "evidence_status")
        if status is not None and status not in EVIDENCE_STATUSES:
            raise ContractError("invalid-brief", f"{unit_id} evidence_status {status!r} is not a supported label",
                                check="evidence-status", reference=unit_id)
        headline = UNIT_HEADING.match(heading).group(2)
        refs = []
        for value in [headline, *field_text(fields)]:
            for marker in CITATION.findall(value):
                source_id = f"source-{int(marker)}"
                if source_id not in refs:
                    refs.append(source_id)
        for source_id in refs:
            if not reference_resolves(source_id, source_ids):
                raise ContractError("dangling-reference", f"{unit_id} cites {source_id}, which the Sources block "
                                    "does not carry", check="citation", artifact="design_brief", reference=source_id)
        raw_lines = body[start:stop]
        while raw_lines and not raw_lines[-1].strip():
            raw_lines = raw_lines[:-1]
        records.append({
            "id": unit_id,
            "order": number,
            "kind": "slide",
            "heading": heading,
            "headline": headline,
            "fields": fields,
            "source_refs": refs,
            "raw": "\n".join(raw_lines),
        })

    input_id = Path(path).stem
    return {
        "artifact_type": "normalized-brief",
        "artifact_version": "1",
        "artifact_id": f"normalized:{input_id}",
        "input_kind": "narrative",
        "target": target,
        "metadata": {key: frontmatter[key] for key in METADATA_KEYS if frontmatter.get(key)},
        "document": {"title": title, "subtitle": subtitle},
        "records": records,
        "data": [],
        "sources": sources,
        "freeze": {
            "copy": True,
            "notes": True,
            "order": True,
            "rendering_contract_heading": preamble[contract_at],
            "rendering_contract": clauses,
            "trailer_notes": trailer_notes,
        },
        "provenance": {
            "input_artifact_type": "design-brief",
            "input_artifact_version": frontmatter["version"],
            "input_artifact_id": input_id,
            "input_file": Path(path).name,
        },
    }


# --- direct adapter: direct-brief@1 -------------------------------------------------------------

def require_text(section, key, owner):
    value = section.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ContractError("invalid-brief", f"{owner} needs a non-empty {key}", check="direct-sections",
                            artifact="direct_brief", reference=owner)
    return value


def normalize_direct(path):
    source = read_json(path)
    if not isinstance(source, dict) or source.get("artifact_type") != "direct-brief":
        raise ContractError("invalid-brief", "direct input must be a direct-brief object", check="input-type")
    require_version(source, "direct_brief")
    artifact_id = require_text(source, "artifact_id", "direct_brief")
    structure = source.get("structure")
    if not isinstance(structure, dict) or not isinstance(structure.get("framework"), str) \
            or not structure["framework"].strip():
        raise ContractError("invalid-brief", "a direct brief declares its own structure.framework",
                            check="direct-structure", artifact="direct_brief")
    sources = source.get("sources", [])
    source_ids = collect_ids(sources, "direct_brief", "sources", code="invalid-brief")
    sections = source.get("sections")
    collect_ids(sections, "direct_brief", "sections", code="invalid-brief")
    if not sections:
        raise ContractError("invalid-brief", "a direct brief needs at least one ordered section",
                            check="direct-sections", artifact="direct_brief")

    records, data, data_ids = [], [], set()
    for order, section in enumerate(sections, 1):
        owner = f"section {section['id']}"
        record = {"id": section["id"], "order": order, "kind": "section"}
        if "role" in section:
            record["role"] = section["role"]
        record["title"] = require_text(section, "title", owner)
        record["body"] = require_text(section, "body", owner)
        if "notes" in section:
            record["notes"] = require_text(section, "notes", owner)
        check_refs(section.get("source_refs", []), source_ids, "direct_brief", owner, "source_refs")
        record["source_refs"] = list(section.get("source_refs", []))
        items = section.get("data", [])
        item_ids = collect_ids(items, "direct_brief", f"{section['id']}.data", code="invalid-brief")
        repeated = item_ids & data_ids
        if repeated:
            raise ContractError("invalid-brief", f"data id {sorted(repeated)[0]} is used twice", check="data",
                                artifact="direct_brief", reference=sorted(repeated)[0])
        data_ids |= item_ids
        for item in items:
            check_refs(item.get("source_refs", []), source_ids, "direct_brief", f"data {item['id']}", "source_refs")
            data.append({**item, "record_ref": section["id"]})
        record["data_refs"] = [item["id"] for item in items]
        records.append(record)

    return {
        "artifact_type": "normalized-brief",
        "artifact_version": "1",
        "artifact_id": f"normalized:{artifact_id}",
        "input_kind": "direct",
        "structure": structure,
        "document": {"title": source.get("title")},
        "records": records,
        "data": data,
        "sources": sources,
        "freeze": {"copy": True, "notes": True, "order": True},
        "provenance": {
            "input_artifact_type": "direct-brief",
            "input_artifact_version": source["artifact_version"],
            "input_artifact_id": artifact_id,
            "input_file": Path(path).name,
        },
    }


# --- artifact chain -----------------------------------------------------------------------------

def check_unit_keys(unit, allowed, slot, owner):
    extra = sorted(set(unit) - allowed)
    if extra:
        raise ContractError("unexpected-field", f"{owner} carries {extra}; downstream units reference copy "
                            "and never carry it", check="unit-fields", artifact=slot, reference=owner)


def validate_chain(chain):
    if not isinstance(chain, dict):
        raise ContractError("invalid-artifact", "an artifact chain is a JSON object", check="chain")
    artifacts = {}
    for slot, kind in CHAIN_SLOTS:
        artifact = chain.get(slot)
        if not isinstance(artifact, dict):
            raise ContractError("invalid-artifact", f"the chain has no {slot}", check="chain", artifact=slot)
        if artifact.get("artifact_type") != kind:
            raise ContractError("invalid-artifact", f"{slot} must be a {kind}", check="artifact-type", artifact=slot)
        require_version(artifact, slot)
        if not isinstance(artifact.get("artifact_id"), str) or not artifact["artifact_id"]:
            raise ContractError("invalid-artifact", f"{slot} needs an artifact_id", check="artifact-id", artifact=slot)
        artifacts[slot] = artifact
    normalized = artifacts["normalized_brief"]
    composition = artifacts["semantic_composition"]
    plan = artifacts["target_resolved_plan"]

    record_ids = collect_ids(normalized.get("records"), "normalized_brief", "records")
    data_ids = collect_ids(normalized.get("data", []), "normalized_brief", "data")
    for item in normalized.get("data", []):
        check_refs([item.get("record_ref")], record_ids, "normalized_brief", f"data {item['id']}", "record_ref")

    check_artifact_ref(composition, "normalized_brief_ref", normalized, "semantic_composition")
    units = composition.get("units")
    unit_ids = collect_ids(units, "semantic_composition", "units")
    for unit in units:
        owner = f"unit {unit['id']}"
        check_unit_keys(unit, COMPOSITION_UNIT_KEYS, "semantic_composition", owner)
        check_refs(unit.get("copy_refs", []), record_ids, "semantic_composition", owner, "copy_refs")
        check_refs(unit.get("data_refs", []), data_ids, "semantic_composition", owner, "data_refs")

    check_artifact_ref(plan, "composition_ref", composition, "target_resolved_plan")
    check_artifact_ref(plan, "normalized_brief_ref", normalized, "target_resolved_plan")
    if not isinstance(plan.get("target"), str) or not plan["target"]:
        raise ContractError("invalid-artifact", "a target-resolved plan names its target", check="target",
                            artifact="target_resolved_plan")
    design = plan.get("design_system")
    if not isinstance(design, dict) or not all(isinstance(design.get(key), str) and design[key]
                                               for key in ("name", "version")):
        raise ContractError("invalid-artifact", "a target-resolved plan pins design_system {name, version}",
                            check="design-system", artifact="target_resolved_plan")
    plan_units = plan.get("units")
    if not isinstance(plan_units, list):
        raise ContractError("invalid-artifact", "target_resolved_plan.units must be a list", check="units",
                            artifact="target_resolved_plan")
    for index, unit in enumerate(plan_units, 1):
        if not isinstance(unit, dict):
            raise ContractError("invalid-artifact", "every plan unit is an object", check="units",
                                artifact="target_resolved_plan")
        owner = f"plan unit {index}"
        check_unit_keys(unit, TARGET_UNIT_KEYS, "target_resolved_plan", owner)
        check_refs([unit.get("composition_unit_ref")], unit_ids, "target_resolved_plan", owner,
                   "composition_unit_ref")
        check_refs(unit.get("copy_refs", []), record_ids, "target_resolved_plan", owner, "copy_refs")
        check_refs(unit.get("data_refs", []), data_ids, "target_resolved_plan", owner, "data_refs")

    return {
        "valid": True,
        "artifacts": [{"slot": slot, "artifact_type": artifacts[slot]["artifact_type"],
                       "artifact_version": artifacts[slot]["artifact_version"],
                       "artifact_id": artifacts[slot]["artifact_id"]} for slot, _ in CHAIN_SLOTS],
        "records": len(record_ids),
        "data": len(data_ids),
        "composition_units": len(unit_ids),
        "plan_units": len(plan_units),
    }


# --- configuration ------------------------------------------------------------------------------

def read_config(path, layer):
    config = read_json(path)
    if not isinstance(config, dict):
        raise ContractError("invalid-config", f"the {layer} configuration must be a JSON object",
                            check="config-shape", reference=layer)
    return config


def check_renderer_pin(renderer, origin):
    if renderer is None:
        return
    pinned = isinstance(renderer, dict) and isinstance(renderer.get("name"), str) and renderer["name"] \
        and isinstance(renderer.get("version"), str) and EXACT_VERSION.match(renderer["version"])
    if not pinned:
        raise ContractError("unpinned-renderer", "a renderer is {name, version} with an exact x.y.z version",
                            check="renderer-pin", reference=origin)
    consumes = renderer.get("consumes", RENDERER_CONSUMES)
    if consumes != RENDERER_CONSUMES:
        raise ContractError("invalid-version", f"the renderer consumes {consumes!r}; validation ends at "
                            f"{RENDERER_CONSUMES}", check="renderer-consumes", reference=origin)


def resolve_config(args):
    layers = [("defaults", DEFAULTS)]
    if args.workspace_preferences and Path(args.workspace_preferences).is_file():
        layers.append(("workspace", read_config(args.workspace_preferences, "workspace")))
    if args.project_config:
        layers.append(("project", read_config(args.project_config, "project")))
    supplied = {}
    for item in args.set_values:
        key, sep, value = item.partition("=")
        if not sep or key not in SETTABLE_KEYS:
            raise UsageError(f"--set takes key=value for one of {', '.join(SETTABLE_KEYS)}")
        supplied[key] = value
    layers.append(("supplied", supplied))
    configuration, origin = {}, {}
    for name, layer in layers:
        for key, value in layer.items():
            if value is not None:
                configuration[key], origin[key] = value, name
    configuration.setdefault("renderer", None)
    origin.setdefault("renderer", "defaults")
    check_renderer_pin(configuration["renderer"], origin["renderer"])
    return {"configuration": configuration, "origin": origin,
            "precedence": ["supplied", "project", "workspace", "defaults"]}


def build_parser():
    top = Parser(prog="validate-publishing.py", description=__doc__.splitlines()[0])
    commands = top.add_subparsers(dest="command", required=True)
    normalize = commands.add_parser("normalize", help="normalize a narrative or direct brief")
    normalize.add_argument("--kind", choices=("narrative", "direct"), required=True)
    normalize.add_argument("--input", required=True)
    validate = commands.add_parser("validate", help="validate a normalized/composition/plan artifact chain")
    validate.add_argument("--input", required=True)
    config = commands.add_parser("resolve-config", help="resolve configuration precedence")
    config.add_argument("--project-config")
    config.add_argument("--workspace-preferences")
    config.add_argument("--set", dest="set_values", action="append", default=[])
    return top


def main(argv=None):
    try:
        args = build_parser().parse_args(argv)
        if args.command == "normalize":
            data = normalize_narrative(args.input) if args.kind == "narrative" else normalize_direct(args.input)
        elif args.command == "validate":
            data = validate_chain(read_json(args.input))
        else:
            data = resolve_config(args)
    except ContractError as exc:
        print(json.dumps(envelope(False, exc.finding, str(exc)), ensure_ascii=False))
        return 1
    except UsageError as exc:
        print(json.dumps(envelope(False, {"code": "usage-error"}, str(exc)), ensure_ascii=False))
        return 2
    except Exception as exc:  # a runtime fault still answers with one envelope, never a traceback
        print(json.dumps(envelope(False, {"code": "runtime-error"}, str(exc)), ensure_ascii=False))
        return 2
    print(json.dumps(envelope(True, data, None), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
