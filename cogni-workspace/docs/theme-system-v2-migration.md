# Theme System v2 — Migration Guide

How to convert a tier-0 theme (single `theme.md`) into a tiered Theme System v2 theme (`manifest.json` + `tokens/` + optional `assets/`, `components/`, `templates/`). The walkthrough uses `cogni-workspace/themes/cogni-work/` as the worked example — every snippet maps to a file you can read on disk.

> **You don't have to migrate.** Tier-0 themes (`theme.md` only, no manifest) are first-class and supported indefinitely. Migrate when you actually need structured tokens, reusable component primitives, or shared templates — not because tier-0 feels "old".

## When to migrate

Promote a theme to tiered when **any** of these is true:

- The same hex value repeats across many surfaces (slides, dashboards, web pages) and downstream skills hard-code it. Tokens make the swap a single-file edit.
- Multiple consumer skills want to render the same kind of UI primitive (slide layout, card, KPI panel) and currently each ships its own inline template. Components let you author the primitive once.
- You ship to several brands (white-label) and need to swap palette + voice without touching consumer-skill code.
- A downstream consumer requires `tokens.css` to live in the theme directory rather than be hand-derived (e.g., `cogni-visual:render-html-slides` `--theme-slug`).

If none of those apply, stay at tier-0. The deeper tiers exist because compounding gains kick in once they exist; no theme is worse for skipping them.

## What you keep

`theme.md` is canonical and stays put. Migration is **additive** — you create new files alongside `theme.md`, you do not restructure or delete it.

- ✅ Keep `theme.md` exactly as-is. Voice and copy rules live there.
- ✅ Keep your existing palette, typography, and design principles in `theme.md`. Tokens *mirror* them as JSON so consumers can read them mechanically; they do not replace `theme.md` as the human-readable source.
- ✅ Keep any existing `theme-showcase.jsx`, `*.pptx`, sample images. They're tier-2 assets and the manifest can declare them after migration.
- ❌ Never delete `theme.md` "because tokens cover it now". `theme.md` carries the *why* (design principles, brand voice); tokens carry the *what* (hex codes, font families). Both are needed.

## Step-by-step walkthrough — cogni-work as the worked example

The four tiers populate in order. Each is independently optional, but tokens is the foundation.

### Step 0. Decide which tiers you need

| Tier | Directory | What it holds | Skip when |
|------|-----------|---------------|-----------|
| 1 — Tokens | `tokens/` | JSON design variables (colors, typography, spacing, radii, shadows, motion) and a generated `tokens.css` | Almost never — tokens are the foundation for the other tiers |
| 2 — Assets | `assets/` | Brand-bound static files (logos, reference fonts, sample documents, hero imagery) | When the theme ships no static binary brand assets |
| 3 — Components | `components/` | Portable HTML primitives downstream skills copy-on-use, organized by surface (`components/deck/`, `components/dashboard/`, …) | When no consumer skill currently needs theme-supplied primitives — defer until at least one does |
| 4 — Templates | `templates/` | Voice/copy scaffolds (IS/DOES/MEANS templates, headline patterns, CTA wording) | Phase 2 — the manifest schema reserves the directory but Phase 3 will define semantics |

For most themes, tier 1 + tier 2 (logos/fonts) is enough to start. Add tier 3 only when a downstream skill is ready to consume it.

### Step 1. Tier 1 — Tokens

The cogni-work pilot exposes one canonical token directory:

```
cogni-workspace/themes/cogni-work/tokens/
├── colors.json
├── typography.json
├── spacing.json
├── radii.json
├── shadows.json
├── motion.json
└── tokens.css      ← GENERATED, do not hand-edit
```

Each `*.json` file is a flat `{key: value}` map with primitive values (string, integer, or float — nested values are silently skipped in v1.0). The canonical file order is `colors → typography → spacing → radii → shadows → motion`.

**Author the JSON.** For the migration, copy every hex, font, and dimension out of `theme.md` into the matching `tokens/<file>.json`. Use kebab-case for keys (e.g., `accent-muted`, not `accentMuted`).

**Generate `tokens.css`.** Never hand-edit this file — drift is a hard validation failure. Run:

```bash
python3 cogni-workspace/scripts/generate-tokens-css.py \
    --tokens-dir cogni-workspace/themes/<your-slug>/tokens --write
```

This emits a single `:root { ... }` block with `--<stem>-<key>` custom properties, in canonical-file then alphabetical-key order. The generator is deterministic — re-running it must produce a byte-identical file.

**Why generated, not hand-authored:** the validator compares the on-disk `tokens.css` byte-for-byte against the regenerated output. Hand edits drift; the generator does not. This is the load-bearing reason to keep CSS as a *generated* artifact.

### Step 2. Tier 2 — Assets (optional)

Brand-bound binary files belong in `assets/`. Layout is loose — flat is fine, nested directories are allowed where the asset family naturally groups (`assets/logos/`, `assets/fonts/`).

The cogni-work pilot keeps its showcase JSX, sample deck, and reference theme.md alongside the manifest at the theme root rather than in `assets/`. That's a legacy choice; new themes should put binary assets in `assets/`.

```
themes/<your-slug>/assets/
├── logo.svg
├── logo-dark.svg
└── hero-cover.png
```

### Step 3. Tier 3 — Components (optional, deferred for cogni-work today)

Components are HTML primitives downstream skills can copy-on-use. JSX is allowed but optional; HTML is the contract per RFC #124 open question 3 resolution.

Organize by **surface** — the consumer-skill family that uses the primitive:

```
themes/<your-slug>/components/
├── deck/
│   ├── title-slide.html
│   ├── content-slide.html
│   ├── metrics-slide.html
│   └── cta-slide.html
├── dashboard/
│   └── kpi-panel.html
└── narrative/
    └── pull-quote.html
```

Reference theme tokens via CSS custom properties (e.g., `var(--colors-primary)`) so consumers inherit the active palette without rewriting markup. Components SHOULD use `{placeholder}` markers that match the consuming skill's vocabulary; they SHOULD NOT contain absolute paths or skill-specific JavaScript — both belong to the consuming skill.

**Authoring rule:** primitives only, not compositions. A `title-slide.html` is a primitive. A "5-slide pitch deck composed of title + 3 content + cta" is a composition; that lives in the consuming skill, not in the theme.

**Cogni-work today:** the cogni-work pilot does not yet ship `components/deck/` — the loader infrastructure in `cogni-visual:render-html-slides` is in place (`--theme-slug` + the loader at `cogni-visual/scripts/load-theme-component.py`), but the deck-component family is a deferred follow-up. When it ships, this section will gain a worked example.

### Step 4. Tier 4 — Templates (deferred to Phase 3)

The schema reserves the `templates/` directory and the `tiers.templates` manifest entry, but Phase 2 does not define semantics. Skip this tier in v1.0.

### Step 5. Author `manifest.json`

Land the manifest after the tier directories exist. Each tier you populated gets a corresponding entry; tiers you skipped are simply absent.

**Minimum manifest** (just opted in to v2, no tiers populated yet — what Operations 3–6 of `manage-themes` emit by default):

```json
{
  "schema_version": "1.0",
  "name": "<Theme Name>",
  "slug": "<your-slug>",
  "tiers": {}
}
```

**Full manifest** (cogni-work pilot, current on-disk shape):

```json
{
  "schema_version": "1.0",
  "name": "Cogni Work",
  "slug": "cogni-work",
  "tiers": {
    "tokens": "tokens/"
  },
  "showcase": "cogni-work-theme-showcase.jsx",
  "voice_ref": "theme.md#voice--copy-guidelines"
}
```

**Reserved keys.** `live`, `live_within_session`, and `copy` are reserved at every nesting depth and the validator hard-fails on them. They're held back for Phase 3's live-theme work; do not use them in v1.0.

The full schema is `cogni-workspace/references/theme-manifest.schema.json` (JSON Schema draft-07). The reference doc is `cogni-workspace/references/theme-manifest.md`.

### Step 6. Phase 3 — Importing from a Claude Design bundle (alternative path)

Steps 1–5 are the **manual** authoring path: hand-populate each tier, write the manifest by hand, run the validator. For themes authored end-to-end in Claude Design (claude.ai/design), Phase 3 of RFC #132 collapses the whole sequence into a single import. The bundle is the upstream truth; the local theme directory is the materialised mirror.

Skip Steps 1–5 entirely when you have a Claude Design bundle URL. Use them when you do not.

**Author flow** (one round trip):

1. Open Claude Design at `claude.ai/design`. Mock the design system through chat — colors, typography, spacing, components. Author or paste the theme.md prose alongside; the bundle copies whatever you put in `project/{slug}-theme.md` verbatim, so the prose you ship to the bundle is the prose your downstream consumers will read.
2. Include a `## Voice & Copy Guidelines` section in the theme.md. The importer aborts cleanly if this header is missing — Phase D of `verify-theme-backcompat.sh` requires it for voice consumers (`cogni-narrative`, `cogni-sales`, `cogni-research`, `cogni-copywriting`).
3. Export the bundle. Claude Design produces a URL of the form `https://api.anthropic.com/v1/design/h/<hash>`. Copy it.
4. Run the importer:
   ```bash
   python3 cogni-workspace/scripts/import-claude-design-bundle.py \
       --url <bundle-url> --target cogni-workspace/themes/<slug> [--allow-overwrite]
   ```
5. The importer fetches the bundle, verifies the gzip + sha256, untars, runs the voice-header check, projects `colors_and_type.css` into the six canonical token JSON files, regenerates `tokens.css` via `scripts/generate-tokens-css.py`, copies allowlisted component primitives, copies deck primitives and assets, regenerates `manifest.json`, runs `validate-theme-manifest.py`, and writes a `.claude-design-source` sidecar last with the bundle URL + sha256 + timestamp.
6. Run `bash cogni-workspace/scripts/verify-theme-backcompat.sh` to confirm the broader integration contract still holds (Phase A discover, Phase B consumer references, Phase D voice section).

The full mapping table — which bundle paths become which theme paths, the CSS-variable → JSON-token projection, the component allowlist, the strict-abort conditions — lives at [`cogni-workspace/references/claude-design-bundle-mapping.md`](../references/claude-design-bundle-mapping.md). Read it before extending or constraining the importer.

**Ownership boundary**:

- **Owned by the bundle** (overwritten on re-import): `theme.md`, every file under `tokens/`, `components/web/`, `components/deck/`, `assets/`, and `manifest.json`.
- **Owned by the workspace** (preserved across re-imports): the directory itself, anything outside the tiers the importer writes (e.g., legacy `*-theme-showcase.jsx` adjacent to the new tiered files — Op 8 can regenerate the showcase against the new tokens whenever you want).
- **Sidecar**: `.claude-design-source` is written by the importer; never hand-edit. It is the re-sync handle.

**Re-sync contract**:

The bundle is the single source of truth. Re-running the importer with the same URL is a no-op (sha256 matches). Re-running with a new URL refreshes the local tiers from upstream. Hand-edits to imported files survive only until the next re-import — if a hand-edit is genuinely needed (e.g., a token override the bundle does not yet support), encode it upstream by re-authoring in Claude Design and re-exporting.

**Troubleshooting**:

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `bundle theme.md missing required header '## Voice & Copy Guidelines'` | Author session predates the strict voice contract | Open Claude Design, add the section to theme.md, re-export, re-run with `--allow-overwrite` |
| `target ... is not empty; pass --allow-overwrite` | Re-syncing a theme directory that already has content | Pass `--allow-overwrite` (the contract is re-syncable upstream — local hand-edits to imported files are not part of the workflow) |
| `bundle root '...' does not end in '-design-system'` | Bundle shape drift or wrong archive | Confirm the URL is a Claude Design export, not some other tar; if Claude Design changed its naming convention, update `derive_slug_from_root` in the importer |
| `expected single top-level directory in archive` | macOS Finder re-tarred the bundle and added `._*` AppleDouble files at the root | The importer already filters `._*` and `.DS_Store`; if you still hit this, re-download the original bundle rather than the Finder-roundtripped copy |
| `no canonical tokens projected from bundle CSS` | The bundle's CSS uses a non-standard naming scheme | Inspect `project/colors_and_type.css`; if Claude Design's variable prefix changed, extend `TOKEN_PROJECTION` in the importer and the mapping doc together |
| `validate-theme-manifest.py rejected the materialised theme` | A mapping rule bug or the bundle includes a reserved key | Inspect the validator error in the importer's JSON envelope; file the bundle URL alongside the error |
| `components_web_warnings: [...]` (non-empty) | Bundle ships a preview file matching neither the allowlist nor the known-skip patterns | Decide per warning: extend the allowlist in `references/claude-design-bundle-mapping.md` (and re-import) or accept the skip |
| Semantic CSS variables (`--fg-1`, `--bg-canvas`, etc.) disappear from `tokens.css` | v1.0 drops the semantic layer because it cannot project into the JSON tier (the values reference other CSS vars) | Expected behaviour; the deferred-feature note in the mapping doc covers a future `tokens/semantic.json` 7th canonical file |

**Cogni-work canary**:

The first cogni-work bundle export (2026-04-25, URL `https://api.anthropic.com/v1/design/h/RSfNvYTiyDECwo4MqTaEFA`) predates the strict voice-header requirement and triggers the abort cleanly. The existing `themes/cogni-work/` stays authoritative until a regenerated bundle with the voice section lands; then the migration completes in one `--allow-overwrite` run.

## Validation

Always run the validator after touching a tiered theme:

```bash
python3 cogni-workspace/scripts/validate-theme-manifest.py \
    cogni-workspace/themes/<your-slug>
```

Successful tier-1 output:

```json
{"success": true, "data": {"tier": "tiered", "theme_dir": "...", "name": "Cogni Work", "slug": "cogni-work", "tiers_present": ["tokens"]}, "error": ""}
```

Successful tier-0 output (no manifest, manifestless theme stays valid):

```json
{"success": true, "data": {"tier": 0, "theme_dir": "...", "note": "no manifest.json — tier-0 theme is valid"}, "error": ""}
```

The validator checks: schema conformance, that every declared tier path exists on disk, that no reserved key appears at any depth, and (when `tokens.css` is present) that it matches the `generate()` output byte-for-byte. A non-zero exit means the theme is not shippable; fix the failure before committing.

CI integration of the validator is not in scope for this guide.

## Rollback

A tiered theme rolls back to tier-0 with two file operations:

```bash
rm cogni-workspace/themes/<your-slug>/manifest.json
rm -rf cogni-workspace/themes/<your-slug>/{tokens,assets,components,templates}
```

`theme.md` stays. After rollback, the theme is tier-0 again — `validate-theme-manifest.py` returns `{"tier": 0}`, every consumer falls back to its inline templates, and `manage-themes` Operation 6 (Audit) preserves the manifestless layout.

Rollback is **additive in reverse**: the deletion only removes the files you added during migration; everything that existed before stays untouched.

## Common pitfalls

1. **Hand-editing `tokens.css`.** Always regenerate via `scripts/generate-tokens-css.py --write`. Hand-edits drift and the validator hard-fails them. If you need to tweak a token, edit the corresponding `tokens/<file>.json` and re-run the generator.
2. **Authoring compositions instead of primitives in `components/`.** `title-slide.html` is a primitive. A "complete 5-slide deck with intro + 3 content + cta" is a composition and does not belong in a theme — it belongs in the consuming skill (e.g., `cogni-visual:story-to-slides`). Themes provide vocabulary; consumer skills compose with that vocabulary.
3. **Deleting `theme.md` because tokens "cover it".** Tokens carry the *what*; `theme.md` carries the *why* (design principles, brand voice, intent for downstream skills). Both are needed. The validator does not enforce `theme.md` existence in v1.0, but every consumer that reads a theme expects it.
4. **Forgetting to update the manifest after populating a new tier.** The `tiers` map is the contract — `discover-themes.py` and downstream consumers route exclusively through it. A populated `components/` directory that's not declared in `tiers.components` is invisible to consumers.
5. **Using camelCase keys in token JSON.** The generator normalizes underscores to hyphens but assumes input keys are kebab-case at minimum. Stick to `accent-muted`, not `accentMuted`, for predictable CSS variable names.
6. **Migrating just to migrate.** If no consumer skill in your stack consumes tier-1 tokens or tier-3 components, migration adds files without value. Stay at tier-0 until a real consumer needs the deeper structure.

## Related documents

- **Manifest schema reference:** `cogni-workspace/references/theme-manifest.md`
- **JSON Schema:** `cogni-workspace/references/theme-manifest.schema.json`
- **Manage Themes skill (Operation 7 — Author a Deep Theme System):** `cogni-workspace/skills/manage-themes/SKILL.md`
- **Reference implementation (cogni-work pilot):** `cogni-workspace/themes/cogni-work/`
- **First consumer (render-html-slides):** `cogni-visual/skills/render-html-slides/` and `cogni-visual/references/theme-component-loader.md`
- **RFC #124:** [Theme System v2 — Structured theme directories](https://github.com/cogni-work/insight-wave/issues/124)
