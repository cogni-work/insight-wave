# Editorial

A warm print-magazine identity: paper-toned grounds, terracotta headline voice, and a Didone display face that gives long-form reading a considered rhythm.

## Color Palette

- **Primary**: `#7A2E1E` - main brand color, headers, key elements
- **Secondary**: `#3E3A33` - supporting color, subheaders
- **Accent**: `#A8541F` - CTAs, highlights, interactive elements
- **Background**: `#FBF7EF` - canvas/page background
- **Surface**: `#F3ECE0` - cards, panels, elevated surfaces
- **Text**: `#241F1A` - body text
- **Text Muted**: `#5C544A` - secondary text, captions

### Status Colors

- **Success**: `#2E7D32`
- **Warning**: `#B45309`
- **Danger**: `#B3261E`
- **Info**: `#1565C0`

## Typography

- **Headers**: Playfair Display Bold / fallback: Georgia Bold, Cambria, serif
- **Body**: Source Serif 4 / fallback: Georgia, Cambria, serif
- **Mono**: IBM Plex Mono / fallback: Consolas, monospace

### Type Scale

- **Display**: 60px / 1.08 / 700 / -0.01em — hero titles
- **H1**: 42px / 1.15 / 700 / -0.005em — page titles
- **H2**: 31px / 1.22 / 700 / 0 — section headers
- **H3**: 23px / 1.3 / 700 / 0 — subsection headers
- **H4**: 19px / 1.35 / 700 — small headings
- **Body**: 17px / 1.7 / 400 — running text
- **Small**: 14px / 1.55 / 400 — captions
- **Eyebrow / Micro**: 12px / 1.4 / 700 / 0.14em / UPPERCASE — section labels

### Web Embedding (HTML)

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Source+Serif+4:wght@400;600&family=IBM+Plex+Mono&display=swap">
```

```css
font-family: 'Source Serif 4', Georgia, Cambria, serif;
```

## Spacing Scale

4pt base. All vertical and horizontal spacing should snap to one of these values.

- **0**: 0
- **1**: 4px — tight inline spacing
- **2**: 8px — small gaps, icon-text pairs
- **3**: 12px — list item spacing
- **4**: 20px — default paragraph margin
- **5**: 28px — card interior padding, default section gap
- **6**: 40px — content band gap
- **7**: 56px — vertical padding inside content bands
- **8**: 80px — major section breaks
- **9**: 120px — hero band vertical padding

**Layout rules:** 660px for copy-heavy surfaces; 1160px for dashboards. 12-col grid with 32px gutters.

## Radii

- **xs**: 0 — small pills, tags
- **sm**: 2px — small buttons, badges
- **md**: 3px — default (buttons, inputs)
- **lg**: 4px — secondary cards
- **xl**: 6px — primary cards
- **2xl**: 8px — large feature panels
- **pill**: 999px — fully rounded toggles, slider thumbs

## Shadow Scale

- **sm**: `0 1px 2px rgba(36, 31, 26, 0.07)` — default card resting
- **md**: `0 3px 9px rgba(36, 31, 26, 0.09)` — panels, elevated surfaces
- **lg**: `0 9px 22px rgba(36, 31, 26, 0.12)` — modals, popovers
- **xl**: `0 20px 44px rgba(36, 31, 26, 0.16)` — major overlays
- **accent-ring**: `0 0 0 3px rgba(168, 84, 31, 0.32)` — focus and selection state

## Motion

- **Easing**: `cubic-bezier(0.33, 0, 0.2, 1)` for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: 130ms — micro-interactions
- **Medium**: 240ms — standard transitions
- **Slow**: 420ms — section reveals, modal entry

## Design Principles

1. Paper first: warm grounds and near-square corners, so screens read like print.
2. Serif throughout — display and body — with size, not family, marking hierarchy.
3. Rules and generous leading instead of boxes; the column does the containing.

## Voice & Copy Guidelines

- **Address**: "we" for the author, "the reader" in third person when framing
- **Casing**: sentence case for headings, small caps only for eyebrows
- **Sentence length**: 18-26 words.
- **Numbers as heroes**: set inline within the sentence, never pulled into a tile
- **Claims grounded**: attribute in the running text rather than a footnote
- **Language**: EN
- **Vibe**: literary, unhurried, argument-led

## Best Used For

Long-form reports, thought-leadership essays, printed one-pagers and posters, annual narratives, research write-ups.

## Source

- **Origin**: bundled first-party preset
- **Extracted**: n/a (authored for this catalog)
