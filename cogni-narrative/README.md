# cogni-narrative

Story arc-driven narrative transformation plugin for [Claude Cowork](https://claude.ai/cowork). Transforms research syntheses, analyses, and structured content into compelling executive narratives using 7 story arc frameworks and 8 narrative techniques. Bilingual EN/DE.

## Why this exists

Research output is structured but not persuasive. Executives don't read data dumps — they need a story that connects evidence to decisions:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Data without narrative | Research reports present findings but no story arc | Executives skim and move on — insights don't drive decisions |
| No methodology discipline | Writers improvise narrative structure per document | Inconsistent quality; some sections compelling, others flat |
| Format lock-in | One narrative output, one format — can't easily derive briefs, talking points, or one-pagers | Manual rewriting for each audience and format |
| Quality unmeasured | No scoring or review gates for narrative quality | Weak narratives ship without feedback |

This plugin applies structured story arc frameworks — each with defined sections, evidence requirements, and transition patterns — so narratives are consistently compelling and reviewable.

> **Important**: This plugin generates executive narratives from structured input. All outputs should be reviewed for accuracy and tone before use in executive presentations, board materials, or external communications.

## What it is

A story arc engine for the insight-wave ecosystem. Seven arc frameworks — Corporate Visions for sales, Technology Futures for innovation, Competitive Intelligence for threats, Strategic Foresight for planning, Industry Transformation for change, Trend Panorama for TIPS output, and Theme-Thesis for investment theme narratives — impose narrative discipline on structured content. Other plugins produce research and data; cogni-narrative shapes it into executive-grade stories that drive decisions.

## What it does

1. **Transform** structured content into executive narratives using a story arc framework — auto-detected or manually selected
2. **Review** narratives against quality gates — structural compliance, evidence density, element balance, language correctness — with scores and grades
3. **Adapt** full narratives into derivative formats: executive briefs (300-500 words), talking points (bullet list), or one-pagers (structured reference)

## What it means for you

- **Arc-disciplined, not improvised.** Every narrative follows a proven story arc structure — consistent quality across documents and authors.
- **Seven frameworks for seven contexts.** Corporate Visions for sales, Technology Futures for innovation, Competitive Intelligence for threats, Strategic Foresight for planning, Industry Transformation for change, Trend Panorama for TIPS output, Theme-Thesis for investment themes.
- **Quality-gated.** Automated scoring (0-100, A-F grades) on structural compliance, critical accuracy, evidence density, and language — with improvement suggestions per dimension.
- **One narrative, three derivative formats.** Executive briefs, talking points, and one-pagers — adapted from the source narrative without rewriting.
- **Bilingual.** Full EN/DE support with localized section headers and proper Unicode handling.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

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

After installing, type one prompt:

> Transform this research into an executive narrative

Claude reads your research output, auto-detects the best story arc, asks you to confirm or override, then generates a 1,500-word executive narrative with inline citations back to source files.

## Story arc frameworks

| Arc | Structure | Best for |
|-----|-----------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Market research, B2B positioning, sales enablement |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation scouting, R&D strategy, technology trends |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis, market monitoring, threat assessment |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning, scenario analysis, strategic options |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry analysis, regulatory impact, transformation roadmaps |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | Trend-scout output, TIPS trend reports, multi-horizon landscapes |

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
| cogni-research | No | Provides research reports as narrative input |
| cogni-copywriting | No | Arc-aware executive polish (downstream) |
| cogni-visual | No | Slide decks and visual assets from narrative output (downstream) |
| cogni-sales | No | Consumes Corporate Visions arc patterns (downstream) |

cogni-narrative is standalone. It transforms structured input from any source — cogni-x plugins or plain markdown files.

## Contributing

Contributions welcome — new arc frameworks, narrative techniques, language templates, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need custom story arc frameworks, house narrative style, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
