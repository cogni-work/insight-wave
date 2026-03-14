#!/usr/bin/env bash
set -euo pipefail
# repair-publisher-ids.sh
# Version: 1.0.0
# Purpose: Fix publisher IDs to use deterministic format matching source wikilinks
# Category: deeper-research utilities
#
# Usage: bash repair-publisher-ids.sh --project-path /path/to/project [--dry-run]
#
# This script:
# 1. Reads each publisher file's domain field
# 2. Generates the correct deterministic ID using generate-publisher-id.sh
# 3. Renames the file and updates the id field in frontmatter
#
# Exit codes:
#   0 - Success
#   1 - Error (missing arguments, directory not found, etc.)

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$SCRIPT_DIR")}"

# Parse arguments
PROJECT_PATH=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$PROJECT_PATH" ]]; then
    echo "Error: --project-path is required" >&2
    exit 1
fi

PUBLISHERS_DIR="$PROJECT_PATH/08-publishers/data"
GENERATE_ID_SCRIPT="$PLUGIN_ROOT/scripts/utils/generate-publisher-id.sh"

if [[ ! -d "$PUBLISHERS_DIR" ]]; then
    echo "Error: Publishers directory not found: $PUBLISHERS_DIR" >&2
    exit 1
fi

if [[ ! -f "$GENERATE_ID_SCRIPT" ]]; then
    echo "Error: generate-publisher-id.sh not found: $GENERATE_ID_SCRIPT" >&2
    exit 1
fi

echo "=== Publisher ID Repair Script ==="
echo "Project: $PROJECT_PATH"
echo "Dry run: $DRY_RUN"
echo ""

# Counters
TOTAL=0
RENAMED=0
SKIPPED=0
ERRORS=0
DUPLICATES=0

# Track new IDs to detect duplicates
declare -A NEW_IDS

# Process each publisher file
for file in "$PUBLISHERS_DIR"/publisher-*.md; do
    [[ -f "$file" ]] || continue
    TOTAL=$((TOTAL + 1))

    filename=$(basename "$file")
    current_id="${filename%.md}"

    # Extract domain from frontmatter
    domain=$(grep -m1 "^domain:" "$file" 2>/dev/null | sed 's/^domain:[[:space:]]*//' | tr -d '"' || echo "")

    if [[ -z "$domain" ]]; then
        echo "SKIP: $filename - no domain field"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Generate correct ID
    result=$("$GENERATE_ID_SCRIPT" --domain "$domain" --json 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "ERROR: $filename - generate-publisher-id.sh failed for domain: $domain"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    new_id=$(echo "$result" | grep -o '"publisher_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"publisher_id"[[:space:]]*:[[:space:]]*"//' | tr -d '"')
    org_name=$(echo "$result" | grep -o '"org_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"org_name"[[:space:]]*:[[:space:]]*"//' | tr -d '"')

    if [[ -z "$new_id" ]]; then
        echo "ERROR: $filename - could not parse publisher_id from result"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Check if already correct
    if [[ "$current_id" == "$new_id" ]]; then
        echo "OK: $filename - already has correct ID"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Check for duplicate new IDs
    if [[ -n "${NEW_IDS[$new_id]}" ]]; then
        echo "DUPLICATE: $filename would become $new_id (already assigned to ${NEW_IDS[$new_id]})"
        DUPLICATES=$((DUPLICATES + 1))
        # Still rename, but append to existing file's source_references instead
        # For now, just skip
        continue
    fi

    NEW_IDS[$new_id]="$filename"

    new_file="$PUBLISHERS_DIR/${new_id}.md"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "WOULD RENAME: $filename → ${new_id}.md (domain: $domain)"
    else
        # Update id field in frontmatter
        sed -i '' "s/^id: $current_id$/id: $new_id/" "$file"

        # Rename file
        mv "$file" "$new_file"

        echo "RENAMED: $filename → ${new_id}.md (domain: $domain)"
    fi

    RENAMED=$((RENAMED + 1))
done

echo ""
echo "=== Summary ==="
echo "Total publishers: $TOTAL"
echo "Renamed: $RENAMED"
echo "Skipped (OK or no domain): $SKIPPED"
echo "Duplicates: $DUPLICATES"
echo "Errors: $ERRORS"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "This was a dry run. Run without --dry-run to apply changes."
fi
