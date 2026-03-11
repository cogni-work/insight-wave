# Design Variables Pattern for HTML Dashboards

Convention for producing themed, self-contained HTML dashboards across cogni plugins.

## 3-Stage Flow

1. **pick-theme** — User selects a theme via `cogni-workspace:pick-theme`. Returns `theme_path`, `theme_name`, `theme_slug`.
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
| `google_fonts_import` | Full `@import url(...)` string | Empty string if using system fonts |

Optional but recommended: `radius`, `shadows` (sm/md/lg/xl), `status` (success/warning/danger/info).

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

- **Canonical example**: `cogni-portfolio/skills/dashboard/` — full 3-stage flow with schema validation
- **Example JSON**: `cogni-workspace/schemas/examples/design-variables-cogni-work.json`
- **Theme entry point**: `cogni-workspace:pick-theme` skill
