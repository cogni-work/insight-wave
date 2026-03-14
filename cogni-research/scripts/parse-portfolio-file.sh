#!/usr/bin/env bash
set -euo pipefail
# parse-portfolio-file.sh
# Version: 1.0.0
# Purpose: Parse portfolio mapping markdown file into structured JSON for use by trends-creator
# Category: utilities
# Compatibility: bash 3.2+ (macOS compatible)
#
# Usage: parse-portfolio-file.sh --file <path> [--json]
#
# Arguments:
#   --file <path>    Absolute path to portfolio mapping markdown file (required)
#   --json           Output JSON format (optional flag, default: true)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "company_name": "Company Name",
#       "generated_date": "YYYY-MM-DD",
#       "dimensions": {
#         "cloud-services": {
#           "id": 1,
#           "name": "Cloud Services",
#           "categories": {
#             "1.1": {
#               "name": "Managed Hyperscaler Services",
#               "offerings": [
#                 {"name": "...", "description": "...", "domain": "...", "link": "..."}
#               ]
#             }
#           }
#         }
#       },
#       "total_offerings": number
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - File not found or validation error
#   2 - Invalid arguments
#
# Example:
#   parse-portfolio-file.sh --file /path/to/deutsche-telekom-portfolio.md --json


# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Dimension mappings (bash 3.2 compatible - no associative arrays)
get_dimension_slug() {
    case "$1" in
        1) echo "connectivity-services" ;;
        2) echo "security-services" ;;
        3) echo "digital-workplace-services" ;;
        4) echo "cloud-services" ;;
        5) echo "managed-infrastructure-services" ;;
        6) echo "application-services" ;;
        7) echo "consulting-services" ;;
        *) echo "" ;;
    esac
}

get_dimension_name() {
    case "$1" in
        1) echo "Connectivity Services" ;;
        2) echo "Security Services" ;;
        3) echo "Digital Workplace Services" ;;
        4) echo "Cloud Services" ;;
        5) echo "Managed Infrastructure Services" ;;
        6) echo "Application Services" ;;
        7) echo "Consulting Services" ;;
        *) echo "" ;;
    esac
}

# Parse arguments
PORTFOLIO_FILE=""
JSON_OUTPUT=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            PORTFOLIO_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            error_json "Unknown argument: $1" 2
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PORTFOLIO_FILE" ]]; then
    error_json "Missing required argument: --file" 2
fi

if [[ ! -f "$PORTFOLIO_FILE" ]]; then
    error_json "Portfolio file not found: $PORTFOLIO_FILE" 1
fi

# Initialize output JSON structure
output_json='{"success":true,"data":{"company_name":"","generated_date":"","dimensions":{},"total_offerings":0}}'

# Extract company name from first heading
company_name="$(grep -m1 "^# " "$PORTFOLIO_FILE" | sed 's/^# //' | sed 's/ ICT Portfolio$//' || echo "Unknown")"
output_json="$(echo "$output_json" | jq --arg name "$company_name" '.data.company_name = $name')"

# Extract generated date if present
generated_date="$(grep -m1 "Portfolio mapping generated on" "$PORTFOLIO_FILE" | sed -E 's/.*generated on ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' || echo "")"
output_json="$(echo "$output_json" | jq --arg date "$generated_date" '.data.generated_date = $date')"

# Initialize dimensions structure
for dim_id in 1 2 3 4 5 6 7; do
    dim_slug="$(get_dimension_slug "$dim_id")"
    dim_name="$(get_dimension_name "$dim_id")"
    output_json="$(echo "$output_json" | jq \
        --arg slug "$dim_slug" \
        --argjson id "$dim_id" \
        --arg name "$dim_name" \
        '.data.dimensions[$slug] = {"id": $id, "name": $name, "categories": {}}')"
done

# Parse the file to extract offerings
total_offerings=0
current_dimension=""
current_category_id=""
current_category_name=""
in_table=false

while IFS= read -r line; do
    # Detect dimension header (## N. Dimension Name)
    if echo "$line" | grep -qE '^##[[:space:]]+[0-9]+\.[[:space:]]+'; then
        dim_num="$(echo "$line" | sed -E 's/^##[[:space:]]+([0-9]+)\..*/\1/')"
        current_dimension="$(get_dimension_slug "$dim_num")"
        in_table=false
        continue
    fi

    # Detect category header (### N.N Category Name)
    if echo "$line" | grep -qE '^###[[:space:]]+[0-9]+\.[0-9]+[[:space:]]+'; then
        current_category_id="$(echo "$line" | sed -E 's/^###[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+.*/\1/')"
        current_category_name="$(echo "$line" | sed -E 's/^###[[:space:]]+[0-9]+\.[0-9]+[[:space:]]+//')"

        # Initialize category in JSON
        if [[ -n "$current_dimension" ]]; then
            output_json="$(echo "$output_json" | jq \
                --arg dim "$current_dimension" \
                --arg cat_id "$current_category_id" \
                --arg cat_name "$current_category_name" \
                '.data.dimensions[$dim].categories[$cat_id] = {"name": $cat_name, "offerings": []}')"
        fi
        in_table=false
        continue
    fi

    # Detect table header
    if echo "$line" | grep -qE '^\|[[:space:]]*Name[[:space:]]*\|'; then
        in_table=true
        continue
    fi

    # Skip table separator
    if echo "$line" | grep -qE '^\|[-]+\|'; then
        continue
    fi

    # Parse table rows
    if [[ "$in_table" == "true" ]] && echo "$line" | grep -qE '^\|'; then
        # Skip "No offerings found" rows
        if echo "$line" | grep -qi "No offerings found"; then
            continue
        fi

        # Extract columns 1-4: Name | Description | Domain | Link (ignoring columns 5-11)
        # Table format: Name | Description | Domain | Link | USP | Provider Unit | Pricing | Delivery | Partners | Verticals | Horizon
        # Remove leading/trailing pipes and split
        row="$(echo "$line" | sed 's/^|//;s/|$//')"

        # Use awk to split by | and trim whitespace
        name="$(echo "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1}')"
        description="$(echo "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')"
        domain="$(echo "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')"
        link_col="$(echo "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')"

        # Extract URL from markdown link format [Link](url)
        if echo "$link_col" | grep -qE '\[.*\]\(.*\)'; then
            link="$(echo "$link_col" | sed -E 's/.*\]\(([^)]*)\).*/\1/')"
        else
            link="$link_col"
        fi

        # Skip empty rows or header rows
        if [[ -z "$name" || "$name" == "Name" ]]; then
            continue
        fi

        # Add offering to JSON
        if [[ -n "$current_dimension" && -n "$current_category_id" ]]; then
            output_json="$(echo "$output_json" | jq \
                --arg dim "$current_dimension" \
                --arg cat_id "$current_category_id" \
                --arg name "$name" \
                --arg desc "$description" \
                --arg domain "$domain" \
                --arg link "$link" \
                '.data.dimensions[$dim].categories[$cat_id].offerings += [{"name": $name, "description": $desc, "domain": $domain, "link": $link}]')"
            total_offerings=$((total_offerings + 1))
        fi
    fi

    # End table when we hit a non-table line (but not empty lines)
    if [[ "$in_table" == "true" ]] && ! echo "$line" | grep -qE '^\|' && [[ -n "$line" ]] && ! echo "$line" | grep -qE '^[[:space:]]*$'; then
        in_table=false
    fi

done < "$PORTFOLIO_FILE"

# Update total offerings count
output_json="$(echo "$output_json" | jq --argjson total "$total_offerings" '.data.total_offerings = $total')"

# Output result
echo "$output_json"
