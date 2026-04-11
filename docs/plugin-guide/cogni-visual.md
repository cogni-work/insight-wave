# cogni-visual

Transform polished narratives and structured data into visual deliverables — slide decks, journey map canvases, solution architecture diagrams, scrollable web pages, and print poster storyboards.

For the canonical IS/DOES/MEANS positioning of this plugin, see the [cogni-visual README](../../cogni-visual/README.md).

---

## Overview

cogni-visual sits at the end of the insight-wave delivery pipeline, after content has been composed (cogni-narrative) and polished (cogni-copywriting). It takes three kinds of inputs — narratives in prose, structured data from cogni-trends, and completed markdown reports — and produces seven kinds of visual output through a two-stage process: brief generation followed by rendering, plus a report enrichment pipeline.

**Stage 1 (brief):** A skill reads the source material, models the audience, selects the format, maps content to layout units, and writes a structured brief as YAML frontmatter + Markdown body. The brief describes *what* to visualize — objects, messages, flow — without prescribing drawing operations.

**Stage 2 (render):** A renderer consumes the brief and produces the final file via a downstream tool: PPTX files via `document-skills:pptx`, Excalidraw canvases via the Excalidraw MCP, or web and print designs via the Pencil MCP.

All visual output inherits brand identity (colors, fonts, identity) from the active cogni-workspace theme. There are no color or font fields in briefs — renderers read `theme.md` directly.

The `/render-infographic` command is a smart dispatcher: it reads the brief's `style_preset` and routes to one of two Opus-powered render agents. Hand-drawn family (sketchnote, whiteboard) goes to `render-infographic-excalidraw` via Excalidraw MCP; editorial family (economist, editorial, data-viz, corporate) goes to `render-infographic-pencil` via Pencil MCP. Direct commands `/render-infographic-excalidraw` and `/render-infographic-pencil` skip the dispatch step when the caller already knows the family.

---

## Key Concepts

### Brief-Based Architecture

All five brief-generating skills produce a structured brief rather than calling a renderer directly. This separation means:

- Briefs are reviewable and editable before rendering
- The same brief can be rendered by different downstream tools as formats evolve
- Rendering failures don't require re-running the brief generation step

Briefs use YAML frontmatter for metadata (`type`, `version`, `theme`, `arc_type`, `arc_id`, `confidence_score`) and Markdown body for content specification.

### Arc Taxonomy

Narrative skills detect the story arc from the source document's `arc_id` frontmatter and map it to a visual arc type via `libraries/arc-taxonomy.md`. Six narrative arcs map to five visual arc types, which control layout ordering, station labels, and section sequencing.

### Assertion Headlines

Every slide title, station headline, section headline, and poster headline must be an assertion — it contains a verb and makes a claim. Topic labels ("Digital Transformation") are rejected; assertions ("Digital transformation is creating $4.2T in new industry value") are required. This applies to all five brief-generating skills.

### Number Plays

Statistics are reframed for visual impact rather than presented as raw numbers. A slide reading "14% of organizations have adopted AI-powered maintenance" becomes a hero number play: "Only 1 in 7 organizations has adopted predictive maintenance — 85% are leaving cost savings on the table." Three reframing patterns: ratio framing, hero number isolation, and before/after contrast.

### Pipeline Position

```
cogni-narrative  →  cogni-copywriting  →  cogni-visual
(compose)            (polish)              (visualize)
```

---

## Getting Started

**First prompt:**

> Create a presentation from my trend report

What happens:

1. `story-to-slides` reads the narrative source file you point it to
2. Detects the story arc from frontmatter (`arc_id`) or infers it from content
3. Models the audience (role, context, objections)
4. Maps narrative sections to slide layouts using the 11 available layout types
5. Generates assertion headlines and number plays for each slide
6. Proposes CTAs (per-slide and primary CTA)
7. Writes `presentation-brief.md` and asks whether to proceed to PPTX rendering

**What to have ready:**

- A narrative document (from cogni-narrative or any well-structured prose)
- An active cogni-workspace theme (for brand-driven output)
- document-skills plugin (for PPTX rendering)

---

## Capabilities

### story-to-slides

Transform any narrative into a multi-slide presentation brief. Models the audience, applies pyramid communication structure, generates assertion headlines with number plays, maps to 11 slide layout types, and produces speaker notes. The brief (`presentation-brief.md`) can be rendered into `.pptx` by `document-skills:pptx` or into a self-contained HTML slide presentation by `render-html-slides`.

**Example prompt:** "Turn my automotive trend report into a 12-slide executive presentation"

---

### render-html-slides

Render a `presentation-brief.md` into a self-contained HTML slide presentation. Produces a single `.html` file with keyboard navigation, speaker notes, and themed styling derived from the active cogni-workspace theme. Offers an alternative HTML output path alongside the existing `story-to-slides` → PPTX pipeline — use this when sharing slides as a web file is preferred over a PPTX download.

Invoke via `/render-html-slides` or by running the skill directly.

**Example prompt:** "/render-html-slides" (when a `presentation-brief.md` is present in the working directory)

---

### story-to-web

Transform any narrative into a scrollable web narrative brief. Maps content to section types (hero, data story, capability, CTA, etc.), selects from 200+ style guide tags, generates design tokens, and outputs image prompts per section. The brief is rendered into a `.pen` design file and self-contained HTML via the Pencil MCP.

**Example prompt:** "Create a scrollable web version of my trend report for the client follow-up microsite"

---

### story-to-storyboard

Transform any narrative into a multi-poster print storyboard brief. Paginates the narrative into 3–5 portrait DIN-A posters (A0–A3) with stacked web sections per poster. Designed for room-tour walkthroughs, guided exhibition posters, and executive presentations with physical materials.

**Example prompt:** "Create a 4-poster print storyboard for our strategy walkthrough"

---

### review-brief

Evaluate a visual brief from three stakeholder perspectives — design quality, audience experience, and usability — before committing to the rendering step. Supports presentation-brief, web-brief, storyboard-brief, and infographic-brief. The skill dispatches the `brief-review-assessor` agent, which returns a structured verdict (accept/revise/reject) with a score and prioritized improvements. If set to auto-improve, it applies critical and high-priority fixes and re-runs the assessment (max 2 rounds).

Reviewing at the brief stage is efficient: editing text is cheap, re-rendering is not.

**Example prompt:** "Review my presentation brief before rendering" or `/review-brief`

---

### enrich-report

Post-process any completed markdown report — from cogni-research, cogni-trends, or standalone — into a themed, self-contained HTML file with interactive Chart.js data visualizations and Excalidraw concept diagrams embedded as inline SVG. Supports optional PDF and DOCX export via the `formats` parameter. The `density` parameter controls enrichment volume: `none` for themed prose only, `minimal`/`balanced`/`rich` for progressively more data visualizations.

This skill supersedes the deprecated `cogni-research:export-report` and is the single output skill for all report formats across the ecosystem.

**Example prompt:** "Enrich my trend report with charts and diagrams" or `/enrich-report path/to/report.md`

---

## Integration Points

### Upstream (what cogni-visual consumes)

| Plugin | What is consumed |
|--------|-----------------|
| cogni-narrative | Polished narratives with `arc_id` frontmatter as source for all five brief-generating skills |
| cogni-copywriting | Executive-polished prose (narratives should be copywriting-complete before visual transformation) |
| cogni-trends | Trend reports for enrich-report |
| cogni-research | Completed research reports for enrich-report (themed HTML with visualizations) |
| cogni-workspace | Theme files (`themes/{id}/theme.md`) for brand-driven colors and fonts in all renderers |

### Downstream (what cogni-visual produces for others)

| Plugin / Tool | What is provided |
|--------------|-----------------|
| document-skills:pptx | Presentation brief (`presentation-brief.md`) for PPTX rendering |
| render-html-slides | Presentation brief (`presentation-brief.md`) for HTML slide rendering |
| Excalidraw MCP | Infographic brief for canvas rendering |
| Pencil MCP | Web brief and storyboard brief for `.pen` design rendering |

---

## Common Workflows

### Workflow 1: Trend Report to Executive Slides

Use this after a cogni-trends pipeline is complete and the report has been polished by cogni-copywriting.

1. cogni-narrative `/narrative` — transform `tips-trend-report.md` into an arc-driven narrative
2. cogni-copywriting `/copywrite` — executive polish on the narrative
3. cogni-visual `/story-to-slides` — generate presentation brief from the narrative
4. Review and edit the brief (assertion headlines, number plays, slide count)
5. `document-skills:pptx` renders the PPTX file

For the full multi-plugin flow, see [../workflows/trend-report-to-deliverables.md](../workflows/trend-report-to-deliverables.md).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Story-to-slides generates topic labels instead of assertions | Source narrative uses section headings rather than claims | Add assertion headlines to your narrative sections before running the skill, or ask the skill to infer assertions from section body text |
| Colors don't match brand | No cogni-workspace theme active | Run `/pick-theme` in cogni-workspace and confirm a theme is active before rendering |
| Web brief renders without images | Pencil MCP not connected | Verify Pencil MCP is running and accessible; the web agent requires it for `.pen` file rendering |
| Slides are too long | Narrative too long for available slide count | Set a target slide count in your story-to-slides prompt, e.g., "max 10 slides" |

---

## Known Issues

## Extending This Plugin

cogni-visual accepts contributions in several areas:

- **Visual templates** — new layout types for story-to-slides (currently 11 layouts)
- **Web section types** — new section schemas for story-to-web
- **Infographic block types** — new block types for story-to-infographic

See [CONTRIBUTING.md](../../cogni-visual/CONTRIBUTING.md) for guidelines.
