#!/usr/bin/env bash
set -euo pipefail
# initialize-project.sh - Create project directory structure for a research report
# Version: 1.0.0
#
# Usage: initialize-project.sh --topic <topic> --type <basic|detailed|deep|outline|resource> --workspace <path> [--language <en|de>] [--tone <tone>] [--researcher-role <role>] [--source-urls <url1,url2,...>] [--query-domains <domain1,domain2,...>] [--max-subtopics <N>] [--citation-format <apa|mla|chicago|harvard|ieee>] [--report-source <web|local|hybrid>] [--document-paths <path1,path2,...>]
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
TONE=""
RESEARCHER_ROLE=""
SOURCE_URLS=""
QUERY_DOMAINS=""
MAX_SUBTOPICS=""
CITATION_FORMAT=""
REPORT_SOURCE=""
DOCUMENT_PATHS=""
CURATE_SOURCES=""
GENERATE_IMAGES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic)    TOPIC="$2"; shift 2;;
    --type)     REPORT_TYPE="$2"; shift 2;;
    --workspace) WORKSPACE="$2"; shift 2;;
    --language) LANGUAGE="$2"; shift 2;;
    --tone)     TONE="$2"; shift 2;;
    --researcher-role) RESEARCHER_ROLE="$2"; shift 2;;
    --source-urls) SOURCE_URLS="$2"; shift 2;;
    --query-domains) QUERY_DOMAINS="$2"; shift 2;;
    --max-subtopics) MAX_SUBTOPICS="$2"; shift 2;;
    --citation-format) CITATION_FORMAT="$2"; shift 2;;
    --report-source) REPORT_SOURCE="$2"; shift 2;;
    --document-paths) DOCUMENT_PATHS="$2"; shift 2;;
    --curate-sources) CURATE_SOURCES="true"; shift 1;;
    --generate-images) GENERATE_IMAGES="true"; shift 1;;
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

if [[ ! "$REPORT_TYPE" =~ ^(basic|detailed|deep|outline|resource)$ ]]; then
  echo "{\"success\": false, \"error\": \"Invalid --type: $REPORT_TYPE. Must be basic, detailed, deep, outline, or resource.\"}" >&2
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

# Build optional JSON fields
OPTIONAL_FIELDS=""
if [[ -n "$TONE" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"tone\": $(echo "$TONE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),"
fi
if [[ -n "$RESEARCHER_ROLE" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"researcher_role\": $(echo "$RESEARCHER_ROLE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),"
fi
if [[ -n "$SOURCE_URLS" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"source_urls\": $(echo "$SOURCE_URLS" | python3 -c 'import json,sys; print(json.dumps([u.strip() for u in sys.stdin.read().strip().split(",") if u.strip()]))'),"
fi
if [[ -n "$QUERY_DOMAINS" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"query_domains\": $(echo "$QUERY_DOMAINS" | python3 -c 'import json,sys; print(json.dumps([d.strip() for d in sys.stdin.read().strip().split(",") if d.strip()]))'),"
fi
if [[ -n "$MAX_SUBTOPICS" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"max_subtopics\": $MAX_SUBTOPICS,"
fi
if [[ -n "$CITATION_FORMAT" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"citation_format\": $(echo "$CITATION_FORMAT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),"
fi
if [[ -n "$REPORT_SOURCE" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"report_source\": $(echo "$REPORT_SOURCE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),"
fi
if [[ -n "$DOCUMENT_PATHS" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"document_paths\": $(echo "$DOCUMENT_PATHS" | python3 -c 'import json,sys; print(json.dumps([p.strip() for p in sys.stdin.read().strip().split(",") if p.strip()]))'),"
fi
if [[ "$CURATE_SOURCES" == "true" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"curate_sources\": true,"
fi
if [[ "$GENERATE_IMAGES" == "true" ]]; then
  OPTIONAL_FIELDS="$OPTIONAL_FIELDS
  \"generate_images\": true,"
fi

cat > "$PROJECT_DIR/.metadata/project-config.json" <<EOF
{
  "topic": $(echo "$TOPIC" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "report_type": "$REPORT_TYPE",
  "language": "$LANGUAGE",${OPTIONAL_FIELDS}
  "created_at": "$TIMESTAMP",
  "plugin": "cogni-gpt-researcher",
  "plugin_version": "0.3.0",
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
