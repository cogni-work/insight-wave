#!/usr/bin/env python3
"""Validate cogni-projects entity markdown files against the data model.

Checks the YAML frontmatter of consultant / project / assignment entity files
(see references/data-model.md) for schema conformance: required keys, valid
enum values, kebab-case slug shape, ISO dates, and numeric ranges.

Stdlib-only (no PyYAML): a small frontmatter-subset parser handles the flat
scalar + simple-list frontmatter the data model uses.

Usage:
  python3 validate-entities.py <path> [<path> ...]

Each <path> is either a single entity .md file or a portfolio directory
(cogni-projects/<portfolio-slug>/); a directory is expanded to every .md file
under its consultants/ projects/ assignments/ subdirectories.

Output: a single JSON line following the repo contract
  {"success": bool, "data": {"errors": [...], "warnings": [...]}, "error": str}
`success` is false when any error is found (or on a hard failure, with `error`
set). Each error/warning is {"entity", "file", "field", "message"}.
"""

import datetime
import json
import os
import re
import sys

# Frontmatter block: leading --- ... --- fence at the top of the file.
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

# kebab-case: lowercase alphanumerics in hyphen-separated segments.
KEBAB_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
# Composite assignment slug: <consultant-slug>--<project-slug>.
COMPOSITE_SLUG_RE = re.compile(
    r"^[a-z0-9]+(?:-[a-z0-9]+)*--[a-z0-9]+(?:-[a-z0-9]+)*$"
)
ISO_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _is_iso_date(value):
    """True when value is a real ISO calendar date (shape AND validity)."""
    if not (isinstance(value, str) and ISO_DATE_RE.match(value)):
        return False
    try:
        datetime.date.fromisoformat(value)
        return True
    except ValueError:
        return False

# Per-type schema. `required` / `optional` list frontmatter keys; `enums` maps a
# key to its allowed values; `ints` maps a key to an inclusive (lo, hi) range;
# `dates` lists ISO-date keys; `lists` are keys that must parse as a list.
SCHEMA = {
    "consultant": {
        "subdir": "consultants",
        "required": ["type", "slug", "name", "seniority", "skills"],
        "optional": [
            "grade", "location", "available_from", "available_until",
            "allocation_pct", "updated",
        ],
        "enums": {
            "seniority": ["junior", "consultant", "senior", "principal", "partner"],
        },
        "ints": {"allocation_pct": (0, 100)},
        "dates": ["available_from", "available_until", "updated"],
        "lists": ["skills"],
        "slug_kind": "simple",
    },
    "project": {
        "subdir": "projects",
        "required": ["type", "slug", "name", "client", "strategic_impact"],
        "optional": ["open_roles", "start_date", "end_date", "status", "updated"],
        "enums": {
            "status": ["prospective", "active", "closed"],
        },
        "ints": {"strategic_impact": (1, 5)},
        "dates": ["start_date", "end_date", "updated"],
        "lists": ["open_roles"],
        "slug_kind": "simple",
    },
    "assignment": {
        "subdir": "assignments",
        "required": [
            "type", "slug", "consultant", "project", "role",
            "start_date", "end_date",
        ],
        "optional": ["allocation_pct", "status", "updated"],
        "enums": {
            "status": ["planned", "active", "completed"],
        },
        "ints": {"allocation_pct": (0, 100)},
        "dates": ["start_date", "end_date", "updated"],
        "lists": [],
        "slug_kind": "composite",
    },
}

# Map an entity subdirectory name to its type, so a file's location can be used
# to infer the expected `type` when the frontmatter is missing or mismatched.
SUBDIR_TO_TYPE = {spec["subdir"]: etype for etype, spec in SCHEMA.items()}


def _strip_scalar(raw):
    """Strip surrounding quotes from a scalar frontmatter value."""
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in ("'", '"'):
        return raw[1:-1]
    return raw


def _coerce(value):
    """Coerce a scalar string to int when it looks like one; else leave it."""
    if isinstance(value, str) and re.fullmatch(r"-?\d+", value):
        return int(value)
    return value


def parse_frontmatter(text):
    """Parse the flat scalar + simple-list frontmatter subset the data model uses.

    Supports `key: scalar`, `key: [a, b]` inline lists, and block lists:
        key:
          - a
          - b
    Returns a dict, or None when no frontmatter fence is present.
    """
    match = FRONTMATTER_RE.match(text)
    if not match:
        return None
    body = match.group(1)
    data = {}
    lines = body.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        # Block-list continuation lines are consumed by their parent key below.
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not m:
            i += 1
            continue
        key, rest = m.group(1), m.group(2).strip()
        if rest == "":
            # Possible block list: gather following `  - item` lines.
            items = []
            j = i + 1
            while j < len(lines) and re.match(r"^\s+-\s+", lines[j]):
                items.append(_coerce(_strip_scalar(re.sub(r"^\s+-\s+", "", lines[j]))))
                j += 1
            if items:
                data[key] = items
                i = j
                continue
            data[key] = ""
            i += 1
            continue
        if rest.startswith("[") and rest.endswith("]"):
            inner = rest[1:-1].strip()
            items = [
                _coerce(_strip_scalar(p))
                for p in _split_inline_list(inner)
            ] if inner else []
            data[key] = items
        else:
            data[key] = _coerce(_strip_scalar(rest))
        i += 1
    return data


def _split_inline_list(inner):
    """Split an inline list body on commas, respecting quoted segments."""
    parts, buf, quote = [], [], None
    for ch in inner:
        if quote:
            buf.append(ch)
            if ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
            buf.append(ch)
        elif ch == ",":
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append("".join(buf))
    return [p.strip() for p in parts if p.strip() != ""]


def _entity_files(path):
    """Expand a path to the entity .md files it covers.

    A file path yields itself. A directory yields every .md file under its
    consultants/ projects/ assignments/ subdirectories.
    """
    if os.path.isfile(path):
        return [path]
    files = []
    for subdir in SUBDIR_TO_TYPE:
        d = os.path.join(path, subdir)
        if os.path.isdir(d):
            for name in sorted(os.listdir(d)):
                if name.endswith(".md"):
                    files.append(os.path.join(d, name))
    return files


def validate_file(filepath):
    """Validate one entity file. Returns (errors, warnings) as lists of dicts."""
    errors, warnings = [], []
    rel = filepath

    def err(field, message, entity="unknown"):
        errors.append(
            {"entity": entity, "file": rel, "field": field, "message": message}
        )

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()
    except OSError as exc:
        err("<file>", "cannot read file: %s" % exc)
        return errors, warnings

    fm = parse_frontmatter(text)
    if fm is None:
        err("<frontmatter>", "no YAML frontmatter block found (expected leading --- ... --- fence)")
        return errors, warnings

    # Infer the expected type from the file's subdirectory.
    parent = os.path.basename(os.path.dirname(filepath))
    inferred = SUBDIR_TO_TYPE.get(parent)
    declared = fm.get("type")

    entity_type = declared if declared in SCHEMA else inferred
    if entity_type not in SCHEMA:
        err("type", "unknown or missing entity type %r (expected one of %s)"
            % (declared, ", ".join(sorted(SCHEMA))),
            entity=str(declared))
        return errors, warnings
    if inferred and declared and declared != inferred:
        err("type", "type %r does not match its %s/ directory (expected %r)"
            % (declared, parent, inferred), entity=entity_type)

    spec = SCHEMA[entity_type]

    # Required keys present and non-empty.
    for key in spec["required"]:
        if key not in fm or fm[key] in ("", [], None):
            err(key, "missing required field", entity=entity_type)

    # Unknown keys are a warning, not an error (forward-compatible frontmatter).
    known = set(spec["required"]) | set(spec["optional"])
    for key in fm:
        if key not in known:
            warnings.append({
                "entity": entity_type, "file": rel, "field": key,
                "message": "unknown field (ignored)",
            })

    # Slug shape.
    slug = fm.get("slug")
    if isinstance(slug, str) and slug:
        if spec["slug_kind"] == "composite":
            if not COMPOSITE_SLUG_RE.match(slug):
                err("slug", "assignment slug must be composite kebab-case "
                    "<consultant>--<project> (got %r)" % slug, entity=entity_type)
        elif not KEBAB_RE.match(slug):
            err("slug", "slug must be kebab-case (got %r)" % slug, entity=entity_type)

    # Enum values.
    for key, allowed in spec["enums"].items():
        if key in fm and fm[key] not in ("", None):
            if fm[key] not in allowed:
                err(key, "invalid value %r (allowed: %s)"
                    % (fm[key], ", ".join(allowed)), entity=entity_type)

    # Integer ranges.
    for key, (lo, hi) in spec["ints"].items():
        if key in fm and fm[key] not in ("", None):
            val = fm[key]
            if not isinstance(val, int):
                err(key, "must be an integer (got %r)" % val, entity=entity_type)
            elif not (lo <= val <= hi):
                err(key, "out of range %d..%d (got %d)" % (lo, hi, val),
                    entity=entity_type)

    # ISO dates.
    for key in spec["dates"]:
        if key in fm and fm[key] not in ("", None):
            if not _is_iso_date(fm[key]):
                err(key, "must be a valid ISO date YYYY-MM-DD (got %r)" % fm[key],
                    entity=entity_type)

    # List-typed fields.
    for key in spec["lists"]:
        if key in fm and fm[key] not in ("", None) and not isinstance(fm[key], list):
            err(key, "must be a list (got %r)" % type(fm[key]).__name__,
                entity=entity_type)

    return errors, warnings


def main(argv):
    if not argv:
        print(json.dumps({
            "success": False, "data": {"errors": [], "warnings": []},
            "error": "usage: validate-entities.py <path> [<path> ...]",
        }))
        return 2

    all_files = []
    for path in argv:
        if not os.path.exists(path):
            print(json.dumps({
                "success": False, "data": {"errors": [], "warnings": []},
                "error": "path not found: %s" % path,
            }))
            return 2
        all_files.extend(_entity_files(path))

    errors, warnings = [], []
    for f in all_files:
        e, w = validate_file(f)
        errors.extend(e)
        warnings.extend(w)

    success = len(errors) == 0
    print(json.dumps({
        "success": success,
        "data": {
            "errors": errors,
            "warnings": warnings,
            "checked": len(all_files),
        },
        "error": "" if success else "%d validation error(s)" % len(errors),
    }))
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
