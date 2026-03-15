#!/usr/bin/env bash
set -euo pipefail
# generate-report-slug.sh - Generate kebab-case slug with date suffix
# Version: 1.0.0
#
# Usage: generate-report-slug.sh <topic>
# Output: {slug}-{YYYY-MM-DD}

if [[ $# -lt 1 ]]; then
  echo "Usage: generate-report-slug.sh <topic>" >&2
  exit 2
fi

TOPIC="$1"
DATE=$(date -u +%Y-%m-%d)

SLUG=$(echo "$TOPIC" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9 ]//g' \
  | tr ' ' '-' \
  | sed 's/-\+/-/g' \
  | head -c 40 \
  | sed 's/-$//')

echo "${SLUG}-${DATE}"
