# cogni-sales

B2B sales pitch generation using Corporate Visions Why Change methodology — creates deal-specific or reusable segment pitches from cogni-portfolio data with web research evidence. Bilingual DE/EN.

## Plugin Architecture

```
skills/                         1 pitch skill (why-stay, why-evolve planned)
  why-change/                     6-phase pipeline: setup → why-change → why-now → why-you → why-pay → synthesize
    SKILL.md                      Full orchestration logic with quality gates per phase
    references/
      pitch-data-model.md         Entity schemas: pitch-log.json, bridge files, claims
      output-specs.md             Deliverable templates for both customer and segment modes
    evals/
      evals.json                  Eval definitions for segment and security pitches
    why-change-workspace/         Iteration workspace with eval baselines (iteration-0 through iteration-3)

agents/                         2 pitch agents
  why-change-researcher.md        All 4 content phases: web research, evidence, narrative, claims (opus)
  pitch-synthesizer.md            Assemble final deliverables from phase bridge files (sonnet)

commands/                       1 slash command
  why-change.md                   Entry point — /why-change (aliases: /pitch, /sales-pitch, /segment-pitch)

scripts/                        3 project utilities
  discover-portfolio.sh           Scan workspace for cogni-portfolio projects, return JSON metadata
  init-pitch-project.sh           Scaffold pitch project directory under cogni-sales/{slug}/
  pitch-status.sh                 Report pitch state: mode, phase, claims, deliverable readiness

references/
  section-headers-de.md           German header mapping for all narrative sections
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 1 | why-change (6-phase pipeline) |
| Agents | 2 | why-change-researcher (opus), pitch-synthesizer (sonnet) |
| Commands | 1 | /why-change (aliases: /pitch, /sales-pitch, /segment-pitch) |
| Scripts | 3 | discover-portfolio, init-pitch-project, pitch-status |

## Workflow Pipeline

```
setup → why-change → why-now → why-you → why-pay → synthesize
 (0)       (1)         (2)       (3)       (4)        (5)
```

**Phase 0 — Setup:** Portfolio discovery, pitch mode selection (customer vs segment), market matching, optional TIPS discovery, solution focus, buyer roles, language, project initialization.

**Phase 1 — Why Change:** Research unconsidered needs. The researcher agent first runs Phase 2.5 (Theme Reasoning) — backwards from portfolio capabilities to derive strategic themes, ranking TIPS investment themes by portfolio alignment when available, then generating targeted search queries. Web research follows guided by these themes. PSB (Problem-Solution-Benefit) structure with contrast patterns.

**Phase 2 — Why Now:** Research urgency drivers. Forcing functions with specific timelines — regulatory deadlines, competitive moves, market windows. Quantified cost of inaction.

**Phase 3 — Why You:** Research differentiation. IS/DOES/MEANS structure where IS starts from the portfolio solution entity (never the customer's problem), DOES states quantified outcomes with You-Phrasing, MEANS explains the competitive moat (barrier to replication, not just outcomes).

**Phase 4 — Why Pay:** Research business impact. Revenue-scaled cost-of-inaction using market `segmentation.arr_min`/`arr_max`. 3-year compound cost stacking. Investment vs inaction ratio.

**Phase 5 — Synthesize:** Assemble all phases into `sales-presentation.md` and `sales-proposal.md` with sequentially renumbered citations and YAML frontmatter.

Each phase has a **quality gate** — the orchestrator presents key findings to the user for approval or revision before proceeding. Interrupted pitches resume from the last completed phase via `pitch-status.sh`.

## Pitch Modes

| Aspect | Customer Mode | Segment Mode |
|--------|--------------|--------------|
| Target | Named company (e.g., "Siemens") | Market segment (e.g., "Enterprise Manufacturing DACH") |
| Research | Company-specific web searches, website analysis | Industry-level web searches, market analysis |
| Framing | "Siemens faces..." / "Your current approach..." | "Organizations in this segment face..." |
| Buyer roles | User-provided titles for specific account | Loaded from portfolio customer profiles or asked for typical segment titles |
| Deliverables | Deal-specific presentation + proposal | Reusable template presentation + proposal |
| Project path | `cogni-sales/{slug}/pitch/` | `cogni-sales/{slug}/segment-pitch/` |

## Cross-Plugin Integration

| Plugin | Required | Direction | Mechanism |
|--------|----------|-----------|-----------|
| cogni-portfolio | Yes | upstream | Products, features, propositions (IS/DOES/MEANS), solutions (pricing tiers), markets (TAM/SAM/SOM, revenue range), competitors, customers (reference accounts) |
| cogni-narrative | Yes | upstream | Corporate Visions arc definition + per-phase pattern files (why-change-patterns.md, why-now-patterns.md, why-you-patterns.md, why-pay-patterns.md) |
| cogni-trends | No | upstream | TIPS value-model themes, regulatory timelines, solution templates, gap analysis — enriches all 4 phases when available |
| cogni-claims | No | downstream | Claims registered during research with source URLs; `/claims verify` validates them |
| cogni-copywriting | No | downstream | Executive polish on final deliverables (`/copywrite sales-presentation.md`) |
| cogni-visual | No | downstream | PPTX generation from sales presentation (`/pptx create sales-presentation.md`) |

## Data Model

Each pitch project lives at `cogni-sales/{slug}/pitch/` (customer) or `cogni-sales/{slug}/segment-pitch/` (segment):

- `.metadata/pitch-log.json` — Master state: pitch_mode, target, portfolio_path, tips_path, buying_center, workflow_state, language
- `.metadata/theme-brief.json` — Strategic themes from backwards portfolio reasoning: capability clusters, ranked TIPS themes, portfolio-derived themes, focused search queries
- `.metadata/claims.json` — Registered claims with source URLs, authority scores (1-5), freshness, evidence type classification
- `01-why-change/` — `research.json` (structured findings) + `narrative.md` (prose)
- `02-why-now/` — `research.json` + `narrative.md`
- `03-why-you/` — `research.json` + `narrative.md`
- `04-why-pay/` — `research.json` + `narrative.md`
- `output/sales-presentation.md` — Why Change narrative arc with YAML frontmatter
- `output/sales-proposal.md` — Formal proposal with implementation and pricing

Bridge files (`research.json`) carry structured findings with evidence arrays, buyer role relevance tags, portfolio entity references, and signal origin (`tips` or `web`). Narrative files (`narrative.md`) carry prose only — no buyer role tags.

## Key Conventions

- Scripts use JSON output: `{"success": bool, ...}` / `{"error": "string"}`
- Scripts are stdlib-only (bash + jq, no pip dependencies)
- Source Authority Matrix scores every source 1-5 (government/peer-reviewed = 5, blogs = 1); prefer 4-5 for quantitative claims
- Blocked domains: pinterest, facebook, instagram, tiktok, reddit — never used as sources
- Anti-hallucination rules: never fabricate URLs, never invent statistics, never round numbers, always include exact URL
- DACH site-specific searches when `language=de`: fraunhofer.de, bitkom.org, vdma.org, eur-lex.europa.eu, handelsblatt.com, destatis.de
- German output uses proper umlauts (never ASCII substitutes); section headers from `references/section-headers-de.md`
- IS/DOES/MEANS semantics: IS describes the solution (never the problem), DOES states outcomes with You-Phrasing, MEANS states the moat (barrier to replication)
- No competitor pricing — use relative language ("wettbewerbsfähig") to avoid contractual risk
- Geographic qualification for uniqueness claims — never claim global uniqueness when only regional applies
- Vendor claim attribution — always prefix with "laut {Vendor}"; never present vendor marketing as provider operational results
- Revenue-scaled cost-of-inaction — if projected costs are <0.5% of `arr_min`, they are immaterial to a CFO
- Plugin version lives at `.claude-plugin/plugin.json` (currently v0.3.5)
