# cogni-copywriting

Professional copywriting toolkit for [Claude Cowork](https://claude.ai/cowork). Polish documents for executive readability, get multi-stakeholder feedback, and strengthen story arc narratives — in English or German. Applies messaging frameworks, readability standards, and impact techniques so your writing lands.

## Why this exists

AI-generated content reads like AI-generated content — competent but generic, wordy, and structurally flat. Executive readers have no patience for it:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Buried conclusions | Reports lead with background instead of the bottom line | Executives stop reading after the first paragraph |
| Stakeholder blind spots | Writers optimize for one audience, miss others | Legal flags risks post-publish; technical reviewers find errors too late |
| Inconsistent tone | Different documents from the same team sound like different companies | Brand dilution and reduced credibility |
| Passive, academic voice | AI output defaults to hedged, passive construction | Weak recommendations that don't drive decisions |

This plugin applies structured messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB) and runs parallel stakeholder personas to catch blind spots — so documents are clear, actionable, and audience-tested before they ship.

## What it does

1. **Polish** documents with messaging frameworks — structure (Pyramid Principle), tone (executive active voice), visual hierarchy, and readability scoring
2. **Review** with 5 parallel stakeholder personas (executive, technical, legal, marketing, end-user) — synthesize feedback, detect blind spots, auto-apply improvements
3. **Scope** to a single dimension — tone only, structure only, or formatting only
4. **Preserve arcs** — when paired with cogni-narrative, detects story arc frontmatter and applies element-specific techniques without breaking arc structure

## What it means for you

- **Executive-ready in one pass.** BLUF framing, Pyramid structure, active voice, visual hierarchy — applied together, not piecemeal.
- **Multi-stakeholder tested.** 5 parallel personas catch what a single reviewer misses — legal risks, technical gaps, marketing opportunities.
- **Arc-aware.** Detects `arc_id` frontmatter and applies techniques tuned to each arc element (ratio framing for Why Change, forcing functions for Why Now).
- **Bilingual.** English uses Flesch scoring; German uses Wolf Schneider rules with Amstad scoring.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- Python 3 (for readability calculations)
- Optional: **cogni-narrative** (arc-aware polishing when `arc_id` frontmatter is present)

## Quick start

```
/copywrite quarterly-report.md              # full polish
/copywrite research-paper.md --scope=tone   # tone only
/review-doc quarterly-report.md             # stakeholder review + auto-apply
/review-doc proposal.md --no-improve        # feedback only, no changes
```

Or describe what you want:

- "Polish this document for executive readability"
- "Run a stakeholder review on the proposal"
- "Just fix the tone — leave structure alone"
- "Review with only the executive and legal personas"

## Try it

After installing, type one prompt:

> Polish this document for executive readability

Claude reads the document, detects its type, applies the appropriate messaging framework, transforms passive voice to active, adds visual hierarchy, and validates with readability scoring. Then run `/review-doc` to get multi-stakeholder feedback.

## Example workflows

### Polish, Then Review

The recommended sequence: polish first to get the document into shape, then review to validate and catch blind spots.

```
/copywrite quarterly-report.md
/review-doc quarterly-report.md
```

### Scoped Polishing

Focus on one dimension — skip the rest:

- `--scope=tone` — transforms passive academic voice to direct executive language
- `--scope=structure` — McKinsey Pyramid only
- `--scope=formatting` — visual hierarchy only

### Story Arc Polishing

When paired with cogni-narrative, detects `arc_id` in frontmatter and applies arc-specific techniques:

```
/copywrite why-change-narrative.md
```

### German Documents

Detects German language automatically, loads Wolf Schneider style rules — breaks Satzklammer, shortens Mittelfeld, eliminates Floskeln. Validates with Amstad readability score.

## Language support

| Language | Readability | Style Rules | Target Score |
|----------|-------------|-------------|--------------|
| English | Flesch Reading Ease | Messaging frameworks, active voice, visual hierarchy | 50-60 |
| German | Amstad | Wolf Schneider (7 rules: Satzklammer, Mittelfeld, Floskeln, Rhythmus, etc.) | 30-50 |

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `copywriter` | skill | Executive document polishing — 7 messaging frameworks, 9 deliverable types, readability scoring, arc-aware mode, sales enhancement |
| `reader` | skill | Multi-stakeholder review — 5 parallel personas with cross-persona synthesis, blind spot detection, and auto-improvement |
| `copywriter` | agent (sonnet) | Delegation agent for parallel document polishing tasks |
| `reader` | agent (sonnet) | Delegation agent for parallel stakeholder review tasks |
| `/copywrite` | command | Polish a document with messaging frameworks and readability optimization |
| `/review-doc` | command | Run parallel stakeholder personas, synthesize feedback, auto-apply improvements |

## Architecture

```
cogni-copywriting/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       2 copywriting skills
│   ├── copywriter/
│   └── reader/
├── agents/                       2 delegation agents
│   ├── copywriter.md
│   └── reader.md
└── commands/                     2 slash commands
    ├── copywrite.md
    └── review-doc.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | No | Arc-aware polishing — detects `arc_id` frontmatter and applies element-specific techniques |

cogni-copywriting is standalone. It's consumed by cogni-sales, cogni-marketing, and cogni-research as an optional polish step.

## Custom development

Need custom messaging frameworks, house style integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
