# cogni-copywriting

Professional document editing and stakeholder review for the insight-wave ecosystem.

> For the canonical IS/DOES/MEANS positioning and installation instructions, see the [cogni-copywriting README](../../cogni-copywriting/README.md).

---

## Overview

cogni-copywriting is the polish layer in the insight-wave pipeline. After research is gathered and a narrative is shaped, this plugin refines the prose so it lands with the intended audience. It also runs multi-stakeholder review to catch blind spots before a document ships.

The plugin applies structured messaging frameworks rather than improvised editing. Each framework has a defined effect: Pyramid Principle restructures argument hierarchy; BLUF surfaces the conclusion before context; SCQA (Situation-Complication-Question-Answer) organises persuasive briefs; STAR and PSB handle case studies and problem-solution framing. You choose a framework, or let the skill infer one from document type.

Arc-aware mode makes this plugin particularly useful downstream of cogni-narrative. When `insight-summary.md` carries an `arc_id` in its YAML frontmatter, cogni-copywriting detects the arc and applies element-specific techniques — ratio framing for Why Change, forcing functions for Why Now — without breaking the section structure that the narrative skill produced.

### When to reach for this plugin

- A document is technically correct but reads as academic, passive, or generic
- You want multi-stakeholder feedback (executive, legal, technical, marketing, end-user) before distribution
- You need to polish JSON text fields — plugin descriptions, IS/DOES/MEANS propositions, category names
- You want to verify that cogni-copywriting's arc-preservation references are still in sync with a new version of cogni-narrative

---

## Key Concepts

### Messaging frameworks

cogni-copywriting applies one primary framework per document pass. The skill detects the document type and recommends a framework, or you specify one.

| Framework | What it does | Best for |
|-----------|-------------|---------|
| BLUF (Bottom Line Up Front) | Moves the conclusion to the first sentence | Executive memos; status updates |
| Pyramid Principle | Structures argument from conclusion → supporting points → detail | Reports; proposals; strategy documents |
| SCQA | Organises as Situation → Complication → Question → Answer | Persuasive briefs; problem statements |
| STAR | Structures as Situation → Task → Action → Result | Case studies; proof points |
| PSB | Structures as Problem → Solution → Benefit | One-pagers; pitch supporting text |
| FAB | Structures as Feature → Advantage → Benefit | Product descriptions; sales sheets |
| Power Positions | Applies impact openers, active voice, concrete specifics | Any document where energy is low |

### Stakeholder personas

The copy-reader skill runs five parallel reader perspectives. Each persona applies a distinct evaluation lens:

| Persona | Focus |
|---------|-------|
| Executive | Decision relevance; clarity; length; BLUF compliance |
| Technical | Accuracy; specificity; technical claims; scope gaps |
| Legal | Risk statements; liability language; regulatory claims |
| Marketing | Brand voice; message consistency; opportunity framing |
| End-user | Clarity for practitioners; jargon; actionability |

The skill synthesises cross-persona feedback into a prioritised list and flags blind spots where only one persona raised an issue.

### Arc-aware mode

When the source file has `arc_id:` in its YAML frontmatter, cogni-copywriting switches to arc-preservation mode. In this mode:

- Each arc element is polished with techniques tuned to its rhetorical role (e.g., ratio framing in Why Change; forcing functions in Why Now)
- Section headings are not restructured — the arc's H2 hierarchy is protected
- Citations are preserved exactly — no marker is removed or reformatted

Arc-aware mode activates automatically. No extra parameter is needed.

### Language support

| Language | Readability metric | Style rules | Target score |
|----------|--------------------|-------------|-------------|
| English | Flesch Reading Ease | Messaging frameworks + active voice + visual hierarchy | 50-60 |
| German | Amstad | Wolf Schneider (Satzklammer, Mittelfeld, Floskeln, Rhythmus, and three more) | 30-50 |

German is auto-detected from document content. You can also pass `--language de` explicitly.

---

## Getting Started

The recommended first use is a full polish pass on a finished document:

```
/copywrite quarterly-report.md
```

Expected output: the skill reads the document, identifies its type (report), applies Pyramid Principle structure and active voice transformation, adds visual hierarchy (bolded lead sentences, subheadings where absent), and reports a readability score before and after. The polished document is written back to the same path, or a new path if you specify `--output`.

Then run a stakeholder review:

```
/review-doc quarterly-report.md
```

The five personas read the polished document in parallel. You receive a consolidated feedback section with cross-persona synthesis and three ranked improvement actions. If you run without `--no-improve`, the skill applies the improvements automatically.

---

## Capabilities

### copywriter — Polish documents with messaging frameworks

Applies one or more messaging frameworks to a business document, transforms passive voice to active, adds visual hierarchy, and calculates readability scores.

**Example prompt:**
```
/copywrite research-paper.md --scope=tone
```

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `--scope` | `full` (default), `tone`, `structure`, or `formatting` |
| `--framework` | Override framework selection: `bluf`, `pyramid`, `scqa`, `star`, `psb`, `fab` |
| `--language` | `en` or `de` (auto-detected if omitted) |
| `--output` | Write to a different path instead of overwriting |

Scope options let you make a targeted pass without touching everything:

- `--scope=tone` — transforms passive, academic voice to direct executive language; leaves structure and formatting unchanged
- `--scope=structure` — McKinsey Pyramid restructure only; leaves voice unchanged
- `--scope=formatting` — adds visual hierarchy (bold leads, subheadings) only

### copy-reader — Multi-stakeholder document review

Runs five parallel personas against a document, synthesises cross-persona feedback, detects blind spots, and optionally applies improvements.

**Example prompt:**
```
/review-doc proposal.md --no-improve
```

When `--no-improve` is omitted, the skill applies the synthesised improvements automatically and saves the updated file. Use `--no-improve` when you want to review feedback before deciding what to act on.

You can also constrain to specific personas:

```
Run a stakeholder review on this document, but only the executive and legal personas
```

### copy-json — Polish text fields inside JSON files

An adapter that extracts string fields from a JSON file, delegates them to the copywriter skill, and writes the polished text back. Useful for marketplace.json, plugin.json descriptions, and IS/DOES/MEANS proposition fields.

**Example prompt:**
```
Polish the description fields in marketplace.json
```

Or via command with dot-path field selection:

```
/copywrite marketplace.json --fields "plugins[*].description"
```

The `--mode sales` flag activates IS/DOES/MEANS framing for proposition fields specifically.

### audit-copywriter — Verify arc-preservation references against cogni-narrative

Checks that cogni-copywriting's arc-preservation references (`arc-preservation.md`, `arc-technique-map.md`, `00-index.md`) match the current arc definitions in cogni-narrative. Detects heading mismatches, missing arcs, technique inconsistencies, and word target drift.

**Example prompt:**
```
Check if cogni-copywriting arc references are in sync with cogni-narrative
```

This skill is read-only — it produces a drift report but never auto-fixes. Useful to run after a cogni-narrative version bump that adds or renames arcs.

---

## Integration Points

### Upstream inputs

| Plugin / source | What cogni-copywriting receives |
|-----------------|--------------------------------|
| cogni-narrative | `insight-summary.md` with `arc_id` frontmatter — triggers arc-aware polishing mode |
| cogni-knowledge | Syntheses and research reports for polish before client distribution |
| cogni-marketing | Generated content pieces for a final editorial pass |
| cogni-sales | Sales presentations and proposals for executive voice polish |
| Plain documents | Any markdown or text file — cogni-copywriting works standalone |

### Downstream consumers

| Plugin | How it uses cogni-copywriting output |
|--------|-------------------------------------|
| cogni-visual | Polished narratives render more cleanly into slide decks and web pages |
| cogni-sales | Calls cogni-copywriting as an optional final step on `sales-presentation.md` |
| cogni-marketing | Calls cogni-copywriting to polish generated content before publication |

---

## Common Workflows

### Full editorial pipeline: polish then review

The standard sequence for any document that will be distributed to executives or clients:

1. `/copywrite ./document.md` — apply frameworks, fix voice, add hierarchy
2. `/review-doc ./document.md` — five-persona review, auto-apply improvements
3. Review the readability score reported after step 1; if below target, run `/copywrite --scope=tone` again

### Arc-aware narrative polish

When working with cogni-narrative output, the sequence integrates naturally:

1. `/narrative ./research-output/` (cogni-narrative) — generates `insight-summary.md` with `arc_id` frontmatter
2. `/copywrite ./insight-summary.md` — arc-aware mode activates automatically; element-specific techniques applied

No extra flags needed. The `arc_id` in frontmatter triggers the preservation mode.

See [../workflows/research-to-narrative.md](../workflows/research-to-narrative.md) for the full research-to-polished-narrative pipeline.

### German document editing

For DACH market documents:

1. `/copywrite ./bericht.md` — German auto-detected; Wolf Schneider rules applied (Satzklammer broken, Mittelfeld shortened, Floskeln removed)
2. The skill reports an Amstad score (target 30-50) and flags sentences that still fail readability thresholds

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| Citations removed after polishing | Copywriter scope was set too aggressively | Check the output diff; restore citation markers; the skill should never remove `[P1-1](url)` style markers — file a bug if it does |
| Arc headings restructured | `arc_id` frontmatter missing from source file | Add `arc_id: {arc-id}` to the YAML frontmatter block before running copywrite |
| German text converted to ASCII (ae, oe, ue) | Language detected as English | Pass `--language de` explicitly |
| Readability score unchanged after full pass | Document is already well-structured; or scope was `tone` only | Check whether `--scope=structure` also needs to run |
| copy-json writes malformed JSON | Field path selector incorrect | Verify dot-path syntax: `plugins[*].description` not `plugins.description`; use `--dry-run` to preview before writing |
| audit-copywriter reports many drift items | cogni-narrative recently updated arcs | Read the drift report, then manually update the three reference files listed; do not auto-fix |
| Stakeholder review personas give conflicting advice | Normal — personas have different priorities | The synthesis section at the top of the review output shows which conflicts are genuine tradeoffs vs. solvable issues |

---

## Extending This Plugin

Contribution areas with the most impact:

- **New messaging frameworks** — Add a framework entry to `skills/copywriter/references/` and update the framework selection logic in the copywriter SKILL.md
- **New stakeholder personas** — Add a persona definition in `skills/copy-reader/references/`; the parallel review runs as many personas as are defined
- **Additional language rules** — Extend `skills/copywriter/references/` with style rule files for languages beyond EN/DE
- **Arc-preservation references** — When adding new arcs to cogni-narrative, run `audit-copywriter` to identify what needs updating in cogni-copywriting's reference files

See [../../CONTRIBUTING.md](../../CONTRIBUTING.md) and [../../cogni-copywriting/CONTRIBUTING.md](../../cogni-copywriting/CONTRIBUTING.md) for contribution guidelines.
