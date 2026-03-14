# Phase 5: Validation & Output

## Phase Objective

Verify citation provenance and return JSON execution summary. Abort if validation fails. Ensure all cited entity IDs exist in filesystem.

---

## ⛔ PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 4 is marked complete. Phase 5 cannot begin until Phase 4 todos are completed.

**THEN verify Phase 4 completion:**

**Phase 4a Outputs (REQUIRED - always present):**
- [ ] research-hub.md exists (renamed from research-hub.md)
- [ ] 00-research-scope.md exists
- [ ] 00-pipeline-metrics.md exists
- [ ] 06-megatrends/README.md enhanced
- [ ] 11-trends/README.md enhanced
- [ ] 12-synthesis/synthesis-cross-dimensional.md exists

**Note:** insight-summary.md validation is handled by deeper-research-3 Phase 13 (Step 1.5), not by synthesis-hub.

**General Validation:**
- [ ] Citations use correct wikilink format `[[path|title]]`
- [ ] Pre-Phase-5 validation checkpoint PASSED

**IF MISSING: STOP. Return to Phase 4.**

---

## Step 0.5: Initialize Phase 5 TodoWrite

Add step-level todos for Phase 5:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 5, Step 1: Extract citation entity paths [in_progress]
- Phase 5, Step 2: Validate entity paths exist [pending]
- Phase 5, Step 2.5: German text validation (if de) [pending]
- Phase 5, Step 2.7: Validate megatrend completeness [pending]
- Phase 5, Step 2.8: Validate trend wikilinks in kanban table [pending]
- Phase 5, Step 2.9: Validate trend planning horizon coverage [pending]
- Phase 5, Step 2.95: Entity catalog validation (arc-aware) [pending]
- Phase 5, Step 3: Generate execution metrics [pending]
- Phase 5, Step 4.5.0: Collect full pipeline metrics [pending]
- Phase 5, Step 4.5: Format enhanced metrics table [pending]
- Phase 5, Step 5: Return JSON summary [pending]

As you complete each step, mark the corresponding todo as completed.
```

**Mark Step 0.5 complete** after TodoWrite initialization.

---

## Phase Start

```bash
log_phase "Phase 5: Validation & Output" "start"
```

## Why Validation Matters

**The Problem:**
- LLMs can generate plausible-looking entity paths that don't exist
- Synthesis may reference trends/concepts/megatrends not in the dataset
- Invalid citations break Obsidian graph connectivity
- Fabricated references undermine research integrity
- Shallow synthesis with low citation counts fails to leverage available evidence

**The Solution:**
- Phase 2: Build complete entity map during loading
- Phase 4: Create synthesis report with citations from loaded entities
- Phase 5: Pre-completion validation before returning summary
- Abort if any fabricated entity paths detected
- Abort if citation coverage too low

---

## Step 1: Extract Citation Entity Paths

Parse research-hub.md for all markdown link citations:

```bash
log_conditional INFO "Extracting citation entity paths from research-hub.md..."

# Extract all markdown links with relative paths
all_citations=$(grep -oE '\]\(\.\./[^)]+\.md\)' "${PROJECT_PATH}/research-hub.md" | sed 's/](\(.*\))/\1/g')

# Count total citations
total_citations=$(echo "$all_citations" | wc -l | tr -d ' ')

log_conditional INFO "Found $total_citations citations to validate"

# Build array of cited paths
cited_paths=()
while IFS= read -r citation; do
  cited_paths+=("$citation")
done <<< "$all_citations"
```

### Citation Format Expected

All citations must use wikilink format with vault-relative paths (no `../`, no `.md`):

- **Trends:** `[[11-trends/data/trend-{slug}-{hash}|title]]`
- **Concepts:** `[[05-domain-concepts/data/concept-{slug}-{hash}|title]]`
- **Megatrends:** `[[06-megatrends/data/megatrend-{slug}-{hash}\|title]]`
- **Dimensions:** `[[01-research-dimensions/data/dimension-{slug}|title]]`

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate Entity Paths Exist

For each extracted citation path, verify file exists:

```bash
log_conditional INFO "Validating all citation paths exist in filesystem..."

invalid_citations=""
invalid_citation_details=""
invalid_count=0

# Validate each citation
for citation_path in "${cited_paths[@]}"; do
  # Resolve relative path to absolute
  # citation_path format: ../XX-directory/entity-file.md
  resolved_path="${PROJECT_PATH}/${citation_path#../}"

  # Check file exists
  if [ ! -f "$resolved_path" ]; then
    invalid_citations="$invalid_citations $citation_path"
    invalid_citation_details="$invalid_citation_details\n- $citation_path → $resolved_path (NOT FOUND)"
    invalid_count=$((invalid_count + 1))
    log_conditional ERROR "Fabricated citation: $citation_path (file not found: $resolved_path)"
  fi
done

log_conditional INFO "Validation results: $invalid_count invalid citations"

if [ "$invalid_count" -gt 0 ]; then
  log_conditional ERROR "Fabricated entity paths detected!"
  log_conditional ERROR "Invalid citations:$invalid_citation_details"
  validation_passed=false
else
  log_conditional INFO "All citations valid - no fabricated entities"
  validation_passed=true
fi
```

### Validation Error Response

**IF ANY FABRICATED:**

```json
{
  "success": false,
  "error": "Fabricated entity IDs detected",
  "fabricated_entities": [
    "11-trends/data/trend-nonexistent-abc123 → /path/to/11-trends/data/trend-nonexistent-abc123.md (NOT FOUND)",
    "05-domain-concepts/data/concept-invalid-def456 → /path/to/05-domain-concepts/data/concept-invalid-def456.md (NOT FOUND)"
  ],
  "fabricated_count": 2,
  "partial_output": "research-hub.md",
  "remediation": "Re-run synthesis with complete entity loading. Ensure Phase 2 entity manifest includes all available entities."
}
```

**ABORT if fabricated entities found.**

**Mark Step 2 todo as completed** before proceeding to Step 2.5.

---

## Step 2.5: German Text Validation (if project_language == "de")

Check for ASCII fallbacks in body text that should use proper umlauts:

```bash
log_conditional INFO "Checking for German umlaut compliance..."

# Read project language from sprint-log.json
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null || echo "en")

if [ "$PROJECT_LANGUAGE" = "de" ]; then
  log_conditional INFO "German project detected - validating umlaut usage"

  # Common ASCII fallback patterns that indicate missing umlauts
  # These patterns appear in word context (not file paths/slugs)
  german_violations=""
  german_violation_count=0

  # Check for common violations (case-insensitive word patterns)
  # Exclude code blocks, file paths, and YAML frontmatter
  report_body=$(sed -n '/^---$/,/^---$/d; /^```/,/^```$/d; p' "${PROJECT_PATH}/research-hub.md")

  # Check for "fuer" (should be "für")
  fuer_count=$(echo "$report_body" | grep -ioE '\bfuer\b' | wc -l | tr -d ' ')
  if [ "$fuer_count" -gt 0 ]; then
    german_violations="$german_violations\n- 'fuer' found $fuer_count times (should be 'für')"
    german_violation_count=$((german_violation_count + fuer_count))
  fi

  # Check for "ueber" (should be "über")
  ueber_count=$(echo "$report_body" | grep -ioE '\bueber' | wc -l | tr -d ' ')
  if [ "$ueber_count" -gt 0 ]; then
    german_violations="$german_violations\n- 'ueber' found $ueber_count times (should be 'über')"
    german_violation_count=$((german_violation_count + ueber_count))
  fi

  # Check for "aenderung" (should be "Änderung")
  aenderung_count=$(echo "$report_body" | grep -ioE 'aenderung' | wc -l | tr -d ' ')
  if [ "$aenderung_count" -gt 0 ]; then
    german_violations="$german_violations\n- 'aenderung' found $aenderung_count times (should be 'Änderung')"
    german_violation_count=$((german_violation_count + aenderung_count))
  fi

  # Check for "grundsaetzlich" (should be "grundsätzlich")
  grundsaetzlich_count=$(echo "$report_body" | grep -ioE 'grundsaetzlich' | wc -l | tr -d ' ')
  if [ "$grundsaetzlich_count" -gt 0 ]; then
    german_violations="$german_violations\n- 'grundsaetzlich' found $grundsaetzlich_count times (should be 'grundsätzlich')"
    german_violation_count=$((german_violation_count + grundsaetzlich_count))
  fi

  # Check for "oe" patterns in words (potential ö violations)
  oe_count=$(echo "$report_body" | grep -oE '\b[a-zA-Z]*oe[a-zA-Z]*\b' | grep -ivE '(toe|shoe|poem|poet|goes|does|foe)' | wc -l | tr -d ' ')
  if [ "$oe_count" -gt 5 ]; then
    german_violations="$german_violations\n- Multiple 'oe' patterns detected ($oe_count occurrences) - check for missing 'ö'"
  fi

  # Check for "ae" patterns in words (potential ä violations)
  ae_count=$(echo "$report_body" | grep -oE '\b[a-zA-Z]*ae[a-zA-Z]*\b' | grep -ivE '(aero|caesar)' | wc -l | tr -d ' ')
  if [ "$ae_count" -gt 5 ]; then
    german_violations="$german_violations\n- Multiple 'ae' patterns detected ($ae_count occurrences) - check for missing 'ä'"
  fi

  if [ "$german_violation_count" -gt 0 ]; then
    log_conditional WARNING "German umlaut violations detected:$german_violations"
    log_conditional WARNING "Total violations: $german_violation_count"
    german_text_validation_passed=false
  else
    log_conditional INFO "German umlaut validation PASSED - proper umlauts used"
    german_text_validation_passed=true
  fi
else
  log_conditional INFO "Non-German project - skipping umlaut validation"
  german_text_validation_passed=true
  german_violation_count=0
fi
```

### German Text Validation Response

**IF VIOLATIONS FOUND (Warning - does not abort):**

Include in JSON response:

```json
{
  "german_text_warnings": [
    "'fuer' found 5 times (should be 'für')",
    "'ueber' found 3 times (should be 'über')",
    "'grundsaetzlich' found 2 times (should be 'grundsätzlich')"
  ],
  "german_violation_count": 10,
  "remediation": "Re-run synthesis ensuring German body text uses proper umlauts (ä, ö, ü, ß) instead of ASCII fallbacks (ae, oe, ue, ss)"
}
```

**Note:** German text violations generate warnings but do not abort validation. The report is still valid but should be reviewed for umlaut compliance.

**Mark Step 2.5 todo as completed** before proceeding to Step 2.7.

---

## Step 2.7: Validate Megatrend Completeness

**Goal:** Ensure 100% of megatrend files are represented in research-hub.md.

**⚠️ CRITICAL:** Unlike citation validation (which checks for fabricated paths), this step validates COMPLETENESS - ensuring every real megatrend file appears in the report.

```bash
log_conditional INFO "Validating megatrend completeness..."

# Count megatrend files on filesystem
megatrend_files=$(ls "${PROJECT_PATH}/06-megatrends/data/megatrend-"*.md 2>/dev/null)
total_megatrends=$(echo "$megatrend_files" | grep -c "megatrend-" || echo 0)

log_conditional INFO "Found $total_megatrends megatrend files in 06-megatrends/data/"

# Extract megatrend references from research-hub.md
# Check both kanban table wikilinks and narrative inline links
megatrends_in_report=$(grep -oE '06-megatrends/data/megatrend-[a-z0-9-]+' "${PROJECT_PATH}/research-hub.md" | sort -u)
megatrends_in_report_count=$(echo "$megatrends_in_report" | grep -c "megatrend-" || echo 0)

log_conditional INFO "Found $megatrends_in_report_count unique megatrend references in report"

# Compare: find missing megatrends
missing_megatrends=""
missing_count=0

for megatrend_file in $megatrend_files; do
  # Extract slug from filename (e.g., megatrend-industrial-ai-a1b2c3d4)
  megatrend_slug=$(basename "$megatrend_file" .md)

  if echo "$megatrends_in_report" | grep -q "$megatrend_slug"; then
    : # Megatrend found in report, continue
  else
    missing_megatrends="$missing_megatrends\n- $megatrend_slug"
    missing_count=$((missing_count + 1))
    log_conditional ERROR "Missing megatrend in report: $megatrend_slug"
  fi
done

# Calculate coverage
if [ "$total_megatrends" -gt 0 ]; then
  megatrend_coverage_percent=$((megatrends_in_report_count * 100 / total_megatrends))
else
  megatrend_coverage_percent=100
fi

log_conditional INFO "Megatrend coverage: $megatrend_coverage_percent%"

# Validation decision
if [ "$missing_count" -gt 0 ]; then
  log_conditional ERROR "Megatrend completeness validation FAILED"
  log_conditional ERROR "Missing megatrends:$missing_megatrends"
  megatrend_completeness_passed=false
else
  log_conditional INFO "Megatrend completeness validation PASSED - all megatrends included"
  megatrend_completeness_passed=true
fi
```

### Validation Rule

**IF megatrends_in_report < total_megatrends:**

- Set `megatrend_completeness_passed = false`
- Set `validation_passed = false`
- Include in error response:

```json
{
  "megatrend_coverage_failed": true,
  "total_megatrends": 7,
  "megatrends_in_report": 5,
  "missing_megatrends": [
    "megatrend-digital-skills-workforce-f6g7h8i9",
    "megatrend-industrial-cybersecurity-d4e5f6g7"
  ],
  "remediation": "Re-run Phase 4 Step 5.3 to add missing megatrends to narrative synthesis"
}
```

**Success Criteria:** `megatrends_in_report == total_megatrends` (100% coverage required)

**Mark Step 2.7 todo as completed** before proceeding to Step 2.8.

---

## Step 2.8: Validate Trend Wikilinks in Kanban Table

**Goal:** Ensure ALL trend entries in the kanban table have proper wikilinks (not plain text).

**⚠️ CRITICAL:** This step catches a common generation error where trends appear as plain text like `**I:** Predictive Maintenance` instead of proper wikilinks like `**I:** [[11-trends/data/trend-{slug}|{title}]]`.

```bash
log_conditional INFO "Validating trend wikilinks in kanban table..."

# Extract the kanban table section (between "Trendlandschaft" header and "<!-- kanban-board -->")
kanban_section=$(sed -n '/^## Trendlandschaft/,/<!-- kanban-board -->/p' "${PROJECT_PATH}/research-hub.md" 2>/dev/null || \
                 sed -n '/^## Trend Landscape/,/<!-- kanban-board -->/p' "${PROJECT_PATH}/research-hub.md")

# Count **I:** entries (trends in table)
total_trend_entries=$(echo "$kanban_section" | grep -oE '\*\*I:\*\*' | wc -l | tr -d ' ')

# Count **I:** entries WITH wikilinks (correct format)
trend_entries_with_wikilinks=$(echo "$kanban_section" | grep -oE '\*\*I:\*\* \[\[11-trends/data/trend-' | wc -l | tr -d ' ')

# Count **I:** entries WITHOUT wikilinks (incorrect - plain text)
trend_entries_plain_text=$((total_trend_entries - trend_entries_with_wikilinks))

log_conditional INFO "Trend entries in kanban table: $total_trend_entries"
log_conditional INFO "Entries with wikilinks: $trend_entries_with_wikilinks"
log_conditional INFO "Entries as plain text (ERROR): $trend_entries_plain_text"

# Extract plain text trend names for error reporting
plain_text_trends=""
if [ "$trend_entries_plain_text" -gt 0 ]; then
  # Find **I:** entries not followed by [[
  plain_text_trends=$(echo "$kanban_section" | grep -oE '\*\*I:\*\* [^<\[]+' | grep -v '\[\[' | sed 's/\*\*I:\*\* //' | head -20)
  log_conditional ERROR "Trends missing wikilinks:$plain_text_trends"
fi

# Validation decision
if [ "$trend_entries_plain_text" -gt 0 ]; then
  log_conditional ERROR "Trend wikilink validation FAILED"
  log_conditional ERROR "$trend_entries_plain_text trend(s) in kanban table are plain text instead of wikilinks"
  trend_wikilink_validation_passed=false
else
  log_conditional INFO "Trend wikilink validation PASSED - all trends have wikilinks"
  trend_wikilink_validation_passed=true
fi
```

### Validation Rule

**IF trend_entries_plain_text > 0:**

- Set `trend_wikilink_validation_passed = false`
- Set `validation_passed = false`
- Include in error response:

```json
{
  "trend_wikilink_failed": true,
  "total_trend_entries": 45,
  "entries_with_wikilinks": 0,
  "entries_plain_text": 45,
  "plain_text_examples": [
    "Predictive Maintenance",
    "MES-Modernisierung",
    "KI-Qualitätskontrolle"
  ],
  "remediation": "Re-run Phase 4 Step 3.1 - load trend YAML frontmatter (dc:identifier, dc:title) and format as [[11-trends/data/{dc:identifier}|{dc:title}]]"
}
```

**Success Criteria:** `trend_entries_plain_text == 0` (all trends must have wikilinks)

**Mark Step 2.8 todo as completed** before proceeding to Step 2.9.

---

## Step 2.9: Validate Trend Planning Horizon Coverage

**Goal:** Report warnings for trends missing `planning_horizon` field to identify data quality issues.

**⚠️ NOTE:** This is a WARNING validation. Missing `planning_horizon` does not block synthesis (trends default to "plan"), but warnings help identify incomplete metadata.

```bash
log_conditional INFO "Validating trend planning horizon coverage..."

# Count total trend files on filesystem
trend_files=$(ls "${PROJECT_PATH}/11-trends/data/trend-"*.md 2>/dev/null)
total_trend_files=$(echo "$trend_files" | grep -c "trend-" || echo 0)

log_conditional INFO "Found $total_trend_files trend files in 11-trends/data/"

# Count trends WITH planning_horizon field (grep for 'planning_horizon:' in frontmatter)
trends_with_horizon=0
trends_without_horizon=0
missing_horizon_list=""

for trend_file in $trend_files; do
  # Check if file has planning_horizon field in YAML frontmatter
  if grep -q "^planning_horizon:" "$trend_file" 2>/dev/null; then
    trends_with_horizon=$((trends_with_horizon + 1))
  else
    trends_without_horizon=$((trends_without_horizon + 1))
    trend_slug=$(basename "$trend_file" .md)
    missing_horizon_list="$missing_horizon_list\n- $trend_slug"
    log_conditional WARNING "Trend missing planning_horizon: $trend_slug"
  fi
done

log_conditional INFO "Trends WITH planning_horizon: $trends_with_horizon"
log_conditional INFO "Trends WITHOUT planning_horizon: $trends_without_horizon"

# Count trend entries in kanban table (grep for **T:** pattern)
trends_in_kanban=$(grep -oE '\*\*T:\*\*' "${PROJECT_PATH}/research-hub.md" 2>/dev/null | wc -l | tr -d ' ')
log_conditional INFO "Trend entries in kanban table: $trends_in_kanban"

# Calculate coverage
if [ "$total_trend_files" -gt 0 ]; then
  horizon_coverage_percent=$((trends_with_horizon * 100 / total_trend_files))
else
  horizon_coverage_percent=100
fi

log_conditional INFO "Planning horizon coverage: $horizon_coverage_percent%"

# Generate warnings (does not block validation)
trend_horizon_warnings=""
if [ "$trends_without_horizon" -gt 0 ]; then
  log_conditional WARNING "Trend metadata quality issue: $trends_without_horizon trend(s) missing planning_horizon field"
  log_conditional WARNING "Missing planning_horizon trends:$missing_horizon_list"
  trend_horizon_warnings="$trends_without_horizon trend(s) missing planning_horizon field (defaulted to 'plan' horizon)"
else
  log_conditional INFO "Trend planning horizon validation PASSED - all trends have planning_horizon"
fi
```

### Validation Output

This validation generates **warnings**, not errors:

```markdown
**Trend Planning Horizon Report:**
- Total trends: {total_trend_files}
- Trends with planning_horizon: {trends_with_horizon}
- Trends without planning_horizon: {trends_without_horizon}
- Horizon coverage: {horizon_coverage_percent}%
- Trends in kanban table: {trends_in_kanban}
- Status: WARNING (if trends_without_horizon > 0) | PASS
```

### Warning Response (Non-Blocking)

**IF trends_without_horizon > 0:**

Include in JSON response warnings array:

```json
{
  "warnings": [
    "{N} trend(s) missing planning_horizon field (defaulted to 'plan' horizon)",
    "Consider adding planning_horizon field to trend entities for accurate temporal classification"
  ],
  "trend_horizon_metadata": {
    "total_trends": 31,
    "with_planning_horizon": 0,
    "without_planning_horizon": 31,
    "horizon_coverage_percent": 0,
    "missing_horizon_examples": [
      "trend-predictive-maintenance-a1b2c3",
      "trend-mes-modernization-d4e5f6",
      "trend-ai-quality-control-g7h8i9"
    ]
  }
}
```

**Note:** These are informational warnings. Synthesis continues successfully. Trends without `planning_horizon` appear in the "plan" column by default (Phase 4 Step 3 algorithm).

**Mark Step 2.9 todo as completed** before proceeding to Step 2.95.

---

## Step 2.95: Entity Catalog Validation (Arc-Aware)

**Objective:** Verify all entity wikilinks in synthesis-cross-dimensional.md reference loaded entities (prevent hallucinated file paths).

**⚠️ CRITICAL:** This step catches arc-specific synthesis errors where entity file paths are fabricated instead of using loaded registry IDs.

**Guard Clause:**

```bash
arc_id=$(jq -r '.arc_id // ""' "${PROJECT_PATH}/.metadata/sprint-log.json")

if [ -z "${arc_id}" ]; then
  echo "No arc specified - skipping entity catalog validation"
  continue_to_step_3
fi

echo "Arc detected: ${arc_id}"
echo "Validating entity catalog references..."
```

**Extract Wikilinks from synthesis-cross-dimensional.md:**

```bash
# Check if synthesis-cross-dimensional.md exists
if [ ! -f "${PROJECT_PATH}/12-synthesis/synthesis-cross-dimensional.md" ]; then
  log_conditional ERROR "synthesis-cross-dimensional.md not found - arc synthesis may have failed"
  entity_catalog_validation_passed=false
  continue_to_step_3
fi

# Parse [[path|display]] or [[path]] patterns
wikilinks=$(grep -oE '\[\[([^]|]+)(\|[^]]+)?\]\]' \
  "${PROJECT_PATH}/12-synthesis/synthesis-cross-dimensional.md" 2>/dev/null | \
  sed -E 's/\[\[([^]|]+).*\]\]/\1/')

wikilink_count=$(echo "${wikilinks}" | grep -c "." || echo 0)

log_conditional INFO "Found ${wikilink_count} wikilinks in synthesis-cross-dimensional.md"
```

**Validate Against Entity Catalogs:**

```bash
validation_failed=false
invalid_wikilinks=()
invalid_wikilink_details=""

for wikilink_path in ${wikilinks}; do
  # Check if path exists in any loaded entity registry
  if entity_in_catalog "${wikilink_path}"; then
    : # Valid wikilink, continue
  else
    validation_failed=true
    invalid_wikilinks+=("${wikilink_path}")
    invalid_wikilink_details="${invalid_wikilink_details}\n- ${wikilink_path} (not in loaded entity registries)"
    log_conditional ERROR "Hallucinated entity path: ${wikilink_path}"
  fi
done

# Function to check if entity exists in loaded catalogs
entity_in_catalog() {
  local path=$1

  # Check FINDINGS_REGISTRY (if arc tier >= 1)
  if [[ "${path}" == 04-findings/data/* ]]; then
    if finding_exists_in_registry "${path}"; then
      return 0
    fi
  fi

  # Check SOURCES_REGISTRY (if arc tier >= 1)
  if [[ "${path}" == 07-sources/data/* ]]; then
    if source_exists_in_registry "${path}"; then
      return 0
    fi
  fi

  # Check TRENDS_REGISTRY (if arc tier >= 2)
  if [[ "${path}" == 11-trends/data/* ]]; then
    if trend_exists_in_registry "${path}"; then
      return 0
    fi
  fi

  # Check CONCEPTS_REGISTRY (if arc tier >= 4)
  if [[ "${path}" == 05-domain-concepts/data/* ]]; then
    if concept_exists_in_registry "${path}"; then
      return 0
    fi
  fi

  # Check DIMENSION_REGISTRY (always loaded)
  if [[ "${path}" == 12-synthesis/synthesis-*.md ]]; then
    if dimension_exists_in_registry "${path}"; then
      return 0
    fi
  fi

  # Not found in any catalog
  return 1
}

# Implement registry lookup functions
finding_exists_in_registry() {
  local path=$1
  # Extract UUID from path (e.g., finding-{slug}-{hash})
  local finding_id=$(basename "${path}" .md)

  # Check if FINDINGS_REGISTRY contains this UUID
  # (Assume FINDINGS_REGISTRY was built in Phase 3 Step 0.95)
  if echo "${FINDINGS_REGISTRY}" | grep -q "${finding_id}"; then
    return 0
  else
    return 1
  fi
}

source_exists_in_registry() {
  local path=$1
  local source_id=$(basename "${path}" .md)

  if echo "${SOURCES_REGISTRY}" | grep -q "${source_id}"; then
    return 0
  else
    return 1
  fi
}

trend_exists_in_registry() {
  local path=$1
  local trend_id=$(basename "${path}" .md)

  if echo "${TRENDS_REGISTRY}" | grep -q "${trend_id}"; then
    return 0
  else
    return 1
  fi
}

concept_exists_in_registry() {
  local path=$1
  local concept_id=$(basename "${path}" .md)

  if echo "${CONCEPTS_REGISTRY}" | grep -q "${concept_id}"; then
    return 0
  else
    return 1
  fi
}

dimension_exists_in_registry() {
  local path=$1
  local dimension_slug=$(basename "${path}" .md | sed 's/synthesis-//')

  if echo "${DIMENSION_REGISTRY}" | grep -q "${dimension_slug}"; then
    return 0
  else
    return 1
  fi
}
```

**Validation Decision:**

```bash
invalid_count=${#invalid_wikilinks[@]}

if [ "${validation_failed}" = true ]; then
  log_conditional ERROR "Entity catalog validation FAILED"
  log_conditional ERROR "${invalid_count} hallucinated entity path(s) detected:${invalid_wikilink_details}"
  entity_catalog_validation_passed=false
else
  log_conditional INFO "Entity catalog validation PASSED - all wikilinks reference loaded entities"
  entity_catalog_validation_passed=true
fi
```

**If Validation Fails:**

Return error JSON with hallucination details:

```json
{
  "success": false,
  "error": "hallucination_detected",
  "phase": "5.2.95",
  "invalid_wikilinks": [
    "04-findings/data/finding-invented-uuid.md",
    "11-trends/data/trend-fabricated-uuid.md",
    "05-domain-concepts/data/concept-nonexistent-uuid.md"
  ],
  "invalid_count": 3,
  "guidance": "Phase 4 arc synthesis fabricated entity file paths. Re-run Phase 4 with strict constraint: ONLY use entity IDs from loaded registries (FINDINGS_REGISTRY, SOURCES_REGISTRY, TRENDS_REGISTRY, CONCEPTS_REGISTRY, DIMENSION_REGISTRY). Do not invent UUIDs or file paths."
}
```

**If Validation Passes:**

```bash
echo "=== ENTITY CATALOG VALIDATION: PASSED ==="
echo "All ${wikilink_count} wikilinks reference loaded entities (no hallucinated paths)"
```

**Mark Step 2.95 todo as completed** before proceeding to Step 3.

---

## Step 3: Generate Execution Metrics

Calculate and document synthesis execution metrics:

```bash
log_conditional INFO "Calculating execution metrics..."

# Calculate word count of report
word_count=$(wc -w < "${PROJECT_PATH}/research-hub.md" | tr -d ' ')

# Count entities synthesized by type
trends_count=0
concepts_count=0
megatrends_count=0
dimensions_count=0

for citation in "${cited_paths[@]}"; do
  if [ "$citation" == *"/11-trends/data/"* ]; then
    trends_count=$((trends_count + 1))
  elif [ "$citation" == *"/05-domain-concepts/data/"* ]; then
    concepts_count=$((concepts_count + 1))
  elif [ "$citation" == *"/06-megatrends/data/"* ]; then
    megatrends_count=$((megatrends_count + 1))
  elif [ "$citation" == *"/01-research-dimensions/data/"* ]; then
    dimensions_count=$((dimensions_count + 1))
  fi
done

# Calculate unique entities (deduplicate)
unique_trends=$(echo "${cited_paths[@]}" | tr ' ' '\n' | grep "11-trends" | sort -u | wc -l | tr -d ' ')
unique_concepts=$(echo "${cited_paths[@]}" | tr ' ' '\n' | grep "05-domain-concepts" | sort -u | wc -l | tr -d ' ')
unique_megatrends=$(echo "${cited_paths[@]}" | tr ' ' '\n' | grep "06-megatrends" | sort -u | wc -l | tr -d ' ')

# Get available entity counts from entity manifest
total_trends=$(echo "$entity_manifest" | grep "11-trends/data/" | wc -l | tr -d ' ')
total_concepts=$(echo "$entity_manifest" | grep "05-domain-concepts/data/" | wc -l | tr -d ' ')
total_megatrends=$(echo "$entity_manifest" | grep "06-megatrends/data/" | wc -l | tr -d ' ')

# Calculate coverage
if [ "$total_trends" -gt 0 ]; then
  trends_coverage_percent=$((unique_trends * 100 / total_trends))
else
  trends_coverage_percent=0
fi

# Log metrics
log_metric "total_citations" "$total_citations" "count"
log_metric "word_count" "$word_count" "count"
log_metric "trends_synthesized" "$unique_trends" "count"
log_metric "concepts_integrated" "$unique_concepts" "count"
log_metric "megatrends_analyzed" "$unique_megatrends" "count"
log_metric "validation_passed" "$validation_passed" "boolean"
```

### Metrics Tracked

**Core Metrics:**
- `total_citations`: Total citation count in research-hub.md
- `word_count`: Word count of final synthesis report

**Entity Metrics:**
- `trends_synthesized`: Unique trends referenced
- `concepts_integrated`: Unique concepts referenced
- `megatrends_analyzed`: Unique megatrends referenced
- `dimensions_referenced`: Unique dimensions referenced

**Coverage Metrics:**
- `trends_coverage_percent`: (Unique trends cited / Total available) * 100
- `concepts_coverage_percent`: (Unique concepts cited / Total available) * 100
- `megatrends_coverage_percent`: (Unique megatrends cited / Total available) * 100

**Validation:**
- `validation_passed`: true/false (all citations valid)
- `fabricated_count`: Count of fabricated entity paths (0 required)

**Mark Step 3 todo as completed** before proceeding to Step 4.5.0.

---

## Step 4.5.0: Collect Full Pipeline Metrics

**Goal:** Count total entities generated across all 12 pipeline phases for comprehensive metrics reporting.

```bash
log_conditional INFO "Collecting full pipeline metrics from all phases..."

# Function to count files safely with graceful degradation
count_phase_files() {
  local phase_dir="$1"
  local pattern="$2"
  local count=0

  if [ -d "${PROJECT_PATH}/${phase_dir}/data" ]; then
    count=$(ls -1 "${PROJECT_PATH}/${phase_dir}/data/"${pattern} 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "$count"
}

# Function to count files in directory without /data subdirectory
count_phase_files_direct() {
  local phase_dir="$1"
  local pattern="$2"
  local count=0

  if [ -d "${PROJECT_PATH}/${phase_dir}" ]; then
    count=$(ls -1 "${PROJECT_PATH}/${phase_dir}/"${pattern} 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "$count"
}

# Collect metrics for each phase
total_initial_questions=$(count_phase_files "00-initial-question" "question-*.md")
total_refined_questions=$(count_phase_files "02-refined-questions" "question-*.md")
total_query_batches=$(count_phase_files "03-query-batches" "batch-*.md")
total_findings=$(count_phase_files "04-findings" "finding-*.md")
total_domain_concepts=$(count_phase_files "05-domain-concepts" "concept-*.md")
total_megatrends_all=$(count_phase_files "06-megatrends" "megatrend-*.md")
total_sources=$(count_phase_files "07-sources" "source-*.md")
total_publishers=$(count_phase_files "08-publishers" "publisher-*.md")
total_citations=$(count_phase_files "09-citations" "citation-*.md")
total_claims=$(count_phase_files "10-claims" "claim-*.md")
total_trends_all=$(count_phase_files "11-trends" "trend-*.md")
total_dimension_syntheses=$(count_phase_files_direct "12-synthesis" "synthesis-*.md")

# Calculate total entities generated
total_entities_generated=$((total_initial_questions + total_refined_questions + total_query_batches + total_findings + total_domain_concepts + total_megatrends_all + total_sources + total_publishers + total_citations + total_claims + total_trends_all + total_dimension_syntheses))

log_conditional INFO "Pipeline metrics collected: total_entities_generated=$total_entities_generated"
log_conditional INFO "  00 Initial Questions: $total_initial_questions"
log_conditional INFO "  02 Refined Questions: $total_refined_questions"
log_conditional INFO "  03 Query Batches: $total_query_batches"
log_conditional INFO "  04 Findings: $total_findings"
log_conditional INFO "  05 Domain Concepts: $total_domain_concepts"
log_conditional INFO "  06 Megatrends: $total_megatrends_all"
log_conditional INFO "  07 Sources: $total_sources"
log_conditional INFO "  08 Publishers: $total_publishers"
log_conditional INFO "  09 Citations: $total_citations"
log_conditional INFO "  10 Claims: $total_claims"
log_conditional INFO "  11 Trends: $total_trends_all"
log_conditional INFO "  12 Dimension Syntheses: $total_dimension_syntheses"
```

**Mark Step 4.5.0 todo as completed** before proceeding to Step 4.5.1.

---

## Step 4.5: Calculate and Insert Statistics

**Goal:** Replace `{STATISTICS_PLACEHOLDER}` in research-hub.md with full pipeline metrics AND entity statistics.

### Step 4.5.1: Count Wikilinks by Type

Extract and count wikilinks from research-hub.md:

```bash
log_conditional INFO "Counting wikilinks by entity type..."

# Extract all wikilinks from research-hub.md
all_wikilinks=$(grep -oE '\[\[[^\]]+\]\]' "${PROJECT_PATH}/research-hub.md" 2>/dev/null || echo "")

# Count wikilinks by entity type (path-based detection)
dimension_wikilinks=$(echo "$all_wikilinks" | grep -c "12-synthesis/synthesis-" || echo 0)
megatrend_wikilinks=$(echo "$all_wikilinks" | grep -c "06-megatrends/data/megatrend-" || echo 0)
trend_wikilinks=$(echo "$all_wikilinks" | grep -c "11-trends/data/trend-" || echo 0)
concept_wikilinks=$(echo "$all_wikilinks" | grep -c "05-domain-concepts/data/concept-" || echo 0)

# Count other wikilinks (not matching above patterns)
total_wikilinks_raw=$(echo "$all_wikilinks" | wc -l | tr -d ' ')
other_wikilinks=$((total_wikilinks_raw - dimension_wikilinks - megatrend_wikilinks - trend_wikilinks - concept_wikilinks))

# Ensure non-negative
if [ "$other_wikilinks" -lt 0 ]; then
  other_wikilinks=0
fi

# Calculate total
total_wikilinks=$((dimension_wikilinks + megatrend_wikilinks + trend_wikilinks + concept_wikilinks + other_wikilinks))

log_conditional INFO "Wikilink counts: total=$total_wikilinks, dimensions=$dimension_wikilinks, megatrends=$megatrend_wikilinks, trends=$trend_wikilinks, concepts=$concept_wikilinks, other=$other_wikilinks"
```

### Step 4.5.2: Format Enhanced Metrics Table (Language-Aware)

Generate bilingual metrics tables (pipeline + entity statistics) based on project language:

```bash
log_conditional INFO "Generating enhanced metrics tables..."

# Read project language from sprint-log.json
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Set language-specific labels
if [ "$PROJECT_LANGUAGE" = "de" ]; then
  # Pipeline metrics labels
  HEADER_FULL_PIPELINE="### Forschungspipeline-Metriken"
  MSG_PIPELINE_INTRO="Diese Forschung synthetisierte Evidenz durch eine 12-stufige Entitätspipeline:"
  LABEL_PHASE="Phase"
  LABEL_ENTITY_TYPE="Entitätstyp"
  LABEL_GENERATED="Generiert"
  LABEL_USED_IN_REPORT="Im Bericht verwendet"
  LABEL_PIPELINE_SUMMARY="**Pipeline-Zusammenfassung:**"
  LABEL_TOTAL_ENTITIES="Generierte Entitäten insgesamt"
  LABEL_ENTITIES_CITED="Im Bericht zitierte Entitäten"
  LABEL_TOTAL_WIKILINKS="Gesamt-Wikilinks"
  LABEL_OVERALL_COVERAGE="Gesamtabdeckung"

  # Entity type names
  ENTITY_INITIAL_QUESTION="Ausgangsfrage"
  ENTITY_REFINED_QUESTIONS="Verfeinerte Fragen"
  ENTITY_QUERY_BATCHES="Suchanfrage-Batches"
  ENTITY_FINDINGS="Ergebnisse"
  ENTITY_DOMAIN_CONCEPTS="Domänenkonzepte"
  ENTITY_MEGATRENDS="Megatrends"
  ENTITY_SOURCES="Quellen"
  ENTITY_PUBLISHERS="Publisher"
  ENTITY_CITATIONS="Zitate"
  ENTITY_CLAIMS="Belege"
  ENTITY_TRENDS="Trends"
  ENTITY_DIMENSION_SYNTHESES="Dimensionssynthesen"

  # Existing entity stats labels
  LABEL_ENTITY_STATS="**Entitätsstatistiken:**"
  LABEL_METRIC="Metrik"
  LABEL_COUNT="Anzahl"
  LABEL_COVERAGE="Abdeckung"
  LABEL_DIMENSIONS="Dimensionen"
  LABEL_TRENDS="Trends analysiert"
  LABEL_MEGATRENDS_STAT="Megatrends identifiziert"
  LABEL_CONCEPTS="Konzepte referenziert"
  LABEL_CITATIONS="Zitate erstellt"
  LABEL_WIKILINK_DENSITY="**Wikilink-Dichte:**"
  LABEL_TOTAL_WIKILINKS="Gesamt-Wikilinks"
  LABEL_BY_TYPE="Nach Typ:"
  LABEL_DIM_SYNTHESES="Dimensionssynthesen"
  LABEL_OTHER="Andere"
else
  # Pipeline metrics labels
  HEADER_FULL_PIPELINE="### Research Pipeline Metrics"
  MSG_PIPELINE_INTRO="This research synthesized evidence through a 12-stage entity pipeline:"
  LABEL_PHASE="Phase"
  LABEL_ENTITY_TYPE="Entity Type"
  LABEL_GENERATED="Generated"
  LABEL_USED_IN_REPORT="Used in Report"
  LABEL_PIPELINE_SUMMARY="**Pipeline Summary:**"
  LABEL_TOTAL_ENTITIES="Total Entities Generated"
  LABEL_ENTITIES_CITED="Entities Cited in Report"
  LABEL_TOTAL_WIKILINKS="Total Wikilinks"
  LABEL_OVERALL_COVERAGE="Overall Coverage"

  # Entity type names
  ENTITY_INITIAL_QUESTION="Initial Question"
  ENTITY_REFINED_QUESTIONS="Refined Questions"
  ENTITY_QUERY_BATCHES="Query Batches"
  ENTITY_FINDINGS="Findings"
  ENTITY_DOMAIN_CONCEPTS="Domain Concepts"
  ENTITY_MEGATRENDS="Megatrends"
  ENTITY_SOURCES="Sources"
  ENTITY_PUBLISHERS="Publishers"
  ENTITY_CITATIONS="Citations"
  ENTITY_CLAIMS="Claims"
  ENTITY_TRENDS="Trends"
  ENTITY_DIMENSION_SYNTHESES="Dimension Syntheses"

  # Existing entity stats labels
  LABEL_ENTITY_STATS="**Entity Statistics:**"
  LABEL_METRIC="Metric"
  LABEL_COUNT="Count"
  LABEL_COVERAGE="Coverage"
  LABEL_DIMENSIONS="Dimensions"
  LABEL_TRENDS="Trends analyzed"
  LABEL_MEGATRENDS_STAT="Megatrends identified"
  LABEL_CONCEPTS="Concepts referenced"
  LABEL_CITATIONS="Citations created"
  LABEL_WIKILINK_DENSITY="**Wikilink Density:**"
  LABEL_TOTAL_WIKILINKS="Total wikilinks"
  LABEL_BY_TYPE="By type:"
  LABEL_DIM_SYNTHESES="Dimension syntheses"
  LABEL_OTHER="Other"
fi

# Use metrics calculated in Step 4 and Step 4.5.0
# dimensions_count, unique_trends, unique_megatrends, unique_concepts, total_citations
# trends_coverage_percent, megatrend_coverage_percent (already calculated)
# total_initial_questions, total_refined_questions, etc. (from Step 4.5.0)

# Calculate concept coverage (if concepts exist)
if [ "$total_concepts" -gt 0 ]; then
  concepts_coverage_percent=$((unique_concepts * 100 / total_concepts))
else
  concepts_coverage_percent=0
fi

# Calculate entities cited in report (wikilinks)
entities_cited_in_report=$((unique_trends + unique_megatrends + unique_concepts + dimensions_count))

# Calculate overall coverage
if [ "$total_entities_generated" -gt 0 ]; then
  overall_coverage_percent=$((entities_cited_in_report * 100 / total_entities_generated))
else
  overall_coverage_percent=0
fi

# Build full pipeline metrics table
PIPELINE_METRICS_TABLE=$(cat <<EOF
${HEADER_FULL_PIPELINE}

${MSG_PIPELINE_INTRO}

| ${LABEL_PHASE} | ${LABEL_ENTITY_TYPE} | ${LABEL_GENERATED} | ${LABEL_USED_IN_REPORT} | ${LABEL_COVERAGE} |
|-------|-------------|-----------|----------------|----------|
| 00 | ${ENTITY_INITIAL_QUESTION} | ${total_initial_questions} | ${total_initial_questions} | 100% |
| 02 | ${ENTITY_REFINED_QUESTIONS} | ${total_refined_questions} | - | - |
| 03 | ${ENTITY_QUERY_BATCHES} | ${total_query_batches} | - | - |
| 04 | ${ENTITY_FINDINGS} | ${total_findings} | - | - |
| 05 | ${ENTITY_DOMAIN_CONCEPTS} | ${total_domain_concepts} | ${unique_concepts} | ${concepts_coverage_percent}% |
| 06 | ${ENTITY_MEGATRENDS} | ${total_megatrends_all} | ${unique_megatrends} | ${megatrend_coverage_percent}% |
| 07 | ${ENTITY_SOURCES} | ${total_sources} | - | - |
| 08 | ${ENTITY_PUBLISHERS} | ${total_publishers} | - | - |
| 09 | ${ENTITY_CITATIONS} | ${total_citations} | - | - |
| 10 | ${ENTITY_CLAIMS} | ${total_claims} | - | - |
| 11 | ${ENTITY_TRENDS} | ${total_trends_all} | ${unique_trends} | ${trends_coverage_percent}% |
| 12 | ${ENTITY_DIMENSION_SYNTHESES} | ${total_dimension_syntheses} | ${dimensions_count} | 100% |

${LABEL_PIPELINE_SUMMARY}
- **${LABEL_TOTAL_ENTITIES}:** ${total_entities_generated}
- **${LABEL_ENTITIES_CITED}:** ${entities_cited_in_report} unique entities
- **${LABEL_TOTAL_WIKILINKS}:** ${total_wikilinks}
- **${LABEL_OVERALL_COVERAGE}:** ${overall_coverage_percent}%
EOF
)

# Build entity statistics table (existing functionality)
ENTITY_STATS_TABLE=$(cat <<EOF
${LABEL_ENTITY_STATS}

| ${LABEL_METRIC} | ${LABEL_COUNT} | ${LABEL_COVERAGE} |
|--------|-------|----------|
| ${LABEL_DIMENSIONS} | ${dimensions_count} | 100% |
| ${LABEL_TRENDS} | ${unique_trends} | ${trends_coverage_percent}% |
| ${LABEL_MEGATRENDS_STAT} | ${unique_megatrends} | ${megatrend_coverage_percent}% |
| ${LABEL_CONCEPTS} | ${unique_concepts} | ${concepts_coverage_percent}% |
| ${LABEL_CITATIONS} | ${total_citations} | - |

${LABEL_WIKILINK_DENSITY}

- **${LABEL_TOTAL_WIKILINKS}:** ${total_wikilinks}
- **${LABEL_BY_TYPE}:**
  - ${LABEL_DIM_SYNTHESES}: ${dimension_wikilinks}
  - ${LABEL_MEGATRENDS_STAT}: ${megatrend_wikilinks}
  - ${LABEL_TRENDS}: ${trend_wikilinks}
  - ${LABEL_CONCEPTS}: ${concept_wikilinks}
  - ${LABEL_OTHER}: ${other_wikilinks}
EOF
)

# Combine both tables
METRICS_TABLE=$(cat <<EOF
${PIPELINE_METRICS_TABLE}

${ENTITY_STATS_TABLE}
EOF
)

log_conditional INFO "Enhanced metrics tables generated (${#METRICS_TABLE} characters)"
```

### Step 4.5.3: Replace Placeholder

Replace `{STATISTICS_PLACEHOLDER}` with the metrics table:

```bash
log_conditional INFO "Replacing statistics placeholder in research-hub.md..."

# Escape special characters for sed (/, &, newlines, backslashes)
# Use a unique delimiter that won't appear in content (e.g., |)
METRICS_TABLE_ESCAPED=$(echo "$METRICS_TABLE" | sed 's/[\/&]/\\&/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Replace placeholder using sed with | delimiter
sed -i.bak "s|{STATISTICS_PLACEHOLDER}|${METRICS_TABLE_ESCAPED}|g" "${PROJECT_PATH}/research-hub.md"

if [ $? -ne 0 ]; then
  log_conditional WARNING "Sed replacement failed, attempting fallback approach"

  # Fallback: Use awk to replace placeholder
  awk -v replacement="$METRICS_TABLE" '{
    if ($0 ~ /{STATISTICS_PLACEHOLDER}/) {
      print replacement
    } else {
      print $0
    }
  }' "${PROJECT_PATH}/research-hub.md" > "${PROJECT_PATH}/research-hub.md.tmp"

  mv "${PROJECT_PATH}/research-hub.md.tmp" "${PROJECT_PATH}/research-hub.md"
fi

# Remove backup file
rm -f "${PROJECT_PATH}/research-hub.md.bak"

log_conditional INFO "Statistics placeholder replaced successfully"
```

### Step 4.5.4: Validation

Verify placeholder was replaced:

```bash
log_conditional INFO "Validating statistics placeholder replacement..."

# Check if placeholder still exists (should be gone)
if grep -q "{STATISTICS_PLACEHOLDER}" "${PROJECT_PATH}/research-hub.md" 2>/dev/null; then
  log_conditional ERROR "Statistics placeholder replacement failed - placeholder still exists"

  # Fallback: Append metrics to appendix if placeholder replacement failed
  log_conditional WARNING "Attempting fallback: appending metrics to appendix"

  # Find appendix section and append metrics
  echo "" >> "${PROJECT_PATH}/research-hub.md"
  echo "### Research Pipeline Metrics" >> "${PROJECT_PATH}/research-hub.md"
  echo "" >> "${PROJECT_PATH}/research-hub.md"
  echo "$METRICS_TABLE" >> "${PROJECT_PATH}/research-hub.md"

  statistics_placeholder_replaced=false
else
  log_conditional INFO "Statistics placeholder successfully replaced"
  statistics_placeholder_replaced=true
fi
```

### Edge Cases Handled

1. **No wikilinks found** - Displays zeros without error
2. **Placeholder not found** - Appends metrics to appendix gracefully (fallback)
3. **Coverage > 100%** - Display as-is (validation would have caught this in Step 2.7)
4. **Missing translations** - Falls back to English labels
5. **Sed replacement failure** - Uses awk fallback, then manual append
6. **Empty metrics** - Zeros displayed normally

**Mark Step 4.5 todo as completed** before proceeding to Step 5.

---

## Step 5: Return JSON Summary

Return comprehensive summary to caller (wrapper agent):

```bash
log_conditional INFO "Generating JSON summary..."

# Detect research type and synthesis format
research_type=$(grep "^research_type:" "${PROJECT_PATH}/research-metadata.yaml" | sed 's/research_type: //' || echo "unknown")
synthesis_format=$(grep "^synthesis_format:" "${PROJECT_PATH}/research-metadata.yaml" | sed 's/synthesis_format: //' || echo "STANDARD")

# Generate timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build warnings array if needed
warnings_json="[]"
if [ -n "$trend_horizon_warnings" ] || [ -n "$german_violations" ]; then
  warnings_array=""
  if [ -n "$trend_horizon_warnings" ]; then
    warnings_array="${warnings_array}\"${trend_horizon_warnings}\","
  fi
  if [ -n "$german_violations" ]; then
    # Add German text warnings
    warnings_array="${warnings_array}\"German text contains ASCII fallbacks instead of proper umlauts\","
  fi
  # Remove trailing comma and wrap in array
  warnings_array=$(echo "$warnings_array" | sed 's/,$//')
  warnings_json="[${warnings_array}]"
fi

# Arc-aware validation check
arc_validation_ok=true
if [ -n "${arc_id}" ] && [ "${entity_catalog_validation_passed}" != "true" ]; then
  arc_validation_ok=false
fi

# Generate JSON response
if [ "$validation_passed" = true ] && [ "$megatrend_completeness_passed" = true ] && [ "$trend_wikilink_validation_passed" = true ] && [ "$arc_validation_ok" = true ]; then
  cat << EOF
{
  "success": true,
  "report_created": "research-hub.md",
  "report_path": "${PROJECT_PATH}/research-hub.md",
  "research_type": "${research_type}",
  "synthesis_format": "${synthesis_format}",
  "metrics": {
    "total_citations": ${total_citations},
    "word_count": ${word_count},
    "trends_synthesized": ${unique_trends},
    "concepts_integrated": ${unique_concepts},
    "megatrends_analyzed": ${unique_megatrends},
    "total_megatrends": ${total_megatrends},
    "megatrend_coverage_percent": ${megatrend_coverage_percent},
    "dimensions_referenced": ${dimensions_count},
    "trends_coverage_percent": ${trends_coverage_percent},
    "validation_passed": true,
    "fabricated_count": 0,
    "wikilinks": {
      "total": ${total_wikilinks},
      "by_type": {
        "dimensions": ${dimension_wikilinks},
        "megatrends": ${megatrend_wikilinks},
        "trends": ${trend_wikilinks},
        "concepts": ${concept_wikilinks},
        "other": ${other_wikilinks}
      }
    }
  },
  "pipeline_metrics": {
    "total_entities_generated": ${total_entities_generated},
    "entities_cited_in_report": ${entities_cited_in_report},
    "overall_coverage_percent": ${overall_coverage_percent},
    "by_phase": {
      "00_initial_question": ${total_initial_questions},
      "02_refined_questions": ${total_refined_questions},
      "03_query_batches": ${total_query_batches},
      "04_findings": ${total_findings},
      "05_domain_concepts": ${total_domain_concepts},
      "06_megatrends": ${total_megatrends_all},
      "07_sources": ${total_sources},
      "08_publishers": ${total_publishers},
      "09_citations": ${total_citations},
      "10_claims": ${total_claims},
      "11_trends": ${total_trends_all},
      "12_dimension_syntheses": ${total_dimension_syntheses}
    }
  },
  "warnings": ${warnings_json},
  "timestamp": "${timestamp}"
}
EOF

  log_phase "Phase 5: Validation & Output" "complete"
  exit 0
else
  # Validation failed - return error
  cat << EOF
{
  "success": false,
  "error": "Validation failed",
  "validation_errors": {
    "citation_validation": ${validation_passed},
    "megatrend_completeness": ${megatrend_completeness_passed},
    "trend_wikilink_validation": ${trend_wikilink_validation_passed},
    "entity_catalog_validation": ${entity_catalog_validation_passed:-true},
    "fabricated_entities": $(echo -e "$invalid_citation_details" | sed '/^$/d' | jq -R . | jq -s . || echo "[]"),
    "missing_megatrends": $(echo -e "$missing_megatrends" | sed '/^$/d' | jq -R . | jq -s . || echo "[]"),
    "plain_text_trends": $(echo -e "$plain_text_trends" | sed '/^$/d' | jq -R . | jq -s . || echo "[]"),
    "hallucinated_entity_paths": $(echo -e "$invalid_wikilink_details" | sed '/^$/d' | jq -R . | jq -s . || echo "[]"),
    "fabricated_count": ${invalid_count},
    "trend_entries_plain_text": ${trend_entries_plain_text:-0},
    "hallucinated_entity_count": ${#invalid_wikilinks[@]:-0}
  },
  "partial_output": "research-hub.md",
  "remediation": "Review validation errors. Ensure all citations reference existing entities. Verify trend entries in kanban table use wikilink format [[11-trends/data/trend-{slug}|{title}]], not plain text."

}
EOF

  log_conditional ERROR "Phase 5 validation failed"
  exit 1
fi
```

### Success Response Format

```json
{
  "success": true,
  "report_created": "research-hub.md",
  "report_path": "/path/to/project/research-hub.md",
  "research_type": "smarter-service",
  "synthesis_format": "STANDARD",
  "metrics": {
    "total_citations": 156,
    "word_count": 4500,
    "trends_synthesized": 12,
    "concepts_integrated": 24,
    "megatrends_analyzed": 18,
    "dimensions_referenced": 3,
    "trends_coverage_percent": 92,
    "validation_passed": true,
    "fabricated_count": 0,
    "wikilinks": {
      "total": 87,
      "by_type": {
        "dimensions": 22,
        "megatrends": 18,
        "trends": 35,
        "concepts": 10,
        "other": 2
      }
    }
  },
  "pipeline_metrics": {
    "total_entities_generated": 487,
    "entities_cited_in_report": 54,
    "overall_coverage_percent": 11,
    "by_phase": {
      "00_initial_question": 1,
      "02_refined_questions": 5,
      "03_query_batches": 3,
      "04_findings": 125,
      "05_domain_concepts": 34,
      "06_megatrends": 18,
      "07_sources": 89,
      "08_publishers": 23,
      "09_citations": 156,
      "10_claims": 67,
      "11_trends": 31,
      "12_dimension_syntheses": 4
    }
  },
  "timestamp": "2025-12-03T10:30:00Z"
}
```

### Error Response Format

```json
{
  "success": false,
  "error": "Validation failed",
  "validation_errors": {
    "citation_validation": false,
    "fabricated_entities": [
      "11-trends/data/trend-nonexistent-abc123 → /path/to/11-trends/data/trend-nonexistent-abc123.md (NOT FOUND)",
      "05-domain-concepts/data/concept-invalid-def456 → /path/to/05-domain-concepts/data/concept-invalid-def456.md (NOT FOUND)"
    ],
    "fabricated_count": 2
  },
  "partial_output": "research-hub.md",
  "remediation": "Review validation errors. Ensure all citations reference existing entities in project directories."
}
```

**Mark Step 5 todo as completed** after phase completion is logged.

---

## Error Handling

### Validation Failed (Fabricated Citations)

**Scenario:** Phase 5 validation detects fabricated entity citations

- **Detection:** Citation references entity file that doesn't exist
- **Recovery:** Abort with error response (partial output exists)
- **Action:** Return error JSON with list of fabricated citations
- **Exit:** 1

### Low Citation Coverage

**Scenario:** Synthesis created but citation counts too low

- **Detection:** Total citations < 50 OR trends coverage < 50%
- **Recovery:** Proceed with warnings
- **Action:** Include warning in JSON response
- **Exit:** 0 (successful with warnings)

**Success JSON with Warnings:**

```json
{
  "success": true,
  "report_created": "research-hub.md",
  "metrics": {
    "total_citations": 35,
    "trends_synthesized": 4,
    "trends_coverage_percent": 42
  },
  "warnings": [
    "Total citations (35) below recommended minimum (50)",
    "Trends coverage (42%) below recommended minimum (70%)",
    "Consider deeper integration of available evidence"
  ]
}
```

---

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you extract all citation entity paths? ✅ YES / ❌ NO
2. Did you validate all entity paths exist? ✅ YES / ❌ NO
3. Are there any fabricated entities? ❌ NO required
4. Did you validate megatrend completeness? ✅ YES / ❌ NO
5. Did you validate trend wikilinks in kanban table? ✅ YES / ❌ NO
6. Did you calculate execution metrics? ✅ YES / ❌ NO
7. Did you return JSON summary? ✅ YES / ❌ NO
8. Does validation_passed == true? ✅ YES / ❌ NO
9. Does megatrend_completeness_passed == true? ✅ YES / ❌ NO
10. Does trend_wikilink_validation_passed == true? ✅ YES / ❌ NO

⛔ **IF ANY INCORRECT: STOP.** Handle error appropriately.

---

## Phase 5 Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before marking phase complete

Before marking Phase 5 complete in TodoWrite, verify:

- [ ] All citation entity paths extracted from research-hub.md
- [ ] All citation paths validated against filesystem
- [ ] Citation validation PASSED (fabricated_count = 0)
- [ ] **Megatrend completeness validated (100% coverage)**
- [ ] **Megatrend completeness PASSED (all megatrends in report)**
- [ ] **Trend wikilinks validated in kanban table**
- [ ] **Trend wikilink validation PASSED (no plain text trends)**
- [ ] Execution metrics calculated
- [ ] **Statistics and wikilink counts calculated (Step 4.5)**
- [ ] **Statistics placeholder replaced in research-hub.md**
- [ ] **Metrics visible in appendix (no placeholder remaining)**
- [ ] JSON summary returned (includes wikilink metrics)
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered correctly
- [ ] Phase 5 todo marked completed in TodoWrite

---

## Quality Standards

**Anti-Hallucination Verification Checklist:**

Before completing Phase 5, verify:

- [ ] research-hub.md created in Phase 4
- [ ] All citations use markdown link format: `[title](../XX-directory/entity-file.md)`
- [ ] All citations validated against filesystem (no fabricated paths)
- [ ] No fabricated entity paths detected (fabricated_count = 0)
- [ ] **All megatrend files from 06-megatrends/data/ appear in report**
- [ ] **megatrend_completeness_passed = true**
- [ ] **All trend entries in kanban table have wikilinks (not plain text)**
- [ ] **trend_wikilink_validation_passed = true**
- [ ] Metrics accurately reflect synthesis content
- [ ] JSON summary matches actual output
- [ ] validation_passed = true

**If ANY verification fails:** Report error, set validation_passed = false, return error JSON with exit code 1.

---

## Success Criteria Summary

**Minimum Requirements:**

- [ ] research-hub.md created with 2000+ words
- [ ] 50+ total citations across synthesis
- [ ] All citations valid (fabricated_count = 0)
- [ ] Trends coverage ≥ 70% (recommended)
- [ ] **Megatrend coverage = 100% (required)**
- [ ] **Trend entries in kanban table = 100% wikilinks (required)**
- [ ] **Statistics inserted in appendix (no placeholder remaining)**
- [ ] JSON summary returned with success: true (includes wikilink metrics)
- [ ] validation_passed = true
- [ ] **megatrend_completeness_passed = true**
- [ ] **trend_wikilink_validation_passed = true**

---

## Why This Validation Matters

Synthesis without evidence grounding = speculation, not analysis.

**The integrity chain:**

1. **Entity manifest** (Phase 1.2): Single source of truth for available entities
2. **Complete loading** (Phase 2): All evidence loaded fully
3. **Evidence-based synthesis** (Phase 4): Grounds all analysis in loaded content
4. **Citation validation** (Phase 5.2): Catches fabricated references before completion
5. **Coverage analysis** (Phase 5.4): Ensures comprehensive evidence use
7. **Result:** Trustworthy synthesis traceable to source material

Synthesis drives strategic decision-making - hallucinated patterns or invalid citations undermine research integrity.

---

## Next Phase

**Phase 6: Cleanup & Handoff (Optional)** - Cleanup temporary files, log completion metrics.

**REQUIREMENT:** Only execute Phase 6 after Phase 5 validation passes. Do not proceed if validation_passed = false.

---

*End of Phase 5: Validation & Output*
