#!/usr/bin/env python3
"""Register a cogni-projects entity file into its portfolio manifest.

Upserts the entity's summary ref into the matching projects-portfolio.json array
(keyed on `slug`), bumps the manifest `updated` date, and appends a transition to
.metadata/execution-log.json.

Idempotent: re-registering the same slug replaces the existing ref in place
rather than appending a second one, and reports action "updated" instead of
"created". This is what makes a re-run of the authoring skill safe.

Not transactional: the execution log and the manifest are two writes, log first.
An interrupted run is repaired by re-running — the upsert is what makes that safe.

Validates before registering, via validate-entities.py, so the manifest cannot
take an entity the validator rejects even when this script is invoked directly.

Stdlib-only (no PyYAML).

Usage:
  python3 register-entity.py <portfolio-dir> <entity-file>

Output: a single JSON line following the repo contract
  {"success": bool, "data": {...}, "error": str}
Exit: 0 ok / 1 the entity failed validation / 2 usage or environment failure.
"""

import datetime
import importlib.util
import json
import os
import sys

# validate-entities.py is not an importable module name (hyphens), so load it by
# file location rather than duplicating its rules here — this script must gate on
# exactly the schema the validator enforces.
_v_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate-entities.py")
_spec = importlib.util.spec_from_file_location("validate_entities", _v_path)
if _spec is None or _spec.loader is None:
    print(json.dumps({
        "success": False, "data": {},
        "error": "cannot load validator module: %s" % _v_path,
    }))
    sys.exit(2)
_ve = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ve)

# The summary-ref fields each type carries into the manifest (see
# references/data-model.md "Manifest registration"). These are an editorial
# subset of the validator's `required` list — the ref is a pointer, not a copy —
# so they are named here rather than derived. The array each type registers into
# is the validator's own subdir name, so it is read from SCHEMA, not restated.
REF_FIELDS = {
    "consultant": ["slug", "name"],
    "project": ["slug", "name"],
    "assignment": ["slug", "consultant", "project"],
}


def _fail(message, code=2):
    print(json.dumps(
        {"success": False, "data": {}, "error": message}, ensure_ascii=False
    ))
    return code


def main(argv):
    if len(argv) != 2:
        return _fail("usage: register-entity.py <portfolio-dir> <entity-file>")

    portfolio_dir, entity_file = argv

    manifest_path = os.path.join(portfolio_dir, "projects-portfolio.json")
    if not os.path.isfile(manifest_path):
        return _fail(
            "portfolio manifest not found: %s (run /cogni-projects:projects-setup first)"
            % manifest_path
        )
    if not os.path.isfile(entity_file):
        return _fail("entity file not found: %s" % entity_file)

    # Gate on the validator rather than re-checking its rules by hand: a weaker
    # local copy would drift, and silently registering an entity the validator
    # rejects is the exact failure registration is supposed to prevent.
    errors, _warnings = _ve.validate_file(entity_file)
    if errors:
        return _fail(
            "entity failed validation (%d error(s)) — run validate-entities.py "
            "on it and fix each error before registering" % len(errors),
            code=1,
        )

    try:
        with open(entity_file, "r", encoding="utf-8") as f:
            fm = _ve.parse_frontmatter(f.read())
    except OSError as exc:
        return _fail("cannot read entity file: %s" % exc)

    # `type` is required for every type and the validator errors when it
    # disagrees with the containing subdirectory, so a validated entity always
    # carries the authoritative type here.
    entity_type = fm.get("type")
    if entity_type not in REF_FIELDS:
        return _fail(
            "unknown entity type %r (expected one of %s)"
            % (entity_type, ", ".join(sorted(REF_FIELDS))),
            code=1,
        )

    array_name = _ve.SCHEMA[entity_type]["subdir"]
    slug = str(fm["slug"])
    ref = {key: str(fm[key]) for key in REF_FIELDS[entity_type]}
    # The ref points at the entity file relative to the portfolio root, so the
    # dashboard and staffing skills can resolve it without knowing the cwd.
    rel = os.path.relpath(os.path.abspath(entity_file), os.path.abspath(portfolio_dir))
    # Refuse an entity that lives outside the target portfolio. Validation cannot
    # catch this — a foreign entity file is itself perfectly valid — but the ref
    # would escape the root, and consumers resolve `file` relative to it, so one
    # portfolio would silently read another's records.
    if rel == os.pardir or rel.startswith(os.pardir + os.sep):
        return _fail(
            "entity file %s is not inside portfolio %s — an entity is registered "
            "only into the portfolio that holds it" % (entity_file, portfolio_dir)
        )
    ref["file"] = rel

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (OSError, ValueError) as exc:
        return _fail("cannot read portfolio manifest: %s" % exc)

    array = manifest.setdefault(array_name, [])
    if not isinstance(array, list):
        return _fail("manifest %r is not a list" % array_name)

    # Upsert keyed on slug — the idempotency contract.
    index = next(
        (i for i, e in enumerate(array) if isinstance(e, dict) and e.get("slug") == slug),
        None,
    )
    if index is None:
        array.append(ref)
        action = "created"
    else:
        array[index] = ref
        action = "updated"

    today = datetime.date.today().isoformat()
    manifest["updated"] = today

    log_path = os.path.join(portfolio_dir, ".metadata", "execution-log.json")
    log = {"transitions": []}
    if os.path.isfile(log_path):
        try:
            with open(log_path, "r", encoding="utf-8") as f:
                log = json.load(f)
        except (OSError, ValueError) as exc:
            return _fail("cannot read execution log: %s" % exc)
    log.setdefault("transitions", []).append({
        "slug": slug,
        "entity_type": entity_type,
        "action": action,
        "file": ref["file"],
        "at": today,
    })

    # ensure_ascii=False matches portfolio-init.sh's writer: these portfolios
    # carry European names, and the repo convention forbids ASCII escapes.
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "w", encoding="utf-8") as f:
            json.dump(log, f, indent=2, ensure_ascii=False)
            f.write("\n")
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
            f.write("\n")
    except OSError as exc:
        return _fail("cannot write portfolio state: %s" % exc)

    print(json.dumps({
        "success": True,
        "data": {
            "slug": slug,
            "entity_type": entity_type,
            "action": action,
            "array": array_name,
            "file": ref["file"],
            "updated": today,
        },
        "error": "",
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
