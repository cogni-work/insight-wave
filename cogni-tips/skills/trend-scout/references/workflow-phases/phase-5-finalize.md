# Phase 5: Finalize Output

**Reference Checksum:** `sha256:trend-scout-p5-final-v2`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-5-finalize.md | Checksum: trend-scout-p5-final-v2
```

---

## Objective

Update the consolidated `trend-scout-output.json` with agreed candidates for downstream `deeper-research-0` consumption.

**Expected Duration:** 10-15 seconds

---

## Entry Gate

Before proceeding, verify Phase 4 outputs:

- [ ] VALIDATION_PASSED = true
- [ ] AGREED_CANDIDATES populated with 52 candidates
- [ ] All metadata available (industry, subsector, topic, language)

---

## Step 5.1: Initialize Finalization Phase

```bash
log_phase "Phase 5: Finalize Output" "start"
log_conditional INFO "Finalizing ${#AGREED_CANDIDATES[@]} agreed candidates"
```

---

## Step 5.2: Update Consolidated trend-scout-output.json

Update the consolidated output file with agreed candidates and finalize execution state:

```bash
# First, write agreed candidates to a temporary JSON file for the script
CANDIDATES_TMP="${PROJECT_PATH}/.metadata/agreed-candidates-tmp.json"

# Build candidates array as JSON and write to temp file
# If input was JSON (Visual Selector App): use SELECTED_CANDIDATES directly
# If input was Markdown: assemble from parsed output
if [[ "$INPUT_SOURCE" == "json" ]]; then
  echo "$SELECTED_CANDIDATES" > "$CANDIDATES_TMP"
else
  # Build from AGREED_CANDIDATES array
  printf '%s\n' "${AGREED_CANDIDATES[@]}" | jq -s '.' > "$CANDIDATES_TMP"
fi

# Use finalize-candidates.sh script
# CRITICAL: Use CLAUDE_PLUGIN_ROOT for scripts, NOT COGNI_WORKSPACE_ROOT
FINALIZE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/finalize-candidates.sh"

# Validate script exists - do NOT improvise if missing
if [[ ! -f "$FINALIZE_SCRIPT" ]]; then
  log_conditional ERROR "Script not found: $FINALIZE_SCRIPT"
  log_conditional ERROR "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
  log_conditional ERROR "Please verify plugin installation"
  exit 1
fi

FINALIZE_OUTPUT=$(bash "$FINALIZE_SCRIPT" \
  --project-path "$PROJECT_PATH" \
  --candidates-file "$CANDIDATES_TMP" \
  --web-count "$WEB_SOURCED_COUNT" \
  --training-count "$TRAINING_SOURCED_COUNT" \
  --user-count "$USER_PROPOSED_COUNT" \
  --search-timestamp "$SEARCH_TIMESTAMP" \
  --web-status "$WEB_RESEARCH_STATUS" \
  --json)

if [[ ! $(echo "$FINALIZE_OUTPUT" | jq -r '.success') == "true" ]]; then
  log_conditional ERROR "Failed to finalize candidates"
  log_conditional ERROR "$(echo "$FINALIZE_OUTPUT" | jq -r '.error')"
  exit 1
fi

# Clean up temp file
rm -f "$CANDIDATES_TMP"

log_conditional INFO "Updated: ${PROJECT_PATH}/.metadata/trend-scout-output.json"
```

### Candidate Structure in Consolidated File

Each candidate in `.tips_candidates.items` has this structure:

```json
{
  "dimension": "externe-effekte",
  "dimension_de": "Externe Effekte",
  "horizon": "act",
  "horizon_de": "Handeln",
  "sequence": 1,
  "trend_name": "EU AI Act Compliance",
  "trend_statement": "EU regulation requiring conformity assessments for high-risk AI systems in machinery, with August 2025 deadline creating compliance pressure for manufacturers.",
  "research_hint": "Investigate compliance pathways, implementation timelines, cost implications, and how leading manufacturers are preparing.",
  "keywords": ["ai-act", "regulation", "compliance"],
  "source": "web-signal",
  "source_url": "https://ec.europa.eu/...",
  "freshness_date": "2024-12",
  "score": 0.82,
  "confidence_tier": "high",
  "signal_intensity": 5
}
```

### Scoring Fields Reference

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `score` | float | 0.0-1.0 | Composite score (impact, probability, strategic fit, source quality, signal strength) |
| `confidence_tier` | string | high/medium/low/uncertain | Source triangulation confidence (high ≥0.80, medium 0.50-0.79, low 0.30-0.49, uncertain <0.30) |
| `signal_intensity` | int | 1-5 | Ansoff weak signal classification (1=turbulence, 5=foreseeable) |

---

## Step 5.3: Update trend-candidates.md Status

Update the frontmatter status to `agreed`:

```bash
# trend-candidates.md is in project root (simplified structure)
TIPS_FILE="${PROJECT_PATH}/trend-candidates.md"

# Update status in frontmatter
sed -i '' 's/^status: draft/status: agreed/' "$TIPS_FILE"
sed -i '' 's/^status: pending_review/status: agreed/' "$TIPS_FILE"

# Add agreed_at timestamp
sed -i '' "/^status: agreed/a\\
agreed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TIPS_FILE"

log_conditional INFO "Updated trend-candidates.md status to 'agreed'"
```

---

## Step 5.4: Log Completion

```bash
log_phase "Phase 5: Finalize Output" "complete"
log_conditional INFO "trend-scout workflow complete"
log_conditional INFO "Output: $OUTPUT_FILE"
```

---

## Step 5.5: Output Success Message

### English Output

```text
## Trend Scout Complete

Successfully finalized 52 trend candidates for {SUBSECTOR_EN}.

### Output Files

| File | Path |
|------|------|
| Consolidated Output | `.metadata/trend-scout-output.json` |
| Selection File | `trend-candidates.md` |

### Candidate Summary

| Source | Count |
|--------|-------|
| Web Signal | {WEB_COUNT} |
| Training | {TRAINING_COUNT} |
| User Proposed | {USER_COUNT} |
| **Total** | **52** |

### Next Steps

**Option A — Full Research Pipeline:**

To start the full research workflow, invoke the `deeper-research-0` skill with:

```
tips_source: {PROJECT_PATH}/.metadata/trend-scout-output.json
```

The configuration and candidates will be loaded from the consolidated output file.

**Option B — Trend Report:**

To generate a narrative TIPS trend report directly, invoke the `trend-report` skill. It will auto-discover this project and enrich each trend with web-sourced quantitative evidence.
```

### German Output

```text
## Trend Scout abgeschlossen

52 Trendkandidaten für {SUBSECTOR_DE} erfolgreich finalisiert.

### Ausgabedateien

| Datei | Pfad |
|-------|------|
| Konsolidierte Ausgabe | `.metadata/trend-scout-output.json` |
| Auswahldatei | `trend-candidates.md` |

### Kandidatenübersicht

| Quelle | Anzahl |
|--------|--------|
| Web-Signal | {WEB_COUNT} |
| Training | {TRAINING_COUNT} |
| Eigene Vorschläge | {USER_COUNT} |
| **Gesamt** | **52** |

### Nächste Schritte

**Option A — Vollständige Recherche-Pipeline:**

Um den Recherche-Workflow zu starten, rufen Sie das `deeper-research-0` Skill auf mit:

```
tips_source: {PROJECT_PATH}/.metadata/trend-scout-output.json
```

Die Konfiguration und Kandidaten werden aus der konsolidierten Ausgabedatei geladen.

**Option B — Trendbericht:**

Um direkt einen narrativen TIPS-Trendbericht zu generieren, rufen Sie das `trend-report` Skill auf. Es erkennt dieses Projekt automatisch und reichert jeden Trend mit webbasierten quantitativen Belegen an.
```

---

## Success Criteria

- [ ] `trend-scout-output.json` updated with agreed candidates
- [ ] `trend-candidates.md` status updated to `agreed`
- [ ] All 52 candidates included in consolidated output
- [ ] Metadata complete (industry, subsector, language, sources)
- [ ] Success message displayed with next steps

---

## Output Files Summary

| File | Location | Purpose |
|------|----------|---------|
| `trend-scout-output.json` | `.metadata/` | Consolidated output (config + candidates + execution state) |
| `trend-candidates.md` | `{PROJECT_PATH}/` | User-facing selection file (status: agreed) |

---

## Integration with deeper-research-0

User invokes `deeper-research-0` with explicit path to trend-scout output:

```yaml
tips_source: {PROJECT_PATH}/.metadata/trend-scout-output.json
```

1. **Phase 0 Detection:**
   - deeper-research-0 checks for `tips_source` parameter
   - Loads consolidated `trend-scout-output.json`

2. **Auto-Configuration:**
   - Reads `.config.research_type` → `smarter-service`
   - Reads `.config.dok_level` → `4`
   - Reads `.project_language` from output
   - Skips user prompts for these settings

3. **Candidate Loading (Phase 2):**
   - Loads candidates from `.tips_candidates.items`
   - Skips tips-selection workflow
   - Proceeds directly with 52 agreed candidates

4. **Research Execution:**
   - Uses industry context from `.config.industry`
   - Uses subsector for web search queries
   - Maintains provenance to trend-scout source file

---

## Workflow Complete

The trend-scout skill has completed all phases. User can now proceed to deeper-research-0 with the `tips_source` path.
