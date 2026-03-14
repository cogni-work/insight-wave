#!/usr/bin/env bash
# validate-wikilinks.sh
# Version: 3.3.0
# Purpose: Verify all wikilinks resolve to existing entity files with categorized error reporting,
#          optional backlink symmetry validation, and citation chain integrity validation
# Changelog:
#   3.3.0: Add partial_path error category for auto-repair of relative wikilinks (../prefix, data/ without entity dir)
#   3.2.1: Fix bash arithmetic expression bug causing silent exit when counters start at 0
#          Add || true to all ((counter++)) expressions to prevent set -e termination
#          Fix entity key mismatch: research-synthesis -> synthesis
#   3.2.0: Add trailing_backslash error category for auto-repair of LLM-generated wikilinks with trailing backslashes
#
# Usage:
#   validate-wikilinks.sh --project-path <path> [OPTIONS]
#
# Arguments:
#   --project-path <path>      Project directory path (required)
#   --json                     Output results in JSON format
#   --check-symmetry           Enable backlink symmetry validation (checks bidirectional consistency)
#   --check-chains             Enable citation chain integrity validation (verifies Citation → Source → Publisher)
#
# Returns:
#   JSON: {"success": true|false, "broken_links": [...], "total_links": N, "broken_count": N,
#          "broken_by_category": {...}, "auto_repairable_count": N, "manual_review_count": N,
#          "symmetry_validation": {"enabled": bool, "asymmetric_count": N, "asymmetric_links": [...]},
#          "citation_chains": {"enabled": bool, "total": N, "valid": N, "issues": [...]}}
#
# Exit codes:
#   0 - All validations pass
#   1 - Issues found (broken links, asymmetric links, or chain issues)
#   2 - Invalid arguments
#
# Example:
#   validate-wikilinks.sh --project-path "/path/to/project" --json
#   validate-wikilinks.sh --project-path "/path/to/project" --check-symmetry --json
#   validate-wikilinks.sh --project-path "/path/to/project" --check-chains --json
#   validate-wikilinks.sh --project-path "/path/to/project" --check-symmetry --check-chains --json


# Script metadata
readonly SCRIPT_VERSION="3.2.1"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source entity configuration for directory key resolution (REQUIRED)
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh not found at ${SCRIPT_DIR}/lib/entity-config.sh" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"
DIR_RESEARCH_DIMENSIONS="$(get_directory_by_key "research-dimensions")"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_DOMAIN_CONCEPTS="$(get_directory_by_key "domain-concepts")"
DIR_MEGATRENDS="$(get_directory_by_key "megatrends")"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"
DIR_CITATIONS="$(get_directory_by_key "citations")"
DIR_CLAIMS="$(get_directory_by_key "claims")"
DIR_TRENDS="$(get_directory_by_key "trends")"
DIR_RESEARCH_SYNTHESIS="$(get_directory_by_key "synthesis")"

# Parse arguments
PROJECT_PATH=""
JSON_OUTPUT=false
CHECK_SYMMETRY=false
CHECK_CHAINS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --check-symmetry)
            CHECK_SYMMETRY=true
            shift
            ;;
        --check-chains)
            CHECK_CHAINS=true
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
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --project-path" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --project-path" >&2
        echo "Usage: $SCRIPT_NAME --project-path <path> [--json] [--check-symmetry]" >&2
    fi
    exit 1
fi

# Check project exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Project not found: $PROJECT_PATH" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Project not found: $PROJECT_PATH" >&2
    fi
    exit 1
fi

# Initialize counters
TOTAL_LINKS=0
VALID_COUNT=0
BROKEN_COUNT=0
declare -a BROKEN_LINKS=()

# Category counters
MISSING_DIR_PREFIX=0
MISSING_MD_EXT=0
HASH_MISMATCH=0
ENTITY_TYPE_CONFUSION=0
MISSING_ENTITY=0
TRAILING_BACKSLASH=0
PARTIAL_PATH=0
AUTO_REPAIRABLE=0
MANUAL_REVIEW=0

# Symmetry validation globals
ASYMMETRIC_COUNT=0
ASYMMETRIC_LINK_RESULTS=()

# Citation chain validation globals
CHAIN_TOTAL=0
CHAIN_VALID=0
CHAIN_ISSUES=()

# Relationship registry: maps forward link relationships to expected backlink fields
# Uses function lookup for bash 3.2 compatibility (macOS)
get_expected_backlink_field() {
    local registry_key="$1"
    case "$registry_key" in
        # Claim forward links -> expected backlinks
        "claim:megatrend_ids:megatrend") echo "claim_ids" ;;
        "claim:citation_ids:citation") echo "claim_ids" ;;
        "claim:source_ids:source") echo "claim_ids" ;;
        "claim:finding_ids:finding") echo "claim_ids" ;;
        # Megatrend forward links -> expected backlinks
        "megatrend:dimension_id:dimension") echo "megatrend_ids" ;;
        # Concept forward links -> expected backlinks
        "concept:dimension_id:dimension") echo "concept_ids" ;;
        # Finding forward links -> expected backlinks
        "finding:batch_id:batch") echo "finding_ids" ;;
        "finding:source_id:source") echo "finding_ids" ;;
        # Source forward links -> expected backlinks
        "source:publisher_id:publisher") echo "source_references" ;;
        # Citation forward links -> expected backlinks
        "citation:source_id:source") echo "citation_ids" ;;
        "citation:publisher_id:publisher") echo "citation_ids" ;;
        *) echo "" ;;
    esac
}

# Categorization helper functions

# Extract entity type from filename (e.g., "source-abc123" -> "source")
extract_entity_type() {
    local filename="$1"
    echo "$filename" | sed -E 's/^([0-9]+-)?([a-z]+)-.*/\2/'
}

# Extract entity type from path (e.g., "10-claims/claim-xyz.md" -> "claim")
extract_entity_type_from_path() {
    local path="$1"
    local filename
    filename="$(basename "$path" .md)"
    extract_entity_type "$filename"
}

# Extract hash from filename (e.g., "source-abc123" -> "abc123")
extract_hash() {
    local filename="$1"
    echo "$filename" | sed -E 's/^([0-9]+-)?[a-z]+-(.*)\.md$/\2/'
}

# Get directory prefix for entity type (e.g., "source" -> "07-sources")
# Uses entity-config.sh resolver functions via DIR_* variables
get_entity_directory() {
    local entity_type="$1"
    case "$entity_type" in
        dimension) echo "$DIR_RESEARCH_DIMENSIONS" ;;
        question) echo "$DIR_REFINED_QUESTIONS" ;;
        batch) echo "$DIR_QUERY_BATCHES" ;;
        finding) echo "$DIR_FINDINGS" ;;
        concept) echo "$DIR_DOMAIN_CONCEPTS" ;;
        megatrend) echo "$DIR_MEGATRENDS" ;;
        source) echo "$DIR_SOURCES" ;;
        publisher) echo "$DIR_PUBLISHERS" ;;
        citation) echo "$DIR_CITATIONS" ;;
        claim) echo "$DIR_CLAIMS" ;;
        # Legacy mappings for backward compatibility (hardcoded - no alias support)
        query) echo "01-queries" ;;
        iteration) echo "02-iterations" ;;
        entity) echo "05-entities" ;;
        trend) echo "06-trends" ;;
        author) echo "08-authors" ;;
        publication) echo "09-publications" ;;
        *) echo "" ;;
    esac
}

# Categorize broken wikilink
categorize_broken_link() {
    local link_path="$1"
    local project_path="$2"

    # Remove anchor if present
    local link_no_anchor="${link_path%%#*}"

    # Check if link has directory prefix
    if [[ "$link_no_anchor" == *"/"* ]]; then
        # Has directory - check if adding .md extension would fix it
        if [[ -f "$project_path/$link_no_anchor.md" ]]; then
            echo "missing_md_extension|$project_path/$link_no_anchor.md|[[$link_no_anchor.md]]"
            return
        fi

        # Check for relative parent traversal (../XX-entity/data/...)
        if [[ "$link_no_anchor" == ../* ]]; then
            local stripped="${link_no_anchor#../}"
            if [[ -f "$project_path/$stripped.md" ]] || [[ -f "$project_path/$stripped" ]]; then
                local target="$project_path/$stripped"
                [[ -f "$target.md" ]] && target="$target.md"
                echo "partial_path|$target|[[$stripped]]"
                return
            fi
        fi

        # Check for partial path (data/entity-slug instead of XX-entity/data/entity-slug)
        if [[ "$link_no_anchor" == data/* ]]; then
            local filename="${link_no_anchor#data/}"
            local entity_type
            entity_type="$(extract_entity_type "$filename")"
            local entity_dir
            entity_dir="$(get_entity_directory "$entity_type")"
            if [[ -n "$entity_dir" ]]; then
                local full_path="$entity_dir/data/$filename"
                if [[ -f "$project_path/$full_path.md" ]] || [[ -f "$project_path/$full_path" ]]; then
                    local target="$project_path/$full_path"
                    [[ -f "$target.md" ]] && target="$target.md"
                    echo "partial_path|$target|[[$full_path]]"
                    return
                fi
            fi
        fi
    else
        # No directory - extract potential entity type and hash
        local entity_type
        entity_type="$(extract_entity_type "$link_no_anchor")"
        local entity_dir
        entity_dir="$(get_entity_directory "$entity_type")"

        if [[ -n "$entity_dir" ]]; then
            # Check if adding directory prefix with data/ subdir would fix it
            if [[ -f "$project_path/$entity_dir/${DATA_SUBDIR}/$link_no_anchor.md" ]]; then
                echo "missing_directory_prefix|$project_path/$entity_dir/${DATA_SUBDIR}/$link_no_anchor.md|[[$entity_dir/${DATA_SUBDIR}/$link_no_anchor]]"
                return
            fi

            # Check legacy structure (without data/ subdir)
            if [[ -f "$project_path/$entity_dir/$link_no_anchor.md" ]]; then
                echo "missing_directory_prefix|$project_path/$entity_dir/$link_no_anchor.md|[[$entity_dir/$link_no_anchor]]"
                return
            fi
        fi

        # Check for hash mismatch (same entity type, different hash)
        if [[ -n "$entity_dir" ]] && [[ -d "$project_path/$entity_dir/${DATA_SUBDIR}" ]]; then
            local base_name="${link_no_anchor%.md}"
            local link_hash
            link_hash="$(extract_hash "$base_name.md")"

            # Find files with same entity type but different hash (in data/ subdir)
            while IFS= read -r candidate_file; do
                local candidate_base
                candidate_base="$(basename "$candidate_file" .md)"
                local candidate_hash
                candidate_hash="$(extract_hash "$candidate_file")"

                if ! [[ "$candidate_hash" == "$link_hash" ]]; then
                    echo "hash_mismatch|$candidate_file|manual_review_required"
                    return
                fi
            done < <(find "$project_path/$entity_dir/${DATA_SUBDIR}" -maxdepth 1 -type f -name "${entity_type}-*.md" 2>/dev/null)
        fi

        # Check for entity type confusion (same hash, different entity type)
        local link_hash
        link_hash="$(extract_hash "$link_no_anchor.md")"
        if [[ -n "$link_hash" ]]; then
            while IFS= read -r candidate_file; do
                local candidate_type
                candidate_type="$(extract_entity_type "$(basename "$candidate_file")")"
                if ! [[ "$candidate_type" == "$entity_type" ]]; then
                    echo "entity_type_confusion|$candidate_file|manual_review_required"
                    return
                fi
            done < <(find "$project_path" -type f -name "*-$link_hash.md" ! -path "*/\.metadata/*" 2>/dev/null)
        fi
    fi

    # Check for trailing backslash (common LLM generation artifact)
    if [[ "$link_no_anchor" == *"\\" ]]; then
        local clean_path="${link_no_anchor%\\}"
        # Check if path without backslash would resolve
        if [[ -f "$project_path/$clean_path.md" ]] || [[ -f "$project_path/$clean_path" ]]; then
            echo "trailing_backslash|$project_path/${clean_path}.md|[[${clean_path}]]"
            return
        fi
    fi

    # If none of the above, it's truly missing
    echo "missing_entity||manual_review_required"
}

# =============================================================================
# SYMMETRY VALIDATION FUNCTIONS (v3.0.0)
# =============================================================================

# Extract YAML frontmatter from markdown file
extract_frontmatter() {
    local file="$1"
    # Get content between first two --- markers
    sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | sed '1d;$d'
}

# Extract array field values from frontmatter (handles both top-level and nested)
# Returns wikilink paths (one per line)
extract_wikilinks_from_field() {
    local frontmatter="$1"
    local field="$2"

    # Try to find the field (may be top-level or nested under provenance:)
    local field_line
    field_line="$(echo "$frontmatter" | grep -E "^\s*${field}:" | head -1 || true)"

    if [[ -z "$field_line" ]]; then
        return
    fi

    # Extract wikilinks from the line: [[path]] or [[path|display]]
    # Use || true to prevent set -e from exiting on empty results
    echo "$field_line" | grep -o '\[\[[^]]*\]\]' 2>/dev/null | sed 's/\[\[//g; s/\]\]//g; s/|.*//g' || true
}

# Resolve wikilink path to actual file path
# Handles both new format (NN-entity/data/filename) and legacy format
resolve_wikilink_path() {
    local project_path="$1"
    local wikilink_path="$2"

    # If path already has directory prefix, check if file exists
    if [[ "$wikilink_path" == *"/"* ]]; then
        # Has directory prefix - check directly
        if [[ -f "$project_path/$wikilink_path.md" ]]; then
            echo "$wikilink_path.md"
            return
        elif [[ -f "$project_path/$wikilink_path" ]]; then
            echo "$wikilink_path"
            return
        fi

        # If path doesn't include data/, try adding it
        if [[ ! "$wikilink_path" == *"/data/"* ]] && [[ ! "$wikilink_path" == *"/${DATA_SUBDIR}/"* ]]; then
            local entity_dir="${wikilink_path%%/*}"
            local filename="${wikilink_path#*/}"
            local with_data="$entity_dir/${DATA_SUBDIR}/$filename"
            if [[ -f "$project_path/$with_data.md" ]]; then
                echo "$with_data.md"
                return
            elif [[ -f "$project_path/$with_data" ]]; then
                echo "$with_data"
                return
            fi
        fi
    else
        # No directory prefix - need to search in data/ subdirectory first
        local entity_type
        entity_type="$(extract_entity_type "$wikilink_path")"
        local entity_dir
        entity_dir="$(get_entity_directory "$entity_type")"

        if [[ -n "$entity_dir" ]]; then
            # Try data/ subdirectory first (new structure)
            if [[ -f "$project_path/$entity_dir/${DATA_SUBDIR}/$wikilink_path.md" ]]; then
                echo "$entity_dir/${DATA_SUBDIR}/$wikilink_path.md"
                return
            elif [[ -f "$project_path/$entity_dir/${DATA_SUBDIR}/$wikilink_path" ]]; then
                echo "$entity_dir/${DATA_SUBDIR}/$wikilink_path"
                return
            fi
            # Fallback to legacy structure
            if [[ -f "$project_path/$entity_dir/$wikilink_path.md" ]]; then
                echo "$entity_dir/$wikilink_path.md"
                return
            elif [[ -f "$project_path/$entity_dir/$wikilink_path" ]]; then
                echo "$entity_dir/$wikilink_path"
                return
            fi
        fi
    fi
}

# Check if entity is referenced in a backlink array
check_backlink_contains() {
    local backlinks="$1"
    local source_entity="$2"

    # Extract source entity filename (without path and extension)
    local source_name
    source_name="$(basename "$source_entity" .md)"

    # Check if source appears in backlinks
    while IFS= read -r backlink; do
        [[ -z "$backlink" ]] && continue

        # Normalize backlink for comparison
        local backlink_name
        backlink_name="$(basename "$backlink" .md)"
        backlink_name="${backlink_name%.md}"

        if [[ "$backlink_name" == "$source_name" ]] || [[ "$backlink" == *"$source_name"* ]]; then
            echo "true"
            return
        fi
    done <<< "$backlinks"

    echo "false"
}

# Validate symmetry of all forward/backlink relationships
# Compatible with bash 3.2 (macOS) - no associative arrays
validate_symmetry() {
    local project_path="$1"

    ASYMMETRIC_COUNT=0
    ASYMMETRIC_LINK_RESULTS=()

    # Process entity files directly (bash 3.2 compatible - no array needed)
    while IFS= read -r -d '' entity_file; do
        local entity_path="${entity_file#$project_path/}"

        # Skip non-entity files (README, synthesis docs, etc.)
        if [[ ! "$entity_path" =~ ^[0-9]+-.*/.+\.md$ ]]; then
            continue
        fi

        local frontmatter
        frontmatter="$(extract_frontmatter "$entity_file")"
        local source_type
        source_type="$(extract_entity_type_from_path "$entity_path")"

        # Check all forward link fields based on entity type
        local forward_fields=""
        case "$source_type" in
            claim)
                forward_fields="megatrend_ids citation_ids source_ids finding_ids"
                ;;
            megatrend)
                forward_fields="dimension_id"
                ;;
            concept)
                forward_fields="dimension_id"
                ;;
            finding)
                forward_fields="batch_id source_id"
                ;;
            source)
                forward_fields="publisher_id"
                ;;
            citation)
                forward_fields="source_id publisher_id"
                ;;
        esac

        # Process each forward link field
        for forward_field in $forward_fields; do
            local targets
            targets="$(extract_wikilinks_from_field "$frontmatter" "$forward_field")"

            [[ -z "$targets" ]] && continue

            # Check each target
            while IFS= read -r target_wikilink; do
                [[ -z "$target_wikilink" ]] && continue

                # Resolve target path
                local resolved_target
                resolved_target="$(resolve_wikilink_path "$project_path" "$target_wikilink")"

                if [[ -z "$resolved_target" ]] || [[ ! -f "$project_path/$resolved_target" ]]; then
                    # Target doesn't exist - already caught by orphan check
                    continue
                fi

                # Get target entity type
                local target_type
                target_type="$(extract_entity_type_from_path "$resolved_target")"

                # Look up expected backlink field
                local registry_key="${source_type}:${forward_field}:${target_type}"
                local expected_backlink_field
                expected_backlink_field="$(get_expected_backlink_field "$registry_key")"

                if [[ -z "$expected_backlink_field" ]]; then
                    # Relationship not in registry, skip
                    continue
                fi

                # Get target's frontmatter and check for backlink
                local target_frontmatter
                target_frontmatter="$(extract_frontmatter "$project_path/$resolved_target")"

                local target_backlinks
                target_backlinks="$(extract_wikilinks_from_field "$target_frontmatter" "$expected_backlink_field")"

                # Check if source entity is in target's backlinks
                local found
                found="$(check_backlink_contains "$target_backlinks" "$entity_path")"

                if [[ "$found" == "false" ]]; then
                    # Asymmetric link found!
                    local source_name
                    source_name="$(basename "$entity_path" .md)"
                    local target_name
                    target_name="$(basename "$resolved_target" .md)"

                    local issue_msg="Missing backlink: ${target_name}.${expected_backlink_field} should contain ${source_name}"

                    ASYMMETRIC_LINK_RESULTS+=("$(jq -n \
                        --arg entity "$entity_path" \
                        --arg field "$forward_field" \
                        --arg target "$resolved_target" \
                        --arg issue "$issue_msg" \
                        '{
                            entity: $entity,
                            field: $field,
                            target: $target,
                            issue: $issue
                        }')")

                    ((ASYMMETRIC_COUNT++)) || true
                fi
            done <<< "$targets"
        done
    done < <(find "$project_path" -type f -name "*.md" ! -path "*/\.metadata/*" -print0 2>/dev/null)
}

# =============================================================================
# CITATION CHAIN VALIDATION FUNCTIONS (v3.1.0)
# =============================================================================

# Extract single wikilink field from frontmatter (not array)
extract_single_wikilink() {
    local frontmatter="$1"
    local field="$2"
    # Extract [[path]] from "field: [[path]]" or "field: \"[[path]]\""
    local line
    line="$(echo "$frontmatter" | grep -E "^\s*${field}:" | head -1 || true)"
    [[ -z "$line" ]] && return
    echo "$line" | grep -o '\[\[[^]]*\]\]' 2>/dev/null | head -1 | sed 's/\[\[//; s/\]\]//' | sed 's/|.*//' || true
}

# Validate URL format (must have protocol)
validate_url_format() {
    local url="$1"
    if [[ -z "$url" ]]; then
        echo "empty"
    elif [[ "$url" =~ ^https?://[^[:space:]]+$ ]]; then
        echo "valid"
    else
        echo "invalid"
    fi
}

# Validate all citation chains
validate_citation_chains() {
    local project_path="$1"

    CHAIN_TOTAL=0
    CHAIN_VALID=0
    CHAIN_ISSUES=()

    # Find all citation entities (in data/ subdirectory)
    local citations_data_dir="$project_path/${DIR_CITATIONS}/${DATA_SUBDIR}"
    local citations_dir="$project_path/${DIR_CITATIONS}"

    # Prefer data/ subdirectory, fall back to legacy
    if [[ -d "$citations_data_dir" ]]; then
        citations_dir="$citations_data_dir"
    elif [[ ! -d "$citations_dir" ]]; then
        return
    fi

    while IFS= read -r -d '' citation_file; do
        ((CHAIN_TOTAL++)) || true
        local citation_path="${citation_file#$project_path/}"
        local has_issue=false
        local issue_msg=""
        local resolved_source=""
        local source_frontmatter=""

        # Extract citation frontmatter
        local frontmatter
        frontmatter="$(extract_frontmatter "$citation_file")"

        # Check 1: Citation source_id resolves
        local cit_source_id
        cit_source_id="$(extract_single_wikilink "$frontmatter" "source_id")"
        if [[ -z "$cit_source_id" ]]; then
            has_issue=true
            issue_msg="Missing source_id field"
        else
            resolved_source="$(resolve_wikilink_path "$project_path" "$cit_source_id")"
            if [[ -z "$resolved_source" ]] || [[ ! -f "$project_path/$resolved_source" ]]; then
                has_issue=true
                issue_msg="Source not found: $cit_source_id"
            fi
        fi

        # Check 2: Citation publisher_id resolves
        local cit_publisher_id
        cit_publisher_id="$(extract_single_wikilink "$frontmatter" "publisher_id")"
        if [[ -z "$cit_publisher_id" ]] && [[ "$has_issue" == false ]]; then
            has_issue=true
            issue_msg="Missing publisher_id field"
        elif [[ -n "$cit_publisher_id" ]] && [[ "$has_issue" == false ]]; then
            local resolved_publisher
            resolved_publisher="$(resolve_wikilink_path "$project_path" "$cit_publisher_id")"
            if [[ -z "$resolved_publisher" ]] || [[ ! -f "$project_path/$resolved_publisher" ]]; then
                has_issue=true
                issue_msg="Publisher not found: $cit_publisher_id"
            fi
        fi

        # Check 3: Source publisher_id matches citation publisher_id
        if [[ "$has_issue" == false ]] && [[ -n "$resolved_source" ]]; then
            source_frontmatter="$(extract_frontmatter "$project_path/$resolved_source")"

            local src_publisher_id
            src_publisher_id="$(extract_single_wikilink "$source_frontmatter" "publisher_id")"

            # Normalize paths for comparison (extract entity name only)
            local cit_pub_normalized
            cit_pub_normalized="$(echo "$cit_publisher_id" | sed 's|^.*/||; s/\.md$//')"
            local src_pub_normalized
            src_pub_normalized="$(echo "$src_publisher_id" | sed 's|^.*/||; s/\.md$//')"

            if ! [[ "$cit_pub_normalized" == "$src_pub_normalized" ]]; then
                has_issue=true
                issue_msg="Publisher mismatch: citation references $cit_pub_normalized, source references $src_pub_normalized"
            fi
        fi

        # Check 4: Source URL format
        if [[ "$has_issue" == false ]] && [[ -n "$source_frontmatter" ]]; then
            local src_url
            src_url="$(echo "$source_frontmatter" | grep -E "^url:" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/^"//; s/"$//' | sed "s/^'//; s/'$//" || true)"

            local url_status
            url_status="$(validate_url_format "$src_url")"

            if [[ "$url_status" == "invalid" ]]; then
                has_issue=true
                issue_msg="Invalid source URL format: missing protocol"
            elif [[ "$url_status" == "empty" ]]; then
                has_issue=true
                issue_msg="Source URL is empty"
            fi
        fi

        # Record result
        if [[ "$has_issue" == true ]]; then
            CHAIN_ISSUES+=("$(jq -n \
                --arg citation "$citation_path" \
                --arg issue "$issue_msg" \
                '{citation: $citation, issue: $issue}')")
        else
            ((CHAIN_VALID++)) || true
        fi
    done < <(find "$citations_dir" -type f -name "citation-*.md" -print0 2>/dev/null)
}

# =============================================================================
# MAIN VALIDATION LOGIC
# =============================================================================

# Find all markdown files in entity directories
while IFS= read -r -d '' file; do
    # Extract wikilinks: [[entity-type/filename]] or [[entity-type/filename|display text]]
    while IFS= read -r link; do
        # Remove [[ and ]] brackets
        link_content="${link#\[\[}"
        link_content="${link_content%\]\]}"

        # Remove display text if present (handles both | and \| for table contexts)
        # Using sed with extended regex to properly handle escaped pipes
        # Pattern (\\)?[|] matches optional backslash before pipe
        link_path="$(echo "$link_content" | sed -E 's/(\\)?[|].*//')"

        # Skip empty links
        [[ -z "$link_path" ]] && continue

        ((TOTAL_LINKS++)) || true

        # Remove anchor if present (e.g., [[file#section]] -> [[file]])
        link_path_no_anchor="${link_path%%#*}"

        # Obsidian uses flat namespace (filename only) OR directory paths
        # Try both approaches to find the file
        target_exists=false
        target_file=""

        # Approach 1: Check if it's a path with directory (e.g., [[03-query-batches/data/batch-001]])
        if [[ "$link_path_no_anchor" == *"/"* ]]; then
            # Has directory path - check directly
            target_file="$PROJECT_PATH/$link_path_no_anchor"
            if [[ -f "$target_file" ]] || [[ -f "$target_file.md" ]]; then
                target_exists=true
                [[ -f "$target_file.md" ]] && target_file="$target_file.md"
            fi
        else
            # Approach 2: Flat namespace (filename only) - search across all entity directories
            # Look for the file in any subdirectory
            while IFS= read -r found_file; do
                target_file="$found_file"
                target_exists=true
                break
            done < <(find "$PROJECT_PATH" -type f \( -name "$link_path_no_anchor" -o -name "$link_path_no_anchor.md" \) ! -path "*/\.metadata/*" 2>/dev/null)
        fi

        # Check if target exists
        if [[ "$target_exists" == true ]]; then
            ((VALID_COUNT++)) || true
        else
            ((BROKEN_COUNT++)) || true

            # Categorize the broken link
            IFS='|' read -r error_type suggested_target suggested_fix <<< "$(categorize_broken_link "$link_path" "$PROJECT_PATH")"

            # Update category counters (use || true to prevent set -e exit when counter is 0)
            case "$error_type" in
                missing_directory_prefix)
                    ((MISSING_DIR_PREFIX++)) || true
                    ((AUTO_REPAIRABLE++)) || true
                    ;;
                missing_md_extension)
                    ((MISSING_MD_EXT++)) || true
                    ((AUTO_REPAIRABLE++)) || true
                    ;;
                trailing_backslash)
                    ((TRAILING_BACKSLASH++)) || true
                    ((AUTO_REPAIRABLE++)) || true
                    ;;
                partial_path)
                    ((PARTIAL_PATH++)) || true
                    ((AUTO_REPAIRABLE++)) || true
                    ;;
                hash_mismatch)
                    ((HASH_MISMATCH++)) || true
                    ((MANUAL_REVIEW++)) || true
                    ;;
                entity_type_confusion)
                    ((ENTITY_TYPE_CONFUSION++)) || true
                    ((MANUAL_REVIEW++)) || true
                    ;;
                missing_entity)
                    ((MISSING_ENTITY++)) || true
                    ((MANUAL_REVIEW++)) || true
                    ;;
            esac

            # Determine if auto-repairable
            auto_repairable=false
            if [[ "$error_type" == "missing_directory_prefix" ]] || [[ "$error_type" == "missing_md_extension" ]] || [[ "$error_type" == "trailing_backslash" ]] || [[ "$error_type" == "partial_path" ]]; then
                auto_repairable=true
            fi

            # Build broken link entry
            BROKEN_LINKS+=("$(jq -n \
                --arg source "$file" \
                --arg link "$link_path" \
                --arg target "${suggested_target:-not_found}" \
                --arg error_type "$error_type" \
                --arg suggested_fix "$suggested_fix" \
                --argjson auto_repairable "$auto_repairable" \
                '{
                    source_file: $source,
                    wikilink: $link,
                    target_file: $target,
                    error_type: $error_type,
                    suggested_fix: $suggested_fix,
                    auto_repairable: $auto_repairable
                }')")
        fi
    done < <(grep -o '\[\[[^]]*\]\]' "$file" || true)
done < <(find "$PROJECT_PATH" -type f -name "*.md" ! -path "*/\.metadata/*" -print0)

# Run symmetry validation if requested
if [[ "$CHECK_SYMMETRY" == true ]]; then
    validate_symmetry "$PROJECT_PATH"
fi

# Run citation chain validation if requested
if [[ "$CHECK_CHAINS" == true ]]; then
    validate_citation_chains "$PROJECT_PATH"
fi

# Calculate broken percentage
BROKEN_PERCENTAGE=0
if [[ $TOTAL_LINKS -gt 0 ]]; then
    BROKEN_PERCENTAGE="$(awk "BEGIN {printf \"%.1f\", ($BROKEN_COUNT / $TOTAL_LINKS) * 100}")"
fi

# Check if repair script exists
REPAIR_SCRIPT_PATH="$(dirname "$0")/repair-wikilinks.sh"
REPAIR_AVAILABLE=false
if [[ -f "$REPAIR_SCRIPT_PATH" ]]; then
    REPAIR_AVAILABLE=true
fi

# Generate report
if [[ "$JSON_OUTPUT" == true ]]; then
    # Build broken links array
    BROKEN_JSON="["
    for ((i=0; i<${#BROKEN_LINKS[@]}; i++)); do
        BROKEN_JSON+="${BROKEN_LINKS[$i]}"
        if [[ $i -lt $((${#BROKEN_LINKS[@]} - 1)) ]]; then
            BROKEN_JSON+=","
        fi
    done
    BROKEN_JSON+="]"

    # Build asymmetric links array
    ASYMMETRIC_JSON="["
    for ((i=0; i<${#ASYMMETRIC_LINK_RESULTS[@]}; i++)); do
        ASYMMETRIC_JSON+="${ASYMMETRIC_LINK_RESULTS[$i]}"
        if [[ $i -lt $((${#ASYMMETRIC_LINK_RESULTS[@]} - 1)) ]]; then
            ASYMMETRIC_JSON+=","
        fi
    done
    ASYMMETRIC_JSON+="]"

    # Build chain issues array
    CHAIN_ISSUES_JSON="["
    for ((i=0; i<${#CHAIN_ISSUES[@]}; i++)); do
        CHAIN_ISSUES_JSON+="${CHAIN_ISSUES[$i]}"
        if [[ $i -lt $((${#CHAIN_ISSUES[@]} - 1)) ]]; then
            CHAIN_ISSUES_JSON+=","
        fi
    done
    CHAIN_ISSUES_JSON+="]"

    # Build repair command
    REPAIR_CMD=""
    if [[ "$REPAIR_AVAILABLE" == true ]]; then
        REPAIR_CMD="bash $REPAIR_SCRIPT_PATH --project-path $PROJECT_PATH --auto-repair"
    fi

    # Determine overall success
    overall_success=true
    if [[ $BROKEN_COUNT -gt 0 ]]; then
        overall_success=false
    fi
    if [[ "$CHECK_SYMMETRY" == true ]] && [[ $ASYMMETRIC_COUNT -gt 0 ]]; then
        overall_success=false
    fi
    if [[ "$CHECK_CHAINS" == true ]] && [[ ${#CHAIN_ISSUES[@]} -gt 0 ]]; then
        overall_success=false
    fi

    # Output JSON result
    jq -n \
        --argjson success "$overall_success" \
        --argjson total "$TOTAL_LINKS" \
        --argjson valid "$VALID_COUNT" \
        --argjson broken "$BROKEN_COUNT" \
        --arg broken_pct "$BROKEN_PERCENTAGE" \
        --argjson missing_dir "$MISSING_DIR_PREFIX" \
        --argjson missing_ext "$MISSING_MD_EXT" \
        --argjson trailing_backslash "$TRAILING_BACKSLASH" \
        --argjson partial_path "$PARTIAL_PATH" \
        --argjson hash_mismatch "$HASH_MISMATCH" \
        --argjson type_confusion "$ENTITY_TYPE_CONFUSION" \
        --argjson missing_entity "$MISSING_ENTITY" \
        --argjson auto_repair "$AUTO_REPAIRABLE" \
        --argjson manual_review "$MANUAL_REVIEW" \
        --argjson links "$BROKEN_JSON" \
        --arg repair_cmd "$REPAIR_CMD" \
        --argjson symmetry_enabled "$CHECK_SYMMETRY" \
        --argjson asymmetric_count "$ASYMMETRIC_COUNT" \
        --argjson asymmetric_links "$ASYMMETRIC_JSON" \
        --argjson chains_enabled "$CHECK_CHAINS" \
        --argjson chain_total "$CHAIN_TOTAL" \
        --argjson chain_valid "$CHAIN_VALID" \
        --argjson chain_issues "$CHAIN_ISSUES_JSON" \
        '{
            success: $success,
            total_links: $total,
            valid_count: $valid,
            broken_count: $broken,
            broken_percentage: ($broken_pct | tonumber),
            broken_by_category: {
                missing_directory_prefix: $missing_dir,
                missing_md_extension: $missing_ext,
                trailing_backslash: $trailing_backslash,
                partial_path: $partial_path,
                hash_mismatch: $hash_mismatch,
                entity_type_confusion: $type_confusion,
                missing_entity: $missing_entity
            },
            auto_repairable_count: $auto_repair,
            manual_review_count: $manual_review,
            broken_links: $links,
            repair_command: (if $repair_cmd != "" then $repair_cmd else null end),
            symmetry_validation: {
                enabled: $symmetry_enabled,
                asymmetric_count: $asymmetric_count,
                asymmetric_links: $asymmetric_links
            },
            citation_chains: {
                enabled: $chains_enabled,
                total: $chain_total,
                valid: $chain_valid,
                issues: $chain_issues
            },
            validation_passed: ($broken == 0 and (if $symmetry_enabled then $asymmetric_count == 0 else true end) and (if $chains_enabled then ($chain_issues | length) == 0 else true end))
        }'
else
    echo "Wikilink Validation Report"
    echo "=========================="
    echo ""
    echo "Total wikilinks found: $TOTAL_LINKS"
    echo "Valid links: $VALID_COUNT"
    echo "Broken links: $BROKEN_COUNT ($BROKEN_PERCENTAGE%)"
    echo ""

    if [[ $BROKEN_COUNT -eq 0 ]]; then
        echo "✓ All wikilinks are valid"
    else
        echo "Broken Links by Category:"
        echo "  - Missing directory prefix: $MISSING_DIR_PREFIX"
        echo "  - Missing .md extension: $MISSING_MD_EXT"
        echo "  - Trailing backslash: $TRAILING_BACKSLASH"
        echo "  - Partial path: $PARTIAL_PATH"
        echo "  - Hash mismatch: $HASH_MISMATCH"
        echo "  - Entity type confusion: $ENTITY_TYPE_CONFUSION"
        echo "  - Missing entity: $MISSING_ENTITY"
        echo ""
        echo "Repairability:"
        echo "  - Auto-repairable: $AUTO_REPAIRABLE"
        echo "  - Require manual review: $MANUAL_REVIEW"
        echo ""

        # Show sample broken links (up to 10)
        echo "Sample Broken Links:"
        count=0
        for broken in "${BROKEN_LINKS[@]}"; do
            if [[ $count -ge 10 ]]; then
                echo "  ... (showing first 10 of $BROKEN_COUNT broken links)"
                break
            fi

            source_file="$(echo "$broken" | jq -r '.source_file')"
            wikilink="$(echo "$broken" | jq -r '.wikilink')"
            error_type="$(echo "$broken" | jq -r '.error_type')"
            suggested_fix="$(echo "$broken" | jq -r '.suggested_fix')"

            echo "  - $wikilink"
            echo "    Source: $source_file"
            echo "    Error: $error_type"
            if ! [[ "$suggested_fix" == "manual_review_required" ]] && ! [[ "$suggested_fix" == "null" ]]; then
                echo "    Fix: $suggested_fix"
            fi
            echo ""

            ((count++))
        done

        # Interactive repair prompt (only if not in JSON mode and repair script available)
        if [[ "$REPAIR_AVAILABLE" == true ]] && [[ -t 0 ]]; then
            echo ""
            echo "Automated repair available!"
            echo "Run: bash $REPAIR_SCRIPT_PATH --project-path $PROJECT_PATH --auto-repair"
            echo ""
            read -p "Run automated repair now? (Y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                bash "$REPAIR_SCRIPT_PATH" --project-path "$PROJECT_PATH" --auto-repair
            fi
        fi
    fi

    # Symmetry validation report
    if [[ "$CHECK_SYMMETRY" == true ]]; then
        echo ""
        echo "Symmetry Validation"
        echo "==================="
        echo ""

        if [[ $ASYMMETRIC_COUNT -eq 0 ]]; then
            echo "✓ All forward/backlink relationships are symmetric"
        else
            echo "⚠ Found $ASYMMETRIC_COUNT asymmetric link(s)"
            echo ""

            # Show sample asymmetric links (up to 10)
            count=0
            for asymmetric in "${ASYMMETRIC_LINK_RESULTS[@]}"; do
                if [[ $count -ge 10 ]]; then
                    echo "  ... (showing first 10 of $ASYMMETRIC_COUNT asymmetric links)"
                    break
                fi

                entity="$(echo "$asymmetric" | jq -r '.entity')"
                field="$(echo "$asymmetric" | jq -r '.field')"
                target="$(echo "$asymmetric" | jq -r '.target')"
                issue="$(echo "$asymmetric" | jq -r '.issue')"

                echo "  - Entity: $entity"
                echo "    Field: $field"
                echo "    Target: $target"
                echo "    Issue: $issue"
                echo ""

                ((count++))
            done
        fi
    fi

    # Citation chain validation report
    if [[ "$CHECK_CHAINS" == true ]]; then
        echo ""
        echo "Citation Chain Validation"
        echo "========================="
        echo ""

        if [[ ${#CHAIN_ISSUES[@]} -eq 0 ]]; then
            if [[ $CHAIN_TOTAL -eq 0 ]]; then
                echo "✓ No citation entities found to validate"
            else
                echo "✓ All $CHAIN_TOTAL citation chains are valid"
            fi
        else
            echo "⚠ Found ${#CHAIN_ISSUES[@]} citation chain issue(s) out of $CHAIN_TOTAL total"
            echo ""

            # Show sample chain issues (up to 10)
            count=0
            for chain_issue in "${CHAIN_ISSUES[@]}"; do
                if [[ $count -ge 10 ]]; then
                    echo "  ... (showing first 10 of ${#CHAIN_ISSUES[@]} chain issues)"
                    break
                fi

                citation="$(echo "$chain_issue" | jq -r '.citation')"
                issue="$(echo "$chain_issue" | jq -r '.issue')"

                echo "  - Citation: $citation"
                echo "    Issue: $issue"
                echo ""

                ((count++))
            done
        fi
    fi
fi

# Exit with appropriate code
if [[ $BROKEN_COUNT -eq 0 ]]; then
    if [[ "$CHECK_SYMMETRY" == true ]] && [[ $ASYMMETRIC_COUNT -gt 0 ]]; then
        exit 1
    fi
    if [[ "$CHECK_CHAINS" == true ]] && [[ ${#CHAIN_ISSUES[@]} -gt 0 ]]; then
        exit 1
    fi
    exit 0
else
    exit 1
fi
