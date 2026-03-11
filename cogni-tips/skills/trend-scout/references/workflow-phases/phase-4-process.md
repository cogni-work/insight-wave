# Phase 4: Process User Selection

**Reference Checksum:** `sha256:trend-scout-p4-process-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-4-process.md | Checksum: trend-scout-p4-process-v1
```

---

## Objective

Parse user selections from either:

- **Visual Selector App:** `trend-selection.json` (preferred)
- **Markdown File:** `trend-candidates.md`

Validate selection counts, handle regeneration requests, and prepare for finalization.

**Expected Duration:** 20-60 seconds (depending on regeneration needs)

---

## Entry Gate

Before proceeding, verify:

- [ ] PROJECT_PATH set
- [ ] PROJECT_LANGUAGE set
- [ ] One of:
  - `trend-selection.json` exists at `{PROJECT_PATH}/` (from Visual Selector App export), OR
  - `trend-candidates.md` exists at `{PROJECT_PATH}/` with user edits

---

## Step 4.1: Initialize Processing Phase

```bash
log_phase "Phase 4: Process User Selection" "start"

# Check for Visual Selector App JSON export first (preferred)
TIPS_SELECTION_JSON="${PROJECT_PATH}/trend-selection.json"
TIPS_SELECTION_DOWNLOADS="$HOME/Downloads/trend-selection.json"
TIPS_CANDIDATES_FILE="${PROJECT_PATH}/trend-candidates.md"

INPUT_SOURCE=""

# Check project folder first
if [[ -f "$TIPS_SELECTION_JSON" ]]; then
  INPUT_SOURCE="json"
  log_conditional INFO "Found trend-selection.json in project folder"
# Check Downloads folder (browser export default location)
elif [[ -f "$TIPS_SELECTION_DOWNLOADS" ]]; then
  cp "$TIPS_SELECTION_DOWNLOADS" "$TIPS_SELECTION_JSON"
  INPUT_SOURCE="json"
  log_conditional INFO "Found trend-selection.json in Downloads, copied to project folder"
elif [[ -f "$TIPS_CANDIDATES_FILE" ]]; then
  INPUT_SOURCE="markdown"
  log_conditional INFO "Found trend-candidates.md"
else
  log_conditional ERROR "No selection input found"
  log_conditional ERROR "Please use the Visual Selector App or edit trend-candidates.md"
  exit 1
fi

log_conditional INFO "Input source: $INPUT_SOURCE"
```

---

## Step 4.2: Read and Parse Selection Input

### Option A: Parse JSON (Visual Selector App)

If `INPUT_SOURCE == "json"`:

```bash
# Read JSON export from Visual Selector App
SELECTION_DATA=$(cat "$TIPS_SELECTION_JSON")

# Validate JSON structure
if echo "$SELECTION_DATA" | jq -e '.selected_candidates' > /dev/null 2>&1; then
  : # Valid JSON structure, continue
else
  log_conditional ERROR "Invalid trend-selection.json format"
  exit 1
fi

# Extract data
TOTAL_SELECTED=$(echo "$SELECTION_DATA" | jq -r '.selection_summary.total_selected')
IS_COMPLETE=$(echo "$SELECTION_DATA" | jq -r '.selection_summary.complete')
SELECTED_CANDIDATES=$(echo "$SELECTION_DATA" | jq '.selected_candidates')
USER_PROPOSALS=$(echo "$SELECTION_DATA" | jq -r '.user_proposals')

log_conditional INFO "JSON parsed: $TOTAL_SELECTED candidates selected"
```

---

## jq Variable Handling (CRITICAL)

When constructing jq commands, shell variables MUST be passed explicitly to jq. They are NOT automatically available inside jq filters.

**WRONG - Variable not passed:**

```bash
# This pattern FAILS because $selected_candidates is undefined in jq
cat > /tmp/script.jq << 'EOF'
.items = $selected_candidates
EOF
jq -f /tmp/script.jq file.json  # ERROR: $selected_candidates is not defined
```

**CORRECT - Use --argjson for JSON data:**

```bash
# Pass shell variable to jq as a jq variable
jq --argjson selected "$SELECTED_CANDIDATES" '.items = $selected' file.json
```

**CORRECT - Use --slurpfile for file-based input:**

```bash
# Load JSON from file into jq variable
jq --slurpfile selected trend-selection.json '.items = $selected[0].selected_candidates' output.json
```

**Rule:** Always use `--arg` (for strings) or `--argjson` (for JSON) to pass shell variables to jq. Never rely on `$variable` syntax inside jq filters without explicitly passing the variable.

---

### JSON Export Schema (from Visual Selector App)

```json
{
  "version": "2.0.0",
  "exported_at": "2025-12-17T10:30:00Z",
  "export_source": "trend-selector-app",
  "project": {
    "project_id": "...",
    "project_name": "...",
    "industry": "...",
    "subsector": "...",
    "language": "en"
  },
  "selection_summary": {
    "total_selected": 60,
    "total_proposals": 0,
    "complete": true,
    "by_dimension": {"t": 15, "p": 15, "i": 15, "s": 15}
  },
  "selected_candidates": [
    {
      "dimension": "externe-effekte",
      "dimension_en": "External Effects",
      "dimension_de": "Externe Effekte",
      "horizon": "act",
      "horizon_de": "Handeln",
      "sequence": 1,
      "trend_name": "...",
      "trend_statement": "...",
      "research_hint": "...",
      "keywords": ["...", "..."],
      "source": "web-signal",
      "source_citation": "[1]",
      "score": 0.82,
      "confidence_tier": "high",
      "signal_intensity": 4
    }
  ],
  "user_proposals": []
}
```

### Option B: Parse Markdown (trend-candidates.md)

### Use Parsing Script

```bash
PARSE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/parse-candidates-md.sh"

PARSE_OUTPUT=$(bash "$PARSE_SCRIPT" --input "$TIPS_CANDIDATES_FILE" --json)

if [[ ! $(echo "$PARSE_OUTPUT" | jq -r '.success') == "true" ]]; then
  log_conditional ERROR "Failed to parse trend-candidates.md"
  log_conditional ERROR "$(echo "$PARSE_OUTPUT" | jq -r '.error')"
  exit 1
fi
```

### Parse Output Structure

```json
{
  "success": true,
  "data": {
    "frontmatter": {
      "status": "draft",
      "project_slug": "...",
      "industry": "...",
      "subsector": "...",
      "project_language": "..."
    },
    "selections": {
      "externe-effekte": {
        "act": [1, 3, 4],
        "plan": [2, 3, 5],
        "observe": [1, 2, 4]
      },
      "neue-horizonte": {...},
      "digitale-wertetreiber": {...},
      "digitales-fundament": {...}
    },
    "user_proposed": [
      {
        "dimension": "externe-effekte",
        "horizon": "act",
        "trend_name": "...",
        "keywords": ["...", "...", "..."],
        "rationale": "..."
      }
    ],
    "regeneration_requests": {
      "externe-effekte": {
        "act": 0,
        "plan": 3,
        "observe": 0
      },
      ...
    },
    "selection_counts": {
      "externe-effekte": {"act": 3, "plan": 2, "observe": 3},
      ...
    }
  }
}
```

---

## Step 4.3: Validate Selection Counts

### Use Validation Script

```bash
VALIDATE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/validate-selection.sh"

VALIDATE_OUTPUT=$(bash "$VALIDATE_SCRIPT" --input "$TIPS_CANDIDATES_FILE" --json)

VALIDATION_PASSED=$(echo "$VALIDATE_OUTPUT" | jq -r '.data.valid')
TOTAL_SELECTED=$(echo "$VALIDATE_OUTPUT" | jq -r '.data.total_selected')
INVALID_CELLS=$(echo "$VALIDATE_OUTPUT" | jq -r '.data.invalid_cells')
```

### Validation Rules

| Rule | Requirement |
|------|-------------|
| Per cell | Exactly 5 candidates selected |
| Total | 60 candidates selected |
| User proposed | Count toward their assigned cell |

---

## Step 4.4: Handle Validation Results

### If Validation Passes

```bash
if [[ "$VALIDATION_PASSED" == "true" ]]; then
  log_conditional INFO "Validation passed: $TOTAL_SELECTED candidates selected"
  PROCEED_TO_PHASE=5
fi
```

### If Validation Fails

```bash
if [[ "$VALIDATION_PASSED" == "false" ]]; then
  log_conditional WARN "Validation failed"

  # Report invalid cells
  echo "$INVALID_CELLS" | jq -c '.[]' | while read cell; do
    DIM=$(echo "$cell" | jq -r '.dimension')
    HOR=$(echo "$cell" | jq -r '.horizon')
    COUNT=$(echo "$cell" | jq -r '.count')
    EXPECTED=5

    if [[ "$PROJECT_LANGUAGE" == "de" ]]; then
      log_conditional WARN "- $DIM / $HOR: $COUNT ausgewählt (erwartet $EXPECTED)"
    else
      log_conditional WARN "- $DIM / $HOR: $COUNT selected (expected $EXPECTED)"
    fi
  done

  # Check for regeneration requests
  HAS_REGENERATION=$(echo "$PARSE_OUTPUT" | jq -r '.data.regeneration_requests | to_entries | map(select(.value | to_entries | map(select(.value > 0)) | length > 0)) | length > 0')

  if [[ "$HAS_REGENERATION" == "true" ]]; then
    PROCEED_TO_REGENERATION=true
  else
    PROCEED_TO_PAUSE=true
  fi
fi
```

---

## Step 4.5: Handle Regeneration Requests

If user requested more candidates (`[+N]`):

### MANDATORY: Thinking Block for Regeneration

<thinking>
**Regeneration Request Processing**

**Requests found:**
- externe-effekte/plan: +3 candidates
- digitales-fundament/act: +2 candidates

**Regeneration strategy:**
For each cell with regeneration request:
1. Load existing candidates for that cell
2. Generate N new candidates (different from existing)
3. Add to the cell's candidate pool
4. Maintain source distribution (web/training mix)

**Generating new candidates...**

*Cell: externe-effekte/plan (+3)*
Existing candidates: [list trend names]
New candidates:
1. {new_trend_1} - distinct from existing
2. {new_trend_2} - distinct from existing
3. {new_trend_3} - distinct from existing

[Continue for each regeneration request...]
</thinking>

### Update trend-candidates.md

```bash
# Add new candidates to the file
# Update sequence numbers
# Preserve existing selections

log_conditional INFO "Regenerated candidates for requested cells"
log_conditional INFO "Updated trend-candidates.md"
```

### After Regeneration

```bash
# PAUSE again for user to review new candidates
PROCEED_TO_PAUSE=true
```

---

## Step 4.6: Handle Pause (Validation Failed, No Regeneration)

Output error message and pause:

### English Output

```text
## Selection Validation Failed

The following cells have incorrect selection counts:

{LIST_OF_INVALID_CELLS}

**Required:** Exactly 5 candidates per cell (60 total)
**Current:** {TOTAL_SELECTED} candidates selected

Please adjust your selections in `trend-candidates.md` and re-invoke trend-scout.
```

### German Output

```text
## Auswahlvalidierung fehlgeschlagen

Die folgenden Zellen haben falsche Auswahlzählungen:

{LIST_OF_INVALID_CELLS}

**Erforderlich:** Genau 5 Kandidaten pro Zelle (60 insgesamt)
**Aktuell:** {TOTAL_SELECTED} Kandidaten ausgewählt

Bitte passen Sie Ihre Auswahl in `trend-candidates.md` an und rufen Sie trend-scout erneut auf.
```

```bash
log_phase "Phase 4: Process User Selection" "paused"
exit 0
```

---

## Step 4.7: Build Agreed Candidates List

When validation passes, build the final list:

```bash
# Extract selected candidates with full details
AGREED_CANDIDATES=()

for dimension in externe-effekte neue-horizonte digitale-wertetreiber digitales-fundament; do
  for horizon in act plan observe; do
    # Get selected sequence numbers for this cell
    SELECTED=$(echo "$PARSE_OUTPUT" | jq -r ".data.selections[\"$dimension\"][\"$horizon\"][]")

    for seq in $SELECTED; do
      # Get full candidate details from original generation
      CANDIDATE=$(get_candidate "$dimension" "$horizon" "$seq")
      AGREED_CANDIDATES+=("$CANDIDATE")
    done
  done
done

# Add user-proposed candidates
USER_PROPOSED=$(echo "$PARSE_OUTPUT" | jq -r '.data.user_proposed[]')
for proposal in $USER_PROPOSED; do
  AGREED_CANDIDATES+=("$proposal")
done

log_conditional INFO "Built agreed candidates list: ${#AGREED_CANDIDATES[@]} candidates"
```

---

## Step 4.8: Mark Phase 4 Complete

```bash
log_phase "Phase 4: Process User Selection" "complete"
log_metric "total_agreed" "${#AGREED_CANDIDATES[@]}" "count"
log_metric "user_proposed" "$USER_PROPOSED_COUNT" "count"
```

---

## Success Criteria

- [ ] trend-candidates.md parsed successfully
- [ ] Selection counts validated
- [ ] Invalid cells reported (if any)
- [ ] Regeneration handled (if requested)
- [ ] 60 candidates in agreed list
- [ ] User-proposed candidates included

---

## Variables Set

| Variable | Description | Example |
|----------|-------------|---------|
| VALIDATION_PASSED | Whether validation succeeded | `true` |
| TOTAL_SELECTED | Number of selected candidates | `60` |
| AGREED_CANDIDATES | Array of agreed candidate objects | `[...]` |
| USER_PROPOSED_COUNT | Number of user proposals | `2` |

---

## Next Phase

If validation passed: Proceed to [phase-5-finalize.md](phase-5-finalize.md)
If validation failed: Pause for user correction, then re-run Phase 4
