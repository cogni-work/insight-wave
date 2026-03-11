---
title: One-Pagers
type: deliverable
category: deliverable-type
tags: [one-pager, marketing, sales, summary]
formality: medium
audience: [prospects, executives, stakeholders]
typical-length: exactly-1-page
recommended-frameworks: [psb, fab]
recommended-principles: [conciseness, visual-hierarchy]
related:
  - briefs
  - proposals
version: 2.0
last_updated: 2026-02-25
---

# One-Pagers

<context>
You are writing a one-pager: a single-page document that sells, summarizes, or positions a product, service, or initiative. One-pagers are the hardest deliverable to write well because the single-page constraint forces maximum information density while remaining scannable. Every word, every visual element, every whitespace decision must earn its place. The reader will spend 30-60 seconds on this document. In that window, they must understand the problem, grasp the solution, believe the value, and know what to do next.
</context>

## Quick Reference

**Purpose:** Single-page product/service/initiative summary that drives action
**Length:** Exactly 1 page (400-600 words, never exceed)
**Formality:** Medium
**Audience:** Prospects, executives, stakeholders
**Best frameworks:** PSB (pain-driven), FAB (feature-driven)
**Visual density:** 4-6 visual elements (bullets, tables, bold emphasis, callouts)
**Key constraint:** Must be graspable in 30-60 seconds by a scanning reader

## When to Use Each Framework

Think through framework selection before writing. The wrong framework wastes your page budget.

<decision_logic>
Choose PSB when:
- The reader knows they have a problem but has not seen your solution
- The sale is pain-driven (cost savings, risk reduction, time recovery)
- The audience is non-technical (executives, business stakeholders)
- You want an emotional hook leading into rational proof

Choose FAB when:
- The reader is evaluating multiple known solutions
- The product has strong technical differentiators
- The audience is technical or already educated on the problem space
- You want to showcase capabilities and translate them to business value

Choose hybrid PSB+FAB when:
- The audience is mixed (technical and business readers)
- You need a pain-driven opening but feature-level detail in the body
- Structure: PSB headline and challenge section, FAB for the solution section
</decision_logic>

## How to Write a One-Pager: Step by Step

Follow these steps in order. Each step builds on the previous one.

### Step 1: Define the Single Core Message

Before writing, answer this question in one sentence: "After reading this page, the reader should believe _____ and do _____."

If you cannot complete that sentence, the one-pager lacks focus. A one-pager that tries to cover two products, two audiences, or two asks will fail at all of them.

<example>
<description>Defining the core message</description>
<weak>"Learn about our analytics platform and its various capabilities."</weak>
<strong>"AnalyticsCo saves marketing teams 20 hours/week on reporting -- schedule a demo."</strong>
<reasoning>The weak version has no specific claim, no audience, and no action. The strong version names the audience, quantifies the value, and specifies the desired action.</reasoning>
</example>

### Step 2: Write the Headline

The headline is the most important line on the page. It must do three things simultaneously: name the audience or pain, state the value, and create urgency or curiosity.

<patterns>
**Pattern A: Quantified value proposition**
"Cut Reporting Time by 75% -- Unified Analytics for Marketing Teams"

**Pattern B: Problem-to-promise**
"Stop Wasting 20 Hours/Week on Manual Reports"

**Pattern C: Audience-specific outcome**
"For Marketing Leaders: One Dashboard, Every Metric, Real-Time"
</patterns>

<example>
<before>AnalyticsCo Platform Overview</before>
<after>Stop Wasting 20 Hours/Week on Manual Reports</after>
<reasoning>The before headline is descriptive but inert -- it tells the reader what the document is, not why they should care. The after headline names the specific pain (wasted time), quantifies it (20 hours/week), and implies a solution exists. A busy executive scanning a stack of one-pagers will stop on the second headline.</reasoning>
</example>

### Step 3: Build the Body Using Your Framework

#### PSB Structure (Recommended for most one-pagers)

```markdown
# [Headline: Quantified value or pain-driven promise]

## The Challenge
[2-3 sentences. Name the specific pain. Quantify the cost. Make the reader nod.]

## Our Solution
[2-3 sentences describing the approach, followed by 3-5 bullet points of key capabilities]
- Capability 1: [what it does + why it matters]
- Capability 2: [what it does + why it matters]
- Capability 3: [what it does + why it matters]

## Results You Can Expect
- [Metric 1]: [specific quantified outcome]
- [Metric 2]: [specific quantified outcome]
- [Metric 3]: [specific quantified outcome]

> "[Testimonial quote with specific result]" -- [Name, Title, Company]

## Get Started
[1-2 sentences. Single clear CTA with contact method or next action.]
```

#### FAB Structure (For feature-differentiation scenarios)

```markdown
# [Headline: Capability-driven value statement]

## Why It Matters
[2-3 sentences framing the market need or evaluation context]

## What Sets Us Apart

**[Feature 1 Name]**
[What it is] -> [Why it is better] -> [What you gain: quantified]

**[Feature 2 Name]**
[What it is] -> [Why it is better] -> [What you gain: quantified]

**[Feature 3 Name]**
[What it is] -> [Why it is better] -> [What you gain: quantified]

## The Bottom Line
[Summary table or 2-3 bullet total-value statement]

## Next Steps
[Single clear CTA]
```

### Step 4: Compress Ruthlessly

After drafting, your first version will be too long. Apply these compression techniques in order.

<compression_sequence>
1. **Delete throat-clearing.** Remove any sentence that says "we are excited to" or "this document will explain." Start with the substance.
2. **Convert prose to bullets.** Any sentence listing 3+ items becomes a bullet list.
3. **Replace paragraphs with tables.** Comparisons, before/after data, and multi-dimension information compress better as tables.
4. **Cut background context.** The reader either knows the background or does not need it for this document. If context is essential, compress it to one sentence.
5. **Merge redundant sections.** If the challenge section and the benefits section both mention "15 hours/week wasted," consolidate.
6. **Apply the filler-phrase substitution table** from `conciseness-principles.md`. One-pagers cannot afford "in order to" (use "to") or "due to the fact that" (use "because").
7. **Count words.** If over 600, cut further. If under 400, you likely have gaps in proof or specificity.
</compression_sequence>

### Step 5: Validate

Run through the validation checklist below before finalizing.

## Annotated Example: SaaS Product One-Pager (PSB)

This example demonstrates a complete one-pager with annotations explaining each decision.

```markdown
# Stop Wasting 20 Hours/Week on Manual Marketing Reports
  [HEADLINE: Pain-driven, quantified, audience-specific]

## The Challenge

Marketing teams juggle 8-12 analytics tools, manually pulling data
into spreadsheets every week. This costs 15-20 hours of analyst time,
delays campaign decisions by 3-5 days, and introduces errors that
erode confidence in the numbers.
  [CHALLENGE: 3 sentences. Specific pain (8-12 tools, manual pulling),
   quantified cost (15-20 hours, 3-5 days delay), emotional hook
   (eroded confidence)]

## How AnalyticsCo Solves This

AnalyticsCo connects to 50+ marketing platforms and delivers
unified dashboards with automated reporting in 30 minutes.

- **Unified data:** One dashboard for all channels, updated hourly
- **Automated reports:** Schedule and send without manual work
- **Smart alerts:** Get notified when metrics shift, not when you check
- **No-code setup:** Connect your tools in 30 minutes, no IT needed
  [SOLUTION: 1 intro sentence, 4 tight bullets. Each bullet names the
   capability and its immediate user benefit. "No-code setup" handles
   the objection "this will take months to implement."]

## Results You Can Expect

| Metric              | Before         | After           |
|---------------------|----------------|-----------------|
| Weekly report time  | 15-20 hours    | < 1 hour        |
| Decision speed      | 3-5 day lag    | Same-day        |
| Data accuracy       | Manual, error-prone | Automated, verified |
| Annual productivity | --             | $40K+ recovered |
  [BENEFITS: Table format compresses 4 metrics into scannable rows.
   Before/after creates contrast. Dollar value anchors the ROI.]

> "We cut reporting from 18 hours to 45 minutes in the first week.
> The data finally matches across teams."
> -- Maria Chen, VP Marketing, TechCorp
  [PROOF: Specific result, named person, real title. Short enough
   to not dominate the page.]

## See It in Action

Request a 15-minute demo: demo@analyticsco.com | (555) 234-5678
  [CTA: Single action, low commitment ("15-minute"), two contact
   methods. No competing CTAs.]
```

**Word count:** ~220 words of body text + table + quote = comfortably under 600 words when rendered on a single page with standard formatting.

## Common Mistakes and Fixes

### Mistake 1: Generic Pain Statement

The challenge section must be specific enough that the reader thinks "that is exactly my situation."

<example>
<before>Businesses today face challenges with data management and reporting efficiency.</before>
<after>Your marketing team spends 15-20 hours every week pulling data from 8 different tools into a spreadsheet that is outdated by the time it reaches leadership.</after>
<reasoning>The before version applies to every company on earth. The after version names the specific audience (marketing team), quantifies the pain (15-20 hours, 8 tools), describes the exact workflow (pulling into spreadsheets), and adds an emotional twist (outdated before it arrives).</reasoning>
</example>

### Mistake 2: Feature Lists Without Value Translation

Listing features without connecting them to outcomes wastes your limited page space.

<example>
<before>
- AI-powered analytics engine
- Real-time data processing
- Custom dashboard builder
- API integrations
</before>
<after>
- **Unified data:** One dashboard replaces 8 separate tools
- **Automated reports:** Eliminate 15 hours/week of manual compilation
- **Smart alerts:** Catch campaign issues in minutes, not days
- **30-minute setup:** No IT resources or coding required
</after>
<reasoning>The before list describes what the product has. The after list describes what the reader gains. Each bullet follows the pattern: bold label (capability) + plain text (outcome or value). The reader never has to ask "so what?"</reasoning>
</example>

### Mistake 3: Vague or Unquantified Benefits

Benefits without numbers are claims. Benefits with numbers are proof.

<example>
<before>
- Significant time savings
- Improved decision-making
- Better data accuracy
- Increased productivity
</before>
<after>
- Recover 15-20 hours/week ($40K+ annual productivity gain)
- Make campaign decisions same-day instead of 3-5 day lag
- Eliminate manual data errors with automated verification
- Achieve full ROI within first month of deployment
</after>
<reasoning>Every "after" bullet contains at least one specific number, time frame, or measurable outcome. "Significant time savings" could mean 5 minutes or 50 hours. "15-20 hours/week" is undeniable and comparable.</reasoning>
</example>

### Mistake 4: Multiple CTAs Competing for Attention

A one-pager gets one ask. Multiple CTAs create decision paralysis.

<example>
<before>
## Next Steps
- Schedule a demo
- Download our whitepaper
- Start a free trial
- Contact our sales team
- Visit our website for more information
</before>
<after>
## See It in Action
Request a 15-minute demo: demo@analyticsco.com | (555) 234-5678
</after>
<reasoning>Five options means the reader picks none. One option with low commitment ("15 minutes") and two easy contact methods removes friction. The section header "See It in Action" is more compelling than "Next Steps" because it implies value rather than obligation.</reasoning>
</example>

### Mistake 5: Wasting Space on Company Background

The one-pager is about the reader's problem, not your company history.

<example>
<before>
## About AnalyticsCo
Founded in 2019, AnalyticsCo is a leading provider of marketing analytics
solutions. With offices in San Francisco and London, we serve over 500
enterprise clients. Our mission is to democratize data-driven marketing.
</before>
<after>
> "We cut reporting from 18 hours to 45 minutes in the first week."
> -- Maria Chen, VP Marketing, TechCorp (one of 500+ enterprise clients)
</after>
<reasoning>The "About" section uses 45 words to say nothing the reader cares about. The testimonial uses 25 words to deliver proof (specific result), credibility (named person, title), and scale ("500+ enterprise clients") in a format that is far more persuasive than self-description.</reasoning>
</example>

## One-Pager Subtypes

Different contexts require adjusting the standard structure. Here is how to adapt.

### Product/Service One-Pager (most common)
- **Framework:** PSB or FAB
- **Focus:** What the offering does and why it matters to the buyer
- **Key section:** Benefits with quantified metrics
- **CTA:** Demo, trial, or sales conversation

### Internal Initiative One-Pager
- **Framework:** PSB (problem the initiative solves)
- **Focus:** Why this initiative deserves resources
- **Key section:** ROI calculation or strategic alignment argument
- **CTA:** Approval, budget allocation, or sponsorship

### Partnership/Investor One-Pager
- **Framework:** FAB (what makes this opportunity unique)
- **Focus:** Market opportunity, traction, and differentiation
- **Key section:** Traction metrics and market size
- **CTA:** Meeting request or next-stage conversation

### Competitive Comparison One-Pager
- **Framework:** FAB with comparison table
- **Focus:** Why you beat the alternatives
- **Key section:** Feature comparison table with outcome framing
- **CTA:** Evaluation or proof-of-concept

## Visual Element Strategy

One-pagers need 4-6 visual elements to achieve scannability within the page constraint. Think of visual elements as compression tools: they convey more information per square inch than prose.

<guidance>
**Required visual elements (include all of these):**
- Bullet lists for features, benefits, or capabilities (1-2 lists)
- Bold emphasis for key terms and metric labels
- Clear section headers (4-6 headers including the headline)

**Strongly recommended (include 1-2 of these):**
- A comparison table (before/after, feature matrix, or metric summary)
- A testimonial block quote with attribution
- A callout box for the single most important metric

**Avoid on one-pagers:**
- Numbered lists longer than 5 items (break into two lists or use a table)
- More than one block quote (takes too much vertical space)
- Code blocks (wrong audience for this deliverable)
- Section dividers (horizontal rules waste vertical space on a one-pager)
</guidance>

**See also:** [visual-elements.md](../03-formatting-standards/visual-elements.md) for full visual formatting reference.

## Space Budget

Use this allocation as a starting guide, then adjust based on content needs.

| Section | Word budget | Page fraction | Priority |
|---------|-------------|---------------|----------|
| Headline | 8-15 words | 5% | Critical -- reader decides to continue or not |
| Challenge / Context | 40-80 words | 15% | High -- establishes relevance |
| Solution / Features | 80-150 words | 30% | High -- the core offering |
| Benefits / Results | 60-120 words | 25% | Critical -- the reason to act |
| Proof (testimonial/data) | 20-40 words | 10% | High -- converts skeptics |
| CTA | 15-30 words | 5% | Critical -- drives the desired action |
| Whitespace and formatting | -- | 10% | Required -- prevents wall-of-text |

**Total:** 400-600 words. If your draft exceeds 600 words, the Challenge or Solution sections are the most likely places to cut.

## Validation Checklist

Before finalizing, verify every item. If any check fails, revise.

<checklist>
**Page constraint:**
- [ ] Total word count is 400-600 words
- [ ] Content fits on exactly one page when rendered with standard formatting
- [ ] No section can be deleted entirely without losing critical information (every section earns its place)

**Information density:**
- [ ] Headline names the audience or pain AND quantifies the value
- [ ] Challenge section is specific enough that the target reader self-identifies
- [ ] Every feature or capability bullet includes its outcome or value (no naked features)
- [ ] At least 3 benefits are quantified with specific numbers
- [ ] Proof element is present (testimonial, case study snippet, or data point)

**Scannability:**
- [ ] A reader scanning only headlines, bold text, and bullet labels grasps the core message
- [ ] 4-6 visual elements present (bullets, tables, bold, callouts)
- [ ] No paragraph exceeds 3 sentences
- [ ] No bullet point exceeds 2 lines

**Action orientation:**
- [ ] Exactly one CTA (not zero, not multiple)
- [ ] CTA specifies the action and provides contact method
- [ ] CTA has low perceived commitment (demo, conversation, trial -- not "sign a contract")

**Language quality:**
- [ ] "You/your" language dominates over "we/our" (customer-centric)
- [ ] Active voice throughout (no "costs will be reduced" -- use "you will reduce costs")
- [ ] No filler phrases (apply conciseness-principles.md Pass 1)
- [ ] No jargon without immediate plain-language payoff
</checklist>

## See Also

- **Frameworks:** `../02-messaging-frameworks/psb-framework.md`, `../02-messaging-frameworks/fab-framework.md`
- **Conciseness:** `../01-core-principles/conciseness-principles.md` (essential -- one-pagers demand extreme conciseness)
- **Visual formatting:** `../03-formatting-standards/visual-elements.md`
- **Related deliverable:** `proposals.md` (one-pagers often serve as the front door to a full proposal)
