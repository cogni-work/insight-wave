---
name: manage-themes
description: >-
  Manage visual design themes for the workspace — extract themes from live
  websites (via claude-in-chrome), PowerPoint templates, or presets, then store and apply
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
  system", "brand identity", or "visual standards", or when the user wants to
  "author tokens", "build a tiered theme system", "deepen a theme", or "match
  the cogni-work pattern".
version: 0.4.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, Skill, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__get_page_text
---

# Manage Themes

## Why This Exists

Without centralized theme management, visual plugins each hardcode their own colors and fonts, producing inconsistent outputs. This skill provides a single place to create, store, audit, and apply themes so every visual output — slides, documents, diagrams, reports — shares a coherent brand identity. Themes are compact markdown files containing color palettes, typography, and design principles.

## Prerequisites

Before any operation, resolve the workspace themes directory:

1. Use `${COGNI_WORKSPACE_ROOT}/themes/` if the env var is set
2. Otherwise fall back to `{workspace}/cogni-workspace/themes/`
3. If the themes directory does not exist, create it (and `_template/` inside it) before proceeding

If claude-in-chrome tools are unavailable, inform the user upfront and suggest PPTX extraction or theme-factory presets as alternatives.

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

After creating or selecting a theme, always run a quick audit (Operation #6) on the result before finalizing — this catches contrast issues and missing sections early. Then offer to generate a theme showcase (Operation #8) so the user can see all tokens in action.

### 2. List Themes

When the user asks to list or show available themes, scan the themes directory:

Use the Glob tool to find all themes:
```
pattern: "*/theme.md"
path: "${COGNI_WORKSPACE_ROOT}/themes"
```

Present each theme with its name (directory name) and first line description from the theme.md file.

### 3. Grab Theme from Website

Extract a visual theme from a live website using claude-in-chrome (the user's Chrome browser). This produces a brand-accurate theme.md from visual inspection and page analysis.

**Requirements**: claude-in-chrome tools (`mcp__claude-in-chrome__*`). Before attempting website extraction, try `mcp__claude-in-chrome__tabs_context_mcp` to verify availability. If unavailable, inform the user that the Claude-in-Chrome extension is required and suggest using theme-factory presets or PPTX extraction instead.

**Workflow**:

1. Open a new tab using `tabs_create_mcp` — never hijack the user's active tab
2. Navigate to the target URL using `navigate`
3. Use `read_page` to get the page's visual structure and content
4. Use `get_page_text` to extract text styles and structural patterns
5. Analyze the page to identify:
   - Primary/secondary/accent colors from headers, buttons, CTAs
   - Font families from headings and body text
   - Background colors and surface patterns
   - Border radius, spacing patterns
6. Research the brand via WebSearch for design philosophy context and official brand colors
7. Calculate WCAG contrast ratios for extracted color pairs
8. Generate theme.md following the template (see Theme File Format below)
9. Save to `{themes-dir}/{theme-slug}/theme.md`
10. Emit a starter `manifest.json` next to `theme.md` (see [Starter Manifest](#starter-manifest) below) and validate with `validate-theme-manifest.py` before completing
11. Offer to deepen this into a tiered theme system (Operation #7)
12. Offer to generate a theme showcase (Operation #8)

**Tips for accurate extraction**: Take multiple screenshots (hero section, navigation,
footer) to capture the full palette. Use WebSearch to find the brand's official style
guide or press kit — these often list exact hex codes. Cross-reference visual inspection
with any brand documentation found online.

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
6. Emit a starter `manifest.json` next to `theme.md` (see [Starter Manifest](#starter-manifest) below) and validate with `validate-theme-manifest.py` before completing
7. Offer to deepen this into a tiered theme system (Operation #7)
8. Offer to generate a theme showcase (Operation #8)

### 5. Create Theme from Preset

Delegate to `document-skills:theme-factory` for preset theme creation:

1. Invoke the `theme-factory` skill to show available presets or create custom themes
2. Once user selects/creates a theme, capture the color palette and typography
3. Generate a theme.md following the template (see Theme File Format below)
4. Save to `{themes-dir}/{theme-slug}/theme.md`
5. Emit a starter `manifest.json` next to `theme.md` (see [Starter Manifest](#starter-manifest) below) and validate with `validate-theme-manifest.py` before completing
6. Offer to deepen this into a tiered theme system (Operation #7)
7. Offer to generate a theme showcase (Operation #8)

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

**Output format**: Present findings as a checklist grouped by dimension, with pass/fail/warning per item and concrete suggestions for anything that fails. If the user agrees with suggestions, apply the fixes directly to the theme.md. After applying fixes, offer to regenerate the theme showcase (Operation #8) so the user can verify the changes visually.

**Manifest handling**: If the theme already has a `manifest.json`, leave it untouched (the audit fixes go in `theme.md`). If the theme is tier-0 and the audit surfaces structural needs that tokens would solve — e.g., the same hex repeats across many surfaces, downstream skills hard-code values that should swap by theme — offer to promote the theme via Operation #7 (Author a Deep Theme System) rather than expanding `theme.md` further. If the theme has neither a `theme.md` nor a `manifest.json` (rare — Op 6 mostly acts on existing themes), emit a starter `manifest.json` (see [Starter Manifest](#starter-manifest) below) so the next operation has an entry point.

### 7. Author a Deep Theme System

When a theme outgrows the single-file `theme.md` and the user wants structured authoring — variable swap-out by downstream skills, component primitives, voice/copy templates — promote the theme to a **tiered** layout per Theme System v2 (RFC #124). This operation is opt-in: tier-0 themes (`theme.md` only, no manifest) remain valid forever.

**When to offer**: After a successful Operation 3, 4, or 5 (ask: *"Want to deepen this into a tiered theme system?"*), or when the user explicitly asks to "build a deep theme", "author tokens", "make this brand a system", or "match the cogni-work pattern". A migration guide that walks an existing tier-0 theme through the upgrade end-to-end is tracked in [#130](https://github.com/cogni-work/insight-wave/issues/130) — once that lands, the file will be available at `references/theme-migration-guide.md`.

**Reference implementation**: `themes/cogni-work/` is the canonical Phase-2 pilot. Read its `manifest.json` and `tokens/` layout before authoring any new tiered theme — that file shape is the contract every downstream consumer expects.

**The four tiers** — populate in this order; each tier is independently optional, but tokens is the foundation:

1. **Tier 1 — Tokens** (`tokens/`). Canonical design variables as flat JSON maps. Six canonical files: `colors.json`, `typography.json`, `spacing.json`, `radii.json`, `shadows.json`, `motion.json`. Each is a `{key: value}` map with primitive values (string, integer, or float — nested values are silently skipped in v1.0). Generate `tokens/tokens.css` deterministically from these JSON sources — never hand-edit the CSS:
   ```bash
   python3 cogni-workspace/scripts/generate-tokens-css.py \
       --tokens-dir <themes-dir>/<slug>/tokens --write
   ```
   The generator emits a single `:root { ... }` block with `--<stem>-<key>` custom properties in canonical-file then alphabetical-key order. Re-running it must produce a byte-identical file (idempotency check via `git diff --exit-code`).

2. **Tier 2 — Assets** (`assets/`). Brand-bound static files — logos (SVG preferred), reference fonts, sample documents, hero imagery. Flat layout is fine; nested directories are allowed where the asset family naturally groups (e.g., `assets/logos/`).

3. **Tier 3 — Components** (`components/`). Portable HTML primitives that downstream skills can copy-on-use (per RFC open question 2 resolution: copy-on-use is the default, opt-in live-theme is reserved). JSX is allowed but optional; HTML is the contract per RFC open question 3 resolution. Each component is one file; reference the theme's tokens via CSS custom properties (e.g., `var(--colors-primary)`) so consumers inherit the active palette without rewriting markup.

4. **Tier 4 — Templates** (`templates/`). Voice-and-copy scaffolds — IS/DOES/MEANS messaging templates, headline patterns, CTA wording. Out of scope for Phase 2 (deferred to Phase 3 per RFC open question 5); the directory is reserved but most themes will not populate it yet.

**Manifest update**: Each tier you populate gets a corresponding entry in `manifest.json`. The `tiers` map is the contract — `discover-themes` and downstream consumers route exclusively through it:

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<theme-slug>",
  "tiers": {
    "tokens": "tokens/",
    "assets": "assets/",
    "components": "components/"
  }
}
```

Reserved keys `live`, `live_within_session`, and `copy` must never appear at any nesting depth (the validator hard-fails on them).

**Validate before completing**: Always run the validator after touching a tiered theme — it checks schema conformance, that declared tier paths exist, and (when `tokens.css` is present) that it matches `generate()` byte-for-byte:

```bash
python3 cogni-workspace/scripts/validate-theme-manifest.py <themes-dir>/<slug>
```

A non-zero exit means the theme is not shippable; fix the failure before declaring the operation complete.

**Workflow** (typical promotion of an existing tier-0 theme):

1. Read the existing `theme.md` to extract palette, typography, and design principles.
2. Create `tokens/`; split the palette into `colors.json`, fonts into `typography.json`, and any spacing/radii/shadow/motion values into the corresponding canonical files.
3. Run `generate-tokens-css.py --write` to emit `tokens.css`; verify the diff is what you expect.
4. Update `manifest.json` to declare `tiers.tokens: "tokens/"`.
5. Optionally populate `assets/` and `components/` — only what the user actually needs.
6. Run `validate-theme-manifest.py` and confirm `success: true`.
7. Offer to regenerate the theme showcase (Operation #8) so the tokens render against the canonical primitives.

### 8. Generate Theme Showcase

After creating, extracting, or improving a theme, offer to generate an interactive React showcase component that demonstrates every design token in context — colors, typography, buttons, cards, tables, forms, status badges, KPI panels, pricing layouts, and navigation patterns.

**When to offer**: After any successful theme creation, deepening, or update (Operations 3–7), ask the user: *"Want me to generate a theme showcase component so you can see all the tokens in action?"*

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

### 9. Apply Theme

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

## Starter Manifest

Operations 3, 4, 5, and (conditionally) 6 emit a minimal `manifest.json` next to `theme.md` for every newly-created theme. The file is the entry point that lets a tier-0 theme opt in to Theme System v2 later (via Operation #7) without renaming or restructuring anything that already shipped:

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<theme-slug>",
  "tiers": {}
}
```

- `schema_version` is always `"1.0"` for now — it pins the file to the current `references/theme-manifest.schema.json`.
- `name` is the human-readable theme name (e.g., `"Cogni Work"`).
- `slug` matches the directory name (kebab-case, see [Naming Convention](#naming-convention) below).
- `tiers` starts empty (`{}`); tiers are added by Operation #7 only when the user explicitly populates them.

Operations 3–5 finish by running `python3 cogni-workspace/scripts/validate-theme-manifest.py <themes-dir>/<slug>` to confirm the manifest is schema-valid before the operation reports success.

**Backwards-compat:** `_template/` and any pre-existing tier-0 theme without a manifest stay valid forever — Operation 6 (Audit/Improve) preserves the manifestless layout unless the user explicitly asks to promote via Operation #7.

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
