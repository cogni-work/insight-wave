---
id: plugin-cogni-website
title: "cogni-website (plugin)"
type: entity
tags: [cogni-website, plugin, website, static-site, html, multi-page]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-website/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-website.md
status: stable
related: [concept-theme-inheritance]
---

> **Incubating** (v0.0.4) — skills may change or be removed at any time.

Assembles multi-page customer websites from portfolio, marketing, trend, and research content produced by other insight-wave plugins. Outputs a deployable static site with shared navigation, theming, and responsive HTML.

## Layer

[[concept-four-layer-architecture|Output layer]]. Pure renderer — every byte of content comes from upstream data plugins.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-website:website-setup` | Initialize project; discover content from cogni-portfolio, cogni-marketing, cogni-trends, cogni-knowledge; pick theme |
| `cogni-website:website-plan` | Plan site structure interactively — discover content, propose pages, map content to sections |
| `cogni-website:website-build` | Build the static site — orchestrate CSS generation, parallel page generation, hero rendering, sitemap |
| `cogni-website:website-preview` | Preview generated website in browser via claude-in-chrome; validate links; report structural issues |
| `cogni-website:website-legal` | Generate Impressum, Datenschutzerklärung, Cookie-Hinweis (or EU equivalents) per jurisdiction |
| `cogni-website:website-resume` | Resume status — show progress |

## Theme inheritance

Reads theme from cogni-workspace via `manage-themes` Operation 11 ([[concept-theme-inheritance]]). The site-assembler agent generates the shared CSS stylesheet from the theme; per-page generators interpolate design variables.

## Hero rendering

Uses pencil MCP for AI-generated imagery in homepage hero sections — see [[concept-mcp-server-map]]. The hero-renderer agent produces hero images aligned with the theme color palette and brand voice.

## Multi-source content discovery

The setup skill walks every other insight-wave plugin's project directories and offers to pull from them: portfolio propositions become "What we do" pages, marketing thought-leadership becomes blog posts, trend reports become insights pages, research becomes white papers.

## Integration

Upstream: cogni-portfolio (propositions, capabilities pages), cogni-marketing (thought-leadership, demand-gen), cogni-trends (trend reports), cogni-knowledge (wiki syntheses), cogni-workspace (theme). Downstream: deployable static site (terminal output).

**Source**: [cogni-website README](https://github.com/cogni-work/insight-wave/blob/main/cogni-website/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-website.md)
