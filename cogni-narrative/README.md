# cogni-narrative

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The story arc engine for the insight-wave ecosystem — it imposes named arc-framework discipline on structured research, turning data into executive-grade narratives between cogni-knowledge and cogni-copywriting.

## Why this exists

Research output is structured but not persuasive. Executives don't read data dumps — they need a story that connects evidence to decisions, and a synthesis that reads well in one document reads flat in the next when every author invents the structure from scratch:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Data without narrative | Research reports present findings but no story arc | Executives skim and move on — insights don't drive decisions |
| No methodology discipline | Writers improvise narrative structure per document | Inconsistent quality; some sections compelling, others flat |
| Format lock-in | One narrative output, one format — can't easily derive briefs, talking points, or one-pagers | Manual rewriting for each audience and format |
| Quality unmeasured | No scoring or review gates for narrative quality | Weak narratives ship without feedback |

A strong synthesis dies when it lands in front of the wrong reader in the wrong shape — and there is no way to tell a compelling draft from a flat one until someone has already skimmed past it.

> **Important**: This plugin generates executive narratives from structured input. All outputs should be reviewed for accuracy and tone before use in executive presentations, board materials, or external communications.

## What it is

A story arc engine for the insight-wave ecosystem. Eleven named arc frameworks — covering sales, innovation, competitive intelligence, investment themes, portfolio introductions, and company pages — impose rhetorical discipline on structured content, mapping evidence to arc elements, transitions, and quality gates. Other plugins produce research and data; cogni-narrative shapes it into executive-grade stories that drive decisions.

## What it does

1. **Transform** structured content into executive narratives using a story arc framework — auto-detected or manually selected → `insight-summary.md` → story-to-slides, story-to-web, why-change
2. **Review** narratives against quality gates — structural compliance, evidence density, element balance, language correctness — with scores and grades
3. **Adapt** full narratives into derivative formats: executive briefs (300-500 words), talking points (bullet list), or one-pagers (structured reference) → `executive-brief.md` + `talking-points.md` + `one-pager.md` → copywriter

## What it means for you

- **Arc-disciplined, not improvised.** Every narrative follows a proven story arc — cutting first-draft time from hours to under 15 minutes, with quality consistent across documents and authors.
- **Match the arc to the audience first.** Eleven frameworks cover every consulting output type — sales enablement, investment themes, company pages — so structure follows context, not guesswork.
- **Catch a weak draft before it ships.** Automated scoring (0-100, A-F) on structure, accuracy, evidence density, and language flags soft sections with per-dimension fixes — before a reader skims past.
- **Repurpose without rewriting.** Derive an executive brief, talking points, and a one-pager from one narrative — three formats, no per-channel rework.
- **Ship in the reader's language.** Full EN/DE support with localized arc headers and proper Unicode — no post-processing for German clients or DACH reports.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/narrative ./research-output/                          # auto-detect arc
/narrative ./analysis/ --arc technology-futures         # specify arc
/narrative ./report.md --arc corporate-visions -o out.md  # specify output
/narrative-review ./insight-summary.md                  # score quality
/narrative-adapt ./insight-summary.md --format executive-brief  # derive brief
```

Or describe what you want:

- "Transform this research into an executive narrative"
- "Score this narrative against quality gates"
- "Create talking points from this narrative"
- "Write a German narrative using the trend panorama arc"

## Try it

Point the plugin at a research-output directory and run the transform:

> Run `/cogni-narrative:narrative ./research-output/`

Claude reads the structured content, proposes the best-fit story arc, and asks you to confirm or override before writing. Approve it, and you get an executive narrative at `./research-output/insight-summary.md` — arc-structured sections with inline citations back to the source files, plus `arc_id` and element metadata in the YAML frontmatter.

Then score what you wrote:

> Run `/cogni-narrative:narrative-review ./research-output/insight-summary.md`

You get a scorecard with a 0-100 composite, an A-F grade, per-gate results (structural, critical, evidence, language), and the top improvement suggestions.

Need a shorter cut for a different audience? Derive one without rewriting:

> Run `/cogni-narrative:narrative-adapt ./research-output/insight-summary.md --format executive-brief`

The adapter writes `executive-brief.md` alongside the source, condensing proportionally while preserving the arc.

## Story arc frameworks

| Arc | Structure | Best for |
|-----|-----------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Market research, B2B positioning, sales enablement |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation scouting, R&D strategy, technology trends |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis, market monitoring, threat assessment |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning, scenario analysis, strategic options |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry analysis, regulatory impact, transformation roadmaps |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | Trend-scout output, TIPS trend reports, multi-horizon landscapes |
| `theme-thesis` | Why Change → Why Now → Why You → Why Pay | Investment theme narratives within TIPS reports |
| `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation | Portfolio introductions, capability overviews, pre-sales |
| `company-credo` | Mission → Conviction → Credibility → Promise | Website About-Us pages, company introductions |
| `engagement-model` | Principles → Process → Partnership → Outcomes | Website How-We-Work pages, engagement sections of proposals |

## Example workflows

### Research-to-Narrative

1. Run `/narrative ./research-output/` to auto-detect the best arc and generate a narrative
2. Review the arc selection and approve or override
3. Receive a 1,500-word executive narrative with inline citations

### Review Narrative Quality

1. Run `/narrative-review ./insight-summary.md` to score an existing narrative
2. Receive a scorecard with per-gate results (Structural, Critical, Evidence, Structure, Language)
3. Review the top 3 improvement suggestions

### Adapt to Derivative Formats

1. `/narrative-adapt ./insight-summary.md --format executive-brief` — 300-500 word condensed version
2. `/narrative-adapt ./insight-summary.md --format talking-points` — bullet-point briefing
3. `/narrative-adapt ./insight-summary.md --format one-pager` — structured reference page

### German-Language Output

Run `/narrative ./research-output/ --lang de` to generate a narrative in German with proper Unicode umlauts and localized section headers.

## How it works

The pipeline runs arc-first, because structure must be chosen before evidence can be placed into it. When you invoke `narrative`, `bridge-citations.py` first converts upstream `[Source: Publisher](URL)` inline citations into per-source markdown files, so the writer can cite and link them cleanly. The skill then analyzes the input's shape and proposes a story arc — one of eleven named frameworks, each defining its own element flow, evidence requirements, and transition patterns. Corporate Visions runs Why Change → Why Now → Why You → Why Pay; trend-panorama runs Forces → Impact → Horizons → Foundations; and so on. You confirm or override, then a per-arc phase-4b synthesis workflow maps the structured content into that arc's elements and writes `insight-summary.md` with `arc_id` frontmatter.

`narrative-review` exists as a separate step because quality is a property of the finished narrative, not a side effect of writing it — it scores the draft across four gates (structural compliance, critical accuracy, evidence density, language correctness) into a composite 0-100 score and A-F grade, with per-dimension suggestions. `narrative-adapt` runs last and downstream: it reads the scored narrative and condenses it proportionally into derivative formats rather than re-deriving structure, so the arc survives into the brief, the talking points, and the one-pager. The `arc_id` frontmatter then carries forward — cogni-copywriting reads it for arc-aware polishing, and cogni-visual reads the narrative for slides and web output.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `narrative` | skill | Story arc selection, narrative transformation, 8 techniques, quality validation, bilingual output |
| `narrative-review` | skill | Quality gate evaluation — scores on structural compliance, evidence, balance, language (0-100, A-F grades) |
| `narrative-adapt` | skill | Format adaptation — executive briefs, talking points, one-pagers preserving arc structure |
| `narrative-writer` | agent (sonnet) | Parallel narrative generation across multiple content sets |
| `narrative-reviewer` | agent (sonnet) | Proactive quality reviewer — triggers after generation to score and present scorecard |
| `narrative-adapter` | agent (sonnet) | Format adaptation agent for derivative output |
| `/narrative` | command | Transform content into an arc-driven narrative |
| `/narrative-review` | command | Score and review a narrative against quality gates |
| `/narrative-adapt` | command | Adapt a narrative into derivative formats |

## Architecture

```
cogni-narrative/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       3 narrative skills
│   ├── narrative/
│   ├── narrative-review/
│   └── narrative-adapt/
├── agents/                       3 delegation agents
│   ├── narrative-writer.md
│   ├── narrative-reviewer.md
│   └── narrative-adapter.md
└── commands/                     3 slash commands
    ├── narrative.md
    ├── narrative-review.md
    └── narrative-adapt.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-trends | No | Provides trend-scout output for the `trend-panorama` arc |
| cogni-knowledge | No | Provides research syntheses (inverted-pipeline output) as narrative input |
| cogni-portfolio | No | jtbd-portfolio arc reads portfolio entity files |
| cogni-copywriting | No | Arc-aware executive polish (downstream) |
| cogni-visual | No | Slide decks and visual assets from narrative output (downstream) |
| cogni-sales | No | Consumes Corporate Visions arc patterns (downstream) |
| cogni-claims | No | company-credo arc references cogni-claims data files for claim-backed credibility sections |

cogni-narrative is standalone. It transforms structured input from any source — cogni-x plugins or plain markdown files.

## Contributing

Contributions welcome — new arc frameworks, narrative techniques, language templates, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom story arc framework, your house narrative style encoded as a gate, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code narrative automation for consulting and sales teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
