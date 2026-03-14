#!/usr/bin/env bash
set -euo pipefail
# verify-source-creator-output.sh
# Anti-hallucination hook for source-creator agent with AUTO-RECOVERY
# Version: 2.0.0
#
# Purpose: Validates source-creator output against filesystem reality
# When hallucination detected, automatically executes script.sh as recovery
#
# Trigger: SubagentStop when source-creator agent completes
#
# Detection Patterns (hallucination indicators):
# 1. Statistics claim sources_created > 0 but 07-sources/ is empty
# 2. Performance > 100 findings/minute (impossibly fast for real script)
# 3. findings_updated > 0 but findings still have empty source_id
# 4. Execution log format doesn't match real script format
#
# Recovery: When hallucination detected, executes script.sh directly
#
# Exit codes:
#   0 - Validation passed or recovery succeeded
#   1 - Recovery failed

set -e

# Source centralized entity config (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_SOURCES="$(get_directory_by_key "sources")"

# Only run for source-creator agent
AGENT_NAME="${CLAUDE_SUBAGENT_NAME:-}"
! [[ "$AGENT_NAME" == "source-creator" ]] && exit 0

# Get agent output
OUTPUT="${CLAUDE_SUBAGENT_OUTPUT:-}"
[[ -z "$OUTPUT" ]] && exit 0

# Try to extract JSON from output
JSON_OUTPUT=""
if echo "$OUTPUT" | jq -e '.' >/dev/null 2>&1; then
  JSON_OUTPUT="$OUTPUT"
else
  # Try to extract JSON from mixed output
  JSON_OUTPUT="$(echo "$OUTPUT" | grep -E '^\{' | tail -1 2>/dev/null || echo "")"
fi

[[ -z "$JSON_OUTPUT" ]] && {
  echo "WARNING: No JSON output from source-creator"
  exit 0  # Can't verify without JSON
}

# Extract claimed metrics
CLAIMED_SOURCES="$(echo "$JSON_OUTPUT" | jq -r '.sources_created // 0')"
CLAIMED_UPDATED="$(echo "$JSON_OUTPUT" | jq -r '.findings_updated // 0')"
CLAIMED_SUCCESS="$(echo "$JSON_OUTPUT" | jq -r '.success // false')"
VALIDATION_PASSED="$(echo "$JSON_OUTPUT" | jq -r '.validation_passed // false')"

# Early exit if no claims
[[ "$CLAIMED_SOURCES" == "0" ]] && [[ "$CLAIMED_UPDATED" == "0" ]] && exit 0

# Try to find project path from context
PROJECT_PATH=""

# Check common locations based on current directory
if [[ -d "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Look for deeper-research project structure
  for dir in "$CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"/*; do
    if [[ -d "$dir/${DIR_FINDINGS}/${DATA_SUBDIR}" ]] && [[ -d "$dir/${DIR_SOURCES}/${DATA_SUBDIR}" || -f "$dir/.metadata/entity-index.json" ]]; then
      PROJECT_PATH="$dir"
      break
    fi
  done
fi

# If no project found, try extracting from output
if [[ -z "$PROJECT_PATH" ]]; then
  STATS_FILE="$(echo "$JSON_OUTPUT" | jq -r '.stats_file // ""')"
  if [[ -n "$STATS_FILE" ]] && ! [[ "$STATS_FILE" == "null" ]]; then
    # Try to find stats file
    for base in "$CLAUDE_PROJECT_DIR" "$HOME/GitHub" "$HOME"; do
      CANDIDATE="$(find "$base" -name "source-creator-statistics.json" -type f 2>/dev/null | head -1)"
      if [[ -n "$CANDIDATE" ]]; then
        PROJECT_PATH="$(dirname "$(dirname "$CANDIDATE")")"
        break
      fi
    done
  fi
fi

# Can't verify without project path
[[ -z "$PROJECT_PATH" ]] && {
  echo "INFO: Cannot locate project path for verification"
  exit 0
}

# ============================================================================
# ANTI-HALLUCINATION CHECKS
# ============================================================================

HALLUCINATION_DETECTED=false
HALLUCINATION_REASONS=""

# CHECK 1: Verify sources actually exist
if [[ "$CLAIMED_SOURCES" -gt 0 ]]; then
  if [[ -d "$PROJECT_PATH/07-sources/${DATA_SUBDIR}" ]]; then
    ACTUAL_SOURCES="$(find "$PROJECT_PATH/07-sources/${DATA_SUBDIR}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$ACTUAL_SOURCES" -eq 0 ]]; then
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_SOURCES sources created but 07-sources/${DATA_SUBDIR}/ is EMPTY"
    elif [[ "$ACTUAL_SOURCES" -lt $(($CLAIMED_SOURCES / 2)) ]]; then
      # Allow some tolerance but flag if way off
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_SOURCES sources but only $ACTUAL_SOURCES exist (>50% missing)"
    fi
  else
    HALLUCINATION_DETECTED=true
    HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_SOURCES sources but 07-sources/${DATA_SUBDIR}/ directory doesn't exist"
  fi
fi

# CHECK 2: Verify findings have source_id (sample check)
if [[ "$CLAIMED_UPDATED" -gt 0 ]] && [[ -d "$PROJECT_PATH/04-findings/${DATA_SUBDIR}" ]]; then
  EMPTY_SOURCE_IDS="$(grep -l '^source_id: ""' "$PROJECT_PATH/04-findings/${DATA_SUBDIR}"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  TOTAL_FINDINGS="$(find "$PROJECT_PATH/04-findings/${DATA_SUBDIR}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

  if [[ "$TOTAL_FINDINGS" -gt 0 ]]; then
    # If most findings still have empty source_id, hallucination likely
    UPDATED_FINDINGS=$(($TOTAL_FINDINGS - $EMPTY_SOURCE_IDS))

    if [[ "$CLAIMED_UPDATED" -gt 0 ]] && [[ "$UPDATED_FINDINGS" -lt $(($CLAIMED_UPDATED / 2)) ]]; then
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_UPDATED findings updated but only $UPDATED_FINDINGS have non-empty source_id"
    fi
  fi
fi

# CHECK 3: Verify execution log format (detect fake logs)
LOG_FILE="$PROJECT_PATH/.logs/source-creator-execution-log.txt"
if [[ -f "$LOG_FILE" ]] && [[ "$CLAIMED_SOURCES" -gt 0 ]]; then
  # Real script logs: "Phase 3.5: Source Entity Creation - Creating source-xxx"
  # Fake logs: "[PROCESS] finding-xxx -> source-xxx-content"

  REAL_LOG_ENTRIES="$(grep -c "Phase 3.5: Source Entity Creation" "$LOG_FILE" 2>/dev/null || echo 0)"
  FAKE_LOG_ENTRIES="$(grep -c '^\[.*\] \[PROCESS\]' "$LOG_FILE" 2>/dev/null || echo 0)"

  if [[ "$FAKE_LOG_ENTRIES" -gt 10 ]] && [[ "$REAL_LOG_ENTRIES" -eq 0 ]]; then
    HALLUCINATION_DETECTED=true
    HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Execution log contains simulated [PROCESS] entries instead of real script output"
  fi
fi

# CHECK 4: Performance sanity check (from stats file)
STATS_FILE="$PROJECT_PATH/.logs/source-creator-statistics.json"
if [[ -f "$STATS_FILE" ]]; then
  # Check for impossibly fast execution
  STATS_JSON="$(cat "$STATS_FILE" 2>/dev/null)"

  # If processing rate is in stats, check it
  PROCESSING_RATE="$(echo "$STATS_JSON" | jq -r '.findings_per_minute // 0' 2>/dev/null || echo 0)"

  # Real script: ~2-5 findings/minute (with all the create-entity.sh calls)
  # Hallucinated: 1000+ findings/minute (impossible)
  if [[ "$PROCESSING_RATE" =~ ^[0-9]+$ ]] && [[ "$PROCESSING_RATE" -gt 500 ]]; then
    HALLUCINATION_DETECTED=true
    HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Processing rate of $PROCESSING_RATE findings/min is impossibly fast (real script: 2-5/min)"
  fi
fi

# ============================================================================
# VERDICT AND AUTO-RECOVERY
# ============================================================================

if [[ "$HALLUCINATION_DETECTED" == true ]]; then
  echo ""
  echo "========================================"
  echo "ANTI-HALLUCINATION GATE TRIGGERED"
  echo "========================================"
  echo ""
  echo "The source-creator agent appears to have SIMULATED execution"
  echo "without actually creating files. Initiating AUTO-RECOVERY..."
  echo ""
  echo "Detection reasons:"
  echo -e "$HALLUCINATION_REASONS"
  echo ""
  echo "Project: $PROJECT_PATH"
  echo "Claimed sources: $CLAIMED_SOURCES"
  echo "Claimed updated: $CLAIMED_UPDATED"
  echo ""

  # ============================================================================
  # AUTO-RECOVERY: Execute script.sh directly
  # ============================================================================

  echo "========================================"
  echo "EXECUTING AUTO-RECOVERY"
  echo "========================================"
  echo ""

  # Build finding files list and write to file (file-based contract)
  FINDING_LIST_FILE="$PROJECT_PATH/.metadata/recovery-finding-list.txt"
  mkdir -p "$PROJECT_PATH/.metadata"
  find "$PROJECT_PATH/04-findings/${DATA_SUBDIR}" -name '*.md' -type f 2>/dev/null > "$FINDING_LIST_FILE"

  if [[ ! -s "$FINDING_LIST_FILE" ]]; then
    echo "ERROR: No findings found in $PROJECT_PATH/04-findings/${DATA_SUBDIR}"
    echo "Cannot proceed with recovery"
    exit 2
  fi

  FINDING_COUNT="$(wc -l < "$FINDING_LIST_FILE" | tr -d ' ')"
  echo "Found $FINDING_COUNT findings to process"
  echo ""

  # Determine CLAUDE_PLUGIN_ROOT
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
  if [[ -z "$PLUGIN_ROOT" ]] || [[ ! -f "$PLUGIN_ROOT/scripts/source-creator.sh" ]]; then
    echo "ERROR: Cannot locate source-creator.sh"
    echo "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT:-not set}"
    echo ""
    echo "MANUAL RECOVERY: Run the bash script directly:"
    echo ""
    echo "  export CLAUDE_PLUGIN_ROOT=\$HOME/.claude/plugins/marketplaces/cogni-research"
    echo "  find $PROJECT_PATH/04-findings -name '*.md' -type f > $PROJECT_PATH/.metadata/finding-list.txt"
    echo "  DEBUG_MODE=true bash \"\$CLAUDE_PLUGIN_ROOT/scripts/source-creator.sh\" \\"
    echo "    --project-path $PROJECT_PATH \\"
    echo "    --finding-list-file $PROJECT_PATH/.metadata/finding-list.txt --language en"
    echo ""
    exit 2
  fi

  SCRIPT_PATH="$PLUGIN_ROOT/scripts/source-creator.sh"
  echo "Executing: $SCRIPT_PATH"
  echo "Project: $PROJECT_PATH"
  echo "Findings: $FINDING_COUNT files"
  echo ""

  # Execute script with recovery flag in environment
  export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
  export RECOVERY_MODE=true

  RECOVERY_OUTPUT="$(bash "$SCRIPT_PATH" \
    --project-path "$PROJECT_PATH" \
    --finding-list-file "$FINDING_LIST_FILE" \
    --language "en" 2>&1)" || {
      RECOVERY_EXIT=$?
      echo "ERROR: Recovery script failed with exit code $RECOVERY_EXIT"
      echo "Output: $RECOVERY_OUTPUT"
      exit 2
    }

  echo ""
  echo "========================================"
  echo "RECOVERY COMPLETE"
  echo "========================================"
  echo ""
  echo "$RECOVERY_OUTPUT"
  echo ""

  # Verify recovery succeeded
  RECOVERED_SOURCES="$(find "$PROJECT_PATH/07-sources/${DATA_SUBDIR}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
  echo "Verification: $RECOVERED_SOURCES source files now exist in 07-sources/${DATA_SUBDIR}/"

  if [[ "$RECOVERED_SOURCES" -gt 0 ]]; then
    echo "Recovery successful - workflow can continue"
    exit 0  # Success after recovery
  else
    echo "WARNING: Recovery completed but no sources created"
    echo "This may indicate all findings were legitimately skipped (no-results, invalid URLs, etc.)"
    exit 0  # Still allow workflow to continue
  fi
fi

echo "Anti-hallucination verification passed for source-creator"
exit 0
