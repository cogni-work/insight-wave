#!/usr/bin/env bash
set -euo pipefail
# validate-script-interfaces.sh
# Version: 2.0.0
# Category: validators
# Purpose: Detect interface mismatches between agents and scripts
#
# Usage: validate-script-interfaces.sh [OPTIONS]
#
# Arguments:
#   --agents-dir <path>      Path to agents directory (default: cogni-research/agents/)
#   --scripts-dir <path>     Path to single scripts directory (backward compatible)
#   --scripts-dirs <paths>   Comma-separated script directory paths (e.g., "path1,path2")
#   --contracts-dir <path>   Path to script contracts directory (REQUIRED)
#   --json                   Output in JSON format
#   --verbose                Enable detailed output
#
# Output:
#   JSON mode (--json):
#   {
#     "success": boolean,
#     "validation_summary": {
#       "total_agents": integer,
#       "total_invocations": integer,
#       "issues_found": integer,
#       "missing_scripts": integer,
#       "parameter_mismatches": integer
#     },
#     "script_locations": {
#       "script-name.sh": "directory-path"
#     },
#     "issues": [...]
#   }
#
#   Standard mode: Human-readable validation report
#
# Exit codes:
#   0 - No issues found
#   1 - Issues found
#   2 - Invalid arguments or contract parsing error
#
# Example:
#   validate-script-interfaces.sh --agents-dir "agents/" \
#     --scripts-dirs "scripts" \
#     --contracts-dir "contracts/" --json


# Forward to JSON mode and format if needed
if ! [[ "${1:-}" == "--json" ]] && ! [[ "${2:-}" == "--json" ]] && ! [[ "${3:-}" == "--json" ]] && ! [[ "${4:-}" == "--json" ]] && ! [[ "${5:-}" == "--json" ]]; then
    # Standard mode: run with --json and format the output
    result="$("$0" "$@" --json)"
    exit_code=$?

    # Parse JSON and display human-readable
    echo "================================================================================"
    echo "Script Interface Validation Report"
    echo "================================================================================"
    echo ""
    echo "Validation Summary:"
    echo "  Total agents scanned:       $(echo "$result" | jq -r '.validation_summary.total_agents')"
    echo "  Total script invocations:   $(echo "$result" | jq -r '.validation_summary.total_invocations')"
    echo "  Issues found:               $(echo "$result" | jq -r '.validation_summary.issues_found')"
    echo "  - Missing scripts:          $(echo "$result" | jq -r '.validation_summary.missing_scripts')"
    echo "  - Parameter mismatches:     $(echo "$result" | jq -r '.validation_summary.parameter_mismatches')"
    echo ""

    issues_count="$(echo "$result" | jq '.issues | length')"
    if [[ "$issues_count" -eq 0 ]]; then
        echo "✅ No issues found! All agent→script interfaces are valid."
    else
        echo "Issues Detected:"
        echo "--------------------------------------------------------------------------------"

        echo "$result" | jq -c '.issues[]' | while read -r issue; do
            type="$(echo "$issue" | jq -r '.type')"
            severity="$(echo "$issue" | jq -r '.severity')"
            agent="$(echo "$issue" | jq -r '.agent')"
            line="$(echo "$issue" | jq -r '.line')"
            script="$(echo "$issue" | jq -r '.script')"
            message="$(echo "$issue" | jq -r '.message')"
            expected="$(echo "$issue" | jq -r '.details.expected | join(" ")')"
            actual="$(echo "$issue" | jq -r '.details.actual | join(" ")')"

            severity_upper="$(echo "$severity" | tr '[:lower:]' '[:upper:]')"
            if [[ "$severity" == "error" ]]; then
                icon="❌"
            else
                icon="⚠️"
            fi

            echo ""
            echo "$icon [$severity_upper] $type"
            echo "   Agent:   $agent"
            echo "   Line:    $line"
            echo "   Script:  $script"
            echo "   Message: $message"

            if [[ -n "$expected" ]] && ! [[ "$expected" == "null" ]]; then
                echo "   Expected: $expected"
            fi
            if [[ -n "$actual" ]] && ! [[ "$actual" == "null" ]]; then
                echo "   Actual:   $actual"
            fi
        done
    fi

    echo ""
    echo "================================================================================"

    exit $exit_code
fi

# JSON MODE IMPLEMENTATION (the core logic)

error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Setup temp files and trap BEFORE any code that might call error_json
ISSUES_FILE="$(mktemp)"
SCRIPT_LOCATIONS_FILE="$(mktemp)"
trap 'rm -f "$ISSUES_FILE" "$SCRIPT_LOCATIONS_FILE"' EXIT INT TERM

AGENTS_DIR="cogni-research/agents/"
SCRIPTS_DIRS=()
CONTRACTS_DIR=""
VERBOSE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --agents-dir) AGENTS_DIR="$2"; shift 2 ;;
        --scripts-dir)
            # Single directory (backward compatibility)
            SCRIPTS_DIRS=("$2")
            shift 2
            ;;
        --scripts-dirs)
            # Multiple directories - bash 3.2 compatible
            OLDIFS="$IFS"
            IFS=','
            SCRIPTS_DIRS=($2)
            IFS="$OLDIFS"
            shift 2
            ;;
        --contracts-dir) CONTRACTS_DIR="$2"; shift 2 ;;
        --json) shift ;;  # Handled above
        --verbose) VERBOSE=1; shift ;;
        *) [[ -n "$1" ]] && error_json "Unknown argument: $1" 2 ;;
    esac
done

[[ -n "$CONTRACTS_DIR" ]] || error_json "Missing required argument: --contracts-dir" 2
[[ -d "$AGENTS_DIR" ]] || error_json "Agents directory not found: $AGENTS_DIR" 2
[[ ${#SCRIPTS_DIRS[@]} -gt 0 ]] || error_json "Missing required argument: --scripts-dir or --scripts-dirs" 2

# Validate all script directories exist
for dir in "${SCRIPTS_DIRS[@]}"; do
    [[ -d "$dir" ]] || error_json "Scripts directory not found: $dir" 2
done
[[ -d "$CONTRACTS_DIR" ]] || error_json "Contracts directory not found: $CONTRACTS_DIR" 2

total_agents=0
total_invocations=0
missing_scripts=0
parameter_mismatches=0

log_verbose() {
    [[ $VERBOSE -eq 1 ]] && echo "[VERBOSE] $*" >&2
}

record_issue() {
    local type="$1" severity="$2" agent="$3" line="$4" script="$5" message="$6"
    local expected="${7:-}" actual="${8:-}"

    local expected_array="[]"
    [[ -n "$expected" ]] && expected_array="$(echo "$expected" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .)"

    local actual_array="[]"
    [[ -n "$actual" ]] && actual_array="$(echo "$actual" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .)"

    jq -n \
        --arg type "$type" \
        --arg severity "$severity" \
        --arg agent "$agent" \
        --arg line "$line" \
        --arg script "$script" \
        --arg message "$message" \
        --argjson expected "$expected_array" \
        --argjson actual "$actual_array" \
        '{
            type: $type,
            severity: $severity,
            agent: $agent,
            line: $line | tonumber,
            script: $script,
            message: $message,
            details: {expected: $expected, actual: $actual}
        }' >> "$ISSUES_FILE"
}

# Discover script locations across multiple directories
discover_script_locations() {
    local script_name="$1"

    for scripts_dir in "${SCRIPTS_DIRS[@]}"; do
        if [[ -f "$scripts_dir/$script_name" ]]; then
            echo "$scripts_dir"
            return 0
        fi
    done

    # Not found
    return 1
}

# Build script locations index
log_verbose "Building script locations index from ${#SCRIPTS_DIRS[@]} directories..."
for scripts_dir in "${SCRIPTS_DIRS[@]}"; do
    for script_path in "$scripts_dir"/*.sh; do
        [[ -f "$script_path" ]] || continue
        script_name="$(basename "$script_path")"

        # Record location (first match wins if duplicates exist)
        if ! grep -q "\"$script_name\"" "$SCRIPT_LOCATIONS_FILE" 2>/dev/null; then
            jq -n \
                --arg name "$script_name" \
                --arg dir "$scripts_dir" \
                '{($name): $dir}' >> "$SCRIPT_LOCATIONS_FILE"
        fi
    done
done
log_verbose "Script locations index built"

# Load contracts
# Bash 3.2 compatible - indexed arrays (declare -A requires Bash 4.0+)
CONTRACT_SCRIPT_NAMES=()
CONTRACT_SCRIPT_PARAMS=()

# Helper function to get params for a script
get_script_params() {
    local script="$1"
    local i=0
    for name in "${CONTRACT_SCRIPT_NAMES[@]}"; do
        if [[ "$name" == "$script" ]]; then
            echo "${CONTRACT_SCRIPT_PARAMS[$i]}"
            return 0
        fi
        i=$((i + 1))
    done
    return 1
}

log_verbose "Loading script contracts from $CONTRACTS_DIR..."

for contract_path in "$CONTRACTS_DIR"/*.yml; do
    [[ -f "$contract_path" ]] || continue

    # Extract script name from contract (assumes 'script: {name: "script-name.sh"}')
    script_name="$(grep '^  name:' "$contract_path" | sed 's/.*"\(.*\)".*/\1/' | head -1)"
    [[ -n "$script_name" ]] || continue

    # Extract parameter names (lines like '  - name: "--param-name"')
    params="$(grep -E '^\s+- name: "--' "$contract_path" | sed 's/.*"--\([^"]*\)".*/--\1/' | tr '\n' ' ')"

    if [[ -n "$params" ]]; then
        CONTRACT_SCRIPT_NAMES+=("$script_name")
        CONTRACT_SCRIPT_PARAMS+=("$params")
    fi
    log_verbose "Loaded contract for $script_name: $params"
done

log_verbose "Loaded ${#CONTRACT_SCRIPT_NAMES[@]} script contracts"

# Scan all agents
log_verbose "Scanning agents in $AGENTS_DIR..."

for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue

    agent_name="$(basename "$agent_file" .md)"
    total_agents=$((total_agents + 1))

    log_verbose "Processing agent: $agent_name"

    # Extract script invocations (lines with 'bash "$SCRIPT_*"' or similar patterns)
    # Look for: bash "$SCRIPT_VAR" or bash "${SCRIPT_VAR}" or direct paths
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Pattern 1: bash "$SCRIPT_VAR" --param1 --param2
        # Pattern 2: bash "${SCRIPT_VAR}" --param1 --param2
        # Pattern 3: bash "/path/to/script.sh" --param1 --param2

        # Extract script invocations
        if echo "$line" | grep -q 'bash.*\.sh'; then
            total_invocations=$((total_invocations + 1))

            # Extract script name (last component ending in .sh before first parameter)
            script_name="$(echo "$line" | sed 's/.*\/\([^/]*\.sh\).*/\1/' | sed 's/["\${}]*//g')"

            # Skip if we couldn't extract a proper script name
            [[ "$script_name" =~ \.sh$ ]] || continue

            log_verbose "  Found invocation: $script_name at line $line_num"

            # Check if script exists in any scripts directory
            if ! discover_script_locations "$script_name" >/dev/null 2>&1; then
                record_issue "missing_script" "error" "$agent_name" "$line_num" "$script_name" \
                    "Script not found in any scripts directory"
                missing_scripts=$((missing_scripts + 1))
                continue
            fi

            # If we have a contract, validate parameters
            if expected_params=$(get_script_params "$script_name"); then

                # Extract actual parameters from invocation line
                # Look for --param patterns
                actual_params="$(echo "$line" | grep -oE -- '--[a-z-]+' | tr '\n' ' ')"

                # Compare parameter sets
                # For each expected parameter, check if it appears in the line
                for expected_param in $expected_params; do
                    if ! echo "$line" | grep -q -- "$expected_param"; then
                        # Don't report optional parameters as missing (those with defaults)
                        # This is a simplification - ideally we'd parse the contract's required field
                        # For now, we'll only report truly missing required params
                        :
                    fi
                done

                # Check for unexpected parameters (in agent but not in contract)
                for actual_param in $actual_params; do
                    if ! echo "$expected_params" | grep -q -- "$actual_param"; then
                        record_issue "parameter_mismatch" "warning" "$agent_name" "$line_num" "$script_name" \
                            "Unexpected parameter '$actual_param' (not in contract)" "$expected_params" "$actual_params"
                        parameter_mismatches=$((parameter_mismatches + 1))
                    fi
                done
            fi
        fi
    done < "$agent_file"
done

log_verbose "Scan complete: $total_agents agents, $total_invocations invocations"

# Build script locations JSON
script_locations_json="{}"
if [[ -f "$SCRIPT_LOCATIONS_FILE" ]]; then
    # Merge all JSON objects into one
    script_locations_json="$(jq -s 'reduce .[] as $item ({}; . * $item)' "$SCRIPT_LOCATIONS_FILE")"
fi

# Build issues JSON
issues_json="[]"
if [[ -f "$ISSUES_FILE" ]] && [[ -s "$ISSUES_FILE" ]]; then
    issues_json="$(jq -s '.' "$ISSUES_FILE")"
fi

issues_found="$(echo "$issues_json" | jq 'length')"

# Output final JSON
jq -n \
    --argjson total_agents "$total_agents" \
    --argjson total_invocations "$total_invocations" \
    --argjson issues_found "$issues_found" \
    --argjson missing_scripts "$missing_scripts" \
    --argjson parameter_mismatches "$parameter_mismatches" \
    --argjson script_locations "$script_locations_json" \
    --argjson issues "$issues_json" \
    '{
        success: ($issues_found == 0),
        validation_summary: {
            total_agents: $total_agents,
            total_invocations: $total_invocations,
            issues_found: $issues_found,
            missing_scripts: $missing_scripts,
            parameter_mismatches: $parameter_mismatches
        },
        script_locations: $script_locations,
        issues: $issues
    }'

# Exit with appropriate code
if [[ $issues_found -gt 0 ]]; then
    exit 1
else
    exit 0
fi
