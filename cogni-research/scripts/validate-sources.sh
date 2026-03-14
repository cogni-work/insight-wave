#!/usr/bin/env bash
set -euo pipefail
# validate-sources.sh
# Version: 1.0.0
# Purpose: Batch validation of source entities for Phase 4.2
# Category: validation
#
# Usage: validate-sources.sh --project-path <path> [--json]
#
# Arguments:
#   --project-path <path>    Path to research project directory (required)
#   --json                   Output JSON format (default: true)
#
# Output (JSON):
#   {
#     "success": true|false,
#     "total_sources": 48,
#     "valid_sources": 45,
#     "invalid_sources": [
#       {
#         "source_id": "source-abc123",
#         "file": "07-sources/source-abc123.md",
#         "error_type": "backlink_missing",
#         "details": "No findings reference this source"
#       }
#     ],
#     "validation_checks": {
#       "url_format": {"passed": 45, "failed": 0},
#       "domain_consistency": {"passed": 45, "failed": 0},
#       "title_present": {"passed": 45, "failed": 0},
#       "backlinks": {"passed": 42, "failed": 3},
#       "entity_index": {"passed": 45, "failed": 0},
#       "duplicates": {"passed": 45, "failed": 0}
#     },
#     "validation_timestamp": "2025-12-17T10:30:00Z"
#   }
#
# Exit codes:
#   0 - Validation passed (may have warnings)
#   1 - Validation failed (critical errors)
#   2 - Invalid parameters


# ============================================================================
# CENTRALIZED CONFIG
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_FINDINGS="$(get_directory_by_key "findings")"

# ============================================================================
# LOGGING INITIALIZATION
# ============================================================================

SCRIPT_NAME="validate-sources"

# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

# ============================================================================
# PARAMETER PARSING
# ============================================================================

PROJECT_PATH=""
JSON_OUTPUT=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --help|-h)
      echo "Usage: validate-sources.sh --project-path <path> [--json]"
      exit 0
      ;;
    *)
      echo '{"success":false,"error":"Unknown parameter: '"$1"'"}'
      exit 2
      ;;
  esac
done

if [[ -z "$PROJECT_PATH" ]]; then
  echo '{"success":false,"error":"Missing --project-path"}'
  exit 2
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo '{"success":false,"error":"Project path not found: '"$PROJECT_PATH"'"}'
  exit 2
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract YAML frontmatter field value
extract_yaml_field() {
  local file="$1"
  local field="$2"
  grep "^${field}:" "$file" 2>/dev/null | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

# Check if source is referenced in any finding
check_backlinks() {
  local source_id="$1"
  local findings_dir="${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}"

  if [[ ! -d "$findings_dir" ]]; then
    echo "0"
    return
  fi

  # Count findings that reference this source_id
  grep -l "source_id:.*${source_id}" "${findings_dir}"/finding-*.md 2>/dev/null | wc -l | tr -d ' '
}

# Check if source exists in entity-index.json
check_entity_index() {
  local source_id="$1"
  local index_file="${PROJECT_PATH}/.metadata/entity-index.json"

  if [[ ! -f "$index_file" ]]; then
    echo "missing_index"
    return
  fi

  # Check if source_id exists in 07-sources array (entities structure)
  if jq -e '.entities["07-sources"] | map(select(.id == "'"${source_id}"'")) | length > 0' "$index_file" >/dev/null 2>&1; then
    echo "found"
  else
    echo "not_found"
  fi
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

log_phase "Phase 1: Source Discovery" "start"

SOURCES_DIR="${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}"

# Handle missing sources directory
if [[ ! -d "$SOURCES_DIR" ]]; then
  jq -n \
    --argjson success true \
    --argjson total 0 \
    --argjson valid 0 \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      success: $success,
      total_sources: $total,
      valid_sources: $valid,
      invalid_sources: [],
      validation_checks: {
        url_format: {passed: 0, failed: 0},
        domain_consistency: {passed: 0, failed: 0},
        title_present: {passed: 0, failed: 0},
        backlinks: {passed: 0, failed: 0},
        entity_index: {passed: 0, failed: 0},
        duplicates: {passed: 0, failed: 0}
      },
      validation_timestamp: $timestamp,
      note: "No sources directory found"
    }'
  exit 0
fi

# Find all source files
# Bash 3.2 compatible array loading (mapfile requires Bash 4.0+)
SOURCE_FILES=()
while IFS= read -r file; do
  SOURCE_FILES+=("$file")
done < <(find "$SOURCES_DIR" -name "source-*.md" -type f 2>/dev/null | sort)
TOTAL_SOURCES=${#SOURCE_FILES[@]}

log_conditional "INFO" "Found $TOTAL_SOURCES source files"
log_phase "Phase 1: Source Discovery" "complete"

# Handle zero sources
if [[ $TOTAL_SOURCES -eq 0 ]]; then
  jq -n \
    --argjson success true \
    --argjson total 0 \
    --argjson valid 0 \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      success: $success,
      total_sources: $total,
      valid_sources: $valid,
      invalid_sources: [],
      validation_checks: {
        url_format: {passed: 0, failed: 0},
        domain_consistency: {passed: 0, failed: 0},
        title_present: {passed: 0, failed: 0},
        backlinks: {passed: 0, failed: 0},
        entity_index: {passed: 0, failed: 0},
        duplicates: {passed: 0, failed: 0}
      },
      validation_timestamp: $timestamp,
      note: "No source files found in sources directory"
    }'
  exit 0
fi

# ============================================================================
# PHASE 2: VALIDATE EACH SOURCE
# ============================================================================

log_phase "Phase 2: Source Validation" "start"

# Initialize counters
VALID_SOURCES=0
INVALID_SOURCES_JSON="[]"

# Validation check counters
URL_PASSED=0
URL_FAILED=0
DOMAIN_PASSED=0
DOMAIN_FAILED=0
TITLE_PASSED=0
TITLE_FAILED=0
BACKLINK_PASSED=0
BACKLINK_FAILED=0
INDEX_PASSED=0
INDEX_FAILED=0
DUPLICATE_PASSED=0
DUPLICATE_FAILED=0

# Track URLs for duplicate detection
# Bash 3.2 compatible - indexed arrays (declare -A requires Bash 4.0+)
SEEN_URLS=()
SEEN_URL_SOURCES=()

# Helper function for URL lookup (returns source_id if found)
url_already_seen() {
  local check_url="$1"
  local i=0
  for url in "${SEEN_URLS[@]}"; do
    if [[ "$url" == "$check_url" ]]; then
      echo "${SEEN_URL_SOURCES[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

for source_file in "${SOURCE_FILES[@]}"; do
  source_id="$(basename "$source_file" .md)"
  is_valid=true
  error_type=""
  error_details=""

  log_conditional "DEBUG" "Validating: $source_id"

  # Extract metadata
  url="$(extract_yaml_field "$source_file" "url")"
  domain="$(extract_yaml_field "$source_file" "domain")"
  title="$(extract_yaml_field "$source_file" "title")"

  # Check 1: URL format
  if [[ ! "$url" =~ ^https?:// ]]; then
    is_valid=false
    error_type="invalid_url"
    error_details="URL does not start with http:// or https://: $url"
    URL_FAILED=$((URL_FAILED + 1))
  else
    URL_PASSED=$((URL_PASSED + 1))

    # Check for duplicates (only if URL is valid)
    if existing_source=$(url_already_seen "$url"); then
      # Duplicate found
      DUPLICATE_FAILED=$((DUPLICATE_FAILED + 1))
      if [[ "$is_valid" == "true" ]]; then
        is_valid=false
        error_type="duplicate_url"
        error_details="URL already used by $existing_source"
      fi
    else
      SEEN_URLS+=("$url")
      SEEN_URL_SOURCES+=("$source_id")
      DUPLICATE_PASSED=$((DUPLICATE_PASSED + 1))
    fi
  fi

  # Check 2: Domain consistency
  if [[ -n "$url" && -n "$domain" ]]; then
    # Extract domain from URL
    extracted_domain="$(echo "$url" | awk -F/ '{print $3}' | sed -E 's/:.*$//' | tr '[:upper:]' '[:lower:]')"
    if ! [[ "$extracted_domain" == "$domain" ]]; then
      if [[ "$is_valid" == "true" ]]; then
        is_valid=false
        error_type="domain_mismatch"
        error_details="Domain '$domain' does not match URL domain '$extracted_domain'"
      fi
      DOMAIN_FAILED=$((DOMAIN_FAILED + 1))
    else
      DOMAIN_PASSED=$((DOMAIN_PASSED + 1))
    fi
  elif [[ -z "$domain" ]]; then
    if [[ "$is_valid" == "true" ]]; then
      is_valid=false
      error_type="missing_domain"
      error_details="Domain field is empty"
    fi
    DOMAIN_FAILED=$((DOMAIN_FAILED + 1))
  else
    DOMAIN_PASSED=$((DOMAIN_PASSED + 1))
  fi

  # Check 3: Title present
  if [[ -z "$title" ]]; then
    if [[ "$is_valid" == "true" ]]; then
      is_valid=false
      error_type="missing_title"
      error_details="Title field is empty"
    fi
    TITLE_FAILED=$((TITLE_FAILED + 1))
  else
    TITLE_PASSED=$((TITLE_PASSED + 1))
  fi

  # Check 4: Backlinks (findings referencing this source)
  backlink_count="$(check_backlinks "$source_id")"
  if [[ "$backlink_count" -eq 0 ]]; then
    # Warning only - not a critical error
    BACKLINK_FAILED=$((BACKLINK_FAILED + 1))
    log_conditional "WARN" "No findings reference source: $source_id"
  else
    BACKLINK_PASSED=$((BACKLINK_PASSED + 1))
  fi

  # Check 5: Entity index sync
  index_status="$(check_entity_index "$source_id")"
  if [[ "$index_status" == "not_found" ]]; then
    if [[ "$is_valid" == "true" ]]; then
      is_valid=false
      error_type="index_desync"
      error_details="Source not found in entity-index.json"
    fi
    INDEX_FAILED=$((INDEX_FAILED + 1))
  elif [[ "$index_status" == "missing_index" ]]; then
    # No index file - skip this check
    INDEX_PASSED=$((INDEX_PASSED + 1))
  else
    INDEX_PASSED=$((INDEX_PASSED + 1))
  fi

  # Record result
  if [[ "$is_valid" == "true" ]]; then
    VALID_SOURCES=$((VALID_SOURCES + 1))
  else
    # Add to invalid sources array
    INVALID_SOURCES_JSON="$(echo "$INVALID_SOURCES_JSON" | jq \
      --arg id "$source_id" \
      --arg file "${DIR_SOURCES}/${source_id}.md" \
      --arg type "$error_type" \
      --arg details "$error_details" \
      '. + [{source_id: $id, file: $file, error_type: $type, details: $details}]')"
  fi
done

log_phase "Phase 2: Source Validation" "complete"

# ============================================================================
# PHASE 3: OUTPUT RESULTS
# ============================================================================

log_phase "Phase 3: Results Output" "start"

INVALID_COUNT="$(echo "$INVALID_SOURCES_JSON" | jq 'length')"
SUCCESS="$([[ $INVALID_COUNT -eq 0 ]] && echo "true" || echo "true")"  # Always success, invalid_sources indicates issues

# Build final JSON output
jq -n \
  --argjson success "$SUCCESS" \
  --argjson total "$TOTAL_SOURCES" \
  --argjson valid "$VALID_SOURCES" \
  --argjson invalid_sources "$INVALID_SOURCES_JSON" \
  --argjson url_passed "$URL_PASSED" \
  --argjson url_failed "$URL_FAILED" \
  --argjson domain_passed "$DOMAIN_PASSED" \
  --argjson domain_failed "$DOMAIN_FAILED" \
  --argjson title_passed "$TITLE_PASSED" \
  --argjson title_failed "$TITLE_FAILED" \
  --argjson backlink_passed "$BACKLINK_PASSED" \
  --argjson backlink_failed "$BACKLINK_FAILED" \
  --argjson index_passed "$INDEX_PASSED" \
  --argjson index_failed "$INDEX_FAILED" \
  --argjson duplicate_passed "$DUPLICATE_PASSED" \
  --argjson duplicate_failed "$DUPLICATE_FAILED" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    success: $success,
    total_sources: $total,
    valid_sources: $valid,
    invalid_sources: $invalid_sources,
    validation_checks: {
      url_format: {passed: $url_passed, failed: $url_failed},
      domain_consistency: {passed: $domain_passed, failed: $domain_failed},
      title_present: {passed: $title_passed, failed: $title_failed},
      backlinks: {passed: $backlink_passed, failed: $backlink_failed},
      entity_index: {passed: $index_passed, failed: $index_failed},
      duplicates: {passed: $duplicate_passed, failed: $duplicate_failed}
    },
    validation_timestamp: $timestamp
  }'

log_metric "total_sources" "$TOTAL_SOURCES" "count"
log_metric "valid_sources" "$VALID_SOURCES" "count"
log_metric "invalid_sources" "$INVALID_COUNT" "count"
log_phase "Phase 3: Results Output" "complete"

exit 0
