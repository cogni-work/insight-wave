---
name: website-resume
description: |
  This skill resumes, continues, or checks status of a cogni-website project. It is the
  primary re-entry point for returning to website work across sessions. It should be
  triggered when the user mentions "continue website", "resume website", "website status",
  "where was I", "Website fortsetzen", "Website-Status", "weiter mit der Website",
  "was fehlt noch", "pick up where I left off", "website status check", or opens a
  session involving an existing website project — even without saying "resume" explicitly.
allowed-tools: Read, Glob, Grep, Bash, Skill
---

# Website Resume

Detect the current state of a website project, show progress, and route to the appropriate next skill.

## Workflow

### 1. Find Website Project

Scan for `website-project.json` in:
- Current directory
- Immediate child directories matching `cogni-website*` or `*-website`

If not found, inform the user and suggest `website-setup`.

### 2. Assess Project State

Read available files and determine the project phase:

| File Exists | Phase | Status |
|-------------|-------|--------|
| `website-project.json` only | Setup complete | Needs plan |
| `+ website-plan.json` | Plan complete | Needs build |
| `+ output/website/index.html` | Build complete | Ready for preview |
| `+ output/website/css/style.css` + pages | Fully built | Ready for deployment |

Count:
- Pages planned (from website-plan.json)
- Pages built (HTML files in output/website/)
- Missing pages (planned but not built)
- Content source freshness (compare source file dates to build dates)

### 3. Present Status

```
Website-Projekt: {slug}

  Phase:           {current phase}
  Unternehmen:     {company name}
  Theme:           {theme name}
  Sprache:         {language}

  Geplante Seiten: {N}
  Erstellte Seiten: {M} / {N}
  Fehlende Seiten: {list if any}

  Rechtliches:
    Rechtsordnung:    {jurisdiction or "noch nicht festgelegt"}
    Legal Pages:      {3/3 generiert | 0/3 fehlen | ⚠ legal_config fehlt}
    Offene TODOs:     {n unfilled «TODO: ...» markers}

  Letzte Änderung: {date}
```

When assessing legal state, read `legal_config.jurisdiction` from `website-project.json`, scan `website-plan.json` for `legal-*` page entries, and grep `content/legal/*.md` for any `«TODO: ` markers.

### 4. Recommend Next Action

Based on the state:

| State | Recommendation |
|-------|---------------|
| Setup complete, no plan | → `/website-plan` — Seitenstruktur planen |
| Plan complete, no build | → `/website-build` — Website generieren |
| Build complete | → `/website-preview` — Website prüfen |
| Build outdated (sources newer than build) | → `/website-build` — Website aktualisieren (Quellen geändert) |
| Partially built (some pages missing) | → `/website-build` — Fehlende Seiten generieren |

### 5. Detect Content Changes

If the site is already built, check if source content has changed since the last build:
- Compare modification times of source files (from `website-plan.json` source_files) vs. output HTML files
- Flag pages where sources are newer than the built HTML
- Offer partial rebuild (only changed pages) or full rebuild

### 6. Detect Upstream Changes

Re-run content discovery using the same globs as website-setup and compare against the `content_discovery` counts stored in `website-project.json`:

- **New entities**: e.g., a new product was added to portfolio, or new marketing articles published → suggest re-planning to include them
- **Removed entities**: source files referenced in the plan no longer exist → warn about stale plan
- **New upstream plugins**: glob for `**/tips-project.json` and `**/output/draft-v*.md` that were not present when the project was created (i.e., `sources.trends_project` or `sources.research_projects` is null/empty but projects now exist) → suggest re-running setup to discover new content sources

Present changes:

```
Änderungen seit letztem Build:

  Neue Inhalte:
    ✚ 2 neue Marketing-Artikel
    ✚ 1 neues Produkt im Portfolio

  Neue Inhaltsquellen verfügbar:
    ✚ Trend-Report gefunden (vorher nicht eingebunden)

  Empfehlung: /website-setup erneut ausführen, um neue Quellen einzubinden
```

Add to recommendation table:

| State | Recommendation |
|-------|---------------|
| New content sources discovered | → `/website-setup` — Neue Quellen einbinden, dann erneut planen |
| New entities in existing sources | → `/website-plan` — Seitenstruktur aktualisieren |
| `legal_config.jurisdiction` set but no `legal-*` pages in plan | → `/website-legal` — Pflichtseiten erzeugen |
| `legal_config.jurisdiction` is `null` | → `/website-legal` — Rechtsordnung festlegen und Pflichtseiten erzeugen |
| Unfilled `«TODO: ...»` markers in `content/legal/*.md` | → `/website-legal` — fehlende Felder ergänzen |
