---
name: compete
description: |
  Analyze competitors for portfolio propositions — competitive landscape,
  battle cards, positioning, differentiation. Use whenever the user mentions
  competitors, competitive analysis, "who else does this", SWOT, win/loss,
  how a proposition stacks up, or wants to understand competitive positioning
  in a market — even if they don't say "compete" explicitly.
---

# Competitive Analysis

Analyze the competitive landscape for each proposition (Feature x Market combination). Competitors are proposition-specific because the same feature competes against different players in different markets.

## Core Concept

Competitive analysis is scoped to propositions, not features or markets alone. A "cloud monitoring" feature may compete against Datadog in mid-market SaaS but against Splunk in enterprise fintech. The competitive positioning and differentiation are always market-dependent.

## Workflow

### 1. Select Propositions to Analyze

List existing propositions (read the `propositions/` directory in the project root) and identify those without corresponding competitor files in `competitors/`. If no propositions exist yet, tell the user they need to create propositions first (via the `propositions` skill) before competitive analysis can begin.

Present options to the user:

- Analyze all pending propositions
- Analyze a specific proposition
- Analyze all propositions for a specific market

### 2. Research Competitors

For each selected proposition, identify 3-5 relevant competitors. Two modes:

**Web research (default)**: Use the Agent tool to delegate to the `competitor-researcher` agent, which searches for:
- Companies offering similar capabilities in this market
- Recent competitive moves, pricing changes, product launches
- Market analyst reports and comparisons

Multiple agents can be launched in parallel for different propositions.

**LLM knowledge (fallback)**: When web search is unavailable, identify known competitors based on the feature category and market segment. Clearly note that competitor data is based on training knowledge and may not reflect latest positioning.

### 3. Structure Competitor Analysis

For each competitor, capture:

- **Name**: Company or product name
- **Positioning**: 1 sentence — their stated value proposition for this market
- **Strengths**: Max 5 items, 1 phrase each
- **Weaknesses**: Max 5 items, 1 phrase each
- **Differentiation**: 1 sentence — how the user's proposition is specifically different/better

### 4. Write Competitor Entities

Write to `competitors/{feature-slug}--{market-slug}.json` (same slug as the proposition):

```json
{
  "slug": "cloud-monitoring--mid-market-saas",
  "proposition_slug": "cloud-monitoring--mid-market-saas",
  "competitors": [
    {
      "name": "Datadog",
      "source_url": "https://example.com/datadog-review",
      "positioning": "Full-stack observability for cloud-scale companies",
      "strengths": ["Brand recognition", "Broad integrations"],
      "weaknesses": ["Expensive at scale", "Overkill for mid-market"],
      "differentiation": "40% lower cost, deploys in hours vs. weeks, purpose-built for mid-market."
    }
  ],
  "created": "2026-01-25"
}
```

### 5. Review with User

Present competitor analysis per proposition. The user may know competitors the research missed, or may disagree with positioning claims. Iterate until accurate.

## Differentiation Guidelines

Strong differentiation statements:
- Reference a specific weakness of the competitor
- Connect to the proposition's DOES or MEANS statement
- Are verifiable or at least defensible
- Avoid generic claims ("better", "faster", "cheaper" without specifics)

## Important Notes

- Competitor files share the same slug as their parent proposition
- One competitor file per proposition, containing an array of all competitors
- Competitive intelligence ages quickly -- note the date of analysis
- The competitor-researcher agent automatically submits verifiable claims (pricing, market share, positioning quotes) to the claims workspace for downstream verification
- **Content Language**: Read `portfolio.json` in the project root. If a `language` field is present, generate all user-facing text content (positioning, strengths/weaknesses, differentiation statements) in that language. JSON field names and slugs remain in English. If no `language` field is present, default to English.
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. Default to English if no `language` field is present.
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md` for complete entity schemas

## Session Management

After completing competitive analysis across multiple propositions or when this skill runs after other heavy skills already consumed context in the same session, proactively check in with the user about starting fresh. Signs that a new session would improve quality:

- Competitor research completed for 5+ propositions
- Three or more different portfolio skills were already invoked this session
- The user asks about remaining context or capacity

When you notice these signals, first invoke `/dashboard` to generate the portfolio dashboard — this gives the user a visual overview of everything accomplished so far. Then recommend a fresh session:

> "We got a lot done: [brief summary of accomplishments]. I've generated the dashboard so you can see the full picture. For the next steps like [recommend next skills], I'd suggest starting a fresh session — just use `/resume-portfolio` to pick up where we left off. That loads the current state cleanly without carrying the weight of this session."

Use the portfolio's communication language (read `portfolio.json` for the `language` field). Frame it as helpful advice for better output quality, not as a limitation. The key message: `/resume-portfolio` exists exactly for this — seamless multi-session workflows.
