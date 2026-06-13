# cogni-narrative

Story arc-driven narrative transformation for the insight-wave ecosystem.

> For the canonical IS/DOES/MEANS positioning and installation instructions, see the [cogni-narrative README](../../cogni-narrative/README.md).

---

## Overview

cogni-narrative sits in the composition layer of the insight-wave pipeline: after research is collected and before content is polished or visualised. Its job is to impose narrative structure on unstructured input — research syntheses, analyses, TIPS trend reports, competitive landscapes — so the output reads as a deliberate argument rather than an information dump.

The plugin provides ten story arc frameworks. Each framework is a sequence of named elements (for example: Why Change → Why Now → Why You → Why Pay) with defined rhetorical intent, evidence requirements, and transition patterns between elements. When you run `/narrative`, the skill reads your source files, proposes the best-fit arc, and writes a ~1,675-word insight summary structured around it. The output file (`insight-summary.md`) carries YAML frontmatter with an `arc_id` field that downstream plugins (cogni-copywriting, cogni-visual) use to apply arc-aware processing.

### When to reach for this plugin

- You have a research report, competitive analysis, or trend output and need to turn it into an executive presentation or briefing
- You need a narrative that can be derived into multiple formats (executive brief, talking points, one-pager) without manual rewriting
- You want automated quality scoring before an insight summary ships to a client or executive audience
- A team member wrote a narrative and you want a structured critique with improvement guidance

---

## Key Concepts

### Story arc frameworks

An arc framework defines the shape of an argument. Rather than writing a narrative from scratch, you select (or let the skill auto-detect) a framework whose rhetorical progression matches your content and audience.

| Arc ID | Element sequence | Use when |
|--------|-----------------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Pitching a solution to a buyer; sales enablement; B2B market research |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation scouting; R&D strategy; technology trend reports |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis; market monitoring; threat assessment |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning; scenario analysis; strategic options |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry analysis; regulatory impact; transformation roadmaps |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | TIPS trend-scout output; Trendradar-native reports |
| `theme-thesis` | Why Change → Why Now → Why You → Why Pay | Investment theme narratives within TIPS reports |
| `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation | Portfolio introductions; capability overviews; pre-sales |
| `company-credo` | Mission → Conviction → Credibility → Promise | Website About-Us pages; company introductions |
| `engagement-model` | Principles → Process → Partnership → Outcomes | Website How-We-Work pages; engagement sections of proposals |

### Arc auto-detection

When you do not specify an arc, the narrative skill reads your source files and infers which framework fits best. It then presents its recommendation and asks you to confirm or override before generating. Override with `--arc {arc-id}` if the auto-detected choice is wrong.

### Quality dimensions

The narrative-review skill evaluates output across four dimensions:

| Dimension | What it checks |
|-----------|----------------|
| Structural compliance | Correct number of arc element sections; presence of required headings |
| Critical accuracy | No unsupported claims; evidence tied to named sources |
| Evidence density | Adequate citation coverage per element; no element left without proof |
| Language | Readability score (Flesch for EN, Amstad for DE); passive voice ratio; sentence length |

Each dimension produces a pass/warn/fail gate. The composite score (0-100, A-F grade) appears in the scorecard header.

### Derivative formats

A full narrative (~1,675 words) is the source from which three derivative formats are condensed without rewriting from scratch:

| Format | Length | Use for |
|--------|--------|---------|
| `executive-brief` | 300-500 words | Email; internal messaging; pre-read before a meeting |
| `talking-points` | Bullet list | Verbal briefing; slide speaker notes |
| `one-pager` | Structured page | Print-ready reference; leave-behind |

Condensation preserves the arc's proportional structure — elements are compressed equally rather than sections being cut.

---

## Getting Started

The fastest first use is to point the skill at a directory of markdown research files:

```
/narrative ./research-output/
```

Expected interaction:

1. The skill scans the source directory and reads all `.md` files
2. It identifies the arc that best fits the content type and presents its choice: "Auto-detected arc: `technology-futures`. Reason: source files contain innovation scouting data with horizon references. Confirm, or override with another arc?"
3. You confirm (or type an alternative arc ID)
4. The skill generates `insight-summary.md` in the source directory — a ~1,675-word narrative structured around the selected arc, with inline citations back to source files

You can also give it a natural-language instruction:

```
Transform this research into an executive narrative
```

Claude reads the files in context, runs the same arc-detection process, and proceeds.

---

## Capabilities

### narrative — Transform content into an arc-driven narrative

Reads source markdown files, auto-detects or applies a specified arc framework, and generates a structured executive narrative with inline citations.

**Example prompt:**
```
/narrative ./analysis/ --arc competitive-intelligence -o output/narrative.md
```

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `--source-path` | Directory of `.md` files, or a single file |
| `--arc-id` | Override auto-detection: `corporate-visions`, `technology-futures`, `competitive-intelligence`, `strategic-foresight`, `industry-transformation`, `trend-panorama`, `theme-thesis`, `jtbd-portfolio`, `company-credo`, `engagement-model` |
| `--language` | `en` (default) or `de` |
| `--output-path` | Defaults to `insight-summary.md` in source directory |
| `--target-length` | Word count (default ~1,675); section proportions scale accordingly |

The output `insight-summary.md` contains YAML frontmatter with `arc_id` and element metadata, which downstream plugins read automatically.

### narrative-review — Score a narrative against quality gates

Evaluates an existing insight summary and produces a scorecard with per-gate results and improvement suggestions.

**Example prompt:**
```
/narrative-review ./insight-summary.md
```

Output: a scorecard block showing pass/warn/fail per gate, composite score (e.g., 78/100, B+), and three ranked improvement actions. Useful as a pre-ship review step before executive distribution.

### narrative-adapt — Derive condensed formats from a full narrative

Adapts an existing narrative into an executive brief, talking points, or one-pager without regenerating from source.

**Example prompt:**
```
/narrative-adapt ./insight-summary.md --format talking-points
```

Or in natural language: "Create talking points from this narrative." The arc structure is preserved in condensed form — the output is not a summary of the narrative, but a proportionally shortened version of each arc element.

---

## Integration Points

### Upstream inputs

| Plugin / source | What cogni-narrative receives |
|-----------------|-------------------------------|
| cogni-knowledge | Syntheses and source markdown files — primary narrative input |
| cogni-trends | TIPS trend-scout output and value-modeler themes — primary input for `trend-panorama` and `theme-thesis` arcs |
| Plain markdown files | Any structured `.md` files — cogni-narrative works standalone without upstream plugins |

### Downstream consumers

| Plugin | How it uses cogni-narrative output |
|--------|-----------------------------------|
| cogni-copywriting | Detects `arc_id` in `insight-summary.md` frontmatter and applies arc-specific polishing techniques (e.g., ratio framing for Why Change; forcing functions for Why Now) |
| cogni-visual | Transforms the narrative into slide decks, journey maps, web pages, and storyboards via `story-to-slides` and related skills |
| cogni-sales | Reads Corporate Visions arc patterns from cogni-narrative to structure `why-change` pitch phases |
| cogni-marketing | Uses long-form narratives as anchor content for thought leadership generation |

---

## Common Workflows

### Research report to executive briefing

This is the most common sequence: research output exists, an executive needs a concise read.

1. Run `/narrative ./research-output/` — confirm arc, receive `insight-summary.md`
2. Run `/narrative-review ./insight-summary.md` — check the quality scorecard; address any warn/fail gates
3. Run `/narrative-adapt ./insight-summary.md --format executive-brief` — produce the 300-500 word email-ready version
4. Optional: run `/copywrite executive-brief.md` (cogni-copywriting) for final polish

See [../workflows/research-to-narrative.md](../workflows/research-to-narrative.md) for the full pipeline.

### Trend report with German output

TIPS trend reports often need German-language output for DACH market teams.

1. Run `/narrative ./tips-output/ --arc trend-panorama --language de`
2. The skill loads German section header templates and Amstad scoring rules
3. Output has localized headings (e.g., "Handlungsfelder" instead of "Foundations") and proper Unicode umlauts
4. Run `/narrative-review ./insight-summary.md` — scoring applies German readability thresholds

### Arc selection guidance

When you are unsure which arc fits your content:

1. Run `/narrative ./content/ --arc ?` or just `/narrative ./content/` and let auto-detection run
2. Review the arc recommendation and reasoning before confirming
3. If the content covers multiple contexts (e.g., competitive landscape with strategic options), choose the primary audience: a sales team gets `corporate-visions`; a strategy committee gets `strategic-foresight`

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| Auto-detected arc is wrong | Source files mix content types | Override with `--arc {arc-id}` explicitly |
| Narrative score below 60 | Evidence density too low — elements lack citations | Add source files with specific evidence; re-run narrative |
| German output has ASCII umlauts (ae, oe) | Language not detected or set to `en` | Pass `--language de` explicitly |
| `insight-summary.md` missing `arc_id` frontmatter | Narrative was written manually, not via this plugin | Add frontmatter block manually: `arc_id: corporate-visions` — cogni-copywriting reads this |
| Derivative format is too long | Source narrative is longer than default (~1,675 words) | Re-run `narrative` with `--target-length 1675` before adapting; or adapt anyway and trim manually |
| narrative-review passes all gates but narrative feels flat | Quality gates check structure, not rhetorical impact | Pipe to `/copywrite --scope tone` (cogni-copywriting) for voice and impact improvement |
| Script error from `bridge-citations.py` | Python 3 not in PATH | Ensure Python 3 is available; the script converts upstream citation formats before narrative reads sources |

---

## Extending This Plugin

cogni-narrative is open for contribution. The most impactful contribution areas:

- **New arc frameworks** — Add a directory under `skills/narrative/references/story-arc/` with an `arc-definition.md` following the existing schema, and a matching `phase-4b-synthesis-{arc-id}.md` workflow file
- **Narrative techniques** — Add technique files under `skills/narrative/references/narrative-techniques/`
- **Language templates** — Extend `skills/narrative/references/language-templates.md` with additional languages or arc-element localisations
- **Quality gate definitions** — Adjust scoring thresholds in `skills/narrative-review/references/scoring-rubric.md`

See [../../CONTRIBUTING.md](../../CONTRIBUTING.md) and [../../cogni-narrative/CONTRIBUTING.md](../../cogni-narrative/CONTRIBUTING.md) for contribution guidelines.
