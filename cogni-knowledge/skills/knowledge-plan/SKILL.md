---
name: knowledge-plan
description: "Phase 1 of the inverted pipeline. Decomposes a research topic into 3-7 sub-questions with per-sub-question candidate-domain hints, writes plan.json into a fresh project directory under the bound knowledge base. No web access at this phase — pure decomposition. Use this skill whenever the user says 'plan a new research topic', 'decompose topic X into sub-questions', 'start a knowledge-pipeline run on X', 'knowledge plan for X', 'create sub-questions for X under the eu-ai-act base'. After plan, the user runs knowledge-curate to discover candidate sources."
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion, Skill
---

# Knowledge Plan

Phase 1 of the inverted pipeline (`plan → curate → fetch → ingest → compose → verify → finalize`). This skill decomposes a research topic into a structured plan that downstream phases (`knowledge-curate`, `knowledge-fetch`, …) consume.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` once at the start of a session to anchor on the phase boundaries and the contract.

## When to run

- User wants to start a new research run on a topic against an existing bound knowledge base
- User explicitly invokes `/cogni-knowledge:knowledge-plan`

## Never run when

- No `binding.json` exists at the resolved knowledge root — offer `knowledge-setup` first. Plan output lives in a fresh project directory under the bound knowledge root; without a binding there is no anchor.
- The user wants the legacy research+ingest flow — that chain is archived under `_archive/` (see `_archive/README.md`). The inverted pipeline is the only live path; if they truly want a one-shot report outside the knowledge base, point at `cogni-research:research-setup`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--topic` | Yes (prompted) | Free-text research topic, e.g. `"GDPR Article 30 records of processing"`. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--market` | No | Market code. One of: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. Resolved in Step 0.5: explicit flag > binding `research_defaults.market` > `dach`. |
| `--output-language` | No | Two-letter code. Resolved in Step 0.5: explicit flag > binding `research_defaults.output_language` > the market's registry `default_output_language` > `en`. No longer a silent `en` default — a `dach` base now emits German without a flag. |
| `--sub-question-hints` | No | Pipe-separated list of sub-question seeds the user wants reflected, e.g. `"records of processing scope|controller vs processor obligations"`. |
| `--dry-run` | No | Print the resolved plan + target paths without writing. |

If `--topic` is missing, ask the user once with AskUserQuestion. Do not invent a topic.

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` — the inverted pipeline does NOT dispatch cogni-research skills or agents (clean-break commitment, per `references/inverted-pipeline.md` §"What is no longer in the runtime path"). Probe handles both layouts:

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
2. Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` — abort and offer `knowledge-setup`. Do not auto-create.

Verify the binding's `knowledge_slug` matches `--knowledge-slug` — mismatch means the user is pointing at the wrong directory.

### 0.5. Resolve market + output language

`market` and `output_language` are first-class config, not silent flags — `output_language` flows `plan.json` → `knowledge-compose` → `wiki-composer` → `knowledge-finalize` (body, headings, localized reference heading), so getting it wrong here mis-languages the whole run. Resolve each independently by this precedence (mirrors `cogni-research`'s `research-setup` Phase 0.1 — *market's `default_output_language`, fallback `en`*):

**`market`:**
1. `--market` flag, if passed.
2. Else the binding's `research_defaults.market` (read the binding object from Step 0; `.get("research_defaults", {}).get("market")` — pre-0.1.1 bindings have no block).
3. Else `dach`.

**`output_language`:**
1. `--output-language` flag, if passed.
2. Else the binding's `research_defaults.output_language`.
3. Else the resolved market's registry `default_output_language` — read from the canonical workspace helper (the same call Step 2 makes for `candidate_domains`; read `data.default_output_language` from that one envelope, no second subprocess):
   ```
   python3 "${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ | head -1)}/scripts/get-market-config.py" --plugin research --market <resolved market>
   ```
   (e.g. `dach`→`de`, `fr`→`fr`, `eu`→`en`.)
4. Else `en`.

**Interactive fallback.** The trigger is **no `--output-language` flag AND no binding `research_defaults.output_language`** — i.e. steps 1 and 2 both missed (only reachable on a pre-0.1.1 base, since `knowledge-setup` Step 2.5 persists a binding default). In that case interactivity decides ask-vs-silent: on an **interactive** run, ask the user once with `AskUserQuestion` — option 1 is the market's `default_output_language` *(Recommended)*, option 2 `en` (English), plus 1–2 common others; the auto-added "Other" takes a two-letter code. On a **non-interactive** run (`--dry-run`, or any run driven by flags/automation), do **not** prompt — silently take step 3's market `default_output_language` (then `en`). Skipping the question also falls back to the market default.

Carry the resolved `market` + `output_language` into Step 2 (candidate domains, `theme_label` language) and Step 3 (plan.json).

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
- `theme_label`: a short (2-5 word) human-readable thematic label for this sub-question, in the project's `output_language`, Title Case (e.g. `"Records of Processing Scope"`, `"Controller vs Processor Obligations"`). Phase 4 (`knowledge-ingest`) files each ingested source under this label as its `wiki/index.md` category, so the index reads thematically instead of one flat `## Sources` heading. Make labels distinct across sub-questions and self-explanatory out of context (they become index headings a reader skims).
- `candidate_domains`: a list of 3-8 domain stems where authoritative answers likely live for this market. Examples for `dach`: `bfdi.bund.de`, `edpb.europa.eu`, `bitkom.org`, `eur-lex.europa.eu`. Use the market's authority sources as your starting set — resolved via the canonical workspace helper. **For regulatory topics that need the actual law text**, list the canonical article-page domain (e.g. `artificialintelligenceact.eu` for the EU AI Act) *first* — `candidate_domains[]` order drives the curator's `site:` queries — and treat legal-database landing/ELI domains (`eur-lex.europa.eu`) as a fallback only, since their ELI URLs can resolve to the wrong document or only a summary:
  ```
  python3 "${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ | head -1)}/scripts/get-market-config.py" --plugin research --market <resolved market>
  ```
  Same path cogni-portfolio's agents use; the helper joins the canonical registry (`cogni-workspace/references/supported-markets-registry.json`) with the research overlay so cogni-knowledge never reaches into cogni-research's filesystem. **Call the helper at most once per run:** Step 0.5 invokes it only as its third fallback (no language flag and no binding default), so if it already fetched the envelope, reuse it here (`authority_sources` and `default_output_language` come from that one call); otherwise — the common case, where a flag or binding default resolved the language and Step 0.5 skipped the helper — Step 2 makes the single call here. Never call it twice.

If `--sub-question-hints` was passed, ensure each hint maps to at least one sub-question — but you may rephrase, split, or merge as needed for coherence.

### 3. Write plan.json

Create `<project_path>/.metadata/` (using `mkdir -p`).

Write `<project_path>/.metadata/plan.json` with the schema below (per `references/inverted-pipeline.md`):

```json
{
  "schema_version": "0.1.0",
  "topic": "<--topic verbatim>",
  "sub_questions": [
    {
      "id": "sq-01",
      "query": "...",
      "search_guidance": "...",
      "theme_label": "Records of Processing Scope",
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

Phase 1 is project-local. Do not call `knowledge-binding.py append-project`. The binding append happens at `knowledge-finalize`, after verification completes.

### 5. Final summary

Print ≤ 6 lines:

- Knowledge base: `<knowledge_slug>` at `<knowledge_root>`
- New project: `<topic_slug>-<date_stamp>` (topic: `<topic>`)
- Plan: `<sub_questions_count>` sub-questions, market `<market>`, language `<output_language>`
- Plan path: `<project_path>/.metadata/plan.json`
- Next: run `knowledge-curate --knowledge-slug <slug> --project-path <project_path>` to discover candidate sources

## Edge cases

- **Topic resolves to the same slug as an existing project on the same day.** Step 1 aborts. The user can rephrase the topic or wait until tomorrow — multi-run-per-day on the same topic is not a supported use case.
- **Sub-question count outside 3-7.** Re-decompose. Too few (1-2) usually means the topic is too narrow for sub-questions; suggest the user research the question directly via WebSearch. Too many (8+) means the topic is too broad; suggest a knowledge-plan per major theme.
- **Binding has no `curator_defaults`.** No problem — `knowledge-plan` does not read `curator_defaults`. Downstream `knowledge-curate` falls back to `DEFAULT_CURATOR_DEFAULTS` for legacy bindings.
- **Binding has no `research_defaults`** (pre-0.1.1 base created before this UX). Step 0.5's `.get("research_defaults", {})` returns empty, so resolution falls straight through to the market's registry `default_output_language` (then the interactive prompt / `en`) — no error, and the run is unaffected.

## Out of scope

- Does NOT call WebSearch or WebFetch (Phase 1 is decomposition only).
- Does NOT touch the wiki — wiki ingest is Phase 4 (`knowledge-ingest`).
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends.
- Does NOT support `--source-mode local|hybrid|wiki` — the inverted pipeline is web-only.

## Output

- `<project_path>/.metadata/plan.json` (schema 0.1.0)

No other files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 1 contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
