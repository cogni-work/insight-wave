#!/usr/bin/env bash
set -euo pipefail
# post-write-validate-wikilinks.sh
# Version: 3.0.0
# Purpose: Validate wikilinks in newly created entity files using centralized validation script
#
# Blocks entity creation if broken wikilinks detected
#
# Exit codes:
#   0 - Validation passed or skipped (non-entity file)
#   1 - Validation failed (broken wikilinks detected)
#
# Environment Variables:
#   DEBUG_MODE    Enable debug logging (true/false, default: false)
#   DEBUG_LEVEL   Logging level: INFO, DEBUG, TRACE (default: INFO)


# ============================================================================
# Enhanced Logging Integration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source entity configuration for directory key resolution (required)
source "$PLUGIN_ROOT/scripts/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"

# Source enhanced-logging.sh if available
if [[ -f "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh" ]]; then
    source "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh"
else
    # Fallback logging functions
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
    log_phase() { log_conditional "PHASE" "$1 [$2]"; }
    log_metric() { log_conditional "METRIC" "$1=$2 unit=$3"; }
fi

# Input: File path of newly written entity
FILE_PATH="${1:-}"

log_phase "post-write-validate-wikilinks" "start"

if [[ -z "$FILE_PATH" ]]; then
    log_conditional WARN "No file path provided to hook"
    echo "[WARN] Wikilink Validation: No file path provided to hook" >&2
    exit 0
fi

log_conditional DEBUG "Validating: $FILE_PATH"

# Extract project path by finding directory with .metadata/entity-index.json
PROJECT_PATH=""

# Try realpath first for canonical paths
if command -v realpath &> /dev/null; then
    PROJECT_PATH="$(realpath "$(dirname "$FILE_PATH")/.." 2>/dev/null || echo "")"
fi

# Fall back to existing regex if realpath failed or unavailable
if [[ -z "$PROJECT_PATH" ]]; then
    # Try multiple path patterns
    if [[ "$FILE_PATH" =~ (.*research-projects/[^/]+) ]]; then
        # Standard research-projects/{project-name} structure
        PROJECT_PATH="${BASH_REMATCH[1]}"
    elif [[ -f "$(dirname "$FILE_PATH")/../.metadata/entity-index.json" ]]; then
        # File is in entity directory (e.g., 04-findings/), project is parent
        PROJECT_PATH="$(cd "$(dirname "$FILE_PATH")/.." && pwd)"
    elif [[ -f "$(dirname "$FILE_PATH")/../../.metadata/entity-index.json" ]]; then
        # File is in sprint subdirectory, project is grandparent
        PROJECT_PATH="$(cd "$(dirname "$FILE_PATH")/../.." && pwd)"
    else
        # Not a deeper-research project, skip validation
        exit 0
    fi
fi

# Skip validation for non-markdown files
if [[ ! "$FILE_PATH" =~ \.(md|markdown)$ ]]; then
    exit 0
fi

# Skip validation for non-entity directories
# Only validate files in entity directories: findings, claims, megatrends, sources, authors, institutions, citations, synthesis
if [[ ! "$FILE_PATH" =~ (findings|claims|megatrends|sources|authors|institutions|citations|synthesis|dimensions|questions|batches)/ ]]; then
    exit 0
fi

# Check if entity-index.json exists (confirms this is a deeper-research project)
if [[ ! -f "$PROJECT_PATH/.metadata/entity-index.json" ]]; then
    echo "[WARN] Wikilink Validation: Not a deeper-research project (no entity-index.json)" >&2
    exit 0
fi

# Determine script location (relative to plugin root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATION_SCRIPT="$PLUGIN_ROOT/scripts/validate-wikilinks.sh"

# Fallback: Try CLAUDE_PLUGIN_ROOT if script not found
if [[ ! -f "$VALIDATION_SCRIPT" ]] && [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    VALIDATION_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/validate-wikilinks.sh"
fi

# Check if validation script exists
if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    echo "[WARN] Wikilink Validation: validate-wikilinks.sh not found at $VALIDATION_SCRIPT" >&2
    echo "Skipping validation (install deeper-research plugin properly)" >&2
    exit 0
fi

# Sanitize PROJECT_PATH
PROJECT_PATH="$(echo "$PROJECT_PATH" | tr -d '\r\n\t')"

# Run centralized validation script
result="$(bash "$VALIDATION_SCRIPT" --project-path "$PROJECT_PATH" --json 2>&1 || true)"

# Parse JSON results
success="$(echo "$result" | jq -r '.success // false' 2>/dev/null || echo "false")"
broken_count="$(echo "$result" | jq -r '.broken_count // 0' 2>/dev/null || echo "0")"

# Check for validation errors
log_metric "broken_wikilinks" "$broken_count" "count"

if [[ "$success" == "false" ]] && [[ "$broken_count" -gt 0 ]]; then
    log_conditional ERROR "Wikilink Validation: $broken_count broken wikilinks detected"
    echo "" >&2
    echo "[ERROR] Wikilink Validation: $broken_count broken wikilinks detected" >&2
    echo "" >&2
    echo "Broken links in $FILE_PATH:" >&2

    # Extract and display broken links with categories
    echo "$result" | jq -r '.broken_links[] | "  - [[\(.link)]] → \(.category): \(.suggested_fix // "entity not found")"' 2>/dev/null || \
    echo "$result" | jq -r '.broken_links[] | "  - [[\(.link)]]"' 2>/dev/null || \
    echo "  (Unable to parse broken links)" >&2

    echo "" >&2

    # Analyze file for specific common issues
    if grep -q '\\]]' "$FILE_PATH"; then
        echo "⚠️  TRAILING BACKSLASH DETECTED:" >&2
        echo "    Found wikilinks ending with \\]] instead of ]]" >&2
        echo "    Cause: LLM JSON escaping artifact during generation" >&2
        echo "    Fix: Remove all \\ before ]] in wikilinks" >&2
        echo "" >&2
    fi

    if grep -q ' ]]' "$FILE_PATH"; then
        echo "⚠️  TRAILING SPACE DETECTED:" >&2
        echo "    Found wikilinks with space before ]]" >&2
        echo "    Cause: Formatting artifact during generation" >&2
        echo "    Fix: Remove spaces before ]] in wikilinks" >&2
        echo "" >&2
    fi

    if grep -q '\.md]]' "$FILE_PATH"; then
        echo "⚠️  .MD EXTENSION DETECTED:" >&2
        echo "    Found wikilinks ending with .md]]" >&2
        echo "    Cause: Path completion artifact during generation" >&2
        echo "    Fix: Remove .md before ]] in wikilinks" >&2
        echo "" >&2
    fi

    echo "This indicates hallucinated or malformed entity references." >&2
    echo "" >&2
    echo "Common fixes:" >&2
    echo "  1. Use actual entity IDs from .metadata/entity-index.json" >&2
    echo "  2. Add directory prefix for sources: [[${DIR_SOURCES}/data/source-xyz]]" >&2
    echo "  3. Add directory prefix for publishers: [[${DIR_PUBLISHERS}/data/publisher-xyz]]" >&2
    echo "  4. Remove trailing backslashes, spaces, or .md extensions" >&2
    echo "" >&2
    echo "Agent should read entity-index.json and use actual entity IDs." >&2
    log_phase "post-write-validate-wikilinks" "complete"
    exit 1
fi

# Success: Log validation passed
filename="$(basename "$FILE_PATH")"
total_links="$(echo "$result" | jq -r '.total_links // 0' 2>/dev/null || echo "?")"
log_conditional INFO "Wikilink validation passed: $filename ($total_links links)"
log_metric "total_links_validated" "$total_links" "count"
echo "✅ Wikilink validation passed: $filename ($total_links links validated)" >&2
log_phase "post-write-validate-wikilinks" "complete"
exit 0
