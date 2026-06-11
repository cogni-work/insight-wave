#!/usr/bin/env bash
# Read a cogni-consult engagement's consult-project.json and derive the WBS
# field/deliverable rollup. Consumers: the consult-action-fields and
# consult-resume skills.
# Usage: bash engagement-status.sh <engagement-dir>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

ENGAGEMENT_DIR="${1:?Usage: bash engagement-status.sh <engagement-dir>}"

ENGAGEMENT_DIR="$ENGAGEMENT_DIR" python3 - <<'PY'
import json, os

engagement_dir = os.environ["ENGAGEMENT_DIR"]
path = os.path.join(engagement_dir, "consult-project.json")
try:
    with open(path) as f:
        project = json.load(f)
except (json.JSONDecodeError, OSError) as exc:
    print(json.dumps({"success": False, "data": {"path": path}, "error": f"unreadable project file: {exc}"}))
    raise SystemExit(0)

# Deliverable state lives only in action-fields/*/field.json (single source of
# truth); field and engagement rollups are derived here at read time. A missing
# field.json is a legitimately not-started field; an unreadable one is surfaced
# as "unreadable" plus a warning, never conflated with "pending".
fields = []
warnings = []
field_slugs = project.get("action_fields") or []
if not isinstance(field_slugs, list) or not all(isinstance(s, str) for s in field_slugs):
    print(json.dumps({"success": False, "data": {"path": path}, "error": "malformed project file: action_fields must be a list of strings"}))
    raise SystemExit(0)

try:
    for slug in field_slugs:
        field_path = os.path.join(engagement_dir, "action-fields", slug, "field.json")
        try:
            with open(field_path) as f:
                field = json.load(f)
            deliverables = field.get("deliverables") or []
            states = [d.get("state", "pending") for d in deliverables]
            if states and all(s == "complete" for s in states):
                rollup = "complete"
            elif any(s != "pending" for s in states):
                rollup = "in-progress"
            else:
                rollup = "pending"
            fields.append({"slug": slug, "state": rollup, "deliverables": deliverables})
        except FileNotFoundError:
            fields.append({"slug": slug, "state": "pending", "deliverables": []})
        except (json.JSONDecodeError, OSError) as exc:
            fields.append({"slug": slug, "state": "unreadable", "deliverables": []})
            warnings.append(f"unreadable field file: {field_path}: {exc}")

    data = {
        **{k: project.get(k) for k in ("slug", "name", "language", "key_question", "updated")},
        "scope_state": (project.get("workflow_state") or {}).get("scope", "pending"),
        "action_fields": fields,
        "plugin_refs": project.get("plugin_refs") or {},
        "warnings": warnings,
    }
except (TypeError, AttributeError) as exc:
    print(json.dumps({"success": False, "data": {"path": path}, "error": f"malformed project file: {exc}"}))
    raise SystemExit(0)

print(json.dumps({"success": True, "data": data, "error": ""}))
PY
