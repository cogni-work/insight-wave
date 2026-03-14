#!/usr/bin/env bash
set -euo pipefail
# validate-entity-schema.sh
# Version: 1.0.0
# Purpose: Validate entity YAML frontmatter against JSON Schema Draft 07 definitions
# Category: validators
#
# Usage:
#   validate-entity-schema.sh --entity-type <type> --entity-file <path> --schema-path <path> --json
#
# Arguments:
#   --entity-type <string>     Entity type (source, finding, publisher, etc.) (required)
#   --entity-file <path>       Absolute path to entity markdown file (required)
#   --schema-path <path>       Absolute path to JSON schema file (required)
#   --json                     Output results in JSON format (required)
#
# Output:
#   JSON: {
#     "success": true|false,
#     "data": {
#       "status": "success|failure",
#       "entity_type": "source",
#       "entity_file": "/path/to/entity.md",
#       "schema_path": "/path/to/schema.json",
#       "validation_errors": [
#         {"field": "dc:identifier", "error": "pattern mismatch", "line": 3}
#       ],
#       "timestamp": "2025-01-26T12:00:00.000Z"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed (schema violations found)
#   2 - Invalid parameters
#   3 - Schema file not found
#   4 - Entity file not found
#   5 - Missing required tools (yq, jq)
#
# Example:
#   validate-entity-schema.sh \
#     --entity-type "source" \
#     --entity-file "/path/to/07-sources/source-abc123.md" \
#     --schema-path "/path/to/schemas/source-entity.schema.json" \
#     --json


# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging
  log_conditional() {
    local level="$1"
    local message="$2"
    [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$level] $message" >&2
  }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Error response function
error_json() {
  local message="$1"
  local exit_code="${2:-1}"
  jq -n \
    --arg error "$message" \
    --argjson code "$exit_code" \
    '{success: false, error: $error, error_code: $code}' >&2
  exit "$exit_code"
}

# Parse arguments
ENTITY_TYPE=""
ENTITY_FILE=""
SCHEMA_PATH=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --entity-type)
      ENTITY_TYPE="$2"
      shift 2
      ;;
    --entity-file)
      ENTITY_FILE="$2"
      shift 2
      ;;
    --schema-path)
      SCHEMA_PATH="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      error_json "Unknown argument: $1" 2
      ;;
  esac
done

log_phase "INIT" "Validation started for entity type: $ENTITY_TYPE"

# Validate required arguments
if [[ -z "$ENTITY_TYPE" ]] || [[ -z "$ENTITY_FILE" ]] || [[ -z "$SCHEMA_PATH" ]]; then
  error_json "Missing required arguments: --entity-type, --entity-file, --schema-path, and --json are all required" 2
fi

if ! [[ "$JSON_OUTPUT" == true ]]; then
  error_json "Missing required --json flag" 2
fi

log_conditional DEBUG "Entity type: $ENTITY_TYPE"
log_conditional DEBUG "Entity file: $ENTITY_FILE"
log_conditional DEBUG "Schema path: $SCHEMA_PATH"

# Check schema file exists
if [[ ! -f "$SCHEMA_PATH" ]]; then
  error_json "Schema file not found: $SCHEMA_PATH" 3
fi

# Check entity file exists
if [[ ! -f "$ENTITY_FILE" ]]; then
  error_json "Entity file not found: $ENTITY_FILE" 4
fi

log_phase "TOOLS_CHECK" "Verifying required tools"

# Check for required tools
if ! command -v yq &> /dev/null; then
  error_json "Required tool 'yq' not found. Install: brew install yq" 5
fi

if ! command -v jq &> /dev/null; then
  error_json "Required tool 'jq' not found. Install: brew install jq" 5
fi

log_conditional DEBUG "Required tools verified: yq, jq"
log_metric "tool_check_passed" "true" "boolean"

log_phase "EXTRACT_FRONTMATTER" "Extracting YAML frontmatter from entity file"

# Extract YAML frontmatter from entity markdown file
# Frontmatter is between first two --- markers
FRONTMATTER_YAML="$(sed -n '/^---$/,/^---$/p' "$ENTITY_FILE" 2>/dev/null | sed '1d;$d')"

if [[ -z "$FRONTMATTER_YAML" ]]; then
  error_json "No YAML frontmatter found in entity file: $ENTITY_FILE" 4
fi

log_conditional DEBUG "Frontmatter extracted successfully"
log_metric "frontmatter_lines" "$(echo "$FRONTMATTER_YAML" | wc -l | tr -d ' ')" "count"

log_phase "CONVERT_YAML" "Converting YAML to JSON"

# Convert YAML to JSON using yq
FRONTMATTER_JSON="$(echo "$FRONTMATTER_YAML" | yq eval -o=json '.' - 2>/dev/null)"

if [[ -z "$FRONTMATTER_JSON" ]]; then
  error_json "Failed to convert YAML frontmatter to JSON" 1
fi

log_conditional DEBUG "YAML converted to JSON successfully"

log_phase "VALIDATE_SCHEMA" "Validating frontmatter against JSON schema"

# Validate JSON against schema using jq
# We use a simple jq-based validation approach since ajv-cli may not be installed
# This validates basic structure but not full JSON Schema compliance
VALIDATION_ERRORS=()
VALIDATION_STATUS="success"

# Read schema to extract required fields
REQUIRED_FIELDS="$(jq -r '.required[]? // empty' "$SCHEMA_PATH" 2>/dev/null)"

# Check required fields
if [[ -n "$REQUIRED_FIELDS" ]]; then
  while IFS= read -r field; do
    # Check if field exists in frontmatter
    field_value="$(echo "$FRONTMATTER_JSON" | jq -r --arg field "$field" '.[$field] // empty' 2>/dev/null)"

    if [[ -z "$field_value" ]]; then
      VALIDATION_ERRORS+=("$(jq -n \
        --arg field "$field" \
        --arg error "Required field missing" \
        --argjson line 0 \
        '{field: $field, error: $error, line: $line}')")
      VALIDATION_STATUS="failure"
    fi
  done <<< "$REQUIRED_FIELDS"
fi

log_conditional DEBUG "Required fields validation completed"
log_metric "required_fields_checked" "$(echo "$REQUIRED_FIELDS" | wc -l | tr -d ' ')" "count"

# Validate field types from schema properties
SCHEMA_PROPERTIES="$(jq -r '.properties | keys[]? // empty' "$SCHEMA_PATH" 2>/dev/null)"

if [[ -n "$SCHEMA_PROPERTIES" ]]; then
  while IFS= read -r property; do
    # Get expected type from schema
    expected_type="$(jq -r --arg prop "$property" '.properties[$prop].type // empty' "$SCHEMA_PATH" 2>/dev/null)"

    if [[ -n "$expected_type" ]]; then
      # Get actual value from frontmatter
      actual_value="$(echo "$FRONTMATTER_JSON" | jq -r --arg prop "$property" '.[$prop] // empty' 2>/dev/null)"

      # Skip if field doesn't exist (already caught by required check)
      if [[ -z "$actual_value" ]]; then
        continue
      fi

      # Check type match using jq type function
      actual_type="$(echo "$FRONTMATTER_JSON" | jq -r --arg prop "$property" '.[$prop] | type // empty' 2>/dev/null)"

      # Map jq types to JSON Schema types
      case "$actual_type" in
        string) jq_schema_type="string" ;;
        number) jq_schema_type="number" ;;
        boolean) jq_schema_type="boolean" ;;
        array) jq_schema_type="array" ;;
        object) jq_schema_type="object" ;;
        null) jq_schema_type="null" ;;
        *) jq_schema_type="unknown" ;;
      esac

      if ! [[ "$jq_schema_type" == "$expected_type" ]] && ! [[ "$expected_type" == "null" ]]; then
        VALIDATION_ERRORS+=("$(jq -n \
          --arg field "$property" \
          --arg error "Type mismatch: expected $expected_type, got $jq_schema_type" \
          --argjson line 0 \
          '{field: $field, error: $error, line: $line}')")
        VALIDATION_STATUS="failure"
      fi
    fi
  done <<< "$SCHEMA_PROPERTIES"
fi

log_conditional DEBUG "Property type validation completed"
log_metric "validation_errors_found" "${#VALIDATION_ERRORS[@]}" "count"

# Validate pattern constraints from schema
while IFS= read -r property; do
  pattern="$(jq -r --arg prop "$property" '.properties[$prop].pattern // empty' "$SCHEMA_PATH" 2>/dev/null)"

  if [[ -n "$pattern" ]]; then
    actual_value="$(echo "$FRONTMATTER_JSON" | jq -r --arg prop "$property" '.[$prop] // empty' 2>/dev/null)"

    if [[ -n "$actual_value" ]]; then
      # Use grep to test pattern match (basic regex)
      if ! echo "$actual_value" | grep -qE "$pattern"; then
        VALIDATION_ERRORS+=("$(jq -n \
          --arg field "$property" \
          --arg error "Pattern mismatch: value does not match required pattern" \
          --argjson line 0 \
          '{field: $field, error: $error, line: $line}')")
        VALIDATION_STATUS="failure"
      fi
    fi
  fi
done <<< "$SCHEMA_PROPERTIES"

log_conditional DEBUG "Pattern validation completed"
log_phase "RESULTS" "Building validation results"

# Build validation errors array
ERRORS_JSON="[]"
if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
  ERRORS_JSON="["
  for ((i=0; i<${#VALIDATION_ERRORS[@]}; i++)); do
    ERRORS_JSON+="${VALIDATION_ERRORS[$i]}"
    if [[ $i -lt $((${#VALIDATION_ERRORS[@]} - 1)) ]]; then
      ERRORS_JSON+=","
    fi
  done
  ERRORS_JSON+="]"
fi

# Generate timestamp
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build success response
jq -n \
  --arg status "$VALIDATION_STATUS" \
  --arg entity_type "$ENTITY_TYPE" \
  --arg entity_file "$ENTITY_FILE" \
  --arg schema_path "$SCHEMA_PATH" \
  --argjson errors "$ERRORS_JSON" \
  --arg timestamp "$TIMESTAMP" \
  '{
    success: true,
    data: {
      status: $status,
      entity_type: $entity_type,
      entity_file: $entity_file,
      schema_path: $schema_path,
      validation_errors: $errors,
      timestamp: $timestamp
    }
  }'

log_metric "execution_time" "$(date +%s)" "timestamp"

# Exit with appropriate code
if [[ "$VALIDATION_STATUS" == "failure" ]]; then
  log_conditional INFO "Validation failed with ${#VALIDATION_ERRORS[@]} errors"
  exit 1
else
  log_conditional INFO "Validation passed successfully"
  exit 0
fi
