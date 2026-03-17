#!/usr/bin/env bash
set -euo pipefail
# discover-portfolio.sh
# Purpose: Scan workspace for cogni-portfolio projects and return metadata
#
# Usage:
#   discover-portfolio.sh [--workspace <path>]
#
# Returns JSON:
#   {
#     "portfolios": [{
#       "path": "/abs/path",
#       "company": "Acme Cloud",
#       "products": 4,
#       "features": 12,
#       "markets": 3,
#       "propositions": 8,
#       "language": "de"
#     }]
#   }

if ! command -v jq &> /dev/null; then
    echo '{"error": "jq is required but not installed", "portfolios": []}' >&2
    exit 1
fi

# Default workspace: current directory
WORKSPACE="${1:-$(pwd)}"

# Parse arguments
while [ $# -gt 0 ]; do
    case $1 in
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Resolve to absolute path
case "$WORKSPACE" in
    /*) ;;
    *)  WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" || WORKSPACE="$(pwd)" ;;
esac

# Find all portfolio.json files (cogni-portfolio format)
PORTFOLIO_FILES=$(find "$WORKSPACE" -maxdepth 4 -name "portfolio.json" -not -path "*/.metadata/*" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)

if [ -z "$PORTFOLIO_FILES" ]; then
    echo '{"portfolios": []}'
    exit 0
fi

PORTFOLIOS_JSON="[]"

while IFS= read -r portfolio_file; do
    if [ -f "$portfolio_file" ]; then
        PORTFOLIO_DIR="$(dirname "$portfolio_file")"

        # Read company name and language from portfolio.json
        COMPANY_NAME=$(jq -r '.company.name // "Unknown"' "$portfolio_file" 2>/dev/null || echo "Unknown")
        LANGUAGE=$(jq -r '.language // "en"' "$portfolio_file" 2>/dev/null || echo "en")

        # Count entities
        PRODUCTS_COUNT=0
        FEATURES_COUNT=0
        MARKETS_COUNT=0
        PROPOSITIONS_COUNT=0

        if [ -d "$PORTFOLIO_DIR/products" ]; then
            PRODUCTS_COUNT=$(find "$PORTFOLIO_DIR/products" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        fi
        if [ -d "$PORTFOLIO_DIR/features" ]; then
            FEATURES_COUNT=$(find "$PORTFOLIO_DIR/features" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        fi
        if [ -d "$PORTFOLIO_DIR/markets" ]; then
            MARKETS_COUNT=$(find "$PORTFOLIO_DIR/markets" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        fi
        if [ -d "$PORTFOLIO_DIR/propositions" ]; then
            PROPOSITIONS_COUNT=$(find "$PORTFOLIO_DIR/propositions" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        fi

        PORTFOLIOS_JSON=$(echo "$PORTFOLIOS_JSON" | jq \
            --arg path "$PORTFOLIO_DIR" \
            --arg company "$COMPANY_NAME" \
            --argjson products "$PRODUCTS_COUNT" \
            --argjson features "$FEATURES_COUNT" \
            --argjson markets "$MARKETS_COUNT" \
            --argjson propositions "$PROPOSITIONS_COUNT" \
            --arg language "$LANGUAGE" \
            '. + [{
                path: $path,
                company: $company,
                products: $products,
                features: $features,
                markets: $markets,
                propositions: $propositions,
                language: $language
            }]')
    fi
done <<< "$PORTFOLIO_FILES"

jq -n --argjson portfolios "$PORTFOLIOS_JSON" '{portfolios: $portfolios}'
exit 0
