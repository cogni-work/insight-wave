---
name: customers
description: |
  Create ideal customer profiles and buyer personas per target market.
  Use whenever the user mentions customer profiles, ICP, buyer persona,
  buying center, target customer, "who buys this", decision-makers,
  buying committee, purchase journey, or wants to understand the people
  behind a market — even if they don't say "customer" explicitly.
---

# Customer Profiling

Create ideal customer profiles (ICPs) for each target market. Customer profiles describe who buys, why they buy, and how they make purchasing decisions.

## Core Concept

Customer profiles are market-scoped, not proposition-scoped. All propositions targeting "mid-market SaaS" share the same customer profile because the buyer is the same person regardless of which feature they are evaluating. The profile captures the buyer's world — their pain points, decision criteria, and information habits.

This matters because downstream deliverables (competitive analysis, messaging, sales collateral) all depend on knowing the buyer. A strong customer profile makes every other skill more effective; a weak one propagates blind spots throughout the portfolio.

## Workflow

### 1. Select Markets

List existing markets (read `markets/` directory) and identify those without customer files. Present options:

- Create profiles for all markets without them
- Create a profile for a specific market

### 2. Gather Customer Intelligence

For each market, build the customer profile from available context:

- **Company context** (`portfolio.json`): Industry knowledge informs buyer types
- **Market definition** (`markets/{slug}.json`): Segmentation criteria constrain the buyer
- **Proposition messaging** (`propositions/`): DOES/MEANS statements reveal which pain points are being addressed
- **User input**: The user may know their buyers well — ask directly

**Web research (optional)**: When the user requests research-backed profiles, delegate to a subagent (Agent tool) to search for industry buyer surveys, role descriptions, and purchasing behavior data for this market segment. This is especially useful when the user lacks first-hand buyer knowledge.

### 3. Build Customer Profiles

For each market, define 1-3 buyer profiles (one primary, others secondary). The primary profile should be the person who initiates or champions the purchase decision.

For each profile capture:

- **Role**: Job title or function (e.g., "VP Engineering")
- **Seniority**: Level in organization (e.g., "C-1", "Director-level")
- **Pain points**: Max 5 items, 1 sentence each — specific problems relevant to the portfolio's features
- **Buying criteria**: Max 5 items, 1 short phrase each (e.g., "Time to value under 2 weeks")
- **Information sources**: Where they learn about solutions (e.g., "Peer recommendations", "Industry podcasts")
- **Decision role**: Their role in the purchase (economic buyer, technical evaluator, champion, etc.)

When a market has multiple profiles, briefly describe the buying committee dynamics: who initiates, who evaluates, who signs off, and where deals typically stall. This context helps downstream messaging target the right person at the right stage.

### 4. Write Customer Entities

Write to `customers/{market-slug}.json` (same slug as the market):

```json
{
  "slug": "mid-market-saas",
  "market_slug": "mid-market-saas",
  "profiles": [
    {
      "role": "VP Engineering",
      "seniority": "C-1",
      "pain_points": [
        "Growing infrastructure complexity outpacing team capacity",
        "Alert fatigue leading to missed critical incidents"
      ],
      "buying_criteria": [
        "Time to value under 2 weeks",
        "Total cost under $100K/year"
      ],
      "information_sources": ["Hacker News", "Peer recommendations"],
      "decision_role": "Economic buyer and technical evaluator"
    }
  ],
  "created": "2026-01-25"
}
```

### 5. Review with User

Present each market's profiles for review. The user likely knows their buyers better than any research — ask explicitly:

- Are these the right roles? Missing anyone?
- Do the pain points ring true?
- Anything surprising or off about the buying criteria?

Iterate until the profiles feel accurate.

### 6. Validate Against Propositions

Cross-reference customer pain points with proposition DOES/MEANS statements. Each pain point should connect to at least one proposition's advantage. Flag gaps where:
- A pain point has no matching proposition
- A proposition addresses a pain point not listed in the customer profile

These gaps are valuable — they either reveal missing propositions or signal that a profile needs updating.

## Important Notes

- Customer files share the same slug as their parent market
- One customer file per market, containing an array of buyer profiles
- **Content Language**: Read `portfolio.json` in the project root. If a `language` field is present, generate all user-facing text content (pain points, buying criteria, profile descriptions) in that language. JSON field names and slugs remain in English. If no `language` field is present, default to English.
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. Default to English if no `language` field is present.
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md` for complete entity schemas

## Session Management

After completing customer profiles across multiple markets or when this skill runs after other heavy skills already consumed context in the same session, proactively check in with the user about starting fresh. Signs that a new session would improve quality:

- Customer profiles completed for 3+ markets
- Three or more different portfolio skills were already invoked this session
- The user asks about remaining context or capacity

When you notice these signals, first invoke `/dashboard` to generate the portfolio dashboard — this gives the user a visual overview of everything accomplished so far. Then recommend a fresh session:

> "We got a lot done: [brief summary of accomplishments]. I've generated the dashboard so you can see the full picture. For the next steps like [recommend next skills], I'd suggest starting a fresh session — just use `/resume-portfolio` to pick up where we left off. That loads the current state cleanly without carrying the weight of this session."

Use the portfolio's communication language (read `portfolio.json` for the `language` field). Frame it as helpful advice for better output quality, not as a limitation. The key message: `/resume-portfolio` exists exactly for this — seamless multi-session workflows.
