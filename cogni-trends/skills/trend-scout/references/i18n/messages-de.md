# German Message Catalog for Trend Scout

Language: `de`

## Phase 0: Initialisierung

### Branchenauswahl

```text
INDUSTRY_SELECTION_TITLE: "Wählen Sie Ihre Branche für TIPS-Scouting"
INDUSTRY_SELECTION_INTRO: "Bitte wählen Sie Ihre Branche und Ihren Teilsektor, um mit dem Trend-Scouting zu beginnen:"
INDUSTRY_SELECTION_PROMPT: "Geben Sie Ihre Auswahl ein (z.B. '1a' für Fertigung - Automobil):"
INDUSTRY_SELECTION_INVALID: "Ungültige Auswahl. Bitte geben Sie einen gültigen Branchen- und Teilsektorcode ein (z.B. '1a')."
```

### Themen-Eingabe

```text
TOPIC_PROMPT_TITLE: "Forschungsthema"
TOPIC_PROMPT_INTRO: "Welches spezifische Thema oder welchen Schwerpunkt möchten Sie innerhalb von {INDUSTRY} - {SUBSECTOR} untersuchen?"
TOPIC_PROMPT_EXAMPLE: "Beispiel: 'KI-gesteuerte prädiktive Wartung', 'Nachhaltige Lieferkette', 'Digitale Kundenerfahrung'"
TOPIC_PROMPT_ENTER: "Geben Sie Ihr Forschungsthema ein:"
```

### Portfolio-Erkennung

```text
PORTFOLIO_DISCOVERY_HEADER: "Portfolio-Projekt-Erkennung"
PORTFOLIO_DISCOVERY_INTRO: "Ich habe bestehende Portfolio-Projekte in Ihrem Workspace gefunden. Sie können direkt für einen dieser Märkte Trend-Scouting starten — Branche, Teilsektor und Forschungsschwerpunkt werden aus Ihrem Portfolio vorausgefüllt."
PORTFOLIO_DISCOVERY_PROJECT: "Portfolio: {COMPANY_NAME} ({INDUSTRY})"
PORTFOLIO_DISCOVERY_MARKET: "{MARKET_NAME} ({REGION}) — Vertikalen: {VERTICALS} [Übereinstimmung: {ALIGNMENT}]"
PORTFOLIO_DISCOVERY_SELECT: "Wählen Sie einen Markt zum Vorausfüllen, oder wählen Sie 'Manuelle Auswahl' für die vollständige Branchentaxonomie:"
PORTFOLIO_DISCOVERY_MANUAL: "Manuelle Auswahl — vollständige Branchentaxonomie verwenden"
PORTFOLIO_DISCOVERY_NONE: "Keine Portfolio-Projekte im Workspace gefunden. Weiter mit manueller Branchenauswahl."
PORTFOLIO_DISCOVERY_ASK_PATH: "Ich konnte keine Portfolio-Projekte finden. Haben Sie ein Arbeitsverzeichnis mit cogni-portfolio Projekten an einem anderen Ort?"
PORTFOLIO_DISCOVERY_SELECTED: "Vorausfüllung aus Portfolio-Markt: {MARKET_NAME}"
PORTFOLIO_DISCOVERY_TOPIC_SUGGEST: "Basierend auf dem gewählten Markt wäre ein mögliches Forschungsthema: '{TOPIC}'. Möchten Sie dieses verwenden oder ein eigenes eingeben?"
```

### Projektinitialisierung

```text
PROJECT_INIT_START: "Initialisiere Trend Scout Projekt..."
PROJECT_INIT_INDUSTRY: "Branche: {INDUSTRY}"
PROJECT_INIT_SUBSECTOR: "Teilsektor: {SUBSECTOR}"
PROJECT_INIT_TOPIC: "Thema: {TOPIC}"
PROJECT_INIT_SLUG: "Projekt-Slug: {SLUG}"
PROJECT_INIT_PATH: "Projektpfad: {PATH}"
PROJECT_INIT_SUCCESS: "Projekt erfolgreich initialisiert."
PROJECT_INIT_FAILED: "Projektinitialisierung fehlgeschlagen: {ERROR}"
```

---

## Phase 1: Web-Recherche

```text
WEB_RESEARCH_START: "Starte zweisprachige Web-Recherche..."
WEB_RESEARCH_DIMENSION: "Suche {DIMENSION} ({REGION})..."
WEB_RESEARCH_PROGRESS: "{COMPLETED}/{TOTAL} Suchen abgeschlossen"
WEB_RESEARCH_SIGNALS: "{COUNT} Trendsignale aus {DIMENSION} extrahiert"
WEB_RESEARCH_SUCCESS: "Web-Recherche abgeschlossen: {TOTAL} Signale über alle Dimensionen extrahiert"
WEB_RESEARCH_PARTIAL: "Web-Recherche teilweise abgeschlossen: {SUCCESS}/{TOTAL} Suchen erfolgreich"
WEB_RESEARCH_FAILED: "Web-Recherche fehlgeschlagen. Fahre nur mit Trainingswissen fort."
WEB_RESEARCH_DISABLED: "Web-Recherche deaktiviert. Verwende nur Trainingswissen."
```

---

## Phase 2: Kandidatengenerierung

```text
GENERATION_START: "Generiere Trendkandidaten für {INDUSTRY} - {SUBSECTOR}..."
GENERATION_CONTEXT: "Verwende {WEB_COUNT} Web-Signale"
GENERATION_PROGRESS: "Generiere Kandidaten für {DIMENSION} - {HORIZON}..."
GENERATION_COMPLETE: "{TOTAL} webfundierte Kandidaten generiert"
```

---

## Phase 3: Präsentation

```text
PRESENT_WRITING: "Schreibe trend-candidates.md..."
PRESENT_SUCCESS: "Kandidatendatei geschrieben nach: {PATH}"
PRESENT_COMPLETE: "Alle {TOTAL} Kandidaten automatisch finalisiert. Weiter zur Finalisierung."
```

---

## Phase 4: Finalisierung

```text
FINALIZE_START: "Finalisiere vereinbarte Kandidaten..."
FINALIZE_CONFIG: "Schreibe trend-scout-config.md..."
FINALIZE_JSON: "Schreibe agreed-trend-candidates.json..."
FINALIZE_UPDATE: "Aktualisiere trend-candidates.md Status auf 'agreed'..."
FINALIZE_SUCCESS_TITLE: "Trend Scout abgeschlossen"
FINALIZE_SUCCESS_SUMMARY: |
  {COUNT} Trendkandidaten erfolgreich finalisiert.

  Ausgabedateien:
  - Konfiguration: {CONFIG_PATH}
  - Kandidaten: {CANDIDATES_PATH}

  Nächster Schritt: Rufen Sie `/value-modeler` auf, um TIPS-Beziehungsnetzwerke und priorisierte Lösungsvorlagen zu erstellen, oder `/trend-report` für einen direkten narrativen Trendbericht.
  Die Konfiguration wird automatisch geladen.
```

---

## Fehlermeldungen

```text
ERROR_NO_INDUSTRY: "Branchenauswahl erforderlich. Bitte wählen Sie eine Branche und einen Teilsektor."
ERROR_NO_TOPIC: "Forschungsthema erforderlich. Bitte geben Sie ein Thema oder einen Schwerpunkt an."
ERROR_PROJECT_EXISTS: "Ein Projekt mit diesem Slug existiert bereits. Verwenden Sie ein anderes Thema oder löschen Sie das vorhandene Projekt."
ERROR_FILE_NOT_FOUND: "Datei nicht gefunden: {PATH}"
ERROR_PARSE_FAILED: "Fehler beim Parsen von {FILE}: {ERROR}"
ERROR_VALIDATION_FAILED: "Validierung fehlgeschlagen: {ERROR}"
```

---

## Dimensionsnamen

```text
DIMENSION_EXTERNE_EFFEKTE: "Externe Effekte"
DIMENSION_NEUE_HORIZONTE: "Neue Horizonte"
DIMENSION_DIGITALE_WERTETREIBER: "Digitale Wertetreiber"
DIMENSION_DIGITALES_FUNDAMENT: "Digitales Fundament"

HORIZON_ACT: "Handeln (0-2 Jahre)"
HORIZON_PLAN: "Planen (2-5 Jahre)"
HORIZON_OBSERVE: "Beobachten (5+ Jahre)"
```

---

## Subkategorienamen

```text
# Externe Effekte Subkategorien
SUBCATEGORY_WIRTSCHAFT: "Wirtschaft"
SUBCATEGORY_WIRTSCHAFT_FOCUS: "Marktkräfte, Wettbewerb, wirtschaftliche Faktoren"
SUBCATEGORY_REGULIERUNG: "Regulierung"
SUBCATEGORY_REGULIERUNG_FOCUS: "Politik, Compliance, rechtliche Rahmenbedingungen"
SUBCATEGORY_GESELLSCHAFT: "Gesellschaft"
SUBCATEGORY_GESELLSCHAFT_FOCUS: "Demografie, gesellschaftliche Veränderungen"

# Neue Horizonte Subkategorien
SUBCATEGORY_STRATEGIE: "Strategie"
SUBCATEGORY_STRATEGIE_FOCUS: "Geschäftsmodellausrichtung, strategische Ziele"
SUBCATEGORY_FUEHRUNG: "Führung"
SUBCATEGORY_FUEHRUNG_FOCUS: "Führungsansätze, organisatorischer Wandel"
SUBCATEGORY_STEUERUNG: "Steuerung"
SUBCATEGORY_STEUERUNG_FOCUS: "Governance, Analytik, Kontrollsysteme"

# Digitale Wertetreiber Subkategorien
SUBCATEGORY_CUSTOMER_EXPERIENCE: "Kundenerlebnis"
SUBCATEGORY_CUSTOMER_EXPERIENCE_FOCUS: "Kundenkontaktpunkte, Engagement"
SUBCATEGORY_PRODUKTE_SERVICES: "Produkte & Services"
SUBCATEGORY_PRODUKTE_SERVICES_FOCUS: "Angebote, Produktinnovation"
SUBCATEGORY_GESCHAEFTSPROZESSE: "Geschäftsprozesse"
SUBCATEGORY_GESCHAEFTSPROZESSE_FOCUS: "Betrieb, Prozessoptimierung"

# Digitales Fundament Subkategorien
SUBCATEGORY_KULTUR: "Kultur"
SUBCATEGORY_KULTUR_FOCUS: "Organisationskultur, Denkweise"
SUBCATEGORY_MITARBEITENDE: "Mitarbeitende"
SUBCATEGORY_MITARBEITENDE_FOCUS: "Belegschaft, Fähigkeiten, Talente"
SUBCATEGORY_TECHNOLOGIE: "Technologie"
SUBCATEGORY_TECHNOLOGIE_FOCUS: "Tech-Infrastruktur, Plattformen"
```

---

## Tabellenkopfzeilen

```text
TABLE_HEADER_SELECT: "Auswahl"
TABLE_HEADER_NUMBER: "#"
TABLE_HEADER_NAME: "Name"
TABLE_HEADER_DESCRIPTION: "Beschreibung"
TABLE_HEADER_KEYWORDS: "Schlüsselwörter"
TABLE_HEADER_RATIONALE: "Begründung"
TABLE_HEADER_MORE: "Mehr?"
TABLE_HEADER_SOURCE: "Quelle"
```

---

## Eigene Vorschläge

```text
USER_PROPOSED_TITLE: "Eigene Vorschläge"
USER_PROPOSED_INSTRUCTIONS: |
  Fügen Sie unten Ihre eigenen Trendkandidaten hinzu. Folgen Sie dem Format:

  | [x] | {dimension} | {horizon} | {name} | {beschreibung} | {schlüsselwort1}, {schlüsselwort2}, {schlüsselwort3} | {begründung} |

  Beispiel:
  | [x] | externe-effekte | act | Mein Trend | Kurze Beschreibung des Trends | schlüssel1, schlüssel2, schlüssel3 | Warum dieser Trend wichtig ist |
```
