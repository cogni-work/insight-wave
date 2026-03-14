#!/usr/bin/env bash
set -euo pipefail
# citation-registry.sh
# Version: 1.1.0
# Category: utilities
# Purpose: Centralized citation management for synthesis documents
#
# Provides citation numbering, deduplication, and References section generation.
# Uses temporary JSON registry for tracking citations across document generation.
#
# Usage:
#   citation-registry.sh init --project-path <path> --document-name <name>
#   citation-registry.sh add --registry <path> --entity-id <id> --text <text> --path <path> --type <type> [--confidence <num>] [--source-id <id>]
#   citation-registry.sh get --registry <path> --entity-id <id>
#   citation-registry.sh generate --registry <path>
#   citation-registry.sh cleanup --registry <path>
#
# Output: JSON (for init, add, get) or markdown (for generate)
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Missing required argument
#   3 - Dependency not found (jq)
#   4 - File/registry error
#

# ============================================================================
# Entity Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source entity configuration for directory key resolution (required)
source "${SCRIPT_DIR}/../lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_SOURCES="$(get_directory_by_key "sources")"

# ============================================================================
# Error Handling
# ============================================================================

error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# ============================================================================
# Command: init
# Initialize empty citation registry
# ============================================================================

cmd_init() {
    local project_path=""
    local document_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --document-name)
                document_name="$2"
                shift 2
                ;;
            *)
                error_json "init: Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "init: Missing --project-path" 2
    [[ -n "$document_name" ]] || error_json "init: Missing --document-name" 2
    [[ -d "$project_path" ]] || error_json "init: Project path not found: $project_path" 4

    # Create registry file path
    local registry_path="/tmp/citation-registry-${document_name}-$$.json"

    # Initialize empty registry
    jq -n '{citations: {}, next_number: 1}' > "$registry_path" || \
        error_json "init: Failed to create registry file" 4

    # Return registry path
    jq -n --arg path "$registry_path" \
        '{success: true, data: {registry_path: $path}}'
}

# ============================================================================
# Command: add
# Add citation to registry, return citation number (deduplicates by entity_id)
# ============================================================================

cmd_add() {
    local registry_path=""
    local entity_id=""
    local entity_text=""
    local entity_path=""
    local entity_type=""
    local confidence=""
    local source_id=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --registry)
                registry_path="$2"
                shift 2
                ;;
            --entity-id)
                entity_id="$2"
                shift 2
                ;;
            --text)
                entity_text="$2"
                shift 2
                ;;
            --path)
                entity_path="$2"
                shift 2
                ;;
            --type)
                entity_type="$2"
                shift 2
                ;;
            --confidence)
                confidence="$2"
                shift 2
                ;;
            --source-id)
                source_id="$2"
    source_id="$(echo "$source_id" | tr -d '\r\t\n')"
                shift 2
                ;;
            *)
                error_json "add: Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$registry_path" ]] || error_json "add: Missing --registry" 2
    [[ -n "$entity_id" ]] || error_json "add: Missing --entity-id" 2
    [[ -n "$entity_text" ]] || error_json "add: Missing --text" 2
    [[ -n "$entity_path" ]] || error_json "add: Missing --path" 2
    [[ -n "$entity_type" ]] || error_json "add: Missing --type" 2
    [[ -f "$registry_path" ]] || error_json "add: Registry not found: $registry_path" 4

    # Check if entity already exists
    local existing_number
    existing_number="$(jq -r --arg id "$entity_id" \
        '.citations[$id].number // empty' "$registry_path" 2>/dev/null || echo "")"

    if [[ -n "$existing_number" ]]; then
        # Return existing number
        jq -n --argjson num "$existing_number" \
            '{success: true, data: {citation_number: $num, new: false}}'
        return 0
    fi

    # Get next number and increment
    local next_number
    next_number="$(jq -r '.next_number' "$registry_path")"

    # Build citation entry based on which optional fields are present
    local citation_entry
    if [[ -n "$confidence" && -n "$source_id" ]]; then
        # Both confidence and source_id
        citation_entry="$(jq -n \
            --argjson num "$next_number" \
            --arg text "$entity_text" \
            --arg path "$entity_path" \
            --arg type "$entity_type" \
            --arg conf "$confidence" \
            --arg src "$source_id" \
            '{
                number: $num,
                text: $text,
                path: $path,
                type: $type,
                confidence: ($conf | tonumber),
                source_id: $src
            }')"
    elif [[ -n "$confidence" ]]; then
        # Only confidence
        citation_entry="$(jq -n \
            --argjson num "$next_number" \
            --arg text "$entity_text" \
            --arg path "$entity_path" \
            --arg type "$entity_type" \
            --arg conf "$confidence" \
            '{
                number: $num,
                text: $text,
                path: $path,
                type: $type,
                confidence: ($conf | tonumber)
            }')"
    elif [[ -n "$source_id" ]]; then
        # Only source_id
        citation_entry="$(jq -n \
            --argjson num "$next_number" \
            --arg text "$entity_text" \
            --arg path "$entity_path" \
            --arg type "$entity_type" \
            --arg src "$source_id" \
            '{
                number: $num,
                text: $text,
                path: $path,
                type: $type,
                source_id: $src
            }')"
    else
        # Neither optional field
        citation_entry="$(jq -n \
            --argjson num "$next_number" \
            --arg text "$entity_text" \
            --arg path "$entity_path" \
            --arg type "$entity_type" \
            '{
                number: $num,
                text: $text,
                path: $path,
                type: $type
            }')"
    fi

    # Update registry (atomic write)
    local temp_file="${registry_path}.tmp.$$"
    jq --arg id "$entity_id" \
       --argjson entry "$citation_entry" \
       --argjson next_num "$((next_number + 1))" \
       '.citations[$id] = $entry | .next_number = $next_num' \
       "$registry_path" > "$temp_file" || \
        error_json "add: Failed to update registry" 4

    mv "$temp_file" "$registry_path" || \
        error_json "add: Failed to save registry" 4

    # Return citation number
    jq -n --argjson num "$next_number" \
        '{success: true, data: {citation_number: $num, new: true}}'
}

# ============================================================================
# Command: get
# Lookup existing citation number by entity_id
# ============================================================================

cmd_get() {
    local registry_path=""
    local entity_id=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --registry)
                registry_path="$2"
                shift 2
                ;;
            --entity-id)
                entity_id="$2"
                shift 2
                ;;
            *)
                error_json "get: Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$registry_path" ]] || error_json "get: Missing --registry" 2
    [[ -n "$entity_id" ]] || error_json "get: Missing --entity-id" 2
    [[ -f "$registry_path" ]] || error_json "get: Registry not found: $registry_path" 4

    # Lookup citation number
    local citation_number
    citation_number="$(jq -r --arg id "$entity_id" \
        '.citations[$id].number // empty' "$registry_path" 2>/dev/null || echo "")"

    if [[ -n "$citation_number" ]]; then
        jq -n --argjson num "$citation_number" --arg id "$entity_id" \
            '{success: true, data: {citation_number: $num, entity_id: $id, found: true}}'
    else
        jq -n --arg id "$entity_id" \
            '{success: true, data: {citation_number: null, entity_id: $id, found: false}}'
    fi
}

# ============================================================================
# Command: generate
# Generate markdown References section from registry
# ============================================================================

cmd_generate() {
    local registry_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --registry)
                registry_path="$2"
                shift 2
                ;;
            *)
                error_json "generate: Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$registry_path" ]] || error_json "generate: Missing --registry" 2
    [[ -f "$registry_path" ]] || error_json "generate: Registry not found: $registry_path" 4

    # Extract and sort citations by number
    local citations_json
    citations_json="$(jq -r '
        .citations |
        to_entries |
        map({
            id: .key,
            number: .value.number,
            text: .value.text,
            path: .value.path,
            type: .value.type,
            confidence: .value.confidence,
            source_id: .value.source_id
        }) |
        sort_by(.number)
    ' "$registry_path")"

    # Check if there are any citations
    local count
    count="$(echo "$citations_json" | jq 'length')"

    if [[ "$count" -eq 0 ]]; then
        echo ""
        return 0
    fi

    # Generate markdown
    echo ""
    echo "---"
    echo ""
    echo "## References"
    echo ""

    # Iterate over citations and format based on what fields are present
    echo "$citations_json" | jq -r --arg sources_dir "$DIR_SOURCES" '.[] |
        if .confidence and .source_id then
            "\(.number). [\(.text)](\(.path)) - Source: [[\($sources_dir)/\(.source_id)]] - Confidence: \(.confidence)"
        elif .confidence then
            "\(.number). [\(.text)](\(.path)) - Confidence: \(.confidence)"
        elif .source_id then
            "\(.number). [\(.text)](\(.path)) - Source: [[\($sources_dir)/\(.source_id)]]"
        else
            "\(.number). [\(.text)](\(.path)]"
        end
    '
}

# ============================================================================
# Command: cleanup
# Remove temporary registry file
# ============================================================================

cmd_cleanup() {
    local registry_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --registry)
                registry_path="$2"
                shift 2
                ;;
            *)
                error_json "cleanup: Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$registry_path" ]] || error_json "cleanup: Missing --registry" 2

    # Remove registry file if it exists
    if [[ -f "$registry_path" ]]; then
        rm -f "$registry_path" || \
            error_json "cleanup: Failed to remove registry file" 4
    fi

    jq -n --arg path "$registry_path" \
        '{success: true, data: {message: "Registry cleaned up", registry_path: $path}}'
}

# ============================================================================
# Main Command Dispatcher
# ============================================================================

main() {
    # Check for jq dependency
    if ! command -v jq &>/dev/null; then
        error_json "jq not found, please install jq" 3
    fi

    # Require command argument
    [[ $# -ge 1 ]] || error_json "Usage: $0 <command> [options]
Commands: init, add, get, generate, cleanup" 2

    local command="$1"
    shift

    case "$command" in
        init)
            cmd_init "$@"
            ;;
        add)
            cmd_add "$@"
            ;;
        get)
            cmd_get "$@"
            ;;
        generate)
            cmd_generate "$@"
            ;;
        cleanup)
            cmd_cleanup "$@"
            ;;
        *)
            error_json "Unknown command: $command. Valid commands: init, add, get, generate, cleanup" 2
            ;;
    esac
}

main "$@"
