#!/usr/bin/env bash
set -euo pipefail
# discover-questions-by-dimension.sh
# Version: 1.0.0
# Purpose: Discover refined questions grouped by dimension for Phase 3 orchestration
# Category: extractors
#
# Usage: discover-questions-by-dimension.sh --project-path <path> [--json]
#
# Arguments:
#   --project-path <path>  Research project directory (required)
#   --json                 Output JSON format (default, for compatibility)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "source": "dimension-plan-batch" | "frontmatter-scan",
#     "data": {
#       "project_path": string,
#       "total_dimensions": number,
#       "total_questions": number,
#       "dimensions": {
#         "dimension-entity-id": {
#           "dimension_number": number,
#           "title": string,
#           "question_count": number,
#           "questions": ["/path/to/question-file.md", ...]
#         }
#       },
#       "execution_batches": [
#         {
#           "batch_number": 1,
#           "batch_name": "Dimension A + Dimension B",
#           "dimension_count": 2,
#           "dimension_ids": ["dimension-a-hash", "dimension-b-hash"],
#           "question_count": 26,
#           "question_paths": ["/path/to/q1.md", ...]
#         }
#       ],
#       "batching": {
#         "strategy": "question-count-based",
#         "target_min": 15,
#         "target_max": 20,
#         "total_batches": 2
#       }
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error (no questions found)
#   2 - Invalid arguments
#   3 - Directory not found
#
# Example:
#   discover-questions-by-dimension.sh --project-path ~/research/portfolio-xyz


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Export CLAUDE_PLUGIN_ROOT for entity-config.sh (scripts/ -> plugin root)
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "${SCRIPT_DIR}")}"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_RESEARCH_DIMENSIONS="$(get_directory_by_key "research-dimensions")"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"

# ============================================================================
# ERROR HANDLER
# ============================================================================

error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# ============================================================================
# FRONTMATTER EXTRACTION (for fallback mode)
# ============================================================================

extract_frontmatter_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (in_fm) exit; in_fm=!in_fm; next }
        in_fm && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            gsub(/^["'\''"]|["'\''""]$/, "")
            print
            exit
        }
    ' "$file"
}

# Extract dimension ID from wikilink format
# Input: "[[${DIR_RESEARCH_DIMENSIONS}/data/dimension-slug-hash8]]"
# Output: "dimension-slug-hash8"
extract_dimension_id_from_wikilink() {
    local wikilink="$1"
    echo "$wikilink" | sed "s/.*\\[\\[${DIR_RESEARCH_DIMENSIONS}\\///" | sed 's/\]\].*//'
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    local project_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="${2:-}"
                shift 2
                ;;
            --json)
                # Always JSON output, this flag is for compatibility
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3

    local questions_dir="$project_path/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}"
    [[ -d "$questions_dir" ]] || error_json "Questions directory not found: $questions_dir" 3

    local batch_file="$project_path/.metadata/dimension-plan-batch.json"
    local source_type=""
    local result_json=""

    # ========================================================================
    # PRIMARY SOURCE: dimension-plan-batch.json
    # ========================================================================

    if [[ -f "$batch_file" ]] && jq -e '.' "$batch_file" > /dev/null 2>&1; then
        source_type="dimension-plan-batch"

        # Build dimensions object using jq
        result_json="$(jq -r --arg project_path "$project_path" --arg dir_questions "$DIR_REFINED_QUESTIONS" --arg data_subdir "$DATA_SUBDIR" '
            # Initialize output structure
            {
                success: true,
                source: "dimension-plan-batch",
                data: {
                    project_path: $project_path,
                    total_dimensions: (.metadata.total_dimensions // .dimensions | length),
                    total_questions: (.metadata.total_questions // 0),
                    dimensions: (
                        reduce .dimensions[] as $dim (
                            {};
                            . + {
                                ($dim.dimension.entity_id): {
                                    dimension_number: $dim.dimension_number,
                                    title: $dim.dimension.title,
                                    question_count: ($dim.questions | length),
                                    questions: [
                                        $dim.questions[] |
                                        "\($project_path)/\($dir_questions)/\($data_subdir)/\(.entity_id).md"
                                    ]
                                }
                            }
                        )
                    )
                }
            }
        ' "$batch_file")"

        # Verify question files exist and count actual questions
        local verified_json
        verified_json="$(echo "$result_json" | jq --arg project_path "$project_path" '
            .data.dimensions |= with_entries(
                .value.questions |= map(select(. as $path | $path | test("^" + $project_path)))
            ) |
            .data.total_questions = ([.data.dimensions[].questions | length] | add // 0)
        ')"

        # Check for missing files and adjust counts
        local missing_files=0
        local total_questions=0
        local verified_dimensions="{}"

        for dim_id in $(echo "$result_json" | jq -r '.data.dimensions | keys[]'); do
            local dim_data
            dim_data="$(echo "$result_json" | jq -c --arg dim_id "$dim_id" '.data.dimensions[$dim_id]')"

            local dim_number
            dim_number="$(echo "$dim_data" | jq -r '.dimension_number')"

            local dim_title
            dim_title="$(echo "$dim_data" | jq -r '.title')"

            local existing_questions="[]"
            local question_count=0

            while IFS= read -r question_path; do
                if [[ -f "$question_path" ]]; then
                    existing_questions="$(echo "$existing_questions" | jq --arg q "$question_path" '. + [$q]')"
                    ((question_count++)) || true
                else
                    ((missing_files++)) || true
                fi
            done < <(echo "$dim_data" | jq -r '.questions[]' 2>/dev/null || true)

            ((total_questions += question_count)) || true

            # Build dimension entry
            local dim_entry
            dim_entry="$(jq -n \
                --argjson num "$dim_number" \
                --arg title "$dim_title" \
                --argjson count "$question_count" \
                --argjson questions "$existing_questions" \
                '{
                    dimension_number: $num,
                    title: $title,
                    question_count: $count,
                    questions: $questions
                }')"

            verified_dimensions="$(echo "$verified_dimensions" | jq --arg dim_id "$dim_id" --argjson dim_entry "$dim_entry" '. + {($dim_id): $dim_entry}')"
        done

        local total_dimensions
        total_dimensions="$(echo "$verified_dimensions" | jq 'keys | length')"

        # Build final output
        result_json="$(jq -n \
            --arg source "$source_type" \
            --arg project_path "$project_path" \
            --argjson total_dimensions "$total_dimensions" \
            --argjson total_questions "$total_questions" \
            --argjson dimensions "$verified_dimensions" \
            '{
                success: true,
                source: $source,
                data: {
                    project_path: $project_path,
                    total_dimensions: $total_dimensions,
                    total_questions: $total_questions,
                    dimensions: $dimensions
                }
            }')"

        if [[ $missing_files -gt 0 ]]; then
            result_json="$(echo "$result_json" | jq --argjson missing "$missing_files" '.data.missing_files = $missing')"
        fi

    else
        # ====================================================================
        # FALLBACK: Scan ${DIR_REFINED_QUESTIONS}/ directory
        # ====================================================================

        source_type="frontmatter-scan"

        local dimensions_json="{}"
        local total_questions=0

        # Scan all question files
        while IFS= read -r question_file; do
            [[ -f "$question_file" ]] || continue

            # Extract dimension_ref from frontmatter
            local dimension_ref
            dimension_ref="$(extract_frontmatter_field "$question_file" "dimension_ref")"
            [[ -n "$dimension_ref" ]] || continue

            # Extract dimension ID from wikilink
            local dim_id
            dim_id="$(extract_dimension_id_from_wikilink "$dimension_ref")"
            [[ -n "$dim_id" ]] || continue

            ((total_questions++)) || true

            # Check if dimension exists in our accumulator
            local dim_exists
            dim_exists="$(echo "$dimensions_json" | jq --arg dim_id "$dim_id" 'has($dim_id)')"

            if [[ "$dim_exists" == "true" ]]; then
                # Add question to existing dimension
                dimensions_json="$(echo "$dimensions_json" | jq \
                    --arg dim_id "$dim_id" \
                    --arg q_path "$question_file" \
                    '.[$dim_id].questions += [$q_path] | .[$dim_id].question_count += 1')"
            else
                # Create new dimension entry
                # Try to get dimension title from dimension file
                local dim_file="$project_path/${DIR_RESEARCH_DIMENSIONS}/${DATA_SUBDIR}/${dim_id}.md"
                local dim_title="$dim_id"
                local dim_number=0

                if [[ -f "$dim_file" ]]; then
                    local extracted_title
                    extracted_title="$(extract_frontmatter_field "$dim_file" "dc:title")"
                    [[ -n "$extracted_title" ]] && dim_title="$extracted_title"

                    # Try to extract dimension number from tags
                    local dim_tag
                    dim_tag="$(grep -o 'dimension-[0-9]\+' "$dim_file" 2>/dev/null | head -1 || true)"
                    if [[ -n "$dim_tag" ]]; then
                        dim_number="$(echo "$dim_tag" | sed 's/dimension-//')"
                    fi
                fi

                local new_dim_entry
                new_dim_entry="$(jq -n \
                    --argjson num "$dim_number" \
                    --arg title "$dim_title" \
                    --argjson count 1 \
                    --arg q_path "$question_file" \
                    '{
                        dimension_number: $num,
                        title: $title,
                        question_count: $count,
                        questions: [$q_path]
                    }')"

                dimensions_json="$(echo "$dimensions_json" | jq --arg dim_id "$dim_id" --argjson entry "$new_dim_entry" '. + {($dim_id): $entry}')"
            fi
        done < <(find "$questions_dir" -name "question-*.md" -type f 2>/dev/null | LC_ALL=C sort)

        local total_dimensions
        total_dimensions="$(echo "$dimensions_json" | jq 'keys | length')"

        # Build final output
        result_json="$(jq -n \
            --arg source "$source_type" \
            --arg project_path "$project_path" \
            --argjson total_dimensions "$total_dimensions" \
            --argjson total_questions "$total_questions" \
            --argjson dimensions "$dimensions_json" \
            '{
                success: true,
                source: $source,
                data: {
                    project_path: $project_path,
                    total_dimensions: $total_dimensions,
                    total_questions: $total_questions,
                    dimensions: $dimensions
                }
            }')"
    fi

    # ========================================================================
    # BATCH CALCULATION (universal 15-20 question batching)
    # ========================================================================

    local TARGET_MIN=15
    local TARGET_MAX=20
    local OVERAGE_ALLOWANCE=2  # 10% of TARGET_MAX (allows up to 22 when merging)

    # Sort dimensions by question_count descending, then pack into batches
    local batches_json
    batches_json="$(echo "$result_json" | jq \
        --argjson target_min "$TARGET_MIN" \
        --argjson target_max "$TARGET_MAX" \
        --argjson overage "$OVERAGE_ALLOWANCE" '
        # Sort dimensions by question_count (largest first)
        .data.dimensions | to_entries | sort_by(-.value.question_count) |

        # Pack dimensions into batches using reduce
        reduce .[] as $dim (
            {batches: [], current: {dims: [], dim_ids: [], paths: [], count: 0}};
            # Case 1: Dimension fits within current batch
            if (.current.count + $dim.value.question_count) <= $target_max then
                .current.dims += [$dim.value.title] |
                .current.dim_ids += [$dim.key] |
                .current.paths += $dim.value.questions |
                .current.count += $dim.value.question_count
            # Case 2: Oversized dimension (exceeds target_max + overage) - dedicated batch with warning
            elif $dim.value.question_count > ($target_max + $overage) then
                (if .current.count > 0 then
                    .batches += [{
                        batch_number: ((.batches | length) + 1),
                        batch_name: (.current.dims | join(" + ")),
                        dimension_count: (.current.dims | length),
                        dimension_ids: .current.dim_ids,
                        question_count: .current.count,
                        question_paths: .current.paths
                    }]
                else . end) |
                .batches += [{
                    batch_number: ((.batches | length) + 1),
                    batch_name: $dim.value.title,
                    dimension_count: 1,
                    dimension_ids: [$dim.key],
                    question_count: $dim.value.question_count,
                    question_paths: $dim.value.questions,
                    _warning: "oversized_dimension_exceeds_target"
                }] |
                .current = {dims: [], dim_ids: [], paths: [], count: 0}
            # Case 3: Start new batch with this dimension
            else
                (if .current.count > 0 then
                    .batches += [{
                        batch_number: ((.batches | length) + 1),
                        batch_name: (.current.dims | join(" + ")),
                        dimension_count: (.current.dims | length),
                        dimension_ids: .current.dim_ids,
                        question_count: .current.count,
                        question_paths: .current.paths
                    }]
                else . end) |
                .current = {
                    dims: [$dim.value.title],
                    dim_ids: [$dim.key],
                    paths: $dim.value.questions,
                    count: $dim.value.question_count
                }
            end
        ) |

        # Finalize last batch
        (if .current.count > 0 then
            .batches += [{
                batch_number: ((.batches | length) + 1),
                batch_name: (.current.dims | join(" + ")),
                dimension_count: (.current.dims | length),
                dimension_ids: .current.dim_ids,
                question_count: .current.count,
                question_paths: .current.paths
            }]
        else . end) |

        # Optional: Merge small trailing batch if it would fit within overage
        (if (.batches | length) > 1 and (.batches[-1].question_count < $target_min) then
            if ((.batches[-2].question_count + .batches[-1].question_count) <= ($target_max + $overage)) then
                .batches[-2].dimension_ids += .batches[-1].dimension_ids |
                .batches[-2].question_paths += .batches[-1].question_paths |
                .batches[-2].question_count += .batches[-1].question_count |
                .batches[-2].dimension_count += .batches[-1].dimension_count |
                .batches[-2].batch_name = ((.batches[-2].batch_name | split(" + ")) + (.batches[-1].batch_name | split(" + ")) | join(" + ")) |
                del(.batches[-1])
            else . end
        else . end) |

        .batches
    ')"

    # Add batching results to output
    result_json="$(echo "$result_json" | jq \
        --argjson batches "$batches_json" \
        --argjson target_min "$TARGET_MIN" \
        --argjson target_max "$TARGET_MAX" '
        .data.execution_batches = $batches |
        .data.batching = {
            strategy: "question-count-based",
            target_min: $target_min,
            target_max: $target_max,
            total_batches: ($batches | length)
        }
    ')"

    # ========================================================================
    # VALIDATION
    # ========================================================================

    local final_total_questions
    final_total_questions="$(echo "$result_json" | jq -r '.data.total_questions')"

    if [[ "$final_total_questions" -eq 0 ]]; then
        error_json "No questions discovered in $questions_dir" 1
    fi

    # Validate batch sizes (warn if any batch exceeds TARGET_MAX + OVERAGE)
    local max_allowed=$((TARGET_MAX + OVERAGE_ALLOWANCE))
    local oversized_batches
    oversized_batches="$(echo "$batches_json" | jq --argjson max "$max_allowed" \
        '[.[] | select(.question_count > $max) | {batch: .batch_number, count: .question_count}]')"

    if [[ $(echo "$oversized_batches" | jq 'length') -gt 0 ]]; then
        echo "WARNING: Oversized batches detected (>${max_allowed} questions): $oversized_batches" >&2
        # Add warnings to batching metadata
        result_json="$(echo "$result_json" | jq --argjson warnings "$oversized_batches" \
            '.data.batching.warnings = $warnings')"
    fi

    # Output result
    echo "$result_json"
}

main "$@"
