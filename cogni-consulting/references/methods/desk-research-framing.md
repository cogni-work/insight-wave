---
name: Desk Research Framing
phase: discover
type: divergent
inputs: [engagement-vision, scope]
outputs: [research-topic, research-config]
duration_estimate: "10-15 min with consultant"
requires_plugins: [cogni-knowledge]
---

# Desk Research Framing

Translate the engagement vision into a well-scoped research topic for the cogni-knowledge inverted pipeline, deposited into the engagement's bound knowledge base so the evidence compounds across phases.

## When to Use

- Every engagement that needs evidence beyond what the client already has
- Critical for: strategic-options, business-case, market-entry, digital-transformation

## Guided Prompt Sequence

### Step 1: Topic Derivation
From the engagement vision, derive a research topic:
- **strategic-options**: "[Industry] strategic landscape and growth vectors in [scope]"
- **business-case**: "[Product/initiative] market opportunity and competitive dynamics"
- **gtm-roadmap**: "[Market] buyer landscape, channels, and competitive positioning"
- **cost-optimization**: "[Domain] operational benchmarks and efficiency best practices"
- **digital-transformation**: "[Industry] digital maturity, technology trends, and transformation case studies"
- **innovation-portfolio**: "[Industry] emerging technologies and innovation investment patterns"
- **market-entry**: "[Market/geography] entry barriers, regulatory landscape, and competitive dynamics"

Present the derived topic and ask the consultant to refine.

### Step 2: Multi-Jurisdiction Check
If the engagement scope spans multiple markets or geographies (e.g., "DACH + US", "Europe-wide"), a single generic research topic will miss jurisdiction-specific factors that matter. For each jurisdiction in scope, identify whether there are regulatory frameworks, industry standards, or market structures that differ materially. If so, either:
- **Expand the research topic** to explicitly name the per-jurisdiction factors (e.g., "including HIPAA compliance landscape for US and Telematikinfrastruktur / gematik requirements for Germany")
- **Run a separate focused research query** per jurisdiction for the regulatory/standards layer

This is especially critical for: market-entry (regulatory barriers differ by country), gtm-roadmap (channel structures and buying behavior vary), digital-transformation (compliance and data sovereignty rules are jurisdiction-specific), and cost-optimization (labor law and works council requirements vary).

The goal is to ensure the discovery evidence is equally specific across all jurisdictions in scope — a synthesis that is detailed for the US but vague for DACH (or vice versa) will be caught by domain experts and undermines credibility.

### Step 3: Research Configuration
Recommend settings for the cogni-knowledge run:
- **Depth** (replaces the old report type): `--target-words 4000` with 5–7 sub-questions (default); `--target-words 6000+` / `--prose-density executive` for digital-transformation/innovation; `--target-words 3000` with 3–4 sub-questions for a focused single-topic dive
- **Market** and **output language**: inherited from the engagement's bound base (`knowledge-setup` defaults, matching the engagement scope — dach, de, us, uk, fr, global). Bind the base first if `plugin_refs.knowledge_base` is unset
- **Tone**: `analytical` for business engagements (a `knowledge-setup` / `knowledge-plan` default)
- **Source**: `--source web` for a new topic (full crawl); `--source wiki` to compose from coverage the base already holds without re-crawling

### Step 4: Dispatch
Run the cogni-knowledge inverted pipeline against the bound base: `knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → knowledge-compose → knowledge-verify → knowledge-finalize` for a new topic, or the shorter `knowledge-plan → knowledge-compose --source wiki → knowledge-verify → knowledge-finalize` when the base already covers it. After `knowledge-finalize`, copy the synthesis `wiki/syntheses/<slug>.md` to the phase's `research/summary.md`.

## Output
The finalized synthesis and its cited sources become inputs for the Define phase — and remain in the bound base for later phases to build on.
