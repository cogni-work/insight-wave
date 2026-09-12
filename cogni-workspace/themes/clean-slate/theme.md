# Clean Slate

A neutral grayscale identity that gets out of the way. No brand colour at all, so charts, screenshots and photography carry every bit of hue on the page.

## Color Palette

- **Primary**: `#1C1C1C` - main brand color, headers, key elements
- **Secondary**: `#4A4A4A` - supporting color, subheaders
- **Accent**: `#6B6B6B` - CTAs, highlights, interactive elements
- **Background**: `#FFFFFF` - canvas/page background
- **Surface**: `#F5F5F5` - cards, panels, elevated surfaces
- **Text**: `#1A1A1A` - body text
- **Text Muted**: `#5C5C5C` - secondary text, captions

### Status Colors

- **Success**: `#2E7D32`
- **Warning**: `#B45309`
- **Danger**: `#C62828`
- **Info**: `#1565C0`

## Typography

- **Headers**: Inter Tight Semibold / fallback: Calibri Bold, system-ui, sans-serif
- **Body**: Inter / fallback: Calibri, system-ui, sans-serif
- **Mono**: JetBrains Mono / fallback: Consolas, monospace

### Type Scale

- **Display**: 52px / 1.1 / 600 / -0.03em — hero titles
- **H1**: 38px / 1.15 / 600 / -0.02em — page titles
- **H2**: 28px / 1.2 / 600 / -0.01em — section headers
- **H3**: 21px / 1.3 / 600 / 0 — subsection headers
- **H4**: 17px / 1.35 / 600 — small headings
- **Body**: 16px / 1.65 / 400 — running text
- **Small**: 13px / 1.5 / 400 — captions
- **Eyebrow / Micro**: 11px / 1.4 / 600 / 0.1em / UPPERCASE — section labels

### Web Embedding (HTML)

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@600&family=Inter:wght@400;600&family=JetBrains+Mono&display=swap">
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
- **8**: 72px — major section breaks
- **9**: 104px — hero band vertical padding

**Layout rules:** 680px for copy-heavy surfaces; 1200px for dashboards. 12-col grid with 24px gutters.

## Radii

- **xs**: 2px — small pills, tags
- **sm**: 3px — small buttons, badges
- **md**: 4px — default (buttons, inputs)
- **lg**: 6px — secondary cards
- **xl**: 8px — primary cards
- **2xl**: 12px — large feature panels
- **pill**: 999px — fully rounded toggles, slider thumbs

## Shadow Scale

- **sm**: `0 1px 2px rgba(0, 0, 0, 0.06)` — default card resting
- **md**: `0 3px 8px rgba(0, 0, 0, 0.08)` — panels, elevated surfaces
- **lg**: `0 8px 20px rgba(0, 0, 0, 0.10)` — modals, popovers
- **xl**: `0 18px 40px rgba(0, 0, 0, 0.14)` — major overlays
- **accent-ring**: `0 0 0 3px rgba(107, 107, 107, 0.30)` — focus and selection state

## Motion

- **Easing**: `cubic-bezier(0.2, 0, 0, 1)` for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: 100ms — micro-interactions
- **Medium**: 180ms — standard transitions
- **Slow**: 320ms — section reveals, modal entry

## Design Principles

1. No hue in the chrome, so every colour on the page belongs to the content.
2. Hierarchy from size and weight alone — never from colour.
3. Hairline borders over fills: separation without visual weight.

## Voice & Copy Guidelines

- **Address**: "you"
- **Casing**: sentence case throughout
- **Sentence length**: 12-18 words.
- **Numbers as heroes**: set large and unadorned; the figure is the emphasis
- **Claims grounded**: state the source inline, or mark the number an estimate
- **Language**: EN
- **Vibe**: plain, exact, unhurried

## Best Used For

Technical documentation, data-heavy dashboards, screenshot-led product walkthroughs, neutral client deliverables where a house brand must not intrude.

## Source

- **Origin**: bundled first-party preset
- **Extracted**: n/a (authored for this catalog)
