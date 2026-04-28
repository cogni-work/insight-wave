#!/usr/bin/env bash
set -euo pipefail
# prepare-phase3-data.sh
# Version: 2.1.0
# Purpose: Generate compact candidate data for Phase 3 of trend-scout
# Category: utilities
#
# Usage: prepare-phase3-data.sh <PROJECT_PATH>
#
# Arguments:
#   PROJECT_PATH  Absolute path to project directory (required)
#
# Outputs:
#   - ${PROJECT_PATH}/.logs/candidates-compact.json (compact for Claude reading)
#
# Dependencies: jq, python3
#
# Exit codes:
#   0 = success
#   1 = missing PROJECT_PATH argument
#   2 = candidates file not found
#   3 = jq not available
#   4 = candidates file is invalid JSON (after sanitize pass)


# Validate arguments
if [[ -z "${1:-}" ]]; then
    echo '{"ok":false,"error":"missing_project_path","message":"Usage: prepare-phase3-data.sh <PROJECT_PATH>"}'
    exit 1
fi

PROJECT_PATH="$1"
CANDIDATES_FILE="${PROJECT_PATH}/.logs/trend-generator-candidates.json"

# Validate dependencies
if ! command -v jq &>/dev/null; then
    echo '{"ok":false,"error":"jq_not_found","message":"jq is required but not installed"}'
    exit 3
fi

# Validate input file exists
if [[ ! -f "$CANDIDATES_FILE" ]]; then
    echo "{\"ok\":false,\"error\":\"candidates_not_found\",\"message\":\"File not found: ${CANDIDATES_FILE}\"}"
    exit 2
fi

# Sanitize mixed German typographic / ASCII quote pairs in place — but JSON-safely.
# Pattern: U+201E opener `„` followed by ASCII U+0022 closer `"` with no intervening
# U+201D `"`. The naive regex `„([^"\\]*)"` is unsafe on already-valid files because
# in a clean payload the next ASCII `"` after `„text”` is the JSON string delimiter
# itself — running the regex would replace the delimiter with U+201D and break JSON
# that was previously fine.
#
# So: parse the file as JSON first. If it parses cleanly, no sanitize is needed.
# Only when parse fails do we attempt the regex repair, and we only persist the
# repaired file if it produces valid JSON. This makes the step both idempotent
# (clean input → no-op) and safe (a regex that doesn't actually fix the file
# never overwrites the original).
#
# See cogni-trends issue #169 for the original reproduction.
python3 - "$CANDIDATES_FILE" >&2 <<'PY'
import json, re, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
try:
    json.loads(content)
    sys.exit(0)  # already valid — no sanitize needed
except json.JSONDecodeError:
    pass
fixed, n = re.subn(r'„([^"\\]*)"', '„\\1”', content)
if n == 0:
    sys.exit(0)  # parse failure not caused by mixed quotes — leave for the validator
try:
    json.loads(fixed)
except json.JSONDecodeError:
    sys.exit(0)  # sanitize did not produce valid JSON — do not persist
with open(path, 'w', encoding='utf-8') as f:
    f.write(fixed)
print(f"prepare-phase3-data: sanitized {n} mixed-quote pair(s) in {path}", file=sys.stderr)
PY

# Pre-validate the sanitized file as parseable JSON before handing to jq.
# `jq` exits cryptically on parse errors; surfacing the failing line/column here
# turns a silent 0-byte output into an actionable diagnostic.
if ! VALIDATE_OUT=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        json.load(f)
except json.JSONDecodeError as e:
    sys.stderr.write(f"line {e.lineno} column {e.colno}: {e.msg}\n")
    sys.exit(1)
except Exception as e:
    sys.stderr.write(f"line 0 column 0: {type(e).__name__}: {e}\n")
    sys.exit(1)
' "$CANDIDATES_FILE" 2>&1); then
    # Parse line/column out of the structured error message.
    LINE=$(echo "$VALIDATE_OUT" | grep -oE 'line [0-9]+' | head -1 | grep -oE '[0-9]+' || echo "0")
    COL=$(echo "$VALIDATE_OUT" | grep -oE 'column [0-9]+' | head -1 | grep -oE '[0-9]+' || echo "0")
    MSG=$(echo "$VALIDATE_OUT" | tr -d '\n' | sed 's/"/\\"/g')
    echo "{\"ok\":false,\"error\":\"invalid_json\",\"file\":\"${CANDIDATES_FILE}\",\"line\":${LINE},\"column\":${COL},\"message\":\"${MSG}\"}"
    exit 4
fi
unset VALIDATE_OUT LINE COL MSG

# Ensure output directories exist
mkdir -p "${PROJECT_PATH}/.logs"

# Generate compact version for Claude (~8-10K tokens instead of ~27K)
# Uses short keys to minimize token usage while preserving all Phase 3 required fields
jq '{
  meta: {
    ts: .generation_metadata.timestamp,
    subsector: .generation_metadata.subsector,
    total: .generation_metadata.total_candidates
  },
  c: [
    (.candidates_by_dimension // .candidates_by_cell) | to_entries[] | .value | to_entries[] |
    # Sort by score descending within each cell
    (.value | sort_by(-.score) | to_entries) | .[] |
    {
      d: .value.dimension,
      h: .value.horizon,
      n: .value.name,
      s: .value.trend_statement,
      r: .value.research_hint,
      k: .value.keywords,
      sc: .value.score,
      ct: .value.confidence_tier,
      si: .value.signal_intensity,
      src: .value.source,
      url: .value.source_url
    }
  ] | sort_by(.d, .h, -.sc)
}' "$CANDIDATES_FILE" > "${PROJECT_PATH}/.logs/candidates-compact.json"

# Calculate file size for verification
COMPACT_SIZE=$(wc -c < "${PROJECT_PATH}/.logs/candidates-compact.json" | tr -d ' ')

# Output success JSON
echo "{\"ok\":true,\"files\":{\"candidates_compact\":\"${PROJECT_PATH}/.logs/candidates-compact.json\"},\"sizes\":{\"compact_bytes\":${COMPACT_SIZE}}}"
