#!/usr/bin/env bash
set -euo pipefail
# reconcile-question-batches.sh
# Version: 1.4.0
# Purpose: Identify refined questions missing query batches with content validation
#          Standard naming: {question_id}-batch.md (deprecated: batch-{slug}.md)
# Category: validation
#
# Compares refined questions against query batches to identify gaps.
# Validates batch content (search_configs, question_ref) not just file existence.
#
# Usage: reconcile-question-batches.sh --project-path <path> [--batch-questions <paths>]
#
# Arguments:
#   --project-path <path>           Path to research project directory (required)
#   --batch-questions <paths>       Comma-separated question paths to check (optional)
#                                   If omitted, checks all questions in project
#
# Output: Compact JSON summary (single line)
#   {
#     "success": true|false,
#     "total_questions": 45,
#     "total_batches": 45,
#     "coverage_percent": 100.0,
#     "missing_questions": [],
#     "malformed_batches": [],
#     "orphaned_batches": [],
#     "recommendation": "CONTINUE"|"RETRY_MISSING"|"HALT_WORKFLOW"
#   }
#
# Exit codes:
#   0 - All questions have valid batches
#   1 - Missing or malformed batches detected
#   2 - Invalid parameters


# ============================================================================
# ENTITY CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source entity configuration for directory key resolution (required)
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DATA_SUBDIR="$(get_data_subdir)"

# ============================================================================
# PARAMETER PARSING
# ============================================================================

PROJECT_PATH=""
BATCH_QUESTIONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --batch-questions)
      BATCH_QUESTIONS="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: reconcile-question-batches.sh --project-path <path> [--batch-questions <paths>]"
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

# Validate batch file content (not just existence)
# Returns: "valid", "missing", "too_small", "empty_search_configs", "broken_question_ref"
validate_batch_content() {
  local batch_file="$1"
  local question_id="$2"

  # Check file exists
  if [[ ! -f "$batch_file" ]]; then
    echo "missing"
    return
  fi

  # Check file size (minimum 500 bytes for valid batch)
  local size
  if [[ "$(uname)" == "Darwin" ]]; then
    size="$(stat -f%z "$batch_file" 2>/dev/null || echo "0")"
  else
    size="$(stat -c%s "$batch_file" 2>/dev/null || echo "0")"
  fi

  if [[ "$size" -lt 500 ]]; then
    echo "too_small"
    return
  fi

  # Accept reconstructed batches (created by repair hook) as valid
  # Check this BEFORE search_configs since reconstructed batches may not have them
  if grep -q '^reconstructed: true' "$batch_file" 2>/dev/null; then
    echo "valid"
    return
  fi

  # Check for search_configs in frontmatter
  # Look for search_configs: followed by array entries
  if ! grep -q 'search_configs:' "$batch_file" 2>/dev/null; then
    echo "empty_search_configs"
    return
  fi

  # Check search_configs has at least one config_id entry
  # Support both YAML format (config_id:) and JSON format ("config_id":)
  if ! grep -qE '(config_id:|"config_id":)' "$batch_file" 2>/dev/null; then
    echo "empty_search_configs"
    return
  fi

  # Check question_ref wikilink exists and resolves
  # Support both formats:
  #   Format 1 (full path): [[02-refined-questions/data/question-slug-uuid]]
  #   Format 2 (short): [[question-slug-uuid]]
  local question_ref ref_question_id

  # Try full path format first: [[DIR/data/question-...]]
  question_ref="$(grep -o "question_ref:.*\[\[${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}/question-[^]]*\]\]" "$batch_file" 2>/dev/null | head -1 || echo "")"
  if [[ -n "$question_ref" ]]; then
    # Extract just the question ID (without path prefix)
    ref_question_id="$(echo "$question_ref" | sed 's/.*\[\[.*\/\(question-[^]]*\)\]\].*/\1/')"
  else
    # Try short format (just question ID in wikilink)
    question_ref="$(grep -o 'question_ref:.*\[\[question-[^]]*\]\]' "$batch_file" 2>/dev/null | head -1 || echo "")"
    if [[ -n "$question_ref" ]]; then
      ref_question_id="$(echo "$question_ref" | sed 's/.*\[\[\(question-[^]]*\)\]\].*/\1/')"
    fi
  fi

  if [[ -z "$question_ref" ]]; then
    echo "broken_question_ref"
    return
  fi

  # Verify referenced question file exists
  if [[ ! -f "${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}/${ref_question_id}.md" ]]; then
    echo "broken_question_ref"
    return
  fi

  echo "valid"
}

# Resolve batch file path using standard naming convention
# Standard: {question_id}-batch.md
# Deprecated: batch-{slug}.md (emits warning)
# Arguments: project_path, question_id
# Returns: path to batch file (standard or deprecated location)
resolve_batch_file() {
  local project_path="$1"
  local question_id="$2"

  # Standard convention: {question_id}-batch.md
  local batch_file="${project_path}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/${question_id}-batch.md"

  # DEPRECATED: Check for old batch-{slug}.md convention and warn
  local slug="${question_id#question-}"
  local deprecated_file="${project_path}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/batch-${slug}.md"

  if [[ -f "$deprecated_file" ]] && [[ ! -f "$batch_file" ]]; then
    echo "WARNING: Found batch using deprecated naming: batch-${slug}.md" >&2
    echo "         Migrate to standard: ${question_id}-batch.md" >&2
    echo "         Run: bash scripts/migrate-batch-naming.sh --project-path \"$project_path\"" >&2
    echo "$deprecated_file"
  else
    echo "$batch_file"
  fi
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

missing_questions=()
malformed_batches=()
orphaned_batches=()
total_questions=0
total_batches=0

# Determine which questions to check
if [[ -n "$BATCH_QUESTIONS" ]]; then
  # Check only specified questions (per-batch validation mode)
  IFS=',' read -ra QUESTION_PATHS <<< "$BATCH_QUESTIONS"
  for question_path in "${QUESTION_PATHS[@]}"; do
    # Clean up path (trim whitespace)
    question_path="$(echo "$question_path" | xargs)"

    if [[ -f "$question_path" ]]; then
      question_id="$(basename "$question_path" .md)"
      batch_file="$(resolve_batch_file "$PROJECT_PATH" "$question_id")"
      batch_id="$(basename "$batch_file" .md)"

      ((total_questions++)) || true

      validation_result="$(validate_batch_content "$batch_file" "$question_id")"

      case "$validation_result" in
        "valid")
          ((total_batches++)) || true
          ;;
        "missing")
          missing_questions+=("$question_id")
          ;;
        *)
          malformed_batches+=("{\"batch_id\":\"${batch_id}\",\"issue\":\"${validation_result}\"}")
          ((total_batches++)) || true  # File exists but malformed
          ;;
      esac
    fi
  done
else
  # Check all questions in project (full validation mode)
  if [[ -d "${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}" ]]; then
    for question_file in "${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}"/question-*.md; do
      [[ -f "$question_file" ]] || continue

      question_id="$(basename "$question_file" .md)"
      batch_file="$(resolve_batch_file "$PROJECT_PATH" "$question_id")"
      batch_id="$(basename "$batch_file" .md)"

      ((total_questions++)) || true

      validation_result="$(validate_batch_content "$batch_file" "$question_id")"

      case "$validation_result" in
        "valid")
          ((total_batches++)) || true
          ;;
        "missing")
          missing_questions+=("$question_id")
          ;;
        *)
          malformed_batches+=("{\"batch_id\":\"${batch_id}\",\"issue\":\"${validation_result}\"}")
          ((total_batches++)) || true  # File exists but malformed
          ;;
      esac
    done
  fi

  # Check for orphaned batches (batches without corresponding questions)
  # Supports both naming conventions: question-{slug}-batch.md and batch-{slug}.md
  if [[ -d "${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}" ]]; then
    for batch_file in "${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}"/*.md; do
      [[ -f "$batch_file" ]] || continue

      batch_id="$(basename "$batch_file" .md)"

      # Derive question_id based on batch naming convention
      if [[ "$batch_id" == question-*-batch ]]; then
        # Convention 1: question-{slug}-batch.md -> question-{slug}
        question_id="${batch_id%-batch}"
      elif [[ "$batch_id" == batch-* ]]; then
        # Convention 2: batch-{slug}.md -> question-{slug}
        question_id="question-${batch_id#batch-}"
      else
        # Not a question-based batch (e.g., README)
        continue
      fi

      question_file="${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}/${question_id}.md"

      if [[ ! -f "$question_file" ]]; then
        orphaned_batches+=("$batch_id")
      fi
    done
  fi
fi

# ============================================================================
# CALCULATE METRICS
# ============================================================================

# Calculate coverage percentage
coverage_percent=0
if [[ $total_questions -gt 0 ]]; then
  coverage_percent="$(echo "scale=1; ($total_batches / $total_questions) * 100" | bc)"
fi

# Determine recommendation
recommendation="CONTINUE"
if [[ ${#missing_questions[@]} -gt 0 ]]; then
  recommendation="RETRY_MISSING"
fi
if [[ ${#malformed_batches[@]} -gt 0 ]]; then
  recommendation="RETRY_MISSING"
fi

# ============================================================================
# OUTPUT JSON
# ============================================================================

# Build JSON arrays
missing_json="[]"
if [[ ${#missing_questions[@]} -gt 0 ]]; then
  missing_json="$(printf '%s\n' "${missing_questions[@]}" | jq -R . | jq -sc .)"
fi

malformed_json="[]"
if [[ ${#malformed_batches[@]} -gt 0 ]]; then
  malformed_json="$(printf '%s\n' "${malformed_batches[@]}" | jq -c . | jq -sc .)"
fi

orphaned_json="[]"
if [[ ${#orphaned_batches[@]} -gt 0 ]]; then
  orphaned_json="$(printf '%s\n' "${orphaned_batches[@]}" | jq -R . | jq -sc .)"
fi

# Determine success
success=true
if [[ ${#missing_questions[@]} -gt 0 ]] || [[ ${#malformed_batches[@]} -gt 0 ]]; then
  success=false
fi

# Output compact JSON
cat <<EOF
{"success":${success},"total_questions":${total_questions},"total_batches":${total_batches},"coverage_percent":${coverage_percent},"missing_questions":${missing_json},"malformed_batches":${malformed_json},"orphaned_batches":${orphaned_json},"recommendation":"${recommendation}"}
EOF

if [[ "$success" == "true" ]]; then
  exit 0
else
  exit 1
fi
