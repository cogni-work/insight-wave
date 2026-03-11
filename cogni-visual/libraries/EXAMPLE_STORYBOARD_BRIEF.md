---
type: storyboard-brief
version: "2.0"
theme: smarter-service
theme_path: "/Users/stephandehaas/Library/CloudStorage/Dropbox/2025 InsightsWave/04 Kundenprojekte/cogni-workplace/themes/smarter-service/theme.md"
style_guide: "Corporate Tech"
customer: "Muller Werkzeugmaschinen GmbH"
provider: "SmartFactory Solutions"
language: "de"
generated: "2026-02-27"
arc_type: "why-change"
arc_id: "industry-transformation"
governing_thought: "Predictive Maintenance senkt ungeplante Stillstande um 73% und macht den Maschinenbau fit fur die nachste Dekade."
confidence_score: 0.88
industry: "maschinenbau"
poster_size: "A1"
poster_count: 4
poster_gap: 200
conversion_goal: "consultation"
base_width: 1440
base_height: 2036
print_width: 3508
print_height: 4961
scale_factor: 2.437
transformation_notes: |
  Story-to-storyboard v2.0 transformation.
  Theme: smarter-service. Style guide: Corporate Tech.
  Arc: why-change (industry-transformation).
  4 posters, each with 2 stacked web sections.
  Portrait only. Base resolution: 1440x2036.
  Reuses web section types with portrait adaptations.
---

# Storyboard Brief: Predictive Maintenance im Maschinenbau

Predictive Maintenance senkt ungeplante Stillstande um 73% und macht den Maschinenbau fit fur die nachste Dekade.

---

## Poster 1: Krafte (Why Change)

```yaml
poster_label: "Krafte"
sequence: "1/4"
sections: 2
height_allocation: [60, 40]

section_1:
  type: hero
  section_theme: dark
  height_percent: 60

  headline: "Predictive Maintenance macht Ihre Fertigung unaufhaltsam"
  subline: "Vom ungeplanten Stillstand zur intelligenten Fertigung"
  cta_text: "Erstgesprach buchen"
  section_label: "KRAFTE"

  image_prompt: |
    Wide panoramic industrial landscape illustration.
    Left side: traditional factory campus with sawtooth-roof production halls,
    old CNC machines visible through open bay doors, overcast sky.
    Right side: modern smart factory with glass-and-steel architecture,
    IoT antennas, bright sunlight.
    Transition zone in center showing modernization in progress.
    Color palette: cyan blue primary, signal orange accent, white background.
    Style: print resolution, high detail. No text, no people.

section_2:
  type: problem-statement
  section_theme: light
  height_percent: 40

  headline: "23 Tage Stillstand kosten 874.000 Euro pro Anlage"
  section_label: "DAS PROBLEM"

  stat_number: "23"
  stat_label: "Tage Stillstand/Jahr"
  stat_context: "pro CNC-Anlage im Durchschnitt"

  body: |
    Jede CNC-Anlage steht durchschnittlich 23 Tage pro Jahr ungeplant still.
    Bei 38.000 Euro Kosten pro Stillstandstag summiert sich der Verlust auf
    874.000 Euro jahrlich.

  bullets:
    - "38.000 Euro Kosten pro Stillstandstag"
    - "Verschleiss wird erst nach Ausfall erkannt"
    - "Wartungszyklen basieren auf starren Intervallen"

  cta:
    text: "Ihre Stillstandskosten berechnen"
    type: evaluate
    urgency: medium

  source: "[VDMA Produktionsausfallstudie 2025](https://www.vdma.org/produktionsausfall-studie)"
```

---

## Poster 2: Reibung (Why Now)

```yaml
poster_label: "Reibung"
sequence: "2/4"
sections: 2
height_allocation: [45, 55]

section_1:
  type: stat-row
  section_theme: dark
  height_percent: 45

  headline: "Drei Krisen treffen den Maschinenbau gleichzeitig"
  section_label: "WARUM JETZT"

  stats:
    - number: "64.000"
      label: "fehlende Fachkrafte bis 2028"
      icon: "users"
    - number: "1:5"
      label: "Reklamationen durch Qualitaetsdrift"
      icon: "triangle-alert"
    - number: "41%"
      label: "hoehere Instandhaltungskosten"
      icon: "trending-up"
    - number: "18+"
      label: "Monate Einarbeitungszeit"
      icon: "clock"

section_2:
  type: comparison
  section_theme: light
  height_percent: 55

  headline: "73% weniger Stillstand in der Pilotlinie bewiesen"
  section_label: "VORHER / NACHHER"

  left_label: "VORHER"
  left_headline: "Reaktive Wartung"
  left_bullets:
    - "23 Tage ungeplanter Stillstand"
    - "874.000 Euro Verlust pro Anlage"
    - "Verschleiss erst nach Ausfall erkannt"
    - "Starre Wartungsintervalle"

  right_label: "NACHHER"
  right_headline: "Predictive Maintenance"
  right_bullets:
    - "6 Tage geplanter Stillstand"
    - "41% geringere Instandhaltungskosten"
    - "14 Tage Vorwarnung vor Ausfall"
    - "Datengetriebene Wartungsfenster"

  cta:
    text: "Vergleichsanalyse fur Ihren Betrieb"
    type: evaluate
    urgency: medium
```

---

## Poster 3: Evolution (Why You)

```yaml
poster_label: "Evolution"
sequence: "3/4"
sections: 2
height_allocation: [50, 50]

section_1:
  type: feature-alternating
  section_theme: light
  height_percent: 50

  headline: "Sensoren liefern 14 Tage Vorwarnung vor dem Ausfall"
  section_label: "DIE LOESUNG"

  body: |
    Vibrationssensoren an Spindel, Vorschub und Lager erfassen den
    Maschinenzustand 500-mal pro Sekunde. Edge-KI erkennt Verschleissmuster
    und warnt 14 Tage vor dem Ausfall.

  image_prompt: |
    Modern CNC machine with glowing sensor nodes at critical points:
    spindle, bearings, feed axis. Digital wave patterns emanate from
    each sensor toward central edge computing unit. Health indicator
    glowing green. Precision gear mechanism in cutaway view.
    Mood: confident, technological. Primary blue with green accents.
    Style: print resolution, high detail. No text, no people.

  cta:
    text: "Sensor-Pilot in 4 Wochen aufbauen"
    type: commit
    urgency: high

section_2:
  type: feature-grid
  section_theme: light-alt
  height_percent: 50

  headline: "Vier Bausteine der intelligenten Fertigung"
  section_label: "FAEHIGKEITEN"

  cards:
    - card_headline: "Echtzeit-Sensorik"
      card_body: "500 Messungen pro Sekunde an Spindel, Vorschub und Lager"
      icon: "activity"
    - card_headline: "Edge-KI"
      card_body: "Verschleissmuster erkennen und Wartungsfenster vorschlagen"
      icon: "cpu"
    - card_headline: "Digitaler Zwilling"
      card_body: "Virtuelles Maschinenabbild fur Simulation und Planung"
      icon: "layers"
    - card_headline: "OEE-Dashboard"
      card_body: "Anlagenverfuegbarkeit und Qualitaet in Echtzeit verfolgen"
      icon: "bar-chart-2"
```

---

## Poster 4: Fuhrung (Why Pay)

```yaml
poster_label: "Fuhrung"
sequence: "4/4"
sections: 2
height_allocation: [55, 45]

section_1:
  type: timeline
  section_theme: light-alt
  height_percent: 55

  headline: "In 12 Wochen zur intelligenten Fertigung"
  section_label: "DER WEG"

  steps:
    - label: "Sensorik-Pilotlinie"
      description: "8 CNC-Anlagen ausrusten, Basisdaten erfassen"
      duration: "Woche 1-4"
    - label: "KI-Training"
      description: "Verschleissmodelle auf historischen Daten trainieren"
      duration: "Woche 5-8"
    - label: "Rollout"
      description: "Auf alle Anlagen skalieren, OEE-Dashboard live"
      duration: "Woche 9-12"

  cta:
    text: "Ihren Pilotplan erstellen"
    type: commit
    urgency: high

section_2:
  type: cta
  section_theme: accent
  height_percent: 45

  headline: "Starten Sie Ihren Predictive-Maintenance-Piloten"
  subline: "Drei Schritte trennen Sie von 73% weniger Stillstand."
  cta_text: "Erstgesprach fur Pilotprojekt buchen"
```

---

## CTA Summary

```yaml
cta_proposals:
  - text: "Erstgesprach fur Pilotprojekt buchen"
    type: commit
    urgency: high
    supporting_sections: [poster_3_section_1, poster_4_section_1]
  - text: "Sensor-Pilot in 4 Wochen aufbauen"
    type: commit
    urgency: high
    supporting_sections: [poster_3_section_1, poster_4_section_1]
  - text: "Ihre Stillstandskosten berechnen"
    type: evaluate
    urgency: medium
    supporting_sections: [poster_1_section_2, poster_2_section_2]
  - text: "Vergleichsanalyse fur Ihren Betrieb"
    type: evaluate
    urgency: medium
    supporting_sections: [poster_2_section_1, poster_2_section_2]
  - text: "VDMA-Studie zur Branchenlage einsehen"
    type: explore
    urgency: low
    supporting_sections: [poster_1_section_2]

primary_cta: "Erstgesprach fur Pilotprojekt buchen"
conversion_goal: "consultation"
```

---

## Generation Metadata

**Story Arc:** why-change (industry-transformation)
**Governing Thought:** Predictive Maintenance senkt ungeplante Stillstande um 73% und macht den Maschinenbau fit fur die nachste Dekade.

**Storyboard Architecture:**
- Poster size: A1 portrait (3508 x 4961 px print, 1440 x 2036 px base)
- Posters: 4 (each with 2 stacked web sections)
- Style guide: Corporate Tech
- Industry: maschinenbau

**Poster Composition:**
- Poster 1: hero (dark) + problem-statement (light) — 60/40 split
- Poster 2: stat-row (dark) + comparison (light) — 45/55 split
- Poster 3: feature-alternating (light) + feature-grid (light-alt) — 50/50 split
- Poster 4: timeline (light-alt) + cta (accent) — 55/45 split

**Section Types Used:** hero, problem-statement, stat-row, comparison, feature-alternating, feature-grid, timeline, cta (8 of 10 types)

**Copywriting Applied:**
- Number plays: 4 (23 days, 64K gap, 73% reduction, 12 weeks)
- Headlines: all assertions with verbs
- Body text: max 50 words per section

**Validation:** Schema: pass | Messages: pass | Visual: pass | Integrity: pass | Print: pass
