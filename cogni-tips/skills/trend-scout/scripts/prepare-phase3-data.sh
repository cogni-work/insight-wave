#!/usr/bin/env bash
set -euo pipefail
# prepare-phase3-data.sh
# Version: 1.2.0
# Purpose: Generate compact candidate data, browser app JSON, and self-contained HTML for Phase 3 of trend-scout
# Category: utilities
#
# Usage: prepare-phase3-data.sh <PROJECT_PATH>
#
# Arguments:
#   PROJECT_PATH  Absolute path to project directory (required)
#
# Environment:
#   CLAUDE_PLUGIN_ROOT  Path to plugin installation (for HTML template)
#
# Outputs:
#   - ${PROJECT_PATH}/trend-app-data.json (full data for browser selector)
#   - ${PROJECT_PATH}/trend-selector-app.html (self-contained HTML with embedded data)
#   - ${PROJECT_PATH}/.logs/candidates-compact.json (compact for Claude reading)
#
# Dependencies: jq
#
# Exit codes:
#   0 = success
#   1 = missing PROJECT_PATH argument
#   2 = candidates file not found
#   3 = jq not available
#   4 = HTML template not found


# Validate arguments
if [[ -z "${1:-}" ]]; then
    echo '{"ok":false,"error":"missing_project_path","message":"Usage: prepare-phase3-data.sh <PROJECT_PATH>"}'
    exit 1
fi

PROJECT_PATH="$1"
CANDIDATES_FILE="${PROJECT_PATH}/.logs/trend-generator-candidates.json"

# Validate dependencies
if ! command -v jq &>/dev/null; then
    echo '{"ok":false,"error":"jq_not_found","message":"jq is required but not installed"}'
    exit 3
fi

# Validate input file exists
if [[ ! -f "$CANDIDATES_FILE" ]]; then
    echo "{\"ok\":false,\"error\":\"candidates_not_found\",\"message\":\"File not found: ${CANDIDATES_FILE}\"}"
    exit 2
fi

# Ensure output directories exist
mkdir -p "${PROJECT_PATH}/.logs"

# 1. Generate trend-app-data.json (full data for browser selector)
# This file preserves all candidate details for the visual selector app
# Pre-selects top 3 candidates per cell (by score) for downstream use
jq --arg project_path "$PROJECT_PATH" '{
  meta: {
    project_path: $project_path,
    timestamp: .generation_metadata.timestamp,
    subsector: .generation_metadata.subsector,
    total_candidates: .generation_metadata.total_candidates
  },
  sources: (
    [.candidates_by_cell | to_entries[] | .value | to_entries[] | .value[] | select(.source == "web-signal" and .source_url != null) | {url: .source_url}]
    | unique_by(.url)
    | to_entries
    | map({key: ((.key + 1) | tostring), value: {url: .value.url}})
    | from_entries
  ),
  candidates: [
    .candidates_by_cell | to_entries[] | .value | to_entries[] |
    # Sort candidates within each cell by score descending, then add rank
    (.value | sort_by(-.score) | to_entries) | .[] |
    {
      id: "\(.value.dimension)-\(.value.horizon)-\(.value.sequence)",
      dimension: .value.dimension,
      dimension_key: (if .value.dimension == "externe-effekte" then "t"
                      elif .value.dimension == "neue-horizonte" then "p"
                      elif .value.dimension == "digitale-wertetreiber" then "i"
                      else "s" end),
      horizon: .value.horizon,
      trend_name: .value.name,
      trend_statement: .value.trend_statement,
      research_hint: .value.research_hint,
      keywords: .value.keywords,
      score: .value.score,
      confidence_tier: .value.confidence_tier,
      signal_intensity: .value.signal_intensity,
      source: .value.source,
      source_url: .value.source_url,
      preSelected: (if .value.horizon == "obs" then .key < 3 else .key < 5 end)
    }
  ]
}' "$CANDIDATES_FILE" > "${PROJECT_PATH}/trend-app-data.json"

# 2. Generate compact version for Claude (~8-10K tokens instead of ~27K)
# Uses short keys to minimize token usage while preserving all Phase 3 required fields
# Includes pre-selection status (ps) for top candidates per cell (5 ACT, 5 PLAN, 3 OBS)
jq '{
  meta: {
    ts: .generation_metadata.timestamp,
    subsector: .generation_metadata.subsector,
    total: .generation_metadata.total_candidates
  },
  c: [
    .candidates_by_cell | to_entries[] | .value | to_entries[] |
    # Sort by score descending within each cell, add rank for pre-selection
    (.value | sort_by(-.score) | to_entries) | .[] |
    {
      d: .value.dimension,
      h: .value.horizon,
      n: .value.name,
      s: .value.trend_statement,
      r: .value.research_hint,
      k: .value.keywords,
      sc: .value.score,
      ct: .value.confidence_tier,
      si: .value.signal_intensity,
      src: .value.source,
      url: .value.source_url,
      ps: (if .value.horizon == "obs" then .key < 3 else .key < 5 end)
    }
  ] | sort_by(.d, .h, -.sc)
}' "$CANDIDATES_FILE" > "${PROJECT_PATH}/.logs/candidates-compact.json"

# Calculate file sizes for verification
APP_SIZE=$(wc -c < "${PROJECT_PATH}/trend-app-data.json" | tr -d ' ')
COMPACT_SIZE=$(wc -c < "${PROJECT_PATH}/.logs/candidates-compact.json" | tr -d ' ')

# 3. Generate self-contained HTML with embedded data (supports file:// protocol)
# Determine plugin root - check CLAUDE_PLUGIN_ROOT or derive from script location
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # CLAUDE_PLUGIN_ROOT points directly to the plugin directory
    if [[ -d "${CLAUDE_PLUGIN_ROOT}/skills/trend-scout" ]]; then
        SKILL_ROOT="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout"
    else
        # Fallback: derive from script location
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
    fi
else
    # Fallback: derive from script location (script is in skills/trend-scout/scripts/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
fi

HTML_TEMPLATE="${SKILL_ROOT}/trend-selector-app.html"
HTML_OUTPUT="${PROJECT_PATH}/trend-selector-app.html"

if [[ ! -f "$HTML_TEMPLATE" ]]; then
    echo "{\"ok\":false,\"error\":\"html_template_not_found\",\"message\":\"HTML template not found: ${HTML_TEMPLATE}\"}"
    exit 4
fi

# Generate self-contained HTML by injecting JSON data before </body> tag
# Use awk for portable multiline handling (works on macOS and Linux)
awk '
    /<\/body>/ {
        # Print the embedded data script before </body>
        print "<script>var EMBEDDED_DATA = "
        while ((getline line < json_file) > 0) print line
        close(json_file)
        print ";</script>"
    }
    { print }
' json_file="${PROJECT_PATH}/trend-app-data.json" "$HTML_TEMPLATE" > "$HTML_OUTPUT"

HTML_SIZE=$(wc -c < "${HTML_OUTPUT}" | tr -d ' ')

# Output success JSON
echo "{\"ok\":true,\"files\":{\"trend_app_data\":\"${PROJECT_PATH}/trend-app-data.json\",\"trend_selector_html\":\"${HTML_OUTPUT}\",\"candidates_compact\":\"${PROJECT_PATH}/.logs/candidates-compact.json\"},\"sizes\":{\"app_bytes\":${APP_SIZE},\"html_bytes\":${HTML_SIZE},\"compact_bytes\":${COMPACT_SIZE}}}"
