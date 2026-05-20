---
name: knowledge-research
description: "Research a topic INTO a bound cogni-knowledge base — runs cogni-research on the topic and deposits the findings into the knowledge base's wiki in one prompt. Reads .cogni-knowledge/binding.json to resolve the wiki path so the user does not have to. Every deposited page is stamped with derived_from_research:<slug>, and the project is recorded in the binding's research_projects[] list. Use this skill whenever the user says 'research X into my knowledge base', 'deposit research on X into the eu-ai-act base', 'knowledge research on X', 'add research on X to the knowledge base', 'feed the knowledge base a research run on X'. Knowledge accumulates across runs — the second knowledge-research on a related topic reads what the first deposited."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Research

Research a topic and deposit the findings into a bound cogni-knowledge base in one command. This is the **accumulation primitive** — every run of this skill leaves the knowledge base denser than before, and the next run reads what previous runs filed.

This skill is a thin orchestrator over `cogni-wiki:wiki-from-research` (Mode A). The cogni-knowledge value-add is three things on top of `wiki-from-research`:

1. Binding-aware wiki path resolution (no `--wiki-root` from the user — read it from `binding.json`).
2. Lineage stamping (`derived_from_research: <slug>` on every deposited page).
3. Binding append (record the project in `research_projects[]` so `knowledge-resume` can list it).

Read `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` once at the start of a session to anchor on the accumulation thesis; read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` to remember the delegation boundary.

## When to run

- User asks to research a topic INTO an existing knowledge base
- User wants the work to compound — second research on a related topic should read the first
- User explicitly invokes `/cogni-knowledge:knowledge-research`

## Never run when

- No `binding.json` exists at the resolved knowledge root — offer `cogni-knowledge:knowledge-setup` first. Do not silently create one; the binding is a deliberate commitment.
- The user wants a one-shot research report with no persistence — point at `cogni-research:research-setup` directly. cogni-knowledge is opinionated about wiki-first.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--topic` | Yes (prompted) | Free-text research topic. Forwarded to `cogni-wiki:wiki-from-research --topic`. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `<cwd>/<knowledge-slug>/`. |
| `--research-overrides` | No | Comma-separated `key=value` hints forwarded to `cogni-wiki:wiki-from-research --research-overrides` (e.g. `report_type=detailed,market=dach,target_words=5000`). Default if absent: `report_type=detailed`. The user can still override every value in `cogni-research:research-setup`'s interactive menu. |
| `--dry-run` | No | Print the resolved plan (binding, wiki path, dispatch) without running. |

If `--topic` is missing, ask the user once. Do not invent a topic.

## Workflow

### 0. Pre-flight

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = <cwd>/<knowledge-slug>/`.

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false` (binding missing or malformed), abort and offer `knowledge-setup`. Do not auto-create.

3. Extract `wiki_path` and `knowledge_slug` from the binding. Validate the binding's `knowledge_slug` matches `--knowledge-slug` — mismatch indicates the user is pointing at the wrong directory.

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort with a clear "the binding points at a wiki that no longer exists" error. Read the live `slug` from that config file — that is the value to forward as `--wiki-slug` in Step 1 (never cache in the binding).

5. If `--dry-run`, print the resolved plan (knowledge_slug, wiki_path, topic, research_overrides) and stop.

### 1. Dispatch `cogni-wiki:wiki-from-research` (Mode A)

```
Skill("cogni-wiki:wiki-from-research",
      args="--topic '<topic>' --wiki-root <wiki_path> --wiki-slug <live_wiki_slug> --research-overrides <overrides>")
```

Default `--research-overrides report_type=detailed` if the caller did not pass any.

`wiki-from-research` will:
1. Pre-flight (Step 0): wiki collision check, dry-run gate.
2. Run `cogni-research:research-setup` → `research-report` to produce `cogni-research-<resolved_slug>/output/report.md`.
3. Skip `wiki-setup` (the wiki already exists; `wiki-from-research` Step 0(2) lands on `wiki_action = resume`).
4. Dispatch `wiki-ingest --discover research:<resolved_slug>` from `<wiki_path>` as cwd to deposit per-sub-question pages under `<wiki_path>/raw/research-<resolved_slug>/` and `<wiki_path>/wiki/**/*.md`.

Parse the `resolved_slug` from `wiki-from-research`'s final summary (Step 4 prints `research_slug` and project path). If the dispatch fails before the deposit completes, abort; do not stamp lineage or append to the binding for a half-completed run.

### 2. Stamp lineage

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/lineage-stamp.py \
    --wiki-root <wiki_path> \
    --research-slug <resolved_slug>
```

The script adds `derived_from_research: <resolved_slug>` to the YAML frontmatter of every wiki page whose `sources:` list points into `<wiki_path>/raw/research-<resolved_slug>/`. Idempotent — safe even if Step 1 was a resume.

On `success: false`, surface the error but **do not abort the workflow** — lineage stamping is a quality-of-life addition; missing stamps degrade Phase 2's cycle-guard but do not corrupt the wiki or the binding. Print a warning and continue.

### 3. Append the project to the binding

Read the live `report_source` from the project's metadata via the shared reader script (same pattern as `knowledge-report` Step 5):

```
RS=$(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/read-project-config.py \
       --project-path cogni-research-<resolved_slug> \
       --field report_source --default web \
     | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['value'])")
```

Then append:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py append-project \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --research-slug <resolved_slug> \
    --report-path <abs path to cogni-research-<resolved_slug>/output/report.md> \
    --report-source $RS
```

`report_source` is read live from the project's config. For Mode A invocations it will normally be `web` — `wiki-from-research` runs `cogni-research`'s default web mode (the skill refuses `report_source ∈ {wiki, hybrid}` projects, see `cogni-wiki/skills/wiki-from-research/SKILL.md` Step 0(3)). If a user reaches `knowledge-research` via a path that resolves to `local` or future modes, the live value is recorded faithfully. The `web` default in the python expression is purely a safety net for a missing key.

On duplicate-slug error from the script (the same `resolved_slug` is already in the binding), surface a warning — this can happen if the user re-ran a research project with the same slug. The wiki pages have been re-deposited (mode: re-ingest), but the binding entry stays as the original deposit's record. Do not abort.

### 4. Final summary

Print ≤ 8 lines:

- Knowledge base: `<knowledge_slug>` at `<knowledge_root>`
- New deposit: `<resolved_slug>` (topic: `<topic>`)
- Wiki pages deposited (count from `wiki-from-research`'s Step 4 summary)
- Pages stamped with lineage (count from `lineage-stamp.py`'s `stamped[]` length)
- Total deposited projects now: `<count>` (from `knowledge-binding.py append-project`'s `research_projects_count`)
- Cost (if `wiki-from-research` returned it — sum from `research-report` Phase 6)
- Suggested next: `knowledge-resume`, `cogni-wiki:wiki-query`, or another `knowledge-research` on an adjacent topic

## Edge cases

- **Topic collision with an existing research project.** `cogni-research:research-setup` (inside `wiki-from-research` Step 1) prompts resume / new / different. The `resolved_slug` we capture in Step 1 reflects the user's choice. If the user picks `resume` of a previously-deposited project, Step 3's binding append will refuse (duplicate slug) — warn and continue; the wiki has been refreshed via `wiki-ingest`'s re-ingest branch.
- **`wiki-from-research` aborts during pre-flight.** No research has run. Surface the error verbatim; the binding is untouched.
- **Wiki path resolves to a different cogni-wiki than the binding records.** Step 0(4) catches this. Abort rather than silently writing into the wrong wiki.

## Out of scope

- Does NOT write wiki pages directly — every deposit goes through `cogni-wiki:wiki-ingest`'s lock-protected pipeline.
- Does NOT modify the research project's files — only the wiki side gets the lineage stamp.
- Does NOT support `report_source ∈ {wiki, hybrid}` — that is Phase 2's `knowledge-report`.

## Output

- A `cogni-research-<resolved_slug>/` project directory (at the workspace root, per `cogni-research`'s default)
- New pages under `<wiki_path>/wiki/**/*.md` and raw sources under `<wiki_path>/raw/research-<resolved_slug>/`
- An updated `<knowledge_root>/.cogni-knowledge/binding.json` with one new entry in `research_projects[]`

No files are written outside the workspace root or the bound knowledge base.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md`
- `cogni-wiki:wiki-from-research` SKILL.md — Mode A contract
- `cogni-wiki:wiki-ingest` SKILL.md and `references/batch-mode.md` — `--discover research:<slug>` contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/lineage-stamp.py --help`
