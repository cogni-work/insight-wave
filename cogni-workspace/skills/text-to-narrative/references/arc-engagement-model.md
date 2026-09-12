---
arc_id: engagement-model
display_name: Engagement Model
display_name_de: Zusammenarbeitsmodell
contract: 2
---

# Engagement Model

## Intent

**Governing question:** How does this company work, what does an engagement look like step by step, what must the buyer bring, and what will they be able to point to at the end?

**Rhetorical job:** Describe a way of working so that a buyer knows what working together will feel like. The arc moves from operating principles through the engagement's phases to the buyer's reciprocal commitments and closes on cross-cutting outcomes — a chronological progression, read for reassurance.

**Not for:** what a specific solution does (a capability page), why the company exists (`company-credo`), a portfolio introduction (`jtbd-portfolio`), or anything carrying pricing or ROI (capability pages and proposals).

## Selection

**Best for:** How-We-Work pages, engagement sections of proposals, partner onboarding, the `approach` scope of cogni-portfolio's customer narrative.

**Signals:** content type `engagement-model` or `how-we-work`; the source describes delivery phases, cadences, artifacts, buyer inputs; keywords such as "how we work", "our process", "delivery model", "ways of working", "partnership".

**Anti-signals:** the source is about one solution's scope (a capability page); it argues why the company exists (`company-credo`); it carries pricing tiers or ROI models (proposal territory).

**Fallback priority:** never a fallback. Selected only on content type or delivery-process signals.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE |
|---|----|----|
| 1 | Principles: Principles We Work By | Prinzipien: Unsere Arbeitsprinzipien |
| 2 | Process: How an Engagement Unfolds | Prozess: Wie eine Zusammenarbeit verläuft |
| 3 | Partnership: What We Expect From You | Partnerschaft: Was wir von Ihnen erwarten |
| 4 | Outcomes: What Success Looks Like | Ergebnisse: Wie Erfolg aussieht |

## Composition

Section lengths are proportions of `--target-length`. **Recommended length: 1,400 words** — How-We-Work pages are scanned for reassurance, not read through — so callers pass `--target-length 1400`; the skill's own default stays 1,675 when the flag is omitted. Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Principles | 24% |
| Process | 30% |
| Partnership | 22% |
| Outcomes | 24% |

**Executive TL;DR emphasis:** principles → process → partnership → outcomes. The narrative opens with the TL;DR defined in `validation.md`; the fear buyers typically bring to engagements, and how this company handles it differently, belongs in its first sentence as the conclusion.

**Transitions:**

1. Principles → Process: "Here is what those principles look like in a typical engagement."
2. Process → Partnership: "None of this works unless you bring a few things to the table as well."
3. Partnership → Outcomes: "If we both hold up our side of that, here is what you will be able to point to at the end."

**Closing pattern:** firm where it matters, flexible where it matters, plus one invitation to a specific next page — "The process adapts to your size and scope. The principles do not. If you want to see which capabilities ride on top of this engagement model, the Capabilities page is the next stop."

## Elements

### 1. Principles

**Purpose:** name three or four operating principles that shape every engagement regardless of capability or market — the answer to "before we talk about what you do, how do you work?"

**Evidence sought:** recurring delivery patterns across solution entities (a phrase in three or more solutions is a principle candidate), the methodology named in the positioning, the convictions of an existing `company-credo` narrative, which principles operationalise.

**Argument move:** scan solutions for recurring patterns → phrase each principle as a short headline plus one paragraph on how it shows up in the work → name what each principle replaces → link each to where it appears in Process.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure) ("Instead of monthly status reports, we run weekly demos"), [Forcing Functions](techniques-overview.md#5-forcing-functions) (why the principle exists).

**Hard rules:** three or four principles; each is operational — "we always X" or "we never Y" — never a value ("we value X"); each is observable in Process.

**Failure modes:** a values wall; "we value transparency"; a principle Process never shows.

### 2. Process

**Purpose:** walk the buyer through the arc of an engagement as a concrete sequence of things they will see, sign and receive — the longest element, because it is what the buyer came to read.

**Evidence sought:** phases across solution entities, deduplicated into the recurring structure; cadence signals in the company description.

**Argument move:** identify the four to six canonical phases that recur across the portfolio (flag disagreement, use the most common) → for each, name what happens, what the buyer sees, what the buyer signs and how long it typically takes → present as a skimmable sequence with headings, not dense paragraphs.

**Techniques:** [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (time bands, cadence specifics), [You-Phrasing](techniques-overview.md#7-you-phrasing) (what you see, what you sign).

**Hard rules:** four to six phases; every phase names at least one concrete artifact and one time band ("2-4 weeks", never "a few weeks"); phases are solution-agnostic — a phase specific to one solution belongs on that solution's capability page.

**Failure modes:** "phase 1, phase 2, phase 3" with no artifacts; false precision or no duration; a phase that only one solution runs.

### 3. Partnership

**Purpose:** name plainly what the buyer must bring for the engagement to work — the reciprocal of Promise, and the element most companies skip.

**Evidence sought:** recurring buying criteria across customer personas, readiness requirements in solutions (input data, approvals, access), documented friction from past engagements.

**Argument move:** extract three or four expectations that apply to most engagements → for each, state what the company needs (access, input, approvals, decisions) and why it matters (what happens to the engagement without it) → tie each to something the company commits in return.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing) ("You will need to…"), [Contrast Structure](techniques-overview.md#6-contrast-structure) (discipline, not obstruction: "if this isn't available, we pause rather than work around it").

**Hard rules:** three or four expectations; each names a concrete thing — a person, a data source, an approval authority, a timebox; the element reads as inputs the engagement needs, never as reasons it could fail.

**Failure modes:** a laundry list; a defensive tone; an expectation with no consequence.

### 4. Outcomes

**Purpose:** state what the buyer will be able to point to after a successful engagement — in outcome terms, not deliverable terms, and cross-cutting rather than per capability.

**Evidence sought:** aggregated MEANS themes across propositions, cross-cutting outcome patterns across solutions.

**Argument move:** aggregate the MEANS layer and pick the three outcome themes that recur → for each, state what the buyer will see change, in buyer language, and how that change is observed → close on the soft-close sentence and one invitation.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing) ("You will see X change"), [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions) (the MEANS layer, aggregated).

**Hard rules:** exactly three outcome themes, each cross-cutting and each with a way to observe it; no per-capability outcomes; **no pricing and no ROI numbers** — those belong on capability pages, where scope is defined, or in proposals, where the customer is specific.

**Failure modes:** "an average 3x ROI within 18 months"; deliverables listed as outcomes; an outcome true for one product only.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Every Principle is an operation ("we always X"), not a value, and appears visibly inside Process.
- Every Process phase names at least one artifact and one time band, and no phase is specific to one solution.
- Every Partnership expectation names a concrete input and is tied to a consequence for the engagement.
- Outcomes carries exactly three cross-cutting themes, each observable.
- **No Pricing / No ROI Numbers:** neither Principles, Process, Partnership nor Outcomes contains a pricing number or an ROI figure — keeping them out is what stops the How We Work page reading as a sales pitch.
- Nothing in the narrative is specific to one solution; it all describes how the company works.
- The chain holds: Process shows the Principles in action; Partnership is the reciprocal of the company's commitments; Outcomes are cross-cutting, not per capability. Where a `company-credo` narrative exists alongside, Partnership mirrors its Promise.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
