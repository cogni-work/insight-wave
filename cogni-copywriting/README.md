# cogni-copywriting

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A [Claude Cowork](https://claude.ai/cowork) plugin that turns AI-generated drafts into executive-ready documents. Seven messaging frameworks, five parallel stakeholder personas for blind-spot review, bilingual readability validation (English Flesch, German Amstad + Wolf Schneider), and Power Positions sales enhancement — while preserving upstream story arc structure from cogni-narrative. A `copy-json` adapter polishes text fields inside JSON files, and `audit-copywriter` verifies arc contracts stay in sync with cogni-narrative upstream.

## Why this exists

AI-generated content reads like AI-generated content — competent but generic, wordy, and structurally flat. Executive readers have no patience for it:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Buried conclusions | Reports lead with background instead of the bottom line | Executives stop reading after the first paragraph |
| Stakeholder blind spots | Writers optimize for one audience, miss others | Legal flags risks post-publish; technical reviewers find errors too late |
| Inconsistent tone | Different documents from the same team sound like different companies | Brand dilution and reduced credibility |
| Passive, academic voice | AI output defaults to hedged, passive construction | Weak recommendations that don't drive decisions |

This plugin applies structured messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB) and runs parallel stakeholder personas to catch blind spots — so documents are clear, actionable, and audience-tested before they ship.

## What it is

A professional editing toolkit for the insight-wave ecosystem. Seven messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid) handle structure and tone, with Power Positions (IS/DOES/MEANS) available as a sales-mode enhancement. Five stakeholder personas (executive, technical, legal, marketing, end-user) simulate reader reactions in parallel. When paired with cogni-narrative, it detects story arc frontmatter and applies element-specific techniques — polishing without breaking narrative structure.

## What it does

1. **Polish** documents with messaging frameworks — structure (Pyramid Principle), tone (executive active voice), visual hierarchy, and readability scoring
2. **Review** with 5 parallel stakeholder personas (executive, technical, legal, marketing, end-user) — synthesize feedback, detect blind spots, auto-apply improvements
3. **Scope** to a single dimension — tone only, structure only, or formatting only
4. **Preserve arcs** — when paired with cogni-narrative, detects story arc frontmatter and applies element-specific techniques without breaking arc structure
5. **Polish JSON** — extract and polish text fields inside structured JSON files (plugin descriptions, propositions, category names) via the copy-json adapter
6. **Audit** arc-preservation references against upstream cogni-narrative definitions — detect missing arcs, heading mismatches, technique inconsistencies

## What it means for you

- **Ship executive-ready documents in one pass** instead of 3-4 editing rounds — BLUF framing, Pyramid structure, active voice, and visual hierarchy applied together, not piecemeal.
- **Stress-test with 5 parallel personas** to catch what a single reviewer misses — legal risks, technical gaps, marketing opportunities surfaced before the document leaves your desk.
- **Protect your narrative investment.** Arc-aware polishing detects story arc structure and applies element-specific techniques — so a document that took cogni-narrative 30 minutes to compose doesn't lose its persuasive spine during editing.
- **Publish in both markets without a second editing cycle.** English uses Flesch scoring (target 50-60); German uses Wolf Schneider rules with Amstad scoring (target 30-50) — eliminating the separate localization review that typically adds 1-2 days per document.

## Install

Part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave). See the [install guide](../cogni-docs/references/Claude%20Code%20desktop.md) for the full setup walkthrough.

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
| `copy-reader` | skill | Multi-stakeholder review — 5 parallel personas with cross-persona synthesis, blind spot detection, and auto-improvement |
| `copy-json` | skill | Adapter that polishes text fields inside JSON files by delegating to copywriter |
| `audit-copywriter` | skill | Audit arc-preservation references against cogni-narrative upstream definitions |
| `copywriter` | agent (opus) | Delegation agent for parallel document polishing tasks |
| `reader` | agent (sonnet) | Delegation agent for parallel stakeholder review tasks |
| `/copywrite` | command | Polish a document with messaging frameworks and readability optimization |
| `/review-doc` | command | Run parallel stakeholder personas, synthesize feedback, auto-apply improvements |

## Architecture

```
cogni-copywriting/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       4 copywriting skills
│   ├── copywriter/
│   ├── copy-reader/
│   ├── copy-json/
│   └── audit-copywriter/
├── agents/                       2 delegation agents
│   ├── copywriter.md
│   └── reader.md
├── commands/                     2 slash commands
│   ├── copywrite.md
│   └── review-doc.md
└── copywriter-workspace/         Evaluation and iteration workspace
    ├── evals/
    ├── iteration-1/
    └── test-docs/
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | No | Arc-aware polishing — detects `arc_id` frontmatter and applies element-specific techniques |

cogni-copywriting is standalone. It's consumed by cogni-sales, cogni-marketing, and cogni-research as an optional polish step.

## Contributing

Contributions welcome — new messaging frameworks, persona definitions, language rules, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need custom messaging frameworks, house style integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
