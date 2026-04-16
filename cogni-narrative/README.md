# cogni-narrative

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

The story arc engine for the insight-wave ecosystem — transforms structured research and portfolio output into executive-grade narratives using 10 arc frameworks (Corporate Visions, JTBD Portfolio, Strategic Foresight, Trend Panorama, and six more) and 8 narrative techniques, sitting between cogni-research and cogni-copywriting in the pipeline and feeding cogni-visual, cogni-sales, and cogni-marketing downstream. Bilingual EN/DE.

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

A story arc engine for the insight-wave ecosystem. Ten named arc frameworks — covering sales, innovation, competitive intelligence, investment themes, portfolio introductions, and company pages — impose rhetorical discipline on structured content, mapping evidence to arc elements, transitions, and quality gates. Other plugins produce research and data; cogni-narrative shapes it into executive-grade stories that drive decisions.

## What it does

1. **Transform** structured content into executive narratives using a story arc framework — auto-detected or manually selected → `insight-summary.md` → story-to-slides, story-to-web, why-change
2. **Review** narratives against quality gates — structural compliance, evidence density, element balance, language correctness — with scores and grades
3. **Adapt** full narratives into derivative formats: executive briefs (300-500 words), talking points (bullet list), or one-pagers (structured reference) → `executive-brief.md` + `talking-points.md` + `one-pager.md` → copywriter

## What it means for you

- **Arc-disciplined, not improvised.** Every narrative follows one of 10 proven story arc structures — cutting first-draft time from hours to under 15 minutes while maintaining consistent quality across documents and authors.
- **Match the arc to the audience before you write.** Ten frameworks cover every consulting output type — from sales enablement to board-ready investment themes to company pages — so structure decisions are made by context, not guesswork.
- **Quality-gated.** Automated scoring (0-100, A-F grades) on structural compliance, critical accuracy, evidence density, and language — with improvement suggestions per dimension.
- **One narrative, three derivative formats.** Executive briefs, talking points, and one-pagers — adapted from the source narrative without rewriting.
- **Ship in the reader's language.** Full EN/DE support with localized arc headers and proper Unicode — no post-processing needed for German-language clients or DACH reports.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

### Claude Code desktop (recommended for insight-wave)

Install Claude Code via the native installer, then register the insight-wave marketplace and install this plugin:

```bash
# 1. Install Claude Code (macOS — other platforms: https://code.claude.com/docs/en/setup)
curl -fsSL https://claude.ai/install.sh | bash

# 2. Register the insight-wave marketplace
/plugin marketplace add cogni-work/insight-wave

# 3. Install this plugin
/plugin install cogni-narrative@insight-wave
```

### Claude Cowork (short text-only tasks)

Cowork runs in Claude Desktop and is available on paid plans (Pro, Max, Team, Enterprise). For insight-wave, prefer Claude Code desktop — Cowork has two caveats that affect this plugin's workflows:

- **Context window**: Cowork caps context at ~200K tokens; long multi-agent flows trigger mid-session compressions.
- **Pencil MCP fidelity**: lower visual fidelity in Cowork than in Claude Code desktop.

See the [consultant install guide](../cogni-docs/references/Claude%20Code%20desktop.md) and the [repo-level deployment guide](../docs/deployment-guide.md) for the full path-by-path walkthrough.

> **insight-wave readiness**: Claude Code desktop is the recommended interface for insight-wave today. This guidance will flip when Cowork closes the context-window and Pencil-fidelity gaps.

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
| cogni-portfolio | No | jtbd-portfolio arc reads portfolio entity files |
| cogni-copywriting | No | Arc-aware executive polish (downstream) |
| cogni-visual | No | Slide decks and visual assets from narrative output (downstream) |
| cogni-sales | No | Consumes Corporate Visions arc patterns (downstream) |
| cogni-claims | No | company-credo arc references cogni-claims data files for claim-backed credibility sections |

cogni-narrative is standalone. It transforms structured input from any source — cogni-x plugins or plain markdown files.

## Contributing

Contributions welcome — new arc frameworks, narrative techniques, language templates, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need custom story arc frameworks, house narrative style, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
