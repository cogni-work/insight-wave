---
type: infographic-brief
version: "1.0"
theme: smarter-service
theme_path: "/cogni-workspace/themes/smarter-service/theme.md"
customer: "Deutsche Bahn AG"
provider: "TechVision Solutions"
language: "de"
generated: "2026-04-10"
layout_type: "stat-heavy"
style_preset: "data-viz"
orientation: "landscape"
dimensions: "1920x1080"
arc_type: "why-change"
arc_id: "corporate-visions"
governing_thought: "KI-Videoanalytik senkt Sicherheitsvorfälle um 73% — manuelle Überwachung reicht nicht mehr aus."
confidence_score: 0.89
transformation_notes: |
  Story-to-infographic transformation.
  Theme: smarter-service. Style: data-viz. Layout: stat-heavy.
  6 content blocks, 3 number plays, 5 icons.
  Content distilled from 2400-word insight-summary to 8 data points.
---

# Infographic Brief: KI-Videoanalytik senkt Sicherheitsvorfälle um 73%

This example demonstrates the v1.0 infographic-brief schema using the stat-heavy layout type
with a data-viz style preset. All color fields are absent — the renderer reads the theme
directly for all visual decisions.

# Rendering-Anforderungen
- Texte und Zahlen sind freigegeben und exakt zu übernehmen; Abweichungen führen zu einer fehlerhaften Infografik.
- Quellenangaben müssen erhalten bleiben; eine Infografik ohne Quellenzeile ist fehlerhaft.
- Chart-Daten müssen exakt übernommen werden; gerundete oder veränderte Werte sind Fehler.

---

## Title Block

```yaml
Block-Type: title
Headline: "KI-Videoanalytik senkt Sicherheitsvorfälle um 73%"
Subline: "Warum Deutsche Bahn jetzt auf automatisierte Überwachung setzt"
Metadata: "Deutsche Bahn AG | TechVision Solutions | April 2026"
```

---

## Block 1: Hero KPI

```yaml
Block-Type: kpi-card
Hero-Number: "73%"
Hero-Label: "weniger Vorfälle"
Sublabel: "nach Pilotprojekt München Hbf (6 Monate)"
Icon-Prompt: "shield with downward arrow, security improvement"
Source: "Interne Pilotdaten, 2025"
```

---

## Block 2: Supporting KPIs

```yaml
Block-Type: stat-row
Stats:
  - number: "< 2s"
    label: "Erkennungszeit"
    icon-prompt: "stopwatch fast"
  - number: "500+"
    label: "Kameras skalierbar"
    icon-prompt: "camera network"
  - number: "24/7"
    label: "Überwachung"
    icon-prompt: "clock continuous"
```

---

## Block 3: Trend Chart

```yaml
Block-Type: chart
Chart-Type: bar
Chart-Title: "Sicherheitsvorfälle pro Quartal"
Data:
  labels: ["Q1 2024", "Q2 2024", "Q3 2024", "Q4 2024", "Q1 2025"]
  datasets:
    - label: "Vorfälle"
      values: [172, 168, 155, 89, 47]
```

---

## Block 4: Context Evidence

```yaml
Block-Type: stat-row
Stats:
  - number: "688"
    label: "Bahnsuizide 2023"
    icon-prompt: "warning triangle"
  - number: "2.661"
    label: "Übergriffe"
    icon-prompt: "alert person"
  - number: "5.400"
    label: "Bahnhöfe"
    icon-prompt: "building train station"
```

---

## Block 5: Process Overview

```yaml
Block-Type: process-strip
Steps:
  - label: "Kameradaten"
    icon-prompt: "camera lens capture"
  - label: "KI-Analyse"
    icon-prompt: "brain neural network"
  - label: "Echtzeit-Alert"
    icon-prompt: "bell notification urgent"
  - label: "Einsatzsteuerung"
    icon-prompt: "dispatch control center"
```

---

## Block 6: Second KPI

```yaml
Block-Type: kpi-card
Hero-Number: "12 Wochen"
Hero-Label: "bis zum Pilotstart"
Sublabel: "schlüsselfertige Implementierung"
Icon-Prompt: "rocket launch fast"
```

---

## CTA Block

```yaml
Block-Type: cta
Headline: "Pilot in 12 Wochen starten"
CTA-Text: "Erstgespräch buchen"
CTA-Type: commit
CTA-Urgency: high
```

---

## Footer Block

```yaml
Block-Type: footer
Left: "Deutsche Bahn AG"
Center: "April 2026"
Right: "TechVision Solutions"
Source-Line: "Quellen: BKA Bundeslagebild 2023, Interne Pilotdaten München Hbf, DB Sicherheitsbericht 2024"
```

---

## Generation Metadata

```yaml
blocks_total: 8
blocks_content: 6
number_plays: 3
icon_prompts: 9
charts: 1
word_count_total: 87
distillation_ratio: "2400 words → 87 words (96.4% reduction)"
layout_confidence: 0.92
style_confidence: 0.88
```
