#!/usr/bin/env bash
set -euo pipefail
# readability.sh
# Version: 1.0.0
# Purpose: Calculate readability metrics for markdown documents
# Category: validators
#
# Usage:
#   readability.sh --file <path> [--lang de|en|auto] [--json]
#
# Arguments:
#   --file <path>     Path to markdown file to analyze (required)
#   --lang <lang>     Language for Flesch formula: de, en, or auto (default: auto)
#   --json            Output raw JSON only, skip formatted display (optional)
#   --help            Show this help message
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "flesch_score": <number>,
#       "avg_paragraph_length": <number>,
#       "total_paragraphs": <number>,
#       "visual_elements": <number>,
#       "header_levels": <number>
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Missing required argument or invalid usage
#   2 - File not found or not readable
#   3 - Python dependency not available
#   4 - Analysis failed
#
# Example:
#   readability.sh --file /path/to/document.md
#   readability.sh --file ./memo.md --json
## Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/calculate_readability.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print warnings
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to output JSON error
json_error() {
    local msg="$1"
    local code="${2:-1}"
    echo "{\"success\": false, \"error\": \"$msg\", \"error_code\": $code}"
    exit "$code"
}

# Function to show usage
usage() {
    echo "Usage: $0 --file <path> [--lang de|en|auto] [--json]"
    echo ""
    echo "Arguments:"
    echo "  --file <path>   Path to markdown file to analyze (required)"
    echo "  --lang <lang>   Language for Flesch formula: de, en, or auto (default: auto)"
    echo "  --json          Output raw JSON only, skip formatted display"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --file /path/to/document.md"
    echo "  $0 --file ./memo.md --json"
    echo "  $0 --file ./bericht.md --lang de"
}

# Parse named arguments
FILE_PATH=""
JSON_ONLY=false
LANG_FLAG="auto"

# German style variables (initialized for overall assessment)
AVG_CLAUSE="N/A"
MAX_CLAUSE="N/A"
OVER_12="N/A"
SENT_STD="N/A"
FLOSKEL_COUNT="N/A"
FLOSKELN_FOUND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            FILE_PATH="$2"
            shift 2
            ;;
        --lang)
            LANG_FLAG="$2"
            shift 2
            ;;
        --json)
            JSON_ONLY=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if file path argument provided
if [ -z "$FILE_PATH" ]; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "Missing required argument: --file" 1
    else
        error "Missing required argument: --file"
        echo ""
        usage
        exit 1
    fi
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "File not found: $FILE_PATH" 2
    else
        error "File not found: $FILE_PATH"
        exit 2
    fi
fi

# Check if file is readable
if [ ! -r "$FILE_PATH" ]; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "File is not readable: $FILE_PATH" 2
    else
        error "File is not readable: $FILE_PATH"
        exit 2
    fi
fi

# Check if file is markdown
if [[ ! "$FILE_PATH" =~ \.md$ ]] && [[ ! "$FILE_PATH" =~ \.markdown$ ]]; then
    if [ "$JSON_ONLY" = false ]; then
        warning "File does not have .md or .markdown extension: $FILE_PATH"
        echo "Continuing anyway, but results may not be accurate for non-markdown files."
    fi
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "python3 not found - required dependency" 3
    else
        error "python3 not found"
        echo ""
        echo "This script requires Python 3 to be installed."
        echo "Install Python 3 and try again."
        exit 3
    fi
fi

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "Python script not found: $PYTHON_SCRIPT" 3
    else
        error "Python script not found: $PYTHON_SCRIPT"
        exit 3
    fi
fi

# Run the Python script
if [ "$JSON_ONLY" = false ]; then
    echo "Analyzing readability metrics for: $(basename "$FILE_PATH")"
    echo ""
fi

OUTPUT="$(python3 "$PYTHON_SCRIPT" "$FILE_PATH" --lang "$LANG_FLAG" 2>&1)"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    if [ "$JSON_ONLY" = true ]; then
        json_error "Failed to calculate readability metrics: $OUTPUT" 4
    else
        error "Failed to calculate readability metrics"
        echo "$OUTPUT"
        exit 4
    fi
fi

# If JSON only mode, wrap output in standard success format and exit
if [ "$JSON_ONLY" = true ]; then
    # Wrap raw Python output in success envelope
    echo "{\"success\": true, \"data\": $OUTPUT}"
    exit 0
fi

# Parse JSON output for formatted display
FLESCH="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['flesch_score'])" 2>/dev/null || echo "N/A")"
DETECTED_LANG="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['detected_language'])" 2>/dev/null || echo "N/A")"
FLESCH_MIN="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['flesch_target_min'])" 2>/dev/null || echo "50")"
FLESCH_MAX="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['flesch_target_max'])" 2>/dev/null || echo "60")"
AVG_PARA="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['avg_paragraph_length'])" 2>/dev/null || echo "N/A")"
TOTAL_PARA="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['total_paragraphs'])" 2>/dev/null || echo "N/A")"
VISUALS="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['visual_elements'])" 2>/dev/null || echo "N/A")"
HEADERS="$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['header_levels'])" 2>/dev/null || echo "N/A")"

# If parsing failed, just output raw JSON
if [ "$FLESCH" = "N/A" ]; then
    echo "$OUTPUT"
    exit 0
fi

# Display formatted results
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "READABILITY METRICS REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detected Language
if [ "$DETECTED_LANG" = "de" ]; then
    echo "Language: German (using Amstad formula)"
else
    echo "Language: English (using standard Flesch formula)"
fi
echo ""

# Flesch Reading Ease (language-aware targets)
FLESCH_NEAR_MIN="$(echo "$FLESCH_MIN - 5" | bc -l)"
FLESCH_NEAR_MAX="$(echo "$FLESCH_MAX + 5" | bc -l)"
echo "Flesch Reading Ease: $FLESCH"
if (( $(echo "$FLESCH >= $FLESCH_MIN && $FLESCH <= $FLESCH_MAX" | bc -l 2>/dev/null || echo 0) )); then
    success "  ✓ Within target range ($FLESCH_MIN-$FLESCH_MAX)"
elif (( $(echo "$FLESCH >= $FLESCH_NEAR_MIN && $FLESCH < $FLESCH_MIN" | bc -l 2>/dev/null || echo 0) )); then
    warning "  ⚠ Slightly below target ($FLESCH_MIN-$FLESCH_MAX)"
elif (( $(echo "$FLESCH > $FLESCH_MAX && $FLESCH <= $FLESCH_NEAR_MAX" | bc -l 2>/dev/null || echo 0) )); then
    warning "  ⚠ Slightly above target ($FLESCH_MIN-$FLESCH_MAX)"
else
    error "  ✗ Outside target range ($FLESCH_MIN-$FLESCH_MAX)"
fi
echo ""

# Average Paragraph Length
echo "Average Paragraph Length: $AVG_PARA sentences"
if (( $(echo "$AVG_PARA >= 3 && $AVG_PARA <= 5" | bc -l 2>/dev/null || echo 0) )); then
    success "  ✓ Within target range (3-5 sentences)"
elif (( $(echo "$AVG_PARA >= 2.5 && $AVG_PARA < 3" | bc -l 2>/dev/null || echo 0) )); then
    warning "  ⚠ Slightly below target (3-5 sentences)"
elif (( $(echo "$AVG_PARA > 5 && $AVG_PARA <= 6" | bc -l 2>/dev/null || echo 0) )); then
    warning "  ⚠ Slightly above target (3-5 sentences)"
else
    error "  ✗ Outside target range (3-5 sentences)"
fi
echo "Total Paragraphs: $TOTAL_PARA"
echo ""

# Visual Elements
echo "Visual Elements: $VISUALS"
if [ "$TOTAL_PARA" != "N/A" ] && [ "$TOTAL_PARA" -gt 0 ]; then
    EXPECTED_VISUALS="$(echo "$TOTAL_PARA / 2" | bc)"
    if [ "$VISUALS" -ge "$EXPECTED_VISUALS" ]; then
        success "  ✓ Good visual element density (~1 per 2 paragraphs)"
    else
        warning "  ⚠ Consider adding more visual elements (target: ~$EXPECTED_VISUALS)"
    fi
fi
echo ""

# Header Levels
echo "Header Hierarchy: $HEADERS levels"
if [ "$HEADERS" -le 3 ]; then
    success "  ✓ Within recommended depth (≤3 levels)"
elif [ "$HEADERS" -eq 4 ]; then
    warning "  ⚠ Consider simplifying hierarchy (recommended: ≤3 levels)"
else
    error "  ✗ Too many header levels (recommended: ≤3 levels)"
fi
echo ""

# German Style Analysis (Wolf Schneider) - only when German detected
if [ "$DETECTED_LANG" = "de" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "WOLF SCHNEIDER STYLE ANALYSIS (German)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    AVG_CLAUSE="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('german_style',{}).get('avg_clause_length','N/A'))" 2>/dev/null || echo "N/A")"
    MAX_CLAUSE="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('german_style',{}).get('max_clause_length','N/A'))" 2>/dev/null || echo "N/A")"
    OVER_12="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('german_style',{}).get('clauses_over_12','N/A'))" 2>/dev/null || echo "N/A")"
    SENT_STD="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('german_style',{}).get('sentence_length_std_dev','N/A'))" 2>/dev/null || echo "N/A")"
    FLOSKEL_COUNT="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('german_style',{}).get('floskel_count','N/A'))" 2>/dev/null || echo "N/A")"
    FLOSKELN_FOUND="$(echo "$OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(', '.join(d.get('german_style',{}).get('floskeln_found',[])))" 2>/dev/null || echo "")"

    # Clause length
    echo "Avg Clause Length: $AVG_CLAUSE words (target: ≤12)"
    if [ "$AVG_CLAUSE" != "N/A" ] && (( $(echo "$AVG_CLAUSE <= 12" | bc -l 2>/dev/null || echo 0) )); then
        success "  ✓ Within Wolf Schneider target"
    else
        warning "  ⚠ Clauses too long — break Satzklammer, shorten Mittelfeld"
    fi

    echo "Max Clause Length: $MAX_CLAUSE words"
    echo "Clauses Over 12 Words: $OVER_12"
    if [ "$OVER_12" != "N/A" ] && [ "$OVER_12" -gt 0 ]; then
        warning "  ⚠ $OVER_12 clause(s) exceed 12-word limit"
    fi
    echo ""

    # Rhythm
    echo "Sentence Length Variation: $SENT_STD (std dev, target: >3.0)"
    if [ "$SENT_STD" != "N/A" ] && (( $(echo "$SENT_STD >= 3.0" | bc -l 2>/dev/null || echo 0) )); then
        success "  ✓ Good rhythmic variety (Maxime 11)"
    else
        warning "  ⚠ Monotone sentence lengths — vary short/long (Maxime 11)"
    fi
    echo ""

    # Floskeln
    echo "Floskeln Detected: $FLOSKEL_COUNT (target: 0)"
    if [ "$FLOSKEL_COUNT" != "N/A" ] && [ "$FLOSKEL_COUNT" -eq 0 ]; then
        success "  ✓ No Floskeln found (Maxime 2)"
    else
        error "  ✗ Floskeln found: $FLOSKELN_FOUND"
    fi
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Overall assessment
ISSUES=0
if ! (( $(echo "$FLESCH >= $FLESCH_MIN && $FLESCH <= $FLESCH_MAX" | bc -l 2>/dev/null || echo 0) )); then
    ((ISSUES++)) || true
fi
if ! (( $(echo "$AVG_PARA >= 3 && $AVG_PARA <= 5" | bc -l 2>/dev/null || echo 0) )); then
    ((ISSUES++)) || true
fi
if [ "$HEADERS" -gt 3 ]; then
    ((ISSUES++)) || true
fi

# German-specific issues
if [ "$DETECTED_LANG" = "de" ]; then
    if [ "$AVG_CLAUSE" != "N/A" ] && (( $(echo "$AVG_CLAUSE > 12" | bc -l 2>/dev/null || echo 0) )); then
        ((ISSUES++)) || true
    fi
    if [ "$FLOSKEL_COUNT" != "N/A" ] && [ "$FLOSKEL_COUNT" -gt 0 ]; then
        ((ISSUES++)) || true
    fi
    if [ "$SENT_STD" != "N/A" ] && (( $(echo "$SENT_STD < 3.0" | bc -l 2>/dev/null || echo 0) )); then
        ((ISSUES++)) || true
    fi
fi

if [ $ISSUES -eq 0 ]; then
    success "✓ All quality metrics within target ranges"
elif [ $ISSUES -eq 1 ]; then
    warning "⚠ 1 metric outside target range - consider revisions"
else
    error "✗ $ISSUES metrics outside target ranges - revisions recommended"
fi

echo ""
echo "Raw JSON output:"
echo "$OUTPUT"
