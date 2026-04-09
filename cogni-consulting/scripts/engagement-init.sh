#!/usr/bin/env bash
# Creates the engagement directory structure for a cogni-consulting project.
# Usage: bash engagement-init.sh <workspace-dir> <engagement-slug>
# Output: JSON {"success": bool, "data": {...}, "error": "string"}

set -euo pipefail

WORKSPACE_DIR="${1:?Usage: engagement-init.sh <workspace-dir> <engagement-slug>}"
SLUG="${2:?Usage: engagement-init.sh <workspace-dir> <engagement-slug>}"

PROJECT_DIR="${WORKSPACE_DIR}/cogni-consulting/${SLUG}"

# Check for existing project
if [ -f "${PROJECT_DIR}/consulting-project.json" ]; then
  echo "{\"success\": false, \"error\": \"Project already exists at ${PROJECT_DIR}\", \"data\": {\"status\": \"exists\", \"path\": \"${PROJECT_DIR}\"}}"
  exit 0
fi

# Create directory structure
mkdir -p "${PROJECT_DIR}/.metadata"
mkdir -p "${PROJECT_DIR}/discover/research"
mkdir -p "${PROJECT_DIR}/discover/trends"
mkdir -p "${PROJECT_DIR}/discover/competitive"
mkdir -p "${PROJECT_DIR}/define"
mkdir -p "${PROJECT_DIR}/develop/options"
mkdir -p "${PROJECT_DIR}/develop/scenarios"
mkdir -p "${PROJECT_DIR}/develop/propositions"
mkdir -p "${PROJECT_DIR}/deliver"
mkdir -p "${PROJECT_DIR}/personas"
mkdir -p "${PROJECT_DIR}/output"

# Initialize execution log
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "${PROJECT_DIR}/.metadata/execution-log.json" << EOFLOG
{
  "created": "${CREATED_AT}",
  "phases": {
    "discover": { "started": null, "completed": null, "iteration_count": 0 },
    "define": { "started": null, "completed": null, "iteration_count": 0 },
    "develop": { "started": null, "completed": null, "iteration_count": 0 },
    "deliver": { "started": null, "completed": null, "iteration_count": 0 }
  }
}
EOFLOG

# Initialize method log
echo '{"methods_applied": []}' > "${PROJECT_DIR}/.metadata/method-log.json"

# Initialize decision log
echo '{"decisions": []}' > "${PROJECT_DIR}/.metadata/decision-log.json"

echo "{\"success\": true, \"data\": {\"path\": \"${PROJECT_DIR}\", \"slug\": \"${SLUG}\"}}"
