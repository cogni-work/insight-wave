---
name: customers
description: |
  Create ideal customer profiles and buyer personas per target market.
  Use whenever the user mentions customer profiles, ICP, buyer persona,
  buying center, target customer, "who buys this", decision-makers,
  buying committee, purchase journey, or wants to understand the people
  behind a market — even if they don't say "customer" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Agent
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

### 2. Gather Customer Intelligence (Data-First)

For each market, read all available data before asking the user anything:

- **Company context** (`portfolio.json`): Industry knowledge informs buyer types
- **Market definition** (`markets/{slug}.json`): Segmentation criteria constrain the buyer
- **Proposition messaging** (`propositions/`): DOES/MEANS statements reveal which pain points are being addressed
- **Competitor analysis** (`competitors/`): Competitor targeting reveals buyer roles and decision patterns
- **Internal context** (`context/context-index.json`, if it exists) -- read entries in `by_relevance["customers"]`. Interview transcripts, CRM summaries, and buyer persona research provide first-hand buyer intelligence. When context entries link to specific market slugs via `entities`, apply that context to those market profiles specifically.

**Web research (optional)**: When the user requests research-backed profiles, delegate to a subagent (Agent tool) to search for industry buyer surveys, role descriptions, and purchasing behavior data for this market segment. This is especially useful when the user lacks first-hand buyer knowledge.

### 2b. State Inferences Before Building

Before building profiles, present what you inferred from available data as testable assumptions:

- "Based on your market segmentation (mid-market SaaS, 50-500 employees), I'm inferring a VP Engineering buyer as the primary decision-maker."
- "Your proposition DOES statements around MTTR reduction suggest SRE pain points — I'll use these as the primary pain points."
- "Your competitor analysis shows competitors targeting CIOs — this suggests you need a CIO profile in the buying committee too."

Ask the user only about aspects not covered by existing data — focus on: buying committee dynamics (who has veto power), information sources (where buyers learn), and deal stall points (where purchases get stuck). Do not re-ask about pain points if propositions already cover them, or about decision-makers if the data makes them obvious.

### 3. Build Customer Profiles

For each market, define 2-4 buyer profiles (one primary, others secondary). The primary profile should be the person who initiates or champions the purchase decision. Include all stakeholders with veto power or formal gatekeeper roles — in regulated industries (energy, healthcare, public sector), this often means a CISO or compliance officer AND the procurement/Einkauf function. For markets where managed services could affect headcount, include Betriebsrat/works council as a stall point with realistic timelines (1-6 months depending on whether Interessenausgleich/Sozialplan negotiations are triggered). Missing a veto-holder from the profile set means downstream messaging has a blind spot that can stall or kill deals.

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

Present each market's profiles for review. Frame it as "confirm or correct my inferences" rather than fresh discovery:

"Here's what I built from your portfolio data — are these the right roles? Anything missing or off?"

Iterate until the profiles feel accurate.

### 5b. Stakeholder Review (Closed Loop)

After writing the customer profiles, delegate to the `customer-review-assessor` agent for qualitative evaluation. This agent assesses the profiles from three stakeholder perspectives:

1. **Reviewer (Procurement)** — Role completeness, pain point specificity, buying criteria realism, decision dynamics accuracy, deal cycle coherence
2. **Chief Sales Officer** — Account targeting clarity, pain-to-proposition mapping, objection anticipation, multi-threading guidance, named customer actionability
3. **Market Expert** — Segment calibration, vertical authenticity, temporal accuracy, information source validity, regional accuracy

The agent returns a structured assessment with a verdict:

- **accept** (all perspectives score 85+): Profile is ready. Proceed to proposition validation.
- **revise** (all perspectives score 70+): Targeted improvements needed. Rewrite only the flagged areas of the profile based on `revision_guidance`. Re-assess. Maximum 2 revision rounds.
- **reject** (any perspective below 50): Fundamental rework needed. Surface the assessment to the user with the diagnosis — do not auto-retry.

**For interactive mode**: Present the assessment summary to the user before revising. Show per-perspective scores and top recommendations. Let the user decide which improvements to prioritize.

**For batch mode (profiles for all markets)**: Run the loop automatically. Profiles that pass after Round 1 skip Round 2. Profiles that still fail after Round 2 are flagged for manual attention.

The stakeholder review complements the proposition cross-validation in Step 6 — Step 6 catches structural gaps (orphan pain points, missing proposition coverage), while stakeholder review catches qualitative issues (unrealistic committee dynamics, non-actionable profiles, wrong vertical terminology). Run the stakeholder review first; structural validation in Step 6 provides a final consistency check.

### 6. Validate Against Propositions

Cross-reference customer pain points with proposition DOES/MEANS statements. Each pain point should connect to at least one proposition's advantage. Flag gaps where:
- A pain point has no matching proposition
- A proposition addresses a pain point not listed in the customer profile

These gaps are valuable — they either reveal missing propositions or signal that a profile needs updating.

### 7. Named Customer Research

After completing buyer personas, offer to identify specific named companies in this market:

> "Would you like to identify specific named companies in this market segment?"

Two modes of operation:

**User-provided:** The user names specific companies they want researched. Proceed directly to research.

**Auto-discover:** When the user wants suggestions, search the web to identify 5-10 candidate companies. Use language-aware queries based on the market's region locale (read `regions.json` for the locale). For non-English locales, search in the region language first, then supplement with English:
- `de-DE`: `"Top {Segment} Unternehmen in {Region}"`, `"führende {Branche} Firmen {Region} {year}"`
- `en-*` or absent: `"top {segment} companies in {region}"`, `"leading {vertical} companies {region} {year}"`

Present the list and let the user select which to research.

For each selected company, delegate research to the `customer-researcher` agent (via the Agent tool). Launch agents in parallel when researching multiple companies. Always include `plugin_root: $CLAUDE_PLUGIN_ROOT` in the agent task prompt. Each agent returns a structured JSON object — do NOT let agents write files directly.

Merge all returned results into a `named_customers` array in the customer JSON. Deduplicate by `domain` — if a company already exists, update rather than duplicate.

### 8. Review Named Customers

Present the named customer results for user review:

- Show a summary table: company name, industry, fit score, key pain points
- Allow the user to remove companies that don't fit
- Allow the user to add more companies (loops back to Step 7)
- Confirm final list before writing

Write the updated customer JSON with both `profiles` and `named_customers`.

After writing, offer: "Would you like to: (a) open the dashboard to see customer coverage across all markets, (b) review the full customer profiles in detail, or (c) proceed to the next steps?"

Wait for the user's explicit response. If they choose (a), delegate to the `dashboard-refresher` agent with `project_dir` and `plugin_root: $CLAUDE_PLUGIN_ROOT` to generate a dashboard snapshot, then ask again if they're ready to proceed.

## Important Notes

- Customer files share the same slug as their parent market
- One customer file per market, containing an array of buyer profiles
- **Content Language**: Read `portfolio.json` in the project root. If a `language` field is present (e.g., `"de"`), write all user-facing text content in that language — pain_points, buying_criteria, decision_role, information_sources, fit_rationale, and all descriptive fields. This means full sentences in the target language, not English sentences with embedded domain terms. For `"de"`: write `"SAP IS-U Ablösung bis 2027 erzwingt Cloud-Migrationsentscheidung unter Zeitdruck bei gleichzeitigem 24/7-Netzbetrieb"`, not `"SAP IS-U end-of-life forces a cloud migration decision under time pressure while maintaining 24/7 grid operations"`. JSON field names and slugs remain in English. If no `language` field is present, default to English.
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. Default to English if no `language` field is present.
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md` for complete entity schemas
