#!/usr/bin/env bash
set -euo pipefail
# discover-research-templates.sh
# Version: 1.0.0
# Purpose: Parse research-types/README.md to extract template metadata and return as JSON
# Category: extractors
#
# Usage: discover-research-templates.sh --json
#
# Arguments:
#   --json              Output results in JSON format (required)
#
# Output (JSON):
#   Success: {
#     "success": true,
#     "templates": [
#       {
#         "name": "smarter-service",
#         "description": "4-dimension trend analysis for digital transformation",
#         "framework": "Trendbook Kompass für die Multikrise (2023)",
#         "dimensions": 4,
#         "when_to_use": "European market context, regulatory considerations, action horizon planning"
#       }
#     ]
#   }
#   Failure: {
#     "success": false,
#     "error": "README.md not found at expected location",
#     "fallback": ["generic"]
#   }
#
# Exit codes:
#   0 - Success (templates discovered or fallback provided)
#   1 - Error (malformed README, parsing failure)
#   2 - Invalid arguments
#
# Example:
#   discover-research-templates.sh --json
#
# Dependencies:
#   - jq (JSON processing)
#   - sed, grep (text parsing)
#
# Environment:
#   CLAUDE_PLUGIN_ROOT - Plugin root directory (required)
#   DEBUG_MODE - Enable verbose logging (optional)


# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source enhanced logging (cross-plugin reference with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging functions (|| true prevents exit code 1 with set -e)
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2 || true; }
fi

# Error handler
error_json() {
    local msg="$1"
    local code="${2:-1}"
    local fallback="${3:-}"

    log_conditional "ERROR" "$msg"

    if [[ -n "$fallback" ]]; then
        jq -n --arg msg "$msg" \
              --argjson code "$code" \
              --argjson fallback "$fallback" \
            '{success: false, error: $msg, error_code: $code, fallback: $fallback}' >&2
    else
        jq -n --arg msg "$msg" \
              --argjson code "$code" \
            '{success: false, error: $msg, error_code: $code}' >&2
    fi

    exit "$code"
}

# Validate environment
validate_environment() {
    log_phase "VALIDATE" "Checking environment and README location"

    # Derive plugin root from script location if not set
    local plugin_root="${CLAUDE_PLUGIN_ROOT:-}"
    if [[ -z "$plugin_root" ]]; then
        # Script is in scripts/, so plugin root is one level up
        plugin_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
        log_conditional "FALLBACK" "Derived plugin root from SCRIPT_DIR: $plugin_root"
    fi

    # Validate plugin root has expected structure
    if [[ ! -d "${plugin_root}/references" ]]; then
        log_conditional "ERROR" "Plugin root does not contain references/ directory: $plugin_root"
    fi

    local readme_path="${plugin_root}/references/research-types/README.md"

    if [[ ! -f "$readme_path" ]]; then
        error_json "README.md not found at expected location: $readme_path" 1 '["generic"]'
    fi

    echo "$readme_path"
}

# Clean markdown formatting from field value
# Input: "** Framework Name (2023)" or "**Fixed 4 dimensions**"
# Output: "Framework Name (2023)" or "Fixed 4 dimensions"
clean_markdown() {
    local value="$1"
    # Remove leading/trailing **, then trim whitespace
    echo "$value" | sed 's/^[*[:space:]]*//' | sed 's/[*[:space:]]*$//'
}

# Extract template name from section header
# Input: Line like "### smarter-service" or "### generic"
# Output: Template name (e.g., "smarter-service")
extract_template_name() {
    local line="$1"
    echo "$line" | sed 's/^###[[:space:]]*//' | tr -d '\r'
}

# Extract metadata field value and clean formatting
# Input: Line like "**Framework:** Trendbook Kompass (2023)"
# Output: "Trendbook Kompass (2023)"
extract_field_value() {
    local line="$1"
    local value
    value="$(echo "$line" | sed 's/^[*]*[^:]*:[[:space:]]*//')"
    clean_markdown "$value"
}

# Clean and extract dimensions value
# Input: "4 (fixed, MECE pre-validated)" or "Variable (2-10, generated...)"
# Output: "4" or "variable"
extract_dimensions() {
    local value="$1"
    if echo "$value" | grep -qi "variable"; then
        echo "variable"
    else
        # Extract only the FIRST number (fix for "8 dimensions (0-7)" bug)
        echo "$value" | grep -oE '^[0-9]+' | head -1
    fi
}

# Build template description from characteristics
build_description() {
    local name="$1"
    local framework="$2"
    local dimensions="$3"

    if [[ "$name" == "tips-framework" ]]; then
        echo "4-component synthesis structure for trend-based research"
    elif [[ "$name" == "smarter-service" ]]; then
        echo "4-dimension trend analysis for digital transformation"
    elif [[ "$name" == "lean-canvas" ]]; then
        echo "9-block business model validation framework"
    elif [[ "$name" == "b2b-ict-portfolio" ]]; then
        echo "8-dimension ICT service portfolio discovery"
    elif [[ "$name" == "customer-value-mapping" ]]; then
        echo "4-dimension Value Story synthesis for sales enablement"
    elif [[ "$name" == "generic" ]]; then
        echo "Variable 2-10 dimensions using Webb's DOK framework"
    else
        echo "Research template: $name"
    fi
}

# Build when_to_use from characteristics
build_when_to_use() {
    local name="$1"
    local characteristics="$2"

    if [[ "$name" == "tips-framework" ]]; then
        echo "Baseline TIPS structure for trend entities, used by smarter-service"
    elif [[ "$name" == "smarter-service" ]]; then
        echo "European market context, regulatory considerations, action horizon planning"
    elif [[ "$name" == "lean-canvas" ]]; then
        echo "Startup validation, business model analysis, product-market fit"
    elif [[ "$name" == "b2b-ict-portfolio" ]]; then
        echo "Enterprise ICT provider analysis, service portfolio discovery, solution catalogs"
    elif [[ "$name" == "customer-value-mapping" ]]; then
        echo "Customer-specific sales enablement, Value Story presentations, TIPS-to-portfolio mapping"
    elif [[ "$name" == "generic" ]]; then
        echo "Exploratory research, custom dimension structures, flexible analysis"
    else
        echo "$characteristics"
    fi
}

# Parse README and extract template metadata
parse_readme() {
    local readme_path="$1"

    log_phase "PARSE" "Extracting template metadata from README"

    # Build JSON array of templates
    local templates="[]"
    local current_template=""
    local current_framework=""
    local current_dimensions=""
    local current_characteristics=""

    local in_research_types_section=false
    local in_template=false

    while IFS= read -r line; do
        # Detect "Available Research Types" section
        if echo "$line" | grep -q "^## Available Research Types"; then
            in_research_types_section=true
            log_conditional "SECTION" "Entered Available Research Types section"
            continue
        fi

        # Exit section if we hit another ## header
        if [[ "$in_research_types_section" == "true" ]] && echo "$line" | grep -q "^##[[:space:]]"; then
            in_research_types_section=false
            log_conditional "SECTION" "Exited Available Research Types section"
            break
        fi

        # Only process templates within the research types section
        if [[ "$in_research_types_section" == "true" ]]; then
            # Detect template section header (### template-name)
            if echo "$line" | grep -q "^###[[:space:]]"; then
                # Save previous template if exists
                if [[ "$in_template" == "true" && -n "$current_template" ]]; then
                    log_conditional "TEMPLATE" "Saving template: $current_template"

                    # Build description and when_to_use
                    local description
                    local when_to_use
                    description="$(build_description "$current_template" "$current_framework" "$current_dimensions")"
                    when_to_use="$(build_when_to_use "$current_template" "$current_characteristics")"

                    # Build template object
                    local template_obj
                    template_obj="$(jq -n \
                        --arg name "$current_template" \
                        --arg desc "$description" \
                        --arg framework "$current_framework" \
                        --arg dims "$current_dimensions" \
                        --arg when "$when_to_use" \
                        '{
                            name: $name,
                            description: $desc,
                            framework: (if $framework == "" or $framework == "None (flexible, domain-based)" then null else $framework end),
                            dimensions: (if $dims | test("^[0-9]+$") then ($dims | tonumber) else $dims end),
                            when_to_use: $when
                        }')"

                    templates="$(echo "$templates" | jq --argjson obj "$template_obj" '. + [$obj]')"
                fi

                # Start new template
                current_template="$(extract_template_name "$line")"
                current_framework=""
                current_dimensions=""
                current_characteristics=""
                in_template=true

                log_conditional "TEMPLATE" "Found template: $current_template"

            elif [[ "$in_template" == "true" ]]; then
                # Stop parsing at horizontal rule
                if echo "$line" | grep -q "^---"; then
                    # Save current template before exiting
                    if [[ -n "$current_template" ]]; then
                        log_conditional "TEMPLATE" "Saving template at section break: $current_template"

                        local description
                        local when_to_use
                        description="$(build_description "$current_template" "$current_framework" "$current_dimensions")"
                        when_to_use="$(build_when_to_use "$current_template" "$current_characteristics")"

                        local template_obj
                        template_obj="$(jq -n \
                            --arg name "$current_template" \
                            --arg desc "$description" \
                            --arg framework "$current_framework" \
                            --arg dims "$current_dimensions" \
                            --arg when "$when_to_use" \
                            '{
                                name: $name,
                                description: $desc,
                                framework: (if $framework == "" or $framework == "None (flexible, domain-based)" then null else $framework end),
                                dimensions: (if $dims | test("^[0-9]+$") then ($dims | tonumber) else $dims end),
                                when_to_use: $when
                            }')"

                        templates="$(echo "$templates" | jq --argjson obj "$template_obj" '. + [$obj]')"
                    fi

                    # Reset for next template
                    current_template=""
                    current_framework=""
                    current_dimensions=""
                    current_characteristics=""
                    in_template=false
                    continue
                fi

                # Extract metadata fields
                if echo "$line" | grep -qi "^\*\*Framework:"; then
                    current_framework="$(extract_field_value "$line")"

                elif echo "$line" | grep -qi "^\*\*Structure:"; then
                    # README uses **Structure:** instead of **Dimensions:**
                    local raw_dims
                    raw_dims="$(extract_field_value "$line")"
                    current_dimensions="$(extract_dimensions "$raw_dims")"
                fi
            fi
        fi

    done < "$readme_path"

    # Save last template if still in progress
    if [[ "$in_template" == "true" && -n "$current_template" ]]; then
        log_conditional "TEMPLATE" "Saving final template: $current_template"

        local description
        local when_to_use
        description="$(build_description "$current_template" "$current_framework" "$current_dimensions")"
        when_to_use="$(build_when_to_use "$current_template" "$current_characteristics")"

        local template_obj
        template_obj="$(jq -n \
            --arg name "$current_template" \
            --arg desc "$description" \
            --arg framework "$current_framework" \
            --arg dims "$current_dimensions" \
            --arg when "$when_to_use" \
            '{
                name: $name,
                description: $desc,
                framework: (if $framework == "" or $framework == "None (flexible, domain-based)" then null else $framework end),
                dimensions: (if $dims | test("^[0-9]+$") then ($dims | tonumber) else $dims end),
                when_to_use: $when
            }')"

        templates="$(echo "$templates" | jq --argjson obj "$template_obj" '. + [$obj]')"
    fi

    # Check if any templates found
    local template_count
    template_count="$(echo "$templates" | jq 'length')"

    log_metric "templates_found" "$template_count" "count"

    if [[ "$template_count" -eq 0 ]]; then
        error_json "No templates found in README.md" 1 '["generic"]'
    fi

    echo "$templates"
}

# Main execution
main() {
    log_phase "START" "Research template discovery"

    # Validate arguments
    if ! [[ $# -ne 1 || "$1" == "--json" ]]; then
        error_json "Usage: $0 --json" 2
    fi

    # Validate environment and get README path
    local readme_path
    readme_path="$(validate_environment)"

    # Parse README and extract templates
    local templates
    templates="$(parse_readme "$readme_path")"

    # Output success JSON
    jq -n --argjson templates "$templates" \
        '{success: true, templates: $templates}'

    log_phase "COMPLETE" "Template discovery successful"
}

main "$@"
