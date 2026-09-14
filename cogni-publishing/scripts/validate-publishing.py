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

The composition commands (check-patterns, compose, check-composition,
check-repair) bind a normalized brief to the pattern library into a
semantic-composition@2; they read the bundled library beside this script, or an
explicit --patterns file, and nothing else.
"""

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path

SUPPORTED = {
    "direct-brief": {"1"},
    "design-brief": {"1.1"},
    "normalized-brief": {"1"},
    "semantic-composition": {"1", "2"},
    "target-resolved-plan": {"1"},
    "pattern-library": {"1"},
}
# The upstream artifact versions each downstream artifact version accepts.
# A new contract version lands here and in references/artifact-contracts.md together.
COMPATIBLE = {
    ("semantic-composition", "1"): {"normalized-brief": {"1"}},
    ("semantic-composition", "2"): {"normalized-brief": {"1"}, "pattern-library": {"1"}},
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


def order_preserved(positions):
    return positions == sorted(positions)


def provenance_present(source_refs):
    return len(source_refs) > 0


def pattern_accepted(pattern):
    return pattern.get("status") == "accepted"


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
    plan_version = artifacts["target_resolved_plan"]["artifact_version"]
    composition_version = artifacts["semantic_composition"]["artifact_version"]
    if not version_supported(composition_version,
                             COMPATIBLE[("target-resolved-plan", plan_version)]["semantic-composition"]):
        raise ContractError("invalid-version", f"target-resolved-plan@{plan_version} does not consume "
                            f"semantic-composition@{composition_version}", check="version-compatibility",
                            artifact="target_resolved_plan", reference=f"semantic-composition@{composition_version}")
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
        if "role" in unit and not (isinstance(unit["role"], str) and ROLE_TOKEN.fullmatch(unit["role"])):
            raise ContractError("unexpected-field", f"{owner} role must be a short kebab-case token, never copy",
                                check="role", artifact="semantic_composition", reference=owner)
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


# --- pattern-bound composition: pattern-library@1 + semantic-composition@2 ----------------------
#
# Patterns are library data; families are code. A pattern names one of four families and the
# validator owns what each family means, so adding a pattern is a library entry and adding a
# family is a reviewed change here. references/design-composition.md is the normative prose.

DEFAULT_LIBRARY = Path(__file__).absolute().parent.parent / "references" / "pattern-library-v1.json"
PATTERN_FIELDS = ("status", "family", "purpose", "eligibility", "slots", "constraints", "evidence_needs",
                  "accessibility", "target_capabilities", "variants", "examples")
PATTERN_STATUSES = {"accepted", "proposed"}
FAMILIES = {"text", "chart", "system", "register"}
CONTENT_KINDS = {"headline", "body", "points", "notes", "evidence", "data"}
ACCESSIBILITY_ROLES = {"statement", "list", "table", "figure", "register"}
TEXT_ALTERNATIVES = {"chart": "data-table", "system": "entity-list"}
EVIDENCE_NEEDS = {"citations": {"carry-all"}, "evidence_status": {"carry-when-present"},
                  "dataset": {"none", "required"}, "provenance": {"none", "every-point-sourced"}}
LIMIT_KEYS = ("min_items", "max_items", "max_chars")
# The bindable content of a normalized record, in authored order. type, element and visual_intent
# are presentation hints and never bindable content.
FIELD_KINDS = {
    "slide": (("headline", "headline"), ("slide_points", "points"), ("talk_track", "notes"),
              ("evidence_status", "evidence")),
    "section": (("title", "headline"), ("body", "body"), ("notes", "notes")),
}
FINGERPRINT_KEYS = ("document", "structure", "records", "data", "sources", "freeze")
COMPOSITION_V2_KEYS = {"artifact_type", "artifact_version", "artifact_id", "normalized_brief_ref",
                       "pattern_library_ref", "design_system", "targets", "document_bindings", "units"}
UNIT_V2_KEYS = {"id", "role", "pattern", "variant", "bindings", "data_bindings", "source_refs", "register_refs",
                "entities", "relationships", "type_floor"}
BINDING_KEYS = {"slot", "record_ref", "field", "digest"}
DATA_BINDING_KEYS = {"slot", "data_ref"}
ENTITY_KEYS = {"id", "record_ref", "field", "item"}
RELATIONSHIP_KEYS = {"from", "to", "kind"}
DOCUMENT_BINDING_KEYS = {"field", "index", "digest"}
# A chart point or a relationship that carries one of these carries a number, unit or label of its own.
MEASUREMENT_KEYS = {"value", "values", "amount", "measure", "measurement", "number", "weight", "quantity",
                    "unit", "label", "percent"}
FAMILY_STRUCTURE = {"data_bindings": "chart", "entities": "system", "relationships": "system",
                    "register_refs": "register"}
GEOMETRY_KEYS = {"x", "y", "left", "top", "right", "bottom", "width", "height", "size", "position",
                 "coordinates", "bounds", "bbox", "grid", "column", "columns", "row", "rows", "span", "layout",
                 "margin", "padding", "offset", "z_index", "font_size", "px", "pt", "emu", "slide_number", "page"}
GEOMETRY_VALUE = re.compile(r"^-?[0-9]+(?:\.[0-9]+)?(?:px|pt|pc|em|rem|emu|in|cm|mm|%|vw|vh)$")
# A unit role names what the unit does, never what it says: a short kebab-case token, not copy.
ROLE_TOKEN = re.compile(r"[a-z][a-z0-9-]{0,63}")
DESIGN_SYSTEM_KEYS = {"name", "version"}


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def digest_of(value):
    return "sha256:" + hashlib.sha256(canonical(value).encode("utf-8")).hexdigest()


def content_fingerprint(brief):
    return digest_of({key: brief.get(key) for key in FINGERPRINT_KEYS})


def record_field(record, key):
    fields = record.get("fields")
    return next((field.get("value") for field in fields if isinstance(field, dict) and field.get("key") == key),
                None) if isinstance(fields, list) else None


def content_fields(record):
    """The record's bindable fields as (field, kind, value), in authored order."""
    found = []
    for field, kind in FIELD_KINDS.get(record.get("kind"), ()):
        if record.get("kind") == "slide" and field != "headline":
            value = record_field(record, field)
        else:
            value = record.get(field)
        if value is not None:
            found.append((field, kind, value))
    return found


def is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def is_index(value):
    return isinstance(value, int) and not isinstance(value, bool)


def string_list(value, allow_empty=False):
    return isinstance(value, list) and (allow_empty or bool(value)) \
        and all(isinstance(item, str) and item for item in value) and len(set(value)) == len(value)


def finding(code, message, check, reference=None, artifact="semantic_composition"):
    return ContractError(code, message, check=check, artifact=artifact, reference=reference)


def check_source_list(entry, check):
    """A record's or data item's source_refs, when present, is a list of non-empty source ids."""
    refs = entry.get("source_refs", [])
    if not isinstance(refs, list) or not all(isinstance(ref, str) and ref for ref in refs):
        raise finding("invalid-artifact", f"{check} {entry['id']} source_refs must be a list of source ids", check,
                      entry["id"], artifact="normalized_brief")


def check_brief(brief):
    """The normalized brief a composition binds, checked just enough to index it safely."""
    if not isinstance(brief, dict):
        raise finding("invalid-artifact", "the brief must be a normalized-brief object", "brief",
                      artifact="normalized_brief")
    if {"success", "data", "error"} <= set(brief):
        raise finding("invalid-artifact", "pass the normalized-brief artifact itself — the envelope's data — "
                      "not the envelope", "brief", artifact="normalized_brief")
    if brief.get("artifact_type") != "normalized-brief":
        raise finding("invalid-artifact", "the brief must be a normalized-brief", "artifact-type",
                      artifact="normalized_brief")
    require_version(brief, "normalized_brief")
    if not isinstance(brief.get("artifact_id"), str) or not brief["artifact_id"]:
        raise finding("invalid-artifact", "normalized_brief needs an artifact_id", "artifact-id",
                      artifact="normalized_brief")
    record_ids = collect_ids(brief.get("records"), "normalized_brief", "records")
    for record in brief["records"]:
        kind = record.get("kind")
        if not is_index(record.get("order")) or not isinstance(kind, str) or kind not in FIELD_KINDS:
            raise finding("invalid-artifact", f"record {record['id']} needs an integer order and a known kind",
                          "records", record["id"], artifact="normalized_brief")
        check_source_list(record, "records")
    collect_ids(brief.get("data", []), "normalized_brief", "data")
    for item in brief.get("data", []):
        check_refs([item.get("record_ref")], record_ids, "normalized_brief", f"data {item['id']}", "record_ref")
        check_source_list(item, "data")
    collect_ids(brief.get("sources", []), "normalized_brief", "sources")
    freeze = brief.get("freeze")
    notes = freeze.get("trailer_notes", []) if isinstance(freeze, dict) else []
    if not isinstance(notes, list) or not all(isinstance(note, str) for note in notes):
        raise finding("invalid-artifact", "freeze.trailer_notes must be a list of strings", "freeze",
                      artifact="normalized_brief")


class BriefIndex:
    def __init__(self, brief):
        self.records = {record["id"]: record for record in brief["records"]}
        self.order = {record["id"]: record["order"] for record in brief["records"]}
        self.fields = {record["id"]: content_fields(record) for record in brief["records"]}
        self.data = {item["id"]: item for item in brief.get("data", [])}
        self.data_index = {item["id"]: index for index, item in enumerate(brief.get("data", []))}
        self.source_ids = [source["id"] for source in brief.get("sources", [])]
        freeze = brief.get("freeze")
        self.trailer = list(freeze.get("trailer_notes", [])) if isinstance(freeze, dict) else []

    def field(self, record_ref, field):
        """(kind, value, position) of a bindable field, or None."""
        if not isinstance(record_ref, str):
            return None
        for position, (name, kind, value) in enumerate(self.fields.get(record_ref, ())):
            if name == field:
                return kind, value, position
        return None


def derived_citations(unit, index):
    """First-seen citations of the unit's bound records, then of its bound data items."""
    refs = []
    for binding in unit.get("bindings") if isinstance(unit.get("bindings"), list) else []:
        ref = binding.get("record_ref") if isinstance(binding, dict) else None
        record = index.records.get(ref) if isinstance(ref, str) else None
        for source_id in (record or {}).get("source_refs", []):
            if source_id not in refs:
                refs.append(source_id)
    for point in unit.get("data_bindings") if isinstance(unit.get("data_bindings"), list) else []:
        ref = point.get("data_ref") if isinstance(point, dict) else None
        item = index.data.get(ref) if isinstance(ref, str) else None
        for source_id in (item or {}).get("source_refs", []):
            if source_id not in refs:
                refs.append(source_id)
    return refs


def fill_composition(brief, composition, patterns):
    """Fill only the mechanical fields a draft leaves out: the content fingerprint, binding digests,
    derived citations, the register and trailer-note bindings. A value already present is left for
    validation to judge. Never picks, splits, merges, truncates or reorders anything."""
    if not isinstance(composition, dict):
        return composition
    index = BriefIndex(brief)
    ref = composition.get("normalized_brief_ref")
    if isinstance(ref, dict) and "content_fingerprint" not in ref:
        ref["content_fingerprint"] = content_fingerprint(brief)
    units = composition.get("units")
    for unit in units if isinstance(units, list) else []:
        if not isinstance(unit, dict):
            continue
        for binding in unit.get("bindings") if isinstance(unit.get("bindings"), list) else []:
            if isinstance(binding, dict) and "digest" not in binding:
                found = index.field(binding.get("record_ref"), binding.get("field"))
                if found is not None:
                    binding["digest"] = digest_of(found[1])
        if "source_refs" not in unit:
            unit["source_refs"] = derived_citations(unit, index)
        name = unit.get("pattern")
        pattern = patterns.get(name) if isinstance(name, str) else None
        if pattern is not None and pattern.get("family") == "register" and "register_refs" not in unit:
            unit["register_refs"] = list(index.source_ids)
    if "document_bindings" not in composition:
        composition["document_bindings"] = [{"field": "trailer_notes", "index": position, "digest": digest_of(note)}
                                            for position, note in enumerate(index.trailer)]
    return composition


# --- pattern library ----------------------------------------------------------------------------

def pattern_error(message, check, reference):
    return ContractError("invalid-pattern", message, check=check, artifact="pattern_library", reference=reference)


def check_limits(limits, owner, pid, check):
    for key in LIMIT_KEYS:
        if key in limits and (not is_index(limits[key]) or limits[key] < 0):
            raise pattern_error(f"{owner}.{key} must be a non-negative integer", check, pid)
    if "min_items" in limits and "max_items" in limits and limits["min_items"] > limits["max_items"]:
        raise pattern_error(f"{owner} has min_items above max_items", check, pid)


def check_pattern_contract(pattern, library):
    """Pass 1: every contract field is present, and each holds a value its family admits."""
    pid = pattern["id"]
    for field in PATTERN_FIELDS:
        value = pattern.get(field)
        empty_allowed = field == "examples" and pattern.get("status") == "proposed" and value == []
        if value is None or (value in ("", {}, []) and not empty_allowed):
            raise pattern_error(f"pattern {pid} is missing its {field} contract field", field, pid)
    if pattern["status"] not in PATTERN_STATUSES:
        raise pattern_error(f"pattern {pid} status must be accepted or proposed", "status", pid)
    family = pattern["family"]
    if family not in FAMILIES:
        raise pattern_error(f"pattern {pid} family must be one of {sorted(FAMILIES)}", "family", pid)
    if not isinstance(pattern["purpose"], str) or not pattern["purpose"].strip():
        raise pattern_error(f"pattern {pid} states why it exists in purpose", "purpose", pid)

    eligibility = pattern["eligibility"]
    if not isinstance(eligibility, dict) or not isinstance(eligibility.get("when"), str) \
            or not eligibility["when"].strip() or not string_list(eligibility.get("record_kinds")) \
            or not set(eligibility["record_kinds"]) <= set(FIELD_KINDS) \
            or not string_list(eligibility.get("slide_types"), allow_empty=True) \
            or not set(eligibility["slide_types"]) <= SLIDE_TYPES \
            or eligibility.get("data") not in ("required", "forbidden") \
            or (eligibility["data"] == "required") != (family == "chart"):
        raise pattern_error(f"pattern {pid} eligibility needs when, record_kinds, slide_types and a data rule "
                            "that matches its family", "eligibility", pid)

    slots = pattern["slots"]
    if not isinstance(slots, list) or not all(isinstance(slot, dict) for slot in slots):
        raise pattern_error(f"pattern {pid} slots must be a list of objects", "slots", pid)
    slot_ids = collect_ids(slots, "pattern_library", "slots", code="invalid-pattern")
    for slot in slots:
        owner = f"{pid}.{slot['id']}"
        accepts = slot.get("accepts")
        if not string_list(accepts) or not set(accepts) <= CONTENT_KINDS \
                or not isinstance(slot.get("required", False), bool):
            raise pattern_error(f"slot {owner} needs accepts from {sorted(CONTENT_KINDS)} and a boolean required",
                                "slots", pid)
        check_limits(slot, owner, pid, "slots")
        if "notes" in accepts and any(key in slot for key in LIMIT_KEYS):
            raise pattern_error(f"slot {owner} limits notes; notes are never limited or truncated", "slots", pid)
    accepted_kinds = [set(slot["accepts"]) for slot in slots]
    if not any("notes" in kinds for kinds in accepted_kinds) or not any("evidence" in kinds for kinds in accepted_kinds):
        raise pattern_error(f"pattern {pid} needs a slot for notes and a slot for evidence status", "slots", pid)
    if any("data" in kinds for kinds in accepted_kinds) != (family == "chart"):
        raise pattern_error(f"pattern {pid}: only the chart family takes data, and it must", "slots", pid)
    if family == "system" and "entities" not in slot_ids:
        raise pattern_error(f"pattern {pid}: the system family needs an entities slot", "slots", pid)

    scale = library["type_scale"]
    constraints = pattern["constraints"]
    if not isinstance(constraints, dict) or constraints.get("min_type_role") not in scale \
            or not is_index(constraints.get("min_records")) or not is_index(constraints.get("max_records")) \
            or not 0 <= constraints["min_records"] <= constraints["max_records"]:
        raise pattern_error(f"pattern {pid} constraints need min_type_role from type_scale and "
                            "min_records <= max_records", "constraints", pid)

    needs = pattern["evidence_needs"]
    if not isinstance(needs, dict) or any(needs.get(key) not in values for key, values in EVIDENCE_NEEDS.items()) \
            or (needs["dataset"] == "required") != (family == "chart") \
            or (needs["provenance"] == "every-point-sourced") != (family == "chart"):
        raise pattern_error(f"pattern {pid} evidence_needs must carry every citation, carry evidence status "
                            "and require a sourced dataset exactly when it charts", "evidence_needs", pid)

    access = pattern["accessibility"]
    if not isinstance(access, dict) or access.get("role") not in ACCESSIBILITY_ROLES \
            or not string_list(access.get("reading_order")) or sorted(access["reading_order"]) != sorted(slot_ids) \
            or access.get("text_alternative") != TEXT_ALTERNATIVES.get(family, "copy"):
        raise pattern_error(f"pattern {pid} accessibility needs a role, a reading order over every slot and "
                            "the text alternative its family requires", "accessibility", pid)

    capabilities = pattern["target_capabilities"]
    if not isinstance(capabilities, dict):
        raise pattern_error(f"pattern {pid} target_capabilities maps targets to capabilities",
                            "target_capabilities", pid)
    for target, needed in capabilities.items():
        known = library["targets"].get(target)
        if known is None or not string_list(needed) or not set(needed) <= set(known["capabilities"]):
            raise pattern_error(f"pattern {pid} declares capabilities target {target} does not offer",
                                "target_capabilities", f"{pid}@{target}")

    variants = pattern["variants"]
    if not isinstance(variants, list) or not all(isinstance(variant, dict) for variant in variants):
        raise pattern_error(f"pattern {pid} variants must be a list of objects", "variants", pid)
    collect_ids(variants, "pattern_library", "variants", code="invalid-pattern")
    for variant in variants:
        owner = f"{pid}/{variant['id']}"
        if not isinstance(variant.get("purpose"), str) or not variant["purpose"].strip():
            raise pattern_error(f"variant {owner} states its purpose", "variants", pid)
        limits = variant.get("limits", {})
        if not isinstance(limits, dict) or not set(limits) <= slot_ids \
                or not all(isinstance(value, dict) and set(value) <= set(LIMIT_KEYS) for value in limits.values()):
            raise pattern_error(f"variant {owner} limits may only name its pattern's slots", "variants", pid)
        for slot_id, value in limits.items():
            check_limits(value, f"{owner}.{slot_id}", pid, "variants")
        floor = variant.get("min_type_role", constraints["min_type_role"])
        if floor not in scale or scale.index(floor) < scale.index(constraints["min_type_role"]):
            raise pattern_error(f"variant {owner} may raise the type floor, never lower it", "variants", pid)
        if family == "system":
            if not string_list(variant.get("relationships")) \
                    or not set(variant["relationships"]) <= set(library["relationship_kinds"]):
                raise pattern_error(f"variant {owner} names the relationship kinds it draws", "variants", pid)
        elif "relationships" in variant:
            raise pattern_error(f"variant {owner}: only the system family draws relationships", "variants", pid)

    examples = pattern["examples"]
    if not isinstance(examples, list) or not all(isinstance(example, dict) for example in examples):
        raise pattern_error(f"pattern {pid} examples must be a list of specimens", "examples", pid)
    collect_ids(examples, "pattern_library", "examples", code="invalid-pattern")
    for example in examples:
        unit = example.get("unit")
        if not isinstance(example.get("brief"), dict) or not isinstance(unit, dict) or unit.get("pattern") != pid:
            raise pattern_error(f"specimen {example['id']} needs a brief and a unit using {pid}", "examples",
                                f"{pid}/{example['id']}")


def specimen_artifacts(pattern, example, library, patterns):
    """A specimen is a minimal normalized brief plus one unit, composed and validated as production."""
    source = example["brief"]
    artifact_id = f"specimen:{example['id']}"
    brief = {
        "artifact_type": "normalized-brief",
        "artifact_version": "1",
        "artifact_id": artifact_id,
        "input_kind": source.get("input_kind"),
        "document": source.get("document", {}),
        "records": copy.deepcopy(source.get("records")),
        "data": copy.deepcopy(source.get("data", [])),
        "sources": copy.deepcopy(source.get("sources", [])),
        "freeze": {"copy": True, "notes": True, "order": True, "trailer_notes": list(source.get("trailer_notes", []))},
        "provenance": {"input_artifact_type": "specimen", "input_artifact_version": "1",
                       "input_artifact_id": example["id"]},
    }
    composition = {
        "artifact_type": "semantic-composition",
        "artifact_version": "2",
        "artifact_id": f"specimen-composition:{example['id']}",
        "normalized_brief_ref": {"artifact_id": artifact_id, "artifact_version": "1"},
        "pattern_library_ref": {"artifact_id": library["artifact_id"], "artifact_version": library["artifact_version"]},
        "design_system": {"name": "specimen", "version": "0"},
        "targets": [target for target in library["targets"] if target in pattern["target_capabilities"]],
        "units": [copy.deepcopy(example["unit"])],
    }
    check_brief(brief)
    return brief, fill_composition(brief, composition, patterns)


def load_library(path):
    """Read and validate a pattern library. Returns (library, readiness of each proposed pattern)."""
    library = read_json(path)
    if not isinstance(library, dict) or library.get("artifact_type") != "pattern-library":
        raise ContractError("invalid-artifact", "the pattern library must be a pattern-library object",
                            check="library", artifact="pattern_library")
    require_version(library, "pattern_library")
    targets = library.get("targets")
    if not isinstance(library.get("artifact_id"), str) or not library["artifact_id"] \
            or not string_list(library.get("type_scale")) or not string_list(library.get("relationship_kinds")) \
            or not isinstance(targets, dict) or not targets \
            or not all(isinstance(target, dict) and string_list(target.get("capabilities"))
                       for target in targets.values()):
        raise ContractError("invalid-artifact", "a pattern library declares artifact_id, type_scale, targets with "
                            "capabilities, and relationship_kinds", check="library", artifact="pattern_library")
    collect_ids(library.get("patterns"), "pattern_library", "patterns", code="invalid-pattern")
    for pattern in library["patterns"]:
        check_pattern_contract(pattern, library)
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    readiness = {}
    for pattern in library["patterns"]:
        blocked = None
        if not pattern["examples"]:
            blocked = {"code": "invalid-pattern", "check": "examples", "reference": pattern["id"]}
        for example in pattern["examples"]:
            try:
                brief, composition = specimen_artifacts(pattern, example, library, patterns)
                validate_composition(brief, composition, library, production=False, require_register=False)
            except ContractError as exc:
                if pattern["status"] == "proposed":
                    blocked = exc.finding
                    break
                raise pattern_error(f"specimen {example['id']} of {pattern['id']} fails its own contract "
                                    f"({exc.finding['code']}: {exc})", "examples",
                                    f"{pattern['id']}/{example['id']}") from exc
        if pattern["status"] == "proposed":
            readiness[pattern["id"]] = {"id": pattern["id"], "ready_for_acceptance": blocked is None,
                                        "blocked_by": blocked}
    return library, readiness


def check_patterns(path):
    library, readiness = load_library(path)
    return {
        "library": {"artifact_id": library["artifact_id"], "artifact_version": library["artifact_version"]},
        "targets": list(library["targets"]),
        "accepted": [pattern["id"] for pattern in library["patterns"] if pattern["status"] == "accepted"],
        "proposed": [readiness[pattern["id"]] for pattern in library["patterns"] if pattern["status"] == "proposed"],
    }


# --- composition validation ---------------------------------------------------------------------

def scan_geometry(node, path):
    if isinstance(node, dict):
        for key, value in node.items():
            here = f"{path}.{key}" if path else key
            if key in GEOMETRY_KEYS:
                raise finding("target-geometry", f"{here} is target geometry; a composition carries semantic "
                              "relationships and leaves layout to the target-resolved plan", "geometry-key", here)
            scan_geometry(value, here)
    elif isinstance(node, list):
        for position, value in enumerate(node):
            scan_geometry(value, f"{path}[{position}]")
    elif isinstance(node, str) and GEOMETRY_VALUE.match(node):
        raise finding("target-geometry", f"{path} holds the dimension {node!r}; a composition carries no target "
                      "geometry", "geometry-value", path)


def slot_count(values):
    return sum(len(value) if isinstance(value, list) else 1 for value in values)


def slot_texts(values):
    for value in values:
        if isinstance(value, list):
            yield from (item for item in value if isinstance(item, str))
        elif isinstance(value, str):
            yield value


class CompositionState:
    def __init__(self):
        self.owner = {}           # record id -> unit id
        self.bound_fields = {}    # (record id, field) -> unit id
        self.bound_data = {}      # data id -> unit id
        self.positions = []       # (record order, record id) over every field binding, in composition order
        self.data_positions = []  # (data index, data id) over every chart point, in composition order
        self.register_units = []
        self.registered_sources = []  # source ids the register unit lists
        self.unit_citations = {}
        self.pattern_counts = {}


def check_unit(unit, index, library, patterns, targets, state, production):
    uid = unit["id"]
    extra = sorted(set(unit) - UNIT_V2_KEYS)
    if extra:
        raise finding("unexpected-field", f"unit {uid} carries {extra}; composition units reference content and "
                      "never carry it", "unit-fields", uid)
    if "role" in unit and not (isinstance(unit["role"], str) and ROLE_TOKEN.fullmatch(unit["role"])):
        raise finding("unexpected-field", f"unit {uid} role must be a short kebab-case token, never copy", "role", uid)
    name = unit.get("pattern")
    pattern = patterns.get(name) if isinstance(name, str) else None
    if pattern is None:
        raise finding("unknown-pattern", f"unit {uid} names pattern {name!r}, which the library does not define",
                      "pattern", str(name))
    pid = pattern["id"]
    if production and not pattern_accepted(pattern):
        raise finding("unaccepted-pattern", f"unit {uid} uses {pid}, which is {pattern['status']}; a pattern is "
                      "usable in production only after it is accepted", "pattern-status", pid)
    variant = next((item for item in pattern["variants"] if item["id"] == unit.get("variant")), None)
    if variant is None:
        raise finding("unknown-pattern", f"unit {uid} names variant {unit.get('variant')!r}, which {pid} does not "
                      "declare", "variant", f"{pid}/{unit.get('variant')}")
    label = f"{uid}:{pid}/{variant['id']}"
    for target in targets:
        if target not in pattern["target_capabilities"]:
            raise finding("unsupported-capability", f"{pid} declares no capabilities for target {target}; choose a "
                          "pattern that supports every requested target", "target-capabilities",
                          f"{uid}:{pid}@{target}")
    for key, family in FAMILY_STRUCTURE.items():
        if key in unit and pattern["family"] != family:
            raise finding("ineligible-pattern", f"unit {uid} carries {key}, which belongs to the {family} family, "
                          f"not {pattern['family']}", "structure", f"{uid}.{key}")
    slots = {slot["id"]: slot for slot in pattern["slots"]}
    slot_values = {slot_id: [] for slot_id in slots}

    bindings = unit.get("bindings")
    if not isinstance(bindings, list):
        raise finding("invalid-artifact", f"unit {uid} needs a bindings list", "bindings", uid)
    unit_records = []
    for binding in bindings:
        if not isinstance(binding, dict):
            raise finding("invalid-artifact", f"every binding of unit {uid} is an object", "bindings", uid)
        extra = sorted(set(binding) - BINDING_KEYS)
        if extra:
            raise finding("unexpected-field", f"a binding of unit {uid} carries {extra}", "binding-fields", uid)
        record_ref, field, slot_id = binding.get("record_ref"), binding.get("field"), binding.get("slot")
        if not isinstance(record_ref, str) or not record_ref:
            raise finding("malformed-reference", f"a binding of unit {uid} has no record_ref", "record_ref", uid)
        if not reference_resolves(record_ref, index.records):
            raise finding("dangling-reference", f"unit {uid} binds {record_ref}, which the brief does not carry",
                          "record_ref", record_ref)
        if state.owner.setdefault(record_ref, uid) != uid:
            raise finding("duplicate-binding", f"record {record_ref} is bound by {state.owner[record_ref]} and "
                          f"again by {uid}; every record belongs to exactly one unit", "record-units", record_ref)
        if record_ref not in unit_records:
            unit_records.append(record_ref)
        key = f"{record_ref}#{field}"
        found = index.field(record_ref, field)
        if found is None:
            raise finding("malformed-reference", f"{key} is not bindable content of {record_ref}", "field", key)
        if (record_ref, field) in state.bound_fields:
            raise finding("duplicate-binding", f"{key} is bound twice; every content field is bound exactly once",
                          "field", key)
        state.bound_fields[(record_ref, field)] = uid
        if not isinstance(slot_id, str) or slot_id not in slots:
            raise finding("ineligible-pattern", f"{pid} has no slot {slot_id!r} for {key}", "slot", key)
        kind, value, _ = found
        if kind not in slots[slot_id]["accepts"]:
            if kind == "notes":
                raise finding("reference-reassigned", f"{key} is a note bound into {slot_id}, which does not carry "
                              "notes", "notes", key)
            if kind == "evidence":
                raise finding("reference-reassigned", f"{key} is an evidence label bound into {slot_id}, which does "
                              "not carry evidence status", "evidence_status", key)
            raise finding("ineligible-pattern", f"slot {pid}.{slot_id} does not accept {kind} content ({key})",
                          "slot-accepts", key)
        if not isinstance(binding.get("digest"), str) or not binding["digest"]:
            raise finding("malformed-reference", f"{key} has no digest; run compose to fill it", "digest", key)
        if binding["digest"] != digest_of(value):
            raise finding("copy-changed", f"{key} no longer matches the digest it was bound with; frozen copy "
                          "changed", "digest", key)
        slot_values[slot_id].append(value)
        state.positions.append((index.order[record_ref], record_ref))

    constraints, eligibility = pattern["constraints"], pattern["eligibility"]
    if not constraints["min_records"] <= len(unit_records) <= constraints["max_records"]:
        raise finding("impossible-fit", f"{label} binds {len(unit_records)} records; {pid} takes "
                      f"{constraints['min_records']}..{constraints['max_records']} — choose another eligible variant or "
                      "pattern; content is never split or merged", "records", label)
    for record_ref in unit_records:
        record = index.records[record_ref]
        if record["kind"] not in eligibility["record_kinds"]:
            raise finding("ineligible-pattern", f"{pid} does not take {record['kind']} records ({record_ref})",
                          "eligibility.record_kinds", label)
        if record["kind"] == "slide" and record_field(record, "type") not in eligibility["slide_types"]:
            raise finding("ineligible-pattern", f"{pid} does not fit a {record_field(record, 'type')} slide "
                          f"({record_ref}); eligible shapes are {eligibility['slide_types']}",
                          "eligibility.slide_types", label)
        if eligibility["data"] == "forbidden" and record.get("data_refs"):
            raise finding("ineligible-pattern", f"{record_ref} carries data, which {pid} cannot show",
                          "eligibility.data", label)
    points = unit.get("data_bindings", [])
    if not isinstance(points, list):
        raise finding("invalid-artifact", f"unit {uid} data_bindings must be a list", "data_bindings", uid)
    if eligibility["data"] == "required" and not points:
        raise finding("absent-dataset", f"{label} charts no supplied dataset; a chart needs data points",
                      "chart-series", uid)

    measure_unit = None
    for point in points:
        if not isinstance(point, dict):
            raise finding("invalid-artifact", f"every data binding of unit {uid} is an object", "data_bindings", uid)
        data_ref = point.get("data_ref")
        measured = sorted(set(point) & MEASUREMENT_KEYS)
        if measured:
            raise finding("invented-value", f"a chart point of {uid} carries its own {measured[0]}; a point references "
                          "a supplied data item and nothing else", "chart-provenance",
                          data_ref if isinstance(data_ref, str) else uid)
        extra = sorted(set(point) - DATA_BINDING_KEYS)
        if extra:
            raise finding("unexpected-field", f"a data binding of unit {uid} carries {extra}", "data-binding-fields",
                          uid)
        slot_id = point.get("slot")
        if not isinstance(slot_id, str) or slot_id not in slots or "data" not in slots[slot_id]["accepts"]:
            raise finding("ineligible-pattern", f"{pid} has no data slot {slot_id!r}", "slot-accepts",
                          f"{uid}:{slot_id}")
        if not isinstance(data_ref, str) or not reference_resolves(data_ref, index.data):
            raise finding("absent-dataset", f"a chart point of {uid} names {data_ref!r}, which no supplied dataset "
                          "carries", "chart-provenance", str(data_ref))
        item = index.data[data_ref]
        if not is_number(item.get("value")) or not isinstance(item.get("unit"), str) or not item["unit"]:
            raise finding("absent-dataset", f"data item {data_ref} supplies no numeric value with a unit",
                          "chart-value", data_ref)
        if data_ref in state.bound_data:
            raise finding("duplicate-binding", f"data item {data_ref} is plotted twice", "data", data_ref)
        state.bound_data[data_ref] = uid
        if item["record_ref"] not in unit_records:
            raise finding("reference-reassigned", f"data item {data_ref} belongs to {item['record_ref']}, which unit "
                          f"{uid} does not bind", "data-record", data_ref)
        sources = item.get("source_refs", [])
        if not isinstance(sources, list):
            raise finding("malformed-reference", f"data item {data_ref} source_refs must be a list", "source_refs",
                          data_ref)
        if not provenance_present(sources):
            raise finding("unsourced-chart-data", f"data item {data_ref} names no source; every plotted value needs "
                          "provenance", "chart-provenance", data_ref)
        for source_id in sources:
            if not reference_resolves(source_id, index.source_ids):
                raise finding("dangling-reference", f"data item {data_ref} cites {source_id}, which the brief does "
                              "not carry", "source_refs", str(source_id))
        if measure_unit is None:
            measure_unit = item["unit"]
        elif item["unit"] != measure_unit:
            raise finding("mismatched-unit", f"data item {data_ref} is in {item['unit']}, but {uid} already plots "
                          f"{measure_unit}; one chart series has one unit", "chart-units", data_ref)
        slot_values[slot_id].append(item)
        state.data_positions.append((index.data_index[data_ref], data_ref))

    if pattern["family"] == "system":
        check_system(unit, variant, index, bindings, label)

    if pattern["family"] == "register":
        state.register_units.append(uid)
        if len(state.register_units) > 1:
            raise finding("duplicate-binding", f"{uid} is a second source register", "register", uid)
        if unit.get("register_refs") != index.source_ids:
            raise finding("source-identity-changed", f"the register of {uid} must list every source once, in its "
                          "original order", "register", uid)
        state.registered_sources = list(unit["register_refs"])

    for slot in pattern["slots"]:
        if slot.get("required") and not slot_values[slot["id"]]:
            raise finding("ineligible-pattern", f"{label} leaves the required slot {slot['id']} empty",
                          "required-slot", f"{uid}:{slot['id']}")

    declared = unit.get("source_refs")
    if declared is None:
        raise finding("reference-omitted", f"unit {uid} carries no source_refs", "citations", uid)
    if not isinstance(declared, list) or not all(isinstance(ref, str) and ref for ref in declared):
        raise finding("malformed-reference", f"unit {uid} source_refs must be a list of source ids", "citations", uid)
    expected = derived_citations(unit, index)
    for ref in declared:
        if not reference_resolves(ref, index.source_ids):
            raise finding("source-identity-changed", f"unit {uid} cites {ref}, which is not a source of the brief",
                          "citations", ref)
    for ref in expected:
        if ref not in declared:
            raise finding("reference-omitted", f"unit {uid} drops the citation {ref} its bound content carries",
                          "citations", f"{uid}:{ref}")
    for ref in declared:
        if ref not in expected:
            raise finding("reference-reassigned", f"unit {uid} cites {ref}, which none of its bound content carries",
                          "citations", f"{uid}:{ref}")
        if declared.count(ref) > 1:
            raise finding("duplicate-binding", f"unit {uid} cites {ref} twice", "citations", f"{uid}:{ref}")
    if declared != expected:
        raise finding("source-identity-changed", f"unit {uid} reorders its citations; expected {expected}",
                      "citation-order", uid)
    state.unit_citations[uid] = set(declared)

    limits = {slot_id: {key: slot[key] for key in LIMIT_KEYS if key in slot} for slot_id, slot in slots.items()}
    for slot_id, override in variant.get("limits", {}).items():
        limits[slot_id].update(override)
    for slot_id in slots:
        values, limit = slot_values[slot_id], limits[slot_id]
        count = slot_count(values)
        advice = "choose another eligible variant or pattern; content is never truncated, split or dropped"
        if "min_items" in limit and count < limit["min_items"]:
            raise finding("impossible-fit", f"{label} places {count} items in {slot_id}, below its minimum of "
                          f"{limit['min_items']} — {advice}", f"{slot_id}.min_items", label)
        if "max_items" in limit and count > limit["max_items"]:
            raise finding("impossible-fit", f"{label} places {count} items in {slot_id}, above its maximum of "
                          f"{limit['max_items']} — {advice}", f"{slot_id}.max_items", label)
        longest = max((len(text) for text in slot_texts(values)), default=0)
        if "max_chars" in limit and longest > limit["max_chars"]:
            raise finding("impossible-fit", f"{label} places a {longest}-character item in {slot_id}, above its "
                          f"limit of {limit['max_chars']} — {advice}", f"{slot_id}.max_chars", label)

    scale = library["type_scale"]
    floor = max(scale.index(constraints["min_type_role"]),
                scale.index(variant.get("min_type_role", constraints["min_type_role"])))
    if "type_floor" in unit and (unit["type_floor"] not in scale or scale.index(unit["type_floor"]) < floor):
        raise finding("typography-relaxed", f"{label} sets type_floor {unit['type_floor']!r} below {scale[floor]}; "
                      "a composition may raise the minimum typography, never lower it", "min_type_role", label)
    state.pattern_counts[pid] = state.pattern_counts.get(pid, 0) + 1


def check_system(unit, variant, index, bindings, label):
    """A conceptual system names every bound item as an entity once, and relates entities semantically."""
    uid = unit["id"]
    entities, relationships = unit.get("entities"), unit.get("relationships")
    if not isinstance(entities, list) or not entities:
        raise finding("ineligible-pattern", f"{label} needs entities over its bound content", "entities", uid)
    entity_ids = collect_ids(entities, "semantic_composition", f"{uid}.entities")
    placed = [(binding["record_ref"], binding["field"]) for binding in bindings if binding["slot"] == "entities"]
    covered, positions = set(), []
    for entity in entities:
        owner = f"{uid}.{entity['id']}"
        if set(entity) & MEASUREMENT_KEYS:
            raise finding("invented-value", f"entity {owner} carries a measurement; a conceptual diagram implies no "
                          "numbers", "system-measurement", uid)
        extra = sorted(set(entity) - ENTITY_KEYS)
        if extra:
            raise finding("unexpected-field", f"entity {owner} carries {extra}", "entity-fields", uid)
        record_ref, field = entity.get("record_ref"), entity.get("field")
        if not isinstance(record_ref, str) or not isinstance(field, str) or (record_ref, field) not in placed:
            raise finding("malformed-reference", f"entity {owner} names content this unit does not place in its "
                          "entities slot", "entities", owner)
        kind, value, position = index.field(record_ref, field)
        if isinstance(value, list):
            item = entity.get("item")
            if not is_index(item) or not 0 <= item < len(value):
                raise finding("malformed-reference", f"entity {owner} needs an item index into {record_ref}#{field}",
                              "entities", owner)
        elif "item" in entity:
            raise finding("malformed-reference", f"entity {owner} indexes a field that is not a list", "entities",
                          owner)
        else:
            item = -1
        if (record_ref, field, item) in covered:
            raise finding("duplicate-binding", f"entity {owner} repeats an item another entity already names",
                          "entities", owner)
        covered.add((record_ref, field, item))
        positions.append((index.order[record_ref], position, item))
    for record_ref, field in placed:
        _, value, _ = index.field(record_ref, field)
        expected = [(record_ref, field, item) for item in range(len(value))] if isinstance(value, list) \
            else [(record_ref, field, -1)]
        for key in expected:
            if key not in covered:
                suffix = f"[{key[2]}]" if key[2] >= 0 else ""
                raise finding("unbound-content", f"{record_ref}#{field}{suffix} is placed in {uid} but named by no "
                              "entity", "entities", f"{record_ref}#{field}{suffix}")
    if not order_preserved(positions):
        raise finding("reordered-unit", f"the entities of {uid} are out of authored order", "entity-order", uid)
    if not isinstance(relationships, list) or not relationships:
        raise finding("ineligible-pattern", f"{label} states no relationship between its entities", "relationships",
                      uid)
    for relationship in relationships:
        if not isinstance(relationship, dict):
            raise finding("invalid-artifact", f"every relationship of {uid} is an object", "relationships", uid)
        if set(relationship) & MEASUREMENT_KEYS:
            raise finding("invented-value", f"a relationship of {uid} carries a measurement; a conceptual diagram "
                          "implies no numbers", "system-measurement", uid)
        extra = sorted(set(relationship) - RELATIONSHIP_KEYS)
        if extra:
            raise finding("unexpected-field", f"a relationship of {uid} carries {extra}", "relationship-fields", uid)
        ends = (relationship.get("from"), relationship.get("to"))
        if not all(isinstance(end, str) and end in entity_ids for end in ends) or ends[0] == ends[1]:
            raise finding("malformed-reference", f"a relationship of {uid} must join two different entities",
                          "relationships", uid)
        if relationship.get("kind") not in variant["relationships"]:
            raise finding("ineligible-pattern", f"{label} draws {variant['relationships']}, not "
                          f"{relationship.get('kind')!r}", "relationships.kind", label)


def check_document_bindings(composition, index):
    entries = composition.get("document_bindings", [])
    if not isinstance(entries, list):
        raise finding("invalid-artifact", "document_bindings must be a list", "document_bindings")
    bound = set()
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != DOCUMENT_BINDING_KEYS:
            raise finding("invalid-artifact", "a document binding is {field, index, digest}", "document_bindings")
        position = entry["index"]
        where = f"trailer_notes[{position}]"
        if entry["field"] != "trailer_notes":
            raise finding("malformed-reference", f"document bindings carry trailer_notes, not {entry['field']!r}",
                          "document_bindings", str(entry["field"]))
        if not is_index(position) or not 0 <= position < len(index.trailer):
            raise finding("dangling-reference", f"{where} does not exist in the brief", "document_bindings", where)
        if position in bound:
            raise finding("duplicate-binding", f"{where} is bound twice", "trailer_notes", where)
        bound.add(position)
        if entry["digest"] != digest_of(index.trailer[position]):
            raise finding("copy-changed", f"{where} no longer matches the digest it was bound with", "digest", where)
    return bound


def first_out_of_order(positions):
    return next(positions[i][1] for i in range(1, len(positions)) if positions[i][0] < positions[i - 1][0])


def validate_composition(brief, composition, library, production=True, require_register=True):
    """Fail fast on the first contract violation; on success report full coverage. A pattern specimen is
    one unit, so load_library validates it with require_register=False: it cannot also carry the register
    a whole document needs."""
    check_brief(brief)
    index = BriefIndex(brief)
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    if not isinstance(composition, dict):
        raise finding("invalid-artifact", "a semantic composition is a JSON object", "composition")
    if composition.get("artifact_type") != "semantic-composition":
        raise finding("invalid-artifact", "the composition must be a semantic-composition", "artifact-type")
    require_version(composition, "semantic_composition")
    if composition["artifact_version"] != "2":
        raise finding("invalid-version", "a pattern-bound composition is semantic-composition@2",
                      "composition-version", f"semantic-composition@{composition['artifact_version']}")
    scan_geometry(composition, "")
    extra = sorted(set(composition) - COMPOSITION_V2_KEYS)
    if extra:
        raise finding("unexpected-field", f"the composition carries {extra}", "composition-fields", extra[0])
    if not isinstance(composition.get("artifact_id"), str) or not composition["artifact_id"]:
        raise finding("invalid-artifact", "the composition needs an artifact_id", "artifact-id")
    check_artifact_ref(composition, "normalized_brief_ref", brief, "semantic_composition")
    check_artifact_ref(composition, "pattern_library_ref", library, "semantic_composition")
    design = composition.get("design_system")
    if not isinstance(design, dict) or not all(isinstance(design.get(key), str) and design[key]
                                               for key in ("name", "version")):
        raise finding("invalid-artifact", "a composition pins design_system {name, version}", "design-system")
    extra = sorted(set(design) - DESIGN_SYSTEM_KEYS)
    if extra:
        raise finding("unexpected-field", f"design_system carries {extra}; it pins a name and a version and nothing "
                      "else", "design-system", extra[0])
    targets = composition.get("targets")
    if not string_list(targets):
        raise finding("invalid-artifact", "targets is a non-empty list of distinct target names", "targets")
    for target in targets:
        if target not in library["targets"]:
            raise finding("unsupported-capability", f"target {target!r} is not one the pattern library supports",
                          "target", target)
    units = composition.get("units")
    collect_ids(units, "semantic_composition", "units")
    if not units:
        raise finding("invalid-artifact", "a composition needs at least one unit", "units")

    state = CompositionState()
    for unit in units:
        check_unit(unit, index, library, patterns, targets, state, production)
    bound_notes = check_document_bindings(composition, index)

    if not order_preserved([order for order, _ in state.positions]):
        culprit = first_out_of_order(state.positions)
        raise finding("reordered-unit", f"{culprit} is bound after content that follows it in the brief; "
                      "units keep the authored order", "record-order", culprit)
    if not order_preserved([position for position, _ in state.data_positions]):
        culprit = first_out_of_order(state.data_positions)
        raise finding("reordered-unit", f"data item {culprit} is plotted out of its authored order", "data-order",
                      culprit)

    records = brief["records"]
    for record in records:
        if record["id"] not in state.owner:
            raise finding("unbound-content", f"record {record['id']} is bound by no unit", "records", record["id"])
    for record in records:
        for field, kind, _ in content_fields(record):
            if (record["id"], field) not in state.bound_fields:
                key = f"{record['id']}#{field}"
                if kind == "notes":
                    raise finding("reference-omitted", f"the note {key} is bound nowhere", "notes", key)
                if kind == "evidence":
                    raise finding("reference-omitted", f"the evidence label {key} is bound nowhere",
                                  "evidence_status", key)
                raise finding("unbound-content", f"{key} is bound nowhere", "fields", key)
    for item in brief.get("data", []):
        if item["id"] not in state.bound_data:
            raise finding("unbound-content", f"data item {item['id']} is bound nowhere", "data", item["id"])
    for position in range(len(index.trailer)):
        if position not in bound_notes:
            raise finding("reference-omitted", f"trailer_notes[{position}] is bound nowhere", "trailer_notes",
                          f"trailer_notes[{position}]")
    if require_register and index.source_ids and not state.register_units:
        raise finding("reference-omitted", "the brief carries sources but no unit registers them; add a sources unit",
                      "register", index.source_ids[0])

    actual = content_fingerprint(brief)
    if composition["normalized_brief_ref"].get("content_fingerprint") != actual:
        raise finding("fingerprint-mismatch", "the composition was bound to different content than the brief "
                      f"now carries ({actual})", "content-fingerprint")

    fields = [(record["id"], kind) for record in records for _, kind, _ in content_fields(record)]
    notes = sum(1 for _, kind in fields if kind == "notes")
    evidence = sum(1 for _, kind in fields if kind == "evidence")
    pairs = [(record["id"], ref, state.owner[record["id"]]) for record in records
             for ref in record.get("source_refs", [])]
    pairs += [(item["id"], ref, state.bound_data[item["id"]]) for item in brief.get("data", [])
              for ref in item.get("source_refs", [])]
    cited = sum(1 for _, ref, owner in pairs if ref in state.unit_citations[owner])
    # Every bound count comes from a recorded binding, never from the expected count it is compared with.
    bound_kinds = [index.field(record_ref, field)[0] for record_ref, field in state.bound_fields]
    coverage = {
        "records": {"expected": len(records), "bound": len(state.owner)},
        "content_fields": {"expected": len(fields), "bound": len(state.bound_fields)},
        "notes": {"expected": notes + len(index.trailer), "bound": bound_kinds.count("notes") + len(bound_notes)},
        "citations": {"expected": len(pairs), "bound": cited},
        "evidence_status": {"expected": evidence, "bound": bound_kinds.count("evidence")},
        "data": {"expected": len(index.data), "bound": len(state.bound_data)},
        "trailer_notes": {"expected": len(index.trailer), "bound": len(bound_notes)},
        "sources": {"expected": len(index.source_ids), "bound": len(state.registered_sources)},
    }
    return {
        "valid": True,
        "artifact_id": composition["artifact_id"],
        "content_fingerprint": actual,
        "units": len(units),
        "patterns": state.pattern_counts,
        "coverage": coverage,
        "omissions": [name for name, row in coverage.items() if row["bound"] != row["expected"]],
    }


def compose(brief, composition, library):
    check_brief(brief)
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    fill_composition(brief, composition, patterns)
    validate_composition(brief, composition, library, production=True)
    return composition


def repair_projection(unit):
    """A unit with the choices a repair may change — pattern, variant and slot names — taken out."""
    projected = {key: value for key, value in unit.items() if key not in ("pattern", "variant")}
    for key in ("bindings", "data_bindings"):
        if isinstance(projected.get(key), list):
            projected[key] = [{k: v for k, v in item.items() if k != "slot"} if isinstance(item, dict) else item
                              for item in projected[key]]
    return projected


def presentation(unit):
    slots = [item.get("slot") for key in ("bindings", "data_bindings")
             for item in (unit.get(key) if isinstance(unit.get(key), list) else []) if isinstance(item, dict)]
    return unit.get("pattern"), unit.get("variant"), slots


def check_repair(brief, before, after, library):
    """A repair changes presentation choices only: the content fingerprint, the units, their order and
    every reference stay exactly as they were."""
    check_brief(brief)
    actual = content_fingerprint(brief)
    for slot, composition in (("repair_before", before), ("repair_after", after)):
        if not isinstance(composition, dict) or composition.get("artifact_type") != "semantic-composition":
            raise finding("invalid-artifact", f"{slot} must be a semantic-composition", "composition", artifact=slot)
        if composition.get("artifact_version") != "2":
            raise finding("invalid-version", f"{slot} must be semantic-composition@2", "composition-version",
                          f"semantic-composition@{composition.get('artifact_version')}", artifact=slot)
        ref = composition.get("normalized_brief_ref")
        declared = ref.get("content_fingerprint") if isinstance(ref, dict) else None
        if declared != actual:
            raise finding("fingerprint-mismatch", f"{slot} was bound to content {declared}, but the brief "
                          f"fingerprints as {actual}; a repair never changes frozen content", "content-fingerprint",
                          artifact=slot)
    for key in sorted(set(before) | set(after)):
        if key != "units" and before.get(key) != after.get(key):
            raise finding("invalid-repair", f"a repair may not change {key}", key, artifact="repair_after")
    before_units, after_units = before.get("units"), after.get("units")
    if not isinstance(before_units, list) or not isinstance(after_units, list) \
            or not all(isinstance(unit, dict) for unit in before_units + after_units):
        raise finding("invalid-artifact", "both compositions need a list of units", "units", artifact="repair_after")
    before_ids = [unit.get("id") for unit in before_units]
    after_ids = [unit.get("id") for unit in after_units]
    if before_ids != after_ids:
        differs = next((i for i in range(min(len(before_ids), len(after_ids))) if before_ids[i] != after_ids[i]),
                       min(len(before_ids), len(after_ids)))
        culprit = before_ids[differs] if differs < len(before_ids) else after_ids[differs]
        raise finding("invalid-repair", "a repair keeps every unit, in its order", "units", str(culprit),
                      artifact="repair_after")
    repaired, unchanged = [], []
    for old, new in zip(before_units, after_units):
        old_view, new_view = repair_projection(old), repair_projection(new)
        for key in sorted(set(old_view) | set(new_view)):
            if old_view.get(key) != new_view.get(key):
                raise finding("invalid-repair", f"unit {old['id']}: a repair may change pattern, variant and slot "
                              f"names only, not {key}", key, str(old["id"]), artifact="repair_after")
        if presentation(old) != presentation(new):
            repaired.append({"unit": old["id"], "before": f"{old.get('pattern')}/{old.get('variant')}",
                             "after": f"{new.get('pattern')}/{new.get('variant')}"})
        else:
            unchanged.append(old["id"])
    validate_composition(brief, after, library, production=True)
    return {"valid": True, "content_fingerprint": actual, "repaired_units": repaired, "unchanged_units": unchanged}


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
    patterns = commands.add_parser("check-patterns", help="validate the pattern library and report pattern status")
    patterns.add_argument("--patterns", default=str(DEFAULT_LIBRARY))
    composing = commands.add_parser("compose", help="fill a composition draft's mechanical fields and validate it")
    checking = commands.add_parser("check-composition", help="validate a semantic-composition@2 against its brief")
    for command in (composing, checking):
        command.add_argument("--brief", required=True)
        command.add_argument("--composition", required=True)
        command.add_argument("--patterns", default=str(DEFAULT_LIBRARY))
    repair = commands.add_parser("check-repair", help="prove a repair changed presentation choices only")
    repair.add_argument("--brief", required=True)
    repair.add_argument("--before", required=True)
    repair.add_argument("--after", required=True)
    repair.add_argument("--patterns", default=str(DEFAULT_LIBRARY))
    return top


def main(argv=None):
    try:
        args = build_parser().parse_args(argv)
        if args.command == "normalize":
            data = normalize_narrative(args.input) if args.kind == "narrative" else normalize_direct(args.input)
        elif args.command == "validate":
            data = validate_chain(read_json(args.input))
        elif args.command == "check-patterns":
            data = check_patterns(args.patterns)
        elif args.command in ("compose", "check-composition"):
            library, _ = load_library(args.patterns)
            brief, composition = read_json(args.brief), read_json(args.composition)
            if args.command == "compose":
                data = compose(brief, composition, library)
            else:
                data = validate_composition(brief, composition, library)
        elif args.command == "check-repair":
            library, _ = load_library(args.patterns)
            data = check_repair(read_json(args.brief), read_json(args.before), read_json(args.after), library)
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
