---
name: wiki-dashboard
description: "Generate a self-contained HTML dashboard for a Karpathy-style wiki — pages by type, tag cloud, backlink graph, recent activity, and size/age histograms. Single HTML file with no external CDN calls, safe to open offline or share. Use this skill whenever the user says 'wiki dashboard', 'visualize my wiki', 'show me the wiki in HTML', 'generate a dashboard', 'wiki overview as HTML', 'render the wiki', or wants a visual birds-eye view of their knowledge base beyond what wiki-resume offers as plain text."
allowed-tools: Read, Write, Bash, Glob
---

# Wiki Dashboard

Render a single self-contained HTML file that gives the user a birds-eye view of their wiki — more visual than `wiki-resume`, less text-heavy than reading individual pages.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start.

## When to run

- User asks for a dashboard, HTML overview, or visualization of the wiki
- After a major ingest session to see the shape of new additions
- Before sharing the wiki with someone else — the dashboard is shareable as a single file

## Never run when

- The wiki is empty — there is nothing to visualize
- The wiki is not set up — offer `wiki-setup`

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Override the auto-detected wiki root |
| `--output` | No | Output path (default: `<wiki-root>/wiki-dashboard.html`) |
| `--open` | No | `yes` / `no` (default `no`) — whether to print the `file://` URL prominently at the end |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. If none, stop.

### 2. Run the renderer script

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-dashboard/scripts/render_dashboard.py --wiki-root <path> --output <output>`. The script reads every page in `wiki/pages/`, parses frontmatter, counts inbound `[[wikilinks]]`, and writes a single HTML file containing:

- Header with wiki name, slug, description, created date
- Stats strip (page count, raw sources, last lint, 30-day activity)
- Pages by type (donut proxy via stacked bars — no JS charting library)
- Tag cloud (top 30 tags, font-sized by frequency)
- Recent activity (last 20 log entries)
- Most-linked pages (top 10 by inbound-link count)
- Orphan pages list
- Full page index grouped by type, with inline-link counts

The output HTML is self-contained: one file, no external CSS/JS/fonts, no CDN calls. Safe to open offline and safe to share — nothing leaves the user's machine to render it.

### 3. Report to the user

Print:
- Path to the generated HTML file
- A one-line summary of what it contains ("Rendered dashboard for {N} pages — open with `open {path}`")
- If `--open yes`, wrap the path in `file://` so the terminal treats it as a URL

### 4. Do not write anywhere else

The dashboard does not touch the wiki content. It does not append to `log.md` — rendering is not a compounding operation. It does not update `config.json`.

## Output

- A single HTML file at `<output>` (default `<wiki-root>/wiki-dashboard.html`)
- Nothing else written

## Design constraints

1. **Self-contained.** No external CSS, no CDN, no Google Fonts, no CDN JS. Inline everything.
2. **Stdlib only.** Python 3 stdlib for rendering; no Jinja, no pandas, no plotly.
3. **Print-friendly.** The HTML must render well when saved as PDF from a browser — no flexbox tricks that break in print layouts.
4. **Accessible color.** The default palette uses color-safe combinations; no content conveyed by color alone.
5. **Fast.** Even on wikis with 1,000+ pages the render should complete in under a few seconds because everything is string concatenation.

## Golden rules

1. **Read-only.** Dashboard never writes to the wiki.
2. **Single file output.** Never emit a directory of assets.
3. **No network calls at render time.** The script must not reach out to any URL.
4. **Idempotent.** Running twice in a row produces identical bytes (modulo the "generated at" timestamp).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./scripts/render_dashboard.py` — the HTML renderer
