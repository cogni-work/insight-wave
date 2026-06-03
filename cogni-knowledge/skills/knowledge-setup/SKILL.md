---
name: knowledge-setup
description: "Bootstrap a cogni-knowledge knowledge base — a cogni-wiki + a binding manifest that records every research project deposited into it. Creates the wiki via cogni-wiki:wiki-setup if it does not exist, then writes .cogni-knowledge/binding.json. Use this skill whenever the user says 'set up a knowledge base', 'start a knowledge base on X', 'bootstrap a wiki-first research base', 'new knowledge base for X', 'create a knowledge base', or 'wiki-first research setup'. After setup, run the inverted pipeline (knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → knowledge-compose → knowledge-verify → knowledge-finalize) to deposit research syntheses into the base."
allowed-tools: Read, Bash, Glob, WebSearch, AskUserQuestion, Skill
---

# Knowledge Setup

Bootstrap a cogni-knowledge knowledge base. A knowledge base is one directory that holds both a cogni-wiki (`.cogni-wiki/config.json`) and a cogni-knowledge binding manifest (`.cogni-knowledge/binding.json`). The wiki is the substrate; the binding records which research projects have contributed to it.

This skill is a **thin orchestrator**. It does not re-implement wiki bootstrapping — that work belongs to `cogni-wiki:wiki-setup`. The cogni-knowledge value-add is the binding manifest plus the one-command workflow.

Read `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` once at the start of a session to anchor on why wiki-first matters; read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` to remember what cogni-knowledge owns vs. delegates.

## When to run

- User asks to bootstrap, set up, initialize, or start a knowledge base
- User wants to begin a long-running research area (multiple projects, accumulating findings)
- User explicitly invokes `/cogni-knowledge:knowledge-setup`

## Never run when

- The target directory already has `.cogni-knowledge/binding.json` — report the existing binding and stop. Re-initialisation is destructive; surface the existing slug and let the user decide.
- The user wants a one-off research report — point them at `cogni-research:research-setup` directly. cogni-knowledge is opinionated about accumulation; cogni-research stays available as a sibling plugin for one-shot reports.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes (prompted) | Kebab-case identifier for the knowledge base, e.g. `eu-ai-act`. Used for the directory name (`cogni-knowledge/<slug>/`) and the `knowledge_slug` field in the binding. |
| `--knowledge-title` | Yes (prompted) | Human-readable title, e.g. `"EU AI Act knowledge base"`. Used as the `--name` for `cogni-wiki:wiki-setup`. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `cogni-knowledge/<knowledge-slug>/` (relative to the current working directory). Both the wiki and the binding live inside this directory. |
| `--description` | No | One-sentence description forwarded to `cogni-wiki:wiki-setup --description`. |
| `--publisher-base-url` | No | Forwarded to `cogni-wiki:wiki-setup --publisher-base-url`. Used as last-resort fallback URL when wiki pages have no per-page publisher URL. |
| `--market` | No | Default market for this knowledge base. One of: `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. Persisted to `binding.json::research_defaults.market`; inherited by every `knowledge-plan` run. Resolved interactively in Step 2.5 when omitted (default `dach`). |
| `--output-language` | No | Default output language (two-letter code) for this knowledge base. Persisted to `binding.json::research_defaults.output_language`; inherited by every `knowledge-plan` run. Resolved interactively in Step 2.5 when omitted — defaults to the chosen market's registry `default_output_language` (e.g. `dach`→`de`, `fr`→`fr`, `eu`→`en`). |
| `--prose-density` | No | Default prose density (`standard`/`executive`) persisted to `binding.json::research_defaults.prose_density`. **Flag-or-default** — not prompted in Step 2.5 (safe default `standard`). |
| `--tone` | No | Default writing tone persisted to `binding.json::research_defaults.tone` (see `${CLAUDE_PLUGIN_ROOT}/references/writing-tones.md`). **Flag-or-default** — not prompted (safe default `objective`). |
| `--citation-format` | No | Default citation format persisted to `binding.json::research_defaults.citation_format` (`ieee`/`chicago` wired; `apa`/`mla`/`harvard` staged). **Flag-or-default** — not prompted (safe default `ieee`). |
| `--target-words` | No | Default soft target word count persisted to `binding.json::research_defaults.target_words`. **Flag-or-default** — not prompted (safe default `4000`). |
| `--charter-domain` | No | One sentence: what this knowledge base is about. Persisted to `binding.json::charter.domain` (schema 0.1.4). Resolved interactively in Step 2.5 when omitted (engages the charter interview). |
| `--charter-audience` | No | Primary reader of the syntheses this base produces. Persisted to `binding.json::charter.audience`. Resolved interactively in Step 2.5 when omitted. |
| `--charter-scope` | No | In/out boundaries — geography / segment / horizon, one line. Persisted to `binding.json::charter.scope`. Resolved interactively in Step 2.5 when omitted. |
| `--open-themes` | No | Pipe-separated seed-theme backlog (e.g. `"high-risk systems\|conformity assessment\|GPAI"`). Persisted to `binding.json::topic_lineage.open_themes[]`; surfaces as the candidate menu for the first research question. Resolved interactively in Step 2.5 when omitted. |
| `--no-charter` | No | Skip the Step 2.5 charter interview AND the Step 5 first-question on-ramp. Use for automation / a flag-only init. The charter fields fall through to `""` and `open_themes[]` to `[]` (a complete, schema-valid 0.1.4 binding either way). |
| `--no-prelim-search` | No | Keep the Step 2.5 charter interview but skip its optional preliminary scoping scan (stays offline). Same semantics as `knowledge-plan --no-prelim-search`. |

If `--knowledge-slug` or `--knowledge-title` is missing, ask the user once with AskUserQuestion (call `ToolSearch(query="select:AskUserQuestion")` to load the schema if needed). Do not invent slugs or titles silently.

## Workflow

### 0. Pre-flight: required plugins

cogni-knowledge is a thin orchestrator over `cogni-wiki` (the inverted pipeline forks the agents it needs locally — see `agents/`); without it, every subsequent step would fail mid-workflow with an opaque `Skill` tool error rather than a clean abort. Probe the cogni-wiki sibling plugin dir before touching anything else. The probe tries both the dev-repo sibling layout (`../<plugin>/skills/...`) and the marketplace cache layout (`../../<plugin>/<version>/skills/...`) so a marketplace-installed user gets the same abort as a dev-repo user:

```
probe_plugin() {
  local plugin="$1" skill="$2"
  # Dev-repo siblings (../<plugin>/skills/...)
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  # Marketplace cache (../../<plugin>/<version>/skills/...)
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If it is `no`, report the missing plugin and abort:

> cogni-knowledge requires `cogni-wiki` to be installed.
> Install via the marketplace, then retry.

Do not attempt to install or auto-recover — surface the missing dependency and let the user install it explicitly.

The same probe runs in every other `knowledge-*` skill. Setup is still the canonical gate because it creates the binding; downstream skills additionally rely on the binding's existence as a soft proxy. A user who somehow reaches a downstream skill without going through setup gets the same clean abort.

### 1. Resolve the knowledge root

1. If `--knowledge-root` was passed, use it as-is.
2. Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` relative to the current working directory — the standard cogni-plugin convention (`cogni-{plugin}/{project-slug}/`), matching `cogni-wiki/{slug}/`.
3. If `<knowledge_root>/.cogni-knowledge/binding.json` already exists: read it, report the existing knowledge_slug/title/wiki_path, and stop. Do not overwrite.

### 2. Pre-flight: wiki vs no wiki

Check `<knowledge_root>/.cogni-wiki/config.json`:

- **Exists** → a wiki is already set up at this path. Skip Step 3 (no need to dispatch `wiki-setup`). Treat the existing wiki as the binding's target.
- **Does not exist** → Step 3 will dispatch `cogni-wiki:wiki-setup`.

If `<knowledge_root>` exists but contains foreign files (no `.cogni-wiki/`, but non-empty subdirs that are not the standard cogni-wiki layout — `raw/`, `wiki/`, `assets/`), abort: "path exists but is not a wiki — choose a different `--knowledge-root` or move the existing files."

### 2.5. Charter framing + language defaults (the single setup interview)

This step steers the base: it captures a coarse **charter** (what the base is about, who reads it, where its boundaries are, which themes to cover first) **and** the default `market` + `output_language`, in **one coherent interview** rather than two disjoint prompts. The charter is the base-level analog of `knowledge-plan`'s per-question topic-framing (`references/topic-framing.md`); the full base-scoped playbook + question bank lives in `${CLAUDE_PLUGIN_ROOT}/references/charter-framing.md`. Read it once here.

Why a charter: in cogni-knowledge one base accumulates *many* topics over time, so the base needs a coarser charter while each `knowledge-plan` run keeps the finer per-question framing that already exists. The charter is persisted to `binding.json::charter` (schema 0.1.4) and seed themes to `topic_lineage.open_themes[]`; `knowledge-plan` Step 0.4 then inherits the charter as grounding so every future run is anchored to the base's domain.

**Engage / skip** (mirror topic-framing's contract — *this base must be steered*, so default-on with an explicit opt-out):

- **Skip** the charter interview when `--no-charter` is passed, **or** the run is non-interactive (all of `--charter-domain`/`--charter-audience`/`--charter-scope` supplied via flags). In the skip case, charter fields fall through to their flags (else `""`) and `open_themes[]` to `--open-themes` (else `[]`) — still a complete schema-0.1.4 binding.
- **Engage** otherwise (the default on an interactive run). Say so in one sentence before asking: *"Let me frame this knowledge base before we set it up — a few quick questions so every future research run is anchored to it."*

When engaged, run the four framing moves (port the **shape** from `references/charter-framing.md`):

1. **Ground** (optional, ≤50 KB, no writes outside the base). Ask for any grounding material: *"Any grounding material for this knowledge base? (a path / pasted text / a URL / 'no context')"*. When the user supplies a path, read conservatively (`Glob` the top-level shape, `Read` the manifest/README, sample 2–3 files; cap ~50 KB). No network here; no writes.
2. **Scan** (optional, fail-soft). Unless `--no-prelim-search` was passed, issue **2–3 broad `WebSearch` queries** on the domain to ground the seed-theme suggestions; review the top snippets for the dominant themes/organizations/terminology. **Any error → skip silently** and fall through to pure reasoning. The scan never blocks framing.
3. **Sharpen** — one `AskUserQuestion` turn (call `ToolSearch(query="select:AskUserQuestion")` to load the schema if needed), ≤4 skippable, **base-scoped** questions. Fold the market/language questions into this same turn (or a single immediate follow-up turn if the four-question budget is full):
   - **Domain** — *"In one sentence, what is this knowledge base about?"* (free text → `charter.domain`)
   - **Audience** — *"Who reads the syntheses this base produces?"* (offer the audience option list from `charter-framing.md` → `charter.audience`)
   - **Scope** — *"What's in and out of scope? (geography / segment / horizon)"* (free text → `charter.scope`)
   - **Seed themes** — *"Which 3–6 themes should this base cover first?"* (multiSelect over scan-derived suggestions + Other → `open_themes[]`)
   - **Market** (only if `--market` not passed): the supported codes; default `dach` *(Recommended)*.
   - **Output language** (only if `--output-language` not passed): option 1 is the market's `default_output_language` *(Recommended)*, option 2 `en`, plus 1–2 common others; "Other" takes a two-letter code.
   Every question is skippable — "I'll decide later" drops to the safe default (charter field → `""`, market → `dach`, language → the market's `default_output_language`, no seed themes).

Resolve the **market / language** default exactly as before (the precedence and helper are unchanged):

1. If **both** `--market` and `--output-language` were passed, use them as-is.
2. Otherwise derive the suggested language default from the market via the canonical workspace helper (the same path `knowledge-plan` uses for `candidate_domains`):
   ```
   python3 "${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ | head -1)}/scripts/get-market-config.py" --plugin research --market <market-or-default-dach>
   ```
   Read `data.default_output_language` from the envelope (e.g. `dach`→`de`, `fr`→`fr`, `eu`→`en`).
3. Surface market + language inside the sharpen turn above (skippable → market `dach`, language = market's `default_output_language`).

Carry the resolved `charter.{domain,audience,scope}`, `open_themes[]`, `market`, and `output_language` into Step 4.

**Writer-quality knobs (`prose_density`, `tone`, `citation_format`, `target_words`) are flag-or-default — NOT prompted here.** Each has a safe default and is primarily a per-run choice on `knowledge-plan`, so the interview stays scoped to charter + market/language; the four knobs persist from their flags when passed, else the script-side defaults (`standard`/`objective`/`ieee`/`4000`). Overridable per run via `knowledge-plan --prose-density|--tone|--citation-format|--target-words`. Carry any passed flags into Step 4.

### 3. Dispatch `cogni-wiki:wiki-setup` (only if no wiki exists)

```
Skill("cogni-wiki:wiki-setup",
      args="--name '<knowledge-title>' --wiki-root <knowledge_root> [--description ...] [--publisher-base-url ...] --skip-prefill-prompt")
```

Pass `--skip-prefill-prompt` because cogni-knowledge has its own opinionated seeding (the user's first `knowledge-plan` → … → `knowledge-finalize` run will seed the wiki domain-specifically — layering canonical foundations on top would clutter the base). The user can still run `cogni-wiki:wiki-prefill` later.

On `wiki-setup` failure, surface the error verbatim and stop. The binding is not written if the wiki was not created.

### 4. Write the binding manifest

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py init \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --knowledge-title "<knowledge_title>" \
    --wiki-path <knowledge_root> \
    --market <resolved market> \
    --output-language <resolved output_language> \
    [--prose-density <flag>] [--tone <flag>] [--citation-format <flag>] [--target-words <flag>] \
    [--charter-domain "<resolved domain>"] [--charter-audience "<resolved audience>"] \
    [--charter-scope "<resolved scope>"] [--open-themes "<theme1|theme2|...>"]
```

`--market` / `--output-language` carry the Step 2.5 resolution into `binding.json::research_defaults` (schema 0.1.2). The four charter args carry the Step 2.5 charter interview into `binding.json::charter` + `topic_lineage.open_themes[]` (schema 0.1.4) — pass each only when resolved (a skipped/blank charter field simply omits the flag and falls through **script-side** to `""`; `framed_at` is stamped only when any charter field is non-empty). The four writer-quality flags are likewise passed only when the user supplied them; **omitted flags fall back script-side** to the `DEFAULT_RESEARCH_DEFAULTS` block (`dach`/`en`/`standard`/`objective`/`ieee`/`4000`), so a plain `init` still writes a complete schema-0.1.4 binding (`research_defaults` complete, `charter` all-`""`, `open_themes` `[]`). The script returns the standard `{success, data, error}` envelope. On failure (e.g. binding already exists), surface the error. The script refuses to overwrite an existing binding — Step 1's pre-flight should have caught that, but the script is the second line of defence.

### 5. Final summary + first-question on-ramp

First print a short summary, ≤ 8 lines:

- Knowledge base path (absolute)
- Knowledge slug and title
- Wiki path (`<knowledge_root>` — they are the same in the default layout)
- Binding file path (`<knowledge_root>/.cogni-knowledge/binding.json`)
- Charter (when set): domain `<charter.domain>`, audience `<charter.audience>`, scope `<charter.scope>`
- Defaults: market `<resolved market>`, output language `<resolved output_language>`, density `<prose_density>`, tone `<tone>`, citations `<citation_format>`, target `<target_words>`w (all inherited by `knowledge-plan`; overridable per run)

Do not print the full binding JSON in the summary — point at the file path and let the user inspect it if they want.

**Then the first-question on-ramp.** A fresh base is empty — the value of setup is leaving the user with a *framed first research question*, not just a binding. Replace the old static "suggested next action" line with one interactive prompt:

- **Skip the prompt entirely** on a non-interactive / `--no-charter` (flag-only) run — print the static guidance instead (the bullet below) and stop. Automation-safe: setup never blocks waiting for input it can't get.
- **Otherwise** ask once with `AskUserQuestion`: *"Frame your first research question now?"*. When `open_themes[]` is non-empty, surface the seed themes as the selectable options so the user picks **which one** to frame first (single select; default = the first seed theme); always include a "No — pick later" option.
  - **A theme is chosen (Yes)** → chain straight into the existing per-question framing:
    ```
    Skill("cogni-knowledge:knowledge-plan",
          args="--knowledge-slug <slug> --topic '<chosen seed theme>' --frame")
    ```
    `--frame` forces `knowledge-plan`'s Step 0.4 per-question topic-framing (which now inherits this base's charter as grounding), so the user leaves with a sharpened first question + `plan.json` + `.metadata/framing.md`. **The chain stops at `plan`** — `knowledge-curate` → `knowledge-fetch` → … each cost web/tokens, so they stay the user's explicit per-run decision. Do **not** auto-run any phase past `plan`.
  - **No — pick later** → print the static next-action guidance below, listing `open_themes[]` as the candidate menu.

Static next-action guidance (printed on skip / "pick later"):

> Next: `cogni-knowledge:knowledge-plan --knowledge-slug <slug> --topic '<one of your seed themes>'`, then `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. Seed themes for this base: `<open_themes joined by ', '>` (or "none — pick any topic" when empty).

## Edge cases

- **Wiki exists but is for a different domain.** Step 2 detects the existing wiki and re-uses it. This is intentional — a user may want to layer a knowledge base onto an existing wiki. The binding records only `wiki_path`; the wiki's own slug is read live from `<wiki_path>/.cogni-wiki/config.json` whenever a consumer needs it, so a wiki rename never causes the binding to drift.
- **`--knowledge-slug` collides with a sibling directory.** Step 1's binding-existence check protects against double-init; if the sibling is a non-wiki directory, Step 2's foreign-files check fires.
- **`wiki-setup` crashes mid-run.** No binding has been written. Surface the wiki-setup error; the user can re-run after fixing whatever wiki-setup complained about.

## Out of scope

- Does NOT write wiki pages — that is `cogni-wiki:wiki-ingest`'s job (transitively via `knowledge-ingest`).
- Does NOT pre-fill the wiki with cogni-wiki foundations — `--skip-prefill-prompt` is set deliberately.
- Does NOT configure source mode — that happens during `knowledge-plan`, where the topic is known.
- Records only the knowledge-base **defaults** (`market`/`output_language` + the four writer-quality knobs `prose_density`/`tone`/`citation_format`/`target_words`) in `binding.json::research_defaults` (Step 2.5, schema 0.1.2). The per-run choice still lives in `knowledge-plan` — a single plan can override any base default with its own matching flag (e.g. an English report about a German market, or an `executive`-density draft on a `standard`-default base).
- The **charter** (Step 2.5, schema 0.1.4) is **domain / audience / scope / seed-themes only** — the coarse base steering. It deliberately does NOT carry the writer-quality knobs (those stay per-run on `knowledge-plan`) and is NOT a per-question prompt: the finer per-research-question framing remains `knowledge-plan` Step 0.4's job, which inherits this charter as grounding.
- Does NOT run any pipeline phase past `plan`. The Step 5 on-ramp chains at most into `knowledge-plan --frame` (cheap, no-web decomposition); `knowledge-curate` onward stay the user's cost-bearing per-run decision.

## Output

- A directory at `<knowledge_root>/` containing:
  - `.cogni-wiki/config.json` (from `cogni-wiki:wiki-setup`)
  - `.cogni-knowledge/binding.json` (from `knowledge-binding.py init`)
  - Standard wiki layout (`raw/`, `wiki/`, `assets/`, etc.)

No files are written outside `<knowledge_root>/`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — what this skill owns vs. delegates (incl. §"How `Skill(...)` blocks are written")
- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — why wiki-first
- `cogni-wiki:wiki-setup` SKILL.md — Step 3 contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
