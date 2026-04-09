# Persona Entity Schema — People We Design For

A persona represents a person or group whose reality the engagement aims to improve. Personas are distinct from quality-gate personas (Engagement Sponsor, Solution Architect, etc.) which evaluate deliverable quality — design-for personas represent the people affected by the engagement outcome.

## Lifecycle

```
hypothesis  ──▶  researched  ──▶  validated
(Setup)          (Discover)       (Define/Develop confirmation)
```

- **hypothesis**: A conjecture from Setup — "we think this is about these people." Requires only name, context, and core tension.
- **researched**: Enriched with evidence during Discover — stakeholder mapping, customer journey, empathy mapping, or portfolio import added substance. Empathy map and needs are populated.
- **validated**: Confirmed through Define or Develop review — the End-User Advocate verified that the persona's tensions are preserved in the problem statement and addressed by solutions.

## Schema

```json
{
  "slug": "schichtleiter",
  "name": "Schichtleiter (Produktionslinie)",
  "maturity": "hypothesis | researched | validated",
  "context": "12 Schichtleiter am Standort Sindelfingen, verantwortlich fuer Produktionssteuerung auf 4 Fertigungslinien",
  "core_tension": "Soll datengetrieben entscheiden, hat aber keine digitalen Werkzeuge und eine gescheiterte Tablet-Initiative hinter sich",
  "empathy_map": {
    "thinks": ["Wieder so ein IT-Projekt, das nach 3 Monaten versandet"],
    "feels": ["Frustration ueber manuelle Prozesse, Skepsis gegenueber Digitalisierung"],
    "says": ["Das haben wir schon versucht, hat nicht funktioniert"],
    "does": ["Entscheidet nach Erfahrung und Bauchgefuehl, fuehrt Papierlisten"]
  },
  "needs": [
    "Werkzeuge, die den Arbeitsalltag vereinfachen statt verkomplizieren",
    "Schulung waehrend der Arbeitszeit, nicht als Zusatzbelastung"
  ],
  "source": "setup-hypothesis | discover-enriched | portfolio-import",
  "portfolio_ref": null,
  "phase_log": [
    {"phase": "setup", "action": "created", "date": "2026-03-18"},
    {"phase": "discover", "action": "enriched", "date": "2026-03-20", "detail": "stakeholder-mapping confirmed influence; empathy map populated from customer journey"}
  ]
}
```

## Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | Kebab-case identifier, used as filename (`personas/{slug}.json`) |
| `name` | Yes | Human-readable label — an archetype, not a personal name (unless the engagement identifies specific individuals) |
| `maturity` | Yes | `hypothesis`, `researched`, or `validated` |
| `context` | Yes | One sentence: who they are, how many, their relationship to the engagement |
| `core_tension` | Yes | The central conflict or challenge they face — what makes their current situation unsatisfying |
| `empathy_map` | No | Think/Feel/Say/Do quadrants. Empty arrays for hypothesis; populated during Discover |
| `needs` | No | Short need statements, used in persona-centered HMW questions. 2-5 items when populated |
| `source` | Yes | How this persona was created: `setup-hypothesis`, `discover-enriched`, `portfolio-import` |
| `portfolio_ref` | No | Path to `customers/{market-slug}.json` when imported from cogni-portfolio. Null otherwise |
| `phase_log` | No | Append-only evolution trail. Each entry: `{phase, action, date, detail?}` |

## Scaling by Engagement Weight

| Field | Lightweight HMW | Medium | Heavy / Standard |
|-------|-----------------|--------|------------------|
| slug, name, context, core_tension | Required | Required | Required |
| maturity | `hypothesis` (may stay) | `researched` | `researched` or `validated` |
| empathy_map | Omit or empty | Partially populated | Fully populated |
| needs | Omit or 1-2 items | 2-3 items | 3-5 items |
| phase_log | Optional | Recommended | Required |

## Portfolio Import Mapping

When importing from cogni-portfolio `customers/{market-slug}.json`:

| Portfolio field | Persona field |
|----------------|---------------|
| `profiles[].role` | `name` |
| `profiles[].pain_points[0]` | `core_tension` |
| `profiles[].pain_points` (remaining) | `needs` |
| `profiles[].decision_role` + `profiles[].seniority` | `context` |
| `market_slug` | Part of `portfolio_ref` path |

Set `source: "portfolio-import"` and `maturity: "hypothesis"` — portfolio buyer profiles describe who BUYS, not necessarily who is AFFECTED. The consultant confirms relevance and adjusts.

## Relationship to Quality-Gate Personas

Design-for personas and quality-gate personas serve different roles:

| | Design-for Personas | Quality-Gate Personas |
|---|---|---|
| **Purpose** | Represent people affected by the engagement | Evaluate deliverable quality |
| **Examples** | Schichtleiter, IT-Team, Betriebsrat | Engagement Sponsor, Solution Architect, End-User Advocate |
| **Created by** | Consultant during Setup, enriched in Discover | Pre-defined in skill references |
| **Data** | JSON files in `personas/` | Markdown profiles in `references/personas/` |
| **Evolves** | hypothesis → researched → validated | Static evaluation criteria |

When design-for personas exist, quality-gate personas (especially End-User Advocate and End-User Proxy) cross-reference them to make evaluations concrete rather than abstract.
