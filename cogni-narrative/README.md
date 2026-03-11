# Narrative Transformation Plugin

A story arc-driven narrative plugin primarily designed for [Cowork](https://claude.com/product/cowork), Anthropic's agentic desktop application — though it also works in Claude Code. Transforms research syntheses, analyses, and structured content into compelling executive narratives using 6 story arc frameworks and 8 narrative techniques.

> **Important**: This plugin generates executive narratives from structured input. All outputs should be reviewed for accuracy and tone before use in executive presentations, board materials, or external communications.

## Installation

```bash
claude plugins add cogni-work/cogni-narrative
```

## Commands

| Command | Description |
|---------|-------------|
| `/narrative` | Transform research syntheses, analyses, and structured markdown into an executive narrative using a story arc framework |
| `/narrative-review` | Score and review a narrative file against story arc quality gates — produces a scorecard with pass/warn/fail per gate and improvement suggestions |
| `/narrative-adapt` | Transform a narrative into derivative formats: executive brief (300-500 words), talking points (bullet list), or one-pager (structured reference) |

## Skills

| Skill | Description |
|-------|-------------|
| `narrative` | Story arc selection, narrative transformation methodology, 8 narrative techniques (Pyramid Principle, PSB, Number Plays, etc.), quality validation, and bilingual output (EN/DE) |
| `narrative-review` | Quality gate evaluation — scores narratives on structural compliance, word counts, citations, element balance, and language correctness (0-100 with A-F grades) |
| `narrative-adapt` | Format adaptation — condenses full narratives into executive briefs, talking points, or one-pagers while preserving arc structure and key evidence |

## Agents

| Agent | Description |
|-------|-------------|
| `narrative-writer` | Transform structured content into executive narratives — enables parallel narrative generation across multiple content sets |
| `narrative-reviewer` | Proactive quality reviewer — triggers after narrative generation to score output against quality gates and present a scorecard |

## Story Arc Frameworks

| Arc | Structure | Best For |
|-----|-----------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Market research, B2B positioning, sales enablement |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation scouting, R&D strategy, technology trends |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis, market monitoring, threat assessment |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning, scenario analysis, strategic options |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry analysis, regulatory impact, transformation roadmaps |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | Trend-scout output, TIPS trend reports, multi-horizon trend landscapes |

## Example Workflows

### Research-to-Narrative

1. Run `/narrative ./research-output/` to auto-detect the best arc and generate a narrative
2. Review the arc selection and approve or override
3. Receive a 1,500-word executive narrative with inline citations back to source files

### Specific Arc Selection

1. Run `/narrative ./analysis/ --arc technology-futures` to apply a specific story arc
2. Run `/narrative ./report.md --arc corporate-visions -o ./insight-summary.md` to specify output path
3. Review the structured narrative with arc-specific section headers

### German-Language Output

1. Run `/narrative ./research-output/ --lang de` to generate a narrative in German
2. Output uses proper Unicode umlauts and localized section headers throughout

### Review Narrative Quality

1. Run `/narrative-review ./insight-summary.md` to score an existing narrative
2. Receive a scorecard with per-gate results (Structural, Critical, Evidence, Structure, Language)
3. Review the top 3 improvement suggestions

### Adapt to Derivative Formats

1. Run `/narrative-adapt ./insight-summary.md --format executive-brief` for a 300-500 word condensed version
2. Run `/narrative-adapt ./insight-summary.md --format talking-points` for a bullet-point briefing
3. Run `/narrative-adapt ./insight-summary.md --format one-pager` for a structured reference page

## MCP Integration

This plugin works standalone with local markdown files. No MCP server connections are required.

For enhanced workflows, connect complementary plugins:

### Research Input

Connect a research plugin (e.g., cogni-research) to generate structured syntheses that serve as narrative input.

### Visual Output

Connect a presentation plugin (e.g., cogni-visual) to transform narratives into slides, poster storyboards, or visual journey maps.

> **Note:** Without upstream research plugins, you can provide any structured markdown files as input for narrative transformation.

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

## License

[AGPL-3.0](LICENSE)
