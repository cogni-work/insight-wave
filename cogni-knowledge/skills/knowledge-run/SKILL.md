---
name: knowledge-run
description: "Drive the cogni-knowledge inverted pipeline end-to-end for ONE fresh topic in a single invocation — the ordered-phase driver. Runs the seven-phase chain knowledge-plan → curate → fetch → ingest → distill (optional, fail-soft) → compose → verify → finalize via Skill(...), threading one resolved project path between phases, depositing a freshly-composed, claim-verified synthesis into the bound wiki with no per-phase manual dispatch. Distinct from its two siblings: knowledge-refresh push-mode lints the wiki and re-researches stale pages (this takes one explicit --topic instead), and knowledge-refresh-synthesis extends ONE existing synthesis from a freshly-landed source (this researches a brand-new topic from scratch). Use this skill whenever the user says 'run the knowledge pipeline on X', 'research X end-to-end into my <slug> base', 'one-shot research X into the eu-ai-act base', or 'run plan to finalize on X'."
allowed-tools: Read, Bash, Glob, Skill, AskUserQuestion
---

# Knowledge Run

Drive the **inverted pipeline** end-to-end for **one fresh topic**, in a single invocation. An operator researching a new topic otherwise hand-dispatches ~7 phase skills (`knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`), re-reading each SKILL.md and threading the project path between them. `knowledge-run` is the ordered-phase driver over that chain: one `--topic`, all phases in order, ending with a deposited `type: synthesis` page in the bound wiki.

This skill is a **pure orchestrator** — it composes existing `cogni-knowledge` phase skills via `Skill(...)`, never re-implementing them. It dispatches **zero cogni-research skills** and runs no vendored `wiki-*` script directly; ingest fan-out, per-batch merge, and the integrity sweep — plus compose expansion and the accept check — come "for free" because `knowledge-ingest` and `knowledge-compose` already encapsulate them.

`knowledge-run` is the **fresh-topic parallel entrypoint** to `knowledge-refresh --mode push`: refresh lints the bound wiki and re-researches *stale pages* selected interactively; `knowledge-run` takes a single explicit topic and runs *one* chain. The Phases-2–7 dispatch block is identical between the two — this skill mirrors that proven loop rather than writing new orchestration, so the two entrypoints cannot drift.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once per session to remember the delegation boundary and the `Skill(...)`-dispatch convention (§"How `Skill(...)` blocks are written").

## When to run

- The user wants to research a brand-new topic into a bound knowledge base without dispatching each phase by hand.
- The user has a sharp topic and wants the whole `plan → finalize` chain driven autonomously to a deposited synthesis.

## Never run when

- No `binding.json` exists at the resolved knowledge root — route to `/cogni-knowledge:knowledge-setup`.
- The user wants to refresh **stale existing pages** rather than research a new topic — that is `knowledge-refresh --mode push` (it lints the wiki and selects stale topics).
- The user wants to extend **one existing synthesis** with a freshly-landed source — that is `knowledge-refresh-synthesis`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. Passed verbatim to every phase. |
| `--topic` | Yes\* | Free-text research topic, e.g. `"GDPR Article 30 records of processing"`. The **fresh-topic entry**: drives `knowledge-plan` and derives the project path. \*Exactly one of `--topic` or `--project-path` is required (mutually exclusive); if both are absent, ask the user once for the topic — do not invent one. |
| `--project-path` | Yes\* | Absolute path to an existing project directory to **resume** — the idempotent resume entry. \*Mutually exclusive with `--topic`; `--knowledge-slug` is still required (threaded to every phase). Checkpoint detection (§0.5) reads how far the project already ran from its on-disk artifacts, skips every completed phase as a logged no-op, and dispatches from the first incomplete phase; a fully-finalized project is a clean no-op. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Passed to every phase so they resolve the same base regardless of cwd. |
| `--frame` | No | Pass-through to `knowledge-plan` — force its topic-framing pass (and preliminary scoping scan) even when the topic looks sharp. |
| `--cobrowse` | No | Pass-through to `knowledge-fetch` — opt into browser-based recovery/top-up of sources. When set, the fetch dispatch **omits** `--no-cobrowse`; the operator must have the Claude-in-Chrome extension enabled (the fetch skill walks them through it). Default is autonomous (`--no-cobrowse`). |
| `--no-distill` | No | Skip the optional Phase-4.5 `knowledge-distill` step entirely. Default keeps distill in the chain as a fail-soft step (a distill failure never fails the topic). |

## Workflow

### 0. Pre-flight

1. Parse the parameters above. **Exactly one of `--topic` or `--project-path` is required (mutually exclusive).** If both are absent, ask the user once for the topic — do not invent one. If both are supplied, stop with a clear error (`--topic and --project-path are mutually exclusive — pass one`). `--project-path` is the **resume entry** (skip §1's plan dispatch, run §0.5 checkpoint detection); `--topic` is the **fresh-topic entry** (run §1 plan, then §2).
2. **Resolve the knowledge root** the same way every phase does: if `--knowledge-root` is set, use it; otherwise `knowledge_root = cogni-knowledge/<knowledge-slug>/` relative to the working directory.
3. **Require a binding.** Confirm `<knowledge_root>/.cogni-knowledge/binding.json` exists. If it does not, stop and route the user to `/cogni-knowledge:knowledge-setup` — there is no base to deposit into.

This skill dispatches only this plugin's own phase skills, so there is no vendored-script or cross-plugin probe to run here — each dispatched phase runs its own pre-flight.

### 0.5. Checkpoint detection (the `--project-path` resume entry)

Initialize `skip_set = {}` and `phase_reached = "none"` so §2's per-phase skip check is well-defined on **both** entries. This step then does real work **only on the resume entry** (`--project-path` supplied). The fresh-topic `--topic` entry leaves `skip_set` empty and falls straight through to §1 — §2 dispatches every phase and relies on the per-phase short-circuit idempotency documented in the Resume contract.

On the resume entry, detect how far the project already ran from its on-disk artifacts, then mark every completed phase for skipping:

1. **Compute `phase_reached`** by reusing the existing detector — no new state model, the same artifact→phase mapping `knowledge-resume` reads:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py project \
     --project-path <project_path> --knowledge-root <knowledge_root>
   ```
   Parse `phase_reached` from the JSON envelope's `data`. It is the deepest phase whose artifact is present, ordered by `pipeline-summary.py`'s authoritative `_PHASE_ORDER`: `none → plan → curate → fetch → ingest → distill → compose → verify → finalize` (`.metadata/plan.json` ⇒ `plan` done, `candidates.json` ⇒ `curate`, `fetch-manifest.json` ⇒ `fetch`, `ingest-manifest.json` ⇒ `ingest`, `distill-manifest.json` ⇒ `distill`, `citation-manifest.json` ⇒ `compose`, `verify-vN.json` ⇒ `verify`, a binding deposit or `run-metrics.json` finalize row ⇒ `finalize`). A degraded/legacy read returns `phase_reached: "none"` — treat it as "resume from the top" (nothing skipped), never as an error.
2. **Clean no-op on a finished project.** If `phase_reached == "finalize"`, the project is already deposited — print `project already finalized — nothing to do (phase_reached=finalize)` and **exit cleanly** with no Skill dispatch. Re-running a finalized project is a safe no-op.
3. **Build the skip set.** Otherwise mark for skipping every §2 phase whose position in `_PHASE_ORDER` is **at or before** the position of `phase_reached` (i.e. it already completed): `skip_set = { P ∈ {curate, fetch, ingest, distill, compose, verify} : index(P) ≤ index(phase_reached) }`. (`plan` is owned by §1's resume branch, not §2; `finalize` is never pre-skipped — a non-`finalize` `phase_reached` means finalize has not run.) The first §2 phase **not** in `skip_set` is the resume point. Examples: `phase_reached == "plan"` → `skip_set = {}`, dispatch from `curate`; `phase_reached == "ingest"` → `skip_set = {curate, fetch, ingest}`, dispatch from `distill`/`compose`; `phase_reached == "verify"` → `skip_set = {curate … verify}`, dispatch only `finalize`.

### 1. Phase 1 — plan (with the idempotent existence guard)

**Resume entry (`--project-path` supplied):** set `project_path = <project_path>` verbatim, then **skip the rest of this section entirely** — no topic-slug/`<today>` derivation, no `knowledge-plan` dispatch (the project is already planned; re-dispatching would abort on the existing dir). First confirm `<project_path>/.metadata/plan.json` exists; if it does not, capture `{failed_phase: "plan", error: "--project-path <project_path> has no .metadata/plan.json — not a resumable project"}` and **stop** (report per §3). On success, §0.5 has already computed `skip_set`; proceed to §2. The `--topic` branch below does not run on the resume entry.

**Fresh-topic entry (`--topic` supplied):** `knowledge-plan` derives `project_path = <knowledge_root>/<topic_slug>-<today>/` and **aborts if that directory already exists** (it never overwrites; it `mkdir -p`s `<project_path>/.metadata/` before writing `plan.json`). To make a same-day re-run resumable rather than a hard abort, compute the same path first and branch on the **project directory** (matching `knowledge-plan`'s own abort condition — not on `plan.json` alone, so a crashed prior plan that created the dir but no manifest is not re-dispatched into an abort):

- `topic_slug` = kebab-case of `--topic` — lowercase, alphanumerics + dashes, collapse dash runs, strip leading/trailing dashes, cap at 60 chars (use `sed`/`python3`, no external slugify dep).
- `today = $(date -u +%F)`.
- `project_path = <knowledge_root>/<topic_slug>-<today>/`.

Branch:

- **Dir does not exist** → dispatch `knowledge-plan` and capture the resolved `<project_path>` from the summary's `New project:` / `Plan path:` lines:
  ```
  Skill("cogni-knowledge:knowledge-plan",
        args="--knowledge-slug <knowledge_slug> --topic '<topic>' --knowledge-root <knowledge_root> [--frame]")
  ```
  Include `--frame` only when it was passed to `knowledge-run`.
- **Dir exists AND `<project_path>/.metadata/plan.json` exists** → skip the dispatch and reuse `<project_path>` (the same-day resume path).
- **Dir exists BUT `plan.json` is absent** (orphaned dir from a crashed plan) → do **not** re-dispatch (`knowledge-plan` would abort on the existing dir). Capture `{failed_phase: "plan", error: "orphaned project dir <project_path> has no plan.json — remove it and re-run"}` and **stop** (this is the one front-end failure; report it per §3).

### 2. Phases 2–7 — curate → fetch → ingest → distill → compose → verify → finalize

Each phase takes the uniform `--knowledge-slug <slug> --project-path <project_path> --knowledge-root <knowledge_root>` interface. Dispatch them in order, threading the same `<project_path>` through. **Parse each phase's `{success}` summary; on a failure, capture `{failed_phase, error}` and STOP the chain — do not run later phases, and do not roll back** (the on-disk manifests are the truth and every phase is idempotent, so a partial run is safely resumable by re-invoking `knowledge-run` with the same `--topic` the same day, or with `--project-path <project_path>`). The single exception is `knowledge-distill`, which is **fail-soft** (see below).

**Checkpoint skip (resume entry).** Before dispatching each phase below, check `skip_set` from §0.5: if the phase is in `skip_set`, do **not** dispatch it — print `phase <name> — skipped (artifact present)` and move to the next. Dispatching begins at the first phase not in `skip_set` (the resume point) and continues in order through `finalize`. On the fresh-topic `--topic` path `skip_set` is empty, so every phase dispatches and this block is byte-identical to a from-scratch run.

```
# Resume entry: skip each phase in skip_set (§0.5), logging "phase <name> — skipped (artifact present)";
# dispatch from the first incomplete phase onward. On the --topic path skip_set is empty (dispatch all).
Skill("cogni-knowledge:knowledge-curate",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
Skill("cogni-knowledge:knowledge-fetch",    args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root> --no-cobrowse")
Skill("cogni-knowledge:knowledge-ingest",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
Skill("cogni-knowledge:knowledge-distill",  args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
Skill("cogni-knowledge:knowledge-compose",  args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
Skill("cogni-knowledge:knowledge-verify",   args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root>")
Skill("cogni-knowledge:knowledge-finalize", args="--knowledge-slug <knowledge_slug> --project-path <project_path> --knowledge-root <knowledge_root> --no-portal-prompt --no-concepts-prompt")
```

Dispatch-time rules, each mirroring `knowledge-refresh` push-mode:

- **`knowledge-fetch` — `--no-cobrowse` by default.** The driver is autonomous, so it must never block on the cobrowse opt-in prompt (the bodies are already fetched during `knowledge-curate`; WebFetch misses stay unavailable rather than waiting for a browser). **When `--cobrowse` was passed to `knowledge-run`, OMIT `--no-cobrowse`** so the operator opts into browser-based recovery/top-up.
- **`knowledge-distill` (Phase 4.5) — optional + fail-soft.** It enriches the bound wiki's concept/entity web, but a distill failure must **not** fail the topic: do not capture it in the failure record and do not skip `compose` — just note it and continue (distill itself exits 0 even on internal failure, so this is belt-and-suspenders). **When `--no-distill` was passed, skip this dispatch entirely.**
- **`knowledge-finalize` — `--no-portal-prompt --no-concepts-prompt`, never `--overwrite`.** The driver must never block on finalize's interactive apply-portal / apply-concepts confirms; the staged diffs are reviewable later (`<wiki>/.cogni-wiki/portal-proposed.md` / `concepts-index-proposed.md`, appliable with `--apply-portal` / `--apply-concepts` or a human-direct `knowledge-finalize`). Do **not** pass `--overwrite` — finalize refusing to clobber an existing `<wiki>/syntheses/<slug>.md` is the correct resume behaviour.

`knowledge-finalize` deposits the verified draft as `<wiki>/syntheses/<slug>.md` and appends the project to `binding.json::research_projects[]` — that is the deliverable.

### 3. Final summary

Print a short summary (≤ 6 lines):

- On success: the deposited synthesis slug and its project path, and a note that a distill failure (if any) was tolerated.
- On a phase failure: `failed at <failed_phase>: <error>` so the operator knows exactly where to resume, plus the reminder that re-invoking `knowledge-run` with `--project-path <project_path>` (or the same `--topic` the same day) resumes the chain from the first incomplete phase — §0.5 checkpoint detection skips the completed phases as logged no-ops.
- On the resume entry, when every phase was already complete: the §0.5 `phase_reached == "finalize"` no-op message (`project already finalized — nothing to do`).
- Suggested next: `/cogni-knowledge:knowledge-resume` to confirm the new deposit, or `/cogni-knowledge:knowledge-dashboard` to re-render the overlay.

### Resume contract

The chain fails soft: a topic that dies mid-chain leaves valid manifests on disk for the phases that completed. Re-invoking `knowledge-run` resumes it — by `--project-path <project_path>` (the explicit resume entry: §0.5 detects `phase_reached` and skips completed phases as logged no-ops, robust across days) or by the same `--topic` (same day, which recomputes the same `<topic_slug>-<today>` path). Either way each phase also short-circuits on already-complete state by construction:

- **`knowledge-plan`** — §1's existence guard reuses `<project_path>` when `plan.json` is present (a later day computes a new `<topic-slug>-<date>` and starts fresh — usually what you want a day later anyway).
- **`knowledge-curate` / `knowledge-fetch`** — `candidate-store.py` / `fetch-cache.py` are dedup-by-construction; re-runs cost only the WebSearch/WebFetch budget for cache misses.
- **`knowledge-ingest`** — skips URLs already in `ingest-manifest.json::ingested[]`.
- **`knowledge-distill`** (optional, fail-soft) — `concept-store.py merge` is byte-stable on re-run; a distill failure never blocks the chain.
- **`knowledge-compose`** — preserves the outline-recovery contract (a leftover `writer-outline-vN.json` triggers Phase-2-only re-run).
- **`knowledge-verify` / `knowledge-finalize`** — verify is single-pass per round; finalize refuses to overwrite an existing synthesis, so a re-run after a successful finalize is a safe no-op.

Explicit checkpoint detection + an idempotent `--project-path` resume entry ship here (§0.5 + §1's resume branch). Cost-gating and an end-of-run summary/ledger build on this skeleton in separate increments.
