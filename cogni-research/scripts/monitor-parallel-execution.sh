#!/usr/bin/env bash
set -euo pipefail
# monitor-parallel-execution.sh
# Version: 1.0.0
# Purpose: Interactive monitoring dashboard for parallel execution logs
# Category: interactive-utilities
#
# ARCHITECTURAL NOTE:
# This is an INTERACTIVE UTILITY TOOL for human operators, not a computational
# service script. Similar to view-execution-log.sh, it provides real-time
# monitoring with orchestration logic for user experience (dashboard rendering,
# live polling, color-coded status updates). Higher complexity (score 5) is
# acceptable for interactive dashboard tools that prioritize UX over the
# single-responsibility principle of service scripts.
#
# Usage: monitor-parallel-execution.sh --log-dir <path> [OPTIONS]
#
# Arguments:
#   --log-dir <path>       Directory containing partition log files (required)
#   --interval <number>    Poll interval in seconds (optional, default: 1)
#   --no-color             Disable color output (optional)
#   --json                 Output final summary as JSON instead of dashboard (optional)
#   --help                 Show this help message
#
# Output:
#   Real-time dashboard display (refreshed every interval):
#   - Overall progress (completed/total partitions)
#   - Per-partition status (phase, progress, errors)
#   - Color-coded status indicators
#   - Auto-exit when all partitions complete
#
#   With --json flag: JSON summary on completion
#   {
#     "success": true,
#     "data": {
#       "total_partitions": <number>,
#       "completed": <number>,
#       "failed": <number>,
#       "duration_seconds": <number>,
#       "partitions": [
#         {
#           "partition_id": <string>,
#           "status": "completed|failed|running",
#           "current_phase": <string>,
#           "error_count": <number>
#         }
#       ]
#     }
#   }
#
# Exit codes:
#   0 - All partitions completed successfully
#   1 - One or more partitions failed
#   2 - Invalid arguments or log directory not found
#
# Examples:
#   # Monitor with default 1-second polling
#   monitor-parallel-execution.sh --log-dir .logs/
#
#   # Monitor with 2-second polling
#   monitor-parallel-execution.sh --log-dir .logs/ --interval 2
#
#   # Monitor and output JSON summary
#   monitor-parallel-execution.sh --log-dir .logs/ --json
#
#   # Monitor without colors (for logging to file)
#   monitor-parallel-execution.sh --log-dir .logs/ --no-color


# Color codes (ANSI escape sequences)
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_GREEN='\033[0;32m'
COLOR_CYAN='\033[0;36m'
COLOR_BLUE='\033[0;34m'
COLOR_GRAY='\033[0;90m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

# Status icons
ICON_RUNNING="⏳"
ICON_COMPLETED="✅"
ICON_FAILED="❌"
ICON_WAITING="⏸️"

# Show help message
show_help() {
    cat << 'EOF'
Usage: monitor-parallel-execution.sh --log-dir PATH [OPTIONS]

Interactive monitoring dashboard for parallel execution of partition workers.
Polls log files every interval and displays real-time progress with color-coded
status updates. Auto-exits when all partitions complete.

Options:
  --log-dir PATH        Directory containing partition log files (required)
  --interval N          Poll interval in seconds (optional, default: 1)
  --no-color            Disable color output
  --json                Output final summary as JSON instead of dashboard
  --help                Show this help message

Examples:
  # Monitor with default 1-second polling
  monitor-parallel-execution.sh --log-dir .logs/

  # Monitor with 2-second polling
  monitor-parallel-execution.sh --log-dir .logs/ --interval 2

  # Monitor and output JSON summary
  monitor-parallel-execution.sh --log-dir .logs/ --json

  # Monitor without colors (for logging to file)
  monitor-parallel-execution.sh --log-dir .logs/ --no-color

Exit codes:
  0 - All partitions completed successfully
  1 - One or more partitions failed
  2 - Invalid arguments or log directory not found

EOF
    exit 0
}

# Error handler
error_exit() {
    echo "ERROR: $1" >&2
    exit "${2:-1}"
}

# Detect if terminal supports colors
supports_color() {
    [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && ! [[ "$TERM" == "dumb" ]]
}

# Parse partition log file to extract status information
parse_partition_log() {
    local log_file="$1"
    local partition_id="$2"

    # Initialize with defaults
    local partition_status="waiting"
    local current_phase="Not started"
    local error_count=0
    local last_line=""

    # Check if log file exists and is readable
    if [[ ! -f "$log_file" ]]; then
        echo "$partition_id|waiting|Not started|0|"
        return
    fi

    # Read log file and extract latest state
    # Look for phase markers, completion markers, error counts
    local phase_markers=()

    while IFS= read -r line; do
        # Track last non-empty line
        [[ -n "$line" ]] && last_line="$line"

        # Extract phase information (bash 3.2 compatible)
        if echo "$line" | grep -q "Phase [0-9]\+:"; then
            local phase="$(echo "$line" | grep -o "Phase [0-9]\+" | grep -o "[0-9]\+")"
            phase_markers+=("$phase")
        fi

        # Count errors
        if echo "$line" | grep -q "\[ERROR\]"; then
            error_count=$((error_count + 1))
        fi

        # Check for completion
        if echo "$line" | grep -q "Partition.*completed successfully"; then
            partition_status="completed"
        fi

        # Check for failure
        if echo "$line" | grep -q "Partition.*failed"; then
            partition_status="failed"
        fi
    done < "$log_file"

    # Determine current phase
    if [[ ${#phase_markers[@]} -gt 0 ]]; then
        local latest_phase="${phase_markers[${#phase_markers[@]}-1]}"
        current_phase="Phase $latest_phase"

        # If not completed or failed, partition_status is running
        if ! [[ "$partition_status" == "completed" ]] && ! [[ "$partition_status" == "failed" ]]; then
            partition_status="running"
        fi
    elif [[ -n "$last_line" ]] && ! [[ "$partition_status" == "completed" ]] && ! [[ "$partition_status" == "failed" ]]; then
        partition_status="running"
        current_phase="Initializing"
    fi

    # Output: partition_id|partition_status|current_phase|error_count|last_line
    echo "$partition_id|$partition_status|$current_phase|$error_count|$last_line"
}

# Render dashboard with current status
render_dashboard() {
    local log_dir="$1"
    local use_color="$2"
    local partition_data="$3"  # Array of parsed partition info

    # Clear screen
    clear

    # Header
    local header="═══ Parallel Execution Monitor ═══"
    if [[ "$use_color" == "true" ]]; then
        echo -e "${COLOR_BOLD}${header}${COLOR_RESET}"
    else
        echo "$header"
    fi
    echo ""

    # Parse partition data and calculate summary
    local total=0
    local completed=0
    local failed=0
    local running=0
    local waiting=0

    while IFS='|' read -r pid status phase errors last; do
        total=$((total + 1))
        case "$status" in
            completed) completed=$((completed + 1)) ;;
            failed) failed=$((failed + 1)) ;;
            running) running=$((running + 1)) ;;
            waiting) waiting=$((waiting + 1)) ;;
        esac
    done <<< "$partition_data"

    # Summary line
    local summary="Progress: $completed/$total completed"
    if [[ $failed -gt 0 ]]; then
        summary="$summary, $failed failed"
    fi
    if [[ $running -gt 0 ]]; then
        summary="$summary, $running running"
    fi

    if [[ "$use_color" == "true" ]]; then
        echo -e "${COLOR_CYAN}${summary}${COLOR_RESET}"
    else
        echo "$summary"
    fi
    echo ""

    # Progress bar
    local bar_width=50
    local progress_percent=0
    if [[ $total -gt 0 ]]; then
        progress_percent=$((completed * 100 / total))
    fi
    local filled=$((progress_percent * bar_width / 100))
    local empty=$((bar_width - filled))

    local bar="["
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    bar="${bar}] ${progress_percent}%"

    if [[ "$use_color" == "true" ]]; then
        if [[ $failed -gt 0 ]]; then
            echo -e "${COLOR_RED}${bar}${COLOR_RESET}"
        else
            echo -e "${COLOR_GREEN}${bar}${COLOR_RESET}"
        fi
    else
        echo "$bar"
    fi
    echo ""

    # Partition details table
    echo "Partition Status:"
    echo "────────────────────────────────────────────────────────────────"
    printf "%-15s %-12s %-20s %-8s\n" "Partition" "Status" "Phase" "Errors"
    echo "────────────────────────────────────────────────────────────────"

    while IFS='|' read -r pid status phase errors last; do
        # Select icon and color
        local icon=""
        local color="${COLOR_RESET}"

        case "$status" in
            completed)
                icon="$ICON_COMPLETED"
                color="$COLOR_GREEN"
                ;;
            failed)
                icon="$ICON_FAILED"
                color="$COLOR_RED"
                ;;
            running)
                icon="$ICON_RUNNING"
                color="$COLOR_CYAN"
                ;;
            waiting)
                icon="$ICON_WAITING"
                color="$COLOR_GRAY"
                ;;
        esac

        # Format status with icon
        local status_display="$icon $status"

        # Format line
        local line="$(printf "%-15s %-12s %-20s %-8s" "$pid" "$status_display" "$phase" "$errors")"

        # Apply color
        if [[ "$use_color" == "true" ]]; then
            echo -e "${color}${line}${COLOR_RESET}"
        else
            echo "$line"
        fi
    done <<< "$partition_data"

    echo ""
    echo "Press Ctrl+C to exit"
}

# Generate JSON summary
generate_json_summary() {
    local partition_data="$1"
    local duration="$2"

    # Build partitions array
    local partitions_json="["
    local first=true

    while IFS='|' read -r pid status phase errors last; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            partitions_json="${partitions_json},"
        fi

        partitions_json="${partitions_json}{\"partition_id\":\"$pid\",\"status\":\"$status\",\"current_phase\":\"$phase\",\"error_count\":$errors}"
    done <<< "$partition_data"

    partitions_json="${partitions_json}]"

    # Count totals
    local total=0
    local completed=0
    local failed=0

    while IFS='|' read -r pid status phase errors last; do
        total=$((total + 1))
        [[ "$status" == "completed" ]] && completed=$((completed + 1))
        [[ "$status" == "failed" ]] && failed=$((failed + 1))
    done <<< "$partition_data"

    # Determine overall success
    local success="true"
    [[ $failed -gt 0 ]] && success="false"

    # Output JSON using jq
    jq -n \
        --argjson success "$success" \
        --argjson total "$total" \
        --argjson completed "$completed" \
        --argjson failed "$failed" \
        --argjson duration "$duration" \
        --argjson partitions "$partitions_json" \
        '{
            success: $success,
            data: {
                total_partitions: $total,
                completed: $completed,
                failed: $failed,
                duration_seconds: $duration,
                partitions: $partitions
            }
        }'
}

# Main monitoring loop
monitor_execution() {
    local log_dir="$1"
    local interval="$2"
    local use_color="$3"
    local json_output="$4"

    local start_time="$(date +%s)"
    local all_done=false

    while [[ "$all_done" == "false" ]]; do
        # Find all partition log files
        local log_files=()
        while IFS= read -r file; do
            log_files+=("$file")
        done < <(find "$log_dir" -name "partition-*-execution-log.txt" 2>/dev/null | sort)

        # If no log files found, wait and retry
        if [[ ${#log_files[@]} -eq 0 ]]; then
            if ! [[ "$json_output" == "true" ]]; then
                echo "Waiting for partition log files in $log_dir..."
            fi
            sleep "$interval"
            continue
        fi

        # BUG-034-A FIX: Array accumulation instead of string concatenation (O(n²) → O(n))
        # Parse all partition logs into array
        local partition_data_array=()
        for log_file in "${log_files[@]}"; do
            local partition_id="$(basename "$log_file" | sed 's/partition-\(.*\)-execution-log.txt/\1/')"
            local parsed="$(parse_partition_log "$log_file" "$partition_id")"
            partition_data_array+=("$parsed")
        done

        # Join array into newline-separated string (single printf operation)
        local partition_data
        partition_data="$(printf '%s\n' "${partition_data_array[@]}")"

        # Check if all partitions are done (completed or failed)
        local done_count=0
        local total_count=0

        while IFS='|' read -r pid status phase errors last; do
            total_count=$((total_count + 1))
            if [[ "$status" == "completed" ]] || [[ "$status" == "failed" ]]; then
                done_count=$((done_count + 1))
            fi
        done <<< "$partition_data"

        if [[ $done_count -eq $total_count ]] && [[ $total_count -gt 0 ]]; then
            all_done=true
        fi

        # Render dashboard or wait
        if ! [[ "$json_output" == "true" ]]; then
            render_dashboard "$log_dir" "$use_color" "$partition_data"
        fi

        # Sleep before next poll (unless done)
        if ! [[ "$all_done" == "true" ]]; then
            sleep "$interval"
        fi
    done

    # Calculate duration
    local end_time="$(date +%s)"
    local duration=$((end_time - start_time))

    # Output final result
    if [[ "$json_output" == "true" ]]; then
        generate_json_summary "$partition_data" "$duration"
    else
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "Monitoring complete. Duration: ${duration}s"
        echo "════════════════════════════════════════════════════════════════"
    fi

    # Determine exit code
    local failed_count=0
    while IFS='|' read -r pid status phase errors last; do
        [[ "$status" == "failed" ]] && failed_count=$((failed_count + 1))
    done <<< "$partition_data"

    if [[ $failed_count -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Main function
main() {
    # Parse arguments
    local log_dir=""
    local interval=1
    local use_color="true"
    local json_output="false"

    # Check for no arguments
    [[ $# -eq 0 ]] && show_help

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --log-dir)
                log_dir="$2"
                shift 2
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            --no-color)
                use_color="false"
                shift
                ;;
            --json)
                json_output="true"
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                error_exit "Unknown argument: $1 (use --help for usage)" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$log_dir" ]] || error_exit "Missing required argument: --log-dir (use --help for usage)" 2
    [[ -d "$log_dir" ]] || error_exit "Log directory not found: $log_dir" 2

    # Validate interval is a number
    [[ "$interval" =~ ^[0-9]+$ ]] || error_exit "Invalid interval: $interval (must be a positive integer)" 2
    [[ $interval -gt 0 ]] || error_exit "Invalid interval: $interval (must be greater than 0)" 2

    # Validate json_output flag value
    if [[ -n "$json_output" ]] && ! [[ "$json_output" == "true" ]] && ! [[ "$json_output" == "false" ]]; then
        error_exit "Invalid --json flag value: $json_output" 2
    fi

    # Disable color if terminal doesn't support it
    if [[ "$use_color" == "true" ]] && ! supports_color; then
        use_color="false"
    fi

    # Start monitoring
    monitor_execution "$log_dir" "$interval" "$use_color" "$json_output"
}

# Execute main function
main "$@"
