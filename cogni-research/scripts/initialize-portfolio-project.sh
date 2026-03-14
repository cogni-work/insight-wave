#!/usr/bin/env bash
set -euo pipefail
# initialize-portfolio-project.sh
# DEPRECATED: Portfolio project initialization is now handled by cogni-portfolio:setup (2026-03-12)
# This script remains functional for existing cogni-research projects.
# Version: 1.0.0
# Purpose: Initialize new portfolio-mapping project with directory structure
# Category: utilities
#
# Usage:
#   initialize-portfolio-project.sh --project-name <name> --company-name <name> [OPTIONS]
#
# Arguments:
#   --project-name <name>      Project slug (required, kebab-case)
#   --company-name <name>      Company display name (required)
#   --company-slug <slug>      Company slug for filenames (optional, derived from company-name)
#   --projects-root <path>     Projects root directory (default: ${COGNI_RESEARCH_ROOT}/portfolios)
#   --json                     Output results in JSON format
#
# Environment Variables:
#   COGNI_RESEARCH_ROOT        Workspace root (set by workplace-manager)
#
# Returns:
#   JSON: {"success": true|false, "project_path": "...", "error": "..."}
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   initialize-portfolio-project.sh --project-name "portfolio-deutsche-telekom-a1b2c3d4" \
#     --company-name "Deutsche Telekom" --json


# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 2
fi

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Default configuration
readonly DEFAULT_PROJECTS_ROOT="${COGNI_RESEARCH_ROOT:-${HOME}/trend-projects}/portfolios"

# Parse arguments
PROJECT_NAME=""
COMPANY_NAME=""
COMPANY_SLUG=""
PROJECTS_ROOT="$DEFAULT_PROJECTS_ROOT"
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --company-name)
            COMPANY_NAME="$2"
            shift 2
            ;;
        --company-slug)
            COMPANY_SLUG="$2"
            shift 2
            ;;
        --projects-root)
            PROJECTS_ROOT="$2"
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
    fi
    exit 1
fi

if [[ -z "$COMPANY_NAME" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --company-name" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --company-name" >&2
    fi
    exit 1
fi

# Sanitize project name
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Invalid project name. Use only letters, numbers, hyphens, and underscores." \
            '{success: false, error: $error}'
    else
        echo "ERROR: Invalid project name '$PROJECT_NAME'" >&2
    fi
    exit 1
fi

# Derive company slug if not provided
if [[ -z "$COMPANY_SLUG" ]]; then
    COMPANY_SLUG="$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')"
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

# Construct project path
readonly PROJECT_PATH="$PROJECTS_ROOT/$PROJECT_NAME"

# Check if project already exists
if [[ -d "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n \
            --arg error "Project already exists: $PROJECT_PATH" \
            --arg path "$PROJECT_PATH" \
            '{success: false, error: $error, project_path: $path, exists: true}'
    else
        echo "ERROR: Project already exists: $PROJECT_PATH" >&2
    fi
    exit 1
fi

# Create project directory structure
mkdir -p "$PROJECT_PATH"
mkdir -p "$PROJECT_PATH/.metadata"
mkdir -p "$PROJECT_PATH/.logs"

# Generate timestamps
readonly CREATED_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Create portfolio-mapping-output.json (metadata file)
readonly OUTPUT_FILE="$PROJECT_PATH/.metadata/portfolio-mapping-output.json"
jq -n \
    --arg project_name "$PROJECT_NAME" \
    --arg project_path "$PROJECT_PATH" \
    --arg company_name "$COMPANY_NAME" \
    --arg company_slug "$COMPANY_SLUG" \
    --arg created "$CREATED_TIMESTAMP" \
    '{
        version: "1.0.0",
        project_slug: $project_name,
        company_name: $company_name,
        company_slug: $company_slug,
        created: $created,
        skill: "portfolio-mapping",
        output_file: ($company_slug + "-portfolio.md"),
        domains_analyzed: [],
        dimensions_covered: 0,
        categories_total: 57,
        status_summary: {
            confirmed: 0,
            not_offered: 0,
            emerging: 0,
            extended: 0
        },
        execution: {
            workflow_state: "initialized",
            current_phase: 0,
            phases_completed: []
        }
    }' > "$OUTPUT_FILE"

# Create README.md
readonly README="$PROJECT_PATH/README.md"
cat > "$README" <<EOF
# Portfolio Mapping: $COMPANY_NAME

**Company**: $COMPANY_NAME
**Created**: $CREATED_TIMESTAMP
**Status**: Initialized

## Project Structure

- \`.metadata/\` - Project configuration and outputs
  - \`portfolio-mapping-output.json\` - Execution metadata and status
- \`.logs/\` - Agent execution logs
  - \`portfolio-web-research-{domain}.json\` - Per-domain research results
- \`${COMPANY_SLUG}-portfolio.md\` - Main portfolio output (created in Phase 6)
- \`README.md\` - This file

## Usage

This project was created by the portfolio-mapping skill from the cogni-research plugin.

### Workflow Phases

1. **Phase 0**: Initialize project (completed)
2. **Phase 1**: Company discovery (subsidiaries, domains)
3. **Phase 2**: Provider profile discovery (Dimension 0)
4. **Phase 3**: Portfolio discovery via parallel agents (Dimensions 1-7)
5. **Phase 4**: Offering aggregation from agent logs
6. **Phase 5**: Discovery status assignment
7. **Phase 6**: Output generation

## Output

The final portfolio will be written to:
\`\`\`
${COMPANY_SLUG}-portfolio.md
\`\`\`

Contains 57 categories across 8 dimensions with full entity schema.
EOF

# Return success
if [[ "$JSON_OUTPUT" == true ]]; then
    jq -n \
        --arg path "$PROJECT_PATH" \
        --arg name "$PROJECT_NAME" \
        --arg company_name "$COMPANY_NAME" \
        --arg company_slug "$COMPANY_SLUG" \
        --arg created "$CREATED_TIMESTAMP" \
        --arg output_file "$OUTPUT_FILE" \
        --arg portfolio_file "${COMPANY_SLUG}-portfolio.md" \
        '{
            success: true,
            project_path: $path,
            project_name: $name,
            company_name: $company_name,
            company_slug: $company_slug,
            created: $created,
            output_file: $output_file,
            portfolio_file: $portfolio_file,
            directories: [".metadata", ".logs"],
            readme: "README.md"
        }'
else
    echo "✓ Portfolio mapping project initialized successfully"
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Company: $COMPANY_NAME"
    echo "Location: $PROJECT_PATH"
    echo ""
    echo "Files created:"
    echo "  - .metadata/portfolio-mapping-output.json"
    echo "  - .logs/ (empty)"
    echo "  - README.md"
fi

exit 0
