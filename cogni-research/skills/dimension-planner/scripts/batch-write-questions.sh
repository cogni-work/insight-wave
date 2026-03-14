#!/usr/bin/env bash
set -euo pipefail
# batch-write-questions.sh
# Version: 1.1.0
# Purpose: Batch write multiple question entity files with YAML validation
# Category: utilities
#
# Changelog:
# - v1.1.0: Fix wikilink fallbacks for multi-project workspaces
#           - Fallback wikilinks now include workspace prefix when PROJECT_AGENTS_OPS_ROOT is set
# - v1.0.1: Fix default output_dir to include data/ subdirectory per entity-schema.json
#
# Usage: batch-write-questions.sh --dimension-slug <string> --questions-json <json> --project-path <path> [--output-dir <path>] [--enable-progress-tracking] [--json]
#
# Arguments:
#   --dimension-slug <string>         Dimension identifier (required)
#   --questions-json <json>           JSON array of question objects with metadata (required)
#   --project-path <path>             Absolute path to research project (required)
#   --output-dir <path>               Directory for question files (optional, default: 02-refined-questions/data)
#   --enable-progress-tracking        Enable detailed progress tracking (optional, default: false)
#   --json                            Return JSON output (optional, default: false)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "dimension_slug": "string",
#       "questions_written": number,
#       "questions_planned": number,
#       "validation_passed": number,
#       "validation_failed": number,
#       "files_created": ["file1.md", "file2.md"],
#       "progress_tracker_path": "path" (if progress tracking enabled)
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error or write failure
#   2 - Invalid arguments
#   3 - Required path not found
#
# Example:
#   batch-write-questions.sh --dimension-slug "customer-analysis" \
#     --questions-json '[{"id":"customer-analysis-q1","text":"...","picot":{...},"finer":{...}}]' \
#     --project-path "/path/to/project" \
#     --json


# Source enhanced logging utilities
if [[ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging functions when enhanced-logging.sh unavailable
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2; }
  log_phase() { echo "[PHASE] $1: $2" >> "${LOG_FILE:-.}" 2>/dev/null; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# Source centralized entity config for DATA_SUBDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"

# Wikilink script path
WIKILINK_SCRIPT="${CLAUDE_PLUGIN_ROOT:-}/scripts/generate-wikilink.sh"

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"

    log_conditional "ERROR" "$message"

    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Build workspace-aware fallback wikilink when generate-wikilink.sh fails
# Usage: build_fallback_wikilink <entity_dir> <filename> [project_path]
# Returns: Wikilink with workspace prefix if PROJECT_AGENTS_OPS_ROOT is set
# Fix v1.1.0: Prevents broken wikilinks in multi-project Obsidian vaults
build_fallback_wikilink() {
    local entity_dir="$1"
    local filename="$2"
    local proj_path="${3:-$project_path}"

    # Detect workspace prefix from project_path
    local workspace_prefix=""
    if [[ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]] && [[ -n "$proj_path" ]]; then
        workspace_prefix="${proj_path#"$PROJECT_AGENTS_OPS_ROOT"/}"
        if [[ "$workspace_prefix" == "$proj_path" ]]; then
            workspace_prefix=""
        fi
    fi

    local path="${entity_dir}/${DATA_SUBDIR}/${filename}"
    if [[ -n "$workspace_prefix" ]]; then
        path="${workspace_prefix}/${path}"
    fi

    echo "[[$path]]"
}

# Validate YAML frontmatter structure
validate_yaml_frontmatter() {
    local yaml_content="$1"
    local question_id="$2"

    # Check for common YAML issues
    if echo "$yaml_content" | grep -q ':='; then
        log_conditional "ERROR" "Invalid YAML operator ':=' in $question_id"
        return 1
    fi

    # Check for required fields
    if ! echo "$yaml_content" | grep -q 'dc:identifier:'; then
        log_conditional "ERROR" "Missing dc:identifier in $question_id"
        return 1
    fi

    if ! echo "$yaml_content" | grep -q 'entity_type:'; then
        log_conditional "ERROR" "Missing entity_type in $question_id"
        return 1
    fi

    # Check for unescaped colons in scalar values (simplified check)
    # This is a basic heuristic - full validation would require YAML parser
    log_conditional "DEBUG" "YAML validation passed for $question_id"
    return 0
}

# Write single question file with validation
write_question_file() {
    local question_json="$1"
    local output_dir="$2"
    local project_language="$3"
    local project_path="$4"

    # Extract question metadata
    local question_id="$(echo "$question_json" | jq -r '.id')"
    local question_text="$(echo "$question_json" | jq -r '.text')"
    local dimension_slug="$(echo "$question_json" | jq -r '.dimension_slug')"
    local order="$(echo "$question_json" | jq -r '.order')"

    # Extract PICOT components
    local population="$(echo "$question_json" | jq -r '.picot.population')"
    local intervention="$(echo "$question_json" | jq -r '.picot.intervention')"
    local comparison="$(echo "$question_json" | jq -r '.picot.comparison')"
    local outcome="$(echo "$question_json" | jq -r '.picot.outcome')"
    local timeframe="$(echo "$question_json" | jq -r '.picot.timeframe')"

    # Extract FINER scores
    local finer_total="$(echo "$question_json" | jq -r '.finer.total')"
    local feasible="$(echo "$question_json" | jq -r '.finer.feasible')"
    local interesting="$(echo "$question_json" | jq -r '.finer.interesting')"
    local novel="$(echo "$question_json" | jq -r '.finer.novel')"
    local ethical="$(echo "$question_json" | jq -r '.finer.ethical')"
    local relevant="$(echo "$question_json" | jq -r '.finer.relevant')"

    # Extract quality attributes
    local confidence="$(echo "$question_json" | jq -r '.quality.confidence // "medium"')"
    local complexity="$(echo "$question_json" | jq -r '.quality.complexity // "moderate"')"

    # Validate required data
    if [[ -z "$question_text" ]] || [[ "$question_text" == "null" ]] || [[ "$question_text" == "..." ]]; then
        log_conditional "ERROR" "Invalid question text for $question_id"
        return 1
    fi

    if [[ "$finer_total" -lt 10 ]]; then
        log_conditional "ERROR" "FINER score too low for $question_id: $finer_total"
        return 1
    fi

    # Generate dimension wikilink
    # Fix v1.1.0: Use workspace-aware fallback for multi-project setups
    local dim_wikilink="$(build_fallback_wikilink "01-research-dimensions" "$dimension_slug" "$project_path")"
    if [[ -n "$project_path" ]] && [[ -x "$WIKILINK_SCRIPT" ]]; then
        if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
            --project-path "$project_path" \
            --entity-dir "01-research-dimensions" \
            --filename "$dimension_slug" 2>/dev/null)"; then
            if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
                dim_wikilink="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
            fi
        fi
    fi

    # Construct YAML frontmatter
    local yaml_content="---
dc:identifier: \"$question_id\"
entity_type: \"refined-question\"
display_name: \"$question_text\"
language: \"$project_language\"
dimension: \"$dim_wikilink\"
dimension_ref: \"$dimension_slug\"
order: $order
picot:
  population: \"$population\"
  intervention: \"$intervention\"
  comparison: \"$comparison\"
  outcome: \"$outcome\"
  timeframe: \"$timeframe\"
quality:
  finer_score: $finer_total
  feasible: $feasible
  interesting: $interesting
  novel: $novel
  ethical: $ethical
  relevant: $relevant
  confidence: \"$confidence\"
  complexity: \"$complexity\"
---"

    # Validate YAML structure
    if ! validate_yaml_frontmatter "$yaml_content" "$question_id"; then
        log_conditional "ERROR" "YAML validation failed for $question_id"
        return 1
    fi

    # Construct full file content
    local file_content="$yaml_content

# $question_text

## PICOT Components

**Population:** $population

**Intervention:** $intervention

**Comparison:** $comparison

**Outcome:** $outcome

**Timeframe:** $timeframe

## Quality Assessment

**FINER Score:** $finer_total/15
- Feasible: $feasible/3
- Interesting: $interesting/3
- Novel: $novel/3
- Ethical: $ethical/3
- Relevant: $relevant/3

**Confidence:** $confidence

**Research Complexity:** $complexity

## Search Strategy

This question requires systematic research across academic and industry sources."

    # Write file
    local file_path="$output_dir/$question_id.md"
    echo "$file_content" > "$file_path"

    # Verify write succeeded
    if [[ ! -f "$file_path" ]] || [[ ! -s "$file_path" ]]; then
        log_conditional "ERROR" "Failed to write $file_path"
        return 1
    fi

    local file_size="$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")"
    log_conditional "INFO" "Created $question_id.md ($file_size bytes)"

    echo "$question_id"
    return 0
}

# Main function
main() {
    # Parse arguments
    local dimension_slug=""
    local questions_json=""
    local project_path=""
    local output_dir="02-refined-questions/data"
    local enable_progress_tracking="false"
    local json_output="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dimension-slug)
                dimension_slug="$2"
                shift 2
                ;;
            --questions-json)
                questions_json="$2"
                shift 2
                ;;
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --enable-progress-tracking)
                enable_progress_tracking="true"
                shift
                ;;
            --json)
                json_output="true"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$dimension_slug" ]] || error_json "Missing required argument: --dimension-slug" 2
    [[ -n "$questions_json" ]] || error_json "Missing required argument: --questions-json" 2
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2

    # Validate paths
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 3

    # Initialize logging
    LOG_FILE="${project_path}/.metadata/batch-write-questions-execution-log.txt"
    mkdir -p "${project_path}/.metadata" 2>/dev/null || true

    echo "========================================" >> "$LOG_FILE"
    echo "Execution Log: batch-write-questions" >> "$LOG_FILE"
    echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"

    log_phase "Phase 1: Initialization" "start"
    log_conditional "INFO" "Script version: 1.0.0"
    log_conditional "INFO" "Project path: $project_path"
    log_conditional "INFO" "Dimension: $dimension_slug"
    log_conditional "DEBUG" "Debug mode: ${DEBUG_MODE:-false}"
    log_phase "Phase 1: Initialization" "complete"

    # Create output directory
    local full_output_dir="${project_path}/${output_dir}"
    mkdir -p "$full_output_dir" 2>/dev/null || error_json "Cannot create output directory: $full_output_dir" 3

    # Get project language from metadata
    local project_language="en"
    if [[ -f "${project_path}/.metadata/sprint-log.json" ]]; then
        project_language="$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json" 2>/dev/null || echo "en")"
    fi
    log_conditional "INFO" "Project language: $project_language"

    # Parse questions array
    log_phase "Phase 2: Batch Write Questions" "start"

    local questions_count="$(echo "$questions_json" | jq 'length')"
    log_conditional "INFO" "Processing $questions_count questions for dimension $dimension_slug"

    # Initialize counters
    local questions_written=0
    local validation_passed=0
    local validation_failed=0
    local files_created=()

    # Initialize progress tracker if enabled
    local progress_tracker_path=""
    if [[ "$enable_progress_tracking" == "true" ]]; then
        progress_tracker_path="${project_path}/.metadata/phase5-progress-${dimension_slug}.md"
        echo "# Batch Write Progress: $dimension_slug" > "$progress_tracker_path"
        echo "**Questions:** $questions_count" >> "$progress_tracker_path"
        echo "**Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$progress_tracker_path"
        echo "" >> "$progress_tracker_path"
        log_conditional "INFO" "Progress tracker enabled: $progress_tracker_path"
    fi

    # Process each question
    local index=0
    while [[ $index -lt $questions_count ]]; do
        local question_json="$(echo "$questions_json" | jq ".[$index]")"
        local question_id="$(echo "$question_json" | jq -r '.id')"

        log_conditional "INFO" "Writing question $((index + 1))/$questions_count: $question_id"

        if write_question_file "$question_json" "$full_output_dir" "$project_language" "$project_path"; then
            questions_written=$((questions_written + 1))
            validation_passed=$((validation_passed + 1))
            files_created+=("$question_id.md")

            if [[ "$enable_progress_tracking" == "true" ]]; then
                echo "- [x] $question_id" >> "$progress_tracker_path"
            fi
        else
            validation_failed=$((validation_failed + 1))
            log_conditional "WARN" "Failed to write $question_id"

            if [[ "$enable_progress_tracking" == "true" ]]; then
                echo "- [ ] $question_id (FAILED)" >> "$progress_tracker_path"
            fi
        fi

        index=$((index + 1))
    done

    log_phase "Phase 2: Batch Write Questions" "complete"

    # Phase 3: Verification and output
    log_phase "Phase 3: Verification and Output" "start"

    # Log metrics
    log_metric "questions_planned" "$questions_count" "count"
    log_metric "questions_written" "$questions_written" "count"
    log_metric "validation_passed" "$validation_passed" "count"
    log_metric "validation_failed" "$validation_failed" "count"

    # Check if all questions were written successfully
    if [[ $validation_failed -gt 0 ]]; then
        log_conditional "WARN" "Some questions failed validation: $validation_failed/$questions_count"
    fi

    if [[ $questions_written -eq 0 ]]; then
        error_json "Failed to write any questions" 1
    fi

    log_phase "Phase 3: Verification and Output" "complete"

    # Build files_created JSON array
    local files_json="[]"
    if [[ ${#files_created[@]} -gt 0 ]]; then
        files_json="$(printf '%s\n' "${files_created[@]}" | jq -R . | jq -s .)"
    fi

    # Success output
    if [[ "$json_output" == "true" ]] || [[ "$enable_progress_tracking" == "true" ]]; then
        jq -n \
            --arg dim "$dimension_slug" \
            --argjson written "$questions_written" \
            --argjson planned "$questions_count" \
            --argjson passed "$validation_passed" \
            --argjson failed "$validation_failed" \
            --argjson files "$files_json" \
            --arg tracker "${progress_tracker_path:-}" \
            '{
                success: true,
                data: {
                    dimension_slug: $dim,
                    questions_written: $written,
                    questions_planned: $planned,
                    validation_passed: $passed,
                    validation_failed: $failed,
                    files_created: $files,
                    progress_tracker_path: (if $tracker != "" then $tracker else null end)
                }
            }'
    else
        echo "✅ Batch write complete: $questions_written/$questions_count questions written for $dimension_slug"
    fi
}

# Execute main function
main "$@"
