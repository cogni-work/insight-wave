# Phase 4: Synthesis Generation

## Objective

Generate comprehensive synthesis document with evidence-based narrative, dual citation format, and complete provenance tracking.

## Language Reference

**MANDATORY:** Use language-aware section headers based on PROJECT_LANGUAGE.

See [../language-templates.md](../language-templates.md) for:

- Section header translations (English/German)
- Evidence assessment table headers
- Navigation labels
- Language-specific formatting rules

## German Text Quality (MANDATORY for PROJECT_LANGUAGE=de)

**CRITICAL:** When generating German text (PROJECT_LANGUAGE=de), you MUST use proper German characters:

| Character | Correct                 | Incorrect                 |
|-----------|-------------------------|---------------------------|
| ä         | Qualität, Wertschöpfung | Qualitaet, Wertschoepfung |
| ö         | Lösungen, Größe         | Loesungen, Groesse        |
| ü         | Führung, Prüfung        | Fuehrung, Pruefung        |
| ß         | Maßnahmen, Größe        | Massnahmen, Groesse       |

**Rules:**

- Body text: ALWAYS use ä, ö, ü, ß
- Section headings: ALWAYS use ä, ö, ü, ß
- File names/slugs: ASCII only (ae, oe, ue, ss) - this is the ONLY exception

**Anti-pattern to avoid:** "mittelstaendischer" → correct: "mittelständischer"

See [../language-templates.md](../language-templates.md) for complete formatting rules.

## Prerequisites (Gate Check)

Before starting Phase 4, verify:

- Phase 3 completed successfully
- THEMATIC_CLUSTERS defined
- CONNECTIONS mapped
- QUALITY_METRICS calculated
- TREND_RANKING established

**IF MISSING: STOP. Return to Phase 3.**

---

## Pre-Existing Synthesis Check

**Action:** Check if synthesis file already exists.

```bash
SYNTHESIS_PATH="${PROJECT_PATH}/12-synthesis/synthesis-${DIMENSION}.md"
if [[ -f "${SYNTHESIS_PATH}" ]]; then
  echo "WARNING: Existing synthesis found at ${SYNTHESIS_PATH}"
  # Skill will overwrite - this is expected behavior for re-synthesis
fi
```

**Behavior:** Overwrite existing synthesis. The skill is designed to regenerate synthesis documents when trends have been updated.

**Note:** If preservation is needed, caller should backup before invocation.

---

## TodoWrite Expansion

When entering Phase 4, expand to these step-level todos:

**Generic path (ARC_ID empty):**

```text
4.1 Generate YAML frontmatter [in_progress]
4.1.5 Add Navigation Header [pending]
4.2 Write Executive Summary [pending]
4.3 Write Strategic Context [pending]
4.4 Write Key Trends section with planning horizons [pending]
4.5 Write Cross-Trend Connections [pending]
4.5.5 Add Related Dimensions section [pending]
4.5.6 Add Related Megatrends section [pending]
4.6 Write Implications & Recommendations [pending]
4.7 Generate Appendix: Evidence Assessment tables [pending]
4.7b Write Appendix: Evidence Quality Analysis section [pending]
4.8 Include Appendix: Domain Concepts [pending]
4.9 Generate Appendix: References section [pending]
```

**Arc path (ARC_ID set):**

```text
4.1 Generate YAML frontmatter (with arc fields) [in_progress]
4.1.5 Add Navigation Header [pending]
4.A0 Write Overview paragraph [pending]
4.A1 Write Arc Element 1 section [pending]
4.A2 Write Arc Element 2 section [pending]
4.A3 Write Arc Element 3 section [pending]
4.A4 Write Arc Element 4 section [pending]
4.5.5 Add Related Dimensions section [pending]
4.5.6 Add Related Megatrends section [pending]
4.7 Generate Appendix: Evidence Assessment tables [pending]
4.7b Write Appendix: Evidence Quality Analysis section [pending]
4.8 Include Appendix: Domain Concepts [pending]
4.9 Generate Appendix: References section [pending]
```

---

## Step 4.1: Generate YAML Frontmatter

**Action:** Create document metadata.

**Template:**

```yaml
---
title: "Dimension Synthesis: {DIMENSION_CONTEXT.display_name}"
dimension: "{DIMENSION}"
research_type: "{RESEARCH_TYPE}"
synthesis_date: "{ISO 8601 timestamp}"
word_count: 0  # Updated after writing
citation_count: 0  # Updated after writing
trend_count: {len(TRENDS)}
cross_connections: {len(CONNECTIONS where strength="strong")}
avg_confidence: {QUALITY_METRICS.avg_trend_confidence}
thematic_clusters: {len(THEMATIC_CLUSTERS)}
evidence_freshness: "{QUALITY_METRICS.evidence_freshness}"

# Enhanced metrics for synthesis-hub aggregation (NEW)
avg_evidence_strength: {QUALITY_METRICS.avg_evidence_strength}
avg_strategic_relevance: {QUALITY_METRICS.avg_strategic_relevance}
avg_actionability: {QUALITY_METRICS.avg_actionability}
avg_novelty: {QUALITY_METRICS.avg_novelty}
verification_rate: {QUALITY_METRICS.verification_rate}
source_tier_1_percentage: {percentage of tier-1 sources}
# Arc metadata — ONLY when ARC_ID is set (delete these 3 lines if ARC_ID is empty)
arc_id: "{ARC_ID}"
arc_display_name: "{ARC_DISPLAY_NAME}"
arc_elements: ["{Element 1 name}", "{Element 2 name}", "{Element 3 name}", "{Element 4 name}"]
---
```

**Example (generic path, no arc):**

```yaml
---
title: "Dimension Synthesis: Governance & Transformationssteuerung"
dimension: "governance-transformationssteuerung"
research_type: "generic"
synthesis_date: "2026-01-11T10:30:00Z"
word_count: 0
citation_count: 0
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
```

**Example (arc path, ARC_ID=corporate-visions):**

```yaml
---
title: "Dimension Synthesis: Governance & Transformationssteuerung"
dimension: "governance-transformationssteuerung"
research_type: "generic"
synthesis_date: "2026-01-11T10:30:00Z"
word_count: 0
citation_count: 0
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
arc_id: "corporate-visions"
arc_display_name: "Corporate Visions"
arc_elements: ["Why Change", "Why Now", "Why You", "Why Pay"]
---
```

**Verification:** All frontmatter fields populated. If ARC_ID is set, arc_id/arc_display_name/arc_elements MUST be present.

---

## Step 4.1.5: Add Navigation Header

**Action:** Generate navigation breadcrumb for standalone reading using language-aware labels.

**Purpose:** Enable readers who land directly on a dimension synthesis (via link, search, or HTML export) to navigate back to the hub document.

**Template (language-aware):**

```markdown
> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {DIMENSION_CONTEXT.display_name}
```

**Example (English - PROJECT_LANGUAGE=en):**

```markdown
> **Navigation:** [Back to Research Report Overview](../research-hub.md) | **Current:** Governance & Transformation Control
```

**Example (German - PROJECT_LANGUAGE=de):**

```markdown
> **Navigation:** [Zurück zur Forschungsbericht-Übersicht](../research-hub.md) | **Aktuell:** Governance & Transformationssteuerung
```

**Placement:** Immediately after YAML frontmatter, before the H1 title.

**HTML Export Note:** This navigation link works in both markdown viewers and HTML exports, as the relative path `../research-hub.md` resolves correctly from `12-synthesis/` to the project root.

**Verification:** Navigation header present with correct dimension name.

---

## Arc Path Routing

**CONDITIONAL:** Check ARC_ID to determine synthesis path.

```text
IF ARC_ID is non-empty (recognized arc from Phase 1 Step 1.5b):
  → Arc path: Steps 4.1 → 4.1.5 → 4.A0 → 4.A1-4.A4 → 4.5.5 → 4.5.6 → 4.7-4.9
  → SKIP generic Steps 4.2-4.6 (their content is redistributed to arc elements)

IF ARC_ID is empty:
  → Generic path: Steps 4.1-4.9 (completely unchanged, proceed to Step 4.2 below)
```

**What generic steps map to in arc path:**

| Generic Step | Arc Path Equivalent |
|-------------|-------------------|
| 4.2 Executive Summary (200-300 words) | Compressed into 4.A0 Overview (100-150 words) |
| 4.3 Strategic Context (150-200 words) | Woven into Overview + element introductions |
| 4.4 Key Trends (450-650 words) | Distributed across 4.A1-4.A4 by arc classification |
| 4.5 Cross-Connections (150-200 words) | Woven as transitions between elements |
| 4.6 Implications (280-400 words) | Absorbed into arc elements (especially element 4) |

**If ARC_ID is set, skip directly to Step 4.A0 below. Otherwise, continue to Step 4.2.**

---

## Step 4.A0: Write Overview Paragraph (Arc Path Only)

**Condition:** Only execute when ARC_ID is set. Skip for generic path.

**Target:** 100-150 words (no H2 header — this is a paragraph under the H1 title)

**Structure:**

```markdown
# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words establishing dimension scope, top findings, and how evidence maps to the arc framework. Mention the arc display name. Include 1-2 citations to highest-ranked trends.}
```

**Content guidance:**

1. Open with dimension scope and strategic importance (1-2 sentences)
2. State the most significant finding from top-ranked trend with citation
3. Preview how evidence organizes across the arc elements (1 sentence)
4. State confidence assessment (1 sentence)

**Citation density:** 1-2 citations

**Example (corporate-visions arc, German):**

```markdown
# Governance & Transformationssteuerung

*Wie kann eine unternehmensweite IT/OT-Transformation über mehrere Jahre strukturiert gesteuert werden?*

Die Analyse dieser Dimension zeigt, dass erfolgreiche Transformationssteuerung ein dediziertes Governance-Framework mit fünf integrierten Kernkompetenzen erfordert<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]]. Die Evidenz aus 14 verifizierten Claims (Konfidenz: 0,81) offenbart klare Handlungsmuster: bestehende Ansätze versagen bei dieser Komplexität, zeitgebundene Faktoren erzwingen schnelles Handeln, spezifische Fähigkeiten ermöglichen Differenzierung, und messbare Wertschöpfung rechtfertigt die Investition<sup>[3](11-trends/data/trend-kpi-erfolgsmessung-g7h8i9.md)</sup> [[11-trends/data/trend-kpi-erfolgsmessung-g7h8i9|KPI-Framework]].
```

**Verification:** 100-150 words, 1-2 citations, arc framework mentioned.

---

## Steps 4.A1-4.A4: Write Arc Element Sections (Arc Path Only)

**Condition:** Only execute when ARC_ID is set. Skip for generic path.

**General structure for each arc element:**

```markdown
## {ARC_HEADER_ELEMENT_N}

{Element narrative using classified trends and claims from ARC_ELEMENT_MAP.element_N}
```

**Arc element header resolution:** Use arc-specific headers from language-templates.md based on ARC_ID and PROJECT_LANGUAGE.

**Per-element writing protocol:**

1. **Opening sentence:** State the element's core assertion based on classified evidence
2. **Trend narratives:** For each trend classified to this element (ordered by TREND_RANKING), write 60-100 words synthesizing the trend with inline citations
3. **Cross-element transitions:** Where a trend connects to another element's trends (from CONNECTIONS), add a brief transition phrase (10-20 words)
4. **Evidence gap handling:** If an element received trends only through rebalancing (Step 3.7), write a shorter section (50-75 words) noting the evidence gap honestly

**Citation format (same as generic path):**

```markdown
Evidence text<sup>[N](11-trends/data/trend-slug.md)</sup> [[11-trends/data/trend-slug|Display Title]].
```

### Step 4.A1: Write Arc Element 1

**Word target:** 250-400 words
**Citation density:** 3-5 citations
**Source:** `ARC_ELEMENT_MAP.element_1.trend_ids` and `ARC_ELEMENT_MAP.element_1.claim_ids`

**Content focus:** See loaded arc template Element 1 content guidance.

### Step 4.A2: Write Arc Element 2

**Word target:** 200-350 words
**Citation density:** 2-4 citations
**Source:** `ARC_ELEMENT_MAP.element_2.trend_ids` and `ARC_ELEMENT_MAP.element_2.claim_ids`

**Content focus:** See loaded arc template Element 2 content guidance.

### Step 4.A3: Write Arc Element 3

**Word target:** 250-400 words
**Citation density:** 3-5 citations
**Source:** `ARC_ELEMENT_MAP.element_3.trend_ids` and `ARC_ELEMENT_MAP.element_3.claim_ids`

**Content focus:** See loaded arc template Element 3 content guidance.

### Step 4.A4: Write Arc Element 4

**Word target:** 150-250 words
**Citation density:** 2-3 citations
**Source:** `ARC_ELEMENT_MAP.element_4.trend_ids` and `ARC_ELEMENT_MAP.element_4.claim_ids`

**Content focus:** See loaded arc template Element 4 content guidance.

---

## Arc Path Frontmatter Reference

Arc frontmatter fields (arc_id, arc_display_name, arc_elements) are **inlined in the Step 4.1 template above**. No separate addition step is needed — the template includes conditional arc lines with clear instructions to delete them when ARC_ID is empty.

---

## Arc Path Word Count Tracking

| Section | Target | Running Total |
|---------|--------|---------------|
| Overview paragraph | 100-150 | ~125 |
| Arc Element 1 | 250-400 | ~450 |
| Arc Element 2 | 200-350 | ~725 |
| Arc Element 3 | 250-400 | ~1000 |
| Arc Element 4 | 150-250 | ~1175 |
| Related Dimensions (opt) | 50-100 | ~1225 |
| Related Megatrends (opt) | 100-250 | ~1350 |
| **Total** | **1,000-1,500** | |

**Appendix sections (excluded from word count):** Same as generic path.

**If exceeding 1,500 words:** Tighten prose in Element 3 or Related Megatrends sections.

**If under 1,000 words:** Expand Element 1 or Element 3 with more trend detail.

---

## Arc Path: After Steps 4.A1-4.A4

After completing arc element sections, resume shared steps:

- **Step 4.5.5:** Add Related Dimensions section (unchanged)
- **Step 4.5.6:** Add Related Megatrends section (unchanged)
- **Steps 4.7-4.9:** Generate appendix (unchanged)

Skip Steps 4.2-4.6 entirely — their content has been redistributed to arc elements.

---

## Step 4.2: Write Executive Summary

**Target:** 200-300 words with 3-5 citations

**Structure (language-aware headers):**

```markdown
# {DIMENSION_CONTEXT.display_name}

*{DIMENSION_CORE_QUESTION}*

## {HEADER_EXECUTIVE_SUMMARY}

[Opening sentence establishing dimension scope and importance]

[Key findings paragraph - synthesize top-ranked trends with citations]

[Strategic implications paragraph - what this means for stakeholders]

[Conclusion - main takeaway with confidence assessment]
```

**Core Question Rendering Rules:**

| Condition | Output |
|---|---|
| `DIMENSION_CORE_QUESTION` is non-empty | Single italic line: `*{DIMENSION_CORE_QUESTION}*` in PROJECT_LANGUAGE |
| `DIMENSION_CORE_QUESTION` is empty | Omit entirely — go straight from H1 to `## {HEADER_EXECUTIVE_SUMMARY}` |

**Header values by language:**

| Language | Header            |
|----------|-------------------|
| en       | Executive Summary |
| de       | Zusammenfassung   |

**Citation format (MANDATORY - both formats):**

```markdown
Das Transformation Office benötigt fünf Kernkompetenzen<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]].
```

**Writing guidelines:**

1. Lead with the most important finding (top-ranked trend)
2. Connect findings to strategic context
3. Use specific evidence, not generalizations
4. Include confidence assessment ("high confidence based on X claims")
5. **MANDATORY (de):** Use proper German Umlaute (ä, ö, ü, ß) in ALL body text - never use ae/oe/ue/ss transliterations

**Example (German):**

```markdown
## Executive Summary

Die erfolgreiche Steuerung der DB Systel IT/OT-Transformation erfordert eine dedizierte Governance-Struktur mit fünf Kernkompetenzen<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]]. Ein traditionelles PMO reicht nicht aus - stattdessen ist ein Transformation Office erforderlich, das Orchestrierung, Change Management, Deployment, Value Realisation und Architektur integriert.

Das Drei-Phasen-Modell (Foundation, Execution, Scale) mit Definition-of-Done-Meilensteinen<sup>[2](11-trends/data/trend-phasenmodell-meilensteine-d4e5f6.md)</sup> [[11-trends/data/trend-phasenmodell-meilensteine-d4e5f6|Phasenmodell]] kombiniert strukturierte Planung mit agiler Anpassungsfähigkeit. Quick Wins in den ersten 6-9 Monaten<sup>[5](11-trends/data/trend-quick-wins-momentum-m3n4o5.md)</sup> [[11-trends/data/trend-quick-wins-momentum-m3n4o5|Quick-Win-Strategie]] etablieren Transformations-Glaubwürdigkeit.

Diese Erkenntnisse basieren auf 14 verifizierten Claims mit einer durchschnittlichen Konfidenz von 0.81, was eine hohe Evidenzqualität indiziert.
```

**Verification:** 200-300 words, 3-5 citations, both formats used.

---

## Step 4.3: Write Strategic Context

**Target:** 150-200 words with 2-3 citations

**Structure (language-aware headers):**

```markdown
## {HEADER_STRATEGIC_CONTEXT}

[Dimension importance - why this matters]

[Connection to overall research question]

[Key challenges or opportunities addressed]
```

**Header values by language:**

| Language | Header                |
|----------|---------------------- |
| en       | Strategic Context     |
| de       | Strategischer Kontext |

**Content source:** DIMENSION_CONTEXT + STRATEGIC_PATTERNS

**Example:**

```markdown
## Strategic Context

Die Dimension Governance & Transformationssteuerung adressiert die kritische Frage, wie eine unternehmensweite IT/OT-Transformation über mehrere Jahre gesteuert werden kann<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]].

Bei Transformationsprojekten dieser Größenordnung - 2026-2030 mit erheblichen Budget- und Personalressourcen - ist die Governance-Struktur erfolgskritisch. Die Forschung zeigt, dass traditionelle Projektmanagement-Ansätze bei derart komplexen Vorhaben versagen und spezialisierte Steuerungsmechanismen erforderlich sind<sup>[4](11-trends/data/trend-stakeholder-management-j0k1l2.md)</sup> [[11-trends/data/trend-stakeholder-management-j0k1l2|Stakeholder-Orchestrierung]].
```

**Verification:** 150-200 words, 2-3 citations.

---

## Step 4.4: Write Key Trends Section

**Target:** 400-600 words total (80-120 words per trend)

**Structure (language-aware headers with planning horizon subsections):**

```markdown
## {HEADER_KEY_TRENDS}

### Act Now (0-6 Months)
Trends requiring immediate action with mature evidence.

#### {Trend Title} (Confidence: 0.85, Quality: 0.82)

[Synthesized narrative with key evidence and citations]

#### {Trend Title} (Confidence: 0.81, Quality: 0.79)

[Synthesized narrative]

### Plan Ahead (6-18 Months)
Trends requiring capability building with strong signals.

#### {Trend Title} (Confidence: 0.78, Quality: 0.76)

[Synthesized narrative]

### Observe & Monitor (18+ Months)
Emerging trends with early-stage evidence.

#### {Trend Title} (Confidence: 0.72, Quality: 0.68)

[Synthesized narrative]
```

**Header values by language:**

| Language | Header           |
|----------|------------------|
| en       | Key Trends     |
| de       | Kernerkenntnisse |

**Planning horizon subsection headers (language-aware):**

| Language | Act Now | Plan Ahead | Observe & Monitor |
|----------|---------|------------|-------------------|
| en       | Act Now (0-6 Months) | Plan Ahead (6-18 Months) | Observe & Monitor (18+ Months) |
| de       | Sofort Handeln (0-6 Monate) | Vorausplanen (6-18 Monate) | Beobachten & Monitoring (18+ Monate) |

**Subsection descriptions (language-aware):**

| Language | Act | Plan | Observe |
|----------|-----|------|---------|
| en       | Trends requiring immediate action with mature evidence. | Trends requiring capability building with strong signals. | Emerging trends with early-stage evidence. |
| de       | Trends mit sofortigem Handlungsbedarf und ausgereifter Evidenz. | Trends mit Kompetenzaufbaubedarf und starken Signalen. | Aufkommende Trends mit frühen Evidenzen. |

**Structural rules:**

1. Use PLANNING_HORIZON_GROUPS from Phase 3
2. Create three H3 subsections: Act Now, Plan Ahead, Observe & Monitor
3. Add one-sentence subsection description after each H3
4. Use H4 headings for individual trends with confidence and quality scores
5. Order trends within each horizon by TREND_RANKING
6. If a horizon has no trends, skip that subsection

**Per-trend content:**

1. Core assertion (what the trend claims)
2. Key evidence (most important claim with citation)
3. Strategic significance (why it matters)
4. (Optional) Megatrend context where applicable

**Citation density:** 1-2 citations per trend subsection

**Megatrend integration (optional):**

When a trend has megatrend_refs, add context referencing the megatrend:

```markdown
This trend manifests the [[06-megatrends/data/megatrend-{slug}|{title}]] megatrend (confidence: {0.XX}, {horizon} horizon), representing {one-sentence connection}.
```

**Example:**

```markdown
## {HEADER_KEY_TRENDS}

### Sofort Handeln (0-6 Monate)
Trends mit sofortigem Handlungsbedarf und ausgereifter Evidenz.

#### Transformation Office Governance (Confidence: 0.85, Quality: 0.82)

Ein Transformation Office mit fünf Kernkompetenzen - Orchestrierung, Change Management, Deployment, Value Realisation und Architektur - ist für die DB Systel Transformation erforderlich<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]]. Diese Struktur unterscheidet sich fundamental von einem traditionellen PMO, da sie die Komplexität einer mehrjährigen IT/OT-Transformation adressiert. Die fünf Kompetenzen arbeiten integriert zusammen, um sowohl strategische als auch operative Herausforderungen zu bewältigen.

### Vorausplanen (6-18 Monate)
Trends mit Kompetenzaufbaubedarf und starken Signalen.

#### KPI-Framework und Erfolgsmessung (Confidence: 0.78, Quality: 0.76)

Ein soziotechnisches KPI-Modell, das auf DB Systels etablierter OKR-Kompetenz aufbaut, kombiniert technische Lagging Indicators mit menschlichen Leading Indicators<sup>[3](11-trends/data/trend-kpi-erfolgsmessung-g7h8i9.md)</sup> [[11-trends/data/trend-kpi-erfolgsmessung-g7h8i9|KPI-Framework]]. Diese Kombination ermöglicht sowohl retrospektive Erfolgsmessung als auch proaktive Steuerung der Transformation durch Frühindikatoren.
```

**Word count impact:** +50 words (subsection headers + descriptions)

**Verification:** 450-650 words, all trends covered in appropriate planning horizon subsections, 1-2 citations per trend.

---

## Step 4.5: Write Cross-Trend Connections

**Target:** 150-200 words

**Structure (language-aware headers):**

```markdown
## {HEADER_CROSS_CONNECTIONS}

[Narrative describing how trends relate to each other]
```

**Header values by language:**

| Language | Header                    |
|----------|---------------------------|
| en       | Cross-Trend Connections |
| de       | Erkenntnisverknüpfungen   |

**Content source:** CONNECTIONS array

**Connection narrative:**

1. Identify the most significant connections (strong + causal/sequential)
2. Explain how trends reinforce or build on each other
3. Highlight any synergies

**Example:**

```markdown
## Cross-Trend Connections

Die fünf Trends dieser Dimension bilden ein kohärentes Steuerungsframework. Die Governance-Struktur (Transformation Office) ermöglicht die Multi-Level-Stakeholder-Orchestrierung und bildet die Grundlage für systematische KPI-Messung. Das Drei-Phasen-Modell strukturiert die zeitliche Abfolge, wobei Quick Wins in Phase 1 (Foundation) die Transformations-Glaubwürdigkeit etablieren, die für Phase 2 (Execution) erforderlich ist.

Diese kausale Verknüpfung - Governance ermöglicht Stakeholder-Management, Quick Wins bauen Momentum für Phasenmodell - zeigt, dass die Elemente nicht isoliert implementiert werden können, sondern als integriertes System funktionieren müssen.
```

**Verification:** 150-200 words.

---

## Step 4.5.5: Add Related Dimensions Section

**Target:** 50-100 words

**Condition:** Include this section if cross-dimension connections were identified during Phase 3 analysis.

**Purpose:** Guide readers to related dimension syntheses for comprehensive understanding.

**Template (language-aware headers):**

```markdown
## {HEADER_RELATED_DIMENSIONS}

{INTRO_RELATED_DIMENSIONS}

- **[{Related Dimension 1 Display Name}](synthesis-{dim1-slug}.md):** {One-sentence relationship description}
- **[{Related Dimension 2 Display Name}](synthesis-{dim2-slug}.md):** {One-sentence relationship description}

*{FOOTER_CROSS_DIMENSIONAL}*
```

**Header values by language:**

| Language | Header                |
|----------|-----------------------|
| en       | Related Dimensions    |
| de       | Verwandte Dimensionen |

**Intro text by language:**

| Language | Text                                                             |
|----------|------------------------------------------------------------------|
| en       | This analysis connects to other research dimensions:             |
| de       | Diese Analyse verbindet sich mit weiteren Forschungsdimensionen: |

**Footer text by language:**

| Language | Text                                                                                                 |
|----------|------------------------------------------------------------------------------------------------------|
| en       | For cross-dimensional synthesis, see the [Research Report Overview](../research-hub.md).          |
| de       | Für dimensionsübergreifende Synthese siehe die [Forschungsbericht-Übersicht](../research-hub.md). |

**Example:**

```markdown
## Related Dimensions

This analysis connects to other research dimensions:

- **[Wirtschaftlichkeit & Business Case](synthesis-wirtschaftlichkeit-business-case.md):** Resource investments for governance structure require business case validation
- **[Risikomanagement & Qualitaetssicherung](synthesis-risikomanagement-qualitaetssicherung.md):** Governance framework enables systematic risk mitigation

*For cross-dimensional synthesis, see the [Research Report Overview](../research-hub.md).*
```

**Data Source:** Use CONNECTIONS from Phase 3 where `strength="strong"` and connection involves a different dimension.

**Skip if:** No cross-dimension connections identified (single-dimension research or isolated dimension).

**Verification:** Related dimensions section present with correct links, or documented as skipped.

---

## Step 4.5.6: Add Related Megatrends Section (NEW)

**Target:** 100-150 words

**Condition:** Include this section if megatrend_refs were found in loaded trends.

**Purpose:** Guide readers to related megatrend entities for cross-dimensional synthesis.

**Template (language-aware headers):**

```markdown
## {HEADER_RELATED_MEGATRENDS}

{INTRO_RELATED_MEGATRENDS}

- [[06-megatrends/data/megatrend-{slug}|{title}]] ({horizon}, {0.XX}) - {One-sentence description of connection}
- [[06-megatrends/data/megatrend-{slug}|{title}]] ({horizon}, {0.XX}) - {One-sentence description}
...

*{FOOTER_MEGATRENDS}*
```

**Header values by language:**

| Language | Header              |
|----------|---------------------|
| en       | Related Megatrends  |
| de       | Verwandte Megatrends |

**Intro text by language:**

| Language | Text                                                    |
|----------|---------------------------------------------------------|
| en       | This dimension connects to {N} cross-dimensional megatrends: |
| de       | Diese Dimension verbindet sich mit {N} dimensionsübergreifenden Megatrends: |

**Footer text by language:**

| Language | Text                                                                                                                  |
|----------|-----------------------------------------------------------------------------------------------------------------------|
| en       | *For detailed megatrend analysis, see individual megatrend entities or the [Research Report Overview](../research-hub.md).* |
| de       | *Für detaillierte Megatrend-Analyse siehe individuelle Megatrend-Entitäten oder die [Forschungsbericht-Übersicht](../research-hub.md).* |

**Example:**

```markdown
## Verwandte Megatrends

Diese Dimension verbindet sich mit 3 dimensionsübergreifenden Megatrends:

- [[06-megatrends/data/megatrend-digitalization-a1b2|Industrial Digitalization]] (act, 0.85) - Digitale Transformation erfordert strukturierte Governance-Mechanismen für erfolgreiche Umsetzung
- [[06-megatrends/data/megatrend-agile-transformation-c3d4|Agile Transformation]] (plan, 0.78) - Agile Methodologien benötigen Transformation-Office-Koordination
- [[06-megatrends/data/megatrend-value-management-e5f6|Value-Based Management]] (act, 0.82) - KPI-Frameworks ermöglichen wertebasierte Steuerung

*Für detaillierte Megatrend-Analyse siehe individuelle Megatrend-Entitäten oder die [Forschungsbericht-Übersicht](../research-hub.md).*
```

**Data Source:** MEGATREND_METADATA loaded in Phase 2

**Skip if:** No megatrend_refs in any trend (log: "No megatrend connections found for dimension {slug}").

**Verification:** Related Megatrends section present with 3-5 megatrends, or documented as skipped.

---

## Step 4.6: Write Implications & Recommendations

**Target:** 200-300 words

**Structure (language-aware headers):**

```markdown
## {HEADER_IMPLICATIONS}

**{HEADER_STRATEGIC_IMPLICATIONS}:**

[Strategic implications - for decision-makers]

**{HEADER_TACTICAL_RECOMMENDATIONS}:**

[Tactical recommendations - for practitioners]

[Prioritized action list with citations]
```

**Header values by language:**

| Language | Header                         |
|----------|--------------------------------|
| en       | Implications & Recommendations |
| de       | Implikationen & Empfehlungen   |

**Sub-header values by language:**

| Language | Strategic                  | Tactical                    |
|----------|----------------------------|-----------------------------|
| en       | Strategic Implications     | Tactical Recommendations    |
| de       | Strategische Implikationen | Taktische Empfehlungen      |

**Content source:** STRATEGIC_PATTERNS + trend Implications sections

**Format:** Bullet points with citations

**Example (Enhanced with role-based framing):**

```markdown
## Implikationen & Empfehlungen

### Strategische Implikationen

**Für Technologieführung:**
- Act-Horizont-Trends (Transformation Office, Governance-Struktur) erfordern sofortige Budgetallokation für spezialisierte Kompetenzen<sup>[1](11-trends/data/trend-transformation-office-governance-a1b2c3.md)</sup> [[11-trends/data/trend-transformation-office-governance-a1b2c3|Governance-Struktur]]
- Plan-Horizont-Trends signalisieren Kompetenzlücken, die 12-18 Monate Skill-Entwicklung benötigen

**Für Operations:**
- Evidenz zeigt 15-20% Effizienzgewinne rechtfertigen ROI für Transformation-Office-Investitionen
- Observe-Horizont-Trends (KI-gestützte Wartung) rechtfertigen Pilot-Programme

**Für Workforce Planning:**
- 3 von 5 Trends erfordern neue technische Kompetenzen (Data Science, IoT-Architektur)
- Verification-Analyse deutet darauf hin, dass externe Partnerschaften Kompetenzaufbau beschleunigen könnten

### Taktische Empfehlungen
1. Priorisiere {Top Act-Horizont Trend} (act, confidence 0.85) - höchster ROI mit ausgereifter Evidenz
2. Initiiere Workforce-Upskilling für Plan-Horizont-Trends (6-18 Monate Lead-Time)
3. Monitore Observe-Horizont-Trends quartalsweise auf Signal-Verstärkung
4. Etabliere OKR-basierte KPI-Struktur ab Projektstart<sup>[3](11-trends/data/trend-kpi-erfolgsmessung-g7h8i9.md)</sup> [[11-trends/data/trend-kpi-erfolgsmessung-g7h8i9|KPI-Framework]]
5. Auswahl von Quick Wins nach Low-Complexity-High-Visibility-Matrix<sup>[5](11-trends/data/trend-quick-wins-momentum-m3n4o5.md)</sup> [[11-trends/data/trend-quick-wins-momentum-m3n4o5|Quick-Win-Strategie]]
```

**Enhanced structure:**

1. Add role-based subsections under Strategic Implications (Technology Leaders, Operations, Workforce Planning)
2. Reference planning horizons explicitly in recommendations
3. Number tactical recommendations by priority
4. Integrate component quality insights (e.g., "verification analysis suggests...")
5. Maintain citation density (each recommendation with citation)

**Word count impact:** +120 words (role-based framing)

**Verification:** 280-400 words, citations for each recommendation, role-based framing present.

---

**NOTE:** Main narrative ends here. Following sections are appendix content excluded from 1,000-1,500 word target.

---

## Step 4.7: Generate Appendix H2 Header and Evidence Assessment Tables

**Action:** Create appendix section with H2 header, then add Evidence Assessment as subsection A with four metrics summary tables using language-aware headers.

**Action:** Create four metrics summary tables using language-aware headers.

**Structure:**

```markdown
## {HEADER_APPENDIX}

### A. {HEADER_EVIDENCE_ASSESSMENT}

**Quality Overview:**
| {TH_METRIC} | {TH_VALUE} | {TH_INTERPRETATION} |
| ------ | ----- | ------------ |
| {ROW_TOTAL_TRENDS} | {TREND_COUNT} | {X act, Y plan, Z observe} |
| {ROW_CLAIMS_REFERENCED} | {TOTAL_CLAIMS} | {X.X claims per trend} |
| {ROW_AVG_TREND_CONFIDENCE} | {QUALITY_METRICS.avg_trend_confidence} | {High/Medium/Low confidence} |
| {ROW_EVIDENCE_FRESHNESS} | {QUALITY_METRICS.evidence_freshness} | All sources <12 months |

### Quality Distribution
| {TH_QUALITY_DIMENSION} | {TH_AVERAGE} | {TH_RANGE} | {TH_NOTES} |
| ----------------- | ------- | ----- | ----- |
| {ROW_EVIDENCE_STRENGTH} | {QUALITY_METRICS.avg_evidence_strength} | {min}-{max} | Strong citation base |
| {ROW_STRATEGIC_RELEVANCE} | {QUALITY_METRICS.avg_strategic_relevance} | {min}-{max} | High alignment to questions |
| {ROW_ACTIONABILITY} | {QUALITY_METRICS.avg_actionability} | {min}-{max} | Clear recommendations |
| {ROW_NOVELTY} | {QUALITY_METRICS.avg_novelty} | {min}-{max} | Some overlap with existing knowledge |

### Verification Status
| {TH_STATUS} | {TH_CLAIMS} | {TH_PERCENTAGE} |
| ------ | ----- | ---------- |
| {ROW_VERIFIED} | {QUALITY_METRICS.verification_breakdown.verified} | {XX%} |
| {ROW_PARTIALLY_VERIFIED} | {QUALITY_METRICS.verification_breakdown.partially_verified} | {XX%} |
| {ROW_UNVERIFIED} | {QUALITY_METRICS.verification_breakdown.unverified} | {XX%} |
| {ROW_CONTRADICTED} | {QUALITY_METRICS.verification_breakdown.contradicted} | {XX%} (if any) |

### Source Reliability
| {TH_TIER} | {TH_SOURCES} | {TH_EXAMPLES} |
| ---- | ------- | -------- |
| {ROW_TIER_1} | {QUALITY_METRICS.source_tier_distribution.tier_1} | Nature, Science, peer-reviewed journals |
| {ROW_TIER_2} | {QUALITY_METRICS.source_tier_distribution.tier_2} | McKinsey, Gartner, industry reports |
| {ROW_TIER_3} | {QUALITY_METRICS.source_tier_distribution.tier_3} | Trade publications, conference papers |
| {ROW_TIER_4} | {QUALITY_METRICS.source_tier_distribution.tier_4} | Blog posts, opinion pieces |
```

**Header values by language:**

| Language | Header              |
|----------|---------------------|
| en       | Evidence Assessment |
| de       | Evidenzbewertung    |

**Table subsection headers (language-aware):**

| Language | Quality Overview | Quality Distribution | Verification Status | Source Reliability |
|----------|------------------|----------------------|---------------------|-------------------|
| en       | Quality Overview | Quality Distribution | Verification Status | Source Reliability |
| de       | Qualitätsübersicht | Qualitätsverteilung | Verifikationsstatus | Quellenreliabilität |

**Table header/row values:** See [../language-templates.md](../language-templates.md) for complete translations.

**Word count impact:** +100 words (table headers, interpretation column, notes)

**Verification:** Four tables complete with accurate values, headers in PROJECT_LANGUAGE.

---

## Step 4.7b: Write Appendix Subsection B - Evidence Quality Analysis

**Target:** 250-300 words

**Action:** Add detailed evidence quality narrative after Evidence Assessment tables as subsection B of appendix.

**Purpose:** Provide readers with trust signals and methodology transparency, showing evidence robustness beyond simple metrics.

**Structure (language-aware headers):**

```markdown
### B. {HEADER_EVIDENCE_QUALITY_ANALYSIS}

### {HEADER_VERIFICATION_ROBUSTNESS}
{INTRO_VERIFICATION_STATS}

{ANALYSIS_UNVERIFIED_CLAIMS}

### {HEADER_SOURCE_AUTHORITY}
{ANALYSIS_TIER_DISTRIBUTION}

{NOTABLE_TIER_1_SOURCES}

### {HEADER_EVIDENCE_FRESHNESS_DETAIL}
{ANALYSIS_RECENCY}

### {HEADER_QUALITY_DIMENSION_INSIGHTS}
**{LABEL_EVIDENCE_STRENGTH} (avg: {0.XX})**: {Interpretation - strong/moderate/weak citation base}. {Range analysis}.

**{LABEL_STRATEGIC_RELEVANCE} (avg: {0.XX})**: {Interpretation - alignment to research questions}.

**{LABEL_ACTIONABILITY} (avg: {0.XX})**: {Interpretation - clarity of recommendations}. {Horizon-specific insights if applicable}.

**{LABEL_NOVELTY} (avg: {0.XX})**: {Interpretation - overlap with existing knowledge vs. new insights}.
```

**Header values by language:**

| Language | Main Header | Subsection Headers |
|----------|-------------|-------------------|
| en       | Evidence Quality Analysis | Verification Robustness, Source Authority, Evidence Freshness, Quality Dimension Insights |
| de       | Evidenzqualitätsanalyse | Verifikationsrobustheit, Quellenautorität, Evidenzaktualität, Qualitätsdimensionen-Einblicke |

**Example:**

```markdown
### B. Evidenzqualitätsanalyse

### Verifikationsrobustheit
Die Trends dieser Dimension werden durch 14 Claims gestützt, von denen 82% verifiziert (11 Claims), 14% teilweise verifiziert (2 Claims) und 4% unverifiziert (1 Claim) sind. Die hohe Verifikationsrate von 82% indiziert starke Evidenzqualität.

Der eine unverifizierte Claim bezieht sich auf zukünftige Technologie-Entwicklungen (18+ Monate) im Observe-Horizont und stellt ein akzeptables Risikoprofil dar.

### Quellenautorität
Die Evidenz stammt überwiegend aus Tier-1 (50%, 8 Quellen) und Tier-2 Quellen (31%, 5 Quellen), mit Tier-3 (12%, 2 Quellen) als ergänzendem Kontext. Keine Tier-4 Quellen wurden verwendet.

Bemerkenswerte Tier-1 Quellen umfassen Nature, Science und peer-reviewed Fachzeitschriften. Tier-2 Quellen umfassen McKinsey, Gartner und Branchenberichte.

### Evidenzaktualität
Alle zitierten Quellen sind aktuell (publiziert innerhalb von 11 Monaten), mit der ältesten Quelle vom 2026-01-09 (11 Monate alt). Hohe Aktualität stärkt Relevanz für aktuelle Entscheidungen.

### Qualitätsdimensionen-Einblicke
**Evidenzstärke (Ø: 0.82)**: Starke Zitationsbasis indiziert umfassende Abdeckung. Range 0.75-0.89 zeigt konsistente Qualität.

**Strategische Relevanz (Ø: 0.85)**: Hohe Ausrichtung zu Forschungsfragen, minimale tangentiale Erkenntnisse.

**Umsetzbarkeit (Ø: 0.78)**: Klare Empfehlungen vorhanden. Act-Horizont-Trends scoren höher (0.84 Ø) als Plan-Horizont (0.76 Ø), was natürliche Umsetzbarkeits-Gradienten reflektiert.

**Neuheit (Ø: 0.75)**: Moderate Überlappung mit bestehendem Wissen, aber signifikante neue Einblicke in Governance-Strukturen für IT/OT-Transformation.
```

**Writing guidelines:**

1. Use quantitative data from QUALITY_METRICS
2. Provide interpretations (not just numbers)
3. Address unverified claims explicitly (risk assessment)
4. Name concrete tier-1 sources where available
5. Connect quality insights to planning horizons where applicable
6. Use proper German Umlaute (ä, ö, ü, ß) if PROJECT_LANGUAGE=de

**Word count impact:** +250 words

**Verification:** Evidence Quality Analysis section present with 4 subsections, 250-300 words, quantitative data with interpretations.

---

## Step 4.8: Include Appendix Subsection C - Domain Concepts

**Action:** List relevant domain terminology using language-aware header as subsection C of appendix.

**Template (language-aware):**

```markdown
### C. {HEADER_DOMAIN_CONCEPTS}

{INTRO_DOMAIN_CONCEPTS}

- **{term}**: {definition}
- **{term}**: {definition}
...
```

**Header values by language:**

| Language | Header          |
|----------|-----------------|
| en       | Domain Concepts |
| de       | Fachbegriffe    |

**Intro text by language:**

| Language | Text                                |
|----------|-------------------------------------|
| en       | Key terms from this dimension:      |
| de       | Schlüsselbegriffe dieser Dimension: |

**Source:** CONCEPTS registry (5-10 terms)

**If no domain concepts loaded:** Skip this section.

**Verification:** 5-10 concepts included (if available), header in PROJECT_LANGUAGE.

---

## Step 4.9: Generate Appendix Subsection D - References Section

**Action:** Create reference list with dual citation format using language-aware headers as subsection D of appendix.

**Template (language-aware):**

```markdown
### D. {HEADER_REFERENCES}

**{HEADER_TRENDS}:**

[1] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[2] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
...

**{HEADER_SUPPORTING_CLAIMS}:**

[C1] [Claim Summary](10-claims/data/claim-slug.md) [[10-claims/data/claim-slug|Claim Title]] (confidence: 0.XX)
...
```

**Header values by language:**

| Language | References | Trends     | Supporting Claims             |
|----------|------------|--------------|-------------------------------|
| en       | References | Trends     | Supporting Claims             |
| de       | Referenzen | Erkenntnisse | Unterstützende Behauptungen   |

**Rules:**

1. Number citations sequentially as they appear in document
2. Include both markdown link and wikilink format
3. Group trends first, then claims
4. Include confidence scores for claims

**Verification:** All inline citations have matching reference entries, headers in PROJECT_LANGUAGE.

---

## Phase 4 Outputs

**Generic path (ARC_ID empty):**

- Complete synthesis document in memory with:
  - YAML frontmatter (with enhanced metrics)
  - Navigation header
  - Executive Summary (200-300 words)
  - Strategic Context (150-200 words)
  - Key Trends with planning horizon structure (450-650 words)
  - Cross-Trend Connections (150-200 words)
  - Related Dimensions (50-100 words, if applicable)
  - Related Megatrends (100-150 words, if applicable)
  - Implications & Recommendations with role-based framing (280-400 words)
  - **Appendix (H2 header)**
    - A. Evidence Assessment tables (4 tables)
    - B. Evidence Quality Analysis (250-300 words)
    - C. Domain Concepts (optional - skip if empty)
    - D. References section

**Arc path (ARC_ID set):**

- Complete synthesis document in memory with:
  - YAML frontmatter (with enhanced metrics + arc_id, arc_display_name, arc_elements)
  - Navigation header
  - Overview paragraph (100-150 words)
  - Arc Element 1 section (250-400 words)
  - Arc Element 2 section (200-350 words)
  - Arc Element 3 section (250-400 words)
  - Arc Element 4 section (150-250 words)
  - Related Dimensions (50-100 words, if applicable)
  - Related Megatrends (100-250 words, if applicable)
  - **Appendix (H2 header)** — unchanged from generic path
    - A. Evidence Assessment tables (4 tables)
    - B. Evidence Quality Analysis (250-300 words)
    - C. Domain Concepts (optional - skip if empty)
    - D. References section

- Main body target: 1,000-1,500 words (excludes appendix content) — both paths

---

## Word Count Tracking

Track word count after each section (excludes appendix):

| Section | Target | Running Total |
| ------- | ------ | ------------- |
| Executive Summary | 200-300 | ~250 |
| Strategic Context | 150-200 | ~425 |
| Key Trends (with horizons) | 450-650 | ~975 |
| Cross-Trend Connections | 150-200 | ~1150 |
| Related Dimensions | 50-100 | ~1200 |
| Related Megatrends | 100-150 | ~1325 |
| Implications | 280-400 | ~1650 |

**Appendix sections (excluded from word count):**
- Evidence Assessment tables
- Evidence Quality Analysis (250-300 words)
- Domain Concepts
- References

**If exceeding 1,500 words:** Tighten prose in Implications or Related Megatrends sections.

**If under 1,000 words:** Expand Key Trends section with more detail or add more megatrend connections.

---

## Error Responses

### Insufficient Citations

```json
{
  "success": false,
  "phase": 4,
  "step": "4.2",
  "error": "Insufficient citations in Executive Summary",
  "citations_found": 1,
  "minimum_required": 3,
  "remediation": "Add more evidence from loaded trends"
}
```

### Word Count Out of Range

```json
{
  "success": false,
  "phase": 4,
  "error": "Word count out of target range",
  "word_count": 650,
  "target_range": "800-1200",
  "remediation": "Expand Key Trends section"
}
```

---

## Transition to Phase 5

**Gate:** All 9 steps completed, document in memory.

**Mark Phase 4 todo as completed.**

**Proceed to:** [phase-5-validation.md](phase-5-validation.md)
