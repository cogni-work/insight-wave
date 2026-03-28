---
name: website-resume
description: |
  This skill resumes, continues, or checks status of a cogni-website project. It is the
  primary re-entry point for returning to website work across sessions. It should be
  triggered when the user mentions "continue website", "resume website", "website status",
  "where was I", "Website fortsetzen", "Website-Status", "weiter mit der Website",
  "pick up where I left off", or opens a session involving an existing website project
  — even without saying "resume" explicitly.
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

  Letzte Änderung: {date}
```

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
- Compare modification times of source files vs. output HTML files
- Flag pages that need regeneration
- Offer partial or full rebuild
