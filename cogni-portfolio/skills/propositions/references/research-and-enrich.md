# Research, Enrich, and Variants

Procedural detail for two distinct workflows the `propositions` skill dispatches: the **Quick Fix** quality-repair loop (via `quality-enricher`) and the **Variant** CRUD operations. Loaded only when these phases fire.

## Contents

1. [Quick Fix vs. Deep Dive](#quick-fix-vs-deep-dive)
2. [When to offer Quick Fix](#when-to-offer-quick-fix)
3. [Quick Fix workflow](#quick-fix-workflow)
4. [Not all dimensions need research](#not-all-dimensions-need-research)
5. [Variant operations](#variant-operations)

## Quick Fix vs. Deep Dive

Two distinct repair paths exist. Pick by the assessor's verdict:

| Situation | Use |
|---|---|
| Fix DOES/MEANS that scored warn/fail on 1–2 dimensions (overall pass/warn) | **Quick Fix** (`quality-enricher` — reactive, targeted gap repair) |
| 2+ dimension fails, or buyer-perspective / need-correctness fail | **Deep Dive** (see `deep-dive-workflow.md`) — these dimensions need buyer language research |
| Validate buyer language against real market usage | **Deep Dive** |
| Analyse how competitors message the same capability for this market | **Deep Dive** |
| Co-create DOES/MEANS through strategic dialogue with evidence | **Deep Dive** |
| Stakeholder review verdict is `reject` for specific propositions | **Deep Dive** on worst offenders |

Quick Fix is reactive and tactical. Deep Dive is strategic and produces messaging intelligence that informs not just the proposition but downstream competitor positioning, solution design, and sales enablement.

## When to offer Quick Fix

- After proposition quality assessment shows any proposition with overall `warn` or `fail`
- When the user explicitly asks to "improve", "fix", "strengthen", or "sharpen" propositions
- During Proposition Review when you identify generic or vendor-centric messaging

## Quick Fix workflow

1. Run quality assessment (`proposition-quality-assessor`) to identify gaps.
2. Present the gap summary — which propositions have issues and on which DOES/MEANS dimensions.
3. Ask which propositions to research and improve (all flagged / fails only / specific ones).
4. For each selected proposition, dispatch the `quality-enricher` agent via the Agent tool with:

   - The proposition JSON (full content)
   - The referenced feature JSON and market JSON (for context)
   - The quality assessment results (DOES dimensions, MEANS dimensions, scores, notes)
   - Company context from `portfolio.json` — company name, domain/website, regional URL for output language, product names, language
   - The project directory path
   - `plugin_root: $CLAUDE_PLUGIN_ROOT`

   **Regional URL derivation:** common pattern is `{domain}/{lang}` (e.g., `t-systems.com/de`). If the company context already includes an explicit `regional_urls` map, use the entry for the portfolio language. Pass both `domain` (for English backup) and `regional_url` (for localised search). The agent also receives the market JSON (which contains `region`) — it uses this to look up the region locale from `regions.json` for market-scoped queries.

   Launch multiple agents in parallel for different propositions.

5. Collect results and present improvements as before/after for DOES and MEANS separately:

   **{feature}--{market}** — Issues: {dimensions}

   | Layer | Current | Proposed |
   |---|---|---|
   | DOES | "current DOES…" | "proposed DOES…" |
   | MEANS | "current MEANS…" | "proposed MEANS…" |

   Show evidence found and confidence level. When confidence is low, present the agent's targeted questions to the user instead.

6. User chooses per proposition: **Accept** / **Edit** / **Skip**.
7. Write accepted changes to the proposition JSON, set the `updated` field to today's date.
8. The agent submits quantified evidence as claims via `append-claim.sh` for downstream verification.

## Not all dimensions need research

Conciseness issues (word count) and escalation problems (MEANS repeats DOES) can be fixed by rewriting from existing content — no research needed. Reserve web research for dimensions where company-specific information is the missing ingredient: **buyer centricity, market specificity, quantification, and differentiation**.

When `need_correctness` or `buyer_perspective` scores `fail`, web research won't repair it. Route those to the Deep Dive workflow instead.

## Variant operations

Propositions can have multiple DOES/MEANS variants, each representing a different angle derived from TIPS value chains or user-originated perspectives. The primary IS/DOES/MEANS remains the default messaging; variants offer alternative positioning for specific sales contexts.

### List variants

Read the proposition JSON and display the `variants` array:

| Variant | Angle | TIPS Ref | Quality | Created |
|---------|-------|----------|---------|---------|
| v-001 | regulatory-compliance | pursuit#st-001 | pass | 2026-03-10 |
| v-002 | cost-optimization | pursuit#st-003 | warn | 2026-03-12 |

Show each variant's `angle`, `tips_ref` (or "manual" if no TIPS reference), and `quality_score` if assessed. If no variants exist, report that and suggest adding one or running the TIPS bridge to generate them.

### Add a variant

For user-originated angles without TIPS context. Prompt for:

1. **Angle** — short kebab-case label (e.g., `talent-retention`, `speed-to-market`)
2. **DOES statement** — the advantage from this angle's perspective
3. **MEANS statement** — the business outcome from this angle's perspective

Apply the same quality criteria as primary DOES/MEANS (word counts, market-swap test, competitor test, "so what?" test — see `quality-dimensions.md`). Assign the next sequential `variant_id` (v-001, v-002, …) and append to the `variants` array. Set `tips_ref` to `null` for manual variants.

### Promote a variant

Swap a variant with the primary DOES/MEANS — the only way to change the primary messaging based on a variant.

1. Read the proposition and find the variant by `variant_id`.
2. Save the current primary `does_statement` and `means_statement` as a new variant (angle `previous-primary`, next sequential `variant_id`).
3. Copy the variant's `does_statement` and `means_statement` to the primary fields.
4. Remove the promoted variant from the `variants` array.
5. Update the `updated` field to today's date.
6. Present the before/after to the user for confirmation before writing.

### Delete a variant

Remove a specific variant from the `variants` array. Show the variant's angle and DOES/MEANS before deleting and ask for confirmation. **This is permanent — the variant cannot be recovered.**

### Variant-aware batch generation

During batch generation, scan existing propositions for `tips_enrichment` metadata. When a proposition has `tips_enrichment` with `st_refs`, offer to generate variants for each referenced ST's value chain. Present these as a separate tier after primary generation:

```
| Feature | Market | ST Ref | Angle | Action |
|---------|--------|--------|-------|--------|
| predictive-analytics | mid-market-dach | st-001 | regulatory-compliance | Generate variant? |
| predictive-analytics | mid-market-dach | st-001 | cost-optimization | Generate variant? |
```

Dispatch variant generation to the `proposition-generator` agent in variant mode (with `tips_ref` and `value_chain_narrative`). Only generate variants after primary propositions are confirmed.
