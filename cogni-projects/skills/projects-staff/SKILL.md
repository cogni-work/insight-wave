---
name: projects-staff
description: |
  This skill should be used when a partner wants a ranked shortlist of
  consultants for the open roles on a cogni-projects portfolio — the staffing
  match engine. Trigger on: "staff this project", "who should I put on",
  "recommend consultants for", "staffing recommendations", "match consultants to
  roles", "rank candidates for the open roles", "who is available for", "build a
  staffing shortlist", or any request to turn a cogni-projects portfolio's
  consultants and projects into a ranked candidate list per open role — even if
  the user does not name the portfolio.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Projects Staff

Turn a cogni-projects portfolio into a ranked staffing shortlist: for every open
role on every project, a list of candidate consultants scored on three visible
factors — **availability**, **profile fit**, and **strategic impact**. It reads
the consultant, project, and assignment records authored by `projects-entities`
and produces the recommendation a partner defends a staffing call with.

The ranking is computed by a deterministic script — `scripts/staffing-score.py`
— so the same portfolio always yields the same shortlist. The skill's job is to
locate the portfolio, run the scorer, and render its JSON into a human-readable
recommendation artifact.

## Core concept

For each project that carries `open_roles`, the scorer ranks candidate
consultants per role on three sub-scores in `[0,1]`, all shown separately plus a
combined score:

- **availability** — how well the consultant's `available_from`/`available_until`
  window overlaps the project's `start_date`/`end_date`, weighted by free
  capacity (`allocation_pct` headroom). A consultant whose window does **not**
  overlap the project window is excluded from that project's ranking entirely.
- **profile fit** — how well the consultant's `skills` match the open role label,
  blended with a seniority prior.
- **strategic impact** — the project's `strategic_impact` (1–5) normalized, so a
  firm-defining project pulls its shortlist up over a purely tactical one.

The full field contract these read lives in
[`../../references/data-model.md`](../../references/data-model.md). The scorer
returns the repo-standard `{"success", "data", "error"}` JSON and never bakes a
wall-clock value into a score, so its output is reproducible.

## Workflow

### Step 1: Locate the target portfolio

Find the portfolio directory the user means. If they name a slug, use
`cogni-projects/<portfolio-slug>/`. Otherwise glob
`cogni-projects/*/projects-portfolio.json` and, when more than one portfolio
exists, ask which one. If none exists, tell the user to run
`/cogni-projects:projects-setup` first and author entities with
`/cogni-projects:projects-entities` — this skill scores an existing portfolio, it
does not scaffold or populate one.

A portfolio with zero projects carrying `open_roles`, or zero consultants, is a
valid but empty input: the scorer returns `success: true` with an empty ranking.
Say so rather than treating it as an error — the fix is to author more entities,
not to debug the skill.

### Step 2: Run the scorer

Run `staffing-score.py` against the portfolio directory and capture its JSON:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/staffing-score.py" "cogni-projects/<portfolio-slug>"
```

It returns `{"success", "data", "error"}` (exit 0 ok / 1 domain failure / 2
usage). On `success: false`, surface `error` to the user and stop — a domain
failure means the portfolio directory or its manifest is unreadable, which the
scorer will not paper over. On success, `data.projects[]` holds, per project, a
`open_roles[]` array where each role carries a `candidates[]` list already ranked
by combined score (best first) and an `excluded_count` of consultants dropped for
no availability overlap.

### Step 3: Write the staffing-recommendation artifact

Render the scorer JSON into a human-readable markdown artifact at
`cogni-projects/<portfolio-slug>/staffing-recommendations.md`, and write the raw
scorer JSON alongside it at
`cogni-projects/<portfolio-slug>/.metadata/staffing-recommendations.json` (the
machine-readable record the backfilling recommender and partner-meeting dashboard
later read).

The markdown artifact has one section per project, and within it one table per
open role. Show the three sub-scores **separately** — that per-factor breakdown
is the point of the engine (a partner needs it to defend the call), never collapse
it to a single opaque number:

```markdown
# Staffing recommendations — <portfolio name>

## <Project name> (`<project-slug>`) — strategic impact <n>/5

### Role: `<role>`

| Rank | Consultant | Availability | Profile fit | Strategic impact | Combined |
|------|-----------|-------------|-------------|------------------|----------|
| 1 | <name> (`<slug>`) | 0.84 | 0.53 | 0.75 | 0.71 |
| 2 | … | … | … | … | … |

_<excluded_count> consultant(s) excluded — no availability overlap with the
project window._
```

Preserve the scorer's ranking order — do not re-sort. When a role has zero
candidates (everyone excluded), say so under its heading instead of rendering an
empty table.

### Step 4: Append a run record to the staffing log

Append one entry to `cogni-projects/<portfolio-slug>/.metadata/staffing-log.json`
(create the file as a JSON array if it does not yet exist) recording this run —
the portfolio slug, the counts from `data` (`consultant_count`, `project_count`,
`ranked_candidate_count`), and the artifact path. This is the append-only audit
trail later skills and the dashboard scan; keep it a flat array of records.

### Step 5: Summarize

Report the artifact path, how many projects and open roles were scored, and the
top candidate for each open role (name + combined score). Keep it short. If any
role came back with everyone excluded, call that out — it usually means no
consultant's availability window overlaps that project, which is a portfolio-data
gap to fix with `/cogni-projects:projects-entities`, not a scoring bug.

## Notes

- **The scorer is the source of truth for ranking.** This skill renders and
  logs; it does not re-rank, re-weight, or filter the scorer's output. To change
  how candidates are scored, change `scripts/staffing-score.py`, not this skill.
- **Scripts return `{success, data, error}` JSON**, stdlib-only — no pip
  dependencies. `staffing-score.py` reuses `validate-entities.py`'s frontmatter
  parser rather than adding its own.
- **Availability is modeled from allocation-window attributes** on the consultant
  records (`available_from` / `available_until` / `allocation_pct`), not a
  separate entity — consistent with the data model.
- **Deterministic output.** Identical portfolio inputs always yield the same
  shortlist (ties break on the consultant slug), so a recommendation is
  reproducible and reviewable.
