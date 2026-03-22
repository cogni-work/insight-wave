---
name: Desk Research Framing
phase: discover
type: divergent
inputs: [engagement-vision, scope]
outputs: [research-topic, research-config]
duration_estimate: "10-15 min with consultant"
requires_plugins: [cogni-gpt-researcher]
---

# Desk Research Framing

Translate the engagement vision into a well-scoped research topic for cogni-gpt-researcher.

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
Recommend settings for cogni-gpt-researcher:
- **Report type**: `detailed` (default), `deep` for digital-transformation/innovation
- **Market**: Match engagement scope (dach, de, us, uk, fr, global)
- **Tone**: `analytical` for business engagements
- **Source mode**: `web` (default), `hybrid` if client has internal documents

### Step 4: Dispatch
Invoke cogni-gpt-researcher:research-report with the configured topic and settings.

## Output
The research report and its sources become inputs for the Define phase.
