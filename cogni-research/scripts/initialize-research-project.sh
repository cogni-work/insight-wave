#!/usr/bin/env bash
set -euo pipefail
# initialize-research-project.sh
# Version: 2.3.0
# Purpose: Initialize new research project with complete entity directory structure
#
# Changelog:
# v2.3.0 (2026-01-21, Research-Type-Specific Methodology):
#   - Template copying now selects research-type-specific methodology files
#   - Priority: research-methodology-{type}.md > research-methodology.md
#   - Supports: generic, b2b-ict-portfolio, lean-canvas
#   - Falls back to generic methodology if type-specific not found
#
# v2.2.0 (2026-01-16, BUG: Template Copying Fix):
#   - Added CLAUDE_PLUGIN_ROOT auto-detection before template copying
#   - Follows pattern from citation-generator.sh (4adc4ecf)
#   - Fixes silent failure when CLAUDE_PLUGIN_ROOT not set
#
# v2.1.0 (2026-01-04, BUG-040: CLAUDE_PROJECT_DIR Fallback):
#   - Added CLAUDE_PROJECT_DIR as fallback when COGNI_RESEARCH_ROOT not set
#   - Projects now created in Claude Code working directory by default
#   - Priority: COGNI_RESEARCH_ROOT > CLAUDE_PROJECT_DIR > ~/research-projects
#
# v2.0.0 (2025-11-16, Sprint 315: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added structured phase markers (5 phases)
#   - Added performance metrics (directories_created, files_initialized, duration)
#   - Now compliant with three-layer debugging architecture
#
# Usage:
#   initialize-research-project.sh --project-name <name> [OPTIONS]
#
# Arguments:
#   --project-name <name>      Project name (required, kebab-case recommended)
#   --projects-root <path>     Projects root directory (default: ${COGNI_RESEARCH_ROOT} or ~/research-projects)
#   --research-type <type>     Research type (e.g., lean-canvas, action-oriented-radar, trend-radar, generic)
#   --language <code>          Project language (ISO 639-1 code, e.g., "en", "de", "fr"; default: "en")
#   --json                     Output results in JSON format
#
# Environment Variables:
#   COGNI_RESEARCH_ROOT         Plugin workspace root (set by workplace-manager)
#   CLAUDE_PROJECT_DIR         Claude Code runtime working directory (auto-set)
#
# Workspace Integration (BUG-040 FIX - priority order):
#   1. --projects-root argument (explicit override, highest priority)
#   2. COGNI_RESEARCH_ROOT environment variable (workplace-manager config)
#   3. CLAUDE_PROJECT_DIR environment variable (Claude Code runtime context)
#   4. ~/research-projects/ (standalone fallback)
#
# Returns:
#   JSON: {"success": true|false, "project_path": "...", "entity_dirs": [...], "error": "..."}
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   initialize-research-project.sh --project-name "green-bonds-study" \
#     --projects-root "$HOME/research-projects" --json


# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    echo "Install jq: https://stedolan.github.io/jq/download/" >&2
    exit 2
fi

# Script metadata
readonly SCRIPT_VERSION="2.3.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===== ENTITY CONFIG INITIALIZATION =====
# Source entity configuration library (provides get_entity_dirs_array, etc.)
if [[ -f "${SCRIPT_DIR}/lib/entity-config.sh" ]]; then
    source "${SCRIPT_DIR}/lib/entity-config.sh"
else
    echo "ERROR: Entity config library not found: ${SCRIPT_DIR}/lib/entity-config.sh" >&2
    exit 2
fi

# ===== PLUGIN ROOT RESOLUTION =====
# Auto-detect CLAUDE_PLUGIN_ROOT if not set (resolve-plugin-root.sh pattern)
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  # Derive from script location: /plugin/scripts/script.sh -> /plugin
  CLAUDE_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export CLAUDE_PLUGIN_ROOT
fi

# Validate CLAUDE_PLUGIN_ROOT has expected structure
if [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: '"${CLAUDE_PLUGIN_ROOT}"'"}' >&2
  exit 1
fi

# ===== LOGGING INITIALIZATION =====
# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

# Track start time
START_TIME="$(date +%s)"

# Default configuration

# BUG-037 FIX: Validate COGNI_RESEARCH_ROOT is an absolute path if set
if [ -n "${COGNI_RESEARCH_ROOT:-}" ]; then
    case "$COGNI_RESEARCH_ROOT" in
        /*) ;;  # already absolute, no action needed
        *)
            if [[ "$JSON_OUTPUT" == true ]]; then
                jq -n --arg error "COGNI_RESEARCH_ROOT must be an absolute path: $COGNI_RESEARCH_ROOT" \
                    '{success: false, error: $error}'
            else
                echo "ERROR: COGNI_RESEARCH_ROOT must be an absolute path: $COGNI_RESEARCH_ROOT" >&2
            fi
            exit 1
            ;;
    esac
fi

# BUG-040 FIX: Intelligent projects root resolution with CLAUDE_PROJECT_DIR fallback
# Priority: 1) COGNI_RESEARCH_ROOT, 2) CLAUDE_PROJECT_DIR, 3) ~/research-projects
if [ -n "${COGNI_RESEARCH_ROOT:-}" ]; then
    DEFAULT_PROJECTS_ROOT="$COGNI_RESEARCH_ROOT"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    # CLAUDE_PROJECT_DIR is set by Claude Code runtime - use it as projects root
    DEFAULT_PROJECTS_ROOT="$CLAUDE_PROJECT_DIR"
else
    DEFAULT_PROJECTS_ROOT="${HOME}/research-projects"
fi
readonly DEFAULT_PROJECTS_ROOT


# Parse arguments
PROJECT_NAME=""
PROJECTS_ROOT="$DEFAULT_PROJECTS_ROOT"
RESEARCH_TYPE="generic"
PROJECT_LANGUAGE="en"  # Default for backward compatibility
JSON_OUTPUT=false

log_phase "Phase 1: Input Parsing" "start"

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --projects-root)
            PROJECTS_ROOT="$2"
            shift 2
            ;;
        --research-type)
            RESEARCH_TYPE="$2"
            shift 2
            ;;
        --language)
            PROJECT_LANGUAGE="$2"
            shift 2
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

log_conditional "INFO" "Parameter: PROJECT_NAME = ${PROJECT_NAME}"
log_conditional "INFO" "Parameter: PROJECTS_ROOT = ${PROJECTS_ROOT}"
log_conditional "INFO" "Parameter: RESEARCH_TYPE = ${RESEARCH_TYPE}"
log_conditional "INFO" "Parameter: PROJECT_LANGUAGE = ${PROJECT_LANGUAGE}"
log_phase "Phase 1: Input Parsing" "complete"

# ===== PHASE 2: VALIDATION =====
log_phase "Phase 2: Input Validation" "start"

# Validation
if [[ -z "$PROJECT_NAME" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --project-name" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --project-name" >&2
        echo "Usage: $SCRIPT_NAME --project-name <name> [--projects-root <path>] [--json]" >&2
    fi
    exit 1
fi

# Sanitize project name (basic validation)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Invalid project name. Use only letters, numbers, hyphens, and underscores." \
            '{success: false, error: $error}'
    else
        echo "ERROR: Invalid project name '$PROJECT_NAME'" >&2
        echo "Use only letters, numbers, hyphens, and underscores" >&2
    fi
    exit 1
fi

# Validate PROJECTS_ROOT
if [[ ! -d "$PROJECTS_ROOT" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Projects root directory does not exist: $PROJECTS_ROOT" \
            --arg path "$PROJECTS_ROOT" \
            '{success: false, error: $error, projects_root: $path}'
    else
        echo "ERROR: Projects root directory does not exist: $PROJECTS_ROOT" >&2
        echo "Create it first with: mkdir -p '$PROJECTS_ROOT'" >&2
    fi
    exit 1
fi


# BUG-039 FIX: Check both write and execute permissions
if [[ ! -w "$PROJECTS_ROOT" ]] || [[ ! -x "$PROJECTS_ROOT" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Projects root directory not accessible (needs write+execute): $PROJECTS_ROOT" \
            --arg path "$PROJECTS_ROOT" \
            '{success: false, error: $error, projects_root: $path}'
    else
        echo "ERROR: Projects root directory not accessible (needs write+execute): $PROJECTS_ROOT" >&2
        echo "Check permissions or use a different location with --projects-root" >&2
    fi
    exit 1
fi

# Generate normalized project ID (used for metadata)
readonly PROJECT_ID="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"

# Construct project path
readonly PROJECT_PATH="$PROJECTS_ROOT/$PROJECT_NAME"
log_conditional "INFO" "Project path: $PROJECT_PATH"

# Check if project already exists
if [[ -d "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n \
            --arg error "Project already exists: $PROJECT_PATH" \
            --arg path "$PROJECT_PATH" \
            '{success: false, error: $error, project_path: $path, exists: true}'
    else
        echo "ERROR: Project already exists: $PROJECT_PATH" >&2
        echo "Use a different project name or delete the existing project" >&2
    fi
    exit 1
fi

log_conditional "INFO" "All validations passed"
log_phase "Phase 2: Input Validation" "complete"

# ===== PHASE 3: DIRECTORY CREATION =====
log_phase "Phase 3: Directory Creation" "start"

# Create project directory structure
mkdir -p "$PROJECT_PATH"
log_conditional "DEBUG" "Created project root: $PROJECT_PATH"

# Entity directories (loaded from central config)
# Bash 3.2 compatible array loading (mapfile requires Bash 4.0+)
ENTITY_DIRS=()
while IFS= read -r dir; do
    ENTITY_DIRS+=("$dir")
done < <(get_entity_dirs_array)
readonly ENTITY_DIRS
readonly DATA_SUBDIR="$(get_data_subdir)"

# Create all entity directories with data subdirectories
for dir in "${ENTITY_DIRS[@]}"; do
    mkdir -p "$PROJECT_PATH/$dir/$DATA_SUBDIR"
    log_conditional "DEBUG" "Created directory: $dir/$DATA_SUBDIR"
done

# Create metadata directory
mkdir -p "$PROJECT_PATH/.metadata"
log_conditional "DEBUG" "Created directory: .metadata"

log_metric "directories_created" "$((${#ENTITY_DIRS[@]} + 2))" "count"
log_phase "Phase 3: Directory Creation" "complete"

# ===== PHASE 4: METADATA INITIALIZATION =====
log_phase "Phase 4: Metadata Initialization" "start"

# Generate timestamps for metadata
readonly CREATED_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build entity_counts object dynamically from config
ENTITY_COUNTS_JSON="{}"
for dir in "${ENTITY_DIRS[@]}"; do
    ENTITY_COUNTS_JSON=$(echo "$ENTITY_COUNTS_JSON" | jq --arg key "$dir" '. + {($key): 0}')
done

# Generate project configuration
readonly PROJECT_CONFIG="$PROJECT_PATH/.metadata/project-config.json"
jq -n \
    --arg project_id "$PROJECT_ID" \
    --arg project_name "$PROJECT_NAME" \
    --arg project_slug "$PROJECT_ID" \
    --arg created "$CREATED_TIMESTAMP" \
    --arg version "1.0.0" \
    --argjson entity_counts "$ENTITY_COUNTS_JSON" \
    '{
        project_id: $project_id,
        project_name: $project_name,
        project_slug: $project_slug,
        created: $created,
        last_updated: $created,
        version: $version,
        sprint_count: 0,
        entity_counts: $entity_counts
    }' > "$PROJECT_CONFIG"

# Build entities object dynamically from config (each key maps to empty array)
ENTITIES_JSON="{}"
for dir in "${ENTITY_DIRS[@]}"; do
    ENTITIES_JSON=$(echo "$ENTITIES_JSON" | jq --arg key "$dir" '. + {($key): []}')
done

# Generate entity index with correct object structure for entity-type keyed access
# BUG FIX: create-entity.sh expects entities to be an OBJECT keyed by entity type,
# not an array. Previous structure `entities: []` caused jq to fail silently on
# `.entities[$entity_type] += [...]` operations, leading to index corruption.
readonly ENTITY_INDEX="$PROJECT_PATH/.metadata/entity-index.json"
jq -n \
    --arg created "$CREATED_TIMESTAMP" \
    --argjson entities "$ENTITIES_JSON" \
    '{
        version: "1.0.0",
        created: $created,
        last_updated: $created,
        entities: $entities
    }' > "$ENTITY_INDEX"

# Generate sprint log
readonly SPRINT_LOG="$PROJECT_PATH/.metadata/sprint-log.json"
jq -n \
    --arg project_id "$PROJECT_ID" \
    --arg research_type "$RESEARCH_TYPE" \
    --arg project_language "$PROJECT_LANGUAGE" \
    '{
        project_id: $project_id,
        research_type: $research_type,
        project_language: $project_language,
        sprints: [],
        current_sprint: 0,
        total_entities_cumulative: 0,
        discovery_complete: false,
        enrichment_complete: false,
        part2_complete: false
    }' > "$SPRINT_LOG"
log_conditional "DEBUG" "Created: .metadata/sprint-log.json"

log_metric "files_initialized" 3 "count"
log_phase "Phase 4: Metadata Initialization" "complete"

# ===== PHASE 5: TEMPLATE COPYING =====
log_phase "Phase 5: Template Copying" "start"

# Copy research methodology documentation based on research type and language
# Priority: research-type-specific > generic
readonly DOCS_DIR="${CLAUDE_PLUGIN_ROOT:-}/docs/user"
readonly METHODOLOGY_DEST="$PROJECT_PATH/research-methodology.md"

# Build methodology file path based on research type
# For types like "generic", "b2b-ict-portfolio", "lean-canvas"
METHODOLOGY_TYPE_EN="${DOCS_DIR}/research-methodology-${RESEARCH_TYPE}.md"
METHODOLOGY_TYPE_DE="${DOCS_DIR}/research-methodology-${RESEARCH_TYPE}-de.md"
METHODOLOGY_GENERIC_EN="${DOCS_DIR}/research-methodology.md"
METHODOLOGY_GENERIC_DE="${DOCS_DIR}/research-methodology-de.md"

# Select methodology file: type-specific > generic, respecting language
SELECTED_METHODOLOGY=""
if [[ "$PROJECT_LANGUAGE" == "de" ]]; then
    # German: try type-specific DE, then type-specific EN, then generic DE, then generic EN
    if [[ -f "$METHODOLOGY_TYPE_DE" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_TYPE_DE"
        log_conditional "DEBUG" "Selected: research-type-specific German methodology (${RESEARCH_TYPE})"
    elif [[ -f "$METHODOLOGY_TYPE_EN" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_TYPE_EN"
        log_conditional "DEBUG" "Selected: research-type-specific English methodology (${RESEARCH_TYPE})"
    elif [[ -f "$METHODOLOGY_GENERIC_DE" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_GENERIC_DE"
        log_conditional "DEBUG" "Selected: generic German methodology"
    elif [[ -f "$METHODOLOGY_GENERIC_EN" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_GENERIC_EN"
        log_conditional "DEBUG" "Selected: generic English methodology"
    fi
else
    # English: try type-specific EN, then generic EN
    if [[ -f "$METHODOLOGY_TYPE_EN" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_TYPE_EN"
        log_conditional "DEBUG" "Selected: research-type-specific methodology (${RESEARCH_TYPE})"
    elif [[ -f "$METHODOLOGY_GENERIC_EN" ]]; then
        SELECTED_METHODOLOGY="$METHODOLOGY_GENERIC_EN"
        log_conditional "DEBUG" "Selected: generic methodology"
    fi
fi

# Copy selected methodology
if [[ -n "$SELECTED_METHODOLOGY" ]] && [[ -f "$SELECTED_METHODOLOGY" ]]; then
    cp "$SELECTED_METHODOLOGY" "$METHODOLOGY_DEST"
    log_conditional "DEBUG" "Copied research methodology to project: $(basename "$SELECTED_METHODOLOGY")"
else
    log_conditional "WARN" "Research methodology template not found"
fi

log_phase "Phase 5: Template Copying" "complete"

# ===== PHASE 6: README GENERATION =====
log_phase "Phase 6: README Generation" "start"

# Create README
readonly README="$PROJECT_PATH/README.md"
cat > "$README" <<EOF
# Research Project: $PROJECT_NAME

**Created**: $CREATED_TIMESTAMP
**Status**: Initialized

## Project Structure

This project follows the cogni-research entity pipeline architecture:

- \`00-initial-question/\` - Original research question and scope
- \`01-research-dimensions/\` - Dimensional analysis framework (MECE)
- \`02-refined-questions/\` - Atomic sub-questions per dimension
- \`03-query-batches/\` - Parallel search strategies
- \`04-findings/\` - Web + LLM research results
- \`05-sources/\` - Enriched sources (URL, publisher profile, APA citation)
- \`06-claims/\` - Verified assertions with three-layer confidence

See [[research-methodology]] for how to verify and trust the research findings.

All entities are connected via Obsidian wikilinks, creating a complete provenance graph from question to synthesis.

## Metadata

- \`.metadata/project-config.json\` - Project configuration
- \`.metadata/entity-index.json\` - Global entity index
- \`.metadata/sprint-log.json\` - Sprint history

## Usage

This project was created by the cogni-research Claude Code plugin.

To resume research: \`"Continue research on $PROJECT_NAME"\`

To generate synthesis: Research will generate \`research-hub.md\` in the project root.
EOF
log_conditional "DEBUG" "Created: README.md"
log_phase "Phase 6: README Generation" "complete"

# ===== FINAL METRICS =====
END_TIME="$(date +%s)"
DURATION=$((END_TIME - START_TIME))
log_metric "duration" "$DURATION" "seconds"
log_conditional "INFO" "Project initialization completed successfully"

# Return success
if [[ "$JSON_OUTPUT" == true ]]; then
    jq -n \
        --arg path "$PROJECT_PATH" \
        --arg name "$PROJECT_NAME" \
        --arg created "$CREATED_TIMESTAMP" \
        --arg language "$PROJECT_LANGUAGE" \
        --arg research_type "$RESEARCH_TYPE" \
        --argjson dirs "$(printf '%s\n' "${ENTITY_DIRS[@]}" | jq -R . | jq -s .)" \
        '{
            success: true,
            project_path: $path,
            project_name: $name,
            project_language: $language,
            research_type: $research_type,
            created: $created,
            entity_dirs: $dirs,
            metadata_files: [
                ".metadata/project-config.json",
                ".metadata/entity-index.json",
                ".metadata/sprint-log.json"
            ],
            readme: "README.md"
        }'
else
    echo "✓ Research project initialized successfully"
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Location: $PROJECT_PATH"
    echo "Language: $PROJECT_LANGUAGE"
    echo "Research Type: $RESEARCH_TYPE"
    echo ""
    echo "Entity directories created:"
    for dir in "${ENTITY_DIRS[@]}"; do
        echo "  - $dir/"
    done
    echo ""
    echo "Metadata files:"
    echo "  - .metadata/project-config.json"
    echo "  - .metadata/entity-index.json"
    echo "  - .metadata/sprint-log.json"
    echo "  - README.md"
fi

exit 0
