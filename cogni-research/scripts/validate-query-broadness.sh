#!/usr/bin/env bash
set -euo pipefail
# validate-query-broadness.sh
# Version: 1.0.0
# Purpose: Analyze search query complexity and estimate success probability
#
# Usage:
#   validate-query-broadness.sh <query>
#   echo "<query>" | validate-query-broadness.sh
#   validate-query-broadness.sh --help
#
# Arguments:
#   query    Search query string (via $1 or stdin)
#   --help   Display usage information
#
# Output (JSON): {query, broadness_score (0-100), probability (LOW|MEDIUM|HIGH), analysis, recommendation}
#
# Exit codes: 0=success, 1=validation error, 2=missing arguments
#
# Scoring: Base 100, penalties for: 3 terms (-20), 4+ terms (-40), site: operator (-10 or -35),
#          date filters (-20), site:scholar.google.com (-15), 3+ technical terms (-25)
#
# Examples:
#   validate-query-broadness.sh "machine learning"
#   echo "site:arxiv.org quantum computing" | validate-query-broadness.sh


error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

show_help() {
    cat << 'EOF'
validate-query-broadness.sh - Search Query Complexity Analyzer

Usage:
  validate-query-broadness.sh <query>
  echo "<query>" | validate-query-broadness.sh

Scoring (penalties from base 100):
  - 3 terms (-20), 4+ terms (-40)
  - site: operator with 1-2 terms (-10), with 3+ terms (-35)
  - Date filters (-20), site:scholar.google.com (-15), 3+ technical terms (-25)

Probability: HIGH (75-100), MEDIUM (50-74), LOW (0-49)

Examples:
  validate-query-broadness.sh "machine learning"
  echo "site:arxiv.org neural networks" | validate-query-broadness.sh
EOF
    exit 0
}

main() {
    local query=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help) show_help ;;
            -*) error_json "Unknown flag: $1" 2 ;;
            *) query="$1"; shift ;;
        esac
    done

    # Get input from stdin if not provided as argument
    if [[ -z "$query" ]]; then
        [[ -t 0 ]] && error_json "No query provided. Use --help for usage." 2
        query="$(cat | tr -d '\r\t\n')"
    fi

    # Validate and trim
    query="$(echo "$query" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$query" ]] && error_json "Query cannot be empty" 1

    # Initialize analysis
    local base_score=100 total_penalty=0 term_count=0
    local has_site_operator=false has_date_filter=false has_scholar_operator=false
    local penalties=()

    # Pattern detection
    echo "$query" | grep -q "site:" && has_site_operator=true
    echo "$query" | grep -qE "after:|before:|\\b202[45]\\b" && has_date_filter=true
    echo "$query" | grep -q "site:scholar.google.com" && has_scholar_operator=true

    # Count terms (quoted phrases count as 1, exclude operators)
    local query_cleaned="$query"
    local quoted_phrase_count="$(echo "$query" | grep -o '"[^"]*"' | wc -l | tr -d ' ')"

    query_cleaned="$(echo "$query" | sed 's/"[^"]*"//g')"
    query_cleaned="$(echo "$query_cleaned" | sed 's/site:[^[:space:]]*//g; s/after:[^[:space:]]*//g; s/before:[^[:space:]]*//g; s/\\b202[45]\\b//g')"
    query_cleaned="$(echo "$query_cleaned" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    local word_count=0
    [[ -n "$query_cleaned" ]] && word_count="$(echo "$query_cleaned" | wc -w | tr -d ' ')"
    term_count=$((quoted_phrase_count + word_count))

    # Apply penalties
    if [[ $term_count -ge 4 ]]; then
        total_penalty=$((total_penalty + 40))
        penalties+=("term_count_4plus")
    elif [[ $term_count -eq 3 ]]; then
        total_penalty=$((total_penalty + 20))
        penalties+=("term_count_3")
    fi

    if [[ "$has_site_operator" == true ]]; then
        if [[ $term_count -ge 3 ]]; then
            total_penalty=$((total_penalty + 35))
            penalties+=("site_operator_3plus_terms")
        else
            total_penalty=$((total_penalty + 10))
            penalties+=("site_operator_1_2_terms")
        fi
    fi

    [[ "$has_date_filter" == true ]] && total_penalty=$((total_penalty + 20)) && penalties+=("date_filter")
    [[ "$has_scholar_operator" == true ]] && total_penalty=$((total_penalty + 15)) && penalties+=("scholar_operator")

    # Technical terms detection (count matches in combined pattern)
    local query_lower="$(echo "$query" | tr '[:upper:]' '[:lower:]')"
    local technical_count="$(echo "$query_lower" | grep -oE "neural|algorithm|optimization|framework|implementation|architecture|transformer|quantum|distributed|scalability" | wc -l | tr -d ' ')"

    if [[ $technical_count -ge 3 ]]; then
        total_penalty=$((total_penalty + 25))
        penalties+=("technical_complexity")
    fi

    # Calculate score
    local broadness_score=$((base_score - total_penalty))
    [[ $broadness_score -lt 0 ]] && broadness_score=0

    # Classify probability
    local probability="LOW"
    [[ $broadness_score -ge 75 ]] && probability="HIGH"
    [[ $broadness_score -ge 50 ]] && [[ $broadness_score -lt 75 ]] && probability="MEDIUM"

    # Generate recommendation
    local recommendation="Query is appropriately broad for search."
    if [[ $broadness_score -lt 50 ]]; then
        recommendation="Query is too specific. Consider: removing site operator, reducing term count to 2, or removing date filters."
    elif [[ $broadness_score -lt 75 ]]; then
        recommendation="Query has moderate complexity. Consider simplifying by removing operators or reducing terms."
    fi

    # Build penalties JSON array
    local penalties_json="[]"
    if [[ ${#penalties[@]} -gt 0 ]]; then
        penalties_json="["
        local first=true
        for penalty in "${penalties[@]}"; do
            [[ "$first" == true ]] && penalties_json="${penalties_json}\"${penalty}\"" && first=false || penalties_json="${penalties_json}, \"${penalty}\""
        done
        penalties_json="${penalties_json}]"
    fi

    # Output JSON
    jq -n \
        --arg query "$query" \
        --argjson score "$broadness_score" \
        --arg prob "$probability" \
        --argjson term_count "$term_count" \
        --arg site_op "$has_site_operator" \
        --arg date_filter "$has_date_filter" \
        --arg scholar_op "$has_scholar_operator" \
        --argjson total_penalty "$total_penalty" \
        --arg recommendation "$recommendation" \
        --argjson penalties "$penalties_json" \
        '{
            query: $query,
            broadness_score: $score,
            probability: $prob,
            analysis: {
                term_count: $term_count,
                has_site_operator: ($site_op == "true"),
                has_date_filter: ($date_filter == "true"),
                has_scholar_operator: ($scholar_op == "true"),
                penalties_applied: $penalties,
                total_penalty: $total_penalty
            },
            recommendation: $recommendation
        }'
}

main "$@"
