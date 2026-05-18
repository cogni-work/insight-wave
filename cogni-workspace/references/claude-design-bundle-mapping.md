# Claude Design Bundle → Theme Materialisation Mapping

Single source of truth for how the `import-claude-design-bundle.py` importer
turns a Claude Design handoff bundle into a Theme System v2 (RFC #132 Phase 3)
theme directory. Read this with `references/theme-manifest.md` and
`docs/theme-system-v2-migration.md`.

A Claude Design bundle is a **gzipped tar archive** served at
`https://api.anthropic.com/v1/design/h/{hash}`. The bundle is the authoring
output of a Claude Design session and is the **re-syncable upstream** for a
local tiered theme — re-running the importer overwrites the materialised
tier files. Local hand-edits to imported files are not part of the workflow.

## Expected bundle shape

The importer assumes the following structure (anything else is workshop noise
and is ignored). All paths are relative to the tar root.

```
{slug}-design-system/                         (the single top-level directory)
├── README.md                                 ignored (coding-agent instructions)
├── chats/*.md                                ignored (design intent transcripts)
└── project/
    ├── README.md                             ignored in v1.0 (see "Open items")
    ├── {slug}-theme.md                       REQUIRED — materialised verbatim to theme.md
    ├── colors_and_type.css                   REQUIRED — parsed into tokens/*.json
    ├── preview/                              optional — see "Component allowlist"
    ├── slides/                               optional → components/deck/
    ├── uploads/                              optional → assets/
    ├── scratch/                              ignored (workshop output)
    └── comments/                             ignored (mirrored GitHub artifacts)
```

The bundle root directory name (`{slug}-design-system/`) must match the
theme slug. The importer derives the slug from the directory name and
records it in the sidecar.

## Mapping table

| Bundle path                            | Theme path                                 | Operation                                                                                       |
|----------------------------------------|--------------------------------------------|-------------------------------------------------------------------------------------------------|
| `project/{slug}-theme.md`              | `theme.md`                                 | Verbatim copy after the **voice-header pre-check** (see below)                                  |
| `project/colors_and_type.css`          | `tokens/*.json`                            | Regex-parse literal `--cw-*` declarations into the six canonical JSON files (see token table)   |
| (derived)                              | `tokens/tokens.css`                        | Regenerated via `scripts/generate-tokens-css.py generate(tokens_dir)` after JSON is written     |
| `project/preview/components-*.html`    | `components/web/<name>.html`               | Allowlisted (see "Component allowlist")                                                         |
| `project/preview/{colors,type,spacing,brand,components-fields,components-toggle-slider}-*.html` | — | Skipped (specimens or out-of-scope primitives)                                                  |
| `project/slides/index.html`            | `components/deck/index.html`               | Verbatim copy                                                                                   |
| `project/slides/*.js`                  | `components/deck/<name>.js`                | Verbatim copy (deck primitive helpers)                                                          |
| `project/uploads/*.png`                | `assets/<name>.png`                        | Verbatim copy                                                                                   |
| (derived)                              | `manifest.json`                            | Regenerated — declares only tiers the import actually populated                                 |
| (derived)                              | `.claude-design-source`                    | Sidecar JSON: `{url, sha256, imported_at, bundle_root, importer_version}`                       |

## Voice-section handling (auto-inject when absent)

Before writing the materialised `theme.md`, the importer reads the bundle's
`project/{slug}-theme.md` and looks for the literal header:

```
## Voice & Copy Guidelines
```

This header is the contract Phase D of `scripts/verify-theme-backcompat.sh`
enforces (lines 372–381) — it is a **structural marker**, not a content
check.

- **If the section is present** in the bundle, the importer copies the
  theme.md verbatim. Upstream voice content always wins.
- **If the section is absent**, the importer auto-injects a stub section
  before the `## Source` heading (or appends it at the end of the file
  when no Source section exists). The stub is clearly tagged as
  machine-generated and instructs the maintainer how to replace it by
  adding real voice content upstream and re-importing with
  `--allow-overwrite`.

The importer reports `voice_section: "bundled"` or
`voice_section: "auto-injected-stub"` in the success envelope so callers
can tell which path was taken.

The stub satisfies Phase D's structural invariant without burdening the
bundle author with voice prose the design tool cannot derive. The
importer does not synthesise voice content from the bundle's
`project/README.md` "Content fundamentals" — that section is intent
documentation for the bundle's coding agent, and conflating intent with
voice rules would mislead voice consumers. Real voice content is always
authored deliberately and beats the stub on every re-import.

The Explore audit that informed this design (search across
`cogni-narrative`, `cogni-sales`, `cogni-research`, `cogni-copywriting`,
and the visual consumers) found that **no consumer today parses the
voice section's content from `theme.md`** — the header is load-bearing
only in the backcompat harness and (now) in the importer's auto-inject
decision. The stub is therefore safe from a consumption standpoint; the
fidelity loss is purely informational for human readers of the theme
directory.

## CSS → JSON token projection

The bundle ships `project/colors_and_type.css` as a single `:root {}` block
with `--cw-*` prefixed custom properties plus a semantic layer
(`--fg-1`, `--bg-canvas`, etc.) and base element styles. The importer reads
only the **literal-value** declarations inside the `:root` block and projects
them into the six canonical token JSON files. Strip the `--cw-` namespace
prefix when projecting (so `--cw-primary: #111111;` becomes
`colors.json["primary"] = "#111111"`, which `generate-tokens-css.py` then
re-emits as `--colors-primary`).

| Bundle CSS prefix     | Target JSON      | Key transformation                            |
|-----------------------|------------------|-----------------------------------------------|
| `--cw-*` (colors)     | `colors.json`    | Strip `--cw-`; keep kebab-case                |
| `--font-*`            | `typography.json`| Strip `--`; keep kebab-case                   |
| `--fs-*`              | `typography.json`| `--fs-h1` → `size-h1`                         |
| `--lh-*`              | `typography.json`| `--lh-h1` → `line-height-h1`                  |
| `--ls-*`              | `typography.json`| `--ls-h1` → `tracking-h1`                     |
| `--sp-*`              | `spacing.json`   | `--sp-3` → `3`                                |
| `--r-*`               | `radii.json`     | `--r-md` → `md`                               |
| `--sh-*`              | `shadows.json`   | `--sh-md` → `md`                              |
| `--ease-*`            | `motion.json`    | `--ease-standard` → `ease-standard`           |
| `--dur-*`             | `motion.json`    | `--dur-fast` → `dur-fast`                     |

### Lossy projection — semantic layer dropped in v1.0

The bundle's semantic CSS layer references other CSS variables instead of
literal values:

```css
--fg-1: var(--cw-primary);
--bg-canvas: var(--cw-bg);
```

These cannot project into the canonical JSON tier (which stores literal
primitives only). The importer **drops** the semantic layer for v1.0. The
mapping doc records this as a deferred feature; the migration guide
documents the drop in its troubleshooting section.

Any `var()`-valued, `calc()`-valued, or `color-mix()`-valued declaration is
silently skipped. Only declarations whose value parses as a literal
(`#hex`, integer + unit, float + unit, bare integer/float, quoted string,
or comma-separated literal list — e.g. font stacks) are projected.

### Status color routing

Status colors in the bundle (`--cw-success`, `--cw-warning`, `--cw-danger`,
`--cw-info`) project into `colors.json` under unprefixed keys
(`success`, `warning`, `danger`, `info`) — same convention as the existing
local cogni-work `colors.json`.

## Component allowlist

The bundle ships 21 `preview/*.html` files. They divide cleanly into runtime
primitives (allowed) and specimens (skipped).

**Allowed → `components/web/<name>.html`** (strip the `components-` prefix
when computing the target filename):

| Bundle file                              | Theme file                          |
|------------------------------------------|-------------------------------------|
| `components-cards.html`                  | `components/web/cards.html`         |
| `components-buttons.html`                | `components/web/buttons.html`       |
| `components-badges.html`                 | `components/web/badges.html`        |
| `components-kpi.html`                    | `components/web/kpi.html`           |
| `components-table.html`                  | `components/web/table.html`         |
| `components-nav-tabs.html`               | `components/web/nav-tabs.html`      |

**Skipped — specimens (not primitives):**

| Pattern                       | Reason                                                |
|-------------------------------|-------------------------------------------------------|
| `colors-*.html`               | Color swatch reference                                 |
| `type-*.html`                 | Type specimen                                          |
| `spacing-*.html`              | Spacing / radii / shadow specimen                      |
| `brand-*.html`                | Brand-asset reference (logo, icons, dark anchor band)  |
| `voice-*.html`                | Voice & copy specimen pages (numbered VOICE · N — anatomy, do/don't, frameworks, microcopy, principles, registers, vocabulary, etc.); reference material, not runtime primitives |
| `components-fields.html`      | Form fields — deferred to a later phase (interactivity)|
| `components-toggle-slider.html`| Toggle/slider — deferred (interactivity)              |

If the bundle's `preview/` ships a file matching neither rule, the importer
logs a warning and skips it. This is permissive on purpose so new bundle
contents do not silently break the import; review the warning before
extending the allowlist.

## Deck primitives — `project/slides/`

The bundle ships `project/slides/index.html` and `project/slides/deck-stage.js`
(at minimum). The importer copies every file under `project/slides/` to
`components/deck/` verbatim. No allowlist filter; the slides directory is
treated as an opaque deck primitive bundle.

## Assets — `project/uploads/`

Every file under `project/uploads/` copies verbatim to `assets/`. The
importer never enters `project/scratch/` (workshop output).

## Manifest generation

The importer regenerates `manifest.json` from scratch on each run, declaring
only the tiers it actually populated. Required fields are filled from the
bundle slug:

```json
{
  "schema_version": "1.0",
  "name": "<derived from bundle slug, Title Case>",
  "slug": "<bundle slug>",
  "tiers": {
    "tokens": "tokens/",
    "assets": "assets/",
    "components": {
      "web": "components/web/",
      "deck": "components/deck/"
    }
  },
  "voice_ref": "theme.md#voice--copy-guidelines"
}
```

A tier key only appears when the import wrote at least one file under it.
`showcase` is **not** generated by the importer in v1.0 — the bundle's deck
primitives serve as the showcase surface via `components/deck/`.

The reserved keys `live`, `live_within_session`, `copy` are never emitted
and are forbidden anywhere in the manifest per RFC #132 schema v1.0.

## Sidecar file — `.claude-design-source`

Written **last**, only after `validate-theme-manifest.py` returns success.
Not part of the manifest contract (the validator ignores it). Format:

```json
{
  "url": "https://api.anthropic.com/v1/design/h/{hash}",
  "sha256": "<sha256 of the gzipped tar archive>",
  "imported_at": "<ISO 8601 UTC timestamp>",
  "bundle_root": "{slug}-design-system",
  "importer_version": "1.0"
}
```

The sidecar drives re-import idempotency: on the next run, if the URL is
unchanged and the freshly-fetched archive's sha256 matches, the importer
exits early as a no-op.

## Strict-abort conditions

The importer exits 1 with a clear message for any of:

| Condition                                                              | Triage                                                                                |
|------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| URL fetch fails or returns non-gzip                                    | Bundle URL invalid / expired — re-export from Claude Design                           |
| Archive contains no `{slug}-design-system/` top-level directory        | Bundle shape drift — file an issue if Claude Design output format changed             |
| `project/{slug}-theme.md` missing                                      | Bundle is incomplete — re-export                                                       |
| Bundle theme.md missing `## Voice & Copy Guidelines` header            | Not an abort condition — importer auto-injects a stub. See "Voice-section handling" above for the rationale and how to replace the stub with real content |
| `project/colors_and_type.css` missing                                  | Bundle is incomplete — re-export                                                       |
| `validate-theme-manifest.py` rejects the generated manifest             | Mapping bug — file an issue with the bundle URL and the validator error               |
| Target directory exists and `--allow-overwrite` not passed             | Pass `--allow-overwrite` (re-syncable upstream model)                                  |

## Cogni-work canary status

The user-provided cogni-work bundle
(`https://api.anthropic.com/v1/design/h/RSfNvYTiyDECwo4MqTaEFA`, exported
2026-04-25) does not contain `## Voice & Copy Guidelines` in its
`project/cogni-work-theme.md`. Under the auto-inject policy the importer
materialises the bundle successfully, inserting the voice stub before
the `## Source` section. The result passes Phase D of
`verify-theme-backcompat.sh` and is shippable as-is.

To complete the cogni-work migration to bundle-sourced authoring, run:

```bash
python3 cogni-workspace/scripts/import-claude-design-bundle.py \
    --url https://api.anthropic.com/v1/design/h/RSfNvYTiyDECwo4MqTaEFA \
    --target cogni-workspace/themes/cogni-work --allow-overwrite
bash cogni-workspace/scripts/verify-theme-backcompat.sh
```

For higher-fidelity voice content (real prose instead of the stub),
re-author the bundle in Claude Design with a structured
`## Voice & Copy Guidelines` section, re-export, and re-import — the
stub gets overwritten by the real content on the next run.

## Open items (deferred past v1.0)

- **Semantic CSS layer.** The bundle's `--fg-*`, `--bg-*`, and semantic
  helpers are dropped in v1.0. A future `tokens/semantic.json` 7th
  canonical file would let the generator preserve them; gated on
  `theme-manifest.schema.json` v1.1.
- **Form-field and toggle primitives.** Bundle's
  `components-fields.html` and `components-toggle-slider.html` are skipped
  because consumers expect static-render HTML primitives; revisit once a
  consumer can host interactive components.
- **Bundle `project/README.md` ingestion.** The bundle README carries
  rich brand context (positioning, content fundamentals, "Sources we
  worked from"). v1.0 treats it as intent documentation; a future phase
  could project selected sections into the theme's `theme.md` or a
  sibling `brand.md`.
- **Auto-bumping `name` casing.** v1.0 derives `name` from the slug via
  naive Title Case. A future phase could read a `brand_name` from the
  bundle README's H1 to preserve display names like "Cogni Work" exactly.
