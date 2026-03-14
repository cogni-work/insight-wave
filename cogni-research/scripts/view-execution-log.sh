#!/usr/bin/env bash
set -euo pipefail
# view-execution-log.sh
# Version: 1.0.0
# Purpose: Interactive CLI tool for navigating execution logs
# Category: utilities
#
# Usage: view-execution-log.sh --log-file <path> [OPTIONS]
#
# Arguments:
#   --log-file PATH    Path to execution log file (required)
#   --phase NUMBER     Jump to specific phase (optional)
#   --level LEVEL      Filter by level: ERROR|WARN|INFO|DEBUG|TRACE (optional)
#   --search PATTERN   Search for pattern with context (optional)
#   --no-color         Disable color output (optional)
#   --help             Show this help message
#
# Output:
#   Human-readable log content with optional formatting:
#   - Line numbers prefixed
#   - Color-coded by level (if terminal supports it)
#   - Paginated with less/more if available
#
# Exit codes:
#   0 - Success
#   1 - Log file not found
#   2 - Invalid phase number or arguments
#
# Examples:
#   # View full log with colors
#   view-execution-log.sh --log-file .logs/source-creator-execution-log.txt
#
#   # Show only Phase 3
#   view-execution-log.sh --log-file .logs/fact-checker-execution-log.txt --phase 3
#
#   # Show only errors
#   view-execution-log.sh --log-file .logs/citation-generator-execution-log.txt --level ERROR
#
#   # Search with context
#   view-execution-log.sh --log-file .logs/log.txt --search "validation failed"


# Color codes (ANSI escape sequences)
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_GREEN='\033[0;32m'
COLOR_CYAN='\033[0;36m'
COLOR_GRAY='\033[0;90m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

# Show help message
show_help() {
    cat << 'EOF'
Usage: view-execution-log.sh --log-file PATH [OPTIONS]

Interactive CLI tool for navigating execution logs with phase navigation,
level filtering, search capabilities, and color output.

Options:
  --log-file PATH    Path to execution log file (required)
  --phase N          Show only Phase N
  --level LEVEL      Filter by level (ERROR|WARN|INFO|DEBUG|TRACE)
  --search PATTERN   Search for pattern with 2 lines context
  --no-color         Disable color output
  --help             Show this help message

Examples:
  # View full log with colors
  view-execution-log.sh --log-file .logs/source-creator-execution-log.txt

  # Show only Phase 3
  view-execution-log.sh --log-file .logs/fact-checker-execution-log.txt --phase 3

  # Show only errors
  view-execution-log.sh --log-file .logs/citation-generator-execution-log.txt --level ERROR

  # Search with context
  view-execution-log.sh --log-file .logs/log.txt --search "validation"

  # Combine filters (Phase 2 errors only)
  view-execution-log.sh --log-file .logs/log.txt --phase 2 --level ERROR

Exit codes:
  0 - Success
  1 - Log file not found
  2 - Invalid phase number or arguments

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

# Apply color to line based on log level
colorize_line() {
    local line="$1"
    local use_color="$2"

    if ! [[ "$use_color" == "true" ]]; then
        echo "$line"
        return
    fi

    # Detect log level and apply appropriate color
    if echo "$line" | grep -q "\[ERROR\]"; then
        echo -e "${COLOR_RED}${line}${COLOR_RESET}"
    elif echo "$line" | grep -q "\[WARN\]"; then
        echo -e "${COLOR_YELLOW}${line}${COLOR_RESET}"
    elif echo "$line" | grep -q "\[INFO\]"; then
        echo -e "${COLOR_GREEN}${line}${COLOR_RESET}"
    elif echo "$line" | grep -q "\[DEBUG\]"; then
        echo -e "${COLOR_CYAN}${line}${COLOR_RESET}"
    elif echo "$line" | grep -q "\[TRACE\]"; then
        echo -e "${COLOR_GRAY}${line}${COLOR_RESET}"
    elif echo "$line" | grep -q "Phase [0-9]"; then
        echo -e "${COLOR_BOLD}${line}${COLOR_RESET}"
    else
        echo "$line"
    fi
}

# Extract phase content from log file
extract_phase() {
    local log_file="$1"
    local phase_num="$2"

    # Validate phase number
    [[ "$phase_num" =~ ^[0-9]+$ ]] || error_exit "Invalid phase number: $phase_num" 2

    # Check if phase exists in log (handle format: "Phase N:" anywhere in line)
    if ! grep -q "Phase ${phase_num}:" "$log_file"; then
        error_exit "Phase $phase_num not found in log file" 2
    fi

    # Extract content using sed (more portable than awk with match)
    # Start printing when we see "Phase N:" and stop at next "Phase" or EOF
    sed -n "/Phase ${phase_num}:/,/Phase [0-9]\+:/p" "$log_file" | sed '$d' | grep -v "^$" || true

    # If the phase is the last one, use a different approach
    local last_phase_line="$(grep -n "Phase ${phase_num}:" "$log_file" | tail -1 | cut -d: -f1)"
    local next_phase_line="$(tail -n "+${last_phase_line}" "$log_file" | grep -n "Phase [0-9]\+:" | head -2 | tail -1 | cut -d: -f1)"

    if [[ -z "$next_phase_line" ]]; then
        # This is the last phase - print from phase marker to end
        tail -n "+${last_phase_line}" "$log_file"
    fi
}

# Filter by log level
filter_by_level() {
    local level="$1"

    # Validate level
    case "$level" in
        ERROR|WARN|INFO|DEBUG|TRACE) ;;
        *) error_exit "Invalid level: $level (must be ERROR|WARN|INFO|DEBUG|TRACE)" 2 ;;
    esac

    # Filter lines containing the specified level
    grep "\[${level}\]"
}

# Search with context
search_with_context() {
    local pattern="$1"
    local log_file="$2"

    # Use grep with context (2 lines before and after)
    grep -n -C 2 "$pattern" "$log_file" || {
        echo "No matches found for pattern: $pattern" >&2
        exit 0
    }
}

# Determine best pager available
get_pager() {
    if command -v less >/dev/null 2>&1; then
        echo "less -R"  # -R preserves color codes
    elif command -v more >/dev/null 2>&1; then
        echo "more"
    else
        echo "cat"
    fi
}

# Main function
main() {
    # Parse arguments
    local log_file=""
    local phase_num=""
    local level_filter=""
    local search_pattern=""
    local use_color="true"

    # Check for no arguments
    [[ $# -eq 0 ]] && show_help

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --log-file)
                log_file="$2"
                shift 2
                ;;
            --phase)
                phase_num="$2"
                shift 2
                ;;
            --level)
                level_filter="$2"
                shift 2
                ;;
            --search)
                search_pattern="$2"
                shift 2
                ;;
            --no-color)
                use_color="false"
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
    [[ -n "$log_file" ]] || error_exit "Missing required argument: --log-file (use --help for usage)" 2
    [[ -f "$log_file" ]] || error_exit "Log file not found: $log_file" 1

    # Disable color if terminal doesn't support it
    if [[ "$use_color" == "true" ]] && ! supports_color; then
        use_color="false"
    fi

    # Handle search mode separately
    if [[ -n "$search_pattern" ]]; then
        search_with_context "$search_pattern" "$log_file" | $(get_pager)
        exit 0
    fi

    # Process log file through filter pipeline
    local content=""

    # Step 1: Extract phase if specified
    if [[ -n "$phase_num" ]]; then
        content="$(extract_phase "$log_file" "$phase_num")"
    else
        content="$(cat "$log_file")"
    fi

    # Step 2: Filter by level if specified
    if [[ -n "$level_filter" ]]; then
        content="$(echo "$content" | filter_by_level "$level_filter")"
    fi

    # Step 3: Add line numbers and colorize
    local line_num=1
    local output=""

    while IFS= read -r line; do
        # Skip empty lines from processing
        [[ -z "$line" ]] && continue

        # Add line number
        local numbered_line="$(printf "%5d  %s" "$line_num" "$line")"

        # Colorize if enabled
        local final_line="$(colorize_line "$numbered_line" "$use_color")"

        # Append to output
        if [[ -z "$output" ]]; then
            output="$final_line"
        else
            output="${output}"$'\n'"${final_line}"
        fi

        line_num=$((line_num + 1))
    done <<< "$content"

    # Step 4: Page output if content is long
    if [[ $(echo "$output" | wc -l) -gt $(tput lines 2>/dev/null || echo 24) ]]; then
        echo "$output" | $(get_pager)
    else
        echo "$output"
    fi
}

# Execute main function
main "$@"
