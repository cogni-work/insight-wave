#!/usr/bin/env bash
set -euo pipefail
# init-pitch-project.sh
# Purpose: Scaffold a new pitch project directory for cogni-sales
#
# Usage:
#   init-pitch-project.sh --customer-name <name> --language <en|de> --workspace <path>
#   init-pitch-project.sh --segment-name <name> --pitch-mode segment --language <en|de> --workspace <path>
#
# Returns JSON:
#   {"success": true, "project_path": "...", "slug": "...", "pitch_mode": "..."}

if ! command -v jq &> /dev/null; then
    echo '{"success": false, "error": "jq is required but not installed"}' >&2
    exit 1
fi

# Parse arguments
CUSTOMER_NAME=""
SEGMENT_NAME=""
PITCH_MODE="customer"
LANGUAGE="en"
WORKSPACE="$(pwd)"

while [ $# -gt 0 ]; do
    case $1 in
        --customer-name)
            CUSTOMER_NAME="$2"
            shift 2
            ;;
        --segment-name)
            SEGMENT_NAME="$2"
            shift 2
            ;;
        --pitch-mode)
            PITCH_MODE="$2"
            shift 2
            ;;
        --language)
            LANGUAGE="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Validate mode and required args
if [ "$PITCH_MODE" = "segment" ]; then
    if [ -z "$SEGMENT_NAME" ]; then
        jq -n '{success: false, error: "Missing required argument: --segment-name (required for segment mode)"}'
        exit 1
    fi
    TARGET_NAME="$SEGMENT_NAME"
elif [ "$PITCH_MODE" = "customer" ]; then
    if [ -z "$CUSTOMER_NAME" ]; then
        jq -n '{success: false, error: "Missing required argument: --customer-name (required for customer mode)"}'
        exit 1
    fi
    TARGET_NAME="$CUSTOMER_NAME"
else
    jq -n --arg mode "$PITCH_MODE" '{success: false, error: ("Invalid pitch mode: " + $mode + ". Use customer or segment")}'
    exit 1
fi

# Generate kebab-case slug
generate_slug() {
    echo "$1" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g' | \
        sed 's/[^a-z0-9]/-/g' | \
        sed 's/-\{2,\}/-/g' | \
        sed 's/^-//; s/-$//'
}

SLUG=$(generate_slug "$TARGET_NAME" | cut -c1-50)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Resolve workspace to absolute path
case "$WORKSPACE" in
    /*) ;;
    *)  WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" ;;
esac

# Project path: nest under cogni-sales/{customer-or-market-slug}/{project-slug}
SALES_ROOT="${WORKSPACE}/cogni-sales"
if [ "$PITCH_MODE" = "segment" ]; then
    PROJECT_PATH="${SALES_ROOT}/${SLUG}/segment-pitch"
else
    PROJECT_PATH="${SALES_ROOT}/${SLUG}/pitch"
fi

# Check if project already exists
if [ -d "$PROJECT_PATH" ]; then
    jq -n \
        --arg path "$PROJECT_PATH" \
        --arg slug "$SLUG" \
        '{success: false, exists: true, project_path: $path, slug: $slug, error: "Project already exists"}'
    exit 1
fi

# Create directory structure
mkdir -p "$PROJECT_PATH/.metadata"
mkdir -p "$PROJECT_PATH/01-why-change"
mkdir -p "$PROJECT_PATH/02-why-now"
mkdir -p "$PROJECT_PATH/03-why-you"
mkdir -p "$PROJECT_PATH/04-why-pay"
mkdir -p "$PROJECT_PATH/output"

# Initialize pitch-log.json (minimal — skill enriches after setup)
if [ "$PITCH_MODE" = "segment" ]; then
    jq -n \
        --arg slug "$SLUG" \
        --arg segment "$SEGMENT_NAME" \
        --arg language "$LANGUAGE" \
        --arg created "$TIMESTAMP" \
        '{
            schema_version: "1.1",
            pitch_mode: "segment",
            slug: $slug,
            segment_name: $segment,
            customer_name: null,
            customer_domain: null,
            customer_industry: null,
            market_slug: null,
            portfolio_path: null,
            tips_path: null,
            company_name: null,
            language: $language,
            solution_focus: [],
            buying_center: {
                economic_buyer: {title: null, priorities: []},
                technical_evaluator: {title: null, priorities: []},
                end_users: [],
                champion: null
            },
            workflow_state: {
                current_phase: "setup",
                phases_completed: [],
                claims_registered: 0
            },
            created_at: $created
        }' > "$PROJECT_PATH/.metadata/pitch-log.json"
else
    jq -n \
        --arg slug "$SLUG" \
        --arg customer "$CUSTOMER_NAME" \
        --arg language "$LANGUAGE" \
        --arg created "$TIMESTAMP" \
        '{
            schema_version: "1.1",
            pitch_mode: "customer",
            slug: $slug,
            segment_name: null,
            customer_name: $customer,
            customer_domain: null,
            customer_industry: null,
            market_slug: null,
            portfolio_path: null,
            tips_path: null,
            company_name: null,
            language: $language,
            solution_focus: [],
            buying_center: {
                economic_buyer: {title: null, priorities: []},
                technical_evaluator: {title: null, priorities: []},
                end_users: [],
                champion: null
            },
            workflow_state: {
                current_phase: "setup",
                phases_completed: [],
                claims_registered: 0
            },
            created_at: $created
        }' > "$PROJECT_PATH/.metadata/pitch-log.json"
fi

# Output result
jq -n \
    --arg path "$PROJECT_PATH" \
    --arg slug "$SLUG" \
    --arg mode "$PITCH_MODE" \
    '{success: true, project_path: $path, slug: $slug, pitch_mode: $mode}'

exit 0
