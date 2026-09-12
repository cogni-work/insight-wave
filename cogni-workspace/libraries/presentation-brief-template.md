---
library_id: presentation-brief-template
version: 1.0.0
created: 2026-09-07
---

# Output Template Reference

## Per-slide YAML pattern

Every slide follows this content-only YAML pattern: a `## Slide N:` heading, then exactly one fenced `yaml` block. No color or styling fields (`Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:`) — the renderer reads the theme directly. The nested `intent.role` key is a different, permitted 4.1 key and is not covered by this prohibition.

## Slide 3: 688 Lives Lost Annually to Preventable Rail Incidents

```yaml
Layout: stat-card-with-context
Slide-Kind: content

intent:
  role: problem
  emphasis: climax

visual:
  kind: stat

Slide-Title: 688 Lives Lost Annually to Preventable Rail Incidents

Hero-Stat-Box:
  Number: 688
  Label: rail suicides per year
  Sublabel: + 2,661 attacks on stations
  Icon: shield

Context-Box:
  Headline: Why manual monitoring fails
  Bullets:
    - Security staff cannot cover all areas 24/7 <sup>[1](https://eba.bund.de/report)</sup>
    - Critical events detected too late to intervene <sup>[2](https://railsafety.eu/study)</sup>
    - Network too large for point-based surveillance

Bottom-Banner:
  Text: Germany leads EU statistics in rail incidents

Speaker-Notes: |
  >> WHAT YOU SAY
  [Opening]: "Ask: 'How many preventable deaths on German rails annually?'"
  [Key point]: "688 is a 3-year average — trend rising: 612, 679, now 773."
  [Pause]: Let the number sink in.
  [Transition]: "These numbers make the 'why now' question unavoidable..."

  >> WHAT YOU NEED TO KNOW
  - Source: [Federal Rail Safety Report 2024](https://eba.bund.de/report)
  - If asked about regional variance: Bavaria = 23% of incidents
  - The 2,661 attacks figure comes from [BKA Statistics](https://bka.de/stats), not rail safety data

Source: "[Federal Rail Safety Report 2024](https://eba.bund.de/sicherheitsbericht-2024)"
```

The slide heading (`## Slide N: ...`) contains the **assertion headline**, not a topic label.

## IS/DOES/MEANS Label Localization

The `Label` field in IS-Box, DOES-Box, and MEANS-Box must match the presentation language:

```yaml
# English (language: en)
IS-Box:
  Label: IS
DOES-Box:
  Label: DOES
MEANS-Box:
  Label: MEANS

# German (language: de)
IS-Box:
  Label: IST
DOES-Box:
  Label: MACHT
MEANS-Box:
  Label: BEDEUTET
```

Never use English labels in a German presentation or vice versa.

---

## Brief Output Template

The final brief uses this structure. Read it before writing Step 9 output.

Schema **4.1** is additive over 4.0: every renderer accepts both, and an unfenced
4.0 brief stays readable. Three of the frontmatter keys added below — `climax`,
`design` and `key_figures` — are defined in
`${CLAUDE_PLUGIN_ROOT}/libraries/presentation-intent.md`, and this template cites that
vocabulary rather than restating it. The remaining two, `max_slides` and
`slides`, are defined here.

### Frontmatter

```yaml
---
type: presentation-brief
version: "4.1"
theme: {theme_context.theme_id}            # optional — a caller may pass it through
theme_path: "{theme_context.theme_path}"   # optional — a caller may pass it through
customer: "{customer_name}"
provider: "{provider_name}"
language: "{language}"
generated: "{date}"
arc_type: "{detected_or_specified_arc}"
arc_id: "{arc_id if resolved, omit if not}"
governing_thought: "{single-sentence argument}"
confidence_score: {avg_confidence}
max_slides: {max_slides}
slides: {slides_total}
climax: {slide number carrying the emphasis peak, omit if none}
design:
  register: {visual/tonal register, e.g. quiet-executive}
  dark_slides: [{slide numbers rendered dark as rhythm anchors}]   # optional — default per presentation-intent.md
  speaker_notes: {full-script | calm peer-to-peer | bullets}
  imagery: {none | type-only | photographic}
  variations: {how many design variations to generate}   # optional — default per presentation-intent.md
key_figures:
  - "{hero number promoted out of prose, provenance marker kept if it carries one}"
transformation_notes: |
  Story-to-slides transformation.
  Theme: {theme_id}. Arc: {arc_type}.
  {N} slides, {avg}% avg confidence.
  {number_plays} number plays, {headlines_optimized} headlines optimized.
---
```

`theme` and `theme_path` are **optional pass-through keys**: a caller that already
resolved a theme may supply them, and a renderer that chooses its own may ignore
them.

`climax` is **conditionally required**: present whenever some slide carries
`emphasis: climax`, omitted when no slide does — which is what the inline
`omit if none` annotation above means. `arc_id` is likewise conditional —
present when the arc resolves, omitted when it does not, which is what its
inline `omit if not` annotation above means. Within `design`, `dark_slides` and
`variations` are optional and fall back to the defaults in
`presentation-intent.md`. `transformation_notes` is producer-emitted provenance,
not a validated input key: this skill always writes it, and no checker requires
it of a brief. **Every other key above is required**, `design` and
`key_figures` included.

This paragraph is the single authority on 4.1 requiredness: `SKILL.md` defers
to it; `presentation-brief-validation.md` restates it for the checker and must not
diverge from it.

### Rendering Contract

The brief carries one labeled contract block, localized, placed after the
governing-thought paragraph and before `## Slide 1`. It replaces the pptx-only
requirements block of 4.0 and is addressed to whichever renderer consumes the brief.

`{IF language == "en":}`

# Rendering Contract

- Copy is frozen: reproduce every headline, bullet, number and label verbatim — a renderer that rewrites a line has changed the deliverable, not styled it.
- Speaker notes travel complete into the renderer's native notes channel; truncated or summarized notes are an incorrect rendering.
- Citation markers `<sup>[N](url)</sup>` become hyperlink runs on the number, and the references slide stays last in the deck.
- Styling comes only from the theme or the renderer's own design system; the brief carries no color, font, or coordinate, and none may be inferred from its wording.
- `Layout` is a content shape and `visual` is an intent: map each to the nearest native layout and never invent content to fill one.

`{IF language == "de":}`

# Rendering-Vertrag

- Texte sind eingefroren: Überschriften, Aufzählungen, Zahlen und Beschriftungen exakt übernehmen — wer eine Zeile umformuliert, ändert das Ergebnis, statt es zu gestalten.
- Notizen für Slides gehen vollständig in den nativen Notizkanal des Renderers; gekürzte oder zusammengefasste Notizen sind eine fehlerhafte Umsetzung.
- Zitatmarker `<sup>[N](url)</sup>` werden zu Hyperlinks auf der Zahl, und die Quellenfolie bleibt die letzte Folie.
- Gestaltung stammt ausschließlich aus dem Theme oder dem Designsystem des Renderers; der Brief enthält keine Farben, Schriften oder Koordinaten, und es dürfen auch keine aus dem Wortlaut abgeleitet werden.
- `Layout` ist eine Inhaltsform und `visual` eine Absicht: beide auf das nächstgelegene native Layout abbilden und niemals Inhalte erfinden, um eines zu füllen.

**The `### Per renderer` block below is template-side documentation and is NOT
emitted into the brief.** The emitted Rendering Contract is the five
renderer-neutral clauses above it and nothing more.

### Per renderer

- Claude Design — consumes the presentation brief; honours `intent.role` for section rhythm and `design.register` for the visual register.
- pptx skill — maps `Layout` to its slide masters and writes `Speaker-Notes` through `slide.addNotes()`.
- render-html-slides — parses the fenced slide blocks directly and renders `Diagram` through Mermaid; it does not yet consume `visual.chart`.

### Slide grammar

Every slide is a `## Slide N:` heading carrying the assertion headline, followed by
**exactly one** fenced `yaml` block. Three top-level keys are new in 4.1 and appear on
every slide — `Slide-Kind`, `intent` and `visual`. The table below enumerates them and their
sub-keys; `visual.chart` and `visual.image_prompt` are conditional on `visual.kind`:

| Key | Values | Purpose |
|---|---|---|
| `Slide-Kind` | `content` / `internal-prep` / `references` | Replaces inference from the INTERNAL banner and from slide position |
| `intent.role` | `hook` / `problem` / `urgency` / `evidence` / `solution` / `proof` / `options` / `roadmap` / `investment` / `call-to-action` | The Step 3c section role, declared rather than re-derived |
| `intent.emphasis` | `climax` / `release` / `none` | The pacing beat the slide carries |
| `visual.kind` | `stat` / `chart` / `diagram` / `table` / `icon` / `image` / `none` | The visual treatment the renderer should build |
| `visual.chart` | `{type, unit, categories[], series[{name, values[]}]}` | Native series data — never an image |
| `visual.image_prompt` | free text | Imagery direction when `visual.kind` is `image` |

The per-slide `type:` tag in `presentation-intent.md` and `visual.kind` above are
**orthogonal, not alternatives**: `type:` annotates the slide's *shape* and is bound
to `Layout` by that library's own Layout-to-type table, while `visual.kind` names the
*visual element the slide carries*. `table` appears in both because a slide whose
shape is a table also carries a table as its visual; every other pairing is free.

`Icon:` is unchanged. `cta:` per slide and a `## CTA Summary` section remain optional.

## Slide 1: {message headline}

```yaml
Layout: title-slide
Slide-Kind: content

intent:
  role: hook
  emphasis: none

visual:
  kind: none

Title: {title}
Subtitle: {subtitle}
Metadata: {customer} | {provider} | {date}
```

## Slide 2: {methodology_headline}

```yaml
Layout: process-flow
Slide-Kind: internal-prep

intent:
  role: hook
  emphasis: none

visual:
  kind: diagram

Diagram: |
  graph LR
    P0["{phase_0}"] --> P1["{phase_1}"] --> P2["{phase_2}"] --> P3["{phase_3}"] --> P4["{phase_4}"]
Detail-Grid:
  P0: [... key concepts ...]
  P1: [... key concepts ...]
  {... etc ...}
Bottom-Banner:
  Text: "{INTERNAL_WARNING}"
Speaker-Notes: |
  {... comprehensive coaching on delivery arc and pacing ...}
```

## Slide 3: {buying_center_headline}

```yaml
Layout: four-quadrants
Slide-Kind: internal-prep

intent:
  role: hook
  emphasis: none

visual:
  kind: table

{... text-card mode: Q1-Q4 with Label, Sublabel, Bullets per stakeholder, conditional on Rich audience mode ...}
Bottom-Banner:
  Text: "{INTERNAL_WARNING}"
Speaker-Notes: |
  {... comprehensive coaching on stakeholder analysis ...}
```

## Slide 4: {first content slide headline}

```yaml
Layout: {layout}
Slide-Kind: content

intent:
  role: problem
  emphasis: none

visual:
  kind: {stat | chart | diagram | table | icon | image | none}

[... content-only YAML, no color or annotation fields ...]
```

[... problem and urgency slides ...]

<!-- WHY-CHANGE ARC: Solution Overview slide (MANDATORY) — placed between urgency and Power Positions -->

## Slide N: {solution_concept_assertion_headline}

```yaml
Layout: two-columns-equal
Slide-Kind: content

intent:
  role: solution
  emphasis: release

visual:
  kind: none

Slide-Title: {Assertion headline describing the overall solution concept}

Left-Column:
  Headline: {localized: "What We Propose" / "Unser Ansatz"}
  Bullets:
    - {High-level solution approach}
    - {Key architectural principle}
    - {Overall platform concept}

Right-Column:
  Headline: {localized: "How It Maps to Your Needs" / "Bezug zu Ihren Anforderungen"}
  Bullets:
    - {Maps to first unconsidered need}
    - {Maps to second unconsidered need}
    - {Overall business impact promise}

Bottom-Banner:
  Text: {Summarizing statement connecting solution to identified needs}

Speaker-Notes: |
  >> {WHAT YOU SAY / WAS SIE SAGEN}
  [Energy: Medium-High — RELEASE moment. Shift tone from crisis to confidence.]
  [Opening]: "Here is what we propose..."
  [Key point]: "{Solution is a platform, not a point product}"
  [Transition]: "Let me show you how each component delivers on this promise..."

  >> {WHAT YOU NEED TO KNOW / WAS SIE WISSEN MUESSEN}
  - This overview orients the audience BEFORE Power Position detail
  - Source: 03-why-you/narrative.md Executive Summary
```

## Slide N+1: {power_position_assertion_headline}

```yaml
Layout: is-does-means
Slide-Kind: content

intent:
  role: proof
  emphasis: none

visual:
  kind: table

Slide-Title: {Assertion headline — specific capability claim, NO methodology jargon like "Power Position" or "Why You"}

IS-Box:
  Label: {localized: "IS" / "IST"}
  Text: {What the solution IS — positioning statement, NOT the problem it solves}

DOES-Box:
  Label: {localized: "DOES" / "MACHT"}
  Text: {What it DOES — capabilities with quantified outcomes, NOT a restatement of what it IS}

MEANS-Box:
  Label: {localized: "MEANS" / "BEDEUTET"}
  Text: {HOW it works — technology/methodology proof, NOT business impact metrics}

Bottom-Banner:
  Text: {Strongest proof point or differentiator}
```

[... repeat for each Power Position — one slide per Power Position, never combined ...]

[... investment and closing slides ...]

## Slide N+2: {references_headline}

```yaml
Layout: two-columns-equal
Slide-Kind: references

intent:
  role: evidence
  emphasis: none

visual:
  kind: table

[... consolidated citation registry, two columns — see references-slide.md ...]
```

## Generation Metadata

```yaml
slides_total: {N}
content_slides: {N}
prep_slides: {N}
number_plays: {count}
headlines_optimized: {count}
bullets_consolidated: {count}
source_links: {count}
layout_distribution:
  {layout_type}: {count}
avg_confidence: {score}
manual_review: [{slide numbers needing review, empty list if none}]
validation:
  schema: {pass | fail}
  messages: {pass | fail}
  copy: {pass | fail}
  logic: {pass | fail}
  integrity: {pass | fail}
```

---

## Step 8.2 Enrichment Prompt Payload

The `slides-enrichment-artist` launch payload a caller interpolates when it hands the agent a completed deck to enrich (the retired `story-to-slides` producer did so at its Step 8.2). The `FRONTMATTER:` block is an interpolation payload — it supplies values for the keys defined under [Frontmatter](#frontmatter) above, not a second definition of the key set; re-derive it from that section whenever the key set or any value annotation changes.

```
Agent tool:
  subagent_type: "cogni-workspace:slides-enrichment-artist"
  prompt: |
    OUTPUT_PATH: {resolved_output_path}
    OUTPUT_TEMPLATE_PATH: $CLAUDE_PLUGIN_ROOT/libraries/presentation-brief-template.md

    FRONTMATTER:
      type: presentation-brief
      version: "4.1"
      theme: {theme_id}                 # omit this line and the next when no theme was supplied
      theme_path: "{theme_path}"        # verbatim from the caller — never rewritten or re-resolved
      customer: "{customer_name}"
      provider: "{provider_name}"
      language: "{language}"
      generated: "{date}"
      arc_type: "{arc_type}"
      arc_id: "{arc_id}"
      governing_thought: "{governing_thought}"
      confidence_score: {avg_confidence}
      max_slides: {max_slides}
      slides: {slides_total}
      climax: {climax_slide}
      design:
        register: {register}
        dark_slides: {dark_slides}
        speaker_notes: {speaker_notes}
        imagery: {imagery}
        variations: {variations}
      key_figures:
        - "{hero number promoted out of prose, provenance marker kept if it carries one}"
      transformation_notes: |
        Story-to-slides transformation.
        Theme: {theme_id}. Arc: {arc_type}.
        {N} slides, {avg}% avg confidence.
        {number_plays} number plays, {headlines_optimized} headlines optimized.

    TITLE: {title}
    SUBTITLE: {subtitle}

    SLIDE_SPECS:
    {all slide YAML from Steps 8 + 8.1}

    AUDIENCE_MODEL:
    {audience model from Step 3}

    ARC_ANALYSIS:
    {arc analysis from Step 4}

    LANGUAGE: {language}
    ARC_ID: {arc_id or "none"}
    ARC_DEFINITION_PATH: {path or "none"}
    BUYER_APPENDIX_PATH: {path or "none"}

    CTA_SUMMARY:
    {cta_summary from Step 6.1 or "none"}

    GENERATION_METADATA_STATS:
      number_plays: {count}
      headlines_optimized: {count}
      bullets_consolidated: {count}
      source_links: {count}
      layout_distribution: "{layout_type: count, ...}"
      avg_confidence: {score}
      manual_review: [{slide list or "none"}]
```

## Citation Handling Rules

### Source field generation priority (per slide)

1. Inline citation with URL `[label](url)` — use directly as Source value
2. Superscript `<sup>[N]</sup>` — resolve footnote URL at bottom of narrative, then generate Source
3. Shortform `[P1-1]` without URL — omit Source field (no clickable link possible)
4. No citation at all — omit Source field

**Label formatting:** Use the shortest meaningful label — report name + year, not the full title. German report names stay in German.

### Preservation rules

- NEVER modify citation URLs — pass through unchanged
- RENUMBER citation IDs sequentially across all slides: original `[P1-1](url)`, `[P2-3](url)` become `[1](url)`, `[2](url)`, `[3](url)` etc. Apply the renumber map consistently to body text, Source fields, and Speaker-Notes
- PRESERVE inline citations as **superscript** in slide body text fields where claims appear: Context-Box Bullets, Left/Right Column Bullets, IS/DOES/MEANS Box Text, Option Features. Format: `<sup>[N](url)</sup>` placed immediately after the claim it supports.
- **Exclusion zones** — these fields must NOT contain citation markers:
  - Headlines (Slide-Title, Context-Box Headline, Column Headlines)
  - Bottom-Banner Text
  - Hero-Stat-Box Number, Label, and Sublabel
  - Step Labels and Step Numbers (timeline-steps)
- Generate `Source` field per slide using the primary citation URL (supplementary slide-level attribution)
- Include citations as regular inline markdown links `[N](url)` in Speaker-Notes "WHAT YOU NEED TO KNOW" section (NO superscript in notes — notes are text-only)
- Build a consolidated citation registry during extraction for the References slide (Step 7b)

### Why-Change Arc: Solution Overview Slide

For why-change arcs, a Solution Overview slide is MANDATORY between urgency and Power Position slides. It uses `two-columns-equal` layout with "What We Propose" / "How It Maps to Your Needs" columns. This slide orients the audience before detailed Power Position slides.
