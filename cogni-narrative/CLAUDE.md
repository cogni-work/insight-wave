# cogni-narrative

Story arc engine for the insight-wave ecosystem — transforms structured content into executive narratives using 11 arc frameworks and 8 narrative techniques.

## Plugin Architecture

```
skills/                         3 narrative skills
  narrative/                      Transform content into arc-driven narrative (main skill)
    scripts/
      bridge-citations.py         Convert upstream citation formats to per-source markdown files
    references/
      language-templates.md       Language and arc element templates (EN/DE; generation stays EN/DE). Also carries FR/IT/PL/NL/ES arc-element + bridge headings for corporate-visions and jtbd-portfolio as reference data for downstream arc-mode translation (cogni-copywriting). References #318.
      narrative-techniques/       8 narrative techniques for story construction
      phase-workflows/            Phase-based workflow guidance (12 workflow files)
        phase-4b-synthesis-corporate-visions.md
        phase-4b-synthesis-technology-futures.md
        phase-4b-synthesis-competitive-intelligence.md
        phase-4b-synthesis-strategic-foresight.md
        phase-4b-synthesis-industry-transformation.md
        phase-4b-synthesis-trend-panorama.md
        phase-4b-synthesis-theme-thesis.md
        phase-4b-synthesis-jtbd-portfolio.md
        phase-4b-synthesis-company-credo.md
        phase-4b-synthesis-engagement-model.md
        phase-4b-synthesis-smarter-service.md
      story-arc/                  11 arc framework definitions
        arc-registry.md           Index of all available story arcs
        corporate-visions/        Why Change → Why Now → Why You → Why Pay
        technology-futures/       Emerging → Converging → Possible → Required
        competitive-intelligence/ Landscape → Shifts → Positioning → Implications
        strategic-foresight/      Signals → Scenarios → Strategies → Decisions
        industry-transformation/  Forces → Friction → Evolution → Leadership
        trend-panorama/           Forces → Impact → Horizons → Foundations (TIPS-native, theme-less)
        smarter-service/          Forces → Impact → Horizons → Foundations (TIPS-native, theme-aware sibling)
        theme-thesis/             Investment theme narratives (Corporate Visions arc for themes)
        jtbd-portfolio/           Jobs-to-be-Done portfolio narrative (buyer jobs → solutions)
        company-credo/            Mission → Conviction → Credibility → Promise (About-Us pages)
        engagement-model/         Principles → Process → Partnership → Outcomes (How-We-Work pages)
  narrative-review/               Score narratives against quality gates (0-100, A-F)
    references/
      scoring-rubric.md           Quality gate definitions and thresholds
  narrative-adapt/                Adapt narratives into derivative formats
    references/
      format-templates.md         Executive brief, talking points, one-pager templates

agents/                         3 delegation agents
  narrative-writer.md             Parallel narrative generation across content sets (sonnet)
  narrative-reviewer.md           Quality gate scoring and scorecard generation (sonnet)
  narrative-adapter.md            Parallel format adaptation across narratives (sonnet)

commands/                       3 slash commands
  narrative.md                    /narrative — transform content into arc-driven narrative
  narrative-review.md             /narrative-review — score quality
  narrative-adapt.md              /narrative-adapt — adapt to derivative format
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 3 | narrative, narrative-review, narrative-adapt |
| Agents | 3 | narrative-writer (sonnet), narrative-reviewer (sonnet), narrative-adapter (sonnet) |
| Commands | 3 | narrative, narrative-review, narrative-adapt |

## 11 Story Arc Frameworks

| Arc ID | Element Flow | Best For |
|--------|-------------|----------|
| corporate-visions | Why Change → Why Now → Why You → Why Pay | Sales, B2B market research |
| technology-futures | Emerging → Converging → Possible → Required | Innovation, R&D, technology trends |
| competitive-intelligence | Landscape → Shifts → Positioning → Implications | Competitive analysis, threat assessment |
| strategic-foresight | Signals → Scenarios → Strategies → Decisions | Long-range planning, scenario analysis |
| industry-transformation | Forces → Friction → Evolution → Leadership | Industry analysis, regulatory impact |
| trend-panorama | Forces → Impact → Horizons → Foundations | TIPS trend-scout output (theme-less, Trendradar-native) |
| smarter-service | Forces → Impact → Horizons → Foundations | TIPS reports with investment themes (theme-aware sibling of trend-panorama) |
| theme-thesis | Why Change → Why Now → Why You → Why Pay | Investment theme narratives within TIPS reports |
| jtbd-portfolio | Jobs → Friction → Portfolio → Invitation | Portfolio introductions, capability overviews, pre-sales |
| company-credo | Mission → Conviction → Credibility → Promise | Website About-Us pages, company introductions |
| engagement-model | Principles → Process → Partnership → Outcomes | Website How-We-Work pages, engagement sections of proposals |

Arc auto-detection: the narrative skill analyzes input content structure and proposes the best-fit arc. User can override with `--arc {arc-id}`.

## Pipeline Position

```
cogni-knowledge → cogni-narrative → cogni-copywriting → cogni-visual
  (research)        (compose)         (polish)           (visualize)
```

- **Upstream**: Research syntheses from cogni-knowledge (inverted-pipeline output; legacy cogni-research projects still work via the same `.metadata/` arc probe); TIPS dimension data from cogni-trends
- **Citation bridge**: `bridge-citations.py` converts `[Source: Publisher](URL)` inline citations into per-source markdown files before Phase 1 loads them
- **Downstream**: cogni-copywriting detects `arc_id` frontmatter and applies arc-aware polishing; cogni-visual transforms narratives into slides, journey maps, web pages, storyboards

## Key Conventions

- Output is `insight-summary.md` with YAML frontmatter containing `arc_id`, `arc_display_name`, and element metadata
- Target length controlled via `--target-length` parameter (default ~1,675 words) with section proportions preserved
- Each arc has a dedicated phase-4b synthesis workflow file defining element-specific writing rules
- Quality scoring: 4 dimensions (structural compliance, critical accuracy, evidence density, language) → composite 0-100 score with A-F grade
- Bilingual EN/DE: localized section headers and proper Unicode handling
- Derivative formats preserve arc structure — executive briefs condense proportionally, not by cutting sections
