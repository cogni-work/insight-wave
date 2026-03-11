#!/bin/bash
# Initialize a cogni-portfolio project directory structure.
# Usage: project-init.sh <workspace-dir> <project-slug>
# Creates: <workspace-dir>/cogni-portfolio/<project-slug>/ with entity subdirectories.
# Outputs JSON: {"status": "created"|"exists", "path": "<absolute-path>"}
# Exit codes: 0 = success, 1 = error
set -euo pipefail

WORKSPACE_DIR="${1:-}"
PROJECT_SLUG="${2:-}"

if [ -z "$WORKSPACE_DIR" ] || [ -z "$PROJECT_SLUG" ]; then
  echo '{"error": "Usage: project-init.sh <workspace-dir> <project-slug>"}' >&2
  exit 1
fi

PROJECT_DIR="$WORKSPACE_DIR/cogni-portfolio/$PROJECT_SLUG"

if [ -d "$PROJECT_DIR" ]; then
  echo "{\"status\": \"exists\", \"path\": \"$PROJECT_DIR\"}"
  exit 0
fi

mkdir -p "$PROJECT_DIR/products"
mkdir -p "$PROJECT_DIR/features"
mkdir -p "$PROJECT_DIR/markets"
mkdir -p "$PROJECT_DIR/propositions"
mkdir -p "$PROJECT_DIR/solutions"
mkdir -p "$PROJECT_DIR/competitors"
mkdir -p "$PROJECT_DIR/customers"
mkdir -p "$PROJECT_DIR/uploads"
mkdir -p "$PROJECT_DIR/output/proposals"
mkdir -p "$PROJECT_DIR/output/briefs"

echo "{\"status\": \"created\", \"path\": \"$PROJECT_DIR\"}"
