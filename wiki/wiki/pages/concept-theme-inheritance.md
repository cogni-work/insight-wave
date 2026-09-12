---
id: concept-theme-inheritance
title: Theme inheritance (cogni-workspace as theme provider)
type: concept
tags: [themes, cogni-workspace, css, design-variables]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

All visual plugins read their theme from cogni-workspace. There's no per-plugin theme configuration — the workspace owns the look-and-feel for everything.

## How it works

1. **cogni-workspace owns the theme.** Themes live in the workspace's themes directory (imported from a Claude Design bundle via `manage-themes` Operation 10, or selected from a preset via `manage-themes` Operation 5).
2. **Visual plugins call `cogni-workspace:manage-themes`, Operation 11 (Select Theme).** This returns the active theme path, which the calling plugin records in YAML frontmatter (the `theme_path` contract — see [[concept-data-isolation]]).
3. **Rendering agents consume the theme as design variables.** The design-variables pattern produces themed CSS custom properties (`--color-primary`, `--font-heading`, `--spacing-unit`) that the rendering pipeline interpolates into output HTML/SVG/PPTX.

## Plugins that participate

- **cogni-workspace** — its own render agents (slides, infographic, storyboard, web) read the theme.
- **cogni-website** — site-assembler generates the shared CSS stylesheet from the theme; page-generator and hero-renderer interpolate variables.
- **cogni-portfolio** — the portfolio dashboard reads the theme for its HTML output.
- **cogni-trends, cogni-marketing** — dashboards pull the same theme for visual consistency.

## Why centralize themes

Three reasons:

- **Consistency across deliverables** — slides, infographics, dashboards, and the website all share the same color palette and typography because they all read from the same source.
- **Decoupled evolution** — the theme can change without any per-plugin update. Add a new corporate brand, and every dashboard refreshes on next render.
- **No per-plugin theme drift** — a plugin can't accidentally hardcode colors and diverge from the rest of the ecosystem.

## The design-variables pattern

CSS custom properties (`--var-name: value;`) defined at `:root` and consumed by per-component selectors. Rendering agents emit a `<style>` block at the top of any HTML output with the theme's variables; component templates use `var(--name)` everywhere a color/font/space appears. This pattern is the load-bearing convention for theme inheritance to actually work.

## Frontmatter contract

The `theme_path` YAML field is one of the documented frontmatter contracts in [[arch-er-diagram]] — set by cogni-workspace, read by its render agents.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
