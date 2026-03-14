#!/usr/bin/env bash
set -euo pipefail
# entity-config.sh
# Version: 1.1.0
# Purpose: Bash interface to centralized entity schema configuration
# Category: lib
#
# Provides functions to read entity configuration from the central
# JSON config file (entity-schema.json) using jq.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/entity-config.sh"
#   # Bash 3.2 compatible array loading (mapfile requires Bash 4.0+):
#   ENTITY_DIRS=()
#   while IFS= read -r dir; do
#       ENTITY_DIRS+=("$dir")
#   done < <(get_entity_dirs_array)
#
# Functions:
#   get_config_path()         - Get path to entity-schema.json
#   get_entity_dirs_array()   - Echo directory names (one per line)
#   get_entity_prefix()       - Get prefix for entity type
#   get_data_subdir()         - Get data subdirectory name
#   needs_deduplication()     - Check if type needs dedup (exit 0/1)
#   get_schema_version()      - Get schema version string
#   get_special_directories() - Echo special directory names
#   get_directory_by_key()    - Resolve key to directory name
#   get_key_by_directory()    - Resolve directory to key
#   get_all_key_mappings()    - Get all key→directory mappings as JSON
#   resolve_entity_vars()     - Resolve {{key}} placeholders in strings
#
# Exit codes:
#   0 - Success (functions return normally)
#   1 - Error (jq not found, config file not found, or invalid input)


# Resolve config path - 3-strategy resolution with validation
_get_config_path() {
    local config_path

    # Strategy 1: CLAUDE_PLUGIN_ROOT env var (most reliable when set by runtime)
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        # Handle monorepo case where root may not include plugin subdir
        if [[ -f "${CLAUDE_PLUGIN_ROOT}/config/entity-schema.json" ]]; then
            config_path="${CLAUDE_PLUGIN_ROOT}/config/entity-schema.json"
        # CLAUDE_PLUGIN_ROOT points directly to plugin root in flat structure
        fi
    fi

    # Strategy 2: BASH_SOURCE with canonicalization + validation
    if [[ -z "${config_path:-}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
        # Canonicalize: resolve ../../ to absolute path before checking
        local candidate_root
        candidate_root="$(cd "${script_dir}/../.." 2>/dev/null && pwd)" || true
        if [[ -n "$candidate_root" ]] && [[ -f "${candidate_root}/config/entity-schema.json" ]]; then
            config_path="${candidate_root}/config/entity-schema.json"
        fi
    fi

    # Strategy 3: Search plugin cache (last resort)
    if [[ -z "${config_path:-}" ]]; then
        local cache_dir="$HOME/.claude/plugins/cache/cogni-research"
        if [[ -d "$cache_dir" ]]; then
            local found
            found="$(find "$cache_dir" -name "entity-schema.json" -path "*/config/*" -type f 2>/dev/null | head -1)"
            if [[ -n "${found:-}" ]]; then
                config_path="$found"
            fi
        fi
    fi

    echo "${config_path:-}"
}

# Verify jq is available
_require_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed" >&2
        return 1
    fi
}

# Get path to entity-schema.json
get_config_path() {
    local config_path
    config_path="$(_get_config_path)"
    if [[ ! -f "$config_path" ]]; then
        echo "ERROR: Entity schema config not found: $config_path" >&2
        return 1
    fi
    echo "$config_path"
}

# Load entity directories as newline-separated output
# Usage (Bash 3.2 compatible):
#   ENTITY_DIRS=()
#   while IFS= read -r dir; do ENTITY_DIRS+=("$dir"); done < <(get_entity_dirs_array)
get_entity_dirs_array() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r '.entity_types[].directory' "$config_path"
}

# Get prefix for entity type
# Usage: prefix=$(get_entity_prefix "04-findings")
get_entity_prefix() {
    local entity_type="$1"
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r --arg type "$entity_type" \
        '.entity_types[] | select(.directory == $type) | .prefix' \
        "$config_path"
}

# Get data subdirectory name (typically "data")
get_data_subdir() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r '.entity_types[0].data_subdir // "data"' "$config_path"
}

# Check if entity type requires deduplication
# Usage: if needs_deduplication "05-sources"; then ...
needs_deduplication() {
    local entity_type="$1"
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -e --arg type "$entity_type" \
        '.entity_types[] | select(.directory == $type) | .dedupe' \
        "$config_path" > /dev/null 2>&1
}

# Get schema version
get_schema_version() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r '.version' "$config_path"
}

# Get special directories (non-entity dirs like .metadata, .logs)
get_special_directories() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r '.special_directories[]' "$config_path"
}

# Get required fields for entity type (comma-separated)
get_required_fields() {
    local entity_type="$1"
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r --arg type "$entity_type" \
        '.entity_types[] | select(.directory == $type) | .required_fields | join(",")' \
        "$config_path"
}

# Get all entity types that require deduplication (newline-separated)
get_dedupe_types() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r '.entity_types[] | select(.dedupe == true) | .directory' "$config_path"
}

# Resolve entity key to directory name
# Usage: dir=$(get_directory_by_key "findings")
# Returns: "04-findings"
get_directory_by_key() {
    local key="$1"
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r --arg key "$key" \
        '.entity_types[] | select(.key == $key) | .directory' \
        "$config_path"
}

# Resolve directory name to entity key
# Usage: key=$(get_key_by_directory "04-findings")
# Returns: "findings"
get_key_by_directory() {
    local directory="$1"
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -r --arg dir "$directory" \
        '.entity_types[] | select(.directory == $dir) | .key' \
        "$config_path"
}

# Get all key-to-directory mappings as JSON
# Usage: mappings=$(get_all_key_mappings)
# Returns: {"findings":"04-findings","sources":"05-sources",...}
get_all_key_mappings() {
    _require_jq || return 1
    local config_path
    config_path="$(get_config_path)" || return 1
    jq -c '[.entity_types[] | {(.key): .directory}] | add' "$config_path"
}

# Resolve entity placeholders in a string
# Usage: resolved=$(resolve_entity_vars "List 04-findings/data/*.md")
# Returns: "List 04-findings/data/*.md"
resolve_entity_vars() {
    local template="$1"
    local result="$template"
    local mappings

    _require_jq || return 1
    mappings="$(get_all_key_mappings)" || return 1

    # Extract all {{key}} patterns and replace them
    local keys
    keys=$(echo "$template" | grep -oE '\{\{[a-z_-]+\}\}' | sed 's/[{}]//g' | sort -u) || true

    for key in $keys; do
        local replacement
        replacement=$(echo "$mappings" | jq -r --arg k "$key" '.[$k] // empty')
        if [[ -n "$replacement" ]]; then
            result="${result//\{\{${key}\}\}/${replacement}}"
        fi
    done

    echo "$result"
}
