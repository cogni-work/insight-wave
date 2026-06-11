#!/usr/bin/env bash
# Create the cogni-consult engagement directory skeleton + consult-project.json.
# Stub: the consult-setup skill fills in the real scaffolding contract.
# Usage: bash engagement-init.sh <engagement-slug> <engagement-name>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

SLUG="${1:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"
NAME="${2:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"

BASE_DIR="cogni-consult/${SLUG}"

if [ -e "$BASE_DIR" ]; then
  printf '{"success": false, "data": {"path": "%s"}, "error": "engagement directory already exists"}\n' "$BASE_DIR"
  exit 0
fi

mkdir -p "$BASE_DIR"/{scope,action-fields,personas,.metadata}

SLUG="$SLUG" NAME="$NAME" BASE_DIR="$BASE_DIR" python3 - <<'PY'
import json, os, datetime

base = os.environ["BASE_DIR"]
today = datetime.date.today().isoformat()
project = {
    "slug": os.environ["SLUG"],
    "name": os.environ["NAME"],
    "language": "en",
    "key_question": "",
    "action_fields": [],
    "workflow_state": {"scope": "pending"},
    "plugin_refs": {},
    "created": today,
    "updated": today,
}
with open(os.path.join(base, "consult-project.json"), "w") as f:
    json.dump(project, f, indent=2, ensure_ascii=False)
    f.write("\n")

for log, payload in [
    ("execution-log.json", {"transitions": []}),
    ("method-log.json", {"methods": []}),
    ("decision-log.json", {"decisions": []}),
]:
    with open(os.path.join(base, ".metadata", log), "w") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")

print(json.dumps({"success": True, "data": {"path": base, "slug": project["slug"]}}))
PY
