#!/usr/bin/env bash
set -euo pipefail
# citation-generator.sh
# Version: 2.0.0
# Purpose: Generate formal APA citations linking sources to publishers using multi-strategy resolution
# Category: citation-generation
#
# Changelog:
# v2.0.0 (2025-11-14, Sprint 277: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added log-execution-context.sh integration for environment capture
#   - Added partition-aware log file naming
#   - Added structured phase markers (6 phases)
#   - Added performance metrics (10 metrics)
#   - Validated CLAUDE_PLUGIN_ROOT environment variable
#   - Now compliant with three-layer debugging architecture
#
# Usage: citation-generator.sh --project-path PATH [OPTIONS]
#
# Arguments:
#   --project-path <path>    Absolute path to research project directory (required)
#   --language <string>      Language code: en|de (optional, default: en)
#   --repair-mode            Fix existing broken publisher links instead of generating new citations (optional flag)
#   --partition <string>     Process subset of sources (e.g., "1/4" for partition 1 of 4) (optional)
#
# Output (JSON only):
#   {
#     "success": true,
#     "citations_created": 23,
#     "citations_skipped": 2,
#     "publisher_matches": {
#       "domain_exact": 15,
#       "name_exact": 5,
#       "domain_parent": 3,
#       "reverse_index": 2,
#       "domain_fallback": 1
#     },
#     "warnings": ["Optional warning messages"]
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   citation-generator.sh --project-path "/path/to/project" --language en --json


# ===== PARAMETER PARSING =====
PROJECT_PATH=""
LANGUAGE="en"
REPAIR_MODE=false
PARTITION=""

# Parse required parameter
if [ $# -eq 0 ]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 1
fi

# Parse all parameters
while [ $# -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --repair-mode)
      REPAIR_MODE=true
      shift
      ;;
    --partition)
      PARTITION="$2"
      shift 2
      ;;
    *)
      echo '{"success": false, "error": "Unknown parameter: '"$1"'"}' >&2
      exit 1
      ;;
  esac
done

# ===== LOGGING INITIALIZATION =====
AGENT_NAME="citation-generator"

# Partition-aware log file naming (shared-bash-patterns.md Section 3)
if [ -n "${PARTITION:-}" ]; then
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-partition${PARTITION}-execution-log.txt"
else
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
fi

# Ensure metadata directory exists
mkdir -p "${PROJECT_PATH}/.metadata" 2>/dev/null || true

# ===== PLUGIN ROOT RESOLUTION =====
# Auto-detect CLAUDE_PLUGIN_ROOT if not set (resolve-plugin-root.sh pattern)
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  # Derive from script location: /plugin/scripts/citation-generator.sh -> /plugin
  CLAUDE_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export CLAUDE_PLUGIN_ROOT
fi

# Validate CLAUDE_PLUGIN_ROOT has expected structure
if [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: '"${CLAUDE_PLUGIN_ROOT}"'"}' >&2
  exit 1
fi

# Final validation
if [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo '{"success": false, "error": "Cannot resolve plugin root. CLAUDE_PLUGIN_ROOT: '"${CLAUDE_PLUGIN_ROOT:-unset}"'"}' >&2
  exit 1
fi

# Source enhanced logging utilities (Sprint 277 migration)
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize log file with header
echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Log execution context
CONTEXT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh" \
  --project-path "$PROJECT_PATH" \
  --agent-name "$AGENT_NAME" \
  --json 2>&1)"
echo "$CONTEXT" >> "$LOG_FILE" 2>/dev/null || true

# Validate log file is writable
if [ ! -w "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
    echo "WARNING: Cannot write to log file: $LOG_FILE" >&2
fi

log_phase "Phase 1: Input Validation" "start"
log_conditional "INFO" "Parameter: PROJECT_PATH = ${PROJECT_PATH}"
log_conditional "INFO" "Parameter: LANGUAGE = ${LANGUAGE}"
if [ -n "$PARTITION" ]; then
  log_conditional "INFO" "Parameter: PARTITION = ${PARTITION}"
fi
log_conditional "INFO" "Log file: $LOG_FILE"

# ===== VALIDATION =====
if [ -z "$PROJECT_PATH" ]; then
  log_conditional "ERROR" "Missing required parameter: --project-path"
  echo '{"success": false, "error": "Missing required parameter: --project-path"}'
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  log_conditional "ERROR" "Project path does not exist: $PROJECT_PATH"
  echo '{"success": false, "error": "Project path does not exist: '"$PROJECT_PATH"'"}'
  exit 1
fi

# Source centralized entity config
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi

if [ -z "$ENTITY_CONFIG" ]; then
  log_conditional "ERROR" "entity-config.sh not found in CLAUDE_PLUGIN_ROOT"
  echo '{"success": false, "error": "entity-config.sh not found in CLAUDE_PLUGIN_ROOT"}'
  exit 1
fi

# shellcheck source=/dev/null
source "$ENTITY_CONFIG"
DATA_SUBDIR="$(get_data_subdir)"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"
DIR_CITATIONS="$(get_directory_by_key "citations")"

if [ ! -d "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}" ]; then
  log_conditional "ERROR" "Sources directory not found: ${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}"
  echo '{"success": false, "error": "Sources directory not found: '"${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}"'"}'
  exit 1
fi

if [ ! -d "${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}" ]; then
  log_conditional "ERROR" "Publishers directory not found: ${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}"
  echo '{"success": false, "error": "Publishers directory not found: '"${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}"'"}'
  exit 1
fi

log_conditional "INFO" "Parameter validation successful"
log_phase "Phase 1: Input Validation" "complete"

# ===== CAPTURE SCRIPT DIRECTORY BEFORE CD (BUG-040 FIX) =====
# Must capture SCRIPT_DIR before changing to PROJECT_PATH, otherwise
# relative paths in BASH_SOURCE[0] will break after cd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_conditional "DEBUG" "Script directory captured: $SCRIPT_DIR"

# ===== WORKING DIRECTORY VALIDATION =====
log_conditional "DEBUG" "Changing to working directory: $PROJECT_PATH"

# BUG-012 FIX: Use immediate exit pattern for cd command
cd "$PROJECT_PATH" || {
  log_conditional "ERROR" "Failed to change to project directory: $PROJECT_PATH"
  echo '{"success": false, "error": "Failed to change to project directory: '"$PROJECT_PATH"'"}'
  exit 1
}

log_conditional "INFO" "Working directory validated: $(pwd)"

# Log execution mode
if [ "$REPAIR_MODE" = true ]; then
  log_conditional "INFO" "Mode: REPAIR (fixing existing broken publisher links)"
  echo "Mode: REPAIR (fixing existing broken publisher links)" >&2
else
  log_conditional "INFO" "Mode: GENERATE (creating new citations for all sources)"
  echo "Mode: GENERATE (creating new citations for all sources)" >&2
fi

echo "Language: $LANGUAGE" >&2

if [ -n "$PARTITION" ]; then
  log_conditional "INFO" "Partition mode: $PARTITION"
  echo "Partition mode: $PARTITION" >&2
fi

# ===== PHASE 2: COMPLETE ENTITY LOADING =====
log_phase "Phase 2: Entity Loading" "start"

# Count sources first for verification
SOURCE_COUNT="$(find "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}" -name "source-*.md" 2>/dev/null | wc -l | tr -d ' ')"
log_conditional "INFO" "Loading $SOURCE_COUNT sources completely (no truncation)..."
echo "INFO: Loading $SOURCE_COUNT sources completely (no truncation)..." >&2

# Collect source IDs
SOURCES_TO_PROCESS=()
for source_file in "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}"/source-*.md; do
  [ -f "$source_file" ] || continue
  source_id="$(basename "$source_file" .md)"
  SOURCES_TO_PROCESS+=("$source_id")
done

# Verify count matches
if [ ${#SOURCES_TO_PROCESS[@]} -ne "$SOURCE_COUNT" ]; then
  log_conditional "ERROR" "Source count mismatch: expected $SOURCE_COUNT, loaded ${#SOURCES_TO_PROCESS[@]}"
  echo '{"success": false, "error": "Source count mismatch: expected '"$SOURCE_COUNT"', loaded '"${#SOURCES_TO_PROCESS[@]}"'"}'
  exit 1
fi

log_conditional "INFO" "VERIFICATION: All $SOURCE_COUNT sources loaded completely"
echo "VERIFICATION: All $SOURCE_COUNT sources loaded completely" >&2

# ===== PUBLISHER LOADING WITH RETRY (BUG-039 FIX) =====
# Addresses race condition when citation-generator is invoked immediately
# after publisher-generator completes in parallel Task execution.
# macOS filesystem caching can cause find/glob to return stale results.
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=2
PUBLISHER_COUNT=0

for attempt in $(seq 1 $MAX_RETRY_ATTEMPTS); do
  # Force filesystem sync before loading (resolves macOS caching issues)
  sync 2>/dev/null || true

  # Count publishers
  PUBLISHER_COUNT="$(find "${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"

  if [ "$PUBLISHER_COUNT" -gt 0 ]; then
    log_conditional "INFO" "Found $PUBLISHER_COUNT publishers on attempt $attempt"
    break
  fi

  if [ "$attempt" -lt "$MAX_RETRY_ATTEMPTS" ]; then
    log_conditional "WARN" "No publishers found on attempt $attempt, retrying in ${RETRY_DELAY}s..."
    echo "WARNING: No publishers found, retrying in ${RETRY_DELAY}s (attempt $attempt/$MAX_RETRY_ATTEMPTS)..." >&2
    sleep $RETRY_DELAY
    RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff: 2s, 4s, 8s
  fi
done

# Log if retry was needed (diagnostic for BUG-039)
if [ "$attempt" -gt 1 ] && [ "$PUBLISHER_COUNT" -gt 0 ]; then
  log_conditional "INFO" "BUG-039: Publishers found after $attempt attempts (filesystem sync delay)"
  echo "INFO: Publishers found after $attempt attempts - filesystem sync resolved" >&2
fi

log_conditional "INFO" "Loading $PUBLISHER_COUNT publishers completely (no truncation)..."
echo "INFO: Loading $PUBLISHER_COUNT publishers completely (no truncation)..." >&2

# Collect publisher IDs
PUBLISHERS_LOADED=()
for publisher_file in "${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}"/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id="$(basename "$publisher_file" .md)"
  PUBLISHERS_LOADED+=("$publisher_id")
done

# Verify count matches
if [ ${#PUBLISHERS_LOADED[@]} -ne "$PUBLISHER_COUNT" ]; then
  log_conditional "ERROR" "Publisher count mismatch: expected $PUBLISHER_COUNT, loaded ${#PUBLISHERS_LOADED[@]}"
  echo '{"success": false, "error": "Publisher count mismatch: expected '"$PUBLISHER_COUNT"', loaded '"${#PUBLISHERS_LOADED[@]}"'"}'
  exit 1
fi

log_conditional "INFO" "VERIFICATION: All $PUBLISHER_COUNT publishers loaded completely"
echo "VERIFICATION: All $PUBLISHER_COUNT publishers loaded completely" >&2

# VERIFICATION CHECKPOINT: Confirm completeness before proceeding
if [ ${#SOURCES_TO_PROCESS[@]} -eq 0 ]; then
  log_conditional "INFO" "No sources to process - exiting with success"
  echo '{"success": true, "citations_created": 0, "citations_skipped": 0, "publisher_matches": {"domain_exact": 0, "name_exact": 0, "domain_parent": 0, "reverse_index": 0, "domain_fallback": 0}}'
  exit 0
fi

# CRITICAL: Verify publishers exist before proceeding
if [ ${#PUBLISHERS_LOADED[@]} -eq 0 ]; then
  log_conditional "ERROR" "No publishers loaded - cannot generate citations without publisher entities"
  echo '{"success": false, "error": "No publishers loaded - cannot generate citations without publisher entities"}' >&2
  exit 1
fi

log_conditional "INFO" "CHECKPOINT: Complete entity loading verified"
log_metric "sources_loaded" "${#SOURCES_TO_PROCESS[@]}" "count"
log_metric "publishers_loaded" "${#PUBLISHERS_LOADED[@]}" "count"
log_phase "Phase 2: Entity Loading" "complete"

echo "===========================================" >&2
echo "CHECKPOINT: Complete entity loading verified" >&2
echo "- Sources: ${#SOURCES_TO_PROCESS[@]}" >&2
echo "- Publishers: ${#PUBLISHERS_LOADED[@]}" >&2
echo "- Ready to proceed with publisher matching" >&2
echo "===========================================" >&2

# ===== PHASE 3: PARTITION FILTERING =====
log_phase "Phase 3: Partition Filtering" "start"
if [ -n "$PARTITION" ]; then
  log_conditional "INFO" "Applying partition filter using partition-entities.sh: $PARTITION"
  echo "Partition mode: $PARTITION" >&2

  # Parse partition (format: "1/4" means partition 1 of 4)
  PARTITION_NUM="$(echo "$PARTITION" | cut -d'/' -f1)"
  TOTAL_PARTITIONS="$(echo "$PARTITION" | cut -d'/' -f2)"

  # Convert 1-based to 0-based index for partition-entities.sh
  PARTITION_INDEX=$((PARTITION_NUM - 1))

  # BUG-018 FIX: Validate partition index is non-negative
  if [ "$PARTITION_INDEX" -lt 0 ]; then
    log_conditional "ERROR" "Invalid partition number: must be >= 1"
    echo '{"success": false, "error": "Invalid partition: must be >= 1"}' >&2
    exit 1
  fi

  # Validate partition parameters
  if [ "$PARTITION_NUM" -lt 1 ] || [ "$PARTITION_NUM" -gt "$TOTAL_PARTITIONS" ]; then
    log_conditional "ERROR" "Invalid partition: $PARTITION (must be 1/$TOTAL_PARTITIONS to $TOTAL_PARTITIONS/$TOTAL_PARTITIONS)"
    echo '{"success": false, "error": "Invalid partition: '"$PARTITION"'"}' >&2
    exit 1
  fi

  # Locate partition-entities.sh (SCRIPT_DIR captured before cd in BUG-040 fix)
  PARTITION_SCRIPT="${SCRIPT_DIR}/partition-entities.sh"

  if [ ! -f "$PARTITION_SCRIPT" ]; then
    log_conditional "ERROR" "partition-entities.sh not found: $PARTITION_SCRIPT"
    echo '{"success": false, "error": "partition-entities.sh not found: '"$PARTITION_SCRIPT"'"}' >&2
    exit 1
  fi

  log_conditional "INFO" "Calling partition-entities.sh with partition-index=$PARTITION_INDEX, total-partitions=$TOTAL_PARTITIONS"

  # Call partition-entities.sh to get slice
  partition_result="$(bash "$PARTITION_SCRIPT" \
    --entity-dir "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}" \
    --pattern "source-*.md" \
    --partition-index "$PARTITION_INDEX" \
    --total-partitions "$TOTAL_PARTITIONS" \
    --json 2>&1)"

  partition_exit_code=$?

  if [ $partition_exit_code -ne 0 ]; then
    log_conditional "ERROR" "partition-entities.sh failed with exit code $partition_exit_code"
    log_conditional "ERROR" "Output: $partition_result"
    echo '{"success": false, "error": "partition-entities.sh failed: '"$partition_result"'"}' >&2
    exit 1
  fi

  # Log partition calculation results for debugging
  log_conditional "INFO" "Partition calculation results:"
  log_conditional "INFO" "  JSON output: $(echo "$partition_result" | jq -c .)"
  total_entities="$(echo "$partition_result" | jq -r '.total_entities')"
  partition_size="$(echo "$partition_result" | jq -r '.partition_size')"
  entities_in_partition="$(echo "$partition_result" | jq -r '.entities_in_partition')"
  partition_start="$(echo "$partition_result" | jq -r '.partition_start')"
  partition_end="$(echo "$partition_result" | jq -r '.partition_end')"

  log_conditional "INFO" "  Total entities in directory: $total_entities"
  log_conditional "INFO" "  Partition size (max per partition): $partition_size"
  log_conditional "INFO" "  Entities in this partition: $entities_in_partition"
  log_conditional "INFO" "  Partition slice: [$partition_start, $partition_end)"

  # Extract file list from JSON and convert to source IDs
  partition_files="$(echo "$partition_result" | jq -r '.entity_files[]')"

  # Build new SOURCES_TO_PROCESS array from partition files
  FILTERED_SOURCES=()
  for file_path in $partition_files; do
    source_id="$(basename "$file_path" .md)"
    FILTERED_SOURCES+=("$source_id")
  done

  SOURCES_TO_PROCESS=("${FILTERED_SOURCES[@]}")

  log_conditional "INFO" "Processing partition $PARTITION_NUM/$TOTAL_PARTITIONS: ${#SOURCES_TO_PROCESS[@]} sources"
  echo "Processing partition $PARTITION_NUM/$TOTAL_PARTITIONS: ${#SOURCES_TO_PROCESS[@]} sources" >&2
  log_metric "partition_sources" "${#SOURCES_TO_PROCESS[@]}" "count"
fi
log_phase "Phase 3: Partition Filtering" "complete"

echo "Sources to process in this invocation: ${#SOURCES_TO_PROCESS[@]}" >&2

# =============================================================================
# SUBDOMAIN NORMALIZATION FUNCTION (Sprint 279)
# =============================================================================
# Purpose: Normalize domain variations to improve publisher matching
# Handles: www. removal, subdomain mapping to parent domains
# Returns: Normalized domain string

normalize_domain_with_subdomain() {
  local domain="$1"

  # Step 1: Remove www. prefix (preserves other subdomains)
  domain="$(echo "$domain" | sed 's/^www\.//')"

  # Step 2: Apply subdomain mapping rules
  # Format: specific.subdomain.com → parent.com

  case "$domain" in
    # International Organizations - World Bank family
    treasury.worldbank.org|data.worldbank.org|blogs.worldbank.org)
      echo "worldbank.org" ;;

    # Academic Publishers - Wiley
    onlinelibrary.wiley.com|analyticalsciencejournals.onlinelibrary.wiley.com)
      echo "wiley.com" ;;

    # Academic Publishers - University presses
    journals.uchicago.edu)
      echo "uchicago.edu" ;;

    # Government/Research - NIH/PubMed
    pmc.ncbi.nlm.nih.gov|pubmed.ncbi.nlm.nih.gov)
      echo "nih.gov" ;;

    # European Union - Keep first-level subdomain
    # Example: research-and-innovation.ec.europa.eu → ec.europa.eu
    *.europa.eu)
      echo "$domain" | sed -E 's/^[^.]+\.([^.]+\.europa\.eu)$/\1/' ;;

    # Corporate Subdomains - BNP Paribas
    globalmarkets.cib.bnpparibas|cib.bnpparibas)
      echo "bnpparibas.com" ;;

    # Default: return as-is (no normalization)
    *)
      echo "$domain" ;;
  esac
}

# Verify function is available
if ! declare -f normalize_domain_with_subdomain > /dev/null; then
  log_conditional "ERROR" "normalize_domain_with_subdomain function not defined"
  echo "ERROR: normalize_domain_with_subdomain function not defined" >&2
  exit 1
fi

# ===== PHASE 4: COMPREHENSIVE PUBLISHER INDEXING =====
log_phase "Phase 4: Publisher Indexing" "start"
log_conditional "INFO" "Building comprehensive publisher lookup structures..."
echo "Building comprehensive publisher lookup structures..." >&2

# SECURITY FIX (BUG-007): Create temporary directory using unpredictable name
TEMP_DIR="$(mktemp -d)" || {
  log_conditional "ERROR" "Failed to create temp directory"
  echo '{"success": false, "error": "Failed to create temp directory"}' >&2
  exit 1
}
trap "rm -rf '$TEMP_DIR'" EXIT

# Strategy 1: Build domain→publisher index file
DOMAIN_INDEX="${TEMP_DIR}/domain_index.txt"
> "$DOMAIN_INDEX"

for publisher_file in "${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}"/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id="$(basename "$publisher_file" .md)"

  # Extract domain using proper YAML parsing
  # Publishers use "domain:" field in YAML frontmatter
  publisher_domain="$(grep "^domain:" "$publisher_file" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')"

  if [ -n "$publisher_domain" ]; then
    # Normalize domain (lowercase first, then subdomain normalization)
    normalized_domain="$(echo "$publisher_domain" | tr '[:upper:]' '[:lower:]')"
    normalized_domain="$(normalize_domain_with_subdomain "$normalized_domain")"
    echo "${normalized_domain}|${publisher_id}" >> "$DOMAIN_INDEX"
  fi
done

domain_count="$(wc -l < "$DOMAIN_INDEX" | tr -d ' ')"
log_conditional "INFO" "Strategy 1: Indexed ${domain_count} publishers by domain"
echo "Strategy 1: Indexed ${domain_count} publishers by domain" >&2

# DEBUG: Show first 10 entries of domain index
echo "DEBUG: First 10 domain index entries:" >&2
head -10 "$DOMAIN_INDEX" >&2

# Strategy 2: Build name→publisher index file
NAME_INDEX="${TEMP_DIR}/name_index.txt"
> "$NAME_INDEX"

for publisher_file in "${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}"/*.md; do
  [ -f "$publisher_file" ] || continue
  publisher_id="$(basename "$publisher_file" .md)"

  # Extract publisher name using proper YAML parsing
  publisher_name="$(grep "^name:" "$publisher_file" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")"

  if [ -n "$publisher_name" ]; then
    # Normalize for matching (lowercase, remove non-alphanumeric)
    normalized_name="$(echo "$publisher_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
    echo "${normalized_name}|${publisher_id}" >> "$NAME_INDEX"
  fi
done

name_count="$(wc -l < "$NAME_INDEX" | tr -d ' ')"
log_conditional "INFO" "Strategy 2: Indexed ${name_count} publishers by name"
echo "Strategy 2: Indexed ${name_count} publishers by name" >&2

# Strategy 3: Build reverse index (source→publisher) - SKIPPED FOR SPEED
REVERSE_INDEX="${TEMP_DIR}/reverse_index.txt"
> "$REVERSE_INDEX"

# Skip reverse index building for now - rely on domain and name matching
reverse_count=0
log_conditional "INFO" "Strategy 3: Indexed ${reverse_count} source→publisher reverse links (skipped)"
echo "Strategy 3: Indexed ${reverse_count} source→publisher reverse links (skipped)" >&2
log_phase "Phase 4: Publisher Indexing" "complete"

# ===== PHASE 5: MULTI-STRATEGY PUBLISHER RESOLUTION & CITATION GENERATION =====
log_phase "Phase 5: Citation Generation" "start"

# Initialize counters
citations_created=0
citations_skipped=0
match_domain_exact=0
match_name_exact=0  # BUG-011: Always 0 (Strategy 2 removed)
match_domain_parent=0  # Sprint 279: Parent domain fallback strategy
match_reverse_index=0
match_domain_fallback=0

# Ensure citations directory exists
mkdir -p "${PROJECT_PATH}/${DIR_CITATIONS}/${DATA_SUBDIR}"

# Locate the APA citation generator script (SCRIPT_DIR captured before cd in BUG-040 fix)
APA_SCRIPT="${SCRIPT_DIR}/generate-apa-citation.sh"

if [ ! -f "$APA_SCRIPT" ]; then
  log_conditional "ERROR" "APA citation script not found: $APA_SCRIPT"
  echo '{"success": false, "error": "APA citation script not found: '"$APA_SCRIPT"'"}' >&2
  exit 1
fi

for source_id in "${SOURCES_TO_PROCESS[@]}"; do
  SOURCE_FILE="${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}/${source_id}.md"

  # Verify source file exists
  if [ ! -f "$SOURCE_FILE" ]; then
    log_conditional "WARN" "Source file not found: $SOURCE_FILE"
    echo "WARNING: Source file not found: $SOURCE_FILE" >&2
    continue
  fi

  # Check if citation already exists for this source (idempotency)
  SOURCE_SLUG="$(echo "$source_id" | sed 's/^source-//')"
  EXISTING_CITATION="$(find "${PROJECT_PATH}/${DIR_CITATIONS}/${DATA_SUBDIR}" -name "citation-${SOURCE_SLUG}-*.md" 2>/dev/null | head -1)"

  if [ -n "$EXISTING_CITATION" ]; then
    log_conditional "DEBUG" "Citation already exists for $source_id, skipping"
    echo "Citation already exists for $source_id ($(basename "$EXISTING_CITATION")), skipping..." >&2
    citations_skipped=$((citations_skipped + 1))
    continue
  fi

  log_conditional "INFO" "Processing source: $source_id"
  echo "Processing source: $source_id" >&2

  # SECURITY FIX (BUG-009): Extract source metadata using proper YAML parsing with validation
  TITLE="$(grep "^title:" "$SOURCE_FILE" | head -1 | sed 's/^title:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")"
  URL="$(grep "^url:" "$SOURCE_FILE" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/"//g')"
  DOMAIN="$(grep "^domain:" "$SOURCE_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')"
  TIER="$(grep "^reliability_tier:" "$SOURCE_FILE" | head -1 | sed 's/^reliability_tier:[[:space:]]*//')"
  DOI="$(grep "^doi:" "$SOURCE_FILE" | head -1 | sed 's/^doi:[[:space:]]*//' | sed 's/"//g')"
  PMID="$(grep "^pmid:" "$SOURCE_FILE" | head -1 | sed 's/^pmid:[[:space:]]*//' | sed 's/"//g')"
  ACCESS_DATE="$(grep "^access_date:" "$SOURCE_FILE" | head -1 | sed 's/^access_date:[[:space:]]*//' | sed 's/"//g')"

  # SECURITY FIX (BUG-009): Validate extracted values don't contain multi-line or YAML artifacts
  # Remove any newlines from extracted values
  if [[ "$TITLE" =~ $'\n' ]]; then
    TITLE="$(echo "$TITLE" | head -1)"
  fi
  TITLE="$(echo "$TITLE" | tr -d '\r\n')"

  if [[ "$URL" =~ $'\n' ]]; then
    URL="$(echo "$URL" | head -1)"
  fi
  URL="$(echo "$URL" | tr -d '\r\n')"

  if [[ "$DOMAIN" =~ $'\n' ]]; then
    DOMAIN="$(echo "$DOMAIN" | head -1)"
  fi
  DOMAIN="$(echo "$DOMAIN" | tr -d '\r\n')"

  if [[ "$ACCESS_DATE" =~ $'\n' ]]; then
    ACCESS_DATE="$(echo "$ACCESS_DATE" | head -1)"
  fi
  ACCESS_DATE="$(echo "$ACCESS_DATE" | tr -d '\r\n')"

  # Validate extracted values don't contain YAML artifacts
  if [[ "$DOMAIN" == *":"* ]] || [[ "$DOMAIN" == *"domain:"* ]]; then
    log_conditional "ERROR" "Extracted domain contains YAML artifacts: $DOMAIN (source: $source_id)"
    echo "ERROR: Extracted domain contains YAML artifacts: $DOMAIN (source: $source_id)" >&2
    continue
  fi

  if [[ "$TITLE" == *"title:"* ]] || [[ "$TITLE" == *"Obsidian"* ]]; then
    log_conditional "ERROR" "Extracted title contains YAML artifacts: $TITLE (source: $source_id)"
    echo "ERROR: Extracted title contains YAML artifacts: $TITLE (source: $source_id)" >&2
    continue
  fi

  if [[ "$URL" == *"url:"* ]] || [[ "$URL" == *"source_url:"* ]]; then
    log_conditional "ERROR" "Extracted URL contains YAML artifacts: $URL (source: $source_id)"
    echo "ERROR: Extracted URL contains YAML artifacts: $URL (source: $source_id)" >&2
    continue
  fi

  # Extract domain from URL for matching
  # Sprint 279: Apply subdomain normalization for consistent matching
  raw_domain="$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | tr '[:upper:]' '[:lower:]')"
  source_domain="$(normalize_domain_with_subdomain "$raw_domain")"

  # DEBUG: Show domain extraction
  echo "  DEBUG: URL='${URL}'" >&2
  echo "  DEBUG: raw_domain='${raw_domain}' → source_domain='${source_domain}'" >&2

  # Initialize publisher resolution
  PUBLISHER_ID=""
  PUBLISHER_NAME=""
  PUBLISHER_TYPE=""
  MATCH_STRATEGY=""

  # ===== MULTI-STRATEGY PUBLISHER RESOLUTION =====

  # Strategy 1: Domain exact match
  if [ -z "$PUBLISHER_ID" ] && [ -n "$source_domain" ]; then
    # DEBUG: Show lookup attempt
    echo "  DEBUG: Looking up source_domain='${source_domain}' in DOMAIN_INDEX" >&2
    grep_result="$(grep "^${source_domain}|" "$DOMAIN_INDEX" 2>/dev/null | head -1)"
    echo "  DEBUG: grep result='${grep_result}'" >&2
    PUBLISHER_ID="$(echo "$grep_result" | cut -d'|' -f2)"
    if [ -n "$PUBLISHER_ID" ]; then
      MATCH_STRATEGY="domain_exact"
      match_domain_exact=$((match_domain_exact + 1))
      log_conditional "INFO" "✓ Strategy 1 (domain_exact): $source_domain → $PUBLISHER_ID"
      echo "  ✓ Strategy 1 (domain_exact): $source_domain → $PUBLISHER_ID" >&2
    else
      echo "  DEBUG: No match found in domain index for '${source_domain}'" >&2
    fi
  fi

  # Strategy 1.5: Parent domain fallback (Sprint 279)
  # Try matching parent domain by stripping leftmost subdomain component
  # Example: blog.example.com → example.com
  if [ -z "$PUBLISHER_ID" ] && [ -n "$source_domain" ]; then
    # Extract parent domain (strip leftmost subdomain)
    parent_domain="$(echo "$source_domain" | sed -E 's/^[^.]+\.//')"

    # Only try if parent is different from original (has subdomain)
    if [ "$parent_domain" != "$source_domain" ]; then
      # Search DOMAIN_INDEX for parent domain
      PUBLISHER_ID="$(grep "^${parent_domain}|" "$DOMAIN_INDEX" 2>/dev/null | head -1 | cut -d'|' -f2)"

      if [ -n "$PUBLISHER_ID" ]; then
        MATCH_STRATEGY="domain_parent"
        match_domain_parent=$((match_domain_parent + 1))
        log_conditional "INFO" "✓ Strategy 1.5 (domain_parent): $source_domain → $parent_domain → $PUBLISHER_ID"
        echo "  ✓ Strategy 1.5 (domain_parent): $source_domain → $parent_domain → $PUBLISHER_ID" >&2
      fi
    fi
  fi

  # Strategy 2: Name exact match - REMOVED (BUG-011 FIX)
  # This strategy read a 'publisher:' field from source entity frontmatter, but per
  # source-creator specification (source-creator/references/entity-templates.md),
  # source entities should NOT contain publisher fields. This strategy caused
  # entity-type confusion errors when source files contained incorrect publisher data.
  # Fix: Removed Strategy 2. Publisher resolution now relies on:
  #   - Strategy 1: Domain exact match
  #   - Strategy 3: Reverse index
  #   - Strategy 4: Domain fallback
  # See: issue-11-analysis.md for detailed investigation
  # if [ -z "$PUBLISHER_ID" ]; then
  #   source_publisher="$(grep "^publisher:" "$SOURCE_FILE" | head -1 | sed 's/^publisher:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")"
  #   if [ -n "$source_publisher" ]; then
  #     normalized="$(echo "$source_publisher" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
  #     PUBLISHER_ID="$(grep "^${normalized}|" "$NAME_INDEX" 2>/dev/null | head -1 | cut -d'|' -f2)"
  #     if [ -n "$PUBLISHER_ID" ]; then
  #       MATCH_STRATEGY="name_exact"
  #       match_name_exact=$((match_name_exact + 1))
  #       log "INFO" "✓ Strategy 2 (name_exact): $source_publisher → $PUBLISHER_ID"
  #       echo "  ✓ Strategy 2 (name_exact): $source_publisher → $PUBLISHER_ID" >&2
  #     fi
  #   fi
  # fi

  # Strategy 3: Reverse index (backward compatibility)
  if [ -z "$PUBLISHER_ID" ]; then
    PUBLISHER_INFO="$(grep "^${source_id}|" "$REVERSE_INDEX" 2>/dev/null | head -1)"
    if [ -n "$PUBLISHER_INFO" ]; then
      PUBLISHER_ID="$(echo "$PUBLISHER_INFO" | cut -d'|' -f2)"
      MATCH_STRATEGY="reverse_index"
      match_reverse_index=$((match_reverse_index + 1))
      log_conditional "INFO" "✓ Strategy 3 (reverse_index): $source_id → $PUBLISHER_ID"
      echo "  ✓ Strategy 3 (reverse_index): $source_id → $PUBLISHER_ID" >&2
    fi
  fi

  # Strategy 4: Domain fallback (no publisher entity found)
  if [ -z "$PUBLISHER_ID" ]; then
    MATCH_STRATEGY="domain_fallback"
    match_domain_fallback=$((match_domain_fallback + 1))
    log_conditional "WARN" "⚠ Strategy 4 (domain_fallback): No publisher found for $source_id (domain: $source_domain)"
    echo "  ⚠ Strategy 4 (domain_fallback): No publisher found for $source_id (domain: $source_domain)" >&2
  fi

  # ===== VALIDATION: Reject empty publisher_id for non-fallback strategies =====
  if [ "$MATCH_STRATEGY" != "domain_fallback" ] && [ -z "$PUBLISHER_ID" ]; then
    log_conditional "ERROR" "Empty publisher_id for strategy $MATCH_STRATEGY (source: $source_id)"
    echo "ERROR: Empty publisher_id for strategy $MATCH_STRATEGY (source: $source_id)" >&2
    continue
  fi

  # ===== EXTRACT PUBLISHER METADATA (if matched) =====
  if [ -n "$PUBLISHER_ID" ]; then
    PUBLISHER_FILE="${PROJECT_PATH}/${DIR_PUBLISHERS}/${DATA_SUBDIR}/${PUBLISHER_ID}.md"
    if [ -f "$PUBLISHER_FILE" ]; then
      PUBLISHER_NAME="$(grep "^name:" "$PUBLISHER_FILE" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")"
      PUBLISHER_TYPE="$(grep "^publisher_type:" "$PUBLISHER_FILE" | head -1 | sed 's/^publisher_type:[[:space:]]*//' | sed 's/"//g')"
    fi
  fi

  # Extract year from access date
  YEAR="$(echo "$ACCESS_DATE" | cut -d'-' -f1)"

  # BUG-038 FIX: Format date for citation with OS-aware date command
  FORMATTED_DATE=""
  # Validate date format before attempting to parse
  if [[ "$ACCESS_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # BSD date (macOS)
      if [ "$LANGUAGE" = "de" ]; then
        # German format: "DD. MMMM YYYY" (script adds "Abgerufen am" prefix)
        FORMATTED_DATE="$(date -j -f "%Y-%m-%d" "$ACCESS_DATE" "+%d. %B %Y" 2>/dev/null || echo "")"
      else
        # English format: "Month Day, Year" (script adds "Retrieved" prefix)
        FORMATTED_DATE="$(date -j -f "%Y-%m-%d" "$ACCESS_DATE" "+%B %d, %Y" 2>/dev/null || echo "")"
      fi
    else
      # GNU date (Linux)
      if [ "$LANGUAGE" = "de" ]; then
        # German format: "DD. MMMM YYYY" (script adds "Abgerufen am" prefix)
        FORMATTED_DATE="$(date -d "$ACCESS_DATE" "+%d. %B %Y" 2>/dev/null || echo "")"
      else
        # English format: "Month Day, Year" (script adds "Retrieved" prefix)
        FORMATTED_DATE="$(date -d "$ACCESS_DATE" "+%B %d, %Y" 2>/dev/null || echo "")"
      fi
    fi
  else
    log_conditional "WARN" "Invalid date format for ACCESS_DATE: $ACCESS_DATE (source: $source_id)"
    echo "WARNING: Invalid date format for ACCESS_DATE: $ACCESS_DATE (source: $source_id)" >&2
    FORMATTED_DATE=""
  fi

  # Determine author/institution parameters for APA script
  AUTHOR_PARAM=""
  INSTITUTION_PARAM=""

  if [ -n "$PUBLISHER_NAME" ]; then
    if [ "$PUBLISHER_TYPE" = "individual" ]; then
      AUTHOR_PARAM="$PUBLISHER_NAME"
    else
      INSTITUTION_PARAM="$PUBLISHER_NAME"
    fi
  fi

  # Generate APA citation using script (already uses jq --arg internally, so safe)
  citation_result="$(bash "$APA_SCRIPT" \
    --title "$TITLE" \
    --url "$URL" \
    --domain "$DOMAIN" \
    --author "$AUTHOR_PARAM" \
    --institution "$INSTITUTION_PARAM" \
    --year "$YEAR" \
    --date "$FORMATTED_DATE" \
    --language "$LANGUAGE" \
    --doi "$DOI" \
    --pmid "$PMID" \
    --json)"

  CITATION_TEXT="$(echo "$citation_result" | jq -r '.citation')"

  # VALIDATION: Check citation doesn't contain YAML artifacts
  if [[ "$CITATION_TEXT" == *"domain:"* ]] || \
     [[ "$CITATION_TEXT" == *"title:"* ]] || \
     [[ "$CITATION_TEXT" == *"url:"* ]] || \
     [[ "$CITATION_TEXT" == *"Udomain:"* ]]; then
    log_conditional "ERROR" "Citation text contains YAML field names (source: $source_id)"
    echo "ERROR: Citation text contains YAML field names (source: $source_id):" >&2
    echo "$CITATION_TEXT" >&2
    continue
  fi

  # VALIDATION: Check German format if language is de
  if [ "$LANGUAGE" = "de" ] && ! [[ "$CITATION_TEXT" == *"Abgerufen am"* ]] && ! [[ "$CITATION_TEXT" == *"n.d."* ]]; then
    log_conditional "WARN" "German citation missing 'Abgerufen am' format (source: $source_id): $CITATION_TEXT"
    echo "WARNING: German citation missing 'Abgerufen am' format (source: $source_id): $CITATION_TEXT" >&2
  fi

  # Generate citation ID (reuse source slug for consistency)
  SOURCE_SLUG="$(echo "$source_id" | sed 's/^source-//')"

  # Generate hash from URL for uniqueness
  CITATION_HASH="$(echo -n "$URL" | shasum -a 256 | cut -c1-8)"

  CITATION_ID="citation-${SOURCE_SLUG}-${CITATION_HASH}"

  # Create citation entity
  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Build publisher wikilink if publisher exists (for Components section)
  PUBLISHER_WIKILINK=""
  if [ -n "$PUBLISHER_ID" ]; then
    PUBLISHER_WIKILINK="- **Publisher**: [[${DIR_PUBLISHERS}/data/${PUBLISHER_ID}]]"
  fi

  # Build publisher_ref frontmatter line if publisher exists (for YAML frontmatter)
  PUBLISHER_REF_LINE=""
  DC_RELATION_PUBLISHER=""
  if [ -n "$PUBLISHER_ID" ]; then
    PUBLISHER_REF_LINE="publisher_ref: \"[[${DIR_PUBLISHERS}/data/${PUBLISHER_ID}]]\""
    DC_RELATION_PUBLISHER=", \"${PUBLISHER_ID}\""
  fi

  # Write citation entity
  cat > "${PROJECT_PATH}/${DIR_CITATIONS}/${DATA_SUBDIR}/${CITATION_ID}.md" <<EOF
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-${TIER}]

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: ${CITATION_ID}"
dc:date: "${TIMESTAMP}"
dc:identifier: "${CITATION_ID}"
dc:type: "citation"
dc:source: "${URL}"
dc:relation: ["${source_id}"${DC_RELATION_PUBLISHER}]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[${DIR_SOURCES}/data/${source_id}]]"
${PUBLISHER_REF_LINE}
citation_format: "APA"
match_strategy: "${MATCH_STRATEGY}"
created_at: "${TIMESTAMP}"
language: "${LANGUAGE}"
---

## Citation

${CITATION_TEXT}

### Components

- **Source**: [[${DIR_SOURCES}/data/${source_id}]]
${PUBLISHER_WIKILINK}
- **Reliability**: Tier ${TIER}
- **Match Strategy**: ${MATCH_STRATEGY}
EOF

  # Increment counter
  citations_created=$((citations_created + 1))

  log_conditional "INFO" "Generated citation: ${CITATION_ID} (strategy: ${MATCH_STRATEGY})"
  echo "Generated citation: ${CITATION_ID} (strategy: ${MATCH_STRATEGY})" >&2
done

# Log metrics for citation generation
log_metric "citations_created" "$citations_created" "count"
log_metric "citations_skipped" "$citations_skipped" "count"
log_metric "match_domain_exact" "$match_domain_exact" "count"
log_metric "match_name_exact" "$match_name_exact" "count"
log_metric "match_reverse_index" "$match_reverse_index" "count"
log_metric "match_domain_fallback" "$match_domain_fallback" "count"
log_phase "Phase 5: Citation Generation" "complete"

# ===== PHASE 6: METADATA RETURN =====
log_phase "Phase 6: Metadata Return" "start"
log_conditional "INFO" "Summary statistics:"
log_conditional "INFO" "  Citations created: $citations_created"
log_conditional "INFO" "  Citations skipped: $citations_skipped"
log_conditional "INFO" "  Publisher matches - domain_exact: $match_domain_exact"
log_conditional "INFO" "  Publisher matches - name_exact: $match_name_exact"
log_conditional "INFO" "  Publisher matches - reverse_index: $match_reverse_index"
log_conditional "INFO" "  Publisher matches - domain_fallback: $match_domain_fallback"

# Calculate domain_fallback percentage and generate warnings if needed
total_citations=${citations_created}
warnings_array=()

if [ $total_citations -gt 0 ]; then
  fallback_pct=$((match_domain_fallback * 100 / total_citations))

  # Warn if >80% used domain_fallback
  if [ $fallback_pct -gt 80 ]; then
    warnings_array+=("${fallback_pct}% citations used domain_fallback - check publisher loading")
  fi
fi

# Build warnings JSON field
warnings_json=""
if [ ${#warnings_array[@]} -gt 0 ]; then
  warnings_json="\"warnings\": ["
  first=true
  for warning in "${warnings_array[@]}"; do
    if [ "$first" = true ]; then
      warnings_json="${warnings_json}\"${warning}\""
      first=false
    else
      warnings_json="${warnings_json},\"${warning}\""
    fi
  done
  warnings_json="${warnings_json}],"
fi

log_conditional "INFO" "Execution completed successfully"
log_conditional "INFO" "Log file: $LOG_FILE"
log_phase "Phase 6: Metadata Return" "complete"

# Generate JSON response (ONLY output)
cat <<EOF
{
  "success": true,
  "citations_created": ${citations_created},
  "citations_skipped": ${citations_skipped},
  ${warnings_json}"publisher_matches": {
    "domain_exact": ${match_domain_exact},
    "name_exact": ${match_name_exact},
    "domain_parent": ${match_domain_parent},
    "reverse_index": ${match_reverse_index},
    "domain_fallback": ${match_domain_fallback}
  }
}
EOF

exit 0
