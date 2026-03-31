# Phase 4: Finalize Output

**Reference Checksum:** `sha256:trend-scout-p4-final-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-4-finalize.md | Checksum: trend-scout-p4-final-v1
```

---

## Objective

Update the consolidated `trend-scout-output.json` with all web-grounded candidates for downstream pipeline consumption (`value-modeler`, `trend-report`).

**Expected Duration:** 10-15 seconds

---

## Entry Gate

Before proceeding, verify Phase 3 outputs:

- [ ] TIPS_CANDIDATES_FILE written with all web-grounded candidates
- [ ] All metadata available (industry, subsector, topic, language)

---

## Step 4.1: Initialize Finalization Phase

```bash
log_phase "Phase 4: Finalize Output" "start"
log_conditional INFO "Finalizing candidates"
```

---

## Step 4.2: Update Consolidated trend-scout-output.json

Update the consolidated output file with all candidates and finalize execution state:

```bash
# Write candidates to a temporary JSON file for the script
CANDIDATES_TMP="${PROJECT_PATH}/.metadata/candidates-tmp.json"

# Build candidates array from the full generator output
# Flatten nested candidates_by_dimension (or candidates_by_cell) into a flat array,
# injecting the dimension field from the nesting keys onto each candidate object
jq '[(.candidates_by_dimension // .candidates_by_cell) | to_entries[] | .key as $dim | .value | to_entries[] | .key as $hor | .value[] | . + {dimension: $dim, horizon: $hor}]' \
  "${PROJECT_PATH}/.logs/trend-generator-candidates.json" > "$CANDIDATES_TMP"

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
  --training-count "0" \
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

## Step 4.3: Log Completion

```bash
log_phase "Phase 4: Finalize Output" "complete"
log_conditional INFO "trend-scout workflow complete"
log_conditional INFO "Output: $OUTPUT_FILE"
```

---

## Step 4.4: Output Success Message

### English Output

```text
## Trend Scout Complete

Successfully finalized {TOTAL_CANDIDATES} web-grounded trend candidates for {SUBSECTOR_EN}.

### Output Files

| File | Path |
|------|------|
| Consolidated Output | `.metadata/trend-scout-output.json` |
| Trend List | `trend-candidates.md` |

### Candidate Summary

| Metric | Value |
|--------|-------|
| Total Candidates | {TOTAL_CANDIDATES} |
| Web Sources | {UNIQUE_SOURCES} unique |
| Cells Covered | {CELLS_WITH_CANDIDATES}/12 |

### Next Steps

**Option A — Trend Report:**

To generate a narrative TIPS trend report directly, invoke the `trend-report` skill:

```
/trend-report
```

It will auto-discover this project and enrich each trend with web-sourced quantitative evidence.

**Option B — Value Modeling (recommended for full pipeline):**

To build T→I→P→S relationship networks and ranked solution templates before reporting, invoke the `value-modeler` skill:

```
/value-modeler
```

It will load configuration and candidates from the consolidated output file. After value-modeler completes, proceed with `/trend-report` for the full CxO narrative.
```

### German Output

```text
## Trend Scout abgeschlossen

60 Trendkandidaten für {SUBSECTOR_DE} erfolgreich finalisiert.

### Ausgabedateien

| Datei | Pfad |
|-------|------|
| Konsolidierte Ausgabe | `.metadata/trend-scout-output.json` |
| Trendliste | `trend-candidates.md` |

### Kandidatenübersicht

| Quelle | Anzahl |
|--------|--------|
| Web-Signal | {WEB_COUNT} |
| Training | {TRAINING_COUNT} |
| **Gesamt** | **60** |

### Nächste Schritte

**Option A — Trendbericht:**

Um direkt einen narrativen TIPS-Trendbericht zu generieren, rufen Sie das `trend-report` Skill auf:

```
/trend-report
```

Es erkennt dieses Projekt automatisch und reichert jeden Trend mit webbasierten quantitativen Belegen an.

**Option B — Value Modeling (empfohlen für vollständige Pipeline):**

Um T→I→P→S Beziehungsnetzwerke und priorisierte Lösungsvorlagen zu erstellen, rufen Sie das `value-modeler` Skill auf:

```
/value-modeler
```

Die Konfiguration und Kandidaten werden aus der konsolidierten Ausgabedatei geladen. Nach Abschluss des Value-Modelers fahren Sie mit `/trend-report` für den vollständigen CxO-Bericht fort.
```

---

## Success Criteria

- [ ] `trend-scout-output.json` updated with all web-grounded candidates
- [ ] `trend-candidates.md` written with status `agreed`
- [ ] Metadata complete (industry, subsector, language, sources)
- [ ] Success message displayed with next steps

---

## Output Files Summary

| File | Location | Purpose |
|------|----------|---------|
| `trend-scout-output.json` | `.metadata/` | Consolidated output (config + candidates + execution state) |
| `trend-candidates.md` | `{PROJECT_PATH}/` | Final trend list (status: agreed) |

---

## Integration with Downstream Pipeline

After trend-scout finalizes, the user proceeds to the next pipeline stage:

### Primary Path: value-modeler

1. **Project Discovery:**
   - value-modeler discovers the project via `tips-project.json`
   - Loads consolidated `trend-scout-output.json`

2. **Auto-Configuration:**
   - Reads `.config.research_type` → `smarter-service`
   - Reads `.config.dok_level` → `4`
   - Reads `.project_language` from output
   - Skips user prompts for these settings

3. **Candidate Loading:**
   - Loads candidates from `.tips_candidates.items`
   - Proceeds with all agreed candidates

4. **Value Modeling:**
   - Builds TIPS relationship networks across dimensions
   - Generates investment themes and ranked solution templates
   - Maintains provenance to trend-scout source file

### Alternative Path: trend-report

If value-modeling is not needed, trend-report can consume trend-scout output directly to produce a CxO-level narrative report.

---

## Workflow Complete

The trend-scout skill has completed all phases. User can now proceed to `/value-modeler` (recommended) or `/trend-report` (simpler path).
