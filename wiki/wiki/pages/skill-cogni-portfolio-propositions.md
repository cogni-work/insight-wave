---
id: skill-cogni-portfolio-propositions
title: "cogni-portfolio:propositions (skill)"
type: entity
tags: [cogni-portfolio, propositions, fab, is-does-means, messaging, b2b, multilingual, skill]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/propositions/SKILL.md
status: stable
related: [plugin-cogni-portfolio, concept-quality-gates, concept-multilingual-support, concept-claims-propagation, concept-data-model-patterns, skill-cogni-portfolio-features, skill-cogni-portfolio-markets, skill-cogni-portfolio-customers, skill-cogni-portfolio-solutions, skill-cogni-portfolio-compete, skill-cogni-portfolio-trends-bridge, agent-cogni-portfolio-proposition-generator, agent-cogni-portfolio-proposition-quality-assessor, agent-cogni-portfolio-proposition-review-assessor, agent-cogni-portfolio-proposition-deep-diver, agent-cogni-portfolio-quality-enricher]
---

> The IS/DOES/MEANS (FAB) value-messaging engine inside [[plugin-cogni-portfolio]] — generates and manages market-specific propositions per Feature × Market pair, with consulting-style critique built in.

The skill that turns a portfolio's market-independent features into market-specific value claims that buyers recognize and pay for. It is deliberately **not** a template-filler — the agent takes a position on messaging quality and pushes back on generic copy.

## Key takeaways

- **Consulting stance, not template-fill.** The skill explicitly rejects mechanical generation. It critiques generic DOES statements, calls out market-agnostic claims, demands a position on which 10-15 of the possible 160 Feature × Market pairs actually deserve a proposition, and refuses to generate every pair as noise. "Generating a proposition for every pair creates noise" is a load-bearing rule.
- **Four entry modes, four response shapes.** explore (conversational, 3-5 questions max, lead with sharp observations) · batch (gated — confirmation required before generating) · single pair (collaborative draft + critique) · review (jump straight to critique, no discovery). The skill warns against collapsing them into the same response.
- **Pre-generation gate has three checks plus a coverage gate.** Structural validation script → `feature-quality-assessor` (haiku) → `feature-review-assessor` (haiku). Then a customer-profile coverage gate: markets without `customers/{market-slug}.json` produce weaker, inferred-buyer messaging — the user must explicitly opt in to bypass. See [[concept-quality-gates]] for the broader three-layer pattern.
- **Four mandatory tests per proposition** before it ships:
  1. **Market-swap** — substituting a different market should break the messaging; if it still works, the DOES is too generic
  2. **Competitor** — could a direct competitor credibly make this same claim? If yes, the messaging describes the category, not the product
  3. **"So what?"** — would a CFO approve budget for this MEANS? Aspirational language ("drives transformation") fails this gate
  4. **Circularity** — IS/DOES/MEANS must each introduce new information, not rephrase the layer above
- **Strict word-count discipline.** IS 20-35 words, DOES 15-30, MEANS 15-30 — language-agnostic (German compound nouns count as one word). Validated by `scripts/validate-entities.sh`.
- **JSON schema lives at `propositions/{feature-slug}--{market-slug}.json`** — `feature_slug` + `market_slug` + IS/DOES/MEANS + optional `evidence[]` array. Each evidence item with a `source_url` is auto-logged as a claim via `scripts/append-claim.sh` for downstream verification through [[concept-claims-propagation]].
- **Three-layer post-check** — `proposition-quality-assessor` (haiku) evaluates 12 dimensions: 7 for DOES (Buyer-centricity, Buyer-perspective correctness, **Need correctness**, Market-specificity, Differentiation, Status-quo contrast, Conciseness) + 5 for MEANS (Outcome specificity, Escalation, Quantification, Emotional resonance, Conciseness); then structural validation; then `proposition-review-assessor` from three perspectives: buyer persona, sales person, product marketer.
- **Need correctness is the load-bearing dimension** — catches the subtlest failure: propositions that correctly classify the buyer archetype but frame value through the provider's lens (e.g., telling an SME buyer "your consultant delivers better results" when their actual need is "I can do this without a consultant"). Specifically detects provider-lens contamination in consumer-market propositions.
- **Variants** allow multiple DOES/MEANS angles per proposition (`regulatory-compliance`, `cost-optimization`, etc.). `variants list / add / promote / delete` operations preserve the primary messaging while accumulating angles; TIPS-derived variants flow in via [[skill-cogni-portfolio-trends-bridge]].
- **Two enrichment paths.** Quick Fix delegates to [[agent-cogni-portfolio-quality-enricher]] for reactive, targeted gap repair (1-2 warn/fail dimensions on overall pass/warn). Deep Dive delegates to [[agent-cogni-portfolio-proposition-deep-diver]] for buyer-language validation, competitive messaging analysis, evidence enrichment, or co-creation — required when `need_correctness` or `buyer_perspective` failed, when 3+ dimensions failed, or when stakeholder-review verdict is "reject".
- **Multilingual by design.** Both content language (IS/DOES/MEANS text) and communication language (status messages, recommendations, questions) are driven by `portfolio.json`'s `language` field — see [[concept-multilingual-support]]. Word counts apply equally across languages.

## Inputs

The skill reads (silently, before any user-facing question):

| File / Pattern | Purpose |
|---|---|
| `portfolio.json` | Company context, language |
| `features/*.json` | The IS layer source — every feature description becomes a proposition's IS statement |
| `markets/*.json` | Market segmentation, pain points, regional context |
| `propositions/*.json` | Existing propositions (coverage and quality state) |
| `customers/*.json` | Buyer personas with pain points, decision roles, buyer language — the gate for buyer-grounded vs inferred messaging |
| `competitors/*.json` | Competitive positioning, claims, white-space opportunities |
| `context/context-index.json` | Strategic intelligence from uploaded documents — `by_relevance["propositions"]` is queried first |

The data-first pattern (read everything, state inferences, ask only about gaps) is enforced — buyer-language questions are not allowed when `customers/{market-slug}.json` exists.

## Outputs

- One `propositions/{feature-slug}--{market-slug}.json` per generated pair (with optional `variants[]` array)
- Updated `excluded_markets[]` entries on `features/*.json` when the user confirms a skip recommendation (so decisions persist across sessions)
- Quality-assessor and review-assessor verdicts, presented in summary tables before downstream skills (solutions, compete) can run
- Auto-logged claims to `cogni-claims/claims.json` for every evidence URL (verifiable via [[concept-claims-propagation]])

## Pipeline position

```
features ──┐
markets ───┼──> propositions ──> solutions ──> packages
customers ─┤        │
           │        ├──> compete (per proposition)
           │        ├──> portfolio-verify (claim verification)
           │        └──> trends-bridge (TIPS variant generation)
           └──> propositions
```

Propositions are the messaging foundation for everything downstream — competitor battlecards, customer profiles, pitch decks, proposals — so the gates are conservative on purpose: weak propositions cascade into weak sales materials.

## Related operations

- **Per-pair editing** — read existing JSON, apply user changes, write back; the skill explicitly considers whether an edit reveals a deeper issue across the feature's other propositions
- **Slug rename** — when a feature or market slug changes, file rename + `scripts/cascade-rename.sh` to update solutions and competitors that reference the old slug
- **Variant operations** — `list / add / promote / delete` for multi-angle messaging, including TIPS value-chain variants generated via [[skill-cogni-portfolio-trends-bridge]]
- **Source registry integration** — when an evidence URL is added, it's also registered in `source-registry.json` with `evidence_refs` pointing back to this proposition; staleness warnings surface when the source has changed since last check

## Why the gates matter

The single sharpest line in the SKILL.md captures the philosophy: *"Five minutes of review here saves hours of rework later."* Once propositions ship into solutions and competitors, fixing a weak DOES or a missing evidence gap means cascading the fix through every dependent entity — and through every pitch and proposal already drafted on top.

## Sources

- [`cogni-portfolio/skills/propositions/SKILL.md`](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/propositions/SKILL.md) — full skill definition (~620 lines)
- [`cogni-portfolio/skills/propositions/references/quality-dimensions.md`](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/skills/propositions/references/quality-dimensions.md) — DOES/MEANS quality-dimension definitions used by `proposition-quality-assessor`
