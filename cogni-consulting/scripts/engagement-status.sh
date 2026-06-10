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

# Phase identifiers are number-prefixed so sequence is self-evident in ids,
# directory names, and logs. LEGACY_TO_PHASE is the read-forward shim: state
# written by pre-rename engagements (bare identifiers) maps to the numbered
# ids on read; engagement files on disk are never rewritten.
PHASE_ORDER = ["0-scope", "1-discover", "2-define", "3-develop", "4-deliver"]
LEGACY_TO_PHASE = {
    "discover": "1-discover",
    "define": "2-define",
    "develop": "3-develop",
    "deliver": "4-deliver",
}
# 0-scope <-> consulting-scope is not string-derivable, so skill names come
# from an explicit lookup instead of f"consulting-{phase}".
PHASE_TO_SKILL = {
    "0-scope": "consulting-scope",
    "1-discover": "consulting-discover",
    "2-define": "consulting-define",
    "3-develop": "consulting-develop",
    "4-deliver": "consulting-deliver",
}

def normalize_phase(p):
    return LEGACY_TO_PHASE.get(p, p)

# Count files in each phase directory. Legacy engagements keep their old
# unprefixed dir names on disk, so fall back to the bare name when the
# numbered dir is absent.
PHASE_TO_LEGACY = {v: k for k, v in LEGACY_TO_PHASE.items()}
phase_counts = {}
for phase in PHASE_ORDER:
    phase_dir = project_dir / phase
    if not phase_dir.exists() and phase in PHASE_TO_LEGACY:
        legacy_dir = project_dir / PHASE_TO_LEGACY[phase]
        if legacy_dir.exists():
            phase_dir = legacy_dir
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
current = normalize_phase(phase_state.get("current", "0-scope"))

next_actions = []
# Phase entries may be keyed by either the numbered id or (legacy) the bare
# name — check both via the shim's inverse.
current_entry = phase_state.get(current) or phase_state.get(
    PHASE_TO_LEGACY.get(current, current), {}
)
current_status = (current_entry or {}).get("status", "pending")

if current_status == "pending":
    next_actions.append({"action": f"Start {current} phase", "skill": PHASE_TO_SKILL.get(current, "consulting-setup")})
elif current_status == "in-progress":
    next_actions.append({"action": f"Continue {current} phase", "skill": PHASE_TO_SKILL.get(current, "consulting-setup")})
elif current_status == "complete":
    idx = PHASE_ORDER.index(current) if current in PHASE_ORDER else -1
    if 0 <= idx < len(PHASE_ORDER) - 1:
        next_phase = PHASE_ORDER[idx + 1]
        next_actions.append({"action": f"Advance to {next_phase} phase", "skill": PHASE_TO_SKILL[next_phase]})
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
