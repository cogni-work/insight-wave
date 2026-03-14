# Phase 5: Validation & Output

## Objective

Verify citation provenance, validate document structure, and write the final synthesis document.

## Prerequisites (Gate Check)

Before starting Phase 5, verify:

- Phase 4 completed successfully
- Complete synthesis document in memory
- All sections present
- Citations use dual format

**IF MISSING: STOP. Return to Phase 4.**

---

## TodoWrite Expansion

When entering Phase 5, expand to these step-level todos:

```text
5.1 Extract and validate entity IDs [in_progress]
5.2 Verify all entities exist in filesystem [pending]
5.3 Calculate final word count [pending]
5.4 Update frontmatter metrics [pending]
5.5 Write synthesis document [pending]
5.6 Generate execution summary [pending]
```

---

## Step 5.1: Extract and Validate Entity IDs

**Action:** Parse synthesis document to extract all cited entity IDs.

**Citation patterns to match:**

```text
# Numbered citation format
<sup>[N](path/to/entity.md)</sup>

# Wikilink format
[[path/to/entity|Display Name]]
```

**Exact regex patterns for extraction:**

```text
# Numbered citation format - extract path from <sup>[N](path)</sup>
NUMBERED_CITATION_REGEX='<sup>\[[0-9]+\]\(([^)]+\.md)\)</sup>'

# Wikilink format - extract path from [[path|display]]
WIKILINK_REGEX='\[\[([^\]|]+\.md)\|[^\]]+\]\]'
```

**Example extraction (bash):**

```bash
# Extract numbered citations
echo "${SYNTHESIS_CONTENT}" | grep -oE '<sup>\[[0-9]+\]\([^)]+\.md\)</sup>' | \
  sed -E 's/<sup>\[[0-9]+\]\(([^)]+\.md)\)<\/sup>/\1/'

# Extract wikilinks
echo "${SYNTHESIS_CONTENT}" | grep -oE '\[\[[^\]|]+\.md\|[^\]]+\]\]' | \
  sed -E 's/\[\[([^\]|]+\.md)\|[^\]]+\]\]/\1/'
```

**Combine and deduplicate:**

```bash
ALL_CITED_PATHS=$(cat numbered_paths.txt wikilink_paths.txt | sort -u)
```

**Extract entity paths:**

```text
CITED_ENTITIES = [
  "11-trends/data/trend-transformation-office-governance-a1b2c3.md",
  "11-trends/data/trend-phasenmodell-meilensteine-d4e5f6.md",
  "10-claims/data/claim-transformation-office-abc123.md",
  ...
]
```

**Validation checks:**

1. All numbered citations have matching wikilinks
2. No duplicate citation numbers
3. Path format is valid (no absolute paths, no `../`)

**Verification:** Entity list extracted, format validated.

---

## Step 5.2: Verify All Entities Exist in Filesystem

**Action:** Check that each cited entity file exists.

**For each entity in CITED_ENTITIES:**

```bash
# Check file exists
if [[ ! -f "${PROJECT_PATH}/${entity_path}" ]]; then
  INVALID_ENTITIES+=("${entity_path}")
fi
```

**Alternative with Read tool:**

Attempt to read each file - if error, mark as invalid.

**If ANY entity missing:**

```json
{
  "success": false,
  "phase": 5,
  "step": "5.2",
  "error": "Fabricated entity IDs detected",
  "fabricated_entities": ["path/to/missing-entity.md"],
  "remediation": "Remove invalid citations or correct entity paths"
}
```

**ABORT synthesis if any entity is fabricated.**

**Verification:** All cited entities exist in filesystem.

---

## Step 5.3: Calculate Final Word Count

**Action:** Count words in synthesis document main body only (excludes appendix).

**Exclude from count:**

- YAML frontmatter (between `---` markers)
- Markdown formatting (headers, links, tables)
- Code blocks
- Comments
- **All appendix content** (from "## Appendix" header to end of document)

**Count method:**

```text
WORD_COUNT = count words in body text only
```

**Validate against target:**

| Status | Word Count | Action |
| ------ | ---------- | ------ |
| Under minimum | < 1,000 | Return to Phase 4, expand content |
| In range | 1,000-1,500 | Proceed |
| Over maximum | > 1,500 | Return to Phase 4, tighten prose |

**Verification:** Word count within 1,000-1,500 range.

---

## Step 5.4: Update Frontmatter Metrics

**Action:** Update YAML frontmatter with final metrics.

**Update fields:**

```yaml
---
word_count: {WORD_COUNT}
citation_count: {len(CITED_ENTITIES)}
# Enhanced metrics (already set in Phase 4, verify accuracy):
avg_evidence_strength: {QUALITY_METRICS.avg_evidence_strength}
avg_strategic_relevance: {QUALITY_METRICS.avg_strategic_relevance}
avg_actionability: {QUALITY_METRICS.avg_actionability}
avg_novelty: {QUALITY_METRICS.avg_novelty}
verification_rate: {QUALITY_METRICS.verification_rate}
source_tier_1_percentage: {tier_1_count / total_sources}
# Other fields already set
---
```

**Verification:** Frontmatter metrics accurate, including enhanced metrics for synthesis-hub aggregation.

---

## Step 5.5: Write Synthesis Document

**Action:** Write validated document to filesystem.

**Output path:**

```text
${PROJECT_PATH}/12-synthesis/synthesis-${DIMENSION}.md
```

**Use Write tool:**

```text
Write: ${PROJECT_PATH}/12-synthesis/synthesis-${DIMENSION}.md
Content: [complete synthesis document]
```

**Verify write success:**

```text
Read: ${PROJECT_PATH}/12-synthesis/synthesis-${DIMENSION}.md
```

Confirm content matches.

**Verification:** File written and readable.

---

## Step 5.6: Generate Execution Summary

**Action:** Create JSON summary of execution.

**Success response template:**

```json
{
  "success": true,
  "dimension": "{DIMENSION}",
  "file": "12-synthesis/synthesis-{DIMENSION}.md",
  "trends_synthesized": {TREND_COUNT},
  "citations_created": {len(CITED_ENTITIES)},
  "word_count": {WORD_COUNT},
  "cross_connections_identified": {len(CONNECTIONS where strong)},
  "thematic_clusters": {len(THEMATIC_CLUSTERS)},
  "avg_confidence": {QUALITY_METRICS.avg_trend_confidence},
  "evidence_freshness": "{QUALITY_METRICS.evidence_freshness}",
  "execution_time_seconds": {elapsed_time}
}
```

**Concise summary (for user display):**

```text
✅ Dimension synthesis complete.
- Dimension: {DIMENSION}
- Trends synthesized: {count}
- Citations created: {count}
- Word count: {count}
- Output: 12-synthesis/synthesis-{DIMENSION}.md
```

**Log completion:**

```bash
echo "[$(date -Iseconds)] Phase 5: Validation - COMPLETE" >> "${LOG_FILE}"
echo "[$(date -Iseconds)] Output: synthesis-${DIMENSION}.md (${WORD_COUNT} words)" >> "${LOG_FILE}"
```

**Verification:** Summary generated, logged.

---

## Phase 5 Outputs

- Validated synthesis document written to filesystem
- All citations verified against actual entities
- Word count confirmed within target range
- Execution summary JSON
- Concise summary for user display

---

## Output File Location

**Primary output:**

```text
${PROJECT_PATH}/12-synthesis/synthesis-${DIMENSION}.md
```

**Example:**

```text
/path/to/project/12-synthesis/synthesis-governance-transformationssteuerung.md
```

**Relationship to other files:**

```text
11-trends/
├── README-governance-transformationssteuerung.md  # Basic README (from trends-creator)
└── data/
    ├── trend-transformation-office-governance-a1b2c3.md
    ├── trend-phasenmodell-meilensteine-d4e5f6.md
    └── ...

12-synthesis/
└── synthesis-governance-transformationssteuerung.md  # Rich synthesis (from this skill)
```

---

## Error Responses

### Fabricated Entities

```json
{
  "success": false,
  "phase": 5,
  "step": "5.2",
  "error": "Fabricated entity IDs detected",
  "fabricated_entities": [
    "11-trends/data/trend-nonexistent.md"
  ],
  "total_citations": 24,
  "valid_citations": 23,
  "remediation": "Remove invalid citations and regenerate synthesis"
}
```

### Word Count Out of Range

```json
{
  "success": false,
  "phase": 5,
  "step": "5.3",
  "error": "Word count out of target range",
  "word_count": 850,
  "target_min": 1000,
  "target_max": 1500,
  "remediation": "Return to Phase 4 and expand content"
}
```

### Write Failure

```json
{
  "success": false,
  "phase": 5,
  "step": "5.5",
  "error": "Failed to write synthesis document",
  "target_path": "12-synthesis/synthesis-dimension.md",
  "remediation": "Check directory permissions and disk space"
}
```

---

## Success Criteria Checklist

Before marking skill complete, verify:

- [ ] All cited entity IDs exist in filesystem
- [ ] Word count is 1,000-1,500 (main body, excludes appendix)
- [ ] Citation count matches frontmatter
- [ ] Both citation formats present (numbered + wikilinks)
- [ ] **IF ARC_ID is empty (generic path):**
  - [ ] Planning horizon structure present in Key Trends section (Act/Plan/Observe subsections)
  - [ ] Implications & Recommendations includes role-based framing
- [ ] **IF ARC_ID is set (arc path):**
  - [ ] Overview paragraph present (100-150 words)
  - [ ] 4 arc element H2 sections present with correct headers per arc_id and PROJECT_LANGUAGE
  - [ ] **STOP AND VERIFY:** Re-read the written file's YAML frontmatter. Confirm ALL THREE arc fields are present: `arc_id`, `arc_display_name`, `arc_elements`. If ANY is missing, add it now (see Step 4.1 frontmatter template above for correct field format).
  - [ ] Each element contains only trends/claims classified to it (from ARC_ELEMENT_MAP)
- [ ] **Appendix structure present:**
  - [ ] H2 "Appendix" header after Implications & Recommendations (generic) or after last arc element (arc)
  - [ ] Subsection A: Evidence Assessment (4 tables)
  - [ ] Subsection B: Evidence Quality Analysis (4 subsections)
  - [ ] Subsection C: Domain Concepts (if not empty) OR skipped cleanly
  - [ ] Subsection D: References (with letter-prefixed subsections)
- [ ] Component quality scores in frontmatter (evidence_strength, strategic_relevance, actionability, novelty)
- [ ] Verification status breakdown in Evidence Assessment
- [ ] Source reliability distribution analyzed
- [ ] Related Megatrends section included (if applicable)
- [ ] Document written to correct path
- [ ] Execution summary generated
- [ ] All TodoWrite items marked complete

---

## Final Output Example

**File:** `12-synthesis/synthesis-governance-transformationssteuerung.md`

```markdown
---
title: "Dimension Synthesis: Governance & Transformationssteuerung"
dimension: "governance-transformationssteuerung"
research_type: "generic"
synthesis_date: "2026-01-11T10:30:00Z"
word_count: 1247
citation_count: 24
trend_count: 5
cross_connections: 4
avg_confidence: 0.81
thematic_clusters: 3
evidence_freshness: "current"
avg_evidence_strength: 0.82
avg_strategic_relevance: 0.85
avg_actionability: 0.78
avg_novelty: 0.75
verification_rate: 0.82
source_tier_1_percentage: 0.50
---

> **Navigation:** [Zurück zur Forschungsbericht-Übersicht](../research-hub.md) | **Aktuell:** Governance & Transformationssteuerung

# Governance & Transformationssteuerung

## Zusammenfassung

Die erfolgreiche Steuerung der DB Systel IT/OT-Transformation erfordert...

## Kernerkenntnisse

### Sofort Handeln (0-6 Monate)
Trends mit sofortigem Handlungsbedarf und ausgereifter Evidenz.

#### Transformation Office Governance (Confidence: 0.85, Quality: 0.82)
Ein Transformation Office mit fünf Kernkompetenzen...

[... full document content with planning horizon structure ...]

## Anhang

### A. Evidenzbewertung

**Qualitätsübersicht:**

| Metrik | Wert | Interpretation |
...

**Qualitätsverteilung:**

| Qualitätsdimension | Durchschnitt | Bereich | Anmerkungen |
...

**Verifikationsstatus:**

| Status | Claims | Prozentsatz |
...

**Quellenreliabilität:**

| Tier | Quellen | Beispiele |
...

### B. Evidenzqualitätsanalyse

**Verifikationsrobustheit:**

Die Trends dieser Dimension werden durch 14 Claims gestützt...

**Quellenautorität:**

Die Evidenz stammt überwiegend aus Tier-1 (50%) und Tier-2 Quellen (31%)...

**Evidenzaktualität:**

Alle zitierten Quellen sind aktuell...

**Qualitätsdimensionen-Einblicke:**

**Evidenzstärke (Ø: 0.82)**: Starke Zitationsbasis...

### C. Fachbegriffe

Schlüsselbegriffe dieser Dimension:
...

### D. Referenzen

**Erkenntnisse:**

[1] [Governance-Struktur](11-trends/data/trend-transformation-office-governance-a1b2c3.md) [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]]
[2] [Phasenmodell-Struktur](11-trends/data/trend-phasenmodell-meilensteine-d4e5f6.md) [[11-trends/data/trend-phasenmodell-meilensteine-d4e5f6|Phasenmodell-Struktur]]
...
```

---

## Transition Complete

**Mark Phase 5 todo as completed.**

**Mark all phase-level todos as completed.**

**Return execution summary to caller.**
