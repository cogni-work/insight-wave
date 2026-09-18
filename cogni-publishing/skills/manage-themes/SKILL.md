---
name: manage-themes
description: >-
  Create, audit, improve, select, and apply visual design themes, no
  workspace required — sourced from Claude Design bundles or bundled presets. Audits
  cover contrast, palette harmony, typography pairing, and completeness. Use
  it whenever the user mentions themes, brand colors or visual identity,
  wants a consistent look-and-feel across outputs, or whenever a downstream
  skill needs a theme resolved before it renders. Trigger phrases include
  "pick a theme", "select a theme", "which theme", "choose theme", "apply a
  theme", "my theme feels off", "check contrast", "improve my colors", "what
  theme for my brand?", "I need a visual identity for my startup", "make it
  match our brand", "use our company colors", "grab the style from that
  site", "brand guidelines", "design system", "brand identity", "visual
  standards", "author tokens", "build a tiered theme system", "deepen a
  theme", and "match the cogni-work pattern". Also triggers on a Claude
  Design bundle URL (api.anthropic.com/v1/design/h/...).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
---

# Manage Themes

## Why This Exists

Without centralized theme management, visual plugins each hardcode their own colors and fonts, producing inconsistent outputs. This skill provides a single place to create, store, audit, and apply themes so every visual output — slides, documents, diagrams, reports — shares a coherent brand identity. Themes are compact markdown files containing color palettes, typography, and design principles.

cogni-publishing owns the whole theme lifecycle and works standalone: no cogni-workspace installation or initialisation is required. `cogni-workspace:manage-themes` survives only as a same-name route that delegates here.

## Prerequisites

Two theme locations exist, and they are never confused:

- **Bundled themes** ship with this plugin in `${CLAUDE_PLUGIN_ROOT}/themes/` — `cogni-work`, the four archetype presets and `_template/`. They are versioned with the plugin and never edited in place.
- **User themes** live in one optional, user-owned directory, resolved as: an explicit `--user-themes <dir>`, else `--workspace-root <root>`/themes, else `${COGNI_WORKSPACE_ROOT}/themes/` when that variable is set, else an auto-discovered workspace — for `discover-themes.py` listings only; `select-theme.py` never auto-discovers (see [Theme Selection Mechanics](references/theme-selection.md)). Existing user themes are read where they are; nothing moves or rewrites them. A user theme shadows a bundled theme of the same slug. Discovery labels these `source: workspace` and bundled ones `source: standard` — legacy labels kept for existing callers — so "workspace theme" below always means a theme in this user location.

Write operations (5 when forking or generating, 7, 10) write only to the user location, and create it — seeding `_template/` from `${CLAUDE_PLUGIN_ROOT}/themes/_template/` — on first use. When nothing resolves — no `--user-themes`, no `COGNI_WORKSPACE_ROOT`, no workspace — ask the user where their themes should live and pass that directory as `--user-themes` on this and later calls; never invent a location, because later discovery never scans a guessed directory. Operations 2, 9 and 11 never create anything: reading the catalog must not leave a directory behind in someone's workspace.

The saved-theme contract every consumer reads — the selection handoff, the tiers, the canonical tokens and their generated projections — is `${CLAUDE_PLUGIN_ROOT}/references/theme-artifact-contract.md`.

Themes are authored in Claude Design and imported as a bundle (Operation 10). If the user has no bundle, offer a bundled preset (Operation 5) or build a theme.md directly from colours and fonts they supply.

## Theme Storage

User themes live in the resolved user location; bundled themes share the same per-theme layout. Each theme gets its own directory:

```
themes/
├── _template/theme.md    # Canonical template (see Theme File Format below)
├── digital-x/theme.md    # Brand theme
├── cogni-work/theme.md   # Brand theme
└── {custom}/theme.md     # User themes
```

When a theme slug already exists, ask the user whether to overwrite or create a versioned alternative (e.g., `acme-v2`).

## Operations

Operation numbers are stable identifiers, not a running sequence. The live-website and PPTX extraction paths that once held 3 and 4 were retired in favour of Operation 10, and every surviving operation keeps its original number so existing references stay valid — the gap is expected, not a missing section. Operation 11 is listed first for the same reason it holds the highest number: it is the newest operation, and it is also the hot path every visual skill dispatches, so a caller that names no operation and needs a theme is reading Operation 11.

### 11. Select Theme

The single entry point for theme selection across the ecosystem. Every skill that produces themed output — slides, dashboards, web narratives, infographics, storyboards, HTML reports — resolves its theme here rather than implementing its own discovery.

**Step 1 — discover.** Run the discovery script for a JSON array of every available theme:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/discover-themes.py"
```

Each entry carries:

```json
{
  "slug": "cogni-work",
  "name": "Cogni Work",
  "description": "A bold, modern theme pairing electric chartreuse with deep black foundations.",
  "primary": "#111111",
  "accent": "#C8E62E",
  "background": "#FAFAF8",
  "font": "DM Sans Bold",
  "path": "/absolute/path/to/themes/cogni-work/theme.md",
  "source": "standard",
  "mtime": 1741564800.0
}
```

The script pre-sorts deterministically by recommendation — `cogni-work` first, then the remaining bundled themes in lexical slug order, then user themes in lexical slug order — so the first entry is always the best default candidate and no further sorting is needed. A user theme still shadows a bundled theme with the same slug. Two optional fields, `tiers` and `manifest_error`, appear only for themes shipping a manifest; see [Theme Selection Mechanics](references/theme-selection.md).

**Step 2 — present the picker.** Build AskUserQuestion options from the discovery output under four rules:

- Show up to 4 themes — the tool's maximum.
- If more than 4 exist, take the first 4 from the discovery output; it is already sorted by relevance.
- The first option is the recommended default — append "(Recommended)" to its label.
- If only 1 theme exists, skip the picker entirely and use it directly, telling the user which theme is being applied.

The "Other" escape hatch built into AskUserQuestion lets the user type a custom theme path.

```json
{
  "questions": [{
    "question": "Which theme would you like to use?",
    "header": "Theme",
    "multiSelect": false,
    "options": [
      {
        "label": "Cogni Work (Recommended)",
        "description": "#111111 + #C8E62E · DM Sans Bold · standard"
      },
      {
        "label": "Digital X",
        "description": "#0D3B4F + #00BCD4 · Inter Bold · workspace"
      }
    ]
  }]
}
```

Option format: `label` is the theme name, `description` is `{primary} + {accent} · {font} · {source}`. Keep a map of label to path from the discovery output so the selection resolves back to an absolute path.

When AskUserQuestion is unavailable — a headless or non-interactive run — take the first discovery entry, since the deterministic recommendation order puts `cogni-work` first when it is available, and name the auto-selected theme in the reply rather than proceeding silently.

**Step 3 — resolve the selection.** Resolve the choice through the selection script rather than by hand, so every route returns the same three fields. Resolve a listed theme by the absolute `path` of its discovery entry, taken from the label-to-path map Step 2 kept:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/select-theme.py" --theme-path <entry.path>   # a listed theme, or a path typed through "Other"
python3 "$CLAUDE_PLUGIN_ROOT/scripts/select-theme.py" --slug <slug>               # a named theme, when Step 1 did not run
```

Never re-resolve a listed theme by slug: `discover-themes.py` can auto-discover a workspace that `select-theme.py` never searches, so a slug lookup can miss the listed theme or return a bundled theme of the same slug instead. `--slug`, `--name` and `--default` serve callers that name a theme without running Step 1; they do not auto-discover, so pass them the same `--user-themes` or `--workspace-root` the discovery used. An explicit `--theme-path` (a `theme.md` or its directory) reads only that path — no workspace, no environment — so it works with no workspace set up at all. A non-zero exit means no such theme; say so and offer the picker again. When `data.color_palette` is `false`, warn that the theme lacks a Color Palette section before handing it on.

**Step 4 — return the contract.** Return `theme_path`, `theme_name` and `theme_slug` from the script's `data` verbatim. These three values are the **return contract** downstream skills depend on:

| Field | Value | Example |
|-------|-------|---------|
| **theme_path** | Absolute path to `theme.md` | `/Users/.../themes/cogni-work/theme.md` |
| **theme_name** | Human-readable name from the H1 | `Cogni Work` |
| **theme_slug** | Directory name (kebab-case) | `cogni-work` |

Downstream skills read design tokens straight from `theme_path`. Python scripts take it as `--theme <theme_path>`; skill-to-skill handoffs include it in the calling context.

**Skip conditions.** Selection is skipped when the caller already has a `theme_path` from upstream, when the caller runs non-interactively, or when only one theme exists (auto-select it). In those cases validate the provided path with `select-theme.py --theme-path` and proceed.

Themes are never created here — Operation 11 only reads. Sources, the optional discovery fields, stale-workspace auto-discovery and the no-themes and script-failure fallbacks are in [Theme Selection Mechanics](references/theme-selection.md).

### 1. Recommend Theme

When the user asks for theme advice — e.g., "what theme for my brand?", "recommend a theme", "I need a visual identity" — guide them through a short discovery to route them to the best creation path.

**Discovery questions** (ask only what's needed, skip what the context already answers):

1. **Existing assets?** — "Do you have a website, PowerPoint template, or brand guidelines (colors/fonts) I can use as a starting point?"
2. **Industry & audience** — "What's the domain (fintech, healthcare, creative agency, etc.) and who sees these outputs?"
3. **Mood & tone** — "Any adjectives that describe the feel you're after? (e.g., bold & modern, calm & trustworthy, playful)"

**Routing logic based on answers:**

| User has... | Action |
|---|---|
| A Claude Design bundle URL (`api.anthropic.com/v1/design/h/<hash>`) | → **Operation 10** (Import from Claude Design Bundle) — the recommended authoring path; ships tokens, components, and assets in one re-syncable step |
| A website URL or a PPTX template | → **Operation 10** (Import from Claude Design Bundle) — recreate the source in Claude Design, then import the bundle |
| Specific colors/fonts but no file | → **Operation 5** — create their own theme from those inputs, following the template |
| Nothing concrete, just a description | → **Operation 5** — start from `cogni-work` or an archetype preset, or generate a custom theme from the description |
| An existing workspace theme that's close | → **Operation 6** (Audit/Improve) — review it and suggest targeted tweaks |
| Existing themes, just wants to choose one | → **Operation 11** (Select Theme) — no interview needed |

After creating or selecting a theme, always run a quick audit (Operation 6) on the result before finalizing — this catches contrast issues and missing sections early. Then offer to generate a theme showcase (Operation 8) so the user can see all tokens in action.

This operation is the interview, not the picker. If the user simply wants to choose among existing themes, that is Operation 11.

### 2. List Themes

When the user asks to list or show available themes, run the same enumerator Operation 11 uses, so the list covers bundled and workspace themes alike:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/discover-themes.py" --pretty
```

Present each theme with its name, slug, source (standard or workspace), description, primary and accent colours, and font. A Glob over the workspace themes directory alone would miss every bundled theme, so it is not the enumerator here.

### 5. Create Theme — from a bundled preset or your own inputs

Two paths, one operation. Both end at a contrast-audited theme; neither depends on anything outside this plugin.

**Start from a bundled preset in `$CLAUDE_PLUGIN_ROOT/themes/`:**

1. Select through Operation 11. Present `cogni-work` first and mark it recommended — it is the reference theme every consumer already exercises — then the archetype presets: `boardroom` (corporate/enterprise), `clean-slate` (minimal grayscale), `signal` (bold accent), `editorial` (warm editorial/print).
2. Ask whether to use it as-is or fork it. **Using it as-is writes nothing** — a bundled preset is already discoverable and already has a path.
3. To fork, copy `theme.md`, `manifest.json` and every tier directory the manifest declares into `<user-themes>/<new-slug>/`, the user location resolved in Prerequisites. Default to a *new* slug, so the user copy does not shadow the bundled one. A same-slug override is allowed when the user wants it; `check-theme-drift.py` will then report the slug as shadowed, which is accurate — explain the advisory rather than suppressing it.
4. Update the forked `theme.md` — its name, description and `Origin` — to reflect the fork, and its `manifest.json` `name` and `slug` to match the new directory. After a palette, type or spacing edit to an archetype-preset fork, re-run `derive-theme-tokens.py <user-themes>/<new-slug> --overwrite`; never hand-edit its token JSON.

**Create your own theme when no candidate fits.** Build a new tier-0 theme from whatever the user supplies — a description of mood, industry and audience; explicit colors and fonts; or a preset to blend from:

1. Name the slug per the [Naming Convention](#naming-convention) below.
2. Write `theme.md` following `{themes-dir}/_template/theme.md` end to end, so every section the template defines is present.
3. Emit a starter `manifest.json` beside it (see [Starter Manifest](#starter-manifest) below).
4. Run the Operation 6 script-backed contrast audit **before** reporting success, and fix or explain any pair below AA.
5. Show the result for review.

Both paths then validate with `validate-theme-manifest.py`, offer to deepen into a tiered theme system (Operation 7), and offer a theme showcase (Operation 8).

Presets are versioned with the plugin; a fork is the user's own theme.

### 6. Audit / Improve Theme

When the user wants feedback on an existing theme — e.g., "my theme feels off", "check my colors", "improve this theme" — read the theme.md and evaluate it across these dimensions:

**Contrast & Accessibility** — measured, never estimated. Build a flat `{"role": "#rrggbb"}` JSON map of the palette, then read the verdicts out of the script:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/check-contrast.py" <palette.json>
```

Build the map from `tokens/colors.json` when the theme is tiered, otherwise from the `## Color Palette` bullets in its `theme.md`, keyed with the role names the script pairs on, and report only what the script measured — never recompute a ratio or substitute a hex of your own. How to build and key the map, and how to read `pairs`, `unclassified`, `collisions`, `failures`, `suggested_hex`, `evaluated` and `success: false`, is in [Contrast Audit](references/contrast-audit.md); read it before reporting any contrast verdict.

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
- Flag palette roles that are absent — a theme needs at minimum: Primary, Background, Surface, Text, plus Text Muted, Accent and Border, which design-render also requires

**Design Principles Review**
- Check whether the stated principles are actionable and specific enough for a downstream skill to follow
- Flag vague principles (e.g., "make it look good") and suggest concrete rewrites

**Output format**: Present findings as a checklist grouped by dimension, with pass/fail/warning per item and concrete suggestions for anything that fails. If the user agrees with suggestions, apply the fixes directly to the theme.md. If the tokens were derived from it, re-run `derive-theme-tokens.py <themes-dir>/<slug> --overwrite` so the renderer and audit see the fix; imported tokens take it in Claude Design. After applying fixes, offer to regenerate the theme showcase (Operation 8) so the user can verify the changes visually.

**Manifest handling**: If the theme already has a `manifest.json`, leave it untouched (the audit fixes go in `theme.md`). If the theme is tier-0 and the audit surfaces structural needs that tokens would solve — e.g., the same hex repeats across many surfaces, downstream skills hard-code values that should swap by theme — offer to promote the theme via Operation 7 (Author a Deep Theme System) rather than expanding `theme.md` further. If the theme has neither a `theme.md` nor a `manifest.json` (rare — Op 6 mostly acts on existing themes), emit a starter `manifest.json` (see [Starter Manifest](#starter-manifest) below) so the next operation has an entry point.

### 7. Author a Deep Theme System

When a theme outgrows the single-file `theme.md` and the user wants structured authoring — variable swap-out by downstream skills, component primitives, voice/copy templates — promote the theme to a **tiered** layout per Theme System v2. This operation is opt-in: tier-0 themes (`theme.md` only, no manifest) remain valid forever.

**When to offer**: After a successful Operation 5 (ask: *"Want to deepen this into a tiered theme system?"*), or when the user explicitly asks to "build a deep theme", "author tokens", "make this brand a system", or "match the cogni-work pattern". The end-to-end walkthrough lives at [`docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md). Read that guide first when promoting a tier-0 theme; this operation is the in-skill entry point, the guide is the authoritative how-to.

**Reference implementation**: `themes/cogni-work/` is the canonical tiered theme. Read its `manifest.json` and `tokens/` layout before authoring any new tiered theme — that file shape is the contract every downstream consumer expects.

**The four tiers** — populate in this order; each tier is independently optional, but tokens is the foundation:

1. **Tier 1 — Tokens** (`tokens/`). The canonical design variables — the one authoritative representation of the theme. Seven canonical files: `colors.json`, `typography.json`, `spacing.json`, `radii.json`, `shadows.json`, `motion.json`, and the optional `semantic.json` for role tokens (`fg`, `bg`, `surface`, …) — design-render reads role colours as keys of `colors.json`, never through `semantic.json`. Each is a `{key: value}` map. A value is a literal (string or number), an alias to another token written exactly `{<stem>.<key>}` — `"fg": "{colors.text}"` keeps the role pointing at the primitive rather than copying its hex — or a DTCG token object carrying `$value`. The supported shapes, and what is deliberately outside them, are in `${CLAUDE_PLUGIN_ROOT}/references/token-subset.md`; it is a bounded subset, not full DTCG support. Generate the projections deterministically from these JSON sources — never hand-edit them:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/generate-tokens-css.py" \
       --tokens-dir <themes-dir>/<slug>/tokens --write
   ```
   The generator emits a single `:root { ... }` block with `--<stem>-<key>` custom properties in canonical-file then alphabetical-key order; an alias becomes a `var()` reference, so the role survives into the CSS. When the theme carries an alias it also writes `tokens.resolved.json`, every token resolved to its literal plus the alias map, for consumers that cannot evaluate `var()` (a PPTX renderer, a colour audit). An alias cycle, a reference no file defines, or an unsupported construct fails the run with the offending token named, and writes nothing.

2. **Tier 2 — Assets** (`assets/`). Brand-bound static files — logos (SVG preferred), reference fonts, sample documents, hero imagery. Flat layout is fine; nested directories are allowed where the asset family naturally groups (e.g., `assets/logos/`).

3. **Tier 3 — Components** (`components/`). Portable HTML primitives that downstream skills can copy-on-use — copy-on-use is the default, and an opt-in live-theme binding is reserved rather than implemented. JSX is allowed but optional; HTML is the contract. Both rules are settled in [`docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md). Each component is one file; reference the theme's tokens via CSS custom properties (e.g., `var(--colors-primary)`) so consumers inherit the active palette without rewriting markup.

4. **Tier 4 — Templates** (`templates/`). Voice-and-copy scaffolds — IS/DOES/MEANS messaging templates, headline patterns, CTA wording. Deferred — the directory is reserved but most themes will not populate it yet; see [`docs/theme-system-v2-migration.md`](../../docs/theme-system-v2-migration.md).

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
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-theme-manifest.py" <themes-dir>/<slug>
```

A non-zero exit means the theme is not shippable; fix the failure before declaring the operation complete.

**Workflow** (typical promotion of an existing tier-0 theme):

1. Derive `tokens/` from `theme.md` rather than transcribing it:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/derive-theme-tokens.py" <themes-dir>/<slug>
   ```
   It reads `## Color Palette`, the `## Typography` font rows, `### Type Scale` and `## Spacing Scale`, and writes `colors.json`, `typography.json` and `spacing.json` with every literal copied verbatim (font families are joined into a quoted CSS stack) under the role keys design-render reads (`bg`, `text-muted`, `font-sans`, `size-h2`, …); `tokens.css` is compiled from them by `generate-tokens-css.py`. A role the file lacks stays absent, so design-render names it — add the row to `theme.md` (a `Border` row is the usual gap) and re-run with `--overwrite`, never hand-edit the derived JSON. Without `--overwrite` it refuses to write over tokens a theme already ships. Radii, shadow and motion values and `semantic.json` aliases stay optional hand-authored additions.
2. Check that the derived values are the ones `theme.md` states. After any hand-authored addition, run `generate-tokens-css.py --write` to refresh `tokens.css`.
3. Update `manifest.json` to declare `tiers.tokens: "tokens/"`.
4. Optionally populate `assets/` and `components/` — only what the user actually needs.
5. Run `validate-theme-manifest.py` and confirm `success: true`.
6. Offer to regenerate the theme showcase (Operation 8) so the tokens render against the canonical primitives.

### 8. Generate Theme Showcase

After creating, importing, or improving a theme, offer to generate an interactive React showcase component that demonstrates every design token in context — colors, typography, buttons, cards, tables, forms, status badges, KPI panels, pricing layouts, and navigation patterns.

**When to offer**: After any successful theme creation, deepening, update, or bundle import (Operations 5–7 and 10), ask the user: *"Want me to generate a theme showcase component so you can see all the tokens in action?"*

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

1. Resolve the theme through Operation 11 — match a named theme against the discovery output by slug or name, skip the picker, and resolve that entry's `path` through Step 3 — then read `theme_path`. Resolving rather than building a path is what lets Operation 9 reach a bundled theme as well as a workspace one.
2. If the user hasn't specified which artifact to theme, ask them (e.g., "Apply this to which output — slides, a document, a diagram?")
3. Include the full theme.md content in the prompt/context when invoking the downstream skill. The consuming skill needs the raw color hex codes, font names, and design principles to apply them. For example:
   - **Slides** (`document-skills:pptx`): pass theme colors and fonts so they map to slide master styles
   - **Documents** (`document-skills:docx`): pass palette for heading colors, accent boxes, table styling
   - **Diagrams and dashboards** (e.g., `cogni-portfolio:portfolio-dashboard`): pass primary/secondary/accent colors and design principles
   - **Web/HTML outputs** (e.g., `cogni-website:website-build`): pass full palette and typography for CSS variable mapping

The theme.md content is the single source of truth — always read it fresh rather than relying on cached or partial values.

### 10. Import from Claude Design Bundle

The recommended authoring path for tiered themes under Theme System v2. The user authors a complete design system in Claude Design (claude.ai/design) — tokens, components, assets, and theme.md prose — then exports a handoff bundle at `https://api.anthropic.com/v1/design/h/<hash>`. This operation materialises the bundle into a Theme System v2 theme directory in one re-syncable step. Claude Design is an optional input, not a dependency: the bundle layout is what exported bundles have been observed to contain rather than a published API, a local `--bundle` archive imports with no network access, and saved themes are consumed without any Claude Design call.

**Why this replaced the live website and PPTX extraction paths**: Claude Design is the authoring tool; this operation is the importer. The bundle ships a complete tiered theme — tokens (canonical JSON + generated CSS), HTML component primitives, deck primitives, and brand assets — that older operations could only produce piecemeal at tier-0. Re-running the importer is idempotent: the bundle is the upstream truth, the local theme directory is the materialised mirror.

**Prerequisites**:
- A Claude Design bundle URL (the user gets one from claude.ai/design at the end of an authoring session). The URL is a stable handle for that bundle version — re-exporting produces a new URL.
- The bundle's `project/{slug}-theme.md` ideally contains a `## Voice & Copy Guidelines` section (the Theme System v2 Phase D structural contract checks the header exists). If the section is missing, the importer auto-injects a clearly-tagged stub so the import still succeeds and the backcompat harness still passes. Real voice content always beats the stub — re-author the bundle with a structured voice section and re-import with `--allow-overwrite` to replace the stub.

**Workflow**:

1. Ask for the Claude Design bundle URL (or path to a local `.tar.gz` for testing). Confirm the target theme slug — typically derived from the bundle's root directory `{slug}-design-system/`.
2. Resolve the target theme directory in the user location: `<user-themes>/{slug}/`. If the directory already exists and is non-empty, ask the user to confirm overwrite (the operation passes `--allow-overwrite` to the importer).
3. Run the importer:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/import-claude-design-bundle.py" \
       --url <bundle-url> --target <themes-dir>/<slug> [--allow-overwrite]
   ```
   For testing or air-gapped flows, swap `--url` for `--bundle <path>` against a local `.tar.gz`. Use `--dry-run` to preview what would be written without touching the target.
4. Inspect the JSON envelope. The importer reports the materialised slug, sha256 of the bundle, populated tiers, the semantic aliases it kept (`aliases`), allowlisted components written, specimens skipped, components warned-about (preview files matching no rule — review and either extend the allowlist in `${CLAUDE_PLUGIN_ROOT}/references/claude-design-bundle-mapping.md` or accept the skip), assets, and the validator payload. Report `aliases_dropped` and `declarations_dropped` to the user rather than passing over them: each names a bundle variable the theme could not hold and why. A bundle alias that loops or references an undeclared variable fails the whole import before anything is written; relay the finding and ask the user to fix it in Claude Design.
5. The importer runs `validate-theme-manifest.py` itself before writing the `.claude-design-source` sidecar — a successful import means the theme is already schema-valid. Then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-theme-backcompat.sh"` to confirm the broader integration contract (Phase A discover, Phase B consumer references, Phase D voice section).
6. Offer to regenerate the theme showcase (Operation 8) so the new tokens render against the canonical primitives. Operation 7 (deep theme authoring) is unnecessary after Op 10 — the bundle ships tiered already.

**Re-syncability**: When the user re-exports the bundle from Claude Design (e.g., after iterating on the design), they get a new URL. Re-run the importer with the new URL and `--allow-overwrite`; the materialised theme refreshes from upstream. Idempotency is preserved at the sha256 level — running the importer against an unchanged URL is a no-op. Overwrite is predictable: the sidecar records every file the importer wrote, a re-import replaces those and removes the ones the new bundle no longer produces, and any file the user added to the theme directory keeps its bytes.

**Mapping details**: The bundle → theme materialisation rules (which preview files become components, how `colors_and_type.css` projects into the canonical token JSON files, which `var()` aliases are kept, which bundle directories are ignored) live in `${CLAUDE_PLUGIN_ROOT}/references/claude-design-bundle-mapping.md`. Edits to that mapping doc are the right place to extend or constrain importer behaviour; the script reads its rules from there as the source of truth. A bundle that omits a structured `## Voice & Copy Guidelines` section takes the auto-inject policy in Prerequisites: the import succeeds with a clearly-tagged stub inserted before `## Source`, and replacing that stub with real voice content follows the re-author-and-re-import remedy stated there.

## Theme File Format

Follow the template at `{themes-dir}/_template/theme.md`. Key sections:

- **Color Palette**: 6-12 colors with hex codes and usage descriptions, including a Border row — design-render requires `colors.border`, and the contrast audit grades it at 3:1 against Background and Surface
- **Status Colors**: Success, Warning, Danger, Info (standardized)
- **Typography**: Header, Body, Mono fonts with fallbacks
- **Design Principles**: 3-8 rules for visual consistency
- **Best Used For**: Target contexts
- **Source**: Origin (Claude Design bundle URL, preset name) and import date

## Starter Manifest

Operations 5 and (conditionally) 6 emit a minimal `manifest.json` next to `theme.md` for every newly-created theme. The file is the entry point that lets a tier-0 theme opt in to Theme System v2 later (via Operation 7) without renaming or restructuring anything that already shipped:

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<theme-slug>",
  "tiers": {}
}
```

- `schema_version` is always `"1.0"` for now — it pins the file to the current `${CLAUDE_PLUGIN_ROOT}/references/theme-manifest.schema.json`.
- `name` is the human-readable theme name (e.g., `"Cogni Work"`).
- `slug` matches the directory name (kebab-case, see [Naming Convention](#naming-convention) below).
- `tiers` starts empty (`{}`); tiers are added by Operation 7 only when the user explicitly populates them.

Operation 5 finishes by running `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-theme-manifest.py" <themes-dir>/<slug>` to confirm the manifest is schema-valid before the operation reports success.

**Backwards-compat:** `_template/` and any pre-existing tier-0 theme without a manifest stay valid forever — Operation 6 (Audit/Improve) preserves the manifestless layout unless the user explicitly asks to promote via Operation 7.

## Naming Convention

Theme directories use kebab-case slugs derived from the brand/source name:
- `digital-x` (from DIGITAL X brand)
- `cogni-work` (from cogni-work.ai)
- `boardroom` (bundled preset)
- `client-acme` (from client brand name)

## Additional Resources

### References

- **`references/theme-selection.md`** — Operation 11 mechanics: the two theme source roots, the optional `tiers` and `manifest_error` discovery fields, stale-workspace auto-discovery, and the fallbacks for no themes found, a failed discovery script, or an unavailable AskUserQuestion. Read it when a selection behaves unexpectedly; Operation 11 above is sufficient for the normal path.
- **`references/contrast-audit.md`** — how to build the palette map for `check-contrast.py` and read every field of its output. Read it before reporting an Operation 6 contrast verdict.
- **`${CLAUDE_PLUGIN_ROOT}/references/theme-artifact-contract.md`** — the saved-theme contract. Read it when handing a theme to a consumer.
- **`${CLAUDE_PLUGIN_ROOT}/references/token-subset.md`** — the accepted token shapes. Read it when authoring or importing tokens.

### Template

- **`{themes-dir}/_template/theme.md`** — Canonical theme template with all sections. Read this template before generating any new theme to ensure all required sections are present.
- **`{themes-dir}/cogni-work/cogni-work-theme-showcase.jsx`** — Reference showcase component. Read this before generating a showcase for a new theme to match the expected quality, structure, and section coverage.

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
