#!/usr/bin/env bash
set -euo pipefail
# initialize-project.sh - Create project directory structure for a research report
# Version: 1.0.0
#
# Usage: initialize-project.sh --topic <topic> --type <basic|detailed|deep> --workspace <path> [--language <en|de>]
#
# Creates:
#   {workspace}/{slug}-{date}/
#   ├── .metadata/
#   │   └── project-config.json
#   ├── 00-sub-questions/data/
#   ├── 01-contexts/data/
#   ├── 02-sources/data/
#   ├── 03-report-claims/data/
#   ├── .logs/
#   └── output/
#
# Output (JSON): {"success": true, "project_path": "..."}

TOPIC=""
REPORT_TYPE="basic"
WORKSPACE=""
LANGUAGE="en"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic)    TOPIC="$2"; shift 2;;
    --type)     REPORT_TYPE="$2"; shift 2;;
    --workspace) WORKSPACE="$2"; shift 2;;
    --language) LANGUAGE="$2"; shift 2;;
    *) echo "{\"success\": false, \"error\": \"Unknown argument: $1\"}" >&2; exit 2;;
  esac
done

# Validate required args
if [[ -z "$TOPIC" ]]; then
  echo '{"success": false, "error": "Missing --topic argument"}' >&2
  exit 2
fi

if [[ -z "$WORKSPACE" ]]; then
  echo '{"success": false, "error": "Missing --workspace argument"}' >&2
  exit 2
fi

if [[ ! "$REPORT_TYPE" =~ ^(basic|detailed|deep)$ ]]; then
  echo "{\"success\": false, \"error\": \"Invalid --type: $REPORT_TYPE. Must be basic, detailed, or deep.\"}" >&2
  exit 2
fi

# Generate slug
SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/-\+/-/g' | head -c 40 | sed 's/-$//')
DATE=$(date -u +%Y-%m-%d)
PROJECT_DIR="$WORKSPACE/${SLUG}-${DATE}"

# Check if project already exists
if [[ -d "$PROJECT_DIR" ]]; then
  echo "{\"success\": true, \"project_path\": \"$PROJECT_DIR\", \"already_exists\": true}"
  exit 0
fi

# Create directory structure
mkdir -p "$PROJECT_DIR/.metadata"
mkdir -p "$PROJECT_DIR/00-sub-questions/data"
mkdir -p "$PROJECT_DIR/01-contexts/data"
mkdir -p "$PROJECT_DIR/02-sources/data"
mkdir -p "$PROJECT_DIR/03-report-claims/data"
mkdir -p "$PROJECT_DIR/.logs"
mkdir -p "$PROJECT_DIR/output"

# Write project config
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$PROJECT_DIR/.metadata/project-config.json" <<EOF
{
  "topic": $(echo "$TOPIC" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "report_type": "$REPORT_TYPE",
  "language": "$LANGUAGE",
  "created_at": "$TIMESTAMP",
  "plugin": "cogni-gpt-researcher",
  "plugin_version": "0.1.0",
  "phases_completed": []
}
EOF

# Initialize execution log
cat > "$PROJECT_DIR/.metadata/execution-log.json" <<EOF
{
  "project_path": "$PROJECT_DIR",
  "topic": $(echo "$TOPIC" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "report_type": "$REPORT_TYPE",
  "started_at": "$TIMESTAMP",
  "phases": {}
}
EOF

echo "{\"success\": true, \"project_path\": \"$PROJECT_DIR\", \"already_exists\": false}"
