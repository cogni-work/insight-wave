---
name: lead-generation
description: "Generate lead generation content (whitepapers, landing pages, email nurture sequences, webinar outlines, gated checklists) that converts interest into qualified leads using portfolio propositions and solutions. Use this skill when the user asks to 'create a whitepaper', 'landing page', 'email sequence', 'nurture campaign', 'webinar outline', 'gated content', 'lead magnet', 'lead gen', 'conversion content', or wants consideration-stage content designed to capture contact information — even if they don't say 'lead generation' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Lead Generation Content

## Purpose

Generate conversion-focused content that turns engaged prospects into qualified leads. Lead gen content provides deep value in exchange for contact information. It sits in the consideration stage — the prospect knows they have a problem (from awareness content) and is evaluating approaches.

## Prerequisites

- Marketing project with GTM paths configured
- Portfolio propositions and solutions populated for the target market
- Recommended: thought leadership + demand gen content exists (lead gen follows them in the funnel)

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug |
| gtm_path | Yes | GTM path theme ID |
| format | No | whitepaper, landing-page, email-nurture, webinar-outline, gated-checklist. If omitted, ask |

## Workflow

### Step 1: Load Context

1. Read `marketing-project.json` — brand, language, content defaults, CTA style
2. Read `content-strategy.json` — narrative angle (especially possibility_promise + solution_proof)
3. Load portfolio data heavily:
   - Propositions for this market: full IS/DOES/MEANS (the value argument)
   - Solutions: implementation phases, pricing tiers (for ROI framing)
   - Packages: bundled offerings (for tier-based CTAs)
   - Customer profiles: buyer personas, pain points, buying criteria
4. Load TIPS data: solution templates, readiness scores (for "what's possible" framing)

### Step 2: Generate Content

Delegate to **content-writer** agent:

#### Whitepaper (2500-4000 words)
Structure:
1. **Title page**: Title, subtitle, brand, date
2. **Executive summary** (200-300w): Problem → Approach → Key findings → CTA
3. **The challenge** (400-600w): Market problem using TIPS implication data. Data-heavy, persona-specific pain points from portfolio customers.
4. **The landscape** (400-600w): How the market is evolving. Use TIPS trend data + competitor landscape from portfolio.
5. **The approach** (600-800w): Methodology/framework for solving the challenge. Draw from portfolio solution phases WITHOUT naming the product. Position as thought leadership with embedded expertise.
6. **Evidence & results** (400-600w): Case study frameworks, ROI calculations from portfolio solution pricing, industry benchmarks from TIPS claims.
7. **Implementation roadmap** (300-400w): Practical steps, drawn from portfolio solution implementation phases. Generic enough to be useful, specific enough to show expertise.
8. **Conclusion + CTA** (200w): Summary + clear next step (consultation, demo, assessment).

Evidence: Heavy — 8-12 TIPS claims with sources. Every section should have at least one data point.
Tone: Brand voice +formal +detailed. Authoritative, not salesy.

#### Landing Page (300-400 words)
Structure:
1. **Headline** (max 10 words): Clear value proposition — what the visitor gets
2. **Subheadline** (max 20 words): How they get it
3. **3 bullet points**: Key takeaways from the gated asset
4. **Social proof line**: "Based on analysis of [N] industry trends" (from TIPS data) or reference case study
5. **Form description**: What info to collect (name, email, company, role)
6. **CTA button text**: Based on brand CTA style:
   - soft-ask: "Get the Guide"
   - direct: "Download Now"
   - value-exchange: "Get Your Free Copy"
7. **Below-fold**: Brief excerpt or table of contents from the gated asset

Output as markdown with HTML-semantic sections (for easy conversion to actual landing page).

#### Email Nurture Sequence (3-5 emails × 150-250 words each)
Structure per sequence:
1. **Email 1 — Delivery** (Day 0): Thank you + asset access link + 1 key insight teaser
2. **Email 2 — Value add** (Day 3): Additional insight related to the asset. Reference one TIPS trend not covered in the asset.
3. **Email 3 — Social proof** (Day 7): How others in their market are approaching this. Reference portfolio solution approach without hard sell.
4. **Email 4 — Soft offer** (Day 14): Invite to webinar, assessment, or consultation. Frame as "explore whether this applies to your situation."
5. **Email 5 — Direct offer** (Day 21): Clear CTA for demo/consultation. Include urgency element if appropriate.

Each email includes: subject line, preview text, body, CTA, P.S. line.
Tone: Brand voice +personal +direct. First person from a specific person (suggest: head of consulting or domain expert).

#### Webinar Outline (600-800 words)
Structure:
1. **Title + subtitle** (event listing ready)
2. **Registration page copy** (150w): Problem + promise + speaker credibility
3. **Agenda** (4-5 segments, 10-15 min each):
   - Segment 1: Market context (TIPS trends)
   - Segment 2: Deep dive on the challenge (TIPS implications)
   - Segment 3: Approach/framework (portfolio expertise)
   - Segment 4: Live demo or case walkthrough (portfolio solutions)
   - Segment 5: Q&A
4. **Speaker notes per segment**: Key points, transition phrases, data to show
5. **Polling questions**: 2-3 audience interaction points
6. **Post-webinar CTA**: Assessment offer, recording access, related whitepaper

#### Gated Checklist (500-700 words)
Structure:
1. **Title**: "The [N]-Point Checklist for [Outcome]"
2. **Introduction** (50w): Who this is for and what it helps assess
3. **Checklist items** (15-25 items): Grouped by category (3-5 groups). Each item is actionable and assessable (yes/no/partial).
4. **Scoring guide**: What score means (ready / needs work / critical gaps)
5. **CTA**: "Need help closing the gaps? Talk to our team."

Draw items from: portfolio solution phases (what good looks like), TIPS trends (what leading companies do), competitor differentiation (what separates leaders from laggards).

### Step 3: Write Output & Update

Write to `content/lead-generation/` with full frontmatter.
For email sequences, write as single file with email separators:
```markdown
<!-- Email 1: Delivery (Day 0) -->
...
<!-- Email 2: Value Add (Day 3) -->
...
```

Update `content-strategy.json`.

Display next steps:
```
Generated: {format} ({word_count} words)
  File: content/lead-generation/{filename}

Conversion funnel:
  ↑ Drive traffic with: /demand-gen --format linkedin-post (promote this asset)
  → Follow up with: /sales-enablement (for prospects who convert)
  ↓ Support sales with: /sales-enablement --format battle-card

Polish: cogni-publishing:copywriter {file_path}
```

## Quality Rules

- **Value-first**: The gated asset must deliver genuine insight. If a reader downloads it and feels tricked, the brand loses trust permanently.
- **No bait-and-switch**: The landing page promise must match the asset content exactly.
- **Persona-specific**: Use buyer language from portfolio customer profiles. A CTO and a CFO need different framings of the same solution.
- **ROI-anchored**: Lead gen content should help the reader build an internal business case. Include calculation frameworks, not just claims.
