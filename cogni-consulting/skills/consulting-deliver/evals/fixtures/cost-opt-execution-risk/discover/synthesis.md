---
title: Discovery Synthesis — CostSmart IT Optimization
engagement: costsmart-it-opt
phase: discover
---

# Discovery Synthesis

## Key Findings

### IT Cost Structure
- Total IT operating costs: €16M annually (8.2% of revenue — industry average for regional banks is 6-7%)
- Data center costs: €4.8M (3 locations, average utilization 35%)
- Cloud spend: €2.1M (AWS primary, growing 30% YoY with limited governance)
- Outsourcing contracts: €5.6M (3 providers: Atos for infrastructure, DXC for application management, local provider for desktop support)
- Internal IT staff: 45 FTE, €3.5M total cost

### Infrastructure Assessment
- 280 servers across 3 data centers, 35% average utilization
- Data Center 1 (headquarters): 180 servers, lease expires Q1 2027
- Data Center 2 (DR site): 60 servers, underutilized — could consolidate to cloud DR
- Data Center 3 (branch processing): 40 servers, local processing for 12 branches
- AWS cloud: 120+ instances, estimated 40% are dev/test that could be rightsized or terminated

### Support Model
- Tier 1 support: 80% of tickets are password resets, hardware requests, and standard software installations
- Outsourced desktop support contract: €1.2M/year, locked until Q3 2027
- Tier 2/3 escalation rate: 35% (industry benchmark: 15-20%)
- No self-service portal; all requests go through phone/email to Tier 1

### Regulatory Environment
- BaFin BAIT (Bankaufsichtliche Anforderungen an die IT): requires documented IT strategy, risk management, outsourcing governance
- Any data center consolidation requires BaFin notification if it changes the IT risk profile
- Cloud migration requires compliance with BAIT cloud-specific requirements (§9)

### Surprises
- The AWS bill is growing 30% YoY but nobody owns cloud cost governance — it's split across 3 teams with no central FinOps
- Limited perspective from branch staff and end users — IT surveys show 62% satisfaction, but the survey is 18 months old
- Outsourcing contracts have exit penalty clauses (12-month notice + 6-month transition fee) that significantly impact consolidation economics
- Works council (Betriebsrat) has not been consulted about potential support model changes — this is legally required for any role restructuring in Germany

## Tensions
- Quick cloud optimization (€800K-1.2M savings) vs. structural transformation (additional €1.5-2M but requires data center consolidation)
- 12-month timeline vs. contract lock-in (2 of 3 outsourcing contracts locked until Q3 2027)
- No headcount reduction policy vs. support model that has 80% automatable Tier 1 tickets
- BaFin compliance maintenance vs. pace of infrastructure change
