#!/usr/bin/env bash
set -euo pipefail
# validate-phase3-completion.sh
# Version: 2.0.1
# Purpose: Single-call validation for Phase 3 (Parallel Findings Creation) completion
# Category: validation
#
# Replaces multiple inline bash validation commands with a single script call.
# Reduces orchestrator context consumption by ~500 characters per validation.
#
# v2.0.0: Added missing_questions array, malformed_batches, coverage_percent
#
# Usage: validate-phase3-completion.sh --project-path <path> [--batch-only]
#
# Arguments:
#   --project-path <path>    Path to research project directory (required)
#   --batch-only             Skip findings/megatrend validation (for Phase 2.5 batch completion)
#
# Output: Compact JSON summary (single line)
#   {
#     "success": true|false,
#     "batches": 15,
#     "questions": 15,
#     "missing_questions": [],
#     "malformed_batches": [],
#     "coverage_percent": 100.0,
#     "agent_logs": 15,
#     "llm_findings": 12,
#     "web_findings": 118,
#     "total_findings": 130,
#     "megatrends": 45,
#     "errors": []
#   }
#
# Error codes:
#   - no_batches:agents_bypassed - CRITICAL: Agents were bypassed
#   - batch_mismatch:XvsY - Batch count doesn't match question count
#   - no_findings - CRITICAL: No findings created
#   - no_web_findings - CRITICAL: Web findings missing
#   - low_findings:N - WARNING: Below 100 threshold
#   - agent_gap:XofY - WARNING: Execution logs missing (X logs for Y questions)
#   - missing_batches:N - CRITICAL: N questions have no batch file
#   - malformed_batches:N - WARNING: N batches have content issues
#
# Exit codes:
#   0 - Validation passed (all checks green)
#   1 - Validation failed (critical errors)
#   2 - Invalid parameters


# Script directory for sourcing libs
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity configuration
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_MEGATRENDS="$(get_directory_by_key "megatrends")"

# ============================================================================
# PARAMETER PARSING
# ============================================================================

PROJECT_PATH=""
BATCH_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --batch-only)
      BATCH_ONLY=true
      shift
      ;;
    --help|-h)
      echo "Usage: validate-phase3-completion.sh --project-path <path> [--batch-only]"
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

  # Check for search_configs with at least one config_id entry
  if ! grep -q 'config_id:' "$batch_file" 2>/dev/null; then
    echo "empty_search_configs"
    return
  fi

  # Check question_ref wikilink exists (with data/ subdirectory)
  if ! grep -q "question_ref:.*\[\[${DIR_REFINED_QUESTIONS}/data/" "$batch_file" 2>/dev/null; then
    echo "broken_question_ref"
    return
  fi

  echo "valid"
}

# ============================================================================
# VALIDATION LOGIC
# ============================================================================

errors=()
missing_questions=()
malformed_batches=()

# Count refined questions and identify missing batches
question_count=0
valid_batch_count=0
if [[ -d "${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}" ]]; then
  for question_file in "${PROJECT_PATH}/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}"/question-*.md; do
    [[ -f "$question_file" ]] || continue
    ((question_count++))

    question_id="$(basename "$question_file" .md)"
    batch_file="${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/${question_id}-batch.md"

    validation_result="$(validate_batch_content "$batch_file")"

    case "$validation_result" in
      "valid")
        ((valid_batch_count++))
        ;;
      "missing")
        missing_questions+=("$question_id")
        ;;
      *)
        malformed_batches+=("{\"batch_id\":\"${question_id}-batch\",\"issue\":\"${validation_result}\"}")
        ;;
    esac
  done
fi

# Count total query batches (for comparison)
batch_count=0
if [[ -d "${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}" ]]; then
  batch_count="$(find "${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

# Calculate coverage percentage
coverage_percent=0
if [[ $question_count -gt 0 ]]; then
  coverage_percent="$(echo "scale=1; ($valid_batch_count / $question_count) * 100" | bc)"
fi

# Count LLM findings (finding-llm-*.md)
llm_findings=0
if [[ -d "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" ]]; then
  llm_findings="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" -maxdepth 1 -name "finding-llm-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

# Count web findings (finding-*.md excluding finding-llm-*.md)
web_findings=0
if [[ -d "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" ]]; then
  web_findings="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" -maxdepth 1 -name "finding-*.md" ! -name "finding-llm-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

total_findings=$((llm_findings + web_findings))

# Count megatrends (created by findings-creator)
megatrend_count=0
if [[ -d "${PROJECT_PATH}/${DIR_MEGATRENDS}/${DATA_SUBDIR}" ]]; then
  megatrend_count="$(find "${PROJECT_PATH}/${DIR_MEGATRENDS}/${DATA_SUBDIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

# ============================================================================
# AGENT INVOCATION VALIDATION
# ============================================================================

# Count execution logs to detect agent invocation gaps
log_dir="${PROJECT_PATH}/.logs/findings-creator"
agent_logs=0
if [[ -d "$log_dir" ]]; then
  agent_logs="$(find "$log_dir" -name "findings-creator-*.txt" -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

# ============================================================================
# ERROR CHECKS
# ============================================================================

# Critical: No query batches = agents were bypassed
if [[ $batch_count -eq 0 ]]; then
  errors+=("no_batches:agents_bypassed")
fi

# Critical: Batch count should equal question count
if [[ $batch_count -ne $question_count ]] && [[ $batch_count -gt 0 ]]; then
  errors+=("batch_mismatch:${batch_count}vs${question_count}")
fi

# Critical: Missing batches detected
if [[ ${#missing_questions[@]} -gt 0 ]]; then
  errors+=("missing_batches:${#missing_questions[@]}")
fi

# Warning: Malformed batches detected
if [[ ${#malformed_batches[@]} -gt 0 ]]; then
  errors+=("malformed_batches:${#malformed_batches[@]}")
fi

# Findings validation (skip in batch-only mode)
if ! [[ "$BATCH_ONLY" == "true" ]]; then
  # Warning: Low findings count (expect 100+ for DOK 2-3)
  if [[ $total_findings -lt 100 ]] && [[ $total_findings -gt 0 ]]; then
    errors+=("low_findings:${total_findings}")
  fi

  # Critical: No findings at all
  if [[ $total_findings -eq 0 ]]; then
    errors+=("no_findings")
  fi

  # Critical: No web findings (unexpected)
  if [[ $web_findings -eq 0 ]] && [[ $batch_count -gt 0 ]]; then
    errors+=("no_web_findings")
  fi

  # Warning: Agent invocation gap (execution logs missing)
  if [[ $agent_logs -lt $question_count ]] && [[ $question_count -gt 0 ]] && [[ $agent_logs -gt 0 ]]; then
    errors+=("agent_gap:${agent_logs}of${question_count}")
  fi
fi

# ============================================================================
# OUTPUT JSON
# ============================================================================

# Determine success (no critical errors)
success=true
for err in "${errors[@]:-}"; do
  case "$err" in
    no_batches:*|no_findings|no_web_findings|batch_mismatch:*|missing_batches:*)
      success=false
      ;;
  esac
done

# Build compact JSON arrays
errors_json="[]"
if [[ ${#errors[@]} -gt 0 ]]; then
  errors_json="$(printf '%s\n' "${errors[@]}" | jq -R . | jq -sc .)"
fi

missing_json="[]"
if [[ ${#missing_questions[@]} -gt 0 ]]; then
  missing_json="$(printf '%s\n' "${missing_questions[@]}" | jq -R . | jq -sc .)"
fi

malformed_json="[]"
if [[ ${#malformed_batches[@]} -gt 0 ]]; then
  malformed_json="$(printf '%s\n' "${malformed_batches[@]}" | jq -c . | jq -sc .)"
fi

cat <<EOF
{"success":${success},"batches":${batch_count},"questions":${question_count},"missing_questions":${missing_json},"malformed_batches":${malformed_json},"coverage_percent":${coverage_percent},"agent_logs":${agent_logs},"llm_findings":${llm_findings},"web_findings":${web_findings},"total_findings":${total_findings},"megatrends":${megatrend_count},"errors":${errors_json}}
EOF

if [[ "$success" == "true" ]]; then
  exit 0
else
  exit 1
fi
