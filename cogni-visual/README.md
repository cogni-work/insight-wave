# cogni-visual

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai/cowork) plugin that turns a polished narrative into branded visual deliverables — the last-mile production step of the insight-wave consulting pipeline.

## Why this exists

The thinking is done and the narrative is written — but the deliverable a client actually sees still has to be built by hand. That last mile is where consulting projects lose days and where polished insight starts to look generic.

| Problem | What happens | Impact |
|---------|-------------|--------|
| Manual visual production | Building a branded slide deck from finished narrative content runs to 1-2 days of layout and formatting | Delivery bottleneck — insight is ready Tuesday, the client sees it Thursday |
| Format fragmentation | The same core message needs slides for the boardroom, a poster for the workshop, and a web page for the follow-up | Every format becomes a separate production effort, re-typed from the same source |
| Template fatigue | Generic templates produce generic-looking output, and custom design is slow and expensive to commission | Deliverables look interchangeable with every other consultancy's output |
| No check before render | Weak headlines and missing calls to action only surface once the file is fully rendered | Rework is expensive — fixing a slide means re-running the whole rendering pipeline |

Each of these costs compounds across every deliverable on every engagement, so the production tax never goes away.

## What it is

A brief-based visual production engine built on a two-stage model: a structured brief (YAML frontmatter plus Markdown body) is the design specification, and rendering agents are the production line that turns it into a finished file. The brief is the source of truth, so every output is theme-driven rather than template-driven — visuals inherit brand identity from a cogni-workspace theme. Other plugins compose and polish the narrative; this one makes it look like a deliverable.

## What it does

1. **Brief** a presentation from any narrative → `presentation-brief.md` → pptx (PowerPoint deck)
2. **Brief** a poster series from any narrative → `storyboard-brief.md` → storyboard (print poster series)
3. **Brief** a scrollable web page from any narrative → `web-brief.md` → web (scrollable landing page)
4. **Brief** an infographic from any narrative → `infographic-brief.md` → `/render-infographic` (auto-routes to Excalidraw for sketchnote/whiteboard or Pencil MCP for economist/editorial/data-viz/corporate)
5. **Enrich** a markdown report into themed HTML → `{report}-enriched.html` (branded interactive HTML)
6. **Render** a presentation brief into a browser-ready HTML deck → `{name}.html` (self-contained slide deck with speaker notes)
7. **Review** a visual brief from three stakeholder perspectives — design quality, audience experience, usability

## What it means for you

- **Skip the formatting day.** Turn a polished narrative into a presentation brief in one prompt — assertion headlines, number plays, speaker notes, and 11 slide layout types generated for you instead of the 1-2 days of manual formatting it replaces.
- **Reuse one narrative across every format.** Produce slides, scrollable web pages, print poster storyboards, and single-page infographics from the same source document — no re-authoring per channel.
- **Reskin everything from one file.** Visuals inherit colors and fonts from your cogni-workspace theme, so changing one theme file restyles every output instead of editing each object by hand.
- **Catch weak headlines before you render.** A three-perspective brief review flags soft headlines, missing CTAs, and layout mismatches up front — fixing a line of text is far cheaper than re-running a render.

## Known Limitations

> **Chrome native messaging host conflict between Cowork and Claude Code** (S2-major) — Browser-based zone review for rendered visuals may fail silently when tools are missing. Workaround: Toggle native messaging host configs by renaming the .json file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for details.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note:** Excalidraw MCP is required for hand-drawn infographic rendering (sketchnote, whiteboard traditions). Pencil MCP is required for editorial infographic rendering (economist, editorial, data-viz, corporate), web narratives, and storyboards. Both MCPs are optional — the brief-generation skills work without them.

## Quick start

```
story-to-slides <narrative.md>             # presentation brief → document-skills:pptx
story-to-web <narrative.md>                # web narrative brief → Pencil MCP
story-to-storyboard <narrative.md>         # poster storyboard brief → Pencil MCP
story-to-infographic <narrative.md>        # infographic brief (7 layouts × 6 style presets)
/render-infographic <brief.md>             # auto-routes to Excalidraw or Pencil based on style
/render-infographic-handdrawn <brief.md>   # direct: sketchnote or whiteboard → Excalidraw
/render-infographic-editorial <brief.md>   # direct: economist/editorial/data-viz → Pencil MCP
/enrich-report <report.md>                 # markdown report → themed HTML with charts + diagrams
/render-html-slides <brief.md>             # presentation brief → self-contained HTML slide deck
/review-brief <brief.md>                   # visual brief → stakeholder review (3 perspectives)
```

Or just describe what you want in natural language:

- "Create a presentation from my narrative"
- "Create a scrollable web version of my narrative"
- "Create an infographic from my narrative"

## Try it

Start from a polished narrative and turn it into an infographic. First, generate the brief:

```
story-to-infographic my-narrative.md
```

Claude reads the narrative, detects its story arc from frontmatter, distills the content into 3-8 scannable blocks with hero numbers and assertion headlines, and writes an `infographic-brief.md` next to your source.

Then render it. The `/render-infographic` command reads the brief's `style_preset` and routes to the right rendering agent automatically:

> Run `/render-infographic infographic-brief.md`

A sketchnote or whiteboard preset routes to Excalidraw for a hand-drawn scene; an economist, editorial, data-viz, or corporate preset routes to Pencil MCP for a clean editorial `.pen` page. Either way the output inherits your cogni-workspace theme, and you get a finished infographic file beside the brief — colors and fonts already on-brand, no manual styling step.

## How it works

The plugin sits at the end of a compose-polish-visualize flow: cogni-narrative composes the story, cogni-copywriting polishes the prose, and cogni-visual visualizes the result. It keeps that final stage in two deliberately separate phases — brief generation and rendering — because authoring a design and producing pixels are different jobs with different failure modes.

In the first phase, a `story-to-X` skill reads the narrative and writes a structured brief: YAML frontmatter for metadata (type, theme, arc) and a Markdown body for the content specification. The brief deliberately carries no colors or fonts — those are resolved later from the theme — so the same brief can be reskinned without re-authoring. Splitting design from rendering is also what makes review cheap: the `review-brief` skill assesses the brief from three stakeholder perspectives (design, audience, usability) before any rendering cost is incurred, so a weak headline is caught as text rather than as a finished file.

In the second phase, a rendering agent consumes the brief and produces the output file, reading the cogni-workspace theme directly for brand identity. Different deliverables route to different backends: slide briefs go to PPTX or a self-contained HTML deck, web and storyboard briefs to Pencil MCP, and infographic briefs through the `/render-infographic` dispatcher, which reads the brief's `style_preset` and routes to a hand-drawn (Excalidraw) or editorial (Pencil) agent. Because the brief is the single source of truth, every backend renders the same specification consistently.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `story-to-slides` | skill | Transform any narrative into an optimized multi-slide presentation brief that the PPTX skill can render |
| `story-to-web` | skill | Transform any narrative into an optimized scrollable web narrative brief that the web agent can render |
| `story-to-storyboard` | skill | Transform any narrative into a multi-poster print storyboard brief for executive walkthroughs |
| `story-to-infographic` | skill | Transform any narrative into a single-page infographic brief (7 layout types, 6 style presets) |
| `render-html-slides` | skill | Render a presentation-brief.md into a self-contained HTML slide presentation with speaker notes and keyboard navigation |
| `enrich-report` | skill | Post-process any completed markdown report into a themed, self-contained HTML file with Chart.js visualizations |
| `review-brief` | skill | Review a visual brief from three stakeholder perspectives — design quality, audience experience, and usability |
| `story-to-slides` | agent | Orchestrates the story-to-slides skill |
| `pptx` | agent | Renders presentation briefs into .pptx via document-skills |
| `html-slides` | agent | Renders presentation briefs into self-contained HTML slide decks |
| `slides-enrichment-artist` | agent | Generates prep slides and per-slide speaker notes for a completed slide deck |
| `story-to-web` | agent | Orchestrates the story-to-web skill |
| `web` | agent | Renders web briefs into .pen + self-contained HTML via Pencil MCP |
| `story-to-storyboard` | agent | Orchestrates the story-to-storyboard skill |
| `storyboard` | agent | Renders storyboard briefs into multi-poster .pen via Pencil MCP |
| `story-to-infographic` | agent | Orchestrates the story-to-infographic skill |
| `render-infographic-pencil` | agent | Renders infographic briefs into editorial .pen via Pencil MCP (economist, editorial, data-viz, corporate) |
| `render-infographic-sketchnote` | agent | Renders infographic briefs into hand-drawn Excalidraw scenes — sketchnote tradition (Mike Rohde) |
| `render-infographic-whiteboard` | agent | Renders infographic briefs into hand-drawn Excalidraw scenes — whiteboard tradition (Dan Roam) |
| `editorial-sketch` | agent | Worker — generates one editorial-discipline line-art sketch as inline SVG |
| `enrich-report` | agent | Orchestrates the enrich-report skill (markdown report → themed HTML) |
| `report-html-writer` | agent | Worker (opus) — writes the scroll-layout HTML from source markdown, enrichment-plan, and design-variables for enrich-report Phase 4a |
| `enriched-report-reviewer` | agent | Worker — visual quality review of enriched HTML via Browser MCP screenshots (10-gate rubric) for enrich-report Phase 5b |
| `concept-diagram` | agent | Worker — generates one concept diagram via Excalidraw MCP (fallback for interactive .excalidraw) |
| `concept-diagram-svg` | agent | Worker — generates one concept diagram as clean inline SVG using geometric primitives (default) |
| `brief-review-assessor` | agent | Assesses visual brief quality from three stakeholder perspectives adapted to the brief type |
| `/enrich-report` | command | Enrich a markdown report with themed Chart.js visualizations and concept diagrams |
| `/render-html-slides` | command | Render a presentation-brief.md into a themed HTML slide presentation with speaker notes |
| `/render-infographic` | command | Render an infographic brief — auto-routes to the right rendering agent based on style preset |
| `/render-infographic-handdrawn` | command | Render an infographic brief as a hand-drawn Excalidraw scene (sketchnote or whiteboard) |
| `/render-infographic-editorial` | command | Render an infographic brief as an editorial .pen file via Pencil MCP |
| `/review-brief` | command | Review a visual brief from stakeholder perspectives (design, audience, usability) |
| `ensure-excalidraw-canvas` | hook (PreToolUse) | Auto-starts Excalidraw canvas frontend before any Excalidraw MCP tool call |

## Architecture

```
cogni-visual/                              # 7 skills · 19 agents · 6 commands · 1 hook
├── .claude-plugin/                        Plugin manifest (v0.16.24)
├── skills/                               7 visual skills (4 brief generators · 1 renderer · 1 enricher · 1 reviewer)
│   ├── story-to-slides/
│   ├── story-to-web/
│   ├── story-to-storyboard/
│   ├── story-to-infographic/
│   ├── render-html-slides/
│   ├── enrich-report/
│   └── review-brief/
├── agents/                               19 agents (orchestration · rendering · workers)
├── commands/                             6 slash commands (including /render-infographic dispatcher + 2 direct variants)
├── hooks/                                1 PreToolUse hook (Excalidraw canvas auto-start)
├── scripts/                              Utility scripts (rasterize-sketch.py, cartographic-outline.py)
├── references/                           Reference data (cartographic-data/)
├── evals/                                Evaluation harnesses (render-infographic)
└── libraries/                            17 shared reference files
    ├── arc-taxonomy.md                   arc ID → visual arc type mapping
    ├── cta-taxonomy.md                   CTA types and urgency levels
    ├── pptx-layouts.md                   slide layout schemas
    ├── web-layouts.md                    section types and design tokens
    ├── storyboard-layouts.md             poster dimensions and zone anatomy
    ├── infographic-layouts.md            layout type schemas for infographics
    ├── infographic-pencil-layouts.md     Pencil MCP: Economist tokens, Lucide icons, batch_design syntax
    ├── brief-review-perspectives.md      perspective sets for stakeholder review
    ├── svg-patterns.md                   SVG element recipes for concept diagrams
    ├── excalidraw-patterns.md            Excalidraw MCP element recipes
    ├── render-excalidraw-common.md       shared hand-drawn discipline (canvas lifecycle, review gates)
    ├── EXAMPLE_BRIEF.md                  annotated presentation brief example
    ├── EXAMPLE_WEB_BRIEF.md              annotated web narrative brief example
    ├── EXAMPLE_STORYBOARD_BRIEF.md       annotated storyboard brief example
    ├── EXAMPLE_INFOGRAPHIC_BRIEF.md      annotated infographic brief (stat-heavy, data-viz)
    ├── EXAMPLE_SKETCHNOTE_BRIEF.md       annotated infographic brief (timeline-flow, sketchnote)
    └── EXAMPLE_ECONOMIST_BRIEF.md        annotated infographic brief (stat-heavy portrait, economist)
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | Yes | Produces narratives consumed by all story-to-X skills (upstream compose step) |
| cogni-copywriting | Yes | Polishes narratives before visual briefing (upstream polish step) |
| cogni-workspace | Yes | Provides brand themes for all visual output |
| cogni-trends | No | Trend reports for enrich-report |
| cogni-knowledge | No | enrich-report detects knowledge project configs for report-type-specific enrichment |
| cogni-portfolio | No | enrich-report references portfolio-dashboard patterns for dashboard-style enrichment |
| cogni-sales | No | story-to-slides integrates with why-change Phase 5 for sales-presentation slide rendering |
| document-skills | No | PPTX rendering for slide briefs |
| Excalidraw MCP | No | Canvas rendering for infographic diagrams (github.com/yctimlin/mcp_excalidraw) |
| Pencil MCP | No | Canvas rendering for web narratives and poster storyboards (pencil.li) |

## Contributing

Contributions welcome — visual templates, layout types, rendering improvements, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need bespoke visual templates, a branded rendering pipeline tuned to your house style, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) designs and maintains custom Claude Code automation for consulting and marketing teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
