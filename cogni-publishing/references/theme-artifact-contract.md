# Theme artifact contract — `theme-artifact@1`

The public contract between the theme lifecycle, which cogni-publishing owns, and every plugin that consumes a theme. A consumer reads saved theme artifacts; it never needs to invoke authoring, and it never needs a cogni-workspace installation or initialisation.

## Selection handoff

A selection returns exactly three fields:

| Field | Value |
|-------|-------|
| `theme_path` | Absolute path to the selected `theme.md` |
| `theme_name` | The `theme.md` H1; the theme directory name when there is no H1 |
| `theme_slug` | The theme directory name, kebab-case |

The field names are the contract: they are never renamed, and no field is added to or dropped from the handoff. `manage-themes` Operation 11 returns them, `scripts/select-theme.py` emits them in its envelope, and `cogni-workspace:manage-themes` passes them through unchanged while it survives as a compatibility route.

Precedence when a consumer needs a theme: a `theme_path` it already holds from upstream wins; then an explicit path the user names; then a discovered theme, where a user theme shadows a bundled theme of the same slug.

## Where themes live

- **Bundled themes** ship in cogni-publishing's `themes/` and are versioned with the plugin.
- **User themes** live in one optional, user-owned directory: `--user-themes <dir>` when named, else `--workspace-root <root>`/themes, else `$COGNI_WORKSPACE_ROOT/themes/`, else the legacy auto-discovered workspace (`discover-themes.py` listings only). They are read in place; nothing in the lifecycle moves, renames or rewrites them during a read, and a read never creates the directory.

## One theme on disk

| Tier | Path | Status |
|------|------|--------|
| 0 | `theme.md` | Always valid on its own, with or without anything below |
| manifest | `manifest.json` | Optional; declares the tiers present — `references/theme-manifest.md` |
| 1 | `tokens/*.json` | The one authoritative representation of design variables — `references/token-subset.md` |
| 1, generated | `tokens/tokens.css`, `tokens/tokens.resolved.json` | Projections generated from the JSON; never edited by hand |
| 2 | `assets/` | Optional brand files |
| 3 | `components/` | Optional copy-on-use HTML primitives — `references/theme-component-loader.md` |
| 4 | `templates/` | Reserved |

A consumer that needs a CSS custom property reads `tokens.css`; one that cannot evaluate `var()` reads `tokens.resolved.json`, which keeps the alias map alongside the resolved literals. Both are regenerated from the JSON, so they cannot disagree with it without failing `validate-theme-manifest.py`.

## Consumer-owned design variables

Each consuming plugin owns the `design-variables.json` it derives from a selected theme and the CSS or HTML it renders from that file. The shape is `references/design-variables-pattern.md`. Owning that file is artifact consumption, not a second theme lifecycle: a consumer may reuse its saved design variables without re-running selection or authoring.
