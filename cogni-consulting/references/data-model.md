# cogni-consulting Data Model Reference

## Engagement Structure

```
cogni-consulting/{engagement-slug}/
├── consulting-project.json                   # Engagement config, vision, phase state
├── .metadata/
│   ├── execution-log.json                 # Phase transitions and timestamps
│   ├── method-log.json                    # Methods proposed and selected per phase
│   └── decision-log.json                  # Key decisions with rationale
├── personas/                              # People we design for (see persona-schema.md)
│   └── {persona-slug}.json               # One file per persona, evolves across phases
├── 0-scope/                               # Key question + scoping dimensions
├── 1-discover/                              # D1 diverge outputs
│   ├── research/                          # summary.md ← cogni-knowledge synthesis (copied from the bound base)
│   ├── trends/                            # → cogni-trends project
│   └── competitive/                       # → cogni-portfolio scan
├── 2-define/                                # D1 converge outputs
│   ├── claims/                            # → cogni-claims verification
│   ├── problem-statement.md               # Synthesized problem framing
│   └── assumptions.md                     # Mapped and prioritized assumptions
├── 3-develop/                               # D2 diverge outputs
│   ├── options/                           # Generated solution options
│   ├── propositions/                      # → cogni-portfolio propositions
│   ├── scenarios/                         # Scenario planning artifacts
│   └── lean-canvas.md                     # Lean Canvas (business-model-hypothesis class)
├── 4-deliver/                               # D2 converge outputs
│   ├── claims/                            # → cogni-claims final verification
│   ├── business-case.md                   # Business case canvas
│   ├── canvas-stress-test.md              # Lean Canvas stress-test report (business-model-hypothesis class)
│   └── roadmap.md                         # Implementation roadmap
└── output/                                # Final deliverable package
    └── {format}/                          # → cogni-visual / document-skills
```

## Entity Schemas

### consulting-project.json (Engagement Root)

Central state file for the engagement. Tracks vision, phase progression, and cross-plugin project references.

```json
{
  "slug": "dach-cloud-expansion",
  "name": "DACH Cloud Portfolio Expansion",
  "vision_class": "strategic-options",
  "vision_statement": "Ranked strategic alternatives for expanding cloud portfolio in the DACH market",
  "language": "de",
  "phase_state": {
    "0-scope": "complete",
    "1-discover": "complete",
    "2-define": "complete",
    "3-develop": "in-progress",
    "4-deliver": "pending"
  },
  "plugin_refs": {
    "knowledge_base": "dach-cloud-expansion",
    "trends": "cogni-trends/dach-cloud-expansion",
    "portfolio": "cogni-portfolio/acme-cloud-services",
    "claims": "cogni-claims/"
  },
  "created": "2026-03-10",
  "updated": "2026-03-18"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | Kebab-case identifier derived from engagement name |
| `name` | Yes | Human-readable engagement name |
| `vision_class` | Yes | One of 7 engagement types (see Vision Classes below) |
| `vision_statement` | Yes | Desired outcome in one sentence |
| `engagement_weight` | No | For `how-might-we` class: `"lightweight"`, `"medium"`, or `"heavy"`. Controls coaching intensity and phase collapsing. `null` for non-HMW classes. |
| `language` | No | ISO 639-1 code (default: `en`). Controls communication language; technical terms stay English |
| `phase_state` | Yes | Per-phase status: `pending` → `in-progress` → `complete` |
| `plugin_refs` | No | Slugs/relative paths to projects created by other plugins. `plugin_refs.knowledge_base` holds the cogni-knowledge base slug bound to the engagement (research compounds there across phases). The legacy `plugin_refs.research_project` (a cogni-research slug) is **deprecated** — engagements now bind a cogni-knowledge base instead. |
| `created` | Yes | ISO date of engagement creation |
| `updated` | Yes | ISO date of last modification |

### execution-log.json (Phase Transitions)

Tracks when each phase started and completed, with the consultant who triggered the transition.

```json
{
  "transitions": [
    {
      "phase": "1-discover",
      "from": "pending",
      "to": "in-progress",
      "timestamp": "2026-03-10T09:00:00Z",
      "triggered_by": "consulting-discover"
    },
    {
      "phase": "1-discover",
      "from": "in-progress",
      "to": "complete",
      "timestamp": "2026-03-12T17:00:00Z",
      "triggered_by": "phase-analyst"
    }
  ]
}
```

### method-log.json (Method Selection)

Records which methods were proposed and selected for each phase.

```json
{
  "phases": {
    "1-discover": {
      "proposed": ["desk-research-framing", "stakeholder-mapping", "customer-journey-analysis"],
      "selected": ["desk-research-framing", "stakeholder-mapping"],
      "rationale": "Customer journey analysis deferred — insufficient direct customer access"
    }
  }
}
```

### decision-log.json (Key Decisions)

Audit trail of decisions made during the engagement with rationale and traceability.

```json
{
  "decisions": [
    {
      "id": "d-001",
      "phase": "2-define",
      "decision": "Focus on mid-market cloud migration rather than greenfield",
      "rationale": "Research shows 73% of DACH mid-market has legacy on-prem; greenfield TAM is 4x smaller",
      "evidence_refs": ["1-discover/research/summary.md"],
      "timestamp": "2026-03-14T11:00:00Z"
    }
  ]
}
```

### personas/{slug}.json (Design-For Personas)

People the engagement aims to help. Created during Setup as hypotheses, enriched during Discover, referenced in Define/Develop/Deliver. Distinct from quality-gate personas (Engagement Sponsor, etc.) which evaluate deliverables.

See `references/persona-schema.md` for the full schema, lifecycle, and portfolio import mapping.

```json
{
  "slug": "schichtleiter",
  "name": "Schichtleiter (Produktionslinie)",
  "maturity": "hypothesis",
  "context": "12 Schichtleiter am Standort Sindelfingen",
  "core_tension": "Soll datengetrieben entscheiden, hat aber keine digitalen Werkzeuge",
  "empathy_map": { "thinks": [], "feels": [], "says": [], "does": [] },
  "needs": [],
  "source": "setup-hypothesis",
  "portfolio_ref": null,
  "phase_log": [{"phase": "setup", "action": "created", "date": "2026-03-18"}]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | Kebab-case identifier, used as filename |
| `name` | Yes | Archetype label |
| `maturity` | Yes | `hypothesis` → `researched` → `validated` |
| `context` | Yes | Who they are, their relationship to the engagement |
| `core_tension` | Yes | Central conflict or challenge they face |
| `empathy_map` | No | Think/Feel/Say/Do — populated during Discover |
| `needs` | No | Need statements used in persona-centered HMW questions |
| `source` | Yes | `setup-hypothesis`, `discover-enriched`, `portfolio-import` |
| `portfolio_ref` | No | Path to cogni-portfolio customer file if imported |
| `phase_log` | No | Append-only evolution trail |

## Vision Classes

8 engagement types that determine recommended methods and deliverables:

| Class | Outcome | Typical Duration |
|-------|---------|------------------|
| `strategic-options` | Ranked strategic alternatives with evaluation criteria | 4-8 weeks |
| `business-case` | Investment justification with financials and risk analysis | 3-6 weeks |
| `gtm-roadmap` | Go-to-market plan with channels, segments, and timeline | 4-6 weeks |
| `cost-optimization` | Prioritized cost reduction opportunities | 3-5 weeks |
| `digital-transformation` | Current-to-target state mapping with transition roadmap | 6-12 weeks |
| `innovation-portfolio` | Prioritized innovation investment bets across horizons | 4-8 weeks |
| `market-entry` | Market feasibility assessment and entry strategy | 4-8 weeks |
| `business-model-hypothesis` | Validated Lean Canvas with research-backed hypothesis | 2-4 weeks |

## Phase State Machine

```
pending ──▶ in-progress ──▶ complete
              │                 │
              │                 └──▶ in-progress (iteration re-entry)
              └── (phase gate — blocks by default, consultant can override)
```

Each phase tracks an `iteration_count` (default 0) that increments on re-entry from `complete` to `in-progress`. This enables consultants to revisit and refine completed phases without losing the audit trail.

Phase gates are enforced at the skill level: each phase skill checks that required inputs from the previous phase exist and have adequate quality (not just file existence, but content substance). The gate blocks by default — the consultant can override by explicitly requesting to proceed. Exception: the Develop proposition quality gate additionally blocks individual propositions that fail on high-weight criteria.

## Cross-Plugin Integration

| Plugin | Direction | Phase | Contract |
|--------|-----------|-------|----------|
| cogni-knowledge | Orchestrates | Discover, Define, Develop, Deliver | Binds one knowledge base per engagement (`knowledge-setup`, slug in `plugin_refs.knowledge_base`) and runs the inverted pipeline (`knowledge-plan → … → knowledge-finalize`); research compounds across phases. Synthesis copied to `<phase>/research/summary.md` |
| cogni-trends | Orchestrates | Discover, Develop | Invokes trend-scout (Discover) and value-modeler (Develop) |
| cogni-portfolio | Orchestrates | Discover, Develop, Deliver | Invokes portfolio-scan, compete, propositions, solutions, portfolio-verify |
| cogni-claims | Orchestrates | Define, Deliver | Invokes claims verification for assumption and deliverable quality gates |
| cogni-visual | Orchestrates | Export | Invokes story-to-slides, enrich-report for final deliverables |
| document-skills | Orchestrates | Export | Formats outputs as PPTX, DOCX, XLSX |
