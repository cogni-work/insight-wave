---
name: knowledge-query
description: "Ask a question against a bound cogni-knowledge base — resolves the wiki path from .cogni-knowledge/binding.json so the user does not need to remember it, then dispatches cogni-wiki:wiki-query against the bound wiki. Use this skill whenever the user says 'query my <slug> knowledge base', 'ask the eu-ai-act base about X', 'knowledge query on Y', 'what does my <slug> base know about Z', 'knowledge-query <slug>'. Read-only — never writes to the binding."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Query

Ask a question against a bound cogni-knowledge base. This skill is a binding-aware wrapper around `cogni-wiki:wiki-query` — its job is to resolve the bound wiki path from `binding.json` so the user types one prompt instead of two, and to append a one-line knowledge-base footer to the upstream answer.

This skill is a thin orchestrator. The cogni-knowledge value-add over a raw `cogni-wiki:wiki-query` dispatch is:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user; read from `binding.json`.
2. **Knowledge-base footer** — every answer ends with one line tying it to the knowledge slug + deposit count + fetch-cache health (cached / unavailable source counts), so the user remembers where the answer came from and how much evidence the base holds.

Read `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` once per session to anchor on the accumulation thesis; read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` to remember the delegation boundary.

## When to run

- User asks a question and references a knowledge base by slug — "what does my eu-ai-act base know about X?", "query the eu-ai-act base on Article 6"
- User explicitly invokes `/cogni-knowledge:knowledge-query`
- User asks a question that clearly lives in a bound knowledge base's domain after `knowledge-resume` has shown what is in the base

## Never run when

- No `binding.json` exists at the resolved knowledge root — route the user to `/cogni-knowledge:knowledge-setup` first. Direct callers who already have a wiki but no binding should use `cogni-wiki:wiki-query` directly.
- The user wants to query a wiki that is NOT a bound cogni-knowledge base — `cogni-wiki:wiki-query` is the right primitive.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--question` | Yes (prompted) | Free-text question. Forwarded to `cogni-wiki:wiki-query --question`. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `cogni-knowledge/<knowledge-slug>/` (relative to the current working directory). |
| `--file-back` | No | `auto` (default — wiki-query asks the user) / `yes` / `no`. Pass-through to `cogni-wiki:wiki-query --file-back`. |
| `--max-pages` | No | Cap on how many pages wiki-query reads. Pass-through to `cogni-wiki:wiki-query --max-pages`. Default 12 (upstream). |

If `--question` is missing, ask the user once via `AskUserQuestion` (single free-text question — load the schema via `ToolSearch(query="select:AskUserQuestion")` if needed). Do not invent a question.

## Workflow

### 0. Pre-flight

**Required plugins.** This skill dispatches `cogni-wiki:wiki-query` and reads the bound wiki — it never reaches cogni-research, so it probes only `cogni-wiki` (the clean break: cogni-research is 0% of the runtime path — same posture as `knowledge-plan`). Abort cleanly here rather than letting the downstream `Skill` dispatch fail with an opaque error. The probe handles both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`):

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

3. Extract `wiki_path`, `knowledge_slug`, and `research_projects[]` from the binding. Validate that `binding.knowledge_slug == --knowledge-slug` — mismatch indicates the user is pointing at the wrong directory.

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort with a clear "the binding points at a wiki that no longer exists" error.

### 1. Dispatch `cogni-wiki:wiki-query`

```
Skill("cogni-wiki:wiki-query",
      args="--wiki-root <wiki_path> --question '<question>' [--file-back <val>] [--max-pages <N>]")
```

`--wiki-root` pins the upstream skill to the bound wiki, bypassing the cwd-walk fallback. Forward `--file-back` and `--max-pages` only if the caller passed them.

### 2. Print the answer + footer

Before printing, read the knowledge-base-global fetch-cache health so the footer can show how much evidence the base has cached:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health \
    --knowledge-root <knowledge_root>
```

Capture `entries` (cached source count `<M>`) and `unavailable` (`<U>`) from `data`. On `success: false`, treat the counts as unknown and drop the fetch-cache clause from the footer rather than aborting — the answer itself is the deliverable.

Print the upstream answer verbatim, then append a single footer line on its own line:

```
Knowledge base: <knowledge_slug> · <N> deposited projects · fetch-cache: <M> sources cached (<U> unavailable) · /cogni-knowledge:knowledge-resume for status.
```

`<N>` is `len(research_projects)` from the binding; `<M>`/`<U>` come from `cache-health`. The footer reminds the user which base the answer came from, how much evidence the inverted pipeline has cached, and points at the status skill.

### 3. No binding write

This skill never modifies the binding. `cogni-wiki:wiki-query` may file the answer back as a `type: synthesis` page (depending on `--file-back`); that decision belongs to wiki-query. The binding's `research_projects[]` records inverted-pipeline deposits (from `knowledge-finalize`), not query answers.

## Edge cases

- **Empty knowledge base.** `research_projects[]` is empty. The skill still dispatches wiki-query — the bound wiki may have pages from `wiki-prefill`, hand-ingested sources, or other wiki-* skills. The footer renders `0 deposited projects` honestly so the user knows the base is sparse.
- **Wiki path resolves to a different cogni-wiki than the binding records.** Pre-flight Step 0(4) catches this — abort rather than querying the wrong wiki.
- **Knowledge slug mismatch.** Pre-flight Step 0(3) catches this — abort.

## Out of scope

- **Multi-question scoping.** This skill takes one question per run; chaining is a future enhancement.
- **Modifying the binding.** Read-only by design.

## Output

- The upstream `wiki-query` answer printed verbatim.
- One footer line appended: `Knowledge base: <slug> · <N> deposited projects · ...`
- Optionally (decided by `wiki-query` itself): a new `wiki/syntheses/<slug>.md` page if `--file-back yes`, plus the `query` and `synthesis` log lines in `wiki/log.md`. None of these are written by this skill.

No files are written outside `<wiki_path>/` and only by upstream `wiki-query`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary and §"How `Skill(...)` blocks are written"
- `cogni-wiki:wiki-query` SKILL.md — the upstream contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health --help` — fetch-cache health for the footer
