#!/usr/bin/env bash
# Read a cogni-consult engagement's consult-project.json and return its
# workflow state. Stub: the consult-resume skill defines the full status contract.
# Usage: bash engagement-status.sh <engagement-dir>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

ENGAGEMENT_DIR="${1:?Usage: bash engagement-status.sh <engagement-dir>}"
PROJECT_FILE="${ENGAGEMENT_DIR}/consult-project.json"

if [ ! -f "$PROJECT_FILE" ]; then
  printf '{"success": false, "data": {"path": "%s"}, "error": "consult-project.json not found"}\n' "$PROJECT_FILE"
  exit 0
fi

PROJECT_FILE="$PROJECT_FILE" ENGAGEMENT_DIR="$ENGAGEMENT_DIR" python3 - <<'PY'
import json, os

path = os.environ["PROJECT_FILE"]
engagement_dir = os.environ["ENGAGEMENT_DIR"]
try:
    with open(path) as f:
        project = json.load(f)
except (json.JSONDecodeError, OSError) as exc:
    print(json.dumps({"success": False, "data": {"path": path}, "error": f"unreadable project file: {exc}"}))
    raise SystemExit(0)

# Deliverable state lives only in action-fields/*/field.json (single source of
# truth); field and engagement rollups are derived here at read time.
fields = {}
for slug in project.get("action_fields", []):
    field_path = os.path.join(engagement_dir, "action-fields", slug, "field.json")
    try:
        with open(field_path) as f:
            field = json.load(f)
        deliverables = field.get("deliverables", [])
        states = [d.get("state", "pending") for d in deliverables]
        if states and all(s == "complete" for s in states):
            rollup = "complete"
        elif any(s != "pending" for s in states):
            rollup = "in-progress"
        else:
            rollup = "pending"
        fields[slug] = {"state": rollup, "deliverables": deliverables}
    except (json.JSONDecodeError, OSError):
        fields[slug] = {"state": "pending", "deliverables": []}

print(json.dumps({
    "success": True,
    "data": {
        **{k: project.get(k) for k in ("slug", "name", "key_question", "updated")},
        "scope_state": project.get("workflow_state", {}).get("scope", "pending"),
        "action_fields": fields,
        "plugin_refs": project.get("plugin_refs", {}),
    },
}))
PY
