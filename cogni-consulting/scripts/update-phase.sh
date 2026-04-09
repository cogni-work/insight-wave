#!/usr/bin/env bash
# Transitions phase state in consulting-project.json.
# Usage: bash update-phase.sh <project-dir> <phase> <status>
# Phases: discover, define, develop, deliver
# Status: pending, in-progress, complete
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

PROJECT_DIR="${1:?Usage: update-phase.sh <project-dir> <phase> <status>}"
PHASE="${2:?Usage: update-phase.sh <project-dir> <phase> <status>}"
STATUS="${3:?Usage: update-phase.sh <project-dir> <phase> <status>}"

if [ ! -f "${PROJECT_DIR}/consulting-project.json" ]; then
  echo "{\"success\": false, \"error\": \"No consulting-project.json found\"}"
  exit 1
fi

python3 - "${PROJECT_DIR}" "${PHASE}" "${STATUS}" << 'PYEOF'
import json, sys
from datetime import datetime, timezone

project_dir = sys.argv[1]
phase = sys.argv[2]
status = sys.argv[3]

valid_phases = ["discover", "define", "develop", "deliver"]
valid_statuses = ["pending", "in-progress", "complete"]

if phase not in valid_phases:
    print(json.dumps({"success": False, "error": f"Invalid phase: {phase}. Must be one of {valid_phases}"}))
    sys.exit(0)

if status not in valid_statuses:
    print(json.dumps({"success": False, "error": f"Invalid status: {status}. Must be one of {valid_statuses}"}))
    sys.exit(0)

project_path = f"{project_dir}/consulting-project.json"
with open(project_path) as f:
    project = json.load(f)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Update phase state
phase_state = project.setdefault("phase_state", {})
phase_data = phase_state.setdefault(phase, {"status": "pending", "started": None, "completed": None, "iteration_count": 0})

# Detect re-entry: complete -> in-progress (iteration)
is_reentry = (phase_data.get("status") == "complete" and status == "in-progress")

phase_data["status"] = status
if status == "in-progress" and not phase_data.get("started"):
    phase_data["started"] = now
if status == "in-progress" and is_reentry:
    phase_data["iteration_count"] = phase_data.get("iteration_count", 0) + 1
if status == "complete":
    phase_data["completed"] = now

# Ensure iteration_count exists (backfill for older engagements)
if "iteration_count" not in phase_data:
    phase_data["iteration_count"] = 0

# Update current phase pointer
if status == "in-progress":
    phase_state["current"] = phase
elif status == "complete":
    idx = valid_phases.index(phase)
    if idx < len(valid_phases) - 1:
        phase_state["current"] = valid_phases[idx + 1]

# Update engagement timestamp
project.setdefault("engagement", {})["updated"] = now

with open(project_path, "w") as f:
    json.dump(project, f, indent=2)

# Update execution log
log_path = f"{project_dir}/.metadata/execution-log.json"
try:
    with open(log_path) as f:
        log = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    log = {"phases": {}}

log_phase = log.setdefault("phases", {}).setdefault(phase, {})
if status == "in-progress" and not log_phase.get("started"):
    log_phase["started"] = now
if status == "in-progress" and is_reentry:
    # Log the re-entry event with iteration count
    reentries = log_phase.setdefault("reentries", [])
    reentries.append({
        "timestamp": now,
        "iteration": phase_data["iteration_count"]
    })
if status == "complete":
    log_phase["completed"] = now

with open(log_path, "w") as f:
    json.dump(log, f, indent=2)

result_data = {"phase": phase, "status": status, "updated": now}
if is_reentry:
    result_data["iteration"] = phase_data["iteration_count"]
    result_data["reentry"] = True

print(json.dumps({"success": True, "data": result_data}))
PYEOF
