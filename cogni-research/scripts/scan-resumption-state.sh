#!/usr/bin/env bash
set -euo pipefail
# scan-resumption-state.sh
# Version: 1.0.0
# Purpose: Scan filesystem to determine resumption state for batch processing phases
# Category: validation
#
# Answers "what work items are already done?" for Phase 3 (findings) or Phase 7 (claims).
# Delegates to Python backend (scan_resumption_state.py) for actual scanning.
#
# Usage: scan-resumption-state.sh --project-path <path> --phase <3|7> [--json]
#
# Arguments:
#   --project-path <path>  Path to research project directory (required)
#   --phase <3|7>          Phase to scan: 3 (findings) or 7 (claims) (required)
#   --json                 Output JSON format (default, always JSON)
#
# Output: Compact JSON summary (single line)
#   Phase 3:
#   {
#     "success": true,
#     "phase": 3,
#     "total_questions": 46,
#     "completed_questions": 30,
#     "pending_questions": ["question-foo-abc123", ...],
#     "completed_question_ids": ["question-bar-def456", ...],
#     "recommendation": "FULL_RUN"|"RESUME"|"COMPLETE"
#   }
#
#   Phase 7:
#   {
#     "success": true,
#     "phase": 7,
#     "total_findings": 120,
#     "completed_findings": 80,
#     "pending_finding_ids": ["finding-foo-abc123", ...],
#     "pending_finding_paths": ["/path/to/finding-foo-abc123.md", ...],
#     "recommendation": "FULL_RUN"|"RESUME"|"COMPLETE"
#   }
#
# Exit codes:
#   0 - Success (any recommendation)
#   1 - Error (invalid path, missing directories)
#   2 - Invalid parameters

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# PARAMETER PARSING
# ============================================================================

PROJECT_PATH=""
PHASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --json)
      # Always JSON, accepted for compatibility
      shift
      ;;
    --help|-h)
      echo "Usage: scan-resumption-state.sh --project-path <path> --phase <3|7> [--json]"
      exit 0
      ;;
    *)
      echo '{"success":false,"error":"Unknown parameter: '"$1"'"}'
      exit 2
      ;;
  esac
done

if [[ -z "$PROJECT_PATH" ]]; then
  echo '{"success":false,"error":"Missing --project-path"}'
  exit 2
fi

if [[ -z "$PHASE" ]]; then
  echo '{"success":false,"error":"Missing --phase"}'
  exit 2
fi

if [[ "$PHASE" != "3" ]] && [[ "$PHASE" != "7" ]]; then
  echo '{"success":false,"error":"Invalid --phase: must be 3 or 7"}'
  exit 2
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo '{"success":false,"error":"Project path not found: '"$PROJECT_PATH"'"}'
  exit 1
fi

# ============================================================================
# DELEGATE TO PYTHON BACKEND
# ============================================================================

exec python3 "${SCRIPT_DIR}/scan_resumption_state.py" \
  --project-path "$PROJECT_PATH" \
  --phase "$PHASE" \
  --json
