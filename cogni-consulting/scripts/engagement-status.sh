#!/usr/bin/env bash
# Reads engagement state from consulting-project.json and plugin project states.
# Usage: bash engagement-status.sh <project-dir>
# Output: JSON with phase_state, plugin_status, methods_used, decisions

set -euo pipefail

PROJECT_DIR="${1:?Usage: engagement-status.sh <project-dir>}"

if [ ! -f "${PROJECT_DIR}/consulting-project.json" ]; then
  echo "{\"success\": false, \"error\": \"No consulting-project.json found in ${PROJECT_DIR}\"}"
  exit 0
fi

python3 - "${PROJECT_DIR}" << 'PYEOF'
import json, sys, os
from pathlib import Path
from datetime import datetime

project_dir = Path(sys.argv[1])

# Read consulting-project.json
with open(project_dir / "consulting-project.json") as f:
    project = json.load(f)

# Count files in each phase directory
phase_counts = {}
for phase in ["discover", "define", "develop", "deliver"]:
    phase_dir = project_dir / phase
    if phase_dir.exists():
        files = [f for f in phase_dir.rglob("*") if f.is_file() and not f.name.startswith(".")]
        phase_counts[phase] = len(files)
    else:
        phase_counts[phase] = 0

# Check output directory
output_dir = project_dir / "output"
output_count = len([f for f in output_dir.rglob("*") if f.is_file()]) if output_dir.exists() else 0

# Check plugin project references
plugin_status = {}
for ref_name, ref_path in project.get("plugin_refs", {}).items():
    if ref_path:
        # Resolve relative to workspace
        abs_path = project_dir.parent.parent / ref_path if not os.path.isabs(ref_path) else Path(ref_path)
        plugin_status[ref_name] = {
            "path": ref_path,
            "exists": abs_path.exists()
        }

# Read metadata
method_log = []
decision_log = []
metadata_dir = project_dir / ".metadata"

if (metadata_dir / "method-log.json").exists():
    with open(metadata_dir / "method-log.json") as f:
        method_log = json.load(f).get("methods_applied", [])

if (metadata_dir / "decision-log.json").exists():
    with open(metadata_dir / "decision-log.json") as f:
        decision_log = json.load(f).get("decisions", [])

# Determine recommended next action
phase_state = project.get("phase_state", {})
current = phase_state.get("current", "discover")
phase_order = ["discover", "define", "develop", "deliver"]

next_actions = []
current_status = phase_state.get(current, {}).get("status", "pending")

if current_status == "pending":
    next_actions.append({"action": f"Start {current} phase", "skill": f"consulting-{current}"})
elif current_status == "in-progress":
    next_actions.append({"action": f"Continue {current} phase", "skill": f"consulting-{current}"})
elif current_status == "complete":
    idx = phase_order.index(current)
    if idx < len(phase_order) - 1:
        next_phase = phase_order[idx + 1]
        next_actions.append({"action": f"Advance to {next_phase} phase", "skill": f"consulting-{next_phase}"})
    else:
        next_actions.append({"action": "Generate deliverable package", "skill": "consulting-export"})

result = {
    "success": True,
    "data": {
        "engagement": project.get("engagement", {}),
        "vision": project.get("vision", {}),
        "phase_state": phase_state,
        "phase_counts": phase_counts,
        "output_count": output_count,
        "plugin_status": plugin_status,
        "methods_used": method_log,
        "decisions": decision_log,
        "next_actions": next_actions
    }
}

print(json.dumps(result, indent=2))
PYEOF
