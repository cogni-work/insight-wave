#!/usr/bin/env bash
set -euo pipefail
# validate-workspace-wikilinks.sh
# Version: 2.0.0
# Event: PreToolUse
# Purpose: Detect and reject bare filename wikilinks in multi-project Obsidian workspaces
#
# Usage:
#   validate-workspace-wikilinks.sh
#
# Description:
#   PreToolUse hook that validates wikilinks in entity files to prevent ambiguous
#   bare filename references in multi-project Obsidian workspaces. Extracts all
#   wikilinks, detects workspace mode (single vs multi-project), and validates
#   patterns based on mode.
#
# Validation Rules:
#   Multi-Project Mode:
#     REJECT: Bare filename patterns [[impl-q2]], [[query-batch-economic]]
#     ACCEPT: Workspace-relative [[cogni-research/project/02-refined-questions/impl-q2]]
#     ACCEPT: Project-relative with directory [[02-refined-questions/data/question-impl-q2]] (minimum)
#
#   Single-Project Mode:
#     ACCEPT: All wikilink patterns (backward compatibility)
#
# Environment Variables:
#   CLAUDE_TOOL_INPUT    JSON with file_path parameter
#   CLAUDE_PROJECT_DIR   Project root directory
#   DEBUG_MODE           Enable debug logging (true/false, default: false)
#   DEBUG_LEVEL          Logging level: INFO, DEBUG, TRACE (default: INFO)
#
# Exit codes:
#   0 - Valid wikilinks or single-project mode
#   1 - Validation failure (bare filename wikilinks detected)
#
# Example:
#   CLAUDE_TOOL_INPUT='{"file_path":"project/02-refined-questions/impl-q2.md"}' \
#   CLAUDE_PROJECT_DIR="/Users/user/workspace" \
#   ./validate-workspace-wikilinks.sh


# ============================================================================
# Enhanced Logging Integration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source enhanced-logging.sh if available
if [[ -f "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh" ]]; then
    source "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh"
else
    # Fallback logging functions
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
    log_phase() { log_conditional "PHASE" "$1 [$2]"; }
    log_metric() { log_conditional "METRIC" "$1=$2 unit=$3"; }
fi

# Error output function
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log_conditional ERROR "$message"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Extract file path from hook environment
extract_file_path() {
    local file_path
    file_path="$(echo "${CLAUDE_TOOL_INPUT:-}" | jq -r '.file_path // empty' 2>/dev/null || echo "")"
    echo "$file_path"
}

# Detect workspace mode (single vs multi-project)
detect_workspace_mode() {
    local project_dir="${CLAUDE_PROJECT_DIR:-}"

    # Check if .claude directory exists (indicates Claude Code workspace)
    if [[ ! -d "$project_dir/.claude" ]]; then
        echo "single"
        return
    fi

    # Check if .claude/plugins/marketplaces exists (multi-project structure)
    if [[ -d "$project_dir/.claude/plugins/marketplaces" ]]; then
        # Count plugin directories (plugins with numbered prefixes indicate multi-project)
        local plugin_count
        plugin_count="$(find "$project_dir/.claude/plugins/marketplaces" -mindepth 1 -maxdepth 1 -type d -name "[0-9]*-*" 2>/dev/null | wc -l | tr -d ' ')"

        if [[ "$plugin_count" -gt 1 ]]; then
            echo "multi"
            return
        fi
    fi

    # Default to single-project mode
    echo "single"
}

# Extract all wikilinks from file
extract_wikilinks() {
    local file_path="$1"
    # Parallel arrays for wikilinks and line numbers (bash 3.2 compatible)
    local -a wikilinks=()
    local -a line_numbers=()

    # Read file line by line and extract wikilinks with line numbers
    local line_num=0
    while IFS= read -r line; do
        line="$(echo "$line" | tr -d '\r')"
        line_num=$((line_num + 1))

        # Extract all wikilinks from this line using grep
        # Pattern: [[...]] where content doesn't contain ]
        if echo "$line" | grep -o '\[\[[^]]\+\]\]' >/dev/null 2>&1; then
            # Extract each wikilink from the line
            while [[ "$line" =~ \[\[([^]]+)\]\] ]]; do
                local wikilink="${BASH_REMATCH[1]}"
                wikilinks+=("$wikilink")
                line_numbers+=("$line_num")
                # Remove matched portion to find next wikilink
                line="${line#*\[\[${wikilink}\]\]}"
            done
        fi
    done < "$file_path"

    # Return parallel arrays as JSON
    if [[ ${#wikilinks[@]} -eq 0 ]]; then
        echo '{"wikilinks":[],"line_numbers":[]}'
        return
    fi

    local wikilinks_json
    local line_numbers_json
    wikilinks_json="$(printf '%s\n' "${wikilinks[@]}" | jq -R . | jq -s .)"
    line_numbers_json="$(printf '%s\n' "${line_numbers[@]}" | jq -s 'map(tonumber)')"

    jq -n \
        --argjson wikilinks "$wikilinks_json" \
        --argjson line_numbers "$line_numbers_json" \
        '{wikilinks: $wikilinks, line_numbers: $line_numbers}'
}

# Normalize wikilink (remove display text and anchors)
normalize_wikilink() {
    local wikilink="$1"

    # Remove display text: [[path|Display]] -> path
    wikilink="${wikilink%%|*}"

    # Remove anchor: [[path#section]] -> path
    wikilink="${wikilink%%#*}"

    echo "$wikilink"
}

# Validate wikilink pattern
is_bare_filename() {
    local wikilink="$1"

    # Normalize wikilink
    wikilink="$(normalize_wikilink "$wikilink")"

    # Bare filename pattern: contains NO directory separator (/)
    # Examples: impl-q2, query-batch-economic
    if ! [[ "$wikilink" == */* ]]; then
        return 0  # Is bare filename
    fi

    return 1  # Has directory structure
}

# Main validation logic
main() {
    log_phase "validate-workspace-wikilinks" "start"

    # Extract file path from environment
    local file_path
    file_path="$(extract_file_path)"

    # Skip validation if no file path (not a file operation)
    if [[ -z "$file_path" ]]; then
        log_conditional DEBUG "No file path, skipping"
        exit 0
    fi

    log_conditional DEBUG "Validating: $file_path"

    # Skip validation if file doesn't exist yet (PreToolUse for new files)
    if [[ ! -f "$file_path" ]]; then
        exit 0
    fi

    # Skip validation for non-markdown files
    if [[ ! "$file_path" =~ \.md$ ]]; then
        exit 0
    fi

    # Detect workspace mode
    local workspace_mode
    workspace_mode="$(detect_workspace_mode)"

    # Skip validation in single-project mode (backward compatibility)
    if [[ "$workspace_mode" = "single" ]]; then
        exit 0
    fi

    # Extract wikilinks from file
    local wikilinks_data
    wikilinks_data="$(extract_wikilinks "$file_path")"

    local wikilinks_json
    local line_numbers_json
    wikilinks_json="$(echo "$wikilinks_data" | jq -r '.wikilinks[]' 2>/dev/null || echo "")"
    line_numbers_json="$(echo "$wikilinks_data" | jq -r '.line_numbers[]' 2>/dev/null || echo "")"

    # If no wikilinks, validation passes
    if [[ -z "$wikilinks_json" ]]; then
        exit 0
    fi

    # Check for bare filename wikilinks
    local -a bare_wikilinks=()
    local -a bare_line_numbers=()
    local idx=0

    while IFS= read -r wikilink && IFS= read -r line_num <&3; do
        if is_bare_filename "$wikilink"; then
            bare_wikilinks+=("$wikilink")
            bare_line_numbers+=("$line_num")
        fi
        idx=$((idx + 1))
    done < <(echo "$wikilinks_json") 3< <(echo "$line_numbers_json")

    # If bare filename wikilinks found, report error
    if [[ ${#bare_wikilinks[@]} -gt 0 ]]; then
        echo "" >&2
        echo "ERROR: Ambiguous wikilinks detected in multi-project workspace" >&2
        echo "" >&2
        echo "Bare filename wikilinks found:" >&2

        for i in "${!bare_wikilinks[@]}"; do
            echo "  - [[${bare_wikilinks[$i]}]] (line ${bare_line_numbers[$i]})" >&2
        done

        echo "" >&2
        echo "In multi-project Obsidian workspaces, wikilinks must include full workspace-relative paths." >&2
        echo "" >&2
        echo "Expected format:" >&2
        echo "  [[cogni-research/project-name/02-refined-questions/data/question-impl-q2]]" >&2
        echo "" >&2
        echo "Minimum format (project-relative):" >&2
        echo "  [[02-refined-questions/data/question-impl-q2]]" >&2
        echo "" >&2
        echo "Please regenerate the entity with workspace-aware wikilinks." >&2
        echo "" >&2

        exit 1
    fi

    # All wikilinks valid
    log_conditional INFO "All wikilinks valid"
    log_phase "validate-workspace-wikilinks" "complete"
    exit 0
}

main "$@"
