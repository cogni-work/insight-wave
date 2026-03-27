---
name: sales-enablement
description: "Generate sales enablement content (battle cards, one-pagers, demo scripts, objection handlers, proposal sections) that equips sales teams with competitive intelligence and deal-closing tools from portfolio data. Use this skill when the user asks to 'create a battle card', 'one-pager', 'demo script', 'objection handling', 'sales collateral', 'proposal section', 'competitive comparison', 'sales enablement', 'arm the sales team', or wants decision-stage internal content for deal support — even if they don't say 'sales enablement' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

# Sales Enablement Content

## Purpose

Generate internal-facing content that equips sales and consulting teams with the intelligence, scripts, and tools they need to close deals. Sales enablement sits at the decision stage — the prospect is evaluating specific solutions and the sales team needs competitive differentiation, objection responses, and deal-specific materials.

## Prerequisites

- Marketing project with GTM paths configured
- Portfolio data: propositions, competitors, solutions, and customer profiles populated
- Recommended: portfolio compete phase completed (competitor data exists)

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug |
| gtm_path | Yes | GTM path theme ID |
| format | No | battle-card, one-pager, demo-script, objection-handler, proposal-section. If omitted, ask |

## Workflow

### Step 1: Load Context

1. Read `marketing-project.json` — brand, language
2. Load portfolio data (this skill is the most portfolio-heavy):
   - Competitors for this market: names, positioning, strengths, weaknesses, differentiation
   - Propositions: full IS/DOES/MEANS statements
   - Solutions: implementation phases, pricing tiers, effort estimates
   - Packages: bundled tiers with pricing
   - Customer profiles: buyer personas with pain points, buying criteria, decision roles
3. Load TIPS data: solution template readiness (what the portfolio covers vs. gaps)
4. **Optional enrichment**: If `sources.enriched_portfolio_narratives` exists in `marketing-project.json`, read the market-level and persona-level customer narratives for this market. These contain pre-written buyer-facing language that strengthens objection handlers and one-pagers with tested messaging. Especially useful for the "When we win" sections in battle cards.

### Step 2: Generate Content

#### Battle Card (400-500 words)
Structure:
1. **Header**: Our solution vs. [Competitor Name] — for [Market]
2. **Quick comparison table**:
   ```
   | Dimension        | Us                    | Competitor           |
   |------------------|-----------------------|----------------------|
   | Core approach    | [IS statement]        | [Their positioning]  |
   | Key advantage    | [DOES statement]      | [Their advantage]    |
   | Customer value   | [MEANS statement]     | [Their value claim]  |
   | Pricing model    | [From solutions]      | [From compete data]  |
   | Readiness        | [Blueprint readiness] | [Est. maturity]      |
   ```
3. **When we win**: Scenarios where our solution is stronger (from portfolio differentiation)
4. **When they win**: Honest assessment of competitor strengths (builds sales credibility)
5. **Trap questions**: Questions to ask the prospect that expose competitor weaknesses
6. **Key objections**: Top 3 objections when competing against this specific competitor + responses
7. **Proof points**: Evidence from TIPS claims or portfolio case studies

Generate one battle card per top competitor (typically 2-3 per market). Use competitor data from `competitors/{feature}--{market}.json`.

#### One-Pager (500-600 words)
Structure:
1. **Headline**: Clear value proposition for this market × GTM path
2. **The challenge** (2-3 sentences): Market-specific pain using TIPS implication tension
3. **Our approach** (3-4 bullets): Key differentiators from portfolio propositions (DOES statements)
4. **What you get** (3-4 bullets): Concrete outcomes from MEANS statements
5. **How it works** (3-4 steps): Simplified implementation from portfolio solution phases
6. **Investment** (range): From portfolio solution pricing tiers (PoV/S/M/L or subscription tiers)
7. **Proof point**: One compelling metric or reference
8. **Next step**: CTA matching brand CTA style

Designed for: PDF handout, email attachment, meeting leave-behind.

#### Demo Script (500-600 words)
Structure:
1. **Pre-demo checklist**: What to know about the prospect (role, pain, evaluation stage)
2. **Opening** (2 min): Connect prospect's stated challenge to TIPS trend (validates their concern)
3. **Demo flow** (3-4 segments, 5 min each):
   - Segment 1: Show how [feature] addresses [pain] → maps to IS/DOES/MEANS
   - Segment 2: Differentiation moment — what competitors can't do
   - Segment 3: ROI visualization — connect to business outcome
   - Segment 4: Implementation simplicity — from solution phases
4. **Closing**: Recap value, propose next step, handle live objections
5. **Follow-up template**: Email template for post-demo

Each segment includes: what to show, what to say, what to emphasize, what to avoid.

#### Objection Handler (300-400 words)
Structure — table format:
```
| Objection | Response | Evidence | When to use |
```

Generate 8-12 common objections sourced from:
- Portfolio competitor data (their strengths = our objections)
- Portfolio customer profiles (buying criteria = evaluation concerns)
- Solution pricing (budget objections)
- Implementation (complexity objections)
- Blueprint gaps (capability objections — be honest, offer roadmap)

Each response follows: Acknowledge → Reframe → Evidence → Redirect

#### Proposal Section (400-600 words)
A drop-in section for sales proposals covering this GTM path:
1. **Market context**: Why this matters now (TIPS trend + implication, 1 paragraph)
2. **Our approach**: Solution methodology (from portfolio solution phases)
3. **Deliverables**: What the customer gets (from solution/package scope)
4. **Investment overview**: Pricing tier summary (from packages)
5. **Why us**: Competitive differentiation (from compete data)
6. **Evidence**: Relevant metrics and claims

### Step 3: Write Output

Write to `content/sales-enablement/` with frontmatter.
For battle cards with multiple competitors, use: `{market}--{gtm-path}--battle-card--{competitor}.md`

Update `content-strategy.json`.

```
Generated: {format} ({word_count} words)
  File: content/sales-enablement/{filename}

Internal distribution:
  - Share battle cards with sales team via CRM or shared drive
  - Add proposal sections to proposal template library
  - Review objection handlers quarterly (competitors evolve)

Refresh triggers:
  - New competitor data → regenerate battle cards
  - Updated pricing → regenerate one-pagers and proposal sections
  - New TIPS pursuit → refresh trend context in all formats
```

## Quality Rules

- **Honesty about gaps**: Never claim capabilities the portfolio doesn't have. Blueprint gaps should be framed as "roadmap" or "partner ecosystem" — not hidden.
- **Sales-ready language**: These are scripts, not essays. Use bullet points, tables, and scannable formats. A salesperson glances at a battle card 5 minutes before a call.
- **Competitor respect**: Never disparage competitors. Frame as "different approach" not "inferior." Professional tone always.
- **Price sensitivity**: Include pricing ranges, not exact figures, unless brand config specifies otherwise. Proposals need flexibility.
