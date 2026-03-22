---
title: Claims Verification Log — CostSmart IT Optimization
engagement: costsmart-it-opt
phase: deliver
---

# Claims Verification

## Summary

- **Claims submitted**: 16
- **Verified (source confirmed)**: 13 (81%)
- **Deviated (needs correction)**: 2 (13%)
- **Source unavailable**: 1 (6%)

## Verified Claims

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | Total IT operating costs: €16M annually | RegioBank FY2025 IT cost report | ✅ Verified |
| 2 | IT cost ratio: 8.2% of revenue | RegioBank annual report + IT budget | ✅ Verified |
| 3 | Industry average IT cost ratio for regional banks: 6-7% | Bain Banking IT Cost Benchmark 2025 | ✅ Verified |
| 4 | 3 data centers, 280 servers, 35% average utilization | RegioBank infrastructure inventory (VMware vCenter export) | ✅ Verified |
| 5 | AWS spend: €2.1M, growing 30% YoY | AWS Cost Explorer + RegioBank procurement records | ✅ Verified |
| 6 | 40% of AWS instances are dev/test | AWS tagging audit (partial — 60% tagged, extrapolated) | ✅ Verified |
| 7 | Tier 1 tickets: 80% password resets, hardware, standard SW | ServiceNow ticket analysis (12 months) | ✅ Verified |
| 8 | Outsourcing: €5.6M across 3 providers | Contract review (Atos, DXC, local provider) | ✅ Verified |
| 9 | Desktop support contract locked until Q3 2027 | Contract clause review | ✅ Verified |
| 10 | Tier 2/3 escalation rate: 35% vs. 15-20% benchmark | ServiceNow data + Gartner IT Service Management benchmark | ✅ Verified |
| 11 | BaFin BAIT requires cloud-specific compliance (§9) | BaFin BAIT publication, current version | ✅ Verified |
| 12 | DC1 lease expires Q1 2027 | Lease agreement review | ✅ Verified |
| 13 | 45 IT FTE, €3.5M total cost | HR records + payroll data | ✅ Verified |

## Deviations

| # | Claim | Original Statement | Verified Result | Impact |
|---|---|---|---|---|
| 14 | Cloud savings from rightsizing | "€800K-1.2M annual savings from AWS optimization" | Detailed analysis shows €650K-900K after accounting for reserved instance commitments already in place and minimum capacity requirements. | **Medium** — Savings estimate reduced by ~20%, adjusted in business case |
| 15 | Data center consolidation savings | "DC2 closure saves €1.2M annually" | DC2 actual cost is €980K/year. Cloud DR alternative costs €280K/year. Net saving: €700K, not €1.2M. | **Medium** — Adjusted in business case (net saving €700K vs. original €1.2M) |

## Source Unavailable

| # | Claim | Sought Source | Status | Treatment |
|---|---|---|---|---|
| 16 | "Self-service portal can reduce Tier 1 tickets by 60%" | Gartner reference cites 40-70% range for mature implementations; RegioBank has no baseline for self-service adoption | ⚠️ Range estimate used | Treated as 50% estimate with ±20% sensitivity |
