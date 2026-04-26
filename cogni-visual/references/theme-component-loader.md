# Theme Component Loader

Reusable loader for Theme System v2 (RFC #124) tier-3 component primitives. Lives at `cogni-visual/scripts/load-theme-component.py`. Stdlib Python, JSON output convention, copy-on-use semantics. Use this from any consuming skill that wants to render with theme-supplied component primitives without reinventing the path resolution.

## When to use

Reach for the loader when a renderer wants to read an HTML primitive from a theme — for example, a slide deck that wants to consume `themes/<slug>/components/deck/title-slide.html` instead of inlining its own `<section>` template. The loader resolves the absolute path and lets the caller decide what to do with the contents (interpolate slide data, copy verbatim, cache, live-reload).

Do not use the loader when the caller wants tier-1 tokens only. `tokens.css` is a static asset — read its path directly from the manifest's `tiers.tokens` and emit an `@import` line. The loader is for the deeper tiers (`components/`, `templates/`) where the caller picks one file out of a typed surface.

## Interface

```bash
python3 cogni-visual/scripts/load-theme-component.py \
    --themes-dir <abs-path-to-themes-dir> \
    --theme-slug <slug> \
    --surface <surface> \
    --component <component-name>
```

Importable form (preferred when the consumer is already Python):

```python
from importlib.util import spec_from_file_location, module_from_spec

spec = spec_from_file_location("loader", "cogni-visual/scripts/load-theme-component.py")
loader = module_from_spec(spec)
spec.loader.exec_module(loader)

result = loader.resolve(themes_dir, theme_slug, surface, component)
```

Both forms return the same envelope:

```json
{"status": "ok",    "path": "...", "theme_slug": "...", "surface": "...", "component": "..."}
{"status": "miss",  "reason": "...", "theme_slug": "...", "surface": "...", "component": "..."}
{"status": "error", "error": "...",  "theme_slug": "...", "surface": "...", "component": "..."}
```

`status: "miss"` is normal control flow — every consumer must have a fallback path that handles miss. The CLI exits 0 on hit and miss; only hard failures (unreadable manifest, malformed JSON) produce exit 1 plus `status: "error"`.

## Miss reasons

The loader's miss reasons are intent-revealing strings, not enums — they exist to make logs readable, not to switch on. Today's reasons:

- `tier-0 theme (no manifest.json)` — the theme has not opted into Theme System v2. Use the inline template.
- `manifest has no tiers map` — manifest exists but is malformed in a way the validator should have caught. Use the inline template.
- `theme has no components tier` — manifest declares `tiers.tokens` only (the current state of `cogni-work`). Use the inline template.
- `surface 'X' not declared in tiers.components` — the components tier exists but doesn't expose this surface. Use the inline template.
- `component file not found: <path>` — the surface declares a path but the file is missing on disk. Use the inline template.
- `theme directory not found: <path>` — the slug doesn't exist under `themes/`. Use the inline template.

Callers should log the reason at debug level and keep moving. Do not branch on the reason string — branch on `status == "miss"` only.

## Copy-on-use semantics

The loader returns paths, never bytes. The caller reads the file, interpolates slide data into placeholders, and emits the result inline in the rendered HTML. The component file is not deep-copied into the output — the rendered HTML is the artifact, the component file stays where it is. This resolves RFC #124 open question 2: copy-on-use is the default, opt-in live-theme is reserved for a future iteration.

The implication for the renderer:

- A theme update (edit `components/deck/title-slide.html`) takes effect on the **next render**, not on the active rendered HTML. This is the expected behavior — rendered HTML is a frozen artifact.
- If a future release wants live-theme behavior (reload the component on every page view), it can either ship a server-side reverse proxy that reads the path at request time or extend the loader's envelope with a `live` flag. Both are out of scope for Phase 2.

## Themes-dir resolution

The loader requires an absolute `--themes-dir`. The renderer is responsible for resolving it. The conventional order, used by `render-html-slides` and recommended for downstream consumers:

1. Explicit `--themes-dir` CLI arg if the consumer exposes one.
2. `$COGNI_WORKSPACE_ROOT/themes` if the env var is set.
3. Walk up from the consumer script looking for a sibling `cogni-workspace/themes` directory (auto-discovery for monorepo development).

`render-html-slides/scripts/generate-html-slides.py:resolve_themes_dir` is the canonical implementation. Copy it; do not duplicate by hand.

## Loading the contents

The loader returns paths, so reading is the caller's job. The minimal pattern:

```python
result = loader.resolve(themes_dir, theme_slug, "deck", "title-slide")
if result["status"] == "ok":
    with open(result["path"], "r", encoding="utf-8") as h:
        component_html = h.read()
    rendered = component_html.format(title=slide.title, subtitle=slide.subtitle)
else:
    rendered = inline_title_slide_template(slide)  # the well-tested fallback
```

Component files are templates — they SHOULD use `{placeholder}` markers that match the consuming skill's vocabulary, and they SHOULD reference theme tokens via CSS custom properties (e.g. `var(--colors-primary)`) so the active palette flows through without rewriting markup. Component files SHOULD NOT contain absolute paths or skill-specific JavaScript — both belong to the consuming skill.

## What this is NOT

- **Not a CSS bundler.** Tokens are handled separately via `tiers.tokens` (see `cogni-workspace/scripts/generate-tokens-css.py`). The loader only resolves component paths.
- **Not a live theme system.** Copy-on-use means the rendered HTML is frozen at render time. Live-reload is reserved for a future iteration (RFC #124 open question 2).
- **Not a validator.** The loader is tolerant on purpose — it returns miss for shapes a validator would reject. Run `cogni-workspace/scripts/validate-theme-manifest.py` if you need schema enforcement.

## Reference consumer

`cogni-visual/skills/render-html-slides/scripts/generate-html-slides.py` is the first consumer (Phase-2 pilot, issue #129). Its `--theme-slug` flag wires the loader for tier-1 tokens; tier-3 deck primitive integration is the next increment, gated on `cogni-work` shipping a `tiers.components.deck` family. Look there for the conventional themes-dir resolution and the eval pattern under `evals/run.py`.
