---
name: knowledge-setup
description: "Bootstrap a cogni-knowledge knowledge base — a cogni-wiki + a binding manifest that records every research project deposited into it. Creates the wiki via cogni-wiki:wiki-setup if it does not exist, then writes .cogni-knowledge/binding.json. Use this skill whenever the user says 'set up a knowledge base', 'start a knowledge base on X', 'bootstrap a wiki-first research base', 'new knowledge base for X', 'create a knowledge base', or 'wiki-first research setup'. After setup, run the inverted pipeline (knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → knowledge-compose → knowledge-verify → knowledge-finalize) to deposit research syntheses into the base."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
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
    --wiki-path <knowledge_root>
```

The script returns the standard `{success, data, error}` envelope. On failure (e.g. binding already exists), surface the error. The script refuses to overwrite an existing binding — Step 1's pre-flight should have caught that, but the script is the second line of defence.

### 5. Final summary

Print a short summary, ≤ 8 lines:

- Knowledge base path (absolute)
- Knowledge slug and title
- Wiki path (`<knowledge_root>` — they are the same in the default layout)
- Binding file path (`<knowledge_root>/.cogni-knowledge/binding.json`)
- Suggested next action: `cogni-knowledge:knowledge-plan --knowledge-slug <slug> --topic '...'`, then `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`

Do not print the full binding JSON in the summary — point at the file path and let the user inspect it if they want.

## Edge cases

- **Wiki exists but is for a different domain.** Step 2 detects the existing wiki and re-uses it. This is intentional — a user may want to layer a knowledge base onto an existing wiki. The binding records only `wiki_path`; the wiki's own slug is read live from `<wiki_path>/.cogni-wiki/config.json` whenever a consumer needs it, so a wiki rename never causes the binding to drift.
- **`--knowledge-slug` collides with a sibling directory.** Step 1's binding-existence check protects against double-init; if the sibling is a non-wiki directory, Step 2's foreign-files check fires.
- **`wiki-setup` crashes mid-run.** No binding has been written. Surface the wiki-setup error; the user can re-run after fixing whatever wiki-setup complained about.

## Out of scope

- Does NOT write wiki pages — that is `cogni-wiki:wiki-ingest`'s job (transitively via `knowledge-ingest`).
- Does NOT pre-fill the wiki with cogni-wiki foundations — `--skip-prefill-prompt` is set deliberately.
- Does NOT configure source mode — that happens during `knowledge-plan`, where the topic is known.

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
