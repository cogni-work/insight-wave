---
library_id: brief-core
version: 1.0.0
created: 2026-09-05
updated: 2026-09-05
---

# Brief Core — the grammar the four brief types share

One document shape underlies every brief the render chain reads, whether hand-authored or caller-supplied: YAML frontmatter, a `##` unit per slide, section, poster or block, exactly one fenced `yaml` block per unit, and two optional trailing sections. This file states the shared core once — the frontmatter keys, the per-type extensions, the version pins, the unit grammar and where each closed enum lives. `scripts/check-brief.py` enforces exactly this: the slides profile in full, the three siblings on the core checks.

## Frontmatter core

Every brief type, at every version, carries these keys:

| Key | Type | Notes |
|-----|------|-------|
| `type` | string | `presentation-brief`, `web-brief`, `storyboard-brief` or `infographic-brief` |
| `version` | quoted string | see § Version pins |
| `customer` | string | organization the brief is for |
| `provider` | string | organization delivering it — never defaulted to the theme name |
| `language` | `en` / `de` | governs copy, number formatting and localized labels |
| `generated` | `YYYY-MM-DD` | |
| `arc_type` | enum | `why-change`, `problem-solution`, `journey`, `argument`, `report` |
| `governing_thought` | string | one sentence with a verb |
| `confidence_score` | number 0–1 | average of per-unit confidences |

Three more are shared but not required by the checker: `theme` and `theme_path` are **optional pass-through keys** (a renderer that chooses its own theme ignores them; when `theme_path` is present it is absolute and ends in `/theme.md`); `arc_id` is **conditional** — present when the arc resolved, omitted when it did not. `transformation_notes` is producer-emitted provenance every skill writes and no checker requires.

## Per-type extensions

| Type | Additional keys |
|------|-----------------|
| `presentation-brief` (4.1) | `max_slides`, `slides`, `design{register, dark_slides, speaker_notes, imagery, variations}`, `key_figures[]`, conditional `climax` (required whenever a slide carries `emphasis: climax`). Authority: `libraries/presentation-brief-template.md` → Frontmatter |
| `web-brief` | `conversion_goal`, `sections` |
| `storyboard-brief` | `industry`, `poster_size`, `poster_count`, `poster_gap`, `conversion_goal`, `base_width`, `base_height`, `print_width`, `print_height`, `scale_factor` |
| `infographic-brief` | `layout_type`, `style_preset`, `orientation`, `dimensions`, `voice_tone`, `palette_override` |

## Version pins

| Type | Current | Accepted as legacy | Owner of the pin |
|------|---------|--------------------|------------------|
| `presentation-brief` | `"4.1"` | `"4.0"` (unfenced slide bodies, no Rendering Contract) | `presentation-brief-template.md` |
| `web-brief` | `"1.1"` | `"1.0"` | `libraries/web-layouts.md` |
| `storyboard-brief` | `"2.1"` | `"2.0"` | `libraries/storyboard-layouts.md` |
| `infographic-brief` | per rendering family — see `libraries/infographic-layouts.md` | `"1.0"`, `"1.1"`, `"1.2"` are all accepted by the `/render-infographic` dispatcher; the two hand-drawn agents accept `"1.0"` and `"1.1"` only | `libraries/infographic-layouts.md` |

Every renderer declares the versions it accepts; a producer writes the current version for its type.

## Unit grammar

| Type | Unit heading | Fixed units | Trailing sections |
|------|--------------|-------------|-------------------|
| `presentation-brief` | `## Slide N: {assertion headline}` | — | `## CTA Summary`, `## Generation Metadata` |
| `web-brief` | `## Section N: {assertion headline}` | `## Header`, `## Footer` | `## CTA Summary`, `## Generation Metadata` |
| `storyboard-brief` | `## Poster N: {station label}` | — | `## CTA Summary`, `## Generation Metadata` |
| `infographic-brief` | `## Block N: {block title}` (a suffixed `## Block 3b:` extends block 3) | `## Title Block`, `## CTA Block`, `## Footer Block` | `## Generation Metadata` |

Units are numbered from 1 without gaps, in document order. Each unit's body is **exactly one** fenced `yaml` block; the trailing sections are fenced too. A brief carries no `Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:` or `Mood:` key at any depth (see `brief-conventions.md` § Theme-driven visuals). Inline citations are `<sup>[N](url)</sup>`, numbered sequentially across the document.

## Closed enums

Each type's unit vocabulary is closed and owned by one file; the producer maps content onto it and the renderer maps it onto its nearest native arrangement.

| Type | Enum | Owner |
|------|------|-------|
| `presentation-brief` | eleven slide layouts | `libraries/pptx-layouts.md` — pinned to its other homes by `tests/test-brief-layout-sync.sh` |
| `presentation-brief` | `Slide-Kind`, `intent.role`, `intent.emphasis`, `visual.kind` | `presentation-brief-template.md` → Slide grammar |
| `web-brief` | section types (`hero`, `problem-statement`, `stat-row`, `feature-alternating`, `feature-grid`, `testimonial`, `comparison`, `timeline`, `cta`, `text-block`) and `section_theme` | `libraries/web-layouts.md` |
| `storyboard-brief` | the web section types, stacked per poster, plus poster geometry | `libraries/storyboard-layouts.md` |
| `infographic-brief` | layout types and block types | `libraries/infographic-layouts.md` |
| all | arc roles | `libraries/arc-taxonomy.md` → Arc Roles |
| all | CTA types (`explore`, `evaluate`, `commit`, `share`) and urgency | `libraries/cta-taxonomy.md` |
