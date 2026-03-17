#!/usr/bin/env bash
set -euo pipefail
# pitch-status.sh
# Purpose: Report pitch project status from pitch-log.json
#
# Usage:
#   pitch-status.sh <project-path>
#
# Returns JSON with phase completion, claims count, and deliverable status.

if ! command -v jq &> /dev/null; then
    echo '{"error": "jq is required but not installed"}' >&2
    exit 1
fi

PROJECT_PATH="${1:-}"

if [ -z "$PROJECT_PATH" ]; then
    echo '{"error": "Missing required argument: project-path"}' >&2
    exit 1
fi

PITCH_LOG="$PROJECT_PATH/.metadata/pitch-log.json"

if [ ! -f "$PITCH_LOG" ]; then
    echo '{"error": "pitch-log.json not found", "project_path": "'"$PROJECT_PATH"'"}' >&2
    exit 1
fi

# Read pitch-log
SLUG=$(jq -r '.slug // "unknown"' "$PITCH_LOG")
CUSTOMER=$(jq -r '.customer_name // "unknown"' "$PITCH_LOG")
CURRENT_PHASE=$(jq -r '.workflow_state.current_phase // "unknown"' "$PITCH_LOG")
PHASES_COMPLETED=$(jq -c '.workflow_state.phases_completed // []' "$PITCH_LOG")
CLAIMS_COUNT=$(jq -r '.workflow_state.claims_registered // 0' "$PITCH_LOG")

# Check deliverables
PRESENTATION_READY=false
PROPOSAL_READY=false
if [ -f "$PROJECT_PATH/output/sales-presentation.md" ]; then
    PRESENTATION_READY=true
fi
if [ -f "$PROJECT_PATH/output/sales-proposal.md" ]; then
    PROPOSAL_READY=true
fi

jq -n \
    --arg slug "$SLUG" \
    --arg customer "$CUSTOMER" \
    --arg current_phase "$CURRENT_PHASE" \
    --argjson phases_completed "$PHASES_COMPLETED" \
    --argjson claims "$CLAIMS_COUNT" \
    --argjson presentation "$PRESENTATION_READY" \
    --argjson proposal "$PROPOSAL_READY" \
    '{
        slug: $slug,
        customer: $customer,
        current_phase: $current_phase,
        phases_completed: $phases_completed,
        claims_registered: $claims,
        deliverables: {
            sales_presentation: $presentation,
            sales_proposal: $proposal
        }
    }'

exit 0
