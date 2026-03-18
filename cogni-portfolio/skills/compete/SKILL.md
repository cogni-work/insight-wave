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
  "trap_questions": [
    "Question targeting a verifiable competitor gap — max 3-4 questions total"
  ],
  "created": "2026-01-25"
}
```

### 5. Stakeholder Review (Closed Loop)

After generating competitor files, run an automated review loop with two stakeholder perspectives before presenting to the user. This catches accuracy gaps, biased positioning, and weak trap questions before they reach the buyer conversation.

#### 5a. Invoke Reviewers

Launch two reviewer subagents **in parallel** for each competitor file:

1. **CSO Reviewer** (`tsystems-cso-reviewer`): Evaluates competitive intel from a sales effectiveness perspective — can an AE use this differentiation to win deals? Are trap questions usable in real evaluations? Does the competitive positioning give the account team ammunition?

2. **Market Industry Analyst** (`market-industry-analyst-reviewer`): Evaluates from an advisory accuracy perspective — are the right competitors identified? Is positioning accurate and current? Are strength/weakness claims balanced and evidence-based? Would the analysis survive peer review?

Pass the competitor file(s) **and** their parent proposition file(s) as context — reviewers need to understand what capability and market the competitive analysis targets.

#### 5b. Convergence Check

Both reviewers return scored assessments. The competitor file passes when:
- CSO average score >= 4.0 across all dimensions
- Analyst average score >= 4.0 across all dimensions
- No individual dimension scores below 3 from either reviewer
- CSO `would_use_in_pitch_deck` is true
- Analyst `would_use_in_advisory_report` is true

If thresholds are met: proceed to Step 6 (present to user).

#### 5c. Auto-Rewrite (if thresholds not met)

When the review loop detects failures:

1. **Synthesize feedback** from both reviewers into targeted rewrite instructions. Map failing dimensions to specific competitor file fields:
   - Low `competitive_win_ability` or `differentiation_defensibility` → rewrite `competitors[].differentiation`
   - Low `market_landscape_accuracy` or `segment_relevance` → re-research competitor selection, add missing players
   - Low `strength_weakness_balance` or `positioning_validity` → rewrite `competitors[].positioning`, `.strengths`, `.weaknesses`
   - Low `trap_question_sophistication` or `objection_handling` → rewrite `trap_questions`

2. **Re-invoke `competitor-researcher`** in revision mode with the synthesized feedback. The researcher targets specific entries for improvement rather than regenerating from scratch.

3. **Re-review** the updated competitor file with both reviewers.

4. **Max 3 iterations**. If convergence is not reached after 3 rounds, present the best-scoring version to the user with a summary of unresolved issues and the reviewer scores.

5. **Write convergence log** to `convergence.json` alongside the competitor file:
```json
{
  "converged": true,
  "reason": "passed",
  "iterations": [
    {"iteration": 0, "cso_avg": 3.67, "analyst_avg": 3.5, "combined_avg": 3.58, "passes": false},
    {"iteration": 1, "cso_avg": 4.17, "analyst_avg": 4.0, "combined_avg": 4.08, "passes": true}
  ],
  "rewrite_actions": ["what was fixed between each iteration"]
}
```

#### 5d. Present Results

After the review loop converges (or reaches max iterations):

- Show the user the final reviewer scores (CSO and Analyst averages, dimension breakdown)
- Highlight any remaining issues flagged by reviewers
- Note convergence path: "Initial score 3.2 → iteration 1: 3.8 → iteration 2: 4.2 (converged)"

### 6. Review with User

Present competitor analysis per proposition. The user may know competitors the research missed, or may disagree with positioning claims. Iterate until accurate.

## Trap Questions

For each competitor file, include a `trap_questions` array with **3-4 questions** designed to expose competitor weaknesses during an RFP evaluation or vendor comparison. Good trap questions:
- Target a specific, verifiable gap the competitor cannot close quickly (infrastructure ownership, certifications, reference customers)
- Are phrased as legitimate evaluation criteria, not gotcha tricks — a procurement team should be comfortable putting these in an RFI
- Cover different stakeholder concerns (security/compliance for CISO, operational continuity for OT, TCO for CFO)
- Would change the evaluation outcome if the competitor answers honestly

Do not generate more than 4 trap questions — focus beats volume. Each question should be a single sentence.

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
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md` for complete entity schemas

## Session Management

After completing competitive analysis across multiple propositions or when this skill runs after other heavy skills already consumed context in the same session, proactively check in with the user about starting fresh. Signs that a new session would improve quality:

- Competitor research completed for 5+ propositions
- Three or more different portfolio skills were already invoked this session
- The user asks about remaining context or capacity

When you notice these signals, first invoke `/portfolio-dashboard` to generate the portfolio dashboard — this gives the user a visual overview of everything accomplished so far. Then recommend a fresh session:

> "We got a lot done: [brief summary of accomplishments]. I've generated the dashboard so you can see the full picture. For the next steps like [recommend next skills], I'd suggest starting a fresh session — just use `/portfolio-resume` to pick up where we left off. That loads the current state cleanly without carrying the weight of this session."

Use the portfolio's communication language (read `portfolio.json` for the `language` field). Frame it as helpful advice for better output quality, not as a limitation. The key message: `/portfolio-resume` exists exactly for this — seamless multi-session workflows.
