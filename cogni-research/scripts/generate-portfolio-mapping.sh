#!/usr/bin/env bash
set -euo pipefail
# generate-portfolio-mapping.sh
# DEPRECATED: Migrated to cogni-portfolio/scripts/generate-portfolio-mapping.sh (2026-03-12)
# This script remains functional for existing cogni-research projects.
# Version: 1.1.0
# Purpose: Generate category-to-entity mapping for portfolio project
# Category: utilities
#
# Usage: generate-portfolio-mapping.sh --project-path <path> [--output <path>]
#
# Arguments:
#   --project-path <path>  Portfolio research project directory (required)
#   --output <path>        Output path (optional, defaults to .metadata/portfolio-category-mapping.json)
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "portfolio_project": "project-slug",
#       "generated_at": "ISO-8601",
#       "category_count": 51,
#       "mapped_count": N,
#       "mappings": {
#         "1.1": {
#           "category_name": "Managed Hyperscaler Services",
#           "dimension": "cloud-services",
#           "entities": ["[[project/11-trends/data/portfolio-xxx]]", ...]
#         },
#         ...
#       }
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Invalid project path
#   2 - No portfolio entities found
#   3 - Usage error
#
# Example:
#   generate-portfolio-mapping.sh --project-path "/research/portfolio-dtag-2024"


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_TRENDS="$(get_directory_by_key "trends")"

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

    local trends_dir="$project_path/${DIR_TRENDS}/${DATA_SUBDIR}"
    [[ -d "$trends_dir" ]] || error_json "Trends directory not found: $trends_dir" 1

    # Set default output path
    if [[ -z "$output_path" ]]; then
        output_path="$project_path/.metadata/portfolio-category-mapping.json"
    fi

    # Ensure .metadata directory exists
    local metadata_dir
    metadata_dir="$(dirname "$output_path")"
    mkdir -p "$metadata_dir"

    # Get project slug from path
    local project_slug
    project_slug="$(basename "$project_path")"

    # Find portfolio entities
    local portfolio_files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && portfolio_files+=("$f")
    done < <(find "$trends_dir" -name "portfolio-*.md" -type f 2>/dev/null || true)

    if [[ ${#portfolio_files[@]} -eq 0 ]]; then
        error_json "No portfolio entities found in $trends_dir" 2
    fi

    # Initialize mappings object with all 57 categories (8 dimensions 0-7)
    local mappings_json="{}"
    for entry in "${TAXONOMY[@]}"; do
        local cat_id cat_name dimension
        IFS='|' read -r cat_id cat_name dimension <<< "$entry"
        mappings_json="$(echo "$mappings_json" | jq \
            --arg id "$cat_id" \
            --arg name "$cat_name" \
            --arg dim "$dimension" \
            '.[$id] = {category_name: $name, dimension: $dim, entities: []}')"
    done

    # Process each portfolio entity
    local mapped_count=0
    for file in "${portfolio_files[@]}"; do
        local entity_id category_id

        # Extract dc:identifier from frontmatter
        entity_id="$(grep -m1 "^dc:identifier:" "$file" | sed 's/dc:identifier: *//' | tr -d '"' || echo "")"
        if [[ -z "$entity_id" ]]; then
            continue
        fi

        # Extract portfolio_category.category_id from frontmatter
        # Handle nested YAML: portfolio_category:\n  category_id: "X.Y"
        category_id="$(awk '
            /^portfolio_category:/ { in_block=1; next }
            in_block && /^  category_id:/ { gsub(/.*category_id: *"?|"?$/, ""); print; exit }
            in_block && /^[^ ]/ { exit }
        ' "$file")"

        if [[ -z "$category_id" ]]; then
            continue
        fi

        # Build wikilink (includes /data/ subdirectory per entity-schema.json)
        local wikilink="[[${project_slug}/${DIR_TRENDS}/${DATA_SUBDIR}/${entity_id}]]"

        # Add to mappings
        mappings_json="$(echo "$mappings_json" | jq \
            --arg id "$category_id" \
            --arg link "$wikilink" \
            'if .[$id] then .[$id].entities += [$link] else . end')"

        ((mapped_count++)) || true
    done

    # Count categories with at least one entity
    local categories_with_entities
    categories_with_entities="$(echo "$mappings_json" | jq '[.[] | select(.entities | length > 0)] | length')"

    # Build final output
    local generated_at
    generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local output_json
    output_json="$(jq -n \
        --arg project "$project_slug" \
        --arg ts "$generated_at" \
        --argjson cat_count 51 \
        --argjson mapped "$categories_with_entities" \
        --argjson entity_count "$mapped_count" \
        --argjson mappings "$mappings_json" \
        '{
            portfolio_project: $project,
            generated_at: $ts,
            category_count: $cat_count,
            mapped_count: $mapped,
            entity_count: $entity_count,
            mappings: $mappings
        }')"

    # Write to file
    echo "$output_json" > "$output_path"

    # Return success response
    jq -n \
        --arg path "$output_path" \
        --argjson mapped "$categories_with_entities" \
        --argjson entities "$mapped_count" \
        '{
            success: true,
            data: {
                output_file: $path,
                categories_mapped: $mapped,
                entities_processed: $entities
            }
        }'
}

main "$@"
