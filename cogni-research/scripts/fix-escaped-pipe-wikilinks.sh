#!/usr/bin/env bash
set -euo pipefail
# fix-escaped-pipe-wikilinks.sh
# Version: 1.0.0
# Purpose: Repairs escaped pipe characters in wikilinks caused by pre-v4.3.4 templates
# Category: repair-utility
#
# Converts [[path\|Label]] to [[path|Label]] in research-hub.md
# Pre-v4.3.4 templates instructed LLMs to escape pipes in wikilinks to prevent
# markdown table breakage. This was fixed in v4.3.4, but existing projects need repair.
#
# Usage: fix-escaped-pipe-wikilinks.sh <project-path>
#
# Arguments:
#   project-path    Absolute path to research project directory (required)
#
# Exit codes:
#   0 - Success (wikilinks repaired or no escaped pipes found)
#   1 - Validation error (missing project path or file not found)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage message
usage() {
    echo "Usage: $0 <project-path>"
    echo "  Repairs escaped pipe characters in wikilinks in research-hub.md"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/research/project"
    exit 1
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

PROJECT_PATH="$1"
REPORT_FILE="${PROJECT_PATH}/research-hub.md"

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project directory does not exist: ${PROJECT_PATH}${NC}"
    exit 1
fi

# Validate report file exists
if [[ ! -f "$REPORT_FILE" ]]; then
    echo -e "${RED}Error: research-hub.md not found at: ${REPORT_FILE}${NC}"
    exit 1
fi

echo "=== Wikilink Repair Script ==="
echo "Project: ${PROJECT_PATH}"
echo "Target: ${REPORT_FILE}"
echo ""

# Count escaped pipes before fix
BEFORE_COUNT=$(grep -F '\|' "$REPORT_FILE" | wc -l | tr -d ' ')
echo "Lines with escaped pipes: ${BEFORE_COUNT}"

if [[ "$BEFORE_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}No escaped pipes found. Nothing to fix!${NC}"
    exit 0
fi

# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${REPORT_FILE}.bak-${TIMESTAMP}"
cp "$REPORT_FILE" "$BACKUP_FILE"
echo -e "${GREEN}Backup created: ${BACKUP_FILE}${NC}"

# Apply sed replacement
# Pattern: Replace all literal \| with |
echo "Applying fix..."
sed -i '' 's/\\\|/|/g' "$REPORT_FILE"

# Count escaped pipes after fix
AFTER_COUNT=$(grep -F '\|' "$REPORT_FILE" | wc -l | tr -d ' ')
FIXED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

echo ""
echo "=== Results ==="
echo -e "${GREEN}Fixed: ${FIXED_COUNT} lines${NC}"
echo "Lines with escaped pipes remaining: ${AFTER_COUNT}"

if [[ "$AFTER_COUNT" -gt 0 ]]; then
    echo -e "${YELLOW}Warning: Some escaped pipes remain. Manual inspection recommended.${NC}"
fi

echo ""
echo -e "${GREEN}Repair complete!${NC}"
echo "Backup available at: ${BACKUP_FILE}"
echo ""
echo "Next steps:"
echo "  1. Open research-hub.md in Obsidian"
echo "  2. Test wikilinks are clickable"
echo "  3. Verify tables render correctly"
