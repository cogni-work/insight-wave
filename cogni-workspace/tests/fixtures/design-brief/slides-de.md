---
type: design-brief
version: "1.1"
target: slides
language: de
arc_id: consulting-problem-solving
arc_display_name: "Consulting Problem-Solving"
title: "Das Instandhaltungsbudget kauft Stillstand — weil niemand die Signale liest"
governing_thought: "Die Betreiber mit dem höchsten Instandhaltungsbudget verlieren die meisten Produktionsstunden: elf Prozent mehr als das unterste Viertel [2]."
source_narrative: consulting-problem-solving-de.md
density:
  profile: standard
  ceilings:
    headline_chars_max: 110
    slide_points_max_lines: 4
    slide_point_words_max: 10
    slide_point_words_max_table: 20
    talk_track_words_min: 150
    talk_track_words_max: 450
    units_min: 5
    units_max_default: 15
design:
  register: quiet-executive
  dark_slides: [1, 7]
  speaker_notes: full-script
  imagery: none
  variations: 1
key_figures:
  - "71 Prozent der Ausfälle hatten ein lesbares Sensorsignal (src: [2])"
  - "47 verschiedene Sensordatenformate (src: [1])"
  - "34 Prozent weniger ungeplante Stillstände (src: [2])"
  - "4,2 Millionen Euro (src: [1])"
climax: 7
---

# Das Instandhaltungsbudget kauft Stillstand — weil niemand die Signale liest

*Wie sollten europäische Industriebetreiber auf den Wandel von der geplanten zur zustandsbasierten Instandhaltung reagieren?*

# Rendering-Vertrag

- Texte sind eingefroren: Überschriften, Aufzählungen, Zahlen und Beschriftungen exakt übernehmen — wer eine Zeile umformuliert, ändert das Ergebnis, statt es zu gestalten.
- Der Sprechtext geht vollständig in den nativen Notizkanal des Renderers; gekürzte oder zusammengefasste Notizen sind eine fehlerhafte Umsetzung.
- Zitatmarker `[N]` werden zu Hyperlinks auf der Zahl, und eine aus dem Quellenblock gebaute Quellenfolie bleibt die letzte Folie.
- Gestaltung stammt ausschließlich aus dem Theme oder dem Designsystem des Renderers; der Brief enthält keine Farben, Schriften oder Koordinaten, und es dürfen auch keine aus dem Wortlaut abgeleitet werden.
- `type` ist eine Inhaltsform: jede Einheit auf das nächstgelegene native Layout abbilden und niemals Inhalte erfinden, um eines zu füllen.

## Slide 1: Das Instandhaltungsbudget kauft Stillstand — weil niemand die Signale liest

type: bluf
visual_intent:
  message_pattern: decision
  relationship: hohes Instandhaltungsbudget und hoher Ausfall gehören zusammen
  focal_point: die Entscheidung des Vorstands vor der Frist
  preferred_expression: metric
  asset_signal: none
slide_points:
- elf Prozent mehr als das unterste Viertel [2]
- 71 Prozent der Ausfälle hatten ein lesbares Sensorsignal [2]
- Der Vorstand entscheidet das im vierten Quartal 2026

talk_track:
Wie sollten europäische Industriebetreiber auf den Wandel von der geplanten zur zustandsbasierten Instandhaltung reagieren? Die Betreiber mit dem höchsten Instandhaltungsbudget verlieren die meisten Produktionsstunden: elf Prozent mehr als das unterste Viertel [2]. Der Grund ist kein Geldproblem, sondern ein Informationsproblem — 71 Prozent der Ausfälle hatten ein lesbares Sensorsignal, das niemand gelesen hat [2]. Betreiber sollten das Budget für Kalenderwartung in eine gemeinsame Anlagenzustandssicht umlenken, bevor die Maschinenverordnung im Januar 2027 gilt [3]. Der Vorstand entscheidet das im vierten Quartal 2026, nicht danach.

## Slide 2: Europäische Industriebetreiber warten ihre Anlagen nach Kalender

type: two-column
element: 1
visual_intent:
  message_pattern: composition
  relationship: getrennte Datensysteme, die einander nicht lesen
  focal_point: die Trennung der Systeme
  preferred_expression: architecture
  asset_signal: diagram
slide_points:
- 47 verschiedene Sensordatenformate [1]
- 24 Produktionsstunden im Jahr an ungeplante Stillstände [2]
- rund 180.000 Euro [2]
- Keines dieser Systeme liest das andere

talk_track:
Europäische Industriebetreiber warten ihre Anlagen nach Kalender: Bauteile werden in festen Intervallen getauscht, unabhängig von ihrem tatsächlichen Verschleiß. Ein typisches Werk erzeugt dabei 47 verschiedene Sensordatenformate über Antriebe, Lager, Pumpen und Steuerungen [1], und die durchschnittliche Anlage verliert 24 Produktionsstunden im Jahr an ungeplante Stillstände, jede davon zu Kosten von rund 180.000 Euro [2]. Die Instandhaltung beschäftigt in einem mittelgroßen Betrieb mit 40 kritischen Anlagen etwa 60 Personen, und ihr Budget wächst seit Jahren in kleinen Schritten, weil jede Störung mit einem kürzeren Intervall beantwortet wird. Die Daten, die die Anlagen dabei erzeugen, laufen in getrennte Systeme: Die Steuerung protokolliert in ihrem eigenen Format, die Antriebe in einem anderen, die Schwingungssensoren in einem dritten. Keines dieser Systeme liest das andere, und niemand ist dafür zuständig, sie zusammen zu lesen. Diese Zahlen sind unstrittig; sie beschreiben den Zustand, von dem jede Entscheidung ausgeht, und keine Seite der Debatte bestreitet sie. Unstrittig ist auch der Rahmen: Die EU-Maschinenverordnung gilt ab Januar 2027 vollständig und verlangt für sicherheitsrelevante Anlagen einen dokumentierten Prozess der Zustandsüberwachung [3]. Mehr braucht die Ausgangslage nicht — alles, was strittig ist, gehört in den nächsten Abschnitt.

## Slide 3: Der Engpass ist vom Personal zum Signal gewandert

type: timeline
element: 2
visual_intent:
  message_pattern: shift
  relationship: der Engpass wandert vom Personal zum Signal
  focal_point: der Wechsel vom Personal zum Signal
  preferred_expression: comparison
  asset_signal: data-chart
slide_points:
- 62 Prozent der ungeplanten Stillstände hatten einen messbaren Vorläufer [2]
- Die Verordnung greift im Januar 2027 [3]
- bis 2030 um 23 Prozent [4]
- Rabatte von acht bis zwölf Prozent [5]

talk_track:
Die Ausgangslage hält nicht mehr, und zwar aus einem Grund, den die meisten Betreiber nicht sehen. Sie behandeln Zuverlässigkeit als Ausgabenfrage: mehr Inspektionen, kürzere Intervalle, größere Ersatzteillager. Die Evidenz zeigt das Gegenteil. In der Fraunhofer-Stichprobe von 214 Werken verliert das oberste Viertel nach Wartungsbudget elf Prozent mehr Produktionsstunden als das unterste [2]. Kalenderwartung tauscht Teile nach Termin, nicht nach Verschleiß; das Budget fließt in Komponenten, die nicht ausfielen, während die ausfallenden unbeobachtet bleiben [1]. 62 Prozent der ungeplanten Stillstände hatten mindestens 48 Stunden vorher einen messbaren Vorläufer in den Sensordaten, und in 71 Prozent dieser Fälle lagen die Daten im System, ohne dass jemand sie las [2]. Der Engpass ist also vom Personal zum Signal gewandert: Nicht die Hände fehlen, sondern der Blick auf das, was die Anlagen bereits melden. Drei äußere Kräfte machen aus dieser Einsicht eine Frist. Die Verordnung greift im Januar 2027, und der VDMA schätzt die durchschnittliche Umsetzungslücke auf 14 Monate — wer 2027 beginnt, kommt zu spät [3]. Die Zahl qualifizierter Instandhaltungstechniker in Deutschland sinkt bis 2030 um 23 Prozent [4], und ihre Lohnprämie stieg in zwei Jahren um 18 Prozent [5]; jede unnötige Wartung wird damit teurer und bindet knappere Hände. Und zwei der drei größten Industrieversicherer im DACH-Raum gewähren seit 2025 Rabatte von acht bis zwölf Prozent für überwachte Anlagen und haben Zuschläge für unüberwachte kritische Anlagen ab 2027 angekündigt [5]. Das Fenster schließt sich von beiden Seiten.

## Slide 4: Eine gemeinsame Anlagenzustandssicht, die alle 47 Formate liest

type: two-column
element: 3
visual_intent:
  message_pattern: system
  relationship: eine gemeinsame Sicht, die alle Formate liest
  focal_point: die gemeinsame Sicht
  preferred_expression: architecture
  asset_signal: diagram
slide_points:
- 34 Prozent weniger ungeplante Stillstände [2]
- 48 bis 72 Stunden vor dem Ausfall [2]
- rund 60 Prozent der Ausfallsignale [1]
- Tempo bis zur Frist und Hoheit über die Daten

talk_track:
Die Antwort lautet: Das Budget der Kalenderwartung in eine gemeinsame Anlagenzustandssicht umlenken, die alle 47 Formate liest, und den Überwachungsprozess von der ersten Anlage an gegen die Verordnung dokumentieren. Erstens: Werke, die ihre Signale in eine einzige Zustandssicht überführen, melden 34 Prozent weniger ungeplante Stillstände als Werke, die es nicht tun [2]. Zweitens: Betreiber, die 2023 begonnen haben, erkennen Verschleißmuster 48 bis 72 Stunden vor dem Ausfall und senken unnötige Eingriffe um rund ein Drittel [2] — das entlastet genau die Techniker, die knapp werden, und verwandelt den Kalender in eine Warteschlange. Drittens: Marktübliche Überwachungsprodukte lesen acht bis zwölf der 47 Formate; in den restlichen entstehen rund 60 Prozent der Ausfallsignale [1]. Eine Lösung, die nur die gängigen Formate abdeckt, löst das Problem daher nicht, sondern verlagert es. Die Interpretation, kenntlich gemacht: Drei Jahre beschriftete Ausfallhistorie sind ein Datenvermögen, das Wettbewerber nachträglich nicht kaufen können [5]. Was die Antwort ausschließt, ist ebenso klar. Mehr Kalenderwartung beantwortet die Komplikation nicht, weil sie den ungelesenen Signalen nichts hinzufügt. Die Antwort verlangt deshalb zwei Dinge zugleich, die getrennt einfacher zu haben wären — Tempo bis zur Frist und Hoheit über die Daten — und genau diese Verbindung unterscheidet sie von den naheliegenden Abkürzungen.

## Slide 5: Der Vorstand entscheidet im vierten Quartal 2026

type: table
element: 4
visual_intent:
  message_pattern: causality
  relationship: aus der Antwort folgen drei Beschlüsse
  focal_point: der Beschluss des Vorstands
  preferred_expression: table
  asset_signal: none
slide_points:
- 1,4 Millionen Euro gegenüber 0,6 Millionen bei geplantem Vorgehen [1]
- weitere 0,9 Millionen Euro [5]
- 4,2 Millionen Euro [1]
- Der erste Schritt ist die Vorstandsvorlage im Oktober

talk_track:
Wenn das die Antwort ist, folgen drei Dinge. Erstens entscheidet der Vorstand im vierten Quartal 2026, denn ein Start 2027 verfehlt die Frist: Der nachgeholte Aufbau unter Zeitdruck kostet 1,4 Millionen Euro gegenüber 0,6 Millionen bei geplantem Vorgehen [1], und die Versicherungszuschläge addieren über drei Jahre weitere 0,9 Millionen Euro [5]. Zweitens gehört die Datenhoheit in jeden Vertrag: Wer die Ausfallhistorie besitzt, entscheidet über den Wert der Investition — das ist die Entscheidung des Einkaufs, nicht der Technik. Drittens misst die Instandhaltungsleitung ab dem ersten Quartal die Formatabdeckung, denn sie ist die Größe, an der die Antwort scheitern kann. Die Gesamtrechnung stützt den Beschluss: Ein zustandsbasiertes Programm kostet für einen Betrieb mit 40 kritischen Anlagen über drei Jahre 4,2 Millionen Euro [1]; Nichthandeln kostet im selben Zeitraum ein Vielfaches davon. Gegeben eine Kalenderwartung, die Stillstand kauft; aber 71 Prozent der Ausfälle sind vorher lesbar; deshalb eine gemeinsame Zustandssicht über alle 47 Formate vor Januar 2027; was bedeutet, dass der Vorstand jetzt entscheidet und die Datenhoheit sichert. Der erste Schritt ist die Vorstandsvorlage im Oktober.

## Slide 6: 71 Prozent der Ausfälle sind vorher lesbar

type: metric
visual_intent:
  message_pattern: comparison
  relationship: die Mehrheit der Ausfälle ist vorher lesbar
  focal_point: der Anteil der lesbaren Ausfälle
  preferred_expression: metric
  asset_signal: data-chart
slide_points:
- 71 Prozent der Ausfälle sind vorher lesbar [2]
- alle 47 Formate [1]
- 4,2 Millionen Euro [1]

talk_track:
Gegeben eine Kalenderwartung, die Stillstand kauft; aber 71 Prozent der Ausfälle sind vorher lesbar; deshalb eine gemeinsame Zustandssicht über alle 47 Formate vor Januar 2027; was bedeutet, dass der Vorstand jetzt entscheidet und die Datenhoheit sichert.

## Slide 7: Der Vorstand entscheidet jetzt und sichert die Datenhoheit

type: bluf
visual_intent:
  message_pattern: decision
  relationship: eine Entscheidung, getroffen vor der Frist
  focal_point: die Entscheidung selbst
  preferred_expression: none
  asset_signal: none
slide_points:
- der Vorstand jetzt entscheidet und die Datenhoheit sichert
- Der erste Schritt ist die Vorstandsvorlage im Oktober

talk_track:
Der erste Schritt ist die Vorstandsvorlage im Oktober. Zweitens gehört die Datenhoheit in jeden Vertrag: Wer die Ausfallhistorie besitzt, entscheidet über den Wert der Investition — das ist die Entscheidung des Einkaufs, nicht der Technik.

## Slide 8: Quellen

type: sources

talk_track:
Das Quellenverzeichnis des Foliensatzes, vom Renderer wörtlich aus dem Quellenblock gebaut. Jeder Zitatmarker der vorherigen Folien wird hier aufgelöst.

note: Texte sind eingefroren — jede Zeile wörtlich übernehmen
note: Zitate als Fußnoten rendern und die URLs erhalten
note: theme.md nur anhängen, wenn kein Designsystem der Organisation konfiguriert ist
note: die Einheiten und ihre Reihenfolge sind das Ergebnis — vor dem Hinzufügen, Zusammenlegen oder Umsortieren nachfragen

**Sources**

[1] source-01-vdma-studie.md — VDMA, „Condition-Monitoring-Studie 2025", 2025, https://www.vdma.org/condition-monitoring-studie-2025
[2] source-02-fraunhofer.md — Fraunhofer IPA, „Instandhaltung 2025", 2025, https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html
[3] source-03-vdma-verordnung.md — VDMA, „Maschinenverordnung: Umsetzung bis 2027", 2025, https://www.vdma.org/maschinenverordnung-umsetzung-2027
[4] source-04-destatis.md — Destatis, „Instandhaltung 2030", 2025, https://www.destatis.de/DE/Themen/Arbeit/Arbeitsmarkt/Erwerbstaetigkeit/instandhaltung-2030.html
[5] source-05-handelsblatt.md — Handelsblatt, „Industrieversicherer, Fachkräfte und Datenvorsprung 2025-2026", 2026, https://www.handelsblatt.com/unternehmen/industrie/
