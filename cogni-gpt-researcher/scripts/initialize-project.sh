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

# Validate optional parameters against allowed values
VALID_TONES="objective analytical persuasive critical narrative simple exploratory comparative evaluative diplomatic provocative technical humorous empathetic"
if [[ -n "$TONE" ]] && ! echo "$VALID_TONES" | grep -qw "$TONE"; then
  echo "{\"success\": false, \"error\": \"Invalid --tone: $TONE. Valid tones: $VALID_TONES\"}" >&2
  exit 2
fi

VALID_CITATION_FORMATS="apa mla chicago harvard ieee"
if [[ -n "$CITATION_FORMAT" ]] && ! echo "$VALID_CITATION_FORMATS" | grep -qw "$CITATION_FORMAT"; then
  echo "{\"success\": false, \"error\": \"Invalid --citation-format: $CITATION_FORMAT. Valid formats: $VALID_CITATION_FORMATS\"}" >&2
  exit 2
fi

if [[ -n "$REPORT_SOURCE" ]] && [[ ! "$REPORT_SOURCE" =~ ^(web|local|hybrid)$ ]]; then
  echo "{\"success\": false, \"error\": \"Invalid --report-source: $REPORT_SOURCE. Must be web, local, or hybrid.\"}" >&2
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

# Read plugin version from plugin.json (avoid hardcoding)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "0.0.0")

# Build project config using jq for safe JSON construction
CONFIG=$(jq -n \
  --arg topic "$TOPIC" \
  --arg report_type "$REPORT_TYPE" \
  --arg language "$LANGUAGE" \
  --arg created_at "$TIMESTAMP" \
  --arg plugin_version "$PLUGIN_VERSION" \
  '{
    topic: $topic,
    report_type: $report_type,
    language: $language,
    created_at: $created_at,
    plugin: "cogni-gpt-researcher",
    plugin_version: $plugin_version,
    phases_completed: []
  }')

# Add optional fields via jq
if [[ -n "$TONE" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$TONE" '. + {tone: $v}')
fi
if [[ -n "$RESEARCHER_ROLE" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$RESEARCHER_ROLE" '. + {researcher_role: $v}')
fi
if [[ -n "$SOURCE_URLS" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$SOURCE_URLS" '. + {source_urls: ($v | split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map(select(length > 0)))}')
fi
if [[ -n "$QUERY_DOMAINS" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$QUERY_DOMAINS" '. + {query_domains: ($v | split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map(select(length > 0)))}')
fi
if [[ -n "$MAX_SUBTOPICS" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --argjson v "$MAX_SUBTOPICS" '. + {max_subtopics: $v}')
fi
if [[ -n "$CITATION_FORMAT" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$CITATION_FORMAT" '. + {citation_format: $v}')
fi
if [[ -n "$REPORT_SOURCE" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$REPORT_SOURCE" '. + {report_source: $v}')
fi
if [[ -n "$DOCUMENT_PATHS" ]]; then
  CONFIG=$(echo "$CONFIG" | jq --arg v "$DOCUMENT_PATHS" '. + {document_paths: ($v | split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map(select(length > 0)))}')
fi
if [[ "$CURATE_SOURCES" == "true" ]]; then
  CONFIG=$(echo "$CONFIG" | jq '. + {curate_sources: true}')
fi
if [[ "$GENERATE_IMAGES" == "true" ]]; then
  CONFIG=$(echo "$CONFIG" | jq '. + {generate_images: true}')
fi

echo "$CONFIG" > "$PROJECT_DIR/.metadata/project-config.json"

# Initialize execution log using jq
jq -n \
  --arg project_path "$PROJECT_DIR" \
  --arg topic "$TOPIC" \
  --arg report_type "$REPORT_TYPE" \
  --arg started_at "$TIMESTAMP" \
  '{
    project_path: $project_path,
    topic: $topic,
    report_type: $report_type,
    started_at: $started_at,
    phases: {}
  }' > "$PROJECT_DIR/.metadata/execution-log.json"

echo "{\"success\": true, \"project_path\": \"$PROJECT_DIR\", \"already_exists\": false}"
