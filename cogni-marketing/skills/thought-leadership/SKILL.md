---
name: thought-leadership
description: "Generate thought leadership content (blog posts, LinkedIn articles, keynote abstracts, podcast outlines, op-eds) that positions the brand as an industry expert using TIPS trend data and portfolio domain authority. Use this skill when the user asks to 'create thought leadership', 'write a blog post about a trend', 'LinkedIn article', 'keynote abstract', 'thought leadership content', 'expert positioning', 'trend article', 'write about [industry trend]', or wants awareness-stage content grounded in strategic trend analysis — even if they don't say 'thought leadership' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Thought Leadership Content Generation

## Purpose

Generate expert-positioning content that leverages TIPS trend analysis (WHY NOW) and portfolio authority (WHAT WE KNOW) to establish the brand as a trusted voice. Thought leadership lives at the top of funnel — it educates, provokes, and builds credibility without hard selling.

## Prerequisites

- Marketing project with at least one GTM path configured
- Content strategy recommended (but not required — can generate ad-hoc)

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug (determines language, persona, proposition context) |
| gtm_path | Yes | GTM path theme ID (determines trend narrative) |
| format | No | Specific format: blog, linkedin-article, keynote-abstract, podcast-outline, op-ed. If omitted, ask user |

## Workflow

### Step 1: Load Context

1. Read `marketing-project.json` — extract brand voice, tone modifiers, content defaults, language
2. Read `content-strategy.json` — find the narrative angle for this market × GTM path cell
3. Load TIPS data for the GTM path:
   - Strategic theme narrative (from `tips-value-model.json`)
   - Top 3 trend candidates in the theme's value chains (from `trend-scout-output.json`)
   - Relevant claims with evidence (from `tips-trend-report-claims.json`)
4. Load portfolio context:
   - Propositions for this market (IS/DOES/MEANS — for domain authority, not sales pitch)
   - Company positioning (from `portfolio.json`)
5. **Optional enrichment**: If `sources.enriched_portfolio_narratives` exists in `marketing-project.json`, read the market-level customer narrative for this market. Use it as a voice and messaging reference — it contains pre-written audience-tailored language that helps maintain consistency between portfolio communication and marketing content. Do not copy verbatim; use it to inform tone and framing.

### Step 2: Select Format

If format not specified, present options with recommendations:
```
Thought leadership formats for {market} × {gtm_path}:
  1. blog (800-1200w) — Recommended as anchor content
  2. linkedin-article (600-800w) — Good for professional reach
  3. keynote-abstract (150-200w) — If speaking engagement planned
  4. podcast-outline (400-500w) — If podcast channel active
  5. op-ed (600-800w) — If publishing in industry media
```

### Step 3: Generate Content

Delegate to **content-writer** agent with these instructions per format:

#### Blog Post (800-1200 words)
Structure:
1. **Hook** (1 paragraph): Start with the trend's most surprising data point or provocative claim. Reference TIPS claim with source.
2. **Context** (2-3 paragraphs): Explain the trend landscape. Use TIPS T→I narrative arc — what's happening and what it means for the reader's business.
3. **Insight** (2-3 paragraphs): The brand's unique perspective. Draw from portfolio domain expertise WITHOUT pitching products. Show thinking, not selling.
4. **Implications** (2-3 paragraphs): What should the reader do? Use TIPS I→P narrative — from implication to possibility.
5. **Forward look** (1 paragraph): Where is this heading? Reference TIPS horizon data (act/plan/observe).
6. **CTA** (1 line): Soft — "Follow for more insights" or "Download our [related whitepaper]" based on brand CTA style.

Tone: Brand voice + thought-leadership modifiers (+educational, +engaging).
Evidence: Embed 3-5 TIPS claims with sources inline. Mark unverified claims.
Language: Generate in project language. Preserve technical terms per language rules.

#### LinkedIn Article (600-800 words)
Structure:
1. **Opening hook** (1-2 sentences): Bold claim or question that stops the scroll
2. **Trend context** (2 paragraphs): Concise version of TIPS trend narrative
3. **Expert take** (2-3 paragraphs): Brand's unique insight — what others are missing
4. **Practical takeaway** (1 paragraph): One actionable insight the reader can use immediately
5. **Engagement prompt**: Question to the audience ("What's your experience with...?")

Tone: Brand voice + social modifiers (+conversational for LinkedIn).
No hard CTA — this is brand building.

#### Keynote Abstract (150-200 words)
Structure:
1. **Title**: Provocative, memorable (max 10 words)
2. **Abstract**: Problem → Insight → Promise format
3. **Key takeaways**: 3 bullet points
4. **Speaker bio context**: 1 sentence connecting speaker to topic

#### Podcast Outline (400-500 words)
Structure:
1. **Episode title + subtitle**
2. **Hook question** (the central debate)
3. **Segment plan** (3-4 segments with talking points)
4. **Key data points** to reference (from TIPS claims)
5. **Guest suggestions** (based on market/industry)
6. **Listener CTA**

#### Op-Ed (600-800 words)
Structure:
1. **Provocative thesis** (1 paragraph): Contrarian or forward-looking claim
2. **Evidence** (2-3 paragraphs): Data and examples supporting the thesis
3. **Counter-argument** (1 paragraph): Acknowledge the opposing view
4. **Resolution** (1-2 paragraphs): Why the thesis holds — with nuance
5. **Call to industry** (1 paragraph): What should change?

### Step 4: Write Output

Write the generated content to:
```
cogni-marketing/{project}/content/thought-leadership/{market}--{gtm-path}--{format}.md
```

Apply frontmatter per data model schema. Include:
```yaml
---
type: thought-leadership
format: blog
market: mid-market-saas-dach
gtm_path: ai-predictive-maintenance
funnel_stage: awareness
language: de
brand_voice: "authoritative, data-driven, forward-looking +educational +engaging"
sources:
  tips_theme: "AI-Driven Predictive Maintenance"
  tips_claims: ["claim_EE_003", "claim_NH_007", "claim_DW_012"]
  portfolio_propositions: ["predictive-analytics--mid-market-saas-dach"]
word_count: 1050
status: draft
created: 2026-03-14
---
```

### Step 5: Review & Polish Recommendation

After generating, display:
```
Content generated: {format} ({word_count} words)
  File: content/thought-leadership/{filename}
  Evidence: {claim_count} TIPS claims embedded
  Language: {language}

Optional next steps:
  - Polish with cogni-copywriting: /copywriter {file_path}
  - Transform into narrative arc: /narrative {file_path}
  - Generate derivative LinkedIn post: /demand-gen --market {m} --gtm-path {g} --format linkedin-post
  - Create visual brief: /cogni-visual:story-to-slides {file_path}
```

Update `content-strategy.json` — increment `pieces_generated` for this cell.

## Anti-Patterns

- **NO product pitching**: Thought leadership educates, it doesn't sell. If a sentence reads like ad copy, rewrite it as insight.
- **NO generic AI content**: Every claim must trace to a specific TIPS trend or portfolio expertise. Generic "digital transformation is important" sentences are banned.
- **NO unattributed statistics**: Every number needs a TIPS claim reference or explicit source.
- **NO conclusion-first for blogs**: Use narrative arc (hook → tension → insight → resolution), not BLUF. BLUF is for internal docs.
