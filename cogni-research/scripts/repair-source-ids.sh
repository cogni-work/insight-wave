#!/usr/bin/env bash
set -euo pipefail
# repair-source-ids.sh
# Purpose: Repair broken source_id wikilinks in findings AND claims by matching hash to actual source files
# Version: 1.1.0
# Category: utilities
#
# Usage: repair-source-ids.sh --project-path <path> [--dry-run] [--json]
#
# Arguments:
#   --project-path <path>  Research project directory (required)
#   --dry-run              Show what would be fixed without making changes (optional)
#   --json                 Output JSON format (optional)
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Description:
#   Scans all findings in 04-findings/data/ and claims in 10-claims/data/ and checks
#   if their source wikilinks point to existing source files. If a source reference has
#   a matching hash but different slug (indicating the same URL was processed with a
#   different title), the script updates the wikilink to point to the actual source file.
#
# Changelog:
#   - v1.1.0: Add claim repair functionality (scans 10-claims/data/)
#   - v1.0.0: Initial version (findings only)
#
# Example:
#   repair-source-ids.sh --project-path /path/to/project --dry-run
#   repair-source-ids.sh --project-path /path/to/project --json


# ============================================================================
# Argument Parsing
# ============================================================================

PROJECT_PATH=""
DRY_RUN=false
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
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

if [ ! -d "$PROJECT_PATH" ]; then
  echo "{\"success\": false, \"error\": \"Project path does not exist: $PROJECT_PATH\"}" >&2
  exit 1
fi

# ============================================================================
# Directory Setup
# ============================================================================

FINDINGS_DIR="${PROJECT_PATH}/04-findings/data"
CLAIMS_DIR="${PROJECT_PATH}/10-claims/data"
SOURCES_DIR="${PROJECT_PATH}/07-sources/data"

if [ ! -d "$SOURCES_DIR" ]; then
  echo "{\"success\": false, \"error\": \"Sources directory not found: $SOURCES_DIR\"}" >&2
  exit 1
fi

# ============================================================================
# Build Source Hash Index
# ============================================================================

# Build an index of source files by their hash (last 8 chars of filename before .md)
declare -a SOURCE_HASHES
declare -a SOURCE_FILES
declare -a SOURCE_IDS

while IFS= read -r source_file; do
  filename="$(basename "$source_file" .md)"
  # Extract hash (last 8 chars after final hyphen)
  hash="${filename##*-}"
  if [[ ${#hash} -eq 8 ]] && [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
    SOURCE_HASHES+=("$hash")
    SOURCE_FILES+=("$source_file")
    SOURCE_IDS+=("$filename")
  fi
done < <(find "$SOURCES_DIR" -name "source-*.md" -type f 2>/dev/null)

# Function to find source file by hash
find_source_by_hash() {
  local target_hash="$1"
  local i=0
  for hash in "${SOURCE_HASHES[@]}"; do
    if [[ "$hash" == "$target_hash" ]]; then
      echo "${SOURCE_IDS[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

# ============================================================================
# Repair Function (used for both findings and claims)
# ============================================================================

repair_source_links() {
  local entity_dir="$1"
  local entity_type="$2"  # "finding" or "claim"
  local scanned=0
  local correct=0
  local broken=0
  local fixed=0
  local no_refs=0
  local errs=0

  if [ ! -d "$entity_dir" ]; then
    echo "0 0 0 0 0 0"
    return
  fi

  while IFS= read -r entity_file; do
    scanned=$((scanned + 1))

    if [ "$entity_type" = "finding" ]; then
      # For findings, check source_id field
      source_id_line="$(grep '^source_id:' "$entity_file" 2>/dev/null || true)"
      if [ -z "$source_id_line" ]; then
        no_refs=$((no_refs + 1))
        continue
      fi

      # Extract the wikilink from source_id field
      source_wikilink="$(echo "$source_id_line" | sed 's/^source_id:[[:space:]]*//' | tr -d '"')"
      if [ -z "$source_wikilink" ] || [ "$source_wikilink" = '""' ]; then
        no_refs=$((no_refs + 1))
        continue
      fi

      # Extract the source ID from wikilink
      source_id="$(echo "$source_wikilink" | sed 's/^\[\[//' | sed 's/\]\]$//' | sed 's/|.*//' | xargs basename)"
      source_hash="${source_id##*-}"

      # Validate hash format
      if [[ ${#source_hash} -ne 8 ]] || [[ ! "$source_hash" =~ ^[a-f0-9]+$ ]]; then
        continue
      fi

      # Check if source exists
      if [ -f "${SOURCES_DIR}/${source_id}.md" ]; then
        correct=$((correct + 1))
        continue
      fi

      broken=$((broken + 1))
      actual_source_id="$(find_source_by_hash "$source_hash" || true)"
      if [ -z "$actual_source_id" ]; then
        errs=$((errs + 1))
        continue
      fi

      correct_wikilink="[[07-sources/data/${actual_source_id}]]"

      if [ "$DRY_RUN" = true ]; then
        [ "$JSON_OUTPUT" = false ] && echo "WOULD FIX ($entity_type): $(basename "$entity_file") - $source_id -> $actual_source_id"
      else
        TMP_FILE="${entity_file}.tmp"
        sed "s|^source_id:.*|source_id: \"$correct_wikilink\"|" "$entity_file" > "$TMP_FILE"
        if grep -qF "source_id: \"$correct_wikilink\"" "$TMP_FILE"; then
          mv "$TMP_FILE" "$entity_file"
          fixed=$((fixed + 1))
          [ "$JSON_OUTPUT" = false ] && echo "FIXED ($entity_type): $(basename "$entity_file") -> $actual_source_id"
        else
          rm -f "$TMP_FILE"
          errs=$((errs + 1))
        fi
      fi

    else
      # For claims, scan entire file for broken source wikilinks
      local file_modified=false
      local claim_broken=0
      local claim_fixed=0

      # Find all source references in the file
      while IFS= read -r source_ref; do
        # Extract source ID from wikilink (handle [[path|display]] format)
        source_id="$(echo "$source_ref" | sed 's/^\[\[//' | sed 's/\]\]$//' | sed 's/|.*//' | xargs basename)"
        source_hash="${source_id##*-}"

        # Validate hash format
        if [[ ${#source_hash} -ne 8 ]] || [[ ! "$source_hash" =~ ^[a-f0-9]+$ ]]; then
          continue
        fi

        # Check if source exists
        if [ -f "${SOURCES_DIR}/${source_id}.md" ]; then
          continue
        fi

        # Broken - find actual source
        actual_source_id="$(find_source_by_hash "$source_hash" || true)"
        if [ -z "$actual_source_id" ]; then
          errs=$((errs + 1))
          continue
        fi

        claim_broken=$((claim_broken + 1))

        if [ "$DRY_RUN" = true ]; then
          [ "$JSON_OUTPUT" = false ] && echo "WOULD FIX ($entity_type): $(basename "$entity_file") - $source_id -> $actual_source_id"
        else
          # Replace all occurrences of broken source ID with correct one
          sed -i '' "s|${source_id}|${actual_source_id}|g" "$entity_file"
          file_modified=true
          claim_fixed=$((claim_fixed + 1))
          [ "$JSON_OUTPUT" = false ] && echo "FIXED ($entity_type): $(basename "$entity_file") - $source_id -> $actual_source_id"
        fi
      done < <(grep -oE '\[\[07-sources/data/source-[a-zA-Z0-9-]+\]\]|\[\[07-sources/data/source-[a-zA-Z0-9-]+\|[^\]]+\]\]' "$entity_file" 2>/dev/null | sort -u)

      if [ $claim_broken -gt 0 ]; then
        broken=$((broken + claim_broken))
        if [ "$file_modified" = true ]; then
          fixed=$((fixed + claim_fixed))
        fi
      else
        correct=$((correct + 1))
      fi
    fi

  done < <(find "$entity_dir" -name "*.md" -type f 2>/dev/null)

  echo "$scanned $correct $broken $fixed $no_refs $errs"
}

# ============================================================================
# Run Repairs
# ============================================================================

if [ "$JSON_OUTPUT" = false ]; then
  echo "=== Repairing Findings ==="
fi
read findings_scanned findings_correct findings_broken findings_fixed findings_no_ref findings_errors < <(repair_source_links "$FINDINGS_DIR" "finding")

if [ "$JSON_OUTPUT" = false ]; then
  echo ""
  echo "=== Repairing Claims ==="
fi
read claims_scanned claims_correct claims_broken claims_fixed claims_no_ref claims_errors < <(repair_source_links "$CLAIMS_DIR" "claim")

# ============================================================================
# Output Results
# ============================================================================

total_scanned=$((findings_scanned + claims_scanned))
total_correct=$((findings_correct + claims_correct))
total_broken=$((findings_broken + claims_broken))
total_fixed=$((findings_fixed + claims_fixed))
total_errors=$((findings_errors + claims_errors))

if [ "$JSON_OUTPUT" = true ]; then
  jq -n \
    --argjson dry_run "$DRY_RUN" \
    --argjson findings_scanned "$findings_scanned" \
    --argjson findings_correct "$findings_correct" \
    --argjson findings_broken "$findings_broken" \
    --argjson findings_fixed "$findings_fixed" \
    --argjson findings_no_ref "$findings_no_ref" \
    --argjson findings_errors "$findings_errors" \
    --argjson claims_scanned "$claims_scanned" \
    --argjson claims_correct "$claims_correct" \
    --argjson claims_broken "$claims_broken" \
    --argjson claims_fixed "$claims_fixed" \
    --argjson claims_errors "$claims_errors" \
    --argjson total_scanned "$total_scanned" \
    --argjson total_broken "$total_broken" \
    --argjson total_fixed "$total_fixed" \
    --argjson total_errors "$total_errors" \
    '{
      success: true,
      dry_run: $dry_run,
      findings: {
        scanned: $findings_scanned,
        correct: $findings_correct,
        broken: $findings_broken,
        fixed: $findings_fixed,
        no_source_id: $findings_no_ref,
        errors: $findings_errors
      },
      claims: {
        scanned: $claims_scanned,
        correct: $claims_correct,
        broken: $claims_broken,
        fixed: $claims_fixed,
        errors: $claims_errors
      },
      totals: {
        scanned: $total_scanned,
        broken: $total_broken,
        fixed: $total_fixed,
        errors: $total_errors
      }
    }'
else
  echo ""
  echo "=== Source ID Repair Summary ==="
  if [ "$DRY_RUN" = true ]; then
    echo "Mode: DRY RUN (no changes made)"
  else
    echo "Mode: REPAIR"
  fi
  echo ""
  echo "Findings:"
  echo "  Scanned:    $findings_scanned"
  echo "  Correct:    $findings_correct"
  echo "  Broken:     $findings_broken"
  echo "  Fixed:      $findings_fixed"
  echo "  No ref:     $findings_no_ref"
  echo "  Errors:     $findings_errors"
  echo ""
  echo "Claims:"
  echo "  Scanned:    $claims_scanned"
  echo "  Correct:    $claims_correct"
  echo "  Broken:     $claims_broken"
  echo "  Fixed:      $claims_fixed"
  echo "  Errors:     $claims_errors"
  echo ""
  echo "Totals:"
  echo "  Scanned:    $total_scanned"
  echo "  Broken:     $total_broken"
  echo "  Fixed:      $total_fixed"
  echo "  Errors:     $total_errors"
fi
