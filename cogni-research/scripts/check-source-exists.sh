#!/usr/bin/env bash
set -euo pipefail
# check-source-exists.sh - Filesystem-based source duplicate detection
# Version: 1.0.0
# Purpose: Check if source with given URL already exists by scanning filesystem
#
# Usage:
#   check-source-exists.sh --project-path <path> --url <url> [--json]
#
# Arguments:
#   --project-path <path>    Research project directory (required)
#   --url <url>              URL to search for (required)
#   --json                   Return JSON response (optional, default: false)
#
# Output:
#   JSON format:
#   {
#     "success": true,
#     "exists": true|false,
#     "source_id": "source-abc123",        (if exists=true)
#     "source_path": "07-sources/...",     (if exists=true)
#     "url_matched": "https://example.com" (if exists=true)
#   }
#
# Exit codes:
#   0 - Always (detection, not validation)
#
# Dependencies:
#   - normalize-url.sh (same directory)
#
# Example:
#   check-source-exists.sh --project-path "/path/to/project" \
#     --url "https://example.com/article" --json


# Script directory for dependency location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity config
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_SOURCES="$(get_directory_by_key "sources")"

# Enhanced logging integration
LOG_LEVEL="${LOG_LEVEL:-info}"
log_debug() { [[ "$LOG_LEVEL" == "debug" ]] && echo "[DEBUG] $*" >&2 || true; }
log_info() { [[ "$LOG_LEVEL" =~ ^(info|debug)$ ]] && echo "[INFO] $*" >&2 || true; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit 0  # Always exit 0 for detection
}

normalize_url() {
    local url="$1"
    local normalize_script="${SCRIPT_DIR}/normalize-url.sh"

    if [[ ! -x "$normalize_script" ]]; then
        log_error "normalize-url.sh not found or not executable at: $normalize_script"
        echo "$url"  # Return original if normalization unavailable
        return
    fi

    local result
    result="$("$normalize_script" "$url" 2>/dev/null)" || {
        log_warn "URL normalization failed for: $url"
        echo "$url"
        return
    }

    echo "$result"
}

extract_url_from_frontmatter() {
    local file="$1"

    # Fast awk-based extraction: find line with "url:" in frontmatter
    # Frontmatter is between --- markers at file start
    local url
    url="$(awk '
        BEGIN { in_frontmatter=0; }
        /^---$/ {
            if (NR == 1) { in_frontmatter=1; next; }
            else if (in_frontmatter) { exit; }
        }
        in_frontmatter && /^url:/ {
            sub(/^url:[ \t]*/, "");
            gsub(/^["'"'"']|["'"'"']$/, "");
            print;
            exit;
        }
    ' "$file" 2>/dev/null)"

    echo "$url"
}

main() {
    local project_path=""
    local search_url=""
    local json_output=false

    # Argument parsing
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --url)
                search_url="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$project_path" ]]; then
        error_json "Missing required argument: --project-path" 2
    fi

    if [[ -z "$search_url" ]]; then
        error_json "Missing required argument: --url" 2
    fi

    # Validate project path exists
    if [[ ! -d "$project_path" ]]; then
        error_json "Project directory not found: $project_path" 3
    fi

    local sources_dir="${project_path}/${DIR_SOURCES}/${DATA_SUBDIR}"

    # Handle missing 07-sources/data/ directory gracefully
    if [[ ! -d "$sources_dir" ]]; then
        log_debug "${DIR_SOURCES}/${DATA_SUBDIR}/ directory not found, returning exists=false"
        jq -n '{success: true, exists: false}'
        exit 0
    fi

    # Normalize search URL
    log_debug "Normalizing search URL: $search_url"
    local normalized_search
    normalized_search="$(normalize_url "$search_url")"
    log_debug "Normalized search URL: $normalized_search"

    # Scan all source files
    local source_files=()
    while IFS= read -r file; do
        source_files+=("$file")
    done < <(find "$sources_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)

    local file_count=${#source_files[@]}
    log_info "Scanning $file_count source files for URL match"

    if [[ $file_count -eq 0 ]]; then
        log_debug "No source files found in $sources_dir"
        jq -n '{success: true, exists: false}'
        exit 0
    fi

    # Process each file with early exit optimization
    local start_time
    start_time="$(date +%s 2>/dev/null || echo "0")"

    for file in "${source_files[@]}"; do
        # Extract URL from frontmatter
        local file_url
        file_url="$(extract_url_from_frontmatter "$file")"

        if [[ -z "$file_url" ]]; then
            log_debug "No URL found in: $(basename "$file")"
            continue
        fi

        # Normalize extracted URL
        local normalized_file_url
        normalized_file_url="$(normalize_url "$file_url")"

        # Compare normalized URLs
        if [[ "$normalized_search" == "$normalized_file_url" ]]; then
            # Match found - extract source_id and relative path
            local source_id
            source_id="$(basename "$file" .md)"

            local relative_path="${DIR_SOURCES}/${DATA_SUBDIR}/$(basename "$file")"

            local end_time
            end_time="$(date +%s 2>/dev/null || echo "0")"
            local duration=$((end_time - start_time))

            log_info "Match found: $source_id (scanned $file_count files in ${duration}s)"

            # Return match result
            jq -n \
                --arg source_id "$source_id" \
                --arg source_path "$relative_path" \
                --arg url_matched "$normalized_file_url" \
                '{
                    success: true,
                    exists: true,
                    source_id: $source_id,
                    source_path: $source_path,
                    url_matched: $url_matched
                }'
            exit 0
        fi
    done

    # No match found
    local end_time
    end_time="$(date +%s 2>/dev/null || echo "0")"
    local duration=$((end_time - start_time))

    log_info "No match found (scanned $file_count files in ${duration}s)"

    jq -n '{success: true, exists: false}'
    exit 0
}

main "$@"
