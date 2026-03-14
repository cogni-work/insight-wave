#!/usr/bin/env bash
# validate-question-files.sh
#
# Purpose: Validates refined question files for empty question text, placeholder values, and missing headings
# Usage: bash validate-question-files.sh --questions-dir <path> [--json]
# Created: Sprint 357 - Fix verification for dimension-planner bug

set -eo pipefail

# Parse arguments
QUESTIONS_DIR=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --questions-dir)
      QUESTIONS_DIR="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$QUESTIONS_DIR" ]]; then
  echo "Error: --questions-dir required" >&2
  echo "Usage: bash validate-question-files.sh --questions-dir <path> [--json]" >&2
  exit 1
fi

if [[ ! -d "$QUESTIONS_DIR" ]]; then
  echo "Error: Questions directory not found: $QUESTIONS_DIR" >&2
  exit 1
fi

# Validation counters
total_files=0
valid_files=0
invalid_files=0
declare -a invalid_file_list=()

# Validation checks
check_question_file() {
  local file="$1"
  local basename="$(basename "$file")"

  # Extract dc:title from YAML frontmatter
  local dc_title="$(grep '^dc:title:' "$file" | sed 's/^dc:title: *//' | tr -d '"')"

  # Extract display_name from YAML frontmatter
  local display_name="$(grep '^display_name:' "$file" | sed 's/^display_name: *//' | tr -d '"')"

  # Extract heading (first line starting with #)
  local heading="$(grep '^# ' "$file" | head -1 | sed 's/^# *//')"

  # Validation: Check if any field is empty or placeholder
  local is_valid=true
  local issues=""

  if [[ -z "$dc_title" ]]; then
    is_valid=false
    issues="${issues}empty dc:title; "
  fi

  if [[ -z "$display_name" ]] || [[ "$display_name" == "..." ]]; then
    is_valid=false
    issues="${issues}invalid display_name ('$display_name'); "
  fi

  if [[ -z "$heading" ]]; then
    is_valid=false
    issues="${issues}empty heading; "
  fi

  if [[ "$is_valid" == true ]]; then
    valid_files=$((valid_files + 1))
  else
    invalid_files=$((invalid_files + 1))
    invalid_file_list+=("$basename: $issues")
  fi
}

# Process all question files
for file in "$QUESTIONS_DIR"/*.md; do
  if [[ -f "$file" ]]; then
    total_files=$((total_files + 1))
    check_question_file "$file"
  fi
done

# Output results
if [[ "$JSON_OUTPUT" == true ]]; then
  # JSON output
  echo "{"
  echo "  \"valid\": $([ $invalid_files -eq 0 ] && echo "true" || echo "false"),"
  echo "  \"total_files\": $total_files,"
  echo "  \"valid_files\": $valid_files,"
  echo "  \"invalid_files\": $invalid_files,"
  echo "  \"invalid_file_details\": ["

  for i in "${!invalid_file_list[@]}"; do
    echo -n "    \"${invalid_file_list[$i]}\""
    if [[ $i -lt $((${#invalid_file_list[@]} - 1)) ]]; then
      echo ","
    else
      echo ""
    fi
  done

  echo "  ]"
  echo "}"
else
  # Human-readable output
  echo "═══════════════════════════════════════════════════════════════"
  echo "Question File Validation Report"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "Directory: $QUESTIONS_DIR"
  echo "Total files: $total_files"
  echo "Valid files: $valid_files"
  echo "Invalid files: $invalid_files"
  echo ""

  if [[ $invalid_files -eq 0 ]]; then
    echo "✅ All question files are valid!"
    echo ""
    echo "Validation checks:"
    echo "  - dc:title is non-empty"
    echo "  - display_name is non-empty and not '...'"
    echo "  - heading (# ...) is non-empty"
  else
    echo "❌ Found $invalid_files invalid question files:"
    echo ""
    for issue in "${invalid_file_list[@]}"; do
      echo "  - $issue"
    done
    echo ""
    echo "These files have empty question text or placeholder values."
    echo "Sprint 357 fix should prevent these issues in future generation."
  fi
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
fi

# Exit with appropriate code
if [[ $invalid_files -eq 0 ]]; then
  exit 0
else
  exit 1
fi
