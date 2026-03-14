#!/usr/bin/env bash
set -euo pipefail
# pre-synthesis-validation.sh
# Version: 2.0.0
# Event: PostToolUse (Task tool)
# Purpose: Validate prerequisites before synthesis-hub agent generates final research synthesis
#
# This hook triggers when Task tool invokes synthesis-hub agent
#
# Validates 5 Critical Gates:
#   1. Claims Availability: Minimum 5 claims exist in 09-claims
#   2. Confidence Score Coverage: All claims have valid confidence scores (0.0-1.0)
#   3. Wikilink Integrity: All wikilinks resolve, claims link to findings
#   4. Citation Availability: At least one citation exists in 08-citations
#   5. Megatrend Structure: Megatrends exist and link to findings
#
# Environment Variables:
#   DEBUG_MODE    Enable debug logging (true/false, default: false)
#   DEBUG_LEVEL   Logging level: INFO, DEBUG, TRACE (default: INFO)
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
DIR_CITATIONS="$(get_directory_by_key "citations")"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_MEGATRENDS="$(get_directory_by_key "megatrends")"

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

# Extract Task tool input to detect synthesis-hub invocation
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only validate when Task tool invokes synthesis-hub
if ! [[ "$TOOL_NAME" == "Task" ]]; then
    exit 0  # Not a Task invocation, skip
fi

# Check if synthesis-hub is being invoked
if ! echo "$TOOL_INPUT" | jq -e '.subagent_type' | grep -qi "synthesis-hub" 2>/dev/null; then
    exit 0  # Not synthesis-hub, skip validation
fi

# ============================================================================
# Configuration
# ============================================================================

MIN_CLAIMS_THRESHOLD=5
MIN_CONFIDENCE_THRESHOLD=0.65

# Research entity directories (with data subdirectory)
CLAIMS_DIR="$PROJECT_DIR/${DIR_CLAIMS}/${DATA_SUBDIR}"
CITATIONS_DIR="$PROJECT_DIR/${DIR_CITATIONS}/${DATA_SUBDIR}"
FINDINGS_DIR="$PROJECT_DIR/${DIR_FINDINGS}/${DATA_SUBDIR}"
MEGATRENDS_DIR="$PROJECT_DIR/${DIR_MEGATRENDS}/${DATA_SUBDIR}"

# Global validation state (shared across validation functions)
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

    # Count claim entity files (exclude README.md)
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

# BUG-008 FIX: Use temp file for error accumulation instead of array concatenation
validate_confidence_scores() {
    echo "Gate 2: Validating confidence scores..."

    local total_scores=0
    local sum_scores=0
    local invalid_scores=0

    # Create temp file for errors (bash 3.2 compatible alternative to array growth)
    local temp_errors="$(mktemp)"
    trap "rm -f '$temp_errors'" RETURN

    # Iterate through all claim files
    while IFS= read -r claim_file; do
        if [[ ! -f "$claim_file" ]]; then
            continue
        fi

        # Extract frontmatter and find confidence_score
        FRONTMATTER="$(awk '/^---$/{flag=!flag;next}flag' "$claim_file" 2>/dev/null || echo "")"

        if [[ -z "$FRONTMATTER" ]]; then
            echo "Missing frontmatter in $(basename "$claim_file")" >> "$temp_errors"
            VALIDATION_PASSED=false
            continue
        fi

        # Extract confidence_score value
        CONFIDENCE="$(echo "$FRONTMATTER" | grep "^confidence_score:" | sed 's/confidence_score:[[:space:]]*//' | tr -d '"\r\t\n' || echo "")"

        if [[ -z "$CONFIDENCE" ]]; then
            echo "Missing confidence_score in $(basename "$claim_file")" >> "$temp_errors"
            VALIDATION_PASSED=false
            continue
        fi

        # Validate score is numeric and in range 0.0-1.0
        if ! echo "$CONFIDENCE" | grep -qE '^[0-9]*\.?[0-9]+$'; then
            echo "Invalid confidence_score format in $(basename "$claim_file"): $CONFIDENCE" >> "$temp_errors"
            VALIDATION_PASSED=false
            invalid_scores=$((invalid_scores + 1))
            continue
        fi

        # Check range (using bc for floating point comparison with LC_NUMERIC=C for locale independence)
        if (( $(LC_NUMERIC=C bc -l <<< "$CONFIDENCE < 0.0" 2>/dev/null || echo 0) )) || (( $(LC_NUMERIC=C bc -l <<< "$CONFIDENCE > 1.0" 2>/dev/null || echo 0) )); then
            echo "Confidence score out of range in $(basename "$claim_file"): $CONFIDENCE (must be 0.0-1.0)" >> "$temp_errors"
            VALIDATION_PASSED=false
            invalid_scores=$((invalid_scores + 1))
            continue
        fi

        # Accumulate for average calculation
        total_scores=$((total_scores + 1))
        sum_scores="$(LC_NUMERIC=C bc -l <<< "$sum_scores + $CONFIDENCE")"

    done < <(find "$CLAIMS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null)

    # Load errors from temp file into array (single operation)
    if [[ -s "$temp_errors" ]]; then
        while IFS= read -r error; do
            CRITICAL_ERRORS+=("$error")
        done < "$temp_errors"
    fi

    if [[ "$total_scores" -gt 0 ]]; then
        AVG_CONFIDENCE="$(LC_NUMERIC=C bc -l <<< "scale=2; $sum_scores / $total_scores")"
        echo "  Average confidence score: $AVG_CONFIDENCE (from $total_scores claims)"

        # Warn if average confidence is low
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

    # Check all claims for wikilink integrity
    while IFS= read -r claim_file; do
        if [[ ! -f "$claim_file" ]]; then
            continue
        fi

        # Extract all wikilinks
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

            # Extract link path (remove [[ ]] and display text after |)
            link_content="${link#\[\[}"
            link_content="${link_content%\]\]}"
            link_path="${link_content%%|*}"

            # Resolve target file
            target_file="$PROJECT_DIR/$link_path.md"

            if [[ ! -f "$target_file" ]]; then
                CRITICAL_ERRORS+=("Broken wikilink in $(basename "$claim_file"): $link")
                broken_links=$((broken_links + 1))
                VALIDATION_PASSED=false
            fi

            # Check if claim links to findings (04-findings/data/)
            if [[ "$link_path" =~ ^04-findings/${DATA_SUBDIR}/ ]]; then
                has_finding_link=true
            fi

        done <<< "$WIKILINKS"

        # Warn if claim doesn't link to findings
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

    if [[ "$missing_finding_links" -gt 0 ]]; then
        echo "  Warning: $missing_finding_links claims missing links to findings"
    fi

    return 0
}

# ============================================================================
# Validation Gate 4: Citation Availability
# ============================================================================

validate_citation_availability() {
    echo "Gate 4: Validating citation availability..."

    if [[ ! -d "$CITATIONS_DIR" ]]; then
        WARNINGS+=("Citations directory missing: $CITATIONS_DIR (optional but recommended)")
        return 0
    fi

    # Count citation entity files
    CITATION_COUNT="$(find "$CITATIONS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$CITATION_COUNT" -eq 0 ]]; then
        WARNINGS+=("No citation entities found in $CITATIONS_DIR (optional but recommended)")
        return 0
    fi

    echo "  Found $CITATION_COUNT citation entities"

    # Validate citations have source_id references
    local missing_source_id=0

    while IFS= read -r citation_file; do
        if [[ ! -f "$citation_file" ]]; then
            continue
        fi

        FRONTMATTER="$(awk '/^---$/{flag=!flag;next}flag' "$citation_file" 2>/dev/null || echo "")"

        if ! echo "$FRONTMATTER" | grep -q "^source_id:"; then
            WARNINGS+=("Citation $(basename "$citation_file") missing source_id reference")
            missing_source_id=$((missing_source_id + 1))
        fi

    done < <(find "$CITATIONS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null)

    if [[ "$missing_source_id" -gt 0 ]]; then
        echo "  Warning: $missing_source_id citations missing source_id"
    fi

    return 0
}

# ============================================================================
# Validation Gate 5: Megatrend Structure
# ============================================================================

validate_megatrend_structure() {
    echo "Gate 5: Validating megatrend structure..."

    if [[ ! -d "$MEGATRENDS_DIR" ]]; then
        WARNINGS+=("Megatrends directory missing: $MEGATRENDS_DIR (synthesis may lack structure)")
        return 0
    fi

    # Count megatrend entity files
    MEGATREND_COUNT="$(find "$MEGATRENDS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$MEGATREND_COUNT" -eq 0 ]]; then
        WARNINGS+=("No megatrend entities found in $MEGATRENDS_DIR (synthesis may lack structure)")
        return 0
    fi

    echo "  Found $MEGATREND_COUNT megatrend entities"

    # Validate megatrends have required megatrend_structure field and wikilinks to findings
    local megatrends_without_findings=0
    local megatrends_missing_structure=0
    local megatrends_invalid_structure=0

    while IFS= read -r megatrend_file; do
        if [[ ! -f "$megatrend_file" ]]; then
            continue
        fi

        # Extract megatrend_structure from YAML frontmatter
        local megatrend_structure=""
        if grep -q "^megatrend_structure:" "$megatrend_file" 2>/dev/null; then
            megatrend_structure=$(grep "^megatrend_structure:" "$megatrend_file" | head -1 | sed 's/^megatrend_structure:[[:space:]]*//' | tr -d '"' | tr -d "'")
        fi

        # Check if megatrend_structure field exists (now required)
        if [[ -z "$megatrend_structure" ]]; then
            CRITICAL_ERRORS+=("Megatrend $(basename "$megatrend_file") missing required megatrend_structure field")
            megatrends_missing_structure=$((megatrends_missing_structure + 1))
            VALIDATION_PASSED=false
        elif ! [[ "$megatrend_structure" == "tips" ]] && ! [[ "$megatrend_structure" == "generic" ]]; then
            CRITICAL_ERRORS+=("Megatrend $(basename "$megatrend_file") has invalid megatrend_structure: '$megatrend_structure' (must be 'tips' or 'generic')")
            megatrends_invalid_structure=$((megatrends_invalid_structure + 1))
            VALIDATION_PASSED=false
        fi

        # Check if megatrend has wikilinks to findings (with data subdir)
        if ! grep -q "\[\[04-findings/${DATA_SUBDIR}/" "$megatrend_file" 2>/dev/null; then
            WARNINGS+=("Megatrend $(basename "$megatrend_file") has no links to findings")
            megatrends_without_findings=$((megatrends_without_findings + 1))
        fi

    done < <(find "$MEGATRENDS_DIR" -name "*.md" -not -name "README.md" 2>/dev/null)

    if [[ "$megatrends_missing_structure" -gt 0 ]]; then
        echo "  ERROR: $megatrends_missing_structure megatrends missing megatrend_structure field"
    fi

    if [[ "$megatrends_invalid_structure" -gt 0 ]]; then
        echo "  ERROR: $megatrends_invalid_structure megatrends have invalid megatrend_structure value"
    fi

    if [[ "$megatrends_without_findings" -gt 0 ]]; then
        echo "  Warning: $megatrends_without_findings megatrends missing links to findings"
    fi

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

# Run all validation gates
validate_claims_availability
validate_confidence_scores
validate_wikilink_integrity
validate_citation_availability
validate_megatrend_structure

# ============================================================================
# Report Results
# ============================================================================

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""

if [[ ${#CRITICAL_ERRORS[@]} -gt 0 ]]; then
    echo "❌ CRITICAL ERRORS (${#CRITICAL_ERRORS[@]}):"
    for error in "${CRITICAL_ERRORS[@]}"; do
        echo "  • $error"
    done
    echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "⚠️  WARNINGS (${#WARNINGS[@]}):"
    for warning in "${WARNINGS[@]}"; do
        echo "  • $warning"
    done
    echo ""
fi

log_metric "critical_errors" "${#CRITICAL_ERRORS[@]}" "count"
log_metric "warnings" "${#WARNINGS[@]}" "count"

if [[ "$VALIDATION_PASSED" == "false" ]]; then
    log_conditional ERROR "Pre-synthesis validation FAILED"
    echo "❌ Pre-synthesis validation FAILED"
    echo ""
    echo "Fix critical errors before proceeding with synthesis generation."
    echo ""
    log_phase "pre-synthesis-validation" "complete"
    exit 1
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    log_conditional WARN "Pre-synthesis validation PASSED with ${#WARNINGS[@]} warnings"
    echo "⚠️  Pre-synthesis validation PASSED with warnings"
    echo ""
    echo "Consider addressing warnings for higher quality synthesis."
    echo ""
else
    log_conditional INFO "Pre-synthesis validation PASSED"
    echo "✅ Pre-synthesis validation PASSED"
    echo ""
    echo "Ready for synthesis generation."
    echo ""
fi

log_phase "pre-synthesis-validation" "complete"
exit 0
