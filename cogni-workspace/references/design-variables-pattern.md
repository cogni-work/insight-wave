# Design Variables Pattern for HTML Dashboards

Convention for producing themed, self-contained HTML dashboards across cogni plugins.

## 3-Stage Flow

1. **Select a theme** — User selects a theme via `cogni-workspace:manage-themes` Operation 11 (Select Theme). Returns `theme_path`, `theme_name`, `theme_slug`.
2. **LLM derives design-variables.json** — Read the theme file and produce a structured JSON with colors, fonts, shadows, and domain-specific tokens. Write it to `<project-dir>/output/design-variables.json`.
3. **Generator consumes JSON** — A Python (or other) script reads the design-variables JSON and injects values as CSS custom properties into the generated HTML.

## Recommended Core Tokens

Every design-variables file should include at minimum:

| Group | Tokens | Notes |
|-------|--------|-------|
| `colors` | `background`, `surface`, `text`, `accent`, `border` | Foundation palette |
| `colors` | `text_muted`, `text_light`, `surface2`, `surface_dark` | Derived variants |
| `colors` | `accent_muted`, `accent_dark` | Accent variants for hover/active states |
| `fonts` | `headers`, `body`, `mono` | Font stacks with system fallbacks |
| `google_fonts_import` | Full `@import url(<https-url>);` statement, or a bare `https://` URL | Empty string if using system fonts. The bare-URL form is canonicalized only by renderers wired to `cogni-workspace/scripts/sanitize-theme.py` (today only cogni-workspace `workspace-dashboard`) — elsewhere emit the full terminated `@import url(...);` statement |

Optional but recommended: `radius`, `shadows` (sm/md/lg/xl), `status` (success/warning/danger/info).

## Value Guard

Design-variables values reach the stylesheet as raw text, so a renderer that consumes `cogni-workspace/scripts/sanitize-theme.py` — today only cogni-workspace `workspace-dashboard`; the sibling dashboards in cogni-website, cogni-visual, cogni-trends, cogni-portfolio and cogni-consult are not yet wired — vets every value before it is interpolated. A rejected value is **silently replaced by the built-in default** and reported in that renderer's output envelope under `theme_warnings` — so a theme that renders is not necessarily a theme that was honoured in full. Check `theme_warnings` when a token appears to have no effect.

Each section is vetted under one of three profiles:

| Profile | Governs | Policy |
|---------|---------|--------|
| `strict` | `colors`, `status` | Denylist `<>{}();@\`, max 120 chars — rejects markup breakout and the `url()` / `@import` external-fetch surface |
| `font-aware` | `fonts`, `shadows`, `radius` | `strict`'s denylist minus the two paren characters, max 300, no shape gate — font stacks and shadow values legitimately need parens |
| `import-aware` | `google_fonts_import` alone | `font-aware`'s denylist and bound, plus a second anchored path accepting one `@import url(<https-url>);` statement or one bare `https://` URL, re-emitted in canonical terminated form |

`sanitize-theme.py` is the implementation and runs standalone against a design-variables file, with an optional `--profile=` override, to ask what a given profile would reject.

## Domain Extension Guidance

Each dashboard has different needs. Add domain-specific tokens freely:

- **Portfolio**: `status` colors for entity completion states
- **TIPS**: role colors (strategist, architect, etc.), severity tones, horizon bands
- **Catalog**: category accent colors, maturity stage indicators
- **Scoring UI**: score-range colors, threshold indicators

There is no strict shared schema — each plugin owns its own token vocabulary. The pattern is the convention, not the structure.

## LLM Derivation Tips

When generating design-variables from a theme file, the LLM should:

- Derive `surface2` (~4% darker than `surface`) if not explicit in the theme
- Compute `accent_muted` and `accent_dark` variants from `accent`
- Build a Google Fonts `@import` URL from the font families specified
- Adjust shadow opacity for dark themes (higher opacity for light-on-dark)
- Ensure **WCAG AA contrast** between `text`/`background` and `text_light`/`surface_dark`
- Set `radius` and `shadows` appropriate to the theme's visual style

## Reference Implementation

- **Canonical example**: `cogni-portfolio/skills/portfolio-dashboard/` — full 3-stage flow with schema validation
- **Example JSON**: `cogni-workspace/schemas/examples/design-variables-cogni-work.json`
- **Theme entry point**: `cogni-workspace:manage-themes` skill, Operation 11 (Select Theme)
