#!/usr/bin/env bash
set -euo pipefail
# unpack-dimension-plan-batch.sh - Unpack batched dimension plan JSON to individual markdown entities
#
# Version: 1.3.0
# Purpose: Parse batched dimension plan JSON containing multiple dimensions and create all markdown files
# v1.3.0: Add project_language support for README localization (de, nl, fr, en)
# Architecture: LLM-Control pattern with JSON I/O, optimized for batch processing
# Compatibility: bash 3.2+
#
# Exit codes:
#   0 - Success
#   2 - Invalid arguments or missing required files/paths
#   3 - Schema validation failed
#   4 - Question count mismatch


# ============================================================================
# ARGUMENT PARSING
# ============================================================================

json_file=""
project_path=""
validate_schema="true"
json_output="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json-file)
      json_file="$2"
      shift 2
      ;;
    --project-path)
      project_path="$2"
      shift 2
      ;;
    --validate-schema)
      validate_schema="$2"
      shift 2
      ;;
    --json)
      json_output="true"
      shift
      ;;
    *)
      echo "{\"success\": false, \"error\": \"Unknown argument: $1\"}" >&2
      exit 2
      ;;
  esac
done

# Validate required arguments
if [[ -z "$json_file" ]] || [[ -z "$project_path" ]]; then
  echo "{\"success\": false, \"error\": \"Required arguments: --json-file, --project-path\"}" >&2
  exit 2
fi

# Validate file exists
if [[ ! -f "$json_file" ]]; then
  echo "{\"success\": false, \"error\": \"JSON file not found: $json_file\"}" >&2
  exit 2
fi

# Validate project path exists
if [[ ! -d "$project_path" ]]; then
  echo "{\"success\": false, \"error\": \"Project path not found: $project_path\"}" >&2
  exit 2
fi

# ============================================================================
# SOURCE CENTRALIZED CONFIG
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract YAML frontmatter from markdown file
# Usage: extract_frontmatter <file_path>
# Returns: YAML content between --- delimiters (excluding the delimiters)
extract_frontmatter() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Build workspace-aware fallback wikilink when generate-wikilink.sh fails
# Usage: build_fallback_wikilink <entity_dir> <filename> [display_name]
# Returns: Wikilink with workspace prefix if PROJECT_AGENTS_OPS_ROOT is set
# Fix v1.2.0: Prevents broken wikilinks in multi-project Obsidian vaults
build_fallback_wikilink() {
  local entity_dir="$1"
  local filename="$2"
  local display_name="${3:-}"

  # Detect workspace prefix from project_path
  local workspace_prefix=""
  if [[ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]]; then
    workspace_prefix="${project_path#"$PROJECT_AGENTS_OPS_ROOT"/}"
    if [[ "$workspace_prefix" == "$project_path" ]]; then
      workspace_prefix=""
    fi
  fi

  local path="${entity_dir}/${DATA_SUBDIR}/${filename}"
  if [[ -n "$workspace_prefix" ]]; then
    path="${workspace_prefix}/${path}"
  fi

  if [[ -n "$display_name" ]]; then
    echo "[[$path|$display_name]]"
  else
    echo "[[$path]]"
  fi
}

# Get translated label for README content
# Usage: get_label <key> <language>
# Returns: Translated string for the given key
get_label() {
  local key="$1"
  local lang="${2:-en}"

  case "$lang" in
    de)
      case "$key" in
        "research_dimensions_overview") echo "Übersicht Forschungsdimensionen" ;;
        "refined_questions_overview") echo "Übersicht Verfeinerte Fragen" ;;
        "initial_question") echo "Ausgangsfrage" ;;
        "research_dimensions") echo "Forschungsdimensionen" ;;
        "refined_questions") echo "Verfeinerte Fragen" ;;
        "hierarchical_view_dimensions") echo "Hierarchische Ansicht der Forschungsdimensionen, abgeleitet von der Ausgangsfrage." ;;
        "hierarchical_view_questions") echo "Hierarchische Ansicht der verfeinerten Fragen, geordnet nach Forschungsdimension." ;;
        "starting_point") echo "Der Ausgangspunkt für dieses Forschungsprojekt." ;;
        "provenance_chain") echo "Herkunftskette" ;;
        "statistics") echo "Statistiken" ;;
        "metric") echo "Metrik" ;;
        "value") echo "Wert" ;;
        "entity_index") echo "Entitätsindex" ;;
        "type") echo "Typ" ;;
        "entity") echo "Entität" ;;
        "link") echo "Link" ;;
        "dimension") echo "Dimension" ;;
        "question") echo "Frage" ;;
        "dimensions") echo "Dimensionen" ;;
        "questions") echo "Fragen" ;;
        "generated_by") echo "Erstellt von" ;;
        "research_question") echo "Forschungsfrage" ;;
        "derived_dimensions") echo "Abgeleitete Dimensionen" ;;
        "total_questions") echo "Gesamtanzahl Fragen" ;;
        *) echo "$key" ;;
      esac
      ;;
    nl)
      case "$key" in
        "research_dimensions_overview") echo "Overzicht Onderzoeksdimensies" ;;
        "refined_questions_overview") echo "Overzicht Verfijnde Vragen" ;;
        "initial_question") echo "Initiële Vraag" ;;
        "research_dimensions") echo "Onderzoeksdimensies" ;;
        "refined_questions") echo "Verfijnde Vragen" ;;
        "hierarchical_view_dimensions") echo "Hiërarchische weergave van onderzoeksdimensies afgeleid van de initiële vraag." ;;
        "hierarchical_view_questions") echo "Hiërarchische weergave van verfijnde vragen geordend per onderzoeksdimensie." ;;
        "starting_point") echo "Het startpunt voor dit onderzoeksproject." ;;
        "provenance_chain") echo "Herkomst keten" ;;
        "statistics") echo "Statistieken" ;;
        "metric") echo "Metriek" ;;
        "value") echo "Waarde" ;;
        "entity_index") echo "Entiteitsindex" ;;
        "type") echo "Type" ;;
        "entity") echo "Entiteit" ;;
        "link") echo "Link" ;;
        "dimension") echo "Dimensie" ;;
        "question") echo "Vraag" ;;
        "dimensions") echo "Dimensies" ;;
        "questions") echo "Vragen" ;;
        "generated_by") echo "Gegenereerd door" ;;
        "research_question") echo "Onderzoeksvraag" ;;
        "derived_dimensions") echo "Afgeleide Dimensies" ;;
        "total_questions") echo "Totaal Vragen" ;;
        *) echo "$key" ;;
      esac
      ;;
    fr)
      case "$key" in
        "research_dimensions_overview") echo "Aperçu des Dimensions de Recherche" ;;
        "refined_questions_overview") echo "Aperçu des Questions Affinées" ;;
        "initial_question") echo "Question Initiale" ;;
        "research_dimensions") echo "Dimensions de Recherche" ;;
        "refined_questions") echo "Questions Affinées" ;;
        "hierarchical_view_dimensions") echo "Vue hiérarchique des dimensions de recherche dérivées de la question initiale." ;;
        "hierarchical_view_questions") echo "Vue hiérarchique des questions affinées organisées par dimension de recherche." ;;
        "starting_point") echo "Le point de départ de ce projet de recherche." ;;
        "provenance_chain") echo "Chaîne de Provenance" ;;
        "statistics") echo "Statistiques" ;;
        "metric") echo "Métrique" ;;
        "value") echo "Valeur" ;;
        "entity_index") echo "Index des Entités" ;;
        "type") echo "Type" ;;
        "entity") echo "Entité" ;;
        "link") echo "Lien" ;;
        "dimension") echo "Dimension" ;;
        "question") echo "Question" ;;
        "dimensions") echo "Dimensions" ;;
        "questions") echo "Questions" ;;
        "generated_by") echo "Généré par" ;;
        "research_question") echo "Question de Recherche" ;;
        "derived_dimensions") echo "Dimensions Dérivées" ;;
        "total_questions") echo "Total Questions" ;;
        *) echo "$key" ;;
      esac
      ;;
    *) # English (default)
      case "$key" in
        "research_dimensions_overview") echo "Research Dimensions Overview" ;;
        "refined_questions_overview") echo "Refined Questions Overview" ;;
        "initial_question") echo "Initial Question" ;;
        "research_dimensions") echo "Research Dimensions" ;;
        "refined_questions") echo "Refined Questions" ;;
        "hierarchical_view_dimensions") echo "Hierarchical view of research dimensions derived from the initial question." ;;
        "hierarchical_view_questions") echo "Hierarchical view of refined questions organized by research dimension." ;;
        "starting_point") echo "The starting point for this research project." ;;
        "provenance_chain") echo "Provenance Chain" ;;
        "statistics") echo "Statistics" ;;
        "metric") echo "Metric" ;;
        "value") echo "Value" ;;
        "entity_index") echo "Entity Index" ;;
        "type") echo "Type" ;;
        "entity") echo "Entity" ;;
        "link") echo "Link" ;;
        "dimension") echo "Dimension" ;;
        "question") echo "Question" ;;
        "dimensions") echo "Dimensions" ;;
        "questions") echo "Questions" ;;
        "generated_by") echo "Generated by" ;;
        "research_question") echo "Research Question" ;;
        "derived_dimensions") echo "Derived Dimensions" ;;
        "total_questions") echo "Total Questions" ;;
        *) echo "$key" ;;
      esac
      ;;
  esac
}

# ============================================================================
# SCHEMA VALIDATION
# ============================================================================

schema_valid="true"

if [[ "$validate_schema" == "true" ]]; then
  # Basic JSON syntax validation
  if ! jq empty "$json_file" 2>/dev/null; then
    echo "{\"success\": false, \"error\": \"Invalid JSON syntax\"}" >&2
    exit 1
  fi

  # Validate batch schema structure
  required_keys=("metadata" "dimensions")
  for key in "${required_keys[@]}"; do
    if ! jq -e ".$key" "$json_file" >/dev/null 2>&1; then
      echo "{\"success\": false, \"error\": \"Missing required key: $key\"}" >&2
      exit 1
    fi
  done

  # Validate metadata fields
  metadata_keys=("project_language" "initial_question_entity_id" "total_dimensions" "total_questions")
  for key in "${metadata_keys[@]}"; do
    if ! jq -e ".metadata.$key" "$json_file" >/dev/null 2>&1; then
      echo "{\"success\": false, \"error\": \"Missing metadata field: $key\"}" >&2
      exit 1
    fi
  done

  # Validate dimensions is non-empty array
  dimension_count="$(jq -r '.dimensions | length' "$json_file")"
  if [[ "$dimension_count" -eq 0 ]]; then
    echo "{\"success\": false, \"error\": \"Dimensions array is empty\"}" >&2
    exit 1
  fi
fi

# ============================================================================
# PARSE BATCH METADATA
# ============================================================================

project_language="$(jq -r '.metadata.project_language' "$json_file")"
initial_question_entity_id="$(jq -r '.metadata.initial_question_entity_id' "$json_file")"
total_dimensions="$(jq -r '.metadata.total_dimensions' "$json_file")"
total_questions="$(jq -r '.metadata.total_questions' "$json_file")"

# Timestamp for all entities
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"

# Create output directories (entities go in /data/ subdirectory)
dimensions_base_dir="$project_path/01-research-dimensions"
questions_base_dir="$project_path/02-refined-questions"
dimensions_dir="$dimensions_base_dir/$DATA_SUBDIR"
questions_dir="$questions_base_dir/$DATA_SUBDIR"
mkdir -p "$dimensions_dir" "$questions_dir"

# Wikilink script path (with SCRIPT_DIR fallback for when CLAUDE_PLUGIN_ROOT is not set)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  WIKILINK_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/generate-wikilink.sh"
else
  WIKILINK_SCRIPT="${SCRIPT_DIR}/../../../scripts/generate-wikilink.sh"
fi

# Generate wikilink for initial question (shared across all dimensions)
# Fix v1.2.0: Use workspace-aware fallback for multi-project setups
INITIAL_QUESTION_WIKILINK="$(build_fallback_wikilink "00-initial-question" "$initial_question_entity_id")"
if [[ -x "$WIKILINK_SCRIPT" ]]; then
  if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
    --project-path "$project_path" \
    --entity-dir "00-initial-question" \
    --filename "$initial_question_entity_id" 2>/dev/null)"; then
    if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
      INITIAL_QUESTION_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
    fi
  fi
fi

# ============================================================================
# TRACKING ARRAYS
# ============================================================================

all_dimension_files=()
all_question_files=()
actual_total_dimensions=0
actual_total_questions=0
dimension_summary_rows=""

# ============================================================================
# PROCESS EACH DIMENSION
# ============================================================================

for dim_idx in $(seq 0 $((total_dimensions - 1))); do
  # Extract dimension-level data
  dimension_number="$(jq -r ".dimensions[$dim_idx].dimension_number" "$json_file")"
  dimension_slug="$(jq -r ".dimensions[$dim_idx].dimension_slug" "$json_file")"

  dimension_title="$(jq -r ".dimensions[$dim_idx].dimension.title" "$json_file")"
  dimension_entity_id="$(jq -r ".dimensions[$dim_idx].dimension.entity_id" "$json_file")"
  dimension_description="$(jq -r ".dimensions[$dim_idx].dimension.description" "$json_file")"
  dimension_scope="$(jq -r ".dimensions[$dim_idx].dimension.scope" "$json_file")"
  dimension_rationale="$(jq -r ".dimensions[$dim_idx].dimension.rationale" "$json_file")"
  planned_question_count="$(jq -r ".dimensions[$dim_idx].dimension.question_count" "$json_file")"

  # Extract hash from dimension entity_id (last 8 alphanumeric chars)
  dimension_hash="$(echo "$dimension_entity_id" | grep -o '[a-z0-9]\{8\}$' || echo "")"

  # Generate dimension wikilink
  # Fix v1.2.0: Use workspace-aware fallback for multi-project setups
  DIMENSION_WIKILINK="$(build_fallback_wikilink "01-research-dimensions" "$dimension_entity_id")"
  if [[ -x "$WIKILINK_SCRIPT" ]]; then
    if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
      --project-path "$project_path" \
      --entity-dir "01-research-dimensions" \
      --filename "$dimension_entity_id" 2>/dev/null)"; then
      if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
        DIMENSION_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
      fi
    fi
  fi

  # --------------------------------------------------------------------------
  # WRITE QUESTIONS FOR THIS DIMENSION
  # --------------------------------------------------------------------------

  dimension_question_files=()
  dimension_question_wikilinks=()
  dimension_question_count=0

  for q_idx in $(seq 0 $((planned_question_count - 1))); do
    # Extract question data
    q_title="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].title" "$json_file")"
    q_entity_id="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].entity_id" "$json_file")"
    q_text="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].question_text" "$json_file")"
    q_rationale="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].rationale" "$json_file")"

    # Extract PICOT components
    picot_population="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].picot_structure.population" "$json_file")"
    picot_intervention="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].picot_structure.intervention" "$json_file")"
    picot_comparison="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].picot_structure.comparison" "$json_file")"
    picot_outcome="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].picot_structure.outcome" "$json_file")"
    picot_timeframe="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].picot_structure.timeframe" "$json_file")"

    # Extract FINER scores
    finer_feasible="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.feasible" "$json_file")"
    finer_interesting="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.interesting" "$json_file")"
    finer_novel="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.novel" "$json_file")"
    finer_ethical="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.ethical" "$json_file")"
    finer_relevant="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.relevant" "$json_file")"
    finer_total="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].finer_scores.total" "$json_file")"

    # Extract TIPS-enhanced fields (optional, for smarter-service research type)
    # Action Horizon
    action_horizon_exists="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].action_horizon // empty" "$json_file")"
    if [[ -n "$action_horizon_exists" ]]; then
      ah_horizon="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].action_horizon.horizon // \"\"" "$json_file")"
      ah_justification="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].action_horizon.justification // \"\"" "$json_file")"
      ah_timeframe="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].action_horizon.timeframe // \"\"" "$json_file")"
    else
      ah_horizon=""
      ah_justification=""
      ah_timeframe=""
    fi

    # Trend Velocity
    trend_velocity_exists="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].trend_velocity // empty" "$json_file")"
    if [[ -n "$trend_velocity_exists" ]]; then
      tv_velocity="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].trend_velocity.velocity // \"\"" "$json_file")"
      tv_momentum="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].trend_velocity.momentum_indicator // \"\"" "$json_file")"
      tv_evidence_type="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].trend_velocity.evidence_type // \"\"" "$json_file")"
    else
      tv_velocity=""
      tv_momentum=""
      tv_evidence_type=""
    fi

    # Case Study Requirement
    case_study_exists="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].case_study_requirement // empty" "$json_file")"
    if [[ -n "$case_study_exists" ]]; then
      cs_level="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].case_study_requirement.requirement_level // \"\"" "$json_file")"
      cs_count="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].case_study_requirement.count // \"\"" "$json_file")"
      cs_tips_role="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].case_study_requirement.tips_role // \"\"" "$json_file")"
    else
      cs_level=""
      cs_count=""
      cs_tips_role=""
    fi

    # Cross-Dimensional Links (as JSON array for frontmatter)
    cross_links_json="$(jq -c ".dimensions[$dim_idx].questions[$q_idx].cross_dimensional_links // []" "$json_file")"
    cross_links_count="$(echo "$cross_links_json" | jq 'length')"

    # Portfolio Category (for b2b-ict-portfolio research type)
    portfolio_category_exists="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].portfolio_category // empty" "$json_file")"
    if [[ -n "$portfolio_category_exists" ]]; then
      pc_category_id="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].portfolio_category.category_id // \"\"" "$json_file")"
      pc_category_name="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].portfolio_category.category_name // \"\"" "$json_file")"
      pc_dimension_slug="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].portfolio_category.dimension_slug // \"\"" "$json_file")"
    else
      pc_category_id=""
      pc_category_name=""
      pc_dimension_slug=""
    fi

    # Extract slug and hash from entity_id
    # Expected format: question-{semantic-slug}-{8char-hash}
    # Example: question-fachkraeftemangel-transformation-1a2b3c4d
    q_hash="$(echo "$q_entity_id" | grep -o '[a-z0-9]\{8\}$' || echo "")"
    q_slug="$(echo "$q_entity_id" | sed 's/^question-//' | sed 's/-[a-z0-9]\{8\}$//')"

    # DEFENSIVE: If slug extraction failed (empty or starts with dash), derive from title
    # This handles malformed entity_ids like "question--3a2b3c4d" (missing semantic slug)
    if [[ -z "$q_slug" ]] || [[ "$q_slug" == -* ]]; then
      # Generate slug from title: lowercase, replace non-alphanumeric with dash, collapse dashes
      q_slug="$(echo "$q_title" | tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)"
      # If still empty, use hash as fallback
      if [[ -z "$q_slug" ]]; then
        q_slug="untitled"
      fi
    fi

    # Generate question filename
    question_file="$questions_dir/question-${q_slug}-${q_hash}.md"

    # Extract short title
    q_short_title="$(echo "$q_title" | sed 's/ - .*//')"
    q_dc_title="Question: $q_short_title"

    # Build TIPS-enhanced frontmatter sections (only if data exists)
    tips_frontmatter=""
    if [[ -n "$ah_horizon" ]]; then
      tips_frontmatter+="action_horizon:
  horizon: \"$ah_horizon\"
  justification: \"$ah_justification\"
  timeframe: \"$ah_timeframe\"
"
    fi
    if [[ -n "$tv_velocity" ]]; then
      tips_frontmatter+="trend_velocity:
  velocity: \"$tv_velocity\"
  momentum_indicator: \"$tv_momentum\"
  evidence_type: \"$tv_evidence_type\"
"
    fi
    if [[ -n "$cs_level" ]]; then
      tips_frontmatter+="case_study_requirement:
  requirement_level: \"$cs_level\"
  count: \"$cs_count\"
  tips_role: \"$cs_tips_role\"
"
    fi
    if [[ "$cross_links_count" -gt 0 ]]; then
      tips_frontmatter+="cross_dimensional_links: $cross_links_json
"
    fi
    if [[ -n "$pc_category_id" ]]; then
      tips_frontmatter+="portfolio_category:
  category_id: \"$pc_category_id\"
  category_name: \"$pc_category_name\"
  dimension_slug: \"$pc_dimension_slug\"
"
    fi

    # Build TIPS-enhanced body sections (only if data exists)
    tips_body=""
    if [[ -n "$ah_horizon" ]]; then
      tips_body+="
## Action Horizon

- **Horizon**: $ah_horizon
- **Timeframe**: $ah_timeframe
- **Justification**: $ah_justification
"
    fi
    if [[ -n "$tv_velocity" ]]; then
      tips_body+="
## Trend Velocity

- **Velocity**: $tv_velocity
- **Momentum Indicator**: $tv_momentum
- **Evidence Type**: $tv_evidence_type
"
    fi
    if [[ -n "$cs_level" ]]; then
      tips_body+="
## Case Study Requirement

- **Requirement Level**: $cs_level
- **Expected Count**: $cs_count
- **TIPS Role**: $cs_tips_role
"
    fi
    if [[ "$cross_links_count" -gt 0 ]]; then
      # Build cross-dimensional links section
      cross_links_section="
## Cross-Dimensional Links
"
      for link_idx in $(seq 0 $((cross_links_count - 1))); do
        link_target="$(echo "$cross_links_json" | jq -r ".[$link_idx].target_dimension")"
        link_type="$(echo "$cross_links_json" | jq -r ".[$link_idx].link_type")"
        link_flow="$(echo "$cross_links_json" | jq -r ".[$link_idx].tips_flow // \"\"")"
        link_evidence="$(echo "$cross_links_json" | jq -r ".[$link_idx].evidence // \"\"")"
        cross_links_section+="
- **Target**: $link_target | **Type**: $link_type | **TIPS Flow**: $link_flow
  - Evidence: $link_evidence
"
      done
      tips_body+="$cross_links_section"
    fi
    if [[ -n "$pc_category_id" ]]; then
      tips_body+="
## Portfolio Category

- **Category ID**: $pc_category_id
- **Category Name**: $pc_category_name
- **Dimension**: $pc_dimension_slug
"
    fi

    # Write question file
    cat > "$question_file" <<EOF
---
tags: [research-question, question, dimension-$dimension_number, $project_language]
dc:creator: Claude (dimension-planner)
dc:title: "$q_dc_title"
dc:created: $timestamp
dc:identifier: $q_entity_id
entity_type: refined-question
question:
  number: $((q_idx + 1))
  slug: "$q_slug"
  title: "$q_title"
  text: "$q_text"
dimension_ref: "$DIMENSION_WIKILINK"
language: $project_language
picot_structure:
  population: "$picot_population"
  intervention: "$picot_intervention"
  comparison: "$picot_comparison"
  outcome: "$picot_outcome"
  timeframe: "$picot_timeframe"
$tips_frontmatter---

# $q_title

**Parent Dimension**: $DIMENSION_WIKILINK

## Research Question

$q_text

## Rationale

$q_rationale

## PICOT Framework

- **Population**: $picot_population
- **Intervention**: $picot_intervention
- **Comparison**: $picot_comparison
- **Outcome**: $picot_outcome
- **Timeframe**: $picot_timeframe

## FINER Assessment

- **Feasible**: $finer_feasible/3
- **Interesting**: $finer_interesting/3
- **Novel**: $finer_novel/3
- **Ethical**: $finer_ethical/3
- **Relevant**: $finer_relevant/3
- **Total Score**: $finer_total/15
$tips_body
EOF

    if [[ ! -f "$question_file" ]]; then
      echo "{\"success\": false, \"error\": \"Failed to write question file: $question_file (dim $dimension_number, q $((q_idx + 1)))\"}" >&2
      exit 3
    fi

    # Track question
    abs_question_file="$(cd "$(dirname "$question_file")" && pwd)"/$(basename "$question_file")
    dimension_question_files+=("$abs_question_file")
    all_question_files+=("$abs_question_file")
    dimension_question_count=$((dimension_question_count + 1))
    actual_total_questions=$((actual_total_questions + 1))

    # Generate wikilink for this question (for Related Questions section in dimension)
    # Fix v1.2.0: Use workspace-aware fallback for multi-project setups
    question_filename="question-${q_slug}-${q_hash}"
    QUESTION_WIKILINK="$(build_fallback_wikilink "02-refined-questions" "$question_filename" "$q_short_title")"
    if [[ -x "$WIKILINK_SCRIPT" ]]; then
      if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
        --project-path "$project_path" \
        --entity-dir "02-refined-questions" \
        --filename "$question_filename" \
        --display-name "$q_short_title" 2>/dev/null)"; then
        if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
          QUESTION_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
        fi
      fi
    fi
    dimension_question_wikilinks+=("$QUESTION_WIKILINK")
  done

  # Verify question count for this dimension
  if [[ "$dimension_question_count" -ne "$planned_question_count" ]]; then
    echo "{\"success\": false, \"error\": \"Question count mismatch for dimension $dimension_number: created $dimension_question_count, expected $planned_question_count\"}" >&2
    exit 4
  fi

  # --------------------------------------------------------------------------
  # WRITE DIMENSION FILE
  # --------------------------------------------------------------------------

  dimension_file="$dimensions_dir/dimension-${dimension_slug}-${dimension_hash}.md"

  # Extract short title
  dimension_short_title="$(echo "$dimension_title" | sed 's/ - .*//')"
  dimension_dc_title="Dimension: $dimension_short_title"

  # Build Related Questions section content
  related_questions_content=""
  for wikilink in "${dimension_question_wikilinks[@]}"; do
    related_questions_content+="- $wikilink"$'\n'
  done

  cat > "$dimension_file" <<EOF
---
tags: [research-dimension, question, dimension-$dimension_number, $project_language]
dc:creator: Claude (dimension-planner)
dc:title: "$dimension_dc_title"
dc:created: $timestamp
dc:identifier: $dimension_entity_id
entity_type: dimension
dimension:
  number: $dimension_number
  slug: "$dimension_slug"
  title: "$dimension_title"
initial_question_ref: "$INITIAL_QUESTION_WIKILINK"
question_count: $dimension_question_count
mece_validated: false
language: $project_language
---

# $dimension_title

**Parent Question**: $INITIAL_QUESTION_WIKILINK

## Description

$dimension_description

## Scope

$dimension_scope

## Rationale

$dimension_rationale

## Related Questions

$related_questions_content
EOF

  if [[ ! -f "$dimension_file" ]]; then
    echo "{\"success\": false, \"error\": \"Failed to write dimension file: $dimension_file\"}" >&2
    exit 3
  fi

  # Track dimension
  abs_dimension_file="$(cd "$(dirname "$dimension_file")" && pwd)"/$(basename "$dimension_file")
  all_dimension_files+=("$abs_dimension_file")
  actual_total_dimensions=$((actual_total_dimensions + 1))
done

# ============================================================================
# VERIFY TOTALS
# ============================================================================

if [[ "$actual_total_dimensions" -ne "$total_dimensions" ]]; then
  echo "{\"success\": false, \"error\": \"Dimension count mismatch: created $actual_total_dimensions, expected $total_dimensions\"}" >&2
  exit 4
fi

if [[ "$actual_total_questions" -ne "$total_questions" ]]; then
  echo "{\"success\": false, \"error\": \"Total question count mismatch: created $actual_total_questions, expected $total_questions\"}" >&2
  exit 4
fi

# ============================================================================
# GENERATE PROVENANCE READMES
# ============================================================================

# Sanitize text for Mermaid mindmap nodes
# Removes parentheses and their contents to prevent parsing errors
# Usage: sanitize_mindmap_label "Text (with parens)"
sanitize_mindmap_label() {
  echo "$1" | sed 's/([^)]*)//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//'
}

# Extract initial question title for mindmap (truncate to 40 chars)
# Format: question-{slug}-{hash} -> readable title
initial_question_title="$(echo "$initial_question_entity_id" | \
  sed 's/^question-//' | sed 's/-[a-z0-9]\{8\}$//' | \
  tr '-' ' ' | cut -c1-40)"

# Capitalize first letter of each word for display
initial_question_display="$(echo "$initial_question_title" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"

# --------------------------------------------------------------------------
# Generate Dimensions README
# --------------------------------------------------------------------------

dimensions_readme_path="$dimensions_base_dir/README.md"

# Build dimension nodes for mindmap
dimension_mindmap_nodes=""
dimension_entity_rows=""

for dim_idx in $(seq 0 $((total_dimensions - 1))); do
  dim_title="$(jq -r ".dimensions[$dim_idx].dimension.title" "$json_file")"
  dim_entity_id="$(jq -r ".dimensions[$dim_idx].dimension.entity_id" "$json_file")"
  dim_question_count="$(jq -r ".dimensions[$dim_idx].dimension.question_count" "$json_file")"
  dim_number=$((dim_idx + 1))

  # Truncate and sanitize title for mindmap (max 40 chars, no parentheses)
  dim_title_short="$(sanitize_mindmap_label "$dim_title" | cut -c1-40)"

  # Generate dimension wikilink for README
  # Fix v1.2.0: Use workspace-aware fallback for multi-project setups
  DIM_README_WIKILINK="$(build_fallback_wikilink "01-research-dimensions" "$dim_entity_id")"
  if [[ -x "$WIKILINK_SCRIPT" ]]; then
    if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
      --project-path "$project_path" \
      --entity-dir "01-research-dimensions" \
      --filename "$dim_entity_id" 2>/dev/null)"; then
      if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
        DIM_README_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
      fi
    fi
  fi

  dimension_mindmap_nodes+="    $dim_title_short"$'\n'
  dimension_entity_rows+="| Dimension | $dim_title | $DIM_README_WIKILINK |"$'\n'
  dimension_summary_rows+="| $dim_number | $DIM_README_WIKILINK | $dim_question_count |"$'\n'
done

cat > "$dimensions_readme_path" <<EOF
---
title: "$(get_label "research_dimensions_overview" "$project_language")"
generated_by: dimension-planner
generated_at: $timestamp
initial_question: "$initial_question_entity_id"
dimension_count: $total_dimensions
project_language: $project_language
---

# $(get_label "research_dimensions" "$project_language")

$(get_label "hierarchical_view_dimensions" "$project_language")

## $(get_label "provenance_chain" "$project_language")

\`\`\`mermaid
mindmap
  root(($initial_question_display))
$dimension_mindmap_nodes\`\`\`

## $(get_label "statistics" "$project_language")

| $(get_label "metric" "$project_language") | $(get_label "value" "$project_language") |
|--------|-------|
| $(get_label "initial_question" "$project_language") | $INITIAL_QUESTION_WIKILINK |
| $(get_label "dimensions" "$project_language") | $total_dimensions |

## $(get_label "entity_index" "$project_language")

| $(get_label "type" "$project_language") | $(get_label "entity" "$project_language") | $(get_label "link" "$project_language") |
|------|--------|------|
| $(get_label "question" "$project_language") | $(get_label "initial_question" "$project_language") | $INITIAL_QUESTION_WIKILINK |
$dimension_entity_rows
---

*$(get_label "generated_by" "$project_language") dimension-planner Phase 5*
EOF

dimensions_readme_created="false"
if [[ -f "$dimensions_readme_path" ]]; then
  dimensions_readme_created="true"
fi

# --------------------------------------------------------------------------
# Generate Refined-Questions README
# --------------------------------------------------------------------------

questions_readme_path="$questions_base_dir/README.md"

# Build hierarchical mindmap nodes and entity rows
question_mindmap_nodes=""
question_entity_rows=""

for dim_idx in $(seq 0 $((total_dimensions - 1))); do
  dim_title="$(jq -r ".dimensions[$dim_idx].dimension.title" "$json_file")"
  dim_entity_id="$(jq -r ".dimensions[$dim_idx].dimension.entity_id" "$json_file")"
  planned_q_count="$(jq -r ".dimensions[$dim_idx].dimension.question_count" "$json_file")"

  # Truncate and sanitize dimension title for mindmap (max 40 chars, no parentheses)
  dim_title_short="$(sanitize_mindmap_label "$dim_title" | cut -c1-40)"

  # Generate dimension wikilink for questions README
  # Fix v1.2.0: Use workspace-aware fallback for multi-project setups
  DIM_Q_README_WIKILINK="$(build_fallback_wikilink "01-research-dimensions" "$dim_entity_id")"
  if [[ -x "$WIKILINK_SCRIPT" ]]; then
    if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
      --project-path "$project_path" \
      --entity-dir "01-research-dimensions" \
      --filename "$dim_entity_id" 2>/dev/null)"; then
      if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
        DIM_Q_README_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
      fi
    fi
  fi

  question_mindmap_nodes+="    $dim_title_short"$'\n'
  question_entity_rows+="| Dimension | $dim_title | $DIM_Q_README_WIKILINK |"$'\n'

  for q_idx in $(seq 0 $((planned_q_count - 1))); do
    q_title="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].title" "$json_file")"
    q_entity_id="$(jq -r ".dimensions[$dim_idx].questions[$q_idx].entity_id" "$json_file")"

    # Truncate and sanitize question title for mindmap (max 40 chars, no parentheses)
    q_title_short="$(sanitize_mindmap_label "$q_title" | cut -c1-40)"

    # Generate question wikilink for questions README
    # Fix v1.2.0: Use workspace-aware fallback for multi-project setups
    Q_README_WIKILINK="$(build_fallback_wikilink "02-refined-questions" "$q_entity_id")"
    if [[ -x "$WIKILINK_SCRIPT" ]]; then
      if WIKILINK_RESULT="$(bash "$WIKILINK_SCRIPT" \
        --project-path "$project_path" \
        --entity-dir "02-refined-questions" \
        --filename "$q_entity_id" 2>/dev/null)"; then
        if echo "$WIKILINK_RESULT" | jq -e . >/dev/null 2>&1; then
          Q_README_WIKILINK="$(echo "$WIKILINK_RESULT" | jq -r '.data.wikilink')"
        fi
      fi
    fi

    question_mindmap_nodes+="      $q_title_short"$'\n'
    question_entity_rows+="| Question | $q_title | $Q_README_WIKILINK |"$'\n'
  done
done

cat > "$questions_readme_path" <<EOF
---
title: "$(get_label "refined_questions_overview" "$project_language")"
generated_by: dimension-planner
generated_at: $timestamp
initial_question: "$initial_question_entity_id"
dimension_count: $total_dimensions
question_count: $total_questions
project_language: $project_language
---

# $(get_label "refined_questions" "$project_language")

$(get_label "hierarchical_view_questions" "$project_language")

## $(get_label "provenance_chain" "$project_language")

\`\`\`mermaid
mindmap
  root(($initial_question_display))
$question_mindmap_nodes\`\`\`

## $(get_label "statistics" "$project_language")

| $(get_label "metric" "$project_language") | $(get_label "value" "$project_language") |
|--------|-------|
| $(get_label "initial_question" "$project_language") | $INITIAL_QUESTION_WIKILINK |
| $(get_label "dimensions" "$project_language") | $total_dimensions |
| $(get_label "refined_questions" "$project_language") | $total_questions |

## $(get_label "entity_index" "$project_language")

| $(get_label "type" "$project_language") | $(get_label "entity" "$project_language") | $(get_label "link" "$project_language") |
|------|--------|------|
| $(get_label "question" "$project_language") | $(get_label "initial_question" "$project_language") | $INITIAL_QUESTION_WIKILINK |
$question_entity_rows
---

*$(get_label "generated_by" "$project_language") dimension-planner Phase 5*
EOF

questions_readme_created="false"
if [[ -f "$questions_readme_path" ]]; then
  questions_readme_created="true"
fi

# --------------------------------------------------------------------------
# Generate Initial-Question README
# --------------------------------------------------------------------------

initial_question_readme_path="$project_path/00-initial-question/README.md"

cat > "$initial_question_readme_path" <<EOF
---
title: "$(get_label "initial_question" "$project_language")"
generated_by: dimension-planner
generated_at: $timestamp
initial_question: "$initial_question_entity_id"
project_language: $project_language
---

# $(get_label "initial_question" "$project_language")

$(get_label "starting_point" "$project_language")

## $(get_label "research_question" "$project_language")

$INITIAL_QUESTION_WIKILINK

## $(get_label "derived_dimensions" "$project_language")

| # | $(get_label "dimension" "$project_language") | $(get_label "questions" "$project_language") |
|---|-----------|-----------|
$dimension_summary_rows
## $(get_label "statistics" "$project_language")

| $(get_label "metric" "$project_language") | $(get_label "value" "$project_language") |
|--------|-------|
| $(get_label "dimensions" "$project_language") | $total_dimensions |
| $(get_label "total_questions" "$project_language") | $total_questions |

---

*$(get_label "generated_by" "$project_language") dimension-planner Phase 5*
EOF

initial_question_readme_created="false"
if [[ -f "$initial_question_readme_path" ]]; then
  initial_question_readme_created="true"
fi

# ============================================================================
# OPTIONAL YAML VALIDATION
# ============================================================================

yaml_valid="true"

if command -v yq >/dev/null 2>&1; then
  # Validate dimension files (frontmatter only)
  for df in "${all_dimension_files[@]}"; do
    if ! extract_frontmatter "$df" | yq eval '.' - >/dev/null 2>&1; then
      yaml_valid="false"
      echo "Warning: Dimension file contains malformed YAML frontmatter: $df" >&2
    fi
  done

  # Validate question files (frontmatter only)
  for qf in "${all_question_files[@]}"; do
    if ! extract_frontmatter "$qf" | yq eval '.' - >/dev/null 2>&1; then
      yaml_valid="false"
      echo "Warning: Question file contains malformed YAML frontmatter: $qf" >&2
    fi
  done
else
  yaml_valid="unknown"
fi

# ============================================================================
# OUTPUT RESULTS
# ============================================================================

# Build dimension files JSON array
dimension_files_json="["
for i in "${!all_dimension_files[@]}"; do
  if [[ $i -gt 0 ]]; then
    dimension_files_json+=","
  fi
  dimension_files_json+="\"${all_dimension_files[$i]}\""
done
dimension_files_json+="]"

# Build question files JSON array
question_files_json="["
for i in "${!all_question_files[@]}"; do
  if [[ $i -gt 0 ]]; then
    question_files_json+=","
  fi
  question_files_json+="\"${all_question_files[$i]}\""
done
question_files_json+="]"

# Output JSON result
cat <<EOF
{
  "success": true,
  "data": {
    "dimension_files": $dimension_files_json,
    "question_files": $question_files_json,
    "dimensions_created": $actual_total_dimensions,
    "questions_created": $actual_total_questions,
    "readmes_created": {
      "initial_question_readme": $initial_question_readme_created,
      "dimensions_readme": $dimensions_readme_created,
      "refined_questions_readme": $questions_readme_created
    }
  },
  "validation_results": {
    "schema_valid": $schema_valid,
    "yaml_valid": "$yaml_valid",
    "dimension_count_match": true,
    "question_count_match": true
  },
  "stats": {
    "planned_dimensions": $total_dimensions,
    "created_dimensions": $actual_total_dimensions,
    "planned_questions": $total_questions,
    "created_questions": $actual_total_questions
  }
}
EOF

exit 0
