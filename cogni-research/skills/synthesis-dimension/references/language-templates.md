# Language Templates

Localized header strings for dimension synthesis document generation based on project language.

## Language Detection

1. If `PROJECT_LANGUAGE` already set: Use as-is
2. Read from `.metadata/sprint-log.json` field `project_language`
3. Fallback: Detect from trend frontmatter `language` field
4. Default: `en`

## Supported Languages

### English (en)

| Variable | Value |
|----------|-------|
| `HEADER_EXECUTIVE_SUMMARY` | Executive Summary |
| `HEADER_STRATEGIC_CONTEXT` | Strategic Context |
| `HEADER_KEY_TRENDS` | Key Trends |
| `HEADER_CROSS_CONNECTIONS` | Cross-Trend Connections |
| `HEADER_RELATED_DIMENSIONS` | Related Dimensions |
| `HEADER_IMPLICATIONS` | Implications & Recommendations |
| `HEADER_STRATEGIC_IMPLICATIONS` | Strategic Implications |
| `HEADER_TACTICAL_RECOMMENDATIONS` | Tactical Recommendations |
| `HEADER_EVIDENCE_ASSESSMENT` | Evidence Assessment |
| `HEADER_DOMAIN_CONCEPTS` | Domain Concepts |
| `HEADER_REFERENCES` | References |
| `HEADER_APPENDIX` | Appendix |
| `HEADER_TRENDS` | Trends |
| `HEADER_SUPPORTING_CLAIMS` | Supporting Claims |
| `LABEL_NAVIGATION` | Navigation |
| `LABEL_CURRENT` | Current |
| `LABEL_BACK_TO_OVERVIEW` | Back to Research Report Overview |
| `LANGUAGE_NAME` | English |

### German (de)

| Variable | Value |
|----------|-------|
| `HEADER_EXECUTIVE_SUMMARY` | Zusammenfassung |
| `HEADER_STRATEGIC_CONTEXT` | Strategischer Kontext |
| `HEADER_KEY_TRENDS` | Kernerkenntnisse |
| `HEADER_CROSS_CONNECTIONS` | Erkenntnisverknüpfungen |
| `HEADER_RELATED_DIMENSIONS` | Verwandte Dimensionen |
| `HEADER_IMPLICATIONS` | Implikationen & Empfehlungen |
| `HEADER_STRATEGIC_IMPLICATIONS` | Strategische Implikationen |
| `HEADER_TACTICAL_RECOMMENDATIONS` | Taktische Empfehlungen |
| `HEADER_EVIDENCE_ASSESSMENT` | Evidenzbewertung |
| `HEADER_DOMAIN_CONCEPTS` | Fachbegriffe |
| `HEADER_REFERENCES` | Referenzen |
| `HEADER_APPENDIX` | Anhang |
| `HEADER_TRENDS` | Erkenntnisse |
| `HEADER_SUPPORTING_CLAIMS` | Unterstützende Behauptungen |
| `LABEL_NAVIGATION` | Navigation |
| `LABEL_CURRENT` | Aktuell |
| `LABEL_BACK_TO_OVERVIEW` | Zurück zur Forschungsbericht-Übersicht |
| `LANGUAGE_NAME` | German |

## Arc Element Section Headers

Arc-specific headers used when `ARC_ID` is set. Loaded from the corresponding arc template, provided here as a consolidated reference.

### Corporate Visions (`corporate-visions`)

| Variable | English (en) | German (de) |
|----------|-------------|-------------|
| `ARC_HEADER_ELEMENT_1` | Why Change | Warum Verändern |
| `ARC_HEADER_ELEMENT_2` | Why Now | Warum Jetzt |
| `ARC_HEADER_ELEMENT_3` | Why You | Warum Sie |
| `ARC_HEADER_ELEMENT_4` | Why Pay | Warum Investieren |

### Technology Futures (`technology-futures`)

| Variable | English (en) | German (de) |
|----------|-------------|-------------|
| `ARC_HEADER_ELEMENT_1` | What's Emerging | Was Entsteht |
| `ARC_HEADER_ELEMENT_2` | What's Converging | Was Konvergiert |
| `ARC_HEADER_ELEMENT_3` | What's Possible | Was Wird Möglich |
| `ARC_HEADER_ELEMENT_4` | What's Required | Was Wird Benötigt |

### Competitive Intelligence (`competitive-intelligence`)

| Variable | English (en) | German (de) |
|----------|-------------|-------------|
| `ARC_HEADER_ELEMENT_1` | Landscape | Wettbewerbslandschaft |
| `ARC_HEADER_ELEMENT_2` | Shifts | Marktverschiebungen |
| `ARC_HEADER_ELEMENT_3` | Positioning | Positionierung |
| `ARC_HEADER_ELEMENT_4` | Implications | Implikationen |

### Strategic Foresight (`strategic-foresight`)

| Variable | English (en) | German (de) |
|----------|-------------|-------------|
| `ARC_HEADER_ELEMENT_1` | Signals | Signale |
| `ARC_HEADER_ELEMENT_2` | Scenarios | Szenarien |
| `ARC_HEADER_ELEMENT_3` | Strategies | Strategien |
| `ARC_HEADER_ELEMENT_4` | Decisions | Entscheidungen |

### Industry Transformation (`industry-transformation`)

| Variable | English (en) | German (de) |
|----------|-------------|-------------|
| `ARC_HEADER_ELEMENT_1` | Forces | Treibende Kräfte |
| `ARC_HEADER_ELEMENT_2` | Friction | Widerstände |
| `ARC_HEADER_ELEMENT_3` | Evolution | Evolutionspfad |
| `ARC_HEADER_ELEMENT_4` | Leadership | Führungsanforderungen |

### Arc Header Usage

When ARC_ID is set, use `ARC_HEADER_ELEMENT_N` variables for the 4 main body H2 sections instead of the generic headers (`HEADER_EXECUTIVE_SUMMARY`, `HEADER_STRATEGIC_CONTEXT`, `HEADER_KEY_TRENDS`, `HEADER_CROSS_CONNECTIONS`, `HEADER_IMPLICATIONS`).

Appendix headers (`HEADER_APPENDIX`, `HEADER_EVIDENCE_ASSESSMENT`, `HEADER_DOMAIN_CONCEPTS`, `HEADER_REFERENCES`) remain unchanged regardless of arc.

---

## Shared Section Headers

Headers used in both generic and arc paths for common document sections.

### English (en)

| Variable | Value |
|----------|-------|
| `HEADER_RELATED_MEGATRENDS` | Related Megatrends |
| `HEADER_EVIDENCE_QUALITY_ANALYSIS` | Evidence Quality Analysis |
| `HEADER_VERIFICATION_ROBUSTNESS` | Verification Robustness |
| `HEADER_SOURCE_AUTHORITY` | Source Authority |
| `HEADER_EVIDENCE_FRESHNESS_DETAIL` | Evidence Freshness |
| `HEADER_QUALITY_DIMENSION_INSIGHTS` | Quality Dimension Insights |

### German (de)

| Variable | Value |
|----------|-------|
| `HEADER_RELATED_MEGATRENDS` | Verwandte Megatrends |
| `HEADER_EVIDENCE_QUALITY_ANALYSIS` | Evidenzqualitätsanalyse |
| `HEADER_VERIFICATION_ROBUSTNESS` | Verifikationsrobustheit |
| `HEADER_SOURCE_AUTHORITY` | Quellenautorität |
| `HEADER_EVIDENCE_FRESHNESS_DETAIL` | Evidenzaktualität |
| `HEADER_QUALITY_DIMENSION_INSIGHTS` | Qualitätsdimensionen-Einblicke |

## Evidence Assessment Table Headers

### English (en)

| Table Header | Value |
|--------------|-------|
| `TH_METRIC` | Metric |
| `TH_VALUE` | Value |
| `ROW_TOTAL_TRENDS` | Total Trends |
| `ROW_CLAIMS_REFERENCED` | Claims Referenced |
| `ROW_AVG_TREND_CONFIDENCE` | Avg Trend Confidence |
| `ROW_AVG_CLAIM_CONFIDENCE` | Avg Claim Confidence |
| `ROW_EVIDENCE_FRESHNESS` | Evidence Freshness |
| `ROW_CROSS_CONNECTIONS` | Cross-Connections |
| `ROW_THEMATIC_CLUSTERS` | Thematic Clusters |

### German (de)

| Table Header | Value |
|--------------|-------|
| `TH_METRIC` | Metrik |
| `TH_VALUE` | Wert |
| `ROW_TOTAL_TRENDS` | Erkenntnisse gesamt |
| `ROW_CLAIMS_REFERENCED` | Referenzierte Behauptungen |
| `ROW_AVG_TREND_CONFIDENCE` | Durchschn. Erkenntniskonfidenz |
| `ROW_AVG_CLAIM_CONFIDENCE` | Durchschn. Behauptungskonfidenz |
| `ROW_EVIDENCE_FRESHNESS` | Evidenzaktualität |
| `ROW_CROSS_CONNECTIONS` | Querverbindungen |
| `ROW_THEMATIC_CLUSTERS` | Thematische Cluster |

## Usage in Synthesis Generation

**Frontmatter:**
```yaml
language: {PROJECT_LANGUAGE}
```

**Navigation header:**
```markdown
> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}
```

**Section headers:**
```markdown
## {HEADER_EXECUTIVE_SUMMARY}

## {HEADER_STRATEGIC_CONTEXT}

## {HEADER_KEY_TRENDS}

## {HEADER_CROSS_CONNECTIONS}

## {HEADER_RELATED_DIMENSIONS}

## {HEADER_IMPLICATIONS}

**{HEADER_STRATEGIC_IMPLICATIONS}:**

**{HEADER_TACTICAL_RECOMMENDATIONS}:**

## {HEADER_EVIDENCE_ASSESSMENT}

## {HEADER_DOMAIN_CONCEPTS}

## {HEADER_REFERENCES}

### {HEADER_TRENDS}

### {HEADER_SUPPORTING_CLAIMS}
```

## Language-Specific Formatting

### German (de)

- **Umlauts:** Use proper umlauts (ä, ö, ü, ß) in all body text and headings
- **Tone:** Formal business German (Sie-Form not applicable in research documents)
- **File names/slugs:** ASCII only (ä→ae, ö→oe, ü→ue, ß→ss)
- **Numbers:** Use comma as decimal separator in prose (0,81 not 0.81)
- **Quotes:** Use German quotation marks („text") in prose if needed

### English (en)

- **Tone:** Professional business English
- **Contractions:** Avoid in formal synthesis documents
- **Numbers:** Use period as decimal separator (0.81)
- **Quotes:** Use standard quotation marks ("text")

## Project Language Loading

```bash
# Phase 1: Load Project Language
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Validate against supported languages
case "$PROJECT_LANGUAGE" in
  en|de)
    log_conditional INFO "PROJECT_LANGUAGE=$PROJECT_LANGUAGE"
    ;;
  *)
    log_conditional WARNING "Unsupported language: $PROJECT_LANGUAGE, defaulting to en"
    PROJECT_LANGUAGE="en"
    ;;
esac
```

## Error Response

Invalid language code handling:

```json
{
  "success": true,
  "language_detected": "en",
  "language_warning": "Unsupported language 'fr' in sprint-log.json, defaulted to 'en'"
}
```
