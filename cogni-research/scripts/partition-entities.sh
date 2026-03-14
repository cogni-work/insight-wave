#!/usr/bin/env bash
set -euo pipefail
# partition-entities.sh
# Version: 1.1.0
# Purpose: Calculate partition slices for parallel agent execution
# Category: utilities
#
# Usage: partition-entities.sh --entity-dir <dir> --pattern <glob> --partition-index <n> --total-partitions <total> --json
#
# Arguments:
#   --entity-dir <path>        Entity directory path (required)
#   --pattern <string>         Glob pattern for entity files (required, e.g., "*.md")
#   --partition-index <number> Partition index (required, 0-based)
#   --total-partitions <number> Total number of partitions (required, must be > 0)
#   --json                     Output JSON format (required)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "partition_index": number,
#     "total_partitions": number,
#     "total_entities": number,
#     "partition_size": number,
#     "partition_start": number,
#     "partition_end": number,
#     "entities_in_partition": number,
#     "entity_files": ["array of file paths"]
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - Directory not found
#
# Example:
#   partition-entities.sh --entity-dir "/path/to/project/05-sources" \
#     --pattern "*.md" --partition-index 0 --total-partitions 4 --json

# Note: Uses LC_ALL=C for deterministic ASCII-based sorting to ensure
# consistent partition boundaries regardless of system locale. This is
# critical for German/UTF-8 filenames (ä, ö, ü, ß) to prevent non-deterministic
# partition overlaps or gaps across multiple script invocations.


error_json() {
    jq -n --arg msg "$1" --argjson code "${2:-1}" '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local entity_dir="" pattern="" partition_index="" total_partitions="" json_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --entity-dir) entity_dir="$2"; shift 2 ;;
            --pattern) pattern="$2"; shift 2 ;;
            --partition-index) partition_index="$2"; shift 2 ;;
            --total-partitions) total_partitions="$2"; shift 2 ;;
            --json) json_flag=true; shift ;;
            *) error_json "Unknown argument: $1" 2 ;;
        esac
    done

    # Validate required arguments
    [[ -n "$entity_dir" ]] || error_json "Missing: --entity-dir" 2
    [[ -n "$pattern" ]] || error_json "Missing: --pattern" 2
    [[ -n "$partition_index" ]] || error_json "Missing: --partition-index" 2
    [[ -n "$total_partitions" ]] || error_json "Missing: --total-partitions" 2
    [[ "$json_flag" = true ]] || error_json "Missing: --json" 2

    # Validate json_flag value (defensive check)
    if ! [[ "$json_flag" == "true" ]] && ! [[ "$json_flag" == "false" ]]; then
        error_json "Invalid --json flag value: $json_flag" 2
    fi

    [[ -d "$entity_dir" ]] || error_json "Directory not found: $entity_dir" 3

    # SECURITY FIX (BUG-005): Validate pattern doesn't contain directory traversal sequences
    # Use separate tests to avoid pipe character issues in eval contexts
    if [[ "$pattern" =~ \.\./ ]] || [[ "$pattern" =~ \.\. ]]; then
        error_json "Invalid pattern: contains directory traversal" 1
    fi

    # Validate numeric arguments
    [[ "$partition_index" =~ ^[0-9]+$ ]] || error_json "partition-index must be non-negative integer" 1
    [[ "$total_partitions" =~ ^[0-9]+$ ]] || error_json "total-partitions must be non-negative integer" 1
    [[ "$total_partitions" -gt 0 ]] || error_json "total-partitions must be > 0" 1
    [[ "$partition_index" -lt "$total_partitions" ]] || error_json "partition-index ($partition_index) >= total-partitions ($total_partitions)" 1

    # List all entity files (sorted for deterministic ordering)
    local entity_files=""
    if compgen -G "${entity_dir}/${pattern}" > /dev/null 2>&1; then
        entity_files="$(find "${entity_dir}" -maxdepth 1 -name "${pattern}" -type f 2>/dev/null | LC_ALL=C sort || echo "")"
    fi

    # Count total entities
    local total_entities=0
    [[ -n "$entity_files" ]] && total_entities="$(echo "$entity_files" | grep -c "^" || echo 0)"

    # Handle empty directory
    if [[ "$total_entities" -eq 0 ]]; then
        jq -n --argjson pi "$partition_index" --argjson tp "$total_partitions" \
            '{success: true, partition_index: $pi, total_partitions: $tp, total_entities: 0,
              partition_size: 0, partition_start: 0, partition_end: 0, entities_in_partition: 0, entity_files: []}'
        return 0
    fi

    # Calculate partition size (ceiling division)
    local partition_size=$(( (total_entities + total_partitions - 1) / total_partitions ))
    local start=$(( partition_index * partition_size ))
    local end=$(( start + partition_size ))
    [[ $end -gt $total_entities ]] && end=$total_entities

    # Extract partition slice
    local partition_files="" entities_in_partition=0
    if [[ $start -lt $total_entities ]]; then
        partition_files="$(echo "$entity_files" | tail -n +$((start + 1)) | head -n $((end - start)))"
        entities_in_partition=$((end - start))
    fi

    # Convert to JSON array
    local entity_files_json="[]"
    [[ -n "$partition_files" ]] && entity_files_json="$(echo "$partition_files" | jq -R . | jq -s .)"

    # Output structured JSON
    jq -n \
        --argjson pi "$partition_index" \
        --argjson tp "$total_partitions" \
        --argjson te "$total_entities" \
        --argjson ps "$partition_size" \
        --argjson pstart "$start" \
        --argjson pend "$end" \
        --argjson eip "$entities_in_partition" \
        --argjson files "$entity_files_json" \
        '{success: true, partition_index: $pi, total_partitions: $tp, total_entities: $te,
          partition_size: $ps, partition_start: $pstart, partition_end: $pend,
          entities_in_partition: $eip, entity_files: $files}'
}

main "$@"
