#!/usr/bin/env bash
set -euo pipefail
# validate-enriched-trends.sh
# Version: 1.0.0
# Purpose: Validate (and repair, if safe) the four enriched-trends JSON files
#          produced by trend-research Phase 1 before downstream skills read them.
# Category: utilities
#
# Usage: validate-enriched-trends.sh <PROJECT_PATH>
#
# Arguments:
#   PROJECT_PATH  Absolute path to project directory (required)
#
# Inputs (per dimension in {externe-effekte, digitale-wertetreiber,
#                           neue-horizonte, digitales-fundament}):
#   ${PROJECT_PATH}/.logs/enriched-trends-{dimension}.json
#
# Behavior:
#   For each enriched-trends file: parse with json.loads. If it parses cleanly,
#   no-op. If it fails AND the failure is the U+201E `„` opener paired with
#   ASCII `"` closer pattern (issues #169 / #182), apply the regex repair
#   `„([^"\\]*)"` → `„\1”` and re-validate. Persist only if the repair
#   produces valid JSON.
#
#   Keep the repair logic structurally identical to
#   skills/trend-scout/scripts/prepare-phase3-data.sh so the two safety
#   nets cannot drift.
#
# Outputs (stdout, single JSON object):
#   {"ok":true,"validated":[<paths>],"repaired":[<paths>],"missing":[<paths>]}
#   {"ok":false,"error":"json_unrepairable","file":"<path>","line":N,"column":N,"message":"..."}
#
# Exit codes:
#   0 = success (all present files parse cleanly, possibly after repair)
#   1 = missing PROJECT_PATH argument
#   4 = at least one enriched-trends file is invalid JSON the repair pattern
#       cannot fix

if [[ -z "${1:-}" ]]; then
    echo '{"ok":false,"error":"missing_project_path","message":"Usage: validate-enriched-trends.sh <PROJECT_PATH>"}'
    exit 1
fi

PROJECT_PATH="$1"

# Single python3 call: iterate over the four target files, attempt the proven
# parse-then-repair pattern, emit a JSON envelope or an error envelope on stderr
# plus exit 4 if any file is invalid and unrepairable.
python3 - "$PROJECT_PATH" <<'PY'
import json, os, re, sys

project_path = sys.argv[1]
logs_dir = os.path.join(project_path, ".logs")
dimensions = [
    "externe-effekte",
    "digitale-wertetreiber",
    "neue-horizonte",
    "digitales-fundament",
]

validated = []
repaired = []
missing = []

for dim in dimensions:
    path = os.path.join(logs_dir, f"enriched-trends-{dim}.json")

    if not os.path.isfile(path):
        missing.append(path)
        continue

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Step 1: cheap path — already valid.
    try:
        json.loads(content)
        validated.append(path)
        continue
    except json.JSONDecodeError:
        pass

    # Step 2: try the known repair (issue #169 pattern).
    fixed, n = re.subn(r'„([^"\\]*)"', '„\\1”', content)
    if n > 0:
        try:
            json.loads(fixed)
        except json.JSONDecodeError:
            n = 0  # repair did not produce valid JSON — fall through to error
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(fixed)
            sys.stderr.write(
                f"validate-enriched-trends: sanitized {n} mixed-quote pair(s) in {path}\n"
            )
            repaired.append(path)
            continue

    # Step 3: irrecoverable — surface the exact line/column.
    try:
        json.loads(content)
    except json.JSONDecodeError as e:
        line = e.lineno
        col = e.colno
        msg = e.msg
    except Exception as e:
        line = 0
        col = 0
        msg = f"{type(e).__name__}: {e}"
    else:
        # Unreachable: we already established the file is invalid above.
        line, col, msg = 0, 0, "unknown_parse_failure"

    print(json.dumps({
        "ok": False,
        "error": "json_unrepairable",
        "file": path,
        "line": line,
        "column": col,
        "message": msg,
    }))
    sys.exit(4)

print(json.dumps({
    "ok": True,
    "validated": validated,
    "repaired": repaired,
    "missing": missing,
}))
PY
