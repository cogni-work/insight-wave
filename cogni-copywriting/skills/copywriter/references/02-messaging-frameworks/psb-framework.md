---
title: PSB Framework (Problem-Solution-Benefit)
type: messaging-framework
category: communication-framework
tags: [psb, marketing, sales, customer-facing, pain-points]
audience: [prospects, customers, external]
best-for: [one-pagers, proposals, marketing-content, sales-collateral]
origin: marketing
formality: medium
related:
  - fab-framework
  - scqa-framework
  - star-framework
version: 2.0
last_updated: 2026-02-25
---

# PSB Framework (Problem-Solution-Benefit)

## Quick Reference

- **Structure:** Problem --> Solution --> Benefit
- **Best for:** One-pagers, proposals, marketing content, sales collateral
- **When to use:** Customer-facing content where the audience already feels a pain point
- **Formality:** Medium
- **Core principle:** Start with the reader's pain. Show how you fix it. Prove the value they gain.

## What PSB Does

PSB is a persuasion framework that structures content around a three-step emotional and logical arc:

1. **Problem** -- Name the reader's pain so they feel understood
2. **Solution** -- Present your offering as the direct answer
3. **Benefit** -- Quantify the value so the reader is motivated to act

The framework works because it mirrors how people make buying decisions: "I have a problem" --> "This thing solves it" --> "The payoff is worth it."

## How to Apply PSB: Step-by-Step

When you receive a request to write content using the PSB framework, follow these steps in order.

### Step 1: Identify and Articulate the Problem

Think through what specific pain the target audience experiences. Then write it so the reader immediately recognizes their own situation.

**Requirements for a strong Problem statement:**
- Name a specific, concrete pain -- not a category of pain
- Quantify the cost (time, money, opportunity, risk) whenever possible
- Use second-person ("you") to make it personal
- Include emotional resonance -- frustration, fear, missed opportunity
- Show urgency: why this matters *now*

**Problem quality test -- ask yourself:**
- Would the reader nod and say "yes, that is exactly my situation"?
- Is there a number attached (hours, dollars, percentage)?
- Does it feel specific to this audience, not generic to any business?

If any answer is no, rewrite the Problem before continuing.

<example>
<input>
Product: Automated code review tool
Audience: Engineering managers at mid-size companies
</input>

<bad_output>
Problem: Code reviews are slow and inefficient.
</bad_output>
<why_bad>Generic. No specifics. No quantification. No emotional hook. Could apply to any process in any industry.</why_bad>

<good_output>
Problem: Your code review process creates 3-5 day release delays. Reviews pile up in queues, engineers context-switch between writing and reviewing, and quality still suffers despite the time investment. Last quarter, your team shipped 40% fewer features than planned -- and your best engineers are frustrated.
</good_output>
<why_good>Specific pain (3-5 day delays). Quantified impact (40% fewer features). Emotional resonance (frustrated engineers). The reader sees themselves in the description.</why_good>
</example>

### Step 2: Present the Solution

Connect your offering directly to the Problem you just described. Every claim in the Solution must map back to a pain point from Step 1.

**Requirements for a strong Solution statement:**
- Open by directly addressing the core problem (not with a company introduction)
- Explain *how* it works, not just *what* it is
- Keep it concrete -- name specific mechanisms, not abstract capabilities
- Include proof of feasibility (integration time, setup effort, compatibility)
- Stay focused: only describe aspects that solve the stated Problem

**Coherence test:** Draw a line from each Problem pain point to the Solution element that addresses it. If any pain point lacks a corresponding solution element, add one. If any solution element lacks a corresponding pain point, remove it or add the missing pain point.

<example>
<input>
Continuing the code review tool example above.
</input>

<bad_output>
Solution: CodeReview Pro is an AI-powered platform with advanced algorithms and a modern interface that transforms your development workflow.
</bad_output>
<why_bad>Leads with product name (company-centric). "AI-powered" and "advanced algorithms" are vague features. "Modern interface" does not connect to any stated problem. "Transforms your development workflow" is meaningless.</why_bad>

<good_output>
Solution: CodeReview Pro automates routine code checks (style, security, complexity) so your engineers only review logic and architecture decisions. It assigns reviewers based on code-area expertise and enforces 24-hour SLAs with automatic escalation. Integrates with GitHub and GitLab in under 10 minutes -- no migration, no workflow disruption.
</good_output>
<why_good>Each element maps to a stated pain: automated checks address quality-despite-time-investment, smart assignment addresses context-switching, SLAs address queue pile-up, fast integration addresses feasibility concerns.</why_good>
</example>

### Step 3: Quantify the Benefit

Translate the Solution into measurable outcomes the reader cares about. Benefits are not features restated -- they are the *results* the reader experiences after adopting the solution.

**Requirements for strong Benefit statements:**
- Quantify with specific metrics: percentages, dollar amounts, time saved, rates improved
- Use the formula: [Action verb] + [metric] + by [amount] + ([dollar/time equivalent])
- Connect each benefit back to a pain point from the Problem
- Include both primary benefits (direct outcomes) and secondary benefits (downstream effects)
- Order benefits from most impactful to least impactful

**Benefit quality test:** Could a CFO put these numbers in a business case? If the benefit is too vague for a spreadsheet, make it more specific.

<example>
<bad_output>
Benefit: Save time on code reviews and ship faster with better quality.
</bad_output>
<why_bad>No numbers. "Save time" and "ship faster" and "better quality" are all unquantified. A CFO cannot act on this.</why_bad>

<good_output>
Benefit: Cut average review cycle from 72 hours to 18 hours (75% reduction). Double your release frequency from biweekly to weekly. Maintain a 1.2% defect escape rate -- better than your current 2.8% despite faster throughput. Engineering teams report 35% higher satisfaction scores. ROI positive within the first month at current team size.
</good_output>
<why_good>Every benefit is quantified. Maps to original pains (delay, quality, frustration). Includes both primary (speed, quality) and secondary (satisfaction, ROI) benefits. A CFO could put these in a spreadsheet.</why_good>
</example>

## Coherence: The Critical Quality Check

The most common failure in PSB content is a broken chain -- the Problem, Solution, and Benefit do not connect logically.

Before finalizing any PSB content, verify the chain:

```
For each pain point in Problem:
  - Does Solution contain a specific mechanism that addresses this pain? [yes/no]
  - Does Benefit contain a quantified outcome from resolving this pain? [yes/no]

For each element in Solution:
  - Does it address a pain stated in Problem? [yes/no]
  - If no --> either add the pain to Problem or remove the element

For each metric in Benefit:
  - Can you trace it back through Solution to Problem? [yes/no]
  - If no --> the benefit is disconnected and should be reworked
```

If any link is broken, fix it before delivering the content.

## Adapting PSB to Deliverable Types

### One-Pagers

- **Problem:** 2-3 sentences. Lead with the most painful quantified impact. Use emotional language.
- **Solution:** 3-5 bullet points of key mechanisms. Include one proof point (integration time, setup effort).
- **Benefit:** 3-5 bullet points, each with a metric. Bold the numbers.
- **Add:** A headline that names the pain, a clear CTA at the bottom, optional testimonial quote.
- **Length:** Single page. Every word must earn its place.

### Proposals

- **Problem:** 1-2 paragraphs demonstrating deep understanding of the client's specific situation. Reference their data, their market, their competitors.
- **Solution:** 2-3 pages detailing your approach, methodology, timeline, and team.
- **Benefit:** Full ROI calculation with before/after comparison. Include case studies from similar clients.
- **Add:** Pricing section, implementation timeline, risk mitigation, next steps.
- **Length:** Determined by scope. The PSB structure organizes the argument even across 20+ pages.

### Marketing Content (Landing Pages, Emails, Ads)

- **Problem:** Headline + 1 paragraph. The headline is the hook -- make it visceral.
- **Solution:** 2-3 paragraphs with feature highlights. Use visuals, screenshots, or diagrams.
- **Benefit:** Bullet list with metrics + customer testimonials as proof.
- **Add:** Social proof (logos, numbers), demo or trial CTA, urgency element.
- **Length:** Varies by format. Prioritize scannability.

### Sales Collateral (Battle Cards, Leave-Behinds)

- **Problem:** Open with a customer quote expressing the exact frustration.
- **Solution:** "How We Help" section -- concise, jargon-free, focused on mechanisms.
- **Benefit:** Case study format with specific before/after metrics from a real client.
- **Add:** Comparison table vs. alternatives, pricing options, contact info.
- **Length:** 1-2 pages. Sales reps must be able to walk through it in 2 minutes.

## Complete Before/After Example

This example shows how an entire PSB one-pager transforms from weak to strong.

### BEFORE (Weak PSB)

```
Businesses face challenges with marketing analytics. Data is scattered
across many tools and it takes a long time to compile reports.

AnalyticsCo is a powerful analytics platform with AI capabilities and
50+ integrations. Our advanced technology consolidates your data.

You'll see significant improvements in efficiency, better decisions,
and improved ROI on marketing spend.
```

**What is wrong:** Problem is generic (could be any business). Solution leads with company name and vague "AI capabilities." Benefits are entirely unquantified. No emotional resonance. No coherence chain.

### AFTER (Strong PSB)

```
# Stop Wasting 20 Hours a Week on Reports Nobody Trusts

## The Problem
Your marketing team spends 15-20 hours every week pulling data from
Google Analytics, HubSpot, Meta Ads, and six other platforms into
spreadsheets. By the time the report is compiled, the data is stale.
Worse, discrepancies between platforms mean nobody fully trusts the
numbers -- so decisions get delayed or made on gut instinct. Last
quarter, three campaigns ran two weeks past their optimal end date
because performance data arrived too late.

## The Solution
AnalyticsCo connects to 50+ marketing platforms and consolidates
your data into a single live dashboard -- no spreadsheets, no
manual pulls.

- **Automated data sync:** All platforms update in real time. No
  more Friday afternoon report scrambles.
- **Cross-platform reconciliation:** Built-in deduplication and
  attribution modeling resolve the discrepancies that erode trust.
- **One-click reporting:** Generate board-ready reports in 30
  seconds, not 3 hours.
- **30-minute setup:** Connect your platforms in a guided wizard.
  No engineering resources needed.

## Your Results
- **Reclaim 20 hours/week** -- $40K in annual productivity returned
  to your team
- **Real-time campaign decisions** -- optimize spend 5x faster than
  weekly reporting cycles
- **Trusted numbers** -- single source of truth eliminates data
  disputes in leadership meetings
- **25% higher campaign ROI** -- based on average client results
  from acting on timely, accurate data

[Schedule a 15-minute demo -->]
```

**What makes this strong:** The headline names the specific pain. Problem uses real numbers and names real tools. Solution elements map 1:1 to stated pains. Benefits are quantified with dollar values and multipliers. CTA is specific and low-commitment.

## Common Mistakes and Corrections

### Mistake 1: Generic Problem Statement
The Problem reads like it could apply to any company in any industry.

| Weak | Strong |
|------|--------|
| "Businesses face challenges with efficiency." | "Your warehouse team spends 12 hours/week on manual inventory counts, and shrinkage still costs you $180K annually." |

**Fix:** Add a specific audience, a specific pain, and a specific number.

### Mistake 2: Solution Describes Features Instead of Mechanisms
The Solution lists what the product *has* instead of what it *does* for the reader.

| Weak | Strong |
|------|--------|
| "Our platform uses advanced AI algorithms and machine learning." | "AI-powered demand forecasting predicts your weekly orders with 95% accuracy, replacing the manual estimates your team spends 8 hours building." |

**Fix:** For every feature, answer "which means that you..." and write that instead.

### Mistake 3: Unquantified Benefits
The Benefit section uses adjectives instead of numbers.

| Weak | Strong |
|------|--------|
| "You'll see significant improvements in productivity." | "Reduce report compilation from 15 hours to 30 minutes per week ($28K annual time savings at your team's average rate)." |

**Fix:** Apply the formula: [Action verb] + [metric] + by [amount] + ([dollar/time equivalent]).

### Mistake 4: Broken Problem-Solution Chain
The Problem talks about one pain, but the Solution addresses a different one.

| Weak | Strong |
|------|--------|
| Problem: "High employee turnover costs you $500K/year." Solution: "Our platform has beautiful dashboards and real-time analytics." | Problem: "High employee turnover costs you $500K/year." Solution: "Pulse surveys and predictive attrition models identify at-risk employees 60 days before they resign, giving managers time to intervene." |

**Fix:** Every Solution element must directly address a stated Problem element. If it does not, either change the Solution or add the relevant pain to the Problem.

### Mistake 5: Company-Centric Language
The content talks about "we" and "our" instead of "you" and "your."

| Weak | Strong |
|------|--------|
| "We are the leading provider of analytics solutions. Our team has 15 years of experience." | "You get a single dashboard that replaces six tools, set up in 30 minutes by your existing team." |

**Fix:** Rewrite every sentence with "you/your" as the subject. The reader is the protagonist, not the vendor.

## PSB vs. FAB: When to Choose Which

| Dimension | PSB | FAB |
|-----------|-----|-----|
| Starting point | Customer's pain | Product's capabilities |
| Best audience | Buyer who knows they have a problem | Buyer evaluating specific features |
| Emotional driver | Relief from pain | Excitement about capability |
| Best deliverables | Sales proposals, one-pagers, pain-driven marketing | Product launches, technical docs, feature announcements |
| Opening move | "You're losing $X because..." | "This feature does X, which means..." |

**Decision rule:**
- If the reader is thinking "I need to fix this problem" --> use PSB
- If the reader is thinking "What can this product do?" --> use FAB
- If you need both --> use PSB for the executive summary and FAB for the detailed solution section

## Validation Checklist

Before delivering any PSB content, verify each item:

- [ ] Problem names a specific, concrete pain (not a category)
- [ ] Problem includes at least one quantified impact (time, money, risk)
- [ ] Problem uses second-person language ("you/your")
- [ ] Problem creates emotional resonance (the reader feels understood)
- [ ] Solution directly addresses every pain point stated in Problem
- [ ] Solution explains mechanisms (how it works), not just features (what it has)
- [ ] Solution includes a feasibility proof (setup time, integration path)
- [ ] Every Benefit is quantified with a specific metric
- [ ] Benefits follow the formula: [verb] + [metric] + by [amount] + ([equivalent])
- [ ] Clear causal chain traces from each Problem through Solution to Benefit
- [ ] No orphaned Solution elements (everything maps to a stated Problem)
- [ ] Content uses "you/your" as primary subject, not "we/our"
- [ ] Call to action is present and specific

## See Also
- `fab-framework.md` -- Feature-focused alternative; use when leading with product capabilities
- `scqa-framework.md` -- Narrative problem-solving; use for strategic or analytical documents
- `star-framework.md` -- Evidence-driven; use when proof through specific examples is the priority
- `../01-core-principles/conciseness-principles.md` -- Essential companion for one-pager deliverables
