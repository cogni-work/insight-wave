# cogni-canvas

A [Claude Cowork](https://claude.ai/cowork) plugin for Lean Canvas authoring and refinement — guiding users through creating business model hypotheses with section-by-section critique, multi-persona stress testing, and version tracking.

## Why this exists

Business model canvases are supposed to be fast, falsifiable, and iterable. In practice, they're often filled in once and never challenged:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Founder-story bias | Canvases describe what was built, not why the customer cares | Positioning misses the buyer's pain; pitch decks confuse investors |
| No structured critique | Teams review canvases in unstructured discussions where loudest voice wins | Weak sections survive; assumptions go untested |
| No version history | Canvas evolves through undocumented edits | Teams forget why decisions were made; pivots lose their learning trail |

## What it is

A structured canvas workflow for Claude Cowork. Three skills cover the full lifecycle: create a canvas from scratch through guided Q&A, refine an existing canvas with section-by-section critique, or stress-test it through four stakeholder personas (investor, target customer, technical co-founder, operations & finance).

## What it does

1. **Create** — guided Q&A builds a complete Lean Canvas from a business idea, filling all 9 sections with specific, testable content
2. **Refine** — section-by-section critique identifies weak spots (vague UVP, untestable assumptions, missing cost drivers) and proposes improvements
3. **Stress-test** — four personas interrogate the canvas independently, then a synthesis protocol reconciles their feedback into a composite score and prioritized action list

## What it means for you

- **Get to a testable hypothesis faster.** The guided Q&A forces specificity — "B2B SaaS for HR" becomes a canvas with named segments, quantified problems, and measurable metrics.
- **Challenge your own thinking.** The stress test surfaces blind spots you can't see from the inside — an investor asks about unit economics, a customer asks "why would I switch?"
- **Keep a decision trail.** Every revision records what changed, why, and what assumptions remain to validate. Version 5 still knows what Version 1 got wrong.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

## Quick start

```
canvas-create                              # guided Q&A to build a new Lean Canvas
canvas-refine <path>                       # critique and improve an existing canvas
canvas-stress-test <path>                  # multi-persona stress test
```

Or just describe what you want in natural language:

- "help me create a lean canvas for my B2B SaaS idea"
- "review my canvas and tell me what's weak"
- "stress-test this canvas from an investor's perspective"
- "refine the revenue streams section — I think the pricing model is too vague"

## Try it

After installing, type one prompt:

> Help me create a lean canvas for a B2B platform that helps boutique consulting firms scale their delivery with AI-native workflows

Claude walks you through each section with targeted questions, challenges vague answers, and produces a complete canvas with YAML frontmatter, all 9 sections filled, and an evolution log tracking assumptions to validate.

## Data model

Canvas files are self-contained markdown with YAML frontmatter tracking version and per-section status:

| Entity | Key fields | Description |
|--------|-----------|-------------|
| Canvas file | version, status.{section}, 9 sections, evolution log | Markdown with YAML frontmatter. Status per section: `filled` / `draft` / `unfilled`. Version incremented on substantive changes |

See [references/data-model.md](references/data-model.md) for the full schema and [references/canvas-format.md](references/canvas-format.md) for the file format specification.

## How it works

Canvases are single markdown files with YAML frontmatter for metadata (version, dates, per-section status) and numbered H2 sections for the 9 Lean Canvas fields. An evolution log after the sections records what changed and why across versions. The stress-test skill runs 4 independent persona evaluations (investor, target customer, technical co-founder, operations & finance) and then synthesizes their feedback into a composite score using a structured reconciliation protocol.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `canvas-create` | skill | Guided Q&A to build a new Lean Canvas from scratch |
| `canvas-refine` | skill | Section-by-section critique and improvement of existing canvases |
| `canvas-stress-test` | skill | Multi-persona stress test with composite scoring and synthesis |

## Architecture

```
cogni-canvas/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       3 canvas skills
│   ├── canvas-create/
│   │   └── SKILL.md
│   ├── canvas-refine/
│   │   └── SKILL.md
│   └── canvas-stress-test/
│       ├── SKILL.md
│       └── references/
│           ├── personas/         4 stakeholder personas
│           └── synthesis-protocol.md
└── references/                   Shared format and quality specs
    ├── data-model.md
    ├── canvas-format.md
    └── lean-canvas-sections.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | No | `portfolio-canvas` extracts products, features, and markets from the canvas for downstream messaging |
| cogni-portfolio | No | `markets` and `compete` validate canvas assumptions (TAM/SAM/SOM, competitive landscape) with real data |

cogni-canvas is standalone — it provides full canvas authoring and refinement without any other plugins. Portfolio integration adds data-backed validation.

## Custom development

Need custom canvas types (Business Model Canvas, Value Proposition Canvas), additional stress-test personas, or integration with your planning tools? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
