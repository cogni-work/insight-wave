#!/usr/bin/env bash
set -euo pipefail
# initialize-trend-project.sh
# Version: 1.0.0
# Purpose: Initialize new TIPS project with directory structure for tips-generator skill
# Category: utilities
#
# Usage:
#   initialize-trend-project.sh --project-name <name> [OPTIONS]
#
# Arguments:
#   --project-name <name>      Project name (required, kebab-case)
#   --industry <industry>      Industry name for metadata (optional)
#   --skill-dir <dir>          Skill-specific subdirectory (e.g., "cogni-tips")
#   --projects-root <path>     Projects root directory (default: current working directory)
#   --language <code>          Project language (ISO 639-1 code, default: "en")
#   --json                     Output results in JSON format
#
# Environment Variables:
#   COGNI_WORKSPACE_ROOT    Optional workspace root override (default: current directory)
#
# Returns:
#   JSON: {"success": true|false, "project_path": "...", "directories": [...], "error": "..."}
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   initialize-trend-project.sh --project-name "tips-manufacturing-2025" \
#     --industry "manufacturing" --json


# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 2
fi

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Default configuration
readonly DEFAULT_PROJECTS_ROOT="${COGNI_WORKSPACE_ROOT:-$(pwd)}"

# Parse arguments
PROJECT_NAME=""
INDUSTRY=""
SKILL_DIR=""
PROJECTS_ROOT="$DEFAULT_PROJECTS_ROOT"
PROJECT_LANGUAGE="en"
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --industry)
            INDUSTRY="$2"
            shift 2
            ;;
        --projects-root)
            PROJECTS_ROOT="$2"
            shift 2
            ;;
        --skill-dir)
            SKILL_DIR="$2"
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

# Validation
if [[ -z "$PROJECT_NAME" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --project-name" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --project-name" >&2
        echo "Usage: $SCRIPT_NAME --project-name <name> [--industry <industry>] [--json]" >&2
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

# Create projects root if it doesn't exist
if [[ ! -d "$PROJECTS_ROOT" ]]; then
    mkdir -p "$PROJECTS_ROOT" || {
        if [[ "$JSON_OUTPUT" == true ]]; then
            jq -n --arg error "Failed to create projects root: $PROJECTS_ROOT" \
                '{success: false, error: $error}'
        else
            echo "ERROR: Failed to create projects root: $PROJECTS_ROOT" >&2
        fi
        exit 1
    }
fi

# Generate normalized project ID
readonly PROJECT_ID="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"

# Construct project path (with optional skill-specific subdirectory)
if [[ -n "$SKILL_DIR" ]]; then
    readonly PROJECT_PATH="$PROJECTS_ROOT/$SKILL_DIR/$PROJECT_NAME"
else
    readonly PROJECT_PATH="$PROJECTS_ROOT/$PROJECT_NAME"
fi

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

# Create project directory structure
mkdir -p "$PROJECT_PATH"

# TIPS-specific directories (simplified structure)
readonly TIPS_DIRS=(
    ".metadata"
)

# Create all directories
for dir in "${TIPS_DIRS[@]}"; do
    mkdir -p "$PROJECT_PATH/$dir"
done

# Generate timestamps
readonly CREATED_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Create consolidated trend-scout-output.json
readonly OUTPUT_FILE="$PROJECT_PATH/.metadata/trend-scout-output.json"
jq -n \
    --arg project_id "$PROJECT_ID" \
    --arg project_name "$PROJECT_NAME" \
    --arg project_path "$PROJECT_PATH" \
    --arg industry "${INDUSTRY:-unspecified}" \
    --arg project_language "$PROJECT_LANGUAGE" \
    --arg created "$CREATED_TIMESTAMP" \
    '{
        version: "1.0.0",
        project_id: $project_id,
        project_name: $project_name,
        project_path: $project_path,
        project_language: $project_language,
        created: $created,

        config: {
            research_type: "smarter-service",
            dok_level: 4,
            industry: {
                primary: $industry,
                primary_en: null,
                primary_de: null,
                subsector: null,
                subsector_en: null,
                subsector_de: null
            },
            research_topic: null,
            organizing_concept: null
        },

        tips_candidates: {
            total: 0,
            source_distribution: {
                web_signal: 0,
                training: 0,
                user_proposed: 0
            },
            web_research_status: "pending",
            search_timestamp: null,
            items: []
        },

        execution: {
            workflow_state: "initialized",
            current_phase: 0,
            phases_completed: []
        },

        deeper_analysis_integration: {
            source_type: "trend-scout",
            auto_load_candidates: true,
            skip_tips_selection: true,
            auto_configure_research_type: true,
            auto_configure_dok_level: true,
            auto_configure_language: true
        }
    }' > "$OUTPUT_FILE"

# Create README.md
readonly README="$PROJECT_PATH/README.md"
cat > "$README" <<EOF
# TIPS Scout Project: $PROJECT_NAME

**Industry**: ${INDUSTRY:-Not specified}
**Created**: $CREATED_TIMESTAMP
**Status**: Initialized

## Project Structure

- \`.metadata/\` - Project configuration and outputs
  - \`trend-scout-output.json\` - Consolidated output (config, candidates, execution state)
- \`trend-candidates.md\` - User-facing candidate selection file (created in Phase 3)
- \`README.md\` - This file

## Usage

This project was created by the trend-scout skill from the cogni-tips plugin.

### Next Steps
1. Run trend-scout to generate trend candidates
2. Review and select candidates in trend-candidates.md
3. Pass to deeper-research-1 using: \`tips_source: $PROJECT_PATH/.metadata/trend-scout-output.json\`

## Integration with deeper-research-1

After completing trend-scout, invoke deeper-research-1 with:
\`\`\`
tips_source: $PROJECT_PATH/.metadata/trend-scout-output.json
\`\`\`
EOF

# Return success
if [[ "$JSON_OUTPUT" == true ]]; then
    jq -n \
        --arg path "$PROJECT_PATH" \
        --arg name "$PROJECT_NAME" \
        --arg industry "${INDUSTRY:-unspecified}" \
        --arg language "$PROJECT_LANGUAGE" \
        --arg created "$CREATED_TIMESTAMP" \
        --arg output_file "$OUTPUT_FILE" \
        --argjson dirs "$(printf '%s\n' "${TIPS_DIRS[@]}" | jq -R . | jq -s .)" \
        '{
            success: true,
            project_path: $path,
            project_name: $name,
            industry: $industry,
            project_language: $language,
            created: $created,
            directories: $dirs,
            output_file: $output_file,
            readme: "README.md"
        }'
else
    echo "✓ TIPS Scout project initialized successfully"
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Location: $PROJECT_PATH"
    echo "Industry: ${INDUSTRY:-Not specified}"
    echo "Language: $PROJECT_LANGUAGE"
    echo ""
    echo "Files created:"
    echo "  - .metadata/trend-scout-output.json"
    echo "  - README.md"
fi

exit 0
