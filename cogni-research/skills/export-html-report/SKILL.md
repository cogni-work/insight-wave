---
name: export-html-report
description: Transform deeper-research-3 output into a single self-contained HTML report. Converts research-hub.md and all entity files (findings, concepts, megatrends, sources, citations, claims, trends) into an interactive HTML document with wikilinks resolved to anchor links and theme support. Use when user wants to export research as HTML, generate HTML report from research project, create standalone research document, or convert research-hub.md to web format.
---

# Export HTML Report

Generate a single self-contained HTML file from deeper-research-3 output. Converts `research-hub.md` plus all entity files into an interactive document with navigation, theme support, and resolved wikilinks.

## Quick Start

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project /path/to/research-project \
  --theme digital-x \
  --output research-report.html
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | Yes | - | Path to research project root |
| `--theme` | No | `digital-x` | Theme ID from `$COGNI_WORKPLACE_ROOT/themes/` |
| `--output` | No | `{project}/research-report.html` | Output HTML file path |
| `--theme-root` | No | Auto-detected | Custom theme root directory |
| `--theme-css-file` | No | - | Path to pre-generated CSS file (or `-` to read from stdin) |

## Project Discovery

When invoked without a `--project` argument:

1. **Check environment variable first:**

   ```bash
   echo "${COGNI_RESEARCH_ROOT:-}"
   ```

   If set, list research projects under `$COGNI_RESEARCH_ROOT/deeper/` to find available projects.

2. **If not set, ask the user:**
   Use AskUserQuestion to request the full path to the research project containing `research-hub.md`.

3. **Validate project path:**
   - Must contain `research-hub.md` at root
   - Should have entity directories (e.g., `04-findings/data/`, `11-trends/data/`)

**DO NOT** attempt to source `.workplace-env.sh` - environment variables are already available via Claude Code's settings.

## Theme Selection

Before running the export script, discover available themes:

1. **List available themes:**

   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" --list-themes
   ```

   This returns JSON with all available themes from ALL workspace locations including metadata (theme_id, theme_name, description, primary_color, accent_color, source).

2. **Present theme options via AskUserQuestion:**

   Parse the JSON output and present each theme with its metadata. The `source` field shows which workspace the theme comes from.

3. **Pass selected theme to script:**
   Use the user's selection as the `--theme` argument.

## Example Invocations

**Basic export with default theme:**

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project ~/research/smarter-service-2025
```

**Export with custom theme:**

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project ~/research/market-analysis \
  --theme cogni-work \
  --output ~/Desktop/market-report.html
```

**Export to specific location:**

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project /data/research/b2b-trends \
  --output /var/www/reports/b2b-trends.html
```

**Export with LLM-generated theme CSS (piped via stdin):**

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project ~/research/smarter-service-2025 \
  --theme-css-file - \
  --output research-report.html << 'THEME_CSS'
:root {
    --color-primary: #0D3C55;
    /* ... all generated variables ... */
}
THEME_CSS
```

## Workflow

```text
1. Load Configuration
   ├── Read sprint-log.json for project metadata
   ├── Resolve theme from $COGNI_WORKPLACE_ROOT/themes/{theme-id}/
   └── Generate CSS from theme.md (see Theme CSS Generation below)

2. Parse Research Report
   ├── Load research-hub.md from project root
   ├── Extract frontmatter metadata
   ├── Detect hub version (v2.x or v3.0)
   ├── Load v3.0 supporting files if applicable
   └── Convert markdown to HTML

3. Collect Entities
   ├── Scan entity directories (see Entity Structure)
   ├── Parse frontmatter from each .md file
   └── Build entity index for wikilink resolution

4. Resolve Wikilinks
   ├── Find all [[entity-id]] patterns
   ├── Map to anchor IDs: <a href="#entity-id">Title</a>
   └── Handle missing entities gracefully

5. Generate HTML
   ├── Build TOC from headings + entity sections
   ├── Embed theme CSS variables
   ├── Include all entities as sections
   └── Add navigation JavaScript

6. Write Output
   └── Single self-contained HTML file
```

## Entity Structure

The script scans these directories from deeper-research-3 output:

| Directory | Entity Type | ID Pattern |
|-----------|-------------|------------|
| `01-research-dimensions/data/` | dimension | `dim-*` |
| `02-refined-questions/data/` | question | `question-*` |
| `04-findings/data/` | finding | `finding-*` |
| `05-concepts/data/` or `05-domain-concepts/data/` | concept | `concept-*` |
| `06-megatrends/data/` | megatrend | `megatrend-*` |
| `07-sources/data/` | source | `source-*` |
| `09-citations/data/` | citation | `citation-*` |
| `10-claims/data/` | claim | `claim-*` |
| `11-trends/data/` | trend | `trend-*` or `portfolio-*` |
| `12-synthesis/` | synthesis | `synthesis-*` |
| `11-trends/` (legacy) | synthesis | `synthesis-*` |

For detailed frontmatter specs, see [references/entity-formats.md](references/entity-formats.md).

## v3.0 Hub Ecosystem Support

The skill automatically detects and handles v3.0 hub ecosystem projects, which use a lightweight hub document with supporting files instead of a monolithic report.

### Version Detection

Projects are identified as v3.0 if `research-hub.md` contains:

```yaml
---
hub_type: "catalog"  # or "navigation" for older projects
synthesis_framework: "Hub-and-Spoke Progressive Disclosure"
---
```

**Version Detection:** The export tool recognizes both `hub_type: "catalog"` (current) and `hub_type: "navigation"` (legacy) as v3.0 hub structures. This ensures backward compatibility with projects created before the terminology update.

### Supporting Files Loaded

For v3.0 projects, the skill automatically loads these additional files:

| File | Description | Order | Word Count |
|------|-------------|-------|------------|
| `insight-summary.md` | Featured journalistic narrative with story arc | -1 | 1,450-1,900 |
| `executive-summary.md` | Optional executive narrative (journalistic style) | 0 | 1,450-1,900 |
| `00-research-scope.md` | Methodology framework, evidence scale | 1 | 400-600 |
| `00-pipeline-metrics.md` | Entity statistics, wikilink density | 2 | 300-400 |
| `12-synthesis/synthesis-cross-dimensional.md` | Cross-dimensional patterns, tensions | 3 | 400-600 |

**Note:** Both `insight-summary.md` and `executive-summary.md` are optional. Projects may have one, both, or neither. When both exist, insight-summary renders first with hero styling (order=-1), followed by executive-summary (order=0).

### Export Structure for v3.0

The HTML export renders supporting files before the hub document:

1. **Insight Summary** (if exists) - featured hero section with story arc badge, research type, word count, and bridge navigation to research report
2. **Executive Summary** (if exists) - with story arc badge and word count
3. **Research Scope & Methodology**
4. **Pipeline Metrics & Statistics**
5. **Cross-Dimensional Analysis**
6. **Research Report** (hub navigation document)
7. **Entity Sections** (trends, concepts, etc.)

### Kanban Board Data Source

For v3.0 projects, trend landscape data is extracted from `11-trends/README.md` instead of the hub document, as the hub contains a Navigation Map table instead.

### Backward Compatibility

The skill maintains full backward compatibility with v2.x projects (monolithic `research-hub.md`):
- Detects v2.x projects automatically (no `hub_type` field)
- Loads only the research report without attempting to load supporting files
- Uses trend landscape table from research report for kanban board

## Landing Page

When a `web-render/landing-page.html` file exists in the research project, it becomes a full-viewport cover page that fades into the tabbed report on CTA click.

### Detection

The export script checks for `{project_path}/web-render/landing-page.html`. If found, the HTML is loaded, wrapped in a `<div class="landing-page">` container, and injected before the report body. If absent, report output is unchanged (fully backward compatible).

### HTML Contract

The landing page HTML must follow these conventions:

| Element | Requirement | Purpose |
|---------|-------------|---------|
| CTA buttons/links | Add class `.lp-enter-report` | Triggers fade-out transition into report |
| Tab targeting | Optional `href="#tab-id"` or `data-target="#tab-id"` on CTA | Navigates to specific report tab after transition |
| Image paths | Use `./images/` relative paths | Auto-rewritten to `./web-render/images/` by the export script |
| Navbar brand | Auto: `.has-landing` class + `role="button"` when landing exists | Clickable home button to return to landing page |

### Behavior

1. Report loads in `landing-mode` — report UI is hidden, landing page is visible
2. Clicking `.lp-enter-report` triggers `enterReport()`:
   - Adds `landing-exit` class (0.4s fade-out via CSS transition)
   - Removes `landing-mode` class to reveal report
   - Defers `LoadingProgress.run()` init until report is visible
   - Navigates to target tab if `href` or `data-target` specified
3. Pressing **Escape** also enters the report (no tab targeting)
4. **Return to landing**: clicking the navbar brand (or pressing Enter/Space when focused) triggers `returnToLanding()`:
   - Adds `landing-enter` class (opacity 0) + `landing-mode` (shows landing, hides report)
   - CSS fades landing page in over 0.4s
   - Removes `landing-enter` after transition completes
   - Does NOT re-run `LoadingProgress` — report state is preserved
5. Print media: landing page is always hidden (`display: none !important`)
6. No-landing-page projects: navbar brand has no icon, no click behavior (standard static text)

### Image Path Rewriting

All `./images/` references in the landing HTML (whether in `src="..."`, `href='...'`, or `url(...)` CSS) are rewritten to `./web-render/images/` so that images resolve correctly from the report's output location.

## Theme CSS Generation

After resolving the theme path, generate a CSS `:root` block from the theme.md content before calling the export script. This requires careful reasoning to map descriptive color names to the correct CSS variables.

### Steps

1. **Resolve theme path:** Use `--list-themes` output to get the theme's `path` field, or resolve from `--theme` argument
2. **Read the theme.md file** to extract Color Palette, Status Colors, and Typography sections
3. **Apply the CSS Mapping Methodology** below to systematically generate all CSS variables
4. **Pipe CSS to script:** Combine CSS generation and export in a single bash command using heredoc. Pass `--theme-css-file -` to read CSS from stdin:

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-html-report/scripts/export_html_report.py" \
  --project "$project_path" \
  --theme-css-file - \
  --output "${project_path}/research-report.html" << 'THEME_CSS'
:root {
    --color-primary: #191919;
    /* ... all generated variables ... */
}
THEME_CSS
```

### CSS Mapping Methodology

Before writing the `:root` block, reason through the color mapping in 7 systematic steps. This prevents incorrect assignments (e.g., swapping primary and accent) that break the visual hierarchy, and ensures the generated CSS produces a cohesive UI across all report components.

**Step 1 — Extract palette entries**

Read theme.md `## Color Palette` section. For each entry, record:
- **Name** (e.g., "Dark Teal")
- **Hex** (e.g., `#0D3C55`)
- **Role description** (e.g., "Primary brand color, headings, dark backgrounds")

Also read `### Status Colors` if present. Also read `## Typography` for font families.

**Step 2 — Classify each color by CSS role**

Match each palette entry's role description to a CSS category using these keyword signals:

| Keywords in description | CSS Role | Primary variable |
|------------------------|----------|-----------------|
| "primary", "headings", "dark backgrounds", "brand color" | Primary | `--color-primary` |
| "accent", "links", "CTAs", "highlights", "interactive" | Accent | `--color-accent` |
| "main backgrounds", "slide backgrounds", "white", "clean" | Background | `--color-bg-primary` |
| "cards", "alternate sections", "subtle contrast" | Background Alt | `--color-bg-secondary` |
| "tinted", "tertiary background" | Background Tertiary | `--color-bg-tertiary` |
| "primary text", "body text", "text on light" | Text Primary | `--color-text-primary` |
| "text on dark", "light text", "white text" | Text Light | `--color-text-light` |
| "headers", "headings font", "display font" | Heading Font | `--font-heading` |

**Ambiguity rule:** If a color matches multiple roles, assign it to the highest-priority category (Primary > Accent > Background). A single hex value MAY intentionally serve as both `--color-primary` and `--color-text-primary` (e.g., dark teal used for headings AND body text).

**Step 3 — Derive variant colors**

From each base color, compute variants by adjusting HSL lightness:

| Base Variable | Derived Variable | Method |
|--------------|-----------------|--------|
| `--color-primary` | `--color-primary-dark` | Darken ~15% (clamp to 0) |
| `--color-primary` | `--color-primary-light` | Lighten ~15% |
| `--color-accent` | `--color-accent-light` | Lighten ~15% |
| `--color-accent` | `--color-accent-dark` | Darken ~10% |
| `--color-text-primary` | `--color-text-secondary` | Lighten ~25% (add gray) |
| `--color-text-secondary` | `--color-text-muted` | Lighten ~20% |
| `--color-text-muted` | `--color-text-tertiary` | Lighten ~15% |
| `--color-bg-secondary` | `--color-bg-code` | Slightly cooler tint (~3%) |
| `--color-text-muted` | `--color-border` | Lighten ~30% (toward bg) |
| `--color-border` | `--color-border-hover` | Darken ~10% |

**Derivation technique:** Convert hex to HSL. Adjust L (lightness) component. Convert back to hex. When "darkening," decrease L. When "lightening," increase L. Keep H and S stable.

**Heading font:** If theme has a separate header/display font, use it for `--font-heading` with a serif fallback stack (e.g., `'TeleNeo ExtraBold', Georgia, 'Times New Roman', serif`). If theme has only one font family, set `--font-heading` to the same as `--font-primary`.

**Step 4 — Map semantic aliases**

These are identity mappings from already-resolved values:

| Semantic Variable | Resolves To |
|-------------------|-------------|
| `--color-background` | Same as `--color-bg-primary` |
| `--color-background-alt` | Same as `--color-bg-secondary` |
| `--color-text` | Same as `--color-text-primary` |
| `--color-border-focus` | Same as `--color-accent` |

**Step 5 — Map status and info colors**

If theme.md includes `### Status Colors`, map them directly:

| Theme Entry | CSS Variable | Derive |
|------------|-------------|--------|
| Success | `--color-success` | `--color-success-light` = lighten 70% (for backgrounds) |
| Warning | `--color-warning` | — |
| (no Info entry) | `--color-info` = same as `--color-accent` | `--color-info-bg` = lighten accent 85% |

If no `### Status Colors` in theme.md, use these defaults:
- `--color-success: #2E7D32` / `--color-success-light: #e8f5e9`
- `--color-warning: #ED6C02`
- `--color-info:` same as `--color-accent` / `--color-info-bg:` lighten accent 85%

**Step 6 — Validate completeness**

Before writing the `:root` block, verify:
- All 26 color variables are assigned (see Variable Reference below)
- Text colors have sufficient contrast against their background (dark text on light bg, light text on dark bg)
- `--color-accent` is visually distinct from `--color-primary` (different hue or >30% lightness difference)
- Font family includes fallback stack (e.g., `'TeleNeo', 'Calibri', sans-serif`)
- Static variables (spacing, shadows, radii) are included as-is
- After variable completeness is confirmed, proceed to **Step 7** for component-level visual reasoning

**Step 7 — Component visual reasoning**

Before writing the `:root` block, mentally simulate how the resolved variables will render across the report's major UI components. This catches visual coherence issues that variable completeness alone cannot detect.

**7a. Component-Variable Map**

Trace each major report component to its CSS variable dependencies:

| Component | Key Variables | Visual Role |
|-----------|--------------|-------------|
| Report header | `primary` (3px border-bottom), `primary` (h1 color) | Brand anchor, first element seen |
| TOC sidebar (fixed 280px) | `bg-secondary` (background), `border` (right edge), `text-secondary` (links) | Navigation surface, must contrast with main area |
| TOC active link | `accent` (background), `text-light` (text) | Active indicator. **Verify:** text-light readable on accent |
| TOC hover | `bg-tertiary` (background), `primary` (text) | Subtle interaction feedback |
| Entity cards | `bg-primary` (surface), `border` (outline), `shadow-sm/md` (elevation) | Content containers, clear boundary against page |
| Entity type borders | 4px left borders: trend=`accent`, finding=`primary-light`, claim=`primary`, source=`text-muted`, concept=`accent-dark`, megatrend=`primary-light`, synthesis=`accent` | Type identification. **Verify:** all visible against `bg-secondary` header |
| Synthesis cards | `bg-tertiary` (full background) | Elevated emphasis for dimension syntheses |
| Insight hero (v3.0) | gradient(`bg-tertiary` → `bg-secondary`), `primary` (3px border), `primary` (label badge bg) | Premium section, highest visual prominence |
| Kanban board | `bg-tertiary` (headers), `bg-primary` (cells), `border` (grid), `bg-secondary` (cards) | Radar grid. Note: card-type dots are hardcoded; dimension swimlane colors use `--color-dim-*` palette |
| Blockquotes | `accent` (4px left border), `bg-secondary` (background), `text-secondary` (text) | Callout emphasis |
| Code blocks | `bg-secondary` (background), `border` (outline), `font-mono` | Must be distinct from surrounding text |
| Tables | `bg-secondary` (header + striped rows), `bg-tertiary` (hover), `border` (cell borders) | Data readability |
| Wikilinks | `accent` (text color) | In-text navigation cues |
| Wikilink popup | `bg-primary` (surface), `border` (outline), `shadow-lg` (elevation) | Floating overlay above all content |
| Back-to-top button | `primary` (background), `text-light` (icon), `primary-dark` (hover) | Floating circular action |
| Badges | Semantic tinted backgrounds via `--color-badge-*` variables (`rgba()` fallbacks) | Compact metadata labels |

**7b. Visual Hierarchy Check**

Reason through the 4-layer visual hierarchy the report creates:

1. **Structural skeleton** (primary color): Header bottom-border, heading colors, claim/megatrend entity borders, back-to-top button, insight label badge. Ask: *Is primary strong enough to anchor the page structure?*

2. **Attention/interaction layer** (accent color): Links, active TOC item, trend/synthesis entity borders, blockquote left borders, wikilink styling, story-arc badges. Ask: *Is accent visually distinct from primary AND readable as both foreground text and background fill?*

3. **Spatial depth** (background cascade): `bg-primary` (page surface) → `bg-secondary` (TOC, entity headers, code blocks) → `bg-tertiary` (hover states, synthesis cards, kanban headers). Ask: *Can the user perceive 3 distinct depth levels? Is each step at least noticeable?*

4. **Text readability cascade**: `text-primary` (body) → `text-secondary` (metadata, TOC links) → `text-muted` (captions, source entity borders) → `text-tertiary` (hints). Ask: *Does each level have sufficient contrast against its most common background?*

**7c. Dark Theme Branch**

If `--color-bg-primary` has HSL lightness < 25% (dark background), apply these adjustments:

| Light theme assumption | Dark theme adjustment |
|----------------------|----------------------|
| bg-primary is white/near-white | bg-primary is dark; bg-secondary must be *lighter* (e.g., `#1A1A1A` vs `#0A0A0A`) |
| bg-secondary → bg-tertiary goes lighter | Maintain upward progression: bg-tertiary *lighter* than bg-secondary |
| text-primary is dark | text-primary becomes light (`#E0E0E0`, not pure white for reduced eye strain) |
| Borders are light gray (`#d4dfe5`) | Borders need more lightness to be visible (e.g., `#333` or `rgba(255,255,255,0.12)`) |
| Shadows use `rgba(0,0,0,0.07-0.1)` | Invisible on dark; increase to `rgba(0,0,0,0.4)` or use accent-tinted glow: `0 4px 8px rgba(accent_r, accent_g, accent_b, 0.12)` |
| Entity 4px borders naturally visible | Verify all 7 border colors have >3:1 contrast against bg-secondary |
| text-light (#FFFFFF) used sparingly | On dark themes text-light may be similar to text-primary; ensure accent bg still makes active TOC link distinguishable |

**Dark theme shadow overrides** (replace the static defaults):
```css
--shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.3);
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.35);
--shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.5);
```
Or for themes with a "glow" design language (e.g., glassmorphism), use accent-tinted shadows:
```css
--shadow-sm: 0 1px 3px rgba(accent_r, accent_g, accent_b, 0.08);
--shadow-md: 0 4px 8px rgba(accent_r, accent_g, accent_b, 0.12);
--shadow-lg: 0 8px 20px rgba(accent_r, accent_g, accent_b, 0.18);
```

**7d. Badge Color Mapping**

The badge system uses 10 CSS variables (`--color-badge-*`) for tinted backgrounds. When generating theme CSS, derive badge tint values from the theme's semantic colors:

| Badge Variable | Derivation |
|---------------|------------|
| `--color-badge-dimension` | primary color at 9% opacity |
| `--color-badge-horizon-act` | success color at 9% opacity |
| `--color-badge-horizon-plan` | warning color at 9% opacity |
| `--color-badge-horizon-observe` | text-muted at 8% opacity |
| `--color-badge-evidence-strong` | success color at 9% opacity |
| `--color-badge-evidence-moderate` | warning color at 9% opacity |
| `--color-badge-evidence-weak` | error/red at 9% opacity |
| `--color-badge-confidence` | accent color at 9% opacity |
| `--color-badge-verified` | success color at 9% opacity |
| `--color-badge-contradicted` | error/red at 9% opacity |

For dark themes, increase opacity to 15-25% for visibility against dark backgrounds. If badge variables are omitted, `report-layout.css` uses built-in `rgba()` fallbacks optimized for light backgrounds.

Dimension colors (`--color-dim-1` through `--color-dim-8`) are used for kanban headers and graph nodes. The export script cycles through the palette algorithmically — no hardcoded slug mappings.

**7e. Quality Verification Checklist**

After generating all variables, verify these visual scenarios before writing the `:root` block:

- [ ] **TOC contrast**: bg-secondary is visibly different from bg-primary (the sidebar must be distinguishable from the main content area)
- [ ] **Active TOC readability**: text-light is readable on accent background (fails if accent is very light like `#FFE082` with white text)
- [ ] **Entity border visibility**: all 7 entity type border colors have visible contrast against bg-secondary (the entity header background)
- [ ] **Card separation**: entity cards (bg-primary + border + shadow) are visually distinct from the page background
- [ ] **Heading hierarchy**: headings in primary/text-primary are bolder/darker than text-secondary body text
- [ ] **Insight hero prominence**: the gradient from bg-tertiary to bg-secondary with 3px primary border creates a distinct featured section
- [ ] **Background depth**: bg-primary → bg-secondary → bg-tertiary creates 3 perceivable depth layers
- [ ] **Dark theme shadows**: if bg-primary lightness < 25%, shadow values have been overridden with higher opacity or accent glow

### CSS Variable Reference

Generate all variables below. **Theme-mapped** variables come from Steps 1-5. **Static** variables are copied as-is for every theme.

```css
:root {
    /* === Primary Family (Step 2 + Step 3) === */
    --color-primary: ;        /* headings, dark backgrounds, primary brand */
    --color-primary-dark: ;   /* darken primary ~15% */
    --color-primary-light: ;  /* lighten primary ~15% */

    /* === Accent Family (Step 2 + Step 3) === */
    --color-accent: ;         /* CTAs, links, highlights, interactive elements */
    --color-accent-light: ;   /* lighten accent ~15% */
    --color-accent-dark: ;    /* darken accent ~10% */

    /* === Background Family (Step 2 + Step 3) === */
    --color-bg-primary: ;     /* main background (usually #ffffff) */
    --color-bg-secondary: ;   /* cards, alternate sections */
    --color-bg-tertiary: ;    /* subtle tinted areas */
    --color-bg-code: ;        /* code snippet background (tinted bg-secondary) */

    /* === Text Family (Step 2 + Step 3) === */
    --color-text-primary: ;   /* main body text */
    --color-text-secondary: ; /* secondary text, metadata */
    --color-text-muted: ;     /* muted/caption text */
    --color-text-tertiary: ;  /* hints, tertiary text (lighten muted ~15%) */
    --color-text-light: ;     /* text on dark backgrounds (usually #ffffff) */

    /* === Border Family (Step 3 + Step 4) === */
    --color-border: ;         /* borders, dividers */
    --color-border-hover: ;   /* darken border ~10% */
    --color-border-focus: ;   /* same as accent */

    /* === Status Colors (Step 5) === */
    --color-success: ;        /* positive indicators, validated badges */
    --color-success-light: ;  /* success background tint */
    --color-warning: ;        /* caution, attention */
    --color-info: ;           /* informational elements (default: same as accent) */
    --color-info-bg: ;        /* info background tint (lighten accent ~85%) */

    /* === Semantic Aliases (Step 4) === */
    --color-background: ;     /* same as bg-primary */
    --color-background-alt: ; /* same as bg-secondary */
    --color-text: ;           /* same as text-primary */

    /* === Badge Tints (Step 7d — optional, has fallbacks) === */
    --color-badge-dimension: ;       /* primary at 9% opacity */
    --color-badge-horizon-act: ;     /* success at 9% opacity */
    --color-badge-horizon-plan: ;    /* warning at 9% opacity */
    --color-badge-horizon-observe: ; /* muted at 8% opacity */
    --color-badge-evidence-strong: ; /* success at 9% opacity */
    --color-badge-evidence-moderate: ; /* warning at 9% opacity */
    --color-badge-evidence-weak: ;   /* red at 9% opacity */
    --color-badge-confidence: ;      /* accent at 9% opacity */
    --color-badge-verified: ;        /* success at 9% opacity */
    --color-badge-contradicted: ;    /* red at 9% opacity */

    /* === Dimension Palette (static defaults, used for kanban/graph) === */
    --color-dim-1: #00b8d4;
    --color-dim-2: #5b2c6f;
    --color-dim-3: #1e8449;
    --color-dim-4: #ff6b4a;
    --color-dim-5: #3b82f6;
    --color-dim-6: #8b5cf6;
    --color-dim-7: #ec4899;
    --color-dim-8: #f59e0b;

    /* === Fonts (from Typography section) === */
    --font-primary: ;         /* body font + fallback, e.g. 'TeleNeo', 'Calibri', sans-serif */
    --font-heading: ;         /* heading font + fallback (h1-h6, entity titles, card stats) */
    --font-mono: 'SF Mono', 'Fira Code', Consolas, monospace;

    /* === Static: copy as-is for all themes === */
    --spacing-xs: 0.25rem;
    --spacing-sm: 0.5rem;
    --spacing-md: 1rem;
    --spacing-lg: 1.5rem;
    --spacing-xl: 2rem;
    --spacing-2xl: 3rem;
    --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.04);
    --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 10px rgba(0, 0, 0, 0.06);
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;
}
```

### Example

Given a theme.md with:

```markdown
## Color Palette
- **Dark Teal**: `#0D3C55` - Primary brand color, headings, dark backgrounds, footer
- **Vibrant Cyan**: `#00D7E9` - DIGITAL X wordmark, links, CTAs, interactive highlights
- **White**: `#FFFFFF` - Main slide backgrounds, clean content areas
- **Light Cyan**: `#E8F4F8` - Cards, alternate sections, subtle contrast
- **Text Primary**: `#0D3C55` - Primary text on light backgrounds
- **Text Light**: `#FFFFFF` - Text on dark backgrounds

### Status Colors
- **Success**: `#2E7D32` - Positive metrics, confirmation
- **Warning**: `#ED6C02` - Caution, attention needed

## Typography
- **Headers**: TeleNeo ExtraBold Italic / fallback: Calibri Bold
- **Body**: TeleNeo Regular / fallback: Calibri
```

**Step 1** extracts 6 palette entries + 2 status entries + font info.

**Step 2** classifies:
- Dark Teal (#0D3C55) → "Primary brand color, headings, dark backgrounds" → **Primary** → `--color-primary`
- Vibrant Cyan (#00D7E9) → "links, CTAs, interactive highlights" → **Accent** → `--color-accent`
- White (#FFFFFF) → "Main slide backgrounds" → **Background** → `--color-bg-primary`
- Light Cyan (#E8F4F8) → "Cards, alternate sections" → **Background Alt** → `--color-bg-secondary`
- Text Primary (#0D3C55) → "Primary text on light backgrounds" → **Text Primary** → `--color-text-primary`
- Text Light (#FFFFFF) → "Text on dark backgrounds" → **Text Light** → `--color-text-light`

**Step 3** derives variants:
- primary-dark: darken #0D3C55 → `#091f2c`
- primary-light: lighten #0D3C55 → `#1a5276`
- accent-light: lighten #00D7E9 → `#4de8f4`
- accent-dark: darken #00D7E9 → `#00b8d4`
- text-secondary: lighten #0D3C55 → `#2c5364`
- text-muted: lighten further → `#5a7a8a`
- text-tertiary: lighten further → `#8a9fad`
- bg-tertiary: tint #E8F4F8 cooler → `#e8f4f8` (already tinted)
- bg-code: tint #E8F4F8 slightly → `#f0f4f7`
- border: lighten text-muted → `#d4dfe5`
- border-hover: darken border → `#b8c9d4`

**Step 4** aliases: background=#FFFFFF, background-alt=#E8F4F8, text=#0D3C55, border-focus=#00D7E9

**Step 5** status: success=#2E7D32, success-light=#e8f5e9, warning=#ED6C02, info=#00D7E9 (=accent), info-bg=#e0f7fa

**Step 6** validates: 26 color vars assigned, dark text on white bg (pass), cyan distinct from teal (different hue, pass).

**Step 7** component check:
- **7a**: Dark Teal (#0D3C55) as primary creates strong header borders and heading colors. Entity type borders all distinct against Light Cyan (#E8F4F8) header background.
- **7b**: Structural skeleton (teal) anchors page. Attention layer (cyan) is highly distinct from teal (different hue, high saturation). White text-light (#FFFFFF) is readable on cyan (#00D7E9) active TOC background.
- **7c**: Light theme (bg-primary lightness=100%) — skip dark theme branch. Standard shadow values work.
- **7d**: Hardcoded badge rgbas designed for light backgrounds — compatible, no action needed.
- **7e**: Background cascade issue — bg-tertiary (`#e8f4f8`) equals bg-secondary (`#E8F4F8`), creating flat depth with only 2 perceivable layers. **Adjustment:** set bg-tertiary to `#d8eef4` for a slightly deeper tint that creates 3 distinct depth levels. All other checklist items pass.

**Dark theme counter-example** (cogni-work theme): bg-primary=`#0A0A0A`, accent=`#00D084`.
- Set bg-secondary=`#1A1A1A`, bg-tertiary=`#252525` for upward depth progression
- text-primary=`#E0E0E0` (not pure white, reduces eye strain)
- Borders: `#333333` for visibility against dark surfaces
- Shadows: use `rgba(0, 208, 132, 0.12)` accent glow per glassmorphism design language
- Entity borders: all 7 colors have >3:1 contrast against `#1A1A1A`
- Badge hardcoded rgbas will have reduced visibility on dark background (known limitation)

Generated output:

```css
:root {
    --color-primary: #0D3C55;
    --color-primary-dark: #091f2c;
    --color-primary-light: #1a5276;
    --color-accent: #00D7E9;
    --color-accent-light: #4de8f4;
    --color-accent-dark: #00b8d4;
    --color-bg-primary: #ffffff;
    --color-bg-secondary: #E8F4F8;
    --color-bg-tertiary: #d8eef4;
    --color-bg-code: #f0f4f7;
    --color-text-primary: #0D3C55;
    --color-text-secondary: #2c5364;
    --color-text-muted: #5a7a8a;
    --color-text-tertiary: #8a9fad;
    --color-text-light: #ffffff;
    --color-border: #d4dfe5;
    --color-border-hover: #b8c9d4;
    --color-border-focus: #00D7E9;
    --color-success: #2E7D32;
    --color-success-light: #e8f5e9;
    --color-warning: #ED6C02;
    --color-info: #00D7E9;
    --color-info-bg: #e0f7fa;
    --color-background: #ffffff;
    --color-background-alt: #E8F4F8;
    --color-text: #0D3C55;
    --font-primary: 'TeleNeo', 'Calibri', sans-serif;
    --font-heading: 'TeleNeo ExtraBold', Georgia, 'Times New Roman', serif;
    --font-mono: 'SF Mono', 'Fira Code', Consolas, monospace;
    --spacing-xs: 0.25rem;
    --spacing-sm: 0.5rem;
    --spacing-md: 1rem;
    --spacing-lg: 1.5rem;
    --spacing-xl: 2rem;
    --spacing-2xl: 3rem;
    --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.04);
    --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 10px rgba(0, 0, 0, 0.06);
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;
}
```

**Required CSS variables:** See [references/theme-integration.md](references/theme-integration.md) for full variable specification.

**Fallback behavior:** If theme not found and no `--theme-css-file` provided, uses sensible defaults (dark teal primary, white background, system fonts).

## HTML Output Structure

The report uses a **tab-based layout** with an Obsidian-style right panel:

```
Navbar: [Overview] [Dimensions] [Megatrends] [Trends] [Panel Toggle]
Main Area (tabs):              Right Panel (toggleable):
  Overview: Hero + nav cards     Graph: D3 force-directed
  Dimensions: Synthesis docs     Detail: Entity browsing
  Megatrends: Cross-dim forces     [Findings][Claims][Sources]...
  Trends: Kanban + entities
```

The right panel is collapsible to a 40px icon rail via the `PanelToggle` JS module. Clicking the `panel-toggle-btn` adds `body.panel-collapsed` and `.right-panel.collapsed`, shrinking the panel to a narrow rail with graph/detail icons. State persists across page loads via `localStorage` key `report-panel-collapsed`. Clicking any rail icon re-expands the panel and scrolls to the corresponding zone.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{project-title} - Research Report</title>
  <style>
    /* Theme variables */
    :root { --color-primary: #0d3c55; ... }
    /* Layout CSS from assets/report-layout.css */
  </style>
</head>
<body>
  <!-- Sticky horizontal navbar (replaces sidebar TOC) -->
  <nav class="report-navbar" role="navigation">
    <div class="navbar-brand">{project-title}</div>
    <div class="navbar-tabs" role="tablist">
      <button class="navbar-tab" data-tab="overview">Overview</button>
      <button class="navbar-tab" data-tab="synthesis">Dimensions</button>
      <button class="navbar-tab" data-tab="megatrends">Megatrends</button>
      <button class="navbar-tab" data-tab="trends">Trends</button>
    </div>
    <button class="navbar-hamburger" aria-label="Toggle menu">&#9776;</button>
  </nav>

  <!-- Main content area with tab panels -->
  <main class="report-main">
    <div id="panel-overview" class="tab-panel active">
      <!-- Insight hero + executive summary + navigation cards -->
    </div>
    <div id="panel-synthesis" class="tab-panel">
      <!-- Dimension synthesis entities -->
    </div>
    <div id="panel-megatrends" class="tab-panel">
      <!-- Megatrend entities -->
    </div>
    <div id="panel-trends" class="tab-panel">
      <!-- Kanban board + trend entities -->
    </div>
  </main>

  <!-- Right panel: graph + entity detail (collapsible, Obsidian-style) -->
  <aside class="right-panel">
    <button class="panel-toggle-btn" id="panel-toggle" aria-label="Toggle research panel">&#9776;</button>
    <div class="panel-rail" aria-hidden="true">
      <button class="panel-rail-icon" title="Graph" data-rail-action="graph">&#9673;</button>
      <button class="panel-rail-icon" title="Details" data-rail-action="detail">&#9776;</button>
    </div>
    <div class="graph-zone" id="graph-container">
      <!-- D3 force-directed graph (lazy-loaded) -->
    </div>
    <div class="graph-resize-handle" aria-hidden="true"></div>
    <div class="entity-detail-zone" id="entity-detail">
      <!-- Entity detail rendered on wikilink/card click -->
    </div>
  </aside>

  <script>
    const RADAR_DATA = { ... };  // Kanban board data
    const GRAPH_DATA = { ... };  // Entity relationship graph
    /* TabRouter + WikilinkPreview + KanbanBoard + GraphView */
  </script>
</body>
</html>
```

### Hash-Based Navigation

| URL Hash | Behavior |
|----------|----------|
| `#overview` / empty | Show Overview tab (default) |
| `#synthesis` | Show Dimensions tab |
| `#megatrends` | Show Megatrends tab |
| `#trends` | Show Trends tab |
| `#synthesis-dim-xyz` | Activate Dimensions tab, scroll to entity |
| `#trend-xyz` | Activate Trends tab, scroll to entity |
| `#finding-xyz` | Open right panel, Findings sub-tab, scroll to entity |
| `#claim-xyz` | Open right panel, Claims sub-tab, scroll to entity |

### Graph Data Structure

The `GRAPH_DATA` object is embedded as JSON for D3 visualization:

```json
{
  "nodes": [
    {"id": "trend-xyz", "type": "trend", "title": "...", "dimension": "...", "horizon": "act"}
  ],
  "links": [
    {"source": "trend-xyz", "target": "claim-abc", "type": "claim"}
  ]
}
```

Edges are extracted from entity metadata fields: `finding_refs`, `claim_refs`, `source_refs`, `portfolio_refs`, `source_ref`.

## Wikilink Resolution

The script converts Obsidian-style wikilinks to HTML anchor links:

| Input | Output |
|-------|--------|
| `[[finding-abc]]` | `<a href="#finding-abc">Finding Title</a>` |
| `[[04-findings/data/finding-abc]]` | `<a href="#finding-abc">Finding Title</a>` |
| `[[source-xyz\|Custom Label]]` | `<a href="#source-xyz">Custom Label</a>` |

Missing entities are rendered with a warning class: `<a href="#missing-id" class="wikilink-broken">missing-id</a>`

## Constraints

- DO NOT modify source files (read-only access)
- External CDN dependencies (D3.js, Mermaid) load with graceful offline fallbacks
- ALWAYS escape HTML in entity content
- ALWAYS use relative paths for internal links
- Handle missing entities gracefully (warn, don't fail)

## Error Handling

| Scenario | Response |
|----------|----------|
| `research-hub.md` missing | HALT with error |
| Entity directory missing | WARN, continue |
| Invalid frontmatter | WARN, skip entity |
| Theme not found | WARN, use fallback |
| Broken wikilink | Render with `.wikilink-broken` class |

## Success Criteria

- Single HTML file generated at output path
- All wikilinks resolved to anchor links with cross-panel routing
- Tab navigation works with hash-based routing
- Right panel shows graph view and entity detail browsing
- Theme CSS variables applied
- Offline-capable with graceful CDN fallbacks (D3, Mermaid)
- Print-friendly styles (all panels rendered linearly)
- Responsive at 768px and 1024px breakpoints
