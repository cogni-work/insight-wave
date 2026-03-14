#!/usr/bin/env bash
set -euo pipefail
# update-batch-with-findings.sh
# Version: 1.0.0
# Purpose: Update query batch entity with finding_ids array for bidirectional navigation
#
# Usage:
#   ./update-batch-with-findings.sh --project-path <path> --batch-file <path> --finding-ids <json-array> [--validate-format <bool>]
#
# Arguments:
#   --project-path <string>     Path to research project root directory (required)
#   --batch-file <string>       Path to batch entity markdown file (required)
#   --finding-ids <json-array>  JSON array of finding wikilinks [[04-findings/data/slug]] (required)
#   --validate-format <bool>    Enforce wiki-link format validation (optional, default: true)
#
# Output:
#   JSON object with structure:
#   {
#     "success": true|false,
#     "batch_file": "/absolute/path/to/batch.md",
#     "findings_added": 12,
#     "validation": {
#       "format_validated": true,
#       "bidirectional_links_checked": true,
#       "broken_links": 0,
#       "missing_backlinks": 0
#     },
#     "errors": []
#   }
#
# Exit codes:
#   0 - Update completed successfully
#   1 - Validation error (invalid format or missing backlinks)
#   2 - Invalid arguments (missing required parameters)
#   3 - File operation error (batch file not found)
#   4 - Atomic update failed (frontmatter validation failed)
#
# Example:
#   ./update-batch-with-findings.sh \
#     --project-path /path/to/research-project \
#     --batch-file 03-batches/batch-001.md \
#     --finding-ids '[["[[04-findings/data/finding-001]]","[[04-findings/data/finding-002]]"]]'


# ============================================================================
# ENTITY CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source entity configuration for directory key resolution (required)
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_FINDINGS="$(get_directory_by_key "findings")"

# ============================================================================
# ERROR HANDLING
# ============================================================================

error_json() {
    local message="$1"
    local code="${2:-1}"

    jq -n \
        --arg msg "$message" \
        --argjson code "$code" \
        '{
            success: false,
            error: $msg,
            error_code: $code
        }' >&2

    exit "$code"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

PROJECT_PATH=""
BATCH_FILE=""
FINDING_IDS_JSON=""
VALIDATE_FORMAT="true"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --batch-file)
            BATCH_FILE="$2"
            shift 2
            ;;
        --finding-ids)
            FINDING_IDS_JSON="$2"
            shift 2
            ;;
        --validate-format)
            VALIDATE_FORMAT="$2"
            shift 2
            ;;
        *)
            error_json "Unknown argument: $1" 2
            ;;
    esac
done

# Validate required parameters
[[ -n "$PROJECT_PATH" ]] || error_json "Missing required parameter: --project-path" 2
[[ -n "$BATCH_FILE" ]] || error_json "Missing required parameter: --batch-file" 2
[[ -n "$FINDING_IDS_JSON" ]] || error_json "Missing required parameter: --finding-ids" 2

# Validate project directory exists
[[ -d "$PROJECT_PATH" ]] || error_json "Project directory not found: $PROJECT_PATH" 3

# Resolve batch file path (handle relative paths)
if [[ "$BATCH_FILE" = /* ]]; then
    BATCH_FILE_ABS="$BATCH_FILE"
else
    BATCH_FILE_ABS="${PROJECT_PATH}/${BATCH_FILE}"
fi

# Validate batch file exists
[[ -f "$BATCH_FILE_ABS" ]] || error_json "Batch file not found: $BATCH_FILE_ABS" 3
[[ -r "$BATCH_FILE_ABS" ]] || error_json "Batch file not readable: $BATCH_FILE_ABS" 3

# Validate finding_ids is valid JSON array
if ! echo "$FINDING_IDS_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
    error_json "Parameter --finding-ids must be a JSON array" 2
fi

# ============================================================================
# WIKI-LINK FORMAT VALIDATION
# ============================================================================

validate_wikilink_format() {
    local finding_id="$1"

    # Must match: [[{DIR_FINDINGS}/data/finding-slug]]
    if [[ ! "$finding_id" =~ ^\[\[${DIR_FINDINGS}/data/[a-z0-9-]+\]\]$ ]]; then
        echo "ERROR: Invalid wikilink format: $finding_id" >&2
        echo "Expected: [[${DIR_FINDINGS}/data/finding-slug]]" >&2
        return 1
    fi

    return 0
}

# Validate all finding_ids if format validation enabled
VALIDATION_ERRORS=0

if [[ "$VALIDATE_FORMAT" = "true" ]]; then
    while IFS= read -r finding_id; do
        if ! validate_wikilink_format "$finding_id"; then
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    done < <(echo "$FINDING_IDS_JSON" | jq -r '.[]')

    if [[ $VALIDATION_ERRORS -gt 0 ]]; then
        error_json "Found $VALIDATION_ERRORS finding_ids with invalid wiki-link format" 1
    fi
fi

# ============================================================================
# ATOMIC BATCH FILE UPDATE
# ============================================================================

BATCH_ID="$(basename "$BATCH_FILE_ABS" .md)"
TMP_BATCH="${BATCH_FILE_ABS}.tmp.$$"

# Trap to cleanup temp file on exit
trap 'rm -f "$TMP_BATCH"' EXIT

# Convert JSON array to newline-separated list for awk
FINDING_IDS_LIST="$(echo "$FINDING_IDS_JSON" | jq -r '.[]')"

# Update batch file frontmatter with finding_ids
awk -v finding_ids="$FINDING_IDS_LIST" '
BEGIN {
    in_frontmatter = 0
    frontmatter_ended = 0
    finding_ids_found = 0
    finding_ids_section = 0
    split(finding_ids, ids_array, "\n")
}

# Start of frontmatter
/^---$/ && NR == 1 {
    in_frontmatter = 1
    print
    next
}

# End of frontmatter
/^---$/ && in_frontmatter && !frontmatter_ended {
    # Insert finding_ids before closing --- if not already present
    if (!finding_ids_found) {
        print "finding_ids:"
        for (i in ids_array) {
            if (ids_array[i] != "") {
                print "  - " ids_array[i]
            }
        }
        finding_ids_found = 1
    }

    frontmatter_ended = 1
    in_frontmatter = 0
    print
    next
}

# Update existing finding_ids section
/^finding_ids:/ && in_frontmatter {
    print "finding_ids:"
    for (i in ids_array) {
        if (ids_array[i] != "") {
            print "  - " ids_array[i]
        }
    }
    finding_ids_section = 1
    finding_ids_found = 1
    next
}

# Skip old finding_ids array items
finding_ids_section && /^  - / {
    next
}

# Exit finding_ids section when we hit non-list line
finding_ids_section && !/^  - / {
    finding_ids_section = 0
}

# Print all other lines
{
    print
}
' "$BATCH_FILE_ABS" > "$TMP_BATCH"

# Validate temp file contains finding_ids section
if ! grep -q "^finding_ids:" "$TMP_BATCH"; then
    rm -f "$TMP_BATCH"
    error_json "Batch update validation failed: finding_ids section not found in updated file" 4
fi

# Atomic move (overwrite original)
mv "$TMP_BATCH" "$BATCH_FILE_ABS"

# ============================================================================
# BIDIRECTIONAL LINK VALIDATION
# ============================================================================

BROKEN_LINKS=0
MISSING_BACKLINKS=0

while IFS= read -r finding_wikilink; do
    [[ -z "$finding_wikilink" ]] && continue

    # Extract finding file from wikilink: [[04-findings/data/finding-X]] → 04-findings/data/finding-X.md
    FINDING_SLUG="$(echo "$finding_wikilink" | sed 's/\[\[//' | sed 's/\]\]//')"
    FINDING_FILE="${PROJECT_PATH}/${FINDING_SLUG}.md"

    # Check if finding file exists
    if [[ ! -f "$FINDING_FILE" ]]; then
        echo "WARNING: Finding not found: $FINDING_FILE" >&2
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
        continue
    fi

    # Check if finding has batch_id pointing back to this batch
    if ! grep -q "batch_id:.*${BATCH_ID}" "$FINDING_FILE"; then
        echo "WARNING: Finding $FINDING_FILE missing batch_id backlink to $BATCH_ID" >&2
        MISSING_BACKLINKS=$((MISSING_BACKLINKS + 1))
    fi
done <<< "$FINDING_IDS_LIST"

# ============================================================================
# SUCCESS OUTPUT
# ============================================================================

FINDINGS_COUNT="$(echo "$FINDING_IDS_JSON" | jq 'length')"

jq -n \
    --arg batch_file "$BATCH_FILE_ABS" \
    --argjson findings_count "$FINDINGS_COUNT" \
    --argjson format_validated "$([[ "$VALIDATE_FORMAT" = "true" ]] && echo true || echo false)" \
    --argjson broken_links "$BROKEN_LINKS" \
    --argjson missing_backlinks "$MISSING_BACKLINKS" \
    '{
        success: true,
        batch_file: $batch_file,
        findings_added: $findings_count,
        validation: {
            format_validated: $format_validated,
            bidirectional_links_checked: true,
            broken_links: $broken_links,
            missing_backlinks: $missing_backlinks
        },
        errors: []
    }'

# Exit with code 1 if validation issues found (non-blocking)
if [[ $BROKEN_LINKS -gt 0 ]] || [[ $MISSING_BACKLINKS -gt 0 ]]; then
    exit 1
fi

exit 0
