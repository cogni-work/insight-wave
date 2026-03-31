# Phase 3: Write Final Trend List

**Reference Checksum:** `sha256:trend-scout-p3-present-v2`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-3-present.md | Checksum: trend-scout-p3-present-v2
```

---

## Objective

Write the final trend list to `trend-candidates.md`. All generated candidates (variable count based on web signals) are the agreed list — no user selection step. After writing, proceed directly to Phase 4 (Finalize).

**Expected Duration:** 15-20 seconds (file writing)

---

## Entry Gate

Before proceeding, verify Phase 2 outputs:

- [ ] PROJECT_PATH set
- [ ] PROJECT_LANGUAGE set
- [ ] CANDIDATES_BY_CELL populated with web-grounded candidates (12-60)
- [ ] Generation metadata available

---

## Step 3.1: Initialize Presentation Phase

```bash
log_phase "Phase 3: Present Candidates" "start"
log_conditional INFO "Writing trend-candidates.md"
log_conditional INFO "Language: ${PROJECT_LANGUAGE}"
```

---

## Step 3.1.5: Prepare Data Files

Execute the data preparation script to generate compact candidate data:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/prepare-phase3-data.sh" "${PROJECT_PATH}"
```

This script:

1. Reads `.logs/trend-generator-candidates.json` (full ~27K tokens)
2. Writes `.logs/candidates-compact.json` (~8-10K tokens for Claude)

**Important:** From this point forward, read ONLY the compact file (`.logs/candidates-compact.json`).

**Field mapping for compact format:**

| Compact Key | Full Key | Description |
|-------------|----------|-------------|
| `d` | dimension | Dimension slug |
| `h` | horizon | Horizon (act/plan/observe) |
| `n` | name | Trend name |
| `s` | trend_statement | 30-50 word statement |
| `r` | research_hint | 20-30 word research guidance |
| `k` | keywords | Array of 3 keywords |
| `sc` | score | Composite score (0.0-1.0) |
| `ct` | confidence_tier | high/medium/low/uncertain |
| `si` | signal_intensity | Ansoff intensity (1-5) |
| `url` | source_url | Web source URL (always present) |

---

## Step 3.2: Build trend-candidates.md Content

### File Structure

```markdown
---
# Frontmatter
status: agreed
project_slug: "{PROJECT_SLUG}"
industry: "{INDUSTRY_SLUG}"
industry_en: "{INDUSTRY_EN}"
industry_de: "{INDUSTRY_DE}"
subsector: "{SUBSECTOR_SLUG}"
subsector_en: "{SUBSECTOR_EN}"
subsector_de: "{SUBSECTOR_DE}"
research_topic: "{RESEARCH_TOPIC}"
project_language: "{PROJECT_LANGUAGE}"
generated_at: "{ISO_TIMESTAMP}"
generated_by: "trend-scout"
total_candidates: {N}
web_research_status: "{success|partial}"
search_timestamp: "{ISO_TIMESTAMP}"
---

# TIPS Candidates / TIPS-Kandidaten

{HEADER_SECTION}

{DIMENSION_SECTIONS}

{SOURCE_INTEGRITY_SUMMARY}

{REFERENCES}
```

---

## Step 3.3: Generate Header Section

### English Header

```markdown
# TIPS Trend List for {SUBSECTOR_EN}

**Industry:** {INDUSTRY_EN}
**Subsector:** {SUBSECTOR_EN}
**Research Topic:** {RESEARCH_TOPIC}
**Generated:** {DATE}

This file contains {N} web-grounded trend candidates across 4 dimensions and 3 planning horizons (1-5 per cell based on available web research signals).
```

### German Header

```markdown
# TIPS-Trendliste für {SUBSECTOR_DE}

**Branche:** {INDUSTRY_DE}
**Teilsektor:** {SUBSECTOR_DE}
**Forschungsthema:** {RESEARCH_TOPIC}
**Generiert:** {DATE}

Diese Datei enthält {N} web-fundierte Trendkandidaten über 4 Dimensionen und 3 Planungshorizonte (1-5 pro Zelle basierend auf verfügbaren Web-Recherche-Signalen).
```

---

## Step 3.4: Generate Legend Section

### English Legend

```markdown
## Legend

- **Statement**: Trend statement (30-50 words) describing what is happening
- **Research**: Research hint (20-30 words) guiding downstream investigation
- **Score**: ★★★★★ (0.85) = Star rating + exact composite score (sorted by score)
- **Confidence**: ✓✓✓ = High, ✓✓○ = Medium, ✓○○ = Low, ?○○ = Uncertain
- **Intensity**: 1-5 (Ansoff signal level, 1=weak, 5=strong)
- **Source**: [n] = Web-sourced (see References)
```

### German Legend

```markdown
## Legende

- **Statement**: Trend-Statement (30-50 Wörter) beschreibt, was passiert
- **Forschung**: Forschungshinweis (20-30 Wörter) für die nachgelagerte Untersuchung
- **Score**: ★★★★★ (0.85) = Sternbewertung + exakter Composite-Score (nach Score sortiert)
- **Konfidenz**: ✓✓✓ = Hoch, ✓✓○ = Mittel, ✓○○ = Niedrig, ?○○ = Unsicher
- **Intensität**: 1-5 (Ansoff Signalstärke, 1=schwach, 5=stark)
- **Quelle**: [n] = Web-recherchiert (siehe Quellenverzeichnis)
```

---

## Step 3.4.1: Build Source Registry

Before generating tables, build a registry of unique sources for citation numbering.

### Algorithm

```text
SOURCES_REGISTRY = []  # List of {number, url, name}
citation_counter = 0

For each candidate in CANDIDATES_BY_CELL (in document order):
  If candidate.source_url exists:
    # Check if URL already registered
    existing = find_in_registry(candidate.source_url)

    If existing:
      candidate.citation = "[{existing.number}]"
    Else:
      citation_counter += 1
      SOURCES_REGISTRY.append({
        number: citation_counter,
        url: candidate.source_url,
        name: extract_domain_name(candidate.source_url)  # e.g., "VDMA", "EUR-Lex"
      })
      candidate.citation = "[{citation_counter}]"
```

### Helper: extract_domain_name

Extract readable source name from URL:
- `https://www.vdma.eu/...` → "VDMA"
- `https://eur-lex.europa.eu/...` → "EUR-Lex"
- `https://www.deloitte.com/...` → "Deloitte"
- `https://www.fraunhofer.de/...` → "Fraunhofer"

### Output

- `SOURCES_REGISTRY`: Used in Step 3.7.1 for References section
- Each candidate has `citation` field populated with `[n]` or `📚`

---

## Step 3.5: Generate Dimension Sections

For each dimension, generate:

### Dimension Header

**English:**
```markdown
---

## Dimension: {DIMENSION_EN}

**German:** {DIMENSION_DE}
**Focus:** {DIMENSION_FOCUS}
**TIPS Element:** {TIPS_ELEMENT}
```

**German:**
```markdown
---

## Dimension: {DIMENSION_DE}

**Englisch:** {DIMENSION_EN}
**Fokus:** {DIMENSION_FOCUS}
**TIPS-Element:** {TIPS_ELEMENT}
```

### Horizon Cards

For each horizon within dimension, generate candidate cards with rich details:

**English:**
```markdown
### Horizon: {HORIZON_NAME} ({HORIZON_TIMEFRAME})
*Sorted by score (highest first)*

---

#### 1. {name}
**Statement:** {trend_statement_30_50_words}
**Keywords:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Confidence:** {conf} | **Intensity:** {int}/5 | **Source:** {citation}

> **Research:** {research_hint_20_30_words_guiding_downstream_investigation}

---

#### 2. {name}
**Statement:** {trend_statement_30_50_words}
**Keywords:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Confidence:** {conf} | **Intensity:** {int}/5 | **Source:** {citation}

> **Research:** {research_hint_20_30_words_guiding_downstream_investigation}

---
... (repeat for all candidates in this cell)
```

**German:**

```markdown
### Horizont: {HORIZON_NAME} ({HORIZON_TIMEFRAME})
*Sortiert nach Score (höchster zuerst)*

---

#### 1. {name}
**Statement:** {trend_statement_30_50_wörter}
**Schlüsselwörter:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Konfidenz:** {conf} | **Intensität:** {int}/5 | **Quelle:** {citation}

> **Forschung:** {research_hint_20_30_wörter_für_nachgelagerte_untersuchung}

---

#### 2. {name}
**Statement:** {trend_statement_30_50_wörter}
**Schlüsselwörter:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Konfidenz:** {conf} | **Intensität:** {int}/5 | **Quelle:** {citation}

> **Forschung:** {research_hint_20_30_wörter_für_nachgelagerte_untersuchung}

---
... (repeat for all candidates in this cell)
```

### Trend Statement Requirements

Each candidate MUST include a `trend_statement` field (30-50 words) that describes:

1. **What is happening**: Observable trend, evidence, facts
2. **Context**: Industry relevance and scope
3. **Timeframe**: When this is occurring or will occur

**Example Statement (English):**
> EU AI Act mandates conformity assessments for high-risk AI systems in machinery, with August 2025 deadline creating immediate compliance pressure for manufacturers using AI-driven automation.

**Example Statement (German):**
> Der EU AI Act schreibt Konformitätsbewertungen für Hochrisiko-KI-Systeme in Maschinen vor, wobei die Frist im August 2025 sofortigen Compliance-Druck für Hersteller mit KI-gesteuerter Automatisierung erzeugt.

### Research Hint Requirements

Each candidate MUST include a `research_hint` field (20-30 words) that guides downstream investigation:

**Structure:** "Investigate [what to discover], [what evidence to find], [what outcomes matter]"

**Example Research Hint (English):**
> Investigate compliance pathways for high-risk AI classifications, implementation costs, and how leading DACH manufacturers are preparing.

**Example Research Hint (German):**
> Untersuchen Sie Compliance-Pfade für Hochrisiko-KI-Klassifizierungen, Implementierungskosten und wie führende DACH-Hersteller sich vorbereiten.

### Scoring Column Formats

| Column | Format | Example |
|--------|--------|---------|
| Rank | Position by score (1=highest) | 1, 2, 3, 4, 5 |
| Score | Star rating + numeric composite score | ★★★★☆ (0.72) |
| Conf | Confidence tier icon | ✓✓✓ (high) |
| Int | Ansoff intensity level | 4 |
| Source | [n] | [1] |

### Score-to-Stars Conversion

```text
0.80-1.00 → ★★★★★
0.60-0.79 → ★★★★☆
0.40-0.59 → ★★★☆☆
0.20-0.39 → ★★☆☆☆
0.00-0.19 → ★☆☆☆☆
```

### Confidence Tier Icons

```text
high     → ✓✓✓
medium   → ✓✓○
low      → ✓○○
uncertain → ?○○
```

### Sorting Rule

**Sort candidates within each cell by score (descending)** so users see highest-scored candidates first.

### Dimension Focus Descriptions

| Dimension | English Focus | German Focus | TIPS |
|-----------|---------------|--------------|------|
| externe-effekte | External forces: regulations, market dynamics, competitive pressure | Externe Kräfte: Regulierung, Marktdynamik, Wettbewerbsdruck | T |
| neue-horizonte | Strategic opportunities: new business models, market expansion | Strategische Chancen: neue Geschäftsmodelle, Markterweiterung | P |
| digitale-wertetreiber | Value creation: customer experience, operational excellence | Wertschöpfung: Kundenerfahrung, operative Exzellenz | I |
| digitales-fundament | Foundation: infrastructure, skills, data, security | Fundament: Infrastruktur, Kompetenzen, Daten, Sicherheit | S |

### Horizon Labels

| Horizon | English | German |
|---------|---------|--------|
| act | Act (0-2 years) | Handeln (0-2 Jahre) |
| plan | Plan (2-5 years) | Planen (2-5 Jahre) |
| observe | Observe (5+ years) | Beobachten (5+ Jahre) |

---

## Step 3.6: Generate Source Coverage Summary

```markdown
---

## Source Coverage

| Metric | Value |
|--------|-------|
| Total candidates | {N} |
| Unique web sources | {N} |
| Cells with candidates | {N}/12 |
| Average score | {score} |
| Average confidence | {high/medium/low distribution} |

*All candidates are grounded in web research signals with verifiable source URLs.*
```

---

## Step 3.7.1: Generate References Section

After the selection summary, generate a numbered references section listing all web sources.

### English

```markdown
---

## References

The following sources were used for web-sourced candidates:

| # | Source | URL |
|---|--------|-----|
| 1 | {source_name_1} | [{title_1}]({url_1}) |
| 2 | {source_name_2} | [{title_2}]({url_2}) |
...

```

### German

```markdown
---

## Quellenverzeichnis

Folgende Quellen wurden für die Trendkandidaten verwendet:

| Nr. | Quelle | URL |
|-----|--------|-----|
| 1 | {source_name_1} | [{title_1}]({url_1}) |
| 2 | {source_name_2} | [{title_2}]({url_2}) |
...
```

### Citation Format Rules

1. **Unique numbering**: Each unique `source_url` gets exactly one number
2. **Deduplication**: If multiple candidates share the same source, they share the citation number
3. **Order**: Sources numbered in order of first appearance in the document

---

## Step 3.8: Write File

```bash
# Write to project root (simplified structure)
TIPS_CANDIDATES_FILE="${PROJECT_PATH}/trend-candidates.md"

# Write file
echo "$TIPS_CANDIDATES_CONTENT" > "$TIPS_CANDIDATES_FILE"

log_conditional INFO "Written trend-candidates.md to: $TIPS_CANDIDATES_FILE"
```

---

## Success Criteria

- [ ] trend-candidates.md written to correct location
- [ ] File contains all web-grounded candidates organized by dimension/horizon
- [ ] All candidates have source URLs
- [ ] File uses correct language (EN or DE)
- [ ] Frontmatter status set to `agreed`

---

## Variables Set

| Variable | Description | Example |
|----------|-------------|---------|
| TIPS_CANDIDATES_FILE | Path to generated file | `${PROJECT_PATH}/trend-candidates.md` |

---

## Next Phase

Proceed directly to [phase-4-finalize.md](phase-4-finalize.md).
