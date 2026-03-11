# Language Templates

Localized header strings for entity generation across the 12-stage entity pipeline.

## Language Detection

1. If `--language` provided: Validate ISO 639-1 format (2-letter lowercase), must be `en` or `de`
2. If not provided: Detect from project metadata (`.metadata/project-config.json`)
3. Workspace preference: Read `.workspace-config.json` language field (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD)
4. Fallback: Sample 3 source files for majority language
5. Default: `en`

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

### 12-synthesis (Hub Report)

Headers for research catalog hub (research-hub.md) and cross-dimensional synthesis (synthesis-cross-dimensional.md).

**Hub Report Headers:**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_RESEARCH_OVERVIEW` | Research Overview | Forschungsübersicht |
| `HEADER_NAVIGATION_MAP` | Navigation Map | Navigationsübersicht |
| `HEADER_RESEARCH_FOUNDATION` | Research Foundation | Forschungsgrundlage |
| `HEADER_CROSS_DIMENSIONAL_ANALYSIS` | Cross-Dimensional Analysis | Dimensionsübergreifende Analyse |
| `HEADER_DIMENSION_DEEP_DIVES` | Dimension Deep-Dives | Dimensions-Tiefenanalysen |
| `HEADER_TREND_INTELLIGENCE` | Trend Intelligence | Trendintelligenz |
| `HEADER_TECHNICAL_DETAILS` | Technical Details | Technische Details |
| `HEADER_APPENDIX_GENERATION` | Appendix: Report Generation | Anhang: Berichterstellung |

**Synthesis File Headers (synthesis-cross-dimensional.md):**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_EXECUTIVE_SUMMARY` | Executive Summary | Zusammenfassung |
| `HEADER_STRATEGIC_RECOMMENDATIONS` | Strategic Recommendations | Strategische Empfehlungen |
| `HEADER_CROSS_DIMENSIONAL_PATTERNS` | Cross-Dimensional Patterns | Dimensionsübergreifende Muster |
| `HEADER_REINFORCING_FINDINGS` | Reinforcing Findings | Verstärkende Ergebnisse |
| `HEADER_TENSIONS_TRADEOFFS` | Tensions and Trade-offs | Spannungen und Zielkonflikte |
| `HEADER_EMERGENT_IMPLICATIONS` | Emergent Implications | Emergente Implikationen |

**Legacy Headers (kept for backward compatibility):**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_RESEARCH_QUESTION` | Research Question | Forschungsfrage |
| `HEADER_OVERARCHING_THEMES` | Overarching Themes | Übergreifende Themen |
| `HEADER_RESEARCH_DIMENSIONS` | Research Dimensions | Forschungsdimensionen |
| `HEADER_RESEARCH_SCOPE_METHODOLOGY` | Research Scope & Methodology | Forschungsumfang & Methodik |
| `HEADER_QUALITY_METRICS` | Research Quality Metrics | Forschungsqualitätsmetriken |
| `HEADER_RESEARCH_DIMENSIONS_ANALYZED` | Research Dimensions | Forschungsdimensionen |
| `HEADER_APPENDIX_SCOPE` | Appendix: Research Scope | Anhang: Forschungsumfang |
| `HEADER_APPENDIX_TECHNICAL` | Appendix: Technical Details | Anhang: Technische Details |
| `HEADER_REPORT_GENERATION` | Report Generation | Berichtserstellung |
| `HEADER_RESEARCH_PIPELINE_METRICS` | Research Pipeline Metrics | Metriken der Forschungspipeline |
| `HEADER_DETAILED_METHODOLOGY` | For Detailed Methodology | Zur detaillierten Methodik |
| `LABEL_RESEARCH_SCOPE` | Research Scope | Forschungsumfang |
| `LABEL_PERIOD` | Period | Zeitraum |
| `LABEL_ENTITY_COUNTS` | Entity Counts | Entitätszählungen |
| `LABEL_EVIDENCE_QUALITY` | Evidence Quality | Evidenzqualität |
| `LABEL_ENTITY_STATISTICS` | Entity Statistics | Entitätsstatistiken |
| `LABEL_WIKILINK_DENSITY` | Wikilink Density | Wikilink-Dichte |
| `LABEL_METRIC` | Metric | Metrik |
| `LABEL_COUNT` | Count | Anzahl |
| `LABEL_COVERAGE` | Coverage | Abdeckung |
| `LABEL_DIMENSIONS` | Dimensions | Dimensionen |
| `LABEL_DIMENSIONS_ANALYZED` | Dimensions Analyzed | Dimensionen analysiert |
| `LABEL_TOTAL_TRENDS` | Total Trends | Trends gesamt |
| `LABEL_CITATION_DENSITY` | Citation Density | Zitat-Dichte |
| `LABEL_ENTITY_COVERAGE` | Coverage | Abdeckung |
| `LABEL_EVIDENCE_STRENGTH` | Evidence Strength | Evidenzstärke |
| `LABEL_TRENDS_ANALYZED` | Trends analyzed | Trends analysiert |
| `LABEL_MEGATRENDS_IDENTIFIED` | Megatrends identified | Megatrends identifiziert |
| `LABEL_CONCEPTS_REFERENCED` | Concepts referenced | Konzepte referenziert |
| `LABEL_CITATIONS_CREATED` | Citations created | Zitate erstellt |
| `LABEL_TOTAL_WIKILINKS` | Total wikilinks | Gesamt-Wikilinks |
| `LABEL_BY_TYPE` | By type | Nach Typ |
| `LABEL_DIM_SYNTHESES` | Dimensions | Dimensionen |
| `LABEL_OTHER` | Other | Andere |
| `LABEL_PRIORITY` | Priority | Priorität |
| `LABEL_DIMENSIONS_ADDRESSED` | Dimensions Addressed | Adressierte Dimensionen |
| `LABEL_DEPENDENCIES` | Dependencies | Abhängigkeiten |
| `VALUE_HIGH` | High | Hoch |
| `VALUE_MEDIUM` | Medium | Mittel |
| `VALUE_LOW` | Low | Niedrig |
| `LINK_FULL_ANALYSIS` | Full Analysis | Vollständige Analyse |
| `LINK_DEEP_DIVE` | Deep Dive | Tiefere Analyse |
| `HEADER_TREND_LANDSCAPE` | Trend Landscape | Trendlandschaft |
| `TH_DIMENSION` | Dimension | Dimension |
| `TH_ACT_HORIZON` | Act (0-6 months) | Act (0-6 Mon.) |
| `TH_PLAN_HORIZON` | Plan (6-18 months) | Plan (6-18 Mon.) |
| `TH_OBSERVE_HORIZON` | Observe (18+ months) | Observe (18+ Mon.) |
| `BRIDGE_TREND_TABLE` | The following table shows the trends and megatrends by dimension and planning horizon: | Die folgende Tabelle zeigt die Trends und Megatrends nach Dimension und Zeithorizont: |
| `LEGEND_MEGATREND` | Megatrend | Megatrend |
| `LEGEND_TREND` | Trend | Erkenntnis |
| `LABEL_GENERAL` | General | Allgemein |
| `LEGEND_KANBAN_TABLE` | Legend: **M** = Megatrend, **T** = Trend | Legende: **M** = Megatrend, **T** = Trend |
| `CALLOUT_HUB_ANALYSIS` | **Hub Analysis:** The following patterns emerge only when viewing dimensions holistically. Dimension-specific details are available in spoke documents. | **Hub-Analyse:** Die folgenden Muster entstehen nur bei ganzheitlicher Betrachtung der Dimensionen. Dimensionsspezifische Details sind in den Spoke-Dokumenten verfügbar. |
| `BRIDGE_EXEC_TO_RECOMMENDATIONS` | **These findings demand strategic action.** The following recommendations leverage cross-dimensional insights to address the research question with maximum impact. | **Diese Erkenntnisse erfordern strategisches Handeln.** Die folgenden Empfehlungen nutzen dimensionsübergreifende Einsichten, um die Forschungsfrage mit maximaler Wirkung zu adressieren. |
| `BRIDGE_RECOMMENDATIONS_TO_PATTERNS` | **To understand these recommendations, we examine how strategic dimensions interact.** The following patterns show how dimensions reinforce, conflict, and create emergent dynamics. | **Um diese Empfehlungen zu verstehen, untersuchen wir, wie strategische Dimensionen interagieren.** Die folgenden Muster zeigen, wie sich Dimensionen verstärken, in Konflikt geraten und emergente Dynamiken erzeugen. |
| `MSG_RESEARCH_FRAMEWORK` | **Research Framework:** Hub-and-Spoke Progressive Disclosure | **Forschungsrahmen:** Hub-and-Spoke Progressive Disclosure |
| `MSG_INTERPRETATION_MULTIFACETED` | Multi-faceted analysis | Mehrdimensionale Analyse |
| `MSG_INTERPRETATION_COMPREHENSIVE` | Comprehensive evidence base | Umfassende Evidenzbasis |
| `MSG_INTERPRETATION_EVIDENCE_BACKED` | Evidence-backed claims | Evidenzbasierte Aussagen |
| `MSG_INTERPRETATION_HIGH_UTILIZATION` | High entity utilization | Hohe Entitätsnutzung |
| `MSG_INTERPRETATION_STRONG_SUBSTANTIATION` | Strong substantiation | Starke Substantiierung |

### 11-trends

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CONTEXT` | Context | Kontext |
| `HEADER_EVIDENCE` | Evidence | Beweise |
| `HEADER_TENSIONS` | Tensions & Limitations | Spannungen & Einschränkungen |
| `HEADER_IMPLICATIONS` | Implications | Implikationen |
| `HEADER_STRATEGIC` | Strategic | Strategisch |
| `HEADER_OPERATIONAL` | Operational | Operativ |
| `HEADER_TECHNICAL` | Technical | Technisch |
| `HEADER_CLAIM_EVIDENCE` | Claim Evidence | Beleglage |
| `HEADER_REFERENCES` | References | Referenzen |
| `HEADER_ENTITY_CITATIONS` | Entity Citations | Entitäts-Zitate |
| `HEADER_CLAIM_CITATIONS` | Claim Citations | Beleg-Zitate |

### 10-claims

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CLAIM` | Claim | Behauptung |
| `HEADER_JUSTIFICATION` | Justification | Begründung |
| `HEADER_EVIDENCE` | Evidence | Beweise |
| `HEADER_CONFIDENCE` | Confidence Breakdown | Konfidenz-Aufschlüsselung |
| `HEADER_PROVENANCE` | Provenance (Audit Trail) | Provenienz (Audit-Pfad) |
| `HEADER_RELEVANCE` | Relevance | Relevanz |

### 09-citations

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CITATION` | Citation | Zitat |
| `HEADER_COMPONENTS` | Components | Komponenten |
| `TEXT_RETRIEVED` | Retrieved {Month} {Day}, {Year} | Abgerufen am {Day}. {Month} {Year} |

### 08-publishers

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CONTEXT` | Context | Kontext |
| `HEADER_TYPE` | Type | Typ |
| `HEADER_SOURCES` | Related Sources | Zugehörige Quellen |
| `HEADER_MISSION` | Mission & Mandate | Mission & Mandat |
| `HEADER_ESTABLISHMENT` | Establishment & Headquarters | Gründung & Hauptsitz |
| `HEADER_EXPERTISE` | Domain Expertise | Domänenexpertise |
| `HEADER_CREDIBILITY` | Credibility Assessment | Glaubwürdigkeitsbewertung |
| `HEADER_BACKGROUND` | Professional Background | Beruflicher Hintergrund |
| `HEADER_EXPERTISE_ROLE` | Expertise & Role | Expertise & Rolle |
| `HEADER_POSITIONS` | Key Positions | Schlüsselpositionen |
| `NOT_DOCUMENTED` | Not publicly documented | Nicht öffentlich dokumentiert |

### 07-sources

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_SOURCE` | Source | Quelle |
| `HEADER_RELIABILITY` | Reliability | Zuverlässigkeit |
| `HEADER_ACCESS_DATE` | Access Date | Zugriffsdatum |
| `HEADER_CONTENT_SUMMARY` | Content Summary | Inhaltszusammenfassung |
| `HEADER_KEY_CLAIMS` | Key Claims | Kernaussagen |

### 06-megatrends (Megatrends)

Megatrends use TIPS-style strategic narrative.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_TREND` | Trend | Trend |
| `HEADER_IMPLICATION` | Implication | Implikation |
| `HEADER_POSSIBILITY` | Possibility | Möglichkeit |
| `HEADER_SOLUTION` | Solution | Lösung |
| `HEADER_EVIDENCE_BASE` | Evidence Base | Evidenzbasis |
| `HEADER_SUPPORTING_CLAIMS` | Supporting Claims | Unterstützende Belege |
| `HEADER_KEY_FINDINGS` | Key Findings | Kernerkenntnisse |
| `LABEL_SOURCE` | Source | Quelle |
| `LABEL_CONFIDENCE` | Confidence | Konfidenz |
| `LABEL_PLANNING_HORIZON` | Planning Horizon | Planungshorizont |
| `LABEL_FINDING_COVERAGE` | Finding Coverage | Ergebnisabdeckung |
| `LABEL_CHANCE` | Chance | Chance |
| `LABEL_RISK` | Risk | Risiko |
| `VALUE_CLUSTERED` | clustered | geclustert |
| `VALUE_SEEDED` | seeded | vordefiniert |
| `VALUE_HYBRID` | hybrid | hybrid |
| `VALUE_STRONG` | strong | stark |
| `VALUE_MODERATE` | moderate | moderat |
| `VALUE_WEAK` | weak | schwach |
| `VALUE_HYPOTHESIS` | hypothesis | Hypothese |
| `VALUE_ACT` | act | handeln |
| `VALUE_PLAN` | plan | planen |
| `VALUE_OBSERVE` | observe | beobachten |
| `MSG_NO_CLAIMS` | No verified claims available for this megatrend. | Keine verifizierten Belege für diesen Megatrend verfügbar. |
| `MSG_HYPOTHESIS_WARNING` | This megatrend was identified as expected but not validated by research findings. Consider additional research. | Dieser Megatrend wurde als erwartet identifiziert, aber nicht durch Forschungsergebnisse validiert. Weitere Recherche empfohlen. |

### 06-megatrends (Generic Structure)

Megatrends for generic research type use domain-based structure instead of TIPS.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_WHAT_IT_IS` | What it is | Was es ist |
| `HEADER_WHAT_IT_DOES` | What it does | Was es tut |
| `HEADER_WHAT_IT_MEANS` | What it means | Was es bedeutet |
| `HEADER_QUALITATIVE_IMPACT` | Qualitative Impact | Qualitative Auswirkungen |
| `HEADER_QUANTITATIVE_INDICATORS` | Quantitative Indicators | Quantitative Indikatoren |
| `HEADER_RELATED_FINDINGS` | Related Findings | Zugehörige Ergebnisse |
| `TH_METRIC` | Metric | Kennzahl |
| `TH_VALUE_RANGE` | Value/Range | Wert/Bereich |
| `TH_SOURCE` | Source | Quelle |
| `MSG_FINDING_REFS_NOTE` | For complete finding references, see the `finding_refs` array in the YAML frontmatter above. | Für vollständige Ergebnisreferenzen siehe das `finding_refs`-Array im YAML-Frontmatter oben. |
| `MSG_METRICS_NOTE` | Metrics extracted from member findings where available. | Metriken aus zugehörigen Ergebnissen extrahiert, sofern verfügbar. |

### 06-megatrends UI Strings (Phase 4b Proposal)

User-facing strings for megatrend seed proposal and validation workflow.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_PROPOSED_MEGATRENDS` | Proposed Seed Megatrends | Vorgeschlagene Seed-Megatrends |
| `MSG_MEGATREND_PROPOSAL_INTRO` | Based on your research question and dimensions, I've identified the following expected megatrends: | Basierend auf Ihrer Forschungsfrage und den Dimensionen habe ich die folgenden erwarteten Megatrends identifiziert: |
| `HEADER_WHAT_ARE_SEEDS` | What are seed megatrends? | Was sind Seed-Megatrends? |
| `MSG_SEED_DEFINITION` | Seed megatrends are **expected canonical trends** that should appear in comprehensive research. | Seed-Megatrends sind **erwartete kanonische Trends**, die in einer umfassenden Recherche erscheinen sollten. |
| `MSG_SEED_PURPOSE` | During megatrend clustering (Phase 5), findings will be matched against these seeds to validate expected themes, flag gaps, and ensure canonical naming. | Während des Megatrend-Clusterings (Phase 5) werden Ergebnisse mit diesen Seeds abgeglichen, um erwartete Themen zu validieren, Lücken aufzuzeigen und kanonische Benennung sicherzustellen. |
| `HEADER_YOUR_OPTIONS` | Your options: | Ihre Optionen: |
| `OPT_ACCEPT_ALL` | **Accept all** - Use all proposed seeds as-is | **Alle akzeptieren** - Alle vorgeschlagenen Seeds unverändert verwenden |
| `OPT_MODIFY` | **Modify** - Change specific seeds (name, keywords, dimension) | **Ändern** - Bestimmte Seeds anpassen (Name, Keywords, Dimension) |
| `OPT_REMOVE` | **Remove** - Exclude seeds you don't expect to be relevant | **Entfernen** - Seeds ausschließen, die Sie nicht für relevant halten |
| `OPT_ADD_CUSTOM` | **Add custom** - Include additional megatrends you expect to see | **Eigene hinzufügen** - Zusätzliche erwartete Megatrends einfügen |
| `OPT_SKIP_SEEDING` | **Skip seeding** - Proceed without seed megatrends (bottom-up only) | **Seeding überspringen** - Ohne Seed-Megatrends fortfahren (nur Bottom-up) |
| `HEADER_FINAL_SEED_LIST` | Final Seed Megatrend List | Finale Seed-Megatrend-Liste |
| `LABEL_NUMBER` | # | Nr. |
| `LABEL_MEGATREND` | Megatrend | Megatrend |
| `LABEL_DIMENSION` | Dimension | Dimension |
| `LABEL_RATIONALE` | Rationale | Begründung |
| `LABEL_STATUS` | Status | Status |
| `VALUE_LLM_PROPOSED` | LLM proposed | LLM-vorgeschlagen |
| `VALUE_USER_ADDED` | User added | Benutzer hinzugefügt |
| `VALUE_REMOVED` | Removed | Entfernt |
| `VALUE_VALIDATED` | Validated | Validiert |
| `MSG_TOTAL_SEEDS` | **Total:** {count} validated seeds | **Gesamt:** {count} validierte Seeds |
| `PROMPT_CONFIRM_SEEDS` | Confirm this list to proceed? (yes/modify/add more) | Diese Liste bestätigen um fortzufahren? (ja/ändern/mehr hinzufügen) |

### 06-megatrends UI Strings (Phase 5 Gap Report)

Strings for megatrend coverage gap reporting.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_GAP_REPORT` | Megatrend Coverage Gap Report | Megatrend-Abdeckungslückenbericht |
| `HEADER_SEED_STATUS` | Seed Megatrends Status | Seed-Megatrends Status |
| `LABEL_SEED_NAME` | Seed Name | Seed-Name |
| `LABEL_EVIDENCE` | Evidence | Evidenz |
| `LABEL_NOTES` | Notes | Anmerkungen |
| `VALUE_MERGED` | Merged with cluster | Mit Cluster zusammengeführt |
| `VALUE_CREATED_HYPOTHESIS` | Created as hypothesis | Als Hypothese erstellt |
| `MSG_NEEDS_MORE_RESEARCH` | Needs more research | Benötigt weitere Recherche |
| `HEADER_GAPS_IDENTIFIED` | Gaps Identified | Identifizierte Lücken |
| `LABEL_CRITICAL` | Critical (must_match) | Kritisch (must_match) |
| `LABEL_WARNINGS` | Warnings (ensure_covered) | Warnungen (ensure_covered) |
| `HEADER_RECOMMENDATIONS` | Recommendations | Empfehlungen |
| `MSG_NO_GAPS` | None | Keine |

### 05-domain-concepts

Domain concepts use IS/DOES/MEANS structure (same as generic megatrends).

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_WHAT_IT_IS` | What it is | Was es ist |
| `HEADER_WHAT_IT_DOES` | What it does | Was es tut |
| `HEADER_WHAT_IT_MEANS` | What it means | Was es bedeutet |
| `HEADER_QUALITATIVE_IMPACT` | Qualitative Impact | Qualitative Auswirkungen |
| `HEADER_QUANTITATIVE_INDICATORS` | Quantitative Indicators | Quantitative Indikatoren |
| `HEADER_RELATED_FINDINGS` | Related Findings | Zugehörige Ergebnisse |

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

### Insight Summary (Arc Element Headers)

Exact `##` section headers for insight-summary.md output, per arc and language. The narrative body MUST contain EXACTLY 4 `##` headers matching the selected arc's elements below. No creative alternatives, no additional `##` sections, no renaming.

**industry-transformation:**

| Element | English (en) | German (de) |
|---------|--------------|-------------|
| 1 | Forces: Transformation Drivers | Kräfte: Makro-Treiber |
| 2 | Friction: Barriers to Change | Reibung: Widerstandspunkte |
| 3 | Evolution: Pathway Forward | Evolution: Strukturelle Veränderungen |
| 4 | Leadership: Strategic Imperatives | Führung: Positionierungsstrategien |

**corporate-visions:**

| Element | English (en) | German (de) |
|---------|--------------|-------------|
| 1 | Why Change: Unconsidered Needs | Warum Wandel: Unerkannte Handlungsbedarfe |
| 2 | Why Now: Forcing Functions | Warum Jetzt: Handlungsdruck |
| 3 | Why You: Unique Positioning | Warum Sie: Einzigartige Positionierung |
| 4 | Why Pay: ROI Justification | Warum Investieren: ROI-Begründung |

**technology-futures:**

| Element | English (en) | German (de) |
|---------|--------------|-------------|
| 1 | What's Emerging: Technology Horizon | Was Entsteht: Technologie-Horizont |
| 2 | What's Converging: Integration Points | Was Konvergiert: Integrationspunkte |
| 3 | What's Possible: Application Scenarios | Was Möglich Ist: Anwendungsszenarien |
| 4 | What's Required: Capability Development | Was Erforderlich Ist: Kompetenzentwicklung |

**competitive-intelligence:**

| Element | English (en) | German (de) |
|---------|--------------|-------------|
| 1 | Landscape: Competitive Overview | Landschaft: Wettbewerbsübersicht |
| 2 | Shifts: Market Dynamics | Verschiebungen: Marktdynamik |
| 3 | Positioning: Strategic Options | Positionierung: Strategische Optionen |
| 4 | Implications: Action Priorities | Implikationen: Handlungsprioritäten |

**strategic-foresight:**

| Element | English (en) | German (de) |
|---------|--------------|-------------|
| 1 | Signals: Early Indicators | Signale: Frühindikatoren |
| 2 | Scenarios: Future States | Szenarien: Zukunftsbilder |
| 3 | Strategies: Adaptive Approaches | Strategien: Adaptive Ansätze |
| 4 | Decisions: Action Framework | Entscheidungen: Handlungsrahmen |

**trend-panorama:**

| Element | English (en) | German (de) | TIPS Dimension |
|---------|--------------|-------------|----------------|
| 1 | Forces: External Pressures & Market Signals | Kräfte: Externe Einflüsse & Marktsignale | T (Externe Effekte) |
| 2 | Impact: Value Chain Disruption | Wirkung: Wertschöpfungsdynamik | I (Digitale Wertetreiber) |
| 3 | Horizons: Strategic Possibilities | Horizonte: Strategische Möglichkeiten | P (Neue Horizonte) |
| 4 | Foundations: Capability Requirements | Fundamente: Kompetenzanforderungen | S (Digitales Fundament) |

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
