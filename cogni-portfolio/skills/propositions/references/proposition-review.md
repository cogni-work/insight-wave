# Proposition Review

The audit walk the `propositions` skill runs when the user asks to review existing propositions, or when you spot quality issues during another operation. Loaded only when this phase fires.

## Contents

1. [Buyer-perspective audit (7 steps)](#buyer-perspective-audit-7-steps)
2. [Validate against the portfolio](#validate-against-the-portfolio)
3. [Review presentation format](#review-presentation-format)

## Buyer-perspective audit (7 steps)

When the user asks to review or improve existing propositions, jump straight into critique. No discovery questions — they already have propositions and want them evaluated.

1. **Read all propositions and their source features and markets.**

2. **Buyer-perspective audit** — for each market, check whether all propositions frame the feature from the correct buyer perspective. Is the buyer a:

   - **Practitioner** — already does this professionally; the feature accelerates them
   - **Consumer** — needs this outcome but doesn't have the capability; the feature provides self-service access
   - **Enabler** — resells or embeds the capability

   A consulting firm should see practitioner-acceleration messaging; an SME should see self-service-empowerment messaging. Mixed perspectives within a single market signal confused positioning.

3. **Differentiation audit** — for each proposition, could a competitor credibly make the same claim? Flag any that fail this test.

4. **Market specificity check** — swap markets mentally. If the DOES/MEANS work for a different market, the messaging is too generic.

5. **Evidence gaps** — propositions making quantitative claims without evidence are vulnerable. Flag them and suggest what evidence to gather.

6. **Coherence by market** — read all propositions for a single market together. Do they tell a story? Would a buyer in this market, reading all your propositions, understand your full value? Or do they sound like disconnected bullet points?

7. **Upstream diagnosis** — trace weak propositions back to their source. Is the feature description too vague? Is the market definition missing pain points? Are customer profiles missing? Flag upstream fixes.

Present your assessment as a consulting memo — lead with *"here's what I'd change and why"* backed by specific analysis. Do not list observations and ask "what do you think?" — state your recommended changes and let the user push back.

For propositions with quality issues that need company-specific information to fix (buyer centricity, market specificity, quantification, differentiation), offer Quick Fix or Deep Dive — see `research-and-enrich.md`.

## Validate against the portfolio

Cross-reference propositions with existing portfolio entities:

- **Feature integrity** — every proposition must reference a valid `feature_slug` in `features/`.
- **Market integrity** — every proposition must reference a valid `market_slug` in `markets/`.
- **Orphaned propositions** — flag propositions referencing features or markets that don't exist.
- **Duplicate messaging** — flag propositions with near-identical DOES/MEANS across different markets. This signals either the markets aren't distinct enough or the messaging isn't specific enough. **One of the highest-value checks**: if two markets get the same messaging, either the markets should merge or the messaging needs differentiation.
- **Product-tier alignment** — check whether a feature's parent product is priced and packaged for the target market. A feature belonging to an Enterprise-tier product positioned for a mid-market segment creates a go-to-market mismatch — the proposition may be strong on paper but impossible to sell without a packaging change. Flag explicitly: *"This feature belongs to your Enterprise product, but you're targeting mid-market buyers on your Professional tier. Either the proposition needs a different packaging story or this pair isn't viable yet."*

Use `$CLAUDE_PLUGIN_ROOT/scripts/project-status.sh` to generate an overview of coverage gaps and orphaned references.

## Review presentation format

Present propositions with consulting commentary, not just the raw statements. Group by feature or by market — whichever the user prefers, or whichever reveals more insight.

| Feature | Market | DOES (summary) | Evidence | Assessment |
|---|---|---|---|---|
| cloud-monitoring | mid-market-saas | Reduces MTTR by 60% | 2 sources | Sharp, buyer-specific |
| data-analytics | enterprise-fintech | Improves decision-making | 0 sources | Too generic — needs rework |

Then deliver your assessment as a consulting perspective:

- Which propositions are strong and ready for downstream use
- Which need sharper messaging and what specifically to change
- Whether the set tells a coherent story to each target market
- What to prioritise next
