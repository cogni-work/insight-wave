#!/usr/bin/env bash
set -euo pipefail
# repair-publisher-links.sh
# Version: 1.0.1
# Purpose: Fix broken publisher wikilinks by fuzzy-matching to actual publisher files
# Category: utilities
#
# Usage: repair-publisher-links.sh --project-path <path> [options]
#
# Arguments:
#   --project-path <path>       Absolute path to deeper-research project directory (required)
#   --dry-run                   Preview changes without applying them (optional)
#   --json                      Output results in JSON format (optional)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "mode": "dry-run" | "repair",
#       "broken_links_found": number,
#       "links_repaired": number,
#       "links_unresolved": number,
#       "repairs": [
#         {
#           "file": "path",
#           "old_link": "[[...]]",
#           "new_link": "[[...]]",
#           "match_score": number
#         }
#       ]
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Some links unresolved
#   2 - Invalid arguments
#   3 - Project path not found


# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity config
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh not found at ${SCRIPT_DIR}/lib/entity-config.sh" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"

# Parse arguments
PROJECT_PATH=""
DRY_RUN=false
JSON_OUTPUT=false

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
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# Validation
if [[ -z "$PROJECT_PATH" ]]; then
    echo "ERROR: Missing required argument: --project-path" >&2
    exit 2
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "ERROR: Project path not found: $PROJECT_PATH" >&2
    exit 3
fi

PUBLISHERS_DIR="$PROJECT_PATH/08-publishers/$DATA_SUBDIR"
if [[ ! -d "$PUBLISHERS_DIR" ]]; then
    echo "ERROR: Publishers directory not found: $PUBLISHERS_DIR" >&2
    exit 3
fi

# Build index of actual publisher files
# Format: normalized_name -> actual_filename
build_publisher_index() {
    local index_file="$(mktemp)"

    while IFS= read -r file; do
        local filename
        filename="$(basename "$file" .md)"

        # Extract the core name without hash (e.g., "publisher-researchgatenet" from "publisher-researchgatenet-5a65971f")
        # Remove trailing hash (8 hex chars)
        local core_name
        core_name="$(echo "$filename" | sed -E 's/-[a-f0-9]{8}$//')"

        # Normalize: lowercase, remove common TLD suffixes for matching
        local normalized
        normalized="$(echo "$core_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/(com|de|net|org|eu|co|info)$//')"

        echo "$normalized|$filename" >> "$index_file"
    done < <(find "$PUBLISHERS_DIR" -maxdepth 1 -name "publisher-*.md" -type f)

    echo "$index_file"
}

# Find best matching publisher for a broken link
find_best_match() {
    local broken_id="$1"
    local index_file="$2"

    # Extract core name from broken link (e.g., "publisher-researchgate" from "publisher-researchgate-3b63d740")
    local broken_core
    broken_core="$(echo "$broken_id" | sed -E 's/-[a-f0-9]{8}$//')"
    local broken_normalized
    broken_normalized="$(echo "$broken_core" | tr '[:upper:]' '[:lower:]')"

    # Try exact match first (after normalization)
    local exact_match
    exact_match="$(grep "^${broken_normalized}|" "$index_file" | head -1 | cut -d'|' -f2)"
    if [[ -n "$exact_match" ]]; then
        echo "$exact_match|100"
        return
    fi

    # Try prefix match (broken name is prefix of actual name)
    local prefix_match
    prefix_match="$(grep "^${broken_normalized}" "$index_file" | head -1 | cut -d'|' -f2)"
    if [[ -n "$prefix_match" ]]; then
        echo "$prefix_match|90"
        return
    fi

    # Try contains match
    local contains_match
    contains_match="$(grep "${broken_normalized}" "$index_file" | head -1 | cut -d'|' -f2)"
    if [[ -n "$contains_match" ]]; then
        echo "$contains_match|70"
        return
    fi

    # No match found
    echo "|0"
}

# Main repair logic
main() {
    local index_file
    index_file="$(build_publisher_index)"
    trap "rm -f '$index_file'" EXIT

    # Find all broken publisher links
    local broken_links_file="$(mktemp)"
    local repairs_file="$(mktemp)"
    local unresolved_file="$(mktemp)"
    trap "rm -f '$index_file' '$broken_links_file' '$repairs_file' '$unresolved_file'" EXIT

    # Find all unique broken publisher links (both with and without workspace prefix)
    # Pattern 1: [[08-publishers/data/publisher-...]]
    # Pattern 2: [[.../08-publishers/data/publisher-...]] (workspace prefix)
    grep -roh '\[\[[^]]*08-publishers/data/publisher-[^]]*\]\]' "$PROJECT_PATH" --include='*.md' 2>/dev/null | sort -u > "$broken_links_file" || true

    local broken_count=0
    local repaired_count=0
    local unresolved_count=0

    # Initialize JSON arrays
    echo "[]" > "$repairs_file.json"

    while IFS= read -r wikilink; do
        [[ -z "$wikilink" ]] && continue

        # Extract the publisher ID from wikilink, handling optional workspace prefix
        # Pattern: [[prefix/08-publishers/data/publisher-xxx]] or [[08-publishers/data/publisher-xxx]]
        local publisher_id
        publisher_id="$(echo "$wikilink" | sed 's/.*08-publishers\/data\///; s/\]\]//')"

        # Extract workspace prefix if present (everything before 08-publishers)
        local workspace_prefix=""
        if [[ "$wikilink" == *"/08-publishers/"* ]] && ! [[ "$wikilink" == "[[08-publishers/"* ]]; then
            workspace_prefix="$(echo "$wikilink" | sed 's/\[\[//; s/08-publishers.*//')"
        fi

        # Check if file exists
        if [[ -f "$PUBLISHERS_DIR/$publisher_id.md" ]]; then
            continue  # Not broken
        fi

        broken_count=$((broken_count + 1))

        # Find best match
        local match_result
        match_result="$(find_best_match "$publisher_id" "$index_file")"
        local matched_file
        matched_file="$(echo "$match_result" | cut -d'|' -f1)"
        local match_score
        match_score="$(echo "$match_result" | cut -d'|' -f2)"

        if [[ -n "$matched_file" ]] && [[ "$match_score" -ge 70 ]]; then
            # Build new wikilink, preserving workspace prefix if present
            local new_wikilink
            if [[ -n "$workspace_prefix" ]]; then
                new_wikilink="[[${workspace_prefix}08-publishers/$DATA_SUBDIR/$matched_file]]"
            else
                new_wikilink="[[08-publishers/$DATA_SUBDIR/$matched_file]]"
            fi

            # Record repair
            local repair_entry
            repair_entry="$(jq -n \
                --arg old "$wikilink" \
                --arg new "$new_wikilink" \
                --argjson score "$match_score" \
                '{old_link: $old, new_link: $new, match_score: $score}')"

            jq --argjson item "$repair_entry" '. + [$item]' "$repairs_file.json" > "$repairs_file.tmp"
            mv "$repairs_file.tmp" "$repairs_file.json"

            # Apply repair if not dry-run
            if [[ "$DRY_RUN" == false ]]; then
                # Escape brackets for grep (grep needs \[ and \] for literal brackets)
                local grep_pattern
                grep_pattern="$(printf '%s\n' "$wikilink" | sed 's/\[/\\[/g; s/\]/\\]/g')"

                # Find all files containing this wikilink and replace
                while IFS= read -r file; do
                    # Escape brackets and special characters for sed
                    local escaped_old
                    escaped_old="$(printf '%s\n' "$wikilink" | sed 's/\[/\\[/g; s/\]/\\]/g; s/\//\\\//g')"
                    local escaped_new
                    escaped_new="$(printf '%s\n' "$new_wikilink" | sed 's/\//\\\//g')"

                    sed -i.bak "s/$escaped_old/$escaped_new/g" "$file"
                    rm -f "${file}.bak"
                done < <(grep -rl "$grep_pattern" "$PROJECT_PATH" --include='*.md' 2>/dev/null || true)
            fi

            repaired_count=$((repaired_count + 1))
        else
            unresolved_count=$((unresolved_count + 1))
            echo "$wikilink" >> "$unresolved_file"
        fi
    done < "$broken_links_file"

    # Generate output
    local mode="repair"
    [[ "$DRY_RUN" == true ]] && mode="dry-run"

    if [[ "$JSON_OUTPUT" == true ]]; then
        local repairs_json
        repairs_json="$(cat "$repairs_file.json")"

        jq -n \
            --arg mode "$mode" \
            --argjson broken "$broken_count" \
            --argjson repaired "$repaired_count" \
            --argjson unresolved "$unresolved_count" \
            --argjson repairs "$repairs_json" \
            '{
                success: true,
                data: {
                    mode: $mode,
                    broken_links_found: $broken,
                    links_repaired: $repaired,
                    links_unresolved: $unresolved,
                    repairs: $repairs
                }
            }'
    else
        echo "Publisher Link Repair Report"
        echo "============================="
        echo "Mode: $mode"
        echo "Project: $PROJECT_PATH"
        echo ""
        echo "Summary:"
        echo "  Broken publisher links: $broken_count"
        echo "  Repaired: $repaired_count"
        echo "  Unresolved: $unresolved_count"
        echo ""

        if [[ "$repaired_count" -gt 0 ]]; then
            echo "Repairs:"
            jq -r '.[] | "  \(.old_link) -> \(.new_link) (score: \(.match_score))"' "$repairs_file.json"
            echo ""
        fi

        if [[ "$unresolved_count" -gt 0 ]]; then
            echo "Unresolved links:"
            while IFS= read -r link; do
                echo "  $link"
            done < "$unresolved_file"
        fi
    fi

    # Exit code
    if [[ "$unresolved_count" -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main
