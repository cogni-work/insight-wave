---
name: knowledge-resume
description: "Show status of a cogni-knowledge base — knowledge slug, bound wiki path, deposited research projects, wiki health verdict, and the recommended next action. Use this skill whenever the user says 'resume the knowledge base', 'knowledge resume', 'knowledge status', 'where was I with the eu-ai-act base', 'what's in my knowledge base', 'show me the knowledge base overview'. Proactively after a long gap between sessions, or right after knowledge-setup or a knowledge-finalize run."
allowed-tools: Read, Bash, Glob
---

# Knowledge Resume

Give the user a fast, grounded status view of a cogni-knowledge base so they know what is inside and what the right next action is. This skill is **read-only** with respect to the binding and the wiki — it never writes. The only side effect is that the native `health.py` invocation appends its health-check log line to `wiki/log.md` (the same side effect the old `cogni-wiki:wiki-resume` dispatch produced — unchanged).

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember the wiki-engine boundary — cogni-knowledge computes the wiki health verdict on the **vendored** wiki-health engine (resolved vendored-first), it does not dispatch `cogni-wiki:wiki-resume`.

## When to run

- User asks for status, overview, or "where was I" on a knowledge base
- User returns after a gap and wants orientation
- Right after `knowledge-setup` or a `knowledge-finalize` run finished, to confirm the deposit and suggest the next step
- Proactively when a session opens in a directory containing `.cogni-knowledge/binding.json`

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base to resume. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--verbose` | No | Includes the last 10 `wiki/log.md` entries verbatim (default: last 3). |

## Workflow

### 0. Pre-flight

**Required engine.** This skill computes the wiki health verdict on the **vendored** wiki-health engine — cogni-knowledge ships a byte-identical copy in-tree under `scripts/vendor/cogni-wiki/`, so a bound base shows its resume status without cogni-wiki installed and this skill no longer dispatches `cogni-wiki:wiki-resume`, mirroring the native posture of `knowledge-dashboard` and `knowledge-query`. It reads the inverted-pipeline manifests via `pipeline-summary.py` and never reaches cogni-research. The `cogni-wiki` install is only a fallback layout. Probe both so the skill aborts cleanly here rather than failing mid-skill:

```
# vendored-first: the in-tree wiki-health scripts are self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-health/scripts" && WIKI_OK=yes || WIKI_OK=no

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

> cogni-knowledge's vendored wiki-health scripts are missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

Resume is read-only with respect to disk; the vendored-first probe gives the user the same clean signal every other `knowledge-*` read/render skill emits. This probe is the early-abort gate only — Step 2's `resolve_wiki_scripts` is the authoritative resolver for the actual `health.py` path; keep the two vendored-first precedences in sync.

### 1. Resolve the knowledge root and read the binding

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`, `research_projects[]`, `created`, and the charter (`binding.get("charter", {}).get("domain"/"audience"/"scope", "")` — schema 0.1.4; the `.get` chain falls through to `""` on a pre-0.1.4 binding, read-only fail-soft). (The bound wiki's own slug, if needed for display, comes live from `<wiki_path>/.cogni-wiki/config.json` — never cached in the binding.)

   Then read the topic lineage for display via the `themes` subcommand (don't render `open_themes[]` from the raw binding — a researched seed is never pruned out of it; `themes` partitions it against `covered_themes[]` at read time):
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py themes \
       --knowledge-root <knowledge_root>
   ```
   Capture `open_active` (still-open seeds, researched ones already dropped) and `covered` (each `{label, question_slug}`, where `label` is already the `labels[0]`-with-`question_slug`-fallback render). Read-only and fail-soft (structurally-invalid / pre-0.1.4 binding → empty lists, `success: true`).

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

### 2. Compute the wiki status natively (vendored `health.py` + direct reads)

Resolve the vendored `wiki-health` scripts dir vendored-first (the same `resolve_wiki_scripts` posture `knowledge-dashboard` / `knowledge-ingest` use), then invoke `health.py` directly — no `Skill` dispatch:

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_HEALTH_SCRIPTS=$(resolve_wiki_scripts wiki-health health.py) \
  || abort "cogni-wiki wiki-health scripts not found (vendored copy missing)"
```

**2a. Health verdict.** Run the vendored `health.py` against the bound wiki (it resolves `_wikilib` itself; read-only apart from the health-check log line it appends — the same side effect the old dispatch produced):

```bash
python3 "${WIKI_HEALTH_SCRIPTS}/health.py" --wiki-root "<wiki_path>"
```

Parse the JSON envelope and capture `data.errors`, `data.warnings`, and `data.stats` (`entries_count_actual`, `entries_count_drift`, `claim_drift_count`). The one-line verdict for Step 3 is **OK** when `errors` is empty, else `N issues — <first error class(es)>`; surface `entries_count_drift` / `claim_drift_count` as warnings when non-zero. On `success: false` (e.g. `<wiki_path>/.cogni-wiki/config.json` absent), surface the error and still print the binding section per Edge cases.

**2b. Context brief + recent log (direct reads).** Read the wiki's own orientation surfaces directly — both fail-soft (a missing file is omitted, never an abort):

- `Read <wiki_path>/wiki/context_brief.md` (auto-rebuilt by ingest/finalize) for the one-paragraph summary.
- `Read <wiki_path>/wiki/log.md` for recent activity — show the **last 3** lines by default, the **last 10** when `--verbose` is set.
- Entry count comes from `<wiki_path>/.cogni-wiki/config.json` (`entries_count`), cross-checked against `data.stats.entries_count_actual` from 2a.

For each deposited project (cap at 5, newest first), read its inverted-pipeline depth so the summary shows how far each project got, not just that it exists:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py project \
    --project-path <research_projects[i].project_path>
```

Capture `sub_questions`, `fetched`, `phase_reached`, and the distill fields `concepts_total` / `claims_attached` / `claims_deduped`. Legacy deposits (no `.metadata/` manifests) return zeros + `phase_reached: "none"` — render their depth as `(legacy deposit)` rather than `0 sub-questions`. Then read the knowledge-base-global fetch-cache verdict once:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health \
    --knowledge-root <knowledge_root>
```

Capture `verdict` (and `entries`).

### 3. Compose the cogni-knowledge summary

Print a ≤ 12-line summary that layers the binding onto the wiki status:

- **Knowledge base.** `<knowledge_title>` (`<knowledge_slug>`), created `<created>`
- **Charter.** When `charter.domain` is non-empty (schema 0.1.4): `<charter.domain> · for <charter.audience> · scope <charter.scope>`. Omit the line entirely on a pre-0.1.4 / unframed base. When the charter is set, append a one-line read-only re-steer offer beneath it: *"Re-steering the base? Run `knowledge-setup --reframe --knowledge-slug <slug>`."* This is a **suggestion only** — resume stays read-only (the re-frame write lives in `knowledge-setup`, never here).
- **Wiki path.** `<wiki_path>` — wiki health verdict from Step 2a (one line: "OK" / "N issues — <first error class(es)>"; append a `· entries drift <±N>` / `· claim drift <N>` note when those stats are non-zero)
- **Deposited research projects.** `<count>` — one line per project (newest first, cap 5, "and N more" for the rest), each as: `<slug> — <sub_questions> sub-questions · <fetched> fetched · phase <phase_reached>` + ` · <concepts_total> concepts (<claims_deduped>/<claims_attached> claims deduped)` when `concepts_total > 0` (the Phase-4.5 distill compounding signal) + `· synthesis ✓` when the binding entry's `report_source == "wiki"` + ` (<deposited_at>)`. Legacy deposits show `<slug> — (legacy deposit) (<deposited_at>)`.
- **Pipeline status.** Knowledge-base-global fetch-cache (one shared cache across all projects): one line by `verdict` — `healthy` → `fetch-cache healthy (<entries> sources)`; `stale` → `fetch-cache stale — re-run knowledge-curate to re-fetch aged sources (or knowledge-refresh to re-run the pipeline on stale topics)`; `empty` → `fetch-cache empty — run knowledge-plan first`.
- **Topic lineage.** Use the `themes` subcommand output from Step 1. If `covered` or `open_active` is non-empty, print them as two short lists: render the **covered** list from `covered[]` (each entry's `label` — already the `labels[0]`-with-`question_slug`-fallback render; never the raw object or the `theme_key`), and the **open** list from `open_active` (plain strings — the still-open seeds, with researched seeds already dropped off so the backlog tracks reality). Else omit.
- **Next action.** One line, selected by the decision tree below.

The Step 2 health detail (the verdict line plus any `errors`/`warnings` worth surfacing, the context-brief summary, and the recent-log lines) appears above the summary so the user has the structural detail at hand; cogni-knowledge's contribution is the binding overlay.

#### Next action — recommend by pipeline phase

Pick the **one** Next-action line to print by branching on workflow state, not by reading out a fixed sequence. The state field is each project's `phase_reached` from `pipeline-summary.py project` (`none` → `plan` → `curate` → `fetch` → `ingest` → `distill` → `compose` → `verify`); a finalized project has `report_source == "wiki"` in its binding entry (the `· synthesis ✓` marker). Evaluate top to bottom and stop at the first match:

- **No projects** (`research_projects` empty): "Run the inverted pipeline — `knowledge-plan --knowledge-slug <slug> --topic '...'`, then `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize` — to deposit your first project."
- **Wiki has structural issues** (Step 2a verdict ≠ OK): "Fix the structural issues first — see the health detail above; run `knowledge-lint --fix=all` to repair the mechanical drift classes (a separate operator-invoked write step — resume never auto-fixes), or `knowledge-health` for a deeper read-only structural verdict. Then resume the pipeline, or `knowledge-query --knowledge-slug <slug> --question '...'` to ask what the base already knows."

Otherwise branch on the newest in-flight project's `phase_reached` (the deepest phase that ran but did not finalize) — one recommendation per state:

| `phase_reached` | Recommend |
|---|---|
| `none` (legacy deposit, no `.metadata/`) | Re-run from `knowledge-plan` — the project predates the inverted pipeline and has no resumable state. |
| `plan` | `knowledge-curate` — sources are planned but not yet discovered/fetched. |
| `curate` | `knowledge-fetch` — candidates scored; build the fetch manifest (add `--cobrowse` to recover WebFetch misses). |
| `fetch` | `knowledge-ingest` — bodies fetched; deposit per-source wiki pages with extracted claims. |
| `ingest` | `knowledge-distill` (optional Phase 4.5 — compounds concepts/entities), then `knowledge-compose`. |
| `distill` | `knowledge-compose` — distillation done; draft the synthesis from the populated wiki. |
| `compose` | `knowledge-verify` — draft + citation manifest exist; run the zero-network claim check. |
| `verify` | `knowledge-finalize` — verified; deposit the synthesis into `wiki/syntheses/` and close the loop. |

- **All projects finalized** (every entry `report_source == "wiki"`, none in flight): the base is compounding — "Ask it with `knowledge-query --knowledge-slug <slug> --question '...'`, render an overview with `knowledge-dashboard`, run the semantic hygiene pass with `knowledge-lint`, refresh stale topics with `knowledge-refresh`, deposit a single source straight into the base with `knowledge-ingest-source`, or start a new project with `knowledge-plan` to keep accumulating."

## Edge cases

- **Binding exists but `wiki_path` no longer does.** Step 1(4) catches the missing `.cogni-wiki/config.json`. Abort with a clear message.
- **`health.py` fails.** Surface its error and still print the binding section — the user benefits from at least knowing the deposit count even if the wiki health check is broken.
- **`research_projects[]` references a `report_path` that no longer exists.** Do not abort; flag in the summary with "(report file missing — possibly archived)" next to that entry. The binding is the durable record; the on-disk research project is incidental.
- **`project_path` missing or its `.metadata/` gone (legacy / archived deposit).** `pipeline-summary.py project` returns zeros + `phase_reached: "none"`; render that project's depth as `(legacy deposit)` rather than zeros. Never abort on a per-project read failure — the binding-level line still renders.
- **`pipeline-summary.py cache-health` fails.** Omit the Pipeline status line rather than aborting; the rest of the summary is still useful.

## Out of scope

- Runs the vendored `wiki-health` engine for the verdict, but does NOT run `wiki-lint` — that is a tokenful semantic pass the user invokes deliberately, not on resume.
- Does NOT dispatch `cogni-wiki:wiki-resume` — the health verdict + status surfaces are computed natively (vendored `health.py` + direct reads of `context_brief.md` / `log.md` / `config.json`).
- Does NOT write to the binding or the wiki — read-only (apart from `health.py`'s own health-check log line).

## Output

A status block printed to the user. No files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary (wiki health computed natively on the vendored engine)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-health/scripts/health.py` — the vendored health engine invoked in Step 2a
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py --help` — per-project depth (`project`) + fetch-cache verdict (`cache-health`)
