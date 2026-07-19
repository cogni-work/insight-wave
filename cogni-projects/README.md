# cogni-projects

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

Partner project-portfolio steering for consulting firms on Claude Code. cogni-projects gives partners one place to model consultants, projects, and staffing — so they can match the right people to the right work by availability, profile fit, and strategic impact. The portfolio scaffold, entity authoring, the staffing match engine, and a read-only partner-meeting dashboard have shipped; the backfilling recommender arrives in a later release.

## Why this exists

Consulting partners steer a portfolio of projects and people with spreadsheets and memory. Who is rolling off next month? Who fits this mandate? Which assignment moves the firm's strategy forward? Those questions have no shared home, so staffing decisions are ad hoc and hard to defend.

| Problem | Consequence |
|---------|-------------|
| No shared model of consultants, projects, and assignments | Staffing lives in scattered spreadsheets and partners' heads |
| Availability and fit are judged by recall | The best match is missed; benched people are overlooked |
| Strategic impact is not weighed against availability | Staffing optimizes utilization, not firm strategy |

## What it is

cogni-projects is a Claude Code plugin that holds a **self-contained project portfolio**: a directory of consultants, projects, and assignments rooted by a single manifest. It is the 14th plugin in the insight-wave ecosystem and the home for partner-facing portfolio steering.

It provides the `projects-setup` skill that scaffolds a portfolio directory, the `projects-entities` skill that authors and registers validated consultant/project/assignment records, the `projects-staff` staffing match engine that ranks candidate consultants per open role, and the read-only `projects-dashboard` skill that renders a partner-meeting portfolio snapshot. Backfilling builds on top of these.

## What it does

- **projects-setup** — initialize a new portfolio directory (`cogni-projects/<portfolio-slug>/`) with a root manifest and metadata logs. Idempotent: re-running never overwrites an existing portfolio.
- **projects-entities** — author one consultant, project, or assignment record and register it in the portfolio manifest, with structural validation.
- **projects-staff** — rank candidate consultants for every open project role on availability, profile fit, and strategic impact, and write a staffing-recommendations artifact.
- **projects-dashboard** — render a read-only partner-meeting snapshot of the portfolio: staffing coverage per project, at-risk projects, and portfolio value by strategic impact.

_More skills (backfilling recommender) land in later roadmap releases._

## What it means for you

You get one durable, browsable home for your project portfolio — the foundation every staffing and steering capability writes into. Author your consultants and projects, then run the staffing engine to get a defensible ranked shortlist for each open role, then render a partner-meeting dashboard over it; later backfilling plugs into the same directory as it ships.

## Installation

Install the insight-wave marketplace, then enable `cogni-projects` from the plugin list. The plugin follows the standard Claude Code plugin layout and requires no external dependencies.

## Quick start

```
/cogni-projects:projects-setup
```

Answer the two prompts (portfolio name and slug) and cogni-projects scaffolds the portfolio directory.

## Try it

Initialize a demo portfolio:

```
/cogni-projects:projects-setup
```

Name it "Demo Advisory", accept the derived slug `demo-advisory`, and confirm. You will get a `cogni-projects/demo-advisory/` directory with a `projects-portfolio.json` manifest and a `.metadata/` log directory. Run it again — it reports the portfolio is already initialized and changes nothing.

## Data model

A portfolio is one directory:

```
cogni-projects/<portfolio-slug>/
├── projects-portfolio.json    Root manifest (identity + consultants/projects/assignments lists)
├── consultants/               Consultant entity records
├── projects/                  Project entity records
├── assignments/               Assignment records
└── .metadata/                 Append-only logs (execution, staffing, decisions)
```

The manifest holds portfolio identity (`slug`, `name`, `language`, timestamps) plus the `consultants[]`, `projects[]`, and `assignments[]` lists that later skills populate.

## How it works

`projects-setup` gathers the portfolio name and slug, confirms the target directory, then runs `scripts/portfolio-init.sh` — a stdlib-only scaffolder that creates the directory skeleton and writes the `projects-portfolio.json` manifest last, so the manifest's existence marks a completed init. Re-running is safe: the script detects the manifest and returns a clean "already initialized" no-op without overwriting anything.

## Components

| Type | Name | Purpose |
|------|------|---------|
| Skill | `projects-setup` | Initialize a portfolio directory |
| Skill | `projects-entities` | Author + register a consultant/project/assignment record |
| Skill | `projects-staff` | Rank candidate consultants per open project role |
| Skill | `projects-dashboard` | Render a read-only partner-meeting portfolio snapshot |
| Script | `portfolio-init.sh` | Idempotent portfolio scaffolder |
| Script | `validate-entities.py` | Entity frontmatter validator |
| Script | `register-entity.py` | Slug-keyed manifest upsert + execution-log append |
| Script | `staffing-score.py` | Deterministic staffing scorer (availability/fit/impact) |
| Script | `render-dashboard.py` | Render the portfolio dashboard HTML from entity data |

## Architecture

cogni-projects is standalone at this stage. Its portfolio directory is the shared substrate for its skills (entity authoring, staffing match, dashboard) and for later ones (backfilling), and for planned cross-plugin bridges to cogni-consult and cogni-portfolio.

## Dependencies

None. Later roadmap children introduce optional bridges to other insight-wave plugins.

## Custom development

The plugin follows the insight-wave conventions documented in `CLAUDE.md`: scripts return `{"success", "data", "error"}` JSON and are stdlib-only; skill names carry the `projects-` domain prefix; the portfolio manifest is the source of truth. Extend it by adding skills under `skills/` and scripts under `scripts/`.

## License

[Apache-2.0](../LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
