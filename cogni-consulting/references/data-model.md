# cogni-consulting Data Model Reference

## Engagement Structure

```
cogni-consulting/{engagement-slug}/
├── consulting-project.json                   # Engagement config, vision, phase state
├── .metadata/
│   ├── execution-log.json                 # Phase transitions and timestamps
│   ├── method-log.json                    # Methods proposed and selected per phase
│   └── decision-log.json                  # Key decisions with rationale
├── discover/                              # D1 diverge outputs
│   ├── research/                          # → cogni-research project
│   ├── trends/                            # → cogni-trends project
│   └── competitive/                       # → cogni-portfolio scan
├── define/                                # D1 converge outputs
│   ├── claims/                            # → cogni-claims verification
│   ├── problem-statement.md               # Synthesized problem framing
│   └── assumptions.md                     # Mapped and prioritized assumptions
├── develop/                               # D2 diverge outputs
│   ├── options/                           # Generated solution options
│   ├── propositions/                      # → cogni-portfolio propositions
│   ├── scenarios/                         # Scenario planning artifacts
│   └── lean-canvas.md                     # Lean Canvas (business-model-hypothesis class)
├── deliver/                               # D2 converge outputs
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
    "discover": "complete",
    "define": "complete",
    "develop": "in-progress",
    "deliver": "pending"
  },
  "plugin_refs": {
    "research": "cogni-research/dach-cloud-expansion",
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
| `language` | No | ISO 639-1 code (default: `en`). Controls communication language; technical terms stay English |
| `phase_state` | Yes | Per-phase status: `pending` → `in-progress` → `complete` |
| `plugin_refs` | No | Relative paths to projects created by other plugins |
| `created` | Yes | ISO date of engagement creation |
| `updated` | Yes | ISO date of last modification |

### execution-log.json (Phase Transitions)

Tracks when each phase started and completed, with the consultant who triggered the transition.

```json
{
  "transitions": [
    {
      "phase": "discover",
      "from": "pending",
      "to": "in-progress",
      "timestamp": "2026-03-10T09:00:00Z",
      "triggered_by": "consulting-discover"
    },
    {
      "phase": "discover",
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
    "discover": {
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
      "phase": "define",
      "decision": "Focus on mid-market cloud migration rather than greenfield",
      "rationale": "Research shows 73% of DACH mid-market has legacy on-prem; greenfield TAM is 4x smaller",
      "evidence_refs": ["cogni-research/dach-cloud-expansion/report.md"],
      "timestamp": "2026-03-14T11:00:00Z"
    }
  ]
}
```

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
              │
              └── (phase gate advisory — consultant can override)
```

Phase gates are advisory: the phase-analyst agent assesses readiness and warns if criteria aren't met, but the consultant can proceed. Exception: the Develop proposition quality gate blocks by default — propositions failing on high-weight criteria are excluded from Option Synthesis unless explicitly reinstated.

## Cross-Plugin Integration

| Plugin | Direction | Phase | Contract |
|--------|-----------|-------|----------|
| cogni-research | Orchestrates | Discover | Creates research project, invokes research-report skill |
| cogni-trends | Orchestrates | Discover, Develop | Invokes trend-scout (Discover) and value-modeler (Develop) |
| cogni-portfolio | Orchestrates | Discover, Develop, Deliver | Invokes portfolio-scan, compete, propositions, solutions, portfolio-verify |
| cogni-claims | Orchestrates | Define, Deliver | Invokes claims verification for assumption and deliverable quality gates |
| cogni-visual | Orchestrates | Export | Invokes story-to-slides, story-to-big-picture for final deliverables |
| document-skills | Orchestrates | Export | Formats outputs as PPTX, DOCX, XLSX |
