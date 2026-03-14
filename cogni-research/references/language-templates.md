# Language Templates

Localized header strings for entity generation across the 7-type entity pipeline.

## Language Detection

1. If `--language` provided: Validate ISO 639-1 format (2-letter lowercase), must be `en` or `de`
2. If not provided: Detect from project metadata (`.metadata/project-config.json`)
3. Fallback: Sample 3 source files for majority language
4. Default: `en`

## Supported Languages

- `en` - English (default)
- `de` - German (Deutsch)

## Localization Rules

### Keep in English

These terms remain English regardless of project language:

- **Framework names:** TIPS, MECE, SWOT, McKinsey Pyramid, Lean Canvas, Gartner Hype Cycle
- **Dublin Core metadata:** dc:*, tags, entity_type, all YAML frontmatter keys
- **Confidence/Quality terms:** High Confidence, Tier 1/2/3/4, reliability labels
- **Entity identifiers:** All IDs, slugs, and filenames use ASCII transliteration

### Localize to Project Language

- Section headings (## Context → ## Kontext)
- Content labels and descriptions
- Navigation text and instructions

## Header Variables by Entity Type

### Hub Report (synthesis output)

Headers for cross-dimensional synthesis report (research-hub.md).

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_EXECUTIVE_SUMMARY` | Executive Summary | Zusammenfassung |
| `HEADER_RESEARCH_QUESTION` | Research Question | Forschungsfrage |
| `HEADER_OVERARCHING_THEMES` | Overarching Themes | Übergreifende Themen |
| `HEADER_RESEARCH_DIMENSIONS` | Research Dimensions | Forschungsdimensionen |
| `HEADER_CROSS_DIMENSIONAL_PATTERNS` | Cross-Dimensional Patterns | Dimensionsübergreifende Muster |
| `HEADER_REINFORCING_FINDINGS` | Reinforcing Findings | Verstärkende Ergebnisse |
| `HEADER_TENSIONS_TRADEOFFS` | Tensions and Trade-offs | Spannungen und Zielkonflikte |
| `HEADER_EMERGENT_IMPLICATIONS` | Emergent Implications | Emergente Implikationen |
| `HEADER_STRATEGIC_RECOMMENDATIONS` | Strategic Recommendations | Strategische Empfehlungen |
| `HEADER_APPENDIX_SCOPE` | Appendix: Research Scope | Anhang: Forschungsumfang |
| `HEADER_REPORT_GENERATION` | Report Generation | Berichtserstellung |
| `HEADER_DETAILED_METHODOLOGY` | For Detailed Methodology | Zur detaillierten Methodik |
| `LABEL_PRIORITY` | Priority | Priorität |
| `LABEL_DIMENSIONS_ADDRESSED` | Dimensions Addressed | Adressierte Dimensionen |
| `LABEL_DEPENDENCIES` | Dependencies | Abhängigkeiten |
| `VALUE_HIGH` | High | Hoch |
| `VALUE_MEDIUM` | Medium | Mittel |
| `VALUE_LOW` | Low | Niedrig |
| `LINK_FULL_ANALYSIS` | Full Analysis | Vollständige Analyse |
| `LINK_DEEP_DIVE` | Deep Dive | Tiefere Analyse |
| `LABEL_GENERAL` | General | Allgemein |

**Research Pipeline Metrics:**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_FULL_PIPELINE_METRICS` | Research Pipeline Metrics | Forschungspipeline-Metriken |
| `MSG_PIPELINE_INTRO` | This research synthesized evidence through a 7-type entity pipeline: | Diese Forschung synthetisierte Evidenz durch eine 7-Typ-Entitätspipeline: |
| `LABEL_PHASE` | Phase | Phase |
| `LABEL_ENTITY_TYPE` | Entity Type | Entitätstyp |
| `LABEL_GENERATED` | Generated | Generiert |
| `LABEL_USED_IN_REPORT` | Used in Report | Im Bericht verwendet |
| `LABEL_PIPELINE_SUMMARY` | Pipeline Summary | Pipeline-Zusammenfassung |
| `LABEL_TOTAL_ENTITIES_GENERATED` | Total Entities Generated | Generierte Entitäten insgesamt |
| `LABEL_ENTITIES_CITED_IN_REPORT` | Entities Cited in Report | Im Bericht zitierte Entitäten |
| `LABEL_OVERALL_COVERAGE` | Overall Coverage | Gesamtabdeckung |
| `ENTITY_INITIAL_QUESTION` | Initial Question | Ausgangsfrage |
| `ENTITY_REFINED_QUESTIONS` | Refined Questions | Verfeinerte Fragen |
| `ENTITY_QUERY_BATCHES` | Query Batches | Suchanfrage-Batches |
| `ENTITY_FINDINGS` | Findings | Ergebnisse |
| `ENTITY_SOURCES` | Sources | Quellen |
| `ENTITY_CLAIMS` | Claims | Belege |

### 06-claims

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CLAIM` | Claim | Behauptung |
| `HEADER_JUSTIFICATION` | Justification | Begründung |
| `HEADER_EVIDENCE` | Evidence | Beweise |
| `HEADER_CONFIDENCE` | Confidence Breakdown | Konfidenz-Aufschlüsselung |
| `HEADER_PROVENANCE` | Provenance (Audit Trail) | Provenienz (Audit-Pfad) |
| `HEADER_RELEVANCE` | Relevance | Relevanz |

### 05-sources

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_SOURCE` | Source | Quelle |
| `HEADER_RELIABILITY` | Reliability | Zuverlässigkeit |
| `HEADER_ACCESS_DATE` | Access Date | Zugriffsdatum |
| `HEADER_CONTENT_SUMMARY` | Content Summary | Inhaltszusammenfassung |
| `HEADER_KEY_CLAIMS` | Key Claims | Kernaussagen |

### 04-findings

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_SUMMARY` | Summary | Zusammenfassung |
| `HEADER_CONTENT` | Content | Inhalt |
| `HEADER_KEY_TRENDS` | Key Trends | Kernerkenntnisse |
| `HEADER_SOURCE` | Source | Quelle |
| `HEADER_EVIDENCE_QUALITY` | Evidence Quality | Evidenzqualität |
| `HEADER_METHODOLOGY` | Methodology & Data Points | Methodik & Datenpunkte |
| `HEADER_RELEVANCE_ASSESSMENT` | Relevance Assessment | Relevanz-Bewertung |

### 03-query-batches

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_QUERIES` | Queries | Suchanfragen |
| `HEADER_STRATEGY` | Search Strategy | Suchstrategie |

### 02-refined-questions

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_QUESTION` | Question | Frage |
| `HEADER_CONTEXT` | Context | Kontext |
| `HEADER_SCOPE` | Scope | Umfang |
| `HEADER_RATIONALE` | Rationale | Begründung |

### 01-research-dimensions

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_OVERVIEW` | Overview | Übersicht |
| `HEADER_RESEARCH_QUESTIONS` | Research Questions | Forschungsfragen |
| `HEADER_KEY_THEMES` | Key Themes | Kernthemen |
| `HEADER_SCOPE` | Scope | Umfang |
| `HEADER_BOUNDARIES` | Boundaries | Abgrenzungen |

### 00-initial-question

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_RESEARCH_QUESTION` | Research Question | Forschungsfrage |
| `HEADER_CONTEXT` | Context | Kontext |
| `HEADER_SCOPE` | Scope | Umfang |
| `HEADER_RESEARCH_TYPE` | Research Type | Forschungstyp |
| `HEADER_OBJECTIVES` | Objectives | Ziele |

## German Text Formatting

When generating content in German (`language: "de"`):

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Section headings | Proper umlauts | "Begründung" NOT "Begrundung" |
| Explanations | Proper umlauts | "für" NOT "fuer", "müssen" NOT "muessen" |
| File names/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

**Correct:**

```markdown
## Kontext

Die IT-OT-Transformation bei DB Systel findet in einem komplexen arbeitsrechtlichen Rahmen statt,
der bei Betriebsänderungen umfangreiche Mitbestimmungsrechte auslöst.
```

**Incorrect (ASCII fallback):**

```markdown
## Context

Die IT-OT-Transformation bei DB Systel findet in einem komplexen arbeitsrechtlichen Rahmen statt,
der bei Betriebsaenderungen umfangreiche Mitbestimmungsrechte ausloest.
```

## Usage in Entity Generation

### Template Pattern

Use header variables in entity templates:

```markdown
## {HEADER_CONTEXT}

{context_content}

## {HEADER_EVIDENCE}

{evidence_content}
```

### Frontmatter

Always include language field:

```yaml
language: {LANGUAGE}
```

### Language Detection in Skills

```bash
# Check project config
LANGUAGE=$(jq -r '.project_language // "en"' "${PROJECT_PATH}/.metadata/project-config.json" 2>/dev/null || echo "en")

# Validate
if [[ ! "$LANGUAGE" =~ ^(en|de)$ ]]; then
  LANGUAGE="en"
fi
```

## Error Response

Invalid language code returns:

```json
{
  "success": false,
  "error": "Invalid language code 'fr'. Supported: en, de (ISO 639-1 format)",
  ...
}
```
