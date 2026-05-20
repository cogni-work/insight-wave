---
name: knowledge-resume
description: "Show status of a cogni-knowledge base — knowledge slug, bound wiki path, deposited research projects, wiki health verdict, and the recommended next action. Delegates structural integrity to cogni-wiki:wiki-resume (which runs wiki-health automatically). Use this skill whenever the user says 'resume the knowledge base', 'knowledge resume', 'knowledge status', 'where was I with the eu-ai-act base', 'what's in my knowledge base', 'show me the knowledge base overview'. Proactively after a long gap between sessions, or right after knowledge-setup or knowledge-research."
allowed-tools: Read, Bash, Glob, Skill
---

# Knowledge Resume

Give the user a fast, grounded status view of a cogni-knowledge base so they know what is inside and what the right next action is. This skill is **read-only** with respect to the binding and the wiki — it never writes. The only side effect is that the upstream `cogni-wiki:wiki-resume` may log its health-check invocation in `wiki/log.md`.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember that wiki health checks belong to cogni-wiki, not to cogni-knowledge.

## When to run

- User asks for status, overview, or "where was I" on a knowledge base
- User returns after a gap and wants orientation
- Right after `knowledge-setup` or `knowledge-research` finished, to confirm the deposit and suggest the next step
- Proactively when a session opens in a directory containing `.cogni-knowledge/binding.json`

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base to resume. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--verbose` | No | Forward to `cogni-wiki:wiki-resume --verbose`. Includes recent log activity verbatim. |

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

Resume is read-only with respect to disk, but it still dispatches `cogni-wiki:wiki-resume` and would fail mid-skill if cogni-wiki were missing. The probe gives the user the same clean signal every other `knowledge-*` skill emits.

### 1. Resolve the knowledge root and read the binding

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = <cwd>/<knowledge-slug>/`.

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`, `research_projects[]`, `created`, `topic_lineage`. (The bound wiki's own slug, if needed for display, comes live from `<wiki_path>/.cogni-wiki/config.json` — never cached in the binding.)

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

### 2. Delegate to `cogni-wiki:wiki-resume`

```
Skill("cogni-wiki:wiki-resume", args="--wiki-root <wiki_path> [--verbose]")
```

`wiki-resume` already runs `wiki-health` automatically (see `cogni-wiki/skills/wiki-resume/SKILL.md` — "As of v0.0.27, resume also runs wiki-health automatically"). Do not run `wiki-health` separately; that would log a noisy second invocation.

Capture the wiki-resume output. Look for:
- The `wiki/context_brief.md` summary (auto-rebuilt by `wiki-ingest`)
- Entry count and recent log activity
- Wiki health verdict (broken wikilinks, missing frontmatter, stale drafts)

### 3. Compose the cogni-knowledge summary

Print a ≤ 12-line summary that layers the binding onto the wiki status:

- **Knowledge base.** `<knowledge_title>` (`<knowledge_slug>`), created `<created>`
- **Wiki path.** `<wiki_path>` — wiki health verdict from Step 2 (one line: "OK" / "N issues — see wiki-resume output above")
- **Deposited research projects.** `<count>` (list slugs + `deposited_at`, newest first; cap at 5, summarise the rest as "and N more")
- **Topic lineage.** If `covered_themes` or `open_themes` are non-empty, print them as two short lists. Else omit.
- **Next action.** Recommend based on state:
  - If `research_projects` is empty: "Run `knowledge-research --knowledge-slug <slug> --topic '...'` to deposit your first project."
  - If wiki has structural issues: "Fix structural issues first — see the wiki-resume output above. Then `knowledge-research` for more deposits or `cogni-wiki:wiki-query` to ask the base."
  - Otherwise: "Run another `knowledge-research` to keep accumulating, or `cogni-wiki:wiki-query --question '...'` to ask the base what it knows."

The full `wiki-resume` output appears verbatim above the summary so the user has the structural detail at hand; cogni-knowledge's contribution is the binding overlay.

## Edge cases

- **Binding exists but `wiki_path` no longer does.** Step 1(4) catches the missing `.cogni-wiki/config.json`. Abort with a clear message.
- **`wiki-resume` fails.** Surface its error and still print the binding section — the user benefits from at least knowing the deposit count even if the wiki status is broken.
- **`research_projects[]` references a `report_path` that no longer exists.** Do not abort; flag in the summary with "(report file missing — possibly archived)" next to that entry. The binding is the durable record; the on-disk research project is incidental.

## Out of scope

- Does NOT run `wiki-health` directly — `wiki-resume` already does.
- Does NOT run `wiki-lint` — that is a tokenful semantic pass that the user invokes deliberately, not on resume.
- Does NOT write to the binding or the wiki — read-only.

## Output

A status block printed to the user. No files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md`
- `cogni-wiki:wiki-resume` SKILL.md
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
