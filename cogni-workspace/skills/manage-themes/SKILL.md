---
name: manage-themes
description: >-
  Create, audit, improve, select, and apply visual design themes for the
  workspace — sourced from Claude Design bundles or bundled presets. Audits
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

<!-- compatibility-delegate: cogni-publishing -->

# Manage Themes (compatibility route)

The theme lifecycle — selection, recommendation, creation, audit, deep authoring, showcase, application and Claude Design bundle import — belongs to **cogni-publishing**. This skill keeps the `cogni-workspace:manage-themes` name working for the callers that still dispatch it, and does no theme work of its own.

## Delegate

1. Invoke the Skill tool with `cogni-publishing:manage-themes` and pass the request through unchanged: the same operation (operation numbers are shared, so Operation 11 is still Select Theme), the same arguments, and any `theme_path` the caller already holds.
2. Return the delegated result unchanged. For Operation 11 that is exactly the three-field handoff — `theme_path` (absolute path to the selected `theme.md`), `theme_name` (its H1) and `theme_slug` (its directory name, kebab-case). Never rename, drop or add a field.
3. Never discover, create, import, validate, compile or store a theme here. A second implementation in this plugin is precisely what the ownership move removed.

## When cogni-publishing is not installed

When the Skill tool cannot find `cogni-publishing:manage-themes`, stop and tell the user that the theme lifecycle moved to cogni-publishing: install cogni-publishing from the insight-wave marketplace and retry. Say what still works in the meantime — a caller that already holds a `theme_path` can keep reading that `theme.md` directly, and existing user themes stay exactly where they are; nothing was moved or overwritten.
