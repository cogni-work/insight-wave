#!/usr/bin/env bash
# Create the cogni-consult engagement directory skeleton + consult-project.json.
# Idempotent: re-run is safe; consult-project.json existence is the completion marker.
# Usage: bash engagement-init.sh <engagement-slug> <engagement-name>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

SLUG="${1:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"
NAME="${2:?Usage: bash engagement-init.sh <engagement-slug> <engagement-name>}"

BASE_DIR="cogni-consult/${SLUG}"

# Idempotency keys on the manifest, not the bare directory, so an interrupted
# run (skeleton created, manifest never written) is repairable by re-running.
if [ -f "$BASE_DIR/consult-project.json" ]; then
  BASE_DIR="$BASE_DIR" python3 -c 'import json, os; print(json.dumps({"success": False, "data": {"path": os.environ["BASE_DIR"]}, "error": "engagement already initialized (consult-project.json exists)"}))'
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

for log, payload in [
    ("execution-log.json", {"transitions": []}),
    ("method-log.json", {"methods": []}),
    ("decision-log.json", {"decisions": []}),
]:
    with open(os.path.join(base, ".metadata", log), "w") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")

# Manifest written last: its existence marks a completed init (see the
# idempotency check above).
with open(os.path.join(base, "consult-project.json"), "w") as f:
    json.dump(project, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(json.dumps({"success": True, "data": {"path": base, "slug": project["slug"]}, "error": ""}))
PY
