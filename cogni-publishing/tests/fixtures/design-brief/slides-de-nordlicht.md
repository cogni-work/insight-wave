---
type: design-brief
version: "1.1"
target: slides
language: de
arc_id: consulting-problem-solving
arc_display_name: "Consulting Problem-Solving"
title: "Nordlicht verkauft Strom in Stunden, die es nicht kennt"
governing_thought: "Der Windpark Nordlicht speist 38 Prozent seiner Jahresmenge in die vier Stunden ein, in denen der Preis am niedrigsten ist [2]."
source_narrative: nordlicht-netzentgelte-de.md
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
  dark_slides: [1, 6]
  speaker_notes: full-script
  imagery: none
  variations: 1
key_figures:
  - "38 Prozent der Jahresmenge in den vier billigsten Stunden (src: [2])"
  - "19 Minuten Vorlauf bis zur Abregelung (src: [1])"
  - "6,80 Euro je Megawattstunde Erlösdifferenz (src: [2])"
  - "31 Millionen Euro über die Laufzeit (src: [3])"
climax: 6
---

# Nordlicht verkauft Strom in Stunden, die es nicht kennt

*Wie sollte ein norddeutscher Windparkbetreiber auf negative Börsenpreise und kurzfristige Abregelung reagieren?*

# Rendering-Vertrag

- Texte sind eingefroren: Überschriften, Aufzählungen, Zahlen und Beschriftungen exakt übernehmen — wer eine Zeile umformuliert, ändert das Ergebnis, statt es zu gestalten.
- Der Sprechtext geht vollständig in den nativen Notizkanal des Renderers; gekürzte oder zusammengefasste Notizen sind eine fehlerhafte Umsetzung.
- Zitatmarker `[N]` werden zu Hyperlinks auf der Zahl, und eine aus dem Quellenblock gebaute Quellenfolie bleibt die letzte Folie.
- Gestaltung stammt ausschließlich aus dem Theme oder dem Designsystem des Renderers; der Brief enthält keine Farben, Schriften oder Koordinaten, und es dürfen auch keine aus dem Wortlaut abgeleitet werden.
- `type` ist eine Inhaltsform: jede Einheit auf das nächstgelegene native Layout abbilden und niemals Inhalte erfinden, um eines zu füllen.

## Slide 1: Nordlicht verkauft Strom in Stunden, die es nicht kennt

type: bluf
visual_intent:
  message_pattern: decision
  relationship: hohe Einspeisung und niedriger Preis fallen zusammen
  focal_point: die Entscheidung der Geschäftsführung vor der Ausschreibung
  preferred_expression: metric
  asset_signal: none
slide_points:
- 38 Prozent der Jahresmenge in den billigsten Stunden [2]
- 19 Minuten Vorlauf bis zur Abregelung [1]
- Die Geschäftsführung entscheidet im zweiten Quartal 2027

talk_track:
Wie sollte ein norddeutscher Windparkbetreiber auf negative Börsenpreise und kurzfristige Abregelung reagieren? Der Windpark Nordlicht speist 38 Prozent seiner Jahresmenge in die vier Stunden ein, in denen der Preis am niedrigsten ist [2]. Das ist kein Wetterproblem, sondern ein Fahrplanproblem: Die Anlagen laufen gegen einen Preis, den niemand im Betrieb vorher sieht. Der Netzbetreiber kündigt eine Abregelung im Mittel 19 Minuten vorher an, und in dieser Frist lässt sich weder ein Speicher laden noch ein Direktvertrag bedienen [1]. Nordlicht sollte die Vermarktung von der reinen Mengenlogik auf eine Fahrplanlogik umstellen, bevor die nächste Ausschreibungsrunde im Januar 2028 die Erlöse für fünfzehn Jahre festschreibt [3]. Die Geschäftsführung entscheidet das im zweiten Quartal 2027, nicht danach. Alles Weitere — der Speicher, der Direktvertrag, die Prognose — folgt aus dieser einen Entscheidung und lässt sich ohne sie nicht sinnvoll dimensionieren.

## Slide 2: Nordlicht vermarktet seine Menge, nicht seine Stunden

type: two-column
element: 1
evidence_status: direct
visual_intent:
  message_pattern: composition
  relationship: getrennte Systeme für Prognose, Vermarktung und Betrieb
  focal_point: die Trennung der drei Systeme
  preferred_expression: architecture
  asset_signal: diagram
slide_points:
- 214 Gigawattstunden Jahresmenge [2]
- 19 Minuten Vorlauf bis zur Abregelung [1]
- drei Systeme ohne gemeinsamen Fahrplan
- Keines dieser Systeme liest das andere

talk_track:
Nordlicht vermarktet seine Menge, nicht seine Stunden. Der Park liefert 214 Gigawattstunden im Jahr und verkauft sie über einen Direktvermarkter, der nach Monatsmenge abrechnet [2]. Die Wetterprognose liegt beim Dienstleister, die Vermarktung beim Händler, die Anlagensteuerung beim Betriebsführer — drei Systeme, von denen keines den Fahrplan des anderen kennt. Der Netzbetreiber meldet eine Abregelung im Mittel 19 Minuten vorher, gelegentlich weniger [1]. In dieser Frist kann der Betriebsführer die Anlage herunterfahren, aber niemand kann die Menge anders verkaufen, weil der Handelstag längst geschlossen ist. Der Betrieb beschäftigt für 48 Anlagen etwa zwölf Personen, und ihr Arbeitstag beginnt mit der Störungsliste des Vortages, nicht mit dem Preisverlauf des kommenden. Diese Zahlen sind unstrittig; sie beschreiben den Zustand, von dem jede Entscheidung ausgeht, und keine Seite bestreitet sie. Unstrittig ist auch der Rahmen: Die nächste Ausschreibungsrunde der Bundesnetzagentur läuft im Januar 2028 und schreibt den Erlöspfad für fünfzehn Jahre fest [3]. Mehr braucht die Ausgangslage nicht — alles Strittige gehört in den nächsten Abschnitt.

## Slide 3: Der Engpass ist von der Anlage zum Fahrplan gewandert

type: timeline
element: 2
evidence_status: triangulated
visual_intent:
  message_pattern: shift
  relationship: der Engpass wandert von der Anlage zum Fahrplan
  focal_point: der Wechsel von der Menge zur Stunde
  preferred_expression: comparison
  asset_signal: data-chart
slide_points:
- 6,80 Euro je Megawattstunde Erlösdifferenz [2]
- 412 Stunden mit negativem Preis [2]
- Die Ausschreibung läuft im Januar 2028 [3]

talk_track:
Die Ausgangslage hält nicht mehr, und zwar aus einem Grund, den die meisten Betreiber nicht sehen. Sie behandeln Erlös als Mengenfrage: mehr Verfügbarkeit, weniger Stillstand, höhere Jahresproduktion. Die Evidenz zeigt etwas anderes. Zwischen zwei Parks gleicher Größe und gleicher Verfügbarkeit liegt die Erlösdifferenz bei 6,80 Euro je Megawattstunde, und sie erklärt sich vollständig aus der Stunde der Einspeisung, nicht aus der Menge [2]. Der deutsche Markt zählte im vergangenen Jahr 412 Stunden mit negativem Preis, und Nordlicht speiste in 94 Prozent davon ein [2]. Der Engpass ist also von der Anlage zum Fahrplan gewandert: Nicht die Turbine fehlt, sondern der Blick auf die Stunde, in der sie liefert. Drei äußere Kräfte machen daraus eine Frist. Die Ausschreibung läuft im Januar 2028, und der Zuschlag bindet den Erlöspfad für fünfzehn Jahre [3]. Die Kosten für Batteriespeicher sinken bis 2030 um 27 Prozent, was die heutige Wirtschaftlichkeitsrechnung jedes Jahr verändert [4]. Und zwei der drei größten Abnehmer im norddeutschen Raum verhandeln seit 2026 nur noch Verträge mit stündlicher Lieferzusage [5]. Das Fenster schließt sich von beiden Seiten.

## Slide 4: Ein gemeinsamer Fahrplan aus Prognose, Preis und Anlage

type: two-column
element: 3
evidence_status: interpretation
visual_intent:
  message_pattern: system
  relationship: ein Fahrplan, der Prognose, Preis und Anlage zusammenführt
  focal_point: der gemeinsame Fahrplan
  preferred_expression: architecture
  asset_signal: diagram
slide_points:
- 4,10 Euro je Megawattstunde Mehrerlös [2]
- 36 Stunden Vorlauf statt 19 Minuten [1]
- rund 60 Prozent der negativen Stunden [2]

talk_track:
Die Antwort lautet: Prognose, Preis und Anlagensteuerung in einen gemeinsamen Fahrplan überführen und die stündliche Lieferzusage von der ersten Anlage an gegen die Ausschreibung dokumentieren. Erstens: Parks, die ihre drei Systeme in einen Fahrplan überführen, erzielen 4,10 Euro je Megawattstunde Mehrerlös gegenüber Parks, die es nicht tun [2]. Zweitens: Betreiber, die 2025 begonnen haben, kennen ihre Abregelung 36 Stunden im Voraus statt 19 Minuten und können die Menge verkaufen, statt sie zu verlieren [1]. Drittens: Marktübliche Vermarktungsprodukte decken den Day-Ahead-Handel ab; in den Intraday-Stunden entstehen jedoch rund 60 Prozent der negativen Preise [2]. Eine Lösung, die nur den Day-Ahead abdeckt, löst das Problem daher nicht, sondern verschiebt es. Die Interpretation, kenntlich gemacht: Drei Jahre stündlich beschriftete Einspeisehistorie sind ein Datenvermögen, das ein Wettbewerber nachträglich nicht kaufen kann [5]. Was die Antwort ausschließt, ist ebenso klar. Mehr Verfügbarkeit beantwortet die Komplikation nicht, weil sie den unbeobachteten Stunden nichts hinzufügt. Die Antwort verlangt deshalb zwei Dinge zugleich, die getrennt einfacher zu haben wären — Tempo bis zur Ausschreibung und Hoheit über die Prognose.

## Slide 5: Die Geschäftsführung entscheidet im zweiten Quartal 2027

type: table
element: 4
evidence_status: mixed
visual_intent:
  message_pattern: causality
  relationship: aus der Antwort folgen drei Beschlüsse
  focal_point: der Beschluss der Geschäftsführung
  preferred_expression: table
  asset_signal: none
slide_points:
- 31 Millionen Euro über die Laufzeit gegenüber 12 Millionen bei geplantem Vorgehen [3]
- weitere 4,5 Millionen Euro aus entgangenen Intraday-Erlösen [2]
- 9,7 Millionen Euro Programmkosten über drei Jahre [3]
- Der erste Schritt ist die Vorlage im April

talk_track:
Wenn das die Antwort ist, folgen drei Dinge. Erstens entscheidet die Geschäftsführung im zweiten Quartal 2027, denn ein Start 2028 verfehlt die Ausschreibung: Der nachgeholte Aufbau unter Zeitdruck kostet über die Laufzeit 31 Millionen Euro gegenüber 12 Millionen bei geplantem Vorgehen [3], und die entgangenen Intraday-Erlöse addieren über drei Jahre weitere 4,5 Millionen Euro [2]. Zweitens gehört die Prognosehoheit in jeden Vertrag: Wer die Einspeisehistorie besitzt, entscheidet über den Wert der Investition — das ist die Entscheidung der Geschäftsführung, nicht des Dienstleisters. Drittens misst die Betriebsführung ab dem ersten Quartal die Intraday-Abdeckung, denn sie ist die Größe, an der die Antwort scheitern kann. Die Gesamtrechnung stützt den Beschluss: Ein Fahrplanprogramm kostet für 48 Anlagen über drei Jahre 9,7 Millionen Euro [3]; Nichthandeln kostet im selben Zeitraum ein Vielfaches davon. Gegeben eine Mengenvermarktung, die in den billigsten Stunden liefert; aber 412 Stunden sind vorher bekannt; deshalb ein gemeinsamer Fahrplan vor Januar 2028; was bedeutet, dass die Geschäftsführung jetzt entscheidet und die Prognosehoheit sichert. Der erste Schritt ist die Vorlage im April.

## Slide 6: 38 Prozent der Jahresmenge liegen in vier Stunden

type: metric
evidence_status: proxy
visual_intent:
  message_pattern: comparison
  relationship: der größte Teil der Menge liegt in den billigsten Stunden
  focal_point: der Anteil der billigsten Stunden
  preferred_expression: metric
  asset_signal: data-chart
slide_points:
- 38 Prozent der Jahresmenge in vier Stunden [2]
- 412 Stunden mit negativem Preis [2]
- 9,7 Millionen Euro Programmkosten [3]

talk_track:
Gegeben eine Mengenvermarktung, die in den billigsten Stunden liefert; aber 412 Stunden mit negativem Preis sind am Vortag bekannt; deshalb ein gemeinsamer Fahrplan aus Prognose, Preis und Anlage vor Januar 2028; was bedeutet, dass die Geschäftsführung jetzt entscheidet und die Prognosehoheit sichert. Diese eine Zahl trägt den ganzen Foliensatz: 38 Prozent der Jahresmenge liegen in vier Stunden, und diese vier Stunden sind die billigsten des Jahres [2].

## Slide 7: Die Geschäftsführung entscheidet jetzt und sichert die Prognosehoheit

type: bluf
visual_intent:
  message_pattern: decision
  relationship: eine Entscheidung, getroffen vor der Ausschreibung
  focal_point: die Entscheidung selbst
  preferred_expression: none
  asset_signal: none
slide_points:
- die Geschäftsführung jetzt entscheidet und die Prognosehoheit sichert
- Der erste Schritt ist die Vorlage im April

talk_track:
Der erste Schritt ist die Vorlage im April. Zweitens gehört die Prognosehoheit in jeden Vertrag: Wer die Einspeisehistorie besitzt, entscheidet über den Wert der Investition — das ist die Entscheidung der Geschäftsführung, nicht des Dienstleisters.

## Slide 8: Quellen

type: sources

talk_track:
Das Quellenverzeichnis des Foliensatzes, vom Renderer wörtlich aus dem Quellenblock gebaut. Jeder Zitatmarker der vorherigen Folien wird hier aufgelöst.

note: Texte sind eingefroren — jede Zeile wörtlich übernehmen
note: Zitate als Fußnoten rendern und die URLs erhalten
note: die Einheiten und ihre Reihenfolge sind das Ergebnis — vor dem Hinzufügen, Zusammenlegen oder Umsortieren nachfragen

**Sources**

[1] source-01-netzbetreiber.md — Bundesnetzagentur, „Redispatch und Abregelung 2026", 2026, https://www.bundesnetzagentur.de/redispatch-abregelung-2026
[2] source-02-fraunhofer-iee.md — Fraunhofer IEE, „Stundenwerte der Windvermarktung 2026", 2026, https://www.iee.fraunhofer.de/de/publikationen/stundenwerte-windvermarktung-2026.html
[3] source-03-ausschreibung.md — Bundesnetzagentur, „Ausschreibungen Wind an Land 2028", 2026, https://www.bundesnetzagentur.de/ausschreibungen-wind-an-land-2028
[4] source-04-destatis.md — Destatis, „Speicherkosten 2030", 2026, https://www.destatis.de/DE/Themen/Branchen-Unternehmen/Energie/speicherkosten-2030.html
[5] source-05-handelsblatt.md — Handelsblatt, „Abnehmer, Speicher und Datenvorsprung 2026", 2026, https://www.handelsblatt.com/unternehmen/energie/abnehmer-speicher-datenvorsprung-2026
