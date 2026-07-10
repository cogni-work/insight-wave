# cogni-copywriting

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The polish layer of the insight-wave pipeline — a Claude Code toolkit that refines AI-generated drafts into executive-ready documents on the McKinsey Pyramid Principle and messaging frameworks.

## Why this exists

AI-generated content reads like AI-generated content — competent but generic, wordy, and structurally flat. Executive readers have no patience for it, and the cost lands after the document has already gone out:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Buried conclusions | Reports lead with background instead of the bottom line | Executives stop reading after the first paragraph |
| Stakeholder blind spots | Writers optimize for one audience, miss others | Legal flags risks post-publish; technical reviewers find errors too late |
| Inconsistent tone | Different documents from the same team sound like different companies | Brand dilutes and credibility erodes |
| Passive, academic voice | AI output defaults to hedged, passive construction | Weak recommendations that don't drive decisions |
| Manual localization | German and English versions are edited in separate review cycles | One to two days added per document before it can ship |

A polished first draft is the difference between a document a decision-maker acts on and one that stalls in review — and the cost compounds across every report, brief, and proposal a team puts out.

## What it is

A document-polishing engine built on the McKinsey Pyramid Principle and a library of structured messaging frameworks, with multilingual readability scoring at its core. It sits at the polish stage of the insight-wave pipeline: cogni-knowledge researches and cogni-narrative composes, then this layer turns the draft into a clear, audience-tested, executive-ready document — preserving any story-arc structure inherited from upstream rather than flattening it.

## What it does

1. **Polish** documents with messaging frameworks — structure (Pyramid Principle), tone (executive active voice), visual hierarchy, and readability scoring
2. **Review** with 5 parallel stakeholder personas (executive, technical, legal, marketing, end-user) — synthesize feedback, detect blind spots, auto-apply improvements
3. **Scope** to a single dimension — tone only, structure only, or formatting only
4. **Preserve arcs** — when paired with cogni-narrative, detects story arc frontmatter and applies element-specific techniques without breaking arc structure
5. **Polish JSON** — extract and polish text fields inside structured JSON files (plugin descriptions, propositions, category names) via the copy-json adapter
6. **Audit** arc-preservation references against upstream cogni-narrative definitions — detect missing arcs, heading mismatches, technique inconsistencies
7. **Translate** across DE/EN/FR/IT/PL/NL/ES (pivoting on EN or DE) — translates first, then applies target-language style discipline (Wolf-Schneider for DE, Flesch-family readability for the others), preserving citations, frontmatter technical IDs, and protected content byte-identical

## What it means for you

- **Ship executive-ready in one pass.** Bottom-line framing, Pyramid structure, active voice, and visual hierarchy applied together replace the usual 3-4 editing rounds.
- **Catch what one reviewer misses.** Five parallel stakeholder personas surface legal risks, technical gaps, and marketing opportunities before the document leaves your desk — not after.
- **Protect your narrative investment.** Arc-aware polishing preserves story-arc structure, so a document cogni-narrative spent time composing keeps its persuasive spine through editing.
- **Publish in both markets without a second cycle.** English scores on Flesch (target 50-60) and German on Amstad with Wolf Schneider rules (target 30-50), eliminating the separate localization review that adds 1-2 days per document.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/copywrite quarterly-report.md              # full polish
/copywrite research-paper.md --scope=tone   # tone only
/copywrite product-overview.md --translate=de  # translate EN→DE and polish
/review-doc quarterly-report.md             # stakeholder review + auto-apply
/review-doc proposal.md --no-improve        # feedback only, no changes
```

Or describe what you want:

- "Polish this document for executive readability"
- "Run a stakeholder review on the proposal"
- "Just fix the tone — leave structure alone"
- "Review with only the executive and legal personas"

## Try it

Point the copywriter at a draft and run it:

> Run `/copywrite quarterly-report.md`

The copywriter detects the document type, applies the matching messaging framework, transforms passive voice to active, adds visual hierarchy, and scores the result. The original is backed up to `.quarterly-report.md`, and the polished version overwrites the input. You'll see a summary like:

```
quarterly-report.md — polished
  Framework: Pyramid (answer-first)
  Active voice: 84% (was 41%)
  Readability: Flesch 56 (target 50-60)
  Backup: .quarterly-report.md
```

Then stress-test it with the stakeholder review:

> Run `/review-doc quarterly-report.md`

Five personas — executive, technical, legal, marketing, end-user — read the document in parallel, raise their questions, and the synthesized CRITICAL and HIGH findings are auto-applied. Want feedback without edits? Add `--no-improve`. Polishing only one dimension? Scope it: `/copywrite quarterly-report.md --scope=tone` leaves structure and formatting untouched.

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

Arc documents can also be translated across all seven languages — `/copywrite arc-narrative.md --translate=fr` (or `de`/`it`/`pl`/`nl`/`es`) swaps the arc-element and bridge headings to that language's canonical set while preserving structure, citations, and arc contract (supported for the `corporate-visions` and `jtbd-portfolio` arcs; every direction still pivots on EN or DE).

### German Documents

Detects German language automatically, loads Wolf Schneider style rules — breaks Satzklammer, shortens Mittelfeld, eliminates Floskeln. Validates with Amstad readability score.

## Language support

| Language | Readability | Style Rules | Target Score | Translation |
|----------|-------------|-------------|--------------|-------------|
| English | Flesch Reading Ease | Messaging frameworks, active voice, visual hierarchy | 50-60 | via EN/DE pivot — `--translate=en` |
| German | Amstad | Wolf Schneider (7 rules: Satzklammer, Mittelfeld, Floskeln, Rhythmus, etc.) | 30-50 | via EN/DE pivot — `--translate=de` |
| French | Kandel-Moles | Vouvoiement, active voice, de-phrases | 50-60 (aspirational) | via EN/DE pivot — `--translate=fr` |
| Italian | Flesch-Vacca | Lei courtesy form, di-phrases, accents | 50-60 (aspirational) | via EN/DE pivot — `--translate=it` |
| Polish | generic-Flesch fallback | Pan/Pani, ą/ć/ę/ł/ń/ó/ś/ź/ż, case agreement | 50-60 (aspirational) | via EN/DE pivot — `--translate=pl` |
| Dutch | Flesch-Douma | U-vorm, closed compounds, V2 order | 50-60 (aspirational) | via EN/DE pivot — `--translate=nl` |
| Spanish | Szigriszt-Pazos | Usted, accents + ñ, inverted ¿¡ | 50-60 (aspirational) | via EN/DE pivot — `--translate=es` |

Translation runs as a two-pass translate-then-polish flow: Pass A transfers meaning (preserving citations, URLs, frontmatter technical IDs, and protected content byte-identical); Pass B applies the target-language style discipline above. Every direction pivots on EN or DE — direct non-EN/DE pairs (e.g. fr→it) are rejected. For the five additional languages the absolute Flesch-family band is aspirational; the translation validator enforces a relative-to-source rule on the same target-language scale. Non-arc FR/IT/PL/NL/ES translation ships now (#255 Slice 1), and arc-mode translation ships across **all seven languages** for the `corporate-visions` and `jtbd-portfolio` arcs (#255 Slices 2–3) — arc-element and bridge headings are substituted from cogni-narrative's canonical heading set rather than freely translated. Broader arc coverage (the other 9 arcs) remains future work; direct non-EN/DE pairs are rejected.

## How it works

Polishing runs as a five-step sequential pipeline, and the order is the point. Step 1 parses parameters and reads `references/00-index.md`, a decision tree that detects the mode — standard, arc, or sales — and loads exactly the references that mode needs rather than every framework at once. Step 2 applies the structural framework (Pyramid, BLUF, SCQA, and the rest), because a document's skeleton has to be right before its prose is worth refining. Step 3 does the line-level work: voice transformation to active, sentence and paragraph splitting, bold anchoring, visual rhythm, and audience-tuned acronym expansion. Step 4 runs the optional stakeholder review but never blocks delivery. Step 5 validates and writes — German characters preserved, citation count intact, readability scored — after backing up the original.

Structure precedes prose for a reason: reordering an argument after it has been word-smithed wastes the polish, so the framework is applied first and the sentence-level discipline second. Arc mode inverts only the structural step — when cogni-narrative frontmatter carries an `arc_id`, the arc *is* the structure, so Step 2 is skipped and element-specific techniques replace the generic framework, keeping the inherited story arc intact. Translation runs as a translate-then-polish two-pass flow that pivots on English or German, transferring meaning first and applying target-language style discipline second, so localization and polish never fight each other. The `audit-copywriter` skill keeps the arc-preservation contract in sync with cogni-narrative upstream so that arc-aware polishing never drifts from the definitions it depends on.

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
    ├── test-docs/
    └── test-fixtures/
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-narrative | No | Arc-aware polishing — detects `arc_id` frontmatter and applies element-specific techniques |

cogni-copywriting is standalone. It's consumed by cogni-sales, cogni-marketing, and cogni-knowledge as an optional polish step.

## Contributing

Contributions welcome — new messaging frameworks, persona definitions, language rules, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom messaging framework, your house style baked into the polish rules, an extra target language, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation for teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
