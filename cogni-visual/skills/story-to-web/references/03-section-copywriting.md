# Section Copywriting

## Purpose

Define web-specific headline hierarchy, CTA copy patterns, body text constraints, and number play techniques for web narrative sections.

> **Core Principle:** Web narratives are scrolled, not clicked through. Every section competes with the reader's thumb. Headlines must stop the scroll, body text must reward the pause, and numbers must create an emotional response — all in under 5 seconds of scanning time per section.

---

## Web Headline Hierarchy

Web headlines follow a different hierarchy than slides. Prioritize transformation language:

### Priority Order

1. **Transformation** — What changes for the reader ("Ihre Fertigung wird unaufhaltsam")
2. **Outcome** — What they achieve ("73% weniger Stillstand")
3. **Benefit** — What they gain ("Kosten senken, Qualitat steigern")

### Headline Rules

| Rule | Constraint | Example |
|------|-----------|---------|
| Must be assertion | Contains a verb | "Sensoren lesen den Maschinenzustand" |
| Max length | 70 characters | Longer than slides (60) for web readability |
| No topic labels | Never "Uberblick", "Zusammenfassung" | Use the assertion instead |
| Hero headline | Transformation-first, 10 words max | "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" |
| Section headline | Outcome or benefit, 12 words max | "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" |
| Card headline | Feature-focused, 6 words max | "Echtzeit-Zustandsuberwachung" |

### Headline Reasoning Process

Headline writing is NOT mechanical formula application — it is message distillation for a scroll-driven medium. Before writing each headline, reason through the transformation, outcome, and benefit priority:

```text
REASON through headline construction for each section:

  1. IDENTIFY the section's core message from the narrative
     → What is the ONE claim this section must communicate?
     → If you cannot state it in one sentence, the section is too broad — split it.

  2. CLASSIFY using the priority order
     → Does this section describe a TRANSFORMATION? (what changes)
       → Lead with the transformation verb: "macht", "verwandelt", "enables"
       → Example: "Predictive Maintenance macht Ihre Fertigung unaufhaltsam"
     → Does it prove an OUTCOME? (what they achieve)
       → Lead with the number or result: "73% weniger Stillstand..."
       → Example: "73% weniger Stillstand in der Pilotlinie bewiesen"
     → Does it describe a BENEFIT? (what they gain)
       → Lead with what improves: "Kosten senken..."
       → Example: "Kosten senken, Qualitat steigern — in einem Schritt"
     → RULE: Never fall below the benefit level to a topic label.
       A topic label means you have not yet distilled the message.

  3. INJECT a number (if the section has data)
     → Scan the narrative section for the most impactful statistic
     → Weave it naturally into the headline:
       ✗ "Die Situation im Maschinenbau" (topic label — no verb, no number)
       ✓ "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" (number + verb + consequence)
     → If no number exists: use a strong verb + specific claim instead
       ✗ "Unsere Losung" (vague label)
       ✓ "Sensoren lesen den Maschinenzustand in Echtzeit" (specific + active)

  4. ACTIVATE the verb
     → Web readers scan faster than slide audiences — passive voice loses them
     → Test: Is the subject DOING something?
       ✗ "Stillstande werden reduziert" (passive — by whom?)
       ✓ "Predictive Maintenance senkt Stillstande um 73%" (active — PM does the work)
     → Test: Is there a verb at all?
       ✗ "Predictive Maintenance fur den Maschinenbau" (noun phrase — no claim)
       ✓ "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" (verb: macht)

  5. CHECK the character limit
     → Hero: max 70 characters, max 10 words
     → Section: max 70 characters, max 12 words
     → Card: max 6 words (noun phrase is OK here)
     → If over limit: Cut modifiers ("innovativ", "umfassend", "fortschrittlich")
     → Use symbols: "%" not "Prozent", "EUR" or "€" not "Euro"

  6. VERIFY the headline tells the story without the body
     → Cover the body text. Read ONLY the headline.
     → Does the reader understand the section's claim? (YES -> proceed)
     → Read ALL headlines in scroll order. Does the argument build?
       (YES -> proceed | NO -> adjust the headline that breaks the flow)
```

### Headline Formulas

For each section type:

| Section Type | Formula | Example |
|-------------|---------|---------|
| hero | {Transformation verb} + {audience benefit} | "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" |
| problem-statement | {Number} + {negative consequence} | "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" |
| stat-row | {Count} + {plural noun} + {verb} + {object} | "Drei Krisen treffen den Maschinenbau gleichzeitig" |
| feature-alternating | {Subject} + {action verb} + {benefit} | "Sensoren lesen den Maschinenzustand in Echtzeit" |
| comparison | {Number}% + {improvement} + {proof qualifier} | "73% weniger Stillstand in der Pilotlinie bewiesen" |
| timeline | "In {duration} zu {outcome}" | "In 12 Wochen zur intelligenten Fertigung" |
| cta | "{Action verb} + {your noun}" (imperative) | "Starten Sie Ihren Predictive-Maintenance-Piloten" |

### Headline Anti-Patterns

These are common mistakes. If you catch yourself writing any of these, STOP and rewrite.

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Topic label: "Uberblick" / "Overview" | No claim, no verb, no reason to stop scrolling | Rewrite as assertion: "{Subject} {verb} {outcome}" |
| Topic label: "Unsere Losung" / "Our Solution" | Tells the reader nothing about WHAT the solution does | Lead with the capability: "Sensoren lesen den Maschinenzustand" |
| Topic label: "Zusammenfassung" / "Key Findings" | Reader already forgot what they read — headline must remind them | State the conclusion: "73% weniger Stillstand bewiesen" |
| Passive voice: "Stillstande werden durch KI reduziert" | Buries the actor, weakens the claim | Active: "KI reduziert Stillstande um 73%" |
| No verb: "Predictive Maintenance im Maschinenbau" | Description, not a claim — readers scroll past | Add the verb: "Predictive Maintenance senkt Ihre Ausfallzeiten" |
| Buzzword soup: "Innovative KI-gestutzte digitale Transformation" | Empty words, no specific claim | Replace with concrete result: "KI erkennt Verschleiss 14 Tage vor dem Ausfall" |
| Too long: "Durch den Einsatz modernster Sensortechnologie und kunstlicher Intelligenz lassen sich ungeplante Maschinenstillstande drastisch reduzieren" (120 chars) | Exceeds 70-char limit, unreadable on mobile | Trim to core: "Sensoren und KI senken Stillstande um 73%" (43 chars) |

---

## CTA Copy Patterns

CTA text adapts to the `conversion_goal` parameter:

| conversion_goal | CTA Text (DE) | CTA Text (EN) |
|----------------|---------------|---------------|
| `consultation` | "Beratung anfragen" | "Request Consultation" |
| `demo` | "Live-Demo buchen" | "Book a Demo" |
| `download` | "Whitepaper herunterladen" | "Download Whitepaper" |
| `trial` | "Kostenlos testen" | "Start Free Trial" |
| `contact` | "Kontakt aufnehmen" | "Get in Touch" |
| `calculate` | "ROI berechnen" | "Calculate Your ROI" |

### CTA Subline Pattern

The CTA subline should reduce friction:

```
"{Value proposition} in {low-commitment action}."

Examples:
- "Berechnen Sie Ihr Einsparpotenzial in einem kostenlosen 30-Minuten-Gesprach."
- "Sehen Sie die Plattform in einer personalisierten 20-Minuten-Demo."
```

### CTA Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Vague CTA: "Mehr erfahren" / "Learn More" | No specific action, low conversion intent | Use goal-specific text: "Beratung anfragen" |
| Aggressive CTA: "Jetzt kaufen" when conversion_goal is `consultation` | Mismatches the funnel stage, creates friction | Match the goal: "Beratung anfragen" |
| Long CTA button text: "Fordern Sie jetzt Ihre kostenlose Beratung an" | Button text must be scannable — 2-3 words max | Shorten: "Beratung anfragen" |
| No friction reducer in subline: "Kontaktieren Sie uns" (no time/commitment info) | Reader imagines worst case (long sales call) | Add specifics: "in einem kostenlosen 30-Minuten-Gesprach" |

---

## Body Text Constraints

| Field | Max Words | Max Sentences | Style |
|-------|-----------|--------------|-------|
| Hero subline | 25 | 1-2 | Benefit-focused, scannable |
| Section body | 50 | 2-3 | Supporting evidence for the headline |
| Card body | 20 | 1-2 | Feature description, no fluff |
| Bullet items | 8 per item | 1 | Scannable, parallel structure |
| Quote text | 30 | 1-2 | Authentic voice, specific result |
| Attribution | 10 | 1 | Name + title + company |

### Body Text Reasoning

Body text serves ONE purpose: support the headline's claim with evidence or explanation. It should never repeat the headline, introduce new claims, or ramble.

```text
REASON through body text for each section:

  1. ASK: "What does the reader need AFTER reading the headline?"
     → If the headline has a NUMBER → body explains the context behind the number
       Headline: "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit"
       Body: explains what causes 23 days, what it costs per day, who is affected
     → If the headline has a TRANSFORMATION → body explains how it works
       Headline: "Sensoren lesen den Maschinenzustand in Echtzeit"
       Body: explains what sensors measure, how often, what edge-KI does with data
     → If the headline has an OUTCOME → body provides proof
       Headline: "73% weniger Stillstand in der Pilotlinie bewiesen"
       Body: references the pilot, methodology, timeline

  2. ENFORCE the word limit
     → Section body: 50 words max, 2-3 sentences
     → If over 50 words: cut background context (move to a separate section or discard)
     → Every sentence must earn its place — ask "does this PROVE the headline?"

  3. CHECK for parallel bullet structure (where bullets exist)
     → All bullets must follow the same grammatical pattern
     → Choose ONE form: verb-first, number-first, or noun-first
       ✗ Mixed: "38.000 EUR Kosten" / "Erkennt Verschleiss zu spat" / "Lieferketten"
       ✓ Parallel: "38.000 EUR pro Stillstandstag" / "14 Tage zu spate Erkennung" / "72h Ersatzteil-Lieferzeit"
```

### Body Text Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Repeating the headline: "23 Tage Stillstand kosten viel. Denn 23 Tage sind eine lange Zeit." | Wastes the reader's time, feels amateur | Add NEW information: explain the 38.000 EUR/day cost |
| Introducing a new claim: Body under "Sensoren lesen..." suddenly talks about ROI | Confuses the reader, dilutes the section focus | Move ROI content to the proof or comparison section |
| Wall of text: 4+ sentences, 80+ words | Reader skips the entire section | Cut to 2-3 sentences, 50 words max |
| Vague language: "erhebliche Verbesserungen" / "significant improvements" | No evidence, no credibility | Replace with specific numbers: "73% weniger Stillstand" |
| Non-parallel bullets: mix of sentence fragments, full sentences, and labels | Creates cognitive friction, harder to scan | Enforce one grammatical form across all bullets |

---

## Number Plays for Web

Reframe statistics for visual impact on web. Same techniques as slides but adapted for larger format:

### Number Play Reasoning Process

Number play selection is NOT random decoration — it is strategic reframing. The goal is to make data FELT, not just seen. Every statistic has a natural presentation form that maximizes emotional impact for the web medium.

Before applying any technique, reason through the data:

```text
REASON through number play selection for each section:

  1. INVENTORY all numbers in the narrative section
     → List every statistic, metric, cost, percentage, count
     → Note for each: value, unit, context, source
     → Example inventory for a Maschinenbau narrative:
       - 23 (days downtime/year, from VDMA study)
       - 38.000 (EUR cost/day, from industry average)
       - 64.000 (missing skilled workers by 2028, from IAB)
       - 1:5 (complaints from quality drift, from QM report)
       - 41% (maintenance cost share, from VDI study)
       - 73% (reduction achieved, from pilot data)
       - 12 (weeks implementation, from project plan)

  2. RANK by emotional impact
     → For web narratives, the ranking differs from slides:
       Cost/loss that accumulates > percentage improvements > absolute counts > ratios
     → WHY: Web readers are scanning for "why should I care?" —
       accumulated costs create urgency, percentages create desire
     → EXCEPTION: when human impact is involved (safety, health),
       absolute numbers always rank highest
     → EXCEPTION: when ratio creates more visceral reaction than percentage:
       "1 von 5 Reklamationen" > "20% Reklamationsquote"

  3. SELECT the hero number (ONE per stat card or section stat)
     → ASK: "Which number would stop the reader mid-scroll?"
     → The hero number gets 48px bold treatment in the stat card
     → All other numbers become supporting context (label, body text)
     → If two numbers feel equally important:
       - Which connects more directly to the section's HEADLINE?
       - Which is more surprising to the TARGET AUDIENCE?
       - Use that one. Move the other to body text or a different section.

  4. CHOOSE the right technique
     → For each number, ask: "What framing creates the strongest emotional response?"

     → Raw count with emotional weight?
       → HERO NUMBER ISOLATION: "23" (stat card) + "Tage Stillstand/Jahr" (label)
       → This works when the number alone is shocking

     → Percentage under 50% representing risk or failure?
       → RATIO FRAMING: "20%" -> "1:5" + "Reklamationen"
       → Ratios feel personal ("1 von 5" means "it could be yours")

     → Before/after data with improvement?
       → BEFORE/AFTER CONTRAST: Left: "23 Tage" / Right: "6 Tage (-73%)"
       → This works in comparison sections

     → Per-unit cost that accumulates?
       → MULTIPLIER: "38.000 EUR/Tag x 23 Tage" -> "874.000 EUR jahrliche Kosten"
       → This works when the total is more shocking than the daily cost

     → Duration or timeline?
       → TIME COMPRESSION: "12 Wochen" as timeline hero number
       → This works in roadmap sections to make implementation feel achievable

  5. VERIFY the reframing is honest
     → Does the reframed number mean the same thing as the original?
     → Would a skeptical reader accept this framing?
     → If the reframing distorts (e.g., cherry-picked timeframe) -> keep original
     → RULE: number plays amplify impact, they never manufacture it
```

### Techniques

| Technique | Raw | Reframed | When to Use |
|-----------|-----|----------|-------------|
| Hero number isolation | "Downtime reduced from 23 to 6 days" | "23" (stat card) + "Tage Stillstand/Jahr" | Problem sections |
| Ratio framing | "20% of complaints" | "1:5" + "Reklamationen" | When ratio is more visceral than percentage |
| Before/after contrast | "23 days -> 6 days" | Left: "23 Tage" / Right: "6 Tage (-73%)" | Comparison sections |
| Time compression | "12 weeks implementation" | "12 Wochen" (timeline hero) | Timeline/roadmap sections |
| Multiplier | "38,000 per day x 23 days" | "874.000 EUR" + "jahrliche Stillstandskosten" | When total is more shocking |

### Number Play Decision Matrix

| Data Type | Best Technique | Web Section Type | Example |
|-----------|---------------|-----------------|---------|
| Single large count | Hero isolation | problem-statement, stat-row | "23" + "Tage Stillstand/Jahr" |
| Percentage < 50% (risk) | Ratio framing | stat-row | "1:5" + "Reklamationen" |
| Before/after metric | B/A contrast | comparison | "23 Tage" vs "6 Tage (-73%)" |
| Per-unit cost | Multiplier | problem-statement | "874.000 EUR jahrliche Kosten" |
| Duration | Time compression | timeline | "12 Wochen" |
| Percentage > 50% (improvement) | Hero isolation | comparison, stat-row | "73%" + "weniger Stillstand" |
| Multiple related stats | Stat row | stat-row (3-4 cards) | Three crisis dimensions side by side |

### Stat Card Formatting

In stat-row and problem-statement sections:

```yaml
stat_number: "23"          # Large display number — no units
stat_label: "Tage/Jahr"    # Unit/context — short
stat_context: "pro Anlage"  # Additional context — optional
```

- Numbers should be visually clean: "23" not "23 Tage"
- Labels provide the unit context
- Use the number that creates the strongest emotional response

### Number Play Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Units in the number field: stat_number: "23 Tage" | Breaks the visual hierarchy — number should be huge, units should be small | Split: number "23", label "Tage/Jahr" |
| Two hero numbers in one stat card | Dilutes impact — reader cannot focus on either | Pick the more surprising number, move the other to body text |
| Unframed percentage: "41%" with no context | Reader has no anchor — is 41% good or bad? | Add context label: "41%" + "Instandhaltungskosten-Anteil" |
| Raw decimal: "0.73" instead of "73%" | Harder to parse at scanning speed | Convert to percentage or ratio for readability |
| Mixing number formats: "64.000" next to "73%" next to "1:5" | Inconsistent formatting within a stat row feels chaotic | Within a single stat-row, prefer consistent formats (all counts, or all percentages) |
| German number in English text: "38.000" (DE) in an EN narrative | German uses period as thousands separator, English uses comma | Match language: DE "38.000", EN "38,000" |

---

## Section Label Convention

Each section can have a small uppercase label above the headline:

| Arc Role | DE Label | EN Label |
|----------|----------|----------|
| hook | (none — hero has no label, or use topic) | (none) |
| problem | "Das Problem" | "The Problem" |
| urgency | "Warum jetzt" | "Why Now" |
| solution | "Die Losung" / "Der Ansatz" | "The Solution" / "Our Approach" |
| proof | "Bewiesene Ergebnisse" | "Proven Results" |
| roadmap | "Der Weg" | "The Path" |
| call-to-action | (none — CTA has no label) | (none) |

Labels are optional. Use them when the narrative structure benefits from explicit signposting. Omit them when the headline is self-explanatory.

---

## Language-Specific Guidance

### German (DE) Patterns

> **Note on examples:** German examples throughout this file use ASCII-safe simplified umlauts (e.g., "Losung" instead of "Lösung", "Uberwachung" instead of "Überwachung") for rendering compatibility in code blocks and YAML. Production briefs should preserve proper umlauts where the rendering system supports them.

German web copy differs from English in structure, compound nouns, and formal address:

| Aspect | Guidance | Example |
|--------|----------|---------|
| Formal address | Use "Sie" (formal you) in all headlines and body text | "Ihre Fertigung", "Starten Sie..." |
| Compound nouns | German forms single compound words — use them for concise headlines | "Echtzeit-Zustandsuberwachung" (not "Uberwachung des Zustands in Echtzeit") |
| Verb position | In assertions, the verb often comes second (V2 rule) | "Sensoren lesen den Maschinenzustand" |
| Imperative | Formal imperative uses "Sie" after the verb | "Starten Sie Ihren Piloten" (not "Starten Ihren Piloten") |
| Number formatting | Period for thousands, comma for decimals | "38.000 EUR", "73,5%" |
| Umlaut handling | Preserve umlauts where possible, accept simplified forms in generated code | "Losung" is acceptable when "Loesung" would break rendering |
| Article usage | German headlines often include articles where English drops them | DE: "Die Losung fur Ihre Fertigung" / EN: "Solution for Your Production" |

### English (EN) Patterns

| Aspect | Guidance | Example |
|--------|----------|---------|
| Title case | Section headlines use title case | "Three Crises Hit Manufacturing Simultaneously" |
| Number formatting | Comma for thousands, period for decimals | "38,000 EUR", "73.5%" |
| Contractions | Avoid in formal web copy | "cannot" not "can't", "do not" not "don't" |
| Active voice priority | English readers expect subject-verb-object | "AI Reduces Downtime by 73%" |

### Common Bilingual Pitfalls

| Pitfall | Example | Fix |
|---------|---------|-----|
| Mixing languages within a section | DE headline + EN body text | All text in one section must be the same language |
| English calques in German | "in Echtzeit monitoren" (Denglisch) | Use German verbs: "in Echtzeit uberwachen" |
| German sentence structure in English | "The downtime can by AI reduced be" (V2 bleed) | English word order: "AI can reduce the downtime" |
| Wrong number format for language | DE: "38,000" or EN: "38.000" | DE: "38.000" / EN: "38,000" |
| Missing formal address in German | "Starte deinen Piloten" (informal du) | "Starten Sie Ihren Piloten" (formal Sie) |
| Translating CTA literally | DE "Anfragen" -> EN "To Request" (infinitive) | EN uses imperative: "Request Consultation" |

---

## End-to-End Worked Examples

### Example 1: Problem-Statement Section (DE)

Complete copywriting transformation from narrative excerpt to finished section specification.

```text
=============================================
INPUT: Narrative excerpt (problem section, DE)
=============================================

From source narrative (role: problem):

  "Der deutsche Maschinenbau-Mittelstand verzeichnet im Durchschnitt 23 Tage
   ungeplanten Stillstand pro CNC-Anlage und Jahr. Dies entspricht Kosten von
   rund 38.000 Euro pro Stillstandstag. Manuelle Wartungszyklen erkennen
   Verschleissmuster erst nach dem Ausfall. Hinzu kommen Ersatzteil-Lieferketten
   mit durchschnittlich 72 Stunden Lieferzeit bei Notbestellungen. Insgesamt
   wurden 2.800 Betriebe befragt."

=============================================
STEP A: HEADLINE REASONING
=============================================

  1. IDENTIFY core message:
     → The section is about the COST OF DOWNTIME — 23 days is the anchor

  2. CLASSIFY priority:
     → This is an OUTCOME (negative) — what the reader is losing
     → Lead with the number + consequence

  3. INJECT number:
     → Most impactful number: 23 (days — tangible, relatable)
     → Weave into headline: "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit"

  4. ACTIVATE verb:
     → "kosten" is active — downtime does the costing ✓
     → Subject (23 Tage Stillstand) is doing something (kosten) to the reader (Ihre Wettbewerbsfahigkeit) ✓

  5. CHECK length:
     → "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" = 52 chars ✓ (under 70)

  6. VERIFY standalone:
     → Reading only the headline — does the reader understand the problem? YES ✓
     → The reader knows: downtime exists (23 days), it hurts (costs competitiveness)

  HEADLINE: "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit"

=============================================
STEP B: NUMBER PLAY REASONING
=============================================

  1. INVENTORY:
     - 23 (days downtime/year, from VDMA study average)
     - 38.000 (EUR cost/day, from industry average)
     - 72 (hours spare part delivery, from supply chain data)
     - 2.800 (companies surveyed — sample size)

  2. RANK by emotional impact:
     → 23 days > 38.000 EUR/day > 72 hours > 2.800 (sample size is context, not impact)
     → 23 days is the most tangible — every plant manager knows what a lost day costs

  3. SELECT hero: 23
     → Billboard test: "23" demands the question "23 what?"
     → Supporting: 38.000 EUR goes into body text, 2.800 goes into stat_context

  4. CHOOSE technique:
     → 23 is a standalone count with emotional weight -> HERO NUMBER ISOLATION
     → Format: stat_number "23", stat_label "Tage Stillstand pro Anlage/Jahr"
     → NOT using multiplier (23 x 38.000 = 874.000) because this is a problem section
       — the daily cost creates more relatable urgency than the annual total
     → The multiplier technique could work in a separate stat-row about financial impact

  5. VERIFY honesty:
     → 23 is from a VDMA study of 2.800 companies — verified average ✓
     → No distortion ✓

  HERO: 23 / LABEL: "Tage Stillstand pro Anlage/Jahr" / CONTEXT: "Durchschnitt uber 2.800 befragte Betriebe"

=============================================
STEP C: BODY TEXT + BULLETS
=============================================

  1. ASK: What does the reader need after "23 Tage Stillstand kosten..."?
     → CONTEXT: What causes 23 days, what does it cost, why can't they fix it?

  2. WRITE body (50 words max):
     "Jede CNC-Anlage im deutschen Mittelstand steht durchschnittlich 23 Tage
      pro Jahr ungeplant still. Manuelle Wartungszyklen erkennen Verschleiss
      erst nach dem Ausfall — und kosten 38.000 Euro pro Stillstandstag."
     → Word count: 30 ✓ (under 50)
     → Supports headline: explains the 23 days + adds the cost dimension

  3. WRITE bullets (parallel structure, 8 words max each):
     → Choose FORM: number-first (to reinforce data-driven problem section)
     → "38.000 EUR Kosten pro Stillstandstag" (5 words) ✓
     → "Manuelle Wartung erkennt Verschleiss zu spat" (6 words) ✓
     → "Ersatzteil-Lieferketten verstarken den Effekt" (5 words) ✓
     → All noun/number-first ✓, all under 8 words ✓

=============================================
OUTPUT: COMPLETE SECTION SPECIFICATION
=============================================

  ## Section 2: 23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit

  type: problem-statement
  section_theme: light
  arc_role: problem

  section_label: "Das Problem"
  headline: "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit"
  body: |
    Jede CNC-Anlage im deutschen Mittelstand steht durchschnittlich 23 Tage
    pro Jahr ungeplant still. Manuelle Wartungszyklen erkennen Verschleiss
    erst nach dem Ausfall — und kosten 38.000 Euro pro Stillstandstag.

  stat_number: "23"
  stat_label: "Tage Stillstand pro Anlage/Jahr"
  stat_context: "Durchschnitt uber 2.800 befragte Betriebe"

  bullets:
    - "38.000 EUR Kosten pro Stillstandstag"
    - "Manuelle Wartung erkennt Verschleiss zu spat"
    - "Ersatzteil-Lieferketten verstarken den Effekt"

  source: "[VDMA Produktionsausfallstudie 2025](https://www.vdma.org/produktionsausfall-studie)"
```

### Example 2: Stat-Row Section with Multiple Number Plays (DE)

```text
=============================================
INPUT: Narrative excerpt (urgency section, DE)
=============================================

  "Der Maschinenbau steht vor drei gleichzeitigen Krisen: Erstens fehlen laut
   IAB-Prognose bis 2028 rund 64.000 Fachkrafte. Zweitens fuhrt die schleichende
   Qualitatsdrift dazu, dass jede funfte Reklamation auf ungeplante Maschinenstillstande
   zuruckgeht. Drittens liegt der Instandhaltungskosten-Anteil bei 41% der
   Gesamtbetriebskosten — deutlich uber dem europaischen Durchschnitt von 28%."

=============================================
REASONING
=============================================

  1. INVENTORY:
     - 64.000 (missing skilled workers by 2028, from IAB)
     - 1 in 5 / 20% (complaints from quality drift, from QM report)
     - 41% (maintenance cost share, from VDI study)
     - 28% (European average — useful as contrast anchor)

  2. This section has THREE parallel crisis dimensions
     → Best section type: stat-row (3-4 stat cards in a horizontal row)
     → Each crisis gets its own card — no single hero number dominates

  3. NUMBER PLAY per card:

     Card 1: 64.000 fehlende Fachkrafte
     → Technique: HERO ISOLATION (large absolute number creates urgency)
     → stat_number: "64.000" / stat_label: "fehlende Fachkrafte bis 2028"
     → NOT using ratio framing — 64.000 as an absolute count is already alarming

     Card 2: Jede funfte Reklamation
     → Technique: RATIO FRAMING ("20%" -> "1:5")
     → stat_number: "1:5" / stat_label: "Reklamationen durch Qualitatsdrift"
     → WHY ratio over percentage: "1 in 5" feels personal — any complaint could be next
     → "20% Reklamationsquote" is abstract; "1:5" is visceral

     Card 3: 41% Instandhaltungskosten
     → Technique: HERO ISOLATION (percentage as-is — already stark)
     → stat_number: "41%" / stat_label: "Instandhaltungskosten-Anteil"
     → The 28% European average is context, not the hero — save for body or comparison

  4. HEADLINE:
     → Three crises, one headline: "Drei Krisen treffen den Maschinenbau gleichzeitig"
     → Formula: {Count} + {plural noun} + {verb} + {object}
     → "Drei" spelled out (not "3") — German convention for small numbers in headlines
     → Active verb "treffen" — the crises are acting on the industry

=============================================
OUTPUT: COMPLETE SECTION SPECIFICATION
=============================================

  ## Section 3: Drei Krisen treffen den Maschinenbau gleichzeitig

  type: stat-row
  section_theme: dark
  arc_role: urgency

  section_label: "Warum jetzt"
  headline: "Drei Krisen treffen den Maschinenbau gleichzeitig"

  stats:
    - number: "64.000"
      label: "fehlende Fachkrafte bis 2028"
      icon: "users"
    - number: "1:5"
      label: "Reklamationen durch Qualitatsdrift"
      icon: "trending-down"
    - number: "41%"
      label: "Instandhaltungskosten-Anteil"
      icon: "euro"
```

### Example 3: Feature-Alternating Section (EN)

```text
=============================================
INPUT: Narrative excerpt (solution section, EN)
=============================================

  "The platform uses vibration sensors mounted on spindles, feeds, and bearings
   to capture machine condition 500 times per second. The edge AI analyzes
   patterns in real time and identifies wear signatures up to 14 days before
   failure. This gives maintenance teams a two-week window to plan repairs
   rather than react to breakdowns."

=============================================
REASONING
=============================================

  1. HEADLINE:
     → Core message: Sensors + AI detect wear before failure
     → Priority: TRANSFORMATION (what changes — reactive -> predictive)
     → Draft: "Sensors Read Machine Condition in Real Time"
     → Verb check: "Read" is active ✓
     → Length: 42 chars ✓ (under 70)
     → Standalone test: Reader understands the capability without body text ✓

  2. BODY (50 words max):
     "Vibration sensors on spindle, feed, and bearing capture machine
      condition 500 times per second. Edge AI detects wear patterns
      14 days before failure — giving your team time to plan repairs
      instead of reacting to breakdowns."
     → Word count: 37 ✓
     → Supports headline: explains HOW sensors read condition
     → Includes the "14 days" proof point (not in headline — would make it too long)

  3. No stat card in this section type — numbers live in the body text

=============================================
OUTPUT: COMPLETE SECTION SPECIFICATION
=============================================

  ## Section 4: Sensors Read Machine Condition in Real Time

  type: feature-alternating
  section_theme: light
  arc_role: solution
  position: odd

  section_label: "The Solution"
  headline: "Sensors Read Machine Condition in Real Time"
  body: |
    Vibration sensors on spindle, feed, and bearing capture machine
    condition 500 times per second. Edge AI detects wear patterns
    14 days before failure — giving your team time to plan repairs
    instead of reacting to breakdowns.

  image_prompt: |
    Close-up photograph of precision vibration sensors mounted on a CNC
    machine spindle, with subtle digital data visualization overlay showing
    wave patterns. Professional industrial photography, blue accent lighting.
    Square format. No text, no people.
    Style: professional stock photography, corporate technology.
```

---

## Quality Self-Check

After writing all section copy and before proceeding to the Section Preview Checkpoint (Step 5b), verify every section against this checklist. For each section, confirm:

```text
QUALITY SELF-CHECK — run for EACH section:

  HEADLINE CHECKS:
  [ ] Is the headline an assertion (contains a verb)?
      → If NO: rewrite — topic labels are the #1 copywriting failure
  [ ] Is the headline under 70 characters?
      → If NO: trim modifiers, use symbols, shorten clauses
  [ ] Does the headline stand alone (reader understands the claim without body)?
      → If NO: the headline is description, not assertion — rewrite
  [ ] Is the verb active (subject does the action)?
      → If NO: flip from passive to active voice

  BODY TEXT CHECKS:
  [ ] Is body text under 50 words (section) or 25 words (hero subline)?
      → If NO: cut background context, keep only evidence
  [ ] Does body text support the headline's claim (not repeat or contradict it)?
      → If NO: rewrite body to answer "why should I believe the headline?"
  [ ] Are bullets parallel in grammatical structure?
      → If NO: pick one form (verb-first, number-first, noun-first) and apply to all
  [ ] Is each bullet under 8 words?
      → If NO: trim articles, hedging language, and filler words

  NUMBER PLAY CHECKS:
  [ ] Is the stat_number field clean (no units mixed in)?
      → If NO: move units to stat_label
  [ ] Is only ONE hero number per stat card?
      → If NO: pick the more impactful number, move the other to body or label
  [ ] Is the number play honest (reframing does not distort the original meaning)?
      → If NO: revert to the original number
  [ ] Does the number format match the language? (DE: "38.000" / EN: "38,000")
      → If NO: fix the thousands separator

  LANGUAGE CHECKS:
  [ ] Is all text in the section the same language (no mixing)?
      → If NO: translate the offending text
  [ ] Does German copy use "Sie" (formal address)?
      → If NO: replace "du/dein" with "Sie/Ihr"
  [ ] Are CTA texts using the correct conversion_goal mapping?
      → If NO: look up the correct CTA text from the CTA Copy Patterns table

  STRUCTURAL CHECKS:
  [ ] Does the headline tell the story without the body (cover test)?
      → If NO: the headline needs the claim, not just the topic
  [ ] Reading all headlines in scroll order — does the argument build?
      → If NO: identify which headline breaks the flow and adjust
  [ ] Does this section add a NEW message (not repeat an earlier section)?
      → If NO: merge with the earlier section or differentiate the angle
```
