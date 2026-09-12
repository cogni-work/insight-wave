---
name: abm
description: "Generate account-based marketing content (account plans, personalized email sequences, executive briefings) tailored to specific named accounts using portfolio customer data and TIPS strategic themes. Use this skill when the user asks to 'create an account plan', 'personalized outreach', 'ABM content', 'executive briefing', 'account-based', 'target specific account', 'personalized campaign', 'named account marketing', or wants content tailored to individual companies or decision-makers — even if they don't say 'ABM' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Account-Based Marketing Content

## Purpose

Generate hyper-personalized content for specific named accounts. ABM content spans the full funnel — from awareness through decision — but is customized to one company's situation, challenges, and decision-makers. It's the highest-effort, highest-conversion content type.

## Prerequisites

- Marketing project with GTM paths configured
- Portfolio customer profiles with named accounts (`customers/{market}.json` → `named_customers[]`)
- Recommended: portfolio propositions and solutions exist for the target market

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| market | Yes | Market slug |
| account | Yes | Named account slug or company name |
| gtm_path | No | GTM path theme ID (if omitted, recommend based on account fit) |
| format | No | account-plan, personalized-email, executive-briefing, custom-landing-page. If omitted, ask |

## Workflow

### Step 1: Load Account Context

1. Read `marketing-project.json` — brand, language
2. Load portfolio customer data for this market:
   - Named account details: company name, size, industry, known contacts
   - Buyer profiles: roles, seniority, pain points, buying criteria
3. Load portfolio propositions and solutions for this market
4. Load TIPS data: strategic themes and trend relevance
5. **Account research** (delegate to content-writer agent with web research):
   - Company website: recent news, press releases, annual reports
   - LinkedIn: key decision-maker profiles and recent posts
   - Industry news: recent challenges or initiatives
   - Technology signals: job postings, tech stack indicators

### Step 2: Account-GTM Fit Assessment

If GTM path not specified, analyze which themes are most relevant to this account:
- Match account industry/challenges to TIPS theme narratives
- Cross-reference with portfolio propositions (which solutions fit their profile)
- Present recommendation:
```
Recommended GTM paths for {account_name}:
  1. AI-Driven Predictive Maintenance — HIGH fit (they posted 3 maintenance engineer roles last month)
  2. Cloud-Native Transformation — MEDIUM fit (still on-premises based on job postings)
```

### Step 3: Generate Content

#### Account Plan (800-1000 words)
Structure:
1. **Account overview**: Company profile, size, industry, key metrics (from web research)
2. **Strategic context**: What challenges this account faces (mapped to TIPS themes)
3. **Stakeholder map**: Known contacts + likely decision-making unit (from portfolio buyer profiles + LinkedIn research)
4. **Value hypothesis**: Which propositions (IS/DOES/MEANS) resonate most, mapped to specific stakeholder pain points
5. **Competitive landscape**: Who else is likely in the deal (from portfolio compete data + account-specific research)
6. **Engagement strategy**: Touch sequence across stakeholders
   - Executive sponsor: executive briefing → thought leadership share → CxO dinner invite
   - Technical evaluator: whitepaper → webinar → demo → PoV
   - Procurement: one-pager → pricing → reference call
7. **Content requirements**: Which marketing assets to create/customize for this account
8. **Timeline**: 90-day engagement plan with milestones
9. **Success metrics**: What "progress" looks like (meeting booked, PoV agreed, etc.)

#### Personalized Email Sequence (3-5 emails × 150-250 words)
Structure:
1. **Email 1 — Insight share** (Day 0): Share a relevant TIPS trend insight connected to their specific situation. Reference something specific about their company (recent news, job posting, annual report).
2. **Email 2 — Peer perspective** (Day 5): How similar companies in their market are approaching this challenge. Reference portfolio market data without naming other clients.
3. **Email 3 — Value offer** (Day 12): Offer something genuinely useful — assessment, benchmark, whitepaper. Frame around their specific pain.
4. **Email 4 — Executive touch** (Day 20): Different angle, higher-level. Focus on business impact, reference industry trends at CxO level.
5. **Email 5 — Direct ask** (Day 30): Clear meeting request. Reference all previous touchpoints. Specific calendar link or time proposal.

Each email: subject line (personalized), preview text, body (reference company by name), CTA, sender (specific person, not brand).

#### Executive Briefing (400-500 words)
Structure:
1. **Title**: "{Account Name} — Strategic Technology Briefing: {Theme}"
2. **Their context** (1 paragraph): What we understand about their situation (researched)
3. **Market dynamics** (1 paragraph): TIPS trends affecting their industry specifically
4. **Opportunity** (1 paragraph): How leading companies in their segment are responding (TIPS possibilities)
5. **Our perspective** (1 paragraph): Relevant portfolio expertise, without hard selling
6. **Discussion points**: 3-5 questions designed to uncover needs and build dialogue
7. **Prepared by**: Author name, title, contact

This is a meeting prep document — designed to be read in 3 minutes before a CxO meeting.

#### Custom Landing Page (300-400 words)
Account-specific landing page copy:
1. **Headline**: "{Account Name}, here's how [peers] are solving [their challenge]"
2. **Personalized intro**: Reference their specific situation
3. **3 relevant assets**: Curated from existing content, matched to their needs
4. **CTA**: Book a personalized assessment/briefing

### Step 4: Write Output

Write to `content/abm/{market}--{account-slug}--{format}.md` with frontmatter.

Additional frontmatter for ABM:
```yaml
account:
  name: "Acme Manufacturing GmbH"
  slug: "acme-manufacturing"
  contacts: ["CTO: Dr. Weber", "VP Engineering: Müller"]
  research_date: 2026-03-14
```

Update `content-strategy.json`.

```
Generated: {format} for {account_name}
  File: content/abm/{filename}

Next steps:
  - Review account research accuracy before sending
  - Personalize further with account-specific case study: /lead-gen --format whitepaper
  - Turn into an arc narrative and a Claude Design slides brief: /cogni-workspace:text-to-narrative {file_path} --target slides
  - Add to CRM as activity
```

## Quality Rules

- **Accuracy over speed**: ABM content MUST be factually correct about the target account. Wrong company facts = instant credibility loss. Always flag research as "as of {date}" and recommend human review.
- **No assumptions**: If you can't find specific account information, say "based on market patterns" not "your company does X."
- **Privacy-conscious**: Use only publicly available information. Don't reference private data, leaked documents, or personal details beyond professional LinkedIn profiles.
- **Genuine value**: Every touchpoint must offer something useful — an insight, a framework, a benchmark. Pure outreach without value is spam, not ABM.
