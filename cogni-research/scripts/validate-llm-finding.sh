#!/usr/bin/env bash
set -euo pipefail
# validate-llm-finding.sh
# Version: 1.0.0
# Purpose: Validate LLM-generated finding entities for schema compliance
# Category: validation
#
# Usage:
#   validate-llm-finding.sh --finding-file <path> [--json]
#
# Exit codes:
#   0   - Validation passed
#   1   - General error
#   2   - Argument error
#   122 - Validation failed


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
FINDING_FILE=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --finding-file)
            FINDING_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

# Validate required arguments
if [[ -z "$FINDING_FILE" ]]; then
    if $JSON_OUTPUT; then
        echo '{"success": false, "error": "Missing required argument: --finding-file"}'
    else
        echo "ERROR: Missing required argument: --finding-file" >&2
    fi
    exit 2
fi

if [[ ! -f "$FINDING_FILE" ]]; then
    if $JSON_OUTPUT; then
        echo "{\"success\": false, \"error\": \"Finding file not found: $FINDING_FILE\"}"
    else
        echo "ERROR: Finding file not found: $FINDING_FILE" >&2
    fi
    exit 2
fi

# Initialize validation results
ERRORS=()
WARNINGS=()

# Read frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$FINDING_FILE" | sed '1d;$d')

# Validation 1: Check question_ref format (wikilink)
QUESTION_REF=$(echo "$FRONTMATTER" | grep -E "^question_ref:" | sed 's/question_ref:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -z "$QUESTION_REF" ]]; then
    ERRORS+=("Missing required field: question_ref")
elif [[ ! "$QUESTION_REF" =~ ^\[\[.*\]\]$ ]]; then
    ERRORS+=("Invalid question_ref format: must be wikilink [[...]], got: $QUESTION_REF")
fi

# Validation 2: Check dc:identifier pattern
DC_IDENTIFIER=$(echo "$FRONTMATTER" | grep -E "^dc:identifier:" | sed 's/dc:identifier:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -z "$DC_IDENTIFIER" ]]; then
    ERRORS+=("Missing required field: dc:identifier")
elif [[ ! "$DC_IDENTIFIER" =~ ^finding-[a-z0-9-]+-[a-f0-9]{8}$ ]]; then
    WARNINGS+=("dc:identifier pattern warning: expected 'finding-{slug}-{8-char-hash}', got: $DC_IDENTIFIER")
fi

# Validation 3: Check dc:creator
DC_CREATOR=$(echo "$FRONTMATTER" | grep -E "^dc:creator:" | sed 's/dc:creator:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -z "$DC_CREATOR" ]]; then
    ERRORS+=("Missing required field: dc:creator")
elif [[ "$DC_CREATOR" == "Claude (findings-creator-llm)" ]]; then
    WARNINGS+=("dc:creator format: should be 'findings-creator-llm' not 'Claude (findings-creator-llm)'")
fi

# Validation 4: Check entity_type
ENTITY_TYPE=$(echo "$FRONTMATTER" | grep -E "^entity_type:" | sed 's/entity_type:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -z "$ENTITY_TYPE" ]]; then
    ERRORS+=("Missing required field: entity_type")
elif ! [[ "$ENTITY_TYPE" == "finding" ]]; then
    ERRORS+=("Invalid entity_type: expected 'finding', got: $ENTITY_TYPE")
fi

# Validation 5: Check dc:created (ISO 8601)
DC_CREATED=$(echo "$FRONTMATTER" | grep -E "^dc:created:" | sed 's/dc:created:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -z "$DC_CREATED" ]]; then
    ERRORS+=("Missing required field: dc:created")
elif [[ ! "$DC_CREATED" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
    ERRORS+=("Invalid dc:created format: expected ISO 8601 timestamp, got: $DC_CREATED")
fi

# Validation 6: Check source_type for LLM findings
SOURCE_TYPE=$(echo "$FRONTMATTER" | grep -E "^source_type:" | sed 's/source_type:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
if [[ -n "$SOURCE_TYPE" && "$SOURCE_TYPE" == "llm_internal_knowledge" ]]; then
    # Check LLM-specific fields
    LLM_MODEL=$(echo "$FRONTMATTER" | grep -E "^llm_model:" | sed 's/llm_model:[[:space:]]*//' | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
    if [[ -z "$LLM_MODEL" ]]; then
        WARNINGS+=("LLM finding missing recommended field: llm_model")
    fi
fi

# Build output
ERROR_COUNT=${#ERRORS[@]}
WARNING_COUNT=${#WARNINGS[@]}
VALIDATION_PASSED=$([[ $ERROR_COUNT -eq 0 ]] && echo "true" || echo "false")

if $JSON_OUTPUT; then
    # JSON output
    ERRORS_JSON="[]"
    if [[ $ERROR_COUNT -gt 0 ]]; then
        ERRORS_JSON=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
    fi

    WARNINGS_JSON="[]"
    if [[ $WARNING_COUNT -gt 0 ]]; then
        WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
    fi

    cat <<EOF
{
  "success": $VALIDATION_PASSED,
  "finding_file": "$FINDING_FILE",
  "error_count": $ERROR_COUNT,
  "warning_count": $WARNING_COUNT,
  "errors": $ERRORS_JSON,
  "warnings": $WARNINGS_JSON
}
EOF
else
    # Text output
    echo "Validating: $FINDING_FILE"
    echo "---"

    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo "ERRORS ($ERROR_COUNT):"
        for err in "${ERRORS[@]}"; do
            echo "  - $err"
        done
    fi

    if [[ $WARNING_COUNT -gt 0 ]]; then
        echo "WARNINGS ($WARNING_COUNT):"
        for warn in "${WARNINGS[@]}"; do
            echo "  - $warn"
        done
    fi

    if [[ "$VALIDATION_PASSED" == "true" ]]; then
        echo "RESULT: PASSED"
    else
        echo "RESULT: FAILED"
    fi
fi

# Exit with appropriate code
if [[ "$VALIDATION_PASSED" == "true" ]]; then
    exit 0
else
    exit 122
fi
