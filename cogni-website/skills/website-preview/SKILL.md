---
name: website-preview
description: |
  This skill previews the generated website in a browser, validates links, and reports
  structural issues. It should be triggered when the user mentions "preview website",
  "open website", "Website anzeigen", "Website öffnen", "show me the website",
  "check the website", "validate links", "website preview", or wants to see the
  generated site in a browser — even without saying "preview" explicitly.
  Requires a built website in output/website/.
allowed-tools: Read, Glob, Bash, Agent
---

# Website Preview

Open the generated static website in a browser and validate its structure.

## Prerequisites

The `output/website/index.html` must exist (from `website-build`). If not found, redirect to the build skill.

## Workflow

### 1. Validate Site Structure

Check that the expected files exist:
- `output/website/index.html`
- `output/website/css/style.css`
- `output/website/sitemap.xml`
- All pages referenced in `website-plan.json`

Report missing files.

### 2. Validate Internal Links

Scan all `.html` files in `output/website/` for local links (`href` not starting with `http`). Check each resolves to an existing file. Report broken links with the page and target.

### 3. Open in Browser

Open the homepage in the default browser:

```bash
# macOS
open output/website/index.html

# Linux
xdg-open output/website/index.html
```

### 4. Suggest Local Server

For full navigation testing (relative paths work best with a server):

```
Für vollständige Navigation empfehle ich einen lokalen Testserver:

  python3 -m http.server -d output/website 8080

Dann öffnen Sie http://localhost:8080 im Browser.
```

### 5. Present Validation Report

```
Website-Vorschau:

  Dateien:        {N} HTML-Seiten, 1 CSS, {M} Bilder
  Gesamtgröße:    {size} KB
  Defekte Links:  {count} ({details if any})
  Fehlende Seiten: {count} ({details if any})

  ✓ Website im Browser geöffnet
```

## Optional: Browser Screenshots

If `claude-in-chrome` MCP is available, offer to take screenshots of each page for review. Use `mcp__claude-in-chrome__navigate` to visit each page and `mcp__claude-in-chrome__get_page_text` to validate rendered content.
