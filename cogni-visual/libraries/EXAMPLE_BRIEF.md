---
type: presentation-brief
version: "4.0"
theme: smarter-service
theme_path: "/cogni-workplace/themes/smarter-service/theme.md"
customer: "Deutsche Bahn AG"
provider: "TechVision Solutions"
language: "de"
generated: "2026-02-09"
arc_type: "why-change"
arc_id: "corporate-visions"
governing_thought: "Deutsche Bahn braucht KI-Videoanalytik, weil manuelle Überwachung die Sicherheitskrise nicht bewältigen kann."
confidence_score: 0.87
transformation_notes: |
  Story-to-slides transformation.
  Theme: smarter-service
  Arc type: why-change
  10 slides generated with 87% average confidence.
  Copywriting: 6 number plays, 10 headlines optimized.
  Diagram slides: 2 (layered-architecture, gantt-chart).
---

# Example Presentation Brief (v4.0 Content-Only Schema)

This example demonstrates the v4.0 content-only slide specification schema. All color fields are absent — the PPTX skill reads the theme directly for all visual decisions.

# PPTX-Rendering-Anforderungen
- Texte und Zahlen sind freigegeben und exakt zu übernehmen; Abweichungen führen zu einer fehlerhaften Präsentation.
- Notizen für Slides müssen vollständig übernommen werden; gekürzte Notizen führen zu einer fehlerhaften Präsentation.
- Quellenangaben müssen mit funktionierenden Links erhalten bleiben; eine Präsentation ohne Quellenlinks ist fehlerhaft.
- Hochgestellte Links wie <sup>[1](url)</sup> müssen als PPTX-Hyperlinks mit der Zahl als Anzeigetext in Hochstellung erstellt werden; nicht umgesetzte Links sind Fehler.

---

## Slide 1: Krise im deutschen Bahnnetz

```yaml
Layout: title-slide

Title: Krise im deutschen Bahnnetz
Subtitle: Warum manuelle Überwachung nicht mehr ausreicht
Metadata: Deutsche Bahn AG | TechVision Solutions | Februar 2026
```

**Notes**: Title and closing slides use fixed layouts with no additional fields beyond Title, Subtitle, and Metadata.

---

## Slide 2: Pitch-Methodik

```yaml
Layout: process-flow

Slide-Title: Pitch-Methodik

Diagram: |
  graph LR
    P0["Buying Center"] --> P1["Why Change"]
    P1 --> P2["Why Now"]
    P2 --> P3["Why You"]
    P3 --> P4["Why Pay"]

Detail-Grid:
  P0:
    - "Economic Buyer"
    - "Technical Evaluator"
    - "End Users"
    - "Champion & Blocker"
  P1:
    - "Sicherheitskrise"
    - "688 Menschenleben"
    - "Veraltete Infrastruktur"
    - "Aha-Moment"
  P2:
    - "EU-Frist 2026"
    - "Wettbewerbsdruck"
    - "Technologiereife"
  P3:
    - "KI-Plattform erprobt"
    - "München-Pilot Erfolg"
    - "87% Erkennungsvorteil"
  P4:
    - "3-Stufen-Investition"
    - "34-Wochen-Rollout"
    - "18-Monate Payback"

Bottom-Banner:
  Text: "INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN"

Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Diese Folie ist Ihr Vortragsfahrplan — die 5-Phasen-Pipeline zeigt die Argumentationslogik Ihrer Präsentation."
  [Kernaussage]: "Arc-Typ 'Why Change' bedeutet: Sie sind der Provokateur. Erst erzeugen Sie Unbehagen, dann bieten Sie Erleichterung."
  [Kernaussage]: "Jede Phase hat einen argumentativen Zweck — die Detail-Boxen zeigen die Schlüsselkonzepte pro Phase."
  [Überleitung]: "Schauen Sie sich nun das Buying Center an — es zeigt Ihnen die Stakeholder-Karten für Ihre Vorbereitung."

  >> WAS SIE WISSEN MÜSSEN

  - Diese Folie ist nur für Ihre Vorbereitung — entfernen Sie sie vor der Kundenpräsentation
  - Arc-Typ "why-change" bedeutet Ihre Rolle: Provokateur (Unbehagen erzeugen, dann Erleichterung bieten)
  - Die These ist Ihr Kompass — jede Folie treibt auf diese Schlussfolgerung zu
  - Zeitschätzung: 10 Folien × ~100 Sek. = ca. 15 Minuten

  - Folien-Fahrplan mit Pacing:
    Folie 4: problem — 688 Menschenleben (PEAK — verlangsamen, Blickkontakt, Zahl wirken lassen)
    Folie 5: problem — 73% Infrastruktur veraltet
    Folie 6: evidence — Vier Krisenquadranten
    Folie 7: solution — KI-Videoanalytik (RELEASE — Tonwechsel zu Zuversicht)
    Folie 8: proof — Manuell vs. KI
    Folie 9: options — Drei Einstiegsoptionen
    Folie 10: solution — Edge-to-Cloud Architektur
    Folie 11: roadmap — Gantt Projektplan
```

**Notes**: Slide 2 (Methodology) is an internal prep slide — always generated. Uses `process-flow` with `Detail-Grid` to show the arc phases as a visual pipeline. PEAK/RELEASE pacing in Speaker-Notes. Not counted against `max_slides`.

---

## Slide 3: Buying Center

```yaml
Layout: four-quadrants

Slide-Title: Buying Center

Q1:
  Label: "Economic Buyer"
  Sublabel: "CFO Infrastruktur"
  Bullets:
    - "Führen mit: ROI und Risikoreduktion"
    - "Kostenreduktion ist Top-Priorität"
    - "Alle Antworten in ROI-Begriffen"

Q2:
  Label: "Technical Evaluator"
  Sublabel: "CTO / IT-Leiter"
  Bullets:
    - "Führen mit: Integrationsfähigkeit"
    - "Open-Source-Architektur betonen"
    - "Legacy-Kompatibilität adressieren"

Q3:
  Label: "End Users"
  Sublabel: "Leitstelle, Sicherheitspersonal"
  Bullets:
    - "Führen mit: Workflow-Vereinfachung"
    - "Minimale Umstellung im Schichtbetrieb"
    - "Schulungskonzept bereithalten"

Q4:
  Label: "Champion"
  Sublabel: "Leiter Digitalisierung"
  Bullets:
    - "Führen mit: Transformationsmandat"
    - "Vorzeigeprojekt für seine Agenda"
    - "Als internen Fürsprecher aktivieren"

Bottom-Banner:
  Text: "INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN"

Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Diese Folie zeigt Ihnen jeden Stakeholder als Karte — Rolle, Titel, Führungsstrategie und Kernbotschaften."
  [Kernaussage]: "Der CFO Infrastruktur ist Ihr Economic Buyer — formulieren Sie JEDE Antwort in ROI-Begriffen."
  [Kernaussage]: "Der Leiter Digitalisierung ist Ihr Champion — nutzen Sie sein Transformationsmandat als internen Hebel."
  [Kernaussage]: "Betriebsrat ist Ihr größtes Risiko — Fokus auf Sicherheit, nicht auf Überwachung."
  [Überleitung]: "Die Präsentation beginnt jetzt — starten Sie mit Überzeugung."

  >> WAS SIE WISSEN MÜSSEN

  - Diese Folie ist nur für Ihre Vorbereitung — entfernen Sie sie vor der Kundenpräsentation
  - Primärer Entscheidungsträger: CFO Infrastruktur — alle Antworten in ROI/Risiko-Begriffen formulieren
  - Champion (Leiter Digitalisierung) ist Ihr Verbündeter — nutzen Sie dessen Motivation als Hebel
  - Größtes Risiko: Betriebsrat — Personalabbau-/Überwachungsbedenken können den Deal blockieren
  - Pitch-Fokus: [EB] → ROI, [TE] → Integration, [EU] → Workflow
```

**Notes**: Slide 3 (Buying Center) is an internal prep slide — conditional, only generated when buying center data is available (Why Change projects with pitch-log.json or phase-0-buyer-map.md). Uses `four-quadrants` in text-card mode. Not counted against `max_slides`.

---

## Slide 4: 688 Menschenleben jährlich durch vermeidbare Schienenunfälle

```yaml
Layout: stat-card-with-context

Slide-Title: 688 Menschenleben jährlich durch vermeidbare Schienenunfälle

Hero-Stat-Box:
  Number: 688
  Label: Schienensuizide jährlich
  Sublabel: + 2.661 Übergriffe auf Bahnhöfen
  Icon: shield

Impact-Box:
  Text: Deutschland führt EU-Statistik an

Context-Box:
  Headline: Warum manuelle Überwachung versagt
  Bullets:
    - Sicherheitspersonal kann nicht alle Bereiche 24/7 abdecken <sup>[1](https://www.eba.bund.de/sicherheitsbericht-2024)</sup>
    - Kritische Ereignisse werden zu spät erkannt <sup>[2](https://www.bka.de/kriminalstatistik)</sup>
    - Das Netzwerk ist zu groß für punktuelle Überwachung

Bottom-Banner:
  Text: Deutschland führt die EU-Statistik an

cta:
  text: "Sicherheitslage Ihres Netzes bewerten"
  type: evaluate
  urgency: medium

Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Fragen Sie das Publikum: 'Wie viele vermeidbare Todesfälle gibt es jährlich auf deutschen Schienen?' Lassen Sie raten, bevor Sie die Zahl zeigen."
  [Kernaussage]: "Die 688 ist ein 3-Jahres-Durchschnitt — und der Trend ist alarmierend: 612, dann 679, jetzt 773."
  [Kernaussage]: "Manuelle Überwachung kann ein Netz von 33.000 km schlicht nicht abdecken — kritische Ereignisse werden zu spät erkannt."
  [Pause]: Lassen Sie die Zahl wirken, bevor Sie fortfahren.
  [Überleitung]: "Diese Zahlen machen die Dringlichkeit unmissverständlich..."

  >> WAS SIE WISSEN MÜSSEN

  - Quelle: 688 ist ein 3-Jahres-Durchschnitt (2021-2023) aus dem [Bundesbericht Schienensicherheit 2024](https://www.eba.bund.de/sicherheitsbericht-2024). Trend: 612 (2021) → 679 (2022) → 773 (2023).
  - Deutschland hat die höchsten absoluten EU-Zahlen, Pro-Kopf vergleichbar mit Frankreich.
  - Bei Rückfrage zu regionalen Unterschieden: Bayern hat 23% der Vorfälle.
  - Die 2.661 Bahnhofsübergriffe stammen aus der BKA-Kriminalstatistik, nicht aus Bahnsicherheitsdaten.
  - Methodik: EBA zählt alle Vorfälle im Umkreis von 500m der Gleise.

Source: "[Bundesbericht Schienensicherheit 2024](https://www.eba.bund.de/sicherheitsbericht-2024)"
```

---

## Slide 5: 42% der Überwachungssysteme sind veraltet

```yaml
Layout: stat-card-with-context

Slide-Title: 42% der Überwachungssysteme sind veraltet

Hero-Stat-Box:
  Number: 42%
  Label: Veraltete Überwachungssysteme
  Sublabel: Durchschnittsalter 18+ Jahre
  Icon: wrench

Context-Box:
  Headline: Warum Updates scheitern
  Bullets:
    - Analoge Technik nicht skalierbar
    - Wartungskosten steigen exponentiell
    - Integration neuer Lösungen unmöglich

Bottom-Banner:
  Text: Jährlich €12M für veraltete Technik

Source: "[DB Infrastruktur Report 2024](https://www.deutschebahn.com/infrastruktur-report)"
```

---

## Slide 6: Vier kritische Handlungsfelder erfordern sofortige Intervention

```yaml
Layout: four-quadrants

Slide-Title: Vier kritische Handlungsfelder

Quadrant-1:
  Number: 688
  Label: Sicherheit
  Sublabel: Suizide p.a.
  Icon: shield

Quadrant-2:
  Number: 42%
  Label: Infrastruktur
  Sublabel: Veraltete Systeme
  Icon: wrench

Quadrant-3:
  Number: 156%
  Label: Kapazität
  Sublabel: Überlastung
  Icon: users

Quadrant-4:
  Number: €2.8M
  Label: Kosten
  Sublabel: Notfall-OPs
  Icon: euro

Bottom-Banner:
  Text: Alle Bereiche benötigen sofortige Intervention
```

---

## Slide 7: KI-Videoanalytik reduziert kritische Vorfälle um 73%

```yaml
Layout: is-does-means

Slide-Title: KI-Videoanalytik für Bahnsicherheit

IS-Box:
  Label: IS
  Text: Eine KI-gestützte Plattform für automatisierte Echtzeit-Überwachung von Bahninfrastruktur

DOES-Box:
  Label: DOES
  Text: Analysiert 24/7 Videomaterial, erkennt kritische Ereignisse (Personen auf Gleisen, Vandalismus, unbefugter Zugang) und sendet Echtzeitwarnungen

MEANS-Box:
  Label: MEANS
  Text: Computer Vision Modelle (YOLOv8, Faster R-CNN) + Anomaly Detection + Edge Computing für <2s Latenz

Bottom-Banner:
  Text: Reduziert kritische Vorfälle um 73% in ersten 6 Monaten

cta:
  text: "Live-Demo der KI-Analyse anfragen"
  type: evaluate
  urgency: medium
```

---

## Slide 8: KI-Überwachung senkt Reaktionszeit um 87% bei 60% Kosteneinsparung

```yaml
Layout: two-columns-equal

Slide-Title: Manuell vs. KI-gestützt

Left-Column:
  Headline: Manuelle Überwachung
  Bullets:
    - 24/7 Personal erforderlich
    - Reaktiv statt proaktiv
    - Keine Mustererkennung
    - Hohe Personalkosten
    - Begrenzte Skalierung

Right-Column:
  Headline: KI-Videoanalyse
  Bullets:
    - Automatische 24/7 Überwachung
    - Proaktive Warnungen
    - Lernende Mustererkennung
    - Skalierbare Lösung
    - 60% Kosteneinsparung

Bottom-Banner:
  Text: KI reduziert Reaktionszeit um 87% bei 60% Kosteneinsparung

Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Stellen Sie den direkten Vergleich her: 'Was kostet Sie jede Minute Reaktionsverzögerung?' Die Gegenüberstellung macht den Unterschied greifbar."
  [Kernaussage]: "Links sehen Sie den Status quo — rechts, was KI-gestützte Überwachung heute schon leistet."
  [Kernaussage]: "48 Stunden vs. 15 Minuten Reaktionszeit — das ist nicht inkrementell, das ist ein Paradigmenwechsel."
  [Betonung]: Betonen Sie die 87% — das ist die Zahl, die im Gedächtnis bleibt.
  [Überleitung]: "Wie könnte eine schrittweise Einführung bei Ihnen aussehen?"

  >> WAS SIE WISSEN MÜSSEN

  - Manuelle Überwachung erfordert 3-Schicht-Betrieb mit mindestens 4 FTE pro Standort. KI skaliert ohne linearen Personalaufbau.
  - Die 87% Reaktionszeitreduktion basiert auf Pilotprojekten an 12 Bahnhöfen (2024-2025).
  - Kosteneinsparung von 60% bezieht sich auf Total Cost of Ownership über 5 Jahre (inkl. Hardware, Wartung, Personal).
  - Bei Rückfrage zu Fehlalarmen: False-Positive-Rate liegt bei 2,3% nach 6 Monaten Lernphase.
  - Bei Rückfrage zu Datenschutz: Alle Videoströme werden lokal verarbeitet, keine Cloud-Übertragung.
```

---

## Slide 9: Regionale Rollout bietet optimales Kosten-Nutzen-Verhältnis

```yaml
Layout: three-options

Slide-Title: Rollout-Strategien im Vergleich

Option-1:
  Name: Pilot (3 Monate)
  Price: €50k
  Features:
    - 5 Bahnhöfe
    - 20 Kameras
    - Basisanalyse
    - Proof of Concept

Option-2:
  Name: Regional (12 Monate)
  Price: €280k
  Badge: Empfohlen
  Features:
    - 25 Bahnhöfe
    - 150 Kameras
    - Erweiterte Analysen
    - 24/7 Monitoring
    - Integration DB-Systeme

Option-3:
  Name: National (36 Monate)
  Price: €1.2M
  Features:
    - 100+ Bahnhöfe
    - 800+ Kameras
    - KI-Training
    - Zentrale Leitstelle
    - Vollintegration

Bottom-Banner:
  Text: Regionale Rollout bietet optimales Kosten-Nutzen-Verhältnis
```

---

## Slide 10: Edge-to-Cloud in 3 Schichten — Videodaten bleiben lokal

```yaml
Layout: layered-architecture

Slide-Title: Edge-to-Cloud in 3 Schichten — Videodaten bleiben lokal

Diagram: |
  graph LR
    subgraph Edge["Edge"]
      A["IP-Kameras + Jetson AI"]
    end
    subgraph Cloud["Open Telekom Cloud"]
      B["Kafka Streaming"]
      C["KI-Analyse-Engine"]
      D["PostgreSQL + Redis"]
    end
    subgraph Operations["Operations"]
      E["Dashboard + Grafana"]
      F["Alerting"]
    end
    A -->|Metadaten| B
    B --> C
    C --> D
    C --> E
    C -.->|Alarme| F

Bottom-Banner:
  Text: Strikte Trennung Edge/Cloud — keine Videoübertragung in die Cloud

Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Lassen Sie mich Ihnen zeigen, wie die Lösung technisch aufgebaut ist — in nur drei Schichten."
  [Kernaussage]: "Entscheidend ist die Trennung: Videodaten bleiben auf dem Edge-Device. Nur Metadaten gehen in die Cloud."
  [Betonung]: Betonen Sie den Datenschutz-Aspekt — DSGVO-Konformität ohne Kompromisse.
  [Überleitung]: "Mit diesem Architekturansatz können wir den Piloten in 6 Wochen starten..."

  >> WAS SIE WISSEN MÜSSEN

  - Vollständige Architektur: 5 Schichten, 12 Komponenten (vereinfacht für Folie)
  - Edge: NVIDIA Jetson Orin NX + IP67-Industriekameras (RTSP-Streams)
  - Messaging: Eclipse Mosquitto MQTT Broker → Apache Kafka Event Streaming
  - Daten: PostgreSQL (persistent) + Redis (Stream Cache) auf Open Telekom Cloud
  - Integration: Grafana Enterprise für Monitoring, MS Teams für Alerting
  - Rückfrage Datenschutz: DSGVO-konform — Videoströme werden lokal verarbeitet, nur anonymisierte Metadaten in die Cloud
  - Rückfrage Vendor Lock-in: Alle Komponenten sind Open-Source-basiert (Kafka, PostgreSQL, Grafana)
```

**Notes**: Architecture diagram slides use the `Diagram:` field with Mermaid `graph LR` source. The Mermaid text is pre-simplified from a complex solution sketch (5 layers, 12 nodes) to 3 lanes with 6 nodes. Full architecture detail lives in Speaker-Notes. The PPTX skill renders the Mermaid as native editable shapes (rounded rectangles + arrow connectors), not as an image.

---

## Slide 11: In 34 Wochen vom PoV zum Pilotbetrieb

```yaml
Layout: gantt-chart

Slide-Title: In 34 Wochen vom PoV zum Pilotbetrieb

Diagram: |
  gantt
    dateFormat YYYY-MM-DD
    section Phase 1
    Proof of Value      :done, pov, 2026-03-01, 42d
    section Phase 2
    Small Scale Pilot   :active, ssp, 2026-04-12, 84d
    section Phase 3
    Medium Scale        :ms, 2026-07-05, 56d
    section Phase 4
    Enterprise Rollout  :er, 2026-08-30, 84d

Bottom-Banner:
  Text: Jede Phase liefert eigenständigen Geschäftswert — kein Big-Bang-Risiko
```

**Notes**: Gantt chart slides use the `Diagram:` field with Mermaid `gantt` source. The PPTX skill renders phase labels on the left and horizontal time bars on the right. Bar colors reflect status: `done` (muted), `active` (accent border), unmarked (future, dashed). Simplified from a detailed project plan — individual tasks grouped into phase-level bars.

---

## Slide 12: Handeln Sie jetzt — Förderfenster schließt

```yaml
Layout: closing-slide

Title: Handeln Sie jetzt — Förderfenster schließt
Subtitle: Pilotprojekt in 6 Wochen starten
Metadata: kontakt@techvision.de | +49 123 456 789
```

---

## CTA Summary

```yaml
cta_proposals:
  - text: "Pilotprojekt in 6 Wochen starten"
    type: commit
    urgency: high
    supporting_sections: [8, 9, 11]
  - text: "Live-Demo der KI-Analyse anfragen"
    type: evaluate
    urgency: medium
    supporting_sections: [7, 10]
  - text: "Sicherheitslage Ihres Netzes bewerten"
    type: evaluate
    urgency: medium
    supporting_sections: [4, 5, 6]
  - text: "Analyse an Ihre Geschäftsführung weiterleiten"
    type: share
    urgency: medium
    supporting_sections: [4, 8]
  - text: "Bundesbericht Schienensicherheit einsehen"
    type: explore
    urgency: low
    supporting_sections: [4, 5]

primary_cta: "Pilotprojekt in 6 Wochen starten"
conversion_goal: "consultation"
```

---

## Key Differences from v2.0/v3.0

| Aspect | v2.0/v3.0 (Old) | v4.0 (Current) |
|--------|-----------------|----------------|
| Color fields | `Background: danger`, `Text-Color: textLight` on every element | Absent — PPTX skill decides |
| Theme reference | `theme_context` block with tokens, color_mode, font | `theme_path` pointing to compact theme.md |
| Visual intent | Mechanical token mapping | Theme-driven — PPTX skill reads theme.md |
| PPTX skill latitude | Zero — follows exact tokens | Full — reads theme for all visual decisions |
| Brief version | `"2.0"` or `"3.0"` | `"4.0"` |

**Backward compatibility:** The PPTX skill still accepts v2.0/v3.0 briefs with explicit color fields. When color fields are present, they take precedence over theme-based inference.

---
