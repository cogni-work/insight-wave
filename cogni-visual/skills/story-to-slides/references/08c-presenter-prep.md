# Presenter Prep Slides (Internal Prep Slide Copywriting)

## Purpose

Define how to auto-generate one or two **internal prep slides** that strategically brief the presenter before they present. These are **visible slides, not data dumps** — they follow the same copywriting principles as content slides, optimized for the specific goal of presenter comprehension. They are placed after Slide 1 (title slide), marked with "INTERNAL — REMOVE FROM CLIENT PRESENTATION" via the `Bottom-Banner` field, and are not counted against `max_slides`.

**Why this matters:** A presenter who understands the room (audience) and the journey (story arc) delivers with conviction. A presenter reading unfamiliar slides delivers mechanically. These internal prep slides are the difference.

---

## Core Principles

> **Internal prep slides** answer three questions in 15 seconds:
> **WHO** is in the room (and how to address each person), **WHY** the arc flows as it does, and **WHAT** role the presenter plays.
> Every element must be glanceable — the presenter reviews these slides minutes before presenting, not hours.
> They are marked "INTERNAL — REMOVE FROM CLIENT PRESENTATION" and should be deleted before the client-facing presentation.

> **Speaker-Notes** answer a different question: not what to glance at before presenting,
> but what to **SAY**, how to **PACE** it, and what to **KNOW** when challenged.
> Notes are the coaching layer — extensive, strategic, and specific to each slide's arc position and audience.
> They are read during preparation and rehearsal, not during presentation.

---

## Architectural Position

These slides are **internal prep slide copywriting** — a component of the slide generation pipeline, not a post-validation afterthought.

- Generated as Step 7c, **before** validation (Step 8), so they are validated alongside all other slides
- Use specialized layouts with `Bottom-Banner` carrying the INTERNAL warning: `process-flow` for Methodology, `four-quadrants` (text-card mode) for Buying Center
- Subject to the same schema compliance, field validation, and quality checks
- The Audience Model (Step 2.5), Story Arc (Step 3), and buyer-appendix (if available from Step 1) provide all source data — no file re-reading needed
- Internal prep slides are numbered sequentially after the title slide: Slide 2 (Methodology), Slide 3 (Buying Center)
- NOT counted against `max_slides` — they will be removed before the client presentation

---

## Three Sub-Steps

- **Sub-step 1: Slide 2 — Pitch-Methodik / Methodology** (always generated)
- **Sub-step 2: Slide 3 — Buying Center** (conditional: only when Audience Model Rich mode)
- **Sub-step 3: Per-slide extensive Speaker-Notes** (always generated, all slides including internal prep slides)

---

## Reasoning Approach: Presenter Comprehension

Before generating any presenter prep content, reason through what the presenter actually needs:

```text
REASON through presenter preparation needs:

  1. WHO is in the room?
     → What roles are represented? (Economic Buyer, Technical Evaluator, End Users)
     → Who holds sign-off power? (primary decision-maker from Audience Model)
     → Who might derail the conversation? (blockers — know their objections COLD)
     → Who is the ally? (champion — leverage their motivation to build momentum)
     → ASK: "If the presenter walks in unprepared for ONE person, who causes
       the most damage?"
       → That person's objection must be prominently visible on the buyer map

  2. WHY is the arc structured this way?
     → What's the governing thought in ONE sentence?
     → What is the argumentative purpose of each arc phase?
       - Why does the presentation START with this topic?
       - Why does each phase FOLLOW the previous one?
       - What is the RHETORICAL STRATEGY behind the sequence?
     → How does the arc type shape the delivery?
       - Why Change: build fear, then offer relief — the presenter must COMMIT to the crisis
       - Problem-Solution: name the pain, then present the fix — tone shift matters
       - Journey: walk through time — the presenter must show pride in progress
       - Argument: thesis first — the presenter must be confident in the claim
       - Report: findings drive it — the presenter must let data speak

  3. WHERE are the emotional peaks?
     → Which slide is the TENSION PEAK? (last problem/urgency slide before the first solution)
       → This is where the presenter should slow down, make eye contact, pause
     → Which slide is the RELEASE? (first solution/proof slide after the peak)
       → This is where the presenter shifts tone from concern to confidence
     → PEAK/RELEASE info goes to Speaker-Notes (the pacing guide), not the slide body
     → The slide body focuses on arc LOGIC (why), the notes provide pacing TACTICS (where)

  4. WHAT could go wrong?
     → What's the hardest question someone in this room will ask?
     → Which stakeholder's objection is the biggest threat to the deal?
     → Is any data assumption-based? (the presenter must NOT speak with false certainty)
     → Where are the weakest evidence points? (anticipate "how do you know that?")
```

---

## Slide 2: Pitch-Methodik / Methodology (Always)

### Purpose

The Methodology slide gives the presenter a **visual pipeline** showing the argumentative structure of the presentation. Instead of a text-heavy two-column layout, it uses `process-flow` with `Detail-Grid` to show each arc phase as a pipeline node with key concepts below. This is always generated — every presenter benefits from understanding the rhetorical strategy.

### Reasoning Approach

The methodology slide shows a **visual pipeline** of the presentation's argumentative structure. Each arc phase becomes a pipeline node, with Detail-Grid items below showing what each phase covers.

```text
REASON through methodology pipeline construction:

  1. IDENTIFY the arc type and phases
     → Look up the arc phase template for the detected arc_type (see table below)
     → Each arc type has a fixed set of phases (typically 4, with optional Phase 0)
     → For "why-change" arc: include Phase 0 (Buying Center) as the pre-phase
       representing audience analysis before the pitch begins

  2. BUILD the Mermaid pipeline
     → Create a `graph LR` with one node per phase
     → Node IDs: P0, P1, P2, P3, P4 (matching arc phase numbers)
     → Node labels: phase display names (max 20 chars)
     → Arrows: simple `-->` between sequential phases
     → Example for why-change:
       graph LR
         P0["Buying Center"] --> P1["Why Change"]
         P1 --> P2["Why Now"]
         P2 --> P3["Why You"]
         P3 --> P4["Why Pay"]

  3. BUILD the Detail-Grid items per phase
     → Each phase gets 3-4 key concepts that the presenter should know
     → For "why-change" with buyer-appendix available:
       P0: stakeholder roles from Audience Model (Economic Buyer, Technical Evaluator, etc.)
       P1: the core crisis elements from the narrative
       P2: timing urgency elements (deadlines, regulatory, competitive)
       P3: differentiator themes (proof points, unique capabilities)
       P4: investment/ROI elements (payback, cost comparison)
     → Detail items are SHORT labels (max 20 chars each), not sentences
     → They give the presenter mental anchors for each phase

  4. CONSTRUCT the Slide-Title
     → Use the methodology display name as a subtitle concept
     → Title format: "{localized_methodology_headline}"
     → The title tells the presenter: "This is the rhetorical strategy"

  5. ADD context to Speaker-Notes
     → The pipeline is VISUAL — the notes explain the LOGIC:
       - WHY this arc type was chosen
       - What ROLE the presenter plays (provocateur, doctor, guide, etc.)
       - PEAK and RELEASE identification with pacing coaching
       - Per-slide pacing guide with section roles
     → The Slide-Title provides the governing thought context
     → Duration estimate: N slides × 100 sec ÷ 60 = minutes
```

### Arc Phase Templates

Each arc type maps to pipeline nodes and Detail-Grid items. During generation, customize Detail-Grid items with specifics from the actual narrative content.

**why-change** (5 nodes: Phase 0-4):

| Node | Label (EN) | Label (DE) | Detail-Grid Items (customize from narrative) |
|------|-----------|-----------|----------------------------------------------|
| P0 | Buying Center | Buying Center | Stakeholder roles from Audience Model |
| P1 | Why Change | Why Change | Core crisis elements making status quo indefensible |
| P2 | Why Now | Why Now | Timing urgency: deadlines, regulations, competitive pressure |
| P3 | Why You | Why You | Differentiators and proof points |
| P4 | Why Pay | Why Pay | Investment elements: ROI, payback, cost comparison |

**problem-solution** (4 nodes: Phase 1-4):

| Node | Label (EN) | Label (DE) | Detail-Grid Items |
|------|-----------|-----------|-------------------|
| P1 | Problem | Problem | Pain points the audience recognizes |
| P2 | Impact | Auswirkung | Cost of inaction, quantified consequences |
| P3 | Solution | Lösung | Fix description, root cause addressed |
| P4 | Proof | Beweis | Evidence, next steps, path forward |

**journey** (4 nodes: Phase 1-4):

| Node | Label (EN) | Label (DE) | Detail-Grid Items |
|------|-----------|-----------|-------------------|
| P1 | Origin | Ausgangslage | Baseline, starting conditions |
| P2 | Milestones | Meilensteine | Key achievements, momentum proof |
| P3 | Current State | Ist-Zustand | Where we stand today |
| P4 | What's Next | Ausblick | Future direction, opportunity |

**argument** (4 nodes: Phase 1-4):

| Node | Label (EN) | Label (DE) | Detail-Grid Items |
|------|-----------|-----------|-------------------|
| P1 | Thesis | These | Core recommendation |
| P2 | Evidence | Evidenz | Supporting data and analysis |
| P3 | Counterpoint | Gegenargument | Objections addressed |
| P4 | Conclusion | Schlussfolgerung | Reinforced thesis, call to action |

**report** (4 nodes: Phase 1-4):

| Node | Label (EN) | Label (DE) | Detail-Grid Items |
|------|-----------|-----------|-------------------|
| P1 | Summary | Zusammenfassung | Key findings framed for decision-makers |
| P2 | Findings | Ergebnisse | Evidence organized for comparison |
| P3 | Analysis | Analyse | Interpretation, implications |
| P4 | Recommendations | Empfehlungen | Actionable next steps ranked by impact |

### Methodology Display Names

| arc_type | English | German |
|----------|---------|--------|
| `why-change` | Corporate Visions "Why Change" | Corporate Visions "Why Change" |
| `problem-solution` | Problem-Solution | Problem-Lösung |
| `journey` | Journey / Timeline | Chronologischer Verlauf |
| `argument` | Thesis-Evidence-Conclusion | These-Evidenz-Schlussfolgerung |
| `report` | Findings-Based Report | Ergebnisbericht |

### PEAK/RELEASE Detection

PEAK and RELEASE are identified for Speaker-Notes pacing (not shown on the slide body):

```text
PEAK/RELEASE detection rules (arc-position-based):
  TENSION PEAK: the last slide with section role = problem or urgency
    before the first slide with section role = solution or proof
    → If NO problem/urgency slides: use the last evidence slide before solution
  RELEASE POINT: the first slide with section role = solution or proof
    after the PEAK
    → If NO solution slides after peak: use the first evidence slide after peak
```

### Methodology Output Format

```yaml
## Slide 2: {localized_methodology_headline}

Layout: process-flow

Slide-Title: {localized_methodology_headline}

Diagram: |
  graph LR
    P0["{phase_0_label}"] --> P1["{phase_1_label}"]
    P1 --> P2["{phase_2_label}"]
    P2 --> P3["{phase_3_label}"]
    P3 --> P4["{phase_4_label}"]

Detail-Grid:
  P0:
    - "{detail_0_1}"
    - "{detail_0_2}"
    - "{detail_0_3}"
    - "{detail_0_4}"
  P1:
    - "{detail_1_1}"
    - "{detail_1_2}"
    - "{detail_1_3}"
    - "{detail_1_4}"
  P2:
    - "{detail_2_1}"
    - "{detail_2_2}"
    - "{detail_2_3}"
  P3:
    - "{detail_3_1}"
    - "{detail_3_2}"
    - "{detail_3_3}"
  P4:
    - "{detail_4_1}"
    - "{detail_4_2}"
    - "{detail_4_3}"

Bottom-Banner:
  Text: "{localized_internal_warning}"

Speaker-Notes: |
  >> {WHAT_YOU_SAY_HEADER}

  [{opening_tag}]: "{coaching on how to use this methodology pipeline for delivery preparation}"
  [{key_point_tag}]: "{explain the arc type and what role the presenter plays (provocateur, doctor, guide, lawyer, analyst)}"
  [{key_point_tag}]: "{explain the PEAK — this is the slide where you slow down, lower voice, make eye contact}"
  [{key_point_tag}]: "{explain the RELEASE — this is where you shift from concern to confidence}"
  [{transition_tag}]: "{bridge to Buying Center slide or first content slide}"

  >> {WHAT_YOU_NEED_TO_KNOW_HEADER}

  - {context}: This slide is for your preparation only — remove before client presentation
  - {context}: Arc type "{arc_type}" means your role as presenter is: {presenter_role_description}
  - {context}: Governing thought: {governing_thought}
  - {context}: Duration estimate: {N} slides × ~100 sec = {M} minutes. The PEAK slide typically takes 2-3 minutes alone.

  - {pacing_guide_label}:
    {FOR each content slide:}
    Slide {N}: {section_role} — {headline snippet, max 40 chars} {(PEAK) or (RELEASE) if applicable — with coaching hint}
```

**Note:** For arc types with only 4 phases (no Phase 0), omit P0 from the Diagram and Detail-Grid. The pipeline then has 4 nodes (P1-P4).

### Methodology Localization

| Field | English | German |
|-------|---------|--------|
| Slide headline | Pitch Methodology | Pitch-Methodik |
| Pacing guide label | Slide-by-slide pacing guide | Folien-Fahrplan mit Pacing |
| PEAK marker | (PEAK) | (PEAK) |
| RELEASE marker | (RELEASE) | (RELEASE) |
| Internal warning | INTERNAL — REMOVE FROM CLIENT PRESENTATION | INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN |

---

## Slide 3: Buying Center (Conditional)

### Purpose

The Buying Center slide gives the presenter a **scannable card grid** showing each key stakeholder as a visual card. Instead of dense bullet lists, it uses `four-quadrants` in text-card mode — each card shows the role, title, "Lead with" instruction, and 3 key messages. This is generated only when the Audience Model was built in Rich mode.

### Reasoning Approach

```text
REASON through buying center card construction:

  1. IDENTIFY the top 4 stakeholders
     → From the Audience Model (Step 2.5), select up to 4 key roles:
       - Economic Buyer (EB): the person who signs the check
       - Technical Evaluator (TE): the person who validates feasibility
       - End Users (EU): the people who use the solution daily
       - Champion: the internal ally who drives the deal forward
     → If more than 4 roles exist, prioritize: EB > TE > EU > Champion > Blockers
     → If fewer than 4 roles, fill remaining quadrants with the most
       relevant blockers or additional stakeholder groups

  2. BUILD each card from Audience Model + buyer-appendix
     → Each card has 4 elements:
       - Label: role name (e.g., "Economic Buyer", "Technical Evaluator")
       - Sublabel: person title (e.g., "CFO Finanzdezernat", "CTO IT-Infrastruktur")
       - Lead-with line: framing guidance for addressing this person
       - Key messages: 3 bullets with the most important talking points

     → IF supplementary_source (buyer-appendix.md) is available (stored in Step 1):
       READ the "Schnellreferenzkarte" / "Quick Reference Card" section:
         - Use "Lead with" column → card's lead-with instruction
         - Use "Winning Message" / "Gewinnbotschaft" column → first key message
         - Use top 2 talking points from per-role sections → remaining key messages
       This produces narrative-specific, evidence-anchored cards.

     → IF supplementary_source is NOT available, derive from Audience Model:
       - Lead-with: synthesized from stakeholder priority + role heuristics
         EB: "Lead with ROI and risk reduction"
         TE: "Lead with integration compatibility"
         EU: "Lead with workflow simplicity"
         Champion: "Lead with their internal mandate"
       - Key messages: derived from priority, objection, and framing guidance

  3. ASSIGN cards to quadrants
     → Q1 (top-left): Economic Buyer — the ultimate decision-maker
     → Q2 (top-right): Technical Evaluator — the feasibility gatekeeper
     → Q3 (bottom-left): End Users — the daily users
     → Q4 (bottom-right): Champion — the internal ally
     → This clockwise priority mapping ensures the presenter's eye naturally
       starts with the most important person (EB, top-left)

  4. COMPRESS for scanning speed
     → The presenter will glance at this slide for 10-15 seconds
     → Label: max 20 chars (role name)
     → Sublabel: max 30 chars (person title, truncate with "...")
     → Lead-with: max 40 chars
     → Each key message: max 50 chars
     → 3 key messages per card (not 4 — space is limited)

  5. FLAG assumptions
     → IF the Audience Model .assumption_based == true:
       APPEND to Slide-Title: " ({assumption_note})"
       Example EN: "Buying Center (assumption-based)"
       Example DE: "Buying Center (annahmebasiert)"
```

### Condition Check

```text
IF Audience Model was built in Rich mode (Step 2.5):
  USE the already-parsed Audience Model data → GENERATE buying center slide
  (No file re-reading needed — stakeholders, champion, blockers are pre-computed)

IF Audience Model is Lean mode or not available:
  SKIP buying center slide entirely
```

**Backward compatibility:** If the Audience Model was built from pitch-log.json or phase-0-buyer-map.md (self-discovered in Step 2.5), the same data is available. The Buying Center slide format is identical regardless of whether the data came from a caller-provided `audience_context` parameter or from self-discovery.

### Buying Center Output Format

```yaml
## Slide 3: {localized_buying_center_headline}

Layout: four-quadrants

Slide-Title: {localized_buying_center_headline}

Q1:
  Label: "{eb_role_label}"
  Sublabel: "{eb_title}"
  Bullets:
    - "{lead_with_label}: {eb_lead_with}"
    - "{eb_key_message_1}"
    - "{eb_key_message_2}"
    - "{eb_key_message_3}"

Q2:
  Label: "{te_role_label}"
  Sublabel: "{te_title}"
  Bullets:
    - "{lead_with_label}: {te_lead_with}"
    - "{te_key_message_1}"
    - "{te_key_message_2}"
    - "{te_key_message_3}"

Q3:
  Label: "{eu_role_label}"
  Sublabel: "{eu_title}"
  Bullets:
    - "{lead_with_label}: {eu_lead_with}"
    - "{eu_key_message_1}"
    - "{eu_key_message_2}"
    - "{eu_key_message_3}"

Q4:
  Label: "{champion_role_label}"
  Sublabel: "{champion_title}"
  Bullets:
    - "{lead_with_label}: {champion_lead_with}"
    - "{champion_key_message_1}"
    - "{champion_key_message_2}"
    - "{champion_key_message_3}"

Bottom-Banner:
  Text: "{localized_internal_warning}"

Speaker-Notes: |
  >> {WHAT_YOU_SAY_HEADER}

  [{opening_tag}]: "{coaching on how to use each stakeholder card for pitch preparation}"
  [{key_point_tag}]: "{explain primary decision-maker's priority and the framing guidance}"
  [{key_point_tag}]: "{explain champion leverage and how to activate their support}"
  [{key_point_tag}]: "{explain blocker mitigation — know each counter before the meeting}"
  [{transition_tag}]: "{bridge to first content slide — the presentation begins now}"

  >> {WHAT_YOU_NEED_TO_KNOW_HEADER}

  - {context}: This slide is for your preparation only — remove before client presentation
  - {context}: Primary decision-maker: {eb_title} — frame all answers around {eb_priority}
  - {context}: Champion ({champion_title}) is your ally — leverage their {motivation}
  - {context}: Biggest risk: {top_blocker_role} — prepare rebuttal for {blocker_objection}
  - {context}: Pitch focus summary: [EB] → ROI, [TE] → Integration, [EU] → Workflow
```

### Buying Center Localization

| Field | English | German |
|-------|---------|--------|
| Slide headline | Buying Center | Buying Center |
| Lead-with label | Lead with | Führen mit |
| Economic Buyer label | Economic Buyer | Economic Buyer |
| Technical Evaluator label | Technical Evaluator | Technical Evaluator |
| End Users label | End Users | End Users |
| Champion label | Champion | Champion |
| Assumption note | assumption-based | annahmebasiert |
| Internal warning | INTERNAL — REMOVE FROM CLIENT PRESENTATION | INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN |

---

## Per-Slide Extensive Speaker-Notes (Always)

### Why Step 7c Generates Better Notes Than Step 5

Speaker-Notes were previously generated at Step 5, before layouts and arc positions were finalized. At Step 7c, the LLM has the complete picture:

```text
CONTEXT AVAILABLE AT STEP 7c (unavailable at Step 5):

  → Finalized layouts (Step 6): stat-card, two-columns-equal, is-does-means, etc.
    → Enables layout-specific opening techniques
  → Section roles from Story Arc (Step 3c)
    → Enables delivery energy calibration per slide via arc position
  → Complete YAML specifications (Step 7)
    → Enables notes that reference exact slide content
  → Full slide order with arc position
    → Enables transition coaching that names the actual next slide
  → Methodology slide (sub-step 1) with PEAK and RELEASE markers in notes
    → Enables arc-position coaching — the highest-impact addition

Without this context, notes are generic. WITH it, notes become strategic coaching.
```

### Format Reference

Read `references/05b-speaker-notes.md` for the **format specification**:
- Two-section structure ("WHAT YOU SAY" + "WHAT YOU NEED TO KNOW")
- Available delivery tags: `[Opening]`, `[Key point]`, `[Pause]`, `[Emphasis]`, `[Transition]`
- Template syntax (English and German)
- Exclusion rules (no duplication of visible slide content)

Step 7c uses this format but extends it with three additional reasoning layers and one new tag.

### Reasoning Approach: Extensive Speaker-Notes

Before writing notes for each slide, reason through what the presenter needs. Steps 1-7 come from `05b-speaker-notes.md`. Steps 8-10 are the context-aware extensions that make notes extensive.

```text
REASON through speaker notes for each slide:

  ══════════════════════════════════════════
  PHASE A: ESTABLISH ARC POSITION (Step 7c only)
  ══════════════════════════════════════════

  0. ESTABLISH arc position for THIS slide
     → Look up this slide's section role (from Step 3c)
     → Note: is this the PEAK? The RELEASE? Before peak? After release?
     → This establishes delivery energy for everything below

     Position determines the presenter's REGISTER:
       BEFORE PEAK → Build tension. Voice confident but building concern.
         Don't resolve anything — let discomfort accumulate.
       PEAK → Maximum gravity. Slow down. Lower voice. Eye contact.
         This is the slide the audience will remember tomorrow.
       RELEASE → Shift tone from concern to confidence.
         Signal: "Here's the way out." The audience exhales here.
       AFTER RELEASE → Build momentum. Increasing confidence and energy.
         Each slide reinforces the case — move with purpose.
       CTA (closing) → Direct and specific. No preamble. State the ask.

  ══════════════════════════════════════════
  PHASE B: BASE NOTES (from 05b-speaker-notes.md)
  ══════════════════════════════════════════

  1. IDENTIFY what the slide SHOWS vs. what it DOESN'T show
     → [as defined in 05b-speaker-notes.md reasoning step 1]

  2. DECIDE the opening technique based on section role
     → [as defined in 05b reasoning step 2]
     → NOTE: Step 9 below OVERRIDES this with a layout-aware opening

  3. PLAN the verbal arc for "WHAT YOU SAY"
     → [as defined in 05b reasoning step 3]

  4. DECIDE where to place [Pause] and [Emphasis] cues
     → [as defined in 05b reasoning step 4]

  5. CRAFT the [Transition] to the next slide
     → At Step 7c, the next slide's content is KNOWN (Step 7 YAML is complete)
     → Use the actual next headline/topic for a specific transition,
       not a generic bridge
     → Example: "Those 688 lives make the timeline non-negotiable —
       let me show you what happens if we miss the 2026 deadline."
       (references the actual next slide's content)

  6. BUILD "WHAT YOU NEED TO KNOW" from four categories
     → [as defined in 05b reasoning step 6: Sources, Context, Q&A Prep, Caveats]
     → NOTE: Step 10 below EXTENDS Q&A Prep with full audience model

  7. VERIFY the notes against three rules
     → [as defined in 05b reasoning step 7: zero duplication, tone, word count]
     → NOTE: Word count target is 200-400 (not 100-200)

  ══════════════════════════════════════════
  PHASE C: CONTEXT-AWARE EXTENSIONS (Step 7c only)
  ══════════════════════════════════════════

  8. ADD arc-position energy coaching [Energy] tag
     → This tag tells the presenter HOW to deliver this specific slide
       based on its position in the emotional arc
     → The [Energy] tag appears as the FIRST element in "WHAT YOU SAY",
       before the [Opening]

     IF this slide is the PEAK (last problem/urgency slide before first solution):
       [Energy]: "You are at the peak of the argument. Slow down.
       Lower your voice. Make eye contact before revealing [the key number/claim].
       Let it land. Count to three silently before advancing."

     IF this slide is the RELEASE (first solution/proof slide after peak):
       [Energy]: "Shift your tone here — from concern to confidence.
       Straighten your posture. This is where the audience starts to believe.
       Deliver with conviction, not relief."

     IF this slide is BEFORE the peak (building tension):
       [Energy]: "Building tension. Keep your energy controlled —
       concern is building but you haven't reached the crisis yet.
       Each point should tighten the argument."

     IF this slide is AFTER the release (building momentum):
       [Energy]: "Momentum phase. Increase your pace slightly.
       The audience is with you now — reinforce their confidence
       with each proof point."

     → EVERY content slide gets an [Energy] tag
     → German equivalents use [Energie] tag

  9. TAILOR opening technique to the slide's layout
     → This OVERRIDES the section-role-only opening decision from step 2
     → COMBINE: layout-specific technique + arc-position emotional register

     Layout-specific opening techniques:

     stat-card-with-context:
       → PROVOKE: Ask the audience to guess the number before revealing it
       → "How many [X] do you think [Y]?" → pause → reveal hero stat
       → The gap between their guess and reality creates shock

     two-columns-equal:
       → CONTRAST: Frame the comparison verbally before they read either column
       → "On one side... on the other..." → let them discover which is which
       → The verbal framing primes them to see YOUR contrast, not their own

     is-does-means:
       → CONNECT: Link the IS statement back to the problem named earlier
       → "Remember [problem from slide N]? Here's what exists to solve it."
       → The callback creates continuity across the arc

     four-quadrants:
       → UNIFY: Name the theme that connects all four quadrants
       → "Four dimensions of this challenge — let me walk you through each."
       → Without unification, four quadrants feels like four disconnected facts

     three-options:
       → FRAME DECISION: Prime the decision context before revealing options
       → "You have three paths forward. Let me show you the trade-offs."
       → The decision frame makes the audience evaluate, not just absorb

     timeline-steps / gantt-chart:
       → ANCHOR TIME: Establish the temporal frame first
       → "Over the next [timeframe], here's the sequence..."
       → Time context makes each step feel achievable, not abstract

     layered-architecture:
       → ORIENT: Give the structural overview before diving in
       → "Three layers, bottom-up — each one enables the next."
       → Orientation prevents the "where am I?" confusion in technical slides

     DEFAULT (any other layout):
       → Use section-role-based technique from 05b reasoning step 2

  10. EXPAND Q&A prep with full Audience Model per slide
      → This EXTENDS the Q&A Prep section from step 6
      → At Step 7c, the full Audience Model (Step 2.5) is available

      10a. IF supplementary_source (buyer-appendix.md) is available (stored in Step 1):
           READ buyer-appendix.md ONCE and extract:
             → Per-role sections: "Key Messages", phase-specific talking points,
               objection responses with evidence
             → "Blocker Mitigation" section: detailed counter-arguments per blocker
             → "Success Metrics" table: baseline vs. target values
           STORE extracted data as buyer_appendix_context for use in 10b/10c below.

      10b. IF Rich mode (Audience Model available):
        FOR EACH slide, reason: which stakeholders does THIS slide's content
        most affect? Consider the slide's section role (from Step 3c):
          - problem/urgency slides → affects EB (risk/cost), TE (feasibility)
          - solution/proof slides → affects TE (integration), EU (workflow)
          - evidence slides → affects EB (ROI), all blockers
          - call-to-action → affects EB (sign-off), champion (leverage)

        FOR each relevant stakeholder:
          → Retrieve their SPECIFIC objection from the Audience Model
          → IF buyer_appendix_context available:
            Cross-reference the role's objection responses from buyer-appendix.md.
            Adapt the pre-synthesized response to THIS slide's specific evidence.
            This produces evidence-anchored rebuttals instead of generic framing.
          → ELSE:
            Craft a SLIDE-SPECIFIC answer from narrative content:
            "If [EB title] asks about [their objection]: [answer using
            evidence from THIS slide specifically]"
          → Example: "If the CFO asks about implementation risk:
            point to the Munich pilot's 94% uptime on THIS slide —
            that's real production data, not a lab test."

        FOR each blocker whose concern area overlaps THIS slide's content:
          → IF buyer_appendix_context available:
            Load the blocker's detailed mitigation strategy from
            the Blocker Mitigation section. Adapt the counter-argument
            to reference THIS slide's specific data/claim.
          → ELSE:
            Prepare a rebuttal using slide-specific evidence
          → "If [blocker role] challenges [their objection]:
            [rebuttal anchored in this slide's data/claim]"

        TARGET: 3-5 prepared Q&A items per slide (Rich mode)
        PRIORITY: Lead with the primary decision-maker's likely question,
          then champion's leverage point, then blocker rebuttals

      10c. IF Lean mode (no Audience Model):
        → Predict using generic role heuristics:
          CFO → "What does this cost? What's the ROI?"
          CTO → "How does this integrate? What's the architecture?"
          Safety/compliance → "Is this certified? What's the liability?"
          Operations → "How long to implement? What resources?"
        → IF buyer_appendix_context available:
          Cross-reference generic questions against buyer-appendix objection
          responses for evidence-based answers (even in Lean mode, the buyer
          appendix provides concrete response material)
        → Target: 3-4 predicted questions per slide minimum
        → The UNCOMFORTABLE question IS the one the audience thinks
          but won't ask — prepare for THAT one specifically
```

### New Tag: [Energy] / [Energie]

| English Tag | German Tag | When to Use |
|-------------|-----------|-------------|
| `[Energy]` | `[Energie]` | Arc-position delivery coaching — on EVERY content slide, as the FIRST element in "WHAT YOU SAY" before [Opening] |

This tag is the ONLY structural addition to the 05b tag system. All other tags (`[Opening]`, `[Key point]`, `[Pause]`, `[Emphasis]`, `[Transition]`) remain as defined in `05b-speaker-notes.md`.

### Length Guidelines (Extensive Notes)

Per-slide targets (replacing 05b's 100-200 word guidance):

| Slide Type | Word Target | Rationale |
|------------|-------------|-----------|
| Title slide | 150-250 words | Arc overview, first impression coaching, audience context |
| Problem/urgency (PEAK) | 250-400 words | Maximum coaching depth — this is THE critical delivery moment |
| Evidence slides | 200-350 words | Source depth + comprehensive Q&A prep for all stakeholders |
| Solution/proof (RELEASE) | 200-350 words | Tone-shift coaching + objection rebuttals |
| Options/roadmap slides | 200-300 words | Decision facilitation coaching |
| Closing slide | 200-300 words | CTA delivery coaching + follow-up actions |

**Overall target:** 200-400 words per slide
**Hard minimum:** 150 words (below this, the presenter is unsupported)
**Hard maximum:** 450 words (above this, the presenter cannot scan under pressure)

**Why higher targets are justified at Step 7c:**
- `[Energy]` arc-position cues are new content (not available at Step 5)
- Full audience Q&A prep (all stakeholders, all objections) adds significant depth
- Layout-aware opening coaching adds concrete delivery instructions
- Specific transitions (referencing actual next slide) require more words
- The notes are now a complete rehearsal tool, not just a safety net

### Generation Process

```text
PREREQUISITE: Sub-steps 1 (Slide 2: Methodology) and 2 (Slide 3: Buying Center) are COMPLETE.
  → The Methodology pipeline is finalized; PEAK/RELEASE markers are computed for Speaker-Notes pacing guide
  → The Audience Model stakeholder data is available (if Rich mode)

FOR each slide (content slides AND internal prep slides):

  0. LOOK UP arc position from Methodology slide (sub-step 1)
     → Record: section role (from Step 3c), PEAK/RELEASE status, position relative to peak

  1-7. APPLY 05b-speaker-notes.md reasoning steps 1-7
     → Generate "WHAT YOU SAY" with [Opening], [Key point], [Pause], [Emphasis], [Transition]
     → Generate "WHAT YOU NEED TO KNOW" with Sources, Context, Q&A Prep, Caveats
     → Use 200-400 word target (not 100-200)

  8. PREPEND [Energy] tag as the first element in "WHAT YOU SAY"
     → Calibrated to arc position (step 0)

  9. REFINE [Opening] using layout-aware technique
     → Replace the section-role-only opening with layout+arc-position combined technique

  10. EXTEND "WHAT YOU NEED TO KNOW" Q&A section
      → Add all relevant stakeholder objections with slide-specific answers

  VERIFY:
    → Word count in 200-400 range (150-450 hard bounds)
    → [Energy] tag present as first element
    → Both sections present and non-empty
    → Zero duplication of visible slide content
    → Transitions reference actual next-slide content
    → Q&A covers all relevant stakeholder objections (Rich mode: 3-5 items minimum)
```

### Extended Template (English)

```yaml
Speaker-Notes: |
  >> WHAT YOU SAY

  [Energy]: "Building tension. Keep your energy controlled — concern is building but you haven't reached the crisis yet."
  [Opening]: "Ask the audience: 'How many preventable deaths occur on German rails annually?' Let them guess before revealing the number."
  [Key point]: "The 688 figure is a 3-year average — and the trend is rising sharply: 612, then 679, now 773."
  [Key point]: "Manual monitoring simply cannot cover a network of this scale — this isn't a staffing problem, it's a structural impossibility."
  [Pause]: Let the number sink in before continuing.
  [Emphasis]: "Every month of delay costs lives — not hypothetically, but statistically."
  [Transition]: "These numbers make the 2026 regulatory deadline non-negotiable — let me show you what that timeline demands."

  >> WHAT YOU NEED TO KNOW

  - Source: 688 is a 3-year average (2021-2023) from the [Federal Rail Safety Report 2024](https://eba.bund.de/report). Trend: 612 (2021) → 679 (2022) → 773 (2023).
  - Context: Germany has highest absolute EU numbers, but per-capita rates comparable to France. Don't overstate the "Germany is uniquely bad" angle.
  - If the CFO asks about cost of inaction: "Each incident costs an average of EUR 1.2M in response, investigation, and service disruption — multiply by 688."
  - If the CTO challenges technical feasibility: "Munich pilot ran for 6 months with 94% uptime on live infrastructure — point to this data on Slide 6."
  - If the safety officer asks about liability: "Under the 2026 EU Rail Safety Directive, operators without automated monitoring face personal liability for board members."
  - If [blocker: Head of Operations] challenges implementation timeline: "Munich pilot was operational in 14 weeks — we have the deployment playbook."
  - Caveat: 2,661 station attacks figure comes from BKA crime statistics, not rail safety data. Different counting methodology — don't conflate the two sources.
  - Caveat: If presenter accidentally mixes the two data sources, correcting themselves shows rigor rather than weakness.
```

### Extended Template (German)

```yaml
Speaker-Notes: |
  >> WAS SIE SAGEN

  [Energie]: "Spannungsaufbau. Halten Sie Ihre Energie kontrolliert — die Besorgnis wächst, aber Sie haben die Krise noch nicht erreicht."
  [Einstieg]: "Fragen Sie: 'Wie viele vermeidbare Todesfälle gibt es jährlich auf deutschen Schienen?' Lassen Sie das Publikum raten."
  [Kernaussage]: "Die 688 ist ein 3-Jahres-Durchschnitt — Tendenz stark steigend: 612, dann 679, jetzt 773."
  [Kernaussage]: "Manuelle Überwachung kann ein Netz dieser Größe schlicht nicht abdecken — das ist kein Personalproblem, sondern strukturell unmöglich."
  [Pause]: Lassen Sie die Zahl wirken, bevor Sie fortfahren.
  [Betonung]: "Jeder Monat Verzögerung kostet Menschenleben — nicht hypothetisch, sondern statistisch belegt."
  [Überleitung]: "Diese Zahlen machen die regulatorische Frist 2026 unverhandelbar — lassen Sie mich zeigen, was dieser Zeitplan verlangt."

  >> WAS SIE WISSEN MÜSSEN

  - Quelle: 3-Jahres-Durchschnitt (2021-2023) aus dem [Bundesbericht Schienensicherheit 2024](https://eba.bund.de/report). Trend: 612→679→773.
  - Kontext: Deutschland hat die höchsten absoluten EU-Zahlen, Pro-Kopf vergleichbar mit Frankreich. Nicht übertreiben.
  - Bei Rückfrage des CFO zu Kosten der Untätigkeit: "Jeder Vorfall kostet durchschnittlich 1,2 Mio. EUR — mal 688."
  - Bei Rückfrage des CTO zur technischen Machbarkeit: "München-Pilot lief 6 Monate mit 94% Verfügbarkeit auf Live-Infrastruktur — verweisen Sie auf Folie 6."
  - Bei Rückfrage des Sicherheitsbeauftragten zur Haftung: "Ab 2026 greift die EU-Schienensicherheitsrichtlinie — persönliche Vorstandshaftung ohne automatisierte Überwachung."
  - Bei Einwand [Blocker: Betriebsleiter] zum Zeitplan: "München-Pilot war in 14 Wochen betriebsbereit — Deployment-Playbook vorhanden."
  - Hinweis: 2.661 Bahnhofsübergriffe stammen aus der BKA-Kriminalstatistik, nicht aus Bahnsicherheitsdaten — andere Zählmethodik.
```

### Speaker-Notes Localization

| Field | English | German |
|-------|---------|--------|
| Section header 1 | `>> WHAT YOU SAY` | `>> WAS SIE SAGEN` |
| Section header 2 | `>> WHAT YOU NEED TO KNOW` | `>> WAS SIE WISSEN MÜSSEN` |
| Energy tag | `[Energy]` | `[Energie]` |
| Before-peak coaching | Keep your energy controlled — concern is building | Halten Sie Ihre Energie kontrolliert — die Besorgnis wächst |
| Peak coaching | Slow down. Lower your voice. Make eye contact. | Verlangsamen Sie. Senken Sie die Stimme. Blickkontakt. |
| Release coaching | Shift tone from concern to confidence. | Tonwechsel: von Sorge zu Zuversicht. |
| After-release coaching | Increase your pace. The audience is with you. | Erhöhen Sie das Tempo. Das Publikum ist bei Ihnen. |
| CTA coaching | Be direct and specific. State the ask. | Direkt und konkret. Formulieren Sie die Bitte. |
| Q&A prefix (Rich) | If [role] asks about [topic] | Bei Rückfrage des [Rolle] zu [Thema] |
| Q&A prefix (Lean) | If asked about [topic] | Bei Rückfrage zu [Thema] |
| Blocker prefix | If [role] challenges [topic] | Bei Einwand [Rolle] zu [Thema] |

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|--------------|-------------|-----|
| Stakeholder info split by category instead of per-person cards | Presenter cannot see the full picture for any single person | Give each stakeholder a self-contained card with role, title, lead-with, and key messages |
| Using two-columns-equal for methodology | Dense text bullets are not scannable | Use process-flow with Detail-Grid for visual pipeline |
| Using two-columns-equal for buying center | Dense bullet list not scannable per-person | Use four-quadrants text-card mode for card grid |
| Missing PEAK/RELEASE markers in methodology notes | Presenter delivers every slide with same energy | Always identify and mark the tension peak and release point in Speaker-Notes |
| Methodology pipeline without Detail-Grid | Presenter sees phase names but not key concepts per phase | Always include Detail-Grid with 3-4 items per pipeline node |
| Raw data without strategic context | Slide becomes an information dump, not a briefing | Apply scanning speed principle: 15-second comprehension target |
| Generating buying center in Lean mode | Assumption-based data presented as fact | Skip Slide 3 (Buying Center) entirely when no real stakeholder data exists |
| Forgetting assumption-based flag | Presenter speaks authoritatively about unverified roles | Append "(assumption-based)" to slide title when model is assumption-based |
| Missing Bottom-Banner INTERNAL warning | Internal prep slides ship to client by accident | Every internal prep slide MUST have Bottom-Banner with INTERNAL warning |
| Generating notes without layout/arc context (at Step 5) | Opening technique is generic; arc coaching impossible; transitions are generic | Generate at Step 7c after layouts and arc positions are finalized |
| Limiting Q&A prep to 1-2 questions per slide | Leaves presenter unprepared for specific stakeholder objections | Cover ALL relevant stakeholder objections per slide (3-5 items Rich mode) |
| Missing [Energy] tag on content slides | Presenter delivers every slide with the same energy level | Every content slide gets [Energy] — calibrated to arc position |
| Speaker-Notes under 150 words | Presenter is unsupported — notes are a thin safety net, not coaching | Target 200-400 words with arc coaching, layout-aware opening, full Q&A |
| Skipping Speaker-Notes on internal prep slides | Presenter doesn't know how to USE the prep slides | Internal prep slides get comprehensive notes explaining their purpose and how to leverage them |
