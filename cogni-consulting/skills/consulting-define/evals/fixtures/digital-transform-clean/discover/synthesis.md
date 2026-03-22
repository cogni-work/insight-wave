# Discovery Synthesis — SmartFactory Digitalisierung

**Engagement**: SmartFactory Digitalisierung (Müller Maschinenbau GmbH)
**Vision Class**: digital-transformation
**Methods**: Desk Research, Trend Scouting, Competitive Analysis, Stakeholder Mapping, Data Audit
**Date**: 2026-03-20

## Themes

### 1. Data Island Problem
Siemens S7 controllers on all 12 CNC machines store operational data locally with no central access. SAP ERP tracks orders and materials reliably, but there is no connection between order data and machine performance data. This fragmentation means production decisions are based on intuition rather than real-time evidence.
- **Source**: Data Audit, Stakeholder Interviews (IT-Leiter Jens Bauer)
- **So what**: Any digital transformation must start with data connectivity — without it, advanced analytics and predictive maintenance are impossible.

### 2. Retrofit vs. Replace Dilemma
Desk research shows that OPC UA retrofit solutions for S7 controllers exist (Siemens MindSphere, third-party gateways) at €15-25k per machine, vs. full machine replacement at €150-400k. Industry trend data confirms that 65% of mid-size manufacturers choose retrofit over replacement for machines under 10 years old. Müller's machines range from 3-15 years.
- **Source**: Desk Research, Trend Scouting, Competitive Analysis (Siemens partner channel)
- **So what**: The budget constraint (€2.5M over 18 months) strongly favors retrofit for newer machines but some older machines may need replacement planning — this creates a segmentation decision.

### 3. Works Council as Strategic Partner, Not Blocker
Betriebsratsvorsitzende Andrea Müller initially expressed concern about performance monitoring. However, stakeholder mapping revealed that the works council is open to data collection if: (a) no individual performance tracking, (b) aggregated data only at machine/line level, (c) workers trained to interpret dashboards themselves. Fraunhofer advisor Prof. Hartmann confirmed this pattern — works councils become advocates when given co-design authority.
- **Source**: Stakeholder Mapping, Desk Research (Fraunhofer case studies)
- **So what**: The works council constraint is real but navigable — transforming it into a governance partnership accelerates adoption and reduces resistance risk.

### 4. Skills Gap Threatens Adoption
IT department has only 3 staff managing all plant IT. None have OT (operational technology) expertise. Shift leaders (12) are experienced operators but have no data literacy training. Without upskilling, new dashboards and data tools will be ignored.
- **Source**: Stakeholder Mapping, Data Audit
- **So what**: Technology deployment without a parallel skills program will fail. The transformation roadmap must include training investment alongside infrastructure.

### 5. Energy Monitoring as Quick Win
Stadtwerke Sindelfingen already provides 15-minute interval energy data via API. This is the only real-time data source currently available without any infrastructure investment. Competitive analysis shows 3 of 5 comparable manufacturers started their digital journey with energy optimization — it provides visible ROI within 3-6 months and builds organizational confidence for larger initiatives.
- **Source**: Data Audit, Competitive Analysis
- **So what**: Energy monitoring is a low-risk, high-visibility starting point that demonstrates value and builds the data culture needed for more complex initiatives.

### 6. Vendor Lock-in Risk with MindSphere
Siemens MindSphere is the obvious platform choice given the existing S7 infrastructure, but trend analysis flags increasing platform lock-in concerns. Two competitors in the analysis switched away from MindSphere within 2 years due to pricing escalation. Open-source alternatives (Apache Kafka + Grafana) require more initial setup but offer flexibility.
- **Source**: Trend Scouting, Competitive Analysis
- **So what**: The platform decision has long-term strategic implications beyond the immediate project — this needs explicit evaluation criteria during solution design.

### 7. Quality Data Gap at Weekends
Quality protocols are Excel-based with 30% data gaps on weekends (reduced staffing). Maintenance logs are still paper-based. This means any quality-focused use case (defect prediction, SPC dashboards) will have systematic blind spots until data capture processes are standardized.
- **Source**: Data Audit
- **So what**: Quality use cases should be deferred until data capture gaps are closed — pursuing them now would produce unreliable results that erode trust in the digital initiative.

## Surprises

1. **Works council openness**: Expected to be the primary blocker; instead, they have a clear framework for acceptable data use that accelerates rather than blocks the initiative (Theme 3)
2. **Energy data availability**: A ready-made data source exists that requires zero infrastructure investment — this wasn't in the original engagement scope but changes the sequencing calculus (Theme 5)

## Tensions

1. **Speed vs. Foundation**: The client wants visible results quickly (energy monitoring, basic dashboards), but the fundamental data connectivity problem (S7 access) must be solved for the transformation to scale. Starting with quick wins risks creating a false sense of progress.
2. **Platform commitment vs. Flexibility**: MindSphere integration is fastest (2-3 months) but creates vendor dependency. Open-source is more flexible but requires capabilities the 3-person IT team doesn't have.
3. **Comprehensive vs. Pragmatic**: A complete Industry 4.0 vision requires all machines connected, quality data standardized, and predictive analytics deployed. The budget supports about 60% of this — prioritization is unavoidable.

## Readiness for Define

**Assessment**: Ready to proceed. The evidence base covers technology, people, process, and commercial dimensions. Theme triangulation is strong — key themes (data connectivity, skills gap, vendor choice) are supported by 2-3 sources each. The works council finding and energy quick-win opportunity are genuine insights that will shape the problem framing.

**Known gaps**: No direct customer/market perspective (this is an internal transformation engagement, so this gap is expected and acceptable). Paper-based maintenance logs were identified but not deeply analyzed — this could matter if maintenance use cases are prioritized.
