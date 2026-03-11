# Speaker Notes — Format Reference

> **Generation home:** Speaker-Notes are generated in **Step 7c** (`08c-presenter-prep.md`), not Step 5. This file defines the **format specification**: two-section structure, available tags, templates, and localization. Step 7c references this file for format rules and extends it with arc-position coaching, layout-aware openings, comprehensive audience Q&A, and Speaker-Notes for internal prep slides.

## Purpose

Define the two-section speaker notes format for each slide, giving the presenter both a delivery script and a knowledge safety net. Speaker notes are the invisible layer that turns a good deck into a confident performance — they tell the presenter what to SAY, HOW to say it, and what to KNOW when challenged.

---

## Two-Section Structure

Every slide gets speaker notes split into two clearly separated sections:

1. **"WHAT YOU SAY"** — A delivery script: what the presenter says out loud, in what order, with cues for pacing and emphasis. This is the section to rehearse.
2. **"WHAT YOU NEED TO KNOW"** — Background knowledge: sources, data provenance, context, and prepared answers to likely questions. This is the safety net for credibility and Q&A.

---

## Exclusions

Content that does NOT belong in speaker notes:

- Content already visible on the slide (no duplication)
- Full paragraphs copied from the narrative (summarize instead)
- Entire source documents
- Content the audience can read themselves

---

## Template (English)

```yaml
Speaker-Notes: |
  >> WHAT YOU SAY

  [Opening]: "Ask the audience: 'How many preventable deaths occur on German rails annually?' Let them guess before revealing the number."
  [Key point]: "The 688 figure is a 3-year average — and the trend is rising sharply."
  [Key point]: "Manual monitoring simply cannot cover a network of this scale."
  [Pause]: Let the number sink in before continuing.
  [Transition]: "These numbers make the 'why now' question unavoidable..."

  >> WHAT YOU NEED TO KNOW

  - Source: 688 is a 3-year average (2021-2023) from the [Federal Rail Safety Report 2024](https://eba.bund.de/report). Trend: 612 (2021) → 679 (2022) → 773 (2023).
  - Germany has the highest absolute EU numbers, but per-capita rates are comparable to France.
  - If asked about regional variance: Bavaria accounts for 23% of all incidents.
  - Methodology: Federal Rail Authority counts all incidents within 500m of tracks.
  - The 2,661 station attacks figure comes from BKA crime statistics, not rail safety data.
```

## Template (German)

```yaml
Speaker-Notes: |
  >> WAS SIE SAGEN

  [Einstieg]: "Fragen Sie: 'Wie viele vermeidbare Todesfälle gibt es jährlich auf deutschen Schienen?' Lassen Sie das Publikum raten."
  [Kernaussage]: "Die 688 ist ein 3-Jahres-Durchschnitt — Tendenz stark steigend."
  [Kernaussage]: "Manuelle Überwachung kann ein Netz dieser Größe schlicht nicht abdecken."
  [Pause]: Lassen Sie die Zahl wirken, bevor Sie fortfahren.
  [Überleitung]: "Diese Zahlen machen die Dringlichkeit unmissverständlich..."

  >> WAS SIE WISSEN MÜSSEN

  - Quelle: 3-Jahres-Durchschnitt (2021-2023) aus dem [Bundesbericht Schienensicherheit 2024](https://eba.bund.de/report). Trend: 612→679→773.
  - Deutschland hat die höchsten absoluten EU-Zahlen, Pro-Kopf vergleichbar mit Frankreich.
  - Bei Rückfrage zu regionalen Unterschieden: Bayern hat 23% der Vorfälle.
  - Methodik: EBA zählt alle Vorfälle im Umkreis von 500m der Gleise.
  - Die 2.661 Bahnhofsübergriffe stammen aus der BKA-Kriminalstatistik, nicht aus Bahnsicherheitsdaten.
```

---

## Available Tags

| English Tag | German Tag | When to Use |
|-------------|-----------|-------------|
| `[Opening]` | `[Einstieg]` | First thing the presenter says — a question, provocative statement, or scene-setter |
| `[Key point]` | `[Kernaussage]` | A talking point that expands on or explains a slide element |
| `[Pause]` | `[Pause]` | Delivery cue — let a number land, create tension, invite reflection |
| `[Emphasis]` | `[Betonung]` | Draw special attention to a word, phrase, or contrast |
| `[Transition]` | `[Überleitung]` | Bridge to the next slide — always the last tag in "WHAT YOU SAY" |

---

## Length Guidelines

> **Active targets** are defined in `08c-presenter-prep.md` (200-400 words per slide). The values below are the base format minimums.

- Minimum: 150 words (below this, the presenter is unsupported)
- Target: 200-400 words per slide (with arc coaching, layout-aware openings, comprehensive Q&A)
- Maximum: 450 words (above this, the presenter cannot scan under pressure)

---

## Reasoning Approach

Speaker notes generation is NOT transcription — it is presentation coaching. The goal is to give the presenter a verbal script that ADDS to the slide (not repeats it) and a knowledge safety net that prevents embarrassment during Q&A.

Before writing notes for each slide, reason through what the presenter needs:

```text
REASON through speaker notes for each slide:

  1. IDENTIFY what the slide SHOWS vs. what it DOESN'T show
     → Read the slide's visible content: headline, hero stat, bullets, banner
     → List what the audience can READ for themselves
       → This content is OFF-LIMITS for "WHAT YOU SAY" (no duplication)
     → Ask: "What does the audience NEED TO HEAR to understand why this matters?"
       → This is the verbal layer that makes the slide land
     → Ask: "What would make the presenter look SMART if asked?"
       → This is the knowledge safety net

     WHY: The worst speaker notes are a transcript of the slide. The audience
     reads the slide in 3 seconds, then listens for 60 seconds. Those 60 seconds
     must add value the slide cannot deliver alone.

  2. DECIDE the opening technique based on the slide's section role (from Step 3c)
     → The opening sets the emotional register for the entire slide.
       Match the section role to the appropriate technique:

     → Section role: problem or urgency → PROVOKE: Ask a question that shocks
       "How many preventable deaths occur on German rails annually?"
       WHY: Problem/urgency slides need emotional activation. A question forces
       the audience to engage before seeing the answer. The gap between
       their guess and the real number creates shock.

     → Section role: evidence → FRAME: Provide context before the data
       "Let me put this market data in perspective..."
       WHY: Evidence slides need the presenter to explain WHY the data matters.
       Without framing, facts feel like a data dump.

     → Section role: solution or proof → CONNECT: Link back to the problem before celebrating
       "Remember the 48-hour response time? Here's where we are now."
       WHY: Solution/proof slides earn impact by referencing the pain they resolve.
       Celebration without contrast feels hollow.

     → Section role: call-to-action → DIRECT: State the specific ask immediately
       "Here's what I need from you by end of quarter."
       WHY: CTA slides work best when the presenter is direct and specific.
       Hesitation or preamble dilutes the ask.

     → Section role: hook, options, roadmap, investment → FRAME (default)
       Use context-setting openings appropriate to the content.

  3. PLAN the verbal arc for "WHAT YOU SAY"
     → A slide's spoken delivery has its own mini-arc:
       Opening → Key points → Pause/Emphasis → Transition
     → Ask for each key point: "Does this EXPLAIN, AMPLIFY, or PROVE?"

       EXPLAIN: The audience can read the bullet but not understand WHY
         → "That 42% figure — those are systems older than the Berlin Wall."
         → Use when the slide has technical data the audience can't interpret alone

       AMPLIFY: The data is clear but the emotional weight needs boosting
         → "688. That's nearly two people every single day."
         → Use when the number is correct but the SCALE isn't felt

       PROVE: The headline makes a claim the audience might doubt
         → "We validated this at the Munich pilot site last quarter."
         → Use when the slide asserts a result without showing the evidence

     → Place key points in IMPACT ORDER, not slide-element order
       × Walk through bullets top-to-bottom (reads like a teleprompter)
       ✓ Lead with the most surprising insight, then support it

  4. DECIDE where to place [Pause] and [Emphasis] cues
     → [Pause] is for AFTER emotional impact — let the audience process
       - After revealing a shocking number: "688 deaths. [Pause]"
       - After a before/after contrast: "48 hours to 15 minutes. [Pause]"
       - Before the transition: give the audience a beat to absorb
       - RULE: Max 1-2 pauses per slide. More than 2 feels theatrical.
     → [Emphasis] is for DURING delivery — vocal stress on specific words
       - On a number: "EVERY month of delay costs two hundred thirty thousand"
       - On a contrast word: "not IF, but WHEN"
       - On the differentiator: "the ONLY solution certified for German rail"
       - RULE: Max 1 emphasis per slide. Overuse dilutes everything.

     WHY: Delivery cues are the difference between reading notes and
     performing them. A well-placed pause after "688 deaths" is worth
     more than three additional bullets of explanation. But too many
     pauses or emphases signal that EVERYTHING is important — which
     means nothing is.

  5. CRAFT the [Transition] — how this slide hands off to the next
     → The transition connects THIS slide's message to the NEXT slide's message
     → Ask: "What question does THIS slide raise that the NEXT slide answers?"

       Slide (problem) → Slide (urgency):
         "These numbers are bad — but the timing makes them critical..."
       Slide (urgency) → Slide (solution):
         "So the question isn't whether to act, but how..."
       Slide (proof) → Slide (investment):
         "Now that you've seen it works, let's talk about what it costs..."
       Slide (investment) → Slide (CTA):
         "The numbers work. Here's how we start..."

     → NEVER end without a transition (except the closing slide)
     → NEVER use generic transitions ("Let's move on", "Next slide please")
     → The best transitions create ANTICIPATION for the next slide

     WHY: A transition is the narrative thread that holds the deck together.
     Without it, each slide feels like an island. With it, the audience
     experiences a flowing argument, not a series of disconnected facts.

  6. BUILD "WHAT YOU NEED TO KNOW" from four categories
     → This section is a QUICK-REFERENCE bullet list (not prose).
       The presenter glances at it in 3 seconds during Q&A.

     → SOURCES: Where does every number on this slide come from?
       - Include [label](url) inline links when URLs are available
       - Note the specific section/page if you have it
       - If a number is a calculated average, show the components:
         "688 = 3-year average: 612 (2021), 679 (2022), 773 (2023)"
       - ASK: "If challenged on any number, can the presenter cite the source?"

     → CONTEXT: What additional facts give the presenter authority?
       - Trend direction (is the number rising, falling, or stable?)
       - Peer comparison (how does this compare to competitors/countries?)
       - Scope/methodology (what does the number include/exclude?)
       - ASK: "What would a domain EXPERT add that isn't on the slide?"

     → Q&A PREP: What will the audience likely ask?
       - Use "If asked about X: [answer]" format

       IF Audience Model available (Rich mode):
         - USE actual stakeholder objections as predicted questions:
           EB objection → prepare direct answer addressing their specific concern
           TE objection → prepare direct answer addressing their specific concern
           EU objection → prepare direct answer addressing their specific concern
           Blocker objections → prepare rebuttal for each blocker's concern
         - The UNCOMFORTABLE question IS the blocker's primary objection
         - Include 1-2 prepared answers per slide minimum, prioritized by
           which stakeholder this slide's content is most relevant to

       IF no Audience Model (Lean mode):
         - PREDICT questions by considering generic audience roles:
           CFO → "What does this cost? What's the ROI?"
           CTO → "How does this integrate? What's the architecture?"
           Safety officer → "Is this certified? What's the liability?"

       - Include 1-2 prepared answers per slide minimum
       - ASK: "What's the most UNCOMFORTABLE question this slide invites?"
         → Prepare an answer for THAT question specifically
         → The uncomfortable question is the one the audience is thinking
           but not asking. Preparing for it builds unshakeable credibility.

     → CAVEATS: Limitations the presenter should acknowledge (not hide)
       - Data limitations ("This is Germany-only; EU-wide figures differ")
       - Methodology notes ("BKA counts differently from EBA")
       - Scope boundaries ("This covers stations, not open track")

     WHY: The presenter's worst moment is being asked a question they
     can't answer. "WHAT YOU NEED TO KNOW" prevents that moment.
     It costs nothing to include, and saves the presenter once per deck.

  7. VERIFY the notes against three rules
     → RULE 1: Zero duplication — nothing in notes appears verbatim on slide
       Read each note line. Is it on the slide? → DELETE it.
     → RULE 2: Spoken vs. reference tone
       "WHAT YOU SAY" reads like speech (test: read it aloud — natural?)
       "WHAT YOU NEED TO KNOW" reads like bullet notes (test: scan in 3 sec)
     → RULE 3: Word count in range — 200-400 words target
       If < 150: the presenter is unsupported → add arc coaching and Q&A prep
       If > 450: the presenter can't scan it → move detail to a handout
```

---

## Generation Process

```text
FOR each slide:
  1. POPULATE "WHAT YOU SAY":
     a. CRAFT an [Opening] — how should the presenter introduce this slide?
        - For stat cards: a question that makes the audience guess the number
        - For comparisons: frame the contrast verbally before the audience reads it
        - For solutions: connect back to the problem slide
     b. ADD [Key point] tags for each major element on the slide
        - Explain WHY this matters, not WHAT it shows (they can read that)
        - Add context that makes the data memorable
        - Use conversational language (this is spoken, not written)
     c. ADD [Pause] or [Emphasis] where delivery timing matters
     d. CLOSE with [Transition] — how does this slide connect to the next one?

  2. POPULATE "WHAT YOU NEED TO KNOW":
     a. SOURCES: Where does every number on this slide come from?
        Include [label](url) inline links when URLs are available
     b. CONTEXT: What additional facts give the presenter authority?
        - Trend data (is the number rising or falling?)
        - Comparisons (how does this compare to peers/competitors/benchmarks?)
        - Scope/methodology (what does the number include/exclude?)
     c. Q&A PREP: What will the audience likely ask?
        Use "If asked about X: [answer]" format
     d. CAVEATS: Any limitations or nuances the presenter should be aware of

  3. VERIFY:
     - "WHAT YOU SAY" reads like a natural verbal delivery script
     - "WHAT YOU NEED TO KNOW" is a quick-reference bullet list, not prose
     - No slide content is duplicated — notes ADD to the slide, not repeat it
     - Both sections are present (neither is empty)
```

---

## Special Cases

- **Title slide**: "WHAT YOU SAY" contains welcome, context-setting, and preview of the argument. "WHAT YOU NEED TO KNOW" optional (audience context, event details).
- **Closing slide**: "WHAT YOU SAY" contains CTA delivery and specific follow-up actions. "WHAT YOU NEED TO KNOW" contains contact details, scheduling links, next concrete steps.
- **Stat cards**: "WHAT YOU NEED TO KNOW" MUST include source citations, trend context, and at least one Q&A prep item.
- **Comparison slides**: "WHAT YOU NEED TO KNOW" includes nuances, edge cases, and methodology differences between compared items.

---

## End-to-End Worked Example

Complete speaker notes reasoning for one slide, showing all steps:

```text
═══════════════════════════════════════════════
INPUT: Slide from Step 7
═══════════════════════════════════════════════

## Slide 3: 688 Lives Lost Annually to Preventable Rail Incidents

Layout: stat-card-with-context
Section role (from Step 3c): problem

Hero-Stat-Box:
  Number: 688
  Label: rail suicides per year
  Sublabel: + 2,661 attacks on stations

Context-Box:
  Headline: Why manual monitoring fails
  Bullets:
    - Security staff cannot cover all areas 24/7
    - Critical events detected too late to intervene
    - Network too large for point-based surveillance

Bottom-Banner:
  Text: Germany leads EU statistics in rail incidents

═══════════════════════════════════════════════
STEP 1: IDENTIFY what the slide SHOWS vs. DOESN'T show
═══════════════════════════════════════════════

  Visible to audience:
    - 688 (hero number)
    - "rail suicides per year" (label)
    - "+ 2,661 attacks on stations" (sublabel)
    - 3 bullets about why monitoring fails
    - Banner: Germany leads EU stats

  NOT visible (candidates for notes):
    - Where 688 comes from (source, methodology)
    - Whether 688 is rising or falling (trend)
    - How Germany compares to other countries (per-capita)
    - What the 2,661 figure includes/excludes
    - Regional breakdown within Germany
    - What "preventable" means specifically

═══════════════════════════════════════════════
STEP 2: DECIDE opening technique
═══════════════════════════════════════════════

  Section role: problem → PROVOKE technique

  → Use a question that forces the audience to confront the number
  → "Ask the audience: 'How many preventable deaths occur on German
     rails annually?' Let them guess before revealing the number."

  WHY this works: The audience's guesses will be LOW (people
  underestimate rail deaths). The gap between their guess and 688
  creates shock. Shock creates receptiveness to the solution.

  Alternative considered: Leading with the number directly
    "688 people die on German rails every year."
    → Rejected: stating the answer skips the engagement step.
    → The question makes the audience WORK for the insight.

═══════════════════════════════════════════════
STEP 3: PLAN verbal arc
═══════════════════════════════════════════════

  [Opening]: Question technique (provoke)

  [Key point 1]: AMPLIFY — "688 is a 3-year average, trend rising"
    → The number on the slide is static. The trend makes it WORSE.
    → "612, then 679, now 773" — the acceleration is the real story
    → This is NOT on the slide — it adds a new dimension (trajectory)

  [Key point 2]: EXPLAIN — "Manual monitoring can't scale"
    → The bullets explain WHAT fails. The verbal adds WHY it's unfixable.
    → "Simply cannot" frames it as structural, not a resourcing problem
    → This connects to the solution slides later (AI can scale)

  → Impact order: Trend first (emotional amplifier), then structural
    explanation (logical setup for solution). Not top-to-bottom bullet reading.

═══════════════════════════════════════════════
STEP 4: PLACE delivery cues
═══════════════════════════════════════════════

  [Pause] after key point 1 (trend reveal):
    → The audience needs a moment to process that it's getting WORSE
    → Placed AFTER "612, 679, 773" — the acceleration needs to land

  No [Emphasis] needed:
    → The number 688 carries its own weight from the opening question
    → Adding vocal emphasis to "six hundred eighty-eight" would feel
      forced. The question technique already creates the emphasis.

═══════════════════════════════════════════════
STEP 5: CRAFT transition
═══════════════════════════════════════════════

  This slide (problem, crisis) → Next slide (urgency or further problem)
  → Question THIS slide raises: "How bad is this really?"
  → NEXT slide answers: "It's getting worse, and deadlines loom"

  Transition: "These numbers make the 'why now' question unavoidable..."
  → Creates anticipation for urgency content
  → Avoids generic "Let's move on to..." phrasing

═══════════════════════════════════════════════
STEP 6: BUILD "WHAT YOU NEED TO KNOW"
═══════════════════════════════════════════════

  SOURCES:
    → 688 = 3-year average (2021-2023)
    → From: Federal Rail Safety Report 2024, Section 4.2
    → URL: https://eba.bund.de/report
    → Breakdown: 612 (2021) → 679 (2022) → 773 (2023)

  CONTEXT:
    → Germany has highest absolute EU numbers
    → BUT per-capita rates comparable to France (important nuance —
      prevents the "Germany is uniquely bad" misinterpretation)
    → Methodology: EBA counts all incidents within 500m of tracks

  Q&A PREP:
    → Most likely question: "Is this just a German problem?"
      → Answer: "Highest absolute, but per-capita comparable to France"
    → Second most likely: "Where in Germany is it worst?"
      → Answer: "Bavaria accounts for 23% of all incidents"
    → Uncomfortable question: "Why do you call them 'preventable'?"
      → Answer: "Detection within 30 seconds enables intervention in
        >60% of cases — proven in Munich pilot" (bridge to solution)

  CAVEATS:
    → 2,661 attacks figure from BKA crime statistics, NOT rail safety data
    → Different counting methodology — don't conflate the two sources
    → If presenter accidentally mixes them up, correcting shows rigor

═══════════════════════════════════════════════
STEP 7: VERIFY
═══════════════════════════════════════════════

  RULE 1 — Zero duplication:
    → "688" appears in notes as CONTEXT (trend breakdown), not repetition ✓
    → Bullets about monitoring are NOT repeated — notes add "why" layer ✓
    → Banner text ("Germany leads EU") NOT duplicated ✓

  RULE 2 — Tone appropriate:
    → "WHAT YOU SAY": Read aloud — "Ask the audience..." → natural ✓
    → "WHAT YOU NEED TO KNOW": Scan in 3 seconds — bullet format ✓

  RULE 3 — Word count:
    → "WHAT YOU SAY": ~65 words
    → "WHAT YOU NEED TO KNOW": ~100 words
    → Total: ~165 words (base format — Step 7c extends to 200-400 with arc coaching, layout-aware openings, and Q&A)

═══════════════════════════════════════════════
OUTPUT: COMPLETE SPEAKER NOTES
═══════════════════════════════════════════════

Speaker-Notes: |
  >> WHAT YOU SAY

  [Opening]: "Ask the audience: 'How many preventable deaths occur on
  German rails annually?' Let them guess before revealing the number."
  [Key point]: "The 688 figure is a 3-year average — and the trend
  is rising sharply: 612, then 679, now 773."
  [Key point]: "Manual monitoring simply cannot cover a network of
  this scale."
  [Pause]: Let the number sink in before continuing.
  [Transition]: "These numbers make the 'why now' question unavoidable..."

  >> WHAT YOU NEED TO KNOW

  - Source: 688 is a 3-year average (2021-2023) from the
    [Federal Rail Safety Report 2024](https://eba.bund.de/report).
    Trend: 612 (2021) → 679 (2022) → 773 (2023).
  - Germany has highest absolute EU numbers, but per-capita rates
    comparable to France.
  - If asked about regional variance: Bavaria accounts for 23% of
    all incidents.
  - If asked "why preventable?": detection within 30 seconds enables
    intervention in >60% of cases (Munich pilot data).
  - Methodology: Federal Rail Authority counts incidents within 500m
    of tracks.
  - The 2,661 station attacks figure comes from BKA crime statistics,
    not rail safety data — different counting methodology.
```

---
