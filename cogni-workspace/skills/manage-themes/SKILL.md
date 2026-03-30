---
name: manage-themes
description: >-
  Manage visual design themes for the workspace — extract themes from live
  websites (via Chrome), PowerPoint templates, or presets, then store and apply
  them to all visual outputs (slides, documents, diagrams, reports). Also audits
  and improves existing themes: contrast/accessibility checks, palette harmony,
  typography pairing, and completeness review. Use this skill whenever the user
  mentions themes, brand colors, visual identity, extracting styles, or wants
  consistent look-and-feel across outputs. Also triggers when the user wants to
  review, audit, fix, or improve a theme — e.g., "my theme feels off", "check
  contrast", "improve my colors". Also triggers when the user needs help choosing
  or building a theme — e.g., "what theme for my brand?", "help me pick a
  theme", "I need a visual identity for my startup". Even if the user just says
  "make it match our brand", "use our company colors", or "grab the style from
  that site", this skill applies. Also triggers on "brand guidelines", "design
  system", "brand identity", or "visual standards".
version: 0.2.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, Skill
---

# Manage Themes

## Why This Exists

Without centralized theme management, visual plugins each hardcode their own colors and fonts, producing inconsistent outputs. This skill provides a single place to create, store, audit, and apply themes so every visual output — slides, documents, diagrams, reports — shares a coherent brand identity. Themes are compact markdown files containing color palettes, typography, and design principles.

## Prerequisites

Before any operation, resolve the workspace themes directory:

1. Use `${COGNI_WORKSPACE_ROOT}/themes/` if the env var is set
2. Otherwise fall back to `{workspace}/cogni-workspace/themes/`
3. If the themes directory does not exist, create it (and `_template/` inside it) before proceeding

If Chrome browser automation tools are unavailable, inform the user upfront and suggest PPTX extraction or theme-factory presets as alternatives.

## Theme Storage

All themes live in the resolved themes directory. Each theme gets its own directory:

```
themes/
├── _template/theme.md    # Canonical template (see Theme File Format below)
├── digital-x/theme.md    # Brand theme
├── cogni-work/theme.md   # Brand theme
└── {custom}/theme.md     # User themes
```

When a theme slug already exists, ask the user whether to overwrite or create a versioned alternative (e.g., `acme-v2`).

## Operations

### 1. Recommend Theme

When the user asks for theme advice — e.g., "what theme for my brand?", "help me pick a theme", "I need a visual identity" — guide them through a short discovery to route them to the best creation path.

**Discovery questions** (ask only what's needed, skip what you can infer from context):

1. **Existing assets?** — "Do you have a website, PowerPoint template, or brand guidelines (colors/fonts) I can work from?"
2. **Industry & audience** — "What's the domain (fintech, healthcare, creative agency, etc.) and who sees these outputs?"
3. **Mood & tone** — "Any adjectives that describe the feel you're after? (e.g., bold & modern, calm & trustworthy, playful)"

**Routing logic based on answers:**

| User has... | Action |
|---|---|
| A website URL | → **Operation #3** (Grab from Website) — extract the real brand |
| A PPTX template | → **Operation #4** (Grab from PPTX) — extract from the template |
| Specific colors/fonts but no file | → Create a custom theme.md directly from their inputs, following the template |
| Nothing concrete, just a description | → **Operation #5** (Create from Preset) — recommend 2-3 theme-factory presets that match their mood/industry, let them pick or blend |
| An existing workspace theme that's close | → **Operation #6** (Audit/Improve) — review it and suggest targeted tweaks |

After creating or selecting a theme, always run a quick audit (Operation #6) on the result before finalizing — this catches contrast issues and missing sections early. Then offer to generate a theme showcase (Operation #7) so the user can see all tokens in action.

### 2. List Themes

When the user asks to list or show available themes, scan the themes directory:

Use the Glob tool to find all themes:
```
pattern: "*/theme.md"
path: "${COGNI_WORKSPACE_ROOT}/themes"
```

Present each theme with its name (directory name) and first line description from the theme.md file.

### 3. Grab Theme from Website

Extract a visual theme from a live website using Chrome browser automation. This produces a brand-accurate theme.md from real CSS and visual inspection.

**Requirements**: Chrome browser automation tools (`mcp__claude-in-chrome__*`). Before attempting website extraction, verify Chrome tools are available by checking if `mcp__claude-in-chrome__tabs_context_mcp` is callable. If unavailable, inform the user that Chrome browser automation is required and suggest using theme-factory presets or PPTX extraction instead.

**Workflow**:

1. Navigate to the target URL using Chrome
2. Take a screenshot for visual reference
3. Extract CSS design tokens using JavaScript execution:
   - Primary/secondary/accent colors from computed styles
   - Font families and sizes
   - Background colors
   - Border radius, spacing patterns
4. Calculate WCAG contrast ratios for extracted color pairs
5. Research the brand via WebSearch for design philosophy context
6. Generate theme.md following the template (see Theme File Format below)
7. Save to `{themes-dir}/{theme-slug}/theme.md`
8. Offer to generate a theme showcase (Operation #7)

**CSS Extraction Script** (execute via JavaScript tool):
```javascript
const cs = getComputedStyle(document.documentElement);
const body = getComputedStyle(document.body);
JSON.stringify({
  colors: {
    primary: cs.getPropertyValue('--primary-color') || cs.color,
    background: body.backgroundColor,
    text: body.color,
    links: getComputedStyle(document.querySelector('a') || document.body).color
  },
  typography: {
    heading: getComputedStyle(document.querySelector('h1,h2,h3') || document.body).fontFamily,
    body: body.fontFamily,
    headingSize: getComputedStyle(document.querySelector('h1') || document.body).fontSize
  }
});
```

Augment extracted values with visual inspection of the screenshot. Infer design principles from the overall visual language.

### 4. Grab Theme from PPTX

Extract theme from a PowerPoint template file. PPTX files embed theme XML in their ZIP structure — the key data lives in `ppt/theme/theme1.xml`.

**Workflow**:

1. Read the PPTX file using the `document-skills:pptx` skill to extract theme XML
2. Parse the OOXML color scheme (`a:clrScheme`) and map to semantic roles:
   - `dk1` → Text color
   - `lt1` → Background color
   - `dk2` → Secondary text
   - `lt2` → Surface/card background
   - `accent1` → Primary brand color
   - `accent2` → Secondary brand color
   - `accent3`–`accent6` → Additional palette colors
3. Parse the font scheme (`a:fontScheme`):
   - `a:majorFont` → Header font family
   - `a:minorFont` → Body font family
4. Generate theme.md following the template (see Theme File Format below)
5. Save to `{themes-dir}/{theme-slug}/theme.md`
6. Offer to generate a theme showcase (Operation #7)

### 5. Create Theme from Preset

Delegate to `document-skills:theme-factory` for preset theme creation:

1. Invoke the `theme-factory` skill to show available presets or create custom themes
2. Once user selects/creates a theme, capture the color palette and typography
3. Generate a theme.md following the template (see Theme File Format below)
4. Save to `{themes-dir}/{theme-slug}/theme.md`
5. Offer to generate a theme showcase (Operation #7)

This bridges theme-factory's preset system with the workspace's theme storage.

### 6. Audit / Improve Theme

When the user wants feedback on an existing theme — e.g., "my theme feels off", "check my colors", "improve this theme" — read the theme.md and evaluate it across these dimensions:

**Contrast & Accessibility**
- Calculate WCAG 2.1 contrast ratios for every foreground/background pair in the palette (Text on Background, Text on Surface, Text Muted on Background, etc.)
- Flag any pair below AA (4.5:1 for normal text, 3:1 for large text/UI elements)
- Suggest replacement hex values that fix failures while staying close to the original hue

**Palette Harmony**
- Check whether the palette follows a recognizable color scheme (complementary, analogous, triadic, split-complementary)
- Flag colors that feel disconnected — e.g., an accent that clashes with the primary
- Suggest adjustments that bring cohesion without losing brand identity

**Typography Pairing**
- Evaluate whether header and body fonts complement each other (contrast in weight/style without clashing)
- Flag if both fonts are the same family with no differentiation, or if a decorative font is used for body text
- Suggest alternatives from commonly available web/system fonts if pairing is weak

**Completeness**
- Compare against the template at `{themes-dir}/_template/theme.md`
- Flag missing sections (e.g., no Status Colors, no Design Principles, no Source)
- Flag palette roles that are absent — a theme needs at minimum: Primary, Background, Surface, Text

**Design Principles Review**
- Check whether the stated principles are actionable and specific enough for a downstream skill to follow
- Flag vague principles (e.g., "make it look good") and suggest concrete rewrites

**Output format**: Present findings as a checklist grouped by dimension, with pass/fail/warning per item and concrete suggestions for anything that fails. If the user agrees with suggestions, apply the fixes directly to the theme.md. After applying fixes, offer to regenerate the theme showcase (Operation #7) so the user can verify the changes visually.

### 7. Generate Theme Showcase

After creating, extracting, or improving a theme, offer to generate an interactive React showcase component that demonstrates every design token in context — colors, typography, buttons, cards, tables, forms, status badges, KPI panels, pricing layouts, and navigation patterns.

**When to offer**: After any successful theme creation or update (Operations 3–6), ask the user: *"Want me to generate a theme showcase component so you can see all the tokens in action?"*

**Workflow**:

1. Read the theme.md for the target theme
2. Generate a self-contained JSX file that renders every palette color, typography scale, button variant, card layout, status badge, data table, form element, and at least one dark-section/light-section pair — all wired to the theme's actual hex values, fonts, and design principles
3. Save to `{themes-dir}/{theme-slug}/{theme-slug}-theme-showcase.jsx`

**Output requirements**:

- Single-file React component using inline styles (no external CSS) — works in any React sandbox or claude.ai artifact
- A `theme` object at the top mapping every palette role (primary, secondary, accent, accentMuted, accentDark, bg, surface, surfaceDark, text, textLight, textMuted, border, plus status colors) to the hex values from theme.md
- Google Fonts link injected at runtime for the theme's font families
- Sections: Hero (dark), Color Palette grid, Typography scale, Buttons & interactions (toggle, slider), Navigation & Tabs, Cards, Status Badges + Data Table (dark), KPI Dashboard, Form Elements, Pricing example (dark), Footer
- Interactive elements using `useState` (tabs, toggle, slider, card selection) to show the theme in motion
- Design principles from the theme.md reflected in visual structure (e.g., dark-light rhythm, accent usage rules)
- The component name follows PascalCase of the theme slug (e.g., `cogni-work` → `CogniWorkThemeShowcase`)

**Reference**: See `themes/cogni-work/cogni-work-theme-showcase.jsx` as the canonical example of quality, structure, and completeness.

### 8. Apply Theme

When the user asks to apply a theme, read the theme.md and feed its contents into the downstream skill that produces the output.

1. Read the requested theme from `{themes-dir}/{name}/theme.md`
2. If the user hasn't specified which artifact to theme, ask them (e.g., "Apply this to which output — slides, a document, a diagram?")
3. Include the full theme.md content in the prompt/context when invoking the downstream skill. The consuming skill needs the raw color hex codes, font names, and design principles to apply them. For example:
   - **Slides** (`document-skills:pptx`): pass theme colors and fonts so they map to slide master styles
   - **Documents** (`document-skills:docx`): pass palette for heading colors, accent boxes, table styling
   - **Diagrams** (e.g., `cogni-visual:render-big-picture`, `cogni-visual:render-big-block`): pass primary/secondary/accent colors and design principles
   - **Web/HTML outputs**: pass full palette and typography for CSS variable mapping

The theme.md content is the single source of truth — always read it fresh rather than relying on cached or partial values.

## Theme File Format

Follow the template at `{themes-dir}/_template/theme.md`. Key sections:

- **Color Palette**: 6-12 colors with hex codes and usage descriptions
- **Status Colors**: Success, Warning, Danger, Info (standardized)
- **Typography**: Header, Body, Mono fonts with fallbacks
- **Design Principles**: 3-8 rules for visual consistency
- **Best Used For**: Target contexts
- **Source**: Origin (URL, PPTX file, preset name) and extraction date

## Naming Convention

Theme directories use kebab-case slugs derived from the brand/source name:
- `digital-x` (from DIGITAL X brand)
- `cogni-work` (from cogni-work.ai)
- `ocean-depths` (from theme-factory preset)
- `client-acme` (from client website)

## Additional Resources

### Template

- **`{themes-dir}/_template/theme.md`** — Canonical theme template with all sections. Read this template before generating any new theme to ensure all required sections are present.
- **`{themes-dir}/cogni-work/cogni-work-theme-showcase.jsx`** — Reference showcase component. Read this before generating a showcase for a new theme to match the expected quality, structure, and section coverage.
