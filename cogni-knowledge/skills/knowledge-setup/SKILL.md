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
- User wants to **re-steer an existing base** — the domain sharpened, the audience shifted, a new seed theme appeared — via `--reframe` (re-runs the charter interview against the existing binding; no hand-editing `binding.json`)

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
| `--reframe` | No | **Re-steer an existing base** instead of bootstrapping a new one. Re-runs the Step 2.5 charter interview against the **existing** binding and writes the updated charter in place via `knowledge-binding.py set-charter` (a **partial** update — only the fields you change). Inverts Step 1's pre-flight: requires an existing binding and aborts when none is found. Skips wiki setup (Steps 2/3), the `init` call (Step 4), and the Step 5 first-question on-ramp. The charter's data shape (schema 0.1.4) is unchanged. |

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
3. **Binding pre-flight — direction depends on the mode:**
   - **Normal (bootstrap) mode** (no `--reframe`): if `<knowledge_root>/.cogni-knowledge/binding.json` already exists, read it, report the existing knowledge_slug/title/wiki_path, and stop. Do not overwrite.
   - **`--reframe` mode** (re-steer): the inverse. The binding **must** exist. If `<knowledge_root>/.cogni-knowledge/binding.json` is **missing**, abort cleanly: *"nothing to re-frame — run `knowledge-setup` (without `--reframe`) to bootstrap this base first."* When it exists, read it, validate its `knowledge_slug` matches `--knowledge-slug` (mismatch → abort), then **jump straight to Step 2.5** — skip the wiki pre-flight / dispatch (Steps 2/3) and the `init` call (Step 4); the wiki and binding already exist, so re-frame only rewrites the charter via `set-charter`.

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

**`--reframe` mode — re-steer an existing charter.** When invoked with `--reframe`, this same interview runs against the **existing** binding instead of a fresh one:

- First **read the current charter** so the user sees what is set today and only changes what shifted:
  ```
  python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read --knowledge-root <knowledge_root>
  ```
  Pull `binding.charter.{domain,audience,scope}` and `binding.topic_lineage.open_themes[]`.
- **Pre-populate the AskUserQuestion defaults** from those current values (the sharpen turn shows "currently: `<domain>`" so an unchanged field is one keystroke to keep).
- Frame the seed-themes question as *"Any **additional** seed themes to add?"* — `set-charter` **union-merges** `--open-themes` into the existing backlog (it appends; it never clobbers or removes). Dropping a seed theme stays a hand-edit for now.
- Say so in one sentence first: *"Let me re-frame this knowledge base — I'll show you what's set today, change only what shifted."*
- The market / language resolution below is **not** re-run in `--reframe` mode (those live in `research_defaults`, not the charter; re-framing steers domain/audience/scope/themes only). Skip straight to writing the charter in Step 4's `--reframe` branch.

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

### 3.5 Seed the curated wiki-output layout (new wikis only)

Run this step **only on the fresh-wiki branch** — when Step 3 just dispatched
`cogni-wiki:wiki-setup`. **Skip it** when Step 2 re-used an existing wiki, and in
`--reframe` mode (which already skips Steps 2–3). It turns the
`schema_version 0.0.9` layout the contract below declares into the actual seeded
shape, so a NEW wiki opens with a curated MAP front door (`wiki/index.md`)
over its per-type sub-indexes — with the overview narrative folded into the
`wiki/index.md` intro (where `knowledge-finalize` maintains it via
`overview_update.py narrative-splice --target-file index.md`) and `wiki/overview.md`
reduced to a stub holding the `## Recent syntheses` list — instead of the
unstructured root files `wiki-setup` leaves. All edits are CK-side; the vendored engine scripts are read-only — this
step *calls* them, never edits them.

**Resolve the wiki-ingest scripts dir** (Step 3 dispatches the skill but resolves
no script dir, so resolve it here, mirroring `knowledge-finalize` Step 0):

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest config_bump.py) \
  || abort "cogni-wiki wiki-ingest scripts not found"
```

**(a) Seed the six per-type sub-index stubs via the canonical renderer.** Call
`sub_index.py render` per type — it writes each `wiki/<type>/index.md` with its
`<!-- MACHINE-OWNED:<TYPE>-INDEX -->` ownership marker under the wiki lock, so the
renderer treats it as a machine-owned upsert target on the first
`knowledge-finalize`. Do **not** hand-author the markers — that would duplicate
`sub_index.py`'s logic, which the no-duplicate-upstream-logic convention forbids:

```
for t in concepts entities people sources questions syntheses; do
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type "$t" --wiki-root <knowledge_root> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    || abort "sub_index render failed for $t"
done
```

**(b) Seed the curated root files — `wiki/index.md` (curated MAP front door,
overview narrative in its intro), `wiki/overview.md` (stub), and the
knowledge-native `SCHEMA.md`.** Overwrite all three `wiki-setup` seeds via Bash
heredocs (since this skill's `allowed-tools` carries no `Write` tool — the seed
mechanism is `cat > … <<'EOF'`, not a `Write` call). All bodies use a **quoted**
heredoc delimiter (`<<'EOF'`) — they need no shell expansion, and quoting keeps a
`<knowledge-title>` that happens to contain a `$` or backtick from being expanded
or executed. Substitute `<knowledge-title>` and — on the `_Created:` subtitle
line **only** — today's date `YYYY-MM-DD` **textually** before running (the
quoted delimiter means the shell will not expand a `$(date)` here — the log
heredoc in (c) is the one place that stays unquoted precisely because it *does*
rely on `$(date)`). Never replace-all on `YYYY-MM-DD`: the SCHEMA.md seed's
audits/ tree line carries `lint-YYYY-MM-DD.md` / `health-YYYY-MM-DD.md` as
filename **patterns** that must stay literal. The in-body `<knowledge-root>/`
tree root in the SCHEMA.md seed likewise stays **literal** — it is a generic
placeholder in the deposited contract, not a substitution token:

- **`wiki/index.md`** becomes the curated **portal front door** carrying the
  `MACHINE-OWNED:OVERVIEW-NARRATIVE` block **in its intro** (the narrative now
  lives here, not in `wiki/overview.md`) plus the `MACHINE-OWNED:ROOT-INDEX`
  ownership marker and the curated-map intro line. `knowledge-finalize`'s
  `root_index.py render` upserts one `## <theme>` section per theme as research
  lands (each a count-link to its per-type sub-indexes, no per-page bullets), and
  `overview_update.py narrative-splice --target-file index.md` refreshes the
  OVERVIEW-NARRATIVE inner. The seed carries no `## <theme>` sections yet (none
  exist) and no per-page bullet line, so the vendored `strip_seed_placeholder`
  has nothing to strip. The intro line matches `root_index.py`'s so the first
  finalize render is a no-op on the intro.
- **`wiki/overview.md`** is re-seeded as a thin **stub** that points at the
  curated map: it no longer carries the `OVERVIEW-NARRATIVE` block (that moved to
  `index.md`'s intro). It remains the home of the `## Recent syntheses` running
  list that `knowledge-finalize`'s `overview_update.py recent-bullet` appends —
  the only surface still written there.
- **`SCHEMA.md`** (at the wiki ROOT, `<knowledge_root>/SCHEMA.md` — one level
  above the `wiki/` page tree the two seeds above target; that is where
  `wiki-setup` copies its generic template) is replaced with the
  **knowledge-native contract**: the generic template declares directories the
  knowledge pipeline never writes (`decisions/`, `meetings/`, `notes/`) while
  omitting the knowledge-native surfaces (`sources/`, `questions/`, `people/`,
  `interviews/`, `audits/`) — so without this overwrite every new base violates
  its own self-describing contract. The seed's directory set is pinned to the
  `sub_index.py` REGISTRY's six indexed types plus the on-disk
  `interviews/` / `audits/` / `wiki/meta/`, and it documents the
  concept-vs-entity **instance-free test** (the same rule the
  `concept-distiller` agent applies) so the contract is readable from inside
  the base. This seed is also the canonical copy `knowledge-index`'s schema
  truth-up applies to existing bases — change it here, never fork it there.

```
cat > <knowledge_root>/wiki/index.md <<'EOF'
# <knowledge-title>

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
_Overview pending — authored on the first knowledge-finalize run._
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->

<!-- MACHINE-OWNED:ROOT-INDEX -->

_Curated map of this knowledge base. Each theme below links to its per-type sub-indexes with live counts — open one to read the pages._
EOF

cat > <knowledge_root>/wiki/overview.md <<'EOF'
# Overview

_The overview narrative now lives in the curated map intro at [index.md](index.md). This page keeps the running `## Recent syntheses` list._
EOF

cat > <knowledge_root>/SCHEMA.md <<'EOF'
# SCHEMA — <knowledge-title>

_Created: YYYY-MM-DD · knowledge-native contract (seeded by cogni-knowledge)_

This file is the contract for how this knowledge base is structured. It lives
inside the base (not inside the plugin) so the base stays self-describing even
if cogni-knowledge is uninstalled or replaced.

## Directory layout

    <knowledge-root>/
    ├── SCHEMA.md             This file — conventions and contract
    ├── raw/                  Immutable source documents (papers, transcripts, data)
    ├── assets/               Attachments referenced from pages
    ├── wiki/
    │   ├── index.md          Curated MAP front door (overview narrative + theme map)
    │   ├── overview.md       Stub — holds the running `## Recent syntheses` list
    │   ├── meta/             Control files: log.md, context_brief.md, open_questions.md
    │   ├── concepts/         type: concept — instance-free ideas, frameworks, mechanisms
    │   ├── entities/         type: entity — named orgs, laws, products, programs
    │   ├── people/           type: person — named humans (the Who facet)
    │   ├── sources/          type: source — ingested bodies with pre-extracted claims
    │   ├── questions/        type: question — research-question nodes with answer claims
    │   ├── syntheses/        type: synthesis — finalized research deposits
    │   ├── interviews/       type: interview — standalone interview deposits
    │   └── audits/           lint-YYYY-MM-DD.md / health-YYYY-MM-DD.md reports
    ├── .cogni-wiki/          Engine metadata (config.json, ingest queue)
    └── .cogni-knowledge/     Binding manifest + fetch cache (which research
                              projects fed this base)

The six indexed types (concepts, entities, people, sources, questions,
syntheses) each carry a machine-owned `index.md`
sub-index; `interviews/` and `audits/` are real on disk but not sub-indexed.
The generic wiki directories this pipeline never writes (`decisions/`,
`meetings/`, `notes/`, legacy flat `pages/`) are intentionally absent — one
appearing here was hand-added and sits outside the pipeline contract.

## Types — what goes where

- **concept** — a reusable, instance-free idea: a framework, mechanism,
  obligation, rule, regime, or discipline describable without naming one
  specific instance. **A concept title MUST be instance-free.** Test: if the
  title only makes sense as one organization's thing, it is an instance ⇒
  `entity`, never `concept`.
  The reusable idea behind an instance may still earn its own concept page.
- **entity** — a named instance: an organization, law, product, program,
  facility, team, service offering, or initiative — even one whose name
  sounds abstract.
- **person** — a named human (the Who facet); named humans live here, never
  in `entities/`.
- **source** — an ingested source body; its `pre_extracted_claims:`
  frontmatter is what drafts cite and the verifier scores against.
- **question** — one node per research sub-question; links its answering
  sources and may carry citable `answer_claims:`.
- **synthesis** — a finalized, verified research deposit (or filed-back query
  answer); cites its wiki provenance.
- **interview** — a standalone interview deposit.

Every page's frontmatter `type:` MUST match the directory it lives in.

## Linking

- `[[page-slug]]` for wiki pages — slug-only, no path; slugs are globally
  unique and resolve to their per-type directory.
- Standard markdown links for external URLs and `raw/` files.
- A forward `[[link]]` implies a prose reverse link on the target page
  (rule `R1_bidirectional_wikilink` — lint reports missing reverses).
  Two exemptions: synthesis-page `wiki://` citations need no reverse link
  (`R2_synthesis_wiki_source`), and audit reports are terminal on both ends
  (`R3_audit_report`). Lint findings cite these rule IDs.

## Golden rules

1. Claude writes the wiki; the user curates the raw sources.
2. Every query reads the wiki — never answers from memory.
3. Citations required — claims on pages trace to `raw/` files or URLs.
4. Append-only log (`wiki/meta/log.md`) — recorded, never rewritten.
EOF
```

**(c) Move the control log under `wiki/meta/`.** Create the meta dir and seed
`wiki/meta/log.md` **directly** — not via `control-path.py log`: the direct
write keeps the seed self-contained (no resolver round-trip), and the resolver
now defaults a file absent from both layouts to `wiki/meta/` anyway, so the
direct seed and the canonical resolution agree.
`_knowledge_lib.meta_dir(<knowledge_root>)` is definitionally
`<knowledge_root>/wiki/meta`. This heredoc alone uses an **unquoted** delimiter
(`<<EOF`) so the shell expands `$(date +%Y-%m-%d)` into the log line:

```
mkdir -p <knowledge_root>/wiki/meta
cat > <knowledge_root>/wiki/meta/log.md <<EOF
# Log

Append-only record of every wiki + knowledge operation. Never rewritten.

## [$(date +%Y-%m-%d)] setup | wiki initialized
EOF
```

**(d) Drop the folded-away flat control file.** Remove only the flat `wiki/log.md`
`wiki-setup` seeded — its content now lives at `wiki/meta/log.md` (seeded in (c)).
**Keep `wiki/overview.md`** — it is the stub re-seeded in (b) that holds the
`## Recent syntheses` list `knowledge-finalize` appends to via `overview_update.py
recent-bullet`; deleting it would make the first finalize recreate a bare default:

```
rm -f <knowledge_root>/wiki/log.md
```

**(e) Advertise `schema_version 0.0.9`.** `wiki-setup` writes `0.0.7`; bump it via
the locked `config_bump.py` (no `--schema-version` flag exists on `wiki-setup`):

```
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" \
  --wiki-root <knowledge_root> --key schema_version --set-string 0.0.9
```

After this step a fresh wiki has exactly `wiki/index.md` (the curated MAP front
door, overview narrative in its intro), `wiki/overview.md` (the seeded stub holding
the `## Recent syntheses` list), `wiki/meta/log.md`, and the six per-type
`wiki/<type>/index.md` stubs — no flat `wiki/log.md`. This invariant holds
**across** the first `knowledge-finalize`: finalize folds the overview narrative
into the `index.md` intro via `overview_update.py narrative-splice --target-file
index.md` and re-renders the curated root MAP (`root_index.py`), never regrowing a
competing root file. `knowledge-health`'s assertions for this shape
are a separate follow-up child of the epic — this step seeds the layout the check
will later assert; it does not add health expectations.

### 4. Write the binding manifest

**`--reframe` mode → `set-charter` (in-place, partial).** Skip the `init` call entirely. Write only the charter fields the user actually changed in Step 2.5, passing **only** those flags (an unchanged field is simply omitted — `set-charter` leaves it untouched; `framed_at` is re-stamped only when domain/audience/scope changes; `--open-themes` union-merges into the existing backlog):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py set-charter \
    --knowledge-root <knowledge_root> --knowledge-slug <knowledge_slug> \
    [--charter-domain "<new domain>"] [--charter-audience "<new audience>"] \
    [--charter-scope "<new scope>"] [--open-themes "<theme1|theme2|...>"]
```

`set-charter` writes the **same** schema-0.1.4 charter shape `init` does (it is a new action, not a new field — `schema_version` is not bumped) and is fail-soft on a pre-0.1.4 binding (it recreates a complete charter block). On `success: false` (e.g. nothing-to-update, or a `--knowledge-slug` mismatch), surface the error and stop. **Then go to Step 5's `--reframe` branch** (print the updated-charter summary; skip the first-question on-ramp).

**Normal (bootstrap) mode → `init`:**

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

**`--reframe` mode → updated-charter summary, no on-ramp.** Print a short confirmation of the re-framed charter (domain / audience / scope, and any seed themes added) and **stop**. Do **not** run the first-question on-ramp — a base being re-framed already has projects, so the right next step is `knowledge-resume --knowledge-slug <slug>` (to see where it stands) or `knowledge-plan --knowledge-slug <slug> --topic '...'` (to frame the next research question against the freshened charter), not a first-question chain. Point at those and end the run.

**Normal (bootstrap) mode** — the rest of this step.

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
- **`--reframe` re-steers the charter only** (domain / audience / scope / *additional* seed themes), in place via `set-charter`. It does NOT re-run wiki setup, does NOT re-run `init`, does NOT re-resolve `market`/`output_language` (those live in `research_defaults`, untouched), and does NOT run the first-question on-ramp. It only ADDS seed themes (union-merge) — removing or replacing a seed theme stays a hand-edit. The charter's data shape (schema 0.1.4) is unchanged.

## Output

- A directory at `<knowledge_root>/` containing:
  - `.cogni-wiki/config.json` (from `cogni-wiki:wiki-setup`)
  - `.cogni-knowledge/binding.json` (from `knowledge-binding.py init`)
  - `raw/`, `assets/`, and the curated `wiki/` output layout below.

No files are written outside `<knowledge_root>/`.

### Curated wiki-output layout (contract, `schema_version` 0.0.9)

The inverted pipeline deposits its knowledge into `wiki/` as a **curated,
progressively-disclosed** tree — a single front door over per-type sub-indexes,
not a flat dump:

```
wiki/
├── index.md            ← curated MAP front door (root_index.py): the overview
│                          narrative (MACHINE-OWNED:OVERVIEW-NARRATIVE) in its
│                          intro, then one `## <theme>` section per theme, each a
│                          count-link to the sub-indexes below — no per-page bullets.
├── overview.md         ← stub: points at index.md; holds the `## Recent
│                          syntheses` list (overview_update.py recent-bullet).
├── concepts/index.md   ← per-type sub-index (exists today via concepts_index.py)
├── sources/index.md    ┐
├── questions/index.md  │
├── syntheses/index.md  │ per-type machine-owned sub-indexes
├── entities/index.md   │
├── people/index.md     ┘
└── meta/               ← visible control files: log.md, context_brief.md,
                           open_questions.md
```

**`schema_version` 0.0.9 is additive and read-forward.** It adds the
first-class `person` page type (`wiki/people/`, split
out of the catch-all `entity`) to the curated layout the previous bump
declared, on top of the existing per-type-directory contract. As with the 0.0.6 (`sources/`), 0.0.7 (`questions/`), and 0.0.8
(curated layout) bumps, an older-but-post-migration wiki reads forward without
a rewrite — an absent `wiki/people/` directory on a 0.0.8 base is harmless;
**0.0.5 remains the hard-fail boundary** (pre-migration wikis still abort). This is the wiki `schema_version`, distinct
from the cogni-knowledge plugin version.

**Layout seeding for NEW wikis lands here** (Step 3.5 above) — a fresh wiki opens
in this curated shape (`wiki/index.md` curated MAP front door with the overview
narrative in its intro, `wiki/overview.md` stub, `wiki/meta/log.md`, per-type
sub-index stubs, `schema_version 0.0.9`). The **`wiki/meta/` control-file path centralization**
(flipping the canonical write target, with a legacy fallback) and the
**lint/health enforcement** of the exemption below remain follow-up children of
this epic. Until the path centralization lands, the legacy flat paths
`wiki/context_brief.md` and `wiki/open_questions.md` remain valid; `wiki/meta/` is
the seeded home for `log.md` and the **declared target** the rest of the layout
work builds toward.

**Overview ownership (landed).** The overview narrative is folded *into* the
`wiki/index.md` intro (the `MACHINE-OWNED:OVERVIEW-NARRATIVE` block lives there).
`knowledge-finalize` maintains it via `overview_update.py narrative-splice
--target-file index.md` and re-renders the curated root MAP (`root_index.py`), so
the seeded shape survives the first finalize byte-for-byte (the seeded intro line
matches `root_index.py`'s, so the first render is a no-op on the intro). So
**seeding (Step 3.5) seeds the folded shape directly**: `wiki/index.md` carries the
`OVERVIEW-NARRATIVE` block + the `ROOT-INDEX` marker, and `wiki/overview.md` is a
stub holding only the `## Recent syntheses` list. The vendored `wiki_index_update.py`
stays byte-identical — `root_index.py` is a new CK-side script (Option A).

**Per-type `index.md` is a machine-owned sub-index, not a page.** Each
`wiki/<type>/index.md` is generated, not authored, so it is **exempt from the
`entries_count`, `orphan_page`, and `reverse_link_missing` checks** — the same
structural exemption the lint/health tooling already grants `is_audit_slug`
pages (`lint-*` / `health-*`). Declaring the exemption here gives the
lint/health-enforcement follow-up a contract to point at.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — what this skill owns vs. delegates (incl. §"How `Skill(...)` blocks are written")
- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — why wiki-first
- `cogni-wiki:wiki-setup` SKILL.md — Step 3 contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
