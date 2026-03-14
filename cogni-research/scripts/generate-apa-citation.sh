#!/usr/bin/env bash
set -euo pipefail
# generate-apa-citation.sh
# Version: 2.0.0
# Purpose: Generate properly formatted APA 7th edition citations with multi-language support
# Category: formatters
#
# Changelog:
# v2.0.0 (2025-11-16, Sprint 315: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added structured phase markers (4 phases)
#   - Added performance metrics
#   - Now compliant with three-layer debugging architecture
#
# Usage: generate-apa-citation.sh --title TITLE --url URL --domain DOMAIN [OPTIONS]
#
# Arguments:
#   --title <string>         Source title (required)
#   --url <string>           Source URL (required)
#   --domain <string>        Source domain (required)
#   --author <string>        Individual author name (optional, e.g., "Smith, J.")
#   --institution <string>   Institutional author name (optional, e.g., "World Bank")
#   --year <string>          Publication year (optional, e.g., "2024")
#   --date <string>          Formatted access date (optional, required for non-author citations)
#   --language <string>      Language code: en|de (optional, default: en)
#   --doi <string>           DOI identifier (optional, will be normalized)
#   --pmid <string>          PMID identifier (optional)
#   --json                   Output JSON format (optional flag, default: plain text)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "citation": "formatted APA citation string",
#     "error": "error message" (if success=false)
#   }
#
# Output (plain text mode):
#   Prints citation to stdout
#
# Exit codes:
#   0 - Success
#   2 - Invalid arguments
#
# Citation Formats (APA 7th Edition):
#
#   Individual Author:
#     Author, A. A. (Year). Title. URL
#
#   Institutional Author (English):
#     Institution Name. (Year). Title. Retrieved Date, from URL
#
#   Institutional Author (German):
#     Institution Name. (Year). Title. Abgerufen am Date, von URL
#
#   Domain Fallback (English):
#     domain.com. (n.d.). Title. Retrieved Date, from URL
#
#   Domain Fallback (German):
#     domain.com. (o. J.). Title. Abgerufen am Date, von URL
#
# DOI/PMID Suffixes:
#   If DOI provided: ... https://doi.org/DOI_VALUE
#   If PMID provided: ... PMID: PMID_VALUE
#
# Examples:
#   # Individual author
#   generate-apa-citation.sh \
#     --title "Green Bonds" \
#     --url "https://example.com/article" \
#     --domain "example.com" \
#     --author "Smith, J." \
#     --year "2024" \
#     --json
#
#   # Institutional author (German)
#   generate-apa-citation.sh \
#     --title "Nachhaltigkeitsbericht 2024" \
#     --url "https://example.com/report" \
#     --domain "example.com" \
#     --institution "World Bank" \
#     --year "2024" \
#     --date "29. Oktober 2025" \
#     --language "de" \
#     --json
#
#   # Domain fallback with DOI
#   generate-apa-citation.sh \
#     --title "Climate Research" \
#     --url "https://example.com/study" \
#     --domain "example.com" \
#     --date "October 29, 2025" \
#     --doi "10.1234/example" \
#     --json


# ===== LOGGING INITIALIZATION =====
SCRIPT_NAME="generate-apa-citation"

# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"

    log_conditional "ERROR" "$message"

    if [[ "$json_mode" = true ]]; then
        jq -n --arg msg "$message" --argjson code "$code" \
            '{success: false, error: $msg, error_code: $code}' >&2
    else
        echo "Error: $message" >&2
    fi
    exit "$code"
}

# Normalize DOI - strip existing prefix and add standard https://doi.org/ prefix
normalize_doi() {
    local doi="$1"
    [[ -z "$doi" ]] && return

    # Strip http:// or https:// doi.org/ prefixes
    doi="${doi#https://doi.org/}"
    doi="${doi#http://doi.org/}"

    # Return normalized DOI with https prefix
    echo "https://doi.org/${doi}"
}

# Build citation based on authorship variant and language
build_citation() {
    local title="$1"
    local url="$2"
    local domain="$3"
    local author="$4"
    local institution="$5"
    local year="$6"
    local date="$7"
    local language="$8"
    local doi="$9"
    local pmid="${10}"

    local citation=""
    local citation_type=""

    # Determine authorship variant
    if [[ -n "$author" ]]; then
        # Individual author format (language-independent)
        citation="${author} (${year}). ${title}. ${url}"
        citation_type="individual_author"

    elif [[ -n "$institution" ]]; then
        # Institutional author format (language-specific)
        if [[ "$language" = "de" ]]; then
            # German format
            citation="${institution}. (${year}). ${title}. Abgerufen am ${date}, von ${url}"
        else
            # English format (default)
            citation="${institution}. (${year}). ${title}. Retrieved ${date}, from ${url}"
        fi
        citation_type="institutional_author"

    else
        # Domain fallback format (language-specific)
        if [[ "$language" = "de" ]]; then
            # German format with "o. J." (ohne Jahr)
            citation="${domain}. (o. J.). ${title}. Abgerufen am ${date}, von ${url}"
        else
            # English format with "n.d." (no date)
            citation="${domain}. (n.d.). ${title}. Retrieved ${date}, from ${url}"
        fi
        citation_type="domain_fallback"
    fi

    log_conditional "DEBUG" "Citation type: $citation_type"

    # Append DOI if provided
    if [[ -n "$doi" ]]; then
        local normalized_doi
        normalized_doi="$(normalize_doi "$doi")"
        citation="${citation} ${normalized_doi}"
        log_conditional "DEBUG" "Added DOI: $normalized_doi"
    fi

    # Append PMID if provided
    if [[ -n "$pmid" ]]; then
        citation="${citation} PMID: ${pmid}"
        log_conditional "DEBUG" "Added PMID: $pmid"
    fi

    echo "$citation"
}

# Main function
main() {
    local start_time
    start_time="$(date +%s)"

    # Initialize variables
    local title=""
    local url=""
    local domain=""
    local author=""
    local institution=""
    local year=""
    local date=""
    local language="en"  # Default to English
    local doi=""
    local pmid=""
    local json_mode=false

    log_phase "Phase 1: Input Parsing" "start"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --url)
                url="$2"
                shift 2
                ;;
            --domain)
                domain="$2"
                shift 2
                ;;
            --author)
                author="$2"
                shift 2
                ;;
            --institution)
                institution="$2"
                shift 2
                ;;
            --year)
                year="$2"
                shift 2
                ;;
            --date)
                date="$2"
                shift 2
                ;;
            --language)
                language="$2"
                shift 2
                ;;
            --doi)
                doi="$2"
                shift 2
                ;;
            --pmid)
                pmid="$2"
                shift 2
                ;;
            --json)
                json_mode=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    log_conditional "INFO" "Parameter: title = ${title:0:50}..."
    log_conditional "INFO" "Parameter: url = ${url}"
    log_conditional "INFO" "Parameter: domain = ${domain}"
    log_conditional "INFO" "Parameter: language = ${language}"
    log_conditional "DEBUG" "Optional: author = ${author:-none}"
    log_conditional "DEBUG" "Optional: institution = ${institution:-none}"
    log_conditional "DEBUG" "Optional: year = ${year:-none}"
    log_conditional "DEBUG" "Optional: doi = ${doi:-none}"
    log_conditional "DEBUG" "Optional: pmid = ${pmid:-none}"

    log_phase "Phase 1: Input Parsing" "complete"

    # ===== PHASE 2: VALIDATION =====
    log_phase "Phase 2: Input Validation" "start"

    # Validate required arguments
    [[ -n "$title" ]] || error_json "Missing required argument: --title" 2
    [[ -n "$url" ]] || error_json "Missing required argument: --url" 2
    [[ -n "$domain" ]] || error_json "Missing required argument: --domain" 2

    # Validate language
    if ! [[ "$language" == "en" ]] && ! [[ "$language" == "de" ]]; then
        error_json "Invalid language: $language (must be 'en' or 'de')" 2
    fi

    # Validate date requirement for non-author citations
    if [[ -z "$author" && -z "$date" ]]; then
        error_json "Missing required argument: --date (required for institutional/domain citations)" 2
    fi

    log_conditional "INFO" "All validations passed"
    log_phase "Phase 2: Input Validation" "complete"

    # ===== PHASE 3: CITATION GENERATION =====
    log_phase "Phase 3: Citation Generation" "start"

    # Build the citation
    local citation
    citation="$(build_citation "$title" "$url" "$domain" "$author" "$institution" "$year" "$date" "$language" "$doi" "$pmid")"

    log_conditional "INFO" "Citation generated successfully"
    log_metric "citation_length" "${#citation}" "characters"
    log_metric "has_doi" "$([[ -n "$doi" ]] && echo 1 || echo 0)" "boolean"
    log_metric "has_pmid" "$([[ -n "$pmid" ]] && echo 1 || echo 0)" "boolean"

    log_phase "Phase 3: Citation Generation" "complete"

    # ===== PHASE 4: OUTPUT =====
    log_phase "Phase 4: Output" "start"

    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - start_time))
    log_metric "duration" "$duration" "seconds"

    # Output result
    if [[ "$json_mode" = true ]]; then
        log_conditional "INFO" "Outputting JSON format"
        jq -n --arg citation "$citation" \
            '{
                success: true,
                citation: $citation
            }'
    else
        log_conditional "INFO" "Outputting plain text format"
        echo "$citation"
    fi

    log_phase "Phase 4: Output" "complete"
}

# Execute main function
main "$@"
