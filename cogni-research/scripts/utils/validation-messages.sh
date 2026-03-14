#!/usr/bin/env bash
set -euo pipefail
# validation-messages.sh
# Version: 1.0.0
# Purpose: Centralized error/warning message catalog for template integration validation
# Category: utilities
#
# Description:
#   Provides user-friendly error and warning messages for template integration
#   validation across synthesis skills (executive-synthesizer,
#   research-executor). Messages follow be-clear-and-direct principles with
#   actionable guidance and progressive disclosure (summary → details → fix steps).
#
# Usage:
#   Source this file in other scripts:
#     source "${PLUGIN_ROOT}/scripts/utils/validation-messages.sh"
#
#   Then call message functions:
#     show_error_template_not_found "smarter-service" "/path/to/template.md"
#     show_warning_template_fallback "competitive-intelligence"
#
# Functions:
#   show_error_template_not_found <research_type> <template_path>
#     - Display error when research type template is missing
#     - Provides steps to verify and restore template
#
#   show_error_horizons_incomplete <total_findings> <categorized_count> <uncategorized_count>
#     - Display error when action horizon categorization is incomplete
#     - Guidance for re-running with DEBUG_MODE and verifying research_type
#
#   show_error_missing_dimensions <dimension_slug>...
#     - Display error when dimension synthesis files are missing
#     - Accepts variadic array of missing dimension slugs
#     - Provides verification guidance for dimension synthesis
#
#   show_warning_template_fallback <research_type>
#     - Display warning when using generic synthesis instead of specific template
#     - Explains impact (generic structure, no framework categorization)
#
#   show_error_dimension_validation <dimension_slug> <validation_error>...
#     - Display error when dimension validation fails
#     - Accepts dimension slug and variadic array of validation errors
#     - Guidance for checking dimension file and questions
#
# Output:
#   All messages output to stderr (>&2) with clear formatting:
#   - Errors: ❌ prefix
#   - Warnings: ⚠️ prefix
#   - Multi-line heredoc format
#   - Includes problem statement, impact, and "To fix:" section
#
# Notes:
#   - Bash 3.2 compatible (no associative arrays)
#   - Source-able library (no direct execution)
#   - Variables used in messages for context specificity


# Function: show_error_template_not_found
# Display error when research type template is not found
#
# Arguments:
#   $1 - research_type: Research type identifier (e.g., "smarter-service")
#   $2 - template_path: Expected path to the template file
#
# Output:
#   Error message to stderr with verification and restoration steps
show_error_template_not_found() {
  local research_type="$1"
  local template_path="$2"

  cat >&2 <<EOF

❌ Research Type Template Not Found

Research type: ${research_type}
Expected path: ${template_path}

Impact: Synthesis will use generic structure instead of ${research_type}-aligned
output. You will lose framework-specific categorization and structured guidance.

To fix:
1. Verify template file exists:
   ls -la "${template_path}"

2. Check research_type in sprint log:
   cat "\${PROJECT_PATH}/.metadata/sprint-log.json" | jq '.research_type'

3. Restore template from:
   - GitHub: anthropics/claude-code marketplace
   - Local dev: cogni-research/references/research-types/${research_type}/

4. Verify template directory structure:
   ls -la "\${PLUGIN_ROOT}/references/research-types/${research_type}/"

Continuing with generic template...

EOF
}

# Function: show_error_horizons_incomplete
# Display error when action horizon categorization is incomplete for smarter-service
#
# Arguments:
#   $1 - total_findings: Total number of findings to categorize
#   $2 - categorized_count: Number of findings successfully categorized
#   $3 - uncategorized_count: Number of findings missing categorization
#
# Output:
#   Error message to stderr with debugging and verification steps
show_error_horizons_incomplete() {
  local total_findings="$1"
  local categorized_count="$2"
  local uncategorized_count="$3"

  cat >&2 <<EOF

❌ Incomplete Action Horizon Categorization

Total findings: ${total_findings}
Categorized: ${categorized_count}
Uncategorized: ${uncategorized_count}

Impact: Smarter-service research requires complete action horizon categorization
(Horizon 1/2/3). Incomplete categorization prevents proper strategic planning and
timeline-based recommendations.

To fix:
1. Re-run research-executor with DEBUG_MODE enabled:
   export DEBUG_MODE=true
   # Re-invoke research-executor skill

2. Check debug logs for categorization failures:
   cat /tmp/research-executor-debug.log | grep "horizon"

3. Verify research_type is set to "smarter-service":
   cat "\${PROJECT_PATH}/.metadata/sprint-log.json" | jq '.research_type'

4. Ensure all findings have valid horizon assignments in research data:
   cat "\${PROJECT_PATH}/.metadata/research-findings.json" | jq '[.findings[] | select(.horizon == null or .horizon == "")] | length'

5. If research_type is incorrect, update sprint-log.json and re-run synthesis:
   # Update research_type in sprint-log.json
   # Re-run executive-synthesizer skill

EOF
}

# Function: show_error_missing_dimensions
# Display error when dimension synthesis files are missing
#
# Arguments:
#   $@ - missing_dims_array: Variadic array of missing dimension slugs
#
# Output:
#   Error message to stderr with verification steps for dimension synthesis
show_error_missing_dimensions() {
  local missing_dims=("$@")
  local missing_count=${#missing_dims[@]}

  # Build comma-separated list of missing dimensions
  local missing_list=""
  for dim in "${missing_dims[@]}"; do
    if [[ -z "$missing_list" ]]; then
      missing_list="$dim"
    else
      missing_list="$missing_list, $dim"
    fi
  done

  cat >&2 <<EOF

❌ Missing Dimension Synthesis Files

Missing dimensions (${missing_count}): ${missing_list}

Impact: Executive synthesis requires all dimension files to be present.
Missing dimension files will result in incomplete analysis and broken cross-
references in the final report.

To fix:
1. Verify dimension synthesis ran for all dimensions:
   ls -la "\${PROJECT_PATH}/.artifacts/dimensions/"

2. Check for dimension synthesis errors in debug logs:
   cat /tmp/dimension-synthesis-debug.log | grep "ERROR"

3. Re-run dimension synthesis for missing dimensions:
   # The synthesis should process all dimensions automatically

4. Verify dimension configuration in sprint log:
   cat "\${PROJECT_PATH}/.metadata/sprint-log.json" | jq '.dimensions'

5. Check expected dimension files exist:
EOF

  for dim in "${missing_dims[@]}"; do
    cat >&2 <<EOF
   ls -la "\${PROJECT_PATH}/.artifacts/dimensions/${dim}.md"
EOF
  done

  cat >&2 <<EOF

EOF
}

# Function: show_warning_template_fallback
# Display warning when using generic synthesis instead of research-type template
#
# Arguments:
#   $1 - research_type: Research type identifier that has no template
#
# Output:
#   Warning message to stderr explaining impact of generic template usage
show_warning_template_fallback() {
  local research_type="$1"

  cat >&2 <<EOF

⚠️  Template Not Found - Using Generic Synthesis

Research type: ${research_type}

Impact: The synthesis will use a generic document structure instead of the
${research_type}-specific template. This means:
  - Generic headings instead of framework-aligned sections
  - No research-type-specific categorization (e.g., action horizons, SWOT)
  - Standard markdown structure without specialized guidance
  - Cross-references may not align with expected ${research_type} format

The synthesis will still be complete and accurate, but won't follow the
specialized structure for ${research_type} research.

To add a template for future research:
1. Create template directory:
   mkdir -p "\${PLUGIN_ROOT}/references/research-types/${research_type}"

2. Add template file:
   touch "\${PLUGIN_ROOT}/references/research-types/${research_type}/synthesis-template.md"

3. Define template structure following existing research type patterns:
   cat "\${PLUGIN_ROOT}/references/research-types/smarter-service/synthesis-template.md"

Continuing with generic synthesis...

EOF
}

# Function: show_error_dimension_validation
# Display error when dimension validation fails
#
# Arguments:
#   $1 - dimension_slug: Dimension identifier (e.g., "market-trends")
#   $@ - validation_errors_array: Variadic array of validation error messages
#
# Output:
#   Error message to stderr with specific validation failures and fix steps
show_error_dimension_validation() {
  local dimension_slug="$1"
  shift
  local validation_errors=("$@")
  local error_count=${#validation_errors[@]}

  cat >&2 <<EOF

❌ Dimension Validation Failed

Dimension: ${dimension_slug}
Validation errors: ${error_count}

Errors:
EOF

  # List each validation error with bullet point
  for error in "${validation_errors[@]}"; do
    cat >&2 <<EOF
  • ${error}
EOF
  done

  cat >&2 <<EOF

Impact: Dimension synthesis cannot proceed with invalid dimension data.
Missing or malformed dimension files will cause synthesis to fail or produce
incomplete results.

To fix:
1. Check dimension file exists:
   ls -la "\${PROJECT_PATH}/.artifacts/dimensions/${dimension_slug}.md"

2. Verify dimension has questions defined:
   cat "\${PROJECT_PATH}/.metadata/sprint-log.json" | jq '.dimensions[] | select(.slug == "${dimension_slug}") | .questions'

3. Check dimension file is not empty:
   wc -l "\${PROJECT_PATH}/.artifacts/dimensions/${dimension_slug}.md"

4. Review dimension synthesis logs for processing errors:
   cat /tmp/dimension-synthesis-debug.log | grep "${dimension_slug}"

5. Re-run dimension synthesis for this dimension:
   export DEBUG_MODE=true
   # Re-invoke dimension synthesis

6. Validate dimension file format:
   head -20 "\${PROJECT_PATH}/.artifacts/dimensions/${dimension_slug}.md"

EOF
}
