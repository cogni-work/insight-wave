---
name: Empathy Mapping
phase: discover
type: divergent
inputs: [personas, stakeholder-map, customer-journey, research-summary]
outputs: [enriched-personas]
duration_estimate: "15-30 min per persona"
requires_plugins: []
---

# Empathy Mapping

Build a rich understanding of each persona by mapping what they think, feel, say, and do. This method bridges the gap between knowing *about* someone and understanding *what it's like to be them* — which is the difference between solutions that look good on slides and solutions people actually adopt.

## When to Use

- When personas exist from Setup (even as hypotheses) and Discovery has produced evidence to ground them
- After stakeholder mapping or customer journey analysis — these methods surface the raw material that empathy mapping organizes
- Particularly valuable for digital-transformation, cost-optimization, and innovation-portfolio vision classes where the people affected by the outcome are not the people commissioning the engagement
- Skip for lightweight HMW engagements unless the consultant specifically requests it

## Guided Prompt Sequence

### Step 1: Select a Persona

Present the available personas from `personas/`. For each, show: name, context, core tension, current maturity level.

Ask: "Which persona should we map first? I'd recommend starting with the one most central to the engagement — the person whose reality we most need to understand."

### Step 2: Map Each Quadrant

For each quadrant, draw from discovery evidence first, then supplement with consultant knowledge. The distinction matters — evidence-based entries carry more weight than assumptions, and gaps reveal where understanding is thin.

**Thinks** — What occupies their mind? What worries them? What do they believe about the situation?
- Draw from: stakeholder interview notes, research about role pressures, industry context
- Prompt: "When this person thinks about [the engagement topic], what goes through their mind? What are they worried about? What assumptions do they carry?"

**Feels** — What emotions drive their behavior? What frustrates, excites, or frightens them?
- Draw from: customer journey pain points, stakeholder mapping notes on resistance or enthusiasm
- Prompt: "How does this person feel about the current situation? About the prospect of change? What past experiences color their feelings?"

**Says** — What do they actually say out loud? What language do they use?
- Draw from: direct quotes in research, stakeholder interview quotes, consultant's own interactions
- Prompt: "If you overheard this person talking to a colleague about [the engagement topic], what would they say? Use their actual words, not a polished version."

**Does** — What behaviors can you observe? What workarounds have they created?
- Draw from: customer journey touchpoints, process observations, consultant's field knowledge
- Prompt: "What does this person actually do day-to-day that relates to this engagement? What workarounds have they invented? What do they avoid?"

### Step 3: Surface Gaps and Contradictions

After mapping all four quadrants, look for:

- **Gaps**: Quadrants with thin or no evidence — these are where understanding is weakest and assumptions are most dangerous. Flag them explicitly.
- **Say-Do contradictions**: What people say often differs from what they do. These contradictions are rich design inputs — a person who says "I want data-driven decisions" but relies on gut feeling is telling you something important about trust and tools.
- **Think-Feel tensions**: Internal conflicts (e.g., "thinks the change is necessary" but "feels anxious about losing control") predict adoption barriers that rational arguments won't resolve.

### Step 4: Extract Needs

From the empathy map, distill 2-5 need statements. Good needs:

- Are framed from the persona's perspective, not the organization's
- Describe the desired state, not the solution: "Needs to trust the data before making decisions" not "Needs a dashboard"
- Connect to the core tension: each need should relate to what makes the current situation unsatisfying

### Step 5: Update the Persona

Write the enriched data back to `personas/{slug}.json`:
- Populate `empathy_map` with the four quadrants
- Add extracted needs to `needs`
- Promote `maturity` to `"researched"` if substantive evidence was added (at least 2 quadrants have evidence-based entries)
- Append to `phase_log`: `{"phase": "discover", "action": "empathy-mapped", "date": "<ISO date>", "detail": "Think/Feel/Say/Do populated from [sources]"}`

### Step 6: Repeat for Additional Personas

If the engagement has 2-4 personas, map each one. Between personas, note where their empathy maps overlap or conflict — a tension between two personas' needs is often the most important design constraint.

## Output

The primary output is the enriched persona files in `personas/`. No separate artifact is needed — the empathy map lives inside the persona entity.

Optionally, present a summary to the consultant:

> **Empathy mapping complete for [N] personas.**
> - [Persona 1]: [one-line summary of key insight]
> - [Persona 2]: [one-line summary]
> - Key tension between personas: [if applicable]
> - Gaps: [quadrants where evidence is thin]

## Tips

- Real quotes are gold — if the consultant has heard the persona say something, capture the exact words
- Emotions are harder to surface than facts — give the consultant time to reflect rather than rushing to the next quadrant
- Resist the urge to make the empathy map "nice" — contradictions, frustrations, and irrational behaviors are the most valuable inputs for design
- If the consultant has no evidence for a quadrant, mark it as assumed rather than fabricating entries
