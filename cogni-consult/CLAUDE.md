# cogni-consult Development Guide

## Identity

cogni-consult is a consulting engagement orchestrator for the insight-wave ecosystem built on three structural bets: **action fields are the work-breakdown-structure containers** for every deliverable (no fixed phase folders), **each deliverable runs its own design-thinking loop** (empathize→define→ideate→prototype→test), and **cogni-knowledge is the central research tool** bound once per engagement and compounding across all deliverables. It was selected after a side-by-side dogfood evaluation of two consulting-orchestration approaches (record: `docs/contributing/cogni-consult-evaluation.md`).

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.x, Preview)
├── CLAUDE.md                      This developer guide
├── README.md                      Plugin documentation
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   ├── dependency-model.md        Deliverable dependency graph: edge schema,
│   │                              validation, cascade + topological refresh
│   ├── deliverable-types.md       Deliverable-type catalog (field-type affinity)
│   ├── evaluation-criteria.md     Six criteria from the replacement evaluation,
│   │                              each with a concrete pass signal
│   ├── frameworks-registry.md     Consulting-framework catalog backing the Define/
│   │                              Prototype framework lens (chosen_framework values)
│   ├── interaction-language.md    Interaction language vs. deliverable language rule
│   ├── persona-schema.md          Acting-persona schema + acting contract
│   ├── project-plan-model.md      Scheduling-field schema + roadmap read-model
│   │                              (topological-layer phase/timeline derivation)
│   ├── publish-routing.md         Canonical publish format→route contract
│   ├── research-routing.md        Canonical cogni-knowledge research rule (binding,
│   │                              pipeline rungs, depth framing, storage contract)
│   ├── personas/                  Packaged default advisors (consulting-partner,
│   │                              project-manager)
│   ├── methods/
│   │   ├── scope-dimensions.md    SMART key question + 5 dimensions + WBS-close method
│   │   ├── empathy-mapping.md     Empathize-stage persona quadrant mapping
│   │   ├── hmw-synthesis.md       Define-stage HMW problem-spec synthesis
│   │   └── guided-ideation.md     Ideate-stage diverge→converge facilitation
│   └── orchestration/             DT orchestration contracts extracted from the
│       │                          consult-design-thinking SKILL body (cap headroom)
│       ├── empathize-intake.md    Pre-gap-check source-material intake rung
│       ├── empathize-empathy-mapping.md  Per-persona empathy-map fan-out + merge
│       │                          + stage-owned persona writes
│       ├── test-provenance-gate.md  Completion-time evidence-provenance record /
│       │                          evidence-provenance-waiver contract
│       ├── test-adherence-review.md  Advisory framework-adherence review dispatch
│       │                          + adherence-review decision-log entry
│       ├── test-promote-check.md   Act-by-default assumption promote-check
│       │                          + assumption-promotion decision-log entry
│       ├── test-persona-challenge.md  Persona-challenge fan-out + merge; writes
│       │                          owned by consult-personas step 5
│       └── close-kb-deposit.md    Elected KB deposit + kb-deposit-waiver contract
├── output-styles/
│   └── strategy-advisor.md        Executive-advisory voice register (opt-in,
│                                  auto-discovered in the /config picker)
├── agents/
│   ├── consult-dashboard-refresher.md  Milestone HTML dashboard refresh (haiku,
│   │                              read-only, no theme prompt)
│   ├── consult-framework-adherence-reviewer.md  Score a finished deliverable against
│   │                              its stored chosen_framework, report structural
│   │                              drift (sonnet, read-only, advisory Test-gate rung)
│   ├── consult-persona-challenger.md  Challenge a deliverable as ONE acting persona
│   │                              in voice, return a structured objection envelope
│   │                              (sonnet, read-only; consult-personas merges + writes)
│   └── consult-empathy-mapper.md  Map ONE persona's empathize-stage empathy map,
│                                  return a structured envelope (sonnet, read-only;
│                                  the Empathize stage merges + writes)
├── scripts/
│   ├── engagement-init.sh         Create engagement directory skeleton
│   │                              + README front door (final, non-fatal step)
│   ├── engagement-status.sh       Read consult-project.json state → JSON
│   ├── generate-engagement-readme.py  Markdown wayfinding front door: write the
│   │                              engagement-root README.md (status snapshot,
│   │                              next action, relative Obsidian links)
│   ├── deliverable-graph.py       Deliverable dependency-graph engine: validate /
│   │                              trace / impact / refresh-order / schedule /
│   │                              cascade-stale
│   ├── resolve-assumptions.py     Render-time {{asm:id}} resolver against the
│   │                              engagement-root assumptions.json registry
│   │                              (fail-loud on unknown ids; verified claim-type
│   │                              values evidence-gated against cogni-claims;
│   │                              --mode link emits [[assumptions#slug|value]])
│   ├── register-generator.py      Generate the browsable assumptions.md register
│   │                              (summary table + anchored ## slug sections)
│   │                              from assumptions.json; overwrite-guarded
│   ├── submit-assumption-claim.py Submit/propagate adapter for the claim-type
│   │                              assumption verify round-trip (consult →
│   │                              cogni-claims → back onto the record)
│   ├── assumption-change-frequency.sh  Read-only git-history spike: how often
│   │                              numeric literals in a deliverable corpus
│   │                              changed (sizing datum for propagation automation)
│   ├── discover-projects.sh       Thin wrapper over the cogni-workspace discovery helper
│   └── _discover_extractor.py     Per-engagement field extractor for the wrapper
└── skills/
    ├── consult-setup/SKILL.md     Engagement entry point: scaffold + knowledge-base bind
    │                              + registry
    ├── consult-scope/SKILL.md     SMART key question + 5 scoping dimensions
    │                              + 3-6 action fields as the WBS
    ├── consult-action-fields/SKILL.md  WBS dashboard + per-field deliverable
    │                              manifests + next-deliverable recommendation
    ├── consult-design-thinking/SKILL.md  Per-deliverable DT loop (empathize→define
    │                              →ideate→prototype→test) + artifact + state writes
    ├── consult-personas/SKILL.md  Acting personas: define from scope, enrich,
    │                              act-as challenge against deliverables (single
    │                              owner of the persona-challenge write contract)
    ├── consult-publish/SKILL.md   Consultant-elected publish seam: completed
    │                              deliverable → presentation-ready brief
    │                              (slides / web-poster / report / infographic)
    ├── consult-resume/SKILL.md    Engagement re-entry point: discovery + WBS
    │                              dashboard + workflow-state next-action routing
    └── consult-dashboard/         Themed HTML engagement dashboard (read-only)
        ├── SKILL.md               pick-theme → design-variables → generate → open
        ├── scripts/generate-dashboard.py  Render dashboard.html from project + field.json
        ├── schemas/               design-variables.schema.json (theme contract)
        └── examples/              design-variables example
```

## Design Principles

- **Action fields as WBS** — scoping derives 3-6 action fields from the key question; every deliverable lives inside exactly one field. Progress is tracked per deliverable, not per global phase
- **Design thinking per deliverable** — each deliverable iterates empathize→define→ideate→prototype→test on its own clock; fields complete when their deliverables do
- **Acting personas as a seed-from-scope gate** — stakeholder personas are seeded from the engagement scope *before* the first design-thinking deliverable can start, then actively challenge deliverable work in their voice (not just describe users). The seed is a gate, not a suggestion: `consult-design-thinking` hard-blocks a not-started deliverable and `consult-resume` routes to persona-seeding first, until the gate is satisfied. The two shipped setup-default advisors (consulting partner, project manager; `source: setup-default`) do **not** satisfy it. The gate is the derived `personas_gate` rollup: **satisfied** when any `personas/*.json` carries `source: scope-seeded` **or** the extensionless `personas/.gate-waiver` marker is present, else **pending**. The waiver is the defaults-only escape — when no external stakeholders are worth modelling, `consult-personas` (mode: waive) writes `.gate-waiver` on explicit confirmation, moving the gate to satisfied without seeding a persona
- **Knowledge base as the research spine** — one cogni-knowledge base bound at setup (`plugin_refs.knowledge_base`); all deliverable research runs through it and compounds
- **Orchestrator, not producer** — manages engagement state; content work dispatches to existing plugins
- **Read-only fan-out agents, single write owner** — parallelizable per-item judgment (Test-stage persona challenge, Empathize empathy-mapping, Test-gate framework-adherence review) is delegated to read-only agents that return `{success, data, error}` envelopes; the orchestrating skill merges the envelopes and owns every write. The persona-challenge write contract lives in exactly one place (consult-personas' challenge mode); the DT loop delegates instead of reimplementing. Together with structural validation and the persona challenge, the advisory adherence review completes the repo's Three-Layer Quality Gate; all gates are advisory — auto-walk never deadlocks. Dense fan-out/merge/idempotency contracts live in `references/orchestration/`, keeping the SKILL body under the 500-line cap
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB
- **Voice in the output style, phase discipline in the skills** — the always-on executive-advisory *voice* lives in the `output-styles/strategy-advisor.md` output style (opt-in, fixed at session start); the diverge/converge *phase discipline* stays in the consult-* skills, which load contextually so they never fire outside an active engagement

## Data Model

Each engagement lives in `cogni-consult/{slug}/` with:
- `consult-project.json` — engagement config, key question, action-field list, scope state, plugin refs
- `assumptions.json` — single source of truth for assumption values; deliverables and briefs cite them as `{{asm:id}}` placeholders resolved at publish time by `resolve-assumptions.py`
- `assumptions.md` — the human-browsable register generated from `assumptions.json` by `register-generator.py` (summary table + anchored `## <slug>` sections); the click-through target for `resolve-assumptions.py --mode link` wikilinks. Generated artifact, overwrite-guarded
- `scope/` — key question + 5 scoping dimensions + derived action-field list
- `action-fields/{field-slug}/` — one directory per WBS field: `field.json` (single source of truth for the field's deliverable states) + deliverable markdown artifacts
- `personas/` — acting stakeholder personas (JSON)
- `sources/` — engagement source inbox: the documented drop location for raw material (LOI, specs, notes, transcripts) to ground a deliverable; scaffolded at setup with a `README.md`, the Empathize stage ingests it into the bound base or reads it into a deliverable's `sources[]`
- `.metadata/` — execution-log, method-log, decision-log (all addressed by `action_field` + `deliverable`)

Full schemas: `references/data-model.md`.

## Scripts

| Script | Purpose |
|--------|---------|
| `engagement-init.sh` | Create the engagement directory skeleton + consult-project.json, then write the engagement-root `README.md` front door via `generate-engagement-readme.py` (final step, non-fatal — a generator failure degrades to a stderr warning) |
| `engagement-status.sh` | Read consult-project.json + derive field/deliverable rollups from `field.json` files, plus the `personas_gate` rollup (satisfied when a `personas/*.json` has `source: scope-seeded` or the extensionless `personas/.gate-waiver` marker is present, else pending) → JSON |
| `generate-engagement-readme.py` | Write the Obsidian-browsable `README.md` front door at the engagement root from the same read model (key question, status snapshot, single next recommended deliverable incl. the `personas_gate` rung, wayfinding links that only target existing files); read-only except the `README.md` it writes. Invoked at scaffold time by `engagement-init.sh` and, unconditionally and non-fatally, at the dashboard milestones — `consult-design-thinking` (session close), `consult-action-fields` (WBS change), `consult-resume` (re-entry) — the markdown parallel to `consult-dashboard-refresher`'s theme-gated HTML refresh |
| `deliverable-graph.py` | Deliverable dependency-graph engine over all `field.json` files: `validate` (cycles + dangling refs), `trace` (upstream lineage), `impact` (downstream blast radius), `refresh-order` (topological layering of stale deliverables), `schedule` (duration-weighted earliest-start/finish + critical path over `depends_on[]`), `cascade-stale` (flag downstream `lineage_status` via idempotent RMW). Full model: `references/dependency-model.md` |
| `resolve-assumptions.py` | Render-time resolver replacing `{{asm:<slug>}}` placeholders with values from the engagement-root `assumptions.json` registry (single source of truth for assumption values). Fail-loud on unresolvable placeholders; wired into `consult-publish` as the mandatory post-build/pre-lineage pass (contract: `references/publish-routing.md`). A cited claim-type assumption at `verified` is evidence-gated: its `citation.claim_id` must resolve to a verified ClaimRecord in the workspace `cogni-claims/claims.json` (read-only; `--claims-file` overrides the location), else the resolve fails loud. The opt-in `--mode link` capability substitutes `[[assumptions#<slug>\|<value>]]` wikilinks into the browsable register instead of the literal value (marker intact); the default `value` mode is byte-for-byte the pre-existing publish behaviour |
| `register-generator.py` | Generate the human-browsable `assumptions.md` register at the engagement root from `assumptions.json`: a summary table (id→anchor, value, type, status, source host, used_by count) plus one anchored `## <slug>` section per assumption (value, provenance, rationale, citation source-lineage quad, `used_by[]` backlinks). Read-only except the register it writes; overwrite-guarded on the same generated-marker footer as `generate-engagement-readme.py`. The `## <slug>` headings are the exact anchors `resolve-assumptions.py --mode link` targets |
| `submit-assumption-claim.py` | Submit/propagate adapter for the claim-type assumption verify round-trip: `submit` maps the assumption onto the unchanged cogni-claims `EntityRef` object contract and appends an `unverified` ClaimRecord under a mkdir lock (idempotent — one assumption, one record); `propagate` writes `status: "verified"` + `citation.claim_id` back onto the assumption record, refusing unless the referenced ClaimRecord is itself verified; `resolve-propagate <asm-id> [--corrected-value <v>]` completes the deviated→resolved leg — writes the corrected value onto the assumption, demotes `status` `verified`→`reviewed`, and stamps `citation.propagated_at`, refusing unless the ClaimRecord is `status: "resolved"` with `resolution.action == "corrected"` (guarded so a resumed run is a no-op). `--corrected-value` is optional: when omitted the value falls back verbatim to the ClaimRecord's `resolution.corrected_statement` (a full sentence, not a scalar extracted from it), failing loud with `corrected_value_missing` when neither is present |
| `assumption-change-frequency.sh` | Read-only retrospective spike (bash exec-delegator over a stdlib-only python3 miner): mines the git history of a deliverable corpus and reports how often bare numeric literals changed (`edits_per_literal` over the observed window). Registry-independent — reads git history, not `assumptions.json` — so it sizes the payoff of the propagation automation before that automation exists. Compares each commit's full-file literal counts against the previous version (not diff fragments), so frontmatter and code-fence boundaries are detected exactly |
| `discover-projects.sh` | Thin wrapper delegating to `cogni-workspace/scripts/discover-plugin-projects.sh` (registry: `$HOME/.claude/cogni-consult-projects.json`) |
| `_discover_extractor.py` | Per-engagement JSON field extractor consumed by the discovery wrapper (reads the flat consult-project.json schema) |

All scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`.
All scripts are stdlib-only (bash + python3, no pip dependencies).

## Key Conventions

- Engagement and entity slugs in kebab-case, derived from names
- Workflow state per deliverable: `pending` → `in-progress` → `complete` (→ `in-progress` on iteration re-entry); stored only in `field.json`, field and engagement completion derived at read time
- `dt_stage` tracks the design-thinking stage per deliverable (`empathize`/`define`/`ideate`/`prototype`/`test`)
- `personas_gate` is a **derived** rollup (never stored): `engagement-status.sh` computes it at read time from the `personas/` directory — **satisfied** when any `personas/*.json` carries `source: scope-seeded` or the extensionless `personas/.gate-waiver` marker exists, else **pending**. It gates the first design-thinking deliverable (seed personas from scope, or take the defaults-only waiver, before deliverable work starts)
- Entity outputs are Obsidian-browsable markdown with YAML frontmatter; state files are plain JSON
- `language` field in consult-project.json is the deliverable/output language for artifacts (technical terms stay English); the user-facing interaction language is a separate, runtime-derived axis (workspace default + message-detection override, never stored) — see `references/interaction-language.md`
- **Research routing**: every research run goes through the engagement's bound knowledge base per `references/research-routing.md` — the canonical rule all deliverable-producing skills point at (binding via `plugin_refs.knowledge_base`, pipeline rungs, depth framing, syntheses copied to `action-fields/<field-slug>/research/<topic-slug>.md`); raw WebSearch only for a single trivial fact-check
- **Publish seam**: `consult-publish` is the consultant-elected, never-auto-firing path that turns a completed deliverable into a presentation-ready brief. It appends one `{format, brief_path, route_steps, source_deliverable, published_at}` entry per published format to the deliverable's `publish[]` array in `field.json` (`format` ∈ `{slides, web-poster, report, infographic}`); `brief_path` is a **path reference** to the produced brief — never copied content, mirroring the source-lineage discipline so an upstream correction stays visible downstream, and `engagement-status.sh` passes the array through verbatim (no script change). Rendering and brand are out of scope: cogni-consult emits the brief, Claude Design (claude.ai/design) renders it. Every format builds a consult-native brief, so the standard path never requires `cogni-visual` (it remains an opt-in local-render fallback only); the optional `cogni-copywriting` polish step is skipped when absent. Canonical routing contract: `references/publish-routing.md`; `publish[]` schema: `references/data-model.md`
