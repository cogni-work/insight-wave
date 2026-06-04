<!--
template: decision (ADR-shaped)
type: decision
required_wikilinks:
  - the engagement, project, or scope the decision belongs to — `[[<context-slug>]]`
  - any prior decision this one supersedes or revises — `[[<prior-decision-slug>]]` (omit if first of its kind)
suggested_wikilinks:
  - inputs that informed the decision (interviews, learnings, prior summaries)
  - downstream pages that should now be updated to reflect the decision
-->

# {{title}}

{{one-sentence summary stating the decision in plain prose: "We chose X over Y, because Z."}}

## Key takeaways

- **Decision**: {{decided option, restated for grep-ability}}
- **Owner**: `[[{{decision-owner-slug}}]]`
- **Status**: {{proposed | accepted | superseded | deprecated}}
- {{additional takeaway capturing the most consequential trade-off}}

## Details

### Context

_(What problem prompted this decision? What forces — technical, organisational, customer-driven — pushed it onto the agenda? Pull from the source; do not narrate from memory.)_

### Options considered

| Option | Pros | Cons | Notes |
|---|---|---|---|
| {{option A}} | {{pros}} | {{cons}} | {{notes / who advocated}} |
| {{option B}} | {{pros}} | {{cons}} | {{notes}} |
| {{option C — including "do nothing" if it was a real option}} | {{pros}} | {{cons}} | {{notes}} |

### Decision

_(State the chosen option in one paragraph. Make the choice unambiguous — a future reader landing here without context should know exactly what was decided.)_

### Rationale

_(Why this option over the alternatives? What evidence, principles, or constraints drove the choice? Cite inputs with `[[wikilinks]]` to interviews, learnings, prior decisions.)_

### Consequences

- **Expected positive**: {{what we believe will improve}}
- **Expected negative / accepted cost**: {{what we are knowingly trading away}}
- **Open risks**: {{what could invalidate this decision later}}

### Revisit conditions

_(What signal would trigger reopening this decision? E.g. "if customer churn on tier-2 exceeds 8% in any quarter", "after the next engagement of this shape ships". Without this, decisions ossify.)_

## Sources

- [{{deciding meeting or doc}}](../../raw/{{source-filename}})
