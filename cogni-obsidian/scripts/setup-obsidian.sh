#!/usr/bin/env bash
set -euo pipefail
# setup-obsidian.sh
# Version: 3.0.0
# Plugin: cogni-obsidian
# Purpose: Configure portable Obsidian integration in user workspace with WSL support
#
# Usage:
#   setup-obsidian.sh <TARGET_DIR> [--dry-run]
#
# Arguments:
#   TARGET_DIR    Path to user's workspace directory (required)
#   --dry-run     Preview changes without modifying files (optional)
#   -h, --help    Show this help message
#
# Output (JSON):
#   {
#     "success": true|false,
#     "data": {
#       "configured": true,
#       "template_source": "/path/to/template",
#       "target": "/path/to/workspace/.obsidian",
#       "dry_run": false,
#       "warnings": []
#     },
#     "error": "error message if failed",
#     "metadata": {
#       "timestamp": "ISO 8601",
#       "script": "setup-obsidian.sh",
#       "version": "3.0.0"
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation failure
#   2 - Invalid arguments
#   3 - Template not found or dependency missing

SCRIPT_VERSION="3.0.0"
SCRIPT_NAME="setup-obsidian.sh"

# Source portability utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../bash/portability-utils.sh
source "${SCRIPT_DIR}/../bash/portability-utils.sh"

error_json() {
    local message="$1"
    local code="${2:-1}"

    jq -n \
        --arg msg "$message" \
        --argjson code "$code" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            success: false,
            error: $msg,
            error_code: $code,
            metadata: {
                timestamp: $timestamp,
                script: "setup-obsidian.sh",
                version: "3.0.0"
            }
        }' >&2
    exit "$code"
}

usage() {
    cat <<'EOF'
Usage: setup-obsidian.sh <TARGET_DIR> [OPTIONS]

Configure portable Obsidian integration in user workspace.

Arguments:
    TARGET_DIR    Path to user's workspace directory (required)

Options:
    --dry-run     Preview changes without modifying files
    -h, --help    Show this help message

Exit Codes:
    0 - Success
    1 - Validation failure
    2 - Invalid arguments
    3 - Template not found or dependency missing
EOF
}

parse_args() {
    TARGET_DIR=""
    DRY_RUN=false

    if [[ $# -eq 0 ]]; then
        usage
        exit 2
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error_json "Unknown option: $1" 2
                ;;
            *)
                if [[ -z "$TARGET_DIR" ]]; then
                    TARGET_DIR="$1"
                    shift
                else
                    error_json "Multiple target directories specified: $TARGET_DIR and $1" 2
                fi
                ;;
        esac
    done

    if [[ -z "$TARGET_DIR" ]]; then
        error_json "TARGET_DIR argument is required" 2
    fi
}

validate_inputs() {
    if ! command -v jq &> /dev/null; then
        error_json "Required dependency 'jq' not found" 3
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        error_json "Target directory does not exist: $TARGET_DIR" 1
    fi

    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

    # Locate template relative to this script (cogni-obsidian plugin)
    PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
    TEMPLATE_SOURCE="${PLUGIN_ROOT}/skills/obsidian-setup/templates/obsidian"

    if [[ ! -d "$TEMPLATE_SOURCE" ]]; then
        error_json "Obsidian template not found at: $TEMPLATE_SOURCE" 3
    fi

    TARGET_OBSIDIAN="${TARGET_DIR}/.obsidian"
}

check_existing_config() {
    if [[ -d "$TARGET_OBSIDIAN" ]]; then
        echo "WARN: Existing .obsidian directory found at: $TARGET_OBSIDIAN" >&2
        HAS_EXISTING=true
    else
        HAS_EXISTING=false
    fi
}

copy_obsidian_template() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: Would copy $TEMPLATE_SOURCE to $TARGET_OBSIDIAN" >&2
        return 0
    fi

    if [[ "$HAS_EXISTING" == "true" ]]; then
        echo "SKIP: Not overwriting existing .obsidian directory" >&2
        return 0
    fi

    if cp -r "$TEMPLATE_SOURCE" "$TARGET_OBSIDIAN" 2>/dev/null; then
        echo "SUCCESS: Copied Obsidian template to $TARGET_OBSIDIAN" >&2
    else
        error_json "Failed to copy template from $TEMPLATE_SOURCE to $TARGET_OBSIDIAN" 1
    fi
}

install_terminal_plugin() {
    local plugin_dir="${TARGET_OBSIDIAN}/plugins/terminal"
    local github_base="https://github.com/polyipseity/obsidian-terminal/releases/latest/download"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: Would download Terminal plugin from GitHub to $plugin_dir" >&2
        return 0
    fi

    if [[ "$HAS_EXISTING" == "true" ]]; then
        echo "SKIP: Not installing Terminal plugin (existing .obsidian directory)" >&2
        return 0
    fi

    mkdir -p "$plugin_dir"

    echo "INFO: Downloading Terminal plugin from GitHub..." >&2

    local files=("main.js" "manifest.json" "styles.css")
    local download_failed=false

    for file in "${files[@]}"; do
        local url="${github_base}/${file}"
        local target="${plugin_dir}/${file}"

        if curl -fsSL -o "$target" "$url" 2>/dev/null; then
            echo "  + Downloaded: $file" >&2
        else
            echo "  x Failed to download: $file" >&2
            download_failed=true
        fi
    done

    if [[ "$download_failed" == "true" ]]; then
        error_json "Failed to download some Terminal plugin files from GitHub" 1
    fi

    echo "SUCCESS: Terminal plugin installed" >&2
}

update_terminal_profile() {
    local terminal_data_path="${TARGET_OBSIDIAN}/plugins/terminal/data.json"
    local orchestrator_script="${TARGET_OBSIDIAN}/plugins/terminal/workplace-orchestrator.sh"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: Would update paths in terminal profile" >&2
        return 0
    fi

    if [[ "$HAS_EXISTING" == "true" ]]; then
        return 0
    fi

    local target_dir_normalized="${TARGET_DIR//\\//}"
    local target_dir_wsl
    target_dir_wsl="$(portable_wsl_path "$TARGET_DIR")"

    if [[ -f "$terminal_data_path" ]]; then
        local temp_file="${terminal_data_path}.tmp"
        sed -e "s|{{WORKPLACE_ROOT}}|${target_dir_normalized}|g" \
            -e "s|{{WORKPLACE_ROOT_WSL}}|${target_dir_wsl}|g" \
            "$terminal_data_path" > "$temp_file"
        mv "$temp_file" "$terminal_data_path"
        echo "SUCCESS: Updated terminal paths (native: $target_dir_normalized, WSL: $target_dir_wsl)" >&2
    else
        echo "WARN: Terminal data.json not found, skipping path updates" >&2
    fi

    if [[ -f "$orchestrator_script" ]]; then
        local temp_file="${orchestrator_script}.tmp"
        sed -e "s|{{WORKPLACE_ROOT}}|${target_dir_normalized}|g" \
            -e "s|{{WORKPLACE_ROOT_WSL}}|${target_dir_wsl}|g" \
            "$orchestrator_script" > "$temp_file"
        mv "$temp_file" "$orchestrator_script"
        chmod +x "$orchestrator_script" 2>/dev/null || true
        echo "SUCCESS: Updated orchestrator script" >&2
    fi
}

update_default_profile() {
    local terminal_data_path="${TARGET_OBSIDIAN}/plugins/terminal/data.json"

    if [[ "$DRY_RUN" == "true" ]] || [[ "$HAS_EXISTING" == "true" ]]; then
        return 0
    fi

    local default_profile="workplace"
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            default_profile="workplace-wsl"
            ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                default_profile="workplace-wsl"
            fi
            ;;
    esac

    if [[ -f "$terminal_data_path" ]]; then
        local temp_file="${terminal_data_path}.tmp"
        jq --arg profile "$default_profile" '.defaultProfile = $profile' "$terminal_data_path" > "$temp_file"
        mv "$temp_file" "$terminal_data_path"
        echo "SUCCESS: Default profile set to: $default_profile" >&2
    fi
}

build_warnings() {
    local warnings=""
    if [[ "$HAS_EXISTING" == "true" ]]; then
        warnings="existing .obsidian directory found (not overwritten)"
    fi
    echo "$warnings"
}

main() {
    parse_args "$@"
    validate_inputs
    check_existing_config
    copy_obsidian_template
    install_terminal_plugin
    update_terminal_profile
    update_default_profile

    local warnings
    warnings="$(build_warnings)"

    jq -n \
        --argjson configured true \
        --arg template_source "$TEMPLATE_SOURCE" \
        --arg target "$TARGET_OBSIDIAN" \
        --argjson dry_run "$DRY_RUN" \
        --arg warnings "$warnings" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            success: true,
            data: {
                configured: $configured,
                template_source: $template_source,
                target: $target,
                dry_run: $dry_run,
                warnings: (if $warnings == "" then [] else [$warnings] end)
            },
            metadata: {
                timestamp: $timestamp,
                script: "setup-obsidian.sh",
                version: "3.0.0"
            }
        }'
}

main "$@"
