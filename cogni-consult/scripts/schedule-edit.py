#!/usr/bin/env python3
"""Plan-editing surface for a cogni-consult engagement's deliverable schedule.

Usage:
  python3 schedule-edit.py <engagement-dir> set <action_field>/<deliverable> \
      --field <start_date|due_date|duration|owner|milestone> --value <value> \
      [--rationale <text>]
  python3 schedule-edit.py <engagement-dir> show <action_field>/<deliverable>

Returns JSON on stdout: {"success": bool, "data": {...}, "error": "string"}

The five scheduling fields (references/project-plan-model.md) are optional and
additive on a deliverable entry inside its owning action-fields/<slug>/field.json.
This is the WRITE half of that contract; the read-model (`deliverable-graph.py
schedule`) is already merged and derives calendar placement from the dependency
graph — no schedule is stored beyond these authored inputs.

`set` writes/updates exactly ONE scheduling field on the named deliverable,
preserving every sibling key of the deliverable entry (state, dt_stage,
depends_on[], persona_review, ...), and appends exactly one `plan-schedule-edit`
entry to .metadata/decision-log.json (the audit-trail contract in
references/data-model.md). One field per invocation keeps a 1:1 mapping to the
singular {field, from, to} decision entry. `show` reads the five fields back.

Validation — on any failure the command returns success:false with a clear error
and writes NOTHING (neither field.json nor the decision-log):
  - start_date / due_date must be ISO-8601 calendar dates (YYYY-MM-DD).
  - duration must be a non-negative integer (effort-days); authored 0 is valid.
  - milestone must be a boolean (true/false).
  - owner is free text.

Stdlib only.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone

# The five optional, additive scheduling fields (references/project-plan-model.md).
SCHEDULING_FIELDS = ("start_date", "due_date", "duration", "owner", "milestone")


def envelope(success, data=None, error=""):
    """Standard cogni-consult script result envelope."""
    return {"success": success, "data": data or {}, "error": error}


def parse_coordinate(raw):
    """Parse the '<action_field>/<deliverable>' CLI shorthand into a pair."""
    if raw is None or "/" not in raw:
        raise ValueError(
            f"coordinate must be '<action_field>/<deliverable>', got: {raw!r}"
        )
    action_field, _, deliverable = raw.partition("/")
    action_field, deliverable = action_field.strip(), deliverable.strip()
    if not action_field or not deliverable:
        raise ValueError(
            f"coordinate must be '<action_field>/<deliverable>', got: {raw!r}"
        )
    return action_field, deliverable


def field_json_path(engagement_dir, action_field):
    return os.path.join(engagement_dir, "action-fields", action_field, "field.json")


def load_field_json(engagement_dir, action_field):
    fpath = field_json_path(engagement_dir, action_field)
    if not os.path.isfile(fpath):
        raise ValueError(f"action field not found: {action_field} ({fpath})")
    with open(fpath) as f:
        return fpath, json.load(f)


def find_deliverable(fjson, deliverable):
    for deliv in fjson.get("deliverables") or []:
        if deliv.get("slug") == deliverable:
            return deliv
    return None


def coerce_value(field, raw):
    """Coerce and validate the raw --value string for the named scheduling field.

    Raises ValueError with a clear message on an unknown field or an invalid
    value, so the caller writes nothing and returns success:false.
    """
    if field in ("start_date", "due_date"):
        try:
            datetime.strptime(raw, "%Y-%m-%d")
        except (ValueError, TypeError):
            raise ValueError(
                f"{field} must be an ISO-8601 date (YYYY-MM-DD), got: {raw!r}"
            )
        return raw
    if field == "duration":
        try:
            n = int(raw)
        except (ValueError, TypeError):
            raise ValueError(
                f"duration must be a non-negative integer (effort-days), got: {raw!r}"
            )
        if n < 0:
            raise ValueError(
                f"duration must be a non-negative integer (effort-days), got: {raw!r}"
            )
        return n
    if field == "milestone":
        low = str(raw).strip().lower()
        if low in ("true", "1", "yes"):
            return True
        if low in ("false", "0", "no"):
            return False
        raise ValueError(f"milestone must be a boolean (true/false), got: {raw!r}")
    if field == "owner":
        return str(raw)
    raise ValueError(f"--field must be one of {SCHEDULING_FIELDS}, got: {field!r}")


def next_decision_id(decisions):
    """The next 'd-NNN' id, one past the max numeric suffix (0 -> d-001)."""
    max_n = 0
    for d in decisions:
        did = d.get("id", "")
        if isinstance(did, str) and did.startswith("d-") and did[2:].isdigit():
            max_n = max(max_n, int(did[2:]))
    return f"d-{max_n + 1:03d}"


def write_json(path, obj):
    """Write JSON matching the plugin's field.json / decision-log style."""
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)
        f.write("\n")


def cmd_set(engagement_dir, coordinate, field, value, rationale):
    """Set one scheduling field on a deliverable and log the edit.

    Order of operations: parse, load, find, validate, and parse the decision-log
    BEFORE any write — so a malformed value, a missing deliverable, or a corrupt
    decision-log leaves both files byte-identical (AC2).
    """
    action_field, deliverable = parse_coordinate(coordinate)
    fpath, fjson = load_field_json(engagement_dir, action_field)
    deliv = find_deliverable(fjson, deliverable)
    if deliv is None:
        raise ValueError(f"deliverable not found: {action_field}/{deliverable}")

    new_value = coerce_value(field, value)

    # Parse the decision-log up front so a corrupt/absent log fails before we
    # touch field.json (keeps the two writes all-or-nothing in practice).
    dpath = os.path.join(engagement_dir, ".metadata", "decision-log.json")
    if not os.path.isfile(dpath):
        raise ValueError(f"decision-log not found: {dpath}")
    with open(dpath) as f:
        dlog = json.load(f)
    decisions = dlog.setdefault("decisions", [])

    old_value = deliv.get(field, None)
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    entry = {
        "id": next_decision_id(decisions),
        "kind": "plan-schedule-edit",
        "action_field": action_field,
        "deliverable": deliverable,
        "field": field,
        "from": old_value,
        "to": new_value,
        "rationale": rationale or "",
        "timestamp": timestamp,
    }

    # Write only after every check has passed.
    deliv[field] = new_value
    write_json(fpath, fjson)

    decisions.append(entry)
    write_json(dpath, dlog)

    return envelope(
        True,
        {
            "action_field": action_field,
            "deliverable": deliverable,
            "field": field,
            "from": old_value,
            "to": new_value,
            "decision_id": entry["id"],
            "timestamp": timestamp,
        },
    )


def cmd_show(engagement_dir, coordinate):
    """Read the five scheduling fields back for one deliverable."""
    action_field, deliverable = parse_coordinate(coordinate)
    _, fjson = load_field_json(engagement_dir, action_field)
    deliv = find_deliverable(fjson, deliverable)
    if deliv is None:
        raise ValueError(f"deliverable not found: {action_field}/{deliverable}")
    schedule = {
        "start_date": deliv.get("start_date"),
        "due_date": deliv.get("due_date"),
        "duration": deliv.get("duration"),
        "owner": deliv.get("owner"),
        "milestone": deliv.get("milestone", False),
    }
    return envelope(
        True,
        {
            "action_field": action_field,
            "deliverable": deliverable,
            "schedule": schedule,
        },
    )


def main():
    ap = argparse.ArgumentParser(
        description="Plan-editing surface for cogni-consult deliverable scheduling fields."
    )
    ap.add_argument("engagement_dir")
    sub = ap.add_subparsers(dest="command", required=True)

    p_set = sub.add_parser("set", help="Set one scheduling field on a deliverable.")
    p_set.add_argument("coordinate", help="<action_field>/<deliverable>")
    # No choices= here: an unknown field must return a JSON success:false envelope
    # (via coerce_value), not an argparse exit-2 usage error on stderr.
    p_set.add_argument("--field", required=True, help=f"one of {SCHEDULING_FIELDS}")
    p_set.add_argument("--value", required=True)
    p_set.add_argument("--rationale", default="")

    p_show = sub.add_parser("show", help="Read the five scheduling fields back.")
    p_show.add_argument("coordinate", help="<action_field>/<deliverable>")

    args = ap.parse_args()
    try:
        if not os.path.isdir(args.engagement_dir):
            raise ValueError(f"engagement directory not found: {args.engagement_dir}")
        if args.command == "set":
            result = cmd_set(
                args.engagement_dir,
                args.coordinate,
                args.field,
                args.value,
                args.rationale,
            )
        elif args.command == "show":
            result = cmd_show(args.engagement_dir, args.coordinate)
        else:  # pragma: no cover — argparse enforces the choice set
            raise ValueError(f"unknown command: {args.command}")
    except ValueError as exc:
        print(json.dumps(envelope(False, {}, str(exc)), ensure_ascii=False))
        return
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
