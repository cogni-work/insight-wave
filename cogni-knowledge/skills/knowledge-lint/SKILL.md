---
name: knowledge-lint
description: "Run semantic lint on a cogni-knowledge base — surface stale pages/drafts, claim drift, and broken reverse links, optionally repairing the mechanical classes with --fix. Use this skill whenever the user says 'lint the knowledge base', 'knowledge lint', 'fix knowledge drift', 'clean up the wiki', 'repair reverse links', 'reconcile entries count', 'what's stale in my knowledge base', or wants to audit-or-repair the structural hygiene of a bound base without running the research pipeline."
allowed-tools: Read, Write, Bash, Glob
---

# Knowledge Lint

Run the **semantic lint pass** on a cogni-knowledge base — surface stale pages, stale drafts, claim drift, missing reverse links, entries-count drift, and formatting findings, and optionally repair the mechanical classes with `--fix`. This is the standalone analog of `cogni-wiki:wiki-lint`, computed **natively on the vendored `lint_wiki.py` engine** (resolved vendored-first via `resolve_wiki_scripts()`), so a Karpathy base is lintable with no `cogni-wiki` plugin installed.

Lint is **read-only by default** (a pure audit). It writes to the wiki **only** when the user passes `--fix` — and even then only the mechanical, deterministic repair classes the engine owns. This is the tokenful semantic counterpart to `knowledge-health`'s cheap structural gate: run health first, reach for lint when you want to inspect or repair drift.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember the wiki-engine boundary — cogni-knowledge runs the lint pass on the **vendored** wiki-lint engine, it does not dispatch `cogni-wiki:wiki-lint`.

## When to run

- User asks to lint, audit hygiene, or find/fix stale content in a knowledge base
- After noticing entries-count or claim drift in `knowledge-health` and wanting to reconcile it
- Periodically as a maintenance pass on a compounding base
- Before a `knowledge-finalize` run, to clean reverse links and drift the synthesis would otherwise inherit

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.

## How it relates to neighbours

- `knowledge-health` is the cheap structural integrity gate (vendored `health.py`); `knowledge-lint` is the semantic hygiene pass (vendored `lint_wiki.py`). They share the bound base but answer different questions — run health for "is it broken?", lint for "is it stale / can it be tidied?".
- `knowledge-finalize` already runs `lint --fix=all` as its deposit-time conformance gate. This skill exposes the **full** lint CLI for deliberate, operator-driven runs (audit, `--suggest`, selective `--fix=<class>`).

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base to lint. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--fix` | No | Repair mode. `--fix=all` enables every mechanical class; `--fix=<class>` enables one. **Writes to the wiki.** Default OFF (audit only). Classes: `reverse_link_missing`, `synthesis_no_wiki_source`, `entries_count_drift`, `frontmatter_defaults`, `alphabetisation`, `raw_citation_depth`, `portal_heading_dedup`. |
| `--suggest` | No | Emit suggested fixes for findings without applying them (read-only). |
| `--dry-run` | No | Show what `--fix` *would* change without writing. |

## Workflow

### 0. Pre-flight

**Required engine.** This skill runs the lint pass on the **vendored** wiki-lint engine — cogni-knowledge ships a byte-identical copy in-tree under `scripts/vendor/cogni-wiki/`, so a bound base is lintable without cogni-wiki installed. The `cogni-wiki` install is only a fallback layout. Probe both so the skill aborts cleanly here rather than failing mid-skill:

```
# vendored-first: the in-tree wiki-lint scripts are self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-lint/scripts" && WIKI_OK=yes || WIKI_OK=no

# fallback: an installed cogni-wiki sibling / marketplace cache (legacy layout)
if [ "$WIKI_OK" = "no" ]; then
  probe_plugin() {
    local plugin="$1" skill="$2"
    test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
    for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
      [ -f "$d" ] && return 0
    done
    return 1
  }
  probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
fi
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge's vendored wiki-lint scripts are missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

This probe is the early-abort gate only — Step 2's `resolve_wiki_scripts` is the authoritative resolver for the actual `lint_wiki.py` path; keep the two vendored-first precedences in sync.

### 1. Resolve the knowledge root and read the binding

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`.

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

### 2. Run the lint pass natively (vendored `lint_wiki.py`)

Resolve the vendored `wiki-lint` scripts dir vendored-first (the same `resolve_wiki_scripts` posture `knowledge-resume` / `knowledge-dashboard` use), then invoke `lint_wiki.py` directly — no `Skill` dispatch:

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_LINT_SCRIPTS=$(resolve_wiki_scripts wiki-lint lint_wiki.py) \
  || abort "cogni-wiki wiki-lint scripts not found (vendored copy missing)"
```

Build the invocation from the parameters. **Default (no `--fix`) is a read-only audit:**

```bash
python3 "${WIKI_LINT_SCRIPTS}/lint_wiki.py" --wiki-root "<wiki_path>"
```

Map the user's flags through verbatim:

- `--fix=<class|all>` → pass `--fix=<value>` (the engine validates the class; `all` enables every class). **This writes to the wiki.** Confirm the user intends a write before passing it; on `--dry-run` the engine reports what it would change without writing.
- `--suggest` → pass `--suggest` (read-only; emits suggested fixes for findings).
- `--dry-run` → pass `--dry-run`.

Parse the JSON envelope `{success, data, error}`. On `success: false`, surface `error` and stop. Otherwise capture `data.errors`, `data.warnings`, `data.info`, `data.stats`, and — in fix mode — `data.fixed[]`, `data.failed[]`, plus `data.suggestions[]` under `--suggest`.

### 3. Compose the lint report

Print a compact report:

- **Header.** `<knowledge_title>` (`<knowledge_slug>`) — `<wiki_path>` — mode: `audit` / `fix=<value>` / `dry-run` / `suggest`.
- **Findings.** The engine reports findings in `warnings` and `info` — `errors` is reserved and stays empty in the current engine, so lead with `warnings` (cap 15), then `info` (cap 10), each as its finding class + the affected page; surface a non-empty `errors` list (cap 20) above them only on the off chance the engine ever populates it. The high-signal classes are `stale_page`, `stale_draft`, and `claim_drift`; surface those first within `warnings`.
- **Fixes (fix mode only).** `<len(fixed)> repaired` — list each `fixed[]` entry (class + page); then `<len(failed)> failed` with each `failed[]` entry and its reason. On `--dry-run`, label the list "would repair".
- **Suggestions (`--suggest` only).** List each `suggestions[]` entry (read-only — nothing was written).
- **Next action.** One line by state:
  - Clean (no findings) → "Wiki is lint-clean. Re-run after the next ingest/finalize."
  - Findings present, audit mode → "Run `knowledge-lint --knowledge-slug <slug> --fix=all` to repair the mechanical classes (reverse links, drift, formatting); the semantic findings (`stale_page` / `claim_drift`) need a research refresh — `knowledge-refresh --knowledge-slug <slug>`."
  - After a fix run with residual `failed[]` → "Some classes could not be auto-repaired — see the failed list; they need a manual look or a research refresh."

## Edge cases

- **Binding exists but `wiki_path` no longer does.** `lint_wiki.py` returns `success: false`. Surface its error and stop.
- **An unknown `--fix` class.** The engine rejects it via its `choices` validation; surface the error rather than guessing a class.
- **`--fix` write fails mid-run.** The engine reports per-class `failed[]` with reasons; never claim a class was fixed when it is in `failed[]`.

## Out of scope

- Does NOT run the structural `health.py` integrity gate — that is `knowledge-health`.
- Does NOT dispatch `cogni-wiki:wiki-lint` — the pass is computed natively on the vendored engine.
- Does NOT write to the wiki unless `--fix` is passed; never writes to the binding.
- Does NOT invent repair classes — only the engine's own mechanical classes are applied.

## Output

A lint report printed to the user. Writes to the wiki only under `--fix` (the engine's mechanical repair classes).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary (lint computed natively on the vendored engine)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py` — the vendored lint engine invoked in Step 2
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
