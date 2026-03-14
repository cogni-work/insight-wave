#!/usr/bin/env bash
set -euo pipefail
# repair-missing-batches.sh
# Version: 1.0.0
# Event: SubagentStop (findings-creator)
# Purpose: Detect and repair missing batch files after findings-creator
#
# Problem: LLM sometimes has batch in memory but never writes it to disk.
#          Findings get created with batch_ref pointing to non-existent batch.
#          Downstream processes (source-creator, publisher-creator) then fail.
#
# Solution: Scan findings for batch_refs, create minimal batch if missing.
#
# Exit codes:
#   0 - Success (no repairs needed OR repairs completed)
#   1 - Error during repair (logged but doesn't block)
#
# Environment:
#   CLAUDE_SUBAGENT_NAME - Agent name (set by Claude Code)
#   CLAUDE_SUBAGENT_OUTPUT - Agent output JSON (set by Claude Code)
#   CLAUDE_PLUGIN_ROOT - Plugin root directory


# Source entity configuration for directory key resolution (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"

# Only run for findings-creator agent
AGENT_NAME="${CLAUDE_SUBAGENT_NAME:-}"
! [[ "$AGENT_NAME" == "findings-creator" ]] && exit 0

# Get agent output
OUTPUT="${CLAUDE_SUBAGENT_OUTPUT:-}"
[[ -z "$OUTPUT" ]] && exit 0

# ============================================================================
# EXTRACT PROJECT PATH FROM AGENT OUTPUT
# ============================================================================

PROJECT_PATH=""

# Try to extract from JSON output
if echo "$OUTPUT" | jq -e '.' >/dev/null 2>&1; then
  # Direct JSON output
  PROJECT_PATH="$(echo "$OUTPUT" | jq -r '.project_path // ""' 2>/dev/null || echo "")"
fi

# Fallback: try to find project path in output text
if [[ -z "$PROJECT_PATH" ]] || [[ "$PROJECT_PATH" == "null" ]]; then
  # Look for common patterns in output
  PROJECT_PATH="$(echo "$OUTPUT" | grep -oE '/[^ ]+/0[0-9]-[^/]+' | head -1 | xargs dirname 2>/dev/null || echo "")"
fi

# Fallback: check CLAUDE_PROJECT_DIR
if [[ -z "$PROJECT_PATH" ]] && [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Look for deeper-research project structure
  for dir in "$CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"/*; do
    if [[ -d "$dir/$DIR_FINDINGS" ]] && [[ -d "$dir/$DIR_QUERY_BATCHES" ]]; then
      PROJECT_PATH="$dir"
      break
    fi
  done
fi

# Can't proceed without project path
if [[ -z "$PROJECT_PATH" ]] || [[ ! -d "$PROJECT_PATH" ]]; then
  echo "INFO: Cannot locate project path for batch repair check"
  exit 0
fi

# Verify project structure
if [[ ! -d "$PROJECT_PATH/$DIR_FINDINGS" ]]; then
  echo "INFO: No $DIR_FINDINGS directory found, skipping batch repair"
  exit 0
fi

# ============================================================================
# DETECT MISSING BATCHES
# ============================================================================

FINDINGS_DIR="$PROJECT_PATH/$DIR_FINDINGS"
BATCHES_DIR="$PROJECT_PATH/$DIR_QUERY_BATCHES"

# Ensure batches directory exists
mkdir -p "$BATCHES_DIR"

# Find all unique batch_refs in findings
# Format: batch_ref: "[[03-query-batches/data/batch-example-q1-b]]"
BATCH_REFS="$(grep -h '^batch_ref:' "$FINDINGS_DIR"/*.md 2>/dev/null | \
  sed 's/batch_ref: *"*\[\[//g; s/\]\]"*//g' | \
  sort -u || echo "")"

if [[ -z "$BATCH_REFS" ]]; then
  # No batch refs found - nothing to repair
  exit 0
fi

MISSING_BATCHES=()
REPAIRS_MADE=0

for batch_ref in $BATCH_REFS; do
  BATCH_FILE="${PROJECT_PATH}/${batch_ref}.md"
  if [[ ! -f "$BATCH_FILE" ]]; then
    MISSING_BATCHES+=("$batch_ref")
  fi
done

if [[ ${#MISSING_BATCHES[@]} -eq 0 ]]; then
  # All batches exist - nothing to repair
  exit 0
fi

# ============================================================================
# REPAIR FUNCTION
# ============================================================================

repair_batch() {
  local batch_ref="$1"
  local batch_id
  batch_id="$(basename "$batch_ref")"

  # Derive question_id from batch_id (remove -b suffix)
  local question_id="${batch_id%-b}"

  # Find findings that reference this batch
  local linked_findings
  linked_findings="$(grep -l "batch_ref:.*${batch_id}" "$FINDINGS_DIR"/*.md 2>/dev/null || echo "")"
  local findings_count
  findings_count="$(echo "$linked_findings" | grep -c '\.md$' || echo "0")"

  # Get question_ref from first finding (if available)
  local question_ref=""
  if [[ -n "$linked_findings" ]]; then
    local first_finding
    first_finding="$(echo "$linked_findings" | head -1)"
    if [[ -f "$first_finding" ]]; then
      question_ref="$(grep '^question_ref:' "$first_finding" 2>/dev/null | \
        sed 's/question_ref: *"*\[\[//; s/\]\]"*//' || echo "")"
    fi
  fi

  # Fallback: derive question_ref from question_id
  if [[ -z "$question_ref" ]]; then
    question_ref="${DIR_REFINED_QUESTIONS}/${question_id}"
  fi

  # Build linked findings list for content
  local findings_list=""
  if [[ -n "$linked_findings" ]]; then
    for finding in $linked_findings; do
      local finding_name
      finding_name="$(basename "$finding" .md)"
      findings_list="${findings_list}
- [[${DIR_FINDINGS}/data/${finding_name}]]"
    done
  fi

  # Create timestamp
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Build content
  local content="# Query Batch: ${batch_id}

**Refined Question**: [[${question_ref}]]

> **Note**: This batch was reconstructed from existing findings. Original search configurations are not available.

## Reconstruction Details

- **Reconstructed at**: ${timestamp}
- **Reason**: Batch file missing after findings-creator
- **Linked findings**: ${findings_count}

## Linked Findings
${findings_list}"

  # Create via create-entity.sh if available, otherwise direct write
  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" ]]; then
    # Use create-entity.sh for proper indexing
    local json_data
    json_data="$(jq -n \
      --arg batch_id "$batch_id" \
      --arg question_ref "[[${question_ref}]]" \
      --arg timestamp "$timestamp" \
      --arg content "$content" \
      '{
        "frontmatter": {
          "tags": ["query-batch", "research-batch", "reconstructed"],
          "entity_type": "query-batch",
          "batch_id": $batch_id,
          "question_ref": $question_ref,
          "search_configs": [{"config_id": ($batch_id + "-reconstructed"), "profile": "reconstructed", "tier": 1, "query_text": "Reconstructed - original query unavailable"}],
          "reconstructed": true,
          "reconstructed_at": $timestamp,
          "reconstructed_reason": "Batch file missing after findings-creator",
          "schema_version": "3.0.0"
        },
        "content": $content
      }')"

    bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
      --project-path "$PROJECT_PATH" \
      --entity-type "$DIR_QUERY_BATCHES" \
      --entity-id "$batch_id" \
      --data "$json_data" \
      --json >/dev/null 2>&1 || {
        echo "WARNING: create-entity.sh failed for ${batch_id}, attempting direct write" >&2
        # Fallback to direct write
        direct_write_batch "$batch_ref" "$batch_id" "$question_ref" "$timestamp" "$content"
      }
  else
    # Direct write (no create-entity.sh available)
    direct_write_batch "$batch_ref" "$batch_id" "$question_ref" "$timestamp" "$content"
  fi
}

direct_write_batch() {
  local batch_ref="$1"
  local batch_id="$2"
  local question_ref="$3"
  local timestamp="$4"
  local content="$5"

  local batch_file="${PROJECT_PATH}/${batch_ref}.md"

  cat > "$batch_file" << EOF
---
tags:
  - query-batch
  - research-batch
  - reconstructed
entity_type: query-batch
batch_id: "${batch_id}"
question_ref: "[[${question_ref}]]"
search_configs:
  - config_id: "${batch_id}-reconstructed"
    profile: "reconstructed"
    tier: 1
    query_text: "Reconstructed - original query unavailable"
reconstructed: true
reconstructed_at: "${timestamp}"
reconstructed_reason: "Batch file missing after findings-creator"
schema_version: "3.0.0"
---

${content}
EOF
}

# ============================================================================
# PERFORM REPAIRS
# ============================================================================

echo ""
echo "========================================"
echo "BATCH REPAIR INITIATED"
echo "========================================"
echo ""
echo "Detected ${#MISSING_BATCHES[@]} missing batch file(s)"
echo "Project: $PROJECT_PATH"
echo ""

for batch_ref in "${MISSING_BATCHES[@]}"; do
  echo "Repairing: ${batch_ref}.md"
  if repair_batch "$batch_ref"; then
    REPAIRS_MADE=$((REPAIRS_MADE + 1))
    echo "  ✓ Reconstructed successfully"
  else
    echo "  ✗ Failed to reconstruct"
  fi
done

echo ""
echo "========================================"
echo "BATCH REPAIR COMPLETED"
echo "========================================"
echo ""
echo "Repaired ${REPAIRS_MADE} of ${#MISSING_BATCHES[@]} missing batch file(s)"
echo ""
echo "Note: Reconstructed batches have empty search_configs."
echo "Original query configurations are not recoverable."
echo "========================================"
echo ""

exit 0
