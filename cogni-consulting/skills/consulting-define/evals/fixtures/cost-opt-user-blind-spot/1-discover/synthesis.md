# Discovery Synthesis — CostSmart IT Optimization

**Engagement**: CostSmart IT Optimization (Meridian Financial Services)
**Vision Class**: cost-optimization
**Methods**: Desk Research, Trend Scouting, Stakeholder Mapping, Data Audit
**Date**: 2026-03-19

## Themes

### 1. Fragmented IT Cost Visibility
IT spend is distributed across 4 systems (ServiceNow ITSM, AWS Cost Explorer, SAP FI, vendor contract database). No unified view of total IT cost exists. In some branches, IT costs are bundled with facilities costs, making accurate cost allocation impossible. The organization literally does not know what IT costs per branch or per user.
- **Source**: Data Audit, Stakeholder Mapping (CIO Sarah Chen confirmed this is her #1 frustration)
- **So what**: You cannot optimize what you cannot measure. Cost transparency must precede cost reduction — otherwise savings claims are unverifiable.

### 2. Cloud Spend Optimization Opportunity
AWS Cost Explorer data shows consistent over-provisioning: average instance utilization is 34%, reserved instance coverage is only 22% (industry benchmark: 60-70%). Estimated savings from right-sizing and reserved instance optimization: €1.8-2.4M annually — potentially achieving the 20-30% target from cloud alone.
- **Source**: Data Audit, Trend Scouting (cloud FinOps best practices)
- **So what**: Cloud optimization is the highest-confidence cost reduction lever. The data is granular, the benchmarks are clear, and the savings are achievable without organizational disruption.

### 3. Vendor Contract Consolidation Potential
28 vendor contracts managed by a 3-person team, with 15% of contracts missing renewal dates. Trend analysis shows that financial services peers average 12-15 strategic vendors vs. Meridian's 28. Contract overlap exists in monitoring, backup, and security tooling (3 vendors each for monitoring alone).
- **Source**: Data Audit, Trend Scouting, Stakeholder Mapping (vendor management team)
- **So what**: Vendor rationalization could reduce management overhead and unlock volume discounts — but contracts are locked until Q3 2027, limiting near-term action to assessment and planning.

### 4. Data Center Consolidation Economics
3 data centers serve 180 branches. Trend analysis shows banking peers moving to 1-2 data centers + cloud burst capacity. However, BaFin data residency requirements and disaster recovery mandates may require maintaining geographic distribution. A detailed workload analysis is needed to determine consolidation feasibility.
- **Source**: Desk Research, Trend Scouting
- **So what**: Data center consolidation is a significant cost lever (facilities, power, staffing) but regulatory constraints make it complex — this is a medium-term initiative, not a quick win.

### 5. ITSM Incident Pattern Signals Automation Opportunity
ServiceNow data shows 42% of incidents are password resets and access requests — highly automatable. IT operations staff spend an estimated 1,200 hours/month on these repetitive tasks. Since workforce reduction isn't an option, automation would free capacity for higher-value work rather than headcount savings.
- **Source**: Data Audit
- **So what**: Automation redirects existing staff capacity rather than reducing headcount — this aligns with the works council constraint and could improve response times and staff satisfaction.

### 6. Branch IT Support Model is Expensive
12 regional IT coordinators support 180 branches. Each coordinator handles 15 branches across a geographic region. Travel time averages 40% of their working hours. Remote support tools exist but adoption is low — branch managers prefer on-site visits.
- **Source**: Stakeholder Mapping, Data Audit
- **So what**: The branch support model is a cost center, but changing it requires addressing branch manager preferences and potentially redefining the coordinator role — this is as much a change management challenge as a cost challenge.

### 7. Compliance Cost is a Fixed Floor
BaFin/MaRisk IT compliance absorbs approximately 18% of the IT budget. The interim compliance officer role (handled by KPMG external auditor) costs €280k/year. Hiring a permanent compliance officer would cost approximately half that but requires finding someone with both BaFin and IT audit expertise — a scarce profile.
- **Source**: Stakeholder Mapping, Desk Research
- **So what**: Compliance costs are largely non-negotiable but the KPMG arrangement is expensive. A permanent hire would save ~€140k/year but introduces recruitment risk.

## Surprises

1. **Cloud savings potential exceeds expectations**: The 34% utilization rate and 22% RI coverage suggest €1.8-2.4M in annual savings from cloud optimization alone — this could achieve the engagement target without touching any other cost lever (Theme 2)
2. **Vacant compliance officer is expensive**: The KPMG interim arrangement costs nearly double what a permanent hire would — this wasn't flagged as a cost concern before the data audit (Theme 7)

## Tensions

1. **Quick wins vs. structural change**: Cloud optimization is fast and high-confidence, but it doesn't address the structural cost issues (vendor sprawl, data center footprint, support model). Focusing on cloud alone delivers the target number but leaves the organization's cost structure unchanged.
2. **Cost reduction vs. service quality**: Branch managers value on-site IT support. Moving to remote-first support saves travel time but branch staff experience it as a service downgrade — and these are the people serving bank customers.
3. **Measurement first vs. action first**: You can't optimize what you can't measure (Theme 1), but building a unified cost view takes 3-6 months before any actual savings begin. The COO's 12-month timeline doesn't leave much room for a measurement-first approach.

## Readiness for Define

**Assessment**: Ready to proceed. Strong quantitative evidence base from Data Audit and Trend Scouting. Stakeholder perspectives well-captured. Multiple actionable cost levers identified with varying timelines and complexity.

**Known gaps**: No competitive analysis was performed (less critical for cost optimization — this isn't a market-facing engagement). Limited perspective from branch staff and end users — the synthesis is dominated by HQ stakeholder views and financial data. The experience of the 2,400 staff who actually use IT services daily is largely absent from the evidence base.
