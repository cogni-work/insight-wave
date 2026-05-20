---
name: knowledge-report
description: "Compose a research report by reading the bound cogni-wiki knowledge base, then re-deposit the result back into the same wiki — the wiki-roundtrip primitive. Reads .cogni-knowledge/binding.json to resolve the wiki path so the user does not have to. Dispatches cogni-research with report_source=wiki against the bound wiki, runs cycle-guard.py to refuse self-citing loops, then re-deposits via cogni-wiki:wiki-from-research Mode B with the --allow-wiki-source --cycle-guard-cleared opt-in flags. Every deposited page is stamped with derived_from_research:<slug>, and the project is recorded in the binding with the live report_source (wiki or hybrid). Use this skill whenever the user says 'write a report from my <knowledge-slug> knowledge base', 'roundtrip report on X', 'compose from accumulated knowledge', 'synthesise what we know about X from the wiki', 'wiki-report on <topic>'. Phase 2 of the absorption roadmap — proves that knowledge compounds across projects."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Report

Compose a report **from** the accumulated knowledge in a bound cogni-knowledge base, then deposit the new report back into the same wiki. This is the **wiki-roundtrip primitive** — the second-order loop that proves knowledge compounds: a wiki-mode research run reads what `knowledge-research` filed, and its own findings join the same wiki for the next reader.

This skill is a thin orchestrator. Three pieces of value-add over a raw `cogni-research` + `cogni-wiki` chain:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user; read it from `binding.json`.
2. **Cycle-guard** — refuses to deposit when the new project's wiki citations form a direct self-cycle (it would be reading its own past deposit as new evidence).
3. **Live `report_source` in the binding** — the deposited project is recorded with `wiki` or `hybrid` (whichever `cogni-research` actually ran), not a hard-coded `web`.

Read `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` once per session to anchor on the accumulation thesis; read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` to remember the delegation boundary.

## When to run

- User asks for a report composed *from* an existing knowledge base — "what do we know about X?", "summarise the EU AI Act base on Article 6", "roundtrip report on foundation models"
- User wants the second-order loop: a new research run that reads what previous runs filed AND adds its own findings to the same wiki
- User explicitly invokes `/cogni-knowledge:knowledge-report`

## Never run when

- No `binding.json` exists at the resolved knowledge root — route the user to `/cogni-knowledge:knowledge-setup` first
- The knowledge base is empty (zero entries in `research_projects[]`) — point the user at `/cogni-knowledge:knowledge-research` instead; there is nothing to read yet
- The user wants a one-shot research report with no persistence — `cogni-research:research-setup` directly is the right primitive

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--topic` | Yes (prompted) | Free-text topic for the report. Forwarded to `cogni-research:research-setup` as natural language. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `<cwd>/<knowledge-slug>/`. |
| `--dry-run` | No | Print the resolved plan (binding, wiki path, dispatch) without running. |

If `--topic` is missing, ask the user once via `AskUserQuestion`. Do not invent a topic. Phase 2 keeps the parameter surface minimal — multi-question scoping is deferred.

## Workflow

### 0. Pre-flight

**Required plugins.** cogni-knowledge is a thin orchestrator over `cogni-wiki` and `cogni-research`; abort cleanly here rather than letting downstream `Skill` dispatches fail with opaque errors. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

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
probe_plugin cogni-research research-setup && RESEARCH_OK=yes || RESEARCH_OK=no
```

If either is `no`, list the missing plugin(s) and abort:

> cogni-knowledge requires both `cogni-wiki` and `cogni-research` to be installed.
> Missing: `<comma-separated list>`. Install via the marketplace, then retry.

Then continue with the binding-resolution checks:

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = <cwd>/<knowledge-slug>/`.

2. Read the binding:

   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```

   On `success: false` (binding missing or malformed), abort and offer `knowledge-setup`. Do not auto-create.

3. Extract `wiki_path`, `knowledge_slug`, and `research_projects[]` from the binding. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. If `len(research_projects) == 0`, abort with "the knowledge base is empty — run `/cogni-knowledge:knowledge-research` at least once before composing a report from it".

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort with a clear "the binding points at a wiki that no longer exists" error.

5. If `--dry-run`, print the resolved plan (knowledge_slug, wiki_path, topic, deposited_projects_count) and stop.

### 1. Dispatch `cogni-research:research-setup` in wiki mode

The skill is interactive and parses intents from the user prompt; feed it the topic plus an explicit instruction to use wiki mode against the bound wiki path. This mirrors `cogni-wiki:wiki-from-research`'s Step 1 prompt-passthrough pattern (see `cogni-wiki/skills/wiki-from-research/SKILL.md:78-81`).

```
Skill("cogni-research:research-setup",
      prompt="Compose a detailed report by reading the wiki at <wiki_path>. Topic: <topic>. Use source mode wiki. Use wiki paths <wiki_path>. Report type detailed.")
```

The user proceeds through `research-setup`'s interactive menu — `wiki` mode will be pre-selected and `wiki_paths` pre-filled. `research-setup` auto-chains to `research-report` and the full pipeline runs to completion: `cogni-research-<resolved_slug>/output/report.md` is written.

Capture `resolved_slug` from the dispatch output (parse `cogni-research-<slug>/` from the printed project path, same convention as `knowledge-research/SKILL.md` Step 1).

If the dispatch fails before `output/report.md` exists, abort. Do NOT run cycle-guard, do NOT deposit, do NOT append to the binding.

### 2. Run cycle-guard

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cycle-guard.py \
    --knowledge-root <knowledge_root> \
    --research-slug <resolved_slug> \
    --research-project-path <abs path to cogni-research-<resolved_slug>/>
```

Interpret the result:

- **Exit 0, `status: not_applicable`** — `report_source ∈ {web, local}` despite the menu pre-fill (the user changed their mind in the interactive menu). Continue without lifting the `wiki-from-research` abort; cogni-research did web/local research and the standard deposit pathway applies.
- **Exit 0, `status: clear`** — wiki-mode run, no direct self-cycle. Proceed to Step 3 with the opt-in flags. `cross_lineage_overlap[]` may be non-empty; that's normal and informational — surface the count in Step 6.
- **Exit 1, `status: cycle_detected`** — abort. Print the `direct_self_cycles[]` JSON block plus the remediation message: "The new project cites wiki pages it had previously deposited (direct self-cycle). Rename the project, scope the topic narrower, or wait for transitive cycle handling (v0.0.7+)." Do NOT deposit, do NOT stamp lineage, do NOT append to binding. The research project's files persist on disk; the user can rename and re-run.

### 3. Deposit via `wiki-from-research` Mode B

```
Skill("cogni-wiki:wiki-from-research",
      args="--research-slug <resolved_slug> --wiki-root <wiki_path> --allow-wiki-source --cycle-guard-cleared")
```

The `--allow-wiki-source --cycle-guard-cleared` flag pair tells `wiki-from-research` to lift its default abort on `report_source ∈ {wiki, hybrid}` projects (see `cogni-wiki/skills/wiki-from-research/SKILL.md` Step 0(3)). The skill trusts our cycle-guard assertion — it does NOT re-run the guard. If cycle-guard returned `not_applicable` (a web/local run), omit both flags — the dispatch is just a normal Mode B run.

### 4. Stamp lineage

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/lineage-stamp.py \
    --wiki-root <wiki_path> \
    --research-slug <resolved_slug>
```

Idempotent. On `success: false`, surface the warning but do NOT abort — lineage stamping is degraded gracefully (Phase 2's cycle-guard depends on stamps for *future* cycles, not the current deposit which has already cleared).

### 5. Append the project to the binding with the *live* `report_source`

This is the satisfaction of the delegation-contract Phase-2 guardrail (`${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` §"Wiring report_source"). Read the live value from `<project>/.metadata/project-config.json` via the shared reader script's `--bare` mode:

```
RS=$(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/read-project-config.py \
       --project-path <abs path to project> \
       --field report_source --default web --bare)
```

`<abs path to project>` resolves to the project directory captured during Step 1. With the F2 fix in cogni-wiki v0.0.43, this is no longer hard-coded to `cogni-research-<slug>/`; cogni-research v0.7.x+ names it `<slug>-<date>/` or `<slug>/`.

Then:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py append-project \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --research-slug <resolved_slug> \
    --report-path <abs path to project>/output/report.md \
    --project-path <abs path to project> \
    --report-source $RS
```

`--project-path` was added to the schema in v0.0.14 (binding `schema_version: 0.0.2`). cycle-guard reads it directly when present and falls back to deriving the dir from `report_path.parent.parent` for legacy 0.0.1 entries.

The value of `$RS` will be `wiki` for a clean wiki-mode run, `hybrid` if the user opted into hybrid in the menu, or `web`/`local` if they pivoted away from wiki mode (in which case Step 2 already returned `not_applicable` and Step 3 ran without the opt-in flags).

On duplicate-slug error, surface a warning — the wiki pages have been (re-)deposited, but the binding entry stays as the original record. Do not abort.

### 6. Final summary

Print ≤ 8 lines:

- Knowledge base: `<knowledge_slug>` at `<knowledge_root>`
- New deposit: `<resolved_slug>` (topic: `<topic>`, source: `<report_source>`)
- Cycle-guard: `direct_self_cycles=0`, `cross_lineage_overlap=N` (the count from Step 2)
- Wiki pages deposited (from `wiki-from-research`'s summary)
- Pages stamped with lineage (from `lineage-stamp.py`)
- Total deposited projects now: `<count>` (from the binding append)
- Cost (if `wiki-from-research` returned it)
- Suggested next: `/cogni-knowledge:knowledge-resume`, `cogni-wiki:wiki-query`, or another `/cogni-knowledge:knowledge-report` on an adjacent question

## Edge cases

- **User pivots away from wiki mode in the interactive menu.** Step 2's cycle-guard returns `not_applicable`. Step 3 omits the opt-in flags and runs as a standard Mode B deposit. Step 5 records `report_source: web|local` per the live config.
- **Cycle detected.** Step 2 aborts cleanly. The research project's files remain on disk — the user can rename the project (`cogni-research:research-setup` with a different topic phrasing) and re-invoke `knowledge-report`.
- **Empty knowledge base.** Step 0(3) catches this — the skill refuses to dispatch wiki-mode research against an empty wiki.
- **Resolved slug collides with an existing deposit.** Step 5's binding append returns the duplicate-slug warning. The wiki has been refreshed via `wiki-ingest`'s re-ingest branch; only the binding record stays as the original.

## Out of scope

- **Multi-hop (transitive) cycle detection.** MVP catches direct self-cycles only. A v0.0.7+ patch lifts that once alpha runs surface real cycle shapes.
- **Multi-topic / multi-question scoping.** Phase 2 takes one topic per run. Deferred to a future enhancement.
- **Automatically running `verify-report` on the new project.** Same nudge contract as `knowledge-research` — manual decision, surfaced in the summary.

## Output

- A `cogni-research-<resolved_slug>/` project directory (at the workspace root)
- New pages under `<wiki_path>/wiki/**/*.md` and raw sources under `<wiki_path>/raw/research-<resolved_slug>/`
- An updated `<knowledge_root>/.cogni-knowledge/binding.json` with one new entry in `research_projects[]` carrying the live `report_source`

No files are written outside the workspace root or the bound knowledge base.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary, plus the Phase-2 `report_source` guardrail
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — Phase 2 deliverable list
- `${CLAUDE_PLUGIN_ROOT}/scripts/cycle-guard.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/lineage-stamp.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `cogni-wiki:wiki-from-research` SKILL.md Step 0(3) — the lifted abort and opt-in flag contract
- `cogni-research:research-setup` SKILL.md — interactive wiki-mode menu (the prompt-passthrough lands here)
