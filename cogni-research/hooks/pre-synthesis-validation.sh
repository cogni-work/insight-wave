#!/usr/bin/env bash
set -euo pipefail
# pre-synthesis-validation.sh
# Version: 3.0.0
# Event: PostToolUse (Task tool)
# Purpose: Validate prerequisites before synthesis skill delegates to cogni-narrative
#
# Validates 4 Critical Gates:
#   1. Claims Availability: Minimum 5 claims exist in 06-claims
#   2. Confidence Score Coverage: All claims have valid confidence scores (0.0-1.0)
#   3. Wikilink Integrity: All wikilinks resolve, claims link to findings
#   4. Source Availability: Sources exist in 05-sources with finding refs
#
# Exit codes:
#   0 - All validations passed (proceed with synthesis)
#   1 - Critical validations failed (block synthesis with detailed report)


# ============================================================================
# Enhanced Logging Integration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source centralized entity config (REQUIRED)
source "$PLUGIN_ROOT/scripts/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh not found at $PLUGIN_ROOT/scripts/lib/entity-config.sh" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"
DIR_CLAIMS="$(get_directory_by_key "claims")"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_FINDINGS="$(get_directory_by_key "findings")"

# Source enhanced-logging.sh if available
if [[ -f "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh" ]]; then
    source "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh"
else
    # Fallback logging functions
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
    log_phase() { log_conditional "PHASE" "$1 [$2]"; }
    log_metric() { log_conditional "METRIC" "$1=$2 unit=$3"; }
fi

# ============================================================================
# Environment Variable Extraction
# ============================================================================

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only validate when Task tool invokes synthesis-related agents
if ! [[ "$TOOL_NAME" == "Task" ]]; then
    exit 0
fi

# Check if a synthesis agent is being invoked (narrative-writer or similar)
if ! echo "$TOOL_INPUT" | jq -e '.subagent_type' 2>/dev/null | grep -qiE "synthesis|narrative" 2>/dev/null; then
    exit 0
fi

# ============================================================================
# Configuration
# ============================================================================

MIN_CLAIMS_THRESHOLD=5
MIN_CONFIDENCE_THRESHOLD=0.65

CLAIMS_DIR="$PROJECT_DIR/${DIR_CLAIMS}/${DATA_SUBDIR}"
SOURCES_DIR="$PROJECT_DIR/${DIR_SOURCES}/${DATA_SUBDIR}"
FINDINGS_DIR="$PROJECT_DIR/${DIR_FINDINGS}/${DATA_SUBDIR}"

# Global validation state
CRITICAL_ERRORS=()
WARNINGS=()
VALIDATION_PASSED=true

# ============================================================================
# Validation Gate 1: Claims Availability
# ============================================================================

validate_claims_availability() {
    echo "Gate 1: Validating claims availability..."

    if [[ ! -d "$CLAIMS_DIR" ]]; then
        CRITICAL_ERRORS+=("Claims directory missing: $CLAIMS_DIR")
        VALIDATION_PASSED=false
        return 1
    fi

    CLAIM_COUNT="$(find "$CLAIMS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$CLAIM_COUNT" -eq 0 ]]; then
        CRITICAL_ERRORS+=("No claim entities found in $CLAIMS_DIR")
        VALIDATION_PASSED=false
        return 1
    fi

    if [[ "$CLAIM_COUNT" -lt "$MIN_CLAIMS_THRESHOLD" ]]; then
        WARNINGS+=("Low claim count: $CLAIM_COUNT claims (recommended minimum: $MIN_CLAIMS_THRESHOLD)")
    fi

    echo "  Found $CLAIM_COUNT claim entities"
    return 0
}

# ============================================================================
# Validation Gate 2: Confidence Score Coverage
# ============================================================================

validate_confidence_scores() {
    echo "Gate 2: Validating confidence scores..."

    local total_scores=0
    local sum_scores=0
    local invalid_scores=0

    local temp_errors="$(mktemp)"
    trap "rm -f '$temp_errors'" RETURN

    while IFS= read -r claim_file; do
        if [[ ! -f "$claim_file" ]]; then
            continue
        fi

        FRONTMATTER="$(awk '/^---$/{flag=!flag;next}flag' "$claim_file" 2>/dev/null || echo "")"

        if [[ -z "$FRONTMATTER" ]]; then
            echo "Missing frontmatter in $(basename "$claim_file")" >> "$temp_errors"
            VALIDATION_PASSED=false
            continue
        fi

        CONFIDENCE="$(echo "$FRONTMATTER" | grep "^confidence_score:" | sed 's/confidence_score:[[:space:]]*//' | tr -d '"\r\t\n' || echo "")"

        if [[ -z "$CONFIDENCE" ]]; then
            echo "Missing confidence_score in $(basename "$claim_file")" >> "$temp_errors"
            VALIDATION_PASSED=false
            continue
        fi

        if ! echo "$CONFIDENCE" | grep -qE '^[0-9]*\.?[0-9]+$'; then
            echo "Invalid confidence_score format in $(basename "$claim_file"): $CONFIDENCE" >> "$temp_errors"
            VALIDATION_PASSED=false
            invalid_scores=$((invalid_scores + 1))
            continue
        fi

        if (( $(LC_NUMERIC=C bc -l <<< "$CONFIDENCE < 0.0" 2>/dev/null || echo 0) )) || (( $(LC_NUMERIC=C bc -l <<< "$CONFIDENCE > 1.0" 2>/dev/null || echo 0) )); then
            echo "Confidence score out of range in $(basename "$claim_file"): $CONFIDENCE (must be 0.0-1.0)" >> "$temp_errors"
            VALIDATION_PASSED=false
            invalid_scores=$((invalid_scores + 1))
            continue
        fi

        total_scores=$((total_scores + 1))
        sum_scores="$(LC_NUMERIC=C bc -l <<< "$sum_scores + $CONFIDENCE")"

    done < <(find "$CLAIMS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null)

    if [[ -s "$temp_errors" ]]; then
        while IFS= read -r error; do
            CRITICAL_ERRORS+=("$error")
        done < "$temp_errors"
    fi

    if [[ "$total_scores" -gt 0 ]]; then
        AVG_CONFIDENCE="$(LC_NUMERIC=C bc -l <<< "scale=2; $sum_scores / $total_scores")"
        echo "  Average confidence score: $AVG_CONFIDENCE (from $total_scores claims)"

        if (( $(LC_NUMERIC=C bc -l <<< "$AVG_CONFIDENCE < $MIN_CONFIDENCE_THRESHOLD") )); then
            WARNINGS+=("Low average confidence score: $AVG_CONFIDENCE (threshold: $MIN_CONFIDENCE_THRESHOLD)")
        fi
    fi

    return 0
}

# ============================================================================
# Validation Gate 3: Wikilink Integrity
# ============================================================================

validate_wikilink_integrity() {
    echo "Gate 3: Validating wikilink integrity..."

    local broken_links=0
    local missing_finding_links=0

    while IFS= read -r claim_file; do
        if [[ ! -f "$claim_file" ]]; then
            continue
        fi

        WIKILINKS="$(grep -o '\[\[[^]]*\]\]' "$claim_file" 2>/dev/null || true)"

        if [[ -z "$WIKILINKS" ]]; then
            WARNINGS+=("No wikilinks found in $(basename "$claim_file")")
            continue
        fi

        local has_finding_link=false

        while IFS= read -r link; do
            if [[ -z "$link" ]]; then
                continue
            fi

            link_content="${link#\[\[}"
            link_content="${link_content%\]\]}"
            link_path="${link_content%%|*}"

            target_file="$PROJECT_DIR/$link_path.md"

            if [[ ! -f "$target_file" ]]; then
                CRITICAL_ERRORS+=("Broken wikilink in $(basename "$claim_file"): $link")
                broken_links=$((broken_links + 1))
                VALIDATION_PASSED=false
            fi

            if [[ "$link_path" =~ ^04-findings/${DATA_SUBDIR}/ ]]; then
                has_finding_link=true
            fi

        done <<< "$WIKILINKS"

        if [[ "$has_finding_link" == "false" ]]; then
            WARNINGS+=("Claim $(basename "$claim_file") has no links to findings (04-findings/${DATA_SUBDIR})")
            missing_finding_links=$((missing_finding_links + 1))
        fi

    done < <(find "$CLAIMS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null)

    if [[ "$broken_links" -gt 0 ]]; then
        echo "  Found $broken_links broken wikilinks"
    else
        echo "  All wikilinks valid"
    fi

    return 0
}

# ============================================================================
# Validation Gate 4: Source Availability
# ============================================================================

validate_source_availability() {
    echo "Gate 4: Validating source availability..."

    if [[ ! -d "$SOURCES_DIR" ]]; then
        WARNINGS+=("Sources directory missing: $SOURCES_DIR (optional but recommended for provenance)")
        return 0
    fi

    SOURCE_COUNT="$(find "$SOURCES_DIR" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$SOURCE_COUNT" -eq 0 ]]; then
        WARNINGS+=("No source entities found in $SOURCES_DIR (provenance chain incomplete)")
        return 0
    fi

    echo "  Found $SOURCE_COUNT source entities"
    return 0
}

# ============================================================================
# Main Validation Execution
# ============================================================================

log_phase "pre-synthesis-validation" "start"

echo ""
echo "=========================================="
echo "Pre-Synthesis Validation"
echo "=========================================="
echo ""

validate_claims_availability
validate_confidence_scores
validate_wikilink_integrity
validate_source_availability

# ============================================================================
# Report Results
# ============================================================================

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""

if [[ ${#CRITICAL_ERRORS[@]} -gt 0 ]]; then
    echo "CRITICAL ERRORS (${#CRITICAL_ERRORS[@]}):"
    for error in "${CRITICAL_ERRORS[@]}"; do
        echo "  - $error"
    done
    echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "WARNINGS (${#WARNINGS[@]}):"
    for warning in "${WARNINGS[@]}"; do
        echo "  - $warning"
    done
    echo ""
fi

log_metric "critical_errors" "${#CRITICAL_ERRORS[@]}" "count"
log_metric "warnings" "${#WARNINGS[@]}" "count"

if [[ "$VALIDATION_PASSED" == "false" ]]; then
    log_conditional ERROR "Pre-synthesis validation FAILED"
    echo "Pre-synthesis validation FAILED"
    echo ""
    echo "Fix critical errors before proceeding with synthesis."
    echo ""
    log_phase "pre-synthesis-validation" "complete"
    exit 1
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    log_conditional WARN "Pre-synthesis validation PASSED with ${#WARNINGS[@]} warnings"
    echo "Pre-synthesis validation PASSED with warnings"
    echo ""
else
    log_conditional INFO "Pre-synthesis validation PASSED"
    echo "Pre-synthesis validation PASSED"
    echo ""
    echo "Ready for synthesis."
    echo ""
fi

log_phase "pre-synthesis-validation" "complete"
exit 0
