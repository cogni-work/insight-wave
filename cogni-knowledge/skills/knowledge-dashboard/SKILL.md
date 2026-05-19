---
name: knowledge-dashboard
description: "Render an HTML dashboard for a bound cogni-knowledge base — dispatches cogni-wiki:wiki-dashboard against the bound wiki and writes a knowledge-overlay.md sidecar that lists deposited research projects and the latest lint-audit claim_drift count. Use this skill whenever the user says 'show the dashboard for my <slug> base', 'knowledge dashboard', 'visualize my eu-ai-act knowledge base', 'render the knowledge base as HTML', 'knowledge-dashboard <slug>'. The sidecar makes the binding's contribution visible alongside the wiki's own dashboard."
allowed-tools: Read, Write, Bash, Glob, Skill
---

# Knowledge Dashboard

Render a self-contained HTML dashboard for a bound cogni-knowledge base. This skill is a thin composition over `cogni-wiki:wiki-dashboard` — it dispatches the upstream dashboard against the bound wiki, then writes one extra markdown file (`knowledge-overlay.md`) that surfaces what `binding.json` knows but `wiki-dashboard` does not: which research projects have contributed, and what the latest lint audit said about claim drift.

The cogni-knowledge value-add over a raw `cogni-wiki:wiki-dashboard` dispatch is:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user.
2. **Knowledge overlay sidecar** — a markdown file co-located with `wiki-dashboard.html` that captures the binding view (deposited projects table + latest lint-audit summary).

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary — this skill writes only one file (`knowledge-overlay.md`); everything else is the upstream dashboard's responsibility.

## When to run

- User asks for a dashboard or HTML view of a bound knowledge base
- After several `knowledge-research` deposits, to see the shape of the accumulated wiki
- Before sharing a knowledge base with a colleague — the dashboard + overlay are both single files

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`. Direct wiki users without a binding should run `cogni-wiki:wiki-dashboard` directly.
- The wiki is empty — `cogni-wiki:wiki-dashboard` already refuses; the overlay still renders honestly with zero deposits.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `<cwd>/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `<cwd>/<knowledge-slug>/`. |
| `--graph` | No | Pass-through to `cogni-wiki:wiki-dashboard --graph`. Values: `no` (default) / `pass1` / `yes`. |
| `--open` | No | Pass-through to `cogni-wiki:wiki-dashboard --open`. Values: `yes` / `no` (default). |

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
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract `wiki_path`, `knowledge_slug`, `knowledge_title`, `research_projects[]`, `created` from the binding. Validate `binding.knowledge_slug == --knowledge-slug`.

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort.

### 1. Dispatch `cogni-wiki:wiki-dashboard`

```
Skill("cogni-wiki:wiki-dashboard",
      args="--wiki-root <wiki_path> [--open <val>] [--graph <val>]")
```

`wiki-dashboard` accepts `--wiki-root` (see `cogni-wiki/skills/wiki-dashboard/SKILL.md:28`). Forward `--graph` and `--open` only if the caller passed them — let the upstream defaults apply otherwise.

If the upstream dispatch fails, surface its error verbatim and stop. Do NOT write the overlay sidecar — a half-rendered dashboard view is worse than none.

### 2. Compose the knowledge overlay sidecar

Write `<wiki_path>/knowledge-overlay.md` (overwrite on rerun — the contents are deterministic from the binding + latest lint audit, so re-running produces identical bytes if nothing has changed).

The overlay is co-located with `wiki-dashboard.html` so the user opens both from the same directory. In the default `knowledge-setup` layout, `<knowledge_root>` and `<wiki_path>` are the same directory (see `knowledge-setup/SKILL.md` §"Edge cases"), so the sidecar also lives at the knowledge-base root.

Contents:

```markdown
# Knowledge overlay — <knowledge_title> (<knowledge_slug>)

Created <created>. Wiki: <wiki_path>.

## Deposited research projects

| slug | deposited_at | report_source | report_path |
|------|--------------|---------------|-------------|
| <slug-1> | <YYYY-MM-DD> | <web|local|wiki|hybrid> | <abs path> |
| ...      | ...          | ...                     | ...         |

(Or, if `research_projects[]` is empty:)
> No research projects deposited yet — run `/cogni-knowledge:knowledge-research --knowledge-slug <slug> --topic '...'` to add the first.

Sort rows by `deposited_at` descending (newest first).

## Claim verification heatmap

(Best-effort summary from the freshest audit file under `<wiki_path>/wiki/audits/lint-*.md`. If audit files exist, render:)
Latest lint audit (<audit-filename>): <N> claim_drift findings.

(If no audit files exist:)
No lint audits yet — run `cogni-wiki:wiki-lint` to populate.
```

Counting `claim_drift` findings: glob `<wiki_path>/wiki/audits/lint-*.md`, sort by filename (ISO-date suffix), take the last one. Use a small bash + python one-liner to count lines matching the `claim_drift` warning marker — exact format depends on `lint_wiki.py`'s output, which is documented at `cogni-wiki/skills/wiki-lint/SKILL.md` (the warning class is the literal string `claim_drift`). A six-line python via `python3 -c` is sufficient — count `claim_drift` substring matches in the audit body. Section is never absent; the empty-state line is informative.

### 3. Print a short summary

≤ 5 lines:

- `wiki-dashboard.html` → `<wiki_path>/wiki-dashboard.html`
- `knowledge-overlay.md` → `<wiki_path>/knowledge-overlay.md`
- Deposited projects: `<count>`
- Latest claim_drift findings: `<N>` (or `no lint audits yet`)
- Open both with `open <wiki_path>/wiki-dashboard.html` and `open <wiki_path>/knowledge-overlay.md`

## Edge cases

- **Empty `research_projects[]`.** Section 2's table is replaced with the empty-state line; the rest of the overlay renders normally.
- **No `wiki/audits/` directory.** Treat as "no lint audits yet" — section 2 still renders.
- **Audit file present but no `claim_drift` markers.** Report `0 claim_drift findings`.
- **Upstream `wiki-dashboard` fails after partial render.** Step 1 already aborted; the overlay is not written.

## Out of scope

- **Running `wiki-lint` from this skill.** The heatmap reads whatever audits already exist on disk. Running lint is a separate user-driven action (it costs tokens; the dashboard is meant to be cheap and frequent).
- **Injecting the binding overlay into `wiki-dashboard.html` itself.** The upstream dashboard is wiki-general; layering knowledge-base-specific content into its HTML would couple the two. The sidecar approach keeps the contracts clean.
- **Modifying the binding.** Read-only by design.
- **Writing anywhere outside `<wiki_path>/`.** The overlay is the only file this skill writes, and it lives inside the bound wiki's directory.

## Output

- A single HTML file at `<wiki_path>/wiki-dashboard.html` (rendered by `cogni-wiki:wiki-dashboard`).
- When `--graph` ∈ {`pass1`, `yes`}: a second HTML at `<wiki_path>/wiki-graph.html` (rendered by `cogni-wiki:wiki-dashboard`).
- A markdown sidecar at `<wiki_path>/knowledge-overlay.md` (written by this skill).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — the delegation boundary
- `cogni-wiki:wiki-dashboard` SKILL.md — the upstream contract
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
