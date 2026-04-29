# Proposition Quality Dimensions

Canonical reference for messaging quality in IS/DOES/MEANS propositions. Loaded by the `propositions` skill when shaping, assessing, or rewriting messaging.

## Contents

1. [The four messaging traps](#the-four-messaging-traps)
2. [Four tests for every proposition](#four-tests-for-every-proposition)
3. [IS quality criteria](#is-quality-criteria)
4. [DOES quality criteria + anti-patterns](#does-quality-criteria--anti-patterns)
5. [MEANS quality criteria + anti-patterns](#means-quality-criteria--anti-patterns)
6. [The 12 assessor dimensions](#the-12-assessor-dimensions)
7. [The need-correctness nuance](#the-need-correctness-nuance)

## The four messaging traps

The most common failure modes — recognise these in a draft before the assessor does.

- **Generic benefits** — "Saves time and money." Every product claims this. Replace with what specifically changes.
- **Feature-as-benefit** — DOES rephrasing the IS with an action verb prepended. "Real-time monitoring means you get real-time monitoring" is circular at three altitudes.
- **Market-agnostic DOES** — if the advantage statement works for every market, either the markets aren't distinct or the messaging isn't specific.
- **Aspirational MEANS** — outcomes the buyer can't measure or doesn't actually prioritise. Ground every benefit in a KPI the buyer already tracks.

## Four tests for every proposition

Run these before presenting messaging to the user. They are non-negotiable — together they catch ~90% of weak propositions before they enter the assessor pipeline.

1. **Market-swap test** — substitute a different market into the DOES/MEANS. If the messaging still works, it is too generic. *"Reduces operational overhead"* works for any market; *"Eliminates the dedicated SRE hire that mid-market SaaS companies can't afford during Series A-to-B scaling"* only works for one.

2. **Competitor test** — could a direct competitor credibly make this same DOES/MEANS claim? If yes, the messaging describes the category, not the product. Rewrite around what is unique to this specific feature.

3. **"So what?" test** — read the MEANS aloud and ask "so what — would a CFO approve budget for this?" If the outcome is too vague to put in a business case, the messaging isn't grounded in a measurable KPI.

4. **Circularity test** — read IS, DOES, MEANS in sequence. If all three say the same thing at different altitudes of abstraction (*"monitors pipelines" → "provides visibility" → "ensures reliability"*), the proposition is circular. Each layer must introduce genuinely new information.

## IS quality criteria

The IS layer restates the feature, lightly adapted for market context.

- Factual, capability-focused
- No superlatives or marketing language
- Same facts as the source feature; only phrasing may shift to match the target buyer's vocabulary

## DOES quality criteria + anti-patterns

The DOES layer is the market-specific advantage. **Target: 15–30 words, 1–2 sentences.**

**Criteria:**
- Written from the buyer's perspective: "you can…" / "teams can…" — not "it provides…" or "our solution enables…"
- Quantified where possible ("reduces X by Y%")
- References the specific pain point of this market segment — would not work if you swapped in a different market
- Implies or states what changes vs. the buyer's current approach (status-quo contrast)
- Action-oriented verb (reduces, eliminates, accelerates, enables)
- Passes the competitor test
- Passes the Snicker Test: a salesperson could say it aloud naturally

**Anti-patterns to reject:**
- Vendor-centric framing — "Our solution enables…", "It provides…", "The platform delivers…"
- Feature restating — DOES that merely rephrases the IS layer with an action verb prepended
- Generic advantage — "Saves time and money" — every product claims this
- Parity claims — any product in the category could make the same statement
- Passive voice / nominalised verbs — "provides optimization" instead of "you can optimize…"

## MEANS quality criteria + anti-patterns

The MEANS layer is the market-specific business outcome. **Target: 15–30 words, 1–2 sentences.**

**Criteria:**
- Business outcome the buyer cares about and can measure (KPI, dollar figure, named metric)
- Introduces genuinely new impact beyond DOES — not a restatement with an outcome verb
- References the buyer's strategic goals or KPIs
- Uses or implies quantification — "$1.2M savings" is stronger than "significant cost reduction"
- Includes personal/emotional impact where appropriate (career protection, reduced firefighting, team morale)
- Connects operational advantage to commercial impact
- Passes the "so what?" test

**Anti-patterns to reject:**
- Vague aspirational language — "drives digital transformation", "delivers ROI", "enhances productivity"
- Circular restating — MEANS repeats DOES with different wording ("ensures reliability" after DOES says "provides visibility")
- Disconnected outcomes — business outcomes not causally linked to the DOES claim
- Press-release tone — "industry-leading performance", "world-class outcomes", "best-in-class results"
- Missing escalation — MEANS staying at the same operational level as DOES instead of rising to business/personal impact

## The 12 assessor dimensions

The `proposition-quality-assessor` agent evaluates DOES across 7 dimensions and MEANS across 5. Each dimension scores `pass` / `warn` / `fail`. Two or more dimension failures roll up to overall `fail`.

**DOES (7 dimensions):**

| Dimension | What it checks |
|---|---|
| Buyer-centricity | Statement is written from the buyer's perspective ("you can…"), not the seller's ("we provide…") |
| Buyer-perspective correctness | The buyer archetype matches the market — practitioner / consumer / enabler (see [need-correctness](#the-need-correctness-nuance)) |
| **Need correctness** | The framed need is the buyer's actual need, not a provider-lens caricature |
| Market-specificity | Statement fails the market-swap test — wouldn't work for a different market |
| Differentiation | Statement passes the competitor test — couldn't credibly be claimed by competitors |
| Status-quo contrast | Statement implies or states what changes vs. the buyer's current approach |
| Conciseness | 15–30 words, 1–2 sentences, no padding |

**MEANS (5 dimensions):**

| Dimension | What it checks |
|---|---|
| Outcome specificity | Names a measurable business outcome, not a vague aspiration |
| Escalation | Rises above DOES — operational advantage → commercial / personal impact |
| Quantification | Includes numbers, KPIs, or specific named metrics where possible |
| Emotional resonance | Touches buyer pain or career impact where appropriate |
| Conciseness | 15–30 words, 1–2 sentences, no padding |

## The need-correctness nuance

This dimension catches the subtlest buyer-perspective failure: propositions that correctly classify the buyer archetype but frame value through the provider's lens.

Example: telling an SME buyer *"your consultant delivers better results"* when the buyer's actual need is *"I can do this without a consultant."* The buyer isn't measuring "better consultant outcomes" — they are measuring "do I still need to hire a consultant?"

This dimension specifically detects provider-lens contamination in consumer-market propositions, where the temptation to frame value through the eyes of a service partner is highest. Need-correctness fails almost always indicate the messaging team is thinking inside-out.

When `need_correctness` scores `fail`, the fix usually is *not* a Quick Fix (web research won't repair it). Route these to the Deep Dive workflow, which validates buyer language against real market usage.
