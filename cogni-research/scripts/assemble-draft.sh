#!/usr/bin/env bash
# assemble-draft.sh
# Version: 1.0.0
# Purpose: Concatenate deep-mode section files into output/draft-v{N}.md and
#          emit per-section word counts as a JSON report. Called from the
#          research-report skill's Phase 4c after all section-writer dispatches
#          finish. Stdlib only — bash 3.2 + python3.
#
# Usage:
#   assemble-draft.sh --project-path <path> --draft-version N [--deficit-threshold 0.80]
#
# Reads:
#   .metadata/writer-outline-v{N}.json — canonical section order and budgets
#   .metadata/draft-sections/section-{NN}.md — one per outline entry
#
# Writes:
#   output/draft-v{N}.md — concatenated draft in outline order
#   .metadata/writer-outline-v{N}.json — updated in place with actual drafted_words
#
# Exit codes:
#   0 — all sections present and within the deficit threshold
#   1 — one or more sections missing, empty, or under-budget past the threshold
#   2 — argument or input error
#
# JSON output (stdout):
#   {"success": true|false, "draft_path": "...", "total_words": N, "sections": [...], "deficits": [...]}

set -u

PROJECT_PATH=""
DRAFT_VERSION=""
DEFICIT_THRESHOLD="0.80"  # section is deficient if drafted_words < budget * threshold

usage() {
    echo "Usage: $0 --project-path <path> --draft-version N [--deficit-threshold 0.80]" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --draft-version)
            DRAFT_VERSION="$2"
            shift 2
            ;;
        --deficit-threshold)
            DEFICIT_THRESHOLD="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

if [ -z "$PROJECT_PATH" ] || [ -z "$DRAFT_VERSION" ]; then
    usage
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "{\"success\": false, \"error\": \"Project path not found: $PROJECT_PATH\"}"
    exit 2
fi

OUTLINE_PATH="${PROJECT_PATH}/.metadata/writer-outline-v${DRAFT_VERSION}.json"
SECTIONS_DIR="${PROJECT_PATH}/.metadata/draft-sections"
OUTPUT_DIR="${PROJECT_PATH}/output"
DRAFT_PATH="${OUTPUT_DIR}/draft-v${DRAFT_VERSION}.md"

if [ ! -f "$OUTLINE_PATH" ]; then
    echo "{\"success\": false, \"error\": \"Writer outline not found: $OUTLINE_PATH\"}"
    exit 2
fi

if [ ! -d "$SECTIONS_DIR" ]; then
    echo "{\"success\": false, \"error\": \"Draft sections directory not found: $SECTIONS_DIR\"}"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Delegate assembly + word counting to python3 so the JSON output is clean
# and the deficit logic stays readable. All file I/O is stdlib only.
python3 - "$OUTLINE_PATH" "$SECTIONS_DIR" "$DRAFT_PATH" "$DEFICIT_THRESHOLD" <<'PY'
import json
import sys
from pathlib import Path

outline_path = Path(sys.argv[1])
sections_dir = Path(sys.argv[2])
draft_path = Path(sys.argv[3])
deficit_threshold = float(sys.argv[4])

try:
    outline = json.loads(outline_path.read_text(encoding='utf-8'))
except (OSError, json.JSONDecodeError) as e:
    print(json.dumps({"success": False, "error": f"Failed to load outline: {e}"}))
    sys.exit(2)

sections = outline.get("sections", [])
if not sections:
    print(json.dumps({"success": False, "error": "Outline contains no sections"}))
    sys.exit(2)

assembled_parts = []
section_reports = []
deficits = []
missing = []
total_words = 0

for pos, section in enumerate(sections):
    index = section.get("index") or f"{pos:02d}"
    heading = section.get("heading", "")
    budget = int(section.get("budget", 0) or 0)

    section_file = sections_dir / f"section-{index}.md"

    if not section_file.is_file():
        missing.append({"index": index, "heading": heading, "path": str(section_file)})
        section_reports.append({
            "index": index,
            "heading": heading,
            "budget": budget,
            "drafted_words": 0,
            "status": "missing",
        })
        continue

    try:
        body = section_file.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError) as e:
        missing.append({"index": index, "heading": heading, "error": str(e)})
        section_reports.append({
            "index": index,
            "heading": heading,
            "budget": budget,
            "drafted_words": 0,
            "status": "unreadable",
        })
        continue

    if not body.strip():
        missing.append({"index": index, "heading": heading, "path": str(section_file), "error": "empty"})
        section_reports.append({
            "index": index,
            "heading": heading,
            "budget": budget,
            "drafted_words": 0,
            "status": "empty",
        })
        continue

    word_count = len(body.split())
    total_words += word_count

    # Update the outline entry with the actual drafted words so the
    # orchestrator has a pre-written audit hook for Phase 4.5.
    section["drafted_words"] = word_count

    status = "ok"
    if budget > 0 and word_count < budget * deficit_threshold:
        status = "deficit"
        deficits.append({
            "index": index,
            "heading": heading,
            "budget": budget,
            "drafted_words": word_count,
            "shortfall": budget - word_count,
            "ratio": round(word_count / budget, 3) if budget else 0.0,
        })

    section_reports.append({
        "index": index,
        "heading": heading,
        "budget": budget,
        "drafted_words": word_count,
        "status": status,
    })

    # Ensure one blank line between concatenated sections so downstream
    # markdown renderers don't merge adjacent blocks.
    if not body.endswith("\n"):
        body += "\n"
    if assembled_parts:
        assembled_parts.append("\n")
    assembled_parts.append(body)

# If any section is missing or empty the assembly is incomplete — do not
# write a partial draft file that downstream phases would mistake for
# complete.
if missing:
    print(json.dumps({
        "success": False,
        "error": "One or more section files missing or empty",
        "missing": missing,
        "sections": section_reports,
    }, ensure_ascii=False))
    sys.exit(1)

# Write the concatenated draft
try:
    draft_path.parent.mkdir(parents=True, exist_ok=True)
    draft_path.write_text("".join(assembled_parts), encoding='utf-8')
except OSError as e:
    print(json.dumps({"success": False, "error": f"Failed to write draft: {e}"}))
    sys.exit(2)

# Persist the updated outline with drafted_words filled in
try:
    outline_path.write_text(
        json.dumps(outline, indent=2, ensure_ascii=False),
        encoding='utf-8',
    )
except OSError as e:
    print(json.dumps({"success": False, "error": f"Failed to update outline: {e}"}))
    sys.exit(2)

# wc -w uses whitespace splits same as str.split(), so the count we
# wrote into drafted_words matches what `wc -w` would report on the
# concatenated file. This is the authoritative count for Phase 4.5.

success = len(deficits) == 0
exit_code = 0 if success else 1

print(json.dumps({
    "success": success,
    "draft_path": str(draft_path),
    "outline_path": str(outline_path),
    "total_words": total_words,
    "sections": section_reports,
    "deficits": deficits,
    "deficit_threshold": deficit_threshold,
}, ensure_ascii=False))

sys.exit(exit_code)
PY

PY_EXIT=$?
exit $PY_EXIT
