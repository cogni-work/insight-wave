---
name: knowledge-plan
description: "Phase 1 of the v0.1.0 inverted pipeline. Decomposes a research topic into 3-7 sub-questions with per-sub-question candidate-domain hints, writes plan.json into a fresh project directory under the bound knowledge base. No web access at this phase — pure decomposition. Use this skill whenever the user says 'plan a new research topic', 'decompose topic X into sub-questions', 'start a knowledge-pipeline run on X', 'knowledge plan for X', 'create sub-questions for X under the eu-ai-act base'. After plan, the user runs knowledge-curate to discover candidate sources."
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Plan

Phase 1 of the v0.1.0 inverted pipeline (`plan → curate → fetch → ingest → compose → verify → finalize`). This skill decomposes a research topic into a structured plan that downstream phases (`knowledge-curate`, `knowledge-fetch`, …) consume.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` once at the start of a session to anchor on the phase boundaries and the v0.1.0 contract.

## When to run

- User wants to start a new research run on a topic against an existing bound knowledge base
- User explicitly invokes `/cogni-knowledge:knowledge-plan`

## Never run when

- No `binding.json` exists at the resolved knowledge root — offer `knowledge-setup` first. Plan output lives in a fresh project directory under the bound knowledge root; without a binding there is no anchor.
- The user wants the legacy v0.0.x research+ingest flow — that chain is archived under `_archive/` (see `_archive/README.md`). v0.1.0 is the only live path; if they truly want a one-shot report outside the knowledge base, point at `cogni-research:research-setup`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--topic` | Yes (prompted) | Free-text research topic, e.g. `"GDPR Article 30 records of processing"`. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--market` | No | Market code (default `dach`). One of: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. |
| `--output-language` | No | Two-letter code, default `en`. |
| `--sub-question-hints` | No | Pipe-separated list of sub-question seeds the user wants reflected, e.g. `"records of processing scope|controller vs processor obligations"`. |
| `--dry-run` | No | Print the resolved plan + target paths without writing. |

If `--topic` is missing, ask the user once with AskUserQuestion. Do not invent a topic.

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` — the v0.1.0 inverted pipeline does NOT dispatch cogni-research skills or agents (clean-break commitment, per `references/inverted-pipeline.md` §"What is no longer in the runtime path"). Probe handles both layouts:

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

If `WIKI_OK=no`, abort:

> cogni-knowledge requires `cogni-wiki` to be installed. Install via the marketplace, then retry.

**Binding.** Resolve `knowledge_root`:
1. If `--knowledge-root` is set, use it.
2. Otherwise, `knowledge_root = <cwd>/<knowledge-slug>/`.

Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` — abort and offer `knowledge-setup`. Do not auto-create.

Verify the binding's `knowledge_slug` matches `--knowledge-slug` — mismatch means the user is pointing at the wrong directory.

### 1. Slugify topic + resolve project root

- `topic_slug = kebab-case of --topic` (lowercase, alphanumerics + dashes; collapse runs of dashes; strip leading/trailing dashes; cap at 60 chars). Use `sed`/`python3` — no external slugify dep.
- `date_stamp = $(date -u +%F)` (e.g. `2026-05-20`).
- `project_path = <knowledge_root>/<topic_slug>-<date_stamp>/`
- If `project_path` already exists, abort with a clear message — do not overwrite (`plan.json` is the project's anchor; re-planning the same topic on the same day means the user wants a different slug or a different date in the dir name).

If `--dry-run`, print the resolved knowledge_root, project_path, sub-question count target (3-7), and stop here.

### 2. Decompose topic into sub-questions (no web)

Reason about the topic. Decompose it into 3-7 sub-questions that together cover the topic with minimal overlap. For each sub-question:

- `id`: `sq-NN` (zero-padded, sequential from `sq-01`).
- `query`: a concrete, search-engine-friendly phrasing of the sub-question.
- `search_guidance`: 1-2 sentences telling the Phase 2 source-curator what kinds of sources would best answer this sub-question (regulatory text, industry analysis, court rulings, etc.).
- `candidate_domains`: a list of 3-8 domain stems where authoritative answers likely live for this market. Examples for `dach`: `bfdi.bund.de`, `edpb.europa.eu`, `bitkom.org`, `eur-lex.europa.eu`. Use the market's authority sources as your starting set — resolved via the canonical workspace helper. **For regulatory topics that need the actual law text**, list the canonical article-page domain (e.g. `artificialintelligenceact.eu` for the EU AI Act) *first* — `candidate_domains[]` order drives the curator's `site:` queries — and treat legal-database landing/ELI domains (`eur-lex.europa.eu`) as a fallback only, since their ELI URLs can resolve to the wrong document or only a summary:
  ```
  python3 "${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ | head -1)}/scripts/get-market-config.py" --plugin research --market <market>
  ```
  Same path cogni-portfolio's agents use; the helper joins the canonical registry (`cogni-workspace/references/supported-markets-registry.json`) with the research overlay so cogni-knowledge never reaches into cogni-research's filesystem.

If `--sub-question-hints` was passed, ensure each hint maps to at least one sub-question — but you may rephrase, split, or merge as needed for coherence.

### 3. Write plan.json

Create `<project_path>/.metadata/` (using `mkdir -p`).

Write `<project_path>/.metadata/plan.json` with the schema below (per `references/inverted-pipeline.md:41-57`):

```json
{
  "schema_version": "0.1.0",
  "topic": "<--topic verbatim>",
  "sub_questions": [
    {
      "id": "sq-01",
      "query": "...",
      "search_guidance": "...",
      "candidate_domains": ["europa.eu", "..."]
    }
  ],
  "market": "<resolved market>",
  "output_language": "<resolved language>",
  "cost_estimate_usd": 0.0,
  "created": "<ISO 8601 UTC, e.g. 2026-05-20T14:31:02Z>"
}
```

Use the Write tool. JSON must be valid (no trailing commas, double quotes).

`cost_estimate_usd` is 0.0 at Phase 1 since this skill does not call WebSearch/WebFetch. Downstream phases accumulate cost into their own manifests.

### 4. Binding is NOT touched

Phase 1 is project-local. Do not call `knowledge-binding.py append-project`. The binding append happens at M9 (`knowledge-finalize`), after verification completes.

### 5. Final summary

Print ≤ 6 lines:

- Knowledge base: `<knowledge_slug>` at `<knowledge_root>`
- New project: `<topic_slug>-<date_stamp>` (topic: `<topic>`)
- Plan: `<sub_questions_count>` sub-questions, market `<market>`, language `<output_language>`
- Plan path: `<project_path>/.metadata/plan.json`
- Next: run `knowledge-curate --knowledge-slug <slug> --project-path <project_path>` to discover candidate sources

## Edge cases

- **Topic resolves to the same slug as an existing project on the same day.** Step 1 aborts. The user can rephrase the topic or wait until tomorrow — multi-run-per-day on the same topic is not a v0.1.0 use case.
- **Sub-question count outside 3-7.** Re-decompose. Too few (1-2) usually means the topic is too narrow for sub-questions; suggest the user research the question directly via WebSearch. Too many (8+) means the topic is too broad; suggest a knowledge-plan per major theme.
- **Binding pre-dates v0.0.3** (no `curator_defaults`). No problem — `knowledge-plan` does not read `curator_defaults`. Downstream `knowledge-curate` falls back to `DEFAULT_CURATOR_DEFAULTS` for legacy bindings.

## Out of scope

- Does NOT call WebSearch or WebFetch (Phase 1 is decomposition only).
- Does NOT touch the wiki — wiki ingest is Phase 4 (`knowledge-ingest`, M5+M6, not yet shipped).
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends.
- Does NOT support `--source-mode local|hybrid|wiki` — v0.1.0 is web-only per `references/absorption-roadmap.md` Phase 5 "Out of scope".

## Output

- `<project_path>/.metadata/plan.json` (schema 0.1.0)

No other files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 1 contract
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — M-table progress
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
