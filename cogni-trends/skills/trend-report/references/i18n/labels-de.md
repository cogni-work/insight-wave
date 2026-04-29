# Deutsche Beschriftungen für Trend-Report

Language: `de`

## Berichtstitel

```text
REPORT_TITLE: "{TITLE}"
REPORT_SUBTITLE: "{SUBTITLE}"
```

> **Titel:** Ein prägnanter Titel (max. 8 Wörter), abgeleitet aus dem Thema, Erzählbogen
> und den Handlungsfeldern. NICHT die Forschungsfrage — die wird zum Untertitel.
> **Untertitel:** Die Forschungsfrage (`{TOPIC}`), ggf. gekürzt für bessere Lesbarkeit.
> NICHT `in {SUBSECTOR}` anhängen — das Forschungsthema enthält bereits den
> Branchen- und Geografiekontext.

## Titelvorschlag

```text
PHASE_0_TITLE_QUESTION: "Vorgeschlagener Berichtstitel — übernehmen oder anpassen:"
PHASE_0_TITLE_HEADER: "Berichtstitel"
PHASE_0_TITLE_ACCEPT: "Übernehmen"
PHASE_0_TITLE_EDIT: "Anpassen"
```

## Abschnittsüberschriften

```text
EXEC_SUMMARY: "Zusammenfassung"
PORTFOLIO_ANALYSIS: "Portfolio-Analyse"
CLAIMS_REGISTRY: "Quellenregister"
```

## TIPS-Dimensionsüberschriften

```text
DIMENSION_T: "T — Trends: Externe Effekte"
DIMENSION_I: "I — Implikationen: Digitale Wertetreiber"
DIMENSION_P: "P — Potenziale: Neue Horizonte"
DIMENSION_S: "S — Schlüssel: Digitales Fundament"
```

## Horizontbezeichnungen

```text
HORIZON_ACT: "ACT-Horizont (0-2 Jahre)"
HORIZON_PLAN: "PLAN-Horizont (2-5 Jahre)"
HORIZON_OBSERVE: "OBSERVE-Horizont (5+ Jahre)"
YEARS: "Jahre"
```

## Trend-Unterabschnitte

```text
OVERVIEW: "Trendübersicht"
IMPLICATIONS: "Implikationen"
OPPORTUNITIES: "Chancen"
ACTIONS: "Empfohlene Maßnahmen"
```

## Zusammenfassung

```text
CROSS_CUTTING_THEMES: "Querschnittsthemen"
KEY_FINDINGS: "Kernbefunde"
INDICATOR_BALANCE: "Indikator-Balance"
STRATEGIC_POSTURE: "Strategische Ausrichtung"
```

## Portfolio-Analyse

```text
HORIZON_DISTRIBUTION: "Horizontverteilung"
CONFIDENCE_DISTRIBUTION: "Konfidenzverteilung"
SIGNAL_INTENSITY: "Signalintensität"
LEADING_LAGGING: "Früh-/Spätindikatoren-Balance"
EVIDENCE_COVERAGE: "Evidenzabdeckung"
DIMENSION: "Dimension"
TOTAL: "Gesamt"
HIGH: "Hoch"
MEDIUM: "Mittel"
LOW: "Niedrig"
UNCERTAIN: "Unsicher"
AVG_INTENSITY: "Ø Intensität"
STRONGEST_TREND: "Stärkster Trend"
LEADING: "Frühindikatoren"
LAGGING: "Spätindikatoren"
RATIO: "Verhältnis"
WITH_EVIDENCE: "Mit Evidenz"
QUALITATIVE_ONLY: "Nur qualitativ"
COVERAGE_PCT: "Abdeckung %"
```

## Quellenregister

```text
CLAIMS_REGISTRY_INTRO: "Alle quantitativen Aussagen aus diesem Bericht mit ihren Quell-URLs."
CLAIM: "Aussage"
VALUE: "Wert"
SOURCE: "Quelle"
CLAIMS: "Aussagen"
```

## Handlungsfelder (Themenmodus)

```text
STRATEGIC_INVESTMENT_THEMES_OVERVIEW: "Handlungsfelder"
INVESTMENT_THEME: "Handlungsfeld"
STRATEGIC_QUESTION: "Strategische Fragestellung"
EXECUTIVE_SPONSOR: "Verantwortlicher Sponsor"
INVESTMENT_THESIS: "Investitionsthese"
VALUE_CHAINS: "Wertschöpfungsketten"
TREND: "Trend"
IMPLICATION: "Implikation"
POSSIBILITY: "Potenzial"
FOUNDATION: "Fundamentanforderungen"
SOLUTION_TEMPLATES: "Lösungsbausteine"
SOLUTION: "Lösung"
CATEGORY: "Kategorie"
ENABLER_TYPE: "Enabler-Typ"
STRATEGIC_ACTIONS: "Strategische Maßnahmen"
EMERGING_SIGNALS: "Aufkommende Signale"
EMERGING_SIGNALS_INTRO: "Die folgenden Kandidaten wurden keinem Handlungsfeld zugeordnet. Sie repräsentieren frühe Signale, die beobachtet werden sollten — ihre Abwesenheit von den aktuellen Handlungsfeldern ist selbst eine informative Beobachtung."
ALL_CANDIDATES_THEMED: "Alle 60 Kandidaten sind durch die Handlungsfelder oben abgedeckt — keine unzugeordneten Signale."
HEADLINE_EVIDENCE: "Kernevidenz"
INVESTMENT_THEME_OVERVIEW: "Handlungsfeldübersicht"
CHAINS: "Ketten"
CANDIDATES: "Kandidaten"
HORIZON_MIX: "Horizontmix"
EVIDENCE: "Evidenz"
ORPHANS: "Unzugeordnet"
MECE_VALIDATION: "MECE-Validierung"
METRIC: "Kennzahl"
STATUS: "Status"
INVESTMENT_THEME_COUNT: "Anzahl Handlungsfelder"
MUTUAL_EXCLUSIVITY: "Gegenseitige Ausschließlichkeit"
COLLECTIVE_EXHAUSTIVENESS: "Kollektive Vollständigkeit"
BALANCE: "Balance"
```

## Story-Arc-Elementbezeichnungen (Fallback / Strukturmarker)

> These labels are structural identifiers, NOT output headings. The theme-writer
> agent generates message-driven headings from evidence (see arc-definition.md
> Heading Generation Rules). These labels serve as: (a) fallback when evidence
> is insufficient, (b) structural markers in agent prompts for element
> identification, (c) quality gate reference labels in validation output.

```text
WHY_CHANGE: "Warum Veränderung: Der unberücksichtigte Bedarf"
WHY_NOW: "Warum jetzt: Das sich schließende Zeitfenster"
WHY_YOU: "Warum Sie: Die Portfolio-Antwort"
WHY_PAY: "Geschäftliche Auswirkungen: Der Business Case"
COST_OF_INACTION: "Handlungskosten vs. Untätigkeitskosten"
```

## Auswahl des Report-Erzählbogens

```text
PHASE_0_ARC_QUESTION: "Welcher Erzählbogen soll den Bericht rahmen? Dies bestimmt die H2-Struktur (Smarter Service: 4 Dimensionen als H2; andere Bögen: Handlungsfelder als H2)."
PHASE_0_ARC_HEADER: "Report-Erzählbogen"
ARC_SMARTER_SERVICE: "Smarter Service (Empfohlen für TIPS-Berichte)"
ARC_SMARTER_SERVICE_DESC: "Makro-Skelett: Kräfte → Wirkung → Horizonte → Fundamente als 4 H2-Abschnitte; Handlungsfelder als verankerte H3-Cases verschachtelt. Schließt mit dem Fähigkeitsimperativ."
ARC_CORPORATE_VISIONS: "Corporate Visions"
ARC_CORPORATE_VISIONS_DESC: "Annahmen hinterfragen, Dringlichkeit erzeugen, Untätigkeit beziffern — der B2B-Überzeugungsrahmen. Handlungsfelder als H2."
ARC_TECHNOLOGY_FUTURES: "Technology Futures"
ARC_TECHNOLOGY_FUTURES_DESC: "Aufkommende Fähigkeiten kartieren, Konvergenz zeigen, erforderliche Investitionen beziffern"
ARC_COMPETITIVE_INTELLIGENCE: "Competitive Intelligence"
ARC_COMPETITIVE_INTELLIGENCE_DESC: "Wettbewerbsverschiebungen kartieren, Positionierungschancen identifizieren, Bedrohungen bewerten"
ARC_STRATEGIC_FORESIGHT: "Strategic Foresight"
ARC_STRATEGIC_FORESIGHT_DESC: "Signale lesen, Szenarien aufbauen, Entscheidungen unter Unsicherheit rahmen"
ARC_INDUSTRY_TRANSFORMATION: "Branchentransformation"
ARC_INDUSTRY_TRANSFORMATION_DESC: "Strukturelle Kräfte identifizieren, Reibungspunkte anerkennen, Transformationspfad aufzeigen"
ARC_TREND_PANORAMA: "Trend-Panorama (TIPS-nativ, ohne Handlungsfelder)"
ARC_TREND_PANORAMA_DESC: "Kräfte → Wirkung → Horizonte → Fundamente als Panorama (ohne Handlungsfelder)"
ARC_THEME_THESIS: "Handlungsfeld-These"
ARC_THEME_THESIS_DESC: "Jedes Handlungsfeld als Investitionsthese mit eigenem quantifiziertem Business Case"

# Smarter-Service-Makroabschnitts-Beschriftungen (vom trend-report-composer verwendet)
MACRO_FORCES: "Kräfte — Externe Effekte"
MACRO_IMPACT: "Wirkung — Digitale Wertetreiber"
MACRO_HORIZONS: "Horizonte — Neue Horizonte"
MACRO_FOUNDATIONS: "Fundamente — Digitales Fundament"

# Smarter-Service-Synthese
SYNTHESIS_HEADING_SMARTER_SERVICE: "Der Fähigkeitsimperativ"
UNIFIED_CAPABILITY_ROADMAP_LABEL: "Übergreifende Fähigkeits-Roadmap"

# Smarter Service: dimensionsspezifische Phase-2-Statusmeldungen
PHASE_2_PRIMER_START: "Schreibe gemeinsamen Dimension-Primer (Smarter Service)..."
PHASE_2_PRIMER_WRITTEN: "Gemeinsamer Dimension-Primer geschrieben."
PHASE_2_THEME_CASE_AGENT_DISPATCH: "Theme-Case-Writer für {N} Handlungsfelder gestartet (schlanker 3-Beat-Modus)."
PHASE_2_THEME_CASE_AGENT_COMPLETE: "Theme-Case fertig: {theme_name}"
PHASE_2_THEME_CASE_AGENT_SKIP_RESUME: "Theme-Case übersprungen (Resume): {theme_name}"
PHASE_2_COMPOSER_DISPATCH: "Dimension-Composer wird gestartet: {dimension}..."
PHASE_2_COMPOSER_COMPLETE: "Dimension-Composer fertig: {dimension}"
PHASE_2_COMPOSER_SKIP_RESUME: "Dimension-Composer übersprungen (Resume): {dimension}"

# Sekundärpol-Callout-Muster (schlanker Modus)
SECONDARY_CALLOUT_PATTERN: "→ Siehe auch Handlungsfeld {N} unter {macro_section} für die {topic}-Abhängigkeit."

# Theme-Case-Heading-Helfer (schlanker Modus)
STRATEGIC_QUESTION_LABEL: "Strategische Frage"

# Quellenregister — Dimensions-Spalte (Smarter-Service-Modus)
DIMENSION_LABEL: "Dimension"
```

## Auswahl der Berichtslänge

```text
PHASE_0_LENGTH_QUESTION: "Wie lang soll der Bericht sein? Die Länge bezieht sich nur auf den Fließtext — das Quellenregister wird immer vollständig ausgegeben und nicht mitgezählt."
PHASE_0_LENGTH_HEADER: "Berichtslänge"
LENGTH_TIER_STANDARD: "Standard (≈4.000 Wörter)"
LENGTH_TIER_STANDARD_DESC: "Detaillierter Researchbericht — Pendant zum 'detailed'-Modus von cogni-research. Empfohlener Standard."
LENGTH_TIER_EXTENDED: "Erweitert (≈5.500 Wörter)"
LENGTH_TIER_EXTENDED_DESC: "Strategische Vertiefung mit mehr Evidenz pro Handlungsfeld."
LENGTH_TIER_COMPREHENSIVE: "Umfassend (≈7.000 Wörter)"
LENGTH_TIER_COMPREHENSIVE_DESC: "Vollständige Tiefenanalyse für Leser, die alle Details wünschen."
LENGTH_TIER_MAXIMUM: "Maximal (≈8.000 Wörter)"
LENGTH_TIER_MAXIMUM_DESC: "Bisheriges Verhalten — ausführlicher Fließtext, volle Evidenz pro Handlungsfeld."
LENGTH_TIER_CUSTOM_DESC: "Per Automation in tips-project.json vorgegeben. Grenzen: 2.500 ≤ target_words ≤ 12.000 Fließtext-Wörter."
```

> Die Längenangaben beziehen sich auf den *Fließtext* — Zusammenfassung + Handlungsfeld-Abschnitte + Brücken + Synthese. Das Quellenregister fügt je nach Anzahl der Aussagen weitere ~1.500–3.500 Wörter hinzu und ist in jedem Modus vollständig enthalten.

## Synthese-Abschnittsüberschriften (pro Erzählbogen)

```text
SYNTHESIS_CORPORATE_VISIONS: "Die Investitionsentscheidung"
SYNTHESIS_TECHNOLOGY_FUTURES: "Was erforderlich ist"
SYNTHESIS_COMPETITIVE_INTELLIGENCE: "Strategische Implikationen"
SYNTHESIS_STRATEGIC_FORESIGHT: "Die anstehenden Entscheidungen"
SYNTHESIS_INDUSTRY_TRANSFORMATION: "Führungspositionierung"
SYNTHESIS_TREND_PANORAMA: "Strategische Grundlagen"
SYNTHESIS_THEME_THESIS: "Aggregierter Investitionsfall"
```

## Brückenabsatz-Bezeichnungen

```text
BRIDGE_LABEL: "Strategische Verknüpfung"
PHASE_2_BRIDGES_START: "Generiere Brückenabsätze zwischen Handlungsfeldern..."
PHASE_2_SYNTHESIS_START: "Schreibe Synthese-Abschnitt..."
PHASE_2_BRIDGE_WRITTEN: "Brücke {N}→{N+1}: {FROM_NAME} → {TO_NAME}"
PHASE_2_SYNTHESIS_WRITTEN: "Synthese-Abschnitt geschrieben"
```

## Phasenmeldungen (Handlungsfeld-Modus)

```text
PHASE_0_INVESTMENT_THEMES_FOUND: "Wertmodell erkannt: {COUNT} Handlungsfelder verfügbar — verwende Handlungsfeld-organisierten Bericht"
PHASE_2_INVESTMENT_THEME_AGENT_DISPATCH: "Starte {COUNT} Handlungsfeld-Agenten..."
PHASE_2_INVESTMENT_THEME_AGENT_COMPLETE: "Handlungsfeld-Agent {N}/{TOTAL}: {NAME} ({WORDS} Wörter, {CITATIONS} Zitate)"
PHASE_2_INVESTMENT_THEME_AGENT_RETRY: "Wiederhole Handlungsfeld-Agent: {NAME}"
PHASE_2_INVESTMENT_THEME_AGENT_SKIP_RESUME: "Handlungsfeld {NAME} bereits geschrieben — überspringe Agent"
PHASE_2_INVESTMENT_THEME_START: "Stelle Handlungsfeld-Bericht zusammen..."
PHASE_2_INVESTMENT_THEME_WRITTEN: "Handlungsfeld {N}/{TOTAL}: {NAME}"
PHASE_2_INVESTMENT_THEME_COMPLETE: "Handlungsfeld-Bericht geschrieben: {PATH}"
```

## Kein-Daten-Markierung

```text
NO_QUANTITATIVE_DATA: "[Keine quantitativen Daten verfügbar]"
```

## Phasenmeldungen

```text
PHASE_0_START: "Lade Trend-Scout-Ergebnisse..."
PHASE_0_LOADED: "{COUNT} vereinbarte Kandidaten über 4 Dimensionen geladen"
PHASE_1_START: "Starte 4 Agenten für Evidenzanreicherung..."
PHASE_1_AGENT: "Agent {N}/4: {DIMENSION} ({COUNT} Trends)"
PHASE_1_COMPLETE: "Alle Agenten abgeschlossen: {CLAIMS} Aussagen aus {SEARCHES} Suchen extrahiert"
PHASE_2_START: "Stelle Trendbericht zusammen..."
PHASE_2_COMPLETE: "Bericht geschrieben: {PATH}"
PHASE_3_ASK: "{COUNT} quantitative Aussagen wurden extrahiert. Möchten Sie diese jetzt verifizieren?"
PHASE_3_VERIFY: "Jetzt verifizieren (Empfohlen)"
PHASE_3_SKIP: "Verifizierung überspringen"
PHASE_3_RUNNING: "Führe Aussagenverifizierung durch..."
PHASE_3_RESULT: "Verifizierung abgeschlossen: {VERDICT} ({PASSED} bestanden, {FAILED} fehlgeschlagen, {REVIEW} Überprüfung)"
PHASE_4_COMPLETE: "Trendbericht abgeschlossen"
```
