<!--
template: meeting
type: meeting
required_wikilinks:
  - at least one attendee or team — `[[<person-or-team-slug>]]`
  - the project, engagement, or topic the meeting concerns — `[[<context-slug>]]`
suggested_wikilinks:
  - any decision recorded in the meeting (cross-link to a `type: decision` page once filed)
  - prior meeting in the same recurring series
-->

# {{title}}

{{one-sentence summary capturing the meeting's purpose and headline outcome.}}

## Key takeaways

- {{takeaway 1 — what was actually decided / shifted / blocked}}
- {{takeaway 2}}
- {{takeaway 3}}
- {{add 0–4 more}}

## Details

### Meeting meta

- **Date**: {{YYYY-MM-DD}}
- **Attendees**: `[[{{person-1}}]]`, `[[{{person-2}}]]`, …
- **Project / context**: `[[{{context-slug}}]]`
- **Format**: {{standup / planning / review / 1:1 / external}}

### Goal

_(Why the meeting happened. The original prompt or agenda item, in one to three sentences. If the meeting drifted from the goal, note that — drift is a signal.)_

### Key discussions

_(One `###` heading per topic. Capture the substance, not the chronology. Quote sparingly.)_

### Decisions made

- {{decision 1}} — promote to a `type: decision` page if it warrants its own ADR
- {{decision 2}}

### Action items

| What | Owner | Due |
|---|---|---|
| {{action 1}} | `[[{{owner-slug}}]]` | {{date}} |
| {{action 2}} | `[[{{owner-slug}}]]` | {{date}} |

### Parking lot

- {{open question or topic deferred to a later meeting}}

## Sources

- [{{meeting notes / recording / chat log}}](../../raw/{{source-filename}})
