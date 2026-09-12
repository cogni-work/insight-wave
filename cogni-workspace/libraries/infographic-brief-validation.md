---
library_id: infographic-brief-validation
version: 1.0.0
created: 2026-09-07
---

# Validation Checklist

Four-layer validation for infographic briefs. Layer 1 is mechanized; Layers 2–4 are reasoned through with the shared rules in `$CLAUDE_PLUGIN_ROOT/libraries/brief-validation-core.md` (§ Core principle, § Severity, § Protocol) and only the infographic-specific rules kept here. Stop on the first failure, fix, then re-check.

---

## Layer 1: Schema Validation

Run the checker and fix every `fail` before reading further:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/check-brief.py" --type infographic "{brief_path}"
```

It enforces the core: frontmatter present with the shared keys (`fm-core-keys`), `type: infographic-brief` with a version the dispatcher accepts and one the brief's own rendering family can render (`fm-type-version` — `"1.2"` for the editorial family, `"1.1"` for the hand-drawn `sketchnote` and `whiteboard` presets, whose agents accept `"1.0"` and `"1.1"` only), `## Block N:` units numbered without gaps and each one fenced, the fixed `## Title Block`, `## CTA Block` and `## Footer Block` present (`unit-numbering`, `unit-fenced`), and no styling field at any depth — `Background`, `Text-Color`, `Icon-Color`, `Role`, `Intensity`, `Mood`, `Fill`, `Border-Color` (`no-color-fields`). A missing `## Generation Metadata` block is a `warn` (`metadata-block`).

Then verify the infographic-specific structure by eye:

| Check | Pass | Fail |
|-------|------|------|
| Required frontmatter fields | All present: theme, theme_path, language, layout_type, style_preset, orientation, dimensions, governing_thought | Any missing |
| Block types valid | Every `Block-Type` is one of: title, kpi-card, stat-row, chart, process-strip, text-block, comparison-pair, icon-grid, svg-diagram, pull-quote, cta, footer | Unknown block type |
| Required block fields | Each block has all required fields per infographic-layouts.md | Missing required field |
| Exactly one title block | Count of title blocks = 1 | 0 or 2+ title blocks |
| Exactly one footer block | Count of footer blocks = 1 | 0 or 2+ footer blocks |
| Layout type match | Blocks match the layout type's required/optional list from infographic-layouts.md | Required block missing or forbidden block present |

---

## Layer 2: Content Density

Infographics fail when they are overloaded. The first two limits derive from the active
`style_preset`'s scan/read target — a 10-second scan for the standard presets, a 60-second
read for `economist` — so both resolve from the Content Density table in
`infographic-style-presets.md`. Every remaining row is a fixed per-block-type cap that does not vary
by preset.

| Check | Pass | Fail |
|-------|------|------|
| Content block count | At least 3 blocks and within the active `style_preset`'s max (Content Density table, `infographic-style-presets.md`), excluding title, CTA, footer | < 3 (too sparse) or over the preset's max (overloaded) |
| Total word count | Within the active `style_preset`'s max word count (Content Density table) | Over the preset's max |
| KPI card word limit | Each kpi-card <= 15 words (excl. number and source) | Any kpi-card over 15 words |
| Text block body limit | Each text-block body <= 40 words | Any body over 40 words |
| Text block headline limit | Each text-block headline <= 8 words | Any headline over 8 words |
| Title headline limit | Title headline <= 12 words | Over 12 words |
| Stat row per stat | Each stat label <= 4 words | Any label over 4 words |
| Process strip per step | Each step label <= 3 words | Any label over 3 words |
| Comparison bullets | Each bullet <= 6 words | Any bullet over 6 words |
| Chart count | 0-2 chart blocks | 3+ charts |
| Number count | Total distinct numbers on page <= 5 (KPI + stat-row + chart labels don't count toward this — only hero numbers and inline numbers) | > 5 inline numbers |

---

## Layer 3: Data Integrity

Read `brief-validation-core.md` § Source preservation and § Language consistency — every number traces to the source, no claim the source does not support, no fabricated URL, one language throughout with real umlauts and German number formatting. Infographic-specific:

| Check | Pass | Fail |
|-------|------|------|
| Chart data valid | Chart data arrays have matching lengths (labels.length == values.length per dataset) | Mismatched array lengths |
| Source line present | Footer includes Source-Line with at least one source | No source attribution |

---

## Layer 4: Distillation Quality

The hardest layer — it evaluates whether the distillation was effective, not just correct. Read `brief-validation-core.md` § Assertion headlines and § Number plays for the title and the hero number; infographic-specific:

| Check | Pass | Fail |
|-------|------|------|
| Title is assertion | Title headline contains a verb and a consequence | Topic label without verb |
| Hero number isolated | At least 1 kpi-card with a prominent hero number | No kpi-card, or hero number buried in text |
| Icon prompts specific | Every Icon-Prompt describes a specific visual concept (object + detail) | Vague prompts ("icon", "business", "good") |
| 10-second scan test | Title + hero number + 2-3 supporting blocks convey the message | Message requires reading all blocks to understand |
| No text walls | No block has more than 3 consecutive sentences | A block with 4+ sentences |
| Structural parallelism | comparison-pair bullets are parallel; icon-grid items are parallel | Mixed grammatical forms within a parallel structure |
| CTA is actionable | CTA uses imperative verb + specific outcome | Vague CTA ("Mehr erfahren") or no CTA |

---

## Validation Protocol

1. Run Layer 1 (the checker, then the structure table). If any fail → fix → re-run Layer 1.
2. Run all Layer 2 checks. If any fail → reduce content → re-run Layers 1-2.
3. Run all Layer 3 checks. If any fail → verify against source → re-run Layers 1-3.
4. Run all Layer 4 checks. If any fail → improve distillation → re-run all layers.

Report validation results as a summary:
```
Validation: Layer 1 ✓ | Layer 2 ✓ | Layer 3 ✓ | Layer 4 ✓
Content blocks: 6/{preset max} | Words: 87/{preset max} | Charts: 1/2 max
```
