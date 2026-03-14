#!/usr/bin/env bash
set -euo pipefail
# generate-wikilink.sh
# Version: 1.4.0
# Purpose: Generate workspace-relative wikilinks for Obsidian multi-project support
# Category: utilities
#
# Usage:
#   generate-wikilink.sh --project-path <path> --entity-dir <name> --filename <name> [--display-name <text>] [--workspace-root <path>]
#
# Arguments:
#   --project-path <path>      Absolute path to project directory (required)
#   --entity-dir <name>        Entity directory name (e.g., "02-refined-questions") (required)
#   --filename <name>          Entity filename without .md extension (required)
#   --display-name <text>      Display text for wikilink (optional, uses pipe syntax: [[path|display]])
#   --workspace-root <path>    Vault root path (optional, auto-detected if omitted)
#
# Environment Variables (priority order):
#   PROJECT_AGENTS_OPS_ROOT    Workplace root (highest priority, set by workplace-manager)
#   OBSIDIAN_VAULT_ROOT        Vault root override (legacy compatibility)
#   (auto-detection)           Falls back to .obsidian directory traversal
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "wikilink": "[[workspace-prefix/entity-dir/filename]]",
#       "workspace_mode": "multi-project" | "single-project",
#       "workspace_root": "/path/to/vault"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success (both single-project and multi-project modes)
#   1 - Validation error (invalid paths, missing directories)
#   2 - Invalid arguments (missing required parameters)
#
# Example:
#   generate-wikilink.sh \
#     --project-path "/vault/cogni-research/project-name" \
#     --entity-dir "02-refined-questions" \
#     --filename "impl-q2"
#
# Returns:
#   {
#     "success": true,
#     "data": {
#       "wikilink": "[[cogni-research/project-name/02-refined-questions/data/question-impl-q2]]",
#       "workspace_mode": "multi-project",
#       "workspace_root": "/vault"
#     }
#   }
#
# Notes:
#   - Environment variable priority: PROJECT_AGENTS_OPS_ROOT → OBSIDIAN_VAULT_ROOT → .obsidian detection
#   - PROJECT_AGENTS_OPS_ROOT integrates with workplace-manager architecture (Sprint 286)
#   - Falls back to single-project mode if workspace root equals project path
#   - Multi-project mode includes full workspace-relative path
#   - Single-project mode omits workspace prefix
#
# Changelog:
# - v1.4.0: Fix: Always use project-relative wikilinks for internal project links
#           - Multi-project mode now uses same format as single-project mode
#           - Fixes broken source_id wikilinks that included unnecessary workspace prefix
#           - Example: [[07-sources/data/source-xxx]] instead of [[prefix/07-sources/data/source-xxx]]


# Source centralized entity config for DATA_SUBDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Auto-detect workspace root with priority hierarchy
detect_workspace_root() {
    local project_path="$1"

    # Priority 1: Canonical workplace root (workplace-manager integration)
    if [[ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]]; then
        echo "$PROJECT_AGENTS_OPS_ROOT"
        return 0
    fi

    # Priority 2: Legacy explicit override
    if [[ -n "${OBSIDIAN_VAULT_ROOT:-}" ]]; then
        echo "$OBSIDIAN_VAULT_ROOT"
        return 0
    fi

    # Priority 3: Auto-detection via .obsidian directory traversal
    local current_path="$project_path"
    while ! [[ "$current_path" == "/" ]]; do
        if [[ -d "$current_path/.obsidian" ]]; then
            echo "$current_path"
            return 0
        fi
        current_path="$(dirname "$current_path")"
    done

    # Priority 4: Fall back to project path (single-project mode)
    echo "$project_path"
}

# Main function
main() {
    # Initialize variables
    local project_path=""
    local entity_dir=""
    local filename=""
    local display_name=""
    local workspace_root=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --entity-dir)
                entity_dir="$2"
                shift 2
                ;;
            --filename)
                filename="$2"
                shift 2
                ;;
            --display-name)
                display_name="$2"
                shift 2
                ;;
            --workspace-root)
                workspace_root="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -n "$entity_dir" ]] || error_json "Missing required argument: --entity-dir" 2
    [[ -n "$filename" ]] || error_json "Missing required argument: --filename" 2

    # Validate project path exists
    [[ -d "$project_path" ]] || error_json "Project path does not exist: $project_path" 1

    # Auto-detect workspace root if not provided
    if [[ -z "$workspace_root" ]]; then
        workspace_root="$(detect_workspace_root "$project_path")"
    fi

    # Validate workspace root exists
    [[ -d "$workspace_root" ]] || error_json "Workspace root does not exist: $workspace_root" 1

    # Determine workspace mode and construct wikilink
    local workspace_mode
    local wikilink
    local workspace_prefix=""

    # Build display suffix if display_name is provided
    local display_suffix=""
    if [[ -n "$display_name" ]]; then
        display_suffix="|$display_name"
    fi

    if [[ "$project_path" == "$workspace_root" ]]; then
        # Single-project mode: project path equals workspace root
        workspace_mode="single-project"
        wikilink="[[$entity_dir/$DATA_SUBDIR/$filename$display_suffix]]"
    else
        # Multi-project mode: extract relative path from workspace root to project
        workspace_prefix="${project_path#$workspace_root/}"

        # Handle case where project_path doesn't start with workspace_root
        if [[ "$workspace_prefix" == "$project_path" ]]; then
            error_json "Project path must be within workspace root: project=$project_path, workspace=$workspace_root" 1
        fi

        workspace_mode="multi-project"
        wikilink="[[$entity_dir/$DATA_SUBDIR/$filename$display_suffix]]"
    fi

    # Success output with structured JSON
    jq -n \
        --arg wikilink "$wikilink" \
        --arg mode "$workspace_mode" \
        --arg root "$workspace_root" \
        '{
            success: true,
            data: {
                wikilink: $wikilink,
                workspace_mode: $mode,
                workspace_root: $root
            }
        }'
}

# Execute main function
main "$@"
