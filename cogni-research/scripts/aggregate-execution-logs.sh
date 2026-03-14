#!/usr/bin/env bash
set -euo pipefail
# aggregate-execution-logs.sh
# Version: 1.0.0
# Category: utilities
# Purpose: Aggregate partition statistics and execution logs from deeper-research projects
#
# Usage:
#   aggregate-execution-logs.sh --project-path <path> [--output-format <format>] [--json]
#
# Arguments:
#   --project-path <path>      Path to research project directory (required)
#   --output-format <format>   Output format: "json" or "markdown" (optional, default: markdown)
#   --json                     Output JSON format (shorthand for --output-format json)
#
# Output (JSON mode):
#   {
#     "success": true,
#     "data": {
#       "project_path": "<path>",
#       "aggregated_at": "<ISO8601 timestamp>",
#       "partition_stats": {
#         "total_partitions": <number>,
#         "partitions_found": <number>,
#         "findings_processed": <number>,
#         "claims_created": <number>,
#         "avg_confidence": <number>,
#         "avg_evidence_confidence": <number>,
#         "avg_claim_quality": <number>,
#         "total_flagged": <number>,
#         "total_errors": <number>,
#         "quality_averages": {
#           "atomicity": <number>,
#           "fluency": <number>,
#           "decontextualization": <number>,
#           "faithfulness": <number>
#         }
#       },
#       "execution_summary": {
#         "agents_executed": ["<agent1>", "<agent2>"],
#         "total_errors": <number>,
#         "total_warnings": <number>
#       }
#     }
#   }
#
# Output (Markdown mode):
#   Human-readable summary with sections for partition stats and execution summary
#
# Exit codes:
#   0 - Success
#   1 - Project path doesn't exist or no logs found
#   2 - Invalid arguments
#
# Example:
#   aggregate-execution-logs.sh --project-path /path/to/project --json


# Error handling function
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Main function
main() {
    local project_path=""
    local output_format="markdown"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                [[ -n "${2:-}" ]] || error_json "Missing value for --project-path" 2
                project_path="$2"
                shift 2
                ;;
            --output-format)
                [[ -n "${2:-}" ]] || error_json "Missing value for --output-format" 2
                output_format="$2"
                shift 2
                ;;
            --json)
                output_format="json"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -d "$project_path" ]] || error_json "Project path does not exist: $project_path" 1

    # Validate output format
    if ! [[ "$output_format" == "json" ]] && ! [[ "$output_format" == "markdown" ]]; then
        error_json "Invalid output format: $output_format (must be 'json' or 'markdown')" 2
    fi

    # Find reports directory
    local reports_dir="${project_path}/reports"
    [[ -d "$reports_dir" ]] || error_json "Reports directory not found: $reports_dir" 1

    # Aggregate partition statistics
    local partition_stats_files=()
    while IFS= read -r file; do
        partition_stats_files+=("$file")
    done < <(find "$reports_dir" -name "partition-*-stats.json" 2>/dev/null | sort)

    # Check if any partition stats found
    if [[ ${#partition_stats_files[@]} -eq 0 ]]; then
        error_json "No partition stats files found in $reports_dir" 1
    fi

    # Initialize aggregation variables
    local total_partitions=0
    local partitions_found=${#partition_stats_files[@]}
    local total_findings=0
    local total_claims=0
    local weighted_confidence=0
    local weighted_evidence_confidence=0
    local weighted_claim_quality=0
    local total_flagged=0
    local total_errors=0

    # Quality dimension accumulators
    local weighted_atomicity=0
    local weighted_fluency=0
    local weighted_decontextualization=0
    local weighted_faithfulness=0

    # Process each partition stats file
    for stats_file in "${partition_stats_files[@]}"; do
        # Extract partition info
        local partition_total
        partition_total="$(jq -r '.partition_info.total_partitions // 0' "$stats_file" 2>/dev/null || echo "0")"
        if [[ "$partition_total" -gt "$total_partitions" ]]; then
            total_partitions="$partition_total"
        fi

        # Extract stats
        local findings
        local claims
        local confidence
        local evidence_conf
        local claim_qual
        local flagged
        local errors

        findings="$(jq -r '.findings_processed // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        claims="$(jq -r '.claims_created // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        confidence="$(jq -r '.avg_confidence // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        evidence_conf="$(jq -r '.avg_evidence_confidence // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        claim_qual="$(jq -r '.avg_claim_quality // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        flagged="$(jq -r '.flagged_for_review // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
        errors="$(jq -r '.error_count // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"

        # Accumulate totals
        total_findings=$((total_findings + findings))
        total_claims=$((total_claims + claims))
        total_flagged=$((total_flagged + flagged))
        total_errors=$((total_errors + errors))

        # Weight by claims created for averages
        if [[ "$claims" -gt 0 ]]; then
            weighted_confidence="$(echo "$weighted_confidence + ($confidence * $claims)" | bc -l)"
            weighted_evidence_confidence="$(echo "$weighted_evidence_confidence + ($evidence_conf * $claims)" | bc -l)"
            weighted_claim_quality="$(echo "$weighted_claim_quality + ($claim_qual * $claims)" | bc -l)"

            # Quality dimensions
            local atomicity
            local fluency
            local decontextualization
            local faithfulness

            atomicity="$(jq -r '.quality_dimension_averages.atomicity // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
            fluency="$(jq -r '.quality_dimension_averages.fluency // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
            decontextualization="$(jq -r '.quality_dimension_averages.decontextualization // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"
            faithfulness="$(jq -r '.quality_dimension_averages.faithfulness // 0' "$stats_file" 2>/dev/null | tr -d '	' || echo "0")"

            weighted_atomicity="$(echo "$weighted_atomicity + ($atomicity * $claims)" | bc -l)"
            weighted_fluency="$(echo "$weighted_fluency + ($fluency * $claims)" | bc -l)"
            weighted_decontextualization="$(echo "$weighted_decontextualization + ($decontextualization * $claims)" | bc -l)"
            weighted_faithfulness="$(echo "$weighted_faithfulness + ($faithfulness * $claims)" | bc -l)"
        fi
    done

    # Calculate weighted averages
    local avg_confidence=0
    local avg_evidence_confidence=0
    local avg_claim_quality=0
    local avg_atomicity=0
    local avg_fluency=0
    local avg_decontextualization=0
    local avg_faithfulness=0

    if [[ "$total_claims" -gt 0 ]]; then
        avg_confidence="$(echo "scale=3; $weighted_confidence / $total_claims" | bc -l)"
        avg_evidence_confidence="$(echo "scale=3; $weighted_evidence_confidence / $total_claims" | bc -l)"
        avg_claim_quality="$(echo "scale=3; $weighted_claim_quality / $total_claims" | bc -l)"
        avg_atomicity="$(echo "scale=3; $weighted_atomicity / $total_claims" | bc -l)"
        avg_fluency="$(echo "scale=3; $weighted_fluency / $total_claims" | bc -l)"
        avg_decontextualization="$(echo "scale=3; $weighted_decontextualization / $total_claims" | bc -l)"
        avg_faithfulness="$(echo "scale=3; $weighted_faithfulness / $total_claims" | bc -l)"
    fi

    # Parse execution logs
    local execution_logs=()
    while IFS= read -r file; do
        execution_logs+=("$file")
    done < <(find "$reports_dir" -name "*-execution-log.txt" 2>/dev/null | sort)

    # BUG-015 FIX: Array accumulation instead of string concatenation (O(n²) → O(n))
    # Extract agent names and error/warning counts
    local agents_list_array=()  # Array to accumulate unique agent names
    local log_errors=0
    local log_warnings=0

    if [[ ${#execution_logs[@]} -gt 0 ]]; then
        # Build lookup string for deduplication (bash 3.2 compatible)
        local agents_lookup=" "

        for log_file in "${execution_logs[@]}"; do
            # Extract agent name from filename
            local agent_name
            agent_name="$(basename "$log_file" | sed 's/-execution-log\.txt$//')"

            # Check if agent already in list using pattern matching
            if ! [[ "$agents_lookup" == *" $agent_name "* ]]; then
                agents_list_array+=("$agent_name")
                agents_lookup="${agents_lookup}${agent_name} "
            fi

            # Count ERROR and WARN occurrences
            local file_errors
            local file_warnings
            file_errors="$(grep -c "\[ERROR\]" "$log_file" 2>/dev/null || true)"
            file_warnings="$(grep -c "\[WARN\]" "$log_file" 2>/dev/null || true)"

            log_errors=$((log_errors + file_errors))
            log_warnings=$((log_warnings + file_warnings))
        done
    fi

    # Build agents array JSON from array (single printf operation)
    local agents_json="[]"
    if [[ ${#agents_list_array[@]} -gt 0 ]]; then
        agents_json="$(printf '%s\n' "${agents_list_array[@]}" | jq -R . | jq -s .)"
    fi

    # Get current timestamp
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Output based on format
    if [[ "$output_format" == "json" ]]; then
        # JSON output
        jq -n \
            --arg project_path "$project_path" \
            --arg aggregated_at "$timestamp" \
            --argjson total_partitions "$total_partitions" \
            --argjson partitions_found "$partitions_found" \
            --argjson findings_processed "$total_findings" \
            --argjson claims_created "$total_claims" \
            --arg avg_confidence "$avg_confidence" \
            --arg avg_evidence_confidence "$avg_evidence_confidence" \
            --arg avg_claim_quality "$avg_claim_quality" \
            --argjson total_flagged "$total_flagged" \
            --argjson total_errors "$total_errors" \
            --arg avg_atomicity "$avg_atomicity" \
            --arg avg_fluency "$avg_fluency" \
            --arg avg_decontextualization "$avg_decontextualization" \
            --arg avg_faithfulness "$avg_faithfulness" \
            --argjson agents_executed "$agents_json" \
            --argjson log_errors "$log_errors" \
            --argjson log_warnings "$log_warnings" \
            '{
                success: true,
                data: {
                    project_path: $project_path,
                    aggregated_at: $aggregated_at,
                    partition_stats: {
                        total_partitions: $total_partitions,
                        partitions_found: $partitions_found,
                        findings_processed: $findings_processed,
                        claims_created: $claims_created,
                        avg_confidence: ($avg_confidence | tonumber),
                        avg_evidence_confidence: ($avg_evidence_confidence | tonumber),
                        avg_claim_quality: ($avg_claim_quality | tonumber),
                        total_flagged: $total_flagged,
                        total_errors: $total_errors,
                        quality_averages: {
                            atomicity: ($avg_atomicity | tonumber),
                            fluency: ($avg_fluency | tonumber),
                            decontextualization: ($avg_decontextualization | tonumber),
                            faithfulness: ($avg_faithfulness | tonumber)
                        }
                    },
                    execution_summary: {
                        agents_executed: $agents_executed,
                        total_errors: $log_errors,
                        total_warnings: $log_warnings
                    }
                }
            }'
    else
        # Format agents list for display
        local agents_display="None"
        if [[ ${#agents_list_array[@]} -gt 0 ]]; then
            agents_display="$(printf '%s\n' "${agents_list_array[@]}" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
        fi
        # Markdown output
        cat <<EOF
# Deeper Research Execution Summary

**Project:** $project_path
**Generated:** $timestamp

## Partition Statistics

- **Total Partitions:** $total_partitions
- **Partitions Found:** $partitions_found
- **Findings Processed:** $total_findings
- **Claims Created:** $total_claims
- **Total Flagged for Review:** $total_flagged
- **Total Errors:** $total_errors

### Confidence Metrics

- **Average Confidence:** $avg_confidence
- **Average Evidence Confidence:** $avg_evidence_confidence
- **Average Claim Quality:** $avg_claim_quality

### Quality Dimensions

- **Atomicity:** $avg_atomicity
- **Fluency:** $avg_fluency
- **Decontextualization:** $avg_decontextualization
- **Faithfulness:** $avg_faithfulness

## Execution Summary

- **Agents Executed:** $agents_display
- **Total Errors in Logs:** $log_errors
- **Total Warnings in Logs:** $log_warnings

EOF

        # Add warnings if errors or warnings found
        if [[ $log_errors -gt 0 ]]; then
            echo "**WARNING:** $log_errors error(s) found in execution logs. Review logs for details."
        fi

        if [[ $log_warnings -gt 0 ]]; then
            echo "**NOTE:** $log_warnings warning(s) found in execution logs."
        fi
    fi
}

main "$@"
