# Content Distillation Rules

The infographic medium rewards ruthless reduction. A 2000-word narrative becomes an 80-120
word infographic — a 95%+ compression ratio. This reference defines how to select the
surviving content.

## The 10-Second Rule

The entire infographic must convey its governing message in 10 seconds of scanning. This
means the viewer's eye path hits: title → hero number → 2-3 supporting elements → CTA.
Everything on the page must support this scan path. Anything that doesn't contribute to
the 10-second comprehension arc gets cut.

## Distillation Process

### 1. Extract Governing Assertion

The governing assertion is the single most important sentence in the narrative. It becomes
the infographic title. It must:
- Contain a verb (not a topic label)
- Include a quantified consequence when possible
- Be self-contained — understandable without context

**Good:** "KI-Videoanalytik senkt Sicherheitsvorfälle um 73%"
**Bad:** "Sicherheit im Bahnnetz" (topic label, no verb, no consequence)
**Bad:** "Über den Einsatz von KI-Videoanalytik im deutschen Bahnnetz" (descriptive, no assertion)

If the narrative lacks a clear governing assertion, synthesize one from the strongest
evidence: "[Subject] [verb] [quantified outcome] — [consequence]".

### 2. Select Hero Numbers (3-5 maximum)

Hero numbers are the visual anchors. They are the first thing the eye notices after the title.

**Selection criteria** (in priority order):
1. **Transformation magnitude** — before/after deltas, percentage changes, multiples (73% reduction > 47 incidents)
2. **Scale indicators** — numbers that establish the problem or opportunity size (2.661 Übergriffe, 5.400 Bahnhöfe)
3. **Time markers** — durations that create urgency or show speed (< 2 Sekunden, 12 Wochen)
4. **Unique specifics** — numbers that only this story has (not generic industry averages)

**Exclusion criteria:**
- Round numbers that feel estimated ("about 50%") — either find the exact number or drop it
- Numbers that need 2+ sentences to contextualize — if the label can't explain it in 4 words, it's too complex for an infographic
- Redundant numbers — if two stats make the same point, keep the more impactful one

**Number play techniques:**
- **Hero isolation**: One number gets maximum visual prominence (the kpi-card)
- **Ratio framing**: "1 in 4" is more visceral than "25%"
- **Before/after contrast**: Show the delta, not just the after state
- **Time compression**: "in 6 Monaten" → makes the achievement tangible

### 3. Select Process/Sequence (0-1)

If the narrative describes a process, workflow, or chronological sequence, select the most
important one and compress it to 4-8 steps. Each step becomes a label (2-4 words) + icon.

**Compression rules:**
- Merge adjacent steps that the viewer doesn't need to distinguish
- Use action verbs in labels: "Erfassen", "Analysieren", "Alarmieren" (not "Datenerfassung")
- If the process has more than 8 steps, it needs a flow-diagram layout with SVG, not a process-strip

### 4. Select Comparison (0-1)

If the narrative contains a before/after, option A vs B, or Handeln vs. Nichthandeln contrast:
- Extract the two sides with 3-5 parallel bullets each
- Keep bullets to max 6 words
- Ensure structural parallelism (same grammatical form on both sides)

### 5. Discard Everything Else

This is the hardest part. Everything that didn't make the cut gets dropped:
- Background context → summarized in the subline (max 15 words)
- Supporting arguments → if they don't have a number, they're not infographic material
- Caveats and qualifications → infographics are assertion media, not nuance media
- Citations → compressed to a single source line in the footer
- Methodology → not for the infographic audience

## Icon-Over-Text Rule

Wherever a concept can be represented by an icon + a 2-3 word label, prefer that over prose.
The concept-diagram-svg agent generates small inline SVG icons from descriptive prompts.

**Good icon prompts:** "shield with downward arrow" (security reduction), "brain neural network"
(AI processing), "clock continuous 24/7" (always-on)

**Bad icon prompts:** "infographic" (too meta), "business" (too vague), "nice icon" (not descriptive)

## Geographic References

Current AI image generators consistently misrepresent country borders and geographic shapes.
The same applies to SVG generation. For any geographic reference:
- Use flag icons instead of maps
- Use city/country name labels instead of geographic outlines
- "Deutschland" + flag icon, not a map outline of Germany

## Language Explicitness

Always specify language in the brief frontmatter. Within content:
- All text in a single language — no mixed-language infographics
- German text uses real umlauts (ä, ö, ü, ß) — never ASCII substitutes
- German numbers use dot separators (2.661, not 2,661)

## Quality Gate: Does It Pass the 10-Second Test?

After distillation, mentally scan the infographic in this order:
1. Title → do I know the topic and the main claim? (2 seconds)
2. Hero number → is there a number that anchors the claim? (2 seconds)
3. Supporting elements → do 2-3 blocks reinforce the message? (4 seconds)
4. CTA → do I know what to do next? (2 seconds)

If any step fails, the distillation needs more work.
