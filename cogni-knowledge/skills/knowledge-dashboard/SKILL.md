---
name: knowledge-dashboard
description: "Render an HTML dashboard for a bound cogni-knowledge base — runs the vendored wiki-dashboard scripts (render_dashboard.py + build_graph.py) natively against the bound wiki and writes a knowledge-overlay.md sidecar that lists deposited research projects and the latest lint-audit claim_drift count. Use this skill whenever the user says 'show the dashboard for my <slug> base', 'knowledge dashboard', 'visualize my eu-ai-act knowledge base', 'render the knowledge base as HTML', 'knowledge-dashboard <slug>'. The sidecar makes the binding's contribution visible alongside the wiki's own dashboard."
allowed-tools: Read, Write, Bash, Glob
---

# Knowledge Dashboard

Render a self-contained HTML dashboard for a bound cogni-knowledge base. This skill runs the **vendored** `render_dashboard.py` (and, for `--graph`, `build_graph.py`) from `scripts/vendor/cogni-wiki/skills/wiki-dashboard/scripts/` natively against the bound wiki — resolved vendored-first via `resolve_wiki_scripts()`, the same posture `knowledge-ingest` uses for its engine helpers — then writes one extra markdown file (`knowledge-overlay.md`) that surfaces what `binding.json` knows but the bare wiki dashboard does not: which research projects have contributed, and what the latest lint audit said about claim drift. A standalone Karpathy base renders its dashboard with no `cogni-wiki` plugin installed.

The cogni-knowledge value-add over a raw wiki-dashboard render is:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user.
2. **Knowledge overlay sidecar** — a markdown file co-located with `wiki-dashboard.html` that captures the binding view: a deposited-projects table with per-project inverted-pipeline depth (sub-questions, fetched/unavailable, distilled concepts + claim-dedup ratio, verifier verdicts), a knowledge-base-global fetch-cache health block, and the latest lint-audit summary.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the boundary — this skill writes only one file (`knowledge-overlay.md`); the HTML render (`wiki-dashboard.html` / `wiki-graph.html`) is the vendored dashboard scripts' responsibility.

## When to run

- User asks for a dashboard or HTML view of a bound knowledge base
- After several pipeline deposits, to see the shape of the accumulated wiki
- Before sharing a knowledge base with a colleague — the dashboard + overlay are both single files

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`. (A raw wiki with no binding is rendered by `render_dashboard.py` directly; this skill adds the binding overlay.)
- The wiki is empty — `render_dashboard.py` still renders an honest empty dashboard, and the overlay renders honestly with zero deposits.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `cogni-knowledge/<knowledge-slug>/` (relative to the current working directory). |
| `--graph` | No | Controls whether the vendored `build_graph.py` runs alongside `render_dashboard.py`. Values: `no` (default, no graph) / `pass1` (structural graph, no LLM) / `yes` (two-pass graph with the LLM relatedness loop). |
| `--open` | No | Print the `file://` URL(s) of the rendered HTML so the user can open them. Values: `yes` / `no` (default). |

## Workflow

### 0. Pre-flight

**Required engine.** This skill resolves the wiki-dashboard scripts **vendored-first** — cogni-knowledge ships a byte-identical copy of the engine in-tree under `scripts/vendor/cogni-wiki/`, so a bound base renders its dashboard without cogni-wiki installed and this skill no longer dispatches `cogni-wiki:wiki-dashboard`. The `cogni-wiki` install is only a fallback layout. Probe both so the skill aborts cleanly here rather than failing mid-render:

```
# vendored-first: the in-tree dashboard scripts are self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-dashboard/scripts" && WIKI_OK=yes || WIKI_OK=no

# fallback: an installed cogni-wiki sibling / marketplace cache (legacy layout)
if [ "$WIKI_OK" = "no" ]; then
  probe_plugin() {
    local plugin="$1" skill="$2"
    test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
    for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
      [ -f "$d" ] && return 0
    done
    return 1
  }
  probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
fi
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge's vendored wiki-dashboard scripts are missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

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

### 1. Render the dashboard natively on the vendored scripts

Resolve the vendored `wiki-dashboard` scripts dir vendored-first (the same `resolve_wiki_scripts` posture `knowledge-ingest` uses), then invoke `render_dashboard.py` directly — no `Skill` dispatch:

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_DASHBOARD_SCRIPTS=$(resolve_wiki_scripts wiki-dashboard render_dashboard.py) \
  || abort "cogni-wiki wiki-dashboard scripts not found (vendored copy missing)"
```

**1a. Render the dashboard HTML.** `render_dashboard.py` takes `--wiki-root` (required; defaults `--output` to `<wiki_path>/wiki-dashboard.html`) and resolves `_wikilib` itself (no `--wiki-scripts-dir` needed):

```bash
python3 "${WIKI_DASHBOARD_SCRIPTS}/render_dashboard.py" --wiki-root "<wiki_path>"
```

Parse the JSON envelope. On `success: false` (or a non-zero exit — e.g. `<wiki_path>/.cogni-wiki/config.json` absent), surface the `error` verbatim and **stop**. Do NOT write the overlay sidecar — a half-rendered dashboard view is worse than none.

**1b. Build the graph (only when `--graph` ∈ {`pass1`, `yes`}).** The graph layer is the separate vendored `build_graph.py` (`--wiki-root` required; writes `<wiki_path>/wiki-graph.html`). `render_dashboard.py` does NOT invoke it — this skill orchestrates it:

- `--graph pass1` — structural graph only, no LLM:
  ```bash
  python3 "${WIKI_DASHBOARD_SCRIPTS}/build_graph.py" --mode build --wiki-root "<wiki_path>"
  ```
- `--graph yes` — two-pass graph with the relatedness loop (reproduces the upstream pass-2 orchestration inline):
  1. Enumerate candidate page pairs:
     ```bash
     python3 "${WIKI_DASHBOARD_SCRIPTS}/build_graph.py" --mode enumerate-candidates --wiki-root "<wiki_path>" --limit 50
     ```
  2. For each emitted candidate `{pair_id, slug_a, slug_b}`, judge relatedness yourself (read the two pages) and record the verdict:
     ```bash
     python3 "${WIKI_DASHBOARD_SCRIPTS}/build_graph.py" --mode record-judgement --wiki-root "<wiki_path>" \
         --pair-id "<pair_id>" --slug-a "<slug_a>" --slug-b "<slug_b>" \
         --judgement related|unrelated --confidence <0.0-1.0> --relationship "<short phrase>"
     ```
  3. Re-render the graph with the recorded judgements:
     ```bash
     python3 "${WIKI_DASHBOARD_SCRIPTS}/build_graph.py" --mode build --wiki-root "<wiki_path>"
     ```

  Judgements are cached at `<wiki_path>/.cogni-wiki/graph-cache/`, so a re-run only judges new pairs. If `build_graph.py` fails, surface the error and skip the graph — the dashboard HTML from 1a still stands; do not abort the overlay.

**1c. `--open`.** When `--open yes`, after the renders print the `file://` URL(s) so the user can open them (`file://<wiki_path>/wiki-dashboard.html`, and `…/wiki-graph.html` when a graph was built). This is a local print — the scripts do not open a browser themselves.

### 2. Compose the knowledge overlay sidecar

Write `<wiki_path>/knowledge-overlay.md` (overwrite on rerun — the contents are deterministic from the binding + latest lint audit, so re-running produces identical bytes if nothing has changed).

The overlay is co-located with `wiki-dashboard.html` so the user opens both from the same directory. In the default `knowledge-setup` layout, `<knowledge_root>` and `<wiki_path>` are the same directory (see `knowledge-setup/SKILL.md` §"Edge cases"), so the sidecar also lives at the knowledge-base root.

For each entry in `research_projects[]`, read its inverted-pipeline depth (one call per project, keyed off the entry's `project_path`):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py project \
    --project-path <research_projects[i].project_path>
```

Capture `sub_questions`, `fetched`, `unavailable`, the distill fields `concepts_total` / `claims_attached` / `claims_deduped`, `verify_counts.{verbatim,paraphrase,unsupported}`, and `grounding_rate` (the latest verify round's draft↔excerpt grounding rate, additive at verify schema 0.1.1; `null` on a legacy 0.1.0 verify file or when nothing was scorable). Legacy deposits (cogni-research layout, no `.metadata/` manifests) return zeros + `phase_reached: "none"` — render those cells as `—` so the table reads honestly rather than implying a zero-claim pipeline ran. A deposit that ran before the distill phase existed (or skipped the optional distill) returns `concepts_total: 0` — render the concepts/deduped cells as `—`. If a project entry has no `project_path` (legacy binding), skip the per-project read and render `—`.

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

| slug | deposited_at | report_source | sub_questions | fetched | unavailable | concepts | claims deduped | verbatim | paraphrase | unsupported | grounding |
|------|--------------|---------------|---------------|---------|-------------|----------|----------------|----------|------------|-------------|-----------|
| <slug-1> | <YYYY-MM-DD> | <web|local|wiki|hybrid> | <n or —> | <n or —> | <n or —> | <concepts_total or —> | <claims_deduped>/<claims_attached> | <n or —> | <n or —> | <n or —> | <pct% or —> |
| ...      | ...          | ...                     | ...      | ...      | ...      | ...      | ...      | ...      | ...      | ...      | ...      | ...      |

The `grounding` cell renders `round(100 * grounding_rate, 1)%` (the latest verify round's draft↔excerpt grounding rate); render `—` when `grounding_rate` is `null` (legacy 0.1.0 verify file, no scorable citations, or a deposit that never reached verify).

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

(When any deposit's latest verify carries a `grounding_rate`, render one line — the headline draft↔excerpt grounding signal, how many scorable citations actually ground in the excerpt they cite, the verify-phase analog of the ingest-time excerpt-presence rate:)
Draft↔excerpt grounding rate (latest verify per project): <slug-1> <pct>% · <slug-2> <pct>% · … — `—` for any deposit whose verify file predates the metric or had no scorable citations.

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
- **`render_dashboard.py` fails (e.g. missing `.cogni-wiki/config.json`).** Step 1a already aborted; the overlay is not written. (A `build_graph.py` failure under `--graph` is non-fatal — the dashboard HTML stands and the overlay still writes.)

## Out of scope

- **Running `wiki-lint` from this skill.** The verification-scope block reads whatever audits already exist on disk. Running lint is a separate user-driven action (it costs tokens; the dashboard is meant to be cheap and frequent).
- **Dispatching `wiki-claims-resweep` itself.** Resweep is expensive (WebFetch per cited URL). The dashboard is meant to be cheap and frequent; it only reads `last-resweep.json` and surfaces the cadence. The resweep is opt-in via `/cogni-knowledge:knowledge-refresh --resweep`.
- **Injecting the binding overlay into `wiki-dashboard.html` itself.** The vendored dashboard render is wiki-general; layering knowledge-base-specific content into its HTML would couple the two. The sidecar approach keeps the contracts clean.
- **Modifying the binding.** Read-only by design.
- **Writing anywhere outside `<wiki_path>/`.** The overlay is the only file this skill writes, and it lives inside the bound wiki's directory.

## Output

- A single HTML file at `<wiki_path>/wiki-dashboard.html` (rendered by the vendored `render_dashboard.py`).
- When `--graph` ∈ {`pass1`, `yes`}: a second HTML at `<wiki_path>/wiki-graph.html` (rendered by the vendored `build_graph.py`).
- A markdown sidecar at `<wiki_path>/knowledge-overlay.md` (written by this skill).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-dashboard/scripts/render_dashboard.py` — the vendored dashboard renderer (`--wiki-root`, `--output`)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-dashboard/scripts/build_graph.py` — the vendored graph layer (`--mode build|enumerate-candidates|record-judgement`)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py --help` — per-project depth (`project`) + fetch-cache health (`cache-health`) + portal-lead-in drift (`portal-staleness`)
- `cogni-wiki:wiki-claims-resweep` SKILL.md — writes `<wiki_path>/.cogni-wiki/last-resweep.json` (the resweep cadence pointer this overlay reads)
