---
name: course-deck
description: >-
  Generate professional PPTX slide decks for cogni-teacher courses. Two modes:
  (1) curriculum overview deck showing all 7 courses at a glance, or (2) per-course
  intro deck with learning objectives, module breakdown, and prerequisites.
  Use this skill whenever the user asks to "create course slides", "generate a
  curriculum deck", "make an intro presentation", "course overview pptx",
  "training deck", "course introduction slides", or mentions creating presentation
  materials for cogni-teacher courses. Also trigger when someone says "prepare
  materials for a training session" or "I need slides for onboarding new learners".
version: 0.1.0
---

# course-deck: Course Presentation Generator

Generate polished PPTX slide decks for cogni-teacher training programs. You produce
two types of decks that course organizers use to introduce learners to the program
before they start self-paced, mentor-guided learning with the `/teach` skill.

## Two Deck Types

### 1. Curriculum Overview (`curriculum`)

A program-level deck introducing the full cogni-works training program. Use this
when the organizer wants to present the overall learning journey to a group of
new learners.

**Slides to generate (~8-10 slides):**

1. **Title slide** — "cogni-works Training Program" with subtitle "Master AI-Powered
   Consulting with Claude Cowork". Dark background (`111111`) with chartreuse accent line.

2. **Why this program** — The value proposition: what consultants gain by learning
   cogni-works (faster deliverables, consistent quality, AI-augmented research).
   Use 3 key benefit statements with icons.

3. **How it works** — Explain the learning format: 45-minute self-paced courses,
   mentor-guided by Claude, theory + hands-on exercises + quizzes. Visual showing
   the module cycle: Theory > Demo > Exercise > Quiz > Recap.

4. **Learning journey** — Visual roadmap of all 7 courses as a numbered path or
   timeline. Show course progression from fundamentals to advanced.

5-6. **Course spotlight slides** — Two slides, each covering 3-4 courses with:
   course number, title, what you'll learn (2-3 bullets), plugins covered.
   Courses 1-3 on one slide, 4-7 on the next.

7. **What you'll build** — Showcase the deliverables learners create during
   exercises (memos, narratives, trend reports, portfolios, presentations).

8. **Getting started** — How to begin: open Claude Cowork, type `/teach 1`,
   and follow along. Include the `/courses` command to check progress.

### 2. Course Introduction (`<course-number>`)

A course-level deck introducing a specific course. Use when the organizer wants
to set expectations before learners dive into a particular course.

**Slides to generate (~6-8 slides):**

1. **Title slide** — Course number and title. Subtitle with duration (45 min)
   and module count.

2. **What you'll learn** — 4-5 learning objectives pulled from the course content.
   Use checkmark icons with chartreuse accent.

3. **Module overview** — All 5 modules listed with brief description of each.
   Visual timeline or numbered cards layout.

4. **Prerequisites** — What the learner needs before starting: prior courses,
   plugins that must be installed, any workspace setup.

5. **Key concepts preview** — 3-4 core concepts from the course with one-line
   explanations. Gives learners mental hooks before they start.

6. **What you'll build** — The hands-on deliverable(s) from the exercises.
   Concrete output they'll walk away with.

7. **Ready to start** — CTA slide: "Open Claude Cowork and type `/teach <N>`
   to begin. Your AI mentor will guide you through each module."

## Content Source

Pull all course content from the reference files in this plugin:

- `references/courses/01-cowork-fundamentals.md`
- `references/courses/02-workspace-obsidian.md`
- `references/courses/03-basic-tools.md`
- `references/courses/04-tips-scouting.md`
- `references/courses/05-tips-reporting.md`
- `references/courses/06-portfolio.md`
- `references/courses/07-visual.md`

Read only the course file(s) needed for the requested deck. For curriculum overview,
skim all 7 files for titles, objectives, and module names — don't load full content.

## Course Mapping

Map user input to course files:

| Input | Course |
|-------|--------|
| 1, cowork, fundamentals | 01-cowork-fundamentals |
| 2, workspace, obsidian | 02-workspace-obsidian |
| 3, basic, tools, copywriting | 03-basic-tools |
| 4, scouting, tips-scouting | 04-tips-scouting |
| 5, reporting, tips-reporting | 05-tips-reporting |
| 6, portfolio | 06-portfolio |
| 7, visual | 07-visual |

## Visual Design: cogni-work Theme

Apply the cogni-work theme. The authoritative theme file lives at:
`/Users/stephandehaas/GitHub/dev/cogni-workspace/themes/cogni-work/theme.md`

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
- Curriculum: `cogni-works-training-program.pptx`
- Course intro: `course-<N>-<name>-intro.pptx` (e.g., `course-3-basic-tools-intro.pptx`)

After generating, tell the user where the file is saved and suggest they review it.
