---
name: demand-generation
description: "Generate demand generation content (SEO articles, LinkedIn posts, carousels, video scripts, infographic specs) that drives awareness and interest using trend hooks and portfolio value propositions. Use this skill when the user asks to 'create social media content', 'LinkedIn post', 'write a social post', 'SEO article', 'carousel', 'video script', 'infographic', 'demand gen', 'social content', 'promote blog', or wants high-frequency channel content to drive traffic and engagement — even if they don't say 'demand generation' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Demand Generation Content

## Purpose

Generate high-frequency, channel-optimized content that drives awareness and interest. Demand gen content bridges thought leadership (insight) and lead generation (conversion). It takes the trend hooks and proposition value messages and adapts them for social, search, and visual channels.

## Prerequisites

- Marketing project with GTM paths configured
- Recommended: anchor thought leadership content exists (to derive from)

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug |
| gtm_path | Yes | GTM path theme ID |
| format | No | linkedin-post, seo-article, carousel, video-script, infographic-spec. If omitted, ask |

## Workflow

### Step 1: Load Context

1. Read `marketing-project.json` — brand voice, content defaults, language
2. Read `content-strategy.json` — narrative angle, planned formats
3. Load TIPS data: trend hook + implication tension (awareness/consideration angles)
4. Load portfolio: propositions for this market (DOES/MEANS statements — the value message)
5. Check for existing thought leadership content in this cell — derive from it if available
6. **Optional enrichment**: If `sources.enriched_portfolio_narratives` exists in `marketing-project.json`, read the market-level customer narrative for this market. Use it as a messaging reference for value language and buyer framing — it reflects how the portfolio speaks to this market's buyers. Do not copy verbatim; adapt for channel-specific tone.

### Step 2: Generate Content

Delegate to **content-writer** agent with format-specific instructions:

#### LinkedIn Post (200-300 words)
Structure:
1. **Hook line** (first line visible in feed — must stop the scroll): Question, bold statement, or surprising stat
2. **Body** (8-12 lines): Short paragraphs (1-2 sentences each). Use line breaks for readability. Mix insight with practical value.
3. **Engagement driver**: Question or call for opinions
4. **Hashtags**: 3-5 relevant industry hashtags

Rules:
- No links in body (LinkedIn suppresses reach). Link in first comment only.
- Use the implication tension as the emotional driver
- End with a question to drive comments
- Emoji OK if brand allows — max 2-3, used structurally (bullet replacement)

#### SEO Article (1000-1500 words)
Structure:
1. **Title**: Include primary keyword, max 60 characters
2. **Meta description**: 155 characters, include keyword + value proposition
3. **H1**: Match title
4. **Introduction** (100-150w): Problem statement + what reader will learn
5. **H2 sections** (3-5 sections, 200-300w each): Each covers a subtopic. Use TIPS data for trend context, portfolio DOES statements for solution angles.
6. **Key takeaways** (bulleted summary)
7. **CTA**: Link to gated asset (whitepaper, webinar) or contact form

Delegate keyword research to **seo-researcher** agent if no existing research. Agent should:
- Identify primary keyword (search volume, difficulty)
- Identify 3-5 secondary keywords
- Check competitor content for this keyword
- Suggest content angle that differentiates

#### Carousel (8 slides × 30 words each)
Structure:
1. **Slide 1 — Hook**: Bold claim or question (large text)
2. **Slides 2-6 — Content**: One insight per slide. Use TIPS T→I→P progression. Each slide = one idea, max 30 words.
3. **Slide 7 — Summary**: Key takeaway
4. **Slide 8 — CTA**: "Follow for more" / "Link in comments" / "Download the guide"

Output as markdown with slide separators:
```markdown
<!-- Slide 1 -->
## [Hook text]

<!-- Slide 2 -->
### [Insight 1]
[Supporting text — max 30 words]
```

Include visual direction notes per slide (color, layout suggestion).

#### Video Script (90 seconds / 225 words)
Structure:
1. **[0-10s] Hook**: Attention-grabbing question or statement
2. **[10-40s] Problem**: The implication tension — what's at stake
3. **[40-70s] Solution angle**: The possibility + how it works (not product pitch)
4. **[70-85s] Proof point**: One compelling data point or example
5. **[85-90s] CTA**: "Learn more at..." or "Link in description"

Include: speaker notes, B-roll suggestions, text overlay cues.

#### Infographic Spec (300-400 words)
Not the visual itself — a creative brief for design:
1. **Title + subtitle**
2. **Data points**: 5-7 key statistics from TIPS claims
3. **Flow**: Visual narrative arc (problem → insight → solution)
4. **Section descriptions**: What each section should show
5. **Brand application**: Colors, fonts, logo placement per visual_direction
6. **Dimensions**: Standard sizes (1080×1080 social, 800×2000 blog embed)

### Step 3: Batch Generation

When generating multiple posts (e.g., "4 LinkedIn posts for this GTM path"):
- Vary the angle: each post uses a different value chain or claim from the theme
- Vary the hook type: question, statistic, bold claim, story opener
- Delegate each to a separate **content-writer** agent for parallel generation
- Number files: `{market}--{gtm-path}--linkedin-post-01.md`, `-02.md`, etc.

### Step 4: Write Output & Update Strategy

Write content to `content/demand-generation/` with full frontmatter.
Update `content-strategy.json` piece counts.

Display:
```
Generated: {count} × {format}
  Files: content/demand-generation/{filenames}

Derivatives available:
  - Adapt to other channels: /demand-gen --format carousel (from this blog)
  - Create lead gen follow-up: /lead-gen --market {m} --gtm-path {g}
  - Polish copy: /copywriter {file_path}
```

## Channel Best Practices

- **LinkedIn**: Personal > company page for reach. Write as person, not brand.
- **SEO**: One primary keyword per article. Internal link to related thought leadership.
- **Carousel**: Teach something — carousels with educational content get 3x engagement.
- **Video**: First 3 seconds decide watch/scroll. Lead with the most surprising fact.
