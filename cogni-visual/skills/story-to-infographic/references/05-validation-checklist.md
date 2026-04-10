# Validation Checklist

Four-layer validation for infographic briefs. Stop on first failure, fix, then re-check.
Self-assessment is unreliable without explicit measurement — models report "pass" while
producing topic-label headlines and exceeding word limits. These gates force honest evaluation.

---

## Layer 1: Schema Validation

Structural correctness. Every field must exist and conform to its type.

| Check | Pass | Fail |
|-------|------|------|
| Brief frontmatter present | `type: infographic-brief`, `version: "1.0"` | Missing or wrong type/version |
| Required frontmatter fields | All present: theme, theme_path, language, layout_type, style_preset, orientation, dimensions, governing_thought | Any missing |
| Block types valid | Every `Block-Type` is one of: title, kpi-card, stat-row, chart, process-strip, text-block, comparison-pair, icon-grid, svg-diagram, cta, footer | Unknown block type |
| Required block fields | Each block has all required fields per infographic-layouts.md | Missing required field |
| YAML parseable | All fenced YAML blocks parse without errors | Syntax errors |
| No color fields | Zero instances of Background, Text-Color, Icon-Color, Fill, Border-Color | Any color field present |
| Exactly one title block | Count of title blocks = 1 | 0 or 2+ title blocks |
| Exactly one footer block | Count of footer blocks = 1 | 0 or 2+ footer blocks |
| Layout type match | Blocks match the layout type's required/optional list from infographic-layouts.md | Required block missing or forbidden block present |

---

## Layer 2: Content Density

Infographics fail when they're overloaded. These limits are derived from the 10-second scan test.

| Check | Pass | Fail |
|-------|------|------|
| Content block count | 3-8 blocks (excluding title, CTA, footer) | < 3 (too sparse) or > 8 (overloaded) |
| Total word count | Under 150 words across all blocks | Over 150 words |
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

Numbers and claims must trace back to the source narrative. Infographics are shared and cited — fabricated data is a credibility disaster.

| Check | Pass | Fail |
|-------|------|------|
| Numbers match source | Every Hero-Number, stat number, and chart data point appears in or is derivable from the source narrative | A number that doesn't exist in the source |
| Chart data valid | Chart data arrays have matching lengths (labels.length == values.length per dataset) | Mismatched array lengths |
| No fabricated claims | Title assertion is supported by evidence in the source | Assertion claims something the source doesn't support |
| Source line present | Footer includes Source-Line with at least one source | No source attribution |
| Language consistency | All text in the specified language (no mixed-language content) | Mixed languages |
| German formatting | If language=de: umlauts are Unicode (ä not ae), numbers use dot separator (2.661 not 2,661) | ASCII umlauts or comma separators |

---

## Layer 4: Distillation Quality

The hardest layer — it evaluates whether the distillation was effective, not just correct.

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

1. Run all Layer 1 checks. If any fail → fix → re-run Layer 1.
2. Run all Layer 2 checks. If any fail → reduce content → re-run Layers 1-2.
3. Run all Layer 3 checks. If any fail → verify against source → re-run Layers 1-3.
4. Run all Layer 4 checks. If any fail → improve distillation → re-run all layers.

Report validation results as a summary:
```
Validation: Layer 1 ✓ | Layer 2 ✓ | Layer 3 ✓ | Layer 4 ✓
Content blocks: 6/8 max | Words: 87/150 max | Charts: 1/2 max
```
