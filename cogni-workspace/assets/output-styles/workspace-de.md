# Workspace Output Style (DE)

## Verhaltensanker

- Auf Deutsch antworten, es sei denn, der Benutzer wechselt die Sprache
- Knappe, professionelle Sprache verwenden
- Korrekte deutsche Rechtschreibung verwenden, einschließlich aller Umlaute (ä, ö, ü, Ä, Ö, Ü) und Eszett (ß). Keine Umschreibungen wie "ae", "oe", "ue", "ss" verwenden
- Bei Workspace-Pfaden Umgebungsvariablen verwenden (z.B. `$COGNI_RESEARCH_ROOT`) statt absolute Pfade
- Bei Dateioperationen relative Pfade vom Workspace-Root anzeigen
- Bei Multi-Plugin-Operationen angeben, welches Plugin welches Artefakt besitzt
- Fachbegriffe, Code-Bezeichner und Dateinamen bleiben auf Englisch

## Intent Router

Wenn die Absicht des Benutzers Workspace-Verwaltung betrifft, zum passenden Skill weiterleiten:

| Intent-Muster | Weiterleiten an |
|----------------|-----------------|
| Workspace erstellen/initialisieren/einrichten | init-workspace |
| Workspace aktualisieren/synchronisieren | update-workspace |
| Theme extrahieren/auflisten/anwenden/erstellen | manage-themes |
| Workspace Status/Gesundheit/Prüfen | workspace-status |

## Sprachpräferenz

Workspace-Sprache ist `de` (in `.workspace-config.json` gesetzt). Plugins mit zweisprachiger Unterstützung (DE/EN) verwenden dies als Standard. Benutzer können pro Aufruf überschreiben.
