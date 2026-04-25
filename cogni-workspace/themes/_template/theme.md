# {Theme Name}

{1-2 sentence description of the visual identity and mood.}

## Color Palette

- **Primary**: `#HEXHEX` - main brand color, headers, key elements
- **Secondary**: `#HEXHEX` - supporting color, subheaders
- **Accent**: `#HEXHEX` - CTAs, highlights, interactive elements
- **Background**: `#HEXHEX` - canvas/page background
- **Surface**: `#HEXHEX` - cards, panels, elevated surfaces
- **Text**: `#HEXHEX` - body text
- **Text Muted**: `#HEXHEX` - secondary text, captions

### Status Colors

- **Success**: `#2E7D32`
- **Warning**: `#ED6C02`
- **Danger**: `#D32F2F`
- **Info**: `#0288D1`

## Typography

- **Headers**: {Font Bold} / fallback: Calibri Bold
- **Body**: {Font Regular} / fallback: Calibri
- **Mono**: {Font Mono} / fallback: Consolas

### Type Scale

- **Display**: {px} / {line-height} / {weight} / {tracking} — hero titles
- **H1**: {px} / {line-height} / {weight} / {tracking} — page titles
- **H2**: {px} / {line-height} / {weight} / {tracking} — section headers
- **H3**: {px} / {line-height} / {weight} / {tracking} — subsection headers
- **H4**: {px} / {line-height} / {weight} — small headings
- **Body**: {px} / {line-height} / {weight} — running text
- **Small**: {px} / {line-height} / {weight} — captions
- **Eyebrow / Micro**: {px} / {line-height} / {weight} / {tracking} / UPPERCASE — section labels

### Web Embedding (HTML)

```html
<!-- TODO: paste the <link> tag for the theme's web fonts (e.g. Google Fonts CSS API URL) -->
```

```css
/* TODO: paste the canonical font-family declaration used in CSS / inline styles */
font-family: '{Font}', system-ui, sans-serif;
```

## Spacing Scale

4pt base. All vertical and horizontal spacing should snap to one of these values.

- **0**: 0
- **1**: {px} — tight inline spacing
- **2**: {px} — small gaps, icon-text pairs
- **3**: {px} — list item spacing
- **4**: {px} — default paragraph margin
- **5**: {px} — card interior padding, default section gap
- **6**: {px} — content band gap
- **7**: {px} — vertical padding inside content bands
- **8**: {px} — major section breaks
- **9**: {px} — hero band vertical padding

**Layout rules:** {content max-width} for copy-heavy surfaces; {dashboard max-width} for dashboards. {grid-cols}-col grid with {gutter}px gutters.

## Radii

- **xs**: {px} — small pills, tags
- **sm**: {px} — small buttons, badges
- **md**: {px} — default (buttons, inputs)
- **lg**: {px} — secondary cards
- **xl**: {px} — primary cards
- **2xl**: {px} — large feature panels
- **pill**: 999px — fully rounded toggles, slider thumbs

## Shadow Scale

- **sm**: `{box-shadow string}` — default card resting
- **md**: `{box-shadow string}` — panels, elevated surfaces
- **lg**: `{box-shadow string}` — modals, popovers
- **xl**: `{box-shadow string}` — major overlays
- **accent-ring**: `{box-shadow string}` — focus and selection state

## Motion

- **Easing**: `{cubic-bezier(...)}` for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: {ms}ms — micro-interactions
- **Medium**: {ms}ms — standard transitions
- **Slow**: {ms}ms — section reveals, modal entry

## Design Principles

1. {First principle}
2. {Second principle}
3. {Third principle}

## Voice & Copy Guidelines

- **Address**: {"you"/"we"/etc.}
- **Casing**: {sentence/title/upper rules per role}
- **Sentence length**: {target range} words.
- **Numbers as heroes**: {how metrics are framed}
- **Claims grounded**: {evidence/citation expectations}
- **Language**: {EN / DE / etc.}
- **Vibe**: {one-line voice summary}

## Best Used For

{Target contexts: enterprise IT, sales decks, research reports, etc.}

## Source

- **Origin**: {website URL, PPTX file, theme-factory preset, or custom}
- **Extracted**: {date}
