#!/usr/bin/env bash
set -euo pipefail
# cleanup-orphaned-batches.sh
# Version: 1.0.1
# Purpose: Remove orphaned query batch files created via Write tool fallback or with naming typos
#
# Cleans up query batch files that violate the create-entity.sh requirement:
# - Files with 'query-batche-' typo prefix (Write tool fallback artifact)
# - Files not indexed in entity-index.json (orphaned entities)
# - Test files (test-*.md)
#
# Usage:
#   cleanup-orphaned-batches.sh --project-path /path/to/project [--dry-run]
#
# Arguments:
#   --project-path <path>  Path to the deeper-research project (required)
#   --dry-run              Show what would be deleted without actually deleting
#   --json                 Output results as JSON
#
# Exit codes:
#   0 - Success (cleanup completed or dry-run finished)
#   1 - Missing required arguments
#   2 - Project path does not exist


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
PROJECT_PATH=""
DRY_RUN=false
JSON_OUTPUT=false

# Counters
TYPO_COUNT=0
ORPHAN_COUNT=0
TEST_COUNT=0

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    -h|--help)
      echo "Usage: cleanup-orphaned-batches.sh --project-path /path/to/project [--dry-run] [--json]"
      echo ""
      echo "Options:"
      echo "  --project-path  Path to the deeper-research project (required)"
      echo "  --dry-run       Show what would be deleted without actually deleting"
      echo "  --json          Output results as JSON"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ------------------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------------------
if [[ -z "$PROJECT_PATH" ]]; then
  echo "ERROR: --project-path is required" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "ERROR: Project path does not exist: $PROJECT_PATH" >&2
  exit 2
fi

BATCHES_DIR="${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}"
ENTITY_INDEX="${PROJECT_PATH}/.metadata/entity-index.json"

if [[ ! -d "$BATCHES_DIR" ]]; then
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo '{"success": true, "message": "No query-batches directory found", "deleted": {"typo": 0, "orphan": 0, "test": 0}}'
  else
    echo "No ${DIR_QUERY_BATCHES} directory found. Nothing to clean up."
  fi
  exit 0
fi

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
log_info() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo "$1"
  fi
}

delete_file() {
  local file="$1"
  local category="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "  [DRY-RUN] Would delete: $file"
  else
    rm "$file"
    log_info "  DELETED: $file"
  fi

  case "$category" in
    typo) ((TYPO_COUNT++)) ;;
    orphan) ((ORPHAN_COUNT++)) ;;
    test) ((TEST_COUNT++)) ;;
  esac
}

# ------------------------------------------------------------------------------
# Main cleanup logic
# ------------------------------------------------------------------------------
log_info "Scanning for orphaned/malformed batch files in: $BATCHES_DIR"
log_info "Mode: $(if [[ "$DRY_RUN" == "true" ]]; then echo "DRY-RUN"; else echo "LIVE"; fi)"
log_info ""

# 1. Find files with 'query-batche-' typo prefix
log_info "=== Files with 'query-batche-' typo prefix ==="
while IFS= read -r -d '' file; do
  delete_file "$file" "typo"
done < <(find "$BATCHES_DIR" -name "query-batche-*.md" -type f -print0 2>/dev/null)

if [[ $TYPO_COUNT -eq 0 ]]; then
  log_info "  (none found)"
fi
log_info ""

# 2. Find files not in entity-index.json (orphaned)
log_info "=== Files not in entity-index.json (orphaned) ==="
if [[ -f "$ENTITY_INDEX" ]]; then
  while IFS= read -r -d '' file; do
    batch_id="$(basename "$file" .md)"

    # Check if batch_id exists in entity-index.json
    if ! jq -e --arg id "$batch_id" \
      '.["03-query-batches"] // [] | map(.id) | index($id)' \
      "$ENTITY_INDEX" >/dev/null 2>&1; then
      delete_file "$file" "orphan"
    fi
  done < <(find "$BATCHES_DIR" -name "question-*-batch.md" -type f -print0 2>/dev/null)

  if [[ $ORPHAN_COUNT -eq 0 ]]; then
    log_info "  (none found)"
  fi
else
  log_info "  (skipped - entity-index.json not found)"
fi
log_info ""

# 3. Find test files
log_info "=== Test files ==="
while IFS= read -r -d '' file; do
  delete_file "$file" "test"
done < <(find "$BATCHES_DIR" -name "test-*.md" -type f -print0 2>/dev/null)

if [[ $TEST_COUNT -eq 0 ]]; then
  log_info "  (none found)"
fi
log_info ""

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
TOTAL=$((TYPO_COUNT + ORPHAN_COUNT + TEST_COUNT))

if [[ "$JSON_OUTPUT" == "true" ]]; then
  cat <<EOF
{
  "success": true,
  "dry_run": $DRY_RUN,
  "project_path": "$PROJECT_PATH",
  "deleted": {
    "typo_prefix": $TYPO_COUNT,
    "orphaned": $ORPHAN_COUNT,
    "test_files": $TEST_COUNT,
    "total": $TOTAL
  }
}
EOF
else
  log_info "=== Summary ==="
  log_info "  Typo prefix files:  $TYPO_COUNT"
  log_info "  Orphaned files:     $ORPHAN_COUNT"
  log_info "  Test files:         $TEST_COUNT"
  log_info "  ─────────────────────"
  log_info "  Total:              $TOTAL"
  log_info ""
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Run without --dry-run to delete these files."
  else
    log_info "Cleanup complete."
  fi
fi

exit 0
