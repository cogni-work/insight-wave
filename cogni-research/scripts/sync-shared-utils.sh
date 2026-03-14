#!/usr/bin/env bash
set -euo pipefail
# sync-shared-utils.sh
# Version: 1.0.0
# Purpose: Copy shared Python utilities into plugin for bundled distribution
#
# This script synchronizes the cogni-workplace/python modules into the
# cogni-research/scripts/shared_utils directory. Run this before
# releasing a new plugin version to ensure bundled utilities are up-to-date.
#
# Usage:
#   ./sync-shared-utils.sh
#
# The script will:
#   1. Detect the source directory (cogni-workplace/python)
#   2. Copy all required Python modules to scripts/shared_utils/
#   3. Report files copied and any errors
#
# Exit codes:
#   0 - Success (all files copied)
#   1 - Error (source not found or copy failed)


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PLUGIN_DIR")"

# Source and target directories
# Try environment variable first (standalone cogni-workplace repo)
if [[ -n "${COGNI_WORKPLACE_ROOT:-}" ]] && [[ -d "$COGNI_WORKPLACE_ROOT/python" ]]; then
    SOURCE_DIR="$COGNI_WORKPLACE_ROOT/python"
elif [[ -d "$REPO_ROOT/cogni-workplace/python" ]]; then
    # Legacy monorepo fallback
    SOURCE_DIR="$REPO_ROOT/cogni-workplace/python"
else
    SOURCE_DIR=""
fi
TARGET_DIR="$SCRIPT_DIR/shared_utils"

echo "Syncing shared utilities for cogni-research plugin..."
echo "  Source: $SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo ""

# Verify source directory exists
if [[ -z "$SOURCE_DIR" ]] || [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${RED}ERROR: Cannot find cogni-workplace Python utilities${NC}"
    echo "Set COGNI_WORKPLACE_ROOT to the cogni-workplace plugin directory."
    echo "Example: export COGNI_WORKPLACE_ROOT=/path/to/cogni-workplace/cogni-workplace"
    exit 1
fi

# Create target directory if needed
mkdir -p "$TARGET_DIR"

# List of required files
FILES=(
    "__init__.py"
    "script_output.py"
    "file_ops.py"
    "cross_platform.py"
    "logging_utils.py"
    "entity_lock.py"
    "entity_index.py"
    "entity_ops.py"
    "entity_config.py"
)

# Copy files
COPIED=0
FAILED=0

for file in "${FILES[@]}"; do
    src="$SOURCE_DIR/$file"
    dst="$TARGET_DIR/$file"

    if [[ -f "$src" ]]; then
        if cp "$src" "$dst"; then
            echo -e "${GREEN}✓${NC} Copied $file"
            ((COPIED++))
        else
            echo -e "${RED}✗${NC} Failed to copy $file"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}!${NC} Source not found: $file"
        ((FAILED++))
    fi
done

echo ""
echo "Sync complete:"
echo "  Files copied: $COPIED"
echo "  Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Some files failed to sync. Check the errors above.${NC}"
    exit 1
fi

# Note about entity_config.py customization
echo ""
echo -e "${YELLOW}NOTE:${NC} The bundled entity_config.py in shared_utils/ has been"
echo "customized with additional path resolution for plugin cache mode."
echo "If cogni-workplace/python/entity_config.py has changed significantly,"
echo "you may need to manually update the bundled version to preserve the"
echo "_find_config_path() enhancements."
