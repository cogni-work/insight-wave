#!/usr/bin/env bash
set -euo pipefail
# source-creator/script.sh
# Purpose: Extract source metadata from findings and create deduplicated source entities
# Version: 3.8.0 - Fix URL collision detection to prevent orphaned source_id backlinks
# Category: deeper-research Phase 6.1
# Usage: ./script.sh --finding-list-file <file> --project-path <path> [--language <lang>] [--partition-index <n>] [--total-partitions <n>]
#
# Environment Variables:
#   QUIET_MODE - Set to "true" to suppress all progress logging (default: false)
#   DEBUG_MODE - Set to "true" to enable verbose logging to file and stderr (default: false)
#                Creates .metadata/source-creator-execution-log.txt when enabled
#
# Exit codes:
#   0 - Success
#   1 - Environment/validation error (CLAUDE_PLUGIN_ROOT not set, scripts not found)
#   2 - Parameter validation error (missing/invalid arguments)
#
# Changelog:
# - v3.8.0: Fix URL collision detection to prevent orphaned source_id backlinks (Issue #85)
#           - Check if URL already exists BEFORE generating semantic slug
#           - Reuse existing source_id for all findings with same URL
#           - Prevents broken wikilinks when findings have different titles but same URL
# - v3.7.0: Fix wikilink fallbacks for multi-project workspaces
#           - Fallback wikilinks now include workspace prefix when PROJECT_AGENTS_OPS_ROOT is set
#           - Prevents broken wikilinks in Obsidian multi-project vault setups
# - v3.6.0: Fix publisher ID mismatch with publisher-generator (Issue #84)
#           - Use shared generate-publisher-id.sh utility for consistent ID generation
#           - Publisher IDs now use name+hash algorithm: publisher-{slug}-{hash}
#           - Eliminates orphaned publishers caused by ID algorithm mismatch
#           - Example: www.pnas.org -> publisher-pnas-d25bff0d (not publisher-www-pnas-org)
# - v3.5.0: Fix source wikilinks in finding backlinks (Issue #83)
#           - Use generate-wikilink.sh for source_id field in findings
#           - Source backlinks now use proper wikilink format: [[05-sources/data/source-xxx]]
#           - Enables Obsidian graph navigation from findings to sources
# - v3.4.0: Harden URL/title extraction to handle all quote styles (Issue #82)
#           - Handle double quotes, single quotes, and no quotes in source_url/dc:title
#           - Add CRLF normalization for Windows line endings
#           - Add jq error handling to prevent cascade failures
#           - Improve frontmatter detection validation
# - v3.3.0: Add collision detection and URL-to-source mapping (Issue #78, Sprint 301)
#           - Track unique_urls_processed metric
#           - Detect and warn on URL collisions (same source_id for different URLs)
#           - Fail validation when collision rate exceeds 10%
#           - Add url_source_mapping in DEBUG_MODE output
# - v3.2.0: Add execution log file support when DEBUG_MODE=true
#           Log file: .metadata/source-creator-execution-log.txt
#           Use log_message() function for consistent logging to both stderr and file
# - v3.1.1: Remove hardcoded QUIET_MODE=true - respect environment variable instead
#           Allow DEBUG_MODE to enable logging even when called from skills
# - v3.1.0: Add QUIET_MODE environment variable to suppress all progress logging to stderr
#           Fixes JSON output contamination when script is called from skills/agents
# - v3.0.0: Refactored to use create-entity.sh infrastructure (Sprint 256)


# Error trap for debugging - logs failing command and line number before exit
# This is critical for diagnosing silent failures with set -e
trap 'echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ERROR: Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# Don't hardcode QUIET_MODE - let it be controlled by environment or parent process
# If DEBUG_MODE is set, ensure logging is enabled
if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
  export QUIET_MODE=false
fi

# ============================================================================
# Phase 0: Parameter Validation
# ============================================================================

PROJECT_PATH=""
FINDING_LIST_FILE=""
LANGUAGE="en"
PARTITION_INDEX=""
TOTAL_PARTITIONS=""

# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --finding-list-file)
      FINDING_LIST_FILE="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --partition-index|--partition-num|--partition-id)
      PARTITION_INDEX="$2"
      shift 2
      ;;
    --total-partitions)
      TOTAL_PARTITIONS="$2"
      shift 2
      ;;
    *)
      echo "{\"success\": false, \"error\": \"Unknown parameter: $1\"}" >&2
      exit 2
      ;;
  esac
done

# Validate required parameters
if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 2
fi

if [ -z "$FINDING_LIST_FILE" ]; then
  echo '{"success": false, "error": "Missing required parameter: --finding-list-file"}' >&2
  exit 2
fi

if [ ! -f "$FINDING_LIST_FILE" ]; then
  echo "{\"success\": false, \"error\": \"Finding list file not found: $FINDING_LIST_FILE\"}" >&2
  exit 2
fi

# Read file and convert to comma-separated for internal processing
FINDING_FILES="$(cat "$FINDING_LIST_FILE" | tr '\n' ',' | sed 's/,$//')"

# Validate language format (ISO 639-1)
if [[ ! "$LANGUAGE" =~ ^[a-z]{2}$ ]]; then
  echo "{\"success\": false, \"error\": \"Invalid language code (must be 2-letter ISO 639-1): $LANGUAGE\"}" >&2
  exit 2
fi

# Validate partitioning parameters if provided
if [ -n "$PARTITION_INDEX" ] || [ -n "$TOTAL_PARTITIONS" ]; then
  if [ -z "$PARTITION_INDEX" ] || [ -z "$TOTAL_PARTITIONS" ]; then
    echo '{"success": false, "error": "Both --partition-index and --total-partitions required for parallel execution"}' >&2
    exit 2
  fi
  if ! [[ "$PARTITION_INDEX" =~ ^[0-9]+$ ]] || ! [[ "$TOTAL_PARTITIONS" =~ ^[0-9]+$ ]]; then
    echo '{"success": false, "error": "Partition parameters must be numeric"}' >&2
    exit 2
  fi
fi

# ============================================================================
# Phase 1: Environment Setup & Working Directory Validation
# ============================================================================

# ===== PLUGIN ROOT RESOLUTION =====
# Auto-detect CLAUDE_PLUGIN_ROOT if not set (resolve-plugin-root.sh pattern)
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  # Derive from script location: /plugin/scripts/source-creator.sh -> /plugin
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

# Determine script directory for calling create-entity.sh
SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"

# Validate scripts directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
  echo "{\"success\": false, \"error\": \"Scripts directory not found: $SCRIPT_DIR\"}" >&2
  exit 1
fi

# Validate create-entity.sh exists
if [ ! -f "$SCRIPT_DIR/create-entity.sh" ]; then
  echo "{\"success\": false, \"error\": \"create-entity.sh not found: $SCRIPT_DIR/create-entity.sh\"}" >&2
  exit 1
fi

# Validate project path exists
if [ ! -d "$PROJECT_PATH" ]; then
  echo "{\"success\": false, \"error\": \"Project path does not exist: $PROJECT_PATH\"}" >&2
  exit 1
fi

# Source centralized entity config
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi

if [ -z "$ENTITY_CONFIG" ]; then
  echo "{\"success\": false, \"error\": \"entity-config.sh not found in CLAUDE_PLUGIN_ROOT\"}" >&2
  exit 1
fi

source "$ENTITY_CONFIG"
DATA_SUBDIR="$(get_data_subdir)"

# Create metadata directory
mkdir -p "${PROJECT_PATH}/.metadata"
mkdir -p "${PROJECT_PATH}/05-sources/${DATA_SUBDIR}"

# Initialize log file for DEBUG_MODE
if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
  LOG_FILE="${PROJECT_PATH}/.metadata/source-creator-execution-log.txt"
  echo "========================================" > "$LOG_FILE"
  echo "Source Creator Execution Log" >> "$LOG_FILE"
  echo "Started: $(date +%Y-%m-%d\ %H:%M:%S)" >> "$LOG_FILE"
  echo "PROJECT_PATH: $PROJECT_PATH" >> "$LOG_FILE"
  echo "LANGUAGE: $LANGUAGE" >> "$LOG_FILE"
  if [[ -n "$PARTITION_INDEX" ]]; then
    echo "PARTITION: $((PARTITION_INDEX + 1))/$TOTAL_PARTITIONS" >> "$LOG_FILE"
  fi
  echo "========================================" >> "$LOG_FILE"
else
  LOG_FILE="/dev/null"
fi

# Helper function for logging
# Note: Use || true to prevent ERR trap from firing on false conditions with &&
log_message() {
  local message="$1"
  if ! [[ "${QUIET_MODE:-false}" == "true" ]]; then
    echo "$message" >&2
    if ! [[ "$LOG_FILE" == "/dev/null" ]]; then
      echo "$message" >> "$LOG_FILE"
    fi
  elif ! [[ "$LOG_FILE" == "/dev/null" ]]; then
    echo "$message" >> "$LOG_FILE"
  fi
}

# Helper function for safe jq array append (prevents cascade failures)
# Usage: ARRAY="$(safe_jq_append "$ARRAY" "$ENTRY" "context_message")"
safe_jq_append() {
  local array="$1"
  local entry="$2"
  local context="${3:-unknown}"
  local result

  result="$(echo "$array" | jq --argjson entry "$entry" '. + [$entry]' 2>/dev/null)"
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo "$result"
  else
    log_message "WARNING: Failed to append jq entry for $context"
    echo "$array"  # Return original array unchanged
  fi
}

# Helper function to extract YAML field value (handles all quote styles)
# Usage: VALUE="$(extract_yaml_field "field_name" "$FILE_PATH")"
# Handles: field: "value", field: 'value', field: value
extract_yaml_field() {
  local field="$1"
  local file="$2"
  local value

  # Extract the line, strip field name, handle quotes, remove CRLF
  value="$(grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    sed -E "s/^${field}:[[:space:]]*//" | \
    sed -E 's/^["'"'"']|["'"'"']$//g' | \
    tr -d '\r')"

  echo "$value"
}

# ============================================================================
# Phase 2: Load & Partition Findings
# ============================================================================

# Convert comma-separated findings to array
IFS=',' read -ra FINDING_FILES_ARRAY <<< "$FINDING_FILES"

# Initialize counters and tracking
sources_created=0
sources_reused=0
findings_updated=0
skipped_count=0
error_count=0
backlink_errors=0
SKIPPED_SOURCES='[]'

# Issue #78: Collision detection tracking
UNIQUE_URLS_PROCESSED=0
COLLISION_COUNT=0
COLLISION_WARNINGS='[]'
# Bash 3.2 compatible: use temp file instead of associative array
COLLISION_TRACKING_FILE="$(mktemp)"
trap 'rm -f "$COLLISION_TRACKING_FILE"' EXIT
URL_SOURCE_MAPPING='{}'      # JSON object for DEBUG_MODE output

# Handle empty findings
if [ ${#FINDING_FILES_ARRAY[@]} -eq 0 ]; then
  REPORT="$(jq -n '{
    "success": true,
    "sources_created": 0,
    "sources_reused": 0,
    "findings_updated": 0,
    "validation_passed": true,
    "total_findings": 0,
    "skipped": 0,
    "skipped_sources": [],
    "skip_reasons_summary": {}
  }')"
  echo "$REPORT" > "${PROJECT_PATH}/.logs/source-creator-statistics.json"
  echo "$REPORT"
  exit 0
fi

# Calculate partition slice if partitioning
START_INDEX=0
END_INDEX=${#FINDING_FILES_ARRAY[@]}
PARTITION_MODE=false

if [ -n "$PARTITION_INDEX" ] && [ -n "$TOTAL_PARTITIONS" ]; then
  PARTITION_MODE=true
  PARTITION_SIZE=$(( (${#FINDING_FILES_ARRAY[@]} + TOTAL_PARTITIONS - 1) / TOTAL_PARTITIONS ))
  START_INDEX=$(( PARTITION_INDEX * PARTITION_SIZE ))
  END_INDEX=$(( START_INDEX + PARTITION_SIZE ))

  if [ $END_INDEX -gt ${#FINDING_FILES_ARRAY[@]} ]; then
    END_INDEX=${#FINDING_FILES_ARRAY[@]}
  fi
fi

# Create findings to process array
FINDINGS_TO_PROCESS=()
for ((i=START_INDEX; i<END_INDEX; i++)); do
  FINDINGS_TO_PROCESS+=("${FINDING_FILES_ARRAY[$i]}")
done

# Store total findings in this partition for later validation
PARTITION_FINDINGS_COUNT=${#FINDINGS_TO_PROCESS[@]}

# ============================================================================
# Phase 3: Iteration & Processing (Main Loop)
# ============================================================================

for i in "${!FINDINGS_TO_PROCESS[@]}"; do
  FINDING_FILE="${FINDINGS_TO_PROCESS[$i]}"
  FINDING_ID="$(basename "$FINDING_FILE" .md)"

  # Sub-Phase 3.1: File Validation

  log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Phase 3.1: File Validation - Processing $FINDING_FILE"

  # Make path absolute if relative
  if [[ ! "$FINDING_FILE" = /* ]]; then
    FINDING_FILE="${PROJECT_PATH}/${FINDING_FILE}"
  fi

  # Validate file exists and is readable
  if [ ! -f "$FINDING_FILE" ] || [ ! -r "$FINDING_FILE" ]; then
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "file_not_found_or_unreadable" \
      --arg message "Finding file does not exist or is not readable" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Normalize CRLF line endings (handle Windows-created files)
  if grep -q $'\r' "$FINDING_FILE" 2>/dev/null; then
    TMP_NORMALIZED="${FINDING_FILE}.normalized"
    tr -d '\r' < "$FINDING_FILE" > "$TMP_NORMALIZED"
    mv "$TMP_NORMALIZED" "$FINDING_FILE"
    log_message "Normalized CRLF line endings in $FINDING_FILE"
  fi

  # Sub-Phase 3.2: No-Results Detection

  if grep -q '^url:[[:space:]]*""' "$FINDING_FILE" || \
     grep -q '^tags:.*no-results' "$FINDING_FILE" || \
     grep -q '^title:.*"No Results:' "$FINDING_FILE" || \
     grep -q '^search_success_level:[[:space:]]*"exhausted"' "$FINDING_FILE"; then

    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "no_results_finding" \
      --arg message "Finding represents exhausted search with no source" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Sub-Phase 3.3: Metadata Extraction

  # Extract source_url from finding (handles "url", 'url', and url formats)
  SOURCE_URL="$(extract_yaml_field "source_url" "$FINDING_FILE")"

  if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = '""' ] || [ "$SOURCE_URL" = "''" ]; then
    # Determine if field is missing or just empty
    if grep -q '^source_url:' "$FINDING_FILE"; then
      SKIP_REASON="empty_source_url"
      SKIP_MSG="source_url field exists but is empty or malformed"
    else
      SKIP_REASON="missing_source_url"
      SKIP_MSG="No source_url field found in frontmatter"
    fi
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "$SKIP_REASON" \
      --arg message "$SKIP_MSG" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    log_message "SKIP: $FINDING_ID - $SKIP_MSG"
    continue
  fi

  # Validate URL is not a wikilink
  if [[ "$SOURCE_URL" =~ ^\[\[ ]]; then
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "wikilink_not_url" \
      --arg message "source_url contains wikilink instead of URL: $SOURCE_URL" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Validate URL has proper protocol
  if [[ ! "$SOURCE_URL" =~ ^https?:// ]]; then
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "invalid_url_protocol" \
      --arg message "URL must start with http:// or https://: $SOURCE_URL" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Extract domain from URL using awk (cross-platform compatible)
  # awk splits by "/" to get domain, sed strips port numbers, tr lowercases
  DOMAIN="$(echo "$SOURCE_URL" | awk -F/ '{print $3}' | sed -E 's/:.*$//' | tr '[:upper:]' '[:lower:]')"

  # Validate domain is not empty
  if [ -z "$DOMAIN" ]; then
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "empty_domain" \
      --arg message "Domain extraction returned empty value from URL: $SOURCE_URL" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Validate domain contains TLD separator (at least one ".")
  if [[ ! "$DOMAIN" =~ \. ]]; then
    SKIP_ENTRY="$(jq -n \
      --arg finding_id "$FINDING_ID" \
      --arg skip_reason "invalid_domain_no_tld" \
      --arg message "Domain missing TLD separator: $DOMAIN (from URL: $SOURCE_URL)" \
      '{finding_id: $finding_id, skip_reason: $skip_reason, error: $message}')"
    SKIPPED_SOURCES="$(safe_jq_append "$SKIPPED_SOURCES" "$SKIP_ENTRY" "$FINDING_ID")"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  # Extract title (using Dublin Core dc:title field, handles all quote styles)
  # Strip "Finding: " prefix if present - source dc:title should have NO prefix
  RAW_TITLE="$(extract_yaml_field "dc:title" "$FINDING_FILE")"
  if [[ "$RAW_TITLE" =~ ^Finding:[[:space:]]* ]]; then
    # Strip "Finding: " prefix - source titles have no prefix per entity template
    TITLE="${RAW_TITLE#Finding: }"
  elif [[ -n "$RAW_TITLE" ]]; then
    # Title exists without Finding: prefix - use as-is
    TITLE="$RAW_TITLE"
  else
    # No title found - use domain fallback
    TITLE="$DOMAIN"
  fi

  # Issue #78: Track unique URLs and detect collisions
  # Fix v3.8.0: Check if URL already exists BEFORE generating slug
  # This ensures all findings with same URL get the same source_id
  UNIQUE_URLS_PROCESSED=$((UNIQUE_URLS_PROCESSED + 1))

  # Check if URL already processed (look up by URL, column 2)
  # Uses fixed-string grep with escaped special chars for URL matching
  ESCAPED_URL="$(printf '%s' "$SOURCE_URL" | sed 's/[[\.*^$()+?{|]/\\&/g')"
  EXISTING_ENTRY="$(grep "	${ESCAPED_URL}$" "$COLLISION_TRACKING_FILE" 2>/dev/null | head -1 || true)"

  if [[ -n "$EXISTING_ENTRY" ]]; then
    # URL already processed - reuse existing source_id (don't generate new slug)
    EXISTING_SOURCE_ID="$(echo "$EXISTING_ENTRY" | cut -f1)"
    SOURCE_ID="$EXISTING_SOURCE_ID"
    SEMANTIC_SLUG="$EXISTING_SOURCE_ID"  # Keep for compatibility with downstream code
    sources_reused=$((sources_reused + 1))
    log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] URL already processed - reusing source: $SOURCE_ID"

    # Skip to wikilink generation and backlink update (no entity creation needed)
    # Generate workspace-relative wikilink for source backlink
    SOURCE_WIKILINK=""
    if WIKILINK_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-wikilink.sh" \
      --project-path "$PROJECT_PATH" \
      --entity-dir "05-sources" \
      --filename "$SOURCE_ID" 2>/dev/null)"; then
      SOURCE_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink // ""')"
    fi
    # Fallback: Build workspace-aware wikilink if generation failed
    if [[ -z "$SOURCE_WIKILINK" ]]; then
      WORKSPACE_PREFIX=""
      if [[ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]]; then
        WORKSPACE_PREFIX="${PROJECT_PATH#"$PROJECT_AGENTS_OPS_ROOT"/}"
        if [[ "$WORKSPACE_PREFIX" == "$PROJECT_PATH" ]]; then
          WORKSPACE_PREFIX=""
        fi
      fi
      if [[ -n "$WORKSPACE_PREFIX" ]]; then
        SOURCE_WIKILINK="[[$WORKSPACE_PREFIX/05-sources/$DATA_SUBDIR/$SOURCE_ID]]"
      else
        SOURCE_WIKILINK="[[05-sources/$DATA_SUBDIR/$SOURCE_ID]]"
      fi
    fi

    # Jump directly to backlink update (Sub-Phase 3.6)
    log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Phase 3.6: Backlink Update - Updating $FINDING_FILE (reused source)"
    TMP_FINDING="${FINDING_FILE}.tmp"
    if grep -q '^source_id:' "$FINDING_FILE"; then
      sed "s|^source_id:.*|source_id: \"$SOURCE_WIKILINK\"|" "$FINDING_FILE" > "$TMP_FINDING"
    else
      CLOSING_FRONTMATTER="$(awk '/^---$/{if(NR>1){print NR; exit}}' "$FINDING_FILE")"
      if [ -n "$CLOSING_FRONTMATTER" ] && [ "$CLOSING_FRONTMATTER" -gt 1 ]; then
        awk -v line="$CLOSING_FRONTMATTER" -v sid="$SOURCE_WIKILINK" '
          NR == line { print "source_id: \"" sid "\"" }
          { print }
        ' "$FINDING_FILE" > "$TMP_FINDING"
      else
        log_message "WARNING: No valid closing frontmatter found in $FINDING_FILE"
        backlink_errors=$((backlink_errors + 1))
        continue
      fi
    fi
    if grep -qF "source_id: \"$SOURCE_WIKILINK\"" "$TMP_FINDING"; then
      mv "$TMP_FINDING" "$FINDING_FILE"
      findings_updated=$((findings_updated + 1))
      log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Backlink updated: $FINDING_FILE → $SOURCE_WIKILINK"
    else
      rm -f "$TMP_FINDING"
      log_message "ERROR: Backlink update validation failed for $FINDING_FILE"
      backlink_errors=$((backlink_errors + 1))
    fi
    continue  # Skip to next finding
  fi

  # New URL - generate semantic slug and create source entity
  SLUG_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
    --title "$TITLE" \
    --content-key "$SOURCE_URL" \
    --json)" || {
      log_message "ERROR: Semantic slug generation failed for $SOURCE_URL"
      error_count=$((error_count + 1))
      continue
    }
  SEMANTIC_SLUG="source-$(echo "$SLUG_RESULT" | jq -r '.data.semantic_uuid')"

  # Track this URL with its source_id for future lookups
  printf '%s\t%s\n' "$SEMANTIC_SLUG" "$SOURCE_URL" >> "$COLLISION_TRACKING_FILE"

  # Track URL-to-source mapping for DEBUG_MODE output
  if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
    URL_SOURCE_MAPPING="$(echo "$URL_SOURCE_MAPPING" | jq --arg url "$SOURCE_URL" --arg sid "$SEMANTIC_SLUG" '. + {($url): $sid}')"
  fi

  # Sub-Phase 3.4: Source Wikilink Generation

  log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Phase 3.4: Wikilink Generation - Generating wikilink for $SEMANTIC_SLUG"

  SOURCE_ID="$SEMANTIC_SLUG"

  # Generate workspace-relative wikilink for source backlink (v3.5.0)
  # Fix v3.7.0: Fallback now includes workspace prefix for multi-project setups
  SOURCE_WIKILINK=""
  if WIKILINK_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-wikilink.sh" \
    --project-path "$PROJECT_PATH" \
    --entity-dir "05-sources" \
    --filename "$SOURCE_ID" 2>/dev/null)"; then
    SOURCE_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink // ""')"
  fi
  # Fallback: Build workspace-aware wikilink if generation failed or returned empty
  if [[ -z "$SOURCE_WIKILINK" ]]; then
    log_message "WARNING: Source wikilink generation failed for $SOURCE_ID - using workspace-aware fallback"
    # Detect workspace prefix from PROJECT_PATH
    WORKSPACE_PREFIX=""
    if [[ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]]; then
      WORKSPACE_PREFIX="${PROJECT_PATH#"$PROJECT_AGENTS_OPS_ROOT"/}"
      if [[ "$WORKSPACE_PREFIX" == "$PROJECT_PATH" ]]; then
        WORKSPACE_PREFIX=""
      fi
    fi
    if [[ -n "$WORKSPACE_PREFIX" ]]; then
      SOURCE_WIKILINK="[[$WORKSPACE_PREFIX/05-sources/$DATA_SUBDIR/$SOURCE_ID]]"
    else
      SOURCE_WIKILINK="[[05-sources/$DATA_SUBDIR/$SOURCE_ID]]"
    fi
  fi

  # ============================================================================
  # CHANGE 1: REFACTOR TO USE CREATE-ENTITY.SH
  # ============================================================================
  # Call create-entity.sh for automatic indexing, locking, deduplication, and
  # atomic writes. This replaces inline cat > creation and manual index updates.
  # ============================================================================

  # Extract DOI and PMID from finding frontmatter (empty string if not found)
  DOI="$(grep -i '^doi:' "$FINDING_FILE" | head -1 | cut -d':' -f2- | xargs || echo "")"
  PMID="$(grep -i '^pmid:' "$FINDING_FILE" | head -1 | cut -d':' -f2- | xargs || echo "")"

  # Generate publisher ID using shared utility (fixes Issue #84: ID mismatch with publisher-generator)
  # Uses same algorithm as publisher-generator: org_name extraction + slug + hash
  # v3.9.0: Remove fallback that created non-hash IDs causing orphaned publishers
  if PUBLISHER_ID_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh" \
    --domain "$DOMAIN" --json 2>/dev/null)"; then
    PUBLISHER_ID="$(echo "$PUBLISHER_ID_RESULT" | jq -r '.data.publisher_id // ""')"
    if [ -z "$PUBLISHER_ID" ] || [ "$PUBLISHER_ID" = "null" ]; then
      # v3.9.0: FAIL instead of using non-hash fallback (fixes orphaned publishers)
      # The old fallback format "publisher-example-com" doesn't match publisher-generator's
      # hash-based format "publisher-example-a1b2c3d4", causing link mismatches.
      log_message "ERROR: Publisher ID generation returned empty for domain: $DOMAIN"
      log_message "  Verify generate-publisher-id.sh is accessible at: ${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh"
      # Leave PUBLISHER_ID empty - citation-generator will handle via domain_fallback
      PUBLISHER_ID=""
    fi
  else
    # v3.9.0: FAIL instead of using non-hash fallback (fixes orphaned publishers)
    log_message "ERROR: generate-publisher-id.sh failed for domain: $DOMAIN"
    log_message "  Verify script exists at: ${CLAUDE_PLUGIN_ROOT}/scripts/utils/generate-publisher-id.sh"
    # Leave PUBLISHER_ID empty - citation-generator will handle via domain_fallback
    PUBLISHER_ID=""
  fi

  # NOTE: 08-publishers entity type has been removed (folded into 05-sources).
  # Publisher metadata is now stored inline in the source entity.
  # PUBLISHER_WIKILINK is kept as a plain ID for backward compatibility.
  PUBLISHER_WIKILINK="$PUBLISHER_ID"

  # Sub-Phase 3.5: Source Entity Creation

  log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Phase 3.5: Source Entity Creation - Creating $SOURCE_ID"

  # Build JSON data for create-entity.sh
  # Note: 'title' is required by create-entity.sh, 'name' used for deduplication
  ENTITY_DATA="$(jq -n \
    --arg title "$TITLE" \
    --arg url "$SOURCE_URL" \
    --arg domain "$DOMAIN" \
    --arg access_date "$(date -u +%Y-%m-%d)" \
    --arg doi "$DOI" \
    --arg pmid "$PMID" \
    --arg publisher_id "$PUBLISHER_WIKILINK" \
    --arg dc_creator "source-creator" \
    --arg dc_type "source" \
    '{
      frontmatter: {
        title: $title,
        name: $title,
        url: $url,
        domain: $domain,
        access_date: $access_date,
        publisher_id: $publisher_id,
        reliability_tier: null,
        doi: $doi,
        pmid: $pmid,
        tags: ["source", "source-type/academic"],
        "dc:creator": $dc_creator,
        "dc:title": $title,
        "dc:source": $url,
        "dc:type": $dc_type
      },
      content: ""
    }')"

  # Call create-entity.sh with custom entity ID (semantic slug)
  # Export QUIET_MODE to suppress stderr logging and prevent JSON contamination
  export QUIET_MODE=true
  CREATE_RESULT="$(bash "${SCRIPT_DIR}/create-entity.sh" \
    --project-path "$PROJECT_PATH" \
    --entity-type "05-sources" \
    --entity-id "$SOURCE_ID" \
    --data "$ENTITY_DATA" \
    --json)"

  CREATE_EXIT_CODE=$?

  if [ $CREATE_EXIT_CODE -eq 0 ]; then
    # Parse JSON response to get entity path and reuse status
    SOURCE_FILE="$(echo "$CREATE_RESULT" | jq -r '.entity_path // ""')"
    SOURCE_REUSED="$(echo "$CREATE_RESULT" | jq -r '.reused // false')"

    if [ -z "$SOURCE_FILE" ] || [ "$SOURCE_FILE" = "null" ]; then
      # Fallback to expected path
      SOURCE_FILE="${PROJECT_PATH}/05-sources/${DATA_SUBDIR}/${SOURCE_ID}.md"
    fi

    # Update counters based on reuse status
    if [ "$SOURCE_REUSED" = "true" ]; then
      sources_reused=$((sources_reused + 1))
      log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Source reused via create-entity.sh: $SOURCE_FILE"
    else
      sources_created=$((sources_created + 1))
      log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Source created via create-entity.sh: $SOURCE_FILE"
    fi
  else
    log_message "ERROR: Source creation failed for $SOURCE_ID"
    log_message "$CREATE_RESULT"
    error_count=$((error_count + 1))
    continue
  fi

  # ============================================================================
  # CHANGE 2: IMPLEMENT ATOMIC BACKLINK UPDATES
  # ============================================================================
  # Replace sed -i '' (non-atomic) with atomic temp file + mv pattern.
  # This prevents corruption if process is interrupted during update.
  # ============================================================================

  # Sub-Phase 3.6: Backlink Update

  log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Phase 3.6: Backlink Update - Updating $FINDING_FILE"

  # Atomic backlink update using temp file
  TMP_FINDING="${FINDING_FILE}.tmp"

  if grep -q '^source_id:' "$FINDING_FILE"; then
    # Update existing source_id with wikilink format
    sed "s|^source_id:.*|source_id: \"$SOURCE_WIKILINK\"|" "$FINDING_FILE" > "$TMP_FINDING"
  else
    # Insert source_id after frontmatter opening
    # Find the line number of the closing --- in frontmatter
    CLOSING_FRONTMATTER="$(awk '/^---$/{if(NR>1){print NR; exit}}' "$FINDING_FILE")"

    if [ -n "$CLOSING_FRONTMATTER" ] && [ "$CLOSING_FRONTMATTER" -gt 1 ]; then
      # Insert source_id before the closing --- line with wikilink format
      awk -v line="$CLOSING_FRONTMATTER" -v sid="$SOURCE_WIKILINK" '
        NR == line { print "source_id: \"" sid "\"" }
        { print }
      ' "$FINDING_FILE" > "$TMP_FINDING"
    else
      # No valid frontmatter found - log warning and skip backlink
      log_message "WARNING: No valid closing frontmatter found in $FINDING_FILE (got: '$CLOSING_FRONTMATTER')"
      backlink_errors=$((backlink_errors + 1))
      continue
    fi
  fi

  # Validate temp file before committing (use -F for fixed string matching - wikilinks contain [[)
  if grep -qF "source_id: \"$SOURCE_WIKILINK\"" "$TMP_FINDING"; then
    mv "$TMP_FINDING" "$FINDING_FILE"  # Atomic on same filesystem
    findings_updated=$((findings_updated + 1))
    log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] Backlink updated: $FINDING_FILE → $SOURCE_WIKILINK"
  else
    rm -f "$TMP_FINDING"
    log_message "ERROR: Backlink update validation failed for $FINDING_FILE"
    backlink_errors=$((backlink_errors + 1))
  fi

done

# ============================================================================
# Phase 4: Statistics & Validation
# ============================================================================

TOTAL_PROCESSED=$((sources_created + sources_reused))
TOTAL_SKIPPED=$skipped_count

# Completeness validation: processed + skipped = partition findings (not total)
if [ $((TOTAL_PROCESSED + TOTAL_SKIPPED)) -ne $PARTITION_FINDINGS_COUNT ]; then
  MISSING_COUNT=$((PARTITION_FINDINGS_COUNT - TOTAL_PROCESSED - TOTAL_SKIPPED))
  ERROR_JSON="$(jq -n \
    --argjson partition_findings $PARTITION_FINDINGS_COUNT \
    --argjson sources_created $sources_created \
    --argjson sources_reused $sources_reused \
    --argjson skipped $TOTAL_SKIPPED \
    --argjson missing $MISSING_COUNT \
    --arg error "Completeness validation failed" \
    '{
      success: false,
      error: $error,
      partition_findings: $partition_findings,
      sources_created: $sources_created,
      sources_reused: $sources_reused,
      skipped: $skipped,
      missing: $missing,
      validation_passed: false
    }')"

  echo "$ERROR_JSON" > "${PROJECT_PATH}/.logs/source-creator-statistics.json"
  echo "$ERROR_JSON"
  exit 1
fi

# ============================================================================
# CHANGE 3: ADD CROSS-VALIDATION STATISTICS
# ============================================================================
# Cross-validate counters against filesystem and entity index to detect
# discrepancies. This prevents false positives like "0 created" vs "45 files".
# ============================================================================

# Cross-validate counters against reality
ACTUAL_SOURCES="$(find "${PROJECT_PATH}/05-sources/${DATA_SUBDIR}" -name "*.md" -type f 2>/dev/null | wc -l | xargs)"
INDEXED_SOURCES="$(jq '.entities["05-sources"] | length // 0' "$PROJECT_PATH/.metadata/entity-index.json" 2>/dev/null || echo 0)"

# Check for discrepancies
VALIDATION_PASSED=true
DISCREPANCY_DETAILS=""

if [ "$ACTUAL_SOURCES" -ne "$INDEXED_SOURCES" ]; then
  VALIDATION_PASSED=false
  DISCREPANCY_DETAILS="Filesystem has $ACTUAL_SOURCES sources but index has $INDEXED_SOURCES"
  log_message "[$(date +%Y-%m-%d\ %H:%M:%S)] WARNING: Entity index discrepancy: $DISCREPANCY_DETAILS"
fi

if [ $error_count -gt 0 ] || [ $backlink_errors -gt 0 ]; then
  VALIDATION_PASSED=false
fi

# Issue #78: Collision threshold validation (fail if >10% collisions)
COLLISION_PERCENTAGE=0
if [ $UNIQUE_URLS_PROCESSED -gt 0 ]; then
  COLLISION_PERCENTAGE=$((COLLISION_COUNT * 100 / UNIQUE_URLS_PROCESSED))
  if [ $COLLISION_PERCENTAGE -gt 10 ]; then
    VALIDATION_PASSED=false
    log_message "[ERROR] Collision rate exceeds threshold: ${COLLISION_PERCENTAGE}% (>${COLLISION_COUNT}/${UNIQUE_URLS_PROCESSED} URLs)"
    log_message "  This indicates potential data loss - review generate-semantic-slug.sh hashing"
  elif [ $COLLISION_COUNT -gt 0 ]; then
    log_message "[WARNING] Collisions detected: ${COLLISION_COUNT}/${UNIQUE_URLS_PROCESSED} URLs (${COLLISION_PERCENTAGE}%)"
  fi
fi

# Generate skip summary
SKIP_SUMMARY="$(echo "$SKIPPED_SOURCES" | jq 'group_by(.skip_reason) | map({(.[0].skip_reason): length}) | add // {}')"

# ============================================================================
# Phase 5: JSON Response
# ============================================================================

# Generate comprehensive report with cross-validation statistics
# Issue #78: Include collision detection metrics
REPORT="$(jq -n \
  --argjson sources_created $sources_created \
  --argjson sources_reused $sources_reused \
  --argjson findings_updated $findings_updated \
  --argjson actual_sources $ACTUAL_SOURCES \
  --argjson indexed_sources $INDEXED_SOURCES \
  --argjson error_count $error_count \
  --argjson backlink_errors $backlink_errors \
  --argjson validation_passed $([ "$VALIDATION_PASSED" = true ] && echo true || echo false) \
  --argjson partition_findings $PARTITION_FINDINGS_COUNT \
  --argjson skipped $TOTAL_SKIPPED \
  --argjson skipped_sources "$SKIPPED_SOURCES" \
  --argjson skip_summary "$SKIP_SUMMARY" \
  --arg discrepancy "$DISCREPANCY_DETAILS" \
  --argjson unique_urls $UNIQUE_URLS_PROCESSED \
  --argjson collision_count $COLLISION_COUNT \
  --argjson collision_pct $COLLISION_PERCENTAGE \
  --argjson collision_warnings "$COLLISION_WARNINGS" \
  '{
    success: true,
    sources_created: $sources_created,
    sources_reused: $sources_reused,
    findings_updated: $findings_updated,
    unique_urls_processed: $unique_urls,
    collision_detection: {
      collision_count: $collision_count,
      collision_percentage: $collision_pct,
      collision_warnings: $collision_warnings
    },
    statistics: {
      filesystem_sources: $actual_sources,
      indexed_sources: $indexed_sources,
      error_count: $error_count,
      backlink_errors: $backlink_errors
    },
    validation_passed: $validation_passed,
    discrepancy: $discrepancy,
    partition_findings: $partition_findings,
    skipped: $skipped,
    skipped_sources: $skipped_sources,
    skip_reasons_summary: $skip_summary
  }')"

# Issue #78: Add URL-to-source mapping in DEBUG_MODE
if [[ "${DEBUG_MODE:-false}" == "true" ]] && ! [[ "$URL_SOURCE_MAPPING" == "{}" ]]; then
  REPORT="$(echo "$REPORT" | jq --argjson mapping "$URL_SOURCE_MAPPING" '. + {url_source_mapping: $mapping}')"
fi

# Write completion log
if ! [[ "$LOG_FILE" == "/dev/null" ]]; then
  echo "========================================" >> "$LOG_FILE"
  echo "Source Creator Execution Complete" >> "$LOG_FILE"
  echo "Completed: $(date +%Y-%m-%d\ %H:%M:%S)" >> "$LOG_FILE"
  echo "Sources Created: $sources_created" >> "$LOG_FILE"
  echo "Sources Reused: $sources_reused" >> "$LOG_FILE"
  echo "Findings Updated: $findings_updated" >> "$LOG_FILE"
  echo "Validation Passed: $VALIDATION_PASSED" >> "$LOG_FILE"
  echo "========================================" >> "$LOG_FILE"
fi

echo "$REPORT" > "${PROJECT_PATH}/.logs/source-creator-statistics.json"
echo "$REPORT"
exit 0
