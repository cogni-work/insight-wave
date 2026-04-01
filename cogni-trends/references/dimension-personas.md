# Dimension Personas for Trend Research

Expert personas that shape how each Smarter Service Trendradar dimension is researched. Each persona brings a distinct analytical lens, search vocabulary, and question pattern that surfaces dimension-appropriate signals.

The web-researcher agent loads this file at Step 0.5 and uses the persona for the current dimension to shape Tier 2 query formulation. The trend-generator uses persona context during extended thinking to prioritize candidates through the right analytical lens.

## How Personas Work

Instead of generic query templates identical across all 4 dimensions, each dimension gets queries shaped by an expert who would naturally investigate that domain. A regulatory analyst asks fundamentally different questions than a CTO — and finds different signals.

Personas influence three things:
1. **Search queries** — vocabulary, source preferences, question framing
2. **Signal evaluation** — what counts as a strong signal differs by domain
3. **Candidate generation** — what the trend-generator prioritizes during extended thinking

## Persona Catalog

---

### Externe Effekte — Regulatory & Market Analyst

**Role:** Senior analyst at an industry association or regulatory body, responsible for monitoring external forces that reshape market boundaries.

**Analytical lens:** Focuses on compliance timelines, enforcement mechanisms, market disruption indicators, competitive dynamics, and demographic shifts. Asks "what external forces are changing the rules?" rather than "what technology is emerging?"

**Search vocabulary by subcategory:**

| Subcategory | DE | Persona-Specific Keywords |
|-------------|-----|--------------------------|
| **wirtschaft** | Wirtschaft | market disruption, competitive dynamics, price pressure, supply chain shift, trade policy, economic indicator, market share shift, consolidation, new entrant |
| **regulierung** | Regulierung | regulatory deadline, compliance requirement, enforcement mechanism, penalty framework, certification mandate, audit obligation, reporting standard, regulatory sandbox |
| **gesellschaft** | Gesellschaft | demographic shift, workforce aging, sustainability mandate, ESG requirement, public sentiment, consumer behavior change, urbanization, skills shortage |

**Question patterns** (use to formulate search queries):
1. "What regulatory deadlines affect {SUBSECTOR} in the next 24 months?"
2. "Which market forces are reshaping competitive dynamics in {SUBSECTOR}?"
3. "What demographic or societal shifts will impact {SUBSECTOR} demand?"
4. "What trade policy or economic indicators signal disruption for {SUBSECTOR}?"
5. "What ESG or sustainability mandates apply to {SUBSECTOR}?"

**Authority preferences:** Government sources (authority 5) > industry associations (4) > consulting firms (4) > business media (3). Prioritize regulatory databases, statistical offices, and policy institutions.

**Industry adaptation hints:**
- Automotive: emissions regulation (EU7, CO2 fleet targets), safety certification (UNECE), trade tariffs
- Banking/Finance: prudential regulation (Basel IV, DORA), payment services (PSD3), anti-money laundering
- Healthcare: medical device regulation (MDR/IVDR), data privacy (EHDS), approval pathways
- Manufacturing: machinery directive, CE marking, product liability, supply chain due diligence (CSDDD)
- Energy: grid codes, renewable mandates, carbon pricing, nuclear phase-out/restart

---

### Neue Horizonte — Chief Strategy Officer

**Role:** CSO of a mid-to-large enterprise, responsible for identifying future revenue sources, evaluating business model evolution, and steering governance transformation.

**Analytical lens:** Focuses on business model viability, revenue diversification, M&A patterns, strategic positioning, and governance evolution. Asks "where is the next growth vector?" rather than "what technology stack should we use?"

**Search vocabulary by subcategory:**

| Subcategory | DE | Persona-Specific Keywords |
|-------------|-----|--------------------------|
| **strategie** | Strategie | business model innovation, revenue diversification, platform strategy, ecosystem play, strategic pivot, market entry, pricing model evolution, subscription model |
| **fuehrung** | Führung | leadership transformation, agile governance, board-level digital literacy, chief digital officer, innovation culture, strategic decision-making, executive alignment |
| **steuerung** | Steuerung | KPI framework, OKR adoption, data-driven decision, portfolio steering, risk governance, performance management, strategic control, balanced scorecard |

**Question patterns:**
1. "What new business models are emerging in {SUBSECTOR} beyond the traditional value chain?"
2. "Which M&A or partnership patterns signal strategic repositioning in {SUBSECTOR}?"
3. "What venture capital flows indicate future growth vectors for {SUBSECTOR}?"
4. "How are {SUBSECTOR} leaders restructuring governance for digital transformation?"
5. "What platform or ecosystem strategies are succeeding in {SUBSECTOR}?"

**Authority preferences:** Consulting firms (McKinsey, BCG, Roland Berger) (authority 4) > business media (HBR, Handelsblatt) (3) > VC/funding databases (3) > industry associations (4).

**Industry adaptation hints:**
- Automotive: mobility-as-a-service, software-defined vehicle revenue, aftermarket digital services
- Banking/Finance: embedded finance, banking-as-a-service, open banking ecosystems
- Healthcare: value-based care models, digital therapeutics, patient platform ecosystems
- Manufacturing: servitization, outcome-based pricing, industrial marketplace platforms
- Energy: energy-as-a-service, virtual power plants, peer-to-peer energy trading

---

### Digitale Wertetreiber — Customer Experience Strategist

**Role:** VP of Digital or Head of Customer Experience, responsible for driving measurable value through digital customer engagement, product innovation, and process optimization.

**Analytical lens:** Focuses on customer journey friction, conversion/NPS benchmarks, digital product ROI, process automation efficiency, and competitive UX differentiation. Asks "where does digital create measurable customer value?" rather than "what infrastructure do we need?"

**Search vocabulary by subcategory:**

| Subcategory | DE | Persona-Specific Keywords |
|-------------|-----|--------------------------|
| **customer-experience** | Kundenerlebnis | customer journey, NPS benchmark, conversion rate, personalization, omnichannel, self-service, customer churn, digital engagement, loyalty program |
| **produkte-services** | Produkte & Services | digital product, feature adoption, product-led growth, API economy, digital twin, smart product, connected device, as-a-service, usage-based |
| **geschaeftsprozesse** | Geschäftsprozesse | process automation, RPA, intelligent automation, workflow optimization, straight-through processing, process mining, operational efficiency, cost per transaction |

**Question patterns:**
1. "What customer experience innovations are driving measurable ROI in {SUBSECTOR}?"
2. "Which digital products or services have achieved significant adoption in {SUBSECTOR}?"
3. "What process automation use cases show the highest efficiency gains in {SUBSECTOR}?"
4. "How are {SUBSECTOR} leaders using data and AI to personalize customer engagement?"
5. "What NPS or customer satisfaction benchmarks exist for digital channels in {SUBSECTOR}?"

**Authority preferences:** Industry benchmarks and case studies (authority 3-4) > consulting firms with quantitative evidence (4) > technology vendors with validated ROI data (2-3) > academic research on adoption (5).

**Industry adaptation hints:**
- Automotive: connected car services, digital showroom, predictive maintenance alerts, OTA updates
- Banking/Finance: digital onboarding, robo-advisory, instant payments, open banking APIs
- Healthcare: patient portal, telehealth adoption, electronic health records UX, clinical decision support
- Manufacturing: configurator tools, B2B e-commerce, predictive quality, digital supply chain visibility
- Energy: smart metering, customer energy dashboards, EV charging UX, dynamic pricing

---

### Digitales Fundament — CTO / Workforce Transformation Expert

**Role:** CTO or VP Engineering combined with a Chief People Officer lens, responsible for technology infrastructure decisions, workforce capability building, and cultural readiness for digital transformation.

**Analytical lens:** Focuses on technology readiness levels, skills gap analysis, infrastructure scalability, cultural change metrics, and developer/employee experience. Asks "do we have the foundation to execute?" rather than "what should we build on top?"

**Search vocabulary by subcategory:**

| Subcategory | DE | Persona-Specific Keywords |
|-------------|-----|--------------------------|
| **kultur** | Kultur | digital culture, change management, innovation mindset, psychological safety, agile transformation, digital maturity, organizational readiness, failure culture |
| **mitarbeitende** | Mitarbeitende | skills gap, upskilling, reskilling, digital literacy, talent shortage, employee experience, remote work, new work, digital workplace, employer branding |
| **technologie** | Technologie | cloud migration, API architecture, data platform, cybersecurity, AI infrastructure, edge computing, legacy modernization, technical debt, DevOps maturity |

**Question patterns:**
1. "What technology infrastructure investments are {SUBSECTOR} leaders prioritizing?"
2. "What skills gaps are most critical for {SUBSECTOR} digital transformation?"
3. "How are {SUBSECTOR} organizations measuring and improving digital maturity?"
4. "What cybersecurity or data governance challenges are emerging for {SUBSECTOR}?"
5. "What cultural transformation approaches show measurable results in {SUBSECTOR}?"

**Authority preferences:** Technology analyst firms (Gartner, Forrester, IDC) (authority 4) > academic/standards bodies (IEEE, NIST) (5) > developer surveys (Stack Overflow, JetBrains) (3) > HR/workforce research (Korn Ferry, LinkedIn) (3).

**Industry adaptation hints:**
- Automotive: AUTOSAR Adaptive, vehicle software platform, SDV skills, EE architecture
- Banking/Finance: core banking modernization, cloud sovereignty, RegTech infrastructure, quantum-safe crypto
- Healthcare: FHIR/HL7 interoperability, health data spaces, clinical AI validation, medical IoT security
- Manufacturing: OT/IT convergence, industrial IoT platforms, digital twin infrastructure, 5G campus networks
- Energy: smart grid technology, SCADA modernization, green hydrogen systems, grid-scale storage

---

## Using Personas in Practice

### For the Web-Researcher Agent

When building Tier 2 search queries for a dimension:

1. Load this file and find the persona for the current dimension
2. Replace generic dimension keywords (e.g., "external trends regulations market forces") with the persona's `search_vocabulary` for the relevant subcategory
3. Use the persona's `question_patterns` to formulate 2-3 additional targeted queries
4. Apply `industry_adaptation_hints` to make queries subsector-specific
5. Respect `authority_preferences` when evaluating and deduplicating results

### For the Trend-Generator Agent

When generating candidates for a dimension during extended thinking:

1. Adopt the persona's analytical lens: "As a {PERSONA_ROLE} examining {DIMENSION} for {SUBSECTOR}..."
2. Use the persona's vocabulary to evaluate whether a candidate is truly relevant to this dimension
3. Apply the persona's authority preferences when assessing source quality
4. Use industry adaptation hints to contextualize candidates to the specific subsector

### Persona Selection

By default, personas are **auto-assigned** based on the dimension being researched. Users can override this in the Phase 0.5 configuration disclosure menu by selecting "manual" persona mode, which allows them to customize persona assignments (e.g., use the CTO persona for Neue Horizonte if the research topic is technology strategy).
