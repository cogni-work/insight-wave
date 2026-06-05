---
name: knowledge-dashboard
description: "Render an HTML dashboard for a bound cogni-knowledge base — dispatches cogni-wiki:wiki-dashboard against the bound wiki and writes a knowledge-overlay.md sidecar that lists deposited research projects and the latest lint-audit claim_drift count. Use this skill whenever the user says 'show the dashboard for my <slug> base', 'knowledge dashboard', 'visualize my eu-ai-act knowledge base', 'render the knowledge base as HTML', 'knowledge-dashboard <slug>'. The sidecar makes the binding's contribution visible alongside the wiki's own dashboard."
allowed-tools: Read, Write, Bash, Glob, Skill
---

# Knowledge Dashboard

Render a self-contained HTML dashboard for a bound cogni-knowledge base. This skill is a thin composition over `cogni-wiki:wiki-dashboard` — it dispatches the upstream dashboard against the bound wiki, then writes one extra markdown file (`knowledge-overlay.md`) that surfaces what `binding.json` knows but `wiki-dashboard` does not: which research projects have contributed, and what the latest lint audit said about claim drift.

The cogni-knowledge value-add over a raw `cogni-wiki:wiki-dashboard` dispatch is:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user.
2. **Knowledge overlay sidecar** — a markdown file co-located with `wiki-dashboard.html` that captures the binding view: a deposited-projects table with per-project inverted-pipeline depth (sub-questions, fetched/unavailable, distilled concepts + claim-dedup ratio, verifier verdicts), a knowledge-base-global fetch-cache health block, and the latest lint-audit summary.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary — this skill writes only one file (`knowledge-overlay.md`); everything else is the upstream dashboard's responsibility.

## When to run

- User asks for a dashboard or HTML view of a bound knowledge base
- After several pipeline deposits, to see the shape of the accumulated wiki
- Before sharing a knowledge base with a colleague — the dashboard + overlay are both single files

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`. Direct wiki users without a binding should run `cogni-wiki:wiki-dashboard` directly.
- The wiki is empty — `cogni-wiki:wiki-dashboard` already refuses; the overlay still renders honestly with zero deposits.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `cogni-knowledge/<knowledge-slug>/` (relative to the current working directory). |
| `--graph` | No | Pass-through to `cogni-wiki:wiki-dashboard --graph`. Values: `no` (default) / `pass1` / `yes`. |
| `--open` | No | Pass-through to `cogni-wiki:wiki-dashboard --open`. Values: `yes` / `no` (default). |

## Workflow

### 0. Pre-flight

**Required plugins.** This skill dispatches `cogni-wiki:wiki-dashboard` and reads the bound wiki + the inverted-pipeline manifests — it never reaches cogni-research, so it probes only `cogni-wiki` (cogni-research is 0% of the runtime path). Abort cleanly here rather than letting the downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge requires `cogni-wiki` to be installed.
> Install it via the marketplace, then retry.

Then continue with the binding-resolution checks:

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract `wiki_path`, `knowledge_slug`, `knowledge_title`, `research_projects[]`, `created` from the binding, plus the charter (`binding.get("charter", {}).get("domain"/"audience"/"scope", "")`). Validate `binding.knowledge_slug == --knowledge-slug`. The charter `.get` chain falls through to `""` on a pre-0.1.4 binding (read-only, fail-soft).

   Then read the **still-open** seed-theme backlog (the seed themes *minus* the ones already researched) via the `themes` subcommand — don't read `open_themes[]` from the raw binding, because a theme that has since been researched still lives there (it is write-once-at-init); `themes` partitions it against `covered_themes[]` at read time:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py themes \
       --knowledge-root <knowledge_root>
   ```
   Capture `open_active` (still-open seeds; researched seeds already dropped off). This is read-only and fail-soft (a structurally-invalid / pre-0.1.4 binding returns `open_active: []`, `success: true`).

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort.

### 1. Dispatch `cogni-wiki:wiki-dashboard`

```
Skill("cogni-wiki:wiki-dashboard",
      args="--wiki-root <wiki_path> [--open <val>] [--graph <val>]")
```

`wiki-dashboard` accepts `--wiki-root` (see `cogni-wiki/skills/wiki-dashboard/SKILL.md:28`). Forward `--graph` and `--open` only if the caller passed them — let the upstream defaults apply otherwise.

If the upstream dispatch fails, surface its error verbatim and stop. Do NOT write the overlay sidecar — a half-rendered dashboard view is worse than none.

### 2. Compose the knowledge overlay sidecar

Write `<wiki_path>/knowledge-overlay.md` (overwrite on rerun — the contents are deterministic from the binding + latest lint audit, so re-running produces identical bytes if nothing has changed).

The overlay is co-located with `wiki-dashboard.html` so the user opens both from the same directory. In the default `knowledge-setup` layout, `<knowledge_root>` and `<wiki_path>` are the same directory (see `knowledge-setup/SKILL.md` §"Edge cases"), so the sidecar also lives at the knowledge-base root.

For each entry in `research_projects[]`, read its inverted-pipeline depth (one call per project, keyed off the entry's `project_path`):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py project \
    --project-path <research_projects[i].project_path>
```

Capture `sub_questions`, `fetched`, `unavailable`, the distill fields `concepts_total` / `claims_attached` / `claims_deduped`, and `verify_counts.{verbatim,paraphrase,unsupported}`. Legacy deposits (cogni-research layout, no `.metadata/` manifests) return zeros + `phase_reached: "none"` — render those cells as `—` so the table reads honestly rather than implying a zero-claim pipeline ran. A deposit that ran before the distill phase existed (or skipped the optional distill) returns `concepts_total: 0` — render the concepts/deduped cells as `—`. If a project entry has no `project_path` (legacy binding), skip the per-project read and render `—`.

Then read the knowledge-base-global fetch-cache health once:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health \
    --knowledge-root <knowledge_root>
```

Capture `entries`, `negative_ratio`, `oldest_age_days`, `max_age_days`, `verdict`.

Then read the curated-portal lead-in staleness signal once. `knowledge-finalize`'s portal auto-refresh stamps each engine-owned per-theme lead-in with a `bullets:<N>` count; this read-only check reports themes whose live bullet count has since drifted more than a small threshold (the `threshold` field, default 2) past the stamp (the lead-in prose no longer reflects what accumulated under it). Pure observability — it never triggers a refresh:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py portal-staleness \
    --wiki-root <wiki_path>
```

Capture `stale_count` and `stale_themes[]`. This is **knowledge-base-global** (one portal per bound wiki), so it surfaces once in the `## Pipeline health` block — never as a per-project column.

Then read the wiki-global live-source resweep cadence once. `cogni-wiki:wiki-claims-resweep` writes `<wiki_path>/.cogni-wiki/last-resweep.json` (lock-wrapped, single-writer-per-wiki); the dashboard only reads it. Absent file → render `never`, no error:

```
python3 -c '
import json, datetime as dt
from pathlib import Path
p = Path("<wiki_path>") / ".cogni-wiki" / "last-resweep.json"
if not p.is_file():
    print("never")
else:
    d = json.loads(p.read_text(encoding="utf-8"))
    sd = d.get("sweep_date", "")
    try:
        age = (dt.date.today() - dt.date.fromisoformat(sd)).days
        print(sd + "|" + str(age))
    except Exception:
        print(sd + "|-")
'
```

Parse the output: a bare `never` line means no resweep has ever run; otherwise split the single line on `|` into `LAST_RESWEEP_DATE` + `LAST_RESWEEP_AGE_DAYS` (age is `-` when `sweep_date` is unparseable). This is **wiki-global** (one resweep applies to the whole bound wiki, not per-project), so it surfaces in the `## Claim verification scope` block + the short summary — never as a per-project table column.

Contents:

```markdown
# Knowledge overlay — <knowledge_title> (<knowledge_slug>)

Created <created>. Wiki: <wiki_path>.

(When `charter.domain` is non-empty — schema 0.1.4:)
**Charter.** <charter.domain> · for <charter.audience> · scope <charter.scope>.

(When `open_active` (from the `themes` subcommand) is non-empty — the still-open seeds, researched ones already removed; omit the line entirely when `open_active` is empty even if the raw `open_themes[]` is non-empty, because every seed has since been researched:)
**Seed themes.** <open_active joined by ' · '>.

## Deposited research projects

| slug | deposited_at | report_source | sub_questions | fetched | unavailable | concepts | claims deduped | verbatim | paraphrase | unsupported |
|------|--------------|---------------|---------------|---------|-------------|----------|----------------|----------|------------|-------------|
| <slug-1> | <YYYY-MM-DD> | <web|local|wiki|hybrid> | <n or —> | <n or —> | <n or —> | <concepts_total or —> | <claims_deduped>/<claims_attached> | <n or —> | <n or —> | <n or —> |
| ...      | ...          | ...                     | ...      | ...      | ...      | ...      | ...      | ...      | ...      | ...      |

(Or, if `research_projects[]` is empty:)
> No research projects deposited yet — run the inverted pipeline (`knowledge-plan` → … → `knowledge-finalize`) to add the first.

Sort rows by `deposited_at` descending (newest first).

## Pipeline health

Fetch-cache (**knowledge-base-global** — one shared cache across all projects, not per-project):
<entries> sources cached · <negative_ratio as %> unavailable · oldest entry <oldest_age_days>d (max <max_age_days>d) · verdict: <verdict>

(If `cache-health` reports `verdict: empty`:)
No fetched sources yet — run `knowledge-fetch` to populate the cache.

(Only when `stale_count > 0` — render nothing on zero drift so a healthy base stays silent:)
Stale portal lead-ins: <stale_count> theme(s) — <stale_themes[].theme, first 5 joined by ', ', then '…and <N> more' when there are over 5> drifted more than `<threshold>` bullets past their stamped count. Re-run `knowledge-finalize --apply-portal` (or `knowledge-refresh --mode push`) to refresh the lead-ins.

## Claim verification scope

**Verification semantics** — every citation in every synthesis below was scored as `verbatim` / `paraphrase` / `synthesis` / `unsupported` against the cited page's `pre_extracted_claims:` block, extracted from the source body **at ingest time**. This is the inverted pipeline's structural cost win versus cogni-claims (<5 min per finalize vs ~25 min): the check is **zero-network** — **no live-source re-fetch ever happens at verify time** (`references/inverted-pipeline.md` Phase 6; `agents/wiki-verifier.md` §"What this agent does NOT do"). So "verified" here means **citation-consistent, not ground-truthed**. Two corollaries:

1. *Extraction fidelity is unchecked.* An extracted claim that distorts the source body but is locatable at its declared `excerpt_position` passes ingest and propagates as evidence.
2. *Sources drift between ingest and read.* URLs 404, paywalls appear, content gets rewritten — nothing re-checks the live URL after ingest.

To re-check the bound wiki against live URLs: `/cogni-knowledge:knowledge-refresh --resweep` (opt-in; delegates to `cogni-wiki:wiki-claims-resweep`, which WebFetches each cited URL once and LLM-compares the live source). Last live-source resweep on this base: `<LAST_RESWEEP_DATE>` (`<LAST_RESWEEP_AGE_DAYS>`d ago) — or `never` when `last-resweep.json` is absent.

(Best-effort lint summary from the freshest audit file under `<wiki_path>/wiki/audits/lint-*.md`. If audit files exist, render:)
Latest lint audit (<audit-filename>): <N> claim_drift findings.

(If no audit files exist:)
No lint audits yet — run `cogni-wiki:wiki-lint` to populate.
```

The `## Pipeline health` block reports the shared fetch-cache; the per-project columns above report each deposit's own pipeline counts. Label the cache block **knowledge-base-global** explicitly so the user does not misread the shared cache as per-project state.

Counting `claim_drift` findings: pick the freshest audit (`ls -1 <wiki_path>/wiki/audits/lint-*.md | tail -1`), then `grep -c claim_drift <audit>`. Line-count, not body-read — audits can run long and the count is all the overlay needs. The warning-class literal is documented at `cogni-wiki/skills/wiki-lint/SKILL.md`. Section is never absent; the empty-state line is informative.

### 3. Print a short summary

≤ 5 lines:

- `wiki-dashboard.html` → `<wiki_path>/wiki-dashboard.html`
- `knowledge-overlay.md` → `<wiki_path>/knowledge-overlay.md`
- Deposited projects: `<count>`
- Fetch-cache: `<entries>` cached, verdict `<verdict>` (knowledge-base-global)
- Latest claim_drift findings: `<N>` (or `no lint audits yet`)
- Last live-source resweep: `<LAST_RESWEEP_DATE>` (`<LAST_RESWEEP_AGE_DAYS>`d ago) | `never`. Run `/cogni-knowledge:knowledge-refresh --resweep` to refresh ground-truth.
- Open both with `open <wiki_path>/wiki-dashboard.html` and `open <wiki_path>/knowledge-overlay.md`

## Edge cases

- **Empty `research_projects[]`.** Section 2's table is replaced with the empty-state line; the rest of the overlay renders normally.
- **Legacy deposit (no `.metadata/` manifests).** `pipeline-summary.py project` returns zeros + `phase_reached: "none"`; render the per-project pipeline columns as `—` rather than `0` so the row reads as "no inverted-pipeline data" rather than "ran with zero results".
- **`pipeline-summary.py cache-health` fails.** Render the `## Pipeline health` block with a one-line "fetch-cache health unavailable" note and keep going — the rest of the overlay is still useful.
- **`pipeline-summary.py portal-staleness` fails.** Omit the stale-lead-ins line entirely and keep going — the signal is purely advisory, and its absence reads the same as a zero-drift base (both render nothing). The script is already fail-soft on a missing/unreadable `index.md` (returns `stale_count: 0`), so a non-zero exit here means a genuine script error, not an empty portal.
- **No `wiki/audits/` directory.** Treat as "no lint audits yet" — section 2 still renders.
- **Audit file present but no `claim_drift` markers.** Report `0 claim_drift findings`.
- **Missing `<wiki_path>/.cogni-wiki/last-resweep.json` (no resweep ever run on this base).** Treat as `never`; the `## Claim verification scope` block + short summary still render normally with the `--resweep` suggestion.
- **Upstream `wiki-dashboard` fails after partial render.** Step 1 already aborted; the overlay is not written.

## Out of scope

- **Running `wiki-lint` from this skill.** The verification-scope block reads whatever audits already exist on disk. Running lint is a separate user-driven action (it costs tokens; the dashboard is meant to be cheap and frequent).
- **Dispatching `wiki-claims-resweep` itself.** Resweep is expensive (WebFetch per cited URL). The dashboard is meant to be cheap and frequent; it only reads `last-resweep.json` and surfaces the cadence. The resweep is opt-in via `/cogni-knowledge:knowledge-refresh --resweep`.
- **Injecting the binding overlay into `wiki-dashboard.html` itself.** The upstream dashboard is wiki-general; layering knowledge-base-specific content into its HTML would couple the two. The sidecar approach keeps the contracts clean.
- **Modifying the binding.** Read-only by design.
- **Writing anywhere outside `<wiki_path>/`.** The overlay is the only file this skill writes, and it lives inside the bound wiki's directory.

## Output

- A single HTML file at `<wiki_path>/wiki-dashboard.html` (rendered by `cogni-wiki:wiki-dashboard`).
- When `--graph` ∈ {`pass1`, `yes`}: a second HTML at `<wiki_path>/wiki-graph.html` (rendered by `cogni-wiki:wiki-dashboard`).
- A markdown sidecar at `<wiki_path>/knowledge-overlay.md` (written by this skill).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary and §"How `Skill(...)` blocks are written"
- `cogni-wiki:wiki-dashboard` SKILL.md — the upstream contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py --help` — per-project depth (`project`) + fetch-cache health (`cache-health`) + portal-lead-in drift (`portal-staleness`)
- `cogni-wiki:wiki-claims-resweep` SKILL.md — writes `<wiki_path>/.cogni-wiki/last-resweep.json` (the resweep cadence pointer this overlay reads)
