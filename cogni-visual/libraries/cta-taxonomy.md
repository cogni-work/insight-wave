# CTA Taxonomy

Shared reference for Call-to-Action extraction, generation, and classification across all story-to-* skills.

## CTA Types

| Type | Engagement Level | Audience Commitment | Examples (EN) | Examples (DE) |
|------|-----------------|---------------------|---------------|---------------|
| `explore` | Low | Time only | "Read the whitepaper", "Browse case studies", "Watch the demo video" | "Whitepaper lesen", "Fallstudien ansehen", "Demo-Video ansehen" |
| `evaluate` | Medium | Time + internal effort | "Try the assessment tool", "Request a benchmark", "Compare your metrics" | "Assessment starten", "Benchmark anfordern", "Ihre Kennzahlen vergleichen" |
| `commit` | High | Budget + decision | "Book a discovery call", "Start pilot project", "Request a proposal" | "Erstgespräch buchen", "Pilotprojekt starten", "Angebot anfordern" |
| `share` | Lateral | Internal influence | "Forward to your leadership team", "Share with your board", "Brief your CTO" | "An Geschäftsführung weiterleiten", "Mit Vorstand teilen", "CTO briefen" |

## Urgency Levels

| Urgency | When to Use | Visual Weight | Copy Signals |
|---------|-------------|---------------|--------------|
| `high` | Closing sections, time-sensitive offers, CTA sections | Primary CTA button, accent color, prominent placement | "now", "today", "before [deadline]", "jetzt", "noch heute" |
| `medium` | Supporting evidence sections, mid-funnel actions | Secondary CTA, text link, subtle highlight | "discover", "learn", "explore", "entdecken", "erfahren" |
| `low` | Early-funnel awareness sections, informational CTAs | Inline text mention, no button | "see also", "for more", "mehr dazu", "weiterlesen" |

## Arc-to-CTA Heuristics

Map arc roles to appropriate CTA types. Each arc role has a natural CTA affinity:

| Arc Role | Primary CTA Type | Urgency | Reasoning |
|----------|-----------------|---------|-----------|
| `hook` | `explore` | low | Audience is not yet engaged — offer easy entry |
| `problem` | `evaluate` | medium | Audience recognizes the issue — offer self-assessment |
| `urgency` | `share` | medium | Audience feels pressure — encourage internal escalation |
| `evidence` | `explore` | low | Audience wants proof — offer deeper reading |
| `solution` | `evaluate` | medium | Audience sees the answer — offer hands-on evaluation |
| `proof` | `commit` | high | Audience is convinced — offer commitment |
| `roadmap` | `commit` | high | Audience sees the path — offer next step |
| `call-to-action` | `commit` | high | Audience is ready — direct ask |

## CTA Extraction Rules

Extract implicit CTAs from narrative content by detecting:

1. **Imperative verbs** — "Contact us", "Schedule a meeting", "Download the report"
2. **Future-oriented promises** — "In 12 weeks...", "Within 3 months..."
3. **Conditional benefits** — "If you act now...", "Companies that start early..."
4. **Comparative advantages** — "vs. competitors who wait...", "compared to manual..."
5. **Risk framing** — "Every day without X costs Y", "The window is closing"

## CTA Generation Rules

Generate new CTAs by combining:

1. **Governing thought** — The core argument implies the primary CTA
2. **Arc type** — why-change arcs favor urgency-driven CTAs; journey arcs favor step-by-step CTAs
3. **Conversion goal** (web only) — consultation, demo, download, trial, contact, calculate
4. **Hero numbers** — Reuse the strongest statistic as CTA ammunition ("Save 23 days of downtime")
5. **Audience context** — Match CTA language to the primary decision-maker's vocabulary

## Per-Section CTA Schema

Each content unit (slide, station, section, poster) receives a `cta` field:

```yaml
cta:
  text: "Schedule a pilot assessment"
  type: "explore|evaluate|commit|share"
  urgency: "low|medium|high"
```

**Constraints:**
- `text`: Max 50 characters, imperative verb start, specific action (not "learn more")
- `type`: Must match one of the four taxonomy types
- `urgency`: Derived from arc role using the heuristic table above, adjustable by user

## CTA Summary Schema

A `cta_summary` block aggregates all per-section CTAs into a prioritized list:

```yaml
## CTA Summary

cta_proposals:
  - text: "Book a 30-minute discovery call"
    type: commit
    urgency: high
    supporting_sections: [6, 7, 8]
  - text: "Download the full trend report"
    type: explore
    urgency: medium
    supporting_sections: [2, 3]
  - text: "Share this analysis with your leadership team"
    type: share
    urgency: medium
    supporting_sections: [4, 5]

primary_cta: "Book a 30-minute discovery call"
conversion_goal: "consultation"
```

**Constraints:**
- 3-5 proposals, ordered by urgency (high first)
- `primary_cta`: The single highest-urgency `commit` CTA — used for hero/closing sections
- `supporting_sections`: List of section numbers that build the case for this CTA
- Each CTA type should appear at least once (explore, evaluate, commit, share)
- `conversion_goal`: Carried forward from parameters (web) or inferred from arc (other formats)

## Interactive CTA Checkpoint

Present the CTA plan to the user for review using AskUserQuestion:

```
Here are the proposed CTAs for your {format}:

**Primary CTA:** {primary_cta}

| Section | CTA | Type | Urgency |
|---------|-----|------|---------|
| {section_id}: {headline} | {cta_text} | {type} | {urgency} |
| ... | ... | ... | ... |

**CTA Summary:**
1. {cta_text} ({type}, {urgency}) — supported by sections {list}
2. {cta_text} ({type}, {urgency}) — supported by sections {list}
3. {cta_text} ({type}, {urgency}) — supported by sections {list}

Would you like to adjust any CTAs, change urgency levels, or add/remove proposals?
```

Wait for user confirmation or adjustments before proceeding.

## Format-Specific Notes

| Format | CTA Rendering | Primary CTA Placement | Notes |
|--------|--------------|----------------------|-------|
| **Slides** | Speaker notes CTA prompts, closing slide CTA | Closing slide (always) | Per-slide CTAs inform speaker delivery, not visual elements |
| **Big Picture** | Station body text, final station as CTA station | Final station (call-to-action role) | CTAs are narrative, not interactive (no buttons) |
| **Web** | CTA buttons, hero CTA, section micro-CTAs | Hero section + final CTA section | `commit` CTAs render as buttons; `explore`/`share` as text links |
| **Storyboard** | Poster body text, summary poster CTA | Summary poster (always last) | CTAs guide presenter's verbal delivery during walkthrough |
