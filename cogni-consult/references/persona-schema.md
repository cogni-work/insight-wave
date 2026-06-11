# Persona Entity Schema — Acting Stakeholder Personas

A persona in cogni-consult is an **acting** persona: the plugin speaks and
challenges as them during deliverable work — they are advisors and critics in
the room, not just descriptions of people the engagement designs for. Every
engagement ships two standard advisors (the consulting partner and the project
manager, copied from `references/personas/`); engagements add client-side
stakeholders seeded from the scope Stakeholder dimension.

## Lifecycle

```
hypothesis  ──▶  researched  ──▶  validated
(created)        (enriched with    (confirmed against real
                  evidence)         stakeholder feedback)
```

- **hypothesis**: A conjecture — "we think this stakeholder matters." Requires only name, context, and core tension. Scope-seeded personas start here with empty arrays; the shipped defaults also start at `hypothesis` but come pre-populated with template capabilities/wants/needs (they are advisors whose voice is known up front).
- **researched**: Enriched with evidence — empathy mapping during deliverable work or knowledge-base synthesis added substance. Empathy map, needs, capabilities, and wants are populated.
- **validated**: Confirmed against reality — the consultant verified the persona's tensions and wants with the actual stakeholder (or their proxy).

## Schema

```json
{
  "slug": "consulting-partner",
  "name": "Consulting Partner",
  "role": "challenger",
  "voice": "Pushes for so-what clarity, client value, and the right framework for the job",
  "maturity": "hypothesis | researched | validated",
  "context": "Owns the client relationship and the engagement economics",
  "core_tension": "Wants depth but sells speed",
  "empathy_map": {
    "thinks": [],
    "feels": [],
    "says": [],
    "does": []
  },
  "capabilities": [],
  "wants": [],
  "needs": [],
  "source": "setup-default | scope-seeded",
  "work_log": [
    {"action_field": "market-evidence", "deliverable": "market-sizing", "action": "challenged", "date": "2026-06-11"}
  ]
}
```

## Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | Kebab-case identifier, used as filename (`personas/{slug}.json`) |
| `name` | Yes | Human-readable label — an archetype, not a personal name (unless the engagement identifies specific individuals) |
| `role` | Yes | How the persona acts in deliverable work — `challenger`, `advisor`, `gatekeeper`, `user` |
| `voice` | Yes | One-line acting directive: how this persona sounds when it challenges work |
| `maturity` | Yes | `hypothesis`, `researched`, or `validated` |
| `context` | Yes | One sentence: who they are, their relationship to the engagement |
| `core_tension` | Yes | The central conflict they carry — what makes their position demanding |
| `empathy_map` | No | Think/Feel/Say/Do quadrants. Empty arrays at hypothesis; populated during enrichment |
| `capabilities` | No | What the persona can decide, access, or do — authority, expertise, resources. Grounds what their challenge can credibly demand |
| `wants` | No | Desired outcomes and preferences — what would make them champion the work. Distinct from `needs`: wants are aspirations, needs are unmet requirements/friction points |
| `needs` | No | Short need statements — unmet requirements the work must satisfy. 2-5 items when populated |
| `source` | Yes | How this persona was created: `setup-default` (packaged template) or `scope-seeded` (from the Stakeholder dimension). Enrichment advances `maturity`, never `source` |
| `work_log` | No | Append-only trail addressed by WBS coordinates. Each entry: `{action_field, deliverable, action, date}` |

There is no phase log — cogni-consult has no phases. The `work_log` records
which deliverables the persona touched (created/enriched/challenged), keyed by
`action_field` + `deliverable` like every other log in the plugin.

## The Acting Contract

When a skill acts as a persona, it speaks **in the persona's voice** and
grounds every challenge in the persona's fields:

- `capabilities` bound what the persona can credibly demand or veto
- `wants` shape what would make them accept the work enthusiastically
- `needs` define the bar the work must clear at minimum
- `core_tension` and `empathy_map` color *how* they push back

A challenge produced in act-as mode is structured, not free-form: what's
missing, what they'd push back on, and what would make them accept it. The
challenge is recorded as a `work_log` entry (`action: "challenged"`) on the
persona and surfaced with the deliverable.

## Scaling Guidance

| Field | Quick engagement | Standard engagement |
|-------|------------------|---------------------|
| slug, name, role, voice, context, core_tension | Required | Required |
| maturity | `hypothesis` (may stay) | `researched` for personas that matter |
| empathy_map | Omit or empty | Populated for challenged-against personas |
| capabilities / wants / needs | 1-2 items each | 2-5 items each |
| work_log | As challenges happen | As challenges happen |

The two shipped defaults stay lightweight on purpose — they are advisors whose
voice and tension carry the challenge; enrich them only when the engagement's
reality diverges from the template.
