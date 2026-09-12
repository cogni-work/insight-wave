# cogni-consult Development Guide

## Identity

cogni-consult is a consulting engagement orchestrator for the insight-wave ecosystem built on three structural bets: **action fields are the work-breakdown-structure containers** for every deliverable (no fixed phase folders), **each deliverable runs its own design-thinking loop** (empathize→define→ideate→prototype→test), and **cogni-knowledge is the central research tool** bound once per engagement and compounding across all deliverables. It was selected after a side-by-side dogfood evaluation of two consulting-orchestration approaches (record: `docs/contributing/cogni-consult-evaluation.md`).

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.x, Preview)
├── CLAUDE.md                      This developer guide
├── README.md                      Plugin documentation
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   ├── dependency-model.md        Deliverable dependency graph: edge schema,
│   │                              validation, cascade + topological refresh
│   ├── deliverable-types.md       Deliverable-type catalog (field-type affinity)
│   ├── engagement-dashboard-rendering.md  Step-4 action-field dashboard rendering contract
│   ├── engagement-list-rendering.md  Step-2 engagement-list rendering + the shared bilingual contract
│   ├── evaluation-criteria.md     Six criteria from the replacement evaluation,
│   │                              each with a concrete pass signal
│   ├── frameworks-registry.md     Consulting-framework catalog backing the Define/
│   │                              Prototype framework lens (chosen_framework values)
│   ├── interaction-language.md    Interaction language vs. deliverable language rule
│   ├── persona-schema.md          Acting-persona schema + acting contract
│   ├── project-plan-model.md      Scheduling-field schema + roadmap read-model
│   │                              (topological-layer phase/timeline derivation)
│   ├── publish-routing.md         Canonical publish format→route contract
│   ├── research-routing.md        Canonical cogni-knowledge research rule (binding,
│   │                              pipeline rungs, depth framing, storage contract)
│   ├── subagent-output-contract.md  Register rules the SubagentStart hook emits
│   │                              verbatim into every dispatched agent
│   ├── user-facing-output.md      Main-loop register OVERLAY on the canonical
│   │                              ecosystem register in cogni-workspace: carries
│   │                              this plugin's state lexicon, coinage anglicism
│   │                              table, and the mirrored description constraints
│   ├── personas/                  Packaged default advisors (consulting-partner,
│   │                              project-manager)
│   ├── methods/
│   │   ├── scope-dimensions.md    SMART key question + 5 dimensions + WBS-close method
│   │   ├── empathy-mapping.md     Empathize-stage persona quadrant mapping
│   │   ├── hmw-synthesis.md       Define-stage HMW problem-spec synthesis
│   │   └── guided-ideation.md     Ideate-stage diverge→converge facilitation
│   └── orchestration/             DT orchestration contracts extracted from the
│       │                          consult-design-thinking SKILL body (cap headroom)
│       ├── empathize-intake.md    Pre-gap-check source-material intake rung
│       ├── empathize-empathy-mapping.md  Per-persona empathy-map fan-out + merge
│       │                          + stage-owned persona writes
│       ├── test-provenance-gate.md  Completion-time evidence-provenance record /
│       │                          evidence-provenance-waiver contract
│       ├── test-adherence-review.md  Advisory framework-adherence review dispatch
│       │                          + adherence-review decision-log entry
│       ├── test-promote-check.md   Act-by-default assumption promote-check
│       │                          + assumption-promotion decision-log entry
│       ├── test-persona-challenge.md  Persona-challenge fan-out + merge; writes
│       │                          owned by consult-personas step 5
│       └── close-kb-deposit.md    Elected KB deposit + kb-deposit-waiver contract
├── output-styles/
│   └── strategy-advisor.md        Language-neutral advisory stance (audience,
│                                  stance, structure); opt-in, auto-discovered
│                                  in the /config picker. The register it
│                                  applies is canonical in cogni-workspace,
│                                  overlaid by references/user-facing-output.md
├── hooks/
│   ├── hooks.json                 SubagentStart, matched on the four consult-*
│   │                              agent types (auto-discovered at the plugin root)
│   └── on-subagent-start.sh       Resolve the workspace interaction language and
│                                  emit it with references/subagent-output-contract.md
│                                  into dispatched agents, which inherit neither
├── agents/
│   ├── consult-dashboard-refresher.md  Milestone HTML dashboard refresh (haiku,
│   │                              read-only, no theme prompt)
│   ├── consult-framework-adherence-reviewer.md  Score a finished deliverable against
│   │                              its stored chosen_framework, report structural
│   │                              drift (sonnet, read-only, advisory Test-gate rung)
│   ├── consult-persona-challenger.md  Challenge a deliverable as ONE acting persona
│   │                              in voice, return a structured objection envelope
│   │                              (sonnet, read-only; consult-personas merges + writes)
│   └── consult-empathy-mapper.md  Map ONE persona's empathize-stage empathy map,
│                                  return a structured envelope (sonnet, read-only;
│                                  the Empathize stage merges + writes)
├── scripts/
│   ├── engagement-init.sh         Create engagement directory skeleton
│   │                              + README front door (final, non-fatal step)
│   ├── engagement-status.sh       Read consult-project.json state → JSON
│   ├── generate-engagement-readme.py  Markdown wayfinding front door: write the
│   │                              engagement-root README.md (status snapshot,
│   │                              next action, relative Obsidian links)
│   ├── deliverable-graph.py       Deliverable dependency-graph engine: validate /
│   │                              trace / impact / refresh-order / schedule /
│   │                              cascade-stale
│   ├── resolve-assumptions.py     Render-time {{asm:id}} resolver against the
│   │                              engagement-root assumptions.json registry
│   │                              (fail-loud on unknown ids; verified claim-type
│   │                              values evidence-gated against `cogni-workspace:claims`;
│   │                              --mode link emits [[assumptions#slug|value]])
│   ├── register-generator.py      Generate the browsable assumptions.md register
│   │                              (summary table + anchored ## slug sections)
│   │                              from assumptions.json; overwrite-guarded
│   ├── submit-assumption-claim.py Submit/propagate adapter for the claim-type
│   │                              assumption verify round-trip (consult →
│   │                              cogni-workspace:claims → back onto the record)
│   ├── assumption-change-frequency.sh  Read-only git-history spike: how often
│   │                              numeric literals in a deliverable corpus
│   │                              changed (sizing datum for propagation automation)
│   ├── orthography-drift-scan.py  Read-only Swiss-ss-in-ß-position scan over one
│   │                              engagement's stored corpus; curated pair list with
│   │                              bounded recall, reports only (no repair mode)
│   ├── discover-projects.sh       Thin wrapper over the cogni-workspace discovery helper
│   └── _discover_extractor.py     Per-engagement field extractor for the wrapper
└── skills/
    ├── consult-setup/SKILL.md     Engagement entry point: scaffold + knowledge-base bind
    │                              + registry
    ├── consult-scope/SKILL.md     SMART key question + 5 scoping dimensions
    │                              + 3-6 action fields as the WBS
    ├── consult-action-fields/SKILL.md  WBS dashboard + per-field deliverable
    │                              manifests + next-deliverable recommendation
    ├── consult-design-thinking/SKILL.md  Per-deliverable DT loop (empathize→define
    │                              →ideate→prototype→test) + artifact + state writes
    ├── consult-personas/SKILL.md  Acting personas: define from scope, enrich,
    │                              act-as challenge against deliverables (single
    │                              owner of the persona-challenge write contract)
    ├── consult-publish/SKILL.md   Consultant-elected publish seam: completed
    │                              deliverable → presentation-ready brief
    │                              (slides / web-poster / report / infographic)
    ├── consult-resume/SKILL.md    Engagement re-entry point: discovery + WBS
    │                              dashboard + workflow-state next-action routing
    └── consult-dashboard/         Themed HTML engagement dashboard (read-only)
        ├── SKILL.md               select theme → design-variables → generate → open
        ├── scripts/generate-dashboard.py  Render dashboard.html from project + field.json
        ├── schemas/               design-variables.schema.json (theme contract)
        └── examples/              design-variables example
```

## Design Principles

- **Action fields as WBS** — scoping derives 3-6 action fields from the key question; every deliverable lives inside exactly one field. Progress is tracked per deliverable, not per global phase
- **Design thinking per deliverable** — each deliverable iterates empathize→define→ideate→prototype→test on its own clock; fields complete when their deliverables do
- **Acting personas as a seed-from-scope gate** — stakeholder personas are seeded from the engagement scope *before* the first design-thinking deliverable can start, then actively challenge deliverable work in their voice (not just describe users). The seed is a gate, not a suggestion: `consult-design-thinking` hard-blocks a not-started deliverable and `consult-resume` routes to persona-seeding first, until the gate is satisfied. The two shipped setup-default advisors (consulting partner, project manager; `source: setup-default`) do **not** satisfy it. The gate is the derived `personas_gate` rollup: **satisfied** when any `personas/*.json` carries `source: scope-seeded` **or** the extensionless `personas/.gate-waiver` marker is present, else **pending**. The waiver is the defaults-only escape — when no external stakeholders are worth modelling, `consult-personas` (mode: waive) writes `.gate-waiver` on explicit confirmation, moving the gate to satisfied without seeding a persona
- **Knowledge base as the research spine** — one cogni-knowledge base bound at setup (`plugin_refs.knowledge_base`); all deliverable research runs through it and compounds
- **Orchestrator, not producer** — manages engagement state; content work dispatches to existing plugins
- **Read-only fan-out agents, single write owner** — parallelizable per-item judgment (Test-stage persona challenge, Empathize empathy-mapping, Test-gate framework-adherence review) is delegated to read-only agents that return `{success, data, error}` envelopes; the orchestrating skill merges the envelopes and owns every write. The persona-challenge write contract lives in exactly one place (consult-personas' challenge mode); the DT loop delegates instead of reimplementing. Together with structural validation and the persona challenge, the advisory adherence review completes the repo's Three-Layer Quality Gate; all gates are advisory — auto-walk never deadlocks. Dense fan-out/merge/idempotency contracts live in `references/orchestration/`, keeping the SKILL body under the 500-line cap
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB
- **Stance in the output style, register in the reference, phase discipline in the skills** — the *stance* (audience, answer-first posture, MECE structure) lives in the one language-neutral output style `output-styles/strategy-advisor.md`, opt-in and fixed at session start. The *register* — language resolution, state lexicon, table contract, step announcements, orthography, prose vocabulary — is canonical in `${COGNI_WORKSPACE_PLUGIN}/references/user-facing-output.md`, which `references/user-facing-output.md` overlays with this plugin's own lexicon and coinages; the style names the overlay rather than restating either. The diverge/converge *phase discipline* stays in the consult-* skills, which load contextually so they never fire outside an active engagement. An output style still does not load `references/` — the main loop reaches the register through the consult-* skills, and the agent path reaches its twin through `hooks/on-subagent-start.sh`. That is why one language-neutral stance file beats an EN/DE pair: there is no longer a second doctrine to keep in step

  **Why the style stays opt-in — the no-auto-applied-output-style non-goal.** A plugin *can* force its own style on every session (`force-for-plugin: true`), and that is exactly why we do not: a forced style is session-global, and multi-plugin resolution is first-loaded-wins, so with the marketplace installed cogni-consult would govern the voice of every unrelated session. That reason is independent of Claude Code's version and is the only one to record.

  **Rejected alternative: generate the styles from the reference.** A build-time generator rendering the style files from `references/user-facing-output.md` was considered and rejected. It preserves two artifacts whose only remaining difference is language, adds a generated-prompt-surface drift class to a plugin whose scripts are all runtime tools, and — because an output style cannot load `references/` — a generated style would silently fall out of step the moment the reference changed, with nothing failing. Reviewing a generated system prompt is also worse than reviewing a hand-written one. Collapsing to one stance file removes the duplication instead of automating its upkeep.

  **The file declares `keep-coding-instructions: true`, and it is load-bearing.** Without it, activating a style drops Claude Code's `# Doing tasks` block — prefer-editing-existing-files, the OWASP warning, the over-engineering rules — which matters for skills that run `deliverable-graph.py` and do idempotent `Edit` round-trips on `field.json`. The plugin output-style loader reads the field (`keepCodingInstructions` travels with `forceForPlugin` from the frontmatter through the merged style map into the prompt assembler), so declaring it keeps those instructions in place. `# Executing actions with care` is unconditional and survives either way. Treat the declaration as behaviour, not decoration: if the file loses it, activating the register silently costs the engineering defaults

  **What the styled path alone does not deliver — the accepted coverage limit.** With the style active and no consult-* skill loaded, the main loop gets stance and nothing else: `## (h) Executive register and engine vocabulary` in the canonical register — executive register, compression discipline, engine vocabulary — and `## (e) Step announcements and brevity budgets`, which holds the work-narration mechanics, are both out of reach until something loads the overlay and the canonical file behind it. The consequence is a session that reads as advisory in posture while still narrating its own tooling, spending paragraphs where the budget allows a line, and reaching for the engine vocabulary the register replaces. What the style carries itself still lands regardless: audience framing, and the answer-first, MECE stance. That gap is intended and accepted, not an oversight — the register is contextual by design, and restating it in the stance file would rebuild the duplicated doctrine that collapsing to one file removed. It closes the moment any consult-* skill loads, which is when consulting work is actually being narrated.

- **Language reaches subagents only through the hook** — a subagent's system prompt is its own body plus a notes block and the environment info: no settings `language` key, no `CLAUDE.md`, no active output style. `hooks/hooks.json` registers a `SubagentStart` hook matched on the four `consult-*` agent types; `hooks/on-subagent-start.sh` resolves the workspace default language and emits it together with `references/subagent-output-contract.md`, read verbatim. Because a hook cannot see the user's message, rung 2 of `references/interaction-language.md` (message-detection override) travels as the `interaction_language` dispatch input, which wins over the hook's default. Keep the doctrine in the reference, not in the hook script and not in the four agent bodies — the script is a delivery mechanism, and the agent bodies hold only the input declaration. The main-loop half is the canonical ecosystem register plus `references/user-facing-output.md` overlaying it — one contract, two delivery paths (those load in the main loop, this one is injected into agents), so a rule changed in either is checked against the other. The rules this file mirrors are canonical (g) and (h), so a change there is what triggers the check, not a change to the overlay

  **The matcher must accept the plugin-qualified agent name.** A plugin-supplied agent is dispatched as `cogni-consult:consult-*`, not as a bare `consult-*`, so the matcher accepts both forms. A matcher anchored on bare names alone silently never fires: all four agents then run without the language block and without the output contract, while `hooks/on-subagent-start.sh` stays correct the whole time. Nothing reports that — the script exits 0 on every path, and a matcher that never matches raises nothing anywhere — which is why the only evidence is the injected context itself, and why `tests/test_subagent_start_hook.sh` pins both name forms. That test is CI-enforced — the `Plugin test suites (discover and run tests/*.sh)` job in `.github/workflows/lint.yml` runs `scripts/run-plugin-tests.py`, which discovers every plugin's `tests/*.sh` and fails the build on a non-zero exit. The rule behind the name form is structural, not a quirk of one build: the host registers a plugin agent under `pluginName:agentName`, joined with `:` and carrying one extra segment per `agents/` subdirectory, and hands that exact string to the `SubagentStart` matcher as `agent_type` — which it applies as a *search*, not a full match, so keeping the regex anchored at both ends is what stops it firing for other plugins' subagents. What was observed directly is the pre-fix failure: a live dispatch of a matched `consult-*` agent arrived with none of the injected block. Post-fix delivery was **not** confirmable in the session that made the change, because hooks load at session start from the installed plugin cache rather than from a branch — to re-check it, dispatch one of the four agents in a fresh session and look for `# Interaction language and output register` in what it received. Two traps for a future reviewer: `SubagentStop` is a different lifecycle point (subagent *finishing*) and is not a substitute for dispatch-time injection; and `plugin-dev`'s `validate-hook-schema.sh` carries an event whitelist predating this event, so it prints `Unknown event type: SubagentStart` and exits 0 — a gap in that validator, not evidence the event is unsupported

- **`allowed-tools` in a skill frontmatter is an auto-approve grant, not a tool filter** — the verdict is **advisory**: the key is *not enforced* as a restriction, so a skill whose `allowed-tools` omits a tool is not thereby prevented from using it. This is worth recording because all nine `skills/consult-*/SKILL.md` declare `allowed-tools` and not one names a subagent-dispatch tool, while four skill bodies dispatch `consult-*` agents — a shape that reads like every delegation in the plugin is silently unreachable. It is not, and the nine declarations are correct as they stand; nothing needs adding to them. What was observed directly, in the host binary resolved at `/Users/stephandehaas/.local/share/claude/versions/2.1.223` (`claude --version` reports `2.1.223 (Claude Code)`), a ~260 MB Mach-O 64-bit arm64 Bun-compiled bundle: the skill-invocation path (byte offset ~250175521 in that bundle) reads the two keys **asymmetrically** — `disallowedTools` is folded into the tool-permission context through a `setToolPermissionContext` call, whereas `allowedTools` receives no such call and instead lands in `toolPermissionContext.alwaysAllowRules.command` (~261432756 and ~261918083); the bundle's own warning string (~253852200) states that bare `allowedTools` entries auto-approve the whole tool *before* the permission callback is consulted, and points at a `PreToolUse` hook as the way to genuinely gate a call; and the `command_permissions` payload the invocation emits is inert downstream (~252590165, ~256149797), rendering to nothing in both the model's context and the UI. The restrictive contrast is an **agent's** `tools:` key, which really does filter that agent's tool list (~250184742) and displays as `All tools` when absent (~251516252) — two different keys on two different file types, and conflating them is what raises the alarm. What is *inferred* rather than observed: that no other code path re-reads the key restrictively — a strings-level trace of a single bundle cannot prove that negative exhaustively. Unlike the deliberately version-independent rationale recorded above for the opt-in output style, this finding is **version-dependent**, which is why the binary path and version are pinned verbatim rather than summarised. To re-check on a newer build, record `readlink -f "$(command -v claude)"` and `claude --version`, then re-inspect the skill-invocation site for a `setToolPermissionContext` call, or any filter over the tool list, applied to `allowedTools`. The verdict is falsified the moment `allowedTools` acquires either — or the moment a skill is observed unable to use a tool its `allowed-tools` omits — and the remedy then is to add the dispatch tool to the dispatching skills and pin it with a suite. No behavioural test of the host's tool filter can be written from this repo: the mechanic lives inside the `claude` binary, not in any repo executable, so the pinned trace above is the strongest available evidence.

## Data Model

Each engagement lives in `cogni-consult/{slug}/` with:
- `consult-project.json` — engagement config, key question, action-field list, scope state, plugin refs
- `assumptions.json` — single source of truth for assumption values; deliverables and briefs cite them as `{{asm:id}}` placeholders resolved at publish time by `resolve-assumptions.py`
- `assumptions.md` — the human-browsable register generated from `assumptions.json` by `register-generator.py` (summary table + anchored `## <slug>` sections); the click-through target for `resolve-assumptions.py --mode link` wikilinks. Generated artifact, overwrite-guarded
- `scope/` — key question + 5 scoping dimensions + derived action-field list
- `action-fields/{field-slug}/` — one directory per WBS field: `field.json` (single source of truth for the field's deliverable states) + deliverable markdown artifacts
- `personas/` — acting stakeholder personas (JSON)
- `sources/` — engagement source inbox: the documented drop location for raw material (LOI, specs, notes, transcripts) to ground a deliverable; scaffolded at setup with a `README.md`, the Empathize stage ingests it into the bound base or reads it into a deliverable's `sources[]`
- `.metadata/` — execution-log, method-log, decision-log (all addressed by `action_field` + `deliverable`)

Full schemas: `references/data-model.md`.

## Scripts

| Script | Purpose |
|--------|---------|
| `engagement-init.sh` | Create the engagement directory skeleton + consult-project.json, then write the engagement-root `README.md` front door via `generate-engagement-readme.py` (final step, non-fatal — a generator failure degrades to a stderr warning) |
| `engagement-status.sh` | Read consult-project.json + derive field/deliverable rollups from `field.json` files, plus the `personas_gate` rollup (satisfied when a `personas/*.json` has `source: scope-seeded` or the extensionless `personas/.gate-waiver` marker is present, else pending) → JSON |
| `generate-engagement-readme.py` | Write the Obsidian-browsable `README.md` front door at the engagement root from the same read model (key question, status snapshot, single next recommended deliverable incl. the `personas_gate` rung, wayfinding links that only target existing files); read-only except the `README.md` it writes. Invoked at scaffold time by `engagement-init.sh` and, unconditionally and non-fatally, at the dashboard milestones — `consult-design-thinking` (session close), `consult-action-fields` (WBS change), `consult-resume` (re-entry) — the markdown parallel to `consult-dashboard-refresher`'s theme-gated HTML refresh |
| `deliverable-graph.py` | Deliverable dependency-graph engine over all `field.json` files: `validate` (cycles + dangling refs), `trace` (upstream lineage), `impact` (downstream blast radius), `refresh-order` (topological layering of stale deliverables), `schedule` (duration-weighted earliest-start/finish + critical path over `depends_on[]`), `cascade-stale` (flag downstream `lineage_status` via idempotent RMW). Full model: `references/dependency-model.md` |
| `resolve-assumptions.py` | Render-time resolver replacing `{{asm:<slug>}}` placeholders with values from the engagement-root `assumptions.json` registry (single source of truth for assumption values). Fail-loud on unresolvable placeholders; wired into `consult-publish` as the mandatory post-build/pre-lineage pass (contract: `references/publish-routing.md`). A cited claim-type assumption at `verified` is evidence-gated: its `citation.claim_id` must resolve to a verified ClaimRecord in the workspace `cogni-claims/claims.json` (read-only; `--claims-file` overrides the location), else the resolve fails loud. The opt-in `--mode link` capability substitutes `[[assumptions#<slug>\|<value>]]` wikilinks into the browsable register instead of the literal value (marker intact); the default `value` mode is byte-for-byte the pre-existing publish behaviour |
| `register-generator.py` | Generate the human-browsable `assumptions.md` register at the engagement root from `assumptions.json`: a summary table (id→anchor, value, type, status, source host, used_by count) plus one anchored `## <slug>` section per assumption (value, provenance, rationale, citation source-lineage quad, `used_by[]` backlinks). Read-only except the register it writes; overwrite-guarded on the same generated-marker footer as `generate-engagement-readme.py`. The `## <slug>` headings are the exact anchors `resolve-assumptions.py --mode link` targets |
| `submit-assumption-claim.py` | Submit/propagate adapter for the claim-type assumption verify round-trip: `submit` maps the assumption onto the unchanged claim-verification `EntityRef` object contract and appends an `unverified` ClaimRecord under a mkdir lock (idempotent — one assumption, one record); `propagate` writes `status: "verified"` + `citation.claim_id` back onto the assumption record, refusing unless the referenced ClaimRecord is itself verified; `resolve-propagate <asm-id> [--corrected-value <v>]` completes the deviated→resolved leg for the three value-affecting resolution actions (mirroring cogni-portfolio verify Step 8), demoting `status` `verified`→`reviewed` and stamping `citation.propagated_at` in every case: `corrected` writes the corrected value — the explicit `--corrected-value`, or when omitted a verbatim fallback to the ClaimRecord's `resolution.corrected_statement` (a full sentence, not a scalar extracted from it), failing loud with `corrected_value_missing` only when neither is present; `alternative_source` writes `resolution.alternative_source_url`/`alternative_source_title` onto the citation, leaving the value untouched; `discarded` unbinds `citation.claim_id`, retaining the value as a last-known figure (the `{{asm:}}` placeholder still needs one, so unlike a portfolio entity field it cannot be deleted). Refuses unless the ClaimRecord is `status: "resolved"` with a propagable action — the non-propagable `disputed`/`accepted_override` keep the original value — and guarded so a resumed run is a no-op |
| `assumption-change-frequency.sh` | Read-only retrospective spike (bash exec-delegator over a stdlib-only python3 miner): mines the git history of a deliverable corpus and reports how often bare numeric literals changed (`edits_per_literal` over the observed window). Registry-independent — reads git history, not `assumptions.json` — so it sizes the payoff of the propagation automation before that automation exists. Compares each commit's full-file literal counts against the previous version (not diff fragments), so frontmatter and code-fence boundaries are detected exactly |
| `orthography-drift-scan.py` | Read-only scan reporting Swiss-`ss` spellings that sit in `ß` positions across one engagement's stored corpus — the drift that makes an engagement's own files out-argue the orthography rule in canonical §(a), which `references/user-facing-output.md` §(a) carries here by pointer, since stored prose reaches the model as in-context evidence while the rule is read once. Reports only: there is no repair mode, no flag that writes, and nothing under the engagement root is opened for writing. Detection is a **curated-list heuristic with bounded recall** whose single machine-readable home is the script's `SWISS_PAIRS` constant, so a zero-finding report means nothing on that list appeared rather than that the corpus is `ß`-correct; "ß position" is not derivable from spelling alone, which is why correct short-vowel `ss` (dass, muss, Prozess) can never match and why the ambiguous homographs `Masse` and `Busse` are deliberately absent. Markdown is scanned whole, while JSON is reached only through named prose keys (`title`, `framing`, `name`, `rationale`, `decision`, `question`, `summary`, `intent`, `key_question`) so engine tokens (`state`, `dt_stage`, slugs, ids) cannot false-positive — and each captured value is JSON-unescaped before matching, since a file written with the default `ensure_ascii=True` carries `Gr\u00f6sse` and would otherwise lose every non-ASCII entry inside a clean-looking zero-finding report. `.metadata/` is walked. Generated echoes are excluded as symptoms rather than sources, identified by the same footer sentinel `generate-engagement-readme.py` and `register-generator.py` key their overwrite guards on rather than by a path list: those guards treat a marker-less file as hand-authored, so a `README.md` a consultant actually wrote is still scanned. Finding drift is a **successful** scan — `success: true` with a non-zero `data.total_findings`, exit 0 — so consumers branch on the count, never the exit code |
| `discover-projects.sh` | Thin wrapper delegating to `cogni-workspace/scripts/discover-plugin-projects.sh` (registry: `$HOME/.claude/cogni-consult-projects.json`) |
| `_discover_extractor.py` | Per-engagement JSON field extractor consumed by the discovery wrapper (reads the flat consult-project.json schema). Also reads each engagement's `.metadata/execution-log.json` and surfaces the newest `transitions[].timestamp` as an additive `last_activity` key — raw and un-normalized, falling back to root `updated` then the empty string — so consumers sort on discovery output instead of reopening every engagement's log. The log read has its own `try/except`, so a corrupt log degrades `last_activity` without stripping the consult-project.json fields |

All scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`.
All scripts are stdlib-only (bash + python3, no pip dependencies).

## Key Conventions

- Engagement and entity slugs in kebab-case, derived from names
- Workflow state per deliverable: `pending` → `in-progress` → `complete` (→ `in-progress` on iteration re-entry); stored only in `field.json`, field and engagement completion derived at read time
- `dt_stage` tracks the design-thinking stage per deliverable (`empathize`/`define`/`ideate`/`prototype`/`test`)
- `personas_gate` is a **derived** rollup (never stored): `engagement-status.sh` computes it at read time from the `personas/` directory — **satisfied** when any `personas/*.json` carries `source: scope-seeded` or the extensionless `personas/.gate-waiver` marker exists, else **pending**. It gates the first design-thinking deliverable (seed personas from scope, or take the defaults-only waiver, before deliverable work starts)
- Entity outputs are Obsidian-browsable markdown with YAML frontmatter; state files are plain JSON
- `language` field in consult-project.json is the deliverable/output language for artifacts (technical terms stay English); the user-facing interaction language is a separate, runtime-derived axis (workspace default + message-detection override, never stored) — see `references/interaction-language.md`, which owns the language axis only. Copy rules for a governed surface live in `references/user-facing-output.md`; a Bash tool call's `description` is section (f) there
- **Research routing**: every research run goes through the engagement's bound knowledge base per `references/research-routing.md` — the canonical rule all deliverable-producing skills point at (binding via `plugin_refs.knowledge_base`, pipeline rungs, depth framing, syntheses copied to `action-fields/<field-slug>/research/<topic-slug>.md`); raw WebSearch only for a single trivial fact-check
- **Publish seam**: `consult-publish` is the consultant-elected, never-auto-firing path that turns a completed deliverable into a presentation-ready brief. It appends one `{format, brief_path, route_steps, source_deliverable, published_at}` entry per published format to the deliverable's `publish[]` array in `field.json` (`format` ∈ `{slides, web-poster, report, infographic}`); `brief_path` is a **path reference** to the produced brief — never copied content, mirroring the source-lineage discipline so an upstream correction stays visible downstream, and `engagement-status.sh` passes the array through verbatim (no script change). Rendering and brand are out of scope: cogni-consult emits the brief, Claude Design (claude.ai/design) renders it. Every format builds a consult-native brief, so the standard path never renders and never dispatches a renderer (`cogni-workspace:enrich-report` / `/render-infographic` remain an opt-in local-render fallback only); the optional `cogni-workspace:copywriter` polish step is skipped when absent. Canonical routing contract: `references/publish-routing.md`; `publish[]` schema: `references/data-model.md`
