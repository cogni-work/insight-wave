# Story Arc Analysis

## Purpose

Define how to read any narrative document and identify its argument structure, governing thought, and section roles — before extracting any content for slides. This is the foundation of intelligent brief generation: understanding *what the narrative is arguing* before deciding *how to present it*.

## Why This Matters

A narrative written for reading (linear, detailed, nuanced) must be restructured for presenting (visual, concise, sequential). The story arc analysis tells us:

1. **What type of argument** is being made (arc type)
2. **What the single key message** is (governing thought)
3. **What role each section plays** in the argument (section roles)
4. **What order the slides should follow** (presentation flow)

Without this analysis, slide generation becomes mechanical extraction — dumping content into layouts without understanding what the audience should take away.

---

## Step 3a: Arc Type Detection

### Reasoning Approach

Arc detection is NOT pattern matching — it is argument classification. The goal is to understand WHAT the narrative is trying to accomplish, then label that intent.

Before scanning for signals, reason about the narrative's overall shape:

```text
REASON about the narrative's intent:
  1. What is the OPENING trying to do?
     → Shock the reader? (problem/why-change)
     → State a thesis? (argument)
     → Summarize findings? (report)
     → Set a starting point? (journey)

  2. What is the MIDDLE doing?
     → Building urgency then presenting a solution? (why-change)
     → Providing supporting evidence? (argument)
     → Walking through time? (journey)
     → Presenting organized findings? (report)
     → Describing impact then fix? (problem-solution)

  3. What is the CLOSING asking for?
     → Investment/budget approval? (why-change)
     → Action on recommendation? (argument)
     → Next steps/future plans? (journey/report)
     → Adoption of solution? (problem-solution)

  4. What is the EMOTIONAL trajectory?
     → Fear → relief → confidence? (why-change / problem-solution)
     → Neutral → conviction? (argument / report)
     → Reflection → anticipation? (journey)
```

### Signal Scan

After reasoning about intent, confirm with structural signals:

```text
SCAN the narrative for:
  1. Header patterns (H1, H2, H3 structure)
  2. Opening section tone (problem? thesis? chronological?)
  3. Closing section type (recommendation? summary? next steps?)
  4. Presence of specific structural markers (see per-type signals below)
  5. Dominant rhetorical pattern
```

### Arc Types and Detection Signals

#### 1. Why Change (`why-change`)

**Core intent:** Persuade the audience to change behavior by moving from crisis → urgency → solution → investment justification.

**Detection signals:**
- Directory structure: `01-why-change/`, `02-why-now/`, `03-why-you/`, `04-why-pay/`
- Headers containing: "Why Change", "Why Now", "Why You", "Why Pay/Business Case"
- File: `power-positions.md` with IS-DOES-MEANS markers
- File: `value-story.md` as overview
- Crisis/problem language in opening sections
- Solution/capability language in middle sections
- Investment/ROI language in closing sections

**Confidence:** 1.0 if directory structure matches; 0.8 if header patterns match

**Presentation flow:**
```
Title → Problem/Crisis → Urgency → Solution Overview → Power Positions (×N) → Investment → Next Steps
```

**Section role mapping:**
| Why Change Section | Role | Slide Group |
|--------------------|------|-------------|
| value-story.md (title) | `hook` | Title |
| 01-why-change (crises) | `problem` | Problem |
| 02-why-now (urgency) | `urgency` | Urgency |
| 03-why-you (Executive Summary) | `solution` | Solution Overview |
| 03-why-you (Power Positions) | `proof` | Power Positions |
| 04-why-pay (business case) | `investment` | Investment |
| Next steps | `call-to-action` | CTA |

**Solution Overview (MANDATORY for why-change arc):** The `03-why-you` section produces TWO distinct slide groups:

1. **Solution Overview** (role: `solution`) — Extracted from the opening paragraphs of `03-why-you/narrative.md` that synthesize portfolio intelligence and unconsidered needs into a high-level solution concept. Describes WHAT the overall approach is. Uses a text-based layout (typically `two-columns-equal`).
2. **Power Position slides** (role: `proof`) — Extracted from the IS-DOES-MEANS blocks in `03-why-you/narrative.md` and `power-positions.md`. Each Power Position produces one `is-does-means` layout slide.

The solution overview slide MUST precede the Power Position slides. Without it, audiences experience cognitive dissonance jumping from crisis/urgency directly to detailed technical capabilities. The overview orients the audience to WHAT the solution is before diving into HOW each component delivers specific outcomes.

---

#### 2. Problem-Solution (`problem-solution`)

**Core intent:** Name a specific problem and propose a fix, without urgency framing or multi-phase sales structure.

**Detection signals:**
- Opening focuses on a problem, pain point, or gap
- Keywords: "challenge", "problem", "issue", "gap", "pain point", "risk"
- Transition markers: "however", "the solution", "our approach", "to address this"
- Closing focuses on benefits, outcomes, or results
- No time-pressure/urgency section (distinguishes from why-change)

**Confidence:** 0.85 if clear problem→solution structure; 0.65 if ambiguous

**Presentation flow:**
```
Title → Problem Definition → Impact/Scale → Solution → Benefits → Proof → Next Steps
```

**Section role mapping:**
| Content Pattern | Role |
|-----------------|------|
| Problem description | `problem` |
| Impact quantification | `evidence` |
| Solution description | `solution` |
| Benefits list | `proof` |
| Implementation | `roadmap` |
| Call to action | `call-to-action` |

---

#### 3. Journey (`journey`)

**Core intent:** Walk the audience through time — past → present → future — to show progress and direction.

**Detection signals:**
- Chronological structure (dates, phases, milestones)
- Keywords: "began", "started", "then", "next", "finally", "milestone", "achievement"
- Past → Present → Future progression
- Project updates, retrospectives, progress reports

**Confidence:** 0.85 if clear temporal markers; 0.6 if implicit chronology

**Presentation flow:**
```
Title → Where We Started → Key Milestones → Current State → Lessons Learned → What's Next
```

**Section role mapping:**
| Content Pattern | Role |
|-----------------|------|
| Starting context | `hook` |
| Historical events | `evidence` |
| Key milestones | `proof` |
| Current state | `evidence` |
| Lessons/insights | `solution` |
| Future plans | `roadmap` |

---

#### 4. Argument (`argument`)

**Core intent:** Present a thesis, support it with evidence, and drive toward a conclusion.

**Detection signals:**
- Opens with a thesis or recommendation
- Body provides supporting evidence organized by topic
- May include counterarguments or alternatives
- Closes with reinforced conclusion and action
- Keywords: "recommend", "propose", "argue", "evidence suggests", "therefore"
- Academic, consulting, or policy documents

**Confidence:** 0.8 if thesis→evidence→conclusion pattern; 0.6 if less structured

**Presentation flow:**
```
Title → Thesis/Recommendation → Argument 1 + Evidence → Argument 2 + Evidence → Argument 3 + Evidence → Conclusion → Call to Action
```

**Section role mapping:**
| Content Pattern | Role |
|-----------------|------|
| Thesis statement | `hook` |
| Supporting arguments | `evidence` |
| Data and proof points | `proof` |
| Counterargument handling | `evidence` |
| Conclusion | `solution` |
| Recommended actions | `call-to-action` |

---

#### 5. Report (`report`)

**Core intent:** Present organized findings with analysis and recommendations for decision-makers.

**Detection signals:**
- Executive summary at the beginning
- Findings organized by topic or category
- Analysis with data tables, charts references
- Recommendations section
- Keywords: "findings", "analysis", "data shows", "recommend", "appendix"
- Research reports, market analyses, audit results

**Confidence:** 0.85 if executive summary + findings + recommendations; 0.6 if partial

**Presentation flow:**
```
Title → Executive Summary → Key Finding 1 → Key Finding 2 → Key Finding 3 → Recommendations → Next Steps
```

**Section role mapping:**
| Content Pattern | Role |
|-----------------|------|
| Executive summary | `hook` |
| Individual findings | `evidence` |
| Analysis/interpretation | `proof` |
| Recommendations | `solution` |
| Implementation plan | `roadmap` |
| Appendix/references | (omit from slides) |

---

### Disambiguation: Resolving Overlapping Signals

When signals point to multiple arc types, reason through these distinguishing questions:

```text
DISAMBIGUATE using these decision questions:

Q1: Is there a 4-part Why Change structure (why-change / why-now / why-you / why-pay)?
  YES → why-change (confidence 1.0, stop here)
  NO  → continue

Q2: Does the narrative use TIME as its organizing principle?
  YES → journey
  NO  → continue

Q3: Does the narrative open with an executive summary and present categorized findings?
  YES → report
  NO  → continue

Q4: Does the narrative have a clear problem section FOLLOWED by a solution section?
  YES → Does it also create urgency (deadline, trend, competitive threat)?
    YES → re-evaluate as why-change (confidence 0.7)
    NO  → problem-solution
  NO  → continue

Q5: Does the narrative open with a thesis and build supporting arguments?
  YES → argument
  NO  → default to argument (lowest structure requirement), flag for review
```

**Common confusion pairs and how to resolve:**

| Pair | Key Differentiator |
|------|-------------------|
| why-change vs problem-solution | Why-change has urgency section AND investment justification. Problem-solution jumps straight from problem to fix. |
| report vs argument | Reports organize findings by TOPIC (parallel structure). Arguments build a CASE (sequential logic). |
| journey vs report | Journeys organize by TIME. Reports organize by CATEGORY. |
| argument vs problem-solution | Arguments start with a THESIS (recommendation up front). Problem-solution starts with the PAIN. |

---

## Step 3b: Governing Thought Extraction

### What is a Governing Thought?

The **governing thought** is the single sentence that captures the entire presentation's argument. It answers: "If the **primary decision-maker** remembers only ONE thing, what should it be?"

### Caller-Provided Governing Thought

When the caller provides a `governing_thought` parameter, this step operates in **validation+enrichment mode**:

```text
IF governing_thought parameter provided:
  1. READ the caller's governing thought
  2. VERIFY it against the narrative:
     - Does the narrative actually support this claim?
     - Is it a single sentence with an active verb?
     - Does it include a number or specific claim?
  3. IF valid → ACCEPT as governing thought (skip candidate generation)
     IF invalid → LOG discrepancy, fall through to candidate generation
  4. ENRICH: check if the Audience Model suggests a stronger framing
     (e.g., caller says "saves lives" but EB priority is ROI → consider adding savings figure)
```

### Extraction Process with Reasoning

When no caller-provided governing thought is available, do not simply copy a sentence from the narrative. Instead, reason through candidates and select the strongest one:

```text
PHASE 1 — Generate candidates (aim for 3-5):

  Scan opening (first 2-3 paragraphs):
    Look for: thesis statements, bold claims, executive summary sentences
    → Candidate A: "{exact sentence or paraphrase}"

  Scan closing (last 2-3 paragraphs):
    Look for: conclusions, recommendations, calls to action
    → Candidate B: "{exact sentence or paraphrase}"

  Identify most-repeated theme:
    Count: key terms, concepts, and claims across all sections
    → Candidate C: "{synthesized statement of dominant theme}"

  Find strongest quantified claim:
    The single most impactful number or comparison in the narrative
    → Candidate D: "{claim with number}"

PHASE 2 — Evaluate each candidate against criteria:

  For each candidate, score YES/NO:
    1. Single sentence, max 25 words?
    2. Contains a verb in active voice?
    3. Includes at least one number or specific claim?
    4. Answers "so what?" — makes the primary decision-maker care?
    5. (Rich Audience Model only) Addresses the primary decision-maker's top priority?
       From Audience Model: primary_decision_maker.top_priority
       → Prefer candidates that speak to this priority
       → Example: EB priority = "ROI within 12 months"
         → Candidate with savings/ROI figure ranks higher than one leading with technical capability

  → Select the candidate with the most YES scores.
  → If tied, prefer the candidate with a number.
  → If still tied AND Audience Model available, prefer the candidate that aligns with the primary decision-maker's priority.

PHASE 3 — Refine the winner:

  Template: "[Subject] [verb] [object] because [reason], resulting in [outcome]."

  Test: Does every section in the narrative connect back to this statement?
    → If a section seems disconnected, either:
      (a) the governing thought is too narrow — broaden it
      (b) the section is tangential — it may be cut or merged in Step 4

  Refine until the statement passes ALL 4 criteria from Phase 2.
```

### Worked Example

Given a narrative about AI video analytics for railway safety:

```text
PHASE 1 — Candidates:
  A (opening): "German rail networks face a growing safety crisis with 688 annual deaths."
  B (closing): "Deploying AI video analytics saves €2.8M annually while preventing loss of life."
  C (theme): "AI-powered video surveillance can detect incidents faster than manual monitoring."
  D (number): "688 rail deaths per year are preventable with existing technology."

PHASE 2 — Evaluation:
  A: ✅ single sentence | ✅ active verb | ✅ number (688) | ❌ no action ("face" is passive)
  B: ✅ single sentence | ✅ active verb | ✅ number (€2.8M) | ✅ audience cares (saves money + lives)
  C: ✅ single sentence | ✅ active verb | ❌ no number | ✅ audience cares
  D: ✅ single sentence | ❌ passive ("are preventable") | ✅ number (688) | ✅ audience cares

  Winner: B (4/4 criteria)

PHASE 3 — Refinement:
  "Deutsche Bahn should deploy AI video analytics to prevent 688 annual rail deaths
   and save €2.8M in emergency costs."
  → 22 words ✅ | active verb "deploy" ✅ | numbers 688 + €2.8M ✅ | so-what ✅
  → Every section connects: crisis (688 deaths) → urgency (trend rising) →
     solution (AI analytics) → investment (€2.8M savings)
```

### Examples by Arc Type

| Arc Type | Governing Thought Example |
|----------|--------------------------|
| `why-change` | "Deutsche Bahn must deploy AI video analytics to prevent 688 annual rail deaths and save €2.8M in emergency costs." |
| `problem-solution` | "Automating customer support triage reduces response time from 48 hours to 15 minutes while cutting costs by 60%." |
| `journey` | "In 18 months, the platform grew from 5 pilot stations to 25 regional sites, proving AI monitoring at scale." |
| `argument` | "Open-source AI models outperform proprietary solutions for edge deployment due to 3x lower latency and zero licensing costs." |
| `report` | "Q3 analysis reveals 23% revenue growth driven by enterprise adoption, with 3 recommendations to sustain momentum." |

---

## Step 3c: Section Role Assignment

### Caller-Provided Section Roles

When the caller provides a `section_roles` parameter:

```text
IF section_roles parameter provided:
  1. PARSE the caller's role mapping (e.g., "01-why-change=problem, 02-why-now=urgency, ...")
  2. VERIFY each role is valid (from the allowed set)
  3. VERIFY the mapping covers all narrative sections
  4. IF valid → ACCEPT as section roles (skip manual assignment below)
     IF partial → ACCEPT mapped sections, manually assign remaining
     IF invalid roles → LOG discrepancy, fall through to manual assignment
```

### Reasoning Approach

Section roles describe FUNCTION in the argument, not TOPIC. The same content can serve different roles depending on where it sits in the arc and what it is trying to accomplish.

Before assigning roles, reason about each section's function:

```text
For each major section (H1 or H2):

  1. READ the section header and first paragraph

  2. ASK: "What is this section DOING for the argument?"
     → Establishing a problem the audience should care about? → problem
     → Creating time pressure or competitive urgency? → urgency
     → Presenting data that quantifies the situation? → evidence
     → Proposing an approach or capability? → solution
     → Demonstrating credibility or track record? → proof
     → Presenting choices or alternatives? → options
     → Showing an implementation path? → roadmap
     → Framing cost vs. value? → investment
     → Driving the audience toward a specific action? → call-to-action
     → Setting the stage or grabbing attention? → hook

  3. VERIFY by testing the alternative:
     A section about "costs" could be:
       → `problem` if it shows the PAIN of current costs ("Manual monitoring costs €4.2M/year")
       → `evidence` if it QUANTIFIES the scale ("Incidents cost the network €4.2M annually")
       → `investment` if it frames the SOLUTION's cost/value ("€1.4M investment saves €4.2M/year")

     The deciding factor is: what does the AUTHOR want the audience to FEEL?
       → Pain? → problem or urgency
       → Understanding? → evidence
       → Confidence? → proof or solution
       → Motivation to act? → investment or call-to-action

     IF Audience Model available (Rich mode), also consider the primary decision-maker:
       → EB-facing deck: "costs" section likely serves as `investment` (frames ROI)
       → TE-facing deck: "costs" section likely serves as `evidence` (neutral data)
       → EU-facing deck: "costs" section likely serves as `problem` (pain they feel daily)
       → When authorial intent and audience alignment agree → high confidence
       → When they conflict → prefer authorial intent, note the tension

  4. CHECK for role gaps in the presentation:
     Every deck needs at minimum: hook, 1+ evidence, call-to-action
     Problem-solution decks need: problem, solution, proof
     Journey decks need: hook, 2+ evidence, roadmap
```

### Worked Example

Given three sections from a narrative about cloud migration:

```text
Section: "The Hidden Cost of Legacy Infrastructure"
  Content: "Maintaining on-premise servers costs the company €3.2M annually.
            Downtime incidents increased 40% in the last year. Each outage
            costs €45K in lost productivity..."

  Reasoning:
    → Topic is "costs" — but what FUNCTION does it serve?
    → The author is using costs to create PAIN. Words: "hidden cost",
      "increased 40%", "lost productivity" all frame the status quo negatively.
    → This is NOT evidence (neutral data) — it is problem (pain framing).
    → Role: problem

Section: "Market Benchmark: Cloud Adoption in DACH"
  Content: "78% of DACH enterprises have migrated primary workloads to cloud.
            Average migration timeline: 14 months. Companies report 35%
            infrastructure cost reduction..."

  Reasoning:
    → Topic is market data — but what FUNCTION?
    → The author is showing what peers have done (78% adopted) and what
      results they achieved (35% savings). This quantifies the opportunity.
    → This is NOT proof (we didn't do it) — it is evidence (the data says).
    → Role: evidence

Section: "Our Track Record: 12 Enterprise Migrations"
  Content: "We have successfully migrated 12 enterprise clients in the DACH
            region, including Deutsche Telekom and BMW. Average migration time:
            11 months (21% faster than market)..."

  Reasoning:
    → Topic is track record — what FUNCTION?
    → The author is demonstrating credibility. "12 clients", "Deutsche Telekom",
      "21% faster" all serve to build trust in the solution provider.
    → This is proof — evidence of the provider's capability.
    → Role: proof
```

### Role Distribution Guidelines

| Deck Length | Recommended Role Distribution |
|-------------|-------------------------------|
| 5-7 slides | 1 hook, 2-3 evidence, 1 solution, 1 CTA |
| 8-12 slides | 1 hook, 3-5 evidence/problem, 2-3 solution/proof, 1 CTA |
| 13-15 slides | 1 hook, 4-6 evidence/problem, 3-4 solution/proof, 1 options/roadmap, 1 CTA |

### Roles That Can Combine

Some sections serve dual roles. When this happens, assign the PRIMARY role and note the secondary:

- `hook` + `problem` (opening with a shocking stat)
- `evidence` + `urgency` (data that creates time pressure)
- `solution` + `proof` (solution with built-in evidence)
- `roadmap` + `call-to-action` (next steps as the path forward)

---

## Story Flow Validation

After assigning roles, reason through the flow to catch structural errors:

```text
CHECK 1: Does the deck start with hook or problem?
  → Never start with solution (audience doesn't know why they need it yet)
  → WHY: The audience must feel the problem before they'll accept the solution.
  → FIX if violated: Move the solution section later; find a problem or
    hook element to open with.

CHECK 2: Does problem come before solution?
  → Build the case before presenting the answer
  → WHY: Solutions without context feel like sales pitches, not arguments.
  → FIX if violated: Reorder so at least one problem/evidence slide precedes
    the first solution slide.

CHECK 3: Does evidence support the governing thought?
  → Every evidence slide should connect to the main argument
  → WHY: Disconnected evidence dilutes the presentation's focus.
  → FIX if violated: Either (a) re-frame the evidence to connect to the
    governing thought, or (b) cut the evidence and use the slide for
    something that supports the argument.

CHECK 4: Does the deck end with call-to-action or roadmap?
  → Always give the audience a clear next step
  → WHY: Presentations without a CTA waste the momentum built by the argument.
  → FIX if violated: Add a CTA slide. If no clear action exists in the
    narrative, synthesize one from the governing thought.

CHECK 5: Is the emotional arc correct?
  → Problem slides create tension
  → Solution slides release tension
  → Proof slides build confidence
  → CTA creates momentum
  → WHY: The audience's emotional state must peak at the problem and
    resolve at the solution. If proof comes before solution, confidence
    is built for nothing.
  → FIX if violated: Reorder so tension builds (problem → urgency →
    evidence), then releases (solution → proof → CTA).
```

---
