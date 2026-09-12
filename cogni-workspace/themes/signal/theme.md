# Signal

A high-contrast identity built around a single loud accent: electric blue structure with a magenta call to action that only ever marks the one thing you want clicked.

## Color Palette

- **Primary**: `#1030C4` - main brand color, headers, key elements
- **Secondary**: `#334155` - supporting color, subheaders
- **Accent**: `#D6006E` - CTAs, highlights, interactive elements
- **Background**: `#FFFFFF` - canvas/page background
- **Surface**: `#F1F3F9` - cards, panels, elevated surfaces
- **Text**: `#0F172A` - body text
- **Text Muted**: `#4B5670` - secondary text, captions

### Status Colors

- **Success**: `#2E7D32`
- **Warning**: `#B45309`
- **Danger**: `#C62828`
- **Info**: `#1565C0`

## Typography

- **Headers**: Space Grotesk Bold / fallback: Calibri Bold, system-ui, sans-serif
- **Body**: IBM Plex Sans / fallback: Calibri, system-ui, sans-serif
- **Mono**: IBM Plex Mono / fallback: Consolas, monospace

### Type Scale

- **Display**: 64px / 1.05 / 700 / -0.03em — hero titles
- **H1**: 44px / 1.1 / 700 / -0.02em — page titles
- **H2**: 32px / 1.2 / 700 / -0.01em — section headers
- **H3**: 23px / 1.3 / 700 / 0 — subsection headers
- **H4**: 18px / 1.35 / 700 — small headings
- **Body**: 16px / 1.6 / 400 — running text
- **Small**: 14px / 1.5 / 400 — captions
- **Eyebrow / Micro**: 12px / 1.4 / 700 / 0.12em / UPPERCASE — section labels

### Web Embedding (HTML)

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@700&family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono&display=swap">
```

```css
font-family: 'IBM Plex Sans', Calibri, system-ui, sans-serif;
```

## Spacing Scale

4pt base. All vertical and horizontal spacing should snap to one of these values.

- **0**: 0
- **1**: 4px — tight inline spacing
- **2**: 8px — small gaps, icon-text pairs
- **3**: 12px — list item spacing
- **4**: 16px — default paragraph margin
- **5**: 24px — card interior padding, default section gap
- **6**: 36px — content band gap
- **7**: 52px — vertical padding inside content bands
- **8**: 72px — major section breaks
- **9**: 112px — hero band vertical padding

**Layout rules:** 700px for copy-heavy surfaces; 1320px for dashboards. 12-col grid with 28px gutters.

## Radii

- **xs**: 4px — small pills, tags
- **sm**: 6px — small buttons, badges
- **md**: 10px — default (buttons, inputs)
- **lg**: 14px — secondary cards
- **xl**: 20px — primary cards
- **2xl**: 28px — large feature panels
- **pill**: 999px — fully rounded toggles, slider thumbs

## Shadow Scale

- **sm**: `0 2px 4px rgba(15, 23, 42, 0.08)` — default card resting
- **md**: `0 6px 14px rgba(15, 23, 42, 0.12)` — panels, elevated surfaces
- **lg**: `0 14px 32px rgba(15, 23, 42, 0.16)` — modals, popovers
- **xl**: `0 28px 60px rgba(15, 23, 42, 0.22)` — major overlays
- **accent-ring**: `0 0 0 4px rgba(214, 0, 110, 0.28)` — focus and selection state

## Motion

- **Easing**: `cubic-bezier(0.16, 1, 0.3, 1)` for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: 140ms — micro-interactions
- **Medium**: 260ms — standard transitions
- **Slow**: 460ms — section reveals, modal entry

## Design Principles

1. One accent, one job: magenta marks the single next action on any screen.
2. Type does the shouting — large display weights, not colour blocks.
3. Contrast is structural, not decorative: every surface step is legible on its own.

## Voice & Copy Guidelines

- **Address**: "you"
- **Casing**: sentence case for headings, uppercase reserved for eyebrows
- **Sentence length**: 10-16 words.
- **Numbers as heroes**: one number per band, set at display size
- **Claims grounded**: a bold claim carries its evidence in the following line
- **Language**: EN
- **Vibe**: direct, confident, momentum-forward

## Best Used For

Product launches, campaign landing pages, conference decks, demand-generation content, anything competing for attention.

## Source

- **Origin**: bundled first-party preset
- **Extracted**: n/a (authored for this catalog)
