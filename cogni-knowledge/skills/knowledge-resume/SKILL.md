---
name: knowledge-resume
description: "Show status of a cogni-knowledge base — knowledge slug, bound wiki path, deposited research projects, wiki health verdict, and the recommended next action. Delegates structural integrity to cogni-wiki:wiki-resume (which runs wiki-health automatically). Use this skill whenever the user says 'resume the knowledge base', 'knowledge resume', 'knowledge status', 'where was I with the eu-ai-act base', 'what's in my knowledge base', 'show me the knowledge base overview'. Proactively after a long gap between sessions, or right after knowledge-setup or a knowledge-finalize run."
allowed-tools: Read, Bash, Glob, Skill
---

# Knowledge Resume

Give the user a fast, grounded status view of a cogni-knowledge base so they know what is inside and what the right next action is. This skill is **read-only** with respect to the binding and the wiki — it never writes. The only side effect is that the upstream `cogni-wiki:wiki-resume` may log its health-check invocation in `wiki/log.md`.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember that wiki health checks belong to cogni-wiki, not to cogni-knowledge.

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
| `--verbose` | No | Forward to `cogni-wiki:wiki-resume --verbose`. Includes recent log activity verbatim. |

## Workflow

### 0. Pre-flight

**Required plugins.** This skill dispatches `cogni-wiki:wiki-resume` and reads the inverted-pipeline manifests — it never reaches cogni-research, so it probes only `cogni-wiki` (the clean break: cogni-research is 0% of the runtime path — same posture as `knowledge-plan`). Abort cleanly here rather than letting the downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

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

Resume is read-only with respect to disk, but it still dispatches `cogni-wiki:wiki-resume` and would fail mid-skill if cogni-wiki were missing. The probe gives the user the same clean signal every other `knowledge-*` skill emits.

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

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`, `research_projects[]`, `created`, `topic_lineage`, and the charter (`binding.get("charter", {}).get("domain"/"audience"/"scope", "")` — schema 0.1.4; the `.get` chain falls through to `""` on a pre-0.1.4 binding, read-only fail-soft). (The bound wiki's own slug, if needed for display, comes live from `<wiki_path>/.cogni-wiki/config.json` — never cached in the binding.)

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

### 2. Delegate to `cogni-wiki:wiki-resume`

```
Skill("cogni-wiki:wiki-resume", args="--wiki-root <wiki_path> [--verbose]")
```

`wiki-resume` already runs `wiki-health` automatically (see `cogni-wiki/skills/wiki-resume/SKILL.md`). Do not run `wiki-health` separately; that would log a noisy second invocation.

Capture the wiki-resume output. Look for:
- The `wiki/context_brief.md` summary (auto-rebuilt by `wiki-ingest`)
- Entry count and recent log activity
- Wiki health verdict (broken wikilinks, missing frontmatter, stale drafts)

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
- **Charter.** When `charter.domain` is non-empty (schema 0.1.4): `<charter.domain> · for <charter.audience> · scope <charter.scope>`. Omit the line entirely on a pre-0.1.4 / unframed base.
- **Wiki path.** `<wiki_path>` — wiki health verdict from Step 2 (one line: "OK" / "N issues — see wiki-resume output above")
- **Deposited research projects.** `<count>` — one line per project (newest first, cap 5, "and N more" for the rest), each as: `<slug> — <sub_questions> sub-questions · <fetched> fetched · phase <phase_reached>` + ` · <concepts_total> concepts (<claims_deduped>/<claims_attached> claims deduped)` when `concepts_total > 0` (the Phase-4.5 distill compounding signal) + `· synthesis ✓` when the binding entry's `report_source == "wiki"` + ` (<deposited_at>)`. Legacy deposits show `<slug> — (legacy deposit) (<deposited_at>)`.
- **Pipeline status.** Knowledge-base-global fetch-cache (one shared cache across all projects): one line by `verdict` — `healthy` → `fetch-cache healthy (<entries> sources)`; `stale` → `fetch-cache stale — re-run knowledge-curate to re-fetch aged sources (or knowledge-refresh to re-run the pipeline on stale topics)`; `empty` → `fetch-cache empty — run knowledge-plan first`.
- **Topic lineage.** If `covered_themes` or `open_themes` are non-empty, print them as two short lists. `covered_themes[]` entries are objects `{theme_key, question_slug, labels[], first_seen, last_seen}` — render each as its `labels[0]` (the human theme phrasing), falling back to `question_slug` when `labels[]` is empty (defensive — `upsert-themes` always unions a non-empty label), never the raw object or the `theme_key` (a normalized token string); `open_themes` entries (if any) are plain strings. Else omit.
- **Next action.** One line, selected by the decision tree below.

The full `wiki-resume` output appears verbatim above the summary so the user has the structural detail at hand; cogni-knowledge's contribution is the binding overlay.

#### Next action — recommend by pipeline phase

Pick the **one** Next-action line to print by branching on workflow state, not by reading out a fixed sequence. The state field is each project's `phase_reached` from `pipeline-summary.py project` (`none` → `plan` → `curate` → `fetch` → `ingest` → `distill` → `compose` → `verify`); a finalized project has `report_source == "wiki"` in its binding entry (the `· synthesis ✓` marker). Evaluate top to bottom and stop at the first match:

- **No projects** (`research_projects` empty): "Run the inverted pipeline — `knowledge-plan --knowledge-slug <slug> --topic '...'`, then `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize` — to deposit your first project."
- **Wiki has structural issues** (Step 2 verdict ≠ OK): "Fix the structural issues first — see the wiki-resume output above. Then resume the pipeline, or `knowledge-query --knowledge-slug <slug> --question '...'` to ask what the base already knows."

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

- **All projects finalized** (every entry `report_source == "wiki"`, none in flight): the base is compounding — "Ask it with `knowledge-query --knowledge-slug <slug> --question '...'`, render an overview with `knowledge-dashboard`, refresh stale topics with `knowledge-refresh`, or start a new project with `knowledge-plan` to keep accumulating."

## Edge cases

- **Binding exists but `wiki_path` no longer does.** Step 1(4) catches the missing `.cogni-wiki/config.json`. Abort with a clear message.
- **`wiki-resume` fails.** Surface its error and still print the binding section — the user benefits from at least knowing the deposit count even if the wiki status is broken.
- **`research_projects[]` references a `report_path` that no longer exists.** Do not abort; flag in the summary with "(report file missing — possibly archived)" next to that entry. The binding is the durable record; the on-disk research project is incidental.
- **`project_path` missing or its `.metadata/` gone (legacy / archived deposit).** `pipeline-summary.py project` returns zeros + `phase_reached: "none"`; render that project's depth as `(legacy deposit)` rather than zeros. Never abort on a per-project read failure — the binding-level line still renders.
- **`pipeline-summary.py cache-health` fails.** Omit the Pipeline status line rather than aborting; the rest of the summary is still useful.

## Out of scope

- Does NOT run `wiki-health` directly — `wiki-resume` already does.
- Does NOT run `wiki-lint` — that is a tokenful semantic pass that the user invokes deliberately, not on resume.
- Does NOT write to the binding or the wiki — read-only.

## Output

A status block printed to the user. No files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary + §"How `Skill(...)` blocks are written"
- `cogni-wiki:wiki-resume` SKILL.md
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py --help` — per-project depth (`project`) + fetch-cache verdict (`cache-health`)
