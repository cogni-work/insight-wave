#!/usr/bin/env bash
set -euo pipefail
# validate-template-adherence.sh
# Version: 1.0.0
# Purpose: Validates synthesis documents follow expected template structure
#
# Usage:
#   ./validate-template-adherence.sh --project-path <path> --research-type <type> --document-type <type> --document-path <path> [--json]
#
# Arguments:
#   --project-path <path>      Research project directory (required)
#   --research-type <string>   One of: action-oriented-radar, trend-radar, lean-canvas (required)
#   --document-type <string>   One of: executive, findings, dimensions, evidence, readme (required)
#   --document-path <path>     Path to synthesis document relative to project (required)
#   --json                     Output JSON format (optional, default: human-readable)
#
# Output:
#   JSON format: {success: bool, validation_status: string, research_type: string, document_type: string, document_path: string, missing_sections: array, warnings: array, metrics: object, timestamp: string}
#   Human format: Readable validation report with sections and metrics
#
# Exit codes:
#   0 - Validation passed (all required sections found)
#   1 - Validation warnings (some sections missing but non-critical)
#   2 - Invalid parameters
#   3 - Document not found
#
# Example:
#   ./validate-template-adherence.sh \
#     --project-path /path/to/project \
#     --research-type action-oriented-radar \
#     --document-type executive \
#     --document-path research-hub.md


# Error handling
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Parse arguments
PROJECT_PATH=""
RESEARCH_TYPE=""
DOCUMENT_TYPE=""
DOCUMENT_PATH=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --research-type)
            RESEARCH_TYPE="$2"
            shift 2
            ;;
        --document-type)
            DOCUMENT_TYPE="$2"
            shift 2
            ;;
        --document-path)
            DOCUMENT_PATH="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            error_json "Unknown parameter: $1" 2
            ;;
    esac
done

# Validate required parameters
[[ -z "$PROJECT_PATH" ]] && error_json "Missing required parameter: --project-path" 2
[[ -z "$RESEARCH_TYPE" ]] && error_json "Missing required parameter: --research-type" 2
[[ -z "$DOCUMENT_TYPE" ]] && error_json "Missing required parameter: --document-type" 2
[[ -z "$DOCUMENT_PATH" ]] && error_json "Missing required parameter: --document-path" 2

# Validate research type
case "$RESEARCH_TYPE" in
    action-oriented-radar|trend-radar|lean-canvas)
        ;;
    *)
        error_json "Invalid research-type: $RESEARCH_TYPE. Must be one of: action-oriented-radar, trend-radar, lean-canvas" 2
        ;;
esac

# Validate document type
case "$DOCUMENT_TYPE" in
    executive|findings|dimensions|evidence|readme)
        ;;
    *)
        error_json "Invalid document-type: $DOCUMENT_TYPE. Must be one of: executive, findings, dimensions, evidence, readme" 2
        ;;
esac

# Validate project path exists
[[ -d "$PROJECT_PATH" ]] || error_json "Project path not found: $PROJECT_PATH" 2

# Build full document path
FULL_DOC_PATH="$PROJECT_PATH/$DOCUMENT_PATH"
[[ -f "$FULL_DOC_PATH" ]] || error_json "Document not found: $FULL_DOC_PATH" 3

# Extract all headers from document
extract_headers() {
    grep -E '^#{1,3} ' "$FULL_DOC_PATH" | sed 's/^#* //' || true
}

# Count citations (numbered references)
count_citations() {
    (grep -o '<sup>\[[0-9]\+\]' "$FULL_DOC_PATH" || true) | wc -l | tr -d ' '
}

# Count specific patterns
count_pattern() {
    local pattern="$1"
    local count
    count="$(grep -c "$pattern" "$FULL_DOC_PATH" 2>/dev/null || true)"
    [[ -z "$count" ]] && count="0"
    echo "$count"
}

# Validate sections against required list
validate_sections() {
    local headers="$1"
    shift
    local -a required_sections=("$@")
    local -a missing_sections=()

    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    # Return missing sections as JSON array
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .
    else
        echo "[]"
    fi
}

# Build standard validation JSON response
build_validation_json() {
    local success="$1"
    local validation_status="$2"
    local missing_json="$3"
    local warnings_json="$4"
    local citation_count="$5"
    local required_sections="$6"
    local found_sections="$7"

    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    jq -n \
        --argjson success "$success" \
        --arg status "$validation_status" \
        --arg research_type "$RESEARCH_TYPE" \
        --arg document_type "$DOCUMENT_TYPE" \
        --arg document_path "$DOCUMENT_PATH" \
        --argjson missing "$missing_json" \
        --argjson warnings "$warnings_json" \
        --argjson required "$required_sections" \
        --argjson found "$found_sections" \
        --argjson citations "$citation_count" \
        --arg timestamp "$timestamp" \
        '{
            success: $success,
            validation_status: $status,
            research_type: $research_type,
            document_type: $document_type,
            document_path: $document_path,
            missing_sections: $missing,
            warnings: $warnings,
            metrics: {
                required_sections: $required,
                found_sections: $found,
                missing_count: ($missing | length),
                citation_count: $citations
            },
            timestamp: $timestamp
        }'
}

# ============================================================================
# EXECUTIVE VALIDATION FUNCTIONS
# ============================================================================

# Validate action-oriented-radar executive template
validate_action_oriented_radar() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Horizon 1: Act (0-2 Years)"
        "Horizon 2: Plan (2-5 Years)"
        "Horizon 3: Observe (5+ Years)"
        "Strategic Recommendations by Horizon"
        "Trend Interdependencies"
        "Risk Assessment Matrix"
        "Evidence Quality Assessment"
        "Cross-Dimensional Insights"
        "Methodology Note"
        "References"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local readiness_count
    readiness_count="$(count_pattern "Readiness Assessment")"

    # Build results
    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 20 ]] && warnings+=("Low citation count: $citation_count (minimum 20 recommended)")
    [[ $readiness_count -lt 3 ]] && warnings+=("Few readiness assessments: $readiness_count (minimum 3 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate trend-radar executive template
validate_trend_radar() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Innovation Trigger"
        "Peak of Inflated Expectations"
        "Trough of Disillusionment"
        "Slope of Enlightenment"
        "Plateau of Productivity"
        "Cross-Stage Analysis"
        "Strategic Implications"
        "Methodology Note"
        "References"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local maturity_count
    maturity_count="$(count_pattern "Maturity Indicators")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 20 ]] && warnings+=("Low citation count: $citation_count (minimum 20 recommended)")
    [[ $maturity_count -lt 5 ]] && warnings+=("Few maturity assessments: $maturity_count (minimum 5 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate lean-canvas executive template
validate_lean_canvas() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Problem"
        "Solution"
        "Key Metrics"
        "Unique Value Proposition"
        "Unfair Advantage"
        "Channels"
        "Customer Segments"
        "Cost Structure"
        "Revenue Streams"
        "Canvas Overview"
        "Validation Summary"
        "References"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local validation_status_count
    validation_status_count="$(count_pattern "Validation Status")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 20 ]] && warnings+=("Low citation count: $citation_count (minimum 20 recommended)")
    [[ $validation_status_count -lt 9 ]] && warnings+=("Few validation statuses: $validation_status_count (need 9, one per canvas block)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# ============================================================================
# DIMENSIONS VALIDATION FUNCTIONS
# ============================================================================

# Validate action-oriented-radar dimensions template
validate_action_oriented_radar_dimensions() {
    local headers
    headers="$(extract_headers)"

    # Flexible matching: Check if at least one Act, Plan, Observe pattern exists
    local has_act
    has_act="$(echo "$headers" | grep -c -E "Act.*Horizon.*\(0-2" || echo "0")"
    local has_plan
    has_plan="$(echo "$headers" | grep -c -E "Plan.*Horizon.*\(2-5" || echo "0")"
    local has_observe
    has_observe="$(echo "$headers" | grep -c -E "Observe.*Horizon.*\(5" || echo "0")"

    local missing_sections=()
    [[ $has_act -eq 0 ]] && missing_sections+=("Act Horizon (0-2 Years)")
    [[ $has_plan -eq 0 ]] && missing_sections+=("Plan Horizon (2-5 Years)")
    [[ $has_observe -eq 0 ]] && missing_sections+=("Observe Horizon (5+ Years)")

    # Check other required sections
    local required_sections=(
        "Cross-Dimensional Horizon Analysis"
        "Readiness Assessment Summary"
        "Horizon Transition Triggers"
    )

    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local readiness_count
    readiness_count="$(count_pattern "Readiness")"

    # Build results
    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $readiness_count -lt 3 ]] && warnings+=("Few readiness assessments: $readiness_count (minimum 3 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "6" \
        "$((6 - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate trend-radar dimensions template
validate_trend_radar_dimensions() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Innovation Trigger"
        "Peak of Inflated Expectations"
        "Trough of Disillusionment"
        "Slope of Enlightenment"
        "Plateau of Productivity"
        "Cross-Dimensional Maturity Analysis"
        "Adoption Timeline Projections"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local maturity_count
    maturity_count="$(count_pattern "Maturity")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $maturity_count -lt 5 ]] && warnings+=("Few maturity assessments: $maturity_count (minimum 5 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate lean-canvas dimensions template
validate_lean_canvas_dimensions() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Problem"
        "Solution"
        "Key Metrics"
        "Unique Value Proposition"
        "Unfair Advantage"
        "Channels"
        "Customer Segments"
        "Cost Structure"
        "Revenue Streams"
        "Cross-Dimensional Validation Patterns"
        "Overall Validation Status"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local validation_count
    validation_count="$(count_pattern "Validation")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $validation_count -lt 9 ]] && warnings+=("Few validation assessments: $validation_count (need 9, one per canvas block)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# ============================================================================
# EVIDENCE VALIDATION FUNCTIONS
# ============================================================================

# Validate action-oriented-radar evidence template
validate_action_oriented_radar_evidence() {
    local headers
    headers="$(extract_headers)"

    # Flexible matching for horizon sections
    local has_act
    has_act="$(echo "$headers" | grep -c -E "Act.*Horizon.*Evidence|Evidence.*Act.*Horizon" || echo "0")"
    local has_plan
    has_plan="$(echo "$headers" | grep -c -E "Plan.*Horizon.*Evidence|Evidence.*Plan.*Horizon" || echo "0")"
    local has_observe
    has_observe="$(echo "$headers" | grep -c -E "Observe.*Horizon.*Evidence|Evidence.*Observe.*Horizon" || echo "0")"

    local missing_sections=()
    [[ $has_act -eq 0 ]] && missing_sections+=("Act Horizon Evidence")
    [[ $has_plan -eq 0 ]] && missing_sections+=("Plan Horizon Evidence")
    [[ $has_observe -eq 0 ]] && missing_sections+=("Observe Horizon Evidence")

    # Check other required sections
    local required_sections=(
        "Publisher Analysis by Horizon"
        "Citation Index with Readiness"
    )

    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local publisher_count
    publisher_count="$(count_pattern "Publisher")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $publisher_count -lt 5 ]] && warnings+=("Few publisher references: $publisher_count (minimum 5 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "5" \
        "$((5 - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate trend-radar evidence template
validate_trend_radar_evidence() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Innovation Trigger Evidence"
        "Peak of Inflated Expectations Evidence"
        "Trough of Disillusionment Evidence"
        "Slope of Enlightenment Evidence"
        "Plateau of Productivity Evidence"
        "Publisher Analysis by Stage"
        "Citation Index with Maturity"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local publisher_count
    publisher_count="$(count_pattern "Publisher")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $publisher_count -lt 5 ]] && warnings+=("Few publisher references: $publisher_count (minimum 5 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate lean-canvas evidence template
validate_lean_canvas_evidence() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Problem Evidence"
        "Solution Evidence"
        "Key Metrics Evidence"
        "Unique Value Proposition Evidence"
        "Unfair Advantage Evidence"
        "Channels Evidence"
        "Customer Segments Evidence"
        "Cost Structure Evidence"
        "Revenue Streams Evidence"
        "Publisher Analysis by Validation Type"
        "Citation Index with Validation Status"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local publisher_count
    publisher_count="$(count_pattern "Publisher")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 15 ]] && warnings+=("Low citation count: $citation_count (minimum 15 recommended)")
    [[ $publisher_count -lt 5 ]] && warnings+=("Few publisher references: $publisher_count (minimum 5 recommended)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# ============================================================================
# README VALIDATION FUNCTIONS
# ============================================================================

# Validate action-oriented-radar readme template
validate_action_oriented_radar_readme() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Research Navigation"
        "Project Structure"
        "Document Hierarchy"
        "Research Framework"
        "Horizon Decision-Making Guide"
        "Transition Triggers Reference"
        "Reading Paths by Role"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local link_count
    link_count="$(count_pattern "\[.*\](.*\.md)")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 5 ]] && warnings+=("Low citation count: $citation_count (minimum 5 recommended)")
    [[ $link_count -lt 10 ]] && warnings+=("Few internal links: $link_count (minimum 10 recommended for navigation)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate trend-radar readme template
validate_trend_radar_readme() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Research Navigation"
        "Project Structure"
        "Document Hierarchy"
        "Research Framework"
        "Stage Strategy Guide"
        "Hype Cycle Interpretation"
        "Reading Paths by Role"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local link_count
    link_count="$(count_pattern "\[.*\](.*\.md)")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 5 ]] && warnings+=("Low citation count: $citation_count (minimum 5 recommended)")
    [[ $link_count -lt 10 ]] && warnings+=("Few internal links: $link_count (minimum 10 recommended for navigation)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# Validate lean-canvas readme template
validate_lean_canvas_readme() {
    local headers
    headers="$(extract_headers)"

    local required_sections=(
        "Research Navigation"
        "Project Structure"
        "Document Hierarchy"
        "Research Framework"
        "Canvas Block Usage Guide"
        "Validation Prioritization"
        "Reading Paths by Role"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! echo "$headers" | grep -qF "$section"; then
            missing_sections+=("$section")
        fi
    done

    local citation_count
    citation_count="$(count_citations)"

    local link_count
    link_count="$(count_pattern "\[.*\](.*\.md)")"

    local missing_json
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        missing_json="$(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)"
    else
        missing_json="[]"
    fi

    local warnings=()
    [[ $citation_count -lt 5 ]] && warnings+=("Low citation count: $citation_count (minimum 5 recommended)")
    [[ $link_count -lt 10 ]] && warnings+=("Few internal links: $link_count (minimum 10 recommended for navigation)")

    local warnings_json
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    else
        warnings_json="[]"
    fi

    local validation_status="passed"
    [[ ${#warnings[@]} -gt 0 ]] && validation_status="warnings"
    [[ ${#missing_sections[@]} -gt 0 ]] && validation_status="failed"

    build_validation_json \
        "$([[ ${#missing_sections[@]} -eq 0 ]] && echo true || echo false)" \
        "$validation_status" \
        "$missing_json" \
        "$warnings_json" \
        "$citation_count" \
        "${#required_sections[@]}" \
        "$((${#required_sections[@]} - ${#missing_sections[@]}))"

    [[ ${#missing_sections[@]} -eq 0 ]] && exit 0 || exit 1
}

# ============================================================================
# FINDINGS VALIDATION FUNCTIONS (Placeholder for future templates)
# ============================================================================

validate_action_oriented_radar_findings() {
    # Placeholder - findings template TBD
    echo '{"success": true, "validation_status": "not_applicable", "message": "Findings template not yet defined for action-oriented-radar"}' | jq
    exit 0
}

validate_trend_radar_findings() {
    # Placeholder - findings template TBD
    echo '{"success": true, "validation_status": "not_applicable", "message": "Findings template not yet defined for trend-radar"}' | jq
    exit 0
}

validate_lean_canvas_findings() {
    # Placeholder - no findings template for lean-canvas
    echo '{"success": true, "validation_status": "not_applicable", "message": "No findings template for lean-canvas"}' | jq
    exit 0
}

# ============================================================================
# MAIN VALIDATION DISPATCH
# ============================================================================

# Route to appropriate validator based on document type and research type
case "$DOCUMENT_TYPE" in
    executive)
        case "$RESEARCH_TYPE" in
            action-oriented-radar)
                validate_action_oriented_radar
                ;;
            trend-radar)
                validate_trend_radar
                ;;
            lean-canvas)
                validate_lean_canvas
                ;;
        esac
        ;;
    findings)
        case "$RESEARCH_TYPE" in
            action-oriented-radar)
                validate_action_oriented_radar_findings
                ;;
            trend-radar)
                validate_trend_radar_findings
                ;;
            lean-canvas)
                validate_lean_canvas_findings
                ;;
        esac
        ;;
    dimensions)
        case "$RESEARCH_TYPE" in
            action-oriented-radar)
                validate_action_oriented_radar_dimensions
                ;;
            trend-radar)
                validate_trend_radar_dimensions
                ;;
            lean-canvas)
                validate_lean_canvas_dimensions
                ;;
        esac
        ;;
    evidence)
        case "$RESEARCH_TYPE" in
            action-oriented-radar)
                validate_action_oriented_radar_evidence
                ;;
            trend-radar)
                validate_trend_radar_evidence
                ;;
            lean-canvas)
                validate_lean_canvas_evidence
                ;;
        esac
        ;;
    readme)
        case "$RESEARCH_TYPE" in
            action-oriented-radar)
                validate_action_oriented_radar_readme
                ;;
            trend-radar)
                validate_trend_radar_readme
                ;;
            lean-canvas)
                validate_lean_canvas_readme
                ;;
        esac
        ;;
esac
