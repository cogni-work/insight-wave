# Proposition Quality Gates

Procedural detail for the four-stage quality gate the `propositions` skill runs before, during, and after generation. Loaded only when the relevant phase fires.

## Contents

1. [Before Generation — Feature Pre-check](#before-generation--feature-pre-check)
2. [Customer-profile coverage gate](#customer-profile-coverage-gate)
3. [After Generation — Proposition Post-check](#after-generation--proposition-post-check)
4. [Stakeholder Review](#stakeholder-review)
5. [Variant Quality](#variant-quality)
6. [Post-Generation Review Checkpoint](#post-generation-review-checkpoint)

These four stages form a state machine — pre-check → post-check → stakeholder review → post-generation checkpoint. The stages are ordered: don't skip ahead.

## Before Generation — Feature Pre-check

Three checks plus a checkpoint, before any proposition is drafted.

1. **Structural validation** — `$CLAUDE_PLUGIN_ROOT/scripts/validate-entities.sh <project-dir>` catches missing fields and very short feature descriptions.

2. **Description quality assessment** — dispatch the `feature-quality-assessor` agent. It evaluates mechanism clarity, customer relevance, differentiation, and language quality in any language (German, English, mixed).

3. **Stakeholder persona review** — confirm the `feature-review-assessor` has been run and returned verdict `accept`. If not, dispatch it now. If verdict is `revise` or `reject`, refuse to generate propositions and direct the user back to the `features` skill.

**If a feature has structural errors, an overall `fail` from the quality assessor, or the feature set has not passed stakeholder review:**

1. Show the specific issues (structural warnings, quality assessment results, stakeholder review findings).
2. Explain why a proposition built on a weak feature set will itself be weak — vague features produce vague IS statements, which cascade into generic DOES/MEANS messaging.
3. Direct the user to fix features first via the `features` skill.
4. Offer to continue with other Feature x Market pairs that pass all three checks.

Features with `warn` from the description quality assessor can proceed (if stakeholder review is `accept`), but flag the warnings so the user is aware.

This pre-check applies to both single-proposition and batch generation. In batch mode, exclude failing features from the generation set and report them separately.

`project-status.sh` reports `feature_quality_warnings` for a quick overview. For deep assessment, always use the agents.

4. **Pre-generation review checkpoint** — after the three checks pass, pause and present the full picture before generating anything. **This is a mandatory interaction point. Do not auto-start batch generation.**

   Present:
   - Stakeholder review verdict and score
   - The relevance matrix from `project-status.sh` — High / Medium / Low / Skip per pair
   - Feature readiness summary (GA / Beta / Planned counts; deferred warnings from the features phase)
   - **Customer-profile coverage** — see the gate ladder below

## Customer-profile coverage gate

Markets with `customers/{market-slug}.json` files produce perspective-correct, buyer-grounded propositions. Markets without them produce propositions with inferred buyer perspective — generic pain points instead of role-specific buying criteria and persona-grounded language.

Present coverage as a table so the user sees the gap clearly. Then offer the appropriate option ladder:

**Zero customer profiles exist:**
- (a) open the dashboard to review the current portfolio state
- (b) see the full feature descriptions that will become the IS layer
- (c) run the `customers` skill first for buyer-grounded propositions **(recommended)**
- (d) proceed without customer profiles — use inferred buyer perspective

**Some but not all markets have profiles:**
- (a) open the dashboard
- (b) see the full feature descriptions
- (c) add customer profiles for the remaining N market(s) first **(recommended)**
- (d) proceed — generate with profiles where available, infer for the rest

**All markets have profiles:**
- (a) open the dashboard
- (b) see the full feature descriptions
- (c) proceed with generation

**The user must explicitly choose (d) to bypass.** Do not auto-proceed past this checkpoint when customer profiles are missing — buyer-grounded messaging is materially better than inferred messaging, and this is the last opportunity to add profiles before generating a large batch.

If the user chooses (a), dispatch the `dashboard-refresher` agent with `project_dir` and `plugin_root: $CLAUDE_PLUGIN_ROOT`, then ask again whether they're ready to proceed. If (b), present feature descriptions with quality status. If (c) where customer profiles are missing, direct them to the `customers` skill. Only proceed to generation after the user confirms (c) when all profiles exist, or explicitly chooses (d).

After batch generation, log which propositions were generated with customer profile data vs. inferred buyer perspective so the user can later identify which to revisit.

The reason this gate exists: once propositions are generated, the user reads them on top of features. Spotting a weak IS statement is much harder when DOES/MEANS messaging is already layered on top.

## After Generation — Proposition Post-check

Run after every generation (single or batch).

1. **Structural validation** — `$CLAUDE_PLUGIN_ROOT/scripts/validate-entities.sh <project-dir>` checks DOES/MEANS word counts against the 15–30 word target. Fast, catches obvious bloat or terseness.

2. **Messaging quality assessment** — dispatch the `proposition-quality-assessor` agent. It evaluates DOES across 7 dimensions and MEANS across 5 (full list in `quality-dimensions.md`).

If a proposition has overall `fail` (two or more dimension failures), **flag it for rewrite** before it flows downstream. Show the specific dimension failures and suggested rewrites.

Propositions with `warn` can proceed but flag the warnings — they represent improvement opportunities the user should be aware of.

In batch mode, present a summary table of pass/warn/fail counts alongside the proposition review table.

## Stakeholder Review

After the messaging quality assessment passes (no `fail` propositions remaining or all fails rewritten), dispatch the `proposition-review-assessor` agent for each market that received new or updated propositions. **This is the final quality gate before propositions flow into competitor analysis, solutions, and sales materials.**

The review evaluates propositions as a set from three perspectives:

- **Simulated Buyer Persona** — *"Would I recognise this as my problem? Does this speak to MY need?"* Catches provider-lens contamination the per-dimension assessor missed.
- **Sales Person** — *"Can I say this in a customer meeting? Is this credible?"* Catches claims that look good on paper but fail in conversation.
- **Product Marketer** — *"Is the messaging coherent across the set? Are we telling one story?"* Catches inconsistency, redundancy, fragmented differentiation.

**Verdicts:**

- **accept** — propositions are ready for downstream use.
- **revise** — present findings grouped by perspective. Offer to rewrite the flagged propositions. Re-run the stakeholder review after fixes.
- **reject** — block downstream flow. Fundamental rework needed. Direct the user to the Deep Dive workflow on the worst offenders.

The stakeholder review is especially important for consumer markets (B2B-SME, self-service buyers) where the provider-lens trap is most common. If the buyer-persona perspective flags need-correctness issues, they are CRITICAL priority — they indicate inside-out thinking.

## Variant Quality

When a proposition has variants, assess each variant's DOES/MEANS alongside the primary using the same 12 dimensions. Report variant quality in the summary table with the variant's angle label. Variants with `fail` should be flagged for rewrite or deletion — weak variants dilute the proposition rather than strengthen it.

## Post-Generation Review Checkpoint

After batch generation completes and the post-check runs, pause and present full results. **This is a mandatory interaction point. Do not auto-continue to next steps or to medium-tier generation.**

Present a comprehensive milestone summary:

- Total propositions generated, grouped by tier (High / Medium / Skip)
- Summary table: Feature | Market | IS word count | DOES word count | MEANS word count | Evidence count | Quality assessment
- Deduplication findings (talking points appearing 3+ times across the batch)
- Propositions flagged for rewrite (overall `fail` from quality assessor)
- Propositions without evidence (if any)

Then offer review options:

> Would you like to: (a) open the dashboard to see the full Feature x Market matrix with the new propositions, (b) read through the generated propositions in detail — I'll present them grouped by feature or market, (c) focus on the flagged propositions that need attention, or (d) proceed to the next tier / next steps?

Wait for the user's explicit response. If (a), dispatch the `dashboard-refresher` agent with `project_dir` and `plugin_root: $CLAUDE_PLUGIN_ROOT`, then ask again whether they're ready. **Do not suggest generating the next tier or moving to solutions until the user has had the chance to review what was just created.**

When the user chooses to read propositions in detail (option b), present each proposition with full IS/DOES/MEANS text and your consulting commentary — not just the summary table. Group by feature or market based on what reveals the most insight (or ask the user's preference). For each proposition include:

- Full IS / DOES / MEANS statements
- Evidence entries with sources
- Your quality assessment (which tests it passes / fails)
- Specific improvement suggestions where relevant

The reason this matters: propositions are the messaging foundation for everything downstream — competitor battlecards, customer profiles, pitch decks, proposals. Five minutes of review here saves hours of cascading rework when a weak DOES is discovered later.
