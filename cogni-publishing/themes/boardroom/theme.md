# Boardroom

A composed corporate identity for enterprise audiences: deep navy authority, restrained brass accent, and a serif headline voice that reads as considered rather than loud.

## Color Palette

- **Primary**: `#12305C` - main brand color, headers, key elements
- **Secondary**: `#3D5A80` - supporting color, subheaders
- **Accent**: `#8C6D1F` - CTAs, highlights, interactive elements
- **Background**: `#FFFFFF` - canvas/page background
- **Surface**: `#F4F6F9` - cards, panels, elevated surfaces
- **Text**: `#1A2331` - body text
- **Text Muted**: `#55617A` - secondary text, captions

### Status Colors

- **Success**: `#2E7D32`
- **Warning**: `#B45309`
- **Danger**: `#C62828`
- **Info**: `#1565C0`

## Typography

- **Headers**: Source Serif 4 Semibold / fallback: Cambria, Georgia, serif
- **Body**: Inter / fallback: Calibri, system-ui, sans-serif
- **Mono**: IBM Plex Mono / fallback: Consolas, monospace

### Type Scale

- **Display**: 56px / 1.1 / 600 / -0.02em — hero titles
- **H1**: 40px / 1.15 / 600 / -0.015em — page titles
- **H2**: 30px / 1.2 / 600 / -0.01em — section headers
- **H3**: 22px / 1.3 / 600 / 0 — subsection headers
- **H4**: 18px / 1.35 / 600 — small headings
- **Body**: 16px / 1.6 / 400 — running text
- **Small**: 14px / 1.5 / 400 — captions
- **Eyebrow / Micro**: 12px / 1.4 / 600 / 0.08em / UPPERCASE — section labels

### Web Embedding (HTML)

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Source+Serif+4:wght@600&family=Inter:wght@400;600&family=IBM+Plex+Mono&display=swap">
```

```css
font-family: 'Inter', Calibri, system-ui, sans-serif;
```

## Spacing Scale

4pt base. All vertical and horizontal spacing should snap to one of these values.

- **0**: 0
- **1**: 4px — tight inline spacing
- **2**: 8px — small gaps, icon-text pairs
- **3**: 12px — list item spacing
- **4**: 16px — default paragraph margin
- **5**: 24px — card interior padding, default section gap
- **6**: 32px — content band gap
- **7**: 48px — vertical padding inside content bands
- **8**: 64px — major section breaks
- **9**: 96px — hero band vertical padding

**Layout rules:** 720px for copy-heavy surfaces; 1280px for dashboards. 12-col grid with 24px gutters.

## Radii

- **xs**: 2px — small pills, tags
- **sm**: 4px — small buttons, badges
- **md**: 6px — default (buttons, inputs)
- **lg**: 10px — secondary cards
- **xl**: 14px — primary cards
- **2xl**: 20px — large feature panels
- **pill**: 999px — fully rounded toggles, slider thumbs

## Shadow Scale

- **sm**: `0 1px 2px rgba(18, 48, 92, 0.08)` — default card resting
- **md**: `0 4px 10px rgba(18, 48, 92, 0.10)` — panels, elevated surfaces
- **lg**: `0 10px 24px rgba(18, 48, 92, 0.14)` — modals, popovers
- **xl**: `0 20px 48px rgba(18, 48, 92, 0.18)` — major overlays
- **accent-ring**: `0 0 0 3px rgba(140, 109, 31, 0.35)` — focus and selection state

## Motion

- **Easing**: `cubic-bezier(0.4, 0, 0.2, 1)` for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: 120ms — micro-interactions
- **Medium**: 220ms — standard transitions
- **Slow**: 400ms — section reveals, modal entry

## Design Principles

1. Authority through restraint — one accent, used sparingly, never as decoration.
2. Serif headlines over sans body: the contrast carries hierarchy without heavy weights.
3. Generous whitespace around numbers, so a figure reads as evidence rather than ornament.

## Voice & Copy Guidelines

- **Address**: "we" for the organisation, "you" for the reader
- **Casing**: sentence case for headings, title case only for proper nouns
- **Sentence length**: 15-22 words.
- **Numbers as heroes**: one figure per claim, with its unit and period stated
- **Claims grounded**: every figure names its source or is labelled an estimate
- **Language**: EN
- **Vibe**: measured, senior, evidence-led

## Best Used For

Board papers, enterprise IT proposals, annual reviews, investor updates, regulated-industry reporting.

## Source

- **Origin**: bundled first-party preset
- **Extracted**: n/a (authored for this catalog)
