# Vendored / incorporated code license audit

**Purpose:** Phase 1 (audit gate) of the AGPL-3.0 → Apache-2.0 relicense roadmap
(epic #1059). This is the blocking legal gate before the LICENSE-text swap
(#1056): it confirms that no incorporated third-party code carries a copyleft
license (GPL / AGPL / LGPL) that would force copyleft on, or otherwise block, a
permissive relicense of the files that incorporate it.

**Verdict:** ✅ **CLEAR to proceed.** No incorporated or vendored code in this
repository is under a copyleft license that blocks a permissive AGPL-3.0 →
Apache-2.0 relicense. The repository's own code is uniformly single
copyright holder (Stephan de Haas / cogni-work.ai), and every bundled
third-party surface is permissively licensed or public domain and already
carries adequate attribution in-tree.

**Scope of audit:** repo-wide. Method: enumerate every directory named
`vendor/`, `third_party/`, `third-party/`, `node_modules/`, `external/`,
`3rdparty/`; scan for dependency manifests (`package.json`, `requirements.txt`,
`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`); grep every tracked file for
`SPDX-License-Identifier`, `Copyright`, and `GPL` / `AGPL` / `LGPL` header text;
enumerate every `LICENSE` / `COPYING` / `NOTICE` file; and confirm the absence of
the out-of-repo `cogni-service/` surface named in the epic intent.

---

## Inventory of incorporated / bundled surfaces

Two bundled surfaces exist in the tree. Both are recorded below with a
determined license and an Apache-2.0-compatibility assessment.

### 1. `cogni-knowledge/scripts/vendor/cogni-wiki/`

| Field | Finding |
|---|---|
| What it is | A verbatim, byte-for-byte mirror of the `cogni-wiki` runtime engine (foundation pages + `wiki-{ingest,lint,health,dashboard,prefill,refresh,claims-resweep}` scripts). |
| Origin | **First-party.** `cogni-wiki` was a plugin in this same monorepo, created under `plugin.json` license `AGPL-3.0-only` with the same sole copyright holder as every other plugin. It was later archived and physically removed during the cogni-knowledge absorption; this vendored copy is the surviving self-contained mirror. |
| Provenance record | `cogni-knowledge/scripts/vendor/README.md` — `"verbatim, byte-for-byte mirror of the cogni-wiki runtime engine"`, `Vendored-from: e356c998e2e14b9c4ead4979c187509b061a228f (2026-06-05)`. |
| License | AGPL-3.0-only (first-party; governed by the repository's root `LICENSE`). |
| Copyleft? | Not third-party copyleft. It is the project's own code under the project's own license — relicensable by the sole copyright holder. |
| In-tree LICENSE/COPYING | None inside the vendor dir. Expected and correct: first-party code falls under the single root `LICENSE`, not a per-dependency license file. |
| Header scan | Grep of every vendored file for `Copyright` / `SPDX-License-Identifier` / `GPL` / `AGPL` / `LGPL` → **zero matches**. |
| Apache-2.0 compatible? | ✅ Yes — first-party code, relicensable at will by the copyright holder. |

### 2. `cogni-visual/references/cartographic-data/countries.geo.json`

| Field | Finding |
|---|---|
| What it is | A low-resolution (1:110M, 180 countries, ~257 KB) world country-outline GeoJSON used by the `editorial-sketch` worker agent to draw accurate country outlines in editorial infographics. |
| Origin | **Third-party, permissive.** Source: [johan/world.geo.json](https://github.com/johan/world.geo.json) (MIT License). Underlying data: [Natural Earth](https://www.naturalearthdata.com/), released into the **public domain**. |
| Provenance record | `cogni-visual/references/cartographic-data/LICENSE.md` (in-tree). |
| License | MIT (packaging) over public-domain source data. |
| Copyleft? | **No.** MIT is a permissive license; public-domain data carries no license obligations at all. |
| Attribution | Already satisfied in-tree by `cartographic-data/LICENSE.md`, which credits johan/world.geo.json (MIT) and Natural Earth. Natural Earth requires no attribution; the credit is a courtesy. |
| Apache-2.0 compatible? | ✅ Yes — MIT and public domain are both compatible with Apache-2.0 (and with the current AGPL-3.0). |

---

## Negative findings (surfaces confirmed absent)

- **No dependency manifests** anywhere in the repo (`package.json`,
  `requirements.txt`, `Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`) — consistent
  with the `CLAUDE.md` invariant "stdlib-only — bash + python3, no pip
  dependencies". There is therefore **no transitive third-party dependency tree**
  to audit.
- **No third-party SPDX identifiers.** A repo-wide `SPDX-License-Identifier` grep
  matches only each plugin's own `LICENSE` file (`AGPL-3.0-only`, first-party).
  No `MIT` / `BSD` / `Apache` / `MPL` / non-Affero `GPL` identifiers appear
  anywhere in code.
- **No copyleft dependency.** A repo-wide grep for GPL/AGPL/LGPL header text
  matches only (a) the repo's own `LICENSE` files and (b) documentation
  describing *this repo's own* AGPL-3.0 licensing — never an incorporated
  third-party component.
- **No `cogni-service/` directory in-repo.** Confirmed via `find` and `ls`. The
  managed-service surface named in the epic intent lives out-of-repo and cannot
  be a blocker here.

## Full LICENSE-file inventory

All first-party license files are `AGPL-3.0-only` and belong to the sole
copyright holder; they are the subject of the #1056 swap, not third-party
obligations:

- Root `LICENSE` (AGPL-3.0-only)
- Per-plugin `LICENSE` files: `cogni-claims`, `cogni-copywriting`, `cogni-help`,
  `cogni-knowledge`, `cogni-marketing`, `cogni-narrative`, `cogni-portfolio`,
  `cogni-sales`, `cogni-trends`, `cogni-visual`, `cogni-workspace` (all
  AGPL-3.0-only)
- `cogni-visual/references/cartographic-data/LICENSE.md` — the **only**
  third-party license file (MIT / public-domain, permissive).

## NOTICE stub decision

**No repo-root `NOTICE` stub is warranted.**

- The `cogni-wiki` vendored tree is first-party, so there is nothing external to
  attribute.
- The cartographic data is public-domain (no attribution required) and its MIT
  packaging is already attributed in-tree by
  `cogni-visual/references/cartographic-data/LICENSE.md`.

If a `NOTICE` file is later desired as a courtesy consolidation, it would restate
the existing cartographic-data attribution — an optional polish, not a
relicense prerequisite.

## Non-blocking residual note (documentation history)

A long-since-removed early `cogni-wiki` `plugin.json` once described the plugin as
"Inspired by Andrej Karpathy's LLM Wiki pattern and the reference implementation
by kfchou/wiki-skills." This was a **design-inspiration credit, not a
code-incorporation claim**: the phrase no longer exists in the working tree, and
no `kfchou` / `wiki-skills` code or string is present anywhere in the repository.
It does not affect the verdict; it is recorded here only so a future auditor who
encounters the phrase in git history has the context.

---

## Conclusion

The permissive AGPL-3.0 → Apache-2.0 relicense is **not blocked** by any
incorporated third-party code. The audit's escalation branch (blocking copyleft
found → STOP and escalate to the maintainer) did **not** fire. Phase 2 — the
LICENSE-text swap (#1056) — may proceed.
