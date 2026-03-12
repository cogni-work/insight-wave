#!/usr/bin/env bash
set -euo pipefail
# generate-ict-scan-mapping.sh
# Version: 2.0.0
# Purpose: Generate category-to-entity mapping from ict-scan research logs
# Category: utilities
#
# Usage: generate-ict-scan-mapping.sh --project-path <path> [--output <path>]
#
# Arguments:
#   --project-path <path>  Portfolio project directory (required)
#   --output <path>        Output path (optional, defaults to research/.metadata/portfolio-category-mapping.json)
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "project_slug": "company-slug",
#       "generated_at": "ISO-8601",
#       "category_count": 57,
#       "mapped_count": N,
#       "mappings": { ... }
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Invalid project path
#   2 - No research logs found
#   3 - Usage error

# Standard portfolio taxonomy (57 categories, 8 dimensions 0-7)
# Format: "ID|NAME|DIMENSION"
TAXONOMY=(
    # Provider Profile Metrics (6)
    "0.1|Financial Scale|provider-profile-metrics"
    "0.2|Workforce Capacity|provider-profile-metrics"
    "0.3|Geographic Presence|provider-profile-metrics"
    "0.4|Market Position|provider-profile-metrics"
    "0.5|Certifications & Accreditations|provider-profile-metrics"
    "0.6|Partnership Ecosystem|provider-profile-metrics"
    # Connectivity Services (7)
    "1.1|WAN Services|connectivity-services"
    "1.2|SASE|connectivity-services"
    "1.3|Internet & Cloud Connect|connectivity-services"
    "1.4|5G & IoT Connectivity|connectivity-services"
    "1.5|Voice Services|connectivity-services"
    "1.6|LAN/WLAN Services|connectivity-services"
    "1.7|Network-as-a-Service|connectivity-services"
    # Security Services (10)
    "2.1|Security Operations (SOC/SIEM)|security-services"
    "2.2|Identity & Access Management|security-services"
    "2.3|Zero Trust Architecture|security-services"
    "2.4|Cloud Security|security-services"
    "2.5|Endpoint Security|security-services"
    "2.6|Network Security|security-services"
    "2.7|Vulnerability Management|security-services"
    "2.8|Security Awareness|security-services"
    "2.9|Compliance & GRC|security-services"
    "2.10|Data Protection & Privacy|security-services"
    # Digital Workplace Services (7)
    "3.1|Unified Communications|digital-workplace-services"
    "3.2|Modern Workplace / M365|digital-workplace-services"
    "3.3|Device Management|digital-workplace-services"
    "3.4|Virtual Desktop & DaaS|digital-workplace-services"
    "3.5|IT Support Services|digital-workplace-services"
    "3.6|Digital Employee Experience|digital-workplace-services"
    "3.7|IT Asset Management|digital-workplace-services"
    # Cloud Services (8)
    "4.1|Managed Hyperscaler Services|cloud-services"
    "4.2|Multi-Cloud Management|cloud-services"
    "4.3|Private Cloud|cloud-services"
    "4.4|Hybrid Cloud|cloud-services"
    "4.5|Cloud Migration Services|cloud-services"
    "4.6|Cloud-Native Platform|cloud-services"
    "4.7|Sovereign Cloud|cloud-services"
    "4.8|Enterprise Platforms on Cloud|cloud-services"
    # Managed Infrastructure Services (7)
    "5.1|Data Center Services|managed-infrastructure-services"
    "5.2|Managed Compute & Storage|managed-infrastructure-services"
    "5.3|Backup & Disaster Recovery|managed-infrastructure-services"
    "5.4|Infrastructure Monitoring|managed-infrastructure-services"
    "5.5|IT Outsourcing (ITO)|managed-infrastructure-services"
    "5.6|Database Administration|managed-infrastructure-services"
    "5.7|Infrastructure Automation|managed-infrastructure-services"
    # Application Services (7)
    "6.1|Custom Application Development|application-services"
    "6.2|Application Modernization|application-services"
    "6.3|Enterprise Platform Services|application-services"
    "6.4|System Integration & API|application-services"
    "6.5|Low-Code/No-Code Platforms|application-services"
    "6.6|AI, Data & Analytics|application-services"
    "6.7|DevOps & Platform Engineering|application-services"
    # Consulting Services (5)
    "7.1|IT Strategy & Architecture|consulting-services"
    "7.2|Digital Transformation|consulting-services"
    "7.3|Business & Industry Consulting|consulting-services"
    "7.4|Program & Project Management|consulting-services"
    "7.5|Vendor & Contract Management|consulting-services"
)

error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local project_path="" output_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path) project_path="${2:-}"; shift 2 ;;
            --output) output_path="${2:-}"; shift 2 ;;
            *) error_json "Unknown argument: $1" 3 ;;
        esac
    done

    # Validate inputs
    [[ -n "$project_path" ]] || error_json "Project path required (--project-path)" 3
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 1

    local logs_dir="$project_path/research/.logs"
    [[ -d "$logs_dir" ]] || error_json "Research logs directory not found: $logs_dir" 1

    # Set default output path
    if [[ -z "$output_path" ]]; then
        output_path="$project_path/research/.metadata/portfolio-category-mapping.json"
    fi

    # Ensure output directory exists
    local metadata_dir
    metadata_dir="$(dirname "$output_path")"
    mkdir -p "$metadata_dir"

    # Get project slug from path
    local project_slug
    project_slug="$(basename "$project_path")"

    # Find research log files
    local log_files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && log_files+=("$f")
    done < <(find "$logs_dir" -name "portfolio-web-research-*.json" -type f 2>/dev/null || true)

    if [[ ${#log_files[@]} -eq 0 ]]; then
        error_json "No research log files found in $logs_dir" 2
    fi

    # Initialize mappings object with all 57 categories
    local mappings_json="{}"
    for entry in "${TAXONOMY[@]}"; do
        local cat_id cat_name dimension
        IFS='|' read -r cat_id cat_name dimension <<< "$entry"
        mappings_json="$(echo "$mappings_json" | jq \
            --arg id "$cat_id" \
            --arg name "$cat_name" \
            --arg dim "$dimension" \
            '.[$id] = {category_name: $name, dimension: $dim, offerings: []}')"
    done

    # Process each log file
    local total_offerings=0
    for file in "${log_files[@]}"; do
        # Extract offerings and map to categories
        local offerings_count
        offerings_count="$(jq '.offerings | length' "$file" 2>/dev/null || echo "0")"

        if [[ "$offerings_count" -gt 0 ]]; then
            # For each offering, add to the appropriate category
            local i=0
            while [[ $i -lt $offerings_count ]]; do
                local cat_id offering_name
                cat_id="$(jq -r ".offerings[$i].category // \"\"" "$file")"
                offering_name="$(jq -r ".offerings[$i].name // \"\"" "$file")"

                if [[ -n "$cat_id" && -n "$offering_name" ]]; then
                    mappings_json="$(echo "$mappings_json" | jq \
                        --arg id "$cat_id" \
                        --arg name "$offering_name" \
                        'if .[$id] then .[$id].offerings += [$name] else . end')"
                    ((total_offerings++)) || true
                fi
                ((i++)) || true
            done
        fi
    done

    # Count categories with at least one offering
    local categories_with_offerings
    categories_with_offerings="$(echo "$mappings_json" | jq '[.[] | select(.offerings | length > 0)] | length')"

    # Build final output
    local generated_at
    generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local output_json
    output_json="$(jq -n \
        --arg project "$project_slug" \
        --arg ts "$generated_at" \
        --argjson cat_count 57 \
        --argjson mapped "$categories_with_offerings" \
        --argjson offerings "$total_offerings" \
        --argjson mappings "$mappings_json" \
        '{
            project_slug: $project,
            generated_at: $ts,
            category_count: $cat_count,
            mapped_count: $mapped,
            total_offerings: $offerings,
            mappings: $mappings
        }')"

    # Write to file
    echo "$output_json" > "$output_path"

    # Return success response
    jq -n \
        --arg path "$output_path" \
        --argjson mapped "$categories_with_offerings" \
        --argjson offerings "$total_offerings" \
        '{
            success: true,
            data: {
                output_file: $path,
                categories_mapped: $mapped,
                offerings_processed: $offerings
            }
        }'
}

main "$@"
