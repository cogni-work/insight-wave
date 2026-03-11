# Phase 3: Present Candidates

**Reference Checksum:** `sha256:trend-scout-p3-present-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-3-present.md | Checksum: trend-scout-p3-present-v1
```

---

## Objective

Write the generated candidates to `trend-candidates.md` for user review and selection, then PAUSE execution for user interaction.

**Expected Duration:** 15-20 seconds (file writing) + user interaction time

---

## Entry Gate

Before proceeding, verify Phase 2 outputs:

- [ ] PROJECT_PATH set
- [ ] PROJECT_LANGUAGE set
- [ ] CANDIDATES_BY_CELL populated with 60 candidates
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

Execute the data preparation script to generate compact candidate data and browser app JSON:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/prepare-phase3-data.sh" "${PROJECT_PATH}"
```

This script:

1. Reads `.logs/trend-generator-candidates.json` (full ~27K tokens)
2. Writes `trend-app-data.json` to project root (full data for browser selector)
3. Writes `trend-selector-app.html` to project root (self-contained HTML with embedded data, works with `file://` protocol)
4. Writes `.logs/candidates-compact.json` (~8-10K tokens for Claude)

**Important:** From this point forward, read ONLY the compact file (`.logs/candidates-compact.json`). The full data is preserved in `trend-app-data.json` and embedded in the HTML for the visual selector app.

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
| `src` | source | web-signal or training |
| `url` | source_url | URL if web-sourced |

---

## Step 3.2: Build trend-candidates.md Content

### File Structure

```markdown
---
# Frontmatter
status: draft
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
total_candidates: 60
selected_count: 0
web_research_status: "{success|partial|failed|disabled}"
web_sourced_candidates: {N}
training_sourced_candidates: {N}
search_timestamp: "{ISO_TIMESTAMP}"
---

# TIPS Candidates / TIPS-Kandidaten

{HEADER_SECTION}

{INSTRUCTIONS_SECTION}

{DIMENSION_SECTIONS}

{USER_PROPOSED_SECTION}

{SELECTION_SUMMARY}
```

---

## Step 3.3: Generate Header Section

### English Header

```markdown
# TIPS Candidates for {SUBSECTOR_EN}

**Industry:** {INDUSTRY_EN}
**Subsector:** {SUBSECTOR_EN}
**Research Topic:** {RESEARCH_TOPIC}
**Generated:** {DATE}

This file contains 76 trend candidates across 4 dimensions and 3 planning horizons.
Please select **5 ACT, 5 PLAN, and 3 OBSERVE per dimension** (52 total) to proceed.
```

### German Header

```markdown
# TIPS-Kandidaten für {SUBSECTOR_DE}

**Branche:** {INDUSTRY_DE}
**Teilsektor:** {SUBSECTOR_DE}
**Forschungsthema:** {RESEARCH_TOPIC}
**Generiert:** {DATE}

Diese Datei enthält 76 Trendkandidaten über 4 Dimensionen und 3 Planungshorizonte.
Bitte wählen Sie **5 ACT, 5 PLAN und 3 OBSERVE pro Dimension** (52 insgesamt) aus, um fortzufahren.
```

---

## Step 3.4: Generate Instructions Section

### English Instructions

```markdown
## Instructions

1. **Review** each candidate in the tables below
2. **Select** candidates per horizon (5 ACT, 5 PLAN, 3 OBSERVE per dimension) by changing `[ ]` to `[x]`
3. **Add proposals** (optional) in the "User Proposed" section at the bottom
4. **Request more** (optional) by adding `[+N]` in the "More?" column (e.g., `[+3]` for 3 more)
5. **Save** this file and re-invoke the `trend-scout` skill

### Selection Requirements

| Requirement | Value |
|-------------|-------|
| ACT per dimension | 5 |
| PLAN per dimension | 5 |
| OBSERVE per dimension | 3 |
| Total selections | 52 (13 × 4 dimensions) |

### Legend

- `#### [ ]` = Not selected (change to `#### [x]` to select)
- `#### [x]` = Selected
- **Statement**: Trend statement (30-50 words) describing what is happening
- **Research**: Research hint (20-30 words) guiding downstream investigation
- **Score**: ★★★★★ (0.85) = Star rating + exact composite score (sorted by score)
- **Confidence**: ✓✓✓ = High, ✓✓○ = Medium, ✓○○ = Low, ?○○ = Uncertain
- **Intensity**: 1-5 (Ansoff signal level, 1=weak, 5=strong)
- **Source**: [n] = Numbered citation (see References section), 📚 = Training knowledge
```

### German Instructions

```markdown
## Anleitung

1. **Prüfen** Sie jeden Kandidaten in den untenstehenden Tabellen
2. **Wählen** Sie Kandidaten pro Horizont (5 ACT, 5 PLAN, 3 OBSERVE pro Dimension), indem Sie `[ ]` zu `[x]` ändern
3. **Eigene Vorschläge** (optional) im Abschnitt "Eigene Vorschläge" am Ende hinzufügen
4. **Mehr anfordern** (optional) durch Hinzufügen von `[+N]` in der Spalte "Mehr?" (z.B. `[+3]` für 3 weitere)
5. **Speichern** Sie diese Datei und rufen Sie das `trend-scout` Skill erneut auf

### Auswahlvoraussetzungen

| Anforderung | Wert |
|-------------|------|
| ACT pro Dimension | 5 |
| PLAN pro Dimension | 5 |
| OBSERVE pro Dimension | 3 |
| Gesamtauswahl | 52 (13 × 4 Dimensionen) |

### Legende

- `#### [ ]` = Nicht ausgewählt (ändern zu `#### [x]` zum Auswählen)
- `#### [x]` = Ausgewählt
- **Statement**: Trend-Statement (30-50 Wörter) beschreibt, was passiert
- **Forschung**: Forschungshinweis (20-30 Wörter) für die nachgelagerte Untersuchung
- **Score**: ★★★★★ (0.85) = Sternbewertung + exakter Composite-Score (nach Score sortiert)
- **Konfidenz**: ✓✓✓ = Hoch, ✓✓○ = Mittel, ✓○○ = Niedrig, ?○○ = Unsicher
- **Intensität**: 1-5 (Ansoff Signalstärke, 1=schwach, 5=stark)
- **Quelle**: [n] = Nummerierte Zitation (siehe Quellenverzeichnis), 📚 = Trainingswissen
```

---

## Step 3.4.1: Build Source Registry

Before generating tables, build a registry of unique sources for citation numbering.

### Algorithm

```text
SOURCES_REGISTRY = []  # List of {number, url, name}
citation_counter = 0

For each candidate in CANDIDATES_BY_CELL (in document order):
  If candidate.source == "web-signal" AND candidate.source_url exists:
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

  Else if candidate.source == "training":
    candidate.citation = "📚"
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
*Sorted by score (highest first) — Select exactly 3 candidates*

---

#### [ ] 1. {name}
**Statement:** {trend_statement_30_50_words}
**Keywords:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Confidence:** {conf} | **Intensity:** {int}/5 | **Source:** {citation}

> **Research:** {research_hint_20_30_words_guiding_downstream_investigation}

---

#### [ ] 2. {name}
**Statement:** {trend_statement_30_50_words}
**Keywords:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Confidence:** {conf} | **Intensity:** {int}/5 | **Source:** {citation}

> **Research:** {research_hint_20_30_words_guiding_downstream_investigation}

---
... (repeat for all 5 candidates)
```

**German:**

```markdown
### Horizont: {HORIZON_NAME} ({HORIZON_TIMEFRAME})
*Sortiert nach Score (höchster zuerst) — Wählen Sie genau 3 Kandidaten*

---

#### [ ] 1. {name}
**Statement:** {trend_statement_30_50_wörter}
**Schlüsselwörter:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Konfidenz:** {conf} | **Intensität:** {int}/5 | **Quelle:** {citation}

> **Forschung:** {research_hint_20_30_wörter_für_nachgelagerte_untersuchung}

---

#### [ ] 2. {name}
**Statement:** {trend_statement_30_50_wörter}
**Schlüsselwörter:** `{kw1}` `{kw2}` `{kw3}`
**Score:** {stars} ({score}) | **Konfidenz:** {conf} | **Intensität:** {int}/5 | **Quelle:** {citation}

> **Forschung:** {research_hint_20_30_wörter_für_nachgelagerte_untersuchung}

---
... (repeat for all 5 candidates)
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
| Source | [n] or 📚 | [1] |

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

## Step 3.6: Generate User Proposed Section

### English

```markdown
---

## User Proposed Candidates

Add your own trend candidates below. Follow the format in the table.

| Select | Dimension | Horizon | Name | Description | Keywords | Rationale |
|--------|-----------|---------|------|-------------|----------|-----------|
| [x] | | | | | | |
| [x] | | | | | | |
| [x] | | | | | | |

**Instructions:**
- Fill in dimension: `externe-effekte`, `neue-horizonte`, `digitale-wertetreiber`, or `digitales-fundament`
- Fill in horizon: `act`, `plan`, or `observe`
- Provide name (1-2 words), description (1 sentence), 3 keywords (comma-separated), and rationale
- User-proposed candidates are automatically selected (`[x]`)
```

### German

```markdown
---

## Eigene Vorschläge

Fügen Sie unten Ihre eigenen Trendkandidaten hinzu. Folgen Sie dem Format in der Tabelle.

| Auswahl | Dimension | Horizont | Name | Beschreibung | Schlüsselwörter | Begründung |
|---------|-----------|----------|------|--------------|-----------------|------------|
| [x] | | | | | | |
| [x] | | | | | | |
| [x] | | | | | | |

**Anleitung:**
- Dimension ausfüllen: `externe-effekte`, `neue-horizonte`, `digitale-wertetreiber`, oder `digitales-fundament`
- Horizont ausfüllen: `act`, `plan`, oder `observe`
- Name (1-2 Wörter), Beschreibung (1 Satz), 3 Schlüsselwörter (kommagetrennt) und Begründung angeben
- Eigene Vorschläge sind automatisch ausgewählt (`[x]`)
```

---

## Step 3.7: Generate Selection Summary

```markdown
---

## Selection Summary

| Dimension | Act | Plan | Observe | Total |
|-----------|-----|------|---------|-------|
| Externe Effekte | 0/5 | 0/5 | 0/3 | 0/13 |
| Neue Horizonte | 0/5 | 0/5 | 0/3 | 0/13 |
| Digitale Wertetreiber | 0/5 | 0/5 | 0/3 | 0/13 |
| Digitales Fundament | 0/5 | 0/5 | 0/3 | 0/13 |
| **Total** | **0/20** | **0/20** | **0/12** | **0/52** |

*This summary updates automatically when you re-invoke trend-scout.*
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

*📚 = Training knowledge (no external source)*
```

### German

```markdown
---

## Quellenverzeichnis

Folgende Quellen wurden für die Web-recherchierten Kandidaten verwendet:

| Nr. | Quelle | URL |
|-----|--------|-----|
| 1 | {source_name_1} | [{title_1}]({url_1}) |
| 2 | {source_name_2} | [{title_2}]({url_2}) |
...

*📚 = Trainingswissen (keine externe Quelle)*
```

### Citation Format Rules

1. **Unique numbering**: Each unique `source_url` gets exactly one number
2. **Deduplication**: If multiple candidates share the same source, they share the citation number
3. **Order**: Sources numbered in order of first appearance in the document
4. **Display**: In tables, web-sourced candidates show `[n]`, training shows `📚`

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

## Step 3.8.1: Verify Visual Selector App Data

**Note:** The `trend-app-data.json` file is generated by the `prepare-phase3-data.sh` script in Step 3.1.5. This step verifies the file exists.

### Verification

```bash
TREND_APP_DATA_FILE="${PROJECT_PATH}/trend-app-data.json"

if [[ -f "$TREND_APP_DATA_FILE" ]]; then
    log_conditional INFO "trend-app-data.json exists at: $TREND_APP_DATA_FILE"
else
    log_conditional ERROR "trend-app-data.json missing - Step 3.1.5 may have failed"
fi
```

### JSON Schema Reference

The generated `trend-app-data.json` contains:

```json
{
  "meta": {
    "timestamp": "{ISO_TIMESTAMP}",
    "subsector": "{SUBSECTOR_SLUG}",
    "total_candidates": 76,
    "source_distribution": {"web_signal": N, "training": N}
  },
  "sources": {
    "1": {"url": "{url_1}"},
    "2": {"url": "{url_2}"}
  },
  "candidates": [
    {
      "id": "{dim}-{horizon}-{seq}",
      "dimension": "{dimension_slug}",
      "dimension_key": "{t|p|i|s}",
      "horizon": "{act|plan|observe}",
      "trend_name": "{name}",
      "trend_statement": "{30_50_word_statement}",
      "research_hint": "{20_30_word_guidance}",
      "keywords": ["{kw1}", "{kw2}", "{kw3}"],
      "score": 0.82,
      "confidence_tier": "{high|medium|low|uncertain}",
      "signal_intensity": 4,
      "source": "{web-signal|training}",
      "source_url": "{url_if_web}"
    }
  ]
}
```

### Dimension Key Mapping

| Dimension Slug | Key |
|----------------|-----|
| externe-effekte | t |
| neue-horizonte | p |
| digitale-wertetreiber | i |
| digitales-fundament | s |

---

## Step 3.8.2: Open Visual Selector App in Browser

The Visual Selector HTML was generated by `prepare-phase3-data.sh` in Step 3.1.5 with embedded JSON data. This self-contained file works with the `file://` protocol (no CORS issues).

**MANDATORY: Execute this Bash command:**

```bash
SELECTOR_APP="${PROJECT_PATH}/trend-selector-app.html"

# Verify the app was generated
if [ -f "$SELECTOR_APP" ]; then
  # Auto-open the selector app in default browser
  open "$SELECTOR_APP"
  echo "Opened trend-selector-app.html in browser"
else
  echo "ERROR: trend-selector-app.html not found - ensure Step 3.1.5 completed successfully"
fi
```

**Note:** The HTML file includes embedded project data, so it works when opened directly via `file://` protocol without needing a local HTTP server.

---

## Step 3.9: Output User Instructions

After writing the file, output instructions based on PROJECT_LANGUAGE:

### English Output

```text
## Action Required: Review and Select Candidates

I've generated 60 trend candidates for {SUBSECTOR_EN}.

### Trend Selector App

**Open the interactive selector:** [{PROJECT_PATH}/trend-selector-app.html]({PROJECT_PATH}/trend-selector-app.html)

The app provides:
- Visual matrix of all 4 dimensions × 3 horizons
- Hover-to-expand detailed descriptions
- Progress tracking with selection counter
- Export to JSON (for Phase 4)

After making selections, click **Export** and save `trend-selection.json` to your project folder.

### Option B: Edit Markdown Directly

**File:** [{PROJECT_PATH}/trend-candidates.md]({PROJECT_PATH}/trend-candidates.md)

1. Open the file above
2. Mark exactly 3 candidates per cell with `[x]`
3. Optionally add your own proposals at the bottom
4. Save the file

---

**Selection requirements:**
- 5 ACT, 5 PLAN, 3 OBSERVE per dimension
- 52 total selections

When you're ready, re-invoke the `trend-scout` skill to continue.
```

### German Output

```text
## Aktion erforderlich: Kandidaten prüfen und auswählen

Ich habe 60 Trendkandidaten für {SUBSECTOR_DE} generiert.

### Trend Selector App

**Interaktiven Selektor öffnen:** [{PROJECT_PATH}/trend-selector-app.html]({PROJECT_PATH}/trend-selector-app.html)

Die App bietet:
- Visuelle Matrix aller 4 Dimensionen × 3 Horizonte
- Detailansicht beim Hover über Kandidaten
- Fortschrittsanzeige mit Auswahlzähler
- Export nach JSON (für Phase 4)

Nach der Auswahl klicken Sie auf **Export** und speichern `trend-selection.json` in Ihrem Projektordner.

### Option B: Markdown direkt bearbeiten

**Datei:** [{PROJECT_PATH}/trend-candidates.md]({PROJECT_PATH}/trend-candidates.md)

1. Öffnen Sie die obige Datei
2. Markieren Sie genau 3 Kandidaten pro Zelle mit `[x]`
3. Fügen Sie optional eigene Vorschläge am Ende hinzu
4. Speichern Sie die Datei

---

**Auswahlvoraussetzungen:**
- 5 ACT, 5 PLAN, 3 OBSERVE pro Dimension
- 52 Auswahlen insgesamt

Wenn Sie bereit sind, rufen Sie das `trend-scout` Skill erneut auf, um fortzufahren.
```

---

## Step 3.10: PAUSE Execution

**CRITICAL:** After outputting instructions, STOP execution. Do not proceed to Phase 4.

```bash
log_phase "Phase 3: Present Candidates" "complete"
log_conditional INFO "PAUSED - Waiting for user to edit trend-candidates.md"

# Exit gracefully - user will re-invoke when ready
exit 0
```

---

## Success Criteria

- [ ] trend-candidates.md written to correct location
- [ ] File contains all 60 candidates organized by dimension/horizon
- [ ] File uses correct language (EN or DE)
- [ ] User instructions displayed
- [ ] Execution paused for user interaction

---

## Variables Set

| Variable | Description | Example |
|----------|-------------|---------|
| TIPS_CANDIDATES_FILE | Path to generated file | `${PROJECT_PATH}/trend-candidates.md` |

---

## Next Phase

User edits file, then re-invokes trend-scout. Proceed to [phase-4-process.md](phase-4-process.md).
