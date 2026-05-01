# Deutsche Beschriftungen für Trend-Recherche

Language: `de`

> **Hinweis:** Pruned auf Recherche-Stage. Synthese- und Booklet-Labels leben in den jeweiligen Schwester-Skills.

## Phasenmeldungen (Recherche)

```text
PHASE_0_START: "Lade Trend-Scout-Ergebnisse..."
PHASE_0_LOADED: "{COUNT} vereinbarte Kandidaten über 4 Dimensionen geladen"
PHASE_0_INVESTMENT_THEMES_FOUND: "Wertmodell erkannt: {COUNT} Handlungsfelder verfügbar"
PHASE_1_START: "Starte 4 Agenten für Evidenzanreicherung..."
PHASE_1_AGENT: "Agent {N}/4: {DIMENSION} ({COUNT} Trends)"
PHASE_1_COMPLETE: "Alle Agenten abgeschlossen: {CLAIMS} Aussagen aus {SEARCHES} Suchen extrahiert"
PHASE_2_RESEARCH_MANIFEST_WRITTEN: "Recherche-Manifest geschrieben: {PATH}"
PHASE_2_RESEARCH_COMPLETE: "Trend-Recherche abgeschlossen — bereit für /trend-synthesis oder /trend-booklet"
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

## Kein-Daten-Markierung

```text
NO_QUANTITATIVE_DATA: "[Keine quantitativen Daten verfügbar]"
```

## Deep-Research-Phase

```text
PHASE_DEEP_RESEARCH_OFFER: "Ich kann eine Tiefenrecherche für 3-5 hochwertige Trends durchführen, bevor der Bericht geschrieben wird. Das dauert ~5-10 Minuten länger, liefert aber reichere Evidenz mit quantitativen Daten."
PHASE_DEEP_RESEARCH_AUTO: "Tiefenrecherche der wichtigsten ACT-Horizont-Trends (empfohlen für Führungskräfte-Publikum)"
PHASE_DEEP_RESEARCH_SKIP: "Tiefenrecherche überspringen und mit Standard-Evidenzanreicherung fortfahren"
PHASE_DEEP_RESEARCH_PICK: "Spezifische Trends für Tiefenrecherche auswählen"
PHASE_DEEP_RESEARCH_DISPATCH: "{COUNT} Tiefenrecherche-Agenten parallel gestartet..."
PHASE_DEEP_RESEARCH_COMPLETE: "Tiefenrecherche abgeschlossen: {OK}/{TOTAL} Trends recherchiert"
```

## JSON-Validitäts-Gate

```text
PHASE_VALIDATE_TRENDS_PASS: "Alle 4 enriched-trends-JSON-Dateien gültig (repariert: {N})"
PHASE_VALIDATE_TRENDS_FAIL: "Enriched-trends-JSON nicht reparierbar: {FILE} (Zeile {LINE}, Spalte {COL}). Bitte den Writer-Agenten der betroffenen Dimension neu starten."
```
