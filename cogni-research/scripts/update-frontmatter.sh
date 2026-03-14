#!/usr/bin/env bash
set -euo pipefail
# update-frontmatter.sh
# Version: 1.0.0
# Purpose: Add or update a key-value pair in YAML frontmatter of a markdown file
# Category: utilities
#
# Usage: update-frontmatter.sh --file <path> --key <name> --value <value> --json
#
# Arguments:
#   --file <path>     Absolute path to markdown file (required)
#   --key <name>      Frontmatter key to update (required)
#   --value <value>   Value to set (required)
#   --json            Output JSON format (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "file": "/path/to/file.md",
#       "key": "research_type",
#       "value": "smarter-service",
#       "action": "updated" | "added"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error (file not found, invalid YAML, etc.)
#   2 - Invalid arguments
#
# Example:
#   update-frontmatter.sh --file "/path/to/question.md" --key "research_type" --value "smarter-service" --json


# Source enhanced logging (with fallback)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Validate key is valid YAML identifier
validate_key() {
    local key="$1"
    if [[ ! "$key" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_json "Invalid key format: $key (must be alphanumeric, underscore, or hyphen)" 2
    fi
}

# Escape value for YAML (handles special characters, quotes, newlines)
escape_yaml_value() {
    local value="$1"
    # If value contains special chars or newlines, quote it
    if [[ "$value" =~ [:\{\}\[\]#\&\*\!\|\>\'\"\%\@\`] ]] || [[ "$value" == *$'\n'* ]]; then
        # Double-quote and escape internal quotes
        value="${value//\"/\\\"}"
        echo "\"$value\""
    else
        echo "$value"
    fi
}

# Check if file has frontmatter
has_frontmatter() {
    local file="$1"
    local first_line
    first_line="$(head -n 1 "$file" 2>/dev/null)"
    [[ "$first_line" == "---" ]]
}

# Update existing frontmatter key or add new key
update_frontmatter_content() {
    local file="$1"
    local key="$2"
    local value="$3"
    local temp_file="$4"

    log_phase "UPDATE" "Processing existing frontmatter"

    local in_frontmatter=false
    local frontmatter_ended=false
    local key_found=false
    local line_number=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))

        # First line - should be "---"
        if [[ $line_number -eq 1 ]]; then
            if ! [[ "$line" == "---" ]]; then
                error_json "Malformed frontmatter: missing opening '---'" 1
            fi
            echo "$line" >> "$temp_file"
            in_frontmatter=true
            continue
        fi

        # Check for closing "---"
        if [[ "$line" == "---" ]] && $in_frontmatter; then
            # If key not found, add it before closing
            if ! $key_found; then
                echo "$key: $value" >> "$temp_file"
                log_conditional "ADD" "Added new key: $key"
            fi
            echo "$line" >> "$temp_file"
            in_frontmatter=false
            frontmatter_ended=true
            continue
        fi

        # Inside frontmatter - check if this is our key
        if $in_frontmatter; then
            if [[ "$line" =~ ^[[:space:]]*${key}:[[:space:]]* ]]; then
                # Key found - replace value
                echo "$key: $value" >> "$temp_file"
                key_found=true
                log_conditional "UPDATE" "Updated existing key: $key"
            else
                # Other frontmatter line - preserve
                echo "$line" >> "$temp_file"
            fi
        else
            # After frontmatter - preserve all content
            echo "$line" >> "$temp_file"
        fi
    done < "$file"

    $key_found
}

# Create new frontmatter block
create_frontmatter() {
    local file="$1"
    local key="$2"
    local value="$3"
    local temp_file="$4"

    log_phase "CREATE" "Creating new frontmatter block"

    # Write frontmatter header
    echo "---" > "$temp_file"
    echo "$key: $value" >> "$temp_file"
    echo "---" >> "$temp_file"

    # Append original content
    cat "$file" >> "$temp_file"
}

# Main function
main() {
    log_phase "START" "update-frontmatter.sh invoked"

    # Parse arguments
    local file=""
    local key=""
    local value=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            --key)
                key="$2"
                shift 2
                ;;
            --value)
                value="$2"
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
    [[ -n "$file" ]] || error_json "Missing required argument: --file" 2
    [[ -n "$key" ]] || error_json "Missing required argument: --key" 2
    [[ -n "$value" ]] || error_json "Missing required argument: --value" 2
    [[ "$json_output" == true ]] || error_json "Missing required argument: --json" 2

    log_metric "file" "$file" "input"
    log_metric "key" "$key" "target"
    log_metric "value" "$value" "new_value"

    # Validate file exists and is readable
    [[ -f "$file" ]] || error_json "File not found: $file" 1
    [[ -r "$file" ]] || error_json "File not readable: $file" 1

    # Validate key format
    validate_key "$key"

    # Escape value for YAML
    local escaped_value
    escaped_value="$(escape_yaml_value "$value")"

    # Create temporary file
    local temp_file
    temp_file="$(mktemp)" || error_json "Failed to create temporary file" 1

    # Determine action based on frontmatter existence
    local action=""
    if has_frontmatter "$file"; then
        log_conditional "DETECT" "Existing frontmatter detected"
        if update_frontmatter_content "$file" "$key" "$escaped_value" "$temp_file"; then
            action="updated"
        else
            action="added"
        fi
    else
        log_conditional "DETECT" "No frontmatter detected - creating new"
        create_frontmatter "$file" "$key" "$escaped_value" "$temp_file"
        action="added"
    fi

    # Validate temporary file is not empty
    [[ -s "$temp_file" ]] || {
        rm -f "$temp_file"
        error_json "Generated empty file - operation aborted" 1
    }

    # Preserve file permissions (portable for macOS/BSD and Linux)
    if stat -f "%Lp" "$file" >/dev/null 2>&1; then
        # macOS/BSD: use stat -f
        local perms
        perms="$(stat -f "%Lp" "$file")"
        chmod "$perms" "$temp_file"
    elif stat -c "%a" "$file" >/dev/null 2>&1; then
        # Linux: use stat -c
        local perms
        perms="$(stat -c "%a" "$file")"
        chmod "$perms" "$temp_file"
    else
        # Fallback if both fail
        chmod 644 "$temp_file"
    fi

    # Atomic replace
    mv "$temp_file" "$file" || error_json "Failed to update file: $file" 1

    log_phase "COMPLETE" "Frontmatter updated successfully"
    log_metric "action" "$action" "result"

    # Success output
    jq -n \
        --arg file "$file" \
        --arg key "$key" \
        --arg value "$value" \
        --arg action "$action" \
        '{
            success: true,
            data: {
                file: $file,
                key: $key,
                value: $value,
                action: $action
            }
        }'
}

# Execute main function
main "$@"
