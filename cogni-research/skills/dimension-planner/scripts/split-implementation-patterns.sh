#!/usr/bin/env bash
# split-implementation-patterns.sh
# Version: 1.0.0
# Purpose: Split implementation-patterns.md into three focused thematic files
# Category: utilities

set -eo pipefail

# === Documentation ===
# Usage: ./split-implementation-patterns.sh
# Arguments: None (uses hardcoded paths)
# Output: Three focused markdown files in references/ directory
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - File operation error

# === Configuration ===
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILL_BASE="$(dirname "$SCRIPT_DIR")"
readonly SOURCE_FILE="${SKILL_BASE}/references/implementation-patterns.md"
readonly OUTPUT_DIR="${SKILL_BASE}/references"

readonly FILE1="${OUTPUT_DIR}/multilingual-patterns.md"
readonly FILE2="${OUTPUT_DIR}/error-recovery-patterns.md"
readonly FILE3="${OUTPUT_DIR}/validation-patterns.md"

# === Logging Setup ===
# Source enhanced logging with fallback
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { echo "[PHASE] $1: $2" >&2; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2 || true; }
fi

# Initialize log file
LOG_FILE="${SKILL_BASE}/reports/split-implementation-patterns.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 2> >(tee -a "$LOG_FILE" >&2)

# === Error Handling ===
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n \
        --arg error "$msg" \
        --argjson code "$code" \
        '{success: false, error: $error, exit_code: $code}' >&2
    exit "$code"
}

# === Main Functions ===

validate_source() {
    log_phase "Validation" "Checking source file"

    if [[ ! -f "$SOURCE_FILE" ]]; then
        error_json "Source file not found: $SOURCE_FILE" 2
    fi

    local size
    size="$(wc -c < "$SOURCE_FILE" | tr -d ' ')"
    log_metric "source_size_bytes" "$size" "bytes"

    if [[ "$size" -lt 1000 ]]; then
        error_json "Source file suspiciously small: $size bytes" 1
    fi
}

create_file_header() {
    local title="$1"
    local description="$2"

    cat <<EOF
# $title

$description

**Source:** Extracted from implementation-patterns.md by split-implementation-patterns.sh v1.0.0

**Related References:**
- implementation-patterns.md - Original comprehensive patterns
- ../../references/shared-bash-patterns.md - Cross-plugin shared patterns

---

EOF
}

extract_sections() {
    local output_file="$1"
    shift
    local sections=("$@")

    log_conditional INFO "Extracting ${#sections[@]} sections to $(basename "$output_file")"

    # Create temp file for extraction
    local temp_file="${output_file}.tmp"
    > "$temp_file"

    for section in "${sections[@]}"; do
        log_conditional DEBUG "Extracting section: $section"

        # Extract section using awk
        awk -v section="$section" '
            BEGIN { in_section = 0; header_found = 0 }

            # Match section header (## Section Name)
            $0 ~ "^## " section {
                in_section = 1
                header_found = 1
                print $0
                next
            }

            # Stop at next ## heading
            in_section && /^## / && $0 !~ section {
                in_section = 0
            }

            # Print lines in section
            in_section {
                print $0
            }

            END {
                if (!header_found) {
                    print "<!-- Section not found: " section " -->" > "/dev/stderr"
                }
            }
        ' "$SOURCE_FILE" >> "$temp_file"

        # Add separator between sections
        echo "" >> "$temp_file"
    done

    # Move temp to final location
    mv "$temp_file" "$output_file"
}

create_multilingual_file() {
    log_phase "File 1" "Creating multilingual-patterns.md"

    local header
    header="$(create_file_header "Multilingual Support Patterns" \
        "Language detection, English slug generation, localized display names, and content localization for multilingual research projects.")"

    echo "$header" > "$FILE1"

    # Extract sections
    local sections=(
        "Section 5: Multilingual Support"
        "Language Detection & Project Language Loading"
        "English Slug Generation Patterns"
        "Localized Display Name Generation"
        "Content Localization: Rationale & Research Focus"
    )

    extract_sections "$FILE1" "${sections[@]}"

    local size
    size="$(wc -c < "$FILE1" | tr -d ' ')"
    log_metric "file1_size" "$size" "bytes"
}

create_error_recovery_file() {
    log_phase "File 2" "Creating error-recovery-patterns.md"

    local header
    header="$(create_file_header "Error Handling and Recovery Patterns" \
        "Comprehensive error detection, recovery strategies, and validation patterns for robust dimension-planner execution.")"

    echo "$header" > "$FILE2"

    # Extract sections
    local sections=(
        "Runtime Safety Patterns"
        "Section 6: Error Handling Patterns"
        "Logging Patterns"
        "JSON Response Pattern"
    )

    extract_sections "$FILE2" "${sections[@]}"

    local size
    size="$(wc -c < "$FILE2" | tr -d ' ')"
    log_metric "file2_size" "$size" "bytes"
}

create_validation_file() {
    log_phase "File 3" "Creating validation-patterns.md"

    local header
    header="$(create_file_header "Validation and Configuration Patterns" \
        "Environment validation, question loading, template parsing, variable assignment, and filename generation patterns.")"

    echo "$header" > "$FILE3"

    # Extract sections
    local sections=(
        "Environment Validation"
        "Question Loading"
        "Template Parsing (Research-Type-Specific Mode)"
        "Variable Assignment Examples"
        "Filename Generation"
        "Dimension Purpose"
        "Key Topics"
    )

    extract_sections "$FILE3" "${sections[@]}"

    local size
    size="$(wc -c < "$FILE3" | tr -d ' ')"
    log_metric "file3_size" "$size" "bytes"
}

validate_outputs() {
    log_phase "Validation" "Verifying output files"

    local files=("$FILE1" "$FILE2" "$FILE3")
    local total_size=0

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error_json "Output file not created: $file" 2
        fi

        local size
        size="$(wc -c < "$file" | tr -d ' ')"
        total_size=$((total_size + size))

        log_conditional INFO "$(basename "$file"): $size bytes"
    done

    log_metric "total_output_size" "$total_size" "bytes"

    # Verify all files created
    if [[ ${#files[@]} -ne 3 ]]; then
        error_json "Expected 3 files, found ${#files[@]}" 1
    fi

    # Check total size is reasonable
    if [[ "$total_size" -lt 5000 ]]; then
        error_json "Total output size suspiciously small: $total_size bytes" 1
    fi
}

generate_success_response() {
    local file1_size file2_size file3_size total_size
    file1_size="$(wc -c < "$FILE1" | tr -d ' ')"
    file2_size="$(wc -c < "$FILE2" | tr -d ' ')"
    file3_size="$(wc -c < "$FILE3" | tr -d ' ')"
    total_size=$((file1_size + file2_size + file3_size))

    jq -n \
        --arg file1 "$FILE1" \
        --arg file2 "$FILE2" \
        --arg file3 "$FILE3" \
        --argjson file1_size "$file1_size" \
        --argjson file2_size "$file2_size" \
        --argjson file3_size "$file3_size" \
        --argjson total_size "$total_size" \
        '{
            success: true,
            data: {
                files_created: 3,
                outputs: [
                    {path: $file1, size_bytes: $file1_size, theme: "multilingual"},
                    {path: $file2, size_bytes: $file2_size, theme: "error-recovery"},
                    {path: $file3, size_bytes: $file3_size, theme: "validation"}
                ],
                total_size_bytes: $total_size
            }
        }'
}

# === Main Execution ===
main() {
    log_phase "Start" "Splitting implementation-patterns.md into thematic files"

    validate_source
    create_multilingual_file
    create_error_recovery_file
    create_validation_file
    validate_outputs

    log_phase "Complete" "Successfully created 3 focused pattern files"
    generate_success_response
}

main "$@"
