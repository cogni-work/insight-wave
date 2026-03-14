#!/usr/bin/env bash
set -euo pipefail
# post-entity-creation.sh
# Version: 2.0.0
# Purpose: Validate entity structure after creation (YAML, wikilinks, UUID)
#
# This hook triggers after Write tool creates entity files (*.md in entity directories)
#
# Validates:
#   - YAML frontmatter syntax (three dashes delimiters)
#   - Required fields present (entity_type, created_at)
#   - Wikilink format correctness [[entity-type/filename]]
#   - UUID uniqueness in entity-index.json
#
# Environment Variables:
#   DEBUG_MODE    Enable debug logging (true/false, default: false)
#   DEBUG_LEVEL   Logging level: INFO, DEBUG, TRACE (default: INFO)
#
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed (blocks operation)


# ============================================================================
# Enhanced Logging Integration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source enhanced-logging.sh if available
if [[ -f "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh" ]]; then
    source "$PLUGIN_ROOT/scripts/utils/enhanced-logging.sh"
else
    # Fallback logging functions
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
    log_phase() { log_conditional "PHASE" "$1 [$2]"; }
    log_metric() { log_conditional "METRIC" "$1=$2 unit=$3"; }
fi

main() {
    log_phase "post-entity-creation" "start"

    # Read JSON input from stdin (PostToolUse hooks receive JSON via stdin)
    local INPUT_JSON
    INPUT_JSON="$(cat)"

    log_conditional DEBUG "Hook fired, processing input"
    log_conditional TRACE "Raw JSON input: $(echo "$INPUT_JSON" | head -c 500)"

    # Parse JSON using python (more reliable than jq for complex JSON)
    if ! command -v python3 &> /dev/null; then
        log_conditional ERROR "python3 not found"
        exit 0  # Don't block if python3 unavailable
    fi

    # Extract fields from JSON
    local TOOL_NAME
    local FILE_PATH
    TOOL_NAME="$(echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tool_name', ''))" 2>/dev/null || echo "")"
    FILE_PATH="$(echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tool_input', {}).get('file_path', ''))" 2>/dev/null || echo "")"

    log_conditional DEBUG "Parsed - Tool: '$TOOL_NAME' | File: '$FILE_PATH'"

    # Only validate entity markdown files
    if [[ ! "$FILE_PATH" =~ \.md$ ]] || [[ ! "$FILE_PATH" =~ (00|01|02|03|04|05|06|07|08|09|10)- ]]; then
        log_conditional DEBUG "Skipping: Not an entity file"
        exit 0  # Not an entity file, skip validation
    fi

    # Extract project path (accounting for data/ subdirectory structure)
    # FILE_PATH structure: {project}/NN-entity-type/data/{filename}.md
    local FILE_DIR
    local ENTITY_DIR
    local PROJECT_PATH
    FILE_DIR="$(dirname "$FILE_PATH")"
    # Check if we're in a data/ subdirectory
    if [[ "$(basename "$FILE_DIR")" == "data" ]]; then
        ENTITY_DIR="$(dirname "$FILE_DIR")"
        PROJECT_PATH="$(dirname "$ENTITY_DIR")"
    else
        # Fallback for legacy structure (entity files directly in entity directory)
        ENTITY_DIR="$FILE_DIR"
        PROJECT_PATH="$(dirname "$ENTITY_DIR")"
    fi

    # Validation errors array
    local -a ERRORS=()

    # ============================================================================
    # VALIDATION 1: YAML Frontmatter Syntax
    # ============================================================================

    # Check for at least 2 YAML delimiters (opening and closing)
    local DELIMITER_COUNT
    DELIMITER_COUNT="$(grep -c '^---$' "$FILE_PATH" || echo "0")"
    if [[ "$DELIMITER_COUNT" -lt 2 ]]; then
        ERRORS+=("Missing YAML frontmatter delimiters (need at least 2 '---' lines, found $DELIMITER_COUNT)")
    fi

    # Extract frontmatter (between first two --- lines)
    local FRONTMATTER
    FRONTMATTER="$(awk '/^---$/{flag=!flag;next}flag' "$FILE_PATH" | head -20 | tr -d '\r\t')"

    # Check for required fields
    if ! echo "$FRONTMATTER" | grep -q "^entity_type:"; then
        ERRORS+=("Missing required field: entity_type")
    fi

    if ! echo "$FRONTMATTER" | grep -q "^created_at:"; then
        ERRORS+=("Missing required field: created_at")
    fi

    # ============================================================================
    # VALIDATION 2: Wikilink Format
    # ============================================================================

    # Find all wikilinks in file
    local WIKILINKS
    WIKILINKS="$(grep -o '\[\[[^]]*\]\]' "$FILE_PATH" || true)"

    if [[ -n "$WIKILINKS" ]]; then
        while IFS= read -r link; do
            # Extract content between [[ ]]
            local link_content="${link#\[\[}"
            link_content="${link_content%\]\]}"

            # Remove display text (after |)
            local link_path="${link_content%%|*}"

            # Validate format: should be entity-type/data/filename
            if [[ ! "$link_path" =~ ^[0-9]{2}-[a-z-]+/data/[a-z0-9-]+$ ]]; then
                ERRORS+=("Invalid wikilink format: $link (expected: NN-entity-type/data/filename)")
            fi

            # NOTE: Target existence check removed to support parallel entity creation
            # During Phase 4/6 of deeper-research, entities reference each other but targets
            # may not exist yet at validation time. Format validation above is sufficient.
        done <<< "$WIKILINKS"
    fi

    # ============================================================================
    # VALIDATION 3: UUID Uniqueness
    # ============================================================================

    local ENTITY_INDEX="$PROJECT_PATH/.metadata/entity-index.json"

    if [[ -f "$ENTITY_INDEX" ]]; then
        # Extract UUID from filename (assuming format: entity-type-UUID.md)
        local FILENAME
        FILENAME="$(basename "$FILE_PATH" .md)"
        # Extract only the FIRST UUID if multiple patterns exist
        local UUID
        UUID="$(echo "$FILENAME" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1 || echo "")"

        if [[ -n "$UUID" ]]; then
            # Check if UUID already exists in index for a different file
            local EXISTING_PATH
            EXISTING_PATH="$(jq -r ".entities[] | select(.uuid == \"$UUID\") | .path" "$ENTITY_INDEX" 2>/dev/null || echo "")"

            if [[ -n "$EXISTING_PATH" ]]; then
                # Normalize paths for comparison (resolve to absolute paths)
                local NORMALIZED_EXISTING
                local NORMALIZED_CURRENT
                NORMALIZED_EXISTING="$(cd "$(dirname "$EXISTING_PATH")" 2>/dev/null && echo "$(pwd)/$(basename "$EXISTING_PATH")" || echo "$EXISTING_PATH")"
                NORMALIZED_CURRENT="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && echo "$(pwd)/$(basename "$FILE_PATH")" || echo "$FILE_PATH")"

                if ! [[ "$NORMALIZED_EXISTING" == "$NORMALIZED_CURRENT" ]]; then
                    ERRORS+=("UUID collision: $UUID already exists at $EXISTING_PATH")
                fi
            fi
        fi
    fi

    # ============================================================================
    # VALIDATION 4: Entity Type Directory Match
    # ============================================================================

    # Extract entity_type from frontmatter
    local ENTITY_TYPE
    ENTITY_TYPE="$(echo "$FRONTMATTER" | grep "^entity_type:" | sed 's/entity_type:[[:space:]]*//' | tr -d '"' || echo "")"

    # Extract entity directory name
    local DIR_NAME
    DIR_NAME="$(basename "$ENTITY_DIR")"

    # Verify entity_type matches directory
    if [[ -n "$ENTITY_TYPE" ]] && ! [[ "$ENTITY_TYPE" == "$DIR_NAME" ]]; then
        ERRORS+=("Entity type mismatch: frontmatter says '$ENTITY_TYPE' but file is in '$DIR_NAME' directory")
    fi

    # ============================================================================
    # Report Results
    # ============================================================================

    log_metric "validation_errors" "${#ERRORS[@]}" "count"

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        log_conditional ERROR "Entity validation FAILED for: $FILE_PATH"
        for error in "${ERRORS[@]}"; do
            log_conditional ERROR "  $error"
        done
        echo "❌ Entity validation FAILED for: $FILE_PATH"
        echo ""
        for error in "${ERRORS[@]}"; do
            echo "  • $error"
        done
        echo ""
        echo "Fix these issues before proceeding."
        log_phase "post-entity-creation" "complete"
        exit 1
    fi

    log_conditional INFO "Entity validation PASSED: $FILE_PATH"
    echo "✅ Entity validation PASSED: $FILE_PATH"
    log_phase "post-entity-creation" "complete"
    exit 0
}

# Execute main function
main "$@"
