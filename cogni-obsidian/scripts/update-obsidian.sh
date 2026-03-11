#!/usr/bin/env bash
set -euo pipefail
# update-obsidian.sh
# Version: 2.0.0
# Plugin: cogni-obsidian
# Purpose: Incrementally update Obsidian terminal configurations in existing workplaces
#
# Usage: update-obsidian.sh <workplace-dir> [--dry-run]
#
# Arguments:
#   workplace-dir    <path>    Absolute path to workplace directory (required)
#   --dry-run                  Preview changes without modifying files (optional)
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - Update operation failed

# Source portability utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../bash/portability-utils.sh
source "${SCRIPT_DIR}/../bash/portability-utils.sh"

PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

error_json() {
    local message="$1"
    local code="${2:-1}"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    jq -n \
        --arg msg "$message" \
        --argjson code "$code" \
        --arg ts "$timestamp" \
        '{
            success: false,
            error: $msg,
            error_code: $code,
            metadata: {
                timestamp: $ts,
                script: "update-obsidian.sh",
                version: "2.0.0"
            }
        }' >&2
    exit "$code"
}

fix_doubled_paths() {
    local workplace_data="$1"
    local dry_run="$2"

    [[ -f "$workplace_data" ]] || return 0
    [[ "$dry_run" == "false" ]] || return 0

    if grep -q '/mnt/c/mnt/c/' "$workplace_data"; then
        local temp_file="${workplace_data}.tmp"
        sed 's|/mnt/c/mnt/c/|/mnt/c/|g' "$workplace_data" > "$temp_file"
        mv "$temp_file" "$workplace_data"
        echo "INFO: Fixed doubled /mnt/c/ paths in data.json" >&2
    fi
}

cleanup_deprecated_profiles() {
    local workplace_data="$1"
    local dry_run="$2"

    local deprecated_profiles=("workplace-windows" "project-agents-monitoring-windows")

    [[ -f "$workplace_data" ]] || return 0
    [[ "$dry_run" == "false" ]] || return 0

    local has_profiles_key
    has_profiles_key="$(jq -e '.profiles' "$workplace_data" &>/dev/null && echo "true" || echo "false")"

    for profile in "${deprecated_profiles[@]}"; do
        local exists
        if [[ "$has_profiles_key" == "true" ]]; then
            exists="$(jq -e --arg name "$profile" '.profiles[$name]' "$workplace_data" &>/dev/null && echo "true" || echo "false")"
            if [[ "$exists" == "true" ]]; then
                local temp_file="${workplace_data}.tmp"
                jq --arg name "$profile" 'del(.profiles[$name])' "$workplace_data" > "$temp_file"
                mv "$temp_file" "$workplace_data"
                echo "INFO: Removed deprecated profile: $profile" >&2
            fi
        else
            exists="$(jq -e --arg name "$profile" '.[$name]' "$workplace_data" &>/dev/null && echo "true" || echo "false")"
            if [[ "$exists" == "true" ]]; then
                local temp_file="${workplace_data}.tmp"
                jq --arg name "$profile" 'del(.[$name])' "$workplace_data" > "$temp_file"
                mv "$temp_file" "$workplace_data"
                echo "INFO: Removed deprecated profile: $profile" >&2
            fi
        fi
    done

    # Migrate defaultProfile if pointing to deprecated
    local current_default
    current_default="$(jq -r '.defaultProfile // ""' "$workplace_data")"
    local new_default=""
    case "$current_default" in
        "workplace-windows") new_default="workplace-wsl" ;;
        "project-agents-monitoring-windows") new_default="project-agents-monitoring-wsl" ;;
    esac
    if [[ -n "$new_default" ]]; then
        local temp_file="${workplace_data}.tmp"
        jq --arg profile "$new_default" '.defaultProfile = $profile' "$workplace_data" > "$temp_file"
        mv "$temp_file" "$workplace_data"
        echo "INFO: Migrated defaultProfile to '$new_default'" >&2
    fi
}

fix_wsl_profile_args() {
    local workplace_data="$1"
    local template_data="$2"
    local dry_run="$3"

    local wsl_profiles=("workplace-wsl")
    local fixed_profiles=()

    [[ -f "$workplace_data" ]] || { echo "[]"; return 0; }
    [[ "$dry_run" == "false" ]] || { echo "[]"; return 0; }

    local has_profiles_key
    has_profiles_key="$(jq -e '.profiles' "$workplace_data" &>/dev/null && echo "true" || echo "false")"

    for profile in "${wsl_profiles[@]}"; do
        local profile_path
        if [[ "$has_profiles_key" == "true" ]]; then
            profile_path=".profiles[\"$profile\"]"
        else
            profile_path=".[\"$profile\"]"
        fi

        local exists
        exists="$(jq -e "$profile_path" "$workplace_data" &>/dev/null && echo "true" || echo "false")"
        [[ "$exists" == "true" ]] || continue

        local needs_fix="false"

        local first_arg
        first_arg="$(jq -r "${profile_path}.args[0] // \"\"" "$workplace_data")"
        if [[ "$first_arg" == "--" ]]; then
            needs_fix="true"
        fi

        local has_conhost
        has_conhost="$(jq -e "${profile_path}.useWin32Conhost" "$workplace_data" &>/dev/null && echo "true" || echo "false")"
        if [[ "$has_conhost" == "false" ]]; then
            needs_fix="true"
        fi

        if [[ "$needs_fix" == "true" ]]; then
            fixed_profiles+=("$profile")

            local template_args
            template_args="$(jq ".profiles[\"$profile\"].args" "$template_data")"

            local temp_file="${workplace_data}.tmp"
            jq --argjson new_args "$template_args" \
                "${profile_path}.args = \$new_args | ${profile_path}.useWin32Conhost = true" \
                "$workplace_data" > "$temp_file"
            mv "$temp_file" "$workplace_data"
            echo "INFO: Fixed WSL profile: $profile" >&2
        fi
    done

    if [[ ${#fixed_profiles[@]} -gt 0 ]]; then
        printf '%s\n' "${fixed_profiles[@]}" | jq -R . | jq -s .
    else
        echo "[]"
    fi
}

validate_json_file() {
    local file_path="$1"
    [[ -f "$file_path" ]] || error_json "JSON file not found: $file_path" 1
    if ! jq . "$file_path" &>/dev/null; then
        error_json "Invalid JSON syntax in: $file_path" 1
    fi
}

get_new_profiles() {
    local template_data="$1"
    local workplace_data="$2"

    local template_profiles
    template_profiles="$(jq -r '.profiles | keys[]' "$template_data" 2>/dev/null || echo "")"

    local has_profiles_key
    has_profiles_key="$(jq -e '.profiles' "$workplace_data" &>/dev/null && echo "true" || echo "false")"

    local new_profiles=()
    while IFS= read -r profile_name; do
        [[ -z "$profile_name" ]] && continue
        local exists
        if [[ "$has_profiles_key" == "true" ]]; then
            exists="$(jq -e --arg name "$profile_name" '.profiles[$name]' "$workplace_data" &>/dev/null && echo "true" || echo "false")"
        else
            exists="$(jq -e --arg name "$profile_name" '.[$name]' "$workplace_data" &>/dev/null && echo "true" || echo "false")"
        fi
        if [[ "$exists" == "false" ]]; then
            new_profiles+=("$profile_name")
        fi
    done <<< "$template_profiles"

    if [[ ${#new_profiles[@]} -gt 0 ]]; then
        printf '%s\n' "${new_profiles[@]}"
    fi
}

merge_profiles() {
    local template_data="$1"
    local workplace_data="$2"
    local dry_run="$3"
    local workplace_root="$4"

    local new_profiles_list
    new_profiles_list="$(get_new_profiles "$template_data" "$workplace_data")"
    [[ -z "$new_profiles_list" ]] && echo "[]" && return 0

    local has_profiles_key
    has_profiles_key="$(jq -e '.profiles' "$workplace_data" &>/dev/null && echo "true" || echo "false")"

    local merge_filter
    if [[ "$has_profiles_key" == "true" ]]; then
        merge_filter='.profiles'
        while IFS= read -r profile_name; do
            [[ -z "$profile_name" ]] && continue
            merge_filter="$merge_filter | .\"$profile_name\" = \$template.profiles.\"$profile_name\""
        done <<< "$new_profiles_list"
    else
        merge_filter='.'
        while IFS= read -r profile_name; do
            [[ -z "$profile_name" ]] && continue
            merge_filter="$merge_filter | .\"$profile_name\" = \$template.profiles.\"$profile_name\""
        done <<< "$new_profiles_list"
    fi

    if [[ "$dry_run" == "false" ]]; then
        local merged_json
        merged_json="$(jq --slurpfile template_content "$template_data" \
            --argjson template "$(jq . "$template_data")" \
            "$merge_filter" "$workplace_data")"

        local workplace_root_normalized="${workplace_root//\\//}"
        local workplace_root_wsl
        workplace_root_wsl="$(portable_wsl_path "$workplace_root")"
        merged_json="$(echo "$merged_json" | sed -e "s|{{WORKPLACE_ROOT}}|$workplace_root_normalized|g" -e "s|{{WORKPLACE_ROOT_WSL}}|$workplace_root_wsl|g")"

        echo "$merged_json" > "$workplace_data" || error_json "Failed to write merged profiles" 3
    fi

    printf '%s\n' "$new_profiles_list" | jq -R . | jq -s .
}

copy_and_substitute_scripts() {
    local template_dir="$1"
    local workplace_dir="$2"
    local workplace_root="$3"
    local dry_run="$4"

    local terminal_dir="$workplace_dir/.obsidian/plugins/terminal"
    local new_scripts=()

    while IFS= read -r script_file; do
        [[ -z "$script_file" ]] && continue
        local script_name
        script_name="$(basename "$script_file")"
        if [[ ! -f "$terminal_dir/$script_name" ]]; then
            new_scripts+=("$script_name")
            if [[ "$dry_run" == "false" ]]; then
                local workplace_root_normalized="${workplace_root//\\//}"
                local workplace_root_wsl
                workplace_root_wsl="$(portable_wsl_path "$workplace_root")"
                sed -e "s|{{WORKPLACE_ROOT}}|$workplace_root_normalized|g" \
                    -e "s|{{WORKPLACE_ROOT_WSL}}|$workplace_root_wsl|g" \
                    "$script_file" > "$terminal_dir/$script_name" || \
                    error_json "Failed to copy script: $script_name" 3
            fi
        fi
    done < <(find "$template_dir" -maxdepth 1 -name "*.sh" -type f)

    if [[ ${#new_scripts[@]} -gt 0 ]]; then
        printf '%s\n' "${new_scripts[@]}" | jq -R . | jq -s .
    else
        echo "[]"
    fi
}

make_scripts_executable() {
    local terminal_dir="$1"
    local dry_run="$2"

    [[ "$dry_run" == "false" ]] || return 0

    while IFS= read -r script_file; do
        [[ -z "$script_file" ]] && continue
        chmod +x "$script_file" 2>/dev/null || true
    done < <(find "$terminal_dir" -maxdepth 1 -name "*.sh" -type f)
}

main() {
    local workplace_dir="${1:-}"
    local dry_run="false"

    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    [[ -n "$workplace_dir" ]] || error_json "Usage: $0 <workplace-dir> [--dry-run]" 2
    workplace_dir="$(cd "$workplace_dir" 2>/dev/null && pwd)" || error_json "Cannot access: $workplace_dir" 1

    # Locate template from plugin root
    local template_dir="${PLUGIN_ROOT}/skills/setup-obsidian/templates/obsidian/plugins/terminal"
    local template_data="$template_dir/data.json"
    local workplace_terminal_dir="$workplace_dir/.obsidian/plugins/terminal"
    local workplace_data="$workplace_terminal_dir/data.json"

    [[ -d "$template_dir" ]] || error_json "Template directory not found: $template_dir" 1
    [[ -f "$template_data" ]] || error_json "Template data.json not found: $template_data" 1
    validate_json_file "$template_data"

    local profiles_added="[]"
    local profiles_fixed="[]"
    local scripts_copied="[]"

    if [[ -d "$workplace_terminal_dir" ]] && [[ -f "$workplace_data" ]]; then
        validate_json_file "$workplace_data"
        fix_doubled_paths "$workplace_data" "$dry_run"
        profiles_added="$(merge_profiles "$template_data" "$workplace_data" "$dry_run" "$workplace_dir")"
        cleanup_deprecated_profiles "$workplace_data" "$dry_run"
        profiles_fixed="$(fix_wsl_profile_args "$workplace_data" "$template_data" "$dry_run")"
        scripts_copied="$(copy_and_substitute_scripts "$template_dir" "$workplace_dir" "$workplace_dir" "$dry_run")"
        make_scripts_executable "$workplace_terminal_dir" "$dry_run"
    fi

    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    jq -n \
        --arg workplace "$workplace_dir" \
        --argjson profiles "$profiles_added" \
        --argjson fixed "$profiles_fixed" \
        --argjson scripts "$scripts_copied" \
        --argjson dry_run "$([[ "$dry_run" == "true" ]] && echo true || echo false)" \
        --arg ts "$timestamp" \
        '{
            success: true,
            data: {
                workplace_dir: $workplace,
                profiles_added: $profiles,
                profiles_fixed: $fixed,
                scripts_copied: $scripts,
                dry_run: $dry_run
            },
            metadata: {
                timestamp: $ts,
                script: "update-obsidian.sh",
                version: "2.0.0"
            }
        }'
}

main "$@"
