# Deutsche Beschriftungen für Trend-Synthese

Language: `de`

> **Hinweis:** Pruned auf Synthese-Stage. Recherche- und Booklet-Labels leben in den jeweiligen Schwester-Skills.

## Berichtstitel

```text
REPORT_TITLE: "{TITLE}"
REPORT_SUBTITLE: "{SUBTITLE}"
```

> **Titel:** Ein prägnanter Titel (max. 8 Wörter), abgeleitet aus dem Thema und
> den Handlungsfeldern. NICHT die Forschungsfrage — die wird zum Untertitel.
> **Untertitel:** Die Forschungsfrage (`{TOPIC}`), ggf. gekürzt für bessere Lesbarkeit.

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
CLAIMS_REGISTRY: "Quellenregister"
```

## Smarter-Service-Makroabschnitts-Beschriftungen

```text
MACRO_FORCES: "Kräfte — Externe Effekte"
MACRO_IMPACT: "Wirkung — Digitale Wertetreiber"
MACRO_HORIZONS: "Horizonte — Neue Horizonte"
MACRO_FOUNDATIONS: "Fundamente — Digitales Fundament"
```

## Smarter-Service-Synthese

```text
SYNTHESIS_HEADING_SMARTER_SERVICE: "Der Fähigkeitsimperativ"
UNIFIED_CAPABILITY_ROADMAP_LABEL: "Übergreifende Fähigkeits-Roadmap"
```

## Phase-2-Statusmeldungen

```text
PHASE_2_PRIMER_START: "Schreibe gemeinsamen Dimension-Primer (Smarter Service)..."
PHASE_2_PRIMER_WRITTEN: "Gemeinsamer Dimension-Primer geschrieben."
PHASE_2_THEME_CASE_AGENT_DISPATCH: "Theme-Case-Writer für {N} Handlungsfelder gestartet (schlanker 3-Beat-Modus)."
PHASE_2_THEME_CASE_AGENT_COMPLETE: "Theme-Case fertig: {theme_name}"
PHASE_2_THEME_CASE_AGENT_SKIP_RESUME: "Theme-Case übersprungen (Resume): {theme_name}"
PHASE_2_COMPOSER_DISPATCH: "Dimension-Composer wird gestartet: {dimension}..."
PHASE_2_COMPOSER_COMPLETE: "Dimension-Composer fertig: {dimension}"
PHASE_2_COMPOSER_SKIP_RESUME: "Dimension-Composer übersprungen (Resume): {dimension}"
PHASE_2_SYNTHESIS_START: "Schreibe Synthese-Abschnitt..."
PHASE_2_SYNTHESIS_WRITTEN: "Synthese-Abschnitt geschrieben"
PHASE_2_COMPLETE: "Bericht geschrieben: {PATH}"
PHASE_3_FINALIZE_COMPLETE: "Trend-Synthese abgeschlossen — bereit für /verify-trend-report"
```

## Theme-Case-Heading-Helfer

```text
STRATEGIC_QUESTION_LABEL: "Strategische Frage"
EXECUTIVE_SPONSOR: "Verantwortlicher Sponsor"
SECONDARY_CALLOUT_PATTERN: "→ Siehe auch Handlungsfeld {N} unter {macro_section} für die {topic}-Abhängigkeit."
THEME_CASE_REFERENCE_PATTERN: "→ Siehe auch Handlungsfeld {N} unter {Macro Section}"
```

## Handlungsfeld-Standard-Beschriftungen (an Writer-Agenten weitergereicht)

```text
INVESTMENT_THEME: "Handlungsfeld"
STRATEGIC_QUESTION: "Strategische Fragestellung"
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
REFERENCES_BLOCK_LABEL: "Referenzbeispiele"
```

## Quellenregister

```text
CLAIMS_REGISTRY_INTRO: "Alle quantitativen Aussagen aus diesem Bericht mit ihren Quell-URLs."
CLAIM: "Aussage"
VALUE: "Wert"
SOURCE: "Quelle"
DIMENSION_LABEL: "Dimension"
INVESTMENT_THEME_LABEL: "Handlungsfeld"
CLAIMS: "Aussagen"
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
LENGTH_TIER_MAXIMUM_DESC: "Ausführlicher Fließtext, volle Evidenz pro Handlungsfeld-Case."
LENGTH_TIER_CUSTOM_DESC: "Per Automation in tips-project.json vorgegeben. Grenzen: 2.500 ≤ target_words ≤ 12.000 Fließtext-Wörter."
LENGTH_BUDGET_REBALANCED_NOTE: "Hinweis: Das Dimension-Narrativ-Budget wurde unter die anfängliche 12%-Allokation gesenkt, damit die Per-Handlungsfeld-Ziele Headroom über dem strukturellen Floor (Stake 80 + Move 130 + Cost 80 = 290) erhalten. Die Composer-Agenten halten weiterhin den 250-Wörter-Floor pro Dimension ein."
LENGTH_BUDGET_FLOOR_WARNING: "Warnung: Das Per-Handlungsfeld-Ziel bindet auch nach Umverteilung der Dimension-Narrative am strukturellen Floor (290 Wörter = Stake 80 + Move 130 + Cost 80). Die Handlungsfeld-Fälle werden voraussichtlich 30–60 % über dem Ziel landen und der Gesamtbericht kann das Tier-Wortziel überschreiten. Empfehlung: Erweitert-Tier wählen oder auf ≤5 Handlungsfelder konsolidieren."
```

> Die Längenangaben beziehen sich auf den *Fließtext* — Zusammenfassung + Makroabschnitte + Synthese. Das Quellenregister fügt je nach Anzahl der Aussagen weitere ~1.500–3.500 Wörter hinzu.
