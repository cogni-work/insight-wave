# Cogni Work

Bold, modern open-source identity pairing electric chartreuse with deep black foundations on warm white — inspired by Vitruvius' triad of *Firmitas · Utilitas · Venustas*. Restrained boldness for B2B knowledge work: dark structural anchors, high-contrast clarity, and a single signature accent used sparingly.

## Color Palette

- **Primary**: `#111111` — near-black structural anchor for headlines, navigation, dark hero bands, and primary text
- **Secondary**: `#333333` — dark charcoal for subheads, supporting text, and pressed states on dark buttons
- **Accent**: `#C8E62E` — chartreuse, the signature — CTAs, single-word highlights, key metrics, active states (never body runs)
- **Accent Muted**: `#A8C424` — olive lime for hover states on accent buttons
- **Accent Dark**: `#8BA31E` — deep lime for pressed/active states on accent buttons
- **Background**: `#FAFAF8` — warm white canvas (never cool grey)
- **Surface**: `#F2F2EE` — light warm gray for cards, panels, alternating sections
- **Surface 2**: `#E8E8E4` — second elevation for nested surfaces
- **Surface Dark**: `#111111` — dark sections, hero bands, closing slides
- **Text**: `#111111` — primary body text on light backgrounds
- **Text Light**: `#FFFFFF` — text on dark backgrounds
- **Text Muted**: `#6B7280` — secondary text, captions, metadata
- **Border**: `#E0E0DC` — warm 1px separators, card borders, form fields

### Status Colors

- **Success**: `#2E7D32` — saturated green for confirmations, completed states
- **Warning**: `#E5A100` — amber for cautions, attention-needed states
- **Danger**: `#D32F2F` — classic red for errors, destructive actions
- **Info**: `#1565C0` — blue for informational callouts and tooltips

## Typography

- **Headers**: DM Sans Bold (700) / fallback: Inter, Calibri, system-ui, sans-serif
- **Body**: DM Sans Regular (400) / fallback: Inter, Calibri, system-ui, sans-serif
- **Eyebrows / Code / Numeric Data**: JetBrains Mono Regular (400/500) / fallback: Fira Code, Consolas, monospace

### Type Scale

- **Display**: 56px / 1.05 line-height / Bold / -0.035em tracking — hero titles, deck title slides
- **H1**: 42px / 1.1 line-height / Bold / -0.03em tracking — page titles, primary headlines
- **H2**: 32px / 1.15 line-height / Bold / -0.02em tracking — section headers
- **H3**: 24px / 1.25 line-height / Semibold / -0.01em tracking — subsection headers, card titles
- **H4**: 18px / 1.3 line-height / Semibold — small headings, label headlines
- **Body**: 15px / 1.6 line-height / Regular — running text
- **Small**: 13px / 1.55 line-height / Regular — captions, secondary copy
- **Eyebrow / Micro**: 11px / 1.4 line-height / Mono Semibold / 0.12em tracking / UPPERCASE — section labels, tags

### Web Embedding (HTML)

```html
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300..700;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

```css
font-family: 'DM Sans', 'Inter', system-ui, sans-serif;
```

> DM Sans + JetBrains Mono are loaded directly from Google Fonts — same files used in the production brand showcase.

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

**Layout rules:** 960px content max-width for copy-heavy surfaces; 1200–1280px for dashboards. 12-col grid with 24px gutters. 40px desktop horizontal gutter.

## Radii

- **xs**: 4px — small pills, tags
- **sm**: 6px — small buttons, badges
- **md**: 8px — default (buttons, inputs)
- **lg**: 10px — secondary cards
- **xl**: 12px — primary cards
- **2xl**: 16px — large feature panels
- **pill**: 999px — toggles, slider thumbs, fully rounded

Never sharp corners. Never fully rounded except true pills.

## Shadow Scale

Soft, restrained, warm-black at low alpha. No inner shadows. No neumorphism.

- **sm**: `0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)` — default card resting
- **md**: `0 4px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)` — panels, elevated surfaces
- **lg**: `0 12px 40px rgba(0,0,0,0.1), 0 4px 12px rgba(0,0,0,0.05)` — modals, popovers
- **xl**: `0 24px 64px rgba(0,0,0,0.14), 0 8px 20px rgba(0,0,0,0.06)` — major overlays
- **accent-ring**: `0 0 0 3px rgba(200,230,46,0.15)` — focus and selection state

## Motion

- **Easing**: `cubic-bezier(0.2, 0, 0, 1)` (deceleration) for most transitions
- **Linear**: only for sliders and progress bars
- **Fast**: 150ms — micro-interactions (hover color change)
- **Medium**: 250ms — standard transitions
- **Slow**: 400ms — section reveals, modal entry

No bounces, springs, scale transforms, or theatrical effects. Fades and color transitions only.

## Design Principles

1. **Chartreuse leads, never overwhelms.** The accent (`#C8E62E`) is reserved for CTAs, single-word highlights, key metrics, and active states. Maximum 5–10% of any visual surface. Never used for body runs. Its power comes from restraint.
2. **Dark-light sandwich for rhythm.** Alternate dark (`#111`) title and closing bands with warm-white content bands. White text on near-black creates visual punctuation that guides the eye through narratives, decks, and long-form pages.
3. **Numbers are heroes.** "3.2×", "47%", "60% of their day" — large numeric callouts paired with plain-language labels are the core rhythm of decks and dashboards. Set hero numbers in DM Sans Bold at display size; labels in mono micro.
4. **Generous whitespace, non-negotiable.** 4pt spacing base. 48px vertical padding inside content bands. 24px card interior. 40px desktop gutter. Sections breathe. Density is achieved through hierarchy, not compression.
5. **Mono eyebrows, sentence-case body.** UPPERCASE JetBrains Mono with 0.12em tracking for short eyebrow labels ("THE CHALLENGE", "THE OPPORTUNITY"). Title Case for section headers. Sentence case for body. This three-register typography carries the entire visual rhythm.
6. **Quiet motion, no flourish.** 150–250ms standard transitions; `cubic-bezier(0.2, 0, 0, 1)` deceleration. Fades and color transitions only — no bounces, springs, scale transforms, or theatrical effects.
7. **Selection rings, not shadow shifts.** Cards lift on hover via a 3px chartreuse selection ring (`rgba(200,230,46,0.15)`) and a 2px chartreuse border swap — not by changing shadow elevation. Shadows stay soft and warm.
8. **No emoji, no gradients, no decoration.** No emoji ever. No background gradients. No backdrop-blur. No hand-drawn illustrations. No telco/SaaS visual clichés. Restraint is the brand.
9. **Two-tone discipline.** The brand is intentionally `#111` + `#C8E62E` plus warm neutrals and four status colors — no extended 50–900 ramps. If a chart needs more colors, derive them from the existing palette rather than introducing new hues.
10. **Tight tracking, confident headlines.** Headings carry -0.02em to -0.035em letter-spacing for a modern, deliberate feel. DM Sans's geometric precision does the work — no condensed, light, or italic display variants.

## Voice & Copy Guidelines

Voice is **executive, confident, methodology-driven, quietly European**. Aligned with the `cogni-copywriting` plugin (BLUF, Pyramid, SCQA frameworks).

- **Address**: "you" to the reader, "we" for cogni-work. Never "I".
- **Casing**: Sentence case for body. Title Case for section headers ("Knowledge Workers Deserve Better Tools"). UPPERCASE mono for short eyebrows ("THE CHALLENGE").
- **Sentence length**: 15–20 words. 3–5 sentence paragraphs. Short clauses land harder.
- **Numbers as heroes**: pair every metric with a plain-language label. "3.2×", "47%", "60% of their day".
- **Claims grounded**: outputs include inline citations and quality gates. Never invent statistics.
- **Trilingual motto**: `Firmitas · Utilitas · Venustas` appears verbatim in taglines and footers (middle-dot separator, Latin).
- **Bilingual capability**: EN + DE. German copy follows Wolf-Schneider style (short sentences, concrete verbs).
- **No emoji**. No exclamation marks beyond the rare CTA. No em-dash filler.
- **Vibe**: *"we know what we're doing, without trying hard."* The chartreuse is loud, so the prose stays quiet.

**Example (deck flow):**

- *Title:* "Cogni Work — Smarter Knowledge Work"
- *Eyebrow:* "THE CHALLENGE"
- *Subhead:* "Knowledge Workers Deserve Better Tools"
- *Body:* "Professionals spend 60% of their day on low-value coordination — emails, status updates, and searching for information across siloed tools."
- *CTA:* "Ready to Work Smarter?" / "Get Started"

## Best Used For

- Open-source platform marketing sites (cogni-work.ai surface)
- B2B SaaS pitch decks and product narratives
- Knowledge-work consulting deliverables (project charters, capability decks)
- Portfolio dashboards and capability overviews
- Methodology-driven research reports and trend analyses
- Plugin and developer-tool documentation surfaces
- Partner program pitches and ecosystem messaging
- Internal tools and dashboards for B2B knowledge workers (consulting, sales, marketing, research)

## Source

- **Origin**: cogni-work.ai brand identity + insight-wave open-source plugin ecosystem
- **Brand Mark**: chartreuse point-up triangle; wordmark `cogni` + chartreuse hyphen + `work` + chartreuse `.ai` in DM Sans Bold (-0.02em tracking)
- **Tagline**: `Firmitas · Utilitas · Venustas` (Latin triad, middle-dot separator)
- **Typography**: DM Sans + JetBrains Mono (Google Fonts)
- **Voice Reference**: cogni-copywriting plugin (BLUF, Pyramid, SCQA frameworks); bilingual EN/DE
- **Design System Reference**: companion design-system project covering tokens, UI kits (website + plugin), 7-slide deck template, preview cards, and asset library
- **Showcase Component**: `themes/cogni-work/cogni-work-theme-showcase.jsx`
- **Updated**: 2026-04-25
