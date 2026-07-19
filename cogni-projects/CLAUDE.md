# cogni-projects

Partner-facing project-portfolio steering for consulting firms. Models
consultants, projects, and staffing so partners can match people to work by
availability, profile fit, and strategic impact. The data model, entity
authoring, the staffing match engine, and the read-only portfolio dashboard
have landed; the backfilling recommender arrives in later roadmap children.

## Plugin Architecture

```
cogni-projects/
├── .claude-plugin/plugin.json        Plugin manifest (name, version, description)
├── README.md                         Plugin documentation (IS/DOES/MEANS messaging)
├── CLAUDE.md                         This developer guide
├── skills/
│   ├── projects-setup/SKILL.md       Initialize a portfolio directory (entry point)
│   ├── projects-entities/SKILL.md    Author + register one consultant/project/assignment
│   ├── projects-staff/SKILL.md       Rank candidate consultants per open project role
│   └── projects-dashboard/SKILL.md   Render a partner-meeting portfolio dashboard (read-only)
├── scripts/
│   ├── portfolio-init.sh             Idempotent portfolio scaffolder (stdlib-only)
│   ├── validate-entities.py          Entity frontmatter validator (stdlib-only)
│   ├── register-entity.py            Slug-keyed manifest upsert + execution-log append
│   ├── staffing-score.py             Deterministic staffing scorer (availability/fit/impact)
│   └── render-dashboard.py           Portfolio health + value HTML render (read-only, stdlib-only)
├── tests/
│   ├── test_register_entity.sh       Atomic-write + idempotency regression suite
│   └── test-render-dashboard.sh      Dashboard render regression test (stdlib-only)
└── references/
    └── data-model.md                 Consultant / project / assignment entity schemas
```

Run the tests directly — bash + python3, no pytest or pip:

```bash
bash cogni-projects/tests/test_register_entity.sh
bash cogni-projects/tests/test-render-dashboard.sh
```

Planned (not yet scaffolded — see the roadmap epic):

- `skills/` for the backfilling recommender.

## Data Model

A portfolio is one `cogni-projects/<portfolio-slug>/` directory:

- `projects-portfolio.json` — root manifest. Holds portfolio identity (`slug`,
  `name`, `language`, `created`, `updated`) plus the `consultants[]`,
  `projects[]`, and `assignments[]` entity lists (empty at scaffold time) and a
  `workflow_state` object.
- `consultants/`, `projects/`, `assignments/` — per-entity record directories.
- `.metadata/` — append-only logs (`execution-log.json`, `staffing-log.json`,
  `decision-log.json`) later skills write to. `staffing-log.json` is an object
  `{"matches": [...]}`; `projects-staff` appends run records to its `matches[]`
  array. Also holds `staffing-recommendations.json` — the last-run staffing
  scorer output snapshot (overwritten each run, **not** an append-only log) that
  the backfilling recommender and dashboard read.

## Conventions

- **Scripts return JSON** `{"success": bool, "data": {...}, "error": "string"}`
  and are stdlib-only (bash + python3, no pip). See `scripts/portfolio-init.sh`.
- **Idempotency keys on the manifest**, not the bare directory: an interrupted
  scaffold (dirs created, manifest never written) is repairable by re-running,
  and a completed re-run returns `{"success": false}` "already initialized" and
  exits 0 without overwriting anything.
- **Manifest written last** so its existence is a reliable "fully initialized"
  marker.
- **Domain-prefixed skill names** — generic names (`setup`, `dashboard`,
  `resume`) must carry the `projects-` prefix per repo convention (enforced by
  `cogni-workspace/scripts/check-skill-names.sh`).

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| _(none yet)_ | — | Cross-plugin bridges to cogni-consult and cogni-portfolio are planned as later roadmap children. |
