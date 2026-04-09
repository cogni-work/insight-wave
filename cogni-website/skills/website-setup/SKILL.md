---
name: website-setup
description: |
  This skill initializes a cogni-website project by discovering content sources from
  cogni-portfolio, cogni-marketing, cogni-trends, and cogni-research, selecting a theme,
  and scaffolding the project directory. It should be triggered when the user mentions
  creating a website, starting a new website project, setting up a website, "build me a
  website", "company website", "customer website", "generate a website", "website setup",
  "Website erstellen", "Homepage erstellen", "Internetauftritt", "Webseite generieren",
  "online presence", "web presence", or wants to turn portfolio content into a web
  presence — even without saying "setup" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill, AskUserQuestion
---

# Website Project Setup

Initialize a cogni-website project by discovering content from existing insight-wave plugins, selecting a theme, and scaffolding the project directory.

## Core Concept

A website project aggregates content from multiple insight-wave plugins into a multi-page static website:
- **cogni-portfolio** (required) — products, features, propositions, solutions, customer narratives
- **cogni-marketing** (optional) — blog posts, articles, whitepapers
- **cogni-trends** (optional) — trend reports with investment themes for an insights page
- **cogni-research** (optional) — research reports for a resources/whitepapers page

Setup discovers what content is available across these plugins, validates minimum requirements, captures company details, selects a visual theme, and creates `website-project.json` — the configuration that all downstream skills depend on.

If a `website-project.json` already exists in the working directory, redirect to the `website-resume` skill.

## Workflow

### 1. Check for Existing Project

Scan the current directory and immediate children for `website-project.json`. If found, inform the user and invoke the `website-resume` skill instead.

### 2. Discover Content Sources

Scan the workspace for insight-wave plugin projects using recursive globs. This mirrors the discovery pattern used by cogni-marketing:marketing-setup — recursive globs ensure discovery works regardless of workspace layout.

#### Portfolio Discovery (required)
- Glob for `**/portfolio.json` (recursive — do not use narrow single-level globs)
- Read each `portfolio.json` to extract: company name, description, industry, language
- Check for synthesized output: `output/README.md`
- Check for enriched customer narratives at `output/communicate/customer-narrative/` (v2 layout — one file per website component, each arc-structured with an `arc_id` field in its YAML frontmatter):
  - Home (`home.md`, arc `jtbd-portfolio`)
  - About Us (`about.md`, arc `company-credo`)
  - How We Work (`approach.md`, arc `engagement-model`)
  - Capability pages (`capabilities/*.md`, arc `corporate-visions`) — one per customer-facing feature
  - Persona landing pages (`for/*.md`, arc `jtbd-portfolio`) — one per `{market}--{persona}` pair
  - These are audience-tailored prose with assertion headlines, pain points, stats, differentiators, and CTAs already written by a copywriter-grade skill. When present, `website-plan` treats them as the **primary** spine for the corresponding pages rather than re-deriving content from raw entity JSON. The `arc_id` frontmatter field tells the planner which story-arc decomposition to apply in step 6a. Store every discovered path — the planner needs them all.
  - **v1 backward-compat:** if the directory instead contains `portfolio-overview.md`, `market/*.md`, or `customer/*.md`, it was produced by an older version of `portfolio-communicate`. Still discover them, but print a warning: "Gefunden: altes customer-narrative-Layout (v1). Bitte `portfolio-communicate` neu ausführen, um die website-orientierte v2-Struktur (`home.md`, `about.md`, `capabilities/*.md`, `for/*.md`, `approach.md`) zu erzeugen." The planner will still read the v1 files, but downstream dedup discipline (Roadmap on home only, differentiators on about only) depends on the v2 layout.
- Count entities: products, features, markets, propositions, solutions, packages

#### Marketing Discovery (optional)
- Glob for `**/marketing-project.json`
- Read `marketing-project.json` for brand voice and content strategy
- Count content pieces by type: `content/thought-leadership/*.md`, `content/demand-generation/*.md`, `content/lead-generation/*.md`

#### Trends Discovery (optional)
- Glob for `**/tips-project.json`
- For each found, check if `tips-trend-report.md` exists alongside it (trend report completed)
- If present, also check for `tips-value-model.json` to count investment themes
- Trend reports contain executive-ready narrative content with inline citations — ideal for an Insights page

#### Research Discovery (optional)
- Glob for directories containing `**/output/draft-v*.md` or `**/output/report.md` (cogni-research output)
- Count available research reports
- Research reports serve as whitepapers/resources — high-value content for establishing authority

#### Present Findings

```
Gefundene Inhaltsquellen:

Portfolio: ../acme-cloud/
  ✓ 3 Produkte, 8 Features, 2 Märkte, 12 Propositions
  ✓ Customer-Narrative (v2): home.md, about.md, approach.md, 6 Capability-Seiten, 4 Persona-Seiten
  ✓ Synthese erstellt

Marketing: ../acme-marketing/
  ✓ 4 Thought-Leadership-Artikel
  ✓ 6 Demand-Generation-Beiträge
  ✓ 2 Landing Pages

Trends: ../b2b-ict-trends/
  ✓ Trend-Report mit 5 Investitionsthemen

Research: ../cloud-security-report/
  ✓ 1 Forschungsbericht
```

If multiple projects of the same type are found, present all and ask the user to select one. If only one exists, confirm automatically.

#### Validation Gates

**Hard gate** — if no portfolio project is found, warn the user that a portfolio is the minimum requirement. Offer to help set one up via `cogni-portfolio:portfolio-setup`. Do not proceed without a portfolio.

**Hard gate** — the discovered portfolio must have at least 1 product AND a company name/description. Without these, the website has no meaningful content to render.

**Soft warnings** (inform but allow proceeding):
- No propositions → product pages will lack benefit messaging
- No customer narratives → About, capability, persona, and approach pages fall back to entity-JSON rendering (flat templates); case studies page not available
- No marketing content → no blog section
- No trend report → no insights page
- No research reports → no resources page

### 3. Gather Company Details

Extract company information from the discovered portfolio.json:
- Company name, description, tagline
- Contact email, phone, address (ask if not in portfolio)
- Language (from portfolio.json `language` field)

Ask only for what's missing. Adapt all user-facing text to the portfolio language (examples below use German):

> "Aus dem Portfolio übernehme ich: **Acme Cloud Services** — Cloud-Infrastruktur für den Mittelstand. Fehlen noch: **Kontakt-E-Mail** und **Adresse** für die Kontaktseite. Können Sie die ergänzen?"

### 3a. Capture Legal Foundation

Websites published in the EU and DACH must carry mandatory legal pages (Impressum, Datenschutzerklärung, Cookie-Hinweis). Capture the foundation now so the downstream `website-legal` skill can render those pages without re-asking everything.

Ask via `AskUserQuestion`:

> "In welcher Rechtsordnung wird die Website veröffentlicht?"

Options:

- **Deutschland (DE)** — Impressum nach § 5 TMG, Datenschutzerklärung nach DSGVO
- **Österreich (AT)** — Offenlegung nach § 5 ECG / § 25 MedienG, DSGVO
- **Schweiz (CH)** — Anbieterkennzeichnung, revDSG
- **EU (übrige Mitgliedstaaten)** — Legal Notice, GDPR Privacy Policy
- **Noch unklar / später festlegen**

If the user picks a jurisdiction, immediately ask the minimum facts via a second `AskUserQuestion` round (one question per topic, batched in a single tool call):

1. Vollständiger Firmenname inkl. Rechtsform (z. B. "Acme Cloud Services GmbH")
2. Eingetragene Anschrift (Straße, PLZ, Ort, Land)
3. Vertretungsberechtigte Person (Name + Rolle, z. B. "Maria Mustermann, Geschäftsführerin")
4. Handelsregistereintrag (HRB/FN/CHE-Nummer + Registergericht — leer lassen falls nicht eingetragen)
5. USt-IdNr. (leer lassen für Kleinunternehmer)
6. Gibt es einen bestellten Datenschutzbeauftragten? (Ja/Nein)

Only ask for additional fields (supervisory authority, professional regulations) if the user indicates a regulated industry. The full schema is in `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/legal-config-schema.md` — do not block setup on it; the `website-legal` skill will fill the gaps later.

If the user picks "noch unklar", write `legal_config: { jurisdiction: null }` and tell them they must run `/website-legal` before publishing.

Persist all captured fields into the `legal_config` block (see step 6 for the schema).

### 4. Select Theme

Invoke `cogni-workspace:pick-theme` to let the user select a visual theme. The theme drives all colors, fonts, and styling across the website.

After theme selection, derive design variables by reading the theme.md file and generating `output/design-variables.json` following the convention in `cogni-workspace/references/design-variables-pattern.md`.

### 5. Configure Build Options

Ask the user about build preferences using AskUserQuestion. Only show options for content sources that were actually discovered:

- **Homepage Hero**: "Pencil MCP" (AI-generated hero image, ~3-5 Min.) or "CSS-only" (schneller, Farbverlauf-Hintergrund)
- **Blog einbinden**: Ja/Nein (only if marketing content exists)
- **Fallstudien einbinden**: Ja/Nein (only if customer narratives exist)
- **Insights-Seite einbinden**: Ja/Nein (only if trend report exists)
- **Ressourcen-Seite einbinden**: Ja/Nein (only if research reports exist)

### 6. Create Project Structure

Create the website project directory and write configuration:

```bash
mkdir -p cogni-website/{output/website/{css,pages,images},output}
```

Write `website-project.json` following the schema documented in `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` (see the project config section). Key fields:

- `slug`, `name`, `language`, `theme_path`
- `company` — name, tagline, description, contact details
- `sources`:
  - `portfolio_project` — path to portfolio directory (required)
  - `marketing_project` — path to marketing directory (null if not found)
  - `trends_project` — path to trends directory (null if not found)
  - `research_projects` — array of paths to research report directories (empty array if none)
  - `enriched_portfolio_narratives` — object with keys `home`, `about`, `approach` (each a single path), `capabilities` (map: `{feature_slug}` → path), and `personas` (map: `{market}--{persona}` → path). Each entry carries the file's `arc_id` so the planner can pick the right decomposition without re-reading the frontmatter. null if no portfolio-communicate output exists. For v1 projects that still have `portfolio-overview.md` / `market/*.md` / `customer/*.md`, write them into a legacy `v1` sub-object (`{ "v1": { "overview": ..., "markets": {...}, "personas": {...} } }`) so the planner can fall back without confusing the new keys.
- `build_options` — hero_renderer, include_blog, include_case_studies, include_insights, include_resources
- `content_discovery` — entity counts per source for change detection by website-resume
- `legal_config` — jurisdiction (`de`/`at`/`ch`/`eu`/`null`), `legal_entity` (legal_name, legal_form, address, register_court, register_number, vat_id), `responsible_person` (name, role, address_same_as_entity), `contact` (email, phone), `data_protection` (controller_name, controller_contact, dpo_required, dpo_name, dpo_contact). Schema: `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/legal-config-schema.md`. Fields not captured in step 3a are written as `null` and filled later by `website-legal`.

All boolean build options default to `true` when the corresponding content source exists, `false` when it does not. Set `hero_renderer` to `"pencil"` or `"html"` based on user choice.

### 7. Present Summary and Next Steps

```
Website-Projekt erstellt: {slug}

Konfiguration:
  Unternehmen: {name}
  Sprache: {language}
  Theme: {theme_name}
  Hero: {pencil|html}

Inhaltsquellen:
  Portfolio: ✓ ({N} Produkte, {M} Features, {K} Propositions)
  Marketing: {✓ N Artikel | ✗ nicht gefunden}
  Trends:    {✓ Trend-Report | ✗ nicht gefunden}
  Research:  {✓ N Berichte | ✗ nicht gefunden}

Rechtliches:
  {✓ DE-Konfiguration erfasst — Impressum, Datenschutz, Cookies werden erzeugt
   | ⚠ ausstehend — bitte vor Veröffentlichung /website-legal ausführen}

Nächster Schritt: /website-plan — Seitenstruktur planen und Inhalte zuordnen
```

## Output Language

Read the `language` field from portfolio.json. Generate all user-facing text in that language. JSON field names and slugs remain in English. Default to German (de) if not specified.

## Slug Convention

Derive the website slug from the company name:
- Lowercase, hyphens instead of spaces
- Replace umlauts: ü→ue, ö→oe, ä→ae, ß→ss
- Remove special characters
- Append `-website` suffix
- Example: "Acme Cloud Services" → `acme-cloud-website`
