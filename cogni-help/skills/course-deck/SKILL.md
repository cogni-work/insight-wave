---
name: course-deck
description: >-
  Generate professional PPTX slide decks for cogni-help workflow tours. Two modes:
  (1) curriculum overview deck showing the 7 workflow tours at a glance, or
  (2) per-tour intro deck with learning objectives, module breakdown, and
  prerequisites. Use this skill whenever the user asks to "create tour slides",
  "generate a curriculum deck", "make an intro presentation", "tour overview pptx",
  "training deck", "tour introduction slides", or mentions creating presentation
  materials for cogni-help workflow tours. Also trigger when someone says "prepare
  materials for a training session" or "I need slides for onboarding new learners".
version: 0.1.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# course-deck: Course Presentation Generator

Generate polished PPTX slide decks for cogni-help training programs. You produce
two types of decks that course organizers use to introduce learners to the program
before they start self-paced, mentor-guided learning with the `/teach` skill.

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Generate all slide content — titles, bullets,
descriptions, CTAs — in that language. Training decks are most effective when
presented in the audience's native language.

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names (`cogni-trends`, `cogni-narrative`, etc.)
- Command names (`/teach`, `/courses`, etc.)
- Technical terms, code snippets

## Two Deck Types

### 1. Curriculum Overview (`curriculum`)

A program-level deck introducing the full insight-wave training program. Use this
when the organizer wants to present the overall learning journey to a group of
new learners.

**Slides to generate (~8-10 slides):**

1. **Title slide** — "insight-wave Training Program" with subtitle "Master AI-Powered
   Consulting with Claude Cowork". Dark background (`111111`) with chartreuse accent line.

2. **Why this program** — The value proposition: what consultants gain by learning
   insight-wave (faster deliverables, consistent quality, AI-augmented research).
   Use 3 key benefit statements with icons.

3. **How it works** — Explain the learning format: integrative workflow tours,
   mentor-guided by Claude, theory + hands-on exercises + quizzes. Visual showing
   the module cycle: Theory > Demo > Exercise > Quiz > Recap.

4. **Learning journey** — Visual roadmap of the 7 workflow tours as a path or
   timeline. Show the cross-plugin pipelines each tour walks through.

5-6. **Tour spotlight slides** — Two slides, each covering 3-4 tours with:
   tour ID, title, pipeline (cross-plugin chain), what you'll learn (2-3 bullets).
   Tours 1-4 on one slide, 5-7 on the next.

7. **What you'll build** — Showcase the deliverables learners create during
   tour exercises (a first-run infographic, a research report, a sales pitch deck,
   a deployable website, a consulting engagement plan).

8. **Getting started** — How to begin: open Claude Cowork, type
   `/teach tour-install-to-infographic`, and follow along. Include the
   `/courses` command to check progress.

### 2. Tour Introduction (`<tour-id-or-short-name>`)

The deck-type token accepts any value listed in the Tour Mapping table below
— full tour IDs (e.g. `tour-research-to-report`) and short aliases (e.g.
`research`, `report`) all resolve to the same tour.

A tour-level deck introducing a specific workflow tour. Use when the organizer
wants to set expectations before learners dive into a particular tour.

**Slides to generate (~6-8 slides):**

1. **Title slide** — Tour ID and title. Subtitle with duration (~45–60 min)
   and module count.

2. **What you'll learn** — 4-5 learning objectives pulled from the tour content,
   anchored on the cross-plugin handoffs the tour walks through. Use checkmark
   icons with chartreuse accent.

3. **Pipeline overview** — The cross-plugin chain (e.g., research → narrative
   → visual) as a horizontal flow diagram, plus the modules listed with brief
   description of each.

4. **Prerequisites** — What the learner needs before starting: prior tours,
   plugins that must be installed, any workspace setup.

5. **Key concepts preview** — 3-4 core concepts from the tour with one-line
   explanations. Gives learners mental hooks before they start.

6. **What you'll build** — The hands-on deliverable from the exercises (every
   tour ends with a real artifact the learner can keep and reuse).

7. **Ready to start** — CTA slide: "Open Claude Cowork and type
   `/teach <tour-id>` to begin. Your AI mentor will guide you through each
   module."

## Content Source

Pull all tour content from the reference files in this plugin:

- `references/courses/tours/tour-research-to-report.md`
- `references/courses/tours/tour-trends-to-solutions.md`
- `references/courses/tours/tour-portfolio-to-pitch.md`
- `references/courses/tours/tour-portfolio-to-website.md`
- `references/courses/tours/tour-consulting-engagement.md`
- `references/courses/tours/tour-content-pipeline.md`
- `references/courses/tours/tour-install-to-infographic.md`

Read only the tour file(s) needed for the requested deck. For curriculum overview,
skim all 7 files for titles, objectives, and module names — don't load full content.

## Tour Mapping

Map user input to tour files:

| Input | Tour |
|-------|------|
| research, research-to-report, report, tour-research-to-report | tour-research-to-report |
| trends, trend, scouting, trends-to-solutions, solutions, tour-trends-to-solutions | tour-trends-to-solutions |
| pitch, portfolio-to-pitch, sales-deck, tour-portfolio-to-pitch | tour-portfolio-to-pitch |
| website, portfolio-to-website, site, tour-portfolio-to-website | tour-portfolio-to-website |
| consulting, diamond, double-diamond, engagement, tour-consulting-engagement | tour-consulting-engagement |
| content, content-pipeline, marketing, tour-content-pipeline | tour-content-pipeline |
| install, infographic, install-to-infographic, first-run, tour-install-to-infographic | tour-install-to-infographic |

## Visual Design: cogni-work Theme

Apply the cogni-work theme. The authoritative theme file lives at:
`$COGNI_WORKSPACE_ROOT/themes/cogni-work/theme.md`

Read it for the full specification. Key rules:

**Colors:**
- Primary/headers: `111111` (near-black) — structural anchors, dark slide backgrounds
- Secondary: `333333` (dark charcoal) — subheaders, supporting text
- Accent: `C8E62E` (chartreuse/lime) — CTAs, highlights, key data points, links
- Accent muted: `A8C424` (olive lime) — hover states, secondary highlights
- Background: `FAFAF8` (warm white) — content slide canvas
- Surface: `F2F2EE` (light warm gray) — cards, panels, elevated containers
- Surface dark: `111111` (near-black) — title/closing slides, hero areas
- Text: `111111` (near-black) — body text on light backgrounds
- Text light: `FFFFFF` (white) — text on dark backgrounds
- Text muted: `6B7280` (cool gray) — captions, metadata
- Border: `E0E0DC` (warm light gray) — card outlines, separators

**Typography:**
- Headers: DM Sans Bold (fallback: Inter Bold, Calibri Bold)
- Body: DM Sans Regular (fallback: Inter, Calibri)
- Mono: JetBrains Mono (fallback: Fira Code, Consolas)

**Design principles (Vitruvius triad):**
- **Dark-light sandwich**: Title and closing slides use dark backgrounds (`111111`);
  content slides use warm white (`FAFAF8`). This creates visual rhythm and narrative structure.
- **Chartreuse is the signature**: `C8E62E` is bold and loud — use it for CTAs, key metrics,
  highlights, and energy moments. Never as body text, never overdone.
- **Restrained boldness**: The lime is loud, so everything else stays quiet. No competing
  colors. Let the accent do the talking.
- **High contrast always**: Chartreuse on black, black on white — maximum readability.
- **Modern confidence**: Clean lines, generous spacing, no ornamentation.
- **No plain bullet dumps**: every slide needs a visual element (shapes, icons, layout variety)

**PPTX color format:** Do NOT prefix hex colors with `#` — PptxGenJS corrupts files
when you do. Use bare hex: `C8E62E`, not `#C8E62E`.

## Building the PPTX

Use PptxGenJS (Node.js) to generate the presentation. Install if needed:
`npm install -g pptxgenjs`

Key technical notes:
- Slide size: 16:9 (10" x 5.625")
- Use `bullet: true` for bullets (never unicode characters)
- Use `breakLine: true` for line breaks in text arrays
- Set `margin: 0` when aligning text with shapes
- Don't reuse option objects across calls (PptxGenJS mutates them)
- Don't use `ROUNDED_RECTANGLE` for accent borders

**Vary the layouts** across slides — mix full-width content, multi-column, card grids,
and icon+text combinations. A deck where every slide looks the same is boring.

## Output

Save the generated PPTX to the user's working directory with a descriptive filename:
- Curriculum: `insight-wave-training-program.pptx`
- Tour intro: `tour-<id>-intro.pptx` (e.g., `tour-research-to-report-intro.pptx`)

After generating, tell the user where the file is saved and suggest they review it.
